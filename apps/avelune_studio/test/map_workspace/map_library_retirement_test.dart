import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_catalogue_workspace_actions.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

class _LibraryWorkspacePort extends WorkspaceMemoryPort {
  _LibraryWorkspacePort(this.empty);
  final bool empty;

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async {
    if (!empty) return super.loadProject(session);
    catalogs++;
    return workspaceProject.copyWith(maps: const []);
  }
}

class _UnexpectedCatalogPort implements MapCatalogPort {
  var mutations = 0, reconciliations = 0;

  @override
  Future<MapCatalogReceipt> mutate(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
  }) async {
    mutations++;
    throw StateError('Mounting the workspace cannot mutate its catalogue.');
  }

  @override
  Future<void> reconcile(
    ProjectSession session,
    MapCatalogReceipt receipt,
  ) async {
    reconciliations++;
    throw StateError('Mounting the workspace cannot integrate a receipt.');
  }
}

void main() {
  for (final size in [const Size(1536, 1024), const Size(900, 700)]) {
    for (final empty in [false, true]) {
      testWidgets(
        '${size.width} ${empty ? 'empty' : 'dirty'} workspace retires its library and retains its owners',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final port = _LibraryWorkspacePort(empty);
          port.saved['a'] = workspaceMap('a').copyWith(
            placedElements: const [
              MapPlacedElement(
                id: 'kept',
                layerId: 'ground',
                elementId: 'tree',
                pos: GridPos(x: 2, y: 2),
              ),
            ],
          );
          final catalog = _UnexpectedCatalogPort();
          final maps = MapWorkspaceController(
            workspaceSession,
            port,
            catalogPort: catalog,
          );
          await maps.initialize();
          final view = MapWorkspaceViewState()..elementsVisible = true;
          final visuals = WorkspaceTestVisuals();
          final search = TextEditingController();
          final homeSearch = TextEditingController();
          addTearDown(maps.dispose);
          addTearDown(view.dispose);
          addTearDown(visuals.dispose);
          addTearDown(search.dispose);
          addTearDown(homeSearch.dispose);
          final document = maps.active;
          if (document != null) {
            document.commit(document.current.copyWith(name: 'Brouillon'));
            view.select(document, MapSelectionFamily.decor, 'kept');
          }
          final source = document?.current;
          final selection = view.target;
          final project = maps.project!;
          final receipt = MapCatalogReceipt(
            before: project,
            manifest: project,
            beforeRevision: 'before',
            revision: 'published',
            changedPaths: const ['project.json'],
          );
          maps.pendingCatalogReceipt = receipt;
          final reads = port.reads, catalogs = port.catalogs;
          var activations = 0;
          await tester.pumpWidget(
            MaterialApp(
              theme: studioTheme(),
              home: StatefulBuilder(
                builder: (context, redraw) {
                  void changed() => redraw(() {});
                  return MapWorkspaceLayout(
                    controller: maps,
                    view: view,
                    visuals: visuals,
                    search: search,
                    homeSearch: homeSearch,
                    error: null,
                    palette: false,
                    inspector: false,
                    generation: 0,
                    onPalette: () {},
                    onInspector: () {},
                    onChanged: changed,
                    onToolChanged: changed,
                    onActivate: (_) => activations++,
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
          );
          await tester.pumpAndSettle();
          for (final key in [
            'new-map',
            'map-library-list',
            'map-library-search',
            'map-navigator-rail',
            'map-left-tab-maps',
          ]) {
            expect(find.byKey(ValueKey(key)), findsNothing);
          }
          expect(find.byTooltip('Dossiers de cartes'), findsNothing);
          expect(find.text('Nouvelle carte'), findsNothing);
          if (empty) {
            expect(
              find.byKey(const ValueKey('map-library-retired')),
              findsOneWidget,
            );
            expect(find.byType(MapElementsPanel), findsNothing);
          } else {
            expect(find.byType(MapElementsPanel), findsOneWidget);
            await tester.tap(find.byKey(const ValueKey('map-open-elements')));
            await tester.pumpAndSettle();
            expect(find.byType(MapElementsPanel), findsNothing);
            await tester.tap(find.byKey(const ValueKey('map-open-elements')));
            await tester.pumpAndSettle();
            expect(find.byType(MapElementsPanel), findsOneWidget);
            expect(document!.current, same(source));
            expect(document.undoCount, 1);
            expect(document.dirty, isTrue);
            expect(document.selectedId, 'kept');
            expect(view.target, same(selection));
          }
          expect(maps.active, same(document));
          expect(maps.project, same(project));
          expect(maps.pendingCatalogReceipt, same(receipt));
          expect(port.reads, reads);
          expect(port.catalogs, catalogs);
          expect(port.writes, 0);
          expect(catalog.mutations, 0);
          expect(catalog.reconciliations, 0);
          expect(activations, 0);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  test(
    'destination opening still activates the real owner after closing',
    () async {
      final maps = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(maps.dispose);
      await maps.initialize();
      final previous = maps.active!;
      previous.commit(previous.current.copyWith(name: 'Brouillon conservé'));
      final draft = previous.current;
      var closed = false;
      Future<void>? activation;
      final open = mapLibraryOpenAction(maps.project!, (entry) {
        expect(closed, isTrue);
        activation = maps.activate(entry);
      }, () => closed = true);
      open('missing');
      expect(closed, isFalse);
      expect(maps.active, same(previous));
      open('b');
      await activation;
      expect(maps.active!.base.mapId, 'b');
      expect(maps.documents['a'], same(previous));
      expect(previous.current, same(draft));
      expect(previous.undoCount, 1);
      expect(previous.dirty, isTrue);
    },
  );
}
