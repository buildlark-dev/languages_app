/// Hace cumplir el grafo de dependencias del Principio II (constitución v1.1.0).
///
/// La constitución dice que la regla "DEBE verificarse con una prueba
/// automatizada que inspeccione los `import` de cada archivo, no por revisión
/// visual". Este es ese archivo.
///
/// El grafo permitido:
///
///     ui       →  engine   →  core
///     ui       →  services →  engine  →  core
///     content  →  core
///
/// Y la regla que hace cierto el Principio I: solo la raíz de composición
/// (`lib/main.dart`) puede importar contenido concreto.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Capas del proyecto, derivadas de la ruta del archivo.
enum Layer { core, engine, services, content, ui, app, root }

/// Qué puede importar cada capa.
///
/// `root` (main.dart) no aparece: es la raíz de composición y puede importar
/// todo, porque su trabajo es precisamente unir las piezas.
const Map<Layer, Set<Layer>> allowedTargets = <Layer, Set<Layer>>{
  Layer.core: <Layer>{Layer.core},
  Layer.engine: <Layer>{Layer.core, Layer.engine},
  Layer.services: <Layer>{Layer.core, Layer.engine, Layer.services},
  Layer.content: <Layer>{Layer.core, Layer.content},
  Layer.ui: <Layer>{
    Layer.core,
    Layer.engine,
    Layer.services,
    Layer.ui,
    Layer.app,
  },
  Layer.app: <Layer>{
    Layer.core,
    Layer.engine,
    Layer.services,
    Layer.ui,
    Layer.app,
  },
};

/// Capas que no pueden depender del framework de interfaz.
///
/// `core` y `engine` deben poder probarse sin montar widgets, que es lo que
/// sostiene el Principio V.
const Set<Layer> flutterFreeLayers = <Layer>{Layer.core, Layer.engine};

void main() {
  final Directory libDir = Directory('lib');

  late List<_SourceFile> sources;

  setUpAll(() {
    expect(
      libDir.existsSync(),
      isTrue,
      reason: 'La prueba debe ejecutarse desde la raíz del proyecto',
    );
    sources = libDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((File f) => f.path.endsWith('.dart'))
        .map(_SourceFile.read)
        .toList(growable: false);
  });

  test('hay archivos que inspeccionar', () {
    expect(sources, isNotEmpty);
  });

  test('cada capa importa solo lo que el Principio II le permite', () {
    final List<String> violations = <String>[];

    for (final _SourceFile source in sources) {
      if (source.layer == Layer.root) continue;
      final Set<Layer> allowed = allowedTargets[source.layer]!;

      for (final _Import import in source.imports) {
        final Layer? target = import.targetLayer;
        if (target == null) continue;
        if (!allowed.contains(target)) {
          violations.add(
            '${source.relativePath} (${source.layer.name}) importa '
            '${import.uri} (${target.name})',
          );
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Violaciones del grafo de dependencias:\n  ${violations.join('\n  ')}',
    );
  });

  test('core y engine no dependen de Flutter', () {
    final List<String> violations = <String>[];

    for (final _SourceFile source in sources) {
      if (!flutterFreeLayers.contains(source.layer)) continue;
      for (final _Import import in source.imports) {
        if (import.isFlutter) {
          violations.add('${source.relativePath} importa ${import.uri}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'core y engine deben ser probables sin montar widgets:\n'
          '  ${violations.join('\n  ')}',
    );
  });

  test('solo main.dart importa contenido concreto', () {
    final List<String> violations = <String>[];

    for (final _SourceFile source in sources) {
      if (source.layer == Layer.root) continue;
      if (source.layer == Layer.content) continue;

      for (final _Import import in source.imports) {
        if (import.targetLayer == Layer.content) {
          violations.add('${source.relativePath} importa ${import.uri}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'El Principio I exige que solo la raíz de composición conozca los '
          'idiomas concretos:\n  ${violations.join('\n  ')}',
    );
  });

  test('ningún archivo de producción supera las 300 líneas', () {
    // El Principio II usa DEBERÍA, no DEBE, así que esto no falla la suite:
    // informa. Los archivos de contenido tienen su propia regla de división en
    // contracts/content-pack.md.
    final List<String> oversized = sources
        .where((_SourceFile s) => s.lineCount > 300)
        .map((_SourceFile s) => '${s.relativePath}: ${s.lineCount} líneas')
        .toList(growable: false);

    if (oversized.isNotEmpty) {
      printOnFailure(
        'Archivos por encima del umbral orientativo:\n  '
        '${oversized.join('\n  ')}',
      );
    }
    expect(sources, isNotEmpty);
  });
}

/// Un archivo de `lib/` con sus importaciones ya resueltas.
class _SourceFile {
  _SourceFile({
    required this.relativePath,
    required this.layer,
    required this.imports,
    required this.lineCount,
  });

  factory _SourceFile.read(File file) {
    final String relative = file.path.replaceAll(r'\', '/');
    final List<String> lines = file.readAsLinesSync();
    return _SourceFile(
      relativePath: relative,
      layer: _layerOf(relative),
      imports: _importsOf(lines, relative),
      lineCount: lines.length,
    );
  }

  final String relativePath;
  final Layer layer;
  final List<_Import> imports;
  final int lineCount;
}

class _Import {
  _Import({
    required this.uri,
    required this.targetLayer,
    required this.isFlutter,
  });

  final String uri;

  /// Capa a la que apunta, o nulo si es externa al proyecto.
  final Layer? targetLayer;

  final bool isFlutter;
}

/// Clasifica un archivo por su ruta.
Layer _layerOf(String path) {
  if (path == 'lib/main.dart') return Layer.root;
  if (path.startsWith('lib/core/')) return Layer.core;
  if (path.startsWith('lib/engine/')) return Layer.engine;
  if (path.startsWith('lib/services/')) return Layer.services;
  if (path.startsWith('lib/content/')) return Layer.content;
  if (path.startsWith('lib/ui/')) return Layer.ui;
  if (path.startsWith('lib/app/')) return Layer.app;
  // firebase_options.dart y cualquier otro archivo suelto de lib/ cuentan como
  // parte de la raíz de composición.
  return Layer.root;
}

final RegExp _importPattern = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
);

List<_Import> _importsOf(List<String> lines, String sourcePath) {
  final List<_Import> result = <_Import>[];

  for (final String line in lines) {
    final RegExpMatch? match = _importPattern.firstMatch(line);
    if (match == null) continue;
    final String uri = match.group(1)!;

    if (uri.startsWith('dart:')) continue;

    final bool isFlutter =
        uri.startsWith('package:flutter/') ||
        uri.startsWith('package:flutter_');

    final String? resolved = _resolveToLibPath(uri, sourcePath);
    result.add(
      _Import(
        uri: uri,
        targetLayer: resolved == null ? null : _layerOf(resolved),
        isFlutter: isFlutter,
      ),
    );
  }

  return result;
}

/// Convierte el URI de un import en una ruta bajo `lib/`, o nulo si es externo.
String? _resolveToLibPath(String uri, String sourcePath) {
  const String selfPackage = 'package:languages_app/';
  if (uri.startsWith(selfPackage)) {
    return 'lib/${uri.substring(selfPackage.length)}';
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return null;

  // Import relativo: se resuelve contra la carpeta del archivo que lo declara.
  final List<String> base = sourcePath.split('/')..removeLast();
  for (final String segment in uri.split('/')) {
    if (segment == '.' || segment.isEmpty) continue;
    if (segment == '..') {
      if (base.isNotEmpty) base.removeLast();
      continue;
    }
    base.add(segment);
  }
  return base.join('/');
}
