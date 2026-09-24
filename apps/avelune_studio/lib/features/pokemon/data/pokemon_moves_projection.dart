import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart' show localizedNamesForMove;

import '../domain/pokemon_workspace_models.dart';

PokemonMovesCatalogView projectPokemonMoves(
  PokemonCatalogFile catalog,
  String relativePath,
  String locale,
) {
  final entries = <PokemonMoveSummary>[];
  final diagnostics = <String>[];
  final identities = <String>{};
  for (var index = 0; index < catalog.entries.length; index++) {
    final raw = catalog.entries[index];
    try {
      final entry = _projectMove(raw, locale);
      if (!identities.add(entry.id)) {
        diagnostics.add('Attaque ${entry.id} répétée à la ligne ${index + 1}.');
      } else {
        entries.add(entry);
      }
    } on Object {
      diagnostics.add('Entrée ${index + 1} illisible.');
    }
  }
  entries.sort((a, b) {
    final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
    return byName == 0 ? a.id.compareTo(b.id) : byName;
  });
  return PokemonMovesCatalogView(
    entries: List.unmodifiable(entries),
    relativePath: relativePath,
    diagnostics: List.unmodifiable(diagnostics),
  );
}

PokemonMoveSummary _projectMove(Map<String, dynamic> raw, String locale) {
  final id = (raw['id'] as String?)?.trim() ?? '';
  if (id.isEmpty) throw const FormatException('Missing move ID');
  final userCreated = (raw['source'] as String?)?.trim() == 'project_custom';
  if (_isCanonical(raw)) {
    final move = PokemonMove.fromJson(raw);
    return PokemonMoveSummary(
      id: move.id,
      name: _localized(move.names, move.name, locale, move.id, userCreated),
      type: move.type,
      category: move.category.name,
      power: move.usesStandardDamageFlow ? move.basePower : null,
      accuracy: move.accuracy.map(
        percent: (value) => '${value.value} %',
        alwaysHits: (_) => 'Toujours',
      ),
      pp: move.pp,
      priority: move.priority,
      target: move.target.name,
      description: move.description.trim().isEmpty
          ? move.shortDescription
          : move.description,
      userCreated: userCreated,
    );
  }
  final names = (raw['names'] as Map?)?.cast<String, dynamic>() ?? {};
  final name = _localized(
    names,
    (raw['name'] as String?)?.trim() ?? id,
    locale,
    id,
    userCreated,
  );
  return PokemonMoveSummary(
    id: id,
    name: name,
    type: (raw['typeId'] ?? raw['type']) as String?,
    category: (raw['damageClass'] ?? raw['category']) as String?,
    power: (raw['power'] as num?)?.toInt(),
    accuracy: raw['accuracy']?.toString() ?? raw['accuracyText'] as String?,
    pp: (raw['pp'] as num?)?.toInt(),
    priority: (raw['priority'] as num?)?.toInt(),
    target: raw['target'] as String?,
    description:
        (raw['effectText'] ?? raw['description'] ?? raw['shortDesc'])
            as String?,
    userCreated: userCreated,
  );
}

bool _isCanonical(Map<String, dynamic> raw) =>
    raw.containsKey('effects') ||
    raw.containsKey('accuracyMode') ||
    raw.containsKey('basePower') ||
    raw.containsKey('damageModel');

String _localized(
  Map names,
  String fallback,
  String locale,
  String id,
  bool userCreated,
) {
  final available = <String, String>{
    if (!userCreated) ...localizedNamesForMove(id.replaceAll('-', '_')),
    for (final entry in names.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
  return resolveLocalizedName(
    names: available,
    locale: locale,
    fallback: fallback,
  );
}
