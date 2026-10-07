/// Estado de la cola de repaso.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module.dart';
import '../../core/review_card.dart';
import '../../services/auth/auth_service.dart';
import '../../services/review/review_store.dart';
import 'auth_providers.dart';
import 'clock_providers.dart';
import 'content_providers.dart';

/// El almacén concreto. **Se sobrescribe en `main.dart`.**
final Provider<ReviewStore> reviewStoreProvider = Provider<ReviewStore>(
  (Ref ref) => throw UnimplementedError(
    'reviewStoreProvider debe sobrescribirse en main.dart',
  ),
);

/// A quién y a qué curso pertenece la cola que se está mirando.
///
/// Es nulo mientras no haya sesión o no se haya elegido idioma, y entonces no
/// hay cola que consultar. Tenerlo como un solo valor evita que cada consulta
/// repita la misma comprobación de dos nulos.
class ReviewScope {
  const ReviewScope({required this.uid, required this.courseId});

  final String uid;
  final String courseId;

  @override
  bool operator ==(Object other) =>
      other is ReviewScope && other.uid == uid && other.courseId == courseId;

  @override
  int get hashCode => Object.hash(uid, courseId);
}

final Provider<ReviewScope?> reviewScopeProvider = Provider<ReviewScope?>((
  Ref ref,
) {
  final StudentIdentity? identity = ref.watch(authStateProvider).value;
  final String? courseId = ref.watch(selectedCourseIdProvider);
  if (identity == null || courseId == null) return null;
  return ReviewScope(uid: identity.uid, courseId: courseId);
});

/// Lo que la pantalla principal necesita saber de la cola.
///
/// Lleva [total] además de [dueToday] porque cero vencidas significa dos cosas
/// muy distintas: quien ya repasó todo hoy merece un «estás al día», y quien
/// todavía no ha empezado ningún módulo no tiene nada que repasar y merece otra
/// frase. FR-030 prohíbe resolver ambos abriendo una sesión vacía.
class ReviewSummary {
  const ReviewSummary({required this.dueToday, required this.total});

  static const ReviewSummary empty = ReviewSummary(dueToday: 0, total: 0);

  final int dueToday;
  final int total;

  /// Hay tarjetas, pero ninguna vence hoy.
  bool get isUpToDate => dueToday == 0 && total > 0;

  /// Todavía no hay cola: no se ha empezado ningún módulo.
  bool get isEmpty => total == 0;
}

/// Mantiene el resumen de la cola y aplica lo que la cambia.
///
/// Es un [AsyncNotifier] y no un `FutureProvider` suelto porque además de leer
/// tiene que **escribir**: sembrar al empezar un módulo y guardar cada tarjeta
/// calificada. Y tras cada escritura el conteo de la pantalla principal debe
/// quedar al día sin que nadie recuerde refrescarlo.
class ReviewSummaryController extends AsyncNotifier<ReviewSummary> {
  @override
  Future<ReviewSummary> build() async {
    final ReviewScope? scope = ref.watch(reviewScopeProvider);
    if (scope == null) return ReviewSummary.empty;
    return _read(scope);
  }

  Future<ReviewSummary> _read(ReviewScope scope) async {
    final ReviewStore store = ref.read(reviewStoreProvider);
    final DateTime today = ref.read(clockProvider)();
    final int due = await store.dueCount(
      uid: scope.uid,
      courseId: scope.courseId,
      today: today,
    );
    final int total = await store.totalCount(
      uid: scope.uid,
      courseId: scope.courseId,
    );
    return ReviewSummary(dueToday: due, total: total);
  }

  /// Siembra la cola con el vocabulario de [module] (FR-028).
  ///
  /// Se llama al **entrar** en el módulo, no al aprobarlo: la palabra se repasa
  /// desde el día en que se estudia, no desde el día en que se examina. Es
  /// idempotente, así que entrar y salir diez veces no cambia nada.
  Future<void> seedModule(Module module) => _write(
    (ReviewScope scope, ReviewStore store) => store.seedModule(
      uid: scope.uid,
      courseId: scope.courseId,
      moduleId: module.id,
      vocabulary: module.vocabulary,
      today: ref.read(clockProvider)(),
    ),
  );

  /// Guarda una tarjeta ya reprogramada por el planificador.
  Future<void> saveGraded(ReviewCard card) => _write(
    (ReviewScope scope, ReviewStore store) =>
        store.save(uid: scope.uid, courseId: scope.courseId, card: card),
  );

  /// Escribe y deja el resumen al día, sin dejar escapar la excepción.
  ///
  /// El fallo se publica como estado de error en lugar de propagarse, porque
  /// quien llama es una pulsación: no hay nadie esperando el resultado para
  /// decidir nada, y una excepción suelta en un `Future` sin `await` acabaría
  /// como error no capturado de zona. La tarjeta de la pantalla principal
  /// simplemente deja de mostrarse, y el aviso de almacenamiento degradado ya
  /// cubre el caso en que la base entera no funciona (FR-043).
  Future<void> _write(
    Future<void> Function(ReviewScope scope, ReviewStore store) operation,
  ) async {
    final ReviewScope? scope = await _resolveScope();
    if (scope == null) return;

    state = await AsyncValue.guard<ReviewSummary>(() async {
      await operation(scope, ref.read(reviewStoreProvider));
      return _read(scope);
    });
  }

  /// Resuelve a quién pertenece la cola, esperando la identidad si hace falta.
  ///
  /// [reviewScopeProvider] da el valor **actual** de un flujo, y la identidad
  /// llega por flujo. Si nadie lo estaba observando todavía, la primera lectura
  /// lo encuentra en carga y devuelve nulo, y entonces la siembra se perdería en
  /// silencio. Que funcione o no dependería de qué otro widget estuviera en
  /// pantalla, que es la clase de dependencia invisible que rompe una pantalla
  /// al reordenar otra.
  Future<ReviewScope?> _resolveScope() async {
    final ReviewScope? current = ref.read(reviewScopeProvider);
    if (current != null) return current;

    final String? courseId = ref.read(selectedCourseIdProvider);
    if (courseId == null) return null;

    // La suscripción explícita no es ceremonia: en Riverpod 3 los proveedores se
    // desechan solos cuando nadie los observa, así que un `read` del futuro de
    // un flujo que nadie más escucha lo desecha **durante la carga**, antes de
    // que emita, y la espera falla con «disposed during loading state».
    final ProviderSubscription<AsyncValue<StudentIdentity?>> keepAlive = ref
        .listen(authStateProvider, (_, _) {});
    try {
      final StudentIdentity? identity = await ref.read(
        authStateProvider.future,
      );
      if (identity == null) return null;
      return ReviewScope(uid: identity.uid, courseId: courseId);
    } finally {
      keepAlive.close();
    }
  }
}

final AsyncNotifierProvider<ReviewSummaryController, ReviewSummary>
reviewSummaryProvider =
    AsyncNotifierProvider<ReviewSummaryController, ReviewSummary>(
      ReviewSummaryController.new,
    );

/// Las tarjetas que toca repasar ahora.
///
/// Depende solo del estudiante y del curso, **no del resumen**. Es deliberado:
/// calificar una tarjeta cambia el conteo de la pantalla principal pero no debe
/// recargar la cola a mitad del recorrido, porque las falladas ya se
/// reprogramaron para mañana y desaparecerían del camino, dejando el contador
/// «tarjeta 3 de 10» mintiendo.
///
/// Es un proveedor y no una carga en `initState` porque el estudiante y el curso
/// llegan de flujos asíncronos: una carga única en el ciclo de vida del widget
/// se dispara antes de que la sesión haya emitido y encuentra la cola vacía.
final FutureProvider<List<ReviewCard>> dueReviewCardsProvider =
    FutureProvider<List<ReviewCard>>((Ref ref) async {
      final ReviewScope? scope = ref.watch(reviewScopeProvider);
      if (scope == null) return const <ReviewCard>[];

      return ref
          .read(reviewStoreProvider)
          .dueCards(
            uid: scope.uid,
            courseId: scope.courseId,
            today: ref.read(clockProvider)(),
          );
    });
