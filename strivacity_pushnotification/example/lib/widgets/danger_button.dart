import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// Red button for destructive actions.
class DangerButton extends StatelessWidget {
  const DangerButton({required this.label, required this.onPressed, super.key});

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
      shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)))),
      elevation: const WidgetStatePropertyAll(0),
      foregroundColor: WidgetStatePropertyAll(onPressed == null ? AppColors.onDisabled : AppColors.onFill),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => switch (states) {
          _ when states.contains(WidgetState.disabled) => AppColors.disabledFill,
          _ when states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered) =>
            AppColors.dangerPressed,
          _ => AppColors.danger,
        },
      ),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    // Overpass leaves more room above its letters than below, so the label is nudged down 1px to
    // look centred.
    child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(label)),
  );
}
