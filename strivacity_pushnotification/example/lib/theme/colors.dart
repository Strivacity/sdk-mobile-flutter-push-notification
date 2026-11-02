import 'dart:ui';

/// The app's colours, named for the job they do rather than for their hue.
///
/// Widgets refer to these names only, so a colour can change in one place.
abstract final class AppColors {
  // Brand

  /// The brand colour: primary buttons, the logo tile, selected and focused states.
  static const primary = Color(0xFF5D21AB);

  /// [primary] when it is pressed or hovered.
  static const primaryPressed = Color(0xFF3F1676);

  /// A lighter brand colour for accents on dark backgrounds, such as glows and outlines.
  static const primaryAccent = Color(0xFF8443DB);

  /// A pale wash of [primary], behind a pressed or open control.
  static const primaryTint = Color(0xFFEFE8F8);

  /// An outline in the brand hue, on light surfaces.
  static const primaryBorder = Color(0xFFCDBFE3);

  // Surfaces

  /// The background of a screen.
  static const screenBackground = Color(0xFFF6F4F9);

  /// The background of cards, sheets and menus.
  static const surface = Color(0xFFFFFFFF);

  /// The deep background of a header, and of the launch screen.
  static const surfaceDark = Color(0xFF231634);

  // Text on light surfaces

  /// Titles, headings and the most important value in a row.
  static const textTitle = Color(0xFF231634);

  /// Running text.
  static const textBody = Color(0xFF4B4158);

  /// Supporting text, such as hints and footnotes.
  static const textSecondary = Color(0xFF6F6A78);

  /// The quietest text, such as labels next to a value.
  static const textMuted = Color(0xFF98949E);

  // Text on dark surfaces

  /// Primary text on [surfaceDark].
  static const textOnDark = Color(0xFFFFFFFF);

  /// Secondary text on [surfaceDark].
  static const textOnDarkSecondary = Color(0xFFCFC3E3);

  /// The quietest text on [surfaceDark].
  static const textOnDarkMuted = Color(0xFFA99BBD);

  /// Text and icons on a [primary] or [danger] fill.
  static const onFill = Color(0xFFFFFFFF);

  // Disabled

  /// The fill of a control that cannot be used.
  static const disabledFill = Color(0xFFE4E0EA);

  /// Text and icons on a [disabledFill].
  static const onDisabled = Color(0xFF98949E);

  // Lines

  /// The outline of a card, menu or outlined control.
  static const border = Color(0xFFE4E0EA);

  /// A hairline between rows inside a card.
  static const divider = Color(0xFFEEE9F3);

  // Status

  /// Destructive actions and errors.
  static const danger = Color(0xFFE40C0C);

  /// [danger] when it is pressed or hovered.
  static const dangerPressed = Color(0xFFB80A0A);

  /// A pale wash of [danger], behind a pressed or hovered destructive item.
  static const dangerTint = Color(0xFFFDECEC);

  /// Something completed as intended.
  static const success = Color(0xFF008060);

  /// Neutral information.
  static const info = Color(0xFF0095E6);

  // Effects

  /// The shadow under a floating menu.
  static const menuShadow = Color(0x2E231634);
}
