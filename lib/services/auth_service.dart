import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  Stream<GoogleSignInAccount?> get authStateChanges => _googleSignIn.onCurrentUserChanged;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (error) {
      debugPrint('Error al iniciar sesión silenciosamente: $error');
      return null;
    }
  }

  Future<GoogleSignInAccount?> signInWithGoogle() async {
    try {
      return await _googleSignIn.signIn();
    } catch (error) {
      debugPrint('Error al iniciar sesión con Google: $error');
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('Error al cerrar sesión: $error');
    }
  }

  Future<http.Client?> getAuthenticatedClient() async {
    try {
      return await _googleSignIn.authenticatedClient();
    } catch (error) {
      debugPrint('Error al crear cliente autenticado: $error');
      return null;
    }
  }
}
