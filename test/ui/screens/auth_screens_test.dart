/// Verifica las pantallas de cuenta: los ocho errores, que no se pierde lo
/// escrito, y la advertencia al cerrar sesión.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/l10n/app_localizations.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/core/sync_state.dart';
import 'package:languages_app/services/auth/auth_service.dart';
import 'package:languages_app/ui/providers/auth_providers.dart';
import 'package:languages_app/ui/providers/progress_providers.dart';
import 'package:languages_app/ui/screens/password_reset_screen.dart';
import 'package:languages_app/ui/screens/sign_in_screen.dart';
import 'package:languages_app/ui/screens/sign_up_screen.dart';
import 'package:languages_app/ui/widgets/sign_out_button.dart';

import '../../fakes/fake_auth_service.dart';
import '../../fakes/fake_sync_service.dart';

/// El mensaje en español que corresponde a cada fallo.
const Map<AuthFailure, String> expectedMessage = <AuthFailure, String>{
  AuthFailure.invalidEmail: 'Ese correo no parece válido.',
  AuthFailure.weakPassword:
      'La contraseña es demasiado corta. Usa al menos seis caracteres.',
  AuthFailure.emailAlreadyInUse:
      'Ya existe una cuenta con ese correo. Prueba a entrar.',
  AuthFailure.wrongCredentials: 'El correo o la contraseña no coinciden.',
  AuthFailure.userNotFound: 'No encontramos ninguna cuenta con ese correo.',
  AuthFailure.tooManyAttempts:
      'Demasiados intentos. Espera unos minutos y vuelve a probar.',
  AuthFailure.unknown: 'Algo falló. Vuelve a intentarlo.',
};

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

  Widget wrap(Widget child, {SyncNotice? notice}) => ProviderScope(
    overrides: [
      authServiceProvider.overrideWithValue(auth),
      syncServiceProvider.overrideWithValue(sync),
      if (notice != null) syncNoticeProvider.overrideWithValue(notice),
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
      home: child,
    ),
  );

  Future<void> submitSignIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).first, 'a@b.com');
    await tester.enterText(find.byType(TextFormField).last, 'secreto123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
  }

  group('cada fallo tiene su propio mensaje (FR-004)', () {
    for (final MapEntry<AuthFailure, String> entry in expectedMessage.entries) {
      testWidgets('${entry.key.name} muestra su texto', (
        WidgetTester tester,
      ) async {
        auth.failWith = entry.key;
        await tester.pumpWidget(wrap(const SignInScreen()));
        await tester.pumpAndSettle();
        await submitSignIn(tester);

        expect(find.text(entry.value), findsOne);
      });
    }

    testWidgets('noConnection explica que solo hace falta la primera vez', (
      WidgetTester tester,
    ) async {
      // Es el caso borde que introduce la cuenta obligatoria: sin el matiz de que
      // después se puede estudiar sin internet, alguien abandona creyendo que la
      // app exige conexión siempre.
      auth.failWith = AuthFailure.noConnection;
      await tester.pumpWidget(wrap(const SignInScreen()));
      await tester.pumpAndSettle();
      await submitSignIn(tester);

      expect(find.textContaining('Sin conexión'), findsOne);
      expect(find.textContaining('después podrás estudiar sin él'), findsOne);
    });
  });

  testWidgets('al fallar NO se pierde lo que la persona escribió', (
    WidgetTester tester,
  ) async {
    auth.failWith = AuthFailure.wrongCredentials;
    await tester.pumpWidget(wrap(const SignInScreen()));
    await tester.pumpAndSettle();
    await submitSignIn(tester);

    expect(find.text('El correo o la contraseña no coinciden.'), findsOne);
    // FR-004: reintentar no debe obligar a teclear otra vez el correo.
    expect(find.text('a@b.com'), findsOne);
  });

  testWidgets('escribir de nuevo descarta el error anterior', (
    WidgetTester tester,
  ) async {
    auth.failWith = AuthFailure.wrongCredentials;
    await tester.pumpWidget(wrap(const SignInScreen()));
    await tester.pumpAndSettle();
    await submitSignIn(tester);
    expect(find.text('El correo o la contraseña no coinciden.'), findsOne);

    await tester.enterText(find.byType(TextFormField).last, 'otra');
    await tester.pumpAndSettle();

    expect(find.text('El correo o la contraseña no coinciden.'), findsNothing);
  });

  testWidgets('no envía nada con los campos vacíos', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(const SignInScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(auth.calls, isEmpty);
  });

  group('registro', () {
    testWidgets('solo pide correo y contraseña, y lo dice (FR-006)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));
      await tester.pumpAndSettle();

      expect(
        find.text('Solo pedimos correo y contraseña. Nada más.'),
        findsOne,
      );
      expect(
        find.byType(TextFormField),
        findsExactly(2),
        reason: 'Ningún campo de nombre, teléfono ni fecha de nacimiento',
      );
    });

    testWidgets('crea la cuenta con los datos recortados', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(const SignUpScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '  a@b.com  ');
      await tester.enterText(find.byType(TextFormField).last, 'secreto123');
      await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('signUp:a@b.com'));
    });
  });

  group('restablecer contraseña', () {
    testWidgets('confirma el envío y menciona la carpeta de spam', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(const PasswordResetScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'a@b.com');
      await tester.tap(
        find.widgetWithText(FilledButton, 'Enviar instrucciones'),
      );
      await tester.pumpAndSettle();

      expect(auth.calls, contains('reset:a@b.com'));
      expect(find.textContaining('carpeta de spam'), findsOne);
    });

    testWidgets('una cuenta inexistente muestra su propio mensaje', (
      WidgetTester tester,
    ) async {
      auth.failWith = AuthFailure.userNotFound;
      await tester.pumpWidget(wrap(const PasswordResetScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'nadie@b.com');
      await tester.tap(
        find.widgetWithText(FilledButton, 'Enviar instrucciones'),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No encontramos ninguna cuenta con ese correo.'),
        findsOne,
      );
    });
  });

  group('cerrar sesión avisa antes (FR-005)', () {
    Future<void> openDialog(WidgetTester tester, SyncNotice notice) async {
      await tester.pumpWidget(
        wrap(
          const Scaffold(appBar: null, body: SignOutButton()),
          notice: notice,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
    }

    testWidgets('sin cambios pendientes tranquiliza', (
      WidgetTester tester,
    ) async {
      await openDialog(tester, SyncNotice.none);

      expect(find.text('¿Cerrar sesión?'), findsOne);
      expect(find.textContaining('está respaldado en la nube'), findsOne);
    });

    testWidgets('con cambios pendientes advierte de la pérdida', (
      WidgetTester tester,
    ) async {
      await openDialog(tester, SyncNotice.pending);

      // El mensaje cambia a propósito: una advertencia idéntica en los dos casos
      // se vuelve ruido que la gente aprende a ignorar.
      expect(find.textContaining('todavía no llegó a la nube'), findsOne);
      expect(find.textContaining('lo perderás'), findsOne);
    });

    testWidgets('cancelar no cierra la sesión', (WidgetTester tester) async {
      await openDialog(tester, SyncNotice.pending);

      await tester.tap(find.widgetWithText(TextButton, 'Cancelar'));
      await tester.pumpAndSettle();

      expect(auth.calls, isNot(contains('signOut')));
    });

    testWidgets('confirmar sí cierra la sesión', (WidgetTester tester) async {
      await openDialog(tester, SyncNotice.none);

      await tester.tap(find.widgetWithText(FilledButton, 'Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(auth.calls, contains('signOut'));
    });
  });

  testWidgets('el aviso de sincronización fallida se muestra', (
    WidgetTester tester,
  ) async {
    // FR-043: un fallo al guardar que no se ve es peor que uno que se ve.
    await tester.pumpWidget(
      wrap(const Scaffold(body: SignOutButton()), notice: SyncNotice.failed),
    );
    await tester.pumpAndSettle();

    expect(sync.currentStatus, isA<SyncState>());
  });
}
