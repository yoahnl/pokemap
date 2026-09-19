import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../tool/create_example_project.dart';
import '../../tool/example_project_assets.dart';
import '../../tool/stress_example_project.dart';

export '../../tool/stress_example_project.dart'
    show stressAtlasId, stressIncidentId;

class ResourceStressFixture {
  ResourceStressFixture._(
    this.directory,
    this.session,
    this.manifest,
    this.maps,
    this.atlasCount,
    this.errorCount,
  );

  final Directory directory;
  final ProjectSession session;
  final ProjectManifest manifest;
  final Map<String, MapData> maps;
  final int atlasCount;
  final int errorCount;

  MapData get lateMap => maps['stress-a']!;
  MapData get otherMap => maps['stress-b']!;
  MapData get incidentMap => maps['stress-errors']!;
  String get lateAtlasId => stressAtlasId(atlasCount - 1);
  int get decodedAtlasBytes => 160 * 64 * 4;

  static Future<ResourceStressFixture> create({
    int atlasCount = 132,
    int errorCount = 200,
  }) async {
    final directory = await Directory.systemTemp.createTemp('studio_stress_');
    try {
      await writeExampleProject(
        directory,
        stress: true,
        stressAtlasCount: atlasCount,
        stressErrorCount: errorCount,
      );
      final root = await directory.resolveSymbolicLinks();
      final manifest = ProjectManifest.fromJson(
        jsonDecode(await File(p.join(root, 'project.json')).readAsString())
            as Map<String, dynamic>,
      );
      final maps = <String, MapData>{};
      for (final entry in manifest.maps) {
        maps[entry.id] = MapData.fromJson(
          jsonDecode(
                await File(p.join(root, entry.relativePath)).readAsString(),
              )
              as Map<String, dynamic>,
        );
      }
      return ResourceStressFixture._(
        directory,
        ProjectSession(
          sessionId: root,
          name: manifest.name,
          directoryPath: root,
        ),
        manifest,
        maps,
        atlasCount,
        errorCount,
      );
    } catch (_) {
      await directory.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> makeMissingAvailable([int index = 0]) async {
    if (index < 0 || index >= errorCount || index % 3 != 0) {
      throw ArgumentError.value(index, 'index', 'Incident de fichier absent');
    }
    await File(
      p.join(directory.path, 'assets', 'absent-$index.png'),
    ).writeAsBytes(exampleAtlasPng());
  }

  Future<void> dispose() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
