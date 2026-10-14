/// Guarda que el paquete web lleve dentro todos los plugins del proyecto.
///
/// Esto no es un escenario inventado: la app desplegada escribía en consola
/// `MissingPluginException(No implementation found for method getAll on channel
/// plugins.flutter.io/shared_preferences)` y perdía el tema y la velocidad de
/// voz **en silencio**, porque un build incremental reutilizó un registro de
/// plugins generado antes de que la dependencia existiera. Las fechas lo
/// cuentan solo: registro a las 07:28, `pubspec.yaml` a las 12:58, build
/// desplegado a las 21:49.
///
/// La comprobación de verdad la hace `tool/build_web.ps1` justo después de
/// compilar, que es donde se puede parar la publicación. Esta prueba cubre la
/// otra mitad: que el proyecto resuelva una implementación web para cada plugin
/// que la necesita, y que ningún registro que haya en disco se quede corto.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Plugins que la app necesita **sí o sí** en web.
///
/// La lista es explícita a propósito: si mañana alguien añade un plugin y no lo
/// apunta aquí, esta prueba no lo protege, y es mejor que se note al leerla que
/// creer que hay una red que no hay.
const Set<String> _requiredWebPlugins = <String>{
  'shared_preferences_web',
  'audioplayers_web',
  'flutter_tts',
  'speech_to_text',
  'firebase_core_web',
  'firebase_auth_web',
  'cloud_firestore_web',
};

void main() {
  late List<String> declaredWebPlugins;

  setUpAll(() {
    final File manifest = File('.flutter-plugins-dependencies');
    expect(
      manifest.existsSync(),
      isTrue,
      reason: 'Lo genera `flutter pub get`; sin él no hay nada que comprobar',
    );

    final Map<String, Object?> parsed =
        jsonDecode(manifest.readAsStringSync()) as Map<String, Object?>;
    final Map<String, Object?> plugins =
        parsed['plugins']! as Map<String, Object?>;
    final List<Object?> web = (plugins['web'] ?? <Object?>[]) as List<Object?>;

    declaredWebPlugins = web
        .whereType<Map<String, Object?>>()
        .map((Map<String, Object?> plugin) => '${plugin['name']}')
        .toList(growable: false);
  });

  test('el proyecto resuelve una implementación web de cada plugin', () {
    for (final String plugin in _requiredWebPlugins) {
      expect(
        declaredWebPlugins,
        contains(plugin),
        reason:
            'Sin $plugin en web, la función que depende de él falla en el '
            'navegador con MissingPluginException y la app sigue como si nada',
      );
    }
  });

  test('ningún registro de plugins generado se queda corto', () {
    final Directory buildCache = Directory('.dart_tool/flutter_build');
    if (!buildCache.existsSync()) {
      // Clon limpio sin build web: no hay paquete que publicar, así que no hay
      // nada que pueda salir mal todavía.
      return;
    }

    final List<File> registrants = buildCache
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (File file) => file.path.endsWith('web_plugin_registrant.dart'),
        )
        .toList(growable: false);

    for (final File registrant in registrants) {
      final String source = registrant.readAsStringSync();
      for (final String plugin in declaredWebPlugins) {
        expect(
          source,
          contains('package:$plugin/'),
          reason:
              '${registrant.path} no registra $plugin. Es un registro '
              'obsoleto: borra .dart_tool/flutter_build y vuelve a compilar '
              '(tool/build_web.ps1 lo hace)',
        );
      }
    }
  });
}
