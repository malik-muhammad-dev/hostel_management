import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/dashboard_controller.dart';

// A palette wide enough that most hostels' category lists won't visibly
// repeat colors; it cycles if there ever are more categories than colors.
const List<Color> _chartPalette = [
  AppColors.primary,
  AppColors.accentGold,
  Color(0xFF2E8B74),
  Color(0xFF3B7DC4),
  Color(0xFFD9645C),
  Color(0xFF8E6C9A),
  Color(0xFFC98A3D),
  Color(0xFF5B7C9F),
  Color(0xFF6BA368),
  Color(0xFFB5548A),
];

class ExpenseBreakdown extends StatelessWidget {
  final DashboardController controller;

  const ExpenseBreakdown({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Obx(() {
        final breakdown = controller.expenseBreakdownThisMonth;
        final total = breakdown.values.fold<double>(0, (a, b) => a + b);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Breakdown',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Where this month\'s money is going',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            if (breakdown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'No expenses recorded this month.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Column(
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 52,
                        sectionsSpace: 3,
                        sections: _buildSections(breakdown, total),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ..._buildLegend(breakdown, total),
                ],
              ),
          ],
        );
      }),
    );
  }

  List<PieChartSectionData> _buildSections(
    Map<String, double> breakdown,
    double total,
  ) {
    final entries = breakdown.entries.toList();

    return List.generate(entries.length, (index) {
      final percentage =
          total == 0 ? 0.0 : (entries[index].value / total) * 100;

      return PieChartSectionData(
        value: entries[index].value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 52,
        color: _chartPalette[index % _chartPalette.length],
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
    });
  }

  List<Widget> _buildLegend(Map<String, double> breakdown, double total) {
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return List.generate(entries.length, (index) {
      final color = _chartPalette[
          breakdown.keys.toList().indexOf(entries[index].key) %
              _chartPalette.length];

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ExpenseItem(
          label: entries[index].key,
          amount: _formatAmount(entries[index].value),
          color: color,
        ),
      );
    });
  }

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    return 'Rs. $formatted';
  }
}

class _ExpenseItem extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _ExpenseItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}