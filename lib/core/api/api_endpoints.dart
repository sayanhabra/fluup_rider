class ApiEndpoints {
  static const String baseUrl = 'https://api.fluup.online/api/v1';
  static const String baseUrlRider = 'https://api.fluup.online/api/v1/rider';

  // ==================== RIDER AUTH ====================
  static const String checkPhoneNo = '/auth/check-phone';
  static const String sendOtp = '/auth/send-otp';
  static const String varifyOtp = '/auth/verify-otp';
  static const String authRefresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String authStatus = '/auth/status';
  static const String getProfile = '/auth/profile';
  static const String updateProfile = '/auth/profile';
  static const String strubmitVerification = '/auth/verification';

  // ==================== ORDER FULFILLMENT ====================
  static const String activeOrderFulfillment = '/order-fulfillment/active';
  static String orderNavigation(int orderId) => '/order-fulfillment/$orderId/navigation';
  static const String telemetryLocation = '/order-fulfillment/location';
  static const String riderAvailabilityStatus = '/order-fulfillment/status';
  static String respondOffer(int orderId) => '/order-fulfillment/$orderId/respond';
  static String arriveAtStore(int orderId) => '/order-fulfillment/$orderId/arrive-at-store';
  static String verifyPickup(int orderId) => '/order-fulfillment/$orderId/verify-pickup';
  static String arriveAtCustomer(int orderId) => '/order-fulfillment/$orderId/arrive-at-customer';
  static String completeDelivery(int orderId) => '/order-fulfillment/$orderId/complete-delivery';
  static String failDelivery(int orderId) => '/order-fulfillment/$orderId/fail-delivery';
  static String returnToStore(int orderId) => '/order-fulfillment/$orderId/return-to-store';
  static String cancelOrder(int orderId) => '/order-fulfillment/$orderId/cancel';

  // ==================== WALLET & EARNINGS ====================
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static const String walletWithdraw = '/wallet/withdraw';
  static const String walletWithdrawals = '/wallet/withdrawals';
  static const String walletPayoutAccount = '/wallet/payout-account';
  static const String walletSettlementHolds = '/wallet/settlement-holds';

  // ==================== NOTIFICATIONS ====================
  static const String notifications = '/notifications';
  static const String notificationsUnread = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationRead(int id) => '/notifications/$id/read';
  static String notificationDelete(int id) => '/notifications/$id';
}
