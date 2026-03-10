import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:istec_checkin/web_admin/widgets/top_navigation.dart';
import 'package:istec_checkin/shared/services/auth_service.dart';
import 'home_screen.dart';
import 'requests_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

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
      body: FutureBuilder(
        future: supabase.from('events').select(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data as List;

          if (events.isEmpty) {
            return const Center(child: Text("Nenhum evento cadastrado."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.event),
                  title: Text(event['name'] ?? 'Evento'),
                  subtitle: Text(
                    "${event['start_date'] ?? ''} • ${event['location'] ?? ''}",
                  ),
                  trailing: Text(
                    event['status'] ?? '',
                    style: TextStyle(
                      color: event['status'] == 'active'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
