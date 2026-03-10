import 'package:flutter/material.dart';
import 'package:istec_checkin/shared/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:istec_checkin/mobile/providers/app_state.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';
import 'scanner_screen.dart';

String formatDateTimePt(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  final mo = dt.month.toString().padLeft(2, '0');
  final yyyy = dt.year.toString();
  return '$hh:$mm $dd/$mo/$yyyy';
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;
      context.read<AppState>().refreshHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = context.watch<AppState>().history;
    final lastRecord = history.isNotEmpty ? history.first : null;
    final statusText = lastRecord == null
        ? ''
        : lastRecord.isApproved
        ? 'Aprovado'
        : lastRecord.isRejected
        ? 'Rejeitado'
        : 'Pendente';
    final statusColor = lastRecord == null
        ? Colors.grey
        : BrandTheme.statusColor(statusText);
    final statusIcon = lastRecord == null
        ? Icons.help_outline
        : lastRecord.isApproved
        ? Icons.check_circle
        : lastRecord.isRejected
        ? Icons.cancel
        : Icons.hourglass_top;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ISTEC Scan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      body: Container(
        decoration: BrandTheme.screenBackground(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              decoration: BrandTheme.softPanel(color: BrandTheme.navy),
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bem-vindo, ${AuthService.currentUser?.userMetadata? ['full_name'] ?? 'Usuário'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              decoration: BrandTheme.softPanel(),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Presença rápida',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Use o scanner para validar a sua entrada no evento.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                      label: const Text(
                        'REALIZAR CHECK-IN',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScannerScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Última Atividade',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            if (history.isNotEmpty)
              Container(
                decoration: BrandTheme.softPanel(),
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      width: 48,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lastRecord!.code,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatDateTimePt(lastRecord.timestamp),
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              Container(
                decoration: BrandTheme.softPanel(),
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'Nenhum registro hoje',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
