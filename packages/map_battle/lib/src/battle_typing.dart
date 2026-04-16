/// Snapshot battle minimal du typing défensif/offensif d'un combattant.
///
/// BE5 ajoute ce contrat pour une raison très concrète :
/// - le moteur possède déjà le type du move ;
/// - mais il ne connaissait toujours pas les types du combattant ;
/// - sans cette donnée, STAB, résistances, faiblesses et immunités restaient
///   impossibles à calculer honnêtement.
///
/// Frontière volontairement petite :
/// - on porte seulement 1 ou 2 types ;
/// - on ne crée pas de framework de typing générique ;
/// - on ne duplique ni le JSON projet, ni un Dex complet dans le contrat.
///
/// Compatibilité assumée :
/// - le vrai chemin runtime -> battle doit fournir un typing explicite ;
/// - les anciens call sites directs de `map_battle` peuvent encore laisser ce
///   champ absent au niveau de `BattleCombatantData` / `BattleCombatant` ;
/// - dans ce cas, le moteur reste neutre sur STAB/effectiveness au lieu
///   d'inventer un typing mensonger.
class BattleTypingSnapshot {
  const BattleTypingSnapshot({
    required this.primaryType,
    this.secondaryType,
  })  : assert(primaryType != ''),
        assert(secondaryType == null || secondaryType != '');

  /// Type principal du combattant.
  final String primaryType;

  /// Type secondaire éventuel du combattant.
  ///
  /// Reste nullable pour représenter proprement les espèces mono-type sans
  /// introduire de sentinelle artificielle du genre `"none"`.
  final String? secondaryType;

  /// Vue ordonnée des types réellement portés.
  ///
  /// L'ordre est conservé pour rester aligné avec la donnée espèce source,
  /// même si BE5 n'en a pas encore besoin pour autre chose que l'itération.
  List<String> get types => <String>[
        primaryType,
        if (secondaryType != null) secondaryType!,
      ];

  /// true si le combattant possède déjà [type].
  ///
  /// Helper borné à BE5 :
  /// - évite de dupliquer les comparaisons STAB dans le moteur ;
  /// - reste volontairement en `String` car `BattleMove.type` est déjà un
  ///   petit contrat stringly-typed côté battle.
  bool hasType(String type) {
    final normalizedType = type.trim().toLowerCase();
    return primaryType.trim().toLowerCase() == normalizedType ||
        secondaryType?.trim().toLowerCase() == normalizedType;
  }
}
