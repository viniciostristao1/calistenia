import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Login com Google nativo (google_sign_in), o seletor de conta do Android.
/// Usa o Web client ID (oauth_client type 3 do google-services.json) como
/// serverClientId. Ele não é segredo (vai no app de qualquer forma).
const _serverClientId =
    '520001144356-490n59hclltbfsh51refjvd40g3sre7t.apps.googleusercontent.com';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;
  bool _gsiInit = false;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureInit() async {
    if (_gsiInit) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _gsiInit = true;
  }

  Future<void> signInWithGoogle() async {
    await _ensureInit();
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    await _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    // Firebase primeiro (a UI muda na hora); o signOut do Google roda depois.
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // ignora se o google_sign_in ainda não foi inicializado
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(FirebaseAuth.instance);
});

/// Estado de login em tempo real (null = deslogado).
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authState;
});
