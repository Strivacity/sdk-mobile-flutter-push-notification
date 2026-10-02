import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// Outlined button for secondary actions.
class OutlineButton extends StatelessWidget {
  const OutlineButton({
    required this.label,
    required this.onPressed,
    this.expanded = false,
    this.destructive = false,
    super.key,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  /// Full width, 48px tall, instead of as wide as the label.
  final bool expanded;

  /// Red instead of purple.
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.danger : AppColors.primary;
    final tint = destructive ? AppColors.dangerTint : AppColors.primaryTint;
    return OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(expanded ? const Size.fromHeight(48) : const Size(0, 44)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(4)))),
        foregroundColor: WidgetStatePropertyAll(onPressed == null ? AppColors.onDisabled : accent),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => switch (states) {
            _ when states.contains(WidgetState.disabled) => AppColors.disabledFill,
            _ when states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered) => tint,
            _ => AppColors.surface,
          },
        ),
        side: WidgetStatePropertyAll(BorderSide(color: onPressed == null ? AppColors.disabledFill : accent)),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      // Overpass leaves more room above its letters than below, so the label is nudged down 1px to
      // look centred.
      child: Padding(padding: const EdgeInsets.only(top: 2), child: Text(label)),
    );
  }
}
