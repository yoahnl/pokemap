import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/resources/application/environment_draft.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_creation_sources.dart';
import 'package:avelune_studio/features/resources/application/resource_family_tree.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_catalog_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';

const _ids = ['interior', 'exterior', 'both', 'unspecified'];

ProjectManifest _project() {
  final base = spatialEnvironmentProject();
  final border = testBorderCatalog().records.single;
  return workspaceProject.copyWith(
    elements: [
      for (final id in _ids) workspaceElement.copyWith(id: id, name: id),
    ],
    models3d: [
      for (final id in _ids)
        ProjectModel3dEntry.fromJson({
          ...base.models3d.single.toJson(),
          'id': id,
          'name': id,
          'relativePath': 'assets/models3d/$id.glb',
        }),
    ],
    environmentPresets: [
      for (final id in _ids)
        EnvironmentPreset(
          id: id,
          name: id,
          templateId: 'manual',
          sortOrder: 0,
          palette: [EnvironmentPaletteItem(elementId: 'interior', weight: 1)],
          defaultParams: EnvironmentGenerationParams.standard(),
        ),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: testBorderCatalog().formatVersion,
      visualSnapshots: testBorderCatalog().visualSnapshots,
      records: [
        for (final id in _ids)
          BorderBlueprintRecord(
            id: id,
            draft: border.draft,
            latestPublished: border.latestPublished,
          ),
      ],
    ),
    resourceLibraryCatalog: ResourceLibraryCatalog(
      entries: [
        for (final kind in [
          'element',
          'model3d',
          'environmentPreset',
          'borderBlueprint',
        ])
          for (final value in ResourcePlacementContext.values)
            ResourceLibraryEntry(
              resourceKind: kind,
              resourceId: value.name,
              placementContext: value,
            ),
      ],
    ),
  );
}

void main() {
  for (final family in [
    ResourceLibraryFamily.models3d,
    ResourceLibraryFamily.environments,
    ResourceLibraryFamily.borders,
  ]) {
    test(
      '${family.name} atelier filters real rows before selection and counts',
      () {
        final project = _project();
        final state = ResourceLibraryState()..selectFamily(family);
        final items = resourceCatalog(project)
            .where(state.includesFamily)
            .toList();
        List<ResourceItem> visible() =>
            filterResourceCatalog(project, items, state.filters);
        expect(visible().map((item) => item.id), unorderedEquals(_ids));
        for (final (context, ids) in [
          (ResourceCatalogContext.interior, ['interior', 'both']),
          (ResourceCatalogContext.exterior, ['exterior', 'both']),
          (ResourceCatalogContext.unspecified, ['unspecified']),
          (ResourceCatalogContext.all, _ids),
        ]) {
          state.filters.context = context;
          final filtered = visible();
          expect(filtered.map((item) => item.id), unorderedEquals(ids));
          expect(
            ResourceFamilyTree(project, items, filters: state.filters).total,
            ids.length,
          );
          expect(ids, contains(state.reconcileSelection(filtered)!.id));
        }
      },
    );
  }

  test('source filtering preserves the hidden catalogue resource and selects an explicit visible result', () {
    final project = _project();
    final before = project.toJson();
    final items = resourceCatalog(project)
        .where((item) => item.element != null)
        .toList();
    final state = ResourceLibraryState()
      ..select(items.firstWhere((item) => item.id == 'exterior'));
    final filters = ResourceCatalogFilterState(
      showComponents: true,
      context: ResourceCatalogContext.interior,
    );
    List<ResourceItem> visible() =>
        filterResourceCatalog(project, items, filters);
    expect(visible().map((item) => item.id), ['interior', 'both']);
    expect(state.selectedIdentity, 'element:exterior');
    expect(
      items.firstWhere((item) => item.id == 'exterior').element,
      isNotNull,
    );
    filters.query = 'both';
    expect(ResourceFamilyTree(project, items, filters: filters).total, 1);
    state.select(visible().single);
    expect(state.selectedIdentity, 'element:both');
    filters.query = '';
    filters.context = ResourceCatalogContext.unspecified;
    expect(visible().single.id, 'unspecified');
    expect(state.selectedIdentity, 'element:both');
    expect(project.toJson(), before);
  });

  test('environment decor candidates filter positive and negative contexts before adding to the draft', () {
    final project = _project();
    final draft = EnvironmentDraft();
    final candidates = environmentPaletteCandidates(project);
    final filters = ResourceCatalogFilterState(
      showComponents: true,
      context: ResourceCatalogContext.exterior,
    );
    List<ResourceItem> visible() =>
        filterResourceCatalog(project, candidates, filters, forMapPicker: true);
    expect(visible().map((item) => item.id), ['exterior', 'both']);
    filters.query = 'both';
    expect(
      ResourceFamilyTree(
        project,
        candidates,
        filters: filters,
        forMapPicker: true,
      ).total,
      1,
    );
    filters.query = '';
    filters.context = ResourceCatalogContext.unspecified;
    final selected = visible().single;
    expect(selected.id, 'unspecified');
    draft.add(selected.id, spatial: selected.model3d != null);
    expect(draft.palette.single.elementId, 'unspecified');
    expect(
      environmentPaletteCandidates(
        project,
        excluded: {selected.identity},
      ).any((item) => item.identity == selected.identity),
      isFalse,
    );
  });

  test(
    'map environment secondary choices filter positive and negative contexts',
    () {
      final project = _project();
      final view = MapWorkspaceEditingState();
      view.resourceFilters.context = ResourceCatalogContext.interior;
      expect(
        view
            .paletteResourcesFor(project, 'a', 'Environnements')
            .map((item) => item.id),
        ['interior', 'both'],
      );
      view.resourceFilters.context = ResourceCatalogContext.unspecified;
      expect(
        view.paletteResourcesFor(project, 'a', 'Environnements').single.id,
        'unspecified',
      );
    },
  );

  test('map border secondary choices preserve a hidden active brush', () {
    final project = _project();
    final view = MapWorkspaceEditingState()
      ..borderBlueprintId = 'exterior'
      ..tool = StudioMapTool.border;
    view.resourceFilters.context = ResourceCatalogContext.interior;
    expect(
      view.paletteResourcesFor(project, 'a', 'Bordures').map((item) => item.id),
      ['interior', 'both'],
    );
    expect(view.borderBlueprintId, 'exterior');
    expect(view.tool, StudioMapTool.border);
    view.resourceFilters.context = ResourceCatalogContext.unspecified;
    expect(
      view.paletteResourcesFor(project, 'a', 'Bordures').single.id,
      'unspecified',
    );
    expect(view.borderBlueprintId, 'exterior');
    expect(view.tool, StudioMapTool.border);
  });
}
