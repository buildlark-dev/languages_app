/// La raíz de la interfaz.
///
/// Todo lo concreto —catálogo, autenticación, sincronización— entra por
/// proveedores que `lib/main.dart` sobrescribe. Esa es la costura del Principio I:
/// `lib/app/` y `lib/ui/` no importan `lib/content/` en ningún punto, y la prueba
/// de arquitectura lo verifica inspeccionando los `import`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/settings/settings_store.dart';
import 'auth_gate.dart';
import 'sync_lifecycle.dart';
import 'l10n/app_localizations.dart';
import 'theme.dart';

/// Preferencias del dispositivo. **Se sobrescribe en `main.dart`.**
///
/// Lanza como los otros ocho proveedores de servicio, y eso es una corrección:
/// antes caía a `InMemorySettingsStore()` en silencio. Como el valor por
/// defecto era razonable, nadie notó durante cuatro revisiones que `main.dart`
/// no lo sobrescribía, y el tema y la velocidad de voz se reiniciaban en cada
/// arranque. Un olvido de cableado debe fallar de inmediato, no funcionar casi
/// bien.
final Provider<SettingsStore> settingsStoreProvider = Provider<SettingsStore>(
  (Ref ref) => throw UnimplementedError(
    'settingsStoreProvider debe sobrescribirse en main.dart',
  ),
);

/// Modo de tema vigente.
final Provider<ThemeMode> themeModeProvider = Provider<ThemeMode>(
  (Ref ref) => ref.watch(settingsStoreProvider).themeMode,
);

class LanguagesApp extends ConsumerWidget {
  const LanguagesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    onGenerateTitle: (BuildContext context) =>
        AppLocalizations.of(context).appTitle,
    theme: lightTheme,
    darkTheme: darkTheme,
    themeMode: ref.watch(themeModeProvider),
    localizationsDelegates: const <LocalizationsDelegate<Object>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: const SyncLifecycle(child: AuthGate()),
  );
}
