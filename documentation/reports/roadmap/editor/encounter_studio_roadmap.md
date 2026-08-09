# Encounter Studio — Roadmap d’implémentation

## 0. Carte d’identité

- Date de création : 2026-08-09.
- Domaine principal : `packages/map_editor`.
- Domaines de parité : `packages/map_authoring` et `tools/pokemap_mcp`.
- Préfixe des lots : `ENS` pour **Encounter Studio**.
- Direction produit validée : un workspace central `Encounter Studio` avec deux
  sections distinctes, `Rencontres sauvages` et `Dresseurs`.
- Référence visuelle : maquette hybride validée durant la session de conception,
  conservée hors dépôt ; elle guide la hiérarchie mais ne devient pas une
  dépendance de build.
- Lot mécanique adjacent : `FG-108 — Encounter Authoring Validation V0`.
- Statut de préparation : `READY`.
- Statut d’implémentation : tous les lots restent `TODO` tant que leurs preuves
  fraîches ne sont pas réunies.

Cette roadmap ne modifie pas `pokemap_roadmap_mecaniques_fangame.md` et ne ferme
aucun lot `FG-*`. Une promotion de `FG-108` devra être demandée et prouvée
séparément.

---

## 1. Résumé exécutif

Le modèle, le runtime walk/surf et un panneau Flutter de création des tables de
rencontres existent déjà. Le défaut actuel est un défaut d’intégration produit :
`EncounterTablesPanel` reste monté uniquement dans l’ancien
`MapInspectorPanel`, qui n’est plus utilisé par le workspace World Map actuel.
L’interface est donc fonctionnelle en test isolé mais inaccessible dans le
produit.

La cible n’est pas de replacer ce panneau dans la World Map. La World Map doit
rester une surface contextuelle d’affectation d’une table existante à une zone.
La création, l’édition, la validation et la gestion des adversaires appartiennent
au nouveau `Encounter Studio`.

L’implémentation est découpée en onze lots atomiques regroupés en cinq phases :

1. sécuriser les contrats existants et la persistance canonique ;
2. créer le shell `Encounter Studio` et y préserver le Studio Dresseurs ;
3. construire la nouvelle expérience des rencontres sauvages ;
4. restaurer une frontière nette avec la World Map et certifier l’UI desktop ;
5. prouver le parcours de bout en bout et fermer les gates de parité.

---

## 2. Décisions verrouillées

1. Le nom produit est `Encounter Studio`.
2. Le studio contient exactement deux sections de premier niveau :
   `Rencontres sauvages` et `Dresseurs`.
3. La toolbar ouvre le workspace `Encounter Studio`, pas un workspace séparé
   pour chaque section.
4. La section active appartient à l’état de session de l’éditeur. Un clic sur
   une table ouvre `Rencontres sauvages`; un clic sur un dresseur ouvre
   `Dresseurs`.
5. La World Map ne contient plus de formulaire complet de création ou
   modification d’une table de rencontres.
6. La World Map conserve les interactions contextuelles nécessaires pour
   affecter une table existante à une zone et peut proposer un raccourci vers le
   studio.
7. La nouvelle UI réutilise les modèles et règles existants. Aucun changement de
   schéma `ProjectManifest`, `ProjectEncounterTable` ou
   `ProjectEncounterEntry` n’est prévu.
8. Les mutations editor passent par `AuthoringMutationAdapter` et les actions
   canoniques déjà publiées :
   `campaign.encounter_table.upsert` et
   `campaign.encounter_table.delete`.
9. Une modification d’entrée réécrit atomiquement la table complète via
   `campaign.encounter_table.upsert`; aucun pseudo-support
   `encounter_entry.*` ne doit être annoncé avant son implémentation réelle.
10. Les composants visuels viennent exclusivement du design system PokeMap et
    des tokens de thème existants. Les widgets du feature ne codent aucune
    couleur produit en dur.
11. La section Dresseurs réutilise `TrainerLibraryPanel`; ses contrats métier et
    son CRUD ne sont pas réécrits dans cette roadmap.
12. La maquette est une direction de composition. Les données, contrôles et
    états visibles doivent rester compatibles avec les capacités réellement
    consommées par le moteur.

---

## 3. Audit initial consolidé

### 3.1 État produit observé

| Élément | État actuel | Conséquence |
|---|---|---|
| Modèle des tables | `ProjectManifest.encounterTables` existe | Aucun nouveau schéma nécessaire |
| Runtime wild | Les rencontres walk/surf sont déclenchées vers le battle handoff | Le redesign ne doit pas modifier le runtime |
| UI de tables | `EncounterTablesPanel` sait créer, éditer et supprimer tables et entrées | Réutiliser les règles et contrôleurs existants |
| Montage UI | Le seul montage produit est `MapInspectorPanel` | Le panneau est orphelin dans le shell actuel |
| Studio Dresseurs | Workspace central, roster, détails et équipes déjà opérationnels | L’intégrer, pas le réécrire |
| Workspace | `EditorWorkspaceMode.trainer` porte encore le Studio Dresseurs | Migrer vers une sémantique `encounter` |
| Persistance editor | Les use cases encounter écrivent encore via le repository editor | Restaurer la frontière canonique |
| API canonique | `campaign.encounter_table.upsert/delete` existent déjà | Aucun nouvel action ID nécessaire pour le périmètre |
| Catalogue prospectif | Des actions fines `encounter_table.*` et `encounter_entry.*` sont documentées comme cible | Ne pas les annoncer comme fonctionnelles |
| Parité MCP | Le dispatcher expose les actions `campaign.*`; les preuves de transport encounter restent à expliciter | Gate obligatoire avant clôture |

### 3.2 Fichiers principaux concernés

| Zone | Fichiers actuels ou proposés | Responsabilité |
|---|---|---|
| État workspace | `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart` | Mode `encounter` et section active |
| Routage | `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart` | Ouverture du studio et sélection de section |
| Shell | `packages/map_editor/lib/src/ui/editor_shell_page.dart` | Projection du workspace central |
| Navigation | `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`, `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart` | Libellé, icône et deep links |
| Nouveau shell | `packages/map_editor/lib/src/ui/panels/encounter_studio_panel.dart` | Bascule Rencontres/Dresseurs |
| Dresseurs | `packages/map_editor/lib/src/ui/panels/trainer_library_panel.dart` et ses `part` files | Expérience existante préservée |
| Rencontres | `packages/map_editor/lib/src/ui/panels/encounter_tables_panel.dart` et ses `part` files | Bibliothèque, table, roster et inspecteur |
| Ancien montage | `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart` | Suppression du formulaire encounter legacy |
| Persistance | `packages/map_editor/lib/src/application/use_cases/encounter_table_use_cases.dart` | Adaptation vers les mutations canoniques |
| Adaptateur | `packages/map_editor/lib/src/application/authoring_api/authoring_mutation_adapter.dart` | Plan/apply/révision/historique communs |
| Action canonique | `packages/map_authoring/lib/src/domains/gameplay/campaign_content_actions.dart` | Upsert/delete atomiques déjà disponibles |
| Parité | `packages/map_authoring/lib/src/parity/full_authoring_parity.dart`, `tools/pokemap_mcp/test/mutation_server.test.ts` | Preuves direct API/CLI/editor/MCP |

Les noms de nouveaux fichiers peuvent être ajustés au début d’un lot si le code
actuel révèle un meilleur emplacement. Un changement doit rester local au lot et
être motivé dans son compte rendu.

### 3.3 Tests existants à préserver

- `packages/map_editor/test/encounter_tables_panel_test.dart`
- `packages/map_editor/test/trainer_library_panel_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/editor_workspace_controller_test.dart`
- `packages/map_editor/test/top_toolbar_test.dart`
- `packages/map_editor/test/authoring_api/editor_mutation_parity_test.dart`
- `packages/map_authoring/test/domains/gameplay/campaign_content_authoring_test.dart`
- `packages/map_authoring/test/parity/full_authoring_parity_test.dart`
- `tools/pokemap_mcp/test/mutation_server.test.ts`

### 3.4 État Git initial

- Branche : `main`.
- HEAD : `49afbe464`.
- Le worktree contient déjà un chantier Smart Tiles/runtime non lié.
- Plusieurs fichiers de parité et `editor_notifier.dart` sont déjà modifiés.
- Aucun fichier ne doit être restauré, nettoyé, reformaté globalement ou ajouté à
  un commit sans autorisation explicite.

État observé avant création de cette roadmap :

```text
 M packages/map_authoring/lib/src/domains/maps/smart_tile_layer_actions.dart
 M packages/map_authoring/lib/src/parity/full_authoring_parity.dart
 M packages/map_authoring/test/domains/maps/smart_tile_layer_actions_test.dart
 M packages/map_authoring/test/domains/maps/smart_tile_layer_editing_actions_test.dart
 M packages/map_authoring/test/parity/full_authoring_parity_test.dart
 M packages/map_core/lib/src/models/map_layer.dart
 M packages/map_core/lib/src/models/map_layer.freezed.dart
 M packages/map_core/lib/src/models/map_layer.g.dart
 M packages/map_core/lib/src/models/smart_tile.dart
 M packages/map_core/lib/src/operations/smart_tile_layer_visual_resolver.dart
 M packages/map_editor/lib/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/features/smart_tiles_studio/application/smart_tile_preset_preview.dart
 M packages/map_editor/lib/src/features/smart_tiles_studio/presentation/smart_tiles_studio_panel.dart
 M packages/map_editor/test/features/editor/presentation/world_map/smart_tile_layer_preset_change_flow_test.dart
 M packages/map_editor/test/features/editor/presentation/world_map/world_map_paint_inspector_test.dart
 M packages/map_editor/test/smart_tiles_studio/smart_tiles_studio_panel_test.dart
 M packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game_support.dart
 M packages/map_runtime/lib/src/presentation/flame/smart_tile_actor_occlusion_component.dart
 M packages/map_runtime/test/smart_tile_actor_occlusion_component_test.dart
 M pokemap_authoring_api_mcp_action_catalog.md
 M tools/pokemap_mcp/test/mutation_server.test.ts
?? packages/map_core/test/smart_tiles/smart_tile_animation_activation_test.dart
?? packages/map_core/test/smart_tiles/smart_tile_layer_visual_plan_animation_time_test.dart
?? packages/map_runtime/lib/src/presentation/flame/smart_tile_animation_activation_controller.dart
?? packages/map_runtime/test/playable_map_game_smart_tile_animation_activation_test.dart
?? packages/map_runtime/test/smart_tile_animation_activation_controller_test.dart
?? packages/map_runtime/test/smart_tile_triggered_animation_render_test.dart
```

### 3.5 Risques principaux

| Risque | Gravité | Réponse de roadmap |
|---|---:|---|
| Écraser le chantier Smart Tiles concurrent | Haute | Lots séquentiels, staging explicite, diff ciblé avant et après chaque lot |
| Recréer un CRUD editor-only | Haute | Gate `AuthoringMutationAdapter` dès la Phase 0 |
| Transformer Encounter Studio en fourre-tout | Haute | Deux sections seulement ; ownership documenté |
| Casser le Studio Dresseurs | Haute | Réutilisation du widget et tests de non-régression |
| Afficher des probabilités fausses | Haute | Projection pure testée à partir des poids réels |
| Faire croire que tous les EncounterKind sont exécutables | Haute | Libellés limités aux capacités prouvées ; FG-100 à FG-107 inchangés |
| Réintroduire la création dans World Map | Moyenne | Suppression du montage legacy et test de frontière |
| Maquette trop dense sur petite fenêtre | Moyenne | Contrat responsive et tests 1280/1440/1672 px |
| Promouvoir une parité MCP non chargée | Haute | Rebuild, tests MCP et `pokemap_describe` live obligatoires |

---

## 4. Objectifs et non-objectifs

### 4.1 Objectifs

- rendre de nouveau accessibles les tables de rencontres sans les rattacher à
  la World Map ;
- fournir un Studio central cohérent avec le reste de PokeMap ;
- préserver toute la profondeur actuelle du Studio Dresseurs ;
- rendre les poids et probabilités compréhensibles sans calcul manuel ;
- guider l’auteur avec des sélecteurs d’espèces, des niveaux et des validations ;
- garantir une sauvegarde atomique, révisionnée et transportable via
  `map_authoring` ;
- certifier les comportements critiques par tests widget et parcours desktop.

### 4.2 Non-objectifs

- ajouter ou modifier les mécaniques runtime walk/surf ;
- implémenter les lots `FG-100` à `FG-107` ;
- ajouter les rencontres statiques, gifts, pêche ou headbutt ;
- modifier les modèles JSON des tables ou entrées ;
- refondre le moteur de combat ou la préparation des `BattleSetup` ;
- réécrire le CRUD Dresseurs ou ses règles métier ;
- refaire la navigation globale de Narrative Studio, Smart Tiles Studio ou
  Environment Studio ;
- publier comme fonctionnelles les actions prospectives
  `encounter_table.*`/`encounter_entry.*` absentes du dispatcher ;
- modifier les Smart Tiles en cours autrement que par un point d’intégration
  explicitement isolé dans `ENS-030`.

---

## 5. Architecture cible

### 5.1 Ownership produit

```text
Encounter Studio
├── Rencontres sauvages
│   ├── Bibliothèque de tables
│   ├── Configuration de table
│   ├── Roster et probabilités
│   ├── Inspecteur contextuel d’entrée
│   └── Validation globale
└── Dresseurs
    └── TrainerLibraryPanel existant

World Map
├── dessine ou sélectionne une zone
├── affecte une table existante
└── ouvre la table dans Encounter Studio
```

### 5.2 Flux de mutation

```text
Intent UI
→ encounter_table_use_cases
→ AuthoringMutationAdapter.plan
→ campaign.encounter_table.upsert/delete
→ AuthoringMutationAdapter.apply
→ snapshot canonique rechargé
→ EditorState adopté
→ UI reconstruite
```

Les ajouts, modifications, réordonnancements et suppressions d’entrées produisent
un nouveau `ProjectEncounterTable` complet puis utilisent l’upsert canonique.
Cette stratégie reste atomique et ne prétend pas fournir une action fine que le
dispatcher ne possède pas.

### 5.3 Projection de probabilité

Pour une table possédant des poids strictement positifs :

```text
partDeLEntree = poidsEntree / sommeDesPoids
probabiliteResolueParPas = chancePerStep * partDeLEntree
```

L’UI affiche séparément la part relative dans la table et la probabilité résolue
par pas. Une somme de poids égale à zéro est un état invalide, jamais affiché
comme `100 %`.

### 5.4 Contrat responsive desktop

| Largeur utile | Composition attendue |
|---:|---|
| `>= 1480 px` | Bibliothèque + éditeur + inspecteur contextuel |
| `1280–1479 px` | Bibliothèque compacte + éditeur + inspecteur réduit |
| `< 1280 px` | Bibliothèque et inspecteur deviennent des panneaux alternés ; aucun overflow |

Le produit reste desktop-first. Aucun layout mobile n’est introduit.

---

## 6. Catalogue des lots

Tous les lots commencent par un test qui échoue pour la raison attendue, puis
suivent le cycle red/green/refactor. Aucune opération Git d’écriture n’appartient
implicitement à un lot.

### ENS-001 — Encounter Studio Characterization & Safety Net

**But :** verrouiller les comportements existants avant déplacement ou refonte.

**Dépendances :** aucune.

**Portée :** tests uniquement, hors corrections minimales nécessaires aux
fixtures de test.

**Preuves attendues :**

- le panneau actuel crée une table et une entrée valide ;
- les niveaux invalides, poids invalides et espèces inconnues restent refusés ;
- le Studio Dresseurs conserve son roster, sa sélection et ses formulaires ;
- l’ancien `MapInspectorPanel` est identifié comme unique montage du panneau
  encounter ;
- les fichiers déjà modifiés par le chantier Smart Tiles restent inchangés par
  le lot.

**Tests ciblés :**

```bash
cd packages/map_editor
flutter test test/encounter_tables_panel_test.dart \
  test/trainer_library_panel_test.dart \
  test/editor_shell_page_smoke_test.dart
```

**DoD :** tests de caractérisation verts, état Git comparé, aucune mutation
produit.

### ENS-002 — Canonical Encounter Table Persistence

**But :** remplacer le write path repository-only par le contrat canonique déjà
disponible.

**Dépendances :** `ENS-001`.

**Portée :** `encounter_table_use_cases.dart`, providers associés et tests de
parité editor.

**Contrat :**

- create/update/add-entry/update-entry/delete-entry utilisent
  `campaign.encounter_table.upsert` ;
- delete-table utilise `campaign.encounter_table.delete` et suit la confirmation
  canonique requise par son niveau de risque ;
- les conflits de révision sont traduits en erreur editor lisible ;
- l’état adopté vient du snapshot relu après apply ;
- aucun fichier projet n’est écrit directement par le feature.

**Tests ciblés :**

```bash
cd packages/map_authoring
dart test test/domains/gameplay/campaign_content_authoring_test.dart

cd ../map_editor
flutter test test/authoring_api/editor_mutation_parity_test.dart \
  test/encounter_tables_panel_test.dart
```

**DoD :** le CRUD existant produit les mêmes documents via le chemin canonique,
et un test négatif prouve qu’une révision périmée n’écrase pas le projet.

### ENS-010 — Encounter Workspace Routing

**But :** remplacer la sémantique workspace `trainer` par `encounter` et porter
la section active dans l’état de session.

**Dépendances :** `ENS-001`.

**Portée :** enum de workspace, controller, notifier de navigation, toolbar,
shell, explorateur et tests associés.

**Comportements :**

- la toolbar affiche `Encounter Studio` ;
- son action ouvre la dernière section active ou `Rencontres sauvages` par
  défaut ;
- un clic sur un dresseur ouvre `Dresseurs` ;
- un clic sur une table ouvre `Rencontres sauvages` ;
- aucun alias `Trainer Studio` ne reste visible dans le shell de production.

**Tests ciblés :**

```bash
cd packages/map_editor
flutter test test/editor_workspace_controller_test.dart \
  test/top_toolbar_test.dart \
  test/editor_shell_page_smoke_test.dart
```

**DoD :** routage bidirectionnel prouvé, exhaustive switches compilés, aucun
changement métier dresseur ou encounter.

### ENS-011 — Encounter Studio Shell & Trainer Integration

**But :** créer le shell central à deux sections et intégrer le Studio Dresseurs
sans duplication.

**Dépendances :** `ENS-010`.

**Portée :** nouveau `encounter_studio_panel.dart`, projection shell et adaptation
minimale de `TrainerLibraryPanel`.

**Comportements :**

- switcher visible `Rencontres sauvages` / `Dresseurs` ;
- sélection clavier et souris ;
- section active restaurée pendant la session ;
- `TrainerLibraryPanel` reste la source de vérité des dresseurs ;
- état vide projet absent et chargement asynchrone cohérents avec les autres
  Studios.

**Tests ciblés :**

```bash
cd packages/map_editor
flutter test test/encounter_studio_panel_test.dart \
  test/trainer_library_panel_test.dart \
  test/editor_shell_page_smoke_test.dart
```

**DoD :** les deux sections sont accessibles et le parcours Dresseurs historique
reste vert sans second controller métier.

### ENS-020 — Wild Encounter Library & Table Configuration

**But :** construire la colonne bibliothèque et l’en-tête de configuration de
table de la maquette approuvée.

**Dépendances :** `ENS-002`, `ENS-011`.

**Portée :** composition de `EncounterTablesPanel`, recherche, sélection,
création, duplication si le contrat actuel le permet, type, taux, tags et
conditions déjà supportées.

**Comportements :**

- recherche insensible à la casse ;
- regroupement stable des tables sans inventer de lien map absent du modèle ;
- création guidée sans saisie manuelle d’ID ;
- édition du type et du taux avec validation inline ;
- les types runtime non certifiés sont indiqués comme indisponibles ou partiels,
  jamais présentés comme jouables ;
- état vide avec action primaire unique.

**Tests ciblés :**

```bash
cd packages/map_editor
flutter test test/encounter_tables_panel_test.dart \
  test/encounter_studio_panel_test.dart
```

**DoD :** bibliothèque et configuration utilisent uniquement le design system,
fonctionnent à 1280 px et persistent par `ENS-002`.

### ENS-021 — Visual Roster & Probability Projection

**But :** rendre les entrées et leur rareté compréhensibles en un regard.

**Dépendances :** `ENS-020`.

**Portée :** lignes Pokémon, sprites déjà disponibles, types, niveaux, poids,
barres relatives et projection de probabilité pure.

**Comportements :**

- ordre des entrées identique au modèle ;
- somme des poids et part relative calculées sans mutation ;
- probabilité résolue distincte de la part relative ;
- poids nul, négatif ou somme nulle signalés comme invalides ;
- absence de sprite dégrade vers un fallback design-system sans bloquer le CRUD ;
- aucun sprite n’est inventé ou extrait d’une spritesheet à la volée.

**Tests ciblés :**

```bash
cd packages/map_editor
flutter test test/encounter_probability_projection_test.dart \
  test/encounter_tables_panel_test.dart
```

**DoD :** projection pure couverte par cas normal et cas limites, roster fidèle à
la table et aucun pourcentage mensonger.

### ENS-022 — Contextual Entry Inspector & Global Validation

**But :** éditer une entrée sans perdre le contexte de la table et exposer les
erreurs réellement bloquantes.

**Dépendances :** `ENS-021`.

**Portée :** sélection de ligne, inspecteur droit, add/update/delete, validation
globale et états de succès/erreur.

**Comportements :**

- sans entrée sélectionnée, l’inspecteur affiche le résumé global ;
- avec une entrée sélectionnée, il édite espèce, niveaux et poids ;
- suppression demande une confirmation locale claire ;
- sélection d’espèce guidée par le Pokédex du projet ;
- validation couvre au minimum espèce, niveaux, poids, doublons et somme ;
- une erreur de persistance conserve le draft et affiche une action de reprise ;
- la validation existante de `FG-108` est consommée quand disponible, sans
  déclarer `FG-108 DONE` sur la seule foi de l’UI.

**Tests ciblés :**

```bash
cd packages/map_editor
flutter test test/encounter_tables_panel_test.dart \
  test/encounter_studio_panel_test.dart \
  test/authoring_api/editor_mutation_parity_test.dart
```

**DoD :** parcours create/edit/delete prouvé, cas négatifs visibles, données
persistées puis relues via le snapshot canonique.

### ENS-030 — World Map Boundary & Deep Link

**But :** retirer la création legacy de la World Map et conserver uniquement
l’affectation contextuelle d’une table existante.

**Dépendances :** `ENS-011`, `ENS-022`, intégration préalable du chantier Smart
Tiles actuellement présent dans le worktree.

**Portée :** `MapInspectorPanel`, points d’affectation de gameplay zone et
raccourci `Ouvrir dans Encounter Studio`.

**Comportements :**

- aucun `EncounterTablesPanel` complet dans la World Map ;
- picker de table existante avec libellé humain ;
- table supprimée signalée comme référence invalide ;
- deep link ouvre la bonne table dans `Rencontres sauvages` ;
- aucun changement de peinture ou de génération Smart Tiles hors du branchement
  strictement nécessaire.

**Tests ciblés :**

```bash
cd packages/map_editor
flutter test test/features/editor/presentation/world_map/world_map_paint_inspector_test.dart \
  test/encounter_studio_panel_test.dart
```

**DoD :** frontière product claire, affectation fonctionnelle et absence de
régression World Map.

### ENS-031 — Responsive, Accessibility & Visual Certification

**But :** rapprocher l’écran Flutter réel de la direction hybride validée et
garantir son utilisabilité desktop.

**Dépendances :** `ENS-020`, `ENS-021`, `ENS-022`.

**Portée :** layout responsive, focus clavier, tooltips, contrastes issus des
tokens, captures et golden ciblé stable.

**Preuves attendues :**

- aucune overflow à 1280, 1440 et 1672 px ;
- tab order cohérent ;
- contrôles icon-only accompagnés d’un tooltip ;
- états hover/focus/selected distincts ;
- comparaison même viewport/même état avec la maquette approuvée ;
- correction des écarts bloquants de hiérarchie, densité et lisibilité.

**Tests ciblés :**

```bash
cd packages/map_editor
flutter test test/encounter_studio_responsive_test.dart \
  test/encounter_studio_golden_test.dart
```

**DoD :** tests responsive verts et preuve desktop réelle inspectée ; le golden
ne remplace pas le parcours interactif.

### ENS-040 — Authoring Transport & Runtime End-to-End Certification

**But :** prouver que l’UI utilise les mêmes contrats que l’API, la CLI et le
MCP, puis qu’une table affectée déclenche encore une rencontre runtime.

**Dépendances :** `ENS-002`, `ENS-022`, `ENS-030`.

**Parcours certifié :**

1. créer une table avec deux entrées ;
2. la modifier depuis l’éditeur ;
3. relire le document via l’API canonique ;
4. reproduire une mutation via JSONL/CLI ;
5. vérifier l’exposition live via MCP ;
6. affecter la table à une zone walk ;
7. déclencher une rencontre dans le runtime smoke ;
8. fermer proprement le workspace MCP.

**Commandes minimales :**

```bash
cd packages/map_authoring
dart run tool/pmcp085_conformance.dart
dart test test/domains/gameplay/campaign_content_authoring_test.dart
dart test test/parity/full_authoring_parity_test.dart

cd ../../tools/pokemap_mcp
npm run check
npm test

cd ../../packages/map_editor
flutter test test/authoring_api/editor_mutation_parity_test.dart \
  test/encounter_studio_panel_test.dart

cd ../map_runtime
flutter test test/wild_battle_end_to_end_flow_test.dart
```

**DoD :** quatre transports prouvés, catalogue live inspecté, runtime smoke vert,
chaque N/A justifié explicitement.

### ENS-041 — Package Gates & Closure Evidence

**But :** exécuter les gates complètes, produire l’état final et proposer les
statuts sans les maquiller.

**Dépendances :** tous les lots précédents.

**Commandes minimales :**

```bash
cd packages/map_authoring
dart test
dart analyze

cd ../map_editor
flutter test
flutter analyze
flutter build macos

cd ../../tools/pokemap_mcp
npm run check
npm test

cd ../..
bash tools/scripts/check_markdown_hygiene.sh
git status --short --untracked-files=all
```

**DoD :** résultats exacts consignés, échecs globaux séparés des régressions du
lot, diff revu fichier par fichier, état Git final publié et aucune opération
Git d’écriture exécutée sans autorisation.

---

## 7. Regroupement des lots en phases

| Phase | Lots | Objectif | Dépendance | Critère de sortie | Statut |
|---|---|---|---|---|---|
| Phase 0 — Contrats sûrs | `ENS-001`, `ENS-002` | Verrouiller les régressions et restaurer le write path canonique | Aucun | CRUD encounter canonique et caractérisé | `⬜ TODO` |
| Phase 1 — Nouveau Studio | `ENS-010`, `ENS-011` | Installer le workspace Encounter et préserver Dresseurs | Phase 0 pour la fermeture ; `ENS-010` peut démarrer après `ENS-001` | Deux sections routables, Dresseurs non régressé | `⬜ TODO` |
| Phase 2 — Rencontres sauvages | `ENS-020`, `ENS-021`, `ENS-022` | Implémenter la maquette hybride et ses validations | Phases 0 et 1 | CRUD complet, probabilités honnêtes, inspecteur contextuel | `⬜ TODO` |
| Phase 3 — Frontière et qualité | `ENS-030`, `ENS-031` | Nettoyer la World Map et certifier l’UI desktop | Phase 2 ; chantier Smart Tiles intégré pour `ENS-030` | Affectation-only dans World Map, UI sans overflow et visuellement certifiée | `⬜ TODO` |
| Phase 4 — Certification | `ENS-040`, `ENS-041` | Prouver transports, runtime, packages et fermeture | Toutes les phases précédentes | Toutes gates exécutées et statut proposé avec preuves | `⬜ TODO` |

### 7.1 Chemin critique

```text
ENS-001
→ ENS-002
→ ENS-010
→ ENS-011
→ ENS-020
→ ENS-021
→ ENS-022
→ ENS-030
→ ENS-040
→ ENS-041
```

`ENS-031` peut avancer après `ENS-022`, en parallèle logique de `ENS-030`, mais
les deux lots ne doivent pas modifier simultanément les mêmes fichiers dans un
worktree partagé.

### 7.2 Gates de phase

Une phase ne passe à `DONE` que si :

1. chaque lot possède un test positif, un test négatif et une non-régression ;
2. les tests ciblés ont été exécutés après les derniers changements ;
3. les fichiers modifiés sont limités à la portée annoncée ;
4. les changements préexistants sont toujours présents et distincts ;
5. les limites et échecs connus sont consignés ;
6. la phase suivante peut partir d’un état compréhensible sans dépendre d’un
   comportement manuel non documenté.

---

## 8. Matrice de validation

| Capacité | Test positif | Test négatif | Non-régression |
|---|---|---|---|
| Routage studio | Toolbar ouvre Encounter Studio | Projet absent désactive l’action | Autres workspaces inchangés |
| Sections | Switch Rencontres/Dresseurs | Section inconnue impossible | Trainer CRUD conservé |
| Tables | Create/update/delete persistés | Nom/taux invalide refusé | Round-trip JSON inchangé |
| Entrées | Add/edit/delete/reorder | Espèce/niveaux/poids invalides | Ordre existant conservé |
| Probabilités | Somme et parts exactes | Somme nulle signalée | `chancePerStep` non confondu avec poids |
| Canonical API | Plan/apply écrit le snapshot | Révision périmée refusée | History/undo restent disponibles |
| World Map | Picker affecte une table | Référence supprimée signalée | Peinture Smart Tiles inchangée |
| MCP | Action visible et mutation relue | Paramètre inconnu rejeté | Catalogues voisins inchangés |
| Responsive | 1280/1440/1672 sans overflow | Largeur sous budget reflow | Studio Dresseurs reste utilisable |
| Runtime | Zone walk déclenche une table authorée | Table invalide bloque la certification | Battle handoff historique vert |

---

## 9. Relation avec la roadmap mécanique

Cette roadmap est une roadmap d’éditeur et de parité, pas la Phase 6 entière des
encounters élargis.

| Lot mécanique | Relation | Effet possible après preuves |
|---|---|---|
| `FG-100` | Audit des kinds runtime | Aucun changement de statut |
| `FG-101` | Conditions encounter | Consommation UI partielle seulement ; pas de fermeture automatique |
| `FG-102` à `FG-107` | Statics, gifts, fishing, headbutt, surf hardening, consumed write-back | Hors périmètre |
| `FG-108` | Validation d’authoring | Peut être proposé `PARTIAL` ou `DONE` uniquement si chaque DoD est prouvé dans `ENS-022`/`ENS-040` |

La fermeture de `FG-108` exige toujours : espèce existante, niveaux valides,
poids valides, références zone→table valides et diagnostic des flags/variables
quand le modèle permet de les vérifier.

---

## 10. Stratégie d’exécution dans le worktree actuel

1. Obtenir l’autorisation explicite de travailler sur `main` ou de créer un
   worktree dédié avant le premier changement de code.
2. Relever `HEAD` et `git status` au début de chaque lot.
3. Ne jamais restaurer ou reformater les fichiers Smart Tiles/runtime déjà
   modifiés.
4. Éviter `editor_notifier.dart` quand un use case ou controller dédié suffit.
5. Si un fichier déjà sale doit être touché, comparer son diff avant et après le
   lot et documenter les lignes ajoutées par Encounter Studio.
6. Ne pas mélanger deux lots dans un même diff de validation.
7. Ne lancer aucune opération `git add`, commit, push, rebase, stash ou worktree
   sans instruction explicite.

---

## 11. Passes de revue exigées

Les règles du repo demandent des verdicts séparés. Le mode multi-agent n’est pas
présumé autorisé par cette roadmap ; à défaut d’autorisation explicite, ces
revues sont menées comme cinq passes indépendantes.

| Passe | Verdict de cette roadmap | Point de contrôle à l’exécution |
|---|---|---|
| Audit / Architecture | `GO CONDITIONNEL` | Le chemin canonique existe ; interdire tout nouveau write path editor-only |
| Implémentation | `GO PAR LOT` | Les onze lots sont bornés ; `ENS-030` attend l’intégration Smart Tiles |
| Tests | `GO` | La matrice couvre positif, négatif et non-régression pour chaque capacité |
| Build / Validation | `GO CONDITIONNEL` | Aucun build n’est pertinent pour la seule roadmap ; build macOS obligatoire dans `ENS-041` |
| Critique finale | `GO AVEC RISQUES EXPLICITES` | Ne pas sur-promettre les encounter kinds, la parité fine ou la fermeture FG-108 |

---

## 12. Auto-critique et risques résiduels

1. Le regroupement des tables par map visible dans la maquette n’est pas garanti
   par le modèle actuel. `ENS-020` doit employer un regroupement réellement
   dérivable ou rester plat ; il ne doit pas inventer une relation persistée.
2. Les sprites Pokémon peuvent dépendre des catalogues/assets du projet. Le
   fallback sans sprite doit rester digne et ne pas bloquer l’authoring.
3. L’upsert de table complète est canonique mais moins fin qu’un futur
   `encounter_entry.update`. Il est acceptable pour ce périmètre seulement si
   les révisions et l’atomicité sont prouvées.
4. La suppression canonique peut demander confirmation parce que l’action est à
   risque élevé. L’UI doit refléter ce contrat au lieu de contourner la gate.
5. Le deep link World Map touche une zone où un chantier Smart Tiles est déjà en
   cours. `ENS-030` doit attendre une base intégrée ou être exécuté dans un
   worktree explicitement autorisé.
6. La certification visuelle ne doit pas pousser à reproduire des éléments de
   maquette que le moteur ne sait pas fournir, notamment un statut actif/inactif
   ou un regroupement absent du modèle.

---

## 13. Conditions de clôture globale

La roadmap peut être proposée `DONE` uniquement lorsque :

- les onze lots sont fermés avec preuves fraîches ;
- `Encounter Studio` remplace visiblement `Trainer Studio` dans le shell ;
- les deux sections restent fonctionnelles après restart de l’éditeur ;
- aucune création complète de table ne subsiste dans la World Map ;
- toutes les mutations encounter de l’éditeur passent par le contrat canonique ;
- direct API, JSONL/CLI, éditeur et MCP sont prouvés ou chaque N/A est justifié ;
- un projet réel peut créer une table, l’affecter et déclencher une rencontre ;
- tests ciblés, suites packages, analyses, build macOS et hygiène Markdown ont
  leurs résultats exacts consignés ;
- le diff final ne mélange ni ne détruit le chantier Smart Tiles préexistant ;
- le statut de `FG-108` est seulement proposé à partir de son DoD réel.
