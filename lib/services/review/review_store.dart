/// Contrato de la cola de repetición espaciada.
///
/// La interfaz depende de esto y no de `services/db/review_dao.dart`. Son dos
/// razones distintas:
///
/// 1. Una prueba de widget no debería necesitar abrir una base SQLite para
///    comprobar que la pantalla dice «estás al día».
/// 2. El almacén local es un detalle. Hoy es Drift; el contrato no promete
///    SQLite en ninguna parte de su firma.
///
/// `uid` y `courseId` viajan en cada llamada, igual que en `ProgressDao` y
/// `SyncService`. Guardarlos en el constructor obligaría a reconstruir el
/// almacén en cada cambio de sesión o de idioma, y un almacén con identidad
/// caducada escribiría en el progreso de otra persona.
library;

import '../../core/review_card.dart';
import '../../core/vocabulary_item.dart';

abstract interface class ReviewStore {
  /// Siembra la cola con el vocabulario de un módulo (FR-028).
  ///
  /// **Debe ser idempotente.** Volver a entrar en un módulo ya empezado no puede
  /// reiniciar la memoria construida sobre sus palabras, así que una tarjeta que
  /// ya existe se deja intacta.
  Future<void> seedModule({
    required String uid,
    required String courseId,
    required String moduleId,
    required List<VocabularyItem> vocabulary,
    required DateTime today,
  });

  /// Las tarjetas que vencen en [today] o antes, de la más antigua a la más
  /// reciente.
  Future<List<ReviewCard>> dueCards({
    required String uid,
    required String courseId,
    required DateTime today,
  });

  /// Cuántas vencen en [today] o antes.
  ///
  /// Existe aparte de [dueCards] porque la pantalla principal solo necesita el
  /// número, y traer mil filas para medir la lista sería gratuito solo el primer
  /// mes de uso.
  Future<int> dueCount({
    required String uid,
    required String courseId,
    required DateTime today,
  });

  /// Guarda una tarjeta ya reprogramada.
  Future<void> save({
    required String uid,
    required String courseId,
    required ReviewCard card,
  });

  /// Cuántas tarjetas hay en total, vencidas o no.
  ///
  /// Sirve para distinguir dos estados que se ven igual con cero vencidas y no
  /// lo son: «estás al día» y «todavía no has empezado ningún módulo».
  Future<int> totalCount({required String uid, required String courseId});
}
