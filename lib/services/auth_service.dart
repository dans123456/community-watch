import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final client = Supabase.instance.client;

  Future<void> signUp(String email, String password, String name) async {
    final result = await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
    if (result.user != null) {
      await client.from('profiles').upsert({
        'id': result.user!.id,
        'full_name': name,
        'role': 'user',
      });
    }
  }

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() => client.auth.signOut();

  Future<bool> isAdmin() async {
    final user = client.auth.currentUser;
    if (user == null) return false;
    final row = await client.from('profiles').select('role').eq('id', user.id).maybeSingle();
    return row?['role'] == 'admin';
  }
}