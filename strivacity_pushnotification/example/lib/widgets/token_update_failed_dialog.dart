import 'package:flutter/material.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'outline_button.dart';

/// Tells the user which enrollments could not be given the new push token.
Future<void> showTokenUpdateFailedDialog(BuildContext context, List<Enrollment> enrollments) => showDialog<void>(
  context: context,
  builder: (context) =>
      TokenUpdateFailedDialog(enrollments: enrollments, onClosed: () => Navigator.of(context).pop()),
);

/// The dialog's content.
class TokenUpdateFailedDialog extends StatelessWidget {
  const TokenUpdateFailedDialog({required this.enrollments, required this.onClosed, super.key});

  final List<Enrollment> enrollments;
  final VoidCallback onClosed;

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
              'Some enrollments were not updated',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textTitle,
              ),
            ),
            const Text(
              'The server did not accept this device’s new push token for the enrollments below. '
              'Sign-in requests for them may not arrive until they are updated.',
              style: _bodyStyle,
            ),
            for (final enrollment in enrollments)
              Text(
                '• ${enrollment.userName ?? enrollment.accountId} at ${enrollment.issuer}',
                style: _bodyStyle.copyWith(fontWeight: FontWeight.w600, color: AppColors.textTitle),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: OutlineButton(label: 'OK', onPressed: onClosed),
            ),
          ],
        ),
      ),
    ),
  );
}
