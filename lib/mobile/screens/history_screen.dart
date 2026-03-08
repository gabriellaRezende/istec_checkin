
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';


String formatDateTimePt(DateTime dt) {
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  final dd = dt.day.toString().padLeft(2, '0');
  final mo = dt.month.toString().padLeft(2, '0');
  final yyyy = dt.year.toString();
  return '$hh:$mm $dd/$mo/$yyyy';
}


class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<AppState>().history;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Presenças')),
      body: history.isEmpty
          ? const Center(child: Text('Ainda não tem presenças confirmadas.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final record = history[index];
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      record.isSuccess ? Icons.check_circle : Icons.error,
                      color: record.isSuccess ? Colors.green : Colors.red,
                    ),
                    title: Text(record.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(formatDateTimePt(record.timestamp)),
                    trailing: const Icon(Icons.chevron_right),
                  ),
                );
              },
            ),
    );
  }
}
