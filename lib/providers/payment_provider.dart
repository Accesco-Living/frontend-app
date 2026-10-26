import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/payment_method_model.dart';

class PaymentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PaymentMethodModel> _paymentMethods = [];
  bool _isLoading = false;

  List<PaymentMethodModel> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;

  PaymentProvider() {
    Future.microtask(() => fetchPaymentMethods());
  }

  Future<void> fetchPaymentMethods() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .get();

      _paymentMethods = snapshot.docs
          .map((doc) => PaymentMethodModel.fromMap(doc.data(), doc.id))
          .toList();
          
      // Sort so default is at the top
      _paymentMethods.sort((a, b) {
        if (a.isDefault && !b.isDefault) return -1;
        if (!a.isDefault && b.isDefault) return 1;
        return 0;
      });
    } catch (e) {
      debugPrint('Error fetching payment methods: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addPaymentMethod(PaymentMethodModel method) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // If it's the first method, make it default automatically
      bool makeDefault = method.isDefault || _paymentMethods.isEmpty;
      
      if (makeDefault && _paymentMethods.isNotEmpty) {
        // Unset previous defaults
        for (var existing in _paymentMethods) {
          if (existing.isDefault) {
            await _firestore
                .collection('users')
                .doc(user.uid)
                .collection('payment_methods')
                .doc(existing.id)
                .update({'isDefault': false});
          }
        }
      }

      final data = method.toMap();
      data['isDefault'] = makeDefault;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .add(data);

      await Future.microtask(() => fetchPaymentMethods());
    } catch (e) {
      debugPrint('Error adding payment method: $e');
    }
  }

  Future<void> deletePaymentMethod(String methodId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .doc(methodId)
          .delete();

      await Future.microtask(() => fetchPaymentMethods());
    } catch (e) {
      debugPrint('Error deleting payment method: $e');
    }
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Set all to non-default
      for (var method in _paymentMethods) {
        if (method.isDefault) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('payment_methods')
              .doc(method.id)
              .update({'isDefault': false});
        }
      }

      // Set chosen one to default
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('payment_methods')
          .doc(methodId)
          .update({'isDefault': true});

      await Future.microtask(() => fetchPaymentMethods());
    } catch (e) {
      debugPrint('Error setting default payment method: $e');
    }
  }
}
