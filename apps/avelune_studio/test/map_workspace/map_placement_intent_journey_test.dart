import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_generated_owner.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_intent_status_chip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_palette_intent.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_harness.dart';
import '../support/map_workspace_fixture.dart';

MapData _withForest(MapData map, List<String> generated) => map.copyWith(
  layers: [
    ...map.layers,
    MapLayer.environment(
      id: 'forest',
      name: 'Forêt',
      content: EnvironmentLayerContent(
        areas: [
          EnvironmentArea(
            id: 'north',
            name: 'Bois du nord',
            presetId: 'woodland',
            mask: EnvironmentAreaMask(
              width: map.size.width,
              height: map.size.height,
              cells: List.filled(map.size.width * map.size.height, true),
            ),
            seed: 7,
            generatedPlacementIds: generated,
          ),
        ],
      ),
    ),
  ],
);

void main() {
  test('the active intent names the edited target before placing', () {
    final view = MapWorkspaceViewState()..tool = StudioMapTool.place;
    expect(mapPaletteIntent(view).target, isNull);
    expect(
      mapPaletteIntent(view, editingExterior: false).target,
      'Zone jouable',
    );
    final exterior = mapPaletteIntent(view, editingExterior: true);
    expect(exterior.target, 'Décor extérieur');
    expect(exterior.action, 'Placement de décor');
    expect(exterior.armed, isFalse);
  });

  testWidgets('the intent chip reads the target first', (tester) async {
    final view = MapWorkspaceViewState()..tool = StudioMapTool.place;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: MapIntentStatusChip(
            intent: mapPaletteIntent(view, editingExterior: true),
          ),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp('^Décor extérieur · Placement de décor')),
      findsOneWidget,
    );
  });

  test('two placements keep two identities and the first survives', () {
    final h = MapSelectionHarness.of(workspaceProject);
    addTearDown(h.dispose);
    final commands = MapEditingCommands(h.document, h.project);
    final first = commands.place(workspaceElement, const GridPos(x: 1, y: 1));
    final second = commands.place(workspaceElement, const GridPos(x: 3, y: 1));
    expect(first, isNotNull);
    expect(second, isNotNull);
    expect(first, isNot(second));
    h.view.tool = StudioMapTool.select;
    final ids = h.document.current.placedElements.map((e) => e.id).toSet();
    expect(ids, containsAll([first, second]));
    expect(
      h.document.current.placedElements
          .where((element) => element.id == first)
          .single
          .elementId,
      workspaceElement.id,
    );
  });

  testWidgets('a generated decor names its zone and opens it', (tester) async {
    final h = MapSelectionHarness.of(workspaceProject);
    addTearDown(h.dispose);
    final commands = MapEditingCommands(h.document, h.project);
    final tree = commands.place(workspaceElement, const GridPos(x: 2, y: 2))!;
    final manual = commands.place(workspaceElement, const GridPos(x: 4, y: 2))!;
    h.document.commit(_withForest(h.document.current, [tree]));

    expect(mapGeneratedOwner(h.document.current, h.project, manual), isNull);
    final owner = mapGeneratedOwner(h.document.current, h.project, tree)!;
    expect(owner.areaName, 'Bois du nord');
    expect(owner.areaId, 'north');

    var changed = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: MapGeneratedOwnerNotice(
            owner: owner,
            view: h.view,
            onChanged: () => changed++,
          ),
        ),
      ),
    );
    expect(find.textContaining('« Bois du nord »'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('generated-owner-open')));
    await tester.pump();
    expect(changed, 1);
    expect(h.view.tool, StudioMapTool.environment);
    expect(h.view.paletteTab, 'Environnements');
    expect(h.view.environment?.areaId, 'north');
    expect(h.view.environment?.layerId, 'forest');
    expect(
      h.document.current.placedElements.map((e) => e.id),
      containsAll([tree, manual]),
    );
  });

  test('a zone summary names its resource, distribution and owned decors', () {
    final h = MapSelectionHarness.of(workspaceProject);
    addTearDown(h.dispose);
    final map = _withForest(h.document.current, ['a', 'b']);
    final area = map.layers
        .whereType<EnvironmentLayer>()
        .single
        .content
        .areas
        .single;
    expect(
      mapEnvironmentAreaSummary(area, h.project),
      contains('Ressource introuvable'),
    );
    final preset = EnvironmentPreset(
      id: 'woodland',
      name: 'Bois clair',
      templateId: 'forest',
      palette: [
        EnvironmentPaletteItem(elementId: workspaceElement.id, weight: 1),
      ],
      defaultParams: EnvironmentGenerationParams(
        density: .4,
        variation: .2,
        edgeDensity: .1,
        minSpacingCells: 2,
      ),
      sortOrder: 0,
    );
    final summary = mapEnvironmentAreaSummary(
      area,
      h.project.copyWith(environmentPresets: [preset]),
    );
    expect(summary, contains('Ressource : Bois clair'));
    expect(summary, contains('densité 40 %'));
    expect(summary, contains('2 décors générés appartiennent à cette zone'));
  });
}
