import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? error;

  const AuthState({required this.status, this.error});

  AuthState copyWith({AuthStatus? status, String? error}) =>
      AuthState(status: status ?? this.status, error: error);
}

class AuthNotifier extends StateNotifier<AuthState> {
  late final StreamSubscription<AuthState> _authSub;

  AuthNotifier() : super(const AuthState(status: AuthStatus.loading)) {
    _init();
  }

  void _init() {
    final client = Supabase.instance.client;

    final session = client.auth.currentSession;
    state = session != null
        ? const AuthState(status: AuthStatus.authenticated)
        : const AuthState(status: AuthStatus.unauthenticated);

    _authSub = client.auth.onAuthStateChange
        .map((event) => event.session != null
            ? const AuthState(status: AuthStatus.authenticated)
            : const AuthState(status: AuthStatus.unauthenticated))
        .listen((s) {
      if (mounted) state = s;
    });
  }

  Future<void> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      // Listener updates state
    } on AuthException catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _mapError(e.message),
      );
    } catch (_) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Bir hata oluştu. Lütfen tekrar deneyin.',
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String restaurantName,
    required String slug,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.backendUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'restaurantName': restaurantName,
              'slug': slug,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 400) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw Exception(body['error'] ?? 'Kayıt başarısız');
      }

      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on Exception catch (e) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  String _mapError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'E-posta veya şifre hatalı.';
    }
    if (message.contains('Email already registered')) {
      return 'Bu e-posta zaten kayıtlı.';
    }
    return message;
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
