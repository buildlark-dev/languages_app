/// Botón de escuchar un texto.
///
/// Si no hay voz disponible **no se dibuja**. Un botón de audio que no suena hace
/// que la persona lo toque varias veces y concluya que la app está rota, cuando el
/// problema es que su dispositivo no tiene la voz instalada.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/speech_providers.dart';

class ListenButton extends ConsumerWidget {
  const ListenButton({required this.text, this.semanticLabel, super.key});

  /// Lo que se leerá en voz alta.
  final String text;

  /// Etiqueta para el lector de pantalla. Por defecto, «Escuchar» más el texto.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(speechAvailabilityProvider).canPlayAudio) {
      return const SizedBox.shrink();
    }

    return IconButton(
      icon: const Icon(Icons.volume_up_outlined),
      tooltip: 'Escuchar',
      // El lector de pantalla ya lee el texto en pantalla; la etiqueta aclara qué
      // hace el botón respecto a ese texto.
      onPressed: () => ref.read(ttsServiceProvider).speak(text),
    );
  }
}
