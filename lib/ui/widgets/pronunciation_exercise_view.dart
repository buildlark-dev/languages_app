/// Ejercicio de pronunciación, con su alternativa escrita siempre disponible.
///
/// Tres reglas que no son negociables:
///
/// * **El permiso se pide al tocar el botón**, explicando para qué (FR-018). No al
///   abrir la lección.
/// * **Un fallo de reconocimiento NO es un error de contenido** (FR-020). Se puede
///   reintentar, y tras varios intentos se puede continuar sin que cuente como
///   fallo.
/// * **La alternativa escrita está siempre a un toque**, incluso con micrófono
///   disponible. Alguien puede estar en el bus y no querer hablar en voz alta;
///   obligarle a usar el micrófono convertiría el ejercicio en un obstáculo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exercise.dart';
import '../../engine/pronunciation_matcher.dart';
import '../../services/speech/speech_help.dart';
import '../../services/speech/stt_service.dart';
import '../providers/speech_providers.dart';
import 'accessible_alternative.dart';
import 'listen_button.dart';

/// Lo que el ejercicio reporta al terminar un intento.
enum PronunciationAttempt {
  /// Se dijo bien, o se escribió bien.
  correct,

  /// Se dijo algo que no coincide con la frase.
  incorrect,

  /// No se pudo intentar: sin micrófono, sin permiso o sin reconocimiento.
  ///
  /// Sale del denominador de la nota (FR-020).
  unavailable,
}

class PronunciationExerciseView extends ConsumerStatefulWidget {
  const PronunciationExerciseView({
    required this.exercise,
    required this.languageTag,
    required this.onAttempt,
    this.answered = false,
    super.key,
  });

  final PronunciationExercise exercise;
  final String languageTag;
  final ValueChanged<PronunciationAttempt> onAttempt;
  final bool answered;

  @override
  ConsumerState<PronunciationExerciseView> createState() =>
      _PronunciationExerciseViewState();
}

class _PronunciationExerciseViewState
    extends ConsumerState<PronunciationExerciseView> {
  final TextEditingController _written = TextEditingController();

  bool _listening = false;
  bool _showWritten = false;
  int _failedAttempts = 0;
  PronunciationMatch? _lastMatch;

  /// Por qué no se pudo escuchar el último intento, si no se pudo.
  ///
  /// Antes esto no se guardaba porque no llegaba: el servicio tiraba el
  /// diagnóstico de la plataforma y la vista solo sabía «usa la alternativa».
  /// Decir *por qué* es lo que FR-017 y FR-018 piden.
  SttFailure? _failure;

  /// Tras tres intentos fallidos se ofrece continuar sin penalización.
  static const int _attemptsBeforeOffer = 3;

  @override
  void dispose() {
    _written.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    final SpeechAvailabilityController controller = ref.read(
      speechAvailabilityProvider.notifier,
    );

    // El permiso se pide **aquí**, al tocar el botón, no al abrir la lección.
    if (!ref.read(speechAvailabilityProvider).canRecord) {
      final bool granted = await controller.requestMicrophone();
      if (!granted) {
        setState(() {
          _showWritten = true;
          _failure = SttFailure.permissionDenied;
        });
        return;
      }
    }

    setState(() => _listening = true);
    final SttOutcome outcome = await ref
        .read(sttServiceProvider)
        .listenOnce(widget.languageTag);
    if (!mounted) return;
    setState(() => _listening = false);

    switch (outcome) {
      case SttRecognized(:final String text):
        final PronunciationMatch match = matchPronunciation(
          recognized: text,
          target: widget.exercise.targetPhrase,
        );
        setState(() {
          _lastMatch = match;
          if (!match.accepted) _failedAttempts++;
        });
        if (match.accepted) widget.onAttempt(PronunciationAttempt.correct);

      case SttNoSpeech():
        // No se oyó nada. No es que se dijera mal.
        setState(() {
          _lastMatch = null;
          _failedAttempts++;
        });

      case SttUseAlternative(:final SttFailure failure):
        // Paso 3 de la degradación: la ruta escrita. No es un error, y ahora
        // llega con el motivo puesto en lugar de aparecer sin explicación.
        setState(() {
          _showWritten = true;
          _failure = failure;
        });
    }
  }

  void _submitWritten() {
    final PronunciationMatch match = matchPronunciation(
      recognized: _written.text,
      target: widget.exercise.targetPhrase,
    );
    widget.onAttempt(
      match.accepted
          ? PronunciationAttempt.correct
          : PronunciationAttempt.incorrect,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se usa `canOfferMicrophone` y no `canRecord`: antes del primer permiso
    // el segundo es falso, y esconder el botón dejaba el permiso imposible
    // de conceder. Se pide al tocarlo, no antes (FR-018).
    final bool canRecord = ref
        .watch(speechAvailabilityProvider)
        .canOfferMicrophone;
    final String? micReason = ref
        .watch(speechAvailabilityProvider)
        .micUnavailableReason;
    final TextTheme text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Di en voz alta:', style: text.labelLarge),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(widget.exercise.targetPhrase, style: text.titleLarge),
            ),
            ListenButton(text: widget.exercise.targetPhrase),
          ],
        ),
        const SizedBox(height: 4),
        Text(widget.exercise.translation, style: text.bodyMedium),
        const SizedBox(height: 24),

        if (!_showWritten && canRecord) ...<Widget>[
          FilledButton.icon(
            onPressed: _listening || widget.answered ? null : _listen,
            icon: Icon(_listening ? Icons.mic : Icons.mic_none),
            label: Text(_listening ? 'Escuchando…' : 'Hablar'),
          ),
          const SizedBox(height: 8),
          // Siempre a un toque, incluso con micrófono: nadie debería tener que
          // hablar en voz alta en el bus para avanzar.
          TextButton(
            onPressed: () => setState(() => _showWritten = true),
            child: const Text('Prefiero escribirlo'),
          ),
        ],

        if (_lastMatch != null && !_lastMatch!.accepted) ...<Widget>[
          const SizedBox(height: 16),
          // FR-017: qué se entendió y qué se esperaba.
          _HeardFeedback(match: _lastMatch!),
        ],

        if (_failedAttempts >= _attemptsBeforeOffer &&
            !widget.answered) ...<Widget>[
          const SizedBox(height: 16),
          // FR-020: se puede continuar sin quedar atrapado, y no cuenta como fallo.
          OutlinedButton(
            onPressed: () => widget.onAttempt(PronunciationAttempt.unavailable),
            child: const Text('Continuar sin pronunciar'),
          ),
        ],

        if (_showWritten || !canRecord) ...<Widget>[
          const SizedBox(height: 16),
          AccessibleAlternative(
            title: 'Escríbelo',
            content: widget.exercise.writtenFallback,
            // Lo que falló en el intento manda sobre lo que se sabía del
            // aparato: es más reciente y más concreto.
            reason: _failure != null
                ? microphoneFailureMessage(_failure!)
                : (canRecord ? null : micReason),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _written,
            enabled: !widget.answered,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Tu respuesta'),
            onSubmitted: (_) => _submitWritten(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.answered ? null : _submitWritten,
            child: const Text('Comprobar'),
          ),
        ],
      ],
    );
  }
}

/// Muestra lo entendido frente a lo esperado.
class _HeardFeedback extends StatelessWidget {
  const _HeardFeedback({required this.match});

  final PronunciationMatch match;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Entendimos: «${match.heard}»',
              style: TextStyle(color: colors.onErrorContainer),
            ),
            const SizedBox(height: 4),
            Text(
              'Esperábamos: «${match.expected}»',
              style: TextStyle(color: colors.onErrorContainer),
            ),
            const SizedBox(height: 8),
            Text(
              'Inténtalo otra vez. No se puntúa el acento, solo que se entienda '
              'la frase.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
            ),
          ],
        ),
      ),
    );
  }
}
