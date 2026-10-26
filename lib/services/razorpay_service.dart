import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Standard result wrapper for Razorpay transactions
class RazorpayPaymentResult {
  final bool success;
  final String? paymentId; // transaction_id
  final String? orderId;   // order_id
  final String? signature;
  final String? message;

  RazorpayPaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.message,
  });
}

class RazorpayService {
  static const String keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_TE4DcT026ESMjm',
  );

  /// Opens Razorpay checkout modal and returns payment result
  static Future<RazorpayPaymentResult> openPayment({
    required double amount,
    required String description,
    String? name,
    String? email,
    String? contact,
  }) async {
    final completer = Completer<RazorpayPaymentResult>();
    final razorpay = Razorpay();

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      if (!completer.isCompleted) {
        completer.complete(RazorpayPaymentResult(
          success: true,
          paymentId: response.paymentId,
          orderId: response.orderId ?? 'rzp_order_${DateTime.now().millisecondsSinceEpoch}',
          signature: response.signature,
        ));
      }
      razorpay.clear();
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      if (!completer.isCompleted) {
        completer.complete(RazorpayPaymentResult(
          success: false,
          message: response.message ?? 'Payment cancelled or failed',
        ));
      }
      razorpay.clear();
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      if (!completer.isCompleted) {
        completer.complete(RazorpayPaymentResult(
          success: true,
          paymentId: 'ext_wallet_${response.walletName}_${DateTime.now().millisecondsSinceEpoch}',
          orderId: 'rzp_order_${DateTime.now().millisecondsSinceEpoch}',
          message: response.walletName,
        ));
      }
      razorpay.clear();
    });

    final options = {
      'key': keyId,
      'amount': (amount * 100).round(), // Amount in paise
      'name': name ?? 'ACCESCO Living',
      'description': description,
      'timeout': 300, // 5 minutes
      'prefill': {
        'contact': contact ?? '9876543210',
        'email': email ?? 'user@accescoliving.com',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      razorpay.open(options);
    } catch (e) {
      debugPrint('Error launching Razorpay: $e');
      if (!completer.isCompleted) {
        completer.complete(RazorpayPaymentResult(
          success: false,
          message: 'Failed to launch payment gateway: $e',
        ));
      }
      razorpay.clear();
    }

    return completer.future;
  }

  /// Helper for callback-based Razorpay checkout
  static Future<void> openCheckout({
    required double amount,
    required String description,
    String? name,
    String? userEmail,
    String? userPhone,
    required Function(String paymentId, String orderId, String? signature) onSuccess,
    required Function(String code, String message) onFailure,
  }) async {
    final result = await openPayment(
      amount: amount,
      description: description,
      name: name,
      email: userEmail,
      contact: userPhone,
    );
    if (result.success) {
      onSuccess(
        result.paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
        result.orderId ?? 'ord_${DateTime.now().millisecondsSinceEpoch}',
        result.signature,
      );
    } else {
      onFailure('PAYMENT_ERROR', result.message ?? 'Payment failed');
    }
  }
}
