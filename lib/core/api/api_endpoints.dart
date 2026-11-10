class ApiEndpoints {
  // static const String baseUrl = 'https://api.fluup.online/api/v1';

  static const String baseUrlRider = 'https://api.fluup.online/api/v1/rider';

  //==================seller =============================
  //auth
  static const String checkPhoneNo = '/auth/check-phone';
  static const String sendOtp = '/auth/send-otp';
  static const String varifyOtp = '/auth/verify-otp';
  static const String authRefresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String authStatus = '/auth/status';
  static const String getProfile = '/auth/profile';
  static const String updateProfile = '/auth/profile';
  static const String profileImage = '/auth/profile-image';
  static const String profileDocs = '/auth/profile/documents';
  static const String storeStatus = '/auth/stores-status';
  static const String strubmitVerification = '/auth/verification';

  // ================= NOTIFICATION =================

  static const notifications = '/notifications';
  static const notificationsUnread = '/notifications/unread-count';
  static const notificationsReadAll = '/notifications/read-all';
}
