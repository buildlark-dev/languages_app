/// Verifica el cableado del armazón: tema, localización y catálogo inyectado.
///
/// Las pantallas de estudio son la Fase 7. Esta prueba existe para no afirmar
/// que el cableado funciona sin comprobarlo: construye la app con un catálogo
/// falso y confirma que arranca, localiza en español y muestra lo que el
/// catálogo le pasa.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/app.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/core/content_pack.dart';
import 'package:languages_app/core/course.dart';
import 'package:languages_app/core/exam.dart';
import 'package:languages_app/core/exercise.dart';
import 'package:languages_app/core/lesson.dart';
import 'package:languages_app/core/level.dart';
import 'package:languages_app/core/module.dart';
import 'package:languages_app/core/teaching_material.dart';
import 'package:languages_app/core/vocabulary_item.dart';

/// Curso de prueba mínimo.
///
/// Que se pueda construir uno sin tocar `lib/content/` es la demostración de que
/// la interfaz no conoce ningún idioma concreto (Principio I).
const Course fakeCourse = Course(
  id: 'xx',
  name: 'Idioma de prueba',
  studyLanguageTag: 'xx-XX',
  supportLanguageTag: 'es',
  levels: <Level>[
    Level(
      id: 'A1',
      name: 'A1 · Prueba',
      description: 'Nivel de prueba.',
      modules: <Module>[
        Module(
          id: 'XXM1',
          order: 1,
          title: 'Módulo de prueba',
          canDo: 'Hacer algo de prueba.',
          vocabulary: <VocabularyItem>[
            VocabularyItem(term: 'one', translation: 'uno'),
          ],
          grammar: GrammarExplanation(title: 'Prueba', bodyHtml: '<p>Prueba</p>'),
          examples: <BilingualExample>[
            BilingualExample(target: 'One.', spanish: 'Uno.'),
          ],
          reading: ReadingPassage(
            id: 'XXM1R',
            title: 'Prueba',
            paragraphs: <String>['Texto de prueba.'],
          ),
          lessons: <Lesson>[
            Lesson(
              id: 'XXM1L1',
              title: 'Lección de prueba',
              exercises: <Exercise>[
                MultipleChoiceExercise(
                  prompt: '¿Uno?',
                  options: <String>['a', 'b', 'c'],
                  answerIndex: 0,
                  explanation: 'Explicación de prueba suficientemente larga.',
                ),
              ],
            ),
          ],
          moduleExam: Exam(
            id: 'XXM1EX',
            scope: ExamScope.module,
            exercises: <Exercise>[],
          ),
        ),
      ],
      levelExam: Exam(id: 'XXEX', scope: ExamScope.level, exercises: <Exercise>[]),
    ),
  ],
  upcomingLevelIds: <String>['A2', 'B1'],
);

class _FakePack implements ContentPack {
  const _FakePack();

  @override
  String get courseId => 'xx';

  @override
  Course get course => fakeCourse;
}

class _FakeCatalog implements CourseCatalog {
  const _FakeCatalog();

  @override
  List<ContentPack> get packs => const <ContentPack>[_FakePack()];

  @override
  ContentPack? packFor(String courseId) =>
      courseId == 'xx' ? const _FakePack() : null;
}

void main() {
  testWidgets('arranca y muestra el catálogo que recibe', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LanguagesApp(catalog: _FakeCatalog()));
    await tester.pumpAndSettle();

    // Cadenas en español, desde el ARB.
    expect(find.text('Idiomas'), findsWidgets);
    expect(find.text('Aprende desde cero hasta hablar con fluidez'), findsOne);
    expect(find.text('Elige el idioma que quieres aprender'), findsOne);

    // El curso inyectado aparece, sin que la interfaz lo importe.
    expect(find.text('Idioma de prueba'), findsOne);
    expect(find.textContaining('1 nivel(es) con contenido'), findsOne);
    expect(find.textContaining('2 próximo'), findsOne);
  });

  testWidgets('no avisa de almacenamiento degradado cuando todo va bien', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LanguagesApp(catalog: _FakeCatalog()));
    await tester.pumpAndSettle();

    expect(find.text('Tu avance no se está guardando'), findsNothing);
  });

  testWidgets('avisa cuando el almacenamiento está degradado', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const LanguagesApp(catalog: _FakeCatalog(), storageDegraded: true),
    );
    await tester.pumpAndSettle();

    // FR-043: el fallo tiene que ser visible, no silencioso.
    expect(find.text('Tu avance no se está guardando'), findsOne);
    expect(
      find.textContaining('se perderá al cerrar la app'),
      findsOne,
    );
  });

  testWidgets('respeta el modo oscuro', (WidgetTester tester) async {
    await tester.pumpWidget(
      const LanguagesApp(catalog: _FakeCatalog(), themeMode: ThemeMode.dark),
    );
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme, isNotNull);
  });

  testWidgets('cabe en 360 dp de ancho sin desbordes', (
    WidgetTester tester,
  ) async {
    // SC-010. Un desborde en Flutter pinta la franja amarilla y registra una
    // excepción, que la prueba hace fallar.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const LanguagesApp(catalog: _FakeCatalog(), storageDegraded: true),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  test('los botones del tema garantizan el área táctil mínima', () {
    // El Principio VII pide 48 dp. Se fija una vez en el tema para que ninguna
    // pantalla tenga que acordarse.
    expect(minTouchTarget, 48);
    expect(
      lightTheme.filledButtonTheme.style?.minimumSize?.resolve(
        <WidgetState>{},
      )?.height,
      minTouchTarget,
    );
  });
}
