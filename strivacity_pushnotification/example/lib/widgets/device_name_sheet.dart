import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/colors.dart';
import 'app_text_field.dart';
import 'primary_button.dart';

/// Asks for a device name; the trimmed name, or null if dismissed.
Future<String?> showDeviceNameSheet(BuildContext context) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: AppColors.surface,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  builder: (context) => DeviceNameSheet(
    onSubmitted: (name) => Navigator.of(context).pop(name),
    onCancelled: () => Navigator.of(context).pop(),
  ),
);

/// Device-name field and Enroll button.
class DeviceNameSheet extends StatefulWidget {
  const DeviceNameSheet({required this.onSubmitted, required this.onCancelled, super.key});

  /// Called with the valid, trimmed name.
  final ValueChanged<String> onSubmitted;

  /// Called on close.
  final VoidCallback onCancelled;

  @override
  State<DeviceNameSheet> createState() => _DeviceNameSheetState();
}

class _DeviceNameSheetState extends State<DeviceNameSheet> {
  // The SDK accepts 1 to 64 characters after trimming.
  static const _maxLength = 64;

  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a device name');
      return;
    }
    widget.onSubmitted(name);
  }

  @override
  Widget build(BuildContext context) => Padding(
    // Lifts the sheet above the keyboard.
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Name this device',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTitle,
                    ),
                  ),
                ),
                // Pulled in so the icon, not its touch target, lines up with the sheet's padding.
                Transform.translate(
                  offset: const Offset(12, 0),
                  child: IconButton(
                    tooltip: 'Cancel',
                    color: AppColors.textBody,
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancelled,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a name that helps you recognize this device in your account.',
              style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14, height: 1.5, color: AppColors.textBody),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Device name',
              hint: 'For example, My phone',
              controller: _controller,
              errorText: _error,
              autofocus: true,
              maxLength: _maxLength,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 8),
            PrimaryButton(label: 'Enroll', onPressed: _submit),
          ],
        ),
      ),
    ),
  );
}
