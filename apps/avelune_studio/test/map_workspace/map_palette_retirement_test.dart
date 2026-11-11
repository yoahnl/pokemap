import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_resource_placement.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:avelune_studio/platform/rendering/viewports/spatial_map_editing_viewport.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_tool_strip.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../support/map_workspace_fixture.dart';
import '../support/spatial_environment_fixture.dart';
import '../support/spatial_narrative_fixture.dart';

class _PaletteWorkspacePort extends WorkspaceMemoryPort {
  _PaletteWorkspacePort(this.project);
  final ProjectManifest project;

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async {
    catalogs++;
    return project;
  }
}

void main() {
  for (final spatial in [false, true]) {
    for (final size in [const Size(1536, 1024), const Size(700, 800)]) {
      testWidgets(
        '${spatial ? '3D' : '2D'} ${size.width} keeps native editing after palette retirement',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final project = spatial
              ? spatialEnvironmentProject()
              : workspaceProject;
          final source = spatial
              ? spatialEnvironmentMap().copyWith(
                  spatialScene: spatialEnvironmentMap().spatialScene!.copyWith(
                    instances: [
                      SpatialModelInstance(
                        id: 'kept',
                        modelId: 'oak',
                        position: Model3dVector3(x: 2, y: 0, z: 2),
                      ),
                    ],
                  ),
                )
              : workspaceMap('a').copyWith(
                  placedElements: const [
                    MapPlacedElement(
                      id: 'kept',
                      elementId: 'tree',
                      layerId: 'ground',
                      pos: GridPos(x: 2, y: 2),
                    ),
                  ],
                );
          final port = _PaletteWorkspacePort(project)..saved['a'] = source;
          final maps = MapWorkspaceController(workspaceSession, port);
          await maps.initialize();
          final document = maps.active!;
          document.commit(
            document.current.copyWith(name: 'Brouillon conservé'),
          );
          final draft = document.current;
          final draftHistoryToken = document.undoToken;
          final savedBefore = document.saved;
          final baseBefore = document.base;
          final projectBefore = maps.project;
          expect(draftHistoryToken, isNotNull);
          final view = MapWorkspaceViewState()
            ..elementsVisible = true
            ..revealPalette = true;
          view.select(document, MapSelectionFamily.decor, 'kept');
          final selection = view.target;
          final atlasTransform = TransformationController(
            Matrix4.identity()..translateByDouble(12, 18, 0, 1),
          );
          view.paletteAtlasId = 'atlas';
          view.paletteAtlasTransforms['atlas'] = atlasTransform;
          view.fittedPaletteAtlases.add('atlas');
          final framing = atlasTransform.value.clone();
          final item = resourceCatalog(project).singleWhere(
            (item) => spatial
                ? item.model3d?.id == 'oak'
                : item.element?.id == 'tree',
          );
          expect(
            await useMapResource(
              workspace: maps,
              item: item,
              view: () => view,
              isActive: () => !maps.isDisposed,
              chooseMap: (_) async => null,
              chooseTile: (_) async => null,
            ),
            isTrue,
          );
          final visuals = spatial
              ? SpatialNarrativeVisuals()
              : WorkspaceTestVisuals();
          final search = TextEditingController(text: 'recherche conservée');
          final homeSearch = TextEditingController();
          view.resourceFilters.query = search.text;
          addTearDown(maps.dispose);
          addTearDown(view.dispose);
          addTearDown(visuals.dispose);
          addTearDown(search.dispose);
          addTearDown(homeSearch.dispose);
          final reads = port.reads, catalogs = port.catalogs;
          var paletteRequests = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: studioTheme(),
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, redraw) {
                    void changed() => redraw(() {});
                    return MapWorkspaceLayout(
                      controller: maps,
                      view: view,
                      visuals: visuals,
                      search: search,
                      homeSearch: homeSearch,
                      error: null,
                      palette: true,
                      inspector: false,
                      generation: 0,
                      onPalette: () => paletteRequests++,
                      onInspector: () {},
                      onChanged: changed,
                      onToolChanged: changed,
                      onActivate: (_) {},
                      onSave: null,
                      onTest: null,
                      onClose: () {},
                      onResources: () {},
                      onMap: () {},
                      onExport: () {},
                      onPokemon: () {},
                      onOpenElement: (_) {},
                      onEditElement: (_) {},
                    );
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(MapWorkspaceToolStrip), findsOneWidget);
          expect(find.byType(MapElementsPanel), findsOneWidget);
          expect(
            find.byType(
              spatial ? SpatialMapEditingViewport : MapEditingViewport2D,
            ),
            findsOneWidget,
          );
          expect(find.byTooltip('Palette'), findsNothing);
          expect(
            find.byKey(const ValueKey('palette-resize-handle')),
            findsNothing,
          );
          expect(find.byKey(const ValueKey('decor-tree')), findsNothing);
          expect(find.byKey(const ValueKey('tile-palette')), findsNothing);
          expect(find.text('recherche conservée'), findsNothing);
          expect(document.current, same(draft));
          expect(document.undoCount, 1);
          expect(document.selectedId, 'kept');
          expect(view.target, same(selection));
          expect(view.tool, StudioMapTool.place);
          expect(spatial ? view.model3d?.id : view.brush?.id, item.id);
          expect(view.revealPalette, isTrue);
          expect(view.resourceFilters.query, search.text);
          expect(view.paletteAtlasId, 'atlas');
          expect(view.paletteAtlasTransforms['atlas'], same(atlasTransform));
          expect(atlasTransform.value, framing);
          expect(view.fittedPaletteAtlases, contains('atlas'));
          expect(paletteRequests, 0);
          expect(port.reads, reads);
          expect(port.catalogs, catalogs);
          expect(port.writes, 0);

          await tester.tap(
            find.descendant(
              of: find.byType(MapWorkspaceToolStrip),
              matching: find.text('Décors'),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(
              'Les palettes de construction sont indisponibles pendant la refonte.',
            ),
            findsOneWidget,
          );
          expect(document.current, same(draft));
          expect(view.tool, StudioMapTool.place);
          expect(paletteRequests, 0);
          await tester.tap(find.byTooltip('Autres outils de carte'));
          await tester.pumpAndSettle();
          expect(find.text('Palette complète'), findsNothing);
          Navigator.of(tester.element(find.byType(PopupMenuItem<String>).first))
              .pop();
          await tester.pumpAndSettle();
          if (spatial) {
            tester
                .widget<SpatialSceneView>(find.byType(SpatialSceneView))
                .onCell(4, 3);
          } else {
            final rect = tester.getRect(
              find.byKey(const ValueKey('map-canvas')),
            );
            await tester.tapAt(
              rect.topLeft +
                  Offset(
                    4.5 * rect.width / source.size.width,
                    3.5 * rect.height / source.size.height,
                  ),
            );
          }
          await tester.pumpAndSettle();
          final placed = document.current;
          expect(placed, isNot(draft));
          expect(document.undoCount, 2);
          if (spatial) {
            expect(placed.spatialScene!.instances, hasLength(2));
            expect(placed.spatialScene!.instances.last.modelId, 'oak');
          } else {
            expect(placed.placedElements, hasLength(2));
            expect(placed.placedElements.last.elementId, 'tree');
          }
          await tester.tap(find.byTooltip('Annuler').last);
          await tester.pumpAndSettle();
          expect(document.current, draft);
          expect(document.current.toJson(), draft.toJson());
          expect(document.undoCount, 1);
          expect(document.undoToken, same(draftHistoryToken));
          expect(document.canUndo, isTrue);
          expect(document.canRedo, isTrue);
          expect(document.historyTokens, hasLength(2));
          expect(document.dirty, isTrue);
          expect(document.saved, same(savedBefore));
          expect(document.base, same(baseBefore));
          expect(maps.active, same(document));
          expect(maps.project, same(projectBefore));
          expect(port.saved['a'], same(source));
          expect(port.writes, 0);
          expect(port.reads, reads);
          expect(port.catalogs, catalogs);
          await tester.tap(find.byTooltip('Rétablir').last);
          await tester.pumpAndSettle();
          expect(document.current, placed);
          expect(document.current.toJson(), placed.toJson());
          expect(document.undoCount, 2);
          expect(document.canUndo, isTrue);
          expect(document.canRedo, isFalse);
          expect(document.redoToken, isNull);
          expect(document.historyTokens, hasLength(2));
          expect(document.dirty, isTrue);
          expect(document.saved, same(savedBefore));
          expect(document.base, same(baseBefore));
          expect(maps.active, same(document));
          expect(maps.project, same(projectBefore));
          expect(port.saved['a'], same(source));
          expect(port.writes, 0);
          expect(port.reads, reads);
          expect(port.catalogs, catalogs);
          final restoredPlacement = document.current;
          expect(await maps.save(document), isTrue, reason: document.error);
          expect(port.writes, 1);
          expect(port.saved.keys, ['a']);
          expect(port.saved['a'], same(restoredPlacement));
          expect(port.saved['a']!.toJson(), placed.toJson());
          expect(document.saved, same(restoredPlacement));
          expect(document.base.map, same(restoredPlacement));
          expect(document.base.revision, isNot(baseBefore.revision));
          expect(document.undoCount, 2);
          expect(document.canRedo, isFalse);
          final reopened = MapWorkspaceController(workspaceSession, port);
          addTearDown(reopened.dispose);
          await reopened.initialize();
          expect(reopened.active!.current, placed);
          expect(reopened.active!.current.toJson(), placed.toJson());
          expect(reopened.active!.dirty, isFalse);
          expect(document.dirty, isFalse);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
