import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../constants/app_constants.dart';

class AppSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<int>? visibleIndexes;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.visibleIndexes,
  });

  @override
  Widget build(BuildContext context) {
    final allItems = [
      (Icons.dashboard_rounded, 'Dashboard'),
      (Icons.people_alt_rounded, 'Students'),
      (Icons.payments_rounded, 'Fees'),
      (Icons.receipt_long_rounded, 'Expenses'),
      (Icons.bar_chart_rounded, 'Reports'),
    ];

    // Pair each item with its original index so filtering never shifts
    // which page a tap actually opens.
    final visibleEntries = List.generate(allItems.length, (i) => i)
        .where((i) => visibleIndexes == null || visibleIndexes!.contains(i))
        .map((i) => (index: i, item: allItems[i]))
        .toList();

    return Container(
      width: 252,
      color: AppColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 28),

          // -------------------------------------------------------------------
          // Brand mark
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Image.asset('assets/images/logo.png'),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.1,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Hostel Management'.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppColors.border),
          ),

          const SizedBox(height: 16),

          // -------------------------------------------------------------------
          // Navigation
          // -------------------------------------------------------------------
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: visibleEntries.length,
              itemBuilder: (context, position) {
                final entry = visibleEntries[position];

                return _SidebarItem(
                  icon: entry.item.$1,
                  title: entry.item.$2,
                  isSelected: selectedIndex == entry.index,
                  onTap: () => onItemSelected(entry.index),
                );
              },
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(height: 1, color: AppColors.border),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  'v${AppConstants.appVersion}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
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

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = widget.isSelected || isHovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.primarySoft
                : isHovered
                ? AppColors.primarySoft.withValues(alpha: 0.55)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // Signature active-indicator: the one place gold and purple
              // meet, reading as a seal-like mark rather than a decoration.
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.accentGold
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(width: 11),

              Icon(
                widget.icon,
                size: 20,
                color: highlighted
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 14,
                    letterSpacing: -0.1,
                    color: highlighted
                        ? AppColors.primaryDeep
                        : AppColors.textPrimary,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}