import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address.dart';

class AddressProvider with ChangeNotifier {
  List<AddressModel> _addresses = [];
  bool _isLoading = false;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;

  AddressProvider() {
    fetchAddresses();
  }

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? 'guest_user_101';

  Future<void> fetchAddresses() async {
    final uid = currentUserId;
    _isLoading = true;
    notifyListeners();

    // 1. Load local cache first for instant UI response & offline resilience
    await _loadLocalAddresses(uid);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final remoteAddresses = snapshot.docs
            .map((doc) => AddressModel.fromMap(doc.id, doc.data()))
            .toList();

        _addresses = remoteAddresses;
        _sortAddresses();
        await _saveLocalAddresses(uid);
      }
    } catch (e) {
      debugPrint('Firestore fetchAddresses notice: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _sortAddresses() {
    _addresses.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return 0;
    });
  }

  Future<void> _loadLocalAddresses(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('local_addresses_$uid') ?? [];
      if (jsonList.isNotEmpty) {
        _addresses = jsonList
            .map((str) => AddressModel.fromMap(
                jsonDecode(str)['id'], jsonDecode(str) as Map<String, dynamic>))
            .toList();
        _sortAddresses();
      } else if (_addresses.isEmpty) {
        // Default seed address
        _addresses = [
          AddressModel(
            id: 'addr_default_1',
            type: 'Home',
            fullAddress: '#42, Koramangala 5th Block, Bengaluru, KAR',
            isDefault: true,
          ),
        ];
        await _saveLocalAddresses(uid);
      }
    } catch (e) {
      debugPrint('Error loading local addresses: $e');
    }
  }

  Future<void> _saveLocalAddresses(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _addresses.map((a) => jsonEncode({
        'id': a.id,
        'type': a.type,
        'fullAddress': a.fullAddress,
        'isDefault': a.isDefault,
      })).toList();
      await prefs.setStringList('local_addresses_$uid', jsonList);
    } catch (e) {
      debugPrint('Error saving local addresses: $e');
    }
  }

  Future<void> addAddress(String type, String fullAddress, {bool setAsDefault = false}) async {
    final uid = currentUserId;
    final isDefault = setAsDefault || _addresses.isEmpty;

    if (isDefault) {
      for (var a in _addresses) {
        a.isDefault = false;
      }
    }

    final newId = 'addr_${DateTime.now().millisecondsSinceEpoch}';
    final newAddress = AddressModel(
      id: newId,
      type: type,
      fullAddress: fullAddress,
      isDefault: isDefault,
    );

    _addresses.insert(0, newAddress);
    _sortAddresses();
    notifyListeners();

    await _saveLocalAddresses(uid);

    try {
      if (isDefault) {
        final batch = FirebaseFirestore.instance.batch();
        final defaultQuery = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('addresses')
            .where('isDefault', isEqualTo: true)
            .get();

        for (var doc in defaultQuery.docs) {
          batch.update(doc.reference, {'isDefault': false});
        }
        await batch.commit();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(newId)
          .set(newAddress.toMap());
    } catch (e) {
      debugPrint('Notice saving address to Firestore: $e');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    final uid = currentUserId;
    _addresses.removeWhere((a) => a.id == addressId);

    if (_addresses.isNotEmpty && !_addresses.any((a) => a.isDefault)) {
      _addresses.first.isDefault = true;
    }

    notifyListeners();
    await _saveLocalAddresses(uid);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .doc(addressId)
          .delete();
    } catch (e) {
      debugPrint('Notice deleting address from Firestore: $e');
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    final uid = currentUserId;
    for (var a in _addresses) {
      a.isDefault = (a.id == addressId);
    }
    _sortAddresses();
    notifyListeners();

    await _saveLocalAddresses(uid);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final allAddresses = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('addresses')
          .get();

      for (var doc in allAddresses.docs) {
        batch.update(doc.reference, {
          'isDefault': doc.id == addressId,
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Notice setting default address in Firestore: $e');
    }
  }
}
