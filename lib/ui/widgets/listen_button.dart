/// Botón de escuchar un texto.
///
/// **Se dibuja siempre.** Antes se escondía cuando la disponibilidad decía que
/// no había voz, con el argumento de que un botón mudo hace pensar que la app
/// está rota. El argumento era bueno y la consecuencia fue peor: la detección
/// se equivoca sola —en el navegador la lista de voces llega vacía en la
/// primera consulta— y entonces la función **desaparecía entera**, sin botón,
/// sin aviso y sin forma de averiguar por qué.
///
/// Entre un botón que explica por qué no suena y ningún botón, el primero gana:
/// el fallo queda a la vista, dice qué hacer y no se lleva por delante la
/// función en los dispositivos donde sí habría funcionado.
///
/// Lo que el mensaje **no** hace es exigir nada. El texto vive en
/// `speech_help.dart` junto a los demás, y los pasos para instalar una voz
/// quedan detrás de un «¿Cómo?» opcional y redactados para la plataforma real.
/// Pedirle a alguien que configure el sistema operativo para poder seguir
/// estudiando es la forma más rápida de que cierre la app.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/speech/speech_help.dart';
import '../../services/speech/tts_service.dart';
import '../providers/speech_providers.dart';

class ListenButton extends ConsumerWidget {
  const ListenButton({required this.text, this.semanticLabel, super.key});

  /// Lo que se leerá en voz alta.
  final String text;

  /// Etiqueta para el lector de pantalla. Por defecto, «Escuchar».
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    icon: const Icon(Icons.volume_up_outlined),
    tooltip: semanticLabel ?? 'Escuchar',
    onPressed: () => _speak(context, ref),
  );

  Future<void> _speak(BuildContext context, WidgetRef ref) async {
    final SpeakOutcome outcome = await ref.read(ttsServiceProvider).speak(text);
    if (outcome.ok || !context.mounted) return;
    showAudioUnavailable(context, outcome);
  }
}

/// Dice que no se pudo reproducir, donde se tocó.
///
/// Función suelta y compartida porque lo usan el botón, el ejercicio de escucha
/// y la lectura, y tres copias del mismo aviso acabarían divergiendo: la que
/// alguien recordara actualizar sonaría distinta de las otras dos.
void showAudioUnavailable(BuildContext context, SpeakOutcome outcome) {
  final bool noVoice = outcome == SpeakOutcome.noVoice;
  final String? steps = noVoice ? voiceInstallSteps : null;

  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(
      content: Text(noVoice ? audioUnavailableMessage : audioFailedMessage),
      duration: const Duration(seconds: 6),
      // El «¿Cómo?» solo aparece cuando hay un paso concreto que dar en esta
      // plataforma. Un botón de ayuda que abre un texto vago es peor que no
      // tener botón.
      action: steps == null
          ? null
          : SnackBarAction(
              label: '¿Cómo?',
              onPressed: () => showDialog<void>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Añadir una voz en inglés'),
                  content: Text(
                    '$steps\n\nNo es obligatorio: todo el curso se puede '
                    'completar leyendo.',
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendido'),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
}
