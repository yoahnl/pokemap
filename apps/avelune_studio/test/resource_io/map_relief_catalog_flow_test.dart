import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_relief_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';
import '../map_workspace/map_relief_fixture.dart';

void main() {
  late Directory root;
  late LocalProjectSessionAdapter sessions;
  late ProjectSession session;
  late MapWorkspaceController workspace;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('studio_relief_flow_');
    sessions = LocalProjectSessionAdapter();
    await writeExampleProject(root);
    for (final id in ['jardin', 'clairiere']) {
      final file = File('${root.path}/maps/$id.json');
      final map = MapData.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      await file.writeAsString(
        jsonEncode(
          reliefToolMap().copyWith(id: map.id, name: map.name).toJson(),
        ),
      );
    }
    final file = File('${root.path}/project.json');
    final source = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    await file.delete();
    final relief = reliefToolProject();
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'relief-flow-test',
      project: source.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        models3d: [...relief.models3d, _bank(relief.models3d.single)],
        borderCatalog: ProjectBorderCatalog(
          formatVersion: relief.borderCatalog.formatVersion,
          records: [
            relief.borderCatalog.records.single,
            _berge(relief.borderCatalog),
          ],
        ),
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'borderBlueprint',
              resourceId: 'fence',
              familyId: 'relief',
              category: ResourceUsageCategory.relief,
            ),
          ],
        ),
      ),
    );
    session = await sessions.open(await root.resolveSymbolicLinks());
    expect(session.storage, ProjectSessionStorage.workingCatalog);
    workspace = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
    await workspace.initialize();
    expect(workspace.error, isNull);
  });

  tearDown(() async {
    workspace.dispose();
    await sessions.close(session);
    await root.delete(recursive: true);
  });

  Future<MapReliefToolState> openReliefTool() async {
    await workspace.activate(
      workspace.project!.maps.singleWhere((entry) => entry.id == 'clairiere'),
    );
    final binding = MapBuilderResourceBinding(
      maps: workspace,
      view: MapWorkspaceEditingState.new,
      visuals: () => null,
      isActive: () => true,
      changed: () {},
    );
    await binding.load();
    await binding.select(
      binding.selection.copyWith(category: ResourceUsageCategory.relief),
    );
    final state = MapReliefToolState();
    await workspace.ensureResourceKind('borderBlueprint', placeableOnly: true);
    final profiles = state.profiles(
      workspace.project!,
      workspace.active!.current,
    );
    expect(profiles.map((profile) => profile.id), ['berge', 'fence']);
    final chosen = mapReliefDefaultProfile(profiles)!;
    state.profileId = chosen.id;
    await workspace.ensureBorderBlueprint(chosen.id);
    return state;
  }

  MapReliefOutcome paint(MapReliefToolState state) {
    final document = workspace.active!;
    return MapReliefCommands(document, workspace.project!).apply(
      MapReliefStroke(
        source: document.current,
        origin: const GridPos(x: 3, y: 3),
        level: 2,
        rectangle: true,
      )..paint(const GridPos(x: 7, y: 4)),
      state,
    );
  }

  test(
    'the relief tool opened like the Studio paints with its default style',
    () async {
      final state = await openReliefTool();
      final outcome = paint(state);

      expect(outcome.problem, isNull);
      expect(state.profileId, 'fence');
      expect(reliefFeatures(workspace.active!.current), ['relief-1']);
      expect(
        workspace.active!.current.spatialScene!.worldHeightAt(5.5, 3.5),
        2,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a style that cannot follow the step names itself and the reason',
    () async {
      final state = await openReliefTool();
      state.profileId = 'berge';
      await workspace.ensureBorderBlueprint('berge');
      final before = workspace.active!.current;
      final outcome = paint(state);

      expect(outcome.problem, MapReliefProblem.profileIncompatible);
      expect(outcome.profileName, 'Berge — angles courts');
      expect(outcome.diagnostics, ['border.spatial.face_base_mismatch']);
      expect(workspace.active!.current, same(before));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

ProjectModel3dEntry _bank(ProjectModel3dEntry face) => ProjectModel3dEntry(
  id: 'bank',
  name: 'Berge basse',
  sourceAssetId: 'bank-source',
  relativePath: 'assets/models3d/bank.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3(
        x: face.inspection.bounds.min.x,
        y: -.6,
        z: face.inspection.bounds.min.z,
      ),
      max: face.inspection.bounds.max,
    ),
    meshCount: 1,
    triangleCount: 1,
  ),
);

BorderBlueprintRecord _berge(ProjectBorderCatalog catalog) {
  final raw = encodeBorderBlueprintRecordJson(
    catalog.records.single,
    formatVersion: catalog.formatVersion,
  );
  raw['id'] = 'berge';
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    definition['name'] = 'Berge — angles courts';
    for (final primitive in (definition['primitives'] as List).cast<Map>()) {
      primitive['sourceModelId'] = 'bank';
    }
  }
  return decodeBorderBlueprintRecordJson(
    raw,
    formatVersion: catalog.formatVersion,
  );
}
