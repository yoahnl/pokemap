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
    role: BetaPlayabilityCompositionRole.composed,
    rationale: 'COMPOSÉ sous BETA-SYS-005, par appel direct sur le roster '
        'INITIAL du projet. Il n\'avait aucun appelant dans tout le dépôt. La '
        'gate vérifiait déjà les références du roster initial via des ensembles, '
        'mais pas sa structure : une party de sept jetait un StateError au '
        'démarrage de la nouvelle partie, et une espèce vide disparaissait des '
        'ensembles après trim. Appelé SANS catalogues, exprès : les références '
        'restent au contrôle existant, sinon chaque espèce inconnue serait '
        'signalée deux fois sous deux codes. Les rosters de SAUVEGARDE restent '
        'hors gate — la gate valide un projet, pas une partie ; la garde des '
        'sauvegardes est PlayerParty.normalized(), qui refuse au chargement.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'pokemon_catalog_coherence_validator.dart',
    role: BetaPlayabilityCompositionRole.composed,
    rationale: 'COMPOSÉ sous BETA-SYS-005. La gate reçoit le nombre d\'erreurs '
        'du PokemonCatalogCoherenceReport et refuse le projet quand il est non '
        'nul ; quand le compte est absent, elle DIT qu\'elle ne s\'est pas '
        'prononcée au lieu de conclure que tout va bien. Le chemin d\'export le '
        'transmet, donc « jouable » veut désormais dire « jouable catalogues '
        'compris ». C\'est ce validateur qui avait bloqué la certification des '
        'objets sous BETA-ITM-007 en refusant la fixture golden.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'project_item_catalog_validator.dart',
    role: BetaPlayabilityCompositionRole.pendingComposition,
    rationale: 'DETTE. Utilisé par l\'authoring, l\'éditeur et la certification '
        'objets. Vérifié : ni la gate ni le chemin d\'export ne l\'appellent, '
        'contrairement à la cohérence Pokémon. À composer avec BETA-ITM-008.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'shop_state_validator.dart',
    role: BetaPlayabilityCompositionRole.composed,
    rationale: 'COMPOSÉ sous BETA-SYS-005, et par APPEL DIRECT : le validateur '
        'est pur sur le manifeste, donc la gate l\'invoque elle-même au lieu de '
        'recevoir un verdict digéré — aucun appelant ne peut oublier de le '
        'déclencher. Il n\'était appelé que par le contrôleur de simulation de '
        'l\'éditeur, donc une boutique incohérente passait l\'export sans un '
        'mot. Réserve assumée : deux de ses huit contrôles ont besoin du '
        'catalogue d\'objets ; sans lui ils sont supprimés et la gate le dit, '
        'plutôt que de déclarer inconnue chaque référence.',
  ),
  BetaPlayabilityCompositionEntry(
    sourceFileName: 'validators.dart',
    role: BetaPlayabilityCompositionRole.gate,
    rationale: 'Baril d\'exports du dossier, pas un validateur.',
  ),
];
