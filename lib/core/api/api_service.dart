import 'dart:io';

import 'package:adm_rider/modules/auth/models/check_phone_response.dart';
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

  ApiService({ApiHandler? apiHandler}) {
    _client = ApiClient();
    _handler = apiHandler ?? ApiHandler(dio: _client.dio);
  }

  // ==================== AUTH CONFIG ====================

  void setBearerToken(String token) => _client.setBearerToken(token);
  void clearAuth() => _client.clearAuth();

  // ==================== RIDER AUTH ====================

  /// POST /rider/auth/check-phone
  Future<CheckPhoneResponse> checkPhone(String phoneNumber) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.checkPhoneNo}',
      data: {'phone': phoneNumber},
      contentType: RequestContentType.json,
      fromJson: (json) => CheckPhoneResponse.fromJson(json),
      errorMessage: 'Failed to check phone number',
    );
  }

  /// POST /rider/auth/send-otp
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

  /// POST /rider/auth/verify-otp
  Future<VerifyOtpResponse> verifyOtp(VerifyOtpRequest request) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.varifyOtp}',
      data: request.toJson(),
      contentType: RequestContentType.json,
      fromJson: (json) => VerifyOtpResponse.fromJson(json),
      errorMessage: 'Failed to verify OTP',
    );
  }

  /// POST /rider/auth/verification
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
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.strubmitVerification}',
      data: formData,
      contentType: RequestContentType.multipart,
      fromJson: (json) => SetProfileSubmitResponse.fromJson(json),
      errorMessage: 'Failed to submit verification',
    );
  }

  /// POST /rider/auth/refresh
  Future<BaseResponseModel> refreshToken(String refreshToken) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.authRefresh}',
      data: {'refreshToken': refreshToken},
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to refresh token',
    );
  }

  /// POST /rider/auth/logout
  Future<BaseResponseModel> logout() async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.logout}',
      data: {},
      contentType: RequestContentType.json,
      extra: {'skipAuth': false, 'skipRefresh': true},
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Logout failed',
    );
  }

  /// GET /rider/auth/status
  Future<BaseResponseModel> getAuthStatus() async {
    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.authStatus}',
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to get auth status',
    );
  }

  /// GET /rider/auth/profile
  Future<UserModel> getProfileAsUser() async {
    final response = await _handler.get<BaseResponseModel>(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.getProfile}',
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to get profile',
    );

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

  /// PATCH /rider/auth/profile
  Future<BaseResponseModel> updateRiderProfile(Map<String, dynamic> data) async {
    return _handler.patch(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.updateProfile}',
      data: data,
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to update rider profile',
    );
  }

  // ==================== ORDER FULFILLMENT ====================

  /// PATCH /rider/order-fulfillment/location
  Future<BaseResponseModel> updateRiderLocation({
    required double latitude,
    required double longitude,
    int? batteryLevel,
  }) async {
    return _handler.patch(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.telemetryLocation}',
      data: {
        'latitude': latitude,
        'longitude': longitude,
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
      },
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to update location',
    );
  }

  /// PATCH /rider/order-fulfillment/status
  Future<BaseResponseModel> updateRiderStatus(
    String status, {
    double? latitude,
    double? longitude,
    int? batteryLevel,
  }) async {
    return _handler.patch(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.riderAvailabilityStatus}',
      data: {
        'status': status,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
      },
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to update status',
    );
  }

  /// GET /rider/order-fulfillment/active
  /// Retrieves the current rider active state & ongoing ride details.
  /// Single source of truth for the rider app.
  Future<BaseResponseModel> getActiveOrderFulfillment() async {
    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.activeOrderFulfillment}',
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to retrieve active order fulfillment state',
    );
  }

  /// GET /rider/order-fulfillment/{orderId}/navigation
  /// Computes Routes API two-wheeler route polylines, ETAs, and turn-by-turn maneuvers
  /// for Rider -> Store (pickup), Rider/Store -> Customer (delivery), or Customer -> Store (return).
  Future<BaseResponseModel> getOrderNavigation(
    int orderId, {
    String? leg,
    double? riderLat,
    double? riderLng,
  }) async {
    final queryParams = <String, dynamic>{
      if (leg != null && leg.isNotEmpty) 'leg': leg,
      if (riderLat != null) 'riderLat': riderLat,
      if (riderLng != null) 'riderLng': riderLng,
    };

    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.orderNavigation(orderId)}',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to retrieve navigation route',
    );
  }

  /// POST /rider/order-fulfillment/{orderId}/respond
  Future<BaseResponseModel> respondOffer({
    required int orderId,
    required String response,
    String? rejectionReason,
  }) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.respondOffer(orderId)}',
      data: {
        'response': response,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      },
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to respond to offer',
    );
  }

  /// POST /rider/order-fulfillment/{orderId}/arrive-at-store
  Future<BaseResponseModel> arriveAtStore({
    required int orderId,
    required double latitude,
    required double longitude,
  }) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.arriveAtStore(orderId)}',
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to record arrival at store',
    );
  }

  /// POST /rider/order-fulfillment/{orderId}/verify-pickup
  Future<BaseResponseModel> verifyPickup({
    required int orderId,
    required String otp,
    required double latitude,
    required double longitude,
  }) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.verifyPickup(orderId)}',
      data: {
        'otp': otp,
        'latitude': latitude,
        'longitude': longitude,
      },
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to verify store pickup OTP',
    );
  }

  /// POST /rider/order-fulfillment/{orderId}/arrive-at-customer
  Future<BaseResponseModel> arriveAtCustomer({
    required int orderId,
    required double latitude,
    required double longitude,
  }) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.arriveAtCustomer(orderId)}',
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to record arrival at customer',
    );
  }

  /// POST /rider/order-fulfillment/{orderId}/complete-delivery
  Future<BaseResponseModel> completeDelivery({
    required int orderId,
    required String deliveryOtp,
    required bool isAgeVerified,
    String verificationMethod = 'OTP_ONLY',
    String? verifiedDocumentType,
  }) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.completeDelivery(orderId)}',
      data: {
        'deliveryOtp': deliveryOtp,
        'isAgeVerified': isAgeVerified,
        'verificationMethod': verificationMethod,
        if (verifiedDocumentType != null) 'verifiedDocumentType': verifiedDocumentType,
      },
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to complete delivery',
    );
  }

  /// POST /rider/order-fulfillment/{orderId}/fail-delivery
  Future<BaseResponseModel> failDelivery({
    required int orderId,
    required String reason,
    required String failureType,
    String? notes,
  }) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.failDelivery(orderId)}',
      data: {
        'reason': reason,
        'failureType': failureType,
        if (notes != null) 'notes': notes,
      },
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to report delivery failure',
    );
  }

  /// POST /rider/order-fulfillment/{orderId}/return-to-store
  Future<BaseResponseModel> returnToStore(int orderId) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.returnToStore(orderId)}',
      data: {},
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to confirm return to store',
    );
  }

  // ==================== WALLET & EARNINGS ====================

  /// GET /rider/wallet
  Future<BaseResponseModel> getRiderWallet() async {
    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.wallet}',
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to load wallet',
    );
  }

  /// GET /rider/wallet/transactions
  Future<BaseResponseModel> getRiderTransactions({
    int page = 1,
    int limit = 20,
    String? transactionType,
    String? startDate,
    String? endDate,
  }) async {
    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.walletTransactions}',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (transactionType != null) 'transactionType': transactionType,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      },
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to load wallet transactions',
    );
  }

  /// POST /rider/wallet/withdraw
  Future<BaseResponseModel> withdrawWallet({
    required int amount,
    required String payoutMethod,
    String? bankAccountNumber,
    String? ifscCode,
    String? bankAccountName,
    String? upiId,
  }) async {
    return _handler.post(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.walletWithdraw}',
      data: {
        'amount': amount,
        'payoutMethod': payoutMethod,
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        if (ifscCode != null) 'ifscCode': ifscCode,
        if (bankAccountName != null) 'bankAccountName': bankAccountName,
        if (upiId != null) 'upiId': upiId,
      },
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to initiate withdrawal',
    );
  }

  /// GET /rider/wallet/withdrawals
  Future<BaseResponseModel> getRiderWithdrawals({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.walletWithdrawals}',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to load withdrawals',
    );
  }

  /// PATCH /rider/wallet/payout-account
  Future<BaseResponseModel> updatePayoutAccount({
    String? bankAccountNumber,
    String? ifscCode,
    String? bankAccountName,
    String? upiId,
  }) async {
    return _handler.patch(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.walletPayoutAccount}',
      data: {
        if (bankAccountNumber != null) 'bankAccountNumber': bankAccountNumber,
        if (ifscCode != null) 'ifscCode': ifscCode,
        if (bankAccountName != null) 'bankAccountName': bankAccountName,
        if (upiId != null) 'upiId': upiId,
      },
      contentType: RequestContentType.json,
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to update payout account',
    );
  }

  /// GET /rider/wallet/settlement-holds
  Future<BaseResponseModel> getSettlementHolds({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrlRider}${ApiEndpoints.walletSettlementHolds}',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
      fromJson: (json) => BaseResponseModel.fromJson(json),
      errorMessage: 'Failed to load settlement holds',
    );
  }

  // ==================== NOTIFICATIONS ====================

  /// GET /api/v1/notifications
  Future<GetNotificationListResponse> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrl}${ApiEndpoints.notifications}',
      queryParameters: {'page': page, 'limit': limit},
      fromJson: (json) => GetNotificationListResponse.fromJson(json),
      errorMessage: 'Failed to load notifications',
    );
  }

  /// GET /api/v1/notifications/unread-count
  Future<UnreadCountNotificationResponse> getUnreadCount() async {
    return _handler.get(
      endpoint: '${ApiEndpoints.baseUrl}${ApiEndpoints.notificationsUnread}',
      fromJson: (json) => UnreadCountNotificationResponse.fromJson(json),
      errorMessage: 'Failed to load unread count',
    );
  }

  /// PATCH /api/v1/notifications/read-all
  Future<MakeAllNotificationAsReadResponse> markAllNotificationsAsRead() async {
    return _handler.patch(
      endpoint: '${ApiEndpoints.baseUrl}${ApiEndpoints.notificationsReadAll}',
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
      endpoint: '${ApiEndpoints.baseUrl}${ApiEndpoints.notificationRead(id)}',
      data: {},
      contentType: RequestContentType.json,
      fromJson: (json) => MakeSingleNotificationAsReadResponse.fromJson(json),
      errorMessage: 'Failed to mark notification as read',
    );
  }

  /// DELETE /api/v1/notifications/{id}
  Future<DeleteNotificationResponse> deleteNotification(int id) async {
    return _handler.delete(
      endpoint: '${ApiEndpoints.baseUrl}${ApiEndpoints.notificationDelete(id)}',
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
      data: json['data'] ?? json['response'] ?? json,
      statusCode: json['status_code'] ?? json['statusCode'] ?? json['code'],
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
