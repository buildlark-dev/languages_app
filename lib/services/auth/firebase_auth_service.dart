/// Autenticación con Firebase.
///
/// Su única responsabilidad delicada es **traducir**: toda `FirebaseAuthException`
/// se convierte en un [AuthFailure] del contrato. Ninguna excepción cruda cruza
/// hacia arriba, porque la interfaz necesita decidir el mensaje por el tipo y no
/// por el texto del error.
library;

import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'auth_service.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final fb.FirebaseAuth _auth;

  @override
  StudentIdentity? get currentUser => _toIdentity(_auth.currentUser);

  @override
  Stream<StudentIdentity?> get authStateChanges =>
      _auth.authStateChanges().map(_toIdentity);

  @override
  Future<StudentIdentity> signUp({
    required String email,
    required String password,
  }) => _guard(() async {
    final fb.UserCredential credential = await _auth
        .createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
    return _requireIdentity(credential.user);
  });

  @override
  Future<StudentIdentity> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    final fb.UserCredential credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _requireIdentity(credential.user);
  });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  StudentIdentity? _toIdentity(fb.User? user) {
    if (user == null) return null;
    return StudentIdentity(uid: user.uid, email: user.email ?? '');
  }

  StudentIdentity _requireIdentity(fb.User? user) {
    final StudentIdentity? identity = _toIdentity(user);
    if (identity == null) throw const AuthException(AuthFailure.unknown);
    return identity;
  }

  /// Envuelve una operación y traduce cualquier fallo a [AuthException].
  Future<T> _guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on fb.FirebaseAuthException catch (error) {
      throw AuthException(_translate(error.code));
    } catch (_) {
      // Un fallo que no es de Firebase Auth (serialización, plataforma) no debe
      // escapar como excepción cruda: la interfaz solo sabe tratar AuthFailure.
      throw const AuthException(AuthFailure.unknown);
    }
  }

  /// Traduce el código de Firebase al fallo del contrato.
  ///
  /// Los códigos están agrupados por lo que la persona tiene que hacer, no por
  /// cómo los nombra Firebase: `invalid-credential`, `wrong-password` y
  /// `invalid-login-credentials` significan lo mismo para quien está intentando
  /// entrar, y Firebase los ha ido renombrando entre versiones.
  static AuthFailure _translate(String code) => switch (code) {
    'invalid-email' => AuthFailure.invalidEmail,
    'weak-password' => AuthFailure.weakPassword,
    'email-already-in-use' => AuthFailure.emailAlreadyInUse,
    'wrong-password' ||
    'invalid-credential' ||
    'invalid-login-credentials' => AuthFailure.wrongCredentials,
    'user-not-found' => AuthFailure.userNotFound,
    'too-many-requests' => AuthFailure.tooManyAttempts,
    'network-request-failed' => AuthFailure.noConnection,
    _ => AuthFailure.unknown,
  };
}
