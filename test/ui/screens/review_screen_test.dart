/// Verifica el repaso en pantalla: la tanda, el estado «al día» y la siembra.
///
/// La prueba que más importa es la del estado al día: FR-030 prohíbe resolver
/// «no hay nada que repasar» abriendo una sesión vacía, y eso solo se puede
/// comprobar mirando que el botón de entrar **no exista**.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/app/l10n/app_localizations.dart';
import 'package:languages_app/app/theme.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/services/auth/auth_service.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/core/thresholds.dart';
import 'package:languages_app/ui/providers/auth_providers.dart';
import 'package:languages_app/ui/providers/clock_providers.dart';
import 'package:languages_app/ui/providers/content_providers.dart';
import 'package:languages_app/ui/providers/review_providers.dart';
import 'package:languages_app/ui/providers/speech_providers.dart';
import 'package:languages_app/ui/screens/module_screen.dart';
import 'package:languages_app/ui/screens/review_screen.dart';
import 'package:languages_app/ui/widgets/review_summary_card.dart';

import '../../fakes/fake_auth_service.dart';
import '../../fakes/fake_catalog.dart';
import '../../fakes/fake_review_store.dart';
import '../../fakes/fake_tts_service.dart';

void main() {
  final DateTime today = DateTime(2026, 10, 7);

  late FakeReviewStore store;

  setUp(() => store = FakeReviewStore());

  ReviewCard cardOf(String term, {required DateTime due, int step = 0}) =>
      ReviewCard(
        moduleId: 'XXM1',
        term: term,
        translation: 'traducción de $term',
        intervalStep: step,
        dueDate: due,
      );

  /// Monta [child] con sesión abierta, idioma elegido y reloj fijo.
  ///
  /// La cola es por estudiante y por curso, así que sin ambas cosas
  /// `reviewScopeProvider` es nulo y el almacén nunca se consulta: una prueba
  /// montada sin ellas pasaría sin probar nada.
  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      reviewStoreProvider.overrideWithValue(store),
      clockProvider.overrideWithValue(fixedClock(today)),
      authServiceProvider.overrideWithValue(
        FakeAuthService(
          initialUser: const StudentIdentity(
            uid: 'u1',
            email: 'ana@example.com',
          ),
        ),
      ),
      courseCatalogProvider.overrideWithValue(const FakeCatalog()),
      selectedCourseIdProvider.overrideWith(PreselectedCourse.new),
      ttsServiceProvider.overrideWithValue(FakeTtsService()),
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
      home: child,
    ),
  );

  group('tanda de repaso', () {
    testWidgets('pregunta en español y oculta la respuesta', (
      WidgetTester tester,
    ) async {
      store = FakeReviewStore(cards: <ReviewCard>[cardOf('name', due: today)]);
      await tester.pumpWidget(wrap(const ReviewScreen()));
      await tester.pumpAndSettle();

      expect(find.text('traducción de name'), findsOne);
      // Destapar antes de intentar recordar vaciaría el ejercicio.
      expect(find.text('name'), findsNothing);
      expect(find.text('Mostrar la respuesta'), findsOne);
      // Y sin destapar no se puede calificar.
      expect(find.textContaining('Me costó'), findsNothing);
    });

    testWidgets('destapar muestra la palabra y las tres calificaciones', (
      WidgetTester tester,
    ) async {
      store = FakeReviewStore(cards: <ReviewCard>[cardOf('name', due: today)]);
      await tester.pumpWidget(wrap(const ReviewScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mostrar la respuesta'));
      await tester.pumpAndSettle();

      expect(find.text('name'), findsOne);
      expect(find.textContaining('No la recordaba'), findsOne);
      expect(find.textContaining('Me costó'), findsOne);
      expect(find.textContaining('Fue inmediato'), findsOne);
    });

    testWidgets('cada tarjeta se guarda al calificarla, no al terminar', (
      WidgetTester tester,
    ) async {
      // Un repaso son hechos independientes: haber recordado la primera sigue
      // siendo cierto aunque se cierre la app en la segunda.
      store = FakeReviewStore(
        cards: <ReviewCard>[
          cardOf('name', due: today),
          cardOf('city', due: today),
        ],
      );
      await tester.pumpWidget(wrap(const ReviewScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tarjeta 1 de 2'), findsOne);
      await tester.tap(find.text('Mostrar la respuesta'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Fue inmediato'));
      await tester.pumpAndSettle();

      expect(store.saved, hasLength(1));
      expect(store.saved.single.term, 'name');
      // Con facilidad avanza dos pasos.
      expect(store.saved.single.intervalStep, 2);
      expect(store.saved.single.dueDate, DateTime(2026, 10, 14));
      expect(find.text('Tarjeta 2 de 2'), findsOne);
      // La respuesta de la siguiente vuelve a estar oculta.
      expect(find.text('Mostrar la respuesta'), findsOne);
    });

    testWidgets('fallar devuelve la palabra al día siguiente', (
      WidgetTester tester,
    ) async {
      store = FakeReviewStore(
        cards: <ReviewCard>[cardOf('name', due: today, step: maxSrsStep)],
      );
      await tester.pumpWidget(wrap(const ReviewScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Mostrar la respuesta'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('No la recordaba'));
      await tester.pumpAndSettle();

      expect(store.saved.single.intervalStep, 0);
      expect(store.saved.single.dueDate, DateTime(2026, 10, 8));
      expect(store.saved.single.lapses, 1);
    });

    testWidgets('al terminar informa qué vuelve mañana, sin nota', (
      WidgetTester tester,
    ) async {
      store = FakeReviewStore(
        cards: <ReviewCard>[
          cardOf('name', due: today),
          cardOf('city', due: today),
        ],
      );
      await tester.pumpWidget(wrap(const ReviewScreen()));
      await tester.pumpAndSettle();

      for (int i = 0; i < 2; i++) {
        await tester.tap(find.text('Mostrar la respuesta'));
        await tester.pumpAndSettle();
        await tester.tap(
          i == 0
              ? find.textContaining('Fue inmediato')
              : find.textContaining('No la recordaba'),
        );
        await tester.pumpAndSettle();
      }

      expect(find.text('Repaso terminado'), findsOne);
      expect(find.text('1 palabra vuelve mañana.'), findsOne);
      // Un repaso no se aprueba ni se suspende.
      expect(find.textContaining('%'), findsNothing);
      expect(find.textContaining('Reintentar'), findsNothing);
    });

    testWidgets('solo entran las vencidas, no toda la cola', (
      WidgetTester tester,
    ) async {
      store = FakeReviewStore(
        cards: <ReviewCard>[
          cardOf('name', due: today),
          cardOf('city', due: addDays(today, 5)),
        ],
      );
      await tester.pumpWidget(wrap(const ReviewScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Tarjeta 1 de 1'), findsOne);
    });
  });

  group('estado «al día» en la pantalla principal', () {
    testWidgets('con cola vacía explica de dónde saldrá el repaso', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(Scaffold(body: ReviewSummaryCard(onOpenReview: () {}))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Todavía no hay repaso'), findsOne);
      expect(find.text('Repasar ahora'), findsNothing);
    });

    testWidgets('sin vencidas dice «estás al día» y NO ofrece entrar', (
      WidgetTester tester,
    ) async {
      store = FakeReviewStore(
        cards: <ReviewCard>[cardOf('name', due: addDays(today, 3))],
      );
      await tester.pumpWidget(
        wrap(Scaffold(body: ReviewSummaryCard(onOpenReview: () {}))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estás al día con el repaso'), findsOne);
      expect(find.textContaining('1 palabra en seguimiento'), findsOne);
      // FR-030: un recorrido de cero tarjetas se lee como un error de la app.
      expect(find.text('Repasar ahora'), findsNothing);
    });

    testWidgets('con vencidas dice cuántas y ofrece entrar', (
      WidgetTester tester,
    ) async {
      store = FakeReviewStore(
        cards: <ReviewCard>[
          cardOf('name', due: today),
          cardOf('city', due: addDays(today, -2)),
          cardOf('home', due: addDays(today, 9)),
        ],
      );
      int opened = 0;
      await tester.pumpWidget(
        wrap(Scaffold(body: ReviewSummaryCard(onOpenReview: () => opened++))),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 palabras para repasar'), findsOne);
      await tester.tap(find.text('Repasar ahora'));
      expect(opened, 1);
    });

    testWidgets('el singular se dice en singular', (WidgetTester tester) async {
      store = FakeReviewStore(cards: <ReviewCard>[cardOf('name', due: today)]);
      await tester.pumpWidget(
        wrap(Scaffold(body: ReviewSummaryCard(onOpenReview: () {}))),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 palabra para repasar'), findsOne);
    });

    testWidgets('el conteo baja al repasar, sin recargar la pantalla', (
      WidgetTester tester,
    ) async {
      store = FakeReviewStore(cards: <ReviewCard>[cardOf('name', due: today)]);
      await tester.pumpWidget(
        wrap(
          Scaffold(
            body: Column(
              children: <Widget>[
                ReviewSummaryCard(onOpenReview: () {}),
                const Expanded(child: ReviewScreen()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 palabra para repasar'), findsOne);

      await tester.tap(find.text('Mostrar la respuesta'));
      await tester.pumpAndSettle();
      // Con la tarjeta de resumen encima, el botón de calificar queda fuera del
      // área visible, y `tap` toca unas coordenadas donde no hay nada en lugar
      // de fallar. Hay que traerlo a la vista primero.
      final Finder easy = find.textContaining('Fue inmediato');
      await tester.ensureVisible(easy);
      await tester.pumpAndSettle();
      await tester.tap(easy);
      await tester.pumpAndSettle();

      expect(find.text('Estás al día con el repaso'), findsOne);
    });
  });

  group('siembra al empezar un módulo (FR-028)', () {
    Widget moduleMap() => ModuleScreen(
      course: fakeCourse,
      level: fakeCourse.levels.single,
      progress: const StudentProgress(
        uid: 'u1',
        courseId: 'xx',
        currentLevelId: 'A1',
        levelStates: <String, LevelState>{'A1': LevelState.unlocked},
      ),
      onOpenModule: (_) {},
      onOpenLevelExam: (_) {},
    );

    testWidgets('entrar en un módulo siembra su vocabulario', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(moduleMap()));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Módulo de prueba'));
      await tester.pumpAndSettle();

      expect(store.seedCalls, <String>['XXM1']);
      expect(store.allCards.single.term, 'one');
      expect(store.allCards.single.dueDate, today, reason: 'vence hoy mismo');
    });

    testWidgets('volver a entrar no reinicia la memoria ya construida', (
      WidgetTester tester,
    ) async {
      // La palabra ya está en el paso 4. Entrar otra vez en el módulo no puede
      // devolverla al día 1.
      store = FakeReviewStore(
        cards: <ReviewCard>[
          ReviewCard(
            moduleId: 'XXM1',
            term: 'one',
            translation: 'uno',
            intervalStep: 4,
            dueDate: addDays(today, 30),
          ),
        ],
      );
      await tester.pumpWidget(wrap(moduleMap()));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Módulo de prueba'));
      await tester.pumpAndSettle();

      expect(store.seedCalls, <String>['XXM1']);
      expect(store.allCards.single.intervalStep, 4);
      expect(store.allCards.single.dueDate, addDays(today, 30));
    });
  });
}

/// Arranca con el idioma ya elegido.
///
/// La cola es por curso, y `selectedCourseIdProvider` nace nulo. Se resuelve
/// sobrescribiendo el proveedor y no llamando a `select()` desde `initState`:
/// Riverpod prohíbe modificar un proveedor mientras el árbol se construye, y lo
/// prohíbe con razón —dos widgets escuchando el mismo valor lo verían distinto—.
class PreselectedCourse extends SelectedCourse {
  @override
  String? build() => 'xx';
}
