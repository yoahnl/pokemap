import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

import '../../../map_authoring/test/support/glb_fixture.dart' show triangleGlb;

void main() {
  test(
    'editor transport persists lift batches, directional ledges and camera while invalid plans preserve map bytes',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'editor-spatial-navigation-',
      );
      addTearDown(() => root.delete(recursive: true));
      const reader = EditorProjectFileReader();
      final path = await reader.canonicalizeDirectory(root.path);
      final file = File('$path/maps/room.json');
      await file.parent.create(recursive: true);
      final map = MapData(
        id: 'room',
        name: 'Salle',
        version: ProjectVersion.v9,
        size: const GridSize(width: 6, height: 4),
        spatialScene: MapSpatialScene(width: 6, depth: 4),
      );
      final project = ProjectManifest(
        name: 'Plateformes',
        version: ProjectVersion.v9,
        maps: const [
          ProjectMapEntry(
            id: 'room',
            name: 'Salle',
            relativePath: 'maps/room.json',
          ),
        ],
        tilesets: [],
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
      );
      await file.writeAsString(jsonEncode(map.toJson()));
      final manifest = File('$path/project.json');
      await manifest.writeAsString(jsonEncode(project.toJson()));
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(queries.closeAll);
      addTearDown(mutations.closeAll);
      var sequence = 0;
      Future<EditorAuthoringMutationResult> apply(
        String action,
        Map<String, Object?> parameters,
      ) async {
        final before = await file.readAsBytes();
        final plan = await mutations.plan(
          path,
          actionId: action,
          parameters: parameters,
          idempotencyKey: 'plan-${sequence++}',
        );
        expect(await file.readAsBytes(), before);
        final result = await mutations.apply(
          plan,
          operationId: 'apply-${sequence++}',
        );
        expect(result.receipt.actionId, action);
        return result;
      }

      Future<void> refuse(
        String action,
        Map<String, Object?> parameters,
        String errorCode,
      ) async {
        final before = await file.readAsBytes();
        await expectLater(
          mutations.plan(
            path,
            actionId: action,
            parameters: parameters,
            idempotencyKey: 'refuse-${sequence++}',
          ),
          throwsA(
            isA<EditorAuthoringMutationFailure>().having(
              (error) => error.code,
              'code',
              errorCode,
            ),
          ),
        );
        expect(await file.readAsBytes(), before);
      }

      Future<MapData> reopen() async {
        await mutations.closeAll();
        await queries.closeAll();
        return (await queries.open(path)).maps.single;
      }

      final model = File('$path/deck.glb');
      await model.writeAsBytes(triangleGlb());
      final staged = await mutations.stageArtifact(
        path,
        sourcePath: model.path,
      );
      await apply('model3d.import', {
        'modelId': 'deck',
        'name': 'Plateau',
        'artifactHandle': staged.reference.handle,
      });
      final lifts = [
        for (final x in [1, 4])
          SpatialLiftDefinition(
            id: 'lift-$x',
            name: 'Ascenseur $x',
            instanceId: 'deck-$x',
            x: x,
            z: 1,
            width: 1,
            depth: 1,
            lowerHeight: 0,
            upperHeight: 3,
            durationMs: 1000,
          ),
      ];
      final instances = [
        for (final lift in lifts)
          SpatialModelInstance(
            id: lift.instanceId,
            modelId: 'deck',
            position: Model3dVector3(x: lift.x + .5, y: 0, z: 1.5),
          ),
      ];
      await apply('map3d.instance.upsert_batch', {
        'mapId': map.id,
        'instances': instances.map((item) => item.toJson()).toList(),
      });
      final projectBytes = await manifest.readAsBytes();
      final base = (await reopen()).spatialScene!;
      final camera = SpatialCameraProfile(
        projection: SpatialCameraProjection.orthographic,
        orthographicHeight: 12.5,
        pitchDegrees: 49,
      );
      final ledge = SpatialLedge(
        id: 'drop',
        x: 2,
        z: 0,
        direction: SpatialRampDirection.south,
      );
      await apply('map3d.camera.configure', {
        'mapId': map.id,
        'camera': camera.toJson(),
      });
      await apply('map3d.ledge.configure', {
        'mapId': map.id,
        'ledges': [ledge.toJson()],
      });
      await apply('map3d.lift.upsert_batch', {
        'mapId': map.id,
        'lifts': lifts.map((item) => item.toJson()).toList(),
      });
      final authored = (await reopen()).spatialScene!;
      expect(authored.camera, camera);
      expect(authored.navigation.ledges, [ledge]);
      expect(authored.lifts, lifts);
      expect(authored.instances, base.instances);
      expect(authored.heightLevels, base.heightLevels);
      await refuse('map3d.camera.configure', {
        'mapId': map.id,
        'camera': {...camera.toJson(), 'orthographicHeight': 0},
      }, 'map3d.parameters_invalid');
      await refuse('map3d.ledge.configure', {
        'mapId': map.id,
        'ledges': [
          {...ledge.toJson(), 'z': 3},
        ],
      }, 'map3d.parameters_invalid');
      await refuse('map3d.lift.upsert_batch', {
        'mapId': map.id,
        'lifts': [
          {...lifts.first.toJson(), 'name': 'Modification partielle'},
          {...lifts.last.toJson(), 'instanceId': 'absent'},
        ],
      }, 'map3d.lift.invalid');
      await refuse('map3d.lift.delete_batch', {
        'mapId': map.id,
        'liftIds': [lifts.first.id, 'absent'],
      }, 'map3d.lift.invalid');
      final beforeDelete = await file.readAsBytes();
      final deleted = await apply('map3d.lift.delete_batch', {
        'mapId': map.id,
        'liftIds': lifts.map((item) => item.id).toList(),
      });
      expect((await reopen()).spatialScene, authored.copyWith(lifts: []));
      await mutations.undo(
        path,
        entryId: deleted.receipt.receiptId,
        idempotencyKey: 'undo-lifts',
      );
      expect(await file.readAsBytes(), beforeDelete);
      expect((await reopen()).spatialScene, authored);
      expect(await manifest.readAsBytes(), projectBytes);
    },
  );
}
