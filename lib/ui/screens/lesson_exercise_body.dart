/// El ejercicio en curso, según su tipo.
///
/// Escucha y pronunciación se presentan aquí por su **alternativa accesible**.
/// Su interfaz con audio y micrófono llega en la Historia 4; la ruta escrita es la
/// que SC-008 exige que exista siempre, así que es la que funciona primero.
library;

import 'package:flutter/material.dart';

import '../../core/exercise.dart';
import '../widgets/gap_fill_field.dart';
import '../widgets/multiple_choice_question.dart';
import '../widgets/sentence_builder.dart';

class LessonExerciseBody extends StatelessWidget {
  const LessonExerciseBody({
    required this.exercise,
    required this.answered,
    required this.choice,
    required this.chosenTokens,
    required this.onChoice,
    required this.onTyped,
    required this.onToggleToken,
    required this.onSubmit,
    super.key,
  });

  final Exercise exercise;
  final bool answered;
  final int? choice;
  final List<int> chosenTokens;
  final ValueChanged<int> onChoice;
  final ValueChanged<String> onTyped;
  final ValueChanged<int> onToggleToken;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => switch (exercise) {
    MultipleChoiceExercise(
      :final String prompt,
      :final List<String> options,
      :final int answerIndex,
    ) =>
      MultipleChoiceQuestion(
        prompt: prompt,
        options: options,
        selectedIndex: choice,
        onSelect: onChoice,
        enabled: !answered,
        correctIndex: answered ? answerIndex : null,
      ),

    GapFillExercise(:final String sentenceWithGap, :final String? hint) =>
      GapFillField(
        sentenceWithGap: sentenceWithGap,
        hint: hint,
        enabled: !answered,
        onChanged: onTyped,
        onSubmit: onSubmit,
      ),

    SentenceBuilderExercise(:final List<String> tokens) => SentenceBuilder(
      tokens: tokens,
      chosenIndices: chosenTokens,
      onToggle: onToggleToken,
      enabled: !answered,
    ),

    // Escucha y pronunciación reciben su interfaz propia en la Historia 4. Aquí
    // se presentan por su alternativa accesible, que es la ruta que siempre debe
    // existir (SC-008).
    ListeningExercise(
      :final String question,
      :final List<String> options,
      :final int answerIndex,
      :final String transcriptFallback,
    ) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(transcriptFallback),
            ),
          ),
          const SizedBox(height: 16),
          MultipleChoiceQuestion(
            prompt: question,
            options: options,
            selectedIndex: choice,
            onSelect: onChoice,
            enabled: !answered,
            correctIndex: answered ? answerIndex : null,
          ),
        ],
      ),

    PronunciationExercise(:final String writtenFallback) => GapFillField(
      sentenceWithGap: writtenFallback,
      enabled: !answered,
      onChanged: onTyped,
      onSubmit: onSubmit,
    ),
  };
}
