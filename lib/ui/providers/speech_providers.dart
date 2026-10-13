/// Voz: servicios y disponibilidad resuelta.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/course.dart';
import '../../services/speech/speech_availability.dart';
import '../../services/speech/stt_service.dart';
import '../../services/speech/tts_service.dart';
import 'content_providers.dart';

/// Los servicios concretos. **Se sobrescriben en `main.dart`.**
final Provider<TtsService> ttsServiceProvider = Provider<TtsService>(
  (Ref ref) =>
      throw UnimplementedError('ttsServiceProvider debe sobrescribirse'),
);

final Provider<SttService> sttServiceProvider = Provider<SttService>(
  (Ref ref) =>
      throw UnimplementedError('sttServiceProvider debe sobrescribirse'),
);

/// Qué se puede hacer con la voz, resuelto una vez por sesión.
///
/// Es un [Notifier] y no un `FutureProvider` porque la disponibilidad **cambia**
/// durante la sesión: al conceder o negar el permiso de micrófono. Un futuro
/// resuelto una vez dejaría la interfaz mostrando la alternativa escrita incluso
/// después de que la persona concediera el permiso.
class SpeechAvailabilityController extends Notifier<SpeechAvailability> {
  @override
  SpeechAvailability build() {
    // Se prepara sola al haber curso abierto, en lugar de esperar a que alguna
    // pantalla llame a [prepare].
    //
    // Es la corrección de un fallo que tuvo la app desplegada: `prepare()` no
    // se llamaba desde ningún sitio, así que la disponibilidad se quedaba en
    // «ninguna» para siempre. El efecto era que `ListenButton` no se dibujaba
    // en ninguna parte y todo ejercicio oral caía a su alternativa escrita: la
    // app no reproducía audio nunca, con el motor de voz entero construido y
    // probado detrás.
    //
    // Depender del curso y no de una llamada desde una pantalla concreta
    // significa que ninguna ruta nueva puede saltárselo, que es justo lo que
    // pasó.
    final Course? course = ref.watch(activeCourseProvider);
    if (course != null) {
      // Después de construir, no durante: `prepare` escribe `state`, y hacerlo
      // dentro de `build` sería modificar el proveedor mientras se construye.
      // La comprobación de `mounted` cubre el hueco entre ambos momentos.
      Future<void>(() {
        if (ref.mounted) return prepare(course.studyLanguageTag);
      });
    }
    return const SpeechAvailability.none();
  }

  /// Prepara la voz para el idioma del curso.
  ///
  /// **No pide el permiso de micrófono**: solo consulta lo que ya se sabe
  /// (FR-018). Pedirlo al arrancar es la forma más rápida de que lo nieguen.
  Future<void> prepare(String languageTag) async {
    final TtsAvailability tts = await ref
        .read(ttsServiceProvider)
        .initialize(languageTag);
    final SttAvailability stt = await ref
        .read(sttServiceProvider)
        .checkAvailability();

    state = SpeechAvailability(tts: tts, stt: stt);
  }

  /// Pide el permiso de micrófono y actualiza la disponibilidad.
  ///
  /// Se invoca cuando la persona toca el botón de hablar, no antes.
  Future<bool> requestMicrophone() async {
    final bool granted = await ref.read(sttServiceProvider).requestPermission();
    final SttAvailability stt = await ref
        .read(sttServiceProvider)
        .checkAvailability();
    state = state.copyWith(stt: stt);
    return granted;
  }
}

final NotifierProvider<SpeechAvailabilityController, SpeechAvailability>
speechAvailabilityProvider =
    NotifierProvider<SpeechAvailabilityController, SpeechAvailability>(
      SpeechAvailabilityController.new,
    );
