/// Mapa de niveles de un curso.
///
/// Muestra los niveles con contenido y, debajo, los anunciados. Los anunciados
/// aparecen en lugar de ocultarse porque «el camino sigue» es información distinta
/// de «esto es todo lo que hay».
library;

import 'package:flutter/material.dart';

import '../../core/course.dart';
import '../../core/level.dart';
import '../../core/student_progress.dart';
import '../../engine/progression.dart';
import '../widgets/level_card.dart';
import '../widgets/mastered_review_notice.dart';
import '../widgets/sync_banner.dart';
import '../widgets/upcoming_level_notice.dart';

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({
    required this.course,
    required this.progress,
    required this.onOpenLevel,
    this.onReviewMastered,
    this.showSyncBanner = true,
    super.key,
  });

  final Course course;
  final StudentProgress progress;
  final ValueChanged<Level> onOpenLevel;

  /// Qué hacer cuando ya no queda contenido nuevo (FR-038).
  ///
  /// Si es nulo no se ofrece el repaso, que es lo correcto en pruebas de widget
  /// centradas en las puertas de progresión.
  final VoidCallback? onReviewMastered;

  /// False en pruebas de widget que no montan los proveedores de sincronización.
  final bool showSyncBanner;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(course.name)),
    body: SafeArea(
      child: Column(
        children: <Widget>[
          if (showSyncBanner) const SyncBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                // Va arriba a propósito: es la única acción disponible, y
                // ponerla tras cuatro insignias y tres avisos de «en
                // preparación» es esconderla.
                if (onReviewMastered != null &&
                    !hasNewContent(course: course, progress: progress))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: MasteredReviewNotice(
                      upcomingLevelId: course.upcomingLevelIds.isEmpty
                          ? null
                          : course.upcomingLevelIds.first,
                      onReview: onReviewMastered!,
                    ),
                  ),
                for (final Level level in course.levels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LevelCard(
                      level: level,
                      state: progress.stateOf(level.id),
                      completion: levelCompletion(
                        progress: progress,
                        level: level,
                      ),
                      passedModules: passedModuleCount(
                        progress: progress,
                        level: level,
                      ),
                      // Un nivel bloqueado no abre nada: sin onTap, no hay ruta.
                      onTap: progress.stateOf(level.id).isOpen
                          ? () => onOpenLevel(level)
                          : null,
                    ),
                  ),
                for (final String upcoming in course.upcomingLevelIds)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: UpcomingLevelNotice(levelId: upcoming),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
