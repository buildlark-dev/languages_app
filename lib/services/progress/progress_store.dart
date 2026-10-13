/// Contrato del almacén local de progreso.
///
/// Mismo motivo que [ReviewStore](../review/review_store.dart): la interfaz
/// depende de esto y no de `services/db/progress_dao.dart`, para que una prueba
/// de widget no tenga que abrir SQLite y para que el almacén siga siendo un
/// detalle sustituible.
///
/// No hay operación de fusión aquí. La fusión es del motor
/// (`engine/progress_merger.dart`) y de la sincronización; un almacén que
/// fusionara sería un segundo sitio donde equivocarse con la regla del
/// Principio IV.
library;

import '../../core/student_progress.dart';

abstract interface class ProgressStore {
  /// El progreso guardado, o nulo si el estudiante no ha empezado este curso.
  Future<StudentProgress?> load({
    required String uid,
    required String courseId,
  });

  /// Guarda el progreso completo.
  ///
  /// **Debe ser atómico.** Guardar niveles y actividades en escrituras separadas
  /// deja, si la app muere en medio, un estudiante con el examen aprobado y el
  /// nivel sin abrir.
  Future<void> save(StudentProgress progress);

  /// Borra todo el progreso local del estudiante en este curso (FR-046).
  Future<void> wipe({required String uid, required String courseId});
}
