/// Verifica que las preferencias sobreviven al cierre de la app.
///
/// Es la prueba que faltaba: el almacén en memoria pasaba todas las de la
/// pantalla de ajustes, y aun así el tema se reiniciaba en cada arranque porque
/// en producción no había ninguna implementación que guardara nada.
///
/// `setMockInitialValues` sustituye el canal de plataforma, de modo que lo que
/// se ejercita es la clase real contra un almacén real en memoria, no un doble
/// escrito por mí que podría ser más complaciente que el de verdad.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/services/settings/prefs_settings_store.dart';
import 'package:languages_app/services/settings/settings_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  Future<SettingsStore> open() => PrefsSettingsStore.open();

  group('valores de partida', () {
    test('sin nada guardado, el tema sigue al del sistema', () async {
      final SettingsStore store = await open();

      expect(store.themeMode, ThemeMode.system);
      expect(store.speechRate, defaultSpeechRate);
    });
  });

  group('el tema sobrevive al cierre', () {
    test('elegir oscuro y volver a abrir lo conserva', () async {
      final SettingsStore first = await open();
      await first.setThemeMode(ThemeMode.dark);

      // Una instancia nueva es lo más parecido a reabrir la app.
      final SettingsStore second = await open();
      expect(second.themeMode, ThemeMode.dark);
    });

    test('los tres modos van y vuelven', () async {
      for (final ThemeMode mode in ThemeMode.values) {
        final SettingsStore store = await open();
        await store.setThemeMode(mode);
        expect((await open()).themeMode, mode);
      }
    });

    test('un modo desconocido degrada al del sistema, no lanza', () async {
      // Lo escribiría una versión futura con más modos. Perder la preferencia
      // es un inconveniente; no arrancar, no.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'languages_app.themeMode': 'sepia',
      });

      expect((await open()).themeMode, ThemeMode.system);
    });
  });

  group('la velocidad de voz sobrevive y se acota', () {
    test('se guarda y se recupera', () async {
      await (await open()).setSpeechRate(0.5);

      expect((await open()).speechRate, 0.5);
    });

    test('un valor por debajo del mínimo se recorta al guardar', () async {
      // Por debajo de 0,3 la voz es ininteligible, y permitirlo sería una forma
      // de romper los ejercicios de escucha.
      await (await open()).setSpeechRate(0.05);

      expect((await open()).speechRate, minSpeechRate);
    });

    test('un valor por encima del máximo también', () async {
      await (await open()).setSpeechRate(4);

      expect((await open()).speechRate, maxSpeechRate);
    });
  });

  group('el contrato no promete lo que no cumple', () {
    test('el almacén en memoria y el persistente parten igual', () async {
      // Si divergieran, las pruebas de la pantalla de ajustes estarían
      // comprobando un comportamiento que en producción no ocurre, que es
      // exactamente lo que pasó con la persistencia.
      final SettingsStore persistent = await open();
      final SettingsStore inMemory = InMemorySettingsStore();

      expect(persistent.themeMode, inMemory.themeMode);
      expect(persistent.speechRate, inMemory.speechRate);
    });

    test('ambos acotan la velocidad igual', () async {
      final SettingsStore persistent = await open();
      final SettingsStore inMemory = InMemorySettingsStore();

      await persistent.setSpeechRate(9);
      await inMemory.setSpeechRate(9);
      expect((await open()).speechRate, inMemory.speechRate);

      await persistent.setSpeechRate(-1);
      await inMemory.setSpeechRate(-1);
      expect((await open()).speechRate, inMemory.speechRate);
    });
  });
}
