/// La navegación del curso: mapa → módulos → módulo → lección o examen.
///
/// Esta es la capa que faltaba, y está aparte de las pantallas a propósito. Las
/// pantallas reciben datos por parámetro y avisan por callback; **ninguna sabe
/// de dónde viene el progreso ni a dónde va el resultado**. Eso es lo que
/// permite probarlas montando solo un `MaterialApp`, sin proveedores ni base de
/// datos, y es la razón de que las pruebas de progresión no necesiten un
/// `ProviderScope`.
///
/// Aquí viven las cuatro rutas que unen todo, cada una con la misma forma:
/// observar el progreso, pintar la pantalla, y al volver guardar lo que haya
/// pasado. `Navigator` sin rutas con nombre, según D8 de research.md: un árbol
/// de cuatro niveles no justifica un enrutador, y los enlaces profundos no
/// forman parte de esta entrega.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/activity_score.dart';
import '../core/course.dart';
import '../core/exam.dart';
import '../core/lesson.dart';
import '../core/level.dart';
import '../core/module.dart';
import '../core/student_progress.dart';
import '../engine/progression.dart';
import '../engine/scoring.dart';
import '../ui/providers/content_providers.dart';
import '../ui/providers/progress_controller.dart';
import '../core/placement_result.dart';
import '../ui/providers/clock_providers.dart';
import '../ui/screens/exam_screen.dart';
import '../ui/screens/lesson_screen.dart';
import '../ui/screens/level_map_screen.dart';
import '../ui/screens/module_detail_screen.dart';
import '../ui/screens/module_screen.dart';
import '../ui/screens/placement_screen.dart';
import '../ui/screens/review_screen.dart';
import '../ui/widgets/placement_offer_card.dart';

/// Base de las rutas del curso: resuelve curso y progreso, o espera.
///
/// Las cuatro rutas necesitan exactamente lo mismo antes de poder pintar nada, y
/// repetir la comprobación en cada una era repetir la ocasión de olvidarla en
/// una.
abstract class _CourseRoute extends ConsumerWidget {
  const _CourseRoute({super.key});

  Widget buildWithCourse(
    BuildContext context,
    WidgetRef ref,
    Course course,
    StudentProgress progress,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Course? course = ref.watch(activeCourseProvider);
    final StudentProgress? progress = ref.watch(studentProgressProvider).value;

    if (course == null || progress == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return buildWithCourse(context, ref, course, progress);
  }
}

/// Mapa de niveles del curso abierto.
class CourseMapRoute extends _CourseRoute {
  const CourseMapRoute({super.key});

  @override
  Widget buildWithCourse(
    BuildContext context,
    WidgetRef ref,
    Course course,
    StudentProgress progress,
  ) => LevelMapScreen(
    course: course,
    progress: progress,
    onOpenLevel: (Level level) => _push(context, LevelRoute(level: level)),
    // Cuando no queda contenido nuevo, lo útil es repasar (FR-038).
    onReviewMastered: () => _push(context, const ReviewScreen()),
    // La nivelación se ofrece aquí, que es lo primero que se ve al elegir el
    // idioma (FR-034). Estaba en la pantalla de inicio, detrás del catálogo, y
    // como elegir idioma entra directo al curso, quien llegaba por primera vez
    // no la veía nunca a menos que retrocediera. La tarjeta decide sola si
    // aparecer, y deja de hacerlo en cuanto hay actividad registrada.
    header: PlacementOfferCard(
      onOpenPlacement: () => _push(context, PlacementRoute(course: course)),
    ),
  );
}

/// Módulos de un nivel, con su examen de nivel al final.
class LevelRoute extends _CourseRoute {
  const LevelRoute({required this.level, super.key});

  final Level level;

  @override
  Widget buildWithCourse(
    BuildContext context,
    WidgetRef ref,
    Course course,
    StudentProgress progress,
  ) => ModuleScreen(
    course: course,
    // Se vuelve a buscar el nivel en el curso en lugar de usar el que llegó por
    // parámetro: el objeto es el mismo, pero así la pantalla no puede mostrar
    // un nivel que ya no esté en el catálogo tras una recarga.
    level: course.levelById(level.id) ?? level,
    progress: progress,
    onOpenModule: (Module module) =>
        _push(context, ModuleRoute(module: module)),
    onOpenLevelExam: (Exam exam) => _push(
      context,
      ExamRoute(
        exam: exam,
        kind: ActivityKind.levelExam,
        title: 'Examen de ${level.id}',
      ),
    ),
  );
}

/// Lecciones y examen de un módulo.
class ModuleRoute extends _CourseRoute {
  const ModuleRoute({required this.module, super.key});

  final Module module;

  @override
  Widget buildWithCourse(
    BuildContext context,
    WidgetRef ref,
    Course course,
    StudentProgress progress,
  ) => ModuleDetailScreen(
    module: module,
    progress: progress,
    onOpenLesson: (Lesson lesson) =>
        _push(context, LessonRoute(module: module, lesson: lesson)),
    onOpenModuleExam: (Exam exam) => _push(
      context,
      ExamRoute(
        exam: exam,
        kind: ActivityKind.moduleExam,
        title: 'Examen de ${module.title}',
      ),
    ),
  );
}

/// Una lección, y el registro de su resultado.
class LessonRoute extends ConsumerWidget {
  const LessonRoute({required this.module, required this.lesson, super.key});

  final Module module;
  final Lesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) => LessonScreen(
    module: module,
    lesson: lesson,
    // El identificador de la actividad es el de la lección: así reintentar la
    // misma lección actualiza su mejor nota en lugar de crear otra entrada.
    onCompleted: (Lesson done, ScoreResult result) => ref
        .read(studentProgressProvider.notifier)
        .recordResult(
          activityId: done.id,
          kind: ActivityKind.lesson,
          result: result,
        ),
  );
}

/// Un examen de módulo o de nivel, y el registro de su resultado.
class ExamRoute extends ConsumerWidget {
  const ExamRoute({
    required this.exam,
    required this.kind,
    required this.title,
    super.key,
  });

  final Exam exam;
  final ActivityKind kind;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ExamScreen(
    exam: exam,
    kind: kind,
    title: title,
    onCompleted: (Exam done, ScoreResult result) => ref
        .read(studentProgressProvider.notifier)
        .recordResult(activityId: done.id, kind: kind, result: result),
  );
}

/// La clase de actividad de un examen, por si hiciera falta derivarla.
///
/// Se expone porque `examKindFor` vive en el motor y esta capa es la única que
/// construye [ExamRoute]: tener aquí el puente evita que una pantalla tenga que
/// importar `progression` solo para saber qué umbral aplicar.
ActivityKind examKindOf({required Course course, required String examId}) =>
    examKindFor(course: course, examId: examId);

void _push(BuildContext context, Widget screen) => Navigator.of(
  context,
).push(MaterialPageRoute<void>(builder: (BuildContext context) => screen));

/// La prueba de nivelación, y el registro de su resultado.
///
/// El resultado se aplica aquí y no dentro de la pantalla porque la pantalla no
/// debería conocer el almacén: recibe el curso y devuelve un
/// [PlacementResult], igual que la lección devuelve un `ScoreResult`.
class PlacementRoute extends ConsumerWidget {
  const PlacementRoute({required this.course, super.key});

  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PlacementScreen(
    course: course,
    now: ref.read(clockProvider)(),
    onFinished: (PlacementResult result) =>
        ref.read(studentProgressProvider.notifier).applyPlacementResult(result),
  );
}
