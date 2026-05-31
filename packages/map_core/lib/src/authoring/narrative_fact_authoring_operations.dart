import '../models/narrative_fact.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../models/scene_consequence.dart';
import '../models/world_rule.dart';

final class NarrativeFactCreationResult {
  const NarrativeFactCreationResult({
    required this.updatedProject,
    required this.createdFact,
  });

  final ProjectManifest updatedProject;
  final NarrativeFactDefinition createdFact;
}

final class NarrativeFactUpdateResult {
  const NarrativeFactUpdateResult({
    required this.updatedProject,
    required this.updatedFact,
  });

  final ProjectManifest updatedProject;
  final NarrativeFactDefinition updatedFact;
}

final class NarrativeFactRemovalResult {
  const NarrativeFactRemovalResult({
    required this.updatedProject,
    required this.removedFact,
  });

  final ProjectManifest updatedProject;
  final NarrativeFactDefinition removedFact;
}

NarrativeFactCreationResult addNarrativeFact(
  ProjectManifest manifest, {
  required String label,
  String description = '',
  String category = '',
  bool defaultValue = false,
  List<String> tags = const <String>[],
  String? legacyFlagName,
}) {
  final trimmedLabel = label.trim();
  if (trimmedLabel.isEmpty) {
    throw ArgumentError.value(label, 'label', 'Fact label is required.');
  }
  final fact = NarrativeFactDefinition(
    id: _uniqueFactId(trimmedLabel, manifest.facts.map((fact) => fact.id)),
    label: trimmedLabel,
    description: description,
    category: category,
    defaultValue: defaultValue,
    tags: tags,
    legacyFlagName: legacyFlagName,
  );
  return NarrativeFactCreationResult(
    updatedProject: manifest.copyWith(facts: [...manifest.facts, fact]),
    createdFact: fact,
  );
}

NarrativeFactUpdateResult updateNarrativeFact(
  ProjectManifest manifest, {
  required String factId,
  required String label,
  String description = '',
  String category = '',
  bool defaultValue = false,
  List<String> tags = const <String>[],
  String? legacyFlagName,
}) {
  final index = manifest.facts.indexWhere((fact) => fact.id == factId);
  if (index < 0) {
    throw ArgumentError.value(factId, 'factId', 'Unknown narrative fact.');
  }
  final updatedFact = NarrativeFactDefinition(
    id: factId,
    label: label,
    description: description,
    category: category,
    defaultValue: defaultValue,
    tags: tags,
    legacyFlagName: legacyFlagName,
  );
  final facts = manifest.facts.toList(growable: true);
  facts[index] = updatedFact;
  return NarrativeFactUpdateResult(
    updatedProject: manifest.copyWith(facts: facts),
    updatedFact: updatedFact,
  );
}

NarrativeFactRemovalResult removeNarrativeFact(
  ProjectManifest manifest, {
  required String factId,
}) {
  final index = manifest.facts.indexWhere((fact) => fact.id == factId);
  if (index < 0) {
    throw ArgumentError.value(factId, 'factId', 'Unknown narrative fact.');
  }
  final referencingScene = _firstSceneReferencingFact(manifest, factId);
  if (referencingScene != null) {
    throw ArgumentError.value(
      factId,
      'factId',
      'Cannot remove narrative fact referenced by scene ${referencingScene.id}.',
    );
  }
  final producingScene = _firstSceneProducingFact(manifest, factId);
  if (producingScene != null) {
    throw ArgumentError.value(
      factId,
      'factId',
      'Cannot remove narrative fact produced by scene ${producingScene.id}.',
    );
  }
  final referencingWorldRule = _firstWorldRuleReferencingFact(manifest, factId);
  if (referencingWorldRule != null) {
    throw ArgumentError.value(
      factId,
      'factId',
      'Cannot remove narrative fact referenced by world rule '
          '${referencingWorldRule.id}.',
    );
  }
  final removedFact = manifest.facts[index];
  final facts = manifest.facts.toList(growable: true)..removeAt(index);
  return NarrativeFactRemovalResult(
    updatedProject: manifest.copyWith(facts: facts),
    removedFact: removedFact,
  );
}

SceneAsset? _firstSceneProducingFact(ProjectManifest manifest, String factId) {
  for (final scene in manifest.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneActionPayload) {
        continue;
      }
      final consequence = payload.consequence;
      if (consequence is SceneSetFactConsequence &&
          consequence.factId == factId) {
        return scene;
      }
    }
  }
  return null;
}

WorldRuleDefinition? _firstWorldRuleReferencingFact(
  ProjectManifest manifest,
  String factId,
) {
  for (final rule in manifest.worldRules) {
    if (rule.source.kind == WorldRuleSourceKind.fact &&
        rule.source.sourceId == factId) {
      return rule;
    }
  }
  return null;
}

SceneAsset? _firstSceneReferencingFact(
    ProjectManifest manifest, String factId) {
  for (final scene in manifest.scenes) {
    for (final node in scene.graph.nodes) {
      final payload = node.payload;
      if (payload is! SceneConditionPayload) {
        continue;
      }
      final source = payload.conditionSource;
      if (source?.sourceKind == SceneConditionSourceKind.fact &&
          source?.sourceId == factId) {
        return scene;
      }
    }
  }
  return null;
}

String _uniqueFactId(String label, Iterable<String> existingIds) {
  final existing = existingIds.toSet();
  final slug = _slugify(label);
  final base = 'fact_${slug.isEmpty ? 'item' : slug}';
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
