import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:istec_checkin/providers/app_state.dart';
import 'package:istec_checkin/screens/login_screen.dart';
import 'package:istec_checkin/screens/dashboard_screen.dart';
import 'package:istec_checkin/screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()), // Gerenciamento de estado global. Pode ser expandido para incluir autenticação, dados do usuário, etc.
      ],
      child: const IstecApp(),
    ),
  );
}

// Widget raiz do aplicativo. Configura o tema, rotas e a tela inicial. Pode ser expandido para incluir suporte a múltiplos idiomas, temas dinâmicos, etc.
class IstecApp extends StatelessWidget {
  const IstecApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISTEC Check-in',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
          secondary: Colors.blueAccent,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

// Widget que decide qual tela mostrar com base no estado de autenticação do usuário. Pode ser expandido para incluir lógica de redirecionamento, verificação de token, etc.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AppState>();
    return authState.isLoggedIn ? const MainNavigation() : const LoginScreen(); // Exibe a tela de login se o usuário não estiver autenticado, caso contrário, exibe a navegação principal.
  }
}

// Widget de navegação principal que gerencia as telas de dashboard e histórico. Pode ser expandido para incluir mais telas, animações de transição, etc. 
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(), //Tela principal do app 
    HistoryScreen(), //Tela de histórico de check-ins do usuário
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Histórico'),
        ],
      ),
    );
  }
}
