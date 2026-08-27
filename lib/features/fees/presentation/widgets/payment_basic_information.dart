import 'package:flutter/material.dart';

import 'package:hostel_management/features/students/data/models/student_model.dart';

import '../../../../app/theme/app_colors.dart';

import '../../data/models/fee_payment_model.dart';
import 'bank_receipt_section.dart';
import 'payment_method_selector.dart';

class PaymentBasicInformation extends StatelessWidget {
  final PaymentMethod? selectedPaymentMethod;
  final ValueChanged<PaymentMethod?> onPaymentMethodChanged;

  final List<StudentModel> students;
  final int? selectedStudentId;
  final ValueChanged<int?> onStudentChanged;

  // `selectedFeeMonth` is always in "YYYY-MM" form (e.g. "2026-08"), the
  // same format the Fees table's month selector uses. Keeping one format
  // across the feature is what lets a submitted payment show up under the
  // right month in the table.
  final String selectedFeeMonth;
  final ValueChanged<String> onFeeMonthChanged;

  const PaymentBasicInformation({
    super.key,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.students,
    required this.selectedStudentId,
    required this.onStudentChanged,
    required this.selectedFeeMonth,
    required this.onFeeMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Enter the basic details of the payment',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(child: _buildStudentDropdown()),

              const SizedBox(width: 18),

              Expanded(
                child: _PaymentMonthField(
                  selectedFeeMonth: selectedFeeMonth,
                  onChanged: onFeeMonthChanged,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // --------------------------------------------------------------------
          // Payment Method
          // --------------------------------------------------------------------
          PaymentMethodSelector(
            selectedMethod: selectedPaymentMethod,
            onChanged: onPaymentMethodChanged,
          ),

          if (selectedPaymentMethod == PaymentMethod.bankTransfer) ...[
            const SizedBox(height: 18),
            const BankReceiptSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Student',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 7),

        // DropdownMenu (not DropdownButtonFormField) — this one supports
        // typing to filter the list, which plain dropdowns don't. With
        // only a handful of students this doesn't matter, but once
        // there are hundreds, scrolling to find one by hand isn't
        // realistic — typing a few letters of the name/roll number is.
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<int>(
              width: constraints.maxWidth,
              initialSelection: selectedStudentId,
              enableFilter: true,
              requestFocusOnTap: true,
              hintText: 'Search by name or roll number',
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              dropdownMenuEntries: students
                  .where((student) => student.id != null)
                  .map((student) {
                return DropdownMenuEntry<int>(
                  value: student.id!,
                  label: '${student.name} (${student.rollNumber ?? '-'})',
                );
              }).toList(),
              onSelected: onStudentChanged,
            );
          },
        ),
      ],
    );
  }
}

// =============================================================================
// Fee Month
//
// Displays a friendly "August 2026" label but reports/consumes the value as
// "YYYY-MM" (e.g. "2026-08") via `onChanged`/`selectedFeeMonth`, matching the
// format used by the Fees table's month selector and stored on
// `FeeTransaction.feeMonth`.
// =============================================================================

class _PaymentMonthField extends StatelessWidget {
  final String selectedFeeMonth;
  final ValueChanged<String> onChanged;

  const _PaymentMonthField({
    required this.selectedFeeMonth,
    required this.onChanged,
  });

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

  String _label(String value) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fee Month',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 7),

        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _selectMonth(context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: 'Select month',
              filled: true,
              fillColor: AppColors.background,
              suffixIcon: const Icon(Icons.calendar_month_outlined, size: 18),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            child: Text(
              selectedFeeMonth.isEmpty
                  ? 'Select month'
                  : _label(selectedFeeMonth),
              style: TextStyle(
                fontSize: 13,
                color: selectedFeeMonth.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectMonth(BuildContext context) async {
    DateTime initialDate = DateTime.now();

    if (selectedFeeMonth.isNotEmpty) {
      final parsed = _parseMonth(selectedFeeMonth);
      if (parsed != null) initialDate = parsed;
    }

    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return _MonthPickerDialog(initialDate: initialDate);
      },
    );

    if (selectedDate == null) return;

    onChanged(_formatFeeMonth(selectedDate.year, selectedDate.month));
  }
}

// =============================================================================
// Month Picker Dialog
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
                  child: Text(_monthName(month)),
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

  String _monthName(int month) {
    const months = [
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

    return months[month - 1];
  }
}