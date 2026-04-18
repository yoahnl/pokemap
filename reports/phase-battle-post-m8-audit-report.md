# Audit post-M8 — battle engine / runtime battle bridge / moves canoniques

> Note R0 — Truth Alignment (2026-04-18)
>
> Ce report reste utile comme audit historique intermédiaire, mais il n'est plus canonique comme photographie du moteur battle et du runtime battle actuels.
>
> Il précède plusieurs seams désormais réellement vivants dans le dépôt actuel, notamment le request model live, la queue locale, le condition engine, les réserves multi-Pokémon, les hazards H1/H2 et la vérité produit du golden slice versionné.
>
> Sources canoniques actuelles:
>
> - `docs/combat/battle-canonical-state-v3.1.md`
> - `docs/combat/battle-roadmap-canonical-v3.1.md`

## 1. Résumé exécutif honnête

Le repo a objectivement franchi un cap utile entre M1 et M8 :

- la chaîne de données `Showdown -> PokemonMove canonique -> seed -> moves.json projet -> loaders runtime -> bridge runtime -> battle` existe vraiment ;
- les seams runtime sont aujourd’hui bien mieux découpés qu’au départ ;
- il n’existe pas de stack parallèle flagrante entre `map_editor`, `map_runtime` et `map_battle` pour les moves ;
- `map_battle` sait enfin exécuter autre chose que des dégâts plats : il sait maintenant appliquer un petit sous-ensemble `modifyStats` déterministe sur `attack`, `defense`, `specialAttack`, `specialDefense`.

Mais le constat important, et franchement moins flatteur, est celui-ci :

**post-M8, le pipeline de données est plus avancé que le moteur de combat lui-même, et le bridge runtime -> battle reste encore partiellement trompeur par perte de sémantique, même s’il refuse déjà honnêtement beaucoup de cas hors scope.**

Ce qui est réellement vrai aujourd’hui :

- `PokemonMove` sait exprimer beaucoup plus de vérité que le moteur n’en exécute ;
- le runtime charge cette vérité proprement ;
- le bridge en exécute un petit sous-ensemble ;
- il refuse déjà explicitement beaucoup de familles hors scope (`applyStatus`, `multiHit`, `drain`, `weather`, `accuracy < 100`, etc.) ;
- mais il détruit encore silencieusement ou ignore des dimensions importantes comme :
  - `priority`
  - `critRatio`
  - `pp`
  - le vrai `target`
  - le `type`
  - les vraies stats offensives/défensives
- et le moteur n’a toujours ni queue d’actions, ni seam RNG, ni vraie précision, ni système de statut, ni side/field state, ni switch pipeline.

Le point de vérité le plus important de cet audit est donc :

**le prochain découpage utile ne doit plus être “par familles de moves”, mais “par couches moteur”.**

Si on continue en mode :

- “supportons tel move”
- “ouvrons telle famille d’effets”

avant d’avoir fermé :

- le contrat battle réel,
- le vrai snapshot de stats,
- la queue d’actions,
- le pipeline hit/accuracy,
- l’état status/field/side,

on va retomber dans le même piège : transporter beaucoup de vérité côté runtime pour finir par l’écraser au dernier moment.

Verdict net :

- **pas besoin d’un nouveau lot d’audit avant d’agir** : cet audit joue ce rôle ;
- **oui, il faut lancer un vrai lot code ensuite** ;
- mais ce lot ne doit pas être “M9 = nouvelle famille de moves” ;
- il doit être un lot de **fondation moteur**, centré sur le contrat battle honnête et les vraies couches manquantes.

## 2. Pré-gates exécutés avant audit + résultats

### 2.1. Battle package

Commande exécutée :

```bash
cd packages/map_battle && /opt/homebrew/bin/dart test
```

Résultat :

- vert
- `All tests passed!`

Commande exécutée :

```bash
cd packages/map_battle && /opt/homebrew/bin/dart analyze
```

Résultat :

- vert
- `No issues found!`

### 2.2. Runtime battle-related

Commande exécutée :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart
```

Résultat :

- vert
- `All tests passed!`

Commande exécutée :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub
```

Résultat :

- rouge préexistant au sens “package entier non vert”
- mais **pas** rouge battle/moves spécifique
- le retour contient surtout :
  - des `info` de lints historiques ;
  - des warnings `invalid_dependency` liés aux `path dependencies` du package ;
  - plusieurs remarques hors seam battle.

Classification honnête du pré-gate :

- **tests battle/runtime ciblés : verts**
- **`map_battle` analyze : vert**
- **`map_runtime` analyze global : rouge préexistant, large, non spécifique au chantier battle post-M8**

## 3. État initial audité réel

### 3.1. Côté données canoniques

Le modèle `PokemonMove` dans `packages/map_core` est déjà substantiel.

Il porte réellement :

- identité :
  - `id`
  - `name`
  - `names`
  - `generation`
  - `source`
- combat de base :
  - `type`
  - `category`
  - `target`
  - `basePower`
  - `accuracy`
  - `pp`
  - `noPpBoosts`
  - `priority`
  - `critRatio`
- métadonnées :
  - `flags`
  - `shortDescription`
  - `description`
  - `engineSupportLevel`
  - `unsupportedReasons`
  - `sourceRefs.showdownMoveId`
  - `sourceRefs.showdownHooksPresent`
- effets structurés :
  - `fixedDamage`
  - `multiHit`
  - `applyStatus`
  - `applyVolatileStatus`
  - `modifyStats`
  - `heal`
  - `drain`
  - `recoil`
  - `setWeather`
  - `setTerrain`
  - `setPseudoWeather`
  - `selfSwitch`
  - `forceSwitch`
  - `breakProtect`
  - `requireRecharge`
  - `chargeThenStrike`
  - `setSideCondition`
  - `setSlotCondition`

Point important :

- le modèle canonique est **beaucoup plus riche** que le moteur battle ;
- ce n’est pas un problème en soi ;
- c’est même normal ;
- le problème apparaît quand le bridge battle accepte un move alors qu’il ne sait pas honnêtement préserver les dimensions qui comptent.

### 3.2. Côté convertisseur / seed / vérité projet

Le convertisseur Showdown dans `map_editor` :

- construit bien de vrais `PokemonMove` ;
- matérialise `engineSupportLevel`, `unsupportedReasons`, `showdownHooksPresent` ;
- mappe déjà beaucoup de familles d’effets structurés ;
- fait le vrai boulot de “source d’import -> forme canonique”.

Le seed embarqué `pokemon_moves_bootstrap_seed.dart` :

- est **curaté**, pas complet ;
- contient 22 moves ;
- dont 17 entrées par défaut `structuredSupported` ;
- et 5 entrées `catalogOnly`.

Le seed est donc utile, mais il ne constitue pas du tout une preuve que le moteur sait exécuter 17 moves de manière honnête.

### 3.3. Côté runtime

`map_runtime` est aujourd’hui propre sur l’architecture de chargement :

- `RuntimeMoveCatalogLoader` charge strictement le catalogue canonique ;
- `RuntimePokemonSpeciesLoader` charge strictement les espèces ;
- `RuntimePokemonLearnsetLoader` charge strictement les learnsets ;
- `RuntimeBattleCombatantSeedBuilder` assemble les combattants runtime ;
- `RuntimeBattleSetupMapper` orchestre ;
- `RuntimeBattleMoveBridge` décide ce qui peut être projeté honnêtement vers `map_battle`.

Autrement dit :

- le runtime n’est plus le vrai point faible principal ;
- il est même plutôt en avance sur `map_battle` sur la qualité des seams.

### 3.4. Côté battle

`map_battle` reste un moteur 1v1 séquentiel très borné.

Ce qu’il fait vraiment :

- crée une session immutable ;
- expose des choix joueur ;
- résout un tour en “joueur d’abord, ennemi ensuite si vivant” ;
- gère `runaway` ;
- gère `captured` comme outcome immédiat ;
- gère `victory` / `defeat` ;
- applique des dégâts très simplifiés ;
- applique des changements d’étages de stats déterministes ;
- scale les dégâts standards avec les stages `attack/defense/specialAttack/specialDefense`.

Ce qu’il ne fait toujours pas :

- aucune vraie queue d’actions ;
- aucun ordre basé sur `priority` ;
- aucun ordre basé sur `speed` ;
- aucun tie-break ;
- aucun RNG ;
- aucune précision réelle ;
- aucun PP ;
- aucun crit ;
- aucun type chart ;
- aucun STAB ;
- aucune immunité ;
- aucun status ;
- aucun volatile ;
- aucun state `field` / `side` ;
- aucun switch ;
- aucun résiduel fin de tour ;
- aucun multi-hit ;
- aucun drain/recoil/heal battle ;
- aucune météo/terrain/pseudo-weather ;
- aucune side condition / slot condition.

## 4. Ce qui a réellement été accompli jusqu’à M8

### 4.1. Ce qui est réellement gagné

De M1 à M8, le repo a réellement gagné ceci :

1. une source de vérité canonique des moves dans `map_core` ;
2. un convertisseur Showdown sérieux côté `map_editor` ;
3. une lecture canonique vs legacy durcie côté éditeur ;
4. un seed bootstrap moves canonique ;
5. un runtime strict de chargement du canonique ;
6. des loaders runtime spécialisés pour `moves`, `species`, `learnsets` ;
7. un builder runtime de seeds de combattants ;
8. un premier bridge runtime -> battle explicite ;
9. un vrai petit sous-ensemble battle exécutable :
   - dégâts standards simplifiés
   - `modifyStats` déterministe sur un sous-ensemble de stats

### 4.2. Ce qui n’a PAS été accompli malgré l’impression possible donnée par la chaîne

Le repo n’a pas encore un vrai “moteur Pokémon-like” riche.

Il n’a pas encore :

- un contrat battle fidèle aux dimensions canoniques importantes ;
- un état de combattant suffisamment riche ;
- un scheduler ;
- un hit pipeline ;
- un damage pipeline proche de Pokémon ;
- un système d’effets d’état ;
- un système de field/side conditions ;
- un pipeline de switch/faint/residual.

En pratique :

- M1 à M7 ont surtout réglé la **plomberie de vérité de données** ;
- M8 a réglé **une première tranche exécutable** ;
- mais cette tranche reste plus étroite que ce qu’un lecteur rapide des reports pourrait croire.

### 4.3. Les deux trous de vérité les plus importants après M8

#### Trou 1 — le bridge battle accepte encore certains moves dont des dimensions clés sont perdues

Exemples concrets :

- `priority` est transporté en canonique, mais pas dans `BattleMoveData` ;
- `critRatio` est transporté en canonique, mais pas dans `BattleMoveData` ;
- `pp` est transporté en canonique, mais pas dans `BattleMoveData` ;
- `type` est transporté en canonique, mais pas dans `BattleMoveData` ;
- `target` est transporté en canonique, mais pas dans `BattleMoveData`.

Conséquence :

- un move `structuredSupported` peut encore passer le bridge alors qu’une partie non neutre de sa sémantique est détruite ;
- le problème n’est **pas** que le bridge laisse tout passer : il refuse déjà beaucoup d’effets et de cas d’accuracy ;
- le problème est qu’il accepte encore des moves pour lesquels certaines dimensions non transportées comptent réellement ;
- c’est déjà faux pour des moves qui jouent sur `critRatio` ;
- c’est faux dès qu’un move dépend d’un `priority != 0` ;
- c’est faux pour le `pp` dès qu’on veut parler d’exécution combat honnête au-delà d’un simple échange de dégâts ;
- le `target` est structurellement perdu, même si en 1v1 singles la plupart des cas aujourd’hui acceptés restent de facto corrects.

#### Trou 2 — le moteur ne possède pas encore les couches qui permettraient d’ouvrir proprement les familles suivantes

Sans :

- queue,
- vitesse,
- RNG,
- précision,
- état de statut,
- field/side state,

la plupart des prochaines familles de moves ne sont pas “un peu absentes”.
Elles sont **structurellement impossibles à supporter honnêtement**.

## 5. Matrice de support réelle post-M8

| Famille / couche | Modèle canonique | Convertisseur | Seed / runtime loading | Bridge runtime -> battle | Moteur battle | Confiance | Blocage principal | Dépendances à débloquer |
|---|---|---|---|---|---|---|---|---|
| Standard damage flow | oui | oui | oui | partiel | partiel | élevée | le bridge refuse déjà beaucoup de cas hors scope mais perd encore `type`, `priority`, `critRatio`, `target`, `pp`; le moteur n’a pas de vraies stats offensives/défensives ni type chart | contrat battle plus riche, snapshot de stats, pipeline dégâts |
| `modifyStats` déterministe atk/def/spa/spd | oui | oui | oui | oui | oui | élevée | sous-ensemble très borné | contrat actuel suffisant pour ce slice |
| `modifyStats` déterministe speed | oui | oui | oui | non | non | élevée | aucune vitesse battle | queue d’actions, speed state |
| `modifyStats` déterministe accuracy/evasion | oui | oui | oui | non | non | élevée | aucune précision battle | RNG + hit pipeline |
| `modifyStats` probabiliste | oui | oui | oui | non | non | élevée | absence de RNG | PRNG + secondaries pipeline |
| `applyStatus` déterministe | oui | oui | oui | non | non | élevée | pas de système de status | état status + setStatus + write-back |
| `applyStatus` probabiliste | oui | oui | oui | non | non | élevée | pas de status, pas de RNG | idem + PRNG |
| `applyVolatileStatus` | oui | oui | oui | non | non | élevée | pas de volatiles | état volatile + hooks |
| `multiHit` | oui | oui | oui | non | non | élevée | pas de boucle hit/résolution multi-coup | action/hit pipeline + RNG |
| `fixedDamage` | oui | oui | oui | non | non | élevée | pas de branche dégâts fixe distincte | damage pipeline plus riche |
| `heal` | oui | oui | oui | non | non | élevée | pas de move execution heal | hit/effect pipeline |
| `drain` | oui | oui | oui | non | non | élevée | dépend du vrai damage dealt | damage pipeline + heal application |
| `recoil` | oui | oui | oui | non | non | élevée | dépend du vrai damage dealt / self-damage | damage pipeline + self-damage |
| `setWeather` | oui | oui | oui | non | non | élevée | pas de `field` state | field state + residual hooks |
| `setTerrain` | oui | oui | oui | non | non | élevée | pas de `field` state | field state + effect listeners |
| `setPseudoWeather` | oui | oui | oui | non | non | élevée | pas de `field` state | field state + effect listeners |
| `setSideCondition` | oui | oui | oui | non | non | élevée | pas de `side` state | side state + switch pipeline |
| `setSlotCondition` | oui | oui | oui | non | non | élevée | pas de slot state | side/slot state + switch pipeline |
| `selfSwitch` | oui | oui | oui | non | non | élevée | pas de switch flow | queue + switch pipeline |
| `forceSwitch` | oui | oui | oui | non | non | élevée | pas de switch flow | queue + switch pipeline |
| `requireRecharge` | oui | oui | oui | non | non | élevée | pas d’état “must recharge” | volatile/status-like action lock |
| `chargeThenStrike` | oui | oui | oui | non | non | élevée | pas de queue ni d’état de charge | queue + volatile/state |
| `breakProtect` | oui | oui | oui | non | non | élevée | pas de système de protection | hit pipeline + protect state |
| `priority` | oui | oui | oui | non (ignoré) | non | élevée | `BattleMoveData` ne transporte pas `priority`, moteur sans queue | queue + contrat battle |
| `accuracy` | oui | oui | oui | partiel | non | élevée | le bridge refuse `<100`, mais ne l’exécute pas | PRNG + hit pipeline |
| `crit` | oui | oui | oui | non (ignoré) | non | élevée | `critRatio` perdu au handoff | contrat battle + damage pipeline |
| `PP` | oui | oui | oui | non (ignoré) | non | élevée | `BattleMoveData` n’a pas de PP | contrat battle + state mutation |
| `speed order` | n/a côté move seul | n/a | partiel via espèces/niveaux seulement | non | non | élevée | aucune speed battle, aucun scheduler | stats snapshot + queue |
| `target` / targeting | oui | oui | oui | partiel | partiel | moyenne | le bridge ne transporte pas `target`; en 1v1 certains cas restent de facto corrects, mais pas honnêtes en général | contrat battle + target resolution |
| `switch flow` | partiel | n/a | partiel | non | non | élevée | trainer = premier membre uniquement, pas de réserve active | queue + switch pipeline |
| `residual / end of turn` | non utile côté modèle move seulement | partiel via hooks convertis en raisons | n/a | non | non | élevée | aucune phase résiduelle | field/side/status systems + queue |
| `abilities / items` en combat | hors modèle move | n/a | partiel via species/party bag | non | non | élevée | battle state trop pauvre, pas d’event system | state + hooks/event model |

Lecture nette de la matrice :

- la chaîne données/runtime est déjà bien plus avancée que le moteur ;
- le vrai goulot n’est pas “exprimer les moves” ;
- le vrai goulot est “avoir les couches moteur qui rendent ces moves exécutablement honnêtes”.

## 6. Comparaison utile avec Showdown

### 6.1. Ce que Showdown a réellement comme couches

En relisant `battle.ts`, `battle-actions.ts`, `battle-queue.ts`, `pokemon.ts`, `dex-moves.ts` et `data/moves.ts`, les couches structurantes réelles sont :

1. **Battle core**
   - état global
   - PRNG
   - sides
   - field
   - queue
   - event dispatch
2. **Battle queue**
   - ordonnancement par ordre / priority / speed / tie-break
   - move / switch / residual / beforeTurn / runSwitch / etc.
3. **Battle actions**
   - `runMove`
   - `useMove`
   - hit pipeline
   - secondaries
   - force switch
   - recoil
   - drain
4. **Pokemon runtime state**
   - stats stockées
   - boosts
   - status
   - volatiles
   - item
   - ability
   - PP par move
5. **Effect / condition model**
   - conditions de status
   - field effects
   - side conditions
   - slot conditions
   - callbacks/hook methods
6. **Contenu data-driven**
   - `data/moves.ts`
   - `data/conditions.ts`
   - etc.

### 6.2. Ce que nous avons déjà, en plus petit

Nous avons déjà :

- un modèle de move canonique data-driven ;
- un bridge runtime -> battle explicite ;
- un battle core pur et immutable ;
- une séparation runtime / battle plutôt saine ;
- une première exécution battle réelle pour :
  - dégâts standards simplifiés
  - `modifyStats` déterministe

### 6.3. Ce qui manque encore complètement ou presque complètement

Par rapport à Showdown, il manque encore les couches suivantes :

- une vraie queue d’actions ;
- un vrai state de battler avec stats/PP/status/volatiles ;
- un vrai field state ;
- un vrai side state ;
- un vrai hit pipeline ;
- un vrai damage pipeline ;
- un seam PRNG battle ;
- un switch pipeline ;
- une phase résiduelle ;
- tout début d’event model ou de points de résolution structurés.

### 6.4. Le vrai enseignement Showdown utile pour ce repo

Le repo local valide exactement la même leçon que l’analyse Showdown :

**la suite doit se faire par couches moteur, pas par mouvements “à la carte”.**

Pourquoi :

- `applyStatus` sans state status = faux support ;
- `Trick Room` sans queue/speed = faux support ;
- `Stealth Rock` sans side state ni switch = faux support ;
- `Thunderbolt` avec secondaries sans RNG = faux support ;
- `Solar Beam` sans état de charge ni scheduler = faux support.

## 7. Analyse des vrais manques architecturaux

### 7.1. Le contrat battle est encore trop pauvre

`BattleMoveData` et `BattleMove` sont encore trop pauvres pour être honnêtes au-delà du slice M8.

Ils ne portent pas :

- `type`
- `target`
- `accuracy`
- `pp`
- `priority`
- `critRatio`
- `flags`

Or ces dimensions ne sont pas “cosmétiques”.
Elles changent l’exécution.

Conséquence :

- le bridge doit soit les transporter,
- soit refuser les moves qui en dépendent,
- et aujourd’hui il le fait encore incomplètement :
  - il refuse déjà explicitement beaucoup d’effets hors scope ;
  - mais il laisse encore passer des moves pour lesquels `priority`, `critRatio` ou `pp` ne sont pas neutres.

### 7.2. L’état du combattant est encore trop pauvre

Nuance importante : `BattleCombatant` porte déjà plus que le strict minimum historique.

Il transporte bien :

- `currentHp`
- `maxHp`
- `abilityId`
- `statStages`

Mais ce qui manque encore est justement ce qui rendrait le moteur honnête au-delà du slice actuel :

- types
- vraies stats offensives / défensives / speed
- status principal
- volatiles
- PP des moves
- item state exploitable
- ability behavior, même si `abilityId` est déjà présent comme donnée inerte

Conséquence :

- même le standard damage flow reste très loin d’un combat Pokémon honnête ;
- `physical` et `special` ne changent réellement quelque chose qu’à travers les stages temporaires, pas via de vraies stats de base ;
- l’ability est aujourd’hui transportée, mais elle n’a aucun effet moteur.

### 7.3. Il n’existe pas encore de vrai scheduler

Le moteur résout encore :

1. joueur
2. ennemi si vivant

Il n’y a pas :

- `priority`
- `speed`
- speed tie
- sous-actions
- switch queue
- residual queue

Conséquence :

- `priority` est actuellement une donnée chargée par le runtime mais morte au battle ;
- `speed` ne peut pas exister honnêtement ;
- `Trick Room` est impossible sans mensonge ;
- `switch` ne peut pas être correctement branché.

### 7.3.b. Le moteur battle reste dépendant du runtime comme point d’entrée honnête

`map_battle` n’est pas intrinsèquement aussi strict que le runtime.

Exemples concrets :

- si le bridge runtime était contourné, un move à `power > 0` sans catégorie explicite retomberait sur `physical` via `BattleMove.resolvedCategory` ;
- si `currentHp` n’est pas fourni, `BattleSession.create` initialise le combattant à `maxHp` ;
- `BattlePhase.resolving` existe dans l’état mais n’est pas réellement utilisé comme vraie phase distincte.

Ce n’est pas un bug immédiat dans le pipeline actuel, parce que le runtime est bien l’unique point d’entrée sérieux.
Mais cela veut dire que l’honnêteté battle repose encore largement sur la discipline du bridge.

### 7.4. Il n’existe pas encore de hit pipeline

Le moteur n’a pas encore les marches nécessaires pour :

- can act
- target resolution
- immunity
- accuracy
- protect
- hit / miss
- secondary application

Conséquence :

- ouvrir `applyStatus`, `breakProtect`, `multiHit`, `chargeThenStrike` ou `requireRecharge` maintenant serait très risqué ;
- on rouvrirait le même noyau à chaque fois.

### 7.5. Il n’existe pas encore de state field/side

Sans :

- weather
- terrain
- pseudoWeather
- side conditions
- slot conditions

les moves de contrôle global resteront forcément `catalogOnly` ou refusés.

### 7.6. Le runtime est plus propre que le moteur

C’est un constat contre-intuitif mais important.

Aujourd’hui :

- `map_runtime` a déjà les bons seams ;
- `map_battle` n’a pas encore les bonnes couches.

Donc la suite ne doit pas chercher un nouveau refactor runtime massif.
Le goulot est désormais clairement dans `map_battle` et dans le contrat runtime -> battle.

### 7.7. Le blueprint local est utile, mais dangereux s’il devient un deuxième moteur

`plan battle engine/logique_metier_battle_engine.dart` a plusieurs bonnes intuitions :

- snapshot de stats ;
- `BattleMoveBlueprint` plus riche ;
- `BattleRulesProfile` ;
- queue ;
- PRNG seed ;
- pipeline de turn/hit/damage.

Mais il n’est **pas branché**.

Le risque post-audit serait :

- de prendre ce blueprint comme un nouveau terrain de jeu ;
- et de fabriquer une deuxième implémentation parallèle au lieu de migrer `map_battle`.

La bonne lecture de ce fichier est :

- **source d’idées et de découpage**
- pas **nouveau noyau à coder à côté**.

## 8. Critique explicite de la roadmap actuelle

### 8.1. Est-ce que les anciens futurs “M9 / M10 / M11 / M12” ont encore du sens ?

**Partiellement seulement.**

Ils ont du sens si :

- on garde leur numérotation comme repère de séquence ;
- mais **on recadre complètement leur contenu**.

Ils n’ont plus de sens si :

- ils restent pensés comme “support de familles de moves” ;
- ou comme une simple continuation linéaire des familles de données vers l’exécution.

Après M8, le vrai découpage utile n’est plus :

- “supportons `applyStatus`”
- puis “supportons `weather`”
- puis “supportons `switch`”

mais :

- “ajoutons la couche moteur qui rend ensuite ces familles supportables”.

### 8.2. Est-ce que la phase F recalée / la logique locale par couches est mieux pensée ?

**Oui, nettement.**

Le plan local et le blueprint montrent une direction plus saine :

- enrichissement du contrat de combat ;
- snapshot de stats ;
- queue ;
- hit pipeline ;
- damage pipeline ;
- puis états/effets.

C’est plus cohérent avec :

- Showdown ;
- le repo local ;
- les limitations post-M8.

### 8.3. Le vrai découpage post-M8 doit-il être par familles, par couches, ou mixte ?

**Réponse recommandée : par couches moteur, avec des familles de moves seulement comme preuves de couverture à l’intérieur de ces couches.**

Concrètement :

- on ne fait pas un lot top-level “moves status” ;
- on fait un lot “state status + hit pipeline minimum”, et `thunder_wave` devient un test de preuve ;
- on ne fait pas un lot top-level “weather” ;
- on fait un lot “field/side state”, et `rain_dance` / `trick_room` deviennent des preuves de couverture.

Pourquoi c’est la bonne réponse :

- ça évite de reconstruire la même plomberie à chaque lot ;
- ça évite de mentir sur le support ;
- ça garde un seul pipeline ;
- c’est aligné avec Showdown et avec le plan local.

## 9. Critique explicite du prompt reçu

### 9.1. Ce qui est bon dans le prompt

- il impose un audit repo-grounded ;
- il interdit les refactors cachés ;
- il impose les pré-gates ;
- il demande de challenger la roadmap existante ;
- il demande une recommandation nette au lieu d’un audit flou.

### 9.2. Ce qui est discutable

- la liste Showdown du prompt mentionne `pokemon-showdown-master/sim/moves.ts`, qui n’existe pas dans ce repo local ; la vraie source structurante de contenu move est `pokemon-showdown-master/data/moves.ts` ;
- le prompt pousse vers un “audit massif” potentiellement trop large : si on le suivait au pied de la lettre sans recadrage, on tomberait vite dans la lecture exhaustive décorative au lieu de la lecture structurante ;
- l’exigence “brutalement honnête” peut pousser à la posture, alors que le bon audit doit surtout être précis.

### 9.3. Ce qui aurait été dangereux si suivi aveuglément

- croire que “relire énormément de fichiers” suffit à produire un bon cadrage ;
- mélanger dans une même conclusion :
  - pipeline amont des données,
  - support runtime,
  - support battle,
  - et backlog futur,
  sans distinguer les couches ;
- continuer à raisonner implicitement en “familles de moves” alors que le repo crie déjà “couches moteur”.

### 9.4. Ce que j’ai recadré volontairement

- j’ai remplacé `sim/moves.ts` par `data/moves.ts` pour la source de contenu ;
- j’ai centré l’analyse Showdown sur les couches utiles :
  - `battle.ts`
  - `battle-actions.ts`
  - `battle-queue.ts`
  - `pokemon.ts`
  - `dex-moves.ts`
  - `data/moves.ts`
- j’ai traité la suite comme un problème de couches moteur, pas comme une check-list de familles de moves.

### 9.5. Pourquoi ce recadrage est meilleur pour ce repo réel

Parce que le repo a déjà :

- une bonne plomberie de données ;
- un bon runtime loader/bridge de base ;
- et un moteur battle encore mince.

Le vrai levier n’est donc pas de rajouter des familles de moves les unes après les autres.
Le vrai levier est d’arrêter de perdre ou de simplifier abusivement la vérité au niveau du contrat battle et du pipeline de résolution.

## 10. Recommandation de suite

### 10.1. Recommandation nette

**Oui, il faut lancer un vrai lot code tout de suite.**

Mais :

- pas un lot “support d’une nouvelle famille de moves” ;
- pas un lot “M8-bis géant” ;
- pas un lot “refonte totale map_battle”.

Le prochain lot doit être :

**un lot de fondation moteur centré sur le contrat battle honnête et les prérequis structurels.**

### 10.2. Recommandation concrète

Le prochain lot recommandé est :

## `M9 — Hardening explicite du bridge battle + contrat battle minimal honnête`

But concret :

- arrêter immédiatement de perdre silencieusement des dimensions canoniques non neutres au handoff ;
- enrichir le contrat `BattleMoveData` / `BattleSetup` uniquement là où le moteur ou le lot suivant va réellement consommer la donnée ;
- durcir le bridge pour qu’il refuse explicitement ce qu’il ne sait toujours pas exécuter honnêtement.

Concrètement, ce lot doit faire au minimum :

- refuser les moves où `priority != 0` tant qu’aucune queue n’existe ;
- refuser les moves où `critRatio` non neutre compte vraiment tant qu’aucun crit n’existe ;
- refuser les moves où `accuracy` non triviale compte vraiment tant que le hit pipeline n’existe pas ;
- refuser plus explicitement les cas où `target` sort du 1v1 singles réellement supporté ;
- préparer, mais sans sur-transport gratuit, l’enrichissement du contrat battle pour le lot suivant.

Ce lot ne doit **pas** essayer de résoudre à lui seul :

- la queue ;
- le snapshot de stats complet ;
- l’accuracy ;
- les crits ;
- la formule de dégâts v2.

Sinon il redeviendra un gros lot flou.

### 10.3. Alternative plus agressive mais encore défendable

Si après découpage détaillé il s’avère que l’enrichissement minimal du contrat battle et le snapshot de stats sont indissociables sans double travail, l’alternative acceptable est :

## `M9 élargi — Hardening du bridge + contrat battle + snapshot de stats v1`

Je la considère plausible, mais plus risquée en taille.

Le danger si on part directement là-dessus est de faire semblant de traiter aussi :

- priorité ;
- vitesse ;
- accuracy ;
- crit ;
- type chart ;

alors que ces couches n’auraient pas encore de pipeline complet derrière.

## 11. Proposition de nouveaux lots / nouveau découpage

### 11.1. Découpage recommandé

Je recommande de repartir sur ce découpage post-M8 :

### `M9 — Hardening du bridge + contrat battle minimal honnête`

Objectif :

- fermer les trous de vérité encore présents dans le bridge ;
- enrichir le contrat battle seulement autant que nécessaire pour éviter les pertes sémantiques déjà identifiées ;
- préparer proprement les lots suivants sans faire semblant d’exécuter plus que le moteur ne sait faire.

Dépendances :

- aucune nouvelle infra externe ;
- réutilise les seams runtime existants.

Ce qu’il ne faut surtout pas faire :

- embarquer dès ce lot toute la formule de dégâts v2 ;
- ouvrir status/weather/switch ;
- créer un DTO battle miroir géant de `PokemonMove`.

### `M10 — Snapshot de stats + damage contract v1`

Objectif :

- introduire les vraies stats minimales nécessaires côté combattant ;
- donner un sens réel à `physical` / `special` au-delà des seuls stages ;
- préparer la future consommation de `type`, puis éventuellement une damage formula v1 plus honnête.

Pourquoi je le mets séparément :

- c’est un changement de contrat/state substantiel ;
- le coller à `M9` crée un lot plus gros et plus risqué ;
- il ne débloque pas encore, à lui seul, priorité/accuracy/crit.

Ce qu’il ne faut surtout pas faire :

- prétendre déjà supporter type chart complet, STAB, immunités, crits et accuracy dans le même lot.

### `M11 — Queue d’actions + vitesse/priorité + seam PRNG`

Objectif :

- introduire un scheduler battle réel ;
- gérer :
  - `priority`
  - `speed`
  - speed ties déterministes
  - point d’entrée PRNG battle
- préparer proprement accuracy, multi-hit, switch, residual.

Dépendances :

- M9 terminé ;
- idéalement M10 si la vitesse vit dans le snapshot de stats ;
- `priority` transporté jusqu’au battle.

Ce qu’il ne faut surtout pas faire :

- ouvrir encore doubles/triples ;
- essayer de brancher déjà toutes les actions Showdown.

### `M12 — Hit pipeline + accuracy / immunités / PP + crits`

Objectif :

- séparer le move pipeline en vraies marches :
  - can act
  - target resolution minimal
  - hit check
  - immunités minimales
  - application du hit
- introduire PP réels ;
- introduire accuracy honnête ;
- introduire crits honnêtes si le contrat battle les transporte correctement.

Dépendances :

- M9
- M10
- M11

Ce qu’il ne faut surtout pas faire :

- ouvrir statuts complets et field state en même temps.

### M13 — Status / volatile minimum + `applyStatus` honnête

Objectif :

- ajouter un vrai status non volatil minimal ;
- ajouter un petit état volatile si nécessaire ;
- ouvrir enfin `applyStatus` honnêtement ;
- garder encore hors scope weather/terrain/side conditions si la couche field/side n’est pas prête.

Dépendances :

- M9
- M10
- M11
- M12

Ce qu’il ne faut surtout pas faire :

- ouvrir tout le paquet weather/terrain/stealth rock dans le même lot ;
- mélanger status, switch pipeline et résiduels sans state adéquat.

### `M14 — Field / side state + switch pipeline + residuals`

Objectif :

- field state
- side conditions
- pseudo-weather
- switch/faint queue
- résiduels fin de tour

Pourquoi je l’isole :

- c’est une vraie couche à part ;
- elle débloque `rain_dance`, `trick_room`, `stealth_rock`, `healing_wish`, `forceSwitch`, `selfSwitch` ;
- elle serait trop grosse si on la fusionne honnêtement dans M12.

### 11.2. Pourquoi cet ordre est le bon

Parce qu’il suit le vrai graphe de dépendances :

1. hardening du bridge + contrat battle minimal honnête
2. snapshot de stats + damage contract v1
3. queue / speed / PRNG
4. hit + PP + accuracy + crits
5. statuses
6. field/side/switch/residual

Et non :

1. choisir des familles de moves au hasard
2. découvrir qu’il manque toujours la même plomberie
3. la recoder à chaque lot

## 12. Risques / pièges

### 12.1. Repartir par familles de moves

C’est le piège principal.

Exemples :

- `thunder_wave` avant status state
- `trick_room` avant queue/speed
- `stealth_rock` avant side state/switch
- `solar_beam` avant charge state

Tout cela produirait du faux support.

### 12.2. Transformer le blueprint local en stack parallèle

`plan battle engine/logique_metier_battle_engine.dart` a de bonnes idées.
Mais si on commence à le “faire vivre à côté”, on crée exactement le genre de duplication qu’on veut éviter.

### 12.3. Enrichir le bridge sans enrichir l’honnêteté

Transporter plus de champs sans durcir les gates ne suffit pas.
Cela peut même aggraver le problème en donnant une illusion de maturité supplémentaire.

### 12.4. Laisser passer des moves “structurally supported” mais battle-faux

Post-M8, c’est déjà le principal risque concret :

- `engineSupportLevel=structuredSupported` ne veut pas dire “battle-ready” ;
- le bridge doit rester le lieu qui tranche honnêtement cette différence ;
- aujourd’hui il le fait encore incomplètement.

### 12.5. Confondre exécution et observabilité

Post-M8, `modifyStats` est réellement exécuté par le moteur.

En revanche :

- `BattleMoveExecution` ne transporte encore que `move` et `damage` ;
- l’overlay runtime ne montre donc que le nom du move et des dégâts.

Ce n’est pas un faux support moteur.
Mais c’est une dette d’observabilité qu’il ne faut pas confondre avec de l’exécution complète.

### 12.5. Sous-estimer la dette du standard damage flow actuel

Le standard damage flow ne “régresse pas”, mais il reste très approximatif :

- pas de vraie stat offensive/défensive ;
- pas de type chart ;
- pas de STAB ;
- pas de crit ;
- pas de précision ;
- pas de PP ;
- pas d’ordre d’action honnête.

Il ne faut donc pas prendre le vert actuel des tests comme preuve d’un moteur déjà “presque Pokémon”.

## 13. Commandes réellement exécutées

### 13.1. État Git / contexte

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
rg --files -g 'AGENTS.md'
```

### 13.2. Pré-gates

```bash
cd packages/map_battle && /opt/homebrew/bin/dart test
cd packages/map_battle && /opt/homebrew/bin/dart analyze
cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_move_catalog_loader_test.dart \
  test/runtime_pokemon_species_loader_test.dart \
  test/runtime_pokemon_learnset_loader_test.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub
```

### 13.3. Lecture / recherche ciblées

Commandes significatives réellement exécutées :

```bash
wc -l <fichiers battle/runtime/core/editor/plan>
rg -n "<motifs battle/runtime/moves>" packages/map_battle/lib/src ...
sed -n '<plages>' packages/map_battle/lib/src/battle_move.dart
sed -n '<plages>' packages/map_battle/lib/src/battle_setup.dart
sed -n '<plages>' packages/map_battle/lib/src/battle_state.dart
sed -n '<plages>' packages/map_battle/lib/src/battle_session.dart
sed -n '<plages>' packages/map_battle/lib/src/battle_resolution.dart
sed -n '<plages>' packages/map_runtime/lib/src/application/runtime_move_catalog_loader.dart
sed -n '<plages>' packages/map_runtime/lib/src/application/runtime_pokemon_species_loader.dart
sed -n '<plages>' packages/map_runtime/lib/src/application/runtime_pokemon_learnset_loader.dart
sed -n '<plages>' packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart
sed -n '<plages>' packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
sed -n '<plages>' packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
sed -n '<plages>' packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
sed -n '<plages>' packages/map_core/lib/src/models/pokemon_move.dart
sed -n '<plages>' packages/map_core/lib/src/models/pokemon_move_accuracy.dart
sed -n '<plages>' packages/map_core/lib/src/models/pokemon_move_effect.dart
sed -n '<plages>' packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart
sed -n '<plages>' packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart
sed -n '<plages>' packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
sed -n '<plages>' 'plan battle engine/logique_metier_battle_engine.dart'
sed -n '<plages>' 'plan battle engine/plan-moteur-combat-projet.md'
rg -n "<headings>" reports/phase-moves-m5-runtime-loader-report.md ...
sed -n '<plages>' pokemon-showdown-master/sim/dex-moves.ts
sed -n '<plages>' pokemon-showdown-master/sim/battle.ts
sed -n '<plages>' pokemon-showdown-master/sim/battle-actions.ts
sed -n '<plages>' pokemon-showdown-master/sim/battle-queue.ts
sed -n '<plages>' pokemon-showdown-master/sim/pokemon.ts
rg -n "<motifs>" pokemon-showdown-master/data/moves.ts
```

### 13.4. Vérifications ponctuelles

```bash
ls pokemon-showdown-master/sim/moves.ts pokemon-showdown-master/data/moves.ts ...
python3 - <<'PY'
# comptage simple d'entrées seed
PY
python3 - <<'PY'
# comptage simple des familles d'effets dans convertisseur/seed
PY
```

## 14. Résultats réels analyze/tests

### 14.1. `packages/map_battle`

`dart test` :

- vert
- tous les tests passent

`dart analyze` :

- vert
- `No issues found!`

### 14.2. `packages/map_runtime`

`flutter test` ciblé battle/runtime :

- vert
- tous les tests passent

`flutter analyze --no-pub` :

- rouge package global
- 157 issues
- principalement :
  - infos `prefer_const_*`
  - infos `avoid_relative_lib_imports`
  - warnings `invalid_dependency`
- pas d’indice dans cette sortie d’une casse spécifique du seam post-M8 audité

### 14.3. Interprétation honnête

Ce lot d’audit ne peut pas conclure :

- “tout runtime est vert”

mais peut conclure honnêtement :

- “les tests runtime battle ciblés sont verts”
- “le seam battle/runtime audité fonctionne”
- “le package `map_runtime` dans son ensemble traîne encore des rouges préexistants non spécifiques”.

## 15. État git utile

État avant création du report :

- `git status --short` : vide
- `git diff --stat` : vide
- `git ls-files --others --exclude-standard` : vide

État attendu après création du report :

- un seul fichier nouveau :
  - `reports/phase-battle-post-m8-audit-report.md`

## 16. Retour du sub-agent d’audit/design

Sub-agent utilisé :

- `Volta`

Mission donnée :

- auditer les seams battle/runtime/showdown ;
- challenger le découpage post-M8 ;
- proposer le prochain lot le plus défendable.

Retour utile retenu :

1. le bon découpage post-M8 est **par couches moteur**, pas par familles de moves ;
2. le moteur sait réellement exécuter :
   - 1v1 séquentiel
   - standard damage flow simplifié
   - `modifyStats` déterministe sur un petit sous-ensemble ;
3. le goulot n’est plus `map_runtime` ;
4. le vrai prochain besoin est le **snapshot de stats** et plus largement le contrat battle ;
5. le prompt pousse implicitement vers le mauvais cadrage s’il fait raisonner “familles de moves d’abord”.

Remarque que je retiens seulement partiellement :

- Volta pousse presque directement vers “Lot 3, vrai snapshot de stats”.
- Je suis d’accord sur le fond, mais j’ajoute explicitement que ce lot doit aussi intégrer le **hardening du bridge** sur les dimensions aujourd’hui perdues (`priority`, `critRatio`, `pp`, `target`), sinon on déplacera juste le problème.

## 17. Retour du reviewer séparé

Reviewer utilisé :

- `Maxwell`

Mission demandée :

- relire l’audit final ;
- vérifier qu’il est repo-grounded ;
- chercher les angles morts ;
- vérifier que je n’ai pas avalé le prompt aveuglément ;
- vérifier la cohérence de la recommandation de suite.

### Retour principal du reviewer

Le reviewer (`Maxwell`) a remonté quatre points utiles :

1. le rapport disait trop vite que `BattleCombatant` ne portait pas l’ability state ; en réalité il transporte déjà `abilityId`, ainsi que `currentHp` et `statStages`, mais ces données restent très partiellement exploitées ;
2. la formule “bridge encore mensonger” était trop large ; le bridge refuse déjà explicitement beaucoup de familles hors scope et les moves à `accuracy < 100` ; la vraie faiblesse restante est surtout la perte silencieuse de dimensions non transportées (`priority`, `critRatio`, `pp`, etc.) ;
3. `map_battle` est plus permissif que le rapport ne le disait si le runtime bridge est contourné : fallback `physical` via `resolvedCategory`, fallback `currentHp -> maxHp`, `BattlePhase.resolving` non réellement utilisée ;
4. la recommandation initiale pour `M9` empaquetait trop de couches d’un coup ; elle risquait de refaire un gros lot flou.

Je considère ces quatre remarques comme valides.

## 18. Corrections éventuelles après review

Corrections réellement appliquées après la review :

1. j’ai requalifié le bridge comme **partiellement trompeur par perte de sémantique**, au lieu de le présenter comme globalement mensonger ;
2. j’ai corrigé la section sur `BattleCombatant` pour distinguer :
   - ce qui est déjà transporté (`currentHp`, `abilityId`, `statStages`) ;
   - ce qui manque encore réellement ;
3. j’ai ajouté une section explicite sur la dépendance actuelle de `map_battle` au runtime comme point d’entrée honnête ;
4. j’ai affiné la recommandation post-M8 :
   - `M9` devient un lot plus serré de hardening du bridge + contrat battle minimal honnête ;
   - le snapshot de stats devient une couche distincte (`M10`) ;
   - la queue/vitesse/PRNG, puis accuracy/PP/crits, restent séparées.

## 19. Autocritique finale

### 19.1. Ce qui est solide dans cet audit

- les conclusions sur les seams runtime sont très bien fondées dans le code ;
- la matrice de support est alignée avec ce que le bridge et le moteur font réellement ;
- le diagnostic “par couches moteur, pas par familles” est cohérent avec :
  - le code battle,
  - le runtime,
  - le plan local,
  - Showdown.

### 19.2. Ce qui reste plus fragile

- je n’ai pas relu exhaustivement l’intégralité de `data/moves.ts`, évidemment ;
- certaines lignes de la matrice sont classées à partir de la structure moteur et des rejects explicites, pas d’une preuve testée move par move sur tout le catalogue ;
- l’évaluation du prochain meilleur lot reste une recommandation d’architecture, donc elle garde une part de jugement.

### 19.3. Ce que je n’ai pas pu conclure avec certitude absolue

- le point exact où il sera préférable d’introduire un mini event system, plutôt qu’un pipeline battle plus explicitement codé ;
- si le futur meilleur découpage autour de `M12` doit fusionner accuracy + PP + crits dans un seul lot, ou si PP mérite finalement un micro-lot isolé selon la taille réelle de `M11` ;
- si un micro-lot “M8-ter hardening” vaut le coût organisationnel face à un M9 plus large mais bien cadré.

### 19.4. Ce qui est ma vraie réserve sur ma propre recommandation

Je recommande de partir directement sur un lot de fondation moteur, pas sur une famille de moves.

C’est la bonne direction.

Mais le **sous-découpage exact** entre :

- contrat battle honnête,
- snapshot de stats,
- queue/priorité/vitesse,
- accuracy/PP,

reste encore légèrement discutable.

Je pense néanmoins que cette incertitude porte sur le **bord des lots**, pas sur leur **ordre de dépendance**.

## 20. Annexe avec le contenu complet du fichier texte touché

Le seul fichier texte touché par cette mission est **ce report lui-même** :

- `reports/phase-battle-post-m8-audit-report.md`

Je n’en duplique pas une seconde copie textuelle intégrale dans cette annexe, parce que cela créerait une récursion artificielle : le contenu complet du fichier touché est précisément l’intégralité du présent document.

## 21. Checklist finale obligatoire

- [x] j’ai audité le code réel
- [x] j’ai exécuté les pré-gates
- [x] je n’ai fait aucune écriture Git interdite
- [x] je n’ai modifié aucun code production/test
- [x] je n’ai créé que le report demandé
- [x] j’ai utilisé un sub-agent d’audit/design
- [x] j’ai utilisé un reviewer séparé
- [x] j’ai challengé le prompt
- [x] j’ai challengé la roadmap existante
- [x] je n’ai pas proposé de stack parallèle
- [x] j’ai produit une recommandation nette pour la suite
- [x] mon report est honnête
- [x] mon report est repo-grounded
- [x] mon report contient une autocritique réelle
