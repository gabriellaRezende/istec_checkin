

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:istec_checkin/shared/services/auth_service.dart';
import 'package:istec_checkin/web_admin/screens/home_screen.dart';
import 'package:istec_checkin/web_admin/screens/events_screen.dart';
import 'package:istec_checkin/web_admin/screens/requests_screen.dart';
import 'package:istec_checkin/web_admin/widgets/top_navigation.dart';

class EventDetailScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<List<Map<String, dynamic>>> _checkinsFuture;

  @override
  void initState() {
    super.initState();
    _checkinsFuture = _loadCheckins();
  }

  Future<List<Map<String, dynamic>>> _loadCheckins() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('checkins')
        .select()
        .eq('event_id', widget.event['id'])
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _reload() async {
    setState(() {
      _checkinsFuture = _loadCheckins();
    });
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');
    final year = parsed.year.toString();
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  String get _qrData => 'ISTEC_EVENT:${widget.event['id']}';

  @override
  Widget build(BuildContext context) {
    final name = (widget.event['name'] ?? 'Evento').toString();
    final address = (widget.event['adress'] ?? '-').toString();
    final startDate = _formatDate(widget.event['start_date']?.toString());
    final startTime = _formatTime(widget.event['start_time']?.toString());
    final endDate = _formatDate(widget.event['end_date']?.toString());
    final endTime = _formatTime(widget.event['end_time']?.toString());
    final status = (widget.event['status'] ?? '-').toString();
    final radius = (widget.event['radius_meters'] ?? '-').toString();
    final latitude = (widget.event['latitude'] ?? '-').toString();
    final longitude = (widget.event['longitude'] ?? '-').toString();

    return Scaffold(
      appBar: TopNavigation(
        title: 'Detalhe do Evento',
        currentSection: AdminSection.events,
        onDashboard: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          );
        },
        onEvents: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const EventsScreen()),
          );
        },
        onRequests: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const RequestsScreen()),
          );
        },
        onSignOut: () async {
          await AuthService.signOutAndRedirect(context);
        },
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _checkinsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar detalhe do evento: ${snapshot.error}'),
            );
          }

          final checkins = snapshot.data ?? [];
          final total = checkins.length;
          final approved = checkins.where((c) => (c['status'] ?? '').toString().toLowerCase() == 'approved').length;
          final rejected = checkins.where((c) => (c['status'] ?? '').toString().toLowerCase() == 'rejected').length;
          final pending = checkins.where((c) => (c['status'] ?? '').toString().toLowerCase() == 'pending').length;

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _InfoRow(label: 'Morada', value: address),
                              _InfoRow(label: 'Início', value: '$startDate às $startTime'),
                              _InfoRow(label: 'Fim', value: '$endDate às $endTime'),
                              _InfoRow(label: 'Raio permitido', value: '$radius m'),
                              _InfoRow(label: 'Latitude', value: latitude),
                              _InfoRow(label: 'Longitude', value: longitude),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Estado: ',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor(status),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Text(
                                'QR Code',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              QrImageView(
                                data: _qrData,
                                version: QrVersions.auto,
                                size: 220,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Este QR identifica o evento para o check-in no app mobile.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Resumo do Evento',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _SummaryCard(title: 'Total', value: total.toString(), color: Colors.blue),
                    _SummaryCard(title: 'Aprovados', value: approved.toString(), color: Colors.green),
                    _SummaryCard(title: 'Rejeitados', value: rejected.toString(), color: Colors.red),
                    _SummaryCard(title: 'Pendentes', value: pending.toString(), color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Check-ins',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Exportar PDF será o próximo passo.'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Exportar PDF'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (checkins.isEmpty)
                          const Text(
                            'Nenhum check-in encontrado para este evento.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Aluno')),
                                DataColumn(label: Text('Estado')),
                                DataColumn(label: Text('Leitura')),
                              ],
                              rows: checkins.map((checkin) {
                                final studentName = (checkin['student_name'] ?? 'Aluno').toString();
                                final checkinStatus = (checkin['status'] ?? '-').toString();
                                final readAt = _formatDateTime(
                                  (checkin['read_at'] ?? checkin['created_at'])?.toString(),
                                );

                                return DataRow(
                                  cells: [
                                    DataCell(Text(studentName)),
                                    DataCell(
                                      Text(
                                        checkinStatus,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _statusColor(checkinStatus),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(readAt)),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}