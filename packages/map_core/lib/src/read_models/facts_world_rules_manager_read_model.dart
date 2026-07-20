import '../diagnostics/world_rule_diagnostics.dart';
import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/narrative_fact.dart';
import '../models/narrative_fact_runtime_state.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/storyline_asset.dart';
import '../models/world_rule.dart';
import 'narrative_dependency_index.dart';

enum FactManagerUsageKind {
  sceneCondition,
  sceneConsequence,
  worldRuleSource,
  newGame,
  eventV2,
  storylineEffect,
  legacySource,
}

final class FactsWorldRulesManagerReadModel {
  FactsWorldRulesManagerReadModel({
    required List<FactManagerEntry> facts,
    required List<WorldRuleManagerEntry> worldRules,
    required List<WorldRuleSourcePickerOption> sourceOptions,
    required List<WorldRuleTargetPickerOption> targetOptions,
    required List<WorldRuleEffectPickerOption> effectOptions,
    required List<WorldRuleDialoguePickerOption> dialogueOptions,
    required List<String> factCategories,
  })  : facts = List<FactManagerEntry>.unmodifiable(facts),
        worldRules = List<WorldRuleManagerEntry>.unmodifiable(worldRules),
        sourceOptions =
            List<WorldRuleSourcePickerOption>.unmodifiable(sourceOptions),
        targetOptions =
            List<WorldRuleTargetPickerOption>.unmodifiable(targetOptions),
        effectOptions =
            List<WorldRuleEffectPickerOption>.unmodifiable(effectOptions),
        dialogueOptions =
            List<WorldRuleDialoguePickerOption>.unmodifiable(dialogueOptions),
        factCategories = List<String>.unmodifiable(factCategories);

  final List<FactManagerEntry> facts;
  final List<WorldRuleManagerEntry> worldRules;
  final List<WorldRuleSourcePickerOption> sourceOptions;
  final List<WorldRuleTargetPickerOption> targetOptions;
  final List<WorldRuleEffectPickerOption> effectOptions;
  final List<WorldRuleDialoguePickerOption> dialogueOptions;
  final List<String> factCategories;

  int get factCount => facts.length;

  int get usedFactCount => facts.where((fact) => fact.isUsed).length;

  int get unusedFactCount => facts.where((fact) => !fact.isUsed).length;

  int get worldRuleCount => worldRules.length;

  int get enabledWorldRuleCount =>
      worldRules.where((rule) => rule.rule.enabled).length;

  int get disabledWorldRuleCount => worldRuleCount - enabledWorldRuleCount;

  int get worldRuleDiagnosticCount =>
      worldRules.fold(0, (total, rule) => total + rule.diagnostics.length);

  FactManagerEntry? factById(String factId) {
    for (final fact in facts) {
      if (fact.fact.id == factId) {
        return fact;
      }
    }
    return null;
  }
}

final class FactManagerEntry {
  FactManagerEntry({
    required this.fact,
    required List<FactManagerUsage> usages,
    required this.hasRuntimeOverride,
    required this.runtimeOverrideValue,
  }) : usages = List<FactManagerUsage>.unmodifiable(usages);

  final NarrativeFactDefinition fact;
  final List<FactManagerUsage> usages;
  final bool hasRuntimeOverride;
  final bool? runtimeOverrideValue;

  bool get isUsed => usages.isNotEmpty;

  bool get initialValue => fact.defaultValue;

  bool get effectiveValue => runtimeOverrideValue ?? initialValue;

  List<FactManagerUsage> get readerUsages => List.unmodifiable(
        usages.where((usage) => !_isFactWriterUsage(usage)),
      );

  List<FactManagerUsage> get writerUsages => List.unmodifiable(
        usages.where(_isFactWriterUsage),
      );
}

final class FactManagerUsage {
  const FactManagerUsage({
    required this.kind,
    required this.factId,
    required this.ownerId,
    required this.ownerLabel,
    required this.details,
    this.referenceResolution = NarrativeDependencyResolution.resolved,
    this.dependencyPath,
    this.dependencyOwner,
  });

  final FactManagerUsageKind kind;
  final String factId;
  final String ownerId;
  final String ownerLabel;
  final String details;
  final NarrativeDependencyResolution referenceResolution;
  final String? dependencyPath;
  final NarrativeDependencyKey? dependencyOwner;
}

final class WorldRuleManagerEntry {
  WorldRuleManagerEntry({
    required this.rule,
    required this.sourceLabel,
    required this.targetLabel,
    required this.effectLabel,
    required this.humanSummary,
    required List<WorldRuleDiagnostic> diagnostics,
  }) : diagnostics = List<WorldRuleDiagnostic>.unmodifiable(diagnostics);

  final WorldRuleDefinition rule;
  final String sourceLabel;
  final String targetLabel;
  final String effectLabel;
  final String humanSummary;
  final List<WorldRuleDiagnostic> diagnostics;

  bool get hasDiagnostics => diagnostics.isNotEmpty;
}

final class WorldRuleSourcePickerOption {
  const WorldRuleSourcePickerOption({
    required this.kind,
    required this.sourceId,
    required this.predicate,
    required this.label,
    required this.subtitle,
    required this.debugTechnicalLabel,
  });

  final WorldRuleSourceKind kind;
  final String sourceId;
  final WorldRuleSourcePredicate predicate;
  final String label;
  final String subtitle;
  final String debugTechnicalLabel;
}

final class WorldRuleTargetPickerOption {
  const WorldRuleTargetPickerOption({
    required this.kind,
    required this.mapId,
    this.entityId,
    this.eventId,
    required this.label,
    required this.subtitle,
    required this.debugTechnicalLabel,
  });

  final WorldRuleTargetKind kind;
  final String mapId;
  final String? entityId;
  final String? eventId;
  final String label;
  final String subtitle;
  final String debugTechnicalLabel;
}

final class WorldRuleEffectPickerOption {
  const WorldRuleEffectPickerOption({
    required this.effectKind,
    required this.compatibleTargetKind,
    required this.label,
    required this.requiresDialogue,
  });

  final WorldRuleEffectKind effectKind;
  final WorldRuleTargetKind compatibleTargetKind;
  final String label;
  final bool requiresDialogue;
}

final class WorldRuleDialoguePickerOption {
  const WorldRuleDialoguePickerOption({
    required this.dialogueId,
    required this.label,
    required this.subtitle,
  });

  final String dialogueId;
  final String label;
  final String subtitle;
}

FactsWorldRulesManagerReadModel buildFactsWorldRulesManagerReadModel(
  ProjectManifest project, {
  List<MapData> maps = const <MapData>[],
  NarrativeDependencyIndex? dependencyIndex,
  NarrativeFactRuntimeState? runtimeState,
}) {
  final usagesByFactId = <String, List<FactManagerUsage>>{
    for (final fact in project.facts) fact.id: <FactManagerUsage>[],
  };
  final factUsages = dependencyIndex == null
      ? _collectFactUsages(project)
      : _collectFactUsagesFromDependencyIndex(dependencyIndex);
  for (final usage in factUsages) {
    usagesByFactId.putIfAbsent(usage.factId, () => <FactManagerUsage>[]);
    usagesByFactId[usage.factId]!.add(usage);
  }
  for (final usages in usagesByFactId.values) {
    usages.sort(_compareFactUsages);
  }

  final factById = {for (final fact in project.facts) fact.id: fact};
  final mapById = {for (final map in maps) map.id: map};
  final dialogueById = {
    for (final dialogue in project.dialogues) dialogue.id: dialogue,
  };
  final diagnosticsReport = diagnoseWorldRules(project, maps: maps);
  final worldRules = project.worldRules.toList(growable: false)
    ..sort(_compareWorldRules);
  final categories = <String>{
    '',
    ...project.facts.map((fact) => fact.category),
  }.toList()
    ..sort();

  return FactsWorldRulesManagerReadModel(
    facts: [
      for (final fact in project.facts)
        FactManagerEntry(
          fact: fact,
          usages: usagesByFactId[fact.id] ?? const <FactManagerUsage>[],
          hasRuntimeOverride:
              runtimeState?.overridesByFactId.containsKey(fact.id) ?? false,
          runtimeOverrideValue: runtimeState?.overridesByFactId[fact.id],
        ),
    ],
    worldRules: [
      for (final rule in worldRules)
        _buildWorldRuleEntry(
          rule,
          factById: factById,
          mapById: mapById,
          dialogueById: dialogueById,
          diagnostics: diagnosticsReport.byRuleId(rule.id),
        ),
    ],
    sourceOptions: _buildSourceOptions(project, maps: maps),
    targetOptions: _buildTargetOptions(project, maps: maps),
    effectOptions: _buildEffectOptions(),
    dialogueOptions: _buildDialogueOptions(project),
    factCategories: categories,
  );
}

bool _isFactWriterUsage(FactManagerUsage usage) {
  return switch (usage.kind) {
    FactManagerUsageKind.sceneConsequence ||
    FactManagerUsageKind.storylineEffect =>
      true,
    FactManagerUsageKind.newGame =>
      (usage.dependencyPath ?? usage.details).contains('.initialFacts['),
    FactManagerUsageKind.sceneCondition ||
    FactManagerUsageKind.worldRuleSource ||
    FactManagerUsageKind.eventV2 ||
    FactManagerUsageKind.legacySource =>
      false,
  };
}

Iterable<FactManagerUsage> _collectFactUsagesFromDependencyIndex(
  NarrativeDependencyIndex index,
) sync* {
  for (final usage in index.usages) {
    if (usage.target.kind != NarrativeDependencyTargetKind.fact) continue;
    yield FactManagerUsage(
      kind: _factManagerKindForDependency(usage),
      factId: usage.target.id,
      ownerId: usage.owner.id,
      ownerLabel: _dependencyOwnerLabel(index, usage.owner),
      details: usage.path,
      referenceResolution: usage.resolution,
      dependencyPath: usage.path,
      dependencyOwner: usage.owner,
    );
  }
}

FactManagerUsageKind _factManagerKindForDependency(
  NarrativeDependencyUsage usage,
) {
  switch (usage.owner.kind) {
    case NarrativeDependencyTargetKind.scene:
      return usage.path.contains('.consequence.')
          ? FactManagerUsageKind.sceneConsequence
          : FactManagerUsageKind.sceneCondition;
    case NarrativeDependencyTargetKind.worldRule:
      return FactManagerUsageKind.worldRuleSource;
    case NarrativeDependencyTargetKind.eventV2:
      return FactManagerUsageKind.eventV2;
    case NarrativeDependencyTargetKind.storyline:
      return FactManagerUsageKind.storylineEffect;
    case NarrativeDependencyTargetKind.sourceMap:
      return usage.owner == const NarrativeDependencyKey.projectNewGame()
          ? FactManagerUsageKind.newGame
          : FactManagerUsageKind.legacySource;
    default:
      return FactManagerUsageKind.legacySource;
  }
}

String _dependencyOwnerLabel(
  NarrativeDependencyIndex index,
  NarrativeDependencyKey owner,
) {
  if (owner == const NarrativeDependencyKey.projectNewGame()) {
    return 'New Game';
  }
  final definitions = index.definitionsFor(owner);
  return definitions.length == 1 ? definitions.single.label : owner.id;
}

Iterable<FactManagerUsage> _collectFactUsages(ProjectManifest project) sync* {
  for (final scene in project.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is SceneConditionPayload) {
        final source = payload.conditionSource;
        if (source?.sourceKind == SceneConditionSourceKind.fact) {
          yield FactManagerUsage(
            kind: FactManagerUsageKind.sceneCondition,
            factId: source!.sourceId,
            ownerId: scene.id,
            ownerLabel: scene.name,
            details: 'Condition ${node.title ?? node.id}',
          );
        }
      }
      if (payload is SceneActionPayload) {
        final consequence = payload.consequence;
        if (consequence is SceneSetFactConsequence) {
          yield FactManagerUsage(
            kind: FactManagerUsageKind.sceneConsequence,
            factId: consequence.factId,
            ownerId: scene.id,
            ownerLabel: scene.name,
            details: 'Conséquence ${node.title ?? node.id}',
          );
        }
      }
    }
  }
  for (final rule in project.worldRules) {
    if (rule.source.kind == WorldRuleSourceKind.fact) {
      yield FactManagerUsage(
        kind: FactManagerUsageKind.worldRuleSource,
        factId: rule.source.sourceId,
        ownerId: rule.id,
        ownerLabel: rule.label,
        details: 'Source de règle du monde',
      );
    }
  }
}

WorldRuleManagerEntry _buildWorldRuleEntry(
  WorldRuleDefinition rule, {
  required Map<String, NarrativeFactDefinition> factById,
  required Map<String, MapData> mapById,
  required Map<String, ProjectDialogueEntry> dialogueById,
  required List<WorldRuleDiagnostic> diagnostics,
}) {
  final sourceLabel = _sourceLabel(rule.source, factById);
  final targetLabel = _targetLabel(rule.target, mapById);
  final effectLabel = _effectLabel(rule.effect, dialogueById);
  return WorldRuleManagerEntry(
    rule: rule,
    sourceLabel: sourceLabel,
    targetLabel: targetLabel,
    effectLabel: effectLabel,
    humanSummary: 'Si $sourceLabel alors $effectLabel sur $targetLabel',
    diagnostics: diagnostics,
  );
}

List<WorldRuleSourcePickerOption> _buildSourceOptions(
  ProjectManifest project, {
  required List<MapData> maps,
}) {
  final options = <WorldRuleSourcePickerOption>[
    for (final fact in project.facts)
      WorldRuleSourcePickerOption(
        kind: WorldRuleSourceKind.fact,
        sourceId: fact.id,
        predicate: WorldRuleSourcePredicate.isTrue,
        label: fact.label,
        subtitle: fact.category.isEmpty ? 'Fact booléen' : fact.category,
        debugTechnicalLabel: fact.legacyFlagName ?? fact.id,
      ),
    for (final step in _storySteps(project))
      WorldRuleSourcePickerOption(
        kind: WorldRuleSourceKind.storyStepCompletion,
        sourceId: step.id,
        predicate: WorldRuleSourcePredicate.completed,
        label: step.title,
        subtitle: 'Étape narrative',
        debugTechnicalLabel: step.id,
      ),
    for (final map in maps)
      for (final event in map.events)
        WorldRuleSourcePickerOption(
          kind: WorldRuleSourceKind.consumedEvent,
          sourceId: event.id,
          predicate: WorldRuleSourcePredicate.consumed,
          label: _eventLabel(event),
          subtitle: map.name,
          debugTechnicalLabel: '${map.id}:${event.id}',
        ),
  ];
  options.sort((a, b) {
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) {
      return byKind;
    }
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });
  return options;
}

List<WorldRuleTargetPickerOption> _buildTargetOptions(
  ProjectManifest project, {
  required List<MapData> maps,
}) {
  final manifestMapNames = {
    for (final map in project.maps) map.id: map.name,
  };
  final options = <WorldRuleTargetPickerOption>[];
  for (final map in maps) {
    final mapLabel = manifestMapNames[map.id] ?? map.name;
    for (final entity in map.entities) {
      final entityLabel = _entityLabel(entity);
      options.add(
        WorldRuleTargetPickerOption(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: map.id,
          entityId: entity.id,
          label: entityLabel,
          subtitle: '$mapLabel · entité',
          debugTechnicalLabel: '${map.id}:${entity.id}',
        ),
      );
      if (entity.kind == MapEntityKind.npc) {
        options.add(
          WorldRuleTargetPickerOption(
            kind: WorldRuleTargetKind.npcDialogue,
            mapId: map.id,
            entityId: entity.id,
            label: entityLabel,
            subtitle: '$mapLabel · dialogue PNJ',
            debugTechnicalLabel: '${map.id}:${entity.id}:dialogue',
          ),
        );
      }
    }
    for (final event in map.events) {
      options.add(
        WorldRuleTargetPickerOption(
          kind: WorldRuleTargetKind.mapEvent,
          mapId: map.id,
          eventId: event.id,
          label: _eventLabel(event),
          subtitle: '$mapLabel · event',
          debugTechnicalLabel: '${map.id}:${event.id}',
        ),
      );
    }
  }
  options.sort((a, b) {
    final byKind = a.kind.index.compareTo(b.kind.index);
    if (byKind != 0) {
      return byKind;
    }
    return a.label.toLowerCase().compareTo(b.label.toLowerCase());
  });
  return options;
}

List<WorldRuleEffectPickerOption> _buildEffectOptions() {
  return const [
    WorldRuleEffectPickerOption(
      effectKind: WorldRuleEffectKind.entityVisible,
      compatibleTargetKind: WorldRuleTargetKind.mapEntity,
      label: 'Entité visible',
      requiresDialogue: false,
    ),
    WorldRuleEffectPickerOption(
      effectKind: WorldRuleEffectKind.entityHidden,
      compatibleTargetKind: WorldRuleTargetKind.mapEntity,
      label: 'Entité cachée',
      requiresDialogue: false,
    ),
    WorldRuleEffectPickerOption(
      effectKind: WorldRuleEffectKind.npcDialogueOverride,
      compatibleTargetKind: WorldRuleTargetKind.npcDialogue,
      label: 'Dialogue PNJ remplacé',
      requiresDialogue: true,
    ),
    WorldRuleEffectPickerOption(
      effectKind: WorldRuleEffectKind.eventEnabled,
      compatibleTargetKind: WorldRuleTargetKind.mapEvent,
      label: 'Event activé',
      requiresDialogue: false,
    ),
    WorldRuleEffectPickerOption(
      effectKind: WorldRuleEffectKind.eventDisabled,
      compatibleTargetKind: WorldRuleTargetKind.mapEvent,
      label: 'Event désactivé',
      requiresDialogue: false,
    ),
    WorldRuleEffectPickerOption(
      effectKind: WorldRuleEffectKind.eventHidden,
      compatibleTargetKind: WorldRuleTargetKind.mapEvent,
      label: 'Event masqué',
      requiresDialogue: false,
    ),
  ];
}

List<WorldRuleDialoguePickerOption> _buildDialogueOptions(
  ProjectManifest project,
) {
  final options = [
    for (final dialogue in project.dialogues)
      WorldRuleDialoguePickerOption(
        dialogueId: dialogue.id,
        label: dialogue.name,
        subtitle: dialogue.relativePath,
      ),
  ];
  options
      .sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  return options;
}

Iterable<StorylineStep> _storySteps(ProjectManifest project) sync* {
  for (final storyline in project.storylines) {
    for (final chapter in storyline.chapters) {
      yield* chapter.steps;
    }
  }
}

String _sourceLabel(
  WorldRuleSource source,
  Map<String, NarrativeFactDefinition> factById,
) {
  final sourceName = switch (source.kind) {
    WorldRuleSourceKind.fact =>
      factById[source.sourceId]?.label ?? source.label ?? source.sourceId,
    WorldRuleSourceKind.storyStepCompletion => source.label ?? source.sourceId,
    WorldRuleSourceKind.consumedEvent => source.label ?? source.sourceId,
  };
  return switch (source.predicate) {
    WorldRuleSourcePredicate.isTrue => '$sourceName est vrai',
    WorldRuleSourcePredicate.isFalse => '$sourceName est faux',
    WorldRuleSourcePredicate.completed => '$sourceName terminée',
    WorldRuleSourcePredicate.notCompleted => '$sourceName non terminée',
    WorldRuleSourcePredicate.consumed => '$sourceName consommé',
    WorldRuleSourcePredicate.notConsumed => '$sourceName non consommé',
  };
}

String _targetLabel(
  WorldRuleTarget target,
  Map<String, MapData> mapById,
) {
  final map = mapById[target.mapId];
  return switch (target.kind) {
    WorldRuleTargetKind.mapEntity => target.label ??
        _entityLabelOrNull(_findEntity(map, target.entityId)) ??
        target.entityId ??
        'Entité inconnue',
    WorldRuleTargetKind.npcDialogue => target.label ??
        _entityLabelOrNull(_findEntity(map, target.entityId)) ??
        target.entityId ??
        'PNJ inconnu',
    WorldRuleTargetKind.mapEvent => target.label ??
        _eventLabelOrNull(_findEvent(map, target.eventId)) ??
        target.eventId ??
        'Event inconnu',
  };
}

String _effectLabel(
  WorldRuleEffect effect,
  Map<String, ProjectDialogueEntry> dialogueById,
) {
  return switch (effect.kind) {
    WorldRuleEffectKind.entityVisible => 'Entité visible',
    WorldRuleEffectKind.entityHidden => 'Entité cachée',
    WorldRuleEffectKind.npcDialogueOverride =>
      'Dialogue remplacé par ${dialogueById[effect.dialogueId]?.name ?? effect.dialogueId ?? 'dialogue inconnu'}',
    WorldRuleEffectKind.eventEnabled => 'Event activé',
    WorldRuleEffectKind.eventDisabled => 'Event désactivé',
    WorldRuleEffectKind.eventHidden => 'Event masqué',
  };
}

MapEntity? _findEntity(MapData? map, String? entityId) {
  if (map == null || entityId == null) {
    return null;
  }
  for (final entity in map.entities) {
    if (entity.id == entityId) {
      return entity;
    }
  }
  return null;
}

MapEventDefinition? _findEvent(MapData? map, String? eventId) {
  if (map == null || eventId == null) {
    return null;
  }
  for (final event in map.events) {
    if (event.id == eventId) {
      return event;
    }
  }
  return null;
}

String _entityLabel(MapEntity entity) {
  final displayName = entity.npc?.displayName.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName;
  }
  final name = entity.name.trim();
  return name.isEmpty ? entity.id : name;
}

String _eventLabel(MapEventDefinition event) {
  final title = event.title.trim();
  return title.isEmpty ? event.id : title;
}

String? _entityLabelOrNull(MapEntity? entity) {
  return entity == null ? null : _entityLabel(entity);
}

String? _eventLabelOrNull(MapEventDefinition? event) {
  return event == null ? null : _eventLabel(event);
}

int _compareFactUsages(FactManagerUsage a, FactManagerUsage b) {
  final byKind = a.kind.index.compareTo(b.kind.index);
  if (byKind != 0) {
    return byKind;
  }
  final byOwner = a.ownerLabel.toLowerCase().compareTo(
        b.ownerLabel.toLowerCase(),
      );
  if (byOwner != 0) {
    return byOwner;
  }
  return a.ownerId.compareTo(b.ownerId);
}

int _compareWorldRules(WorldRuleDefinition a, WorldRuleDefinition b) {
  final byPriority = a.priority.compareTo(b.priority);
  if (byPriority != 0) {
    return byPriority;
  }
  return a.id.compareTo(b.id);
}
