import 'dart:async';

import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/map_workspace/application/environment_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_category.dart';
import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_panel.dart';

ResourceCatalogContext mapBuilderDefaultContext(MapRole? role) =>
    switch (role) {
      MapRole.exterior || MapRole.sub_area => ResourceCatalogContext.exterior,
      MapRole.interior ||
      MapRole.basement ||
      MapRole.upper_floor ||
      MapRole.room => ResourceCatalogContext.interior,
      _ => ResourceCatalogContext.all,
    };

ProjectManifest? mapBuilderCatalog(
  ProjectManifest? visual,
  ProjectManifest? project,
) {
  if (visual == null || project == null) return visual ?? project;
  if (identical(
    visual.resourceLibraryCatalog,
    project.resourceLibraryCatalog,
  )) {
    return visual;
  }
  return visual.copyWith(
    resourceLibraryCatalog: project.resourceLibraryCatalog,
  );
}

enum MapBuilderResourceProblem { loadFailed, tileUnavailable }

class MapBuilderResourceBinding {
  MapBuilderResourceBinding({
    required this.maps,
    required this.view,
    required this.visuals,
    required this.isActive,
    required this.changed,
  });

  final MapWorkspaceController maps;
  final MapWorkspaceEditingState? Function() view;
  final MapWorkspaceVisuals? Function() visuals;
  final bool Function() isActive;
  final void Function() changed;
  var selection = const MapBuilderResourceSelection(
    category: ResourceUsageCategory.ground,
    scope: ResourceCatalogScope.all,
    context: ResourceCatalogContext.all,
    query: '',
  );
  String? _contextMapId;
  var loading = false;
  String? error;
  MapBuilderResourceProblem? problem;
  Object? problemCause;
  ResourceItem? armed;
  var _request = 0;

  ProjectManifest? _visualSource, _librarySource, _catalog;

  ProjectManifest? get catalog {
    final visual = maps.visualProject;
    final project = maps.project;
    if (!identical(visual, _visualSource) ||
        !identical(project, _librarySource)) {
      _visualSource = visual;
      _librarySource = project;
      _catalog = mapBuilderCatalog(visual, project);
    }
    return _catalog;
  }

  void follow(ProjectMapEntry? entry) {
    if (entry == null || entry.id == _contextMapId) return;
    _contextMapId = entry.id;
    selection = selection.copyWith(
      context: mapBuilderDefaultContext(entry.role),
    );
    final tool = view()?.tool;
    if (tool == null ||
        tool == StudioMapTool.select ||
        tool == StudioMapTool.pan) {
      armed = null;
    }
  }

  Future<void> select(MapBuilderResourceSelection value) async {
    final kindChanged = value.category != selection.category;
    selection = value;
    changed();
    if (kindChanged || !maps.hasResourceKind(_kind, placeableOnly: true)) {
      await load();
    }
  }

  String get _kind => selection.category.loadedKind(
    maps.project?.settings.dimension ?? ProjectDimension.twoD,
  );

  Future<void> load() async {
    final request = ++_request;
    loading = !maps.hasResourceKind(_kind, placeableOnly: true);
    error = null;
    problem = null;
    changed();
    try {
      await maps.ensureResourceKind(_kind, placeableOnly: true);
      if (isActive()) unawaited(_prefetchOthers());
    } catch (failure) {
      if (isActive() && request == _request) {
        problem = MapBuilderResourceProblem.loadFailed;
        problemCause = failure;
      }
    } finally {
      if (isActive() && request == _request) {
        loading = false;
        changed();
      }
    }
  }

  Future<void> _prefetchOthers() {
    final dimension = maps.project?.settings.dimension ?? ProjectDimension.twoD;
    final current = _kind;
    return maps.prefetchResourceKinds({
      for (final category in ResourceUsageCategory.values)
        if (category.loadedKind(dimension) != current)
          category.loadedKind(dimension),
    }, placeableOnly: true);
  }

  Future<void> use(ResourceItem item) async {
    final state = view();
    final document = maps.active;
    final project = maps.project;
    if (state == null || document == null || project == null) return;
    error = null;
    problem = null;
    var used = false;
    if (item.environment case final preset?) {
      try {
        state.selectEnvironmentPreset(document, project, preset);
        used = true;
      } on Object catch (failure) {
        error = environmentEditingMessage(failure);
      }
    } else if (item.tileset != null) {
      problem = MapBuilderResourceProblem.tileUnavailable;
    } else if (await _resolve(item)) {
      used = await useMapResource(
        workspace: maps,
        item: item,
        view: view,
        isActive: isActive,
        chooseMap: (_) async => null,
        chooseTile: (_) async => null,
      );
    }
    if (!isActive()) return;
    if (used) {
      armed = item;
      retainWorkspaceBrush(visuals(), state);
    }
    changed();
  }

  Future<bool> _resolve(ResourceItem item) async {
    final kind = item.canonicalKind;
    if (maps.hasResourceClosure(kind, item.id)) return true;
    try {
      await maps.ensureResourceClosure(kind, item.id);
      return true;
    } catch (failure) {
      problem = MapBuilderResourceProblem.loadFailed;
      problemCause = failure;
      return false;
    }
  }

  void release() {
    armed = null;
    final state = view();
    if (state != null) {
      state
        ..brush = null
        ..model3d = null
        ..terrain = null
        ..tile = null
        ..borderBlueprintId = null
        ..tool = StudioMapTool.select;
      retainWorkspaceBrush(visuals(), state);
    }
    changed();
  }

  void reconcileTool() {
    final tool = view()?.tool;
    if (armed != null &&
        (tool == null ||
            tool == StudioMapTool.select ||
            tool == StudioMapTool.pan)) {
      armed = null;
    }
  }
}
