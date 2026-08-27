import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class MonthPickerField extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String emptyText;

  const MonthPickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.emptyText = 'Select month',
  });

  static const monthNames = [
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

  DateTime? _parseMonth(String value) {
    final parts = value.split('-');

    if (parts.length != 2) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);

    if (year == null ||
        month == null ||
        month < 1 ||
        month > 12) {
      return null;
    }

    return DateTime(year, month);
  }

  String _formatMonthLabel(String value) {
    final parsed = _parseMonth(value);

    if (parsed == null) {
      return value;
    }

    return '${monthNames[parsed.month - 1]} ${parsed.year}';
  }

  String _formatMonth(int year, int month) {
    return '${year.toString().padLeft(4, '0')}-'
        '${month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(
                width: constraints.maxWidth > 350
                    ? 230
                    : constraints.maxWidth,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _pickMonth(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      suffixIcon: const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                      enabledBorder:
                          OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.border,
                        ),
                      ),
                    ),
                    child: Text(
                      value.isEmpty
                          ? emptyText
                          : _formatMonthLabel(value),
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
  }

  Future<void> _pickMonth(
    BuildContext context,
  ) async {
    var initialDate = DateTime.now();

    final parsed = _parseMonth(value);

    if (parsed != null) {
      initialDate = parsed;
    }

    final selected = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return _MonthPickerDialog(
          initialDate: initialDate,
          monthNames: monthNames,
        );
      },
    );

    if (selected == null) {
      return;
    }

    onChanged(
      _formatMonth(
        selected.year,
        selected.month,
      ),
    );
  }
}

class _MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final List<String> monthNames;

  const _MonthPickerDialog({
    required this.initialDate,
    required this.monthNames,
  });

  @override
  State<_MonthPickerDialog> createState() =>
      _MonthPickerDialogState();
}

class _MonthPickerDialogState
    extends State<_MonthPickerDialog> {
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
      title: const Text('Select Month'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedYear,
              decoration: const InputDecoration(
                labelText: 'Year',
              ),
              items: List.generate(
                21,
                (index) {
                  final year =
                      DateTime.now().year - 10 + index;

                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text(
                      year.toString(),
                    ),
                  );
                },
              ),
              onChanged: (year) {
                if (year == null) {
                  return;
                }

                setState(() {
                  selectedYear = year;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Month',
              ),
              items: List.generate(
                12,
                (index) {
                  final month = index + 1;

                  return DropdownMenuItem<int>(
                    value: month,
                    child: Text(
                      widget.monthNames[month - 1],
                    ),
                  );
                },
              ),
              onChanged: (month) {
                if (month == null) {
                  return;
                }

                setState(() {
                  selectedMonth = month;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              DateTime(
                selectedYear,
                selectedMonth,
              ),
            );
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}