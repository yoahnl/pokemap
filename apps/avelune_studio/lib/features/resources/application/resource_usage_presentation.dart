import '../domain/resource_usage_port.dart';

Map<String, List<ResourceUsageEntry>> groupResourceUsageEntries(
  ResourceUsageReport? report,
) {
  final groups = <String, List<ResourceUsageEntry>>{};
  for (final entry in report?.entries ?? <ResourceUsageEntry>[]) {
    groups.putIfAbsent(entry.ownerKind, () => []).add(entry);
  }
  return groups;
}

String resourceUsageRelationLabel(ResourceUsageRelation relation) =>
    switch (relation) {
      ResourceUsageRelation.direct => 'Direct',
      ResourceUsageRelation.indirect => 'Indirect',
      ResourceUsageRelation.technical => 'Conservation technique',
      ResourceUsageRelation.ambiguous => 'Identité ambiguë',
    };

String resourceUsageOwnerLabel(String owner) => switch (owner) {
  'map' => 'Cartes et instances',
  'element' => 'Définitions de décors',
  'preset' => 'Terrains automatiques',
  'character' => 'Personnages et portraits',
  'scene' => 'Scènes',
  'presentationCinematic' => 'Présentations',
  'media' => 'Médias de présentation',
  'border' || 'borderSnapshot' => 'Bordures et snapshots',
  'smartTileDraft' => 'Brouillons de terrains',
  'dialogueSource' => 'Dialogues',
  'pokemonMedia' => 'Médias Pokémon',
  _ => owner,
};

String resourceUsageRelationSummary(ResourceUsageReport report) => [
  for (final relation in ResourceUsageRelation.values)
    '${resourceUsageRelationLabel(relation)} : ${report.entries.where((entry) => entry.relation == relation).length}',
].join(' · ');

String? resourceUsageEmptyMessage(
  ResourceUsageReport report, {
  required List<String> dirtyOwners,
  required bool stale,
}) => report.entries.isNotEmpty
    ? null
    : report.complete && dirtyOwners.isEmpty && !stale
    ? 'Aucun usage trouvé dans le périmètre complet de cette révision.'
    : 'Aucun résultat disponible. Cela ne signifie pas « inutilisé ».';
