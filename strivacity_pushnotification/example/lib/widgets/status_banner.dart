import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// A line of status with a spinner, for something that is under way and will clear by itself.
class StatusBanner extends StatelessWidget {
  const StatusBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.primaryTint,
      border: Border.all(color: AppColors.primaryBorder),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        spacing: 12,
        children: [
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                height: 1.4,
                color: AppColors.textTitle,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
