import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_draft_persistence_coordinator.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_draft_persistence_state.dart';

void main() {
  group('SmartTileDraftPersistenceCoordinator', () {
    test('debounces one discrete edit for exactly 500 ms with a fake clock',
        () async {
      final scheduler = _FakeScheduler();
      final gateway = _FakeGateway();
      final coordinator = _coordinator(gateway, scheduler);

      coordinator.updateDraft(_draft(name: 'After'));
      await scheduler.elapse(const Duration(milliseconds: 499));
      expect(gateway.calls, isEmpty);

      await scheduler.elapse(const Duration(milliseconds: 1));
      expect(gateway.calls, hasLength(1));
      expect(gateway.calls.single.draft.name, 'After');
      gateway.calls.single.succeed(revision: 'revision-1');
      await coordinator.flush();

      expect(coordinator.state.phase, SmartTileDraftPersistencePhase.saved);
      expect(coordinator.state.snapshotRevision, 'revision-1');
      expect(coordinator.draft.name, 'After');
    });

    test('serializes applies and coalesces an in-flight edit latest-wins',
        () async {
      final scheduler = _FakeScheduler();
      final gateway = _FakeGateway();
      final states = <SmartTileDraftPersistenceState>[];
      final coordinator = _coordinator(
        gateway,
        scheduler,
        onStateChanged: states.add,
      );

      coordinator.updateDraft(_draft(name: 'Generation 1'));
      await scheduler.elapse(const Duration(milliseconds: 500));
      expect(gateway.calls, hasLength(1));
      coordinator.updateDraft(_draft(name: 'Generation 2'));
      expect(gateway.maximumInFlight, 1);

      gateway.calls.first.succeed(revision: 'revision-1');
      await _eventLoop();
      expect(gateway.calls, hasLength(2));
      expect(gateway.calls.last.draft.name, 'Generation 2');
      expect(gateway.calls.last.expectedRevision, 'revision-1');
      expect(
        states.where(
          (state) =>
              state.phase == SmartTileDraftPersistencePhase.saved &&
              state.persistedGeneration == 1,
        ),
        isEmpty,
        reason: 'a stale generation must never make the current draft saved',
      );

      gateway.calls.last.succeed(revision: 'revision-2');
      await coordinator.flush();
      expect(coordinator.draft.name, 'Generation 2');
      expect(coordinator.state.persistedGeneration, 2);
      expect(gateway.maximumInFlight, 1);
    });

    test('flush cancels debounce and persists immediately', () async {
      final scheduler = _FakeScheduler();
      final gateway = _FakeGateway(autoSucceed: true);
      final coordinator = _coordinator(gateway, scheduler);

      coordinator.updateDraft(_draft(name: 'Flush now'));
      final state = await coordinator.flush();

      expect(gateway.calls, hasLength(1));
      expect(state.phase, SmartTileDraftPersistencePhase.saved);
      await scheduler.elapse(const Duration(seconds: 1));
      expect(gateway.calls, hasLength(1));
    });

    test('CAS conflict never retries until explicit fresh-revision consent',
        () async {
      final scheduler = _FakeScheduler();
      final gateway = _FakeGateway();
      final coordinator = _coordinator(gateway, scheduler);
      coordinator.updateDraft(_draft(name: 'Conflicting'));
      final flushing = coordinator.flush();
      gateway.calls.single.fail(
        const EditorAuthoringMutationFailure(
          code: 'plan.stale',
          message: 'The project changed.',
        ),
      );
      await flushing;

      expect(coordinator.state.phase, SmartTileDraftPersistencePhase.conflict);
      coordinator.updateDraft(_draft(name: 'Still local'));
      await scheduler.elapse(const Duration(seconds: 1));
      expect(gateway.calls, hasLength(1));
      expect(() => coordinator.retry(), throwsArgumentError);

      final retrying = coordinator.retry(expectedRevision: 'revision-fresh');
      await _eventLoop();
      expect(gateway.calls, hasLength(2));
      expect(gateway.calls.last.expectedRevision, 'revision-fresh');
      expect(gateway.calls.last.draft.name, 'Still local');
      gateway.calls.last.succeed(revision: 'revision-2');
      expect(
        (await retrying).phase,
        SmartTileDraftPersistencePhase.saved,
      );
    });

    test('failed save exposes retry and reuses the latest local draft',
        () async {
      final scheduler = _FakeScheduler();
      final gateway = _FakeGateway();
      final coordinator = _coordinator(gateway, scheduler);
      coordinator.updateDraft(_draft(name: 'First failure'));
      final flushing = coordinator.flush();
      gateway.calls.single.fail(StateError('offline'));
      await flushing;
      expect(coordinator.state.phase, SmartTileDraftPersistencePhase.failed);

      coordinator.updateDraft(_draft(name: 'Edited after failure'));
      final retrying = coordinator.retry();
      await _eventLoop();
      expect(gateway.calls.last.draft.name, 'Edited after failure');
      gateway.calls.last.succeed(revision: 'revision-retry');
      expect((await retrying).phase, SmartTileDraftPersistencePhase.saved);
    });

    test('reopen restores the canonical document and its revision', () async {
      final scheduler = _FakeScheduler();
      final gateway = _FakeGateway(
        initialDraft: _draft(name: 'Canonical reopen'),
        initialRevision: 'revision-reopen',
      );

      final coordinator = await SmartTileDraftPersistenceCoordinator.reopen(
        projectRootPath: '/project',
        draftId: 'draft-grass',
        gateway: gateway,
        scheduler: scheduler,
      );

      expect(coordinator.draft.name, 'Canonical reopen');
      expect(coordinator.state.phase, SmartTileDraftPersistencePhase.saved);
      expect(coordinator.state.snapshotRevision, 'revision-reopen');
      coordinator.updateDraft(_draft(name: 'Canonical reopen'));
      await scheduler.elapse(const Duration(seconds: 1));
      expect(gateway.calls, isEmpty, reason: 'canonical no-op is not planned');
    });

    test('uses a canonical SHA-256 idempotency key', () async {
      final scheduler = _FakeScheduler();
      final gateway = _FakeGateway(autoSucceed: true);
      final draft = _draft(name: 'Fingerprint');
      final coordinator = _coordinator(gateway, scheduler);

      coordinator.updateDraft(draft);
      await coordinator.flush();

      final fingerprint = smartTileDraftCanonicalFingerprint(draft);
      expect(fingerprint, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(
        gateway.calls.single.idempotencyKey,
        'smart-tile-draft:${draft.id}:$fingerprint',
      );
    });
  });
}

SmartTileDraftPersistenceCoordinator _coordinator(
  _FakeGateway gateway,
  _FakeScheduler scheduler, {
  SmartTileDraftPersistenceListener? onStateChanged,
}) =>
    SmartTileDraftPersistenceCoordinator(
      projectRootPath: '/project',
      initialDraft: _draft(),
      initialSnapshotRevision: 'revision-0',
      gateway: gateway,
      scheduler: scheduler,
      onStateChanged: onStateChanged,
    );

ProjectSmartTileAuthoringDraft _draft({String name = 'Grass'}) =>
    ProjectSmartTileAuthoringDraft(
      id: 'draft-grass',
      targetPresetId: 'grass',
      name: name,
      usage: SmartTileUsage.terrain,
      lastStage: SmartTileAuthoringStage.usage,
    );

Future<void> _eventLoop() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

final class _FakeScheduler implements SmartTileDraftDebounceScheduler {
  Duration _now = Duration.zero;
  final List<_FakeTimer> _timers = <_FakeTimer>[];

  @override
  SmartTileDraftDebounceTimer schedule(
    Duration delay,
    void Function() callback,
  ) {
    final timer = _FakeTimer(_now + delay, callback);
    _timers.add(timer);
    return timer;
  }

  Future<void> elapse(Duration duration) async {
    _now += duration;
    final due = _timers
        .where((timer) => timer.isActive && timer.due <= _now)
        .toList(growable: false);
    for (final timer in due) {
      timer.fire();
    }
    await _eventLoop();
  }
}

final class _FakeTimer implements SmartTileDraftDebounceTimer {
  _FakeTimer(this.due, this._callback);

  final Duration due;
  final void Function() _callback;
  bool _active = true;

  @override
  bool get isActive => _active;

  @override
  void cancel() => _active = false;

  void fire() {
    if (!_active) return;
    _active = false;
    _callback();
  }
}

final class _FakeGateway implements SmartTileDraftPersistenceGateway {
  _FakeGateway({
    this.autoSucceed = false,
    ProjectSmartTileAuthoringDraft? initialDraft,
    String initialRevision = 'revision-0',
  })  : _canonicalDraft = initialDraft,
        _revision = initialRevision;

  final bool autoSucceed;
  final List<_FakeUpsertCall> calls = <_FakeUpsertCall>[];
  ProjectSmartTileAuthoringDraft? _canonicalDraft;
  String _revision;
  int _inFlight = 0;
  int maximumInFlight = 0;

  @override
  Future<SmartTileDraftCanonicalSnapshot> load({
    required String projectRootPath,
    required String draftId,
  }) async =>
      SmartTileDraftCanonicalSnapshot(
        snapshotRevision: _revision,
        manifest: ProjectManifest(
          name: 'Fixture',
          version: ProjectVersion.v6,
          maps: const <ProjectMapEntry>[],
          tilesets: const <ProjectTilesetEntry>[],
          smartTileCatalog: ProjectSmartTileCatalog(
            drafts: <ProjectSmartTileAuthoringDraft>[
              if (_canonicalDraft case final draft?) draft,
            ],
          ),
        ),
        draft: _canonicalDraft?.id == draftId ? _canonicalDraft : null,
      );

  @override
  Future<SmartTileDraftPersistenceApplyResult> upsert({
    required String projectRootPath,
    required ProjectSmartTileAuthoringDraft draft,
    required String expectedRevision,
    required String idempotencyKey,
    required String operationId,
  }) async {
    _inFlight++;
    maximumInFlight = _inFlight > maximumInFlight ? _inFlight : maximumInFlight;
    final completer = Completer<SmartTileDraftPersistenceApplyResult>();
    final call = _FakeUpsertCall(
      draft: draft,
      expectedRevision: expectedRevision,
      idempotencyKey: idempotencyKey,
      completer: completer,
      succeed: (revision) {
        _canonicalDraft = draft;
        _revision = revision;
      },
    );
    calls.add(call);
    if (autoSucceed) call.succeed(revision: 'revision-${calls.length}');
    try {
      return await completer.future;
    } finally {
      _inFlight--;
    }
  }
}

final class _FakeUpsertCall {
  _FakeUpsertCall({
    required this.draft,
    required this.expectedRevision,
    required this.idempotencyKey,
    required Completer<SmartTileDraftPersistenceApplyResult> completer,
    required void Function(String revision) succeed,
  })  : _completer = completer,
        _onSucceed = succeed;

  final ProjectSmartTileAuthoringDraft draft;
  final String expectedRevision;
  final String idempotencyKey;
  final Completer<SmartTileDraftPersistenceApplyResult> _completer;
  final void Function(String revision) _onSucceed;

  void succeed({required String revision}) {
    _onSucceed(revision);
    _completer.complete(
      SmartTileDraftPersistenceApplyResult(snapshotRevision: revision),
    );
  }

  void fail(Object error) => _completer.completeError(error);
}
