import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:path/path.dart' as p;

Future<Map<String, String>> sourceFingerprints(String root) async {
  final files = <String, String>{};
  final partitioned = await _usesPartitionedCatalog(
    File(p.join(root, 'project.json')),
  );
  final directories = [Directory(root)];
  while (directories.isNotEmpty) {
    final directory = directories.removeLast();
    await for (final entry in directory.list(followLinks: false)) {
      final relative = p.relative(entry.path, from: root).replaceAll('\\', '/');
      if (entry is File && relative != '.DS_Store') {
        files[relative] = await _fingerprintFile(entry, relative);
      }
      if (entry is! Directory ||
          const {'.pokemap', '.git', '.dart_tool'}.contains(relative)) {
        continue;
      }
      if (partitioned && relative == 'catalog') {
        for (final path in const [
          CatalogStorageStore.headStorageKey,
          'catalog/IDENTITY.json',
        ]) {
          final file = File(p.join(root, path));
          if (await FileSystemEntity.type(file.path, followLinks: false) ==
              FileSystemEntityType.file) {
            files[path] = await _fingerprintFile(file, path);
          }
        }
      } else {
        directories.add(entry);
      }
    }
  }
  return files;
}

Future<bool> _usesPartitionedCatalog(File project) async {
  if (await FileSystemEntity.type(project.path, followLinks: false) !=
          FileSystemEntityType.file ||
      await project.length() > 4096) {
    return false;
  }
  try {
    final descriptor = jsonDecode(await project.readAsString());
    return descriptor is Map &&
        const {
          'avelune.working-catalog',
          'avelune.portable-catalog',
        }.contains(descriptor['format']);
  } on FormatException {
    return false;
  }
}

Future<String> _fingerprintFile(File file, String path) async {
  final fingerprint = NarrativeProjectFingerprintBuilder()
    ..startEntry(relativePath: path, byteLength: await file.length());
  await for (final bytes in file.openRead()) {
    fingerprint.addBytes(bytes);
  }
  fingerprint.endEntry();
  return fingerprint.close();
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
