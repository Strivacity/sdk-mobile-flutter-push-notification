import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_card.dart';

/// What the backend says about a sign-in attempt, as labelled rows in a card. Entries with no
/// value are left out, and nothing shows when none remain.
class ChallengeMetadata extends StatelessWidget {
  const ChallengeMetadata({required this.metadata, super.key});

  final Map<String, String?> metadata;

  // The keys the backend is known to send, in display order. Others follow, labelled by their key.
  static const _knownLabels = {'loginTimestamp': 'Time', 'deviceInfo': 'User agent', 'location': 'Location'};

  static const _labelStyle = TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, color: AppColors.textSecondary);
  static const _valueStyle = TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, color: AppColors.textTitle);

  /// 'someKey' as 'Some key'.
  static String _labelOf(String key) {
    final spaced = key.replaceAllMapped(RegExp('([a-z])([A-Z])'), (match) => '${match[1]} ${match[2]!.toLowerCase()}');
    return spaced.isEmpty ? key : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      ..._knownLabels.keys.where(metadata.containsKey),
      ...metadata.keys.where((key) => !_knownLabels.containsKey(key)),
    ].where((key) => metadata[key]?.isNotEmpty ?? false).toList();
    if (keys.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        children: [
          for (final (index, key) in keys.indexed)
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 10),
                  child: Text(_knownLabels[key] ?? _labelOf(key), style: _labelStyle),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 16, top: index == 0 ? 0 : 10),
                  child: Text(metadata[key]!, style: _valueStyle),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
