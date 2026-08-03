import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core_providers.dart'
    as editor_core;
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/use_case_providers.dart'
    as editor_use_cases;
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/ports/narrative_event_spatial_source_creation_gateway.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_preview_transaction.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import 'package:map_editor/src/ui/canvas/events/narrative_event_map_return_panel.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:path/path.dart' as p;

import '../../support/event_registry_persistence_fixtures.dart';

const _eventId = 'evt_019abcde-0000-7000-8000-000000000361';

void main() {
  group('NS-EVENT-V2-25 map source creation banner', () {
    testWidgets(
        'source-less CTA exposes five types and map tap previews before legacy callback',
        (tester) async {
      final sourceGateway = _RecordingSourceGateway();
      final registryGateway = _RecordingRegistryGateway();
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _map();
      final project = _project();
      final beforeMapHash = narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(map.toJson()),
      );
      final beforeManifestHash = narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(project.toJson()),
      );
      notifier.state = EditorState(
        projectRootPath: '/project',
        project: project,
        activeMap: map,
        savedMapSnapshot: map,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      var legacyPositionCalls = 0;
      await _pump(
        tester,
        container,
        onLegacyPosition: (_) => legacyPositionCalls++,
      );

      await _openCreationFromEventPanel(tester, controller);

      expect(notifier.state.workspaceMode, EditorWorkspaceMode.map);
      expect(
        controller.state.navigationMode,
        NarrativeEventMapNavigationMode.create,
      );
      for (final kind in NarrativeEventPhysicalSourceKind.values) {
        expect(
          find.byKey(ValueKey('narrative-event-create-kind-${kind.name}')),
          findsOneWidget,
        );
      }
      expect(find.textContaining('layerId'), findsNothing);
      expect(find.textContaining('coordonnée'), findsNothing);
      expect(find.textContaining('Choisir une map'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-create-kind-sign')),
      );
      await tester.pump();
      await tester.tapAt(const Offset(600, 400));
      await tester.pump();

      final proposal = controller.state.sourceCreationProposal;
      expect(proposal, isNotNull);
      expect(proposal!.physicalKind, NarrativeEventPhysicalSourceKind.sign);
      expect(notifier.state.activeMap, same(map));
      expect(notifier.state.isDirty, isFalse);
      expect(legacyPositionCalls, 0);
      expect(sourceGateway.commitCalls, 0);
      expect(registryGateway.persistCalls, 0);
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('narrative-event-create-cancel-preview'),
          ),
          matching: find.text('Annuler'),
        ),
        findsOneWidget,
      );
      expect(find.text('Annuler l’aperçu'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('narrative-event-create-confirm'),
          ),
          matching: find.text('Enregistrer et lier'),
        ),
        findsOneWidget,
      );
      expect(find.text('Créer et lier'), findsNothing);

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cancel-preview'),
        ),
      );
      await tester.pump();

      expect(controller.state.sourceCreationProposal, isNull);
      expect(sourceGateway.commitCalls, 0);
      expect(registryGateway.persistCalls, 0);
      expect(notifier.state.activeMap, same(map));
      final afterCancelMapHash = narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(
          notifier.state.activeMap!.toJson(),
        ),
      );
      final afterCancelManifestHash = narrativeEventBytesFingerprint(
        canonicalizeNarrativeEventJsonUtf8(
          notifier.state.project!.toJson(),
        ),
      );
      expect(afterCancelMapHash, beforeMapHash);
      expect(afterCancelManifestHash, beforeManifestHash);
      // Machine-readable proof that cancelling a preview performs no map or
      // manifest write before the durable two-commit workflow starts.
      // ignore: avoid_print
      print(
        'PHASE_G_CANCEL_HASH_TRACE ${jsonEncode({
              'before': {
                'map': beforeMapHash,
                'manifest': beforeManifestHash,
                'journal': 'absent',
              },
              'afterCancel': {
                'map': afterCancelMapHash,
                'manifest': afterCancelManifestHash,
                'journal': 'absent',
              },
            })}',
      );
    });

    testWidgets(
        'confirm persists map then Event and returns to the exact draft',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final steps = <String>[];
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
        steps: steps,
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
        steps: steps,
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: map,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: map,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey('narrative-event-create-kind-zone1x1'),
            ),
          )
          .onPressed!();
      await tester.pump();
      expect(
        controller.state.sourceCreationKind,
        NarrativeEventPhysicalSourceKind.zone1x1,
      );
      expect(
        controller.state.navigationMode,
        NarrativeEventMapNavigationMode.create,
      );
      await tester.tapAt(const Offset(600, 400));
      await tester.pump();

      expect(controller.state.sourceCreationProposal, isNotNull);
      expect(notifier.state.isDirty, isFalse);
      expect(notifier.state.isProjectDirty, isFalse);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-confirm'),
              ),
            )
            .onPressed,
        isNotNull,
      );

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-confirm')),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult != null) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Source creation did not complete within two seconds.');
      });
      await tester.pump();

      expect(
        controller.state.lastSourceCreationResult?.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
        reason:
            '${controller.state.lastSourceCreationResult?.code}: ${controller.state.lastSourceCreationResult?.message}',
      );
      expect(steps, ['map', 'registry', 'finalize']);
      expect(sourceGateway.commitCalls, 1);
      expect(sourceGateway.acknowledgeCalls, 1);
      expect(registryGateway.persistCalls, 1);
      expect(notifier.state.workspaceMode, EditorWorkspaceMode.events);
      expect(controller.state.selectedNarrativeEventV2Id, _eventId);
      expect(controller.state.pendingReturn, isNull);
      expect(notifier.state.activeMap!.triggers, hasLength(1));
      expect(notifier.state.isDirty, isFalse);
      expect(
        notifier
            .state.project!.eventRegistry!.records.single.draftOrNull!.source,
        NarrativeEventSourceRef.triggerEnter(
          'map_a',
          notifier.state.activeMap!.triggers.single.id,
        ),
      );
      final diskMap = (await tester.runAsync(() async {
        return MapData.fromJson(
          Map<String, dynamic>.from(
            decodeNarrativeEventJsonStrict(
              await File(fixture.session.mapPaths['map_a']!).readAsString(),
            ) as Map,
          ),
        );
      }))!;
      expect(diskMap.triggers, hasLength(1));
      expect(
        (await tester.runAsync(
          () => sourceGateway.inspectProject(fixture.projectPath),
        ))!
            .status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    testWidgets('busy state blocks double submit and cancel until commit ends',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      var allowPrepare = false;
      final sourceGateway = _RecordingSourceGateway(
        syntheticCommit: true,
      );
      final registryGateway = _RecordingRegistryGateway(
        syntheticCommit: true,
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
        explicitUseCase: NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: sourceGateway,
          registryGateway: registryGateway,
          prepareSession: (_) async {
            while (!allowPrepare) {
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            return fixture.session;
          },
          operationIdFactory: () => 'banner_busy_source',
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: map,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: map,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-create-kind-item')),
      );
      await tester.pump();
      await tester.tapAt(const Offset(600, 400));
      await tester.pump();

      expect(controller.state.sourceCreationProposal, isNotNull);
      expect(controller.state.projectRootPath, notifier.state.projectRootPath);
      expect(controller.state.pendingReturn, isNotNull);
      expect(
        controller.state.navigationMode,
        NarrativeEventMapNavigationMode.create,
      );
      expect(controller.state.isSourceCreationBusy, isFalse);

      await tester.runAsync(() async {
        final token = controller.state.pendingReturn;
        final pending = controller.confirmSourceCreation(
          projectRootPath: notifier.state.projectRootPath,
          project: notifier.state.project!,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap:
              notifier.adoptPersistedNarrativeEventSourceProposal,
          applyPersistedRegistry: notifier.applyPersistedNarrativeEventRegistry,
        );
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.isSourceCreationBusy, isTrue);
        expect(sourceGateway.commitCalls, 0);
        final duplicate = await controller.confirmSourceCreation(
          projectRootPath: notifier.state.projectRootPath,
          project: notifier.state.project!,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap:
              notifier.adoptPersistedNarrativeEventSourceProposal,
          applyPersistedRegistry: notifier.applyPersistedNarrativeEventRegistry,
        );
        expect(duplicate?.code, 'sourceCreationInProgress');
        controller.cancelMapNavigation();
        expect(controller.state.pendingReturn, same(token));
        allowPrepare = true;
        await pending.timeout(const Duration(seconds: 2));
      });
      await tester.pump();

      expect(sourceGateway.commitCalls, 1);
      expect(
        controller.state.lastSourceCreationResult?.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
        reason:
            '${controller.state.lastSourceCreationResult?.code}: ${controller.state.lastSourceCreationResult?.message}',
      );
      expect(controller.state.lastSourceCreationResult?.code, 'sourceMissing');
      expect(registryGateway.persistCalls, 0);
    });

    testWidgets(
        'source map commit publishes the shared lease before rename and blocks a stale normal save',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final beforeMapRename = Completer<void>();
      final releaseMapRename = Completer<void>();
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(
          faultInjector: (checkpoint) async {
            if (checkpoint !=
                NarrativeEventSpatialLinkCheckpoint.beforeMapRename) {
              return;
            }
            if (!beforeMapRename.isCompleted) beforeMapRename.complete();
            await releaseMapRename.future;
          },
        ),
      );
      final mapRepository = _RejectingMapRepository();
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
        mapRepository: mapRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: map,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: map,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      tester
          .widget<PokeMapButton>(
            find.byKey(
              const ValueKey('narrative-event-create-kind-sign'),
            ),
          )
          .onPressed!();
      await tester.pump();
      await tester.tapAt(const Offset(600, 400));
      await tester.pump();

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-confirm')),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (beforeMapRename.isCompleted) return;
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult != null) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Source commit did not reach map rename: '
            '${controller.state.lastSourceCreationResult?.code} / '
            '${controller.state.lastSourceCreationResult?.message}; '
            'commit calls=${sourceGateway.commitCalls}.');
      });

      expect(
        notifier.state.isSaving,
        isTrue,
        reason: 'The Event writer must publish the shared map lease.',
      );
      final sourceBaseline = notifier.state.activeMap;
      notifier.addEntityAt(
        const GridPos(x: 8, y: 8),
        kind: MapEntityKind.custom,
      );
      expect(
        notifier.state.activeMap,
        same(sourceBaseline),
        reason: 'Map edits must not invalidate source adoption mid-commit.',
      );
      final competingProposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 9, y: 9),
        kind: NarrativeEventPhysicalSourceKind.item,
      );
      expect(competingProposal, isNotNull);
      expect(
        notifier.adoptPersistedNarrativeEventSourceProposal(
          competingProposal!,
        ),
        isFalse,
        reason: 'Only the lease owner may adopt a persisted map proposal.',
      );
      expect(notifier.state.activeMap, same(sourceBaseline));
      await tester.runAsync(notifier.saveActiveMap);
      expect(
        mapRepository.operationCalls,
        0,
        reason: 'A stale normal save must not enter map IO during commit.',
      );

      await tester.runAsync(() async {
        releaseMapRename.complete();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.committed) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Source creation did not finish after releasing its map rename.');
      });
      await tester.pump();

      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.activeMap!.entities, hasLength(1));
      final diskMap = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(diskMap.entities, hasLength(1));
    });

    testWidgets(
        'normal project reload owns the lease before IO and Event reload reuses its owner token',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final projectRepository = _SuspendingProjectRepository(
        FileProjectRepository(),
      );
      final container = _container(
        sourceGateway: _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
        ),
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
        projectRepository: projectRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: map,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: map,
      );

      late final Future<MapActivationOutcome> normalReload;
      await tester.runAsync(() async {
        normalReload = notifier.activateProject(
          fixture.projectPath,
          rememberAsRecent: false,
        );
        await _waitForProjectLoadStarted(projectRepository);
      });
      expect(notifier.state.isSaving, isTrue);
      expect(
        notifier.beginNarrativeEventSourceMapWriteLease(),
        isNull,
        reason: 'An Event writer must not overtake a normal project reload.',
      );

      await tester.runAsync(() async {
        projectRepository.releaseLoad.complete();
        expect(
          await normalReload.timeout(const Duration(seconds: 2)),
          MapActivationOutcome.activated,
        );
      });
      expect(notifier.state.isSaving, isFalse);

      final ownerToken = notifier.beginNarrativeEventSourceMapWriteLease();
      expect(ownerToken, isNotNull);
      await tester.runAsync(
        () => notifier.loadProject(
          fixture.projectPath,
          rememberAsRecent: false,
          mapWriteLeaseToken: ownerToken,
        ),
      );
      expect(notifier.state.isSaving, isTrue);
      await tester.runAsync(
        () => notifier.loadMap(
          'maps/map_a.json',
          mapWriteLeaseToken: ownerToken,
        ),
      );
      expect(notifier.state.isSaving, isTrue);
      notifier.endNarrativeEventSourceMapWriteLease(ownerToken!);
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.activeMap, map);
    });

    testWidgets(
        'failed memory adoption keeps the durable journal and gates false recovery exits',
        (tester) async {
      final map = _mapWithBorderPreviewTarget();
      final project = _project().copyWith(version: ProjectVersion.v6);
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
      );
      final projectRepository =
          _SuspendingProjectRepository(FileProjectRepository());
      final mapRepository =
          _LoadDelegatingRejectingSaveMapRepository(FileMapRepository());
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
        mapRepository: mapRepository,
        projectRepository: projectRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: map,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: map,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-create-kind-sign')),
      );
      await tester.pump();
      await tester.tapAt(const Offset(600, 400));
      await tester.pump();

      var registryAdoptions = 0;
      final result = await tester.runAsync(
        () => controller.confirmSourceCreation(
          projectRootPath: notifier.state.projectRootPath,
          project: notifier.state.project!,
          mapDirty: false,
          projectDirty: false,
          saving: false,
          adoptPersistedMap: (_) => false,
          applyPersistedRegistry: ({
            required expectedProjectRootPath,
            required expectedPreviousRegistry,
            required nextRegistry,
          }) {
            registryAdoptions++;
            return true;
          },
        ),
      );
      await tester.pump();

      expect(
        result?.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(result?.code, 'committedMapOutOfSync');
      expect(result?.journal?.state,
          NarrativeEventSpatialLinkJournalState.eventCommitted);
      expect(registryAdoptions, 0);
      expect(sourceGateway.acknowledgeCalls, 0);
      expect(
          await tester
              .runAsync(() => File(result!.journal!.journalPath).exists()),
          isTrue);
      expect(
        find.byKey(const ValueKey('narrative-event-create-reload')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('narrative-event-create-retry')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
        findsNothing,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-cancel')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-return')),
            )
            .onPressed,
        isNull,
      );
      final recoveryToken = controller.state.pendingReturn;
      controller.cancelMapNavigation();
      expect(controller.state.pendingReturn, same(recoveryToken));
      var openedDuringRecovery = false;
      expect(
        controller.returnToEvent(
          project: project,
          openExactEvent: ({required eventId, required groupContext}) {
            openedDuringRecovery = true;
          },
        ),
        isFalse,
      );
      expect(openedDuringRecovery, isFalse);
      expect(controller.state.pendingReturn, same(recoveryToken));

      final staleReloadCallback = tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey('narrative-event-create-reload')),
          )
          .onPressed!;
      final previewController =
          container.read(borderPreviewControllerProvider.notifier);
      final previewMap = notifier.state.activeMap!;
      previewController.begin(
        map: previewMap,
        layerId: 'borders',
        featureId: 'coast',
        context: createEditorBorderPreviewContext(
          projectRootPath: notifier.state.projectRootPath!,
          activeMapPath: notifier.state.activeMapPath!,
          project: notifier.state.project!,
          map: previewMap,
        ),
      );
      await tester.pump();

      expect(previewController.current.hasPendingPreview, isTrue);
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-reload')),
            )
            .onPressed,
        isNull,
      );
      expect(
        notifier.beginNarrativeEventSourceCleanupInterlock(
          expectedProjectRootPath: notifier.state.projectRootPath!,
          expectedActiveMap: previewMap,
          journal: result!.journal!,
        ),
        isFalse,
      );
      staleReloadCallback();
      await tester.pump();
      expect(
        projectRepository.loadStarted.isCompleted,
        isFalse,
        reason: 'The reload callback must recheck a newly pending preview.',
      );

      previewController.cancel();
      await tester.pump();
      expect(previewController.current.hasPendingPreview, isFalse);

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-reload')),
            )
            .onPressed!();
        await _waitForProjectLoadStarted(projectRepository);
      });
      expect(
        notifier.state.isSaving,
        isTrue,
        reason: 'Reload recovery must own the lease before project IO.',
      );
      await tester.runAsync(notifier.saveActiveMap);
      expect(mapRepository.saveCalls, 0);

      await tester.runAsync(() async {
        projectRepository.releaseLoad.complete();
        for (var attempt = 0; attempt < 300; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.committed &&
              sourceGateway.acknowledgeCalls == 1) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Reload did not resynchronize and acknowledge the exact Event.');
      });
      await tester.pump();

      expect(sourceGateway.acknowledgeCalls, 1);
      expect(
          await tester
              .runAsync(() => File(result.journal!.journalPath).exists()),
          isFalse);
      expect(
        notifier
            .state.project!.eventRegistry!.records.single.draftOrNull!.source,
        result.journal!.source,
      );
      expect(
        notifier.state.activeMap!.entities.single.id,
        narrativeEventSpatialSourceOwnerId(result.journal!.source),
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-cancel')),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-return')),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets(
        'new controller discovers eventCommitted from exact view then reloads and acknowledges',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: FileProjectRepository(),
          operationIdFactory: () => 'banner_restart_event_committed',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: _recoveryProposal(map),
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(interrupted.journal?.state,
          NarrativeEventSpatialLinkJournalState.eventCommitted);
      expect(
          await tester
              .runAsync(() => File(interrupted.journal!.journalPath).exists()),
          isTrue);
      final diskProject = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringProject(
          await File(fixture.projectPath).readAsBytes(),
        ).manifest;
      }))!;
      final diskMap = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringMap(
          await File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          fixture.session.mapPaths['map_a']!,
        );
      }))!;
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: diskProject,
        activeMap: diskMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: diskMap,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          diskProject,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-view-on-map')),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.journal?.state ==
                  NarrativeEventSpatialLinkJournalState.eventCommitted) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Exact Event view did not discover eventCommitted recovery.');
      });
      await tester.pump();

      expect(controller.state.navigationMode,
          NarrativeEventMapNavigationMode.view);
      expect(
        find.byKey(const ValueKey('narrative-event-create-reload')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-map-return')),
            )
            .onPressed,
        isNull,
      );

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-reload')),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 300; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.committed &&
              sourceGateway.acknowledgeCalls == 1) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Restarted exact Event recovery did not acknowledge.');
      });
      await tester.pump();

      expect(sourceGateway.commitCalls, 0);
      expect(registryGateway.persistCalls, 0);
      expect(sourceGateway.acknowledgeCalls, 1);
      expect(
          await tester
              .runAsync(() => File(interrupted.journal!.journalPath).exists()),
          isFalse);
      expect(
        (await tester.runAsync(
          () => sourceGateway.inspectProject(fixture.projectPath),
        ))!
            .status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    testWidgets(
        'new controller exposes recovery, cancels cleanup safely, then retries without rewriting map',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'banner_restart_recovery',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      final diskMap = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringMap(
          await File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          fixture.session.mapPaths['map_a']!,
        );
      }))!;
      final mapBytesBeforeRetry = (await tester.runAsync(
        () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
      ))!;
      expect(diskMap.entities, hasLength(1));

      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: diskMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: diskMap,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-source-on-map'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.recoveryRequired) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Restarted controller did not discover the durable journal.');
      });
      await tester.pump();

      expect(
        find.byKey(const ValueKey('narrative-event-create-retry')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-confirm'),
        ),
        findsOneWidget,
      );
      expect(find.text('Confirmer la suppression'), findsOneWidget);
      expect(sourceGateway.cleanupCalls, 0);
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-cancel'),
        ),
      );
      await tester.pump();
      expect(controller.state.cleanupConfirmationRequested, isFalse);
      expect(sourceGateway.cleanupCalls, 0);

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(const ValueKey('narrative-event-create-retry')),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.committed) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Recovery retry did not complete.');
      });
      await tester.pump();

      expect(sourceGateway.commitCalls, 0);
      expect(sourceGateway.cleanupCalls, 0);
      expect(registryGateway.persistCalls, 1);
      expect(notifier.state.workspaceMode, EditorWorkspaceMode.events);
      expect(controller.state.selectedNarrativeEventV2Id, _eventId);
      expect(controller.state.pendingReturn, isNull);
      expect(notifier.state.activeMap!.entities, hasLength(1));
      expect(
        notifier.state.project!.eventRegistry!.records,
        hasLength(1),
      );
      expect(
        notifier
            .state.project!.eventRegistry!.records.single.draftOrNull!.source,
        proposal.source,
      );
      expect(
        await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ),
        mapBytesBeforeRetry,
      );
    });

    testWidgets(
        'confirmed cleanup button removes only the pending owner and clears the journal',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'banner_confirmed_cleanup',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      final journalPath = interrupted.journal!.journalPath;
      const independentOwner = MapEntity(
        id: 'independent_sign',
        name: 'Independent sign',
        kind: MapEntityKind.sign,
        pos: GridPos(x: 6, y: 4),
        sign: MapEntitySignData(plainText: 'Preserve me'),
      );
      final committedMap = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringMap(
          await File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          fixture.session.mapPaths['map_a']!,
        );
      }))!;
      final mapWithIndependentChange = committedMap.copyWith(
        entities: [...committedMap.entities, independentOwner],
      );
      final projectBytesBeforeCleanup = (await tester.runAsync(
        () => File(fixture.projectPath).readAsBytes(),
      ))!;
      await tester.runAsync(
        () => File(fixture.session.mapPaths['map_a']!).writeAsBytes(
          canonicalizeNarrativeEventJsonUtf8(
            mapWithIndependentChange.toJson(),
          ),
          flush: true,
        ),
      );

      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: mapWithIndependentChange,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: mapWithIndependentChange,
        selectedEntityId: 'recovery_sign',
        selectedEntityKind: MapEntityKind.sign,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);

      expect(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();
      expect(sourceGateway.cleanupCalls, 0);
      expect(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-confirm'),
        ),
        findsOneWidget,
      );

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-cleanup-confirm'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.cleaned) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Confirmed cleanup did not complete.');
      });
      await tester.pump();

      expect(sourceGateway.cleanupCalls, 1);
      expect(registryGateway.persistCalls, 0);
      expect(controller.state.cleanupConfirmationRequested, isFalse);
      expect(
        controller.state.lastSourceCreationResult?.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
      );
      final cleanedMap = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringMap(
          await File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          fixture.session.mapPaths['map_a']!,
        );
      }))!;
      expect(cleanedMap.entities, [independentOwner]);
      expect(notifier.state.activeMap, cleanedMap);
      expect(notifier.state.savedMapSnapshot, cleanedMap);
      expect(
        identical(
          notifier.state.activeMap,
          notifier.state.savedMapSnapshot,
        ),
        isTrue,
      );
      expect(notifier.state.selectedEntityId, isNull);
      expect(notifier.state.isDirty, isFalse);
      await tester.runAsync(notifier.saveActiveMap);
      final mapAfterSave = (await tester.runAsync(() async {
        return decodeValidatedNarrativeEventAuthoringMap(
          await File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          fixture.session.mapPaths['map_a']!,
        );
      }))!;
      expect(mapAfterSave.entities, [independentOwner]);
      expect(
        await tester.runAsync(
          () => File(fixture.projectPath).readAsBytes(),
        ),
        projectBytesBeforeCleanup,
      );
      expect(
        decodeValidatedNarrativeEventAuthoringProject(
          projectBytesBeforeCleanup,
        ).manifest.eventRegistry!.records.single.draftOrNull!.source,
        isNull,
      );
      expect(await tester.runAsync(() => File(journalPath).exists()), isFalse);
      expect(
        (await tester.runAsync(
          () => sourceGateway.inspectProject(fixture.projectPath),
        ))!
            .status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    testWidgets(
        'cleanup CAS mismatch interlocks stale map writes until a map-only reload acknowledges cleanup',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_stale_map_interlock',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );

      late EditorNotifier notifier;
      late MapData staleConcurrentMap;
      var saveAttemptedDuringCleanup = false;
      var saveBlockedDuringCleanup = false;
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
        duringCleanup: () async {
          saveAttemptedDuringCleanup = true;
          await notifier.saveActiveMap();
          saveBlockedDuringCleanup =
              notifier.state.errorMessage?.toLowerCase().contains('recharg') ==
                  true;
        },
        afterCleanup: () async {
          final current = notifier.state;
          final activeMap = current.activeMap!;
          final changedOwner = activeMap.entities.single.copyWith(
            name: 'Owner edited concurrently after cleanup',
          );
          staleConcurrentMap = activeMap.copyWith(entities: [changedOwner]);
          notifier.state = current.copyWith(
            activeMap: staleConcurrentMap,
            isDirty: true,
            isProjectDirty: true,
          );
        },
      );
      final registryGateway = _RecordingRegistryGateway(
        delegate: FileProjectRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: registryGateway,
      );
      notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        selectedEntityId: 'recovery_sign',
        selectedEntityKind: MapEntityKind.sign,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();

      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-cleanup-confirm'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.code ==
                  'cleanedMapOutOfSync') {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Cleanup did not expose the stale map recovery interlock.');
      });
      await tester.pump();

      expect(sourceGateway.cleanupCalls, 1);
      expect(saveAttemptedDuringCleanup, isTrue);
      expect(
        saveBlockedDuringCleanup,
        isTrue,
        reason: 'The stale-map barrier must be armed before cleanup I/O.',
      );
      expect(notifier.state.activeMap, same(staleConcurrentMap));
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.isProjectDirty, isTrue);
      final cleanDiskBytes = (await tester.runAsync(
        () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
      ))!;
      expect(
        decodeValidatedNarrativeEventAuthoringMap(
          cleanDiskBytes,
          fixture.session.mapPaths['map_a']!,
        ).entities,
        isEmpty,
      );

      await tester.runAsync(notifier.saveActiveMap);
      final diskMapAfterBlockedSave = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(
        diskMapAfterBlockedSave.entities,
        isEmpty,
        reason: 'Saving the stale snapshot must not resurrect its owner.',
      );
      expect(notifier.state.activeMap, same(staleConcurrentMap));
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.errorMessage?.toLowerCase(), contains('recharg'));

      notifier.addEntityAt(
        const GridPos(x: 8, y: 8),
        kind: MapEntityKind.custom,
      );
      expect(notifier.state.activeMap, same(staleConcurrentMap));
      expect(notifier.state.activeMap!.entities, hasLength(1));
      expect(notifier.state.errorMessage?.toLowerCase(), contains('recharg'));
      await tester.pump();

      final reloadButton = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('narrative-event-create-reload')),
      );
      expect(
        reloadButton.onPressed,
        isNotNull,
        reason: 'Cleanup recovery must not deadlock behind dirty state.',
      );
      await tester.runAsync(() async {
        reloadButton.onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (controller.state.lastSourceCreationResult?.status ==
                  NarrativeEventExplicitSourceCreationStatus.cleaned &&
              notifier.state.activeMap?.entities.isEmpty == true) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Map-only reload did not acknowledge the durable cleanup.');
      });
      await tester.pump();

      expect(notifier.state.activeMap!.entities, isEmpty);
      expect(notifier.state.savedMapSnapshot, notifier.state.activeMap);
      expect(notifier.state.isDirty, isFalse);
      expect(
        notifier.state.isProjectDirty,
        isTrue,
        reason: 'Cleanup reload must not discard unrelated manifest edits.',
      );
      expect(
        controller.state.lastSourceCreationResult?.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
      );
      expect(
        controller.state.lastSourceCreationResult?.code,
        'cleanupReloaded',
      );

      notifier.addEntityAt(
        const GridPos(x: 8, y: 8),
        kind: MapEntityKind.custom,
      );
      expect(notifier.state.activeMap!.entities, hasLength(1));
      expect(notifier.state.isDirty, isTrue);
    });

    testWidgets(
        'post-rename cleanup verification failure keeps stale map saves interlocked',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_post_rename_verification',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );

      final cleanupRepository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (checkpoint !=
              NarrativeEventSpatialLinkCheckpoint.afterCleanupRename) {
            return;
          }
          final mapPath = fixture.session.mapPaths['map_a']!;
          final cleaned = decodeValidatedNarrativeEventAuthoringMap(
            await File(mapPath).readAsBytes(),
            mapPath,
          );
          await FileMapRepository().saveMap(
            cleaned.copyWith(
              mapMetadata: cleaned.mapMetadata.copyWith(
                displayName: 'Post-rename concurrent bytes',
              ),
            ),
            mapPath,
          );
        },
      );
      final sourceGateway = _RecordingSourceGateway(
        delegate: cleanupRepository,
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-cleanup-confirm'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.code ==
                  'cleanupMapHashMismatch') {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Cleanup did not expose its post-rename verification failure.');
      });
      await tester.pump();

      expect(sourceGateway.cleanupCalls, 1);
      expect(
        decodeValidatedNarrativeEventAuthoringMap(
          (await tester.runAsync(
            () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
          ))!,
          fixture.session.mapPaths['map_a']!,
        ).entities,
        isEmpty,
      );

      await tester.runAsync(notifier.saveActiveMap);
      final afterBlockedSave = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(
        afterBlockedSave.entities,
        isEmpty,
        reason: 'An uncertain durable cleanup must retain its write barrier.',
      );
      expect(
        afterBlockedSave.mapMetadata.displayName,
        'Post-rename concurrent bytes',
      );
      expect(notifier.state.errorMessage?.toLowerCase(), contains('recharg'));
    });

    testWidgets(
        'owner-present reload rebinds an uncertain cleanup lock for an in-process retry',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_owner_reload_retry',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );

      var failOnce = true;
      final cleanupRepository = NarrativeEventSpatialLinkJournalRepository(
        faultInjector: (checkpoint) async {
          if (failOnce &&
              checkpoint ==
                  NarrativeEventSpatialLinkCheckpoint
                      .afterCleanupJournalMarked) {
            failOnce = false;
            throw const FileSystemException('one-shot cleanup interruption');
          }
        },
      );
      final container = _container(
        sourceGateway: _RecordingSourceGateway(delegate: cleanupRepository),
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);
      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-cleanup-confirm'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.code ==
                  'cleanupException') {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Cleanup did not expose the one-shot interruption.');
      });
      await tester.pump();

      final originalIdentity = notifier.state.activeMap;
      await tester.runAsync(() => notifier.loadMap('maps/map_a.json'));
      final reloadedOwnerMap = notifier.state.activeMap!;
      expect(reloadedOwnerMap, isNot(same(originalIdentity)));
      expect(reloadedOwnerMap.entities, hasLength(1));
      expect(controller.requestSourceCleanupConfirmation(), isTrue);

      final retried = (await tester.runAsync(
        () => controller.cleanupCreatedSource(
          projectRootPath: notifier.state.projectRootPath,
          activeMap: reloadedOwnerMap,
          mapDirty: notifier.state.isDirty,
          projectDirty: notifier.state.isProjectDirty,
          saving: notifier.state.isSaving,
          beginCleanupInterlock:
              notifier.beginNarrativeEventSourceCleanupInterlock,
          releaseCleanupInterlock:
              notifier.releaseNarrativeEventSourceCleanupInterlock,
          adoptPersistedCleanup:
              notifier.adoptPersistedNarrativeEventSourceCleanup,
        ),
      ))!;

      expect(
        retried.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
      );
      expect(notifier.state.activeMap!.entities, isEmpty);
      expect(notifier.state.isDirty, isFalse);
    });

    testWidgets(
        'a direct map writer started before cleanup is serialized and cleanup performs no IO',
        (tester) async {
      final map = _tileMap();
      final project = _projectWithTilesets();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_in_flight_map_writer',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );

      final saveUseCase = _SuspendingSaveMapUseCase(FileMapRepository());
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
        saveMapUseCase: saveUseCase,
      );
      expect(
        container.read(editor_use_cases.saveMapUseCaseProvider),
        same(saveUseCase),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        activeLayerId: 'ground',
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);

      late final Future<ActiveMapSaveOutcome> writer;
      await tester.runAsync(() async {
        await notifier.assignTilesetToActiveLayer('secondary');
        expect(notifier.state.isDirty, isTrue);
        writer = notifier.saveActiveMap();
        await Future<void>.delayed(Duration.zero);
        expect(
          notifier.state.isSaving,
          isTrue,
          reason: notifier.state.errorMessage,
        );
        for (var attempt = 0; attempt < 200; attempt++) {
          if (saveUseCase.saveStarted) return;
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('The map save did not reach the suspended writer.');
      });
      expect(
        notifier.state.isSaving,
        isTrue,
        reason: 'The direct writer must publish its lease before map IO.',
      );

      await tester.tap(
        find.byKey(
          const ValueKey('narrative-event-create-cleanup-request'),
        ),
      );
      await tester.pump();
      await tester.runAsync(() async {
        tester
            .widget<PokeMapButton>(
              find.byKey(
                const ValueKey('narrative-event-create-cleanup-confirm'),
              ),
            )
            .onPressed!();
        for (var attempt = 0; attempt < 200; attempt++) {
          if (!controller.state.isSourceCreationBusy &&
              controller.state.lastSourceCreationResult?.code ==
                  'cleanupInterlockUnavailable') {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Cleanup did not refuse the in-flight map writer.');
      });
      await tester.pump();

      expect(sourceGateway.cleanupCalls, 0);
      expect(saveUseCase.saveCalls, 1);

      final concurrentMap = notifier.state.activeMap!.copyWith(
        mapMetadata: notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Concurrent editor snapshot',
        ),
      );
      notifier.state = notifier.state.copyWith(
        activeMap: concurrentMap,
        isDirty: true,
      );

      await tester.runAsync(() async {
        saveUseCase.releaseSave = true;
        await writer;
      });
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.activeMap, same(concurrentMap));
      expect(notifier.state.activeMap!.mapMetadata.displayName,
          'Concurrent editor snapshot');
      expect(
        (notifier.state.activeMap!.layers.single as TileLayer).tilesetId,
        'secondary',
        reason: 'A stale writer result must not replace the newer snapshot.',
      );
      final diskMap = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(diskMap.entities, hasLength(1));
      expect((diskMap.layers.single as TileLayer).tilesetId, 'secondary');
    });

    testWidgets(
        'a map reload started before cleanup owns the lease and cannot resurrect the cleaned owner',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_in_flight_map_reload',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );

      final mapRepository = _SnapshotSuspendingMapRepository(
        FileMapRepository(),
        staleSnapshot: proposal.afterMap,
      );
      final sourceGateway = _RecordingSourceGateway(
        delegate: NarrativeEventSpatialLinkJournalRepository(),
      );
      final container = _container(
        sourceGateway: sourceGateway,
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
        mapRepository: mapRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        selectedEntityId: 'recovery_sign',
        selectedEntityKind: MapEntityKind.sign,
        workspaceMode: EditorWorkspaceMode.events,
      );
      final controller =
          container.read(narrativeEventMapBridgeControllerProvider.notifier);
      expect(
        controller.selectNarrativeEventV2(
          project,
          _eventId,
          groupContext: const NarrativeEventGroupContext.map('map_a'),
        ),
        isTrue,
      );
      await _pump(tester, container);
      await _openCreationFromEventPanel(tester, controller);

      expect(notifier.state.isSaving, isFalse);
      mapRepository.suspendNextLoad();
      late final Future<void> staleReload;
      await tester.runAsync(() async {
        staleReload = notifier.loadMap('maps/map_a.json');
        await mapRepository.targetLoadStarted.future.timeout(
          const Duration(seconds: 2),
        );
        await mapRepository.snapshotRead.future.timeout(
          const Duration(seconds: 10),
        );
      });
      expect(notifier.state.isSaving, isTrue);
      expect(controller.requestSourceCleanupConfirmation(), isTrue);

      final blocked = (await tester.runAsync(
        () => controller.cleanupCreatedSource(
          projectRootPath: notifier.state.projectRootPath,
          activeMap: notifier.state.activeMap!,
          mapDirty: notifier.state.isDirty,
          projectDirty: notifier.state.isProjectDirty,
          saving: notifier.state.isSaving,
          beginCleanupInterlock:
              notifier.beginNarrativeEventSourceCleanupInterlock,
          releaseCleanupInterlock:
              notifier.releaseNarrativeEventSourceCleanupInterlock,
          adoptPersistedCleanup:
              notifier.adoptPersistedNarrativeEventSourceCleanup,
        ),
      ))!;
      expect(blocked.code, 'cleanupInterlockUnavailable');
      expect(sourceGateway.cleanupCalls, 0);

      await tester.runAsync(() async {
        mapRepository.releaseLoad.complete();
        await staleReload.timeout(const Duration(seconds: 2));
      });
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.activeMap!.entities, hasLength(1));
      expect(controller.requestSourceCleanupConfirmation(), isTrue);

      final cleaned = (await tester.runAsync(
        () => controller
            .cleanupCreatedSource(
              projectRootPath: notifier.state.projectRootPath,
              activeMap: notifier.state.activeMap!,
              mapDirty: notifier.state.isDirty,
              projectDirty: notifier.state.isProjectDirty,
              saving: notifier.state.isSaving,
              beginCleanupInterlock:
                  notifier.beginNarrativeEventSourceCleanupInterlock,
              releaseCleanupInterlock:
                  notifier.releaseNarrativeEventSourceCleanupInterlock,
              adoptPersistedCleanup:
                  notifier.adoptPersistedNarrativeEventSourceCleanup,
            )
            .timeout(const Duration(seconds: 10)),
      ))!;
      expect(
        cleaned.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
      );
      expect(sourceGateway.cleanupCalls, 1);
      expect(notifier.state.activeMap!.entities, isEmpty);

      await tester.runAsync(notifier.saveActiveMap);
      final diskMap = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(
        diskMap.entities,
        isEmpty,
        reason: 'The pre-cleanup reload must never resurrect its snapshot.',
      );
    });

    testWidgets(
        'cleanup interlock blocks map lifecycle IO and duplicate create is rejected before IO',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_lifecycle_interlock',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      final journal = interrupted.journal!;
      final mapRepository = _RejectingMapRepository();
      final projectRepository = _RejectingProjectRepository();
      final container = _container(
        sourceGateway: _RecordingSourceGateway(
          delegate: NarrativeEventSpatialLinkJournalRepository(),
        ),
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
        mapRepository: mapRepository,
        projectRepository: projectRepository,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: proposal.afterMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
      );
      expect(
        notifier.beginNarrativeEventSourceCleanupInterlock(
          expectedProjectRootPath: p.dirname(fixture.projectPath),
          expectedActiveMap: proposal.afterMap,
          journal: journal,
        ),
        isTrue,
      );

      await notifier.renameMap('map_a', 'map_b');
      await notifier.deleteMap('map_a');
      await notifier.createMap('map_new', 4, 4);

      final switchedMap = map.copyWith(id: 'map_switched');
      notifier.state = notifier.state.copyWith(
        activeMap: switchedMap,
        activeMapPath: p.join(
          p.dirname(fixture.session.mapPaths['map_a']!),
          'map_switched.json',
        ),
        savedMapSnapshot: switchedMap,
      );
      await notifier.createMap('map_new_after_switch', 4, 4);

      expect(mapRepository.operationCalls, 0);
      expect(projectRepository.saveCalls, 0);

      notifier.releaseNarrativeEventSourceCleanupInterlock(
        expectedProjectRootPath: p.dirname(fixture.projectPath),
        journal: journal,
      );
      await notifier.createMap('map_a', 4, 4);

      expect(mapRepository.operationCalls, 0);
      expect(projectRepository.saveCalls, 0);
      expect(notifier.state.errorMessage, contains('existe déjà'));

      await expectLater(
        CreateMapUseCase(mapRepository, projectRepository).execute(
          ProjectFileSystem(p.dirname(fixture.projectPath)),
          project,
          'map_a',
          4,
          4,
        ),
        throwsA(isA<EditorConflictException>()),
      );
      expect(mapRepository.operationCalls, 0);
      expect(projectRepository.saveCalls, 0);
      await tester.pump();
    });

    testWidgets(
        'cleanup rebases the exact owner deletion over unrelated concurrent map edits',
        (tester) async {
      final map = _map();
      final project = _project();
      final fixture = (await tester.runAsync(
        () => createPersistenceFixture(
          registry: project.eventRegistry,
          map: map,
        ),
      ))!;
      addTearDown(() => tester.runAsync(fixture.dispose));
      final proposal = _recoveryProposal(map);
      final repository = NarrativeEventSpatialLinkJournalRepository();
      final interrupted = (await tester.runAsync(
        () => NarrativeEventExplicitSourceCreationUseCase(
          sourceGateway: repository,
          registryGateway: _FailingRegistryGateway(),
          operationIdFactory: () => 'cleanup_concurrent_rebase',
        ).createAndLink(
          projectPath: fixture.projectPath,
          eventId: _eventId,
          proposal: proposal,
          mapDirty: false,
          projectDirty: false,
          saving: false,
        ),
      ))!;
      final journal = interrupted.journal!;
      final cleaned = (await tester.runAsync(
        () => repository.cleanupSource(
          projectPath: fixture.projectPath,
          operationId: journal.operationId,
          confirmed: true,
        ),
      ))!;
      expect(
        cleaned.status,
        NarrativeEventSpatialLinkOperationStatus.cleaned,
      );

      final concurrentMap = proposal.afterMap.copyWith(
        mapMetadata: proposal.afterMap.mapMetadata.copyWith(
          displayName: 'Concurrent map label',
        ),
      );
      final container = _container(
        sourceGateway: _RecordingSourceGateway(delegate: repository),
        registryGateway: _RecordingRegistryGateway(
          delegate: FileProjectRepository(),
        ),
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: p.dirname(fixture.projectPath),
        project: project,
        activeMap: concurrentMap,
        activeMapPath: fixture.session.mapPaths['map_a'],
        savedMapSnapshot: proposal.afterMap,
        selectedEntityId: 'recovery_sign',
        selectedEntityKind: MapEntityKind.sign,
        isDirty: true,
      );

      final adopted = (await tester.runAsync(
        () => notifier.adoptPersistedNarrativeEventSourceCleanup(
          expectedProjectRootPath: p.dirname(fixture.projectPath),
          expectedActiveMap: proposal.afterMap,
          journal: journal,
        ),
      ))!;

      expect(adopted, isTrue);
      expect(notifier.state.activeMap!.entities, isEmpty);
      expect(
        notifier.state.activeMap!.mapMetadata.displayName,
        'Concurrent map label',
      );
      expect(notifier.state.selectedEntityId, isNull);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.savedMapSnapshot!.entities, isEmpty);
      expect(
        notifier.state.savedMapSnapshot!.mapMetadata.displayName,
        isEmpty,
      );

      await tester.runAsync(notifier.saveActiveMap);
      final savedMap = decodeValidatedNarrativeEventAuthoringMap(
        (await tester.runAsync(
          () => File(fixture.session.mapPaths['map_a']!).readAsBytes(),
        ))!,
        fixture.session.mapPaths['map_a']!,
      );
      expect(savedMap.entities, isEmpty);
      expect(savedMap.mapMetadata.displayName, 'Concurrent map label');
    });
  });
}

ProviderContainer _container({
  required NarrativeEventSpatialSourceCreationGateway sourceGateway,
  required NarrativeEventRegistryPersistenceGateway registryGateway,
  NarrativeEventExplicitSourceCreationUseCase? explicitUseCase,
  MapRepository? mapRepository,
  SaveMapUseCase? saveMapUseCase,
  ProjectRepository? projectRepository,
}) {
  final container = ProviderContainer(
    overrides: [
      narrativeEventSpatialSourceCreationGatewayProvider.overrideWithValue(
        sourceGateway,
      ),
      narrativeEventRegistryPersistenceGatewayProvider.overrideWithValue(
        registryGateway,
      ),
      if (explicitUseCase != null)
        narrativeEventExplicitSourceCreationUseCaseProvider.overrideWithValue(
          explicitUseCase,
        ),
      if (mapRepository != null)
        mapRepositoryProvider.overrideWithValue(mapRepository),
      if (mapRepository != null)
        editor_use_cases.saveMapUseCaseProvider.overrideWithValue(
          SaveMapUseCase(mapRepository),
        ),
      if (saveMapUseCase != null)
        editor_use_cases.saveMapUseCaseProvider.overrideWithValue(
          saveMapUseCase,
        ),
      if (projectRepository != null)
        editor_core.projectRepositoryProvider
            .overrideWith((ref) => projectRepository),
    ],
  );
  final editor = container.listen<EditorState>(
    editorNotifierProvider,
    (_, __) {},
    fireImmediately: true,
  );
  final bridge = container.listen<NarrativeEventMapBridgeState>(
    narrativeEventMapBridgeControllerProvider,
    (_, __) {},
    fireImmediately: true,
  );
  final workspaceFactory = container.listen(
    projectWorkspaceFactoryProvider,
    (_, __) {},
    fireImmediately: true,
  );
  addTearDown(() {
    workspaceFactory.close();
    bridge.close();
    editor.close();
    container.dispose();
  });
  return container;
}

Future<void> _openCreationFromEventPanel(
  WidgetTester tester,
  NarrativeEventMapBridgeController controller,
) async {
  await tester.runAsync(() async {
    tester
        .widget<PokeMapButton>(
          find.byKey(
            const ValueKey('narrative-event-create-source-on-map'),
          ),
        )
        .onPressed!();
    // The callback opens create mode first, then performs the recovery
    // inspection. Do not mistake the short gap between those awaits for idle.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    for (var attempt = 0; attempt < 200; attempt++) {
      if (!controller.state.isSourceCreationBusy &&
          controller.state.navigationMode ==
              NarrativeEventMapNavigationMode.create) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    fail('The Event panel did not open source creation mode.');
  });
  await tester.pump();
}

Future<void> _pump(
  WidgetTester tester,
  ProviderContainer container, {
  ValueChanged<GridPos>? onLegacyPosition,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 700));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosTheme(
        data: MacosThemeData.light(),
        child: MaterialApp(
          home: CupertinoPageScaffold(
            child: Stack(
              children: [
                Positioned.fill(
                  child: MapCanvas(
                    onEventBuilderPositionChosen: onLegacyPosition,
                  ),
                ),
                const Align(
                  alignment: Alignment.bottomCenter,
                  child: NarrativeEventMapReturnPanel(),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ProjectManifest _project() {
  return ProjectManifest(
    name: 'V2-25 banner project',
    maps: [
      const ProjectMapEntry(
        id: 'map_a',
        name: 'Map A',
        relativePath: 'maps/map_a.json',
      ),
    ],
    tilesets: [],
    scenes: [],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.dualRead,
      records: [
        NarrativeEventRecord.draft(
          NarrativeEventDraft(
            id: _eventId,
            name: 'Event sans source',
            conditions: const [],
            priority: 0,
            order: 0,
          ),
        ),
      ],
      legacyClaims: const [],
    ),
  );
}

MapData _map() => const MapData(
      id: 'map_a',
      name: 'Map A',
      size: GridSize(width: 20, height: 15),
      layers: [ObjectLayer(id: 'objects', name: 'Objects')],
    );

MapData _mapWithBorderPreviewTarget() {
  final base = _map();
  return base.copyWith(
    version: ProjectVersion.v6,
    layers: <MapLayer>[
      ...base.layers,
      MapLayer.border(
        id: 'borders',
        name: 'Borders',
        content: BorderLayerContent(
          features: <BorderFeature>[
            BorderFeature(
              id: 'coast',
              name: 'Coast',
              blueprintId: 'coast-blueprint',
              seed: BorderSignedInt64.fromInt(7),
              geometry: BorderRegionGeometry(
                width: base.size.width,
                height: base.size.height,
                cells: List<bool>.filled(
                  base.size.width * base.size.height,
                  false,
                )..[0] = true,
              ),
              overrides: const <BorderSlotOverride>[],
              keepOutRegions: const <BorderKeepOutRegion>[],
            ),
          ],
        ),
      ),
    ],
  );
}

ProjectManifest _projectWithTilesets() => _project().copyWith(
      tilesets: const [
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

MapData _tileMap() => MapData(
      id: 'map_a',
      name: 'Map A',
      size: const GridSize(width: 20, height: 15),
      layers: [
        TileLayer(
          id: 'ground',
          name: 'Ground',
          tilesetId: 'primary',
          tiles: List<int>.filled(20 * 15, 0),
        ),
      ],
    );

NarrativeEventCreatedSourceProposal _recoveryProposal(MapData beforeMap) {
  const owner = MapEntity(
    id: 'recovery_sign',
    name: 'Recovery sign',
    kind: MapEntityKind.sign,
    pos: GridPos(x: 2, y: 2),
    sign: MapEntitySignData(),
  );
  return NarrativeEventCreatedSourceProposal(
    physicalKind: NarrativeEventPhysicalSourceKind.sign,
    source: NarrativeEventSourceRef.entityInteract(
      beforeMap.id,
      owner.id,
    ),
    beforeMap: beforeMap,
    afterMap: beforeMap.copyWith(entities: const [owner]),
    bounds: const MapRect(
      pos: GridPos(x: 2, y: 2),
      size: GridSize(width: 1, height: 1),
    ),
    ownerJson: {
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': beforeMap.id,
      'sourceId': owner.id,
      'owner': owner.toJson(),
    },
  );
}

final class _RecordingSourceGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  _RecordingSourceGateway({
    this.delegate,
    List<String>? steps,
    this.syntheticCommit = false,
    this.duringCleanup,
    this.afterCleanup,
  }) : steps = steps ?? <String>[];

  final NarrativeEventSpatialSourceCreationGateway? delegate;
  final List<String> steps;
  final bool syntheticCommit;
  final Future<void> Function()? duringCleanup;
  final Future<void> Function()? afterCleanup;
  int commitCalls = 0;
  int cleanupCalls = 0;
  int acknowledgeCalls = 0;
  NarrativeEventSpatialLinkJournal? _lastJournal;

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    acknowledgeCalls++;
    if (syntheticCommit) {
      return Future.value(
        NarrativeEventSpatialLinkOperationResult(
          status: NarrativeEventSpatialLinkOperationStatus.eventCommitted,
          code: 'eventCommitAcknowledged',
          message: 'Synthetic acknowledgement.',
          journal: _lastJournal,
        ),
      );
    }
    final target = delegate;
    if (target == null) throw StateError('Unexpected acknowledgement.');
    return target.acknowledgeEventCommitted(
      projectPath: projectPath,
      operationId: operationId,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) async {
    commitCalls++;
    steps.add('map');
    final target = delegate;
    if (syntheticCommit) {
      final preparedAt = DateTime.utc(2026, 7, 15, 12);
      final journal = NarrativeEventSpatialLinkJournal(
        schemaVersion: 1,
        operationId: request.operationId,
        projectPath: request.projectPath,
        projectRevision: request.projectRevision,
        journalPath: '${request.projectPath}.spatial.journal',
        mapPath: '${request.projectPath}.map',
        mapTempPath: '${request.projectPath}.map.tmp',
        mapId: request.afterMap.id,
        eventId: request.eventId,
        eventRecordFingerprintBefore: request.eventRecordFingerprintBefore,
        source: request.source,
        sourceOwnerJson: request.sourceOwnerJson,
        sourceOwnerFingerprint: request.sourceOwnerFingerprint,
        beforeMapHash: narrativeEventBytesFingerprint(
          canonicalizeNarrativeEventJsonUtf8(request.beforeMap.toJson()),
        ),
        afterMapHash: narrativeEventBytesFingerprint(
          canonicalizeNarrativeEventJsonUtf8(request.afterMap.toJson()),
        ),
        state: NarrativeEventSpatialLinkJournalState.mapCommitted,
        preparedAt: preparedAt,
        mapCommittedAt: preparedAt.add(const Duration(seconds: 1)),
        cleanupMarker: NarrativeEventSpatialLinkCleanupMarker.none,
      );
      _lastJournal = journal;
      return NarrativeEventSpatialLinkOperationResult(
        status: NarrativeEventSpatialLinkOperationStatus.mapCommitted,
        code: 'mapCommitted',
        message: 'Synthetic map commit.',
        journal: journal,
      );
    }
    if (target == null) throw StateError('Unexpected map write.');
    return target.commitMap(request);
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) async {
    cleanupCalls++;
    final target = delegate;
    if (target == null) throw StateError('Unexpected cleanup.');
    await duringCleanup?.call();
    final result = await target.cleanupSource(
      projectPath: projectPath,
      operationId: operationId,
      confirmed: confirmed,
    );
    await afterCleanup?.call();
    return result;
  }

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) {
    final target = delegate;
    if (target == null) throw StateError('Unexpected inspection.');
    return target.inspectProject(projectPath);
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) {
    steps.add('finalize');
    if (syntheticCommit) {
      return Future.value(
        NarrativeEventSpatialLinkOperationResult(
          status: NarrativeEventSpatialLinkOperationStatus.eventCommitted,
          code: 'eventCommitted',
          message: 'Synthetic finalization.',
          journal: _lastJournal,
        ),
      );
    }
    final target = delegate;
    if (target == null) throw StateError('Unexpected finalization.');
    return target.markEventCommitted(
      projectPath: projectPath,
      operationId: operationId,
    );
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) {
    final target = delegate;
    if (target == null) throw StateError('Unexpected recovery.');
    return target.recoverProject(
      projectPath: projectPath,
      expectedOperationId: expectedOperationId,
      expectedEventId: expectedEventId,
      expectedMapId: expectedMapId,
      expectedSource: expectedSource,
    );
  }
}

final class _SuspendingSaveMapUseCase extends SaveMapUseCase {
  _SuspendingSaveMapUseCase(this._delegate) : super(_delegate);

  final MapRepository _delegate;
  bool saveStarted = false;
  bool releaseSave = false;
  int saveCalls = 0;

  @override
  Future<String?> executeRevisioned(
    MapData map,
    String path, {
    required String? expectedRevision,
    ProjectManifest? projectDialogueContext,
  }) async {
    saveCalls++;
    saveStarted = true;
    while (!releaseSave) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    await _delegate.saveMap(
      map,
      path,
      projectDialogueContext: projectDialogueContext,
    );
    return null;
  }
}

Future<void> _waitForProjectLoadStarted(
  _SuspendingProjectRepository repository,
) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    if (repository.loadCalls > 0) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Project activation did not enter the overridden repository.');
}

final class _SuspendingProjectRepository implements ProjectRepository {
  _SuspendingProjectRepository(this._delegate);

  final ProjectRepository _delegate;
  final Completer<void> loadStarted = Completer<void>();
  final Completer<void> releaseLoad = Completer<void>();
  var loadCalls = 0;

  @override
  Future<ProjectManifest> loadProject(String path) async {
    loadCalls += 1;
    if (!loadStarted.isCompleted) loadStarted.complete();
    await releaseLoad.future;
    return _delegate.loadProject(path);
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) =>
      _delegate.saveProject(project, path);
}

final class _SnapshotSuspendingMapRepository implements MapRepository {
  _SnapshotSuspendingMapRepository(
    this._delegate, {
    required this.staleSnapshot,
  });

  final MapRepository _delegate;
  final MapData staleSnapshot;
  Completer<void>? _targetLoadStarted;
  Completer<void>? _snapshotRead;
  Completer<void>? _releaseLoad;
  var _suspendNextLoad = false;

  Completer<void> get targetLoadStarted => _targetLoadStarted!;
  Completer<void> get snapshotRead => _snapshotRead!;
  Completer<void> get releaseLoad => _releaseLoad!;

  void suspendNextLoad() {
    if (_suspendNextLoad) {
      throw StateError('A target map load is already armed.');
    }
    _suspendNextLoad = true;
    _targetLoadStarted = Completer<void>();
    _snapshotRead = Completer<void>();
    _releaseLoad = Completer<void>();
  }

  @override
  Future<void> deleteMap(String path) => _delegate.deleteMap(path);

  @override
  Future<MapData> loadMap(String path) async {
    if (!_suspendNextLoad) return _delegate.loadMap(path);
    _suspendNextLoad = false;
    targetLoadStarted.complete();
    if (!snapshotRead.isCompleted) snapshotRead.complete();
    await releaseLoad.future;
    return staleSnapshot;
  }

  @override
  Future<void> renameMap(String oldPath, String newPath) =>
      _delegate.renameMap(oldPath, newPath);

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) {
    return _delegate.saveMap(
      map,
      path,
      projectDialogueContext: projectDialogueContext,
    );
  }
}

final class _LoadDelegatingRejectingSaveMapRepository implements MapRepository {
  _LoadDelegatingRejectingSaveMapRepository(this._delegate);

  final MapRepository _delegate;
  int saveCalls = 0;

  @override
  Future<void> deleteMap(String path) => _delegate.deleteMap(path);

  @override
  Future<MapData> loadMap(String path) => _delegate.loadMap(path);

  @override
  Future<void> renameMap(String oldPath, String newPath) =>
      _delegate.renameMap(oldPath, newPath);

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async {
    saveCalls++;
    throw StateError('A stale normal save reached map IO.');
  }
}

final class _RejectingMapRepository implements MapRepository {
  int operationCalls = 0;

  Never _unexpected(String operation) {
    operationCalls++;
    throw StateError('Unexpected map repository $operation.');
  }

  @override
  Future<void> deleteMap(String path) async => _unexpected('delete');

  @override
  Future<MapData> loadMap(String path) async => _unexpected('load');

  @override
  Future<void> renameMap(String oldPath, String newPath) async =>
      _unexpected('rename');

  @override
  Future<void> saveMap(
    MapData map,
    String path, {
    ProjectManifest? projectDialogueContext,
  }) async =>
      _unexpected('save');
}

final class _RejectingProjectRepository implements ProjectRepository {
  int saveCalls = 0;

  @override
  Future<ProjectManifest> loadProject(String path) async =>
      throw StateError('Unexpected project repository load.');

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    saveCalls++;
    throw StateError('Unexpected project repository save.');
  }
}

final class _RecordingRegistryGateway
    implements NarrativeEventRegistryPersistenceGateway {
  _RecordingRegistryGateway({
    this.delegate,
    List<String>? steps,
    this.syntheticCommit = false,
  }) : steps = steps ?? <String>[];

  final NarrativeEventRegistryPersistenceGateway? delegate;
  final List<String> steps;
  final bool syntheticCommit;
  int persistCalls = 0;

  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    final target = delegate;
    if (target == null) throw StateError('Unexpected registry inspection.');
    return target.inspectRecovery(projectPath);
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) {
    persistCalls++;
    steps.add('registry');
    if (syntheticCommit) {
      return Future.value(
        NarrativeEventRegistryPersistenceResult(
          status: NarrativeEventRegistryPersistenceStatus.committed,
          code: 'committed',
          message: 'Synthetic registry commit.',
        ),
      );
    }
    final target = delegate;
    if (target == null) throw StateError('Unexpected registry write.');
    return target.persist(request);
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    final target = delegate;
    if (target == null) throw StateError('Unexpected registry recovery.');
    return target.recover(projectPath);
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    final target = delegate;
    if (target == null) throw StateError('Unexpected registry undo.');
    return target.undo(undoPath);
  }
}

final class _FailingRegistryGateway
    implements NarrativeEventRegistryPersistenceGateway {
  @override
  Future<NarrativeEventRegistryRecoveryInspection> inspectRecovery(
    String projectPath,
  ) {
    throw StateError('Unexpected registry recovery inspection.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> persist(
    NarrativeEventRegistryWriteRequest request,
  ) async {
    return NarrativeEventRegistryPersistenceResult(
      status: NarrativeEventRegistryPersistenceStatus.ioFailure,
      code: 'simulatedRegistryFailure',
      message: 'Simulated post-map registry failure.',
    );
  }

  @override
  Future<List<NarrativeEventRegistryPersistenceResult>> recover(
    String projectPath,
  ) {
    throw StateError('Unexpected registry recovery.');
  }

  @override
  Future<NarrativeEventRegistryPersistenceResult> undo(String undoPath) {
    throw StateError('Unexpected registry undo.');
  }
}
