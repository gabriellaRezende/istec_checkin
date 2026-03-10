import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:istec_checkin/web_admin/widgets/top_navigation.dart';
import 'package:istec_checkin/shared/services/auth_service.dart';
import 'home_screen.dart';
import 'events_screen.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

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
      body: FutureBuilder(
        future: supabase.from('checkins').select().eq('status', 'pending'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final checkins = snapshot.data as List;

          if (checkins.isEmpty) {
            return const Center(child: Text("Nenhuma solicitação pendente."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: checkins.length,
            itemBuilder: (context, index) {
              final checkin = checkins[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: Text(checkin['student_name'] ?? 'Aluno'),
                  subtitle: Text("Evento: ${checkin['event_id']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await supabase
                              .from('checkins')
                              .update({'status': 'approved'})
                              .eq('id', checkin['id']);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await supabase
                              .from('checkins')
                              .update({'status': 'rejected'})
                              .eq('id', checkin['id']);
                        },
                      ),
                    ],
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
