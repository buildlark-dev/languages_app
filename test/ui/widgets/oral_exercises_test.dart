/// Verifica los dos ejercicios orales, incluida la ruta sin micrófono.
///
/// SC-008 exige que el 100 % de los ejercicios de escucha y pronunciación se pueda
/// completar y aprobar con el micrófono denegado y el sonido apagado. Estas pruebas
/// son esa verificación.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/l10n/app_localizations.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/core/exercise.dart';
import 'package:languages_app/services/speech/speech_availability.dart';
import 'package:languages_app/services/speech/stt_service.dart';
import 'package:languages_app/services/speech/tts_service.dart';
import 'package:languages_app/ui/providers/speech_providers.dart';
import 'package:languages_app/ui/widgets/listening_exercise_view.dart';
import 'package:languages_app/ui/widgets/pronunciation_exercise_view.dart';

import '../../fakes/fake_stt_service.dart';
import '../../fakes/fake_tts_service.dart';

const ListeningExercise listening = ListeningExercise(
  spokenText: 'I am a nurse at the hospital.',
  question: '¿Cuál es su profesión?',
  options: <String>['Profesora', 'Enfermera', 'Médica'],
  answerIndex: 1,
  explanation: 'Dice «nurse», que es enfermera y no médica.',
  transcriptFallback: 'I am a nurse at the hospital.',
);

const PronunciationExercise pronunciation = PronunciationExercise(
  targetPhrase: 'Nice to meet you.',
  translation: 'Encantado de conocerte.',
  explanation: 'Fórmula fija de presentación, no se traduce literalmente.',
  writtenFallback: 'Nice to meet you.',
);

void main() {
  late FakeTtsService tts;
  late FakeSttService stt;

  setUp(() async {
    tts = FakeTtsService();
    stt = FakeSttService();

    // El doble no habla hasta inicializarse, igual que el real: así una prueba no
    // puede pasar con audio que en producción sería un no-op silencioso.
    await tts.initialize('en-US');
  });

  Widget wrap(Widget child, {SpeechAvailability? availability}) =>
      ProviderScope(
        overrides: [
          ttsServiceProvider.overrideWithValue(tts),
          sttServiceProvider.overrideWithValue(stt),
          if (availability != null)
            speechAvailabilityProvider.overrideWith(
              () => _FixedAvailability(availability),
            ),
        ],
        child: MaterialApp(
          theme: lightTheme,
          localizationsDelegates: const <LocalizationsDelegate<Object>>[
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      );

  group('comprensión auditiva', () {
    testWidgets('con voz disponible ofrece el botón de escuchar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ListeningExerciseView(
            exercise: listening,
            selectedIndex: null,
            onSelect: (_) {},
          ),
          availability: const SpeechAvailability.full(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Escuchar'), findsOne);
      expect(find.textContaining('repetirlo cuantas veces'), findsOne);
      // El transcript NO se revela antes de responder: sería dar la respuesta.
      expect(find.text('Transcripción'), findsNothing);
    });

    testWidgets('tocar escuchar lee el texto del ejercicio', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ListeningExerciseView(
            exercise: listening,
            selectedIndex: null,
            onSelect: (_) {},
          ),
          availability: const SpeechAvailability.full(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Escuchar'));
      await tester.pumpAndSettle();

      expect(tts.spoken, <String>['I am a nurse at the hospital.']);
    });

    testWidgets('SIN voz muestra el transcript y explica por qué', (
      WidgetTester tester,
    ) async {
      // T129. Lo esencial: el ejercicio sigue siendo completable, y la persona
      // entiende que el problema es su dispositivo, no la app.
      await tester.pumpWidget(
        wrap(
          ListeningExerciseView(
            exercise: listening,
            selectedIndex: null,
            onSelect: (_) {},
          ),
          availability: const SpeechAvailability(
            tts: TtsAvailability.languageMissing,
            stt: SttAvailability.onDeviceReady,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Transcripción'), findsOne);
      expect(find.text('I am a nurse at the hospital.'), findsOne);
      expect(
        find.text('Tu dispositivo no tiene instalada la voz en inglés.'),
        findsOne,
      );
      // Y no hay ningún botón de audio que no sonaría.
      expect(find.widgetWithText(FilledButton, 'Escuchar'), findsNothing);
    });

    testWidgets('las opciones se pueden responder sin audio', (
      WidgetTester tester,
    ) async {
      final List<int> chosen = <int>[];
      await tester.pumpWidget(
        wrap(
          ListeningExerciseView(
            exercise: listening,
            selectedIndex: null,
            onSelect: chosen.add,
          ),
          availability: const SpeechAvailability.none(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Enfermera'));
      await tester.pumpAndSettle();

      expect(chosen, <int>[1]);
    });

    testWidgets('tras responder con audio se revela lo que decía', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ListeningExerciseView(
            exercise: listening,
            selectedIndex: 1,
            onSelect: (_) {},
            answered: true,
          ),
          availability: const SpeechAvailability.full(),
        ),
      );
      await tester.pumpAndSettle();

      // Es la forma de aprender qué se oyó de verdad frente a lo que se creyó oír.
      expect(find.text('Lo que decía'), findsOne);
    });
  });

  group('pronunciación', () {
    testWidgets('con micrófono ofrece hablar y también escribir', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PronunciationExerciseView(
            exercise: pronunciation,
            languageTag: 'en-US',
            onAttempt: (_) {},
          ),
          availability: const SpeechAvailability.full(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Hablar'), findsOne);
      // Siempre a un toque: nadie debería tener que hablar en voz alta en el bus.
      expect(find.text('Prefiero escribirlo'), findsOne);
    });

    testWidgets('el permiso NO se pide al mostrar el ejercicio (FR-018)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PronunciationExerciseView(
            exercise: pronunciation,
            languageTag: 'en-US',
            onAttempt: (_) {},
          ),
          availability: const SpeechAvailability.full(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        stt.permissionRequests,
        0,
        reason:
            'Pedirlo al abrir la lección es la forma más rápida de que lo '
            'nieguen',
      );
    });

    testWidgets('SIN micrófono en el aparato muestra la alternativa escrita', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PronunciationExerciseView(
            exercise: pronunciation,
            languageTag: 'en-US',
            onAttempt: (_) {},
          ),
          availability: const SpeechAvailability(
            tts: TtsAvailability.available,
            stt: SttAvailability.noMicrophone,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Escríbelo'), findsOne);
      expect(find.textContaining('No detectamos micrófono'), findsOne);
      expect(find.widgetWithText(FilledButton, 'Hablar'), findsNothing);
    });

    testWidgets('SE PUEDE ACERTAR por escrito con el micrófono denegado', (
      WidgetTester tester,
    ) async {
      // T128, y la razón de ser de SC-008.
      final List<PronunciationAttempt> attempts = <PronunciationAttempt>[];
      await tester.pumpWidget(
        wrap(
          PronunciationExerciseView(
            exercise: pronunciation,
            languageTag: 'en-US',
            onAttempt: attempts.add,
          ),
          availability: const SpeechAvailability(
            tts: TtsAvailability.unsupportedPlatform,
            stt: SttAvailability.permissionDenied,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Con el permiso aún sin conceder, el micrófono SÍ se ofrece —de otro
      // modo no habría forma de concederlo— y junto a él está la salida
      // escrita, a un toque. Esa es la ruta que SC-008 exige que exista.
      expect(find.text('Hablar'), findsOne);
      await tester.tap(find.text('Prefiero escribirlo'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Nice to meet you.');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Comprobar'));
      await tester.pumpAndSettle();

      expect(attempts, <PronunciationAttempt>[PronunciationAttempt.correct]);
    });

    testWidgets('una respuesta escrita incorrecta se marca como fallo', (
      WidgetTester tester,
    ) async {
      final List<PronunciationAttempt> attempts = <PronunciationAttempt>[];
      await tester.pumpWidget(
        wrap(
          PronunciationExerciseView(
            exercise: pronunciation,
            languageTag: 'en-US',
            onAttempt: attempts.add,
          ),
          availability: const SpeechAvailability.none(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'good morning');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Comprobar'));
      await tester.pumpAndSettle();

      expect(attempts, <PronunciationAttempt>[PronunciationAttempt.incorrect]);
    });

    testWidgets('hablar bien acierta', (WidgetTester tester) async {
      stt.outcome = const SttRecognized('nice to meet you');
      final List<PronunciationAttempt> attempts = <PronunciationAttempt>[];

      await tester.pumpWidget(
        wrap(
          PronunciationExerciseView(
            exercise: pronunciation,
            languageTag: 'en-US',
            onAttempt: attempts.add,
          ),
          availability: const SpeechAvailability.full(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Hablar'));
      await tester.pumpAndSettle();

      expect(stt.listenCalls, 1);
      expect(attempts, <PronunciationAttempt>[PronunciationAttempt.correct]);
    });

    testWidgets('hablar mal muestra qué se entendió y qué se esperaba', (
      WidgetTester tester,
    ) async {
      // FR-017.
      stt.outcome = const SttRecognized('good morning everyone');

      await tester.pumpWidget(
        wrap(
          PronunciationExerciseView(
            exercise: pronunciation,
            languageTag: 'en-US',
            onAttempt: (_) {},
          ),
          availability: const SpeechAvailability.full(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Hablar'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Entendimos: «good morning everyone»'),
        findsOne,
      );
      expect(find.textContaining('Esperábamos: «nice to meet you»'), findsOne);
      // Y se aclara que no se puntúa el acento.
      expect(find.textContaining('No se puntúa el acento'), findsOne);
    });

    testWidgets('el reconocimiento no disponible lleva a la alternativa', (
      WidgetTester tester,
    ) async {
      // Paso 3 de la degradación. No es un error: es la ruta válida.
      stt.outcome = const SttUseAlternative(SttAvailability.networkOnly);
      final List<PronunciationAttempt> attempts = <PronunciationAttempt>[];

      await tester.pumpWidget(
        wrap(
          PronunciationExerciseView(
            exercise: pronunciation,
            languageTag: 'en-US',
            onAttempt: attempts.add,
          ),
          availability: const SpeechAvailability.full(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Hablar'));
      await tester.pumpAndSettle();

      expect(find.text('Escríbelo'), findsOne);
      expect(
        attempts,
        isEmpty,
        reason: 'No es ni acierto ni fallo: se ofrece otra ruta',
      );
    });

    testWidgets('tras tres intentos fallidos se puede continuar sin penalizar', (
      WidgetTester tester,
    ) async {
      // FR-020: un fallo de reconocimiento no es un error de contenido, y nadie
      // debe quedar atrapado en un ejercicio.
      stt.outcome = const SttNoSpeech();
      final List<PronunciationAttempt> attempts = <PronunciationAttempt>[];

      await tester.pumpWidget(
        wrap(
          PronunciationExerciseView(
            exercise: pronunciation,
            languageTag: 'en-US',
            onAttempt: attempts.add,
          ),
          availability: const SpeechAvailability.full(),
        ),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.widgetWithText(FilledButton, 'Hablar'));
        await tester.pumpAndSettle();
      }

      // Tres silencios no han contado como fallos de contenido.
      expect(attempts, isEmpty);

      final Finder skip = find.widgetWithText(
        OutlinedButton,
        'Continuar sin pronunciar',
      );
      expect(skip, findsOne);

      await tester.tap(skip);
      await tester.pumpAndSettle();

      expect(attempts, <PronunciationAttempt>[
        PronunciationAttempt.unavailable,
      ]);
    });
  });
}

/// Fija la disponibilidad de voz sin pasar por los servicios.
class _FixedAvailability extends SpeechAvailabilityController {
  _FixedAvailability(this._value);

  final SpeechAvailability _value;

  @override
  SpeechAvailability build() => _value;
}
