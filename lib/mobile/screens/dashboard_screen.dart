import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:istec_checkin/mobile/providers/app_state.dart';
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
      context.read<AppState>().refreshHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
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
        : lastRecord.isApproved
            ? Colors.green
            : lastRecord.isRejected
                ? Colors.red
                : Colors.orange;
    final statusIcon = lastRecord == null
        ? Icons.help_outline
        : lastRecord.isApproved
            ? Icons.check_circle
            : lastRecord.isRejected
                ? Icons.cancel
                : Icons.hourglass_top;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ISTEC Check-in'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
                    SizedBox(height: 12),
                    Text('Bem-vindo, Aluno ISTEC', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('ID: 2024517', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(24),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.qr_code_scanner, size: 32),
              label: const Text('REALIZAR CHECK-IN', style: TextStyle(fontSize: 16)),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const ScannerScreen())
              ),
            ),


            const SizedBox(height: 40),
            const Text('Última Atividade', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (history.isNotEmpty)
              ListTile(
                leading: Icon(statusIcon, color: statusColor),
                title: Text(
                  lastRecord!.code,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(formatDateTimePt(lastRecord.timestamp)),
                  ],
                ),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              )
            else
              const Center(
                child: Text(
                  'Nenhum registro hoje',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
