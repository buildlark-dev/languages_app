/// Verifica el recorrido completo de una lección.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/l10n/app_localizations.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/core/lesson.dart';
import 'package:languages_app/core/module.dart';
import 'package:languages_app/engine/scoring.dart';
import 'package:languages_app/ui/screens/lesson_screen.dart';

import 'package:languages_app/ui/providers/speech_providers.dart';

import '../../fakes/fake_stt_service.dart';
import '../../fakes/fake_tts_service.dart';
import '../../fakes/test_lesson.dart';

void main() {
  late List<ScoreResult> saved;

  setUp(() => saved = <ScoreResult>[]);

  // Sin llamar a prepare(), la disponibilidad de voz es «ninguna», que es el caso
  // de SC-008: los ejercicios orales se resuelven por su alternativa accesible.
  Widget wrap(Module module, Lesson lesson) => ProviderScope(
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
      home: LessonScreen(
        module: module,
        lesson: lesson,
        onCompleted: (Lesson _, ScoreResult result) async => saved.add(result),
      ),
    ),
  );

  /// Avanza desde el material de estudio hasta los ejercicios.
  ///
  /// Hace scroll primero porque el material de estudio es largo y un `ListView`
  /// no construye lo que está fuera de pantalla, así que el botón del final no
  /// existe para los buscadores hasta que se desplaza hasta él.
  Future<void> startExercises(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Empezar ejercicios'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Empezar ejercicios'));
    await tester.pumpAndSettle();
  }

  /// Responde la opción múltiple en curso y continúa.
  Future<void> answerChoice(WidgetTester tester, String option) async {
    await tapOption(tester, option);
    await tapButton(tester, "Comprobar");
    await tapButton(tester, "Continuar");
  }

  testWidgets('empieza en el material de estudio, no en los ejercicios', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(testModule, testLesson));
    await tester.pumpAndSettle();

    expect(find.text('Al terminar podrás'), findsOne);
    expect(find.text('Vocabulario'), findsOne);
    // El botón del final existe, pero hay que desplazarse: un ListView no
    // construye lo que está fuera de pantalla.
    await tester.scrollUntilVisible(
      find.text("Empezar ejercicios"),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text("Empezar ejercicios"), findsOne);
    // Nada se ha guardado por abrir la lección.
    expect(saved, isEmpty);
  });

  testWidgets('el material de estudio muestra vocabulario y gramática', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(testModule, testLesson));
    await tester.pumpAndSettle();

    expect(find.text('name'), findsOne);
    expect(find.text('el nombre', skipOffstage: false), findsOne);
    // El HTML de la gramática se renderiza, no se muestra crudo.
    expect(find.textContaining('<p>'), findsNothing);
  });

  testWidgets('no se puede comprobar sin responder', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(testModule, testLesson));
    await tester.pumpAndSettle();
    await startExercises(tester);

    final FilledButton button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Comprobar'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('responder bien muestra la explicación, no solo el veredicto', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(testModule, testLesson));
    await tester.pumpAndSettle();
    await startExercises(tester);

    await tapOption(tester, 'is');
    await tapButton(tester, 'Comprobar');

    expect(find.text('Correcto'), findsOne);
    // FR-025: el motivo, no solo la respuesta.
    expect(find.textContaining('tercera persona'), findsOne);
  });

  testWidgets('responder mal muestra qué se esperaba y por qué', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(testModule, testLesson));
    await tester.pumpAndSettle();
    await startExercises(tester);

    await tapOption(tester, 'are');
    await tapButton(tester, 'Comprobar');

    expect(find.text('Incorrecto'), findsOne);
    expect(find.textContaining('Se esperaba: is'), findsOne);
    expect(find.textContaining('tercera persona'), findsOne);
  });

  testWidgets('tras corregir no se puede cambiar la respuesta', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(testModule, testLesson));
    await tester.pumpAndSettle();
    await startExercises(tester);

    await tapOption(tester, 'are');
    await tapButton(tester, 'Comprobar');

    final OutlinedButton option = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'is'),
    );
    expect(option.onPressed, isNull);
  });

  testWidgets('aprobar con el 100 % guarda el resultado una sola vez', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(testModule, testLesson));
    await tester.pumpAndSettle();
    await startExercises(tester);

    // Los cinco ejercicios, todos bien.
    await answerChoice(tester, 'is');
    await _answerGap(tester, 'is');
    await _buildSentence(tester, <String>['My', 'sister', 'is', 'a', 'teacher.']);
    await _answerListening(tester, 'Enfermera');
    await _answerGap(tester, 'Nice to meet you.');

    expect(find.text('100 %'), findsOne);
    expect(find.text('Lección aprobada'), findsOne);
    expect(saved, hasLength(1));
    expect(saved.single.passed, isTrue);
    expect(saved.single.percentage, 100);
  });

  testWidgets('abandonar a mitad NO guarda nada', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(testModule, testLesson));
    await tester.pumpAndSettle();
    await startExercises(tester);

    await answerChoice(tester, 'is');
    await _answerGap(tester, 'is');

    // Aquí el estudiante cierra. La sesión vive en memoria, así que su mejor
    // puntaje anterior queda intacto: una lección interrumpida no es una lección
    // fallada.
    expect(saved, isEmpty);
  });

  testWidgets('suspender ofrece reintentar y explica el umbral', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(wrap(testModule, testLesson));
    await tester.pumpAndSettle();
    await startExercises(tester);

    // Tres de cinco mal: 40 %.
    await answerChoice(tester, 'are');
    await _answerGap(tester, 'are');
    await _buildSentence(tester, <String>['teacher.', 'is', 'My']);
    await _answerListening(tester, 'Enfermera');
    await _answerGap(tester, 'Nice to meet you.');

    expect(find.text('40 %'), findsOne);
    expect(find.textContaining('Necesitas 70 %'), findsOne);
    expect(find.widgetWithText(FilledButton, 'Reintentar'), findsOne);
    expect(saved.single.passed, isFalse);
  });

  testWidgets('cabe a 360 dp en todas las fases', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(testModule, testLesson));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'material de estudio');

    await startExercises(tester);
    expect(tester.takeException(), isNull, reason: 'ejercicios');

    await answerChoice(tester, 'is');
    await _answerGap(tester, 'is');
    await _buildSentence(tester, <String>['My', 'sister', 'is', 'a', 'teacher.']);
    await _answerListening(tester, 'Enfermera');
    await _answerGap(tester, 'Nice to meet you.');
    expect(tester.takeException(), isNull, reason: 'resultado');
  });
}

/// Toca un botón del final del recorrido, desplazándose si hace falta.
///
/// `ListView(children:)` **también** instancia sus hijos de forma diferida, no
/// solo `ListView.builder`. Cuando el panel de retroalimentación crece, el botón
/// de avanzar deja de existir en el árbol, y entonces `ensureVisible` no sirve:
/// no se puede desplazar hasta algo que todavía no se construyó. Hay que buscarlo
/// desplazando.
Future<void> tapButton(WidgetTester tester, String label) async {
  final Finder button = find.widgetWithText(FilledButton, label);

  if (button.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      button,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> tapOption(WidgetTester tester, String label) async {
  final Finder option = find.widgetWithText(OutlinedButton, label).first;
  if (option.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      option,
      300,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> _answerGap(WidgetTester tester, String answer) async {
  await tester.enterText(find.byType(TextField), answer);
  await tester.pumpAndSettle();
  await tapButton(tester, "Comprobar");
  await tapButton(tester, "Continuar");
}

Future<void> _buildSentence(WidgetTester tester, List<String> words) async {
  for (final String word in words) {
    await tapOption(tester, word);
  }
  await tapButton(tester, "Comprobar");
  await tapButton(tester, "Continuar");
}

Future<void> _answerListening(WidgetTester tester, String option) async {
  await tapOption(tester, option);
  await tapButton(tester, "Comprobar");
  await tapButton(tester, "Continuar");
}
