import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';

/// One enrollment in a list, with a menu of actions. Stack items inside a card.
class EnrollmentListItem extends StatelessWidget {
  const EnrollmentListItem({
    required this.deviceName,
    required this.issuer,
    required this.account,
    required this.onUnenroll,
    this.showDivider = true,
    super.key,
  });

  final String deviceName;
  final String issuer;
  final String account;

  /// Called when "Unenroll" is picked from the menu. Null disables the item.
  final VoidCallback? onUnenroll;

  /// Draws a hairline above the item; turn off for the first one.
  final bool showDivider;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      border: showDivider
          ? const Border(top: BorderSide(color: AppColors.divider))
          : null,
    ),
    child: Padding(
      padding: EdgeInsets.only(top: showDivider ? 14 : 4, bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  deviceName,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTitle,
                  ),
                ),
                _Details(issuer: issuer, account: account),
              ],
            ),
          ),
          // Nudged so the dots, not their touch target, line up with the card's padding.
          Transform.translate(
            offset: const Offset(8, -6),
            child: _ActionsMenu(onUnenroll: onUnenroll),
          ),
        ],
      ),
    ),
  );
}

enum _ItemAction { unenroll }

/// The three-dot button and its menu.
class _ActionsMenu extends StatefulWidget {
  const _ActionsMenu({required this.onUnenroll});

  final VoidCallback? onUnenroll;

  @override
  State<_ActionsMenu> createState() => _ActionsMenuState();
}

class _ActionsMenuState extends State<_ActionsMenu> {
  // The button keeps its highlight for as long as its menu is open.
  bool _open = false;

  static const _menuWidth = 150.0;
  static const _buttonSize = 44.0;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.menuShadow,
        elevation: 12,
        menuPadding: const EdgeInsets.all(4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      hoverColor: AppColors.dangerTint,
      splashColor: AppColors.dangerTint,
      highlightColor: AppColors.dangerTint,
    ),
    child: PopupMenuButton<_ItemAction>(
      tooltip: 'Actions',
      position: PopupMenuPosition.under,
      constraints: const BoxConstraints(minWidth: _menuWidth),
      padding: EdgeInsets.zero,
      iconSize: 20,
      icon: const Icon(Icons.more_vert),
      style: ButtonStyle(
        fixedSize: const WidgetStatePropertyAll(Size.square(_buttonSize)),
        shape: const WidgetStatePropertyAll(CircleBorder()),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => _highlighted(states)
              ? AppColors.primary
              : AppColors.textBody,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              _highlighted(states) ? AppColors.primaryTint : Colors.transparent,
        ),
      ),
      onOpened: () => setState(() => _open = true),
      onCanceled: () => setState(() => _open = false),
      onSelected: (action) {
        setState(() => _open = false);
        switch (action) {
          case _ItemAction.unenroll:
            widget.onUnenroll?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ItemAction.unenroll,
          enabled: widget.onUnenroll != null,
          padding: const EdgeInsets.all(12),
          child: Text(
            'Unenroll',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 14,
              color: widget.onUnenroll == null ? AppColors.onDisabled : AppColors.danger,
            ),
          ),
        ),
      ],
    ),
  );

  bool _highlighted(Set<WidgetState> states) =>
      _open ||
      states.contains(WidgetState.pressed) ||
      states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.focused);
}

/// Issuer and account as labelled lines; values wrap, even mid-word.
class _Details extends StatelessWidget {
  const _Details({required this.issuer, required this.account});

  final String issuer;
  final String account;

  static const _labelStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 13,
    color: AppColors.textMuted,
  );
  static const _valueStyle = TextStyle(
    fontFamily: AppTheme.fontFamily,
    fontSize: 13,
    color: AppColors.textBody,
  );

  @override
  Widget build(BuildContext context) => Table(
    columnWidths: const {
      0: IntrinsicColumnWidth(),
      1: FlexColumnWidth(),
    },
    children: [
      _row('Issuer', issuer, first: true),
      _row('Account', account),
    ],
  );

  TableRow _row(String label, String value, {bool first = false}) => TableRow(
    children: [
      Padding(
        padding: EdgeInsets.only(top: first ? 0 : 2),
        child: Text(label, style: _labelStyle),
      ),
      Padding(
        padding: EdgeInsets.only(left: 10, top: first ? 0 : 2),
        child: Text(value, style: _valueStyle),
      ),
    ],
  );
}
