/// Elige qué voz concreta debe leer el inglés.
///
/// ## Por qué no basta con `setLanguage`
///
/// Medido en el navegador con la app desplegada: hay cinco voces inglesas
/// instaladas, **ninguna** marcada como predeterminada, y la voz por defecto
/// del navegador es `es-ES Microsoft Helena`, porque el documento se declara
/// `lang="es"`. Si fijar el idioma no acaba de fijar la voz, el inglés se lee
/// con voz española: **suena**, así que ninguna detección lo nota, y enseña una
/// pronunciación equivocada. En una app de idiomas eso es peor que el silencio,
/// porque el silencio se ve y esto no.
///
/// Función pura y en su propio archivo para poder probarla sin motor de voz: la
/// lista de voces de un dispositivo no se puede fabricar en una prueba, pero la
/// decisión sí.
library;

/// Una voz elegida, en el formato que espera `flutter_tts.setVoice`.
typedef VoiceChoice = Map<String, String>;

/// La mejor voz de [voices] para [languageTag], o `null` si no hay ninguna.
///
/// Orden de preferencia:
///
/// 1. Coincidencia exacta de etiqueta (`en-US` para contenido en `en-US`).
/// 2. Cualquier voz del mismo idioma (`en-GB`, `en_AU`): para A1 sirve igual, y
///    ser estricto dejaría sin audio a mucha gente que sí tiene voz en inglés.
/// 3. Nada. Quien llama debe entonces conformarse con `setLanguage` o avisar.
///
/// Entre varias candidatas del mismo rango se queda con la primera, que es el
/// orden en que el sistema las ofrece. No se intenta adivinar cuál suena mejor:
/// eso depende del dispositivo y no hay dato en la lista que lo diga.
VoiceChoice? pickVoice(List<Object?> voices, String languageTag) {
  final String wanted = _normalize(languageTag);
  final String prefix = wanted.split('-').first;

  VoiceChoice? sameLanguage;

  for (final Object? entry in voices) {
    if (entry is! Map) continue;

    final String name = '${entry['name'] ?? ''}';
    final String locale = '${entry['locale'] ?? ''}';
    if (name.isEmpty || locale.isEmpty) continue;

    final String normalized = _normalize(locale);
    final VoiceChoice choice = <String, String>{
      'name': name,
      'locale': locale,
    };

    if (normalized == wanted) return choice;
    // La primera del idioma se guarda, pero se sigue buscando: una
    // coincidencia exacta más adelante en la lista debe ganar.
    sameLanguage ??= normalized.split('-').first == prefix ? choice : null;
  }

  return sameLanguage;
}

/// `en_US`, `en-us` y `en-US` son la misma etiqueta.
String _normalize(String tag) => tag.trim().toLowerCase().replaceAll('_', '-');
