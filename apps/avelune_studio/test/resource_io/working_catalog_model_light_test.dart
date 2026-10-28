import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/resources/data/local_working_catalog_adapter.dart';

import '../../tool/create_example_project.dart';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';

void main() {
  test('native catalog light save preserves preview identity, other data, conflicts and reopen', () async {
    final root = await Directory.systemTemp.createTemp('studio_light_catalog_');
    final sessions = LocalProjectSessionAdapter();
    await writeExampleProject(root);
    final file = File('${root.path}/project.json');
    final source = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()),
    );
    await file.delete();
    final lamp = ProjectModel3dEntry(
      id: 'lamp',
      name: 'Lamp',
      sourceAssetId: 'model3d_lamp',
      relativePath: 'assets/models3d/lamp.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 3, z: 1),
        ),
        meshCount: 1,
        triangleCount: 4,
      ),
    );
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'light-catalog-test',
      project: source.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        models3d: [lamp],
      ),
    );
    final session = await sessions.open(await root.resolveSymbolicLinks());
    final adapter = LocalWorkingCatalogAdapter(session);
    final maps = LocalMapWorkspaceAdapter();
    await maps.loadCatalog(session);
    addTearDown(() async {
      await adapter.close();
      await sessions.close(session);
      await root.delete(recursive: true);
    });
    final page = await adapter.query(kind: 'model3d', text: '');
    final before = await adapter.open(page.items.single);
    final descriptor = await file.readAsBytes();
    final light = Model3dPointLight(
      localPosition: Model3dVector3(x: 0, y: 2.25, z: 0),
      colorCycle: ModelLightColorCycle(
        colors: [0xbddfff, 0xf2c8e5],
        periodSeconds: 12,
      ),
      proximity: ModelLightProximity(mode: ModelLightProximityMode.near),
      flame: ModelLightFlame(height: .3, flicker: .1, style: ModelLightFlameStyle.brazier, embers: .75, crackleVolume: .65),
    );
    final saved = await adapter.configureLight(
      before.entry,
      light,
      revision: before.revision,
    );
    await maps.acceptModelLight(
      session,
      saved.definitions.models3d.single,
      saved.previousDocumentRevision!,
      saved.documentRevision!,
    );
    final baseline = await maps.resourceBaseline(session);
    expect(baseline.revision, saved.documentRevision);
    await maps.loadResourceKind(session, 'model3d');
    expect(saved.visualIdentity, same(before.visualIdentity));
    expect(saved.definitions.models3d.single.light, light);
    expect(await file.readAsBytes(), descriptor);
    await expectLater(
      adapter.configureLight(before.entry, null, revision: before.revision),
      throwsStateError,
    );
    final reopened = await adapter.open(page.items.single);
    expect(reopened.definitions.models3d.single.light, light);
    expect(reopened.revision, saved.revision);
    final disabled = await adapter.configureLight(
      reopened.entry,
      null,
      revision: reopened.revision,
    );
    expect(disabled.definitions.models3d.single.light, isNull);
    final restored = await adapter.configureLight(
      disabled.entry,
      light,
      revision: disabled.revision,
    );
    expect(restored.definitions.models3d.single.light, light);
  });
}
