import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_relief_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../map_workspace/map_relief_fixture.dart';
import 'map_relief_catalog_fixture.dart';

void main() {
  late Directory root;
  late LocalProjectSessionAdapter sessions;
  late ProjectSession session;
  late MapWorkspaceController workspace;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('studio_relief_flow_');
    sessions = LocalProjectSessionAdapter();
    await writeReliefCatalogProject(root);
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
    expect(profiles.map((profile) => profile.id), ['fence', 'berge']);
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
      expect(outcome.profileName, 'Talus — angles courts');
      expect(outcome.diagnostics, ['border.spatial.face_base_mismatch']);
      expect(workspace.active!.current, same(before));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
