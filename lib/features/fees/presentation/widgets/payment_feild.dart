import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class PaymentField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? suffixIcon;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool enabled;

  const PaymentField({
    super.key,
    required this.label,
    required this.hint,
    this.suffixIcon,
    this.controller,
    this.keyboardType,
    this.enabled = true,
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
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon == null ? null : Icon(suffixIcon, size: 18),
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
