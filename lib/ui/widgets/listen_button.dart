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
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Decirlo donde se tocó, no en una pantalla aparte: quien pulsa está
    // leyendo una palabra y no quiere irse a ninguna parte.
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          outcome == SpeakOutcome.noVoice
              // El consejo es tan importante como el diagnóstico: la voz la
              // pone el sistema, no la app, y sin decir dónde se instala la
              // persona no tiene nada que hacer con la información.
              ? 'No hay voz en inglés instalada. En Android se añade en '
                    'Ajustes → Sistema → Idiomas → Salida de texto a voz; en el '
                    'navegador depende de las voces del sistema.'
              : 'No se pudo reproducir el audio. Inténtalo otra vez.',
        ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
