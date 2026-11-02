import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';

/// [header] on top, scrolling [child], pinned [footer]. Expects a dark header.
class ScreenLayout extends StatelessWidget {
  const ScreenLayout({
    required this.header,
    required this.child,
    this.footer,
    super.key,
  });

  final Widget header;

  /// Scrolls.
  final Widget child;

  final Widget? footer;

  /// Space around [child].
  static const bodyPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 24);

  static const _footerPadding = EdgeInsets.fromLTRB(20, 12, 20, 24);

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
    ),
    child: Scaffold(
      backgroundColor: AppColors.screenBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: SingleChildScrollView(
              padding: bodyPadding,
              child: child,
            ),
          ),
          if (footer != null)
            SafeArea(
              top: false,
              child: Padding(padding: _footerPadding, child: footer),
            ),
        ],
      ),
    ),
  );
}
