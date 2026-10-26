import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/monthyl_expense.dart';
import '../models/store_spend.dart';
import '/utils/app_colors.dart';

class CategoryItem {
  final String label;
  final double amount;
  final double percent;
  final Color color;

  CategoryItem({
    required this.label,
    required this.amount,
    required this.percent,
    required this.color,
  });
}

class ExpenseProvider extends ChangeNotifier {
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String _selectedMonth = DateFormat('MMMM yyyy').format(DateTime.now());
  String get selectedMonth => _selectedMonth;

  Map<String, MonthlyExpenseData> _monthlyData = {};
  Map<String, List<Map<String, dynamic>>> _dailySpendByMonth = {};

  List<String> get availableMonths => _monthlyData.keys.toList();

  double _monthlyBudget = 18000.0;
  double get monthlyBudget => _monthlyBudget;

  double _groklyBudget = 11500.0;
  double get groklyBudget => _groklyBudget;

  double _swadishttBudget = 4000.0;
  double get swadishttBudget => _swadishttBudget;

  ExpenseProvider() {
    _initAndLoadData();
  }

  Future<void> _initAndLoadData() async {
    await fetchXpenseData();
  }

  Future<void> fetchXpenseData() async {
    _isLoading = true;
    notifyListeners();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // 1. Fetch Budget settings from Firestore
      try {
        final budgetDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('settings')
            .doc('xpense_budget')
            .get();

        if (budgetDoc.exists && budgetDoc.data() != null) {
          final data = budgetDoc.data()!;
          _monthlyBudget = (data['monthlyBudget'] ?? 18000.0).toDouble();
          _groklyBudget = (data['groklyBudget'] ?? 11500.0).toDouble();
          _swadishttBudget = (data['swadishttBudget'] ?? 4000.0).toDouble();
        }
      } catch (e) {
        debugPrint('Error fetching xpense budget: $e');
      }

      // 2. Fetch Orders from Firestore
      try {
        final List<Map<String, dynamic>> allOrders = [];

        // Collection 1: orders
        final topOrders = await FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: uid)
            .get();
        for (var doc in topOrders.docs) {
          allOrders.add(_normalizeOrder(doc.data(), doc.id, 'TopLevel'));
        }

        // Collection 2: users/{uid}/orders (Grokly)
        final groklyOrders = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('orders')
            .get();
        for (var doc in groklyOrders.docs) {
          allOrders.add(_normalizeOrder(doc.data(), doc.id, 'Grokly'));
        }

        // Collection 3: users/{uid}/swadishtt_orders
        final swadishttOrders = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('swadishtt_orders')
            .get();
        for (var doc in swadishttOrders.docs) {
          allOrders.add(_normalizeOrder(doc.data(), doc.id, 'Swadishtt'));
        }

        // Process all orders into monthly and daily breakdowns
        _processOrdersData(allOrders);
      } catch (e) {
        debugPrint('Error fetching orders for xpense meter: $e');
        _setupFallbackData();
      }
    } else {
      _setupFallbackData();
    }

    _isLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> _normalizeOrder(
      Map<String, dynamic> data, String docId, String source) {
    String service = data['service'] ?? '';
    if (service.isEmpty) {
      if (source == 'Grokly') {
        service = 'Grokly';
      } else if (source == 'Swadishtt' || data.containsKey('restaurantName')) {
        service = 'Swadishtt';
      } else {
        service = 'Grokly';
      }
    }

    double total = double.tryParse((data['total'] ??
                data['totalPaid'] ??
                data['price'] ??
                data['amount'] ??
                0)
            .toString()) ??
        0.0;

    DateTime orderDate = DateTime.now();
    if (data['createdAt'] is Timestamp) {
      orderDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['dateText'] != null || data['date'] != null) {
      final parsed = DateTime.tryParse(data['dateText'] ?? data['date'] ?? '');
      if (parsed != null) orderDate = parsed;
    }

    return {
      'id': docId,
      'service': service,
      'total': total,
      'date': orderDate,
    };
  }

  void _processOrdersData(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      _setupFallbackData();
      return;
    }

    final Map<String, double> groklySpendsByMonth = {};
    final Map<String, double> swadishttSpendsByMonth = {};
    final Map<String, Map<String, double>> dailyMapByMonth = {};

    for (var order in orders) {
      final DateTime dt = order['date'] as DateTime;
      final String monthKey = DateFormat('MMMM yyyy').format(dt);
      final double total = order['total'] as double;
      final String service = order['service'] as String;

      if (service.contains('Swadishtt')) {
        swadishttSpendsByMonth[monthKey] =
            (swadishttSpendsByMonth[monthKey] ?? 0.0) + total;
      } else {
        groklySpendsByMonth[monthKey] =
            (groklySpendsByMonth[monthKey] ?? 0.0) + total;
      }

      dailyMapByMonth.putIfAbsent(monthKey, () => {});
      final fullDayKey = DateFormat('EEE, d MMM').format(dt);
      dailyMapByMonth[monthKey]![fullDayKey] =
          (dailyMapByMonth[monthKey]![fullDayKey] ?? 0.0) + total;
    }

    final Map<String, MonthlyExpenseData> newMonthlyData = {};
    final Map<String, List<Map<String, dynamic>>> newDailySpend = {};

    final allMonthsSet = {
      ...groklySpendsByMonth.keys,
      ...swadishttSpendsByMonth.keys,
      _selectedMonth
    };

    for (var monthKey in allMonthsSet) {
      final grokly = groklySpendsByMonth[monthKey] ?? 6250.0;
      final swadishtt = swadishttSpendsByMonth[monthKey] ?? 4800.0;

      newMonthlyData[monthKey] = MonthlyExpenseData(
        monthYear: monthKey,
        totalBudget: _monthlyBudget,
        growthPercentage: 0.0,
        storeSpends: [
          StoreSpend(
            storeName: 'Grokly',
            categoryName: 'Grocery',
            amount: grokly,
            color: AppColors.groklyPrimary,
            icon: Icons.shopping_cart_outlined,
            imagePath: 'assets/vegetables.png',
          ),
          StoreSpend(
            storeName: 'Swadishtt',
            categoryName: 'Food',
            amount: swadishtt,
            color: AppColors.swadistPrimary,
            icon: Icons.restaurant_outlined,
            imagePath: 'assets/paneer.png',
          ),
        ],
      );

      final monthDays = dailyMapByMonth[monthKey] ?? {};
      final List<Map<String, dynamic>> dailyList = [];

      if (monthDays.isNotEmpty) {
        monthDays.forEach((dayStr, amt) {
          dailyList.add({
            'label': dayStr.contains(', ') ? dayStr.split(', ').last : dayStr,
            'day': dayStr,
            'amount': amt,
          });
        });
        dailyList.sort((a, b) => (a['day'] as String).compareTo(b['day'] as String));
      } else {
        // Generate dynamic trend points for this month
        final monthAbbr = monthKey.split(' ').first.substring(0, 3);
        final total = grokly + swadishtt;
        dailyList.addAll([
          {'label': '1 $monthAbbr', 'day': 'Fri, 1 $monthAbbr', 'amount': (total * 0.03).roundToDouble()},
          {'label': '8 $monthAbbr', 'day': 'Sun, 8 $monthAbbr', 'amount': (total * 0.01).roundToDouble()},
          {'label': '15 $monthAbbr', 'day': 'Fri, 15 $monthAbbr', 'amount': (total * 0.22).roundToDouble()},
          {'label': '18 $monthAbbr', 'day': 'Mon, 18 $monthAbbr', 'amount': (total * 0.08).roundToDouble()},
          {'label': '22 $monthAbbr', 'day': 'Fri, 22 $monthAbbr', 'amount': (total * 0.03).roundToDouble()},
          {'label': '31 $monthAbbr', 'day': 'Sun, 31 $monthAbbr', 'amount': (total * 0.05).roundToDouble()},
        ]);
      }

      newDailySpend[monthKey] = dailyList;
    }

    _monthlyData = newMonthlyData;
    _dailySpendByMonth = newDailySpend;
  }

  void _setupFallbackData() {
    final activeMonth = _selectedMonth.isNotEmpty
        ? _selectedMonth
        : DateFormat('MMMM yyyy').format(DateTime.now());

    final monthAbbr = activeMonth.split(' ').first.substring(0, 3);

    _monthlyData = {
      activeMonth: MonthlyExpenseData(
        monthYear: activeMonth,
        totalBudget: _monthlyBudget,
        growthPercentage: 0.0,
        storeSpends: const [
          StoreSpend(
            storeName: 'Grokly',
            categoryName: 'Grocery',
            amount: 6250.0,
            color: AppColors.groklyPrimary,
            icon: Icons.shopping_cart_outlined,
            imagePath: 'assets/vegetables.png',
          ),
          StoreSpend(
            storeName: 'Swadishtt',
            categoryName: 'Food',
            amount: 4800.0,
            color: AppColors.swadistPrimary,
            icon: Icons.restaurant_outlined,
            imagePath: 'assets/paneer.png',
          ),
        ],
      ),
    };

    _dailySpendByMonth = {
      activeMonth: [
        {'label': '1 $monthAbbr', 'day': 'Fri, 1 $monthAbbr', 'amount': 320.0},
        {'label': '8 $monthAbbr', 'day': 'Sun, 8 $monthAbbr', 'amount': 120.0},
        {'label': '15 $monthAbbr', 'day': 'Fri, 15 $monthAbbr', 'amount': 2450.0},
        {'label': '18 $monthAbbr', 'day': 'Mon, 18 $monthAbbr', 'amount': 900.0},
        {'label': '22 $monthAbbr', 'day': 'Fri, 22 $monthAbbr', 'amount': 350.0},
        {'label': '31 $monthAbbr', 'day': 'Sun, 31 $monthAbbr', 'amount': 500.0},
      ],
    };
  }

  Future<void> saveBudgetToBackend() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('settings')
            .doc('xpense_budget')
            .set({
          'monthlyBudget': _monthlyBudget,
          'groklyBudget': _groklyBudget,
          'swadishttBudget': _swadishttBudget,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving xpense budget to backend: $e');
      }
    }
    notifyListeners();
  }

  void selectMonth(String month) {
    if (!_monthlyData.containsKey(month)) return;
    if (_selectedMonth == month) return;

    _selectedMonth = month;
    notifyListeners();
  }

  void updateMonthlyBudget(double value) {
    _monthlyBudget = value.clamp(1000.0, 125000.0);
    notifyListeners();
  }

  void updateGroklyBudget(double value) {
    _groklyBudget = _clampPlatformBudget(value);
    notifyListeners();
  }

  void updateSwadishttBudget(double value) {
    _swadishttBudget = _clampPlatformBudget(value);
    notifyListeners();
  }

  double _clampPlatformBudget(double value) {
    return value.clamp(1000.0, _monthlyBudget);
  }

  double get totalPlannedBudget => _groklyBudget + _swadishttBudget;
  double get budgetDifference => totalPlannedBudget - monthlyBudget;
  bool get isOverBudget => totalPlannedBudget > monthlyBudget;

  MonthlyExpenseData get currentExpenseData {
    return _monthlyData[_selectedMonth] ??
        (_monthlyData.isNotEmpty
            ? _monthlyData.values.first
            : MonthlyExpenseData(
                monthYear: _selectedMonth,
                totalBudget: _monthlyBudget,
                growthPercentage: 0.0,
                storeSpends: const [],
              ));
  }

  double get totalSpent => currentExpenseData.totalSpent;
  double get budgetLeft => monthlyBudget - totalSpent;

  double get dailyAverageSpend {
    final day = DateTime.now().day;
    if (day <= 0) return 0.0;
    return totalSpent / day;
  }

  List<Map<String, dynamic>> get currentDailySpend {
    return _dailySpendByMonth[_selectedMonth] ?? [];
  }

  double get topSpendDayAmount {
    final list = currentDailySpend;
    if (list.isEmpty) return 0.0;
    return list
        .map((e) => e['amount'] as double)
        .reduce((a, b) => a > b ? a : b);
  }

  String get topSpendDay {
    final list = currentDailySpend;
    if (list.isEmpty) return '-';
    final entry = list.reduce(
      (a, b) => (a['amount'] as double) > (b['amount'] as double) ? a : b,
    );
    return entry['day'] as String;
  }

  double get lowestSpendDayAmount {
    final list = currentDailySpend;
    if (list.isEmpty) return 0.0;
    return list
        .map((e) => e['amount'] as double)
        .reduce((a, b) => a < b ? a : b);
  }

  String get lowestSpendDay {
    final list = currentDailySpend;
    if (list.isEmpty) return '-';
    final entry = list.reduce(
      (a, b) => (a['amount'] as double) < (b['amount'] as double) ? a : b,
    );
    return entry['day'] as String;
  }

  List<CategoryItem> get categoryBreakdown {
    final stores = currentExpenseData.storeSpends;
    double total = totalSpent;
    if (total <= 0) total = 1.0;

    double groklyAmt = 0.0;
    double swadishttAmt = 0.0;

    for (var s in stores) {
      if (s.storeName.contains('Grokly')) {
        groklyAmt += s.amount;
      } else if (s.storeName.contains('Swadishtt')) {
        swadishttAmt += s.amount;
      }
    }

    final groklyPercent = (groklyAmt / total) * 100;
    final swadishttPercent = (swadishttAmt / total) * 100;

    return [
      CategoryItem(
        label: 'Groceries',
        amount: groklyAmt,
        percent: groklyPercent,
        color: AppColors.groklyPrimary,
      ),
      CategoryItem(
        label: 'Food & Dining',
        amount: swadishttAmt,
        percent: swadishttPercent,
        color: AppColors.swadistPrimary,
      ),
    ];
  }
}
