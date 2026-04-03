# LOT 63 — UX placement visuel des waypoints PNJ (Map Editor)

## 1. Résumé exécutif

Ce lot remplace le flux “coordonnées X/Y manuelles uniquement” par un vrai mode de placement visuel des waypoints PNJ sur la map.

Résultat:

- état éditeur explicite pour le mode placement waypoint;
- bouton d’activation/désactivation dans le panneau entité NPC (mode `patrol`);
- clic map re-routé vers `ajout waypoint` tant que le mode est actif;
- mise à jour immédiate des données entité et de la liste de waypoints;
- garde-fous robustes si le contexte devient invalide.

Le lot reste strictement dans le scope demandé (map_editor UX waypoint).

---

## 2. Objectif du lot

Permettre de construire une patrouille PNJ en cliquant directement sur la carte:

1. sélectionner un NPC;
2. activer “placement waypoint”;
3. cliquer la map pour ajouter des waypoints successifs;
4. quitter explicitement le mode placement.

La saisie X/Y reste disponible en secours.

---

## 3. Audit de l’existant (avant implémentation)

Points analysés:

- état de sélection entité dans `EditorState` / `EditorNotifier`;
- flux de clic map dans `map_canvas.dart` (`applyToolAt`, `onTapUp`);
- mutation entité via `updateEntity(...)` (pipeline service/use-case existant);
- synchronisation du panneau via `_syncControllers(...)` dans `EntityPropertiesPanel`.

Constat:

- aucun état dédié pour un mode secondaire “placement waypoint”;
- clic map entièrement piloté par `activeTool`;
- pas de canal explicite pour router le clic map vers “ajout waypoint”;
- panneau entité uniquement orienté saisie manuelle.

---

## 4. Décision d’architecture

### 4.1 État source de vérité

Ajout dans `EditorState`:

- `npcWaypointPlacementEntityId: String?`

Sémantique:

- `null`: pas de mode placement actif;
- non null: le clic map doit viser l’ajout de waypoint pour cet `entityId`.

### 4.2 Orchestration métier côté notifier

Ajout de 3 méthodes dans `EditorNotifier`:

- `startNpcWaypointPlacementForSelectedEntity()`
- `cancelNpcWaypointPlacement(...)`
- `addNpcWaypointAt(GridPos position)`

Le notifier valide le contexte (entity existante, type NPC, mode `patrol`) et applique la mutation entité.

### 4.3 Reroutage du clic map

Dans `MapCanvas`, `onTapUp`:

1. calcule `gridPos`;
2. si placement waypoint actif: tente `notifier.addNpcWaypointAt(gridPos)`;
3. si `handled == true`, le flux s’arrête (pas d’outil normal);
4. sinon, fallback vers le flux outil existant.

### 4.4 UI panneau entité

Dans `EntityPropertiesPanel` (section mouvement NPC):

- bouton toggle:
  - “Placer waypoint sur la map”
  - “Quitter mode placement”
- message explicite quand mode actif;
- conservation des champs manuels existants.

---

## 5. Flux fonctionnel final

1. L’utilisateur sélectionne un NPC.
2. Il met `Déplacement PNJ = Patrouille` (ou garde déjà configuré).
3. Il active le mode placement depuis le panneau.
4. Le canvas affiche un badge de mode actif.
5. Chaque clic map ajoute un waypoint à `npc.movement.waypoints`.
6. Le panneau se resynchronise automatiquement (via mutation map + fingerprint).
7. L’utilisateur peut ajouter plusieurs points et sortir explicitement du mode.

---

## 6. Cas limites gérés

- mode actif sans map active: sortie propre du mode placement;
- entité ciblée supprimée: sortie propre du mode placement;
- entité ciblée non NPC: sortie propre;
- NPC repassé hors `patrol`: sortie propre;
- changement de sélection entité: le mode ne reste actif que si on reste sur la même entité.

---

## 7. Fichiers modifiés

- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.freezed.dart` (généré)
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.g.dart` (généré)
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart`

## 8. Fichiers créés

- `packages/map_editor/test/editor_notifier_npc_waypoint_placement_test.dart`

---

## 9. Extraits clés

### 9.1 État éditeur dédié

`EditorState` porte désormais `npcWaypointPlacementEntityId` pour représenter explicitement la session de placement waypoint.

### 9.2 Notifier: activation / désactivation / ajout

Le notifier encapsule:

- validation de contexte;
- ajout effectif de waypoint;
- annulation sécurisée en cas d’invalidation.

### 9.3 Canvas: reroutage du clic

`onTapUp` tente d’abord l’ajout waypoint si mode actif, puis repasse au flux outil classique uniquement si non consommé.

### 9.4 Panel: UX explicite

Le panneau NPC expose un toggle clair et un indicateur de mode actif.

---

## 10. Tests ajoutés

Fichier:

- `packages/map_editor/test/editor_notifier_npc_waypoint_placement_test.dart`

Couverture:

- activation/désactivation du mode placement;
- ajout d’un waypoint sur la bonne entité;
- sortie propre si contexte invalide.

---

## 11. Validations exécutées

### 11.1 Codegen

```bash
cd packages/map_editor
flutter pub run build_runner build --delete-conflicting-outputs
```

Résultat: OK (génération `freezed`/`riverpod`).

### 11.2 Format

```bash
dart format \
  packages/map_editor/lib/src/features/editor/state/editor_state.dart \
  packages/map_editor/lib/src/features/editor/state/editor_notifier.dart \
  packages/map_editor/lib/src/ui/canvas/map_canvas.dart \
  packages/map_editor/lib/src/ui/panels/entity_properties_panel.dart \
  packages/map_editor/test/editor_notifier_npc_waypoint_placement_test.dart
```

Résultat: OK.

### 11.3 Analyze ciblé

```bash
cd packages/map_editor
flutter analyze \
  lib/src/features/editor/state/editor_state.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  lib/src/ui/canvas/map_canvas.dart \
  lib/src/ui/panels/entity_properties_panel.dart \
  test/editor_notifier_npc_waypoint_placement_test.dart
```

Résultat: **No issues found**.

### 11.4 Tests ciblés

```bash
cd packages/map_editor
flutter test test/editor_notifier_npc_waypoint_placement_test.dart
```

Résultat: **All tests passed**.

---

## 12. Limites restantes

- le lot n’ajoute pas (encore) de rendu graphique des waypoints/segments sur le canvas (hors minimum obligatoire);
- l’UX reste volontairement simple: append de waypoints (pas d’édition directe par drag sur map dans ce lot).

---

## 13. Prochaines étapes logiques (hors lot)

- overlay waypoints + segments sur map pour le NPC sélectionné;
- suppression/réordonnancement de waypoint par interaction map;
- mode “replace waypoint” / insertion à index.

---

## 14. État git final exact

Ce lot a été réalisé sans commit git et sans opération git destructive.

