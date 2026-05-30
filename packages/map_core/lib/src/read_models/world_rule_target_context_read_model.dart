import '../diagnostics/world_rule_diagnostics.dart';
import '../models/map_data.dart';
import '../models/narrative_fact.dart';
import '../models/project_manifest.dart';
import '../models/world_rule.dart';

final class WorldRuleTargetContextReadModel {
  WorldRuleTargetContextReadModel({
    required this.targetKind,
    required this.mapId,
    this.entityId,
    this.eventId,
    required List<WorldRuleTargetContextRuleView> rules,
  }) : _rules = List<WorldRuleTargetContextRuleView>.unmodifiable(rules);

  final WorldRuleTargetKind targetKind;
  final String mapId;
  final String? entityId;
  final String? eventId;
  final List<WorldRuleTargetContextRuleView> _rules;

  List<WorldRuleTargetContextRuleView> get rules => _rules;

  int get ruleCount => _rules.length;

  bool get isEmpty => _rules.isEmpty;

  List<WorldRuleDiagnostic> get diagnostics {
    return List<WorldRuleDiagnostic>.unmodifiable(
      _rules.expand((rule) => rule.diagnostics),
    );
  }

  bool get hasDiagnostics => _rules.any((rule) => rule.hasDiagnostics);
}

final class WorldRuleTargetContextRuleView {
  WorldRuleTargetContextRuleView({
    required this.rule,
    required this.sourceLabel,
    required this.targetLabel,
    required this.effectLabel,
    required List<WorldRuleDiagnostic> diagnostics,
  }) : _diagnostics = List<WorldRuleDiagnostic>.unmodifiable(diagnostics);

  final WorldRuleDefinition rule;
  final String sourceLabel;
  final String targetLabel;
  final String effectLabel;
  final List<WorldRuleDiagnostic> _diagnostics;

  String get id => rule.id;

  String get label => rule.label;

  bool get enabled => rule.enabled;

  List<WorldRuleDiagnostic> get diagnostics => _diagnostics;

  bool get hasDiagnostics => _diagnostics.isNotEmpty;
}

WorldRuleTargetContextReadModel buildWorldRuleTargetContextReadModel(
  ProjectManifest project, {
  required WorldRuleTargetKind targetKind,
  required String mapId,
  String? entityId,
  String? eventId,
  List<MapData> maps = const <MapData>[],
}) {
  final factById = {for (final fact in project.facts) fact.id: fact};
  final dialogueById = {
    for (final dialogue in project.dialogues) dialogue.id: dialogue
  };
  final mapsById = {for (final map in maps) map.id: map};
  final diagnosticsReport = diagnoseWorldRules(project, maps: maps);
  final matchingRules = [
    for (final rule in project.worldRules)
      if (_matchesTargetContext(
        rule.target,
        targetKind: targetKind,
        mapId: mapId,
        entityId: entityId,
        eventId: eventId,
      ))
        rule,
  ]..sort(_compareRules);

  return WorldRuleTargetContextReadModel(
    targetKind: targetKind,
    mapId: mapId,
    entityId: entityId,
    eventId: eventId,
    rules: [
      for (final rule in matchingRules)
        WorldRuleTargetContextRuleView(
          rule: rule,
          sourceLabel: _sourceLabel(rule.source, factById),
          targetLabel: _targetLabel(rule.target, mapsById),
          effectLabel: _effectLabel(rule.effect, dialogueById),
          diagnostics: diagnosticsReport.byRuleId(rule.id),
        ),
    ],
  );
}

bool _matchesTargetContext(
  WorldRuleTarget target, {
  required WorldRuleTargetKind targetKind,
  required String mapId,
  required String? entityId,
  required String? eventId,
}) {
  if (target.kind != targetKind || target.mapId != mapId) {
    return false;
  }
  return switch (targetKind) {
    WorldRuleTargetKind.mapEntity ||
    WorldRuleTargetKind.npcDialogue =>
      target.entityId == entityId,
    WorldRuleTargetKind.mapEvent => target.eventId == eventId,
  };
}

int _compareRules(WorldRuleDefinition a, WorldRuleDefinition b) {
  final byPriority = a.priority.compareTo(b.priority);
  if (byPriority != 0) {
    return byPriority;
  }
  return a.id.compareTo(b.id);
}

String _sourceLabel(
  WorldRuleSource source,
  Map<String, NarrativeFactDefinition> factById,
) {
  final sourceName = switch (source.kind) {
    WorldRuleSourceKind.fact =>
      factById[source.sourceId]?.label ?? source.sourceId,
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
  Map<String, MapData> mapsById,
) {
  final map = mapsById[target.mapId];
  return switch (target.kind) {
    WorldRuleTargetKind.mapEntity => target.label ??
        map?.entities
            .where((entity) => entity.id == target.entityId)
            .map((entity) => entity.name)
            .firstOrNull ??
        target.entityId ??
        'Entité inconnue',
    WorldRuleTargetKind.npcDialogue => target.label ??
        map?.entities
            .where((entity) => entity.id == target.entityId)
            .map((entity) => entity.name)
            .firstOrNull ??
        target.entityId ??
        'PNJ inconnu',
    WorldRuleTargetKind.mapEvent => target.label ??
        map?.events
            .where((event) => event.id == target.eventId)
            .map((event) => event.title)
            .firstOrNull ??
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
