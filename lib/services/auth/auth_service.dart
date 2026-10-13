/// Contrato de autenticación.
///
/// Ninguna excepción del proveedor cruza esta frontera. La interfaz necesita dar
/// un mensaje distinto a cada caso (FR-004), y para eso los errores tienen que
/// ser un tipo cerrado, no un texto que haya que inspeccionar con `contains`.
library;

/// Identidad mínima de un estudiante autenticado.
///
/// Solo lo necesario para sincronizar: FR-006 prohíbe pedir más datos.
class StudentIdentity {
  const StudentIdentity({required this.uid, required this.email});

  final String uid;
  final String email;
}

/// Lo que puede fallar al crear una cuenta o entrar.
enum AuthFailure {
  invalidEmail,
  weakPassword,
  emailAlreadyInUse,
  wrongCredentials,
  userNotFound,
  tooManyAttempts,

  /// Sin red. Es el caso del primer arranque, que FR-004 obliga a explicar con
  /// claridad y a dejar reintentable.
  noConnection,

  unknown,
}

/// Error de autenticación tipado.
class AuthException implements Exception {
  const AuthException(this.failure);

  final AuthFailure failure;

  @override
  String toString() => 'AuthException(${failure.name})';
}

abstract interface class AuthService {
  /// La sesión actual, o nulo si no hay ninguna.
  StudentIdentity? get currentUser;

  /// Emite al entrar y al salir.
  Stream<StudentIdentity?> get authStateChanges;

  /// Crea una cuenta. Lanza [AuthException] con su causa tipada.
  Future<StudentIdentity> signUp({
    required String email,
    required String password,
  });

  /// Inicia sesión. Lanza [AuthException] con su causa tipada.
  Future<StudentIdentity> signIn({
    required String email,
    required String password,
  });

  /// Envía el correo de restablecimiento de contraseña.
  Future<void> sendPasswordReset(String email);

  /// Cierra la sesión.
  ///
  /// **No borra la base local.** Quién borra y cuándo lo decide la interfaz, que
  /// antes debe advertir qué quedaría sin respaldar (FR-005). Separarlo evita
  /// que cerrar sesión por error destruya progreso sin sincronizar.
  Future<void> signOut();
}
