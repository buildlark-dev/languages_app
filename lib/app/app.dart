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
import '../ui/providers/speech_providers.dart';
import '../ui/widgets/update_overlay.dart';
import 'auth_gate.dart';
import 'speech_route_observer.dart';
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

class LanguagesApp extends ConsumerStatefulWidget {
  const LanguagesApp({super.key});

  @override
  ConsumerState<LanguagesApp> createState() => _LanguagesAppState();
}

class _LanguagesAppState extends ConsumerState<LanguagesApp> {
  /// Se crea **una vez**, no en cada construcción: un `NavigatorObserver` se
  /// registra en el navegador al montarse, y entregar uno nuevo en cada
  /// reconstrucción —el tema cambia, la app se reconstruye— lo dejaría
  /// enganchado dos veces o ninguna.
  late final SpeechRouteObserver _speechObserver = SpeechRouteObserver(
    () => ref.read(ttsServiceProvider).stop(),
  );

  @override
  Widget build(BuildContext context) => MaterialApp(
    navigatorObservers: <NavigatorObserver>[_speechObserver],
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
    // El aviso de versión nueva va en `builder` y no dentro de una pantalla:
    // así queda por encima de todas, incluidas las que se abren con
    // `Navigator.push`, y una publicación a mitad de lección se puede ofrecer
    // sin interrumpirla.
    builder: (BuildContext context, Widget? child) =>
        UpdateOverlay(child: child ?? const SizedBox.shrink()),
    home: const SyncLifecycle(child: AuthGate()),
  );
}
