import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// Labelled text field with a reserved error line, so errors never shift the layout.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.maxLength,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;

  /// Shown in red below the field, which is also outlined red.
  final String? errorText;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool autofocus;

  /// Typing limit.
  final int? maxLength;

  static const _height = 48.0;
  static const _errorLineHeight = 20.0;

  static const _textStyle = TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, color: AppColors.textTitle);

  @override
  Widget build(BuildContext context) {
    final errorText = this.errorText;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textTitle,
          ),
        ),
        SizedBox(
          height: _height,
          child: TextField(
            controller: controller,
            autofocus: autofocus,
            maxLength: maxLength,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.center,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            cursorColor: AppColors.primary,
            style: _textStyle,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: _textStyle.copyWith(color: AppColors.textMuted),
              counterText: '',
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              enabledBorder: _border(hasError ? AppColors.danger : AppColors.primaryBorder),
              focusedBorder: _border(hasError ? AppColors.danger : AppColors.primary, width: 2),
            ),
          ),
        ),
        SizedBox(
          height: _errorLineHeight,
          child: errorText == null
              ? null
              : Text(
                  errorText,
                  style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 13, color: AppColors.danger),
                ),
        ),
      ],
    );
  }

  // The default corner radius is 4, as in the design.
  static OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(borderSide: BorderSide(color: color, width: width));
}
