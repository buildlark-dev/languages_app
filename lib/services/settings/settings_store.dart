/// Preferencias del dispositivo.
///
/// No se sincronizan: el modo oscuro y la velocidad de la voz son del aparato,
/// no del estudiante. Alguien puede querer modo claro en el PC y oscuro en el
/// teléfono, y sincronizarlo sería una molestia, no una ventaja.
///
/// Se declara como contrato para que las pruebas usen una implementación en
/// memoria sin tocar el almacenamiento del sistema.
///
// ignore_for_file: prefer_initializing_formals
// El lint sugiere `this._campo` en el constructor, pero Dart no admite
// parámetros nombrados que empiecen por guion bajo, así que la forma que
// propone no compila con campos privados.
library;

import 'package:flutter/material.dart';

abstract interface class SettingsStore {
  ThemeMode get themeMode;
  Future<void> setThemeMode(ThemeMode mode);

  /// Velocidad de la síntesis de voz, de 0.0 a 1.0.
  double get speechRate;
  Future<void> setSpeechRate(double rate);

  /// Último curso elegido, para volver a él al abrir la app.
  String? get lastCourseId;
  Future<void> setLastCourseId(String courseId);
}

/// Implementación en memoria.
///
/// Es la que usan las pruebas, y también sirve de reserva si el almacenamiento
/// de preferencias falla: perder el modo oscuro es un inconveniente, no una
/// razón para no arrancar.
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore({
    ThemeMode themeMode = ThemeMode.system,
    double speechRate = 0.9,
    String? lastCourseId,
  }) : _themeMode = themeMode,
       _speechRate = speechRate,
       _lastCourseId = lastCourseId;

  ThemeMode _themeMode;
  double _speechRate;
  String? _lastCourseId;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  Future<void> setThemeMode(ThemeMode mode) async => _themeMode = mode;

  @override
  double get speechRate => _speechRate;

  /// La velocidad se acota entre 0.3 y 1.0.
  ///
  /// Por debajo de 0.3 la voz se vuelve ininteligible, que es peor que una voz
  /// rápida, y permitirlo solo daría una forma de romper los ejercicios de
  /// escucha.
  @override
  Future<void> setSpeechRate(double rate) async =>
      _speechRate = rate.clamp(0.3, 1.0);

  @override
  String? get lastCourseId => _lastCourseId;

  @override
  Future<void> setLastCourseId(String courseId) async =>
      _lastCourseId = courseId;
}
