/// Pantalla de inicio para una sesión ya iniciada.
///
/// Provisional: el mapa de niveles y el recorrido de lecciones son las Fases 5 y
/// 4. Esta existe para que el flujo completo de cuenta sea recorrible y
/// verificable ahora, con el aviso de sincronización y el cierre de sesión en su
/// sitio definitivo.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/content_pack.dart';
import '../core/course.dart';
import '../core/placement_result.dart';
import '../services/auth/auth_service.dart';
import '../ui/providers/auth_providers.dart';
import '../ui/providers/content_providers.dart';
import '../ui/providers/clock_providers.dart';
import '../ui/providers/progress_controller.dart';
import '../ui/screens/placement_screen.dart';
import '../ui/screens/progress_screen.dart';
import '../ui/screens/review_screen.dart';
import '../ui/screens/settings_screen.dart';
import '../ui/widgets/placement_offer_card.dart';
import '../ui/widgets/review_summary_card.dart';
import '../ui/widgets/sign_out_button.dart';
import '../ui/widgets/sync_banner.dart';
import 'course_flow.dart';
import 'l10n/app_localizations.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final StudentIdentity? identity = ref.watch(authStateProvider).value;
    final CourseCatalog catalog = ref.watch(courseCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: <Widget>[
          if (ref.watch(selectedCourseIdProvider) != null)
            IconButton(
              icon: const Icon(Icons.insights_outlined),
              tooltip: 'Tu progreso',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const ProgressScreen(),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const SettingsScreen(),
              ),
            ),
          ),
          const SignOutButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            const SyncBanner(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  if (identity != null)
                    Text(
                      identity.email,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 16),
                  // Solo tiene sentido con un idioma elegido: la cola de repaso
                  // es por curso.
                  if (ref.watch(selectedCourseIdProvider) != null) ...<Widget>[
                    // Primero la nivelación: a quien acaba de entrar le importa
                    // más saber por dónde empezar que repasar lo que todavía no
                    // ha estudiado. La tarjeta decide sola si aparecer, y a
                    // partir de la primera actividad deja de hacerlo (T143).
                    PlacementOfferCard(
                      onOpenPlacement: () => _openPlacement(context, ref),
                    ),
                    ReviewSummaryCard(
                      onOpenReview: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) =>
                              const ReviewScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    l10n.chooseCourse,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  for (final ContentPack pack in catalog.packs)
                    Card(
                      child: ListTile(
                        title: Text(pack.course.name),
                        subtitle: Text(
                          '${pack.course.levels.length} nivel(es) · '
                          '${pack.course.upcomingLevelIds.length} '
                          '${l10n.levelUpcoming.toLowerCase()}',
                        ),
                        // Elegir el idioma y entrar son la misma acción: un
                        // catálogo de un solo curso donde hay que tocar dos
                        // veces solo deja al estudiante preguntándose si el
                        // primer toque funcionó.
                        onTap: () => _openCourse(context, ref, pack.courseId),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Selecciona el idioma y abre su mapa de niveles.
  ///
  /// La selección se hace antes de navegar porque todo lo que la ruta necesita
  /// —progreso, cola de repaso, nivelación— se resuelve a partir del curso
  /// elegido. Navegar primero mostraría un indicador de carga que solo existe
  /// por el orden de dos líneas.
  void _openCourse(BuildContext context, WidgetRef ref, String courseId) {
    ref.read(selectedCourseIdProvider.notifier).select(courseId);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const CourseMapRoute(),
      ),
    );
  }

  /// Abre la nivelación y aplica su resultado al progreso.
  ///
  /// El resultado se aplica aquí y no dentro de la pantalla porque la pantalla
  /// no debería conocer el almacén: recibe el curso y devuelve un
  /// [PlacementResult], igual que la lección devuelve un `ScoreResult`.
  void _openPlacement(BuildContext context, WidgetRef ref) {
    final Course? course = ref.read(activeCourseProvider);
    if (course?.placementTest == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => PlacementScreen(
          course: course!,
          now: ref.read(clockProvider)(),
          onFinished: (PlacementResult result) => ref
              .read(studentProgressProvider.notifier)
              .applyPlacementResult(result),
        ),
      ),
    );
  }
}
