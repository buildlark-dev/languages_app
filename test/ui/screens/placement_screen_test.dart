/// Verifica la nivelación en pantalla.
///
/// Las dos pruebas que más importan son la de omitir —FR-034 exige que sea una
/// salida de un toque— y la del estimado por encima del contenido disponible,
/// que es el caso que el catálogo de hoy produce siempre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/l10n/app_localizations.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/core/activity_score.dart';
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
import 'package:languages_app/ui/screens/level_map_screen.dart';
import 'package:languages_app/ui/screens/placement_screen.dart';

void main() {
  final DateTime now = DateTime(2026, 10, 7);

  late List<PlacementResult> finished;

  setUp(() => finished = <PlacementResult>[]);

  Widget wrap(Widget child) => MaterialApp(
    theme: lightTheme,
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  Widget screenFor(Course course) => wrap(
    PlacementScreen(
      course: course,
      now: now,
      onFinished: (PlacementResult result) async => finished.add(result),
    ),
  );

  /// Responde los seis ítems, acertando los primeros [correctLevels] niveles.
  ///
  /// Cada nivel tiene dos ítems y la opción correcta es siempre la primera, así
  /// que acertar es tocar «correcta» y fallar es tocar «incorrecta».
  Future<void> answerAll(WidgetTester tester, int correctLevels) async {
    for (int i = 0; i < 6; i++) {
      final bool answerWell = i < correctLevels * 2;
      await tester.tap(find.text(answerWell ? 'correcta' : 'incorrecta'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(i == 5 ? 'Terminar' : 'Siguiente'));
      await tester.pumpAndSettle();
    }
  }

  group('presentación', () {
    testWidgets('empieza explicando, no preguntando', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();

      expect(find.text('¿Ya sabes algo del idioma?'), findsOne);
      expect(find.textContaining('no se aprueba ni se suspende'), findsOne);
      expect(find.text('Pregunta 1 de 6'), findsNothing);
      expect(finished, isEmpty);
    });

    testWidgets('omitir está a un toque y no pide confirmación (FR-034)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Empezar desde cero'));
      await tester.pumpAndSettle();

      // Un toque, sin diálogo: empezar de cero es legítimo, no un error.
      expect(finished, hasLength(1));
      expect(finished.single.skipped, isTrue);
      expect(finished.single.estimatedLevelId, 'A1');
      expect(finished.single.masteredLevelIds, isEmpty);
    });
  });

  group('recorrido', () {
    testWidgets('no corrige sobre la marcha', (WidgetTester tester) async {
      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer la prueba'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('incorrecta'));
      await tester.pumpAndSettle();

      // Corregir enseñaría el patrón justo antes del otro ítem del mismo nivel.
      expect(find.text('Correcto'), findsNothing);
      expect(find.text('Incorrecto'), findsNothing);
      expect(find.textContaining('Se esperaba'), findsNothing);
      expect(find.text('Siguiente'), findsOne);
    });

    testWidgets('no se puede avanzar sin responder', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer la prueba'));
      await tester.pumpAndSettle();

      final FilledButton next = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Siguiente'),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('el último ítem dice Terminar, no Siguiente', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer la prueba'));
      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('correcta'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Pregunta 6 de 6'), findsOne);
      expect(find.text('Terminar'), findsOne);
      expect(find.text('Siguiente'), findsNothing);
      // Y todavía no se ha reportado nada.
      expect(finished, isEmpty);
    });

    testWidgets('se reporta una sola vez, al terminar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer la prueba'));
      await tester.pumpAndSettle();
      await answerAll(tester, 1);

      expect(finished, hasLength(1));
      expect(finished.single.takenAt, now);
      expect(finished.single.skipped, isFalse);
    });
  });

  group('resultado', () {
    testWidgets('informa el estimado real aunque supere al contenido', (
      WidgetTester tester,
    ) async {
      // Acierta los tres niveles: estimado B1, y solo A1 existe.
      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer la prueba'));
      await tester.pumpAndSettle();
      await answerAll(tester, 3);

      // FR-035: se informa sin rebajarlo ni ocultarlo.
      expect(find.text('Tu nivel estimado es B1'), findsOne);
      // FR-036: y se explica por qué se empieza en otro sitio.
      expect(find.text('Empiezas en A1'), findsOne);
      expect(
        find.textContaining('contenido de B1 está en preparación'),
        findsOne,
      );
      expect(finished.single.estimatedLevelId, 'B1');
    });

    testWidgets('marca como dominado lo demostrado con contenido (FR-037)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer la prueba'));
      await tester.pumpAndSettle();
      await answerAll(tester, 2);

      expect(find.textContaining('A1 queda marcado como dominado'), findsOne);
      expect(
        find.textContaining('No tienes que volver a aprobarlos'),
        findsOne,
      );
      expect(finished.single.masteredLevelIds, <String>['A1']);
    });

    testWidgets('avisa de que lo que queda es repaso, no contenido nuevo', (
      WidgetTester tester,
    ) async {
      // El asignado coincide con un nivel dominado: no hay nada nuevo (FR-038).
      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer la prueba'));
      await tester.pumpAndSettle();
      await answerAll(tester, 3);

      expect(find.text('Lo que encontrarás es repaso'), findsOne);
    });

    testWidgets('quien falla todo empieza en A1 sin explicaciones sobrantes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer la prueba'));
      await tester.pumpAndSettle();
      await answerAll(tester, 0);

      expect(find.text('Tu nivel estimado es A1'), findsOne);
      expect(find.text('Empiezas en A1'), findsOne);
      // Sin diferencia que explicar, no se explica nada.
      expect(find.textContaining('está en preparación'), findsNothing);
      expect(find.textContaining('dominado'), findsNothing);
      expect(find.text('Lo que encontrarás es repaso'), findsNothing);
    });

    testWidgets('con contenido hasta B1, dar B1 empieza en B1', (
      WidgetTester tester,
    ) async {
      // Mismo resultado, catálogo más grande: el asignado sube sin migración.
      await tester.pumpWidget(screenFor(_threeLevelCourse));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer la prueba'));
      await tester.pumpAndSettle();
      await answerAll(tester, 2);

      expect(find.text('Tu nivel estimado es B1'), findsOne);
      expect(find.text('Empiezas en B1'), findsOne);
      expect(find.textContaining('está en preparación'), findsNothing);
      expect(find.text('Lo que encontrarás es repaso'), findsNothing);
    });

    testWidgets('cabe a 360 dp en las tres fases', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(screenFor(_oneLevelCourse));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'presentación');

      await tester.tap(find.text('Hacer la prueba'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'recorrido');

      await answerAll(tester, 3);
      expect(tester.takeException(), isNull, reason: 'resultado');
    });
  });

  group('no volver a ofrecerla de forma intrusiva (T143)', () {
    StudentProgress progressWith({
      PlacementResult? placement,
      bool withActivity = false,
    }) => StudentProgress(
      uid: 'u1',
      courseId: 'xx',
      currentLevelId: 'A1',
      placement: placement,
      activityScores: <String, ActivityScore>{
        if (withActivity)
          'A1M1EX': ActivityScore(
            kind: ActivityKind.moduleExam,
            bestScore: 0.9,
            lastAttemptAt: now,
          ),
      },
    );

    test('se ofrece a quien acaba de empezar', () {
      expect(
        shouldOfferPlacement(course: _oneLevelCourse, progress: progressWith()),
        isTrue,
      );
    });

    test('no se ofrece a quien ya la hizo', () {
      expect(
        shouldOfferPlacement(
          course: _oneLevelCourse,
          progress: progressWith(
            placement: PlacementResult(
              estimatedLevelId: 'A2',
              masteredLevelIds: const <String>['A1'],
              takenAt: now,
            ),
          ),
        ),
        isFalse,
      );
    });

    test('omitirla también cuenta como respuesta', () {
      // Se le preguntó y dijo que no. Volver a preguntar es insistir.
      expect(
        shouldOfferPlacement(
          course: _oneLevelCourse,
          progress: progressWith(placement: PlacementResult.skippedAt(now)),
        ),
        isFalse,
      );
    });

    test('no se ofrece a quien ya tiene progreso', () {
      expect(
        shouldOfferPlacement(
          course: _oneLevelCourse,
          progress: progressWith(withActivity: true),
        ),
        isFalse,
      );
    });

    test('no se ofrece en un curso sin nivelación', () {
      expect(
        shouldOfferPlacement(
          course: _courseWithoutPlacement,
          progress: progressWith(),
        ),
        isFalse,
      );
    });
  });

  group('repasar lo dominado cuando no queda nada nuevo (FR-038)', () {
    StudentProgress allMastered() => const StudentProgress(
      uid: 'u1',
      courseId: 'xx',
      currentLevelId: 'A1',
      levelStates: <String, LevelState>{'A1': LevelState.mastered},
    );

    testWidgets('el mapa ofrece repaso en lugar de quedarse vacío', (
      WidgetTester tester,
    ) async {
      int reviews = 0;
      await tester.pumpWidget(
        wrap(
          LevelMapScreen(
            course: _oneLevelCourse,
            progress: allMastered(),
            showSyncBanner: false,
            onOpenLevel: (_) {},
            onReviewMastered: () => reviews++,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ya dominas todo lo publicado'), findsOne);
      expect(find.textContaining('Estamos preparando A2'), findsOne);

      await tester.tap(find.text('Repasar lo dominado'));
      expect(reviews, 1);
    });

    testWidgets('con contenido nuevo pendiente NO se ofrece', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          LevelMapScreen(
            course: _oneLevelCourse,
            progress: const StudentProgress(
              uid: 'u1',
              courseId: 'xx',
              currentLevelId: 'A1',
              levelStates: <String, LevelState>{'A1': LevelState.unlocked},
            ),
            showSyncBanner: false,
            onOpenLevel: (_) {},
            onReviewMastered: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Invitar a repasar a quien tiene cuatro módulos sin empezar lo desvía.
      expect(find.text('Ya dominas todo lo publicado'), findsNothing);
    });
  });
}

/// Ítem acertado al tocar «correcta».
const Exercise _goodItem = MultipleChoiceExercise(
  prompt: 'Elige la correcta',
  options: <String>['correcta', 'incorrecta'],
  answerIndex: 0,
  explanation:
      'Explicación de prueba suficientemente larga para la invariante.',
);

/// Prueba de tres niveles, dos ítems cada uno.
const PlacementExam _exam = PlacementExam(
  id: 'TESTPLACE',
  items: <PlacementItem>[
    PlacementItem(levelId: 'A1', exercise: _goodItem),
    PlacementItem(levelId: 'A1', exercise: _goodItem),
    PlacementItem(levelId: 'A2', exercise: _goodItem),
    PlacementItem(levelId: 'A2', exercise: _goodItem),
    PlacementItem(levelId: 'B1', exercise: _goodItem),
    PlacementItem(levelId: 'B1', exercise: _goodItem),
  ],
);

final Course _oneLevelCourse = _courseWith(<String>['A1'], exam: _exam);
final Course _threeLevelCourse = _courseWith(<String>[
  'A1',
  'A2',
  'B1',
], exam: _exam);
final Course _courseWithoutPlacement = _courseWith(<String>['A1']);

Course _courseWith(List<String> levelIds, {PlacementExam? exam}) => Course(
  id: 'xx',
  name: 'Idioma de prueba',
  studyLanguageTag: 'xx-XX',
  supportLanguageTag: 'es',
  placementTest: exam,
  levels: <Level>[
    for (final String levelId in levelIds)
      Level(
        id: levelId,
        name: 'Nivel $levelId',
        description: 'Lo básico de $levelId.',
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
              Lesson(
                id: 'L1',
                title: 'Lección',
                exercises: <Exercise>[_goodItem],
              ),
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
