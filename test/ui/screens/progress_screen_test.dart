/// Verifica la pantalla de progreso y las tres insignias (FR-031, FR-032,
/// FR-033).
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/l10n/app_localizations.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/engine/streak_tracker.dart';
import 'package:languages_app/services/auth/auth_service.dart';
import 'package:languages_app/ui/providers/auth_providers.dart';
import 'package:languages_app/ui/providers/clock_providers.dart';
import 'package:languages_app/ui/providers/content_providers.dart';
import 'package:languages_app/ui/providers/progress_providers.dart';
import 'package:languages_app/ui/providers/review_providers.dart';
import 'package:languages_app/ui/screens/progress_screen.dart';
import 'package:languages_app/ui/widgets/progress_ring.dart';
import 'package:languages_app/ui/widgets/streak_badge.dart';
import 'package:languages_app/ui/widgets/xp_badge.dart';

import '../../fakes/fake_auth_service.dart';
import '../../fakes/fake_catalog.dart';
import '../../fakes/fake_progress_store.dart';
import '../../fakes/fake_review_store.dart';
import '../../fakes/fake_sync_service.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 7);

  Widget wrapBare(Widget child) => MaterialApp(
    theme: lightTheme,
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  group('insignia de racha', () {
    testWidgets('sin actividad no hay racha, y el icono está apagado', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapBare(StreakBadge(streak: StreakPoint.none, today: today)),
      );

      expect(find.text('Sin racha todavía'), findsOne);
      expect(find.byIcon(Icons.local_fire_department_outlined), findsOne);
      expect(find.byIcon(Icons.local_fire_department), findsNothing);
    });

    testWidgets('con actividad hoy, felicita sin pedir nada', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapBare(
          StreakBadge(
            streak: StreakPoint(date: today, count: 4),
            today: today,
          ),
        ),
      );

      expect(find.text('4 días seguidos'), findsOne);
      expect(find.byIcon(Icons.local_fire_department), findsOne);
      expect(find.text('Estudia hoy para no perderla'), findsNothing);
    });

    testWidgets('con la racha viva pero hoy sin estudiar, avisa', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapBare(
          StreakBadge(
            streak: StreakPoint(date: addDays(today, -1), count: 4),
            today: today,
          ),
        ),
      );

      expect(find.text('4 días seguidos'), findsOne);
      expect(find.text('Estudia hoy para no perderla'), findsOne);
    });

    testWidgets('una racha rota muestra cero, no su último valor', (
      WidgetTester tester,
    ) async {
      // El contador solo se toca al estudiar. Sin la consulta al motor, esto
      // diría «9 días seguidos» a quien no estudia desde hace un mes.
      await tester.pumpWidget(
        wrapBare(
          StreakBadge(
            streak: StreakPoint(date: addDays(today, -30), count: 9),
            today: today,
          ),
        ),
      );

      expect(find.text('Sin racha todavía'), findsOne);
      expect(find.text('9 días seguidos'), findsNothing);
    });

    testWidgets('el singular se dice en singular', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapBare(
          StreakBadge(
            streak: StreakPoint(date: today, count: 1),
            today: today,
          ),
        ),
      );

      expect(find.text('1 día seguido'), findsOne);
    });
  });

  group('insignia de XP', () {
    testWidgets('muestra el total acumulado', (WidgetTester tester) async {
      await tester.pumpWidget(wrapBare(const XpBadge(xp: 340)));

      expect(find.text('340 XP'), findsOne);
    });

    testWidgets('muestra lo ganado cuando hay ganancia', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapBare(const XpBadge(xp: 360, justGained: 20)));

      expect(find.text('360 XP'), findsOne);
      expect(find.text('+20'), findsOne);
    });

    testWidgets('un reintento sin mejora NO muestra +0', (
      WidgetTester tester,
    ) async {
      // El motor concede cero al repetir sin mejorar. Un «+0» al lado de un
      // total que no se movió es ruido que invita a preguntarse si falló algo.
      await tester.pumpWidget(wrapBare(const XpBadge(xp: 360, justGained: 0)));

      expect(find.text('360 XP'), findsOne);
      expect(find.textContaining('+'), findsNothing);
    });
  });

  group('anillo de avance', () {
    testWidgets('el porcentaje va escrito, no solo dibujado', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapBare(const ProgressRing(completion: 0.5, label: 'Avance de A1')),
      );

      expect(find.text('50 %'), findsOne);
    });

    testWidgets('redondea y recorta fuera de rango', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapBare(const ProgressRing(completion: 0.666, label: 'A1')),
      );
      expect(find.text('67 %'), findsOne);

      await tester.pumpWidget(
        wrapBare(const ProgressRing(completion: 1.4, label: 'A1')),
      );
      expect(find.text('100 %'), findsOne);
    });

    testWidgets('a 130 % de tamaño de letra no se desborda (FR-047)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: Scaffold(body: ProgressRing(completion: 1, label: 'A1')),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('100 %'), findsOne);
    });
  });

  group('pantalla de progreso (FR-033)', () {
    late FakeProgressStore progressStore;
    late FakeReviewStore reviewStore;

    ReviewCard cardOf(String term, DateTime due) => ReviewCard(
      moduleId: 'XXM1',
      term: term,
      translation: 'traducción de $term',
      intervalStep: 0,
      dueDate: due,
    );

    Widget wrapScreen({
      required StudentProgress stored,
      List<ReviewCard> cards = const <ReviewCard>[],
    }) {
      progressStore = FakeProgressStore(initial: stored);
      reviewStore = FakeReviewStore(cards: cards);

      return ProviderScope(
        overrides: [
          progressStoreProvider.overrideWithValue(progressStore),
          reviewStoreProvider.overrideWithValue(reviewStore),
          syncServiceProvider.overrideWithValue(FakeSyncService()),
          clockProvider.overrideWithValue(fixedClock(today)),
          courseCatalogProvider.overrideWithValue(const FakeCatalog()),
          selectedCourseIdProvider.overrideWith(PreselectedCourse.new),
          authServiceProvider.overrideWithValue(
            FakeAuthService(
              initialUser: const StudentIdentity(
                uid: 'u1',
                email: 'ana@example.com',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: lightTheme,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProgressScreen(),
        ),
      );
    }

    StudentProgress progressWith({
      bool moduleExamPassed = false,
      int xp = 0,
      int streak = 0,
      DateTime? lastActivity,
      LevelState levelState = LevelState.unlocked,
    }) => StudentProgress(
      uid: 'u1',
      courseId: 'xx',
      currentLevelId: 'A1',
      xp: xp,
      streakCount: streak,
      lastActivityDate: lastActivity,
      levelStates: <String, LevelState>{'A1': levelState},
      activityScores: <String, ActivityScore>{
        if (moduleExamPassed)
          'XXM1EX': ActivityScore(
            kind: ActivityKind.moduleExam,
            bestScore: 0.9,
            lastAttemptAt: today,
          ),
      },
    );

    testWidgets('muestra el avance del nivel y los módulos superados', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapScreen(stored: progressWith()));
      await tester.pumpAndSettle();

      // El catálogo falso tiene un módulo en A1, sin aprobar.
      expect(find.text('0 %'), findsOne);
      expect(find.text('Módulos superados'), findsOne);
      expect(find.text('0 de 1'), findsOne);
    });

    testWidgets('aprobar el módulo mueve el anillo al 100 %', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapScreen(stored: progressWith(moduleExamPassed: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ProgressRing), findsOne);
      expect(find.text('100 %'), findsOne);
      expect(find.text('1 de 1'), findsOne);
    });

    testWidgets('muestra el tamaño de la cola de repaso', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapScreen(
          stored: progressWith(),
          cards: <ReviewCard>[
            cardOf('one', today),
            cardOf('two', today),
            cardOf('three', addDays(today, 5)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Palabras en repaso'), findsOne);
      expect(find.text('3 · 2 vencen hoy'), findsOne);
    });

    testWidgets('con la cola al día lo dice, sin un cero suelto', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapScreen(
          stored: progressWith(),
          cards: <ReviewCard>[cardOf('one', addDays(today, 3))],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 · al día'), findsOne);
    });

    testWidgets('sin cola todavía lo distingue de estar al día', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrapScreen(stored: progressWith()));
      await tester.pumpAndSettle();

      expect(find.text('ninguna todavía'), findsOne);
    });

    testWidgets('muestra racha y XP', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapScreen(
          stored: progressWith(xp: 120, streak: 3, lastActivity: today),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 días seguidos'), findsOne);
      expect(find.text('120 XP'), findsOne);
    });

    testWidgets('lista los niveles con su estado, incluidos los anunciados', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapScreen(stored: progressWith(levelState: LevelState.mastered)),
      );
      await tester.pumpAndSettle();

      // El nombre lo lleva el anillo; la lista usa el identificador, así que
      // ninguna cifra ni ningún nombre aparece dos veces en la pantalla.
      expect(find.text('A1 · Prueba'), findsOne);
      expect(find.text('A1'), findsOne);
      expect(find.text('Dominado'), findsOne);
      // El catálogo falso anuncia A2 y B1.
      expect(find.text('A2 · en preparación'), findsOne);
      expect(find.text('B1 · en preparación'), findsOne);
    });

    testWidgets('cabe a 360 dp', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapScreen(
          stored: progressWith(xp: 999, streak: 12, lastActivity: today),
          cards: <ReviewCard>[cardOf('one', today)],
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}

/// Idioma preseleccionado: la pantalla de progreso es por curso.
class PreselectedCourse extends SelectedCourse {
  @override
  String? build() => 'xx';
}
