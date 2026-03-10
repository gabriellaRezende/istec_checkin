import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';

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
      if (!mounted) return;
      context.read<AppState>().refreshHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = context.watch<AppState>().history;

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de Presenças')),
      body: Container(
        decoration: BrandTheme.screenBackground(),
        child: history.isEmpty
            ? Center(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(24),
                  decoration: BrandTheme.softPanel(),
                  child: const Text('Ainda não tem presenças confirmadas.'),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final record = history[index];
                  final statusText = record.isApproved
                      ? 'Aprovado'
                      : record.isRejected
                      ? 'Rejeitado'
                      : 'Pendente';

                  final statusColor = BrandTheme.statusColor(statusText);
                  final statusIcon = record.isApproved
                      ? Icons.check_circle
                      : record.isRejected
                      ? Icons.cancel
                      : Icons.hourglass_top;
                  return Container(
                    decoration: BrandTheme.softPanel(),
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
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
                                record.code,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
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
                                formatDateTimePt(record.timestamp),
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
