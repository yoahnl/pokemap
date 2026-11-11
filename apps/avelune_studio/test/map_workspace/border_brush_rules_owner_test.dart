import 'package:avelune_studio/features/map_workspace/application/map_border_drawing_draft.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_catalog_fixture.dart';
import '../support/map_workspace_fixture.dart';

ProjectManifest _project({bool deprecated = false, bool published = true}) {
  final catalog = testBorderCatalog();
  final record = catalog.records.single;
  return workspaceProject.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: catalog.formatVersion,
      records: [
        BorderBlueprintRecord(
          id: record.id,
          draft: record.draft,
          latestPublished: published ? record.latestPublished : null,
          isDeprecated: deprecated,
        ),
      ],
      visualSnapshots: catalog.visualSnapshots,
    ),
  );
}

MapBorderDrawingDraft _draft(String mapId) => MapBorderDrawingDraft.start(
  mapId: mapId,
  mapSize: const GridSize(width: 20, height: 15),
  blueprintId: 'muret',
  origin: const GridPos(x: 2, y: 3),
).addAngle(const GridPos(x: 6, y: 3));

MapWorkspaceEditingState _armed(ProjectManifest project) {
  final view = MapWorkspaceEditingState()
    ..borderBlueprintId = 'muret'
    ..tool = StudioMapTool.border;
  view.reconcileResources(project, mapId: 'a');
  return view;
}

void main() {
  test('a published border stays armed on the brush', () {
    final view = _armed(_project());
    expect(view.borderBlueprintId, 'muret');
    expect(view.tool, StudioMapTool.border);
  });

  test('a deprecated border is removed from the brush', () {
    final view = _armed(_project());
    view.borderDraft = _draft('a');
    view.reconcileResources(_project(deprecated: true), mapId: 'a');
    expect(view.borderBlueprintId, isNull);
    expect(view.borderDraft, isNull);
    expect(view.tool, StudioMapTool.select);
  });

  test('an unpublished border is removed from the brush', () {
    final view = _armed(_project());
    view.reconcileResources(_project(published: false), mapId: 'a');
    expect(view.borderBlueprintId, isNull);
    expect(view.tool, StudioMapTool.select);
  });

  test('a border draft is kept per map and restored on return', () {
    final project = _project();
    final view = _armed(project);
    final draft = _draft('a');
    view.borderDraft = draft;
    view.reconcileResources(project, mapId: 'b');
    expect(view.borderDraft, isNull);
    expect(view.retainedBorderDraftFor('a'), same(draft));
    view.borderBlueprintId = null;
    view.reconcileResources(project, mapId: 'a');
    expect(view.borderDraft, same(draft));
    expect(view.borderBlueprintId, 'muret');
    expect(view.retainedBorderDraftFor('a'), isNull);
  });

  test('a viewport focusing another map parks the draft instead of dropping it', () {
    final view = _armed(_project());
    final draft = _draft('a');
    view.borderDraft = draft;
    view.focusBorderDraftOn('b');
    expect(view.borderDraft, isNull);
    view.focusBorderDraftOn('a');
    expect(view.borderDraft, same(draft));
  });

  test('a parked draft is dropped when its map or its border disappears', () {
    final project = _project();
    final view = _armed(project);
    view.borderDraft = _draft('a');
    view.reconcileResources(project, mapId: 'b');
    view.reconcileResources(
      project.copyWith(maps: [workspaceEntries.last]),
      mapId: 'b',
    );
    expect(view.retainedBorderDraftFor('a'), isNull);

    final second = _armed(project);
    second.borderDraft = _draft('a');
    second.reconcileResources(project, mapId: 'b');
    second.reconcileResources(_project(deprecated: true), mapId: 'b');
    expect(second.retainedBorderDraftFor('a'), isNull);
  });
}
