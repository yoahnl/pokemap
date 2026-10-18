import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/workspace/project_creation_kit.dart';
import 'package:map_core/map_core.dart';

final class SyntheticProjectTemplate {
  SyntheticProjectTemplate(
      {this.id = 'alpha',
      this.tileSize = 32,
      this.width = 32,
      this.height = 26});
  final String id;
  final int tileSize, width, height;
  late final request = ProjectCreationRequest(
      name: 'Synthetic $id',
      folderName: 'fixture',
      parentPath: '/fixture',
      template: ProjectCreationTemplate.playable,
      tileSize: tileSize,
      mapWidth: width,
      mapHeight: height);
  late final kit = buildProjectCreationKit(request);
  late final Map<String, List<int>> files = _files();
  late final preview = buildProjectCreationPreviewPng(request)!;
  late final archive = _archive();
  late final descriptor = <String, dynamic>{
    'id': id,
    'label': 'Template $id',
    'description': 'Synthetic editable project.',
    'revision': 'synthetic-$id-1',
    'projectPaths': [
      'project.json',
      'maps/',
      'dialogues/',
      'assets/',
      'asset-provenance.json'
    ],
    'archive': {
      'uri': 'https://example.test/$id/project.zip',
      'sha256': sha256.convert(archive).toString()
    },
    'preview': {
      'uri': 'https://example.test/$id/preview.png',
      'sha256': sha256.convert(preview).toString()
    },
    'geometry': {'tileSize': tileSize, 'mapWidth': width, 'mapHeight': height}
  };
  ProjectTemplateCatalog get catalog => ProjectTemplateCatalog.fromJson({
        'schemaVersion': 1,
        'templates': [descriptor]
      });

  Map<String, List<int>> _files() {
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(kit.files['maps/first-map.json']!))
            as Map<String, dynamic>);
    final manifest = kit.manifest.copyWith(maps: [
      ...kit.manifest.maps,
      const ProjectMapEntry(
          id: 'annex', name: 'Annex', relativePath: 'maps/annex.json')
    ], dialogues: [
      const ProjectDialogueEntry(
          id: 'intro',
          name: 'Synthetic introduction',
          relativePath: 'dialogues/intro.yarn')
    ]);
    return {
      ...kit.files,
      'project.json': utf8.encode(jsonEncode(manifest.toJson())),
      'maps/annex.json': utf8.encode(
          jsonEncode(map.copyWith(id: 'annex', name: 'Annex').toJson())),
      'dialogues/intro.yarn':
          utf8.encode('title: Intro\n---\nSynthetic template content.\n===\n'),
      'asset-provenance.json': utf8
          .encode(jsonEncode({'source': 'synthetic test fixture', 'id': id}))
    };
  }

  List<int> _archive() {
    final result = Archive();
    for (final file in files.entries) {
      result.addFile(ArchiveFile(
          'fixture-$id/${file.key}', file.value.length, file.value));
    }
    result.addFile(ArchiveFile(
        'fixture-$id/preview/overview.png', preview.length, preview));
    result.addFile(ArchiveFile.string(
        'fixture-$id/README.md', 'Synthetic fixture documentation.'));
    return ZipEncoder().encode(result);
  }
}
