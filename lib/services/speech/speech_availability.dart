/// Qué se puede hacer con la voz en este dispositivo, resuelto de una vez.
///
/// Existe para que la interfaz no tenga que combinar dos disponibilidades en cada
/// widget. La decisión «¿botón de audio o transcript?» y «¿micrófono o
/// alternativa?» se toma aquí, una vez, y las pantallas solo la consultan.
library;

import 'stt_service.dart';
import 'tts_service.dart';

class SpeechAvailability {
  const SpeechAvailability({required this.tts, required this.stt});

  /// Todo disponible: el caso normal en un teléfono con la voz instalada.
  const SpeechAvailability.full()
    : tts = TtsAvailability.available,
      stt = SttAvailability.onDeviceReady;

  /// Nada disponible: la ruta que SC-008 exige que siga funcionando.
  const SpeechAvailability.none()
    : tts = TtsAvailability.unsupportedPlatform,
      stt = SttAvailability.unsupportedPlatform;

  final TtsAvailability tts;
  final SttAvailability stt;

  /// Si vale la pena mostrar el botón de escuchar.
  ///
  /// Cuando es false, el ejercicio de escucha muestra su transcript: un botón de
  /// audio que no suena hace que la persona concluya que la app está rota, cuando
  /// el problema es que su dispositivo no tiene la voz instalada.
  bool get canPlayAudio => tts.canSpeak;

  /// Si vale la pena ofrecer el micrófono.
  bool get canRecord => stt.canListen;

  /// Si el reconocimiento funcionará sin conexión.
  ///
  /// Informativo: la interfaz no cambia por esto, pero permite explicar a la
  /// persona por qué la pronunciación puede no funcionar en modo avión.
  bool get worksOffline => stt == SttAvailability.onDeviceReady;

  /// Por qué no hay audio, para poder explicarlo.
  String? get audioUnavailableReason => switch (tts) {
    TtsAvailability.available => null,
    TtsAvailability.languageMissing =>
      'Tu dispositivo no tiene instalada la voz en inglés.',
    TtsAvailability.engineMissing =>
      'Tu dispositivo no tiene motor de voz disponible.',
    TtsAvailability.unsupportedPlatform =>
      'Este dispositivo no admite reproducción de voz.',
  };

  /// Por qué no hay micrófono, para poder explicarlo.
  String? get micUnavailableReason => switch (stt) {
    SttAvailability.onDeviceReady || SttAvailability.networkOnly => null,
    SttAvailability.permissionDenied =>
      'No concediste permiso de micrófono. Puedes responder por escrito.',
    SttAvailability.noMicrophone =>
      'No detectamos micrófono. Puedes responder por escrito.',
    SttAvailability.unsupportedPlatform =>
      'Este dispositivo no admite reconocimiento de voz. Puedes responder por '
          'escrito.',
  };

  SpeechAvailability copyWith({TtsAvailability? tts, SttAvailability? stt}) =>
      SpeechAvailability(tts: tts ?? this.tts, stt: stt ?? this.stt);
}
