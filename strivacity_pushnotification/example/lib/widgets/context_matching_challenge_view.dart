import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'challenge_summary.dart';
import 'number_button.dart';
import 'outline_button.dart';
import 'screen_header.dart';
import 'screen_layout.dart';

/// The screen for a challenge that asks to pick the number shown on the sign-in screen.
class ContextMatchingChallengeView extends StatelessWidget {
  const ContextMatchingChallengeView({
    required this.account,
    required this.metadata,
    required this.options,
    required this.onSelected,
    required this.onDeny,
    super.key,
  });

  final String account;
  final Map<String, String?> metadata;
  final List<String> options;

  /// Null disables the numbers, as does [onDeny] being null for Deny.
  final ValueChanged<String>? onSelected;
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
              'Select the number shown on the sign-in screen, or deny if this was not you.',
              style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, height: 1.5, color: AppColors.textBody),
            ),
            NumberGrid(options: options, onSelected: onSelected),
          ],
        ),
      ],
    ),
  );
}
