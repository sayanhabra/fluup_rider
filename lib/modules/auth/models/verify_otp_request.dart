import '../../../core/shared/helpers/client_security_helper.dart';

class VerifyOtpRequest {
  final String phone;
  final String code;
  final String? name;
  final String challengeToken;
  final String? deviceToken;
  final String? deviceId;
  final String botTrap;
  final String? clientSignature;

  const VerifyOtpRequest({
    required this.phone,
    required this.code,
    this.name,
    required this.challengeToken,
    this.deviceToken,
    this.deviceId,
    this.botTrap = '',
    this.clientSignature,
  });

  Map<String, dynamic> toJson() {
    final signature =
        clientSignature ?? ClientSecurityHelper.generateClientSignature(phone);
    return {
      'phone': phone,
      'code': code,
      'challengeToken': challengeToken,
      'clientSignature': signature,
      'botTrap': botTrap,
      if (name != null && name!.isNotEmpty) 'name': name,
      if (deviceToken != null && deviceToken!.isNotEmpty)
        'deviceToken': deviceToken,
      if (deviceId != null && deviceId!.isNotEmpty) 'deviceId': deviceId,
    };
  }

  @override
  String toString() =>
      'VerifyOtpRequest(phone: $phone, code: $code, name: $name, deviceToken: $deviceToken, deviceId: $deviceId, challengeToken: $challengeToken, botTrap: $botTrap, clientSignature: $clientSignature)';
}
