/// A1 · Módulo 2 — Mi casa y mi ciudad.
///
/// Solo ensambla. El material está en los tres archivos hermanos
/// `a1_module2_vocabulary.dart`, `a1_module2_grammar.dart` y
/// `a1_module2_exercises.dart`.
library;

import '../../core/module.dart';
import 'a1_module2_exercises.dart';
import 'a1_module2_grammar.dart';
import 'a1_module2_vocabulary.dart';

const Module a1Module2 = Module(
  id: 'A1M2',
  order: 2,
  title: 'Mi casa y mi ciudad',
  canDo:
      'Describir objetos, decir qué hay en un lugar y ubicar cosas en el '
      'espacio.',
  vocabulary: a1Module2Vocabulary,
  grammar: a1Module2Grammar,
  examples: a1Module2Examples,
  reading: a1Module2Reading,
  lessons: a1Module2Lessons,
  moduleExam: a1Module2Exam,
);
