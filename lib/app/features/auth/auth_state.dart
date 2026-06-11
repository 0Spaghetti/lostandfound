import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../data/providers.dart';

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
    // Listen to Firebase auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      Future.microtask(() {
        if (user != null) {
          state = AuthState(
            isAuthenticated: true,
            isGuest: user.isAnonymous,
          );
        } else {
          state = const AuthState(
            isAuthenticated: false,
            isGuest: false,
          );
        }
      });
    });

    final currentUser = FirebaseAuth.instance.currentUser;
    return AuthState(
      isAuthenticated: currentUser != null,
      isGuest: currentUser?.isAnonymous ?? false,
    );
  }

  Future<void> login(String email, String password) async {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUp(String name, String email, String password) async {
    final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await userCredential.user?.updateDisplayName(name);
    // Invalidate providers to force them to fetch the fresh name/email from Firebase
    ref.invalidate(profileNameProvider);
    ref.invalidate(profileEmailProvider);
  }

  Future<void> continueAsGuest() async {
    await FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // User canceled the sign-in
      return;
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    
    // authStateChanges listener will automatically trigger profile rebuilds
    // to fetch the Google account's display name and email.
  }

  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
