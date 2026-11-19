import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

import '../../../map_distribution/test/support/spatial_package_fixture.dart';

Future<void> writeSpatialExportProject(Directory root) async {
  final files = spatialPayload();
  final project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!)));
  const dialogue = ProjectDialogueEntry(
      id: 'halte', name: 'La halte', relativePath: 'dialogues/halte.yarn');
  files['project/project.json'] =
      utf8.encode(jsonEncode(project.copyWith(dialogues: [dialogue]).toJson()));
  files['project/${dialogue.relativePath}'] =
      utf8.encode('title: Start\n---\nBienvenue à la halte.\n===\n');
  files['project/assets/provenance/hgss.json'] =
      utf8.encode(jsonEncode({'source': 'authoring-only'}));
  for (final entry in files.entries) {
    final file =
        File(p.join(root.path, entry.key.substring('project/'.length)));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(entry.value);
  }
}

GamePackageExportProfile spatialExportProfile() => GamePackageExportProfile(
    gameId: 'games.example.spatial',
    gameVersion: '0.1.0',
    title: 'La halte des falaises',
    authorName: 'Yoahn',
    defaultLocale: 'fr',
    supportedLocales: ['fr']);

ProjectManifest publishedSpatialProject(Archive archive) =>
    PortableCatalogPublication.decodeProjectSync(
        jsonDecode(
                utf8.decode(archive.findFile('project/project.json')!.content))
            as Map<String, dynamic>,
        readObject: (ref) => archive
            .findFile('project/${PortableCatalogPublication.objectPath(ref)}')!
            .content);

GamePackageManifest inspectSpatialPackageFile(File package) {
  final file = package.openSync();
  try {
    return const GamePackageInspector()
        .inspectSourceSync(_FileSource(file))
        .manifest;
  } finally {
    file.closeSync();
  }
}

final class _FileSource implements RandomAccessPackageSource {
  _FileSource(this.file);
  final RandomAccessFile file;
  @override
  int get length => file.lengthSync();
  @override
  Uint8List readAtSync(int offset, int length) {
    file.setPositionSync(offset);
    return file.readSync(length);
  }
}
