/// Fija los seis ajustes que salieron de recorrer la app a mano.
///
/// Cada uno es un fallo que ninguna prueba vio porque todas montaban la pieza
/// por separado: el campo de texto nunca cambiaba de ejercicio, el micrófono
/// nunca empezaba sin permiso, y la pantalla de ajustes nunca se abría sin que
/// otra hubiera preparado la voz antes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/l10n/app_localizations.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/exercise.dart';
import 'package:languages_app/engine/answer_check.dart';
import 'package:languages_app/engine/answer_matcher.dart';
import 'package:languages_app/engine/scoring.dart';
import 'package:languages_app/services/speech/speech_availability.dart';
import 'package:languages_app/services/speech/stt_service.dart';
import 'package:languages_app/services/speech/tts_service.dart';
import 'package:languages_app/ui/providers/speech_providers.dart';
import 'package:languages_app/ui/screens/exercise_runner.dart';
import 'package:languages_app/ui/widgets/gap_fill_field.dart';
import 'package:languages_app/ui/widgets/listen_button.dart';
import 'package:languages_app/ui/widgets/pronunciation_exercise_view.dart';

import '../../fakes/fake_stt_service.dart';
import '../../fakes/fake_tts_service.dart';

void main() {
  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      ttsServiceProvider.overrideWithValue(FakeTtsService()),
      sttServiceProvider.overrideWithValue(FakeSttService()),
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
      home: Scaffold(body: child),
    ),
  );

  group('1 · un recuadro por palabra', () {
    testWidgets('una respuesta de una palabra tiene un solo recuadro', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          GapFillField(
            sentenceWithGap: 'She ___ a nurse.',
            wordCount: 1,
            onChanged: (_) {},
            onSubmit: () {},
          ),
        ),
      );

      expect(find.byType(TextField), findsOne);
      expect(find.text('Tu respuesta'), findsOne);
    });

    testWidgets('una de dos palabras tiene dos, numerados', (
      WidgetTester tester,
    ) async {
      // El número de recuadros es la única pista sobre cuántas palabras faltan,
      // que un campo libre dejaba adivinar.
      await tester.pumpWidget(
        wrap(
          GapFillField(
            sentenceWithGap: '___ a market near here?',
            wordCount: 2,
            onChanged: (_) {},
            onSubmit: () {},
          ),
        ),
      );

      expect(find.byType(TextField), findsExactly(2));
      expect(find.text('Palabra 1'), findsOne);
      expect(find.text('Palabra 2'), findsOne);
    });

    testWidgets('lo escrito se une con espacios', (WidgetTester tester) async {
      String reported = '';
      await tester.pumpWidget(
        wrap(
          GapFillField(
            sentenceWithGap: '___ a market near here?',
            wordCount: 2,
            onChanged: (String v) => reported = v,
            onSubmit: () {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), 'is');
      await tester.enterText(find.byType(TextField).at(1), 'there');

      expect(reported, 'is there');
    });

    testWidgets('un recuadro vacío no deja un espacio suelto', (
      WidgetTester tester,
    ) async {
      // La variante corta —`aren't` frente a `are not`— cabe en un recuadro
      // dejando el otro en blanco, y eso no debe producir un espacio final.
      String reported = '';
      await tester.pumpWidget(
        wrap(
          GapFillField(
            sentenceWithGap: 'They ___ here.',
            wordCount: 2,
            onChanged: (String v) => reported = v,
            onSubmit: () {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).at(0), "aren't");

      expect(reported, "aren't");
    });
  });

  group('3 · lo escrito no pasa al ejercicio siguiente', () {
    testWidgets('el recuadro aparece vacío en la pregunta siguiente', (
      WidgetTester tester,
    ) async {
      // El fallo real: el campo guarda lo tecleado en su propio controlador,
      // dentro de un `State` que Flutter reutilizaba al cambiar de ejercicio.
      await tester.pumpWidget(
        wrap(
          ExerciseRunner(
            exercises: const <Exercise>[
              GapFillExercise(
                sentenceWithGap: 'My brother ___ a doctor.',
                acceptedAnswers: <String>['is'],
                explanation: 'Tercera persona del singular del verbo be.',
              ),
              GapFillExercise(
                sentenceWithGap: 'They ___ at home.',
                acceptedAnswers: <String>['are'],
                explanation: 'Plural del verbo be en presente.',
              ),
            ],
            kind: ActivityKind.lesson,
            onCompleted: (ScoreResult _) async {},
            onFinishedBuilder: (ScoreResult _, VoidCallback _) =>
                const Text('fin'),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'is');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Comprobar'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
      await tester.pumpAndSettle();

      expect(find.text('They ___ at home.'), findsOne);
      final TextField next = tester.widget<TextField>(find.byType(TextField));
      expect(
        next.controller?.text ?? '',
        isEmpty,
        reason: 'la respuesta anterior no puede quedarse escrita',
      );
    });
  });

  group('5 · apóstrofo', () {
    test('se acepta sin apóstrofo y se dice cómo se escribe', () {
      final ({AnswerMatch match, String? expected}) result = checkAnswer(
        'arent',
        <String>["aren't", 'are not'],
      );

      expect(result.match, AnswerMatch.apostrophe);
      expect(result.match.isCorrect, isTrue);
      expect(result.expected, "aren't");
    });

    test('con apóstrofo es coincidencia exacta, sin aviso', () {
      expect(
        checkAnswer("aren't", <String>["aren't"]).match,
        AnswerMatch.exact,
      );
      expect(
        spellingNoteFor(
          const GapFillExercise(
            sentenceWithGap: 'They ___ here.',
            acceptedAnswers: <String>["aren't"],
            explanation: 'Negativo del verbo be en plural, forma contraída.',
          ),
          const AnswerDraft(typed: "aren't"),
        ),
        isNull,
      );
    });

    test('el aviso nombra la forma correcta', () {
      expect(
        spellingNoteFor(
          const GapFillExercise(
            sentenceWithGap: 'He ___ work on Sundays.',
            acceptedAnswers: <String>["doesn't", 'does not'],
            explanation: 'Negativo del presente simple en tercera persona.',
          ),
          const AnswerDraft(typed: 'doesnt'),
        ),
        'Se escribe «doesn\'t», con apóstrofo.',
      );
    });

    test('una respuesta equivocada sigue siendo equivocada', () {
      // Ignorar el apóstrofo no puede convertir `is` en `isn't`.
      expect(checkAnswer('isnt', <String>['is']).match, AnswerMatch.none);
      expect(checkAnswer('was', <String>["aren't"]).match, AnswerMatch.none);
    });

    testWidgets('el aviso se ve al acertar sin apóstrofo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ExerciseRunner(
            exercises: const <Exercise>[
              GapFillExercise(
                sentenceWithGap: 'They ___ here.',
                acceptedAnswers: <String>["aren't", 'are not'],
                explanation: 'Negativo del verbo be en plural.',
              ),
            ],
            kind: ActivityKind.lesson,
            onCompleted: (ScoreResult _) async {},
            onFinishedBuilder: (ScoreResult _, VoidCallback _) =>
                const Text('fin'),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'arent');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Comprobar'));
      await tester.pumpAndSettle();

      expect(find.text('Correcto'), findsOne);
      expect(find.textContaining('con apóstrofo'), findsOne);
    });
  });

  group('2 · el micrófono se puede conceder', () {
    testWidgets('sin permiso todavía, el botón de hablar SÍ aparece', (
      WidgetTester tester,
    ) async {
      // El fallo: `canRecord` es falso antes del primer permiso, y la vista
      // escondía el botón. Sin botón no hay forma de pedirlo, así que en una
      // instalación nueva el micrófono no aparecía nunca.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ttsServiceProvider.overrideWithValue(FakeTtsService()),
            sttServiceProvider.overrideWithValue(FakeSttService()),
            speechAvailabilityProvider.overrideWith(_DeniedAvailability.new),
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
              body: PronunciationExerciseView(
                exercise: const PronunciationExercise(
                  targetPhrase: 'Nice to meet you.',
                  translation: 'Encantado de conocerte.',
                  explanation: 'Fórmula fija de presentación.',
                  writtenFallback: 'Nice to meet you.',
                ),
                languageTag: 'en-US',
                onAttempt: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hablar'), findsOne);
      // Y la salida escrita sigue a un toque, que es lo que SC-008 exige.
      expect(find.text('Prefiero escribirlo'), findsOne);
    });

    test('sin micrófono físico no se ofrece nada que pedir', () {
      const SpeechAvailability none = SpeechAvailability(
        tts: TtsAvailability.available,
        stt: SttAvailability.noMicrophone,
      );

      expect(none.canOfferMicrophone, isFalse);
      expect(none.canRecord, isFalse);
    });

    test('con permiso pendiente sí hay algo que pedir', () {
      const SpeechAvailability pending = SpeechAvailability(
        tts: TtsAvailability.available,
        stt: SttAvailability.permissionDenied,
      );

      expect(pending.canOfferMicrophone, isTrue);
      expect(pending.canRecord, isFalse, reason: 'todavía no se puede grabar');
    });
  });

  group('7 · el audio no depende de que la detección acierte', () {
    testWidgets('el botón de escuchar se dibuja aunque se crea que no hay voz', (
      WidgetTester tester,
    ) async {
      // La detección se equivoca sola: en web la lista de voces llega vacía en
      // la primera consulta. Cuando eso decidía si el botón existía, la
      // función desaparecía entera y sin rastro.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ttsServiceProvider.overrideWithValue(
              FakeTtsService(
                initialAvailability: TtsAvailability.languageMissing,
              ),
            ),
            sttServiceProvider.overrideWithValue(FakeSttService()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ListenButton(text: 'name')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.volume_up_outlined), findsOne);
    });

    testWidgets('al tocarlo sin voz dice que se puede seguir, sin exigir nada', (
      WidgetTester tester,
    ) async {
      // La contrapartida de dibujarlo siempre: no puede callarse. Pero lo que
      // dice **no puede ser una tarea de configuración**: «instala una voz»
      // echa de la app a quien solo quería estudiar. Los pasos siguen
      // existiendo, detrás de un «¿Cómo?» opcional y para la plataforma real.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ttsServiceProvider.overrideWithValue(
              FakeTtsService(
                initialAvailability: TtsAvailability.languageMissing,
              ),
            ),
            sttServiceProvider.overrideWithValue(FakeSttService()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: ListenButton(text: 'name')),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.volume_up_outlined));
      await tester.pumpAndSettle();

      expect(find.textContaining('se aprueba igual'), findsOne);
      expect(
        find.textContaining('Ajustes'),
        findsNothing,
        reason: 'El aviso informa; no manda a configurar el aparato',
      );

      // Y para quien sí quiera instalarla, los pasos están a un toque.
      await tester.tap(find.text('¿Cómo?'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Salida de texto a voz'), findsOne);
      expect(find.textContaining('No es obligatorio'), findsOne);
    });

    test('hablar reintenta la preparación antes de rendirse', () async {
      // El caso de web: la primera consulta no encontró voces, la segunda sí.
      // Rendirse para siempre por la primera deja la app muda toda la sesión.
      final FakeTtsService tts = FakeTtsService(
        initialAvailability: TtsAvailability.languageMissing,
      );
      await tts.initialize('en-US');
      expect(await tts.speak('name'), SpeakOutcome.noVoice);

      tts.initialAvailability = TtsAvailability.available;
      await tts.initialize('en-US');

      expect(await tts.speak('name'), SpeakOutcome.spoken);
      expect(tts.spoken, <String>['name']);
    });
  });
}

/// Disponibilidad con el permiso aún sin conceder.
class _DeniedAvailability extends SpeechAvailabilityController {
  @override
  SpeechAvailability build() => const SpeechAvailability(
    tts: TtsAvailability.available,
    stt: SttAvailability.permissionDenied,
  );
}
