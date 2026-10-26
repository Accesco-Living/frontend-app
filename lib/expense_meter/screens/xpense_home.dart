import '../models/monthyl_expense.dart';
import '../models/store_spend.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/xpense_provider.dart';
import '../../../utils/app_colors.dart';
import '../widgets/set_budget_screen.dart';
import '../widgets/xpense_wallet_card.dart';
import 'analytics_screen.dart';

class XpenseHomeScreen extends StatelessWidget {
  const XpenseHomeScreen({super.key});

  String _money(num value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final data = provider.currentExpenseData;

    final budgetLeft = provider.budgetLeft < 0 ? 0.0 : provider.budgetLeft;

    final remainingPercent = provider.monthlyBudget <= 0
        ? 0
        : ((budgetLeft / provider.monthlyBudget) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // ============================================================
            // HEADER
            // ============================================================

            const _HomeHeader(),

            const SizedBox(height: 12),

            // ============================================================
            // WALLET
            // ============================================================
            WalletWidget(
              expenseData: data,
              onTap: () {
                SetBudgetSheet.show(context);
              },
            ),

            const SizedBox(height: 16),

            // ============================================================
            // AT A GLANCE
            // ============================================================
            _SectionHeader(
              title: 'At a Glance',
              action: 'View Analytics',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    iconAsset: 'assets/mdi_wallet.png',
                    label: 'Budget Left',
                    value: _money(budgetLeft),
                    caption: '$remainingPercent% Remaining',
                    captionColor: AppColors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    iconAsset: 'assets/mdi_graph-line.png',
                    label: 'Daily Avg. Spend',
                    value: _money(provider.dailyAverageSpend),
                    caption: 'Keep it up!',
                    captionColor: AppColors.lightPink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    iconAsset: 'assets/uil_calender.png',
                    label: 'Top Spend Day',
                    value: provider.topSpendDay,
                    caption: _money(provider.topSpendDayAmount),
                    captionColor: AppColors.lightPink,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ============================================================
            // SPEND BY PLATFORM
            // ============================================================
            _SectionHeader(
              title: 'Spend by Platform',
              action: 'View All',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                );
              },
            ),

            const SizedBox(height: 12),

            _SpendByPlatformCard(data: data),

            const SizedBox(height: 14),

            // ============================================================
            // SET BUDGET
            // ============================================================
            _SetBudgetCard(
              onTap: () {
                SetBudgetSheet.show(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onTap;

  const _SectionHeader({required this.title, required this.action, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              letterSpacing: -0.25,
            ),
          ),
        ),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                action,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightPink,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: AppColors.lightPink,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String iconAsset;
  final String label;
  final String value;
  final String caption;
  final Color captionColor;

  const _StatCard({
    required this.iconAsset,
    required this.label,
    required this.value,
    required this.caption,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 109,
      height: 118,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.mainPink.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              iconAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
              height: 1.15,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              caption,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: captionColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendByPlatformCard extends StatelessWidget {
  final MonthlyExpenseData data;

  const _SpendByPlatformCard({required this.data});

  String _money(num value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final stores = data.storeSpends;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 9, 20, 9),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        children: [
          for (int i = 0; i < stores.length; i++) ...[
            _PlatformRow(
              spend: stores[i],
              totalSpent: data.totalSpent,
              money: _money,
            ),
            if (i < stores.length - 1)
              const Divider(height: 1, thickness: 1, color: AppColors.divider),
          ],
        ],
      ),
    );
  }
}

class _PlatformRow extends StatelessWidget {
  final StoreSpend spend;
  final double totalSpent;
  final String Function(num) money;

  const _PlatformRow({
    required this.spend,
    required this.totalSpent,
    required this.money,
  });

  @override
  Widget build(BuildContext context) {
    final percentage =
        totalSpent <= 0 ? 0 : ((spend.amount / totalSpent) * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // ==============================================================
          // PLATFORM IMAGE / ICON
          // ==============================================================

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: spend.imagePath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      spend.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return Icon(spend.icon, color: spend.color, size: 22);
                      },
                    ),
                  )
                : Icon(spend.icon, color: spend.color, size: 22),
          ),

          const SizedBox(width: 12),

          // ==============================================================
          // NAME / AMOUNT / PROGRESS
          // ==============================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        spend.storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      money(spend.amount),
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (percentage / 100).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor: AppColors.darkGrey,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            spend.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$percentage%',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SetBudgetCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SetBudgetCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(27),
        child: Container(
          height: 88,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.black,
                AppColors.xpenseMain,
                AppColors.lightPink,
              ],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Your Budget',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Plan and allocate your Budget',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.mainPink,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.add_rounded,
                  size: 22,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  'Xpense Meter',
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    letterSpacing: -0.35,
                  ),
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
          Image.asset(
            'assets/icon-btn.png',
            width: 52,
            height: 52,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
