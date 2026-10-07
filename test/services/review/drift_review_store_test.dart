/// Verifica el recorrido completo contra la base real: sembrar, calificar y
/// comprobar que la palabra sale de la cola del día.
///
/// El `ReviewDao` ya tiene sus propias pruebas. Esta existe porque un adaptador
/// delgado es justo donde un parámetro cruzado —`moduleId` por `term`, `uid` por
/// `courseId`— pasa desapercibido: cada método compila igual de bien mal
/// conectado que bien conectado.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/vocabulary_item.dart';
import 'package:languages_app/engine/srs_scheduler.dart';
import 'package:languages_app/services/db/app_database.dart';
import 'package:languages_app/services/db/review_dao.dart';
import 'package:languages_app/services/review/drift_review_store.dart';
import 'package:languages_app/services/review/review_store.dart';

void main() {
  late AppDatabase db;
  late ReviewStore store;

  const String uid = 'u1';
  const String courseId = 'en';
  final DateTime today = DateTime(2026, 10, 7);

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    store = DriftReviewStore(ReviewDao(db));
  });

  tearDown(() async => db.close());

  Future<void> seedTwo() => store.seedModule(
    uid: uid,
    courseId: courseId,
    moduleId: 'A1M1',
    vocabulary: const <VocabularyItem>[
      VocabularyItem(term: 'name', translation: 'el nombre'),
      VocabularyItem(term: 'city', translation: 'la ciudad'),
    ],
    today: today,
  );

  test('sembrar deja las palabras vencidas el mismo día', () async {
    await seedTwo();

    expect(await store.dueCount(uid: uid, courseId: courseId, today: today), 2);
    expect(await store.totalCount(uid: uid, courseId: courseId), 2);
    final List<ReviewCard> due = await store.dueCards(
      uid: uid,
      courseId: courseId,
      today: today,
    );
    expect(
      due.map((ReviewCard c) => c.term),
      containsAll(<String>['name', 'city']),
    );
    expect(due.first.translation, isNotEmpty, reason: 'la traducción viaja');
  });

  test(
    'calificar saca la palabra de la cola de hoy y la trae el día debido',
    () async {
      await seedTwo();
      final List<ReviewCard> due = await store.dueCards(
        uid: uid,
        courseId: courseId,
        today: today,
      );
      final ReviewCard first = due.firstWhere(
        (ReviewCard c) => c.term == 'name',
      );

      await store.save(
        uid: uid,
        courseId: courseId,
        card: gradeCard(card: first, grade: RecallGrade.easy, today: today),
      );

      // Hoy ya solo queda la otra.
      final List<ReviewCard> stillDue = await store.dueCards(
        uid: uid,
        courseId: courseId,
        today: today,
      );
      expect(stillDue.map((ReviewCard c) => c.term), <String>['city']);
      // Y la calificada vuelve a los siete días, no antes.
      expect(
        await store.dueCount(
          uid: uid,
          courseId: courseId,
          today: addDays(today, 6),
        ),
        1,
      );
      expect(
        await store.dueCount(
          uid: uid,
          courseId: courseId,
          today: addDays(today, 7),
        ),
        2,
      );
      // Calificar no crea tarjetas nuevas: actualiza la misma fila.
      expect(await store.totalCount(uid: uid, courseId: courseId), 2);
    },
  );

  test('la cola de otro estudiante no se mezcla', () async {
    await seedTwo();

    expect(
      await store.dueCount(uid: 'otro', courseId: courseId, today: today),
      0,
    );
    expect(await store.totalCount(uid: 'otro', courseId: courseId), 0);
    // Ni la del mismo estudiante en otro idioma.
    expect(await store.dueCount(uid: uid, courseId: 'fr', today: today), 0);
  });

  test('volver a sembrar no reinicia lo ya aprendido', () async {
    await seedTwo();
    final ReviewCard card = (await store.dueCards(
      uid: uid,
      courseId: courseId,
      today: today,
    )).first;
    await store.save(
      uid: uid,
      courseId: courseId,
      card: gradeCard(card: card, grade: RecallGrade.easy, today: today),
    );

    // El estudiante vuelve a entrar en el módulo una semana después.
    await store.seedModule(
      uid: uid,
      courseId: courseId,
      moduleId: 'A1M1',
      vocabulary: const <VocabularyItem>[
        VocabularyItem(term: 'name', translation: 'el nombre'),
        VocabularyItem(term: 'city', translation: 'la ciudad'),
      ],
      today: addDays(today, 7),
    );

    expect(await store.totalCount(uid: uid, courseId: courseId), 2);
    final List<ReviewCard> all = await store.dueCards(
      uid: uid,
      courseId: courseId,
      today: addDays(today, 7),
    );
    final ReviewCard reseeded = all.firstWhere(
      (ReviewCard c) => c.term == card.term,
    );
    expect(reseeded.intervalStep, 2, reason: 'conserva su avance');
  });
}
