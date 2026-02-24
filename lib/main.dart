import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:istec_checkin/providers/app_state.dart';
import 'package:istec_checkin/screens/login_screen.dart';
import 'package:istec_checkin/screens/dashboard_screen.dart';
import 'package:istec_checkin/screens/history_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // inicializa o flutter e o sistema nativo.
  runApp(
    // Inicia com o multiprovider que injeta o AppState para a aplicação.
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()), // Toda a aplicação terá acesso ao AppState, que gerencia o estado global.
      ],
      child: const IstecApp(),
    ),
  );
}


class IstecApp extends StatelessWidget {
  const IstecApp({super.key});

// Metodo build retorna um widget.
// Aqui retorna o MaterialApp que defini o tema e a estrutura do aplicativo.
  @override
  Widget build(BuildContext context) {
    return MaterialApp( //Define o tema, titulo e a tela home.
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
      home: const AuthWrapper(), //retorna a classe AuthWrapper que decide qual tela mostrar com base no estado de autenticação do usuário.
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

// Widget de navegação principal que gerencia as telas de dashboard e histórico. 
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0; // Índice da tela atualmente selecionada na barra de navegação. Ou seja, inicia com a tela de dashboard selecionada. Altera para 1 quando clica no histórico.

  static const List<Widget> _screens = [
    DashboardScreen(), //Tela principal do app 
    HistoryScreen(), //Tela de histórico de check-ins do usuário
  ];

//Scafoold retorna com a estrutura da tela que foi selecionada na navegação.
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
