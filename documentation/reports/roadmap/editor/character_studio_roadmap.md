# Character Studio — Roadmap d’implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use `subagent-driven-development` (recommended when explicitly authorized) or `executing-plans` to implement this roadmap lot by lot. Track execution with the checkboxes below. Never run Git write operations without explicit user authorization.

**Goal:** Remplacer la Character Library par un Character Studio no-code complet, fondé sur le design premium validé : structure générale de la proposition 1, matrice d’animations de la proposition 2, états de portraits globaux au projet, animations personnalisées globales et consommation réelle dans les dialogues, cinématiques et le runtime.

**Architecture:** Faire évoluer le manifeste v6 de manière strictement additive. Les catalogues globaux portent des identifiants stables ; chaque personnage ne stocke que ses variantes et clips. Toutes les mutations passent par `map_authoring`, puis sont consommées par l’éditeur, le JSONL/CLI, MCP, l’export et le runtime. La sauvegarde d’un personnage incomplet reste autorisée ; la disponibilité des quatre directions de l’animation Base est une règle de readiness bloquante pour l’exécution, pas une erreur structurelle empêchant le travail en cours.

**Tech Stack:** Dart 3, Flutter desktop, Riverpod, Freezed/JSON serialization selon les conventions locales, `map_core`, `map_authoring`, `map_editor`, `map_runtime`, `map_player_ui`, JSONL/CLI, PokeMap MCP.

---

## 1. Statut et règles d’exécution

- [x] `DONE` — les lots CHS-001 à CHS-061 sont implémentés et certifiés au 12 août 2026.
- [x] `DONE_WITH_RESERVATIONS` — les lots de durcissement CHS-062 à CHS-065 sont livrés ; les analyses globales `map_runtime` et `playable_runtime_host` restent arrêtées par des diagnostics `info` préexistants, sans échec fonctionnel Character Studio.
- Clôture historique CHS-001 à CHS-061 : `documentation/reports/editor/character_studio_final_closure_2026-08-12.md` ; les preuves S13 sont consolidées dans la phase 7 ci-dessous.
- L’audit de la section 2 reste la photographie historique prise avant l’implémentation.
- Cette roadmap est le document canonique du chantier Character Studio.
- Un lot doit rester petit, testable, réversible et livrable indépendamment.
- Une phase permet de traiter plusieurs lots dans la même session, uniquement selon les vagues indiquées ; deux lots qui touchent le même modèle, codec ou fichier généré restent séquentiels.
- Chaque lot se termine par ses tests ciblés et un état Git lisible. Une phase se termine par les tests croisés de ses packages.
- Aucun statut `DONE` ne peut être attribué sur la seule présence d’un modèle, d’un écran ou d’un test isolé : la preuve doit traverser données, authoring, UI no-code, persistance, runtime et scénario déterministe lorsque ces couches sont applicables.
- Le visuel de référence est le mockup premium hybride validé dans la conversation : proposition 1 pour le shell et les portraits, proposition 2 pour la matrice d’animations.

## 2. Audit initial — état vérifié avant roadmap

### 2.1 Git et périmètre

- Branche observée : `main`.
- HEAD observé : `984b6973d`.
- État initial : worktree propre, aucun fichier modifié ou non suivi.
- L’audit a été strictement read-only ; seuls les tests de caractérisation ont produit des artefacts temporaires de build ignorés par Git.

### 2.2 Modèle et validation actuels

- `ProjectCharacterEntry` stocke l’identité, un `tilesetId`, les dimensions de frame, les animations et les tags.
- `CharacterAnimationState` est un enum fermé : `idle`, `walk`, `run`.
- Une animation est identifiée par le couple état/direction et utilise la spritesheet du personnage.
- Le manifeste ne contient ni catalogue global d’expressions, ni portraits par personnage, ni définition globale d’animation personnalisée.
- Le projet courant utilise `ProjectVersion.v6`; plusieurs contrats Smart Tiles attendent explicitement v6. La roadmap n’introduit donc pas artificiellement un v7 pour des champs additifs.
- Le validateur vérifie déjà les IDs, le tileset, la géométrie des frames et les durées, mais ne connaît ni couverture Base, ni références de portraits, ni animations custom.

### 2.3 Authoring et éditeur actuels

- `map_authoring` expose aujourd’hui le personnage via les actions génériques `campaign.character.upsert/delete`, sans ressources ni mutations sémantiques de Character Studio.
- L’éditeur utilise encore `CharacterLibraryPanel`, un panneau Explorer d’environ 1 300 lignes avec des primitives UI historiques et des sauvegardes directes via `character_use_cases.dart`.
- `EditorWorkspaceMode` et `EditorCanvasHost` n’ont pas de workspace Character Studio.
- L’état éditeur ne conserve que `selectedCharacterId`; il n’existe pas de sélection de portrait, clip, direction ou frame.
- Il n’existe pas de suite ciblée couvrant directement tous les use cases de personnages.

### 2.4 Dialogues et runtime actuels

- Une ligne de dialogue compilée ne stocke qu’un texte ; le speaker est déduit au runtime en coupant la chaîne au premier `:`.
- Le format de dialogue ne possède donc aucune identité de personnage ou expression structurée.
- Le runtime d’overworld et les previews résolvent uniquement `idle`, `walk` et `run`, avec les fallbacks historiques.
- `actorEmote` affiche un emote visuel ; ce n’est pas et ne doit pas devenir un détournement pour jouer une animation de personnage.
- `map_player_ui` affiche le speaker et le texte sans portrait.

### 2.5 Baseline fraîche

| Commande | Résultat |
|---|---:|
| `cd packages/map_core && dart test test/runtime_dialogue_document_test.dart test/cinematic_actor_display_preview_model_test.dart test/cinematic_diagnostics_test.dart` | 89 tests réussis |
| `cd packages/map_authoring && dart test test/domains/gameplay/campaign_content_authoring_test.dart test/parity/full_authoring_parity_test.dart` | 14 tests réussis |
| `cd packages/map_editor && flutter test test/cinematic_actor_sprite_preview_resolver_test.dart test/cinematic_actor_walking_animation_preview_resolver_test.dart` | 25 tests réussis |
| `cd packages/map_runtime && flutter test test/player_component_test.dart test/dialogue_presentation_snapshot_test.dart test/compiled_dialogue_runtime_test.dart` | 6 tests réussis |
| `cd packages/map_player_ui && flutter test test/player_dialogue_overlay_test.dart` | 5 tests réussis |

## 3. Contrat produit à ne pas diluer

### 3.1 Personnages et portraits

1. Les états de portrait sont globaux au projet et librement nommés : `Neutre`, `Contente`, `Triste`, `Surprise`, ou n’importe quel autre libellé.
2. Un état possède un ID stable indépendant de son libellé. Renommer `Surprise` en `Étonnée` ne casse aucune référence.
3. Chaque personnage peut fournir zéro ou une image par état global.
4. L’absence d’un portrait est visible et diagnostiquée, mais ne bloque pas la sauvegarde du personnage.
5. La suppression d’un état global est interdite tant que ses usages ne sont pas explicitement remplacés ou effacés.
6. Les dialogues sélectionnent un personnage et un état avec des pickers ; aucun ID brut ni directive Yarn n’est requis dans le parcours normal.
7. Sans métadonnée de portrait, un ancien dialogue continue d’afficher exactement son speaker et son texte historiques.

### 3.2 Animations

1. `Base` est le libellé Studio de l’état historique `idle`.
2. Pour être `runtime ready`, Base exige exactement une animation exploitable pour Nord, Sud, Est et Ouest.
3. `Marche` et `Course` restent des capacités système optionnelles correspondant à `walk` et `run`.
4. Les animations personnalisées sont définies globalement au projet, librement nommées et réordonnables.
5. Une définition custom choisit un mode immuable tant qu’elle est référencée : `directional` avec N/S/E/O, ou `single` sans direction.
6. Chaque personnage peut fournir ou non les clips d’une définition globale.
7. Chaque clip possède sa source, ses frames ordonnées, leurs durées et son mode de boucle.
8. Une case absente dans la matrice reste visible en état vide/ambre ; elle n’est jamais remplacée silencieusement dans les données.
9. Les fallbacks runtime historiques restent déterministes pour Base/Marche/Course.
10. Les animations custom sont déclenchées par un contrat dédié depuis une scène ou une cinématique, jamais via `actorEmote`.

### 3.3 Expérience Studio

- Colonne gauche : recherche, filtres, liste des personnages, statut de couverture, création.
- Centre : identité du personnage et onglets `Identité`, `Portraits`, `Animations`.
- Droite : inspecteur contextuel de l’état, du clip ou de la frame sélectionnée.
- Portraits : grand aperçu, grille des états globaux, ajout/remplacement, cadrage et aperçu de dialogue.
- Animations : matrice Base/Marche/Course/custom × directions, aperçu live, timeline des frames, source et découpe.
- Catalogue global : gestion séparée des états de portrait et définitions d’animation, avec dépendances avant suppression.
- Responsive : trois colonnes sur grand écran ; bibliothèque et inspecteur deviennent des panneaux alternables aux largeurs plus faibles, sans perte de fonction.
- Tous les contrôles utilisent le design system PokeMap et ses tokens ; aucun `Color(...)`, `Colors.*` ou composant local ad hoc dans le nouveau feature.

## 4. Architecture cible

### 4.1 Schéma additif dans `map_core`

Le manifeste v6 reçoit un champ optionnel/defaulté :

```text
ProjectManifest.characterStudioCatalog
└── ProjectCharacterStudioCatalog
    ├── portraitStates: List<CharacterPortraitStateDefinition>
    └── customAnimationDefinitions: List<CharacterCustomAnimationDefinition>

ProjectCharacterEntry
├── portraits: List<CharacterPortraitVariant>
├── animations: List<CharacterAnimation>                 (héritage Base/Marche/Course)
└── customAnimations: List<CharacterCustomAnimationClip>
```

Contrats précis :

- `CharacterPortraitStateDefinition`: `id`, `displayName`, `sortOrder`.
- `CharacterPortraitVariant`: `portraitStateId`, `assetId`, `fitMode`, données de cadrage normalisées si nécessaires.
- `CharacterCustomAnimationDefinition`: `id`, `displayName`, `mode`, `sortOrder`.
- `CharacterCustomAnimationMode`: `directional` ou `single`.
- `CharacterCustomAnimationClip`: `definitionId`, `direction?`, `sourceAssetId`, `frames`, `loop`.
- `CharacterAnimation`: conserve `state`, `direction` et `frames`, ajoute `sourceAssetId?` et `loop` avec defaults rétrocompatibles.
- Les définitions système Base/Marche/Course sont projetées par le read model et ne sont pas dupliquées dans `customAnimationDefinitions`.
- Une source absente sur une animation système signifie : utiliser le `tilesetId` historique du personnage.
- Tous les IDs d’assets restent logiques et portables ; aucun chemin absolu local n’entre dans le manifeste.

### 4.2 Compatibilité

- Un projet v6 existant décode avec catalogues et listes vides.
- `idle`, `walk`, `run` gardent leurs valeurs JSON historiques.
- La migration est une normalisation en mémoire et une écriture additive, sans réécriture obligatoire à l’ouverture.
- Les codecs doivent prouver le round-trip des fixtures historiques et des nouvelles données.
- La readiness, l’éditeur et l’export comprennent les nouveaux champs ; un ancien binaire peut les perdre s’il réécrit le manifeste. Le Studio doit afficher un minimum-version/backup warning plutôt que prétendre garantir un downgrade impossible.

### 4.3 Validation versus readiness

**Validation structurelle bloquante :** IDs globaux dupliqués, référence globale orpheline, asset inexistant, mode/direction incohérent, slot de clip dupliqué, rectangle hors source, frame vide, durée invalide.

**Readiness bloquante :** une direction Base N/S/E/O absente ou inexploitable pour un personnage déclaré jouable/placé dans le monde.

**Diagnostic non bloquant :** état de portrait non fourni, Marche/Course absente, custom non fournie, couverture partielle d’une custom directionnelle non utilisée.

Le personnage peut être sauvegardé incomplet ; l’export ou le lancement explique précisément ce qui manque et où le corriger.

### 4.4 Références et suppression sûre

- Le reference index couvre personnages, dialogues, cinématiques, scènes, default player et usages runtime exportés.
- Toute suppression globale commence par une opération `deletePlan` pure qui retourne les dépendances et les choix `replace`, `clear` ou `cancel`.
- Une suppression n’accepte jamais un simple `force: true` opaque.
- Renommer conserve l’ID. Changer le mode directionnel d’une définition utilisée requiert une migration explicite de ses clips.

### 4.5 API canonique et parité MCP

Ressources découvrables visées :

- `characterStudio.catalog`
- `characterStudio.characters`
- `characterStudio.character`
- `characterStudio.dependencies`
- `characterStudio.readiness`

Familles d’actions visées :

- `characterStudio.portraitState.create/update/reorder/deletePlan/delete`
- `characterStudio.animationDefinition.create/update/reorder/deletePlan/delete`
- `characterStudio.character.create/update/setDefault/deletePlan/delete`
- `characterStudio.portrait.assign/clear`
- `characterStudio.animationClip.upsert/delete`
- `characterStudio.animationFrame.insert/update/reorder/delete`
- `characterStudio.asset.import/replace`
- `characterStudio.preview.render`

Les noms définitifs doivent respecter la grammaire du registre existant, mais la sémantique et la granularité ci-dessus sont contractuelles. L’éditeur appelle l’adapter canonique ; il ne sauvegarde plus directement le manifeste pour ces opérations.

## 5. Vue d’ensemble des phases

| Phase | Lots | Résultat utilisable | Dépend de |
|---|---|---|---|
| 0 — Fondations sûres | CHS-001 à CHS-004 | Schéma, migration et diagnostics prêts sans régression | — |
| 1 — Authoring canonique | CHS-010 à CHS-017 | Toute la sémantique accessible par API, JSONL, éditeur et MCP | Phase 0 |
| 2 — Shell et identité | CHS-020 à CHS-023 | Character Studio navigable et édition d’identité opérationnelle | Phase 1 |
| 3 — Portraits et dialogues | CHS-030 à CHS-036 | Portraits globaux éditables et réellement affichés en dialogue | Phase 2 |
| 4 — Matrice et runtime d’animation | CHS-040 à CHS-046 | Animations système/custom éditables et jouées réellement | Phase 2 |
| 5 — Certification et livraison | CHS-050 à CHS-054 | Export, accessibilité, MCP et golden slice certifiés | Phases 3 et 4 |
| 6 — Durcissement final | CHS-055 à CHS-061 | Preuves desktop réelles, parité des transports et démarrage éditeur certifiés | Phase 5 |
| 7 — Durcissement transactionnel | CHS-062 à CHS-065 | Références dialogue, brouillons et imports média atomiques certifiés | Phase 6 |

Les phases 3 et 4 peuvent être exécutées par deux flux indépendants une fois les phases 0–2 stabilisées. Leur intégration partage cependant le même read model personnage et doit être fusionnée/testée avant la phase 5.

---

## 6. Phase 0 — Fondations sûres

**Objectif de phase :** introduire les contrats de données sans casser les projets v6 ni transformer les brouillons incomplets en projets impossibles à sauvegarder.

**Vagues :** CHS-001 seul → CHS-002 → CHS-003 et CHS-004 en parallèle logique, avec exécution séquentielle des générateurs.

### CHS-001 — Caractériser les contrats historiques

- [x] **Résultat :** verrouiller JSON, fallbacks et validations existants avant évolution.
- **Scope :** fixtures v6, `idle/walk/run`, `tilesetId` implicite, default player, round-trip manifeste, cadence runtime.
- **Fichiers principaux :** `packages/map_core/test/project_manifest_character_compatibility_test.dart`, `packages/map_runtime/test/player_component_test.dart`, fixtures existantes du manifeste.
- **Tests à ajouter :** ancien projet sans champ Studio ; animation legacy sans source dédiée ; ordre/fallback des états ; sauvegarde d’un personnage partiel.
- **Gate :** les nouveaux tests passent avant toute modification du modèle et échoueraient si les clés ou fallbacks historiques changeaient.
- **Dépendances :** aucune.

### CHS-002 — Ajouter le schéma Character Studio additif

- [x] **Résultat :** modèles globaux, portraits et clips custom sérialisables dans v6.
- **Scope :** classes et enums listés en 4.1, defaults vides, égalité/copyWith, exports publics, génération ciblée si le package l’utilise.
- **Fichiers principaux :** `packages/map_core/lib/src/models/project_manifest.dart`, `packages/map_core/lib/src/models/enums.dart`, `packages/map_core/lib/map_core.dart`, fichiers générés directement associés.
- **Tests :** `packages/map_core/test/project_character_studio_model_test.dart` avec JSON minimal, JSON complet, `single`, `directional`, source legacy et source dédiée.
- **Non-goal :** aucune UI, aucune mutation, aucun nouveau `ProjectVersion`.
- **Gate :** `dart test test/project_character_studio_model_test.dart test/project_manifest_character_compatibility_test.dart` et `dart analyze` sans nouvelle erreur.
- **Dépendances :** CHS-001.

### CHS-003 — Migration, normalisation et round-trip v6

- [x] **Résultat :** ouvrir, éditer et resauvegarder un ancien projet sans perte ni migration forcée.
- **Scope :** defaults de décodage, normalisation d’ID, conservation des listes legacy, règle de warning pour ouverture par une version trop ancienne.
- **Fichiers principaux :** codecs/manifeste dans `packages/map_core/lib/src/models/`, chargeur de projet concerné, `packages/map_core/test/fixtures/` si une fixture consolidée est nécessaire.
- **Tests :** `packages/map_core/test/project_character_studio_migration_test.dart` couvrant ancien → nouveau → JSON, nouveau → JSON → nouveau, clés inconnues et stabilité de l’ID lors d’un rename.
- **Gate :** aucune fixture existante ne change hors ajout intentionnel ; le diff JSON est limité aux champs effectivement édités.
- **Dépendances :** CHS-002.

### CHS-004 — Validation, readiness et index de références

- [x] **Résultat :** distinguer clairement données invalides, personnage incomplet et capacité optionnelle absente.
- **Scope :** unicité, références globales, règles mode/direction, géométrie, couverture Base, diagnostics portrait/custom, usages de suppression.
- **Fichiers principaux :** validateur de projet dans `packages/map_core/lib/src/validation/`, modèles de diagnostics/readiness, index de références narratif/personnage.
- **Tests :** `packages/map_core/test/project_character_studio_validation_test.dart`, `packages/map_core/test/character_studio_reference_index_test.dart`.
- **Cas obligatoires :** quatre Base valides ; chaque direction manquante ; custom `single` avec direction interdite ; custom `directional` sans direction ; état supprimé encore référencé ; portrait absent non bloquant.
- **Gate :** un brouillon incomplet se sauvegarde, mais un export/playtest reçoit un diagnostic localisé et actionnable.
- **Dépendances :** CHS-002 ; exploite les fixtures de CHS-003.

**Gate de phase 0 :**

```bash
cd packages/map_core
dart test test/project_manifest_character_compatibility_test.dart test/project_character_studio_model_test.dart test/project_character_studio_migration_test.dart test/project_character_studio_validation_test.dart test/character_studio_reference_index_test.dart
dart analyze
```

---

## 7. Phase 1 — Authoring canonique, assets et parité

**Objectif de phase :** rendre chaque opération Studio sémantique, découvrable, révisionnée et transportable avant de construire l’UI premium.

**Vagues :** CHS-010 et CHS-015 → CHS-011/012 en parallèle → CHS-013/014 en parallèle → CHS-016 → CHS-017.

### CHS-010 — Projections et ressources de lecture Character Studio

- [x] **Résultat :** snapshots immuables du catalogue, des personnages, de la couverture et des dépendances.
- **Scope :** resources list/get, filtres, tri, selected status, readiness détaillée, révision de workspace.
- **Fichiers principaux :** nouveau domaine `packages/map_authoring/lib/src/domains/gameplay/character_studio/`, `packages/map_authoring/lib/src/registry/resource_kind_registry.dart`, barrels du package.
- **Tests :** `packages/map_authoring/test/domains/gameplay/character_studio_resource_test.dart`.
- **Gate :** deux lectures de la même révision sont déterministes ; aucune projection ne mutile le manifeste.
- **Dépendances :** phase 0.

### CHS-011 — Mutations du catalogue global de portraits

- [x] **Résultat :** créer, renommer, réordonner et supprimer sûrement les états de portrait.
- **Scope :** slug initial, ID stable, libellé validé, collisions, `expectedRevision`, `dryRun`, `deletePlan`, replace/clear transactionnel.
- **Fichiers principaux :** domaine Character Studio authoring, `action_registry.dart`, contrats de mutation.
- **Tests :** `character_studio_portrait_state_actions_test.dart` avec succès, conflit de révision, doublon, rename, dépendances dialogue/personnage et rollback.
- **Gate :** aucune suppression référencée n’est possible sans plan explicite.
- **Dépendances :** CHS-010.

### CHS-012 — Mutations du catalogue global d’animations

- [x] **Résultat :** gérer les définitions custom sans altérer Base/Marche/Course.
- **Scope :** create/update/reorder, modes `single/directional`, immutabilité conditionnelle du mode, delete plan incluant clips/cinématiques/scènes.
- **Fichiers principaux :** domaine Character Studio authoring et registry.
- **Tests :** `character_studio_animation_definition_actions_test.dart`.
- **Gate :** les définitions système sont visibles mais impossibles à supprimer ou recréer comme custom.
- **Dépendances :** CHS-010.

### CHS-013 — Mutations d’identité et de portraits par personnage

- [x] **Résultat :** CRUD personnage, default player et affectations de portraits via actions spécialisées.
- **Scope :** create/update, tags/rôle, set default, assign/replace/clear portrait, delete plan cross-références.
- **Fichiers principaux :** domaine authoring Character Studio ; adaptation ou remplacement ciblé de `campaign.character.upsert/delete` sans casser leurs callers.
- **Tests :** `character_studio_character_actions_test.dart`, incluant compatibilité des actions campaign historiques.
- **Gate :** aucune UI n’a besoin de reconstruire un `ProjectCharacterEntry` complet pour changer un portrait.
- **Dépendances :** CHS-011.

### CHS-014 — Mutations de clips, directions et frames

- [x] **Résultat :** éditer un slot de matrice et sa timeline sans sauvegarde globale opaque.
- **Scope :** upsert/delete clip, source, loop, insert/update/reorder/delete frame, durées, rectangles, built-in/custom, `single/directional`.
- **Fichiers principaux :** domaine authoring Character Studio, registry et sérialisation de payload.
- **Tests :** `character_studio_animation_clip_actions_test.dart` avec toutes les directions, limites d’index, géométrie et atomicité.
- **Gate :** chaque mutation retourne la nouvelle révision et le slot mis à jour ; un conflit ne produit aucune écriture partielle.
- **Dépendances :** CHS-012.

### CHS-015 — Import, remplacement et portabilité des assets

- [x] **Résultat :** portraits et spritesheets custom entrent dans le catalogue d’assets avec identité portable.
- **Scope :** PNG supporté, dimensions, copie contrôlée, déduplication, remplacement, référence logique, fermeture des assets orphelins, source rectangle.
- **Fichiers principaux :** `packages/map_authoring/lib/src/domains/assets/asset_store.dart`, actions assets, nouveau bridge Character Studio.
- **Tests :** `packages/map_authoring/test/domains/assets/character_studio_asset_actions_test.dart` avec chemins hors root, doublon, fichier manquant, remplacement et cleanup sûr.
- **Gate :** aucun chemin absolu n’est sérialisé ; un asset partagé n’est jamais supprimé par erreur.
- **Dépendances :** phase 0.

### CHS-016 — Adapter l’éditeur à l’API canonique

- [x] **Résultat :** une seule voie d’écriture pour les personnages.
- **Scope :** providers, session de workspace, `AuthoringMutationAdapter`, migration progressive de `character_use_cases.dart`, gestion d’expiration/reopen, feedback erreurs/révision.
- **Fichiers principaux :** `packages/map_editor/lib/src/application/use_cases/character_use_cases.dart`, providers editor/authoring, nouveau feature `character_studio/application/`.
- **Tests :** `packages/map_editor/test/features/character_studio/character_studio_authoring_adapter_test.dart`.
- **Gate :** les anciens entry points encore nécessaires délèguent aux actions canoniques ; aucune sauvegarde directe divergente ne demeure pour le Studio.
- **Dépendances :** CHS-013, CHS-014 et CHS-015.

### CHS-017 — Parité API directe, JSONL/CLI, éditeur et MCP

- [x] **Résultat :** surface officiellement découvrable sur tous les transports PokeMap.
- **Scope :** catalogue d’actions/resources, schémas JSON, exemples, JSONL native flow, MCP catalog, rebuild de `tools/pokemap_mcp`, live `pokemap_describe`.
- **Fichiers principaux :** tests de parity `packages/map_authoring/test/parity/`, `tools/pokemap_mcp/`, `pokemap_authoring_api_mcp_action_catalog.md` uniquement si le catalogue généré exige une mise à jour explicite.
- **Tests :** scénario create state → create character → import/assign portrait → create custom definition → upsert frames → save/reopen/read.
- **Gate :** mêmes entrées, diagnostics et résultat sémantique sur les quatre transports ; le catalogue live expose réellement les actions.
- **Dépendances :** CHS-010 à CHS-016.

**Gate de phase 1 :**

```bash
cd packages/map_authoring
dart test test/domains/gameplay/character_studio_resource_test.dart test/domains/gameplay/character_studio_portrait_state_actions_test.dart test/domains/gameplay/character_studio_animation_definition_actions_test.dart test/domains/gameplay/character_studio_character_actions_test.dart test/domains/gameplay/character_studio_animation_clip_actions_test.dart test/domains/assets/character_studio_asset_actions_test.dart test/parity/character_studio_full_parity_test.dart
dart analyze

cd ../../tools/pokemap_mcp
dart test
dart analyze
```

---

## 8. Phase 2 — Shell premium et identité

**Objectif de phase :** remplacer le panneau secondaire par un véritable workspace responsive, tout en conservant un accès lisible depuis l’Explorer.

**Vagues :** CHS-020 et CHS-023 → CHS-021 → CHS-022. Le découpage de l’ancien panneau est séquentiel pour éviter deux sources de vérité.

### CHS-020 — Route workspace et navigation Explorer

- [x] **Résultat :** `Character Studio` devient un mode de workspace de premier rang.
- **Scope :** `EditorWorkspaceMode.characterStudio`, controller, providers, `EditorCanvasHost`, sélection Explorer, titre/description/badge, restauration de mode.
- **Fichiers principaux :** `editor_workspace_mode.dart`, `editor_workspace_controller.dart`, `editor_canvas_host.dart`, `project_explorer_panel.dart`, workspace providers.
- **Tests :** `packages/map_editor/test/character_studio_workspace_routing_test.dart`.
- **Gate :** cliquer la carte ouvre le Studio, la carte reste sélectionnée, rouvrir le projet restaure un mode valide.
- **Dépendances :** phase 1.

### CHS-021 — Shell trois colonnes responsive

- [x] **Résultat :** structure visuelle fidèle au mockup premium.
- **Scope :** header, statut runtime, save feedback, bibliothèque, canvas central, inspecteur, seuils grand/moyen/petit, drawers/panneaux alternables.
- **Fichiers principaux :** nouveau `packages/map_editor/lib/src/features/character_studio/presentation/character_studio_workspace.dart` et widgets locaux composés uniquement de primitives design system.
- **Tests :** `character_studio_workspace_layout_test.dart` aux largeurs 1672, 1440, 1280 et largeur minimale supportée ; absence d’overflow.
- **Gate :** aucune couleur hardcodée, navigation clavier entre zones, focus visible et semantics des régions.
- **Dépendances :** CHS-020.

### CHS-022 — Bibliothèque et onglet Identité

- [x] **Résultat :** créer, chercher, filtrer, sélectionner, modifier et supprimer un personnage depuis le Studio.
- **Scope :** row compacte, avatar, rôles/tags, compteurs portraits/animations, filtres Tous/Joueurs/PNJ/incomplets, formulaire identité, default player, delete plan.
- **Fichiers principaux :** `features/character_studio/presentation/library/`, `identity/`, read model/application de la feature.
- **Tests :** `character_studio_library_test.dart`, `character_studio_identity_test.dart`, `character_studio_delete_flow_test.dart`.
- **Gate :** toutes les actions utilisent CHS-016 ; les dépendances sont affichées avant suppression ; aucun ID brut n’est demandé.
- **Dépendances :** CHS-021 et CHS-013.

### CHS-023 — Primitives d’aperçu portrait/sprite partagées

- [x] **Résultat :** rendu asynchrone, zoom, fond transparent et erreurs unifiés avant les deux onglets média.
- **Scope :** cache par asset/révision, checkerboard tokenisé, contain/cover, pixelated rendering pour sprites, loading/error/empty, annulation des résolutions obsolètes.
- **Fichiers principaux :** `features/character_studio/presentation/preview/`, resolver application partagé.
- **Tests :** `character_studio_media_preview_test.dart`, tests cache/stale request.
- **Gate :** changer rapidement personnage/slot n’affiche jamais l’asset de la sélection précédente.
- **Dépendances :** CHS-015 ; peut avancer en parallèle de CHS-020.

**Gate de phase 2 :**

```bash
cd packages/map_editor
flutter test test/character_studio_workspace_routing_test.dart test/features/character_studio/character_studio_workspace_layout_test.dart test/features/character_studio/character_studio_library_test.dart test/features/character_studio/character_studio_identity_test.dart test/features/character_studio/character_studio_delete_flow_test.dart test/features/character_studio/character_studio_media_preview_test.dart
flutter analyze
```

---

## 9. Phase 3 — Portraits, dialogues et rendu joueur

**Objectif de phase :** livrer une tranche verticale complète depuis le catalogue global jusqu’au portrait visible dans un vrai dialogue runtime.

**Vagues :** CHS-030 et CHS-033 en parallèle → CHS-031 et CHS-034 → CHS-032 et CHS-035 → CHS-036.

### CHS-030 — Gestionnaire global des états de portrait

- [x] **Résultat :** créer et administrer les expressions au niveau projet.
- **Scope :** liste triée, create, rename, drag/reorder ou commandes accessibles, couverture globale, delete plan, replace/clear, libellé/ID séparés.
- **Fichiers principaux :** `features/character_studio/presentation/catalog/portrait_state_manager.dart` et state associé.
- **Tests :** `character_studio_portrait_state_manager_test.dart`.
- **Gate :** rename conserve les portraits/dialogues ; suppression référencée montre exactement personnages et dialogues touchés.
- **Dépendances :** phase 2 et CHS-011.

### CHS-031 — Onglet Portraits et affectation par personnage

- [x] **Résultat :** grille fidèle au mockup 1, avec aperçu principal et import/remplacement.
- **Scope :** sélection d’état, cartes défini/non défini, add/replace/clear, preview grand format, zoom, fond, fit/cadrage, raccourci vers catalogue global.
- **Fichiers principaux :** `features/character_studio/presentation/portraits/`.
- **Tests :** `character_studio_portraits_tab_test.dart`, `character_studio_portrait_import_test.dart`.
- **Gate :** feedback progress/success/error ; asset invalide non enregistré ; sélection préservée après mutation.
- **Dépendances :** CHS-030, CHS-023 et CHS-015.

### CHS-032 — Inspecteur portrait, couverture et aperçu de dialogue

- [x] **Résultat :** inspecteur droit complet et lisible.
- **Scope :** libellé, clé stable read-only, source, replace, fit/crop, validation, compteur d’usages, personnages manquants, bulle de dialogue d’aperçu.
- **Fichiers principaux :** `features/character_studio/presentation/portraits/portrait_inspector.dart`, diagnostics/read model.
- **Tests :** `character_studio_portrait_inspector_test.dart`.
- **Gate :** les diagnostics distinguent source invalide, portrait absent et référence utilisée ; l’aperçu suit la sélection courante.
- **Dépendances :** CHS-031 et CHS-004.

### CHS-033 — Contrat de dialogue structuré et rétrocompatible

- [x] **Résultat :** une ligne peut porter `characterId` et `portraitStateId` optionnels sans casser les dialogues texte existants.
- **Scope :** nouvelle version lisible du document runtime ou extension additive explicitement testée, codec acceptant les versions historiques, directive Yarn PokeMap avant la ligne, propagation dans choix/branches.
- **Syntaxe proposée :** `<<portrait elia surprised>>` s’applique uniquement à la ligne suivante ; sans directive, parsing historique `Speaker: texte` inchangé.
- **Fichiers principaux :** `packages/map_core/lib/src/dialogue/runtime_dialogue_document.dart`, compilateur Yarn, codecs/diagnostics associés.
- **Tests :** `runtime_dialogue_portrait_metadata_test.dart`, mise à jour ciblée de `runtime_dialogue_document_test.dart`.
- **Gate :** ancien document → même présentation ; nouvelle directive → IDs structurés ; directive invalide → diagnostic localisé sans crash.
- **Dépendances :** phase 0 ; peut avancer en parallèle de CHS-030.

### CHS-034 — Pickers personnage/expression dans Dialogue Studio

- [x] **Résultat :** auteur no-code, directive masquée et round-trip fidèle.
- **Scope :** enrichir `DeLineStep`, pickers guidés, état par défaut, preview, encode/decode Yarn, copier/coller, lignes de choix.
- **Fichiers principaux :** `features/dialogue/application/dialogue_editor_model.dart`, `dialogue_yarn_codec.dart`, widgets du Dialogue Studio.
- **Tests :** `dialogue_character_portrait_picker_test.dart`, `dialogue_yarn_portrait_round_trip_test.dart`.
- **Gate :** l’utilisateur ne saisit jamais la directive ; un fichier Yarn existant sans métadonnées reste byte-stable hors ligne éditée.
- **Dépendances :** CHS-033 et ressources CHS-010.

### CHS-035 — Résolution runtime des portraits

- [x] **Résultat :** convertir les IDs de dialogue en asset affichable avec fallback sûr.
- **Scope :** resolver manifeste/catalogue/assets, cache, snapshot enrichi, speaker legacy, référence supprimée, asset absent, préchargement borné.
- **Fichiers principaux :** `packages/map_runtime/lib/src/application/dialogue_runtime_models.dart`, `presentation/flutter/dialogue_presentation_snapshot.dart`, nouveau resolver portrait.
- **Tests :** `packages/map_runtime/test/dialogue_portrait_resolver_test.dart`, extension de `dialogue_presentation_snapshot_test.dart` et `compiled_dialogue_runtime_test.dart`.
- **Gate :** métadonnée valide fournit le portrait ; invalide/absente retombe sur le dialogue texte sans bloquer l’histoire.
- **Dépendances :** CHS-031, CHS-033 et packaging asset de CHS-015.

### CHS-036 — Affichage portrait dans `map_player_ui`

- [x] **Résultat :** portrait réellement visible dans la bulle de dialogue joueur.
- **Scope :** layout avec/sans portrait, speaker, texte long, choix, petits écrans, safe areas, accessibilité, animation de changement discrète et testable.
- **Fichiers principaux :** `packages/map_player_ui/lib/src/player/player_dialogue_overlay.dart`, design tokens/composants existants si extension nécessaire.
- **Tests :** `player_dialogue_portrait_overlay_test.dart`, goldens clair/sombre, portrait absent, texte long, choix et narrow layout.
- **Gate :** aucun déplacement régressif quand il n’y a pas de portrait ; semantics du portrait décoratif/nom accessibles correctement.
- **Dépendances :** CHS-032 et CHS-035.

**Gate de phase 3 :**

```bash
cd packages/map_core
dart test test/runtime_dialogue_document_test.dart test/runtime_dialogue_portrait_metadata_test.dart

cd ../map_editor
flutter test test/features/character_studio/character_studio_portrait_state_manager_test.dart test/features/character_studio/character_studio_portraits_tab_test.dart test/features/character_studio/character_studio_portrait_import_test.dart test/features/character_studio/character_studio_portrait_inspector_test.dart test/dialogue_character_portrait_picker_test.dart test/dialogue_yarn_portrait_round_trip_test.dart

cd ../map_runtime
flutter test test/dialogue_portrait_resolver_test.dart test/dialogue_presentation_snapshot_test.dart test/compiled_dialogue_runtime_test.dart

cd ../map_player_ui
flutter test test/player_dialogue_overlay_test.dart test/player_dialogue_portrait_overlay_test.dart
```

---

## 10. Phase 4 — Matrice d’animations et consommation runtime

**Objectif de phase :** livrer la matrice appréciée dans la proposition 2, puis prouver qu’un clip custom n’est pas seulement joli dans l’éditeur mais réellement jouable.

**Vagues :** CHS-040 et CHS-044 en parallèle → CHS-041 → CHS-042/043 en parallèle contrôlé → CHS-045 → CHS-046.

### CHS-040 — Gestionnaire global des définitions d’animation

- [x] **Résultat :** catalogue système + custom compréhensible au niveau projet.
- **Scope :** Base/Marche/Course read-only, create custom, nom, mode, tri, couverture, delete plan, migration de mode explicite.
- **Fichiers principaux :** `features/character_studio/presentation/catalog/animation_definition_manager.dart`.
- **Tests :** `character_studio_animation_definition_manager_test.dart`.
- **Gate :** impossible de supprimer Base/Marche/Course ou de créer une custom avec un ID réservé.
- **Dépendances :** phase 2 et CHS-012.

### CHS-041 — Read model et grille de matrice unifiée

- [x] **Résultat :** tableau Base/Marche/Course/custom × N/S/E/O ou slot unique.
- **Scope :** ordering global, statut requis/optionnel, défini/manquant/invalide, compte de frames, sélection clavier, filtres, focus conservé.
- **Fichiers principaux :** `features/character_studio/application/character_animation_matrix_model.dart`, `presentation/animations/animation_matrix.dart`.
- **Tests :** `character_animation_matrix_model_test.dart`, `character_animation_matrix_widget_test.dart`.
- **Gate :** Base manquante est rouge/bloquante ; optionnel manquant est ambre ; custom `single` n’affiche pas quatre faux slots.
- **Dépendances :** CHS-040 et CHS-004.

### CHS-042 — Source, découpe et timeline de frames

- [x] **Résultat :** éditer précisément le contenu du slot sélectionné.
- **Scope :** choisir/remplacer source, dimensions, grille assistée, rectangles, ajout/suppression/duplication/réordre, durée par frame, validation instantanée.
- **Fichiers principaux :** `features/character_studio/presentation/animations/frame_timeline.dart`, `sprite_source_inspector.dart`, modèles de formulaire.
- **Tests :** `character_animation_frame_timeline_test.dart`, `character_animation_source_slicing_test.dart`.
- **Gate :** aucune frame hors image ou durée invalide n’est appliquée ; la correction proposée ne modifie que le slot sélectionné.
- **Dépendances :** CHS-041, CHS-014 et CHS-015.

### CHS-043 — Aperçu live, playback et boucle

- [x] **Résultat :** preview centrale fidèle aux durées et à l’ordre réel des frames.
- **Scope :** play/pause, frame step, vitesse d’aperçu non persistée, loop persistée, direction, zoom pixel-perfect, fond, empty/error, annulation au changement de slot.
- **Fichiers principaux :** `features/character_studio/presentation/animations/animation_preview.dart`, controller/ticker testable.
- **Tests :** `character_animation_preview_test.dart` avec fake clock, boucle/non-boucle et changement de sélection.
- **Gate :** aucun `Timer` non déterministe dans les tests ; la cadence preview correspond au runtime pour les mêmes frames.
- **Dépendances :** CHS-041 et CHS-023 ; se raccorde à CHS-042.

### CHS-044 — Source dédiée et fallbacks runtime système

- [x] **Résultat :** Base/Marche/Course peuvent utiliser une source dédiée sans régression legacy.
- **Scope :** resolver source, préchargement, `overworld_actor_component.dart`, player/NPC/cinematic previews, fallback `tilesetId`, cadence et direction.
- **Fichiers principaux :** `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`, `application/runtime_character_refs.dart`, resolvers actor existants.
- **Tests :** `character_animation_source_resolver_test.dart`, extensions ciblées de `player_component_test.dart` et previews editor concernées.
- **Gate :** fixtures legacy rendu identique ; source dédiée choisie quand valide ; source manquante produit diagnostic + fallback défini.
- **Dépendances :** phase 0 et packaging CHS-015 ; peut avancer en parallèle de CHS-040.

### CHS-045 — Contrat runtime dédié pour animation custom

- [x] **Résultat :** jouer une custom sur un acteur, attendre ou interrompre proprement, puis restaurer son état.
- **Scope :** commande pure identifiée par définition, direction facultative, loop/count/duration, policy d’interruption, completion déterministe, fallback/diagnostic.
- **Fichiers principaux :** modèles cinématiques/scènes de `map_core`, port runtime dans `map_runtime/application`, sink Flame ; ne pas toucher à la sémantique `actorEmote`.
- **Tests :** `character_custom_animation_runtime_test.dart`, tests interruption, acteur absent, clip absent, `single/directional`, restauration Base.
- **Gate :** aucune boucle infinie ne bloque une scène ; une commande attendable a toujours une règle de fin explicite.
- **Dépendances :** CHS-014 et CHS-044.

### CHS-046 — Authoring cinématique/scène et previews custom

- [x] **Résultat :** déclencher une custom depuis les outils narratifs no-code et voir le même résultat en preview/runtime.
- **Scope :** nouveau step/command dédié, picker acteur + définition + direction, diagnostics de capacité, timeline preview, encode/decode, exécuteur scene runtime.
- **Fichiers principaux :** Cinematic Builder, modèles de commande interactifs, `scene_interactive_command_runtime_executor.dart`, `flame_cinematic_runtime_playback_sink.dart`, preview adapters.
- **Tests :** builder widget tests, codec tests, `cinematic_custom_character_animation_test.dart`, scene runtime executor tests.
- **Gate :** rename d’une définition ne casse pas la commande ; suppression référencée est bloquée ; preview et runtime consomment le même ID stable.
- **Dépendances :** CHS-040, CHS-043 et CHS-045.

**Gate de phase 4 :**

```bash
cd packages/map_editor
flutter test test/features/character_studio/character_studio_animation_definition_manager_test.dart test/features/character_studio/character_animation_matrix_model_test.dart test/features/character_studio/character_animation_matrix_widget_test.dart test/features/character_studio/character_animation_frame_timeline_test.dart test/features/character_studio/character_animation_source_slicing_test.dart test/features/character_studio/character_animation_preview_test.dart

cd ../map_runtime
flutter test test/character_animation_source_resolver_test.dart test/character_custom_animation_runtime_test.dart test/player_component_test.dart test/cinematic_custom_character_animation_test.dart
```

---

## 11. Phase 5 — Export, certification et livraison

**Objectif de phase :** fermer les trous entre une belle UI et un vrai produit, ce petit détail que l’industrie appelle parfois « fonctionner ».

**Vagues :** CHS-050 et CHS-051 en parallèle → CHS-052 et CHS-053 en parallèle → CHS-054.

### CHS-050 — Export, installation et fermeture des assets

- [x] **Résultat :** tous les assets Studio nécessaires sont emballés et résolus dans le projet jouable.
- **Scope :** dependency closure, chemins portables, déduplication, assets orphelins, invalidation cache, import/export/reimport, diagnostics précis.
- **Fichiers principaux :** pipeline d’export du projet, asset manifest runtime, install/import du projet jouable.
- **Tests :** `character_studio_export_asset_closure_test.dart`, fixture exportée avec portraits, sources dédiées et custom.
- **Gate :** déplacer le projet exporté puis le lancer ne dépend d’aucun chemin machine source.
- **Dépendances :** phases 3 et 4.

### CHS-051 — Responsive, accessibilité et goldens premium

- [x] **Résultat :** visuel stabilisé et interactions utilisables hors écran de démonstration.
- **Scope :** thèmes clair/sombre, 1672/1440/1280/minimum, focus order, clavier, screen reader, contrastes, longs libellés FR, 0/1/50 personnages, 0/20 états/custom.
- **Fichiers principaux :** tests/goldens Character Studio ; extensions design system seulement si un vrai primitive manque.
- **Tests :** goldens shell/portrait/matrice/inspecteurs/empty/error, widget tests keyboard/semantics/overflow.
- **Gate :** aucun overflow, contrôle masqué ou action uniquement basée sur la couleur.
- **Dépendances :** phases 3 et 4.

### CHS-052 — Golden slice end-to-end

- [x] **Résultat :** scénario déterministe complet prouvant la chaîne de valeur.
- **Scénario :** ouvrir projet v6 → créer `Surprise` → assigner portrait à Élia → créer custom `Saluer` directionnelle → configurer quatre clips → ajouter ligne de dialogue avec portrait → ajouter commande cinématique → sauvegarder → fermer/réouvrir → exporter → lancer → voir portrait → jouer Saluer → restaurer Base.
- **Couches prouvées :** modèles, validation, actions, JSONL/MCP, éditeur no-code, persistance, export, runtime et UI joueur.
- **Fichiers principaux :** fixture golden consolidée et tests d’intégration existants appropriés ; pas de deuxième framework de certification.
- **Gate :** même résultat après reload et dans le projet exporté ; diagnostics vides pour le personnage prêt.
- **Dépendances :** CHS-050 et toutes les tranches fonctionnelles.

### CHS-053 — Certification MCP live et documentation de contrat

- [x] **Résultat :** vérifier le serveur réellement construit, pas seulement des registry tests.
- **Scope :** rebuild MCP, démarrage, `pokemap_describe`, ressources/actions listées, mutation dry-run puis apply dans un workspace autorisé, requery, fermeture.
- **Fichiers principaux :** tests MCP/JSONL et catalogue canonique si nécessaire.
- **Gate :** aucune action fantôme dans la documentation ; aucun comportement Studio disponible uniquement depuis l’éditeur.
- **Dépendances :** CHS-017 et sémantique finale des phases 3/4.

### CHS-054 — Validation complète et dossier de clôture

- [x] **Résultat :** décision explicite `DONE`, `PARTIAL` ou `BLOCKED` avec preuves fraîches.
- **Scope :** format ciblé, tests/analyzes package par package, builds nécessaires, markdown hygiene, diff check, inventaire des changements, risques restants, état Git final.
- **Commandes minimales :** suites complètes `map_core`, `map_authoring`, `map_editor`, `map_runtime`, `map_player_ui`, `tools/pokemap_mcp`, puis smoke du host jouable si le flux export/runtime est touché.
- **Gate :** aucun lot n’est marqué terminé si sa preuve de couche applicable manque ; les échecs legacy non liés sont séparés et documentés avec leur commande exacte.
- **Dépendances :** CHS-050 à CHS-053.

**Gate de phase 5 :**

```bash
cd packages/map_core && dart test && dart analyze
cd ../map_authoring && dart test && dart analyze
cd ../map_editor && flutter test && flutter analyze
cd ../map_runtime && flutter test && flutter analyze
cd ../map_player_ui && flutter test && flutter analyze
cd ../../tools/pokemap_mcp && dart test && dart analyze
cd ../../examples/playable_runtime_host && flutter test && flutter analyze
cd ../.. && bash tools/scripts/check_markdown_hygiene.sh && git diff --check
```

---

## 12. Phase 6 — Durcissement post-certification

**Objectif de phase :** fermer les derniers écarts découverts par l’usage réel après S9 : prouver les sprites dans l’interface, certifier chaque transport Character Studio et supprimer l’assertion Riverpod qui pouvait polluer le démarrage de l’application.

**Vagues :** CHS-055 → CHS-056 → CHS-057/058 → CHS-059 → CHS-060 → CHS-061.

### CHS-055 — Harness desktop déterministe

- [x] **Résultat :** un entrypoint Marionette ouvre un projet explicite sans modifier la logique de production.
- **Scope :** bootstrap desktop de développement, `MARIONETTE_PROJECT_PATH`, contexte projet et ouverture déterministe du Studio.
- **Fichiers principaux :** `packages/map_editor/dev/marionette_main.dart`, `packages/map_editor/test/dev/marionette_main_test.dart`.
- **Gate :** l’entrypoint reste séparé de `main.dart`, refuse les chemins ambigus et publie le projet réellement restauré.
- **Commit :** `6076307e6 test(character-studio): add desktop visual harness`.

### CHS-056 — Preuves de vrais sprites dans les previews

- [x] **Résultat :** la matrice et l’aperçu live prouvent le rendu de sources PNG réelles, pas seulement la présence de widgets.
- **Scope :** thumbnails par slot, preview centrale, fixture image, golden 1920 × 1080 et stabilité responsive.
- **Fichiers principaux :** `character_studio_workspace.dart`, `character_studio_responsive_accessibility_golden_test.dart`, `character_studio_real-sprite-previews_1920x1080.png`.
- **Gate :** le golden contient des pixels différents par direction et l’aperçu live du slot sélectionné.
- **Commit :** `4e1526549 test(character-studio): certify real sprite previews`.

### CHS-057 — Transports identité et portraits

- [x] **Résultat :** les mutations d’identité, default player, portraits et états globaux sont prouvées sur API directe, JSONL/CLI, éditeur et MCP.
- **Scope :** create/update/delete plan/delete, assign/clear portrait, create/update/reorder/delete plan/delete d’état, receipts et erreurs.
- **Fichiers principaux :** worker JSONL, parity Character Studio, adapter éditeur et tests du serveur MCP.
- **Gate :** scénario complet avec révision, relecture et absence d’écriture partielle sur erreur.
- **Commit :** `c0d818d16 test(character-studio): certify identity and portrait transports`.

### CHS-058 — Transports animations, frames et assets

- [x] **Résultat :** toutes les mutations d’animation et d’asset sont prouvées sur les quatre transports.
- **Scope :** définitions, clips, frames, import/replace, payloads JSONL, receipts éditeur et cycle MCP.
- **Fichiers principaux :** worker JSONL, parity Character Studio, `editor_receipt_presenter.dart`, adapter éditeur et tests MCP.
- **Gate :** source importée, clip créé, frames insérées/modifiées/réordonnées/supprimées, puis relecture identique.
- **Commit :** `fd75320ab test(character-studio): certify animation transports`.

### CHS-059 — Publication canonique des preuves de parité

- [x] **Résultat :** les 25 actions Character Studio portent leurs preuves de transport dans `fullParity`.
- **Scope :** registre canonique, test exhaustif des IDs, publication par le serveur MCP réellement packagé.
- **Fichiers principaux :** `full_authoring_parity.dart`, `full_authoring_parity_test.dart`, `mutation_server.test.ts`.
- **Gate :** aucune action Character Studio absente, fantôme ou dépourvue de la certification attendue.
- **Commit :** `d979c44f1 test(authoring): register character studio parity evidence`.

### CHS-060 — Réconciliation Riverpod sûre au démarrage

- [x] **Résultat :** le montage initial de `EditorNotifier` ne modifie plus un provider pendant la construction de l’arbre Flutter.
- **Scope :** différer uniquement la première réconciliation Border, conserver les réconciliations synchrones suivantes et relire l’état courant après la microtask.
- **Fichiers principaux :** `editor_notifier.dart`, `editor_notifier_startup_reconciliation_test.dart`.
- **Gate :** reproduction widget de l’assertion historique, puis 59/59 tests ciblés et `flutter analyze` sans diagnostic.
- **Commit :** `c0d6fa36a fix(editor): defer startup selection reconciliation`.

### CHS-061 — Certification finale et roadmap synchronisée

- [x] **Résultat :** chaîne Character Studio recertifiée de `map_core` au desktop réel, roadmap CHS-001…CHS-061 et dossier de clôture consolidé.
- **Scope :** suites verticales, analyses, smoke host, build macOS, serveur MCP packagé, cycle MCP live, captures desktop, hygiène Git/Markdown et risques résiduels.
- **Fichiers principaux :** cette roadmap et `documentation/reports/editor/character_studio_final_closure_2026-08-12.md`.
- **Gate :** preuves fraîches consignées dans la clôture, aucun fichier produit modifié dans ce lot documentaire et worktree propre après commit.

**Gate de phase 6 :**

```bash
cd packages/map_core && dart test test/project_character_studio_model_test.dart test/project_character_studio_migration_test.dart test/project_character_studio_validation_test.dart test/character_studio_reference_index_test.dart test/runtime_dialogue_portrait_metadata_test.dart test/character_custom_animation_runtime_contract_test.dart test/cinematic_character_custom_animation_contract_test.dart && dart analyze
cd ../map_authoring && dart test test/domains/gameplay/character_studio_resource_test.dart test/domains/gameplay/character_studio_portrait_state_actions_test.dart test/domains/gameplay/character_studio_animation_definition_actions_test.dart test/domains/gameplay/character_studio_character_actions_test.dart test/domains/gameplay/character_studio_animation_clip_actions_test.dart test/domains/assets/character_studio_asset_actions_test.dart test/parity/character_studio_full_parity_test.dart && dart analyze
cd ../map_editor && flutter test test/features/character_studio test/character_studio_export_asset_closure_test.dart test/character_studio_golden_slice_e2e_test.dart test/character_studio_workspace_routing_test.dart && flutter analyze && flutter build macos --debug
cd ../map_runtime && flutter test test/character_animation_source_resolver_test.dart test/character_custom_animation_runtime_test.dart test/character_studio_golden_slice_runtime_test.dart test/cinematic_custom_character_animation_test.dart test/dialogue_portrait_resolver_test.dart && flutter analyze
cd ../map_player_ui && flutter test test/player_dialogue_overlay_test.dart test/player_dialogue_portrait_overlay_test.dart && flutter analyze
cd ../../tools/pokemap_mcp && npm run check && npm test
cd ../../examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart && flutter analyze
cd ../.. && bash tools/scripts/check_markdown_hygiene.sh && git diff --check
```

## 13. Phase 7 — Durcissement transactionnel S13

**Objectif de phase :** fermer les quatre écarts restants révélés par l’audit post-S12 : références de personnages dans les directives de portrait Yarn, perte silencieuse d’un brouillon d’identité à la fermeture, imports média en deux mutations et accumulation future des assets d’animation remplacés.

**Vagues :** CHS-062 → CHS-063 → CHS-064 → CHS-065.

### CHS-062 — Suppression consciente des portraits de dialogue

- [x] **Résultat :** `characterStudio.character.deletePlan` recense les directives `<<portrait character state>>` et `characterStudio.character.delete` les efface ou remplace dans la même transaction que le manifeste et les cartes.
- **Scope :** sources Yarn UTF-8, preview de dépendances, résolutions `clear` et `replace`, comptage exact ; aucune réécriture des dialogues sans référence au personnage.
- **Fichiers principaux :** `character_studio_character_actions.dart`, `character_studio_character_actions_test.dart`.
- **Gate :** 24 tests Authoring ciblés réussis, dont plan, clear, replace et parité Character Studio ; `dart analyze` sans diagnostic.
- **Commit :** `1447681ff fix(character-studio): resolve dialogue character references`.

### CHS-063 — Brouillons d’identité et fermeture protégée

- [x] **Résultat :** tout brouillon d’identité marque le projet comme non synchronisé et une demande de fermeture propose explicitement de rester ou de quitter sans enregistrer.
- **Scope :** état sale global, conservation du brouillon après annulation, destruction uniquement après confirmation de sortie ; aucune persistance implicite d’un formulaire incomplet.
- **Fichiers principaux :** `character_studio_identity_draft_controller.dart`, `editor_shell_page.dart`, `status_bar.dart`, `character_studio_workspace_layout_test.dart`.
- **Gate :** 28 tests widget ciblés réussis ; scénario de sortie `cancel` puis `exit` prouvé ; `flutter analyze` sans diagnostic.
- **Commit :** `104120f23 fix(character-studio): guard unsaved identity drafts`.

### CHS-064 — Imports média atomiques et remplacement borné

- [x] **Résultat :** l’import du PNG, sa publication dans le catalogue et son affectation au portrait ou au clip forment une seule mutation canonique ; une réimportation de source portable réutilise son `assetId` et supprime transactionnellement l’ancien blob lorsqu’il n’est plus partagé.
- **Scope :** binding optionnel des actions `characterStudio.asset.import/replace`, portraits, clips système/custom, source historique vers premier asset portable, API directe, JSONL/CLI, éditeur et MCP live.
- **Fichiers principaux :** `character_studio_asset_actions.dart`, services d’import portrait/animation, tests Authoring, Editor et `mutation_server.test.ts`.
- **Gate :** 32 tests Authoring ciblés, 18 tests Editor ciblés et le scénario MCP CHS-058 réussis ; analyses `map_authoring` et `map_editor` sans diagnostic ; build TypeScript MCP réussi.
- **Commits :** `2ac5e0876 fix(character-studio): make media imports atomic`, puis `bc741d579 fix(character-studio): isolate shared media replacements` après la passe critique sur les assets multi-slots.

### CHS-065 — Recertification et synchronisation S13

- [x] **Résultat :** les verticales Core, Authoring, Editor, Runtime, Player UI, host et MCP ont été rejouées ; le build macOS debug et la politique SPM-only sont prouvés.
- **Scope :** tests ciblés Character Studio, analyses de packages, build desktop, suite MCP packagée, hygiène Git/Markdown et documentation honnête des réserves globales.
- **Fichiers principaux :** cette roadmap uniquement.
- **Réserves :** `map_runtime` conserve 7 diagnostics `info` et `playable_runtime_host` 27 diagnostics `info`, tous hors fichiers S13 ; leurs tests ciblés réussissent respectivement 20/20 et 10/10. `map_core` signale 121 `info` avec un code de sortie nul.
- **Gate fonctionnelle :** Core 43/43, Authoring 59/59, Editor 94/94, Runtime 20/20, Player UI 11/11, host 10/10, MCP 46/46 plus rejeu ciblé CHS-058, et politique macOS SPM 2/2.

**Verdict des passes S13 :**

| Passe | Verdict | Preuve |
|---|---|---|
| Audit / architecture | `PASS` | Les références Yarn, le cache de brouillons, les doubles mutations et le cycle de vie des assets ont été tracés avant modification. |
| Implémentation | `PASS` | Trois lots produit bornés livrés en quatre commits, dont un correctif issu de la critique, sans nouveau schéma de projet ni nouveau chemin d’écriture. |
| Tests | `PASS` | Cas positifs, erreurs, annulation de sortie, réécriture clear/replace, atomicité, relecture et parité directe/JSONL/MCP couverts. |
| Build / validation | `PASS_WITH_RESERVATIONS` | Build macOS et MCP réussis ; réserves d’analyse globales préexistantes consignées sans les masquer. |
| Critique finale | `PASS_WITH_RISKS` | Pas d’écriture partielle identifiée ; les anciens enregistrements d’assets déjà orphelins ne sont pas nettoyés rétroactivement. |

## 14. Ordonnancement recommandé des sessions

| Session | Lots groupés | Pourquoi ce batch reste cohérent |
|---|---|---|
| S1 | CHS-001 à CHS-004 | Une seule frontière de schéma/compatibilité, validée avant toute UI |
| S2 | CHS-010, CHS-011, CHS-012, CHS-015 | Ressources et catalogues globaux, assets en parallèle logique |
| S3 | CHS-013, CHS-014, CHS-016, CHS-017 | Mutations personnage/clip puis branchement et parity |
| S4 | CHS-020 à CHS-023 | Shell complet et identité, sans encore mêler les verticales média |
| S5 | CHS-030 à CHS-034 | Authoring portraits et contrat dialogue jusqu’au round-trip éditeur |
| S6 | CHS-035, CHS-036 | Runtime + UI joueur des portraits |
| S7 | CHS-040 à CHS-043 | Catalogue, matrice, timeline et preview d’animation |
| S8 | CHS-044 à CHS-046 | Consommation runtime et authoring narratif des custom |
| S9 | CHS-050 à CHS-054 | Packaging, golden slice, MCP live et certification |
| S10 | CHS-055, CHS-056 | Harness desktop puis preuve visuelle de vrais sprites |
| S11 | CHS-057 à CHS-059 | Certification des quatre transports et publication de la parité |
| S12 | CHS-060, CHS-061 | Démarrage Riverpod sûr puis certification finale consolidée |
| S13 | CHS-062 à CHS-065 | Références dialogue, brouillons, atomicité média puis recertification verticale |

Chaque session peut produire plusieurs lots, mais le verdict et les tests restent enregistrés lot par lot. On évite ainsi le commit « Character Studio final vraiment final v7 bis » de 18 000 lignes, créature légendaire dont personne ne souhaite faire la review.

## 15. Définition de Done par lot et par phase

### Lot terminé

- [x] Scope et non-goals respectés.
- [x] Tests du lot écrits et verts.
- [x] API publique/barrels/génération ajustés seulement si nécessaires.
- [x] Validation et messages no-code actionnables.
- [x] Parité MCP évaluée : prouvée, explicitement N/A ou lot dépendant identifié.
- [x] Pas de couleur hardcodée ni primitive editor hors design system.
- [x] Diff limité au lot, aucun travail concurrent écrasé.
- [x] État Git final et limites rapportés.

### Phase terminée

- [x] Tous les lots de la phase satisfont leur gate.
- [x] Suites croisées de la phase vertes.
- [x] Reload/persistence prouvés pour toute nouvelle donnée.
- [x] Aucun chemin d’écriture alternatif ne contourne l’API canonique.
- [x] Les diagnostics de readiness sont cohérents entre éditeur, export et runtime.
- [x] Une courte auto-critique recense dette, risques et décision pour la phase suivante.

## 16. Risques et décisions à surveiller

1. **Downgrade v6 :** garder le numéro v6 évite une explosion de contrats Smart Tiles, mais un ancien éditeur qui réécrit des JSON inconnus peut perdre les champs Studio. Mitigation : round-trip testé dans la version courante, warning de version minimale et backup avant downgrade.
2. **Deux sources d’assets :** le `tilesetId` historique et les nouveaux asset IDs peuvent diverger. Mitigation : resolver unique, fallback explicitement testé, export closure centralisée.
3. **Dialogue texte historique :** modifier agressivement `Speaker: texte` casserait du contenu. Mitigation : métadonnées optionnelles, directive one-shot et codec v1/v2 rétrocompatible.
4. **Suppression globale :** un état ou une custom peut être référencé très loin. Mitigation : reference index et delete plan transactionnel, jamais de force opaque.
5. **Boucles custom :** une animation loop dans une scène attendable peut bloquer le scénario. Mitigation : policy de completion obligatoire et timeout/durée/count explicites.
6. **Performance :** grandes images et nombreux personnages peuvent saturer mémoire et décodage. Mitigation : previews dimensionnées, cache borné par révision, annulation des requêtes obsolètes, préchargement runtime ciblé.
7. **Duplication UI :** conserver Character Library et Character Studio comme deux CRUD complets créerait une dérive. Mitigation : un seul adapter canonique, ancien panneau réduit à la navigation ou retiré à la phase 2.
8. **Dette design system :** l’ancien panneau contient des exceptions historiques. Mitigation : la nouvelle feature n’en hérite pas ; une primitive manquante est ajoutée au design system avant usage.
9. **Portée narrative :** cinématiques et scènes possèdent plusieurs exécuteurs. Mitigation : une commande de domaine commune, adapters explicites, tests preview/runtime et diagnostics de capacité.
10. **Roadmap volumineuse :** 46 lots peuvent encourager des implémentations partielles présentées comme finies. Mitigation : gates verticales et statut par couche, pas de `DONE` esthétique.

## 17. Passes de revue de cette roadmap

| Passe | Verdict | Vérification |
|---|---|---|
| Audit / architecture | `PASS` | Les modèles, l’éditeur, le dialogue, le runtime, les assets et `map_authoring` ont été tracés avant le découpage. |
| Plan d’implémentation | `PASS` | 46 lots ordonnés en 8 phases et 13 sessions, avec dépendances, fichiers, tests et gates explicites. |
| Tests / caractérisation | `PASS` | Baseline initiale conservée et gates S13 rejouées de Core au serveur MCP packagé. |
| Build / validation produit | `PASS_WITH_RESERVATIONS` | Build macOS SPM réussi ; diagnostics `info` globaux hors S13 consignés en CHS-065. |
| Critique finale | `PASS_WITH_RISKS` | Le partage multi-slots est protégé ; le nettoyage rétroactif des anciens assets déjà orphelins reste hors scope. |

## 18. Fichiers et changements produits par ce travail

- Document canonique mis à jour : `documentation/reports/roadmap/editor/character_studio_roadmap.md`.
- Zones couvertes : audit initial, contrat produit, architecture cible, 46 lots en 8 phases, 13 sessions, commandes de gate, Definition of Done, risques et passes de revue.
- La synchronisation CHS-055 à CHS-065 est documentaire ; les changements produit et tests associés restent tracés par leurs commits et par la clôture finale.
