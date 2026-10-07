/// La raíz de la interfaz.
///
/// Recibe el catálogo **ya construido** en lugar de importarlo. Esa es la
/// costura del Principio I: `lib/app/` y `lib/ui/` no saben que existe el inglés,
/// y la prueba de arquitectura lo verifica inspeccionando los `import`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/content_pack.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';

class LanguagesApp extends StatelessWidget {
  const LanguagesApp({
    required this.catalog,
    this.themeMode = ThemeMode.system,
    this.storageDegraded = false,
    super.key,
  });

  /// Los idiomas disponibles, inyectados desde `main.dart`.
  final CourseCatalog catalog;

  final ThemeMode themeMode;

  /// True si el almacenamiento local falló y el progreso no se guardará.
  ///
  /// Se propaga hasta aquí porque FR-043 prohíbe fallar en silencio: la
  /// interfaz tiene que poder decirlo.
  final bool storageDegraded;

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (BuildContext context) =>
        AppLocalizations.of(context).appTitle,
    theme: lightTheme,
    darkTheme: darkTheme,
    themeMode: themeMode,
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: _StartupScreen(
      catalog: catalog,
      storageDegraded: storageDegraded,
    ),
  );
}

/// Pantalla provisional de arranque.
///
/// Las pantallas reales son la Fase 7. Esta existe para que el cableado completo
/// —Firebase, almacén, catálogo, tema, localización— se pueda comprobar de
/// principio a fin antes de que exista una sola pantalla de estudio.
class _StartupScreen extends StatelessWidget {
  const _StartupScreen({required this.catalog, required this.storageDegraded});

  final CourseCatalog catalog;
  final bool storageDegraded;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Text(l10n.appTagline, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            if (storageDegraded)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.storageDegradedTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.storageDegradedBody),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
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
                    '${pack.course.levels.length} nivel(es) con contenido · '
                    '${pack.course.upcomingLevelIds.length} ${l10n.levelUpcoming.toLowerCase()}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
