import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';


class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static const String _kReturnedContainersKey = 'swadishtt_returned_containers';

  static String get currentUserId => _auth.currentUser?.uid ?? 'guest_user_101';
  static User? get currentUser => _auth.currentUser;

  // Per-user isolated in-memory cache
  static final Map<String, List<Map<String, dynamic>>> _userOrdersMemory = {};

  /// Initialize Firestore persistence settings
  static Future<void> init() async {
    try {
      _db.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint('Firestore persistence initialized!');
    } catch (e) {
      debugPrint('Firestore init settings note: $e');
    }
  }

  // --- Authentication Methods ---

  /// Google Sign In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign In error: $e');
      rethrow;
    }
  }

  /// Email Sign Up
  static Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }

  /// Email Sign In
  static Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Link Phone Credential to existing account
  static Future<UserCredential?> linkPhoneCredential(AuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.linkWithCredential(credential);
      }
      return null;
    } catch (e) {
      debugPrint('Link phone error: $e');
      rethrow;
    }
  }

  /// Check if phone is already indexed by another user
  static Future<bool> isPhoneRegistered(String phone) async {
    try {
      final doc = await _db.collection('phone_index').doc(phone).get();
      return doc.exists;
    } catch (e) {
      debugPrint('Check phone index error: $e');
      return false;
    }
  }

  /// Synchronize Firestore Profile
  static Future<void> syncFirestoreProfile(User user, {String? phone}) async {
    final docRef = _db.collection('users').doc(user.uid);
    final userPhone = phone ?? user.phoneNumber;

    final data = {
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'phone': userPhone,
      'phoneVerified': userPhone != null,
      'photoUrl': user.photoURL,
      'provider': user.providerData.isNotEmpty ? user.providerData.first.providerId : 'email',
      'lastLogin': FieldValue.serverTimestamp(), // Consistent with checklist
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Use a batch to make phone indexing atomic with profile creation if possible
    final batch = _db.batch();
    batch.set(docRef, data, SetOptions(merge: true));

    if (userPhone != null) {
      final indexRef = _db.collection('phone_index').doc(userPhone);
      batch.set(indexRef, {
        'uid': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Logout and clear everything
  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accesco_logged_in');
    await prefs.remove('accesco_profile_completed');
    // Keep container IDs for now as they are "green points" local cache
  }

  /// Fetch local set of returned container order IDs
  static Future<Set<String>> getReturnedContainerIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kReturnedContainersKey) ?? [];
      return list.toSet();
    } catch (e) {
      return {};
    }
  }

  /// Save returned container ID locally
  static Future<void> saveReturnedContainerId(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_kReturnedContainersKey) ?? [];
      if (!list.contains(orderId.toString())) {
        list.add(orderId.toString());
        await prefs.setStringList(_kReturnedContainersKey, list);
      }
    } catch (e) {
      debugPrint('Error saving container locally: $e');
    }
  }

  /// Get Notification Preferences
  static Future<Map<String, dynamic>?> getNotificationPreferences({String type = 'notifications'}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _db.collection('users').doc(user.uid).collection('settings').doc(type).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching $type preferences: $e');
    }
    return null;
  }

  /// Update Notification Preferences
  static Future<void> updateNotificationPreferences(Map<String, dynamic> data, {String type = 'notifications'}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).collection('settings').doc(type).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating $type preferences: $e');
    }
  }

  /// Get Referral Data
  static Future<Map<String, dynamic>?> getReferralData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _db.collection('users').doc(user.uid).collection('settings').doc('referral').get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      debugPrint('Error fetching referral data: $e');
    }
    return null;
  }

  /// Update Referral Data
  static Future<void> updateReferralData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).collection('settings').doc('referral').set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating referral data: $e');
    }
  }

  /// Get initial demo orders bound to a specific user ID
  static List<Map<String, dynamic>> _getDefaultDemoOrders(String userId) {
    return [
      {
        'id': '99821',
        'orderNumber': 'Order #99821',
        'invoiceNumber': 'INV-2026-99821',
        'userId': userId,
        'restaurantName': 'Swad House Kitchen',
        'restaurantImage': 'assets/Swadishtt/spaghetti bolognese.png',
        'price': 348,
        'subtotal': 348,
        'taxAmount': 17,
        'deliveryFee': 25,
        'totalPaid': 390,
        'dateText': 'Just now',
        'groupSection': 'Today',
        'status': 'Preparing',
        'paymentMethod': 'Cash on Delivery',
        'containerReturned': false,
        'items': [
          {
            'name': 'Paneer Butter Masala',
            'quantity': 1,
            'price': 199,
            'image': 'assets/Swadishtt/burger.png',
          },
          {
            'name': 'Dal Makhani with Rice',
            'quantity': 1,
            'price': 149,
            'image': 'assets/Swadishtt/spaghetti bolognese.png',
          },
        ],
      },
      {
        'id': '12345',
        'orderNumber': 'Order #12345',
        'invoiceNumber': 'INV-2026-12345',
        'userId': userId,
        'restaurantName': 'Homely Bites',
        'restaurantImage': 'assets/Swadishtt/lemon herb roasted chicken.png',
        'price': 279,
        'subtotal': 279,
        'taxAmount': 14,
        'deliveryFee': 20,
        'totalPaid': 313,
        'dateText': 'Yesterday, 7:40 PM',
        'groupSection': 'Yesterday',
        'status': 'Delivered',
        'paymentMethod': 'UPI',
        'containerReturned': false,
        'items': [
          {
            'name': 'Special Thali Meal',
            'quantity': 1,
            'price': 279,
            'image': 'assets/Swadishtt/thali engine.png',
          },
        ],
      },
      {
        'id': '12110',
        'orderNumber': 'Order #12110',
        'invoiceNumber': 'INV-2026-12110',
        'userId': userId,
        'restaurantName': 'Biryani Hub',
        'restaurantImage': 'assets/Swadishtt/chicken.png',
        'price': 399,
        'subtotal': 399,
        'taxAmount': 20,
        'deliveryFee': 30,
        'totalPaid': 449,
        'dateText': '10 Jul, 1:15 PM',
        'groupSection': 'Yesterday',
        'status': 'Delivered',
        'paymentMethod': 'UPI',
        'containerReturned': false,
        'items': [
          {
            'name': 'Hyderabadi Chicken Biryani',
            'quantity': 1,
            'price': 399,
            'image': 'assets/Swadishtt/chicken.png',
          },
        ],
      },
    ];
  }

  /// Seed realistic demo orders into Firebase Firestore for current user
  static Future<void> seedDemoOrders() async {
    try {
      final userId = currentUserId;
      final querySnapshot = await _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        debugPrint('Firestore already has orders for user: $userId');
        return;
      }

      final demoOrders = _getDefaultDemoOrders(userId);
      final batch = _db.batch();
      for (final order in demoOrders) {
        final docRef = _db.collection('orders').doc('${userId}_${order['id']}');
        final dataWithDoc = Map<String, dynamic>.from(order);
        dataWithDoc['createdAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, dataWithDoc);
      }
      await batch.commit();
      debugPrint('Successfully seeded demo orders into Firestore for user: $userId');
    } catch (e) {
      debugPrint('Error seeding demo orders: $e');
    }
  }

  /// Get real-time stream of orders from Firestore with per-user persistent memory fallback
  static Stream<List<Map<String, dynamic>>> getOrdersStream() async* {
    final userId = currentUserId;
    final returnedIds = await getReturnedContainerIds();

    // Ensure per-user memory cache is initialized
    _userOrdersMemory.putIfAbsent(userId, () => _getDefaultDemoOrders(userId));
    final userList = _userOrdersMemory[userId]!;

    for (final item in userList) {
      if (returnedIds.contains(item['id'].toString())) {
        item['containerReturned'] = true;
      }
    }

    yield List<Map<String, dynamic>>.from(userList);

    try {
      await for (final snapshot in _db
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .snapshots()) {
        final firestoreDocs = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['docId'] = doc.id;
          final docOrderId = (data['id'] ?? doc.id).toString();
          if (returnedIds.contains(docOrderId) || data['containerReturned'] == true) {
            data['containerReturned'] = true;
            saveReturnedContainerId(docOrderId);
          }
          return data;
        }).toList();

        final mergedMap = <String, Map<String, dynamic>>{};
        for (final item in userList) {
          final itemId = item['id'].toString();
          if (returnedIds.contains(itemId)) {
            item['containerReturned'] = true;
          }
          mergedMap[itemId] = item;
        }
        for (final item in firestoreDocs) {
          final itemId = item['id'].toString();
          if (returnedIds.contains(itemId)) {
            item['containerReturned'] = true;
          }
          mergedMap[itemId] = item;
        }

        final resultList = mergedMap.values.toList();
        _userOrdersMemory[userId] = resultList;
        yield resultList;
      }
    } catch (e) {
      debugPrint('Firestore stream fallback to user local orders: $e');
      yield List<Map<String, dynamic>>.from(_userOrdersMemory[userId] ?? []);
    }
  }

  /// Create a new order via Cloud Function or direct Firestore write
  static Future<String> createOrder({
    required String restaurantName,
    required String restaurantImage,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'UPI',
    String? razorpayOrderId,
    String? transactionId,
  }) async {
    final userId = currentUserId;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final generatedOrderId = razorpayOrderId ?? timestamp.toString();

    try {
      try {
        final callable = _functions.httpsCallable('createOrder');
        final result = await callable.call({
          'restaurantName': restaurantName,
          'restaurantImage': restaurantImage,
          'items': items,
          'paymentMethod': paymentMethod,
          'razorpayOrderId': razorpayOrderId,
          'transactionId': transactionId,
        });

        final data = Map<String, dynamic>.from(result.data as Map);
        final orderId = data['orderId'] as String;

        // Update local memory for instant UI feedback
        _userOrdersMemory.putIfAbsent(userId, () => []);
        _userOrdersMemory[userId]!.insert(0, {
          'id': orderId,
          'orderNumber': data['orderNumber'],
          'invoiceNumber': data['invoiceNumber'],
          'userId': userId,
          'restaurantName': restaurantName,
          'restaurantImage': restaurantImage,
          'price': data['subtotal'],
          'subtotal': data['subtotal'],
          'taxAmount': data['taxAmount'],
          'deliveryFee': data['deliveryFee'],
          'totalPaid': data['totalPaid'],
          'dateText': 'Just now',
          'groupSection': 'Today',
          'status': 'Preparing',
          'paymentMethod': paymentMethod,
          'razorpayOrderId': razorpayOrderId,
          'transactionId': transactionId,
          'containerReturned': false,
          'items': items,
        });

        debugPrint('Order $orderId created via Cloud Function for $userId!');
        return orderId;
      } catch (cfError) {
        debugPrint('Cloud Function fallback to Firestore direct write: $cfError');
        final docId = '${userId}_$generatedOrderId';
        await _db.collection('orders').doc(docId).set({
          'id': generatedOrderId,
          'userId': userId,
          'restaurantName': restaurantName,
          'restaurantImage': restaurantImage,
          'items': items,
          'paymentMethod': paymentMethod,
          'razorpayOrderId': razorpayOrderId ?? generatedOrderId,
          'transactionId': transactionId ?? 'txn_$timestamp',
          'totalPaid': totalAmount,
          'status': 'Preparing',
          'containerReturned': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        _userOrdersMemory.putIfAbsent(userId, () => []);
        _userOrdersMemory[userId]!.insert(0, {
          'id': generatedOrderId,
          'orderNumber': 'Order #$generatedOrderId',
          'invoiceNumber': 'INV-${DateTime.now().year}-$generatedOrderId',
          'userId': userId,
          'restaurantName': restaurantName,
          'restaurantImage': restaurantImage,
          'price': totalAmount,
          'subtotal': totalAmount,
          'taxAmount': totalAmount * 0.05,
          'deliveryFee': 25.0,
          'totalPaid': totalAmount,
          'dateText': 'Just now',
          'groupSection': 'Today',
          'status': 'Preparing',
          'paymentMethod': paymentMethod,
          'razorpayOrderId': razorpayOrderId ?? generatedOrderId,
          'transactionId': transactionId ?? 'txn_$timestamp',
          'containerReturned': false,
          'items': items,
        });

        return generatedOrderId;
      }
    } catch (e) {
      debugPrint('Error creating order: $e');
      rethrow;
    }
  }

  /// Record a wallet transaction (Top-up, Order Payment, Refund)
  static Future<void> recordWalletTransaction({
    String? uid,
    String? userId,
    required double amount,
    required String type,
    String? title,
    String? description,
    String? orderId,
    String? transactionId,
    String? paymentId,
  }) async {
    final effectiveUserId = uid ?? userId ?? currentUserId;
    final effectiveTitle = description ?? title ?? (type == 'credit' ? 'Wallet Top-Up' : 'Order Payment');
    final effectiveTxId = paymentId ?? transactionId ?? 'txn_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final docRef = _db.collection('wallet_transactions').doc();
      await docRef.set({
        'id': docRef.id,
        'userId': effectiveUserId,
        'amount': amount,
        'type': type,
        'title': effectiveTitle,
        'description': effectiveTitle,
        'orderId': orderId ?? 'wallet_ord_${DateTime.now().millisecondsSinceEpoch}',
        'transactionId': effectiveTxId,
        'paymentId': effectiveTxId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Wallet transaction recorded in database: ${docRef.id}');
    } catch (e) {
      debugPrint('Error recording wallet transaction: $e');
    }
  }

  /// Stream live food items from Firestore collection
  static Stream<List<Map<String, dynamic>>> getFoodItemsStream() {
    return _db.collection('food_items').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Update container return status via Cloud Function
  static Future<void> updateContainerReturn(String orderId) async {
    final strId = orderId.toString();
    final userId = currentUserId;

    // 1. Update local memory cache immediately for responsive UI
    final userList = _userOrdersMemory[userId] ?? [];
    for (final order in userList) {
      if (order['id'].toString() == strId) {
        order['containerReturned'] = true;
      }
    }

    // 2. Persist locally
    await saveReturnedContainerId(strId);

    // 3. Call Cloud Function for server-side update & green points
    try {
      final callable = _functions.httpsCallable('returnContainer');
      await callable.call({'orderId': strId});
      debugPrint('Container return processed via Cloud Function & Green Points awarded!');
    } catch (e) {
      debugPrint('Error returning container via Cloud Function: $e');
    }
  }

  /// Submit packaging feedback via Cloud Function
  static Future<void> submitPackagingFeedback({
    required String orderId,
    required String selectedFeedback,
    required String comments,
  }) async {
    try {
      final callable = _functions.httpsCallable('submitFeedback');
      await callable.call({
        'orderId': orderId,
        'selectedFeedback': selectedFeedback,
        'comments': comments,
      });
      debugPrint('Packaging feedback submitted via Cloud Function!');
    } catch (e) {
      debugPrint('Error submitting packaging feedback: $e');
    }
  }

  /// Submit reported issue via Cloud Function (server calculates refund)
  static Future<void> submitReportedIssue({
    required String orderId,
    required String issueType,
    required List<String> selectedItems,
    required String details,
    required double refundAmount,
  }) async {
    try {
      final callable = _functions.httpsCallable('reportIssue');
      await callable.call({
        'orderId': orderId,
        'issueType': issueType,
        'selectedItems': selectedItems,
        'details': details,
      });
      debugPrint('Reported issue submitted via Cloud Function!');
    } catch (e) {
      debugPrint('Error submitting reported issue: $e');
    }
  }

  /// Save customized order item via Cloud Function
  static Future<void> saveCustomizedItem({
    required String itemName,
    required double basePrice,
    required List<Map<String, dynamic>> addOns,
    required String specialInstructions,
    required double totalPrice,
  }) async {
    try {
      final callable = _functions.httpsCallable('saveCustomizedItem');
      await callable.call({
        'itemName': itemName,
        'basePrice': basePrice,
        'addOns': addOns,
        'specialInstructions': specialInstructions,
        'totalPrice': totalPrice,
      });
      debugPrint('Customized order item saved via Cloud Function for $currentUserId!');
    } catch (e) {
      debugPrint('Error saving customized order item: $e');
    }
  }
}