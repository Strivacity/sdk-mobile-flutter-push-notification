import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// Dark top bar: logo tile beside a title and optional subtitle. Runs under the status bar.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({required this.title, this.subtitle, super.key});

  final String title;

  /// Smaller line under [title].
  final String? subtitle;

  static const _padding = EdgeInsets.symmetric(horizontal: 24, vertical: 28);
  static const _gap = 12.0;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    return ColoredBox(
      color: AppColors.surfaceDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: _padding,
          child: Row(
            spacing: _gap,
            children: [
              const _LogoTile(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontSize: 13,
                            color: AppColors.textOnDarkSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoTile extends StatelessWidget {
  const _LogoTile();

  static const _size = 36.0;
  static const _iconWidth = 20.0;
  static const _iconAsset = 'assets/images/strivacity_icon_white.svg';

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.primary,
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
    child: SizedBox.square(
      dimension: _size,
      child: Center(
        child: SvgPicture.asset(
          _iconAsset,
          width: _iconWidth,
          excludeFromSemantics: true,
        ),
      ),
    ),
  );
}
