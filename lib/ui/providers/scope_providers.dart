/// A quién y a qué curso pertenece lo que la pantalla está mirando.
///
/// Está aparte porque lo necesitan el progreso y la cola de repaso, y ambos lo
/// resolvían igual. Dos copias de la misma comprobación de dos nulos es una
/// copia de más: el día que entre un tercer consumidor, la que se olvide de
/// actualizar será la que escriba en el progreso de otra persona.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth/auth_service.dart';
import 'auth_providers.dart';
import 'content_providers.dart';

class StudentScope {
  const StudentScope({required this.uid, required this.courseId});

  final String uid;
  final String courseId;

  @override
  bool operator ==(Object other) =>
      other is StudentScope && other.uid == uid && other.courseId == courseId;

  @override
  int get hashCode => Object.hash(uid, courseId);
}

/// El ámbito actual, o nulo mientras no haya sesión o idioma elegido.
final Provider<StudentScope?> studentScopeProvider = Provider<StudentScope?>((
  Ref ref,
) {
  final StudentIdentity? identity = ref.watch(authStateProvider).value;
  final String? courseId = ref.watch(selectedCourseIdProvider);
  if (identity == null || courseId == null) return null;
  return StudentScope(uid: identity.uid, courseId: courseId);
});

/// El ámbito, observándolo y esperando la identidad si todavía está en camino.
///
/// Es la versión para quien construye estado a partir del ámbito, en lugar de
/// solo pintarlo. La diferencia con [studentScopeProvider] es el `await`: ese
/// devuelve el valor **actual** del flujo de sesión, que en la primera lectura
/// es nulo porque el flujo todavía no emitió. Un `build` que lo leyera así se
/// resolvería con «no hay nadie» y entregaría una pantalla vacía antes de que
/// llegara la identidad.
///
/// La espera es segura porque quien llama ya hizo `ref.watch` del flujo: eso lo
/// mantiene vivo durante el `await`, que es justo lo que falta cuando se lee su
/// futuro a pelo.
Future<StudentScope?> watchStudentScope(Ref ref) async {
  final AsyncValue<StudentIdentity?> auth = ref.watch(authStateProvider);
  final String? courseId = ref.watch(selectedCourseIdProvider);
  if (courseId == null) return null;

  final StudentIdentity? identity = auth.hasValue
      ? auth.value
      : await ref.read(authStateProvider.future);
  if (identity == null) return null;
  return StudentScope(uid: identity.uid, courseId: courseId);
}

/// Resuelve el ámbito esperando la identidad si todavía no llegó.
///
/// [studentScopeProvider] da el valor **actual** de un flujo, y la identidad
/// llega por flujo. Si nadie lo estaba observando todavía, la primera lectura lo
/// encuentra en carga y devuelve nulo, y entonces una escritura disparada por
/// una pulsación se perdería en silencio. Que funcionara o no dependería de qué
/// otro widget estuviera en pantalla, que es la clase de dependencia invisible
/// que rompe una pantalla al reordenar otra.
Future<StudentScope?> resolveStudentScope(Ref ref) async {
  final StudentScope? current = ref.read(studentScopeProvider);
  if (current != null) return current;

  final String? courseId = ref.read(selectedCourseIdProvider);
  if (courseId == null) return null;

  // La suscripción explícita no es ceremonia: en Riverpod 3 los proveedores se
  // desechan solos cuando nadie los observa, así que esperar el futuro de un
  // flujo que nadie más escucha lo desecha **durante la carga**, antes de que
  // emita, y la espera falla con «disposed during loading state».
  final ProviderSubscription<AsyncValue<StudentIdentity?>> keepAlive = ref
      .listen(authStateProvider, (_, _) {});
  try {
    final StudentIdentity? identity = await ref.read(authStateProvider.future);
    if (identity == null) return null;
    return StudentScope(uid: identity.uid, courseId: courseId);
  } finally {
    keepAlive.close();
  }
}
