/// A1 · Módulo 1 — vocabulario.
///
/// Separado del módulo porque el archivo completo pasaba de 300 líneas
/// (Principio II). La regla de división está en
/// `specs/001-english-a1-core/contracts/content-pack.md`: se parte por tipo de
/// material, no por ejercicio individual.
library;

import '../../core/vocabulary_item.dart';

const List<VocabularyItem> a1Module1Vocabulary = <VocabularyItem>[
  VocabularyItem(term: 'name', translation: 'nombre', hint: '🪪'),
  VocabularyItem(term: 'surname', translation: 'apellido', hint: '✍️'),
  VocabularyItem(term: 'country', translation: 'país', hint: '🌍'),
  VocabularyItem(term: 'city', translation: 'ciudad', hint: '🏙️'),
  VocabularyItem(term: 'job', translation: 'trabajo', hint: '💼'),
  VocabularyItem(term: 'teacher', translation: 'docente', hint: '👩‍🏫'),
  VocabularyItem(term: 'student', translation: 'estudiante', hint: '🎒'),
  VocabularyItem(term: 'friend', translation: 'amigo / amiga', hint: '🤝'),
  VocabularyItem(
    term: 'neighbour',
    translation: 'vecino / vecina',
    hint: '🏘️',
  ),
  VocabularyItem(term: 'age', translation: 'edad', hint: '🎂'),
  VocabularyItem(term: 'address', translation: 'dirección', hint: '📮'),
  VocabularyItem(
    term: 'phone number',
    translation: 'número de teléfono',
    hint: '📱',
  ),
];
