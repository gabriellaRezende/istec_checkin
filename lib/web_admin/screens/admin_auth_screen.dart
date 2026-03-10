import 'package:flutter/material.dart';

import 'package:istec_checkin/shared/services/auth_service.dart';
import 'package:istec_checkin/shared/theme/brand_theme.dart';
import 'package:istec_checkin/web_admin/screens/home_screen.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoginMode = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        await AuthService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          expectedRole: 'admin',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login realizado com sucesso.')),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else {
        await AuthService.signUpAdmin(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Conta administrativa criada com sucesso. Já pode iniciar sessão.',
            ),
          ),
        );

        setState(() {
          _isLoginMode = true;
          _passwordController.clear();
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
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BrandTheme.screenBackground(),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BrandTheme.softPanel(color: BrandTheme.navy),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ISTEC Admin',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 14),
                          Text(
                            'Gestao simples de eventos com validação de presença. Tudo dentro do mesmo ecossistema.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Container(
                      decoration: BrandTheme.softPanel(),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isLoginMode
                                    ? 'Entrar no painel administrativo'
                                    : 'Criar conta administrativa',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isLoginMode
                                    ? 'Use as credenciais institucionais para aceder.'
                                    : 'Crie uma conta administrativa com email institucional.',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 24),
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
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email institucional',
                                  hintText: 'nome.sobrenome@my.istec.pt',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';

                                  if (email.isEmpty) {
                                    return 'Informe o email.';
                                  }

                                  if (!AuthService.isInstitutionalEmail(
                                    email,
                                  )) {
                                    return 'Use um email @my.istec.pt válido.';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
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
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _submit,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
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
                                            _isLoginMode
                                                ? 'Entrar'
                                                : 'Criar conta admin',
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton(
                                  onPressed: _isLoading ? null : _toggleMode,
                                  child: Text(
                                    _isLoginMode
                                        ? 'Ainda não tem conta? Criar conta admin'
                                        : 'Já tem conta? Entrar',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
