import '../providers/xpense_provider.dart';
import '../../../utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SetBudgetSheet extends StatelessWidget {
  const SetBudgetSheet({super.key});

  static const double minBudget = 1000;
  static const double maxBudget = 18000;

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      builder: (_) => const SetBudgetSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final allocated = provider.totalPlannedBudget;
        final difference = provider.budgetDifference;
        final isOver = provider.isOverBudget;

        final remaining = provider.monthlyBudget - allocated;

        final month = provider.selectedMonth;

        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ========================================================
                  // HANDLE
                  // ========================================================

                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.sliderGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ========================================================
                  // HEADER
                  // ========================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Set Your Budget',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Icon(
                        Icons.auto_awesome,
                        size: 19,
                        color: AppColors.lightPink,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.lightGrey,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: AppColors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ========================================================
                  // DESCRIPTION
                  // ========================================================
                  Text(
                    'Plan your monthly budget and allocate it across\nplatforms.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ========================================================
                  // TOTAL MONTHLY BUDGET HEADER
                  // ========================================================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Total Monthly Budget',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.black,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _showMonthPicker(context, provider);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 11,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                month,
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: AppColors.black,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ========================================================
                  // MONTHLY BUDGET
                  // ========================================================
                  _MonthlyBudgetCard(
                    budget: provider.monthlyBudget,
                    onEdit: () {
                      _showBudgetEditor(context, provider);
                    },
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'You can distribute this budget across your platforms\nbelow.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      height: 1.25,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ========================================================
                  // ALLOCATE BUDGET
                  // ========================================================
                  Text(
                    'Allocate Budget',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ========================================================
                  // GROKLY
                  // ========================================================
                  _BudgetSliderCard(
                    name: 'Grokly',
                    value: provider.groklyBudget,
                    color: AppColors.green,
                    icon: Icons.shopping_cart_outlined,
                    onChanged: provider.updateGroklyBudget,
                  ),

                  const SizedBox(height: 12),

                  // ========================================================
                  // SWADISHTT
                  // ========================================================
                  _BudgetSliderCard(
                    name: 'Swadishtt',
                    value: provider.swadishttBudget,
                    color: AppColors.swadishttPink,
                    icon: Icons.restaurant_outlined,
                    onChanged: provider.updateSwadishttBudget,
                  ),

                  const SizedBox(height: 12),

                  // ========================================================


                  // ========================================================
                  // ALLOCATION VS BUDGET
                  // ========================================================
                  _AllocationCard(
                    provider: provider,
                    allocated: allocated,
                    difference: difference,
                    remaining: remaining,
                    isOver: isOver,
                  ),

                  const SizedBox(height: 16),

                  // ========================================================
                  // SAVE
                  // ========================================================
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await provider.saveBudgetToBackend();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Budget saved successfully!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.black,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        'Save Budget →',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showBudgetEditor(BuildContext context, ExpenseProvider provider) {
    final controller = TextEditingController(
      text: provider.monthlyBudget.round().toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Monthly Budget',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: '₹ ',
              filled: true,
              fillColor: AppColors.lightGrey,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.dmSans(color: AppColors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final value = double.tryParse(
                  controller.text.replaceAll(',', ''),
                );

                if (value == null) return;

                provider.updateMonthlyBudget(value);

                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mainPink,
                elevation: 0,
              ),
              child: Text(
                'Save',
                style: GoogleFonts.dmSans(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMonthPicker(BuildContext context, ExpenseProvider provider) {
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
}

class _MonthlyBudgetCard extends StatelessWidget {
  final double budget;
  final VoidCallback onEdit;

  const _MonthlyBudgetCard({required this.budget, required this.onEdit});

  String _money(num value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
                  _money(budget),
                  style: GoogleFonts.dmSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  'of ₹1,25,000 Budget',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 19,
                color: AppColors.mainPink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSliderCard extends StatelessWidget {
  final String name;
  final double value;
  final Color color;
  final IconData icon;
  final ValueChanged<double> onChanged;

  const _BudgetSliderCard({
    required this.name,
    required this.value,
    required this.color,
    required this.icon,
    required this.onChanged,
  });

  String _money(num value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.darkGrey, width: 1),
      ),
      child: Column(
        children: [
          // ==============================================================
          // TOP ROW
          // ==============================================================

          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              Text(
                _money(value),
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // ==============================================================
          // SLIDER
          // ==============================================================
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              activeTrackColor: color,
              inactiveTrackColor: AppColors.sliderGrey,
              thumbColor: AppColors.white,
              overlayColor: color.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 8,
                elevation: 0,
              ),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.clamp(
                SetBudgetSheet.minBudget,
                SetBudgetSheet.maxBudget,
              ),
              min: SetBudgetSheet.minBudget,
              max: SetBudgetSheet.maxBudget,
              onChanged: onChanged,
            ),
          ),

          // ==============================================================
          // MIN / MAX
          // ==============================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹1,000',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                ),
                Text(
                  '₹18,000',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllocationCard extends StatelessWidget {
  final ExpenseProvider provider;
  final double allocated;
  final double difference;
  final double remaining;
  final bool isOver;

  const _AllocationCard({
    required this.provider,
    required this.allocated,
    required this.difference,
    required this.remaining,
    required this.isOver,
  });

  String _money(num value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final total = provider.monthlyBudget;

    final grokly = provider.groklyBudget / total;
    final swadishtt = provider.swadishttBudget / total;


    return Container(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==============================================================
          // TITLE
          // ==============================================================

          Row(
            children: [
              Expanded(
                child: Text(
                  'Allocation vs. Budget',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
              if (isOver)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightPink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Over by ${_money(difference)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // ==============================================================
          // BUDGET LABEL
          // ==============================================================
          Center(
            child: Text(
              'Budget ${_money(total)}',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),

          const SizedBox(height: 7),

          // ==============================================================
          // ALLOCATION BAR
          // ==============================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (grokly > 0)
                    Expanded(
                      flex: (grokly * 1000).round(),
                      child: Container(color: AppColors.green),
                    ),
                  if (swadishtt > 0)
                    Expanded(
                      flex: (swadishtt * 1000).round(),
                      child: Container(color: AppColors.swadishttPink),
                    ),

                  if (isOver)
                    Expanded(
                      flex: ((difference / total) * 1000).abs().round().clamp(
                            1,
                            1000,
                          ),
                      child: Container(color: AppColors.lightPink),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ==============================================================
          // LEGEND
          // ==============================================================
          Wrap(
            spacing: 10,
            runSpacing: 5,
            children: [
              _LegendItem(color: AppColors.green, text: 'Grokly'),
              _LegendItem(color: AppColors.swadishttPink, text: 'Swadishtt'),

              if (isOver)
                _LegendItem(color: AppColors.lightPink, text: 'Over budget'),
            ],
          ),

          const SizedBox(height: 12),

          const Divider(height: 1, thickness: 1, color: AppColors.divider),

          const SizedBox(height: 12),

          // ==============================================================
          // TOTALS
          // ==============================================================
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allocated',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _money(allocated),
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isOver ? 'Over Budget' : 'Remaining',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isOver ? '-${_money(difference)}' : _money(remaining),
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isOver ? AppColors.lightPink : AppColors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }
}
