import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';

const _isAuthenticatedKey = 'auth_is_authenticated';
const _isGuestKey = 'auth_is_guest';

class AuthState {
  const AuthState({
    required this.isAuthenticated,
    required this.isGuest,
  });

  final bool isAuthenticated;
  final bool isGuest;
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AuthState(
      isAuthenticated: prefs.getBool(_isAuthenticatedKey) ?? false,
      isGuest: prefs.getBool(_isGuestKey) ?? false,
    );
  }

  Future<void> login(String email, String password) async {
    // Mock login delay
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_isAuthenticatedKey, true);
    await prefs.setBool(_isGuestKey, false);
    state = const AuthState(isAuthenticated: true, isGuest: false);
  }

  Future<void> signUp(String name, String email, String password) async {
    // Mock signup delay
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_isAuthenticatedKey, true);
    await prefs.setBool(_isGuestKey, false);
    state = const AuthState(isAuthenticated: true, isGuest: false);
  }

  Future<void> continueAsGuest() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_isAuthenticatedKey, false);
    await prefs.setBool(_isGuestKey, true);
    state = const AuthState(isAuthenticated: false, isGuest: true);
  }

  Future<void> logout() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_isAuthenticatedKey, false);
    await prefs.setBool(_isGuestKey, false);
    state = const AuthState(isAuthenticated: false, isGuest: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
