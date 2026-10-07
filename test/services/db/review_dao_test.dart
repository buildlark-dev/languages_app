/// Verifica la cola de repaso y el índice del que depende su rendimiento.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/vocabulary_item.dart';
import 'package:languages_app/services/db/app_database.dart';
import 'package:languages_app/services/db/review_dao.dart';

void main() {
  late AppDatabase db;
  late ReviewDao dao;

  const String uid = 'u1';
  const String courseId = 'en';
  final DateTime today = DateTime(2026, 10, 6);

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    dao = ReviewDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('sembrar un módulo crea una tarjeta por palabra, vencida hoy', () async {
    await dao.seed(
      uid: uid,
      courseId: courseId,
      moduleId: 'A1M1',
      vocabulary: const <VocabularyItem>[
        VocabularyItem(term: 'name', translation: 'el nombre'),
        VocabularyItem(term: 'city', translation: 'la ciudad'),
      ],
      today: today,
    );

    final List<ReviewCard> due = await dao.dueOn(
      uid: uid,
      courseId: courseId,
      today: today,
    );
    expect(due, hasLength(2));
    expect(due.every((ReviewCard c) => c.intervalStep == 0), isTrue);
  });

  test('volver a sembrar NO reinicia el progreso de memoria ya construido',
      () async {
    const List<VocabularyItem> vocabulary = <VocabularyItem>[
      VocabularyItem(term: 'name', translation: 'el nombre'),
    ];

    await dao.seed(
      uid: uid,
      courseId: courseId,
      moduleId: 'A1M1',
      vocabulary: vocabulary,
      today: today,
    );

    // El estudiante la repasó y avanzó al intervalo 3.
    await dao.upsert(
      uid: uid,
      courseId: courseId,
      card: ReviewCard(
        moduleId: 'A1M1',
        term: 'name',
        translation: 'el nombre',
        intervalStep: 3,
        dueDate: DateTime(2026, 10, 22),
      ),
    );

    // Vuelve a entrar al módulo, lo que siembra otra vez.
    await dao.seed(
      uid: uid,
      courseId: courseId,
      moduleId: 'A1M1',
      vocabulary: vocabulary,
      today: today,
    );

    final int total = await dao.totalCount(uid: uid, courseId: courseId);
    expect(total, 1, reason: 'No debe duplicar la tarjeta');

    final List<ReviewCard> due = await dao.dueOn(
      uid: uid,
      courseId: courseId,
      today: today,
    );
    expect(
      due,
      isEmpty,
      reason: 'La tarjeta avanzada no debe volver a vencer hoy',
    );
  });

  test('solo devuelve lo vencido, ordenado por fecha', () async {
    Future<void> add(String term, DateTime due) => dao.upsert(
      uid: uid,
      courseId: courseId,
      card: ReviewCard(
        moduleId: 'A1M1',
        term: term,
        translation: term,
        intervalStep: 0,
        dueDate: due,
      ),
    );

    await add('ayer', DateTime(2026, 10, 5));
    await add('hoy', DateTime(2026, 10, 6));
    await add('manana', DateTime(2026, 10, 7));

    final List<ReviewCard> due = await dao.dueOn(
      uid: uid,
      courseId: courseId,
      today: today,
    );

    expect(due.map((ReviewCard c) => c.term), <String>['ayer', 'hoy']);
    expect(await dao.dueCountOn(uid: uid, courseId: courseId, today: today), 2);
  });

  test('una cola sin vencidas devuelve lista vacía, no error', () async {
    await dao.upsert(
      uid: uid,
      courseId: courseId,
      card: ReviewCard(
        moduleId: 'A1M1',
        term: 'name',
        translation: 'el nombre',
        intervalStep: 5,
        dueDate: DateTime(2027, 1, 1),
      ),
    );

    expect(
      await dao.dueOn(uid: uid, courseId: courseId, today: today),
      isEmpty,
    );
    expect(await dao.dueCountOn(uid: uid, courseId: courseId, today: today), 0);
  });

  test('consultar lo vencido con 2.000 tarjetas tarda menos de 50 ms', () async {
    // La meta de rendimiento del plan. Lo que se verifica de verdad es que el
    // índice idx_review_due está en uso: sin él, esto degrada a recorrido
    // completo de tabla y el margen desaparece.
    await db.batch((batch) {
      batch.insertAll(db.reviewCards, <ReviewCardRow>[
        for (int i = 0; i < 2000; i++)
          ReviewCardRow(
            uid: uid,
            courseId: courseId,
            moduleId: 'A1M${i % 4 + 1}',
            term: 'term$i',
            translation: 'palabra $i',
            intervalStep: i % 6,
            // La mitad vencidas, la mitad futuras.
            dueDate: today.add(Duration(days: i.isEven ? -1 : 30)),
            lapses: 0,
          ),
      ]);
    });

    final Stopwatch watch = Stopwatch()..start();
    final List<ReviewCard> due = await dao.dueOn(
      uid: uid,
      courseId: courseId,
      today: today,
    );
    watch.stop();

    expect(due, hasLength(1000));
    expect(
      watch.elapsedMilliseconds,
      lessThan(50),
      reason:
          'Tardó ${watch.elapsedMilliseconds} ms. Revisar que idx_review_due '
          'exista sobre (uid, course_id, due_date)',
    );
  });

  test('el índice idx_review_due existe en el esquema', () async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'idx_review_due'",
        )
        .get();
    expect(
      rows,
      hasLength(1),
      reason: 'Es el índice del que depende la meta de 50 ms',
    );
  });
}
