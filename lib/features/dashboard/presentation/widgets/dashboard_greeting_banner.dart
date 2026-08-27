import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardGreetingBanner extends StatelessWidget {
  final DashboardController controller;

  const DashboardGreetingBanner({super.key, required this.controller});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _firstName(String username) {
    if (username.trim().isEmpty) return '';
    final capitalized = username[0].toUpperCase() + username.substring(1);
    return capitalized;
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primarySoft, AppColors.canvas],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;

          final textColumn = Obx(() {
            final user = authController.currentUser.value;
            final name = user != null ? _firstName(user.username) : '';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_greeting()}${name.isEmpty ? '' : ', $name'} 👋',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: AppColors.primaryDeep,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Here\'s what\'s happening at the hostel today.',
                  style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
                ),
              ],
            );
          });

          final gauge = Obx(
            () => _CollectionGauge(
              percent: controller.collectionRatePercent,
            ),
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                textColumn,
                const SizedBox(height: 20),
                gauge,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: textColumn),
              const SizedBox(width: 20),
              gauge,
            ],
          );
        },
      ),
    );
  }
}

class _CollectionGauge extends StatelessWidget {
  final double percent;

  const _CollectionGauge({required this.percent});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDeep,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Collected',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}