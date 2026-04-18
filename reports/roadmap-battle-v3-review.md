# Review technique de la roadmap battle canonique v3

## 1. Résumé exécutif honnête

La roadmap v3 est nettement meilleure que l’ancienne lecture héritée du repo, mais elle n’est pas canonique telle quelle.

Ce qu’elle comprend correctement :
- le moteur battle PokeMap n’est plus un prototype “pré-fondations” ;
- il existe déjà un vrai slice `singles-only` jouable avec actif + réserves, vrai handoff runtime, vraie overlay, vraie timeline, vraies battles wild/trainer, vraie capture minimale et vrai write-back minimal ;
- le problème dominant n’est plus “l’absence de moteur”, mais la centralisation dans `packages/map_battle/lib/src/battle_session.dart`, l’asymétrie des seams, et la dérive documentaire.

Ce qu’elle dit trop fort ou trop faux :
- elle parle trop comme si le canon battle était à “réinitialiser” alors qu’une partie du canon existe déjà sous forme de slice produit versionné, smoke tests, bridge runtime réel et host lançable ;
- elle réintroduit `R2 scheduler` et `R3 conditions` comme des fondations à construire, alors qu’un scheduler local réel et un condition engine réel existent déjà ; le vrai sujet est leur consolidation et leur extension honnête, pas leur invention ;
- elle fige trop l’ordre `R2 -> R3 -> R4`, alors que le repo montre que `R4` peut devenir prioritaire si la prochaine mécanique Showdown-like touche `forced switch`, `self switch` ou l’élargissement des requests/contracts ;
- elle refuse `H3` de manière trop absolue. Le repo ne justifie pas “aucun H3 possible”. Il justifie “pas de H3 large ou structurellement coûteux tant que les seams actuels ne sont pas consolidés”.

Verdict net :
- la roadmap v3 est **bonne dans son diagnostic principal** ;
- elle est **meilleure que la vieille roadmap** ;
- elle est **trop reset-heavy et trop rigide dans son séquencement** pour devenir le canon telle quelle ;
- elle est **adoptable après corrections**, pas adoptable en l’état.

## 2. Pré-gates exécutés + résultats

Pré-gates read-only exécutés au début de ce passage :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultats réellement observés avant création du présent report :

- `git status --short --untracked-files=all`
  - `?? reports/battle-state-vs-showdown-audit.md`
- `git diff --stat`
  - vide
- `git ls-files --others --exclude-standard`
  - `reports/battle-state-vs-showdown-audit.md`

Conclusion utile :
- le worktree n’était pas parfaitement propre au départ ;
- l’unique bruit initial était un report markdown non suivi préexistant ;
- aucun diff tracked n’était présent.

## 3. Méthode réelle utilisée

Ordre réel de travail :

1. revalidation de l’état Git read-only ;
2. réutilisation de l’audit battle/runtime précédent comme hypothèse de départ, puis revalidation ciblée des preuves ;
3. rerun des validations utiles sur `map_battle`, `map_runtime`, `map_editor` et `examples/playable_runtime_host` ;
4. relecture ciblée du code battle, runtime, bootstrap, host et docs/roadmaps historiques ;
5. comparaison ciblée avec le clone local Showdown ;
6. usage de sub-agents spécialisés ;
7. review séparée adverse ;
8. synthèse et rédaction du rapport.

Sous-agents réellement utilisés pour ce passage :

- `Darwin` : battle-core / architecture / fit de la roadmap avec `map_battle`
- `Dirac` : comparaison Showdown ciblée + jugement sur le séquencement
- `Pasteur` : runtime / bootstrap / host / vérité produit
- `Carson` : review adverse supplémentaire sur l’obsolescence de la roadmap héritée
- `Huygens` : reviewer final séparé, chargé d’attaquer le fond

Skills / plugins réellement utilisés :

- plugin `Superpowers`
  - `using-superpowers`
  - `dispatching-parallel-agents`
  - `verification-before-completion`
- plugin `Game Studio`
  - non utilisé sur le fond, car la demande porte sur un audit d’architecture/code battle/runtime, pas sur un playtest visuel browser-game.

Code réellement lu ou relu pour cette review :

- battle core :
  - `packages/map_battle/lib/src/battle_session.dart`
  - `packages/map_battle/lib/src/battle_state.dart`
  - `packages/map_battle/lib/src/battle_setup.dart`
  - `packages/map_battle/lib/src/battle_decision.dart`
  - `packages/map_battle/lib/src/battle_queue.dart`
  - `packages/map_battle/lib/src/battle_condition_engine.dart`
  - `packages/map_battle/lib/src/battle_field.dart`
  - `packages/map_battle/lib/src/battle_status.dart`
  - `packages/map_battle/lib/src/battle_volatile.dart`
  - `packages/map_battle/lib/src/battle_move.dart`
  - `packages/map_battle/lib/src/battle_action.dart`
  - `packages/map_battle/lib/src/battle_type_chart.dart`
  - `packages/map_battle/lib/src/battle_spikes.dart`
  - `packages/map_battle/lib/src/battle_stealth_rock.dart`
- runtime / host :
  - `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
  - `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
  - `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
  - `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
  - `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
  - `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
  - `examples/playable_runtime_host/README.md`
  - `examples/playable_runtime_host/golden_battle_slice/README.md`
  - `examples/playable_runtime_host/lib/src/runtime_launch_save.dart`
- bootstrap / seed :
  - `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`
  - `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
  - `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`
- historique :
  - `ROADMAP_FANGAME_RECALEE.md`
  - `reports/phase-battle-post-m8-audit-report.md`
  - `reports/phase-battle-be1-bridge-hardening-report.md`
  - `reports/phase-r1-lot-11-wild-battle-end-to-end-report.md`
  - `reports/phase-a-golden-battle-slice-report.md`
  - `reports/phase-h2-spikes-minimal-report.md`
- Showdown local :
  - `pokemon-showdown-master/sim/battle-queue.ts`
  - `pokemon-showdown-master/sim/side.ts`
  - `pokemon-showdown-master/sim/field.ts`
  - `pokemon-showdown-master/data/moves.ts`
  - `pokemon-showdown-master/test/sim/misc/hazards.js`

## 4. Périmètre audité

Périmètre effectivement audité :

- battle core réel
  - `packages/map_battle/**`
- runtime battle réel
  - `packages/map_runtime/**`
- bootstrap / seed / projet frais
  - `packages/map_editor/**`
- host / vérité produit lançable
  - `examples/playable_runtime_host/**`
- roadmaps / reports / docs historiques
  - `reports/**`
  - `ROADMAP_FANGAME_RECALEE.md`
  - `plan battle engine/plan-moteur-combat-projet.md`
- référence Showdown locale
  - `/Users/karim/Project/pokemonProject/pokemon-showdown-master/**`

Important :
- la roadmap auditée est le texte fourni dans le prompt utilisateur ;
- les fichiers roadmap/reports du repo ont servi de contrepoint historique, pas de source de vérité primaire ;
- la vérité primaire reste le code et les validations relancées.

## 5. État réel du moteur battle aujourd’hui

### 5.1. Le moteur n’est plus “pré-fondations”

Le repo battle actuel porte déjà un vrai slice moteur :

- vraie topologie sides + actif + réserves dans `packages/map_battle/lib/src/battle_state.dart:55-65` et `packages/map_battle/lib/src/battle_state.dart:523-595`
- vrai `BattleSetup` avec réserves joueur et ennemi dans `packages/map_battle/lib/src/battle_setup.dart:41-56`
- vrai request model joueur typé dans `packages/map_battle/lib/src/battle_decision.dart:70-220`
- vraie queue locale de tour dans `packages/map_battle/lib/src/battle_queue.dart:6-241`
- vrai condition engine consommé par le moteur dans `packages/map_battle/lib/src/battle_condition_engine.dart:15-240`
- vrai ordre d’action avec priorité / vitesse / inversion locale Trick Room dans `packages/map_battle/lib/src/battle_session.dart:1347-1463`
- vraie résolution de PP / accuracy / crit minimal / dégâts / STAB / type chart / immunités dans `packages/map_battle/lib/src/battle_session.dart:1700-1815` et `packages/map_battle/lib/src/battle_type_chart.dart:199-265`
- vraies side mechanics `Stealth Rock` et `Spikes` avec restitution timeline dans `packages/map_battle/lib/src/battle_session.dart:2284-2307`

Dire encore “pas de vraie topologie”, “pas de vraie queue” ou “pas de vraie battleabilité” est faux au regard du code.

### 5.2. Ce que le moteur supporte réellement

Support effectivement exécutable aujourd’hui dans `map_battle` :

- `singles-only`, un seul slot actif par side
- actif + réserves joueur
- actif + réserves ennemi pour trainer battles
- `BattleTurnChoiceRequest`
- `BattleForcedReplacementRequest`
- ordre minimal par priorité puis vitesse, avec inversion locale Trick Room
- consommation de PP
- accuracy minimale
- crit minimal
- dégâts simples sur snapshot de stats
- STAB
- effectiveness / immunités via type chart locale
- statuts majeurs `par`, `brn`, `psn`, `tox`
- volatiles `protect`, `mustRecharge`, `chargeThenStrike`
- field `rain`, `sandstorm`, `trickRoom`
- switch volontaire
- remplacement forcé joueur
- auto-switch ennemi
- `Stealth Rock`
- `Spikes`
- timeline ordonnée exploitable par le runtime

### 5.3. Ce que le moteur supporte mais en slice local borné

Exemples de support réel mais borné :

- le request model reste joueur-only, `slot 0` only, singles-only dans `packages/map_battle/lib/src/battle_decision.dart:70-97`
- la queue sait gérer seulement `Fight`, `Switch`, `Recharge`, fin de tour, checks post-turn, auto-switch et replacement-required dans `packages/map_battle/lib/src/battle_queue.dart:78-90` et `packages/map_battle/lib/src/battle_queue.dart:145-241`
- le condition engine couvre seulement statuts majeurs, volatiles BE8 et field BE9, pas les side conditions dans `packages/map_battle/lib/src/battle_condition_engine.dart:23-37`
- `BattleMoveTarget` existe, mais la session dit explicitement que cela n’ouvre pas un targeting riche dans `packages/map_battle/lib/src/battle_move.dart:21-42` et `packages/map_battle/lib/src/battle_session.dart:1717-1766`
- les hazards sont deux branches dédiées, pas un framework de side conditions dans `packages/map_battle/lib/src/battle_session.dart:2284-2307`

### 5.4. Ce qui reste faux, simplifié ou fragile

Fragilités et simplifications concrètes :

- pas de `Struggle` ; l’ennemi lève un `StateError` s’il n’a plus de move utilisable dans `packages/map_battle/lib/src/battle_session.dart:908-929`
- fallback IA douteux vers `BattleActionRun()` si l’ennemi n’a aucune attaque dans `packages/map_battle/lib/src/battle_session.dart:928-929`
- tie-break à vitesse égale déterministe “joueur avant ennemi”, sans PRNG ni shuffle Showdown-like dans `packages/map_battle/lib/src/battle_session.dart:1430-1439`
- priorité de switch locale hardcodée à `6` dans `packages/map_battle/lib/src/battle_session.dart:1451-1459`
- politique `double KO => victory` maintenue par vérification “enemy d’abord” dans `packages/map_battle/lib/src/battle_session.dart:2022-2033`
- ordre hazards local `Stealth Rock puis Spikes`, divergent de Showdown dans `packages/map_battle/lib/src/battle_session.dart:2287-2307`
- compatibilité historique encore présente :
  - type `unknown` neutralisé au lieu d’échouer dans `packages/map_battle/lib/src/battle_move.dart:192` et `packages/map_battle/lib/src/battle_type_chart.dart:203-236`
  - `resolvedCategory` fallback historique `physical/status` dans `packages/map_battle/lib/src/battle_move.dart:430-444`

### 5.5. Le vrai problème structurel actuel

Le problème principal n’est pas “pas assez de moves”. C’est :

- la densité de causalité dans `packages/map_battle/lib/src/battle_session.dart`
- l’asymétrie entre conditions de field/status/volatile d’un côté et side conditions/hazards de l’autre
- la petitesse volontaire des contrats de request/targeting/queue
- la présence de dettes de compatibilité historiques dans le core battle

`battle_session.dart` reste le centre de gravité du moteur :
- IA
- choix ennemi
- ordre
- queue execution
- résolution d’exécution
- calcul de dégâts
- issue determination
- interruptions H1/H2
- reprise après remplacement

Preuves directes :
- `packages/map_battle/lib/src/battle_session.dart:690-752`
- `packages/map_battle/lib/src/battle_session.dart:908-950`
- `packages/map_battle/lib/src/battle_session.dart:1322-1463`
- `packages/map_battle/lib/src/battle_session.dart:1717-1815`
- `packages/map_battle/lib/src/battle_session.dart:2036-2055`
- `packages/map_battle/lib/src/battle_session.dart:2284-2307`

## 6. État réel du runtime / bootstrap / host

### 6.1. Runtime battle réel

Le runtime battle n’est pas hypothétique. Il est branché.

Preuves :

- ouverture battle depuis `PlayableMapGame` avec vrai mapping asynchrone dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3032-3115`
- mémorisation explicite de la lineup runtime pour write-back honnête dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3047-3090`
- write-back outcome réel dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3209-3248`
- whiteout-lite réel dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3280-3315`

### 6.2. Runtime setup / bridge / overlay

`RuntimeBattleSetupMapper` :
- construit vrai `BattleSetup` depuis la vraie party et les vraies teams trainer dans `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:48-172`
- sélectionne actif + réserves jouables dans `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:175-248`
- décide `allowCapture` au bon seam runtime dans `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:161-171`

`RuntimeBattleMoveBridge` :
- transporte réellement priorité, PP, target battle, field subset, side subset et crit minimal via le chemin runtime ;
- refuse explicitement ce qui dépasse le slice supporté ;
- supporte le sous-ensemble exact Trick Room via garde `structuredPartial` ciblée dans `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:764-886`

`BattleOverlayComponent` :
- exige une vraie timeline et refuse le vieux mode “buckets seuls” dans `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:35-54`
- consomme la chronologie observable du moteur pour afficher les événements battle.

### 6.3. Runtime write-back réel, mais étroit

Le write-back runtime existe, mais il ne faut pas le sur-vendre.

Ce qui est réellement réécrit :
- PV du lineup engagé sur les bons slots party dans `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:319-380`
- flag trainer defeated sur vraie victoire trainer dans `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:225-229`
- capture minimale avec consommation d’une Poké Ball et ajout à la party dans `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:186-223` et `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:274-317`
- whiteout-lite minimal à `1 HP` pour un seul slot dans `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:57-119`

Ce qui n’est pas encore réécrit honnêtement :
- PP courants
- statuts majeurs persistés
- items/abilities/side conditions post-battle

Le code le dit explicitement dans `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:329-332`.

### 6.4. Bootstrap / seed : honnête, mais imparfait

Le bootstrap moves est volontairement curaté, offline, versionné et non exhaustif dans `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:14-40`.

Points honnêtes :
- le seed ne prétend pas être tout Showdown dans `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:60-76`
- il garde des entrées `catalogOnly` quand le moteur/runtime ne savent pas les exécuter honnêtement

Points imparfaits :
- `stealth_rock` et `spikes` vivent encore dans une liste `_catalogOnlySeedMoves` malgré leur support bout à bout, même si le commentaire tente de recadrer cela dans `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:602-644`
- `trick_room` reste seedé en `structuredPartial` alors que le runtime bridge supporte désormais un sous-ensemble exact du move, ce qui crée une sous-déclaration documentaire dans `packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:804-843` et `packages/map_runtime/test/runtime_battle_move_bridge_test.dart:805-835`

### 6.5. Host / vérité produit

Le host d’exemple prouve une vérité produit battleable réelle.

Preuves :
- le host versionne un golden slice battle-ready dans `examples/playable_runtime_host/README.md:6-34`
- le golden slice README dit explicitement qu’il prouve le démarrage honnête d’un combat wild et trainer dans `examples/playable_runtime_host/golden_battle_slice/README.md:1-28`
- le smoke test runtime prouve un vrai démarrage de battle wild et trainer sur le slice versionné dans `packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart:18-108`
- le host test prouve l’existence d’une vraie save de lancement versionnée dans `examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart:9-22`

### 6.6. Limite importante : “slice battleable” ne veut pas dire “projet frais générique battle-ready”

La roadmap v3 parle comme si la “vérité produit battleable” était franchie. C’est vrai pour le golden slice versionné, pas pour n’importe quel projet fraîchement initialisé.

Preuves :
- `InitializePokemonProjectStorageUseCase` ne seed par défaut qu’un scaffold et un `moves.json` bootstrap ; il ne crée pas un projet immédiatement battle-ready avec espèces/learnsets/party jouables dans `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart:87-111`
- la mise à disposition d’un mini corpus battleable passe par `SeedPokemonDemoDataUseCase` et/ou par la save de lancement du host dans `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart:23-81`

Conséquence :
- “vérité produit battleable : faite” doit être formulé comme “versioned golden slice battleable : oui”, pas comme “tout projet frais est battle-ready”.

## 7. Comparaison Showdown ciblée

### 7.1. Fichiers Showdown consultés

Clone local utilisé :

- `/Users/karim/Project/pokemonProject/pokemon-showdown-master`

Fichiers consultés :

- `pokemon-showdown-master/sim/battle-queue.ts`
- `pokemon-showdown-master/sim/side.ts`
- `pokemon-showdown-master/sim/field.ts`
- `pokemon-showdown-master/data/moves.ts`
- `pokemon-showdown-master/test/sim/misc/hazards.js`

### 7.2. Tableau comparatif utile

| Famille | PokeMap réel | Showdown utile | Écart réel | Implication pour la roadmap |
|---|---|---|---|---|
| décision / request model | requests joueur-only, slot 0, singles-only dans `battle_decision.dart:70-220` | `requestState` side-level `move/switch/teampreview/wait` dans `sim/side.ts:280-349` | loin de Showdown, mais honnête pour le slice | la roadmap a raison de cibler requests/contracts, mais faux de faire comme si rien n’existait |
| side / slot | deux sides canoniques, actif + réserves, slot actif unique dans `battle_state.dart:523-595` | topology side plus riche, multi-positions selon format | proche seulement pour le scope singles local | la vieille histoire “pas de vraie topologie” est morte |
| targeting | petite taxonomie `self/opponent/field/opponentSide/unspecified` dans `battle_move.dart:21-42`, consommée localement dans `battle_session.dart:1717-1766` | targeting Showdown beaucoup plus riche | très loin structurellement | la roadmap a raison de viser les contracts/targeting, mais cet enjeu peut remonter avant R3 selon la mécanique visée |
| scheduling / queue | vraie queue locale, petite, bornée dans `battle_queue.dart:6-241` | `BattleQueue` centrale, riche, taxonomie large dans `sim/battle-queue.ts:166-376` | loin mais réelle | `R2` doit être consolidation du scheduler existant, pas création ex nihilo |
| conditions | vrai `BattleConditionEngine` pour statuses/volatiles/field dans `battle_condition_engine.dart:15-240` | conditions Showdown génériques + callbacks dans `sim/field.ts` et `data/moves.ts` | loin mais déjà ouvert | `R3` doit être consolidation et réduction d’asymétrie, pas fondation vide |
| hazards | SR + Spikes réels, side-level, ordre SR puis Spikes dans `battle_session.dart:2284-2307` | hazards side conditions génériques ; ordre testé Toxic Spikes -> Sticky Web -> Spikes -> Stealth Rock dans `test/sim/misc/hazards.js:86-92` | divergence concrète, pas convergence | la roadmap a raison d’éviter de continuer les hazards “pour le plaisir” |
| speed / priority / Trick Room | vrai ordre local avec tie-break déterministe joueur avant ennemi dans `battle_session.dart:1347-1459` | queue/action ordering + tie handling plus riche dans `sim/battle-queue.ts` et Trick Room pseudoWeather complet dans `data/moves.ts:20007-20045` | local honnête mais simplifié | le repo est déjà plus réel que ne le dit la roadmap, mais reste loin de Showdown |
| accuracy / PP / crit | vrais seams minimaux dans `battle_session.dart:1700-1815` | pipeline beaucoup plus riche | simplifié mais vivant | la roadmap héritée qui disait cela “à construire” est dépassée |
| field / pseudoWeather | `rain`, `sandstorm`, `trickRoom` bornés dans `battle_field.dart` | map pseudoWeather générique + callbacks `onFieldStart/onFieldRestart/onFieldEnd` dans `sim/field.ts:195-228` et `data/moves.ts:20007-20045` | loin de Showdown | justifie consolidation R3, mais pas réinvention de zéro |
| runtime bridge | bridge réel, strict, avec refus explicites | Showdown n’a pas ce seam runtime local | n/a côté moteur Showdown, mais seam produit fort côté PokeMap | la roadmap doit le reconnaître comme déjà acquis |
| bootstrap truth | seed curaté, non exhaustif, partiellement sous-déclaré | Showdown data exhaustive | pas comparable directement | la roadmap doit distinguer seed honnête curaté et parité Showdown |

### 7.3. Lecture froide

Conclusion Showdown utile :

- PokeMap est déjà “surprenant de réalité” pour un repo qui se racontait encore récemment comme très en amont ;
- mais PokeMap reste loin de Showdown sur les couches architecturales, pas seulement sur la liste des mécaniques ;
- l’écart qui bloque vraiment la suite n’est pas “il manque tel move”, c’est “les couches déjà ouvertes restent trop étroites et trop concentrées”.

## 8. Audit section par section de la roadmap proposée

### 8.1. Section `0. Statut réel canonique`

Verdict : **globalement correcte mais incomplète**

Ce qui est juste :
- la liste des capacités réellement existantes colle globalement au repo réel ;
- le rejet du récit “pré-fondations” est correct ;
- le diagnostic “moteur trop centralisé / fondations asymétriques / doc en retard” est le meilleur point de la roadmap.

Ce qui manque ou glisse :
- la formulation “slice singles local” doit être précisée en “`singles-only` avec réserves”, pas “simple 1v1 plat” ;
- elle ne dit pas assez explicitement que queue et condition engine existent déjà comme composants vivants ;
- elle survole la dette de compatibilité historique dans `BattleMove` et `BattleTypeChart`.

### 8.2. Section `1. Vision générale`

Verdict : **correcte dans l’intention mais trop générique**

Bon point :
- viser requests, targeting, conditions, scheduling et contrats comme vrais axes structurels rapproche bien plus Showdown que d’empiler des moves.

Limite :
- la vision ne distingue pas assez “consolider ce qui existe déjà” de “construire de nouvelles fondations”.

### 8.3. Section `2. Règles stratégiques non négociables`

#### Règle 1 — Le code réel prime

Verdict : **bonne et à garder telle quelle**

Elle colle à la réalité du repo et corrige utilement la dérive des vieux reports.

#### Règle 2 — Aucun faux support

Verdict : **bonne et à garder telle quelle**

Elle colle exactement au comportement du bridge runtime, du host et du seed curaté.

#### Règle 3 — Pas de H3 tant que le canon n’est pas recadré

Verdict : **bonne mais à reformuler**

Pourquoi :
- refuser un H3 large ou structurellement coûteux maintenant est raisonnable ;
- refuser absolument tout H3 tant que `R0` n’est pas “terminé” est trop rigide ;
- le repo prouve déjà qu’un micro-slice borné peut être absorbé si ses seams restent compatibles avec l’existant, comme H1/H2 l’ont montré.

Formulation plus juste :
- pas de H3 large par défaut ;
- un H3 micro-slice n’est réouvrable qu’après vérité documentaire resserrée et hardening ciblé, et uniquement s’il tient dans les seams actuels.

#### Règle 4 — Pas de framework générique par panique

Verdict : **bonne et à garder telle quelle**

Elle colle exactement à l’esprit réel du repo.

#### Règle 5 — Toute étape doit produire une vérité mesurable

Verdict : **bonne et à garder telle quelle**

La golden slice, le smoke test, le bridge filtering et les tests battle vont déjà dans ce sens.

#### Règle 6 — On n’empile plus aveuglément dans battle_session.dart

Verdict : **bonne et à garder telle quelle**

C’est la bonne pression d’architecture.

#### Règle 7 — Le runtime ne doit jamais sur-promettre

Verdict : **bonne mais à nuancer**

Nuance :
- la prod runtime live ne sur-promet pas ;
- une partie de la dette documentaire actuelle est l’inverse : `packages/map_runtime/README.md` sous-promet le runtime réel.

#### Règle 8 — Le seed/bootstrap doit rester honnête

Verdict : **bonne et à garder telle quelle**

Elle colle à l’état réel du seed.

### 8.4. Section `3. Nouveau séquencement officiel`

#### Phase R0 — Canon reset

Verdict : **correcte dans l’intention mais mal formulée**

Le problème :
- le mot `reset` sur-corrige ;
- le canon n’est pas absent ;
- il existe déjà sous forme de golden slice versionné, smoke test runtime battle, host launch save, battle/runtime tests verts.

Le vrai besoin :
- réalignement documentaire et déclassification des artefacts obsolètes ;
- pas “refonder le canon”, mais “resserrer le canon déjà partiellement vivant”.

#### Phase R1 — Hardening du slice actuel

Verdict : **bonne mais à resserrer**

C’est la phase la plus solide de la roadmap.

Les vrais items R1 :
- `Struggle` absent
- fallback IA `BattleActionRun()`
- hard-fail `no bridgeable move`
- politique double KO
- ambiguïtés de seed/support labels
- doc runtime et rapports historiques décalés

Ce qui est trop flou :
- “hardening” ne doit pas devenir une phase vague où tout rentre.

#### Phase R2 — Fondation Scheduler

Verdict : **correcte dans l’intention mais mal ordonnée et mal nommée**

Faux implicite :
- le scheduler local n’est pas à créer ; il existe déjà.

Vrai besoin :
- consolidation / extraction / enrichissement du scheduler existant ;
- réduction de la gravité de `battle_session.dart`.

Le nom “Fondation Scheduler” peut rester seulement si le texte dit explicitement :
- il existe déjà une queue locale vivante ;
- R2 vise à la sortir du statut de petit scheduler absorbé par `BattleSession`.

#### Phase R3 — Fondation Conditions

Verdict : **correcte dans l’intention mais mal nommée**

Faux implicite :
- il existe déjà un foyer réel de conditions dans `BattleConditionEngine`.

Vrai besoin :
- réduction de l’asymétrie entre :
  - statuses / volatiles / field d’un côté
  - side conditions / entry hazards de l’autre
- clarification du cycle de vie des conditions supportées

#### Phase R4 — Fondation Targeting / Requests / Contracts

Verdict : **bonne mais à déplacer dans l’ordre**

Pourquoi :
- si la prochaine mécanique candidate est `forced switch` ou `self switch`, `R4` devient au moins aussi prioritaire que `R3` ;
- le repo actuel montre que le goulot n’est pas seulement conditionnel ; il est aussi dans la petitesse des requests et du targeting.

Le bon ordre n’est pas forcément `R3 puis R4`.

#### Phase H3 — Première reprise des mécaniques riches

Verdict : **bonne mais à reformuler**

Ce qui est juste :
- pas de reprise large et opportuniste ;
- pas de “move cool” ajouté sans substrat.

Ce qui est trop dur :
- la condition d’ouverture est écrite trop comme un mur absolu ;
- le repo justifie surtout un `yes under conditions` pour un micro-slice, pas un `no` métaphysique.

### 8.5. Section `4. Ordre officiel recommandé`

Verdict : **correcte dans l’esprit mais trop rigide**

Bon point :
- `R0 -> R1` avant toute reprise riche est sain.

Point faible :
- `R2 -> R3 -> R4` comme ordre fixe est trop rigide ;
- `R3` et `R4` devraient être dépendants de la famille Showdown-like réellement visée ensuite.

### 8.6. Section `5. Décision finale`

Verdict : **bonne mais trop catégorique**

“Ne pas partir sur H3 maintenant” est un bon garde-fou contre un H3 large ou paresseux.

Ce n’est pas encore une formulation canonique parfaite, car elle écrase la possibilité d’un micro-H3 borné si :
- la vérité documentaire est resserrée ;
- le hardening critique a été fait ;
- le candidat reste strictement dans les seams existants.

### 8.7. Section `6. Résumé ultra court`

Verdict : **bonne et à garder telle quelle après reformulation de H3**

L’esprit est bon. La phrase finale doit simplement éviter le `non` trop absolu sur H3.

## 9. Tableau des points corrects / discutables / faux / dépassés

| Point roadmap | Classement | Pourquoi | Preuves |
|---|---|---|---|
| “Le moteur est déjà réel” | correcte | vrai slice battle/runtime/host déjà en prod locale | `battle_session.dart`, `playable_map_game.dart:3040-3258`, `phase_a_golden_battle_slice_smoke_test.dart:18-108` |
| “Le problème n’est plus l’absence de moteur” | correcte | le vrai frein est structurel | `battle_session.dart:947`, `battle_queue.dart:6-20`, `battle_condition_engine.dart:15-37` |
| “Ancienne histoire pré-fondations fausse” | correcte | topologie, queue, request model, handoff et host réels existent | `battle_state.dart:523-595`, `battle_queue.dart:6-241`, `runtime_battle_setup_mapper.dart:48-172` |
| “R0 canon reset” | bonne mais à reformuler | le canon n’est pas absent ; il est partiellement vivant et mal aligné | `golden_battle_slice/README.md:1-28`, `phase_a_golden_battle_slice_smoke_test.dart:18-108` |
| “R1 hardening du slice actuel” | correcte | c’est le chantier technique le plus justifié à court terme | `battle_session.dart:908-929`, `runtime_battle_combatant_seed_builder.dart:118-125` |
| “R2 fondation scheduler” | correcte dans l’intention mais mal ordonnée | il existe déjà un scheduler local | `battle_queue.dart:6-241` |
| “R3 fondation conditions” | correcte dans l’intention mais mal ordonnée | il existe déjà un condition engine réel | `battle_condition_engine.dart:15-240` |
| “R4 targeting/contracts après R3” | bonne mais à déplacer dans l’ordre | peut devenir prioritaire selon le H3 candidat | `battle_move.dart:21-42`, `battle_decision.dart:70-97`, `battle_action.dart:136-148` |
| “Pas de framework générique par panique” | correcte | cohérent avec l’architecture réelle du repo | `battle_field.dart`, `battle_spikes.dart`, `battle_stealth_rock.dart` |
| “Le runtime ne doit jamais sur-promettre” | globalement correcte mais incomplète | la prod runtime ne sur-promet pas ; le README runtime sous-promet | `playable_map_game.dart:3040-3258`, `packages/map_runtime/README.md:18-23` |
| “La vérité produit battleable est faite” | globalement correcte mais incomplète | vrai pour le golden slice versionné ; faux si lu comme propriété de tout projet frais | `examples/playable_runtime_host/README.md:6-34`, `initialize_pokemon_project_storage_use_case.dart:87-111` |
| “H3 non maintenant” | bonne mais à reformuler | bon refus d’un H3 large ; trop absolu pour un micro-slice borné | `phase-h2-spikes-minimal-report.md:510-513`, `battle_stealth_rock_test.dart:282-330`, `battle_spikes_test.dart:619-639` |
| ordre fixe `R0 -> R1 -> R2 -> R3 -> R4 -> H3` | trompeuse | trop rigide, transforme des seams existants en prérequis à recréer | `battle_queue.dart:6-241`, `battle_condition_engine.dart:15-240`, `battle_decision.dart:70-97` |
| lecture héritée D/E/F comme photo actuelle | dépassée par le repo | bridge runtime, wild loop, capture, whiteout-lite sont déjà là | `ROADMAP_FANGAME_RECALEE.md:662-704` contre `playable_map_game.dart:3040-3315`, `runtime_battle_outcome_apply.dart:57-233` |

## 10. Blockers réels pour continuer à se rapprocher de Showdown

| Blocker | Type | Severity | Why it matters now | Blocks H3? | Evidence |
|---|---|---|---|---|---|
| Centralisation de la causalité dans `battle_session.dart` | architecture | high | chaque nouvelle mécanique riche risque d’être une branche ad hoc de plus | oui pour un H3 structurellement coûteux | `battle_session.dart:690-752`, `battle_session.dart:947`, `battle_session.dart:1322-1463`, `battle_session.dart:1717-1815` |
| Queue locale réelle mais trop petite | scheduling | high | elle n’absorbe pas proprement des familles plus riches de sequencing/interruptions | oui si H3 dépasse `Fight/Switch/Recharge` | `battle_queue.dart:6-20`, `battle_queue.dart:78-90` |
| Condition engine réel mais asymétrique | architecture | high | statuses/volatiles/field y vivent ; side conditions/hazards n’y vivent pas | oui pour un H3 condition-side-level | `battle_condition_engine.dart:15-37`, `battle_session.dart:2284-2307` |
| Contracts / requests / targeting trop serrés | contracts | high | `forced switch`, `self switch`, targeting side-level riche ne rentrent pas proprement | oui si H3 touche switch/phazing/self-switch | `battle_decision.dart:70-97`, `battle_move.dart:21-42`, `battle_action.dart:136-148` |
| Hard-fail “no bridgeable move remaining after filtering” | runtime | medium | peut empêcher le démarrage malgré un moteur battle réel | oui côté produit/runtime content | `runtime_battle_combatant_seed_builder.dart:53-125` |
| Pas de `Struggle` + fallback IA douteux | product | medium | edge-case honteux visible, dette assumée mais non traitée | non pour un micro-H3, oui pour élargissement de contenu | `battle_session.dart:908-929` |
| Tie-break et ordre hazards locaux divergents de Showdown | product | medium | limite la prétention Showdown-like et doit être assumée/documentée | non pour tout H3, oui pour discours de convergence | `battle_session.dart:1430-1439`, `battle_session.dart:2287-2307`, `hazards.js:86-92` |
| Bootstrap/support labels en léger décalage | bootstrap | medium | produit un canon de vérité flou si non recadré | non seul, oui pour canon propre | `pokemon_moves_bootstrap_seed.dart:602-844`, `runtime_battle_move_bridge_test.dart:805-835` |
| README/runtime docs historiques obsolètes | product | low | entretient une fausse photographie du runtime | non techniquement, oui documenteirement | `packages/map_runtime/README.md:18-23` |
| Fresh project générique non battle-ready par défaut | bootstrap | medium | empêche de confondre golden slice et bootstrap universel | non pour core battle, oui pour vérité produit | `initialize_pokemon_project_storage_use_case.dart:87-111`, `seed_pokemon_demo_data_use_case.dart:23-81` |

## 11. Décision sur H3 maintenant ou non

Réponse honnête :

- **non** pour un H3 large, opportuniste, ou qui ouvrirait de nouvelles branches lourdes dans `battle_session.dart`
- **oui sous conditions** pour un H3 micro-slice strictement borné qui tient dans les seams actuels

Donc, la phrase canonique la plus juste n’est pas :

- “H3 maintenant : non, point”

mais plutôt :

- “H3 large maintenant : non”
- “H3 micro-slice maintenant : seulement après vérité documentaire resserrée + hardening ciblé, et uniquement si le candidat rentre dans les contrats actuels”

Pourquoi ce n’est pas un vrai `non` absolu :

- H1 et H2 ont déjà montré que le moteur peut absorber une famille bornée supplémentaire sans s’écrouler ;
- la queue sait déjà suspendre un tour, demander un remplacement forcé, puis reprendre les étapes restantes ;
- le point bloquant n’est pas l’impossibilité totale d’ajouter quoi que ce soit, c’est l’impossibilité d’ouvrir n’importe quoi proprement.

Preuves :
- `packages/map_battle/lib/src/battle_session.dart:1322-1345`
- `packages/map_battle/test/battle_stealth_rock_test.dart:282-330`
- `packages/map_battle/test/battle_spikes_test.dart:619-639`

Conséquence pour la roadmap :
- le refus d’un H3 large est juste ;
- la formulation “donc non, pas maintenant” est trop absolue pour devenir le canon sans nuance.

## 12. Verdict final sur la roadmap

Verdict global :

- la roadmap v3 est **globalement saine sur le diagnostic**
- elle est **meilleure que l’ancienne vision héritée**
- elle est **trop reset-heavy et trop rigide** pour être adoptée telle quelle
- elle est **adoptable après corrections**

Pourquoi elle n’est pas adoptable telle quelle :

1. elle traite comme “fondations à ouvrir” des couches déjà vivantes ;
2. elle surestime l’absence de canon alors qu’un canon partiel existe déjà ;
3. elle fige un ordre `R2 -> R3 -> R4` que le repo ne justifie pas ;
4. elle transforme un bon garde-fou contre H3 large en interdit trop absolu.

## 13. Corrections proposées si nécessaire

Une v3.1 corrigée n’a pas besoin de tout réécrire. Il faut corriger seulement ce qui est faux, bancal ou mal ordonné.

### 13.1. Correction 1 — renommer et resserrer R0

Remplacer `R0 — Canon reset` par quelque chose comme :

- `R0 — Truth alignment / recadrage canonique`

Contenu réel :
- déclasser les roadmaps/reports manifestement dépassés ;
- aligner la documentation runtime/host/battle avec le repo réel ;
- expliciter la distinction entre golden slice battleable et projet frais générique ;
- publier une matrice de support actuelle.

Ce que R0 ne doit pas raconter :
- que le canon battle est entièrement absent.

### 13.2. Correction 2 — resserrer R1

R1 doit être listé sur des dettes concrètes :

- `Struggle`
- fallback IA `Run`
- hard-fail `no bridgeable move`
- double KO policy
- seed/support labels (`trick_room`, regroupement `catalogOnly`)
- doc/runtime truth ciblée

Pas plus.

### 13.3. Correction 3 — réécrire R2

Remplacer l’idée implicite “fonder le scheduler” par :

- consolider, extraire et enrichir le scheduler local existant

Objectif :
- faire sortir davantage de sequencing de `BattleSession`
- sans inventer un clone de `sim/battle-queue.ts`

### 13.4. Correction 4 — réécrire R3

Remplacer l’idée implicite “créer une place pour les conditions” par :

- consolider le condition engine existant
- traiter explicitement l’asymétrie side-level

Objectif :
- réduire les branches spéciales pour hazards / side conditions
- sans ouvrir un `runEvent` Showdown-like total

### 13.5. Correction 5 — rendre R4 conditionnel

La bonne règle n’est pas “R4 après R3” mais :

- si le prochain candidat touche switch / phazing / self-switch / forced action, remonter R4 avant ou avec R3
- si le prochain candidat touche status/volatile/side condition riche, R3 peut venir avant

### 13.6. Correction 6 — reformuler H3

Remplacer :

- “pas de H3 maintenant”

par :

- “pas de H3 large ni structurellement coûteux maintenant”
- “un H3 micro-slice n’est rouvrable qu’après vérité documentaire resserrée et hardening ciblé, et seulement s’il reste dans les seams actuels”

## 14. Critique explicite du prompt et de la roadmap

### 14.1. Ce que le prompt et la roadmap demandent correctement

- ils exigent de repartir du code réel ;
- ils combattent explicitement les faux supports ;
- ils forcent à regarder runtime, bootstrap et host, pas seulement `map_battle` ;
- ils refusent les frameworks morts et les refactors abstraits décoratifs ;
- ils recentrent la discussion sur la convergence Showdown utile, pas sur l’accumulation de moves.

### 14.2. Ce qui est discutable

- le mot `reset` dans `R0` dramatise trop un problème documentaire réel mais partiel ;
- l’enchaînement linéaire `R2 -> R3 -> R4` suppose une dépendance plus forte que ce que montre le repo ;
- la formulation `pas de H3 tant que ...` peut pousser à une inertie excessive alors que le repo supporte déjà des micro-slices bornés.

### 14.3. Ce qui est déjà dépassé par le repo

- toute lecture héritée qui traite bridge runtime -> battle, wild battle loop, capture minimale, seen/caught ou whiteout-lite comme “à venir” ;
- toute formulation qui fait encore de la queue et du condition engine des absences ;
- toute photographie qui sous-estime le host golden slice et la vérité produit déjà versionnée.

### 14.4. Ce qui pourrait pousser à un faux diagnostic si suivi aveuglément

- croire que le repo a surtout un problème de documentation et pas un vrai problème d’architecture battle ;
- croire que R0 seul débloquera la suite ;
- croire que “pas de H3” est la seule position saine alors que le vrai critère est l’ajustement du candidat aux seams actuels ;
- croire que le battle core est encore trop pauvre pour toute extension, ce qui sous-vend H1/H2 et les preuves runtime/host déjà acquises.

## 15. Retour des sub-agents

### 15.1. Sub-agent battle-core / architecture — Darwin

Apport :
- a confirmé que la roadmap lit juste le diagnostic principal : le moteur n’est plus pré-fondations ;
- a montré que `R2` et `R3` racontent mal l’existant, parce qu’une vraie queue et un vrai condition engine existent déjà ;
- a insisté sur le fait que `R4` est peut-être sous-priorisé selon la future mécanique.

Retenu :
- le constat “centralisation et asymétrie des fondations” est le meilleur point de la roadmap ;
- `R1` est la phase la plus solide ;
- `R2/R3` doivent être reformulés en consolidation, pas invention.

Rejeté ou nuancé :
- Darwin classe `R0` comme utile mais surtout gouvernance ; je le retiens partiellement, mais je conserve l’idée qu’un réalignement documentaire fort reste nécessaire.

### 15.2. Sub-agent showdown comparison — Dirac

Apport :
- a confirmé que `R0 -> R1 -> R2` est un squelette raisonnable ;
- a rappelé que PokeMap reste loin de Showdown sur requests/queue/effects génériques ;
- a noté que `R3` et `R4` ne doivent marcher que s’ils restent étroits.

Retenu :
- pas de faux rapprochement avec Showdown ;
- les couches structurelles comptent plus que les moves isolés.

Rejeté ou nuancé :
- Dirac refuse H3 maintenant de façon plus dure ; je le nuance avec le reviewer final, qui montre qu’un micro-H3 borné reste conceptuellement possible.

### 15.3. Sub-agent runtime/bootstrap truth — Pasteur

Apport :
- a rappelé que runtime handoff, overlay, write-back minimal et host truth existent déjà et ne doivent plus être racontés comme futurs ;
- a insisté sur la différence entre golden slice battleable et projet frais générique ;
- a pointé le vrai enjeu bootstrap/content startability.

Retenu :
- R0/R1 doivent être recalibrés autour de la vérité produit réelle ;
- la roadmap sous-estime que le host battleable existe déjà.

Rejeté ou nuancé :
- Pasteur pousse assez fort vers “content readiness” ; je le garde surtout comme correction produit/bootstrap, pas comme remplacement du sujet battle-core.

### 15.4. Sub-agent review adverse supplémentaire — Carson

Apport :
- a contesté la tendance à faire du README runtime l’axe documentaire principal ;
- a rappelé que la vérité produit la plus honnête vit surtout dans le host et la golden slice ;
- a jugé l’ancienne roadmap héritée explicitement dépassée sur le bridge battle réel.

Retenu :
- la vérité produit la plus crédible est la golden slice et ses smoke tests ;
- la roadmap héritée n’est plus utilisable comme photo battle/runtime.

## 16. Retour du reviewer séparé

Reviewer final séparé :

- `Huygens`

Findings concrets retenus :

1. `R2 -> R3 -> R4` part d’une prémisse fausse si elle suppose ces couches absentes. La queue, le condition engine et les contrats singles existent déjà en version bornée.
2. `R0 canon reset` sur-corrige. Le canon n’est pas vide ; le vrai problème est une dérive documentaire sélective.
3. `H3 no-now` est trop absolu. Les preuves H1/H2 montrent qu’un micro-slice borné peut rentrer si ses seams sont compatibles.
4. `R1 hardening` doit être plus petit et plus précis : hard-fail de setup, labels seed/support, vérité bootstrap/documentation.
5. `R4` ne doit pas être automatiquement relégué après `R3`.

Ce qu’il a challengé explicitement :
- le caractère trop “reset” de la roadmap ;
- la tendance à re-solver des couches déjà existantes ;
- l’absolutisme du refus de H3.

Doutes restants après review :
- le degré exact auquel un micro-H3 serait rentable maintenant dépend du candidat précis ; le repo ne permet pas de l’affirmer dans l’abstrait.

Conclusion du reviewer séparé :
- **pas adoptable telle quelle**
- il faut une version plus petite, plus exacte et moins rigide

## 17. Autocritique finale

Limites de cette review :

- je n’ai pas construit un harness automatisé de comparaison comportementale PokeMap vs Showdown ;
- la review Showdown reste ciblée sur les couches utiles, pas sur une parité exhaustive ;
- une partie du jugement sur la rentabilité d’un micro-H3 reste une inférence architecturale, pas une preuve mathématique ;
- je n’ai pas réexécuté l’intégralité de tous les tests runtime du package, seulement le sous-ensemble battle/runtime utile à cette review ;
- la roadmap auditée est un texte inline utilisateur, pas un artefact versionné du repo, ce qui limite les renvois ligne à ligne côté roadmap elle-même.

Points où je pourrais encore me tromper :

- sur la priorité relative exacte de `R3` et `R4`, car elle dépend fortement du prochain candidat H3 concret ;
- sur la sévérité à accorder à la dette documentaire vs la dette architecturale selon la manière dont l’équipe gouverne réellement le repo.

## 18. Commandes réellement lancées

Pré-gates Git :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Validation battle :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test
```

Validation runtime ciblée :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/application/runtime_battle_outcome_apply.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
```

Validation bootstrap / editor :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub \
  lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart \
  test/pokemon_moves_bootstrap_seed_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test \
  test/pokemon_moves_bootstrap_seed_test.dart
```

Validation host :

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter test \
  test/project_loader_page_test.dart \
  test/runtime_launch_save_test.dart \
  test/runtime_demo_party_seed_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

Inspection read-only ciblée :

```bash
rg --files -g 'ROADMAP*' -g 'reports/**' -g 'docs/**' -g 'plan*'
rg -n ...
nl -ba ... | sed -n ...
```

Sub-agents / reviewer :

- `send_input` et `wait_agent` vers `Darwin`, `Dirac`, `Pasteur`, `Carson`, `Huygens`

## 19. Résultats réellement obtenus

Pré-gates :

- `git status --short --untracked-files=all`
  - `?? reports/battle-state-vs-showdown-audit.md`
- `git diff --stat`
  - vide
- `git ls-files --others --exclude-standard`
  - `reports/battle-state-vs-showdown-audit.md`

Validation battle :

- `dart analyze`
  - `No issues found!`
- `dart test`
  - `All tests passed!`

Validation runtime ciblée :

- `flutter analyze --no-pub ...`
  - `Analyzing 12 items... No issues found!`
- `flutter test ...`
  - `All tests passed!`

Validation bootstrap / editor :

- `flutter analyze --no-pub ...`
  - `Analyzing 2 items... No issues found!`
- `flutter test ...`
  - `All tests passed!`

Validation host :

- `flutter test ...`
  - `All tests passed!`

Bruit observé mais non bloquant :

- certains appels Flutter ont brièvement affiché `Waiting for another flutter command to release the startup lock...`
- ce n’est pas un problème du repo ; c’est un bruit d’environnement/outil

## 20. État git final utile

État Git utile après création du présent report :

- fichiers non suivis :
  - `reports/battle-state-vs-showdown-audit.md`
  - `reports/roadmap-battle-v3-review.md`
- aucun diff tracked introduit par cette review
- aucun fichier du code source modifié

## 21. Checklist finale

- ai-je utilisé le code réel comme source de vérité principale ? oui
- ai-je distingué support honnête vs support partiel vs support mensonger ? oui
- ai-je comparé le moteur à Showdown sur le bon périmètre ? oui
- ai-je évalué runtime et bootstrap, pas seulement `map_battle` ? oui
- ai-je signalé les contradictions roadmap / repo ? oui
- ai-je évité tout faux “c’est presque bon” ? oui
- ai-je décidé clairement si H3 est cohérent maintenant ou non ? oui
- ai-je justifié cette décision avec preuves ? oui
- ai-je gardé le travail strictement read-only ? oui, hors création du report markdown demandé
- ai-je utilisé des sub-agents ? oui
- ai-je fait une review séparée ? oui
- ai-je inclus une autocritique finale ? oui

## 22. Décision nette : adoptable telle quelle / adoptable après corrections / non adoptable

**Décision nette : adoptable après corrections**

Formulation finale :

- la roadmap v3 est meilleure que l’ancienne lecture héritée ;
- elle décrit correctement le vrai problème principal du repo ;
- elle n’est pas assez exacte pour devenir le canon telle quelle ;
- elle doit être corrigée sur :
  - la portée de `R0`
  - la définition de `R1`
  - la formulation de `R2` et `R3`
  - l’ordre relatif de `R4`
  - l’absolutisme du refus de `H3`

Décision opérationnelle :

- **adoptable après corrections**
- **pas adoptable telle quelle**
