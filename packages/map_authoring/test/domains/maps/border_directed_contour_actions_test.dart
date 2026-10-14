import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import '../assets/resource_information_fixture.dart';
import 'environment_spatial_actions_test.dart' show environmentModelGlb;
import 'border_spatial_actions_test.dart'
    show spatialBorderAuthoringFixture, context;

void main() {
  for (final jsonl in [false, true]) {
    test(
        'directed region publish materialize and reopen through ${jsonl ? 'JSONL' : 'direct API'}',
        () async {
      final fixture = spatialBorderAuthoringFixture();
      final host = await ResourceInformationFixture.create(fixture.project
          .copyWith(
              maps: [],
              models3d: [],
              borderCatalog: const ProjectBorderCatalog.empty()));
      addTearDown(host.dispose);
      final width = fixture.map.spatialScene!.width,
          depth = fixture.map.spatialScene!.depth;
      final cells = [
        for (var z = 0; z < depth; z++)
          for (var x = 0; x < width; x++)
            x >= 1 &&
                x < width - 1 &&
                z >= 1 &&
                z < depth - 1 &&
                !(x == 2 && z == 2)
      ];
      final scene = fixture.map.spatialScene!
          .copyWith(heightLevels: cells.map((cell) => cell ? 8 : 0).toList());
      final mapFile = File('${host.root.path}/maps/map.json');
      await mapFile.parent.create(recursive: true);
      await mapFile.writeAsString(jsonEncode(fixture.map.copyWith(
          spatialScene: scene,
          layers: [MapLayer.border(id: 'border', name: 'Falaises')]).toJson()));
      final model = fixture.project.models3d.single;
      final bytes = environmentModelGlb();
      final source = File('${host.root.path}/${model.relativePath}');
      await source.parent.create(recursive: true);
      await source.writeAsBytes(bytes);
      final artifact =
          ContentArtifactRef.fromBytes(bytes, mediaType: 'model/gltf-binary');
      final blob = File('${host.root.path}/${assetBlobStorageKey(artifact)}');
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(bytes);
      await File('${host.root.path}/assets/.pokemap-assets.json')
          .writeAsString(jsonEncode(AssetCatalog(records: [
        AssetRecord(
            id: model.sourceAssetId,
            logicalPath: model.relativePath,
            artifact: artifact)
      ]).toJson()));
      await File('${host.root.path}/project.json').writeAsString(jsonEncode(
          fixture.project
              .copyWith(borderCatalog: const ProjectBorderCatalog.empty())
              .toJson()));
      final raw = encodeBorderBlueprintRecordJson(
          fixture.project.borderCatalog.records.single,
          formatVersion: 5);
      final definition = (raw['draft'] as Map)['definition'] as Map;
      definition['followContourDirection'] = true;
      definition['replacesGround'] = true;
      definition['groundBaseOffset'] = -.0625;
      final primitives = definition['primitives'] as List;
      for (final primitive in primitives.cast<Map>()) {
        primitive['authoredOrientation'] = 'east';
        primitive['anchorWorld'] = {
          'x': 0.0,
          'y': scene.levelHeight * 8,
          'z': 0.0
        };
      }
      final corner = Map<String, Object?>.from(
          primitives.singleWhere((p) => p['role'] == 'lineCorner') as Map);
      primitives.removeWhere((p) => p['role'] == 'lineCorner');
      primitives.add({...corner, 'id': 'corner-right', 'cornerTurn': 'right'});
      primitives.add({...corner, 'id': 'corner-left', 'cornerTurn': 'left'});
      Future<void> mutate(
          String action, Map<String, Object?> parameters) async {
        if (jsonl) {
          await host.mutate(action, parameters);
          return;
        }
        final snapshot = await host.snapshots.load(ProjectHandle(host.project));
        final key = 'direct-${host.next++}';
        final request = AuthoringRequest(
            requestId: key,
            actionId: action,
            actionVersion: 1,
            workspaceHandle: host.workspace,
            parameters: parameters,
            expectedRevision: snapshot.revision,
            idempotencyKey: key);
        final before = await mapFile.readAsBytes();
        final planned = await host.mutations
            .planMutation(ProjectHandle(host.project), request);
        expect(await mapFile.readAsBytes(), before);
        final applied = await host.mutations.applyMutation(
            ProjectHandle(host.project),
            planId: planned.planId,
            operationId: key);
        expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      }

      await mutate('border.blueprint.draft.upsert', {'record': raw});
      await mutate('border.blueprint.publish', {'blueprintId': 'fence'});
      final edgePoints = [
        for (var x = width - 2; x >= 1; x--) {'x': x, 'y': 2}
      ];
      await mutate('border_layer.feature_create', {
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'cliff-edge',
        'blueprintId': 'fence',
        'name': 'Falaise vers l’ouest',
        'seed': '17',
        'geometry': {
          'kind': 'stroke',
          'alignment': 'gridEdges',
          'strokes': [
            {'id': 'edge', 'closed': false, 'points': edgePoints}
          ]
        }
      });
      await mutate('border_layer.materialize_apply',
          {'mapId': 'map', 'layerId': 'border', 'featureId': 'cliff-edge'});
      final edgeMap =
          MapData.fromJson(jsonDecode(await mapFile.readAsString()));
      expect(edgeMap.spatialScene!.instances.map((i) => i.position.y),
          everyElement(0.0));
      expect(edgeMap.spatialScene!.instances.map((i) => i.rotationDegrees),
          everyElement(-180.0));
      final edgeFeature =
          (edgeMap.layers.single as BorderLayer).content.features.single;
      expect(
          (edgeFeature.geometry as BorderStrokeGeometry)
              .strokes
              .single
              .points
              .first
              .x,
          width - 2);
      await mutate('border_layer.feature_delete',
          {'mapId': 'map', 'layerId': 'border', 'featureId': 'cliff-edge'});
      await mutate('border_layer.feature_create', {
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'cliff-cells',
        'blueprintId': 'fence',
        'name': 'Couronne au bord du plateau',
        'seed': '17',
        'geometry': {
          'kind': 'stroke',
          'alignment': 'cellCenters',
          'strokes': [
            {
              'id': 'crown',
              'closed': false,
              'points': [
                for (var x = 1; x <= width - 2; x++) {'x': x, 'y': 0}
              ]
            }
          ]
        }
      });
      await mutate('border_layer.materialize_apply',
          {'mapId': 'map', 'layerId': 'border', 'featureId': 'cliff-cells'});
      final cellMap =
          MapData.fromJson(jsonDecode(await mapFile.readAsString()));
      expect(cellMap.spatialScene!.instances.map((i) => i.position.y),
          everyElement(0.0));
      expect(cellMap.spatialScene!.instances.map((i) => i.rotationDegrees),
          everyElement(0.0));
      expect(cellMap.spatialScene!.instances.first.position.z, .5);
      final cellReopened = MapData.fromJson(cellMap.toJson());
      expect(
          diagnoseSpatialBorderFeature(
                  manifest:
                      (await host.snapshots.load(ProjectHandle(host.project)))
                          .manifest,
                  map: cellReopened,
                  layerId: 'border',
                  featureId: 'cliff-cells')
              .hasErrors,
          isFalse);
      await mutate('border_layer.feature_delete',
          {'mapId': 'map', 'layerId': 'border', 'featureId': 'cliff-cells'});
      final maskDefinition = Map<String, Object?>.from(definition)
        ..['replacesGround'] = false
        ..['groundBaseOffset'] = 0
        ..['masksGroundCells'] = true;
      await mutate('border.blueprint.draft.upsert', {
        'record': {'id': 'wall-mask', 'draft': {'baseRevision': 0, 'definition': maskDefinition}},
      });
      await mutate('border.blueprint.publish', {'blueprintId': 'wall-mask'});
      await mutate('border_layer.feature_create', {
        'mapId': 'map', 'layerId': 'border', 'featureId': 'wall-mask',
        'blueprintId': 'wall-mask', 'name': 'Muret sans sol dessous', 'seed': '19',
        'geometry': {'kind': 'stroke', 'alignment': 'cellCenters', 'strokes': [
          {'id': 'mask', 'closed': false, 'points': [for (var x = 1; x <= width - 2; x++) {'x': x, 'y': 0}]},
        ]},
      });
      await mutate('border_layer.materialize_apply', {'mapId': 'map', 'layerId': 'border', 'featureId': 'wall-mask'});
      final maskSnapshot = await host.snapshots.load(ProjectHandle(host.project));
      expect(maskSnapshot.manifest.borderCatalog.recordById('wall-mask')!.latestPublished!.definition.masksGroundCells, isTrue);
      expect(resolveSpatialBorderGroundMaskCells(manifest: maskSnapshot.manifest, map: maskSnapshot.maps.single),
        {for (var x = 1; x <= width - 2; x++) (x, 0)});
      expect(maskSnapshot.maps.single.spatialScene!.heightLevels, scene.heightLevels);
      expect(maskSnapshot.maps.single.spatialScene!.navigation, scene.navigation);
      await mutate('border_layer.feature_delete', {'mapId': 'map', 'layerId': 'border', 'featureId': 'wall-mask'});
      await mutate('border_layer.feature_create', {
        'mapId': 'map',
        'layerId': 'border',
        'featureId': 'cliff',
        'blueprintId': 'fence',
        'name': 'Plateau percé',
        'seed': '17',
        'geometry': {
          'kind': 'region',
          'width': width,
          'height': depth,
          'cells': cells
        }
      });
      await mutate('border_layer.materialize_apply',
          {'mapId': 'map', 'layerId': 'border', 'featureId': 'cliff'});
      final savedBytes = await mapFile.readAsBytes();
      final saved = MapData.fromJson(jsonDecode(utf8.decode(savedBytes)));
      final feature =
          (saved.layers.single as BorderLayer).content.features.single;
      expect(saved.spatialScene!.instances.map((i) => i.position.y),
          everyElement(0.0));
      expect(
          saved.spatialScene!.instances.map((i) => i.rotationDegrees).toSet(),
          {0.0, -90.0, -180.0, -270.0});
      expect(
          feature.materialization!.spatialPlacements
              .map((p) => p.primitiveId)
              .toSet(),
          containsAll(['corner-left', 'corner-right', 'lineStraight']));
      await host.command('close', {'projectHandle': host.project});
      final opened =
          await host.command('open', {'projectRoot': host.root.path});
      expect(opened.status, AuthoringResultStatus.success);
      final handle = ProjectHandle(opened.data['projectHandle'] as String);
      final reopened = await host.snapshots.load(handle);
      expect(reopened.maps.single, saved);
      expect(await mapFile.readAsBytes(), savedBytes);
      expect(
          reopened.manifest.borderCatalog.recordById('fence')!.latestPublished!
              .definition.followContourDirection,
          isTrue);
      expect(
          reopened.manifest.borderCatalog.recordById('fence')!.latestPublished!
              .definition.replacesGround,
          isTrue);
      expect(
          reopened.manifest.borderCatalog.recordById('fence')!.latestPublished!
              .definition.groundBaseOffset,
          -.0625);
      expect(reopened.manifest.borderCatalog.recordById('wall-mask')!.latestPublished!.definition.masksGroundCells, isTrue);
      expect(
          resolveSpatialBorderGroundReplacements(
              manifest: reopened.manifest, map: saved),
          isNotEmpty);
      expect(
          resolveSpatialBorderGroundReplacements(
                  manifest: reopened.manifest, map: saved)
              .map((contact) => contact.lowerHeight),
          everyElement(-.0625));
      expect(
          diagnoseSpatialBorderFeature(
                  manifest: reopened.manifest,
                  map: reopened.maps.single,
                  layerId: 'border',
                  featureId: 'cliff')
              .hasErrors,
          isFalse);
      await host.command('close', {'projectHandle': handle.value});
    });
  }

  test('canonical publication keeps cliff direction and both corner shapes',
      () async {
    final fixture = spatialBorderAuthoringFixture(published: false);
    final raw = encodeBorderBlueprintRecordJson(
        fixture.project.borderCatalog.records.single,
        formatVersion: 5);
    final definition = (raw['draft'] as Map)['definition'] as Map;
    definition['followContourDirection'] = true;
    final primitives = definition['primitives'] as List;
    final corner = Map<String, Object?>.from(
        primitives.singleWhere((p) => p['role'] == 'lineCorner') as Map);
    primitives.removeWhere((p) => p['role'] == 'lineCorner');
    primitives.add({...corner, 'id': 'corner-right', 'cornerTurn': 'right'});
    primitives.add({...corner, 'id': 'corner-left', 'cornerTurn': 'left'});
    final project = fixture.project.copyWith(
        borderCatalog: ProjectBorderCatalog(
            formatVersion: 5,
            records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 5)]));
    final snapshot = librarySnapshot([fixture.map], project: project);
    final mutation = await BorderCatalogActions(
            artifactStore:
                MemoryArtifactStore(maximumArtifactBytes: 1024 * 1024))
        .build(context(
            snapshot, 'border.blueprint.publish', {'blueprintId': 'fence'}));
    final change = mutation.changeSet.changes
        .singleWhere((change) => change.resource.kind == 'project');
    final published =
        ProjectManifest.fromJson(jsonDecode(utf8.decode(change.afterBytes!)))
            .borderCatalog
            .records
            .single
            .latestPublished!
            .definition;
    expect(published.followContourDirection, isTrue);
    expect(
        published.primitives
            .where((p) => p.role == BorderPrimitiveRole.lineCorner)
            .map((p) => p.cornerTurn)
            .toSet(),
        BorderCornerTurn.values.toSet());
  });
}
