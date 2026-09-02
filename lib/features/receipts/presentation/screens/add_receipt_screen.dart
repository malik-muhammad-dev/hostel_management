import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../models/receipt_model.dart';
import '../controllers/receipt_controller.dart';

// Note: the "Received From" field used to be free text for anyone. It's
// now a required Student/Faculty choice (see _ReceivedFromField below) —
// a deliberate tightening from the original optional text box, matching
// the client's later "is it student or faculty" requirement.

// =============================================================================
// ADD / EDIT RECEIPT SCREEN
// =============================================================================

class AddReceiptScreen extends StatelessWidget {
  const AddReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ReceiptController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: _ReceiptForm(controller: controller),
    );
  }
}

class _ReceiptForm extends StatelessWidget {
  final ReceiptController controller;

  const _ReceiptForm({required this.controller});

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
          const _FormHeader(),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DateField(
                  controller: controller.dateController,
                  onDateSelected: controller.setDate,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _AmountField(controller: controller.amountController),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ReceivedFromField(controller: controller),
          const SizedBox(height: 18),
          _ReceiptTextField(
            controller: controller.notesController,
            label: 'Notes (optional)',
            hint: 'What is this for?',
            maxLines: 3,
          ),
          const SizedBox(height: 18),
          _PaymentMethodField(controller: controller),
          const SizedBox(height: 28),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 20),
          _FormActions(controller: controller),
        ],
      ),
    );
  }
}

// =============================================================================
// FORM HEADER
// =============================================================================

class _FormHeader extends StatelessWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.local_atm_rounded,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Cash',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Cash received outside of the regular fee — never touches fee/expense records',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// DATE FIELD
// =============================================================================

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<DateTime> onDateSelected;

  const _DateField({required this.controller, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDate(context),
          decoration: InputDecoration(
            hintText: 'Select date',
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final currentDate = DateTime.tryParse(controller.text) ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) {
      return;
    }

    onDateSelected(selectedDate);
  }
}

// =============================================================================
// AMOUNT FIELD
// =============================================================================

class _AmountField extends StatelessWidget {
  final TextEditingController controller;

  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return _ReceiptTextField(
      controller: controller,
      label: 'Amount',
      hint: 'Enter amount received',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      prefixText: 'Rs. ',
    );
  }
}

// =============================================================================
// SHARED TEXT FIELD
// =============================================================================

class _ReceiptTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? prefixText;

  const _ReceiptTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// WHO THIS CASH IS FOR — Student or Faculty
// =============================================================================

class _ReceivedFromField extends StatelessWidget {
  final ReceiptController controller;

  const _ReceivedFromField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Who Is This For',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final type = controller.receivedFromType.value;

          return Row(
            children: [
              Expanded(
                child: _PaymentOption(
                  title: 'Student',
                  icon: Icons.school_outlined,
                  selected: type == ReceivedFromType.student,
                  onTap: () =>
                      controller.setReceivedFromType(ReceivedFromType.student),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PaymentOption(
                  title: 'Faculty',
                  icon: Icons.badge_outlined,
                  selected: type == ReceivedFromType.faculty,
                  onTap: () =>
                      controller.setReceivedFromType(ReceivedFromType.faculty),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 14),
        Obx(() {
          final type = controller.receivedFromType.value;

          if (type == ReceivedFromType.student) {
            return _StudentPicker(controller: controller);
          }

          if (type == ReceivedFromType.faculty) {
            return _ReceiptTextField(
              controller: controller.receivedFromController,
              label: 'Faculty Name',
              hint: "Enter the faculty member's name",
            );
          }

          return const SizedBox.shrink();
        }),
      ],
    );
  }
}

// =============================================================================
// STUDENT PICKER — same searchable dropdown the Fees screen already uses
// (type to filter by name or roll number), so it looks and behaves
// identically. Only lists active students.
// =============================================================================

class _StudentPicker extends StatelessWidget {
  final ReceiptController controller;

  const _StudentPicker({required this.controller});

  @override
  Widget build(BuildContext context) {
    final students = controller.studentController.activeStudents
        .where((student) => student.id != null)
        .toList();

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
        LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<int>(
              width: constraints.maxWidth,
              initialSelection: controller.selectedStudentId.value,
              enableFilter: true,
              requestFocusOnTap: true,
              hintText: 'Search by name or roll number',
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: AppColors.background,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              dropdownMenuEntries: students.map((student) {
                return DropdownMenuEntry<int>(
                  value: student.id!,
                  label: '${student.name} (${student.rollNumber ?? '-'})',
                );
              }).toList(),
              onSelected: controller.setSelectedStudent,
            );
          },
        ),
      ],
    );
  }
}

// =============================================================================
// PAYMENT METHOD ("Kept As" — where this cash is being held)
// =============================================================================

class _PaymentMethodField extends StatelessWidget {
  final ReceiptController controller;

  const _PaymentMethodField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kept As',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Obx(
          () => Row(
            children: [
              Expanded(
                child: _PaymentOption(
                  title: 'Cash',
                  icon: Icons.payments_outlined,
                  selected: controller.paymentMode.value == ReceiptPaymentMode.cash,
                  onTap: () => controller.setPaymentMode(ReceiptPaymentMode.cash),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _PaymentOption(
                  title: 'Account',
                  icon: Icons.account_balance_outlined,
                  selected:
                      controller.paymentMode.value == ReceiptPaymentMode.account,
                  onTap: () => controller.setPaymentMode(ReceiptPaymentMode.account),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentOption({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryLight : AppColors.background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 19,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 19,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// FORM ACTIONS
// =============================================================================

class _FormActions extends StatelessWidget {
  final ReceiptController controller;

  const _FormActions({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: controller.isSaving.value
                ? null
                : () {
                    controller.clearForm();
                    Get.find<AppShellController>().popPage();
                  },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: controller.isSaving.value ? null : () => _save(context),
            icon: controller.isSaving.value
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined, size: 18),
            label: Text(controller.isEditMode ? 'Update Receipt' : 'Save Receipt'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final validationMessage = controller.validate();

    if (validationMessage != null) {
      _showMessage(context, validationMessage);
      return;
    }

    if (controller.isEditMode) {
      final success = await controller.updateReceipt();

      if (!context.mounted) {
        return;
      }

      if (!success) {
        _showMessage(context, 'Unable to update receipt.');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt updated successfully.')),
      );

      Get.find<AppShellController>().popPage();
      return;
    }

    final createdReceipt = await controller.addReceipt();

    if (!context.mounted) {
      return;
    }

    if (createdReceipt == null) {
      _showMessage(context, 'Unable to save receipt.');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receipt added successfully.')),
    );

    Get.find<AppShellController>().popPage();
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}