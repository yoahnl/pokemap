import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/resources/application/environment_draft.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

class _Resources extends Fake implements ResourcePort {}

const _element = ResourceItem(
  id: 'tree',
  name: 'Arbre',
  kind: ResourceKind.decors,
  element: workspaceElement,
);

void main() {
  late WorkspaceMemoryPort port;
  late MapWorkspaceController workspace;
  late MapWorkspaceEditingState view;
  late ResourceNavigation resources;
  setUp(() async {
    port = WorkspaceMemoryPort();
    workspace = MapWorkspaceController(workspaceSession, port);
    await workspace.initialize();
    view = MapWorkspaceEditingState();
    resources = ResourceNavigation(
      workspace: workspace,
      port: _Resources(),
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
    );
  });
  tearDown(() {
    resources.dispose();
    workspace.dispose();
  });

  Future<bool> use(
    ResourceItem item, {
    Future<ProjectMapEntry?> Function(List<ProjectMapEntry>)? chooseMap,
    Future<TileLayerPaletteEntry?> Function(ProjectTilesetEntry)? chooseTile,
  }) => useMapResource(
    workspace: workspace,
    item: item,
    view: () => view,
    isActive: () => true,
    chooseMap: chooseMap ?? (_) async => null,
    chooseTile: chooseTile ?? (_) async => null,
  );

  test(
    'arming a decor changes only the brush and preserves document history',
    () async {
      final before = workspace.active!.current;
      final steps = workspace.active!.undoCount;
      view.tile = const TileLayerPaletteEntry(
        tilesetId: 'atlas',
        localTileId: 0,
      );
      expect(await use(_element), isTrue);
      expect(view.brush, workspaceElement);
      expect(view.tile, isNull);
      expect(view.tool, StudioMapTool.place);
      expect(workspace.active!.current, same(before));
      expect(workspace.active!.undoCount, steps);
      expect(port.writes, 0);
    },
  );

  test('map choice contains only maps that can use the resource', () async {
    workspace.project = workspaceProject.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: 'tree',
            mapId: 'b',
          ),
        ],
      ),
    );
    workspace.active = null;
    final offered = <String>[];
    expect(
      await use(
        _element,
        chooseMap: (entries) async {
          offered.addAll(entries.map((entry) => entry.id));
          return entries.single;
        },
      ),
      isTrue,
    );
    expect(offered, ['b']);
    expect(workspace.active!.current.id, 'b');
    expect(view.brush, workspaceElement);
  });

  test(
    'a scoped resource cannot arm an already active map from another scope',
    () async {
      workspace.project = workspaceProject.copyWith(
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: 'tree',
              mapId: 'b',
            ),
          ],
        ),
      );
      expect(await use(_element), isFalse);
      expect(view.brush, isNull);
      expect(view.tool, StudioMapTool.select);
    },
  );

  test('cancelling map choice keeps the workspace inactive', () async {
    workspace.active = null;
    expect(await use(_element), isFalse);
    expect(workspace.active, isNull);
    expect(view.brush, isNull);
  });

  test('a tile result is ignored when another map becomes active', () async {
    final tile = Completer<TileLayerPaletteEntry?>();
    final item = ResourceItem(
      id: 'atlas',
      name: 'Atlas',
      kind: ResourceKind.images,
      tileset: workspaceProject.tilesets.single,
    );
    final selecting = use(item, chooseTile: (_) => tile.future);
    await workspace.activate(workspaceEntries.last);
    tile.complete(
      const TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0),
    );
    expect(await selecting, isFalse);
    expect(view.tile, isNull);
    expect(view.tool, StudioMapTool.select);
  });

  test('a selected tile arms the native paint tool', () async {
    const tile = TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 0);
    final item = ResourceItem(
      id: 'atlas',
      name: 'Atlas',
      kind: ResourceKind.images,
      tileset: workspaceProject.tilesets.single,
    );
    view.brush = workspaceElement;
    expect(await use(item, chooseTile: (_) async => tile), isTrue);
    expect(view.tile, tile);
    expect(view.brush, isNull);
    expect(view.tool, StudioMapTool.paint);
  });

  test(
    'an unsaved environment is refused before creating its map zone',
    () async {
      final preset = EnvironmentPreset(
        id: 'garden',
        name: 'Jardin',
        templateId: 'manual',
        sortOrder: 0,
        palette: [EnvironmentPaletteItem(elementId: 'tree', weight: 1)],
        defaultParams: EnvironmentGenerationParams.standard(),
      );
      workspace.project = workspaceProject.copyWith(
        environmentPresets: [preset],
      );
      resources.environments[preset.id] = EnvironmentDraft(original: preset)
        ..name = 'Brouillon';
      final before = workspace.active!.current;
      final steps = workspace.active!.undoCount;
      Future<bool> draw() => useMapEnvironment(
        workspace: workspace,
        resources: resources,
        preset: preset,
        view: () => view,
        isActive: () => true,
        chooseMap: (_) async => null,
      );
      expect(await draw(), isFalse);
      expect(resources.error, contains('Enregistrez'));
      expect(workspace.active!.current, same(before));
      expect(workspace.active!.undoCount, steps);
      resources.environments.clear();
      expect(await draw(), isTrue);
      expect(view.environment, isNotNull);
      expect(view.tool, StudioMapTool.environment);
      expect(workspace.active!.undoCount, steps + 1);
      expect(port.writes, 0);
    },
  );
}
