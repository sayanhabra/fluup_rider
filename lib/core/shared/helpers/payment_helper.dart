import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayPaymentHelper {
  RazorpayPaymentHelper({
    required this.onPaymentSuccess,
    required this.onPaymentError,
    this.onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _attachListeners();
  }

  late final Razorpay _razorpay;

  final void Function(PaymentSuccessResponse response) onPaymentSuccess;

  final void Function(PaymentFailureResponse response) onPaymentError;

  final void Function(ExternalWalletResponse response)? onExternalWallet;

  // ============================================================
  // ATTACH LISTENERS
  // ============================================================

  void _attachListeners() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    onPaymentSuccess(response);
  }

  void _handleError(PaymentFailureResponse response) {
    onPaymentError(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    onExternalWallet?.call(response);
  }

  // ============================================================
  // OPEN CHECKOUT
  //
  // IMPORTANT:
  // orderId should come from YOUR BACKEND.
  // Do not create the Razorpay order from Flutter.
  // ============================================================

  void openCheckout({
    required String keyId,
    required String orderId,
    required int amountInPaise,
    required String customerName,
    String? phone,
    String? email,
    String? description,
    String currency = 'INR',
    String businessName = 'Traders Terminal',
  }) {
    if (orderId.isEmpty) {
      throw ArgumentError('Razorpay orderId cannot be empty.');
    }

    if (amountInPaise <= 0) {
      throw ArgumentError('Payment amount must be greater than 0.');
    }

    final options = <String, dynamic>{
      'key': keyId,

      // Order created by your backend.
      'order_id': orderId,

      // Amount in smallest currency unit.
      // ₹500 = 50000 paise.
      'amount': amountInPaise,

      'currency': currency,

      'name': businessName,

      'description': description ?? 'Payment',

      'prefill': {
        'name': customerName,

        if (phone != null && phone.trim().isNotEmpty) 'contact': phone.trim(),

        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      },

      'theme': {'color': '#F9A825'},

      'retry': {'enabled': true, 'max_count': 3},

      'timeout': 300,

      'notes': {'source': 'flutter_app'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      throw Exception('Unable to open Razorpay checkout: $e');
    }
  }

  // ============================================================
  // DISPOSE
  //
  // Call from Screen dispose()
  // ============================================================

  void dispose() {
    _razorpay.clear();
  }
}





// Flutter App
//     │
//     │ amount / product ID
//     ▼
// Your Backend
//     │
//     │ Create Razorpay Order
//     ▼
// Returns order_id
//     │
//     ▼
// Flutter opens Razorpay Checkout
//     │
//     ▼
// PaymentSuccessResponse
//     │
//     │ payment_id
//     │ order_id
//     │ signature
//     ▼
// Your Backend
//     │
//     │ Verify Razorpay signature
//     │ Check/capture payment status
//     ▼
// Verified
//     │
//     ▼
// Mark order/payment successful