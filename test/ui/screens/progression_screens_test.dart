/// Verifica el mapa de niveles, el mapa de módulos y el examen.
///
/// La prueba más importante es la que comprueba que un nivel anunciado **no abre
/// nada por ninguna vía**: es la garantía de FR-038 a nivel de interfaz.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/l10n/app_localizations.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/content/en/english_course.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/course.dart';
import 'package:languages_app/core/exam.dart';
import 'package:languages_app/core/exercise.dart';
import 'package:languages_app/core/level.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/module.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/engine/scoring.dart';
import 'package:languages_app/ui/screens/exam_screen.dart';
import 'package:languages_app/ui/screens/level_map_screen.dart';
import 'package:languages_app/ui/providers/review_providers.dart';
import 'package:languages_app/ui/screens/module_screen.dart';

import '../../fakes/fake_review_store.dart';

const Course course = englishCourse;
Level get a1 => course.levels.single;
Module moduleAt(int i) => a1.modules[i];

ActivityScore passedScore() => ActivityScore(
  kind: ActivityKind.moduleExam,
  bestScore: 0.9,
  lastAttemptAt: DateTime(2026, 10, 6),
);

StudentProgress progressWith({
  LevelState a1State = LevelState.unlocked,
  int passedModules = 0,
  bool levelExamPassed = false,
}) => StudentProgress(
  uid: 'u1',
  courseId: 'en',
  currentLevelId: 'A1',
  levelStates: <String, LevelState>{
    'A1': levelExamPassed ? LevelState.passed : a1State,
  },
  activityScores: <String, ActivityScore>{
    for (int i = 0; i < passedModules; i++)
      moduleAt(i).moduleExam.id: passedScore(),
    if (levelExamPassed)
      a1.levelExam.id: ActivityScore(
        kind: ActivityKind.levelExam,
        bestScore: 0.85,
        lastAttemptAt: DateTime(2026, 10, 6),
      ),
  },
);

/// Monta la pantalla con un ámbito de proveedores.
///
/// El ámbito es necesario desde que `ModuleScreen` siembra la cola de repaso al
/// entrar en un módulo (FR-028). Aquí no se eligió curso ni hay sesión abierta,
/// así que la siembra se descarta sola: estas pruebas son sobre las puertas de
/// progresión, y la siembra tiene las suyas en `review_screen_test.dart`.
Widget wrap(Widget child) => ProviderScope(
  overrides: [reviewStoreProvider.overrideWithValue(FakeReviewStore())],
  child: MaterialApp(
    theme: lightTheme,
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

/// Desplaza hasta la tarjeta del examen de nivel.
///
/// Está al final de un ListView con cuatro módulos por delante, y un ListView no
/// construye lo que queda fuera de pantalla: sin desplazar, el botón no existe
/// para los buscadores.
Future<void> scrollToLevelExam(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.textContaining("Examen de A1"),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  group('mapa de niveles', () {
    testWidgets('muestra A1 y los cinco niveles anunciados', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          LevelMapScreen(
            course: course,
            progress: progressWith(),
            onOpenLevel: (_) {},
            showSyncBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('A1 · Fundamentos'), findsOne);
      for (final String id in course.upcomingLevelIds) {
        expect(
          find.textContaining('$id · Próximo', skipOffstage: false),
          findsOne,
          reason: id,
        );
      }
    });

    testWidgets('un nivel anunciado NO abre nada al tocarlo', (
      WidgetTester tester,
    ) async {
      // FR-038 en la interfaz. La garantía de fondo es estructural: A2 no es un
      // Level, así que no existe dato que pudiera representar la entrada.
      final List<Level> opened = <Level>[];
      await tester.pumpWidget(
        wrap(
          LevelMapScreen(
            course: course,
            progress: progressWith(),
            onOpenLevel: opened.add,
            showSyncBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Finder a2 = find.textContaining('A2 · Próximo');
      await tester.ensureVisible(a2);
      await tester.pumpAndSettle();
      await tester.tap(a2, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
    });

    testWidgets('un nivel bloqueado no abre nada', (WidgetTester tester) async {
      final List<Level> opened = <Level>[];
      await tester.pumpWidget(
        wrap(
          LevelMapScreen(
            course: course,
            progress: progressWith(a1State: LevelState.locked),
            onOpenLevel: opened.add,
            showSyncBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A1 · Fundamentos'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
      expect(find.text('Bloqueado'), findsOne);
    });

    testWidgets('un nivel desbloqueado se abre', (WidgetTester tester) async {
      final List<Level> opened = <Level>[];
      await tester.pumpWidget(
        wrap(
          LevelMapScreen(
            course: course,
            progress: progressWith(),
            onOpenLevel: opened.add,
            showSyncBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('A1 · Fundamentos'));
      await tester.pumpAndSettle();

      expect(opened.single.id, 'A1');
    });

    testWidgets('el avance se muestra como módulos aprobados', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          LevelMapScreen(
            course: course,
            progress: progressWith(passedModules: 2),
            onOpenLevel: (_) {},
            showSyncBanner: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2/4'), findsOne);
    });
  });

  group('mapa de módulos', () {
    testWidgets('solo el primer módulo está abierto al empezar', (
      WidgetTester tester,
    ) async {
      final List<Module> opened = <Module>[];
      await tester.pumpWidget(
        wrap(
          ModuleScreen(
            course: course,
            level: a1,
            progress: progressWith(),
            onOpenModule: opened.add,
            onOpenLevelExam: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('1. ${moduleAt(0).title}'));
      await tester.pumpAndSettle();
      expect(opened.single.id, moduleAt(0).id);

      opened.clear();
      final Finder second = find.textContaining('2. ${moduleAt(1).title}');
      await tester.ensureVisible(second);
      await tester.pumpAndSettle();
      await tester.tap(second, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
    });

    testWidgets('un módulo bloqueado explica QUÉ falta', (
      WidgetTester tester,
    ) async {
      // FR-023: un candado sin motivo es una pared.
      await tester.pumpWidget(
        wrap(
          ModuleScreen(
            course: course,
            level: a1,
            progress: progressWith(),
            onOpenModule: (_) {},
            onOpenLevelExam: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Primero aprueba el módulo «${moduleAt(0).title}»',
          skipOffstage: false,
        ),
        findsOne,
      );
    });

    testWidgets('el objetivo "puedo hacer X" se ve antes de entrar', (
      WidgetTester tester,
    ) async {
      // FR-011.
      await tester.pumpWidget(
        wrap(
          ModuleScreen(
            course: course,
            level: a1,
            progress: progressWith(),
            onOpenModule: (_) {},
            onOpenLevelExam: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(moduleAt(0).canDo), findsOne);
    });

    testWidgets('el examen de nivel aprobado dice con qué nota', (
      WidgetTester tester,
    ) async {
      // T164, reportado verificando tras reiniciar el dispositivo: se veían
      // las lecciones aprobadas, pero del examen de A1 solo se ofrecía volver
      // a presentarlo, **sin el resultado obtenido**. El puntaje estaba
      // guardado —hay una prueba de persistencia que lo fija—; lo que faltaba
      // era enseñarlo. Sin la nota, «aprobado» y «aprobado raspando» se ven
      // igual y no se sabe si conviene repetir.
      await tester.pumpWidget(
        wrap(
          ModuleScreen(
            course: course,
            level: a1,
            progress: progressWith(passedModules: 4, levelExamPassed: true),
            onOpenModule: (_) {},
            onOpenLevelExam: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await scrollToLevelExam(tester);

      expect(find.textContaining('Aprobado con un 85 %'), findsOne);
      expect(
        find.widgetWithText(OutlinedButton, 'Repetir el examen'),
        findsOne,
        reason: 'Aprobado no quita la posibilidad de repetirlo (FR-027)',
      );
    });

    testWidgets('el examen de nivel dice cuántos módulos faltan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ModuleScreen(
            course: course,
            level: a1,
            progress: progressWith(passedModules: 2),
            onOpenModule: (_) {},
            onOpenLevelExam: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await scrollToLevelExam(tester);

      expect(find.textContaining("Aprueba los 4 módulos"), findsOne);
      expect(
        find.widgetWithText(FilledButton, 'Presentar el examen'),
        findsNothing,
      );
    });

    testWidgets('con los cuatro módulos aprobados, el examen se habilita', (
      WidgetTester tester,
    ) async {
      final List<Exam> opened = <Exam>[];
      await tester.pumpWidget(
        wrap(
          ModuleScreen(
            course: course,
            level: a1,
            progress: progressWith(passedModules: 4),
            onOpenModule: (_) {},
            onOpenLevelExam: opened.add,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await scrollToLevelExam(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, "Presentar el examen"),
      );
      await tester.pumpAndSettle();

      expect(opened.single.id, a1.levelExam.id);
    });

    testWidgets('aprobado el nivel, ofrece repetir en lugar de presentar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ModuleScreen(
            course: course,
            level: a1,
            progress: progressWith(passedModules: 4, levelExamPassed: true),
            onOpenModule: (_) {},
            onOpenLevelExam: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await scrollToLevelExam(tester);

      expect(find.textContaining("Ya superaste el nivel"), findsOne);
      expect(
        find.widgetWithText(OutlinedButton, "Repetir el examen"),
        findsOne,
      );
    });
  });

  group('examen', () {
    testWidgets('usa el umbral del 80 %, no el de lección', (
      WidgetTester tester,
    ) async {
      final List<ScoreResult> saved = <ScoreResult>[];
      await tester.pumpWidget(
        wrap(
          ExamScreen(
            exam: moduleAt(0).moduleExam,
            kind: ActivityKind.moduleExam,
            title: 'Examen del módulo',
            onCompleted: (Exam _, ScoreResult r) async => saved.add(r),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Ejercicio 1 de 10'), findsOne);
      // No hay material de estudio: un examen evalúa lo ya aprendido.
      expect(find.text('Empezar ejercicios'), findsNothing);
      expect(saved, isEmpty);
    });

    testWidgets('el mensaje de suspenso cita el 80 % y quita el miedo', (
      WidgetTester tester,
    ) async {
      final List<ScoreResult> saved = <ScoreResult>[];
      await tester.pumpWidget(
        wrap(
          ExamScreen(
            exam: const Exam(
              id: 'X',
              scope: ExamScope.module,
              exercises: <Exercise>[],
            ),
            kind: ActivityKind.moduleExam,
            title: 'Examen',
            onCompleted: (Exam _, ScoreResult r) async => saved.add(r),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Un examen vacío se completa de inmediato y no aprueba.
      expect(find.textContaining('Necesitas 80 %'), findsOne);
      expect(find.textContaining('Se conserva tu mejor resultado'), findsOne);
      expect(saved.single.passed, isFalse);
    });
  });
}
