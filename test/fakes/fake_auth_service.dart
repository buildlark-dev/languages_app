/// Doble de [AuthService] capaz de simular **los ocho** fallos tipados.
///
/// Obligación del contrato: un falso que solo cubriera el camino feliz dejaría
/// sin probar precisamente los mensajes que FR-004 exige distinguir.
library;

import 'dart:async';

import 'package:languages_app/services/auth/auth_service.dart';

class FakeAuthService implements AuthService {
  FakeAuthService({StudentIdentity? initialUser, this.failWith})
    : _currentUser = initialUser {
    _controller.add(_currentUser);
  }

  /// Si no es nulo, toda operación falla con este motivo.
  AuthFailure? failWith;

  StudentIdentity? _currentUser;
  final StreamController<StudentIdentity?> _controller =
      StreamController<StudentIdentity?>.broadcast();

  /// Qué se invocó, para comprobar que la interfaz llama a lo que debe.
  final List<String> calls = <String>[];

  @override
  StudentIdentity? get currentUser => _currentUser;

  @override
  Stream<StudentIdentity?> get authStateChanges => _controller.stream;

  @override
  Future<StudentIdentity> signUp({
    required String email,
    required String password,
  }) async {
    calls.add('signUp:$email');
    return _completeSignIn(email);
  }

  @override
  Future<StudentIdentity> signIn({
    required String email,
    required String password,
  }) async {
    calls.add('signIn:$email');
    return _completeSignIn(email);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    calls.add('reset:$email');
    final AuthFailure? failure = failWith;
    if (failure != null) throw AuthException(failure);
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    _currentUser = null;
    _controller.add(null);
  }

  StudentIdentity _completeSignIn(String email) {
    final AuthFailure? failure = failWith;
    if (failure != null) throw AuthException(failure);
    final StudentIdentity identity = StudentIdentity(
      uid: 'uid-$email',
      email: email,
    );
    _currentUser = identity;
    _controller.add(identity);
    return identity;
  }

  Future<void> dispose() => _controller.close();
}
