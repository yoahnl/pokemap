import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/data/local_resource_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../../tool/create_example_project.dart';
import 'map_workspace_fixture.dart';

class ResourceMapJourneyFixture {
  ResourceMapJourneyFixture(
    this.root,
    this.session,
    this.maps,
    this.workspace,
    this.resources,
    this.navigation,
    this.view,
  );

  final Directory root;
  final ProjectSession session;
  final LocalMapWorkspaceAdapter maps;
  final MapWorkspaceController workspace;
  final LocalResourceAdapter resources;
  final ResourceNavigation navigation;
  final MapWorkspaceEditingState view;

  static Future<ResourceMapJourneyFixture> create({bool stress = false}) async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await parent.create(recursive: true);
    final temporary = await parent.createTemp('resource_map_journey_');
    final root = Directory(await temporary.resolveSymbolicLinks());
    addTearDown(() => root.delete(recursive: true));
    await writeExampleProject(root, stress: stress);
    final session = ProjectSession(
      sessionId: root.path,
      name: 'Parcours Ressources et carte',
      directoryPath: root.path,
    );
    final maps = LocalMapWorkspaceAdapter();
    final workspace = MapWorkspaceController(session, maps);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final resources = LocalResourceAdapter(session: session, mapAdapter: maps);
    addTearDown(resources.dispose);
    final visuals = WorkspaceTestVisuals();
    addTearDown(visuals.dispose);
    final view = MapWorkspaceEditingState();
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: resources,
      visuals: visuals,
      onUse: (item) {
        if (item.terrain case final preset?) {
          view.prepareTerrainPainting(preset);
        }
      },
    );
    addTearDown(navigation.dispose);
    return ResourceMapJourneyFixture(
      root,
      session,
      maps,
      workspace,
      resources,
      navigation,
      view,
    );
  }

  void paintTerrain(GridPos from, [GridPos? to]) {
    final document = workspace.active!;
    final stroke = MapCanvasStroke.start(
      map: document.current,
      project: workspace.project!,
      view: view,
      commands: MapEditingCommands(document, workspace.project!),
      origin: from,
    );
    expect(stroke, isNotNull);
    if (to != null) stroke!.paint(to);
    document.commit(stroke!.commit());
  }
}
