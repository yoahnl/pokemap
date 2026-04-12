// Socle progressif de recherche dans un catalogue local déjà chargé.
//
// Intention du lot 6 :
// - offrir un point commun réutilisable entre catalogues locaux ;
// - partir de `moves` sans forcer un framework multi-catalogues ;
// - rester purement en mémoire, sans loader ni repository supplémentaire.
//
// On évite volontairement une interface séparée ici :
// - il n'existe encore qu'un premier consommateur concret (`moves`) ;
// - ajouter une couche d'abstraction de plus serait de la sur-ingénierie ;
// - ce service générique suffit déjà comme contrat stable et testable.

typedef LocalCatalogIdOf<TEntry> = String Function(TEntry entry);
typedef LocalCatalogLabelOf<TEntry> = String Function(TEntry entry);
typedef LocalCatalogSearchTermsOf<TEntry> = Iterable<String> Function(
  TEntry entry,
);

/// Implémentation progressive et réutilisable du contrat de recherche locale.
///
/// Décisions assumées :
/// - l'algorithme reste simple et stable ;
/// - pas de fuzzy matching ;
/// - pas de normalisation destructive ;
/// - l'ordre des résultats reste prédictible.
///
/// Cela suffit pour préparer trainers / encounters plus tard sans imposer une
/// architecture générique disproportionnée dès maintenant.
class ProgressiveLocalCatalogLookupService<TEntry> {
  const ProgressiveLocalCatalogLookupService({
    required this.idOf,
    required this.labelOf,
    required this.searchTermsOf,
  });

  final LocalCatalogIdOf<TEntry> idOf;
  final LocalCatalogLabelOf<TEntry> labelOf;
  final LocalCatalogSearchTermsOf<TEntry> searchTermsOf;

  TEntry? findById(
    Iterable<TEntry> entries,
    String id,
  ) {
    final normalizedId = id.trim().toLowerCase();
    if (normalizedId.isEmpty) {
      return null;
    }

    for (final entry in entries) {
      if (idOf(entry).trim().toLowerCase() == normalizedId) {
        return entry;
      }
    }
    return null;
  }

  List<TEntry> search(
    Iterable<TEntry> entries,
    String rawQuery, {
    int limit = 8,
  }) {
    final safeLimit = limit <= 0 ? 0 : limit;
    if (safeLimit == 0) {
      return <TEntry>[];
    }

    final materializedEntries = entries.toList(growable: false);
    final normalizedQuery = rawQuery.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return materializedEntries.take(safeLimit).toList(growable: false);
    }

    final rankedEntries = materializedEntries
        .map(
          (entry) => (
            entry: entry,
            rank: _rankEntry(entry, normalizedQuery),
          ),
        )
        .where((candidate) => candidate.rank != null)
        .cast<({TEntry entry, int rank})>()
        .toList(growable: false)
      ..sort((left, right) {
        final rankCompare = left.rank.compareTo(right.rank);
        if (rankCompare != 0) {
          return rankCompare;
        }
        final labelCompare =
            labelOf(left.entry).compareTo(labelOf(right.entry));
        if (labelCompare != 0) {
          return labelCompare;
        }
        return idOf(left.entry).compareTo(idOf(right.entry));
      });

    return rankedEntries
        .take(safeLimit)
        .map((candidate) => candidate.entry)
        .toList(growable: false);
  }

  int? _rankEntry(TEntry entry, String normalizedQuery) {
    final normalizedId = idOf(entry).trim().toLowerCase();
    final normalizedLabel = labelOf(entry).trim().toLowerCase();
    final haystack = searchTermsOf(entry)
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(' ')
        .toLowerCase();

    if (normalizedId == normalizedQuery) {
      return 0;
    }
    if (normalizedLabel == normalizedQuery) {
      return 1;
    }
    if (normalizedId.startsWith(normalizedQuery)) {
      return 2;
    }
    if (normalizedLabel.startsWith(normalizedQuery)) {
      return 3;
    }
    if (haystack.contains(normalizedQuery)) {
      return 4;
    }
    return null;
  }
}
