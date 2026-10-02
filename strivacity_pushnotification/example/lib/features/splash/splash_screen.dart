import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'native_splash_channel.dart';

/// The app's start screen: the Strivacity logo and the app name over a softly breathing glow.
///
/// The loading indicator and status line that follow are not part of this screen.
class const SplashScreen({
  required final String logoText,
  required final String footerText,
  super.key,
})
    extends StatefulWidget {
  /// The colour behind the screen's content. The native launch screen uses the same colour.
  static const backgroundColor = Color(0xFF231634);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // The glow grows and fades once per period, then returns.
  static const _glowPeriod = Duration(milliseconds: 3200);

  // Each outline ring expands and fades once per period. A second ring runs half a period behind.
  static const _ringPeriod = Duration(milliseconds: 2400);

  // The logo tile and the background show at once. Everything else fades in over this time.
  static const _revealPeriod = Duration(milliseconds: 1200);

  static final _glowScale = _breathing(from: 1, to: 1.12);
  static final _glowOpacity = _breathing(from: 1, to: 0.7);

  late final AnimationController _reveal = AnimationController(vsync: this, duration: _revealPeriod);
  late final Animation<double> _revealOpacity = CurvedAnimation(parent: _reveal, curve: Curves.easeOut);

  late final AnimationController _glow = AnimationController(vsync: this, duration: _glowPeriod);
  late final AnimationController _rings = AnimationController(vsync: this, duration: _ringPeriod);
  bool _animate = true;

  static TweenSequence<double> _breathing({required double from, required double to}) => TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: from, end: to).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(begin: to, end: from).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 1,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    // The native splash screen is still covering this screen until it is removed, so wait for that
    // before fading in, or the fade would already be over by the time it can be seen.
    unawaited(
      NativeSplashChannel.untilGone().then((_) {
        if (mounted && _animate) _reveal.forward();
      }),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context);
    if (_animate) {
      if (!_glow.isAnimating) _glow.repeat();
      if (!_rings.isAnimating) _rings.repeat();
    } else {
      _reveal.value = 1;
      _glow.stop();
      _rings.stop();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    _glow.dispose();
    _rings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: SplashScreen.backgroundColor,
    body: LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          // The glow is centred on the screen, behind the logo tile.
          Positioned(
            left: (constraints.maxWidth - _Glow.diameter) / 2,
            top: (constraints.maxHeight - _Glow.diameter) / 2,
            width: _Glow.diameter,
            height: _Glow.diameter,
            child: ExcludeSemantics(
              child: FadeTransition(
                opacity: _revealOpacity,
                child: FadeTransition(
                  opacity: _glowOpacity.animate(_glow),
                  child: ScaleTransition(scale: _glowScale.animate(_glow), child: const _Glow()),
                ),
              ),
            ),
          ),
          Center(
            child: _Branding(rings: _animate ? _rings : null, reveal: _revealOpacity, logoText: widget.logoText),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: FadeTransition(
                  opacity: _revealOpacity,
                  child: Text(widget.footerText, style: const TextStyle(fontSize: 12, color: _Palette.footer)),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The logo tile with the wordmark and the app name hanging below it.
///
/// Only the tile takes up space, so centring this widget centres the tile, as on the native splash
/// screen, however tall the text below is.
class const _Branding({required this.rings, required this.reveal, required final String logoText})
    extends StatelessWidget {
  /// Drives the outline rings around the logo tile. Null shows no rings.
  final Animation<double>? rings;

  /// Fades in the rings and the text. The logo tile itself is always fully visible.
  final Animation<double> reveal;

  static const _wordmarkAsset = 'assets/images/strivacity_wordmark_white.svg';

  // How far the text area extends past each side of the tile, so the text can be wider than it.
  static const _textOverhang = 60.0;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: _LogoTile._size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        _LogoTile(rings: rings, reveal: reveal),
        Positioned(
          top: _LogoTile._size + 36,
          left: -_textOverhang,
          right: -_textOverhang,
          child: FadeTransition(
            opacity: reveal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(_wordmarkAsset, width: 150, semanticsLabel: 'Strivacity'),
                const SizedBox(height: 10),
                Text(
                  logoText.toUpperCase(),
                  style: const TextStyle(fontSize: 13, letterSpacing: 2.6, color: _Palette.label),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// The purple tile with the white logo mark, and the rings that expand from its edge.
class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.rings, required this.reveal});

  final Animation<double>? rings;

  /// Fades in the rings. The tile and the mark on it are not affected.
  final Animation<double> reveal;

  static const _size = 112.0;
  static const _radius = BorderRadius.all(Radius.circular(28));
  static const _iconAsset = 'assets/images/strivacity_icon_white.svg';

  @override
  Widget build(BuildContext context) {
    final rings = this.rings;
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: _Palette.tile,
              borderRadius: _radius,
              border: Border.all(color: _Palette.tileBorder),
            ),
            child: Center(child: SvgPicture.asset(_iconAsset, width: 60, excludeFromSemantics: true)),
          ),
          if (rings != null) ...[
            Positioned.fill(
              child: FadeTransition(
                opacity: reveal,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: _Ring(animation: rings, phase: 0)),
                    Positioned.fill(child: _Ring(animation: rings, phase: 0.5)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// An outline that grows to 1.7 times the tile and fades out, then starts over.
class _Ring extends StatelessWidget {
  const _Ring({required this.animation, required this.phase});

  final Animation<double> animation;

  /// How far into its period this ring starts, as a fraction of the period.
  final double phase;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = Curves.easeOut.transform((animation.value + phase) % 1);
        return Opacity(
          opacity: 0.8 * (1 - progress),
          child: Transform.scale(scale: 1 + 0.7 * progress, child: child),
        );
      },
      child: const DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: _LogoTile._radius,
          border: Border.fromBorderSide(BorderSide(color: _Palette.ring, width: 2)),
        ),
      ),
    ),
  );
}

/// The soft purple light behind the logo, fading to nothing at its edge.
class _Glow extends StatelessWidget {
  const _Glow();

  static const diameter = 520.0;

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [_Palette.glowCenter, _Palette.glowEdge]),
    ),
  );
}

abstract final class _Palette {
  static const tile = Color(0xFF5D21AB);
  static const tileBorder = Color(0x1FFFFFFF);
  static const ring = Color(0xFF8443DB);
  static const label = Color(0xFFCFC3E3);
  static const footer = Color(0xFFA99BBD);
  static const glowCenter = Color.fromRGBO(132, 67, 219, 0.45);

  // The same colour, fully transparent, so the gradient fades without darkening.
  static const glowEdge = Color.fromRGBO(132, 67, 219, 0);
}
