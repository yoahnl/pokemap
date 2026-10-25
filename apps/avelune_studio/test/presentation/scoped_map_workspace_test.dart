import 'dart:async';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_resource_diagnostic.dart';
import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:avelune_studio/presentation/features/resources/working_catalog_workspace.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_application_frame.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/shared/widgets/dialogs/studio_review_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

void main() {
  testWidgets(
    'scoped map test opens the runtime without loading all workshops',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final port = ScopedTestMapPort();
      final controller = MapWorkspaceController(scopedMapSession, port);
      addTearDown(controller.dispose);
      var launches = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MapWorkspaceScreen(
            controller: controller,
            loadVisuals: (_, _) async => _Visuals([]),
            runtimeBuilder: (entry, revision, close) {
              launches++;
              expect(entry.id, 'first');
              expect(revision, 'map-1');
              return Scaffold(
                body: TextButton(
                  onPressed: close,
                  child: const Text('Retour du test'),
                ),
              );
            },
            onClose: () async {},
            registerExitGuard: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      final document = controller.active;
      final reads = List.of(port.selections);
      await tester.tap(find.text('Tester la carte'));
      await tester.pumpAndSettle();
      expect(launches, 1);
      expect(find.text('Retour du test'), findsOneWidget);
      expect(port.fullReads, 0);
      expect(port.workshops, isEmpty);
      expect(port.selections, reads);
      expect(controller.hasCompleteProject, isFalse);
      await tester.tap(find.text('Retour du test'));
      await tester.pumpAndSettle();
      expect(controller.active, same(document));
      expect(controller.active!.dirty, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('map rendering stays scoped without a global workshop banner', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1500, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final port = ScopedTestMapPort();
    final controller = MapWorkspaceController(scopedMapSession, port);
    addTearDown(controller.dispose);
    final visualContexts = <List<String>>[];
    final visuals = <_Visuals>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MapWorkspaceScreen(
          controller: controller,
          loadVisuals: (ProjectSession session, ProjectManifest project) async {
            visualContexts.add(
              project.tilesets.map((item) => item.id).toList(),
            );
            final instance = _Visuals(visualContexts);
            visuals.add(instance);
            return instance;
          },
          runtimeBuilder: (_, _, _) => const SizedBox(),
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(port.fullReads, 0);
    expect(visualContexts.single, ['first']);
    final delayed = Completer<void>();
    visuals.first.nextUpdate = delayed;
    await controller.activate(secondScopedMap);
    await tester.pump();
    await controller.activate(firstScopedMap);
    await tester.pump();
    delayed.complete();
    await tester.pumpAndSettle();
    expect(visualContexts.last, ['first']);
    await controller.activate(secondScopedMap);
    await tester.pumpAndSettle();
    expect(visualContexts.last, ['second']);
    expect(find.text('Carte second'), findsWidgets);
    expect(
      find.byKey(const ValueKey('workspace-materialize-workshops')),
      findsNothing,
    );
    await tester.tap(find.text('Pokémon'));
    await tester.pumpAndSettle();
    expect(port.fullReads, 0);
    expect(find.text('Charger tous les ateliers du projet ?'), findsNothing);
    expect(port.workshops, contains(MapWorkspaceWorkshop.pokemon));
    expect(port.fullReads, 0);
    expect(visualContexts.last, ['second']);
    expect(visuals.first.disposed, isFalse);
    expect(controller.active?.base.mapId, 'second');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'resources share the Studio frame and preserve drafts without full reads',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final mapPort = ScopedTestMapPort();
      final maps = MapWorkspaceController(scopedMapSession, mapPort);
      final catalogPort = _CatalogPort();
      final catalog = WorkingCatalogController(catalogPort);
      final home = StudioHomeNavigation();
      addTearDown(maps.dispose);
      addTearDown(catalog.dispose);
      addTearDown(home.dispose);
      var visualLoads = 0;
      Future<bool> Function()? exit;
      await tester.pumpWidget(
        MaterialApp(
          home: MapWorkspaceScreen(
            controller: maps,
            home: home,
            loadVisuals: (_, _) async {
              visualLoads++;
              return _Visuals([]);
            },
            resourceLibraryBuilder: (context, guard, onSaved, onOpenTools) =>
                WorkingCatalogWorkspace(
                  session: scopedMapSession,
                  controller: catalog,
                  onClose: () async {},
                  registerExitGuard: guard,
                  embedded: true,
                  onSaved: onSaved,
                  onOpenTools: onOpenTools,
                ),
            runtimeBuilder: (_, _, _) => const SizedBox(),
            onClose: () async {},
            registerExitGuard: (guard) => exit = guard,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(catalogPort.queries, 0);
      final draft = maps.active!;
      draft.current = draft.current.copyWith(name: 'Brouillon conservé');
      await tester.tap(find.text('Ressources'));
      await tester.pumpAndSettle();
      expect(find.byType(StudioApplicationFrame), findsOneWidget);
      expect(tester.getTopLeft(find.byType(StudioApplicationFrame)).dy, 0);
      expect(find.text('Retour à la bibliothèque'), findsNothing);
      expect(find.text('Charger tous les ateliers et imports'), findsNothing);
      expect(find.text('Bibliothèque du projet'), findsOneWidget);
      expect(catalogPort.queries, 1);
      expect(mapPort.fullReads, 0);
      await catalog.select(catalogPort.entry);
      await tester.pumpAndSettle();
      catalog.edit(name: 'Ressource modifiée');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
      expect(find.text('Conserver vos modifications ?'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Bibliothèque du projet'), findsOneWidget);
      expect(catalog.dirty, isTrue);
      catalogPort.failSave = true;
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(StudioReviewDialog),
          matching: find.text('Enregistrer'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bibliothèque du projet'), findsOneWidget);
      expect(catalog.dirty, isTrue);
      catalogPort.failSave = false;
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(StudioReviewDialog),
          matching: find.text('Enregistrer'),
        ),
      );
      await tester.pumpAndSettle();
      expect(catalog.dirty, isFalse);
      expect(catalogPort.entry.name, 'Ressource modifiée');
      expect(find.text('Bibliothèque du projet'), findsNothing);
      expect(maps.active, same(draft));
      expect(maps.active!.current.name, 'Brouillon conservé');
      expect(maps.active!.dirty, isTrue);
      expect(visualLoads, 1);
      expect(mapPort.fullReads, 0);
      home.navigate('resources');
      await tester.pumpAndSettle();
      expect(find.text('Bibliothèque du projet'), findsOneWidget);
      await catalog.select(catalogPort.entry);
      catalog.edit(name: 'À abandonner');
      await tester.pumpAndSettle();
      final closing = exit!();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(await closing, isFalse);
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abandonner'));
      await tester.pumpAndSettle();
      expect(catalog.dirty, isFalse);
      expect(maps.active, same(draft));
      expect(visualLoads, 1);
      expect(mapPort.fullReads, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

class _Visuals extends ChangeNotifier
    implements MapWorkspaceVisuals, ResourceWorkspaceVisuals {
  _Visuals(this.contexts);
  final List<List<String>> contexts;
  bool disposed = false;
  Completer<void>? nextUpdate;
  @override
  Future<void> updateCatalog(
    ProjectManifest manifest, {
    Set<String> changedRelativePaths = const {},
  }) async {
    final delayed = nextUpdate;
    nextUpdate = null;
    await delayed?.future;
    contexts.add(manifest.tilesets.map((e) => e.id).toList());
  }

  @override
  Widget canvas(
    MapData map, {
    MapPlacedElement? placedElementPreview,
    Color? collisionColor,
  }) => Text('Carte ${map.id}');
  @override
  List<WorkspaceResourceDiagnostic> get diagnostics => const [];
  @override
  Set<String> get activeResourceIds => const {};
  @override
  List<String> get warnings => const [];
  @override
  void setActiveMap(MapData map) {}
  @override
  void setBrush(ProjectElementEntry? element, TileLayerPaletteEntry? tile) {}
  @override
  void setTerrainBrush(ProjectSmartTilePreset? preset) {}
  @override
  Future<void> retryResources(Iterable<String> resourceIds) async {}
  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) =>
      const SizedBox();
  @override
  Widget placementPreview(ProjectElementEntry element, Size size) =>
      const SizedBox();
  @override
  Widget tileThumbnail(TileLayerPaletteEntry tile, {double size = 48}) =>
      const SizedBox();
  @override
  Widget atlasPreview(String tilesetId) => const SizedBox();
  @override
  Future<void> dispose() async {
    disposed = true;
    super.dispose();
  }
}

class _CatalogPort implements WorkingCatalogPort {
  int queries = 0;
  bool failSave = false;
  WorkingCatalogEntry entry = const WorkingCatalogEntry(
    id: 'decor',
    kind: 'element',
    name: 'Décor',
  );
  @override
  Future<WorkingCatalogPage> query({
    required String kind,
    required String text,
    String? cursor,
    String? placementContext,
  }) async {
    queries++;
    return WorkingCatalogPage(revision: 'catalog', items: [entry], total: 1);
  }

  @override
  Future<WorkingCatalogDetail> open(WorkingCatalogEntry selected) async =>
      WorkingCatalogDetail(
        entry: entry,
        revision: 'catalog',
        definitions: scopedMapMetadata,
      );
  @override
  Future<WorkingCatalogDetail> save(
    WorkingCatalogEntry selected,
    WorkingCatalogDraft draft, {
    required String revision,
  }) async {
    if (failSave) throw StateError('Échec de sauvegarde');
    entry = WorkingCatalogEntry(
      id: entry.id,
      kind: entry.kind,
      name: draft.name,
    );
    return open(entry);
  }

  @override
  Future<void> close() async {}
  @override
  Future<void> recover(String operationId) async {}
}
