import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_panels.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/resources/atlas_selection_view.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('lazy decor grid retains scroll and activates actual brush', (
    tester,
  ) async {
    final view = MapWorkspaceViewState();
    final search = TextEditingController();
    final visuals = _PaletteVisuals();
    final project = workspaceProject.copyWith(
      elements: [
        for (var i = 0; i < 500; i++)
          workspaceElement.copyWith(id: 'tree-$i', name: 'Arbre $i'),
      ],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r', mapId: 'a'),
    );
    addTearDown(view.dispose);
    addTearDown(search.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 580,
            child: StatefulBuilder(
              builder: (context, setState) => MapWorkspacePalette(
                project: project,
                document: document,
                visuals: visuals,
                view: view,
                search: search,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
      ),
    );
    expect(visuals.requested.length, lessThan(20));
    await tester.tap(find.byKey(const ValueKey('decor-tree-0')));
    await tester.pump();
    expect(view.brush!.id, 'tree-0');
    expect(view.tool, StudioMapTool.place);
    expect(document.dirty, isFalse);
    await tester.drag(
      find.byKey(const ValueKey('decor-palette')),
      const Offset(0, -260),
    );
    await tester.pumpAndSettle();
    final offset = view.paletteScrollOffsets['Décors']!;
    expect(offset, greaterThan(100));
    await tester.tap(find.text('Terrains'));
    await tester.pump();
    await tester.tap(find.text('Décors'));
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('decor-palette')),
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      closeTo(offset, .1),
    );
    await tester.enterText(find.byType(TextField), 'Arbre 499');
    await tester.pumpAndSettle();
    expect(find.text('1 décors'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('decor-tree-499')));
    await tester.pump();
    expect(view.brush!.id, 'tree-499');
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline atlas selects real tile and preserves zoom across tabs', (
    tester,
  ) async {
    final view = MapWorkspaceViewState()..paletteTab = 'Tuiles';
    final search = TextEditingController();
    final project = workspaceProject.copyWith(
      tilesets: [
        const ProjectTilesetEntry(
          id: 'atlas',
          name: 'Atlas test',
          relativePath: 'atlas.png',
          source: ProjectRegularAtlasTilesetSource(
            assetId: 'atlas',
            pixelWidth: 128,
            pixelHeight: 128,
            tileWidth: 32,
            tileHeight: 32,
          ),
        ),
      ],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: workspaceMap('a'), revision: 'r', mapId: 'a'),
    );
    addTearDown(view.dispose);
    addTearDown(search.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 640,
            child: StatefulBuilder(
              builder: (context, setState) => MapWorkspacePalette(
                project: project,
                document: document,
                visuals: _PaletteVisuals(),
                view: view,
                search: search,
                onChanged: () => setState(() {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final selection = tester.widget<AtlasSelectionView>(
      find.byType(AtlasSelectionView),
    );
    selection.onSelected(const TilesetSourceRect(x: 2, y: 1));
    await tester.pump();
    expect(
      view.tile,
      const TileLayerPaletteEntry(tilesetId: 'atlas', localTileId: 6),
    );
    expect(view.tool, StudioMapTool.paint);
    expect(find.byType(Dialog), findsNothing);
    await tester.tap(find.byTooltip('Zoom avant'));
    await tester.pumpAndSettle();
    final transform = view.paletteAtlasTransforms['atlas']!.value.clone();
    await tester.tap(find.text('Décors'));
    await tester.pump();
    await tester.tap(find.text('Tuiles'));
    await tester.pumpAndSettle();
    expect(view.paletteAtlasTransforms['atlas']!.value, transform);
    expect(tester.takeException(), isNull);
  });
}

class _PaletteVisuals extends WorkspaceTestVisuals
    implements ResourceWorkspaceVisuals {
  final requested = <String>{};
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) {
    requested.add(element.id);
    return SizedBox.square(dimension: size);
  }

  @override
  Widget atlasPreview(String tilesetId) => const SizedBox.expand();
  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {}
  @override
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  }) async {}
}
