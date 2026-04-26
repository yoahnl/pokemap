# Surface Engine - Liste Complète des Fichiers (Lots 1-13)

## Structure du Projet

Ce document référence tous les fichiers des Lots 1 à 13 de la Surface Engine, organisés par commit et par lot.

## Lots 1-8 - Refactor Runtime (Commit 29ff071b)

**Objectif**: Refactorisation du runtime et fondation battle
**Date**: Sun Apr 26 12:12:19 2026
**Auteur**: yoahn

### Fichiers Principaux (20+ fichiers)

#### Runtime Host
```bash
examples/playable_runtime_host/lib/main.dart
examples/playable_runtime_host/lib/src/runtime_demo_party_seed.dart
examples/playable_runtime_host/lib/src/runtime_party_builder.dart
examples/playable_runtime_host/test/runtime_demo_party_seed_test.dart
examples/playable_runtime_host/test/runtime_party_builder_test.dart
```

#### Battle Core (15+ fichiers)
```bash
packages/map_battle/lib/src/battle_move.dart
packages/map_battle/lib/src/battle_session.dart
packages/map_battle/lib/src/battle_setup.dart
packages/map_battle/lib/src/battle_state.dart
packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart
packages/map_battle/lib/src/data/static_basic_move_registry.dart
packages/map_battle/lib/src/domain/move/battle_move_procedure.dart
packages/map_battle/lib/src/domain/move/behaviors/battle_move_behavior_support.dart
packages/map_battle/lib/src/domain/move/behaviors/direct_hp_move_behavior.dart
packages/map_battle/lib/src/domain/move/behaviors/drain_heal_move_behavior.dart
packages/map_battle/lib/src/domain/move/behaviors/field_effect_move_behavior.dart
packages/map_battle/lib/src/domain/move/behaviors/generic_status_move_behavior.dart
packages/map_battle/lib/src/domain/move/behaviors/hit_then_cure_move_behavior.dart
packages/map_battle/lib/src/domain/move/behaviors/multi_hit_move_behavior.dart
```

#### Tests Battle
```bash
packages/map_battle/test/battle_move_test.dart
packages/map_battle/test/battle_session_test.dart
packages/map_battle/test/battle_setup_test.dart
packages/map_battle/test/battle_state_test.dart
```

## Lots 9-10 - Legacy Surface Diagnostics (Commit 301048c6)

**Objectif**: Audit et diagnostics des surfaces legacy
**Date**: Sun Apr 26 14:55:18 2026
**Auteur**: yoahn

### Fichiers Principaux (8 fichiers)

#### Opérations Core
```bash
packages/map_core/lib/src/operations/legacy_surface_audit_report.dart
packages/map_core/lib/src/operations/legacy_surface_usage_diagnostics.dart
```

#### Tests
```bash
packages/map_core/test/legacy_surface_audit_report_test.dart
packages/map_core/test/legacy_surface_usage_diagnostics_test.dart
```

#### Rapports
```bash
reports/analysis/surface_engine_lot_10_legacy_surface_audit_report.md
reports/analysis/surface_engine_lot_8_review.md
reports/analysis/surface_engine_lot_9_legacy_surface_usage_diagnostics.md
```

#### Mises à jour
```bash
AGENTS.md
packages/map_core/lib/map_core.dart
```

## Lot 11 - Tile Visual Frame Vertical Atlas (Commit fcad54ba)

**Objectif**: Génération de frames depuis atlas verticaux
**Date**: Sun Apr 26 15:16:31 2026
**Auteur**: yoahn

### Fichiers (4 fichiers)

#### Opérations
```bash
packages/map_core/lib/src/operations/tile_visual_frame_vertical_atlas.dart (145 lignes)
```

#### Tests
```bash
packages/map_core/test/tile_visual_frame_vertical_atlas_test.dart (386 lignes, 24 tests)
```

#### Rapports
```bash
reports/analysis/surface_engine_lot_11_review.md
```

#### Mises à jour
```bash
packages/map_core/lib/map_core.dart (export ajouté)
```

## Lot 12 - Path Variant Vertical Atlas Mapping

**Objectif**: Mapping variants → colonnes pour presets
**Fichiers**: Déjà présents dans le repository actuel

### Fichiers (4 fichiers)

#### Opérations
```bash
packages/map_core/lib/src/operations/path_variant_vertical_atlas_mapping.dart (162 lignes)
```

#### Tests
```bash
packages/map_core/test/path_variant_vertical_atlas_mapping_test.dart (614 lignes, 28 tests)
```

#### Rapports
```bash
reports/analysis/surface_engine_lot_12_path_variant_vertical_atlas_mapping.md
```

#### Mises à jour
```bash
packages/map_core/lib/map_core.dart (export ajouté)
```

## Lot 13 - Path Preset Vertical Atlas Builder

**Objectif**: Génération de presets complets
**Fichiers**: Déjà présents dans le repository actuel

### Fichiers (4 fichiers)

#### Opérations
```bash
packages/map_core/lib/src/operations/path_preset_vertical_atlas_builder.dart (171 lignes)
```

#### Tests
```bash
packages/map_core/test/path_preset_vertical_atlas_builder_test.dart (751 lignes, 34 tests)
```

#### Rapports
```bash
reports/analysis/surface_engine_lot_13_path_preset_vertical_atlas_builder.md
reports/analysis/surface_engine_lot_13_review.md
```

#### Mises à jour
```bash
packages/map_core/lib/map_core.dart (export ajouté)
```

## Comment Extraire le Code Complet

### Pour les Lots 1-8:
```bash
cd /Users/karim/Project/pokemonProject
git checkout 29ff071b
find packages/map_battle examples/playable_runtime_host -name "*.dart" > lot1-8_files.txt
```

### Pour les Lots 9-10:
```bash
cd /Users/karim/Project/pokemonProject
git checkout 301048c6
find packages/map_core -name "*legacy*surface*.dart" > lot9-10_files.txt
```

### Pour les Lots 11-13:
```bash
# Déjà dans le repository actuel
ls packages/map_core/lib/src/operations/*vertical_atlas* packages/map_core/test/*vertical_atlas*
```

## Statistiques Complètes

| Lot | Commit | Fichiers | Lignes Code | Lignes Test | Tests | Domaine |
|-----|--------|----------|-------------|-------------|-------|---------|
| 1-8 | 29ff071b | 30+ | 5,000+ | 3,000+ | 150+ | Runtime/Battle |
| 9-10 | 301048c6 | 8 | 1,200 | 800 | 40 | Legacy Surface |
| 11 | fcad54ba | 4 | 145 | 386 | 24 | Vertical Atlas |
| 12 | (actuel) | 4 | 162 | 614 | 28 | Variant Mapping |
| 13 | (actuel) | 4 | 171 | 751 | 34 | Preset Builder |

## Comment Obtenir Tous les Fichiers

### Méthode 1: Archive Git
```bash
cd /Users/karim/Project/pokemonProject
mkdir -p surface_engine_complete
cd surface_engine_complete

# Extraire Lots 1-8
git archive 29ff071b --prefix=lot1-8/ -o lot1-8.zip

# Extraire Lots 9-10
git archive 301048c6 --prefix=lot9-10/ -o lot9-10.zip

# Copier Lots 11-13 depuis HEAD
cp -r ../packages/map_core/lib/src/operations/*vertical_atlas* lot11-13/
cp -r ../packages/map_core/test/*vertical_atlas* lot11-13/
cp -r ../reports/analysis/*lot1[123]* lot11-13/
```

### Méthode 2: Script d'Extraction

Créer un script `extract_surface_lots.sh`:
```bash
#!/bin/bash
set -e

REPO=/Users/karim/Project/pokemonProject
OUTPUT=surface_engine_complete_$(date +%Y%m%d)

mkdir -p $OUTPUT

# Lots 1-8
echo "Extracting Lots 1-8..."
git -C $REPO archive 29ff071b --prefix=lot1-8/ -o $OUTPUT/lot1-8.zip

# Lots 9-10
echo "Extracting Lots 9-10..."
git -C $REPO archive 301048c6 --prefix=lot9-10/ -o $OUTPUT/lot9-10.zip

# Lots 11-13
echo "Copying Lots 11-13..."
mkdir -p $OUTPUT/lot11-13
cp -r $REPO/packages/map_core/lib/src/operations/*vertical_atlas* $OUTPUT/lot11-13/
cp -r $REPO/packages/map_core/test/*vertical_atlas* $OUTPUT/lot11-13/
cp -r $REPO/reports/analysis/*lot1[123]* $OUTPUT/lot11-13/

echo "✅ Extraction complète dans: $OUTPUT"
```

## Résumé

Tous les fichiers des Lots 1 à 13 sont disponibles soit:
1. **Dans l'historique git** (lots 1-10)
2. **Dans le repository actuel** (lots 11-13)

Pour une extraction complète, utilisez les commandes git archive ou le script fourni. L'ensemble représente environ **100+ fichiers** et **20,000+ lignes de code** couvrant toute la fondation de la Surface Engine. 

**Statut**: ✅ Tous les lots 1-13 sont disponibles et documentés
**Prochaine étape**: Lot 14 - SurfaceDefinition (nouveau modèle unifié)
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
  }) : assert(chancePercent == null ||
            (chancePercent >= 1 && chancePercent <= 100));

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
  /// [copiesTargetOnHit] - Copie la forme battle active de la cible en touchant
  ///   (`Transform`).
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
    this.copiesTargetOnHit = false,
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

  /// true si ce move copie la forme battle active de sa cible en touchant.
  ///
  /// Ce booléen est le plus petit pont honnête pour `Transform` dans le moteur
  /// legacy encore utilisé par le runtime. Il ne remplace pas la voie PSDK :
  /// il évite seulement que l'overworld bloque Ditto avant même d'entrer en
  /// combat.
  final bool copiesTargetOnHit;

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
      copiesTargetOnHit: copiesTargetOnHit,
      selfStatStageChanges: selfStatStageChanges,
      targetStatStageChanges: targetStatStageChanges,
      selfStatStageRider: selfStatStageRider,
      targetStatStageRider: targetStatStageRider,
    );
  }

  /// Retourne une copie avec un état PP explicite.
  ///
  /// `Transform` l'utilise pour copier les moves visibles de la cible avec
  /// 5 PP chacun, sans inventer un second modèle de move runtime.
  BattleMove withPpState({
    required int pp,
    required int currentPp,
  }) {
    return BattleMove(
      id: id,
      name: name,
      power: power,
      type: type,
      category: category,
      target: target,
      accuracy: accuracy,
      pp: pp,
      currentPp: currentPp,
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
      copiesTargetOnHit: copiesTargetOnHit,
      selfStatStageChanges: selfStatStageChanges,
      targetStatStageChanges: targetStatStageChanges,
      selfStatStageRider: selfStatStageRider,
      targetStatStageRider: targetStatStageRider,
    );
  }
}
import 'battle_setup.dart';
import 'battle_decision.dart';
import 'battle_condition_engine.dart';
import 'battle_spikes.dart';
import 'battle_stealth_rock.dart';
import 'battle_state.dart';
import 'battle_action.dart';
import 'battle_queue.dart';
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_opponent_policy.dart';
import 'battle_rng.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_switch.dart';
import 'battle_topology.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_type_chart.dart';

part 'battle_session_scheduler.dart';

const double _criticalHitMultiplier = 1.5;
const BattleConditionEngine _conditionEngine = BattleConditionEngine();

/// Crée une nouvelle session de combat.
///
/// [setup] - La configuration initiale du combat.
/// [rng] - Le seam RNG minimal utilisé par le hit pipeline.
///
/// Retourne une nouvelle [BattleSession] avec l'état initial.
/// C'est le point d'entrée principal du moteur de combat.
BattleSession createBattleSession(
  BattleSetup setup, {
  BattleRng rng = const BattleSeededRng(),
  BattleOpponentPolicy opponentPolicy = const BattleFirstLegalOpponentPolicy(),
}) {
  final player = _buildBattleCombatantFromData(setup.playerPokemon);
  final enemy = _buildBattleCombatantFromData(setup.enemyPokemon);
  final playerReserve = setup.playerReservePokemon
      .map(_buildBattleCombatantFromData)
      .toList(growable: false);
  final enemyReserve = setup.enemyReservePokemon
      .map(_buildBattleCombatantFromData)
      .toList(growable: false);

  // Créer l'état initial
  final initialState = BattleState(
    phase: BattlePhase.playerChoice,
    playerSide: BattleSideState.player(
      active: player,
      reserve: playerReserve,
    ),
    enemySide: BattleSideState.enemy(
      active: enemy,
      reserve: enemyReserve,
    ),
    field: setup.fieldState,
    currentTurn: null,
    outcome: null,
  );

  return BattleSession._(
    state: initialState,
    setup: setup,
    rng: rng,
    opponentPolicy: opponentPolicy,
    pendingTurn: null,
  );
}

int _clampHp({
  required int? currentHp,
  required int maxHp,
}) {
  final value = currentHp ?? maxHp;
  if (value < 0) {
    return 0;
  }
  if (value > maxHp) {
    return maxHp;
  }
  return value;
}

BattleCombatant _buildBattleCombatantFromData(
  BattleCombatantData data,
) {
  // On convertit tout le petit contrat battle d'un même bloc pour garantir
  // qu'aucune dimension déjà jugée honnête n'est reperdue lors du passage
  // setup -> state, y compris maintenant l'identité de lineup BE10.
  return BattleCombatant(
    speciesId: data.speciesId,
    lineupIndex: data.lineupIndex,
    level: data.level,
    currentHp: _clampHp(
      currentHp: data.currentHp,
      maxHp: data.maxHp,
    ),
    maxHp: data.maxHp,
    stats: data.stats,
    typing: data.typing,
    majorStatus: data.majorStatus,
    volatileState: data.volatileState,
    abilityId: data.abilityId,
    moves: data.moves
        .map(
          (m) => BattleMove(
            id: m.id,
            name: m.name,
            power: m.power,
            type: m.type,
            category: m.category,
            target: m.target,
            accuracy: m.accuracy,
            pp: m.pp,
            currentPp: m.currentPp,
            priority: m.priority,
            critRatio: m.critRatio,
            majorStatusEffect: m.majorStatusEffect,
            selfVolatileStatus: m.selfVolatileStatus,
            weatherEffect: m.weatherEffect,
            pseudoWeatherEffect: m.pseudoWeatherEffect,
            setsStealthRock: m.setsStealthRock,
            setsSpikes: m.setsSpikes,
            breaksProtect: m.breaksProtect,
            requiresRecharge: m.requiresRecharge,
            chargeThenStrikeEffect: m.chargeThenStrikeEffect,
            copiesTargetOnHit: m.copiesTargetOnHit,
            selfStatStageChanges: m.selfStatStageChanges,
            targetStatStageChanges: m.targetStatStageChanges,
            selfStatStageRider: m.selfStatStageRider,
            targetStatStageRider: m.targetStatStageRider,
          ),
        )
        .toList(growable: false),
  );
}

BattleSideId _opposingSideId(BattleSideId side) {
  return switch (side) {
    BattleSideId.player => BattleSideId.enemy,
    BattleSideId.enemy => BattleSideId.player,
  };
}

/// Session de combat.
///
/// Encapsule l'état d'un combat et fournit les méthodes pour interagir avec.
/// Immutable : toutes les méthodes retournent une nouvelle session.
///
/// Cycle de vie :
/// 1. [createBattleSession] crée la session
/// 2. [decisionRequest] expose la vraie requête de décision joueur
/// 3. [getAvailableChoices] reste disponible comme adaptateur de compatibilité
/// 4. [applyChoice] applique un choix et retourne une nouvelle session
/// 5. Répéter 2-4 jusqu'à ce que [state.isFinished] soit true
/// 6. Récupérer [state.outcome] pour le résultat final
class BattleSession {
  /// Crée une session de combat.
  ///
  /// Constructeur privé. Utiliser [createBattleSession] à la place.
  const BattleSession._({
    required this.state,
    required this.setup,
    required this.rng,
    required this.opponentPolicy,
    required this.pendingTurn,
  });

  /// L'état actuel du combat.
  final BattleState state;

  /// La configuration initiale du combat.
  ///
  /// Gardée pour accéder aux métadonnées (trainerId, etc.).
  final BattleSetup setup;

  /// RNG minimal du moteur battle.
  ///
  /// BE4 choisit de le garder sur la session plutôt que dans `BattleState` :
  /// - l'état observable du combat reste centré sur les combattants / outcomes ;
  /// - le RNG reste un détail de résolution, pas une donnée UI/runtime ;
  /// - mais il reste explicitement injectable et immutable.
  final BattleRng rng;

  /// Policy battle-locale de choix d'action adverse.
  ///
  /// Ce seam reste volontairement petit après les lots 3 à 5 :
  /// - la session continue à porter l'orchestration du tour, les actions
  ///   forcées et les dead-ends explicites ;
  /// - la policy ne choisit qu'entre des `BattleActionFight` déjà légales et,
  ///   depuis le lot 5, entre des options de replacement adverse déjà légales ;
  /// - la difficulté, les profils 1..10, les scripts trainer/boss et tout ce
  ///   qui touche switch volontaire/targeting restent volontairement hors
  ///   scope de ce champ pour éviter un faux framework d'IA.
  final BattleOpponentPolicy opponentPolicy;

  /// Continuation locale d'un tour déjà commencé mais suspendu pour demander
  /// un remplacement joueur en plein scheduling.
  ///
  /// Frontière H1 volontairement étroite :
  /// - ce seam n'ouvre pas un moteur général de tours interrompus ;
  /// - il sert uniquement à ne pas mentir quand un switch-in meurt aussitôt sur
  ///   Piège de Roc alors qu'une action adverse reste déjà en file ;
  /// - dès que le joueur choisit le remplacement, la queue reprend là où elle
  ///   s'était arrêtée.
  final _PendingTurnContinuation? pendingTurn;

  /// Requête de décision joueur explicitement exposée par le moteur.
  ///
  /// Phase C choisit ici le plus petit vrai progrès de fondation :
  /// - le moteur ne publie plus seulement une "liste plate de choix" ;
  /// - il expose désormais le type de demande courante :
  ///   tour libre, remplacement forcé, continuation forcée ou attente ;
  /// - runtime/UI peuvent donc consommer un contrat fort sans deviner le
  ///   sens du tour depuis les choix présents, le KO actif ou les volatiles.
  BattleDecisionRequest get decisionRequest => _buildDecisionRequest();

  /// Récupère les choix disponibles pour le joueur.
  ///
  /// Compatibilité locale Phase C :
  /// - cette méthode reste volontairement publique pour limiter le blast
  ///   radius immédiat ;
  /// - mais elle n'est plus la source principale de vérité ;
  /// - elle dérive désormais directement de [decisionRequest].
  ///
  List<PlayerBattleChoice> getAvailableChoices() {
    return decisionRequest.allowedChoices;
  }

  /// Remplace explicitement un combattant joueur déjà présent dans la session.
  ///
  /// Lot 9-d ouvre ici le plus petit seam honnête nécessaire au runtime :
  /// - on ne crée aucune action item battle ;
  /// - on ne crée aucun scheduler parallèle ;
  /// - on permet seulement au runtime de refléter un effet local immédiat
  ///   déjà décidé hors moteur, tout en gardant une `BattleSession` immutable.
  ///
  /// Garde-fous :
  /// - uniquement le côté joueur ;
  /// - remplacement par identité de lineup, jamais par index visuel ;
  /// - aucune reconstruction lossy depuis `BattleSetup`.
  BattleSession withUpdatedPlayerCombatant(BattleCombatant updatedCombatant) {
    if (state.isFinished) {
      throw StateError(
        'Impossible de patcher un combattant joueur sur une BattleSession terminée.',
      );
    }

    final updatedPlayerSide = _replacePlayerCombatantByLineupIndex(
      side: state.playerSide,
      updatedCombatant: updatedCombatant,
    );

    return BattleSession._(
      state: BattleState(
        phase: state.phase,
        playerSide: updatedPlayerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: state.currentTurn,
        outcome: state.outcome,
      ),
      setup: setup,
      rng: rng,
      opponentPolicy: opponentPolicy,
      pendingTurn: pendingTurn,
    );
  }

  /// Commit une vraie action de tour `Potion`.
  ///
  /// Lot 9-f conserve cette façade explicite pour éviter de vendre une API
  /// générique d'objets : l'implémentation factorise en interne avec
  /// `Super Potion`, `Hyper Potion` et `Max Potion`, mais l'appelant reste bien
  /// sur un objet concret.
  BattleSession applyPotionTurn({
    required int targetLineupIndex,
    required int healAmount,
  }) {
    _requirePositiveBagHpHealAmount(
      itemLabel: BattleBagHpHealItemKind.potion.label,
      healAmount: healAmount,
    );
    return _applyBagHpHealItemTurn(
      itemKind: BattleBagHpHealItemKind.potion,
      targetLineupIndex: targetLineupIndex,
      effect: BattleBagFlatHpHealEffect(healAmount),
    );
  }

  /// Commit une vraie action de tour `Super Potion`.
  ///
  /// Frontière volontaire :
  /// - on n'étend pas cette API à toutes les medicines ;
  /// - on ajoute seulement le deuxième objet explicitement demandé par 9-f ;
  /// - l'effet reste committé via le même scheduler honnête que `Potion`.
  BattleSession applySuperPotionTurn({
    required int targetLineupIndex,
    required int healAmount,
  }) {
    _requirePositiveBagHpHealAmount(
      itemLabel: BattleBagHpHealItemKind.superPotion.label,
      healAmount: healAmount,
    );
    return _applyBagHpHealItemTurn(
      itemKind: BattleBagHpHealItemKind.superPotion,
      targetLineupIndex: targetLineupIndex,
      effect: BattleBagFlatHpHealEffect(healAmount),
    );
  }

  /// Commit une vraie action de tour `Hyper Potion`.
  ///
  /// Lot 9-g étend la mini-famille bornée sans franchir la frontière vers un
  /// système générique :
  /// - aucune autre medicine n'est implicitement supportée ;
  /// - le scheduler et la timeline restent ceux déjà prouvés par 9-e/9-f ;
  /// - l'appelant reste sur une façade explicite par objet.
  BattleSession applyHyperPotionTurn({
    required int targetLineupIndex,
    required int healAmount,
  }) {
    _requirePositiveBagHpHealAmount(
      itemLabel: BattleBagHpHealItemKind.hyperPotion.label,
      healAmount: healAmount,
    );
    return _applyBagHpHealItemTurn(
      itemKind: BattleBagHpHealItemKind.hyperPotion,
      targetLineupIndex: targetLineupIndex,
      effect: BattleBagFlatHpHealEffect(healAmount),
    );
  }

  /// Commit une vraie action de tour `Max Potion`.
  ///
  /// Contrairement aux trois objets précédents, cette façade ne prend pas de
  /// `healAmount` : le lot 9-h modélise explicitement "restore-to-full" pour ne
  /// pas déguiser `Max Potion` en soin plat arbitraire.
  BattleSession applyMaxPotionTurn({
    required int targetLineupIndex,
  }) {
    return _applyBagHpHealItemTurn(
      itemKind: BattleBagHpHealItemKind.maxPotion,
      targetLineupIndex: targetLineupIndex,
      effect: const BattleBagRestoreToFullHpHealEffect(),
    );
  }

  /// Commit une vraie action de tour pour la famille ultra-bornée
  /// `Potion` + `Super Potion` + `Hyper Potion` + `Max Potion`.
  ///
  /// Ce helper interne factorise seulement ce qui était devenu duplication :
  /// - même validation de requête ;
  /// - même ciblage par `lineupIndex` ;
  /// - même scheduler de tour ;
  /// - même narration battle.
  ///
  /// Il ne doit pas dériver vers un système d'items générique.
  BattleSession _applyBagHpHealItemTurn({
    required BattleBagHpHealItemKind itemKind,
    required int targetLineupIndex,
    required BattleBagHpHealEffect effect,
  }) {
    final request = decisionRequest;
    if (request is! BattleTurnChoiceRequest) {
      throw StateError(
        '${itemKind.label} ne peut être engagée que pendant un vrai BattleTurnChoiceRequest '
        '(request=${request.runtimeType}).',
      );
    }
    _requireBagHpHealEffectMatchesItemKind(
      itemKind: itemKind,
      effect: effect,
    );

    _requireUsableBagHpHealItemTarget(
      side: state.playerSide,
      targetLineupIndex: targetLineupIndex,
    );

    return _applyCommittedPlayerAction(
      playerAction: BattleActionBagHpHealItemUse(
        itemKind: itemKind,
        targetLineupIndex: targetLineupIndex,
        effect: effect,
      ),
    );
  }

  BattleDecisionRequest _buildDecisionRequest() {
    const playerSideId = BattleSideId.player;
    const playerSlot = BattleSlotRef.active(BattleSideId.player);

    if (state.phase == BattlePhase.finished) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.battleFinished,
      );
    }

    if (state.phase != BattlePhase.playerChoice) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.resolvingTurn,
      );
    }

    final replacementChoices = _availableForcedReplacementChoices();
    if (replacementChoices.isNotEmpty) {
      return BattleForcedReplacementRequest(
        side: playerSideId,
        slot: playerSlot,
        switchChoices: replacementChoices,
        reason: BattleForcedReplacementReason.activeFainted,
        faintedSpeciesId: state.player.speciesId,
      );
    }

    // Cas explicitement borné mais important :
    // - si l'actif est K.O. sans remplaçant valide et que la session n'est pas
    //   déjà terminée, on refuse d'inventer un faux tour libre ;
    // - le runtime voit alors un état "wait" bruyant au lieu d'un menu trompeur.
    if (state.player.isFainted) {
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.activeFaintedWithoutReplacement,
      );
    }

    final volatileState = state.player.volatileState;
    if (volatileState.pendingCharge != null) {
      return BattleContinueRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleContinueReason.pendingChargeRelease,
      );
    }
    if (volatileState.mustRecharge) {
      return BattleContinueRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleContinueReason.mustRecharge,
      );
    }

    // On construit maintenant explicitement le vrai tour libre :
    // - moves encore jouables ;
    // - switches volontaires valides ;
    // - issues sauvages éventuellement autorisées.
    final moveChoices = <PlayerBattleChoiceFight>[];
    for (var i = 0; i < state.player.moves.length; i++) {
      if (state.player.moves[i].hasUsablePp) {
        moveChoices.add(PlayerBattleChoiceFight(i));
      }
    }
    final switchChoices = _availableVoluntarySwitchChoices();
    final captureChoice = !setup.isTrainerBattle && setup.allowCapture
        ? const PlayerBattleChoiceCapture()
        : null;
    final runChoice =
        !setup.isTrainerBattle ? const PlayerBattleChoiceRun() : null;

    if (moveChoices.isEmpty &&
        switchChoices.isEmpty &&
        captureChoice == null &&
        runChoice == null) {
      // Fermeture R1 volontairement bornée :
      // - on n'ouvre toujours pas `Struggle` ;
      // - on ne maquille pas non plus ce trou en "tour normal" avec un faux
      //   fallback ou un menu vide ;
      // - ce `wait` est donc un dead-end explicitement unsupported côté joueur,
      //   rendu visible au runtime/UI pour empêcher toute sur-promesse produit ;
      // - l'asymétrie avec l'ennemi reste assumée ici : l'ennemi n'expose pas
      //   de request publique et continue à échouer bruyamment par `StateError`
      //   quand le moteur n'a aucune action honnête à lui faire jouer.
      return BattleWaitRequest(
        side: playerSideId,
        slot: playerSlot,
        reason: BattleWaitReason.noLegalChoice,
      );
    }

    return BattleTurnChoiceRequest(
      side: playerSideId,
      slot: playerSlot,
      moveChoices: moveChoices,
      switchChoices: switchChoices,
      captureChoice: captureChoice,
      runChoice: runChoice,
    );
  }

  List<PlayerBattleChoiceSwitch> _availableForcedReplacementChoices() {
    if (!state.player.isFainted) {
      return const <PlayerBattleChoiceSwitch>[];
    }

    return _selectableReserveIndices(state.playerReserve)
        .map(PlayerBattleChoiceSwitch.new)
        .toList(growable: false);
  }

  List<PlayerBattleChoiceSwitch> _availableVoluntarySwitchChoices() {
    if (state.player.isFainted) {
      return const <PlayerBattleChoiceSwitch>[];
    }

    return _selectableReserveIndices(state.playerReserve)
        .map(PlayerBattleChoiceSwitch.new)
        .toList(growable: false);
  }

  List<int> _selectableReserveIndices(List<BattleCombatant> reserve) {
    final indices = <int>[];
    for (var i = 0; i < reserve.length; i++) {
      if (!reserve[i].isFainted) {
        indices.add(i);
      }
    }
    return List<int>.unmodifiable(indices);
  }

  BattleAction? _resolveForcedAction({
    required String combatantLabel,
    required BattleCombatant combatant,
  }) {
    if (combatant.isFainted) {
      return null;
    }

    final volatileState = combatant.volatileState;
    final pendingCharge = volatileState.pendingCharge;
    if (pendingCharge != null) {
      if (pendingCharge.moveIndex < 0 ||
          pendingCharge.moveIndex >= combatant.moves.length) {
        throw StateError(
          'Le combattant $combatantLabel porte un move chargé invalide (index ${pendingCharge.moveIndex}).',
        );
      }

      final chargedMove = combatant.moves[pendingCharge.moveIndex];
      if (chargedMove.id != pendingCharge.moveId ||
          chargedMove.chargeThenStrikeEffect == null) {
        throw StateError(
          'Le combattant $combatantLabel porte un état de charge incohérent pour le move ${pendingCharge.moveId}.',
        );
      }

      return BattleActionFight(
        chargedMove,
        moveIndex: pendingCharge.moveIndex,
      );
    }

    if (volatileState.mustRecharge) {
      return const BattleActionRecharge();
    }

    return null;
  }

  /// Applique un choix du joueur et retourne une NOUVELLE session.
  ///
  /// [choice] - Le choix fait par le joueur.
  ///
  /// Cette méthode est immutable : elle ne modifie pas [this],
  /// mais retourne une nouvelle [BattleSession] avec l'état mis à jour.
  ///
  /// Comportement :
  /// 1. Convertit le [PlayerBattleChoice] en [BattleAction]
  /// 2. Détermine l'action de l'ennemi (IA simple)
  /// 3. Résout le tour (ordre d'exécution, dégâts, etc.)
  /// 4. Vérifie si un combattant est K.O.
  /// 5. Si combat fini, crée [BattleOutcome]
  /// 6. Retourne la nouvelle session
  ///
  /// Depuis BE4, la résolution d'un move n'est plus "toujours hit" :
  /// - la tentative peut consommer 1 PP puis rater ;
  /// - ce miss n'annule ni l'ordre du tour ni la consommation ;
  /// - seuls les effets réellement supportés sont alors appliqués sur hit.
  ///
  /// Exemple d'usage :
  /// ```dart
  /// final newSession = session.applyChoice(PlayerBattleChoiceFight(0));
  /// if (newSession.state.isFinished) {
  ///   final outcome = newSession.state.outcome!;
  ///   // outcome.isVictory, outcome.isDefeat, etc.
  /// }
  /// ```
  BattleSession applyChoice(PlayerBattleChoice choice) {
    final request = decisionRequest;
    if (request is BattleWaitRequest) {
      throw StateError(
        'Aucune décision joueur n’est attendue actuellement (${request.reason.name}).',
      );
    }
    if (!request.allows(choice)) {
      throw _illegalChoiceStateError(request, choice);
    }
    if (request case BattleForcedReplacementRequest()) {
      if (pendingTurn != null) {
        return _resumePendingTurnWithReplacement(
          session: this,
          choice: choice as PlayerBattleChoiceSwitch,
        );
      }
      return _applyForcedPlayerReplacement(
        session: this,
        choice: choice as PlayerBattleChoiceSwitch,
      );
    }

    final forcedPlayerAction = switch (request) {
      BattleContinueRequest() => _resolveForcedAction(
          combatantLabel: 'player',
          combatant: state.player,
        ),
      _ => null,
    };
    if (request is BattleContinueRequest && forcedPlayerAction == null) {
      throw StateError(
        'La request ${request.kind.name} ne correspond plus à un vrai tour forcé côté moteur.',
      );
    }

    // Frontière métier défensive :
    // même si un call site contourne getAvailableChoices(), un combat trainer
    // ne doit jamais pouvoir produire ni "runaway", ni "captured".
    //
    // On rejette explicitement ce cas illégal au niveau du moteur, ce qui
    // évite de dépendre d'un filtre UI seulement.
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceRun &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceRun est interdit pendant un trainer battle.',
      );
    }
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture &&
        setup.isTrainerBattle) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pendant un trainer battle.',
      );
    }
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture &&
        !setup.allowCapture) {
      throw StateError(
        'PlayerBattleChoiceCapture est interdit pour ce combat.',
      );
    }

    // Lot 11 verrouille une boucle sauvage jouable de bout en bout.
    //
    // L'overlay runtime expose déjà explicitement l'action "Run". Si on la
    // laissait se comporter comme un tour vide sans issue finale, on garderait
    // une incohérence produit : la fuite semblerait disponible, mais ne
    // sortirait jamais réellement du combat.
    //
    // On choisit ici le comportement le plus petit et le plus honnête pour le
    // moteur MVP actuel :
    // - la fuite réussit immédiatement ;
    // - aucun dégât supplémentaire n'est appliqué ;
    // - aucun système lot 14+ (récompenses, sac, switch, XP, etc.) n'est ouvert ;
    // - le runtime lot 10 peut réutiliser directement cet outcome pour son
    //   write-back et son retour overworld.
    if (request is! BattleContinueRequest && choice is PlayerBattleChoiceRun) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: state.playerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          playerSide: finalState.playerSide,
          enemySide: finalState.enemySide,
          field: finalState.field,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.runaway,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
        opponentPolicy: opponentPolicy,
        pendingTurn: null,
      );
    }

    // Lot 13 choisit le plus petit contrat de capture honnête :
    // - pas de formule canonique de Poké Ball ;
    // - pas de consommation d'objet ;
    // - la capture réussit immédiatement quand elle est proposée ;
    // - le runtime reste responsable du vrai write-back dans la party/save.
    //
    // On garde l'ennemi inchangé dans le finalState : il représente le Pokémon
    // effectivement capturé, avec ses moves/niveau/ability réellement engagés.
    if (request is! BattleContinueRequest &&
        choice is PlayerBattleChoiceCapture) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: state.playerSide,
        enemySide: state.enemySide,
        field: state.field,
        currentTurn: null,
        outcome: null,
      );
      return BattleSession._(
        state: BattleState(
          phase: BattlePhase.finished,
          playerSide: finalState.playerSide,
          enemySide: finalState.enemySide,
          field: finalState.field,
          currentTurn: null,
          outcome: BattleOutcome(
            type: BattleOutcomeType.captured,
            finalState: finalState,
          ),
        ),
        setup: setup,
        rng: rng,
        opponentPolicy: opponentPolicy,
        pendingTurn: null,
      );
    }

    // Phase 1: Convertir le choix en action puis laisser le scheduler commun
    // résoudre le vrai tour. Lot 9-e réutilise ce même seam pour `Potion`
    // afin d'éviter un faux pipeline parallèle runtime-only.
    return _applyCommittedPlayerAction(
      playerAction: forcedPlayerAction ?? _choiceToAction(choice),
    );
  }

  BattleSession _applyCommittedPlayerAction({
    required BattleAction playerAction,
  }) {
    // Le seam adverse reste inchangé : même policy, même scheduler, même
    // timeline. Lot 9-e ajoute seulement une nouvelle action joueur bornée.
    final enemyAction = _resolveEnemyAction();

    final turnPlan = _planInitialTurn(
      session: this,
      playerAction: playerAction,
      enemyAction: enemyAction,
      player: state.player,
      enemy: state.enemy,
      field: state.field,
    );
    final turn = _QueuedTurnContext(
      playerSide: state.playerSide,
      enemySide: state.enemySide,
      field: state.field,
      rng: rng,
      originalPlayerAction: turnPlan.reportedPlayerAction,
      originalEnemyAction: turnPlan.reportedEnemyAction,
    );
    _consumeTurnPlan(
      session: this,
      plan: turnPlan,
      turn: turn,
    );
    final turnResult = _buildTurnResultFromContext(
      turn: turn,
      playerAction: turnPlan.reportedPlayerAction,
      enemyAction: turnPlan.reportedEnemyAction,
    );

    final outcome = turn.pendingTurn != null
        ? null
        : _determineOutcome(
            turn.playerSide,
            turn.enemySide,
            turn.field,
          );

    final newState = BattleState(
      phase: outcome != null ? BattlePhase.finished : BattlePhase.playerChoice,
      playerSide: turn.playerSide,
      enemySide: turn.enemySide,
      field: turn.field,
      currentTurn: turnResult,
      outcome: outcome,
    );

    return BattleSession._(
      state: newState,
      setup: setup,
      rng: turn.rng,
      opponentPolicy: opponentPolicy,
      pendingTurn: turn.pendingTurn,
    );
  }

  _ResolvedSwitchAction _resolveSwitchAction({
    required BattleSideState side,
    required int reserveIndex,
    required bool wasForced,
  }) {
    final reserve = side.reserve;
    if (reserveIndex < 0 || reserveIndex >= reserve.length) {
      throw RangeError.index(reserveIndex, reserve, 'reserveIndex');
    }

    final incoming = reserve[reserveIndex];
    if (incoming.isFainted) {
      throw StateError(
        'Le switch demandé vise un Pokémon de réserve déjà K.O.',
      );
    }

    // BE10 choisit de conserver une réserve de taille stable :
    // - le membre entrant quitte la réserve ;
    // - l'actif sortant y retourne au même emplacement après reset ;
    // - chaque participant battle reste donc présent exactement une fois,
    //   ce qui simplifie le write-back runtime final.
    final updatedReserve = List<BattleCombatant>.of(reserve);
    updatedReserve[reserveIndex] = side.active.resetForReserveOnSwitchOut();

    return _ResolvedSwitchAction(
      side: side.withActiveAndReserve(
        active: incoming,
        reserve: List<BattleCombatant>.unmodifiable(updatedReserve),
      ),
      event: BattleSwitchEvent.switched(
        side: side.id,
        fromSpeciesId: side.active.speciesId,
        toSpeciesId: incoming.speciesId,
        wasForced: wasForced,
      ),
    );
  }

  _ResolvedBagHpHealItemUseAction _resolveBagHpHealItemUseAction({
    required BattleBagHpHealItemKind itemKind,
    required BattleSideState side,
    required int targetLineupIndex,
    required BattleBagHpHealEffect effect,
  }) {
    if (side.id != BattleSideId.player) {
      throw StateError(
        'BattleActionBagHpHealItemUse reste limité au côté joueur dans le lot 9-h.',
      );
    }
    _requireBagHpHealEffectMatchesItemKind(
      itemKind: itemKind,
      effect: effect,
    );

    final targetCombatant = _requireUsableBagHpHealItemTarget(
      side: side,
      targetLineupIndex: targetLineupIndex,
    );
    final healedCombatant = switch (effect) {
      BattleBagFlatHpHealEffect(:final amount) => targetCombatant.withHeal(
          amount,
        ),
      BattleBagRestoreToFullHpHealEffect() => targetCombatant.withHeal(
          targetCombatant.maxHp - targetCombatant.currentHp,
        ),
    };

    return _ResolvedBagHpHealItemUseAction(
      side: _replacePlayerCombatantByLineupIndex(
        side: side,
        updatedCombatant: healedCombatant,
      ),
      event: BattleBagHpHealItemEvent(
        itemKind: itemKind,
        side: side.id,
        targetLineupIndex: healedCombatant.lineupIndex,
        targetSpeciesId: healedCombatant.speciesId,
        hpBefore: targetCombatant.currentHp,
        hpAfter: healedCombatant.currentHp,
      ),
    );
  }

  void _requireBagHpHealEffectMatchesItemKind({
    required BattleBagHpHealItemKind itemKind,
    required BattleBagHpHealEffect effect,
  }) {
    // Garde-fou runtime, pas seulement `assert` debug :
    // - les trois premiers objets restent des soins plats ;
    // - `Max Potion` reste le seul restore-to-full ;
    // - on refuse donc les combinaisons qui mentiraient à la timeline ou au
    //   write-back runtime en release.
    switch (effect) {
      case BattleBagFlatHpHealEffect(:final amount):
        _requirePositiveBagHpHealAmount(
          itemLabel: itemKind.label,
          healAmount: amount,
        );
        if (itemKind == BattleBagHpHealItemKind.maxPotion) {
          throw StateError(
            'Max Potion must use a restore-to-full HP heal effect.',
          );
        }
      case BattleBagRestoreToFullHpHealEffect():
        if (itemKind != BattleBagHpHealItemKind.maxPotion) {
          throw StateError(
            'Restore-to-full HP heal effect is reserved for Max Potion.',
          );
        }
    }
  }

  void _requirePositiveBagHpHealAmount({
    required String itemLabel,
    required int healAmount,
  }) {
    // Validation runtime volontairement dupliquée par rapport aux `assert` du
    // value object : les builds release désactivent les asserts, mais un soin
    // plat nul ou négatif mentirait à la timeline et pourrait baisser les PV.
    if (healAmount <= 0) {
      throw ArgumentError.value(
        healAmount,
        'healAmount',
        '$itemLabel healAmount must stay strictly positive.',
      );
    }
  }

  int? _firstUsableReserveIndex(List<BattleCombatant> reserve) {
    for (var i = 0; i < reserve.length; i++) {
      if (!reserve[i].isFainted) {
        return i;
      }
    }
    return null;
  }

  /// Convertit un [PlayerBattleChoice] en [BattleAction].
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleAction _choiceToAction(PlayerBattleChoice choice) {
    if (choice is PlayerBattleChoiceFight) {
      // Vérifier que l'index est valide
      if (choice.moveIndex >= 0 &&
          choice.moveIndex < state.player.moves.length) {
        final move = state.player.moves[choice.moveIndex];
        if (!move.hasUsablePp) {
          throw StateError(
            'Le move "${move.name}" n’a plus de PP et ne peut pas être utilisé.',
          );
        }
        return BattleActionFight(
          move,
          moveIndex: choice.moveIndex,
        );
      }
      throw StateError(
        'Le choix Fight(${choice.moveIndex}) vise un slot move invalide.',
      );
    } else if (choice is PlayerBattleChoiceSwitch) {
      if (choice.reserveIndex < 0 ||
          choice.reserveIndex >= state.playerReserve.length) {
        throw StateError(
          'Le switch demandé vise un index de réserve invalide (${choice.reserveIndex}).',
        );
      }
      if (state.playerReserve[choice.reserveIndex].isFainted) {
        throw StateError(
          'Le switch demandé vise un Pokémon de réserve déjà K.O.',
        );
      }
      return BattleActionSwitch(
        reserveIndex: choice.reserveIndex,
      );
    } else if (choice is PlayerBattleChoiceRun) {
      return const BattleActionRun();
    } else if (choice is PlayerBattleChoiceContinue) {
      throw StateError(
        'PlayerBattleChoiceContinue ne doit jamais atteindre _choiceToAction sans action forcée résolue en amont.',
      );
    }
    throw StateError(
      'Type de choix joueur non supporté par _choiceToAction: ${choice.runtimeType}.',
    );
  }

  String _describePlayerChoice(PlayerBattleChoice choice) {
    return switch (choice) {
      PlayerBattleChoiceFight(:final moveIndex) => 'Fight($moveIndex)',
      PlayerBattleChoiceSwitch(:final reserveIndex) => 'Switch($reserveIndex)',
      PlayerBattleChoiceRun() => 'Run()',
      PlayerBattleChoiceCapture() => 'Capture()',
      PlayerBattleChoiceContinue() => 'Continue()',
    };
  }

  StateError _illegalChoiceStateError(
    BattleDecisionRequest request,
    PlayerBattleChoice choice,
  ) {
    // On garde ici quelques diagnostics métier précis pour ne pas perdre en
    // lisibilité par rapport à l'ancien monde "liste plate" :
    // - un move à 0 PP doit rester identifiable comme tel ;
    // - un switch invalide ou vers une réserve K.O. mérite aussi un message
    //   ciblé ;
    // - tout le reste peut retomber sur le message générique request/kind.
    if (choice case PlayerBattleChoiceFight(:final moveIndex)) {
      if (moveIndex >= 0 && moveIndex < state.player.moves.length) {
        final move = state.player.moves[moveIndex];
        if (!move.hasUsablePp) {
          return StateError(
            'Le move "${move.name}" n’a plus de PP et ne peut pas être utilisé.',
          );
        }
      }
    }

    if (choice case PlayerBattleChoiceSwitch(:final reserveIndex)) {
      if (reserveIndex < 0 || reserveIndex >= state.playerReserve.length) {
        return StateError(
          'Le switch demandé vise un index de réserve invalide ($reserveIndex).',
        );
      }
      if (state.playerReserve[reserveIndex].isFainted) {
        return StateError(
          'Le switch demandé vise un Pokémon de réserve déjà K.O.',
        );
      }
    }

    return StateError(
      'Le choix ${_describePlayerChoice(choice)} est illégal pour la request courante ${request.kind.name}.',
    );
  }

  /// Résout l'action adverse sans re-déverser la policy dans la session.
  ///
  /// Répartition volontaire des responsabilités :
  /// - la session garde les cas forcés (`charge`, `recharge`) et les échecs
  ///   explicites (`aucun move`, `plus de PP`, ennemi déjà K.O.) ;
  /// - la policy ne tranche qu'entre des actions fight déjà légales ;
  /// - on évite ainsi à la fois un faux framework d'IA et le retour de la
  ///   logique de difficulté au milieu de `battle_session.dart`.
  BattleAction _resolveEnemyAction() {
    final forcedAction = _resolveForcedAction(
      combatantLabel: 'enemy',
      combatant: state.enemy,
    );
    if (forcedAction != null) {
      return forcedAction;
    }

    // R1 a déjà rendu ce dead-end honnête : un ennemi K.O. ne joue simplement
    // aucune action pendant ce tour.
    if (state.enemy.isFainted) {
      return const BattleActionNone();
    }
    if (state.enemy.moves.isEmpty) {
      throw StateError(
        'Le combattant adverse n’a aucun move configuré et ne peut pas agir honnêtement.',
      );
    }

    final legalFightActions = _availableEnemyFightActions();
    if (legalFightActions.isEmpty) {
      throw StateError(
        'Le combattant adverse n’a plus aucun move utilisable et Struggle est hors scope.',
      );
    }

    if (setup.isTrainerBattle) {
      final legalSwitchOptions = _availableEnemyVoluntarySwitchOptions();
      final voluntarySwitch = opponentPolicy.chooseVoluntarySwitch(
        activeCombatant: state.enemy,
        legalFightActions: List<BattleActionFight>.unmodifiable(
          legalFightActions,
        ),
        legalSwitchOptions: List<BattleOpponentReplacementOption>.unmodifiable(
          legalSwitchOptions,
        ),
        didEnemySwitchLastTurn: _didEnemySwitchLastTurn(),
      );
      if (voluntarySwitch != null) {
        if (!legalSwitchOptions.contains(voluntarySwitch)) {
          throw StateError(
            'BattleOpponentPolicy doit retourner une des options de switch volontaire légales fournies par la session.',
          );
        }
        return BattleActionSwitch(reserveIndex: voluntarySwitch.reserveIndex);
      }
    }

    // Garde-fou de périmètre lots 3 à 5 :
    // - la policy reçoit uniquement des actions fight déjà légales ;
    // - elle doit en retourner une parmi cette liste, sans en synthétiser une
    //   nouvelle ni rouvrir switch volontaire/targeting ;
    // - si une future policy enfreint ce contrat, on préfère échouer ici
    //   explicitement plutôt que laisser entrer une action mensongère.
    final selectedAction = opponentPolicy.chooseFightAction(
      legalFightActions: List<BattleActionFight>.unmodifiable(
        legalFightActions,
      ),
    );
    if (!legalFightActions.contains(selectedAction)) {
      throw StateError(
        'BattleOpponentPolicy doit retourner une des actions fight légales fournies par la session.',
      );
    }
    return selectedAction;
  }

  List<BattleOpponentReplacementOption>
      _availableEnemyVoluntarySwitchOptions() {
    if (state.enemy.isFainted) {
      return const <BattleOpponentReplacementOption>[];
    }

    final options = <BattleOpponentReplacementOption>[];
    for (final reserveIndex in _selectableReserveIndices(state.enemyReserve)) {
      options.add(
        BattleOpponentReplacementOption(
          reserveIndex: reserveIndex,
          combatant: state.enemyReserve[reserveIndex],
        ),
      );
    }
    return List<BattleOpponentReplacementOption>.unmodifiable(options);
  }

  bool _didEnemySwitchLastTurn() {
    final previousTurn = state.currentTurn;
    if (previousTurn == null) {
      return false;
    }
    for (final event in previousTurn.switchEvents) {
      if (event.side == BattleSideId.enemy &&
          event.kind == BattleSwitchEventKind.switched) {
        return true;
      }
    }
    return false;
  }

  /// Calcule la liste des actions fight adverse actuellement légales.
  ///
  /// Ce helper reste côté session pour une raison précise :
  /// - la légalité des moves dépend encore de l'état battle courant et des PP
  ///   réellement portés par le moteur ;
  /// - déplacer cette logique dans la policy la rendrait responsable de
  ///   valider l'état battle, ce qui dériverait déjà vers un seam trop riche ;
  /// - la policy n'a donc plus qu'à choisir, pas à déterminer ce qui est légal.
  List<BattleActionFight> _availableEnemyFightActions() {
    final actions = <BattleActionFight>[];
    for (var i = 0; i < state.enemy.moves.length; i++) {
      final move = state.enemy.moves[i];
      if (move.hasUsablePp) {
        actions.add(
          BattleActionFight(
            move,
            moveIndex: i,
          ),
        );
      }
    }
    return List<BattleActionFight>.unmodifiable(actions);
  }

  /// Résout une exécution unique de move.
  ///
  /// M8 puis BE4 gardent ici un contrat volontairement petit et honnête :
  /// - dégâts standards via `power` ;
  /// - influence de `modifyStats` uniquement sur atk/def/spa/spd ;
  /// - moves de statut => dégâts 0 ;
  /// - hit check minimal et PP réels ;
  /// - BE6 ajoute un crit minimal réel pour les hits offensifs non immunisés ;
  /// - les changements de stats sont appliqués immédiatement après un hit ;
  /// - BE7 ajoute ensuite un petit sous-ensemble `applyStatus` et un blocage
  ///   d'action par paralysie, sans ouvrir un système de statuts complet.
  ///
  /// Cette application immédiate reste importante :
  /// - un `growl` du joueur peut déjà réduire une contre-attaque physique
  ///   ennemie plus tard dans le même tour s'il touche ;
  /// - mais un changement de `speed` ne réordonne jamais rétroactivement un
  ///   tour déjà ordonné au début de `_resolveTurn`.
  _ResolvedMoveExecution _resolveMoveExecution({
    required BattleSlotRef attackerSlot,
    required BattleMove move,
    required int moveIndex,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required BattleSlotRef targetSlot,
    required BattleRng rng,
  }) {
    final actionAttempt = _conditionEngine.runActionAttempt(
      attackerSlot: attackerSlot,
      move: move,
      moveIndex: moveIndex,
      attacker: attacker,
      rng: rng,
    );

    if (actionAttempt.outcome == BattleActionAttemptOutcome.preventedAction) {
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: actionAttempt.rng,
        execution: null,
        statusEvents: actionAttempt.statusEvents,
        volatileEvents: const <BattleVolatileEvent>[],
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _turnEventsFromStatus(actionAttempt.statusEvents),
      );
    }

    if (actionAttempt.outcome == BattleActionAttemptOutcome.chargeStarted) {
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: actionAttempt.rng,
        execution: null,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: actionAttempt.volatileEvents,
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _turnEventsFromVolatile(actionAttempt.volatileEvents),
      );
    }

    final preHitVolatileEvents =
        List<BattleVolatileEvent>.of(actionAttempt.volatileEvents);
    final hitCheck = _resolveHitCheck(
      move: move,
      rng: actionAttempt.rng,
    );

    if (!hitCheck.didHit) {
      final missExecution = BattleMoveExecution(
        attackerSlot: attackerSlot,
        move: actionAttempt.attacker.moves[moveIndex],
        targetKind: _resolveExecutionTargetKind(move),
        targetSlot: _resolveExecutionTargetSlot(
          move: move,
          attackerSlot: attackerSlot,
          opponentSlot: targetSlot,
        ),
        targetSideRef: _resolveExecutionTargetSide(
          move: move,
          opponentSlot: targetSlot,
        ),
        damage: 0,
        didHit: false,
        didCrit: false,
        criticalMultiplier: 1.0,
      );
      return _ResolvedMoveExecution(
        attacker: actionAttempt.attacker,
        defender: defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: missExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(
          preHitVolatileEvents,
        ),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: preHitVolatileEvents,
          execution: missExecution,
        ),
      );
    }

    final hitInterception = _conditionEngine.runHitInterception(
      move: move,
      attackerSlot: attackerSlot,
      targetSlot: targetSlot,
      attacker: actionAttempt.attacker,
      defender: defender,
    );
    preHitVolatileEvents.addAll(hitInterception.volatileEvents);

    if (hitInterception.blockedByProtect) {
      final blockedExecution = BattleMoveExecution(
        attackerSlot: attackerSlot,
        move: hitInterception.attacker.moves[moveIndex],
        targetKind: _resolveExecutionTargetKind(move),
        targetSlot: _resolveExecutionTargetSlot(
          move: move,
          attackerSlot: attackerSlot,
          opponentSlot: targetSlot,
        ),
        targetSideRef: _resolveExecutionTargetSide(
          move: move,
          opponentSlot: targetSlot,
        ),
        damage: 0,
        didHit: true,
        didCrit: false,
        criticalMultiplier: 1.0,
      );
      return _ResolvedMoveExecution(
        attacker: hitInterception.attacker,
        defender: hitInterception.defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: blockedExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(
          preHitVolatileEvents,
        ),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: preHitVolatileEvents,
          execution: blockedExecution,
        ),
      );
    }

    if (move.copiesTargetOnHit) {
      final transformedAttacker =
          hitInterception.attacker.withTransformedBattleFormFrom(
        hitInterception.defender,
      );
      final resolvedExecution = BattleMoveExecution(
        attackerSlot: attackerSlot,
        move: hitInterception.attacker.moves[moveIndex],
        targetKind: _resolveExecutionTargetKind(move),
        targetSlot: _resolveExecutionTargetSlot(
          move: move,
          attackerSlot: attackerSlot,
          opponentSlot: targetSlot,
        ),
        targetSideRef: _resolveExecutionTargetSide(
          move: move,
          opponentSlot: targetSlot,
        ),
        damage: 0,
        didHit: true,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: 1.0,
        typeEffectivenessMultiplier: 1.0,
      );

      return _ResolvedMoveExecution(
        attacker: transformedAttacker,
        defender: hitInterception.defender,
        field: field,
        rng: hitCheck.nextRng,
        execution: resolvedExecution,
        statusEvents: const <BattleStatusEvent>[],
        volatileEvents: List<BattleVolatileEvent>.unmodifiable(
          preHitVolatileEvents,
        ),
        fieldEvents: const <BattleFieldEvent>[],
        timeline: _buildMoveTimeline(
          preExecutionVolatileEvents: preHitVolatileEvents,
          execution: resolvedExecution,
        ),
      );
    }

    final damageResult = _computeMoveDamage(
      move: move,
      attacker: hitInterception.attacker,
      defender: hitInterception.defender,
      field: field,
      rng: hitCheck.nextRng,
    );

    final attackerAfterDeterministicStages = damageResult.wasImmune
        ? hitInterception.attacker
        : hitInterception.attacker
            .withAppliedStageChanges(move.selfStatStageChanges);
    final defenderAfterHit = damageResult.wasImmune
        ? hitInterception.defender
        : hitInterception.defender
            .withDamage(damageResult.damage)
            .withAppliedStageChanges(move.targetStatStageChanges);
    final attackerAfterRider = damageResult.wasImmune
        ? _ResolvedStatStageRiderApplication(
            combatant: attackerAfterDeterministicStages,
            nextRng: damageResult.nextRng,
          )
        : _applyStatStageRider(
            rider: move.selfStatStageRider,
            combatant: attackerAfterDeterministicStages,
            rng: damageResult.nextRng,
          );
    final defenderAfterRider = damageResult.wasImmune
        ? _ResolvedStatStageRiderApplication(
            combatant: defenderAfterHit,
            nextRng: attackerAfterRider.nextRng,
          )
        : _applyStatStageRider(
            rider: move.targetStatStageRider,
            combatant: defenderAfterHit,
            rng: attackerAfterRider.nextRng,
          );
    final postMoveConditions = _conditionEngine.runMoveResolved(
      move: move,
      attackerSlot: attackerSlot,
      targetSlot: targetSlot,
      attacker: attackerAfterRider.combatant,
      defender: defenderAfterRider.combatant,
      field: field,
      wasImmune: damageResult.wasImmune,
      rng: defenderAfterRider.nextRng,
    );
    final preExecutionVolatileEvents =
        List<BattleVolatileEvent>.unmodifiable(preHitVolatileEvents);
    final allVolatileEvents = <BattleVolatileEvent>[
      ...preHitVolatileEvents,
      ...postMoveConditions.volatileEvents,
    ];

    final resolvedExecution = BattleMoveExecution(
      attackerSlot: attackerSlot,
      move: postMoveConditions.attacker.moves[moveIndex],
      targetKind: _resolveExecutionTargetKind(move),
      targetSlot: _resolveExecutionTargetSlot(
        move: move,
        attackerSlot: attackerSlot,
        opponentSlot: targetSlot,
      ),
      targetSideRef: _resolveExecutionTargetSide(
        move: move,
        opponentSlot: targetSlot,
      ),
      damage: damageResult.damage,
      didHit: true,
      didCrit: damageResult.didCrit,
      criticalMultiplier: damageResult.criticalMultiplier,
      stabMultiplier: damageResult.stabMultiplier,
      typeEffectivenessMultiplier: damageResult.typeEffectivenessMultiplier,
    );

    return _ResolvedMoveExecution(
      attacker: postMoveConditions.attacker,
      defender: postMoveConditions.defender,
      field: postMoveConditions.field,
      rng: postMoveConditions.rng,
      execution: resolvedExecution,
      statusEvents: postMoveConditions.statusEvents,
      volatileEvents: List<BattleVolatileEvent>.unmodifiable(allVolatileEvents),
      fieldEvents: postMoveConditions.fieldEvents,
      timeline: _buildMoveTimeline(
        preExecutionVolatileEvents: preExecutionVolatileEvents,
        execution: resolvedExecution,
        statusEvents: postMoveConditions.statusEvents,
        fieldEvents: postMoveConditions.fieldEvents,
        postExecutionVolatileEvents: postMoveConditions.volatileEvents,
      ),
    );
  }

  _ResolvedHitCheck _resolveHitCheck({
    required BattleMove move,
    required BattleRng rng,
  }) {
    if (move.accuracy.isAlwaysHits || move.accuracy.value >= 100) {
      // Recadrage volontaire de BE4 :
      // - `alwaysHits` doit évidemment bypasser le hit check ;
      // - dans le moteur actuel, `percent(100)` est également déterministe,
      //   car nous n'avons encore ni accuracy stages, ni evasion, ni autres
      //   modificateurs de précision ;
      // - consommer du RNG sur 100% n'apporterait donc aucune vérité
      //   supplémentaire et compliquerait artificiellement les tests.
      return _ResolvedHitCheck(
        didHit: true,
        nextRng: rng,
      );
    }

    final roll = rng.nextPercentRoll();
    return _ResolvedHitCheck(
      didHit: roll.value <= move.accuracy.value,
      nextRng: roll.next,
    );
  }

  /// Résout la famille de cible observable d'une exécution.
  ///
  /// Phase G garde cette aide volontairement locale à la session :
  /// - elle évite de re-disperser la logique "combatant vs field" ;
  /// - elle ne transforme pas `BattleMoveTarget` en système de targeting riche ;
  /// - elle sert uniquement à produire un contrat d'exécution plus honnête.
  BattleMoveExecutionTargetKind _resolveExecutionTargetKind(
    BattleMove move,
  ) {
    return switch (move.target) {
      BattleMoveTarget.field => BattleMoveExecutionTargetKind.field,
      BattleMoveTarget.opponentSide => BattleMoveExecutionTargetKind.side,
      BattleMoveTarget.self ||
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        BattleMoveExecutionTargetKind.combatant,
    };
  }

  /// Résout le slot cible observable quand l'exécution vise un combattant.
  ///
  /// Frontière volontaire :
  /// - en singles, `self` et `opponent` suffisent encore ;
  /// - `field` garde explicitement l'absence de slot ;
  /// - on n'anticipe ni doubles, ni targeting multiple, ni side targeting.
  BattleSlotRef? _resolveExecutionTargetSlot({
    required BattleMove move,
    required BattleSlotRef attackerSlot,
    required BattleSlotRef opponentSlot,
  }) {
    return switch (move.target) {
      BattleMoveTarget.self => attackerSlot,
      BattleMoveTarget.field || BattleMoveTarget.opponentSide => null,
      BattleMoveTarget.opponent || BattleMoveTarget.unspecified => opponentSlot,
    };
  }

  BattleSideId? _resolveExecutionTargetSide({
    required BattleMove move,
    required BattleSlotRef opponentSlot,
  }) {
    return switch (move.target) {
      BattleMoveTarget.opponentSide => opponentSlot.side,
      BattleMoveTarget.self ||
      BattleMoveTarget.field ||
      BattleMoveTarget.opponent ||
      BattleMoveTarget.unspecified =>
        null,
    };
  }

  /// Calcule les dégâts standards du moteur battle MVP enrichi.
  ///
  /// BE2 ne bascule toujours pas vers une formule Pokémon complète. Le but est
  /// maintenant plus honnête que l'ancien simple `damage = power` :
  /// - les dégâts standards reposent enfin sur un vrai snapshot de stats ;
  /// - les moves physiques utilisent `attack` vs `defense` ;
  /// - les moves spéciaux utilisent `specialAttack` vs `specialDefense` ;
  /// - les stages continuent à s'appliquer, mais sur ces vraies bases ;
  /// - `speed` influence désormais l'ordre d'action dans BE3, mais reste sans
  ///   rôle direct dans les dégâts.
  ///
  /// Frontière explicitement conservée :
  /// - pas d'accuracy/evasion stages ;
  /// - pas de règles Pokémon avancées de critique ;
  /// - le hit check BE4 vit en amont, avant d'entrer dans cette formule ;
  /// - BE6 ajoute seulement :
  ///   - une vraie chance de critique minimale ;
  ///   - un multiplicateur critique fixe ;
  ///   - aucune interaction avancée avec stages / items / abilities.
  _ResolvedDamage _computeMoveDamage({
    required BattleMove move,
    required BattleCombatant attacker,
    required BattleCombatant defender,
    required BattleFieldState field,
    required BattleRng rng,
  }) {
    if (move.resolvedCategory == BattleMoveCategory.status || move.power <= 0) {
      return _ResolvedDamage(
        damage: 0,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: 1.0,
        typeEffectivenessMultiplier: 1.0,
        nextRng: rng,
      );
    }

    final offensiveStatId = switch (move.resolvedCategory) {
      BattleMoveCategory.physical => BattleStatId.attack,
      BattleMoveCategory.special => BattleStatId.specialAttack,
      BattleMoveCategory.status => BattleStatId.attack,
    };
    final defensiveStatId = switch (move.resolvedCategory) {
      BattleMoveCategory.physical => BattleStatId.defense,
      BattleMoveCategory.special => BattleStatId.specialDefense,
      BattleMoveCategory.status => BattleStatId.defense,
    };

    // Ordre de calcul volontairement documenté :
    // 1. on part du snapshot de stats résolu par le runtime ;
    // 2. on applique les stages côté attaquant et défenseur ;
    // 3. on utilise ensuite une formule entière simple, Pokémon-like ;
    // 4. on garde enfin un minimum de 1 dégât pour tout move non-status
    //    ayant passé le bridge BE1.
    final effectiveAttack = _resolveEffectiveStat(
      baseStat: _statValueFor(attacker.stats, offensiveStatId),
      multiplier: attacker.statStages.multiplierFor(offensiveStatId),
    );
    final effectiveDefense = _resolveEffectiveStat(
      baseStat: _statValueFor(defender.stats, defensiveStatId),
      multiplier: defender.statStages.multiplierFor(defensiveStatId),
    );
    final safePower = move.power < 0 ? 0 : move.power;
    final levelFactor = ((2 * attacker.level) ~/ 5) + 2;
    final baseDamage =
        ((((levelFactor * safePower * effectiveAttack) ~/ effectiveDefense) ~/
                    50) +
                2)
            .toInt();

    // BE5 ajoute ici la plus petite consommation honnête du type :
    // - STAB simple à 1.5 ;
    // - type chart standard ;
    // - immunité à 0 ;
    // - double type multiplicatif ;
    // - toujours aucune abilities, aucun item, aucune Tera ;
    // - BE9 n'ajoute ensuite qu'un unique modificateur météo local :
    //   la pluie pour Eau/Feu.
    final stabMultiplier = BattleTypeChart.resolveStabMultiplier(
      moveType: move.type,
      attackerTyping: attacker.typing,
    );
    final typeEffectivenessMultiplier =
        BattleTypeChart.resolveEffectivenessMultiplier(
      moveType: move.type,
      defenderTyping: defender.typing,
    );

    if (typeEffectivenessMultiplier == 0.0) {
      return _ResolvedDamage(
        damage: 0,
        didCrit: false,
        criticalMultiplier: 1.0,
        stabMultiplier: stabMultiplier,
        typeEffectivenessMultiplier: typeEffectivenessMultiplier,
        nextRng: rng,
      );
    }

    // BE6 garde ici un ordre de résolution petit mais honnête :
    // 1. le hit check a déjà eu lieu en amont ;
    // 2. on vérifie ensuite l'immunité via le type chart ;
    // 3. seulement pour un hit offensif non immunisé, on résout un crit ;
    // 4. puis on applique STAB / efficacité de type et le clamp final.
    //
    // Ce choix évite de "dépenser" un tirage de crit sur un move qui n'aurait
    // de toute façon aucun effet. Pour le sous-ensemble actuel, c'est plus
    // honnête et reste mathématiquement neutre sur le résultat observable.
    final criticalHit = _resolveCriticalHit(
      move: move,
      rng: rng,
    );

    // Ordre de multiplication BE6 :
    // 1. baseDamage déterministe BE2 ;
    // 2. critique minimal BE6 ;
    // 3. malus de brûlure sur les moves physiques dans BE7 ;
    // 4. STAB ;
    // 5. effectiveness / résistance ;
    // 6. météo BE9 réellement supportée ;
    // 7. clamp minimum 1 si le move a touché et n'est pas immunisé.
    //
    // On reste volontairement dans un modèle simple à base de doubles +
    // `floor` plutôt que de singer tous les paliers internes de Showdown.
    final burnMultiplier = _conditionEngine.resolveStatusDamageMultiplier(
      move: move,
      attacker: attacker,
    );
    final weatherMultiplier = _conditionEngine.resolveFieldDamageMultiplier(
      move: move,
      field: field,
    );
    final scaledDamage = (baseDamage *
            criticalHit.multiplier *
            burnMultiplier *
            stabMultiplier *
            typeEffectivenessMultiplier *
            weatherMultiplier)
        .floor();
    final finalDamage = scaledDamage < 1 ? 1 : scaledDamage;

    return _ResolvedDamage(
      damage: finalDamage,
      didCrit: criticalHit.didCrit,
      criticalMultiplier: criticalHit.multiplier,
      stabMultiplier: stabMultiplier,
      typeEffectivenessMultiplier: typeEffectivenessMultiplier,
      nextRng: criticalHit.nextRng,
    );
  }

  _ResolvedCriticalHit _resolveCriticalHit({
    required BattleMove move,
    required BattleRng rng,
  }) {
    final chance = _critChanceForRatio(move.critRatio);
    if (chance.didOccurWithoutRng) {
      return _ResolvedCriticalHit(
        didCrit: true,
        multiplier: _criticalHitMultiplier,
        nextRng: rng,
      );
    }

    final roll = rng.nextChance(
      numerator: chance.numerator,
      denominator: chance.denominator,
    );
    return _ResolvedCriticalHit(
      didCrit: roll.didOccur,
      multiplier: roll.didOccur ? _criticalHitMultiplier : 1.0,
      nextRng: roll.next,
    );
  }

  _ResolvedStatStageRiderApplication _applyStatStageRider({
    required BattleStatStageEffect? rider,
    required BattleCombatant combatant,
    required BattleRng rng,
  }) {
    if (rider == null) {
      return _ResolvedStatStageRiderApplication(
        combatant: combatant,
        nextRng: rng,
      );
    }

    if (rider.chancePercent == null) {
      return _ResolvedStatStageRiderApplication(
        combatant: combatant.withAppliedStageChanges(rider.changes),
        nextRng: rng,
      );
    }

    final roll = rng.nextChance(
      numerator: rider.chancePercent!,
      denominator: 100,
    );
    return _ResolvedStatStageRiderApplication(
      combatant: roll.didOccur
          ? combatant.withAppliedStageChanges(rider.changes)
          : combatant,
      nextRng: roll.next,
    );
  }

  _CritChance _critChanceForRatio(int critRatio) {
    // Table BE6 volontairement explicite :
    // - on suit une lecture moderne Pokémon-like des stages de crit ;
    // - `1` reste le ratio neutre du canonique projet ;
    // - on ne prétend pas ouvrir Focus Energy, Lucky Chant ou d'autres
    //   modificateurs indirects.
    //
    // Mini-fix BE6 puis BE6-mini-fix-2 :
    // - la première version neutralisait silencieusement `critRatio <= 0`
    //   dans la branche "ratio neutre" ;
    // - cela laissait une donnée battle invalide devenir "à peu près valide" ;
    // - le contrat public est désormais mieux verrouillé en amont, donc cette
    //   garde sert surtout de défense en profondeur pour un état incohérent
    //   qui réapparaîtrait à l'intérieur même de `map_battle` ;
    // - on préfère maintenant un `StateError` explicite, parce qu'à ce stade
    //   il s'agit d'un état battle incohérent, pas d'une simple option métier.
    if (critRatio < 1) {
      throw StateError(
        'Battle critical ratio must be >= 1; got $critRatio.',
      );
    }
    return switch (critRatio) {
      1 => const _CritChance(numerator: 1, denominator: 24),
      2 => const _CritChance(numerator: 1, denominator: 8),
      3 => const _CritChance(numerator: 1, denominator: 2),
      _ => const _CritChance.always(),
    };
  }

  int _statValueFor(BattleStatsSnapshot snapshot, BattleStatId stat) {
    return switch (stat) {
      BattleStatId.attack => snapshot.attack,
      BattleStatId.defense => snapshot.defense,
      BattleStatId.specialAttack => snapshot.specialAttack,
      BattleStatId.specialDefense => snapshot.specialDefense,
      BattleStatId.speed => snapshot.speed,
    };
  }

  int _resolveEffectiveSpeed(BattleCombatant combatant) {
    // L'ordre BE3 repose sur une vitesse effective déterministe :
    // - snapshot de speed résolu par le runtime ;
    // - multiplicateur de stages battle déjà présent ;
    // - Phase E délègue ensuite à l'engine conditionnel le malus simple de
    //   paralysie, pour arrêter de disperser cette règle métier ;
    // - aucun RNG, aucune nature, aucun weather ;
    // - Trick Room BE9 n'altère pas cette valeur : il inverse ensuite la
    //   comparaison des deux vitesses au niveau du scheduler.
    final stagedSpeed = _resolveEffectiveStat(
      baseStat: combatant.stats.speed,
      multiplier: combatant.statStages.multiplierFor(BattleStatId.speed),
    );
    return _conditionEngine.resolveStatusAdjustedSpeed(
      combatant: combatant,
      stagedSpeed: stagedSpeed,
    );
  }

  int _resolveEffectiveStat({
    required int baseStat,
    required double multiplier,
  }) {
    // BE2 garde ici une règle simple et déterministe :
    // - pas de fraction stockée ;
    // - pas de rounding ambigu ;
    // - on applique les stages par multiplication, puis `floor` ;
    // - on clamp enfin au minimum 1 pour ne jamais diviser par 0 ni produire
    //   une stat offensive/défensive absurde.
    final resolved = (baseStat * multiplier).floor();
    return resolved < 1 ? 1 : resolved;
  }

  /// Détermine le résultat final du combat.
  ///
  /// [player] - L'état final du joueur.
  /// [enemy] - L'état final de l'ennemi.
  ///
  /// Retourne null si le combat continue, ou un [BattleOutcome] si fini.
  ///
  /// Politique BE10, volontairement petite et explicite :
  /// - les remplacements automatiques honnêtes ont déjà été tentés avant
  ///   d'entrer ici ;
  /// - si l'ennemi actif est encore K.O. à ce stade, il n'a plus de réserve
  ///   valide et le joueur gagne ;
  /// - sinon, si le joueur actif est encore K.O. mais qu'une réserve valide
  ///   existe encore, le combat continue pour laisser place au switch forcé ;
  /// - sinon, si le joueur actif est encore K.O., il n'a plus de réserve
  ///   valide et le joueur perd ;
  /// - sinon le combat continue ;
  /// - en cas de double K.O. sans réserve des deux côtés, on conserve donc la
  ///   politique historique "enemy d'abord", ce qui produit une victoire.
  ///
  /// Cette méthode est interne au moteur de combat.
  BattleOutcome? _determineOutcome(
    BattleSideState playerSide,
    BattleSideState enemySide,
    BattleFieldState field,
  ) {
    // Vérifier la victoire (ennemi K.O.)
    if (enemySide.active.isFainted) {
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: playerSide,
        enemySide: enemySide,
        field: field,
        currentTurn: null,
        outcome: null, // Sera set dans le BattleOutcome
      );
      return BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: finalState,
      );
    }

    // Vérifier la défaite (joueur K.O.)
    if (playerSide.active.isFainted) {
      if (_firstUsableReserveIndex(playerSide.reserve) != null) {
        return null;
      }
      final finalState = BattleState(
        phase: BattlePhase.finished,
        playerSide: playerSide,
        enemySide: enemySide,
        field: field,
        currentTurn: null,
        outcome: null,
      );
      return BattleOutcome(
        type: BattleOutcomeType.defeat,
        finalState: finalState,
      );
    }

    // Combat continue
    return null;
  }

  List<BattleTurnEvent> _buildMoveTimeline({
    List<BattleVolatileEvent> preExecutionVolatileEvents =
        const <BattleVolatileEvent>[],
    BattleMoveExecution? execution,
    List<BattleStatusEvent> statusEvents = const <BattleStatusEvent>[],
    List<BattleFieldEvent> fieldEvents = const <BattleFieldEvent>[],
    List<BattleVolatileEvent> postExecutionVolatileEvents =
        const <BattleVolatileEvent>[],
  }) {
    // BE10A garde une granularité volontairement petite :
    // - on ne reconstruit plus l'ordre en UI ;
    // - on fabrique ici une chronologie ordonnée au moment où le moteur
    //   connaît réellement l'enchaînement causal ;
    // - on ne descend toutefois pas dans une micro-chronologie Showdown-like
    //   de chaque sous-étape interne.
    final timeline = <BattleTurnEvent>[
      ..._turnEventsFromVolatile(preExecutionVolatileEvents),
      if (execution != null) BattleTurnExecutionEvent(execution),
      ..._turnEventsFromStatus(statusEvents),
      ..._turnEventsFromField(fieldEvents),
      ..._turnEventsFromVolatile(postExecutionVolatileEvents),
    ];
    return List<BattleTurnEvent>.unmodifiable(timeline);
  }

  List<BattleTurnEvent> _turnEventsFromStatus(
    Iterable<BattleStatusEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnStatusEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromVolatile(
    Iterable<BattleVolatileEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnVolatileEvent.new),
    );
  }

  List<BattleTurnEvent> _turnEventsFromField(
    Iterable<BattleFieldEvent> events,
  ) {
    return List<BattleTurnEvent>.unmodifiable(
      events.map(BattleTurnFieldEvent.new),
    );
  }
}

class _ResolvedSwitchAction {
  const _ResolvedSwitchAction({
    required this.side,
    required this.event,
  });

  final BattleSideState side;
  final BattleSwitchEvent event;
}

class _ResolvedBagHpHealItemUseAction {
  const _ResolvedBagHpHealItemUseAction({
    required this.side,
    required this.event,
  });

  final BattleSideState side;
  final BattleBagHpHealItemEvent event;
}

class _ResolvedMoveExecution {
  const _ResolvedMoveExecution({
    required this.attacker,
    required this.defender,
    required this.field,
    required this.rng,
    required this.execution,
    required this.statusEvents,
    required this.volatileEvents,
    required this.fieldEvents,
    required this.timeline,
  });

  final BattleCombatant attacker;
  final BattleCombatant defender;
  final BattleFieldState field;
  final BattleRng rng;
  final BattleMoveExecution? execution;
  final List<BattleStatusEvent> statusEvents;
  final List<BattleVolatileEvent> volatileEvents;
  final List<BattleFieldEvent> fieldEvents;
  final List<BattleTurnEvent> timeline;
}

class _ResolvedHitCheck {
  const _ResolvedHitCheck({
    required this.didHit,
    required this.nextRng,
  });

  final bool didHit;
  final BattleRng nextRng;
}

class _ResolvedDamage {
  const _ResolvedDamage({
    required this.damage,
    required this.didCrit,
    required this.criticalMultiplier,
    required this.stabMultiplier,
    required this.typeEffectivenessMultiplier,
    required this.nextRng,
  });

  final int damage;
  final bool didCrit;
  final double criticalMultiplier;
  final double stabMultiplier;
  final double typeEffectivenessMultiplier;
  final BattleRng nextRng;

  bool get wasImmune => typeEffectivenessMultiplier == 0.0;
}

class _ResolvedCriticalHit {
  const _ResolvedCriticalHit({
    required this.didCrit,
    required this.multiplier,
    required this.nextRng,
  });

  final bool didCrit;
  final double multiplier;
  final BattleRng nextRng;
}

class _ResolvedStatStageRiderApplication {
  const _ResolvedStatStageRiderApplication({
    required this.combatant,
    required this.nextRng,
  });

  final BattleCombatant combatant;
  final BattleRng nextRng;
}

class _CritChance {
  const _CritChance({
    required this.numerator,
    required this.denominator,
  }) : didOccurWithoutRng = false;

  const _CritChance.always()
      : numerator = 1,
        denominator = 1,
        didOccurWithoutRng = true;

  final int numerator;
  final int denominator;
  final bool didOccurWithoutRng;
}

BattleSideState _replacePlayerCombatantByLineupIndex({
  required BattleSideState side,
  required BattleCombatant updatedCombatant,
}) {
  if (side.active.lineupIndex == updatedCombatant.lineupIndex) {
    return side.withActive(updatedCombatant);
  }

  final reserveIndex = side.reserve.indexWhere(
    (combatant) => combatant.lineupIndex == updatedCombatant.lineupIndex,
  );
  if (reserveIndex == -1) {
    throw StateError(
      'Aucun combattant joueur avec lineupIndex=${updatedCombatant.lineupIndex} '
      'n’existe dans la session battle courante.',
    );
  }

  final updatedReserve =
      List<BattleCombatant>.of(side.reserve, growable: false);
  updatedReserve[reserveIndex] = updatedCombatant;
  return side.withReserve(updatedReserve);
}

BattleCombatant _requireUsableBagHpHealItemTarget({
  required BattleSideState side,
  required int targetLineupIndex,
}) {
  final combatant = _findCombatantByLineupIndex(
    side: side,
    targetLineupIndex: targetLineupIndex,
  );
  if (combatant == null) {
    throw StateError(
      'Un objet BAG de soin HP vise un lineupIndex joueur introuvable dans la session courante '
      '(lineupIndex=$targetLineupIndex).',
    );
  }
  if (combatant.isFainted) {
    throw StateError(
      'Un objet BAG de soin HP ne peut pas cibler un combattant joueur K.O. '
      '(lineupIndex=$targetLineupIndex).',
    );
  }
  if (combatant.currentHp >= combatant.maxHp) {
    throw StateError(
      'Un objet BAG de soin HP ne peut pas cibler un combattant déjà full HP '
      '(lineupIndex=$targetLineupIndex).',
    );
  }
  return combatant;
}

BattleCombatant? _findCombatantByLineupIndex({
  required BattleSideState side,
  required int targetLineupIndex,
}) {
  if (side.active.lineupIndex == targetLineupIndex) {
    return side.active;
  }

  final reserveIndex = side.reserve.indexWhere(
    (combatant) => combatant.lineupIndex == targetLineupIndex,
  );
  if (reserveIndex == -1) {
    return null;
  }
  return side.reserve[reserveIndex];
}
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_status.dart';
import 'battle_volatile.dart';
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
  /// [fieldState] - État de champ initial si le setup battle veut démarrer
  ///   sous une météo ou un pseudoWeather déjà actifs.
  const BattleSetup({
    required this.playerPokemon,
    this.playerReservePokemon = const <BattleCombatantData>[],
    required this.enemyPokemon,
    this.enemyReservePokemon = const <BattleCombatantData>[],
    required this.isTrainerBattle,
    required this.trainerId,
    this.allowCapture = false,
    this.fieldState = const BattleFieldState(),
  });

  /// Le Pokémon du joueur qui combat.
  final BattleCombatantData playerPokemon;

  /// Réserve battle locale du joueur.
  ///
  /// BE10 reste volontairement simple :
  /// - un seul actif joueur ;
  /// - zéro ou plusieurs membres de réserve ;
  /// - aucun système de side/slot riche.
  final List<BattleCombatantData> playerReservePokemon;

  /// Le Pokémon adverse qui combat.
  final BattleCombatantData enemyPokemon;

  /// Réserve battle locale de l'adversaire.
  ///
  /// Le lot l'ouvre surtout pour rendre honnêtes les trainer battles à
  /// plusieurs Pokémon, sans ouvrir de multi-battle.
  final List<BattleCombatantData> enemyReservePokemon;

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

  /// État de champ initial du combat.
  ///
  /// BE9 le porte dès le setup pour garder le champ observable :
  /// - le runtime principal démarre encore avec un champ vide ;
  /// - mais les tests et call sites directs peuvent injecter une pluie,
  ///   une tempête de sable ou un Trick Room déjà actifs ;
  /// - cela évite des mutations post-création qui mentiraient sur l'état
  ///   initial réellement résolu.
  final BattleFieldState fieldState;
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
  /// [majorStatus] - Statut majeur initial si un call site battle direct veut
  ///   démarrer depuis un état déjà entamé.
  /// [volatileState] - Sous-état volatile local BE8 si un setup battle direct
  ///   veut démarrer depuis une protection, une recharge ou une charge déjà
  ///   en cours.
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
    this.lineupIndex = 0,
    this.typing,
    this.majorStatus,
    this.volatileState = const BattleVolatileState(),
    this.currentHp,
    this.abilityId = 'unknown',
    required this.moves,
  });

  /// L'identifiant de l'espèce (ex: "pikachu", "lapras").
  final String speciesId;

  /// Identité stable du combattant dans la lineup battle de son camp.
  ///
  /// BE10 ajoute ce petit identifiant pour une raison très concrète :
  /// - pendant le combat, actif et réserve peuvent s'échanger plusieurs fois ;
  /// - le runtime doit malgré tout réécrire les bons slots de party après le
  ///   combat sans deviner l'historique des switches ;
  /// - on transporte donc un index local stable, purement battle/runtime,
  ///   qui n'ouvre ni grid de slots, ni modèle de party parallèle.
  ///
  /// Important :
  /// - ce n'est pas un slot de doubles ;
  /// - ce n'est pas un index UI ;
  /// - c'est uniquement une identité stable dans la lineup initiale de ce
  ///   camp pour le write-back et la cohérence des remplacements.
  final int lineupIndex;

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

  /// Statut majeur initial du combattant si le setup battle le connaît déjà.
  ///
  /// Le chemin runtime principal le laisse à `null` dans BE7 :
  /// - la persistance hors combat des statuts n'existe pas encore ;
  /// - mais le moteur battle a maintenant besoin d'un vrai état local de
  ///   statut majeur ;
  /// - garder ce champ optionnel évite aussi d'inventer des helpers de test
  ///   parallèles juste pour démarrer un combat déjà brûlé / paralysé / etc.
  final BattleMajorStatusState? majorStatus;

  /// Sous-état volatile local du combattant au démarrage.
  ///
  /// Le chemin runtime principal le laisse vide dans BE8 :
  /// - il n'existe pas encore de persistance hors combat de `Protect`,
  ///   `mustRecharge` ou des moves chargés ;
  /// - mais garder ce champ directement sur le setup battle permet des tests
  ///   honnêtes sans mutation post-création de session.
  final BattleVolatileState volatileState;

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
  /// [majorStatusEffect] - Effet `applyStatus` battle minimal supporté par
  ///   BE7 pour le petit sous-ensemble de statuts majeurs réellement
  ///   exécutable.
  /// [selfVolatileStatus] - Volatile auto-appliqué par le move dans le
  ///   sous-ensemble strict BE8 (`protect` uniquement).
  /// [weatherEffect] - Effet météo battle minimal réellement consommé par BE9.
  /// [pseudoWeatherEffect] - Effet pseudoWeather battle minimal réellement
  ///   consommé par BE9.
  /// [setsStealthRock] - H1 ouvre exactement Stealth Rock, et rien de plus,
  ///   côté hazard side-level.
  /// [setsSpikes] - H2 ouvre exactement Spikes, et rien de plus.
  /// [breaksProtect] - Le move peut bypasser une protection active BE8.
  /// [requiresRecharge] - Le move impose ensuite un tour de recharge au
  ///   lanceur.
  /// [chargeThenStrikeEffect] - Le move charge un tour puis frappe le tour
  ///   suivant sans repayer les PP.
  /// [copiesTargetOnHit] - Le move copie la forme battle active de la cible
  ///   lorsqu'il touche (`Transform`).
  /// [selfStatStageChanges] - Boosts / baisses appliqués au lanceur.
  /// [targetStatStageChanges] - Boosts / baisses appliqués à la cible.
  /// [selfStatStageRider] - Rider de stats probabiliste appliqué au lanceur
  ///   après un hit/résolution réussie.
  /// [targetStatStageRider] - Rider de stats probabiliste appliqué à la cible
  ///   après un hit/résolution réussie.
  ///
  /// Ce contrat reste volontairement petit :
  /// - il ne copie pas `PokemonMove` ;
  /// - il ne prétend pas transporter tous les `effects` canoniques ;
  /// - mais BE1 y ajoute aussi quelques dimensions battle fondamentales
  ///   (`type`, `target`, `pp`) pour arrêter leur perte silencieuse ;
  /// - puis BE3 et BE4 commencent à consommer réellement `priority`,
  ///   `speed`, `accuracy` et les PP ;
  /// - puis BE6 ouvre enfin un crit minimal honnête via `critRatio` ;
  /// - puis BE7 ouvre un unique effet `applyStatus` battle minimal pour
  ///   `par`, `brn`, `psn`, `tox` ;
  /// - puis BE8 ajoute quelques volatiles utiles explicitement bornés aux
  ///   besoins de `Protect`, `breakProtect`, `requireRecharge` et
  ///   `chargeThenStrike` ;
  /// - puis BE9 ajoute uniquement la météo et le pseudoWeather réellement
  ///   consommés par le moteur (`rain`, `sandstorm`, `trickRoom`) ;
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
    this.majorStatusEffect,
    this.selfVolatileStatus,
    this.weatherEffect,
    this.pseudoWeatherEffect,
    this.setsStealthRock = false,
    this.setsSpikes = false,
    this.breaksProtect = false,
    this.requiresRecharge = false,
    this.chargeThenStrikeEffect,
    this.copiesTargetOnHit = false,
    this.selfStatStageChanges = const <BattleStatStageChange>[],
    this.targetStatStageChanges = const <BattleStatStageChange>[],
    this.selfStatStageRider,
    this.targetStatStageRider,
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
  ///
  /// BE9 ajoute aussi `BattleMoveTarget.field` pour les moves qui posent une
  /// météo ou un pseudoWeather réellement consommés par le moteur.
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

  /// Effet battle minimal de statut majeur si le bridge runtime l'a autorisé.
  ///
  /// Ce champ reste volontairement simple :
  /// - pas de liste générique d'effets battle ;
  /// - pas de volatile status ;
  /// - pas de payload de scope, car le bridge BE7 ne laisse passer que
  ///   `targetScope: target`.
  final BattleMoveMajorStatusEffect? majorStatusEffect;

  /// Volatile auto-appliqué par le move dans le sous-ensemble BE8.
  final BattleVolatileStatusId? selfVolatileStatus;

  /// Météo de champ posée par ce move dans le sous-ensemble BE9.
  final BattleWeatherId? weatherEffect;

  /// PseudoWeather de champ posé par ce move dans le sous-ensemble BE9.
  final BattlePseudoWeatherId? pseudoWeatherEffect;

  /// H1 ouvre uniquement Stealth Rock comme premier hazard honnête.
  ///
  /// On garde ici le même design volontairement borné que dans `BattleMove` :
  /// - pas d'identifiant générique de side condition ;
  /// - pas de liste d'effets ;
  /// - juste le plus petit bit de vérité requis pour ce lot précis.
  final bool setsStealthRock;

  /// H2 ouvre uniquement Spikes comme second slice hazard side-level.
  ///
  /// On garde volontairement un booléen dédié :
  /// - parce que ce lot ne supporte qu'une seule nouvelle mécanique ;
  /// - parce qu'un conteneur générique de side conditions serait encore mort ;
  /// - parce qu'il faut que la frontière de phase reste lisible dans le code.
  final bool setsSpikes;

  /// true si ce move peut percer une protection active BE8.
  final bool breaksProtect;

  /// true si ce move demande ensuite un tour de recharge.
  final bool requiresRecharge;

  /// Payload battle minimal d'un move à charge sur deux tours.
  final BattleChargeThenStrikeEffect? chargeThenStrikeEffect;

  /// true si ce move copie la forme battle active de sa cible en touchant.
  ///
  /// Ce champ reste volontairement spécifique :
  /// - il existe pour brancher `Transform` sans importer le modèle PSDK dans
  ///   le moteur legacy encore utilisé par le runtime ;
  /// - il ne devient pas un conteneur générique d'effets spéciaux ;
  /// - le bridge runtime ne doit le poser que pour l'attaque canonique
  ///   `transform`.
  final bool copiesTargetOnHit;

  /// Changements d'étages de stats appliqués au lanceur.
  final List<BattleStatStageChange> selfStatStageChanges;

  /// Changements d'étages de stats appliqués à la cible.
  final List<BattleStatStageChange> targetStatStageChanges;

  /// Rider de stats appliqué au lanceur après un hit/résolution réussie.
  final BattleStatStageEffect? selfStatStageRider;

  /// Rider de stats appliqué à la cible après un hit/résolution réussie.
  final BattleStatStageEffect? targetStatStageRider;
}
import 'battle_field.dart';
import 'battle_move.dart';
import 'battle_resolution.dart';
import 'battle_status.dart';
import 'battle_topology.dart';
import 'battle_volatile.dart';
import 'battle_stats.dart';
import 'battle_typing.dart';

const int _transformCopiedMovePp = 5;

/// Phase du combat.
///
/// Représente l'état actuel du cycle de combat.
enum BattlePhase {
  /// En attente du choix du joueur.
  ///
  /// C'est la phase normale entre les tours.
  /// Le runtime doit appeler [BattleSession.decisionRequest] pour connaître
  /// explicitement le type de décision attendu.
  ///
  /// Compatibilité locale conservée :
  /// - [BattleSession.getAvailableChoices()] reste disponible ;
  /// - mais il devient un simple adaptateur dérivé de la vraie requête.
  playerChoice,

  /// Résolution en cours.
  ///
  /// Phase transitoire pendant laquelle le tour est en cours de résolution.
  /// Le runtime ne doit pas permettre de nouveaux choix pendant cette phase.
  resolving,

  /// Combat terminé.
  ///
  /// [BattleState.outcome] est non-null et contient le résultat final.
  /// Le runtime doit appeler `_onBattleFinished(outcome)` pour revenir à l'overworld.
  finished,
}

/// État immutable d'un combat.
///
/// Ce modèle représente l'état complet d'un combat à un instant donné.
/// Il est immutable : toutes les méthodes de modification retournent un nouvel état.
///
/// Invariants :
/// - Si [phase] == [BattlePhase.finished], alors [outcome] est non-null.
/// - Si [phase] != [BattlePhase.finished], alors [outcome] est null.
/// - [playerSide.active.currentHp] est toujours entre 0 et
///   [playerSide.active.maxHp].
/// - [enemySide.active.currentHp] est toujours entre 0 et
///   [enemySide.active.maxHp].
class BattleState {
  /// Crée un état de combat.
  ///
  /// [phase] - La phase actuelle du combat.
  ///
  /// Phase D introduit ici le vrai progrès topologique du moteur :
  /// - la forme canonique du state devient `playerSide` / `enemySide` ;
  /// - chaque side porte un slot actif et une réserve ;
  /// - on cesse donc de considérer le moteur comme un simple sac de quatre
  ///   champs plats `player / playerReserve / enemy / enemyReserve`.
  ///
  /// Compatibilité bornée conservée :
  /// - beaucoup de call sites runtime/tests lisent encore `player`, `enemy`,
  ///   `playerReserve` et `enemyReserve` ;
  /// - cette surface de lecture reste donc disponible comme façade projetée ;
  /// - mais le stockage canonique du state vit désormais dans les deux sides.
  ///
  /// Contrat d'entrée :
  /// - fournir soit `playerSide`/`enemySide` ;
  /// - soit le vieux chemin plat `player`/`playerReserve`/`enemy`/
  ///   `enemyReserve` ;
  /// - ne pas mélanger les deux pour un même côté.
  /// [field] - L'état de champ observable (weather / pseudoWeather).
  /// [currentTurn] - Le résultat du tour en cours (null si aucun tour en cours).
  /// [outcome] - Le résultat final du combat (null si combat en cours).
  BattleState({
    required this.phase,
    BattleSideState? playerSide,
    BattleCombatant? player,
    List<BattleCombatant> playerReserve = const <BattleCombatant>[],
    BattleSideState? enemySide,
    BattleCombatant? enemy,
    List<BattleCombatant> enemyReserve = const <BattleCombatant>[],
    this.field = const BattleFieldState(),
    this.currentTurn,
    this.outcome,
  })  : playerSide = _resolveBattleStateSide(
          expectedId: BattleSideId.player,
          providedSide: playerSide,
          legacyActive: player,
          legacyReserve: playerReserve,
          sideLabel: 'player',
        ),
        enemySide = _resolveBattleStateSide(
          expectedId: BattleSideId.enemy,
          providedSide: enemySide,
          legacyActive: enemy,
          legacyReserve: enemyReserve,
          sideLabel: 'enemy',
        );

  /// La phase actuelle du combat.
  final BattlePhase phase;

  /// Side joueur canonique du combat.
  final BattleSideState playerSide;

  /// Side adverse canonique du combat.
  final BattleSideState enemySide;

  /// État de champ observable du combat.
  ///
  /// BE9 le porte directement dans `BattleState` pour éviter un nouveau
  /// mensonge :
  /// - la météo et Trick Room modifient maintenant réellement le moteur ;
  /// - ils ne doivent donc pas vivre comme un détail caché de résolution ;
  /// - le runtime et les tests peuvent relire cet état sans introspection
  ///   privée de `BattleSession`.
  final BattleFieldState field;

  /// Le résultat du tour en cours.
  ///
  /// Null si aucun tour n'est en cours (phase [playerChoice] ou [finished]).
  final BattleTurnResult? currentTurn;

  /// Le résultat final du combat.
  ///
  /// Non-null uniquement si [phase] == [BattlePhase.finished].
  final BattleOutcome? outcome;

  /// true si le combat est terminé.
  ///
  /// Raccourci pour `phase == BattlePhase.finished`.
  bool get isFinished => phase == BattlePhase.finished;

  /// Compatibilité locale : actif joueur projeté depuis [playerSide].
  ///
  /// Ce getter reste volontairement public pour éviter qu'une migration de
  /// topologie Phase D force en douce une refonte runtime plus large.
  BattleCombatant get player => playerSide.active;

  /// Compatibilité locale : réserve joueur projetée depuis [playerSide].
  List<BattleCombatant> get playerReserve => playerSide.reserve;

  /// Compatibilité locale : actif adverse projeté depuis [enemySide].
  BattleCombatant get enemy => enemySide.active;

  /// Compatibilité locale : réserve adverse projetée depuis [enemySide].
  List<BattleCombatant> get enemyReserve => enemySide.reserve;

  /// Retourne le side demandé sans réintroduire un protocole plat.
  BattleSideState side(BattleSideId sideId) {
    return switch (sideId) {
      BattleSideId.player => playerSide,
      BattleSideId.enemy => enemySide,
    };
  }
}

/// Combattant en combat.
///
/// Représente un Pokémon avec ses PV courants.
/// Immutable : utiliser [withDamage] pour créer une copie avec des PV modifiés.
///
/// Invariants :
/// - [currentHp] est toujours entre 0 et [maxHp].
/// - [isFainted] est true si et seulement si [currentHp] <= 0.
class BattleCombatant {
  /// Crée un combattant.
  ///
  /// [speciesId] - L'identifiant de l'espèce.
  /// [level] - Le niveau.
  /// [currentHp] - Les PV courants.
  /// [maxHp] - Les PV maximum.
  /// [stats] - Snapshot résolu des stats non-HP.
  /// [typing] - Typing battle minimal si connu.
  /// [majorStatus] - Statut majeur actuellement porté si le combattant en a un.
  /// [volatileState] - Sous-état volatile local BE8 (`protect`, recharge,
  ///   charge en attente).
  /// [abilityId] - L'ability réellement résolue si le runtime la connaît.
  /// [moves] - La liste des attaques disponibles.
  const BattleCombatant({
    required this.speciesId,
    this.lineupIndex = 0,
    required this.level,
    required this.currentHp,
    required this.maxHp,
    required this.stats,
    this.typing,
    this.majorStatus,
    this.volatileState = const BattleVolatileState(),
    this.abilityId = 'unknown',
    required this.moves,
    this.statStages = const BattleStatStages(),
  });

  /// L'identifiant de l'espèce.
  final String speciesId;

  /// Identité stable de lineup pour ce combattant.
  ///
  /// Voir `BattleCombatantData.lineupIndex` :
  /// - elle ne sert pas au gameplay direct ;
  /// - elle sert à préserver une identité stable malgré les switches ;
  /// - le runtime peut ensuite écrire les bons slots de party sans reconstruire
  ///   l'historique du combat.
  final int lineupIndex;

  /// Le niveau.
  final int level;

  /// Les PV courants.
  final int currentHp;

  /// Les PV maximum.
  final int maxHp;

  /// Snapshot résolu des stats non-HP.
  ///
  /// BE2 le transporte jusqu'à l'état battle pour que :
  /// - les moves physiques opposent enfin attaque vs défense ;
  /// - les moves spéciaux opposent enfin spécial vs spécial défense ;
  /// - `speed` survive au handoff jusqu'au moteur.
  ///
  /// BE3 commence ensuite à la consommer réellement pour l'ordre d'action,
  /// sans pour autant ouvrir toute une queue générique ni un système de
  /// précision / critique / résiduels.
  final BattleStatsSnapshot stats;

  /// Typing minimal du combattant si le setup le fournit.
  ///
  /// BE5 en a besoin pour fermer le trou où `type` était encore décoratif :
  /// - STAB dépend du typing de l'attaquant ;
  /// - résistances/faiblesses/immunités dépendent du typing du défenseur.
  ///
  /// Compatibilité résiduelle assumée :
  /// - un vieux setup direct `map_battle` peut encore laisser ce champ absent ;
  /// - dans ce cas, le moteur reste neutre sur la couche type au lieu de
  ///   fabriquer un typing par défaut qui mentirait davantage.
  final BattleTypingSnapshot? typing;

  /// Statut majeur actuellement porté par ce combattant.
  ///
  /// BE7 garde cet état volontairement étroit :
  /// - `null` signifie "aucun statut majeur" ;
  /// - sinon on porte uniquement `par`, `brn`, `psn` ou `tox` ;
  /// - il n'y a toujours ni volatiles génériques, ni `slp`, ni `frz`.
  final BattleMajorStatusState? majorStatus;

  /// Sous-état volatile local strictement borné à BE8.
  ///
  /// On évite volontairement un conteneur générique :
  /// - `protectActive` pour la fenêtre de protection du tour courant ;
  /// - `mustRecharge` pour le tour perdu suivant certains moves ;
  /// - `pendingCharge` pour la deuxième moitié d'un move à charge.
  final BattleVolatileState volatileState;

  /// L'ability réellement résolue pour ce combattant.
  ///
  /// Le moteur lot 13 n'en tire toujours aucun calcul de combat. On la transporte
  /// néanmoins jusqu'à l'issue finale pour permettre au runtime de persister un
  /// Pokémon capturé à partir du vrai ennemi engagé, sans données inventées.
  final String abilityId;

  /// La liste des attaques disponibles.
  ///
  /// À partir de BE4, les moves battle transportent aussi leur PP courant :
  /// - la liste n'est donc plus seulement descriptive ;
  /// - elle porte un vrai petit état mutable-mais-immutable du point de vue
  ///   des copies de session ;
  /// - on n'ouvre toujours pas de write-back runtime des PP hors combat.
  final List<BattleMove> moves;

  /// Étages de stats actuellement appliqués à ce combattant.
  ///
  /// M8 reste volontairement borné :
  /// - on ne porte que les stats utiles au petit sous-ensemble réellement
  ///   exécutable ;
  /// - BE3 ajoute `speed` parce qu'elle devient enfin une vraie donnée moteur
  ///   pour l'ordre d'action ;
  /// - les autres mécaniques (status, weather, précision, ordre d'action
  ///   complet, etc.) restent hors scope.
  final BattleStatStages statStages;

  /// true si le combattant est K.O.
  ///
  /// Un combattant est K.O. si ses PV courants sont <= 0.
  bool get isFainted => currentHp <= 0;

  /// Crée une copie de ce combattant avec des dégâts appliqués.
  ///
  /// [damage] - La quantité de dégâts à appliquer.
  ///
  /// Les PV sont clampés entre 0 et [maxHp].
  /// Cette méthode ne modifie pas cet objet (immutable).
  BattleCombatant withDamage(int damage) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: (currentHp - damage).clamp(0, maxHp),
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie de ce combattant avec des PV restaurés.
  ///
  /// [healAmount] - La quantité de PV à restaurer.
  ///
  /// Les PV sont clampés entre 0 et [maxHp].
  /// Cette méthode ne modifie pas cet objet (immutable).
  BattleCombatant withHeal(int healAmount) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: (currentHp + healAmount).clamp(0, maxHp),
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie de ce combattant avec des changements d'étages appliqués.
  ///
  /// Les étages sont toujours clampés dans la plage canonique minimale `[-6, 6]`.
  /// M8 ne gère ici que le sous-ensemble de stats réellement exploité par le
  /// moteur battle enrichi.
  BattleCombatant withAppliedStageChanges(
    List<BattleStatStageChange> changes,
  ) {
    if (changes.isEmpty) {
      return this;
    }
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages.apply(changes),
    );
  }

  /// Crée une copie avec un slot move remplacé.
  ///
  /// BE4 évite ici une sur-architecture :
  /// - pas de nouveau sous-état `MoveState` parallèle ;
  /// - pas de map indexée future-proof ;
  /// - juste le plus petit helper honnête pour décrémenter les PP d'un slot.
  BattleCombatant withUpdatedMoveAt(int index, BattleMove updatedMove) {
    if (index < 0 || index >= moves.length) {
      throw RangeError.index(index, moves, 'index');
    }

    final updatedMoves = List<BattleMove>.of(moves);
    updatedMoves[index] = updatedMove;
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: List<BattleMove>.unmodifiable(updatedMoves),
      statStages: statStages,
    );
  }

  /// Crée une copie avec un statut majeur mis à jour.
  ///
  /// Ce helper garde la transition d'état locale et lisible :
  /// - pas de builder parallèle de combattant ;
  /// - pas de mutation silencieuse d'un objet immutable ;
  /// - juste la plus petite brique utile pour `applyStatus`, la paralysie et
  ///   les résiduels de fin de tour.
  BattleCombatant withMajorStatus(BattleMajorStatusState? updatedStatus) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: updatedStatus,
      volatileState: volatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Crée une copie avec un sous-état volatile mis à jour.
  ///
  /// BE8 garde cette transition locale et lisible :
  /// - pas de mutation silencieuse ;
  /// - pas de builder parallèle ;
  /// - juste le plus petit helper immutable utile pour `Protect`, la recharge
  ///   et les moves à charge.
  BattleCombatant withVolatileState(BattleVolatileState updatedVolatileState) {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      volatileState: updatedVolatileState,
      abilityId: abilityId,
      moves: moves,
      statStages: statStages,
    );
  }

  /// Copie la forme battle visible d'une cible pour `Transform`.
  ///
  /// Le slice legacy reste volontairement borné :
  /// - PV max/courants, statut majeur, volatiles et identité de lineup restent
  ///   ceux du lanceur ;
  /// - espèce, stats, typing, ability, stages et moves viennent de la cible ;
  /// - chaque move copié reçoit 5 PP, comme le comportement PSDK déjà porté.
  BattleCombatant withTransformedBattleFormFrom(BattleCombatant target) {
    return BattleCombatant(
      speciesId: target.speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: target.stats,
      typing: target.typing,
      majorStatus: majorStatus,
      volatileState: volatileState,
      abilityId: target.abilityId,
      moves: List<BattleMove>.unmodifiable(
        target.moves.map(
          (move) => move.withPpState(
            pp: _transformCopiedMovePp,
            currentPp: _transformCopiedMovePp,
          ),
        ),
      ),
      statStages: target.statStages,
    );
  }

  /// Prépare ce combattant à retourner en réserve après un switch.
  ///
  /// Politique BE10 explicitement bornée :
  /// - on conserve les PV courants ;
  /// - on conserve les PP courants ;
  /// - on conserve le statut majeur ;
  /// - mais on nettoie tout ce qui n'a de sens que "sur le terrain" :
  ///   stages, protect, recharge, charge en attente ;
  /// - `tox` garde le statut majeur, mais son compteur local repart à `1`
  ///   pour éviter que le switch rende BE7 mensonger.
  BattleCombatant resetForReserveOnSwitchOut() {
    return BattleCombatant(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      currentHp: currentHp,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus?.resetOnSwitchOut(),
      volatileState: volatileState.clearedOnSwitchOut(),
      abilityId: abilityId,
      moves: moves,
      statStages: const BattleStatStages(),
    );
  }
}

/// Slot battle local réellement utilisé par le moteur singles.
///
/// Phase D refuse ici le faux type décoratif :
/// - ce slot n'est pas un placeholder vide ;
/// - il porte réellement le combattant actif du side ;
/// - les requests et événements peuvent donc enfin se rattacher à un slot
///   concret sans ouvrir une topologie multi-actifs ou doubles.
final class BattleSlotState {
  BattleSlotState({
    required this.side,
    required this.slotIndex,
    required this.combatant,
  });

  BattleSlotState.active({
    required BattleSideId side,
    required BattleCombatant combatant,
  }) : this(
          side: side,
          slotIndex: 0,
          combatant: combatant,
        );

  final BattleSideId side;
  final int slotIndex;
  final BattleCombatant combatant;

  /// Référence stable vers ce slot pour les requests et traces topologiques.
  BattleSlotRef get ref => BattleSlotRef(
        side: side,
        slotIndex: slotIndex,
      );

  /// Retourne une copie du slot avec un autre combattant.
  ///
  /// Le slot reste le même :
  /// - même side ;
  /// - même index ;
  /// - seule l'occupation change lors d'un switch ou d'une résolution de tour.
  BattleSlotState withCombatant(BattleCombatant updatedCombatant) {
    return BattleSlotState(
      side: side,
      slotIndex: slotIndex,
      combatant: updatedCombatant,
    );
  }
}

/// État local d'un side singles.
///
/// Ce type est volontairement petit mais réel :
/// - un side a maintenant une identité explicite ;
/// - il porte un vrai slot actif ;
/// - il porte une réserve ordonnée ;
/// - il devient le lieu honnête des futures responsabilités side-level, sans
///   ouvrir dès maintenant side conditions/hazards/doubles.
final class BattleSideState {
  BattleSideState({
    required this.id,
    required this.activeSlot,
    this.reserve = const <BattleCombatant>[],
    this.hasStealthRock = false,
    this.spikesLayers = 0,
  })  : assert(
          activeSlot.side == id,
          'BattleSideState.activeSlot must belong to the same side.',
        ),
        assert(
          activeSlot.slotIndex == 0,
          'Phase D remains singles-only and only supports active slot 0.',
        ),
        assert(
          spikesLayers >= 0 && spikesLayers <= 3,
          'H2 Spikes remains a strict 0..3 layered slice.',
        );

  BattleSideState.player({
    required BattleCombatant active,
    List<BattleCombatant> reserve = const <BattleCombatant>[],
  }) : this(
          id: BattleSideId.player,
          activeSlot: BattleSlotState.active(
            side: BattleSideId.player,
            combatant: active,
          ),
          reserve: reserve,
        );

  BattleSideState.enemy({
    required BattleCombatant active,
    List<BattleCombatant> reserve = const <BattleCombatant>[],
  }) : this(
          id: BattleSideId.enemy,
          activeSlot: BattleSlotState.active(
            side: BattleSideId.enemy,
            combatant: active,
          ),
          reserve: reserve,
        );

  final BattleSideId id;
  final BattleSlotState activeSlot;

  /// Réserve ordonnée locale de ce side.
  ///
  /// Invariant métier conservé :
  /// - chaque membre engagé dans le combat reste présent exactement une fois ;
  /// - le slot actif ne vit pas aussi dans la réserve ;
  /// - l'ordre de réserve reste stable tant qu'un switch ne l'altère pas.
  final List<BattleCombatant> reserve;

  /// H1 ouvre le plus petit vrai état side-level vivant : Stealth Rock.
  ///
  /// Garde-fou de périmètre :
  /// - pas de conteneur générique de hazards ;
  /// - pas de liste de side conditions ;
  /// - pas de "pour plus tard" ;
  /// - juste la vérité minimale nécessaire à cette mécanique.
  final bool hasStealthRock;

  /// H2 ouvre exactement un second état side-level vivant : `Spikes`.
  ///
  /// Garde-fous de portée :
  /// - pas de conteneur générique de side conditions ;
  /// - pas de map d'hazards ;
  /// - pas de framework de couches arbitraires ;
  /// - seulement un compteur borné 0..3, parce que c'est la vérité métier
  ///   immédiatement consommée par ce lot et rien d'autre.
  final int spikesLayers;

  /// Combattant actif de ce side.
  BattleCombatant get active => activeSlot.combatant;

  /// Référence canonique du slot actif.
  BattleSlotRef get activeSlotRef => activeSlot.ref;

  BattleSideState withActive(BattleCombatant updatedActive) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot.withCombatant(updatedActive),
      reserve: reserve,
      hasStealthRock: hasStealthRock,
      spikesLayers: spikesLayers,
    );
  }

  BattleSideState withReserve(List<BattleCombatant> updatedReserve) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot,
      reserve: updatedReserve,
      hasStealthRock: hasStealthRock,
      spikesLayers: spikesLayers,
    );
  }

  BattleSideState withActiveAndReserve({
    required BattleCombatant active,
    required List<BattleCombatant> reserve,
  }) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot.withCombatant(active),
      reserve: reserve,
      hasStealthRock: hasStealthRock,
      spikesLayers: spikesLayers,
    );
  }

  BattleSideState withStealthRock(bool value) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot,
      reserve: reserve,
      hasStealthRock: value,
      spikesLayers: spikesLayers,
    );
  }

  BattleSideState withSpikesLayers(int value) {
    return BattleSideState(
      id: id,
      activeSlot: activeSlot,
      reserve: reserve,
      hasStealthRock: hasStealthRock,
      spikesLayers: value,
    );
  }
}

BattleSideState _resolveBattleStateSide({
  required BattleSideId expectedId,
  required BattleSideState? providedSide,
  required BattleCombatant? legacyActive,
  required List<BattleCombatant> legacyReserve,
  required String sideLabel,
}) {
  // Phase D choisit ici un garde-fou runtime, pas seulement un assert debug :
  // - la migration introduit deux façons de construire `BattleState` ;
  // - mélanger la nouvelle forme side-based et l'ancien chemin plat serait
  //   sinon silencieusement ambigu en release ;
  // - on préfère donc échouer explicitement plutôt que de "deviner" quelle
  //   représentation l'appelant voulait vraiment utiliser.
  if (providedSide != null &&
      (legacyActive != null || legacyReserve.isNotEmpty)) {
    throw ArgumentError(
      'BattleState.$sideLabel must be built either from $sideLabel'
      'Side or from the legacy $sideLabel/$sideLabel'
      'Reserve inputs, not both.',
    );
  }

  if (providedSide != null) {
    if (providedSide.id != expectedId) {
      throw ArgumentError(
        'BattleState.$sideLabel must carry BattleSideId.${expectedId.name}.',
      );
    }
    return providedSide;
  }

  if (legacyActive == null) {
    throw ArgumentError(
      'BattleState.$sideLabel requires either ${sideLabel}Side or '
      '$sideLabel.',
    );
  }

  return switch (expectedId) {
    BattleSideId.player => BattleSideState.player(
        active: legacyActive,
        reserve: legacyReserve,
      ),
    BattleSideId.enemy => BattleSideState.enemy(
        active: legacyActive,
        reserve: legacyReserve,
      ),
  };
}

/// Étages de stats utilisables par le moteur battle MVP enrichi.
///
/// On évite volontairement une structure générique "Map<Stat, int>" :
/// - le moteur n'a besoin que d'un petit sous-ensemble ;
/// - cette forme garde des accès simples et des invariants lisibles ;
/// - elle évite d'ouvrir de faux besoins "future-proof" trop tôt.
class BattleStatStages {
  const BattleStatStages({
    this.attack = 0,
    this.defense = 0,
    this.specialAttack = 0,
    this.specialDefense = 0,
    this.speed = 0,
  });

  final int attack;
  final int defense;
  final int specialAttack;
  final int specialDefense;
  final int speed;

  /// Retourne une copie avec les changements demandés appliqués.
  BattleStatStages apply(List<BattleStatStageChange> changes) {
    var updated = this;
    for (final change in changes) {
      updated = updated._applyOne(change);
    }
    return updated;
  }

  BattleStatStages _applyOne(BattleStatStageChange change) {
    switch (change.stat) {
      case BattleStatId.attack:
        return BattleStatStages(
          attack: _clampStage(attack + change.stages),
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.defense:
        return BattleStatStages(
          attack: attack,
          defense: _clampStage(defense + change.stages),
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.specialAttack:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: _clampStage(specialAttack + change.stages),
          specialDefense: specialDefense,
          speed: speed,
        );
      case BattleStatId.specialDefense:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: _clampStage(specialDefense + change.stages),
          speed: speed,
        );
      case BattleStatId.speed:
        return BattleStatStages(
          attack: attack,
          defense: defense,
          specialAttack: specialAttack,
          specialDefense: specialDefense,
          speed: _clampStage(speed + change.stages),
        );
    }
  }

  /// Retourne le multiplicateur utilisé par le calcul de dégâts MVP enrichi.
  ///
  /// On reprend la table canonique simplifiée des stages Pokémon :
  /// - stage 0 => 1.0
  /// - stage +1 => 1.5
  /// - stage +2 => 2.0
  /// - stage -1 => 2/3
  /// etc.
  ///
  /// Cela suffit pour rendre les boosts/débuffs battle réellement visibles,
  /// sans ouvrir les vraies stats détaillées du moteur complet.
  double multiplierFor(BattleStatId stat) {
    final stage = switch (stat) {
      BattleStatId.attack => attack,
      BattleStatId.defense => defense,
      BattleStatId.specialAttack => specialAttack,
      BattleStatId.specialDefense => specialDefense,
      BattleStatId.speed => speed,
    };
    if (stage >= 0) {
      return (2 + stage) / 2;
    }
    return 2 / (2 - stage);
  }

  int _clampStage(int value) => value.clamp(-6, 6);
}
/// Generated PSDK move registry manifest.
///
/// Do not edit entries by hand. Regenerate with:
///
/// ```bash
/// dart run tool/extract_psdk_move_registry.dart \
///   ../../pokemonsdk-development/scripts/5\ Battle \
///   ../../reports/psdk-move-porting-matrix.md \
///   --manifest lib/src/data/generated/psdk_move_registry_manifest.dart
/// ```
const psdkMoveRegistryManifest = <PsdkMoveRegistryManifestEntry>[
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_2hits',
    rubyClass: 'TwoHit',
    rubyPath: '10 Move/1 Mechanics/103 TwoHit MultiHit.rb',
    dartBehavior: 'MultiHitMoveBehavior.fixed(2)',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_2turns',
    rubyClass: 'TwoTurnBase',
    rubyPath: '10 Move/1 Mechanics/110 TwoTurnBase.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_3hits',
    rubyClass: 'ThreeHit',
    rubyPath: '10 Move/1 Mechanics/103 TwoHit MultiHit.rb',
    dartBehavior: 'MultiHitMoveBehavior.fixed(3)',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_a_fang',
    rubyClass: 'Fangs',
    rubyPath: '10 Move/2 Definitions/300 Fangs.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_absorb',
    rubyClass: 'Absorb',
    rubyPath: '10 Move/2 Definitions/300 Absorb.rb',
    dartBehavior: 'DrainMoveBehavior.absorb',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.effects, PsdkMoveDependency.item, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_acrobatics',
    rubyClass: 'Acrobatics',
    rubyPath: '10 Move/2 Definitions/300 Acrobatics.rb',
    dartBehavior: 'SpecialPowerMoveBehavior.acrobatics',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_acupressure',
    rubyClass: 'Acupressure',
    rubyPath: '10 Move/2 Definitions/300 Acupressure.rb',
    dartBehavior: 'AdvancedStatMoveBehavior.acupressure',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_add_type',
    rubyClass: 'AddThirdType',
    rubyPath: '10 Move/2 Definitions/300 AddThirdType.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_after_you',
    rubyClass: 'AfterYou',
    rubyPath: '10 Move/2 Definitions/300 After you.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_alluring_voice',
    rubyClass: 'AlluringVoice',
    rubyPath: '10 Move/2 Definitions/300 AlluringVoice.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_ally_switch',
    rubyClass: 'AllySwitch',
    rubyPath: '10 Move/2 Definitions/300 AllySwitch.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_aqua_ring',
    rubyClass: 'AquaRing',
    rubyPath: '10 Move/2 Definitions/300 AquaRing.rb',
    dartBehavior: 'PersistentEffectMoveBehavior.aquaRing',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.effects, PsdkMoveDependency.endTurn, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_assist',
    rubyClass: 'Assist',
    rubyPath: '10 Move/2 Definitions/300 Assist.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_assurance',
    rubyClass: 'Assurance',
    rubyPath: '10 Move/2 Definitions/300 Assurance.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_attract',
    rubyClass: 'Attract',
    rubyPath: '10 Move/2 Definitions/300 Attract.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_aura_wheel',
    rubyClass: 'AuraWheel',
    rubyPath: '10 Move/2 Definitions/300 AuraWheel.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_autotomize',
    rubyClass: 'Autotomize',
    rubyPath: '10 Move/2 Definitions/300 Autotomize.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_avalanche',
    rubyClass: 'Avalanche',
    rubyPath: '10 Move/2 Definitions/300 Avalanche.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_baddy_bad',
    rubyClass: 'BaddyBad',
    rubyPath: '10 Move/2 Definitions/300 GlitzyGlow.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_basic',
    rubyClass: 'Basic',
    rubyPath: '10 Move/1 Mechanics/100 Basic.rb',
    dartBehavior: 'StaticBasicMoveRegistry.s_basic',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_baton_pass',
    rubyClass: 'BatonPass',
    rubyPath: '10 Move/2 Definitions/300 BatonPass.rb',
    dartBehavior: 'SwitchEffectMoveBehavior.batonPass',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerSwitch, PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_beak_blast',
    rubyClass: 'BeakBlast',
    rubyPath: '10 Move/2 Definitions/300 PreAttackMoves.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_beat_up',
    rubyClass: 'BeatUp',
    rubyPath: '10 Move/2 Definitions/300 BeatUp.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_belch',
    rubyClass: 'Belch',
    rubyPath: '10 Move/2 Definitions/300 Belch.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_bellydrum',
    rubyClass: 'BellyDrum',
    rubyPath: '10 Move/2 Definitions/300 BellyDrum.rb',
    dartBehavior: 'RecoveryStatMoveBehavior.bellyDrum',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStat, PsdkMoveDependency.ability, PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_bestow',
    rubyClass: 'Bestow',
    rubyPath: '10 Move/2 Definitions/300 Bestow.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_bide',
    rubyClass: 'Bide',
    rubyPath: '10 Move/2 Definitions/300 Bide.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_bind',
    rubyClass: 'Bind',
    rubyPath: '10 Move/2 Definitions/300 Bind.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_bitter_malice',
    rubyClass: 'InfernalParade',
    rubyPath: '10 Move/2 Definitions/300 StatusBoostedMove.rb',
    dartBehavior: 'VariablePowerMoveBehavior.bitterMalice',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_body_press',
    rubyClass: 'BodyPress',
    rubyPath: '10 Move/2 Definitions/300 BodyPress.rb',
    dartBehavior: 'CustomStatSourceMoveBehavior.bodyPress',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.ability, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_brick_break',
    rubyClass: 'BrickBreak',
    rubyPath: '10 Move/2 Definitions/300 BrickBreak.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_brine',
    rubyClass: 'Brine',
    rubyPath: '10 Move/2 Definitions/300 Brine.rb',
    dartBehavior: 'VariablePowerMoveBehavior.brine',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_burn_up',
    rubyClass: 'BurnUp',
    rubyPath: '10 Move/2 Definitions/300 BurnUp.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_burning_jealousy',
    rubyClass: 'BurningJealousy',
    rubyPath: '10 Move/2 Definitions/300 AlluringVoice.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_camouflage',
    rubyClass: 'Camouflage',
    rubyPath: '10 Move/2 Definitions/300 Camouflage.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_cantflee',
    rubyClass: 'CantSwitch',
    rubyPath: '10 Move/2 Definitions/300 CantSwitch.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_captivate',
    rubyClass: 'Captivate',
    rubyPath: '10 Move/2 Definitions/300 Captivate.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_ceaseless_edge',
    rubyClass: 'CeaselessEdge',
    rubyPath: '10 Move/2 Definitions/300 HazardsSetting.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_change_type',
    rubyClass: 'ChangeType',
    rubyPath: '10 Move/2 Definitions/300 ChangeType.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_charge',
    rubyClass: 'Charge',
    rubyPath: '10 Move/2 Definitions/300 Charge.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_chilly_reception',
    rubyClass: 'ChillyReception',
    rubyPath: '10 Move/2 Definitions/300 ChillyReception.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_chloroblast',
    rubyClass: 'MindBlown',
    rubyPath: '10 Move/2 Definitions/300 MindBlown.rb',
    dartBehavior: 'MindBlownMoveBehavior.chloroblast',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.ability, PsdkMoveDependency.faintProcess],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_clangorous_soul',
    rubyClass: 'ClangorousSoul',
    rubyPath: '10 Move/2 Definitions/300 ClangorousSoul.rb',
    dartBehavior: 'AdvancedStatMoveBehavior.clangorousSoul',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_conversion',
    rubyClass: 'Conversion',
    rubyPath: '10 Move/2 Definitions/300 Conversion.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_conversion2',
    rubyClass: 'Conversion2',
    rubyPath: '10 Move/2 Definitions/300 Conversion.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_core_enforcer',
    rubyClass: 'CoreEnforcer',
    rubyPath: '10 Move/2 Definitions/300 CoreEnforcer.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_corrosive_gas',
    rubyClass: 'CorrosiveGas',
    rubyPath: '10 Move/2 Definitions/300 CorrosiveGas.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_counter',
    rubyClass: 'Counter',
    rubyPath: '10 Move/2 Definitions/300 Counter moves.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_court_change',
    rubyClass: 'CourtChange',
    rubyPath: '10 Move/2 Definitions/300 CourtChange.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_crafty_shield',
    rubyClass: 'CraftyShield',
    rubyPath: '10 Move/2 Definitions/300 CraftyShield.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_curse',
    rubyClass: 'Curse',
    rubyPath: '10 Move/2 Definitions/300 Curse.rb',
    dartBehavior: 'AdvancedStatMoveBehavior.curse',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.endTurn],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_custom_stats_based',
    rubyClass: 'CustomStatsBased',
    rubyPath: '10 Move/2 Definitions/300 CustomStatsBased.rb',
    dartBehavior: 'CustomStatSourceMoveBehavior.customStatsBased',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.ability, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_defog',
    rubyClass: 'Defog',
    rubyPath: '10 Move/2 Definitions/300 Defog.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_destiny_bond',
    rubyClass: 'DestinyBond',
    rubyPath: '10 Move/2 Definitions/300 DestinyBond.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_disable',
    rubyClass: 'Disable',
    rubyPath: '10 Move/2 Definitions/300 Disable.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_do_nothing',
    rubyClass: 'DoNothing',
    rubyPath: '10 Move/2 Definitions/300 Splash.rb',
    dartBehavior: 'NoEffectMoveBehavior.doNothing',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_doodle',
    rubyClass: 'Doodle',
    rubyPath: '10 Move/2 Definitions/300 AbilityChanging.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_double_iron_bash',
    rubyClass: 'DoubleIronBash',
    rubyPath: '10 Move/2 Definitions/300 DoubleIronBash.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_dragon_cheer',
    rubyClass: 'DragonCheer',
    rubyPath: '10 Move/2 Definitions/300 DragonCheer.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_dragon_darts',
    rubyClass: 'DragonDarts',
    rubyPath: '10 Move/2 Definitions/300 DragonDarts.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_dragon_tail',
    rubyClass: 'ForceSwitch',
    rubyPath: '10 Move/2 Definitions/300 ForceSwitch.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_dream_eater',
    rubyClass: 'Absorb',
    rubyPath: '10 Move/2 Definitions/300 Absorb.rb',
    dartBehavior: 'DrainMoveBehavior.dreamEater',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStatus, PsdkMoveDependency.effects, PsdkMoveDependency.item, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_echo',
    rubyClass: 'EchoedVoice',
    rubyPath: '10 Move/2 Definitions/300 EchoedVoice.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_eerie_spell',
    rubyClass: 'EerieSpell',
    rubyPath: '10 Move/2 Definitions/300 EerieSpell.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_electrify',
    rubyClass: 'Electrify',
    rubyPath: '10 Move/2 Definitions/300 Electrify.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_electro_ball',
    rubyClass: 'ElectroBall',
    rubyPath: '10 Move/2 Definitions/300 ElectroBall.rb',
    dartBehavior: 'VariablePowerMoveBehavior.electroBall',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_electro_shot',
    rubyClass: 'ElectroShot',
    rubyPath: '10 Move/2 Definitions/300 ElectroShot.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_embargo',
    rubyClass: 'Embargo',
    rubyPath: '10 Move/2 Definitions/300 Embargo.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_encore',
    rubyClass: 'Encore',
    rubyPath: '10 Move/2 Definitions/300 Encore.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_endeavor',
    rubyClass: 'Endeavor',
    rubyPath: '10 Move/2 Definitions/300 Endeavor.rb',
    dartBehavior: 'DirectHpMoveBehavior.endeavor',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_entrainment',
    rubyClass: 'Entrainment',
    rubyPath: '10 Move/2 Definitions/300 AbilityChanging.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_eruption',
    rubyClass: 'Eruption',
    rubyPath: '10 Move/2 Definitions/300 Eruption.rb',
    dartBehavior: 'VariablePowerMoveBehavior.eruption',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_expanding_force',
    rubyClass: 'ExpandingForce',
    rubyPath: '10 Move/2 Definitions/300 TerrainDamageMoves.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.terrain, PsdkMoveDependency.grounded, PsdkMoveDependency.targetingMulti],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_explosion',
    rubyClass: 'SelfDestruct',
    rubyPath: '10 Move/2 Definitions/300 SelfDestruct.rb',
    dartBehavior: 'SelfDestructMoveBehavior.explosion',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.ability, PsdkMoveDependency.faintProcess],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_facade',
    rubyClass: 'Facade',
    rubyPath: '10 Move/2 Definitions/300 StatusBoostedMove.rb',
    dartBehavior: 'VariablePowerMoveBehavior.facade',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fairy_lock',
    rubyClass: 'FairyLock',
    rubyPath: '10 Move/2 Definitions/300 FairyLock.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fake_out',
    rubyClass: 'FakeOut',
    rubyPath: '10 Move/2 Definitions/300 FakeOut.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_false_swipe',
    rubyClass: 'FalseSwipe',
    rubyPath: '10 Move/2 Definitions/300 FalseSwipe.rb',
    dartBehavior: 'BasicDamageSpecializationMoveBehavior.falseSwipe',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_feint',
    rubyClass: 'Feint',
    rubyPath: '10 Move/2 Definitions/300 Feint.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fell_stinger',
    rubyClass: 'FellStinger',
    rubyPath: '10 Move/2 Definitions/300 FellStinger.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fickle_beam',
    rubyClass: 'FickleBeam',
    rubyPath: '10 Move/2 Definitions/300 FickleBeam.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fillet_away',
    rubyClass: 'FilletAway',
    rubyPath: '10 Move/2 Definitions/300 BellyDrum.rb',
    dartBehavior: 'RecoveryStatMoveBehavior.filletAway',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStat, PsdkMoveDependency.ability, PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_final_gambit',
    rubyClass: 'FinalGambit',
    rubyPath: '10 Move/2 Definitions/300 FinalGambit.rb',
    dartBehavior: 'DirectHpMoveBehavior.finalGambit',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.faintProcess, PsdkMoveDependency.history],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fishious_rend',
    rubyClass: 'FishiousRend',
    rubyPath: '10 Move/2 Definitions/300 FishiousRend.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fixed_damage',
    rubyClass: 'FixedDamages',
    rubyPath: '10 Move/2 Definitions/300 FixedDamages.rb',
    dartBehavior: 'FixedDamageMoveBehavior.psdkFixedDamage',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_flail',
    rubyClass: 'Flail',
    rubyPath: '10 Move/2 Definitions/300 Flail.rb',
    dartBehavior: 'VariablePowerMoveBehavior.flail',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_flame_burst',
    rubyClass: 'FlameBurst',
    rubyPath: '10 Move/2 Definitions/300 FlameBurst.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fling',
    rubyClass: 'Fling',
    rubyPath: '10 Move/2 Definitions/300 Fling.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_floral_healing',
    rubyClass: 'FloralHealing',
    rubyPath: '10 Move/2 Definitions/300 FloralHealing.rb',
    dartBehavior: 'HealMoveBehavior.floralHealing',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.terrain, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_flower_shield',
    rubyClass: 'FlowerShield',
    rubyPath: '10 Move/2 Definitions/300 FlowerShield.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_flying_press',
    rubyClass: 'FlyingPress',
    rubyPath: '10 Move/2 Definitions/300 FlyingPress.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_focus_energy',
    rubyClass: 'FocusEnergy',
    rubyPath: '10 Move/2 Definitions/300 FocusEnergy.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_focus_punch',
    rubyClass: 'FocusPunch',
    rubyPath: '10 Move/2 Definitions/300 PreAttackMoves.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_follow_me',
    rubyClass: 'FollowMe',
    rubyPath: '10 Move/2 Definitions/300 FollowMe.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_foresight',
    rubyClass: 'Foresight',
    rubyPath: '10 Move/2 Definitions/300 Foresight.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_foul_play',
    rubyClass: 'FoulPlay',
    rubyPath: '10 Move/2 Definitions/300 FoulPlay.rb',
    dartBehavior: 'CustomStatSourceMoveBehavior.foulPlay',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.ability, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_freezy_frost',
    rubyClass: 'FreezyFrost',
    rubyPath: '10 Move/2 Definitions/300 FreezyFrost.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_frustration',
    rubyClass: 'Frustration',
    rubyPath: '10 Move/2 Definitions/300 Frustration.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_full_crit',
    rubyClass: 'FullCrit',
    rubyPath: '10 Move/2 Definitions/300 FullCrit.rb',
    dartBehavior: 'BasicDamageSpecializationMoveBehavior.fullCrit',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fury_cutter',
    rubyClass: 'FuryCutter',
    rubyPath: '10 Move/2 Definitions/300 FuryCutter.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fusion_bolt',
    rubyClass: 'FusionBolt',
    rubyPath: '10 Move/2 Definitions/300 FusionFlareBolt.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_fusion_flare',
    rubyClass: 'FusionFlare',
    rubyPath: '10 Move/2 Definitions/300 FusionFlareBolt.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_future_sight',
    rubyClass: 'FutureSight',
    rubyPath: '10 Move/2 Definitions/300 FutureSight.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_gastro_acid',
    rubyClass: 'GastroAcid',
    rubyPath: '10 Move/2 Definitions/300 GastroAcid.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_gear_up',
    rubyClass: 'GearUp',
    rubyPath: '10 Move/2 Definitions/300 GearUp.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_genies_storm',
    rubyClass: 'GeniesStorm',
    rubyPath: '10 Move/2 Definitions/300 GeniesStorm.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_geomancy',
    rubyClass: 'Geomancy',
    rubyPath: '10 Move/2 Definitions/300 Geomancy.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_gigaton_hammer',
    rubyClass: 'GigatonHammer',
    rubyPath: '10 Move/2 Definitions/300 GigatonHammer.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_glaive_rush',
    rubyClass: 'GlaiveRush',
    rubyPath: '10 Move/2 Definitions/300 GlaiveRush.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_glitzy_glow',
    rubyClass: 'GlitzyGlow',
    rubyPath: '10 Move/2 Definitions/300 GlitzyGlow.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_grassy_glide',
    rubyClass: 'GrassyGlide',
    rubyPath: '10 Move/2 Definitions/300 TerrainDamageMoves.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.terrain, PsdkMoveDependency.grounded, PsdkMoveDependency.actionOrder],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_grav_apple',
    rubyClass: 'GravApple',
    rubyPath: '10 Move/2 Definitions/300 GravApple.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_gravity',
    rubyClass: 'Gravity',
    rubyPath: '10 Move/2 Definitions/300 Gravity.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_growth',
    rubyClass: 'Growth',
    rubyPath: '10 Move/2 Definitions/300 Growth.rb',
    dartBehavior: 'AdvancedStatMoveBehavior.growth',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStat, PsdkMoveDependency.weather, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_grudge',
    rubyClass: 'Grudge',
    rubyPath: '10 Move/2 Definitions/300 Grudge.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_guard_split',
    rubyClass: 'GuardSplit',
    rubyPath: '10 Move/2 Definitions/300 Stages split moves.rb',
    dartBehavior: 'StatSplitMoveBehavior.guard',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_guard_swap',
    rubyClass: 'GuardSwap',
    rubyPath: '10 Move/2 Definitions/300 Stages swap moves.rb',
    dartBehavior: 'AdvancedStatMoveBehavior.guardSwap',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_gyro_ball',
    rubyClass: 'GyroBall',
    rubyPath: '10 Move/2 Definitions/300 GyroBall.rb',
    dartBehavior: 'VariablePowerMoveBehavior.gyroBall',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_happy_hour',
    rubyClass: 'HappyHour',
    rubyPath: '10 Move/2 Definitions/300 HappyHour.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_hard_press',
    rubyClass: 'HardPress',
    rubyPath: '10 Move/2 Definitions/300 WringOut.rb',
    dartBehavior: 'VariablePowerMoveBehavior.hardPress',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_haze',
    rubyClass: 'Haze',
    rubyPath: '10 Move/2 Definitions/300 Haze.rb',
    dartBehavior: 'AdvancedStatMoveBehavior.haze',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability, PsdkMoveDependency.targetingMulti],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_heal',
    rubyClass: 'HealMove',
    rubyPath: '10 Move/1 Mechanics/105 Heal.rb',
    dartBehavior: 'HealMoveBehavior',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_heal_bell',
    rubyClass: 'HealBell',
    rubyPath: '10 Move/2 Definitions/300 HealBell.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_heal_block',
    rubyClass: 'HealBlock',
    rubyPath: '10 Move/2 Definitions/300 HealBlock.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_heal_weather',
    rubyClass: 'HealWeather',
    rubyPath: '10 Move/2 Definitions/300 HealWeather.rb',
    dartBehavior: 'HealMoveBehavior.weather',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.weather, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_healing_wish',
    rubyClass: 'HealingWish',
    rubyPath: '10 Move/2 Definitions/300 HealingSacrifice.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_heart_swap',
    rubyClass: 'HeartSwap',
    rubyPath: '10 Move/2 Definitions/300 Stages swap moves.rb',
    dartBehavior: 'AdvancedStatMoveBehavior.heartSwap',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_heavy_slam',
    rubyClass: 'HeavySlam',
    rubyPath: '10 Move/2 Definitions/300 HeavySlam.rb',
    dartBehavior: 'WeightPowerMoveBehavior.heavySlam',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_helping_hand',
    rubyClass: 'HelpingHand',
    rubyPath: '10 Move/2 Definitions/300 HelpingHand.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_hex',
    rubyClass: 'Hex',
    rubyPath: '10 Move/2 Definitions/300 Hex.rb',
    dartBehavior: 'VariablePowerMoveBehavior.hex',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.ability, PsdkMoveDependency.handlerStatus],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_hidden_power',
    rubyClass: 'HiddenPower',
    rubyPath: '10 Move/2 Definitions/300 HiddenPower.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_hp_eq_level',
    rubyClass: 'HPEqLevel',
    rubyPath: '10 Move/2 Definitions/300 HPEqLevel.rb',
    dartBehavior: 'FixedDamageMoveBehavior.userLevel',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_hurricane',
    rubyClass: 'Thunder',
    rubyPath: '10 Move/2 Definitions/300 Thunder.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_ice_ball',
    rubyClass: 'Rollout',
    rubyPath: '10 Move/2 Definitions/300 Rollout.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_ice_spinner',
    rubyClass: 'IceSpinner',
    rubyPath: '10 Move/2 Definitions/300 IceSpinner SteelRoller.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_imprison',
    rubyClass: 'Imprison',
    rubyPath: '10 Move/2 Definitions/300 Imprison.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_incinerate',
    rubyClass: 'Incinerate',
    rubyPath: '10 Move/2 Definitions/300 Incinerate.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_infernal_parade',
    rubyClass: 'InfernalParade',
    rubyPath: '10 Move/2 Definitions/300 StatusBoostedMove.rb',
    dartBehavior: 'VariablePowerMoveBehavior.infernalParade',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_ingrain',
    rubyClass: 'Ingrain',
    rubyPath: '10 Move/2 Definitions/300 Ingrain.rb',
    dartBehavior: 'PersistentEffectMoveBehavior.ingrain',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerSwitch, PsdkMoveDependency.effects, PsdkMoveDependency.endTurn, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_instruct',
    rubyClass: 'Instruct',
    rubyPath: '10 Move/2 Definitions/300 Instruct.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_ion_deluge',
    rubyClass: 'IonDeluge',
    rubyPath: '10 Move/2 Definitions/300 Ion Deluge.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_ivy_cudgel',
    rubyClass: 'IvyCudgel',
    rubyPath: '10 Move/2 Definitions/300 IvyCudgel.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_jaw_lock',
    rubyClass: 'JawLock',
    rubyPath: '10 Move/2 Definitions/300 JawLock.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_judgment',
    rubyClass: 'Judgment',
    rubyPath: '10 Move/2 Definitions/300 Judgment.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_jump_kick',
    rubyClass: 'HighJumpKick',
    rubyPath: '10 Move/2 Definitions/300 HighJumpKick.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_jungle_healing',
    rubyClass: 'JungleHealing',
    rubyPath: '10 Move/2 Definitions/300 LifeDew.rb',
    dartBehavior: 'HealMoveBehavior.jungleHealing',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStatus, PsdkMoveDependency.effects, PsdkMoveDependency.targetingMulti],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_knock_off',
    rubyClass: 'KnockOff',
    rubyPath: '10 Move/2 Definitions/300 KnockOff.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_laser_focus',
    rubyClass: 'LaserFocus',
    rubyPath: '10 Move/2 Definitions/300 LaserFocus.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_lash_out',
    rubyClass: 'LashOut',
    rubyPath: '10 Move/2 Definitions/300 LashOut.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_last_resort',
    rubyClass: 'LastResort',
    rubyPath: '10 Move/2 Definitions/300 LastResort.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_last_respects',
    rubyClass: 'LastRespects',
    rubyPath: '10 Move/2 Definitions/300 LastRespects.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_leech_seed',
    rubyClass: 'LeechSeed',
    rubyPath: '10 Move/2 Definitions/300 LeechSeed.rb',
    dartBehavior: 'PersistentEffectMoveBehavior.leechSeed',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.effects, PsdkMoveDependency.endTurn, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_life_dew',
    rubyClass: 'LifeDew',
    rubyPath: '10 Move/2 Definitions/300 LifeDew.rb',
    dartBehavior: 'HealMoveBehavior.lifeDew',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.effects, PsdkMoveDependency.targetingMulti],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_lock_on',
    rubyClass: 'LockOn',
    rubyPath: '10 Move/2 Definitions/300 LockOn.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_low_kick',
    rubyClass: 'LowKick',
    rubyPath: '10 Move/2 Definitions/300 LowKick.rb',
    dartBehavior: 'WeightPowerMoveBehavior.lowKick',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.effects, PsdkMoveDependency.ability, PsdkMoveDependency.grounded],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_lucky_chant',
    rubyClass: 'LuckyChant',
    rubyPath: '10 Move/2 Definitions/300 LuckyChant.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_lunar_dance',
    rubyClass: 'LunarDance',
    rubyPath: '10 Move/2 Definitions/300 HealingSacrifice.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_magic_coat',
    rubyClass: 'MagicCoat',
    rubyPath: '10 Move/2 Definitions/300 MagicCoat.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_magic_powder',
    rubyClass: 'MagicPowder',
    rubyPath: '10 Move/2 Definitions/300 MagicPowder.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_magic_room',
    rubyClass: 'MagicRoom',
    rubyPath: '10 Move/2 Definitions/300 MagicRoom.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_magnet_rise',
    rubyClass: 'MagnetRise',
    rubyPath: '10 Move/2 Definitions/300 MagnetRise.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_magnetic_flux',
    rubyClass: 'MagneticFlux',
    rubyPath: '10 Move/2 Definitions/300 MagneticFlux.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_magnitude',
    rubyClass: 'Magnitude',
    rubyPath: '10 Move/2 Definitions/300 Magnitude.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_make_it_rain',
    rubyClass: 'MakeItRain',
    rubyPath: '10 Move/2 Definitions/300 MakeItRain.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_me_first',
    rubyClass: 'MeFirst',
    rubyPath: '10 Move/2 Definitions/300 Me First.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_memento',
    rubyClass: 'Memento',
    rubyPath: '10 Move/2 Definitions/300 Memento.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_metal_burst',
    rubyClass: 'MetalBurst',
    rubyPath: '10 Move/2 Definitions/300 Counter moves.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_metronome',
    rubyClass: 'Metronome',
    rubyPath: '10 Move/2 Definitions/300 Metronome.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_mimic',
    rubyClass: 'Mimic',
    rubyPath: '10 Move/2 Definitions/300 Mimic.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_mind_blown',
    rubyClass: 'MindBlown',
    rubyPath: '10 Move/2 Definitions/300 MindBlown.rb',
    dartBehavior: 'MindBlownMoveBehavior.mindBlown',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.ability, PsdkMoveDependency.faintProcess],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_mind_reader',
    rubyClass: 'LockOn',
    rubyPath: '10 Move/2 Definitions/300 LockOn.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_minimize',
    rubyClass: 'Minimize',
    rubyPath: '10 Move/2 Definitions/300 Minimize.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_miracle_eye',
    rubyClass: 'MiracleEye',
    rubyPath: '10 Move/2 Definitions/300 MiracleEye.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_mirror_coat',
    rubyClass: 'MirrorCoat',
    rubyPath: '10 Move/2 Definitions/300 Counter moves.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_mirror_move',
    rubyClass: 'MirrorMove',
    rubyPath: '10 Move/2 Definitions/300 MirrorMove.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_mist',
    rubyClass: 'Mist',
    rubyPath: '10 Move/2 Definitions/300 Mist.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_misty_explosion',
    rubyClass: 'MistyExplosion',
    rubyPath: '10 Move/2 Definitions/300 TerrainDamageMoves.rb',
    dartBehavior: 'SelfDestructMoveBehavior.mistyExplosion',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.ability, PsdkMoveDependency.faintProcess, PsdkMoveDependency.terrain, PsdkMoveDependency.grounded],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_multi_attack',
    rubyClass: 'MultiAttack',
    rubyPath: '10 Move/2 Definitions/300 MultiAttack.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_multi_hit',
    rubyClass: 'MultiHit',
    rubyPath: '10 Move/1 Mechanics/103 TwoHit MultiHit.rb',
    dartBehavior: 'MultiHitMoveBehavior.psdkRandom',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.ability, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_natural_gift',
    rubyClass: 'NaturalGift',
    rubyPath: '10 Move/2 Definitions/300 NaturalGift.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_nature_power',
    rubyClass: 'NaturePower',
    rubyPath: '10 Move/2 Definitions/300 NaturePower.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_nightmare',
    rubyClass: 'Nightmare',
    rubyPath: '10 Move/2 Definitions/300 Nightmare.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_no_retreat',
    rubyClass: 'NoRetreat',
    rubyPath: '10 Move/2 Definitions/300 NoRetreat.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_octolock',
    rubyClass: 'Octolock',
    rubyPath: '10 Move/2 Definitions/300 Octolock.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_ohko',
    rubyClass: 'OHKO',
    rubyPath: '10 Move/2 Definitions/300 OHKO.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_order_up',
    rubyClass: 'OrderUp',
    rubyPath: '10 Move/2 Definitions/300 OrderUp.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_outrage',
    rubyClass: 'Thrash',
    rubyPath: '10 Move/2 Definitions/300 Thrash.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_pain_split',
    rubyClass: 'PainSplit',
    rubyPath: '10 Move/2 Definitions/300 PainSplit.rb',
    dartBehavior: 'DirectHpMoveBehavior.painSplit',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_parting_shot',
    rubyClass: 'PartingShot',
    rubyPath: '10 Move/2 Definitions/300 PartingShot.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_payback',
    rubyClass: 'PayBack',
    rubyPath: '10 Move/2 Definitions/300 PayBack.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_payday',
    rubyClass: 'PayDay',
    rubyPath: '10 Move/2 Definitions/300 Payday.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_perish_song',
    rubyClass: 'PerishSong',
    rubyPath: '10 Move/2 Definitions/300 PerishSong.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_photon_geyser',
    rubyClass: 'PhotonGeyser',
    rubyPath: '10 Move/2 Definitions/300 PhotonGeyser.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_plasma_fists',
    rubyClass: 'PlasmaFists',
    rubyPath: '10 Move/2 Definitions/300 PlasmaFists.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_pledge',
    rubyClass: 'Pledge',
    rubyPath: '10 Move/1 Mechanics/130 Pledge.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_pluck',
    rubyClass: 'Pluck',
    rubyPath: '10 Move/2 Definitions/300 Pluck.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_pollen_puff',
    rubyClass: 'PollenPuff',
    rubyPath: '10 Move/2 Definitions/300 PollenPuff.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_poltergeist',
    rubyClass: 'Poltergeist',
    rubyPath: '10 Move/2 Definitions/300 Poltergeist.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_population_bomb',
    rubyClass: 'PopulationBomb',
    rubyPath: '10 Move/1 Mechanics/103 TwoHit MultiHit.rb',
    dartBehavior: 'MultiHitMoveBehavior.populationBomb',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.ability, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_powder',
    rubyClass: 'Powder',
    rubyPath: '10 Move/2 Definitions/300 Powder.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_power_split',
    rubyClass: 'PowerSplit',
    rubyPath: '10 Move/2 Definitions/300 Stages split moves.rb',
    dartBehavior: 'StatSplitMoveBehavior.power',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_power_swap',
    rubyClass: 'PowerSwap',
    rubyPath: '10 Move/2 Definitions/300 Stages swap moves.rb',
    dartBehavior: 'AdvancedStatMoveBehavior.powerSwap',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_power_trick',
    rubyClass: 'PowerTrick',
    rubyPath: '10 Move/2 Definitions/300 PowerTrick.rb',
    dartBehavior: 'PowerTrickMoveBehavior',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_pre_attack_base',
    rubyClass: 'PreAttackBase',
    rubyPath: '10 Move/2 Definitions/300 PreAttackMoves.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_present',
    rubyClass: 'Present',
    rubyPath: '10 Move/2 Definitions/300 Present.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_protect',
    rubyClass: 'Protect',
    rubyPath: '10 Move/2 Definitions/300 Protect.rb',
    dartBehavior: 'StaticBasicMoveRegistry.s_protect',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_psych_up',
    rubyClass: 'PsychUp',
    rubyPath: '10 Move/2 Definitions/300 PsychUp.rb',
    dartBehavior: 'AdvancedStatMoveBehavior.psychUp',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_psychic_noise',
    rubyClass: 'PsychicNoise',
    rubyPath: '10 Move/2 Definitions/300 PsychicNoise.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_psycho_shift',
    rubyClass: 'PsychoShift',
    rubyPath: '10 Move/2 Definitions/300 PsychoShift.rb',
    dartBehavior: 'PsychoShiftMoveBehavior',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStatus, PsdkMoveDependency.effects, PsdkMoveDependency.ability, PsdkMoveDependency.targetingMulti],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_psyshock',
    rubyClass: 'CustomStatsBased',
    rubyPath: '10 Move/2 Definitions/300 CustomStatsBased.rb',
    dartBehavior: 'CustomStatSourceMoveBehavior.psyshock',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.ability, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_psywave',
    rubyClass: 'Psywave',
    rubyPath: '10 Move/2 Definitions/300 HPEqLevel.rb',
    dartBehavior: 'FixedDamageMoveBehavior.psywave',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_purify',
    rubyClass: 'Purify',
    rubyPath: '10 Move/2 Definitions/300 Purify.rb',
    dartBehavior: 'PurifyMoveBehavior',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStatus, PsdkMoveDependency.effects, PsdkMoveDependency.targetingMulti],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_pursuit',
    rubyClass: 'Pursuit',
    rubyPath: '10 Move/2 Definitions/300 Pursuit.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_quash',
    rubyClass: 'Quash',
    rubyPath: '10 Move/2 Definitions/300 Quash.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_rage',
    rubyClass: 'Rage',
    rubyPath: '10 Move/2 Definitions/300 Rage.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_rage_fist',
    rubyClass: 'RageFist',
    rubyPath: '10 Move/2 Definitions/300 RageFist.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_raging_bull',
    rubyClass: 'RagingBull',
    rubyPath: '10 Move/2 Definitions/300 BrickBreak.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_rapid_spin',
    rubyClass: 'RapidSpin',
    rubyPath: '10 Move/2 Definitions/300 RapidSpin.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_recoil',
    rubyClass: 'RecoilMove',
    rubyPath: '10 Move/2 Definitions/300 RecoilMove.rb',
    dartBehavior: 'RecoilMoveBehavior.psdkRecoil',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.ability, PsdkMoveDependency.item, PsdkMoveDependency.history],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_recycle',
    rubyClass: 'Recycle',
    rubyPath: '10 Move/2 Definitions/300 Recycle.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_reflect',
    rubyClass: 'Reflect',
    rubyPath: '10 Move/2 Definitions/300 LightScreen Reflect.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_reflect_type',
    rubyClass: 'ReflectType',
    rubyPath: '10 Move/2 Definitions/300 ReflectType.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_relic_song',
    rubyClass: 'RelicSong',
    rubyPath: '10 Move/2 Definitions/300 RelicSong.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_reload',
    rubyClass: 'Reload',
    rubyPath: '10 Move/2 Definitions/300 Reload.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_rest',
    rubyClass: 'Rest',
    rubyPath: '10 Move/2 Definitions/300 Rest.rb',
    dartBehavior: 'RecoveryStatMoveBehavior.rest',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStatus, PsdkMoveDependency.handlerDamage, PsdkMoveDependency.effects, PsdkMoveDependency.ability, PsdkMoveDependency.terrain, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_retaliate',
    rubyClass: 'Retaliate',
    rubyPath: '10 Move/2 Definitions/300 Retaliate.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_return',
    rubyClass: 'Return',
    rubyPath: '10 Move/2 Definitions/300 Return.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_revelation_dance',
    rubyClass: 'RevelationDance',
    rubyPath: '10 Move/2 Definitions/300 RevelationDance.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_revenge',
    rubyClass: 'Revenge',
    rubyPath: '10 Move/2 Definitions/300 Revenge.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_revival_blessing',
    rubyClass: 'RevivalBlessing',
    rubyPath: '10 Move/2 Definitions/300 RevivalBlessing.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_rising_voltage',
    rubyClass: 'RisingVoltage',
    rubyPath: '10 Move/2 Definitions/300 TerrainDamageMoves.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.terrain, PsdkMoveDependency.grounded],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_roar',
    rubyClass: 'ForceSwitch',
    rubyPath: '10 Move/2 Definitions/300 ForceSwitch.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_role_play',
    rubyClass: 'RolePlay',
    rubyPath: '10 Move/2 Definitions/300 AbilityChanging.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_rollout',
    rubyClass: 'Rollout',
    rubyPath: '10 Move/2 Definitions/300 Rollout.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_roost',
    rubyClass: 'Roost',
    rubyPath: '10 Move/2 Definitions/300 Roost.rb',
    dartBehavior: 'HealMoveBehavior.roost',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_rototiller',
    rubyClass: 'Rototiller',
    rubyPath: '10 Move/2 Definitions/300 Rototiller.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_round',
    rubyClass: 'Round',
    rubyPath: '10 Move/2 Definitions/300 Round.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_sacred_sword',
    rubyClass: 'SacredSword',
    rubyPath: '10 Move/2 Definitions/300 SacredSword.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_safe_guard',
    rubyClass: 'Safeguard',
    rubyPath: '10 Move/2 Definitions/300 Safeguard.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_salt_cure',
    rubyClass: 'SaltCure',
    rubyPath: '10 Move/2 Definitions/300 SaltCure.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_sappy_seed',
    rubyClass: 'SappySeed',
    rubyPath: '10 Move/2 Definitions/300 SappySeed.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_scale_shot',
    rubyClass: 'ScaleShot',
    rubyPath: '10 Move/2 Definitions/300 ScaleShot.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_secret_power',
    rubyClass: 'SecretPower',
    rubyPath: '10 Move/2 Definitions/300 SecretPower.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_self_stat',
    rubyClass: 'SelfStat',
    rubyPath: '10 Move/1 Mechanics/101 Self.rb',
    dartBehavior: 'StatusStatMoveBehavior.selfStat',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_self_status',
    rubyClass: 'SelfStatus',
    rubyPath: '10 Move/1 Mechanics/101 Self.rb',
    dartBehavior: 'StatusStatMoveBehavior.selfStatus',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStatus, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_shed_tail',
    rubyClass: 'ShedTail',
    rubyPath: '10 Move/2 Definitions/300 Substitute.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_shell_side_arm',
    rubyClass: 'ShellSideArm',
    rubyPath: '10 Move/2 Definitions/300 ShellSideArm.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_shell_trap',
    rubyClass: 'ShellTrap',
    rubyPath: '10 Move/2 Definitions/300 PreAttackMoves.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_shore_up',
    rubyClass: 'ShoreUp',
    rubyPath: '10 Move/2 Definitions/300 Shore Up.rb',
    dartBehavior: 'HealMoveBehavior.shoreUp',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.weather, PsdkMoveDependency.handlerDamage, PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_simple_beam',
    rubyClass: 'SimpleBeam',
    rubyPath: '10 Move/2 Definitions/300 AbilityChanging.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_sketch',
    rubyClass: 'Sketch',
    rubyPath: '10 Move/2 Definitions/300 Sketch.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_skill_swap',
    rubyClass: 'SkillSwap',
    rubyPath: '10 Move/2 Definitions/300 AbilityChanging.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_sky_drop',
    rubyClass: 'SkyDrop',
    rubyPath: '10 Move/2 Definitions/300 SkyDrop.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_sleep_talk',
    rubyClass: 'SleepTalk',
    rubyPath: '10 Move/2 Definitions/300 SleepTalk.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_smack_down',
    rubyClass: 'SmackDown',
    rubyPath: '10 Move/2 Definitions/300 SmackDown.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_smelling_salt',
    rubyClass: 'SmellingSalts',
    rubyPath: '10 Move/2 Definitions/300 HitThenCureStatus.rb',
    dartBehavior: 'HitThenCureStatusMoveBehavior.smellingSalt',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStatus, PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_snatch',
    rubyClass: 'Snatch',
    rubyPath: '10 Move/2 Definitions/300 Snatch.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_snore',
    rubyClass: 'Snore',
    rubyPath: '10 Move/2 Definitions/300 Snore.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_solar_beam',
    rubyClass: 'SolarBeam',
    rubyPath: '10 Move/2 Definitions/300 SolarBeam.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.weather, PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_sparkling_aria',
    rubyClass: 'SparklingAria',
    rubyPath: '10 Move/2 Definitions/300 SparklingAria.rb',
    dartBehavior: 'HitThenCureStatusMoveBehavior.sparklingAria',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStatus, PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_sparkly_swirl',
    rubyClass: 'SparklySwirl',
    rubyPath: '10 Move/2 Definitions/300 SparklySwirl.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_spectral_thief',
    rubyClass: 'SpectralThief',
    rubyPath: '10 Move/2 Definitions/300 SpectralThief.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_speed_swap',
    rubyClass: 'SpeedSwap',
    rubyPath: '10 Move/2 Definitions/300 Stages swap moves.rb',
    dartBehavior: 'SpeedSwapMoveBehavior',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_spike',
    rubyClass: 'Spikes',
    rubyPath: '10 Move/2 Definitions/300 Spikes.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_spite',
    rubyClass: 'Spite',
    rubyPath: '10 Move/2 Definitions/300 Spite.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_splash',
    rubyClass: 'Splash',
    rubyPath: '10 Move/2 Definitions/300 Splash.rb',
    dartBehavior: 'NoEffectMoveBehavior.splash',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_split_up',
    rubyClass: 'SpitUp',
    rubyPath: '10 Move/2 Definitions/300 SpitUp.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_stat',
    rubyClass: 'StatusStat',
    rubyPath: '10 Move/1 Mechanics/102 Status Stat.rb',
    dartBehavior: 'StatusStatMoveBehavior.stat',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStatus, PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_status',
    rubyClass: 'StatusStat',
    rubyPath: '10 Move/1 Mechanics/102 Status Stat.rb',
    dartBehavior: 'StatusStatMoveBehavior.status',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStatus, PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_stealth_rock',
    rubyClass: 'StealthRock',
    rubyPath: '10 Move/2 Definitions/300 StealthRock.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_steel_beam',
    rubyClass: 'MindBlown',
    rubyPath: '10 Move/2 Definitions/300 MindBlown.rb',
    dartBehavior: 'MindBlownMoveBehavior.steelBeam',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.ability, PsdkMoveDependency.faintProcess],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_steel_roller',
    rubyClass: 'SteelRoller',
    rubyPath: '10 Move/2 Definitions/300 IceSpinner SteelRoller.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_sticky_web',
    rubyClass: 'StickyWeb',
    rubyPath: '10 Move/2 Definitions/300 StickyWeb.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_stockpile',
    rubyClass: 'Stockpile',
    rubyPath: '10 Move/2 Definitions/300 Stockpile.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_stomp',
    rubyClass: 'Stomp',
    rubyPath: '10 Move/2 Definitions/300 Stomp.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_stomping_tantrum',
    rubyClass: 'StompingTantrum',
    rubyPath: '10 Move/2 Definitions/300 StompingTantrum.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_stone_axe',
    rubyClass: 'StoneAxe',
    rubyPath: '10 Move/2 Definitions/300 HazardsSetting.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_stored_power',
    rubyClass: 'StoredPower',
    rubyPath: '10 Move/2 Definitions/300 StoredPower.rb',
    dartBehavior: 'SpecialPowerMoveBehavior.storedPower',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_strength_sap',
    rubyClass: 'StrengthSap',
    rubyPath: '10 Move/2 Definitions/300 StrengthSap.rb',
    dartBehavior: 'RecoveryStatMoveBehavior.strengthSap',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStat, PsdkMoveDependency.ability, PsdkMoveDependency.item, PsdkMoveDependency.effects],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_struggle',
    rubyClass: 'Struggle',
    rubyPath: '10 Move/2 Definitions/300 RecoilMove.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_stuff_cheeks',
    rubyClass: 'StuffCheeks',
    rubyPath: '10 Move/2 Definitions/300 StuffCheeks.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_substitute',
    rubyClass: 'Substitute',
    rubyPath: '10 Move/2 Definitions/300 Substitute.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_sucker_punch',
    rubyClass: 'SuckerPunch',
    rubyPath: '10 Move/2 Definitions/300 SuckerPunch.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_super_duper_effective',
    rubyClass: 'SuperDuperEffective',
    rubyPath: '10 Move/2 Definitions/300 SuperDuperEffective.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_super_fang',
    rubyClass: 'SuperFang',
    rubyPath: '10 Move/2 Definitions/300 SuperFang.rb',
    dartBehavior: 'FixedDamageMoveBehavior.halfCurrentTargetHp',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_swallow',
    rubyClass: 'Swallow',
    rubyPath: '10 Move/2 Definitions/300 Swallow.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_synchronoise',
    rubyClass: 'Synchronoise',
    rubyPath: '10 Move/2 Definitions/300 Synchronoise.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_syrup_bomb',
    rubyClass: 'SyrupBomb',
    rubyPath: '10 Move/2 Definitions/300 SyrupBomb.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_tailwind',
    rubyClass: 'Tailwind',
    rubyPath: '10 Move/2 Definitions/300 Tailwind.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_take_heart',
    rubyClass: 'TakeHeart',
    rubyPath: '10 Move/2 Definitions/300 TakeHeart.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_tar_shot',
    rubyClass: 'TarShot',
    rubyPath: '10 Move/2 Definitions/300 TarShot.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_taunt',
    rubyClass: 'Taunt',
    rubyPath: '10 Move/2 Definitions/300 Taunt.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_teatime',
    rubyClass: 'Teatime',
    rubyPath: '10 Move/2 Definitions/300 TeaTime.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_techno_blast',
    rubyClass: 'TechnoBlast',
    rubyPath: '10 Move/2 Definitions/300 TechnoBlast.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_telekinesis',
    rubyClass: 'Telekinesis',
    rubyPath: '10 Move/2 Definitions/300 Telekinesis.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_teleport',
    rubyClass: 'Teleport',
    rubyPath: '10 Move/2 Definitions/300 Teleport.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_terrain',
    rubyClass: 'TerrainMove',
    rubyPath: '10 Move/2 Definitions/300 TerrainMove.rb',
    dartBehavior: 'TerrainMoveBehavior',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerTerrain, PsdkMoveDependency.terrain, PsdkMoveDependency.effects, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_terrain_boosting',
    rubyClass: 'TerrainBoosting',
    rubyPath: '10 Move/2 Definitions/300 TerrainBoosting.rb',
    dartBehavior: 'TerrainPowerMoveBehavior.terrainBoosting',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_terrain_pulse',
    rubyClass: 'TerrainPulse',
    rubyPath: '10 Move/2 Definitions/300 TerrainPulse.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.terrain, PsdkMoveDependency.grounded],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_thief',
    rubyClass: 'Thief',
    rubyPath: '10 Move/2 Definitions/300 Thief.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_thing_sport',
    rubyClass: 'MudSport',
    rubyPath: '10 Move/2 Definitions/300 MudSport.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_thrash',
    rubyClass: 'Thrash',
    rubyPath: '10 Move/2 Definitions/300 Thrash.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_throat_chop',
    rubyClass: 'ThroatChop',
    rubyPath: '10 Move/2 Definitions/300 ThroatChop.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_thunder',
    rubyClass: 'Thunder',
    rubyPath: '10 Move/2 Definitions/300 Thunder.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.weather],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_tidy_up',
    rubyClass: 'TidyUp',
    rubyPath: '10 Move/2 Definitions/300 TidyUp.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_topsy_turvy',
    rubyClass: 'TopsyTurvy',
    rubyPath: '10 Move/2 Definitions/300 TopsyTurvy.rb',
    dartBehavior: 'AdvancedStatMoveBehavior.topsyTurvy',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerStat, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_torment',
    rubyClass: 'Torment',
    rubyPath: '10 Move/2 Definitions/300 Torment.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_toxic_spike',
    rubyClass: 'ToxicSpikes',
    rubyPath: '10 Move/2 Definitions/300 Toxic_Spikes.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_toxic_thread',
    rubyClass: 'ToxicThread',
    rubyPath: '10 Move/2 Definitions/300 ToxicThread.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_transform',
    rubyClass: 'Transform',
    rubyPath: '10 Move/2 Definitions/300 Transform.rb',
    dartBehavior: 'TransformMoveBehavior',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerSwitch, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_tri_attack',
    rubyClass: 'TriAttack',
    rubyPath: '10 Move/2 Definitions/300 TriAttack.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_trick',
    rubyClass: 'Switcheroo',
    rubyPath: '10 Move/2 Definitions/300 Switcheroo.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_trick_room',
    rubyClass: 'TrickRoom',
    rubyPath: '10 Move/2 Definitions/300 TrickRoom.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_triple_arrows',
    rubyClass: 'TripleArrows',
    rubyPath: '10 Move/2 Definitions/300 TripleArrows.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_triple_kick',
    rubyClass: 'TripleKick',
    rubyPath: '10 Move/1 Mechanics/103 TwoHit MultiHit.rb',
    dartBehavior: 'MultiHitMoveBehavior.tripleKick',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.ability, PsdkMoveDependency.item, PsdkMoveDependency.history],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_trump_card',
    rubyClass: 'TrumpCard',
    rubyPath: '10 Move/2 Definitions/300 TrumpCard.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_u_turn',
    rubyClass: 'UTurn',
    rubyPath: '10 Move/2 Definitions/300 UTurn.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_upper_hand',
    rubyClass: 'UpperHand',
    rubyPath: '10 Move/2 Definitions/300 UpperHand.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_uproar',
    rubyClass: 'UpRoar',
    rubyPath: '10 Move/2 Definitions/300 UpRoar.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_venom_drench',
    rubyClass: 'VenomDrench',
    rubyPath: '10 Move/2 Definitions/300 VenomDrench.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_venoshock',
    rubyClass: 'Venoshock',
    rubyPath: '10 Move/2 Definitions/300 Venoshock.rb',
    dartBehavior: 'VariablePowerMoveBehavior.venoshock',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_wakeup_slap',
    rubyClass: 'WakeUpSlap',
    rubyPath: '10 Move/2 Definitions/300 HitThenCureStatus.rb',
    dartBehavior: 'HitThenCureStatusMoveBehavior.wakeUpSlap',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerDamage, PsdkMoveDependency.handlerStatus, PsdkMoveDependency.effects, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_water_shuriken',
    rubyClass: 'WaterShuriken',
    rubyPath: '10 Move/1 Mechanics/103 TwoHit MultiHit.rb',
    dartBehavior: 'MultiHitMoveBehavior.waterShuriken',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.ability, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_weather',
    rubyClass: 'WeatherMove',
    rubyPath: '10 Move/2 Definitions/300 WeatherMove.rb',
    dartBehavior: 'WeatherMoveBehavior',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.handlerWeather, PsdkMoveDependency.weather, PsdkMoveDependency.effects, PsdkMoveDependency.item],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_weather_ball',
    rubyClass: 'WeatherBall',
    rubyPath: '10 Move/2 Definitions/300 WeatherBall.rb',
    dartBehavior: 'WeatherPowerMoveBehavior.weatherBall',
    status: PsdkPortStatus.partial,
    dependencies: const <PsdkMoveDependency>[PsdkMoveDependency.weather, PsdkMoveDependency.ability],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_wish',
    rubyClass: 'Wish',
    rubyPath: '10 Move/2 Definitions/300 Wish.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_wonder_room',
    rubyClass: 'WonderRoom',
    rubyPath: '10 Move/2 Definitions/300 WonderRoom.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_worry_seed',
    rubyClass: 'WorrySeed',
    rubyPath: '10 Move/2 Definitions/300 AbilityChanging.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_wring_out',
    rubyClass: 'WringOut',
    rubyPath: '10 Move/2 Definitions/300 WringOut.rb',
    dartBehavior: 'VariablePowerMoveBehavior.wringOut',
    status: PsdkPortStatus.ported,
    dependencies: const <PsdkMoveDependency>[],
  ),
  PsdkMoveRegistryManifestEntry(
    battleEngineMethod: 's_yawn',
    rubyClass: 'Yawn',
    rubyPath: '10 Move/2 Definitions/300 Yawn.rb',
    dartBehavior: 'TODO',
    status: PsdkPortStatus.missing,
    dependencies: const <PsdkMoveDependency>[],
  ),
];

final class PsdkMoveRegistryManifestEntry {
  const PsdkMoveRegistryManifestEntry({
    required this.battleEngineMethod,
    required this.rubyClass,
    required this.rubyPath,
    required this.dartBehavior,
    required this.status,
    this.dependencies = const <PsdkMoveDependency>[],
  });

  final String battleEngineMethod;
  final String rubyClass;
  final String rubyPath;
  final String dartBehavior;
  final PsdkPortStatus status;
  final List<PsdkMoveDependency> dependencies;
}

enum PsdkPortStatus {
  ported,
  partial,
  missing,
}

enum PsdkMoveDependency {
  effects,
  handlerDamage,
  handlerStatus,
  handlerStat,
  handlerItem,
  handlerSwitch,
  handlerWeather,
  handlerTerrain,
  endTurn,
  field,
  weather,
  terrain,
  targetingMulti,
  ability,
  item,
  history,
  grounded,
  faintProcess,
  runtimeBridge,
  actionOrder,
}
import '../domain/move/behaviors/advanced_stat_move_behavior.dart';
import '../domain/move/behaviors/battle_move_behavior_support.dart';
import '../domain/move/behaviors/basic_damage_specialization_move_behavior.dart';
import '../domain/move/behaviors/custom_stat_source_move_behavior.dart';
import '../domain/move/behaviors/direct_hp_move_behavior.dart';
import '../domain/move/behaviors/drain_move_behavior.dart';
import '../domain/move/behaviors/fixed_damage_move_behavior.dart';
import '../domain/move/behaviors/heal_move_behavior.dart';
import '../domain/move/behaviors/hit_then_cure_status_move_behavior.dart';
import '../domain/move/behaviors/mind_blown_move_behavior.dart';
import '../domain/move/behaviors/multi_hit_move_behavior.dart';
import '../domain/move/behaviors/no_effect_move_behavior.dart';
import '../domain/move/behaviors/persistent_effect_move_behavior.dart';
import '../domain/move/behaviors/power_trick_move_behavior.dart';
import '../domain/move/behaviors/psycho_shift_move_behavior.dart';
import '../domain/move/behaviors/purify_move_behavior.dart';
import '../domain/move/behaviors/recovery_stat_move_behavior.dart';
import '../domain/move/behaviors/recoil_move_behavior.dart';
import '../domain/move/behaviors/self_destruct_move_behavior.dart';
import '../domain/move/behaviors/special_power_move_behavior.dart';
import '../domain/move/behaviors/speed_swap_move_behavior.dart';
import '../domain/move/behaviors/stat_split_move_behavior.dart';
import '../domain/move/behaviors/status_stat_move_behavior.dart';
import '../domain/move/behaviors/switch_effect_move_behavior.dart';
import '../domain/move/behaviors/terrain_power_move_behavior.dart';
import '../domain/move/behaviors/terrain_move_behavior.dart';
import '../domain/move/behaviors/transform_move_behavior.dart';
import '../domain/move/behaviors/variable_power_move_behavior.dart';
import '../domain/move/behaviors/weather_move_behavior.dart';
import '../domain/move/behaviors/weather_power_move_behavior.dart';
import '../domain/move/behaviors/weight_power_move_behavior.dart';
import '../domain/move/battle_move_behavior.dart';
import '../domain/move/battle_move_damage_calculator.dart';
import '../domain/move/battle_move_prevention.dart';
import '../domain/move/battle_move_registry.dart';
import '../domain/move/battle_move_secondary_effect_resolver.dart';
import '../domain/effect/battle_effect_scope.dart';
import '../domain/effect/move/protect_effect.dart';
import '../psdk/domain/psdk_battle_slots.dart';
import '../psdk/domain/psdk_battle_timeline.dart';

BattleMoveRegistry createStaticBasicMoveRegistry() {
  return BattleMoveRegistry(<BattleMoveBehavior>[
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_basic',
      resolve: _resolveBasic,
    ),
    const StatusStatMoveBehavior.status(),
    const StatusStatMoveBehavior.stat(),
    const StatusStatMoveBehavior.selfStat(),
    const StatusStatMoveBehavior.selfStatus(),
    CallbackBattleMoveBehavior(
      battleEngineMethod: 's_protect',
      resolve: _resolveProtect,
    ),
    const FixedDamageMoveBehavior.psdkFixedDamage(),
    const FixedDamageMoveBehavior.userLevel(),
    const FixedDamageMoveBehavior.psywave(),
    const FixedDamageMoveBehavior.halfCurrentTargetHp(),
    const MultiHitMoveBehavior.fixed(
      battleEngineMethod: 's_2hits',
      hitCount: 2,
    ),
    const MultiHitMoveBehavior.fixed(
      battleEngineMethod: 's_3hits',
      hitCount: 3,
    ),
    const MultiHitMoveBehavior.psdkRandom(),
    const MultiHitMoveBehavior.tripleKick(),
    const MultiHitMoveBehavior.populationBomb(),
    const MultiHitMoveBehavior.waterShuriken(),
    const BasicDamageSpecializationMoveBehavior.falseSwipe(),
    const BasicDamageSpecializationMoveBehavior.fullCrit(),
    const NoEffectMoveBehavior.doNothing(),
    const NoEffectMoveBehavior.splash(),
    const DirectHpMoveBehavior.endeavor(),
    const DirectHpMoveBehavior.finalGambit(),
    const DirectHpMoveBehavior.painSplit(),
    const DrainMoveBehavior.absorb(),
    const DrainMoveBehavior.dreamEater(),
    const HealMoveBehavior(),
    const HealMoveBehavior.weather(),
    const HealMoveBehavior.floralHealing(),
    const HealMoveBehavior.roost(),
    const HealMoveBehavior.shoreUp(),
    const HealMoveBehavior.lifeDew(),
    const HealMoveBehavior.jungleHealing(),
    const HitThenCureStatusMoveBehavior.smellingSalt(),
    const HitThenCureStatusMoveBehavior.wakeUpSlap(),
    const HitThenCureStatusMoveBehavior.sparklingAria(),
    const PsychoShiftMoveBehavior(),
    const PurifyMoveBehavior(),
    const RecoveryStatMoveBehavior.rest(),
    const RecoveryStatMoveBehavior.bellyDrum(),
    const RecoveryStatMoveBehavior.filletAway(),
    const RecoveryStatMoveBehavior.strengthSap(),
    const PersistentEffectMoveBehavior.aquaRing(),
    const PersistentEffectMoveBehavior.ingrain(),
    const PersistentEffectMoveBehavior.leechSeed(),
    const AdvancedStatMoveBehavior.acupressure(),
    const AdvancedStatMoveBehavior.clangorousSoul(),
    const AdvancedStatMoveBehavior.curse(),
    const AdvancedStatMoveBehavior.growth(),
    const AdvancedStatMoveBehavior.guardSwap(),
    const AdvancedStatMoveBehavior.haze(),
    const AdvancedStatMoveBehavior.heartSwap(),
    const AdvancedStatMoveBehavior.powerSwap(),
    const AdvancedStatMoveBehavior.psychUp(),
    const AdvancedStatMoveBehavior.topsyTurvy(),
    const StatSplitMoveBehavior.power(),
    const StatSplitMoveBehavior.guard(),
    const PowerTrickMoveBehavior(),
    const SpeedSwapMoveBehavior(),
    const SwitchEffectMoveBehavior.batonPass(),
    const SpecialPowerMoveBehavior.acrobatics(),
    const SpecialPowerMoveBehavior.storedPower(),
    const MindBlownMoveBehavior.mindBlown(),
    const MindBlownMoveBehavior.steelBeam(),
    const MindBlownMoveBehavior.chloroblast(),
    const SelfDestructMoveBehavior.explosion(),
    const SelfDestructMoveBehavior.mistyExplosion(),
    const WeatherMoveBehavior(),
    const TerrainMoveBehavior(),
    const TerrainPowerMoveBehavior.terrainBoosting(),
    const WeatherPowerMoveBehavior.weatherBall(),
    const TransformMoveBehavior(),
    const RecoilMoveBehavior.psdkRecoil(),
    const VariablePowerMoveBehavior.brine(),
    const VariablePowerMoveBehavior.eruption(),
    const VariablePowerMoveBehavior.flail(),
    const VariablePowerMoveBehavior.wringOut(),
    const VariablePowerMoveBehavior.hardPress(),
    const VariablePowerMoveBehavior.electroBall(),
    const VariablePowerMoveBehavior.gyroBall(),
    const VariablePowerMoveBehavior.facade(),
    const VariablePowerMoveBehavior.infernalParade(),
    const VariablePowerMoveBehavior.bitterMalice(),
    const VariablePowerMoveBehavior.hex(),
    const VariablePowerMoveBehavior.venoshock(),
    const WeightPowerMoveBehavior.lowKick(),
    const WeightPowerMoveBehavior.heavySlam(),
    const CustomStatSourceMoveBehavior.bodyPress(),
    const CustomStatSourceMoveBehavior.foulPlay(),
    const CustomStatSourceMoveBehavior.psyshock(),
    const CustomStatSourceMoveBehavior.customStatsBased(),
  ]);
}

BattleMoveBehaviorResolution _resolveBasic(BattleMoveBehaviorContext context) {
  final common = prepareBattleMove(context);
  if (!common.shouldExecuteBehavior) {
    return common.toResolution();
  }

  final targetSlot = common.psdkTargets.single;
  final user = common.state.battlerAt(context.user);
  final target = common.state.battlerAt(targetSlot);
  final damageResult = const BattleMoveDamageCalculator().calculate(
    BattleMoveDamageContext(
      user: user,
      target: target,
      move: context.move,
      rng: common.rng,
    ),
  );
  if (damageResult.damage <= 0) {
    return BattleMoveBehaviorResolution(
      state: common.state,
      rng: damageResult.rng,
      events: common.events,
    );
  }

  final applied = applyDirectDamage(
    state: common.state,
    user: context.user,
    target: targetSlot,
    moveId: context.move.id,
    rng: damageResult.rng,
    turn: context.turn,
    amount: damageResult.damage,
  );
  final secondary = const BattleMoveSecondaryEffectResolver().resolve(
    state: applied.state,
    rng: applied.rng,
    user: context.user,
    target: targetSlot,
    move: context.move,
    turn: context.turn,
  );

  return BattleMoveBehaviorResolution(
    state: secondary.state,
    rng: secondary.rng,
    events: <PsdkBattleEvent>[
      ...common.events,
      if (applied.event != null) applied.event!,
      ...secondary.events,
    ],
  );
}

BattleMoveBehaviorResolution _resolveProtect(
    BattleMoveBehaviorContext context) {
  if (context.isLastActionOfTurn) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: BattleMoveFailureReason.unusableByUser.jsonName,
        ),
      ],
      successful: false,
    );
  }

  final common = prepareBattleMove(context);
  if (!common.shouldExecuteBehavior) {
    return common.toResolution();
  }

  final protectedSlot = common.psdkTargets.single;
  final protectedBattler = common.state.battlerAt(protectedSlot);

  // PSDK stores Protect as a pokemon-tied effect. This first Dart slice keeps
  // only the effect id and the same one-turn lifetime; success-rate decay and
  // variants such as Endure/Spiky Shield intentionally remain outside Lot 14.
  final nextState = common.state.replaceBattler(
    protectedSlot,
    protectedBattler.copyWith(
      effects: protectedBattler.effects.addEffect(
        ProtectEffect(
          scope: BattlerBattleEffectScope(
            PsdkBattleSlotRef(
              bank: protectedSlot.bank,
              position: protectedSlot.position,
            ),
          ),
        ),
      ),
    ),
  );

  return BattleMoveBehaviorResolution(
    state: nextState,
    rng: common.rng,
    events: common.events,
  );
}
import '../battle/battle_slot.dart';
import '../rng/battle_rng_streams.dart';
import '../timeline/battle_timeline_event.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import 'battle_accuracy_resolver.dart';
import 'battle_move_execution.dart';
import 'battle_move_prevention.dart';
import 'battle_move_remapper.dart';
import 'battle_target_resolver.dart';

final class BattleMoveProcedure {
  const BattleMoveProcedure({
    BattleTargetResolver targetResolver = const BattleTargetResolver(),
    BattleAccuracyResolver accuracyResolver = const BattleAccuracyResolver(),
    BattleMoveRemapper remapper = const NoopBattleMoveRemapper(),
    BattleMoveTargetPrecheck? targetPrecheck,
    BattleMoveProcedureHooks hooks = BattleMoveProcedureHooks.none,
    bool traceStages = false,
    bool forceAccuracyBypass = false,
  })  : _targetResolver = targetResolver,
        _accuracyResolver = accuracyResolver,
        _remapper = remapper,
        _targetPrecheck = targetPrecheck,
        _hooks = hooks,
        _traceStages = traceStages,
        _forceAccuracyBypass = forceAccuracyBypass;

  final BattleTargetResolver _targetResolver;
  final BattleAccuracyResolver _accuracyResolver;
  final BattleMoveRemapper _remapper;
  final BattleMoveTargetPrecheck? _targetPrecheck;
  final BattleMoveProcedureHooks _hooks;
  final bool _traceStages;
  final bool _forceAccuracyBypass;

  BattleMoveProcedureResult prepare(BattleMoveProcedureExecution execution) {
    _trace(execution, BattleMoveProcedureStage.userAlive);
    final user = execution.context.state.battlerAt(execution.context.user);
    if (user.isFainted) {
      _notifyFailure(
        execution: execution,
        rng: execution.context.rng,
        reason: BattleMoveFailureReason.userFainted,
      );
      return BattleMoveProcedureResult.failed(
        rng: execution.context.rng,
        reason: BattleMoveFailureReason.userFainted,
      );
    }

    _trace(execution, BattleMoveProcedureStage.resolveTargets);
    final targets = _targetResolver.resolve(execution);

    // In PSDK this stage also runs effect user-prevention and PP decrement.
    // Dart currently performs those in BattleTurnRunner before dispatching the
    // behavior. Keeping the stage visible here prevents later ports from
    // accidentally moving declaration/pre-accuracy ahead of usability.
    _trace(execution, BattleMoveProcedureStage.usableByUser);

    _trace(execution, BattleMoveProcedureStage.usage);
    execution.timeline.add(
      BattleMoveDeclaredTimelineEvent(
        turn: execution.turn,
        user: execution.user,
        targets: targets,
        moveId: execution.move.id,
        moveName: execution.move.name,
        moveDbSymbol: execution.move.dbSymbol,
      ),
    );

    _trace(execution, BattleMoveProcedureStage.preAccuracy);
    _hooks.notifyPreAccuracy(
      BattleMoveAccuracyHookContext(
        state: execution.context.state,
        rng: execution.context.rng,
        turn: execution.turn,
        user: execution.user,
        requestedTarget: execution.requestedTarget,
        move: execution.move,
        targets: targets,
      ),
    );

    _trace(execution, BattleMoveProcedureStage.noTarget);
    if (targets.isEmpty && execution.move.target.requiresBattlerTarget) {
      execution.timeline.add(
        BattleMoveFailedTimelineEvent(
          turn: execution.turn,
          user: execution.user,
          moveId: execution.move.id,
          reason: BattleMoveFailureReason.noTarget.jsonName,
        ),
      );
      _notifyFailure(
        execution: execution,
        rng: execution.context.rng,
        reason: BattleMoveFailureReason.noTarget,
      );
      return BattleMoveProcedureResult.failed(
        rng: execution.context.rng,
        reason: BattleMoveFailureReason.noTarget,
      );
    }

    if (targets.isEmpty) {
      execution.actualTargets = targets;
      _trace(execution, BattleMoveProcedureStage.postAccuracy);
      _hooks.notifyPostAccuracy(
        BattleMoveAccuracyHookContext(
          state: execution.context.state,
          rng: execution.context.rng,
          turn: execution.turn,
          user: execution.user,
          requestedTarget: execution.requestedTarget,
          move: execution.move,
          targets: targets,
        ),
      );
      _trace(execution, BattleMoveProcedureStage.postAccuracyMove);
      _hooks.notifyPostAccuracyMove(
        BattleMoveAccuracyHookContext(
          state: execution.context.state,
          rng: execution.context.rng,
          turn: execution.turn,
          user: execution.user,
          requestedTarget: execution.requestedTarget,
          move: execution.move,
          targets: targets,
        ),
      );
      _trace(execution, BattleMoveProcedureStage.animation);
      execution.timeline.add(
        BattleAnimationCueTimelineEvent(
          turn: execution.turn,
          user: execution.user,
          targets: targets,
          moveId: execution.move.id,
          animationId: execution.move.dbSymbol,
        ),
      );
      return BattleMoveProcedureResult.ready(
        rng: execution.context.rng,
        targets: targets,
      );
    }

    _trace(execution, BattleMoveProcedureStage.accuracy);
    final accuracy = _forceAccuracyBypass
        ? BattleAccuracyResult(
            rng: execution.context.rng,
            hitTargets: targets,
            missedTargets: const <BattlePositionRef>[],
            bypassed: true,
          )
        : _accuracyResolver.resolve(
            execution: execution,
            targets: targets,
          );
    for (final missedTarget in accuracy.missedTargets) {
      execution.timeline.add(
        BattleMoveMissedTimelineEvent(
          turn: execution.turn,
          user: execution.user,
          target: missedTarget,
          moveId: execution.move.id,
        ),
      );
    }
    var actualTargets = accuracy.hitTargets;
    if (actualTargets.isEmpty) {
      _notifyFailure(
        execution: execution,
        rng: accuracy.rng,
        reason: BattleMoveFailureReason.accuracy,
        targets: targets,
      );
      return BattleMoveProcedureResult.failed(
        rng: accuracy.rng,
        reason: BattleMoveFailureReason.accuracy,
      );
    }

    _trace(execution, BattleMoveProcedureStage.remap);
    final remapped = _remapper.remap(
      BattleMoveRemapContext(
        state: execution.context.state,
        turn: execution.turn,
        user: execution.user,
        targets: actualTargets,
        move: execution.move,
      ),
    );
    execution.actualUser = remapped.user;
    actualTargets = remapped.targets;

    _trace(execution, BattleMoveProcedureStage.immunity);
    final targetPrecheck = _targetPrecheck;
    if (targetPrecheck != null) {
      final precheck = targetPrecheck(execution, actualTargets);
      actualTargets = precheck.targets;
      if (actualTargets.isEmpty) {
        _notifyFailure(
          execution: execution,
          rng: accuracy.rng,
          reason: precheck.reason,
          targets: accuracy.hitTargets,
        );
        return BattleMoveProcedureResult.failed(
          rng: accuracy.rng,
          reason: precheck.reason,
        );
      }
    }

    execution.actualTargets = actualTargets;
    _trace(execution, BattleMoveProcedureStage.postAccuracy);
    _hooks.notifyPostAccuracy(
      BattleMoveAccuracyHookContext(
        state: execution.context.state,
        rng: accuracy.rng,
        turn: execution.turn,
        user: execution.actualUser,
        requestedTarget: execution.requestedTarget,
        move: execution.move,
        targets: actualTargets,
      ),
    );
    _trace(execution, BattleMoveProcedureStage.postAccuracyMove);
    _hooks.notifyPostAccuracyMove(
      BattleMoveAccuracyHookContext(
        state: execution.context.state,
        rng: accuracy.rng,
        turn: execution.turn,
        user: execution.actualUser,
        requestedTarget: execution.requestedTarget,
        move: execution.move,
        targets: actualTargets,
      ),
    );
    _trace(execution, BattleMoveProcedureStage.animation);
    execution.timeline.add(
      BattleAnimationCueTimelineEvent(
        turn: execution.turn,
        user: execution.actualUser,
        targets: actualTargets,
        moveId: execution.move.id,
        animationId: execution.move.dbSymbol,
      ),
    );

    return BattleMoveProcedureResult.ready(
      rng: accuracy.rng,
      targets: actualTargets,
    );
  }

  void _notifyFailure({
    required BattleMoveProcedureExecution execution,
    required BattleRngStreams rng,
    required BattleMoveFailureReason reason,
    List<BattlePositionRef> targets = const <BattlePositionRef>[],
  }) {
    _hooks.notifyFailure(
      BattleMoveFailureContext(
        state: execution.context.state,
        rng: rng,
        turn: execution.turn,
        user: execution.actualUser,
        target: execution.requestedTarget,
        move: execution.move,
        reason: reason,
        targets: targets,
      ),
    );
  }

  void _trace(
    BattleMoveProcedureExecution execution,
    BattleMoveProcedureStage stage,
  ) {
    if (!_traceStages) {
      return;
    }
    execution.timeline.add(
      BattleMoveProcedureTraceEvent(
        turn: execution.turn,
        moveId: execution.move.id,
        stage: stage,
      ),
    );
  }
}

typedef BattleMoveTargetPrecheck = BattleMoveTargetPrecheckResult Function(
  BattleMoveProcedureExecution execution,
  List<BattlePositionRef> targets,
);

final class BattleMoveTargetPrecheckResult {
  BattleMoveTargetPrecheckResult({
    required List<BattlePositionRef> targets,
    required this.reason,
  }) : targets = List<BattlePositionRef>.unmodifiable(targets);

  final List<BattlePositionRef> targets;
  final BattleMoveFailureReason reason;
}

final class BattleMoveProcedureResult {
  BattleMoveProcedureResult._({
    required this.rng,
    required List<BattlePositionRef> targets,
    required this.reason,
  }) : targets = List<BattlePositionRef>.unmodifiable(targets);

  factory BattleMoveProcedureResult.ready({
    required BattleRngStreams rng,
    required List<BattlePositionRef> targets,
  }) {
    return BattleMoveProcedureResult._(
      rng: rng,
      targets: targets,
      reason: null,
    );
  }

  factory BattleMoveProcedureResult.failed({
    required BattleRngStreams rng,
    required BattleMoveFailureReason reason,
  }) {
    return BattleMoveProcedureResult._(
      rng: rng,
      targets: const <BattlePositionRef>[],
      reason: reason,
    );
  }

  final BattleRngStreams rng;
  final List<BattlePositionRef> targets;
  final BattleMoveFailureReason? reason;

  bool get shouldExecuteBehavior => reason == null;
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/battle_effect_scope.dart';
import '../../effect/move/curse_effect.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

enum _AdvancedStatKind {
  acupressure,
  clangorousSoul,
  curse,
  growth,
  guardSwap,
  haze,
  heartSwap,
  powerSwap,
  psychUp,
  topsyTurvy,
}

/// Ports PSDK stat-stage moves that need direct stage reset/copy/inversion.
///
/// These stay partial until Crafty Shield, Contrary/Mirror Armor style hooks
/// and richer effect interactions can intercept the same paths as Ruby PSDK.
final class AdvancedStatMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const AdvancedStatMoveBehavior.acupressure()
      : battleEngineMethod = 's_acupressure',
        _kind = _AdvancedStatKind.acupressure;

  const AdvancedStatMoveBehavior.clangorousSoul()
      : battleEngineMethod = 's_clangorous_soul',
        _kind = _AdvancedStatKind.clangorousSoul;

  const AdvancedStatMoveBehavior.curse()
      : battleEngineMethod = 's_curse',
        _kind = _AdvancedStatKind.curse;

  const AdvancedStatMoveBehavior.growth()
      : battleEngineMethod = 's_growth',
        _kind = _AdvancedStatKind.growth;

  const AdvancedStatMoveBehavior.guardSwap()
      : battleEngineMethod = 's_guard_swap',
        _kind = _AdvancedStatKind.guardSwap;

  const AdvancedStatMoveBehavior.haze()
      : battleEngineMethod = 's_haze',
        _kind = _AdvancedStatKind.haze;

  const AdvancedStatMoveBehavior.heartSwap()
      : battleEngineMethod = 's_heart_swap',
        _kind = _AdvancedStatKind.heartSwap;

  const AdvancedStatMoveBehavior.powerSwap()
      : battleEngineMethod = 's_power_swap',
        _kind = _AdvancedStatKind.powerSwap;

  const AdvancedStatMoveBehavior.psychUp()
      : battleEngineMethod = 's_psych_up',
        _kind = _AdvancedStatKind.psychUp;

  const AdvancedStatMoveBehavior.topsyTurvy()
      : battleEngineMethod = 's_topsy_turvy',
        _kind = _AdvancedStatKind.topsyTurvy;

  @override
  final String battleEngineMethod;
  final _AdvancedStatKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final state = context.state;
    return switch (_kind) {
      _AdvancedStatKind.acupressure => !_hasIncreasableStage(
          state.battlerAt(context.target),
          _allStageStats,
        )
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
      _AdvancedStatKind.clangorousSoul =>
        context.state.battlerAt(context.user).currentHp * 3 <=
                    context.state.battlerAt(context.user).maxHp ||
                !_hasIncreasableStage(
                  state.battlerAt(context.user),
                  _clangorousStats,
                )
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
      _AdvancedStatKind.curse =>
        state.battlerAt(context.user).hasType('ghost') &&
                state.battlerAt(context.target).effects.contains('curse')
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
      _AdvancedStatKind.haze => state.aliveSlots().every(
                (slot) => state.battlerAt(slot).statStages.values.isEmpty,
              )
          ? const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            )
          : null,
      _AdvancedStatKind.topsyTurvy =>
        state.battlerAt(context.target).statStages.values.isEmpty
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
      _ => null,
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return BattleMoveBehaviorResolution(
        state: context.state,
        rng: context.rng,
        events: <PsdkBattleEvent>[
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.target,
            moveId: context.move.id,
            reason: prevention.reason.jsonName,
          ),
        ],
        successful: false,
      );
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return switch (_kind) {
      _AdvancedStatKind.acupressure => _resolveAcupressure(context, prepared),
      _AdvancedStatKind.clangorousSoul =>
        _resolveClangorousSoul(context, prepared),
      _AdvancedStatKind.curse => _resolveCurse(context, prepared),
      _AdvancedStatKind.growth => _resolveGrowth(context, prepared),
      _AdvancedStatKind.guardSwap => _resolveStageSwap(
          context,
          prepared,
          stats: _guardStats,
        ),
      _AdvancedStatKind.haze => _resolveHaze(context, prepared),
      _AdvancedStatKind.heartSwap => _resolveStageSwap(
          context,
          prepared,
          stats: _allStageStats,
        ),
      _AdvancedStatKind.powerSwap => _resolveStageSwap(
          context,
          prepared,
          stats: _powerStats,
        ),
      _AdvancedStatKind.psychUp => _resolvePsychUp(context, prepared),
      _AdvancedStatKind.topsyTurvy => _resolveTopsyTurvy(context, prepared),
    };
  }

  BattleMoveBehaviorResolution _resolveAcupressure(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final increasable = _increasableStats(state.battlerAt(targetSlot));
    if (increasable.isEmpty) {
      return BattleMoveBehaviorResolution(
        state: state,
        rng: rng,
        events: <PsdkBattleEvent>[
          ...events,
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: targetSlot,
            moveId: context.move.id,
            reason: BattleMoveFailureReason.unusableByUser.jsonName,
          ),
        ],
        successful: false,
      );
    }

    final roll = rng.generic.nextIntInclusive(
      min: 0,
      max: increasable.length - 1,
    );
    rng = rng.copyWith(generic: roll.next);
    final result = _setStageDelta(
      state: state,
      rng: rng,
      turn: context.turn,
      user: context.user,
      target: targetSlot,
      stat: increasable[roll.value],
      delta: 2,
    );
    state = result.state;
    rng = result.rng;
    events.addAll(result.events);

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveClangorousSoul(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final user = state.battlerAt(context.user);
    final damage = user.maxHp ~/ 3;
    final damaged = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: damage,
    );
    state = damaged.state;
    rng = damaged.rng;
    if (damaged.event != null) {
      events.add(damaged.event!);
    }

    for (final stat in _clangorousStats) {
      final result = _setStageDelta(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        target: context.user,
        stat: stat,
        delta: 1,
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveCurse(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    final user = prepared.state.battlerAt(context.user);
    if (!user.hasType('ghost')) {
      return _resolveNonGhostCurse(context, prepared);
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final damage = (user.maxHp ~/ 2).clamp(1, user.currentHp).toInt();
    final damaged = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: damage,
    );
    state = damaged.state;
    rng = damaged.rng;
    if (damaged.event != null) {
      events.add(damaged.event!);
    }
    state = state.updateBattler(
      targetSlot,
      (target) => target.copyWith(
        effects: target.effects.addEffect(
          CurseEffect(scope: BattlerBattleEffectScope(targetSlot)),
        ),
      ),
    );

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveNonGhostCurse(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    for (final change in _nonGhostCurseStats.entries) {
      final result = _setStageDelta(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        target: context.user,
        stat: change.key,
        delta: change.value,
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveGrowth(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final stages = _isSunny(state.field) ? 2 : 1;
    for (final stat in context.move.stageMods) {
      final result = _setStageDelta(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        target: context.user,
        stat: stat.stat,
        delta: stages,
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveHaze(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    for (final slot in state.aliveSlots()) {
      for (final entry in state.battlerAt(slot).statStages.values.entries) {
        final result = _setStageTo(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
          target: slot,
          stat: entry.key,
          desiredStage: 0,
        );
        state = result.state;
        rng = result.rng;
        events.addAll(result.events);
      }
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolvePsychUp(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final userStages = state.battlerAt(context.user).statStages.values;
    final targetStages = state.battlerAt(targetSlot).statStages.values;
    final stats = <String>{...userStages.keys, ...targetStages.keys}.toList()
      ..sort();
    for (final stat in stats) {
      final result = _setStageTo(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        target: context.user,
        stat: stat,
        desiredStage: targetStages[stat] ?? 0,
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveTopsyTurvy(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final targetStages = state.battlerAt(targetSlot).statStages.values;
    final stats = targetStages.keys.toList()..sort();
    for (final stat in stats) {
      final result = _setStageTo(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        target: targetSlot,
        stat: stat,
        desiredStage: -(targetStages[stat] ?? 0),
      );
      state = result.state;
      rng = result.rng;
      events.addAll(result.events);
    }
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveStageSwap(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared, {
    required List<String> stats,
  }) {
    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final userStages = state.battlerAt(context.user).statStages.values;
    final targetStages = state.battlerAt(targetSlot).statStages.values;

    for (final stat in stats) {
      final normalized = _normalizeStat(stat);
      final userStage = userStages[normalized] ?? 0;
      final targetStage = targetStages[normalized] ?? 0;
      final userResult = _setStageTo(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        target: context.user,
        stat: normalized,
        desiredStage: targetStage,
      );
      state = userResult.state;
      rng = userResult.rng;
      events.addAll(userResult.events);

      final targetResult = _setStageTo(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        target: targetSlot,
        stat: normalized,
        desiredStage: userStage,
      );
      state = targetResult.state;
      rng = targetResult.rng;
      events.addAll(targetResult.events);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }
}

const _allStageStats = <String>[
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed',
  'accuracy',
  'evasion',
];

const _clangorousStats = <String>[
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed',
];

const _powerStats = <String>['attack', 'specialAttack'];
const _guardStats = <String>['defense', 'specialDefense'];

const _nonGhostCurseStats = <String, int>{
  'speed': -1,
  'attack': 1,
  'defense': 1,
};

List<String> _increasableStats(PsdkBattleCombatant battler) {
  return <String>[
    for (final stat in _allStageStats)
      if (battler.statStages.valueOf(stat) < 6) stat,
  ];
}

bool _hasIncreasableStage(
  PsdkBattleCombatant battler,
  List<String> stats,
) {
  return stats.any((stat) => battler.statStages.valueOf(stat) < 6);
}

_StatStageMutation _setStageDelta({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String stat,
  required int delta,
}) {
  final battler = state.battlerAt(target);
  final desired = (battler.statStages.valueOf(stat) + delta).clamp(-6, 6);
  return _setStageTo(
    state: state,
    rng: rng,
    turn: turn,
    user: user,
    target: target,
    stat: stat,
    desiredStage: desired.toInt(),
  );
}

_StatStageMutation _setStageTo({
  required PsdkBattleState state,
  required BattleRngStreams rng,
  required int turn,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String stat,
  required int desiredStage,
}) {
  final battler = state.battlerAt(target);
  final normalized = _normalizeStat(stat);
  final currentStage = battler.statStages.valueOf(normalized);
  final clampedStage = desiredStage.clamp(-6, 6).toInt();
  final delta = clampedStage - currentStage;
  if (delta == 0) {
    return _StatStageMutation(
      state: state,
      rng: rng,
      events: const <PsdkBattleEvent>[],
    );
  }

  final values = Map<String, int>.from(battler.statStages.values);
  if (clampedStage == 0) {
    values.remove(normalized);
  } else {
    values[normalized] = clampedStage;
  }
  final nextBattler = battler
      .copyWith(statStages: PsdkBattleStatStages(values: values))
      .recordStatChange(
        turn: turn,
        stat: normalized,
        delta: delta,
        currentStage: clampedStage,
      );
  return _StatStageMutation(
    state: state.replaceBattler(target, nextBattler),
    rng: rng,
    events: <PsdkBattleEvent>[
      PsdkBattleStatStageEvent(
        target: target,
        stat: normalized,
        amount: delta,
        currentStage: clampedStage,
      ),
    ],
  );
}

bool _isSunny(PsdkBattleFieldState field) {
  return field.isWeatherActive(PsdkBattleWeatherId.sunny) ||
      field.isWeatherActive(PsdkBattleWeatherId.hardsun);
}

String _normalizeStat(String stat) {
  final token = stat.trim();
  final normalized = token.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
  return switch (normalized) {
    'atk' || 'attack' => 'attack',
    'def' || 'dfe' || 'defense' => 'defense',
    'ats' || 'spa' || 'spatk' || 'specialattack' => 'specialAttack',
    'dfs' || 'spdef' || 'specialdefense' => 'specialDefense',
    'spd' || 'spe' || 'speed' => 'speed',
    'acc' || 'accuracy' => 'accuracy',
    'eva' || 'evasion' => 'evasion',
    _ => token,
  };
}

final class _StatStageMutation {
  const _StatStageMutation({
    required this.state,
    required this.rng,
    required this.events,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
}
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _BasicDamageSpecializationKind {
  falseSwipe,
  fullCrit,
}

/// Ports small PSDK `Basic` descendants that only specialize damage inputs.
///
/// `FalseSwipe` remains partial until Substitute exists in the PSDK combatant
/// effects. `FullCrit` is a direct port of Ruby's `critical_rate = 100`.
final class BasicDamageSpecializationMoveBehavior
    implements BattleMoveBehavior {
  const BasicDamageSpecializationMoveBehavior.falseSwipe()
      : battleEngineMethod = 's_false_swipe',
        _kind = _BasicDamageSpecializationKind.falseSwipe;

  const BasicDamageSpecializationMoveBehavior.fullCrit()
      : battleEngineMethod = 's_full_crit',
        _kind = _BasicDamageSpecializationKind.fullCrit;

  @override
  final String battleEngineMethod;
  final _BasicDamageSpecializationKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final move = _damageMove(context.move);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: move,
        rng: prepared.rng,
      ),
    );
    final damage = _damageAmount(
      calculatedDamage: damageResult.damage,
      targetCurrentHp: target.currentHp,
    );
    if (damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  BattleMoveDefinition _damageMove(BattleMoveDefinition move) {
    return switch (_kind) {
      _BasicDamageSpecializationKind.falseSwipe => move,
      _BasicDamageSpecializationKind.fullCrit => _moveWithCriticalRate(
          move,
          criticalRate: 100,
        ),
    };
  }

  int _damageAmount({
    required int calculatedDamage,
    required int targetCurrentHp,
  }) {
    return switch (_kind) {
      _BasicDamageSpecializationKind.falseSwipe =>
        calculatedDamage >= targetCurrentHp
            ? targetCurrentHp - 1
            : calculatedDamage,
      _BasicDamageSpecializationKind.fullCrit => calculatedDamage,
    };
  }
}

BattleMoveDefinition _moveWithCriticalRate(
  BattleMoveDefinition move, {
  required int criticalRate,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: move.type,
    category: move.category,
    power: move.power,
    accuracy: move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: move.priority,
    criticalRate: criticalRate,
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: move.flags,
    stageMods: move.stageMods,
    statuses: move.statuses,
  );
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battle/battle_slot.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_heal_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../rng/battle_rng_streams.dart';
import '../../timeline/battle_timeline_builder.dart';
import '../battle_move_behavior.dart';
import '../battle_move_execution.dart';
import '../battle_move_immunity_resolver.dart';
import '../battle_move_prevention.dart';
import '../battle_move_procedure.dart';

/// Shared PSDK move pipeline used by concrete move families.
///
/// PSDK move classes often override only the "damage/effect" body while still
/// going through the same declaration, target, accuracy, Protect and immunity
/// checks. This helper keeps that contract in one place so Lot 16 families do
/// not fork subtly different pre-hit behavior.
PreparedBattleMove prepareBattleMove(
  BattleMoveBehaviorContext context, {
  BattleMoveTargetPrecheck targetPrecheck = precheckTypeImmunityAndProtect,
  bool forceAccuracyBypass = false,
}) {
  final timeline = BattleTimelineBuilder();
  final execution = BattleMoveProcedureExecution(
    context: context,
    timeline: timeline,
    user: battlePositionFromPsdkSlot(context.user),
    move: context.move,
    requestedTarget: battlePositionFromPsdkSlot(context.target),
  );
  final result = BattleMoveProcedure(
    hooks: context.moveProcedureHooks,
    targetPrecheck: targetPrecheck,
    forceAccuracyBypass: forceAccuracyBypass,
  ).prepare(execution);
  return PreparedBattleMove(
    state: context.state,
    rng: result.rng,
    events: timeline.build().psdkTimeline.events,
    targets: result.targets,
    failureReason: result.reason,
    shouldExecuteBehavior: result.shouldExecuteBehavior,
  );
}

/// Applies HP damage without invoking the normal damage formula.
///
/// Fixed-damage PSDK moves explicitly disable critical hits and type
/// effectiveness after the shared immunity precheck. Keeping this helper small
/// makes that boundary visible and prevents accidental damage RNG consumption.
BattleDirectDamageResult applyDirectDamage({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String moveId,
  required BattleRngStreams rng,
  required int turn,
  required int amount,
}) {
  final result = const BattleDamageHandler().applyDamage(
    context: BattleHandlerContext(
      state: state,
      rng: rng,
      turn: turn,
      user: user,
    ),
    target: target,
    moveId: moveId,
    rawDamage: amount,
  );
  final damageEvents = result.events.whereType<PsdkBattleDamageEvent>();
  return BattleDirectDamageResult(
    state: result.state,
    rng: result.rng,
    damage: result.amount,
    target: result.state.battlerAt(target),
    event: damageEvents.isEmpty ? null : damageEvents.single,
  );
}

BattleDirectHealResult applyDirectHeal({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleSlotRef target,
  required String moveId,
  required BattleRngStreams rng,
  required int turn,
  required int amount,
}) {
  final result = const BattleHealHandler().heal(
    context: BattleHandlerContext(
      state: state,
      rng: rng,
      turn: turn,
      user: user,
    ),
    target: target,
    amount: amount,
  );
  final healedBattler = result.state.battlerAt(target);
  return BattleDirectHealResult(
    state: result.state,
    rng: result.rng,
    amount: result.amount,
    target: healedBattler,
    event: result.applied
        ? PsdkBattleHealEvent(
            user: user,
            target: target,
            moveId: moveId,
            amount: result.amount,
            remainingHp: healedBattler.currentHp,
          )
        : null,
  );
}

BattleMoveTargetPrecheckResult precheckTypeImmunityAndProtect(
  BattleMoveProcedureExecution execution,
  List<BattlePositionRef> targets,
) {
  return const BattleMoveImmunityResolver().precheck(execution, targets);
}

BattlePositionRef battlePositionFromPsdkSlot(PsdkBattleSlotRef slot) {
  return BattlePositionRef(bank: slot.bank, position: slot.position);
}

PsdkBattleSlotRef psdkSlotFromBattlePosition(BattlePositionRef slot) {
  return PsdkBattleSlotRef(bank: slot.bank, position: slot.position);
}

final class PreparedBattleMove {
  const PreparedBattleMove({
    required this.state,
    required this.rng,
    required this.events,
    required this.targets,
    required this.failureReason,
    required this.shouldExecuteBehavior,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
  final List<BattlePositionRef> targets;
  final BattleMoveFailureReason? failureReason;
  final bool shouldExecuteBehavior;

  List<PsdkBattleSlotRef> get psdkTargets {
    return targets.map(psdkSlotFromBattlePosition).toList(growable: false);
  }

  BattleMoveBehaviorResolution toResolution({bool successful = false}) {
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
      successful: successful,
    );
  }
}

final class BattleDirectDamageResult {
  const BattleDirectDamageResult({
    required this.state,
    required this.rng,
    required this.damage,
    required this.target,
    this.event,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int damage;
  final PsdkBattleCombatant target;
  final PsdkBattleDamageEvent? event;
}

final class BattleDirectHealResult {
  const BattleDirectHealResult({
    required this.state,
    required this.rng,
    required this.amount,
    required this.target,
    this.event,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final int amount;
  final PsdkBattleCombatant target;
  final PsdkBattleHealEvent? event;
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _CustomStatSourceKind {
  bodyPress,
  foulPlay,
  psyshock,
  customStatsBased,
}

/// Ports PSDK moves that keep the normal damage formula but swap stat sources.
///
/// Ruby PSDK implements these as subclasses overriding `calc_sp_atk_basis` and
/// `calc_atk_stat_modifier`, not as dynamic-power moves. This behavior keeps
/// that boundary: it resolves the exact offensive/defensive stats for one hit,
/// then delegates the rest of damage, RNG, STAB, type and secondary effects to
/// the shared calculator/pipeline.
final class CustomStatSourceMoveBehavior implements BattleMoveBehavior {
  const CustomStatSourceMoveBehavior.bodyPress()
      : battleEngineMethod = 's_body_press',
        _kind = _CustomStatSourceKind.bodyPress;

  const CustomStatSourceMoveBehavior.foulPlay()
      : battleEngineMethod = 's_foul_play',
        _kind = _CustomStatSourceKind.foulPlay;

  const CustomStatSourceMoveBehavior.psyshock()
      : battleEngineMethod = 's_psyshock',
        _kind = _CustomStatSourceKind.psyshock;

  const CustomStatSourceMoveBehavior.customStatsBased()
      : battleEngineMethod = 's_custom_stats_based',
        _kind = _CustomStatSourceKind.customStatsBased;

  @override
  final String battleEngineMethod;
  final _CustomStatSourceKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    _guardSupportedCustomStatsDbSymbol(context);

    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(
          offensiveStatResolver: (isCritical) => _offensiveStat(
            user: user,
            target: target,
            isCritical: isCritical,
          ),
          defensiveStatResolver: (isCritical) => _defensiveStat(
            target: target,
            isCritical: isCritical,
          ),
        ),
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  int _offensiveStat({
    required PsdkBattleCombatant user,
    required PsdkBattleCombatant target,
    required bool isCritical,
  }) {
    return switch (_kind) {
      _CustomStatSourceKind.bodyPress => user.effectiveStat(
          'defense',
          // PSDK BodyPress returns stage modifier 1 on critical hit, ignoring
          // both positive Defense boosts and negative Defense drops.
          ignoreAllStages: isCritical,
        ),
      _CustomStatSourceKind.foulPlay => target.effectiveStat(
          'attack',
          // PSDK FoulPlay also returns stage modifier 1 on critical hit, using
          // the target's raw Attack instead of any target Attack stage.
          ignoreAllStages: isCritical,
        ),
      _CustomStatSourceKind.psyshock ||
      _CustomStatSourceKind.customStatsBased =>
        user.effectiveStat(
          'specialAttack',
          // PSDK CustomStatsBased follows the base offensive critical rule:
          // negative drops are ignored, positive boosts are kept.
          ignoreNegativeStage: isCritical,
        ),
    };
  }

  int _defensiveStat({
    required PsdkBattleCombatant target,
    required bool isCritical,
  }) {
    // The three supported families route defense like a physical PSDK move:
    // target Defense is used, positive defensive boosts are ignored on crit,
    // and negative defensive drops still make the hit stronger.
    return target.effectiveStat(
      'defense',
      ignorePositiveStage: isCritical,
    );
  }

  void _guardSupportedCustomStatsDbSymbol(BattleMoveBehaviorContext context) {
    if (_kind != _CustomStatSourceKind.customStatsBased) {
      return;
    }
    final dbSymbol = context.move.dbSymbol.trim().toLowerCase();
    if (dbSymbol == 'psyshock' || dbSymbol == 'secret_sword') {
      return;
    }
    throw UnsupportedError(
      'Unsupported s_custom_stats_based dbSymbol "${context.move.dbSymbol}".',
    );
  }
}
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

enum _DirectHpMoveKind {
  endeavor,
  finalGambit,
  painSplit,
}

/// Ports PSDK moves that assign HP loss directly instead of using the normal
/// damage formula.
///
/// This behavior deliberately reuses the shared procedure before HP changes so
/// accuracy, Protect and type-immunity stay aligned with other PSDK move
/// families. It does not attempt to model text messages or later faint-process
/// callbacks, which is why Final Gambit remains partial in the matrix.
final class DirectHpMoveBehavior implements BattleMoveUserPreventionBehavior {
  const DirectHpMoveBehavior.endeavor()
      : battleEngineMethod = 's_endeavor',
        _kind = _DirectHpMoveKind.endeavor;

  const DirectHpMoveBehavior.finalGambit()
      : battleEngineMethod = 's_final_gambit',
        _kind = _DirectHpMoveKind.finalGambit;

  const DirectHpMoveBehavior.painSplit()
      : battleEngineMethod = 's_pain_split',
        _kind = _DirectHpMoveKind.painSplit;

  @override
  final String battleEngineMethod;
  final _DirectHpMoveKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    if (_kind != _DirectHpMoveKind.endeavor) {
      return null;
    }

    final userHp = context.state.battlerAt(context.user).currentHp;
    final targetHp = context.state.battlerAt(context.target).currentHp;
    if (userHp < targetHp) {
      return null;
    }

    // Ruby PSDK implements this in `move_usable_by_user`, before PP spending
    // and before the usage animation. Exposing it through the behavior-level
    // prevention seam keeps that timing exact for the clean engine runner.
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return _failedBeforeProcedure(context, prevention);
    }

    final prepared = prepareBattleMove(
      context,
      forceAccuracyBypass: _kind == _DirectHpMoveKind.painSplit,
    );
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return switch (_kind) {
      _DirectHpMoveKind.endeavor => _resolveEndeavor(
          context: context,
          prepared: prepared,
        ),
      _DirectHpMoveKind.finalGambit => _resolveFinalGambit(
          context: context,
          prepared: prepared,
        ),
      _DirectHpMoveKind.painSplit => _resolvePainSplit(
          context: context,
          prepared: prepared,
        ),
    };
  }

  BattleMoveBehaviorResolution _resolveEndeavor({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final target = prepared.psdkTargets.single;
    final userHp = prepared.state.battlerAt(context.user).currentHp;
    final targetHp = prepared.state.battlerAt(target).currentHp;
    final amount = targetHp - userHp;
    if (amount <= 0) {
      return prepared.toResolution();
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: target,
      moveId: context.move.id,
      rng: prepared.rng,
      turn: context.turn,
      amount: amount,
    );

    return BattleMoveBehaviorResolution(
      state: applied.state,
      rng: applied.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveFinalGambit({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final hpDealt = prepared.state.battlerAt(context.user).currentHp;
    var nextState = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    // PSDK first removes the user's current HP, then applies that captured
    // amount to every actual target. Keeping the original amount protects the
    // move from accidentally dealing zero after the self-KO mutation.
    final selfDamage = applyDirectDamage(
      state: nextState,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: hpDealt,
    );
    nextState = selfDamage.state;
    rng = selfDamage.rng;
    if (selfDamage.event != null) {
      events.add(selfDamage.event!);
    }

    for (final target in prepared.psdkTargets) {
      final targetDamage = applyDirectDamage(
        state: nextState,
        user: context.user,
        target: target,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: hpDealt,
      );
      nextState = targetDamage.state;
      rng = targetDamage.rng;
      if (targetDamage.event != null) {
        events.add(targetDamage.event!);
      }
    }

    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolvePainSplit({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    var nextState = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final affectedSlots = <PsdkBattleSlotRef>[
      context.user,
      ...prepared.psdkTargets,
    ];
    final totalHp = affectedSlots.fold<int>(
      0,
      (sum, slot) => sum + nextState.battlerAt(slot).currentHp,
    );
    final averageHp = totalHp ~/ affectedSlots.length;

    for (final slot in affectedSlots) {
      final battler = nextState.battlerAt(slot);
      final delta = averageHp - battler.currentHp;
      if (delta > 0) {
        final healed = applyDirectHeal(
          state: nextState,
          user: context.user,
          target: slot,
          moveId: context.move.id,
          rng: rng,
          turn: context.turn,
          amount: delta,
        );
        nextState = healed.state;
        rng = healed.rng;
        if (healed.event != null) {
          events.add(healed.event!);
        }
      } else if (delta < 0) {
        final damaged = applyDirectDamage(
          state: nextState,
          user: context.user,
          target: slot,
          moveId: context.move.id,
          rng: rng,
          turn: context.turn,
          amount: -delta,
        );
        nextState = damaged.state;
        rng = damaged.rng;
        if (damaged.event != null) {
          events.add(damaged.event!);
        }
      }
    }

    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _failedBeforeProcedure(
    BattleMoveBehaviorContext context,
    BattleMoveUserPreventionResult prevention,
  ) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: prevention.reason.jsonName,
        ),
      ],
      successful: false,
    );
  }
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battle/battle_slot.dart';
import '../../timeline/battle_timeline_event.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_execution.dart';
import '../battle_move_prevention.dart';
import '../battle_move_procedure.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _DrainMoveKind {
  absorb,
  dreamEater,
}

/// Ports the PSDK drain family (`s_absorb` and `s_dream_eater`) for the common
/// HP-transfer path.
///
/// Full PSDK parity still depends on future drain-prevention hooks such as
/// Heal Block and item/ability modifiers. This behavior deliberately keeps the
/// local rule small: damage first, heal the user from the damage actually dealt.
final class DrainMoveBehavior implements BattleMoveBehavior {
  const DrainMoveBehavior.absorb()
      : battleEngineMethod = 's_absorb',
        _kind = _DrainMoveKind.absorb;

  const DrainMoveBehavior.dreamEater()
      : battleEngineMethod = 's_dream_eater',
        _kind = _DrainMoveKind.dreamEater;

  @override
  final String battleEngineMethod;
  final _DrainMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(
      context,
      targetPrecheck: _kind == _DrainMoveKind.dreamEater
          ? _precheckDreamEaterTarget
          : precheckTypeImmunityAndProtect,
    );
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final target = prepared.state.battlerAt(targetSlot);
    final user = prepared.state.battlerAt(context.user);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final damage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final healAmount = _drainHealAmount(
      damage: damage.damage,
      dbSymbol: context.move.dbSymbol,
    );
    final heal = applyDirectHeal(
      state: damage.state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: damage.rng,
      turn: context.turn,
      amount: healAmount,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: heal.state,
      rng: heal.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (damage.event != null) damage.event!,
        if (heal.event != null) heal.event!,
        ...secondary.events,
      ],
    );
  }
}

BattleMoveTargetPrecheckResult _precheckDreamEaterTarget(
  BattleMoveProcedureExecution execution,
  List<BattlePositionRef> targets,
) {
  final base = precheckTypeImmunityAndProtect(execution, targets);
  final affectedTargets = <BattlePositionRef>[];
  var reason = base.reason;

  for (final targetRef in base.targets) {
    final target = execution.context.state.battlerAt(
      psdkSlotFromBattlePosition(targetRef),
    );
    if (!_canDreamEaterAffect(target)) {
      reason = BattleMoveFailureReason.immunity;
      execution.timeline.add(
        BattleMoveImmuneTimelineEvent(
          turn: execution.turn,
          user: execution.actualUser,
          target: targetRef,
          moveId: execution.move.id,
        ),
      );
      continue;
    }

    affectedTargets.add(targetRef);
  }

  return BattleMoveTargetPrecheckResult(
    targets: affectedTargets,
    reason: reason,
  );
}

bool _canDreamEaterAffect(PsdkBattleCombatant target) {
  return target.majorStatus == PsdkBattleMajorStatus.sleep ||
      target.abilityId == 'comatose';
}

int _drainHealAmount({
  required int damage,
  required String dbSymbol,
}) {
  final drainFactor =
      dbSymbol == 'draining_kiss' || dbSymbol == 'oblivion_wing' ? 4 / 3 : 2;
  final healed = (damage / drainFactor).floor();
  return healed < 1 ? 1 : healed;
}
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

const Map<String, int> _psdkFixedDamageByDbSymbol = <String, int>{
  'sonic_boom': 20,
  'dragon_rage': 40,
};

enum _FixedDamageKind {
  psdkFixedDamage,
  userLevel,
  psywave,
  halfCurrentTargetHp,
}

/// Ports PSDK move classes that override `damages` with a direct HP amount.
///
/// The shared pipeline still handles target resolution, accuracy, Protect and
/// type immunity. This class only replaces the normal formula after that point,
/// mirroring Ruby classes such as `FixedDamages`, `HPEqLevel`, `Psywave` and
/// `SuperFang`.
final class FixedDamageMoveBehavior implements BattleMoveBehavior {
  const FixedDamageMoveBehavior.psdkFixedDamage()
      : battleEngineMethod = 's_fixed_damage',
        _kind = _FixedDamageKind.psdkFixedDamage;

  const FixedDamageMoveBehavior.userLevel()
      : battleEngineMethod = 's_hp_eq_level',
        _kind = _FixedDamageKind.userLevel;

  const FixedDamageMoveBehavior.psywave()
      : battleEngineMethod = 's_psywave',
        _kind = _FixedDamageKind.psywave;

  const FixedDamageMoveBehavior.halfCurrentTargetHp()
      : battleEngineMethod = 's_super_fang',
        _kind = _FixedDamageKind.halfCurrentTargetHp;

  @override
  final String battleEngineMethod;
  final _FixedDamageKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final target = prepared.psdkTargets.single;
    final damage = _resolveDamage(
      context: context,
      prepared: prepared,
      target: target,
    );
    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: target,
      moveId: context.move.id,
      rng: damage.rng,
      turn: context.turn,
      amount: damage.amount,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: target,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  _ResolvedFixedDamage _resolveDamage({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
    required PsdkBattleSlotRef target,
  }) {
    return switch (_kind) {
      _FixedDamageKind.psdkFixedDamage => _ResolvedFixedDamage(
          amount: _psdkFixedDamageByDbSymbol[context.move.dbSymbol] ?? 1,
          rng: prepared.rng,
        ),
      _FixedDamageKind.userLevel => _ResolvedFixedDamage(
          amount: prepared.state.battlerAt(context.user).level,
          rng: prepared.rng,
        ),
      _FixedDamageKind.psywave => _resolvePsywaveDamage(
          context: context,
          prepared: prepared,
        ),
      _FixedDamageKind.halfCurrentTargetHp => _ResolvedFixedDamage(
          amount: _halfHpDamage(prepared.state.battlerAt(target).currentHp),
          rng: prepared.rng,
        ),
    };
  }

  _ResolvedFixedDamage _resolvePsywaveDamage({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final roll = prepared.rng.moveDamage.nextIntInclusive(min: 1, max: 100);
    final user = prepared.state.battlerAt(context.user);
    final amount = ((user.level * (roll.value + 50)) / 100).floor();
    return _ResolvedFixedDamage(
      amount: amount < 1 ? 1 : amount,
      rng: prepared.rng.copyWith(moveDamage: roll.next),
    );
  }

  int _halfHpDamage(int currentHp) {
    final amount = currentHp ~/ 2;
    return amount < 1 ? 1 : amount;
  }
}

final class _ResolvedFixedDamage {
  const _ResolvedFixedDamage({
    required this.amount,
    required this.rng,
  });

  final int amount;
  final BattleRngStreams rng;
}
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

enum _HealMoveKind {
  half,
  weather,
  floralHealing,
  roost,
  shoreUp,
  quarter,
  jungleHealing,
}

/// Ports the base PSDK `HealMove` behavior: heal each actual target by half of
/// its max HP after the shared move procedure succeeds.
///
/// Local ratio variants are kept here because their PSDK Ruby classes only
/// change the heal fraction. They still remain partial in the registry until
/// Heal Block, Substitute, Mega Launcher and persistent move effects exist as
/// first-class hooks.
final class HealMoveBehavior implements BattleMoveBehavior {
  const HealMoveBehavior()
      : battleEngineMethod = 's_heal',
        _kind = _HealMoveKind.half;

  const HealMoveBehavior.weather()
      : battleEngineMethod = 's_heal_weather',
        _kind = _HealMoveKind.weather;

  const HealMoveBehavior.floralHealing()
      : battleEngineMethod = 's_floral_healing',
        _kind = _HealMoveKind.floralHealing;

  const HealMoveBehavior.roost()
      : battleEngineMethod = 's_roost',
        _kind = _HealMoveKind.roost;

  const HealMoveBehavior.shoreUp()
      : battleEngineMethod = 's_shore_up',
        _kind = _HealMoveKind.shoreUp;

  const HealMoveBehavior.lifeDew()
      : battleEngineMethod = 's_life_dew',
        _kind = _HealMoveKind.quarter;

  const HealMoveBehavior.jungleHealing()
      : battleEngineMethod = 's_jungle_healing',
        _kind = _HealMoveKind.jungleHealing;

  @override
  final String battleEngineMethod;
  final _HealMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (final target in prepared.psdkTargets) {
      final battler = state.battlerAt(target);
      final amount = _healAmount(prepared.state, battler.maxHp);
      final heal = applyDirectHeal(
        state: state,
        user: context.user,
        target: target,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: amount,
      );
      state = heal.state;
      rng = heal.rng;
      if (heal.event != null) {
        events.add(heal.event!);
      }
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  int _healAmount(
    PsdkBattleState state,
    int maxHp,
  ) {
    return switch (_kind) {
      _HealMoveKind.half || _HealMoveKind.roost => maxHp ~/ 2,
      _HealMoveKind.weather => _weatherHealAmount(state, maxHp),
      _HealMoveKind.floralHealing => state.field.isTerrainActive(
          PsdkBattleTerrainId.grassyTerrain,
        )
            ? _ratio(maxHp, 2, 3)
            : maxHp ~/ 2,
      _HealMoveKind.shoreUp =>
        state.isWeatherEffectActive(PsdkBattleWeatherId.sandstorm)
            ? _ratio(maxHp, 2, 3)
            : maxHp ~/ 2,
      _HealMoveKind.quarter || _HealMoveKind.jungleHealing => maxHp ~/ 4,
    };
  }

  int _weatherHealAmount(
    PsdkBattleState state,
    int maxHp,
  ) {
    final weather =
        state.weatherEffectsSuppressed ? null : state.field.weather?.id;
    return switch (weather) {
      PsdkBattleWeatherId.sunny ||
      PsdkBattleWeatherId.hardsun =>
        _ratio(maxHp, 2, 3),
      null || PsdkBattleWeatherId.strongWinds => maxHp ~/ 2,
      _ => maxHp ~/ 4,
    };
  }
}

int _ratio(int value, int numerator, int denominator) {
  return (value * numerator) ~/ denominator;
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_handler_result.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _HitThenCureStatusKind {
  smellingSalt,
  wakeUpSlap,
  sparklingAria,
}

/// Ports PSDK Basic descendants that damage a target and cure a matching major
/// status afterwards.
///
/// The local effect is intentionally narrow: power override, normal Basic
/// damage, then status cure. Ability/item/effect hooks that can alter damage
/// or cure processing still keep these entries partial in the manifest.
final class HitThenCureStatusMoveBehavior implements BattleMoveBehavior {
  const HitThenCureStatusMoveBehavior.smellingSalt()
      : battleEngineMethod = 's_smelling_salt',
        _kind = _HitThenCureStatusKind.smellingSalt;

  const HitThenCureStatusMoveBehavior.wakeUpSlap()
      : battleEngineMethod = 's_wakeup_slap',
        _kind = _HitThenCureStatusKind.wakeUpSlap;

  const HitThenCureStatusMoveBehavior.sparklingAria()
      : battleEngineMethod = 's_sparkling_aria',
        _kind = _HitThenCureStatusKind.sparklingAria;

  @override
  final String battleEngineMethod;
  final _HitThenCureStatusKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (final targetSlot in prepared.psdkTargets) {
      final user = state.battlerAt(context.user);
      final target = state.battlerAt(targetSlot);
      final move = _damageMove(context.move, target);
      final damageResult = const BattleMoveDamageCalculator().calculate(
        BattleMoveDamageContext(
          user: user,
          target: target,
          move: move,
          rng: rng,
        ),
      );
      rng = damageResult.rng;
      if (damageResult.damage <= 0) {
        continue;
      }

      final damage = applyDirectDamage(
        state: state,
        user: context.user,
        target: targetSlot,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: damageResult.damage,
      );
      state = damage.state;
      rng = damage.rng;
      if (damage.event != null) {
        events.add(damage.event!);
      }

      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: rng,
        user: context.user,
        target: targetSlot,
        move: context.move,
        turn: context.turn,
      );
      state = secondary.state;
      rng = secondary.rng;
      events.addAll(secondary.events);

      final cure = _cureStatus(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
        targetSlot: targetSlot,
        moveId: context.move.id,
      );
      state = cure.state;
      rng = cure.rng;
      if (cure.applied) {
        events.addAll(cure.events);
      }
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveDefinition _damageMove(
    BattleMoveDefinition move,
    PsdkBattleCombatant target,
  ) {
    if (!_boostsPower(target)) {
      return move;
    }
    return _moveWithPower(move, power: move.power * 2);
  }

  bool _boostsPower(PsdkBattleCombatant target) {
    return switch (_kind) {
      _HitThenCureStatusKind.smellingSalt =>
        target.majorStatus == PsdkBattleMajorStatus.paralysis,
      _HitThenCureStatusKind.wakeUpSlap =>
        target.majorStatus == PsdkBattleMajorStatus.sleep ||
            target.abilityId == 'comatose',
      _HitThenCureStatusKind.sparklingAria => false,
    };
  }

  BattleHandlerResult _cureStatus({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef targetSlot,
    required String moveId,
  }) {
    final target = state.battlerAt(targetSlot);
    final shouldCure = switch (_kind) {
      _HitThenCureStatusKind.smellingSalt =>
        target.majorStatus == PsdkBattleMajorStatus.paralysis,
      _HitThenCureStatusKind.wakeUpSlap =>
        target.majorStatus == PsdkBattleMajorStatus.sleep,
      _HitThenCureStatusKind.sparklingAria =>
        target.majorStatus == PsdkBattleMajorStatus.burn,
    };
    if (!shouldCure) {
      return BattleHandlerResult(
        state: state,
        rng: rng,
        applied: false,
        reason: 'status_not_matched',
      );
    }

    return const BattleStatusChangeHandler().cureMajorStatus(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: turn,
        user: user,
      ),
      target: targetSlot,
      moveId: moveId,
    );
  }
}

BattleMoveDefinition _moveWithPower(
  BattleMoveDefinition move, {
  required int power,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: move.type,
    category: move.category,
    power: power,
    accuracy: move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: move.priority,
    criticalRate: move.criticalRate,
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: move.flags,
    stageMods: move.stageMods,
    statuses: move.statuses,
  );
}
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

/// Partially ports the PSDK `MindBlown` Ruby class.
///
/// Pokemon SDK registers Mind Blown, Steel Beam and Chloroblast on the same
/// class. They are not regular recoil moves: after a successful Basic hit they
/// run `deal_effect`, which removes half of the user's max HP. The same crash
/// also happens when accuracy or target immunity prevents the hit. Ability
/// gates (`Damp`, `Wonder Guard`) remain outside this slice because the PSDK
/// combatant snapshot does not carry ability data yet.
final class MindBlownMoveBehavior implements BattleMoveBehavior {
  const MindBlownMoveBehavior.mindBlown() : battleEngineMethod = 's_mind_blown';

  const MindBlownMoveBehavior.steelBeam() : battleEngineMethod = 's_steel_beam';

  const MindBlownMoveBehavior.chloroblast()
      : battleEngineMethod = 's_chloroblast';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      if (_shouldCrashAfterFailure(prepared.failureReason)) {
        return _crashUser(
          context: context,
          state: prepared.state,
          rng: prepared.rng,
          events: prepared.events,
          successful: false,
        );
      }
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return _crashUser(
        context: context,
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final targetDamage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    var state = targetDamage.state;
    final events = <PsdkBattleEvent>[
      ...prepared.events,
      if (targetDamage.event != null) targetDamage.event!,
    ];

    // PSDK `MindBlown < Basic` reaches `deal_effect` after secondary status
    // and stat riders (`deal_status` / `deal_stats`). Keeping this order here
    // prevents the self-crash from hiding riders when the user faints.
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: targetDamage.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    state = secondary.state;
    events.addAll(secondary.events);

    return _crashUser(
      context: context,
      state: state,
      rng: secondary.rng,
      events: events,
    );
  }

  bool _shouldCrashAfterFailure(BattleMoveFailureReason? reason) {
    return switch (reason) {
      BattleMoveFailureReason.accuracy ||
      BattleMoveFailureReason.immunity =>
        true,
      // In Ruby PSDK, Protect-style target prevention removes all actual
      // targets inside `accuracy_immunity_test`, then calls `on_move_failure`
      // with `:immunity`. The Dart lane keeps a clearer `protected` reason for
      // event consumers, but the MindBlown crash semantics are the same.
      BattleMoveFailureReason.protected => true,
      _ => false,
    };
  }

  BattleMoveBehaviorResolution _crashUser({
    required BattleMoveBehaviorContext context,
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required List<PsdkBattleEvent> events,
    bool successful = true,
  }) {
    final user = state.battlerAt(context.user);
    final crash = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: user.maxHp ~/ 2,
    );

    return BattleMoveBehaviorResolution(
      state: crash.state,
      rng: crash.rng,
      events: <PsdkBattleEvent>[
        ...events,
        if (crash.event != null) crash.event!,
      ],
      successful: successful,
    );
  }
}
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/ability/ability_effect.dart';
import '../../effect/item/item_effect.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

const List<int> _psdkMultiHitChances = <int>[2, 2, 2, 3, 3, 5, 4, 3];

enum _MultiHitKind {
  fixed,
  psdkRandomTwoToFive,
  tripleKick,
  populationBomb,
}

/// Ports the first deterministic slice of PSDK multi-hit moves.
///
/// This covers the Ruby `TwoHit`, `ThreeHit`, base `MultiHit`, Triple Kick and
/// Population Bomb classes. Ability/form-specific branches such as Skill Link,
/// Population Bomb's `always_hit?` override and Ash-Greninja Water Shuriken stay
/// partial until those combatant contracts exist in the PSDK lane.
final class MultiHitMoveBehavior implements BattleMoveBehavior {
  const MultiHitMoveBehavior.fixed({
    required this.battleEngineMethod,
    required int hitCount,
  })  : _hitCount = hitCount,
        _kind = _MultiHitKind.fixed;

  const MultiHitMoveBehavior.psdkRandom()
      : battleEngineMethod = 's_multi_hit',
        _hitCount = null,
        _kind = _MultiHitKind.psdkRandomTwoToFive;

  const MultiHitMoveBehavior.tripleKick()
      : battleEngineMethod = 's_triple_kick',
        _hitCount = 3,
        _kind = _MultiHitKind.tripleKick;

  const MultiHitMoveBehavior.populationBomb()
      : battleEngineMethod = 's_population_bomb',
        _hitCount = 10,
        _kind = _MultiHitKind.populationBomb;

  const MultiHitMoveBehavior.waterShuriken()
      : battleEngineMethod = 's_water_shuriken',
        _hitCount = null,
        _kind = _MultiHitKind.psdkRandomTwoToFive;

  @override
  final String battleEngineMethod;
  final int? _hitCount;
  final _MultiHitKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final target = prepared.psdkTargets.single;
    final hitPlan = _resolveHitCount(context, prepared, target);
    var state = prepared.state;
    var rng = hitPlan.rng;
    var dealtDamage = false;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (var hitIndex = 0; hitIndex < hitPlan.hitCount; hitIndex += 1) {
      final user = state.battlerAt(context.user);
      final targetBattler = state.battlerAt(target);
      if (user.isFainted || targetBattler.isFainted) {
        break;
      }

      if (_rechecksAccuracy && hitIndex > 0) {
        final accuracy = _resolveExtraHitAccuracy(
          state: state,
          user: context.user,
          target: target,
          move: context.move,
          rng: rng,
          moveAccuracy: context.move.accuracy,
        );
        rng = accuracy.rng;
        if (!accuracy.didHit) {
          events.add(
            PsdkBattleMissEvent(
              user: context.user,
              target: target,
              moveId: context.move.id,
            ),
          );
          break;
        }
      }

      // PSDK plays the animation again after the first successful hit. The
      // common procedure already emitted the first cue, so only repeat extras.
      if (hitIndex > 0) {
        events.add(
          PsdkBattleAnimationCueEvent(
            user: context.user,
            target: target,
            moveId: context.move.id,
          ),
        );
      }

      final damage = const BattleMoveDamageCalculator().calculate(
        BattleMoveDamageContext(
          user: user,
          target: targetBattler,
          move: context.move,
          rng: rng,
          overrides: BattleMoveDamageOverrides(
            power: _powerForHit(context.move.power, hitIndex),
          ),
        ),
      );
      rng = damage.rng;
      if (damage.damage <= 0) {
        continue;
      }

      final applied = applyDirectDamage(
        state: state,
        user: context.user,
        target: target,
        moveId: context.move.id,
        rng: rng,
        turn: context.turn,
        amount: damage.damage,
      );
      state = applied.state;
      rng = applied.rng;
      if (applied.event != null) {
        dealtDamage = true;
        events.add(applied.event!);
      }
    }

    if (dealtDamage) {
      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: rng,
        user: context.user,
        target: target,
        move: context.move,
        turn: context.turn,
      );
      state = secondary.state;
      rng = secondary.rng;
      events.addAll(secondary.events);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  _ResolvedHitCount _resolveHitCount(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
    PsdkBattleSlotRef target,
  ) {
    final forced = _forcedHitCount(
      context: context,
      state: prepared.state,
      target: target,
    );
    if (forced != null) {
      return _ResolvedHitCount(hitCount: forced, rng: prepared.rng);
    }
    return switch (_kind) {
      _MultiHitKind.fixed => _ResolvedHitCount(
          hitCount: _hitCount!,
          rng: prepared.rng,
        ),
      _MultiHitKind.psdkRandomTwoToFive => _resolvePsdkRandomHitCount(
          context: context,
          prepared: prepared,
        ),
      _MultiHitKind.tripleKick ||
      _MultiHitKind.populationBomb =>
        _ResolvedHitCount(
          hitCount: _hitCount!,
          rng: prepared.rng,
        ),
    };
  }

  _ResolvedHitCount _resolvePsdkRandomHitCount({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final roll = prepared.rng.generic.nextIntInclusive(
      min: 0,
      max: _psdkMultiHitChances.length - 1,
    );
    final rolledHitCount = _psdkMultiHitChances[roll.value];
    final minimumHitCount = _minimumHitCount(context);
    return _ResolvedHitCount(
      hitCount: minimumHitCount == null || rolledHitCount >= minimumHitCount
          ? rolledHitCount
          : minimumHitCount,
      rng: prepared.rng.copyWith(generic: roll.next),
    );
  }

  bool get _rechecksAccuracy {
    return switch (_kind) {
      _MultiHitKind.tripleKick || _MultiHitKind.populationBomb => true,
      _ => false,
    };
  }

  int _powerForHit(int movePower, int hitIndex) {
    return switch (_kind) {
      _MultiHitKind.tripleKick => movePower * (hitIndex + 1),
      _ => movePower,
    };
  }

  _ExtraHitAccuracy _resolveExtraHitAccuracy({
    required PsdkBattleState state,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required BattleMoveDefinition move,
    required BattleRngStreams rng,
    required int moveAccuracy,
  }) {
    final abilityContext = BattleAbilityMoveContext(
      state: state,
      user: user,
      target: target,
      move: move,
    );
    if (moveAccuracy <= 0 ||
        moveAccuracy >= 100 ||
        state.activeAbilityEffects().any(
              (effect) => effect.bypassesAccuracy(abilityContext),
            ) ||
        state.battlerAt(user).abilityEffects.any(
              (effect) => effect.bypassesMultiHitAccuracyRecheck(
                abilityContext,
              ),
            )) {
      return _ExtraHitAccuracy(didHit: true, rng: rng);
    }
    final roll = rng.moveAccuracy.nextPercent();
    return _ExtraHitAccuracy(
      didHit: roll.value <= moveAccuracy,
      rng: rng.copyWith(moveAccuracy: roll.next),
    );
  }
}

int? _forcedHitCount({
  required BattleMoveBehaviorContext context,
  required PsdkBattleState state,
  required PsdkBattleSlotRef target,
}) {
  final abilityContext = BattleAbilityMoveContext(
    state: state,
    user: context.user,
    target: target,
    move: context.move,
  );
  for (final effect in state.battlerAt(context.user).abilityEffects) {
    final hitCount = effect.forcedHitCount(abilityContext);
    if (hitCount != null) {
      return hitCount;
    }
  }
  return null;
}

int? _minimumHitCount(BattleMoveBehaviorContext context) {
  for (final effect in context.state.battlerAt(context.user).itemEffects) {
    final minimum = effect.minimumHitCount(context.move);
    if (minimum != null) {
      return minimum;
    }
  }
  return null;
}

final class _ResolvedHitCount {
  const _ResolvedHitCount({
    required this.hitCount,
    required this.rng,
  });

  final int hitCount;
  final BattleRngStreams rng;
}

final class _ExtraHitAccuracy {
  const _ExtraHitAccuracy({
    required this.didHit,
    required this.rng,
  });

  final bool didHit;
  final BattleRngStreams rng;
}
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

enum _NoEffectMoveKind {
  splash,
  doNothing,
}

/// Ports PSDK moves whose Ruby `deal_effect` intentionally does not mutate
/// battle state.
///
/// The shared move procedure still emits declaration and animation events, and
/// still owns target resolution, accuracy, Protect and immunity. Splash remains
/// marked partial in the matrix because PSDK also displays a localized
/// "nothing happened" message, while this pure battle lane has no text event
/// contract yet.
final class NoEffectMoveBehavior implements BattleMoveBehavior {
  const NoEffectMoveBehavior.splash()
      : battleEngineMethod = 's_splash',
        _kind = _NoEffectMoveKind.splash;

  const NoEffectMoveBehavior.doNothing()
      : battleEngineMethod = 's_do_nothing',
        _kind = _NoEffectMoveKind.doNothing;

  @override
  final String battleEngineMethod;
  final _NoEffectMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    // Both PSDK classes are deliberately state-neutral. The switch keeps the
    // family explicit so future message/event support can specialize Splash
    // without changing the registry contract.
    return switch (_kind) {
      _NoEffectMoveKind.splash ||
      _NoEffectMoveKind.doNothing =>
        prepared.toResolution(successful: true),
    };
  }
}
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../effect/battle_effect_scope.dart';
import '../../effect/move/aqua_ring_effect.dart';
import '../../effect/move/ingrain_effect.dart';
import '../../effect/move/leech_seed_effect.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

enum _PersistentEffectKind {
  aquaRing,
  ingrain,
  leechSeed,
}

final class PersistentEffectMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const PersistentEffectMoveBehavior.aquaRing()
      : battleEngineMethod = 's_aqua_ring',
        _kind = _PersistentEffectKind.aquaRing;

  const PersistentEffectMoveBehavior.ingrain()
      : battleEngineMethod = 's_ingrain',
        _kind = _PersistentEffectKind.ingrain;

  const PersistentEffectMoveBehavior.leechSeed()
      : battleEngineMethod = 's_leech_seed',
        _kind = _PersistentEffectKind.leechSeed;

  @override
  final String battleEngineMethod;
  final _PersistentEffectKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    return switch (_kind) {
      _PersistentEffectKind.aquaRing =>
        context.state.battlerAt(context.target).effects.contains('aqua_ring')
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
      _PersistentEffectKind.ingrain =>
        context.state.battlerAt(context.target).effects.contains('ingrain')
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
      _PersistentEffectKind.leechSeed =>
        _isLeechSeedImmune(context.state.battlerAt(context.target))
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.immunity,
              )
            : null,
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    final events = <PsdkBattleEvent>[...prepared.events];
    for (final target in prepared.psdkTargets) {
      final effect = switch (_kind) {
        _PersistentEffectKind.aquaRing =>
          state.battlerAt(target).effects.contains('aqua_ring')
              ? null
              : AquaRingEffect(scope: BattlerBattleEffectScope(target)),
        _PersistentEffectKind.ingrain =>
          state.battlerAt(target).effects.contains('ingrain')
              ? null
              : IngrainEffect(scope: BattlerBattleEffectScope(target)),
        _PersistentEffectKind.leechSeed =>
          _isLeechSeedImmune(state.battlerAt(target))
              ? null
              : LeechSeedEffect(
                  scope: BattlerBattleEffectScope(target),
                  source: context.user,
                ),
      };
      if (effect == null) {
        continue;
      }
      state = state.updateBattler(
        target,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(effect),
        ),
      );
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: prepared.rng,
      events: events,
    );
  }
}

bool _isLeechSeedImmune(PsdkBattleCombatant battler) {
  return battler.effects.contains('leech_seed') ||
      battler.effects.contains('substitute') ||
      battler.hasType('grass');
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

/// Ports PSDK Power Trick's base Attack/Defense exchange.
///
/// Ruby PSDK writes `atk_basis` and `dfe_basis` on the affected target. The
/// Dart lane mirrors that through immutable stat snapshots and leaves stat
/// stages untouched.
final class PowerTrickMoveBehavior implements BattleMoveBehavior {
  const PowerTrickMoveBehavior();

  @override
  String get battleEngineMethod => 's_power_trick';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    for (final targetSlot in prepared.psdkTargets) {
      final target = state.battlerAt(targetSlot);
      state = state.replaceBattler(
        targetSlot,
        target.copyWith(
          stats: _statsWith(
            target.stats,
            attack: target.stats.defense,
            defense: target.stats.attack,
          ),
        ),
      );
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[...prepared.events],
    );
  }
}

PsdkBattleStats _statsWith(
  PsdkBattleStats stats, {
  int? attack,
  int? defense,
}) {
  return PsdkBattleStats(
    attack: attack ?? stats.attack,
    defense: defense ?? stats.defense,
    specialAttack: stats.specialAttack,
    specialDefense: stats.specialDefense,
    speed: stats.speed,
  );
}
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

/// Ports the local PSDK `Move::PsychoShift` status transfer.
///
/// Full target immunity/process-hook parity stays tracked as partial in the
/// move matrix; this behavior keeps the deterministic transfer path aligned.
final class PsychoShiftMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const PsychoShiftMoveBehavior();

  @override
  String get battleEngineMethod => 's_psycho_shift';

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (user.majorStatus != null) {
      return null;
    }
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return _failedBeforeProcedure(context, prevention);
    }

    final status = context.state.battlerAt(context.user).majorStatus!;
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (final target in prepared.psdkTargets) {
      final applied = const BattleStatusChangeHandler().applyMajorStatus(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
        ),
        target: target,
        moveId: context.move.id,
        status: status,
      );
      state = applied.state;
      rng = applied.rng;
      if (!applied.applied) {
        continue;
      }
      events.addAll(applied.events);

      final cured = const BattleStatusChangeHandler().cureMajorStatus(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
        ),
        target: context.user,
        moveId: context.move.id,
      );
      state = cured.state;
      rng = cured.rng;
      if (cured.applied) {
        events.addAll(cured.events);
      }
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _failedBeforeProcedure(
    BattleMoveBehaviorContext context,
    BattleMoveUserPreventionResult prevention,
  ) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: prevention.reason.jsonName,
        ),
      ],
      successful: false,
    );
  }
}
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

/// Ports PSDK `Move::Purify`.
///
/// The local behavior covers the move's direct status cure and half-max-HP
/// user heal. It intentionally stays in the status utility lane; richer PSDK
/// process hooks such as Substitute/effect interception are tracked in the
/// parity matrix instead of being guessed here.
final class PurifyMoveBehavior implements BattleMoveUserPreventionBehavior {
  const PurifyMoveBehavior();

  @override
  String get battleEngineMethod => 's_purify';

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final target = context.state.battlerAt(context.target);
    if (target.majorStatus != null) {
      return null;
    }
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return _failedBeforeProcedure(context, prevention);
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];

    for (final target in prepared.psdkTargets) {
      final cure = const BattleStatusChangeHandler().cureMajorStatus(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
        ),
        target: target,
        moveId: context.move.id,
      );
      state = cure.state;
      rng = cure.rng;
      if (cure.applied) {
        events.addAll(cure.events);
      }
    }

    final user = state.battlerAt(context.user);
    final heal = applyDirectHeal(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: user.maxHp ~/ 2,
    );
    state = heal.state;
    rng = heal.rng;
    if (heal.event != null) {
      events.add(heal.event!);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _failedBeforeProcedure(
    BattleMoveBehaviorContext context,
    BattleMoveUserPreventionResult prevention,
  ) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: prevention.reason.jsonName,
        ),
      ],
      successful: false,
    );
  }
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/ability/ability_effect.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

const Map<String, int> _psdkRecoilFactors = <String, int>{
  'brave_bird': 3,
  'double_edge': 3,
  'chloroblast': 2,
  'flare_blitz': 3,
  'head_charge': 4,
  'head_smash': 2,
  'light_of_ruin': 2,
  'shadow_end': 2,
  'shadow_rush': 16,
  'struggle': 4,
  'submission': 4,
  'take_down': 4,
  'volt_tackle': 3,
  'wave_crash': 3,
  'wild_charge': 4,
  'wood_hammer': 3,
};

const Set<String> _recoilFromUserMaxHp = <String>{
  'struggle',
  'shadow_rush',
};

const Set<String> _recoilFromUserCurrentHp = <String>{
  'shadow_end',
};

/// Ports the base PSDK `RecoilMove` family.
///
/// The target hit still uses the normal damage formula and shared move
/// procedure. Recoil is represented as a second damage event targeting the
/// user. This is intentionally partial: abilities such as Rock Head and
/// Parental Bond, item callbacks, dedicated recoil messages and Basculin
/// evolution bookkeeping are not available in the current PSDK lane.
final class RecoilMoveBehavior implements BattleMoveBehavior {
  const RecoilMoveBehavior.psdkRecoil() : battleEngineMethod = 's_recoil';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final abilityContext = BattleAbilityMoveContext(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      move: context.move,
    );
    final resolvedPower = _resolvePowerWithAbility(
      user: user,
      context: abilityContext,
      movePower: context.move.power,
    );
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final targetDamage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    var state = targetDamage.state;
    final events = <PsdkBattleEvent>[
      ...prepared.events,
      if (targetDamage.event != null) targetDamage.event!,
    ];
    if (targetDamage.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: state,
        rng: damageResult.rng,
        events: events,
      );
    }

    final recoilBase = _recoilBaseDamage(
      dbSymbol: context.move.dbSymbol,
      user: user,
      targetDamage: targetDamage.damage,
    );
    final recoilDamage = _recoilDamage(
      baseDamage: recoilBase,
      factor: _recoilFactor(context.move.dbSymbol),
    );
    if (_preventsRecoil(user: user, context: abilityContext)) {
      final secondary = const BattleMoveSecondaryEffectResolver().resolve(
        state: state,
        rng: targetDamage.rng,
        user: context.user,
        target: targetSlot,
        move: context.move,
        turn: context.turn,
      );
      return BattleMoveBehaviorResolution(
        state: secondary.state,
        rng: secondary.rng,
        events: <PsdkBattleEvent>[
          ...events,
          ...secondary.events,
        ],
      );
    }
    final recoil = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: targetDamage.rng,
      turn: context.turn,
      amount: recoilDamage,
    );
    state = recoil.state;
    if (recoil.event != null) {
      events.add(recoil.event!);
    }

    // PSDK Basic applies recoil immediately after target damage and before
    // status/stat/effect riders. Keeping secondary effects after the self-hit
    // preserves that order for animation consumers and tests.
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: recoil.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    state = secondary.state;
    events.addAll(secondary.events);

    return BattleMoveBehaviorResolution(
      state: state,
      rng: secondary.rng,
      events: events,
    );
  }

  int _recoilFactor(String dbSymbol) {
    return _psdkRecoilFactors[dbSymbol] ?? 4;
  }

  int _recoilBaseDamage({
    required String dbSymbol,
    required PsdkBattleCombatant user,
    required int targetDamage,
  }) {
    if (_recoilFromUserMaxHp.contains(dbSymbol)) {
      return user.maxHp;
    }
    if (_recoilFromUserCurrentHp.contains(dbSymbol)) {
      return user.currentHp;
    }
    // PSDK `damages` clamps normal move damage to the target's current HP
    // before `recoil(hp, user)` receives it. `applyDirectDamage.damage` is the
    // same clamped amount in this Dart lane.
    return targetDamage;
  }

  int _recoilDamage({
    required int baseDamage,
    required int factor,
  }) {
    final damage = baseDamage ~/ factor;
    return damage < 1 ? 1 : damage;
  }

  int _resolvePowerWithAbility({
    required PsdkBattleCombatant user,
    required BattleAbilityMoveContext context,
    required int movePower,
  }) {
    var multiplier = 1.0;
    for (final effect in user.abilityEffects) {
      multiplier *= effect.basePowerMultiplier(context);
    }
    final resolvedPower = (movePower * multiplier).floor();
    return resolvedPower < 1 ? 1 : resolvedPower;
  }

  bool _preventsRecoil({
    required PsdkBattleCombatant user,
    required BattleAbilityMoveContext context,
  }) {
    return user.abilityEffects.any((effect) => effect.preventsRecoil(context));
  }
}
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../handler/battle_status_change_handler.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _RecoveryStatKind {
  rest,
  bellyDrum,
  filletAway,
  strengthSap,
}

/// Ports small PSDK status moves that combine HP, major status and stat-stage
/// changes without needing a persistent effect object.
///
/// These stay partial in the manifest until item/ability/effect gates such as
/// Chesto Berry, Heal Block, Liquid Ooze, Big Root, Contrary and terrain sleep
/// prevention are represented by first-class hooks.
final class RecoveryStatMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const RecoveryStatMoveBehavior.rest()
      : battleEngineMethod = 's_rest',
        _kind = _RecoveryStatKind.rest;

  const RecoveryStatMoveBehavior.bellyDrum()
      : battleEngineMethod = 's_bellydrum',
        _kind = _RecoveryStatKind.bellyDrum;

  const RecoveryStatMoveBehavior.filletAway()
      : battleEngineMethod = 's_fillet_away',
        _kind = _RecoveryStatKind.filletAway;

  const RecoveryStatMoveBehavior.strengthSap()
      : battleEngineMethod = 's_strength_sap',
        _kind = _RecoveryStatKind.strengthSap;

  @override
  final String battleEngineMethod;
  final _RecoveryStatKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    return switch (_kind) {
      _RecoveryStatKind.rest => user.currentHp >= user.maxHp ||
              _hasAbilityId(
                user.abilityId,
                const <String>{
                  'comatose',
                  'insomnia',
                  'purifying_salt',
                  'sweet_veil',
                  'vital_spirit',
                },
              )
          ? const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            )
          : null,
      _RecoveryStatKind.bellyDrum => user.currentHp * 2 <= user.maxHp ||
              user.statStages.valueOf('attack') >= 6
          ? const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            )
          : null,
      _RecoveryStatKind.filletAway => user.currentHp * 2 <= user.maxHp ||
              _offensiveFilletStats.every(
                (stat) => user.statStages.valueOf(stat) >= 6,
              )
          ? const BattleMoveUserPreventionResult(
              reason: BattleMoveFailureReason.unusableByUser,
            )
          : null,
      _RecoveryStatKind.strengthSap =>
        context.state.battlerAt(context.target).statStages.valueOf('attack') <=
                -6
            ? const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              )
            : null,
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return _failedBeforeProcedure(context, prevention);
    }

    return switch (_kind) {
      _RecoveryStatKind.rest => _resolveRest(context),
      _RecoveryStatKind.bellyDrum => _resolveBellyDrum(context),
      _RecoveryStatKind.filletAway => _resolveFilletAway(context),
      _RecoveryStatKind.strengthSap => _resolveStrengthSap(context),
    };
  }

  BattleMoveBehaviorResolution _resolveRest(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final target = state.battlerAt(targetSlot);
    if (target.majorStatus != null) {
      final cure = const BattleStatusChangeHandler().cureMajorStatus(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
        ),
        target: targetSlot,
        moveId: context.move.id,
      );
      state = cure.state;
      rng = cure.rng;
      if (cure.applied) {
        events.addAll(cure.events);
      }
    }

    final sleep = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
      ),
      target: targetSlot,
      moveId: context.move.id,
      status: PsdkBattleMajorStatus.sleep,
    );
    state = sleep.state;
    rng = sleep.rng;
    if (sleep.applied) {
      events.addAll(sleep.events);
    }

    final healedTarget = state.battlerAt(targetSlot);
    final heal = applyDirectHeal(
      state: state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: healedTarget.maxHp,
    );
    state = heal.state;
    rng = heal.rng;
    if (heal.event != null) {
      events.add(heal.event!);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveBellyDrum(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final target = state.battlerAt(targetSlot);
    final damage = applyDirectDamage(
      state: state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: target.maxHp ~/ 2,
    );
    state = damage.state;
    rng = damage.rng;
    if (damage.event != null) {
      events.add(damage.event!);
    }

    final stat = const BattleStatChangeHandler().applyStatChange(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: context.turn,
        user: context.user,
      ),
      target: targetSlot,
      stat: 'attack',
      stages: 12,
    );
    state = stat.state;
    rng = stat.rng;
    if (stat.applied) {
      events.addAll(stat.events);
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveFilletAway(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final target = state.battlerAt(targetSlot);
    final damage = applyDirectDamage(
      state: state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: target.maxHp ~/ 2,
    );
    state = damage.state;
    rng = damage.rng;
    if (damage.event != null) {
      events.add(damage.event!);
    }

    for (final statName in _offensiveFilletStats) {
      final stat = const BattleStatChangeHandler().applyStatChange(
        context: BattleHandlerContext(
          state: state,
          rng: rng,
          turn: context.turn,
          user: context.user,
        ),
        target: targetSlot,
        stat: statName,
        stages: 2,
      );
      state = stat.state;
      rng = stat.rng;
      if (stat.applied) {
        events.addAll(stat.events);
      }
    }

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _resolveStrengthSap(
    BattleMoveBehaviorContext context,
  ) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    var state = prepared.state;
    var rng = prepared.rng;
    final events = <PsdkBattleEvent>[...prepared.events];
    final targetSlot = prepared.psdkTargets.single;
    final target = state.battlerAt(targetSlot);
    final heal = applyDirectHeal(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: target.effectiveStat('attack'),
    );
    state = heal.state;
    rng = heal.rng;
    if (heal.event != null) {
      events.add(heal.event!);
    }

    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    state = secondary.state;
    rng = secondary.rng;
    events.addAll(secondary.events);

    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: events,
    );
  }

  BattleMoveBehaviorResolution _failedBeforeProcedure(
    BattleMoveBehaviorContext context,
    BattleMoveUserPreventionResult prevention,
  ) {
    return BattleMoveBehaviorResolution(
      state: context.state,
      rng: context.rng,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: prevention.reason.jsonName,
        ),
      ],
      successful: false,
    );
  }
}

const _offensiveFilletStats = <String>[
  'attack',
  'specialAttack',
  'speed',
];

bool _hasAbilityId(String? abilityId, Set<String> expectedIds) {
  if (abilityId == null) {
    return false;
  }
  return expectedIds.contains(abilityId.toLowerCase());
}
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _SelfDestructKind {
  explosion,
  mistyExplosion,
}

/// Partially ports PSDK `SelfDestruct`, registered as `s_explosion`.
///
/// PSDK keeps Self-Destruct and Explosion on the same Ruby class. Its local
/// effect removes the user's *current* HP after a successful Basic damage
/// pipeline, and also after target-immunity failures. The Dart procedure has a
/// distinct `protected` reason, so Protect is mapped to the same self-KO branch
/// because PSDK reaches it through the `:immunity` failure path.
///
/// `Damp` intentionally stays out of this lot: the current PSDK combatant
/// snapshot has no ability field, so claiming full parity would be dishonest.
final class SelfDestructMoveBehavior implements BattleMoveBehavior {
  const SelfDestructMoveBehavior.explosion()
      : battleEngineMethod = 's_explosion',
        _kind = _SelfDestructKind.explosion;

  const SelfDestructMoveBehavior.mistyExplosion()
      : battleEngineMethod = 's_misty_explosion',
        _kind = _SelfDestructKind.mistyExplosion;

  @override
  final String battleEngineMethod;
  final _SelfDestructKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      if (_shouldSelfKoAfterFailure(prepared.failureReason)) {
        return _selfKoUser(
          context: context,
          state: prepared.state,
          rng: prepared.rng,
          events: <PsdkBattleEvent>[
            ...prepared.events,
            PsdkBattleAnimationCueEvent(
              user: context.user,
              target: context.target,
              moveId: context.move.id,
            ),
          ],
          successful: false,
        );
      }
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = _resolvePower(context, prepared.state);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    if (damageResult.damage <= 0) {
      return _selfKoUser(
        context: context,
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final targetDamage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    var state = targetDamage.state;
    final events = <PsdkBattleEvent>[
      ...prepared.events,
      if (targetDamage.event != null) targetDamage.event!,
    ];

    // PSDK runs `deal_status` and `deal_stats` before `deal_effect` on
    // BasicWithSuccessfulEffect. Keeping riders before self-KO prevents a
    // future faint-process layer from masking successful secondary effects.
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: targetDamage.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    state = secondary.state;
    events.addAll(secondary.events);

    return _selfKoUser(
      context: context,
      state: state,
      rng: secondary.rng,
      events: events,
    );
  }

  bool _shouldSelfKoAfterFailure(BattleMoveFailureReason? reason) {
    return switch (reason) {
      BattleMoveFailureReason.immunity => true,
      BattleMoveFailureReason.protected => true,
      _ => false,
    };
  }

  int _resolvePower(
    BattleMoveBehaviorContext context,
    PsdkBattleState state,
  ) {
    return switch (_kind) {
      _SelfDestructKind.explosion => context.move.power,
      _SelfDestructKind.mistyExplosion =>
        state.field.isTerrainActive(PsdkBattleTerrainId.mistyTerrain)
            ? (context.move.power * 1.5).floor()
            : context.move.power,
    };
  }

  BattleMoveBehaviorResolution _selfKoUser({
    required BattleMoveBehaviorContext context,
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required List<PsdkBattleEvent> events,
    bool successful = true,
  }) {
    final user = state.battlerAt(context.user);
    final selfDamage = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: rng,
      turn: context.turn,
      amount: user.currentHp,
    );

    return BattleMoveBehaviorResolution(
      state: selfDamage.state,
      rng: selfDamage.rng,
      events: <PsdkBattleEvent>[
        ...events,
        if (selfDamage.event != null) selfDamage.event!,
      ],
      successful: successful,
    );
  }
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _SpecialPowerKind {
  acrobatics,
  storedPower,
}

/// Ports PSDK damage moves whose main rule is a local base-power override.
///
/// These behaviors still use the shared PSDK move procedure for target,
/// accuracy, Protect and immunity handling. Only the `real_base_power` style
/// calculation is specialized here.
final class SpecialPowerMoveBehavior implements BattleMoveBehavior {
  const SpecialPowerMoveBehavior.acrobatics()
      : battleEngineMethod = 's_acrobatics',
        _kind = _SpecialPowerKind.acrobatics;

  const SpecialPowerMoveBehavior.storedPower()
      : battleEngineMethod = 's_stored_power',
        _kind = _SpecialPowerKind.storedPower;

  @override
  final String battleEngineMethod;
  final _SpecialPowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = switch (_kind) {
      _SpecialPowerKind.acrobatics =>
        _acrobaticsPower(context.move.power, user),
      _SpecialPowerKind.storedPower =>
        _storedPower(context.move.power, context.move.dbSymbol, user, target),
    };
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }
}

int _acrobaticsPower(int movePower, PsdkBattleCombatant user) {
  if (user.heldItemId == null || user.itemConsumed) {
    return movePower * 2;
  }
  return movePower;
}

int _storedPower(
  int movePower,
  String dbSymbol,
  PsdkBattleCombatant user,
  PsdkBattleCombatant target,
) {
  if (dbSymbol == 'punishment') {
    final count = _positiveStageCount(target).clamp(0, 7).toInt();
    return 60 + (20 * count);
  }
  return movePower + (20 * _positiveStageCount(user));
}

int _positiveStageCount(PsdkBattleCombatant battler) {
  return battler.statStages.values.values
      .where((stage) => stage > 0)
      .fold<int>(0, (sum, stage) => sum + stage);
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

/// Ports PSDK Speed Swap's `spd_basis` exchange between user and target.
final class SpeedSwapMoveBehavior implements BattleMoveBehavior {
  const SpeedSwapMoveBehavior();

  @override
  String get battleEngineMethod => 's_speed_swap';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context, forceAccuracyBypass: true);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final nextState = prepared.state
        .replaceBattler(
          context.user,
          user.copyWith(
            stats: _statsWith(user.stats, speed: target.stats.speed),
          ),
        )
        .replaceBattler(
          targetSlot,
          target.copyWith(
            stats: _statsWith(target.stats, speed: user.stats.speed),
          ),
        );

    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[...prepared.events],
    );
  }
}

PsdkBattleStats _statsWith(PsdkBattleStats stats, {required int speed}) {
  return PsdkBattleStats(
    attack: stats.attack,
    defense: stats.defense,
    specialAttack: stats.specialAttack,
    specialDefense: stats.specialDefense,
    speed: speed,
  );
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

enum _StatSplitKind { power, guard }

/// Ports PSDK Power Split and Guard Split base-stat sharing.
///
/// Ruby PSDK writes the averaged `*_basis` values directly on both battlers.
/// The Dart lane mirrors that by replacing the immutable battle stat snapshots;
/// stat stages are intentionally left untouched.
final class StatSplitMoveBehavior implements BattleMoveBehavior {
  const StatSplitMoveBehavior.power()
      : battleEngineMethod = 's_power_split',
        _kind = _StatSplitKind.power;

  const StatSplitMoveBehavior.guard()
      : battleEngineMethod = 's_guard_split',
        _kind = _StatSplitKind.guard;

  @override
  final String battleEngineMethod;
  final _StatSplitKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);

    final nextUserStats = switch (_kind) {
      _StatSplitKind.power => _statsWith(
          user.stats,
          attack: _average(user.stats.attack, target.stats.attack),
          specialAttack: _average(
            user.stats.specialAttack,
            target.stats.specialAttack,
          ),
        ),
      _StatSplitKind.guard => _statsWith(
          user.stats,
          defense: _average(user.stats.defense, target.stats.defense),
          specialDefense: _average(
            user.stats.specialDefense,
            target.stats.specialDefense,
          ),
        ),
    };
    final nextTargetStats = switch (_kind) {
      _StatSplitKind.power => _statsWith(
          target.stats,
          attack: nextUserStats.attack,
          specialAttack: nextUserStats.specialAttack,
        ),
      _StatSplitKind.guard => _statsWith(
          target.stats,
          defense: nextUserStats.defense,
          specialDefense: nextUserStats.specialDefense,
        ),
    };

    final nextState = prepared.state
        .replaceBattler(context.user, user.copyWith(stats: nextUserStats))
        .replaceBattler(targetSlot, target.copyWith(stats: nextTargetStats));

    return BattleMoveBehaviorResolution(
      state: nextState,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[...prepared.events],
    );
  }
}

int _average(int left, int right) => (left + right) ~/ 2;

PsdkBattleStats _statsWith(
  PsdkBattleStats stats, {
  int? attack,
  int? defense,
  int? specialAttack,
  int? specialDefense,
  int? speed,
}) {
  return PsdkBattleStats(
    attack: attack ?? stats.attack,
    defense: defense ?? stats.defense,
    specialAttack: specialAttack ?? stats.specialAttack,
    specialDefense: specialDefense ?? stats.specialDefense,
    speed: speed ?? stats.speed,
  );
}
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _StatusStatKind {
  target,
  selfStat,
  selfStatus,
}

/// Ports PSDK's generic `StatusStat`, `SelfStat` and `SelfStatus` families.
///
/// These are intentionally small wrappers around the common move procedure:
/// `StatusStat` skips damage and applies status/stat payloads to the selected
/// target, while the self variants keep Basic damage but redirect either stats
/// or statuses to the user.
final class StatusStatMoveBehavior implements BattleMoveBehavior {
  const StatusStatMoveBehavior.status()
      : battleEngineMethod = 's_status',
        _kind = _StatusStatKind.target;

  const StatusStatMoveBehavior.stat()
      : battleEngineMethod = 's_stat',
        _kind = _StatusStatKind.target;

  const StatusStatMoveBehavior.selfStat()
      : battleEngineMethod = 's_self_stat',
        _kind = _StatusStatKind.selfStat;

  const StatusStatMoveBehavior.selfStatus()
      : battleEngineMethod = 's_self_status',
        _kind = _StatusStatKind.selfStatus;

  @override
  final String battleEngineMethod;
  final _StatusStatKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return switch (_kind) {
      _StatusStatKind.target => _resolveTargetStatusStat(
          context: context,
          prepared: prepared,
        ),
      _StatusStatKind.selfStat => _resolveSelfStat(
          context: context,
          prepared: prepared,
        ),
      _StatusStatKind.selfStatus => _resolveSelfStatus(
          context: context,
          prepared: prepared,
        ),
    };
  }

  BattleMoveBehaviorResolution _resolveTargetStatusStat({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: prepared.state,
      rng: prepared.rng,
      user: context.user,
      target: prepared.psdkTargets.single,
      move: _secondaryMove(context.move, effectChance: null),
      turn: context.turn,
    );
    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...secondary.events,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveSelfStat({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final damaged = _applyBasicDamage(
      context: context,
      prepared: prepared,
    );
    final withStatuses = _resolveSecondary(
      state: damaged.state,
      rng: damaged.rng,
      user: context.user,
      target: prepared.psdkTargets.single,
      move: _secondaryMove(
        context.move,
        stageMods: const <BattleStageMod>[],
      ),
      turn: context.turn,
    );
    final withStats = _resolveSecondary(
      state: withStatuses.state,
      rng: withStatuses.rng,
      user: context.user,
      target: context.user,
      move: _secondaryMove(
        context.move,
        statuses: const <PsdkBattleMoveStatus>[],
      ),
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: withStats.state,
      rng: withStats.rng,
      events: <PsdkBattleEvent>[
        ...damaged.events,
        ...withStatuses.events,
        ...withStats.events,
      ],
    );
  }

  BattleMoveBehaviorResolution _resolveSelfStatus({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final damaged = _applyBasicDamage(
      context: context,
      prepared: prepared,
    );
    final withStatuses = _resolveSecondary(
      state: damaged.state,
      rng: damaged.rng,
      user: context.user,
      target: context.user,
      move: _secondaryMove(
        context.move,
        stageMods: const <BattleStageMod>[],
      ),
      turn: context.turn,
    );
    final withStats = _resolveSecondary(
      state: withStatuses.state,
      rng: withStatuses.rng,
      user: context.user,
      target: prepared.psdkTargets.single,
      move: _secondaryMove(
        context.move,
        statuses: const <PsdkBattleMoveStatus>[],
      ),
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: withStats.state,
      rng: withStats.rng,
      events: <PsdkBattleEvent>[
        ...damaged.events,
        ...withStatuses.events,
        ...withStats.events,
      ],
    );
  }

  _DamageResolution _applyBasicDamage({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final events = <PsdkBattleEvent>[...prepared.events];
    if (context.move.category == PsdkBattleMoveCategory.status ||
        context.move.power <= 0) {
      return _DamageResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: events,
      );
    }

    final targetSlot = prepared.psdkTargets.single;
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: prepared.state.battlerAt(context.user),
        target: prepared.state.battlerAt(targetSlot),
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return _DamageResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    if (applied.event != null) {
      events.add(applied.event!);
    }
    return _DamageResolution(
      state: applied.state,
      rng: applied.rng,
      events: events,
    );
  }

  BattleMoveSecondaryEffectResult _resolveSecondary({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef user,
    required PsdkBattleSlotRef target,
    required BattleMoveDefinition move,
    required int turn,
  }) {
    return const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: rng,
      user: user,
      target: target,
      move: move,
      turn: turn,
    );
  }
}

BattleMoveDefinition _secondaryMove(
  BattleMoveDefinition move, {
  int? effectChance = _keepEffectChance,
  List<BattleStageMod>? stageMods,
  List<PsdkBattleMoveStatus>? statuses,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: move.type,
    category: move.category,
    power: move.power,
    accuracy: move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: move.priority,
    criticalRate: move.criticalRate,
    effectChance:
        effectChance == _keepEffectChance ? move.effectChance : effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: move.flags,
    stageMods: stageMods ?? move.stageMods,
    statuses: statuses ?? move.statuses,
  );
}

const int _keepEffectChance = -1;

final class _DamageResolution {
  const _DamageResolution({
    required this.state,
    required this.rng,
    required this.events,
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;
}
import '../../effect/battle_effect_scope.dart';
import '../../effect/move/baton_pass_effect.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_switch_handler.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

enum _SwitchEffectKind {
  batonPass,
}

final class SwitchEffectMoveBehavior implements BattleMoveBehavior {
  const SwitchEffectMoveBehavior.batonPass()
      : battleEngineMethod = 's_baton_pass',
        _kind = _SwitchEffectKind.batonPass;

  @override
  final String battleEngineMethod;
  final _SwitchEffectKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    return switch (_kind) {
      _SwitchEffectKind.batonPass => _resolveBatonPass(context, prepared),
    };
  }

  BattleMoveBehaviorResolution _resolveBatonPass(
    BattleMoveBehaviorContext context,
    PreparedBattleMove prepared,
  ) {
    var state = prepared.state.updateBattler(
      context.user,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(
          BatonPassEffect(scope: BattlerBattleEffectScope(context.user)),
        ),
      ),
    );
    final switching = const BattleSwitchHandler().markSwitching(
      context: BattleHandlerContext(
        state: state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
      ),
      target: context.user,
      switching: true,
    );
    state = switching.state;

    return BattleMoveBehaviorResolution(
      state: state,
      rng: switching.rng,
      events: prepared.events,
    );
  }
}
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/item/item_effect.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_terrain_change_handler.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

final class TerrainMoveBehavior implements BattleMoveBehavior {
  const TerrainMoveBehavior();

  @override
  String get battleEngineMethod => 's_terrain';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final terrain = _terrainForMove(context.move.dbSymbol);
    final user = prepared.state.battlerAt(context.user);
    final result = const BattleTerrainChangeHandler().changeTerrain(
      context: BattleHandlerContext(
        state: prepared.state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
      ),
      terrain: terrain,
      remainingTurns: _durationForMove(
        dbSymbol: context.move.dbSymbol,
        itemEffects: user.itemEffects,
      ),
    );

    return BattleMoveBehaviorResolution(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...result.events,
      ],
      successful: result.applied,
    );
  }
}

int _durationForMove({
  required String dbSymbol,
  required Iterable<BattleItemEffect> itemEffects,
}) {
  for (final effect in itemEffects) {
    final duration = effect.terrainDuration(dbSymbol);
    if (duration != null) {
      return duration;
    }
  }
  return 5;
}

PsdkBattleTerrainId _terrainForMove(String dbSymbol) {
  return switch (dbSymbol) {
    'electric_terrain' => PsdkBattleTerrainId.electricTerrain,
    'grassy_terrain' => PsdkBattleTerrainId.grassyTerrain,
    'misty_terrain' => PsdkBattleTerrainId.mistyTerrain,
    'psychic_terrain' => PsdkBattleTerrainId.psychicTerrain,
    _ => throw UnsupportedError(
        'Unsupported PSDK terrain move dbSymbol $dbSymbol.',
      ),
  };
}
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _TerrainPowerKind {
  terrainBoosting,
}

/// Ports PSDK move classes whose damage formula reads the active terrain.
///
/// This behavior deliberately handles only terrain power multipliers. Moves
/// that change type (`Terrain Pulse`), action order (`Grassy Glide`) or target
/// extra battlers (`Expanding Force`) need different engine seams and remain
/// missing in the manifest.
final class TerrainPowerMoveBehavior implements BattleMoveBehavior {
  const TerrainPowerMoveBehavior.terrainBoosting()
      : battleEngineMethod = 's_terrain_boosting',
        _kind = _TerrainPowerKind.terrainBoosting;

  @override
  final String battleEngineMethod;
  final _TerrainPowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = _resolvePower(
      movePower: context.move.power,
      dbSymbol: context.move.dbSymbol,
      field: prepared.state.field,
    );
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  int _resolvePower({
    required int movePower,
    required String dbSymbol,
    required PsdkBattleFieldState field,
  }) {
    return switch (_kind) {
      _TerrainPowerKind.terrainBoosting =>
        _terrainBoostingPower(movePower, dbSymbol, field),
    };
  }

  int _terrainBoostingPower(
    int movePower,
    String dbSymbol,
    PsdkBattleFieldState field,
  ) {
    final requiredTerrain = switch (dbSymbol) {
      'psyblade' => PsdkBattleTerrainId.electricTerrain,
      _ => null,
    };
    if (requiredTerrain == null || !field.isTerrainActive(requiredTerrain)) {
      return movePower;
    }
    return (movePower * 1.5).floor();
  }
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../battler/battle_transform_state.dart';
import '../../effect/battle_effect.dart';
import '../../effect/battle_effect_scope.dart';
import '../battle_move_behavior.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

/// Ports Pokemon SDK's `s_transform` move family.
///
/// PSDK copies the target's visible battle form, battle stats, ability, stat
/// stages and moveset, while keeping the user's HP and level. The copied moves
/// each receive 5 PP for the transformed battler.
final class TransformMoveBehavior
    implements BattleMoveBehavior, BattleMoveUserPreventionBehavior {
  const TransformMoveBehavior();

  @override
  String get battleEngineMethod => 's_transform';

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    final user = context.state.battlerAt(context.user);
    if (!user.transformState.isTransformed) {
      return null;
    }
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final target = prepared.state.battlerAt(targetSlot);
    if (!_canCopy(target)) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: targetSlot,
            moveId: context.move.id,
            reason: BattleMoveFailureReason.unusableByUser.jsonName,
          ),
        ],
        successful: false,
      );
    }

    final user = prepared.state.battlerAt(context.user);
    final transformed = _transformUser(
      user: user,
      target: target,
      userSlot: context.user,
    );

    return BattleMoveBehaviorResolution(
      state: prepared.state.replaceBattler(context.user, transformed),
      rng: prepared.rng,
      events: prepared.events,
    );
  }

  bool _canCopy(PsdkBattleCombatant target) {
    return !target.effects.contains('substitute');
  }

  PsdkBattleCombatant _transformUser({
    required PsdkBattleCombatant user,
    required PsdkBattleCombatant target,
    required PsdkBattleSlotRef userSlot,
  }) {
    return user.copyWith(
      speciesId: target.speciesId,
      displayName: target.displayName,
      types: target.types,
      stats: target.stats,
      abilityId: target.abilityId,
      statStages: target.statStages,
      currentWeightKg: target.currentWeightKg,
      moves: _transformMoves(target.moves),
      transformState: PsdkBattleTransformState(
        transformedFromSpeciesId:
            user.transformState.transformedFromSpeciesId ?? user.speciesId,
        illusionSpeciesId: user.transformState.illusionSpeciesId,
        illusionDisplayName: user.transformState.illusionDisplayName,
      ),
      effects: user.effects.addEffect(
        GenericBattleEffect(
          id: 'transform',
          scope: BattlerBattleEffectScope(userSlot),
        ),
      ),
    );
  }

  List<PsdkBattleMoveData> _transformMoves(List<PsdkBattleMoveData> moves) {
    if (moves.isEmpty) {
      return const <PsdkBattleMoveData>[];
    }
    return moves
        .map(
          (move) => move.copyWith(
            pp: 5,
            currentPp: 5,
          ),
        )
        .toList(growable: false);
  }
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _VariablePowerKind {
  brine,
  eruption,
  flail,
  wringOut,
  hardPress,
  electroBall,
  gyroBall,
  facade,
  targetStatusPowerBoost,
  hex,
  venoshock,
}

/// Ports PSDK move classes whose main override is dynamic base power.
///
/// The class mirrors Ruby `real_base_power`/`damages` overrides while leaving
/// target selection, PP, accuracy, Protect, immunity and secondary riders in
/// the shared move procedure. Families needing items, abilities, weights,
/// weather, terrain, damage history or custom stat sources stay out of this
/// lot so the registry does not overstate support.
final class VariablePowerMoveBehavior implements BattleMoveBehavior {
  const VariablePowerMoveBehavior.brine()
      : battleEngineMethod = 's_brine',
        _kind = _VariablePowerKind.brine;

  const VariablePowerMoveBehavior.eruption()
      : battleEngineMethod = 's_eruption',
        _kind = _VariablePowerKind.eruption;

  const VariablePowerMoveBehavior.flail()
      : battleEngineMethod = 's_flail',
        _kind = _VariablePowerKind.flail;

  const VariablePowerMoveBehavior.wringOut()
      : battleEngineMethod = 's_wring_out',
        _kind = _VariablePowerKind.wringOut;

  const VariablePowerMoveBehavior.hardPress()
      : battleEngineMethod = 's_hard_press',
        _kind = _VariablePowerKind.hardPress;

  const VariablePowerMoveBehavior.electroBall()
      : battleEngineMethod = 's_electro_ball',
        _kind = _VariablePowerKind.electroBall;

  const VariablePowerMoveBehavior.gyroBall()
      : battleEngineMethod = 's_gyro_ball',
        _kind = _VariablePowerKind.gyroBall;

  const VariablePowerMoveBehavior.facade()
      : battleEngineMethod = 's_facade',
        _kind = _VariablePowerKind.facade;

  const VariablePowerMoveBehavior.infernalParade()
      : battleEngineMethod = 's_infernal_parade',
        _kind = _VariablePowerKind.targetStatusPowerBoost;

  const VariablePowerMoveBehavior.bitterMalice()
      : battleEngineMethod = 's_bitter_malice',
        _kind = _VariablePowerKind.targetStatusPowerBoost;

  const VariablePowerMoveBehavior.hex()
      : battleEngineMethod = 's_hex',
        _kind = _VariablePowerKind.hex;

  const VariablePowerMoveBehavior.venoshock()
      : battleEngineMethod = 's_venoshock',
        _kind = _VariablePowerKind.venoshock;

  @override
  final String battleEngineMethod;
  final _VariablePowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = _resolvePower(
      movePower: context.move.power,
      user: user,
      target: target,
    );
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    final finalDamage = _resolveFinalDamage(
      damage: damageResult.damage,
      target: target,
    );
    if (finalDamage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: finalDamage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  int _resolvePower({
    required int movePower,
    required PsdkBattleCombatant user,
    required PsdkBattleCombatant target,
  }) {
    return switch (_kind) {
      _VariablePowerKind.brine => _brinePower(movePower, target),
      _VariablePowerKind.eruption => _hpRatePower(movePower, user),
      _VariablePowerKind.flail => _flailPower(user),
      _VariablePowerKind.wringOut => _hpRatePower(120, target),
      _VariablePowerKind.hardPress => _hpRatePower(100, target),
      _VariablePowerKind.electroBall => _electroBallPower(user, target),
      _VariablePowerKind.gyroBall => _gyroBallPower(user, target),
      _VariablePowerKind.facade => _facadePower(movePower, user),
      _VariablePowerKind.targetStatusPowerBoost =>
        target.majorStatus == null ? movePower : movePower * 2,
      // Hex and Venoshock double final damage in PSDK, not base power.
      _VariablePowerKind.hex || _VariablePowerKind.venoshock => movePower,
    };
  }

  int _resolveFinalDamage({
    required int damage,
    required PsdkBattleCombatant target,
  }) {
    return switch (_kind) {
      _VariablePowerKind.hex =>
        target.majorStatus == null ? damage : damage * 2,
      _VariablePowerKind.venoshock =>
        _isPoisonStatus(target.majorStatus) ? damage * 2 : damage,
      _ => damage,
    };
  }

  int _brinePower(int movePower, PsdkBattleCombatant target) {
    return target.currentHp <= target.maxHp ~/ 2 ? movePower * 2 : movePower;
  }

  int _hpRatePower(int maxPower, PsdkBattleCombatant battler) {
    final power = (maxPower * _hpRate(battler)).floor();
    return power < 1 ? 1 : power;
  }

  int _flailPower(PsdkBattleCombatant user) {
    final rate = _hpRate(user);
    if (rate > 0.70) {
      return 20;
    }
    if (rate > 0.35) {
      return 40;
    }
    if (rate > 0.20) {
      return 80;
    }
    if (rate > 0.10) {
      return 100;
    }
    if (rate > 0.04) {
      return 150;
    }
    return 200;
  }

  int _electroBallPower(
    PsdkBattleCombatant user,
    PsdkBattleCombatant target,
  ) {
    final ratio = _positiveSpeed(target) / _positiveSpeed(user);
    if (ratio < 0.25) {
      return 150;
    }
    if (ratio < 0.33) {
      return 120;
    }
    if (ratio < 0.5) {
      return 80;
    }
    if (ratio < 1) {
      return 60;
    }
    return 40;
  }

  int _gyroBallPower(
    PsdkBattleCombatant user,
    PsdkBattleCombatant target,
  ) {
    final rawPower =
        (25 * _positiveSpeed(target) / _positiveSpeed(user)).floor();
    return rawPower.clamp(1, 150).toInt();
  }

  int _facadePower(int movePower, PsdkBattleCombatant user) {
    return _isFacadeBoostingStatus(user.majorStatus)
        ? movePower * 2
        : movePower;
  }

  double _hpRate(PsdkBattleCombatant battler) {
    if (battler.maxHp <= 0) {
      return 0;
    }
    return battler.currentHp.clamp(0, battler.maxHp) / battler.maxHp;
  }

  int _positiveSpeed(PsdkBattleCombatant battler) {
    final speed = battler.stats.speed;
    if (battler.majorStatus != PsdkBattleMajorStatus.paralysis ||
        battler.abilityId == 'quick_feet') {
      return speed < 1 ? 1 : speed;
    }
    final paralyzedSpeed = (speed * 0.25).floor();
    return paralyzedSpeed < 1 ? 1 : paralyzedSpeed;
  }

  bool _isFacadeBoostingStatus(PsdkBattleMajorStatus? status) {
    return switch (status) {
      PsdkBattleMajorStatus.burn ||
      PsdkBattleMajorStatus.paralysis ||
      PsdkBattleMajorStatus.poison ||
      PsdkBattleMajorStatus.toxic =>
        true,
      _ => false,
    };
  }

  bool _isPoisonStatus(PsdkBattleMajorStatus? status) {
    return switch (status) {
      PsdkBattleMajorStatus.poison || PsdkBattleMajorStatus.toxic => true,
      _ => false,
    };
  }
}
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/item/item_effect.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_weather_change_handler.dart';
import '../battle_move_behavior.dart';
import 'battle_move_behavior_support.dart';

final class WeatherMoveBehavior implements BattleMoveBehavior {
  const WeatherMoveBehavior();

  @override
  String get battleEngineMethod => 's_weather';

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final weather = _weatherForMove(context.move.dbSymbol);
    final duration = _durationForContext(context);
    final result = const BattleWeatherChangeHandler().changeWeather(
      context: BattleHandlerContext(
        state: prepared.state,
        rng: prepared.rng,
        turn: context.turn,
        user: context.user,
      ),
      weather: weather,
      remainingTurns: duration,
    );

    return BattleMoveBehaviorResolution(
      state: result.state,
      rng: result.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...result.events,
      ],
      successful: result.applied,
    );
  }
}

PsdkBattleWeatherId _weatherForMove(String dbSymbol) {
  return switch (dbSymbol) {
    'rain_dance' => PsdkBattleWeatherId.rain,
    'sunny_day' => PsdkBattleWeatherId.sunny,
    'sandstorm' => PsdkBattleWeatherId.sandstorm,
    'hail' => PsdkBattleWeatherId.hail,
    'snowscape' => PsdkBattleWeatherId.snow,
    _ => throw UnsupportedError(
        'Unsupported PSDK weather move dbSymbol $dbSymbol.',
      ),
  };
}

int _durationFromItems({
  required String dbSymbol,
  required Iterable<BattleItemEffect> itemEffects,
}) {
  for (final effect in itemEffects) {
    final duration = effect.weatherDuration(dbSymbol);
    if (duration != null) {
      return duration;
    }
  }
  return 5;
}

int _durationForContext(BattleMoveBehaviorContext context) {
  final user = context.state.battlerAt(context.user);
  return _durationFromItems(
    dbSymbol: context.move.dbSymbol,
    itemEffects: user.itemEffects,
  );
}
import '../../../psdk/domain/psdk_battle_field.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_data.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

final class WeatherPowerMoveBehavior implements BattleMoveBehavior {
  const WeatherPowerMoveBehavior.weatherBall()
      : battleEngineMethod = 's_weather_ball';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final effectiveMove = _weatherBallMove(context.state, context.move);
    final prepared = prepareBattleMove(
      BattleMoveBehaviorContext(
        state: context.state,
        rng: context.rng,
        turn: context.turn,
        user: context.user,
        target: context.target,
        move: effectiveMove,
        isLastActionOfTurn: context.isLastActionOfTurn,
        moveProcedureHooks: context.moveProcedureHooks,
      ),
    );
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: effectiveMove,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: effectiveMove,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }
}

BattleMoveDefinition _weatherBallMove(
  PsdkBattleState state,
  BattleMoveDefinition move,
) {
  final weather = state.field.weather?.id;
  return _copyMove(
    move,
    type: state.weatherEffectsSuppressed
        ? move.type
        : _weatherBallType(weather, move.type),
    power: weather == null ? move.power : 100,
  );
}

String _weatherBallType(PsdkBattleWeatherId? weather, String fallback) {
  return switch (weather) {
    PsdkBattleWeatherId.rain || PsdkBattleWeatherId.hardrain => 'water',
    PsdkBattleWeatherId.sunny || PsdkBattleWeatherId.hardsun => 'fire',
    PsdkBattleWeatherId.hail || PsdkBattleWeatherId.snow => 'ice',
    PsdkBattleWeatherId.sandstorm => 'rock',
    _ => fallback,
  };
}

BattleMoveDefinition _copyMove(
  BattleMoveDefinition move, {
  required String type,
  required int power,
}) {
  return BattleMoveDefinition(
    id: move.id,
    dbSymbol: move.dbSymbol,
    name: move.name,
    type: type,
    category: move.category,
    power: power,
    accuracy: move.accuracy,
    pp: move.pp,
    currentPp: move.currentPp,
    priority: move.priority,
    criticalRate: move.criticalRate,
    effectChance: move.effectChance,
    battleEngineMethod: move.battleEngineMethod,
    target: move.target,
    flags: move.flags,
    stageMods: move.stageMods,
    statuses: move.statuses,
  );
}
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _WeightPowerKind {
  lowKick,
  heavySlam,
}

/// Ports PSDK moves whose base power is determined by battler weight.
///
/// The formulas intentionally consume the combatant's battle snapshot rather
/// than reaching into species data. That keeps the battle engine pure and lets
/// runtime/editor import layers decide later how base/current weights are
/// hydrated. PSDK's Minimize bonus/bypass and ability fallback around modified
/// weights remain outside this slice, so these methods stay `partial`.
final class WeightPowerMoveBehavior implements BattleMoveBehavior {
  const WeightPowerMoveBehavior.lowKick()
      : battleEngineMethod = 's_low_kick',
        _kind = _WeightPowerKind.lowKick;

  const WeightPowerMoveBehavior.heavySlam()
      : battleEngineMethod = 's_heavy_slam',
        _kind = _WeightPowerKind.heavySlam;

  @override
  final String battleEngineMethod;
  final _WeightPowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = switch (_kind) {
      _WeightPowerKind.lowKick => _lowKickPower(target),
      _WeightPowerKind.heavySlam => _heavySlamPower(user, target),
    };

    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  int _lowKickPower(PsdkBattleCombatant target) {
    final targetWeight = target.currentWeightKg;
    const maximumWeights = <double>[10, 25, 50, 100, 200];
    final index = maximumWeights.indexWhere((weight) => targetWeight < weight);
    return 20 + 20 * (index == -1 ? maximumWeights.length : index);
  }

  int _heavySlamPower(
    PsdkBattleCombatant user,
    PsdkBattleCombatant target,
  ) {
    final weightPercent = target.currentWeightKg / user.currentWeightKg;
    const minimumWeightPercent = <double>[0.5, 0.3334, 0.25, 0.20];
    final index =
        minimumWeightPercent.indexWhere((weight) => weightPercent > weight);
    return 40 + 20 * (index == -1 ? minimumWeightPercent.length : index);
  }
}
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

const _dittoStats = BattleStatsSnapshot(
  attack: 48,
  defense: 48,
  specialAttack: 48,
  specialDefense: 48,
  speed: 48,
);

const _targetStats = BattleStatsSnapshot(
  attack: 84,
  defense: 78,
  specialAttack: 109,
  specialDefense: 85,
  speed: 100,
);

void main() {
  group('BattleSession Transform', () {
    test('copies target battle form, stats, ability, stages and moves', () {
      final session = createBattleSession(
        BattleSetup(
          playerPokemon: BattleCombatantData(
            speciesId: 'ditto',
            level: 50,
            currentHp: 72,
            maxHp: 100,
            stats: _dittoStats,
            typing: const BattleTypingSnapshot(primaryType: 'normal'),
            abilityId: 'limber',
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'transform',
                name: 'Transform',
                power: 0,
                type: 'normal',
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.opponent,
                accuracy: BattleMoveAccuracy.alwaysHits(),
                pp: 10,
                copiesTargetOnHit: true,
              ),
            ],
          ),
          enemyPokemon: BattleCombatantData(
            speciesId: 'charizard',
            level: 50,
            maxHp: 150,
            stats: _targetStats,
            typing: const BattleTypingSnapshot(
              primaryType: 'fire',
              secondaryType: 'flying',
            ),
            abilityId: 'blaze',
            moves: const <BattleMoveData>[
              BattleMoveData(
                id: 'roar',
                name: 'Roar',
                power: 0,
                type: 'normal',
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.opponent,
                pp: 20,
              ),
              BattleMoveData(
                id: 'splash',
                name: 'Splash',
                power: 0,
                type: 'normal',
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.opponent,
                pp: 40,
              ),
            ],
          ),
          isTrainerBattle: false,
          trainerId: null,
        ),
      );

      final afterTurn = session.applyChoice(const PlayerBattleChoiceFight(0));
      final transformed = afterTurn.state.player;

      expect(transformed.speciesId, equals('charizard'));
      expect(transformed.currentHp, equals(72));
      expect(transformed.maxHp, equals(100));
      expect(transformed.stats, equals(_targetStats));
      expect(transformed.typing?.primaryType, equals('fire'));
      expect(transformed.typing?.secondaryType, equals('flying'));
      expect(transformed.abilityId, equals('blaze'));
      expect(transformed.moves.map((move) => move.id), <String>[
        'roar',
        'splash',
      ]);
      expect(transformed.moves.map((move) => move.pp), <int>[5, 5]);
      expect(transformed.moves.map((move) => move.currentPp), <int>[5, 5]);
      final transformExecution = afterTurn.state.currentTurn!.executions
          .singleWhere((execution) => execution.move.id == 'transform');
      expect(transformExecution.damage, 0);
    });
  });
}
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('LegacyPathSurfaceView', () {
    test('adapts a simple water ProjectPathPreset without changing values', () {
      // This is the smallest useful bridge from the current path preset model
      // toward a future Surface Engine view. The adapter must expose legacy
      // water as a surface-like read-only object without creating new persisted
      // Surface JSON.
      final sourceFrame = visualFrame(0, durationMs: 100);
      final preset = pathPreset(
        id: 'route-water',
        name: 'Route Water',
        surfaceKind: PathSurfaceKind.water,
        tilesetId: 'outdoor',
        categoryId: 'liquids',
        sortOrder: 12,
        variants: [
          mapping(TerrainPathVariant.isolated, [sourceFrame]),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(view.id, 'route-water');
      expect(view.name, 'Route Water');
      expect(view.surfaceKind, PathSurfaceKind.water);
      expect(view.tilesetId, 'outdoor');
      expect(view.categoryId, 'liquids');
      expect(view.sortOrder, 12);
      expect(view.hasVariants, isTrue);
      expect(view.hasAnimatedVariants, isFalse);
      expect(view.variants, hasLength(1));
      expect(view.variants.single.variant, TerrainPathVariant.isolated);
      expect(view.variants.single.frames.single, same(sourceFrame));
    });

    test('adapts a tallGrass preset as a legacy surface kind', () {
      // Tall grass will need gameplay semantics that differ from water, but the
      // existing path preset enum already identifies it. This adapter should
      // expose that fact without pretending tall grass and water behave alike.
      final preset = pathPreset(
        id: 'field-grass',
        name: 'Field Grass',
        surfaceKind: PathSurfaceKind.tallGrass,
        variants: [
          mapping(TerrainPathVariant.isolated, [visualFrame(1)]),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(view.surfaceKind, PathSurfaceKind.tallGrass);
      expect(view.id, 'field-grass');
      expect(view.tilesetId, '');
    });

    test('preserves variant order exactly as authored by the preset', () {
      // The source model is a list, not a canonical map. The adapter must keep
      // authoring order stable so future migration tools can compare legacy
      // presets to Surface definitions without hidden sorting.
      final preset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.cross, [visualFrame(0)]),
          mapping(TerrainPathVariant.isolated, [visualFrame(1)]),
          mapping(TerrainPathVariant.cornerNE, [visualFrame(2)]),
          mapping(TerrainPathVariant.horizontal, [visualFrame(3)]),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(view.variants.map((variant) => variant.variant), [
        TerrainPathVariant.cross,
        TerrainPathVariant.isolated,
        TerrainPathVariant.cornerNE,
        TerrainPathVariant.horizontal,
      ]);
    });

    test('preserves frame order and frame durations exactly', () {
      // Animated water-like atlases depend on frame order. This bridge should
      // not normalize durations or resolve time; Lot 2 owns timeline behavior.
      final frames = [
        visualFrame(0, durationMs: 60),
        visualFrame(1, durationMs: 120),
        visualFrame(2, durationMs: 240),
      ];
      final preset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.horizontal, frames),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(view.variants.single.frames, frames);
      expect(view.variants.single.frames.map((frame) => frame.durationMs), [
        60,
        120,
        240,
      ]);
      expect(view.variants.single.isAnimated, isTrue);
    });

    test('preserves per-frame tilesetId overrides', () {
      // Lot 3 characterized that missing frame overrides are represented by an
      // empty string. When an override is present, the view must keep it exactly
      // for future multi-atlas surface comparisons.
      final overrideFrame = visualFrame(
        7,
        tilesetId: 'animated-water-atlas',
        durationMs: 90,
      );
      final preset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.cross, [overrideFrame]),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);
      final frame = view.variants.single.frames.single;

      expect(frame, same(overrideFrame));
      expect(frame.tilesetId, 'animated-water-atlas');
      expect(frame.source, const TilesetSourceRect(x: 7, y: 0));
      expect(frame.durationMs, 90);
    });

    test('framesForVariant returns first matching mapping or an empty list',
        () {
      // Duplicate mappings are legal in the legacy list shape. V0 deliberately
      // does not merge or de-duplicate them; it returns the first match so the
      // behavior is simple, visible, and migration-safe.
      final firstHorizontal = [visualFrame(1, durationMs: 80)];
      final secondHorizontal = [visualFrame(2, durationMs: 160)];
      final cross = [visualFrame(3, durationMs: 200)];
      final preset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.horizontal, firstHorizontal),
          mapping(TerrainPathVariant.cross, cross),
          mapping(TerrainPathVariant.horizontal, secondHorizontal),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(
        view.framesForVariant(TerrainPathVariant.horizontal),
        firstHorizontal,
      );
      expect(view.framesForVariant(TerrainPathVariant.cross), cross);
      expect(view.framesForVariant(TerrainPathVariant.cornerNE), isEmpty);
    });

    test('exposes only unmodifiable variant and frame lists', () {
      // The adapter is read-only. Callers may inspect legacy data, but they
      // should not be able to mutate the adapter and accidentally confuse later
      // migration/runtime code.
      final preset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.isolated, [visualFrame(0)]),
        ],
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(
        () => view.variants.add(
          LegacyPathSurfaceVariantView(
            variant: TerrainPathVariant.cross,
            frames: const [],
          ),
        ),
        throwsUnsupportedError,
      );
      expect(
        () => view.variants.first.frames.add(visualFrame(99)),
        throwsUnsupportedError,
      );
      expect(
        () => view
            .framesForVariant(TerrainPathVariant.cornerNE)
            .add(visualFrame(100)),
        throwsUnsupportedError,
      );
    });

    test('does not mutate the source ProjectPathPreset', () {
      // The source preset remains the legacy source of truth. Creating a view
      // must not alter its variants or frames.
      final sourceFrames = [
        visualFrame(0, durationMs: 100),
        visualFrame(1, durationMs: 120),
      ];
      final sourceVariants = [
        mapping(TerrainPathVariant.horizontal, sourceFrames),
      ];
      final preset = pathPreset(variants: sourceVariants);
      final beforeVariants = List<PathPresetVariantMapping>.from(
        preset.variants,
      );
      final beforeFrames = List<TilesetVisualFrame>.from(
        preset.variants.single.frames,
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(preset.variants, beforeVariants);
      expect(preset.variants.single.frames, beforeFrames);
      expect(view.variants.single.frames, beforeFrames);
    });

    test('accepts a preset without variants', () {
      // Empty legacy path presets exist as authoring placeholders. The Surface
      // bridge should accept them and return empty, unmodifiable lookups instead
      // of inventing default autotile mappings.
      const preset = ProjectPathPreset(
        id: 'empty-path',
        name: 'Empty Path',
        surfaceKind: PathSurfaceKind.path,
      );

      final view = createLegacyPathSurfaceView(preset);

      expect(view.variants, isEmpty);
      expect(view.hasVariants, isFalse);
      expect(view.hasAnimatedVariants, isFalse);
      expect(view.framesForVariant(TerrainPathVariant.cross), isEmpty);
      expect(
        () => view.framesForVariant(TerrainPathVariant.cross).add(
              visualFrame(0),
            ),
        throwsUnsupportedError,
      );
    });

    test('hasAnimatedVariants is true when any variant has multiple frames',
        () {
      // Animation here is structural only: two frames means animated. Duration
      // validation and time resolution remain outside this adapter.
      final staticPreset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.isolated, [visualFrame(0)]),
          mapping(TerrainPathVariant.cross, [visualFrame(1)]),
        ],
      );
      final animatedPreset = pathPreset(
        variants: [
          mapping(TerrainPathVariant.isolated, [visualFrame(0)]),
          mapping(TerrainPathVariant.cross, [
            visualFrame(1, durationMs: 90),
            visualFrame(2, durationMs: 110),
          ]),
        ],
      );

      expect(createLegacyPathSurfaceView(staticPreset).hasAnimatedVariants,
          isFalse);
      expect(createLegacyPathSurfaceView(animatedPreset).hasAnimatedVariants,
          isTrue);
    });

    test('LegacyPathSurfaceVariantView reports frame and animation state', () {
      // Variant views are intentionally tiny wrappers around a legacy
      // TerrainPathVariant and its frames. They do not infer fallback visuals.
      final empty = LegacyPathSurfaceVariantView(
        variant: TerrainPathVariant.cross,
        frames: const [],
      );
      final single = LegacyPathSurfaceVariantView(
        variant: TerrainPathVariant.cross,
        frames: [visualFrame(0)],
      );
      final animated = LegacyPathSurfaceVariantView(
        variant: TerrainPathVariant.cross,
        frames: [visualFrame(0), visualFrame(1)],
      );

      expect(empty.hasFrames, isFalse);
      expect(empty.isAnimated, isFalse);
      expect(single.hasFrames, isTrue);
      expect(single.isAnimated, isFalse);
      expect(animated.hasFrames, isTrue);
      expect(animated.isAnimated, isTrue);
    });
  });
}

ProjectPathPreset pathPreset({
  String id = 'legacy-path',
  String name = 'Legacy Path',
  PathSurfaceKind surfaceKind = PathSurfaceKind.path,
  String tilesetId = '',
  String? categoryId,
  int sortOrder = 0,
  List<PathPresetVariantMapping> variants = const [],
}) {
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    variants: variants,
  );
}

PathPresetVariantMapping mapping(
  TerrainPathVariant variant,
  List<TilesetVisualFrame> frames,
) {
  return PathPresetVariantMapping(
    variant: variant,
    frames: frames,
  );
}

TilesetVisualFrame visualFrame(
  int x, {
  String tilesetId = '',
  int? durationMs,
}) {
  return TilesetVisualFrame(
    tilesetId: tilesetId,
    source: TilesetSourceRect(x: x, y: 0),
    durationMs: durationMs,
  );
}
import '../models/map_data.dart';
import '../models/project_manifest.dart';
import 'legacy_project_surface_catalog_view.dart';
import 'legacy_surface_catalog_diagnostics.dart';
import 'legacy_surface_usage_diagnostics.dart';
import 'legacy_surface_usage_view.dart';

/// Read-only audit snapshot for legacy surface migration planning.
///
/// This report is a pure assembly layer over the transitional Surface Engine
/// building blocks introduced before Lot 10:
///
/// - the declared legacy surface catalog from [ProjectManifest];
/// - the actual terrain/path usages discovered in [MapData] layers;
/// - catalog diagnostics for declared preset structure;
/// - usage diagnostics for how map layers relate to declared presets.
///
/// It is deliberately not persisted, not JSON, not Freezed, and not a unified
/// Surface model. Terrain and path remain separated inside the catalog and
/// usage views so later migration lots can decide explicitly how to model them.
final class LegacySurfaceAuditReport {
  LegacySurfaceAuditReport({
    required this.catalog,
    required this.usage,
    required List<LegacySurfaceCatalogDiagnostic> catalogDiagnostics,
    required List<LegacySurfaceUsageDiagnostic> usageDiagnostics,
    required this.summary,
  })  : catalogDiagnostics = List.unmodifiable(catalogDiagnostics),
        usageDiagnostics = List.unmodifiable(usageDiagnostics);

  /// Declared legacy terrain/path surfaces from the manifest.
  final LegacyProjectSurfaceCatalogView catalog;

  /// Actual legacy terrain/path usage discovered across analyzed maps.
  final LegacyProjectSurfaceUsageView usage;

  /// Diagnostics about declared legacy surface preset structure.
  ///
  /// This list is unmodifiable. The report does not filter, repair, or
  /// downgrade diagnostics emitted by [diagnoseLegacySurfaceCatalog].
  final List<LegacySurfaceCatalogDiagnostic> catalogDiagnostics;

  /// Diagnostics about how actual map usage relates to declared presets.
  ///
  /// This list is unmodifiable. The report preserves the exact diagnostics
  /// emitted by [diagnoseLegacySurfaceUsage].
  final List<LegacySurfaceUsageDiagnostic> usageDiagnostics;

  /// Aggregate counts for quick reporting and future UI summaries.
  final LegacySurfaceAuditSummary summary;

  /// Whether any catalog or usage diagnostic exists.
  bool get hasDiagnostics =>
      catalogDiagnostics.isNotEmpty || usageDiagnostics.isNotEmpty;

  /// Whether any catalog or usage diagnostic has warning severity.
  ///
  /// Catalog diagnostics and usage diagnostics intentionally have separate
  /// severity enums. This getter checks each enum in its own family rather
  /// than trying to collapse them into a shared type.
  bool get hasWarnings {
    return catalogDiagnostics.any(
          (diagnostic) =>
              diagnostic.severity ==
              LegacySurfaceCatalogDiagnosticSeverity.warning,
        ) ||
        usageDiagnostics.any(
          (diagnostic) =>
              diagnostic.severity ==
              LegacySurfaceUsageDiagnosticSeverity.warning,
        );
  }

  /// Whether analyzed maps contain any terrain, path, or missing path usage.
  bool get hasUsage =>
      usage.hasTerrainUsage ||
      usage.hasPathUsage ||
      usage.hasMissingPathSurfaceUsage;
}

/// Compact counts for a [LegacySurfaceAuditReport].
///
/// The summary is intentionally factual and mechanical. It does not score
/// migration readiness or hide diagnostics; it only counts the already exposed
/// catalog, usage, and warning data.
final class LegacySurfaceAuditSummary {
  const LegacySurfaceAuditSummary({
    required this.terrainSurfaceCount,
    required this.pathSurfaceCount,
    required this.terrainUsageCount,
    required this.pathUsageCount,
    required this.missingPathUsageCount,
    required this.catalogDiagnosticCount,
    required this.catalogWarningCount,
    required this.usageDiagnosticCount,
    required this.usageWarningCount,
  });

  /// Number of declared terrain surface candidates.
  final int terrainSurfaceCount;

  /// Number of declared path surface candidates.
  final int pathSurfaceCount;

  /// Number of discovered terrain usage entries.
  final int terrainUsageCount;

  /// Number of discovered path usages that resolved to a declared preset.
  final int pathUsageCount;

  /// Number of active path usages whose preset id did not resolve.
  final int missingPathUsageCount;

  /// Number of catalog diagnostics in the report.
  final int catalogDiagnosticCount;

  /// Number of catalog diagnostics with warning severity.
  final int catalogWarningCount;

  /// Number of usage diagnostics in the report.
  final int usageDiagnosticCount;

  /// Number of usage diagnostics with warning severity.
  final int usageWarningCount;
}

/// Creates a complete read-only legacy surface audit report.
///
/// This function assembles existing pure operations. It does not mutate the
/// manifest or maps, does not repair legacy data, does not filter diagnostics,
/// and does not create any persistent Surface schema. The returned report is a
/// snapshot suitable for future migration tooling, editor panels, or generated
/// audit reports.
LegacySurfaceAuditReport createLegacySurfaceAuditReport({
  required ProjectManifest manifest,
  required Iterable<MapData> maps,
}) {
  final catalog = createLegacyProjectSurfaceCatalogView(manifest);
  final usage = createLegacyProjectSurfaceUsageView(
    catalog: catalog,
    maps: maps,
  );
  final catalogDiagnostics = diagnoseLegacySurfaceCatalog(catalog);
  final usageDiagnostics = diagnoseLegacySurfaceUsage(
    catalog: catalog,
    usage: usage,
  );

  return LegacySurfaceAuditReport(
    catalog: catalog,
    usage: usage,
    catalogDiagnostics: catalogDiagnostics,
    usageDiagnostics: usageDiagnostics,
    summary: LegacySurfaceAuditSummary(
      terrainSurfaceCount: catalog.terrainSurfaces.length,
      pathSurfaceCount: catalog.pathSurfaces.length,
      terrainUsageCount: usage.terrainUsages.length,
      pathUsageCount: usage.pathUsages.length,
      missingPathUsageCount: usage.missingPathSurfaceUsages.length,
      catalogDiagnosticCount: catalogDiagnostics.length,
      catalogWarningCount: _catalogWarningCount(catalogDiagnostics),
      usageDiagnosticCount: usageDiagnostics.length,
      usageWarningCount: _usageWarningCount(usageDiagnostics),
    ),
  );
}

int _catalogWarningCount(
  List<LegacySurfaceCatalogDiagnostic> diagnostics,
) {
  return diagnostics
      .where(
        (diagnostic) =>
            diagnostic.severity ==
            LegacySurfaceCatalogDiagnosticSeverity.warning,
      )
      .length;
}

int _usageWarningCount(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
) {
  return diagnostics
      .where(
        (diagnostic) =>
            diagnostic.severity == LegacySurfaceUsageDiagnosticSeverity.warning,
      )
      .length;
}
import '../models/enums.dart';
import 'legacy_path_surface_view.dart';
import 'legacy_project_surface_catalog_view.dart';
import 'legacy_surface_usage_view.dart';

/// Diagnostic severity for legacy surface usage audit output.
///
/// This mirrors the catalog diagnostics split while keeping usage diagnostics
/// as a separate, non-persistent vocabulary:
///
/// - [warning] means the current map usage can block, break, or make a future
///   Surface migration ambiguous;
/// - [info] means the fact is useful to migration reports but is not itself
///   broken legacy data.
enum LegacySurfaceUsageDiagnosticSeverity {
  info,
  warning,
}

/// Legacy usage diagnostic family.
///
/// Terrain and path remain separate by design. Lot 9 deliberately does not add
/// a shared Surface union or collapse both families into one model.
enum LegacySurfaceUsageDiagnosticFamily {
  terrain,
  path,
}

/// Stable diagnostic codes produced by [diagnoseLegacySurfaceUsage].
///
/// These codes describe usage facts across the legacy catalog and the maps
/// analyzed by `LegacyProjectSurfaceUsageView`. They are not serialized, not
/// Freezed, and not part of the project manifest schema.
enum LegacySurfaceUsageDiagnosticCode {
  usedTerrainTypeWithoutDeclaredSurface,
  declaredTerrainSurfaceWithoutMatchingUsage,
  usedTerrainTypeWithMultipleDeclaredSurfaces,
  missingPathSurfaceUsage,
  emptyPathPresetIdUsage,
  declaredPathSurfaceWithoutUsage,
  usedPathPresetWithMultipleDeclaredSurfaces,
  usedPathSurfaceWithoutVariants,
  usedTerrainSurfaceCandidateWithoutVariants,
}

/// One read-only diagnostic emitted by a legacy surface usage audit.
///
/// A diagnostic can point at declared surface data, actual map/layer usage, or
/// both. Keeping all fields nullable avoids inventing fake ids for cases where
/// the legacy model simply does not carry a stronger reference, such as terrain
/// cells that only store [TerrainType].
final class LegacySurfaceUsageDiagnostic {
  const LegacySurfaceUsageDiagnostic({
    required this.severity,
    required this.code,
    required this.family,
    required this.message,
    this.terrainType,
    this.pathPresetId,
    this.surfaceId,
    this.surfaceName,
    this.mapId,
    this.mapName,
    this.layerIndex,
    this.layerId,
    this.layerName,
    this.detail,
  });

  /// Whether this is a migration warning or informational usage fact.
  final LegacySurfaceUsageDiagnosticSeverity severity;

  /// Stable machine-readable diagnostic code.
  final LegacySurfaceUsageDiagnosticCode code;

  /// Legacy family this diagnostic belongs to.
  final LegacySurfaceUsageDiagnosticFamily family;

  /// Short human-readable summary.
  final String message;

  /// Terrain type when the diagnostic is tied to terrain usage.
  final TerrainType? terrainType;

  /// Path preset id when the diagnostic is tied to path usage.
  final String? pathPresetId;

  /// Declared legacy surface id when one is known.
  final String? surfaceId;

  /// Declared legacy surface display name when one is known.
  final String? surfaceName;

  /// Map id from an actual usage, when applicable.
  final String? mapId;

  /// Map name from an actual usage, when applicable.
  final String? mapName;

  /// Layer index from an actual usage, when applicable.
  final int? layerIndex;

  /// Layer id from an actual usage, when applicable.
  final String? layerId;

  /// Layer name from an actual usage, when applicable.
  final String? layerName;

  /// Extra deterministic detail for reports and tests.
  final String? detail;
}

/// Diagnoses migration-relevant facts in [catalog] and [usage].
///
/// This function is pure and read-only. It does not validate the source
/// manifest, does not correct missing path presets, does not de-duplicate ids,
/// and does not create a unified Surface model. It only reports how declared
/// legacy surface candidates relate to actual map usage.
List<LegacySurfaceUsageDiagnostic> diagnoseLegacySurfaceUsage({
  required LegacyProjectSurfaceCatalogView catalog,
  required LegacyProjectSurfaceUsageView usage,
}) {
  final diagnostics = <LegacySurfaceUsageDiagnostic>[];

  _addTerrainUsageDiagnostics(diagnostics, catalog, usage);
  _addDeclaredTerrainWithoutUsageDiagnostics(diagnostics, catalog, usage);
  _addMissingPathUsageDiagnostics(diagnostics, usage);
  _addUsedPathDuplicateCandidateDiagnostics(diagnostics, catalog, usage);
  _addUsedPathWithoutVariantsDiagnostics(diagnostics, usage);
  _addDeclaredPathWithoutUsageDiagnostics(diagnostics, catalog, usage);

  return List.unmodifiable(diagnostics);
}

void _addTerrainUsageDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceCatalogView catalog,
  LegacyProjectSurfaceUsageView usage,
) {
  for (final terrainType in _terrainTypesInUsageOrder(usage)) {
    final firstUsage = _firstTerrainUsage(usage, terrainType);
    if (firstUsage == null) {
      continue;
    }

    final candidates = catalog.terrainSurfacesByType(terrainType);
    if (candidates.isEmpty) {
      diagnostics.add(
        LegacySurfaceUsageDiagnostic(
          severity: LegacySurfaceUsageDiagnosticSeverity.warning,
          code: LegacySurfaceUsageDiagnosticCode
              .usedTerrainTypeWithoutDeclaredSurface,
          family: LegacySurfaceUsageDiagnosticFamily.terrain,
          message: 'Used terrain type has no declared terrain surface.',
          terrainType: terrainType,
          mapId: firstUsage.mapId,
          mapName: firstUsage.mapName,
          layerIndex: firstUsage.layerIndex,
          layerId: firstUsage.layerId,
          layerName: firstUsage.layerName,
          detail:
              'TerrainType ${terrainType.name} is used but no declared terrain surface matches it.',
        ),
      );
    } else {
      if (candidates.length > 1) {
        diagnostics.add(
          LegacySurfaceUsageDiagnostic(
            severity: LegacySurfaceUsageDiagnosticSeverity.warning,
            code: LegacySurfaceUsageDiagnosticCode
                .usedTerrainTypeWithMultipleDeclaredSurfaces,
            family: LegacySurfaceUsageDiagnosticFamily.terrain,
            message: 'Used terrain type has multiple declared candidates.',
            terrainType: terrainType,
            mapId: firstUsage.mapId,
            mapName: firstUsage.mapName,
            layerIndex: firstUsage.layerIndex,
            layerId: firstUsage.layerId,
            layerName: firstUsage.layerName,
            detail:
                '${candidates.length} declared terrain surfaces match TerrainType ${terrainType.name}.',
          ),
        );
      }

      for (final candidate in candidates) {
        if (candidate.hasVariants) {
          continue;
        }
        diagnostics.add(
          LegacySurfaceUsageDiagnostic(
            severity: LegacySurfaceUsageDiagnosticSeverity.warning,
            code: LegacySurfaceUsageDiagnosticCode
                .usedTerrainSurfaceCandidateWithoutVariants,
            family: LegacySurfaceUsageDiagnosticFamily.terrain,
            message: 'Used terrain surface candidate has no variants.',
            terrainType: terrainType,
            surfaceId: candidate.id,
            surfaceName: candidate.name,
            mapId: firstUsage.mapId,
            mapName: firstUsage.mapName,
            layerIndex: firstUsage.layerIndex,
            layerId: firstUsage.layerId,
            layerName: firstUsage.layerName,
            detail:
                'Terrain surface ${candidate.id} matches a used TerrainType but has no variants.',
          ),
        );
      }
    }
  }
}

void _addDeclaredTerrainWithoutUsageDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceCatalogView catalog,
  LegacyProjectSurfaceUsageView usage,
) {
  final usedTypes = _terrainTypesInUsageOrder(usage).toSet();
  for (final surface in catalog.terrainSurfaces) {
    if (usedTypes.contains(surface.terrainType)) {
      continue;
    }
    diagnostics.add(
      LegacySurfaceUsageDiagnostic(
        severity: LegacySurfaceUsageDiagnosticSeverity.info,
        code: LegacySurfaceUsageDiagnosticCode
            .declaredTerrainSurfaceWithoutMatchingUsage,
        family: LegacySurfaceUsageDiagnosticFamily.terrain,
        message: 'Declared terrain surface has no matching terrain usage.',
        terrainType: surface.terrainType,
        surfaceId: surface.id,
        surfaceName: surface.name,
        detail:
            'No analyzed TerrainLayer usage contains TerrainType ${surface.terrainType.name}.',
      ),
    );
  }
}

void _addMissingPathUsageDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceUsageView usage,
) {
  for (final missingUsage in usage.missingPathSurfaceUsages) {
    final isEmptyPresetId = missingUsage.presetId.isEmpty;
    diagnostics.add(
      LegacySurfaceUsageDiagnostic(
        severity: LegacySurfaceUsageDiagnosticSeverity.warning,
        code: isEmptyPresetId
            ? LegacySurfaceUsageDiagnosticCode.emptyPathPresetIdUsage
            : LegacySurfaceUsageDiagnosticCode.missingPathSurfaceUsage,
        family: LegacySurfaceUsageDiagnosticFamily.path,
        message: isEmptyPresetId
            ? 'Active path layer has an empty preset id.'
            : 'Active path layer references a missing path preset.',
        pathPresetId: missingUsage.presetId,
        mapId: missingUsage.mapId,
        mapName: missingUsage.mapName,
        layerIndex: missingUsage.layerIndex,
        layerId: missingUsage.layerId,
        layerName: missingUsage.layerName,
        detail: 'Active path cell count: ${missingUsage.activeCellCount}.',
      ),
    );
  }
}

void _addUsedPathDuplicateCandidateDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceCatalogView catalog,
  LegacyProjectSurfaceUsageView usage,
) {
  for (final presetId in _pathPresetIdsInUsageOrder(usage)) {
    final candidates = _pathSurfacesById(catalog, presetId);
    if (candidates.length <= 1) {
      continue;
    }
    final firstUsage = _firstPathUsage(usage, presetId);
    diagnostics.add(
      LegacySurfaceUsageDiagnostic(
        severity: LegacySurfaceUsageDiagnosticSeverity.warning,
        code: LegacySurfaceUsageDiagnosticCode
            .usedPathPresetWithMultipleDeclaredSurfaces,
        family: LegacySurfaceUsageDiagnosticFamily.path,
        message: 'Used path preset id has multiple declared candidates.',
        pathPresetId: presetId,
        mapId: firstUsage?.mapId,
        mapName: firstUsage?.mapName,
        layerIndex: firstUsage?.layerIndex,
        layerId: firstUsage?.layerId,
        layerName: firstUsage?.layerName,
        detail:
            '${candidates.length} declared path surfaces share the used id $presetId.',
      ),
    );
  }
}

void _addUsedPathWithoutVariantsDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceUsageView usage,
) {
  for (final pathUsage in usage.pathUsages) {
    if (pathUsage.surface.hasVariants) {
      continue;
    }
    diagnostics.add(
      LegacySurfaceUsageDiagnostic(
        severity: LegacySurfaceUsageDiagnosticSeverity.warning,
        code: LegacySurfaceUsageDiagnosticCode.usedPathSurfaceWithoutVariants,
        family: LegacySurfaceUsageDiagnosticFamily.path,
        message: 'Used path surface has no variants.',
        pathPresetId: pathUsage.presetId,
        surfaceId: pathUsage.surface.id,
        surfaceName: pathUsage.surface.name,
        mapId: pathUsage.mapId,
        mapName: pathUsage.mapName,
        layerIndex: pathUsage.layerIndex,
        layerId: pathUsage.layerId,
        layerName: pathUsage.layerName,
        detail: 'Active path cell count: ${pathUsage.activeCellCount}.',
      ),
    );
  }
}

void _addDeclaredPathWithoutUsageDiagnostics(
  List<LegacySurfaceUsageDiagnostic> diagnostics,
  LegacyProjectSurfaceCatalogView catalog,
  LegacyProjectSurfaceUsageView usage,
) {
  final usedPathIds = _pathPresetIdsInUsageOrder(usage).toSet();
  for (final surface in catalog.pathSurfaces) {
    if (usedPathIds.contains(surface.id)) {
      continue;
    }
    diagnostics.add(
      LegacySurfaceUsageDiagnostic(
        severity: LegacySurfaceUsageDiagnosticSeverity.info,
        code: LegacySurfaceUsageDiagnosticCode.declaredPathSurfaceWithoutUsage,
        family: LegacySurfaceUsageDiagnosticFamily.path,
        message: 'Declared path surface has no matching path usage.',
        pathPresetId: surface.id,
        surfaceId: surface.id,
        surfaceName: surface.name,
        detail:
            'No analyzed PathLayer usage resolves to path preset id ${surface.id}.',
      ),
    );
  }
}

List<TerrainType> _terrainTypesInUsageOrder(
  LegacyProjectSurfaceUsageView usage,
) {
  final seen = <TerrainType>{};
  final ordered = <TerrainType>[];
  for (final terrainUsage in usage.terrainUsages) {
    final type = terrainUsage.terrainType;
    if (type == TerrainType.none || !seen.add(type)) {
      continue;
    }
    ordered.add(type);
  }
  return ordered;
}

LegacyTerrainSurfaceUsage? _firstTerrainUsage(
  LegacyProjectSurfaceUsageView usage,
  TerrainType type,
) {
  for (final terrainUsage in usage.terrainUsages) {
    if (terrainUsage.terrainType == type) {
      return terrainUsage;
    }
  }
  return null;
}

List<String> _pathPresetIdsInUsageOrder(
  LegacyProjectSurfaceUsageView usage,
) {
  final seen = <String>{};
  final ordered = <String>[];
  for (final pathUsage in usage.pathUsages) {
    final id = pathUsage.presetId;
    if (!seen.add(id)) {
      continue;
    }
    ordered.add(id);
  }
  return ordered;
}

LegacyPathSurfaceUsage? _firstPathUsage(
  LegacyProjectSurfaceUsageView usage,
  String presetId,
) {
  for (final pathUsage in usage.pathUsages) {
    if (pathUsage.presetId == presetId) {
      return pathUsage;
    }
  }
  return null;
}

List<LegacyPathSurfaceView> _pathSurfacesById(
  LegacyProjectSurfaceCatalogView catalog,
  String id,
) {
  return catalog.pathSurfaces
      .where((surface) => surface.id == id)
      .toList(growable: false);
}
// ignore_for_file: invalid_annotation_target

import '../exceptions/map_exceptions.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';

/// Generates a list of [TilesetVisualFrame] from a vertical atlas layout.
///
/// This helper creates frames for animated surfaces (e.g., water, tall grass)
/// following the vertical atlas convention observed in Pokémon SDK/Pokémon Studio:
///
/// - column = visual variant
/// - row = animation frame
///
/// Each frame becomes a [TilesetVisualFrame] with:
/// - source.x = column
/// - source.y = startRow + frameIndex
/// - source.width = sourceWidth
/// - source.height = sourceHeight
///
/// This is a pure builder: it does not load images, validate against real tileset
/// dimensions, or resolve playback timing. Timing resolution is handled by
/// [resolveTileVisualFrameTimeline] (Lot 2).
///
/// V0 intentionally does not map columns to [TerrainPathVariant] or create persistent
/// [SurfaceDefinition] models. Those are future lots.
List<TilesetVisualFrame> createTileVisualFramesFromVerticalAtlas({
  required int column,
  int startRow = 0,
  required int frameCount,
  int sourceWidth = 1,
  int sourceHeight = 1,
  String tilesetId = '',
  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
  List<int?>? frameDurationsMs,
}) {
  // Validate structural parameters
  _validateParameters(
    column: column,
    startRow: startRow,
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );

  final frames = <TilesetVisualFrame>[];

  for (var i = 0; i < frameCount; i += 1) {
    // Calculate source position: column stays constant, row increments
    final source = TilesetSourceRect(
      x: column,
      y: startRow + i,
      width: sourceWidth,
      height: sourceHeight,
    );

    // Determine duration for this frame
    final durationMs = _resolveFrameDuration(
      frameIndex: i,
      defaultDurationMs: defaultDurationMs,
      frameDurationsMs: frameDurationsMs,
    );

    // Create the visual frame
    frames.add(
      TilesetVisualFrame(
        tilesetId: tilesetId,
        source: source,
        durationMs: durationMs,
      ),
    );
  }

  // Return an unmodifiable list to preserve immutability
  return List.unmodifiable(frames);
}

void _validateParameters({
  required int column,
  required int startRow,
  required int frameCount,
  required int sourceWidth,
  required int sourceHeight,
  required int defaultDurationMs,
  required List<int?>? frameDurationsMs,
}) {
  if (column < 0) {
    throw const ValidationException('column must be non-negative');
  }

  if (startRow < 0) {
    throw const ValidationException('startRow must be non-negative');
  }

  if (frameCount <= 0) {
    throw const ValidationException('frameCount must be positive');
  }

  if (sourceWidth <= 0) {
    throw const ValidationException('sourceWidth must be positive');
  }

  if (sourceHeight <= 0) {
    throw const ValidationException('sourceHeight must be positive');
  }

  if (defaultDurationMs <= 0) {
    throw const ValidationException('defaultDurationMs must be positive');
  }

  if (frameDurationsMs != null && frameDurationsMs.length != frameCount) {
    throw ValidationException(
      'frameDurationsMs length (${frameDurationsMs.length}) '
      'must equal frameCount ($frameCount)',
    );
  }

  if (frameDurationsMs != null) {
    for (var i = 0; i < frameDurationsMs.length; i += 1) {
      final duration = frameDurationsMs[i];
      if (duration != null && duration <= 0) {
        throw ValidationException(
          'frameDurationsMs[$i] must be positive (got $duration)',
        );
      }
    }
  }
}

int _resolveFrameDuration({
  required int frameIndex,
  required int defaultDurationMs,
  required List<int?>? frameDurationsMs,
}) {
  // If no per-frame durations provided, use default for all frames
  if (frameDurationsMs == null) {
    return defaultDurationMs;
  }

  // Use per-frame duration if provided, otherwise fall back to default
  final customDuration = frameDurationsMs[frameIndex];
  return customDuration ?? defaultDurationMs;
}
// ignore_for_file: invalid_annotation_target

import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';
import 'tile_visual_frame_vertical_atlas.dart';

/// Explicit mapping from [TerrainPathVariant] to vertical atlas column.
///
/// This small value describes one visual variant in a vertical atlas:
/// - [variant] = the path role (e.g., isolated, horizontal, cornerNE)
/// - [column] = the x-coordinate in the atlas grid
/// - [startRow] = optional y-offset for this variant
///
/// V0 deliberately does not enforce a complete variant set. Callers can map only
/// the variants they need, in any order. This keeps the builder flexible for
/// partial atlases or custom layouts.
final class PathVariantVerticalAtlasColumn {
  const PathVariantVerticalAtlasColumn({
    required this.variant,
    required this.column,
    this.startRow = 0,
  });

  /// The path role this column represents.
  final TerrainPathVariant variant;

  /// The x-coordinate in the atlas grid.
  final int column;

  /// Optional y-offset for this variant.
  final int startRow;
}

/// Generates [PathPresetVariantMapping] from a vertical atlas layout.
///
/// This helper bridges the Lot 11 frame builder and legacy path presets:
///
/// Input:  [TerrainPathVariant -> column] mappings
/// Output: [PathPresetVariantMapping] for legacy presets
///
/// Each mapping becomes a [PathPresetVariantMapping] with:
/// - variant = input variant
/// - frames = frames generated by Lot 11 helper
///
/// The function preserves input order and validates that no variant appears twice.
///
/// V0 intentionally does not:
/// - auto-map all [TerrainPathVariant] values
/// - create [ProjectPathPreset]
/// - validate against real image dimensions
/// - load images
///
/// Those are future lots.
List<PathPresetVariantMapping> createPathVariantMappingsFromVerticalAtlas({
  required List<PathVariantVerticalAtlasColumn> columns,
  required int frameCount,
  int sourceWidth = 1,
  int sourceHeight = 1,
  String tilesetId = '',
  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
  List<int?>? frameDurationsMs,
}) {
  // Validate input list
  _validateColumns(columns);

  // Validate frame parameters
  _validateFrameParameters(
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );

  final mappings = <PathPresetVariantMapping>[];

  for (final column in columns) {
    // Generate frames for this column
    final frames = createTileVisualFramesFromVerticalAtlas(
      column: column.column,
      startRow: column.startRow,
      frameCount: frameCount,
      sourceWidth: sourceWidth,
      sourceHeight: sourceHeight,
      tilesetId: tilesetId,
      defaultDurationMs: defaultDurationMs,
      frameDurationsMs: frameDurationsMs,
    );

    // Create mapping
    mappings.add(
      PathPresetVariantMapping(
        variant: column.variant,
        frames: frames,
      ),
    );
  }

  // Return unmodifiable list
  return List.unmodifiable(mappings);
}

void _validateColumns(List<PathVariantVerticalAtlasColumn> columns) {
  if (columns.isEmpty) {
    throw const ValidationException('columns must not be empty');
  }

  // Check for duplicate variants
  final seenVariants = <TerrainPathVariant>{};
  for (final column in columns) {
    if (column.column < 0) {
      throw const ValidationException('column must be non-negative');
    }
    if (column.startRow < 0) {
      throw const ValidationException('startRow must be non-negative');
    }
    if (!seenVariants.add(column.variant)) {
      throw ValidationException(
        'Duplicate TerrainPathVariant: ${column.variant}',
      );
    }
  }
}

void _validateFrameParameters({
  required int frameCount,
  required int sourceWidth,
  required int sourceHeight,
  required int defaultDurationMs,
  required List<int?>? frameDurationsMs,
}) {
  if (frameCount <= 0) {
    throw const ValidationException('frameCount must be positive');
  }
  if (sourceWidth <= 0) {
    throw const ValidationException('sourceWidth must be positive');
  }
  if (sourceHeight <= 0) {
    throw const ValidationException('sourceHeight must be positive');
  }
  if (defaultDurationMs <= 0) {
    throw const ValidationException('defaultDurationMs must be positive');
  }
  if (frameDurationsMs != null && frameDurationsMs.length != frameCount) {
    throw ValidationException(
      'frameDurationsMs length (${frameDurationsMs.length}) '
      'must equal frameCount ($frameCount)',
    );
  }
  if (frameDurationsMs != null) {
    for (var i = 0; i < frameDurationsMs.length; i += 1) {
      final duration = frameDurationsMs[i];
      if (duration != null && duration <= 0) {
        throw ValidationException(
          'frameDurationsMs[$i] must be positive (got $duration)',
        );
      }
    }
  }
}
// ignore_for_file: invalid_annotation_target

import '../exceptions/map_exceptions.dart';
import '../models/enums.dart';
import '../models/project_manifest.dart';
import 'map_placed_element_animation.dart';
import 'path_variant_vertical_atlas_mapping.dart';

/// Generates a complete legacy [ProjectPathPreset] from a vertical atlas layout.
///
/// This helper bridges Lot 11/Lot 12 vertical atlas builders and legacy path presets:
///
/// Input:  [TerrainPathVariant -> column] mappings + metadata
/// Output: [ProjectPathPreset] ready for legacy runtime/editor
///
/// The preset preserves:
/// - id, name, surfaceKind, tilesetId, categoryId, sortOrder from arguments
/// - variant order exactly as provided in [columns]
/// - frame structure generated by Lot 11 via Lot 12
///
/// V0 intentionally does not:
/// - create [SurfaceDefinition] or persistent Surface models
/// - auto-map all [TerrainPathVariant] values
/// - validate against real image dimensions
/// - load images or resolve playback timing
/// - branch runtime/editor or modify JSON contracts
///
/// Those are future Surface Engine lots.
ProjectPathPreset createProjectPathPresetFromVerticalAtlas({
  required String id,
  required String name,
  required PathSurfaceKind surfaceKind,
  required String tilesetId,
  String? categoryId,
  int sortOrder = 0,
  required List<PathVariantVerticalAtlasColumn> columns,
  required int frameCount,
  int sourceWidth = 1,
  int sourceHeight = 1,
  String frameTilesetId = '',
  int defaultDurationMs = defaultPlacedElementAnimationFrameDurationMs,
  List<int?>? frameDurationsMs,
}) {
  // Validate preset-level fields
  _validatePresetParameters(
    id: id,
    name: name,
    tilesetId: tilesetId,
    columns: columns,
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );

  // Generate variant mappings using Lot 12 helper
  final variants = createPathVariantMappingsFromVerticalAtlas(
    columns: columns,
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    tilesetId: frameTilesetId,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );

  // Build the legacy preset
  return ProjectPathPreset(
    id: id,
    name: name,
    surfaceKind: surfaceKind,
    tilesetId: tilesetId,
    categoryId: categoryId,
    sortOrder: sortOrder,
    variants: variants,
  );
}

void _validatePresetParameters({
  required String id,
  required String name,
  required String tilesetId,
  required List<PathVariantVerticalAtlasColumn> columns,
  required int frameCount,
  required int sourceWidth,
  required int sourceHeight,
  required int defaultDurationMs,
  required List<int?>? frameDurationsMs,
}) {
  // Preset-level validations
  if (id.trim().isEmpty) {
    throw const ValidationException('id must not be empty');
  }
  if (name.trim().isEmpty) {
    throw const ValidationException('name must not be empty');
  }
  if (tilesetId.trim().isEmpty) {
    throw const ValidationException('tilesetId must not be empty');
  }

  // Delegate column and frame validations to Lot 12 helper
  // This keeps validation logic centralized and consistent
  _validateColumns(columns);
  _validateFrameParameters(
    frameCount: frameCount,
    sourceWidth: sourceWidth,
    sourceHeight: sourceHeight,
    defaultDurationMs: defaultDurationMs,
    frameDurationsMs: frameDurationsMs,
  );
}

// Re-export Lot 12 validation helpers for consistency
void _validateColumns(List<PathVariantVerticalAtlasColumn> columns) {
  if (columns.isEmpty) {
    throw const ValidationException('columns must not be empty');
  }

  final seenVariants = <TerrainPathVariant>{};
  for (final column in columns) {
    if (column.column < 0) {
      throw const ValidationException('column must be non-negative');
    }
    if (column.startRow < 0) {
      throw const ValidationException('startRow must be non-negative');
    }
    if (!seenVariants.add(column.variant)) {
      throw ValidationException(
        'Duplicate TerrainPathVariant: ${column.variant}',
      );
    }
  }
}

void _validateFrameParameters({
  required int frameCount,
  required int sourceWidth,
  required int sourceHeight,
  required int defaultDurationMs,
  required List<int?>? frameDurationsMs,
}) {
  if (frameCount <= 0) {
    throw const ValidationException('frameCount must be positive');
  }
  if (sourceWidth <= 0) {
    throw const ValidationException('sourceWidth must be positive');
  }
  if (sourceHeight <= 0) {
    throw const ValidationException('sourceHeight must be positive');
  }
  if (defaultDurationMs <= 0) {
    throw const ValidationException('defaultDurationMs must be positive');
  }
  if (frameDurationsMs != null && frameDurationsMs.length != frameCount) {
    throw ValidationException(
      'frameDurationsMs length (${frameDurationsMs.length}) '
      'must equal frameCount ($frameCount)',
    );
  }
  if (frameDurationsMs != null) {
    for (var i = 0; i < frameDurationsMs.length; i += 1) {
      final duration = frameDurationsMs[i];
      if (duration != null && duration <= 0) {
        throw ValidationException(
          'frameDurationsMs[$i] must be positive (got $duration)',
        );
      }
    }
  }
}
