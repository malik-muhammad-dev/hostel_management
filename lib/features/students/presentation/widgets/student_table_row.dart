import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class StudentTableRow extends StatefulWidget {
  final String name;
  final String studentId;
  final String program;
  final String contact;
  final bool isActive;
  final VoidCallback onTap;

  const StudentTableRow({
    super.key,
    required this.name,
    required this.studentId,
    required this.program,
    required this.contact,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<StudentTableRow> createState() => _StudentTableRowState();
}

class _StudentTableRowState extends State<StudentTableRow> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          isHovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          isHovered = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isHovered
              ? AppColors.primaryLight.withValues(alpha: 0.35)
              : AppColors.surface,
          border: const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                widget.name.substring(0, 1),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(width: 15),

            // Name
            Expanded(
              flex: 3,
              child: Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // ID
            Expanded(
              flex: 2,
              child: Text(
                widget.studentId,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // Program
            Expanded(
              flex: 2,
              child: Text(
                widget.program,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // Contact
            Expanded(
              flex: 2,
              child: Text(
                widget.contact,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            // Status
            SizedBox(
              width: 90,
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 7),

                  Text(
                    widget.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: widget.isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // More button
            SizedBox(
              width: 30,
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: widget.onTap,
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
