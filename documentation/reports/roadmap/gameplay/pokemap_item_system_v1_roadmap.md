# PokeMap Item System V1 — Roadmap d’implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development when explicitly authorized, or executing-plans for an execution inline. Implémenter cette roadmap lot par lot, suivre les cases à cocher et ne jamais effectuer d’opération Git d’écriture sans autorisation explicite.

**Goal:** Construire un système d’objets cohérent, project-owned et extensible dans lequel le catalogue, le Bag, l’overworld, les combats, la capture, les boutiques, les récompenses, l’éditeur et le MCP consomment une définition canonique unique.

**Architecture:** Introduire dans map_core des contrats d’objets exécutables et un codec de catalogue strict, puis résoudre leurs capacités dans map_gameplay sans dépendre de Flutter ou de Flame. Les pockets restent des métadonnées de présentation ; aucun comportement ne dépend d’une chaîne de catégorie. Le changement est une rupture assumée : seuls le catalogue et les sauvegardes du nouvel Item System sont acceptés, sans lecteur, adaptateur ou migration pour les anciens formats.

**Tech Stack:** Dart 3, Flutter, Freezed/JSON selon les conventions locales, map_core, map_gameplay, map_battle, map_runtime, map_authoring, map_editor, JSONL/CLI, PokeMap MCP et outils de certification produit.

---

## 1. Statut, autorité et règle de portée

- [ ] IN_PROGRESS — les phases 0 à 6 sont clôturées ; ITM-070 est livré et ITM-071 est le prochain lot de certification.
- Dernière mise à jour : 11 août 2026, après création et validation de la fixture synthétique Golden Item System du lot ITM-070.
- Avancement : 37 lots DONE, 1 lot DEFERRED_BY_PRODUCT et 4 lots TODO sur 42 lots uniques.
- Phases : 7 phases réalisées sur 8 ; seule la phase 7 reste à exécuter.
- Travail restant : 4 lots immédiatement exécutables (`ITM-071` à `ITM-074`) et 1 lot différé (`ITM-034`) qui ne doit pas être compté comme une tâche de la prochaine vague.
- Unité de suivi : cette roadmap ne maintient pas un second registre de tâches atomiques ; les unités d’exécution officielles sont les lots `ITM-*`.
- La phase 3 est clôturée sur le périmètre V1 signé ; ITM-034 Repel reste explicitement différé avec FG-065 et ne bloque ni la phase 6, ni la capture minimale.
- Ce document est la roadmap dédiée à la refonte Item System V1.
- La roadmap mécanique racine reste l’autorité des statuts FG-050 et FG-060 à FG-079.
- Les identifiants ITM-* découpent l’implémentation technique sans remplacer les identifiants FG-*.
- Aucun projet de jeu utilisateur n’est une source de vérité produit.
- Les projets réels peuvent servir de smoke tests manuels, jamais de fixture canonique, de règle métier ou de dépendance CI.
- Les preuves automatisées utilisent uniquement des fixtures synthétiques appartenant au dépôt.
- Un lot n’est DONE que si ses contrats, ses tests ciblés, son analyse et son état Git sont rapportés avec des résultats frais.
- Aucun statut existant de la roadmap mécanique n’est rétrogradé automatiquement par ce document. Les lots déjà fermés sont recertifiés sur la nouvelle architecture avant suppression des chemins historiques.

## 2. Résumé exécutif

À l’ouverture de cette roadmap, le système possédait déjà des briques réelles et testées : persistance du Bag, soins hors combat, objets de combat génériques, capture minimale, boutiques, récompenses, pickups, machines et objets tenus. Le problème initial n’était donc pas l’absence de fonctionnalités, mais l’absence d’une autorité commune.

Le diagnostic de départ était le suivant :

- BagEntry persiste itemId, categoryId et quantity ;
- Bag.normalized fusionne par le couple categoryId/itemId ;
- le catalogue d’objets est projeté dans l’éditeur par un modèle privé ;
- PlayerItemEffectRegistry connaît une petite liste d’identifiants codés en dur ;
- le runtime de combat filtre aussi sur des catégories codées en dur ;
- les boutiques, récompenses et conséquences de scène réinventent leur propre catégorie ;
- capture, TM/HM et objets tenus utilisent encore des registries ou loaders séparés ;
- la validation structurelle ne prouve pas qu’un objet configuré est réellement consommable ;
- les contrats item.* et bag.* documentés ne sont pas exposés par le MCP live.

La stratégie retenue est un remplacement progressif du code, livré comme une rupture de données unique :

1. caractériser les comportements métier qui doivent survivre, sans conserver leurs formats ;
2. créer les contrats stricts et le codec canoniques ;
3. remplacer le Bag et refuser explicitement les anciennes sauvegardes ;
4. basculer chaque consommateur vers le resolver commun ;
5. livrer l’authoring no-code et la parité MCP ;
6. supprimer intégralement les chemins historiques ;
7. certifier le tout sur une golden slice générique.

### 2.1 État livré après la phase 5

| Domaine | État au 11 août 2026 | Autorité actuelle |
|---|---|---|
| Catalogue et codec | DONE — schéma V1 strict, définitions exécutables, validation et ports partagés | `ProjectItemCatalog` dans map_core |
| Bag et sauvegarde | DONE — piles par itemId, opérations atomiques, receipts, wire strict itemId/quantity et refus typé de tout ancien champ | `BagOperations` et `UnsupportedSaveSchema` |
| Gameplay | DONE sur le périmètre V1 — overworld, battle, capture minimale, key items, TM/HM, évolution et held items | `ItemCatalogSnapshot`, `ItemCapabilityResolver` et services spécialisés |
| Producteurs et économie | DONE — New Game, événements, pickups, rewards et shops utilisent les contrats canoniques | `BagOperations` et `ProjectItemReferenceIndex` |
| Authoring et MCP | DONE — lectures, mutations, Item Studio, pickers, JSONL, Editor et MCP sont raccordés | map_authoring et ses adaptateurs de transport |
| Suppression historique | DONE — décisions par catégorie, registries, wrappers dupliqués et ancien wire Bag retirés | ITM-060 à ITM-062 |
| Certification produit | IN_PROGRESS — fixture Golden Item System repo-owned livrée ; flow automatisé à exécuter | ITM-071 à ITM-074 |

### 2.2 Décision de continuation

ITM-060 à ITM-062 ont retiré les décisions historiques par catégorie, les registries, les wrappers devenus inutiles et l’ancien wire Bag. ITM-070 fournit désormais la fixture synthétique stricte sur laquelle le flow automatisé ITM-071 doit s’appuyer. ITM-034 reste hors vague tant que la décision produit FG-065 n’est pas explicitement réouverte. Cette synthèse ne modifie aucun statut FG de la roadmap mécanique racine : leur recertification reste réservée à ITM-074.

## 3. Audit initial vérifié

### 3.1 Git et périmètre

- Branche observée : main.
- HEAD observé à la création de la roadmap : c145292d3.
- État initial : worktree propre.
- L’audit n’a modifié aucun code produit.
- Les zones auditées couvrent map_core, map_gameplay, map_battle, map_runtime, map_editor, map_authoring, tools/pokemap_mcp et la roadmap mécanique.

### 3.2 Contrats et comportements actuels

| Domaine | État observé | Limite structurante |
|---|---|---|
| Catalogue | Import, lecture, recherche, sprites et métadonnées | Modèle privé à map_editor ; texte d’effet non exécutable |
| Bag | Quantités, normalisation et save/load | categoryId participe à l’identité d’une pile |
| Objets joueur | Heal, cure, revive, PP, key item et Ball metadata | Registry MVP limité à des IDs codés en dur |
| Overworld | Menu Bag, cible, transaction et sauvegarde | Résolution par registry statique et loaders annexes |
| Combat | Heal, cure et revive via action générique | Disponibilité encore filtrée par categoryId |
| Capture | Formule déterministe et une Poké Ball minimale | Une seule Ball et catégorie runtime historique |
| Shops | Modèle, états, prix, stock, achat et vente | Catégorie dérivée séparément du catalogue |
| Give/take/rewards | Mutations et persistance fonctionnelles | Inférence partielle et codée en dur de la catégorie |
| TM/HM | Loader catalogue et service d’apprentissage | Métadonnées séparées du registre d’utilisation |
| Objets tenus | Registry battle et write-back runtime | Pas d’opération Bag/Party complète et canonique |
| Validation | Forme des BagEntry et références de shops | Pas de validation de capacité runtime par contexte |
| Authoring/MCP | New Game, shops et payloads d’entités partiels | Aucun domaine item ou bag découvrable dans le live MCP |

### 3.3 Autorités actuellement concurrentes

Les sources suivantes définissent aujourd’hui une partie du comportement Item :

1. packages/map_gameplay/lib/src/player_item_effects.dart
2. packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart
3. packages/map_battle/lib/src/capture_formula.dart
4. packages/map_runtime/lib/src/application/runtime_move_machine_loader.dart
5. packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
6. packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
7. packages/map_runtime/lib/src/application/player_service_runtime_controller.dart
8. packages/map_gameplay/lib/src/game_state_mutations.dart
9. packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart

Ces fichiers ne doivent pas être fusionnés artificiellement dans un mega-service. La cible est un contrat partagé et plusieurs adaptateurs spécialisés qui consomment ce contrat.

### 3.4 Baseline fraîche issue de l’audit

| Commande | Résultat |
|---|---:|
| cd packages/map_gameplay puis cinq suites Bag, rewards, shops, machines et New Game | 89 tests réussis |
| cd packages/map_battle puis quatre suites items génériques, capture et manifest held items | 35 tests réussis |
| cd packages/map_runtime puis onze suites Bag, battle, shop, pickup, key item, held item, machine, reward et New Game | 72 tests réussis |
| cd packages/map_editor puis suites New Game, catalogue, synchronisation et shops | 18 tests réussis |
| cd packages/map_editor puis scènes filtrées giveItem/takeItem | 4 tests réussis |
| cd packages/map_battle && dart analyze | aucune issue |
| cd packages/map_gameplay && dart analyze | une info préexistante unnecessary_library_name |
| analyses ciblées map_runtime et map_editor | aucune issue |

Cette baseline prouve les slices existantes. Elle ne prouve pas leur intégration avec des catégories de catalogue arbitraires.

### 3.5 État frais après la phase 5 et le rebase

- Branche vérifiée : `codex/item-system-phase-0`.
- Base locale vérifiée : `main` à `6ea3b7e8fd09`, ancêtre du HEAD de la branche.
- HEAD produit vérifié avant cette mise à jour documentaire : `dbc93a7dd`.
- Écart vérifié : 40 commits de la branche et aucun commit de `main` absent après le rebase.
- État Git initial de cette mise à jour : worktree propre.

| Vérification fraîche | Résultat exact |
|---|---:|
| `cd packages/map_authoring && dart test` | 562 tests réussis |
| `cd packages/map_authoring && dart analyze` | aucune issue |
| `cd packages/map_editor && flutter test test/item_studio_workspace_test.dart test/authoring_api/item_authoring_transport_test.dart` | 7 tests réussis |
| `cd packages/map_editor && flutter analyze` | aucune issue |
| `cd packages/map_runtime && flutter test test/player_service_runtime_controller_test.dart test/player/runtime_shop_service_test.dart` | 12 tests réussis |
| `cd examples/playable_runtime_host && flutter test test/evaluation/evaluation_playtest_adapter_test.dart --plain-name "bounded player-state service drives Bag commands without durable writes"` | 1 test réussi |
| `cd examples/playable_runtime_host && flutter analyze lib/main.dart` | aucune issue |
| `cd tools/pokemap_mcp && node --import tsx --test test/item_authoring.test.ts test/playtest_player_state.test.ts` | 2 tests réussis |
| `cd tools/pokemap_mcp && npm run check` | aucune erreur TypeScript |

L’analyse globale de `examples/playable_runtime_host` conserve un exit code non nul causé par 26 lints de niveau `info` déjà présents et hors périmètre Item System. Le fichier recomposé par le rebase, `lib/main.dart`, est analysé sans issue. Cette dette n’est donc ni masquée, ni attribuée à la phase 5.

## 4. Contrat produit non négociable

### 4.1 Identité et présentation

1. itemId est l’identité stable d’un objet dans un projet.
2. Deux piles possédant le même itemId représentent le même objet ; le nouveau wire Bag ne contient aucune catégorie.
3. pocketId organise l’interface et peut être librement défini par le projet.
4. Une catégorie issue d’un import externe est transformée en pocketId ou en tag avant l’écriture canonique ; categoryId n’existe pas dans le nouveau contrat.
5. Renommer un objet ou son pocket ne modifie ni ses usages, ni les sauvegardes, ni les références.
6. Un objet valide sans usage direct est affiché comme objet passif, pas comme objet cassé.
7. Unsupported signifie que la définition demande une capacité que le moteur ne sait pas exécuter ; cette situation doit être détectée avant le playtest.

### 4.2 Comportement

1. Une définition exécutable déclare explicitement les contextes autorisés.
2. Le même effet produit le même résultat en overworld et en combat lorsque les deux contextes sont déclarés.
3. Aucun écran ne réinterprète un texte descriptif pour fabriquer un effet.
4. Une consommation est transactionnelle : zéro consommation sans effet appliqué, exactement une consommation après un effet accepté.
5. La capture consomme exactement la Ball associée à la tentative acceptée, succès ou échec.
6. Les multiplicateurs de capture utilisent des rationnels entiers, jamais des doubles divergents.
7. Les objets tenus restent résolus par map_battle, mais leur référence et leur support sont validés depuis la définition canonique.
8. Les machines restent résolues par le service d’apprentissage, mais leurs métadonnées proviennent de la même définition canonique.
9. Les objets clés ne sont ni jetables, ni vendables, ni consommables par défaut.
10. Les objets custom peuvent être passifs, utilisables ou liés à une action sémantique explicitement supportée.

### 4.3 Rupture de format

1. Un catalogue sans le schemaVersion exact du nouvel Item System est refusé.
2. Une sauvegarde utilisant l’ancien BagEntry ou contenant categoryId est refusée.
3. Aucun lecteur dual, fallback MVP, adaptateur legacy ou migration automatique n’est livré.
4. Le refus retourne une erreur typée avec le format détecté, le format attendu et le chemin concerné.
5. Une écriture de catalogue ou de sauvegarde est déterministe et stable.
6. Les doublons du même itemId dans le nouveau format sont fusionnés de manière déterministe, avec conservation de la quantité totale.
7. Une définition inconnue échoue en validation avec un chemin précis ; elle ne devient pas silencieusement un objet passif.

## 5. Architecture cible

### 5.1 Contrats dans map_core

Créer un domaine focalisé dans packages/map_core/lib/src/models/items/.

Contrats visés :

    ProjectItemCatalog
      schemaVersion: int (valeur obligatoire : 1)
      entries: List<ProjectItemDefinition>

    ProjectItemDefinition
      id: String
      displayName: String
      aliases: List<String>
      pocketId: String
      description: String?
      buyPrice: int?
      sellPrice: int?
      tags: Set<String>
      uses: List<ProjectItemUseDefinition>
      capture: ProjectCaptureItemDefinition?
      machine: ProjectMoveMachineItemDefinition?
      heldEffectId: String?

    ProjectItemUseDefinition
      contexts: Set<ProjectItemUseContext>
      target: ProjectItemTargetKind
      consumption: ProjectItemConsumptionPolicy
      effect: ProjectItemEffectDefinition

    ProjectItemEffectDefinition
      healHp(mode: flat|full, amount: int?)
      cureStatus(mode: listed|all, statusIds: Set<String>)
      revive(rateNumerator: int, rateDenominator: int)
      restorePp(mode: flat|full, amount: int?)
      repel(steps: int)
      semanticAction(actionId: String)

    ProjectCaptureItemDefinition
      rateNumerator: int
      rateDenominator: int
      allowedEncounterKinds: Set<EncounterKind>

    ProjectMoveMachineItemDefinition
      moveId: String
      kind: tm|hm
      consumable: bool

    SaveData
      itemSystemSchemaVersion: int (valeur obligatoire : 1)
      bag: List<BagEntry>

    BagEntry
      itemId: String
      quantity: int

Les effets sont un vocabulaire fermé et versionné. Un projet peut créer autant d’objets qu’il le souhaite, mais ne peut pas injecter du code arbitraire dans le runtime.

Règles de cohérence :

- contexts accepte overworld et battle ; deux uses d’un même objet ne peuvent pas se chevaucher sur un contexte ;
- target accepte partyMember, partyMove, world et none ;
- consumption accepte onApplied et never ;
- flat exige un amount strictement positif ; full interdit amount ;
- listed exige au moins un statusId ; all interdit une liste non vide ;
- buyPrice et sellPrice sont des valeurs par défaut de catalogue, jamais une priorité sur un prix authored dans un ShopEntryDefinition ;
- une évolution par objet reste définie dans le catalogue d’évolutions. ItemCatalogSnapshot reçoit un overlay de références d’évolution et ne duplique pas cette règle dans ProjectItemDefinition ;
- heldEffectId référence une capacité déclarée par map_battle ; il ne contient ni classe Dart, ni code, ni payload moteur opaque.

### 5.2 Codec partagé

Le parsing JSON devient une fonction pure de map_core :

    ProjectItemCatalog decodeProjectItemCatalog(Object? json)
    Map<String, Object?> encodeProjectItemCatalog(ProjectItemCatalog catalog)

Les accès fichiers restent dans leurs adaptateurs :

- map_editor lit et écrit via ses repositories ;
- map_runtime lit via un loader borné au projectRoot ;
- map_authoring lit et mute via ProjectSnapshot et transactions ;
- le MCP ne lit jamais directement un chemin arbitraire.

### 5.3 Résolution pure dans map_gameplay

Créer ItemCatalogSnapshot, ItemCapabilityResolver, BagOperations, PlayerItemUseService, ItemUseRequest, ItemUseResult et ItemConsumptionReceipt.

ItemCapabilityResolver répond au minimum :

- l’objet existe-t-il ;
- est-il passif ou utilisable ;
- dans quels contextes ;
- quelle cible est requise ;
- quel effet déterministe appliquer ;
- doit-il être consommé ;
- quelles capacités runtime externes sont requises.

ItemCatalogSnapshot compose la définition d’objet avec les références externes qui restent autoritaires dans leur domaine : règles d’évolution, compatibilité de moves et capability truth des held effects. Cette composition est un read model ; elle ne recopie pas ces données dans le catalogue Item.

### 5.4 Adaptateurs

- map_runtime adapte ItemUseRequest aux menus pause et battle.
- map_battle conserve l’exécution battle pure et reçoit un effet déjà résolu.
- map_editor construit et valide les définitions via des pickers no-code.
- map_authoring possède les mutations sémantiques et le reference index.
- tools/pokemap_mcp transporte les mêmes contrats sans raccourci filesystem.

### 5.5 Cache et performance

- Le catalogue est décodé une fois par révision de projet.
- ItemCatalogSnapshot indexe les définitions par itemId en O(1).
- Aucun menu n’effectue une lecture fichier par ligne de Bag.
- Les diagnostics de catalogue sont calculés une fois et réutilisés.
- Les tests de performance couvrent au moins 5 000 définitions et un Bag de 500 piles sans dépendre du réseau.

## 6. Stratégie de rupture et de bascule

### Étape A — figer le nouveau format

- Définir un schemaVersion obligatoire pour le catalogue et la sauvegarde.
- Définir BagEntry uniquement par itemId et quantity.
- Interdire categoryId dans le catalogue canonique et dans le Bag.
- Définir les erreurs UnsupportedItemCatalogSchema et UnsupportedSaveSchema.

### Étape B — construire le nouveau système isolément

- Accepter uniquement le catalogue canonique strict.
- Résoudre les objets MVP depuis un seed catalog conforme au nouveau schéma.
- N’inférer aucun effet depuis un identifiant, une catégorie ou un texte libre.
- Tester les anciens formats uniquement pour prouver leur refus explicite.

### Étape C — basculer tous les consommateurs

- Remplacer chaque lecture historique par ItemCatalogSnapshot et BagOperations.
- Dériver pocketId et labels exclusivement du catalogue canonique.
- Interdire tout fallback vers PlayerItemEffectRegistry.mvp ou un loader historique.
- Ne publier aucune version hybride acceptant les deux systèmes.

### Étape D — supprimer l’ancien système

- Supprimer les codecs, modèles, registries, guards et fixtures de succès historiques.
- Conserver uniquement des fixtures minimales de rejet de schéma.
- Vérifier par recherche statique qu’aucun categoryId ni fallback ancien ne subsiste dans les chemins produit.
- Certifier uniquement un nouveau projet synthétique et une nouvelle sauvegarde synthétique.

## 7. Vue d’ensemble des phases

| Phase | Total | DONE | TODO | Différé | Lots réalisés | Lots à faire ou différés | Statut |
|---|---:|---:|---:|---:|---|---|---|
| 0 — Vérité et inventaire de rupture | 1 | 1 | 0 | 0 | `ITM-001` | — | DONE |
| 1 — Contrats canoniques | 5 | 5 | 0 | 0 | `ITM-010` à `ITM-014` | — | DONE |
| 2 — Bag transactionnel | 5 | 5 | 0 | 0 | `ITM-020` à `ITM-024` | — | DONE |
| 3 — Consommateurs gameplay | 12 | 11 | 0 | 1 | `ITM-025` à `ITM-027`, `ITM-030` à `ITM-033`, `ITM-035` à `ITM-038` | `ITM-034` — DEFERRED_BY_PRODUCT | DONE_SCOPE_V1 |
| 4 — Producteurs et économie | 5 | 5 | 0 | 0 | `ITM-040` à `ITM-044` | — | DONE |
| 5 — Authoring et MCP | 6 | 6 | 0 | 0 | `ITM-050` à `ITM-055` | — | DONE |
| 6 — Suppression historique | 3 | 3 | 0 | 0 | `ITM-060` à `ITM-062` | — | DONE |
| 7 — Certification | 5 | 1 | 4 | 0 | `ITM-070` | `ITM-071` à `ITM-074` | IN_PROGRESS |
| **Total** | **42** | **37** | **4** | **1** | **Phases 0 à 6 + ITM-070** | **ITM-071 à ITM-074 + ITM-034 différé** | **IN_PROGRESS** |

Le reste à faire immédiatement représente donc 4 lots, tous regroupés dans la phase 7. Le nombre de lots non-DONE est de 5 uniquement si le lot produit différé `ITM-034` est inclus ; ce dernier n’entre pas dans la prochaine vague tant que FG-065 reste DEFERRED.

### 7.1 Preuves Git après rebase

| Phase | Commits rebased de preuve |
|---|---|
| 0 | `a07f0b0a3` |
| 1 | `a42813236` à `df01da0c0` |
| 2 | `963f95403` à `df8efd489` |
| 3 | `0f80d69a8` à `62fa55b94` |
| 4 | `e616cb5a3` à `985c544f5` |
| 5 | `208fdbe19` à `73810116b`, puis intégration post-rebase `dbc93a7dd` |
| 6 | `6f9e454fb`, `091c60a11`, correctif de revue `5db84a28a`, puis clôture `9fb30476f` |
| 7 | — |

Ces identifiants remplacent les hashes antérieurs au rebase. Ils prouvent l’historique de la branche dédiée ; ils ne remplacent pas les commandes fraîches exigées pour clôturer les phases 6 et 7.

Les phases 3 et 4 peuvent avancer en deux flux après ITM-024. Les lots qui modifient save_data.dart, le codec de catalogue ou les registries partagés restent séquentiels.

## 8. Phase 0 — Vérité et inventaire de rupture

### ITM-001 — Matrice de caractérisation inter-contextes

- [x] **Résultat :** verrouiller les divergences actuelles avant correction.
- **Fichiers de test :**
  - packages/map_gameplay/test/item_system_current_behavior_characterization_test.dart
  - packages/map_runtime/test/item_system_current_behavior_characterization_test.dart
  - packages/map_runtime/test/runtime_battle_outcome_apply_test.dart
  - packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
  - packages/map_editor/test/project_new_game_configuration_form_test.dart
- **Observations à verrouiller :**
  - delta HP exact des objets MVP dans chaque contexte ;
  - consommation exacte lors d’un effet ou d’une capture acceptée ;
  - absence de consommation sur no-effect ;
  - chemins actuels fondés sur categoryId, registries ou loaders séparés ;
  - sérialisation actuelle du catalogue et du Bag, uniquement comme inventaire de suppression.
- **Règle :** ces tests caractérisent les sémantiques, pas une promesse de compatibilité ; les assertions portant sur les anciens formats sont supprimées par ITM-060 à ITM-062.
- **Gate :** les tests de caractérisation passent sur le système actuel et chaque chemin destiné à disparaître possède un propriétaire de lot explicite.
- **Dépendances :** aucune.

**Divergences caractérisées :**

- Potion, Super Potion et Max Potion produisent le même delta dans les chemins observés ;
- Hyper Potion soigne 120 HP via PlayerItemOperations mais 200 HP via le wrapper battle historique ;
- la capture reconnaît uniquement itemId poke-ball avec categoryId items ;
- les soins battle reconnaissent uniquement categoryId medicine ;
- un no-effect ne consomme pas l’objet ;
- une capture acceptée consomme exactement une Poké Ball, succès ou échec.

**Inventaire chemin actuel → lot propriétaire :**

| Chemin actuel | Autorité ou dette observée | Lot propriétaire |
|---|---|---|
| packages/map_core/lib/src/models/save_data.dart | BagEntry sérialise categoryId ; Bag.normalized identifie une pile par categoryId et itemId | ITM-020, ITM-023, ITM-062 |
| packages/map_gameplay/lib/src/player_item_effects.dart | Registry MVP codé en dur, résolution hors combat et valeur Hyper Potion à 120 | ITM-012, ITM-022, ITM-026, ITM-061 |
| packages/map_gameplay/lib/src/game_state_mutations.dart | give, purchase, sell et consume propagent ou infèrent une catégorie | ITM-024, ITM-041, ITM-043, ITM-060 |
| packages/map_gameplay/lib/src/new_game_state_builder.dart | initialBag est normalisé avec l’identité historique du Bag | ITM-040, ITM-062 |
| packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart | Classification capture et medicine par chaînes de catégories, puis lookup dans le registry MVP | ITM-025, ITM-027, ITM-060 |
| packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart | Wrappers et valeurs HP dupliqués ; Hyper Potion vaut 200 | ITM-026, ITM-031, ITM-061 |
| packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart | Disponibilité de capture codée sur poke-ball et items | ITM-032, ITM-060 |
| packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart | Consommation de capture recode le couple poke-ball et items | ITM-032, ITM-060 |
| packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart | Pause Bag résout le registry MVP et interprète les catégories | ITM-027, ITM-030, ITM-060, ITM-061 |
| packages/map_runtime/lib/src/application/runtime_move_machine_loader.dart | Loader et modèle de machines séparés du catalogue partagé | ITM-014, ITM-035, ITM-061 |
| packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart | Autorité d’exécution des objets tenus à composer avec le catalogue canonique | ITM-038 |
| packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart | Modèle de catalogue privé, categoryId et effectText non exécutables | ITM-010, ITM-011, ITM-014, ITM-052 |
| packages/map_core/lib/src/models/project_manifest.dart et packages/map_editor/test/project_new_game_configuration_form_test.dart | New Game authoré par projet, mais initialBag utilise encore l’ancien BagEntry | ITM-040, ITM-053, ITM-062 |
| packages/map_authoring/lib et tools/pokemap_mcp | Aucun domaine sémantique item ou bag découvrable dans les contrats live observés | ITM-050 à ITM-055 |

**Verdict ITM-001 :** DONE. Les statuts FG-060 à FG-064 restent inchangés ; leur recertification sur la nouvelle architecture demeure réservée à ITM-074.

**Preuves fraîches du 11 août 2026 :**

| Vérification | Résultat exact |
|---|---|
| `cd packages/map_gameplay && dart test test/item_system_current_behavior_characterization_test.dart test/party_bag_heal_operations_test.dart` | 31 tests réussis |
| `cd packages/map_runtime && flutter test test/item_system_current_behavior_characterization_test.dart test/runtime_battle_outcome_apply_test.dart test/battle_bag_menu_model_test.dart test/runtime_generic_battle_items_v0_test.dart test/wild_battle_end_to_end_flow_test.dart` | 70 tests réussis |
| `cd packages/map_editor && flutter test test/project_new_game_configuration_form_test.dart` | 3 tests réussis |
| `cd packages/map_gameplay && dart analyze` | aucune erreur ; une info préexistante unnecessary_library_name |
| `cd packages/map_runtime && flutter analyze test/item_system_current_behavior_characterization_test.dart` | aucune issue |
| `cd packages/map_editor && flutter analyze test/project_new_game_configuration_form_test.dart` | aucune issue |
| Build applicatif | non applicable : aucun code produit ni configuration de build modifiés |
| Parité MCP | non applicable à ce lot de caractérisation ; l’absence d’exposition item/bag est assignée à ITM-050 à ITM-055 |

**Passes de clôture :** audit des autorités, caractérisation comportementale, contrôle de cohérence des dépendances et auto-critique locale. Aucun sub-agent n’a été utilisé pour ce lot borné.

**État Git initial :** worktree propre sur 96cbaf08a, branche codex/item-system-phase-0.

**Gate de phase 0 :** suites de caractérisation vertes et tableau de correspondance chemin actuel → lot de suppression complet.

## 9. Phase 1 — Contrats canoniques et catalogue strict

### ITM-010 — Modèles Item System V1

- [x] **Résultat :** contrats listés en section 5.1, immuables et sérialisables.
- **Fichiers à créer :**
  - packages/map_core/lib/src/models/items/project_item_catalog.dart
  - packages/map_core/lib/src/models/items/project_item_definition.dart
  - packages/map_core/lib/src/models/items/project_item_effect_definition.dart
  - packages/map_core/lib/src/models/items/project_item_capabilities.dart
- **Fichiers à modifier :**
  - packages/map_core/lib/map_core.dart
- **Tests à créer :**
  - packages/map_core/test/project_item_catalog_model_test.dart
  - packages/map_core/test/project_item_effect_definition_test.dart
- **Cas obligatoires :**
  - round-trip de chaque kind ;
  - contexts vides interdits pour un use ;
  - ratio de capture positif et réduit ;
  - machine HM non consommable ;
  - IDs, pockets et tags normalisés ;
  - effet semanticAction limité à un registre déclaré.
- **Non-goal :** aucune lecture fichier et aucune UI.
- **Gate :** tests ciblés et dart analyze sans nouvelle issue.
- **Dépendances :** ITM-001.

**Preuves ITM-010 :** les 11 tests ciblés passent ; `dart analyze` termine sans erreur ni warning et ne signale aucune nouvelle info dans les fichiers Item System. Les 119 infos remontées appartiennent à la baseline existante du package. Les quatre modèles canoniques et leurs sorties Freezed/JSON sont exportés par `map_core` ; aucun accès fichier, adaptateur ou comportement runtime n'a été ajouté.

### ITM-011 — Codec strict du catalogue canonique

- [x] **Résultat :** un codec partagé accepte uniquement le schemaVersion du nouvel Item System et refuse tout autre format.
- **Fichiers à créer :**
  - packages/map_core/lib/src/serialization/project_item_catalog_codec.dart
- **Tests à créer :**
  - packages/map_core/test/project_item_catalog_codec_test.dart
- **Fixtures à créer :**
  - packages/map_core/test/fixtures/items_catalog_v1_complete.json
  - packages/map_core/test/fixtures/items_catalog_legacy_rejected.json
- **Règles de codec :**
  - schemaVersion 1 obligatoire ;
  - rejet des champs categoryId et effect text legacy ;
  - aucun effet déduit d’un texte libre ;
  - aucun seed ou fallback injecté pendant le décodage ;
  - diagnostics localisés par entry index et itemId.
- **Gate :** round-trip v1 canonique, stabilité d’ordre et rejet typé de chaque ancien format prouvés.
- **Dépendances :** ITM-010.

**Preuves ITM-011 :** les 5 tests du codec et les 16 tests cumulés des contrats passent. Le codec pur exige `schemaVersion: 1`, refuse les champs historiques et les effets en texte libre avec code, chemin, index et itemId, rejette les kinds et champs inconnus, conserve l'ordre des entrées et n'injecte ni seed ni fallback. L'analyse ciblée du codec et de ses tests ne remonte aucune issue.

### ITM-012 — Seed canonique des objets MVP

- [x] **Résultat :** remplacer la Map privée actuelle par des définitions ProjectItemDefinition.
- **Fichiers à créer :**
  - packages/map_gameplay/lib/src/items/mvp_item_catalog.dart
- **Fichiers à modifier :**
  - packages/map_gameplay/lib/src/player_item_effects.dart
  - packages/map_gameplay/lib/map_gameplay.dart
- **Contenu minimal :**
  - quatre Potions ;
  - cures de statuts actuellement supportées ;
  - Full Heal ;
  - Revive ;
  - Ether et Max Ether ;
  - Poké Ball ;
  - key item passif générique.
- **Gate :** aucune valeur n'est dupliquée entre le seed canonique et sa projection overworld ; la convergence avec les wrappers battle, notamment l'écart Hyper Potion 120/200, reste la responsabilité explicite d'ITM-026.
- **Dépendances :** ITM-010.

**Preuves ITM-012 :** le seed canonique contient les 15 objets MVP attendus et `PlayerItemEffectRegistry.mvp` projette ses valeurs depuis les `ProjectItemDefinition` sans Map de valeurs concurrente. Les 34 tests gameplay ciblés et les 21 tests runtime de caractérisation/menu battle passent ; `dart analyze` ne remonte que l'info `unnecessary_library_name` préexistante du barrel. Aucun comportement battle n'a été modifié prématurément.

### ITM-013 — Validation sémantique et capability truth

- [x] **Résultat :** chaque définition annonce honnêtement si toutes ses capacités sont câblées.
- **Fichiers à créer :**
  - packages/map_core/lib/src/validation/project_item_catalog_validator.dart
  - packages/map_core/lib/src/read_models/item_capability_truth.dart
- **Tests à créer :**
  - packages/map_core/test/project_item_catalog_validator_test.dart
- **Diagnostics bloquants :**
  - duplicate itemId ;
  - kind ou version inconnu ;
  - ratio invalide ;
  - cible incompatible avec effet ;
  - heldEffectId non déclaré par la capability truth fournie ;
  - moveId absent ;
  - action sémantique inconnue.
- **Diagnostics non bloquants :**
  - objet passif sans prix ;
  - pocket vide remplacé par fallback de présentation ;
  - champs externes non consommés.
- **Gate :** aucun objet unsupported ne peut être présenté comme runtime-ready.
- **Dépendances :** ITM-011.

**Preuves ITM-013 :** les 6 tests du validator et les 22 tests cumulés des contrats/codec passent ; l'analyse ciblée est sans issue. Le rapport distingue `runtimeReady`, `passive` et `unsupported`, rend bloquants les duplicats, versions/kinds inconnus, ratios, cibles, moveId, held effects et actions sémantiques invalides, et conserve les avertissements de présentation/import non bloquants. Les champs externes sont signalés par l'adaptateur d'import avant écriture ; ils ne sont jamais tolérés silencieusement dans le JSON canonique strict.

### ITM-014 — Loader partagé par ports

- [x] **Résultat :** éditeur et runtime utilisent le même codec sans partager leurs accès fichiers.
- **Fichiers à modifier :**
  - packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart
  - packages/map_editor/lib/src/application/use_cases/sync_pokemon_items_catalog_use_case.dart
  - packages/map_runtime/lib/src/application/runtime_move_machine_loader.dart
- **Fichiers à créer :**
  - packages/map_runtime/lib/src/application/runtime_item_catalog_loader.dart
- **Fichiers d’intégration également modifiés :**
  - packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
  - packages/map_runtime/lib/map_runtime.dart
- **Tests :**
  - packages/map_editor/test/load_pokemon_items_catalog_use_case_test.dart
  - packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart
  - packages/map_runtime/test/runtime_item_catalog_loader_test.dart
- **Gate :** les deux adaptateurs produisent des ProjectItemDefinition égales depuis le même JSON.
- **Dépendances :** ITM-011 et ITM-013.

**Preuves ITM-014 :** les 35 tests ciblés éditeur et les 5 tests ciblés runtime passent. Les deux ports décodent le wire strict avec `decodeProjectItemCatalog`, puis comparent le résultat au même contrat `ProjectItemCatalog` normalisé. Le loader éditeur ne dépend plus du repository générique des anciens catalogues ; le runtime réutilise le loader canonique pour les métadonnées TM/HM. Le synchroniseur convertit les métadonnées externes avant écriture, préserve les capacités gameplay authorées, n’infère aucun effet depuis du texte libre et refuse tout catalogue local legacy sans le réécrire. L’analyse ciblée éditeur est sans issue ; l’analyse runtime réussit avec `--no-fatal-infos` et conserve une seule info préexistante `unnecessary_library_name` sur le barrel.

**Gate de phase 1 :** ITM-010 à ITM-014 sont clôturés. Le catalogue, son codec, le seed MVP, la validation de capacités et les ports éditeur/runtime reposent désormais sur les mêmes contrats stricts. Aucun fallback, lecteur double ou migration automatique vers les anciens formats n’a été ajouté. La bascule du Bag, des saves et des consommateurs gameplay reste explicitement portée par les phases 2 et 3.

## 10. Phase 2 — Bag transactionnel

### ITM-020 — Définir l’identité logique d’une pile

- [x] **Résultat :** toutes les opérations gameplay identifient une pile par itemId.
- **Fichiers à modifier :**
  - packages/map_core/lib/src/models/save_data.dart
  - fichiers générés associés à save_data.dart
- **Tests à créer :**
  - packages/map_core/test/bag_stack_identity_test.dart
- **Cas obligatoires :**
  - mêmes itemId fusionnés ;
  - quantité totale conservée ;
  - ordre stable ;
  - ancien JSON refusé avec UnsupportedSaveSchema ;
  - écriture strictement conforme au nouveau schemaVersion ;
  - overflow de quantité rejeté.
- **Gate :** aucune quantité n’est perdue pendant la normalisation.
- **Dépendances :** ITM-011.

**Preuves ITM-020 :** les 6 tests dédiés et les 65 tests cumulés du Bag, de `SaveData`, de la persistance et du New Game passent. `BagEntry` ne persiste plus que `itemId` et `quantity`, la normalisation fusionne et trie par `itemId`, et tout dépassement de l'int64 signé est refusé avant addition. `SaveData` écrit obligatoirement `itemSystemSchemaVersion: 1` et rejette par `UnsupportedSaveSchema` une version absente ou toute entrée contenant encore `categoryId`. L'analyse ciblée des cinq fichiers source/test concernés ne remonte aucune issue. La suite complète `map_core` a dépassé la limite d'exécution de 120 secondes sans fournir de verdict ; elle n'est donc pas comptée comme preuve de ce lot.

### ITM-021 — BagOperations et receipts atomiques

- [x] **Résultat :** give, take, consume et inspect utilisent une API pure unique.
- **Fichiers à créer :**
  - packages/map_gameplay/lib/src/items/bag_operations.dart
  - packages/map_gameplay/lib/src/items/bag_operation_result.dart
- **Tests à créer :**
  - packages/map_gameplay/test/bag_operations_test.dart
- **Contrats :** BagGiveRequest, BagTakeRequest, BagConsumeRequest, BagOperationResult et ItemConsumptionReceipt.
- **Invariants :**
  - état original conservé sur échec ;
  - quantité positive obligatoire ;
  - receipt identifie itemId, quantité avant/après et raison ;
  - key item consumption refusée sauf politique explicite.
- **Gate :** tests positifs, négatifs, overflow et idempotence.
- **Dépendances :** ITM-020.

**Preuves ITM-021 :** les 8 tests dédiés passent et l'analyse ciblée des deux contrats, de l'implémentation et du test est sans issue. `BagOperations` fournit `give`, `take`, `consume` et `quantityOf` sur l'identité `itemId`, refuse les requêtes invalides, les quantités insuffisantes et l'overflow sans remplacer le Bag original, et protège les key items sauf autorisation explicite. Toute consommation réussie produit un unique `ItemConsumptionReceipt` avec l'identité, les quantités avant/après et la raison ; les échecs idempotents n'émettent aucun receipt.

### ITM-022 — PlayerItemUseService

- [x] **Résultat :** remplacer PlayerItemOperations par un service fondé sur ItemCatalogSnapshot.
- **Fichiers à créer :**
  - packages/map_gameplay/lib/src/items/item_catalog_snapshot.dart
  - packages/map_gameplay/lib/src/items/item_capability_resolver.dart
  - packages/map_gameplay/lib/src/items/player_item_use_service.dart
- **Fichiers à modifier :**
  - packages/map_gameplay/lib/src/player_item_effects.dart
- **Tests à créer :**
  - packages/map_gameplay/test/player_item_use_service_test.dart
- **Cas obligatoires :**
  - heal plat/full ;
  - cure ciblée/any ;
  - revive ;
  - PP single move ;
  - mauvaise cible ;
  - mauvais contexte ;
  - no-effect ;
  - définition inconnue ;
  - receipt de consommation exact.
- **Gate :** le service ne lit ni catégorie, ni fichier, ni dépendance Flutter.
- **Dépendances :** ITM-012 et ITM-021.

**Preuves ITM-022 :** les 19 tests cumulés du snapshot, du catalogue MVP, de `BagOperations` et du nouveau service passent ; l'analyse ciblée des six fichiers source/test est sans issue. `PlayerItemUseService` résout la définition et le contexte via `ItemCatalogSnapshot` et `ItemCapabilityResolver`, applique les heals plats/complets, cures listées/globales, revive et PP ciblés, puis consomme atomiquement selon la policy canonique. Les mauvaises cibles, contextes absents, no-effect, définitions inconnues et stocks insuffisants conservent l'état original et n'émettent aucun receipt. Une recherche ciblée confirme l'absence de `categoryId`, `dart:io`, Flutter, `PlayerItemEffectRegistry` et `PlayerItemOperations` dans le nouveau chemin.

### ITM-023 — Version gate de sauvegarde et diagnostic de rupture

- [x] **Résultat :** accepter uniquement le nouveau schéma de sauvegarde et refuser les anciennes structures sans mutation.
- **Fichiers à créer :**
  - packages/map_gameplay/lib/src/items/save_item_schema_guard.dart
- **Tests à créer :**
  - packages/map_gameplay/test/save_item_schema_guard_test.dart
- **Diagnostic :**
  - schemaVersion détecté ;
  - schemaVersion attendu ;
  - chemin du premier champ incompatible ;
  - code UnsupportedSaveSchema ;
  - état joueur original inchangé.
- **Gate :** nouveau save → save → load est stable ; chaque ancienne fixture est refusée sans produire de nouvel état.
- **Dépendances :** ITM-020 et ITM-021.

**Preuves ITM-023 :** les 2 tests dédiés passent et l'analyse ciblée est sans issue. `SaveItemSchemaGuard` recharge un save V1 canonique en conservant un JSON stable et retourne le `SaveData` et le `GameState` reconstruits. Les fixtures sans version, avec mauvaise version ou avec `categoryId` sont refusées avec le code `UnsupportedSaveSchema`, la version détectée, la version attendue et le premier chemin incompatible ; le résultat conserve exactement l'instance d'état originale et ne produit aucun `SaveData` partiel.

### ITM-024 — Adapter GameStateMutations

- [x] **Résultat :** supprimer les inférences de catégorie de giveItem, rewards, purchase et consume.
- **Fichiers à modifier :**
  - packages/map_gameplay/lib/src/game_state_mutations.dart
  - packages/map_gameplay/lib/src/battle_reward.dart
- **Tests à modifier :**
  - packages/map_gameplay/test/party_bag_heal_operations_test.dart
  - packages/map_gameplay/test/battle_reward_operations_test.dart
  - packages/map_gameplay/test/shop_operations_test.dart
- **Gate :** aucun switch ou if sur un itemId concret ne subsiste dans GameStateMutations.
- **Dépendances :** ITM-021 et ITM-022.

**Preuves ITM-024 :** les 46 tests ciblés de mutations, rewards, shops et caractérisation passent, puis la suite complète `map_gameplay` termine avec 464 tests réussis. `dart analyze` ne remonte aucune erreur ni warning et conserve uniquement l'info préexistante `unnecessary_library_name` du barrel. `GameStateMutations` délègue give, purchase, sell et consume à `BagOperations`, et la vente protège les key items à partir des tags de l'`ItemCatalogSnapshot`. `BattleRewardItemGrant` était déjà strictement défini par `itemId` et `quantity` et n'a requis aucun changement artificiel. Une recherche ciblée ne trouve plus aucun `categoryId`, registre legacy ou identifiant d'objet MVP concret dans `map_gameplay/lib`.

## 11. Phase 3 — Consommateurs gameplay

### ITM-025 — Classifier par capacité canonique

- [x] **Résultat :** le menu battle et la capture utilisent exclusivement la définition canonique, sans categoryId ni fallback par itemId MVP.
- **Fichiers principaux :**
  - packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
  - packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
  - packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
  - packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
- **Tests :**
  - packages/map_runtime/test/item_capability_classification_test.dart
  - packages/map_runtime/test/battle_bag_menu_model_test.dart
  - packages/map_runtime/test/runtime_generic_battle_items_v0_test.dart
- **Règle :** categoryId est absent des entrées runtime et n’intervient dans aucun booléen de support.
- **Gate :** les comportements heal, capture et consommation caractérisés dans ITM-001 restent verts sur le nouveau format.
- **Dépendances :** ITM-014 et ITM-024.

**Preuves ITM-025 :** le runtime charge un `ItemCatalogSnapshot` unique au boot et le transmet au menu battle, aux mappers legacy/PSDK et à l'application générique des medicines. La classification lit `capture` et les `uses` battle de la définition canonique ; un objet nommé `poke-ball` sans capacité de capture reste unsupported, tandis qu'une Ball synthétique dans un pocket arbitraire est reconnue. Les entrées et actions battle n'exposent plus `categoryId`, et les trois suites ciblées totalisent 22 tests réussis. L'analyse statique ciblée des six fichiers de classification/chargement termine sans issue.

### ITM-026 — Unifier les valeurs des effets MVP

- [x] **Résultat :** une seule valeur autoritaire par Potion, cure, revive et restore PP.
- **Fichiers principaux :**
  - packages/map_gameplay/lib/src/player_item_effects.dart
  - packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
  - packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
- **Cas obligatoire :** Hyper Potion produit exactement le même delta hors combat, en battle PSDK et dans le texte de résultat.
- **Gate :** un test paramétré compare les trois chemins pour Potion, Super Potion, Hyper Potion et Max Potion.
- **Dépendances :** ITM-025.

**Preuves ITM-026 :** les wrappers battle legacy et PSDK résolvent désormais leur effet dans le même `ItemCatalogSnapshot` que `PlayerItemUseService` ; les constantes runtime 20/50/200 ont été supprimées. Le test paramétré compare Potion, Super Potion, Hyper Potion et Max Potion sur les chemins overworld, battle legacy, battle PSDK et narration. Les 14 tests ciblés passent, notamment Hyper Potion à 120 PV sur les quatre projections.

### ITM-027 — Diagnostic honnête utilisable/passif/unsupported

- [x] **Résultat :** supprimer l’ambiguïté utilisateur entre un objet passif et une fonctionnalité moteur absente.
- **Fichiers principaux :**
  - packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart
  - packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
  - packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart
- **États produit :**
  - usable ;
  - passive ;
  - unavailableInContext ;
  - invalidDefinition ;
  - unsupportedCapability.
- **Gate :** tests widget/model vérifiant libellé, sélection et raison de désactivation.
- **Dépendances :** ITM-025.

**Preuves ITM-027 :** `ItemUsabilityState` porte les cinq états produit et les projections battle/overworld les exposent avec un libellé et une raison de désactivation distincts. Le menu battle affiche le nom et le pocket du catalogue plutôt qu’un identifiant humanisé ; le sac pause distingue notamment un key item passif, un usage réservé au battle, une définition absente et une action sémantique moteur non supportée. Les 23 tests ciblés de classification, menu battle et projection pause passent, et l'analyse ciblée du builder ne remonte aucune issue.

**Gate de bascule initiale :**

    cd packages/map_runtime
    flutter test test/item_capability_classification_test.dart test/battle_bag_menu_model_test.dart test/runtime_generic_battle_items_v0_test.dart test/wild_battle_end_to_end_flow_test.dart
    flutter analyze

Résultat attendu : exit code 0 et All tests passed.

### ITM-030 — Menu Bag overworld

- [x] **Résultat :** présentation, cible et utilisabilité proviennent de ItemCapabilityResolver.
- **Fichiers à modifier :**
  - packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart
  - packages/map_runtime/lib/src/application/player_service_runtime_controller.dart
- **Tests :**
  - packages/map_runtime/test/player/runtime_player_pause_data_builder_test.dart
  - packages/map_runtime/test/player/runtime_pause_bag_item_service_test.dart
- **Cas obligatoires :** custom pocket, objet passif, objet invalide, mauvaise cible, no-effect et chaque failure reason.
- **Gate :** aucune classification par catégorie et aucune lecture de catalogue déclenchée par une ligne de Bag.
- **Dépendances :** ITM-022 et ITM-014.

**Preuves ITM-030 :** la projection pause et le contrôleur d'usage partagent le catalogue V1 et résolvent présentation, cible, contexte et effet depuis la définition canonique. Le contrôleur ne délègue plus au registre MVP et les CT réutilisent leurs métadonnées déjà chargées au lieu de relire le catalogue. Les tests couvrent un pocket personnalisé, la mauvaise cible sans mutation, un objet passif, une définition absente, un contexte indisponible, une capacité non supportée, un no-effect, une évolution et une CT. Les huit tests ciblés passent et l'analyse statique des deux chemins runtime et de leurs tests ne remonte aucune issue.

### ITM-031 — Objets génériques en combat

- [x] **Résultat :** FG-050 est réellement câblé du Bag au moteur battle.
- **Fichiers à modifier :**
  - packages/map_runtime/lib/src/presentation/flame/battle_bag_menu_model.dart
  - packages/map_runtime/lib/src/presentation/flame/battle_medicine_target_menu_model.dart
  - packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
  - packages/map_battle/lib/src/domain/action/battle_item_action_handler.dart
- **Tests :**
  - packages/map_battle/test/generic_battle_items_v0_test.dart
  - packages/map_runtime/test/runtime_generic_battle_items_v0_test.dart
  - packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
- **Gate :** heal, cure et revive utilisent tous ItemUseResult et un seul receipt de consommation.
- **Dépendances :** ITM-022 et ITM-030.

**Preuves ITM-031 :** le runtime projette d'abord la lineup battle dans le `GameState`, puis délègue heal, cure et revive à `PlayerItemUseService`. Une réussite transporte exactement un `ItemConsumptionReceipt`, et le runtime exige en parallèle exactement un événement `item_consumed` concordant dans la timeline moteur avant le write-back. Trois objets synthétiques dans des pockets arbitraires prouvent le soin, la cure et le revive sans identifiant MVP codé en dur ; les no-effect restent atomiques. La restauration de PP, non encore câblée côté moteur battle, est honnêtement classée unsupported. Les suites ciblées terminent avec 5 tests `map_battle`, 8 tests `map_gameplay`, 29 tests de modèles/application runtime et 17 tests du flux wild réussis ; les analyses ciblées des trois packages ne remontent aucune issue.

### ITM-032 — Capture items génériques

- [x] **Résultat :** la formule reçoit les métadonnées de la Ball choisie.
- **Fichiers à modifier :**
  - packages/map_battle/lib/src/capture_formula.dart
  - packages/map_battle/lib/src/domain/action/battle_capture_action_handler.dart
  - packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart
  - packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
- **Tests :**
  - packages/map_battle/test/battle_capture_formula_test.dart
  - packages/map_battle/test/battle_capture_flow_test.dart
  - packages/map_runtime/test/wild_battle_end_to_end_flow_test.dart
- **Cas minimum :**
  - ratio 1/1 ;
  - ratio supérieur dans un test moteur synthétique, sans livrer une famille de Balls ;
  - item non Ball ;
  - trainer battle ;
  - party pleine ;
  - tentative ratée consommée ;
  - tentative réussie consommée.
- **Gate :** aucune constante de catégorie ou de Ball ne subsiste dans map_runtime.
- **Dépendances :** ITM-013 et ITM-031.

**Preuves ITM-032 :** la décision de capture transporte désormais l'identifiant exact de l'objet choisi et son ratio canonique jusqu'aux moteurs legacy et PSDK. La formule applique ce ratio sous forme rationnelle, puis le runtime valide l'objet contre le catalogue et le type de rencontre avant toute mutation. Une tentative produit exactement un `ItemConsumptionReceipt` concordant avec l'événement moteur, qu'elle échoue ou réussisse ; le stockage d'un Pokémon capturé reste couvert lorsque l'équipe est pleine. Les tests synthétiques prouvent les ratios 1/1 et 5/2 avec `aurora-orb`, ainsi que le rejet des objets non capturants et des combats de dresseur. Les suites ciblées terminent avec 13 tests `map_battle`, 76 tests de modèles/setup/application runtime, 17 tests du flux wild, 10 tests d'intégration post-combat et 9 tests du coordinateur réussis ; les analyses ciblées des deux packages ne remontent aucune issue. La recherche du gate ne trouve plus aucune constante de Ball ou de catégorie dans `packages/map_runtime/lib`.

### ITM-033 — Key Item Gates

- [x] **Résultat :** les conditions gameplay interrogent les capacités du Bag sans consommer l’objet.
- **Fichiers à modifier :**
  - packages/map_gameplay/lib/src/game_state_mutations.dart
  - packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
  - packages/map_gameplay/lib/src/script_condition_evaluator.dart
- **Tests :**
  - packages/map_runtime/test/key_item_door_gate_readiness_test.dart
  - packages/map_gameplay/test/key_item_gate_test.dart
- **Gate :** présence, absence, quantité, invendabilité et save/load sont prouvés.
- **Dépendances :** ITM-021 et ITM-013.

**Preuves ITM-033 :** `BagOperations.quantityOf` est désormais l'unique requête de quantité utilisée par `GameStateMutations`, `ScriptConditionEvaluator` et le writer de conséquences. Le scénario de porte interroge directement `itemQuantityAtLeast` : le pickup ne crée plus de flag miroir, l'ouverture ne consomme pas l'objet et la quantité reste stable. Un objet-clé synthétique dans un pocket libre prouve présence, absence, seuil de quantité, invendabilité malgré un prix de vente authoré et roundtrip save/load. Les suites ciblées terminent avec 33 tests gameplay et 38 tests runtime réussis ; les deux analyses ciblées ne remontent aucune issue.

### ITM-034 — Repel

- [ ] **Statut :** DEFERRED_BY_PRODUCT — ce lot ne rejoint aucune vague d’exécution tant que FG-065 reste DEFERRED.
- **Résultat futur :** un effet repel authored porte une durée en pas et modifie l’évaluation des rencontres.
- **Fichiers à créer ou modifier :**
  - packages/map_gameplay/lib/src/items/repel_state.dart
  - packages/map_gameplay/lib/src/gameplay_encounter.dart
  - packages/map_runtime/lib/src/application/player_service_runtime_controller.dart
- **Tests :**
  - packages/map_gameplay/test/repel_item_effect_test.dart
  - packages/map_runtime/test/player/runtime_repel_item_service_test.dart
- **Décision de lot :** choisir et documenter replace, extend ou reject lorsqu’un Repel est déjà actif.
- **Gate :** activation, décrément, fin, save/load et no-effect sont testés sans RNG réel.
- **Dépendances :** ITM-022.

### ITM-035 — TM/HM unifiées

- [x] **Résultat :** machine metadata est lue depuis ProjectItemDefinition.
- **Fichiers à modifier :**
  - packages/map_runtime/lib/src/application/runtime_move_machine_loader.dart
  - packages/map_gameplay/lib/src/pokemon_move_machine_service.dart
- **Tests :**
  - packages/map_runtime/test/runtime_move_machine_loader_test.dart
  - packages/map_gameplay/test/pokemon_move_machine_service_test.dart
- **Gate :** TM consommable, HM réutilisable, compatibilité, remplacement exact et refus atomique.
- **Dépendances :** ITM-014 et ITM-022.

**Preuves ITM-035 :** `RuntimeMoveMachineLoader` résout exclusivement `ProjectItemDefinition.machine`, puis vérifie la compatibilité TM/HM dans le learnset et la présence de l'attaque dans le catalogue canonique. `PokemonMoveMachineService` délègue la consommation des TM à `BagOperations` et retourne l'unique `ItemConsumptionReceipt`; les HM restent réutilisables. Les tests couvrent apprentissage, PP, remplacement exact, refus atomiques, doublon, save/load, incompatibilité d'espèce et métadonnées invalides. Les suites ciblées terminent avec 4 tests gameplay et 2 tests runtime réussis, et les analyses ciblées ne remontent aucune issue.

### ITM-036 — Objets d’évolution

- [x] **Résultat :** les items d’évolution sont résolus via itemId canonique et le catalogue des règles d’évolution.
- **Fichiers à modifier :**
  - packages/map_runtime/lib/src/application/player_service_runtime_controller.dart
  - packages/map_runtime/lib/src/application/runtime_pokemon_evolution_loader.dart
  - packages/map_gameplay/lib/src/pokemon_evolution_service.dart
- **Tests :**
  - packages/map_runtime/test/player/runtime_pause_bag_item_service_test.dart
- **Gate :** évolution réussie consomme selon policy ; refus ou cible incompatible ne consomme pas.
- **Dépendances :** ITM-022 et ITM-030.

**Preuves ITM-036 :** le contrôleur runtime n'essaie plus de traiter tout objet passif comme une pierre d'évolution : seule une définition canonique portant le tag `evolution` ouvre ce chemin. `RuntimePokemonEvolutionLoader` filtre ensuite les règles typées par l'`itemId` exact et résout l'espèce cible depuis le catalogue Pokémon. `PokemonEvolutionItemOperations` applique l'évolution et la consommation via `BagOperations` en une mutation atomique avec un unique receipt. Les refus, mauvaises cibles, règles incompatibles et objets passifs custom conservent le Pokémon et le Bag. Les suites ciblées terminent avec 16 tests gameplay et 18 tests runtime réussis, et les analyses ciblées ne remontent aucune issue.

### ITM-037 — Equip/unequip d’objets tenus

- [x] **Résultat :** transfert atomique Bag ↔ party member avec persistance.
- **Fichiers à créer :**
  - packages/map_gameplay/lib/src/items/held_item_operations.dart
- **Fichiers à modifier :**
  - packages/map_runtime/lib/src/application/player_service_runtime_controller.dart
  - packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
  - packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart
- **Tests :**
  - packages/map_gameplay/test/held_item_operations_test.dart
  - packages/map_runtime/test/runtime_held_item_bridge_v0_test.dart
- **Cas obligatoires :** equip, swap, unequip, cible invalide, objet absent, held effect inconnu et save/load.
- **Gate :** aucune quantité n’est perdue pendant un swap.
- **Dépendances :** ITM-021 et ITM-013.

**Preuves ITM-037 :** `HeldItemOperations` possède désormais les transactions pures equip, swap et unequip. Chaque chemin compose `BagOperations`, conserve l'état original en cas de cible invalide, objet absent, doublon ou overflow, et ne perd aucune quantité lors d'un échange. Les commandes pause runtime exposent explicitement equip et unequip, refusent les définitions absentes et les objets passifs sans `heldEffectId`, puis sauvegardent une seule fois la mutation réussie. Le bridge battle existant continue de hydrater et réconcilier les objets inchangés, consommés, retirés ou reçus. Les suites ciblées terminent avec 5 tests gameplay et 12 tests runtime réussis, et les analyses ciblées ne remontent aucune issue.

### ITM-038 — Réconciliation avec ItemEffectRegistry battle

- [x] **Résultat :** heldEffectId authored est validé et adapté vers le registry map_battle sans dupliquer les factories.
- **Fichiers à modifier :**
  - packages/map_battle/lib/src/domain/effect/item/item_effect_registry.dart
  - packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart
- **Tests :**
  - packages/map_battle/test/psdk_item_registry_manifest_test.dart
  - packages/map_runtime/test/runtime_held_item_bridge_v0_test.dart
- **Gate :** item passif, held supporté et held non porté ont trois diagnostics distincts.
- **Dépendances :** ITM-013 et ITM-037.

**Preuves ITM-038 :** `ItemEffectRegistry.supportsHeldEffect` concentre désormais la vérité `manifest ported + factory enregistrée`. Le runtime résout l'`itemId` canonique vers le `heldEffectId` authored avant le handoff PSDK et expose quatre états typés : définition absente, passif, supporté et non porté. Les commandes d'équipement refusent séparément les objets passifs et les effets non portés sans mutation. Le write-back post-combat préserve l'`itemId` canonique d'origine ou reconvertit un effet reçu vers une définition canonique unique ; aucun ID moteur n'entre dans le save. Les tests ciblés du registry terminent avec 18 tests réussis et les suites runtime du bridge, du seed builder et du setup mapper avec 58 tests réussis.

**Gate de phase 3 :**

    cd packages/map_gameplay
    dart test test/player_item_use_service_test.dart test/pokemon_move_machine_service_test.dart test/held_item_operations_test.dart
    dart analyze

    cd packages/map_battle
    dart test test/generic_battle_items_v0_test.dart test/battle_capture_formula_test.dart test/battle_capture_flow_test.dart test/psdk_item_registry_manifest_test.dart
    dart analyze

    cd packages/map_runtime
    flutter test test/player/runtime_pause_bag_item_service_test.dart test/runtime_generic_battle_items_v0_test.dart test/wild_battle_end_to_end_flow_test.dart test/runtime_held_item_bridge_v0_test.dart
    flutter analyze

Résultat attendu : exit code 0 pour chaque commande.

## 12. Phase 4 — Producteurs, événements et économie

### ITM-040 — New Game initial Bag

- [x] **Résultat :** le picker ajoute un itemId et laisse pocket et effets au catalogue.
- **Fichiers à modifier :**
  - packages/map_editor/lib/src/ui/canvas/new_game/project_new_game_configuration_sheet.dart
  - packages/map_core/lib/src/models/project_new_game_config.dart
  - packages/map_gameplay/lib/src/new_game_state_builder.dart
- **Tests :**
  - packages/map_editor/test/project_new_game_configuration_form_test.dart
  - packages/map_gameplay/test/project_new_game_state_builder_test.dart
- **Gate :** aucun categoryId hardcodé dans le formulaire ou le builder.
- **Dépendances :** ITM-021 et ITM-014.

**Preuves ITM-040 :** le modèle `ProjectNewGameConfig` persiste exclusivement une liste de `BagEntry(itemId, quantity)`, le formulaire ajoute l'identifiant sélectionné depuis le catalogue guidé et `createNewGameStateFromProject` normalise directement ces stacks sans connaître pocket, catégorie ou effet. La preuve utilise `custom-passive-thread`, un objet synthétique sans sémantique MVP, puis vérifie son round-trip save/load. Les suites ciblées terminent avec 7 tests gameplay et 3 tests editor réussis. La recherche statique de `categoryId` sur le modèle, le formulaire, le builder et leurs tests ne retourne aucun résultat.

### ITM-041 — GiveItem, TakeItem et pickups

- [x] **Résultat :** scripts, scènes et pickups passent par BagOperations.
- **Fichiers à modifier :**
  - packages/map_runtime/lib/src/application/script_command_executor.dart
  - packages/map_runtime/lib/src/application/scenario_runtime/scenario_runtime_executor.dart
  - packages/map_runtime/lib/src/application/scene_runtime/scene_consequence_runtime_writer.dart
- **Tests :**
  - packages/map_runtime/test/item_pickup_give_item_readiness_test.dart
  - packages/map_editor/test/scenes_workspace_shell_test.dart
- **Gate :** pickup unique, take insuffisant, save/reload et objet custom passif.
- **Dépendances :** ITM-024.

**Preuves ITM-041 :** les commandes de script, conséquences de scène et nœuds de scénario délèguent tous leurs mutations à `GameStateMutations`, lui-même adossé à `BagOperations`. `giveItem` rejette désormais une quantité nulle ou négative avant tout commit, tandis que `takeItem` insuffisant reste atomique. Les preuves couvrent un pickup unique de `test_custom_passive_thread`, sa persistance après save/reload, les créations et éditions guidées `giveItem`/`takeItem`, ainsi que l'absence de duplication. Les suites runtime ciblées terminent avec 12 puis 40 tests réussis et les 4 scénarios editor ciblés réussissent. La suite editor complète atteint 80 tests réussis mais reste rouge sur 9 goldens historiques absents du dépôt, sans lien avec ce lot.

### ITM-042 — Battle rewards et trainer rewards

- [x] **Résultat :** les grants portent itemId et quantity ; BagOperations résout l’ajout.
- **Fichiers à modifier :**
  - packages/map_gameplay/lib/src/battle_reward.dart
  - packages/map_gameplay/lib/src/battle_progression_service.dart
  - packages/map_runtime/lib/src/application/runtime_battle_reward_resolver.dart
- **Tests :**
  - packages/map_gameplay/test/battle_reward_model_test.dart
  - packages/map_gameplay/test/battle_reward_operations_test.dart
  - packages/map_runtime/test/runtime_battle_reward_resolver_test.dart
  - packages/map_runtime/test/reward_bridge_readiness_test.dart
- **Gate :** reward inconnue échoue avant application ; aucune mutation partielle.
- **Dépendances :** ITM-024.

**Preuves ITM-042 :** `BattleRewardItemGrant` conserve le contrat strict `itemId + quantity`. `GameStateMutations` valide désormais l'intégralité des grants contre `ItemCatalogSnapshot` avant d'appliquer argent, objets, flags, badge ou aptitude de terrain, puis délègue chaque ajout à `BagOperations`. Une récompense inconnue produit une `BattleRewardApplicationException` typée et le coordinateur runtime refuse de créer la transaction post-combat en préservant l'état original. Les suites ciblées terminent avec 28 tests gameplay et 25 tests runtime réussis ; la suite gameplay complète réussit 474 tests. La suite runtime complète atteint 2 289 tests réussis, 1 test ignoré et 1 échec historique dû au golden `world_map_editor_gate_5_rotation_runtime.png` absent du dépôt.

### ITM-043 — Shops et ventes

- [x] **Résultat :** shops utilisent les prix authored et ItemCapabilityResolver pour pocket, key item et sellability.
- **Fichiers à modifier :**
  - packages/map_core/lib/src/models/shop_definition.dart
  - packages/map_gameplay/lib/src/game_state_mutations.dart
  - packages/map_runtime/lib/src/application/player_service_runtime_controller.dart
- **Tests :**
  - packages/map_gameplay/test/shop_operations_test.dart
  - packages/map_runtime/test/player/runtime_shop_service_test.dart
- **Gate :** achat, vente, key item, stock, custom item et changement de profil restent transactionnels.
- **Dépendances :** ITM-024 et ITM-013.

**Preuves ITM-043 :** achats et ventes exigent le même `ItemCatalogSnapshot` et résolvent la définition canonique via `ItemCapabilityResolver`, tandis que `ShopEntryDefinition.price` et `sellPrice` restent les seules valeurs transactionnelles. Un item présent dans un profil de boutique mais absent du catalogue échoue avant débit, ajout au Bag ou consommation de stock. Les key items restent invendables, les changements de profil sont revérifiés au moment de confirmer et `custom-passive-thread` s'achète avec son prix authored sans sémantique codée en dur. Le runtime conserve le snapshot dans la session de boutique, sans fallback lors de la transaction. Les compteurs de stock utilisent exclusivement `shopId::stateId::itemId`, y compris `default`, sans clé historique de compatibilité. Les suites ciblées terminent avec 32 tests gameplay et 4 tests runtime réussis ; la suite gameplay complète réussit 476 tests.

### ITM-044 — Références et usages d’objets

- [x] **Résultat :** indexer New Game, scènes, scripts, shops, rewards, pickups, machines, évolutions et held items.
- **Fichiers à créer :**
  - packages/map_core/lib/src/read_models/project_item_reference_index.dart
- **Tests à créer :**
  - packages/map_core/test/project_item_reference_index_test.dart
- **Gate :** suppression ou rename d’un item retourne toutes les dépendances avec leur chemin éditable.
- **Dépendances :** ITM-040 à ITM-043.

**Preuves ITM-044 :** `ProjectItemReferenceIndex` fournit une vue immuable, triée et dédupliquée des usages par `itemId`, avec le type de référence, la source, le chemin éditable et le caractère bloquant pour une suppression. L’index collecte les Bags et held items de New Game, les actions et conditions de scènes, les commandes de scripts et scénarios, les profils de shops et leurs conditions, les récompenses et held items de dresseurs, les pickups de maps, les conditions narratives et les capacités machine du catalogue. Les références d’évolution peuvent être composées de façon typée depuis leur autorité externe au manifest core ; elles restent bloquantes, tandis que la capacité machine portée par la définition supprimée ne bloque pas sa propre suppression. La fixture synthétique certifie 17 usages couvrant les 15 catégories, dont 16 dépendances bloquantes, ainsi que les chemins éditables, le tri et la déduplication déterministes. Les suites ciblées terminent avec 50 tests réussis. La suite `map_core` complète atteint 4 114 tests réussis, 1 test ignoré et 7 échecs hors scope ; le premier échec isolé est l’inventaire Smart Tiles qui n’attend pas encore `smart_tile.layer.change_preset` et `smart_tile.layer.set_animation_activation` déjà présents dans le catalogue produit.

## 13. Phase 5 — Authoring no-code et MCP

### ITM-050 — Ressources de lecture Item

- [x] **Résultat :** itemCatalog, itemDefinition, itemUsage et itemReadiness sont queryables.
- **Fichiers à modifier :**
  - packages/map_authoring/lib/src/registry/resource_kind_registry.dart
  - packages/map_authoring/lib/src/workspace/project_query_service.dart
  - packages/map_authoring/lib/src/parity/full_authoring_parity.dart
- **Tests :**
  - packages/map_authoring/test/contracts/query_pagination_test.dart
  - packages/map_authoring/test/parity/full_authoring_parity_test.dart
- **Gate :** list/get/search/summary, field masks, pagination et stabilité de révision.
- **Dépendances :** ITM-014 et ITM-044.

**Preuves ITM-050 :** le snapshot authoring charge le catalogue configuré `pokemon.catalogFiles.items` comme ressource cohérente, fingerprintée et liée à la révision. Un projet qui référence un objet sans catalogue canonique échoue en lecture stricte avec `project.item_catalog_missing`; la projection editor conserve un diagnostic réparable. `itemCatalog`, `itemDefinition`, `itemUsage` et `itemReadiness` sont enregistrés comme ressources queryables et projetés par `ProjectQueryService` avec recherche, filtres, field masks, pagination et chemins éditables issus de `ProjectItemReferenceIndex`. La parité PMCP-085 les exige désormais comme lectures directes. Les suites ciblées terminent avec 47 tests réussis et l’analyse ciblée ne signale aucun problème.

### ITM-051 — Mutations sémantiques Item

- [x] **Résultat :** exposer les actions documentées item.* avec plan/apply et validation.
- **Fichiers à créer :**
  - packages/map_authoring/lib/src/domains/gameplay/item_catalog_actions.dart
  - packages/map_authoring/test/domains/gameplay/item_catalog_actions_test.dart
- **Actions minimales :**
  - item.create ;
  - item.update ;
  - item.clone ;
  - item.delete_plan ;
  - item.delete_apply ;
  - item.set_overworld_effect ;
  - item.set_battle_effect ;
  - item.set_held_effect ;
  - item.set_capture_effect ;
  - item.set_tm_hm_move ;
  - item.validate ;
  - item.simulate.
- **Gate :** atomicité, dry-run, expectedRevision, idempotence, undo et dépendances de suppression.
- **Dépendances :** ITM-050.

**Preuves ITM-051 :** neuf mutations durables `item.*` sont enregistrées dans le dispatcher canonique : création, remplacement, clone, suppression confirmée et configuration séparée des usages overworld/battle, held, capture et machine. Chaque plan remplace atomiquement l’unique ressource `itemCatalog`, avec pre-image exacte, CAS de révision, diff, dry-run, idempotence et undo fournis par le pipeline journalisé. `item.delete_apply` refuse toute dépendance bloquante et retourne ses chemins éditables. Les opérations sans écriture `item.delete_plan`, `item.validate` et `item.simulate` restent volontairement des query actions discoverables afin de ne jamais fabriquer une fausse mutation. Les suites ciblées terminent avec 40 tests réussis et l’analyse ciblée ne signale aucun problème.

### ITM-052 — Item Studio no-code

- [x] **Résultat :** créer et éditer un objet sans JSON ni ID brut.
- **Fichiers à créer :**
  - packages/map_editor/lib/src/features/gameplay/items/item_studio_workspace.dart
  - packages/map_editor/lib/src/features/gameplay/items/item_catalog_list.dart
  - packages/map_editor/lib/src/features/gameplay/items/item_definition_editor.dart
  - packages/map_editor/lib/src/features/gameplay/items/item_effect_editor.dart
  - packages/map_editor/lib/src/features/gameplay/items/item_readiness_panel.dart
- **Expérience minimale :**
  - recherche et filtres ;
  - identité, pocket, prix et présentation ;
  - contextes, cible, consumption policy et effet ;
  - capture, machine et held ;
  - usages et diagnostics ;
  - preview/simulation.
- **Règle UI :** design system et tokens uniquement.
- **Tests à créer :**
  - packages/map_editor/test/item_studio_workspace_test.dart
  - packages/map_editor/test/item_definition_editor_test.dart
- **Gate :** création, édition, erreur inline, undo et reload.
- **Dépendances :** ITM-051.

**Preuves ITM-052 :** la route Items du workspace Pokédex ouvre désormais un Item Studio fondé sur `AuthoringQueryAdapter` et `AuthoringMutationAdapter`, et non sur le loader privé historique. Le Studio pagine les ressources `itemDefinition`, `itemReadiness` et `itemUsage`, puis exécute `item.create`, `item.update`, `item.simulate` et l'undo canonique avec révision attendue et receipt journalisée. L'identité est générée depuis le nom ; pockets, contextes, cibles, consommation, effets, capture, machine et held passent par des contrôles guidés du design system. Les choix machine et held proviennent uniquement des capacités déjà déclarées dans le catalogue canonique ; aucun ID libre ni source privée n'est utilisé pour combler un manque. Les tests widget couvrent création, édition, validation inline, erreur de mutation, reload, undo et les capacités ; la suite ciblée avec les guardrails design system et la caractérisation de l'ancien panneau termine avec 31 tests réussis. L'analyse ciblée ne signale aucun problème.

### ITM-053 — Pickers contextuels cohérents

- [x] **Résultat :** chaque écran filtre les objets par capacité réelle.
- **Surfaces :** New Game, give/take item, rewards, shops, machines, held items et capture preview.
- **Tests :**
  - suites widget existantes de chaque surface ;
  - packages/map_editor/test/item_capability_picker_test.dart.
- **Gate :** aucun picker normal ne demande categoryId ou itemId brut.
- **Dépendances :** ITM-052.

**Preuves ITM-053 :** `ItemCapabilityPicker` projette exclusivement les `ProjectItemDefinition` prêtes et filtre les usages monde, combat, capture, machine et held depuis leurs capacités canoniques, sans catégorie heuristique. Une référence existante devenue indisponible reste réparable sous un libellé neutre qui n'affiche jamais son ID brut. New Game, give/take item, récompenses de dresseur, boutiques et objets tenus utilisent désormais ce contrat ; les catalogues Scene et Shop proviennent du gateway authoring canonique. Le fallback d'ID brut des objets tenus a été supprimé, tandis que les filtres Capture et Capsule du Studio et le picker partagé certifient leurs capacités dédiées. Les suites ciblées des pickers, du New Game, des boutiques, des dresseurs et des conséquences Scene terminent avec 37 tests réussis ; l'analyse ciblée et le guardrail design system ne signalent aucun problème.

### ITM-054 — Transport JSONL/CLI et MCP

- [x] **Résultat :** les ressources/actions Item traversent direct API, CLI, editor et MCP.
- **Fichiers à modifier :**
  - packages/map_authoring/lib/src/tooling/jsonl_worker.dart
  - packages/map_authoring/lib/src/registry/action_registry.dart
  - packages/map_authoring/lib/src/registry/mutation_registry.dart
  - packages/map_authoring/lib/src/registry/resource_kind_registry.dart
  - packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart
  - tools/pokemap_mcp/src/authoring_client.ts
- **Tests :**
  - packages/map_authoring/test/parity/full_authoring_parity_test.dart
  - packages/map_authoring/test/domains/gameplay/item_catalog_jsonl_test.dart ;
  - tools/pokemap_mcp/test/item_authoring.test.ts.
- **Gate :** describe live annonce item resources/actions et chaque transport possède une preuve end-to-end.
- **Dépendances :** ITM-051 et ITM-052.

**Preuves ITM-054 :** les adaptateurs génériques JSONL, Editor et MCP acheminaient déjà les contrats canoniques sans branche spécifique au domaine Item. Les preuves end-to-end ouvrent un vrai projet strict, annoncent les quatre ressources Item et les neuf mutations durables, interrogent la simulation canonique, appliquent `item.create`, relisent le résultat et vérifient l'undo côté Editor. Le registre de parité associe désormais chaque action `item.*` aux quatre transports `directApi`, `cli`, `editor` et `mcp`. Les suites ciblées Authoring terminent avec 11 tests réussis, le test Editor avec 1 test réussi et le test MCP avec 1 test réussi ; le build TypeScript termine sans erreur.

### ITM-055 — Séparer authoring et mutation de save

- [x] **Résultat :** ne pas confondre actions item.* de projet avec commandes Bag d’un joueur.
- **Décision contractuelle :**
  - item.* modifie le catalogue du projet ;
  - campaign.new_game.update configure le Bag initial ;
  - les commandes Bag de playtest passent par un service de session borné ;
  - le MCP authoring ne modifie jamais arbitrairement une sauvegarde utilisateur.
- **Tests :**
  - permissions ;
  - workspace ownership ;
  - refus d’un bag.give sans session de playtest ;
  - aucune écriture hors projectRoot.
- **Gate :** catalog mutations et player-state mutations ont des permissions et receipts distincts.
- **Dépendances :** ITM-054.

**Preuves ITM-055 :** `PlaytestPlayerStateService` est l'unique frontière publique pour `bag.give` et `bag.consume` côté playtest. Il exige une session vivante liée aux mêmes `WorkspaceHandle` et `ProjectHandle`, sépare `playtest.run` de `playtest.control`, réserve atomiquement chaque identifiant de session et libère les sessions terminales après un échec de commande ou d'arrêt. Il n'accepte aucun chemin de sauvegarde et retourne un receipt non durable `playtest_player_state`. Les deux commandes traversent réellement `RuntimePlaytestPort`, `EvaluationPlaytestDriver` et l'unique `EvaluationCommandDispatcher` avant d'appliquer `GameStateMutations` ; `item.*` et `campaign.new_game.update` restent des mutations de projet avec `project.write` et receipts authoring journalisés. L'ancien catalogue de descripteurs `sandbox.*`, non exécutable, a été supprimé sans alias. Le describe MCP n'annonce aucune mutation Bag ; `bag.give` et `sandbox.bag.give` sont refusés avec le code `map.action_unsupported`, y compris avec un `savePath`, sans modifier le fichier témoin hors `projectRoot`. Le catalogue canonique accompagne désormais toute requête shop jusqu'au host et les stocks utilisent exclusivement la clé `shopId::stateId::itemId`, sans cas spécial historique. Après rebase, la suite `map_authoring` complète termine avec 562 tests réussis et `dart analyze` sans problème. Les preuves runtime et host ciblées du lot terminaient respectivement avec 12 et 10 tests réussis ; la validation post-rebase confirme à nouveau les 12 tests runtime et le scénario host borné. La suite MCP sérialisée du lot termine avec 42 tests réussis en 195,4 secondes ; les deux scénarios Item/playtest repassent après rebase et `npm run check` ne signale aucune erreur TypeScript.

**Gate de phase 5 :** DONE. ITM-050 à ITM-055 sont clôturés, les quatre transports sont couverts et les mutations de catalogue restent séparées des mutations temporaires de session joueur. Le rebase a conservé les ressources Item et les nouveaux contrats de présentation de `main`; le commit d’intégration `dbc93a7dd` réconcilie le barrel local, le registre de ressources et le golden JSONL. Aucun droit d’écriture arbitraire dans une sauvegarde utilisateur n’a été introduit.

## 14. Phase 6 — Suppression totale des chemins historiques

**Statut de phase :** DONE. ITM-060 à ITM-062 sont clôturés. Les occurrences `categoryId` propres aux catégories visuelles, Smart Tiles ou imports externes ne relèvent pas de ce nettoyage ; seuls le wire Bag et les décisions Item gameplay étaient concernés.

### ITM-060 — Retirer les guards de catégories

- [x] **Résultat :** aucune décision gameplay ne dépend de medicine, items, healing ou standard-balls.
- **Nettoyage de caractérisation :** transférer les assertions métier toujours valides vers les suites canoniques, puis supprimer les assertions et fixtures qui décrivent le succès des anciens formats dans :
  - packages/map_gameplay/test/item_system_current_behavior_characterization_test.dart
  - packages/map_runtime/test/item_system_current_behavior_characterization_test.dart
- **Commande de preuve :**

    rg -n "categoryId.*(medicine|items)|standard-balls|healing" packages/map_gameplay/lib packages/map_runtime/lib packages/map_battle/lib

- **Résultat attendu :** aucun résultat dans les chemins produit ; seules les fixtures de rejet de schéma peuvent contenir ces chaînes.
- **Dépendances :** ITM-030 à ITM-043, hors ITM-034 tant que FG-065 reste DEFERRED.

**Preuves ITM-060 :** les deux suites `item_system_current_behavior_characterization_test.dart`, créées pour ITM-001, ont été supprimées après comparaison avec les suites canoniques. Les valeurs et métadonnées MVP restent couvertes par `mvp_item_catalog_test.dart`, l’application et la consommation par `player_item_use_service_test.dart`, et la classification runtime par capacité par `item_capability_classification_test.dart`, `battle_bag_menu_model_test.dart` et `runtime_generic_battle_items_v0_test.dart`. Les 11 tests gameplay et les 24 tests runtime de remplacement passent ; les analyses ciblées des chemins Item gameplay et runtime ne remontent aucune issue. La recherche statique ciblée ne trouve ni décision `categoryId`/`pocketId` sur les anciennes valeurs, ni fichier de caractérisation transitoire restant. Les occurrences de `medicine` ou `healing` conservées dans les définitions canoniques sont des métadonnées de présentation ou des tags, jamais des branches métier.

### ITM-061 — Retirer les registries et wrappers dupliqués

- [x] **Résultat :** PlayerItemEffectRegistry.mvp et les wrappers Potion historiques ne sont plus des autorités.
- **Fichiers visés :**
  - packages/map_gameplay/lib/src/player_item_effects.dart
  - packages/map_runtime/lib/src/application/runtime_battle_bag_hp_heal_item_apply.dart
- **Règle :** aucune façade temporaire, aucun alias et aucun fallback historique ne subsiste dans l’API publique.
- **Gate :** recherche d’identifiants et valeurs MVP sans duplication.
- **Dépendances :** ITM-031 et ITM-012.

**Preuves ITM-061 :** l’enum `BattleBagHpHealItemKind`, les quatre méthodes `apply*PotionTurn`, les quatre wrappers runtime Potion et le fallback qui transformait tout identifiant HP inconnu en Potion ont été supprimés sans alias. `BattleBagHpHealItemUse` transporte désormais `itemId`, `displayName`, la cible et l’effet canonique ; le moteur applique une unique commande générique et les adaptateurs legacy/PSDK délèguent à `PlayerItemUseService`, qui conserve l’atomicité entre effet et consommation. Un garde statique map_core refuse la réintroduction des registries et façades supprimés. Une revue indépendante a détecté que la policy canonique `never` restait refusée après l’application de l’effet ; le correctif propage maintenant la policy aux deux moteurs, conserve le Bag avec un receipt nul et émet `item_used` au lieu de `item_consumed`. La contre-revue ne conserve aucun finding Critical ou Important. Les 47 tests map_battle, les 19 tests runtime Item, les 56 tests de l’overlay et les 17 tests du flux sauvage passent. `dart analyze` est propre dans map_battle et l’analyse ciblée des fichiers runtime touchés est propre ; l’analyse complète runtime ne remonte que trois infos préexistantes hors périmètre. La recherche statique produit ne trouve aucun identifiant historique interdit.

### ITM-062 — Supprimer définitivement l’ancien wire Bag

- [x] **Résultat :** categoryId et tous les décodeurs de l’ancien Bag sont physiquement absents du modèle, du codec et du runtime.
- **Preuves requises :**
  - recherche statique sans lecture ou écriture categoryId dans les chemins produit ;
  - nouveau BagEntry sérialisé uniquement avec itemId et quantity ;
  - ancienne fixture refusée par UnsupportedSaveSchema ;
  - aucune API de migration ou de conversion exportée ;
  - golden save conforme au nouveau schemaVersion.
- **Issue acceptable :** retrait complet uniquement.
- **Interdit :** maintenir un champ ignoré, un alias de décodage ou un fallback silencieux.
- **Dépendances :** ITM-060 et ITM-023.

**Preuves ITM-062 :** `save_data.dart` ne connaît plus aucun nom de champ historique. Le décodeur accepte uniquement les clés `itemId` et `quantity` pour chaque `BagEntry` et transforme toute autre clé en `UnsupportedSaveSchema` avec un chemin déterministe, sans mutation par `SaveItemSchemaGuard`. Le test a d’abord échoué sur la connaissance explicite de `categoryId` et sur l’acceptation silencieuse d’un champ arbitraire, puis il est repassé après le remplacement par la liste blanche canonique. La fixture `packages/map_core/test/fixtures/item_system_v1_save.json` prouve un save V1 chargé et réémis avec `itemSystemSchemaVersion: 1` et les deux seules clés autorisées. Le garde statique ne trouve ni `categoryId` dans `save_data.dart` et ses fichiers générés, ni API `LegacyBag`, `migrateBag` ou `convertBag` ; l’ancienne forme ne subsiste que dans les tests de rejet et de garde. Les suites ciblées terminent avec 69 tests map_core, 57 tests map_gameplay, 20 tests runtime save/load et 5 tests du host réussis. Les analyses ciblées des fichiers touchés sont propres ; les analyses complètes map_core et map_gameplay ne remontent respectivement que 121 et 1 infos préexistantes, sans erreur.

**Gate de phase 6 :** DONE. Les décisions gameplay ne dépendent plus des catégories, les effets combat n’ont plus de façade par Potion et le wire Bag ne possède aucun lecteur de compatibilité. ITM-070 peut commencer sans s’appuyer sur une API ou une fixture historique.

## 15. Phase 7 — Certification et clôture

**Statut de phase :** IN_PROGRESS. ITM-070 est clôturé ; ITM-071 doit maintenant exécuter le scénario déterministe sur cette fixture sans réintroduire de façade historique.

### ITM-070 — Fixture Golden Item System

- [x] **Résultat :** créer un mini-projet synthétique, générique et repo-owned.
- **Emplacement :**
  - examples/playable_runtime_host/golden_item_system/
- **Contenu :**
  - une map minimale ;
  - un Pokémon joueur et un adversaire capturable ;
  - Potion, cure, Revive, Ether, Poké Ball minimale, key item, TM, held item et objet passif custom ;
  - pickup, shop, reward et save/reload.
- **Interdit :** dépendre d’un nom, chemin, asset ou état d’un projet utilisateur.
- **Dépendances :** ITM-062.

**Preuves ITM-070 :** `examples/playable_runtime_host/golden_item_system/` contient un projet V6 autonome avec une map sans tileset externe, un Pokémon joueur, un adversaire sauvage capturable, un trainer à reward, une boutique et un walkthrough borné. Son catalogue Item System `schemaVersion: 1` couvre Potion, cure, Revive, Ether, Poké Ball, key item, TM, held item et passif custom ; le Bag initial n’écrit que `itemId` et `quantity`. Le pickup Ether est une vraie entité `kind: item` reliée à un scénario `sourceEntityInteract -> giveItem -> setFlag -> completeStep`, et non une simple instruction déclarative du walkthrough. Le test `golden_item_system_fixture_test.dart` charge et valide le manifeste et la map via les loaders runtime, charge et valide le catalogue via le codec strict partagé, exige les références canoniques `mapPickup` et `scenarioGive`, puis vérifie les douze étapes du scénario. `flutter test test/golden_item_system_fixture_test.dart` termine avec 1 test réussi ; aucun chemin, asset ni état d’un projet utilisateur n’est référencé.

### ITM-071 — Golden flow automatisé

- [ ] **Résultat :** prouver la chaîne complète.
- **Scénario :**
  1. créer une nouvelle partie ;
  2. recevoir des objets initiaux ;
  3. ramasser un objet ;
  4. soigner hors combat ;
  5. acheter puis vendre ;
  6. utiliser un objet en combat ;
  7. tenter une capture ;
  8. équiper un held item ;
  9. apprendre une capacité par TM ;
  10. obtenir une reward ;
  11. sauvegarder et recharger ;
  12. vérifier quantités, party, held item, moves et progression.
- **Test à créer :**
  - examples/playable_runtime_host/test/golden_item_system_flow_test.dart
- **Gate :** aucun accès réseau, RNG injecté, résultat déterministe.
- **Dépendances :** ITM-070.

### ITM-072 — Certification produit

- [ ] **Résultat :** intégrer le domaine aux niveaux de preuve L0-L6.
- **Fichiers à modifier :**
  - tools/pokemap_product_certification/lib/pokemap_product_certification.dart
  - tools/pokemap_product_certification/test/item_system_certification_test.dart
- **Axes :** schema, authoring, persistence, runtime, player UX, MCP parity et golden flow.
- **Gate :** aucune capacité Item n’est CERTIFIED sur un simple test de modèle.
- **Dépendances :** ITM-071 et ITM-054.

### ITM-073 — Matrice finale de validation

- [ ] **Résultat :** exécuter les suites packages dans l’ordre.

    cd packages/map_core && dart test && dart analyze
    cd packages/map_gameplay && dart test && dart analyze
    cd packages/map_battle && dart test && dart analyze
    cd packages/map_authoring && dart test && dart analyze
    cd packages/map_runtime && flutter test && flutter analyze
    cd packages/map_editor && flutter test && flutter analyze
    cd examples/playable_runtime_host && flutter test && flutter analyze
    cd tools/pokemap_mcp && npm test && npm run check

- **Builds :**

    cd packages/map_editor && flutter build macos --debug
    cd examples/playable_runtime_host && flutter build macos --debug

- **Gate :** résultats exacts consignés ; toute dette préexistante séparée du scope.
- **Dépendances :** ITM-072.

### ITM-074 — Recertification de la roadmap mécanique

- [ ] **Résultat :** proposer les statuts FG avec preuves fraîches.
- **Lots à auditer :**
  - FG-050 ;
  - FG-060 à FG-070 ;
  - FG-072 et FG-073 ;
  - FG-074 à FG-079 pour non-régression shops.
- **Règle :** FG-065 et FG-066 conservent leur décision produit DEFERRED tant que cette décision n’est pas explicitement changée ; la capture minimale reste néanmoins certifiée.
- **Gate :** chaque statut cite fichiers, commandes, résultats, limites et scénario de preuve.
- **Dépendances :** ITM-073.

## 16. Vagues d’exécution recommandées

| Vague | Lots | Statut | Peut être parallélisé logiquement | Point de synchronisation |
|---|---|---|---|---|
| A | ITM-001 | DONE | Non | Inventaire de rupture |
| B | ITM-010 → ITM-014 | DONE | ITM-012 et ITM-013 après ITM-011 | Codec partagé |
| C | ITM-020 → ITM-024 | DONE | ITM-022 et ITM-023 après ITM-021 | Bag API stable |
| D1 | ITM-025 → ITM-038 hors ITM-034 différé | DONE_SCOPE_V1 | Classification, capture, machines et held après resolver | Consommateurs |
| D2 | ITM-040 → ITM-044 | DONE | Rewards et shops après BagOperations | Producteurs |
| E | ITM-050 → ITM-055 | DONE | UI après actions ; transports après contrats | Parité |
| F | ITM-060 → ITM-062 | DONE | Non | Suppression historique |
| G | ITM-070 → ITM-074 | IN_PROGRESS — ITM-070 DONE | Non | Certification |

Une vague n’autorise pas plusieurs modifications concurrentes du même modèle généré, du même codec ou de save_data.dart.

## 17. Matrice de preuve obligatoire

| Capacité | Core | Gameplay | Runtime | Editor | Authoring/MCP | Golden |
|---|---:|---:|---:|---:|---:|---:|
| Catalogue V1 | requis | requis | requis | requis | requis | requis |
| Bag give/take | requis | requis | requis | picker | service borné | requis |
| Heal/cure/revive | contrat | requis | requis | preview | simulate | requis |
| PP | contrat | requis | requis | preview | simulate | requis |
| Capture | contrat | effet résolu | requis | preview | simulate | requis |
| Key item | contrat | requis | requis | picker | usages | requis |
| Repel | contrat futur | DEFERRED | DEFERRED | DEFERRED | DEFERRED | DEFERRED |
| TM/HM | contrat | requis | requis | picker | validate | requis |
| Held item | contrat | requis | requis | picker | validate | requis |
| Shops/rewards | référence | requis | requis | requis | requis | requis |
| Save schema gate | codec strict | requis | requis | diagnostic | N/A | requis |

N/A signifie réellement non applicable ; il ne doit pas masquer une exposition absente.

## 18. Risques et garde-fous

### Risque 1 — Refaire un mega-registry

**Garde-fou :** map_core porte les données, map_gameplay la résolution pure, map_battle l’exécution battle et les adapters l’IO. Aucun package ne devient propriétaire de tout.

### Risque 2 — Rendre la rupture ambiguë ou silencieuse

**Garde-fou :** schemaVersion obligatoire, erreurs typées, aucune transformation automatique et fixtures anciennes conservées uniquement pour vérifier leur refus.

### Risque 3 — Confondre import externe et sémantique PokeMap

**Garde-fou :** les champs externes restent des données importées ; seuls les blocs gameplay versionnés sont exécutables.

### Risque 4 — Afficher des milliers d’objets comme utilisables

**Garde-fou :** capability truth, états passif/unavailable/unsupported et filtres contextuels.

### Risque 5 — Duplications de valeurs

**Garde-fou :** seed canonique, tests de parité inter-contextes et retrait des wrappers historiques.

### Risque 6 — MCP de façade

**Garde-fou :** aucune clôture sans describe live, query réelle, plan/apply et tests des quatre transports.

### Risque 7 — Roadmap trop large pour une seule livraison

**Garde-fou :** chaque phase produit un système utilisable ; Phase 0 répare la régression sans attendre Item Studio, et aucune phase ne nécessite une PR monolithique.

## 19. Limites explicitement conservées

- Les effets non supportés par map_battle restent hors scope tant qu’ils n’ont pas leur propre lot.
- Le scripting arbitraire d’effets d’objets n’est pas introduit.
- Les familles complètes de Balls et Repel restent soumises aux décisions produit de la roadmap mécanique.
- Les projets, catalogues et sauvegardes de l’ancien système ne sont ni supportés, ni migrés, ni convertis par cette roadmap.
- Aucun nettoyage sans rapport avec Item System n’est autorisé.
- Aucun changement visuel du battle HUD n’est prévu hors états et diagnostics nécessaires.
- categoryId a été supprimé physiquement du wire Bag par ITM-062 ; aucun mode de compatibilité ne peut le réintroduire.

## 20. Checklist de clôture d’un lot

- [ ] Audit du lot et état Git initial consignés.
- [ ] Test positif écrit avant implémentation lorsque possible.
- [ ] Cas négatif et garde-fou couverts.
- [ ] Refus explicite des anciens formats couvert.
- [ ] Tests ciblés exécutés avec résultat exact.
- [ ] Suite package exécutée ou raison précise de non-exécution.
- [ ] Analyse exécutée.
- [ ] Build exécuté lorsqu’une application ou un transport compilable est touché.
- [ ] Parité MCP évaluée.
- [ ] Aucun fichier hors scope modifié.
- [ ] État Git final consigné.
- [ ] Statut ITM et proposition de statut FG rapportés sans les maquiller.

## 21. Prochaine exécution

Cette roadmap continue d’être exécutée lot par lot, avec un checkpoint après chaque lot de certification.

1. **ITM-071 — golden runtime flow :** enchaîner les usages Item sur la fixture ITM-070 et produire une preuve exécutable réutilisable par la certification.
2. **ITM-072 — certification produit :** raccorder schema, authoring, persistence, runtime, UX joueur, MCP et golden flow aux niveaux de preuve L0-L6.
3. **ITM-073 — matrice finale de validation :** exécuter toutes les suites, analyses et builds prévus en séparant explicitement les dettes préexistantes.
4. **ITM-074 — recertification mécanique :** proposer les statuts FG finaux uniquement à partir des preuves fraîches de la golden slice et de la matrice complète.

ITM-034 reste différé et ne doit pas être glissé discrètement dans la certification sous prétexte qu’un Repel « n’a pas l’air bien méchant » — c’est exactement ainsi que les petits lots se transforment en marécages.
