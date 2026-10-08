/// Decide si una respuesta compuesta en pantalla es correcta.
///
/// Vive en el motor y no dentro del recorredor de ejercicios porque ahora hay
/// **dos** recorridos: la lección o examen, que corrige y explica, y la
/// nivelación, que solo registra acierto o fallo. Si cada uno llevara su propio
/// `switch`, arreglar la corrección de un hueco significaría arreglarla dos
/// veces, y la segunda se olvidaría.
///
/// La comparación de texto no se hace aquí: la hace `answer_matcher.dart`, que
/// es quien sabe que un apóstrofo tipográfico y uno recto son el mismo.
library;

import '../core/exercise.dart';
import 'answer_matcher.dart';

/// Lo que la persona lleva compuesto para el ejercicio en curso.
///
/// Es un solo objeto con los tres canales en lugar de tres parámetros sueltos
/// porque cada tipo de ejercicio usa uno distinto, y pasarlos juntos evita que
/// alguien añada un cuarto tipo y olvide propagar su canal.
class AnswerDraft {
  const AnswerDraft({
    this.choice,
    this.typed = '',
    this.chosenTokens = const <int>[],
  });

  /// Opción marcada, en opción múltiple y escucha.
  final int? choice;

  /// Texto escrito, en huecos y en la alternativa escrita de pronunciación.
  final String typed;

  /// Índices de las fichas elegidas, en orden, al construir una oración.
  final List<int> chosenTokens;

  AnswerDraft withChoice(int choice) =>
      AnswerDraft(choice: choice, typed: typed, chosenTokens: chosenTokens);

  AnswerDraft withTyped(String text) =>
      AnswerDraft(choice: choice, typed: text, chosenTokens: chosenTokens);

  /// Añade o quita una ficha, conservando el orden de elección.
  ///
  /// El orden es el que se juzga, así que quitar la del medio no reordena las
  /// demás: la oración se construye con las que queden, tal como están.
  AnswerDraft toggling(int index) => AnswerDraft(
    choice: choice,
    typed: typed,
    chosenTokens: chosenTokens.contains(index)
        ? (<int>[...chosenTokens]..remove(index))
        : <int>[...chosenTokens, index],
  );
}

/// Si [draft] resuelve [exercise] correctamente.
bool isAnswerCorrect(Exercise exercise, AnswerDraft draft) =>
    switch (exercise) {
      MultipleChoiceExercise(:final int answerIndex) =>
        draft.choice == answerIndex,
      ListeningExercise(:final int answerIndex) => draft.choice == answerIndex,
      GapFillExercise(:final List<String> acceptedAnswers) => matchesAnswer(
        draft.typed,
        acceptedAnswers,
      ),
      SentenceBuilderExercise(
        :final List<String> tokens,
        :final String targetSentence,
      ) =>
        matchesSentence(
          draft.chosenTokens.map((int i) => tokens[i]).join(' '),
          targetSentence,
        ),
      // La pronunciación tiene su propio canal con micrófono; por aquí llega
      // solo su alternativa escrita, que es la ruta que SC-008 exige que exista
      // siempre.
      PronunciationExercise(:final String targetPhrase) => matchesSentence(
        draft.typed,
        targetPhrase,
      ),
    };

/// Si hay respuesta suficiente para poder comprobarla.
///
/// Separado de [isAnswerCorrect] a propósito: sin esto, un campo vacío contaría
/// como respuesta equivocada, y pulsar «Comprobar» sin querer gastaría el
/// intento.
bool isDraftComplete(Exercise exercise, AnswerDraft draft) =>
    switch (exercise) {
      MultipleChoiceExercise() || ListeningExercise() => draft.choice != null,
      GapFillExercise() ||
      PronunciationExercise() => draft.typed.trim().isNotEmpty,
      SentenceBuilderExercise() => draft.chosenTokens.isNotEmpty,
    };

/// La respuesta esperada de un ejercicio, para mostrarla al fallar.
String? expectedAnswerOf(Exercise exercise) => switch (exercise) {
  MultipleChoiceExercise(:final String correctOption) => correctOption,
  ListeningExercise(:final List<String> options, :final int answerIndex) =>
    options[answerIndex],
  GapFillExercise(:final List<String> acceptedAnswers) => acceptedAnswers.first,
  SentenceBuilderExercise(:final String targetSentence) => targetSentence,
  PronunciationExercise(:final String targetPhrase) => targetPhrase,
};
