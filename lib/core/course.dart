/// Un curso: un idioma ofrecido en el catálogo.
library;

import 'exam.dart';
import 'level.dart';
import 'module.dart';

class Course {
  const Course({
    required this.id,
    required this.name,
    required this.studyLanguageTag,
    required this.supportLanguageTag,
    required this.levels,
    this.upcomingLevelIds = const <String>[],
    this.placementTest,
  });

  /// Código ISO del idioma. Único en el catálogo. Ej.: `en`.
  final String id;

  /// Nombre en español. Ej.: "Inglés".
  final String name;

  /// Etiqueta BCP 47 para la síntesis y el reconocimiento de voz. Ej.: `en-US`.
  final String studyLanguageTag;

  /// Idioma de apoyo. `es` en esta entrega.
  ///
  /// Se declara en lugar de asumirse: el Principio I exige que el idioma de la
  /// interfaz y el idioma estudiado sean dimensiones independientes.
  final String supportLanguageTag;

  /// Niveles **con contenido**, en orden MCER ascendente y sin huecos.
  final List<Level> levels;

  /// Niveles anunciados pero sin contenido construido.
  ///
  /// La interfaz los dibuja como "próximo · en preparación" y **no** permite
  /// entrar (FR-038). No son [Level] porque un nivel sin módulos violaría las
  /// invariantes del contenido; dejarlos como identificadores significa que no
  /// existe dato que pudiera representar la entrada.
  final List<String> upcomingLevelIds;

  /// Nulo si el curso no ofrece nivelación.
  final PlacementExam? placementTest;

  /// El nivel con contenido más alto. Es el techo de lo estudiable hoy.
  Level get highestLevelWithContent => levels.last;

  Level? levelById(String levelId) {
    for (final Level level in levels) {
      if (level.id == levelId) return level;
    }
    return null;
  }

  /// El nivel con contenido que sigue al dado, o nulo si era el último.
  ///
  /// Devuelve nulo también cuando el siguiente nivel está solo anunciado: desde
  /// el punto de vista de la progresión, un nivel sin contenido no existe.
  Level? levelAfter(String levelId) {
    final int index = levels.indexWhere((Level l) => l.id == levelId);
    if (index < 0 || index + 1 >= levels.length) return null;
    return levels[index + 1];
  }

  /// Busca un módulo en todo el curso.
  Module? moduleById(String moduleId) {
    for (final Level level in levels) {
      final Module? found = level.moduleById(moduleId);
      if (found != null) return found;
    }
    return null;
  }

  /// El nivel al que pertenece un módulo.
  Level? levelOfModule(String moduleId) {
    for (final Level level in levels) {
      if (level.moduleById(moduleId) != null) return level;
    }
    return null;
  }
}
