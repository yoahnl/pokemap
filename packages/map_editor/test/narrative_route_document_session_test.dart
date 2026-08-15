import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_document_route.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/application/services/narrative_route_document_session.dart';

void main() {
  group('NarrativeRouteDocumentSession', () {
    test(
      'keeps Scene and Presentation histories under exact identities',
      () async {
        final scene = _fixture(
          route: NarrativeDocumentRoute.scene(
            sceneId: 'scene_new_game',
            source: NarrativeLibrarySourceContext(
              library: NarrativeLibraryKind.scenes,
            ),
          ),
        );
        final presentation = _fixture(
          route: NarrativeDocumentRoute.presentation(
            cinematicId: 'opening',
            source: NarrativeLibrarySourceContext(
              library: NarrativeLibraryKind.cinematics,
              cinematicFamily: CinematicLibraryFamily.presentation,
            ),
          ),
        );
        addTearDown(scene.controller.dispose);
        addTearDown(presentation.controller.dispose);

        await scene.controller.initialize();
        await presentation.controller.initialize();
        await scene.controller.apply(
          document: 'scene-local',
          operationId: 'scene-edit',
          label: 'Modifier la scène',
        );

        expect(scene.controller.state.canUndo, isTrue);
        expect(presentation.controller.state.canUndo, isFalse);
        expect(
          scene.controller.route.sessionDocumentId,
          'scene:scene_new_game',
        );
        expect(
          presentation.controller.route.sessionDocumentId,
          'presentationCinematic:opening',
        );
      },
    );

    test('rejects a session borrowed from another document', () {
      final route = NarrativeDocumentRoute.scene(
        sceneId: 'scene_new_game',
        source: NarrativeLibrarySourceContext(
          library: NarrativeLibraryKind.scenes,
        ),
      );

      expect(
        () => NarrativeRouteDocumentSession<String>(
          route: route,
          session: NarrativeDocumentSession<String>(
            documentId: 'map:world',
            initialDocument: 'disk',
            gateway: _MemoryGateway(),
            recoveryStore: _MemoryRecoveryStore(),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('uses one guard for cancel, discard and save-and-exit', () async {
      final cancelled = _fixture(route: _presentationRoute());
      addTearDown(cancelled.controller.dispose);
      await cancelled.controller.initialize();
      await cancelled.controller.apply(
        document: 'local',
        operationId: 'edit-cancel',
        label: 'Modifier',
      );

      expect(
        (await cancelled.controller.requestExit()).status,
        NarrativeDocumentExitStatus.decisionRequired,
      );
      expect(
        (await cancelled.controller.requestExit(
          decision: NarrativeDocumentExitDecision.cancel,
        )).status,
        NarrativeDocumentExitStatus.cancelled,
      );
      expect(cancelled.controller.state.document, 'local');

      expect(
        (await cancelled.controller.requestExit(
          decision: NarrativeDocumentExitDecision.discard,
        )).status,
        NarrativeDocumentExitStatus.exited,
      );
      expect(cancelled.controller.state.document, 'disk');
      expect(cancelled.routeStore.route, isNull);

      final saved = _fixture(route: _presentationRoute());
      addTearDown(saved.controller.dispose);
      await saved.controller.initialize();
      await saved.controller.apply(
        document: 'published',
        operationId: 'edit-save',
        label: 'Modifier',
      );
      final result = await saved.controller.requestExit(
        decision: NarrativeDocumentExitDecision.save,
        operationId: 'save-and-exit',
      );

      expect(result.status, NarrativeDocumentExitStatus.exited);
      expect(result.source, _presentationRoute().source);
      expect(saved.gateway.document, 'published');
      expect(saved.routeStore.route, isNull);
    });

    test(
      'keeps a conflicting draft without overwrite or automatic merge',
      () async {
        final fixture = _fixture(route: _presentationRoute());
        addTearDown(fixture.controller.dispose);
        await fixture.controller.initialize();
        await fixture.controller.apply(
          document: 'local',
          operationId: 'edit-conflict',
          label: 'Modifier',
        );
        fixture.gateway
          ..document = 'external'
          ..revision = 'revision-external';

        final result = await fixture.controller.requestExit(
          decision: NarrativeDocumentExitDecision.save,
          operationId: 'save-conflict',
        );

        expect(result.status, NarrativeDocumentExitStatus.conflicted);
        expect(fixture.controller.state.document, 'local');
        expect(fixture.gateway.document, 'external');
        expect(fixture.controller.conflictActions, const {
          NarrativeDocumentConflictAction.compare,
          NarrativeDocumentConflictAction.saveAsNew,
          NarrativeDocumentConflictAction.reloadExternal,
        });
        expect(fixture.routeStore.route, fixture.controller.route);
      },
    );

    test('resolves a conflict only through explicit user actions', () async {
      final fixture = _fixture(route: _presentationRoute());
      addTearDown(fixture.controller.dispose);
      await fixture.controller.initialize();
      await fixture.controller.apply(
        document: 'local',
        operationId: 'edit-conflict-resolution',
        label: 'Modifier',
      );
      fixture.gateway
        ..document = 'external'
        ..revision = 'revision-external';
      expect(
        await fixture.controller.save(operationId: 'conflicting-save'),
        isFalse,
      );

      final copiedRoute = NarrativeDocumentRoute.presentation(
        cinematicId: 'opening-copy',
        source: _presentationRoute().source,
      );
      final savedAsNew = await fixture.controller.saveConflictAsNew((
        document,
        source,
      ) async {
        expect(document, 'local');
        expect(source, _presentationRoute().source);
        return copiedRoute;
      });

      expect(savedAsNew, copiedRoute);
      expect(fixture.routeStore.route, copiedRoute);
      expect(fixture.gateway.document, 'external');
      expect(await fixture.controller.reloadExternal(), isTrue);
      expect(fixture.controller.state.document, 'external');
      expect(
        fixture.controller.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
    });

    test(
      'restores a crash draft and exact route in a new controller',
      () async {
        final route = _presentationRoute();
        final gateway = _MemoryGateway();
        final recovery = _MemoryRecoveryStore();
        final routeStore = _MemoryRouteStore();
        final first = _fixture(
          route: route,
          gateway: gateway,
          recovery: recovery,
          routeStore: routeStore,
        );
        await first.controller.initialize();
        await first.controller.apply(
          document: 'recovered',
          operationId: 'edit-before-crash',
          label: 'Modifier',
        );
        first.controller.dispose();

        final restoredRoute = await routeStore.read();
        final second = _fixture(
          route: restoredRoute!,
          gateway: gateway,
          recovery: recovery,
          routeStore: routeStore,
        );
        addTearDown(second.controller.dispose);
        await second.controller.initialize();

        expect(second.controller.state.document, 'recovered');
        expect(
          second.controller.state.status,
          NarrativeDocumentSessionStatus.recovered,
        );
        expect(second.controller.route.source, route.source);
      },
    );
  });
}

NarrativeDocumentRoute _presentationRoute() =>
    NarrativeDocumentRoute.presentation(
      cinematicId: 'opening',
      source: NarrativeSceneSourceContext(
        sceneId: 'scene_new_game',
        viewportX: 20,
        viewportY: 40,
        zoom: 1.25,
        selectedNodeId: 'node_presentation',
        inspector: NarrativeSceneInspector.properties,
      ),
    );

_Fixture _fixture({
  required NarrativeDocumentRoute route,
  _MemoryGateway? gateway,
  _MemoryRecoveryStore? recovery,
  _MemoryRouteStore? routeStore,
}) {
  final resolvedGateway = gateway ?? _MemoryGateway();
  final resolvedRecovery = recovery ?? _MemoryRecoveryStore();
  final resolvedRouteStore = routeStore ?? _MemoryRouteStore();
  return _Fixture(
    gateway: resolvedGateway,
    routeStore: resolvedRouteStore,
    controller: NarrativeRouteDocumentSession<String>(
      route: route,
      session: NarrativeDocumentSession<String>(
        documentId: route.sessionDocumentId,
        initialDocument: resolvedGateway.document,
        gateway: resolvedGateway,
        recoveryStore: resolvedRecovery,
      ),
      routeStore: resolvedRouteStore,
    ),
  );
}

final class _Fixture {
  const _Fixture({
    required this.gateway,
    required this.routeStore,
    required this.controller,
  });

  final _MemoryGateway gateway;
  final _MemoryRouteStore routeStore;
  final NarrativeRouteDocumentSession<String> controller;
}

final class _MemoryGateway implements NarrativeDocumentGateway<String> {
  String document = 'disk';
  String revision = 'revision-1';

  @override
  Future<NarrativeDocumentVersion<String>> read() async =>
      NarrativeDocumentVersion(revision: revision, document: document);

  @override
  Future<NarrativeDocumentSaveResult<String>> save({
    required String expectedRevision,
    required String before,
    required String after,
    required String operationId,
  }) async {
    if (expectedRevision != revision || before != document) {
      return NarrativeDocumentSaveResult<String>.conflicted(
        code: 'staleProjectRevision',
        message: 'External change.',
        external: NarrativeDocumentVersion(
          revision: revision,
          document: document,
        ),
      );
    }
    document = after;
    revision = 'revision-saved';
    return NarrativeDocumentSaveResult<String>.saved(
      NarrativeDocumentVersion(revision: revision, document: document),
    );
  }
}

final class _MemoryRecoveryStore
    implements NarrativeDocumentRecoveryStore<String> {
  NarrativeDocumentRecoveryRecord<String>? record;

  @override
  Future<void> clear() async => record = null;

  @override
  Future<NarrativeDocumentRecoveryRecord<String>?> read() async => record;

  @override
  Future<void> write(NarrativeDocumentRecoveryRecord<String> record) async {
    this.record = record;
  }
}

final class _MemoryRouteStore implements NarrativeDocumentRouteStore {
  NarrativeDocumentRoute? route;

  @override
  Future<void> clear() async => route = null;

  @override
  Future<NarrativeDocumentRoute?> read() async => route;

  @override
  Future<void> write(NarrativeDocumentRoute route) async {
    this.route = route;
  }
}
