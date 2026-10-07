/// Sesión de repaso de la cola de repetición espaciada.
///
/// No se abre nunca vacía. FR-030 lo exige, y quien llama ya debería haberlo
/// evitado mostrando «estás al día», pero si llega aquí sin tarjetas lo dice
/// claramente en lugar de mostrar un recorrido de cero pasos.
///
/// La sesión vive en memoria (`engine/review_session.dart`), pero **cada tarjeta
/// se persiste en el momento de calificarla**, no al final. Aquí no aplica la
/// regla de la lección —nada se guarda hasta terminar—, y es por una diferencia
/// real: una lección es una nota que se aprueba o se suspende, así que a medias
/// no significa nada. Un repaso son hechos independientes, y haber recordado
/// seis palabras sigue siendo cierto aunque se cierre la app en la séptima.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/review_card.dart';
import '../../engine/review_session.dart';
import '../providers/clock_providers.dart';
import '../providers/review_providers.dart';
import '../widgets/review_card_view.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  /// La tanda en curso. Se crea con la primera cola que llega y **no se vuelve
  /// a crear**: la cola de esta sesión es la que había al entrar.
  ///
  /// Si se rehiciera al calificar, las tarjetas falladas hoy —reprogramadas para
  /// mañana— desaparecerían del recorrido a mitad, y el contador de «tarjeta 3
  /// de 10» cambiaría bajo los pies de la persona.
  ReviewSession? _session;

  bool _revealed = false;

  Future<void> _grade(RecallGrade grade) async {
    final ReviewSession session = _session!;
    final DateTime today = ref.read(clockProvider)();
    final ReviewCard rescheduled = session.grade(grade, today);

    setState(() => _revealed = false);
    await ref.read(reviewSummaryProvider.notifier).saveGraded(rescheduled);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ReviewCard>> due = ref.watch(dueReviewCardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Repaso')),
      body: SafeArea(child: _body(due)),
    );
  }

  Widget _body(AsyncValue<List<ReviewCard>> due) {
    final List<ReviewCard>? cards = due.value;
    if (cards == null) {
      // Incluye el caso de error: si la cola no se puede leer, no hay repaso que
      // ofrecer, y decirlo es mejor que un indicador girando para siempre.
      return due.hasError
          ? const _NothingDue()
          : const Center(child: CircularProgressIndicator());
    }

    final ReviewSession session = _session ??= ReviewSession.start(
      queue: cards,
    );

    if (session.totalCount == 0) return const _NothingDue();
    if (session.isComplete) {
      return _Finished(
        recalled: session.recalledCount,
        forgotten: session.forgottenCount,
      );
    }
    return _InProgress(
      session: session,
      revealed: _revealed,
      onReveal: () => setState(() => _revealed = true),
      onGrade: _grade,
    );
  }
}

/// La tarjeta en curso con su progreso.
class _InProgress extends StatelessWidget {
  const _InProgress({
    required this.session,
    required this.revealed,
    required this.onReveal,
    required this.onGrade,
  });

  final ReviewSession session;
  final bool revealed;
  final VoidCallback onReveal;
  final RecallGraded onGrade;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      LinearProgressIndicator(value: session.progress),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(
              'Tarjeta ${session.currentIndex + 1} de ${session.totalCount}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            ReviewCardView(
              card: session.currentCard!,
              revealed: revealed,
              onReveal: onReveal,
              onGrade: onGrade,
            ),
          ],
        ),
      ),
    ],
  );
}

/// No había nada que repasar. No debería verse si la pantalla principal hizo su
/// trabajo, pero abrir un recorrido vacío sería peor que decirlo.
class _NothingDue extends StatelessWidget {
  const _NothingDue();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.check_circle_outline, size: 48),
          const SizedBox(height: 16),
          Text(
            'Estás al día con el repaso',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'No hay palabras que venzan hoy. Vuelve mañana o sigue con una '
            'lección nueva.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}

/// Resumen al terminar la tanda.
class _Finished extends StatelessWidget {
  const _Finished({required this.recalled, required this.forgotten});

  final int recalled;
  final int forgotten;

  @override
  Widget build(BuildContext context) {
    final int total = recalled + forgotten;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.task_alt, size: 48),
            const SizedBox(height: 16),
            Text(
              'Repaso terminado',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('$total ${total == 1 ? 'tarjeta' : 'tarjetas'}'),
            const SizedBox(height: 16),
            // Sin porcentaje ni veredicto: un repaso no se aprueba. Se informa
            // qué vuelve mañana, que es lo único accionable.
            Text(
              forgotten == 0
                  ? 'Recordaste todas.'
                  : forgotten == 1
                  ? '1 palabra vuelve mañana.'
                  : '$forgotten palabras vuelven mañana.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
