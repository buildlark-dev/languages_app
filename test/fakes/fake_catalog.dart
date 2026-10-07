/// Catálogo de prueba construido **solo con contratos de `core`**.
///
/// Que se pueda armar un curso completo sin importar nada de `lib/content/` es la
/// demostración práctica del Principio I: la interfaz no conoce ningún idioma
/// concreto, solo el contrato.
library;

import 'package:languages_app/core/content_pack.dart';
import 'package:languages_app/core/course.dart';
import 'package:languages_app/core/exam.dart';
import 'package:languages_app/core/exercise.dart';
import 'package:languages_app/core/lesson.dart';
import 'package:languages_app/core/level.dart';
import 'package:languages_app/core/module.dart';
import 'package:languages_app/core/teaching_material.dart';
import 'package:languages_app/core/vocabulary_item.dart';

const Course fakeCourse = Course(
  id: 'xx',
  name: 'Idioma de prueba',
  studyLanguageTag: 'xx-XX',
  supportLanguageTag: 'es',
  levels: <Level>[
    Level(
      id: 'A1',
      name: 'A1 · Prueba',
      description: 'Nivel de prueba.',
      modules: <Module>[
        Module(
          id: 'XXM1',
          order: 1,
          title: 'Módulo de prueba',
          canDo: 'Hacer algo de prueba.',
          vocabulary: <VocabularyItem>[
            VocabularyItem(term: 'one', translation: 'uno'),
          ],
          grammar: GrammarExplanation(
            title: 'Prueba',
            bodyHtml: '<p>Prueba</p>',
          ),
          examples: <BilingualExample>[
            BilingualExample(target: 'One.', spanish: 'Uno.'),
          ],
          reading: ReadingPassage(
            id: 'XXM1R',
            title: 'Prueba',
            paragraphs: <String>['Texto de prueba.'],
          ),
          lessons: <Lesson>[
            Lesson(
              id: 'XXM1L1',
              title: 'Lección de prueba',
              exercises: <Exercise>[
                MultipleChoiceExercise(
                  prompt: '¿Uno?',
                  options: <String>['a', 'b', 'c'],
                  answerIndex: 0,
                  explanation: 'Explicación de prueba suficientemente larga.',
                ),
              ],
            ),
          ],
          moduleExam: Exam(
            id: 'XXM1EX',
            scope: ExamScope.module,
            exercises: <Exercise>[],
          ),
        ),
      ],
      levelExam: Exam(
        id: 'XXEX',
        scope: ExamScope.level,
        exercises: <Exercise>[],
      ),
    ),
  ],
  upcomingLevelIds: <String>['A2', 'B1'],
);

class FakePack implements ContentPack {
  const FakePack();

  @override
  String get courseId => 'xx';

  @override
  Course get course => fakeCourse;
}

class FakeCatalog implements CourseCatalog {
  const FakeCatalog();

  @override
  List<ContentPack> get packs => const <ContentPack>[FakePack()];

  @override
  ContentPack? packFor(String courseId) =>
      courseId == 'xx' ? const FakePack() : null;
}
