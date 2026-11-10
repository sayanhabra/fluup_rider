import 'dart:io';

import 'package:adm_rider/modules/auth/models/check_phone_response.dart';
import 'package:adm_rider/modules/auth/models/seller_profile_response.dart';
import 'package:adm_rider/modules/auth/models/send_otp_response.dart';
import 'package:adm_rider/modules/auth/models/set_profile_submit_response.dart';
import 'package:adm_rider/modules/auth/models/user_model.dart';
import 'package:adm_rider/modules/auth/models/verify_otp_request.dart';
import 'package:adm_rider/modules/auth/models/verify_otp_response.dart';
import 'package:adm_rider/modules/notifications/models/notification_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';
import 'api_endpoints.dart';
import 'api_handler.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  late final ApiHandler _handler;
  late final ApiClient _client;

  ApiService() {
    _client = ApiClient();
    _handler = ApiHandler(dio: _client.dio);
  }

  // ==================== AUTH CONFIG ====================

  void setBearerToken(String token) => _client.setBearerToken(token);
  void clearAuth() => _client.clearAuth();

  // ==================== SELLER AUTH ====================

  /// POST /seller/auth/check-phone
  Future<CheckPhoneResponse> checkPhone(String phoneNumber) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.checkPhoneNo}',
      data: {'phone': phoneNumber},
      contentType: RequestContentType.json,
      fromJson: (json) => CheckPhoneResponse.fromJson(json),
      errorMessage: 'Failed to check phone number',
    );
  }

  /// POST /seller/auth/send-otp
  /// [phone] is mandatory, [name] is optional (for new users)
  Future<SendOtpResponse> sendOtp({required String phone, String? name}) async {
    final data = {'phone': phone};
    if (name != null && name.isNotEmpty) {
      data['name'] = name;
    }

    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.sendOtp}',
      data: data,
      contentType: RequestContentType.json,
      fromJson: (json) => SendOtpResponse.fromJson(json),
      errorMessage: 'Failed to send OTP',
    );
  }

  /// POST /seller/auth/verify-otp
  Future<VerifyOtpResponse> verifyOtp(VerifyOtpRequest request) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.varifyOtp}',
      data: request.toJson(),
      contentType: RequestContentType.json,
      fromJson: (json) => VerifyOtpResponse.fromJson(json),
      errorMessage: 'Failed to verify OTP',
    );
  }

  /// POST /rider/auth/submit-verification (or relevant endpoint path)
  Future<SetProfileSubmitResponse> setProfile({
    required Map<String, dynamic> data,
    required File documentFront,
    File? documentBack,
    required File selfie,
    required File drivingLicenseDocument,
  }) async {
    final Map<String, dynamic> formDataMap = {
      ...data,
      'documentFront': await MultipartFile.fromFile(
        documentFront.path,
        filename: documentFront.path.split('/').last,
      ),
      if (documentBack != null)
        'documentBack': await MultipartFile.fromFile(
          documentBack.path,
          filename: documentBack.path.split('/').last,
        ),
      'selfie': await MultipartFile.fromFile(
        selfie.path,
        filename: selfie.path.split('/').last,
      ),
      'drivingLicenseDocument': await MultipartFile.fromFile(
        drivingLicenseDocument.path,
        filename: drivingLicenseDocument.path.split('/').last,
      ),
    };

    final formData = FormData.fromMap(formDataMap);

    return _handler.post(
      // REPLACE with your actual endpoint from ApiEndpoints
      endpoint:
          '${ApiEndpoints.baseUrlRider}${ApiEndpoints.strubmitVerification}',
      data: formData,
      contentType:
          RequestContentType.multipart, // Ensure your ApiHandler supports this
      fromJson: (json) => SetProfileSubmitResponse.fromJson(json),
      errorMessage: 'Failed to submit verification',
    );
  }

  /// POST /seller/auth/refresh
  Future<BaseResponseModel> refreshToken(String refreshToken) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.authRefresh}',
      data: {'refreshToken': refreshToken},
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to refresh token',
    );
  }

  /// POST /seller/auth/logout
  Future logout() async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.logout}',
      data: {},
      contentType: RequestContentType.json,
      extra: {'skipAuth': false, 'skipRefresh': true},
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Logout failed',
    );
  }

  /// GET /seller/auth/status
  Future<BaseResponseModel> getAuthStatus() async {
    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.authStatus}',
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to get auth status',
    );
  }

  /// GET /seller/auth/profile
  Future<UserModel> getProfileAsUser() async {
    final response = await _handler.get<BaseResponseModel>(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.getProfile}',
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to get profile',
    );

    // Extract user data from the response
    final responseData = response.data;
    if (responseData is Map) {
      final responseObj = responseData['response'];
      if (responseObj is Map) {
        return UserModel.fromJson(responseObj as Map<String, dynamic>);
      }

      return UserModel.fromJson(responseData as Map<String, dynamic>);
    }

    throw Exception('Invalid profile response format');
  }

  /// PUT /seller/auth/profile
  Future<SellerProfileResponse> updateProfile(Map<String, dynamic> data) async {
    return _handler.put(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.updateProfile}',
      data: data,
      contentType: RequestContentType.json,
      fromJson: (json) => SellerProfileResponse.fromJson(json),
      errorMessage: 'Failed to update profile',
    );
  }

  /// PATCH /seller/auth/profile-image
  Future<BaseResponseModel> updateProfileImage(String imageFilePath) async {
    return _handler.uploadFile(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.profileImage}',
      filePath: imageFilePath,
      fileKey: 'profile_image',
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to update profile image',
    );
  }

  /// POST /seller/auth/profile/documents
  Future<BaseResponseModel> uploadProfileDocument(
    String filePath, {
    String fileKey = 'document',
    Map<String, dynamic>? extraData,
  }) async {
    return _handler.uploadFile(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.profileDocs}',
      filePath: filePath,
      fileKey: fileKey,
      additionalData: extraData,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to upload document',
    );
  }

  /// PATCH /seller/auth/stores-status
  Future<BaseResponseModel> toggleStoreStatus(bool isOpen) async {
    return _handler.patch(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.storeStatus}',
      data: {'is_open': isOpen},
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to toggle store status',
    );
  }

  // ==================== NOTIFICATIONS ====================

  /// GET /api/v1/notifications
  /// List notifications for the current user (paginated).
  Future<GetNotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.notifications}',
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (json) => GetNotificationListResponse.fromJson(json),
      errorMessage: 'Failed to load notifications',
    );
  }

  /// GET /api/v1/notifications/unread-count
  Future<UnreadCountNotificationResponse> getUnreadCount() async {
    return _handler.get(
      endpoint:
          '${ApiEndpoints.baseUrlRider}${ApiEndpoints.notificationsUnread}',
      fromJson: (json) => UnreadCountNotificationResponse.fromJson(json),
      errorMessage: 'Failed to load unread count',
    );
  }

  /// PATCH /api/v1/notifications/read-all
  Future<MakeAllNotificationAsReadResponse> markAllNotificationsAsRead() async {
    return _handler.patch(
      endpoint:
          '${ApiEndpoints.baseUrlRider}${ApiEndpoints.notificationsReadAll}',
      data: {},
      contentType: RequestContentType.json,
      fromJson: (json) => MakeAllNotificationAsReadResponse.fromJson(json),
      errorMessage: 'Failed to mark all as read',
    );
  }

  /// PATCH /api/v1/notifications/{id}/read
  Future<MakeSingleNotificationAsReadResponse> markNotificationAsRead(
    int id,
  ) async {
    return _handler.patch(
      endpoint:
          '${ApiEndpoints.baseUrlRider}${ApiEndpoints.notifications}/$id/read',
      data: {},
      contentType: RequestContentType.json,
      fromJson: (json) => MakeSingleNotificationAsReadResponse.fromJson(json),
      errorMessage: 'Failed to mark notification as read',
    );
  }

  /// DELETE /api/v1/notifications/{id}
  Future<DeleteNotificationResponse> deleteNotification(int id) async {
    return _handler.delete(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.notifications}/$id',
      fromJson: (json) => DeleteNotificationResponse.fromJson(json),
      errorMessage: 'Failed to delete notification',
    );
  }
}

class BaseResponseModel {
  final bool? success;
  final String? message;
  final dynamic data;
  final int? statusCode;

  BaseResponseModel({this.success, this.message, this.data, this.statusCode});

  factory BaseResponseModel.fromJson(Map<String, dynamic> json) {
    return BaseResponseModel(
      success: json['success'] ?? json['status'] == 'success',
      message: json['message'] ?? json['msg'] ?? json['detail'],
      data: json['data'] ?? json,
      statusCode: json['status_code'] ?? json['code'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'status_code': statusCode,
    };
  }
}
