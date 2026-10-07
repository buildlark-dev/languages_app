/// Hace cumplir las invariantes del contrato de contenido sobre el nivel A1.
///
/// Está escrita **antes** de que existan todos los módulos, a propósito: así los
/// que falten nacen ya vigilados. Añadir un módulo a [a1Modules] extiende la
/// cobertura sin tocar una sola aserción.
///
/// Las invariantes están en
/// `specs/001-english-a1-core/contracts/content-pack.md`.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/content/en/a1_module1_identity.dart';
import 'package:languages_app/content/en/a1_module2_home_city.dart';
import 'package:languages_app/content/en/a1_module3_routines.dart';
import 'package:languages_app/content/en/a1_module4_likes.dart';
import 'package:languages_app/content/catalog.dart';
import 'package:languages_app/content/en/english_course.dart';
import 'package:languages_app/core/course.dart';
import 'package:languages_app/core/exam.dart';
import 'package:languages_app/core/level.dart';
import 'package:languages_app/core/exercise.dart';
import 'package:languages_app/core/lesson.dart';
import 'package:languages_app/core/module.dart';
import 'package:languages_app/core/thresholds.dart';

/// Los módulos de A1 que ya existen.
///
/// Al escribir A1M2, A1M3 y A1M4 se añaden aquí y heredan todas las
/// comprobaciones.
const List<Module> a1Modules = <Module>[
  a1Module1,
  a1Module2,
  a1Module3,
  a1Module4,
];

void main() {
  test('hay módulos que comprobar', () {
    expect(a1Modules, isNotEmpty);
  });

  group('estructura', () {
    test('los identificadores de módulo son únicos', () {
      final Set<String> ids = a1Modules.map((Module m) => m.id).toSet();
      expect(ids, hasLength(a1Modules.length));
    });

    test('el orden es consecutivo desde 1, sin huecos', () {
      final List<int> orders = a1Modules.map((Module m) => m.order).toList()
        ..sort();
      for (int i = 0; i < orders.length; i++) {
        expect(orders[i], i + 1, reason: 'Hueco en el orden de los módulos');
      }
    });

    test('los identificadores de lección y de examen son únicos en el nivel',
        () {
      final List<String> all = <String>[
        for (final Module m in a1Modules) ...<String>[
          for (final Lesson l in m.lessons) l.id,
          m.moduleExam.id,
        ],
      ];
      expect(all.toSet(), hasLength(all.length));
    });
  });

  group('completitud pedagógica', () {
    for (final Module module in a1Modules) {
      test('${module.id} declara su objetivo "puedo hacer X"', () {
        expect(module.canDo.trim(), isNotEmpty);
      });

      test('${module.id} tiene al menos 8 ítems de vocabulario', () {
        expect(module.vocabulary.length, greaterThanOrEqualTo(8));
      });

      test('${module.id} no repite términos en su vocabulario', () {
        final Set<String> terms = module.vocabulary
            .map((dynamic v) => v.term as String)
            .toSet();
        expect(
          terms,
          hasLength(module.vocabulary.length),
          reason: 'El término es parte de la clave de la tarjeta de repaso',
        );
      });

      test('${module.id} tiene al menos 3 ejemplos bilingües', () {
        expect(module.examples.length, greaterThanOrEqualTo(3));
      });

      test('${module.id} tiene una lectura con texto', () {
        expect(module.reading.paragraphs, isNotEmpty);
        expect(module.reading.id.trim(), isNotEmpty);
      });

      test('${module.id} tiene al menos una lección', () {
        expect(module.lessons, isNotEmpty);
      });

      test('${module.id}: cada lección tiene al menos 5 ejercicios', () {
        for (final Lesson lesson in module.lessons) {
          expect(
            lesson.exercises.length,
            greaterThanOrEqualTo(5),
            reason:
                '${lesson.id}: con menos de 5, el umbral del 70 % no es '
                'alcanzable de forma exacta',
          );
        }
      });

      test('${module.id}: el examen tiene al menos 10 ejercicios', () {
        expect(module.moduleExam.exercises.length, greaterThanOrEqualTo(10));
        expect(module.moduleExam.scope, ExamScope.module);
        expect(module.moduleExam.passThreshold, examPassThreshold);
      });

      test('${module.id}: toda referencia de lectura apunta a su pasaje', () {
        for (final Lesson lesson in module.lessons) {
          final String? ref = lesson.readingRef;
          if (ref == null) continue;
          expect(
            ref,
            module.reading.id,
            reason: '${lesson.id} apunta a un pasaje que no existe',
          );
        }
      });
    }
  });

  group('cuatro destrezas', () {
    for (final Module module in a1Modules) {
      test('${module.id} ejercita la escucha', () {
        expect(
          module.hasListening,
          isTrue,
          reason: 'Invariante 10: todo módulo necesita comprensión auditiva',
        );
      });

      test('${module.id} ejercita el habla', () {
        expect(
          module.hasPronunciation,
          isTrue,
          reason: 'Invariante 11: todo módulo necesita pronunciación',
        );
      });

      test('${module.id} ejercita la producción escrita', () {
        expect(
          module.hasWrittenProduction,
          isTrue,
          reason: 'Invariante 12: construir frases o rellenar huecos',
        );
      });
    }
  });

  group('retroalimentación y accesibilidad', () {
    /// Todos los ejercicios del nivel, de lecciones y de exámenes.
    Iterable<(String, Exercise)> allExercises() sync* {
      for (final Module module in a1Modules) {
        for (final Lesson lesson in module.lessons) {
          for (final Exercise e in lesson.exercises) {
            yield (lesson.id, e);
          }
        }
        for (final Exercise e in module.moduleExam.exercises) {
          yield (module.moduleExam.id, e);
        }
      }
    }

    test('todo ejercicio explica POR QUÉ, no solo cuál era la respuesta', () {
      for (final (String owner, Exercise e) in allExercises()) {
        expect(e.explanation.trim(), isNotEmpty, reason: 'en $owner');
        // Comprobación aproximada de la invariante 14: una explicación de tres
        // palabras no explica un motivo. La calidad la juzga la revisión humana.
        expect(
          e.explanation.trim().length,
          greaterThan(20),
          reason: 'Explicación demasiado corta en $owner: «${e.explanation}»',
        );
      }
    });

    test('todo ejercicio oral declara su alternativa accesible', () {
      // El compilador ya lo garantiza, porque es un parámetro `required`. Esta
      // prueba es la red de seguridad ante un cambio futuro del tipo, y
      // comprueba además que no esté vacía.
      for (final (String owner, Exercise e) in allExercises()) {
        if (e is! OralExercise) continue;
        expect(
          e.accessibleAlternative.trim(),
          isNotEmpty,
          reason: 'SC-008 exige poder aprobar sin micrófono. En $owner',
        );
      }
    });

    test('las opciones múltiples tienen al menos 3 y un índice válido', () {
      for (final (String owner, Exercise e) in allExercises()) {
        switch (e) {
          case MultipleChoiceExercise(:final List<String> options, :final int answerIndex):
            expect(options.length, greaterThanOrEqualTo(3), reason: 'en $owner');
            expect(answerIndex, inInclusiveRange(0, options.length - 1),
                reason: 'en $owner');
          case ListeningExercise(:final List<String> options, :final int answerIndex):
            expect(options.length, greaterThanOrEqualTo(3), reason: 'en $owner');
            expect(answerIndex, inInclusiveRange(0, options.length - 1),
                reason: 'en $owner');
          case GapFillExercise(:final List<String> acceptedAnswers):
            expect(acceptedAnswers, isNotEmpty, reason: 'en $owner');
          case SentenceBuilderExercise(:final List<String> tokens):
            expect(tokens.length, greaterThanOrEqualTo(2), reason: 'en $owner');
          case PronunciationExercise(:final String targetPhrase):
            expect(targetPhrase.trim(), isNotEmpty, reason: 'en $owner');
        }
      }
    });

    test('las respuestas aceptadas se declaran normalizadas', () {
      for (final (String owner, Exercise e) in allExercises()) {
        if (e is! GapFillExercise) continue;
        for (final String answer in e.acceptedAnswers) {
          expect(
            answer,
            answer.trim(),
            reason: 'Invariante 18: sin espacios al borde. En $owner',
          );
          expect(
            answer,
            answer.toLowerCase(),
            reason: 'Invariante 18: en minúsculas. En $owner',
          );
        }
      }
    });

    test('las fichas de construir frases bastan para montar la objetivo', () {
      for (final (String owner, Exercise e) in allExercises()) {
        if (e is! SentenceBuilderExercise) continue;
        final List<String> sorted = <String>[...e.tokens]..sort();
        final List<String> expected = e.targetSentence.split(' ')..sort();
        expect(
          sorted,
          expected,
          reason:
              'Las fichas deben ser exactamente las palabras de la frase. '
              'En $owner',
        );
      }
    });
  });

  group('curso y catálogo', () {
    const Course course = englishCourse;

    test('solo declara niveles que tienen contenido', () {
      expect(course.levels, hasLength(1));
      expect(course.levels.single.id, 'A1');
      expect(course.levels.single.modules, hasLength(4));
    });

    test('los identificadores de nivel pertenecen al conjunto MCER', () {
      for (final Level level in course.levels) {
        expect(cefrLevelIds, contains(level.id));
      }
      for (final String id in course.upcomingLevelIds) {
        expect(cefrLevelIds, contains(id));
      }
    });

    test('los niveles anunciados van después de los que tienen contenido', () {
      final int lastWithContent = cefrLevelIds.indexOf(
        course.levels.last.id,
      );
      for (final String id in course.upcomingLevelIds) {
        expect(
          cefrLevelIds.indexOf(id),
          greaterThan(lastWithContent),
          reason: 'Un nivel anunciado no puede ser anterior al último con '
              'contenido',
        );
      }
    });

    test('ningún nivel anunciado existe también como nivel con contenido', () {
      final Set<String> withContent = course.levels
          .map((Level l) => l.id)
          .toSet();
      for (final String id in course.upcomingLevelIds) {
        expect(
          withContent,
          isNot(contains(id)),
          reason: 'Invariante 21: sin intersección entre ambas listas',
        );
      }
    });

    test('el nivel tiene examen de nivel con al menos 10 ejercicios', () {
      final Exam exam = course.levels.single.levelExam;
      expect(exam.scope, ExamScope.level);
      expect(exam.exercises.length, greaterThanOrEqualTo(10));
      expect(exam.passThreshold, examPassThreshold);
    });

    test('el examen de nivel es aprobable sin micrófono', () {
      // La invariante 22 permite ejercicios orales en exámenes, pero el que
      // decide el paso de nivel no debe poner en desventaja a quien no tiene
      // micrófono. La escucha sí entra: su alternativa es la transcripción.
      final Iterable<Exercise> oral = course.levels.single.levelExam.exercises
          .whereType<PronunciationExercise>();
      expect(
        oral,
        isEmpty,
        reason: 'Sin ejercicios de pronunciación en el examen de nivel',
      );
    });

    test('la nivelación puede estimar niveles sin contenido', () {
      final PlacementExam? placement = course.placementTest;
      expect(placement, isNotNull);
      // Es el punto de FR-035: estimar el nivel real, no el alcanzable.
      expect(
        placement!.coveredLevelIds,
        containsAll(<String>['A1', 'A2', 'B1']),
      );
      for (final String id in placement.coveredLevelIds) {
        expect(cefrLevelIds, contains(id));
      }
    });

    test('todo ítem de nivelación explica su respuesta', () {
      for (final PlacementItem item in course.placementTest!.items) {
        expect(item.exercise.explanation.trim(), isNotEmpty);
      }
    });

    test('el catálogo expone el curso y lo encuentra por su código', () {
      const AppCourseCatalog catalog = AppCourseCatalog();
      expect(catalog.packs, hasLength(1));
      expect(catalog.packFor('en')?.course.id, 'en');
      expect(catalog.packFor('fr'), isNull);
    });

    test('los módulos del nivel coinciden con los que se comprueban', () {
      expect(
        course.levels.single.modules.map((Module m) => m.id),
        a1Modules.map((Module m) => m.id),
        reason: 'Un módulo nuevo debe añadirse a a1Modules para quedar vigilado',
      );
    });
  });
}
