# Audit de progression Pokédex et plan de suite

Date : 2026-04-10

## Mise à jour de statut au 2026-04-11

Important :
- cette section est désormais la **source de vérité actuelle** ;
- elle remplace les statuts plus anciens plus bas dans ce document quand ils se contredisent ;
- les sections détaillées historiques sont conservées pour le contexte, mais elles ont été rédigées avant le réalignement des fondations Pokédex, avant la phase 5, et avant le lot 23.

### Résumé rapide actuel

Ce qui est fait aujourd’hui :
- les fondations Pokédex locales existent et fonctionnent ;
- le storage local est réaligné sur `data/pokemon/media` ;
- le contrat espèce utilise `refs.learnset / refs.evolution / refs.media` ;
- le contrat média Pokémon existe ;
- lecture, écriture, validation et indexation locales existent ;
- la tuile Pokédex éditeur existe ;
- la liste, la recherche, les filtres, la sélection et la fiche détail lecture seule existent ;
- le lot 23 d’import unitaire d’une espèce JSON interne est fait ;
- le mini-fix de robustesse du lot 23 est fait.

Ce qui n’est pas encore fait :
- imports internes learnset / évolution / média / catalogues (`lots 24 à 27`) ;
- normalisation externe Showdown / PokeAPI (`lots 28 à 36`) ;
- curation locale / overrides (`lots 37 à 43`) ;
- modèles gameplay/save (`lots 44 à 47`) ;
- menus in-game (`lots 48 à 51`).

### Tableau de statut actuel des lots

Statuts utilisés :
- `OK` : fait et exploitable dans le périmètre du lot
- `PARTIEL` : présent, mais avec un compromis ou une forme plus générique que la cible finale
- `NON FAIT` : pas encore traité

| Lot | Statut | Lecture honnête |
| --- | --- | --- |
| 1 | OK | Arborescence locale Pokémon en place, avec `data/pokemon/media` |
| 2 | OK | Modèle espèce local en place, sérialisable, avec bloc `refs` |
| 3 | OK | Modèle learnset local en place, avec `levelUp`, `tm`, `tutor`, `egg`, `event`, `transfer` |
| 4 | OK | Modèle évolution local en place, avec `preEvolution`, `targetSpeciesId`, `method`, `minLevel`, `itemId`, `requiredMoveId`, `conditionText` |
| 5 | OK | Modèle média Pokémon en place, compatible avec le système d’animation existant, sans GIF |
| 6 | PARTIEL | Catalogues principaux présents et sérialisables, mais encore portés par un contrat générique plutôt qu’un type Dart dédié par grand catalogue |
| 7 | PARTIEL | Catalogues secondaires et manifeste local présents, mais encore dans une forme générique côté modélisation |
| 8 | OK | Repositories de lecture locaux présents pour species, learnsets, evolutions, media et catalogues |
| 9 | OK | Repositories d’écriture locaux présents pour species, learnsets, evolutions, media et catalogues |
| 10 | OK | Validation locale présente, avec rapport structuré et checks utiles sur refs et données croisées |
| 11 | OK | Références Pokédex légères dans `project.json`, sans données inline |
| 12 | OK | `PokemonDatabaseIndex` présent et exploitable pour alimenter la liste sans charger tout le détail |
| 13 | OK | Tuile Pokédex vide initiale intégrée à l’éditeur |
| 14 | OK | Liste simple locale des espèces importées |
| 15 | OK | Recherche texte simple sur nom / id / numéro dex |
| 16 | OK | Filtres simples type + génération |
| 17 | OK | Sélection locale d’une espèce dans la liste |
| 18 | OK | Vue détail `Overview` |
| 19 | OK | Vue `Formes / classification` |
| 20 | OK | Onglet `Learnset` |
| 21 | OK | Onglet `Évolutions` |
| 22 | OK | Onglet `Médias` |
| 23 | OK | Import manuel d’une espèce depuis un JSON interne, avec mini-fix de robustesse appliqué |
| 24 | NON FAIT | Import manuel d’un learnset interne |
| 25 | NON FAIT | Import manuel d’une évolution interne |
| 26 | NON FAIT | Import manuel d’un média interne |
| 27 | NON FAIT | Import manuel d’un catalogue global interne |
| 28 | NON FAIT | Normalisation des catalogues globaux depuis sources externes |
| 29 | NON FAIT | Convertisseur Showdown → espèce core |
| 30 | NON FAIT | Convertisseur Showdown → formes / classification |
| 31 | NON FAIT | Convertisseur PokeAPI → learnset |
| 32 | NON FAIT | Convertisseur PokeAPI → évolutions |
| 33 | NON FAIT | Génération de stubs média |
| 34 | NON FAIT | Commande d’import unitaire depuis source externe |
| 35 | NON FAIT | Commande d’import par lot |
| 36 | NON FAIT | Dry-run / merge policy / rapport de conflits |
| 37 | NON FAIT | Activer / désactiver une espèce dans le projet |
| 38 | NON FAIT | Filtre UI activé / désactivé |
| 39 | NON FAIT | Édition locale des métadonnées simples |
| 40 | NON FAIT | Édition locale des formes / classification |
| 41 | NON FAIT | Édition locale des learnsets autorisés |
| 42 | NON FAIT | Édition locale des évolutions |
| 43 | NON FAIT | Édition locale des médias utilisés |
| 44 | NON FAIT | Modèle `OwnedPokemon` |
| 45 | NON FAIT | Modèle `TrainerProfile` |
| 46 | NON FAIT | Modèle `Bag` |
| 47 | NON FAIT | Modèle `SaveGame` et flux de save simple |
| 48 | NON FAIT | Menu principal du jeu |
| 49 | NON FAIT | Écran Pokédex en jeu |
| 50 | NON FAIT | Écran Sac |
| 51 | NON FAIT | Écran Dresseur |

### Suite recommandée maintenant

Le prochain point propre à attaquer est :
1. `Lot 24`
2. `Lot 25`
3. `Lot 26`
4. `Lot 27`

Donc, à date :
- **ce qu’on a fait** : `lots 1 à 23`, avec `lots 6` et `7` encore marqués `PARTIEL` à cause de la modélisation générique des catalogues ;
- **ce qu’on n’a pas fait** : `lots 24 à 51`.

## Résumé exécutif

Le repo contient déjà une vraie base Pokédex exploitable :

- stockage local dans le workspace projet ;
- modèles locaux `species`, `learnset`, `evolution` ;
- bootstrap/seed ;
- lecture/écriture locales ;
- validation locale ;
- config légère dans `project.json` ;
- index léger ;
- tuile UI Pokédex ;
- liste simple ;
- recherche texte ;
- filtres simples.

Mais il y a un point important à dire franchement : **le code actuel n'est pas aligné à 100 % avec le nouveau mémo produit**.

En pratique :

- les lots "bas niveau" existent bien en grande partie ;
- plusieurs sont **MVP / partiels** par rapport au schéma cible riche ;
- la numérotation historique du repo ne correspond pas exactement à la nouvelle roadmap ;
- et il y a encore des **incohérences structurelles réelles** qu'il vaut mieux corriger avant d'attaquer trop loin les détails riches, les imports externes et les overrides.

Conclusion honnête :

- on n'est pas simplement "au lot 15 proprement terminé" au sens strict du nouveau mémo ;
- on est plutôt à :
  - **lots 13 à 16 UI déjà présents en pratique** ;
  - avec **plusieurs lots 1 à 12 seulement partiellement conformes** à la cible finale.

La bonne stratégie n'est donc pas :

- "continuer comme si tout le socle était parfait".

La bonne stratégie est :

1. **geler ce qui fonctionne déjà** ;
2. **rattraper les écarts de fondation** ;
3. **reprendre ensuite la roadmap à partir du prochain lot réellement manquant**.

## Méthode d'audit

Inspection directe des fichiers suivants :

- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/application/models/pokemon_database_index.dart`
- `packages/map_editor/lib/src/application/models/pokedex_list_entry.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/application/services/pokemon_database_index.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_validator.dart`
- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/list_pokedex_entries_use_case.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/pokemon_database_index_test.dart`
- `packages/map_editor/test/list_pokedex_entries_use_case_test.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- rapports Pokédex déjà présents dans `reports/`

## Écarts structurels importants constatés

Avant le détail lot par lot, voici les écarts qui comptent vraiment.

### 1. Le stockage bootstrap n'est pas encore aligné avec la convention produit finale

Le bootstrap crée encore :

- `data/pokemon/sprite_sets/`

dans :

- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`

Alors que la convention produit retenue plus récente est :

- `data/pokemon/media/`

et que `ProjectPokemonConfig.mediaDir` pointe déjà vers :

- `data/pokemon/media`

dans :

- `packages/map_core/lib/src/models/project_manifest.dart`

Donc aujourd'hui, il y a une **incohérence réelle entre la config projet et le bootstrap local**.

### 2. Le modèle espèce n'a pas encore le contrat cible retenu

Le modèle actuel `PokemonSpeciesFile` contient encore :

- `evolutionRef`
- `learnsetRef`
- `spriteSetRef`
- `cryRef`

dans :

- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`

Alors que la cible produit moderne du mémo est :

```json
"refs": {
  "learnset": "...",
  "evolution": "...",
  "media": "..."
}
```

Donc le repo utilise encore une **ancienne forme de références**, plus fragmentée que la cible finale.

### 3. Le lot "media" n'existe pas encore vraiment au sens du mémo

Je n'ai pas trouvé de vrai :

- `PokemonMediaFile`
- `PokemonMediaVariant`

Le système actuel sait parler de :

- `spriteSetRef`
- `cryRef`

mais **pas encore d'un contrat média Pokémon complet et unifié**.

### 4. Learnsets et évolutions sont encore minimaux

Le schéma actuel est propre, mais limité :

- `PokemonLearnsetFile` : `startingMoves`, `relearnMoves`, `levelUp`
- `PokemonEvolutionEntry` : `targetSpeciesId`, `method`, `minLevel`

Les blocs attendus plus riches du mémo ne sont pas encore là :

- `tm`
- `tutor`
- `egg`
- `event`
- `transfer`
- `itemId`
- `requiredMoveId`
- `conditionText`
- etc.

### 5. Les catalogues sont encore génériques, pas typés par domaine

Le repo a un modèle générique :

- `PokemonCatalogFile`

mais pas encore :

- un type Dart dédié par grand catalogue ;
- ni un contrat riche spécifique par domaine métier.

Ça fonctionne pour la phase actuelle, mais ce n'est pas encore la forme cible du mémo.

### 6. Le Pokédex UI existe déjà au-delà du lot 15 du mémo

Le workspace Pokédex actuel gère déjà :

- placeholder ;
- liste ;
- recherche ;
- filtres type + génération.

Donc, si on se base sur **le mémo que tu viens de donner**, le repo a déjà **dépassé le lot 15** et a en pratique déjà une partie du **lot 16**.

Le problème n'est pas l'absence de progression UI.
Le problème est plutôt : **la base de données Pokédex n'est pas encore totalement réalignée avec le contrat final qu'on veut soutenir**.

## Vérification lot par lot contre la roadmap cible

Statuts utilisés :

- `OK` : conforme ou très proche du besoin cible
- `PARTIEL` : existe, mais seulement sous une forme incomplète ou différente
- `NON FAIT` : pas réellement présent

### Phase 1 — Fondations de données

#### Lot 1 — Créer l’arborescence de données Pokémon

Statut : `PARTIEL`

Constat :

- le bootstrap crée bien des dossiers Pokémon locaux ;
- il crée aussi les catalogues JSON de base ;
- mais il crée encore `data/pokemon/sprite_sets/` au lieu de la cible `data/pokemon/media/`.

Fichier principal :

- `packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`

Verdict :

- base présente ;
- alignement produit final pas encore correct.

#### Lot 2 — Créer le modèle de base espèce

Statut : `PARTIEL`

Constat :

- `PokemonSpeciesFile` existe ;
- il est sérialisable ;
- il couvre déjà une bonne partie du noyau espèce ;
- mais le contrat n'est pas celui de la cible finale ;
- il utilise encore des refs éclatées `spriteSetRef` / `cryRef`.

Fichier principal :

- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`

Verdict :

- bon socle ;
- pas encore le bon contrat final.

#### Lot 3 — Créer le modèle de base learnset

Statut : `PARTIEL`

Constat :

- `PokemonLearnsetFile` existe ;
- sérialisation en place ;
- `moveId`, `level`, `versionGroup`, `source` sont modélisés pour `levelUp` ;
- mais il manque encore les familles attendues par la roadmap :
  - `tm`
  - `tutor`
  - `egg`
  - `event`
  - `transfer`
  - etc.

Verdict :

- base propre ;
- pas encore au niveau de richesse attendu.

#### Lot 4 — Créer le modèle de base évolution

Statut : `PARTIEL`

Constat :

- `PokemonEvolutionFile` et `PokemonEvolutionEntry` existent ;
- `preEvolution`, `targetSpeciesId`, `method`, `minLevel` existent ;
- mais il manque encore plusieurs champs ciblés du mémo :
  - `itemId`
  - `requiredMoveId`
  - `conditionText`
  - autres conditions avancées.

Verdict :

- présent ;
- encore minimal.

#### Lot 5 — Créer le modèle de base média

Statut : `NON FAIT`

Constat :

- pas de vrai `PokemonMediaFile` trouvé ;
- pas de vrai `PokemonMediaVariant` trouvé ;
- pas de schéma unifié média Pokémon trouvé ;
- seulement des refs séparées `spriteSetRef` et `cryRef`.

Verdict :

- c'est le plus gros trou réel des fondations.

#### Lot 6 — Créer les catalogues globaux principaux

Statut : `PARTIEL`

Constat :

- les fichiers catalogues existent via bootstrap/seed ;
- les clés principales existent :
  - `moves`
  - `abilities`
  - `items`
  - `types`
  - `growth_rates`
  - `natures`
- mais l'implémentation actuelle passe par un contrat générique `PokemonCatalogFile`, pas par un type dédié par catalogue.

Verdict :

- exploitable ;
- pas encore conforme à la cible de modélisation.

#### Lot 7 — Créer les catalogues globaux secondaires et le manifeste local Pokémon

Statut : `PARTIEL`

Constat :

- bootstrap et seed prévoient :
  - `egg_groups`
  - `habitats`
  - `encounter_rules`
  - `generations`
  - `version_groups`
- `pokemon_data_manifest.json` existe côté bootstrap ;
- mais là encore, on reste sur des contrats génériques, et le manifeste local est encore lié à l'ancien vocabulaire `sprite_sets`.

Verdict :

- présent en grande partie ;
- nécessite un réalignement.

### Phase 2 — Infrastructure locale

#### Lot 8 — Créer les repositories de lecture locaux

Statut : `PARTIEL`

Constat :

- lecture locale OK pour :
  - species
  - learnsets
  - evolutions
  - catalogues
  - index/listings
- erreurs explicites correctement gérées ;
- **pas de lecture média Pokémon dédiée**.

Fichiers principaux :

- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`

Verdict :

- très bonne base ;
- mais pas complète vis-à-vis du schéma cible.

#### Lot 9 — Créer les repositories d’écriture locaux

Statut : `PARTIEL`

Constat :

- écriture stable pour :
  - species
  - learnsets
  - evolutions
  - catalogues
- pas d'écriture média dédiée.

Verdict :

- solide ;
- mais incomplet tant que `PokemonMediaFile` n'existe pas.

#### Lot 10 — Créer les validateurs de données Pokémon

Statut : `PARTIEL`

Constat :

- un vrai validateur local existe ;
- rapport structuré existe ;
- tests existent ;
- validation des refs croisées et catalogues moves/types existe ;
- mais la validation n'est pas encore alignée sur un schéma média complet ni sur tous les catalogues futurs ;
- la checklist métier du nouveau mémo est plus ambitieuse que le validateur actuel.

Verdict :

- bon lot ;
- à étendre seulement après réalignement du schéma.

### Phase 3 — Intégration au projet PokeMap

#### Lot 11 — Ajouter les références Pokémon dans le project.json

Statut : `PARTIEL`

Constat :

- `ProjectPokemonConfig` existe bien dans `ProjectManifest` ;
- `project.json` reste léger ;
- migration/fallback existent ;
- mais il y a un écart concret entre cette config et le bootstrap actuel :
  - config : `mediaDir = data/pokemon/media`
  - bootstrap réel : `data/pokemon/sprite_sets`

Verdict :

- lot conceptuellement fait ;
- cohérence finale encore à rétablir.

#### Lot 12 — Créer le service PokemonDatabaseIndex

Statut : `PARTIEL`

Constat :

- `PokemonDatabaseIndex` existe ;
- index léger existe ;
- il alimente la UI sans lire learnsets/evolutions/media détaillés ;
- il expose :
  - `id`
  - `nationalDex`
  - `primaryName`
  - `types`
  - `genIntroduced`
  - `refs`
- mais `refs` sont encore :
  - `learnset`
  - `evolution`
  - `spriteSet`
  - `cry`

et pas encore la forme cible unifiée autour de `media`.

Verdict :

- bon service ;
- contrat encore intermédiaire.

### Phase 4 — UI minimale de la tuile Pokédex dans l’éditeur

#### Lot 13 — Créer la tuile Pokédex vide dans l’éditeur

Statut : `OK`

Constat :

- workspace Pokédex présent ;
- navigation présente ;
- placeholder honnête présent.

#### Lot 14 — Afficher la liste simple des espèces importées

Statut : `OK`

Constat :

- liste locale affichée ;
- colonnes simples présentes ;
- lecture seule.

#### Lot 15 — Ajouter recherche texte simple

Statut : `OK`

Constat :

- recherche locale par nom / id / numéro dex déjà en place ;
- comportement simple et prévisible.

#### Lot 16 — Ajouter filtres simples réellement disponibles

Statut : `OK`

Constat :

- filtres `type` et `génération` déjà présents dans la UI actuelle ;
- cumul avec recherche déjà implémenté.

Conséquence importante :

- **le repo actuel a déjà dépassé le lot 15 du mémo.**

### Phase 5 — Fiche détail Pokédex dans l’éditeur

#### Lot 17 — Sélectionner une espèce depuis la liste

Statut : `NON FAIT`

Constat :

- la liste actuelle reste lecture seule ;
- pas de sélection persistante de ligne ;
- pas d'espèce active courante côté UI locale.

### Lots 18+ 

Statut global : `NON FAIT`

Constat :

- pas de fiche détail Pokédex riche ;
- pas d'onglets Overview / Learnset / Evolutions / Media ;
- pas d'import interne ;
- pas de pipeline externe ;
- pas d'overrides ;
- pas de modèles OwnedPokemon / Bag / SaveGame ;
- pas de réutilisation in-game.

## Verdict global sur "est-ce que tout est bon jusqu'au lot 15 ?"

Réponse courte : **non, pas au sens strict du nouveau mémo**.

Réponse plus juste :

- **oui**, il y a déjà un vrai Pokédex fonctionnel jusqu'à la liste/recherche/filtres ;
- **non**, les fondations 1 à 12 ne sont pas toutes parfaitement alignées avec le contrat final que tu veux désormais ;
- et **oui**, la UI a même déjà atteint le lot 16 du nouveau mémo.

Donc le bon diagnostic n'est pas :

- "on s'est arrêtés proprement au lot 15".

Le bon diagnostic est :

- "on a déjà avancé plus loin sur la UI que sur la stabilité du contrat de données final".

## Ce qu'il faut faire maintenant

Il faut **continuer**, mais pas n'importe comment.

Je recommande un plan en deux temps :

1. **Phase 0 de réalignement Pokédex**
2. **Puis reprise de la roadmap métier/UI/import dans un ordre sûr**

## Phase 0 — Rattrapage de fondation avant de continuer

Cette phase n'ajoute pas de nouveau scope produit visible.
Elle sert à éviter de bâtir la suite sur un contrat bancal.

### R0.1 — Réaligner le storage local sur `media/`

Objectif :

- remplacer la convention historique `sprite_sets` par la convention produit finale `media`.

À faire :

- mettre à jour `InitializePokemonProjectStorageUseCase`
- mettre à jour le manifeste local Pokémon bootstrap
- mettre à jour le seed si nécessaire
- mettre à jour les tests de bootstrap/seed/reader qui parlent encore de `sprite_sets`

Pourquoi c'est prioritaire :

- aujourd'hui `project.json` et le bootstrap ne racontent pas la même histoire.

### R0.2 — Introduire un vrai `PokemonMediaFile`

Objectif :

- créer enfin le contrat média Pokémon local attendu.

À faire :

- ajouter `PokemonMediaFile`
- ajouter `PokemonMediaVariant`
- ajouter un contrat `animations` compatible avec le système existant
- bannir explicitement tout GIF dans le modèle

Pourquoi c'est prioritaire :

- tant que ce modèle n'existe pas, les refs espèce restent structurellement provisoires.

### R0.3 — Remplacer les refs éclatées par un vrai bloc `refs`

Objectif :

- faire converger `PokemonSpeciesFile` vers :

```json
"refs": {
  "learnset": "...",
  "evolution": "...",
  "media": "..."
}
```

À faire :

- introduire un type `PokemonSpeciesRefs`
- migrer lecture/écriture/validation/index
- conserver éventuellement une compat temporaire de migration si nécessaire

Pourquoi c'est prioritaire :

- c'est un point de vérité structurel ;
- plus on attend, plus on duplique les adaptations.

### R0.4 — Enrichir learnset et évolution au niveau "vrai minimum cible"

Objectif :

- ne pas tout faire d'un coup, mais atteindre un minimum cohérent avec la roadmap.

Learnset minimum à ajouter :

- `tm`
- `tutor`
- `egg`
- `event`
- `transfer`

Evolution minimum à ajouter :

- `itemId`
- `requiredMoveId`
- `conditionText`

Pourquoi c'est prioritaire :

- sinon la future fiche détail va devoir être codée sur un contrat déjà obsolète.

### R0.5 — Décider clairement la stratégie de catalogues

Deux options saines :

1. **types Dart dédiés par grand catalogue**
2. **contrat générique conservé, mais avec wrappers applicatifs typés**

Je recommande :

- **wrappers typés progressifs**, pas une explosion immédiate de fichiers, si on veut garder le scope propre.

Pourquoi :

- le générique actuel est pratique ;
- mais il devient trop flou pour les imports externes et les écrans de détail riches.

## Roadmap recommandée pour finir tous les lots

Voici l'ordre que je recommande maintenant.

## Étape A — Rattrapage de fondation

### A1

Faire la phase `R0.1` à `R0.5`.

Sortie attendue :

- schéma local réaligné ;
- media réel ;
- refs cohérentes ;
- index et validation mis à jour ;
- project config cohérente avec le storage réel.

## Étape B — Reprendre la roadmap UI là où elle devrait vraiment reprendre

Après réalignement, reprendre ainsi :

### Lot 17 — Sélection d’une espèce

Faire :

- sélection de ligne ;
- état d'espèce active local au workspace ;
- mise en évidence visuelle propre.

### Lot 18 — Vue détail overview

Faire :

- identité ;
- types ;
- stats ;
- talents ;
- refs.

### Lot 19 — Formes / classification

Faire :

- formes ;
- classification ;
- flags simples.

### Lot 20 — Learnset

Faire :

- sections de learnset ;
- groupement lisible ;
- niveau/méthode/versionGroup bien visibles.

### Lot 21 — Évolutions

Faire :

- pré-évolution ;
- évolutions suivantes ;
- conditions lisibles.

### Lot 22 — Médias

Faire :

- front/back/shiny/icon/party/portrait/cry ;
- refs d'animation ;
- strictement sans GIF.

## Étape C — Import local interne

Ensuite reprendre la phase 6 telle quelle, car elle reste logique :

- lot 23
- lot 24
- lot 25
- lot 26
- lot 27

Mais avec un prérequis clair :

- `PokemonMediaFile` doit exister avant le lot 26.

## Étape D — Import externe / normalisation

Ensuite :

- lots 28 à 36

Ordre conseillé à l'intérieur :

1. catalogues globaux
2. convertisseur espèce core
3. convertisseur formes/classification
4. convertisseur learnset
5. convertisseur évolutions
6. stub média
7. import unitaire
8. batch
9. dry-run / merge policy

## Étape E — Curation locale / overrides

Ensuite :

- lots 37 à 43

Point important :

- ne pas démarrer cette phase avant que l'import externe soit stable ;
- sinon on devra gérer trop tôt les conflits entre source importée et override local.

## Étape F — Gameplay/save foundations

Ensuite :

- lots 44 à 47

C'est bien le bon moment :

- le catalogue Pokédex sera alors suffisamment stable pour préparer `OwnedPokemon`.

## Étape G — Menus in-game

Enfin :

- lots 48 à 51

Parce que :

- l'écran Pokédex en jeu doit idéalement réutiliser un contenu déjà bien stabilisé ;
- pas l'inverse.

## Plan concret recommandé en nouveaux lots de travail

Pour la suite immédiate, je te recommande de ne pas reprendre directement au lot 17 du mémo.

Je recommande ce découpage opérationnel :

### Lot A — Réaligner le storage local Pokédex sur `media/`

### Lot B — Introduire `PokemonMediaFile` et les tests JSON associés

### Lot C — Migrer `PokemonSpeciesFile` vers `refs.learnset/evolution/media`

### Lot D — Ajouter lecture/écriture/validation/index pour `media`

### Lot E — Enrichir `PokemonLearnsetFile`

### Lot F — Enrichir `PokemonEvolutionFile`

### Lot G — Stabiliser `PokemonDatabaseIndex` sur le contrat final

### Lot H — Vérifier toute la chaîne existante jusqu'à la UI liste/recherche/filtres

### Lot I — Reprendre le lot 17 du mémo

À partir de là, on pourra repartir proprement sur :

- lot 17
- lot 18
- lot 19
- lot 20
- lot 21
- lot 22
- puis le reste.

## Ce que je recommande très clairement

Je recommande **de ne pas continuer directement vers la fiche détail Pokédex** tant que les points suivants ne sont pas traités :

- `media/` pas encore aligné ;
- pas de vrai `PokemonMediaFile` ;
- refs espèce encore en ancien format ;
- learnsets/evolutions encore trop minimaux pour les vues riches ;
- lecture/écriture/validation média inexistantes.

Sinon, on va faire exactement ce qu'on veut éviter :

- bricoler une UI riche sur un schéma transitoire ;
- puis devoir tout rebrancher quand l'import externe et les médias arriveront.

## Recommandation finale

Oui, on peut tout à fait continuer le projet.

Mais le meilleur prochain mouvement n'est pas :

- "lot 17 direct".

Le meilleur prochain mouvement est :

- **une mini phase de réalignement des fondations Pokédex** ;
- puis reprise propre du parcours UI détail ;
- puis import interne ;
- puis import externe ;
- puis overrides ;
- puis save/gameplay ;
- puis menus in-game.

En une phrase :

**le Pokédex actuel est déjà utile, mais il faut maintenant consolider son contrat de données avant de construire les couches riches dessus.**
