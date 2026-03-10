import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();

  static final SupabaseClient _supabase = Supabase.instance.client;

  static const String _institutionDomain = '@my.istec.pt';

  static bool isInstitutionalEmail(String email) {
    final normalized = email.trim().toLowerCase();

    final regex = RegExp(r'^[a-zA-Z0-9._-]+@my\.istec\.pt$');
    return regex.hasMatch(normalized);
  }

  static Future<AuthResponse> signUpStudent({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return _signUpWithRole(
      fullName: fullName,
      email: email,
      password: password,
      role: 'student',
    );
  }

  static Future<AuthResponse> signUpAdmin({
    required String fullName,
    required String email,
    required String password,
  }) async {
    return _signUpWithRole(
      fullName: fullName,
      email: email,
      password: password,
      role: 'admin',
    );
  }

  static Future<AuthResponse> _signUpWithRole({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = fullName.trim();

    if (normalizedName.isEmpty) {
      throw Exception('O nome é obrigatório.');
    }

    if (!isInstitutionalEmail(normalizedEmail)) {
      throw Exception(
        'Utilize um email institucional válido no formato nome.sobrenome$_institutionDomain',
      );
    }

    if (password.trim().length < 6) {
      throw Exception('A password deve ter pelo menos 6 caracteres.');
    }

    final existingProfile = await _supabase
        .from('profiles')
        .select('id, email, role')
        .eq('email', normalizedEmail)
        .maybeSingle();

    if (existingProfile != null) {
      final existingRole = existingProfile['role'];

      if (existingRole == role) {
        throw Exception('Este email já está registado.');
      }

      if (role == 'student') {
        throw Exception(
          'Este email já está registado como utilizador administrativo. O registo no app é apenas para alunos.',
        );
      }

      throw Exception(
        'Este email já está registado como aluno. O painel web é apenas para utilizadores autorizados.',
      );
    }

    final response = await _supabase.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {
        'full_name': normalizedName,
        'role': role,
      },
    );

    final user = response.user;

    if (user == null) {
      throw Exception(
        'Não foi possível concluir o registo neste momento. Tente novamente.',
      );
    }

    await _supabase.from('profiles').insert({
      'id': user.id,
      'full_name': normalizedName,
      'email': normalizedEmail,
      'role': role,
    });

    return response;
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
    required String expectedRole,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!isInstitutionalEmail(normalizedEmail)) {
      throw Exception(
        'Utilize um email institucional válido no formato nome.sobrenome$_institutionDomain',
      );
    }

    final response = await _supabase.auth.signInWithPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = response.user;

    if (user == null) {
      throw Exception('Não foi possível autenticar o utilizador.');
    }

    final profile = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profile == null) {
      await _supabase.auth.signOut();
      throw Exception('Perfil do utilizador não encontrado.');
    }

    final role = profile['role'] as String?;

    if (role != expectedRole) {
      await _supabase.auth.signOut();

      if (expectedRole == 'student') {
        throw Exception(
          'Este acesso é destinado apenas a alunos. Utilize o painel correto.',
        );
      }

      throw Exception(
        'Este acesso é destinado apenas a administradores autorizados.',
      );
    }

    return response;
  }

  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    final user = _supabase.auth.currentUser;

    if (user == null) return null;

    return await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
  }

  static User? get currentUser => _supabase.auth.currentUser;

  static Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}