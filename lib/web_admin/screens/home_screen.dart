import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:istec_checkin/web_admin/widgets/top_navigation.dart';
import 'package:istec_checkin/web_admin/screens/events_screen.dart';
import 'package:istec_checkin/web_admin/screens/requests_screen.dart';

import 'package:istec_checkin/shared/services/auth_service.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TopNavigation(
  title: 'ISTEC Admin',
  currentSection: AdminSection.dashboard,
  onDashboard: () {},
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
    await AuthService.signOut();
  },
),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Modal de criação do evento será o próximo passo.'),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Evento'),
      ),
      body: FutureBuilder<_DashboardData>(
        future: _DashboardData.load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar dashboard: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data ?? _DashboardData.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Visão Geral do Sistema',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Resumo de eventos e validação de presenças.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    DashboardMetricCard(
                      title: 'Eventos Ativos',
                      value: data.activeEvents.toString(),
                      icon: Icons.event_available,
                    ),
                    DashboardMetricCard(
                      title: 'Check-ins Hoje',
                      value: data.checkinsToday.toString(),
                      icon: Icons.qr_code_scanner,
                    ),
                    DashboardMetricCard(
                      title: 'Aprovados',
                      value: data.approvedCheckins.toString(),
                      icon: Icons.check_circle_outline,
                    ),
                    DashboardMetricCard(
                      title: 'Rejeitados',
                      value: data.rejectedCheckins.toString(),
                      icon: Icons.cancel_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Próximos Eventos',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (data.upcomingEvents.isEmpty)
                          const Text(
                            'Nenhum próximo evento encontrado.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ...data.upcomingEvents.map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.event_note),
                                ),
                                title: Text(event.name),
                                subtitle: Text(
                                  '${event.startDate} às ${event.startTime}',
                                ),
                                trailing: Text(
                                  event.status,
                                  style: TextStyle(
                                    color: event.status.toLowerCase() == 'active'
                                        ? Colors.green
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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

class DashboardMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const DashboardMetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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

class _DashboardData {
  final int activeEvents;
  final int checkinsToday;
  final int approvedCheckins;
  final int rejectedCheckins;
  final List<_UpcomingEvent> upcomingEvents;

  const _DashboardData({
    required this.activeEvents,
    required this.checkinsToday,
    required this.approvedCheckins,
    required this.rejectedCheckins,
    required this.upcomingEvents,
  });

  factory _DashboardData.empty() {
    return const _DashboardData(
      activeEvents: 0,
      checkinsToday: 0,
      approvedCheckins: 0,
      rejectedCheckins: 0,
      upcomingEvents: [],
    );
  }

  static Future<_DashboardData> load() async {
    final supabase = Supabase.instance.client;

    final eventsResponse = await supabase.from('events').select();
    final checkinsResponse = await supabase.from('checkins').select();

    final events = List<Map<String, dynamic>>.from(eventsResponse);
    final checkins = List<Map<String, dynamic>>.from(checkinsResponse);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final activeEvents = events.where((event) {
      final status = (event['status'] ?? '').toString().toLowerCase();
      return status == 'active';
    }).length;

    final checkinsToday = checkins.where((checkin) {
      final rawDate = checkin['created_at'] ?? checkin['read_at'];
      if (rawDate == null) return false;

      final parsed = DateTime.tryParse(rawDate.toString());
      if (parsed == null) return false;

      final checkinDate = DateTime(parsed.year, parsed.month, parsed.day);
      return checkinDate == today;
    }).length;

    final approvedCheckins = checkins.where((checkin) {
      final status = (checkin['status'] ?? '').toString().toLowerCase();
      return status == 'approved';
    }).length;

    final rejectedCheckins = checkins.where((checkin) {
      final status = (checkin['status'] ?? '').toString().toLowerCase();
      return status == 'rejected';
    }).length;

    final upcoming = events.map((event) {
      return _UpcomingEvent(
        name: (event['name'] ?? 'Evento sem nome').toString(),
        startDate: (event['start_date'] ?? '-').toString(),
        startTime: (event['start_time'] ?? '-').toString(),
        status: (event['status'] ?? '-').toString(),
      );
    }).toList();

    upcoming.sort((a, b) {
      final aDate = '${a.startDate} ${a.startTime}';
      final bDate = '${b.startDate} ${b.startTime}';

      return aDate.compareTo(bDate);
    });

    return _DashboardData(
      activeEvents: activeEvents,
      checkinsToday: checkinsToday,
      approvedCheckins: approvedCheckins,
      rejectedCheckins: rejectedCheckins,
      upcomingEvents: upcoming.take(5).toList(),
    );
  }
}

class _UpcomingEvent {
  final String name;
  final String startDate;
  final String startTime;
  final String status;

  const _UpcomingEvent({
    required this.name,
    required this.startDate,
    required this.startTime,
    required this.status,
  });
}