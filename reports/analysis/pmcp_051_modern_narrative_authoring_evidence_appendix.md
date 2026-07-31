# PMCP-051 — Contenu intégral des fichiers créés

Cette annexe reproduit intégralement les fichiers texte créés par le lot.

## `lib/src/domains/narrative/event_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'modern_narrative_inspection.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';

final class EventV2Actions {
  const EventV2Actions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const [
      ('event_v2.create_draft', 'Create an Event V2 draft'),
      ('event_v2.record_upsert', 'Create or replace an Event V2 record'),
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
        risk: entry.$1.endsWith('.delete')
            ? AuthoringRiskLevel.high
            : AuthoringRiskLevel.medium,
      ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
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
      preview: const ModernNarrativeInspector()
          .inspect(project: projected, maps: context.snapshot.maps)
          .toJson(),
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
    final current = project.eventRegistry;
    final registry = current == null
        ? NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.legacyOnly,
            records: [record],
            legacyClaims: const [],
          )
        : _upsertNarrativeEventRecord(current, record);
    final projected = project.copyWith(eventRegistry: registry);
    if (record.definitionOrNull != null) {
      final catalog = buildNarrativeEventProjectCatalog(
        project: projected,
        maps: maps,
      );
      final report = buildNarrativeEventValidationReportSubset(
        registry: registry,
        catalog: catalog,
        eventIds: {record.id},
      );
      if (report.hasBlockingDiagnostics) {
        throw NarrativeAuthoringException(
          'event_v2.validation_failed',
          'The configured Event V2 has blocking canonical diagnostics.',
          details: report.toDebugJson(),
        );
      }
    }
    return projected;
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

NarrativeEventRegistry _upsertNarrativeEventRecord(
  NarrativeEventRegistry registry,
  NarrativeEventRecord nextRecord,
) {
  final exists = registry.records.any((record) => record.id == nextRecord.id);
  return NarrativeEventRegistry(
    schemaVersion: registry.schemaVersion,
    mode: registry.mode,
    records: exists
        ? [
            for (final record in registry.records)
              if (record.id == nextRecord.id) nextRecord else record,
          ]
        : [...registry.records, nextRecord],
    legacyClaims: registry.legacyClaims,
  );
}
```

## `lib/src/domains/narrative/fact_rule_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'modern_narrative_inspection.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';

final class FactRuleActions {
  const FactRuleActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const [
      ('fact.create', 'Create a typed narrative Fact', ['project', 'fact']),
      ('fact.update', 'Update a typed narrative Fact', ['project', 'fact']),
      (
        'fact.delete',
        'Delete an unreferenced narrative Fact',
        ['project', 'fact']
      ),
      (
        'world_rule.create',
        'Create a validated World Rule',
        ['project', 'worldRule'],
      ),
      (
        'world_rule.update',
        'Update a validated World Rule',
        ['project', 'worldRule'],
      ),
      (
        'world_rule.delete',
        'Delete a World Rule',
        ['project', 'worldRule'],
      ),
    ])
      narrativeActionDescriptor(
        entry.$1,
        entry.$2,
        resourceKinds: entry.$3,
        risk: entry.$1.endsWith('.delete')
            ? AuthoringRiskLevel.high
            : AuthoringRiskLevel.medium,
      ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    switch (context.request.actionId) {
      case 'fact.create':
        rejectUnknownNarrativeParameters(parameters, const {'fact'});
        final fact = _decodeFact(narrativeObjectParameter(parameters, 'fact'));
        final projected = createFact(context.snapshot.manifest, fact: fact);
        return _draft(
          context,
          projected,
          path: '/facts/${fact.id}',
          after: fact.toJson(),
        );
      case 'fact.update':
        rejectUnknownNarrativeParameters(parameters, const {'fact'});
        final fact = _decodeFact(narrativeObjectParameter(parameters, 'fact'));
        final before = context.snapshot.manifest.facts
            .where((candidate) => candidate.id == fact.id)
            .firstOrNull;
        final projected = updateFact(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          fact: fact,
        );
        return _draft(
          context,
          projected,
          path: '/facts/${fact.id}',
          before: before?.toJson(),
          after: fact.toJson(),
        );
      case 'fact.delete':
        rejectUnknownNarrativeParameters(parameters, const {'factId'});
        final id = narrativeStringParameter(parameters, 'factId');
        final before = context.snapshot.manifest.facts
            .where((candidate) => candidate.id == id)
            .firstOrNull;
        final projected = deleteFact(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          factId: id,
        );
        return _draft(
          context,
          projected,
          path: '/facts/$id',
          before: before?.toJson(),
        );
      case 'world_rule.create':
        rejectUnknownNarrativeParameters(parameters, const {'rule'});
        final rule = _decodeRule(narrativeObjectParameter(parameters, 'rule'));
        final projected = createWorldRule(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          rule: rule,
        );
        return _draft(
          context,
          projected,
          path: '/worldRules/${rule.id}',
          after: rule.toJson(),
        );
      case 'world_rule.update':
        rejectUnknownNarrativeParameters(parameters, const {'rule'});
        final rule = _decodeRule(narrativeObjectParameter(parameters, 'rule'));
        final before = context.snapshot.manifest.worldRules
            .where((candidate) => candidate.id == rule.id)
            .firstOrNull;
        final projected = updateWorldRuleDefinition(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          rule: rule,
        );
        return _draft(
          context,
          projected,
          path: '/worldRules/${rule.id}',
          before: before?.toJson(),
          after: rule.toJson(),
        );
      case 'world_rule.delete':
        rejectUnknownNarrativeParameters(parameters, const {'ruleId'});
        final id = narrativeStringParameter(parameters, 'ruleId');
        final before = context.snapshot.manifest.worldRules
            .where((candidate) => candidate.id == id)
            .firstOrNull;
        final projected = deleteWorldRule(
          context.snapshot.manifest,
          ruleId: id,
        );
        return _draft(
          context,
          projected,
          path: '/worldRules/$id',
          before: before?.toJson(),
        );
      default:
        throw NarrativeAuthoringException(
          'fact_rule.action_unsupported',
          'The requested Fact or World Rule action is unsupported.',
        );
    }
  }

  ProjectManifest createFact(
    ProjectManifest project, {
    required NarrativeFactDefinition fact,
  }) =>
      _translate('fact.create_rejected', () {
        final result = addNarrativeFact(
          project,
          label: fact.label,
          description: fact.description,
          category: fact.category,
          initialValue: fact.initialValue,
          tags: fact.tags,
          legacyFlagName: fact.legacyFlagName,
        );
        if (result.createdFact.id != fact.id) {
          throw ArgumentError.value(
            fact.id,
            'fact.id',
            'must equal the canonical generated id ${result.createdFact.id}',
          );
        }
        return result.updatedProject;
      });

  ProjectManifest updateFact(
    ProjectManifest project, {
    required List<MapData> maps,
    required NarrativeFactDefinition fact,
  }) =>
      _translate('fact.update_rejected', () {
        final preview = previewNarrativeFactTypeChange(
          project,
          factId: fact.id,
          nextKind: fact.valueKind,
          maps: maps,
        );
        return updateNarrativeFact(
          project,
          factId: fact.id,
          label: fact.label,
          description: fact.description,
          category: fact.category,
          initialValue: fact.initialValue,
          tags: fact.tags,
          legacyFlagName: fact.legacyFlagName,
          typeChangePreview: preview,
        ).updatedProject;
      });

  ProjectManifest deleteFact(
    ProjectManifest project, {
    required List<MapData> maps,
    required String factId,
  }) =>
      _translate(
        'fact.delete_rejected',
        () => removeNarrativeFact(
          project,
          factId: factId,
          maps: maps,
          dependencyIndex: buildNarrativeDependencyIndex(
            project: project,
            maps: maps,
          ),
        ).updatedProject,
      );

  ProjectManifest createWorldRule(
    ProjectManifest project, {
    required List<MapData> maps,
    required WorldRuleDefinition rule,
  }) =>
      _translate('world_rule.create_rejected', () {
        final result = addWorldRule(
          project,
          label: rule.label,
          description: rule.description,
          enabled: rule.enabled,
          source: rule.source,
          target: rule.target,
          effect: rule.effect,
          priority: rule.priority,
          tags: rule.tags,
          debugTechnicalLabel: rule.debugTechnicalLabel,
          maps: maps,
        );
        if (result.createdRule.id != rule.id) {
          throw ArgumentError.value(
            rule.id,
            'rule.id',
            'must equal the canonical generated id ${result.createdRule.id}',
          );
        }
        return result.updatedProject;
      });

  ProjectManifest updateWorldRuleDefinition(
    ProjectManifest project, {
    required List<MapData> maps,
    required WorldRuleDefinition rule,
  }) =>
      _translate(
        'world_rule.update_rejected',
        () => updateWorldRule(
          project,
          ruleId: rule.id,
          label: rule.label,
          description: rule.description,
          enabled: rule.enabled,
          source: rule.source,
          target: rule.target,
          effect: rule.effect,
          priority: rule.priority,
          tags: rule.tags,
          debugTechnicalLabel: rule.debugTechnicalLabel,
          maps: maps,
        ).updatedProject,
      );

  ProjectManifest deleteWorldRule(
    ProjectManifest project, {
    required String ruleId,
  }) =>
      _translate(
        'world_rule.delete_rejected',
        () => removeWorldRule(project, ruleId: ruleId).updatedProject,
      );

  AuthoringMutationDraft _draft(
    AuthoringPlanningContext context,
    ProjectManifest projected, {
    required String path,
    Object? before,
    Object? after,
  }) =>
      narrativeProjectDraft(
        context.snapshot,
        projected,
        operation: context.request.actionId,
        path: path,
        before: before,
        after: after,
        preview: const ModernNarrativeInspector()
            .inspect(project: projected, maps: context.snapshot.maps)
            .toJson(),
      );
}

T _translate<T>(String code, T Function() operation) {
  try {
    return operation();
  } on NarrativeAuthoringException {
    rethrow;
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      code,
      'The canonical narrative operation rejected the mutation.',
      details: {
        'validationType': error.runtimeType.toString(),
        'reason': error.toString(),
      },
    );
  }
}

NarrativeFactDefinition _decodeFact(Map<String, dynamic> json) {
  try {
    return NarrativeFactDefinition.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'fact.invalid',
      'The Fact payload cannot be decoded.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}

WorldRuleDefinition _decodeRule(Map<String, dynamic> json) {
  try {
    return WorldRuleDefinition.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'world_rule.invalid',
      'The World Rule payload cannot be decoded.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}
```

## `lib/src/domains/narrative/modern_narrative_inspection.dart`

```dart
import 'package:map_core/map_core.dart';

enum ModernNarrativeDiagnosticSeverity { error, warning, info }

final class ModernNarrativeDiagnostic {
  const ModernNarrativeDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.resourceKind,
    this.resourceId,
    this.path,
  });

  final String code;
  final ModernNarrativeDiagnosticSeverity severity;
  final String message;
  final String resourceKind;
  final String? resourceId;
  final String? path;

  Map<String, Object?> toJson() => {
        'code': code,
        'severity': severity.name,
        'message': message,
        'resourceKind': resourceKind,
        if (resourceId != null) 'resourceId': resourceId,
        if (path != null) 'path': path,
      };
}

final class NarrativeRuntimeConsumerTruth {
  const NarrativeRuntimeConsumerTruth({
    required this.domain,
    required this.authority,
    required this.supported,
  });

  final String domain;
  final String authority;
  final bool supported;

  Map<String, Object?> toJson() => {
        'domain': domain,
        'authority': authority,
        'supported': supported,
      };
}

final class ModernNarrativeInspectionReport {
  ModernNarrativeInspectionReport({
    required Iterable<ModernNarrativeDiagnostic> diagnostics,
    required Iterable<NarrativeRuntimeConsumerTruth> runtimeConsumers,
    required this.dependencyDefinitionCount,
    required this.dependencyUsageCount,
    required this.eventValidation,
    required this.eventReachability,
  })  : diagnostics = List.unmodifiable(diagnostics),
        runtimeConsumers = List.unmodifiable(runtimeConsumers);

  final List<ModernNarrativeDiagnostic> diagnostics;
  final List<NarrativeRuntimeConsumerTruth> runtimeConsumers;
  final int dependencyDefinitionCount;
  final int dependencyUsageCount;
  final Map<String, Object?> eventValidation;
  final Map<String, Object?> eventReachability;

  bool get canPublish => diagnostics.every(
        (item) => item.severity != ModernNarrativeDiagnosticSeverity.error,
      );

  Map<String, Object?> toJson() => {
        'canPublish': canPublish,
        'diagnostics': [for (final item in diagnostics) item.toJson()],
        'runtimeConsumers': [
          for (final item in runtimeConsumers) item.toJson()
        ],
        'dependencyImpact': {
          'definitionCount': dependencyDefinitionCount,
          'usageCount': dependencyUsageCount,
        },
        'eventValidation': eventValidation,
        'eventReachability': eventReachability,
      };
}

/// Consolidates authoring gates while retaining `map_core` as the authority.
final class ModernNarrativeInspector {
  const ModernNarrativeInspector();

  ModernNarrativeInspectionReport inspect({
    required ProjectManifest project,
    required List<MapData> maps,
  }) {
    final diagnostics = <ModernNarrativeDiagnostic>[];
    final mapsById = {for (final map in maps) map.id: map};
    for (final scene in project.scenes) {
      final report = diagnoseSceneAgainstProject(
        scene,
        project,
        mapsById: mapsById,
      );
      for (final item in report.diagnostics) {
        diagnostics.add(
          ModernNarrativeDiagnostic(
            code: 'scene.${item.code.name}',
            severity: _sceneSeverity(item.severity),
            message: item.message,
            resourceKind: 'scene',
            resourceId: item.sceneId,
            path: item.nodeId == null ? null : 'nodes.${item.nodeId}',
          ),
        );
      }
      if (!buildSceneRuntimePlan(scene).canBuild && !report.hasErrors) {
        diagnostics.add(
          ModernNarrativeDiagnostic(
            code: 'scene.runtimePlanUnavailable',
            severity: ModernNarrativeDiagnosticSeverity.error,
            message: 'The canonical runtime cannot build this Scene.',
            resourceKind: 'scene',
            resourceId: scene.id,
          ),
        );
      }
    }

    final worldRules = diagnoseWorldRules(project, maps: maps);
    for (final item in worldRules.diagnostics) {
      diagnostics.add(
        ModernNarrativeDiagnostic(
          code: 'worldRule.${item.code.name}',
          severity: _worldRuleSeverity(item.severity),
          message: item.message,
          resourceKind: 'worldRule',
          resourceId: item.ruleId,
          path: item.mapId,
        ),
      );
    }

    final registry = project.eventRegistry;
    var validation = <String, Object?>{
      'errorCount': 0,
      'warningCount': 0,
      'diagnostics': const <Object?>[],
    };
    var reachability = <String, Object?>{
      'sources': const <Object?>[],
      'diagnostics': const <Object?>[],
    };
    if (registry != null) {
      final catalog = buildNarrativeEventProjectCatalog(
        project: project,
        maps: maps,
      );
      final validationReport = buildNarrativeEventValidationReport(
        registry: registry,
        catalog: catalog,
      );
      validation = validationReport.toDebugJson();
      for (final item in validationReport.diagnostics) {
        diagnostics.add(
          ModernNarrativeDiagnostic(
            code: 'eventV2.${item.code}',
            severity: _eventSeverity(item.severity),
            message: item.message,
            resourceKind: 'eventV2',
            resourceId: item.eventId,
            path: item.path,
          ),
        );
      }
      reachability = buildNarrativeEventReachabilityReport(
        registry: registry,
        catalog: catalog,
      ).toDebugJson();
    }

    final dependencies = buildNarrativeDependencyIndex(
      project: project,
      maps: maps,
    );
    for (final item in dependencies.issues) {
      diagnostics.add(
        ModernNarrativeDiagnostic(
          code: 'dependency.${item.kind.name}',
          severity:
              item.criticality == NarrativeDependencyCriticality.runtimeBlocking
                  ? ModernNarrativeDiagnosticSeverity.error
                  : ModernNarrativeDiagnosticSeverity.warning,
          message: item.message,
          resourceKind: item.target.kind.name,
          resourceId: item.target.id,
          path: item.path,
        ),
      );
    }
    diagnostics.sort((left, right) {
      final kind = left.resourceKind.compareTo(right.resourceKind);
      if (kind != 0) return kind;
      final id = (left.resourceId ?? '').compareTo(right.resourceId ?? '');
      if (id != 0) return id;
      return left.code.compareTo(right.code);
    });

    return ModernNarrativeInspectionReport(
      diagnostics: diagnostics,
      runtimeConsumers: const [
        NarrativeRuntimeConsumerTruth(
          domain: 'scene',
          authority: 'buildSceneRuntimePlan',
          supported: true,
        ),
        NarrativeRuntimeConsumerTruth(
          domain: 'eventV2',
          authority: 'NarrativeEventDispatchAuthority',
          supported: true,
        ),
        NarrativeRuntimeConsumerTruth(
          domain: 'worldRule',
          authority: 'projectWorldRuleEffects',
          supported: true,
        ),
      ],
      dependencyDefinitionCount: dependencies.definitions.length,
      dependencyUsageCount: dependencies.usages.length,
      eventValidation: validation,
      eventReachability: reachability,
    );
  }
}

ModernNarrativeDiagnosticSeverity _sceneSeverity(
  SceneDiagnosticSeverity value,
) =>
    switch (value) {
      SceneDiagnosticSeverity.error => ModernNarrativeDiagnosticSeverity.error,
      SceneDiagnosticSeverity.warning =>
        ModernNarrativeDiagnosticSeverity.warning,
      SceneDiagnosticSeverity.info => ModernNarrativeDiagnosticSeverity.info,
    };

ModernNarrativeDiagnosticSeverity _worldRuleSeverity(
  WorldRuleDiagnosticSeverity value,
) =>
    switch (value) {
      WorldRuleDiagnosticSeverity.error =>
        ModernNarrativeDiagnosticSeverity.error,
      WorldRuleDiagnosticSeverity.warning =>
        ModernNarrativeDiagnosticSeverity.warning,
      WorldRuleDiagnosticSeverity.info =>
        ModernNarrativeDiagnosticSeverity.info,
    };

ModernNarrativeDiagnosticSeverity _eventSeverity(
  NarrativeEventValidationSeverity value,
) =>
    switch (value) {
      NarrativeEventValidationSeverity.error =>
        ModernNarrativeDiagnosticSeverity.error,
      NarrativeEventValidationSeverity.warning =>
        ModernNarrativeDiagnosticSeverity.warning,
      NarrativeEventValidationSeverity.info =>
        ModernNarrativeDiagnosticSeverity.info,
    };
```

## `lib/src/domains/narrative/narrative_action_support.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import '../maps/map_lifecycle_adapter.dart';

AuthoringActionDescriptor narrativeActionDescriptor(
  String id,
  String summary, {
  List<String> resourceKinds = const ['project'],
  AuthoringRiskLevel risk = AuthoringRiskLevel.medium,
}) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring/$id.input.v1',
      outputSchemaId: 'pokemap.authoring/$id.output.v1',
      riskLevel: risk,
      resourceKinds: resourceKinds,
      capabilityIds: const ['authoring.narrative.modern'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
    );

AuthoringMutationDraft narrativeProjectDraft(
  ProjectSnapshot snapshot,
  ProjectManifest projected, {
  required String operation,
  required String path,
  Object? before,
  Object? after,
  Map<String, Object?> preview = const {},
}) {
  final project = AuthoringResourceRef(
    kind: 'project',
    id: 'project',
    revision: snapshot.resourceFingerprints['project'],
  );
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: [
        AuthoringResourceChange(
          resource: project,
          storageKey: 'project.json',
          beforeBytes: snapshot.resourceBytes('project'),
          afterBytes: encodeProjectAuthoringDocument(snapshot, projected),
        ),
      ],
      diff: AuthoringDiff([
        AuthoringDiffEntry(
          operation: operation.endsWith('.delete')
              ? AuthoringDiffOperation.remove
              : before == null
                  ? AuthoringDiffOperation.add
                  : AuthoringDiffOperation.replace,
          resource: project,
          path: path,
          before: before,
          after: after,
        ),
      ]),
    ),
    preview: {'operation': operation, 'path': path, ...preview},
  );
}

Map<String, dynamic> narrativeObjectParameter(
  Map<String, Object?> parameters,
  String key,
) {
  final raw = parameters[key];
  if (raw is! Map) {
    throw ArgumentError.value(raw, key, 'must be a JSON object');
  }
  return Map<String, dynamic>.from(raw);
}

String narrativeStringParameter(
  Map<String, Object?> parameters,
  String key,
) {
  final value = parameters[key];
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw ArgumentError.value(value, key, 'must be a nonblank trimmed string');
  }
  return value;
}

void rejectUnknownNarrativeParameters(
  Map<String, Object?> parameters,
  Set<String> allowed,
) {
  final unknown =
      parameters.keys.where((key) => !allowed.contains(key)).toList()..sort();
  if (unknown.isNotEmpty) {
    throw ArgumentError.value(unknown, 'parameters', 'contains unknown keys');
  }
}
```

## `lib/src/domains/narrative/scene_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'modern_narrative_inspection.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';

final class SceneActions {
  const SceneActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    narrativeActionDescriptor(
      'scene.upsert',
      'Create or replace a complete Scene graph',
      resourceKinds: const ['project', 'scene'],
    ),
    narrativeActionDescriptor(
      'scene.delete',
      'Delete an unreferenced Scene or replace its references',
      resourceKinds: const ['project', 'scene'],
      risk: AuthoringRiskLevel.high,
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    switch (context.request.actionId) {
      case 'scene.upsert':
        rejectUnknownNarrativeParameters(parameters, const {'scene'});
        final scene =
            _decodeScene(narrativeObjectParameter(parameters, 'scene'));
        final before = context.snapshot.manifest.scenes
            .where((candidate) => candidate.id == scene.id)
            .firstOrNull;
        final projected = upsert(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          scene: scene,
        );
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/${scene.id}',
          before: before?.toJson(),
          after: scene.toJson(),
          preview: const ModernNarrativeInspector()
              .inspect(project: projected, maps: context.snapshot.maps)
              .toJson(),
        );
      case 'scene.delete':
        rejectUnknownNarrativeParameters(
          parameters,
          const {'sceneId', 'replacementSceneId'},
        );
        final sceneId = narrativeStringParameter(parameters, 'sceneId');
        final before = context.snapshot.manifest.scenes
            .where((candidate) => candidate.id == sceneId)
            .firstOrNull;
        final replacement = parameters['replacementSceneId'];
        if (replacement != null && replacement is! String) {
          throw ArgumentError.value(
            replacement,
            'replacementSceneId',
            'must be a string',
          );
        }
        final projected = delete(
          context.snapshot.manifest,
          sceneId: sceneId,
          replacementSceneId: replacement as String?,
        );
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/scenes/$sceneId',
          before: before?.toJson(),
          preview: const ModernNarrativeInspector()
              .inspect(project: projected, maps: context.snapshot.maps)
              .toJson(),
        );
      default:
        throw NarrativeAuthoringException(
          'scene.action_unsupported',
          'The requested Scene action is unsupported.',
        );
    }
  }

  ProjectManifest upsert(
    ProjectManifest project, {
    required List<MapData> maps,
    required SceneAsset scene,
  }) {
    final exists = project.scenes.any((candidate) => candidate.id == scene.id);
    final projected = project.copyWith(
      scenes: exists
          ? [
              for (final candidate in project.scenes)
                if (candidate.id == scene.id) scene else candidate,
            ]
          : [...project.scenes, scene],
    );
    final diagnostics = diagnoseSceneAgainstProject(
      scene,
      projected,
      mapsById: {for (final map in maps) map.id: map},
    );
    final runtimePlan = buildSceneRuntimePlan(scene);
    if (diagnostics.hasErrors || !runtimePlan.canBuild) {
      throw NarrativeAuthoringException(
        'scene.publication_blocked',
        'The Scene is not safe for the canonical runtime.',
        details: {
          'diagnostics': [
            for (final item in diagnostics.diagnostics)
              {
                'code': item.code.name,
                'severity': item.severity.name,
                'message': item.message,
                if (item.nodeId != null) 'nodeId': item.nodeId,
                if (item.edgeId != null) 'edgeId': item.edgeId,
              },
          ],
          'runtimePlanBuildable': runtimePlan.canBuild,
        },
      );
    }
    return projected;
  }

  ProjectManifest delete(
    ProjectManifest project, {
    required String sceneId,
    String? replacementSceneId,
  }) {
    final result = deleteSceneFromProject(
      project,
      sceneId: sceneId,
      replacementSceneId: replacementSceneId,
      dependencyIndex: buildNarrativeDependencyIndex(project: project),
    );
    if (!result.isApplied) {
      throw NarrativeAuthoringException(
        result.code ?? 'scene.delete_rejected',
        result.message ?? 'The canonical Scene deletion was rejected.',
        details: {'referencePaths': result.referencePaths},
      );
    }
    return result.after;
  }
}

SceneAsset _decodeScene(Map<String, dynamic> json) {
  try {
    return SceneAsset.fromJson(json);
  } on Object catch (error) {
    throw NarrativeAuthoringException(
      'scene.invalid',
      'The Scene payload cannot be decoded.',
      details: {'validationType': error.runtimeType.toString()},
    );
  }
}
```

## `test/domains/narrative/modern_narrative_authoring_test.dart`

```dart
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('modern narrative authoring', () {
    test('publication gate uses canonical Scene and runtime diagnostics', () {
      final project = _manifest(
        scenes: [
          SceneAsset(
            id: 'broken_scene',
            name: 'Broken scene',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
              edges: const [],
            ),
          ),
        ],
      );

      final report = const ModernNarrativeInspector().inspect(
        project: project,
        maps: [],
      );

      expect(report.canPublish, isFalse);
      expect(
        report.diagnostics.map((item) => item.code),
        contains('scene.missingEndNode'),
      );
      expect(
        report.runtimeConsumers.map((item) => item.authority),
        containsAll({
          'buildSceneRuntimePlan',
          'NarrativeEventDispatchAuthority',
          'projectWorldRuleEffects',
        }),
      );
    });

    test('Scene deletion is blocked by the canonical dependency index', () {
      final scene = _scene();
      final project = _manifest(
        scenes: [scene],
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: 'evt_018f0f8c-7b8a-7def-8000-000000000001',
                name: 'Uses scene',
                conditions: const [],
                sceneId: scene.id,
                priority: 0,
                order: 0,
              ),
            ),
          ],
          legacyClaims: const [],
        ),
      );

      expect(
        () => const SceneActions().delete(project, sceneId: scene.id),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'sceneReferenced',
          ),
        ),
      );
    });

    test('Event V2 publication rejects an incomplete draft canonically', () {
      final project = _manifest(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: [
            NarrativeEventRecord.draft(
              NarrativeEventDraft(
                id: 'evt_018f0f8c-7b8a-7def-8000-000000000002',
                name: 'Incomplete',
                conditions: const [],
                priority: 0,
                order: 0,
              ),
            ),
          ],
          legacyClaims: const [],
        ),
      );

      expect(
        () => const EventV2Actions().publish(
          project,
          maps: const [],
          revision: 'revision-1',
          eventId: 'evt_018f0f8c-7b8a-7def-8000-000000000002',
        ),
        throwsA(
          isA<NarrativeAuthoringException>().having(
            (error) => error.code,
            'code',
            'sourceRequired',
          ),
        ),
      );
    });

    test('Fact type changes require a dependency-safe canonical preview', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_gate',
        label: 'Gate',
      );
      final project = _manifest(
        facts: [fact],
        scenes: [
          SceneAsset(
            id: 'condition_scene',
            name: 'Condition scene',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: [
                SceneNode(id: 'start', kind: SceneNodeKind.start),
                SceneNode(
                  id: 'condition',
                  kind: SceneNodeKind.condition,
                  payload: SceneConditionPayload(
                    conditionSource: SceneConditionSource(
                      sourceKind: SceneConditionSourceKind.fact,
                      sourceId: fact.id,
                      operator: SceneConditionOperator.isTrue,
                    ),
                  ),
                ),
                SceneNode(id: 'end', kind: SceneNodeKind.end),
              ],
              edges: [
                SceneEdge(
                  id: 'start_condition',
                  fromNodeId: 'start',
                  fromPortId: 'completed',
                  toNodeId: 'condition',
                  kind: SceneEdgeKind.defaultFlow,
                ),
                SceneEdge(
                  id: 'condition_true',
                  fromNodeId: 'condition',
                  fromPortId: 'true',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.conditionTrue,
                ),
                SceneEdge(
                  id: 'condition_false',
                  fromNodeId: 'condition',
                  fromPortId: 'false',
                  toNodeId: 'end',
                  kind: SceneEdgeKind.conditionFalse,
                ),
              ],
            ),
          ),
        ],
      );

      expect(
        () => const FactRuleActions().updateFact(
          project,
          maps: const [],
          fact: NarrativeFactDefinition(
            id: 'fact_gate',
            label: 'Gate',
            initialValue: NarrativeValue.integer(1),
          ),
        ),
        throwsA(isA<NarrativeAuthoringException>()),
      );
    });

    test('canonical dispatcher and reads expose modern narrative resources',
        () {
      final ids = AuthoringMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();
      expect(
        ids,
        containsAll({
          'scene.upsert',
          'scene.delete',
          'event_v2.record_upsert',
          'event_v2.publish',
          'event_v2.activate',
          'event_v2.deactivate',
          'event_v2.delete',
          'fact.create',
          'fact.update',
          'fact.delete',
          'world_rule.create',
          'world_rule.update',
          'world_rule.delete',
        }),
      );
      expect(
        AuthoringResourceKindRegistry.canonicalMinimal()
            .resourceKinds
            .map((kind) => kind.id),
        containsAll({'scene', 'eventV2', 'fact', 'worldRule'}),
      );
    });
  });
}

ProjectManifest _manifest({
  List<SceneAsset> scenes = const [],
  List<NarrativeFactDefinition> facts = const [],
  NarrativeEventRegistry? eventRegistry,
}) =>
    ProjectManifest(
      name: 'Modern narrative fixture',
      maps: const [],
      tilesets: const [],
      scenes: scenes,
      facts: facts,
      eventRegistry: eventRegistry,
    );

SceneAsset _scene() => SceneAsset(
      id: 'intro_scene',
      name: 'Intro scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );
```
