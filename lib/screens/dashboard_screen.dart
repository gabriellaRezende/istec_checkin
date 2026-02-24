import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:istec_checkin/providers/app_state.dart';
import 'scanner_screen.dart';

String formatDateTimePt(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  final mo = dt.month.toString().padLeft(2, '0');
  final yyyy = dt.year.toString();
  return '$hh:$mm $dd/$mo/$yyyy';
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().history;

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
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  history.first.id,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(formatDateTimePt(history.first.timestamp)),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
