import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// A large button showing one number.
class NumberButton extends StatelessWidget {
  const NumberButton({required this.label, required this.onPressed, super.key});

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;

  static const _height = 72.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _height,
    child: OutlinedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: const WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
        foregroundColor: WidgetStatePropertyAll(onPressed == null ? AppColors.onDisabled : AppColors.textTitle),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => switch (states) {
            _ when states.contains(WidgetState.disabled) => AppColors.disabledFill,
            _ when states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered) => AppColors.primaryTint,
            _ => AppColors.surface,
          },
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => switch (states) {
            _ when states.contains(WidgetState.disabled) => const BorderSide(color: AppColors.disabledFill, width: 1.5),
            _ when states.contains(WidgetState.focused) => const BorderSide(color: AppColors.primary, width: 2),
            _ when states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered) => const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
            _ => const BorderSide(color: AppColors.primaryBorder, width: 1.5),
          },
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 30, fontWeight: FontWeight.w600),
        ),
      ),
      // Overpass leaves more room above its letters than below, so the label is nudged down 2px to
      // look centred.
      child: Padding(padding: const EdgeInsets.only(top: 4), child: Text(label)),
    ),
  );
}

/// [NumberButton]s laid out three to a row.
class NumberGrid extends StatelessWidget {
  const NumberGrid({required this.options, required this.onSelected, super.key});

  final List<String> options;

  /// Null disables every button.
  final ValueChanged<String>? onSelected;

  static const _columns = 3;
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final onSelected = this.onSelected;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - _gap * (_columns - 1)) / _columns;
        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final option in options)
              SizedBox(
                width: width,
                child: NumberButton(label: option, onPressed: onSelected == null ? null : () => onSelected(option)),
              ),
          ],
        );
      },
    );
  }
}
