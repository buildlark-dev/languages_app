/// A1 · Módulo 1 — Identidad y saludos.
///
/// Este archivo solo **ensambla**. El material está repartido en tres archivos
/// hermanos, porque el módulo completo pasaba de 300 líneas y el Principio II
/// pide partir antes de seguir creciendo:
///
/// * `a1_module1_vocabulary.dart` — vocabulario
/// * `a1_module1_grammar.dart` — gramática, ejemplos y lectura (no se puntúan)
/// * `a1_module1_exercises.dart` — lecciones y examen (lo calificable)
///
/// Contenido derivado de la ruta ya validada en `Study/ruta-de-ingles.html`. No
/// se inventa gramática (Principio III).
library;

import '../../core/module.dart';
import 'a1_module1_exercises.dart';
import 'a1_module1_grammar.dart';
import 'a1_module1_vocabulary.dart';

const Module a1Module1 = Module(
  id: 'A1M1',
  order: 1,
  title: 'Identidad y saludos',
  canDo:
      'Presentarte, deletrear tu nombre, decir de dónde eres y preguntar lo '
      'mismo a otra persona.',
  vocabulary: a1Module1Vocabulary,
  grammar: a1Module1Grammar,
  examples: a1Module1Examples,
  reading: a1Module1Reading,
  lessons: a1Module1Lessons,
  moduleExam: a1Module1Exam,
);
