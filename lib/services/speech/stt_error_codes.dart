/// Traduce los códigos de error del reconocedor a algo que se pueda explicar.
///
/// Archivo aparte porque son dos vocabularios distintos y conviene poder
/// probarlos sin un micrófono: el navegador informa los códigos de la Web Speech
/// API (`not-allowed`, `network`, `no-speech`…) y Android los de
/// `SpeechRecognizer` (`error_permission`, `error_network`, `error_no_match`…).
/// El plugin los pasa tal cual, sin unificarlos, así que la unificación tiene
/// que estar en algún sitio y este es el sitio.
///
/// Lo que no se reconoce no se adivina: cae en [SttFailure.unknown], que es el
/// único valor que admite reintento ciego. Inventar un diagnóstico sería peor
/// que no dar ninguno.
library;

import 'stt_service.dart';

/// Qué significa el código que informó la plataforma.
SttFailure failureForCode(String raw) {
  final String code = raw.trim().toLowerCase();

  return switch (code) {
    // Web Speech API.
    'not-allowed' || 'service-not-allowed' => SttFailure.permissionDenied,
    'network' => SttFailure.needsNetwork,
    'language-not-supported' => SttFailure.languageUnsupported,
    'audio-capture' => SttFailure.noMicrophone,
    'not supported' || 'speech_not_supported' => SttFailure.noRecognizer,

    // Android SpeechRecognizer.
    'error_permission' ||
    'error_insufficient_permissions' => SttFailure.permissionDenied,
    'error_network' ||
    'error_network_timeout' ||
    'error_server' ||
    'error_server_disconnected' => SttFailure.needsNetwork,
    'error_language_not_supported' ||
    'error_language_unavailable' => SttFailure.languageUnsupported,
    'error_audio' || 'error_no_microphone' => SttFailure.noMicrophone,
    // `error_client` es lo que informa Android cuando pide reconocimiento
    // local y el paquete de idioma offline no está instalado, que es el caso
    // normal del paso 1 de la degradación: no es un fallo, es la señal de
    // pasar al reconocedor del sistema.
    'error_client' ||
    'error_cannot_check_support' ||
    'error_busy' => SttFailure.noRecognizer,
    _ => SttFailure.unknown,
  };
}

/// Si el código significa «no se oyó nada» en lugar de «no se pudo escuchar».
///
/// Importa porque FR-020 prohíbe contar un fallo de reconocimiento como error
/// de contenido, y «silencio» tiene que llevar a reintentar, no a la
/// alternativa escrita.
bool isSilence(String raw) {
  final String code = raw.trim().toLowerCase();
  return code == 'no-speech' ||
      code == 'error_no_match' ||
      code == 'error_speech_timeout';
}
