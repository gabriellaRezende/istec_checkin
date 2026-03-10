import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:istec_checkin/mobile/providers/app_state.dart';
import 'package:istec_checkin/shared/services/auth_service.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';
import 'package:istec_checkin/shared/utils/geo_helper.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();

  bool _isProcessing = false;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _ensureLocationReady();
  }

  Future<void> _ensureLocationReady() async {
    try {
      await GeoHelper.determinePosition();
    } catch (e) {
      if (!mounted) return;
      await _showError(
        'Localização necessária',
        'Ative a localização e conceda permissão para continuar.\n\nDetalhes: ${e.toString()}',
        showOpenSettings: true,
      );
    }
  }

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

  Future<void> _showSuccess(String eventName) async {
    if (_dialogOpen) return;
    _dialogOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Check-in enviado'),
          content: Text(
            'O seu check-in para "$eventName" foi enviado para validação.',
          ),
          actions: [
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

  String? _extractEventId(String? rawCode) {
    if (rawCode == null) return null;

    final trimmed = rawCode.trim();
    const prefix = 'ISTEC_EVENT:';

    if (!trimmed.startsWith(prefix)) return null;

    final eventId = trimmed.substring(prefix.length).trim();
    return eventId.isEmpty ? null : eventId;
  }

  DateTime? _parseEventDateTime(String? rawDate, String? rawTime) {
    if (rawDate == null ||
        rawDate.isEmpty ||
        rawTime == null ||
        rawTime.isEmpty) {
      return null;
    }

    final normalizedTime = rawTime.length == 5 ? '$rawTime:00' : rawTime;
    return DateTime.tryParse('${rawDate}T$normalizedTime');
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    _isProcessing = true;

    await _scannerController.stop();

    try {
      final code = capture.barcodes.first.rawValue;
      final eventId = _extractEventId(code);

      if (eventId == null) {
        await _showError(
          'QR Code inválido',
          'Este código não pertence a um evento válido do ISTEC.',
        );
        return;
      }

      final supabase = Supabase.instance.client;
      final event = await supabase
          .from('events')
          .select()
          .eq('id', eventId)
          .maybeSingle();

      if (event == null) {
        await _showError(
          'Evento não encontrado',
          'O evento associado a este QR Code não foi encontrado.',
        );
        return;
      }

      final eventName = (event['name'] ?? 'Evento').toString();
      final status = (event['status'] ?? '').toString().toLowerCase();

      if (status != 'active') {
        await _showError(
          'Evento indisponível',
          'Este evento não está ativo para check-in.',
        );
        return;
      }

      final startDateTime = _parseEventDateTime(
        event['start_date']?.toString(),
        event['start_time']?.toString(),
      );
      final endDateTime = _parseEventDateTime(
        event['end_date']?.toString(),
        event['end_time']?.toString(),
      );

      final now = DateTime.now();

      if (startDateTime != null && now.isBefore(startDateTime)) {
        await _showError(
          'Evento ainda não iniciou',
          'O check-in para "$eventName" ainda não está disponível.',
        );
        return;
      }

      if (endDateTime != null && now.isAfter(endDateTime)) {
        await _showError(
          'Evento encerrado',
          'O período de check-in deste evento já terminou.',
        );
        return;
      }

      final eventLat = (event['latitude'] as num?)?.toDouble();
      final eventLng = (event['longitude'] as num?)?.toDouble();
      final radiusMeters = (event['radius_meters'] as num?)?.toDouble() ?? 100;

      if (eventLat == null || eventLng == null) {
        await _showError(
          'Evento sem localização',
          'Este evento não possui localização configurada.',
        );
        return;
      }

      final pos = await GeoHelper.determinePosition();
      final distance = GeoHelper.calculateDistance(
        pos.latitude,
        pos.longitude,
        eventLat,
        eventLng,
      );

      if (distance > radiusMeters) {
        await _showError(
          'Fora do raio permitido',
          'Você está a ${distance.toStringAsFixed(0)}m do evento.\n\nAproxime-se e tente novamente.',
        );
        return;
      }

      final profile = await AuthService.getCurrentProfile();
      final user = AuthService.currentUser;
      final studentName = (profile?['full_name'] ?? 'Aluno').toString();
      final studentEmail = (user?.email ?? '').toString();
      final address = (event['adress'] ?? '').toString();

      final existingCheckin = await supabase
          .from('checkins')
          .select('id, status')
          .eq('event_id', eventId)
          .eq('student_email', studentEmail)
          .maybeSingle();

      if (existingCheckin != null) {
        final existingStatus = (existingCheckin['status'] ?? 'pending')
            .toString()
            .toLowerCase();

        String statusLabel;
        switch (existingStatus) {
          case 'approved':
            statusLabel = 'aprovado';
            break;
          case 'rejected':
            statusLabel = 'rejeitado';
            break;
          default:
            statusLabel = 'pendente';
        }

        await _showError(
          'Check-in já realizado',
          'Você já realizou o check-in para este evento. Estado atual: $statusLabel.',
        );
        return;
      }

      await supabase.from('checkins').insert({
        'event_id': eventId,
        'student_name': studentName,
        'student_email': studentEmail,
        'event_name': eventName,
        'event_address': address,
        'status': 'pending',
        'read_at': DateTime.now().toIso8601String(),
        'device_latitude': pos.latitude,
        'device_longitude': pos.longitude,
        'distance_meters': distance,
      });

      if (!mounted) return;

      await context.read<AppState>().refreshHistory();

      if (!mounted) return;
      await _showSuccess(eventName);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      await _showError(
        'Erro ao processar check-in',
        'Não foi possível concluir o check-in.\n\nDetalhes: ${e.toString()}',
        showOpenSettings: false,
      );
    } finally {
      _isProcessing = false;
      if (mounted) {
        await _scannerController.start();
      }
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _scannerController, onDetect: _onDetect),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    BrandTheme.navy.withValues(alpha: 0.72),
                    Colors.transparent,
                    BrandTheme.navy.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BrandTheme.softPanel(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.qr_code_scanner_rounded),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aponte a câmara para o QR Code do evento.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BrandTheme.softPanel(
                      color: BrandTheme.navy.withValues(alpha: 0.82),
                    ),
                    child: const Text(
                      'Mantenha o código dentro da área destacada para validar o check-in.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
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
}
