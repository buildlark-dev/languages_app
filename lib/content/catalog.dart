/// El catálogo de idiomas disponibles.
///
/// Este es el **único** archivo del proyecto que importa un paquete de contenido
/// concreto, y `lib/main.dart` es el único que lo importa a él. Esa cadena de dos
/// eslabones es lo que hace cierto el Principio I: ni el motor ni la interfaz
/// saben que existe el inglés.
///
/// Añadir francés es, exactamente:
///
/// 1. Crear `lib/content/fr/` con sus módulos.
/// 2. Implementar `ContentPack` en `french_course.dart`.
/// 3. Añadir una línea a [packs].
/// 4. Crear su prueba de integridad.
///
/// Nada de `lib/core/`, `lib/engine/`, `lib/services/` ni `lib/ui/` cambia, y
/// SC-011 lo verifica.
library;

import '../core/content_pack.dart';
import 'en/english_course.dart';

class AppCourseCatalog implements CourseCatalog {
  const AppCourseCatalog();

  @override
  List<ContentPack> get packs => const <ContentPack>[EnglishContentPack()];

  @override
  ContentPack? packFor(String courseId) {
    for (final ContentPack pack in packs) {
      if (pack.courseId == courseId) return pack;
    }
    return null;
  }
}
