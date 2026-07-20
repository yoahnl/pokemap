import '../models/map_data.dart';
import '../models/narrative_fact.dart';
import '../models/project_manifest.dart';
import '../read_models/narrative_dependency_index.dart';

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
  final currentFact = _uniqueFact(manifest, factId);
  final index = manifest.facts.indexOf(currentFact);
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

/// Duplicates author-facing metadata without duplicating a legacy alias.
///
/// A legacy flag is an identity bridge, not ordinary metadata. Copying it would
/// make dependency resolution ambiguous, so the new Fact deliberately starts
/// without one and can be linked explicitly by a later migration workflow.
NarrativeFactCreationResult duplicateNarrativeFact(
  ProjectManifest manifest, {
  required String factId,
}) {
  final source = _uniqueFact(manifest, factId);
  final label = '${source.label} (copie)';
  final duplicated = NarrativeFactDefinition(
    id: _uniqueFactId(label, manifest.facts.map((fact) => fact.id)),
    label: label,
    description: source.description,
    category: source.category,
    defaultValue: source.defaultValue,
    tags: source.tags,
  );
  return NarrativeFactCreationResult(
    updatedProject: manifest.copyWith(facts: [...manifest.facts, duplicated]),
    createdFact: duplicated,
  );
}

NarrativeFactRemovalResult removeNarrativeFact(
  ProjectManifest manifest, {
  required String factId,
  List<MapData> maps = const <MapData>[],
  NarrativeDependencyIndex? dependencyIndex,
}) {
  final removedFact = _uniqueFact(manifest, factId);
  final index = manifest.facts.indexOf(removedFact);
  final canonicalIndex =
      buildNarrativeDependencyIndex(project: manifest, maps: maps);
  final target = NarrativeDependencyKey(
    NarrativeDependencyTargetKind.fact,
    factId,
  );
  final usages = <NarrativeDependencyUsage>[
    ...canonicalIndex.usagesFor(target),
    if (dependencyIndex != null && !identical(dependencyIndex, canonicalIndex))
      ...dependencyIndex.usagesFor(target),
  ];
  if (usages.isNotEmpty) {
    final first = usages.first;
    throw ArgumentError.value(
      factId,
      'factId',
      'Cannot remove narrative fact referenced at ${first.path}.',
    );
  }
  final facts = manifest.facts.toList(growable: true)..removeAt(index);
  return NarrativeFactRemovalResult(
    updatedProject: manifest.copyWith(facts: facts),
    removedFact: removedFact,
  );
}

NarrativeFactDefinition _uniqueFact(
  ProjectManifest manifest,
  String factId,
) {
  final matches = manifest.facts.where((fact) => fact.id == factId).toList();
  if (matches.isEmpty) {
    throw ArgumentError.value(factId, 'factId', 'Unknown narrative fact.');
  }
  if (matches.length != 1) {
    throw ArgumentError.value(
      factId,
      'factId',
      'Ambiguous narrative fact identity.',
    );
  }
  return matches.single;
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
