import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/features/editor/application/tiled_map_import_service.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

void main() {
  test('inspects then atomically imports a generic external TMX bundle',
      () async {
    final root = await Directory.systemTemp.createTemp('editor-tmx-import-');
    addTearDown(() => root.delete(recursive: true));
    final projectRoot = Directory('${root.path}/project')..createSync();
    final sourceRoot = Directory('${root.path}/source')..createSync();
    await File('${projectRoot.path}/project.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(
        const ProjectManifest(
          name: 'TMX editor fixture',
          version: ProjectVersion.v6,
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ).toJson(),
      )}\n',
    );
    await File('${sourceRoot.path}/road.png').writeAsBytes(_pngBytes);
    await File('${sourceRoot.path}/road.tsx').writeAsString(_tsx);
    final tmxPath = '${sourceRoot.path}/route-one.tmx';
    await File(tmxPath).writeAsString(_tmx);

    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    addTearDown(mutations.closeAll);
    addTearDown(queries.closeAll);
    final service = TiledMapImportService(
      mutations: mutations,
      queries: queries,
    );

    final inspection = await service.inspect(
      projectRootPath: projectRoot.path,
      tmxPath: tmxPath,
    );

    expect(inspection.source.mapId, startsWith('route-one-'));
    expect(inspection.source.width, 2);
    expect(inspection.source.height, 1);
    expect(inspection.source.tileLayerCount, 1);
    expect(inspection.source.objectCount, 1);
    expect(inspection.source.tilesets, hasLength(1));
    expect(inspection.preview['operation'], 'map.tiled.import');
    expect(inspection.preview['tilesetCount'], 1);

    final imported = await service.apply(inspection);

    expect(imported.map.id, inspection.source.mapId);
    expect(imported.manifest.maps.single.id, inspection.source.mapId);
    expect(imported.manifest.tilesets, hasLength(1));
    expect(imported.receiptId, isNotEmpty);
    final canonical = await queries.open(projectRoot.path);
    expect(canonical.mapById(inspection.source.mapId), isNotNull);
  });

  test('inspection fails before planning when one declared TSX is missing',
      () async {
    final root = await Directory.systemTemp.createTemp('editor-tmx-missing-');
    addTearDown(() => root.delete(recursive: true));
    final projectRoot = Directory('${root.path}/project')..createSync();
    await File('${projectRoot.path}/project.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(
        const ProjectManifest(
          name: 'Missing TSX fixture',
          version: ProjectVersion.v6,
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ).toJson(),
      )}\n',
    );
    final tmxPath = '${root.path}/missing.tmx';
    await File(tmxPath).writeAsString(_tmx);
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    addTearDown(mutations.closeAll);
    addTearDown(queries.closeAll);

    await expectLater(
      () => TiledMapImportService(
        mutations: mutations,
        queries: queries,
      ).inspect(projectRootPath: projectRoot.path, tmxPath: tmxPath),
      throwsA(
        isA<TiledMapImportServiceException>().having(
          (error) => error.code,
          'code',
          'map.tiled.tsx_missing',
        ),
      ),
    );
  });
}

final List<int> _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+'
  'A8AAQUBAScY42YAAAAASUVORK5CYII=',
);

const _tsx = '''
<tileset name="Road" tilewidth="1" tileheight="1" tilecount="1" columns="1">
  <image source="road.png" width="1" height="1"/>
</tileset>
''';

const _tmx = '''
<map version="1.10" tiledversion="1.11.2" orientation="orthogonal"
  renderorder="right-down" width="2" height="1" tilewidth="1" tileheight="1"
  infinite="0" nextlayerid="3" nextobjectid="2">
  <tileset firstgid="1" source="road.tsx"/>
  <layer id="1" name="Ground" width="2" height="1">
    <data encoding="csv">1,0</data>
  </layer>
  <objectgroup id="2" name="Objects">
    <object id="1" name="Marker" x="1" y="0" point="1"/>
  </objectgroup>
</map>
''';
