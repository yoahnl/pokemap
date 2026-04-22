import 'battle_field.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';

/// Catégorie battle minimale d'une attaque.
///
/// M8 puis BE5 n'ouvrent toujours pas un système de typing complet, mais le
/// bridge runtime -> battle doit au moins distinguer :
/// - les attaques physiques ;
/// - les attaques spéciales ;
/// - les attaques de statut.
///
/// Cette information suffit pour donner un vrai effet battle au petit
/// sous-ensemble `modifyStats` retenu dans ce lot.
enum BattleMoveCategory {
  physical,
  special,
  status,
}

/// Cible battle minimale explicitement transportée par le bridge runtime.
///
/// BE1 ne crée pas un système de ciblage complet façon Showdown.
/// On transporte seulement ce qui est déjà honnête dans le moteur actuel :
/// - `self` pour les moves explicitement auto-ciblés ;
/// - `opponent` pour les moves qui, en 1v1 simple actif, ciblent l'adversaire ;
/// - `field` pour les moves BE9 qui posent une météo ou un pseudoWeather ;
/// - `unspecified` comme compatibilité pour les anciens call sites/tests qui
///   construisaient encore des `BattleMoveData` pauvres à la main.
///
/// Important :
/// - `unspecified` n'est pas une nouvelle sémantique battle ;
/// - c'est un garde-fou de compatibilité pour éviter d'inventer une cible
///   mensongère sur les anciens setups locaux ;
/// - le bridge runtime BE1, lui, doit toujours fournir une cible explicite.
enum BattleMoveTarget {
  unspecified,
  opponent,
  self,
  field,
  opponentSide,
}

/// Contrat minimal de précision réellement exécutable par `map_battle`.
///
/// BE4 n'importe pas `PokemonMoveAccuracy` depuis `map_core` :
/// - `map_battle` doit rester pur et indépendant du modèle projet ;
/// - le bridge runtime traduit donc vers ce petit contrat local ;
/// - on ne transporte que ce que le moteur sait réellement consommer.
///
/// Frontière volontaire :
/// - `alwaysHits` pour les moves qui bypassent le hit check ;
/// - `percent` pour un pourcentage entier simple ;
/// - pas d'evasion/accuracy stages ;
/// - pas d'autres variantes exotériques.
///
/// Note BE4 :
/// - `percent(100)` reste distinct de `alwaysHits` dans la donnée transportée ;
/// - mais le moteur actuel le résout quand même de façon déterministe, faute
///   de modificateurs accuracy/evasion dans ce lot.
enum BattleMoveAccuracyKind {
  alwaysHits,
  percent,
}

/// Représentation battle minimale de la précision.
///
/// Décision de BE4 :
/// - ce type vit au plus près de `BattleMove` parce qu'il n'a de sens que
///   pour le contrat move battle ;
/// - il reste petit, explicite et testable ;
/// - il n'ouvre ni une taxonomie canonique parallèle, ni une logique moteur
///   générique hors de proportion.
class BattleMoveAccuracy {
  const BattleMoveAccuracy.alwaysHits()
      : kind = BattleMoveAccuracyKind.alwaysHits,
        value = 100;

  const BattleMoveAccuracy.percent({
    required this.value,
  })  : assert(value >= 1 && value <= 100),
        kind = BattleMoveAccuracyKind.percent;

  final BattleMoveAccuracyKind kind;
  final int value;

  bool get isAlwaysHits => kind == BattleMoveAccuracyKind.alwaysHits;
}

/// Identifiant de stat exploitable par le moteur battle MVP enrichi.
///
/// Décision volontairement bornée pour M8 puis BE3 :
/// - on ne porte que les stats déjà utiles à un effet battle réel ;
/// - BE3 ouvre `speed` parce qu'elle devient enfin consommée pour l'ordre
///   d'action minimal honnête ;
/// - on n'ouvre toujours pas accuracy / evasion, car cela rouvrirait la
///   précision réelle et d'autres mécaniques hors scope ;
/// - le bridge runtime continue donc de refuser explicitement ces autres cas.
enum BattleStatId {
  attack,
  defense,
  specialAttack,
  specialDefense,
  speed,
}

/// Changement d'étage de stat appliqué pendant le combat.
///
/// Ce type est petit mais typé :
/// - il évite de faire circuler des `Map<String, int>` peu robustes ;
/// - il garde `BattleMoveData` et `BattleMove` lisibles ;
/// - il permet au moteur MVP d'appliquer un vrai effet non-dégât.
class BattleStatStageChange {
  const BattleStatStageChange({
    required this.stat,
    required this.stages,
  });

  final BattleStatId stat;
  final int stages;
}

/// Rider battle minimal de changement de stats résolu après un hit réussi.
///
/// BDC-01 garde volontairement ce contrat petit :
/// - un seul paquet de changements de stages ;
/// - une chance optionnelle, exprimée en pourcentage entier ;
/// - aucune callback, aucun bus d'événements, aucune logique Showdown-like.
class BattleStatStageEffect {
  const BattleStatStageEffect({
    required this.changes,
    this.chancePercent,
  }) : assert(chancePercent == null || (chancePercent >= 1 && chancePercent <= 100));

  final List<BattleStatStageChange> changes;
  final int? chancePercent;
}

/// Attaque utilisée pendant un combat.
///
/// Ce modèle représente une attaque disponible pour un combattant.
/// Il est utilisé pendant le combat, contrairement à [BattleMoveData]
/// qui est utilisé uniquement pour la configuration initiale.
///
/// Mini-fix BE6-2 :
/// - cette classe devient volontairement `final` ;
/// - ce n'est pas un point d'extension du moteur, mais un contrat de donnée ;
/// - le mini-fix précédent avait amélioré la robustesse locale, tout en
///   laissant un bypass trivial par héritage/override dans les tests ;
/// - on ferme donc ce trou au niveau langage au lieu de continuer à écrire
///   des preuves artificielles basées sur des sous-classes malformées.
final class BattleMove {
  /// Crée une attaque.
  ///
  /// [id] - L'identifiant canonique de l'attaque.
  /// [name] - Le nom affiché de l'attaque.
  /// [power] - La puissance de l'attaque (dégâts de base).
  /// [type] - Le type canonique transporté et désormais consommé pour STAB /
  ///   type chart dans le petit sous-ensemble honnête BE5.
  /// [category] - La catégorie battle minimale déjà résolue par le runtime.
  /// [target] - La cible battle minimale résolue par le bridge runtime.
  /// [accuracy] - La précision minimale réellement consommée par BE4.
  /// [pp] - Le PP max du move.
  /// [currentPp] - Le PP courant dans l'état battle.
  /// [priority] - Priorité canonique réellement consommée par BE3 pour
  ///   l'ordre d'action 1v1 minimal.
  /// [critRatio] - Ratio critique minimal désormais consommé par BE6.
  /// [majorStatusEffect] - Effet `applyStatus` battle minimal réellement
  ///   supporté par BE7 pour `par`, `brn`, `psn`, `tox`.
  /// [selfVolatileStatus] - Volatile auto-appliqué dans le petit sous-ensemble
  ///   BE8 (`protect` uniquement).
  /// [weatherEffect] - Effet météo battle minimal réellement consommé par BE9.
  /// [pseudoWeatherEffect] - Effet pseudoWeather battle minimal réellement
  ///   consommé par BE9.
  /// [setsStealthRock] - H1 ouvre exactement Stealth Rock, et rien de plus,
  ///   comme premier hazard side-level honnête.
  /// [setsSpikes] - H2 ouvre exactement Spikes, et rien de plus, comme second
  ///   slice hazard side-level honnête.
  /// [breaksProtect] - Permet au move de bypasser une protection active BE8.
  /// [requiresRecharge] - Demande un tour de recharge honnête au lanceur après
  ///   une exécution réussie.
  /// [chargeThenStrikeEffect] - Porte le petit contrat local d'un move qui
  ///   charge un tour puis frappe le tour suivant sans repayer les PP.
  /// [selfStatStageChanges] - Boosts / baisses appliqués au lanceur.
  /// [targetStatStageChanges] - Boosts / baisses appliqués à la cible.
  /// [selfStatStageRider] - Rider de stats probabiliste appliqué au lanceur
  ///   après un hit/résolution réussie.
  /// [targetStatStageRider] - Rider de stats probabiliste appliqué à la cible
  ///   après un hit/résolution réussie.
  ///
  /// M8 puis BE1 choisissent volontairement de n'embarquer ici qu'un petit
  /// sous-ensemble :
  /// - dégâts standards ;
  /// - modifications déterministes de stats ;
  /// - transport honnête de quelques dimensions structurantes (`type`,
  ///   `target`, `pp`) pour arrêter leur perte silencieuse au handoff ;
  /// - puis, en BE3, transport et consommation réelle de `priority` pour
  ///   sortir du mensonge "joueur puis ennemi" ;
  /// - puis, en BE4, un vrai hit pipeline minimal avec précision et PP ;
  /// - puis, en BE6, un crit minimal honnête via `critRatio` ;
  /// - puis, en BE7, un petit sous-ensemble `applyStatus` réellement
  ///   exécutable sans ouvrir un système générique de statuts ;
  /// - puis, en BE8, quelques volatiles utiles strictement bornés à
  ///   `Protect`, `requireRecharge`, `chargeThenStrike` et `breakProtect` ;
  /// - puis, en BE9, un tout petit seam de champ pour `rain`, `sandstorm`
  ///   et `trickRoom`, sans ouvrir side/slot/terrain ;
  /// - toujours aucun status non volatil, aucun scheduler générique.
  const BattleMove({
    required this.id,
    required this.name,
    required this.power,
    this.type = 'unknown',
    this.category,
    this.target = BattleMoveTarget.unspecified,
    this.accuracy = const BattleMoveAccuracy.percent(value: 100),
    this.pp = 35,
    int? currentPp,
    this.priority = 0,
    int critRatio = 1,
    this.majorStatusEffect,
    this.selfVolatileStatus,
    this.weatherEffect,
    this.pseudoWeatherEffect,
    this.setsStealthRock = false,
    this.setsSpikes = false,
    this.breaksProtect = false,
    this.requiresRecharge = false,
    this.chargeThenStrikeEffect,
    this.selfStatStageChanges = const <BattleStatStageChange>[],
    this.targetStatStageChanges = const <BattleStatStageChange>[],
    this.selfStatStageRider,
    this.targetStatStageRider,
  })  : assert(
          critRatio >= 1,
          'BattleMove critRatio must be >= 1.',
        ),
        _critRatio = critRatio,
        currentPp = currentPp ?? pp;

  /// L'identifiant canonique de l'attaque.
  final String id;

  /// Le nom affiché de l'attaque.
  final String name;

  /// La puissance de l'attaque (dégâts de base).
  ///
  /// Pour ce MVP enrichi :
  /// - les dégâts standards partent toujours de `power` ;
  /// - des multiplicateurs d'étages de stats peuvent maintenant s'ajouter ;
  /// - un move de statut garde généralement `power == 0`.
  final int power;

  /// Type canonique transporté jusqu'au moteur battle.
  ///
  /// Historique utile :
  /// - BE1 arrête d'abord sa perte silencieuse au bridge ;
  /// - BE5 commence ensuite à le consommer réellement pour STAB,
  ///   effectiveness et immunités ;
  /// - on reste malgré tout très loin d'un système de type Pokémon complet
  ///   (pas d'abilities, pas de Tera, pas d'effets spéciaux de move).
  final String type;

  /// Catégorie battle explicitement résolue par le bridge runtime.
  ///
  /// Compatibilité ascendante :
  /// - les anciens tests/call sites n'avaient que `power` ;
  /// - on garde donc ce champ optionnel ;
  /// - si absent, on déduit une catégorie minimale historique.
  final BattleMoveCategory? category;

  /// Cible battle minimale transportée jusqu'au moteur.
  ///
  /// Le moteur MVP ne l'exécute pas encore activement dans sa résolution :
  /// - le combat reste 1v1 simple actif ;
  /// - mais BE1 arrête au moins de perdre cette information au handoff ;
  /// - les targets incompatibles avec ce petit contrat sont refusés plus tôt
  ///   par le bridge runtime.
  ///
  /// BE9 ajoute `field` pour les moves qui posent une météo ou `Trick Room` :
  /// - ces moves ne visent ni réellement `self`, ni réellement `opponent` ;
  /// - les marquer `unspecified` reperdrait une intention désormais consommée
  ///   par le moteur ;
  /// - on garde malgré tout un targeting battle très petit.
  final BattleMoveTarget target;

  /// Précision réellement consommée par le moteur battle.
  ///
  /// BE4 garde ici un contrat petit mais honnête :
  /// - `alwaysHits` bypasse le hit check ;
  /// - `percent` déclenche un check simple sur 1..100 pour les valeurs
  ///   réellement non triviales ;
  /// - `percent(100)` reste déterministe dans le moteur actuel, car BE4
  ///   n'ouvre toujours ni accuracy stages, ni evasion ;
  /// - pas d'autres couches de précision, pas d'evasion, pas de modificateurs.
  final BattleMoveAccuracy accuracy;

  /// PP maximum du move dans l'état battle.
  ///
  /// `pp` reste le contrat de capacité max du move.
  /// L'état courant vit dans [currentPp].
  ///
  /// Compatibilité volontairement bornée :
  /// - le runtime principal fournit déjà le PP canonique réel ;
  /// - les anciens call sites battle directs omettaient souvent ce champ ;
  /// - on garde donc un défaut pragmatique à 35 pour ne pas transformer BE4
  ///   en migration parasite de tous les setups battle locaux.
  final int pp;

  /// PP courant du move dans l'état battle.
  ///
  /// BE4 ouvre enfin cette donnée parce que :
  /// - les PP cessent d'être décoratifs ;
  /// - le moteur doit pouvoir filtrer les moves inutilisables ;
  /// - un miss consomme quand même 1 PP de façon honnête.
  final int currentPp;

  /// Priorité battle minimale du move.
  ///
  /// BE3 consomme enfin cette donnée pour fermer le trou :
  /// - priorité d'abord ;
  /// - puis vitesse effective ;
  /// - puis tie-break déterministe explicite.
  ///
  /// On garde un défaut à `0` pour préserver les anciens call sites/tests qui
  /// construisent encore des moves battle pauvres à la main.
  final int priority;

  /// Ratio critique minimal transporté jusqu'au moteur battle.
  ///
  /// BE6 choisit ici le plus petit contrat utile :
  /// - on transporte l'entier canonique déjà présent côté runtime ;
  /// - le moteur l'interprète via une table explicite de chances ;
  /// - on n'ouvre pas pour autant les règles Pokémon avancées liées aux crits
  ///   (abilities, items, Focus Energy, Lucky Chant, ignore stages, etc.).
  ///
  /// Valeur neutre :
  /// - `1` signifie le ratio critique standard.
  ///
  /// Garde-fou de mini-fix BE6 :
  /// - ce contrat public reste `const`, donc le garde-fou local le plus petit
  ///   et le plus cohérent ici reste une assertion ;
  /// - BE6-mini-fix-2 verrouille maintenant aussi la classe au niveau langage,
  ///   donc le bypass trivial par override externe disparaît ;
  /// - on ajoute quand même aussi une validation runtime au getter, parce
  ///   qu'un objet battle incohérent peut encore émerger d'un futur mauvais
  ///   refactor interne ou d'un état construit dans cette même librairie ;
  /// - le moteur garde enfin une dernière validation défensive plus loin :
  ///   cette garde n'est plus la preuve principale du contrat public, mais
  ///   une défense en profondeur.
  final int _critRatio;

  int get critRatio {
    if (_critRatio < 1) {
      throw StateError('BattleMove critRatio must be >= 1; got $_critRatio.');
    }
    return _critRatio;
  }

  /// Effet battle minimal de statut majeur transporté par le bridge runtime.
  ///
  /// BE7 garde ce contrat volontairement petit :
  /// - un seul effet de statut majeur par move ;
  /// - pas de payload canonique complet ;
  /// - pas de support des volatiles ;
  /// - pas de targeting générique, car le bridge ne laisse déjà passer que le
  ///   scope `target` honnêtement exécutable aujourd'hui.
  final BattleMoveMajorStatusEffect? majorStatusEffect;

  /// Volatile auto-appliqué par ce move dans le sous-ensemble BE8.
  ///
  /// Ce champ reste volontairement étroit :
  /// - `protect` seulement ;
  /// - pas de confusion, pas de semi-invulnérabilité, pas de framework
  ///   générique de volatiles.
  final BattleVolatileStatusId? selfVolatileStatus;

  /// Météo de champ posée par ce move dans le sous-ensemble BE9.
  ///
  /// Le move porte seulement l'intention de pose :
  /// - la durée et l'état actif vivent dans `BattleFieldState` ;
  /// - `rain` et `sandstorm` sont les seuls IDs réellement supportés ;
  /// - pas de météo avancée, pas d'abilities, pas d'items.
  final BattleWeatherId? weatherEffect;

  /// PseudoWeather de champ posé par ce move dans le sous-ensemble BE9.
  ///
  /// Même frontière que pour [weatherEffect] :
  /// - `trickRoom` seulement ;
  /// - aucun système générique de rooms ;
  /// - la durée et l'expiration vivent dans `BattleFieldState`.
  final BattlePseudoWeatherId? pseudoWeatherEffect;

  /// H1 ouvre uniquement Stealth Rock comme side condition vivante.
  ///
  /// On choisit volontairement un booléen dédié plutôt qu'un faux framework :
  /// - le lot ne supporte qu'une seule mécanique side-level ;
  /// - aucun autre hazard n'entre ici ;
  /// - si de futurs lots H ouvrent autre chose, ils devront le justifier à
  ///   nouveau au lieu de profiter d'un conteneur mort.
  final bool setsStealthRock;

  /// H2 ouvre uniquement `Spikes` comme second slice side-level vivant.
  ///
  /// Même garde-fou que pour H1 :
  /// - ce booléen existe parce qu'il est immédiatement consommé ;
  /// - il ne devient pas un système générique de hazards ;
  /// - si d'autres mécaniques H arrivent, elles devront être justifiées à
  ///   nouveau au lieu de s'installer silencieusement dans une abstraction
  ///   morte.
  final bool setsSpikes;

  /// true si ce move peut percer une protection active BE8.
  ///
  /// Le booléen reste plus honnête qu'une abstraction générique :
  /// - il documente un unique besoin réel du lot ;
  /// - il évite d'ouvrir une taxonomie entière de "modificateurs de défense"
  ///   alors que seul `breakProtect` est réellement exécutable ici.
  final bool breaksProtect;

  /// true si ce move impose ensuite un tour de recharge au lanceur.
  ///
  /// BE8 garde une sémantique locale explicite :
  /// - le move réussi ;
  /// - le combattant marque ensuite un état `mustRecharge` ;
  /// - le tour suivant est perdu honnêtement, puis l'état est nettoyé.
  final bool requiresRecharge;

  /// Petit payload d'un move à charge sur deux tours.
  ///
  /// Si non-null :
  /// - le premier tour ne fait que charger ;
  /// - le second réutilise ce move sans redépenser les PP ;
  /// - le moteur n'ouvre ni raccourci météo, ni Power Herb, ni autres cas
  ///   spéciaux hors scope.
  final BattleChargeThenStrikeEffect? chargeThenStrikeEffect;

  /// Changements d'étages de stats appliqués au lanceur.
  final List<BattleStatStageChange> selfStatStageChanges;

  /// Changements d'étages de stats appliqués à la cible.
  final List<BattleStatStageChange> targetStatStageChanges;

  /// Rider de stats appliqué au lanceur après un hit/résolution réussie.
  final BattleStatStageEffect? selfStatStageRider;

  /// Rider de stats appliqué à la cible après un hit/résolution réussie.
  final BattleStatStageEffect? targetStatStageRider;

  /// true si le move peut encore être tenté honnêtement.
  ///
  /// BE4 n'ouvre toujours pas Struggle :
  /// - un move à `currentPp == 0` n'est donc plus utilisable ;
  /// - `getAvailableChoices()` doit le filtrer ;
  /// - un forçage direct du moteur doit être refusé explicitement.
  bool get hasUsablePp => currentPp > 0;

  /// Catégorie réellement utilisée par le moteur.
  ///
  /// Le bridge runtime fournit maintenant cette info explicitement, mais ce
  /// getter garde une compatibilité honnête avec les anciens setups pauvres :
  /// - `power <= 0` => move de statut ;
  /// - sinon, fallback historique sur "physical".
  BattleMoveCategory get resolvedCategory {
    if (category != null) {
      return category!;
    }
    if (power <= 0) {
      return BattleMoveCategory.status;
    }
    return BattleMoveCategory.physical;
  }

  /// Retourne une copie avec 1 PP consommé.
  ///
  /// Le décrément reste local au move, ce qui évite de réinventer un
  /// conteneur battle parallèle juste pour les PP.
  BattleMove withConsumedPp() {
    return BattleMove(
      id: id,
      name: name,
      power: power,
      type: type,
      category: category,
      target: target,
      accuracy: accuracy,
      pp: pp,
      currentPp: currentPp > 0 ? currentPp - 1 : 0,
      priority: priority,
      critRatio: critRatio,
      majorStatusEffect: majorStatusEffect,
      selfVolatileStatus: selfVolatileStatus,
      weatherEffect: weatherEffect,
      pseudoWeatherEffect: pseudoWeatherEffect,
      setsStealthRock: setsStealthRock,
      setsSpikes: setsSpikes,
      breaksProtect: breaksProtect,
      requiresRecharge: requiresRecharge,
      chargeThenStrikeEffect: chargeThenStrikeEffect,
      selfStatStageChanges: selfStatStageChanges,
      targetStatStageChanges: targetStatStageChanges,
      selfStatStageRider: selfStatStageRider,
      targetStatStageRider: targetStatStageRider,
    );
  }
}
