import '../use_cases/sync_pokemon_moves_catalog_use_case.dart';

/// Recherche locale ciblée sur le catalogue `moves` déjà synchronisé.
///
/// Ce helper reste volontairement petit et spécifique :
/// - il ne recharge rien depuis le disque ;
/// - il ne crée pas une nouvelle stack "catalog search" générique ;
/// - il consomme simplement la projection 11B déjà utilisée par l'éditeur.
///
/// Le lot 5 en a besoin pour deux usages strictement locaux :
/// - retrouver rapidement un move connu par `id` exact ;
/// - filtrer des suggestions lisibles à partir du catalogue moves existant.
class PokemonMovesCatalogLookupService {
  const PokemonMovesCatalogLookupService();

  /// Retourne l'entrée exacte d'un move local à partir de son `moveId`.
  ///
  /// La résolution reste volontairement stricte :
  /// - elle compare uniquement l'id local canonique ;
  /// - elle n'essaie pas de normaliser, corriger ou réécrire un id legacy ;
  /// - elle permet donc à l'UI de signaler honnêtement les ids inconnus.
  PokemonMoveCatalogEntryView? findById(
    List<PokemonMoveCatalogEntryView> entries,
    String moveId,
  ) {
    final normalizedId = moveId.trim().toLowerCase();
    if (normalizedId.isEmpty) {
      return null;
    }

    for (final entry in entries) {
      if (entry.id.toLowerCase() == normalizedId) {
        return entry;
      }
    }
    return null;
  }

  /// Filtre des suggestions locales stables pour l'éditeur.
  ///
  /// On garde une logique simple et déterministe :
  /// - priorité aux correspondances exactes sur `id` puis `name` ;
  /// - puis correspondances préfixe ;
  /// - puis correspondances partielles dans le même haystack local ;
  /// - ordre secondaire stable par nom puis id.
  ///
  /// Non-objectifs assumés :
  /// - pas de fuzzy matching ;
  /// - pas d'auto-correction ;
  /// - pas de résolution implicite d'alias non exposés par la donnée locale.
  List<PokemonMoveCatalogEntryView> search(
    List<PokemonMoveCatalogEntryView> entries,
    String rawQuery, {
    int limit = 8,
  }) {
    final normalizedQuery = rawQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return entries.take(limit).toList(growable: false);
    }

    final rankedEntries = entries
        .map(
          (entry) => (
            entry: entry,
            rank: _rankEntry(entry, normalizedQuery),
          ),
        )
        .where((candidate) => candidate.rank != null)
        .cast<({PokemonMoveCatalogEntryView entry, int rank})>()
        .toList(growable: false)
      ..sort((left, right) {
        final rankCompare = left.rank.compareTo(right.rank);
        if (rankCompare != 0) {
          return rankCompare;
        }
        final nameCompare = left.entry.name.compareTo(right.entry.name);
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.entry.id.compareTo(right.entry.id);
      });

    return rankedEntries
        .take(limit)
        .map((candidate) => candidate.entry)
        .toList(growable: false);
  }

  int? _rankEntry(
    PokemonMoveCatalogEntryView entry,
    String normalizedQuery,
  ) {
    final normalizedId = entry.id.toLowerCase();
    final normalizedName = entry.name.toLowerCase();
    final haystack = <String>[
      entry.id,
      entry.name,
      entry.type ?? '',
      entry.category ?? '',
      entry.shortDesc ?? '',
    ].join(' ').toLowerCase();

    if (normalizedId == normalizedQuery) {
      return 0;
    }
    if (normalizedName == normalizedQuery) {
      return 1;
    }
    if (normalizedId.startsWith(normalizedQuery)) {
      return 2;
    }
    if (normalizedName.startsWith(normalizedQuery)) {
      return 3;
    }
    if (haystack.contains(normalizedQuery)) {
      return 4;
    }
    return null;
  }
}
