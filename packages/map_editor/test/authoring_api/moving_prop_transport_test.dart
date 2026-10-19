import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'editor adapter semantically authors props and preserves map content on delete',
    () async {
      final root = await Directory.systemTemp.createTemp('moving-prop-editor-');
      addTearDown(() => root.delete(recursive: true));
      final map = MapData(
        id: 'hall',
        name: 'Hall',
        size: const GridSize(width: 8, height: 8),
        layers: [
          MapLayer.tile(id: 'art', name: 'Décors', cells: List.filled(64, 0)),
        ],
        placedElements: const [
          MapPlacedElement(
            id: 'visual',
            elementId: 'gate-art',
            layerId: 'art',
            pos: GridPos(x: 2, y: 2),
            properties: {
              pokemapPlacementOriginProperty: pokemapPlacementOriginAuthored,
            },
          ),
        ],
      );
      final project = ProjectManifest(
        name: 'Props',
        maps: const [
          ProjectMapEntry(id: 'hall', name: 'Hall', relativePath: 'hall.json'),
        ],
        settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
        tilesets: const [],
        elements: const [
          ProjectElementEntry(
            id: 'gate-art',
            name: 'Grille',
            tilesetId: 'tiles',
            categoryId: 'decor',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
          ),
        ],
      );
      final prop = MovingPropDefinition(
        id: 'gate',
        placedElementId: 'visual',
        closedPositionPx: const PixelOffset(x: 64, y: 64),
        openPositionPx: const PixelOffset(x: 96, y: 64),
        collisionRect: const PixelRect(
          leftPx: 0,
          topPx: 0,
          widthPx: 32,
          heightPx: 32,
        ),
      );
      final file = File('${root.path}/hall.json');
      await file.writeAsString(jsonEncode(map.toJson()));
      final projectFile = File('${root.path}/project.json');
      await projectFile.writeAsString(jsonEncode(project.toJson()));
      const reader = LocalProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: _RootLocator(root.path),
      );
      addTearDown(mutations.closeAll);
      addTearDown(queries.closeAll);
      var revision = (await queries.open(root.path)).snapshotRevision;
      var expectedPlacements = map.placedElements;
      for (final (action, parameters) in [
        (
          'map.prop.upsert',
          <String, Object?>{'mapId': 'hall', 'prop': prop.toJson()},
        ),
        (
          'map.prop.delete',
          <String, Object?>{'mapId': 'hall', 'propId': 'gate'},
        ),
      ]) {
        final before = await file.readAsBytes();
        final plan = await mutations.plan(
          root.path,
          actionId: action,
          parameters: parameters,
          idempotencyKey: action,
          requestId: action,
          expectedRevision: revision,
        );
        expect(await file.readAsBytes(), before);
        final result = await mutations.apply(plan, operationId: action);
        expect(result.receipt.status, AuthoringReceiptStatus.applied);
        revision = result.snapshotRevision!;
        final saved = MapData.fromJson(jsonDecode(await file.readAsString()));
        expect(saved.movingProps, action.endsWith('upsert') ? [prop] : isEmpty);
        expect(saved.layers, map.layers);
        expect(saved.placedElements, expectedPlacements);
        if (action.endsWith('upsert')) {
          final move = await mutations.plan(
            root.path,
            actionId: 'placed_element.set_geometry',
            parameters: {
              'mapId': 'hall',
              'instanceId': 'visual',
              'pixelX': 96,
              'pixelY': 64,
              'pixelSize': null,
            },
            idempotencyKey: 'move',
            requestId: 'move',
            expectedRevision: revision,
          );
          final moved = await mutations.apply(move, operationId: 'move');
          revision = moved.snapshotRevision!;
          final movedMap = MapData.fromJson(
            jsonDecode(await file.readAsString()),
          );
          expect(
            movedMap.movingProps.single.closedPositionPx,
            const PixelOffset(x: 96, y: 64),
          );
          expect(
            movedMap.movingProps.single.openPositionPx,
            const PixelOffset(x: 128, y: 64),
          );
          expectedPlacements = [
            map.placedElements.single.copyWith(pos: const GridPos(x: 3, y: 2)),
          ];
          expect(movedMap.placedElements, expectedPlacements);
          final beforeFailure = await file.readAsBytes();
          await expectLater(
            mutations.plan(
              root.path,
              actionId: 'placed_element.set_geometry',
              parameters: {
                'mapId': 'hall',
                'instanceId': 'visual',
                'pixelX': 224,
                'pixelY': 64,
                'pixelSize': null,
              },
              idempotencyKey: 'outside',
              requestId: 'outside',
              expectedRevision: revision,
            ),
            throwsA(isA<Exception>()),
          );
          expect(await file.readAsBytes(), beforeFailure);
        }
      }
      expect(jsonDecode(await projectFile.readAsString()), project.toJson());
    },
  );
}

final class _RootLocator implements EditorProjectRootLocator {
  const _RootLocator(this.root);
  final String root;
  @override
  Future<String> locateForResource(String resourcePath) async => root;
}
