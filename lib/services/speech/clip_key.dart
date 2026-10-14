/// La clave con la que se busca el audio grabado de un texto.
///
/// El generador y la app tienen que coincidir **exactamente**, o el clip existe
/// y nadie lo encuentra. Por eso la normalización vive aquí, en un solo sitio,
/// y la importan los dos: el script que genera los archivos y el servicio que
/// los reproduce.
///
/// Se normaliza poco y a propósito: espacios de sobra y mayúsculas no cambian
/// cómo se pronuncia una frase, pero la puntuación sí —«Hello» y «Hello!» se
/// dicen distinto— así que se conserva.
library;

/// Cómo se nombra un texto dentro del catálogo de audio.
String clipKey(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
