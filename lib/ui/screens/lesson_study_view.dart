/// Material de estudio de una lección, antes de empezar a responder.
///
/// Vocabulario, gramática, ejemplos y lectura **no se puntúan** (FR-013): se
/// consultan. Por eso esta vista es solo lectura y el avance depende de un botón
/// explícito, no de haberla recorrido.
library;

import 'package:flutter/material.dart';

import '../../core/lesson.dart';
import '../../core/module.dart';
import '../../core/teaching_material.dart';
import '../../core/vocabulary_item.dart';
import '../widgets/bilingual_example_tile.dart';
import '../widgets/grammar_panel.dart';
import '../widgets/reading_passage_view.dart';
import '../widgets/listen_button.dart';
import '../widgets/vocabulary_card.dart';

class LessonStudyView extends StatelessWidget {
  const LessonStudyView({
    required this.module,
    required this.lesson,
    required this.onStart,
    super.key,
  });

  final Module module;
  final Lesson lesson;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: <Widget>[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Al terminar podrás',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(module.canDo, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text('Vocabulario', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final VocabularyItem item in module.vocabulary)
        VocabularyCard(
          item: item,
          // El botón se dibuja solo si hay voz disponible: no aparece un control
          // de audio que no suena.
          trailing: ListenButton(text: item.textToSpeak),
        ),
      const SizedBox(height: 24),
      Text('Gramática', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      GrammarPanel(grammar: module.grammar),
      const SizedBox(height: 24),
      Text('Ejemplos', style: Theme.of(context).textTheme.titleMedium),
      for (final BilingualExample example in module.examples)
        BilingualExampleTile(
          example: example,
          trailing: ListenButton(text: example.target),
        ),
      if (lesson.readingRef != null) ...<Widget>[
        const SizedBox(height: 24),
        Text('Lectura', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ReadingPassageView(passage: module.reading),
      ],
      const SizedBox(height: 32),
      FilledButton(onPressed: onStart, child: const Text('Empezar ejercicios')),
      const SizedBox(height: 16),
    ],
  );
}
