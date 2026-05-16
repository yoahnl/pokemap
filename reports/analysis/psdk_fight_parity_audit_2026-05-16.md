# Audit de parite PSDK Fight - 2026-05-16

## Perimetre

Cet audit mesure l'etat actuel de la parite du moteur de combat Dart avec Pokemon SDK, en se concentrant sur `packages/map_battle`, l'integration runtime via `packages/map_runtime`, et les sources locales Pokemon SDK suivantes :

- `pokemonsdk-development/scripts/5 Battle`
- `pokémon_sdk_test_project/Data/Studio/moves`
- `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- `packages/map_battle/tool/generate_psdk_attack_coverage_report.dart`
- `packages/map_battle/tool/extract_psdk_effect_matrix.dart`

Les animations ne sont pas auditees ici, conformement au perimetre actuel. Les changements non lies deja presents dans `map_editor` / `reports/shadows` n'ont pas ete modifies.

Context Mode : indisponible dans cette session (`ctx status` retourne `command not found`). Les sorties volumineuses ont donc ete limitees, generees dans `/tmp`, puis synthetisees.

## Resume executif

Le moteur est beaucoup plus propre et plus proche de Pokemon SDK qu'au debut de la migration : on a une architecture de combat Dart dediee, un registre PSDK, des comportements par familles de moves, des effets objet, un pipeline de degats, de priorite, de PP, d'accuracy, de statuts, de meteo/terrain, de switch et de timeline teste.

Mais la parite stricte avec Pokemon SDK n'est pas encore atteinte. Le chiffre important est celui-ci :

| Axe | Etat actuel | Pourcentage strict |
| --- | ---: | ---: |
| Methodes `battleEngineMethod` PSDK portees completement | 25 / 330 | 7.58% |
| Methodes `battleEngineMethod` PSDK partielles | 305 / 330 | 92.42% |
| Attaques Studio vraiment `fait` | 33 / 728 | 4.53% |
| Attaques Studio `partiel` | 695 / 728 | 95.47% |
| Attaques Studio `pas_fait` / inconnues | 0 / 728 | 0.00% |
| Effets PSDK completement portes | 0 / 482 | 0.00% |
| Effets PSDK partiels | 25 / 482 | 5.19% |
| Effets PSDK manquants | 457 / 482 | 94.81% |

Interpretation importante : `pas_fait = 0` ne veut pas dire que les 728 attaques sont correctes. Cela veut dire que chaque attaque Studio locale a au moins une entree de registre ou un fallback partiel. La parite stricte des attaques reste a 33 / 728.

## Etat d'alignement global

| Domaine | Alignement | Etat |
| --- | ---: | --- |
| Clean architecture battle Dart | Eleve | Le package `map_battle` est pur Dart, isole, avec domain/application/data, registry PSDK et tests dedies. |
| Chargement et index des attaques Studio | Eleve | 728 attaques Studio sont lues, 258 methodes uniques sont reconnues, 0 methode inconnue. |
| Couverture executable minimale | Eleve mais partielle | Toutes les attaques ont un chemin local, mais 95.47% passent par un comportement partiel. |
| Parite stricte des attaques | Faible | 33 attaques sur 728 sont marquees `fait`. |
| Parite stricte des methodes Ruby `battleEngineMethod` | Faible | 25 methodes sur 330 sont `ported`. |
| Effets PSDK et callbacks | Tres faible | 0 effet completement porte, 25 effets partiels, 457 manquants. |
| Runtime bridge joueur -> battle | Moyen-faible | Le bridge est honnete et teste, mais encore beaucoup plus restrictif que le moteur PSDK partiel. |
| Multi-target / doubles / banks complexes | Partiel | La topologie existe, mais le comportement cible/side/ally reste incomplet. |
| Items et abilities | Partiel | Quelques effets existent, mais la matrice PSDK montre encore 251 ability effects et 87 item effects manquants. |
| AI Pokemon SDK | Faible | Les fichiers PSDK AI sont identifies, mais la logique actuelle reste une politique locale simplifiee. |

Score synthetique recommande :

- Parite stricte attaques : 4.53%.
- Parite stricte methodes PSDK : 7.58%.
- Parite stricte effets PSDK : 0%.
- Parite fonctionnelle locale du slice teste : bonne, car les tests passent, mais ce n'est pas une parite Pokemon SDK complete.

## Ce qui est aligne

### Architecture combat

Le moteur actuel respecte bien la direction voulue :

- `packages/map_battle` reste un package Dart pur.
- Les concepts PSDK sont modelises dans des couches explicites : topology, battler state, action queue, move registry, effect stack, handlers, timeline, RNG.
- Les anciens contrats runtime ne sont pas melanges directement avec les sources Ruby.
- Les comportements de moves sont regroupes par familles dans `packages/map_battle/lib/src/domain/move/behaviors`.

Fichiers representatifs :

- `packages/map_battle/lib/src/domain/battle/battle_context.dart`
- `packages/map_battle/lib/src/domain/battle/battle_topology.dart`
- `packages/map_battle/lib/src/domain/action/battle_action_queue.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_registry.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`
- `packages/map_battle/lib/src/domain/effect/battle_effect_stack.dart`
- `packages/map_battle/lib/src/domain/handler/*`

### Data PSDK et coverage

Le registre local couvre maintenant tous les `battleEngineMethod` utilises par les 728 attaques Studio locales :

- total attaques Studio : 728
- methodes battle uniques dans Studio : 258
- methodes inconnues : 0
- attaques sans entree locale : 0

Cela donne une bonne base d'inventaire et evite les trous silencieux.

### Tests et verification locale

La suite `map_battle` est consequente :

- 85 fichiers de tests Dart dans `packages/map_battle/test`
- 68 fichiers de tests contenant `psdk` dans leur chemin
- 38 fichiers dans `packages/map_battle/test/psdk_move_families`
- 888 tests passent sur `packages/map_battle`

Les tests couvrent notamment :

- degats et type chart
- STAB / immunites / third type
- accuracy, crit, PP
- stat stages
- statuts majeurs
- meteo / terrain / pseudo-weather
- multi-hit
- fixed damage
- variable power
- recoil, drain, heal
- self destruct / direct HP
- switch et hazards
- Transform
- plusieurs effets objet : Protect, Confusion, Taunt, Disable, Encore, Bind, Leech Seed, Ingrain, Aqua Ring, Salt Cure, etc.

### Methodes vraiment portees

Les methodes `battleEngineMethod` strictement marquees `ported` sont actuellement :

| Methode | Attaques Studio couvertes |
| --- | ---: |
| `s_2hits` | 6 |
| `s_brine` | 1 |
| `s_electro_ball` | 1 |
| `s_endeavor` | 1 |
| `s_eruption` | 2 |
| `s_facade` | 1 |
| `s_fixed_damage` | 2 |
| `s_flail` | 2 |
| `s_full_crit` | 2 |
| `s_guard_split` | 1 |
| `s_hp_eq_level` | 2 |
| `s_power_split` | 1 |
| `s_power_trick` | 1 |
| `s_psywave` | 1 |
| `s_speed_swap` | 1 |
| `s_stored_power` | 3 |
| `s_super_fang` | 2 |
| `s_venoshock` | 1 |
| `s_wring_out` | 2 |

Les 33 attaques Studio marquees `fait` sont :

`bonemerang`, `brine`, `crush_grip`, `double_hit`, `double_kick`, `dragon_rage`, `dual_chop`, `electro_ball`, `endeavor`, `eruption`, `facade`, `flail`, `frost_breath`, `gear_grind`, `guard_split`, `nature_s_madness`, `night_shade`, `power_split`, `power_trick`, `power_trip`, `psywave`, `punishment`, `reversal`, `seismic_toss`, `sonic_boom`, `speed_swap`, `stored_power`, `storm_throw`, `super_fang`, `twineedle`, `venoshock`, `water_spout`, `wring_out`.

## Ce qui n'est pas aligne

### 1. La majorite des attaques sont encore des comportements partiels

Top des comportements partiels actuels :

| Comportement Dart partiel | Attaques concernees |
| --- | ---: |
| `StaticBasicMoveRegistry.s_basic` | 229 |
| `StatusStatMoveBehavior.selfStat` | 50 |
| `StatusStatMoveBehavior.stat` | 27 |
| `StatusStatMoveBehavior.status` | 18 |
| `MultiHitMoveBehavior.psdkRandom` | 14 |
| `StaticBasicMoveRegistry.s_2turns` | 12 |
| `RecoilMoveBehavior.psdkRecoil` | 12 |
| `StaticBasicMoveRegistry.s_z_move` | 10 |
| `DrainMoveBehavior.absorb` | 9 |
| `StaticBasicMoveRegistry.s_protect` | 9 |
| `StaticBasicMoveRegistry.s_bind` | 8 |
| `StaticBasicMoveRegistry.s_reload` | 8 |
| `StaticBasicMoveRegistry.s_cantflee` | 7 |
| `HealMoveBehavior` | 6 |

`s_basic` a lui seul couvre 229 attaques. C'est utile pour jouer, mais ce n'est pas une preuve de parite : toutes les particularites PSDK autour de callbacks, effets secondaires, flags, items, abilities, targeting et messages ne sont pas garanties.

### 2. Les effets PSDK sont le plus gros ecart

La matrice extraite depuis `pokemonsdk-development/scripts/5 Battle/06 Effects` donne :

| Famille PSDK | `partial` | `missing` |
| --- | ---: | ---: |
| ability | 3 | 251 |
| field | 0 | 15 |
| item | 0 | 87 |
| mechanics | 0 | 4 |
| move | 22 | 93 |
| status | 0 | 7 |

Les familles de hooks les plus manquantes sont :

| Hook family manquante | Nombre |
| --- | ---: |
| `post_damage` | 75 |
| `switch` | 70 |
| `end_turn` | 52 |
| `status_prevention` | 33 |
| `move_prevention` | 29 |
| `lifecycle` | 28 |
| `stat_change` | 23 |
| `action_order` | 19 |
| `damage_prevention` | 14 |
| `weather_change` | 10 |

Les 25 effets seulement partiels sont :

`AquaRing`, `ArenaTrap`, `Attract`, `BatonPass`, `Bind`, `CantSwitch`, `Confusion`, `Curse`, `Disable`, `Encore`, `Flinch`, `HealBlock`, `Imprison`, `Ingrain`, `LeechSeed`, `MagnetPull`, `Protect`, `SaltCure`, `ShadowTag`, `SmackDown`, `SyrupBomb`, `TarShot`, `Taunt`, `ThroatChop`, `Torment`.

Points non alignes majeurs :

- pas de generic PSDK `EffectBase` complet ;
- pas de cycle complet `on_delete`, `on_reset_states`, `on_clear_message`, `on_increase_message` ;
- `post_damage`, `switch`, `end_turn` et prevention sont encore tres incomplets ;
- les effets abilities/items sont largement absents ;
- les messages et branches d'exception PSDK restent souvent notes comme futur travail.

### 3. Le runtime bridge reste beaucoup plus restrictif que `map_battle`

`packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart` projette les moves canoniques vers `BattleMoveData`. Il est volontairement honnete, mais limite :

- refuse encore `heal`, `drain`, `recoil` dans beaucoup de cas runtime ;
- refuse `selfSwitch`, `forceSwitch`, `setTerrain`, `setSlotCondition` ;
- refuse de nombreux statuts majeurs hors `par`, `brn`, `psn`, `tox` ;
- accepte seulement `protect` comme volatile auto-cible ;
- accepte seulement `raindance`, `sandstorm`, `trickroom` cote champ ;
- laisse certains riders, comme la confusion de `Water Pulse`, tomber en degats purs ;
- autorise `Transform` via un cas special, mais pas encore toute la famille de moves de copie/appel (`Mimic`, `Sketch`, `Metronome`, `Sleep Talk`, etc.).

Consequence directe : une attaque peut etre partiellement presente dans `map_battle` mais ne pas etre utilisable depuis l'exemple runtime, le picker ou le bridge actuel.

### 4. Le ciblage PSDK complet n'est pas encore la

La topologie Dart existe, mais le bridge runtime et beaucoup de comportements restent centres sur le slice local singles :

- `self`
- adversaire actif
- terrain global limite
- side adverse pour quelques hazards

Pokemon SDK gere beaucoup plus largement :

- banks multiples ;
- ally / foe side ;
- position-tied effects ;
- adjacent targets ;
- multi-target ;
- redirect / follow me / ally switch ;
- slots et effets de position.

Les methodes marquees avec dependencies `targetingMulti`, `handlerSwitch`, `field`, `terrain`, `effects` indiquent les endroits a reprendre.

### 5. L'AI Pokemon SDK n'est pas encore equivalente

Pokemon SDK contient `5 Battle/30 AI` avec base AI, choix de move, mega evolution, switch, item et flee. Le moteur actuel a une politique d'opposant locale testee, mais pas une parite AI PSDK :

- pas de heuristiques PSDK completes ;
- pas d'integration des items/abilities complets dans la decision ;
- pas de scoring equivalent aux familles PSDK.

### 6. Les actions PSDK hors attaque restent partielles

Pokemon SDK a des actions dediees :

- Attack / PreAttack
- Mega
- Item
- Switch
- Flee
- HighPriorityItem
- Shift
- NoAction

Le moteur local couvre le combat utile, les switches et quelques items runtime, mais pas toute la grammaire d'action PSDK.

## Ecart fichier par fichier a haut niveau

| Zone Pokemon SDK | Source PSDK | Etat Dart | Verdict |
| --- | --- | --- | --- |
| Scene / UI battle | `01 Scene`, `02 Visual` | Hors perimetre moteur, UI Flutter runtime separee | Pas de parite stricte attendue ici |
| PokemonBattler | `03 PokemonBattler` | `BattleBattler`, stats, histories, transform state | Partiel mais bien structure |
| Logic / handlers | `04 Logic`, `04 Logic/1 Handlers` | handlers Dart damage/stat/status/weather/terrain/item/switch/end turn | Partiel |
| Actions | `05 Actions` | action queue, decision mapper, turn runner | Partiel |
| Effects | `06 Effects` | 25 effets partiels, registries ability/item/status/field | Tres incomplet |
| Move mechanics | `10 Move/1 Mechanics` | procedure, accuracy, damage, type, prevention, target resolver | Bon socle, parite incomplete |
| Move definitions | `10 Move/2 Definitions` | 330 methodes manifestees, 25 ported, 305 partial | Incomplet |
| MoveAnimation | `20 MoveAnimation` | Hors audit actuel | Non evalue |
| AI | `30 AI` | politique locale simplifiee | Incomplet |

## Taches restantes pour une vraie parite

### Lot A - Stabiliser la mesure de parite

Objectif : rendre les chiffres ci-dessus reproductibles en CI.

Actions :

- Ajouter un script unique qui regenere :
  - couverture attaques Studio ;
  - matrice effets PSDK ;
  - compteur methodes `ported` / `partial` / `missing` ;
  - compteur runtime bridgeable.
- Faire echouer le check si une attaque devient `unknown_method`.
- Distinguer officiellement trois colonnes :
  - `registered`
  - `runtime_bridgeable`
  - `psdk_strict_parity`

Pourquoi : aujourd'hui `pas_fait = 0` peut donner une illusion de parite. Il faut un tableau qui montre clairement ce qui est jouable, partiel, et strictement fidele.

### Lot B - Aligner le runtime bridge sur le registre PSDK

Objectif : eviter que le runtime filtre des moves que `map_battle` sait deja executer partiellement ou completement.

Actions :

- Remplacer progressivement la projection `PokemonMove -> BattleMoveData` par une resolution `PokemonMove -> PsdkMoveRegistry`.
- Transporter le `battleEngineMethod` jusqu'au moteur quand il existe.
- Ajouter un statut explicite dans l'UI :
  - jouable complet ;
  - jouable partiel ;
  - bloque par bridge ;
  - bloque par donnees.
- Mesurer le nombre exact d'attaques bridgeables dans l'exemple runtime.

Pourquoi : actuellement le moteur bas niveau et le bridge runtime n'ont pas la meme definition de "supporte".

### Lot C - Promouvoir les familles partielles les plus massives

Objectif : augmenter vite la parite stricte des 728 attaques.

Priorite :

1. `s_basic` : 229 attaques.
2. `s_self_stat` : 50 attaques.
3. `s_stat` : 27 attaques.
4. `s_status` : 18 attaques.
5. `s_multi_hit` : 14 attaques.
6. `s_2turns` : 12 attaques.
7. `s_recoil` : 12 attaques.
8. `s_absorb` : 9 attaques.
9. `s_protect` : 9 attaques.
10. `s_bind` : 8 attaques.

Pourquoi : ces familles concentrent le plus d'attaques. Mais il faut les promouvoir seulement quand les exceptions PSDK sont couvertes, pas juste parce que les degats de base fonctionnent.

### Lot D - Porter le systeme d'effets PSDK generique

Objectif : sortir du statut "effets objet partiels isoles".

Actions :

- Definir un equivalent Dart clair de `EffectBase`.
- Representer les hooks PSDK comme des interfaces ou callbacks typed :
  - move prevention ;
  - damage prevention ;
  - post damage ;
  - end turn ;
  - switch ;
  - lifecycle ;
  - stat/status/weather/terrain change.
- Ajouter un dispatcher d'effets par phase.
- Faire migrer les 25 effets partiels vers ce dispatcher.

Pourquoi : sans ce lot, on continuera a coder des exceptions move par move au lieu de reproduire le moteur Pokemon SDK.

### Lot E - Ability et item effects

Objectif : couvrir les deux plus gros trous de la matrice effets.

Actions :

- Porter les ability effects par familles :
  - immunites ;
  - prevention ;
  - post-damage ;
  - switch trapping ;
  - weather ;
  - stat/status hooks.
- Porter les item effects par familles :
  - berries ;
  - held item damage modifiers ;
  - healing/residual ;
  - weather/terrain duration ;
  - recoil/drain modifiers ;
  - choice/scarf/band/specs-like locks.

Pourquoi : beaucoup d'attaques Pokemon ne sont correctes que si abilities/items sont dans la boucle.

### Lot F - Targeting, banks, sides et doubles

Objectif : passer du singles utile a une topologie PSDK fonctionnelle.

Actions :

- Finaliser les target resolvers pour `ally`, `allAdjacent`, `foeSide`, `allySide`, `random`, position-tied.
- Porter Follow Me / Rage Powder / Ally Switch / Helping Hand / wide guards.
- Porter les side conditions et slot conditions avec duree, stack et cleanup.
- Ajouter des scenarios doubles en tests.

Pourquoi : PSDK est structure autour des banks/positions ; sans ca, beaucoup de moves resteront partiels.

### Lot G - Actions PSDK completes

Objectif : couvrir la grammaire d'action.

Actions :

- Switch volontaire complet.
- Switch force complet.
- Items battle complets.
- Flee/Safari si voulu.
- Mega / Z / autres actions speciales si elles restent dans le scope.
- Shift / HighPriorityItem / NoAction.

Pourquoi : le combat Pokemon SDK n'est pas seulement "executer une attaque".

### Lot H - Golden tests contre Pokemon SDK

Objectif : prouver la parite, pas seulement l'intention.

Actions :

- Construire des fixtures Ruby/JSON attendues depuis PSDK pour des scenarios atomiques.
- Comparer :
  - HP final ;
  - stat stages ;
  - status/effects ;
  - timeline ;
  - target choisi ;
  - messages si le projet veut la parite texte.
- Ajouter une commande CLI de regression :
  - `dart run tool/psdk_parity_audit.dart`
  - `dart test test/psdk_golden/...`

Pourquoi : sans golden tests PSDK, le statut `ported` reste une declaration locale.

## Verification effectuee

Commandes executees :

```bash
ctx status
```

Resultat : echec attendu, `ctx` indisponible (`command not found`).

```bash
git status --short --untracked-files=all
```

Resultat avant audit : plusieurs changements non lies dans `AGENTS.md`, `packages/map_editor/...`, `reports/shadows/...`.

```bash
dart run tool/generate_psdk_attack_coverage_report.dart ../../pokémon_sdk_test_project/Data/Studio/moves /tmp/psdk-attack-coverage-current.md
```

Resultat : `Wrote 728 PSDK attack coverage rows to /tmp/psdk-attack-coverage-current.md`.

```bash
dart run tool/extract_psdk_effect_matrix.dart ../../pokemonsdk-development/scripts/'5 Battle' /tmp/psdk-effect-matrix-current.md
```

Resultat : succes, matrice extraite avec 482 effect classes.

```bash
dart test --reporter compact
```

Dans `packages/map_battle`.

Resultat : `All tests passed!`, 888 tests passes.

```bash
dart analyze
```

Dans `packages/map_battle`.

Resultat : `No issues found!`.

```bash
flutter test test/runtime_battle_move_bridge_test.dart test/runtime_battle_setup_mapper_test.dart --reporter compact
```

Dans `packages/map_runtime`.

Resultat : `All tests passed!`, 63 tests passes.

```bash
flutter test test/runtime_demo_party_seed_test.dart --reporter compact
```

Dans `examples/playable_runtime_host`.

Resultat : `All tests passed!`, 9 tests passes.

```bash
flutter analyze
```

Dans `packages/map_runtime`.

Resultat : echec avec 352 issues de niveau `info`, principalement `prefer_const_constructors`, plus quelques `avoid_relative_lib_imports` et conventions de noms dans les tests. Aucune correction faite car hors perimetre audit combat.

```bash
flutter analyze
```

Dans `examples/playable_runtime_host`.

Resultat : echec avec 2 issues de niveau `info` (`package_names`, `prefer_const_constructors`). Aucune correction faite car hors perimetre audit combat.

## Inventaire des fichiers touches par cet audit

Crees :

- `reports/analysis/psdk_fight_parity_audit_2026-05-16.md`

Modifies :

- Aucun fichier source.

Supprimes :

- Aucun.

Generes hors repo :

- `/tmp/psdk-attack-coverage-current.md`
- `/tmp/psdk-effect-matrix-current.md`

Changements preexistants non lies observes et non modifies volontairement :

- `AGENTS.md`
- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`
- `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`
- `packages/map_editor/test/editor_notifier_project_dirty_state_test.dart`
- `packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart`
- `packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart`
- `packages/map_editor/lib/src/application/use_cases/apply_element_auto_shadow_suggestions_use_case.dart`
- `packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart`
- `packages/map_editor/test/features/tileset_library/apply_element_auto_shadow_suggestions_use_case_test.dart`
- `packages/map_editor/test/tileset_palette_element_auto_shadow_backfill_test.dart`
- `reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md`
- `reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md`
- `reports/shadows/shadow_lot_40_element_auto_shadow_backfill_plan.md`

## Conclusion

On est dans un etat intermediaire solide : le moteur local est propre, teste, et il sait jouer beaucoup de situations utiles. En revanche, si on parle de vraie parite Pokemon SDK, on est encore au debut de la parite stricte.

Le plus gros ecart n'est plus "on n'a pas de systeme de combat" ; ce point est resolu. Le gros ecart est maintenant :

1. transformer les fallbacks partiels en comportements PSDK stricts ;
2. porter le systeme generique d'effets/callbacks ;
3. aligner le runtime bridge avec le registre PSDK ;
4. prouver la parite par golden tests contre Pokemon SDK.

Priorite recommandee : Lot A puis Lot B, avant de continuer a porter attaque par attaque. Sans ces deux lots, on risque de continuer a augmenter la couverture interne sans que le runtime jouable ni le pourcentage de parite stricte reflètent clairement le progres reel.

## Mise a jour Lot 01 - 2026-05-16

Le Lot 01 du plan 100% PSDK a ajoute un CLI reproductible :

```bash
cd packages/map_battle
dart run tool/psdk_fight_parity_audit.dart --json /tmp/psdk-fight-audit.json --markdown /tmp/psdk-fight-audit.md
```

Resultat verifie :

- attaques strictes : 33 / 728 ;
- attaques partielles : 695 / 728 ;
- attaques `pas_fait` : 0 / 728 ;
- methodes manifestees : 330 ;
- methodes portees : 25 ;
- methodes partielles : 305 ;
- effets PSDK : 482 ;
- effets partiels : 25 ;
- effets manquants : 457 ;
- runtime bridge : section presente mais `not_measured`, car les diagnostics runtime dedies sont prevus par le Lot 04.

Fichiers ajoutes/modifies par ce lot :

- `packages/map_battle/lib/src/data/psdk_fight_parity_audit.dart`
- `packages/map_battle/tool/psdk_fight_parity_audit.dart`
- `packages/map_battle/test/tool/psdk_fight_parity_audit_test.dart`
- `packages/map_battle/lib/src/data/psdk_attack_coverage_report.dart`
- `reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md`
- `reports/analysis/psdk_fight_parity_audit_2026-05-16.md`

## Mise a jour Lot 02 - 2026-05-16

Le Lot 02 a ajoute une gate de non-regression pour eviter que les prochains lots fassent baisser la parite mesuree.

Commande :

```bash
cd packages/map_battle
dart run tool/psdk_fight_parity_audit.dart --gate --json /tmp/psdk-fight-audit.json --markdown /tmp/psdk-fight-audit.md
```

Seuils initiaux :

- `unknown_methods <= 0`
- `strict_attacks >= 33`
- `strict_methods >= 25`
- `known_or_partial_effects >= 25`

Fichiers ajoutes/modifies par ce lot :

- `packages/map_battle/lib/src/data/psdk_parity_gate.dart`
- `packages/map_battle/tool/psdk_fight_parity_audit.dart`
- `packages/map_battle/test/psdk_parity_gate_test.dart`
- `reports/analysis/psdk_fight_parity_gate_policy.md`
- `reports/analysis/psdk_fight_100_percent_lot_plan_2026-05-16.md`
- `reports/analysis/psdk_fight_parity_audit_2026-05-16.md`
