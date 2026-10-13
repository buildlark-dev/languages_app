/// Todo lo que la app puede llegar a leer en voz alta, de un curso.
///
/// Lo usan dos cosas que **tienen** que coincidir: el script que genera los
/// clips de audio y la prueba que comprueba que no falta ninguno. Si la lista
/// viviera en el script, la prueba no podría verificar nada; si viviera en la
/// prueba, el script generaría otra cosa.
///
/// Recorre el curso entero y no solo A1 a propósito: el día que exista A2, los
/// clips que le falten aparecerán solos en el inventario en lugar de descubrirse
/// cuando alguien toque un botón mudo.
///
/// ## Lo que queda fuera, y por qué
///
/// Los ejemplos **dentro** de la explicación gramatical no entran. Se extraen
/// del HTML en tiempo de ejecución, así que no son un texto que este archivo
/// pueda enumerar sin meter la interfaz dentro de una capa de servicios. Esos
/// siguen dependiendo de la voz del sistema, y está dicho en D5.
library;

import '../../core/content_pack.dart';
import '../../core/course.dart';
import '../../core/exercise.dart';
import '../../core/lesson.dart';
import '../../core/level.dart';
import '../../core/module.dart';
import '../../core/teaching_material.dart';
import '../../core/vocabulary_item.dart';
import 'clip_key.dart';

/// Los textos que se pronuncian en [pack], sin repetidos y en orden estable.
///
/// El orden importa poco para la app y mucho para el repositorio: con un orden
/// estable, regenerar el audio sin cambiar el contenido no produce un solo
/// archivo distinto, y el diff de un cambio de contenido se lee.
List<String> spokenTextsOf(ContentPack pack) {
  final Map<String, String> byKey = <String, String>{};

  void add(String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    // La clave decide la identidad: dos textos que solo difieren en espacios o
    // mayúsculas comparten clip, igual que en tiempo de ejecución.
    byKey.putIfAbsent(clipKey(trimmed), () => trimmed);
  }

  void addExercises(Iterable<Exercise> exercises) {
    for (final Exercise exercise in exercises) {
      switch (exercise) {
        case ListeningExercise(:final String spokenText):
          add(spokenText);
        case PronunciationExercise(:final String targetPhrase):
          add(targetPhrase);
        case MultipleChoiceExercise():
        case SentenceBuilderExercise():
        case GapFillExercise():
          // No se pronuncian: su enunciado está en español y su respuesta se
          // escribe o se elige.
          break;
      }
    }
  }

  final Course course = pack.course;
  for (final Level level in course.levels) {
    for (final Module module in level.modules) {
      for (final VocabularyItem item in module.vocabulary) {
        add(item.textToSpeak);
      }
      for (final BilingualExample example in module.examples) {
        add(example.target);
      }
      for (final String paragraph in module.reading.paragraphs) {
        add(paragraph);
      }
      for (final Lesson lesson in module.lessons) {
        addExercises(lesson.exercises);
      }
      addExercises(module.moduleExam.exercises);
    }
    addExercises(level.levelExam.exercises);
  }

  return byKey.values.toList(growable: false);
}
