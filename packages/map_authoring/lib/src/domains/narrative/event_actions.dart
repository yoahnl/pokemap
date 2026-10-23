import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';

final class EventV2Actions {
  const EventV2Actions();

  static const maxBatchRecords = 128;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const [
      ('event_v2.create_draft', 'Create an Event V2 draft'),
      ('event_v2.record_upsert', 'Create or replace an Event V2 record'),
      (
        'event_v2.record_upsert_batch',
        'Create or replace a bounded Event V2 record batch'
      ),
      ('event_v2.registry_mode.set', 'Activate an Event V2 registry mode'),
      ('event_v2.publish', 'Publish a complete Event V2 draft'),
      ('event_v2.unpublish', 'Return an Event V2 to draft state'),
      ('event_v2.activate', 'Activate a published Event V2'),
      ('event_v2.deactivate', 'Deactivate a published Event V2'),
      ('event_v2.delete', 'Delete an unreferenced Event V2'),
    ])
      narrativeActionDescriptor(
        entry.$1,
        entry.$2,
        resourceKinds: const ['project', 'eventV2'],
        extensions: {
          'sourceVariants': NarrativeEventSourceRef.contracts,
          'parallelPolicy': NarrativeEventParallelPolicy.contract,
          if (entry.$1 == 'event_v2.record_upsert' ||
              entry.$1 == 'event_v2.record_upsert_batch')
            'mapEventInstanceBoolean': {
              'conditionKind': 'mapEventInstanceBoolean',
              'parameters': ['mapId', 'eventId', 'key', 'expectedValue'],
              'owner': 'knownUniqueLogicalMapEntity',
              'valueType': 'boolean',
              'defaultValue': false,
              'lifetime': 'mapEventInstance',
              'saveResume': 'retainedInstanceState',
              'recreatedInstance': 'defaultsRestored',
            },
          if (entry.$1 == 'event_v2.record_upsert_batch')
            'records': {
              'type': 'array',
              'minItems': 1,
              'maxItems': maxBatchRecords,
              'uniqueBy': 'id'
            },
        },
        risk: entry.$1.endsWith('.delete')
            ? AuthoringRiskLevel.high
            : AuthoringRiskLevel.medium,
      ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    if (context.request.actionId == 'event_v2.record_upsert_batch') {
      rejectUnknownNarrativeParameters(parameters, const {'records'});
      final raw = parameters['records'];
      if (raw is! List || raw.isEmpty || raw.length > maxBatchRecords) {
        throw NarrativeAuthoringException(
          'event_v2.batch_invalid',
          'An Event V2 record batch requires 1 to $maxBatchRecords records.',
        );
      }
      final records = <NarrativeEventRecord>[];
      for (final value in raw) {
        if (value is! Map) {
          throw NarrativeAuthoringException('event_v2.record_invalid',
              'The Event V2 record must be a JSON object.');
        }
        records.add(_decodeRecord(Map<String, dynamic>.from(value)));
      }
      final projected = upsertRecords(context.snapshot.manifest,
          maps: context.snapshot.maps, records: records);
      return narrativeProjectDraft(context.snapshot, projected,
          operation: context.request.actionId,
          path: '/eventRegistry/records',
          before: context.snapshot.manifest.eventRegistry?.records
              .map((record) => record.toJson())
              .toList(),
          after: projected.eventRegistry!.records
              .map((record) => record.toJson())
              .toList(),
          preview: {'recordIds': records.map((record) => record.id).toList()});
    }
    if (context.request.actionId == 'event_v2.registry_mode.set') {
      rejectUnknownNarrativeParameters(parameters, const {'mode'});
      final before = context.snapshot.manifest.eventRegistry?.mode;
      final projected = setRegistryMode(
        context.snapshot.manifest,
        maps: context.snapshot.maps,
        mode: _decodeRegistryMode(
          narrativeStringParameter(parameters, 'mode'),
        ),
      );
      return narrativeProjectDraft(
        context.snapshot,
        projected,
        operation: context.request.actionId,
        path: '/eventRegistry/mode',
        before: before?.name,
        after: projected.eventRegistry!.mode.name,
        includeInspectionPreview: true,
      );
    }
    late final ProjectManifest projected;
    late final String eventId;
    NarrativeEventRecord? before;
    switch (context.request.actionId) {
      case 'event_v2.create_draft':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'name', 'rawUuid', 'initialSource'},
        );
        final name = narrativeStringParameter(parameters, 'name');
        final rawUuid = narrativeStringParameter(parameters, 'rawUuid');
        NarrativeEventSourceRef? initialSource;
        if (parameters['initialSource'] case final Map raw) {
          initialSource = NarrativeEventSourceRef.fromJson(
            Map<String, dynamic>.from(raw),
          );
        } else if (parameters['initialSource'] != null) {
          throw ArgumentError.value(
            parameters['initialSource'],
            'initialSource',
            'must be a JSON object',
          );
        }
        projected = createDraft(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          revision: context.snapshot.revision,
          name: name,
          rawUuid: rawUuid,
          initialSource: initialSource,
        );
        final previousIds = context.snapshot.manifest.eventRegistry?.records
                .map((record) => record.id)
                .toSet() ??
            const <String>{};
        eventId = projected.eventRegistry!.records
            .where((record) => !previousIds.contains(record.id))
            .single
            .id;
      case 'event_v2.record_upsert':
        rejectUnknownNarrativeParameters(parameters, const {'record'});
        final record = _decodeRecord(
          narrativeObjectParameter(parameters, 'record'),
        );
        eventId = record.id;
        before = _findRecord(context.snapshot.manifest, eventId);
        projected = upsertRecord(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          record: record,
        );
      case 'event_v2.publish':
      case 'event_v2.unpublish':
      case 'event_v2.activate':
      case 'event_v2.deactivate':
      case 'event_v2.delete':
        rejectUnknownNarrativeParameters(parameters, const {'eventId'});
        eventId = narrativeStringParameter(parameters, 'eventId');
        before = _findRecord(context.snapshot.manifest, eventId);
        projected = switch (context.request.actionId) {
          'event_v2.publish' => publish(
              context.snapshot.manifest,
              maps: context.snapshot.maps,
              revision: context.snapshot.revision,
              eventId: eventId,
            ),
          'event_v2.unpublish' => unpublish(
              context.snapshot.manifest,
              maps: context.snapshot.maps,
              revision: context.snapshot.revision,
              eventId: eventId,
            ),
          'event_v2.activate' => activate(
              context.snapshot.manifest,
              maps: context.snapshot.maps,
              revision: context.snapshot.revision,
              eventId: eventId,
            ),
          'event_v2.deactivate' => deactivate(
              context.snapshot.manifest,
              maps: context.snapshot.maps,
              revision: context.snapshot.revision,
              eventId: eventId,
            ),
          'event_v2.delete' => delete(
              context.snapshot.manifest,
              maps: context.snapshot.maps,
              revision: context.snapshot.revision,
              eventId: eventId,
            ),
          _ => throw StateError('unreachable Event V2 action'),
        };
      default:
        throw NarrativeAuthoringException(
          'event_v2.action_unsupported',
          'The requested Event V2 action is unsupported.',
        );
    }
    final after = _findRecord(projected, eventId);
    return narrativeProjectDraft(
      context.snapshot,
      projected,
      operation: context.request.actionId,
      path: '/eventRegistry/records/$eventId',
      before: before?.toJson(),
      after: after?.toJson(),
      includeInspectionPreview: true,
    );
  }

  ProjectManifest createDraft(
    ProjectManifest project, {
    required List<MapData> maps,
    required String revision,
    required String name,
    required String rawUuid,
    NarrativeEventSourceRef? initialSource,
  }) {
    final context = _context(project, maps: maps, revision: revision);
    return _apply(
      project,
      createNarrativeEventDraft(
        context: context,
        expectedRevision: revision,
        name: name,
        initialSource: initialSource,
        idGenerator: NarrativeEventIdGenerator(rawUuidFactory: () => rawUuid),
      ),
    );
  }

  ProjectManifest upsertRecord(
    ProjectManifest project, {
    required List<MapData> maps,
    required NarrativeEventRecord record,
  }) {
    return upsertRecords(project, maps: maps, records: [record]);
  }

  ProjectManifest upsertRecords(
    ProjectManifest project, {
    required List<MapData> maps,
    required List<NarrativeEventRecord> records,
  }) {
    if (records.isEmpty || records.length > maxBatchRecords) {
      throw NarrativeAuthoringException('event_v2.batch_invalid',
          'An Event V2 record batch requires 1 to $maxBatchRecords records.');
    }
    final replacements = <String, NarrativeEventRecord>{};
    for (final record in records) {
      if (replacements.containsKey(record.id)) {
        throw NarrativeAuthoringException('event_v2.batch_duplicate',
            'An Event V2 record batch requires unique event IDs.');
      }
      replacements[record.id] = record;
    }
    final current = project.eventRegistry;
    final registry = NarrativeEventRegistry(
      schemaVersion: current?.schemaVersion ?? 1,
      mode: current?.mode ?? EventSystemMode.legacyOnly,
      records: [
        for (final record in current?.records ?? const <NarrativeEventRecord>[])
          replacements.remove(record.id) ?? record,
        ...replacements.values,
      ],
      legacyClaims: current?.legacyClaims ?? const <LegacySourceClaim>[],
    );
    final projected = project.copyWith(eventRegistry: registry);
    final requiresCatalog = records.any((record) =>
        record.definitionOrNull != null ||
        (record.definitionOrNull?.source ?? record.draftOrNull?.source)?.kind ==
            NarrativeEventSourceKind.triggerBump);
    final catalog = requiresCatalog
        ? buildNarrativeEventProjectCatalog(project: projected, maps: maps)
        : null;
    for (final record in records) {
      final source =
          record.definitionOrNull?.source ?? record.draftOrNull?.source;
      if (source?.kind == NarrativeEventSourceKind.triggerBump &&
          catalog!.resolveSource(source!).status !=
              NarrativeEventProjectResolutionStatus.found) {
        throw NarrativeAuthoringException('event_v2.source_unavailable',
            'The contact source requires one valid event trigger in a 2D map.');
      }
    }
    final definedIds = records
        .where((record) => record.definitionOrNull != null)
        .map((record) => record.id)
        .toSet();
    if (definedIds.isNotEmpty) {
      final report = buildNarrativeEventValidationReportSubset(
          registry: registry, catalog: catalog!, eventIds: definedIds);
      if (report.hasBlockingDiagnostics) {
        throw NarrativeAuthoringException('event_v2.validation_failed',
            'The configured Event V2 has blocking canonical diagnostics.',
            details: report.toDebugJson());
      }
    }
    return projected;
  }

  ProjectManifest setRegistryMode(
    ProjectManifest project, {
    required List<MapData> maps,
    required EventSystemMode mode,
  }) {
    if (mode == EventSystemMode.legacyOnly) {
      throw NarrativeAuthoringException(
        'event_v2.registry_mode_invalid',
        'The canonical activation action accepts only dualRead or v2Only.',
        details: {'mode': mode.name},
      );
    }
    final current = project.eventRegistry;
    final legacyMapEventCount = maps.fold<int>(
      0,
      (count, map) => count + map.events.length,
    );
    final legacyScenarioSourceCount = project.scenarios.fold<int>(
      0,
      (count, scenario) =>
          count + scenario.nodes.where(isLegacyScenarioSourceNode).length,
    );
    if (current?.mode == mode) {
      throw NarrativeAuthoringException(
        'event_v2.no_change',
        'The requested Event V2 registry mode is already active.',
        details: {'mode': mode.name},
      );
    }
    final unsafeDualReadRecovery = current?.mode == EventSystemMode.v2Only &&
        mode == EventSystemMode.dualRead &&
        (current!.legacyClaims.isNotEmpty ||
            legacyMapEventCount > 0 ||
            legacyScenarioSourceCount > 0);
    if (unsafeDualReadRecovery ||
        (mode == EventSystemMode.v2Only &&
            (current?.records.isNotEmpty == true ||
                current?.legacyClaims.isNotEmpty == true ||
                legacyMapEventCount > 0 ||
                legacyScenarioSourceCount > 0))) {
      throw NarrativeAuthoringException(
        'event_v2.registry_mode_unsafe',
        'The Event V2 registry cannot safely perform this mode transition.',
        details: {
          'currentMode': (current?.mode ?? EventSystemMode.legacyOnly).name,
          'targetMode': mode.name,
          'recordCount': current?.records.length ?? 0,
          'legacyClaimCount': current?.legacyClaims.length ?? 0,
          'legacyMapEventCount': legacyMapEventCount,
          'legacyScenarioSourceCount': legacyScenarioSourceCount,
        },
      );
    }
    return project.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: current?.schemaVersion ?? 1,
        mode: mode,
        records: current?.records ?? const <NarrativeEventRecord>[],
        legacyClaims: current?.legacyClaims ?? const <LegacySourceClaim>[],
      ),
    );
  }

  ProjectManifest publish(
    ProjectManifest project, {
    required List<MapData> maps,
    required String revision,
    required String eventId,
  }) =>
      _apply(
        project,
        publishNarrativeEvent(
          context: _context(project, maps: maps, revision: revision),
          expectedRevision: revision,
          eventId: eventId,
        ),
      );

  ProjectManifest unpublish(
    ProjectManifest project, {
    required List<MapData> maps,
    required String revision,
    required String eventId,
  }) =>
      _apply(
        project,
        unpublishNarrativeEvent(
          context: _context(project, maps: maps, revision: revision),
          expectedRevision: revision,
          eventId: eventId,
        ),
      );

  ProjectManifest activate(
    ProjectManifest project, {
    required List<MapData> maps,
    required String revision,
    required String eventId,
  }) =>
      _apply(
        project,
        activateNarrativeEvent(
          context: _context(project, maps: maps, revision: revision),
          expectedRevision: revision,
          eventId: eventId,
        ),
      );

  ProjectManifest deactivate(
    ProjectManifest project, {
    required List<MapData> maps,
    required String revision,
    required String eventId,
  }) =>
      _apply(
        project,
        deactivateNarrativeEvent(
          context: _context(project, maps: maps, revision: revision),
          expectedRevision: revision,
          eventId: eventId,
        ),
      );

  ProjectManifest delete(
    ProjectManifest project, {
    required List<MapData> maps,
    required String revision,
    required String eventId,
  }) =>
      _apply(
        project,
        deleteNarrativeEvent(
          context: _context(project, maps: maps, revision: revision),
          expectedRevision: revision,
          eventId: eventId,
          dependencyIndex: buildNarrativeDependencyIndex(
            project: project,
            maps: maps,
          ),
        ),
      );
}

NarrativeEventAuthoringContext _context(
  ProjectManifest project, {
  required List<MapData> maps,
  required String revision,
}) {
  final registry = project.eventRegistry;
  final catalog = buildNarrativeEventProjectCatalog(
    project: project,
    maps: maps,
  );
  return NarrativeEventAuthoringContext(
    registryState: registry == null
        ? EventRegistryDecodeResult.absent()
        : EventRegistryDecodeResult.decoded(registry),
    revision: revision,
    catalog: catalog,
    sourceIndex: buildNarrativeEventSourceIndex(
      registry?.records ?? const <NarrativeEventRecord>[],
    ),
    manifestHash: catalog.manifestHash,
    mapHashes: catalog.mapHashes,
  );
}

ProjectManifest _apply(
  ProjectManifest project,
  NarrativeEventAuthoringResult result,
) {
  switch (result.status) {
    case NarrativeEventAuthoringStatus.applied:
      return project.copyWith(eventRegistry: result.nextRegistry!);
    case NarrativeEventAuthoringStatus.noOp:
      return project;
    case NarrativeEventAuthoringStatus.rejected:
    case NarrativeEventAuthoringStatus.staleRevision:
    case NarrativeEventAuthoringStatus.unsupportedRegistry:
    case NarrativeEventAuthoringStatus.invalidRegistry:
      throw NarrativeAuthoringException(
        result.rejectionCode ?? 'event_v2.rejected',
        result.humanReason ?? 'The canonical Event V2 operation was rejected.',
        details: {
          'status': result.status.name,
          'diagnostics': [
            for (final item in result.diagnostics)
              {
                'code': item.code,
                'message': item.message,
                if (item.path != null) 'path': item.path,
              },
          ],
        },
      );
  }
}

NarrativeEventRecord? _findRecord(ProjectManifest project, String eventId) =>
    project.eventRegistry?.records
        .where((record) => record.id == eventId)
        .firstOrNull;

NarrativeEventRecord _decodeRecord(Map<String, dynamic> json) {
  try {
    return NarrativeEventRecord.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'event_v2.record_invalid',
      'The Event V2 record cannot be decoded.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

EventSystemMode _decodeRegistryMode(String value) => switch (value) {
      'dualRead' => EventSystemMode.dualRead,
      'v2Only' => EventSystemMode.v2Only,
      _ => throw NarrativeAuthoringException(
          'event_v2.registry_mode_invalid',
          'The Event V2 registry mode must be dualRead or v2Only.',
          details: {'mode': value},
        ),
    };
