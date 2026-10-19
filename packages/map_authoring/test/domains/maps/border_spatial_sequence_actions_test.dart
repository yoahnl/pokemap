import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_information_fixture.dart';
import '../assets/resource_pack_import_fixture.dart';
import 'border_spatial_actions_test.dart' show spatialBorderAuthoringFixture;
import 'environment_spatial_actions_test.dart' show environmentModelGlb;

void main() {
  test('discovers the spatial cyclic sequence contract', () {
    for (final id in [
      'border.blueprint.draft.upsert',
      'border.blueprint.publish'
    ]) {
      final action = BorderCatalogActions.descriptors
          .singleWhere((value) => value.id == id);
      expect(action.extensions['spatialSequence'], {
        'minimumCatalogFormatVersion': 12,
        'lengthField': 'definition.sequenceLength',
        'indexField': 'primitives[].sequenceIndex',
        'sourceDimension': '3d',
        'template': 'connectedLine',
        'straightOnly': true,
        'phaseReference': 'sourceEdgeOffsetPlusNodeIndex',
        'phaseBeforeSuppression': true,
        'lineSide': 'primary',
      });
    }
  });

  for (final jsonl in [false, true]) {
    for (final reverse in [false, true]) {
      test(
          '${jsonl ? 'JSONL' : 'direct API'} publishes moves erases and reopens cyclic borders reverse=$reverse',
          () async {
        final base = spatialBorderAuthoringFixture(
            straightOnly: true, includeCorner: false);
        final originalModel = base.project.models3d.single;
        final models = [
          for (var phase = 0; phase < 6; phase++)
            ProjectModel3dEntry.fromJson({
              ...originalModel.toJson(),
              'id': 'step-$phase',
              'sourceAssetId': 'step-source-$phase',
              'relativePath': 'assets/models3d/step-$phase.glb'
            })
        ];
        final project = base.project.copyWith(
            models3d: models,
            borderCatalog: const ProjectBorderCatalog.empty());
        final host = await ResourceInformationFixture.create(
            project.copyWith(maps: [], models3d: []));
        addTearDown(host.dispose);
        final mapFile = File('${host.root.path}/maps/map.json');
        await mapFile.parent.create(recursive: true);
        await mapFile.writeAsString(jsonEncode(base.map.copyWith(
          size: const GridSize(width: 24, height: 12),
          spatialScene: MapSpatialScene(width: 24, depth: 12),
          layers: [
            MapLayer.border(
                id: 'border',
                name: 'Motif',
                content: BorderLayerContent(features: const []))
          ],
        ).toJson()));
        final modelBytes = environmentModelGlb();
        final artifact = ContentArtifactRef.fromBytes(modelBytes,
            mediaType: 'model/gltf-binary');
        final blob = File('${host.root.path}/${assetBlobStorageKey(artifact)}');
        await blob.parent.create(recursive: true);
        await blob.writeAsBytes(modelBytes);
        for (final model in models) {
          final file = File('${host.root.path}/${model.relativePath}');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(modelBytes);
        }
        await File('${host.root.path}/assets/.pokemap-assets.json')
            .writeAsString(jsonEncode(AssetCatalog(records: [
          for (final model in models)
            AssetRecord(
                id: model.sourceAssetId,
                logicalPath: model.relativePath,
                artifact: artifact)
        ]).toJson()));
        final projectFile = File('${host.root.path}/project.json');
        await projectFile.writeAsString(jsonEncode(project.toJson()));
        var serial = 0;
        Future<void> mutate(
            String actionId, Map<String, Object?> parameters) async {
          final snapshot =
              await host.snapshots.load(ProjectHandle(host.project));
          final request = AuthoringRequest(
              requestId: 'sequence-${serial++}',
              actionId: actionId,
              actionVersion: 1,
              workspaceHandle: host.workspace,
              parameters: parameters,
              expectedRevision: snapshot.revision,
              idempotencyKey: 'sequence-$serial');
          final beforeMap = await mapFile.readAsBytes(),
              beforeProject = await projectFile.readAsBytes();
          late final String planId;
          if (jsonl) {
            final plan = await host.command('plan',
                {'projectHandle': host.project, 'request': request.toJson()});
            expect(plan.status, AuthoringResultStatus.success,
                reason: jsonEncode(plan.toJson()));
            planId = plan.data['planId'] as String;
          } else {
            planId = (await host.mutations
                    .planMutation(ProjectHandle(host.project), request))
                .planId;
          }
          expect(await mapFile.readAsBytes(), beforeMap);
          expect(await projectFile.readAsBytes(), beforeProject);
          if (jsonl) {
            final result = await host.command('apply', {
              'projectHandle': host.project,
              'planId': planId,
              'operationId': 'sequence-apply-$serial'
            });
            expect(result.status, AuthoringResultStatus.success,
                reason: jsonEncode(result.toJson()));
          } else {
            final result = await host.mutations.applyMutation(
                ProjectHandle(host.project),
                planId: planId,
                operationId: 'sequence-apply-$serial');
            expect(result.receipt.status, AuthoringReceiptStatus.applied);
          }
        }

        final definition = <String, Object?>{
          'name': 'Motif six étapes',
          'previewSeed': '17',
          'template': 'connectedLine',
          'straightOnly': true,
          'sequenceLength': 6,
          'sortOrder': 0,
          'defaults': {
            'irregularityPermille': 0,
            'detailDensityPermille': 0,
            'variationPermille': 1000,
            'maxOverlapPx': 0,
            'gapTolerancePx': 0,
            'depthRows': 1
          },
          'primitives': [
            for (var phase = 0; phase < 6; phase++)
              for (final kind in ['body', 'start', 'end'])
                {
                  'id': '$kind-$phase',
                  'sourceModelId': 'step-$phase',
                  'role': kind == 'body' ? 'lineStraight' : 'lineCap',
                  'sequenceIndex': phase,
                  'weight': 1,
                  'authoredOrientation': kind == 'end' ? 'west' : 'east',
                  'transforms': {
                    'allowFlipX': false,
                    'allowedQuarterTurns': [0, 1]
                  }
                }
          ],
        };
        await mutate('border.blueprint.draft.upsert', {
          'record': {
            'id': 'fence',
            'draft': {'baseRevision': 0, 'definition': definition}
          }
        });
        await mutate('border.blueprint.publish', {'blueprintId': 'fence'});
        final savedProject = await host.read();
        expect(savedProject.borderCatalog.formatVersion, 12);
        final record = encodeBorderBlueprintRecordJson(
            savedProject.borderCatalog.records.single,
            formatVersion: 12);
        for (final value in [
          (record['draft'] as Map)['definition'],
          (record['latestPublished'] as Map)['definition']
        ]) {
          expect(value['sequenceLength'], 6);
          expect(
              (value['primitives'] as List).map((p) => p['sequenceIndex'] ?? 0),
              [
                for (var phase = 0; phase < 6; phase++) ...[phase, phase, phase]
              ]);
        }
        if (!jsonl && !reverse) {
          final transferred = await NativeResourcePackImportFixture.create(
            sourceManifest: savedProject,
            roots: [
              NativeResourcePackRef(
                  kind: ResourcePackKind.borderBlueprint, id: 'fence')
            ],
            sourceFiles: [
              for (final model in models)
                NativeResourcePackFile(
                    id: model.sourceAssetId,
                    logicalPath: model.relativePath,
                    byteLength: modelBytes.length,
                    rawSha256: sha256.convert(modelBytes).toString(),
                    mediaType: 'model/gltf-binary',
                    openRead: () => Stream.value(modelBytes))
            ],
            target: ProjectManifest(
                name: 'Blank cyclic border target',
                version: ProjectVersion.v9,
                maps: [],
                tilesets: [],
                settings: ProjectSettings(
                    dimension: ProjectDimension.threeD,
                    spatialCamera: SpatialCameraProfile())),
          );
          addTearDown(transferred.dispose);
          final portable = transferred
              .source.archive.inspection.catalog.borderCatalog.records.single;
          expect(portable.latestPublished!.definition.sequenceLength, 6);
          final selection = await transferred.select(roots: [
            ResourcePackRef(
                kind: ResourcePackKind.borderBlueprint, id: portable.id)
          ]);
          final prepared = await transferred.prepare(selection: selection);
          expect(prepared.status, ResourcePackPreparedImportStatus.ready);
          await transferred.apply(await transferred.plan(prepared));
          final imported =
              (await transferred.loader.load(transferred.opened.projectHandle))
                  .manifest;
          expect(imported.borderCatalog.formatVersion, 12);
          final installed = imported.borderCatalog.records.single;
          expect(installed.draft.definition.sequenceLength, 6);
          expect(installed.latestPublished!.definition.sequenceLength, 6);
          expect(
              installed.draft.definition.primitives
                  .map((value) => value.sequenceIndex),
              portable.draft.definition.primitives
                  .map((value) => value.sequenceIndex));
          final importedModels =
              imported.models3d.map((model) => model.id).toSet();
          expect(
              installed.draft.definition.primitives.every(
                  (value) => importedModels.contains(value.sourceModelId)),
              isTrue);
          await transferred.close();
          await transferred.open();
          expect(
              (await transferred.loader.load(transferred.opened.projectHandle))
                  .manifest
                  .borderCatalog,
              imported.borderCatalog);
        }
        final target = <String, Object?>{
          'mapId': 'map',
          'layerId': 'border',
          'featureId': 'sequence'
        };
        await mutate('border_layer.feature_create', {
          ...target,
          'blueprintId': 'fence',
          'name': 'Séquence',
          'seed': '29',
          'geometry': {
            'kind': 'stroke',
            'strokes': [
              {
                'id': 'line',
                'closed': false,
                'points': [
                  for (var x = 1; x <= 12; x++)
                    {'x': reverse ? 13 - x : x, 'y': 2}
                ]
              }
            ]
          }
        });
        await mutate('border_layer.materialize_apply', target);
        MapData readMap() =>
            MapData.fromJson(jsonDecode(mapFile.readAsStringSync()));
        final initial = readMap();
        expect(initial.spatialScene!.instances.map((value) => value.modelId),
            [for (var i = 0; i < 12; i++) 'step-${i % 6}']);
        await mutate('border_layer.stroke_erase', {
          ...target,
          'points': [
            {'x': 4, 'y': 2}
          ]
        });
        final erased = readMap();
        final byX = {
          for (final instance in erased.spatialScene!.instances)
            instance.position.x: instance.modelId
        };
        expect(byX.values, hasLength(11));
        for (var x = 1; x <= 12; x++) {
          if (x != 4) expect(byX[x + .5], 'step-${(x - 1) % 6}');
        }
        await mutate(
            'border_layer.feature_move', {...target, 'dx': 2, 'dy': 1});
        await mutate('border_layer.materialize_apply', target);
        final moved = readMap();
        for (final instance in moved.spatialScene!.instances) {
          expect(instance.modelId, byX[instance.position.x - 2]);
        }
        final stableMap = await mapFile.readAsBytes(),
            stableProject = await projectFile.readAsBytes();
        final bad = await host.plan(
            'border_layer.feature_update', {...target, 'lineSide': 'inverted'});
        expect(bad.status, AuthoringResultStatus.failure);
        expect(jsonEncode(bad.toJson()),
            contains('border.spatial.line_side_inversion_unsupported'));
        expect(await mapFile.readAsBytes(), stableMap);
        expect(await projectFile.readAsBytes(), stableProject);
        final badCreate = await host.plan('border_layer.feature_create', {
          ...target,
          'featureId': 'unsupported',
          'name': 'Unsupported side',
          'blueprintId': 'fence',
          'seed': '1',
          'lineSide': 'inverted',
          'geometry': {
            'kind': 'stroke',
            'strokes': [
              {
                'id': 'line',
                'closed': false,
                'points': [
                  {'x': 1, 'y': 1},
                  {'x': 2, 'y': 1}
                ]
              }
            ]
          }
        });
        expect(badCreate.status, AuthoringResultStatus.failure);
        expect(jsonEncode(badCreate.toJson()),
            contains('border.spatial.line_side_inversion_unsupported'));
        expect(await mapFile.readAsBytes(), stableMap);
        expect(await projectFile.readAsBytes(), stableProject);
        await host.command('close', {'projectHandle': host.project});
        final opened =
            await host.command('open', {'projectRoot': host.root.path});
        expect(opened.status, AuthoringResultStatus.success);
        final restored = await host.snapshots
            .load(ProjectHandle(opened.data['projectHandle'] as String));
        expect(restored.maps.single, moved);
        expect(
            restored.manifest.borderCatalog, (await host.read()).borderCatalog);
        await host
            .command('close', {'projectHandle': restored.projectHandle.value});
      });
    }
  }
}
