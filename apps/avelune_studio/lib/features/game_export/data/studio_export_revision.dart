import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

Future<Map<String, String>> sourceFingerprints(String root) async {
  final files = <String, String>{};
  await for (final entry in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entry is! File) continue;
    final relative = p.relative(entry.path, from: root).replaceAll('\\', '/');
    if (relative.startsWith('.pokemap/') ||
        relative.startsWith('.git/') ||
        relative.startsWith('.dart_tool/') ||
        relative == '.DS_Store') {
      continue;
    }
    files[relative] = computeAuthoringBytesFingerprint(
      await entry.readAsBytes(),
      logicalName: relative,
    );
  }
  return files;
}

bool sameSourceFiles(Map<String, String> left, Map<String, String> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);

String sourceRevisionOf(Map<String, String> files) {
  final entries = files.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return computeAuthoringBytesFingerprint(
    utf8.encode(
      entries.map((entry) => '${entry.key}:${entry.value}').join('\n'),
    ),
    logicalName: 'studio-export-source',
  );
}
