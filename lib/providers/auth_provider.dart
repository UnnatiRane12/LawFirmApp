import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<User?> {
  AuthNotifier() : super(SupabaseService.client.auth.currentUser) {
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      state = data.session?.user;
    });
  }

  Future<void> signUp(String email, String password, {required String fullName, required String role}) async {
    final response = await SupabaseService.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );
    
    // Manually create profile if signup successful (replaces trigger)
    if (response.user != null) {
      await SupabaseService.client.from('profiles').insert({
        'id': response.user!.id,
        'email': email,
        'full_name': fullName,
        'role': role,
      });
    }

    state = response.user;
  }

  Future<void> signIn(String email, String password) async {
    final response = await SupabaseService.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    state = response.user;
  }

  Future<void> signOut() async {
    await SupabaseService.client.auth.signOut();
    state = null;
  }

  String? get userRole => state?.userMetadata?['role'] as String?;
}
