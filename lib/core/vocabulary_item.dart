/// Una palabra o expresión del idioma que se estudia, con su apoyo en español.
library;

class VocabularyItem {
  const VocabularyItem({
    required this.term,
    required this.translation,
    this.hint,
    this.spokenForm,
  });

  /// La palabra o expresión en el idioma estudiado.
  ///
  /// Junto al identificador del módulo forma la clave de la tarjeta de repaso.
  /// Por eso debe ser estable: cambiar una traducción o una ayuda visual no
  /// afecta al progreso del estudiante, pero cambiar el término reinicia su
  /// tarjeta.
  final String term;

  /// Su traducción al español.
  final String translation;

  /// Ayuda visual opcional, normalmente un emoji.
  final String? hint;

  /// Texto a pronunciar cuando difiere del término escrito.
  ///
  /// Sirve para expresiones donde la forma escrita y la hablada no coinciden.
  /// Si es nulo, se pronuncia [term].
  final String? spokenForm;

  /// Lo que la síntesis de voz debe leer.
  String get textToSpeak => spokenForm ?? term;
}
