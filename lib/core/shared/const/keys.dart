class Keys {
  // Razorpay
  static const RAZORPAY_KEY = "rzp_test_BxCwMXwNYYKq1S";
  static const RAZORPAY_SECRET = "Z05FOb0krbQhfpJa3tnYFOT8";
  // -- Auth Token --
  static const LOCAl_AUTH_TOKEN_KEY = "auth_token";

  static const HIVE_USER_BOX = "hive_user_box";

  // Pre-shared HMAC client secret for auth clientSignature
  static const String CLIENT_SIGNATURE_SECRET = String.fromEnvironment(
    'OTP_CLIENT_SIGNATURE_SECRET',
    defaultValue: '26c59fa81742e9b891b2c45d6e7f8a9b0c1d2e3f4a5b6c7d8e94338a',
  );

  // static const USER_TYPE = "USER_TYPE_VENDOR";
  //  USER_TYPE_VENDOR   ,    USER_TYPE_RIDER
}
