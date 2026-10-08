/// Verifica los ajustes y, sobre todo, que borrar exige confirmación (FR-046).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/app.dart';
import 'package:languages_app/app/l10n/app_localizations.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/services/auth/auth_service.dart';
import 'package:languages_app/services/backup/json_backup_service.dart';
import 'package:languages_app/services/settings/settings_store.dart';
import 'package:languages_app/ui/providers/auth_providers.dart';
import 'package:languages_app/ui/providers/backup_providers.dart';
import 'package:languages_app/ui/providers/clock_providers.dart';
import 'package:languages_app/ui/providers/content_providers.dart';
import 'package:languages_app/ui/providers/progress_providers.dart';
import 'package:languages_app/ui/providers/review_providers.dart';
import 'package:languages_app/ui/providers/speech_providers.dart';
import 'package:languages_app/ui/screens/settings_screen.dart';

import '../../fakes/fake_auth_service.dart';
import '../../fakes/fake_catalog.dart';
import '../../fakes/fake_progress_store.dart';
import '../../fakes/fake_review_store.dart';
import '../../fakes/fake_sync_service.dart';
import '../../fakes/fake_tts_service.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 8);

  late FakeProgressStore progressStore;
  late InMemorySettingsStore settings;
  late FakeTtsService tts;

  /// Lo que el portapapeles recibió, en orden.
  late List<String> copied;

  StudentProgress stored({int xp = 150}) => StudentProgress(
    uid: 'u1',
    courseId: 'xx',
    currentLevelId: 'A1',
    xp: xp,
    streakCount: 3,
    lastActivityDate: today,
    levelStates: const <String, LevelState>{'A1': LevelState.unlocked},
    activityScores: <String, ActivityScore>{
      'XXM1EX': ActivityScore(
        kind: ActivityKind.moduleExam,
        bestScore: 0.9,
        lastAttemptAt: today,
      ),
    },
  );

  setUp(() {
    settings = InMemorySettingsStore();
    tts = FakeTtsService();
    copied = <String>[];

    // El portapapeles es un canal de plataforma: en una prueba de widget hay
    // que interceptarlo, porque no hay sistema operativo detrás que responda.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (
          MethodCall call,
        ) async {
          if (call.method == 'Clipboard.setData') {
            copied.add(
              (call.arguments as Map<Object?, Object?>)['text'] as String,
            );
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Widget wrap({StudentProgress? progress}) {
    progressStore = FakeProgressStore(initial: progress);

    return ProviderScope(
      overrides: [
        progressStoreProvider.overrideWithValue(progressStore),
        backupServiceProvider.overrideWithValue(
          JsonBackupService(progressStore, clock: fixedClock(today)),
        ),
        reviewStoreProvider.overrideWithValue(FakeReviewStore()),
        syncServiceProvider.overrideWithValue(FakeSyncService()),
        settingsStoreProvider.overrideWithValue(settings),
        ttsServiceProvider.overrideWithValue(tts),
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
        darkTheme: darkTheme,
        localizationsDelegates: const <LocalizationsDelegate<Object>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SettingsScreen(),
      ),
    );
  }

  /// Toca algo que puede estar fuera de pantalla.
  ///
  /// La pantalla de ajustes es larga y un `ListView` no construye lo que queda
  /// fuera. Peor aún: `tap` sobre un widget construido pero bajo el borde no
  /// falla, toca unas coordenadas donde no hay nada, y el síntoma es un diálogo
  /// que no aparece sin ningún error.
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

  group('apariencia', () {
    testWidgets('ofrece los tres modos y parte del sistema (FR-048)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text('Como el sistema'), findsOne);
      expect(find.text('Claro'), findsOne);
      expect(find.text('Oscuro'), findsOne);
      expect(settings.themeMode, ThemeMode.system);
    });

    testWidgets('elegir oscuro lo guarda', (WidgetTester tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Oscuro'));
      await tester.pumpAndSettle();

      expect(settings.themeMode, ThemeMode.dark);
    });
  });

  group('voz', () {
    testWidgets('cambiar la velocidad la guarda y la aplica a la voz', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      // Arrastrar el deslizador hasta el extremo lento.
      await tester.drag(find.byType(Slider), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(settings.speechRate, 0.3);
      // Cambiar el número y seguir oyendo la velocidad anterior parecería que
      // el ajuste no funciona.
      expect(tts.lastRate, isNotNull);
      expect(tts.lastRate, 0.3);
    });

    testWidgets('se puede probar la voz sin entrar en una lección', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await tts.initialize('xx-XX');

      await tester.tap(find.text('Probar la voz'));
      await tester.pumpAndSettle();

      expect(tts.spoken, isNotEmpty);
    });
  });

  group('exportar e importar', () {
    testWidgets('exportar deja el respaldo en el portapapeles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(progress: stored()));
      await tester.pumpAndSettle();

      await tapScrolled(tester, find.text('Copiar mi respaldo'));

      expect(copied, hasLength(1));
      expect(copied.single, contains('"courseId": "xx"'));
      expect(find.textContaining('Respaldo copiado'), findsOne);
    });

    testWidgets('sin progreso lo dice en lugar de copiar algo vacío', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tapScrolled(tester, find.text('Copiar mi respaldo'));

      expect(copied, isEmpty);
      expect(
        find.textContaining('Todavía no hay nada que respaldar'),
        findsOne,
      );
    });

    testWidgets('importar un respaldo válido lo fusiona', (
      WidgetTester tester,
    ) async {
      // Primero se exporta con 400 XP, luego se parte de 10 y se importa: el
      // respaldo aporta lo que falta.
      await tester.pumpWidget(wrap(progress: stored(xp: 400)));
      await tester.pumpAndSettle();
      await tapScrolled(tester, find.text('Copiar mi respaldo'));
      final String backup = copied.single;

      await tester.pumpWidget(wrap(progress: stored(xp: 10)));
      await tester.pumpAndSettle();

      await tapScrolled(tester, find.text('Importar un respaldo'));
      await tester.enterText(find.byType(TextField), backup);
      await tester.tap(find.widgetWithText(FilledButton, 'Importar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('combinado con tu avance actual'), findsOne);
      expect(progressStore.current('u1', 'xx')!.xp, 400);
    });

    testWidgets('un texto que no es respaldo se rechaza y NO toca nada', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(progress: stored()));
      await tester.pumpAndSettle();

      await tapScrolled(tester, find.text('Importar un respaldo'));
      await tester.enterText(find.byType(TextField), 'hola, soy un texto');
      await tester.tap(find.widgetWithText(FilledButton, 'Importar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('no es un respaldo válido'), findsOne);
      expect(find.textContaining('No se ha cambiado nada'), findsOne);
      expect(progressStore.current('u1', 'xx')!.xp, 150);
    });

    testWidgets('una versión futura se rechaza explicando qué hacer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(progress: stored()));
      await tester.pumpAndSettle();

      await tapScrolled(tester, find.text('Importar un respaldo'));
      await tester.enterText(
        find.byType(TextField),
        '{"backupVersion": 99, "courseId": "xx", "progress": {}}',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Importar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('una versión más nueva de la app'), findsOne);
      expect(find.textContaining('Actualiza la app'), findsOne);
    });

    testWidgets('un respaldo de otro idioma se rechaza con los dos nombres', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(progress: stored()));
      await tester.pumpAndSettle();

      await tapScrolled(tester, find.text('Importar un respaldo'));
      await tester.enterText(
        find.byType(TextField),
        '{"backupVersion": 1, "courseId": "fr", "progress": {"xp": 9999}}',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Importar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('del idioma «fr»'), findsOne);
      expect(progressStore.current('u1', 'xx')!.xp, 150);
    });

    testWidgets('cancelar el diálogo de importar no hace nada', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(progress: stored()));
      await tester.pumpAndSettle();

      await tapScrolled(tester, find.text('Importar un respaldo'));
      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(progressStore.current('u1', 'xx')!.xp, 150);
      expect(find.textContaining('No se ha cambiado nada'), findsNothing);
    });
  });

  group('borrar exige confirmación explícita (FR-046)', () {
    testWidgets('tocar borrar abre el diálogo sin borrar todavía', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(progress: stored()));
      await tester.pumpAndSettle();

      await tapScrolled(
        tester,
        find.widgetWithText(OutlinedButton, 'Borrar mi progreso'),
      );

      expect(find.text('¿Borrar tu progreso?'), findsOne);
      // Dice qué se pierde y nombra el respaldo como única vuelta atrás.
      expect(find.textContaining('racha, XP y la cola de repaso'), findsOne);
      expect(find.textContaining('no se puede deshacer'), findsOne);
      expect(find.textContaining('respaldo exportado antes'), findsOne);
      // Y todavía no se ha borrado nada.
      expect(progressStore.current('u1', 'xx'), isNotNull);
    });

    testWidgets('cancelar deja el progreso intacto', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(progress: stored()));
      await tester.pumpAndSettle();

      await tapScrolled(
        tester,
        find.widgetWithText(OutlinedButton, 'Borrar mi progreso'),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(progressStore.current('u1', 'xx'), isNotNull);
      expect(progressStore.current('u1', 'xx')!.xp, 150);
    });

    testWidgets('confirmar sí borra', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(progress: stored()));
      await tester.pumpAndSettle();

      await tapScrolled(
        tester,
        find.widgetWithText(OutlinedButton, 'Borrar mi progreso'),
      );
      await tester.tap(find.widgetWithText(TextButton, 'Borrar'));
      await tester.pumpAndSettle();

      expect(progressStore.current('u1', 'xx'), isNull);
      expect(find.textContaining('se borró'), findsOne);
    });

    testWidgets('cancelar es el botón predeterminado, no borrar', (
      WidgetTester tester,
    ) async {
      // Si alguien pulsa sin leer, no debe pasar nada: el botón relleno —el que
      // la vista empuja a pulsar— es el inofensivo.
      await tester.pumpWidget(wrap(progress: stored()));
      await tester.pumpAndSettle();

      await tapScrolled(
        tester,
        find.widgetWithText(OutlinedButton, 'Borrar mi progreso'),
      );

      expect(find.widgetWithText(FilledButton, 'Cancelar'), findsOne);
      expect(find.widgetWithText(FilledButton, 'Borrar'), findsNothing);
      expect(find.widgetWithText(TextButton, 'Borrar'), findsOne);
    });
  });

  testWidgets('cabe a 360 dp', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(progress: stored()));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

/// Idioma preseleccionado: el respaldo es por curso.
class PreselectedCourse extends SelectedCourse {
  @override
  String? build() => 'xx';
}
