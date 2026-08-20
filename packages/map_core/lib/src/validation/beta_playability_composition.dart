/// Ce que la gate de jouabilité bêta compose, et ce qu'elle ne compose pas.
///
/// BETA-SYS-005. Le ticket disait « sa composition est plus étroite que le
/// ticket et ne couvre pas toutes les gates ». Mesuré le 2026-08-20 : la gate
/// compose ZÉRO des validateurs de domaine du dépôt, et `player_roster_validation`
/// n'a aucun appelant nulle part.
///
/// Rien ne signalait cet écart, parce que ne pas composer un validateur ne
/// casse rien : la gate rend simplement un verdict trop optimiste. Ce catalogue
/// rend l'oubli impossible en silence — un test lit le répertoire
/// `lib/src/validation/` et exige une entrée pour chaque fichier, donc en
/// ajouter un sans décider s'il entre dans la gate fait échouer la suite.
///
/// C'est la même discipline que le catalogue des volatiles de combat : le
/// niveau de couverture est déclaré ET confronté à la source.
library;

/// Place d'un validateur vis-à-vis de la gate de jouabilité bêta.
enum BetaPlayabilityCompositionRole {
  /// La gate elle-même, ou son propre outillage.
  gate,

  /// Composé dans le verdict de jouabilité bêta.
  composed,

  /// Hors périmètre : le validateur répond à une autre question que
  /// « ce projet est-il jouable de bout en bout ».
  outOfScope,

  /// Dans le périmètre, mais PAS encore composé. C'est de la dette, et elle est
  /// nommée pour ne pas se confondre avec un choix.
  pendingComposition,
}

/// Un validateur du dépôt et sa place dans la gate.
class BetaPlayabilityCompositionEntry {
  const BetaPlayabilityCompositionEntry({
    required this.sourceFileName,
    required this.role,
    required this.rationale,
  });

  /// Nom de fichier sous `lib/src/validation/`.
  final String sourceFileName;

  final BetaPlayabilityCompositionRole role;

  /// Pourquoi cette place. Obligatoire : une dette sans explication redevient
  /// un oubli au bout de deux mois.
  final String rationale;
}

/// Catalogue de composition, trié par nom de fichier.
const List<BetaPlayabilityCompositionEntry> betaPlayabilityComposition =
    <BetaPlayabilityCompositionEntry>[
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'beta_playability_composition.dart',
    role: BetaPlayabilityCompositionRole.gate,
    rationale: 'Ce catalogue lui-même.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'beta_playability_validator.dart',
    role: BetaPlayabilityCompositionRole.gate,
    rationale: 'La gate. Elle valide maps, spawns, dresseurs, espèces, '
        'capacités, starters, capture, sauvegarde, et depuis BETA-SYS-005 les '
        'capacités terrain exigées par les zones de mouvement.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'border_validation.dart',
    role: BetaPlayabilityCompositionRole.outOfScope,
    rationale: 'Cohérence des plans de bordure pendant l\'édition. Une bordure '
        'incohérente est laide, pas injouable.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'dialogue_validation.dart',
    role: BetaPlayabilityCompositionRole.outOfScope,
    rationale: 'Convention de chemin des fichiers de dialogue. Contrainte '
        'd\'organisation du projet, pas de parcours joueur.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'entity_editor_visual_validation.dart',
    role: BetaPlayabilityCompositionRole.outOfScope,
    rationale: 'Rendu des entités dans l\'éditeur. Aucune incidence sur le '
        'parcours joueur.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'map_delta_validator.dart',
    role: BetaPlayabilityCompositionRole.outOfScope,
    rationale: 'Bien-formation d\'un delta de mutation de carte, vérifiée au '
        'moment d\'appliquer. Rien à dire sur un projet au repos.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'player_roster_validation.dart',
    role: BetaPlayabilityCompositionRole.pendingComposition,
    rationale: 'DETTE. Ce validateur n\'a AUCUN appelant dans tout le dépôt : '
        'ni la gate, ni l\'éditeur, ni l\'export. Un roster de départ invalide '
        'passe donc partout. À composer sous BETA-PTY-005, qui porte la gate '
        'Party/PC.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'pokemon_catalog_coherence_validator.dart',
    role: BetaPlayabilityCompositionRole.pendingComposition,
    rationale: 'DETTE. Utilisé par l\'authoring et un sanitizer de l\'éditeur, '
        'jamais par la gate. Or c\'est lui qui a bloqué la certification des '
        'objets en refusant la fixture golden sous BETA-ITM-007 : ses 19 '
        'diagnostics sont exactement le genre de chose qui rend un projet '
        'inexportable, et la gate n\'en sait rien.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'project_item_catalog_validator.dart',
    role: BetaPlayabilityCompositionRole.pendingComposition,
    rationale: 'DETTE. Utilisé par l\'authoring, l\'éditeur et la certification '
        'objets, jamais par la gate. À composer avec BETA-ITM-008.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'shop_state_validator.dart',
    role: BetaPlayabilityCompositionRole.pendingComposition,
    rationale: 'DETTE. Utilisé seulement par le contrôleur de simulation de '
        'l\'éditeur. Une boutique incohérente est un blocage de parcours si le '
        'joueur y achète une Poké Ball obligatoire.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'validators.dart',
    role: BetaPlayabilityCompositionRole.gate,
    rationale: 'Baril d\'exports du dossier, pas un validateur.',
  ),
];
