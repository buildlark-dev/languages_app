/// Fija la semántica de la nivelación: estimado, asignado y dominados.
///
/// La prueba que más importa es la del estimado por encima del contenido
/// disponible: es el caso que FR-035 y FR-036 describen y el que el catálogo de
/// hoy produce siempre, porque solo A1 tiene contenido.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/course.dart';
import 'package:languages_app/core/exam.dart';
import 'package:languages_app/core/exercise.dart';
import 'package:languages_app/core/lesson.dart';
import 'package:languages_app/core/level.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/module.dart';
import 'package:languages_app/core/placement_result.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/core/teaching_material.dart';
import 'package:languages_app/core/vocabulary_item.dart';
import 'package:languages_app/engine/placement_evaluator.dart';

void main() {
  final DateTime takenAt = DateTime(2026, 10, 7);

  /// Prueba de cinco niveles, dos ítems cada uno: A1, A2, B1, B2, C1.
  ///
  /// Imita la forma real de `placement_test_en.dart`, incluidos los niveles sin
  /// contenido construido, sin depender de su contenido concreto.
  const PlacementExam exam = PlacementExam(
    id: 'TESTPLACE',
    items: <PlacementItem>[
      PlacementItem(levelId: 'A1', exercise: _item),
      PlacementItem(levelId: 'A1', exercise: _item),
      PlacementItem(levelId: 'A2', exercise: _item),
      PlacementItem(levelId: 'A2', exercise: _item),
      PlacementItem(levelId: 'B1', exercise: _item),
      PlacementItem(levelId: 'B1', exercise: _item),
      PlacementItem(levelId: 'B2', exercise: _item),
      PlacementItem(levelId: 'B2', exercise: _item),
      PlacementItem(levelId: 'C1', exercise: _item),
      PlacementItem(levelId: 'C1', exercise: _item),
    ],
  );

  /// Respuestas: `levels` dice cuántos niveles se aciertan completos desde abajo.
  List<bool> acingUpTo(int levels) => <bool>[
    for (int i = 0; i < 10; i++) i < levels * 2,
  ];

  /// Curso con contenido solo en A1, como el de hoy.
  final Course oneLevelCourse = _courseWith(<String>['A1']);

  /// Curso con contenido hasta B1, como el de dentro de unos meses.
  final Course threeLevelCourse = _courseWith(<String>['A1', 'A2', 'B1']);

  group('nota por nivel', () {
    test('cada nivel se puntúa con sus propios ítems', () {
      final Map<String, double> scores = placementLevelScores(
        exam: exam,
        // A1 completo, A2 a medias, el resto mal.
        answers: <bool>[
          true,
          true,
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      );

      expect(scores['A1'], 1.0);
      expect(scores['A2'], 0.5);
      expect(scores['B1'], 0.0);
    });

    test('un nivel que la prueba no cubre no aparece, ni con cero', () {
      // Cero significaría «lo falló», y eso no lo afirmó nadie.
      final Map<String, double> scores = placementLevelScores(
        exam: exam,
        answers: acingUpTo(5),
      );

      expect(scores.containsKey('C2'), isFalse);
      expect(scores.keys, hasLength(5));
    });
  });

  group('niveles demostrados', () {
    test('la racha debe ser contigua desde el más bajo', () {
      // Falla A2 y acierta B1: acertó una pregunta, no está en B1.
      final List<String> demonstrated = demonstratedLevelIds(
        exam: exam,
        answers: <bool>[
          true,
          true,
          false,
          false,
          true,
          true,
          false,
          false,
          false,
          false,
        ],
      );

      expect(demonstrated, <String>['A1']);
    });

    test('acertar uno de dos no basta para demostrar el nivel', () {
      // El umbral es el del examen de nivel: con dos ítems significa los dos.
      final List<String> demonstrated = demonstratedLevelIds(
        exam: exam,
        answers: <bool>[
          true,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
          false,
        ],
      );

      expect(demonstrated, isEmpty);
    });

    test('fallarlo todo no demuestra nada', () {
      expect(demonstratedLevelIds(exam: exam, answers: acingUpTo(0)), isEmpty);
    });
  });

  group('nivel estimado', () {
    test('es el primero que no se demostró', () {
      // Demuestra A1 y A2: debería empezar por B1.
      expect(estimatedLevelFor(exam: exam, answers: acingUpTo(2)), 'B1');
    });

    test('fallarlo todo estima el nivel más bajo, no menos', () {
      // No existe nada por debajo de A1.
      expect(estimatedLevelFor(exam: exam, answers: acingUpTo(0)), 'A1');
    });

    test('acertarlo todo estima el nivel más alto que la prueba mide', () {
      // La prueba llega a C1. Afirmar C2 sería afirmar algo no medido.
      expect(estimatedLevelFor(exam: exam, answers: acingUpTo(5)), 'C1');
    });

    test('puede ser cualquier nivel MCER, también los sin contenido', () {
      // Esta es la mitad de FR-035: el estimado no se recorta por catálogo.
      expect(estimatedLevelFor(exam: exam, answers: acingUpTo(1)), 'A2');
      expect(estimatedLevelFor(exam: exam, answers: acingUpTo(3)), 'B2');
      expect(estimatedLevelFor(exam: exam, answers: acingUpTo(4)), 'C1');
    });
  });

  group('nivel asignado', () {
    test(
      'se limita al nivel con contenido más alto que no supere al estimado',
      () {
        expect(
          assignedLevelFor(course: oneLevelCourse, estimatedLevelId: 'B1'),
          'A1',
        );
        expect(
          assignedLevelFor(course: threeLevelCourse, estimatedLevelId: 'B1'),
          'B1',
        );
        expect(
          assignedLevelFor(course: threeLevelCourse, estimatedLevelId: 'C1'),
          'B1',
        );
      },
    );

    test('no sube por encima del estimado aunque haya contenido', () {
      expect(
        assignedLevelFor(course: threeLevelCourse, estimatedLevelId: 'A2'),
        'A2',
      );
      expect(
        assignedLevelFor(course: threeLevelCourse, estimatedLevelId: 'A1'),
        'A1',
      );
    });

    test('se deriva del catálogo, así que publicar un nivel lo sube solo', () {
      // El mismo resultado almacenado, dos catálogos: el asignado cambia sin
      // migración y sin volver a examinar a nadie. Es el motivo de no
      // almacenarlo.
      const String estimated = 'B1';

      expect(
        assignedLevelFor(course: oneLevelCourse, estimatedLevelId: estimated),
        'A1',
      );
      expect(
        assignedLevelFor(course: threeLevelCourse, estimatedLevelId: estimated),
        'B1',
      );
    });
  });

  group('niveles dominados', () {
    test('solo se marcan los demostrados que existen en el catálogo', () {
      // Demuestra A1 y A2, pero solo A1 tiene contenido.
      expect(
        masteredLevelIdsFor(
          course: oneLevelCourse,
          exam: exam,
          answers: acingUpTo(2),
        ),
        <String>['A1'],
      );
      expect(
        masteredLevelIdsFor(
          course: threeLevelCourse,
          exam: exam,
          answers: acingUpTo(2),
        ),
        <String>['A1', 'A2'],
      );
    });

    test('quien no demuestra nada no domina nada', () {
      expect(
        masteredLevelIdsFor(
          course: threeLevelCourse,
          exam: exam,
          answers: acingUpTo(0),
        ),
        isEmpty,
      );
    });

    test('el nivel asignado no se marca como dominado', () {
      // Demuestra A1, empieza en A2: A2 es donde estudia, no algo que domine.
      final PlacementResult result = evaluatePlacement(
        course: threeLevelCourse,
        exam: exam,
        answers: acingUpTo(1),

        takenAt: takenAt,
      );

      expect(result.estimatedLevelId, 'A2');
      expect(result.masteredLevelIds, <String>['A1']);
      expect(
        assignedLevelFor(
          course: threeLevelCourse,
          estimatedLevelId: result.estimatedLevelId,
        ),
        'A2',
      );
    });
  });

  group('aplicar al progreso', () {
    StudentProgress fresh() => const StudentProgress(
      uid: 'u1',
      courseId: 'xx',
      currentLevelId: 'A1',
      levelStates: <String, LevelState>{'A1': LevelState.unlocked},
    );

    test('los dominados quedan mastered, no passed', () {
      // La persona no presentó el examen de nivel. Mezclar los dos estados
      // borraría la diferencia entre demostrar en una prueba corta y superar el
      // nivel entero.
      final StudentProgress after = applyPlacement(
        progress: fresh(),
        course: threeLevelCourse,
        result: evaluatePlacement(
          course: threeLevelCourse,
          exam: exam,
          answers: acingUpTo(2),
          takenAt: takenAt,
        ),
      );

      expect(after.levelStates['A1'], LevelState.mastered);
      expect(after.levelStates['A2'], LevelState.mastered);
      expect(after.levelStates['A1']!.isCleared, isTrue);
      expect(after.levelStates['A1'], isNot(LevelState.passed));
    });

    test('los dominados quedan abiertos para repaso (FR-037)', () {
      final StudentProgress after = applyPlacement(
        progress: fresh(),
        course: threeLevelCourse,
        result: evaluatePlacement(
          course: threeLevelCourse,
          exam: exam,
          answers: acingUpTo(2),
          takenAt: takenAt,
        ),
      );

      expect(after.levelStates['A1']!.isOpen, isTrue);
    });

    test('el nivel asignado queda abierto y es el actual', () {
      final StudentProgress after = applyPlacement(
        progress: fresh(),
        course: threeLevelCourse,
        result: evaluatePlacement(
          course: threeLevelCourse,
          exam: exam,
          answers: acingUpTo(2),
          takenAt: takenAt,
        ),
      );

      expect(after.currentLevelId, 'B1');
      expect(after.levelStates['B1'], LevelState.unlocked);
    });

    test('estimar por encima del contenido asigna el techo disponible', () {
      // El caso de hoy: solo A1 existe. Quien da C1 estudia A1, y A1 queda
      // dominado, así que lo que encuentra es repaso (FR-038).
      final PlacementResult result = evaluatePlacement(
        course: oneLevelCourse,
        exam: exam,
        answers: acingUpTo(5),
        takenAt: takenAt,
      );
      final StudentProgress after = applyPlacement(
        progress: fresh(),
        course: oneLevelCourse,
        result: result,
      );

      expect(result.estimatedLevelId, 'C1', reason: 'no se rebaja');
      expect(after.currentLevelId, 'A1');
      expect(after.levelStates['A1'], LevelState.mastered);
      expect(after.levelStates.containsKey('C1'), isFalse);
    });

    test('nunca degrada un estado más avanzado', () {
      // Quien ya aprobó A1 por examen y luego nivela no puede perder el
      // `passed`: es la invariante del Principio IV aplicada aquí.
      final StudentProgress veteran = fresh().copyWith(
        levelStates: <String, LevelState>{'A1': LevelState.passed},
      );

      final StudentProgress after = applyPlacement(
        progress: veteran,
        course: threeLevelCourse,
        result: evaluatePlacement(
          course: threeLevelCourse,
          exam: exam,
          answers: acingUpTo(1),
          takenAt: takenAt,
        ),
      );

      expect(after.levelStates['A1'], LevelState.passed);
    });

    test('guarda el resultado, y solo el estimado y los dominados', () {
      final StudentProgress after = applyPlacement(
        progress: fresh(),
        course: oneLevelCourse,
        result: evaluatePlacement(
          course: oneLevelCourse,
          exam: exam,
          answers: acingUpTo(3),
          takenAt: takenAt,
        ),
      );

      expect(after.placement!.estimatedLevelId, 'B2');
      expect(after.placement!.masteredLevelIds, <String>['A1']);
      expect(after.placement!.takenAt, takenAt);
      expect(after.placement!.skipped, isFalse);
    });
  });

  group('omitir la prueba', () {
    test('omitir empieza en A1 sin dominar nada (FR-034)', () {
      final PlacementResult skipped = PlacementResult.skippedAt(takenAt);
      final StudentProgress after = applyPlacement(
        progress: const StudentProgress(
          uid: 'u1',
          courseId: 'xx',
          currentLevelId: 'A1',
        ),
        course: threeLevelCourse,
        result: skipped,
      );

      expect(skipped.skipped, isTrue);
      expect(after.currentLevelId, 'A1');
      expect(after.levelStates['A1'], LevelState.unlocked);
      expect(after.levelStates.containsKey('A2'), isFalse);
    });

    test('omitir deja constancia, para no volver a ofrecerla sin motivo', () {
      final StudentProgress after = applyPlacement(
        progress: const StudentProgress(
          uid: 'u1',
          courseId: 'xx',
          currentLevelId: 'A1',
        ),
        course: oneLevelCourse,
        result: PlacementResult.skippedAt(takenAt),
      );

      expect(after.placement, isNotNull);
      expect(after.placement!.skipped, isTrue);
    });
  });

  group('repasar lo dominado no altera la nivelación (FR-037)', () {
    test('aplicar el mismo resultado dos veces no cambia nada', () {
      // `applyPlacement` es la única función que escribe la marca y la
      // estimación, y es idempotente: repasar un nivel dominado pasa por
      // `recordActivity`, que no toca ninguna de las dos.
      final PlacementResult result = evaluatePlacement(
        course: threeLevelCourse,
        exam: exam,
        answers: acingUpTo(2),
        takenAt: takenAt,
      );
      final StudentProgress once = applyPlacement(
        progress: const StudentProgress(
          uid: 'u1',
          courseId: 'xx',
          currentLevelId: 'A1',
        ),
        course: threeLevelCourse,
        result: result,
      );
      final StudentProgress twice = applyPlacement(
        progress: once,
        course: threeLevelCourse,
        result: result,
      );

      expect(twice.levelStates, once.levelStates);
      expect(twice.currentLevelId, once.currentLevelId);
      expect(
        twice.placement!.estimatedLevelId,
        once.placement!.estimatedLevelId,
      );
    });
  });
}

/// Ejercicio mínimo válido. El contenido no importa: lo que se evalúa es la
/// etiqueta de nivel del ítem, no el ejercicio.
const Exercise _item = MultipleChoiceExercise(
  prompt: 'Pregunta de nivelación',
  options: <String>['a', 'b'],
  answerIndex: 0,
  explanation:
      'Explicación de prueba suficientemente larga para la invariante.',
);

/// Curso con un módulo por nivel, para los niveles dados.
Course _courseWith(List<String> levelIds) => Course(
  id: 'xx',
  name: 'Idioma de prueba',
  studyLanguageTag: 'xx-XX',
  supportLanguageTag: 'es',
  levels: <Level>[
    for (final String levelId in levelIds)
      Level(
        id: levelId,
        name: 'Nivel $levelId',
        description: 'Nivel de prueba $levelId.',
        modules: <Module>[
          Module(
            id: '${levelId}M1',
            order: 1,
            title: 'Módulo de $levelId',
            canDo: 'Hacer algo en $levelId.',
            vocabulary: const <VocabularyItem>[
              VocabularyItem(term: 'one', translation: 'uno'),
            ],
            grammar: const GrammarExplanation(
              title: 'Gramática',
              bodyHtml: '<p>Explicación.</p>',
            ),
            examples: const <BilingualExample>[
              BilingualExample(target: 'One.', spanish: 'Uno.'),
            ],
            reading: ReadingPassage(
              id: '${levelId}M1R',
              title: 'Lectura',
              paragraphs: const <String>['Texto de prueba.'],
            ),
            lessons: const <Lesson>[
              Lesson(id: 'L1', title: 'Lección', exercises: <Exercise>[_item]),
            ],
            moduleExam: Exam(
              id: '${levelId}M1EX',
              scope: ExamScope.module,
              exercises: const <Exercise>[],
            ),
          ),
        ],
        levelExam: Exam(
          id: '${levelId}EX',
          scope: ExamScope.level,
          exercises: const <Exercise>[],
        ),
      ),
  ],
  upcomingLevelIds: <String>[
    for (final String id in <String>['A1', 'A2', 'B1', 'B2', 'C1', 'C2'])
      if (!levelIds.contains(id)) id,
  ],
);
