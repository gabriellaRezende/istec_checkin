import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:istec_checkin/web_admin/widgets/top_navigation.dart';
import 'package:istec_checkin/shared/services/auth_service.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';
import 'package:istec_checkin/web_admin/screens/events_details_screen.dart';

import 'home_screen.dart';
import 'requests_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  late Future<List<Map<String, dynamic>>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
  }

  Future<List<Map<String, dynamic>>> _loadEvents() async {
    final supabase = Supabase.instance.client;

    await _expireFinishedEvents();

    final response = await supabase
        .from('events')
        .select()
        .order('start_date', ascending: false)
        .order('start_time', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _reload() async {
    setState(() {
      _eventsFuture = _loadEvents();
    });
  }

  Future<void> _expireFinishedEvents() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('events')
        .select('id, end_date, end_time, status');

    final events = List<Map<String, dynamic>>.from(response);
    final now = DateTime.now();

    for (final event in events) {
      final status = (event['status'] ?? '').toString().toLowerCase();
      final rawEndDate = event['end_date']?.toString();
      final rawEndTime = event['end_time']?.toString();

      if (status != 'active') continue;
      if (rawEndDate == null || rawEndTime == null) continue;

      final normalizedTime = rawEndTime.length == 5
          ? '$rawEndTime:00'
          : rawEndTime;

      final endDateTime = DateTime.tryParse('${rawEndDate}T$normalizedTime');

      if (endDateTime == null) continue;

      if (now.isAfter(endDateTime)) {
        await supabase
            .from('events')
            .update({'status': 'inactive'})
            .eq('id', event['id']);
      }
    }
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final y = parsed.year.toString();

    return "$d/$m/$y";
  }

  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  Color _statusColor(String status) {
    if (status == 'active') return Colors.green;
    if (status == 'inactive') return Colors.grey;
    return Colors.blueGrey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
        currentSection: AdminSection.events,
        onDashboard: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
          );
        },
        onEvents: () {},
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
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar eventos: ${snapshot.error}'),
            );
          }

          final events = snapshot.data ?? [];

          if (events.isEmpty) {
            return const Center(child: Text('Nenhum evento cadastrado.'));
          }

          return Container(
            decoration: BrandTheme.screenBackground(),
            child: RefreshIndicator(
              onRefresh: _reload,
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];

                  final name = event['name'] ?? 'Evento';
                  final address = event['adress'] ?? '';
                  final status = (event['status'] ?? '').toString();

                  final startDate = _formatDate(event['start_date']);
                  final startTime = _formatTime(event['start_time']);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BrandTheme.softPanel(),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EventDetailScreen(event: event),
                          ),
                        );
                      },
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: BrandTheme.sky,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.event, color: BrandTheme.navy),
                      ),
                      title: Text(name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$startDate às $startTime"),
                          if (address.isNotEmpty)
                            Text(
                              address,
                              style: const TextStyle(color: Colors.grey),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            status,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _statusColor(status),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 16),
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
