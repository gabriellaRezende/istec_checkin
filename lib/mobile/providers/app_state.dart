import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:istec_checkin/shared/models/check_in.dart';
import 'package:istec_checkin/shared/services/auth_service.dart';

class AppState with ChangeNotifier {
  bool _isLoggedIn = AuthService.currentUser != null;
  List<CheckInRecord> _history = [];

  bool get isLoggedIn => _isLoggedIn;
  List<CheckInRecord> get history => _history;

  AppState() {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _isLoggedIn = AuthService.currentUser != null;

    if (_isLoggedIn) {
      await refreshHistory();
    } else {
      _history = [];
      notifyListeners();
    }
  }

  Future<void> setLoggedIn() async {
    _isLoggedIn = true;
    notifyListeners();
    await refreshHistory();
  }

  void logout() {
    _isLoggedIn = false;
    _history = [];
    notifyListeners();
  }

  Future<void> addRecord(CheckInRecord record) async {
    _history.insert(0, record);
    notifyListeners();
  }

  Future<void> refreshHistory() async {
    try {
      final user = AuthService.currentUser;

      if (user == null) {
        _history = [];
        notifyListeners();
        return;
      }

      final supabase = Supabase.instance.client;
      List<Map<String, dynamic>> rows = [];

      try {
        final response = await supabase
            .from('checkins')
            .select('id,status,created_at,read_at,event_id,student_name,student_email,events(name,adress)')
            .eq('student_email', user.email ?? '')
            .order('created_at', ascending: false);

        rows = List<Map<String, dynamic>>.from(response);
      } catch (_) {
        final profile = await AuthService.getCurrentProfile();
        final fullName = (profile?['full_name'] ?? '').toString();

        if (fullName.isNotEmpty) {
          final response = await supabase
              .from('checkins')
              .select('id,status,created_at,read_at,event_id,student_name,event_name,event_address')
              .eq('student_name', fullName)
              .order('created_at', ascending: false);

          rows = List<Map<String, dynamic>>.from(response);
        }
      }

      _history = rows.map(_mapCheckInRecord).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar histórico do Supabase: $e');
    }
  }

  CheckInRecord _mapCheckInRecord(Map<String, dynamic> row) {
    final status = (row['status'] ?? '').toString().toLowerCase();
    final relatedEvent = row['events'];

    String eventName = 'Evento';
    String location = '';

    if (relatedEvent is Map<String, dynamic>) {
      eventName = (relatedEvent['name'] ?? 'Evento').toString();
      location = (relatedEvent['adress'] ?? '').toString();
    } else {
      eventName = (row['event_name'] ?? row['event_id'] ?? 'Evento').toString();
      location = (row['event_address'] ?? row['adress'] ?? '').toString();
    }

    return CheckInRecord.fromJson({
      'id': (row['id'] ?? '').toString(),
      'code': eventName,
      'location': location,
      'status': status.isEmpty ? 'pending' : status,
      'timestamp': (row['read_at'] ?? row['created_at'] ?? DateTime.now().toIso8601String()).toString(),
    });
  }
}
