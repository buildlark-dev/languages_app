/// A1 · Módulo 1 — vocabulario.
///
/// Separado del módulo porque el archivo completo pasaba de 300 líneas
/// (Principio II). La regla de división está en
/// `specs/001-english-a1-core/contracts/content-pack.md`: se parte por tipo de
/// material, no por ejercicio individual.
library;

import '../../core/vocabulary_item.dart';

const List<VocabularyItem> a1Module1Vocabulary = <VocabularyItem>[
  VocabularyItem(term: 'name', translation: 'el nombre', hint: '🪪'),
  VocabularyItem(term: 'surname', translation: 'el apellido', hint: '✍️'),
  VocabularyItem(term: 'country', translation: 'el país', hint: '🌍'),
  VocabularyItem(term: 'city', translation: 'la ciudad', hint: '🏙️'),
  VocabularyItem(term: 'job', translation: 'el trabajo', hint: '💼'),
  VocabularyItem(term: 'teacher', translation: 'el/la docente', hint: '👩‍🏫'),
  VocabularyItem(term: 'student', translation: 'el/la estudiante', hint: '🎒'),
  VocabularyItem(
    term: 'friend',
    translation: 'el amigo / la amiga',
    hint: '🤝',
  ),
  VocabularyItem(
    term: 'neighbour',
    translation: 'el vecino / la vecina',
    hint: '🏘️',
  ),
  VocabularyItem(term: 'age', translation: 'la edad', hint: '🎂'),
  VocabularyItem(term: 'address', translation: 'la dirección', hint: '📮'),
  VocabularyItem(
    term: 'phone number',
    translation: 'el número de teléfono',
    hint: '📱',
  ),
];
