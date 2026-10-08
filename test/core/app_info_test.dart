/// Verifica que la versión declarada en código no se desfase de pubspec.yaml.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/app_info.dart';

void main() {
  test('appVersion coincide con la versión de pubspec.yaml', () {
    // Es el guardia de la constante copiada a mano: `app_info.dart` evita una
    // dependencia solo para leer una cadena, y esta prueba paga el precio de esa
    // decisión. Sin ella, un respaldo diría que lo escribió una versión que no
    // existe.
    final List<String> lines = File('pubspec.yaml').readAsLinesSync();
    final String versionLine = lines.firstWhere(
      (String line) => line.startsWith('version:'),
      orElse: () => '',
    );

    expect(versionLine, isNotEmpty, reason: 'pubspec.yaml declara version:');

    // `1.0.0+1` en pubspec; en código va sin el número de compilación.
    final String declared = versionLine
        .substring('version:'.length)
        .trim()
        .split('+')
        .first;

    expect(appVersion, declared);
  });
}
