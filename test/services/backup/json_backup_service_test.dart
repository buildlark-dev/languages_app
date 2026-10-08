/// Verifica el respaldo: ida y vuelta, rechazos y la fusión al importar.
///
/// La prueba que da sentido a todo el archivo es «importar un respaldo viejo no
/// pierde el progreso posterior». Es lo contrario de lo que la palabra
/// «restaurar» sugiere, y es la razón de que el contrato no ofrezca una
/// operación de reemplazo.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:languages_app/core/activity_score.dart';
import 'package:languages_app/core/app_info.dart';
import 'package:languages_app/core/clock.dart';
import 'package:languages_app/core/level_state.dart';
import 'package:languages_app/core/placement_result.dart';
import 'package:languages_app/core/review_card.dart';
import 'package:languages_app/core/student_progress.dart';
import 'package:languages_app/services/backup/backup_document.dart';
import 'package:languages_app/services/backup/backup_service.dart';
import 'package:languages_app/services/backup/json_backup_service.dart';

import '../../fakes/fake_progress_store.dart';

void main() {
  final DateTime exportDay = DateTime(2026, 10, 8, 9, 30);

  late FakeProgressStore store;
  late JsonBackupService service;

  StudentProgress progressWith({
    int xp = 150,
    int streak = 4,
    DateTime? lastActivity,
    double examScore = 0.9,
    LevelState a1 = LevelState.unlocked,
  }) => StudentProgress(
    uid: 'u1',
    courseId: 'en',
    currentLevelId: 'A1',
    xp: xp,
    streakCount: streak,
    lastActivityDate: lastActivity ?? DateTime(2026, 10, 7),
    levelStates: <String, LevelState>{'A1': a1},
    activityScores: <String, ActivityScore>{
      'A1M1EX': ActivityScore(
        kind: ActivityKind.moduleExam,
        bestScore: examScore,
        attempts: 2,
        lastAttemptAt: DateTime(2026, 10, 7, 18),
      ),
    },
    reviewCards: <String, ReviewCard>{
      'A1M1|name': ReviewCard(
        moduleId: 'A1M1',
        term: 'name',
        translation: 'el nombre',
        intervalStep: 3,
        dueDate: DateTime(2026, 10, 20),
        lapses: 1,
      ),
    },
    placement: PlacementResult(
      estimatedLevelId: 'B1',
      masteredLevelIds: const <String>['A1'],
      takenAt: DateTime(2026, 10, 1),
    ),
  );

  void makeService({StudentProgress? stored}) {
    store = FakeProgressStore(initial: stored);
    service = JsonBackupService(store, clock: fixedClock(exportDay));
  }

  setUp(makeService);

  group('exportar', () {
    test('sin progreso guardado no hay respaldo que ofrecer', () async {
      // Un archivo de quien no ha estudiado nada es una falsa red de seguridad.
      expect(await service.export(uid: 'u1', courseId: 'en'), isNull);
    });

    test('el sobre lleva versión, app, idioma y fecha', () async {
      makeService(stored: progressWith());

      final BackupDocument doc = (await service.export(
        uid: 'u1',
        courseId: 'en',
      ))!;

      expect(doc.backupVersion, currentBackupVersion);
      expect(doc.appVersion, appVersion);
      expect(doc.courseId, 'en');
      expect(doc.exportedAt, exportDay);
    });

    test(
      'el JSON es legible y no incluye el identificador del estudiante',
      () async {
        makeService(stored: progressWith());
        final BackupDocument doc = (await service.export(
          uid: 'u1',
          courseId: 'en',
        ))!;

        final String json = service.serialize(doc);

        expect(json, contains('\n'), reason: 'va con sangría');
        // Un respaldo es del estudiante que lo importa, no del que lo exportó:
        // guardar el uid invitaría a comprobarlo, y quien rehiciera su cuenta no
        // podría recuperar su propio avance.
        expect(json, isNot(contains('u1')));
        expect(json, contains('"courseId": "en"'));
      },
    );
  });

  group('ida y vuelta', () {
    test('todo el progreso sobrevive al archivo', () async {
      makeService(stored: progressWith());
      final BackupDocument doc = (await service.export(
        uid: 'u1',
        courseId: 'en',
      ))!;

      final BackupParseResult parsed = service.parse(
        service.serialize(doc),
        uid: 'u1',
        expectedCourseId: 'en',
      );

      expect(parsed, isA<BackupValid>());
      final StudentProgress back = (parsed as BackupValid).document.progress;

      expect(back.xp, 150);
      expect(back.streakCount, 4);
      expect(back.lastActivityDate, DateTime(2026, 10, 7));
      expect(back.levelStates['A1'], LevelState.unlocked);
      expect(back.activityScores['A1M1EX']!.bestScore, 0.9);
      expect(back.activityScores['A1M1EX']!.attempts, 2);
      expect(back.activityScores['A1M1EX']!.kind, ActivityKind.moduleExam);
      expect(back.reviewCards['A1M1|name']!.intervalStep, 3);
      expect(back.reviewCards['A1M1|name']!.dueDate, DateTime(2026, 10, 20));
      expect(back.reviewCards['A1M1|name']!.lapses, 1);
      expect(back.placement!.estimatedLevelId, 'B1');
      expect(back.placement!.masteredLevelIds, <String>['A1']);
      expect(back.placement!.takenAt, DateTime(2026, 10, 1));
    });

    test(
      'el estudiante que importa es el que lo pide, no el del archivo',
      () async {
        makeService(stored: progressWith());
        final BackupDocument doc = (await service.export(
          uid: 'u1',
          courseId: 'en',
        ))!;

        final BackupValid parsed =
            service.parse(
                  service.serialize(doc),
                  uid: 'otro',
                  expectedCourseId: 'en',
                )
                as BackupValid;

        expect(parsed.document.progress.uid, 'otro');
      },
    );
  });

  group('rechazos, sin tocar el progreso', () {
    test('un archivo que no es JSON se rechaza con motivo', () {
      makeService(stored: progressWith());

      final BackupParseResult result = service.parse(
        'esto no es json {{{',
        uid: 'u1',
        expectedCourseId: 'en',
      );

      expect(result, isA<BackupMalformed>());
      expect((result as BackupMalformed).reason, isNotEmpty);
      expect(store.saves, isEmpty, reason: 'validar no escribe');
    });

    test('un JSON que no es un respaldo se rechaza', () {
      expect(
        service.parse('[1, 2, 3]', uid: 'u1', expectedCourseId: 'en'),
        isA<BackupMalformed>(),
      );
      expect(
        service.parse('"texto"', uid: 'u1', expectedCourseId: 'en'),
        isA<BackupMalformed>(),
      );
    });

    test('sin versión de formato se rechaza antes de mirar el contenido', () {
      final BackupParseResult result = service.parse(
        '{"courseId": "en", "progress": {}}',
        uid: 'u1',
        expectedCourseId: 'en',
      );

      expect(result, isA<BackupMalformed>());
    });

    test('una versión futura se rechaza en lugar de intentarlo', () {
      // Interpretar un formato desconocido con reglas viejas es la forma de
      // corromper el progreso creyendo que se recupera.
      final BackupParseResult result = service.parse(
        '{"backupVersion": 99, "courseId": "en", "progress": {}}',
        uid: 'u1',
        expectedCourseId: 'en',
      );

      expect(result, isA<BackupUnsupportedVersion>());
      final BackupUnsupportedVersion bad = result as BackupUnsupportedVersion;
      expect(bad.found, 99);
      expect(bad.supported, currentBackupVersion);
    });

    test('la versión se comprueba antes que el idioma', () {
      // Si el sobre no se entiende, no se puede confiar en nada de dentro, ni
      // siquiera en el nombre del curso.
      final BackupParseResult result = service.parse(
        '{"backupVersion": 99, "courseId": "fr", "progress": {}}',
        uid: 'u1',
        expectedCourseId: 'en',
      );

      expect(result, isA<BackupUnsupportedVersion>());
    });

    test('un respaldo de otro idioma se rechaza con los dos nombres', () async {
      makeService(stored: progressWith());

      final BackupParseResult result = service.parse(
        '{"backupVersion": 1, "courseId": "fr", "progress": {"xp": 9999}}',
        uid: 'u1',
        expectedCourseId: 'en',
      );

      expect(result, isA<BackupWrongCourse>());
      final BackupWrongCourse wrong = result as BackupWrongCourse;
      expect(wrong.found, 'fr');
      expect(wrong.expected, 'en');
      // No se mezcló vocabulario francés en el progreso de inglés.
      expect(store.current('u1', 'en')!.xp, 150);
    });

    test('una versión vieja del sobre SÍ se acepta', () {
      // Rechazar hacia atrás dejaría inservibles los respaldos ya hechos.
      final BackupParseResult result = service.parse(
        '{"backupVersion": 0, "courseId": "en", "progress": {"xp": 10}}',
        uid: 'u1',
        expectedCourseId: 'en',
      );

      expect(result, isA<BackupValid>());
    });
  });

  group('importar fusiona, nunca reemplaza', () {
    test('un respaldo viejo NO pierde el progreso posterior', () async {
      // El caso clave. El archivo es de cuando llevaba 150 XP; desde entonces
      // la persona llegó a 400 y aprobó el examen con mejor nota.
      final BackupDocument old = BackupDocument(
        courseId: 'en',
        exportedAt: DateTime(2026, 8, 1),
        appVersion: appVersion,
        progress: progressWith(xp: 150, examScore: 0.8, streak: 4),
      );

      makeService(
        stored: progressWith(
          xp: 400,
          examScore: 0.95,
          streak: 11,
          lastActivity: DateTime(2026, 10, 8),
          a1: LevelState.passed,
        ),
      );

      final StudentProgress merged = await service.import(old, uid: 'u1');

      expect(merged.xp, 400, reason: 'el XP no retrocede');
      expect(merged.activityScores['A1M1EX']!.bestScore, 0.95);
      expect(merged.streakCount, 11);
      expect(merged.levelStates['A1'], LevelState.passed);
      // Y lo fusionado queda guardado.
      expect(store.current('u1', 'en')!.xp, 400);
    });

    test('recupera lo que solo estaba en el respaldo', () async {
      // La otra mitad de la fusión: lo del archivo que falta en local entra.
      final BackupDocument doc = BackupDocument(
        courseId: 'en',
        exportedAt: DateTime(2026, 8, 1),
        appVersion: appVersion,
        progress: progressWith(),
      );

      makeService(
        stored: const StudentProgress(
          uid: 'u1',
          courseId: 'en',
          currentLevelId: 'A1',
          xp: 20,
          levelStates: <String, LevelState>{'A1': LevelState.unlocked},
        ),
      );

      final StudentProgress merged = await service.import(doc, uid: 'u1');

      expect(merged.xp, 150);
      expect(merged.activityScores['A1M1EX'], isNotNull);
      expect(merged.reviewCards['A1M1|name']!.intervalStep, 3);
      expect(merged.placement!.estimatedLevelId, 'B1');
    });

    test('sin nada local el respaldo entra tal cual', () async {
      final BackupDocument doc = BackupDocument(
        courseId: 'en',
        exportedAt: exportDay,
        appVersion: appVersion,
        progress: progressWith(),
      );

      final StudentProgress merged = await service.import(doc, uid: 'u1');

      expect(merged.xp, 150);
      expect(store.current('u1', 'en'), isNotNull);
    });

    test('importar dos veces el mismo respaldo no cambia nada', () async {
      // La fusión es idempotente, así que reimportar por error es inofensivo.
      makeService(stored: progressWith(xp: 400));
      final BackupDocument doc = BackupDocument(
        courseId: 'en',
        exportedAt: exportDay,
        appVersion: appVersion,
        progress: progressWith(),
      );

      final StudentProgress once = await service.import(doc, uid: 'u1');
      final StudentProgress twice = await service.import(doc, uid: 'u1');

      expect(twice.xp, once.xp);
      expect(twice.streakCount, once.streakCount);
      expect(
        twice.activityScores['A1M1EX']!.bestScore,
        once.activityScores['A1M1EX']!.bestScore,
      );
    });

    test('ningún campo retrocede al importar algo peor en todo', () async {
      // Monotonía campo por campo: el respaldo es peor en cada dimensión a la
      // vez, así que cualquier reemplazo accidental en cualquier campo sale
      // aquí, no solo en el XP.
      makeService(
        stored: progressWith(
          xp: 400,
          streak: 11,
          lastActivity: DateTime(2026, 10, 8),
          examScore: 0.95,
          a1: LevelState.passed,
        ),
      );
      final StudentProgress local = store.current('u1', 'en')!;

      final StudentProgress merged = await service.import(
        BackupDocument(
          courseId: 'en',
          exportedAt: DateTime(2026, 7, 1),
          appVersion: appVersion,
          progress: StudentProgress(
            uid: 'u1',
            courseId: 'en',
            currentLevelId: 'A1',
            xp: 5,
            streakCount: 1,
            lastActivityDate: DateTime(2026, 7, 1),
            levelStates: const <String, LevelState>{'A1': LevelState.unlocked},
            activityScores: <String, ActivityScore>{
              'A1M1EX': ActivityScore(
                kind: ActivityKind.moduleExam,
                bestScore: 0.1,
                lastAttemptAt: DateTime(2026, 7, 1),
              ),
            },
            reviewCards: <String, ReviewCard>{
              'A1M1|name': ReviewCard(
                moduleId: 'A1M1',
                term: 'name',
                translation: 'el nombre',
                intervalStep: 0,
                dueDate: DateTime(2026, 7, 2),
              ),
            },
          ),
        ),
        uid: 'u1',
      );

      expect(merged.xp, greaterThanOrEqualTo(local.xp));
      expect(merged.streakCount, local.streakCount);
      expect(merged.lastActivityDate, local.lastActivityDate);
      expect(
        merged.levelStates['A1']!.rank,
        greaterThanOrEqualTo(local.levelStates['A1']!.rank),
      );
      expect(
        merged.activityScores['A1M1EX']!.bestScore,
        greaterThanOrEqualTo(local.activityScores['A1M1EX']!.bestScore),
      );
      expect(
        merged.reviewCards['A1M1|name']!.intervalStep,
        greaterThanOrEqualTo(local.reviewCards['A1M1|name']!.intervalStep),
      );
      // La única excepción buscada: la fecha de repaso se adelanta a propósito,
      // porque ante la duda conviene repasar antes.
      expect(merged.reviewCards['A1M1|name']!.dueDate, DateTime(2026, 7, 2));
      expect(merged.placement!.estimatedLevelId, 'B1');
    });
  });

  group('borrar', () {
    test('borra el progreso del curso', () async {
      makeService(stored: progressWith());
      expect(store.current('u1', 'en'), isNotNull);

      await service.wipe(uid: 'u1', courseId: 'en');

      expect(store.current('u1', 'en'), isNull);
    });

    test('borrar un curso no toca otro', () async {
      makeService(stored: progressWith());

      await service.wipe(uid: 'u1', courseId: 'fr');

      expect(store.current('u1', 'en'), isNotNull);
    });
  });
}
