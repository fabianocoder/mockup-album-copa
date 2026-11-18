import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../shared/widgets/empty_state.dart';

/// Lê um QR Code pela câmera e devolve o texto bruto via `Navigator.pop`.
/// A permissão da câmera só é pedida quando esta página é aberta.
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _done = true;
        Navigator.of(context).pop(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler QR Code')),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => EmptyState(
              icon: Icons.no_photography_outlined,
              message:
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                  ? 'Permita o acesso à câmera nas configurações do aparelho '
                        'para ler o QR Code.'
                  : 'Não foi possível usar a câmera neste aparelho.',
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Aponte a câmera para o QR Code da outra pessoa.',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
