import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';

void main() {
  test(
    'editor pixel geometry plans, applies, projects and undoes atomically',
    () async {
      final root = await Directory.systemTemp.createTemp('geometry-');
      addTearDown(() => root.delete(recursive: true));
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 3, height: 3),
        layers: const [
          MapLayer.tile(
            id: 'decor',
            name: 'Decor',
            cells: [0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ],
        placedElements: [
          for (final id in ['a', 'b'])
            MapPlacedElement(
              id: id,
              elementId: 'prop',
              layerId: 'decor',
              pos: const GridPos(x: 1, y: 1),
              properties: const {
                'pokemapPlacementOrigin': 'authored',
                'preserved': 'yes',
              },
            ),
        ],
      );
      const manifest = ProjectManifest(
        name: 'Geometry',
        settings: ProjectSettings(tileWidth: 16, tileHeight: 32),
        maps: [
          ProjectMapEntry(
            id: 'map',
            name: 'Map',
            relativePath: 'maps/map.json',
          ),
        ],
        tilesets: [
          ProjectTilesetEntry(
            id: 'ts',
            name: 'TS',
            relativePath: 'assets/ts.png',
          ),
        ],
        elementCategories: [ProjectElementCategory(id: 'cat', name: 'Cat')],
        elements: [
          ProjectElementEntry(
            id: 'prop',
            name: 'Prop',
            tilesetId: 'ts',
            categoryId: 'cat',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
          ),
        ],
      );
      await Directory('${root.path}/maps').create();
      await File(
        '${root.path}/project.json',
      ).writeAsString(jsonEncode(manifest.toJson()));
      final mapFile = File('${root.path}/maps/map.json');
      await mapFile.writeAsString(jsonEncode(map.toJson()));

      const reader = LocalProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: _Root(root.path),
      );
      addTearDown(mutations.closeAll);
      addTearDown(queries.closeAll);
      final opened = await queries.open(root.path);
      final before = await mapFile.readAsBytes();
      await expectLater(
        mutations.plan(
          root.path,
          actionId: 'placed_element.set_geometry',
          parameters: const {
            'mapId': 'map',
            'instanceId': 'a',
            'pixelX': 17,
            'pixelY': 35,
          },
          idempotencyKey: 'missing-size',
          requestId: 'missing-size',
          expectedRevision: opened.snapshotRevision,
        ),
        throwsA(isA<EditorAuthoringMutationFailure>()),
      );
      expect(await mapFile.readAsBytes(), before);
      final plan = await mutations.plan(
        root.path,
        actionId: 'placed_element.set_geometry',
        parameters: const {
          'mapId': 'map',
          'instanceId': 'a',
          'pixelX': 17,
          'pixelY': 35,
          'pixelSize': {'width': 5, 'height': 7},
        },
        idempotencyKey: 'geometry',
        requestId: 'geometry',
        expectedRevision: opened.snapshotRevision,
      );
      expect(await mapFile.readAsBytes(), before);
      final applied = await mutations.apply(
        plan,
        operationId: 'geometry-apply',
      );
      expect(applied.receipt.actionId, 'placed_element.set_geometry');
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      final saved = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
      );
      expect(saved.placedElements.map((e) => e.id), ['a', 'b']);
      expect(
        saved.placedElements.first.pixelOffset,
        const PixelOffset(x: 1, y: 3),
      );
      expect(
        saved.placedElements.first.pixelSize,
        const PixelSize(width: 5, height: 7),
      );
      await mutations.undo(
        root.path,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'geometry-undo',
      );
      expect(await mapFile.readAsBytes(), before);
      final restored = (await queries.open(root.path)).query(
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          view: AuthoringQueryView.detail,
          ids: const ['map'],
        ),
      );
      expect(
        ((restored['items']! as List).single as Map)['placedElements'],
        map.toJson()['placedElements'],
      );
    },
  );
}

final class _Root implements EditorProjectRootLocator {
  const _Root(this.path);
  final String path;
  @override
  Future<String> locateForResource(String resourcePath) async => path;
}
