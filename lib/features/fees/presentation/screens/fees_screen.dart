import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../../../students/presentation/controllers/student_controller.dart';

import '../controllers/fee_controller.dart';
import '../widgets/fee_records_table.dart';
import '../widgets/fee_summary.dart';
import '../widgets/fee_table_header.dart';

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

  // ===========================================================================
  // MONTH HELPERS
  //
  // Fee month is always stored/passed as "YYYY-MM" (e.g. "2026-08"). This is
  // the same format the payment form uses, so a submitted payment always
  // matches the month it's filed under here.
  // ===========================================================================

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _formatMonthLabel(String value) {
    final parsed = _parseMonth(value);
    if (parsed == null) return value;
    return '${_monthNames[parsed.month - 1]} ${parsed.year}';
  }

  DateTime? _parseMonth(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return null;
    

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) {
      return null;
    }

    return DateTime(year, month);
  }

  String _formatFeeMonth(int year, int month) {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}';
  }

  // ===========================================================================
  // MONTH SELECTOR
  //
  // Opens a year/month picker dialog instead of a fixed generated list, so
  // any past or future year can be chosen, not just the next 24 months.
  // ===========================================================================

  Widget _buildMonthSelector(
    BuildContext context,
    FeeController feeController,
  ) {
    return Obx(() {
      final currentValue = feeController.feeTableMonth.value;
      final showAll = feeController.showAllMonths.value;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Fee Month',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                // "All" — shows every month's activity at once, no single
                // month selected. This is the default view.
                _MonthChip(
                  label: 'All',
                  selected: showAll,
                  onTap: feeController.showAllFeeRecords,
                ),

                SizedBox(
                  width: constraints.maxWidth > 350
                      ? 230
                      : constraints.maxWidth,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () =>
                        _pickMonth(context, feeController, currentValue),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: showAll
                            ? AppColors.background
                            : AppColors.primaryLight,
                        suffixIcon: const Icon(
                          Icons.calendar_month_outlined,
                          size: 18,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Text(
                        currentValue.isEmpty
                            ? 'Select fee month'
                            : _formatMonthLabel(currentValue),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Future<void> _pickMonth(
    BuildContext context,
    FeeController feeController,
    String currentValue,
  ) async {
    DateTime initialDate = DateTime.now();
    final parsed = _parseMonth(currentValue);
    if (parsed != null) initialDate = parsed;

    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthPickerDialog(initialDate: initialDate),
    );

    if (selected == null) return;

    feeController.setFeeTableMonth(
      _formatFeeMonth(selected.year, selected.month),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final feeController = Get.find<FeeController>();
    final studentController = Get.find<StudentController>();
    final settingsController = Get.find<AppSettingsController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, settingsController),

          const SizedBox(height: 24),

          _buildMonthSelector(context, feeController),

          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // Dashboard summary — scoped to the selected month, same as the
          // records table below.
          // -------------------------------------------------------------------
          Obx(
            () => FeeSummary(
              totalExpected: feeController.totalExpected,
              collected: feeController.collected,
              outstanding: feeController.outstanding,
              overdue: feeController.overdue,
              monthLabel: feeController.showAllMonths.value
                  ? 'All Time'
                  : (feeController.feeTableMonth.value.isEmpty
                      ? ''
                      : _formatMonthLabel(feeController.feeTableMonth.value)),
            ),
          ),

          const SizedBox(height: 24),

          // -------------------------------------------------------------------
          // Monthly fee records — scoped to the selected month, or every
          // month at once when "All" is active.
          // -------------------------------------------------------------------
          Obx(() {
            final showAll = feeController.showAllMonths.value;
            final month = feeController.feeTableMonth.value;

            // An Inactive student is excluded from this table entirely —
            // client's explicit instruction: her fee should be
            // "completely off," not just hidden on the Dashboard while
            // still showing up here. Matches FeeController.totalExpected/
            // outstanding/overdue above, which already exclude her the
            // same way — this list and those totals must agree on who
            // counts as "currently owing," or the table and the summary
            // cards above it would disagree again.
            final currentStudents = studentController.activeStudents
                .where((student) => student.status != 'Inactive')
                .toList();

            // In single-month mode, a student who wasn't enrolled yet
            // for that month shouldn't appear as a row at all — showing
            // them with an all-zero "Paid" entry (balance 0 reads as
            // "Paid") is misleading, since they were never charged
            // anything in the first place.
            final visibleStudents = showAll
                ? currentStudents
                : currentStudents
                    .where(
                      (student) =>
                          feeController.isStudentEnrolledInMonth(
                        student,
                        month,
                      ),
                    )
                    .toList();

            // Shimmer only on the very first load (neither Students nor
            // Fees has fetched anything yet) — never over a page that
            // already has real rows, even during a quiet background
            // refresh from real-time sync.
            final isInitialLoading =
                (studentController.isLoading.value ||
                    feeController.isLoading.value) &&
                visibleStudents.isEmpty;

            if (isInitialLoading) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    FeeTableHeader(),
                    TableSkeleton(
                      columnFlexes: [3, 2, 2, 2, 2],
                      trailingWidth: 90,
                    ),
                  ],
                ),
              );
            }

            return FeeRecordsTable(
              students: visibleStudents,
              summaries: visibleStudents
                  .where((student) => student.id != null)
                  .map(
                    (student) => showAll
                        ? feeController.computeFeeSummary(student.id!)
                        : feeController.computeFeeSummaryForMonth(
                            student.id!,
                            month,
                          ),
                  )
                  .toList(),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader(
    BuildContext context,
    AppSettingsController settingsController,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fees & Payments',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Manage student fees, payments, outstanding balances and dues',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        _buildFineRuleChip(context, settingsController),
      ],
    );
  }

  // ===========================================================================
  // LATE FINE RULE
  //
  // A small, always-visible control so the admin never has to hunt for
  // this — it directly answers "what happens if a student doesn't pay by
  // the Nth". Tapping it opens a dialog to change the amount/day; the
  // change applies immediately everywhere (Fees table, Record Payment,
  // Dashboard's Overdue figure) since it's read live from Settings.
  // ===========================================================================

  Widget _buildFineRuleChip(
    BuildContext context,
    AppSettingsController settingsController,
  ) {
    return Obx(
      () => InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showEditFineRuleDialog(context, settingsController),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.report_gmailerrorred_outlined,
                size: 16,
                color: AppColors.error,
              ),
              const SizedBox(width: 8),
              Text(
                'Late Fine: Rs. ${settingsController.fineAmount.value.toStringAsFixed(0)} '
                'after the ${_ordinal(settingsController.fineDueDay.value)}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.edit_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ordinal(int day) {
    if (day % 10 == 1 && day != 11) return '${day}st';
    if (day % 10 == 2 && day != 12) return '${day}nd';
    if (day % 10 == 3 && day != 13) return '${day}rd';
    return '${day}th';
  }

  Future<void> _showEditFineRuleDialog(
    BuildContext context,
    AppSettingsController settingsController,
  ) async {
    final amountController = TextEditingController(
      text: settingsController.fineAmount.value.toStringAsFixed(0),
    );
    final dayController = TextEditingController(
      text: settingsController.fineDueDay.value.toString(),
    );

    final errorText = ''.obs;

    final result = await showDialog<_FineRuleResult>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Late Fine Rule'),
          content: SizedBox(
            width: 340,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Applies automatically once a month\'s due day has '
                  'passed and that month is still unpaid.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(),
                  decoration: const InputDecoration(
                    labelText: 'Fine amount',
                    prefixText: 'Rs. ',
                    hintText: 'e.g. 100',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: dayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Due day of the month',
                    hintText: '1-28',
                  ),
                ),
                Obx(
                  () => errorText.value.isEmpty
                      ? const SizedBox(height: 8)
                      : Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            errorText.value,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final cleanedAmount = amountController.text
                    .replaceAll(RegExp(r'[^0-9.]'), '')
                    .trim();
                final amount = double.tryParse(cleanedAmount);

                final day = int.tryParse(dayController.text.trim());

                if (cleanedAmount.isEmpty || amount == null || amount < 0) {
                  errorText.value = 'Enter a valid fine amount';
                  return;
                }

                // Restricted to 1-28 so it's always a valid day in every
                // month, including February — no month-end edge cases
                // to reason about anywhere this is used.
                if (day == null || day < 1 || day > 28) {
                  errorText.value = 'Due day must be between 1 and 28';
                  return;
                }

                Navigator.of(context).pop(
                  _FineRuleResult(amount: amount, dueDay: day),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await settingsController.setFineRule(
        amount: result.amount,
        dueDay: result.dueDay,
      );
    }
  }
}

class _FineRuleResult {
  final double amount;
  final int dueDay;

  const _FineRuleResult({required this.amount, required this.dueDay});
}

// =============================================================================
// Month Picker Dialog
//
// Same year/month picker pattern used on the Record Payment screen, kept
// local here to avoid coupling the two screens together over one shared
// private widget. If this exact dialog is needed a third time, pull it out
// into its own shared widget file instead of copying it again.
// =============================================================================

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;

  const _MonthPickerDialog({required this.initialDate});

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Fee Month'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedYear,
              decoration: const InputDecoration(labelText: 'Year'),
              items: List.generate(21, (index) {
                final year = DateTime.now().year - 10 + index;
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text(year.toString()),
                );
              }),
              onChanged: (year) {
                if (year == null) return;
                setState(() => selectedYear = year);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: selectedMonth,
              decoration: const InputDecoration(labelText: 'Month'),
              items: List.generate(12, (index) {
                final month = index + 1;
                return DropdownMenuItem<int>(
                  value: month,
                  child: Text(FeesScreen._monthNames[month - 1]),
                );
              }),
              onChanged: (month) {
                if (month == null) return;
                setState(() => selectedMonth = month);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(DateTime(selectedYear, selectedMonth));
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}

// =============================================================================
// Month Chip — the "All" toggle next to the month picker.
// =============================================================================

class _MonthChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MonthChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}