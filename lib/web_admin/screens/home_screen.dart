import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:istec_checkin/web_admin/widgets/top_navigation.dart';
import 'package:istec_checkin/web_admin/screens/events_screen.dart';
import 'package:istec_checkin/web_admin/screens/requests_screen.dart';
import 'package:istec_checkin/web_admin/widgets/create_event_modal.dart';

import 'package:istec_checkin/shared/services/auth_service.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';

import 'package:qr_flutter/qr_flutter.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late Future<_DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _DashboardData.load();
  }

  Future<void> _reloadDashboard() async {
    setState(() {
      _dashboardFuture = _DashboardData.load();
    });
  }

  Future<void> _showEventCreatedDialog(Map<String, dynamic> event) async {
    final name = (event['name'] ?? '').toString();
    final address = (event['adress'] ?? '').toString();
    final startDate = (event['start_date'] ?? '').toString();
    final startTime = (event['start_time'] ?? '').toString();
    final endDate = (event['end_date'] ?? '').toString();
    final endTime = (event['end_time'] ?? '').toString();
    final radius = (event['radius_meters'] ?? '').toString();

    final qrData = 'ISTEC_EVENT:${event['id']}';

    await showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          child: SizedBox(
            width: 650,
            child: Container(
              decoration: BrandTheme.softPanel(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evento criado com sucesso',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nome: $name'),
                              const SizedBox(height: 8),
                              Text('Morada: $address'),
                              const SizedBox(height: 8),
                              Text(
                                'Início: $startDate às ${startTime.length >= 5 ? startTime.substring(0, 5) : startTime}',
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fim: $endDate às ${endTime.length >= 5 ? endTime.substring(0, 5) : endTime}',
                              ),
                              const SizedBox(height: 8),
                              Text('Raio permitido: $radius metros'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            const Text(
                              'QR Code',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: BrandTheme.mist,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: QrImageView(
                                data: qrData,
                                version: QrVersions.auto,
                                size: 200,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Fechar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

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
          await AuthService.signOutAndRedirect(context);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final event = await showDialog(
            context: context,
            builder: (_) => const CreateEventModal(),
          );

          if (event != null) {
            if (!mounted) return;

            await _reloadDashboard();

            if (!mounted) return;

            await _showEventCreatedDialog(Map<String, dynamic>.from(event));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Evento'),
      ),
      body: FutureBuilder<_DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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

          return Container(
            decoration: BrandTheme.screenBackground(),
            child: RefreshIndicator(
              onRefresh: _reloadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Visão Geral do Sistema',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                  Container(
                    decoration: BrandTheme.softPanel(),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Eventos em Andamento',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (data.ongoingEvents.isEmpty)
                            const Text(
                              'Nenhum evento em andamento neste momento.',
                              style: TextStyle(color: Colors.grey),
                            )
                          else
                            ...data.ongoingEvents.map(
                              (event) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.play_circle_outline),
                                  ),
                                  title: Text(event.name),
                                  subtitle: Text(
                                    '${event.formattedDate} • ${event.formattedTimeRange}',
                                  ),
                                  trailing: Text(
                                    event.status,
                                    style: const TextStyle(
                                      color: Colors.green,
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
                  const SizedBox(height: 24),
                  Container(
                    decoration: BrandTheme.softPanel(),
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
                                    '${event.formattedDate} às ${event.formattedTime}',
                                  ),
                                  trailing: Text(
                                    event.status,
                                    style: TextStyle(
                                      color:
                                          event.status.toLowerCase() == 'active'
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
      child: Container(
        decoration: BrandTheme.softPanel(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: BrandTheme.sky,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: BrandTheme.navy),
              ),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.grey)),
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
  final List<_DashboardEventItem> ongoingEvents;
  final List<_UpcomingEvent> upcomingEvents;

  const _DashboardData({
    required this.activeEvents,
    required this.checkinsToday,
    required this.approvedCheckins,
    required this.rejectedCheckins,
    required this.ongoingEvents,
    required this.upcomingEvents,
  });

  factory _DashboardData.empty() {
    return const _DashboardData(
      activeEvents: 0,
      checkinsToday: 0,
      approvedCheckins: 0,
      rejectedCheckins: 0,
      ongoingEvents: [],
      upcomingEvents: [],
    );
  }

  static Future<void> _expireFinishedEvents() async {
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

  static Future<_DashboardData> load() async {
    final supabase = Supabase.instance.client;
    await _expireFinishedEvents();

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

    final ongoing = events
        .map((event) {
          final name = (event['name'] ?? 'Evento sem nome').toString();
          final status = (event['status'] ?? '-').toString();
          final rawStartDate = (event['start_date'] ?? '').toString();
          final rawStartTime = (event['start_time'] ?? '').toString();
          final rawEndDate = (event['end_date'] ?? '').toString();
          final rawEndTime = (event['end_time'] ?? '').toString();

          final startDateTime = _parseEventDateTime(rawStartDate, rawStartTime);
          final endDateTime = _parseEventDateTime(rawEndDate, rawEndTime);
          final isActive = status.toLowerCase() == 'active';

          if (!isActive || startDateTime == null || endDateTime == null) {
            return null;
          }

          if (now.isBefore(startDateTime) || now.isAfter(endDateTime)) {
            return null;
          }

          return _DashboardEventItem(
            name: name,
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            status: status,
          );
        })
        .whereType<_DashboardEventItem>()
        .toList();

    ongoing.sort((a, b) => a.endDateTime.compareTo(b.endDateTime));

    final upcoming = events
        .map((event) {
          final name = (event['name'] ?? 'Evento sem nome').toString();
          final status = (event['status'] ?? '-').toString();
          final rawDate = (event['start_date'] ?? '').toString();
          final rawTime = (event['start_time'] ?? '').toString();

          final startDateTime = _parseEventDateTime(rawDate, rawTime);
          if (startDateTime == null) return null;
          if (startDateTime.isBefore(now)) return null;

          return _UpcomingEvent(
            name: name,
            startDateTime: startDateTime,
            status: status,
          );
        })
        .whereType<_UpcomingEvent>()
        .toList();

    upcoming.sort((a, b) => a.startDateTime.compareTo(b.startDateTime));

    return _DashboardData(
      activeEvents: activeEvents,
      checkinsToday: checkinsToday,
      approvedCheckins: approvedCheckins,
      rejectedCheckins: rejectedCheckins,
      ongoingEvents: ongoing.take(5).toList(),
      upcomingEvents: upcoming.take(5).toList(),
    );
  }

  static DateTime? _parseEventDateTime(String rawDate, String rawTime) {
    if (rawDate.isEmpty || rawTime.isEmpty) return null;

    final normalizedTime = rawTime.length == 5 ? '$rawTime:00' : rawTime;
    return DateTime.tryParse('${rawDate}T$normalizedTime');
  }
}

class _UpcomingEvent {
  final String name;
  final DateTime startDateTime;
  final String status;

  const _UpcomingEvent({
    required this.name,
    required this.startDateTime,
    required this.status,
  });

  String get formattedDate {
    final day = startDateTime.day.toString().padLeft(2, '0');
    final month = startDateTime.month.toString().padLeft(2, '0');
    final year = startDateTime.year.toString();
    return '$day/$month/$year';
  }

  String get formattedTime {
    final hour = startDateTime.hour.toString().padLeft(2, '0');
    final minute = startDateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _DashboardEventItem {
  final String name;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String status;

  const _DashboardEventItem({
    required this.name,
    required this.startDateTime,
    required this.endDateTime,
    required this.status,
  });

  String get formattedDate {
    final day = startDateTime.day.toString().padLeft(2, '0');
    final month = startDateTime.month.toString().padLeft(2, '0');
    final year = startDateTime.year.toString();
    return '$day/$month/$year';
  }

  String get formattedTimeRange {
    final startHour = startDateTime.hour.toString().padLeft(2, '0');
    final startMinute = startDateTime.minute.toString().padLeft(2, '0');
    final endHour = endDateTime.hour.toString().padLeft(2, '0');
    final endMinute = endDateTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }
}
