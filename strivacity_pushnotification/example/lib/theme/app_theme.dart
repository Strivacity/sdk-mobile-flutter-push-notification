import 'package:flutter/material.dart';

import 'colors.dart';

/// The app theme, the same in light and dark mode.
abstract final class AppTheme {
  static const fontFamily = 'Overpass';

  static ThemeData get data => ThemeData(
    fontFamily: fontFamily,
    scaffoldBackgroundColor: AppColors.screenBackground,
  );
}
