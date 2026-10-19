import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'modern_narrative_inspection.dart';
import 'narrative_action_support.dart';
import 'narrative_authoring_exception.dart';
import 'dialogue_fact_snapshot.dart';

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
        'world_rule.upsert_batch',
        'Create or update a bounded atomic World Rule batch',
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
        extensions: entry.$1 == 'world_rule.upsert_batch'
            ? const {
                'batch': {
                  'minRules': 1,
                  'maxRules': maxWorldRuleBatchSize,
                  'uniqueBy': 'id',
                  'semantics': 'createOrUpdate',
                  'atomic': true,
                },
                'rules': {
                  'type': 'array',
                  'minItems': 1,
                  'maxItems': maxWorldRuleBatchSize,
                  'uniqueBy': 'id',
                },
              }
            : const {},
        risk: entry.$1.endsWith('.delete')
            ? AuthoringRiskLevel.high
            : AuthoringRiskLevel.medium,
      ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    final parameters = context.request.parameters;
    switch (context.request.actionId) {
      case 'world_rule.upsert_batch':
        final rules = _decodeRuleBatch(parameters);
        final projected = upsertWorldRuleDefinitions(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          rules: rules,
        );
        return narrativeProjectDraft(
          context.snapshot,
          projected,
          operation: context.request.actionId,
          path: '/worldRules',
          before: context.snapshot.manifest.worldRules
              .map((rule) => rule.toJson())
              .toList(),
          after: projected.worldRules.map((rule) => rule.toJson()).toList(),
          preview: {'ruleIds': rules.map((rule) => rule.id).toList()},
          includeInspectionPreview: true,
        );
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
        final documents = snapshotDialogueDocuments(context.snapshot);
        if (documents.entries.any((entry) => dialogueDocumentFactIds(entry.value).contains(id))) {
          throw NarrativeAuthoringException('fact.delete_rejected', 'A dialogue still references this Fact.',
              details: {'dialogueIds': [for (final entry in documents.entries)
                if (dialogueDocumentFactIds(entry.value).contains(id)) entry.key]});
        }
        final before = context.snapshot.manifest.facts
            .where((candidate) => candidate.id == id)
            .firstOrNull;
        final projected = deleteFact(
          context.snapshot.manifest,
          maps: context.snapshot.maps,
          factId: id,
          dialogueDocuments: documents,
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
    Map<String, RuntimeDialogueDocument> dialogueDocuments = const {},
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
            dialogueDocuments: dialogueDocuments,
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

  ProjectManifest upsertWorldRuleDefinitions(
    ProjectManifest project, {
    required List<MapData> maps,
    required List<WorldRuleDefinition> rules,
  }) {
    if (rules.isEmpty || rules.length > maxWorldRuleBatchSize) {
      throw NarrativeAuthoringException(
        'world_rule.batch_invalid',
        'A World Rule batch requires 1 to $maxWorldRuleBatchSize rules.',
      );
    }
    final ids = <String>{};
    for (var index = 0; index < rules.length; index++) {
      if (!ids.add(rules[index].id)) {
        throw NarrativeAuthoringException(
          'world_rule.batch_duplicate_id',
          'World Rule batch ids must be unique.',
          details: {
            'index': index,
            'ruleId': rules[index].id,
            'reason': 'The rule id appears more than once in this batch.',
          },
        );
      }
    }
    try {
      return upsertWorldRules(project, maps: maps, rules: rules);
    } on WorldRuleBatchException catch (error) {
      throw NarrativeAuthoringException(
        'world_rule.batch_rejected',
        'The canonical World Rule operation rejected a batch member.',
        details: {
          'index': error.index,
          'ruleId': rules[error.index].id,
          'validationType': error.cause.runtimeType.toString(),
          'reason': error.cause.toString(),
        },
      );
    }
  }

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
            .inspect(
              project: projected,
              maps: context.snapshot.maps,
              itemCatalog: context.snapshot.itemCatalog,
            )
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

List<WorldRuleDefinition> _decodeRuleBatch(Map<String, Object?> parameters) {
  if (parameters.keys.any((key) => key != 'rules')) {
    throw NarrativeAuthoringException(
      'world_rule.batch_invalid',
      'The World Rule batch accepts only the rules parameter.',
    );
  }
  final raw = parameters['rules'];
  if (raw is! List || raw.isEmpty || raw.length > maxWorldRuleBatchSize) {
    throw NarrativeAuthoringException(
      'world_rule.batch_invalid',
      'A World Rule batch requires 1 to $maxWorldRuleBatchSize rules.',
    );
  }
  final rules = <WorldRuleDefinition>[];
  for (var index = 0; index < raw.length; index++) {
    try {
      final value = raw[index];
      if (value is! Map) {
        throw const FormatException('A World Rule must be a JSON object.');
      }
      rules.add(WorldRuleDefinition.fromJson(Map<String, dynamic>.from(value)));
    } on Object catch (error) {
      throw NarrativeAuthoringException(
        'world_rule.batch_rule_invalid',
        'The World Rule batch member cannot be decoded.',
        details: {
          'index': index,
          'validationType': error.runtimeType.toString(),
          'reason': error.toString(),
        },
      );
    }
  }
  return rules;
}
