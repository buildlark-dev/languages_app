/// Que la app sepa que hay una versión nueva, y que no se lo invente.
///
/// Existe porque la app desplegada quedó congelada en los dispositivos que ya
/// la tenían. Arreglar las cabeceras de caché era necesario y no suficiente:
/// una PWA instalada no se cierra nunca, y el navegador solo cambia de versión
/// cuando se cierran todas las ventanas.
///
/// La regla que se fija aquí: **no saberlo no es una actualización**. Un aviso
/// que aparece sin que haya nada nuevo enseña a ignorar el aviso.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/services/update/update_checker.dart';
import 'package:languages_app/ui/providers/update_providers.dart';

class _FakeUpdateChecker implements UpdateChecker {
  _FakeUpdateChecker({this.available = false});

  bool available;
  int applyCount = 0;
  int askedCount = 0;

  @override
  Future<bool> isUpdateAvailable() async {
    askedCount++;
    return available;
  }

  @override
  Future<void> apply() async => applyCount++;
}

void main() {
  test('en Android y escritorio no hay nada que actualizar desde la app', () async {
    // Allí la versión la cambia la tienda o el paquete. Contestar «no hay
    // nada» es la respuesta correcta, no una carencia.
    const UpdateChecker checker = NoUpdateChecker();
    expect(await checker.isUpdateAvailable(), isFalse);
    await checker.apply();
  });

  test('el estado empieza en «no hay nada» y se comprueba solo', () async {
    final _FakeUpdateChecker checker = _FakeUpdateChecker(available: true);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        updateCheckerProvider.overrideWithValue(checker),
        // En pruebas no hay identificador de compilación, así que el
        // proveedor se queda callado por defecto: aquí se enciende a mano.
        updateAvailableProvider.overrideWith(
          () => UpdateAvailability(enabled: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Hay que escuchar: todos los proveedores se autodescartan, y uno que nadie
    // observa se desecha a mitad de la comprobación.
    container.listen<bool>(updateAvailableProvider, (_, _) {});

    expect(
      container.read(updateAvailableProvider),
      isFalse,
      reason: 'Antes de preguntar, la respuesta honesta es que no hay nada',
    );

    // La comprobación se lanza después de construir, no durante.
    await Future<void>.delayed(Duration.zero);
    expect(checker.askedCount, 1);
    expect(container.read(updateAvailableProvider), isTrue);
  });

  test('comprobar otra vez refleja lo que haya publicado', () async {
    final _FakeUpdateChecker checker = _FakeUpdateChecker();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        updateCheckerProvider.overrideWithValue(checker),
        // En pruebas no hay identificador de compilación, así que el
        // proveedor se queda callado por defecto: aquí se enciende a mano.
        updateAvailableProvider.overrideWith(
          () => UpdateAvailability(enabled: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen<bool>(updateAvailableProvider, (_, _) {});

    await Future<void>.delayed(Duration.zero);
    expect(container.read(updateAvailableProvider), isFalse);

    // Se publica algo mientras la app está abierta, que es el caso que hay que
    // cubrir en una PWA instalada.
    checker.available = true;
    await container.read(updateAvailableProvider.notifier).check();

    expect(container.read(updateAvailableProvider), isTrue);
  });

  test('se vuelve a preguntar cada cierto tiempo', () async {
    // Depender solo de «la app vuelve a primer plano» resultó frágil: en una
    // pestaña que nunca se oculta ese evento no llega nunca, y el aviso no
    // aparecía hasta cerrar y abrir. Una PWA instalada puede pasar días así.
    final _FakeUpdateChecker checker = _FakeUpdateChecker();
    final ProviderContainer container = ProviderContainer(
      overrides: [
        updateCheckerProvider.overrideWithValue(checker),
        updateAvailableProvider.overrideWith(
          () => UpdateAvailability(
            enabled: true,
            every: const Duration(milliseconds: 20),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen<bool>(updateAvailableProvider, (_, _) {});

    await Future<void>.delayed(const Duration(milliseconds: 70));

    expect(
      checker.askedCount,
      greaterThan(1),
      reason: 'La primera es la del arranque; tiene que haber más',
    );
  });

  test('sin identificador de compilación no se pregunta nada', () async {
    // Es el caso de flutter run y el de las pruebas: no hay nada publicado
    // con qué comparar, y un temporizador vivo en ese caso solo deja basura.
    final _FakeUpdateChecker checker = _FakeUpdateChecker(available: true);
    final ProviderContainer container = ProviderContainer(
      overrides: [updateCheckerProvider.overrideWithValue(checker)],
    );
    addTearDown(container.dispose);
    container.listen<bool>(updateAvailableProvider, (_, _) {});

    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(checker.askedCount, 0);
    expect(container.read(updateAvailableProvider), isFalse);
  });

  test('aplicar delega en el comprobador', () async {
    final _FakeUpdateChecker checker = _FakeUpdateChecker(available: true);
    final ProviderContainer container = ProviderContainer(
      overrides: [
        updateCheckerProvider.overrideWithValue(checker),
        // En pruebas no hay identificador de compilación, así que el
        // proveedor se queda callado por defecto: aquí se enciende a mano.
        updateAvailableProvider.overrideWith(
          () => UpdateAvailability(enabled: true),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen<bool>(updateAvailableProvider, (_, _) {});

    await container.read(updateAvailableProvider.notifier).apply();
    expect(checker.applyCount, 1);
  });
}
