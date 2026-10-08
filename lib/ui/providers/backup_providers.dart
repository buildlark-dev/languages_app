/// Estado de las tres acciones de respaldo.
///
/// La transferencia del archivo se hace por **portapapeles**, no por selector de
/// archivos. Es una decisión con un porqué y con un límite conocido:
///
/// * El porqué: no añade ninguna dependencia nativa, y funciona igual en Android
///   y en web, que son los dos destinos de esta entrega. Un selector de archivos
///   exige permisos distintos en cada plataforma y un camino de pruebas que
///   todavía no existe.
/// * El límite: el respaldo vive donde la persona lo pegue. El JSON se emite con
///   sangría precisamente para que sea legible y se pueda guardar en cualquier
///   sitio con confianza.
library;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/backup/backup_document.dart';
import '../../services/backup/backup_service.dart';
import 'progress_controller.dart';
import 'review_providers.dart';
import 'scope_providers.dart';

/// El servicio concreto. **Se sobrescribe en `main.dart`.**
final Provider<BackupService> backupServiceProvider = Provider<BackupService>(
  (Ref ref) => throw UnimplementedError(
    'backupServiceProvider debe sobrescribirse en main.dart',
  ),
);

/// Qué acabó de pasar, para decirlo en pantalla.
enum BackupAction {
  /// El respaldo está en el portapapeles.
  exported,

  /// Un respaldo se fusionó con el progreso.
  imported,

  /// El progreso local se borró.
  wiped,

  /// No había progreso que respaldar.
  nothingToExport,
}

class BackupState {
  const BackupState({this.busy = false, this.lastAction, this.parseFailure});

  final bool busy;

  /// La última acción completada, o nulo si aún no hubo ninguna.
  final BackupAction? lastAction;

  /// Por qué se rechazó el último archivo, o nulo si no se rechazó ninguno.
  ///
  /// Se guarda el resultado completo y no un texto: el mensaje lo elige la
  /// pantalla con un `switch` exhaustivo, así que un caso nuevo no puede
  /// quedarse sin explicación.
  final BackupParseResult? parseFailure;
}

/// Ejecuta exportar, importar y borrar.
class BackupController extends Notifier<BackupState> {
  @override
  BackupState build() => const BackupState();

  /// Deja el respaldo en el portapapeles.
  Future<void> exportToClipboard() async {
    final StudentScope? scope = await resolveStudentScope(ref);
    if (scope == null) return;

    state = const BackupState(busy: true);
    final BackupService service = ref.read(backupServiceProvider);
    final BackupDocument? document = await service.export(
      uid: scope.uid,
      courseId: scope.courseId,
    );

    if (document == null) {
      state = const BackupState(lastAction: BackupAction.nothingToExport);
      return;
    }

    await Clipboard.setData(ClipboardData(text: service.serialize(document)));
    state = const BackupState(lastAction: BackupAction.exported);
  }

  /// Valida [raw] y, si es bueno, lo fusiona con el progreso.
  ///
  /// Devuelve true solo si se importó. Un archivo rechazado deja el motivo en
  /// [BackupState.parseFailure] y **no toca nada**.
  Future<bool> importFromText(String raw) async {
    final StudentScope? scope = await resolveStudentScope(ref);
    if (scope == null) return false;

    state = const BackupState(busy: true);
    final BackupService service = ref.read(backupServiceProvider);
    final BackupParseResult parsed = service.parse(
      raw,
      uid: scope.uid,
      expectedCourseId: scope.courseId,
    );

    switch (parsed) {
      case BackupValid(:final BackupDocument document):
        final StudentProgressController progress = ref.read(
          studentProgressProvider.notifier,
        );
        progress.adopt(await service.import(document, uid: scope.uid));
        // La cola de repaso llegó dentro del progreso fusionado, así que su
        // conteo en pantalla está desfasado hasta que se relea.
        ref.invalidate(reviewSummaryProvider);
        state = const BackupState(lastAction: BackupAction.imported);
        return true;

      case BackupUnsupportedVersion():
      case BackupMalformed():
      case BackupWrongCourse():
        state = BackupState(parseFailure: parsed);
        return false;
    }
  }

  /// Borra el progreso local del curso abierto.
  ///
  /// Quien llama debe haber confirmado antes (FR-046). Aquí no se vuelve a
  /// preguntar: una segunda confirmación dentro del servicio solo enseñaría a
  /// pulsar «sí» dos veces sin leer.
  Future<void> wipe() async {
    final StudentScope? scope = await resolveStudentScope(ref);
    if (scope == null) return;

    state = const BackupState(busy: true);
    await ref
        .read(backupServiceProvider)
        .wipe(uid: scope.uid, courseId: scope.courseId);

    // Se reconstruye todo lo que leía del progreso borrado. Sin esto, la
    // pantalla seguiría mostrando el avance de un progreso que ya no existe.
    ref.invalidate(studentProgressProvider);
    ref.invalidate(reviewSummaryProvider);
    state = const BackupState(lastAction: BackupAction.wiped);
  }

  /// Olvida el último resultado, al cerrar el aviso.
  void dismiss() => state = const BackupState();
}

final NotifierProvider<BackupController, BackupState> backupControllerProvider =
    NotifierProvider<BackupController, BackupState>(BackupController.new);
