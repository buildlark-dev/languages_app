/// Pronunciar una palabra y saber si salió bien.
///
/// Es la versión ligera del ejercicio de pronunciación: aquí **no se califica
/// nada** ni se bloquea el avance, solo se dice si lo que se oyó encaja. Lo usa
/// el repaso, donde la nota la pone la persona eligiendo cómo lo recordó, y la
/// pronunciación es una comprobación aparte que ofrecer sin obligar.
///
/// **Se dibuja siempre, y no se borra al fallar.** Antes desaparecía: tras el
/// primer intento sin permiso o sin reconocedor devolvía un hueco vacío, así
/// que el botón se iba de la tarjeta sin decir nada y no había forma de volver
/// a intentarlo. Era el mismo patrón que había borrado los botones de escuchar,
/// una capa más abajo.
///
/// La regla es la de toda la app: el control existe, el intento decide, y lo
/// que pasó se dice en el sitio donde se tocó.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/pronunciation_matcher.dart';
import '../../services/speech/speech_help.dart';
import '../../services/speech/stt_service.dart';
import '../providers/speech_providers.dart';

class PronunciationCheck extends ConsumerStatefulWidget {
  const PronunciationCheck({
    required this.target,
    required this.languageTag,
    super.key,
  });

  /// Lo que se espera oír.
  final String target;

  final String languageTag;

  @override
  ConsumerState<PronunciationCheck> createState() => _PronunciationCheckState();
}

class _PronunciationCheckState extends ConsumerState<PronunciationCheck> {
  bool _listening = false;
  PronunciationMatch? _match;
  bool _noSpeech = false;

  /// Por qué no se pudo escuchar, si no se pudo.
  SttFailure? _failure;

  Future<void> _listen() async {
    final SpeechAvailabilityController controller = ref.read(
      speechAvailabilityProvider.notifier,
    );

    // El permiso se pide al tocar, nunca antes (FR-018).
    if (!ref.read(speechAvailabilityProvider).canRecord) {
      final bool granted = await controller.requestMicrophone();
      if (!granted) {
        setState(() => _failure = SttFailure.permissionDenied);
        return;
      }
    }

    setState(() {
      _listening = true;
      _noSpeech = false;
      _match = null;
      _failure = null;
    });

    final SttOutcome outcome = await ref
        .read(sttServiceProvider)
        .listenOnce(widget.languageTag);
    if (!mounted) return;
    setState(() => _listening = false);

    switch (outcome) {
      case SttRecognized(:final String text):
        setState(
          () => _match = matchPronunciation(
            recognized: text,
            target: widget.target,
          ),
        );
      case SttNoSpeech():
        setState(() => _noSpeech = true);
      case SttUseAlternative(:final SttFailure failure):
        setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    // No se consulta ninguna disponibilidad para decidir si el botón existe.
    // Esa consulta es justo lo que hacía desaparecer el control cuando la
    // detección se equivocaba, y se equivoca sola: en el navegador la lista de
    // voces llega vacía en la primera consulta y el permiso de micrófono no se
    // conoce hasta que se pide. El permiso se sigue pidiendo al tocar (FR-018).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OutlinedButton.icon(
          onPressed: _listening ? null : _listen,
          icon: Icon(_listening ? Icons.mic : Icons.mic_none),
          label: Text(_listening ? 'Escuchando…' : 'Pronunciar la palabra'),
        ),
        if (_noSpeech) ...<Widget>[
          const SizedBox(height: 8),
          const Text('No se escuchó nada. Prueba otra vez, más cerca.'),
        ],
        if (_failure != null) ...<Widget>[
          const SizedBox(height: 8),
          // Se queda escrito debajo del botón, que sigue ahí: el repaso no
          // depende de esto —la nota la pone la persona— y lo único que hace
          // falta es que sepa por qué no se oyó y pueda volver a intentarlo.
          Semantics(
            liveRegion: true,
            child: Text(
              microphoneFailureMessage(_failure!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
        if (_match != null) ...<Widget>[
          const SizedBox(height: 8),
          _Verdict(match: _match!),
        ],
      ],
    );
  }
}

/// Qué se oyó y si valió.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.match});

  final PronunciationMatch match;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool ok = match.accepted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          ok ? Icons.check_circle_outline : Icons.replay,
          color: ok ? colors.primary : colors.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            // Al fallar se dice qué se entendió, que es lo único accionable:
            // sin eso no se sabe si el problema fue la pronunciación o el
            // ruido de la calle (FR-017).
            ok
                ? 'Bien pronunciado.'
                : 'Se entendió «${match.heard}». Se esperaba '
                      '«${match.expected}».',
          ),
        ),
      ],
    );
  }
}
