/// Preferencias del dispositivo.
///
/// No se sincronizan: el modo oscuro y la velocidad de la voz son del aparato,
/// no del estudiante. Alguien puede querer modo claro en el PC y oscuro en el
/// teléfono, y sincronizarlo sería una molestia, no una ventaja.
///
/// Se declara como contrato para que las pruebas usen una implementación en
/// memoria sin tocar el almacenamiento del sistema. La de producción es
/// `prefs_settings_store.dart`.
///
/// Los **getters son sincrónicos** a propósito: el tema se lee al construir
/// cada widget, y una lectura asíncrona ahí obligaría a toda la interfaz a
/// esperar por un valor que ya se conoce. Quien implemente este contrato carga
/// una vez al arrancar y responde de memoria después.
library;

import 'package:flutter/material.dart';

/// Velocidad de lectura por defecto.
const double defaultSpeechRate = 0.9;

/// Límites de la velocidad de voz.
///
/// Por debajo de [minSpeechRate] la voz se vuelve ininteligible, que es peor
/// que una voz rápida, y permitirlo solo daría una forma de romper los
/// ejercicios de escucha. Están aquí y no en cada implementación porque antes
/// estaban escritos dos veces y nada garantizaba que coincidieran.
const double minSpeechRate = 0.3;
const double maxSpeechRate = 1.0;

abstract interface class SettingsStore {
  ThemeMode get themeMode;
  Future<void> setThemeMode(ThemeMode mode);

  /// Velocidad de la síntesis de voz, entre [minSpeechRate] y [maxSpeechRate].
  double get speechRate;
  Future<void> setSpeechRate(double rate);
}

/// Implementación en memoria.
///
/// Es la que usan las pruebas, y también la reserva si el almacenamiento de
/// preferencias falla: perder el modo oscuro es un inconveniente, no una razón
/// para no arrancar.
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore({
    ThemeMode themeMode = ThemeMode.system,
    double speechRate = defaultSpeechRate,
  }) : _themeMode = themeMode,
       _speechRate = speechRate;

  ThemeMode _themeMode;
  double _speechRate;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async => _themeMode = mode;

  @override
  double get speechRate => _speechRate;

  @override
  Future<void> setSpeechRate(double rate) async =>
      _speechRate = rate.clamp(minSpeechRate, maxSpeechRate);
}
