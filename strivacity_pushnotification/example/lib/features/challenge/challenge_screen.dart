import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:strivacity_pushnotification/strivacity_pushnotification.dart';

import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/context_matching_challenge_view.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/screen_layout.dart';
import '../../widgets/simple_challenge_view.dart';
import 'challenge_state.dart';
import 'challenge_view_model.dart';

/// Answers the sign-in request that the push [payload] points at.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({required this.payload, required this.createViewModel, super.key});

  final Map<String, Object?> payload;

  /// Called once, when the screen is first built; the screen owns and disposes what it returns.
  final ChallengeViewModel Function() createViewModel;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  late final ChallengeViewModel _viewModel = widget.createViewModel();

  @override
  void initState() {
    super.initState();
    unawaited(_viewModel.load(widget.payload));
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  /// An answer was submitted: nothing more to show. The state only becomes done once.
  void _closeWhenDone(BuildContext context) {
    if (_viewModel.state.value.status == ChallengeStatus.done) untracked(() => Navigator.of(context).pop());
  }

  @override
  Widget build(BuildContext context) => SignalEffect(
    effect: _closeWhenDone,
    child: SignalBuilder(builder: (context) => _ChallengeBody(_viewModel.state.value, viewModel: _viewModel)),
  );
}

/// The screen for [state]: the challenge when there is one to answer, else a stand-in.
class _ChallengeBody extends StatelessWidget {
  const _ChallengeBody(this.state, {required this.viewModel});

  final ChallengeState state;
  final ChallengeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final challenge = state.challenge;
    if (state.status == ChallengeStatus.failure || challenge == null) {
      return _Placeholder(error: state.error);
    }
    // Answers are off while one is being submitted, and once it has been.
    final answerable = state.status == ChallengeStatus.ready;
    final onDeny = answerable ? () => unawaited(viewModel.deny()) : null;
    return switch (challenge) {
      SimpleChallenge() => SimpleChallengeView(
        account: challenge.accountId,
        metadata: challenge.metadata,
        onApprove: answerable ? () => unawaited(viewModel.approve()) : null,
        onDeny: onDeny,
      ),
      ContextMatchingChallenge() => ContextMatchingChallengeView(
        account: challenge.accountId,
        metadata: challenge.metadata,
        options: challenge.options,
        onSelected: answerable ? (option) => unawaited(viewModel.select(option)) : null,
        onDeny: onDeny,
      ),
    };
  }
}

/// Shown while the challenge loads, and when it can't be loaded or answered.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.error});

  /// Null while loading.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final error = this.error;
    return ScreenLayout(
      header: const ScreenHeader(title: 'Authenticator', subtitle: 'Sign-in request'),
      child: AppCard(
        child: error == null
            ? const Center(
                child: SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              )
            : Text(
                error,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
      ),
    );
  }
}
