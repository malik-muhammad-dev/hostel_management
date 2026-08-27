import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/theme/app_colors.dart';
import '../../features/auth/data/models/app_user_model.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class AppTopBar extends StatelessWidget {
  final String sectionTitle;

  const AppTopBar({super.key, required this.sectionTitle});

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.feeCollector:
        return 'Fee Collector';
    }
  }

  String _initials(String username) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // -----------------------------------------------------------------
          // Current section — tells the person where they are, rather than
          // repeating the brand name that already sits in the sidebar.
          // -----------------------------------------------------------------
          Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),

          const Spacer(),

          // -----------------------------------------------------------------
          // Notifications
          // -----------------------------------------------------------------
          _IconAction(
            icon: Icons.notifications_none_rounded,
            tooltip: 'Notifications',
            onPressed: () {},
          ),

          const SizedBox(width: 8),

          Container(
            width: 1,
            height: 28,
            color: AppColors.border,
          ),

          const SizedBox(width: 16),

          // -----------------------------------------------------------------
          // Signed-in user
          // -----------------------------------------------------------------
          Obx(() {
            final user = authController.currentUser.value;

            return Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    user != null ? _initials(user.username) : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user?.username ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user != null ? _roleLabel(user.role) : '',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),

          const SizedBox(width: 6),

          _IconAction(
            icon: Icons.logout_rounded,
            tooltip: 'Sign out',
            onPressed: authController.logout,
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.primarySoft : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.icon,
              size: 20,
              color: _hovered
                  ? AppColors.primaryDeep
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}