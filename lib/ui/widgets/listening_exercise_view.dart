/// Ejercicio de comprensión auditiva.
///
/// Botón para oír el audio, repetible cuantas veces se quiera, **y** la
/// transcripción plegada. Los dos, siempre: antes se elegía entre uno y otra
/// según la voz detectada, y cuando la detección se equivocaba el ejercicio se
/// quedaba sin audio para todo el mundo.
///
/// Repetir sin límite es deliberado. En un examen de certificación el audio suena
/// una vez, pero esto es aprendizaje: oír tres veces una frase de A1 es
/// exactamente lo que construye el oído.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exercise.dart';
import '../../services/speech/tts_service.dart';
import '../providers/speech_providers.dart';
import 'accessible_alternative.dart';
import 'listen_button.dart';
import 'multiple_choice_question.dart';

class ListeningExerciseView extends ConsumerWidget {
  const ListeningExerciseView({
    required this.exercise,
    required this.selectedIndex,
    required this.onSelect,
    this.answered = false,
    super.key,
  });

  final ListeningExercise exercise;
  final int? selectedIndex;
  final ValueChanged<int> onSelect;
  final bool answered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // El botón de oír se ofrece **siempre**, y la transcripción también está
    // siempre, plegada. Antes se elegía entre uno y otra según la
    // disponibilidad detectada, y cuando la detección se equivocaba —en web la
    // lista de voces llega vacía en la primera consulta— el ejercicio se
    // quedaba sin audio para todo el mundo.
    //
    // Tenerlos a la vez no rompe nada: la transcripción es la alternativa
    // accesible que FR-019 exige que exista, y plegada no regala la respuesta
    // a quien sí quiere escuchar.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                FilledButton.tonalIcon(
                  onPressed: () => _play(context, ref),
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Escuchar'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Puedes repetirlo cuantas veces quieras.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ExpansionTile(
          title: const Text('Ver la transcripción'),
          tilePadding: EdgeInsets.zero,
          children: <Widget>[
            // Leer y responder sobre lo leído sigue siendo comprensión, y es
            // la ruta que hace aprobable el ejercicio sin sonido (SC-008).
            AccessibleAlternative(
              title: 'Transcripción',
              content: exercise.transcriptFallback,
            ),
          ],
        ),
        const SizedBox(height: 24),
        MultipleChoiceQuestion(
          prompt: exercise.question,
          options: exercise.options,
          selectedIndex: selectedIndex,
          onSelect: onSelect,
          enabled: !answered,
          correctIndex: answered ? exercise.answerIndex : null,
        ),
        if (answered) ...<Widget>[
          const SizedBox(height: 16),
          // Tras responder se revela sin plegar: es la forma de aprender qué
          // se oyó de verdad frente a lo que se creyó oír.
          AccessibleAlternative(
            title: 'Lo que decía',
            content: exercise.transcriptFallback,
          ),
        ],
      ],
    );
  }

  /// Reproduce el audio y, si no se puede, dice por qué.
  ///
  /// El mensaje va donde se tocó. Antes esta rama no existía: sin voz no había
  /// botón, así que tampoco había nada que explicar ni momento para hacerlo.
  Future<void> _play(BuildContext context, WidgetRef ref) async {
    final SpeakOutcome outcome = await ref
        .read(ttsServiceProvider)
        .speak(exercise.spokenText);
    if (outcome.ok || !context.mounted) return;

    // El mismo aviso que el botón de escuchar, por la misma razón: el texto
    // que se lee en el peor momento tiene que ser uno, no tres variantes que
    // divergen.
    showAudioUnavailable(context, outcome);
  }
}
