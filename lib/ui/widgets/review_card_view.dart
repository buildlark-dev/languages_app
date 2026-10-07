/// Una tarjeta de repaso: pregunta, respuesta oculta y tres calificaciones.
///
/// Pregunta en **español** y espera la palabra en el idioma estudiado, no al
/// revés. Reconocer «name» y decir «el nombre» es mucho más fácil que producir
/// «name» partiendo de «el nombre», y la segunda es la que hace falta para
/// hablar. Repasar en la dirección fácil da una sensación de dominio que no se
/// sostiene en una conversación.
library;

import 'package:flutter/material.dart';

import '../../core/review_card.dart';
import 'listen_button.dart';

/// Qué calificación eligió la persona.
typedef RecallGraded = void Function(RecallGrade grade);

class ReviewCardView extends StatelessWidget {
  const ReviewCardView({
    required this.card,
    required this.revealed,
    required this.onReveal,
    required this.onGrade,
    super.key,
  });

  final ReviewCard card;

  /// Si ya se destapó la respuesta.
  ///
  /// Las calificaciones solo aparecen después. Poder calificar sin haber
  /// intentado recordar vacía el ejercicio: el valor del repaso está en el
  /// esfuerzo de recuperación, no en pasar tarjetas.
  final bool revealed;

  final VoidCallback onReveal;
  final RecallGraded onGrade;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                Text(
                  '¿Cómo se dice…?',
                  style: text.labelLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  card.translation,
                  style: text.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (revealed) ...<Widget>[
                  const Divider(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          card.term,
                          style: text.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      ListenButton(text: card.term),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (!revealed)
          FilledButton(
            onPressed: onReveal,
            child: const Text('Mostrar la respuesta'),
          )
        else
          _GradeButtons(onGrade: onGrade),
      ],
    );
  }
}

/// Las tres calificaciones, con lo que cada una significa escrito al lado.
///
/// Decir «vuelve mañana» o «vuelve más adelante» en lugar de solo «Difícil» y
/// «Fácil» no es decoración: sin eso, nadie sabe qué está eligiendo, y una
/// persona que quiere terminar rápido pulsa «Fácil» en todo y desactiva el
/// sistema sin saberlo.
class _GradeButtons extends StatelessWidget {
  const _GradeButtons({required this.onGrade});

  final RecallGraded onGrade;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      OutlinedButton(
        onPressed: () => onGrade(RecallGrade.forgotten),
        child: const Text('No la recordaba · vuelve mañana'),
      ),
      const SizedBox(height: 8),
      FilledButton.tonal(
        onPressed: () => onGrade(RecallGrade.hard),
        child: const Text('Me costó · vuelve pronto'),
      ),
      const SizedBox(height: 8),
      FilledButton(
        onPressed: () => onGrade(RecallGrade.easy),
        child: const Text('Fue inmediato · vuelve más adelante'),
      ),
    ],
  );
}
