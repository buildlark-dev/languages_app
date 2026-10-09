/// Que el diagnóstico del reconocedor llegue traducido, no tirado.
///
/// El fallo que corrige esto se midió en el navegador de la app desplegada:
/// `start()` informa `not-allowed` en **milisegundos**, y el servicio pasaba
/// `onError: (_) {}`. Resultado: seis segundos de ventana más dos de pausa,
/// repetido para el segundo paso, dieciséis segundos de «Escuchando…» y al
/// final la alternativa escrita sin una palabra sobre el micrófono.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/services/speech/stt_error_codes.dart';
import 'package:languages_app/services/speech/stt_service.dart';

void main() {
  group('códigos del navegador', () {
    test('el permiso denegado se reconoce', () {
      expect(failureForCode('not-allowed'), SttFailure.permissionDenied);
      expect(
        failureForCode('service-not-allowed'),
        SttFailure.permissionDenied,
      );
    });

    test('la falta de red se distingue de la falta de permiso', () {
      // Importa porque el mensaje y la salida son distintos: con red el
      // micrófono volverá a funcionar solo, sin permiso hay que concederlo.
      expect(failureForCode('network'), SttFailure.needsNetwork);
    });

    test('«no se oyó nada» no es un fallo del micrófono', () {
      // FR-020: no puede contar como error de contenido ni mandar a la
      // alternativa escrita. La respuesta correcta es «prueba otra vez».
      expect(isSilence('no-speech'), isTrue);
      expect(isSilence('not-allowed'), isFalse);
    });

    test('el idioma que falta se reconoce', () {
      expect(
        failureForCode('language-not-supported'),
        SttFailure.languageUnsupported,
      );
    });
  });

  group('códigos de Android', () {
    test('el permiso denegado se reconoce con su otro nombre', () {
      expect(failureForCode('error_permission'), SttFailure.permissionDenied);
    });

    test('silencio y falta de coincidencia son silencio', () {
      expect(isSilence('error_no_match'), isTrue);
      expect(isSilence('error_speech_timeout'), isTrue);
    });

    test('error_client lleva al reconocedor del sistema', () {
      // Es lo que Android informa cuando se pide reconocimiento local y el
      // paquete de idioma offline no está: justo el caso en que el paso 2 de la
      // degradación sí puede funcionar.
      final SttFailure failure = failureForCode('error_client');
      expect(failure, SttFailure.noRecognizer);
      expect(failure.worthRetryingOverNetwork, isTrue);
    });

    test('el servidor caído se trata como falta de red', () {
      expect(failureForCode('error_server'), SttFailure.needsNetwork);
    });
  });

  group('lo que no se reconoce', () {
    test('no se adivina', () {
      expect(failureForCode('algo_que_nadie_ha_visto'), SttFailure.unknown);
      expect(failureForCode(''), SttFailure.unknown);
    });

    test('mayúsculas y espacios no cambian el diagnóstico', () {
      expect(failureForCode('  NOT-ALLOWED '), SttFailure.permissionDenied);
    });
  });

  group('reintentar o no', () {
    test('un permiso denegado no se reintenta por red', () {
      // Reintentar aquí solo gasta ocho segundos del tiempo de quien espera:
      // el reconocedor del sistema necesita el mismo permiso.
      expect(SttFailure.permissionDenied.worthRetryingOverNetwork, isFalse);
      expect(SttFailure.noMicrophone.worthRetryingOverNetwork, isFalse);
      expect(SttFailure.languageUnsupported.worthRetryingOverNetwork, isFalse);
    });

    test('la falta de reconocedor local sí', () {
      expect(SttFailure.noRecognizer.worthRetryingOverNetwork, isTrue);
      expect(SttFailure.unknown.worthRetryingOverNetwork, isTrue);
    });
  });
}
