import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

enum AuthType { none, basic, bearer, apiKey, custom }

class AuthConfig {
  final AuthType type;
  final String? token;
  final String? username;
  final String? password;
  final String? headerName;
  final String? customPrefix;

  const AuthConfig._({
    required this.type,
    this.token,
    this.username,
    this.password,
    this.headerName,
    this.customPrefix,
  });

  factory AuthConfig.none() => const AuthConfig._(type: AuthType.none);

  factory AuthConfig.basic({
    required String username,
    required String password,
  }) {
    return AuthConfig._(
      type: AuthType.basic,
      username: username,
      password: password,
    );
  }

  factory AuthConfig.bearer(String token) {
    return AuthConfig._(type: AuthType.bearer, token: token);
  }

  factory AuthConfig.apiKey(String key, {String headerName = 'X-API-Key'}) {
    return AuthConfig._(
      type: AuthType.apiKey,
      token: key,
      headerName: headerName,
    );
  }

  factory AuthConfig.custom(String token, {required String prefix}) {
    return AuthConfig._(
      type: AuthType.custom,
      token: token,
      customPrefix: prefix,
    );
  }

  String? get headerValue {
    switch (type) {
      case AuthType.none:
        return null;
      case AuthType.basic:
        if (username == null || password == null) return null;
        return 'Basic ${base64Encode(utf8.encode('$username:$password'))}';
      case AuthType.bearer:
        return token != null && token!.isNotEmpty ? 'Bearer $token' : null;
      case AuthType.apiKey:
        return null;
      case AuthType.custom:
        return token != null && customPrefix != null
            ? '$customPrefix $token'
            : null;
    }
  }

  String? get apiKeyHeaderName {
    if (type == AuthType.apiKey) return headerName ?? 'X-API-Key';
    return null;
  }

  String? get apiKeyHeaderValue {
    if (type == AuthType.apiKey) return token;
    return null;
  }
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  bool _isInitialized = false;

  static const String _defaultUsername = 'test';
  static const String _defaultPassword = 'test';

  AuthConfig _authConfig = AuthConfig.basic(
    username: _defaultUsername,
    password: _defaultPassword,
  );

  bool _isRefreshing = false;
  Completer<void>? _refreshCompleter;

  VoidCallback? onUnauthorized;

  // ==================== INITIALIZATION ====================

  void init() {
    if (_isInitialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrlRider,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    _setupInterceptors();
    _isInitialized = true;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.extra['skipAuth'] != true) {
            _applyAuth(options);
          }

          return handler.next(options);
        },

        onResponse: (response, handler) {
          return handler.next(response);
        },

        onError: (error, handler) async {
          print('🔥 API ERROR');
          print('URL: ${error.requestOptions.uri}');
          print('STATUS: ${error.response?.statusCode}');

          if (error.response?.statusCode == 401) {
            print('🔄 401 → START TOKEN REFRESH');

            await _handleTokenRefresh(error, handler);
            return;
          }

          print('❌ ${error.response?.statusCode} → NO REFRESH');

          handler.next(error);
        },
      ),
    );

    _dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  /// Apply auth headers based on current config
  void _applyAuth(RequestOptions options) {
    options.headers.remove('Authorization');
    options.headers.remove('X-API-Key');

    switch (_authConfig.type) {
      case AuthType.none:
        break;
      case AuthType.basic:
      case AuthType.bearer:
      case AuthType.custom:
        final value = _authConfig.headerValue;
        if (value != null) {
          options.headers['Authorization'] = value;
        }
        break;
      case AuthType.apiKey:
        final headerName = _authConfig.apiKeyHeaderName;
        final headerValue = _authConfig.apiKeyHeaderValue;
        if (headerName != null && headerValue != null) {
          options.headers[headerName] = headerValue;
        }
        break;
    }
  }

  // ==================== TOKEN REFRESH ====================

  Future<void> _handleTokenRefresh(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // ============================================================
    // NEVER refresh the refresh API itself
    // ============================================================

    if (err.requestOptions.path.contains(ApiEndpoints.authRefresh)) {
      print('❌ REFRESH API ITSELF RETURNED 401');

      _isRefreshing = false;

      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter!.completeError(Exception('Refresh token expired'));
      }

      _refreshCompleter = null;

      // THIS means refresh token is invalid/expired.
      // Only here should logout happen.
      onUnauthorized?.call();

      handler.reject(err);
      return;
    }

    // ============================================================
    // Another request is already refreshing
    // ============================================================

    if (_isRefreshing && _refreshCompleter != null) {
      try {
        await _refreshCompleter!.future;

        final newAccessToken = _authConfig.token;

        if (newAccessToken == null || newAccessToken.isEmpty) {
          handler.reject(err);
          return;
        }

        final opts = err.requestOptions;

        opts.headers['Authorization'] = 'Bearer $newAccessToken';

        final response = await _dio.fetch(opts);

        // IMPORTANT:
        // Whatever the retried API returns, pass it back.
        // Do NOT logout here.
        handler.resolve(response);
      } catch (e) {
        // Do NOT call onUnauthorized here.
        //
        // This could be:
        // 400 validation error
        // 403
        // 404
        // server error
        //
        // It does NOT mean refresh token expired.
        handler.reject(e is DioException ? e : err);
      }

      return;
    }

    // ============================================================
    // START REFRESH
    // ============================================================

    _isRefreshing = true;
    _refreshCompleter = Completer<void>();

    try {
      final prefs = await SharedPreferences.getInstance();

      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        print('❌ REFRESH TOKEN NOT FOUND');

        throw Exception('Refresh token not found');
      }

      print('🔄 REFRESH TOKEN FOUND');
      print('🔄 Calling refresh API...');

      // ==========================================================
      // REFRESH API
      // ==========================================================

      Response refreshResponse;

      try {
        refreshResponse = await _dio.post(
          '${ApiEndpoints.baseUrlRider}${ApiEndpoints.authRefresh}',
          data: {'refreshToken': refreshToken},
          options: Options(
            headers: {'Authorization': null, 'Cookie': null},
            extra: {'skipAuth': true, 'skipRefresh': true},
          ),
        );
      } catch (e) {
        // ========================================================
        // REFRESH API FAILED
        // ========================================================

        print('❌ REFRESH API FAILED: $e');

        // ONLY HERE logout is allowed.
        onUnauthorized?.call();

        rethrow;
      }

      // ==========================================================
      // Check refresh response
      // ==========================================================

      final data = refreshResponse.data;

      final newAccessToken = data?['response']?['accessToken'] as String?;

      final newRefreshToken = data?['response']?['refreshToken'] as String?;

      if (newAccessToken == null || newAccessToken.isEmpty) {
        print('❌ REFRESH RESPONSE HAS NO ACCESS TOKEN');

        // Refresh was unsuccessful.
        onUnauthorized?.call();

        throw Exception('No access token in refresh response');
      }

      if (newRefreshToken == null || newRefreshToken.isEmpty) {
        print('❌ REFRESH RESPONSE HAS NO REFRESH TOKEN');

        // Refresh was unsuccessful.
        onUnauthorized?.call();

        throw Exception('No refresh token in refresh response');
      }

      print('✅ REFRESH API SUCCESS');
      print('✅ New access token received');
      print('✅ New refresh token received');

      // ==========================================================
      // SAVE BOTH TOKENS
      // ==========================================================

      await prefs.setString('access_token', newAccessToken);

      await prefs.setString('refresh_token', newRefreshToken);

      // ==========================================================
      // UPDATE CURRENT AUTHORIZATION
      // ==========================================================

      setBearerToken(newAccessToken);

      // ==========================================================
      // Notify waiting requests
      // ==========================================================

      if (!_refreshCompleter!.isCompleted) {
        _refreshCompleter!.complete();
      }

      // ==========================================================
      // RETRY ORIGINAL REQUEST
      // ==========================================================

      final opts = err.requestOptions;

      opts.headers['Authorization'] = 'Bearer $newAccessToken';

      print('🔁 RETRY ORIGINAL REQUEST');

      try {
        final retryResponse = await _dio.fetch(opts);

        // ========================================================
        // IMPORTANT
        //
        // The retry may return:
        //
        // 200 → success
        // 400 → validation error
        // 403 → permission error
        // 404 → not found
        //
        // None of these should logout the user.
        // ========================================================

        handler.resolve(retryResponse);
      } catch (retryError) {
        print('❌ RETRIED API FAILED: $retryError');

        // VERY IMPORTANT:
        // Do NOT call onUnauthorized().
        //
        // The refresh already succeeded.
        // This is an error from the original API.
        handler.reject(retryError is DioException ? retryError : err);
      }
    } catch (e) {
      print('❌ TOKEN REFRESH FAILED: $e');

      // DO NOT call onUnauthorized() here.
      //
      // Why?
      // The refresh API failure is already handled above.
      //
      // Calling it here again can cause duplicate logout.

      if (_refreshCompleter != null && !_refreshCompleter!.isCompleted) {
        _refreshCompleter!.completeError(e);
      }

      handler.reject(e is DioException ? e : err);
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }
  // ==================== AUTH CONFIGURATION ====================

  void setAuth(AuthConfig config) => _authConfig = config;

  void setBearerToken(String token) => _authConfig = AuthConfig.bearer(token);

  void setBasicAuth(String username, String password) =>
      _authConfig = AuthConfig.basic(username: username, password: password);

  void setApiKey(String key, {String headerName = 'X-API-Key'}) =>
      _authConfig = AuthConfig.apiKey(key, headerName: headerName);

  void setCustomAuth(String token, {required String prefix}) =>
      _authConfig = AuthConfig.custom(token, prefix: prefix);

  void clearAuth() => _authConfig = AuthConfig.none();

  void resetToDefaultAuth() => _authConfig = AuthConfig.basic(
    username: _defaultUsername,
    password: _defaultPassword,
  );

  // bool _shouldSkipTokenRefresh(RequestOptions options) {
  //   return options.extra['skipRefresh'] == true;
  // }

  // ==================== GETTERS ====================

  Dio get dio {
    if (!_isInitialized) init();
    return _dio;
  }

  AuthConfig get currentAuth => _authConfig;
  AuthType get currentAuthType => _authConfig.type;
  bool get isAuthenticated => _authConfig.type != AuthType.none;
}
