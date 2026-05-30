import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';

enum WorldRuleDiagnosticSeverity {
  error,
  warning,
  info,
}

enum WorldRuleDiagnosticCode {
  worldRuleSourceMissing,
  worldRuleSourceUnknown,
  worldRuleSourceUnsupported,
  worldRuleTargetMissing,
  worldRuleTargetUnknown,
  worldRuleEffectMissing,
  worldRuleEffectUnsupported,
  worldRuleEffectTargetMismatch,
  worldRuleConflict,
  worldRuleUsesRawTechnicalId,
  worldRuleLegacyPredicateLeak,
}

final class WorldRuleDiagnostic {
  const WorldRuleDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    required this.ruleId,
    this.sourceId,
    this.targetId,
    this.mapId,
    this.suggestedFixLabel,
  });

  final WorldRuleDiagnosticCode code;
  final WorldRuleDiagnosticSeverity severity;
  final String message;
  final String ruleId;
  final String? sourceId;
  final String? targetId;
  final String? mapId;
  final String? suggestedFixLabel;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldRuleDiagnostic &&
          other.code == code &&
          other.severity == severity &&
          other.message == message &&
          other.ruleId == ruleId &&
          other.sourceId == sourceId &&
          other.targetId == targetId &&
          other.mapId == mapId &&
          other.suggestedFixLabel == suggestedFixLabel;

  @override
  int get hashCode => Object.hash(
        code,
        severity,
        message,
        ruleId,
        sourceId,
        targetId,
        mapId,
        suggestedFixLabel,
      );
}

final class WorldRuleDiagnosticsReport {
  WorldRuleDiagnosticsReport({
    required List<WorldRuleDiagnostic> diagnostics,
  }) : _diagnostics = List<WorldRuleDiagnostic>.unmodifiable(diagnostics);

  final List<WorldRuleDiagnostic> _diagnostics;

  List<WorldRuleDiagnostic> get diagnostics => _diagnostics;

  int get count => _diagnostics.length;

  int get errorCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == WorldRuleDiagnosticSeverity.error)
      .length;

  int get warningCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == WorldRuleDiagnosticSeverity.warning)
      .length;

  int get infoCount => _diagnostics
      .where((diagnostic) =>
          diagnostic.severity == WorldRuleDiagnosticSeverity.info)
      .length;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;

  bool get hasErrors => errorCount > 0;

  List<WorldRuleDiagnostic> byCode(WorldRuleDiagnosticCode code) {
    return List<WorldRuleDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.code == code),
    );
  }

  List<WorldRuleDiagnostic> byRuleId(String ruleId) {
    return List<WorldRuleDiagnostic>.unmodifiable(
      _diagnostics.where((diagnostic) => diagnostic.ruleId == ruleId),
    );
  }
}

WorldRuleDiagnosticsReport diagnoseWorldRules(
  ProjectManifest project, {
  List<MapData> maps = const <MapData>[],
}) {
  final diagnostics = <WorldRuleDiagnostic>[];
  final mapsById = {for (final map in maps) map.id: map};
  final projectMapIds = project.maps.map((map) => map.id).toSet();
  final factIds = project.facts.map((fact) => fact.id).toSet();
  final dialogueIds = project.dialogues.map((dialogue) => dialogue.id).toSet();
  final storyStepIds = _storyStepIds(project);
  final consumedEventIds = _eventIds(maps);

  for (final rule in project.worldRules) {
    _diagnoseSource(
      rule,
      diagnostics,
      factIds: factIds,
      storyStepIds: storyStepIds,
      consumedEventIds: consumedEventIds,
    );
    _diagnoseTarget(
      rule,
      diagnostics,
      projectMapIds: projectMapIds,
      mapsById: mapsById,
    );
    _diagnoseEffect(
      rule,
      diagnostics,
      dialogueIds: dialogueIds,
    );
    _diagnoseLabels(rule, diagnostics);
  }
  _diagnoseConflicts(project.worldRules, diagnostics);
  return WorldRuleDiagnosticsReport(diagnostics: diagnostics);
}

void _diagnoseSource(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics, {
  required Set<String> factIds,
  required Set<String> storyStepIds,
  required Set<String> consumedEventIds,
}) {
  if (rule.source.sourceId.trim().isEmpty) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleSourceMissing,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'La World Rule doit choisir une source métier.',
        ruleId: rule.id,
        suggestedFixLabel: 'Choisir un Fact, une étape ou un event consommé.',
      ),
    );
    return;
  }
  if (!isWorldRuleSourcePredicateCompatible(
    rule.source.kind,
    rule.source.predicate,
  )) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleSourceUnsupported,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'Le prédicat de source n’est pas supporté par ce type.',
        ruleId: rule.id,
        sourceId: rule.source.sourceId,
        suggestedFixLabel: 'Choisir un prédicat compatible avec la source.',
      ),
    );
  }

  switch (rule.source.kind) {
    case WorldRuleSourceKind.fact:
      if (!factIds.contains(rule.source.sourceId)) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleSourceUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule référence un Fact absent du projet.',
            ruleId: rule.id,
            sourceId: rule.source.sourceId,
            suggestedFixLabel: 'Choisir un Fact existant.',
          ),
        );
      }
    case WorldRuleSourceKind.storyStepCompletion:
      if (storyStepIds.isNotEmpty &&
          !storyStepIds.contains(rule.source.sourceId)) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleSourceUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule référence une étape narrative inconnue.',
            ruleId: rule.id,
            sourceId: rule.source.sourceId,
            suggestedFixLabel: 'Choisir une étape existante.',
          ),
        );
      }
    case WorldRuleSourceKind.consumedEvent:
      if (consumedEventIds.isNotEmpty &&
          !consumedEventIds.contains(rule.source.sourceId)) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleSourceUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule référence un event consommé inconnu.',
            ruleId: rule.id,
            sourceId: rule.source.sourceId,
            suggestedFixLabel: 'Choisir un event existant.',
          ),
        );
      }
  }
}

void _diagnoseTarget(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics, {
  required Set<String> projectMapIds,
  required Map<String, MapData> mapsById,
}) {
  if (rule.target.mapId.trim().isEmpty) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleTargetMissing,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'La World Rule doit choisir une map cible.',
        ruleId: rule.id,
        suggestedFixLabel: 'Choisir une map cible.',
      ),
    );
    return;
  }
  if (!projectMapIds.contains(rule.target.mapId) &&
      !mapsById.containsKey(rule.target.mapId)) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleTargetUnknown,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'La World Rule cible une map inconnue.',
        ruleId: rule.id,
        mapId: rule.target.mapId,
        suggestedFixLabel: 'Choisir une map du projet.',
      ),
    );
    return;
  }
  final map = mapsById[rule.target.mapId];
  if (map == null) {
    return;
  }
  switch (rule.target.kind) {
    case WorldRuleTargetKind.mapEntity:
      final entityId = rule.target.entityId?.trim() ?? '';
      if (entityId.isEmpty) {
        diagnostics.add(_missingTarget(rule, 'entité cible'));
        return;
      }
      if (!map.entities.any((entity) => entity.id == entityId)) {
        diagnostics.add(_unknownTarget(rule, entityId, 'entité'));
      }
    case WorldRuleTargetKind.npcDialogue:
      final entityId = rule.target.entityId?.trim() ?? '';
      if (entityId.isEmpty) {
        diagnostics.add(_missingTarget(rule, 'PNJ cible'));
        return;
      }
      final entity = _findEntity(map, entityId);
      if (entity == null) {
        diagnostics.add(_unknownTarget(rule, entityId, 'PNJ'));
      } else if (entity.kind != MapEntityKind.npc) {
        diagnostics.add(
          WorldRuleDiagnostic(
            code: WorldRuleDiagnosticCode.worldRuleTargetUnknown,
            severity: WorldRuleDiagnosticSeverity.error,
            message: 'La World Rule de dialogue cible une entité non PNJ.',
            ruleId: rule.id,
            targetId: entityId,
            mapId: rule.target.mapId,
            suggestedFixLabel: 'Choisir un PNJ.',
          ),
        );
      }
    case WorldRuleTargetKind.mapEvent:
      final eventId = rule.target.eventId?.trim() ?? '';
      if (eventId.isEmpty) {
        diagnostics.add(_missingTarget(rule, 'event cible'));
        return;
      }
      if (!map.events.any((event) => event.id == eventId)) {
        diagnostics.add(_unknownTarget(rule, eventId, 'event'));
      }
  }
}

void _diagnoseEffect(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics, {
  required Set<String> dialogueIds,
}) {
  if (!isWorldRuleEffectCompatibleWithTarget(
    rule.target.kind,
    rule.effect.kind,
  )) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleEffectTargetMismatch,
        severity: WorldRuleDiagnosticSeverity.error,
        message: 'L’effet de la World Rule ne correspond pas à sa cible.',
        ruleId: rule.id,
        targetId: _targetIdentity(rule.target),
        mapId: rule.target.mapId,
        suggestedFixLabel: 'Choisir un effet compatible avec la cible.',
      ),
    );
  }
  if (rule.effect.kind == WorldRuleEffectKind.npcDialogueOverride) {
    final dialogueId = rule.effect.dialogueId?.trim() ?? '';
    if (dialogueId.isEmpty) {
      diagnostics.add(
        WorldRuleDiagnostic(
          code: WorldRuleDiagnosticCode.worldRuleEffectMissing,
          severity: WorldRuleDiagnosticSeverity.error,
          message: 'L’effet de dialogue doit choisir un dialogue.',
          ruleId: rule.id,
          suggestedFixLabel: 'Choisir un dialogue existant.',
        ),
      );
    } else if (!dialogueIds.contains(dialogueId)) {
      diagnostics.add(
        WorldRuleDiagnostic(
          code: WorldRuleDiagnosticCode.worldRuleEffectUnsupported,
          severity: WorldRuleDiagnosticSeverity.error,
          message: 'L’effet référence un dialogue absent du projet.',
          ruleId: rule.id,
          targetId: dialogueId,
          suggestedFixLabel: 'Choisir un dialogue existant.',
        ),
      );
    }
  }
}

void _diagnoseLabels(
  WorldRuleDefinition rule,
  List<WorldRuleDiagnostic> diagnostics,
) {
  if (rule.label.trim() == rule.id ||
      (rule.label.contains('_') && !rule.label.contains(' '))) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleUsesRawTechnicalId,
        severity: WorldRuleDiagnosticSeverity.warning,
        message: 'La World Rule affiche encore un identifiant technique.',
        ruleId: rule.id,
        suggestedFixLabel: 'Donner un label lisible à la règle.',
      ),
    );
  }
  final debug = [
    rule.debugTechnicalLabel,
    rule.source.debugTechnicalLabel,
  ].whereType<String>().join(' ').toLowerCase();
  if (debug.contains('scriptcondition') ||
      debug.contains('script_condition') ||
      debug.contains('predicate')) {
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleLegacyPredicateLeak,
        severity: WorldRuleDiagnosticSeverity.warning,
        message: 'La World Rule expose encore un prédicat legacy.',
        ruleId: rule.id,
        suggestedFixLabel: 'Remplacer par une source métier lisible.',
      ),
    );
  }
}

void _diagnoseConflicts(
  List<WorldRuleDefinition> rules,
  List<WorldRuleDiagnostic> diagnostics,
) {
  final seen = <String, WorldRuleDefinition>{};
  for (final rule in rules) {
    if (!rule.enabled) {
      continue;
    }
    final key =
        '${_targetIdentity(rule.target)}|${rule.effect.kind.name}|${rule.priority}';
    final previous = seen[key];
    if (previous == null) {
      seen[key] = rule;
      continue;
    }
    diagnostics.add(
      WorldRuleDiagnostic(
        code: WorldRuleDiagnosticCode.worldRuleConflict,
        severity: WorldRuleDiagnosticSeverity.warning,
        message:
            'Plusieurs World Rules actives ciblent le même effet avec la même priorité.',
        ruleId: rule.id,
        targetId: _targetIdentity(rule.target),
        mapId: rule.target.mapId,
        suggestedFixLabel: 'Changer la priorité ou fusionner ces règles.',
      ),
    );
  }
}

WorldRuleDiagnostic _missingTarget(WorldRuleDefinition rule, String label) {
  return WorldRuleDiagnostic(
    code: WorldRuleDiagnosticCode.worldRuleTargetMissing,
    severity: WorldRuleDiagnosticSeverity.error,
    message: 'La World Rule doit choisir une $label.',
    ruleId: rule.id,
    mapId: rule.target.mapId,
    suggestedFixLabel: 'Choisir une cible existante.',
  );
}

WorldRuleDiagnostic _unknownTarget(
  WorldRuleDefinition rule,
  String targetId,
  String label,
) {
  return WorldRuleDiagnostic(
    code: WorldRuleDiagnosticCode.worldRuleTargetUnknown,
    severity: WorldRuleDiagnosticSeverity.error,
    message: 'La World Rule cible un(e) $label inconnu(e).',
    ruleId: rule.id,
    targetId: targetId,
    mapId: rule.target.mapId,
    suggestedFixLabel: 'Choisir une cible existante.',
  );
}

MapEntity? _findEntity(MapData map, String entityId) {
  for (final entity in map.entities) {
    if (entity.id == entityId) {
      return entity;
    }
  }
  return null;
}

Set<String> _storyStepIds(ProjectManifest project) {
  return {
    for (final storyline in project.storylines)
      for (final chapter in storyline.chapters)
        for (final step in chapter.steps) step.id,
  };
}

Set<String> _eventIds(List<MapData> maps) {
  return {
    for (final map in maps)
      for (final event in map.events) event.id,
  };
}

String _targetIdentity(WorldRuleTarget target) {
  return switch (target.kind) {
    WorldRuleTargetKind.mapEntity =>
      '${target.mapId}:entity:${target.entityId ?? ''}',
    WorldRuleTargetKind.npcDialogue =>
      '${target.mapId}:npcDialogue:${target.entityId ?? ''}',
    WorldRuleTargetKind.mapEvent =>
      '${target.mapId}:event:${target.eventId ?? ''}',
  };
}
