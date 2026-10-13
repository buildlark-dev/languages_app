/// Que ningún mensaje de voz exija configurar el aparato.
///
/// Es una prueba de producto, no de lógica, y está aquí porque el fallo que
/// corrige fue de producto: el mensaje decía «En Android se añade en Ajustes →
/// Sistema → Idiomas → Salida de texto a voz», lo que en Android es una
/// exigencia y en cualquier otra plataforma no dice nada que se pueda hacer.
/// Quien abre una app para aprender inglés y recibe una tarea de configuración,
/// la cierra.
///
/// La regla que se fija: **todo mensaje termina en lo que sí se puede hacer**, y
/// los pasos de configuración viven aparte, detrás de una pregunta opcional.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/services/speech/speech_help.dart';
import 'package:languages_app/services/speech/stt_service.dart';

void main() {
  test('el aviso de audio no manda a ningún ajuste', () {
    expect(audioUnavailableMessage, isNot(contains('Ajustes')));
    expect(audioUnavailableMessage, isNot(contains('Configuración')));
    // Y dice que se puede seguir, que es lo único que importa en ese momento.
    expect(audioUnavailableMessage, contains('se aprueba igual'));
  });

  test('cada fallo de micrófono termina en una salida', () {
    for (final SttFailure failure in SttFailure.values) {
      final String message = microphoneFailureMessage(failure);
      expect(
        message,
        anyOf(
          contains('escribir'),
          contains('intentarlo'),
        ),
        reason:
            'El mensaje de $failure deja a la persona sin saber qué hacer, y '
            'en un ejercicio oral la salida existe siempre (FR-019, SC-008)',
      );
    }
  });

  test('ningún mensaje de micrófono empieza culpando al dispositivo', () {
    // El permiso es lo único que la persona puede conceder; el resto son
    // propiedades del aparato y decirlo como reproche no ayuda a nadie.
    expect(
      microphoneFailureMessage(SttFailure.permissionDenied),
      contains('permiso'),
    );
    expect(
      microphoneFailureMessage(SttFailure.needsNetwork),
      contains('conexión'),
    );
  });

  test('los pasos de instalación existen y son específicos de plataforma', () {
    // En las pruebas `defaultTargetPlatform` es Android, así que debe salir el
    // texto de Android y **solo** el de Android: un párrafo que nombra cuatro
    // sistemas obliga a la persona a averiguar cuál es el suyo.
    final String? steps = voiceInstallSteps;
    expect(steps, isNotNull);
    expect(steps, contains('Ajustes'));
    expect(steps, isNot(contains('Windows')));
  });

  test('el permiso de micrófono se explica donde se concede', () {
    expect(microphonePermissionSteps, contains('Micrófono'));
  });
}
