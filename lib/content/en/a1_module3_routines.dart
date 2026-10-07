/// A1 · Módulo 3 — Rutinas y horarios.
///
/// Solo ensambla. El material está en los tres archivos hermanos
/// `a1_module3_vocabulary.dart`, `a1_module3_grammar.dart` y
/// `a1_module3_exercises.dart`.
library;

import '../../core/module.dart';
import 'a1_module3_exercises.dart';
import 'a1_module3_grammar.dart';
import 'a1_module3_vocabulary.dart';

const Module a1Module3 = Module(
  id: 'A1M3',
  order: 3,
  title: 'Rutinas y horarios',
  canDo:
      'Contar tu día, decir la hora y preguntar por la rutina de otra persona.',
  vocabulary: a1Module3Vocabulary,
  grammar: a1Module3Grammar,
  examples: a1Module3Examples,
  reading: a1Module3Reading,
  lessons: a1Module3Lessons,
  moduleExam: a1Module3Exam,
);
