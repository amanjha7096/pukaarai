import 'package:flutter/material.dart';
import 'package:tracking/core/constants/app_constants.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.onChanged,
    this.obscureText = false,
    this.prefixIcon,
    this.keyboardType,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(color: AppColors.textSecondary),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
            : null,
      ),
    );
  }
}
