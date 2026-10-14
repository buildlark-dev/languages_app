/// Prints every text the app can speak, as JSON, for the audio generator.
///
/// It reads the content through `spokenTextsOf`, the same function the
/// integrity test uses, so the generator cannot drift from what the app will
/// ask for at runtime. That is the whole point of this file existing instead
/// of the list being hard-coded in the PowerShell script.
///
/// It writes a file instead of printing: PowerShell 5.1 decodes a native
/// command's stdout with the console code page, which turned "Bogotá" and an
/// em dash into mojibake and left two clips unfindable. A file written as
/// UTF-8 and read back as UTF-8 has no such step.
///
/// Run: dart run tool/list_spoken_texts.dart build/spoken_texts.json
library;

import 'dart:convert';
import 'dart:io';

import 'package:languages_app/content/catalog.dart';
import 'package:languages_app/core/content_pack.dart';
import 'package:languages_app/services/speech/clip_key.dart';
import 'package:languages_app/services/speech/spoken_texts.dart';

void main(List<String> args) {
  final String target = args.isEmpty ? 'build/spoken_texts.json' : args.first;
  const AppCourseCatalog catalog = AppCourseCatalog();
  final List<Map<String, String>> entries = <Map<String, String>>[];

  for (final ContentPack pack in catalog.packs) {
    for (final String text in spokenTextsOf(pack)) {
      final String key = clipKey(text);
      entries.add(<String, String>{
        'key': key,
        'text': text,
        'file': fileNameFor(key),
      });
    }
  }

  final File out = File(target);
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(const JsonEncoder().convert(entries));

  // ignore: avoid_print
  print('${entries.length} spoken texts written to $target');
}

/// A stable, readable file name for a clip.
///
/// Readable because `good-morning-3f2a1b7c.mp3` is debuggable and
/// `clip_0042.mp3` is not. Stable because the hash comes from the key, so
/// adding a word to the middle of a module does not rename ninety files and
/// produce a diff nobody can read.
String fileNameFor(String key) {
  final String slug = key
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  final String short = slug.length <= 32 ? slug : slug.substring(0, 32);
  return '${short.isEmpty ? 'clip' : short}-${_hash(key)}';
}

/// FNV-1a, 32 bits. Not cryptography: a short, stable discriminator so two
/// texts with the same slug cannot collide on one file.
String _hash(String value) {
  int hash = 0x811c9dc5;
  for (final int unit in utf8.encode(value)) {
    hash = (hash ^ unit) & 0xffffffff;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}
