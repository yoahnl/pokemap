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
