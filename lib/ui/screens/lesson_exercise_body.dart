/// El ejercicio en curso, según su tipo.
///
/// Los cinco tipos se despachan con un `switch` sobre la jerarquía `sealed`, así
/// que añadir un sexto no compila hasta que se le dé interfaz aquí.
library;

import 'package:flutter/material.dart';

import '../../core/exercise.dart';
import '../widgets/gap_fill_field.dart';
import '../widgets/listening_exercise_view.dart';
import '../widgets/multiple_choice_question.dart';
import '../widgets/pronunciation_exercise_view.dart';
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
    required this.languageTag,
    required this.onPronunciationAttempt,
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

  /// Idioma del curso, para el reconocimiento de habla.
  final String languageTag;

  /// Resultado de un intento de pronunciación.
  ///
  /// Es un canal propio porque la pronunciación se resuelve dentro de su widget
  /// —tiene micrófono, reintentos y alternativa— y puede devolver `unavailable`,
  /// que no es ni acierto ni fallo (FR-020).
  final ValueChanged<PronunciationAttempt> onPronunciationAttempt;

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

    // Los dos orales tienen interfaz propia, que decide sola entre audio y
    // alternativa según lo que el dispositivo ofrezca.
    final ListeningExercise listening => ListeningExerciseView(
      exercise: listening,
      selectedIndex: choice,
      onSelect: onChoice,
      answered: answered,
    ),

    final PronunciationExercise pronunciation => PronunciationExerciseView(
      exercise: pronunciation,
      languageTag: languageTag,
      answered: answered,
      onAttempt: onPronunciationAttempt,
    ),
  };
}
