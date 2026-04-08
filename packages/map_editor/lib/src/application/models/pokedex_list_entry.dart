/// Projection applicative minimale d'une ligne de liste Pokédex.
///
/// Cette classe reste volontairement découplée du stockage local :
/// - aucun chemin de fichier
/// - aucun détail de workspace
/// - uniquement les champs utiles à une future UI de liste
class PokedexListEntry {
  const PokedexListEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.isStarterEligible,
    this.genIntroduced,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final List<String> types;
  final bool isStarterEligible;
  final int? genIntroduced;
}
