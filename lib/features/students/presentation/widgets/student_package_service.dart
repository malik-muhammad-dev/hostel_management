import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/models/student_model.dart';
import '../controllers/student_service_controller.dart';

class StudentPackageServices extends StatelessWidget {
  final StudentModel student;

  const StudentPackageServices({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPackageCard(),
        const SizedBox(height: 20),
        _ServicesCard(student: student),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Package / Fee
  // ---------------------------------------------------------------------------

  Widget _buildPackageCard() {
    final monthlyFee =
        student.netMonthlyFee ?? student.monthlyFee ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              SizedBox(width: 10),
              Text(
                'Fee Configuration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  label: 'Monthly Fee',
                  value: _formatAmount(monthlyFee),
                ),
              ),
              Expanded(
                child: _InfoItem(
                  label: 'Package Start',
                  value: student.packageStartDate ?? '-',
                ),
          )],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Amount
  // ---------------------------------------------------------------------------

  String _formatAmount(double amount) {
    final formatted = amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return 'Rs. $formatted';
  }
}

// =============================================================================
// Services Card
// =============================================================================

class _ServicesCard extends StatelessWidget {
  final StudentModel student;

  const _ServicesCard({
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final serviceController =
        Get.find<StudentServiceController>();

    // Load services for this student.
    //
    // The controller itself prevents unnecessary reloads when the same
    // student is already selected.
    if (student.id != null &&
        serviceController.selectedStudentId.value != student.id) {
      serviceController.loadServices(student.id!);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -----------------------------------------------------------------
          // Header
          // -----------------------------------------------------------------

          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Services',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Services currently assigned to this student',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              OutlinedButton.icon(
                onPressed: student.id == null
                    ? null
                    : () {
                        _showAddServiceDialog(
                          context,
                          serviceController,
                          student.id!,
                        );
                      },
                icon: const Icon(
                  Icons.add_rounded,
                  size: 17,
                ),
                label: const Text('Add Service'),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // -----------------------------------------------------------------
          // Dynamic services
          // -----------------------------------------------------------------

          Obx(
            () {
              if (serviceController.isLoading.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 24,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final services =
                  serviceController.services.toList();

              if (services.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: services.map(
                  (service) {
                    return Padding(
                      padding: const EdgeInsets.only(
                        bottom: 12,
                      ),
                      child: _ServiceItem(
                        icon: _getServiceIcon(
                          service.name,
                        ),
                        name: service.name,
                        description:
                            service.description ??
                                'Student service',
                        amount: service.monthlyAmount,
                        isActive: service.isActive,
                        onToggle: (value) async {
                          await serviceController
                              .setServiceActive(
                            service,
                            value,
                          );
                        },
                      ),
                    );
                  },
                ).toList(),
              );
            },
          ),
        ],
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
        vertical: 22,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.miscellaneous_services_outlined,
            size: 28,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 8),
          Text(
            'No services assigned',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Add a service if this student uses an additional service.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
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
    StudentServiceController controller,
    int studentId,
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
                  keyboardType:
                      const TextInputType.numberWithOptions(
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
                final name =
                    nameController.text.trim();

                final description =
                    descriptionController.text.trim();

                final amount =
                    double.tryParse(
                  amountController.text.trim(),
                );

                if (name.isEmpty) {
                  Get.snackbar(
                    'Invalid Service',
                    'Please enter a service name.',
                    snackPosition:
                        SnackPosition.BOTTOM,
                  );
                  return;
                }

                if (amount == null || amount <= 0) {
                  Get.snackbar(
                    'Invalid Amount',
                    'Please enter a valid monthly amount.',
                    snackPosition:
                        SnackPosition.BOTTOM,
                  );
                  return;
                }

                final success =
                    await controller.addService(
                  studentId: studentId,
                  name: name,
                  description: description.isEmpty
                      ? null
                      : description,
                  monthlyAmount: amount,
                );

                if (!success) {
                  if (!dialogContext.mounted) {
                    return;
                  }

                  Get.snackbar(
                    'Service',
                    'Unable to add service.',
                    snackPosition:
                        SnackPosition.BOTTOM,
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
}

// =============================================================================
// Service item
// =============================================================================

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String name;
  final String description;
  final double amount;
  final bool isActive;
  final ValueChanged<bool> onToggle;

  const _ServiceItem({
    required this.icon,
    required this.name,
    required this.description,
    required this.amount,
    required this.isActive,
    required this.onToggle,
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
        color: isActive
            ? AppColors.primaryLight.withValues(
                alpha: 0.45,
              )
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? AppColors.primary
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
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
            value: isActive,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Info item
// =============================================================================

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;

  const _InfoItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
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