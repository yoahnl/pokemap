import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_filter_button.dart';
import 'package:avelune_studio/presentation/features/resources/resource_library_screen.dart';
import 'package:avelune_studio/presentation/features/resources/resource_preview.dart';
import 'package:avelune_studio/presentation/features/characters/character_workspace_visuals.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

Future<void> _choose(WidgetTester tester, String key, String label) async {
  await tester.tap(find.byKey(ValueKey(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('components draft counts apply cancel reset and removable tag', (
    tester,
  ) async {
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
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                ResourceFilterButton(
                  filters: filters,
                  onChanged: () => setState(() => changes++),
                  countResults: (draft, _) => filterResourceCatalog(
                    project,
                    resourceCatalog(project),
                    draft,
                  ).length,
                ),
                ResourceFilterTags(
                  filters: filters,
                  onChanged: () => setState(() => changes++),
                ),
                Text(
                  'Visible: ${filterResourceCatalog(project, resourceCatalog(project), filters).length}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    String count() => tester
        .widget<Text>(
          find.byKey(const ValueKey('resource-filter-result-count')),
        )
        .data!;
    await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
    await tester.pumpAndSettle();
    expect(count(), '2 résultats');
    await tester.tap(find.byKey(const ValueKey('resource-filter-components')));
    await tester.pumpAndSettle();
    expect(count(), '3 résultats');
    expect(filters.showComponents, isFalse);
    expect(find.text('Visible: 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('resource-filter-cancel')));
    await tester.pumpAndSettle();
    expect(changes, 0);
    await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('resource-filter-components')));
    await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
    await tester.pumpAndSettle();
    expect(filters.showComponents, isTrue);
    expect(find.text('Visible: 3'), findsOneWidget);
    expect(find.text('Filtres (1)'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('Retirer le filtre Composants affichés')),
    );
    await tester.pumpAndSettle();
    expect(filters.showComponents, isFalse);
    filters.showComponents = true;
    filters.query = 'absent';
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
    await tester.pumpAndSettle();
    expect(count(), '0 résultats');
    await tester.tap(find.byKey(const ValueKey('resource-filter-reset')));
    await tester.pumpAndSettle();
    expect(count(), '0 résultats');
    expect(filters.showComponents, isTrue);
    await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
    await tester.pumpAndSettle();
    expect(filters.showComponents, isFalse);
    expect(filters.query, 'absent');
    expect(tester.takeException(), isNull);
  });
  testWidgets('character resources retain their authored animation preview', (
    tester,
  ) async {
    const character = ProjectCharacterEntry(
      id: 'guide',
      name: 'Guide',
      tilesetId: 'sheet',
      animations: [
        CharacterAnimation(
          state: CharacterAnimationState.idle,
          direction: EntityFacing.south,
          frames: [
            CharacterAnimationFrame(
              source: TilesetSourceRect(x: 6, y: 2, width: 1, height: 2),
            ),
          ],
        ),
      ],
    );
    final project = workspaceProject.copyWith(characters: [character]);
    final visuals = _CharacterVisuals();
    final item = resourceCatalog(project)
        .singleWhere((item) => item.character != null);
    await tester.pumpWidget(
      MaterialApp(home: resourcePreview(item, project, visuals, size: 190)),
    );
    expect(visuals.character, same(character));
    expect(find.text('Guide face sud'), findsOneWidget);
    expect(visuals.tileRequests, 0);
  });
  testWidgets(
    'filter draft cancels applies resets and tags remove one filter',
    (tester) async {
      final filters = ResourceCatalogFilterState(query: 'chêne');
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  ResourceFilterButton(
                    filters: filters,
                    onChanged: () => setState(() => changes++),
                    activeMapName: 'Clairière',
                  ),
                  ResourceFilterTags(
                    filters: filters,
                    onChanged: () => setState(() => changes++),
                    activeMapName: 'Clairière',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
      await tester.pumpAndSettle();
      await _choose(tester, 'resource-filter-scope', 'Propres à une carte');
      await _choose(tester, 'resource-filter-usage', 'Poser');
      expect(filters.scope, ResourceCatalogScope.all);
      expect(filters.usage, ResourceCatalogUsage.all);
      await tester.tap(find.byKey(const ValueKey('resource-filter-cancel')));
      await tester.pumpAndSettle();
      expect(changes, 0);
      await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
      await tester.pumpAndSettle();
      await _choose(tester, 'resource-filter-scope', 'Propres à une carte');
      await _choose(tester, 'resource-filter-usage', 'Poser');
      await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
      await tester.pumpAndSettle();
      expect(changes, 1);
      expect(filters.scope, ResourceCatalogScope.map);
      expect(filters.usage, ResourceCatalogUsage.place);
      expect(find.text('Filtres (2)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('Retirer le filtre Poser')));
      await tester.pump();
      expect(filters.scope, ResourceCatalogScope.map);
      expect(filters.usage, ResourceCatalogUsage.all);
      expect(filters.query, 'chêne');
      await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('resource-filter-reset')));
      await tester.pump();
      expect(filters.scope, ResourceCatalogScope.map);
      await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
      await tester.pumpAndSettle();
      expect(filters.scope, ResourceCatalogScope.all);
      expect(filters.query, 'chêne');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'map filter uses availability without a competing usage selector',
    (tester) async {
      final filters = ResourceCatalogFilterState();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: ResourceFilterButton(
              filters: filters,
              onChanged: () {},
              activeMapName: 'Clairière',
              forMapPicker: true,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('resource-filter-scope')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('resource-filter-usage')), findsNothing);
      await _choose(tester, 'resource-filter-scope', 'Propres à « Clairière »');
      await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
      await tester.pumpAndSettle();
      expect(filters.scope, ResourceCatalogScope.map);
      expect(filters.usage, ResourceCatalogUsage.all);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(1536, 1024),
    const Size(720, 620),
    const Size(760, 480),
  ]) {
    testWidgets('library families availability and details at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final project = workspaceProject.copyWith(
        elements: [
          workspaceElement,
          workspaceElement.copyWith(id: 'other', name: 'Cèdre'),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [
            ResourceFamily(id: 'cedars', name: 'Cèdres', parentId: 'trees'),
          ],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: 'tree',
              familyId: 'trees',
            ),
            ResourceLibraryEntry(
              resourceKind: 'element',
              resourceId: 'other',
              familyId: 'cedars',
              mapId: 'b',
            ),
          ],
        ),
      );
      final state = ResourceLibraryState();
      var classified = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MediaQuery(
            data: MediaQueryData(
              textScaler: TextScaler.linear(size.height < 500 ? 1.5 : 1),
            ),
            child: Scaffold(
              body: ResourceLibraryScreen(
                project: project,
                visuals: WorkspaceTestVisuals(),
                state: state,
                activeMapId: 'a',
                targetMapName: 'Clairière',
                onUse: (_) {},
                onEdit: (_) {},
                onTerrain: (_) {},
                onClassify: (_) => classified++,
                onManageFamilies: () {},
                onCreateBorder: () {},
                onResumeBorder: (_) {},
                onImport: () {},
                onBack: () {},
              ),
            ),
          ),
        ),
      );
      expect(state.atelierVisible, isFalse);
      expect(
        find.byKey(const ValueKey('resource-card-tileset:atlas')),
        findsOneWidget,
      );
      if (size.width < 1200) {
        await tester.tap(
          find.byKey(const ValueKey('resource-nature-family-chooser')),
        );
        await tester.pumpAndSettle();
      }
      await tester.ensureVisible(
        find.byKey(const ValueKey('resource-nature-family-trees')),
      );
      await tester.tap(
        find.byKey(const ValueKey('resource-nature-family-trees')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('resource-card-tileset:atlas')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('resource-card-element:other')),
        findsOneWidget,
      );
      String draftCount() => tester
          .widget<Text>(
            find.byKey(const ValueKey('resource-filter-result-count')),
          )
          .data!;
      await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
      await tester.pumpAndSettle();
      expect(draftCount(), '2 résultats');
      await _choose(tester, 'resource-filter-scope', 'Propres à une carte');
      expect(draftCount(), '1 résultat');
      expect(state.filters.scope, ResourceCatalogScope.all);
      await _choose(tester, 'resource-filter-usage', 'Peindre');
      expect(draftCount(), '0 résultats');
      expect(state.filters.usage, ResourceCatalogUsage.all);
      await tester.tap(find.byKey(const ValueKey('resource-filter-reset')));
      await tester.pump();
      expect(draftCount(), '2 résultats');
      expect(state.filters.familyId, 'trees');
      await tester.tap(find.byKey(const ValueKey('resource-filter-cancel')));
      await tester.pumpAndSettle();
      expect(state.filters.scope, ResourceCatalogScope.all);
      expect(
        find.byKey(const ValueKey('resource-card-element:tree')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
      await tester.pumpAndSettle();
      expect(draftCount(), '2 résultats');
      await _choose(tester, 'resource-filter-scope', 'Propres à une carte');
      expect(draftCount(), '1 résultat');
      await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
      await tester.pumpAndSettle();
      expect(state.filters.scope, ResourceCatalogScope.map);
      expect(
        find.byKey(const ValueKey('resource-card-element:tree')),
        findsNothing,
      );
      await tester.tap(
        find.byKey(const ValueKey('resource-card-element:other')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Carte : Jardin'), findsWidgets);
      expect(
        tester
            .widget<StudioButton>(find.byKey(const ValueKey('resource-use')))
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('resource-classify')),
      );
      await tester.tap(find.byKey(const ValueKey('resource-classify')));
      await tester.pumpAndSettle();
      expect(classified, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

class _CharacterVisuals extends WorkspaceTestVisuals
    implements CharacterWorkspaceVisuals {
  ProjectCharacterEntry? character;
  int tileRequests = 0;
  @override
  ProjectRegularAtlasTilesetSource? characterAtlas(
    ProjectCharacterEntry character,
  ) => null;
  @override
  Widget characterThumbnail(
    ProjectCharacterEntry character, {
    double size = 48,
    EntityFacing facing = EntityFacing.south,
  }) {
    this.character = character;
    return Text('${character.name} face sud');
  }

  @override
  Widget characterAnimationThumbnail(
    ProjectCharacterEntry character, {
    required double size,
    required EntityFacing facing,
    required CharacterAnimationState state,
    required int elapsedMs,
  }) => characterThumbnail(character, size: size, facing: facing);
  @override
  void setCharacterBrush(ProjectCharacterEntry? character) {}
  @override
  Widget tileThumbnail(TileLayerPaletteEntry tile, {double size = 48}) {
    tileRequests++;
    return super.tileThumbnail(tile, size: size);
  }
}
