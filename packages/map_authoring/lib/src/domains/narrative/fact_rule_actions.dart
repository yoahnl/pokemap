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
