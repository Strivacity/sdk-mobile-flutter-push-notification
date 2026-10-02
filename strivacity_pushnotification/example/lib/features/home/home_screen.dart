import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/device_name_sheet.dart';
import '../../widgets/enrollment_list_item.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/screen_layout.dart';
import '../../widgets/status_banner.dart';
import '../../widgets/token_update_failed_dialog.dart';
import '../../widgets/unenroll_dialog.dart';
import 'home_state.dart';
import 'home_view_model.dart';

/// Home: enroll this device, list its enrollments.
class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.createViewModel, super.key});

  /// Called once, when the screen is first built; the screen owns and disposes what it returns.
  final HomeViewModel Function() createViewModel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HomeViewModel _viewModel = widget.createViewModel();

  /// The state as of the last change, to tell which one-time effects a change calls for.
  late HomeState _previous = _viewModel.state.peek();

  @override
  void initState() {
    super.initState();
    // After the first frame, so a change that is already due (a finished token update) can open a
    // dialog, and the effect in build sees it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_viewModel.start());
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// Only the state is tracked: the reactions read and change it themselves.
  void _reactToState(BuildContext context) {
    final current = _viewModel.state.value;
    untracked(() => _onStateChanged(current));
  }

  void _onStateChanged(HomeState current) {
    final previous = _previous;
    _previous = current;
    if (previous.pendingGrant == null && current.pendingGrant != null) unawaited(_askForDeviceName());
    if (current.notice != null && current.notice != previous.notice) _showNotice(current.notice!);
    if (previous.tokenUpdateFailures == null && current.tokenUpdateFailures != null) {
      unawaited(_showTokenUpdateFailures(current.tokenUpdateFailures!));
    }
  }

  Future<void> _showTokenUpdateFailures(List<Enrollment> enrollments) async {
    await showTokenUpdateFailedDialog(context, enrollments);
    if (mounted) _viewModel.tokenUpdateFailuresShown();
  }

  Future<void> _scan() async {
    // Routes from `MaterialApp.routes` are untyped, so the result is cast rather than asked for.
    final url = await Navigator.of(context).pushNamed(AppRoute.scan) as String?;
    if (url != null && mounted) unawaited(_viewModel.enrollmentScanned(url));
  }

  Future<void> _askForDeviceName() async {
    final name = await showDeviceNameSheet(context);
    if (!mounted) return;
    if (name == null) {
      _viewModel.enrollmentCancelled();
    } else {
      unawaited(_viewModel.deviceNameSubmitted(name));
    }
  }

  Future<void> _confirmUnenroll(Enrollment enrollment) async {
    final confirmed = await showUnenrollDialog(
      context,
      account: enrollment.userName ?? enrollment.accountId,
      issuer: enrollment.issuer,
    );
    if (confirmed == true && mounted) unawaited(_viewModel.unenrollConfirmed(enrollment));
  }

  void _showNotice(HomeNotice notice) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(notice.message),
          backgroundColor: switch (notice.kind) {
            HomeNoticeKind.success => AppColors.success,
            HomeNoticeKind.info => AppColors.info,
            HomeNoticeKind.error => AppColors.danger,
          },
        ),
      );
    _viewModel.noticeShown();
  }

  @override
  Widget build(BuildContext context) => SignalEffect(
    effect: _reactToState,
    child: _HomeLayout(
      state: _viewModel.state,
      onEnroll: _scan,
      onUnenroll: (enrollment) => unawaited(_confirmUnenroll(enrollment)),
    ),
  );
}

class _HomeLayout extends StatelessWidget {
  const _HomeLayout({required this.state, required this.onEnroll, required this.onUnenroll});

  final ReadonlySignal<HomeState> state;
  final VoidCallback onEnroll;
  final ValueChanged<Enrollment> onUnenroll;

  static const _headingStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textTitle,
  );
  static const _bodyStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14,
    height: 1.5,
    color: AppColors.textBody,
  );
  static const _footnoteStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) => ScreenLayout(
    header: const ScreenHeader(title: 'Enrollments'),
    footer: const Text('Version 1.0.0', textAlign: TextAlign.center, style: _footnoteStyle),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: [
        SignalBuilder(
          builder: (context) => state.value.tokenUpdating
              ? const StatusBanner(message: 'Updating enrollments…')
              : const SizedBox.shrink(),
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              const Text(
                'Enroll this device for another account to approve its sign-in requests here too.',
                style: _bodyStyle,
              ),
              SignalBuilder(
                builder: (context) => PrimaryButton(
                  label: 'Enroll this device',
                  loading: _isEnrollButtonLoading(state.value),
                  onPressed: onEnroll,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            const Text('Enrollments', style: _headingStyle),
            AppCard(
              child: SignalBuilder(builder: (context) => _EnrollmentList(state.value, onUnenroll: onUnenroll)),
            ),
          ],
        ),
      ],
    ),
  );

  static bool _isEnrollButtonLoading(HomeState state) => state.status == HomeStatus.loading || state.enrolling;
}

/// The enrollments, or a stand-in while loading, on failure, or when empty.
class _EnrollmentList extends StatelessWidget {
  const _EnrollmentList(this.state, {required this.onUnenroll});

  final HomeState state;
  final ValueChanged<Enrollment> onUnenroll;

  static const _quietStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 14,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  @override
  Widget build(BuildContext context) => switch (state.status) {
    HomeStatus.loading => const Center(
      child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
    ),
    HomeStatus.failure => const Text('The enrollments could not be loaded.', style: _quietStyle),
    HomeStatus.ready when state.enrollments.isEmpty => const Text(
      'No devices are enrolled. Push requests will not arrive until you enroll a device.',
      style: _quietStyle,
    ),
    HomeStatus.ready => Column(
      children: [
        for (final (index, enrollment) in state.enrollments.indexed)
          EnrollmentListItem(
            deviceName: enrollment.deviceName ?? 'This device',
            issuer: enrollment.issuer,
            account: enrollment.userName ?? enrollment.accountId,
            showDivider: index > 0,
            // Off while the backend is being told about a new push token, which unenrolling would race.
            onUnenroll: state.tokenUpdating ? null : () => onUnenroll(enrollment),
          ),
      ],
    ),
  };
}
