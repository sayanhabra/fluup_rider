// features/auth/models/verify_otp_response.dart

import 'package:adm_rider/core/shared/const/next_step_enum.dart';

import 'user_model.dart';

class VerifyOtpResponseData {
  final String accessToken;
  final String refreshToken;
  final NextStep nextStep;
  final UserModel user;

  const VerifyOtpResponseData({
    required this.accessToken,
    required this.refreshToken,
    required this.nextStep,
    required this.user,
  });

  factory VerifyOtpResponseData.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponseData(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      nextStep: NextStep.fromString(json['nextStep'] as String?),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'nextStep': nextStep.value,
      'user': user.toJson(),
    };
  }
}

class VerifyOtpResponse {
  final int statusCode;
  final String message;
  final VerifyOtpResponseData response;

  const VerifyOtpResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      statusCode: json['statusCode'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      response: VerifyOtpResponseData.fromJson(
        json['response'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'statusCode': statusCode,
      'message': message,
      'response': response.toJson(),
    };
  }

  bool get isSuccess => statusCode == 200;

  String get accessToken => response.accessToken;

  String get refreshToken => response.refreshToken;

  NextStep get nextStep => response.nextStep;

  UserModel get user => response.user;
}
