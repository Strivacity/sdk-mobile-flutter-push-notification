/// Previews of the app's widgets, for the widget previewer. Nothing in the app uses this file.
library;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import 'features/splash/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/colors.dart';
import 'widgets/account_block.dart';
import 'widgets/app_card.dart';
import 'widgets/app_text_field.dart';
import 'widgets/challenge_metadata.dart';
import 'widgets/challenge_summary.dart';
import 'widgets/context_matching_challenge_view.dart';
import 'widgets/danger_button.dart';
import 'widgets/device_name_sheet.dart';
import 'widgets/enrollment_list_item.dart';
import 'widgets/number_button.dart';
import 'widgets/outline_button.dart';
import 'widgets/primary_button.dart';
import 'widgets/screen_header.dart';
import 'widgets/screen_layout.dart';
import 'widgets/simple_challenge_view.dart';
import 'widgets/status_banner.dart';
import 'widgets/token_update_failed_dialog.dart';
import 'widgets/unenroll_dialog.dart';

/// Applies [AppTheme.data] to a preview.
Widget previewWrapper(Widget child) => Theme(data: AppTheme.data, child: child);

const _metadata = {
  'loginTimestamp': '10:42 AM, Oct 1, 2026',
  'deviceInfo': 'Chrome 141 on macOS 15',
  'location': 'Austin, Texas, US',
};

// SplashScreen

/// Shows the splash screen in the widget previewer.
@Preview(name: 'Splash screen', size: Size(390, 844))
Widget splashScreenPreview() =>
    const SplashScreen(logoText: 'Authenticator', footerText: 'Device Enrollment Example App');

// AccountBlock

/// An ordinary account.
@Preview(name: 'Account block', group: 'AccountBlock', size: Size(390, 130), wrapper: previewWrapper)
Widget accountBlockPreview() =>
    const Padding(padding: EdgeInsets.all(20), child: AccountBlock(account: 'jane.doe@strivacity.com'));

/// A long account that wraps.
@Preview(name: 'Long account', group: 'AccountBlock', size: Size(390, 170), wrapper: previewWrapper)
Widget accountBlockLongPreview() => const Padding(
  padding: EdgeInsets.all(20),
  child: AccountBlock(account: 'a.very.long.account.name.that.does.not.fit+test@strivacity.com'),
);

// AppCard

/// Card with a heading and text.
@Preview(name: 'Card', group: 'AppCard', size: Size(390, 200), wrapper: previewWrapper)
Widget appCardPreview() => const Padding(
  padding: EdgeInsets.all(20),
  child: AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        Text(
          'This device is not enrolled',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textTitle,
          ),
        ),
        Text(
          'Enroll this device to approve sign-in requests as a second step '
          'with a push notification.',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14,
            height: 1.5,
            color: AppColors.textBody,
          ),
        ),
      ],
    ),
  ),
);

// AppTextField

/// Empty, showing the hint.
@Preview(name: 'Empty', group: 'AppTextField', size: Size(390, 150), wrapper: previewWrapper)
Widget appTextFieldPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: AppTextField(label: 'Device name', hint: 'For example, My phone', controller: TextEditingController()),
);

/// With text.
@Preview(name: 'Filled', group: 'AppTextField', size: Size(390, 150), wrapper: previewWrapper)
Widget appTextFieldFilledPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: AppTextField(label: 'Device name', controller: TextEditingController(text: "Jane's Pixel 8")),
);

/// With an error.
@Preview(name: 'Error', group: 'AppTextField', size: Size(390, 150), wrapper: previewWrapper)
Widget appTextFieldErrorPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: AppTextField(
    label: 'Device name',
    controller: TextEditingController(),
    errorText: 'Enter a device name',
  ),
);

/// Live: submit empty to see the error; typing clears it.
@Preview(name: 'Interactive', group: 'AppTextField', size: Size(390, 300), wrapper: previewWrapper)
Widget appTextFieldInteractivePreview() => const _InteractiveField();

class _InteractiveField extends StatefulWidget {
  const _InteractiveField();

  @override
  State<_InteractiveField> createState() => _InteractiveFieldState();
}

class _InteractiveFieldState extends State<_InteractiveField> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: AppTextField(
      label: 'Device name',
      hint: 'For example, My phone',
      controller: _controller,
      errorText: _error,
      maxLength: 64,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      onSubmitted: (value) => setState(() => _error = value.trim().isEmpty ? 'Enter a device name' : null),
    ),
  );
}

/// Inside a card, as in a form.
@Preview(name: 'In a card', group: 'AppTextField', size: Size(390, 190), wrapper: previewWrapper)
Widget appTextFieldInCardPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: AppCard(
    child: AppTextField(label: 'Device name', controller: TextEditingController(text: "Jane's Pixel 8")),
  ),
);

// ChallengeMetadata

/// The usual keys.
@Preview(name: 'Usual keys', group: 'ChallengeMetadata', size: Size(390, 170), wrapper: previewWrapper)
Widget challengeMetadataPreview() =>
    const Padding(padding: EdgeInsets.all(20), child: ChallengeMetadata(metadata: _metadata));

/// A null value, an empty one and an unknown key.
@Preview(name: 'Odd entries', group: 'ChallengeMetadata', size: Size(390, 170), wrapper: previewWrapper)
Widget challengeMetadataOddPreview() => const Padding(
  padding: EdgeInsets.all(20),
  child: ChallengeMetadata(metadata: {'deviceInfo': 'Chrome on MacOS', 'location': null, 'ipAddress': '203.0.113.7', 'note': ''}),
);

// ChallengeSummary

/// With the usual details.
@Preview(name: 'Challenge summary', group: 'ChallengeSummary', size: Size(390, 400), wrapper: previewWrapper)
Widget challengeSummaryPreview() => const Padding(
  padding: EdgeInsets.all(20),
  child: ChallengeSummary(account: 'jane.doe@strivacity.com', metadata: _metadata),
);

// ContextMatchingChallengeView

/// Three options, ready to answer.
@Preview(name: 'Context matching', group: 'ContextMatchingChallengeView', size: Size(390, 844), wrapper: previewWrapper)
Widget contextMatchingChallengeViewPreview() => ContextMatchingChallengeView(
  account: 'jane.doe@strivacity.com',
  metadata: _metadata,
  options: const ['27', '64', '81'],
  onSelected: (_) {},
  onDeny: () {},
);

/// While an answer is being submitted.
@Preview(name: 'Buttons disabled', group: 'ContextMatchingChallengeView', size: Size(390, 844), wrapper: previewWrapper)
Widget contextMatchingChallengeViewDisabledPreview() => const ContextMatchingChallengeView(
  account: 'jane.doe@strivacity.com',
  metadata: _metadata,
  options: ['27', '64', '81'],
  onSelected: null,
  onDeny: null,
);

// DangerButton

/// Enabled and disabled.
@Preview(name: 'Danger button', group: 'DangerButton', size: Size(390, 140), wrapper: previewWrapper)
Widget dangerButtonPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 12,
    children: [
      DangerButton(label: 'Unenroll', onPressed: () {}),
      const DangerButton(label: 'Unenroll', onPressed: null),
    ],
  ),
);

// DeviceNameSheet

/// Opens the real sheet; logs the name.
@Preview(name: 'Opened from a button', group: 'DeviceNameSheet', size: Size(390, 600), wrapper: previewWrapper)
Widget deviceNameSheetOpenerPreview() => const _SheetOpener();

class _SheetOpener extends StatelessWidget {
  const _SheetOpener();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: PrimaryButton(
          label: 'Name this device',
          onPressed: () async => debugPrint('Named: ${await showDeviceNameSheet(context)}'),
        ),
      ),
    ),
  );
}

/// Sheet content; tap Enroll while empty to see the error.
@Preview(name: 'Device name sheet', group: 'DeviceNameSheet', size: Size(390, 340), wrapper: previewWrapper)
Widget deviceNameSheetPreview() => Align(
  alignment: Alignment.bottomCenter,
  child: DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: DeviceNameSheet(onSubmitted: (_) {}, onCancelled: () {}),
  ),
);

// EnrollmentListItem

/// A single item.
@Preview(name: 'One item', group: 'EnrollmentListItem', size: Size(390, 170), wrapper: previewWrapper)
Widget enrollmentListItemPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: AppCard(
    child: EnrollmentListItem(
      deviceName: "Jane's Pixel 8",
      issuer: 'https://login.strivacity.com',
      account: 'jane.doe@strivacity.com',
      showDivider: false,
      onUnenroll: () {},
    ),
  ),
);

/// Two items stacked in a card.
@Preview(name: 'Two items', group: 'EnrollmentListItem', size: Size(390, 330), wrapper: previewWrapper)
Widget enrollmentListItemsPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: AppCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EnrollmentListItem(
          deviceName: "Jane's Pixel 8",
          issuer: 'https://login.strivacity.com',
          account: 'jane.doe@strivacity.com',
          showDivider: false,
          onUnenroll: () {},
        ),
        EnrollmentListItem(
          deviceName: "Jane's Pixel 8 (Sandbox)",
          issuer: 'https://sandbox.strivacity.com',
          account: 'jane.doe+test@strivacity.com',
          onUnenroll: () {},
        ),
      ],
    ),
  ),
);

/// Long values wrapping.
@Preview(name: 'Long values', group: 'EnrollmentListItem', size: Size(390, 240), wrapper: previewWrapper)
Widget enrollmentListItemLongValuesPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: AppCard(
    child: EnrollmentListItem(
      deviceName: "Jane's Pixel 8 with a rather long device name",
      issuer: 'https://a-very-long-tenant-name.login.strivacity.example.com/path',
      account: 'a.very.long.account.name.that.does.not.fit+test@strivacity.com',
      showDivider: false,
      onUnenroll: () {},
    ),
  ),
);

// NumberButton, NumberGrid

/// One button, enabled and disabled.
@Preview(name: 'Number button', group: 'NumberButton', size: Size(390, 190), wrapper: previewWrapper)
Widget numberButtonPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    spacing: 12,
    children: [
      SizedBox(width: 110, child: NumberButton(label: '64', onPressed: () {})),
      const SizedBox(width: 110, child: NumberButton(label: '64', onPressed: null)),
    ],
  ),
);

/// Three options.
@Preview(name: 'Three options', group: 'NumberGrid', size: Size(390, 120), wrapper: previewWrapper)
Widget numberGridPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: NumberGrid(options: const ['27', '64', '81'], onSelected: (_) {}),
);

/// Five options wrapping onto a second row.
@Preview(name: 'Five options', group: 'NumberGrid', size: Size(390, 200), wrapper: previewWrapper)
Widget numberGridFivePreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: NumberGrid(options: const ['10', '26', '33', '48', '95'], onSelected: (_) {}),
);

// OutlineButton

/// Enabled and disabled.
@Preview(name: 'Outline button', group: 'OutlineButton', size: Size(390, 140), wrapper: previewWrapper)
Widget outlineButtonPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 12,
    children: [
      OutlineButton(label: 'Cancel', onPressed: () {}),
      const OutlineButton(label: 'Cancel', onPressed: null),
    ],
  ),
);

/// Full-width destructive, as for Deny.
@Preview(name: 'Expanded, destructive', group: 'OutlineButton', size: Size(390, 140), wrapper: previewWrapper)
Widget outlineButtonDestructivePreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: Column(
    spacing: 12,
    children: [
      OutlineButton(label: 'Deny', onPressed: () {}, expanded: true, destructive: true),
      const OutlineButton(label: 'Deny', onPressed: null, expanded: true, destructive: true),
    ],
  ),
);

// PrimaryButton

/// Enabled.
@Preview(name: 'Enabled', group: 'PrimaryButton', size: Size(390, 88), wrapper: previewWrapper)
Widget primaryButtonPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: PrimaryButton(label: 'Enroll this device', onPressed: () {}),
);

/// Loading.
@Preview(name: 'Loading', group: 'PrimaryButton', size: Size(390, 88), wrapper: previewWrapper)
Widget primaryButtonLoadingPreview() => Padding(
  padding: const EdgeInsets.all(20),
  child: PrimaryButton(label: 'Enroll this device', onPressed: () {}, loading: true),
);

/// Disabled.
@Preview(name: 'Disabled', group: 'PrimaryButton', size: Size(390, 88), wrapper: previewWrapper)
Widget primaryButtonDisabledPreview() => const Padding(
  padding: EdgeInsets.all(20),
  child: PrimaryButton(label: 'Enroll this device', onPressed: null),
);

// ScreenHeader

/// Title only.
@Preview(name: 'Title only', group: 'ScreenHeader', size: Size(390, 120), wrapper: previewWrapper)
Widget screenHeaderPreview() => const ScreenHeader(title: 'Enrollments');

/// Title and subtitle.
@Preview(name: 'Title and subtitle', group: 'ScreenHeader', size: Size(390, 120), wrapper: previewWrapper)
Widget screenHeaderWithSubtitlePreview() =>
    const ScreenHeader(title: 'Jane Doe', subtitle: 'jane.doe@strivacity.com');

/// Long text, ellipsized.
@Preview(name: 'Long text', group: 'ScreenHeader', size: Size(390, 120), wrapper: previewWrapper)
Widget screenHeaderLongTextPreview() => const ScreenHeader(
  title: 'A very long title that does not fit on one line',
  subtitle: 'a.very.long.email.address.that.does.not.fit@strivacity.com',
);

// ScreenLayout

/// Content that fits.
@Preview(name: 'App screen', group: 'AppScreen', size: Size(390, 844), wrapper: previewWrapper)
Widget appScreenPreview() => const ScreenLayout(
  header: _PlaceholderHeader(),
  footer: Text('Footer', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [_Placeholder('Content'), _Placeholder('Content')],
  ),
);

/// Content that scrolls.
@Preview(name: 'App screen, scrolling content', group: 'AppScreen', size: Size(390, 600), wrapper: previewWrapper)
Widget appScreenScrollingPreview() => ScreenLayout(
  header: const _PlaceholderHeader(),
  footer: const Text('Footer', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [for (var i = 1; i <= 8; i++) _Placeholder('Content $i')],
  ),
);

/// Stands in for real content, which has its own previews.
class _Placeholder extends StatelessWidget {
  const _Placeholder(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 96,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
  );
}

/// Stands in for the real header, which has its own previews.
class _PlaceholderHeader extends StatelessWidget {
  const _PlaceholderHeader();

  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceDark,
    padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
    child: const SafeArea(
      bottom: false,
      child: Text(
        'Header',
        style: TextStyle(color: AppColors.textOnDark, fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

// SimpleChallengeView

/// Ready to answer.
@Preview(name: 'Simple challenge', group: 'SimpleChallengeView', size: Size(390, 844), wrapper: previewWrapper)
Widget simpleChallengeViewPreview() =>
    SimpleChallengeView(account: 'jane.doe@strivacity.com', metadata: _metadata, onApprove: () {}, onDeny: () {});

/// While an answer is being submitted.
@Preview(name: 'Buttons disabled', group: 'SimpleChallengeView', size: Size(390, 844), wrapper: previewWrapper)
Widget simpleChallengeViewDisabledPreview() => const SimpleChallengeView(
  account: 'jane.doe@strivacity.com',
  metadata: _metadata,
  onApprove: null,
  onDeny: null,
);

// StatusBanner

/// A short message.
@Preview(name: 'Status banner', group: 'StatusBanner', size: Size(390, 100), wrapper: previewWrapper)
Widget statusBannerPreview() =>
    const Padding(padding: EdgeInsets.all(20), child: StatusBanner(message: 'Updating enrollments…'));

/// A message that wraps.
@Preview(name: 'Long message', group: 'StatusBanner', size: Size(390, 130), wrapper: previewWrapper)
Widget statusBannerLongPreview() => const Padding(
  padding: EdgeInsets.all(20),
  child: StatusBanner(message: 'Updating your enrollments with the new push token. This only takes a moment.'),
);

// TokenUpdateFailedDialog

/// Two enrollments.
@Preview(name: 'Token update failed', group: 'TokenUpdateFailedDialog', size: Size(390, 520), wrapper: previewWrapper)
Widget tokenUpdateFailedDialogPreview() => Center(
  child: TokenUpdateFailedDialog(
    enrollments: const [
      Enrollment(
        issuer: 'https://login.strivacity.com',
        accountId: 'jane.doe@strivacity.com',
        keyId: 'key-1',
      ),
      Enrollment(
        issuer: 'https://sandbox.strivacity.com',
        accountId: 'jane.doe+test@strivacity.com',
        keyId: 'key-2',
        userName: 'Jane (sandbox)',
      ),
    ],
    onClosed: () {},
  ),
);

// UnenrollDialog

/// Dialog content.
@Preview(name: 'Unenroll dialog', group: 'UnenrollDialog', size: Size(390, 460), wrapper: previewWrapper)
Widget unenrollDialogPreview() => Center(
  child: UnenrollDialog(
    account: 'jane.doe@strivacity.com',
    issuer: 'https://login.strivacity.com',
    onConfirmed: () {},
    onCancelled: () {},
  ),
);

/// Opens the real dialog; logs the result.
@Preview(name: 'Opened from a button', group: 'UnenrollDialog', size: Size(390, 600), wrapper: previewWrapper)
Widget unenrollDialogOpenerPreview() => const _DialogOpener();

class _DialogOpener extends StatelessWidget {
  const _DialogOpener();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: OutlineButton(
        label: 'Unenroll…',
        onPressed: () async => debugPrint(
          'Confirmed: ${await showUnenrollDialog(context, account: 'jane.doe@strivacity.com', issuer: 'https://login.strivacity.com')}',
        ),
      ),
    ),
  );
}
