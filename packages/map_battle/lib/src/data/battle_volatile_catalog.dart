/// Inventaire des familles de conditions volatiles du moteur de combat.
///
/// Le ticket BETA-BAT-005 met en garde : « ne pas promettre toutes les
/// volatiles sans inventaire ». Ce catalogue est donc une déclaration
/// auditable, à côté de [BattleParityTarget] et de `psdk_damage_reference`,
/// dont la particularité est qu'elle est **confrontée à la réalité par un
/// test** plutôt que maintenue à la main.
///
/// `battle_volatile_catalog_test.dart` vérifie les deux sens :
/// - toute famille présente dans `lib/src/domain/effect/move/` figure ici, donc
///   on ne peut pas ajouter une volatile sans la classer ;
/// - toute famille déclarée ici existe dans le moteur, donc le catalogue ne peut
///   pas promettre une mécanique absente.
///
/// Le niveau de support n'est pas déclaratif non plus : il est mesuré. Une
/// famille `certified` doit être nommée par au moins un fichier de test, une
/// famille `implemented` par aucun. Écrire un test pour une famille
/// `implemented` fait donc échouer la suite jusqu'à ce que son niveau soit
/// relevé, et supprimer le dernier test d'une famille `certified` la fait
/// échouer aussi. Aucun des deux sens ne peut dériver en silence.
///
/// ORDRE DES DÉCLENCHEURS, second critère du ticket : une volatile posée par un
/// rider de capacité passe par `battle_move_secondary_effect_resolver`, après
/// les dégâts et après l'application d'un éventuel statut majeur. Une volatile
/// posée par une méthode de combat (`s_protect` et sa famille) est posée par le
/// comportement lui-même, avant la résolution des dégâts du tour. Le nettoyage
/// suit trois chemins distincts : fin de tour pour les protections, sortie de
/// terrain pour tout ce que `_switchOutSnapshot` emporte avec la pile d'effets,
/// et fin de combat pour le write-back, qui ne persiste aucun volatile.
library;

/// Niveau de support d'une famille de volatile.
enum BattleVolatileSupport {
  /// Implémentée, exercée par un test, et conforme à ce que sa famille promet.
  certified,

  /// Exercée par un test qui CONSIGNE UN ÉCART connu.
  ///
  /// Ce niveau existe pour ne pas avoir à choisir entre mentir et ne rien dire
  /// quand une famille marche à moitié. Il n'a aucun membre aujourd'hui : les
  /// six variantes de protection l'ont porté le temps qu'un hook mutateur
  /// dédié soit ajouté pour leur punition de contact, puis sont passées en
  /// `certified`. Le garder documente la distinction pour la prochaine fois.
  partial,

  /// Atteignable, mais aucun test ne la nomme.
  ///
  /// Ce niveau n'est pas un fourre-tout : c'est une dette visible. Les quatre
  /// familles qui le portent au 2026-08-18 sont toutes atteignables depuis
  /// `static_basic_move_registry`, donc une vraie capacité peut les poser sans
  /// qu'aucune preuve ne décrive leur cycle de vie.
  implemented,
}

/// Une famille de volatile et son niveau de support mesuré.
final class BattleVolatileFamily {
  const BattleVolatileFamily({
    required this.id,
    required this.support,
    this.note,
  });

  /// Identifiant d'effet, tel que le moteur le porte dans sa pile.
  final String id;

  final BattleVolatileSupport support;

  /// Précision quand le nom ne suffit pas. Volontairement absente partout où il
  /// n'y a rien à ajouter : une note par famille produirait de la prose que
  /// personne n'a vérifiée.
  final String? note;
}

/// Catalogue complet, trié par identifiant.
const battleVolatileCatalog = <BattleVolatileFamily>[
  BattleVolatileFamily(
    id: 'ability_suppressed',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'aqua_ring',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'attract',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'baneful_bunker',
    support: BattleVolatileSupport.certified,
    note: 'Famille protection. Punition de contact verifiee : poison.',
  ),
  BattleVolatileFamily(
    id: 'baton_pass',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'beak_blast',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'bestow',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'bide',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'bind',
    support: BattleVolatileSupport.certified,
    note:
        'Famille trapping, minimum exige par le ticket. Identifiant declare via PsdkBattleEffectIds.',
  ),
  BattleVolatileFamily(
    id: 'burning_bulwark',
    support: BattleVolatileSupport.certified,
    note: 'Famille protection. Punition de contact verifiee : brulure.',
  ),
  BattleVolatileFamily(
    id: 'cant_switch',
    support: BattleVolatileSupport.certified,
    note:
        'Famille trapping, minimum exige par le ticket. Identifiant declare via PsdkBattleEffectIds.',
  ),
  BattleVolatileFamily(
    id: 'confusion',
    support: BattleVolatileSupport.certified,
    note:
        'Rider de capacite, vocabulaire PsdkBattleVolatileStatus. Minimum exige par le ticket.',
  ),
  BattleVolatileFamily(
    id: 'curse',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'destiny_bond',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'disable',
    support: BattleVolatileSupport.certified,
    note: 'Minimum exige par le ticket.',
  ),
  BattleVolatileFamily(
    id: 'drowsiness',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'echoed_voice',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'embargo',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'encore',
    support: BattleVolatileSupport.certified,
    note: 'Minimum exige par le ticket.',
  ),
  BattleVolatileFamily(
    id: 'endure',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'fairy_lock',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'flinch',
    support: BattleVolatileSupport.certified,
    note:
        'Rider de capacite, vocabulaire PsdkBattleVolatileStatus. Minimum exige par le ticket.',
  ),
  BattleVolatileFamily(
    id: 'focus_punch',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'force_next_move_base',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'grudge',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'happy_hour',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'heal_block',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'imprison',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'ingrain',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'item_burnt',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'item_stolen',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'king_s_shield',
    support: BattleVolatileSupport.certified,
    note: 'Famille protection. Punition de contact verifiee : Attaque -1.',
  ),
  BattleVolatileFamily(
    id: 'leech_seed',
    support: BattleVolatileSupport.certified,
    note: 'Minimum exige par le ticket.',
  ),
  BattleVolatileFamily(
    id: 'lock_on',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'magic_coat',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'nightmare',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'no_retreat',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'obstruct',
    support: BattleVolatileSupport.certified,
    note: 'Famille protection. Punition de contact verifiee : Defense -2.',
  ),
  BattleVolatileFamily(
    id: 'octolock',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'perish_song',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'powder',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'prevent_targets_move',
    support: BattleVolatileSupport.implemented,
    note:
        'Enregistree dans battle_effect_registry avec un identifiant canonique, sans aucune preuve de cycle de vie.',
  ),
  BattleVolatileFamily(
    id: 'protect',
    support: BattleVolatileSupport.certified,
    note:
        'Famille protection, minimum exige par le ticket. Bloque sans punir, contrairement a ses variantes.',
  ),
  BattleVolatileFamily(
    id: 'rollout',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'roost',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'salt_cure',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'shed_tail',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'shell_trap',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'silk_trap',
    support: BattleVolatileSupport.certified,
    note: 'Famille protection. Punition de contact verifiee : Vitesse -1.',
  ),
  BattleVolatileFamily(
    id: 'smack_down',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'snatch',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'snatched',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'spiky_shield',
    support: BattleVolatileSupport.certified,
    note:
        'Famille protection. Punition de contact verifiee : degats de maxHp / 8.',
  ),
  BattleVolatileFamily(
    id: 'stockpile',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'substitute',
    support: BattleVolatileSupport.certified,
    note:
        'Hors du modele legacy BE8, qui le declare explicitement hors scope ; la voie PSDK l\'implemente.',
  ),
  BattleVolatileFamily(
    id: 'syrup_bomb',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'tar_shot',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'taunt',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'throat_chop',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'torment',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'triple_arrows',
    support: BattleVolatileSupport.certified,
  ),
  BattleVolatileFamily(
    id: 'two_turn_charge',
    support: BattleVolatileSupport.certified,
    note:
        'Famille recharge et charge sur deux tours, minimum exige par le ticket. Exercee par sa classe plutot que par son identifiant.',
  ),
  BattleVolatileFamily(
    id: 'uproar',
    support: BattleVolatileSupport.certified,
  ),
];
