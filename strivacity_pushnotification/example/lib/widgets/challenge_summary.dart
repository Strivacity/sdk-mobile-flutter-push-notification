import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'account_block.dart';
import 'challenge_metadata.dart';

/// The question, the account and the details of a sign-in request, as the top of either challenge
/// screen.
class ChallengeSummary extends StatelessWidget {
  const ChallengeSummary({required this.account, required this.metadata, super.key});

  final String account;
  final Map<String, String?> metadata;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 20,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          const Text(
            'Approve this sign-in?',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textTitle,
            ),
          ),
          AccountBlock(account: account),
        ],
      ),
      ChallengeMetadata(metadata: metadata),
    ],
  );
}
