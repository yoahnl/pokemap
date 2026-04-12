# Roadmap Maître Recalée — pokemonProject

## 1. But du document

Ce document sert de **roadmap maître recalée** pour la suite du projet.

Il ne repart pas de zéro.
Il part de l'état réel actuel du repo et d'un principe central qui ne doit pas bouger :

**on améliore l'existant, on ne crée aucune stack parallèle.**

Cela implique explicitement :

- pas de nouveau runtime Pokémon parallèle ;
- pas de nouveau save system parallèle ;
- pas de nouveau modèle concurrent à `PlayerPokemon` ;
- pas de nouveau moteur de combat parallèle à `map_battle` ;
- pas de second pipeline Pokédex ;
- pas de logique métier poussée dans les widgets UI ;
- pas de grand refactor transversal "propre" si une extension locale honnête suffit.

Ce document remplace une roadmap trop "domain-first" par une roadmap plus **réaliste, verticale et pilotable**.

## 2. Résumé exécutif

Le projet a déjà dépassé le stade du prototype vide.

Aujourd'hui, le repo dispose déjà de fondations réelles pour :

- la persistance de partie ;
- le Pokédex local et ses imports externes ;
- le catalogue local des moves ;
- l'édition minimale des learnsets ;
- les trainers et les encounter tables ;
- les battle requests runtime ;
- un moteur de combat pur Dart encore minimal ;
- un pattern réel de field move avec Surf.

Le vrai enjeu n'est donc plus de "construire un système Pokémon from scratch".
Le vrai enjeu est de **faire converger les briques existantes vers une boucle fangame complète**.

Le point le plus important de cette version recalée est le suivant :

**le bridge runtime -> battle réel doit arriver tôt**.

On ne doit pas repousser indéfiniment la preuve de la boucle de jeu pendant qu'on peaufine l'authoring.
La bonne stratégie est :

1. rendre le Pokédex auteur vraiment productif ;
2. brancher les références assistées là où elles ont déjà un retour immédiat ;
3. rendre trainers et encounters suffisamment propres pour produire de vraies données ;
4. supprimer le placeholder du handoff runtime -> battle ;
5. obtenir un combat sauvage réel ;
6. obtenir capture + persistance minimale ;
7. seulement ensuite approfondir le moteur de combat et élargir la boucle RPG.

## 3. Ce qui est déjà acquis dans le repo

Cette section ne décrit pas des intentions.
Elle décrit les éléments déjà présents dans l'état actuel du repo et du worktree.

### 3.1. Save et modèle de partie

Le repo a déjà une vraie base persistée :

- `GameState`
- `SaveData`
- `PlayerPokemon`
- `PlayerParty`
- `TrainerProfile`
- `Bag`
- `PlayerProgression`
- migration legacy et persistance runtime

Conclusion :

- on ne crée surtout pas de modèle `OwnedPokemon` concurrent ;
- on ne crée surtout pas un second format de save.

### 3.2. Pokédex et import Pokémon

La phase 11A est considérée comme clôturée.
Le repo a déjà :

- une config Pokémon projet légère dans `ProjectManifest` ;
- un `dataRoot`, des sous-dossiers dédiés (`species`, `learnsets`, `evolutions`, `media`) et des `catalogFiles` explicites ;
- un bootstrap local via `InitializePokemonProjectStorageUseCase` ;
- un pipeline d'import externe Pokémon ;
- un `dryRun` et une preview ;
- une source produit unique côté UI ;
- des mini-fix de cohérence média ;
- une preuve de clôture 11A documentée.

Conclusion :

- on ne rouvre pas artificiellement 11A ;
- on n'écrit pas un deuxième pipeline d'import externe.

### 3.3. Catalogues locaux et moves catalog

Le repo n'est plus dans un état "catalogues à inventer".
Il a déjà :

- un scaffold local de catalogues dans l'arborescence Pokémon du projet ;
- des clés catalogue explicites dans la config Pokémon ;
- un import JSON catalogue local ;
- des validations croisées déjà branchées sur certains catalogues ;
- des seeds et jeux de démonstration pour plusieurs familles.

La phase 11B a ensuite fait exister un vrai premier jalon moves dans le worktree courant :

- catalogue local des moves ;
- sync/import depuis source externe ;
- surface minimale côté éditeur ;
- première intégration utile avec le learnset editor.

Le repo valide déjà concrètement :

- `learnset -> moves catalog`
- `species -> types catalog`

et sait déjà basculer certains catalogues manquants vers des warnings explicites plutôt que des comportements opaques.

Conclusion :

- la partie "catalogues" ne repart pas de zéro ;
- la stratégie réaliste est bien **moves-first**, déjà amorcée ;
- le prochain travail doit capitaliser sur ce socle au lieu de le réécrire.

### 3.4. Trainers et encounter tables

Le repo contient déjà :

- `ProjectTrainerEntry` et ses variantes associées ;
- des use cases trainers ;
- des use cases encounter tables ;
- un wiring applicatif déjà exposé dans l'éditeur ;
- des panneaux éditeur existants ;
- la résolution de rencontres côté `map_gameplay`.

Conclusion :

- on améliore ces surfaces ;
- on ne crée pas un second système de trainers ou de rencontres.

### 3.5. Runtime et battle skeleton

Le runtime sait déjà :

- déclencher une demande de combat sauvage ;
- déclencher une demande de combat trainer ;
- produire de vrais `BattleStartRequest` sauvages et trainers ;
- ouvrir un overlay de combat ;
- relayer un flux de retour combat vers l'overworld.

Le moteur `map_battle` existe déjà, mais il reste un MVP.

Le vrai trou actuel est bien le dernier maillon :

- le mapping final vers `BattleSetup` reste encore placeholder ;
- `_toBattleSetup()` injecte encore des espèces, niveaux et moves simplifiés au lieu de consommer complètement les vraies données projet/save.

Conclusion :

- le vrai point critique n'est pas "faire apparaître un combat" ;
- le vrai point critique est de **faire cesser les placeholders métier** entre runtime, données projet et moteur battle.

### 3.6. Field moves

Surf existe déjà comme pattern réel.

Conclusion :

- les futures capacités terrain doivent généraliser ce pattern ;
- elles ne doivent pas le dupliquer en plusieurs sous-systèmes hardcodés.

## 4. Ce qui reste partiel

Cette section couvre les zones déjà entamées mais pas encore suffisamment solides pour être considérées comme "terminées".

### 4.1. Pokédex auteur

Le Pokédex existe, mais il manque encore :

- la vraie résolution de requête externe ;
- l'auto-complétion mono-espèce ;
- le vrai flow batch utilisable ;
- le dry-run batch lisible ;
- l'exécution batch avec progression et rapport ;
- la maintenance bulk ergonomique.

### 4.2. Catalogues et références assistées

Le catalogue moves existe déjà, mais il reste partiel au niveau produit :

- l'UI learnset doit encore mieux exploiter ce catalogue ;
- les équipes trainers doivent ensuite bénéficier du même socle moves-first ;
- les autres écrans n'en profitent pas encore suffisamment ;
- moves est la priorité actuelle ;
- abilities / items / types / egg groups / growth rates sont encore à traiter de manière progressive.

### 4.3. Trainers et encounters

Le socle est là, mais l'expérience auteur n'est pas encore au bon niveau :

- trop de friction pour authorer une vraie team trainer proprement ;
- encore trop de surfaces peu assistées ;
- les encounter tables ne sont pas encore au niveau d'un vrai workflow "fangame authoring".

### 4.4. Bridge runtime -> battle

C'est aujourd'hui le plus gros point de vérité technique restant :

- le runtime sait lancer le combat ;
- mais le mapping final vers `BattleSetup` reste encore trop placeholder ;
- tant que ça n'est pas traité, la boucle de jeu Pokémon n'est pas vraiment prouvée.

### 4.5. Combat system

Le moteur battle existe, mais la profondeur système reste limitée :

- dégâts encore trop simplifiés ;
- pas encore toute la chaîne type chart / PP / accuracy / switch / statuts ;
- pas encore une boucle Pokémon crédible de bout en bout.

## 5. Ce qui reste réellement à construire

Voici les grands blocs qui restent réellement à construire, en distinguant bien le cœur de boucle du confort plus tardif.

### 5.1. Must-have avant toute ambition "fangame complet"

- Pokédex batch auteur utilisable
- références assistées moves là où elles ont le plus de valeur
- edition trainers/encounters suffisamment propre
- bridge runtime -> battle réel
- combat sauvage réel
- seen/caught persistant
- capture minimale
- trainer battle minimal complet
- heal / whiteout-lite

### 5.2. Should-have après preuve de boucle

- catalogues additionnels progressifs
- battle depth stage 1 puis stage 2
- starter / gifts / static encounters
- shop minimal
- centre Pokémon plus propre
- field abilities généralisées

### 5.3. Later

- tooling auteur plus riche
- recherche globale projet
- dashboard santé étendu
- UX runtime joueur plus ambitieuse
- documentation complète
- projet démo de référence
- packaging / build guide final

## 6. Roadmap maître recalée

La roadmap ci-dessous est le nouveau document de pilotage global.
Elle est volontairement plus compacte que la première version.

### Phase A — Pokédex auteur productif

But :

- rendre l'import, la recherche, le batch et la maintenance Pokédex réellement exploitables à l'échelle.

Contenu :

- résolveur de requête externe ;
- auto-complétion mono-espèce ;
- batch selection ;
- dry-run batch ;
- exécution batch ;
- rapport final ;
- revalidate / reimport / delete / maintenance bulk.

### Phase B — Références assistées progressives, moves-first

But :

- faire disparaître les champs texte bruts là où ils créent le plus de dette.

Ordre recommandé :

1. moves partout où ils débloquent une vraie valeur ;
2. species/forms/items dans trainers et encounters ;
3. autres catalogues seulement quand un écran ou une boucle les exige réellement.

Important :

- cette phase part d'un socle déjà présent ;
- elle ne recrée ni le moves catalog, ni son import, ni sa première surface éditeur ;
- elle prolonge ce qui est déjà livré en 11B.

### Phase C — Authoring trainers / encounters convergent

But :

- permettre à un auteur de produire sans JSON manuel des données directement combatables.

Contenu :

- trainer library minimal mais propre ;
- encounter tables minimales mais propres ;
- validation inline ;
- preview auteur simple.

### Phase D — Bridge runtime -> battle réel

But :

- faire sauter le placeholder entre les données projet/save et le moteur battle.

Contenu :

- mapper la vraie party joueur ;
- mapper les wild encounters réels ;
- mapper les vraies teams trainers ;
- appliquer proprement le résultat de combat au `GameState`.

### Phase E — Boucle Pokémon minimale jouable

But :

- prouver une vraie boucle Pokémon verticale.

Contenu :

- combat sauvage réel ;
- seen/caught ;
- capture minimale ;
- save/load cohérent ;
- combat trainer minimal ;
- heal / whiteout-lite.

### Phase F — Battle depth progressive

But :

- rendre le combat crédible sans bloquer la preuve de boucle.

Découpage recommandé :

- F1 : stats et payloads enrichis
- F2 : dégâts + STAB + type chart
- F3 : accuracy + crit + priorité + PP
- F4 : switch et parties complètes
- F5 : statuts majeurs
- F6 : abilities / items / forms progressifs
- F7 : rewards / IA / hooks de progression

### Phase G — Boucle fangame minimale complète

But :

- dépasser la simple preuve de combat pour obtenir un mini jeu Pokémon jouable.

Contenu :

- starter / gift / static encounter ;
- centre Pokémon ;
- shop minimal ;
- progression terrain généralisée ;
- économie et boucle de survie plus propre.

### Phase H — Tooling auteur, UX runtime et docs

But :

- transformer le repo en vrai produit interne confortable.

Contenu :

- validation actionnable ;
- health dashboard ;
- recherche globale ;
- playtest rapide ;
- rapports exportables ;
- UX runtime joueur enrichie ;
- documentation ;
- projet démo.

## 7. Milestones verticaux recalés

Ces milestones sont les vrais jalons de preuve.
Ils servent à éviter l'effet "beaucoup de lots terminés, peu de boucle réellement jouable".

### M1 — Pokédex auteur utilisable

Ce que ce milestone prouve :

- un auteur peut importer et maintenir des espèces à grande échelle sans bricoler.

Gate de sortie :

- mono-espèce avec auto-complétion ;
- batch sélectionnable ;
- dry-run batch ;
- exécution batch ;
- rapport lisible ;
- pas de parsing batch caché dans l'UI.

### M2 — Données combat authorables correctement

Ce que ce milestone prouve :

- les données qui alimentent le gameplay combatable peuvent être produites proprement dans l'éditeur.

Gate de sortie :

- learnsets profitent réellement du catalogue moves local ;
- trainers authorables sans JSON manuel ;
- encounter tables authorables sans texte libre fragile ;
- erreurs de refs visibles immédiatement ;
- preview auteur minimale disponible là où utile.

### M3 — Handoff combat réel

Ce que ce milestone prouve :

- le runtime ne triche plus entre ses requests, les données projet et `BattleSetup`.

Gate de sortie :

- plus de placeholder métier dans le handoff ;
- vraie party joueur mappée ;
- vraies species wild mappées ;
- vraies teams trainers mappées ;
- tests runtime dédiés.

### M4 — Combat sauvage jouable

Ce que ce milestone prouve :

- la première vraie boucle Pokémon verticale existe.

Gate de sortie :

- déplacement ;
- rencontre sauvage ;
- handoff réel ;
- combat jouable ;
- retour overworld propre ;
- état runtime resynchronisé.

### M5 — Capture et persistance minimale

Ce que ce milestone prouve :

- la boucle de jeu commence à "tenir" comme jeu Pokémon, pas seulement comme démo de combat.

Gate de sortie :

- seen/caught persiste ;
- capture minimale fonctionne ;
- l'équipe ou un fallback minimal est mis à jour proprement ;
- save/load relit correctement ce nouvel état.

### M6 — Combat trainer minimal complet

Ce que ce milestone prouve :

- la seconde grande boucle du RPG Pokémon est présente.

Gate de sortie :

- trainer battle réel ;
- victoire/défaite mappées ;
- anti-retrigger ;
- reward minimal ;
- flags de progression cohérents.

### M7 — Boucle fangame minimale complète

Ce que ce milestone prouve :

- on a un mini fangame Pokémon jouable du début à une petite boucle de progression.

Gate de sortie :

- starter ou gift minimal ;
- wild battle ;
- capture ;
- trainer battle ;
- heal ;
- whiteout-lite ;
- save/load toujours cohérent.

### M8 — Combat crédible v2

Ce que ce milestone prouve :

- le système de combat devient défendable comme vrai combat Pokémon simplifié.

Gate de sortie :

- dégâts crédibles ;
- type chart ;
- précision ;
- PP ;
- switch ;
- statuts stage 1.

### M9 — Tooling auteur de production

Ce que ce milestone prouve :

- le repo est tenable pour une production plus longue sans dette explosive.

Gate de sortie :

- validation actionnable ;
- recherche projet ;
- bulk maintenance ;
- playtest rapide ;
- rapports exploitables.

## 8. Backlog prioritaire recalé

Cette section décrit les **15 prochains lots réalistes**.
Ils sont ordonnés pour maximiser la convergence produit, pas seulement la pureté par domaine.

### Lot 1 — Résolveur de requête externe Pokédex

Priorité : `must-have`

But :

- transformer une requête utilisateur en intention structurée :
  - mono-espèce ;
  - liste ;
  - plage dex ;
  - génération.

Pourquoi maintenant :

- c'est la base de toute l'UX Pokédex moderne.

Done :

- `bulbasaur`, `1-151`, `gen 1`, `pikachu,eevee,abra` sont reconnus correctement ;
- la sortie est structurée et réutilisable en UI ;
- aucun parsing batch métier dans les widgets.

### Lot 2 — Auto-complétion mono-espèce dans le wizard

Priorité : `must-have`

But :

- remplacer la saisie libre fragile par une sélection assistée explicite.

Pourquoi maintenant :

- c'est le plus petit gain produit immédiatement visible.

Done :

- impossible de prévisualiser/importer sans espèce réellement résolue ;
- suggestions clavier/souris ;
- états loading / error / introuvable propres.

### Lot 3 — Sélection batch + dry-run batch

Priorité : `must-have`

But :

- exposer le batch de manière lisible avant écriture.

Pourquoi maintenant :

- le batch existe déjà côté métier ; il manque surtout le vrai flow auteur.

Done :

- liste finale ciblée visible ;
- doublons supprimés ;
- dry-run sans écriture ;
- preview stable et lisible même sur gros lot.

### Lot 4 — Exécution batch + progression + rapport

Priorité : `must-have`

But :

- rendre le batch réellement productif.

Done :

- progression ;
- compteurs succès / conflit / skip / erreur ;
- retry des seules erreurs ;
- rapport final clair.

### Lot 5 — Exploitation réelle du catalogue moves dans le Pokédex

Priorité : `must-have`

But :

- faire passer le learnset editor d'une simple garde minimale à une vraie saisie assistée moves-first.

Pourquoi maintenant :

- le socle moves catalog local existe déjà ;
- il faut maintenant l'utiliser davantage.

Done :

- recherche locale de moves dans le learnset editor ;
- sélection assistée ;
- validation plus lisible ;
- affichage honnête des ids legacy hors catalogue.

### Lot 6 — Service de recherche catalogue progressif

Priorité : `must-have`

But :

- créer le contrat commun réutilisable pour les catalogues locaux.

Important :

- le service doit partir du moves catalog déjà présent ;
- il ne doit pas forcer d'emblée abilities/items/types si ces catalogues ne sont pas encore prêts à être productisés.

Done :

- recherche par id/libellé ;
- contrat stable ;
- réutilisable par Pokédex, trainers et encounters.

### Lot 7 — Trainers : surface minimale vraiment exploitable

Priorité : `must-have`

But :

- permettre à un auteur de créer un trainer complet sans JSON.

Done :

- création/édition/suppression trainer ;
- édition propre de la team ;
- species/moves/items/forms assistés là où c'est disponible ;
- erreurs visibles immédiatement ;
- sauvegarde stable ;
- un auteur peut créer un trainer complet sans JSON.

### Lot 8 — Encounter tables : surface minimale vraiment exploitable

Priorité : `must-have`

But :

- permettre à un auteur de configurer une table wild valide sans texte libre fragile.

Done :

- add/edit/delete/reorder d'entrées ;
- species assistée ;
- validation niveau/poids ;
- lisibilité des probabilités ;
- preview auteur simple si le coût reste faible ;
- un auteur peut configurer une table wild valide sans texte libre fragile.

### Lot 9 — Mappers runtime réels vers `BattleSetup`

Priorité : `must-have`

But :

- supprimer les placeholders métier du handoff combat.

Done :

- player party -> `BattleSetup`
- wild encounter -> `BattleSetup`
- trainer team -> `BattleSetup`
- plus aucune espèce/move hardcodée dans le mapping final.

### Lot 10 — Application du résultat de combat au `GameState`

Priorité : `must-have`

But :

- resynchroniser réellement le runtime après combat.

Done :

- HP post-combat appliqués ;
- issues victory/defeat/runaway mappées ;
- trainer defeated flag cohérent ;
- retour overworld propre.

### Lot 11 — Combat sauvage end-to-end jouable

Priorité : `must-have`

But :

- obtenir la première vraie preuve verticale de boucle Pokémon.

Done :

- déplacement -> rencontre -> combat -> retour overworld ;
- plus aucun placeholder métier visible ;
- tests runtime de non-régression.

### Lot 12 — Seen / caught persistants

Priorité : `must-have`

But :

- préparer la boucle Pokémon persistée sans encore ouvrir un chantier capture trop gros d'un seul bloc.

Done :

- état seen/caught sérialisé ;
- save/load cohérent ;
- runtime capable d'en tirer parti.

### Lot 13 — Capture runtime minimale

Priorité : `must-have`

But :

- ajouter la capture comme premier vrai enrichissement de la boucle sauvage.

Done :

- consommation d'une ball ;
- résolution minimale de capture ;
- mise à jour seen/caught ;
- insertion contrôlée dans l'équipe ou fallback minimal.

### Lot 14 — Combat trainer minimal complet

Priorité : `must-have`

But :

- prouver la seconde grande boucle de jeu.

Done :

- trainer battle réel ;
- victoire/défaite stables ;
- anti-retrigger ;
- reward minimal ;
- flags cohérents.

### Lot 15 — Heal / center / whiteout-lite

Priorité : `must-have`

But :

- fermer la boucle de survie minimale du jeu.

Done :

- soin complet ;
- point de reprise minimal ;
- whiteout-lite ;
- save/load toujours cohérent après ces transitions.

## 9. Lots redécoupés / reformulés

Cette section capture explicitement les corrections de forme appliquées à la roadmap précédente.

### 9.1. Catalogues

Ancienne erreur :

- traiter d'un bloc moves + abilities + items + types + egg groups + growth rates.

Décision recalée :

- **moves d'abord** ;
- ensuite seulement les autres catalogues quand un écran ou un workflow les exige réellement.

### 9.2. Trainers

Ancienne erreur :

- "upgrade panel trainer" restait trop abstrait.

Nouvelle définition :

- **un auteur peut créer un trainer complet sans JSON**
- **la team est éditable proprement**
- **les refs invalides sont visibles immédiatement**

### 9.3. Encounter tables

Ancienne erreur :

- "upgrade encounter tables" restait trop vague.

Nouvelle définition :

- **un auteur peut configurer une table wild valide sans texte libre fragile**
- **les probabilités sont lisibles**
- **les erreurs sont visibles avant runtime**

### 9.4. Capture / seen-caught / save-load

Ancienne erreur :

- tout mélanger dans un seul lot trop gros.

Nouvelle décision :

- d'abord seen/caught persistants ;
- ensuite capture runtime minimale ;
- ensuite seulement les raffinements de party overflow, boxes complètes et UX avancée.

### 9.5. Combat depth

Ancienne erreur :

- compacter trop de profondeur battle dans une seule phase.

Nouvelle décision :

- prouver d'abord la boucle verticale avec un moteur encore simple ;
- approfondir ensuite en plusieurs étages clairement séparés.

## 10. Registre de risques mis à jour

### 10.1. Risques techniques

- `PlayableMapGame` peut continuer à grossir trop vite si l'on ne sort pas assez tôt les mappers et l'outcome applier.
- le contrat entre données locales Pokémon, battle setup et moteur combat peut rester incomplet.
- le moteur `map_battle` peut devenir le nouveau goulet si on lui demande trop tôt toute la profondeur système.

### 10.2. Risques de migration

- toute extension de `GameState` / `PlayerPokemon` a un coût réel de migration ;
- si on ouvre trop vite boxes + progression dex + capture + UI runtime complète, le risque de dette de save augmente fortement.

### 10.3. Risques d'UX auteur

- si les champs texte libres restent trop longtemps dans learnsets/trainers/encounters, la dette de données continuera à s'accumuler ;
- si le batch Pokédex devient trop complexe trop tôt, l'outil peut devenir impressionnant mais peu fiable.

### 10.4. Risques produit

- trop de polish auteur avant preuve de boucle de jeu ;
- faux sentiment de progrès si beaucoup d'UI avancent alors que le handoff runtime -> battle reste placeholder ;
- faux sentiment de profondeur si `map_battle` grossit avant d'avoir prouvé la boucle verticale minimale.

### 10.5. Stratégie de mitigation

- garder le bridge runtime très haut dans l'ordre ;
- imposer des gates de sortie par milestone ;
- découper les lots save/capture/combat plus finement ;
- ne productiser les autres catalogues qu'au moment opportun ;
- préférer des tranches verticales prouvées à des lots "impressionnants" mais partiellement intégrés.

## 11. Ordre réaliste recommandé à partir d'aujourd'hui

L'ordre recommandé est le suivant :

1. Lots 1 à 4
   - rendre le Pokédex auteur vraiment productif
2. Lots 5 à 8
   - supprimer la dette de référence là où elle gêne déjà concrètement
3. Lots 9 à 11
   - supprimer les placeholders runtime -> battle et prouver le combat sauvage réel
4. Lots 12 à 15
   - transformer cette première boucle en mini boucle Pokémon persistée
5. Battle depth par étapes
6. Boucle fangame élargie
7. Tooling riche / UX runtime / docs

## 12. Verdict final

La roadmap initiale était **bonne comme vision**.

La version recalée de ce document est meilleure pour trois raisons :

- elle tient compte de ce qui est déjà acquis dans le repo, notamment la clôture 11A et le socle moves catalog 11B ;
- elle reconnaît plus explicitement que les catalogues locaux et une partie de la validation croisée existent déjà ;
- elle remonte le bridge runtime -> battle à la bonne hauteur de priorité ;
- elle remplace une progression trop "par domaine" par une progression plus **verticale, prouvable et jouable**.

La bonne suite réaliste n'est donc pas :

- de réouvrir 11A ;
- de réinventer la stack Pokémon ;
- de lancer immédiatement toute la profondeur battle ;
- ou de multiplier les catalogues d'un coup.

La bonne suite réaliste est :

1. finaliser un **poste de travail Pokédex productif** ;
2. fiabiliser les **références assistées moves-first** ;
3. rendre **trainers et encounters** vraiment authorables ;
4. supprimer les **placeholders runtime -> battle** ;
5. obtenir une **boucle sauvage réelle** ;
6. ajouter **capture + persistance minimale** ;
7. puis seulement approfondir le combat, la progression, l'économie et le tooling.
