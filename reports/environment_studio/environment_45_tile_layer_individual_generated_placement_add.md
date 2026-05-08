# Environment-45 — TileLayer Individual Generated Placement Add V0

## 1. Résumé

Environment-45 ajoute l’ajout individuel d’un placement généré depuis le flow TileLayer-centric.

Ajouts principaux :
- exposition de la palette du preset actif dans le read model TileLayer-centric ;
- sélection editor-only de l’élément de palette à ajouter ;
- use case `AddTileLayerEnvironmentGeneratedPlacementAtUseCase` ;
- méthodes notifier `select/start/stop/add at` côté TileLayer actif ;
- routage canvas via le mode existant `EnvironmentMaskEditMode.generatedAdd` ;
- UI “Palette du preset”, “Ajouter un élément généré”, “Ajout actif”, “Arrêter l’ajout” ;
- tests use case, notifier, canvas, read model et widget.

Complément post-livraison demandé explicitement par l’utilisateur :
- surbrillance du placement généré qui sera supprimé en mode “Supprimer un élément généré” depuis le flow TileLayer-centric ;
- correction du resolver de hover pour accepter un TileLayer actif et résoudre l’EnvironmentLayer attaché ;
- test canvas vérifiant que le painter reçoit l’id du placement supprimable au hover.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector reste le lieu de peinture, génération et affinage.
- Ce lot ajoute seulement l’ajout individuel d’un élément généré.
- Aucune nouvelle suppression individuelle n’a été ajoutée.
- L’ajout individuel est disponible seulement quand l’area sélectionnée a déjà des `generatedPlacementIds`.

## 3. Audit de l’existant

Fichiers inspectés :
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/environment_generated_placements_clear_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_notifier_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Audit fonctionnel :
- Le legacy possédait déjà `addGeneratedEnvironmentPlacementAt(GridPos pos)` pour un `EnvironmentLayer` actif.
- Le canvas routait déjà `EnvironmentMaskEditMode.generatedAdd` vers `notifier.addGeneratedEnvironmentPlacementAt(gridPos)`.
- Le legacy choisissait automatiquement le premier item valide du preset, validait le footprint/bounds, créait un `MapPlacedElement`, puis ajoutait son id dans `generatedPlacementIds`.
- Environment-44 avait déjà ajouté un fichier TileLayer-centric pour l’édition individuelle générée ; Environment-45 le complète avec l’ajout.
- La stratégie d’id reprend `generatedEnvironmentPlacementId(areaId, pos, elementId)` avec suffixe `_2`, `_3`, etc. en cas de conflit.
- Le footprint utilisé est celui de `element.frames.primarySource`, avec minimum `1x1`.
- Le mode `EnvironmentMaskEditMode.generatedAdd` existait déjà, donc aucun champ Freezed/généré n’a été ajouté.

## 4. Read model / palette

Read model modifié :
- nouveau `TileLayerEnvironmentPaletteItemSummary` ;
- nouveau champ `selectedAreaPaletteItems` ;
- nouveau booléen `canAddGeneratedPlacement`.

Champs exposés par item :
- `elementId`
- `elementName`
- `weight`
- `collisionMode`
- `hasMissingElement`
- `isSelected`

Règle `canAddGeneratedPlacement` :
- `generatedPlacementCount > 0` obligatoire ;
- au moins un item disponible dans la palette ;
- si un seul item valide existe, sélection implicite autorisée ;
- si plusieurs items valides existent, un item sélectionné est requis.

Éléments manquants :
- restent affichés dans la palette avec `hasMissingElement: true` ;
- ne rendent pas l’ajout possible.

## 5. Use case TileLayer-centric

Nom :
- `AddTileLayerEnvironmentGeneratedPlacementAtUseCase`

Entrées :
- `MapData map`
- `ProjectManifest manifest`
- `String tileLayerId`
- `String areaId`
- `String elementId`
- `GridPos pos`

Sortie :
- `AddTileLayerEnvironmentGeneratedPlacementResult`
- `map`
- `tileLayerId`
- `environmentLayerId`
- `areaId`
- `addedPlacementId`
- `added`

Validations :
- `tileLayerId` non vide ;
- layer trouvé et bien `TileLayer` ;
- `EnvironmentLayer` attaché via `targetTileLayerId` ;
- `areaId` non vide ;
- area trouvée ;
- area déjà générée (`generatedPlacementIds` non vide) ;
- preset trouvé ;
- `elementId` non vide ;
- élément présent dans la palette du preset ;
- élément présent dans `ProjectManifest.elements` ;
- tileset élément compatible avec le TileLayer ;
- footprint dans les bounds de la map.

Effets :
- crée un `MapPlacedElement` sur le TileLayer actif ;
- ajoute son id à `area.generatedPlacementIds` ;
- préserve les autres ids générés ;
- préserve placements manuels ;
- préserve placements d’autres areas ;
- préserve mask / seed / paramsOverride / presetId.

## 6. Notifier / mode

Méthodes ajoutées :
- `selectEnvironmentGeneratedPlacementElementForActiveTileLayer(String elementId)`
- `startAddingGeneratedEnvironmentPlacementForActiveTileLayer()`
- `stopAddingGeneratedEnvironmentPlacement()`
- `addGeneratedEnvironmentPlacementAtForActiveTileLayer(GridPos pos)`

État editor-only ajouté :
- `environmentGeneratedPlacementAddElementProvider`
- stocke `String? selectedElementId`
- ne mute pas `MapData`.

Comportements :
- `select` valide l’élément dans la palette active et le manifest, garde le TileLayer actif, ne mute pas la map ;
- `start` exige une area déjà générée, sélection explicite ou implicite, puis active `EnvironmentMaskEditMode.generatedAdd` ;
- `stop` remet `environmentMaskEditMode` à `null` ;
- `add at` exige le mode actif, appelle le use case, applique une seule mutation map, garde le mode ajout actif.

Impacts :
- `activeLayerId` reste le TileLayer ;
- `selectedEnvironmentAreaId` reste stable ;
- paint / erase / delete sont exclus par le mode unique `environmentMaskEditMode` ;
- `statusMessage` annonce la sélection, le démarrage, l’arrêt ou l’ajout ;
- `errorMessage` reste discret sur position invalide.

## 7. Canvas routing

`MapCanvas` n’a pas été modifié.

Raison :
- le routing existant appelle déjà `notifier.addGeneratedEnvironmentPlacementAt(gridPos)` quand `environmentMaskEditMode == EnvironmentMaskEditMode.generatedAdd`.

Adaptation effectuée :
- `EditorNotifier.addGeneratedEnvironmentPlacementAt(GridPos pos)` délègue maintenant au flow TileLayer-centric si le layer actif est un `TileLayer`.

Comportements testés :
- tap valide : ajoute un placement généré à l’area sélectionnée ;
- tap avec footprint hors bounds : ne mute pas `MapData` ;
- `activeLayerId`, `selectedEnvironmentAreaId` et mode ajout restent stables.
- complément suppression demandé par l’utilisateur : hover sur placement généré fournit l’id au painter, puis hover sur manuel remet la preview à `null`.

## 8. Intégration UI

Dans `TileLayerEnvironmentInspectorSection` :
- ajout de la section “Palette du preset” ;
- affichage “Élément à ajouter” ;
- affichage du nom élément si disponible ;
- fallback `Introuvable (<elementId>)` si l’élément est absent du manifest ;
- ajout du bouton “Ajouter un élément généré” ;
- ajout de l’état “Ajout actif” ;
- ajout du bouton “Arrêter l’ajout”.

Dans `MapInspectorPanel` :
- lecture de `environmentGeneratedPlacementAddElementProvider` ;
- passage de la sélection au read model builder ;
- callbacks TileLayer-centric passés seulement si le contexte est valide ;
- démarrage de l’ajout uniquement si `readModel.canAddGeneratedPlacement == true`.

Distinction UX :
- “Ajouter un élément généré” ajoute un seul élément environnemental issu du preset ;
- “Supprimer un élément généré” reste l’action individuelle du Lot 44 ;
- “Effacer les placements générés” reste l’action globale.

Complément demandé par l’utilisateur après livraison :
- en mode “Supprimer un élément généré”, le canvas met maintenant en surbrillance l’élément généré qui sera retiré au clic ;
- le painter savait déjà dessiner l’indice rouge via `environmentGeneratedDeletePreviewId` ;
- la correction porte sur `resolveEnvironmentGeneratedPlacementDeleteTarget`, qui sait maintenant partir d’un TileLayer actif pour retrouver l’EnvironmentLayer attaché.

## 9. Tests

Commande RED use case :

```bash
cd packages/map_editor
dart format test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart && flutter test test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart
```

Résultat RED exact utile :

```text
Error: Method not found: 'AddTileLayerEnvironmentGeneratedPlacementAtUseCase'.
```

Commande RED widget :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat RED exact utile :

```text
test/environment_studio/tile_layer_environment_inspector_section_test.dart:1559:37: Error: Method not found: '_paletteItems'.
test/environment_studio/tile_layer_environment_inspector_section_test.dart:1594:9: Error: No named parameter with the name 'onSelectGeneratedPlacementElement'.
test/environment_studio/tile_layer_environment_inspector_section_test.dart:1625:9: Error: No named parameter with the name 'onStartAddGeneratedPlacement'.
test/environment_studio/tile_layer_environment_inspector_section_test.dart:1719:9: Error: No named parameter with the name 'isAddingGeneratedPlacement'.
00:00 +0 -1: Some tests failed.
```

Commandes GREEN ciblées :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart
00:00 +0: AddTileLayerEnvironmentGeneratedPlacementAtUseCase ajoute un placement généré à une position valide
00:00 +1: AddTileLayerEnvironmentGeneratedPlacementAtUseCase génère un id suffixé si l’id stable est déjà utilisé
00:00 +2: AddTileLayerEnvironmentGeneratedPlacementAtUseCase refuse les entrées et positions invalides sans mutation
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_add_notifier_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_notifier_test.dart
00:00 +0: EditorNotifier TileLayer individual generated placement add sélection élément garde TileLayer actif et ne mute pas la MapData
00:00 +1: EditorNotifier TileLayer individual generated placement add start et stop add mode gardent TileLayer et area
00:00 +2: EditorNotifier TileLayer individual generated placement add add at ajoute un placement généré et garde le mode actif
00:00 +3: EditorNotifier TileLayer individual generated placement add position invalide ne mute pas la MapData et garde le mode actif
00:00 +4: EditorNotifier TileLayer individual generated placement add refuse sans TileLayer actif, sans area, ou sans élément sélectionné
00:00 +5: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart
00:00 +0: tap canvas ajoute un placement généré au TileLayer actif
00:00 +1: tap canvas avec footprint invalide ne mute pas la MapData
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
00:01 +43: TileLayerEnvironmentInspectorSection affiche Palette du preset et les éléments disponibles
00:01 +44: TileLayerEnvironmentInspectorSection sélection d’un élément généré déclenche le callback
00:01 +45: TileLayerEnvironmentInspectorSection Ajouter un élément généré désactivé sans generated placements
00:01 +46: TileLayerEnvironmentInspectorSection Ajouter un élément généré désactivé sans sélection quand plusieurs items
00:01 +47: TileLayerEnvironmentInspectorSection Ajouter un élément généré actif avec élément sélectionné
00:01 +48: TileLayerEnvironmentInspectorSection mode ajout actif affiche stop et aide
00:01 +53: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
00:00 +26: TileLayerEnvironmentAttachmentReadModel expose la palette du preset avec la sélection et les éléments manquants
00:00 +27: TileLayerEnvironmentAttachmentReadModel désactive l’ajout individuel si tous les éléments sont manquants
00:00 +29: All tests passed!
```

Non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generated_placements_clear_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generated_placements_clear_test.dart
00:00 +10: EditorNotifier.clearEnvironmentGeneratedPlacements addGeneratedEnvironmentPlacementAt ajoute un placement individuel du preset
[editor][environment] added generated placement by click id=env_gen_a1_1_1_tree elementId=tree pos=(1,1)
00:01 +14: All tests passed!
```

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
00:00 +1: hover canvas met en surbrillance le placement supprimable
00:00 +2: tap canvas sur placement manuel ne supprime rien
00:00 +3: All tests passed!
```

Complément demandé par l’utilisateur, surbrillance hover suppression :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generated_placement_hover_preview_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
00:00 +0: Environment generated placement hover preview resolves the generated placement that would be added by a click
00:00 +1: Environment generated placement hover preview does not preview add when the element footprint leaves the map
00:00 +2: Environment generated placement hover preview resolves the topmost generated placement that delete would remove
00:00 +3: Environment generated placement hover preview resolves delete target from active TileLayer attachment
00:00 +4: All tests passed!
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

Complément MapInspectorPanel :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_generate_button_wiring_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_generate_button_wiring_test.dart
00:01 +13: All tests passed!
```

## 10. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart lib/src/features/editor/state/environment_generated_placement_add_element_provider.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart test/environment_studio/tile_layer_environment_individual_add_notifier_test.dart test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat :

```text
Analyzing 13 items...
No issues found! (ran in 3.1s)
```

Analyse complémentaire pour la surbrillance suppression demandée par l’utilisateur :

```bash
cd packages/map_editor
flutter analyze lib/src/application/services/environment_generated_placement_hover_resolver.dart test/environment_studio/environment_generated_placement_hover_preview_test.dart test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
```

```text
Analyzing 3 items...
No issues found! (ran in 1.5s)
```

Dettes préexistantes hors lot :
- aucune dette bloquante observée dans les commandes ciblées.

Problèmes introduits par ce lot :
- aucun problème connu après les tests et l’analyse ciblée.

## 11. Fichiers créés/modifiés

Fichiers déjà présents/modifiés avant Environment-45 :
- aucun. Le `git status --short --untracked-files=all` initial n’a produit aucune ligne.

Fichiers créés par Environment-45 :
- `packages/map_editor/lib/src/features/editor/state/environment_generated_placement_add_element_provider.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_notifier_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart`
- `reports/environment_studio/environment_45_tile_layer_individual_generated_placement_add.md`

Fichiers modifiés par Environment-45 :
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart` (complément demandé par l’utilisateur : surbrillance suppression)
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart` (complément demandé par l’utilisateur)
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart` (complément demandé par l’utilisateur)
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fichiers préexistants dans le worktree non touchés :
- aucun fichier sale préexistant.

## 12. Non-objectifs respectés

- Pas de suppression individuelle nouvelle.
- Pas de génération complète.
- Pas de clear global.
- Pas de regenerate/shuffle.
- Pas de preview de génération ou d’ajout ; seule une surbrillance de suppression a été ajoutée sur demande explicite de l’utilisateur.
- Pas de modification du mask.
- Pas de modification des params locaux.
- Pas de modification du preset global.
- Pas de création/suppression/renommage d’area.
- Pas de modification `map_core`.
- Pas de modification runtime.
- Pas de modification gameplay.
- Pas de modification battle.
- Pas de build_runner.
- Pas de generated files.

## 13. Evidence pack

### git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
```

### git diff --stat

Commande :

```bash
git diff --stat
```

Résultat exact :

```text
 ...le_layer_environment_attachment_read_model.dart |  22 ++
 ...ronment_generated_placement_hover_resolver.dart |  22 +-
 ..._environment_attachment_read_model_builder.dart |  88 +++++++
 ...ronment_generated_placement_edit_use_cases.dart | 258 ++++++++++++++++++++
 .../src/features/editor/state/editor_notifier.dart | 243 +++++++++++++++++++
 .../lib/src/ui/panels/map_inspector_panel.dart     |  38 ++-
 .../tile_layer_environment_inspector_section.dart  | 263 ++++++++++++++++++++-
 ...ent_generated_placement_hover_preview_test.dart |  38 +++
 ...yer_environment_attachment_read_model_test.dart |  88 +++++++
 ..._environment_individual_delete_canvas_test.dart |  43 ++++
 ...e_layer_environment_inspector_section_test.dart | 237 +++++++++++++++++++
 11 files changed, 1333 insertions(+), 7 deletions(-)
```

Note factuelle : `git diff --stat` ne liste pas les fichiers non suivis. Les fichiers créés par Environment-45 apparaissent dans `git status` final.

### git diff --name-only

Commande :

```bash
git diff --name-only
```

Résultat exact :

```text
packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart
packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

### git diff --check

Commande :

```bash
git diff --check
```

Résultat exact :

```text
```

### git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
 M packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart
 M packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
 M packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
 M packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/lib/src/features/editor/state/environment_generated_placement_add_element_provider.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_notifier_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart
?? reports/environment_studio/environment_45_tile_layer_individual_generated_placement_add.md
```

## 14. Diff pertinent

### Read model

```diff
+final class TileLayerEnvironmentPaletteItemSummary {
+  const TileLayerEnvironmentPaletteItemSummary({
+    required this.elementId,
+    required this.elementName,
+    required this.weight,
+    required this.collisionMode,
+    required this.hasMissingElement,
+    required this.isSelected,
+  });
+  ...
+}
...
+    this.canAddGeneratedPlacement = false,
+    this.selectedAreaPaletteItems = const [],
...
+  final bool canAddGeneratedPlacement;
+  final List<TileLayerEnvironmentPaletteItemSummary> selectedAreaPaletteItems;
```

### Read model builder

```diff
 TileLayerEnvironmentAttachmentReadModel buildTileLayerEnvironmentAttachmentReadModel({
   required ProjectManifest? manifest,
   required MapData? map,
   required String? selectedLayerId,
   required String? selectedEnvironmentAreaId,
+  String? selectedGeneratedPlacementElementId,
 }) {
...
+  final selectedPaletteItems = preset == null
+      ? const <TileLayerEnvironmentPaletteItemSummary>[]
+      : _buildPaletteSummaries(
+          manifest: manifest,
+          preset: preset,
+          selectedGeneratedPlacementElementId:
+              selectedGeneratedPlacementElementId,
+        );
+  final canAddGeneratedPlacement = generatedPlacementCount > 0 &&
+      _hasSelectablePaletteItem(selectedPaletteItems);
...
+List<TileLayerEnvironmentPaletteItemSummary> _buildPaletteSummaries({...})
+TileLayerEnvironmentPaletteItemSummary _paletteSummary({...})
+bool _hasSelectablePaletteItem(List<TileLayerEnvironmentPaletteItemSummary> items)
```

### Use case

```diff
+final class AddTileLayerEnvironmentGeneratedPlacementResult {
+  const AddTileLayerEnvironmentGeneratedPlacementResult({
+    required this.map,
+    required this.tileLayerId,
+    required this.environmentLayerId,
+    required this.areaId,
+    required this.addedPlacementId,
+  });
+  ...
+}
+
+class AddTileLayerEnvironmentGeneratedPlacementAtUseCase {
+  AddTileLayerEnvironmentGeneratedPlacementResult execute(
+    MapData map, {
+    required ProjectManifest manifest,
+    required String tileLayerId,
+    required String areaId,
+    required String elementId,
+    required GridPos pos,
+  }) {
+    final target = _resolveTarget(map, tileLayerId: tileLayerId, areaId: areaId);
+    if (target.area.generatedPlacementIds.isEmpty) {
+      throw const EditorValidationException(
+        'Generate the environment area before adding individual placements',
+      );
+    }
+    ...
+    final placed = MapPlacedElement(
+      id: placedId,
+      layerId: target.tileLayer.id,
+      elementId: paletteItem.elementId,
+      pos: pos,
+      applyCollision: _applyCollisionFromEnvironmentMode(
+        paletteItem.collisionMode,
+      ),
+    );
+    final updated = _addGeneratedPlacement(...);
+    MapValidator.validate(updated, projectDialogueContext: manifest);
+    return AddTileLayerEnvironmentGeneratedPlacementResult(...);
+  }
+}
```

```diff
+String _uniqueGeneratedEnvironmentPlacementId(
+  MapData map, {
+  required EnvironmentArea area,
+  required GridPos pos,
+  required String elementId,
+}) {
+  final baseId = generatedEnvironmentPlacementId(
+    areaId: area.id,
+    pos: pos,
+    elementId: elementId,
+  );
+  final usedIds = {
+    ...area.generatedPlacementIds,
+    for (final placed in map.placedElements) placed.id,
+  };
+  if (!usedIds.contains(baseId)) return baseId;
+  var suffix = 2;
+  while (usedIds.contains('${baseId}_$suffix')) {
+    suffix++;
+  }
+  return '${baseId}_$suffix';
+}
```

### Provider créé

Contenu complet :

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final environmentGeneratedPlacementAddElementProvider = StateProvider<String?>(
  (ref) => null,
);
```

### Notifier

```diff
+  void selectEnvironmentGeneratedPlacementElementForActiveTileLayer(
+    String elementId,
+  ) { ... }
+
+  void startAddingGeneratedEnvironmentPlacementForActiveTileLayer() { ... }
+
+  void stopAddingGeneratedEnvironmentPlacement() { ... }
+
+  bool addGeneratedEnvironmentPlacementAtForActiveTileLayer(GridPos pos) {
+    final map = state.activeMap;
+    if (map == null) {
+      return false;
+    }
+    if (state.environmentMaskEditMode != EnvironmentMaskEditMode.generatedAdd) {
+      state = state.copyWith(
+        errorMessage: 'Activez l’ajout d’un élément généré avant de cliquer.',
+      );
+      return false;
+    }
+    ...
+    _applyMapMutation(
+      previousMap: map,
+      updatedMap: result.map,
+      preferredActiveLayerId: result.tileLayerId,
+      statusMessage: 'Élément généré ajouté.',
+    );
+    state = state.copyWith(
+      activeLayerId: result.tileLayerId,
+      selectedEnvironmentAreaId: result.areaId,
+      environmentMaskEditMode: EnvironmentMaskEditMode.generatedAdd,
+      errorMessage: null,
+    );
+    return true;
+  }
```

```diff
   bool addGeneratedEnvironmentPlacementAt(GridPos pos) {
     ...
     final activeLayer = _findLayerById(map, activeLayerId);
+    if (activeLayer is TileLayer) {
+      return addGeneratedEnvironmentPlacementAtForActiveTileLayer(pos);
+    }
     if (activeLayer is! EnvironmentLayer) {
       return false;
    }
```

### Surbrillance suppression demandée par l’utilisateur

```diff
 EnvironmentGeneratedPlacementDeleteTarget?
     resolveEnvironmentGeneratedPlacementDeleteTarget({
   required MapData map,
   required ProjectManifest? manifest,
   required String? activeLayerId,
   required String? selectedAreaId,
   required GridPos pos,
 }) {
-  final envLayer = _activeEnvironmentLayer(map, activeLayerId);
+  final envLayer = _activeOrAttachedEnvironmentLayer(map, activeLayerId);
   if (envLayer == null) return null;
```

```diff
+EnvironmentLayer? _activeOrAttachedEnvironmentLayer(
+  MapData map,
+  String? activeLayerId,
+) {
+  final layerId = activeLayerId?.trim();
+  if (layerId == null || layerId.isEmpty) return null;
+  for (final layer in map.layers) {
+    if (layer.id == layerId && layer is EnvironmentLayer) {
+      return layer;
+    }
+  }
+  for (final layer in map.layers) {
+    if (layer is EnvironmentLayer &&
+        layer.content.targetTileLayerId?.trim() == layerId) {
+      return layer;
+    }
+  }
+  return null;
+}
```

```diff
+    test('resolves delete target from active TileLayer attachment', () {
+      final ctx = _previewContext();
+      final map = ctx.map.copyWith(
+        placedElements: const [
+          MapPlacedElement(
+            id: 'manual_tree',
+            layerId: 'tiles',
+            elementId: 'tree_large',
+            pos: GridPos(x: 2, y: 2),
+          ),
+          MapPlacedElement(
+            id: 'generated_bottom',
+            layerId: 'tiles',
+            elementId: 'tree_large',
+            pos: GridPos(x: 1, y: 1),
+          ),
+          MapPlacedElement(
+            id: 'generated_top',
+            layerId: 'tiles',
+            elementId: 'tree_large',
+            pos: GridPos(x: 2, y: 2),
+          ),
+        ],
+      );
+
+      final target = resolveEnvironmentGeneratedPlacementDeleteTarget(
+        map: map,
+        manifest: ctx.manifest,
+        activeLayerId: 'tiles',
+        selectedAreaId: 'area one',
+        pos: const GridPos(x: 2, y: 2),
+      );
+
+      expect(target, isNotNull);
+      expect(target!.placed.id, 'generated_top');
+      expect(target.element?.id, 'tree_large');
+    });
```

```diff
+  testWidgets('hover canvas met en surbrillance le placement supprimable',
+      (tester) async {
+    ...
+    final customPaint = tester.widget<CustomPaint>(
+      find.byWidgetPredicate(
+        (widget) =>
+            widget is CustomPaint && widget.painter is MapGridPainter,
+      ),
+    );
+    final painter = customPaint.painter as MapGridPainter;
+    expect(painter.environmentGeneratedDeletePreviewId, 'generated');
+    ...
+    final manualHoverPainter = manualHoverPaint.painter as MapGridPainter;
+    expect(manualHoverPainter.environmentGeneratedDeletePreviewId, isNull);
+  });
```

### MapInspectorPanel

```diff
+import '../../features/editor/state/environment_generated_placement_add_element_provider.dart';
...
+    final selectedGeneratedPlacementElementId =
+        ref.watch(environmentGeneratedPlacementAddElementProvider);
...
       ? buildTileLayerEnvironmentAttachmentReadModel(
           manifest: state.project,
           map: activeMap,
           selectedLayerId: state.activeLayerId,
           selectedEnvironmentAreaId: state.selectedEnvironmentAreaId,
+          selectedGeneratedPlacementElementId:
+              selectedGeneratedPlacementElementId,
         )
...
+    final isTileLayerGeneratedPlacementAddActive = activeLayer is TileLayer &&
+        tileLayerEnvironmentReadModel != null &&
+        state.environmentMaskEditMode == EnvironmentMaskEditMode.generatedAdd &&
+        effectiveTileLayerEnvironmentAreaId != null;
...
+    final canStartTileLayerGeneratedPlacementAdd = activeLayer is TileLayer &&
+        tileLayerEnvironmentReadModel != null &&
+        tileLayerEnvironmentReadModel.canAddGeneratedPlacement &&
+        !tileLayerEnvironmentReadModel.hasErrors &&
+        effectiveTileLayerEnvironmentAreaId != null &&
+        !isTileLayerEnvironmentActionActive;
```

### TileLayerEnvironmentInspectorSection

```diff
+    this.isAddingGeneratedPlacement = false,
+    this.onSelectGeneratedPlacementElement,
+    this.onStartAddGeneratedPlacement,
+    this.onStopAddGeneratedPlacement,
...
+  final bool isAddingGeneratedPlacement;
+  final ValueChanged<String>? onSelectGeneratedPlacementElement;
+  final VoidCallback? onStartAddGeneratedPlacement;
+  final VoidCallback? onStopAddGeneratedPlacement;
```

```diff
+          if (isAddingGeneratedPlacement) ...[
+            const SizedBox(height: 12),
+            const _ActiveGeneratedPlacementAddBanner(),
+          ],
...
+          if (_shouldShowGeneratedPlacementPalette(readModel)) ...[
+            const SizedBox(height: 12),
+            _GeneratedPlacementPaletteSection(
+              items: readModel.selectedAreaPaletteItems,
+              onSelectGeneratedPlacementElement:
+                  onSelectGeneratedPlacementElement,
+            ),
+          ],
```

```diff
+class _ActiveGeneratedPlacementAddBanner extends StatelessWidget {
+  const _ActiveGeneratedPlacementAddBanner();
+  ...
+          Text('Ajout actif', ...)
+          Text(
+            'Cliquez sur la carte pour ajouter cet élément à cette zone.',
+            ...
+          ),
+}
```

```diff
+class _GeneratedPlacementPaletteSection extends StatelessWidget { ... }
+class _GeneratedPlacementPaletteItemChip extends StatelessWidget { ... }
```

```diff
+    if (!isEnvironmentActionActive &&
+        (readModel.hasGeneratedPlacements ||
+            readModel.canPaintMask ||
+            readModel.selectedAreaPaletteItems.isNotEmpty)) {
+      actions.add(
+        _ActionData(
+          icon: CupertinoIcons.plus_circle,
+          label: 'Ajouter un élément généré',
+          enabled: readModel.canAddGeneratedPlacement &&
+              !readModel.hasErrors &&
+              onStartAddGeneratedPlacement != null,
+          onPressed: readModel.canAddGeneratedPlacement
+              ? onStartAddGeneratedPlacement
+              : null,
+        ),
+      );
+    }
```

### Tests créés

Les trois nouveaux fichiers de tests contiennent des fixtures map/manifest complètes. Les scénarios couverts par leur code sont :

`tile_layer_environment_individual_add_use_case_test.dart` :
- ajoute un placement généré à une position valide ;
- ajoute l’id dans `generatedPlacementIds` ;
- vérifie `layerId`, `elementId`, `pos` ;
- préserve autres ids, placements manuels, placements autre area, mask, paramsOverride, seed, presetId ;
- génère un suffixe d’id si conflit ;
- refuse area jamais générée ;
- refuse élément absent de la palette ;
- refuse élément absent du manifest ;
- refuse position hors map ;
- refuse footprint hors map ;
- refuse tileLayer vide/introuvable/non TileLayer ;
- refuse absence d’EnvironmentLayer attaché ;
- refuse area vide/introuvable.

`tile_layer_environment_individual_add_notifier_test.dart` :
- sélection d’élément sans mutation `MapData` ;
- start/stop du mode ajout ;
- stoppe delete/paint/erase via mode unique ;
- add at ajoute et garde mode actif ;
- position invalide sans mutation ;
- erreurs sans TileLayer, sans area, sans élément sélectionné.

`tile_layer_environment_individual_add_canvas_test.dart` :
- tap canvas valide ajoute `env_gen_area_1_1_tree` ;
- TileLayer et area restent stables ;
- mode `generatedAdd` reste actif ;
- tap avec footprint invalide ne mute pas `MapData`.

## 15. Auto-review

- L’ajout individuel cible-t-il uniquement l’area sélectionnée ? Oui.
- L’élément ajouté doit-il appartenir à la palette du preset ? Oui.
- L’élément ajouté doit-il exister dans le manifest ? Oui.
- Le footprint bounds est-il validé ? Oui.
- Le MapPlacedElement est-il créé ? Oui.
- L’id est-il ajouté à generatedPlacementIds ? Oui.
- Les placements manuels sont-ils préservés ? Oui.
- Les placements générés d’autres areas sont-ils préservés ? Oui.
- mask / seed / paramsOverride / presetId sont-ils préservés ? Oui.
- activeLayerId reste-t-il le TileLayer ? Oui.
- selectedEnvironmentAreaId reste-t-il stable ? Oui.
- Le mode ajout est-il activable/désactivable ? Oui.
- Le clic invalide ne mute-t-il pas MapData ? Oui.
- La surbrillance suppression demandée par l’utilisateur cible-t-elle le placement qui serait supprimé ? Oui, via `environmentGeneratedDeletePreviewId`.
- Le flow legacy reste-t-il intact ? Oui, le mode legacy EnvironmentLayer continue d’utiliser son chemin existant.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 16. Critique du prompt et du lot

Clair :
- la contrainte “fine-tuning après génération” était nette ;
- la source de vérité TileLayer → EnvironmentLayer attaché → area sélectionnée était claire ;
- la séparation avec ajout manuel classique était claire.

Ambigu :
- le prompt mentionnait une palette potentiellement vide, mais `EnvironmentPreset` refuse une palette vide. Le test couvre donc le cas utile “palette présente mais tous les éléments manquent”.
- le read model ne filtre pas par compatibilité tileset ; la validation stricte reste dans le notifier/use case au moment de sélectionner/d’ajouter.

À trancher avant Environment-46 :
- si les `EnvironmentLayer` techniques doivent être masqués, regroupés ou affichés comme sous-objets du TileLayer ;
- si la palette d’ajout doit rester visible avant première génération ou seulement après génération.

## 17. Verdict

```text
Environment-45 livré
Complément utilisateur surbrillance suppression : livré
Code produit modifié : oui
Code UI/canvas modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-46 — Hide / Group Technical EnvironmentLayer V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté l’ajout individuel Environment-45 et, après demande utilisateur, uniquement la surbrillance suppression.
- [x] Je n’ai pas ajouté de nouvelle suppression individuelle.
- [x] Je n’ai pas lancé de génération complète.
- [x] Je n’ai pas ajouté de preview de génération ou d’ajout.
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

## Note post-livraison

Après la livraison et le complément de surbrillance demandé par l’utilisateur,
l’utilisateur a demandé explicitement un commit. Les lignes de checklist
relatives à l’absence de commit décrivent donc la livraison avant cette demande
explicite.
