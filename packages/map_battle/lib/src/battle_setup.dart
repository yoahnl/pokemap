import 'battle_move.dart';
import 'battle_stats.dart';
import 'battle_typing.dart';

/// Configuration initiale d'un combat.
///
/// Modèle pur, sans dépendance runtime.
/// Construit depuis [BattleStartRequest] par le runtime via un mapper dédié.
///
/// Ce modèle contient uniquement les données nécessaires au moteur de combat,
/// sans aucune référence à l'orchestration runtime (OverworldReturnContext, etc.).
class BattleSetup {
  /// Crée une configuration de combat.
  ///
  /// [playerPokemon] - Le Pokémon du joueur qui combat.
  /// [enemyPokemon] - Le Pokémon adverse qui combat.
  /// [isTrainerBattle] - true si c'est un combat contre un dresseur.
  /// [trainerId] - L'identifiant du dresseur (non-null si [isTrainerBattle] est true).
  /// [allowCapture] - true si le runtime autorise explicitement la capture
  ///   pour ce combat. Le lot 13 l'utilise uniquement pour les rencontres
  ///   sauvages quand la party a encore de la place.
  const BattleSetup({
    required this.playerPokemon,
    required this.enemyPokemon,
    required this.isTrainerBattle,
    required this.trainerId,
    this.allowCapture = false,
  });

  /// Le Pokémon du joueur qui combat.
  final BattleCombatantData playerPokemon;

  /// Le Pokémon adverse qui combat.
  final BattleCombatantData enemyPokemon;

  /// true si c'est un combat contre un dresseur.
  ///
  /// Si false, c'est une rencontre sauvage (wild battle).
  final bool isTrainerBattle;

  /// L'identifiant du dresseur.
  ///
  /// Non-null si [isTrainerBattle] est true.
  /// Utilisé par le runtime pour marquer `trainer_defeated:{trainerId}` après victoire.
  final String? trainerId;

  /// true si l'action Capture doit être exposée au joueur.
  ///
  /// Invariants métier lot 13 :
  /// - jamais en combat trainer ;
  /// - seulement si le runtime sait qu'une capture réussie peut être écrite
  ///   proprement dans l'état joueur ;
  /// - on évite ainsi toute promesse mensongère quand la party est pleine.
  final bool allowCapture;
}

/// Données minimales d'un combattant pour initialiser un combat.
///
/// Ce modèle est utilisé uniquement pour la configuration initiale.
/// Une fois le combat démarré, [BattleCombatant] est utilisé à la place.
class BattleCombatantData {
  /// Crée les données d'un combattant.
  ///
  /// [speciesId] - L'identifiant de l'espèce (ex: "pikachu", "lapras").
  /// [level] - Le niveau du combattant.
  /// [maxHp] - Les points de vie maximum.
  /// [currentHp] - Les PV courants si le runtime les connaît déjà.
  /// [stats] - Snapshot résolu des stats non-HP réellement exploitées par le
  /// moteur battle.
  /// [typing] - Typing défensif/offensif minimal du combattant si connu.
  /// [abilityId] - L'ability réellement résolue si le runtime la connaît.
  ///
  /// Le lot 9 du runtime -> battle handoff doit partir de la vraie party du
  /// joueur. On ajoute donc ce champ optionnel au setup pour éviter de soigner
  /// implicitement le Pokémon actif lors de l'ouverture du combat.
  /// [moves] - La liste des attaques disponibles (4 max).
  const BattleCombatantData({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.stats,
    this.typing,
    this.currentHp,
    this.abilityId = 'unknown',
    required this.moves,
  });

  /// L'identifiant de l'espèce (ex: "pikachu", "lapras").
  final String speciesId;

  /// Le niveau du combattant.
  final int level;

  /// Les points de vie maximum.
  final int maxHp;

  /// Snapshot résolu des stats non-HP pour ce combattant.
  ///
  /// BE2 choisit un vrai contrat typé ici pour deux raisons :
  /// - le moteur ne doit plus inventer implicitement des valeurs offensives /
  ///   défensives à partir de rien ;
  /// - le runtime est la bonne frontière pour résoudre ces stats à partir des
  ///   species data, du niveau et des IV/EV disponibles.
  ///
  /// `speed` est déjà transportée pour arrêter sa perte silencieuse, même si
  /// elle est maintenant consommée pour l'ordre d'action honnête minimal.
  final BattleStatsSnapshot stats;

  /// Typing minimal du combattant si le handoff le connaît déjà.
  ///
  /// BE5 choisit ici une compatibilité volontairement bornée :
  /// - le vrai chemin runtime -> battle doit fournir cette donnée ;
  /// - les anciens call sites directs de `map_battle` peuvent encore l'omettre
  ///   pour éviter une migration parasite de tout le package ;
  /// - en l'absence de typing, le moteur reste neutre sur STAB/effectiveness
  ///   au lieu d'inventer un type mensonger.
  final BattleTypingSnapshot? typing;

  /// Les points de vie courants si le handoff runtime les fournit déjà.
  ///
  /// Si null, le moteur démarre le combat à pleine vie, ce qui conserve le
  /// comportement historique des tests et call sites qui n'ont pas besoin de
  /// porter cet état.
  final int? currentHp;

  /// L'ability réellement résolue si le runtime la connaît déjà.
  ///
  /// Le moteur de combat MVP n'utilise pas encore cette donnée pour ses
  /// calculs, mais le lot 13 en a besoin pour construire un Pokémon capturé
  /// sans réinventer un deuxième format intermédiaire.
  final String abilityId;

  /// La liste des attaques disponibles.
  final List<BattleMoveData> moves;
}

/// Données minimales d'une attaque pour initialiser un combat.
///
/// Ce modèle est utilisé uniquement pour la configuration initiale.
/// Une fois le combat démarré, [BattleMove] est utilisé à la place.
///
/// Mini-fix BE6-2 :
/// - ce contrat de setup devient lui aussi `final` ;
/// - il doit rester un petit DTO battle, pas une surface extensible ;
/// - verrouiller aussi le setup évite de fermer `BattleMove` tout en laissant
///   encore entrer des valeurs malformées par héritage avant la création de
///   session ;
/// - on garde `const`, les assertions locales, puis les gardes runtime comme
///   défense en profondeur, mais le bypass trivial par override disparaît.
final class BattleMoveData {
  /// Crée les données d'une attaque.
  ///
  /// [id] - L'identifiant canonique de l'attaque.
  /// [name] - Le nom affiché de l'attaque.
  /// [power] - La puissance de l'attaque (dégâts de base).
  /// [type] - Le type canonique transporté puis consommé pour la couche type
  ///   minimale ouverte en BE5.
  /// [category] - La catégorie battle minimale déjà résolue par le runtime.
  /// [target] - La cible battle minimale résolue par le bridge runtime.
  /// [accuracy] - La précision battle minimale réellement consommée par BE4.
  /// [pp] - Le PP max transporté vers le moteur.
  /// [currentPp] - Le PP courant initial si un call site battle direct veut
  ///   forcer un état de combat déjà entamé.
  /// [priority] - Priorité canonique transportée et consommée par BE3 pour
  ///   l'ordre d'action minimal honnête.
  /// [critRatio] - Ratio critique minimal transporté et consommé par BE6.
  /// [selfStatStageChanges] - Boosts / baisses appliqués au lanceur.
  /// [targetStatStageChanges] - Boosts / baisses appliqués à la cible.
  ///
  /// Ce contrat reste volontairement petit :
  /// - il ne copie pas `PokemonMove` ;
  /// - il ne prétend pas transporter tous les `effects` canoniques ;
  /// - mais BE1 y ajoute aussi quelques dimensions battle fondamentales
  ///   (`type`, `target`, `pp`) pour arrêter leur perte silencieuse ;
  /// - puis BE3 et BE4 commencent à consommer réellement `priority`,
  ///   `speed`, `accuracy` et les PP ;
  /// - puis BE6 ouvre enfin un crit minimal honnête via `critRatio` ;
  /// - le reste reste explicitement hors scope.
  const BattleMoveData({
    required this.id,
    required this.name,
    required this.power,
    this.type = 'unknown',
    this.category,
    this.target = BattleMoveTarget.unspecified,
    this.accuracy = const BattleMoveAccuracy.percent(value: 100),
    this.pp = 35,
    this.currentPp,
    this.priority = 0,
    int critRatio = 1,
    this.selfStatStageChanges = const <BattleStatStageChange>[],
    this.targetStatStageChanges = const <BattleStatStageChange>[],
  })  : assert(
          critRatio >= 1,
          'BattleMoveData critRatio must be >= 1.',
        ),
        _critRatio = critRatio;

  /// L'identifiant canonique de l'attaque.
  final String id;

  /// Le nom affiché de l'attaque.
  final String name;

  /// La puissance de l'attaque (dégâts de base).
  ///
  /// Depuis BE2, cette donnée n'est plus utilisée seule :
  /// - `power` reste bien la base du damage contract ;
  /// - mais le moteur la combine maintenant avec les vraies stats résolues
  ///   du combattant et de sa cible ;
  /// - un move de statut garde `power <= 0` et inflige donc 0 dégât.
  final int power;

  /// Type canonique du move.
  ///
  /// Donnée transportée dès BE1 pour éviter sa perte silencieuse au handoff.
  ///
  /// BE5 commence enfin à la consommer réellement pour :
  /// - le STAB ;
  /// - l'efficacité de type ;
  /// - les immunités.
  ///
  /// Les anciens call sites directs peuvent encore garder la valeur par défaut
  /// `"unknown"` : dans ce cas, le moteur reste neutre au lieu de prétendre
  /// connaître un type qu'il n'a pas.
  final String type;

  /// Catégorie battle explicitement résolue par le bridge runtime.
  ///
  /// Ce champ est optionnel pour préserver les anciens call sites/tests qui ne
  /// transportaient encore que `power`.
  final BattleMoveCategory? category;

  /// Cible battle minimale résolue par le bridge runtime.
  ///
  /// Le moteur n'en tire pas encore une logique complète de targeting, mais le
  /// handoff ne doit plus jeter cette information quand elle reste simple et
  /// honnête dans le cadre 1v1 actuel.
  final BattleMoveTarget target;

  /// Contrat minimal de précision battle.
  ///
  /// BE4 ouvre enfin un vrai hit pipeline honnête :
  /// - le moteur n'a plus besoin que le runtime neutralise l'accuracy ;
  /// - `alwaysHits` et `percent` suffisent pour le sous-ensemble supporté ;
  /// - le reste des mécaniques de précision reste hors scope.
  final BattleMoveAccuracy accuracy;

  /// PP maximum du move.
  ///
  /// `BattleMoveData` reste un contrat de setup :
  /// - `pp` décrit la capacité max du move ;
  /// - `currentPp`, si fourni, permet seulement d'initialiser un état battle
  ///   déjà entamé ;
  /// - sinon, le moteur démarre à pleine valeur.
  ///
  /// Compatibilité volontairement bornée :
  /// - le chemin runtime -> battle fournit déjà le PP canonique réel ;
  /// - les anciens call sites `map_battle` directs n'avaient souvent aucun PP
  ///   explicite et supposaient juste "move utilisable" ;
  /// - on garde donc un défaut pragmatique à 35 pour ne pas transformer BE4
  ///   en migration massive hors scope ;
  /// - ce défaut n'est pas une vérité Pokédex : c'est un garde-fou de
  ///   compatibilité pour les setups battle locaux, documenté comme tel.
  final int pp;

  /// Valeur courante de PP au démarrage de la session si connue.
  ///
  /// Le runtime principal n'en a pas besoin aujourd'hui :
  /// - les combats commencent encore avec tous les PP pleins ;
  /// - la write-back des PP reste hors scope.
  ///
  /// En revanche, ce champ rend le contrat battle direct plus honnête et
  /// simplifie les tests ciblés de BE4 sans bricoler l'état après coup.
  final int? currentPp;

  /// Priorité battle minimale du move.
  ///
  /// BE1 refusait encore `priority != 0` parce que le moteur résolvait
  /// toujours "joueur puis ennemi". BE3 ouvre enfin ce champ :
  /// - il est transporté dès le setup ;
  /// - il est consommé ensuite par `BattleSession` pour l'ordre du tour ;
  /// - mais il ne crée pas pour autant une vraie queue générique.
  final int priority;

  /// Ratio critique minimal transporté jusqu'au moteur battle.
  ///
  /// BE6 reste volontairement petit :
  /// - on transporte seulement l'entier canonique déjà présent côté runtime ;
  /// - le moteur battle l'interprète via une table locale explicite ;
  /// - on n'ouvre pas les règles avancées de critique du jeu complet.
  ///
  /// Valeur neutre :
  /// - `1` correspond au ratio critique standard.
  ///
  /// Garde-fou de mini-fix BE6 :
  /// - comme pour `BattleMove`, ce contrat de setup reste `const` pour ne pas
  ///   casser inutilement les anciens call sites battle directs ;
  /// - l’assertion arrête donc tôt les usages invalides en debug/test ;
  /// - BE6-mini-fix-2 verrouille maintenant aussi la classe au niveau langage,
  ///   donc le contournement trivial par sous-classe externe disparaît ;
  /// - on garde en plus un getter validé, car un objet battle incohérent peut
  ///   encore apparaître via un futur mauvais refactor interne ;
  /// - le moteur garde enfin sa propre validation défensive au moment exact où
  ///   il consomme le ratio critique ; cette dernière garde reste une défense
  ///   en profondeur, pas la preuve principale du contrat public.
  final int _critRatio;

  int get critRatio {
    if (_critRatio < 1) {
      throw StateError(
        'BattleMoveData critRatio must be >= 1; got $_critRatio.',
      );
    }
    return _critRatio;
  }

  /// Changements d'étages de stats appliqués au lanceur.
  final List<BattleStatStageChange> selfStatStageChanges;

  /// Changements d'étages de stats appliqués à la cible.
  final List<BattleStatStageChange> targetStatStageChanges;
}
