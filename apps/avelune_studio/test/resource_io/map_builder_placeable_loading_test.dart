import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

void main() {
  late Directory root;
  late LocalProjectSessionAdapter sessions;
  late ProjectSession session;

  ProjectModel3dEntry model(String id) => ProjectModel3dEntry(
    id: id,
    name: id,
    sourceAssetId: 'model3d_$id',
    relativePath: 'assets/models3d/$id.glb',
    inspection: Model3dInspection(
      bounds: Model3dBounds(
        min: Model3dVector3.zero,
        max: Model3dVector3(x: 1, y: 1, z: 1),
      ),
      meshCount: 1,
      triangleCount: 4,
    ),
  );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('studio_placeable_catalog_');
    sessions = LocalProjectSessionAdapter();
    await writeExampleProject(root);
    final file = File('${root.path}/project.json');
    final source = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()),
    );
    await file.delete();
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'placeable-catalog-test',
      project: source.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        models3d: [model('bed'), model('bed_leg'), model('lamp')],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'bed_leg',
              role: ResourceLibraryRole.component,
            ),
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'lamp',
              category: ResourceUsageCategory.furniture,
            ),
          ],
        ),
      ),
    );
    session = await sessions.open(await root.resolveSymbolicLinks());
  });

  tearDown(() async {
    await sessions.close(session);
    await root.delete(recursive: true);
  });

  List<String> models(MapWorkspaceCatalog catalog) =>
      [for (final entry in catalog.metadata.models3d) entry.id]..sort();

  test('placeable loading skips component resources only', () async {
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadCatalog(session);

    final placeable = await maps.loadResourceKind(
      session,
      'model3d',
      placeableOnly: true,
    );
    final all = await maps.loadResourceKind(session, 'model3d');

    expect(models(placeable), ['bed', 'lamp']);
    expect(
      placeable.metadata.resourceLibraryCatalog
          .entryFor('model3d', 'lamp')
          ?.category,
      ResourceUsageCategory.furniture,
    );
    expect(models(all), ['bed', 'bed_leg', 'lamp']);
  });

  test(
    'an already read family is reused until the catalog is reopened',
    () async {
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadCatalog(session);
      final first = await maps.loadResourceKind(
        session,
        'model3d',
        placeableOnly: true,
      );
      final objects = Directory('${root.path}/catalog/objects');
      final aside = await objects.rename('${root.path}/catalog/objects-aside');
      addTearDown(() async {
        if (await aside.exists()) await aside.rename(objects.path);
      });

      final again = await maps.loadResourceKind(
        session,
        'model3d',
        placeableOnly: true,
      );

      expect(again.revision, first.revision);
      expect(models(again), models(first));
      await expectLater(
        maps.loadResourceKind(session, 'model3d'),
        throwsA(anything),
      );
      await aside.rename(objects.path);
      await maps.loadCatalog(session);
      await objects.rename(aside.path);
      await expectLater(
        maps.loadResourceKind(session, 'model3d', placeableOnly: true),
        throwsA(anything),
      );
    },
  );

  test('a prefetched family is ready before it is asked for', () async {
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadCatalog(session);

    await maps.prefetchResourceKind(session, 'model3d', placeableOnly: true);
    final objects = Directory('${root.path}/catalog/objects');
    final aside = await objects.rename('${root.path}/catalog/objects-aside');
    addTearDown(() async {
      if (await aside.exists()) await aside.rename(objects.path);
    });
    final loaded = await maps.loadResourceKind(
      session,
      'model3d',
      placeableOnly: true,
    );

    expect(models(loaded), ['bed', 'lamp']);
    await maps.prefetchResourceKind(session, 'smartTilePreset');
    await expectLater(
      maps.loadResourceKind(session, 'smartTilePreset'),
      throwsA(anything),
    );
  });
}
