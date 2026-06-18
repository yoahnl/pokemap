# Event Builder V1 Drag/Drop Detailed Lot Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` or `superpowers:executing-plans` to implement this plan task-by-task. Each lot below is intentionally bounded and must produce testable software on its own.

**Goal:** construire une V1 de l’Event Builder proche de l’image cible Yoahn, avec liste + bibliothèque + builder central + inspecteur + drag/drop contrôlé, sans transformer l’outil en graph libre ni en moteur runtime.

**Architecture:** la trajectoire part de l’Event Builder actuel livré par NS-EVENT-16, stabilise d’abord le layout et l’ajout par clic, puis ajoute le drag/drop comme couche d’interaction au-dessus des opérations existantes. Les nouvelles capacités métier restent séparées en lots dédiés avant d’être exposées dans la bibliothèque ou rendues droppables.

**Tech Stack:** Flutter desktop dans `packages/map_editor`, modèles et opérations pures dans `packages/map_core` uniquement quand un contrat authoring doit devenir source de vérité, tests widget Flutter pour l’UI, tests Dart core pour les opérations pures, Visual Gates dans `reports/narrativeStudio/events/screenshots`.

---

## 1. Résumé exécutif

### Verdict produit

Oui, l’option **V1 avec drag/drop** est faisable, mais elle ne doit pas démarrer par le drag/drop. L’écran actuel sait déjà éditer des morceaux importants de l’event, mais il n’a pas encore la structure cible stable :

```text
liste événements
→ bibliothèque d’éléments
→ builder central en blocs
→ inspecteur droit
→ validation / aperçu
```

Le drag/drop doit arriver après :

1. compactage de la création ;
2. builder central en blocs ;
3. inspecteur séparé ;
4. bibliothèque read-only ;
5. ajout par clic ;
6. modèle de slots compatibles.

Sinon, on obtiendra un drag/drop fragile posé sur une UI encore en mutation.

### Nombre de lots

| Périmètre | Nombre de lots | Verdict |
|---|---:|---|
| V1 drag/drop minimal sur capacités existantes | 14 lots | Suffisant pour drag depuis bibliothèque vers Déclencheur/Conditions/Action/Comportement, avec refus no-code. |
| V1 proche image cible avec Résultats/Réactions/Monde partiels | 22 lots | Recommandé si l’objectif est vraiment de se rapprocher de l’image fournie. |
| V1 robuste avec accessibilité, reorder, Visual Gates et closure | 26 lots | Recommandé pour éviter une dette UI/test immédiatement après livraison. |

### Recommandation

Je recommande de planifier **26 lots** :

```text
NS-EVENT-18 à NS-EVENT-43
```

Ce découpage est volontairement plus long qu’une estimation optimiste. Il protège :

- les tests existants ;
- les opérations authoring déjà livrées ;
- la frontière Event / Scene / Runtime ;
- l’accessibilité clavier ;
- les refus de drop incompatibles ;
- la lisibilité no-code.

## 2. État de départ vérifié

### Worktree initial

Commande :

```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 12
```

Sortie utile :

```text
/Users/karim/Project/pokemonProject
main
?? reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md
54c59fba ns_event_16: Consolidation de la disposition des blocs et disponibilité de la création d'activation de carte
8b3866a8 ns_event_15: Ajout de l'auteur des types de déclencheurs pour les événements
8a5996be ns_event_14: Ajout des conditions de consommation d'événements
7f490b9e ns_event_13: Ajout de l'auteur des conditions de fait pour les événements
26bec474 ns_event_12: Ajout de l'auteur des comportements pour les événements
00698aea ns_event_11: Ajout de l'auteur des actions de scène pour les événements
fc0e0be0 ns_event_10: Ajout de la saisie du titre pour les brouillons d'événements
cdedbe6e ns_event_09: Fermeture du flux de création de brouillon
d3f1866f ns_event_08: Ajout du sélecteur de position explicite sur la carte pour la création de brouillon
30ae9429 ns_event_07: Ajout de l'entrée UI explicite pour la création de brouillon avec position
3bd06d2b ns_event_06: Ajout des opérations de création de brouillon pour l'éditeur d'événements
6fe430d9 ns_event_05: Polissage des détails en lecture seule et diagnostics
```

`git diff --stat` et `git diff --name-only` étaient vides. Le fichier NS-EVENT-17 non suivi est préexistant dans ce tour et n’est pas un changement produit.

### Rapports et preuves lus

- `reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md`
- `reports/narrativeStudio/events/ns_event_builder_mvp_v1_lot_plan.md`
- `reports/narrativeStudio/events/ns_event_16_block_layout_consolidation_v0.md`
- `reports/narrativeStudio/events/ns_event_16_map_activation_creation_availability_v0.md`
- `reports/narrativeStudio/events/ns_event_15_trigger_type_authoring_v0.md`
- `reports/narrativeStudio/events/ns_event_14_event_consumed_conditions_authoring_v0.md`
- `reports/narrativeStudio/events/ns_event_13_fact_conditions_authoring_v0.md`

### Fichiers code audités

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

### Constat technique important

Le fichier `event_builder_workspace.dart` contient déjà :

```text
EventBuilderWorkspace
_EventCreationColumn
_DraftPositionPickerPanel
_EventListPanel
_EventDetailsPanel
_buildTriggerBlock
_buildConditionsBlock
_buildSceneActionBlock
_buildBehaviorBlock
```

Le test NS-EVENT-16 vérifie explicitement :

```text
expect(find.text('Drag/drop'), findsNothing);
```

Donc le drag/drop n’existe pas aujourd’hui et a été volontairement gardé hors scope.

## 3. Principes de conception V1 drag/drop

### Principe 1 — Drag/drop comme couche d’interaction, pas comme moteur métier

Un drop ne doit jamais inventer une mutation. Il doit appeler une opération déjà testée :

- ajouter condition Fact ;
- ajouter condition Event consumed ;
- choisir action Scene ;
- changer type de déclencheur ;
- changer comportement ;
- plus tard : ajouter outcome / réaction / world change.

### Principe 2 — Clic d’abord, drag/drop ensuite

Chaque élément droppable doit avoir une alternative par clic ou clavier. Si un bloc n’est utilisable qu’en drag/drop, l’UX devient moins accessible et plus difficile à tester.

### Principe 3 — Slots compatibles explicites

La V1 ne doit pas accepter “drop n’importe quoi n’importe où”. Chaque slot déclare :

```text
slotId
section
acceptedItemKinds
state: enabled / disabled / locked
human refusal message
```

### Principe 4 — Pas de graph libre

L’image cible montre un flow vertical guidé. La V1 doit rester :

```text
Déclencheur
→ Conditions
→ Actions
→ Résultats
→ Réactions
→ Monde
→ Fin
```

Pas de canvas infini, pas de nodes libres, pas d’arêtes arbitraires.

### Principe 5 — Reorder seulement quand le modèle le justifie

Le reorder des conditions peut être visuel mais sémantiquement neutre si tout compile en `allOf`. Les actions/réactions deviennent sensibles à l’ordre seulement quand le modèle supporte plusieurs entrées ordonnées.

## 4. Architecture cible

### Découpage de fichiers recommandé

Le fichier `event_builder_workspace.dart` est déjà dense. La V1 drag/drop doit éviter de l’alourdir davantage.

| Fichier | Créer / Modifier / Supprimer | Responsabilité |
|---|---|---|
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart` | Modifier puis réduire progressivement | Composition de haut niveau et wiring callbacks. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart` | Créer | Création compacte, accordéon, position picker V0. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_event_list_panel.dart` | Créer | Liste événements, groupement, recherche plus tard. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart` | Créer | Builder central vertical en blocs. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart` | Créer | Inspecteur droit, détails techniques, édition fine. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart` | Créer | Bibliothèque d’éléments, groupes, disponibilité. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_drag_models.dart` | Créer | Types UI-only : item draggable, slot, drop intent, compatibility. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_drag_controller.dart` | Créer | Traduction drop intent → callback existant. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_drop_zone.dart` | Créer | Widget DragTarget / états hover / refus. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_draggable_tile.dart` | Créer | Widget source draggable de bibliothèque. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart` | Créer | Blocs Déclencheur, Conditions, Actions, Monde, Fin. |
| `packages/map_editor/lib/src/ui/canvas/events/event_builder_outcome_blocks.dart` | Créer plus tard | Blocs Résultats/Réactions. |
| `packages/map_editor/test/event_builder_workspace_test.dart` | Modifier | Tests widget existants et régressions. |
| `packages/map_editor/test/event_builder_drag_drop_test.dart` | Créer | Tests dédiés drag/drop, slots, refus, accessibilité. |
| `packages/map_editor/test/event_builder_visual_gate_test.dart` | Optionnel créer | Captures ciblées si le fichier actuel devient trop lourd. |

### Suppressions prévues

Il ne faut pas supprimer brutalement du code. Les suppressions doivent être des extractions progressives :

| Élément à supprimer de `event_builder_workspace.dart` | Moment | Remplacement |
|---|---|---|
| `_EventCreationColumn` inline | NS-EVENT-18 | `event_builder_creation_panel.dart` |
| `_EventListPanel` inline | NS-EVENT-19 ou 20 | `event_builder_event_list_panel.dart` |
| `_EventDetailsPanel` monolithique | NS-EVENT-19 à 20 | `event_builder_central_flow.dart` + `event_builder_inspector_panel.dart` |
| Logique locale de compatibilité add/drop | NS-EVENT-25 | `event_builder_drag_models.dart` |
| Widgets source/drop inline | NS-EVENT-26 à 27 | `event_builder_draggable_tile.dart` + `event_builder_drop_zone.dart` |

## 5. Plan lot par lot

## Phase A — Stabiliser la scène avant le drag/drop

### NS-EVENT-18 — Creation Panel Compact / Collapsible V0

**Type :** UI layout.

**Objectif :** rendre la création et la grille de position secondaires.

**Pourquoi ce lot existe :** la grille V0 est utile mais trop visible. Elle doit devenir un outil d’entrée, pas la pièce centrale.

**Créer :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_creation_panel.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

**Supprimer :**

- déplacer progressivement `_EventCreationColumn` et `_DraftPositionPickerPanel` hors de `event_builder_workspace.dart`.

**Tests attendus :**

- `NS-EVENT-18 creation panel is collapsed when an event is selected`
- `NS-EVENT-18 creation panel expands from New event action`
- `NS-EVENT-18 explicit position picker still creates a draft`
- `NS-EVENT-18 map activation still hides position picker when no map is active`

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png`

**Critères d’acceptation :**

- la grille n’est pas visible par défaut quand un event est sélectionné ;
- le flux NS-EVENT-09 reste intact ;
- aucune capacité métier nouvelle.

### NS-EVENT-19 — Event Builder Central Blocks Layout V0

**Type :** UI layout.

**Objectif :** installer le builder central vertical.

**Créer :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

**Supprimer :**

- extraire les sections centrales de `_EventDetailsPanel`.

**Tests attendus :**

- `NS-EVENT-19 shows central flow blocks in canonical order`
- `NS-EVENT-19 keeps trigger authoring working from the block`
- `NS-EVENT-19 keeps condition authoring working from the block`
- `NS-EVENT-19 keeps scene action authoring working from the block`
- `NS-EVENT-19 still hides results and reactions authoring`

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_19_event_builder_central_blocks_layout_v0.png`

**Critères d’acceptation :**

- ordre visible : Déclencheur, Conditions, Action principale, Comportement, Changements du monde, Diagnostics ;
- pas de bibliothèque ;
- pas de drag/drop.

### NS-EVENT-20 — Event Inspector Split V0

**Type :** UI layout / split responsibilities.

**Objectif :** séparer builder central et inspecteur droit.

**Créer :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

**Supprimer :**

- retirer du builder central les informations techniques lourdes.

**Tests attendus :**

- `NS-EVENT-20 shows event inspector on the right`
- `NS-EVENT-20 keeps technical id secondary in inspector`
- `NS-EVENT-20 central flow does not duplicate technical details`
- `NS-EVENT-20 title trigger scene behavior still update selected event`

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_20_event_inspector_split_v0.png`

**Critères d’acceptation :**

- trois zones lisibles : liste, builder, inspecteur ;
- les tests NS-EVENT-10 à NS-EVENT-16 restent verts.

### NS-EVENT-21 — Element Library Read-only V0

**Type :** UI read-only.

**Objectif :** afficher la bibliothèque d’éléments sans mutation.

**Créer :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

**Supprimer :**

- rien.

**Groupes :**

- Déclencheurs ;
- Conditions ;
- Actions ;
- Résultats ;
- Réactions ;
- Monde.

**Tests attendus :**

- `NS-EVENT-21 shows read-only element library groups`
- `NS-EVENT-21 marks unsupported elements as coming later`
- `NS-EVENT-21 clicking read-only library item does not mutate event`
- `NS-EVENT-21 does not expose raw metadata keys`

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_21_element_library_readonly_v0.png`

**Critères d’acceptation :**

- la bibliothèque prépare l’UI cible ;
- aucune mutation ;
- aucun drag/drop.

### NS-EVENT-22 — Add-by-click From Library V0

**Type :** UI authoring.

**Objectif :** rendre la bibliothèque utile par clic avant le drag/drop.

**Créer :**

- éventuellement `packages/map_editor/lib/src/ui/canvas/events/event_builder_library_actions.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

**Supprimer :**

- rien.

**Comportements :**

- clic Condition Fact ouvre le picker Fact ;
- clic Condition Event ouvre le picker Event ;
- clic Action Scene focalise l’action principale ;
- clic Déclencheur focalise le bloc déclencheur ;
- clic Comportement focalise le bloc comportement ;
- clic unsupported affiche message no-code.

**Tests attendus :**

- `NS-EVENT-22 clicking Fact condition library item opens fact choice`
- `NS-EVENT-22 clicking Event condition library item opens event choice`
- `NS-EVENT-22 clicking Scene action library item focuses scene action`
- `NS-EVENT-22 unsupported library item shows not available message`

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_22_add_by_click_from_library_v0.png`

**Critères d’acceptation :**

- tout élément droppable futur a déjà une alternative clic.

### NS-EVENT-23 — Actions / Conditions Block Polish V0

**Type :** UI polish.

**Objectif :** rendre les blocs existants visuellement prêts pour les slots.

**Créer :**

- éventuellement `packages/map_editor/lib/src/ui/canvas/events/event_builder_condition_rows.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

**Supprimer :**

- duplication de rows conditions dans l’ancien fichier si extraite.

**Tests attendus :**

- `NS-EVENT-23 condition rows remain removable`
- `NS-EVENT-23 empty condition slot is visible without promising drag/drop`
- `NS-EVENT-23 scene action block remains no-code`

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_23_actions_conditions_block_polish_v0.png`

**Critères d’acceptation :**

- les blocs ont une structure qui pourra accueillir les drop zones.

### NS-EVENT-24 — MVP UX Closure Visual Gate

**Type :** audit / Visual Gate.

**Objectif :** fermer le layout pré-drag/drop.

**Créer :**

- `reports/narrativeStudio/events/ns_event_24_mvp_ux_closure_visual_gate.md`
- `reports/narrativeStudio/events/screenshots/ns_event_24_mvp_ux_closure_visual_gate.png`

**Modifier :**

- seulement tests/docs si l’audit trouve un petit écart.

**Supprimer :**

- rien.

**Tests attendus :**

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart --name "NS-EVENT-18|NS-EVENT-19|NS-EVENT-20|NS-EVENT-21|NS-EVENT-22|NS-EVENT-23|NS-EVENT-24"
flutter analyze --no-fatal-infos lib/src/ui/canvas/events test/event_builder_workspace_test.dart
```

**Critères d’acceptation :**

- layout stable ;
- bibliothèque par clic disponible ;
- aucun drag/drop commencé.

## Phase B — Contrat d’interaction drag/drop

### NS-EVENT-25 — Drag/Drop Slot Registry Contract V0

**Type :** UI contract / tests purs map_editor.

**Objectif :** définir les items de bibliothèque, les slots et la compatibilité sans widget drag.

**Créer :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_drag_models.dart`
- `packages/map_editor/test/event_builder_drag_models_test.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart`

**Supprimer :**

- aucune logique compatible/incompatible codée en dur dans les widgets.

**Types attendus :**

```dart
enum EventBuilderLibraryItemKind {
  triggerActor,
  triggerObject,
  triggerZone,
  conditionFact,
  conditionEventConsumed,
  actionScene,
  behaviorReuse,
  resultVictory,
  resultDefeat,
  reactionSetFact,
  worldChange,
}

enum EventBuilderDropSlotKind {
  trigger,
  conditions,
  actions,
  behavior,
  results,
  reactions,
  world,
}
```

**Tests attendus :**

- `conditionFact` accepté par `conditions` ;
- `actionScene` accepté par `actions` ;
- `triggerActor` accepté par `trigger` ;
- `reactionSetFact` refusé tant que reactions non supporté ;
- message humain pour drop incompatible.

**Visual Gate :**

- aucune capture obligatoire.

**Critères d’acceptation :**

- compatibilité testée sans UI ;
- pas de mutation d’event.

### NS-EVENT-26 — Draggable Library Tiles Visual V0

**Type :** UI.

**Objectif :** rendre les éléments de bibliothèque visuellement draggable, sans drop actif.

**Créer :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_draggable_tile.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

**Supprimer :**

- rien.

**Tests attendus :**

- `NS-EVENT-26 library supported items expose draggable affordance`
- `NS-EVENT-26 unsupported items are not draggable`
- `NS-EVENT-26 click fallback still works`

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_26_draggable_library_tiles_visual_v0.png`

**Critères d’acceptation :**

- l’UI suggère le drag ;
- aucun drop ne mute encore l’event.

### NS-EVENT-27 — Builder Drop Zones Visual States V0

**Type :** UI.

**Objectif :** afficher les zones de drop et leurs états hover/compatible/incompatible.

**Créer :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_drop_zone.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`
- `packages/map_editor/test/event_builder_drag_drop_test.dart`

**Supprimer :**

- rien.

**Tests attendus :**

- `NS-EVENT-27 conditions block exposes a drop zone`
- `NS-EVENT-27 actions block exposes a drop zone`
- `NS-EVENT-27 incompatible item shows refusal copy`
- `NS-EVENT-27 hovering does not mutate selected event`

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_27_builder_drop_zones_visual_states_v0.png`

**Critères d’acceptation :**

- les slots sont visibles ;
- aucun drop exécuté encore.

### NS-EVENT-28 — Drop Intent Controller V0

**Type :** UI state / orchestration.

**Objectif :** traduire un drop compatible en intention testable, sans encore appeler tous les callbacks.

**Créer :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_drag_controller.dart`
- `packages/map_editor/test/event_builder_drag_controller_test.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_workspace.dart`

**Supprimer :**

- rien.

**Tests attendus :**

- drop `conditionFact` sur `conditions` produit `addFactConditionIntent` ;
- drop `actionScene` sur `actions` produit `chooseSceneIntent` ;
- drop incompatible produit `refusedIntent` ;
- event non sélectionné produit refus no-code.

**Critères d’acceptation :**

- aucune mutation implicite ;
- toutes les intentions sont nommées et testées.

## Phase C — Drag/drop utile sur capacités existantes

### NS-EVENT-29 — Drop Conditions From Library V0

**Type :** UI authoring.

**Objectif :** permettre de déposer les conditions supportées dans le bloc Conditions.

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_drag_controller.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart`
- `packages/map_editor/test/event_builder_drag_drop_test.dart`

**Supprimer :**

- rien.

**Comportements :**

- drop `Fact vrai/faux` ouvre ou exécute le même flux que le clic ;
- drop `Event consumed/not consumed` ouvre ou exécute le même flux que le clic ;
- si aucun Fact/Event option n’existe, message no-code ;
- legacy condition lock refuse le drop.

**Tests attendus :**

- `NS-EVENT-29 dropping Fact condition adds fact condition`
- `NS-EVENT-29 dropping Event consumed condition excludes current event`
- `NS-EVENT-29 locked legacy conditions refuse condition drop`
- `NS-EVENT-29 refused drop does not mutate event`

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_29_drop_conditions_from_library_v0.png`

### NS-EVENT-30 — Drop Scene Action / Trigger / Behavior From Library V0

**Type :** UI authoring.

**Objectif :** permettre les drops vers les blocs Déclencheur, Action principale et Comportement.

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_drag_controller.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart`
- `packages/map_editor/test/event_builder_drag_drop_test.dart`

**Comportements :**

- drop trigger PNJ/objet/zone appelle le callback de trigger type existant ;
- drop action Scene ouvre le picker Scene ;
- drop behavior oneShot/reusable applique le comportement ;
- effect reste hors MVP.

**Tests attendus :**

- `NS-EVENT-30 dropping object trigger updates trigger type`
- `NS-EVENT-30 dropping scene action opens scene picker`
- `NS-EVENT-30 dropping reusable behavior updates reuse policy`
- `NS-EVENT-30 dropping effect trigger is refused`

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_30_drop_scene_trigger_behavior_v0.png`

### NS-EVENT-31 — Incompatible Drop Diagnostics / No Mutation Gate

**Type :** hardening.

**Objectif :** prouver que les drops interdits ne modifient rien.

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_drop_zone.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_drag_controller.dart`
- `packages/map_editor/test/event_builder_drag_drop_test.dart`

**Tests attendus :**

- drop condition sur Trigger refusé ;
- drop trigger sur Conditions refusé ;
- drop action sur Monde refusé tant que non supporté ;
- drop quand aucun event sélectionné refusé ;
- drop sur condition lock refusé ;
- event avant/après strictement identique si refus.

**Visual Gate :**

- optionnelle, si le refus est visuellement nouveau.

**Critères d’acceptation :**

- pas de mutation silencieuse ;
- message humain ;
- pas de jargon `slotKind` ou `itemKind`.

### NS-EVENT-32 — Keyboard Add / Accessible Drag Alternative V0

**Type :** accessibilité / UX.

**Objectif :** fournir une alternative clavier complète au drag/drop.

**Créer :**

- éventuellement `packages/map_editor/lib/src/ui/canvas/events/event_builder_keyboard_actions.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart`
- `packages/map_editor/test/event_builder_drag_drop_test.dart`

**Tests attendus :**

- focus bibliothèque + Enter ouvre l’action compatible ;
- Escape annule un choix ;
- Tab atteint liste, bibliothèque, builder, inspecteur ;
- aucun piège focus.

**Visual Gate :**

- pas obligatoire, mais capture recommandée si focus states visibles.

**Critères d’acceptation :**

- le drag/drop n’est pas le seul chemin authoring.

## Phase D — Reorder contrôlé

### NS-EVENT-33 — Event Builder Condition Reorder Core Operation V0

**Type :** map_core pure operation.

**Objectif :** réordonner les conditions supportées proprement.

**Créer ou modifier :**

- `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
- `packages/map_core/test/event_builder_authoring_operations_test.dart`
- export si nécessaire dans `packages/map_core/lib/map_core.dart`

**Supprimer :**

- aucun.

**Opération attendue :**

```dart
EventBuilderContract reorderEventBuilderCondition(
  EventBuilderContract contract, {
  required int fromIndex,
  required int toIndex,
})
```

**Tests attendus :**

- reorder 0 → 1 ;
- reorder dernier → premier ;
- index hors limites refusé ;
- legacy condition preserved bloque reorder ;
- compilation conserve un `allOf` valide.

**Critères d’acceptation :**

- pas de UI ;
- pas de runtime ;
- conditions legacy jamais perdues.

### NS-EVENT-34 — Event Builder Condition Reorder UI V0

**Type :** UI drag reorder.

**Objectif :** réordonner les conditions dans le bloc Conditions avec poignée visuelle.

**Modifier :**

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart`
- `packages/map_editor/test/event_builder_drag_drop_test.dart`
- `packages/map_editor/test/event_builder_draft_creation_notifier_test.dart`

**Tests attendus :**

- reorder condition modifie l’ordre ;
- sceneTarget/script/message/metadata préservés ;
- selectedMapEventId préservé ;
- condition legacy lock désactive reorder ;
- alternative clavier existe.

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_34_condition_reorder_ui_v0.png`

### NS-EVENT-35 — Drag/Drop V1A Closure Gate

**Type :** gate / audit.

**Objectif :** fermer le drag/drop sur capacités existantes avant d’ouvrir outcomes/réactions.

**Créer :**

- `reports/narrativeStudio/events/ns_event_35_drag_drop_v1a_closure_gate.md`
- `reports/narrativeStudio/events/screenshots/ns_event_35_drag_drop_v1a_closure_gate.png`

**Tests attendus :**

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
flutter test --reporter=compact test/event_builder_drag_drop_test.dart
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
flutter analyze --no-fatal-infos lib/src/ui/canvas/events test/event_builder_workspace_test.dart test/event_builder_drag_drop_test.dart
```

Si NS-EVENT-33 touche `map_core` :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_authoring_operations_test.dart test/event_builder_contract_test.dart test/event_builder_read_model_test.dart
dart analyze lib/src/authoring/event_builder_authoring_operations.dart test/event_builder_authoring_operations_test.dart
```

**Critères d’acceptation :**

- bibliothèque draggable ;
- drop compatible fonctionne ;
- drop incompatible refusé ;
- reorder conditions disponible ;
- accessibilité minimale prouvée.

## Phase E — Résultats et réactions proches image cible

### NS-EVENT-36 — Event Results Contract / Read Model Prep V0

**Type :** map_core contract.

**Objectif :** représenter `Victoire`, `Défaite`, `Échec` comme résultats authorables, sans battle engine.

**Créer ou modifier :**

- `packages/map_core/lib/src/authoring/event_builder_contract.dart`
- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- `packages/map_core/test/event_builder_contract_test.dart`
- `packages/map_core/test/event_builder_read_model_test.dart`

**Non-objectifs :**

- pas de combat réel ;
- pas de trainer team ;
- pas de runtime.

**Tests attendus :**

- event sans résultats affiche résultats par défaut vides ;
- victory/defeat labels français ;
- unknown result diagnostic ;
- sérialisation metadata si nécessaire.

### NS-EVENT-37 — Event Results UI Blocks V0

**Type :** UI.

**Objectif :** afficher `Résultats possibles` dans le builder central.

**Créer :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_outcome_blocks.dart`

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_central_flow.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

**Tests attendus :**

- bloc Résultats visibles ;
- victoire/défaite/échec lisibles ;
- éléments résultats dans bibliothèque ;
- drag/drop résultats désactivé ou limité selon contrat.

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_37_event_results_ui_blocks_v0.png`

### NS-EVENT-38 — Outcome Reactions Contract V0

**Type :** map_core contract.

**Objectif :** représenter les réactions attachées à un résultat.

**Créer ou modifier :**

- `packages/map_core/lib/src/authoring/event_builder_contract.dart`
- `packages/map_core/lib/src/authoring/event_builder_authoring_operations.dart`
- `packages/map_core/test/event_builder_authoring_operations_test.dart`

**Réactions V0 autorisées :**

- set Fact true/false ;
- play Scene après résultat ;
- complete Story Step seulement si contrat Step prêt, sinon explicitement hors scope.

**Tests attendus :**

- ajouter réaction victory set fact ;
- ajouter réaction defeat scene ;
- retirer réaction ;
- ordre préservé ;
- unknown target diagnostic.

### NS-EVENT-39 — Outcome Reactions UI Add-by-click V0

**Type :** UI authoring.

**Objectif :** ajouter des réactions par clic avant drag/drop.

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_outcome_blocks.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_inspector_panel.dart`
- `packages/map_editor/test/event_builder_workspace_test.dart`

**Tests attendus :**

- ajouter set Fact sur Victoire ;
- ajouter Scene sur Défaite ;
- retirer réaction ;
- labels no-code ;
- aucun champ ID libre.

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_39_outcome_reactions_ui_add_by_click_v0.png`

### NS-EVENT-40 — Outcome Reactions Drag/Drop V0

**Type :** UI drag/drop.

**Objectif :** permettre de déposer des réactions dans les colonnes Victoire/Défaite/Échec.

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_drag_models.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_drag_controller.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_outcome_blocks.dart`
- `packages/map_editor/test/event_builder_drag_drop_test.dart`

**Tests attendus :**

- drop set Fact sur Victoire ;
- drop Scene sur Défaite ;
- drop réaction sur Conditions refusé ;
- drop condition sur Réactions refusé ;
- no mutation on refusal.

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_40_outcome_reactions_drag_drop_v0.png`

## Phase F — Changements du monde et validation

### NS-EVENT-41 — World Changes Contract / Read Model V0

**Type :** map_core contract.

**Objectif :** cadrer les changements du monde authorables depuis Event Builder.

**Changements V0 recommandés :**

- set Fact ;
- unlock Story Step si le modèle Step est disponible ;
- change dialogue target seulement si les contrats Dialogue sont prêts.

**Créer ou modifier :**

- `packages/map_core/lib/src/authoring/event_builder_contract.dart`
- `packages/map_core/lib/src/read_models/event_builder_read_model.dart`
- tests core event builder.

**Non-objectifs :**

- pas de world rule inline complète ;
- pas de modification map directe ;
- pas de visual diff.

### NS-EVENT-42 — World Changes UI + Drop V0

**Type :** UI authoring + drag/drop.

**Objectif :** rendre la section Monde utile et proche cible.

**Modifier :**

- `packages/map_editor/lib/src/ui/canvas/events/event_builder_flow_blocks.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_element_library.dart`
- `packages/map_editor/lib/src/ui/canvas/events/event_builder_drag_controller.dart`
- `packages/map_editor/test/event_builder_drag_drop_test.dart`

**Tests attendus :**

- ajouter world change supporté par clic ;
- drop world change supporté ;
- unsupported world change refusé ;
- labels humains ;
- World Rules workspace reste séparé.

**Visual Gate :**

- `reports/narrativeStudio/events/screenshots/ns_event_42_world_changes_ui_drop_v0.png`

### NS-EVENT-43 — Event Builder V1 Drag/Drop Closure Gate

**Type :** audit / polish / Visual Gate final.

**Objectif :** fermer la V1 drag/drop.

**Créer :**

- `reports/narrativeStudio/events/ns_event_43_event_builder_v1_drag_drop_closure_gate.md`
- `reports/narrativeStudio/events/screenshots/ns_event_43_event_builder_v1_drag_drop_closure_gate.png`

**Tests obligatoires :**

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
flutter test --reporter=compact test/event_builder_drag_drop_test.dart
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
flutter analyze --no-fatal-infos lib/src/ui/canvas/events test/event_builder_workspace_test.dart test/event_builder_drag_drop_test.dart
flutter build macos --debug
```

Core si touché :

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/event_builder_draft_creation_operations_test.dart
dart analyze lib test
```

**Visual Gate final :**

La capture doit montrer :

- liste événements ;
- bibliothèque d’éléments ;
- builder central ;
- inspecteur droit ;
- drag affordance ;
- drop zones ;
- conditions ;
- action Scene ;
- résultats possibles ;
- réactions ;
- changements du monde ;
- message de validation lisible.

**Critères d’acceptation :**

- pas de graph libre ;
- pas de runtime ;
- drop compatible fonctionne ;
- drop incompatible refuse sans mutation ;
- alternative clavier existe ;
- tests et analyse passent ou écarts documentés ;
- l’image cible est atteinte dans l’esprit produit.

## 6. Matrice de dépendances

| Dépendance | Lots concernés | Décision |
|---|---|---|
| Layout central stable | 19+ | Obligatoire avant drag/drop. |
| Bibliothèque read-only | 21+ | Obligatoire avant Draggable. |
| Add-by-click | 22+ | Obligatoire avant drop utile. |
| Slot registry | 25+ | Obligatoire avant DragTarget. |
| Conditions Fact/Event existantes | 29+ | Réutiliser opérations NS-EVENT-13/14. |
| Trigger/Scene/Behavior existants | 30+ | Réutiliser opérations NS-EVENT-11/12/15. |
| Reorder conditions | 33+ | Nécessite pure operation testée. |
| Outcomes/Réactions | 36+ | Nécessite contrat core, pas seulement UI. |
| World changes | 41+ | Ne doit pas dupliquer World Rules workspace. |

## 7. Tests globaux à maintenir

### Tests map_editor récurrents

```bash
cd packages/map_editor
flutter test --reporter=compact test/event_builder_workspace_test.dart
flutter test --reporter=compact test/event_builder_drag_drop_test.dart
flutter test --reporter=compact test/event_builder_draft_creation_notifier_test.dart
flutter analyze --no-fatal-infos lib/src/ui/canvas/events test/event_builder_workspace_test.dart test/event_builder_drag_drop_test.dart
```

### Tests map_core si contrat touché

```bash
cd packages/map_core
dart test --reporter=compact test/event_builder_contract_test.dart test/event_builder_authoring_operations_test.dart test/event_builder_read_model_test.dart test/event_builder_draft_creation_operations_test.dart
dart analyze lib test
```

### Build recommandé à chaque lot UI structurel

```bash
cd packages/map_editor
flutter build macos --debug
```

## 8. Visual Gates attendues

| Lot | Screenshot |
|---|---|
| NS-EVENT-18 | `reports/narrativeStudio/events/screenshots/ns_event_18_creation_panel_compact_collapsible_v0.png` |
| NS-EVENT-19 | `reports/narrativeStudio/events/screenshots/ns_event_19_event_builder_central_blocks_layout_v0.png` |
| NS-EVENT-20 | `reports/narrativeStudio/events/screenshots/ns_event_20_event_inspector_split_v0.png` |
| NS-EVENT-21 | `reports/narrativeStudio/events/screenshots/ns_event_21_element_library_readonly_v0.png` |
| NS-EVENT-22 | `reports/narrativeStudio/events/screenshots/ns_event_22_add_by_click_from_library_v0.png` |
| NS-EVENT-23 | `reports/narrativeStudio/events/screenshots/ns_event_23_actions_conditions_block_polish_v0.png` |
| NS-EVENT-24 | `reports/narrativeStudio/events/screenshots/ns_event_24_mvp_ux_closure_visual_gate.png` |
| NS-EVENT-26 | `reports/narrativeStudio/events/screenshots/ns_event_26_draggable_library_tiles_visual_v0.png` |
| NS-EVENT-27 | `reports/narrativeStudio/events/screenshots/ns_event_27_builder_drop_zones_visual_states_v0.png` |
| NS-EVENT-29 | `reports/narrativeStudio/events/screenshots/ns_event_29_drop_conditions_from_library_v0.png` |
| NS-EVENT-30 | `reports/narrativeStudio/events/screenshots/ns_event_30_drop_scene_trigger_behavior_v0.png` |
| NS-EVENT-34 | `reports/narrativeStudio/events/screenshots/ns_event_34_condition_reorder_ui_v0.png` |
| NS-EVENT-35 | `reports/narrativeStudio/events/screenshots/ns_event_35_drag_drop_v1a_closure_gate.png` |
| NS-EVENT-37 | `reports/narrativeStudio/events/screenshots/ns_event_37_event_results_ui_blocks_v0.png` |
| NS-EVENT-39 | `reports/narrativeStudio/events/screenshots/ns_event_39_outcome_reactions_ui_add_by_click_v0.png` |
| NS-EVENT-40 | `reports/narrativeStudio/events/screenshots/ns_event_40_outcome_reactions_drag_drop_v0.png` |
| NS-EVENT-42 | `reports/narrativeStudio/events/screenshots/ns_event_42_world_changes_ui_drop_v0.png` |
| NS-EVENT-43 | `reports/narrativeStudio/events/screenshots/ns_event_43_event_builder_v1_drag_drop_closure_gate.png` |

## 9. Ce qu’il ne faut pas faire

- Ne pas démarrer par `Draggable` / `DragTarget`.
- Ne pas créer un canvas libre.
- Ne pas faire de drag/drop sans alternative clic/clavier.
- Ne pas accepter un drop incompatible silencieusement.
- Ne pas exposer `slotKind`, `itemKind`, `MapEventType`, `sceneId`, `factId` comme workflow principal.
- Ne pas mélanger World Rules workspace et Event Builder.
- Ne pas créer de runtime camera/event/scene en douce.
- Ne pas modifier Selbrume pendant les lots UI.
- Ne pas supprimer les tests qui interdisent le drag/drop avant le lot qui l’introduit.

## 10. Plan d’exécution recommandé

### Démarrage immédiat

Le prochain prompt devrait être :

```text
NS-EVENT-18 — Creation Panel Compact / Collapsible V0
```

Il doit faire uniquement :

- extraction `event_builder_creation_panel.dart` ;
- panneau création compact ;
- grille repliée quand event sélectionné ;
- tests widget ;
- Visual Gate.

### Moment où le drag/drop devient autorisé

Le drag/drop devient autorisé uniquement après NS-EVENT-24.

Avant NS-EVENT-24, tout prompt qui demande drag/drop doit être refusé ou recadré, car les slots ne sont pas encore stabilisés.

### Premier lot drag/drop réel

Le premier lot drag/drop réel est :

```text
NS-EVENT-25 — Drag/Drop Slot Registry Contract V0
```

Même ce lot ne doit pas encore déplacer des éléments à l’écran. Il crée les garde-fous.

## 11. Auto-review critique

### Ce que ce plan prouve

- Le drag/drop est découpé après stabilisation du layout.
- Les fichiers à créer sont identifiés.
- Les fichiers à modifier sont identifiés.
- Les suppressions sont des extractions progressives, pas des destructions.
- Les tests attendus sont nommés par lot.
- Les Visual Gates sont listées.

### Ce que ce plan ne prouve pas

- Il ne prouve pas que les contrats outcomes/réactions actuels existent déjà.
- Il ne prouve pas que Story Steps sont prêts pour World Changes.
- Il ne prouve pas que `flutter build macos --debug` est vert aujourd’hui.
- Il ne choisit pas encore entre `LongPressDraggable`, `Draggable`, `DragTarget` ou une abstraction maison : ce choix appartient à NS-EVENT-25/26 après audit Flutter UI précis.

### Risques majeurs

- `event_builder_workspace.dart` peut devenir ingérable si les extractions NS-EVENT-18 à 20 sont bâclées.
- Le drag/drop peut être inaccessible si l’alternative clavier est repoussée.
- Les outcomes/réactions peuvent ouvrir un vrai chantier core plus large que prévu.
- Les World Changes peuvent dupliquer les World Rules si la frontière produit n’est pas surveillée.

### Critique du besoin

Demander directement “V1 avec drag/drop” est compréhensible côté produit, parce que l’image cible le suggère fortement. Techniquement, le drag/drop doit rester une couche tardive. Le vrai ordre robuste est :

```text
layout
→ bibliothèque read-only
→ add-by-click
→ slot registry
→ drag/drop visuel
→ drag/drop mutateur
→ reorder
→ outcomes/réactions/monde
→ closure
```

Si on inverse cet ordre, on risque de construire une interaction spectaculaire mais fragile.

## 12. Gate final de ce plan documentaire

Commande :

```text
git status --short --untracked-files=all
```

Sortie :

```text
?? reports/narrativeStudio/events/ns_event_17_target_layout_alignment_plan.md
?? reports/narrativeStudio/events/ns_event_v1_drag_drop_detailed_lot_plan.md
```

Commande :

```text
git diff --stat
```

Sortie :

```text
<vide>
```

Commande :

```text
git diff --name-only
```

Sortie :

```text
<vide>
```

Commande :

```text
git diff --check
```

Sortie :

```text
<vide>
```

Comme ce document est un plan, aucun test Flutter/Dart n’est requis.
