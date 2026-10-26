import 'dart:math' as math;
import 'dart:ui' as ui;

import '/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/xpense_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

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

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 562),
            color: AppColors.white,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================================
                  // HEADER
                  // ========================================================
                  _AnalyticsHeader(provider: provider),

                  const SizedBox(height: 14),

                  // ========================================================
                  // TABS
                  // ========================================================
                  const _AnalyticsTabs(),

                  const SizedBox(height: 10),

                  // ========================================================
                  // MONTH SPEND
                  // ========================================================
                  _MonthlySpendCard(provider: provider, money: _money),

                  const SizedBox(height: 16),

                  // ========================================================
                  // SPEND TREND
                  // ========================================================
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: double.infinity,
                      ),
                      child: _SpendTrendCard(provider: provider),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ========================================================
                  // HIGH / LOW DAYS
                  // ========================================================
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.arrow_upward_rounded,
                          label: 'Highest Spend Day',
                          date: provider.topSpendDay,
                          amount: _money(provider.topSpendDayAmount),
                          iconColor: AppColors.green,
                          amountColor: AppColors.green,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _MetricCard(
                          icon: Icons.arrow_downward_rounded,
                          label: 'Lowest Spend Day',
                          date: provider.lowestSpendDay,
                          amount: _money(provider.lowestSpendDayAmount),
                          iconColor: AppColors.red,
                          amountColor: AppColors.red,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ========================================================
                  // CATEGORY BREAKDOWN
                  // ========================================================
                  _CategoryBreakdown(provider: provider, money: _money),

                  const SizedBox(height: 12),

                  // ========================================================
                  // BOTTOM SAFE AREA / HOME INDICATOR
                  // ========================================================
                  Center(
                    child: Container(
                      width: 140,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// HEADER
// ============================================================================

class _AnalyticsHeader extends StatelessWidget {
  final ExpenseProvider provider;

  const _AnalyticsHeader({required this.provider});

  void _showMonthPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Month',
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                ...provider.availableMonths.map((month) {
                  final selected = month == provider.selectedMonth;

                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    tileColor:
                        selected ? AppColors.lightGrey : AppColors.transparent,
                    title: Text(
                      month,
                      style: GoogleFonts.dmSans(
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.black,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.mainPink,
                          )
                        : null,
                    onTap: () {
                      provider.selectMonth(month);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 17,
            color: AppColors.black,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Analytics',
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.black,
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _showMonthPicker(context),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 10,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  provider.selectedMonth,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: AppColors.white,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// TABS
// ============================================================================

class _AnalyticsTabs extends StatelessWidget {
  const _AnalyticsTabs();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TabChip(label: 'Overview', active: true)),
        const SizedBox(width: 8),
        Expanded(child: _TabChip(label: 'Spending')),
        const SizedBox(width: 8),
        Expanded(child: _TabChip(label: 'Trends')),
        const SizedBox(width: 8),
        Expanded(child: _TabChip(label: 'Compare')),
      ],
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;

  const _TabChip({required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.lightPink : AppColors.black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}

// ============================================================================
// MONTHLY SPEND
// ============================================================================

class _MonthlySpendCard extends StatelessWidget {
  final ExpenseProvider provider;
  final String Function(num) money;

  const _MonthlySpendCard({required this.provider, required this.money});

  @override
  Widget build(BuildContext context) {
    final double totalSpent = provider.totalSpent;
    final double budget = provider.monthlyBudget;
    final int percent =
        budget <= 0 ? 0 : ((totalSpent / budget) * 100).round();
    final double progressRatio =
        budget <= 0 ? 0.0 : (totalSpent / budget).clamp(0.0, 1.0);

    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.black, AppColors.xpenseMain, AppColors.lightPink],
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
                  'This Month Spend',
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  money(totalSpent),
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: -0.7,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'of ${money(budget)} Budget',
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.white.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),

          // PERCENTAGE RING
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 66,
                  height: 66,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 7,
                    color: AppColors.white.withValues(alpha: 0.15),
                  ),
                ),
                SizedBox(
                  width: 66,
                  height: 66,
                  child: CircularProgressIndicator(
                    value: progressRatio,
                    strokeWidth: 5,
                    color: AppColors.white,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percent%',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'OF BUDGET',
                      style: GoogleFonts.dmSans(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
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

// ============================================================================
// SPEND TREND
// ============================================================================

class _SpendTrendCard extends StatelessWidget {
  final ExpenseProvider provider;

  const _SpendTrendCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      padding: const EdgeInsets.fromLTRB(12, 12, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spend Trend',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: CustomPaint(
              painter: _SpendTrendPainter(dailyData: provider.currentDailySpend),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendTrendPainter extends CustomPainter {
  final List<Map<String, dynamic>> dailyData;

  _SpendTrendPainter({required this.dailyData});

  @override
  void paint(Canvas canvas, Size size) {
    final chartLeft = 38.0;
    final chartRight = size.width - 10;
    final chartTop = 18.0;
    final chartBottom = size.height - 35;

    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    // GRID
    final gridPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.10)
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = chartTop + (i / 3) * chartHeight;
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);
    }

    // Y LABELS
    double maxAmt = 1000.0;
    if (dailyData.isNotEmpty) {
      final maxFound = dailyData
          .map((e) => (e['amount'] as double))
          .reduce((a, b) => a > b ? a : b);
      if (maxFound > 1000) maxAmt = maxFound;
    }

    final yLabels = [
      '${(maxAmt / 1000).toStringAsFixed(1)}K',
      '${(maxAmt * 0.75 / 1000).toStringAsFixed(1)}K',
      '${(maxAmt * 0.5 / 1000).toStringAsFixed(1)}K',
      '${(maxAmt * 0.25 / 1000).toStringAsFixed(1)}K',
      '0',
    ];

    for (int i = 0; i < yLabels.length; i++) {
      final y = chartTop + (i / 4) * chartHeight;
      final painter = TextPainter(
        text: TextSpan(
          text: yLabels[i],
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      painter.layout();
      painter.paint(canvas, Offset(0, y - painter.height / 2));
    }

    if (dailyData.isEmpty) return;

    final path = Path();
    for (int i = 0; i < dailyData.length; i++) {
      final x = dailyData.length == 1
          ? chartLeft + chartWidth / 2
          : chartLeft + (i / (dailyData.length - 1)) * chartWidth;

      final amt = dailyData[i]['amount'] as double;
      final ratio = (amt / maxAmt).clamp(0.0, 1.0);
      final y = chartBottom - ratio * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // AREA
    final fillPath = Path.from(path)
      ..lineTo(chartRight, chartBottom)
      ..lineTo(chartLeft, chartBottom)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.lightPink.withValues(alpha: 0.24),
          AppColors.lightPink.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, chartTop, size.width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    // LINE
    final linePaint = Paint()
      ..color = AppColors.lightPink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // HIGHLIGHT POINT (PEAK DAY)
    int maxIndex = 0;
    double maxVal = dailyData.first['amount'] as double;
    for (int i = 1; i < dailyData.length; i++) {
      if ((dailyData[i]['amount'] as double) > maxVal) {
        maxVal = dailyData[i]['amount'] as double;
        maxIndex = i;
      }
    }

    final selectedX = dailyData.length == 1
        ? chartLeft + chartWidth / 2
        : chartLeft + (maxIndex / (dailyData.length - 1)) * chartWidth;
    final selectedY =
        chartBottom - (maxVal / maxAmt).clamp(0.0, 1.0) * chartHeight;

    canvas.drawCircle(
      Offset(selectedX, selectedY),
      7,
      Paint()..color = AppColors.lightPink,
    );

    canvas.drawCircle(
      Offset(selectedX, selectedY),
      3,
      Paint()..color = AppColors.white,
    );

    // X LABELS
    for (int i = 0; i < dailyData.length; i++) {
      final x = dailyData.length == 1
          ? chartLeft + chartWidth / 2
          : chartLeft + (i / (dailyData.length - 1)) * chartWidth;

      final label = (dailyData[i]['label'] as String);

      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr,
      );

      painter.layout();
      painter.paint(canvas, Offset(x - painter.width / 2, size.height - 22));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ============================================================================
// HIGH / LOW METRIC
// ============================================================================

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String date;
  final String amount;
  final Color iconColor;
  final Color amountColor;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.date,
    required this.amount,
    required this.iconColor,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grey,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            date,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            amount,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: amountColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CATEGORY BREAKDOWN
// ============================================================================

class _CategoryBreakdown extends StatelessWidget {
  final ExpenseProvider provider;
  final String Function(num) money;

  const _CategoryBreakdown({required this.provider, required this.money});

  @override
  Widget build(BuildContext context) {
    final categories = provider.categoryBreakdown;
    final totalSpent = provider.totalSpent;

    final List<double> segments = categories.map((c) => c.percent / 100).toList();
    final List<Color> colors = categories.map((c) => c.color).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Breakdown',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // DONUT
              SizedBox(
                width: 118,
                height: 118,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    segments: segments.isEmpty ? [1.0] : segments,
                    colors: colors.isEmpty ? [AppColors.grey] : colors,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          money(totalSpent),
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                          ),
                        ),
                        Text(
                          'TOTAL',
                          style: GoogleFonts.dmSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: AppColors.grey,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // LEGEND
              Expanded(
                child: Column(
                  children: [
                    for (var cat in categories)
                      _LegendRow(
                        color: cat.color,
                        label: cat.label,
                        amount: money(cat.amount),
                        percent: '${cat.percent.round()}%',
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;
  final String percent;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.amount,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              percent,
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<double> segments;
  final List<Color> colors;

  _DonutChartPainter({required this.segments, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < segments.length; i++) {
      final sweepAngle = segments[i] * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
