import 'package:flutter/material.dart';
import 'package:istec_checkin/web_admin/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:istec_checkin/web_admin/screens/admin_auth_screen.dart';
import 'package:istec_checkin/shared/services/auth_service.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISTEC Admin',
      debugShowCheckedModeBanner: false,
      theme: BrandTheme.light(),
      home: const AdminAuthGate(),
    );
  }
}

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      initialData: AuthState(
        AuthChangeEvent.initialSession,
        Supabase.instance.client.auth.currentSession,
      ),
      builder: (context, snapshot) {
        final user = Supabase.instance.client.auth.currentUser;

        if (user == null) {
          return const AdminAuthScreen();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getCurrentProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Erro ao carregar perfil: ${profileSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await AuthService.signOut();
                          },
                          child: const Text('Voltar ao login'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return const _UnauthorizedAdminAccess(
                message: 'Perfil não encontrado para este utilizador.',
              );
            }

            final role = profile['role'] as String?;

            if (role != 'admin') {
              return const _UnauthorizedAdminAccess(
                message:
                    'Este painel é destinado apenas a administradores autorizados.',
              );
            }

            return const AdminHomeScreen();
          },
        );
      },
    );
  }
}

class _UnauthorizedAdminAccess extends StatelessWidget {
  final String message;

  const _UnauthorizedAdminAccess({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BrandTheme.screenBackground(),
        child: Center(
          child: Container(
            decoration: BrandTheme.softPanel(),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Acesso não autorizado',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(message, textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await AuthService.signOut();
                      },
                      child: const Text('Sair'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
