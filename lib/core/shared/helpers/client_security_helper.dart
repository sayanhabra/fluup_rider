import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../const/keys.dart';

class ClientSecurityHelper {
  /// Normalizes an Indian phone number to 10 digits, matching backend [normalizeIndianPhone].
  ///
  /// Examples:
  /// - `+919876543210` -> `9876543210`
  /// - `9876543210`    -> `9876543210`
  /// - `09876543210`   -> `9876543210`
  static String normalizeIndianPhone(String phone) {
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    }

    return digits;
  }

  /// Generates the HMAC-SHA256 signature of the normalized phone number.
  /// Uses [Keys.CLIENT_SIGNATURE_SECRET] by default, or an optionally provided [secret].
  static String generateClientSignature(String phone, [String? secret]) {
    final key = secret ?? Keys.CLIENT_SIGNATURE_SECRET;
    final normalized = normalizeIndianPhone(phone);
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(normalized));
    return digest.toString();
  }
}
