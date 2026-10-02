import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'danger_button.dart';
import 'outline_button.dart';

/// Confirms removing [account]'s enrollment at [issuer]; true when confirmed.
Future<bool?> showUnenrollDialog(BuildContext context, {required String account, required String issuer}) =>
    showDialog<bool>(
      context: context,
      builder: (context) => UnenrollDialog(
        account: account,
        issuer: issuer,
        onConfirmed: () => Navigator.of(context).pop(true),
        onCancelled: () => Navigator.of(context).pop(false),
      ),
    );

/// The dialog's content.
class UnenrollDialog extends StatelessWidget {
  const UnenrollDialog({
    required this.account,
    required this.issuer,
    required this.onConfirmed,
    required this.onCancelled,
    super.key,
  });

  final String account;
  final String issuer;
  final VoidCallback onConfirmed;
  final VoidCallback onCancelled;

  static const _bodyStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14,
    height: 1.5,
    color: AppColors.textBody,
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.surface,
    surfaceTintColor: Colors.transparent,
    insetPadding: const EdgeInsets.all(20),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            const Text(
              'Confirm unenrollment',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textTitle,
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'This device will stop receiving push notifications for '),
                  TextSpan(
                    text: account,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' at $issuer.'),
                ],
              ),
              style: _bodyStyle,
            ),
            const Text(
              'You will no longer be able to approve its sign-in requests from this device. '
              'To receive them again, enroll this device again.',
              style: _bodyStyle,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                DangerButton(label: 'Unenroll', onPressed: onConfirmed),
                OutlineButton(label: 'Cancel', onPressed: onCancelled),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
