import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

Future<Directory> createProject(
  Directory parent,
  String name, {
  bool withUnreadMap = false,
}) async {
  final directory = await Directory(p.join(parent.path, name)).create();
  await File(p.join(directory.path, 'project.json')).writeAsString(
    jsonEncode(
      ProjectManifest(
        name: name,
        maps: [
          if (withUnreadMap)
            const ProjectMapEntry(
              id: 'unread',
              name: 'Carte non chargée',
              relativePath: 'maps/not-loaded.json',
            ),
        ],
        tilesets: [],
      ).toJson(),
    ),
  );
  return directory;
}

Future<String> projectFingerprint(Directory directory) async {
  final files = await directory
      .list(recursive: true)
      .where((e) => e is File)
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  return computeNarrativeProjectFingerprint([
    for (final file in files)
      NarrativeProjectFingerprintEntry(
        relativePath: p.relative(file.path, from: directory.path),
        bytes: await File(file.path).readAsBytes(),
      ),
  ]);
}

Future<List<String>> projectInventory(Directory directory) async {
  final entries = await directory
      .list(recursive: true, followLinks: false)
      .map((entry) => p.relative(entry.path, from: directory.path))
      .toList();
  return entries..sort();
}

final class CountingProjectReader implements ProjectFileReader {
  final readPaths = <String>[];
  final delegate = const LocalProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    readPaths.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}
