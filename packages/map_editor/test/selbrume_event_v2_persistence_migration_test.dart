import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_builder_v2_use_case.dart';
import 'package:map_editor/src/application/use_cases/narrative_event_explicit_source_creation_use_case.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import 'package:path/path.dart' as p;

import 'support/selbrume_event_v2_fixture.dart';

const _recoveryEntityId = 'phase_j_recovery_probe';

void main() {
  group('J2 autonomous Selbrume Event V2 fixture', () {
    test('reopens identically and attests every payload hash', () async {
      final root = _versionedFixtureRoot();
      final manifest = _jsonObject(
        jsonDecode(
          await File(p.join(root.path, 'fixture_manifest.json')).readAsString(),
        ),
      );
      final payloadFiles = _jsonObjects(manifest['payloadFiles']);
      expect(payloadFiles, isNotEmpty);
      for (final entry in payloadFiles) {
        final file = File(p.join(root.path, entry['path']! as String));
        expect(await file.exists(), isTrue, reason: file.path);
        expect(
          narrativeEventBytesFingerprint(await file.readAsBytes()),
          entry['sha256'],
          reason: entry['path']! as String,
        );
        expect(await file.length(), entry['bytes']);
      }

      final projectPath = p.join(root.path, 'project.json');
      final first = await NarrativeEventAuthoringSession.prepare(projectPath);
      final second = await NarrativeEventAuthoringSession.prepare(projectPath);
      expect(first.manifest.toJson(), second.manifest.toJson());
      expect(first.manifest.maps.map((entry) => entry.id), <String>[
        selbrumePortMapId,
        selbrumeMarshMapId,
      ]);
      expect(first.context.registryOrNull?.records, hasLength(3));
      expect(
        first.context.registryOrNull?.records
            .every((record) => record.enabledOrNull == true),
        isTrue,
      );
      final mapRepository = FileMapRepository();
      for (final entry in first.manifest.maps) {
        final mapPath = p.join(root.path, entry.relativePath);
        final before = await mapRepository.loadMap(mapPath);
        final after = await mapRepository.loadMap(mapPath);
        expect(after.toJson(), before.toJson());
        expect(after.connections, isEmpty);
        expect(after.warps, isEmpty);
      }

      final promotion = _jsonObject(
        jsonDecode(
          await File(p.join(root.path, 'promotion_manifest.json'))
              .readAsString(),
        ),
      );
      expect(promotion['state'], 'frozenForJ5');
      final ordered = _jsonObjects(promotion['orderedFiles']);
      expect(ordered.map((entry) => entry['order']), <Object?>[1, 2, 3, 4]);
      expect(
        ordered.map((entry) => entry['destination']).toSet(),
        hasLength(4),
      );
      for (final entry in ordered) {
        final source = File(p.join(root.path, entry['source']! as String));
        expect(
          narrativeEventBytesFingerprint(await source.readAsBytes()),
          entry['sha256'],
        );
      }
    });

    test('regenerates the versioned fixture byte-for-byte from the checkpoint',
        () async {
      final fixture = await SelbrumeEventV2Fixture.create();
      addTearDown(fixture.dispose);
      final regeneratedRoot = Directory(
        p.join(fixture.temporaryRoot.path, 'regenerated_fixture'),
      );

      await fixture.exportAutonomousFixture(regeneratedRoot);

      expect(
        await _fileTreeFingerprints(regeneratedRoot),
        await _fileTreeFingerprints(_versionedFixtureRoot()),
      );
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('retries a map-first crash without rewriting the physical source',
        () async {
      final copy = await _copyVersionedFixture();
      addTearDown(copy.dispose);
      final probe = await _prepareRecoveryProbe(copy);
      final mapFile = File(probe.mapPath);
      final beforeMapHash = narrativeEventBytesFingerprint(
        await mapFile.readAsBytes(),
      );
      final interrupted = await _interruptBetweenMapAndRegistry(
        copy: copy,
        probe: probe,
        operationId: 'phase_j_retry',
      );
      expect(
        interrupted.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(
        interrupted.journal?.state,
        NarrativeEventSpatialLinkJournalState.mapCommitted,
      );
      final committedMapBytes = await mapFile.readAsBytes();
      expect(
        narrativeEventBytesFingerprint(committedMapBytes),
        isNot(beforeMapHash),
      );

      final restarted = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
        registryGateway: FileProjectRepository(),
      );
      final retried = await restarted.retry(
        projectPath: copy.projectPath,
        expectedEventId: probe.eventId,
        expectedMapId: selbrumePortMapId,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        retried.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(await mapFile.readAsBytes(), committedMapBytes);
      final reopened = await NarrativeEventAuthoringSession.prepare(
        copy.projectPath,
      );
      final record = reopened.manifest.eventRegistry!.records.singleWhere(
        (candidate) => candidate.id == probe.eventId,
      );
      expect(record.draftOrNull?.source, probe.proposal.source);

      final acknowledged = await restarted.acknowledge(
        projectPath: copy.projectPath,
        operationId: retried.journal!.operationId,
        expectedEventId: probe.eventId,
        expectedMapId: selbrumePortMapId,
      );
      expect(
        acknowledged.status,
        NarrativeEventExplicitSourceCreationStatus.committed,
      );
      expect(
        (await NarrativeEventSpatialLinkJournalRepository()
                .inspectProject(copy.projectPath))
            .status,
        NarrativeEventSpatialLinkInspectionStatus.clear,
      );
    });

    test('rejects a stale project revision before any source write', () async {
      final copy = await _copyVersionedFixture();
      addTearDown(copy.dispose);
      final probe = await _prepareRecoveryProbe(copy);
      final session = await NarrativeEventAuthoringSession.prepare(
        copy.projectPath,
      );
      final record = session.manifest.eventRegistry!.records.singleWhere(
        (candidate) => candidate.id == probe.eventId,
      );
      final mapBytesBefore = await File(probe.mapPath).readAsBytes();
      await File(copy.projectPath).writeAsString(
        '${await File(copy.projectPath).readAsString()}\n',
        flush: true,
      );

      final result =
          await NarrativeEventSpatialLinkJournalRepository().commitMap(
        NarrativeEventSpatialLinkMapCommitRequest(
          projectPath: copy.projectPath,
          projectRevision: session.projectRevision,
          operationId: 'phase_j_stale_revision',
          eventId: probe.eventId,
          eventRecordFingerprintBefore:
              narrativeEventRecordCanonicalFingerprint(record),
          beforeMap: probe.proposal.beforeMap,
          afterMap: probe.proposal.afterMap,
          source: probe.proposal.source,
          sourceOwnerJson: probe.proposal.ownerJson,
          sourceOwnerFingerprint: probe.proposal.ownerFingerprint,
        ),
      );
      expect(result.status, NarrativeEventSpatialLinkOperationStatus.conflict);
      expect(result.code, 'staleProjectRevision');
      expect(await File(probe.mapPath).readAsBytes(), mapBytesBefore);
      expect(result.journal, isNull);
    });

    test('compensates only the exact owner and preserves divergent evidence',
        () async {
      final cleanCopy = await _copyVersionedFixture();
      addTearDown(cleanCopy.dispose);
      final cleanProbe = await _prepareRecoveryProbe(cleanCopy);
      final beforeMap = cleanProbe.proposal.beforeMap;
      final interrupted = await _interruptBetweenMapAndRegistry(
        copy: cleanCopy,
        probe: cleanProbe,
        operationId: 'phase_j_compensation',
      );
      expect(await FileProjectRepository().recover(cleanCopy.projectPath),
          isNotEmpty);
      final cleanup = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
        registryGateway: FileProjectRepository(),
      );
      final cleaned = await cleanup.cleanup(
        projectPath: cleanCopy.projectPath,
        operationId: interrupted.journal!.operationId,
        expectedEventId: cleanProbe.eventId,
        expectedMapId: selbrumePortMapId,
        confirmed: true,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        cleaned.status,
        NarrativeEventExplicitSourceCreationStatus.cleaned,
        reason: '${cleaned.code}: ${cleaned.message}',
      );
      final restored = await FileMapRepository().loadMap(cleanProbe.mapPath);
      expect(restored.toJson(), beforeMap.toJson());

      final revisionCopy = await _copyVersionedFixture();
      addTearDown(revisionCopy.dispose);
      final revisionProbe = await _prepareRecoveryProbe(revisionCopy);
      final revisionInterrupted = await _interruptBetweenMapAndRegistry(
        copy: revisionCopy,
        probe: revisionProbe,
        operationId: 'phase_j_cleanup_revision',
      );
      expect(
        await FileProjectRepository().recover(revisionCopy.projectPath),
        isNotEmpty,
      );
      final revisionGatedCleanup = NarrativeEventExplicitSourceCreationUseCase(
        sourceGateway: NarrativeEventSpatialLinkJournalRepository(
          faultInjector: (checkpoint) async {
            if (checkpoint ==
                NarrativeEventSpatialLinkCheckpoint.beforeCleanupRename) {
              await File(revisionCopy.projectPath).writeAsString(
                '${await File(revisionCopy.projectPath).readAsString()}\n',
                flush: true,
              );
            }
          },
        ),
        registryGateway: FileProjectRepository(),
      );
      final revisionRefused = await revisionGatedCleanup.cleanup(
        projectPath: revisionCopy.projectPath,
        operationId: revisionInterrupted.journal!.operationId,
        expectedEventId: revisionProbe.eventId,
        expectedMapId: selbrumePortMapId,
        confirmed: true,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        revisionRefused.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(revisionRefused.code, 'projectChangedDuringCleanup');
      expect(
        (await FileMapRepository().loadMap(revisionProbe.mapPath))
            .entities
            .any((entity) => entity.id == _recoveryEntityId),
        isTrue,
      );
      expect(
        await File(revisionInterrupted.journal!.journalPath).exists(),
        isTrue,
      );

      final divergentCopy = await _copyVersionedFixture();
      addTearDown(divergentCopy.dispose);
      final divergentProbe = await _prepareRecoveryProbe(divergentCopy);
      final divergentInterrupted = await _interruptBetweenMapAndRegistry(
        copy: divergentCopy,
        probe: divergentProbe,
        operationId: 'phase_j_divergent_owner',
      );
      expect(await FileProjectRepository().recover(divergentCopy.projectPath),
          isNotEmpty);
      final mapFile = File(divergentProbe.mapPath);
      final committedMap = await FileMapRepository().loadMap(mapFile.path);
      final tampered = committedMap.copyWith(
        entities: <MapEntity>[
          for (final entity in committedMap.entities)
            if (entity.id == _recoveryEntityId)
              entity.copyWith(name: 'Ownership changed elsewhere')
            else
              entity,
        ],
      );
      await mapFile.writeAsBytes(
        utf8.encode(jsonEncode(tampered.toJson())),
        flush: true,
      );
      final divergentBytes = await mapFile.readAsBytes();
      final refused = await cleanup.cleanup(
        projectPath: divergentCopy.projectPath,
        operationId: divergentInterrupted.journal!.operationId,
        expectedEventId: divergentProbe.eventId,
        expectedMapId: selbrumePortMapId,
        confirmed: true,
        mapDirty: false,
        projectDirty: false,
        saving: false,
      );
      expect(
        refused.status,
        NarrativeEventExplicitSourceCreationStatus.recoveryRequired,
      );
      expect(refused.code, 'sourceFingerprintMismatch');
      expect(await mapFile.readAsBytes(), divergentBytes);
      expect(
        await File(divergentInterrupted.journal!.journalPath).exists(),
        isTrue,
      );
    });
  });
}

Directory _versionedFixtureRoot() {
  return Directory(
    p.join(
      findPokemonProjectRoot().path,
      'examples',
      'playable_runtime_host',
      'event_builder_v2_selbrume_slice',
    ),
  );
}

Future<Map<String, String>> _fileTreeFingerprints(Directory root) async {
  final files = <File>[];
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is File) files.add(entity);
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  return <String, String>{
    for (final file in files)
      p.posix.normalize(
        p.relative(file.path, from: root.path).replaceAll(r'\', '/'),
      ): narrativeEventBytesFingerprint(await file.readAsBytes()),
  };
}

Future<_FixtureCopy> _copyVersionedFixture() async {
  final temporaryRoot =
      await Directory.systemTemp.createTemp('pokemap_phase_j_fixture_');
  final projectRoot = Directory(p.join(temporaryRoot.path, 'slice'));
  final result = await Process.run(
    '/bin/cp',
    <String>['-cR', _versionedFixtureRoot().path, projectRoot.path],
  );
  if (result.exitCode != 0) {
    throw FileSystemException('Fixture clone failed', '${result.stderr}');
  }
  return _FixtureCopy(
    temporaryRoot: temporaryRoot,
    projectRoot: projectRoot,
    projectPath: p.join(projectRoot.path, 'project.json'),
  );
}

Future<_RecoveryProbe> _prepareRecoveryProbe(_FixtureCopy copy) async {
  final builder = NarrativeEventBuilderV2UseCase(
    persistenceGateway: FileProjectRepository(),
    idGeneratorFactory: () => NarrativeEventIdGenerator(
      rawUuidFactory: () => '019abcde-4000-7000-8000-000000000099',
    ),
    operationIdFactory: () => 'phase_j_recovery_draft',
  );
  final draft = await builder.createDraft(
    projectPath: copy.projectPath,
    name: 'J2 recovery probe',
    environment: const NarrativeEventBuilderV2WriteEnvironment.clean(),
  );
  if (!draft.succeeded || draft.eventId == null) {
    throw StateError('${draft.code}: ${draft.message}');
  }
  final session = await NarrativeEventAuthoringSession.prepare(
    copy.projectPath,
  );
  final mapEntry = session.manifest.maps.singleWhere(
    (entry) => entry.id == selbrumePortMapId,
  );
  final mapPath = p.join(copy.projectRoot.path, mapEntry.relativePath);
  final beforeMap = await FileMapRepository().loadMap(mapPath);
  const owner = MapEntity(
    id: _recoveryEntityId,
    name: 'J2 recovery probe',
    kind: MapEntityKind.sign,
    pos: GridPos(x: 40, y: 31),
    sign: MapEntitySignData(),
  );
  final proposal = NarrativeEventCreatedSourceProposal(
    physicalKind: NarrativeEventPhysicalSourceKind.sign,
    source: NarrativeEventSourceRef.entityInteract(
      selbrumePortMapId,
      _recoveryEntityId,
    ),
    beforeMap: beforeMap,
    afterMap: beforeMap.copyWith(
      entities: <MapEntity>[...beforeMap.entities, owner],
    ),
    bounds: const MapRect(
      pos: GridPos(x: 40, y: 31),
      size: GridSize(width: 1, height: 1),
    ),
    ownerJson: <String, Object?>{
      'schemaVersion': 1,
      'ownerKind': 'mapEntity',
      'mapId': selbrumePortMapId,
      'sourceId': _recoveryEntityId,
      'owner': owner.toJson(),
    },
  );
  return _RecoveryProbe(
    eventId: draft.eventId!,
    mapPath: mapPath,
    proposal: proposal,
  );
}

Future<NarrativeEventExplicitSourceCreationResult>
    _interruptBetweenMapAndRegistry({
  required _FixtureCopy copy,
  required _RecoveryProbe probe,
  required String operationId,
}) {
  final useCase = NarrativeEventExplicitSourceCreationUseCase(
    sourceGateway: NarrativeEventSpatialLinkJournalRepository(),
    registryGateway: FileProjectRepository(
      eventRegistryPersistence: NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('simulated registry crash');
          }
        },
      ),
    ),
    operationIdFactory: () => operationId,
  );
  return useCase.createAndLink(
    projectPath: copy.projectPath,
    eventId: probe.eventId,
    proposal: probe.proposal,
    mapDirty: false,
    projectDirty: false,
    saving: false,
  );
}

Map<String, Object?> _jsonObject(Object? value) {
  return (value as Map).cast<String, Object?>();
}

List<Map<String, Object?>> _jsonObjects(Object? value) {
  return (value as List)
      .map((entry) => _jsonObject(entry))
      .toList(growable: false);
}

final class _FixtureCopy {
  const _FixtureCopy({
    required this.temporaryRoot,
    required this.projectRoot,
    required this.projectPath,
  });

  final Directory temporaryRoot;
  final Directory projectRoot;
  final String projectPath;

  Future<void> dispose() async {
    if (await temporaryRoot.exists()) {
      await temporaryRoot.delete(recursive: true);
    }
  }
}

final class _RecoveryProbe {
  const _RecoveryProbe({
    required this.eventId,
    required this.mapPath,
    required this.proposal,
  });

  final String eventId;
  final String mapPath;
  final NarrativeEventCreatedSourceProposal proposal;
}
