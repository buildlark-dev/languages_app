/// Que el aviso de versión nueva se ofrezca sin interrumpir.
///
/// La regla que fija esta prueba es de producto: **se ofrece, no se recarga**.
/// Recargar sola es lo que hace la mayoría de las PWA y aquí sería un error:
/// perder el ejercicio a medias por una mejora de la app es de las cosas que
/// hacen cerrarla y no volver.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/services/update/update_checker.dart';
import 'package:languages_app/ui/providers/update_providers.dart';
import 'package:languages_app/ui/widgets/update_overlay.dart';

class _FakeUpdateChecker implements UpdateChecker {
  _FakeUpdateChecker({this.available = false});

  final bool available;
  int applyCount = 0;

  @override
  Future<bool> isUpdateAvailable() async => available;

  @override
  Future<void> apply() async => applyCount++;
}

void main() {
  Widget wrap(_FakeUpdateChecker checker) => ProviderScope(
    overrides: [
      updateCheckerProvider.overrideWithValue(checker),
      // Sin identificador de compilación el proveedor se queda callado, que
      // es lo correcto en pruebas y en `flutter run`. Aquí se enciende.
      updateAvailableProvider.overrideWith(
        () => UpdateAvailability(enabled: true),
      ),
    ],
    child: MaterialApp(
      home: const Scaffold(body: Text('una lección a medias')),
      builder: (BuildContext context, Widget? child) =>
          UpdateOverlay(child: child ?? const SizedBox.shrink()),
    ),
  );

  testWidgets('sin versión nueva no se ve nada', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(_FakeUpdateChecker()));
    await tester.pumpAndSettle();

    expect(find.textContaining('versión nueva'), findsNothing);
    expect(find.text('una lección a medias'), findsOne);
  });

  testWidgets('con versión nueva se ofrece, y lo de debajo sigue ahí', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(_FakeUpdateChecker(available: true)));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hay una versión nueva'), findsOne);
    // Lo importante: no tapa ni sustituye la pantalla. Es una oferta.
    expect(find.text('una lección a medias'), findsOne);
    expect(find.text('Actualizar'), findsOne);
    expect(find.text('Luego'), findsOne);
  });

  testWidgets('«Luego» lo quita sin actualizar', (WidgetTester tester) async {
    final _FakeUpdateChecker checker = _FakeUpdateChecker(available: true);
    await tester.pumpWidget(wrap(checker));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Luego'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Hay una versión nueva'), findsNothing);
    expect(
      checker.applyCount,
      0,
      reason: 'Descartar el aviso no puede recargar la app',
    );
  });

  testWidgets('«Actualizar» se queda con la versión publicada', (
    WidgetTester tester,
  ) async {
    final _FakeUpdateChecker checker = _FakeUpdateChecker(available: true);
    await tester.pumpWidget(wrap(checker));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    expect(checker.applyCount, 1);
  });

  testWidgets('el aviso cabe a 360 dp con la fuente al 130 %', (
    WidgetTester tester,
  ) async {
    // Principio VII: móvil primero desde 360 dp, y la fuente del sistema puede
    // estar aumentada. Un aviso que desborda tapa el contenido en lugar de
    // ofrecer algo.
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          updateCheckerProvider.overrideWithValue(
            _FakeUpdateChecker(available: true),
          ),
          updateAvailableProvider.overrideWith(
            () => UpdateAvailability(enabled: true),
          ),
        ],
        child: MaterialApp(
          home: const Scaffold(body: SizedBox.shrink()),
          builder: (BuildContext context, Widget? child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 1.3,
            maxScaleFactor: 1.3,
            child: UpdateOverlay(child: child ?? const SizedBox.shrink()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Actualizar'), findsOne);
  });
}
