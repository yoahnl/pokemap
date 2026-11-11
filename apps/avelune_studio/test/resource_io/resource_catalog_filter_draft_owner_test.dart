import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

ProjectManifest _contextProject() => workspaceProject.copyWith(
  tilesets: [],
  elements: [
    workspaceElement.copyWith(id: 'inside'),
    workspaceElement.copyWith(id: 'outside'),
  ],
  resourceLibraryCatalog: ResourceLibraryCatalog(
    entries: [
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'inside',
        placementContext: ResourcePlacementContext.interior,
      ),
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'outside',
        placementContext: ResourcePlacementContext.exterior,
      ),
    ],
  ),
);

int _count(ProjectManifest project, ResourceCatalogFilterState filters) =>
    filterResourceCatalog(project, resourceCatalog(project), filters).length;

void main() {
  test('context draft counts apply cancel reset tag and keyboard in a small window', () {
    final project = _contextProject();
    final filters = ResourceCatalogFilterState();
    var draft = filters.copy();
    expect(_count(project, draft), 2);
    draft.context = ResourceCatalogContext.interior;
    expect(_count(project, draft), 1);
    expect(filters.context, ResourceCatalogContext.all);
    expect(filters.activeFilterCount(), 0);

    draft = filters.copy();
    draft.context = ResourceCatalogContext.exterior;
    expect(filters.context, ResourceCatalogContext.all);

    draft = filters.copy();
    draft.context = ResourceCatalogContext.unspecified;
    expect(_count(project, draft), 0);
    filters.applyDraft(draft);
    expect(filters.context, ResourceCatalogContext.unspecified);
    expect(filters.activeFilterCount(), 1);

    draft = filters.copy();
    draft.resetDraftFields();
    expect(_count(project, draft), 2);
    expect(filters.context, ResourceCatalogContext.unspecified);
    filters.applyDraft(draft);
    expect(filters.context, ResourceCatalogContext.all);
    expect(filters.activeFilterCount(), 0);
  });

  test('components draft counts apply cancel reset and removable tag', () {
    final project = workspaceProject.copyWith(
      elements: [
        workspaceElement,
        workspaceElement.copyWith(id: 'component', name: 'Phase source'),
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: 'component',
            role: ResourceLibraryRole.component,
          ),
        ],
      ),
    );
    final filters = ResourceCatalogFilterState();
    var draft = filters.copy();
    expect(_count(project, draft), 2);
    draft.showComponents = true;
    expect(_count(project, draft), 3);
    expect(filters.showComponents, isFalse);
    expect(_count(project, filters), 2);

    draft = filters.copy();
    draft.showComponents = true;
    filters.applyDraft(draft);
    expect(filters.showComponents, isTrue);
    expect(_count(project, filters), 3);
    expect(filters.activeFilterCount(), 1);

    filters.showComponents = false;
    expect(filters.activeFilterCount(), 0);

    filters.showComponents = true;
    filters.query = 'absent';
    draft = filters.copy();
    expect(_count(project, draft), 0);
    draft.resetDraftFields();
    expect(_count(project, draft), 0);
    expect(filters.showComponents, isTrue);
    filters.applyDraft(draft);
    expect(filters.showComponents, isFalse);
    expect(filters.query, 'absent');
  });

  test('filter draft cancels applies resets and tags remove one filter', () {
    final filters = ResourceCatalogFilterState(query: 'chêne');
    var draft = filters.copy();
    draft.scope = ResourceCatalogScope.map;
    draft.usage = ResourceCatalogUsage.place;
    expect(filters.scope, ResourceCatalogScope.all);
    expect(filters.usage, ResourceCatalogUsage.all);

    draft = filters.copy();
    draft.scope = ResourceCatalogScope.map;
    draft.usage = ResourceCatalogUsage.place;
    filters.applyDraft(draft);
    expect(filters.scope, ResourceCatalogScope.map);
    expect(filters.usage, ResourceCatalogUsage.place);
    expect(filters.activeFilterCount(), 2);
    expect(filters.activeFilterCount(forMapPicker: true), 1);

    filters.usage = ResourceCatalogUsage.all;
    expect(filters.scope, ResourceCatalogScope.map);
    expect(filters.query, 'chêne');

    draft = filters.copy();
    draft.resetDraftFields();
    expect(filters.scope, ResourceCatalogScope.map);
    filters.applyDraft(draft);
    expect(filters.scope, ResourceCatalogScope.all);
    expect(filters.query, 'chêne');
  });

  test('applying a draft only copies the type when the type filter is shown', () {
    final filters = ResourceCatalogFilterState(
      familyId: 'famille',
      usableOnly: true,
    );
    final draft = filters.copy()..typeKind = 'element';
    filters.applyDraft(draft);
    expect(filters.typeKind, isEmpty);
    expect(filters.activeFilterCount(showType: true), 0);
    filters.applyDraft(draft, showType: true);
    expect(filters.typeKind, 'element');
    expect(filters.activeFilterCount(showType: true), 1);
    expect(filters.activeFilterCount(), 0);
    expect(filters.activeFilterCount(categorySelected: true), 1);
    filters.resetDraftFields();
    expect(filters.typeKind, isEmpty);
    expect(filters.familyId, 'famille');
    expect(filters.usableOnly, isTrue);
  });
}
