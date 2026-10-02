import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// Full-width purple call-to-action button.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Shows a spinner instead of [label] and ignores taps.
  final bool loading;

  static const _height = 48.0;
  static const _radius = BorderRadius.all(Radius.circular(4));
  static const _spinnerSize = 18.0;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(_height)),
      shape: const WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: _radius),
      ),
      elevation: const WidgetStatePropertyAll(0),
      foregroundColor: WidgetStatePropertyAll(
        onPressed == null && !loading ? AppColors.onDisabled : AppColors.onFill,
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => switch (states) {
          // A button that is busy keeps its colour; one that is unavailable turns grey.
          _ when states.contains(WidgetState.disabled) =>
            loading ? AppColors.primary : AppColors.disabledFill,
          _ when states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered) => AppColors.primaryPressed,
          _ => AppColors.primary,
        },
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    child: loading
        ? const SizedBox.square(
            dimension: _spinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.onFill,
            ),
          )
        // Overpass leaves more room above its letters than below, so the label is nudged down 1px
        // to look centred.
        : Padding(padding: const EdgeInsets.only(top: 2), child: Text(label)),
  );
}
