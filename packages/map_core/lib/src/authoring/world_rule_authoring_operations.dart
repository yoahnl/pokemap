import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/narrative_event_definition.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';

const maxWorldRuleBatchSize = 128;

final class WorldRuleBatchException implements Exception {
  const WorldRuleBatchException({required this.index, required this.cause});

  final int index;
  final Object cause;

  @override
  String toString() => 'WorldRuleBatchException(index: $index, cause: $cause)';
}

final class WorldRuleCreationResult {
  const WorldRuleCreationResult({
    required this.updatedProject,
    required this.createdRule,
  });

  final ProjectManifest updatedProject;
  final WorldRuleDefinition createdRule;
}

final class WorldRuleUpdateResult {
  const WorldRuleUpdateResult({
    required this.updatedProject,
    required this.updatedRule,
  });

  final ProjectManifest updatedProject;
  final WorldRuleDefinition updatedRule;
}

final class WorldRuleRemovalResult {
  const WorldRuleRemovalResult({
    required this.updatedProject,
    required this.removedRule,
  });

  final ProjectManifest updatedProject;
  final WorldRuleDefinition removedRule;
}

WorldRuleCreationResult addWorldRule(
  ProjectManifest manifest, {
  required String label,
  String description = '',
  bool enabled = true,
  required WorldRuleSource source,
  required WorldRuleTarget target,
  required WorldRuleEffect effect,
  int priority = 0,
  List<String> tags = const <String>[],
  String? debugTechnicalLabel,
  List<MapData> maps = const <MapData>[],
}) {
  final trimmedLabel = label.trim();
  if (trimmedLabel.isEmpty) {
    throw ArgumentError.value(label, 'label', 'World rule label is required.');
  }
  final rule = WorldRuleDefinition(
    id: _uniqueWorldRuleId(
      trimmedLabel,
      manifest.worldRules.map((rule) => rule.id),
    ),
    label: trimmedLabel,
    description: description,
    enabled: enabled,
    source: source,
    target: target,
    effect: effect,
    priority: priority,
    tags: tags,
    debugTechnicalLabel: debugTechnicalLabel,
  );
  _validateWorldRuleForAuthoring(manifest, rule, maps: maps);
  return WorldRuleCreationResult(
    updatedProject: manifest.copyWith(
      worldRules: [...manifest.worldRules, rule],
    ),
    createdRule: rule,
  );
}

WorldRuleUpdateResult updateWorldRule(
  ProjectManifest manifest, {
  required String ruleId,
  required String label,
  String description = '',
  bool enabled = true,
  required WorldRuleSource source,
  required WorldRuleTarget target,
  required WorldRuleEffect effect,
  int priority = 0,
  List<String> tags = const <String>[],
  String? debugTechnicalLabel,
  List<MapData> maps = const <MapData>[],
}) {
  final index = manifest.worldRules.indexWhere((rule) => rule.id == ruleId);
  if (index < 0) {
    throw ArgumentError.value(ruleId, 'ruleId', 'Unknown world rule.');
  }
  final updatedRule = WorldRuleDefinition(
    id: ruleId,
    label: label,
    description: description,
    enabled: enabled,
    source: source,
    target: target,
    effect: effect,
    priority: priority,
    tags: tags,
    debugTechnicalLabel: debugTechnicalLabel,
  );
  _validateWorldRuleForAuthoring(manifest, updatedRule, maps: maps);
  final worldRules = manifest.worldRules.toList(growable: true);
  worldRules[index] = updatedRule;
  return WorldRuleUpdateResult(
    updatedProject: manifest.copyWith(worldRules: worldRules),
    updatedRule: updatedRule,
  );
}

WorldRuleRemovalResult removeWorldRule(
  ProjectManifest manifest, {
  required String ruleId,
}) {
  final index = manifest.worldRules.indexWhere((rule) => rule.id == ruleId);
  if (index < 0) {
    throw ArgumentError.value(ruleId, 'ruleId', 'Unknown world rule.');
  }
  final removedRule = manifest.worldRules[index];
  final worldRules = manifest.worldRules.toList(growable: true)
    ..removeAt(index);
  return WorldRuleRemovalResult(
    updatedProject: manifest.copyWith(worldRules: worldRules),
    removedRule: removedRule,
  );
}

ProjectManifest upsertWorldRules(
  ProjectManifest manifest, {
  required List<WorldRuleDefinition> rules,
  List<MapData> maps = const <MapData>[],
}) {
  if (rules.isEmpty || rules.length > maxWorldRuleBatchSize) {
    throw ArgumentError.value(
      rules.length,
      'rules',
      'A world rule batch requires 1 to $maxWorldRuleBatchSize rules.',
    );
  }
  final batchIds = <String>{};
  for (var index = 0; index < rules.length; index++) {
    if (!batchIds.add(rules[index].id)) {
      throw WorldRuleBatchException(
        index: index,
        cause: ArgumentError.value(
          rules[index].id,
          'rule.id',
          'World rule batch ids must be unique.',
        ),
      );
    }
  }
  final worldRules = manifest.worldRules.toList(growable: true);
  final positions = <String, int>{};
  for (var index = 0; index < worldRules.length; index++) {
    positions.putIfAbsent(worldRules[index].id, () => index);
  }
  final existingIds = positions.keys.toSet();
  for (var index = 0; index < rules.length; index++) {
    final rule = rules[index];
    final position = positions[rule.id];
    if (position != null) {
      worldRules[position] = rule;
      continue;
    }
    final canonicalId = _uniqueWorldRuleId(rule.label, existingIds);
    if (rule.id != canonicalId) {
      throw WorldRuleBatchException(
        index: index,
        cause: ArgumentError.value(
          rule.id,
          'rule.id',
          'must equal the canonical generated id $canonicalId',
        ),
      );
    }
    existingIds.add(rule.id);
    worldRules.add(rule);
  }
  final references = _WorldRuleAuthoringReferences(manifest, maps);
  for (var index = 0; index < rules.length; index++) {
    try {
      _validateWorldRuleForAuthoring(
        manifest,
        rules[index],
        maps: maps,
        references: references,
      );
    } on Object catch (error) {
      throw WorldRuleBatchException(index: index, cause: error);
    }
  }
  return manifest.copyWith(worldRules: worldRules);
}

void _validateWorldRuleForAuthoring(
  ProjectManifest manifest,
  WorldRuleDefinition rule, {
  required List<MapData> maps,
  _WorldRuleAuthoringReferences? references,
}) {
  final sourceId = rule.source.sourceId.trim();
  if (sourceId.isEmpty) {
    throw ArgumentError.value(
      sourceId,
      'source.sourceId',
      'World rule source id is required.',
    );
  }
  if (!isWorldRuleSourcePredicateCompatible(
    rule.source.kind,
    rule.source.predicate,
  )) {
    throw ArgumentError.value(
      rule.source.predicate,
      'source.predicate',
      'World rule predicate is not compatible with its source.',
    );
  }
  if (!isWorldRuleEffectCompatibleWithTarget(
    rule.target.kind,
    rule.effect.kind,
  )) {
    throw ArgumentError.value(
      rule.effect.kind,
      'effect.kind',
      'World rule effect is not compatible with its target.',
    );
  }
  if (rule.target.kind != WorldRuleTargetKind.narrativeEvent &&
      rule.target.mapId.trim().isEmpty) {
    throw ArgumentError.value(
      rule.target.mapId,
      'target.mapId',
      'World rule target map id is required.',
    );
  }
  switch (rule.target.kind) {
    case WorldRuleTargetKind.atmosphere:
      break;
    case WorldRuleTargetKind.mapEntity:
    case WorldRuleTargetKind.npcDialogue:
      if ((rule.target.entityId ?? '').trim().isEmpty) {
        throw ArgumentError.value(
          rule.target.entityId,
          'target.entityId',
          'World rule target entity id is required.',
        );
      }
    case WorldRuleTargetKind.mapEvent:
    case WorldRuleTargetKind.narrativeEvent:
      if ((rule.target.eventId ?? '').trim().isEmpty) {
        throw ArgumentError.value(
          rule.target.eventId,
          'target.eventId',
          'World rule target event id is required.',
        );
      }
  }
  if ((rule.effect.kind == WorldRuleEffectKind.atmosphere) != (rule.effect.visualSettings != null) || (rule.effect.visualSettings?.isEmpty ?? false)) {
    throw ArgumentError('Atmosphere effects require nonempty visual settings.');
  }
  if (rule.effect.kind == WorldRuleEffectKind.npcDialogueOverride &&
      (rule.effect.dialogueId ?? '').trim().isEmpty) {
    throw ArgumentError.value(
      rule.effect.dialogueId,
      'effect.dialogueId',
      'World rule dialogue override id is required.',
    );
  }
  final context = references ?? _WorldRuleAuthoringReferences(manifest, maps);
  _validateSourceReferences(rule, context);
  _validateTargetReferences(rule, context);
  _validateEffectReferences(rule, context);
}

void _validateSourceReferences(
  WorldRuleDefinition rule,
  _WorldRuleAuthoringReferences references,
) {
  switch (rule.source.kind) {
    case WorldRuleSourceKind.fact:
      if (!references.factIds.contains(rule.source.sourceId)) {
        throw ArgumentError.value(
          rule.source.sourceId,
          'source.sourceId',
          'Unknown narrative fact for world rule.',
        );
      }
    case WorldRuleSourceKind.storyStepCompletion:
      final stepIds = references.storyStepIds;
      if (stepIds.isNotEmpty && !stepIds.contains(rule.source.sourceId)) {
        throw ArgumentError.value(
          rule.source.sourceId,
          'source.sourceId',
          'Unknown story step for world rule.',
        );
      }
    case WorldRuleSourceKind.consumedEvent:
      final eventIds = references.eventIds;
      if (eventIds.isNotEmpty && !eventIds.contains(rule.source.sourceId)) {
        throw ArgumentError.value(
          rule.source.sourceId,
          'source.sourceId',
          'Unknown consumed event for world rule.',
        );
      }
  }
}

void _validateTargetReferences(
  WorldRuleDefinition rule,
  _WorldRuleAuthoringReferences references,
) {
  if (rule.target.kind == WorldRuleTargetKind.narrativeEvent) {
    if (!references.narrativeEventIds.contains(rule.target.eventId)) {
      throw ArgumentError.value(
        rule.target.eventId,
        'target.eventId',
        'Unknown Narrative Event V2 for world rule target.',
      );
    }
    return;
  }
  if (!references.manifestMapIds.contains(rule.target.mapId) &&
      !references.mapsById.containsKey(rule.target.mapId)) {
    throw ArgumentError.value(
      rule.target.mapId,
      'target.mapId',
      'Unknown map for world rule target.',
    );
  }
  final map = references.mapsById[rule.target.mapId];
  if (map == null) {
    return;
  }
  switch (rule.target.kind) {
    case WorldRuleTargetKind.atmosphere:
      break;
    case WorldRuleTargetKind.mapEntity:
      final entityIds = references.entityIdsByMap.putIfAbsent(
        map.id,
        () => map.entities.map((entity) => entity.id).toSet(),
      );
      if (!entityIds.contains(rule.target.entityId)) {
        throw ArgumentError.value(
          rule.target.entityId,
          'target.entityId',
          'Unknown map entity for world rule target.',
        );
      }
    case WorldRuleTargetKind.npcDialogue:
      final entity = _findEntity(map, rule.target.entityId ?? '');
      if (entity == null) {
        throw ArgumentError.value(
          rule.target.entityId,
          'target.entityId',
          'Unknown NPC entity for world rule target.',
        );
      }
      if (entity.kind != MapEntityKind.npc) {
        throw ArgumentError.value(
          rule.target.entityId,
          'target.entityId',
          'World rule dialogue override target must be an NPC.',
        );
      }
    case WorldRuleTargetKind.mapEvent:
      final eventIds = references.eventIdsByMap.putIfAbsent(
        map.id,
        () => map.events.map((event) => event.id).toSet(),
      );
      if (!eventIds.contains(rule.target.eventId)) {
        throw ArgumentError.value(
          rule.target.eventId,
          'target.eventId',
          'Unknown map event for world rule target.',
        );
      }
    case WorldRuleTargetKind.narrativeEvent:
      throw StateError('Narrative Event targets are validated project-wide.');
  }
}

void _validateEffectReferences(
  WorldRuleDefinition rule,
  _WorldRuleAuthoringReferences references,
) {
  if (rule.effect.kind != WorldRuleEffectKind.npcDialogueOverride) {
    return;
  }
  if (!references.dialogueIds.contains(rule.effect.dialogueId)) {
    throw ArgumentError.value(
      rule.effect.dialogueId,
      'effect.dialogueId',
      'Unknown dialogue for world rule effect.',
    );
  }
}

final class _WorldRuleAuthoringReferences {
  _WorldRuleAuthoringReferences(this.manifest, this.maps);

  final ProjectManifest manifest;
  final List<MapData> maps;

  late final factIds = manifest.facts.map((fact) => fact.id).toSet();
  late final storyStepIds = _storyStepIds(manifest);
  late final eventIds = _eventIds(manifest, maps);
  late final narrativeEventIds = {
    for (final record
        in manifest.eventRegistry?.records ?? const <NarrativeEventRecord>[])
      record.id,
  };
  late final manifestMapIds = manifest.maps.map((map) => map.id).toSet();
  late final mapsById = {for (final map in maps) map.id: map};
  final entityIdsByMap = <String, Set<String>>{};
  final eventIdsByMap = <String, Set<String>>{};
  late final dialogueIds = manifest.dialogues
      .map((dialogue) => dialogue.id)
      .toSet();
}

MapEntity? _findEntity(MapData map, String entityId) {
  for (final entity in map.entities) {
    if (entity.id == entityId) {
      return entity;
    }
  }
  return null;
}

Set<String> _storyStepIds(ProjectManifest manifest) {
  return {
    for (final storyline in manifest.storylines)
      for (final chapter in storyline.chapters)
        for (final step in chapter.steps) step.id,
  };
}

Set<String> _eventIds(ProjectManifest manifest, List<MapData> maps) {
  return {
    for (final map in maps)
      for (final event in map.events) event.id,
    for (final record
        in manifest.eventRegistry?.records ?? const <NarrativeEventRecord>[])
      record.id,
  };
}

String _uniqueWorldRuleId(String label, Iterable<String> existingIds) {
  final existing = existingIds is Set<String>
      ? existingIds
      : existingIds.toSet();
  final slug = _slugify(label);
  final base = 'world_rule_${slug.isEmpty ? 'item' : slug}';
  if (!existing.contains(base)) {
    return base;
  }
  var suffix = 2;
  while (existing.contains('${base}_$suffix')) {
    suffix++;
  }
  return '${base}_$suffix';
}

String _slugify(String value) {
  final lower = value.trim().toLowerCase();
  final buffer = StringBuffer();
  var wroteSeparator = false;

  for (final codeUnit in lower.codeUnits) {
    final isDigit = codeUnit >= 48 && codeUnit <= 57;
    final isAsciiLetter = codeUnit >= 97 && codeUnit <= 122;
    if (isDigit || isAsciiLetter) {
      buffer.writeCharCode(codeUnit);
      wroteSeparator = false;
    } else if (!wroteSeparator && buffer.isNotEmpty) {
      buffer.write('_');
      wroteSeparator = true;
    }
  }

  final slug = buffer.toString();
  return slug.endsWith('_') ? slug.substring(0, slug.length - 1) : slug;
}
