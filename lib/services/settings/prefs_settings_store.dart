/// Preferencias del dispositivo, guardadas con `shared_preferences`.
///
/// ## Por qué no una tabla de drift
///
/// `plan.md` rechaza `shared_preferences` y elige drift, pero ese rechazo era
/// **para el progreso**: lo que faltaba era esquema versionado, migraciones y
/// consultas por fecha de vencimiento. Dos escalares del aparato no necesitan
/// nada de eso, y una tabla nueva obligaría a subir `appSchemaVersion`, escribir
/// un paso de migración y demostrar en una prueba que no se perdió progreso
/// —el Principio IV— por el modo oscuro.
///
/// Hay además una razón de forma que decide sola: [SettingsStore] expone
/// **getters sincrónicos**, porque el tema se lee al construir cada widget.
/// Drift es asíncrono de arriba abajo y obligaría a mantener una caché en
/// memoria por delante. `SharedPreferences` ya funciona así: una carga
/// asíncrona en el arranque y lecturas sincrónicas después.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_store.dart';

/// Claves con prefijo para no chocar con nada que escriba un plugin.
const String _themeKey = 'languages_app.themeMode';
const String _rateKey = 'languages_app.speechRate';

class PrefsSettingsStore implements SettingsStore {
  const PrefsSettingsStore(this._prefs);

  final SharedPreferences _prefs;

  /// Abre el almacén. Lo llama `main.dart` antes de arrancar la interfaz.
  static Future<SettingsStore> open() async =>
      PrefsSettingsStore(await SharedPreferences.getInstance());

  @override
  ThemeMode get themeMode {
    final String? stored = _prefs.getString(_themeKey);
    // Un valor desconocido —de una versión futura con más modos— degrada al del
    // sistema en lugar de lanzar. Perder la preferencia es un inconveniente;
    // no arrancar, no.
    return switch (stored) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async =>
      _prefs.setString(_themeKey, mode.name);

  @override
  double get speechRate => _prefs.getDouble(_rateKey) ?? defaultSpeechRate;

  /// Se acota aquí igual que en el almacén en memoria: por debajo de 0,3 la voz
  /// se vuelve ininteligible, y un valor fuera de rango puede llegar de una
  /// versión anterior o de un archivo de preferencias manipulado.
  @override
  Future<void> setSpeechRate(double rate) async =>
      _prefs.setDouble(_rateKey, rate.clamp(minSpeechRate, maxSpeechRate));
}
