import 'package:dio/dio.dart';
import 'api_client.dart';

/// Supported content types for requests
enum RequestContentType { json, formData, multipart }

/// Generic API Handler that supports ALL HTTP methods and ALL parameter types
class ApiHandler {
  final Dio _dio;

  ApiHandler({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  // =========================================================================
  // GET
  // =========================================================================

  Future<T> get<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    String? errorMessage,
  }) async {
    return _execute<T>(
      method: 'GET',
      endpoint: endpoint,
      fromJson: fromJson,
      queryParameters: queryParameters,
      headers: headers,
      errorMessage: errorMessage ?? 'GET request failed',
    );
  }

  // =========================================================================
  // POST
  // =========================================================================

  Future<T> post<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    RequestContentType contentType = RequestContentType.formData,
    String? errorMessage,
    Map<String, dynamic>? extra,
  }) async {
    return _execute<T>(
      method: 'POST',
      endpoint: endpoint,
      fromJson: fromJson,
      data: data,
      extra: extra,
      queryParameters: queryParameters,
      headers: headers,
      contentType: contentType,
      errorMessage: errorMessage ?? 'POST request failed',
    );
  }

  // =========================================================================
  // PUT
  // =========================================================================

  Future<T> put<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    RequestContentType contentType = RequestContentType.formData,
    String? errorMessage,
  }) async {
    return _execute<T>(
      method: 'PUT',
      endpoint: endpoint,
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      contentType: contentType,
      errorMessage: errorMessage ?? 'PUT request failed',
    );
  }

  // =========================================================================
  // DELETE
  // =========================================================================

  Future<T> delete<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    RequestContentType contentType = RequestContentType.json,
    String? errorMessage,
  }) async {
    return _execute<T>(
      method: 'DELETE',
      endpoint: endpoint,
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      contentType: contentType,
      errorMessage: errorMessage ?? 'DELETE request failed',
    );
  }

  // =========================================================================
  // PATCH
  // =========================================================================

  Future<T> patch<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    RequestContentType contentType = RequestContentType.formData,
    String? errorMessage,
  }) async {
    return _execute<T>(
      method: 'PATCH',
      endpoint: endpoint,
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      contentType: contentType,
      errorMessage: errorMessage ?? 'PATCH request failed',
    );
  }

  // =========================================================================
  // SINGLE FILE UPLOAD
  // =========================================================================

  Future<T> uploadFile<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    required String filePath,
    required String fileKey,
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    String? errorMessage,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        fileKey: await MultipartFile.fromFile(filePath),
        if (additionalData != null) ...additionalData,
      });

      final response = await _dio.post(
        endpoint,
        data: formData,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        onSendProgress: onSendProgress,
      );

      return _parseResponse(
        response,
        fromJson,
        errorMessage ?? 'File upload failed',
      );
    } on DioException catch (e) {
      throw _parseError(e, errorMessage ?? 'File upload failed');
    } catch (e) {
      throw Exception('Unexpected error during file upload: $e');
    }
  }

  // =========================================================================
  // MULTIPLE FILES UPLOAD
  // =========================================================================

  Future<T> uploadMultipleFiles<T>({
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, String> files, // {fieldName: filePath}
    Map<String, dynamic>? additionalData,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    String? errorMessage,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final Map<String, dynamic> formMap = {};

      for (final entry in files.entries) {
        formMap[entry.key] = await MultipartFile.fromFile(entry.value);
      }

      if (additionalData != null) {
        formMap.addAll(additionalData);
      }

      final formData = FormData.fromMap(formMap);

      final response = await _dio.post(
        endpoint,
        data: formData,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        onSendProgress: onSendProgress,
      );

      return _parseResponse(
        response,
        fromJson,
        errorMessage ?? 'Multiple files upload failed',
      );
    } on DioException catch (e) {
      throw _parseError(e, errorMessage ?? 'Multiple files upload failed');
    } catch (e) {
      throw Exception('Unexpected error during multiple files upload: $e');
    }
  }

  // =========================================================================
  // DOWNLOAD FILE
  // =========================================================================

  Future<Response> downloadFile({
    required String endpoint,
    required String savePath,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    void Function(int received, int total)? onReceiveProgress,
    String? errorMessage,
  }) async {
    try {
      final response = await _dio.download(
        endpoint,
        savePath,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _parseError(e, errorMessage ?? 'Download failed');
    }
  }

  // =========================================================================
  // RAW REQUEST (Full control)
  // =========================================================================

  Future<T> request<T>({
    required String method,
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    RequestContentType contentType = RequestContentType.json,
    String? errorMessage,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    return _execute<T>(
      method: method,
      endpoint: endpoint,
      fromJson: fromJson,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      contentType: contentType,
      errorMessage: errorMessage ?? '$method request failed',
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  // =========================================================================
  // PRIVATE CORE EXECUTOR
  // =========================================================================

  Future<T> _execute<T>({
    required String method,
    required String endpoint,
    required T Function(Map<String, dynamic>) fromJson,
    dynamic data,
    Map<String, dynamic>? extra,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    RequestContentType contentType = RequestContentType.formData,
    required String errorMessage,
    void Function(int sent, int total)? onSendProgress,
    void Function(int received, int total)? onReceiveProgress,
  }) async {
    try {
      dynamic requestData;

      if (data != null) {
        switch (contentType) {
          case RequestContentType.formData:
            requestData = data is FormData ? data : FormData.fromMap(data);
            break;
          case RequestContentType.json:
            requestData = data;
            break;
          case RequestContentType.multipart:
            requestData = data is FormData ? data : FormData.fromMap(data);
            break;
        }
      }

      final response = await _dio.request(
        endpoint,
        data: requestData,

        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: headers,
          extra: extra,
          contentType: contentType == RequestContentType.json
              ? Headers.jsonContentType
              : contentType == RequestContentType.formData
              ? Headers.formUrlEncodedContentType
              : null,
        ),
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return _parseResponse(response, fromJson, errorMessage);
    } on DioException catch (e) {
      throw _parseError(e, errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  // =========================================================================
  // RESPONSE PARSER
  // =========================================================================

  T _parseResponse<T>(
    Response response,
    T Function(Map<String, dynamic>) fromJson,
    String errorMessage,
  ) {
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.data == null ||
          (response.data is String && (response.data as String).isEmpty)) {
        return fromJson({'success': true, 'status_code': statusCode});
      }

      if (response.data is List) {
        return fromJson({'data': response.data, 'status_code': statusCode});
      }

      if (response.data is Map<String, dynamic>) {
        return fromJson(response.data as Map<String, dynamic>);
      }

      return fromJson({
        'data': response.data,
        'success': true,
        'status_code': statusCode,
      });
    } else {
      String serverMessage = 'Unknown error';
      if (response.data is Map) {
        serverMessage =
            response.data['message'] ??
            response.data['error'] ??
            response.data['msg'] ??
            'Server error';
      }
      throw Exception('$errorMessage: $statusCode - $serverMessage');
    }
  }

  // =========================================================================
  // ERROR PARSER
  // =========================================================================

  Exception _parseError(DioException e, String errorMessage) {
    // ============================================================
    // SERVER RESPONSE EXISTS
    // ============================================================
    if (e.response != null) {
      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data;

      dynamic rawMessage;

      if (errorData is Map) {
        rawMessage =
            errorData['message'] ??
            errorData['error'] ??
            errorData['msg'] ??
            errorData['detail'];
      } else if (errorData is String) {
        rawMessage = errorData;
      }

      String message;

      // API returned a String
      if (rawMessage is String && rawMessage.trim().isNotEmpty) {
        message = rawMessage;
      }
      // API returned a List of validation errors
      else if (rawMessage is List) {
        final messages = rawMessage
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();

        message = messages.isNotEmpty
            ? messages.join('\n')
            : '$errorMessage (Status: $statusCode)';
      }
      // No usable message
      else {
        message = '$errorMessage (Status: $statusCode)';
      }

      return Exception(message);
    }

    // ============================================================
    // NETWORK / DIO ERRORS
    // ============================================================

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return Exception('Connection timeout. Please try again.');

      case DioExceptionType.connectionError:
        return Exception('No internet connection. Please check your network.');

      case DioExceptionType.badCertificate:
        return Exception(
          'SSL certificate error. Please check your connection.',
        );

      case DioExceptionType.badResponse:
        return Exception('Server returned an invalid response.');

      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');

      case DioExceptionType.unknown:
        return Exception('Network error: ${e.message ?? 'Unknown error'}');
    }
  }
}
