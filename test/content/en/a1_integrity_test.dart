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
import 'package:languages_app/core/vocabulary_item.dart';
import 'package:languages_app/core/placement_result.dart';
import 'package:languages_app/engine/answer_check.dart';
import 'package:languages_app/engine/placement_evaluator.dart';
import 'package:languages_app/ui/widgets/simple_html_text.dart';

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

    test(
      'los identificadores de lección y de examen son únicos en el nivel',
      () {
        final List<String> all = <String>[
          for (final Module m in a1Modules) ...<String>[
            for (final Lesson l in m.lessons) l.id,
            m.moduleExam.id,
          ],
        ];
        expect(all.toSet(), hasLength(all.length));
      },
    );
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
          case MultipleChoiceExercise(
            :final List<String> options,
            :final int answerIndex,
          ):
            expect(
              options.length,
              greaterThanOrEqualTo(3),
              reason: 'en $owner',
            );
            expect(
              answerIndex,
              inInclusiveRange(0, options.length - 1),
              reason: 'en $owner',
            );
          case ListeningExercise(
            :final List<String> options,
            :final int answerIndex,
          ):
            expect(
              options.length,
              greaterThanOrEqualTo(3),
              reason: 'en $owner',
            );
            expect(
              answerIndex,
              inInclusiveRange(0, options.length - 1),
              reason: 'en $owner',
            );
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

  group('HTML del contenido acotado al que sabemos renderizar', () {
    /// Todas las cadenas con marcado que el contenido declara.
    Iterable<(String, String)> markupStrings() sync* {
      for (final Module module in a1Modules) {
        yield ('${module.id}.grammar.title', module.grammar.title);
        yield ('${module.id}.grammar.body', module.grammar.bodyHtml);
        for (final Lesson lesson in module.lessons) {
          for (final Exercise e in lesson.exercises) {
            yield ('${lesson.id}.explanation', e.explanation);
          }
        }
        for (final Exercise e in module.moduleExam.exercises) {
          yield ('${module.moduleExam.id}.explanation', e.explanation);
        }
      }
    }

    test('no aparece ninguna etiqueta sin soporte', () {
      // El renderizador es pequeño a propósito y soporta nueve etiquetas. Esta
      // prueba es lo que mantiene esa decisión viable: si alguien escribe <ul>
      // en una explicación, falla aquí en lugar de desaparecer en pantalla.
      final RegExp tagPattern = RegExp(r'</?([a-zA-Z][a-zA-Z0-9]*)[^>]*>');
      final List<String> violations = <String>[];

      for (final (String owner, String text) in markupStrings()) {
        for (final RegExpMatch match in tagPattern.allMatches(text)) {
          final String tag = match.group(1)!.toLowerCase();
          if (!supportedHtmlTags.contains(tag)) {
            violations.add('$owner usa <$tag>');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Etiquetas sin soporte en simple_html_text.dart:\n  '
            '${violations.join('\n  ')}',
      );
    });

    test('las etiquetas en línea están balanceadas', () {
      // Una etiqueta sin cerrar deja el resto del texto con el estilo pegado,
      // que en el caso de <s> convertiría una explicación entera en texto
      // tachado.
      final RegExp inline = RegExp(r'</?(b|i|code|s)>');
      final List<String> violations = <String>[];

      for (final (String owner, String text) in markupStrings()) {
        final List<String> stack = <String>[];
        for (final RegExpMatch match in inline.allMatches(text)) {
          final String tag = match.group(1)!;
          if (match.group(0)!.startsWith('</')) {
            if (stack.isEmpty || !stack.contains(tag)) {
              violations.add('$owner cierra <$tag> sin abrirlo');
            } else {
              stack.remove(tag);
            }
          } else {
            stack.add(tag);
          }
        }
        if (stack.isNotEmpty) {
          violations.add('$owner deja sin cerrar: ${stack.join(", ")}');
        }
      }

      expect(violations, isEmpty, reason: violations.join('\n  '));
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
      final int lastWithContent = cefrLevelIds.indexOf(course.levels.last.id);
      for (final String id in course.upcomingLevelIds) {
        expect(
          cefrLevelIds.indexOf(id),
          greaterThan(lastWithContent),
          reason:
              'Un nivel anunciado no puede ser anterior al último con '
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

    test('ninguna traducción arrastra el artículo', () {
      // El lado español es apoyo para traducir, no una lección de género: el
      // artículo no aporta nada a quien ya habla español, y venía puesto en 26
      // de 48 entradas y ausente en el resto. En el repaso esa inconsistencia
      // se nota, porque la tarjeta pregunta «¿cómo se dice "nombre"?» y antes
      // preguntaba «¿cómo se dice "el nombre"?» según la palabra.
      final RegExp leadingArticle = RegExp(
        r'^(el|la|los|las|un|una|el/la|la/el|un/una|una/un)[ /]',
        caseSensitive: false,
      );

      for (final Module module in a1Modules) {
        for (final VocabularyItem item in module.vocabulary) {
          expect(
            leadingArticle.hasMatch(item.translation),
            isFalse,
            reason:
                '«${item.term}» se traduce como «${item.translation}», con '
                'artículo delante',
          );
        }
      }
    });

    test('todo ítem de nivelación explica su respuesta', () {
      for (final PlacementItem item in course.placementTest!.items) {
        expect(item.exercise.explanation.trim(), isNotEmpty);
      }
    });

    test('cada nivel de la nivelación tiene al menos dos ítems', () {
      // Con un solo ítem, el umbral del 80 % se decidiría a cara o cruz, y lo
      // que se juega es saltarse un nivel entero de contenido.
      final Map<String, int> perLevel = <String, int>{};
      for (final PlacementItem item in course.placementTest!.items) {
        perLevel[item.levelId] = (perLevel[item.levelId] ?? 0) + 1;
      }
      for (final MapEntry<String, int> entry in perLevel.entries) {
        expect(
          entry.value,
          greaterThanOrEqualTo(2),
          reason: 'El nivel ${entry.key} se decide con ${entry.value} ítem(s)',
        );
      }
    });

    test('acertar la nivelación real estima por encima del contenido', () {
      // La comprobación extremo a extremo sobre el contenido de verdad: es el
      // caso de FR-036 y el único que el catálogo de hoy puede producir.
      final PlacementExam exam = course.placementTest!;
      final PlacementResult result = evaluatePlacement(
        course: course,
        exam: exam,
        answers: List<bool>.filled(exam.items.length, true),
        takenAt: DateTime(2026, 10, 7),
      );

      expect(result.estimatedLevelId, 'C1', reason: 'el techo que mide');
      expect(result.masteredLevelIds, <String>['A1']);
      expect(
        assignedLevelFor(
          course: course,
          estimatedLevelId: result.estimatedLevelId,
        ),
        'A1',
      );
    });

    test('fallar la nivelación real deja a la persona en A1', () {
      final PlacementExam exam = course.placementTest!;
      final PlacementResult result = evaluatePlacement(
        course: course,
        exam: exam,
        answers: List<bool>.filled(exam.items.length, false),
        takenAt: DateTime(2026, 10, 7),
      );

      expect(result.estimatedLevelId, 'A1');
      expect(result.masteredLevelIds, isEmpty);
    });

    test('la respuesta correcta de cada ítem es la que el motor acepta', () {
      // Verifica el cableado real: si un `answerIndex` apuntara a la opción
      // equivocada, la nivelación mandaría a A1 a quien contesta bien, y
      // ninguna otra prueba lo notaría.
      for (final PlacementItem item in course.placementTest!.items) {
        final Exercise exercise = item.exercise;
        expect(
          exercise,
          isA<MultipleChoiceExercise>(),
          reason: 'La nivelación usa opción múltiple',
        );
        final int answerIndex =
            (exercise as MultipleChoiceExercise).answerIndex;
        expect(
          isAnswerCorrect(exercise, AnswerDraft(choice: answerIndex)),
          isTrue,
        );
        expect(
          isAnswerCorrect(
            exercise,
            AnswerDraft(choice: (answerIndex + 1) % exercise.options.length),
          ),
          isFalse,
        );
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
        reason:
            'Un módulo nuevo debe añadirse a a1Modules para quedar vigilado',
      );
    });
  });
}
