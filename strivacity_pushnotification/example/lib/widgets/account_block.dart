import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// The account a sign-in request is for, in a tinted panel.
class AccountBlock extends StatelessWidget {
  const AccountBlock({required this.account, super.key});

  final String account;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.primaryTint,
      border: Border.all(color: AppColors.primaryBorder),
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          const Text(
            'ACCOUNT',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.96,
              color: AppColors.primary,
            ),
          ),
          Text(
            account,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textTitle,
            ),
          ),
        ],
      ),
    ),
  );
}
