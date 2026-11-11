import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_destination_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_publication_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workshop_routes.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/resources/application/working_catalog_controller.dart';
import 'package:avelune_studio/features/resources/coordination/working_catalog_workflow.dart';
import 'package:avelune_studio/features/resources/domain/working_catalog_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/scoped_map_workspace_port.dart';

class _CatalogPort implements WorkingCatalogPort {
  int queries = 0, saveCalls = 0;
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
    saveCalls++;
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

Future<void> _settle() async {
  for (var turn = 0; turn < 20; turn++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test(
    'injected catalogue owner guard preserves drafts and Studio navigation without the retired screen',
    () async {
      final mapPort = ScopedTestMapPort();
      final maps = MapWorkspaceController(scopedMapSession, mapPort);
      addTearDown(maps.dispose);
      await maps.initialize();
      final catalogPort = _CatalogPort();
      final catalog = WorkingCatalogController(catalogPort);
      addTearDown(catalog.dispose);
      Completer<WorkingCatalogExitDecision>? decision;
      Future<WorkingCatalogExitDecision> confirmExit() {
        expect(decision, isNull);
        decision = Completer<WorkingCatalogExitDecision>();
        return decision!.future;
      }

      Future<void> choose(WorkingCatalogExitDecision value) async {
        final pending = decision;
        expect(pending, isNotNull);
        decision = null;
        pending!.complete(value);
        await _settle();
      }

      WorkingCatalogWorkflow? library;
      Future<bool> Function()? libraryGuard;
      var releases = 0;
      Future<void> mountLibrary() async {
        late final WorkingCatalogWorkflow mounted;
        mounted = WorkingCatalogWorkflow(
          catalog: catalog,
          isActive: () => identical(library, mounted),
          confirmExit: confirmExit,
          onSaved: maps.refreshCatalogSelection,
          changed: () {},
        );
        library = mounted;
        libraryGuard = () => mounted.allowExit(closing: true);
        await catalog.search('');
      }

      final navigation = WorkspaceNavigationSession(
        controller: maps,
        isActive: () => true,
        changed: () {},
      );
      final sessions = WorkspaceSessionControllers(
        controller: maps,
        changed: () {},
        visualCatalogChanged: (_) {},
        flushEditors: () async => true,
      );
      addTearDown(sessions.dispose);
      final workshops = WorkspaceWorkshopRoutes(
        controller: maps,
        isActive: () => true,
        failed: (_) {},
        changed: () {},
      );
      final destinations = WorkspaceDestinationWorkflow(
        controller: maps,
        navigation: navigation,
        sessions: sessions,
        workshops: workshops,
        isActive: () => true,
        changed: () {},
        leavePokemon: () async => true,
        flushFocus: () {},
        closeContext: () {},
        libraryExitGuard: () => libraryGuard,
        libraryReleased: () {
          releases++;
          library?.dispose();
          library = null;
          libraryGuard = null;
        },
        customResourceLibrary: () => true,
      );
      addTearDown(destinations.dispose);
      final publication = WorkspacePublicationWorkflow(
        controller: maps,
        workflow: WorkspaceWorkflow(
          controller: maps,
          isActive: () => true,
          changed: () {},
          resources: () => null,
          narrative: () => null,
          confirmClose: () async => WorkspaceCloseChoice.cancel,
          flushFocus: () {},
          launchMap: (_, _) async {},
        ),
        isActive: () => true,
        connectionBusy: () => false,
        exporter: () => null,
        resources: () => null,
        pokemon: () => null,
      );
      Future<bool> close() => publication.allowClose(
        leavePokemon: () async => true,
        leaveLibrary: destinations.allowLibraryExit,
      );

      expect(await destinations.allowLibraryExit(), isTrue);
      final draft = maps.active!;
      draft.current = draft.current.copyWith(name: 'Brouillon conservé');
      expect(catalogPort.queries, 0);

      destinations.show(WorkspaceSpace.resources);
      await _settle();
      expect(navigation.space, WorkspaceSpace.resources);
      expect(mapPort.workshops, isEmpty);
      expect(mapPort.resourceKinds, isEmpty);
      expect(mapPort.fullReads, 0);
      await mountLibrary();
      expect(catalogPort.queries, 1);
      await catalog.select(catalogPort.entry);
      catalog.edit(name: 'Ressource modifiée');

      destinations.show(WorkspaceSpace.map);
      await _settle();
      expect(decision, isNotNull);
      expect(catalogPort.saveCalls, 0);
      await choose(WorkingCatalogExitDecision.stay);
      expect(navigation.space, WorkspaceSpace.resources);
      expect(releases, 0);
      expect(catalog.dirty, isTrue);

      catalogPort.failSave = true;
      destinations.show(WorkspaceSpace.map);
      await _settle();
      await choose(WorkingCatalogExitDecision.save);
      expect(navigation.space, WorkspaceSpace.resources);
      expect(releases, 0);
      expect(catalog.dirty, isTrue);
      expect(catalogPort.saveCalls, 1);
      expect(catalog.error, contains('Échec de sauvegarde'));
      expect(catalog.draft!.name, 'Ressource modifiée');
      expect(catalogPort.entry.name, 'Décor');

      catalogPort.failSave = false;
      destinations.show(WorkspaceSpace.map);
      await _settle();
      await choose(WorkingCatalogExitDecision.save);
      expect(catalog.dirty, isFalse);
      expect(catalogPort.entry.name, 'Ressource modifiée');
      expect(catalogPort.saveCalls, 2);
      expect(navigation.space, WorkspaceSpace.map);
      expect(releases, 1);
      expect(await destinations.allowLibraryExit(), isTrue);
      expect(maps.active, same(draft));
      expect(maps.active!.current.name, 'Brouillon conservé');
      expect(maps.active!.dirty, isTrue);
      expect(mapPort.fullReads, 0);

      destinations.show(WorkspaceSpace.resources);
      await _settle();
      expect(navigation.space, WorkspaceSpace.resources);
      await mountLibrary();
      await catalog.select(catalogPort.entry);
      catalog.edit(name: 'À abandonner');
      final closing = close();
      await _settle();
      await choose(WorkingCatalogExitDecision.stay);
      expect(await closing, isFalse);
      expect(catalog.dirty, isTrue);
      expect(catalog.draft!.name, 'À abandonner');
      expect(navigation.space, WorkspaceSpace.resources);

      destinations.show(WorkspaceSpace.map);
      await _settle();
      await choose(WorkingCatalogExitDecision.discard);
      expect(catalog.dirty, isFalse);
      expect(catalogPort.saveCalls, 2);
      expect(catalogPort.entry.name, 'Ressource modifiée');
      expect(navigation.space, WorkspaceSpace.map);
      expect(releases, 2);
      expect(maps.active, same(draft));
      expect(maps.active!.current.name, 'Brouillon conservé');
      expect(mapPort.workshops, isEmpty);
      expect(mapPort.fullReads, 0);
    },
  );
}
