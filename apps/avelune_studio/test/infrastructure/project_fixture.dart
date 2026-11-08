import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

Future<Directory> createProject(
  Directory parent,
  String name, {
  bool withUnreadMap = false,
  String? manifestName,
}) async {
  final directory = await Directory(p.join(parent.path, name)).create();
  await File(p.join(directory.path, 'project.json')).writeAsString(
    jsonEncode(
      ProjectManifest(
        name: manifestName ?? name,
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

bool _isAuthoringState(Directory directory, String path) =>
    p.split(p.relative(path, from: directory.path)).first == '.pokemap';

Future<String> projectFingerprint(
  Directory directory, {
  bool includeAuthoringState = true,
}) async {
  final files = await directory
      .list(recursive: true)
      .where(
        (e) =>
            e is File &&
            (includeAuthoringState || !_isAuthoringState(directory, e.path)),
      )
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

Future<List<String>> projectInventory(
  Directory directory, {
  bool includeAuthoringState = true,
}) async {
  final entries = await directory
      .list(recursive: true, followLinks: false)
      .where(
        (entry) =>
            includeAuthoringState || !_isAuthoringState(directory, entry.path),
      )
      .map((entry) => p.relative(entry.path, from: directory.path))
      .toList();
  return entries..sort();
}

final class CountingProjectReader
    implements ProjectFileReader, ProjectResourceProbeReader {
  final readPaths = <String>[];
  final delegate = const LocalProjectFileReader();

  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => delegate.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );

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
