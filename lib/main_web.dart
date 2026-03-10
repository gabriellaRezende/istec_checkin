import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:istec_checkin/web_admin/app_web.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rfwqyvuqucithqmbyotf.supabase.co',
    anonKey: 'sb_publishable_eRKuZ6VMOdEGISunf7DZQA_QZIKnzkt',
  );

  runApp(const AdminApp());
}