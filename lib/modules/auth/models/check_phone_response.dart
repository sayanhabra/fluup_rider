import 'package:adm_rider/core/shared/const/next_step_enum.dart';

class CheckPhoneResponse {
  final int statusCode;
  final String message;
  final NextStep nextStep;
  final String? challengeToken;
  final int? expiresInSeconds;
  final int? cooldownSeconds;

  const CheckPhoneResponse({
    required this.statusCode,
    required this.message,
    required this.nextStep,
    this.challengeToken,
    this.expiresInSeconds,
    this.cooldownSeconds,
  });

  factory CheckPhoneResponse.fromJson(Map<String, dynamic> json) {
    final responseData = json['response'] as Map<String, dynamic>?;
    return CheckPhoneResponse(
      statusCode: json['statusCode'] as int? ?? 0,
      message: json['message'] as String? ?? '',
      nextStep: NextStep.fromString(responseData?['nextStep'] as String?),
      challengeToken: responseData?['challengeToken'] as String?,
      expiresInSeconds: _toInt(responseData?['expiresInSeconds']),
      cooldownSeconds: _toInt(responseData?['cooldownSeconds']),
    );
  }

  static int? _toInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String)
      return int.tryParse(val) ?? double.tryParse(val)?.toInt();
    return null;
  }

  bool get isSuccess => statusCode == 200;
  bool get isNewUser => nextStep.isEnterName;
  bool get isExistingUser => nextStep.isOtpVerification;
}
