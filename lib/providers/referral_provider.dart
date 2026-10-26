import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class ReferralEntry {
  final String initials;
  final String name;
  final String status;
  final String reward;

  const ReferralEntry({
    required this.initials,
    required this.name,
    required this.status,
    required this.reward,
  });

  Map<String, dynamic> toMap() {
    return {
      'initials': initials,
      'name': name,
      'status': status,
      'reward': reward,
    };
  }

  factory ReferralEntry.fromMap(Map<String, dynamic> map) {
    return ReferralEntry(
      initials: map['initials'] ?? '',
      name: map['name'] ?? '',
      status: map['status'] ?? '',
      reward: map['reward'] ?? '',
    );
  }
}

class ReferralProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  int completedInvites = 1;
  final int targetInvites = 10;
  String referralCode = 'AC7K9L2';
  double earnedAmount = 450;
  bool isRedeemed = false;
  List<ReferralEntry> recentReferrals = [];

  ReferralProvider() {
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    final data = await FirebaseService.getReferralData();
    if (data != null) {
      completedInvites = data['completedInvites'] ?? 1;
      referralCode = data['referralCode'] ?? 'AC7K9L2';
      earnedAmount = (data['earnedAmount'] ?? 450.0).toDouble();
      isRedeemed = data['isRedeemed'] ?? false;
      if (data['recentReferrals'] != null) {
        recentReferrals = (data['recentReferrals'] as List).map((e) => ReferralEntry.fromMap(e as Map<String, dynamic>)).toList();
      }
    } else {
      // Setup initial data if missing in backend
      completedInvites = 1;
      earnedAmount = 450.0;
      isRedeemed = false;
      recentReferrals = [
        const ReferralEntry(
          initials: 'PS',
          name: 'Priya S.',
          status: 'Completed',
          reward: '+₹100',
        ),
        const ReferralEntry(
          initials: 'RK',
          name: 'Ravi K.',
          status: 'Completed',
          reward: '+₹100',
        ),
      ];
      await _saveData();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveData() async {
    await FirebaseService.updateReferralData({
      'completedInvites': completedInvites,
      'referralCode': referralCode,
      'earnedAmount': earnedAmount,
      'isRedeemed': isRedeemed,
      'recentReferrals': recentReferrals.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> inviteFriend() async {
    if (completedInvites < targetInvites) {
      completedInvites++;
      earnedAmount += 50.0;
      recentReferrals.insert(0, ReferralEntry(
        initials: 'F$completedInvites',
        name: 'Friend $completedInvites',
        status: 'Completed',
        reward: '+₹50',
      ));
      notifyListeners();
      await _saveData();
    }
  }

  Future<void> redeemNow() async {
    if (!isRedeemed) {
      isRedeemed = true;
      notifyListeners();
      await _saveData();
    }
  }
}
