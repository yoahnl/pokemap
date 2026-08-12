# PokeMap Item System V1 — Roadmap d’implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development when explicitly authorized, or executing-plans for an execution inline. Implémenter cette roadmap lot par lot, suivre les cases à cocher et ne jamais effectuer d’opération Git d’écriture sans autorisation explicite.

**Goal:** Construire un système d’objets cohérent, project-owned et extensible dans lequel le catalogue, le Bag, l’overworld, les combats, la capture, les boutiques, les récompenses, l’éditeur et le MCP consomment une définition canonique unique.

**Architecture:** Introduire dans map_core des contrats d’objets exécutables et un codec de catalogue strict, puis résoudre leurs capacités dans map_gameplay sans dépendre de Flutter ou de Flame. Les pockets restent des métadonnées de présentation ; aucun comportement ne dépend d’une chaîne de catégorie. Le changement est une rupture assumée : seuls le catalogue et les sauvegardes du nouvel Item System sont acceptés, sans lecteur, adaptateur ou migration pour les anciens formats.

**Tech Stack:** Dart 3, Flutter, Freezed/JSON selon les conventions locales, map_core, map_gameplay, map_battle, map_runtime, map_authoring, map_editor, JSONL/CLI, PokeMap MCP et outils de certification produit.

---

## 1. Statut, autorité et règle de portée

- [ ] PARTIAL — la phase 8 clôt la certification technique L0-L3, L5 et L6 par des receipts exécutés ; L4 et les parcours produit de phase 9 restent à fermer.
- Dernière mise à jour : 12 août 2026, après exécution de la phase 8 et recertification complète des preuves et transports.
- Avancement : 51 lots DONE, 1 lot PARTIAL, 6 lots TODO et 1 lot DEFERRED_BY_PRODUCT sur 59 lots uniques.
- Phases : 8 phases clôturées, 1 phase PARTIAL et 1 phase TODO sur 10.
- Travail restant : `ITM-085` reste PARTIAL tant que le serveur MCP global configuré n’est pas rechargé sur le build courant ; 6 lots produit (`ITM-100` à `ITM-105`) restent TODO. `ITM-034` reste différé et exige une nouvelle décision produit.
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

### 2.1 État livré après la phase 8

| Domaine | État au 11 août 2026 | Autorité actuelle |
|---|---|---|
| Catalogue et codec | DONE — schéma V1 strict, définitions exécutables, validation et ports partagés | `ProjectItemCatalog` dans map_core |
| Bag et sauvegarde | DONE — piles par itemId, opérations atomiques, receipts, wire strict itemId/quantity et refus typé de tout ancien champ | `BagOperations` et `UnsupportedSaveSchema` |
| Gameplay | DONE sur le périmètre V1 — overworld, battle, capture minimale, key items, TM/HM, évolution et held items | `ItemCatalogSnapshot`, `ItemCapabilityResolver` et services spécialisés |
| Producteurs et économie | DONE — New Game, événements, pickups, rewards et shops utilisent les contrats canoniques | `BagOperations` et `ProjectItemReferenceIndex` |
| Authoring et MCP | DONE techniquement — les neuf mutations produisent 36 receipts distincts sur direct API, JSONL, Editor et MCP officiel ; seul le reload du serveur MCP global configuré reste PARTIAL | map_authoring, adaptateurs de transport et runner L5 |
| Suppression historique | DONE — décisions par catégorie, registries, wrappers dupliqués et ancien wire Bag retirés | ITM-060 à ITM-062 |
| Certification produit | PARTIAL produit — L0-L3, L5 et L6 sont CERTIFIED par exécution ; L4 reste PARTIAL jusqu’aux parcours joueur held item et HM | runner Item System V1 de `pokemap_product_certification` |

### 2.2 Décision de continuation

ITM-060 à ITM-062 ont retiré les décisions historiques par catégorie, les registries, les wrappers devenus inutiles et l’ancien wire Bag. ITM-070 et ITM-071 fournissent une fixture stricte et un flow L6 réellement exécuté par les API de production. La phase 8 a supprimé le faux positif de parité, exécuté les neuf actions `item.*` sur les quatre transports, lié chaque preuve au commit, à la fixture et à l’état observé, puis introduit des collectors réels pour L0-L3 et L5. Le runner reproductible certifie désormais L0-L3, L5 et L6 et maintient honnêtement L4 PARTIAL. La continuation porte donc uniquement sur le reload du serveur MCP global configuré et sur la phase 9 : parcours joueur held item/HM/hidden item, fixture Selbrume V6 et recertification produit finale. Aucun lecteur historique, fallback ou mécanisme de migration ne doit être réintroduit.

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

| Phase | Total | DONE | PARTIAL | TODO | Différé | Lots réalisés | Lots à faire ou différés | Statut |
|---|---:|---:|---:|---:|---:|---|---|---|
| 0 — Vérité et inventaire de rupture | 1 | 1 | 0 | 0 | 0 | `ITM-001` | — | DONE |
| 1 — Contrats canoniques | 5 | 5 | 0 | 0 | 0 | `ITM-010` à `ITM-014` | — | DONE |
| 2 — Bag transactionnel | 5 | 5 | 0 | 0 | 0 | `ITM-020` à `ITM-024` | — | DONE |
| 3 — Consommateurs gameplay | 12 | 11 | 0 | 0 | 1 | `ITM-025` à `ITM-027`, `ITM-030` à `ITM-033`, `ITM-035` à `ITM-038` | `ITM-034` — DEFERRED_BY_PRODUCT | DONE_SCOPE_V1 |
| 4 — Producteurs et économie | 5 | 5 | 0 | 0 | 0 | `ITM-040` à `ITM-044` | — | DONE |
| 5 — Authoring et MCP | 6 | 6 | 0 | 0 | 0 | `ITM-050` à `ITM-055` | — | DONE |
| 6 — Suppression historique | 3 | 3 | 0 | 0 | 0 | `ITM-060` à `ITM-062` | — | DONE |
| 7 — Certification | 5 | 5 | 0 | 0 | 0 | `ITM-070` à `ITM-074` | — | DONE |
| 8 — Vérité des preuves et transports | 11 | 10 | 1 | 0 | 0 | `ITM-080` à `ITM-084`, `ITM-086` à `ITM-090` | `ITM-085` — PARTIAL | PARTIAL |
| 9 — Parcours produit et recertification | 6 | 0 | 0 | 6 | 0 | — | `ITM-100` à `ITM-105` | TODO |
| **Total** | **59** | **51** | **1** | **6** | **1** | **51 lots clôturés** | **6 TODO, 1 PARTIAL, 1 différé** | **PARTIAL** |

L’ordre recommandé restant est strict : recharger le MCP global seulement avec l’autorisation adéquate, puis fermer les parcours utilisateur de phase 9. `ITM-034` reste différé avec FG-065 et n’entre pas dans les 6 lots TODO.

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
| 7 | `7980897a1`, `6a03ab0e0`, `9dfd652c2`, `6de69184f`, puis clôture ITM-074 dans le commit de cette mise à jour |

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

- [x] **Résultat :** les quatre ressources et neuf mutations Item sont déclarées et réellement exécutées sur direct API, JSONL/CLI, Editor et MCP officiel.
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

**Contre-audit ITM-054 :** les adaptateurs génériques savent acheminer les contrats canoniques et les catalogues annoncent bien quatre ressources et neuf mutations. Toutefois, `AuthoringFullParityCatalog._endToEndEvidenceFor()` associe à toutes les actions `item.*` les mêmes fichiers de test, alors que `item_catalog_jsonl_test.dart`, `item_authoring_transport_test.dart` et `item_authoring.test.ts` n’exécutent réellement que `item.create`. Une déclaration de contrat, une énumération dans describe ou un fichier de test commun ne constitue pas une preuve d’exécution par action. `ITM-080` à `ITM-085` ferment ce lot sans modifier ses contrats fonctionnels.

**Clôture phase 8 :** la parité est désormais fail-closed et action-scoped. Les tests directs/JSONL, Editor et MCP exécutent chaque mutation et vérifient receipt, requery, validation et état sémantique final. Le collector L5 rejoue les 36 couples, rejette toute preuve d’une autre révision, fixture, action ou transport et fournit le bundle consommé par PMCP-085. Le serveur MCP packagé du worktree passe le smoke officiel ; le reload de l’instance globale configurée reste suivi séparément par ITM-085.

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

**Gate de phase 5 :** DONE. ITM-050 à ITM-055 sont clôturés ; les 36 couples action/transport sont exécutés et consommables par le runner. Aucun droit d’écriture arbitraire dans une sauvegarde utilisateur n’a été introduit.

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

**Statut de phase :** DONE après phase 8. ITM-070 à ITM-074 sont clôturés ; ITM-072 consomme désormais les receipts exécutés par les collectors L0-L3, L5 et L6 et conserve L4 PARTIAL comme verdict produit explicite.

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

- [x] **Résultat :** prouver la chaîne complète.
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

**Preuves ITM-071 :** `GoldenItemSystemJourney` est un runner réutilisable du host, pas un interpréteur parallèle de `walkthrough.json` : le walkthrough fixe uniquement l’ordre attendu, puis le runner appelle les loaders runtime, `createNewGameStateFromProject`, `ScenarioRuntimeExecutor`, `PlayerItemUseService`, les transactions de shop, le moteur `map_battle`, le bridge d’objet de combat, la capture runtime, `HeldItemOperations`, `RuntimeMoveMachineLoader`, `PokemonMoveMachineService`, les rewards et `FileGameSaveRepository`. Le pickup est idempotent par condition `flagIsUnset`; cure, PP, soin, Potion en combat, capture, TM, held item, key gate, passif, reward et un vrai K.O. suivi d’un Revive sont observés. Deux exécutions avec la graine 47 produisent le même receipt, avec SHA-256 de fixture et d’état final. Le dépôt runtime écrit désormais `itemSystemSchemaVersion: 1`, rejette les sauvegardes sans marqueur et valide les seules clés `itemId`/`quantity` avant décodage, sans fallback. Les suites ciblées terminent avec 55 tests map_core, 19 tests save/load runtime et 2 tests Golden Item System réussis. Les analyses ciblées map_core, runtime et host ne remontent aucune issue ; l’analyse incluant le barrel runtime conserve uniquement l’info préexistante `unnecessary_library_name`.

### ITM-072 — Certification produit

- [x] **Résultat :** le modèle L0-L6 est alimenté par des receipts exécutés, liés au commit et à la fixture ; L4 reste explicitement PARTIAL sans contaminer la certification technique des autres niveaux.
- **Fichiers à modifier :**
  - tools/pokemap_product_certification/lib/pokemap_product_certification.dart
  - tools/pokemap_product_certification/test/item_system_certification_test.dart
- **Axes :** schema, authoring, persistence, runtime, player UX, MCP parity et golden flow.
- **Gate :** aucune capacité Item n’est CERTIFIED sur un simple test de modèle.
- **Dépendances :** ITM-071 et ITM-054.

**Contre-audit ITM-072 :** `ItemSystemV1CertificationProfile` définit correctement L0 à L6 et refuse les preuves incomplètes. L6 consomme bien le receipt ITM-071 réellement exécuté. En revanche, le test de certification construit lui-même les ensembles de capacités attendus et des chaînes de 64 caractères jouant le rôle de digests pour L0 à L3 ; aucun collector du package n’exécute actuellement les codecs, l’authoring, la persistance ou le runtime pour produire ces preuves. Le modèle est utile, mais un test de modèle ne peut pas s’auto-déclarer preuve produit. `ITM-086` à `ITM-090` introduisent les receipts canoniques, les collectors et le runner nécessaires.

**Clôture phase 8 :** `ItemSystemV1CertificationRunner` exécute les codecs stricts, l’authoring, la persistance, les services runtime, les quatre transports et `GoldenItemSystemJourney`. Chaque receipt recalcule ses digests de source, fixture, payload et état observé. Une commande produit le JSON canonique : L0, L1, L2, L3, L5 et L6 sont CERTIFIED ; L4 reste PARTIAL pour `held_item_controls`. La suite complète du package passe 22/22 et l’analyse ne remonte aucune issue.

### ITM-073 — Matrice finale de validation

- [x] **Résultat :** exécuter les suites packages dans l’ordre.

    cd packages/map_core && dart test && dart analyze
    cd packages/map_gameplay && dart test && dart analyze
    cd packages/map_battle && dart test && dart analyze
    cd packages/map_authoring && dart test && dart analyze
    cd packages/map_runtime && flutter test && flutter analyze
    cd packages/map_player_ui && flutter test && flutter analyze
    cd packages/map_editor && flutter test && flutter analyze
    cd examples/playable_runtime_host && flutter test && flutter analyze
    cd tools/pokemap_product_certification && flutter test && flutter analyze
    cd packages/map_authoring && dart run tool/pmcp085_conformance.dart
    cd tools/pokemap_mcp && npm test
    cd tools/pokemap_mcp && npm run check
    cd tools/pokemap_mcp && npm run build

- **Builds :**

    cd packages/map_editor && flutter build macos --debug
    cd examples/playable_runtime_host && flutter build macos --debug

- **Gate :** résultats exacts consignés ; toute dette préexistante séparée du scope.
- **Dépendances :** ITM-072.

**Preuves ITM-073 :** la matrice a été exécutée séquentiellement, commande par commande. Les stabilisations du lot rendent le bootstrap Item d’un projet neuf strict et directement décodable, conservent Ether en overworld tant que le combat ne sait pas restaurer les PP, réalignent le test de route sur l’Item Studio canonique, complètent le contrat `usability` de `map_player_ui`, rendent la fixture de certification neutre V6 autonome et ignorent uniquement les acknowledgements CocoaPods générés dans le contrôle Markdown. Aucun lecteur d’ancien catalogue, fallback ou migration automatique n’a été ajouté.

| Périmètre | Tests | Analyse ou build | Verdict frais |
|---|---|---|---|
| `map_core` | 4 137 réussis, 8 échecs, 1 ignoré | 121 infos, aucune erreur ni warning | Dettes hors Item : rapports générés historiques absents. |
| `map_gameplay` | 468 réussis | 1 info `unnecessary_library_name` | Vert ; Ether MVP est certifié overworld uniquement. |
| `map_battle` | 1 746 réussis, 28 échecs | aucune issue | Échecs sur le chemin externe absent `pokémon_sdk_test_project/Data/Studio/moves`. |
| `map_authoring` | 562 réussis | aucune issue | Vert. |
| `map_runtime` | 2 286 réussis, 3 échecs, 1 ignoré | 7 infos | Échecs sur trois preuves visuelles historiques absentes sous `reports/ui`. Les 9 tests Item combat ciblés passent. |
| `map_player_ui` | 218 réussis | aucune issue | Vert après ajout explicite de `usability`. |
| `map_editor` | 5 218 réussis, 119 échecs et 10 ignorés avant interruption de la suite globale ; 27 tests Items ciblés réussis | analyse globale interrompue sans résultat après plus de 7 minutes ; analyse ciblée des 5 fichiers concernés sans issue ; build macOS réussi | La suite globale mêle goldens absents, fixtures Selbrume V2 et dettes async hors Item. L’export Personalization précédemment bloqué par `project.item_catalog_invalid` repasse. |
| `playable_runtime_host` | 248 réussis, 25 échecs et 3 ignorés avant blocage ; interruption à 3 min 19 s | 27 infos ; build macOS réussi | Golden Item System vert. Les échecs globaux proviennent surtout de Selbrume V2 refusé par le runtime V6 et de l’ancien cockpit d’évaluation. |
| `pokemap_product_certification` | 13 réussis | aucune issue | Vert ; les quatre échecs neutres observés à ITM-072 sont corrigés. |
| `pokemap_mcp` | 43 réussis en 281,369 s | `npm run check` et `npm run build` réussis | Vert pour le code construit dans le worktree. |
| PMCP-085 | runner réussi : 72 ressources, 272 mutations, 0 cellule bloquée ou manquante | 16 actions avec preuve E2E, 15 sur tous les transports ; `transportCertificationComplete: false` | La matrice générique ne suffit pas à certifier les neuf actions Item individuellement. |
| MCP live | `pokemap_describe` répond | 31 ressources, 263 mutations, aucune ressource Item et aucune action `item.*` | Serveur live stale ; L5 reste PARTIAL. Aucun outil de reload n’est exposé dans cette session. |
| Hygiène | `check_markdown_hygiene.sh` réussi après les deux builds | `PokeMap.app` et `PokeMap Selbrume.app` construits en debug | Vert ; les fichiers CocoaPods générés ne créent plus un faux échec Markdown. |

Le lot est DONE parce que la matrice demandée a été réellement exécutée et ses résultats séparés par origine, pas parce que le monorepo entier serait artificiellement déclaré vert. Les preuves L4 et L5 restent PARTIAL : le Player UI ne propose pas encore de commandes equip/unequip et le serveur MCP live n’embarque pas les contrats Item du worktree.

### ITM-074 — Recertification de la roadmap mécanique

- [x] **Résultat :** proposer les statuts FG avec preuves fraîches.
- **Lots à auditer :**
  - FG-050 ;
  - FG-060 à FG-070 ;
  - FG-072 et FG-073 ;
  - FG-074 à FG-079 pour non-régression shops.
- **Règle :** FG-065 et FG-066 conservent leur décision produit DEFERRED tant que cette décision n’est pas explicitement changée ; la capture minimale reste néanmoins certifiée.
- **Gate :** chaque statut cite fichiers, commandes, résultats, limites et scénario de preuve.
- **Dépendances :** ITM-073.

**Preuves ITM-074 :** la roadmap mécanique racine contient désormais une ligne de recertification datée et sourcée pour chacun des vingt lots demandés. FG-050, FG-064 et FG-067 passent de TODO à DONE sur les moteurs génériques, le gate key item direct et le pickup visible idempotent. FG-060 à FG-063, FG-069/070 et FG-074 à FG-078 restent DONE avec preuves fraîches. FG-065 et FG-066 restent DEFERRED ; la Poké Ball minimale est néanmoins exécutée. FG-068 reste TODO faute de hidden item dédié. FG-072 reste PARTIAL car equip/swap/unequip existent dans gameplay/runtime mais aucun contrôle correspondant n’est rendu par `map_player_ui`. FG-073 reste PARTIAL car la TM est jouable et la policy HM est testée, sans parcours joueur HM bout en bout. FG-079 passe de DONE historique à PARTIAL : le shop synthétique passe 5/5, mais la golden Selbrume échoue avant le scénario sur `smart_tile_v6_project_required (expected=v6, actual=v2)`.

Les commandes ciblées de recertification terminent avec 11 tests Core, 43 Gameplay, 41 Runtime, 14 Editor et 6 Host réussis. Le test Selbrume ciblé termine avec 0 réussite et 1 échec de setup. Ces résultats complètent, sans la remplacer, la matrice globale ITM-073. Le verdict final des niveaux de preuve est L0 schema CERTIFIED, L1 authoring CERTIFIED sur le code source, L2 persistence CERTIFIED, L3 runtime CERTIFIED, L4 player UX PARTIAL, L5 transports PARTIAL et L6 golden flow CERTIFIED. Le serveur MCP live chargé dans cette session reste antérieur au worktree et n’expose aucune ressource Item ni action `item.*`.

## 16. Vagues d’exécution recommandées

| Vague | Lots | Statut | Peut être parallélisé logiquement | Point de synchronisation |
|---|---|---|---|---|
| A | ITM-001 | DONE | Non | Inventaire de rupture |
| B | ITM-010 → ITM-014 | DONE | ITM-012 et ITM-013 après ITM-011 | Codec partagé |
| C | ITM-020 → ITM-024 | DONE | ITM-022 et ITM-023 après ITM-021 | Bag API stable |
| D1 | ITM-025 → ITM-038 hors ITM-034 différé | DONE_SCOPE_V1 | Classification, capture, machines et held après resolver | Consommateurs |
| D2 | ITM-040 → ITM-044 | DONE | Rewards et shops après BagOperations | Producteurs |
| E | ITM-050 → ITM-055 | DONE | UI après actions ; transports après contrats | Parité action-scoped |
| F | ITM-060 → ITM-062 | DONE | Non | Suppression historique |
| G | ITM-070 → ITM-074 | DONE | Non | Receipts exécutés |
| H | ITM-080 → ITM-085 | PARTIAL | ITM-081 à ITM-083 peuvent être préparés séparément | Reload du MCP global configuré |
| I | ITM-086 → ITM-090 | DONE | Les collectors L0/L1 et L2/L3 après le receipt commun | Certification exécutable |
| J | ITM-100 → ITM-105 | TODO | Held item, HM et hidden item sont indépendants ; tests Flutter en série | Clôture produit |

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

## 21. Roadmap complète des travaux restants

Les lots suivants ferment les écarts prouvés par le contre-audit. Ils ne refont pas le moteur Item déjà fonctionnel et n’ajoutent aucun chemin de compatibilité. Chaque lot doit être livré dans un commit dédié après autorisation Git explicite, avec test écrit ou durci avant le code de production, résultats exacts et état Git final.

### 21.1 Ordre de livraison

| Ordre | Lots | Objectif | Sortie obligatoire |
|---:|---|---|---|
| 1 | `ITM-080` | Faire échouer la parité lorsqu’une action n’est pas réellement exécutée | Registre fail-closed |
| 2 | `ITM-081` à `ITM-083` | Exécuter les neuf mutations sur direct API, JSONL, Editor et MCP | 36 couples action/transport prouvés |
| 3 | `ITM-084` et `ITM-085` | Réconcilier PMCP puis vérifier le serveur réellement chargé | L5 techniquement clos |
| 4 | `ITM-086` à `ITM-089` | Produire des receipts L0-L5 par des runners de production | Certification non synthétique |
| 5 | `ITM-090` | Rejouer la matrice et corriger les statuts | ITM-054 et ITM-072 proposés DONE |
| 6 | `ITM-100` à `ITM-102` | Fermer held item, HM et hidden item côté joueur | L4, FG-068, FG-072 et FG-073 fermables |
| 7 | `ITM-103` à `ITM-105` | Convertir la fixture Selbrume stricte et recertifier le produit | FG-079 et Item V1 fermables |

### 21.2 Phase 8 — Vérité des preuves et transports

#### ITM-080 — Rendre la preuve de transport fail-closed

- [x] **Résultat :** le faux positif qui attribuait les mêmes tests aux neuf actions `item.*` est supprimé.
- **Fichiers :** `packages/map_authoring/lib/src/parity/full_authoring_parity.dart`, `packages/map_authoring/test/parity/full_authoring_parity_test.dart`.
- **Tests d’abord :** prouver que `item.create` conserve ses preuves et que les huit actions non exécutées n’obtiennent aucune preuve E2E par simple appartenance au domaine Item.
- **Gate :** `dart test test/parity/full_authoring_parity_test.dart` et `dart analyze` réussissent ; PMCP ne peut plus déclarer une action Item fully-E2E sans receipt spécifique.
- **Dépendance :** aucune. **Commit cible :** `fix(items): fail close transport evidence`.

**Preuve :** `AuthoringFullParityCatalog` ne produit plus de certification Item à partir d’un nom de fichier partagé. Les tests prouvent qu’une action sans exécution propre reste incomplète et PMCP échoue fermé sans bundle de receipts.

#### ITM-081 — Matrice direct API et JSONL des neuf mutations

- [x] **Résultat :** les neuf mutations sont exécutées par direct API et JSONL avec état final canonique équivalent.
- **Fichiers :** `packages/map_authoring/test/domains/gameplay/item_catalog_actions_test.dart`, `packages/map_authoring/test/domains/gameplay/item_catalog_jsonl_test.dart`, puis uniquement les handlers de `packages/map_authoring/lib/src/domains/gameplay/` si un écart réel est découvert.
- **Tests d’abord :** pour chaque action, planifier, appliquer avec une révision attendue, relire le catalogue et comparer l’état final direct/JSONL ; couvrir révision périmée, identifiant invalide, delete référencé et absence de mutation sur refus.
- **Gate :** les 18 couples action/transport produisent un receipt distinct et un état final canonique équivalent.
- **Dépendance :** ITM-080. **Commit cible :** `test(items): prove direct and jsonl mutation parity`.

**Preuve :** 18 couples produisent des receipts distincts ; révision périmée, identifiant invalide, suppression référencée et refus sans mutation sont couverts.

#### ITM-082 — Matrice Editor des neuf mutations

- [x] **Résultat :** l’adaptateur Editor transporte les neuf mutations sémantiques sans logique Item privée.
- **Fichiers :** `packages/map_editor/test/authoring_api/item_authoring_transport_test.dart`, `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart` uniquement si le test révèle un défaut.
- **Tests d’abord :** exécuter les neuf actions, vérifier receipt, requery, révision, undo et restauration exacte ; vérifier qu’un refus ne crée aucune entrée d’historique.
- **Gate :** neuf actions Editor réussies et `flutter analyze` sans erreur ni warning sur le périmètre touché.
- **Dépendances :** ITM-080 et ITM-081. **Commit cible :** `test(items): prove editor mutation parity`.

**Preuve :** les neuf actions vérifient receipt, requery, révision, undo et restauration exacte ; un refus ne crée aucune entrée d’historique.

#### ITM-083 — Matrice MCP des neuf mutations

- [x] **Résultat :** les neuf actions sont exécutées via le client MCP officiel sur une copie temporaire repo-owned.
- **Fichiers :** `tools/pokemap_mcp/test/item_authoring.test.ts`, `tools/pokemap_mcp/src/authoring_client.ts` uniquement si nécessaire.
- **Tests d’abord :** `workspace.open`, query de révision, plan, apply, requery et validation pour chaque action ; couvrir confirmation de suppression, révision périmée et refus sans mutation.
- **Gate :** neuf receipts MCP distincts, `npm test`, `npm run check` et `npm run build` réussis.
- **Dépendances :** ITM-080 et ITM-081. **Commit cible :** `test(items): prove mcp mutation parity`.

**Preuve :** le smoke isolé du build packagé passe en 6,8 s avec neuf receipts, requery et validation. La suite MCP globale reste fragile sous charge et produit deux `worker.timeout`, consignés dans ITM-090 ; `npm run check` et `npm run build` passent.

#### ITM-084 — Réconcilier PMCP-085 action par action

- [x] **Résultat :** PMCP-085 consomme les preuves réellement exécutées, action par action, jamais un nom de fichier partagé.
- **Fichiers :** `packages/map_authoring/lib/src/parity/full_authoring_parity.dart`, `packages/map_authoring/test/parity/full_authoring_parity_test.dart`, `packages/map_authoring/tool/pmcp085_conformance.dart` si le format de receipt doit évoluer.
- **Tests d’abord :** un transport absent laisse uniquement l’action concernée incomplète ; une preuve d’une autre action, révision ou fixture est rejetée.
- **Gate :** les neuf actions Item ont quatre transports prouvés. `transportCertificationComplete` peut rester faux pour d’autres domaines sans dégrader le verdict Item.
- **Dépendances :** ITM-081 à ITM-083. **Commit cible :** `fix(items): reconcile action scoped parity receipts`.

**Preuve :** le bundle lie action, transport, source, fixture, executor, receipt normalisé et digest d’état. Le run frais rapporte 72 ressources, 274 mutations et `itemTransportCertificationComplete: true` ; la certification globale des autres domaines reste indépendante.

#### ITM-085 — Smoke du MCP live courant

- [ ] **Résultat PARTIAL :** le build packagé exact du worktree est exécuté par le client MCP officiel, mais l’instance MCP globale configurée pointe encore l’ancien checkout.
- **Périmètre :** `tools/pokemap_mcp/dist/`, serveur MCP configuré, copie temporaire de `examples/playable_runtime_host/golden_item_system/` placée sous une racine étroite autorisée.
- **Procédure :** reconstruire le MCP, recharger explicitement ce build, exécuter `pokemap_describe`, ouvrir la copie jetable, interroger les quatre ressources Item, appliquer les neuf mutations avec requery/validate, puis fermer le workspace.
- **Gate :** describe live expose quatre ressources et neuf actions Item ; les 36 couples attendus par L5 sont liés au build, au commit et au digest de fixture courants.
- **Sécurité :** aucune mutation d’un projet utilisateur et aucun élargissement de racine au home. Toute modification de configuration MCP globale exige une autorisation séparée.
- **Dépendance :** ITM-084. **Commit cible :** `test(items): record live mcp smoke contract` si une fixture ou un test versionné change ; sinon lot de vérification sans commit artificiel.

**Preuve et limite :** `live_item_smoke.test.ts` reconstruit le serveur, copie la Golden fixture sous une racine temporaire étroite, vérifie describe, ressources et neuf mutations, puis ferme le workspace. Le test isolé passe. Aucun reload ni changement de configuration globale n’est effectué sans autorisation séparée ; ce seul point maintient ITM-085 PARTIAL.

#### ITM-086 — Receipt canonique d’exécution L0-L6

- [x] **Résultat :** les chaînes arbitraires sont remplacées par un contrat calculé, vérifiable et profondément immuable.
- **Fichiers à créer :** `tools/pokemap_product_certification/lib/src/item_system_execution_receipt.dart`, `tools/pokemap_product_certification/test/item_system_execution_receipt_test.dart` ; exporter depuis `tools/pokemap_product_certification/lib/pokemap_product_certification.dart`.
- **Contrat :** niveau, commit, digest SHA-256 de fixture, digest SHA-256 du payload canonique, capacités tentées/réussies/échouées, producteur, version du runner, horodatage informatif et verdict.
- **Tests d’abord :** le digest est recalculé depuis le payload ; capability dupliquée, inconnue, non exécutée, digest forgé ou révision discordante est refusée.
- **Gate :** aucun collector ne peut construire directement un statut CERTIFIED.
- **Dépendance :** ITM-071. **Commit cible :** `feat(items): define executable certification receipts`.

**Preuve :** le receipt lie niveau, source, fixture, payload, capacités et producteur ; digest forgé, source discordante, capacité inconnue ou non exécutée sont refusés. L’horodatage informatif n’altère pas le digest de preuve.

#### ITM-087 — Collectors L0 schema et L1 authoring

- [x] **Résultat :** L0 et L1 sont produits par exécution des APIs réelles sur la fixture Golden.
- **Fichiers à créer :** `tools/pokemap_product_certification/lib/src/item_system_schema_evidence_collector.dart`, `tools/pokemap_product_certification/lib/src/item_system_authoring_evidence_collector.dart`, tests homonymes sous `tools/pokemap_product_certification/test/` ; ajouter `map_authoring` aux dépendances directes si nécessaire.
- **L0 :** décoder catalogue et save V1, valider Bag strict, puis prouver le refus des champs historiques et du marqueur de schéma absent.
- **L1 :** charger les quatre ressources, exécuter CRUD/effects/readiness/reference guards via map_authoring et produire les receipts correspondants.
- **Gate :** aucune liste de capacités attendues n’est copiée dans le test pour simuler le succès ; elle provient des opérations réellement terminées.
- **Dépendance :** ITM-086. **Commit cible :** `feat(items): collect schema and authoring evidence`.

**Preuve :** L0 décode catalogue et save stricts puis prouve le refus des marqueurs/champs historiques ; L1 charge les ressources et exécute CRUD, effets, readiness et guards via map_authoring.

#### ITM-088 — Collectors L2 persistence et L3 runtime

- [x] **Résultat :** L2 et L3 proviennent de la persistance et des services runtime de production.
- **Fichiers à créer :** `tools/pokemap_product_certification/lib/src/item_system_persistence_evidence_collector.dart`, `tools/pokemap_product_certification/lib/src/item_system_runtime_evidence_collector.dart`, tests homonymes.
- **L2 :** exécuter new game, pickup idempotent, shop, reward et `FileGameSaveRepository` avec round-trip strict et digests avant/après.
- **L3 :** exécuter medicine overworld/battle, capture, key gate, TM, held item et passif via les services déjà utilisés par `GoldenItemSystemJourney` ; ne pas réimplémenter les mutations dans le collector.
- **Gate :** toute capacité non atteinte ou sans observation avant/après reste PARTIAL ; les sauvegardes anciennes restent refusées.
- **Dépendance :** ITM-086. **Commit cible :** `feat(items): collect persistence and runtime evidence`.

**Preuve :** L2 exécute new game, pickup idempotent, shop, reward et round-trip strict ; L3 consomme la Golden journey pour medicine, capture, key gate, TM, held item et passif sans réimplémenter les mutations.

#### ITM-089 — Collector L5 et runner de certification

- [x] **Résultat :** L0-L6 sont composés par une commande reproductible et fail-closed.
- **Fichiers à créer :** `tools/pokemap_product_certification/lib/src/item_system_transport_evidence_collector.dart`, `tools/pokemap_product_certification/lib/src/item_system_v1_certification_runner.dart`, `tools/pokemap_product_certification/bin/certify_item_system_v1.dart` ; durcir `tools/pokemap_product_certification/test/item_system_certification_test.dart`.
- **Entrées :** receipts ITM-081 à ITM-085, collectors ITM-087/088 et receipt L6 de `GoldenItemSystemJourney` ; L4 reste PARTIAL jusqu’à ITM-100/101.
- **Sortie :** JSON canonique L0-L6 lié au commit et aux fixtures, avec raisons précises pour chaque niveau non certifié.
- **Gate :** supprimer les helpers de test qui fabriquent `_completeEvidence` ou des pseudo-digests ; deux exécutions inchangées produisent le même payload hors horodatage informatif.
- **Dépendances :** ITM-084 à ITM-088. **Commit cible :** `feat(items): run executable item certification`.

**Preuve :** `dart run bin/certify_item_system_v1.dart` construit le MCP, exécute les collectors et écrit certification plus bundle transport. L0-L3, L5 et L6 sont CERTIFIED, L4 reste PARTIAL ; les 36 receipts L5 sont liés à la source, à la fixture et aux états observés.

#### ITM-090 — Recertification technique de la phase 8

- [x] **Résultat :** la matrice complète est rejouée et les statuts reflètent les preuves fraîches, sans déclarer vertes les dettes globales hors Item.
- **Commandes minimales :** suites et analyses `map_core`, `map_gameplay`, `map_battle`, `map_authoring`, `map_runtime`, `map_player_ui`, `map_editor`, host et certification ; PMCP-085 ; tests/check/build MCP ; deux builds macOS ; smoke MCP live ; hygiène Markdown.
- **Gate :** ITM-054 et ITM-072 ne passent DONE que si les receipts action/transport et L0-L6 sont consommables par le runner. L4 peut rester PARTIAL sans bloquer la clôture technique de L0-L3, L5 et L6.
- **Documentation :** mettre à jour ce fichier et proposer les changements FG dans `pokemap_roadmap_mecaniques_fangame.md` avec résultats exacts, sans masquer les dettes hors Item.
- **Dépendance :** ITM-089. **Commit cible :** `test(items): recertify executable evidence matrix`.

**Verdict :** la clôture technique est acquise pour L0-L3, L5 et L6. L4 reste PARTIAL par contrat ; ITM-085 reste PARTIAL uniquement pour le reload du serveur MCP global configuré. ITM-054 et ITM-072 passent DONE car leurs receipts sont exécutés et consommés par le runner.

| Périmètre frais | Résultat exact | Lecture |
|---|---|---|
| `map_core` | 4 145 réussis, 7 échecs, 1 ignoré ; analyse sans erreur/warning, 121 infos | Échecs de gates/fixtures historiques, round-trip de présentation et save canonique hors changement phase 8. |
| `map_gameplay` | 468/468 ; analyse sans erreur/warning, 1 info | Vert. |
| `map_battle` | 1 746 réussis, 28 échecs ; analyse sans issue | Corpus et artefacts PSDK externes absents ou désynchronisés. |
| `map_authoring` | 573/573 ; analyse sans issue | Vert, y compris la parité Item action-scoped. |
| `map_runtime` | 2 308 réussis, 3 échecs, 1 ignoré ; analyse sans erreur/warning, 7 infos | Deux anciennes sauvegardes narratives sans schéma strict et une preuve visuelle historique. |
| `map_player_ui` | 218/218 ; analyse sans issue | Vert ; L4 reste fonctionnellement partiel faute de contrôles held item. |
| `map_editor` | 5 406 réussis, 124 échecs, 11 ignorés avant arrêt à 12 min 20 s ; analyse sans issue ; build macOS réussi | Suite globale bloquée après fixtures V2/goldens et dettes async hors Item ; tests Item ciblés verts. |
| `playable_runtime_host` | 248 réussis, 25 échecs, 3 ignorés avant blocage ; analyse sans erreur/warning, 27 infos ; build macOS réussi | Probe web Selbrume puis runner inactif plus de deux heures ; Golden Item ciblé vert. |
| `pokemap_product_certification` | 22/22 ; analyse sans issue | Vert après exclusion du worker CLI de la découverte automatique des tests. |
| `pokemap_mcp` | suite globale : 42 réussis, 2 `worker.timeout` ; smoke Item isolé : 1/1 en 6,8 s ; check/build réussis | Fragilité de timeout sous charge conservée comme dette globale ; contrat Item packagé prouvé. |
| Runner L0-L6 | L0-L3, L5, L6 CERTIFIED ; L4 PARTIAL | Verdict technique attendu et fail-closed. |
| Builds macOS | `PokeMap.app` 69,9 MB et `PokeMap Selbrume.app` 52,3 MB | Réussis en release. |

### 21.3 Phase 9 — Parcours produit et recertification

#### ITM-100 — Contrôles joueur des objets tenus

- [ ] **But :** permettre give/swap/take depuis le Bag ou le résumé d’équipe et fermer L4/FG-072.
- **Fichiers :** `packages/map_player_ui/lib/src/player/runtime_player_detail_router.dart`, `packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart`, `packages/map_runtime/lib/src/player/runtime_player_pause_data.dart`, tests `packages/map_player_ui/test/player/runtime_player_detail_router_test.dart` et `packages/map_runtime/test/runtime_held_item_bridge_v0_test.dart`.
- **Tests d’abord :** équiper, remplacer avec retour atomique au Bag, retirer, annuler, Bag insuffisant, cible invalide et persistance après save/reload.
- **Gate :** les commandes existantes `equipHeldItem`/`unequipHeldItem` sont réellement émises par l’UI ; aucun ID brut n’est demandé au joueur.
- **Dépendance :** ITM-090. **Commit cible :** `feat(items): add player held item controls`.

#### ITM-101 — Parcours joueur HM complet

- [ ] **But :** fermer FG-073 de la sélection de la HM jusqu’à la non-consommation.
- **Fichiers :** `packages/map_player_ui/lib/src/player/runtime_player_detail_router.dart`, `packages/map_runtime/lib/src/application/runtime_move_machine_loader.dart`, `packages/map_runtime/lib/src/player/runtime_player_pause_data_builder.dart`, leurs tests ciblés et `examples/playable_runtime_host/test/golden_item_system_flow_test.dart`.
- **Tests d’abord :** compatibilité, sélection du Pokémon, remplacement à quatre moves, annulation, HM réutilisable/non consommée, save/reload et respect du gate badge/field ability sans déduction naïve depuis le move.
- **Gate :** un test widget émet la commande joueur et un test host observe Bag, moves et progression avant/après.
- **Dépendance :** ITM-090. **Commit cible :** `feat(items): prove complete player hm journey`.

#### ITM-102 — Hidden Item Event V0

- [ ] **But :** fermer FG-068 avec un objet invisible mais inspectable, idempotent et sauvegardé.
- **Fichiers :** `packages/map_core/lib/src/models/map_entity_payloads.dart` et générés associés, authoring sémantique sous `packages/map_authoring/lib/src/domains/maps/`, `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`, interaction/runtime sous `packages/map_runtime/lib/src/`, plus tests core/authoring/editor/runtime et fixture Golden.
- **Tests d’abord :** l’objet n’est pas rendu, se déclenche par action/interact, affiche un message dédié, crédite le Bag une seule fois, reste consommé après save/reload et ne requiert aucun Itemfinder.
- **Authoring :** choix guidé visible/hidden et picker Item canonique ; aucun JSON manuel ni champ historique.
- **Gate :** ressources/actions MCP et transports sont étendus si un nouveau contrat sémantique est ajouté ; la golden flow observe le pickup caché sans dupliquer le pickup visible.
- **Dépendance :** ITM-090. **Commit cible :** `feat(items): add hidden item event`.

#### ITM-103 — Cutover strict de la fixture Selbrume vers V6

- [ ] **But :** rendre le projet repo-owned `selbrume/` chargeable par le runtime V6 courant.
- **Fichiers :** `selbrume/project.json` et uniquement les assets/manifests repo-owned rendus incompatibles par la conversion.
- **Règle :** convertir les données, pas assouplir le runtime. Aucun lecteur V2, fallback, dual schema ou migration à l’ouverture n’est autorisé.
- **Tests d’abord :** caractériser le refus V2, produire la fixture V6, puis vérifier load/validate/export et l’absence des anciens champs Item/Bag.
- **Gate :** `selbrume_dynamic_shop_e2e_test.dart` dépasse le setup `smart_tile_v6_project_required`; validate et export V6 réussissent.
- **Dépendance :** ITM-090. **Commit cible :** `refactor(selbrume): cut project fixture to v6`.

#### ITM-104 — Recertification du Shop dynamique Selbrume

- [ ] **But :** fermer FG-079 avec un parcours réel, pas seulement la fixture synthétique du Shop.
- **Tests :** `examples/playable_runtime_host/test/selbrume_dynamic_shop_e2e_test.dart`, `examples/playable_runtime_host/test/in_game_shop_page_test.dart`, tests Editor `shop_state_preview_strip_test.dart`, `shop_state_simulation_controller_test.dart`, `narrative_studio_shop_route_test.dart` et une capture réelle du Shop Builder.
- **Scénarios :** default, after-lysa, lighthouse-alert et story-finished ; achat, argent, inventaire, stock isolé, fermeture authored et save/reload.
- **Gate :** tous les profils sont observés par le parcours joueur, la capture Editor est produite depuis le produit courant et aucun test ne dépend d’un chemin machine externe.
- **Dépendance :** ITM-103. **Commit cible :** `test(selbrume): recertify dynamic shop journey`.

#### ITM-105 — Clôture produit Item System V1

- [ ] **But :** établir le verdict final après les parcours joueur et Selbrume.
- **Matrice :** rejouer ITM-090, les tests ITM-100 à ITM-104, le runner L0-L6, PMCP, MCP live, les builds macOS et l’hygiène Markdown.
- **Gate :** aucune capacité n’est CERTIFIED sans receipt exécuté ; L4 exige held item et HM, L5 les 36 couples action/transport et L6 la golden flow déterministe.
- **Documentation :** mettre à jour cette roadmap et `pokemap_roadmap_mecaniques_fangame.md` ; FG-068, FG-072, FG-073 et FG-079 ne passent DONE qu’avec les preuves de leur propre DoD.
- **Dépendances :** ITM-100 à ITM-104. **Commit cible :** `docs(items): close item system v1 certification`.

### 21.4 Décisions produit qui ne sont pas des lots exécutables

| Sujet | Statut | Conséquence |
|---|---|---|
| `ITM-034` / FG-065 Repel | DEFERRED_BY_PRODUCT | Ne pas implémenter sans réouverture explicite de la décision produit. |
| FG-066 familles complètes de Balls | DEFERRED_BY_PRODUCT | La Poké Ball minimale reste suffisante pour le périmètre actuel ; aucun catalogue de familles n’est inventé. |
| FG-071 Heal Center Flow | Roadmap mécanique distincte | Les primitives de soin Item restent acquises ; le dialogue, la commande de centre et le respawn ne sont pas glissés dans Item V1. |
| Compatibilité anciens catalogues/Bags/saves | INTERDITE | Aucun lot futur de cette roadmap ne peut ajouter migration, fallback ou double lecteur. |

ITM-034 reste différé et ne doit pas être glissé discrètement dans une maintenance sous prétexte qu’un Repel « n’a pas l’air bien méchant » — c’est exactement ainsi que les petits lots se transforment en marécages.
