/// Dentro de un módulo: sus lecciones y su examen.
///
/// El examen **no** está bloqueado por las lecciones. FR-023 solo bloquea un
/// módulo hasta aprobar el anterior, y añadir aquí una puerta que la
/// especificación no pide castigaría a quien ya sabe el contenido: la
/// nivelación existe para no hacerle repetir lo que domina, y obligarlo a pasar
/// por cinco lecciones para poder demostrarlo sería deshacerlo.
///
/// Lo que sí se dice es **cuántas lecciones lleva**, para que presentarse sin
/// haberlas hecho sea una decisión informada y no un descuido.
library;

import 'package:flutter/material.dart';

import '../../core/activity_score.dart';
import '../../core/exam.dart';
import '../../core/lesson.dart';
import '../../core/module.dart';
import '../../core/student_progress.dart';
import '../widgets/exam_result_label.dart';
import '../widgets/grammar_panel.dart';
import '../widgets/simple_html_text.dart';

class ModuleDetailScreen extends StatelessWidget {
  const ModuleDetailScreen({
    required this.module,
    required this.progress,
    required this.onOpenLesson,
    required this.onOpenModuleExam,
    super.key,
  });

  final Module module;
  final StudentProgress progress;
  final ValueChanged<Lesson> onOpenLesson;
  final ValueChanged<Exam> onOpenModuleExam;

  @override
  Widget build(BuildContext context) {
    final int passedLessons = module.lessons
        .where((Lesson lesson) => progress.hasPassed(lesson.id))
        .length;
    final bool examPassed = progress.hasPassed(module.moduleExam.id);

    return Scaffold(
      appBar: AppBar(title: Text(module.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            // El objetivo funcional, otra vez: es lo que convierte una lista de
            // lecciones en una promesa concreta (FR-011).
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
                    Text(
                      module.canDo,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Lecciones', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final Lesson lesson in module.lessons)
              _LessonTile(
                lesson: lesson,
                passed: progress.hasPassed(lesson.id),
                onTap: () => onOpenLesson(lesson),
              ),
            const SizedBox(height: 24),
            // La gramática del módulo queda consultable aquí, fuera del
            // recorrido de una lección concreta: se vuelve a ella mientras se
            // practica, y tener que entrar en una lección para releerla
            // obligaría a empezar un recorrido solo para consultar.
            ExpansionTile(
              // El título lleva marcado —`<i>to be</i>`— porque los nombres de
              // las formas gramaticales van en cursiva. Un `Text` lo enseñaba
              // en crudo: «El verbo <i>to be</i> y los pronombres», visto en el
              // emulador Pixel 7. Dentro del panel sí se renderizaba, así que
              // el mismo texto salía bien en un sitio y mal en el otro.
              title: SimpleHtmlText(module.grammar.title),
              tilePadding: EdgeInsets.zero,
              children: <Widget>[GrammarPanel(grammar: module.grammar)],
            ),
            const SizedBox(height: 24),
            _ModuleExamCard(
              examPassed: examPassed,
              score: progress.activityScores[module.moduleExam.id],
              passedLessons: passedLessons,
              totalLessons: module.lessons.length,
              onOpen: () => onOpenModuleExam(module.moduleExam),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.passed,
    required this.onTap,
  });

  final Lesson lesson;
  final bool passed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          passed ? Icons.check_circle : Icons.play_circle_outline,
          color: passed ? colors.primary : colors.onSurfaceVariant,
        ),
        title: Text(lesson.title),
        subtitle: Text(
          '${lesson.exercises.length} ejercicios'
          '${passed ? ' · aprobada' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ModuleExamCard extends StatelessWidget {
  const _ModuleExamCard({
    required this.examPassed,
    required this.score,
    required this.passedLessons,
    required this.totalLessons,
    required this.onOpen,
  });

  final bool examPassed;

  /// El mejor intento, para poder decir con qué nota se aprobó.
  final ActivityScore? score;
  final int passedLessons;
  final int totalLessons;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      color: examPassed ? null : colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  examPassed
                      ? Icons.workspace_premium
                      : Icons.emoji_events_outlined,
                  color: colors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Examen del módulo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              examPassed
                  ? '${passedExamLabel(score)} Puedes repetirlo cuando quieras.'
                  : pendingExamLabel(
                      score,
                      pending:
                          'Necesitas 80 % para aprobarlo. Llevas '
                          '$passedLessons de $totalLessons lecciones.',
                    ),
            ),
            const SizedBox(height: 16),
            examPassed
                ? OutlinedButton(
                    onPressed: onOpen,
                    child: const Text('Repetir el examen'),
                  )
                : FilledButton(
                    onPressed: onOpen,
                    child: const Text('Presentar el examen'),
                  ),
          ],
        ),
      ),
    );
  }
}
