/// Verifica el cableado del armazón y la puerta de autenticación.
///
/// El catálogo de prueba se construye **solo con contratos de `core`**, sin tocar
/// `lib/content/`. Que eso sea posible es la demostración de que la interfaz no
/// conoce ningún idioma concreto (Principio I).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/app.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/services/auth/auth_service.dart';
import 'package:languages_app/services/settings/settings_store.dart';
import 'package:languages_app/services/update/update_checker.dart';
import 'package:languages_app/ui/providers/auth_providers.dart';
import 'package:languages_app/ui/providers/content_providers.dart';
import 'package:languages_app/ui/providers/progress_providers.dart';
import 'package:languages_app/ui/providers/speech_providers.dart';
import 'package:languages_app/ui/providers/update_providers.dart';

import '../fakes/fake_auth_service.dart';
import '../fakes/fake_catalog.dart';
import '../fakes/fake_tts_service.dart';
import '../fakes/fake_sync_service.dart';

void main() {
  late FakeAuthService auth;
  late FakeSyncService sync;

  setUp(() {
    auth = FakeAuthService();
    sync = FakeSyncService();
  });

  tearDown(() async {
    await auth.dispose();
    await sync.dispose();
  });

  Widget buildApp({bool storageDegraded = false, ThemeMode? themeMode}) =>
      ProviderScope(
        overrides: [
          settingsStoreProvider.overrideWithValue(InMemorySettingsStore()),
          courseCatalogProvider.overrideWithValue(const FakeCatalog()),
          authServiceProvider.overrideWithValue(auth),
          syncServiceProvider.overrideWithValue(sync),
          storageDegradedProvider.overrideWithValue(storageDegraded),
          // En pruebas no hay nada publicado con qué comparar, y el
          // proveedor lanza si falta: es la regla que destapó que
          // `settingsStoreProvider` no estaba cableado.
          updateCheckerProvider.overrideWithValue(const NoUpdateChecker()),
          // La raíz observa las rutas para callar la voz al cambiar de
          // pantalla, así que necesita el servicio de voz desde el primer
          // cambio de ruta, que es el de la pantalla inicial.
          ttsServiceProvider.overrideWithValue(FakeTtsService()),
          if (themeMode != null) themeModeProvider.overrideWithValue(themeMode),
        ],
        child: const LanguagesApp(),
      );

  testWidgets('sin sesión muestra la pantalla de acceso', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('Correo electrónico'), findsOne);
    expect(find.text('Contraseña'), findsOne);
    expect(find.text('¿No tienes cuenta? Créala'), findsOne);
    expect(find.text('Olvidé mi contraseña'), findsOne);
  });

  testWidgets('con sesión muestra el catálogo que recibe', (
    WidgetTester tester,
  ) async {
    auth = FakeAuthService(
      initialUser: const StudentIdentity(uid: 'u1', email: 'a@b.com'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Elige el idioma que quieres aprender'), findsOne);
    expect(find.text('Idioma de prueba'), findsOne);
    expect(find.text('a@b.com'), findsOne);
  });

  testWidgets('entrar transita solo del acceso al inicio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    expect(find.text('Elige el idioma que quieres aprender'), findsNothing);

    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, 'secreto123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    // La transición la hace la puerta al observar la sesión: ninguna pantalla
    // navega a mano tras autenticarse.
    expect(find.text('Elige el idioma que quieres aprender'), findsOne);
  });

  testWidgets('crear cuenta entra directo, sin quedarse en el registro', (
    WidgetTester tester,
  ) async {
    // T163, reportado verificando en un iPhone: «deja crear cuenta pero la
    // pantalla se queda estática, toca ir atrás». El registro se abre con
    // `Navigator.push` sobre el acceso, así que la puerta cambiaba a la
    // pantalla de inicio **debajo** de una pantalla de registro que seguía
    // tapándola. Cronometrar SC-001 con ese rodeo no mide el flujo real.
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('¿No tienes cuenta? Créala'));
    await tester.pumpAndSettle();
    expect(find.text('Crear cuenta'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).first, 'nueva@b.com');
    await tester.enterText(find.byType(TextFormField).last, 'secreto123');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();

    expect(
      find.text('Elige el idioma que quieres aprender'),
      findsOne,
      reason: 'Crear cuenta tiene que dejar a la persona dentro de la app',
    );
    expect(
      find.byType(TextFormField),
      findsNothing,
      reason: 'La pantalla de registro no puede seguir encima',
    );
  });

  testWidgets('avisa cuando el almacenamiento está degradado', (
    WidgetTester tester,
  ) async {
    auth = FakeAuthService(
      initialUser: const StudentIdentity(uid: 'u1', email: 'a@b.com'),
    );
    await tester.pumpWidget(buildApp(storageDegraded: true));
    await tester.pumpAndSettle();

    // FR-043: el fallo tiene que ser visible, no silencioso.
    expect(find.text('Tu avance no se está guardando'), findsOne);
  });

  testWidgets('no avisa nada cuando todo va bien', (WidgetTester tester) async {
    auth = FakeAuthService(
      initialUser: const StudentIdentity(uid: 'u1', email: 'a@b.com'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Tu avance no se está guardando'), findsNothing);
    expect(find.text('Guardando tu avance…'), findsNothing);
  });

  testWidgets('respeta el modo oscuro', (WidgetTester tester) async {
    await tester.pumpWidget(buildApp(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget<MaterialApp>(
      find.byType(MaterialApp),
    );
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme, isNotNull);
  });

  testWidgets('cabe en 360 dp de ancho sin desbordes', (
    WidgetTester tester,
  ) async {
    // SC-010. Un desborde pinta la franja amarilla y registra una excepción, que
    // esta aserción convierte en fallo.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    auth = FakeAuthService(
      initialUser: const StudentIdentity(uid: 'u1', email: 'a@b.com'),
    );
    await tester.pumpWidget(buildApp(storageDegraded: true));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  test('los botones del tema garantizan el área táctil mínima', () {
    expect(minTouchTarget, 48);
    expect(
      lightTheme.filledButtonTheme.style?.minimumSize
          ?.resolve(<WidgetState>{})
          ?.height,
      minTouchTarget,
    );
  });
}
