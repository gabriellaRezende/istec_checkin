import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:istec_checkin/shared/services/auth_service.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';
import 'package:istec_checkin/web_admin/screens/events_screen.dart';
import 'package:istec_checkin/web_admin/screens/home_screen.dart';
import 'package:istec_checkin/web_admin/widgets/top_navigation.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _loadRequests();
  }

  Future<List<Map<String, dynamic>>> _loadRequests() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('checkins')
        .select()
        .eq('status', 'pending')
        .order('read_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _reload() async {
    setState(() {
      _requestsFuture = _loadRequests();
    });
  }

  Future<void> _updateStatus({required int id, required String status}) async {
    final supabase = Supabase.instance.client;

    await supabase.from('checkins').update({'status': status}).eq('id', id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'approved'
              ? 'Check-in aprovado com sucesso.'
              : 'Check-in rejeitado com sucesso.',
        ),
      ),
    );

    await _reload();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        currentSection: AdminSection.requests,
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
        onRequests: () {},
        onSignOut: () async {
          await AuthService.signOutAndRedirect(context);
        },
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar solicitações: ${snapshot.error}'),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Container(
              decoration: BrandTheme.screenBackground(),
              child: RefreshIndicator(
                onRefresh: _reload,
                child: ListView(
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BrandTheme.softPanel(),
                        child: const Text(
                          'Nenhuma solicitação pendente.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            decoration: BrandTheme.screenBackground(),
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];

                  final id = request['id'] as int;
                  final studentName = (request['student_name'] ?? 'Aluno')
                      .toString();
                  final studentEmail = (request['student_email'] ?? '-')
                      .toString();
                  final eventName = (request['event_name'] ?? 'Evento')
                      .toString();
                  final eventAddress = (request['event_address'] ?? '')
                      .toString();
                  final distance = (request['distance_meters'] ?? 0).toString();
                  final readAt = _formatDateTime(
                    (request['read_at'] ?? request['created_at'])?.toString(),
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BrandTheme.softPanel(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eventName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _RequestInfoRow(label: 'Aluno', value: studentName),
                          _RequestInfoRow(label: 'Email', value: studentEmail),
                          _RequestInfoRow(label: 'Morada', value: eventAddress),
                          _RequestInfoRow(
                            label: 'Distância',
                            value:
                                '${double.tryParse(distance)?.toStringAsFixed(1) ?? distance} m',
                          ),
                          _RequestInfoRow(label: 'Leitura', value: readAt),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              FilledButton.icon(
                                onPressed: () async {
                                  await _updateStatus(
                                    id: id,
                                    status: 'approved',
                                  );
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Aprovar'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await _updateStatus(
                                    id: id,
                                    status: 'rejected',
                                  );
                                },
                                icon: const Icon(Icons.close),
                                label: const Text('Rejeitar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RequestInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _RequestInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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
