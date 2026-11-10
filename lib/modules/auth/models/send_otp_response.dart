import 'package:adm_rider/core/shared/const/next_step_enum.dart';

class SendOtpResponseData {
  final NextStep nextStep;
  final String challengeToken;
  final int expiresInSeconds;
  final int cooldownSeconds;

  const SendOtpResponseData({
    required this.nextStep,
    required this.challengeToken,
    required this.expiresInSeconds,
    required this.cooldownSeconds,
  });

  factory SendOtpResponseData.fromJson(Map<String, dynamic> json) {
    return SendOtpResponseData(
      nextStep: NextStep.fromString(json['nextStep'] as String?),
      challengeToken: json['challengeToken'] as String? ?? '',
      expiresInSeconds: _toInt(json['expiresInSeconds']) ?? 300,
      cooldownSeconds: _toInt(json['cooldownSeconds']) ?? 60,
    );
  }

  static int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? double.tryParse(val)?.toInt();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'nextStep': nextStep.value,
      'challengeToken': challengeToken,
      'expiresInSeconds': expiresInSeconds,
      'cooldownSeconds': cooldownSeconds,
    };
  }
}

class SendOtpResponse {
  final int statusCode;
  final String message;
  final SendOtpResponseData response;

  const SendOtpResponse({
    required this.statusCode,
    required this.message,
    required this.response,
  });

  factory SendOtpResponse.fromJson(Map<String, dynamic> json) {
    return SendOtpResponse(
      statusCode: json['statusCode'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      response: SendOtpResponseData.fromJson(
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
  String get challengeToken => response.challengeToken;
  int get expiresInSeconds => response.expiresInSeconds;
  int get cooldownSeconds => response.cooldownSeconds;
}
