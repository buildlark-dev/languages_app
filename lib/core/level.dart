/// Un nivel del Marco Común Europeo de Referencia, **con contenido**.
///
/// Los niveles anunciados pero sin contenido construido NO son [Level]: se
/// declaran como identificadores en `Course.upcomingLevelIds`. Un `Level` sin
/// módulos violaría las invariantes del contrato de contenido, y además tener
/// objetos vacíos abriría la puerta a que la interfaz permitiera entrar en
/// ellos. Si el dato no existe, no hay ruta que bloquear.
library;

import 'exam.dart';
import 'module.dart';

class Level {
  const Level({
    required this.id,
    required this.name,
    required this.description,
    required this.modules,
    required this.levelExam,
  });

  /// Uno de `A1`, `A2`, `B1`, `B2`, `C1`, `C2`.
  final String id;

  /// Ej.: "A1 · Fundamentos".
  final String name;

  /// Qué habilita el nivel, en español.
  final String description;

  /// En orden ascendente por `order`, sin huecos.
  final List<Module> modules;

  /// Obligatorio: es la puerta al nivel siguiente.
  final Exam levelExam;

  /// Busca un módulo por su identificador.
  Module? moduleById(String moduleId) {
    for (final Module module in modules) {
      if (module.id == moduleId) return module;
    }
    return null;
  }

  /// El módulo que sigue al dado, o nulo si era el último.
  Module? moduleAfter(String moduleId) {
    final int index = modules.indexWhere((Module m) => m.id == moduleId);
    if (index < 0 || index + 1 >= modules.length) return null;
    return modules[index + 1];
  }
}
