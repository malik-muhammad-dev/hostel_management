import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../controllers/student_service_controller.dart';
import 'form_section.dart';

class ServicesInformationSection extends StatelessWidget {
  final StudentServiceController controller;
  final bool isNewStudent;

  const ServicesInformationSection({
    super.key,
    required this.controller,
    required this.isNewStudent,
  });

  @override
  Widget build(BuildContext context) {
    return FormSection(
      title: 'Additional Services',
      subtitle: 'Select optional services for this student',
      icon: Icons.miscellaneous_services_outlined,
      child: Obx(
        () {
          final services = isNewStudent
              ? controller.draftServices.toList()
              : controller.services.toList();

          return Column(
            children: [
              // ---------------------------------------------------------------
              // Service list
              // ---------------------------------------------------------------

              if (services.isEmpty)
                _buildEmptyState()
              else
                ...services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ServiceOption(
                      icon: _getServiceIcon(service.name),
                      title: service.name,
                      subtitle: service.description ??
                          'Optional student service',
                      amount: service.monthlyAmount,
                      enabled: service.isActive,
                      onChanged: (value) async {
                        if (isNewStudent) {
                          // -------------------------------------------------
                          // Draft service
                          //
                          // We don't have a student ID yet, so simply update
                          // the draft object.
                          // -------------------------------------------------

                          final updatedService = service.copyWith(
                            isActive: value,
                          );

                          final index =
                              controller.draftServices.indexWhere(
                            (item) => item.id == service.id,
                          );

                          if (index != -1) {
                            controller.draftServices[index] =
                                updatedService;
                            controller.draftServices.refresh();
                          }
                        } else {
                          await controller.setServiceActive(
                            service,
                            value,
                          );
                        }
                      },
                    ),
                  ),
                ),

              // ---------------------------------------------------------------
              // Add Service
              // ---------------------------------------------------------------

              const SizedBox(height: 4),

              OutlinedButton.icon(
                onPressed: () {
                  _showAddServiceDialog(
                    context,
                  );
                },
                icon: const Icon(
                  Icons.add_rounded,
                  size: 18,
                ),
                label: const Text('Add Service'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(
                    color: AppColors.primary,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // ---------------------------------------------------------------
              // Total active services
              // ---------------------------------------------------------------

              if (services.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildServiceTotal(services),
              ],
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Text(
        'No services added for this student.',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Service total
  // ---------------------------------------------------------------------------

  Widget _buildServiceTotal(
    List<dynamic> services,
  ) {
    final total = services
        .where((service) => service.isActive)
        .fold<double>(
          0.0,
          (sum, service) =>
              sum + (service.monthlyAmount as double),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Active Services Total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            _formatAmount(total),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add service dialog
  // ---------------------------------------------------------------------------

  Future<void> _showAddServiceDialog(
    BuildContext context,
  ) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Service'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Service Name',
                    hintText: 'e.g. Laundry',
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Amount',
                    hintText: 'e.g. 1000',
                    prefixText: 'Rs. ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description =
                    descriptionController.text.trim();

                final amount = double.tryParse(
                  amountController.text.trim(),
                );

                if (name.isEmpty) {
                  Get.snackbar(
                    'Invalid Service',
                    'Please enter a service name.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                if (amount == null || amount <= 0) {
                  Get.snackbar(
                    'Invalid Amount',
                    'Please enter a valid monthly amount.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                bool success;

                if (isNewStudent) {
                  // ---------------------------------------------------------
                  // New student → store as draft.
                  // ---------------------------------------------------------

                  success = controller.addDraftService(
                    name: name,
                    description:
                        description.isEmpty ? null : description,
                    monthlyAmount: amount,
                  );
                } else {
                 // ---------------------------------------------------------
// Existing student → save directly.
// ---------------------------------------------------------

final studentId =
    controller.selectedStudentId.value;

if (studentId == null) {
  Get.snackbar(
    'Service',
    'Student ID could not be determined.',
    snackPosition: SnackPosition.BOTTOM,
  );
  return;
}

success = await controller.addService(
  studentId: studentId,
  name: name,
  description: description.isEmpty
      ? null
      : description,
  monthlyAmount: amount,
);

                  success = true;
                }

                if (!success) {
                  Get.snackbar(
                    'Service',
                    'Unable to add service.',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    amountController.dispose();
  }

  // ---------------------------------------------------------------------------
  // Service icon
  // ---------------------------------------------------------------------------

  IconData _getServiceIcon(String name) {
    switch (name.trim().toLowerCase()) {
      case 'transport':
        return Icons.directions_bus_outlined;

      case 'laundry':
        return Icons.local_laundry_service_outlined;

      case 'internet':
        return Icons.wifi_outlined;

      case 'mess':
        return Icons.restaurant_outlined;

      case 'parking':
        return Icons.local_parking_outlined;

      default:
        return Icons.miscellaneous_services_outlined;
    }
  }

  // ---------------------------------------------------------------------------
  // Amount formatter
  // ---------------------------------------------------------------------------

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return 'Rs. $formatted / month';
  }
}

// =============================================================================
// Service option
// =============================================================================

class ServiceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double amount;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const ServiceOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.enabled,
    required this.onChanged,
  });

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return 'Rs. $formatted / month';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: enabled
            ? AppColors.primaryLight.withValues(alpha: 0.45)
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: enabled
              ? AppColors.primary
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 19,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _formatAmount(amount),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: enabled,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}