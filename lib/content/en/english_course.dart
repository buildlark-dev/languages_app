/// El curso de inglés: implementación del contrato [ContentPack].
///
/// `levels` lleva **solo los niveles con contenido construido**. A2 en adelante
/// van en `upcomingLevelIds` como identificadores sueltos, no como objetos
/// `Level` vacíos: un nivel sin módulos violaría las invariantes 6 y 9 del
/// contrato de contenido, y además tener el objeto abriría la puerta a que la
/// interfaz permitiera entrar en él. Si el dato no existe, no hay ruta que
/// bloquear (FR-038).
library;

import '../../core/content_pack.dart';
import '../../core/course.dart';
import '../../core/level.dart';
import '../../core/module.dart';
import 'a1_level_exam.dart';
import 'a1_module1_identity.dart';
import 'a1_module2_home_city.dart';
import 'a1_module3_routines.dart';
import 'a1_module4_likes.dart';
import 'placement_test_en.dart';

const Level englishA1 = Level(
  id: 'A1',
  name: 'A1 · Fundamentos',
  description:
      'Presentarte, describir tu entorno inmediato y hablar de tu rutina con '
      'frases simples.',
  modules: <Module>[a1Module1, a1Module2, a1Module3, a1Module4],
  levelExam: a1LevelExam,
);

const Course englishCourse = Course(
  id: 'en',
  name: 'Inglés',
  studyLanguageTag: 'en-US',
  supportLanguageTag: 'es',
  levels: <Level>[englishA1],
  upcomingLevelIds: <String>['A2', 'B1', 'B2', 'C1', 'C2'],
  placementTest: englishPlacementTest,
);

/// Paquete de contenido de inglés.
class EnglishContentPack implements ContentPack {
  const EnglishContentPack();

  @override
  String get courseId => 'en';

  @override
  Course get course => englishCourse;
}
