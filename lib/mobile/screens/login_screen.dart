import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:istec_checkin/mobile/providers/app_state.dart';
import 'package:istec_checkin/shared/services/auth_service.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await AuthService.signIn(
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
          expectedRole: 'student',
        );

        if (!mounted) return;

        await context
            .read<AppState>()
            .setLoggedIn(); // Atualiza o estado global para refletir o login
      } else {
        await AuthService.signUpStudent(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conta de aluno criada com sucesso. Já pode iniciar sessão.',
            ),
          ),
        );

        setState(() {
          _isLoginMode = true;
          _passController.clear();
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _passController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BrandTheme.heroBackground(),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  decoration: BrandTheme.softPanel(
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: BrandTheme.mist,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Image.asset(
                              'assets/images/istec_logo.png',
                              width: 110,
                              height: 110,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            _isLoginMode
                                ? 'Entrar como Aluno'
                                : 'Criar conta de Aluno',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: BrandTheme.ink,
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLoginMode
                                ? 'Acesso destinado apenas a alunos.'
                                : 'Use o email institucional @my.istec.pt.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          if (!_isLoginMode) ...[
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome completo',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (value) {
                                if (_isLoginMode) return null;
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o nome completo.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email institucional',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              final email = value?.trim() ?? '';

                              if (email.isEmpty) {
                                return 'Informe o email.';
                              }

                              if (!AuthService.isInstitutionalEmail(email)) {
                                return 'Use um email @my.istec.pt válido.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: (value) {
                              final password = value?.trim() ?? '';

                              if (password.isEmpty) {
                                return 'Informe a password.';
                              }

                              if (!_isLoginMode && password.length < 6) {
                                return 'Mínimo de 6 caracteres.';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isLoginMode ? 'ENTRAR' : 'CRIAR CONTA',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _isLoading ? null : _toggleMode,
                            child: Text(
                              _isLoginMode
                                  ? 'Ainda não tem conta? Criar conta de aluno'
                                  : 'Já tem conta? Entrar',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
