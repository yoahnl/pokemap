import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';

import '../../../map_authoring/test/support/glb_fixture.dart' show triangleGlb;
import '../../../map_core/test/spatial_ramp_surface_test.dart'
    show surfaceScene;

void main() {
  test(
    'editor bridge persists clears reopens and undoes a precise stair surface',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'ramp-surface-editor-',
      );
      addTearDown(() => root.delete(recursive: true));
      final map = MapData(
        id: 'map',
        name: 'Escalier',
        version: ProjectVersion.v9,
        size: const GridSize(width: 6, height: 4),
        spatialScene: surfaceScene().copyWith(instances: []),
      );
      final project = ProjectManifest(
        name: 'Escalier',
        version: ProjectVersion.v9,
        tilesets: [],
        maps: const [
          ProjectMapEntry(
            id: 'map',
            name: 'Escalier',
            relativePath: 'maps/map.json',
          ),
        ],
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
      );
      final mapFile = File('${root.path}/maps/map.json');
      await mapFile.parent.create(recursive: true);
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      await File(
        '${root.path}/project.json',
      ).writeAsString(jsonEncode(project.toJson()));
      final modelFile = File('${root.path}/unit.glb');
      await modelFile.writeAsBytes(triangleGlb());
      const reader = EditorProjectFileReader();
      final path = await reader.canonicalizeDirectory(root.path);
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      addTearDown(queries.closeAll);
      addTearDown(mutations.closeAll);
      await queries.retainOnly(path);
      await mutations.retainOnly(path);
      var sequence = 0;
      Future<EditorAuthoringMutationResult> mutate(
        String action,
        Map<String, Object?> parameters,
      ) async {
        final before = await mapFile.readAsBytes();
        final planned = await mutations.plan(
          path,
          actionId: action,
          parameters: parameters,
          idempotencyKey: 'plan-${sequence++}',
        );
        expect(await mapFile.readAsBytes(), before);
        final result = await mutations.apply(
          planned,
          operationId: 'apply-${sequence++}',
        );
        expect(result.receipt.actionId, action);
        return result;
      }

      final staged = await mutations.stageArtifact(
        path,
        sourcePath: modelFile.path,
      );
      await mutate('model3d.import', {
        'modelId': 'stair-model',
        'name': 'Escalier',
        'artifactHandle': staged.reference.handle,
      });
      await mutate('map3d.instance.upsert', {
        'mapId': 'map',
        'instance': surfaceScene().instances.single.toJson(),
      });
      final before = await mapFile.readAsBytes();
      final navigation = map.spatialScene!.navigation.toJson();
      (navigation['ramps'] as List).single['surfaceInstanceId'] = 'stairs';
      navigation['maximumFishingDropWorld'] = .5;
      final applied = await mutate('map3d.navigation.configure', {
        'mapId': 'map',
        'navigation': navigation,
      });
      final linkedBytes = await mapFile.readAsBytes();
      MapData saved() =>
          MapData.fromJson(jsonDecode(mapFile.readAsStringSync()));
      expect(
        saved().spatialScene!.navigation.ramps.single.surfaceInstanceId,
        'stairs',
      );
      expect(saved().spatialScene!.navigation.ramps.single.x, 1.25);
      expect(saved().spatialScene!.navigation.maximumFishingDropWorld, .5);
      final linked = saved();
      await mutations.closeProject(path);
      await queries.closeAll();
      await queries.retainOnly(path);
      expect(await mutations.readRevision(path), isNotEmpty);
      expect(saved(), linked);
      final cleared = linked.spatialScene!.navigation.toJson();
      (cleared['ramps'] as List).single['surfaceInstanceId'] = null;
      final clear = await mutate('map3d.navigation.configure', {
        'mapId': 'map',
        'navigation': cleared,
      });
      expect(
        saved().spatialScene!.navigation.ramps.single.surfaceInstanceId,
        isNull,
      );
      await mutations.undo(
        path,
        entryId: clear.receipt.receiptId,
        idempotencyKey: 'undo-clear',
      );
      expect(await mapFile.readAsBytes(), linkedBytes);
      await mutations.undo(
        path,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'undo-link',
      );
      expect(await mapFile.readAsBytes(), before);
    },
  );
}
