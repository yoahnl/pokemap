# Analyse ultra complète des mécaniques de combat Pokémon à partir de Pokémon Showdown

## Objet du document

Ce document sert de base de travail pour reconstruire un moteur de combat Pokémon sérieux dans votre propre stack.

L’objectif n’est pas de copier aveuglément Pokémon Showdown, mais de comprendre :
- ce que Showdown modélise vraiment ;
- comment il découpe la simulation ;
- dans quel ordre les règles sont appliquées ;
- où vivent les mécaniques génériques ;
- où vivent les mécaniques spécifiques aux moves, talents, objets et statuts ;
- comment gérer les variations de génération sans casser le noyau du moteur.

Ce document est volontairement orienté **moteur** et **architecture**, pas seulement “liste de règles”. L’idée est d’en faire un support durable pour votre future roadmap combat.

---

## 1. La leçon principale à retenir

La vraie leçon de Pokémon Showdown n’est pas “le combat Pokémon = une formule de dégâts”.

La vraie leçon est :

**un combat Pokémon est un moteur d’état piloté par une queue d’actions, un système d’événements et des effets attachés à plusieurs niveaux**.

Autrement dit, un vrai moteur Pokémon doit savoir gérer simultanément :
- un état global de combat ;
- des états attachés au terrain ;
- des états attachés aux côtés ;
- des états attachés aux slots ;
- des états attachés aux Pokémon ;
- des états attachés aux moves ;
- des actions ordonnées selon une logique précise ;
- des hooks qui peuvent réécrire ou interrompre une étape de résolution.

Si vous ne modélisez que :
- `species`
- `level`
- `hp`
- `power`

vous n’obtenez pas un moteur Pokémon, vous obtenez un mini-système de duel.

---

## 2. Vue d’ensemble de l’architecture combat de Showdown

Showdown sépare la simulation en plusieurs couches très nettes.

### 2.1 Le noyau d’orchestration

Ce sont les fichiers qui pilotent vraiment le combat :
- `sim/battle.ts`
- `sim/battle-actions.ts`
- `sim/battle-queue.ts`
- `sim/pokemon.ts`
- `sim/field.ts`
- `sim/side.ts`

Rôles :

#### `sim/battle.ts`
C’est le chef d’orchestre.
Il contient :
- la battle elle-même ;
- l’event system ;
- l’ordonnancement ;
- la résolution de nombreux événements globaux ;
- les structures `Battle`, `sides`, `field`, `queue`, `actions`, `prng`.

#### `sim/battle-actions.ts`
C’est la couche qui résout les actions de combat :
- utiliser un move ;
- lancer le pipeline de hit ;
- calculer les dégâts ;
- appliquer les secondaires ;
- switcher ;
- mega évoluer ;
- teracristalliser ;
- gérer les transformations d’action.

#### `sim/battle-queue.ts`
C’est le scheduler des actions.
Il transforme des choix en actions concrètes, les trie et les injecte dans la boucle du tour.

#### `sim/pokemon.ts`
C’est le modèle runtime d’un combattant.
Il contient :
- stats ;
- boosts ;
- status ;
- volatiles ;
- item ;
- ability ;
- types ;
- moveslots ;
- targeting helpers ;
- immunités ;
- logique HP/faint/heal.

#### `sim/field.ts`
C’est le niveau “terrain global” :
- météo ;
- terrain ;
- pseudo-weather.

#### `sim/side.ts`
C’est le niveau “côté joueur / camp” :
- équipe ;
- actifs ;
- side conditions ;
- slot conditions ;
- requests de choix ;
- règles propres au side.

---

### 2.2 La couche “schéma des effets”

Ce sont les fichiers qui définissent **le contrat des mécaniques** :
- `sim/dex-moves.ts`
- `sim/dex-conditions.ts`

Leur rôle est capital.

Ils ne disent pas seulement “un move a un nom et une puissance”.
Ils définissent :
- le type de cible ;
- les flags ;
- les callbacks possibles ;
- les champs de secondaires ;
- les modificateurs de puissance, précision, immunité, type, STAB, etc. ;
- les événements supportés par un effect.

C’est cette couche qui transforme le moteur en moteur **data-driven**.

---

### 2.3 La couche “contenu des mécaniques”

Ce sont les gros fichiers de données :
- `data/moves.ts`
- `data/abilities.ts`
- `data/items.ts`
- `data/conditions.ts`

Ici vivent les comportements concrets.
Par exemple :
- un talent qui modifie la précision ;
- un objet qui bloque une altération de talent ;
- un move qui pose une side condition ;
- un statut qui applique un malus de vitesse ;
- une météo qui change des dégâts.

Showdown n’encode donc pas “tout le combat” dans un seul fichier monolithique.
Il a :
- un noyau,
- un contrat de hooks,
- puis des tables de données riches branchées sur ces hooks.

---

### 2.4 La couche “variantes de génération / mod”

Ce point est extrêmement important.

Showdown ne gère pas les générations seulement avec quelques nombres conditionnels.
Il a aussi une vraie couche d’override :
- `data/mods/gen1/...`
- `data/mods/gen2/...`
- etc.

Cela veut dire qu’une différence de génération peut être :
- une simple variation numérique ;
- une variation de statut ;
- une variation de pipeline ;
- une variation de callback ;
- une variation de script move/condition/item/ability.

C’est un point crucial pour votre propre moteur :
**si vous voulez supporter plusieurs styles de combat, il faut prévoir une vraie stratégie de variantes, pas une pluie de `if (gen === x)` partout.**

---

## 3. Les concepts d’état indispensables à modéliser

Pour refaire votre moteur, il faut poser une hiérarchie d’état claire.

### 3.1 Battle

Le niveau `Battle` doit porter au minimum :
- format / règles ;
- PRNG ;
- field ;
- sides ;
- queue ;
- actions helper ;
- état du tour ;
- événements en cours ;
- active move / active pokemon / active target ;
- logs et éventuellement input log.

Concrètement, `Battle` est le contexte principal de résolution.

### 3.2 Field

Le champ global doit porter :
- météo active ;
- état de la météo ;
- terrain actif ;
- état du terrain ;
- pseudo-weathers.

Il faut traiter le terrain comme un conteneur d’effets globaux temporaires.

### 3.3 Side

Un side doit porter :
- équipe complète ;
- Pokémon actifs ;
- nombre de Pokémon restants ;
- side conditions ;
- slot conditions ;
- flags d’usage (zMoveUsed, dynamaxUsed, etc.) ;
- request actuelle ;
- choix courant.

### 3.4 Pokemon

Le combattant runtime doit porter beaucoup plus que : `speciesId`, `level`, `hp`.

Il faut au minimum prévoir :
- espèce runtime ;
- niveau ;
- HP courants / max HP ;
- stats stockées ;
- boosts ;
- status principal ;
- volatiles ;
- item ;
- ability ;
- nature ;
- moveslots avec PP ;
- types effectifs ;
- flags de combat (fainted, trapped, transformed, terastallized, etc.) ;
- historique utile (lastMove, attackedBy, etc.).

### 3.5 EffectState

C’est un des concepts les plus importants.

Showdown attache des états d’effet à :
- un Pokémon ;
- un side ;
- un slot ;
- le field.

Cet état sert à stocker :
- durée ;
- source ;
- sourceSlot ;
- ordre de création ;
- n’importe quelle donnée utile à un callback futur.

Autrement dit, un `EffectState` n’est pas juste un flag booléen.
C’est la mémoire vivante d’un effet.

---

## 4. Le cœur du moteur : la queue d’actions

Si tu veux identifier le vrai cœur opérationnel du combat Pokémon, c’est ici.

### 4.1 Ce que fait la queue

La queue d’actions prend :
- des choix joueur/IA,
- les transforme en actions concrètes,
- les ordonne,
- puis les exécute dans le bon ordre.

La boucle générale est simple dans son principe :
1. les choix deviennent des actions ;
2. les actions entrent dans la queue ;
3. la queue est triée ;
4. on exécute une action après l’autre ;
5. on recommence.

### 4.2 Une action n’est pas juste “utiliser un move”

Dans Showdown, la queue ne contient pas seulement :
- move
- switch

Elle contient aussi des actions système, par exemple :
- `beforeTurn`
- `beforeTurnMove`
- `residual`
- `runSwitch`
- `megaEvo`
- `runDynamax`
- `terastallize`
- `team`
- `instaswitch`
- `priorityChargeMove`

C’est une leçon majeure :
**la simulation Pokémon n’est pas un simple enchaînement de moves.**
C’est un pipeline d’actions hétérogènes.

### 4.3 L’ordre des actions

Le tri de Showdown repose sur :
1. `order` croissant ;
2. `priority` décroissante ;
3. `speed` décroissante ;
4. `subOrder` croissant ;
5. `effectOrder` croissant.

Ensuite les égalités sont départagées avec le PRNG.

Ce point est fondamental pour votre moteur :
- il faut distinguer l’ordre structurel (`order`) de la priorité de move ;
- il faut distinguer la priorité de combat de l’ordre interne entre effets concurrents ;
- il faut gérer les speed ties proprement et de manière déterministe.

### 4.4 Les résolutions implicites d’un choix

Une commande “move X + mega + tera + max” n’est pas un seul bloc.

La queue résout et injecte automatiquement des sous-actions :
- mega évolution avant move ;
- teracristallisation avant move ;
- callbacks `beforeTurnMove` ;
- priorité spéciale de certaines charges.

Donc, dans votre moteur, un choix utilisateur doit devenir une **intention**, puis être “compilé” en une ou plusieurs actions concrètes.

---

## 5. Le vrai centre nerveux : le système d’événements

C’est **la partie la plus importante** de Showdown.

### 5.1 Pourquoi ce système est si central

Sans event system, vous allez rapidement vous retrouver avec :
- des `if` partout ;
- du code spaghetti ;
- des règles impossibles à faire cohabiter ;
- des talents, objets et statuts qui cassent le pipeline dès qu’ils interagissent.

Le système d’événements permet de dire :
- “quand quelque chose tente de se produire, qui a le droit d’intervenir ?”
- “dans quel ordre ?”
- “qui peut modifier la valeur ?”
- “qui peut bloquer ?”
- “qui peut réagir après coup ?”

### 5.2 Deux fonctions centrales

Showdown tourne autour de deux primitives :
- `singleEvent(...)`
- `runEvent(...)`

#### `singleEvent`
Exécute un handler précis d’un effet donné.
Utilisé quand on sait exactement quel effet on veut appeler.

#### `runEvent`
Cherche tous les handlers pertinents pour un événement donné, les trie, les exécute, propage éventuellement une relay variable, et retourne le résultat final.

### 5.3 La relay variable

C’est une idée essentielle.

Un événement peut transporter une valeur modifiable, par exemple :
- les dégâts ;
- la précision ;
- la puissance ;
- les boosts ;
- l’effectiveness.

Chaque handler peut :
- ne rien faire (`undefined`) ;
- renvoyer une nouvelle valeur ;
- retourner `false` ou `null` pour bloquer / interrompre ;
- retourner une valeur falsy pour arrêter la propagation.

Concrètement, cela donne une architecture très puissante :
- la mécanique de base produit une première valeur ;
- des effets la modifient à la volée ;
- le résultat final sort du pipeline.

### 5.4 Qui peut écouter un événement ?

Showdown permet à de nombreux types d’effets d’écouter :
- abilities ;
- items ;
- statuts ;
- volatiles ;
- side conditions ;
- slot conditions ;
- weather ;
- terrain ;
- pseudoWeather ;
- règles / formats / scripts.

### 5.5 Les préfixes d’écoute

`sim/dex-conditions.ts` montre que les handlers ne sont pas seulement “onX”.
Il existe aussi des préfixes relationnels :
- `onAlly...`
- `onFoe...`
- `onSource...`
- `onAny...`

C’est capital pour un vrai moteur doubles / triples / multi.

### 5.6 Les suppressions de handlers

Un point de finesse très important :
Showdown ne se contente pas de chercher des handlers.
Il sait aussi les **supprimer dynamiquement** du flux si l’effet est neutralisé.

Exemples :
- ability ignorée ;
- item ignoré ;
- weather supprimée par Air Lock-like ;
- status plus présent ;
- effet remplacé ou supprimé entre-temps.

Donc votre moteur devra intégrer la notion :
**un effet enregistré n’est pas forcément un effet encore valide au moment de son déclenchement.**

---

## 6. Le pipeline complet d’un move

C’est la deuxième grande zone critique.

### 6.1 Différence entre “runMove” et “useMove”

Showdown distingue :
- `runMove` : le move comme action choisie dans le tour ;
- `useMove` : l’exécution interne du move lui-même.

Cette distinction est excellente.

#### `runMove`
Gère surtout :
- les conditions de tentative ;
- le PP ;
- les locks ;
- la consommation de ressource ;
- certains effets de haut niveau ;
- le fait que “le Pokémon a tenté d’utiliser le move”.

#### `useMove`
Gère surtout :
- le ciblage effectif ;
- les modifications du move ;
- le pipeline du hit ;
- les dégâts ;
- les secondaires ;
- les effets intrinsèques du move.

Si vous refaites votre moteur, cette séparation est **très saine**.

### 6.2 Étapes haut niveau d’un move

Dans les grandes lignes, un move passe par :
1. validation de la tentative (`BeforeMove`, etc.) ;
2. gestion PP / move lock / état utilisateur ;
3. transformation éventuelle du move (Z, Max, etc.) ;
4. modification cible / type / move ;
5. résolution des cibles ;
6. pipeline de hit ;
7. application dégâts ;
8. application effets primaires ;
9. application secondaires ;
10. effets after-move ;
11. faint / switch / checks de fin.

### 6.3 Les modifications du move avant impact

Avant que le move “frappe”, Showdown laisse des points d’intervention pour :
- `ModifyTarget`
- `ModifyType`
- `ModifyMove`

C’est la bonne architecture.

Cela veut dire qu’un move n’est pas un bloc figé. À l’exécution, il peut être réécrit.

### 6.4 Le pipeline fin du hit

Showdown documente très explicitement les étapes de `trySpreadMoveHit`.

L’ordre conceptuel est :
0. invulnérabilité temporaire (Fly, Dive, Dig, etc.) ;
1. `TryHit` ;
2. immunité de type ;
3. autres immunités spécifiques ;
4. précision ;
5. protections ;
6. vols de boosts (ex. Spectral Thief-like) ;
7. boucle effective de hit / multihit.

C’est exactement le genre d’ordre qu’il faut figer noir sur blanc dans votre futur moteur.

---

## 7. Précision, esquive et hit chance

### 7.1 La précision n’est pas juste un pourcentage fixe

Showdown calcule la précision en plusieurs couches :
- précision de base du move ;
- `ModifyAccuracy` event ;
- boosts accuracy du lanceur ;
- boosts evasion de la cible ;
- exceptions `alwaysHit` ;
- cas spéciaux OHKO ;
- `Accuracy` event final ;
- tirage PRNG.

### 7.2 Implication pour votre moteur

Il faut distinguer au minimum :
- précision intrinsèque du move ;
- modificateurs de précision ;
- modificateurs d’esquive ;
- exceptions de type “cannot miss” ;
- immunités et semi-invulnérabilités, qui ne sont pas la même chose qu’un miss.

### 7.3 Règle d’architecture

Dans votre futur moteur, ne mélangez jamais :
- miss par précision,
- échec par immunité,
- échec par protect,
- échec par invulnérabilité,
- échec par impossibilité d’usage,
- fail silencieux / fail bruyant.

Ce sont des causes distinctes, avec parfois des messages et conséquences distincts.

---

## 8. Immunités, invulnérabilités, protections

### 8.1 Immunité de type

Showdown distingue clairement la vérification d’immunité de type via `runImmunity`.

Cette logique gère :
- le type du move ;
- les exceptions `ignoreImmunity` ;
- le cas particulier du Sol et du grounded check ;
- les immunités naturelles ;
- les immunités artificielles ;
- certains messages spéciaux comme Levitate.

### 8.2 Immunité de statut

Les statuts passent par `runStatusImmunity`, qui sépare :
- immunité naturelle ;
- immunité artificielle via événement `Immunity`.

### 8.3 Semi-invulnérabilité

Showdown traite séparément les états du type :
- Fly,
- Bounce,
- Dive,
- Dig,
- Phantom Force,
- Shadow Force,
- Sky Drop.

Ce n’est pas une “immunité de type”.
C’est une indisponibilité temporaire pour certains moves.

### 8.4 Protection

La protection est encore autre chose.
Il existe des états dédiés comme :
- Protect,
- King’s Shield,
- Spiky Shield,
- Baneful Bunker,
- Obstruct,
- Silk Trap,
- Burning Bulwark,
- etc.

Les protections se traitent dans une étape dédiée du pipeline.

### 8.5 Leçon de design

Dans votre moteur, il faut trois familles séparées :
- **immunity**
- **invulnerability**
- **protection**

Si vous fusionnez tout ça dans un seul booléen “canBeHit”, vous allez perdre énormément de finesse.

---

## 9. Le calcul de dégâts

### 9.1 Structure générale

Showdown calcule le dommage en plusieurs phases :
- détermination de la puissance de base ;
- choix de la stat offensive ;
- choix de la stat défensive ;
- boosts / ignore boosts / overrides ;
- formule de base ;
- multiplicateurs intermédiaires ;
- weather ;
- crit ;
- random factor ;
- STAB ;
- effectiveness ;
- burn ;
- final modifier ;
- minimum damage / truncation.

### 9.2 Base power

La puissance n’est pas toujours une constante.
Le move peut avoir :
- `basePower` simple ;
- `basePowerCallback` ;
- une valeur nulle ;
- des effets de spread ;
- des effets de parental bond ;
- des effets de Tera / Stellar ;
- des effets de move-specific rewrites.

### 9.3 Critiques

Les critiques passent par :
- une modification du crit ratio ;
- un tirage PRNG ;
- un événement `CriticalHit` ;
- une logique d’ignore certains boosts.

### 9.4 Stat offensif / défensif

Le move peut redéfinir :
- le Pokémon utilisé comme attaquant ;
- le Pokémon utilisé comme défenseur ;
- la stat offensive ;
- la stat défensive.

Donc un move n’utilise pas forcément `atk vs def` ou `spa vs spd` de manière triviale.

### 9.5 STAB

Le STAB n’est pas juste “1.5 si même type”.
Il y a des complications modernes :
- STAB forcé ;
- Tera ;
- Stellar ;
- modifications de STAB par événements.

### 9.6 Effectiveness

Showdown accumule l’effectiveness par type, puis applique :
- `-supereffective` si positif ;
- `-resisted` si négatif ;
- multiplication/division par paliers ;
- exceptions liées à certaines capacités.

### 9.7 Burn physique

Le malus de burn sur les moves physiques est appliqué à part, avec exception `Guts` et cas spéciaux.

### 9.8 Final modifiers

Le moteur laisse un `ModifyDamage` final, qui permet de brancher :
- Life Orb-like,
- autres multiplicateurs tardifs,
- contournements de protect partiels,
- cas spécifiques de fin de pipeline.

### 9.9 La confusion comme pipeline à part

Showdown a même une fonction séparée pour les dégâts de confusion, car ils ne suivent pas exactement la même logique que les dégâts ordinaires.

### 9.10 Leçon de design

Il faut impérativement éviter un service “damage = formula unique”.

Il faut au minimum découper :
- `BasePowerResolver`
- `AttackDefenseResolver`
- `DamageFormula`
- `DamageModifierPipeline`
- `TypeEffectivenessResolver`
- `CriticalHitResolver`
- `RandomDamageRoller`

---

## 10. Stats, boosts, speed, Trick Room

### 10.1 Stat stockée vs stat calculée

Showdown distingue :
- la stat stockée ;
- la stat après boosts ;
- la stat après événements `ModifyX` ;
- la stat d’action.

C’est une séparation très saine.

### 10.2 Wonder Room

Wonder Room peut échanger la défense et la défense spéciale dans certains calculs.
Cela est géré au niveau de `Pokemon.calculateStat` / `getStat`.

### 10.3 Trick Room

La vitesse d’action n’est pas simplement “la speed”.
Showdown a `getActionSpeed()` qui :
- calcule la speed réelle ;
- inverse l’ordre sous Trick Room ;
- tronque la valeur dans un contexte déterminé.

### 10.4 Boosts

Les boosts passent par :
- table de stages ;
- clamp ;
- event `ModifyBoost` ;
- puis éventuels `ModifyAtk`, `ModifyDef`, etc.

### 10.5 Leçon de design

Dans votre moteur, il faut séparer :
- stat de base,
- stat calculée,
- stat d’action.

Sinon vous allez mélanger :
- les stats utilisées pour le tri,
- les stats utilisées pour les dégâts,
- les stats affichées,
- les stats modifiées temporairement.

---

## 11. Les statuts principaux

### 11.1 Un statut est un effect, pas un booléen

Showdown traite un status principal comme un `Condition` avec :
- un `statusState` ;
- un `Start` ;
- des handlers ;
- un éventuel `AfterSetStatus` ;
- des hooks au tour / au move / à la vitesse / au résiduel.

### 11.2 `setStatus`

Le pipeline typique est :
- vérifier immunités ;
- `SetStatus` event ;
- créer `statusState` ;
- `Start` ;
- `AfterSetStatus`.

### 11.3 Exemples concrets

Dans `data/conditions.ts` :
- burn applique un résiduel ;
- paralysis modifie la vitesse et peut bloquer avant le move.

### 11.4 Leçon de design

Votre moteur doit traiter les statuts comme des effets entièrement scriptables avec :
- début,
- durée éventuelle,
- réactions pendant le tour,
- réactions sur la vitesse,
- résiduel,
- fin.

Pas comme un simple enum lu à deux endroits.

---

## 12. Les volatiles

Les volatiles sont l’autre couche majeure de micro-mécaniques.

Exemples :
- confusion,
- taunt,
- encore,
- substitute,
- locked move,
- protect variants,
- two-turn moves,
- trapped flags,
- etc.

### 12.1 Cycle d’un volatile

`addVolatile` :
- vérifie immunité si besoin ;
- `TryAddVolatile` ;
- crée l’état ;
- `Start` ;
- gère les liens éventuels.

`removeVolatile` :
- `End` ;
- nettoyage ;
- suppression des éventuels liens.

### 12.2 Volatiles liés

Showdown peut lier des volatiles entre Pokémon.
C’est très utile pour des effets dépendants d’une source et d’une cible.

### 12.3 Leçon de design

Il faut un vrai store de volatiles par combattant, pas une forêt de flags éparpillés.

---

## 13. Les objets

### 13.1 Les objets ne sont pas juste des bonus passifs

Un item peut intervenir à plusieurs moments :
- `UseItem`
- `TryEatItem`
- `Eat`
- `AfterUseItem`
- `TakeItem`
- `End`
- `Start`

### 13.2 États importants

Showdown distingue notamment :
- l’objet tenu ;
- l’état de l’objet (`itemState`) ;
- le dernier objet ;
- le fait qu’il ait été utilisé ce tour ;
- les cas spéciaux de baies/restoration.

### 13.3 Actions clés

Il y a plusieurs opérations distinctes :
- `eatItem`
- `useItem`
- `takeItem`
- `setItem`
- `clearItem`

Ce sont des verbes différents.

### 13.4 Leçon de design

Dans votre moteur, il faut des opérations d’item explicites.
Ne faites pas un seul `applyItemEffect()` générique opaque.

---

## 14. Les talents

### 14.1 Un talent est aussi un effect scriptable

Le talent possède :
- son état ;
- ses handlers ;
- sa logique de `Start` / `End` ;
- sa possibilité d’être supprimé, ignoré, remplacé, restauré.

### 14.2 Ignorer un talent

Showdown gère de vrais cas de suppression de talent, par exemple :
- Gastro Acid-like ;
- Neutralizing Gas-like ;
- Mold Breaker-like pour certains handlers.

### 14.3 Changer de talent

`setAbility()` n’est pas un simple assign.
Il passe par :
- règles de suppression / interdiction ;
- `SetAbility` event ;
- `End` de l’ancien ;
- création du nouvel état ;
- `Start` du nouveau.

### 14.4 Leçon de design

Les talents doivent être pilotés comme des effets runtime vivants, pas comme un champ de lecture seule accroché à la species.

---

## 15. Weather, terrain, pseudo-weather

### 15.1 Le terrain global est un niveau à part entière

Le `Field` Showdown gère trois familles distinctes :
- météo ;
- terrain ;
- pseudoWeather.

### 15.2 Météo

La météo possède :
- un id ;
- un state ;
- une source éventuelle ;
- une durée ;
- un `FieldStart` ;
- un `FieldEnd` ;
- des hooks `WeatherChange`.

### 15.3 Terrain

Le terrain suit une logique analogue :
- id,
- state,
- source,
- durée,
- `FieldStart`,
- `FieldEnd`,
- `TerrainChange`,
- `effectiveTerrain(target)`.

### 15.4 Pseudo-weather

Les pseudo-weathers sont des effets de champ globaux non météo / non terrain.
Ils sont stockés séparément avec leur propre état.

### 15.5 La météo peut être supprimée / neutralisée

Showdown distingue la météo définie de la météo effectivement applicable, notamment via `effectiveWeather()` et `suppressingWeather()`.

### 15.6 Leçon de design

Dans votre moteur, ne rangez pas tout ce qui est global dans une seule map “fieldEffects”.
Gardez au moins trois familles :
- weather,
- terrain,
- pseudoWeather.

---

## 16. Side conditions et slot conditions

### 16.1 Deux niveaux différents

Showdown distingue :
- les conditions de camp (`sideConditions`) ;
- les conditions de slot (`slotConditions`).

Cette séparation est très utile.

### 16.2 Pourquoi c’est important

Certaines mécaniques affectent :
- tout un côté ;
- une position précise ;
- un Pokémon occupant actuellement ou ultérieurement cette position.

Si vous mélangez tout dans une seule structure, vous perdez énormément de clarté.

---

## 17. Ciblage, redirection, adjacency, doubles

### 17.1 Le move ne cible pas toujours “1 ennemi”

Showdown encode de nombreux types de target :
- self,
- normal,
- adjacentFoe,
- any,
- foeSide,
- allySide,
- allAdjacentFoes,
- all,
- etc.

### 17.2 Le ciblage réel se résout au runtime

Le moteur gère :
- la redirection ;
- la retarget si la cible meurt ;
- les smart targets ;
- les constraints d’adjacence ;
- les pressure targets ;
- les target modifications en cours de pipeline.

### 17.3 Leçon de design

Le ciblage doit être un vrai sous-système :
- `TargetingRules`
- `TargetResolver`
- `RedirectionResolver`
- `AdjacencyResolver`

Pas juste `targetId` dans une action.

---

## 18. Faint, switch, residual, fin de tour

### 18.1 Un faint n’est pas immédiatement résolu

Showdown met le Pokémon dans une `faintQueue`.
Cela permet de respecter l’ordre de résolution du moteur.

### 18.2 Le switch est aussi un pipeline

Le moteur gère :
- `BeforeSwitchOut` ;
- flags de switch ;
- `runSwitch` ;
- `SwitchIn` field event ;
- puis activation des handlers associés.

### 18.3 La fin de tour

Le tour n’est pas fini quand toutes les attaques sont passées.
Il faut encore :
- gérer le résiduel ;
- résoudre les morts ;
- gérer les forced switches ;
- éventuellement faire des requests de switch ;
- terminer le tour ;
- vider / réinitialiser certains états.

### 18.4 Leçon de design

Votre moteur doit avoir une vraie phase :
- `BeforeTurn`
- `ActionLoop`
- `MidTurnRequests`
- `Residual`
- `EndTurn`

---

## 19. Multihit, spread, drain, recoil, crash, self-KO

### 19.1 Multihit

Showdown gère le multihit avec :
- distribution du nombre de hits ;
- modifications Loaded Dice-like ;
- suivi du damage par hit ;
- accumulation total damage ;
- `-hitcount`.

### 19.2 Spread

Les moves de spread utilisent un multiplicateur dédié.

### 19.3 Drain

Le drain n’est pas la même chose que heal générique.
Il dépend du damage effectivement infligé.

### 19.4 Recoil

Le moteur distingue le vrai recoil et d’autres auto-dégâts communautairement appelés recoil.

### 19.5 Crash / selfdestruct / special cases

Ces cas ont leurs points d’entrée spécifiques.
Ils ne doivent pas être noyés dans un traitement uniforme trop simpliste.

---

## 20. Transformations de combat : Mega, Z, Max, Tera

### 20.1 Ce sont des couches d’action, pas seulement de data

Showdown les traite dans la queue et dans les actions, pas seulement comme des transformations de stats.

### 20.2 Pourquoi c’est important

Parce qu’une transformation affecte :
- le timing ;
- le move utilisé ;
- le type ;
- le STAB ;
- les restrictions du side ;
- parfois les formes ;
- parfois le ciblage ou le rendu d’information.

### 20.3 Leçon de design

Dans votre moteur, prévoyez :
- un niveau `BattleAction` pour les transformations ;
- un niveau `TransformationService` ;
- un niveau `MoveVariantResolver`.

---

## 21. Le PRNG et le déterminisme

### 21.1 Point capital

Showdown ne se contente pas d’utiliser `Math.random()`.

Il simule un PRNG déterministe, capable de :
- reproduire les résultats,
- stocker un seed,
- rejouer une simulation à l’identique avec même seed + mêmes décisions.

### 21.2 Pourquoi c’est indispensable pour vous aussi

Sans PRNG déterministe, vous allez rendre très coûteux :
- les tests,
- les replays,
- le debug,
- la reproduction de bugs,
- la validation d’ordre d’événements.

### 21.3 Règle de design

Votre moteur doit avoir :
- un PRNG injectable ;
- un seed persistant dans les logs/replays ;
- une API simple : `random`, `randomChance`, `sample`, `shuffle`.

---

## 22. Formats, rulesets, mods

### 22.1 Les formats ne sont pas qu’un menu UX

Dans Showdown :
- `config/formats.ts` décrit les formats,
- `data/rulesets.ts` porte les règles,
- les formats peuvent changer le mod actif,
- donc le comportement du moteur.

### 22.2 Conséquence pour votre stack

Si vous voulez un vrai “moteur de création de jeux”, il faut penser :
- **combat ruleset**,
- **battle profile**,
- **mechanics profile**,
- **generation profile**.

Pas seulement “mode normal”.

### 22.3 Variantes de génération

La bonne abstraction n’est pas :
- un énorme moteur figé + quelques exceptions.

La bonne abstraction est :
- un noyau de simulation,
- des données,
- des variantes de comportement par profile/mod.

---

## 23. Ce qu’il faut absolument reproduire dans votre moteur

Si je devais résumer les briques indispensables à reprendre conceptuellement, ce serait :

### 23.1 Une queue d’actions réelle

Pas seulement “joueur attaque, ennemi attaque”.

### 23.2 Un event system riche

Avec relay variables, ordre, sources, cibles, et invalidation dynamique des handlers.

### 23.3 Des effets attachés à plusieurs niveaux

- battle,
- field,
- side,
- slot,
- pokemon,
- move.

### 23.4 Un modèle runtime Pokémon riche

Avec status, volatiles, item state, ability state, boosts, PP, targeting helpers, immunities.

### 23.5 Une séparation nette entre :

- noyau de simulation,
- schéma des effets,
- contenu des moves/abilities/items/status,
- profils de génération/règles.

### 23.6 Un PRNG déterministe

Non négociable.

---

## 24. Ce qu’il ne faut surtout pas copier aveuglément

Showdown est extrêmement puissant, mais ce n’est pas forcément la forme idéale pour votre produit.

### 24.1 Ne pas copier la complexité brute telle quelle

Le couple :
- event system très dynamique,
- énorme quantité de callbacks dans les data,

est très efficace pour couvrir toutes les mécaniques Pokémon, mais peut devenir lourd à maintenir si vous n’avez pas les mêmes besoins de compatibilité totale.

### 24.2 Ne pas tout faire “callback first” trop tôt

Pour votre moteur, je recommande probablement un compromis :
- pipeline explicite par phase,
- plus hooks bien typés,
- moins de liberté totale partout au début.

### 24.3 Ne pas mélanger simulation et UI

C’est un point où votre projet est déjà sur la bonne voie avec `map_battle` comme package pur.

### 24.4 Ne pas rendre les données combat dépendantes du runtime Flame

La simulation doit rester pure et déterministe.

---

## 25. Recommandation d’architecture pour votre propre moteur

Si je devais en déduire une architecture cible pour vous, je viserais quelque chose comme :

### 25.1 Noyau pur

#### `BattleEngine`
- état principal ;
- boucle de tour ;
- request state ;
- orchestration.

#### `ActionQueue`
- compile les intentions ;
- trie ;
- injecte ;
- gère les mid-turn inserts.

#### `EventEngine`
- `singleEvent`
- `runEvent`
- ordre des handlers
- relay vars
- invalidation des handlers.

### 25.2 Modèles runtime

- `BattleState`
- `BattleSideState`
- `BattleFieldState`
- `BattlePokemonState`
- `EffectState`
- `BattleAction`
- `BattleRequest`

### 25.3 Services spécialisés

- `TargetingService`
- `DamageService`
- `AccuracyService`
- `StatService`
- `StatusService`
- `SwitchService`
- `TransformationService`
- `ResidualService`

### 25.4 Contrat de données

Vos catalogues locaux Pokémon doivent porter assez d’info pour alimenter le moteur :
- move type,
- category,
- power,
- accuracy,
- pp,
- priority,
- target,
- flags utiles plus tard,
- short effects / semantic fields.

### 25.5 Profils de mécaniques

Prévoir un système du genre :
- `BattleMechanicsProfile`
- `Gen1MechanicsProfile`
- `Gen3MechanicsProfile`
- `Gen9MechanicsProfile`
- ou bien un système de `mod` / `ruleset` / `script patches`.

---

## 26. Ce qui est le plus important à relire pour une future analyse complète

Si je devais choisir **la partie la plus importante** du projet Showdown à relire pour refaire une analyse complète des mécaniques de combat, ce serait :

## **le trio `sim/battle.ts` + `sim/battle-actions.ts` + `sim/pokemon.ts`**

Et si je devais n’en nommer qu’un seul :

## **`sim/battle.ts`**

Pourquoi ?
Parce que c’est là que se trouve :
- le système d’événements ;
- l’ordonnancement ;
- la logique de propagation ;
- l’ordre des handlers ;
- le lien entre toutes les autres couches.

Mais pour reconstruire réellement le moteur, `battle.ts` seul ne suffit pas.

### Ordre de lecture recommandé la prochaine fois

1. `sim/battle.ts`
2. `sim/battle-actions.ts`
3. `sim/pokemon.ts`
4. `sim/battle-queue.ts`
5. `sim/dex-moves.ts`
6. `sim/dex-conditions.ts`
7. `sim/field.ts`
8. `sim/side.ts`
9. `data/moves.ts`
10. `data/abilities.ts`
11. `data/items.ts`
12. `data/conditions.ts`
13. `data/mods/*`
14. `config/formats.ts`
15. `data/rulesets.ts`

### Pourquoi cet ordre est le bon

- `battle.ts` dit **comment** le moteur vit ;
- `battle-actions.ts` dit **comment** une action se résout ;
- `pokemon.ts` dit **où** vit l’état d’un combattant ;
- `battle-queue.ts` dit **dans quel ordre** les choses arrivent ;
- `dex-moves.ts` et `dex-conditions.ts` disent **quelles capacités d’extension** le moteur expose ;
- `data/*` dit **quelles mécaniques concrètes** sont branchées dessus ;
- `mods/*` dit **comment les générations divergent**.

---

## 27. Ce qui est directement utile pour votre projet actuel

Bonne nouvelle : votre projet a déjà plusieurs fondations compatibles avec une montée en puissance du moteur.

### 27.1 Ce que vous avez déjà

Vous avez déjà, côté projet local Pokémon :
- des catalogues pour `moves`, `abilities`, `items`, `types`, etc. ;
- un schéma de move qui porte déjà `type`, `category`, `power`, `accuracy`, `pp`, `priority`, `target` ;
- des learnsets locaux ;
- un runtime qui sait déjà lancer un combat ;
- un `BattleSetup` / `BattleState` / `BattleAction` minimal.

### 27.2 Ce qui manque encore fortement

Votre moteur combat actuel reste encore minimal si on le compare à Showdown :
- payload move trop pauvre ;
- combattants trop pauvres ;
- pas encore de vrai système d’effets ;
- dégâts encore simplifiés ;
- pas encore de vraie séparation entre immunité / précision / protection / statut / secondaires ;
- pas encore de queue d’actions riche à la hauteur des mécaniques complètes.

### 27.3 Ce que cela veut dire pour la suite

Le bon prochain chantier n’est pas “ajouter une feature flashy”.
Le bon prochain chantier est bien :
- enrichir le payload combat,
- enrichir l’état runtime combat,
- poser le vrai pipeline,
- puis seulement ensuite ajouter accuracy, STAB, type chart, PP, etc.

---

## 28. Recommandation de roadmap combat après cette analyse

À partir de cette lecture, la progression saine pour votre moteur serait :

### Étape A — Enrichissement des données de combat

Objectif :
- moves complets,
- types du Pokémon,
- stats de combat,
- accuracy/pp/priority/target dans le runtime,
- boosts,
- status/volatiles de base.

### Étape B — Pipeline de hit réel

Objectif :
- invulnerability,
- try hit,
- immunité de type,
- immunités spécifiques,
- accuracy,
- protection,
- application du hit.

### Étape C — Damage pipeline réel

Objectif :
- base power,
- offensive stat,
- defensive stat,
- crit,
- random,
- STAB,
- effectiveness,
- burn,
- final modifiers.

### Étape D — Effets et hooks

Objectif :
- statuts,
- volatiles,
- side conditions,
- weather,
- terrain,
- items,
- talents.

### Étape E — Queue et multi-combattants

Objectif :
- vrais switchs,
- faint queue,
- residual,
- doubles / plus tard.

---

## 29. Conclusion de fond

La compréhension profonde de Showdown donne une direction très claire :

### Un vrai moteur Pokémon doit être construit autour de 5 piliers

1. **un état de combat riche et hiérarchisé**
2. **une queue d’actions ordonnée**
3. **un système d’événements central**
4. **des effets data-driven branchés sur des hooks typés**
5. **un PRNG déterministe**

### La partie la plus importante à retenir

Si je devais condenser tout le document en une seule phrase :

> **Le moteur de combat Pokémon n’est pas une formule ; c’est un système d’ordonnancement et de propagation d’effets.**

Et si je devais condenser encore plus :

> **Commencez par reproduire le pipeline, pas les chiffres.**

C’est ça qui vous permettra ensuite d’ajouter proprement :
- précision,
- type chart,
- PP,
- statuts,
- talents,
- objets,
- switch,
- doubles,
- variations de génération,

sans détruire le moteur à chaque lot.

---

## 30. Fichiers à considérer comme “source de vérité” pour la prochaine passe d’analyse

### Priorité absolue
- `sim/battle.ts`
- `sim/battle-actions.ts`
- `sim/pokemon.ts`

### Priorité très haute
- `sim/battle-queue.ts`
- `sim/dex-moves.ts`
- `sim/dex-conditions.ts`

### Priorité haute
- `sim/field.ts`
- `sim/side.ts`
- `data/moves.ts`
- `data/abilities.ts`
- `data/items.ts`
- `data/conditions.ts`

### Priorité nécessaire pour la fidélité générationnelle
- `data/mods/gen1/*`
- `data/mods/gen2/*`
- `data/mods/gen3/*`
- etc.

### Priorité utile pour les règles de format
- `config/formats.ts`
- `data/rulesets.ts`

---

## 31. Verdict final pour votre projet

La conclusion pratique est simple :

- vous n’avez **pas** besoin de copier Showdown tel quel ;
- vous avez **besoin** de reprendre ses grandes idées structurelles ;
- le centre de gravité de votre prochaine roadmap combat doit être :
  - enrichissement de l’état,
  - pipeline d’action,
  - pipeline de hit,
  - pipeline de dégâts,
  - hooks d’effets.

C’est la base qui vous permettra ensuite de faire un moteur de création de jeux Pokémon propre, extensible et vraiment sérieux.
