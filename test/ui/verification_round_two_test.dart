/// Los tres fallos encontrados verificando en un iPhone, fijados.
///
/// La cuarta cosa que se reportó —el micrófono del ejercicio de pronunciación—
/// no está aquí y es deliberado: lo que cambió para intentar arreglarlo es una
/// llamada al navegador (`getUserMedia`) que no existe en la VM de Dart, así
/// que una prueba en este entorno solo comprobaría el camino que ya funcionaba.
/// Está dicho en `verification.md` y hace falta un iPhone para cerrarlo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/speech_route_observer.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/ui/widgets/exam_result_label.dart';

void main() {
  group('T164 · el examen dice con qué nota se aprobó', () {
    // Reportado tras reiniciar el dispositivo: se veían las lecciones
    // aprobadas, pero del examen solo se ofrecía volver a presentarlo, sin el
    // resultado obtenido. El dato estaba guardado; faltaba enseñarlo.

    test('la nota del mejor intento se redondea a entero', () {
      final ActivityScore score = ActivityScore(
        kind: ActivityKind.levelExam,
        bestScore: 0.857,
        lastAttemptAt: DateTime(2026, 10, 13),
      );

      expect(percentageOf(score), 86);
      expect(passedExamLabel(score), 'Aprobado con un 86 %.');
    });

    test('sin puntaje guardado se dice «Aprobado» a secas', () {
      // Puede pasar con un progreso traído de otro dispositivo si algún día
      // cambia el esquema. Quedarse sin tarjeta por eso sería peor que
      // quedarse sin el número.
      expect(passedExamLabel(null), 'Aprobado.');
    });

    test('un examen suspendido dice cuánto se sacó', () {
      // Visto en el emulador Pixel 7: el examen de A1 nunca se aprobó, y la
      // tarjeta solo decía «Necesitas 80 % para superar el nivel». Quien
      // suspendió por poco y quien suspendió por mucho veían lo mismo, y es
      // justo lo que se reportó como «no muestra el resultado que se obtuvo».
      final ActivityScore score = ActivityScore(
        kind: ActivityKind.levelExam,
        bestScore: 0.65,
        lastAttemptAt: DateTime(2026, 10, 13),
      );

      expect(
        pendingExamLabel(score, pending: 'Necesitas 80 %.'),
        'Tu mejor intento: 65 %. Necesitas 80 %.',
      );
    });

    test('sin intentos no se inventa ningún resultado', () {
      // Antes de presentarse por primera vez no hay nada que contar, y un
      // «0 %» sería una nota que nadie sacó.
      expect(
        pendingExamLabel(null, pending: 'Necesitas 80 %.'),
        'Necesitas 80 %.',
      );
    });

    test('un 80 % justo se dice como 80 y no como 79', () {
      // El umbral de los exámenes. Si el redondeo de la tarjeta no coincide
      // con el de la pantalla de resultados, el mismo examen parece aprobado
      // en una pantalla y raspando en la otra.
      final ActivityScore score = ActivityScore(
        kind: ActivityKind.moduleExam,
        bestScore: 0.8,
        lastAttemptAt: DateTime(2026, 10, 13),
      );

      expect(passedExamLabel(score), 'Aprobado con un 80 %.');
    });
  });

  group('audio que no sobrevive al cambio de pantalla', () {
    // Reportado: un texto largo seguía sonando al pasar al ejercicio siguiente
    // o al salir a otra pantalla, sin ningún control a mano para pararlo.

    testWidgets('cualquier navegación calla la voz', (
      WidgetTester tester,
    ) async {
      int stops = 0;
      final SpeechRouteObserver observer = SpeechRouteObserver(() => stops++);

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: <NavigatorObserver>[observer],
          home: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      const Scaffold(body: Text('otra pantalla')),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      // La ruta inicial ya cuenta como cambio de pantalla.
      expect(stops, 1);

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(stops, 2, reason: 'Entrar en otra pantalla tiene que callar');

      // Se vuelve con el navegador y no con `pageBack`, que busca el botón de
      // retroceso de una barra que esta pantalla de prueba no tiene.
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(stops, 3, reason: 'Volver atrás también');
    });
  });
}
