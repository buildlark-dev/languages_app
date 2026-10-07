/// Acceso al contenido **a través del contrato**.
///
/// `lib/ui/` no importa `lib/content/` en ningún punto: recibe el catálogo por
/// este proveedor, cuyo valor concreto inyecta `lib/main.dart`. Esa es la costura
/// del Principio I, y la prueba de arquitectura la verifica inspeccionando los
/// `import`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/content_pack.dart';
import '../../core/course.dart';

/// El catálogo de idiomas. **Se sobrescribe en `main.dart`.**
///
/// Lanzar en lugar de devolver un catálogo vacío es deliberado: un olvido de
/// cableado debe fallar de inmediato y con un mensaje claro, no producir una app
/// que arranca sin idiomas y parece estar bien.
final Provider<CourseCatalog> courseCatalogProvider = Provider<CourseCatalog>(
  (Ref ref) => throw UnimplementedError(
    'courseCatalogProvider debe sobrescribirse en main.dart con el catálogo '
    'concreto. La interfaz no puede importar lib/content/ (Principio I).',
  ),
);

/// Código del curso que el estudiante tiene abierto.
///
/// Es un [Notifier] y no el `StateProvider` de versiones anteriores de Riverpod,
/// que desapareció en la 3.
class SelectedCourse extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String courseId) => state = courseId;

  void clear() => state = null;
}

final NotifierProvider<SelectedCourse, String?> selectedCourseIdProvider =
    NotifierProvider<SelectedCourse, String?>(SelectedCourse.new);

/// El curso activo, o nulo si todavía no se eligió.
final Provider<Course?> activeCourseProvider = Provider<Course?>((Ref ref) {
  final String? courseId = ref.watch(selectedCourseIdProvider);
  if (courseId == null) return null;
  return ref.watch(courseCatalogProvider).packFor(courseId)?.course;
});
