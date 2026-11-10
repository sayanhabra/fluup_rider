class VerifyOtpRequest {
  final String phone;
  final String code;
  final String? name;
  final String challengeToken;
  final String? deviceToken;
  final String? deviceId;

  const VerifyOtpRequest({
    required this.phone,
    required this.code,
    this.name,
    required this.challengeToken,
    this.deviceToken,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'code': code,
      if (name != null && name!.isNotEmpty) 'name': name,
      if (deviceToken != null && deviceToken!.isNotEmpty)
        'deviceToken': deviceToken,
      if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
      'challengeToken': challengeToken,
    };
  }

  @override
  String toString() =>
      'VerifyOtpRequest(phone: $phone, code: $code, name: $name, deviceToken: $deviceToken, deviceId: $deviceId, challengeToken: $challengeToken)';
}
