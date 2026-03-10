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


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {

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
                final statusText = record.isApproved
                    ? 'Aprovado'
                    : record.isRejected
                        ? 'Rejeitado'
                        : 'Pendente';

                final statusColor = record.isApproved
                    ? Colors.green
                    : record.isRejected
                        ? Colors.red
                        : Colors.orange;

                final statusIcon = record.isApproved
                    ? Icons.check_circle
                    : record.isRejected
                        ? Icons.cancel
                        : Icons.hourglass_top;
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      statusIcon,
                      color: statusColor,
                    ),
                    title: Text(
                      record.code,
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
                        Text(formatDateTimePt(record.timestamp)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
