/// Estado de la cola de repaso.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/module.dart';
import '../../core/review_card.dart';
import '../../services/review/review_store.dart';
import 'clock_providers.dart';
import 'scope_providers.dart';

/// El almacén concreto. **Se sobrescribe en `main.dart`.**
final Provider<ReviewStore> reviewStoreProvider = Provider<ReviewStore>(
  (Ref ref) => throw UnimplementedError(
    'reviewStoreProvider debe sobrescribirse en main.dart',
  ),
);

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
    final StudentScope? scope = await watchStudentScope(ref);
    if (scope == null) return ReviewSummary.empty;
    return _read(scope);
  }

  Future<ReviewSummary> _read(StudentScope scope) async {
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
    (StudentScope scope, ReviewStore store) => store.seedModule(
      uid: scope.uid,
      courseId: scope.courseId,
      moduleId: module.id,
      vocabulary: module.vocabulary,
      today: ref.read(clockProvider)(),
    ),
  );

  /// Guarda una tarjeta ya reprogramada por el planificador.
  Future<void> saveGraded(ReviewCard card) => _write(
    (StudentScope scope, ReviewStore store) =>
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
    Future<void> Function(StudentScope scope, ReviewStore store) operation,
  ) async {
    final StudentScope? scope = await resolveStudentScope(ref);
    if (scope == null) return;

    state = await AsyncValue.guard<ReviewSummary>(() async {
      await operation(scope, ref.read(reviewStoreProvider));
      return _read(scope);
    });
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
      final StudentScope? scope = await watchStudentScope(ref);
      if (scope == null) return const <ReviewCard>[];

      return ref
          .read(reviewStoreProvider)
          .dueCards(
            uid: scope.uid,
            courseId: scope.courseId,
            today: ref.read(clockProvider)(),
          );
    });
