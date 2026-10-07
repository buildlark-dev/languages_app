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
import '../widgets/sync_banner.dart';
import '../widgets/upcoming_level_notice.dart';

class LevelMapScreen extends StatelessWidget {
  const LevelMapScreen({
    required this.course,
    required this.progress,
    required this.onOpenLevel,
    this.showSyncBanner = true,
    super.key,
  });

  final Course course;
  final StudentProgress progress;
  final ValueChanged<Level> onOpenLevel;

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
