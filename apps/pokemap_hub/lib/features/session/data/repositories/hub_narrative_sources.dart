import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

Map<String, String> narrativeMapSourceHashes(
  ProjectManifest project,
  Map<String, GamePackageFileEntry> inventory,
) => {
  for (final map in project.maps)
    map.id:
        inventory['project/${map.relativePath}']?.sha256 ??
        (throw const FormatException(
          'Narrative map is missing from the inventory.',
        )),
};

Future<void> verifyNarrativeSources(
  Directory root,
  GamePackageManifest manifest,
  List<String> paths,
) => Isolate.run(() async {
  final entries = {
    for (final entry in manifest.content.files) entry.path: entry,
  };
  final canonicalRoot = await root.resolveSymbolicLinks();
  for (final path in paths) {
    final entry = entries[path];
    final file = File(p.join(root.path, path));
    if (entry == null ||
        !p.isWithin(canonicalRoot, await file.resolveSymbolicLinks()) ||
        await FileSystemEntity.type(file.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await file.length() != entry.size ||
        (await sha256.bind(file.openRead()).first).toString() != entry.sha256) {
      throw const FormatException(
        'Narrative source does not match the verified inventory.',
      );
    }
  }
});
