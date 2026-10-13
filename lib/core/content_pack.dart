/// El contrato que todo idioma debe implementar.
///
/// Este archivo es lo que hace cumplible el Principio I. El motor y la interfaz
/// dependen de esta abstracción; **nunca** de `lib/content/en/` ni de ningún
/// otro paquete concreto.
///
/// Añadir francés o portugués consiste en implementar esta clase y registrarla
/// en el catálogo. Ni `lib/core/`, ni `lib/engine/`, ni `lib/services/`, ni
/// `lib/ui/` cambian una línea, y SC-011 lo verifica.
library;

import 'course.dart';

abstract interface class ContentPack {
  /// Código ISO del idioma. Único en el catálogo.
  String get courseId;

  /// El curso completo: niveles con contenido y niveles anunciados.
  Course get course;
}

/// El catálogo de cursos disponibles.
///
/// Se declara aquí, en la capa de contratos, para que la interfaz pueda
/// consumirlo sin importar `lib/content/`. La implementación concreta
/// —`lib/content/catalog.dart`, el único archivo que conoce los idiomas— se
/// inyecta desde `lib/main.dart`.
abstract interface class CourseCatalog {
  /// Los paquetes disponibles, en el orden en que se ofrecen.
  List<ContentPack> get packs;

  /// Busca un paquete por el código de su idioma.
  ContentPack? packFor(String courseId);
}
