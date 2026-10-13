/// Pruebas de los tres widgets de ejercicio y del panel de retroalimentación.
///
/// Se prueban por separado de la pantalla porque tienen comportamiento propio que
/// la pantalla no ejercita del todo: palabras repetidas, accesibilidad y el
/// renderizado del marcado.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/ui/widgets/feedback_panel.dart';
import 'package:languages_app/ui/widgets/gap_fill_field.dart';
import 'package:languages_app/ui/widgets/sentence_builder.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: lightTheme,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  group('SentenceBuilder', () {
    testWidgets('empieza vacío y con todas las fichas disponibles', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SentenceBuilder(
            tokens: const <String>['My', 'sister', 'is'],
            chosenIndices: const <int>[],
            onToggle: (_) {},
          ),
        ),
      );

      expect(find.text('Toca las palabras para armar la frase'), findsOne);
      expect(find.widgetWithText(OutlinedButton, 'My'), findsOne);
      expect(find.widgetWithText(OutlinedButton, 'sister'), findsOne);
    });

    testWidgets('tocar una ficha la notifica por su índice', (
      WidgetTester tester,
    ) async {
      final List<int> toggled = <int>[];
      await tester.pumpWidget(
        wrap(
          SentenceBuilder(
            tokens: const <String>['My', 'sister', 'is'],
            chosenIndices: const <int>[],
            onToggle: toggled.add,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'sister'));
      expect(toggled, <int>[1]);
    });

    testWidgets('una palabra repetida se maneja por posición, no por texto', (
      WidgetTester tester,
    ) async {
      // «the» aparece dos veces. Si las fichas se identificaran por su texto,
      // colocar una quitaría también su gemela de la zona disponible.
      await tester.pumpWidget(
        wrap(
          SentenceBuilder(
            tokens: const <String>['at', 'the', 'end', 'of', 'the', 'street'],
            chosenIndices: const <int>[1],
            onToggle: (_) {},
          ),
        ),
      );

      // Una colocada arriba y otra todavía disponible abajo.
      expect(find.widgetWithText(FilledButton, 'the'), findsOne);
      expect(find.widgetWithText(OutlinedButton, 'the'), findsOne);
    });

    testWidgets('las fichas anuncian qué hacen al lector de pantalla', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SentenceBuilder(
            tokens: const <String>['casa'],
            chosenIndices: const <int>[],
            onToggle: (_) {},
          ),
        ),
      );

      // «Añadir casa» en lugar de solo «casa»: es lo que hace usable el
      // ejercicio sin ver la pantalla.
      expect(find.bySemanticsLabel('Añadir casa'), findsOne);
    });

    testWidgets('deshabilitado no responde al toque', (
      WidgetTester tester,
    ) async {
      final List<int> toggled = <int>[];
      await tester.pumpWidget(
        wrap(
          SentenceBuilder(
            tokens: const <String>['My'],
            chosenIndices: const <int>[],
            onToggle: toggled.add,
            enabled: false,
          ),
        ),
      );

      await tester.tap(find.widgetWithText(OutlinedButton, 'My'));
      expect(toggled, isEmpty);
    });
  });

  group('GapFillField', () {
    testWidgets('muestra la frase con su hueco y la pista', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          GapFillField(
            wordCount: 1,
            sentenceWithGap: 'My brother ___ a doctor.',
            hint: 'tercera persona',
            onChanged: (_) {},
            onSubmit: () {},
          ),
        ),
      );

      expect(find.text('My brother ___ a doctor.'), findsOne);
      expect(find.text('tercera persona'), findsOne);
    });

    testWidgets('el lector de pantalla oye «espacio en blanco», no guiones', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          GapFillField(
            wordCount: 1,
            sentenceWithGap: 'My brother ___ a doctor.',
            onChanged: (_) {},
            onSubmit: () {},
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('My brother espacio en blanco a doctor.'),
        findsOne,
      );
    });

    testWidgets('notifica lo que se escribe', (WidgetTester tester) async {
      final List<String> typed = <String>[];
      await tester.pumpWidget(
        wrap(
          GapFillField(
            wordCount: 1,
            sentenceWithGap: '___ a doctor.',
            onChanged: typed.add,
            onSubmit: () {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), "is");
      expect(typed.last, 'is');
    });

    testWidgets('enviar desde el teclado dispara onSubmit', (
      WidgetTester tester,
    ) async {
      int submits = 0;
      await tester.pumpWidget(
        wrap(
          GapFillField(
            wordCount: 1,
            sentenceWithGap: '___ a doctor.',
            onChanged: (_) {},
            onSubmit: () => submits++,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'is');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(submits, 1);
    });
  });

  group('FeedbackPanel', () {
    testWidgets('al acertar no muestra la respuesta esperada', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const FeedbackPanel(
            correct: true,
            explanation: 'Tercera persona del singular.',
            expectedAnswer: 'is',
          ),
        ),
      );

      expect(find.text('Correcto'), findsOne);
      expect(find.textContaining('Se esperaba'), findsNothing);
    });

    testWidgets('al fallar muestra qué se esperaba Y el motivo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const FeedbackPanel(
            correct: false,
            explanation: 'Tercera persona del singular.',
            expectedAnswer: 'is',
          ),
        ),
      );

      expect(find.text('Incorrecto'), findsOne);
      expect(find.text('Se esperaba: is'), findsOne);
      // FR-025: el motivo es lo que enseña.
      expect(find.textContaining('Tercera persona'), findsOne);
    });

    testWidgets('renderiza el marcado en lugar de mostrarlo crudo', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const FeedbackPanel(
            correct: false,
            explanation:
                '<p>Con <code>doesn\'t</code> el verbo pierde la -s: '
                '<s>doesn\'t works</s>.</p>',
          ),
        ),
      );

      expect(find.textContaining('<p>'), findsNothing);
      expect(find.textContaining('<code>'), findsNothing);
      // El tachado debe llegar como estilo, porque marca la forma incorrecta.
      final Iterable<Text> texts = tester.widgetList<Text>(find.byType(Text));
      expect(texts, isNotEmpty);
    });
  });
}
