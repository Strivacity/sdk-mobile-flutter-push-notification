import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../theme/app_theme.dart';
import '../../theme/colors.dart';

/// Camera that pops with the first QR code's text, or null when closed.
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  // One code is enough; the camera can report several more before it has stopped.
  bool _done = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_done) return;
    final value = capture.barcodes.map((barcode) => barcode.rawValue).nonNulls.first;
    _done = true;
    await _controller.stop();
    if (mounted) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
    child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _CameraError(error),
          ),
          const _ScanFrame(),
          const _CloseButton(),
          const _Instruction(),
        ],
      ),
    ),
  );
}

/// Dims the preview outside the scan square.
class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) => const IgnorePointer(child: CustomPaint(painter: _ScanFramePainter()));
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter();

  static const _maxSide = 280.0;
  static const _radius = Radius.circular(24);

  @override
  void paint(Canvas canvas, Size size) {
    final side = (size.shortestSide * 0.7).clamp(0.0, _maxSide);
    final frame = RRect.fromRectAndRadius(Rect.fromCenter(center: size.center(Offset.zero), width: side, height: side), _radius);
    final dimmed = Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(frame));
    canvas
      ..drawPath(dimmed, Paint()..color = AppColors.surfaceDark.withValues(alpha: 0.7))
      ..drawRRect(
        frame,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = AppColors.textOnDark,
      );
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) => false;
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: IconButton(
          tooltip: 'Close',
          color: AppColors.textOnDark,
          iconSize: 28,
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    ),
  );
}

class _Instruction extends StatelessWidget {
  const _Instruction();

  @override
  Widget build(BuildContext context) => const SafeArea(
    child: Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(32, 0, 32, 48),
        child: Text(
          'Point the camera at the enrollment QR code',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 16, color: AppColors.textOnDark),
        ),
      ),
    ),
  );
}

/// Shown when the camera can't be used.
class _CameraError extends StatelessWidget {
  const _CameraError(this.error);

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.surfaceDark,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          error.errorCode == MobileScannerErrorCode.permissionDenied
              ? 'Camera access is needed to scan the enrollment QR code. Allow it in the device settings, then try again.'
              : 'The camera could not be started.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 16, height: 1.5, color: AppColors.textOnDark),
        ),
      ),
    ),
  );
}
