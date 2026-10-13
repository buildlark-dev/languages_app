/// Comprueba contra la base real que guardar el progreso **no** deshace un
/// repaso ya calificado.
///
/// Es el hueco que dejó pasar el fallo: las pruebas del repaso usan el almacén
/// falso y las del progreso usan el suyo, así que nunca se cruzaban. Aquí
/// trabajan los dos sobre la **misma** base.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/core/vocabulary_item.dart';
import 'package:languages_app/engine/srs_scheduler.dart';
import 'package:languages_app/services/db/app_database.dart';
import 'package:languages_app/services/db/progress_dao.dart';
import 'package:languages_app/services/db/review_dao.dart';

void main() {
  late AppDatabase db;
  late ProgressDao progress;
  late ReviewDao review;

  const String uid = 'u1';
  const String courseId = 'en';
  final DateTime today = DateTime(2026, 10, 8);

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    progress = ProgressDao(db);
    review = ReviewDao(db);
  });

  tearDown(() async => db.close());

  Future<void> seedAndSaveBase() async {
    await progress.save(
      const StudentProgress(
        uid: uid,
        courseId: courseId,
        currentLevelId: 'A1',
        levelStates: <String, LevelState>{'A1': LevelState.unlocked},
      ),
    );
    await review.seed(
      uid: uid,
      courseId: courseId,
      moduleId: 'A1M1',
      vocabulary: const <VocabularyItem>[
        VocabularyItem(term: 'name', translation: 'el nombre'),
      ],
      today: today,
    );
  }

  test(
    'calificar y después guardar el progreso NO revierte la tarjeta',
    () async {
      await seedAndSaveBase();

      // Así arranca la app: carga el progreso, y con él la instantánea de la cola.
      final StudentProgress loaded = (await progress.load(
        uid: uid,
        courseId: courseId,
      ))!;
      expect(loaded.reviewCards['A1M1|name']!.intervalStep, 0);

      // El estudiante repasa: la tarjeta avanza en la tabla, no en la
      // instantánea que la app tiene en memoria.
      final ReviewCard graded = gradeCard(
        card: loaded.reviewCards['A1M1|name']!,
        grade: RecallGrade.easy,
        today: today,
      );
      await review.upsert(uid: uid, courseId: courseId, card: graded);
      expect(graded.intervalStep, 2);

      // Y después termina una lección cualquiera, lo que guarda el progreso
      // **con la instantánea vieja dentro**.
      await progress.save(loaded.copyWith(xp: 20));

      final StudentProgress after = (await progress.load(
        uid: uid,
        courseId: courseId,
      ))!;
      expect(
        after.reviewCards['A1M1|name']!.intervalStep,
        2,
        reason: 'el repaso no puede deshacerse al guardar el progreso',
      );
      expect(after.reviewCards['A1M1|name']!.dueDate, graded.dueDate);
      expect(after.xp, 20, reason: 'el resto del progreso sí se guarda');
    },
  );

  test('la tarjeta tampoco reaparece vencida en la cola de hoy', () async {
    await seedAndSaveBase();
    final StudentProgress loaded = (await progress.load(
      uid: uid,
      courseId: courseId,
    ))!;

    await review.upsert(
      uid: uid,
      courseId: courseId,
      card: gradeCard(
        card: loaded.reviewCards['A1M1|name']!,
        grade: RecallGrade.easy,
        today: today,
      ),
    );
    await progress.save(loaded.copyWith(xp: 20));

    // Lo que ve la pantalla principal: ya no vence nada hoy.
    expect(
      await review.dueCountOn(uid: uid, courseId: courseId, today: today),
      0,
    );
  });

  test('una tarjeta que llega de la nube sí entra', () async {
    // La fusión no puede ser «ignorar lo que trae el progreso»: entonces el
    // repaso dejaría de sincronizarse entre dispositivos.
    await seedAndSaveBase();
    final StudentProgress loaded = (await progress.load(
      uid: uid,
      courseId: courseId,
    ))!;

    await progress.save(
      loaded.copyWith(
        reviewCards: <String, ReviewCard>{
          ...loaded.reviewCards,
          'A1M2|city': ReviewCard(
            moduleId: 'A1M2',
            term: 'city',
            translation: 'la ciudad',
            intervalStep: 3,
            dueDate: addDays(today, 16),
          ),
        },
      ),
    );

    final StudentProgress after = (await progress.load(
      uid: uid,
      courseId: courseId,
    ))!;
    expect(after.reviewCards['A1M2|city']!.intervalStep, 3);
  });

  test('con pasos distintos gana entera la tarjeta más avanzada', () async {
    // El lado menos avanzado suele ser la instantánea caducada del mismo
    // dispositivo, así que su fecha tampoco vale.
    await seedAndSaveBase();
    final StudentProgress loaded = (await progress.load(
      uid: uid,
      courseId: courseId,
    ))!;

    await review.upsert(
      uid: uid,
      courseId: courseId,
      card: ReviewCard(
        moduleId: 'A1M1',
        term: 'name',
        translation: 'el nombre',
        intervalStep: 4,
        dueDate: addDays(today, 35),
        lapses: 1,
      ),
    );

    // El progreso trae un paso menor pero una fecha más próxima.
    await progress.save(
      loaded.copyWith(
        reviewCards: <String, ReviewCard>{
          'A1M1|name': ReviewCard(
            moduleId: 'A1M1',
            term: 'name',
            translation: 'el nombre',
            intervalStep: 2,
            dueDate: addDays(today, 7),
          ),
        },
      ),
    );

    final ReviewCard after = (await progress.load(
      uid: uid,
      courseId: courseId,
    ))!.reviewCards['A1M1|name']!;

    expect(after.intervalStep, 4, reason: 'el paso mayor');
    expect(
      after.dueDate,
      addDays(today, 35),
      reason: 'la fecha de la más avanzada, no la de la instantánea',
    );
    expect(after.lapses, 1, reason: 'los fallos no se olvidan');
  });
  test('con el mismo paso sigue ganando la fecha más próxima', () async {
    // El caso real de dos dispositivos: `mergeProgress` ya resolvió el paso
    // antes de llegar aquí, así que lo que queda por decidir es la fecha, y
    // ahí sí vale «ante la duda, repasar antes».
    await seedAndSaveBase();
    final StudentProgress loaded = (await progress.load(
      uid: uid,
      courseId: courseId,
    ))!;

    await review.upsert(
      uid: uid,
      courseId: courseId,
      card: ReviewCard(
        moduleId: 'A1M1',
        term: 'name',
        translation: 'el nombre',
        intervalStep: 3,
        dueDate: addDays(today, 16),
      ),
    );

    await progress.save(
      loaded.copyWith(
        reviewCards: <String, ReviewCard>{
          'A1M1|name': ReviewCard(
            moduleId: 'A1M1',
            term: 'name',
            translation: 'el nombre',
            intervalStep: 3,
            dueDate: addDays(today, 2),
          ),
        },
      ),
    );

    final ReviewCard after = (await progress.load(
      uid: uid,
      courseId: courseId,
    ))!.reviewCards['A1M1|name']!;

    expect(after.intervalStep, 3);
    expect(after.dueDate, addDays(today, 2));
  });
}
