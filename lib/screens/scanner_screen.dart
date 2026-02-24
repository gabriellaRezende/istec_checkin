import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import 'package:istec_checkin/models/check_in.dart';
import 'package:istec_checkin/providers/app_state.dart';
import 'package:istec_checkin/utils/geo_helper.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();

  // QRCode válido precisa ter este valor textual.
  final Set<String> _validCodes = {
    'EVENTO-TECNOLOGIA-2026',
    'WORKSHOP-FLUTTER-2026',
    'PALESTRA-INTELIGENCIA-ARTIFICIAL-2026',
    };

  bool _isProcessing = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    //Antes de iniciar a camera pede permissão para localização/GPS
    _ensureLocationReady();
  }

  //Verifica se a funçaõ de localização esta pronta e ai pode iniciar a camera, no caso de não estar pronta mostra o dialog.
  Future<void> _ensureLocationReady() async {
    try {
      await GeoHelper.determinePosition();
    } catch (e) {
      if (!mounted) return;
      await _showError(
        'Localização necessária',
        'Ative a localização e conceda permissão para continuar.\n\nDetalhes: ${e.toString()}',
        showOpenSettings: true, // Oferece opção para abrir as configurações de localização do dispositivo.
      );
    }
  }

  // Exibe um dialog de erro com título, mensagem e opcionalmente um botão para abrir as configurações de localização do dispositivo.
  Future<void> _showError(
    String title,
    String message, {
    bool showOpenSettings = false,
  }) async {
    if (_dialogOpen) return;
    _dialogOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            if (showOpenSettings)
              TextButton(
                onPressed: () async {
                  await Geolocator.openLocationSettings();
                  await Geolocator.openAppSettings();
                },
                child: const Text('ABRIR DEFINIÇÕES'),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    _dialogOpen = false;
  }

  // Gerencia o processo de detecção do QR code, valida o código, verifica a localização e registra o check-in no histórico do app.
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    _isProcessing = true;

    // Evita que escaneei varias vezes o mesmo código.
    await _scannerController.stop();

    try {
      final code = capture.barcodes.first.rawValue;

      // Valida o código do QR code. Se for inválido, exibe um dialog de erro e retorna.
      if (code == null || !_validCodes.contains(code)) {
        await _showError(
          'QR Code inválido',
          'Este código não pertence ao ISTEC.',
        );
        return;
      }

      // Caso válido verifica a localização do usuário. Se estiver fora do raio permitido, exibe um dialog de erro e retorna.
      final pos = await GeoHelper.determinePosition();
      final dist = GeoHelper.calculateDistance(
        pos.latitude,
        pos.longitude,
        GeoHelper.targetLat,
        GeoHelper.targetLng,
      );

      if (dist > GeoHelper.radiusMeters) {
        await _showError(
          'Fora do raio permitido',
          'Você está a ${dist.toStringAsFixed(0)}m do evento.\n\nAproxime-se e tente novamente.',
        );
        return;
      }

      // Check-in feito com sucesso e registra no histórico do app.
      if (!mounted) return;
      context.read<AppState>().addRecord(
            CheckInRecord(
              id: code,
              timestamp: DateTime.now(),
              location: '${pos.latitude.toStringAsFixed(6)},${pos.longitude.toStringAsFixed(6)}',
              isSuccess: true,
            ),
          );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      await _showError(
        'Erro de GPS',
        'Certifique-se de que a localização está ativa e permitida.\n\nDetalhes: ${e.toString()}',
        showOpenSettings: true,
      );
    } finally {
      _isProcessing = false;
      if (mounted) {
        await _scannerController.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner'),
      ),
      body: MobileScanner(
        controller: _scannerController,
        onDetect: _onDetect,
      ),
    );
  }
}