import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:istec_checkin/mobile/providers/app_state.dart';
import 'package:istec_checkin/mobile/screens/login_screen.dart';
import 'package:istec_checkin/mobile/screens/dashboard_screen.dart';
import 'package:istec_checkin/mobile/screens/history_screen.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rfwqyvuqucithqmbyotf.supabase.co',
    anonKey: 'sb_publishable_eRKuZ6VMOdEGISunf7DZQA_QZIKnzkt',
  );

  runApp(const IstecApp());
}

class IstecApp extends StatelessWidget {
  const IstecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AppState())],
      child: MaterialApp(
        title: 'ISTEC Check-in',
        debugShowCheckedModeBanner: false,
        theme: BrandTheme.light(),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AppState>();

    return authState.isLoggedIn ? const MainNavigation() : const LoginScreen();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [DashboardScreen(), HistoryScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Histórico',
          ),
        ],
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}
