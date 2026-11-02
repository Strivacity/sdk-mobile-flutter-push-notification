import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'challenge_summary.dart';
import 'outline_button.dart';
import 'primary_button.dart';
import 'screen_header.dart';
import 'screen_layout.dart';

/// The screen for a challenge that asks only to approve or deny.
class SimpleChallengeView extends StatelessWidget {
  const SimpleChallengeView({
    required this.account,
    required this.metadata,
    required this.onApprove,
    required this.onDeny,
    super.key,
  });

  final String account;
  final Map<String, String?> metadata;

  /// Null disables Approve, as does [onDeny] being null for Deny.
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;

  @override
  Widget build(BuildContext context) => ScreenLayout(
    header: const ScreenHeader(title: 'Authenticator', subtitle: 'Sign-in request'),
    footer: OutlineButton(label: 'Deny', onPressed: onDeny, expanded: true, destructive: true),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        ChallengeSummary(account: account, metadata: metadata),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            const Text(
              'Approve if you are signing in, or deny if this was not you.',
              style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, height: 1.5, color: AppColors.textBody),
            ),
            PrimaryButton(label: 'Approve', onPressed: onApprove),
          ],
        ),
      ],
    ),
  );
}
