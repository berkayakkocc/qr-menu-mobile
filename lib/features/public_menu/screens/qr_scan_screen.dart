import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  bool _hasNavigated = false;

  String? _extractSlug(String rawValue) {
    final match = RegExp(r'/public/([a-z0-9-]+)/menu').firstMatch(rawValue);
    return match?.group(1);
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasNavigated) return;
    final rawValue = capture.barcodes.firstOrNull?.rawValue;
    if (rawValue == null) return;

    final slug = _extractSlug(rawValue);
    if (slug == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçersiz QR kod. Lütfen menü QR kodunu okutun.')),
      );
      return;
    }

    setState(() => _hasNavigated = true);
    context.go('/menu/$slug');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('QR Kodu Tara'),
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          // Scan area overlay
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2563EB), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  for (final alignment in [
                    Alignment.topLeft,
                    Alignment.topRight,
                    Alignment.bottomLeft,
                    Alignment.bottomRight,
                  ])
                    Align(
                      alignment: alignment,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.only(
                            topLeft: alignment == Alignment.topLeft
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                            topRight: alignment == Alignment.topRight
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                            bottomLeft: alignment == Alignment.bottomLeft
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                            bottomRight: alignment == Alignment.bottomRight
                                ? const Radius.circular(12)
                                : const Radius.circular(0),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Text(
              'QR kodu çerçeve içine hizalayın',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
