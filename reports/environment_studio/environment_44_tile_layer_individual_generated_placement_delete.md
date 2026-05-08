# Environment-44 — TileLayer Individual Generated Placement Delete V0

## 1. Résumé

Environment-44 ajoute la suppression individuelle d’un `MapPlacedElement` généré depuis le flow TileLayer-centric.

Ajouts principaux :
- un use case TileLayer-centric `DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase` ;
- un mode notifier start / stop / delete-at-click pour le TileLayer actif ;
- le routing canvas existant réutilisé via `EnvironmentMaskEditMode.generatedDelete` ;
- le wiring `MapInspectorPanel` vers `TileLayerEnvironmentInspectorSection` ;
- une action UI distincte `Supprimer un élément généré` et un état `Suppression active` ;
- tests use case, notifier, canvas, widget et wiring panel.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector reste le lieu de peinture, génération et affinage.
- Ce lot ajoute seulement la suppression individuelle d’un placement généré de l’area sélectionnée.
- L’action reste distincte de `Effacer les placements générés`, qui supprime tout ce qui appartient à l’area.
- Aucun ajout individuel n’est ajouté dans ce lot.

## 3. Audit de l’existant

Fichiers inspectés :
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/environment_generated_placements_clear_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_clear_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Commande d’audit :

```bash
rg -n "deleteGeneratedEnvironmentPlacementAt|deletePlacedElementInstance|addGeneratedEnvironmentPlacementAt|environmentGenerated|generatedPlacementIds|selectedPlacedElementInstanceId|MapPlacedElement|placedElements|hover|EnvironmentGeneratedPlacement|EnvironmentMaskEditMode|delete.*placement|suppression" packages/map_editor/lib/src packages/map_editor/test/environment_studio packages/map_core/lib/src
```

Constats :
- Le legacy possède déjà `EnvironmentMaskEditMode.generatedDelete`.
- `MapCanvas` route déjà les taps en mode `generatedDelete` vers `EditorNotifier.deleteGeneratedEnvironmentPlacementAt(gridPos)`.
- Le legacy savait supprimer individuellement depuis un `EnvironmentLayer` actif.
- Le resolver `resolveEnvironmentGeneratedPlacementDeleteTarget` sait vérifier qu’un placement cliqué appartient à `area.generatedPlacementIds`.
- Ce resolver utilise le `manifest` pour hit-test le footprint multi-tuile via les dimensions de frame quand elles existent.
- Le flow TileLayer-centric manquait la résolution `TileLayer actif -> EnvironmentLayer attaché -> area sélectionnée`.

Décision footprint :
- Footprint supporté en V0, par réutilisation du resolver legacy.
- Le test use case clique une cellule interne d’un élément `big_tree` 2x2 et supprime bien le placement.

## 4. Use case TileLayer-centric

Nom :
- `DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase`

Fichier :
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart`

Entrées :
- `MapData map`
- `ProjectManifest? manifest`
- `String tileLayerId`
- `String areaId`
- `GridPos pos`

Sortie :
- `DeleteTileLayerEnvironmentGeneratedPlacementResult`
- `map`
- `tileLayerId`
- `environmentLayerId`
- `areaId`
- `removedPlacementId`
- `removed`

Validation :
- refuse `tileLayerId` vide ;
- refuse `areaId` vide ;
- refuse TileLayer introuvable ;
- refuse layer non TileLayer ;
- refuse absence d’EnvironmentLayer attaché ;
- refuse area introuvable.

Résolution :

```text
TileLayer actif
→ premier EnvironmentLayer dont targetTileLayerId == tileLayerId
→ area sélectionnée
→ resolver legacy de placement généré cliqué
```

Suppression :
- supprime seulement `MapPlacedElement.id == removedPlacementId` ;
- retire seulement cet id de `area.generatedPlacementIds` ;
- conserve les autres ids ;
- conserve les placements manuels ;
- conserve les placements générés d’autres areas ;
- conserve `mask`, `seed`, `paramsOverride`, `presetId`.

## 5. Notifier / mode

Méthodes ajoutées dans `EditorNotifier` :
- `startDeletingGeneratedEnvironmentPlacementForActiveTileLayer()`
- `stopDeletingGeneratedEnvironmentPlacement()`
- `deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(GridPos pos)`

Comportement start :
- vérifie qu’un TileLayer est actif ;
- vérifie l’area effective ;
- vérifie l’EnvironmentLayer attaché ;
- vérifie qu’il existe des `generatedPlacementIds` ;
- met `environmentMaskEditMode = EnvironmentMaskEditMode.generatedDelete` ;
- garde `activeLayerId` sur le TileLayer ;
- garde `selectedEnvironmentAreaId`.

Comportement stop :
- remet `environmentMaskEditMode` à `null` ;
- garde le TileLayer et l’area sélectionnée.

Comportement delete-at-click :
- exige le mode `generatedDelete` ;
- appelle le use case TileLayer-centric ;
- applique une mutation seulement si un placement est réellement retiré ;
- garde le mode suppression actif après suppression ;
- garde `activeLayerId` et `selectedEnvironmentAreaId` stables ;
- nettoie `selectedPlacedElementInstanceId` si l’élément sélectionné vient d’être supprimé ;
- écrit un `statusMessage` discret si le clic vise du vide, un manuel ou une autre area.

## 6. Canvas routing

`MapCanvas` n’a pas été modifié.

Raison :
- le canvas routait déjà `EnvironmentMaskEditMode.generatedDelete` vers `EditorNotifier.deleteGeneratedEnvironmentPlacementAt(gridPos)`.
- la méthode legacy a été adaptée pour déléguer au flow TileLayer-centric quand `activeLayerId` pointe vers un `TileLayer`.

Priorité :
- le routing existant donne déjà priorité au mode `generatedDelete` avant les autres interactions de tap.

Comportements testés :
- tap sur placement généré de l’area active : suppression ;
- tap sur placement manuel : aucune mutation ;
- mode suppression reste actif ;
- TileLayer et area restent sélectionnés.

## 7. Intégration UI

`TileLayerEnvironmentInspectorSection` reçoit :
- `isDeletingGeneratedPlacement`
- `onStartDeleteGeneratedPlacement`
- `onStopDeleteGeneratedPlacement`

Action ajoutée :
- `Supprimer un élément généré`

Activation :
- active seulement si `readModel.hasGeneratedPlacements == true` ;
- désactive si callback absent ;
- désactive si `readModel.hasErrors == true` ;
- indisponible pendant paint / erase / suppression déjà active.

État actif :
- affiche `Suppression active` ;
- affiche `Cliquez un élément généré pour le retirer de cette zone.` ;
- affiche `Arrêter la suppression`.

Distinction :
- `Supprimer un élément généré` retire un seul placement cliqué ;
- `Effacer les placements générés` reste l’action globale pour vider tous les placements générés de l’area.

## 8. Tests

Commandes lancées et résultats exacts :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart
00:00 +0: DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase supprime un placement généré cliqué dans son footprint
00:00 +1: DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase préserve les placements manuels et les placements d’une autre area
00:00 +2: DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase refuse les entrées invalides sans mutation
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_delete_notifier_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_notifier_test.dart
00:00 +0: EditorNotifier TileLayer individual generated placement delete start delete mode garde TileLayer et stoppe paint/erase
00:00 +1: EditorNotifier TileLayer individual generated placement delete delete at supprime le placement généré et garde le mode actif
00:00 +2: EditorNotifier TileLayer individual generated placement delete clic vide ou manuel ne mute pas la MapData et garde le mode actif
00:00 +3: EditorNotifier TileLayer individual generated placement delete refuse sans TileLayer actif, sans area, ou sans generated ids
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
00:00 +0: tap canvas supprime un placement généré du TileLayer actif
00:00 +1: tap canvas sur placement manuel ne supprime rien
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
00:02 +47: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generate_button_wiring_test.dart
```

```text
00:00 +0: Lot 25 — EditorNotifier.generateEnvironmentAreaPlacements chemin heureux : placements, dirty, layer actif, masque edit arrêté
00:00 +1: Lot 25 — EditorNotifier.generateEnvironmentAreaPlacements masque vide : aucun placement, message sans mutation
00:00 +2: Lot 25 — EditorNotifier.generateEnvironmentAreaPlacements déjà généré : pas de nouveau placement
00:00 +3: Lot 25 — EditorNotifier.generateEnvironmentAreaPlacements cible TileLayer absente : erreur, pas de placement
00:00 +4: Lot 25 — EditorNotifier.generateEnvironmentAreaPlacements apply échoue : conflit id placement existant
00:00 +5: Lot 25 — EnvironmentLayerInspectorPanel Generate sans cible : bouton désactivé + texte cible
00:00 +6: Lot 25 — EnvironmentLayerInspectorPanel Generate cible ok masque vide : désactivé + texte masque
00:00 +7: Lot 25 — EnvironmentLayerInspectorPanel Generate cible tileset incompatible : bouton désactivé
00:00 +8: Lot 25 — EnvironmentLayerInspectorPanel Generate clic Générer : placements + bouton désactivé ensuite
00:01 +9: Lot 25 — EnvironmentLayerInspectorPanel Generate TileLayer inspector active Générer avec une seule area effective
00:01 +10: Lot 25 — EnvironmentLayerInspectorPanel Generate TileLayer inspector désactive Régénérer et Shuffle sans placements générés
00:01 +11: Lot 25 — EnvironmentLayerInspectorPanel Generate TileLayer inspector active et stoppe la suppression individuelle
00:01 +12: Lot 25 — EnvironmentLayerInspectorPanel Generate preset manifest introuvable : désactivé
00:01 +13: All tests passed!
```

Non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generated_placements_clear_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generated_placements_clear_test.dart
00:00 +0: ClearEnvironmentGeneratedPlacementsUseCase — modèles EnvironmentClearResult copie défensivement et listes immuables
00:00 +1: ClearEnvironmentGeneratedPlacementsUseCase — modèles EnvironmentClearedGeneratedPlacement et EnvironmentClearIssue
00:00 +2: ClearEnvironmentGeneratedPlacementsUseCase clear heureux : ids supprimés, manuel conservé, masque et cible préservés
00:00 +3: ClearEnvironmentGeneratedPlacementsUseCase deux areas : clear A ne touche pas B
00:00 +4: ClearEnvironmentGeneratedPlacementsUseCase ids manquants : warning, liste vidée, existant supprimé
00:00 +5: ClearEnvironmentGeneratedPlacementsUseCase generatedPlacementIds vide : map inchangée, warning
00:00 +6: ClearEnvironmentGeneratedPlacementsUseCase erreurs bloquantes : layer / area inconnus
00:00 +7: EditorNotifier.clearEnvironmentGeneratedPlacements succès : dirty, sélection placé nettoyée, status effacé
00:00 +8: EditorNotifier.clearEnvironmentGeneratedPlacements deletePlacedElementInstance retire un placement généré individuel et sa référence
[editor][elements] deleted generated placed instance id=g1 elementId=e1 layer=tiles pos=(0,0)
00:00 +9: EditorNotifier.clearEnvironmentGeneratedPlacements deleteGeneratedEnvironmentPlacementAt supprime le placement généré cliqué dans son footprint
[editor][environment] deleted generated placement by click id=tree_a elementId=tree pos=(0,0)
00:00 +10: EditorNotifier.clearEnvironmentGeneratedPlacements addGeneratedEnvironmentPlacementAt ajoute un placement individuel du preset
[editor][environment] added generated placement by click id=env_gen_a1_1_1_tree elementId=tree pos=(1,1)
00:00 +11: EditorNotifier.clearEnvironmentGeneratedPlacements no-op ids vides : map inchangée, isDirty inchangé
00:00 +12: EnvironmentLayerInspectorPanel — Clear sans placements générés : bouton disabled + texte
00:00 +13: EnvironmentLayerInspectorPanel — Clear clear puis generate disponible
00:01 +14: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_clear_use_case_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_clear_use_case_test.dart
00:00 +0: ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase efface les placements générés de l’area ciblée seulement
00:00 +1: ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase generatedPlacementIds vide retourne un no-op clair
00:00 +2: ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase refuse les entrées invalides sans mutation
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_clear_notifier_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_clear_notifier_test.dart
00:00 +0: EditorNotifier TileLayer environment clear efface les placements générés et garde la sélection TileLayer stable
00:00 +1: EditorNotifier TileLayer environment clear refuse si aucun TileLayer actif
00:00 +2: EditorNotifier TileLayer environment clear refuse si aucune area est sélectionnée
00:00 +3: EditorNotifier TileLayer environment clear aucun generatedPlacementId ne mute pas la MapData
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_use_case_test.dart
00:00 +0: TileLayer environment regenerate / shuffle use cases regenerate clear puis génère avec le même seed
00:00 +1: TileLayer environment regenerate / shuffle use cases shuffle clear puis change seed et génère
00:00 +2: TileLayer environment regenerate / shuffle use cases regenerate peut finir sans nouveaux candidats après clear
00:00 +3: TileLayer environment regenerate / shuffle use cases refuse les entrées invalides sans mutation
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_regenerate_shuffle_notifier_test.dart
00:00 +0: EditorNotifier TileLayer regenerate / shuffle regenerate garde la sélection TileLayer et conserve le seed
00:00 +1: EditorNotifier TileLayer regenerate / shuffle shuffle garde la sélection TileLayer et change le seed
00:00 +2: EditorNotifier TileLayer regenerate / shuffle refuse sans TileLayer actif ou sans area sélectionnée
00:00 +3: EditorNotifier TileLayer regenerate / shuffle refuse si generatedPlacementIds est vide
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
00:00 +0: Golden Slice — workflow notifier complet generate → clear → generate → regenerate → shuffle ; manuel conservé
00:00 +1: Golden Slice — workflow notifier complet shuffle sans placements générés préalables : seed change et placements
00:00 +2: Golden Slice — workflow notifier complet clear sans placements : message statut, carte inchangée
00:00 +3: Golden Slice — inspecteur minimal résumé + Generate activé quand prêt
00:00 +4: Golden Slice — inspecteur minimal Generate désactivé sans cible TileLayer
00:00 +5: Golden Slice — validation finale (Lot 29) generate → clear → generate → regenerate → shuffle : invariants manifest, tuiles, masque, sélection, ids
00:00 +6: All tests passed!
```

Cas couverts :
- suppression par footprint ;
- suppression via notifier ;
- routing tap canvas ;
- no-op sur placement manuel ;
- no-op sur autre area ;
- start/stop mode ;
- UI bouton actif/désactivé ;
- wiring MapInspectorPanel ;
- non-régression legacy clear/generate/regenerate/shuffle.

## 9. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart test/environment_studio/tile_layer_environment_individual_delete_notifier_test.dart test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_generate_button_wiring_test.dart
```

Résultat exact :

```text
Analyzing 10 items...                                           
No issues found! (ran in 2.9s)
```

Dettes préexistantes hors lot :
- aucune dette bloquante détectée par l’analyse ciblée ;
- les logs `[editor][elements]` et `[editor][environment]` dans `environment_generated_placements_clear_test.dart` sont des sorties legacy préexistantes.

## 10. Fichiers créés/modifiés

Fichiers préexistants dans le worktree avant Environment-44 :
- aucun fichier modifié ou non suivi au `git status --short --untracked-files=all` initial.

Fichiers créés par Environment-44 :
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_notifier_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart`
- `reports/environment_studio/environment_44_tile_layer_individual_generated_placement_delete.md`

Fichiers modifiés par Environment-44 :
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fichiers inspectés mais non modifiés :
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`

## 11. Non-objectifs respectés

- Pas d’ajout individuel.
- Pas de génération.
- Pas de clear global ajouté ou modifié.
- Pas de regenerate/shuffle modifié.
- Pas de preview.
- Pas de modification du mask.
- Pas de modification des params locaux.
- Pas de modification du preset global.
- Pas de création, suppression ou renommage d’EnvironmentArea.
- Pas de modification de `map_core`.
- Pas de modification de `map_runtime`.
- Pas de modification de `map_gameplay`.
- Pas de modification de `map_battle`.
- Pas de `build_runner`.
- Aucun generated file modifié.

## 12. Evidence pack

### Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact initial :

```text

```

### Git status après implémentation avant rapport

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart
```

### Git diff stat

Commande :

```bash
git diff --stat
```

Résultat exact avant création du rapport :

```text
 .../src/features/editor/state/editor_notifier.dart | 166 +++++++++++++++++++++
 .../lib/src/ui/panels/map_inspector_panel.dart     |  28 +++-
 .../tile_layer_environment_inspector_section.dart  |  95 +++++++++++-
 .../environment_generate_button_wiring_test.dart   |  99 ++++++++++++
 ...e_layer_environment_inspector_section_test.dart | 144 ++++++++++++++++++
 5 files changed, 529 insertions(+), 3 deletions(-)
```

Note vérifiable :
- `git diff --stat` ne liste pas les fichiers non suivis.
- Les fichiers créés par Environment-44 sont listés dans `git status --short --untracked-files=all`.

### Git diff name-only

Commande :

```bash
git diff --name-only
```

Résultat exact avant création du rapport :

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

### Git diff check

Commande :

```bash
git diff --check
```

Résultat exact :

```text

```

Exit code : `0`.

## 13. Diff pertinent

Les fichiers de tests créés contiennent des fixtures répétitives. Les blocs reproduits ci-dessous incluent les assertions comportementales et les chemins de production qui prouvent le lot : validation, suppression, préservation, routing canvas et wiring UI.

### Nouveau use case

```dart
final class DeleteTileLayerEnvironmentGeneratedPlacementResult {
  const DeleteTileLayerEnvironmentGeneratedPlacementResult({
    required this.map,
    required this.tileLayerId,
    required this.environmentLayerId,
    required this.areaId,
    required this.removedPlacementId,
  });

  final MapData map;
  final String tileLayerId;
  final String environmentLayerId;
  final String areaId;
  final String? removedPlacementId;

  bool get removed => removedPlacementId != null;
}

class DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase {
  DeleteTileLayerEnvironmentGeneratedPlacementResult execute(
    MapData map, {
    required ProjectManifest? manifest,
    required String tileLayerId,
    required String areaId,
    required GridPos pos,
  }) {
    final target = _resolveTarget(
      map,
      tileLayerId: tileLayerId,
      areaId: areaId,
    );
    final deleteTarget = resolveEnvironmentGeneratedPlacementDeleteTarget(
      map: map,
      manifest: manifest,
      activeLayerId: target.environmentLayer.id,
      selectedAreaId: target.area.id,
      pos: pos,
    );
    if (deleteTarget == null) {
      return DeleteTileLayerEnvironmentGeneratedPlacementResult(
        map: map,
        tileLayerId: target.tileLayer.id,
        environmentLayerId: target.environmentLayer.id,
        areaId: target.area.id,
        removedPlacementId: null,
      );
    }

    final updated = _deleteGeneratedPlacement(
      map,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      placedElementId: deleteTarget.placed.id,
    );
    MapValidator.validate(updated, projectDialogueContext: manifest);
    return DeleteTileLayerEnvironmentGeneratedPlacementResult(
      map: updated,
      tileLayerId: target.tileLayer.id,
      environmentLayerId: target.environmentLayer.id,
      areaId: target.area.id,
      removedPlacementId: deleteTarget.placed.id,
    );
  }
}
```

### Suppression ciblée dans le use case

```dart
MapData _deleteGeneratedPlacement(
  MapData map, {
  required String environmentLayerId,
  required String areaId,
  required String placedElementId,
}) {
  return map.copyWith(
    layers: [
      for (final layer in map.layers)
        if (layer is EnvironmentLayer && layer.id == environmentLayerId)
          MapLayer.environment(
            id: layer.id,
            name: layer.name,
            isVisible: layer.isVisible,
            opacity: layer.opacity,
            content: EnvironmentLayerContent(
              targetTileLayerId: layer.content.targetTileLayerId,
              areas: [
                for (final area in layer.content.areas)
                  if (area.id == areaId)
                    EnvironmentArea(
                      id: area.id,
                      name: area.name,
                      presetId: area.presetId,
                      mask: area.mask,
                      seed: area.seed,
                      paramsOverride: area.paramsOverride,
                      generatedPlacementIds: [
                        for (final id in area.generatedPlacementIds)
                          if (id != placedElementId) id,
                      ],
                    )
                  else
                    area,
              ],
            ),
            properties: layer.properties,
          )
        else
          layer,
    ],
    placedElements: [
      for (final placed in map.placedElements)
        if (placed.id != placedElementId) placed,
    ],
  );
}
```

### Notifier TileLayer-centric

```diff
+  void startDeletingGeneratedEnvironmentPlacementForActiveTileLayer() {
+    final map = state.activeMap;
+    if (map == null) return;
+    final layerId = state.activeLayerId?.trim();
+    if (layerId == null || layerId.isEmpty) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez un TileLayer pour supprimer un élément généré.',
+      );
+      return;
+    }
+    final activeLayer = _findLayerById(map, layerId);
+    if (activeLayer is! TileLayer) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez un TileLayer pour supprimer un élément généré.',
+      );
+      return;
+    }
+    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
+    if (areaId == null || areaId.isEmpty) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez une zone d’environnement avant de supprimer un élément généré.',
+      );
+      return;
+    }
+    final target = resolveEnvironmentMaskPaintTarget(
+      map: map,
+      activeLayerId: layerId,
+      selectedAreaId: areaId,
+    );
+    if (target == null) {
+      final hasAttachment = map.layers.any(
+        (layer) =>
+            layer is EnvironmentLayer &&
+            layer.content.targetTileLayerId?.trim() == layerId,
+      );
+      state = state.copyWith(
+        errorMessage: hasAttachment
+            ? 'La zone d’environnement sélectionnée est introuvable.'
+            : 'Activez d’abord l’environnement sur ce layer.',
+      );
+      return;
+    }
+    if (target.area.generatedPlacementIds.isEmpty) {
+      state = state.copyWith(
+        activeLayerId: layerId,
+        selectedEnvironmentAreaId: target.areaId,
+        environmentMaskEditMode: null,
+        statusMessage:
+            'Aucun placement généré à supprimer individuellement pour cette zone.',
+        errorMessage: null,
+      );
+      return;
+    }
+
+    state = state.copyWith(
+      activeLayerId: layerId,
+      selectedEnvironmentAreaId: target.areaId,
+      environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
+      statusMessage:
+          'Suppression active : cliquez un élément généré pour le retirer.',
+      errorMessage: null,
+    );
+  }
```

```diff
+  bool deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(GridPos pos) {
+    final map = state.activeMap;
+    if (map == null) {
+      return false;
+    }
+    if (state.environmentMaskEditMode !=
+        EnvironmentMaskEditMode.generatedDelete) {
+      state = state.copyWith(
+        errorMessage:
+            'Activez la suppression d’un élément généré avant de cliquer.',
+      );
+      return false;
+    }
+    final layerId = state.activeLayerId?.trim();
+    if (layerId == null || layerId.isEmpty) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez un TileLayer pour supprimer un élément généré.',
+      );
+      return false;
+    }
+    final activeLayer = _findLayerById(map, layerId);
+    if (activeLayer is! TileLayer) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez un TileLayer pour supprimer un élément généré.',
+      );
+      return false;
+    }
+    final areaId = _effectiveEnvironmentAreaIdForActiveTileLayer(map, layerId);
+    if (areaId == null || areaId.isEmpty) {
+      state = state.copyWith(
+        errorMessage:
+            'Sélectionnez une zone d’environnement avant de supprimer un élément généré.',
+      );
+      return false;
+    }
+
+    try {
+      final result =
+          DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase().execute(
+        map,
+        manifest: state.project,
+        tileLayerId: layerId,
+        areaId: areaId,
+        pos: pos,
+      );
+      if (!result.removed) {
+        state = state.copyWith(
+          activeLayerId: result.tileLayerId,
+          selectedEnvironmentAreaId: result.areaId,
+          environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
+          statusMessage:
+              'Aucun placement généré de cette zone à supprimer ici.',
+          errorMessage: null,
+        );
+        return false;
+      }
+
+      final removedId = result.removedPlacementId!;
+      final selectionBefore = state.selectedPlacedElementInstanceId?.trim();
+      final clearSelection = selectionBefore != null &&
+          selectionBefore.isNotEmpty &&
+          selectionBefore == removedId;
+      _applyMapMutation(
+        previousMap: map,
+        updatedMap: result.map,
+        preferredActiveLayerId: result.tileLayerId,
+        statusMessage: 'Placement généré supprimé.',
+      );
+      state = state.copyWith(
+        activeLayerId: result.tileLayerId,
+        selectedEnvironmentAreaId: result.areaId,
+        selectedPlacedElementInstanceId:
+            clearSelection ? null : state.selectedPlacedElementInstanceId,
+        environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
+        errorMessage: null,
+      );
+      return true;
+    } catch (e) {
+      state = state.copyWith(
+        errorMessage: 'Impossible de supprimer cet élément généré : $e',
+      );
+      return false;
+    }
+  }
```

### Délégation canvas existante

```diff
     final activeLayer = _findLayerById(map, activeLayerId);
+    if (activeLayer is TileLayer) {
+      return deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(pos);
+    }
     if (activeLayer is! EnvironmentLayer) {
       return false;
     }
```

### MapInspectorPanel wiring

```diff
+    final isTileLayerGeneratedPlacementDeleteActive =
+        activeLayer is TileLayer &&
+            tileLayerEnvironmentReadModel != null &&
+            state.environmentMaskEditMode ==
+                EnvironmentMaskEditMode.generatedDelete &&
+            effectiveTileLayerEnvironmentAreaId != null;
     final isTileLayerMaskEditingActive =
         isTileLayerMaskPaintingActive || isTileLayerMaskErasingActive;
+    final isTileLayerEnvironmentActionActive = isTileLayerMaskEditingActive ||
+        isTileLayerGeneratedPlacementDeleteActive;
...
+    final canStartTileLayerGeneratedPlacementDelete =
+        activeLayer is TileLayer &&
+            tileLayerEnvironmentReadModel != null &&
+            tileLayerEnvironmentReadModel.hasGeneratedPlacements &&
+            !tileLayerEnvironmentReadModel.hasErrors &&
+            effectiveTileLayerEnvironmentAreaId != null &&
+            !isTileLayerEnvironmentActionActive;
```

```diff
+                    isDeletingGeneratedPlacement:
+                        isTileLayerGeneratedPlacementDeleteActive,
...
+                    onStartDeleteGeneratedPlacement:
+                        canStartTileLayerGeneratedPlacementDelete
+                            ? notifier
+                                .startDeletingGeneratedEnvironmentPlacementForActiveTileLayer
+                            : null,
+                    onStopDeleteGeneratedPlacement:
+                        isTileLayerGeneratedPlacementDeleteActive
+                            ? notifier.stopDeletingGeneratedEnvironmentPlacement
+                            : null,
```

### UI section

```diff
+          if (isDeletingGeneratedPlacement) ...[
+            const SizedBox(height: 12),
+            const _ActiveGeneratedPlacementDeleteBanner(),
+          ],
```

```dart
class _ActiveGeneratedPlacementDeleteBanner extends StatelessWidget {
  const _ActiveGeneratedPlacementDeleteBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.12),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suppression active',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Cliquez un élément généré pour le retirer de cette zone.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
```

```diff
+    if (isDeletingGeneratedPlacement) {
+      actions.add(
+        _ActionData(
+          icon: CupertinoIcons.stop_circle,
+          label: 'Arrêter la suppression',
+          enabled: onStopDeleteGeneratedPlacement != null,
+          onPressed: onStopDeleteGeneratedPlacement,
+        ),
+      );
+    } else if (isMaskEditingActive) {
```

```diff
+    if (!isEnvironmentActionActive &&
+        (readModel.hasGeneratedPlacements || readModel.canPaintMask)) {
+      actions.add(
+        _ActionData(
+          icon: CupertinoIcons.minus_circle,
+          label: 'Supprimer un élément généré',
+          enabled: readModel.hasGeneratedPlacements &&
+              !readModel.hasErrors &&
+              onStartDeleteGeneratedPlacement != null,
+          onPressed: readModel.hasGeneratedPlacements
+              ? onStartDeleteGeneratedPlacement
+              : null,
+        ),
+      );
+    }
```

### Tests use case

```dart
test('supprime un placement généré cliqué dans son footprint', () {
  final map = _map();
  final result =
      DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase().execute(
    map,
    manifest: _manifest(),
    tileLayerId: 'tiles',
    areaId: 'area',
    pos: const GridPos(x: 2, y: 2),
  );

  expect(result.removed, isTrue);
  expect(result.removedPlacementId, 'generated_big');
  expect(result.tileLayerId, 'tiles');
  expect(result.environmentLayerId, 'env');
  expect(result.areaId, 'area');
  expect(
    result.map.placedElements.map((element) => element.id).toList(),
    const ['manual', 'generated_a', 'other_generated'],
  );

  final area = _areaById(result.map, 'area');
  expect(area.generatedPlacementIds, const ['generated_a', 'missing_ref']);
  expect(area.mask, _areaById(map, 'area').mask);
  expect(area.paramsOverride, _params);
  expect(area.seed, 11);
  expect(area.presetId, 'forest');

  final other = _areaById(result.map, 'other');
  expect(other.generatedPlacementIds, const ['other_generated']);
});
```

```dart
test('préserve les placements manuels et les placements d’une autre area', () {
  final map = _map();
  final useCase = DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase();

  final manualResult = useCase.execute(
    map,
    manifest: _manifest(),
    tileLayerId: 'tiles',
    areaId: 'area',
    pos: const GridPos(x: 0, y: 0),
  );
  expect(identical(manualResult.map, map), isTrue);
  expect(manualResult.removed, isFalse);

  final otherAreaResult = useCase.execute(
    map,
    manifest: _manifest(),
    tileLayerId: 'tiles',
    areaId: 'area',
    pos: const GridPos(x: 4, y: 4),
  );
  expect(identical(otherAreaResult.map, map), isTrue);
  expect(otherAreaResult.removed, isFalse);
  expect(
    otherAreaResult.map.placedElements.map((element) => element.id),
    containsAll(const ['manual', 'other_generated']),
  );
  expect(
    _areaById(otherAreaResult.map, 'other').generatedPlacementIds,
    const ['other_generated'],
  );
});
```

### Tests notifier

```dart
test('start delete mode garde TileLayer et stoppe paint/erase', () {
  notifier.state = EditorState(
    project: _manifest(),
    activeMap: map,
    activeLayerId: 'tiles',
    selectedEnvironmentAreaId: 'area',
    environmentMaskEditMode: EnvironmentMaskEditMode.paint,
  );

  notifier.startDeletingGeneratedEnvironmentPlacementForActiveTileLayer();

  final state = notifier.state;
  expect(state.activeMap, same(map));
  expect(state.activeLayerId, 'tiles');
  expect(state.selectedEnvironmentAreaId, 'area');
  expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.generatedDelete);
  expect(state.statusMessage, contains('Suppression active'));
  expect(state.errorMessage, isNull);

  notifier.stopDeletingGeneratedEnvironmentPlacement();

  final stopped = notifier.state;
  expect(stopped.activeLayerId, 'tiles');
  expect(stopped.selectedEnvironmentAreaId, 'area');
  expect(stopped.environmentMaskEditMode, isNull);
  expect(stopped.statusMessage, contains('arrêtée'));
});
```

```dart
test('delete at supprime le placement généré et garde le mode actif', () {
  notifier.state = EditorState(
    project: _manifest(),
    activeMap: map,
    activeLayerId: 'tiles',
    selectedEnvironmentAreaId: 'area',
    environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
    selectedPlacedElementInstanceId: 'generated_big',
    savedMapSnapshot: map,
  );

  notifier.deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(
    const GridPos(x: 2, y: 2),
  );

  final state = notifier.state;
  expect(state.activeMap, isNot(same(map)));
  expect(state.activeLayerId, 'tiles');
  expect(state.selectedEnvironmentAreaId, 'area');
  expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.generatedDelete);
  expect(state.selectedPlacedElementInstanceId, isNull);
  expect(state.statusMessage, contains('Placement généré supprimé'));
  expect(state.errorMessage, isNull);
  expect(state.isDirty, isTrue);
  expect(
    state.activeMap!.placedElements.map((element) => element.id).toList(),
    const ['manual', 'generated_a', 'other_generated'],
  );
});
```

### Tests canvas

```dart
testWidgets('tap canvas supprime un placement généré du TileLayer actif',
    (tester) async {
  container.read(editorNotifierProvider.notifier).state = EditorState(
    project: _manifest(),
    activeMap: map,
    activeLayerId: 'tiles',
    selectedEnvironmentAreaId: 'area',
    environmentMaskEditMode: EnvironmentMaskEditMode.generatedDelete,
    savedMapSnapshot: map,
  );

  await _pumpCanvas(tester, container);

  final mapBox = tester.getRect(find.byType(MapCanvas));
  await tester.tapAt(mapBox.topLeft + const Offset(48, 48));
  await tester.pump();

  final state = container.read(editorNotifierProvider);
  expect(state.activeLayerId, 'tiles');
  expect(state.selectedEnvironmentAreaId, 'area');
  expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.generatedDelete);
  expect(
    state.activeMap!.placedElements.map((element) => element.id).toList(),
    const ['manual', 'other_generated'],
  );
  expect(_areaById(state.activeMap!, 'area').generatedPlacementIds, isEmpty);
});
```

### Tests UI

```dart
testWidgets('Supprimer un élément généré est actif avec callback',
    (tester) async {
  var started = 0;
  await _pump(
    tester,
    const TileLayerEnvironmentAttachmentReadModel(
      state: TileLayerEnvironmentAttachmentState.generated,
      selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
      hasAttachment: true,
      hasValidTargetTileLayer: true,
      selectedEnvironmentAreaName: 'Bosquet nord',
      selectedPresetName: 'Forêt',
      maskActiveCellCount: 42,
      hasMask: true,
      generatedPlacementCount: 18,
      hasGeneratedPlacements: true,
      canClearGeneratedPlacements: true,
      emptyStateTitle: 'Placements générés',
      emptyStateMessage: 'Cette zone contient déjà des placements générés.',
    ),
    onStartDeleteGeneratedPlacement: () {
      started++;
    },
  );

  expect(_buttonFor(tester, 'Supprimer un élément généré').onPressed,
      isNotNull);

  await tester.ensureVisible(find.text('Supprimer un élément généré'));
  await tester.tap(find.text('Supprimer un élément généré'));
  await tester.pump();

  expect(started, 1);
});
```

### Test MapInspectorPanel wiring

```dart
testWidgets('TileLayer inspector active et stoppe la suppression individuelle',
    (tester) async {
  final area = _area(
    id: 'area1',
    w: 2,
    h: 2,
    generatedPlacementIds: const ['generated'],
  );
  final generated = MapPlacedElement(
    id: 'generated',
    layerId: 'tiles',
    elementId: 'e1',
    pos: const GridPos(x: 1, y: 1),
  );
  final map = MapData(
    id: 'm1',
    name: 'M1',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'tsA',
    layers: [tile, env],
    placedElements: [generated],
  );
  container.read(editorNotifierProvider.notifier).state = EditorState(
    projectRootPath: '/r',
    project: _manifest(),
    activeMap: map,
    activeMapPath: 'maps/x.json',
    activeLayerId: 'tiles',
    selectedEnvironmentAreaId: 'area1',
    savedMapSnapshot: map,
  );

  final startDelete = find.text('Supprimer un élément généré');
  expect(startDelete, findsOneWidget);
  expect(_cupertinoButtonFor(tester, 'Supprimer un élément généré').onPressed,
      isNotNull);

  await tester.tap(startDelete);
  await tester.pumpAndSettle();

  var state = container.read(editorNotifierProvider);
  expect(state.activeLayerId, 'tiles');
  expect(state.selectedEnvironmentAreaId, 'area1');
  expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.generatedDelete);
  expect(find.text('Suppression active'), findsOneWidget);
  expect(find.text('Arrêter la suppression'), findsOneWidget);

  await tester.tap(find.text('Arrêter la suppression'));
  await tester.pumpAndSettle();

  state = container.read(editorNotifierProvider);
  expect(state.activeLayerId, 'tiles');
  expect(state.selectedEnvironmentAreaId, 'area1');
  expect(state.environmentMaskEditMode, isNull);
});
```

## 14. Auto-review

- La suppression individuelle cible-t-elle uniquement l’area sélectionnée ? Oui, le use case résout l’area sélectionnée et le resolver vérifie `generatedPlacementIds`.
- Les placements manuels sont-ils préservés ? Oui, tests use case, notifier et canvas.
- Les placements générés d’autres areas sont-ils préservés ? Oui, tests use case, notifier et canvas.
- L’id est-il retiré de `generatedPlacementIds` ? Oui, tests use case, notifier et canvas.
- Le `MapPlacedElement` est-il supprimé ? Oui.
- `mask / seed / paramsOverride / presetId` sont-ils préservés ? Oui, tests use case et notifier.
- `activeLayerId` reste-t-il le TileLayer ? Oui, tests notifier, canvas et wiring panel.
- `selectedEnvironmentAreaId` reste-t-il stable ? Oui.
- Le mode suppression est-il activable/désactivable ? Oui.
- Le clic vide ne mute-t-il pas MapData ? Oui, test notifier et canvas sur manuel/no-op.
- Le flow legacy reste-t-il intact ? Oui, non-régression `environment_generated_placements_clear_test.dart` verte.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 15. Critique du prompt et du lot

Ce qui était clair :
- le périmètre strict : suppression individuelle uniquement ;
- l’appartenance à l’area sélectionnée via `generatedPlacementIds` ;
- la distinction UI entre suppression individuelle et clear global ;
- les non-objectifs, notamment pas d’ajout individuel et pas de génération.

Ce qui était ambigu :
- si le hover preview devait aussi être TileLayer-centric. Le routing clic fonctionne sans modifier `MapCanvas`; le hover visuel n’a pas été étendu dans ce lot.
- si le mode devait auto-stop après un clic. La recommandation V0 était de garder le mode actif, ce qui a été retenu.

À trancher avant Environment-45 :
- comment choisir l’élément à ajouter individuellement depuis le preset ;
- si l’ajout individuel doit utiliser une palette dédiée ou un item par défaut ;
- si le hover preview doit afficher explicitement le placement généré ciblable côté TileLayer-centric.

## 16. Verdict

```text
Environment-44 livré
Code produit modifié : oui
Code UI/canvas modifié : oui côté UI, non côté fichier canvas
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-45 — TileLayer Individual Generated Placement Add V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement la suppression individuelle.
- [x] Je n’ai pas ajouté l’ajout individuel.
- [x] Je n’ai pas lancé de génération.
- [x] Je n’ai pas ajouté de preview.
- [x] Je n’ai pas modifié le mask.
- [x] Je n’ai pas modifié les params locaux.
- [x] Je n’ai pas modifié le preset global.
- [x] Je n’ai pas créé/supprimé/renommé d’area.
- [x] Les placements manuels sont préservés.
- [x] Le TileLayer reste sélectionné.
- [x] selectedEnvironmentAreaId reste stable.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.

## Commande finale obligatoire

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact final :

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart
?? reports/environment_studio/environment_44_tile_layer_individual_generated_placement_delete.md
```
