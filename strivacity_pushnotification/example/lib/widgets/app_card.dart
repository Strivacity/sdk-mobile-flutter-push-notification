import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// A white, outlined, rounded panel.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = defaultPadding,
    super.key,
  });

  final Widget child;

  /// Space around [child].
  final EdgeInsetsGeometry padding;

  static const defaultPadding = EdgeInsets.all(20);

  static const _radius = BorderRadius.all(Radius.circular(12));

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: _radius,
    ),
    child: Padding(padding: padding, child: child),
  );
}
