import 'dart:isolate';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';

import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/data/local_resource_usage_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/exterior_decoration_fixture.dart';

void main() {
  test('saved exterior owners appear in resource usages and invalidate after removal', () async {
    final base = Directory(
      '/Users/karim/Library/Caches/AveluneQA/exterior-decoration/authoring',
    );
    await base.create(recursive: true);
    final root = await base.createTemp('usage_studio_');
    addTearDown(() => root.delete(recursive: true));
    final fixture = await createExteriorDecorationFixture(root.path);
    final project = exteriorDecorationFixtureProject();
    final assets = File('${root.path}/$assetCatalogStorageKey');
    await assets.parent.create(recursive: true);
    await assets.writeAsString(
      jsonEncode(
        AssetCatalog(
          records: [
            for (final model in project.models3d)
              AssetRecord(
                id: model.sourceAssetId,
                logicalPath: model.relativePath,
                artifact: ContentArtifactRef.fromBytes([
                  1,
                ], mediaType: 'model/gltf-binary'),
              ),
          ],
        ).toJson(),
      ),
    );
    final service = LocalMapExteriorDecorationAuthoring(
      policy: await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader(),
      ),
    );
    final placed = await service.setSector(
      projectRoot: root.path,
      mapId: 'route',
      expectedRevision: fixture['revision'] as String,
      operationId: 'place-tree',
      sector: ExteriorDecorationSector(
        id: 'west',
        originX: -16,
        originZ: 0,
        scene: MapSpatialScene(
          width: 16,
          depth: 16,
          instances: [
            SpatialModelInstance(
              id: 'tree',
              modelId: 'oak',
              position: Model3dVector3(x: 2, y: 0, z: 2),
            ),
          ],
        ),
      ),
    );
    final port = LocalResourceUsageAdapter(
      session: ProjectSession(
        sessionId: 'usage',
        name: project.name,
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      ),
    );
    addTearDown(port.dispose);
    final report = await port.analyze(
      const ResourceUsageTarget(family: 'models3d', id: 'oak'),
    );
    expect(report.complete, isTrue, reason: report.coverageIssues.toString());
    final owner = report.entries.singleWhere(
      (entry) => entry.entityId == 'exterior:sector:west',
    );
    expect(owner.mapId, 'route');
    expect(owner.ownerLabel, contains('Décor extérieur'));
    expect(owner.location, contains('maps/route.decoration/west.json'));
    expect(await port.isCurrent(report), isTrue);
    await service.removeSector(
      projectRoot: root.path,
      mapId: 'route',
      sectorId: 'west',
      expectedRevision: placed.afterRevision,
      operationId: 'remove-tree',
    );
    expect(await port.isCurrent(report), isFalse);
    final reopened = await port.analyze(report.target);
    expect(
      reopened.entries.where(
        (entry) => entry.entityId?.startsWith('exterior:') == true,
      ),
      isEmpty,
    );
  });
  test(
    'Studio exterior persistence uses the canonical seeded authoring worker',
    () async {
      final base = Directory(
        '/Users/karim/Library/Caches/AveluneQA/exterior-decoration/authoring',
      );
      await base.create(recursive: true);
      final root = await base.createTemp('worker_studio_');
      addTearDown(() => root.delete(recursive: true));
      await createExteriorDecorationFixture(root.path);
      final session = ProjectSession(
        sessionId: 'worker-studio',
        name: 'Worker studio',
        directoryPath: root.path,
        storage: ProjectSessionStorage.workingCatalog,
      );
      final adapter = LocalMapWorkspaceAdapter();
      await adapter.loadCatalog(session);
      await adapter.loadMap(
        session,
        const ProjectMapEntry(
          id: 'route',
          name: 'Route',
          relativePath: 'maps/route.json',
        ),
      );
      final port = ReceivePort();
      final traces = <Map>[];
      final subscription = port.listen((value) => traces.add(value as Map));
      MapAuthoringWorkerDiagnostics.port = port.sendPort;
      addTearDown(() async {
        MapAuthoringWorkerDiagnostics.port = null;
        await subscription.cancel();
        port.close();
      });
      Future<Map> trace() async {
        for (var i = 0; i < 100 && traces.isEmpty; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(traces, isNotEmpty);
        return traces.removeAt(0);
      }

      final state = await adapter.loadExteriorDecoration(session, 'route');
      await trace();
      final changed = await adapter.saveExteriorDecorationSectors(
        session,
        'route',
        [
          ExteriorDecorationSector(
            id: 'west',
            originX: -16,
            originZ: 0,
            scene: MapSpatialScene(
              width: 16,
              depth: 16,
              heightLevels: List.filled(256, 1),
            ),
          ),
        ],
        [],
        state.revision,
      );
      final rows = (await trace())['rows'] as List;
      expect(
        rows.where(
          (row) =>
              row['path'] == 'maps/route.json' && row['operation'] == 'read',
        ),
        isEmpty,
      );
      final reopened = await adapter.loadExteriorDecoration(session, 'route');
      await trace();
      expect(reopened.revision, changed.revision);
      expect(reopened.decoration!.sectors.single.scene.heightLevels.first, 1);
    },
  );
}
