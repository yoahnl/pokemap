import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/app/providers/editor/map_use_case_providers.dart';
import 'package:map_editor/src/application/models/map_history_snapshot.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/map_dependency_preflight_service.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/domain/models/map_document_persistence.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_controller.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('EditorNotifier.activateMap', () {
    test('same-map activation is a strict no-op, even while dirty', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier;
      final before = _dirtySourceState();
      notifier.state = before;

      final outcome = await notifier.activateMap('maps/alpha.json');

      expect(outcome, MapActivationOutcome.activated);
      expect(notifier.state, before);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('explicit recovery reload bypasses the dirty prompt', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      final outcome = await notifier.activateMap(
        'maps/alpha.json',
        forceReload: true,
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(notifier.state.activeMap, same(_alphaSaved));
      expect(notifier.state.isDirty, isFalse);
      expect(
        fixture.repository.loadedPaths,
        <String>['/project/maps/alpha.json'],
      );
    });

    test('dirty activation requires a decision before any I/O', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      final outcome = await notifier.activateMap('maps/beta.json');

      expect(outcome, MapActivationOutcome.requiresDecision);
      expect(notifier.state.activeMap!.id, 'alpha');
      expect(notifier.state.isDirty, isTrue);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('clean map with a pending Border preview requires a decision',
        () async {
      final fixture = _ActivationFixture();
      final map = _alphaWithBorder();
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(
          activeMap: map,
          savedMapSnapshot: map,
        );
      fixture.preview.begin(
        map: map,
        layerId: 'borders',
        featureId: 'coast',
        context: createEditorBorderPreviewContext(
          projectRootPath: '/project',
          activeMapPath: '/project/maps/alpha.json',
          project: _project,
          map: map,
        ),
      );

      final outcome = await notifier.activateMap('maps/beta.json');

      expect(outcome, MapActivationOutcome.requiresDecision);
      expect(notifier.state.activeMap, same(map));
      expect(fixture.preview.current.hasPendingPreview, isTrue);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('cancel keeps the complete source editing session intact', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier;
      final before = _dirtySourceState();
      notifier.state = before;

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.cancel,
      );

      expect(outcome, MapActivationOutcome.cancelled);
      expect(notifier.state, before);
      expect(fixture.repository.loadedPaths, isEmpty);
    });

    test('a stale decision after cancel is rejected without I/O', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier;
      final before = _dirtySourceState();
      notifier.state = before;

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      expect(
        await notifier.activateMap(
          'maps/beta.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationOutcome.cancelled,
      );

      final staleOutcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );

      expect(staleOutcome, MapActivationOutcome.unavailable);
      expect(notifier.state, before);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('Discard is rejected if the source snapshot changed while prompting',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final replacement = notifier.state.copyWith(
        activeMap: notifier.state.activeMap!.copyWith(name: 'Async result'),
      );
      notifier.state = replacement;

      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );

      expect(outcome, MapActivationOutcome.unavailable);
      expect(notifier.state, replacement);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('a stale decision cannot hide behind a same-map no-op', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      expect(
        await notifier.activateMap(
          'maps/beta.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationOutcome.cancelled,
      );
      final replacementProject = _project.copyWith(name: 'Replacement');
      final replacementState = _cleanSourceState().copyWith(
        project: replacementProject,
        activeMap: _beta,
        activeMapPath: '/project/maps/beta.json',
        savedMapSnapshot: _beta,
      );
      notifier.state = replacementState;

      final staleOutcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );

      expect(staleOutcome, MapActivationOutcome.unavailable);
      expect(notifier.state, replacementState);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('discard loads the target and opens a clean document', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(notifier.state.activeMap, same(_beta));
      expect(notifier.state.activeMapPath, '/project/maps/beta.json');
      expect(notifier.state.savedMapSnapshot, same(_beta));
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.mapUndoStack, isEmpty);
      expect(notifier.state.mapRedoStack, isEmpty);
      expect(fixture.repository.loadedPaths, ['/project/maps/beta.json']);
      expect(fixture.repository.savedPaths, isEmpty);
    });

    test('save persists the source before loading the target', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier
        ..state = const EditorState(
          projectRootPath: '/project',
          project: _project,
        );
      expect(
        await notifier.activateMap('maps/alpha.json'),
        MapActivationOutcome.activated,
      );
      fixture.repository
        ..loadedPaths.clear()
        ..callOrder.clear();
      notifier.state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.save,
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(fixture.repository.callOrder, <String>[
        'save:/project/maps/alpha.json',
        'load:/project/maps/beta.json',
      ]);
      expect(fixture.repository.savedMaps.single, same(_alphaEdited));
      expect(notifier.state.activeMap, same(_beta));
      expect(notifier.state.isDirty, isFalse);
    });

    test('successful external save may advance map identity before activation',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final savedReplacement =
          notifier.state.activeMap!.copyWith(name: 'Saved async result');
      notifier.state = notifier.state.copyWith(
        activeMap: savedReplacement,
        savedMapSnapshot: savedReplacement,
        isDirty: false,
      );

      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.save,
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(notifier.state.activeMap, same(_beta));
      expect(fixture.repository.savedPaths, isEmpty);
      expect(
        fixture.repository.loadedPaths,
        <String>['/project/maps/beta.json'],
      );
    });

    test('failed save blocks navigation and preserves the source', () async {
      final fixture = _ActivationFixture(saveError: StateError('disk full'));
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.save,
      );

      expect(outcome, MapActivationOutcome.saveBlocked);
      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.activeMapPath, '/project/maps/alpha.json');
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.mapUndoStack, isNotEmpty);
      expect(fixture.repository.loadedPaths, isEmpty);
    });

    test('missing target is rejected before saving a dirty source', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      final outcome = await notifier.activateMap('maps/missing.json');

      expect(outcome, MapActivationOutcome.failed);
      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.activeMapPath, '/project/maps/alpha.json');
      expect(notifier.state.isDirty, isTrue);
      expect(fixture.repository.savedPaths, isEmpty);
      expect(fixture.repository.loadedPaths, isEmpty);
    });

    test('failed target load never replaces or cleans the source', () async {
      final fixture = _ActivationFixture();
      fixture.repository.mapsByPath.remove('/project/maps/beta.json');
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );

      expect(outcome, MapActivationOutcome.failed);
      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.activeMapPath, '/project/maps/alpha.json');
      expect(notifier.state.savedMapSnapshot, same(_alphaSaved));
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.mapUndoStack, isNotEmpty);
    });

    test('rejects a target whose persisted ID disagrees with the manifest',
        () async {
      final fixture = _ActivationFixture();
      fixture.repository.mapsByPath['/project/maps/beta.json'] =
          _beta.copyWith(id: 'wrong');
      final notifier = fixture.notifier..state = _cleanSourceState();

      final outcome = await notifier.activateMap('maps/beta.json');

      expect(outcome, MapActivationOutcome.failed);
      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.activeMapPath, '/project/maps/alpha.json');
      expect(notifier.state.isDirty, isFalse);
    });

    test('rejects a second concurrent activation as busy', () async {
      final loadStarted = Completer<void>();
      final releaseLoad = Completer<MapData>();
      final fixture = _ActivationFixture(
        loadHandler: (path) {
          if (path == '/project/maps/beta.json') {
            if (!loadStarted.isCompleted) loadStarted.complete();
            return releaseLoad.future;
          }
          return Future<MapData>.value(_gamma);
        },
      );
      final notifier = fixture.notifier..state = _cleanSourceState();

      final first = notifier.activateMap('maps/beta.json');
      await loadStarted.future;
      final second = await notifier.activateMap('maps/gamma.json');

      expect(second, MapActivationOutcome.busy);
      releaseLoad.complete(_beta);
      expect(await first, MapActivationOutcome.activated);
      expect(notifier.state.activeMap, same(_beta));
    });

    test('a dirty Discard load owns the gateway until adoption completes',
        () async {
      final loadStarted = Completer<void>();
      final releaseLoad = Completer<MapData>();
      final fixture = _ActivationFixture(
        loadHandler: (path) {
          if (path == '/project/maps/beta.json') {
            if (!loadStarted.isCompleted) loadStarted.complete();
            return releaseLoad.future;
          }
          return Future<MapData>.value(_gamma);
        },
      );
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
      );
      final first = notifier.activateMap(
        'maps/beta.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
      );
      await loadStarted.future;

      expect(
        await notifier.activateMap('maps/gamma.json'),
        MapActivationOutcome.busy,
      );
      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.busy,
      );

      releaseLoad.complete(_beta);
      expect(await first, MapActivationOutcome.activated);
      expect(notifier.state.activeMap, same(_beta));
      expect(fixture.projectRepository.loadedPaths, isEmpty);
    });

    test('only one dirty activation decision can be pending', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      final first = await notifier.activateMap('maps/beta.json');
      final second = await notifier.activateMap('maps/gamma.json');

      expect(first, MapActivationOutcome.requiresDecision);
      expect(second, MapActivationOutcome.busy);
      expect(
        await notifier.activateMap(
          'maps/beta.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationOutcome.cancelled,
      );
      expect(
        await notifier.activateMap('maps/gamma.json'),
        MapActivationOutcome.requiresDecision,
      );
    });

    test('connected-map check and cancel preserve an in-progress stroke',
        () async {
      final fixture = _ActivationFixture();
      const strokeStart = MapHistorySnapshot(map: _alphaSaved);
      final connectedAlpha = _alphaEdited.copyWith(
        connections: const <MapConnection>[
          MapConnection(
            direction: MapConnectionDirection.north,
            targetMapId: 'beta',
            offset: 0,
          ),
        ],
      );
      final before = _dirtySourceState().copyWith(
        activeMap: connectedAlpha,
        mapStrokeStart: strokeStart,
      );
      final notifier = fixture.notifier..state = before;

      final check = await notifier.activateConnectedMap(
        MapConnectionDirection.north,
      );
      expect(check, MapActivationOutcome.requiresDecision);
      expect(notifier.state, before);

      final cancelled = await notifier.activateConnectedMap(
        MapConnectionDirection.north,
        dirtyDecision: DirtyMapActivationDecision.cancel,
      );
      expect(cancelled, MapActivationOutcome.cancelled);
      expect(notifier.state, before);
      expect(fixture.repository.loadedPaths, isEmpty);
      expect(fixture.repository.savedPaths, isEmpty);
    });
  });

  group('project session replacement interlock', () {
    test('clean project activation owns the lease before repository I/O',
        () async {
      final loadStarted = Completer<void>();
      final releaseLoad = Completer<ProjectManifest>();
      final fixture = _ActivationFixture(
        projectLoadHandler: (path) {
          if (!loadStarted.isCompleted) loadStarted.complete();
          return releaseLoad.future;
        },
      );
      final notifier = fixture.notifier..state = _cleanSourceState();

      final activation = notifier.activateProject(
        '/other/project.json',
        rememberAsRecent: false,
      );
      await loadStarted.future;

      expect(notifier.state.isSaving, isTrue);
      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.busy,
      );
      releaseLoad.complete(_project);
      expect(await activation, MapActivationOutcome.activated);
      expect(notifier.state.isSaving, isFalse);
    });

    test('clean project authorization rejects a microtask document change',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _cleanSourceState();

      scheduleMicrotask(() {
        notifier.state = notifier.state.copyWith(
          activeMap: notifier.state.activeMap!.copyWith(name: 'Async result'),
          isDirty: true,
        );
      });
      final activation = notifier.activateProject(
        '/other/project.json',
        rememberAsRecent: false,
      );

      expect(await activation, MapActivationOutcome.unavailable);
      expect(fixture.projectRepository.loadedPaths, isEmpty);
      expect(notifier.state.activeMap!.name, 'Async result');
      expect(notifier.state.isDirty, isTrue);
    });

    test('dirty project load requires a handshake and Cancel preserves source',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier;
      final before = _dirtySourceState();
      notifier.state = before;

      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.requiresDecision,
      );
      expect(fixture.projectRepository.loadedPaths, isEmpty);

      expect(
        await notifier.activateProject(
          '/other/project.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
          rememberAsRecent: false,
        ),
        MapActivationOutcome.cancelled,
      );
      expect(notifier.state, before);
      fixture.expectNoLifecycleIo();
    });

    test('Discard loads the project only after the exact handshake', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.requiresDecision,
      );
      final outcome = await notifier.activateProject(
        '/other/project.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
        rememberAsRecent: false,
      );

      expect(outcome, MapActivationOutcome.activated);
      expect(
        fixture.projectRepository.loadedPaths,
        <String>['/other/project.json'],
      );
      expect(notifier.state.activeMap, isNull);
      expect(notifier.state.activeMapPath, isNull);
      expect(notifier.state.isDirty, isFalse);
    });

    test(
        'project Discard is rejected if the active map changed while prompting',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.requiresDecision,
      );
      final replacement = notifier.state.copyWith(
        activeMap: notifier.state.activeMap!.copyWith(name: 'Async result'),
      );
      notifier.state = replacement;

      final outcome = await notifier.activateProject(
        '/other/project.json',
        dirtyDecision: DirtyMapActivationDecision.discard,
        rememberAsRecent: false,
      );

      expect(outcome, MapActivationOutcome.unavailable);
      expect(notifier.state, replacement);
      fixture.expectNoLifecycleIo();
    });

    test('low-level project wrappers cannot silently replace a dirty map',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier;
      final before = _dirtySourceState();
      notifier.state = before;

      await notifier.loadProject(
        '/other/project.json',
        rememberAsRecent: false,
      );
      await notifier.createProject('Other', '/other');

      expect(notifier.state, before);
      fixture.expectNoLifecycleIo();
      expect(
        await notifier.activateMap('maps/beta.json'),
        MapActivationOutcome.requiresDecision,
        reason: 'Compatibility wrappers must release their pending handshake.',
      );
      expect(
        await notifier.activateMap(
          'maps/beta.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationOutcome.cancelled,
      );
    });

    test('pending Border preview protects project open and creation', () async {
      final fixture = _ActivationFixture();
      final map = _beginPendingAlphaBorderPreview(fixture);
      final notifier = fixture.notifier;

      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.requiresDecision,
      );
      expect(
        await notifier.activateProject(
          '/other/project.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
          rememberAsRecent: false,
        ),
        MapActivationOutcome.cancelled,
      );
      expect(
        await notifier.createAndActivateProject('Other', '/other'),
        MapActivationOutcome.requiresDecision,
      );
      expect(
        await notifier.createAndActivateProject(
          'Other',
          '/other',
          dirtyDecision: DirtyMapActivationDecision.cancel,
        ),
        MapActivationOutcome.cancelled,
      );

      expect(notifier.state.activeMap, same(map));
      expect(fixture.preview.current.hasPendingPreview, isTrue);
      fixture.expectNoLifecycleIo();
    });

    test('project-dirty state also requires an explicit replacement decision',
        () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(isProjectDirty: true);

      expect(
        await notifier.activateProject(
          '/other/project.json',
          rememberAsRecent: false,
        ),
        MapActivationOutcome.requiresDecision,
      );
      expect(fixture.projectRepository.loadedPaths, isEmpty);
      expect(
        await notifier.activateProject(
          '/other/project.json',
          dirtyDecision: DirtyMapActivationDecision.cancel,
          rememberAsRecent: false,
        ),
        MapActivationOutcome.cancelled,
      );
      expect(notifier.state.isProjectDirty, isTrue);
      fixture.expectNoLifecycleIo();
    });
  });

  group('DS-04 map dependency preflight handoff', () {
    test('rename returns canonical incoming usages to the UI', () async {
      final fixture = _ActivationFixture();
      fixture.repository.mapsByPath['/project/maps/beta.json'] = _beta.copyWith(
        warps: const <MapWarp>[
          MapWarp(
            id: 'to_alpha',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'alpha',
            targetPos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      final notifier = fixture.notifier..state = _cleanSourceState();

      final result = await notifier.renameMap('alpha', 'delta');

      expect(result, isNotNull);
      expect(result!.operation, MapDependencyPreflightOperation.rename);
      expect(
        result.inspection.usages.single.path,
        'maps[beta].warps[0].targetMapId',
      );
      expect(
        result.inspection.usages.single.navigationIntent?.mapId,
        'beta',
      );
      expect(notifier.state.errorMessage, result.blockingMessage);
      expect(fixture.repository.savedPaths, isEmpty);
      expect(fixture.repository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });

    test('delete returns incomplete-index diagnostics to the UI', () async {
      final fixture = _ActivationFixture();
      fixture.repository.mapsByPath.remove('/project/maps/gamma.json');
      final notifier = fixture.notifier..state = _cleanSourceState();

      final result = await notifier.deleteMap('beta');

      expect(result, isNotNull);
      expect(result!.operation, MapDependencyPreflightOperation.delete);
      expect(result.isComplete, isFalse);
      expect(
        result.indexIssues.single.kind,
        MapDependencyIndexIssueKind.unreadableMap,
      );
      expect(result.indexIssues.single.mapId, 'gamma');
      expect(notifier.state.errorMessage, result.blockingMessage);
      expect(fixture.repository.savedPaths, isEmpty);
      expect(fixture.repository.deletedPaths, isEmpty);
      expect(fixture.projectRepository.savedProjects, isEmpty);
    });
  });

  group('dirty active-map lifecycle interlock', () {
    test('create cannot replace a dirty active map', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      await notifier.createMap('delta', 8, 8);

      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.isDirty, isTrue);
      fixture.expectNoLifecycleIo();
    });

    test('rename cannot mutate the dirty active map on disk', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      await notifier.renameMap('alpha', 'delta');

      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.isDirty, isTrue);
      fixture.expectNoLifecycleIo();
    });

    test('delete cannot remove the dirty active map from disk', () async {
      final fixture = _ActivationFixture();
      final notifier = fixture.notifier..state = _dirtySourceState();

      await notifier.deleteMap('alpha');

      expect(notifier.state.activeMap, same(_alphaEdited));
      expect(notifier.state.isDirty, isTrue);
      fixture.expectNoLifecycleIo();
    });

    test('legacy active map stays read-only before a stroke can begin', () {
      final fixture = _ActivationFixture();
      final legacy = _alphaEdited.copyWith(id: '../legacy');
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(
          activeMap: legacy,
          savedMapSnapshot: legacy,
        );

      notifier.beginMapStroke();

      expect(notifier.state.mapStrokeStart, isNull);
      expect(notifier.state.errorMessage, contains('lecture seule'));
      fixture.expectNoLifecycleIo();
    });

    test('pending Border preview blocks every map lifecycle replacement',
        () async {
      final fixture = _ActivationFixture();
      final map = _beginPendingAlphaBorderPreview(fixture);
      final notifier = fixture.notifier;

      await notifier.createMap('delta', 8, 8);
      await notifier.renameMap('beta', 'delta');
      await notifier.deleteMap('beta');
      await notifier.duplicateMap('beta');

      expect(notifier.state.activeMap, same(map));
      expect(fixture.preview.current.hasPendingPreview, isTrue);
      expect(notifier.state.errorMessage, contains('aperçu de bordure'));
      fixture.expectNoLifecycleIo();
    });

    test('pending Border preview blocks direct map writers', () async {
      final fixture = _ActivationFixture();
      final map = _beginPendingAlphaBorderPreview(fixture);
      final notifier = fixture.notifier;

      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 0, y: 0),
        kind: NarrativeEventPhysicalSourceKind.npc,
      );
      final writeLease = notifier.beginNarrativeEventSourceMapWriteLease();
      await notifier.assignTilesetToActiveLayer('secondary');
      await notifier.createReciprocalWarpForSelectedWarp();

      expect(proposal, isNull);
      expect(writeLease, isNull);
      expect(notifier.state.activeMap, same(map));
      expect(fixture.preview.current.hasPendingPreview, isTrue);
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.errorMessage, contains('aperçu de bordure'));
      fixture.expectNoLifecycleIo();
    });

    test('legacy active map blocks every direct map writer', () async {
      final fixture = _ActivationFixture();
      final legacy = _alphaWithBorder().copyWith(id: '../legacy');
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(
          project: _projectWithTilesets,
          activeMap: legacy,
          activeMapPath: '/project/maps/legacy.json',
          savedMapSnapshot: legacy,
          activeLayerId: 'ground',
          selectedWarpId: 'north_exit',
        );

      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 0, y: 0),
        kind: NarrativeEventPhysicalSourceKind.npc,
      );
      final writeLease = notifier.beginNarrativeEventSourceMapWriteLease();
      await notifier.assignTilesetToActiveLayer('secondary');
      await notifier.createReciprocalWarpForSelectedWarp();

      expect(proposal, isNull);
      expect(writeLease, isNull);
      expect(notifier.state.activeMap, same(legacy));
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.errorMessage, contains('lecture seule'));
      fixture.expectNoLifecycleIo();
    });

    test('ambiguous manifest path ownership makes direct writers read-only',
        () async {
      final fixture = _ActivationFixture();
      final ambiguousProject = _project.copyWith(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/shared.json',
          ),
          ProjectMapEntry(
            id: 'beta',
            name: 'Beta',
            relativePath: 'maps/SHARED.json',
          ),
        ],
      );
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(project: ambiguousProject);

      expect(
        await notifier.saveActiveMap(),
        ActiveMapSaveOutcome.unavailable,
      );
      expect(notifier.beginNarrativeEventSourceMapWriteLease(), isNull);

      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.errorMessage, contains('lecture seule'));
      fixture.expectNoLifecycleIo();
    });

    test('canonical map cannot write a reciprocal warp into a legacy target',
        () async {
      final fixture = _ActivationFixture();
      final source = _alphaWithBorder().copyWith(
        warps: const <MapWarp>[
          MapWarp(
            id: 'legacy_exit',
            pos: GridPos(x: 0, y: 0),
            targetMapId: '../legacy',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final project = _projectWithTilesets.copyWith(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'alpha',
            name: 'Alpha',
            relativePath: 'maps/alpha.json',
          ),
          ProjectMapEntry(
            id: '../legacy',
            name: 'Legacy',
            relativePath: 'maps/legacy.json',
          ),
        ],
      );
      final notifier = fixture.notifier
        ..state = _cleanSourceState().copyWith(
          project: project,
          activeMap: source,
          savedMapSnapshot: source,
          activeLayerId: 'ground',
          selectedWarpId: 'legacy_exit',
        );

      await notifier.createReciprocalWarpForSelectedWarp();

      expect(notifier.state.activeMap, same(source));
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.errorMessage, contains('lecture seule'));
      fixture.expectNoLifecycleIo();
    });
  });
}

const _alphaSaved = MapData(
  id: 'alpha',
  name: 'Alpha saved',
  size: GridSize(width: 2, height: 2),
);
const _alphaEdited = MapData(
  id: 'alpha',
  name: 'Alpha edited',
  size: GridSize(width: 2, height: 2),
);
const _beta = MapData(
  id: 'beta',
  name: 'Beta',
  size: GridSize(width: 2, height: 2),
);
const _gamma = MapData(
  id: 'gamma',
  name: 'Gamma',
  size: GridSize(width: 2, height: 2),
);

const _project = ProjectManifest(
  name: 'Demo',
  tilesets: <ProjectTilesetEntry>[],
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'alpha',
      name: 'Alpha',
      relativePath: 'maps/alpha.json',
    ),
    ProjectMapEntry(
      id: 'beta',
      name: 'Beta',
      relativePath: 'maps/beta.json',
    ),
    ProjectMapEntry(
      id: 'gamma',
      name: 'Gamma',
      relativePath: 'maps/gamma.json',
    ),
  ],
);

final _projectWithTilesets = _project.copyWith(
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'primary',
      name: 'Primary',
      relativePath: 'tilesets/primary.png',
    ),
    ProjectTilesetEntry(
      id: 'secondary',
      name: 'Secondary',
      relativePath: 'tilesets/secondary.png',
    ),
  ],
);

EditorState _dirtySourceState() => const EditorState(
      projectRootPath: '/project',
      project: _project,
      activeMap: _alphaEdited,
      activeMapPath: '/project/maps/alpha.json',
      savedMapSnapshot: _alphaSaved,
      activeLayerId: 'decor',
      zoom: 1.75,
      panOffset: Offset(13, -8),
      mapUndoStack: <MapHistorySnapshot>[
        MapHistorySnapshot(map: _alphaSaved),
      ],
      canUndoMap: true,
      isDirty: true,
    );

EditorState _cleanSourceState() => _dirtySourceState().copyWith(
      savedMapSnapshot: _alphaEdited,
      mapUndoStack: const <MapHistorySnapshot>[],
      canUndoMap: false,
      isDirty: false,
    );

MapData _alphaWithBorder() => MapData(
      id: 'alpha',
      name: 'Alpha with Border preview',
      size: const GridSize(width: 2, height: 2),
      layers: <MapLayer>[
        const TileLayer(
          id: 'ground',
          name: 'Sol',
          tilesetId: 'primary',
          tiles: <int>[0, 0, 0, 0],
        ),
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            features: <BorderFeature>[
              BorderFeature(
                id: 'coast',
                name: 'Côte',
                blueprintId: 'coast-blueprint',
                seed: BorderSignedInt64.fromInt(7),
                geometry: BorderRegionGeometry(
                  width: 2,
                  height: 2,
                  cells: const <bool>[true, false, false, false],
                ),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
              ),
            ],
          ),
        ),
      ],
      warps: const <MapWarp>[
        MapWarp(
          id: 'north_exit',
          pos: GridPos(x: 0, y: 0),
          targetMapId: 'beta',
          targetPos: GridPos(x: 0, y: 0),
        ),
      ],
    );

MapData _beginPendingAlphaBorderPreview(_ActivationFixture fixture) {
  final map = _alphaWithBorder();
  fixture.notifier.state = _cleanSourceState().copyWith(
    project: _projectWithTilesets,
    activeMap: map,
    savedMapSnapshot: map,
    activeLayerId: 'ground',
    selectedWarpId: 'north_exit',
  );
  fixture.preview.begin(
    map: map,
    layerId: 'borders',
    featureId: 'coast',
    context: createEditorBorderPreviewContext(
      projectRootPath: '/project',
      activeMapPath: '/project/maps/alpha.json',
      project: _projectWithTilesets,
      map: map,
    ),
  );
  return map;
}

final class _ActivationFixture {
  _ActivationFixture({
    Object? saveError,
    Future<MapData> Function(String path)? loadHandler,
    Future<ProjectManifest> Function(String path)? projectLoadHandler,
  })  : preview = BorderPreviewController(),
        repository = _ActivationMapRepository(
          saveError: saveError,
          loadHandler: loadHandler,
        ),
        projectRepository = _ActivationProjectRepository(
          loadHandler: projectLoadHandler,
        ) {
    container = ProviderContainer(
      overrides: <Override>[
        mapRepositoryProvider.overrideWith((ref) => repository),
        saveMapUseCaseProvider.overrideWith(
          (ref) => SaveMapUseCase(repository),
        ),
        projectRepositoryProvider.overrideWith((ref) => projectRepository),
        projectWorkspaceFactoryProvider.overrideWith(
          (ref) => const _ActivationWorkspaceFactory(),
        ),
        editorAuthoringSessionLifecycleProvider.overrideWith(
          (ref) => EditorAuthoringSessionLifecycle(
            fileReader: const _ActivationProjectFileReader(),
          ),
        ),
        borderPreviewControllerProvider.overrideWith((ref) => preview),
      ],
    );
    addTearDown(container.dispose);
  }

  final _ActivationMapRepository repository;
  final _ActivationProjectRepository projectRepository;
  final BorderPreviewController preview;
  late final ProviderContainer container;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  void expectNoLifecycleIo() {
    expect(repository.loadedPaths, isEmpty);
    expect(repository.savedPaths, isEmpty);
    expect(repository.deletedPaths, isEmpty);
    expect(projectRepository.savedProjects, isEmpty);
  }
}

final class _ActivationProjectFileReader implements ProjectFileReader {
  const _ActivationProjectFileReader();

  @override
  Future<String> canonicalizeDirectory(String path) async => path;

  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    throw UnsupportedError('Activation lifecycle tests do not read files.');
  }
}

final class _ActivationWorkspaceFactory implements ProjectWorkspaceFactory {
  const _ActivationWorkspaceFactory();

  @override
  ProjectWorkspace create(String projectRoot) =>
      _ActivationWorkspace(projectRoot);
}

final class _ActivationWorkspace implements ProjectWorkspace {
  const _ActivationWorkspace(this.projectRoot);

  @override
  final String projectRoot;

  @override
  String get projectManifestPath => '$projectRoot/project.json';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '$projectRoot/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async =>
      '$projectRoot/tilesets/imported.png';

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '$projectRoot/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

final class _ActivationMapRepository implements RevisionedMapRepository {
  _ActivationMapRepository({
    this.saveError,
    this.loadHandler,
  });

  final Object? saveError;
  final Future<MapData> Function(String path)? loadHandler;
  final Map<String, MapData> mapsByPath = <String, MapData>{
    '/project/maps/alpha.json': _alphaSaved,
    '/project/maps/beta.json': _beta,
    '/project/maps/gamma.json': _gamma,
  };
  final List<String> loadedPaths = <String>[];
  final List<String> savedPaths = <String>[];
  final List<String> deletedPaths = <String>[];
  final List<MapData> savedMaps = <MapData>[];
  final List<String> callOrder = <String>[];

  @override
  Future<void> deleteMap(String path) async {
    deletedPaths.add(path);
  }

  @override
  Future<MapData> loadMap(String path) async {
    loadedPaths.add(path);
    callOrder.add('load:$path');
    final customHandler = loadHandler;
    if (customHandler != null) return customHandler(path);
    final map = mapsByPath[path];
    if (map == null) throw StateError('Missing map: $path');
    return map;
  }

  @override
  Future<RevisionedMapDocument> loadMapDocument(String path) async {
    final map = await loadMap(path);
    return RevisionedMapDocument(
      map: map,
      revision: mapDocumentRevisionFor(map),
    );
  }

  @override
  Future<RevisionedMapDocument> saveMapDocument(
    MapData map,
    String path, {
    required MapDocumentWritePrecondition precondition,
    ProjectManifest? projectDialogueContext,
  }) async {
    await saveMap(
      map,
      path,
      projectDialogueContext: projectDialogueContext,
    );
    mapsByPath[path] = map;
    return RevisionedMapDocument(
      map: map,
      revision: mapDocumentRevisionFor(map),
    );
  }

  @override
  Future<void> deleteMapDocument(
    String path, {
    required String expectedRevision,
  }) =>
      deleteMap(path);

  @override
  Future<MapDocumentRecoveryResult> recoverMapDocument(String path) async {
    final map = mapsByPath[path];
    return MapDocumentRecoveryResult(
      status: MapDocumentRecoveryStatus.clear,
      targetPath: path,
      revision: map == null ? null : mapDocumentRevisionFor(map),
    );
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) async {}

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    savedPaths.add(path);
    savedMaps.add(map);
    callOrder.add('save:$path');
    final failure = saveError;
    if (failure != null) throw failure;
  }
}

final class _ActivationProjectRepository implements ProjectRepository {
  _ActivationProjectRepository({this.loadHandler});

  final Future<ProjectManifest> Function(String path)? loadHandler;
  final List<String> loadedPaths = <String>[];
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) async {
    loadedPaths.add(path);
    final customHandler = loadHandler;
    if (customHandler != null) return customHandler(path);
    return _project;
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    savedProjects.add(project);
  }
}
