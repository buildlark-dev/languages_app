/// Ejercicio de comprensión auditiva.
///
/// Si hay voz: botón para oír el audio, repetible cuantas veces se quiera. Si no:
/// el transcript, con el motivo.
///
/// Repetir sin límite es deliberado. En un examen de certificación el audio suena
/// una vez, pero esto es aprendizaje: oír tres veces una frase de A1 es
/// exactamente lo que construye el oído.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exercise.dart';
import '../providers/speech_providers.dart';
import 'accessible_alternative.dart';
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
    final bool canPlay = ref.watch(speechAvailabilityProvider).canPlayAudio;
    final String? reason = ref
        .watch(speechAvailabilityProvider)
        .audioUnavailableReason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (canPlay)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        ref.read(ttsServiceProvider).speak(exercise.spokenText),
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
          )
        else
          // Sin voz, el transcript conserva todo el ejercicio: leer y responder
          // sobre lo leído sigue siendo comprensión (SC-008).
          AccessibleAlternative(
            title: 'Transcripción',
            content: exercise.transcriptFallback,
            reason: reason,
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
        if (canPlay && answered) ...<Widget>[
          const SizedBox(height: 16),
          // Tras responder se revela el transcript: es la forma de aprender qué
          // se oyó de verdad frente a lo que se creyó oír.
          AccessibleAlternative(
            title: 'Lo que decía',
            content: exercise.transcriptFallback,
          ),
        ],
      ],
    );
  }
}
