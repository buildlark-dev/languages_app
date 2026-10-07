/// Estado de la sesión y acciones de autenticación.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth/auth_service.dart';

/// El servicio concreto. **Se sobrescribe en `main.dart`.**
final Provider<AuthService> authServiceProvider = Provider<AuthService>(
  (Ref ref) => throw UnimplementedError(
    'authServiceProvider debe sobrescribirse en main.dart',
  ),
);

/// Quién está dentro, o nulo si no hay sesión.
final StreamProvider<StudentIdentity?> authStateProvider =
    StreamProvider<StudentIdentity?>(
      (Ref ref) => ref.watch(authServiceProvider).authStateChanges,
    );

/// Estado de un formulario de autenticación.
class AuthFormState {
  const AuthFormState({
    this.submitting = false,
    this.failure,
    this.done = false,
  });

  final bool submitting;

  /// Último fallo, para que la pantalla elija el mensaje por el **tipo**.
  final AuthFailure? failure;

  /// La operación terminó bien. Lo usa la pantalla de restablecimiento.
  final bool done;

  AuthFormState clearError() =>
      AuthFormState(submitting: submitting, done: done);
}

/// Ejecuta las operaciones de cuenta y publica su estado.
///
/// Nunca deja escapar una excepción a la interfaz: traduce el fallo a
/// [AuthFormState.failure] para que la pantalla no tenga que envolver nada en
/// `try`. Y **no borra lo que la persona escribió** al fallar, que es lo que
/// FR-004 exige.
class AuthController extends Notifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  Future<bool> signIn({required String email, required String password}) =>
      _run(
        () => ref
            .read(authServiceProvider)
            .signIn(email: email, password: password),
      );

  Future<bool> signUp({required String email, required String password}) =>
      _run(
        () => ref
            .read(authServiceProvider)
            .signUp(email: email, password: password),
      );

  Future<bool> sendPasswordReset(String email) =>
      _run(() => ref.read(authServiceProvider).sendPasswordReset(email));

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = const AuthFormState();
  }

  /// Limpia el error al empezar a escribir de nuevo.
  void dismissError() => state = state.clearError();

  Future<bool> _run(Future<void> Function() operation) async {
    state = const AuthFormState(submitting: true);
    try {
      await operation();
      state = const AuthFormState(done: true);
      return true;
    } on AuthException catch (error) {
      state = AuthFormState(failure: error.failure);
      return false;
    } catch (_) {
      // El contrato promete AuthException, pero si algo se colara no debe
      // llegar como excepción cruda a la pantalla.
      state = const AuthFormState(failure: AuthFailure.unknown);
      return false;
    }
  }
}

final NotifierProvider<AuthController, AuthFormState> authControllerProvider =
    NotifierProvider<AuthController, AuthFormState>(AuthController.new);
