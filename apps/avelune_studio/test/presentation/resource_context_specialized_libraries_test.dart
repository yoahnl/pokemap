import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/resources/application/environment_draft.dart';
import 'package:avelune_studio/features/resources/domain/model_resource_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_border_tool_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_environment_tool_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/resources/environment_editor_screen.dart';
import 'package:avelune_studio/presentation/features/resources/environment_library.dart';
import 'package:avelune_studio/presentation/features/resources/model_resource_library.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_library_screen.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/features/resources/resource_source_list.dart';
import 'package:avelune_studio/presentation/features/resources/resource_family_tree_view.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
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

Widget _app(Widget child) => MaterialApp(
  theme: studioTheme(),
  home: Scaffold(body: child),
);

Future<void> _context(
  WidgetTester tester,
  ResourceCatalogContext value, {
  String? count,
}) async {
  await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
  await tester.pumpAndSettle();
  tester
      .widget<StudioSelect>(
        find.byKey(const ValueKey('resource-filter-context')),
      )
      .onChanged!(value.name);
  await tester.pump();
  if (count != null) {
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('resource-filter-result-count')),
          )
          .data,
      count,
    );
  }
  await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
  await tester.pumpAndSettle();
}

void _visible(String prefix, Set<String> expected) {
  for (final id in _ids) {
    expect(
      find.byKey(ValueKey('$prefix-$id')),
      expected.contains(id) ? findsOneWidget : findsNothing,
      reason: '$prefix-$id',
    );
  }
}

void main() {
  for (final family in [
    ResourceLibraryFamily.models3d,
    ResourceLibraryFamily.environments,
    ResourceLibraryFamily.borders,
  ]) {
    testWidgets(
      '${family.name} atelier filters real rows before selection and counts',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1500, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final project = _project();
        final controller = MapWorkspaceController(
          workspaceSession,
          WorkspaceMemoryPort(),
        )..project = project;
        final navigation = ResourceNavigation(
          workspace: controller,
          port: _Models(),
          visuals: WorkspaceTestVisuals(),
          onUse: (_) {},
        );
        final state = navigation.library..selectFamily(family);
        addTearDown(() {
          navigation.dispose();
          controller.dispose();
        });
        await tester.pumpWidget(
          _app(
            ResourceLibraryScreen(
              project: project,
              visuals: WorkspaceTestVisuals(),
              state: state,
              modelLibrary: (items) =>
                  ModelResourceLibrary(navigation: navigation, items: items),
              environmentLibrary: (items) => EnvironmentLibrary(
                project: project,
                items: items,
                visuals: WorkspaceTestVisuals(),
                onEdit: (_) {},
                onDuplicate: (_) {},
                onRemove: (_) {},
                onDraw: (_) {},
              ),
              onUse: (_) {},
              onEdit: (_) {},
              onTerrain: (_) {},
              onCreateBorder: () {},
              onResumeBorder: (_) {},
              onImport: () {},
              onBack: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        final prefix = switch (family) {
          ResourceLibraryFamily.models3d => 'model-resource',
          ResourceLibraryFamily.environments => 'environment',
          _ => 'border-resource',
        };
        _visible(prefix, _ids.toSet());
        await _context(
          tester,
          ResourceCatalogContext.interior,
          count: '2 résultats',
        );
        _visible(prefix, {'interior', 'both'});
        await _context(
          tester,
          ResourceCatalogContext.exterior,
          count: '2 résultats',
        );
        _visible(prefix, {'exterior', 'both'});
        await _context(
          tester,
          ResourceCatalogContext.unspecified,
          count: '1 résultat',
        );
        _visible(prefix, {'unspecified'});
        await _context(
          tester,
          ResourceCatalogContext.all,
          count: '4 résultats',
        );
        _visible(prefix, _ids.toSet());
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'source list filters contexts and keeps the selected hidden source',
    (tester) async {
      final project = _project();
      String? picked;
      await tester.pumpWidget(
        _app(
          ResourceSourceList(
            project: project,
            visuals: WorkspaceTestVisuals(),
            items: resourceCatalog(project)
                .where((item) => item.element != null)
                .toList(),
            selectedIdentity: 'element:exterior',
            onPick: (item) => picked = item.identity,
          ),
        ),
      );
      await _context(
        tester,
        ResourceCatalogContext.interior,
        count: '2 résultats',
      );
      _visible('path-source', {'interior', 'both'});
      expect(picked, isNull);
      await tester.enterText(find.byType(TextField), 'both');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('resource-source-families')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ResourceFamilyTreeView>(find.byType(ResourceFamilyTreeView))
            .tree
            .total,
        1,
      );
      await tester.tap(find.byTooltip('Retour à la carte'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('path-source-both')));
      expect(picked, 'element:both');
      await _context(
        tester,
        ResourceCatalogContext.unspecified,
        count: '1 résultat',
      );
      _visible('path-source', {'unspecified'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'environment decor picker filters positive and negative contexts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final draft = EnvironmentDraft();
      await tester.pumpWidget(
        _app(
          EnvironmentEditorScreen(
            draft: draft,
            project: _project(),
            visuals: WorkspaceTestVisuals(),
            onSave: () async {},
            onChanged: () {},
            onClose: () {},
            onDiscard: () {},
            onEditDecor: (_) {},
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('environment-add-decor')));
      await tester.pumpAndSettle();
      await _context(
        tester,
        ResourceCatalogContext.exterior,
        count: '2 résultats',
      );
      _visible('environment-decor', {'exterior', 'both'});
      final search = find
          .descendant(
            of: find.byType(Dialog).last,
            matching: find.byType(TextField),
          )
          .first;
      await tester.enterText(search, 'both');
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('environment-decor-families')),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ResourceFamilyTreeView>(find.byType(ResourceFamilyTreeView))
            .tree
            .total,
        1,
      );
      await tester.tap(find.byTooltip('Retour à la carte'));
      await tester.pumpAndSettle();
      await tester.enterText(search, '');
      await tester.pump();
      await _context(
        tester,
        ResourceCatalogContext.unspecified,
        count: '1 résultat',
      );
      _visible('environment-decor', {'unspecified'});
      await tester.tap(
        find.byKey(const ValueKey('environment-decor-unspecified')),
      );
      await tester.pumpAndSettle();
      expect(draft.palette.single.elementId, 'unspecified');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'map environment secondary picker filters positive and negative contexts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => StudioButton(
              label: 'Choisir',
              onPressed: () =>
                  chooseEnvironmentPreset(context, _project(), mapId: 'a'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choisir'));
      await tester.pumpAndSettle();
      await _context(
        tester,
        ResourceCatalogContext.interior,
        count: '2 résultats',
      );
      _visible('environment-preset', {'interior', 'both'});
      await _context(
        tester,
        ResourceCatalogContext.unspecified,
        count: '1 résultat',
      );
      _visible('environment-preset', {'unspecified'});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'map border secondary picker hides choices while preserving the active brush',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final view = MapWorkspaceViewState()
        ..borderBlueprintId = 'exterior'
        ..tool = StudioMapTool.border;
      addTearDown(view.dispose);
      final document = EditableMapDocument(
        MapWorkspaceDocument(
          map: workspaceMap('a'),
          revision: 'r0',
          mapId: 'a',
        ),
      );
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, refresh) => MapBorderToolPanel(
              document: document,
              project: _project(),
              view: view,
              onChanged: () => refresh(() {}),
              onCreateModel: () {},
            ),
          ),
        ),
      );
      await _context(
        tester,
        ResourceCatalogContext.interior,
        count: '2 résultats',
      );
      final picker = tester.widget<DropdownButton<String>>(
        find.byKey(const ValueKey('border-model-picker')),
      );
      expect(picker.items!.map((item) => item.value), ['interior', 'both']);
      expect(view.borderBlueprintId, 'exterior');
      expect(view.tool, StudioMapTool.border);
      await _context(
        tester,
        ResourceCatalogContext.unspecified,
        count: '1 résultat',
      );
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.byKey(const ValueKey('border-model-picker')),
            )
            .items!
            .single
            .value,
        'unspecified',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _Models implements ResourcePort, ModelResourcePort {
  @override
  Future<Uint8List> readModel(String modelId) async =>
      throw StateError('Preview omitted by fixture');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
