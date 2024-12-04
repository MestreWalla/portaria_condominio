import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../controllers/visita_controller.dart';
import 'package:provider/provider.dart';
import '../../localizations/app_localizations.dart';

class QRScannerView extends StatefulWidget {
  const QRScannerView({super.key});

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        iconTheme: IconThemeData(color: colorScheme.primary),
        title: Text(
          localizations.translate('qr_code_reader'),
          style: TextStyle(color: colorScheme.primary),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return Icon(
                      Icons.flash_off,
                      color: colorScheme.primary,
                    );
                  case TorchState.on:
                    return Icon(
                      Icons.flash_on,
                      color: colorScheme.primary,
                    );
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return Icon(
                      Icons.camera_front,
                      color: colorScheme.primary,
                    );
                  case CameraFacing.back:
                    return Icon(
                      Icons.camera_rear,
                      color: colorScheme.primary,
                    );
                }
              },
            ),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _onDetect,
            overlay: Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 60,
                      color: colorScheme.primary.withOpacity(0.7),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.translate('scan_qr_code_instruction'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3.0,
                            color: colorScheme.surface.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      localizations.translate('processing_qr_code'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isProcessing = true);

    try {
      final visitaController = Provider.of<VisitaController>(context, listen: false);
      final success = await visitaController.processarQRCodeVisita(code);
      final localizations = AppLocalizations.of(context);
      final theme = Theme.of(context);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('qr_code_success'),
                  style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.primaryContainer,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: theme.colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('invalid_qr_code'),
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: theme.colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).translate('qr_code_error'),
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ],
          ),
          backgroundColor: theme.colorScheme.errorContainer,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
