/// Recorre la app de punta a punta: elegir idioma, entrar en un módulo, hacer
/// una lección y ver el progreso guardado.
///
/// Es la prueba que demuestra que la app es **recorrible**, no solo que cada
/// pantalla funciona por separado. Hasta esta fase cada pantalla tenía su prueba
/// y ninguna estaba conectada a la siguiente, así que nada garantizaba que el
/// camino existiera.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/app.dart';
import 'package:languages_app/app/home_shell.dart';
import 'package:languages_app/app/l10n/app_localizations.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/services/auth/auth_service.dart';
import 'package:languages_app/services/settings/settings_store.dart';
import 'package:languages_app/ui/providers/auth_providers.dart';
import 'package:languages_app/ui/providers/clock_providers.dart';
import 'package:languages_app/ui/providers/content_providers.dart';
import 'package:languages_app/ui/providers/progress_providers.dart';
import 'package:languages_app/ui/providers/review_providers.dart';
import 'package:languages_app/ui/providers/speech_providers.dart';

import '../fakes/fake_auth_service.dart';
import '../fakes/fake_catalog.dart';
import '../fakes/fake_progress_store.dart';
import '../fakes/fake_review_store.dart';
import '../fakes/fake_stt_service.dart';
import '../fakes/fake_sync_service.dart';
import '../fakes/fake_tts_service.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 8);

  late FakeProgressStore progressStore;
  late FakeReviewStore reviewStore;
  late FakeSyncService sync;

  Widget wrap({StudentProgress? progress}) {
    progressStore = FakeProgressStore(initial: progress);
    reviewStore = FakeReviewStore();
    sync = FakeSyncService();

    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(progressStore),
        reviewStoreProvider.overrideWithValue(reviewStore),
        syncServiceProvider.overrideWithValue(sync),
        settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
        clockProvider.overrideWithValue(fixedClock(today)),
        courseCatalogProvider.overrideWithValue(const FakeCatalog()),
        ttsServiceProvider.overrideWithValue(FakeTtsService()),
        sttServiceProvider.overrideWithValue(FakeSttService()),
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
        home: const HomeShell(),
      ),
    );
  }

  /// Toca algo que puede estar fuera de pantalla.
  Future<void> tapScrolled(WidgetTester tester, Finder target) async {
    if (target.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        target,
        200,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('elegir el idioma abre su mapa de niveles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Elige el idioma que quieres aprender'), findsOne);

    await tapScrolled(tester, find.text('Idioma de prueba'));

    // El mapa del curso, con su nivel y sus niveles anunciados.
    expect(find.text('A1 · Prueba'), findsOne);
    expect(find.textContaining('A2'), findsWidgets);
  });

  testWidgets('del mapa al módulo y de ahí a la lección', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tapScrolled(tester, find.text('Idioma de prueba'));
    await tapScrolled(tester, find.text('A1 · Prueba'));

    // Mapa de módulos del nivel.
    expect(find.textContaining('Módulo de prueba'), findsOne);
    await tapScrolled(tester, find.textContaining('1. Módulo de prueba'));

    // Dentro del módulo: su objetivo, su lección y su examen.
    expect(find.text('Al terminar podrás'), findsOne);
    expect(find.text('Lección de prueba'), findsOne);
    expect(find.text('Examen del módulo'), findsOne);

    await tapScrolled(tester, find.text('Lección de prueba'));

    // Material de estudio primero, no ejercicios (FR-013).
    expect(find.text('Vocabulario'), findsOne);
  });

  testWidgets('entrar en un módulo siembra su vocabulario (FR-028)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tapScrolled(tester, find.text('Idioma de prueba'));
    await tapScrolled(tester, find.text('A1 · Prueba'));
    await tapScrolled(tester, find.textContaining('1. Módulo de prueba'));

    expect(reviewStore.seedCalls, <String>['XXM1']);
    expect(reviewStore.allCards.single.term, 'one');
  });

  testWidgets('aprobar la lección guarda el progreso y lo sincroniza', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tapScrolled(tester, find.text('Idioma de prueba'));
    await tapScrolled(tester, find.text('A1 · Prueba'));
    await tapScrolled(tester, find.textContaining('1. Módulo de prueba'));
    await tapScrolled(tester, find.text('Lección de prueba'));
    await tapScrolled(tester, find.text('Empezar ejercicios'));

    // El único ejercicio del catálogo falso: la opción correcta es la primera.
    await tapScrolled(tester, find.widgetWithText(OutlinedButton, 'a'));
    await tapScrolled(tester, find.widgetWithText(FilledButton, 'Comprobar'));
    await tapScrolled(tester, find.widgetWithText(FilledButton, 'Continuar'));

    expect(find.text('100 %'), findsOne);
    expect(find.text('Lección aprobada'), findsOne);

    // Lo que importa: quedó en disco y se pidió sincronizar.
    final StudentProgress saved = progressStore.current('u1', 'xx')!;
    expect(saved.activityScores['XXM1L1']!.bestScore, 1.0);
    expect(saved.xp, greaterThan(0));
    expect(saved.streakCount, 1);
    expect(saved.lastActivityDate, today);
    expect(sync.pushCount, greaterThanOrEqualTo(1));
  });

  testWidgets('el progreso guardado se ve en la pantalla de progreso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tapScrolled(tester, find.text('Idioma de prueba'));
    await tapScrolled(tester, find.text('A1 · Prueba'));
    await tapScrolled(tester, find.textContaining('1. Módulo de prueba'));
    await tapScrolled(tester, find.text('Lección de prueba'));
    await tapScrolled(tester, find.text('Empezar ejercicios'));
    await tapScrolled(tester, find.widgetWithText(OutlinedButton, 'a'));
    await tapScrolled(tester, find.widgetWithText(FilledButton, 'Comprobar'));
    await tapScrolled(tester, find.widgetWithText(FilledButton, 'Continuar'));

    // Volver atrás hasta la pantalla principal y abrir el progreso.
    final NavigatorState navigator = tester.state<NavigatorState>(
      find.byType(Navigator),
    );
    navigator.popUntil((Route<Object?> route) => route.isFirst);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tu progreso'));
    await tester.pumpAndSettle();

    expect(find.text('1 día seguido'), findsOne);
    expect(find.textContaining('XP'), findsWidgets);
    // La lección aprobada no aprueba el módulo: eso lo decide su examen.
    expect(find.text('0 de 1'), findsOne);
  });

  testWidgets('un nivel bloqueado no abre por ninguna vía (SC-009)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        progress: const StudentProgress(
          uid: 'u1',
          courseId: 'xx',
          currentLevelId: 'A1',
          levelStates: <String, LevelState>{'A1': LevelState.locked},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tapScrolled(tester, find.text('Idioma de prueba'));

    // La tarjeta existe y se ve, pero no tiene ruta: sin `onTap` no hay forma de
    // entrar, ni tocando ni con el teclado.
    expect(find.text('A1 · Prueba'), findsOne);
    await tester.tap(find.text('A1 · Prueba'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Módulo de prueba'), findsNothing);
  });

  testWidgets('un nivel anunciado tampoco abre nada (FR-038)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tapScrolled(tester, find.text('Idioma de prueba'));

    // A2 y B1 están anunciados en el catálogo falso: aparecen, no se abren.
    await tapScrolled(tester, find.textContaining('A2'));
    expect(find.text('Al terminar podrás'), findsNothing);
  });

  testWidgets('se llega a ajustes y al repaso desde la pantalla principal', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    // El icono de ajustes solo aparece con un idioma elegido, así que primero
    // hay que entrar y volver.
    await tapScrolled(tester, find.text('Idioma de prueba'));
    final NavigatorState navigator = tester.state<NavigatorState>(
      find.byType(Navigator),
    );
    navigator.popUntil((Route<Object?> route) => route.isFirst);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Ajustes'), findsWidgets);
    expect(find.text('Respaldo'), findsOne);
  });

  testWidgets('elegir el idioma ofrece la nivelación acto seguido (FR-034)', (
    WidgetTester tester,
  ) async {
    // Estaba en la pantalla de inicio, detrás del catálogo. Como elegir idioma
    // entra directo al curso, quien llegaba por primera vez no la veía nunca.
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tapScrolled(tester, find.text('Idioma de prueba'));

    expect(find.text('¿Empiezas de cero?'), findsOne);
    await tapScrolled(tester, find.text('Ver mi nivel'));
    expect(find.text('¿Ya sabes algo del idioma?'), findsOne);
  });

  testWidgets('con actividad registrada ya no se ofrece la nivelación', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        progress: StudentProgress(
          uid: 'u1',
          courseId: 'xx',
          currentLevelId: 'A1',
          levelStates: const <String, LevelState>{'A1': LevelState.unlocked},
          activityScores: <String, ActivityScore>{
            'XXM1L1': ActivityScore(
              kind: ActivityKind.lesson,
              bestScore: 0.9,
              lastAttemptAt: today,
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tapScrolled(tester, find.text('Idioma de prueba'));

    expect(find.text('¿Empiezas de cero?'), findsNothing);
  });

  testWidgets('con el curso abierto, el audio está disponible (T181)', (
    WidgetTester tester,
  ) async {
    // La comprobación de extremo a extremo de que la voz se prepara sola: el
    // botón de escuchar solo se dibuja si hay audio.
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tapScrolled(tester, find.text('Idioma de prueba'));
    await tapScrolled(tester, find.text('A1 · Prueba'));
    await tapScrolled(tester, find.textContaining('1. Módulo de prueba'));
    await tapScrolled(tester, find.text('Lección de prueba'));

    expect(find.byIcon(Icons.volume_up_outlined), findsWidgets);
  });
}
