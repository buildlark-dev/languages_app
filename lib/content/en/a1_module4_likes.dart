/// A1 · Módulo 4 — Gustos y capacidades.
///
/// Solo ensambla. El material está en los tres archivos hermanos
/// `a1_module4_vocabulary.dart`, `a1_module4_grammar.dart` y
/// `a1_module4_exercises.dart`.
library;

import '../../core/module.dart';
import 'a1_module4_exercises.dart';
import 'a1_module4_grammar.dart';
import 'a1_module4_vocabulary.dart';

const Module a1Module4 = Module(
  id: 'A1M4',
  order: 4,
  title: 'Gustos y capacidades',
  canDo: 'Expresar preferencias, hablar de lo que sabes hacer y pedir comida.',
  vocabulary: a1Module4Vocabulary,
  grammar: a1Module4Grammar,
  examples: a1Module4Examples,
  reading: a1Module4Reading,
  lessons: a1Module4Lessons,
  moduleExam: a1Module4Exam,
);
