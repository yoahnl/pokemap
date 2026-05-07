# Environment-37 — TileLayer Environment Brush Cursor Overlay V0

## 1. Résumé

Ajout d’un overlay visuel de cursor brush sur le canvas du Map Editor.

Le lot ajoute :
- un helper pur `resolveEnvironmentMaskBrushFootprint` pour calculer les cellules couvertes par une brush carrée 1 / 3 / 5 / 7 ;
- la réutilisation de ce helper par la vraie peinture du masque ;
- un objet `EnvironmentMaskBrushCursorOverlay` passé à `MapGridPainter` ;
- un rendu visuel distinct pour paint et erase ;
- le wiring dans `MapCanvas` pour afficher l’overlay uniquement lorsque `environmentMaskEditMode` est `paint` ou `erase` et qu’une cible valide existe ;
- deux tests ciblés : footprint pur et painter overlay.

Le lot reste strictement visuel côté hover : aucun hover ne mute `MapData`.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets / recettes d’environnement.
- Map Editor / TileLayer inspector devient le lieu de peinture et génération.
- Ce lot ajoute seulement un overlay de cursor brush.
- Pas de génération ni preview de placements dans ce lot.

## 3. Audit de l’existant

Fichiers inspectés :
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/environment_mask_brush_size_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_brush_size_state_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_erase_mode_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart`
- `packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart`
- `packages/map_editor/test/map_grid_painter_test.dart`

Fonctionnement actuel de brush size :
- la taille de brush est portée par `environmentMaskBrushSizeProvider` ;
- les tailles autorisées sont `1`, `3`, `5`, `7` ;
- `PaintEnvironmentAreaMaskBrushStrokeUseCase` appliquait déjà paint/erase en carré, mais son calcul de footprint était local au use case.

Fonctionnement actuel du canvas hover / pointer :
- `MapCanvas` stocke déjà une cellule `_hoveredTile` locale et transient ;
- `_onMapPointerHover` convertit la position écran en `GridPos` via `_screenToGrid` ;
- `MouseRegion.onExit` remet `_hoveredTile` à `null` ;
- le hover existant n’appelle pas `paintEnvironmentAreaMaskAt`.

Fonctionnement actuel du mask overlay :
- `MapCanvas` résout `environmentMaskOverlay` uniquement si `environmentMaskEditMode` est `paint` ou `erase` et si `resolveEnvironmentMaskPaintTarget` retourne une cible valide ;
- `MapGridPainter._paintEnvironmentMaskOverlay` dessine les cellules actives du masque en vert semi-transparent.

Décision retenue pour l’overlay cursor :
- réutiliser `_hoveredTile` comme état hover local ;
- ne pas ajouter de champ dans `EditorState`, `MapData` ou `ProjectManifest` ;
- créer un helper pur de footprint partagé par use case et painter ;
- supprimer le hover single-cell générique quand l’overlay brush est actif, pour éviter deux previews superposées.

## 4. Footprint de brush

Helper ajouté :
- `packages/map_editor/lib/src/application/services/environment_mask_brush_footprint_resolver.dart`
- fonction `resolveEnvironmentMaskBrushFootprint`
- résultat `EnvironmentMaskBrushFootprint`

Entrées :
- `GridSize mapSize`
- `GridPos center`
- `int brushSize`

Sorties :
- `EnvironmentMaskBrushFootprint.cells`, liste stable de `GridPos`
- `isEmpty` pour les centres hors map ou tailles de map invalides

Règles :
- tailles autorisées : `1`, `3`, `5`, `7`
- tailles invalides : `EditorValidationException`
- `radius = (brushSize - 1) ~/ 2`
- carré centré sur la cellule hover/clic
- clipping aux bords de map
- centre hors map : footprint vide
- ordre stable : row-major, de `minY` à `maxY`, puis de `minX` à `maxX`

Réutilisation :
- `PaintEnvironmentAreaMaskBrushStrokeUseCase` utilise maintenant le helper pour appliquer la vraie peinture/effacement ;
- `MapGridPainter` utilise le même helper pour dessiner l’overlay.

## 5. Canvas hover state

L’état hover reste local à `MapCanvas` :
- champ existant : `_hoveredTile`
- mise à jour : `_onMapPointerHover`
- clear : `MouseRegion.onExit`
- aucune écriture dans `MapData`
- aucune écriture dans `EditorState`
- aucune modification de `activeLayerId`, `selectedEnvironmentAreaId`, `environmentMaskEditMode` ou brush size

L’overlay est construit seulement si :
- `environmentMaskEditMode` est `paint` ou `erase` ;
- `resolveEnvironmentMaskPaintTarget` retourne une cible valide ;
- `_hoveredTile` n’est pas `null`.

## 6. Painter / overlay

Données passées au painter :
- `EnvironmentMaskBrushCursorOverlay.center`
- `EnvironmentMaskBrushCursorOverlay.brushSize`
- `EnvironmentMaskBrushCursorOverlay.mode`

Rendu paint :
- fill cyan semi-transparent `0x6626C6DA`
- border cyan clair `0xFF80DEEA`

Rendu erase :
- fill orange semi-transparent `0x66FF7043`
- border orange clair `0xFFFFB199`

Comportement aux bords :
- le painter appelle `resolveEnvironmentMaskBrushFootprint` ;
- les cellules hors bounds ne sont jamais dessinées ;
- size 5 au bord est couvert par test no-throw et par test footprint.

Compatibilité :
- le flow TileLayer-centric garde `activeLayerId = TileLayer.id` et utilise le resolver existant ;
- le flow legacy `EnvironmentLayer` reste compatible car le même resolver `resolveEnvironmentMaskPaintTarget` continue d’autoriser les deux cas ;
- `MapCanvas` n’a pas changé le routing paint/erase réel.

## 7. Tests

Tests RED ajoutés avant implémentation :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_mask_brush_footprint_resolver_test.dart
```

Résultat RED :

```text
Error when reading 'lib/src/application/services/environment_mask_brush_footprint_resolver.dart': No such file or directory
Method not found: 'resolveEnvironmentMaskBrushFootprint'
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_brush_cursor_overlay_test.dart
```

Résultat RED :

```text
Type 'EnvironmentMaskBrushCursorOverlay' not found
Couldn't find constructor 'EnvironmentMaskBrushCursorOverlay'
No named parameter with the name 'environmentBrushCursorOverlay'
```

Tests GREEN lancés après implémentation :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_mask_brush_footprint_resolver_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_mask_brush_footprint_resolver_test.dart
00:00 +0: resolveEnvironmentMaskBrushFootprint size 1 retourne exactement la cellule centrale
00:00 +1: resolveEnvironmentMaskBrushFootprint size 3 retourne un carré 3x3 stable en ordre row-major
00:00 +2: resolveEnvironmentMaskBrushFootprint size 5 retourne un carré 5x5 stable
00:00 +3: resolveEnvironmentMaskBrushFootprint size 7 retourne un carré 7x7 stable
00:00 +4: resolveEnvironmentMaskBrushFootprint bord de map clippe correctement
00:00 +5: resolveEnvironmentMaskBrushFootprint centre hors map retourne vide
00:00 +6: resolveEnvironmentMaskBrushFootprint tailles invalides refusées
00:00 +7: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_brush_cursor_overlay_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_brush_cursor_overlay_test.dart
00:00 +0: Environment brush cursor overlay MapGridPainter ne lève pas avec un overlay paint
00:00 +1: Environment brush cursor overlay MapGridPainter ne lève pas avec un overlay erase
00:00 +2: Environment brush cursor overlay MapGridPainter ne lève pas avec size 5 au bord de map
00:00 +3: Environment brush cursor overlay MapGridPainter ne lève pas avec overlay null
00:00 +4: Environment brush cursor overlay shouldRepaint distingue paint et erase
00:00 +5: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_mask_brush_size_use_case_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_mask_brush_size_use_case_test.dart
00:00 +0: PaintEnvironmentAreaMaskBrushStrokeUseCase brush size 1 peint exactement la cellule centrale
00:00 +1: PaintEnvironmentAreaMaskBrushStrokeUseCase brush size 3 peint un carré 3x3
00:00 +2: PaintEnvironmentAreaMaskBrushStrokeUseCase brush size 5 peint un carré 5x5
00:00 +3: PaintEnvironmentAreaMaskBrushStrokeUseCase brush size 7 peint un carré 7x7
00:00 +4: PaintEnvironmentAreaMaskBrushStrokeUseCase brush en bord de map clippe correctement
00:00 +5: PaintEnvironmentAreaMaskBrushStrokeUseCase brush hors map ne crash pas et ne peint rien
00:00 +6: PaintEnvironmentAreaMaskBrushStrokeUseCase erase avec size 3 remet les cellules à false
00:00 +7: PaintEnvironmentAreaMaskBrushStrokeUseCase refuse brush size invalide
00:00 +8: PaintEnvironmentAreaMaskBrushStrokeUseCase préserve les autres areas layers et placedElements
00:00 +9: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
00:00 +0: tap canvas peint le masque attaché quand le TileLayer est actif
00:00 +1: tap canvas peint un carré 3x3 avec brush size 3
00:00 +2: tap canvas efface un carré 3x3 avec brush size 3
00:00 +3: tap canvas erase taille 1 efface exactement la cellule centrale
00:00 +4: All tests passed!
```

Non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_erase_mode_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_erase_mode_test.dart
00:00 +0: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer active le mode erase sans changer le TileLayer sélectionné
00:00 +1: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer stop remet le mode à null et garde la zone active
00:00 +2: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer refuse si aucun TileLayer actif
00:00 +3: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer refuse si aucun EnvironmentLayer attaché
00:00 +4: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer refuse si aucune area est sélectionnée
00:00 +5: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer refuse si area sélectionnée introuvable
00:00 +6: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_brush_size_state_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_brush_size_state_test.dart
00:00 +0: Environment mask brush size state taille par défaut = 1
00:00 +1: Environment mask brush size state setEnvironmentMaskBrushSize change la taille
00:00 +2: Environment mask brush size state taille invalide ne change pas l’état et affiche une erreur
00:00 +3: Environment mask brush size state changer la taille ne mute pas MapData ni les sélections
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_layer_mask_brush_tool_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_layer_mask_brush_tool_test.dart
00:00 +0: Lot 22 — PaintEnvironmentAreaMaskCellUseCase paint (1,1) : une cellule active, preset et placements préservés
00:00 +1: Lot 22 — PaintEnvironmentAreaMaskCellUseCase erase : cellule repasse false, compteur diminue
00:00 +2: Lot 22 — PaintEnvironmentAreaMaskCellUseCase no-op paint true sur true → même référence MapData
00:00 +3: Lot 22 — PaintEnvironmentAreaMaskCellUseCase no-op erase false sur false → même référence MapData
00:00 +4: Lot 22 — PaintEnvironmentAreaMaskCellUseCase erreurs use case
00:00 +5: Lot 22 — EditorNotifier masque start paint / erase / stop + paint met dirty et préserve chemins
00:00 +6: Lot 22 — EditorNotifier masque changer de layer actif hors Environment → mode masque désactivé
00:00 +7: Lot 22 — EditorNotifier masque removeEnvironmentArea nettoie la sélection masque
00:00 +8: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +9: Lot 22 — MapCanvas tap masque tap peint une cellule du masque
00:01 +10: Lot 22 — MapCanvas tap masque mode erase + tap efface la cellule
00:01 +11: Lot 22 — MapCanvas tap masque tap sans mode placement ne supprime pas un arbre généré
00:01 +12: Lot 22 — MapCanvas tap masque mode suppression + tap retire un arbre généré
[editor][environment] deleted generated placement by click id=tree_a elementId=tree pos=(0,0)
00:01 +13: Lot 22 — MapGridPainter overlay masque environmentMaskOverlay actif ne lève pas
00:01 +14: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
00:00 +0: TileLayerEnvironmentAttachmentReadModel retourne un empty state quand le projet est null
00:00 +1: TileLayerEnvironmentAttachmentReadModel retourne un état neutre quand la map est null
00:00 +2: TileLayerEnvironmentAttachmentReadModel retourne un état neutre quand aucun layer est sélectionné
00:00 +3: TileLayerEnvironmentAttachmentReadModel détecte un TileLayer sans environnement attaché
00:00 +4: TileLayerEnvironmentAttachmentReadModel détecte un TileLayer avec EnvironmentLayer attaché
00:00 +5: TileLayerEnvironmentAttachmentReadModel détecte plusieurs EnvironmentLayers attachés au même TileLayer
00:00 +6: TileLayerEnvironmentAttachmentReadModel détecte un EnvironmentLayer sélectionné directement en mode legacy
00:00 +7: TileLayerEnvironmentAttachmentReadModel détecte targetTileLayerId manquant
00:00 +8: TileLayerEnvironmentAttachmentReadModel détecte target layer inexistant
00:00 +9: TileLayerEnvironmentAttachmentReadModel détecte target layer non TileLayer
00:00 +10: TileLayerEnvironmentAttachmentReadModel détecte absence d’area
00:00 +11: TileLayerEnvironmentAttachmentReadModel détecte area sélectionnée valide
00:00 +12: TileLayerEnvironmentAttachmentReadModel détecte area sélectionnée absente
00:00 +13: TileLayerEnvironmentAttachmentReadModel utilise la seule area existante quand aucune sélection est fournie
00:00 +14: TileLayerEnvironmentAttachmentReadModel demande une sélection quand plusieurs areas existent sans sélection
00:00 +15: TileLayerEnvironmentAttachmentReadModel détecte preset valide
00:00 +16: TileLayerEnvironmentAttachmentReadModel détecte preset manquant
00:00 +17: TileLayerEnvironmentAttachmentReadModel détecte masque vide
00:00 +18: TileLayerEnvironmentAttachmentReadModel détecte masque non vide
00:00 +19: TileLayerEnvironmentAttachmentReadModel compte generatedPlacementIds et placements manquants
00:00 +20: TileLayerEnvironmentAttachmentReadModel retourne un état neutre pour un layer non TileLayer
00:00 +21: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
00:00 +0: EnableTileLayerEnvironmentAttachmentUseCase crée un EnvironmentLayer attaché à un TileLayer sans environnement
00:00 +1: EnableTileLayerEnvironmentAttachmentUseCase insère le nouvel EnvironmentLayer juste après le TileLayer ciblé
00:00 +2: EnableTileLayerEnvironmentAttachmentUseCase ne recrée rien si un EnvironmentLayer cible déjà le TileLayer
00:00 +3: EnableTileLayerEnvironmentAttachmentUseCase refuse un layer introuvable
00:00 +4: EnableTileLayerEnvironmentAttachmentUseCase refuse un layer non TileLayer
00:00 +5: EnableTileLayerEnvironmentAttachmentUseCase préserve les autres layers et les placedElements
00:00 +6: EnableTileLayerEnvironmentAttachmentUseCase génère un id unique si un layer environnement porte déjà le base id
00:00 +7: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
00:00 +0: CreateTileLayerEnvironmentAreaUseCase crée une EnvironmentArea dans l’EnvironmentLayer attaché
00:00 +1: CreateTileLayerEnvironmentAreaUseCase génère un id unique et garde un nom lisible
00:00 +2: CreateTileLayerEnvironmentAreaUseCase refuse tileLayerId vide
00:00 +3: CreateTileLayerEnvironmentAreaUseCase refuse TileLayer introuvable
00:00 +4: CreateTileLayerEnvironmentAreaUseCase refuse layer non TileLayer
00:00 +5: CreateTileLayerEnvironmentAreaUseCase refuse absence d’EnvironmentLayer attaché
00:00 +6: CreateTileLayerEnvironmentAreaUseCase refuse presetId vide ou absent du manifest
00:00 +7: CreateTileLayerEnvironmentAreaUseCase préserve les autres layers et les placedElements
00:00 +8: CreateTileLayerEnvironmentAreaUseCase ajoute dans le premier EnvironmentLayer attaché selon l’ordre
00:00 +9: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_notifier_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_area_notifier_test.dart
00:00 +0: EditorNotifier.createEnvironmentAreaForActiveTileLayer crée une area et garde le TileLayer sélectionné
00:00 +1: EditorNotifier.createEnvironmentAreaForActiveTileLayer refuse un preset absent sans créer de zone
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
00:00 +0: TileLayerEnvironmentInspectorSection affiche Aucun environnement sur ce layer
00:00 +1: TileLayerEnvironmentInspectorSection affiche Activer l’environnement sans callback de mutation
00:00 +2: TileLayerEnvironmentInspectorSection active Activer l’environnement avec callback
00:00 +3: TileLayerEnvironmentInspectorSection bloque Ajouter une zone si aucun preset existe
00:00 +4: TileLayerEnvironmentInspectorSection active Ajouter une zone avec un preset unique
00:00 +5: TileLayerEnvironmentInspectorSection bloque Ajouter une zone avec plusieurs presets sans sélection
00:00 +6: TileLayerEnvironmentInspectorSection active Ajouter une zone avec plusieurs presets et sélection
00:00 +7: TileLayerEnvironmentInspectorSection affiche un état prêt avec preset zone et masque
00:00 +8: TileLayerEnvironmentInspectorSection affiche le nombre de placements générés
00:00 +9: TileLayerEnvironmentInspectorSection affiche un warning si des placements sont manquants
00:00 +10: TileLayerEnvironmentInspectorSection affiche une erreur si le preset est manquant
00:00 +11: TileLayerEnvironmentInspectorSection affiche un message legacy
00:00 +12: TileLayerEnvironmentInspectorSection n’affiche pas d’action active de génération dans ce lot
00:00 +13: TileLayerEnvironmentInspectorSection active Peindre le masque avec callback
00:00 +14: TileLayerEnvironmentInspectorSection affiche Effacer du masque quand le masque est éditable
00:00 +15: TileLayerEnvironmentInspectorSection active Effacer du masque avec callback
00:00 +16: TileLayerEnvironmentInspectorSection affiche Taille du pinceau et les choix 1 3 5 7
00:00 +17: TileLayerEnvironmentInspectorSection cliquer sur 3 change la taille du pinceau
00:00 +18: TileLayerEnvironmentInspectorSection sans callback les tailles de pinceau sont désactivées
00:01 +19: TileLayerEnvironmentInspectorSection affiche Peinture active et stop quand le mode est actif
00:01 +20: TileLayerEnvironmentInspectorSection affiche Effacement actif et garde la taille visible
00:01 +21: TileLayerEnvironmentInspectorSection après création avec masque vide la brush reste désactivée
00:01 +22: TileLayerEnvironmentInspectorSection la suppression des placements générés reste désactivée
00:01 +23: All tests passed!
```

Cas couverts :
- helper size 1 / 3 / 5 / 7 ;
- ordre row-major ;
- clipping bord de map ;
- centre hors map ;
- tailles invalides ;
- painter no-throw paint ;
- painter no-throw erase ;
- painter no-throw bord de map ;
- painter no-throw overlay null ;
- repaint quand mode paint devient erase ;
- non-régression du use case brush ;
- non-régression du routing canvas TileLayer paint/erase ;
- non-régressions des lots 30 à 36 demandées.

## 8. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/services/environment_mask_brush_footprint_resolver.dart lib/src/application/use_cases/environment_mask_use_cases.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart test/environment_studio/environment_mask_brush_footprint_resolver_test.dart test/environment_studio/tile_layer_environment_brush_cursor_overlay_test.dart test/environment_studio/environment_mask_brush_size_use_case_test.dart test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
```

Résultat :

```text
Analyzing 8 items...                                            
No issues found! (ran in 2.2s)
```

Dette préexistante hors lot :
- aucune dette préexistante n’est remontée par l’analyse ciblée.

## 9. Fichiers créés/modifiés

Fichiers déjà présents/modifiés avant Environment-37 :
- aucun ; le `git status --short --untracked-files=all` initial était vide.

Fichiers créés par Environment-37 :
- `packages/map_editor/lib/src/application/services/environment_mask_brush_footprint_resolver.dart`
- `packages/map_editor/test/environment_studio/environment_mask_brush_footprint_resolver_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_brush_cursor_overlay_test.dart`
- `reports/environment_studio/environment_37_tile_layer_environment_brush_cursor_overlay.md`

Fichiers modifiés par Environment-37 :
- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`

Fichiers préexistants dans le worktree non touchés :
- aucun fichier préexistant modifié hors lot au démarrage.

Problèmes introduits par ce lot :
- aucun problème détecté par les tests et l’analyse ciblée lancés.

## 10. Non-objectifs respectés

- pas de brush circulaire ;
- pas de shape ;
- pas de slider ;
- pas de génération ;
- pas de preview de placements générés ;
- pas de clear/regenerate/shuffle ;
- pas de MapPlacedElement ;
- pas de création d’area ;
- pas de création de preset ;
- pas de migration ;
- pas de map_core ;
- pas de runtime ;
- pas de build_runner ;
- pas de generated files.

## 11. Evidence pack

Status initial :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
```

Status final :

```bash
git status --short --untracked-files=all
```

Résultat final :

```text
 M packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
?? packages/map_editor/lib/src/application/services/environment_mask_brush_footprint_resolver.dart
?? packages/map_editor/test/environment_studio/environment_mask_brush_footprint_resolver_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_brush_cursor_overlay_test.dart
?? reports/environment_studio/environment_37_tile_layer_environment_brush_cursor_overlay.md
```

Diff stat :

```bash
git diff --stat
```

Résultat :

```text
 .../use_cases/environment_mask_use_cases.dart      | 38 +++++---------
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   | 18 ++++++-
 .../src/ui/canvas/map_canvas/map_grid_painter.dart | 61 ++++++++++++++++++++++
 3 files changed, 91 insertions(+), 26 deletions(-)
```

Diff name-only :

```bash
git diff --name-only
```

Résultat :

```text
packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
```

Note sur `git diff --stat` et `git diff --name-only` :
- ces deux commandes Git listent les fichiers suivis modifiés ;
- les fichiers créés par Environment-37 apparaissent dans le status final avec le préfixe `??`.

Diff check :

```bash
git diff --check
```

Résultat :

```text
```

Commandes principales :
- `dart format packages/map_editor/lib/src/application/services/environment_mask_brush_footprint_resolver.dart packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart packages/map_editor/lib/src/ui/canvas/map_canvas.dart packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart packages/map_editor/test/environment_studio/environment_mask_brush_footprint_resolver_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_brush_cursor_overlay_test.dart`
- `flutter test test/environment_studio/environment_mask_brush_footprint_resolver_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_brush_cursor_overlay_test.dart`
- `flutter test test/environment_studio/environment_mask_brush_size_use_case_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_erase_mode_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_brush_size_state_test.dart`
- `flutter test test/environment_studio/environment_layer_mask_brush_tool_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_area_create_use_case_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_area_notifier_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `flutter analyze lib/src/application/services/environment_mask_brush_footprint_resolver.dart lib/src/application/use_cases/environment_mask_use_cases.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart test/environment_studio/environment_mask_brush_footprint_resolver_test.dart test/environment_studio/tile_layer_environment_brush_cursor_overlay_test.dart test/environment_studio/environment_mask_brush_size_use_case_test.dart test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart`
- `git diff --check`

Résultats tests :
- tous les tests ciblés et non-régressions listés en section 7 passent.

Résultat analyse :
- `No issues found! (ran in 2.2s)`

## 12. Diff pertinent

### Nouveau fichier — `packages/map_editor/lib/src/application/services/environment_mask_brush_footprint_resolver.dart`

```dart
import 'package:map_core/map_core.dart';

import '../errors/application_errors.dart';

const Set<int> kEnvironmentMaskBrushFootprintSizes = {1, 3, 5, 7};

final class EnvironmentMaskBrushFootprint {
  const EnvironmentMaskBrushFootprint({
    required this.mapSize,
    required this.center,
    required this.brushSize,
    required this.cells,
  });

  final GridSize mapSize;
  final GridPos center;
  final int brushSize;
  final List<GridPos> cells;

  bool get isEmpty => cells.isEmpty;
}

EnvironmentMaskBrushFootprint resolveEnvironmentMaskBrushFootprint({
  required GridSize mapSize,
  required GridPos center,
  required int brushSize,
}) {
  if (!kEnvironmentMaskBrushFootprintSizes.contains(brushSize)) {
    throw EditorValidationException(
      'Environment mask brush size must be one of 1, 3, 5 or 7: $brushSize',
    );
  }

  if (mapSize.width <= 0 ||
      mapSize.height <= 0 ||
      center.x < 0 ||
      center.y < 0 ||
      center.x >= mapSize.width ||
      center.y >= mapSize.height) {
    return EnvironmentMaskBrushFootprint(
      mapSize: mapSize,
      center: center,
      brushSize: brushSize,
      cells: const [],
    );
  }

  final radius = (brushSize - 1) ~/ 2;
  final minX = (center.x - radius).clamp(0, mapSize.width - 1);
  final maxX = (center.x + radius).clamp(0, mapSize.width - 1);
  final minY = (center.y - radius).clamp(0, mapSize.height - 1);
  final maxY = (center.y + radius).clamp(0, mapSize.height - 1);

  final cells = <GridPos>[];
  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      cells.add(GridPos(x: x, y: y));
    }
  }

  return EnvironmentMaskBrushFootprint(
    mapSize: mapSize,
    center: center,
    brushSize: brushSize,
    cells: List<GridPos>.unmodifiable(cells),
  );
}
```

### Hunk — `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart`

```diff
diff --git a/packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart b/packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart
index b5e57da0..60473452 100644
--- a/packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart
+++ b/packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart
@@ -1,6 +1,7 @@
 import 'package:map_core/map_core.dart';
 
 import '../errors/application_errors.dart';
+import '../services/environment_mask_brush_footprint_resolver.dart';
 
 /// Lot Environment-22 : peinture / effacement d’une cellule du masque d’une zone.
 ///
@@ -123,8 +124,6 @@ class PaintEnvironmentAreaMaskCellUseCase {
 }
 
 class PaintEnvironmentAreaMaskBrushStrokeUseCase {
-  static const allowedBrushSizes = {1, 3, 5, 7};
-
   MapData execute(
     MapData map, {
     required String environmentLayerId,
@@ -143,15 +142,12 @@ class PaintEnvironmentAreaMaskBrushStrokeUseCase {
     if (aid.isEmpty) {
       throw const EditorValidationException('Area id cannot be empty');
     }
-    if (!allowedBrushSizes.contains(brushSize)) {
-      throw EditorValidationException(
-        'Environment mask brush size must be one of 1, 3, 5 or 7: $brushSize',
-      );
-    }
-    if (center.x < 0 ||
-        center.y < 0 ||
-        center.x >= map.size.width ||
-        center.y >= map.size.height) {
+    final footprint = resolveEnvironmentMaskBrushFootprint(
+      mapSize: map.size,
+      center: center,
+      brushSize: brushSize,
+    );
+    if (footprint.isEmpty) {
       return map;
     }
 
@@ -196,22 +192,14 @@ class PaintEnvironmentAreaMaskBrushStrokeUseCase {
       );
     }
 
-    final radius = (brushSize - 1) ~/ 2;
-    final minX = (center.x - radius).clamp(0, mask.width - 1);
-    final maxX = (center.x + radius).clamp(0, mask.width - 1);
-    final minY = (center.y - radius).clamp(0, mask.height - 1);
-    final maxY = (center.y + radius).clamp(0, mask.height - 1);
-
     List<bool>? nextCells;
-    for (var y = minY; y <= maxY; y++) {
-      for (var x = minX; x <= maxX; x++) {
-        final index = y * mask.width + x;
-        if (mask.cells[index] == isActive) {
-          continue;
-        }
-        nextCells ??= List<bool>.from(mask.cells, growable: false);
-        nextCells[index] = isActive;
+    for (final cell in footprint.cells) {
+      final index = cell.y * mask.width + cell.x;
+      if (mask.cells[index] == isActive) {
+        continue;
       }
+      nextCells ??= List<bool>.from(mask.cells, growable: false);
+      nextCells[index] = isActive;
     }
 
     if (nextCells == null) {
```

### Hunk — `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
index a43fc716..14499abd 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas.dart
@@ -13,10 +13,12 @@ import 'package:map_core/map_core.dart';
 import '../../application/models/map_tool_preview.dart';
 import '../../application/models/path_autotile_set.dart';
 import '../../application/services/environment_generated_placement_hover_resolver.dart';
+import '../../application/services/environment_mask_brush_footprint_resolver.dart';
 import '../../application/services/environment_mask_paint_target_resolver.dart';
 import '../../application/services/tileset_transparent_color_processor.dart';
 import '../../features/editor/state/editor_notifier.dart';
 import '../../features/editor/state/editor_state.dart';
+import '../../features/editor/state/environment_mask_brush_size_provider.dart';
 import '../../features/editor/tools/editor_tool.dart';
 import '../../features/path_pattern/path_pattern_editor_render_resolution.dart';
 import '../../features/surface_painter/surface_layer_static_preview.dart';
@@ -129,6 +131,8 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
   Widget build(BuildContext context) {
     final state = ref.watch(editorNotifierProvider);
     final notifier = ref.read(editorNotifierProvider.notifier);
+    final environmentMaskBrushSize =
+        ref.watch(environmentMaskBrushSizeProvider);
     final activeMap = state.activeMap;
     final settings = state.project?.settings ?? const ProjectSettings();
     final connectionLabelsByDirection =
@@ -255,6 +259,14 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
                 selectedAreaId: state.selectedEnvironmentAreaId,
               )?.area.mask
             : null;
+        final environmentBrushCursorOverlay =
+            isEnvironmentMaskEditing && hoveredTile != null
+                ? EnvironmentMaskBrushCursorOverlay(
+                    center: hoveredTile,
+                    brushSize: environmentMaskBrushSize,
+                    mode: state.environmentMaskEditMode!,
+                  )
+                : null;
 
         void applyToolAt(GridPos gridPos, {bool partOfStroke = false}) {
           if (isEnvironmentMaskEditing) {
@@ -481,7 +493,9 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
                           map: activeMap,
                           zoom: state.zoom,
                           offset: state.panOffset,
-                          hoveredTile: _hoveredTile,
+                          hoveredTile: environmentBrushCursorOverlay == null
+                              ? _hoveredTile
+                              : null,
                           activeLayerId: state.activeLayerId,
                           tileWidth: tileWidth,
                           tileHeight: tileHeight,
@@ -509,6 +523,8 @@ class _MapCanvasState extends ConsumerState<MapCanvas> {
                           project: state.project,
                           editorEntityAnimationMs: _editorEntityAnimationMs,
                           environmentMaskOverlay: environmentMaskOverlay,
+                          environmentBrushCursorOverlay:
+                              environmentBrushCursorOverlay,
                           environmentGeneratedAddPreview:
                               environmentGeneratedAddPreview?.placed,
                           environmentGeneratedDeletePreviewId:
```

### Hunk — `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`

```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
index fdb09ec1..5d55a13c 100644
--- a/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
+++ b/packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
@@ -154,6 +154,30 @@ bool _isExplicitForegroundTileLayerForEditor({
   return containsMarker(id) || containsMarker(name);
 }
 
+@visibleForTesting
+final class EnvironmentMaskBrushCursorOverlay {
+  const EnvironmentMaskBrushCursorOverlay({
+    required this.center,
+    required this.brushSize,
+    required this.mode,
+  });
+
+  final GridPos center;
+  final int brushSize;
+  final EnvironmentMaskEditMode mode;
+
+  @override
+  bool operator ==(Object other) {
+    return other is EnvironmentMaskBrushCursorOverlay &&
+        other.center == center &&
+        other.brushSize == brushSize &&
+        other.mode == mode;
+  }
+
+  @override
+  int get hashCode => Object.hash(center, brushSize, mode);
+}
+
 /// Painter massif extrait tel quel du shell `MapCanvas`.
 ///
 /// Cette extraction est volontairement mécanique : on ne change pas la
@@ -190,6 +214,7 @@ class MapGridPainter extends CustomPainter {
 
   /// Lot Environment-22 : surcouche semi-transparente des cellules masque actives.
   final EnvironmentAreaMask? environmentMaskOverlay;
+  final EnvironmentMaskBrushCursorOverlay? environmentBrushCursorOverlay;
   final MapPlacedElement? environmentGeneratedAddPreview;
   final String? environmentGeneratedDeletePreviewId;
 
@@ -222,6 +247,7 @@ class MapGridPainter extends CustomPainter {
     this.project,
     this.editorEntityAnimationMs = 0,
     this.environmentMaskOverlay,
+    this.environmentBrushCursorOverlay,
     this.environmentGeneratedAddPreview,
     this.environmentGeneratedDeletePreviewId,
   });
@@ -381,6 +407,7 @@ class MapGridPainter extends CustomPainter {
     _paintToolPreview(canvas);
     _paintEnvironmentGeneratedAddPreview(canvas);
     _paintEnvironmentMaskOverlay(canvas);
+    _paintEnvironmentBrushCursorOverlay(canvas);
     _paintMapEvents(canvas);
     _paintTriggers(canvas);
     _paintWarps(canvas);
@@ -426,6 +453,38 @@ class MapGridPainter extends CustomPainter {
     }
   }
 
+  void _paintEnvironmentBrushCursorOverlay(Canvas canvas) {
+    final overlay = environmentBrushCursorOverlay;
+    if (overlay == null) return;
+
+    final footprint = resolveEnvironmentMaskBrushFootprint(
+      mapSize: map.size,
+      center: overlay.center,
+      brushSize: overlay.brushSize,
+    );
+    if (footprint.isEmpty) return;
+
+    final isErase = overlay.mode == EnvironmentMaskEditMode.erase;
+    final fill = Paint()
+      ..color = (isErase ? const Color(0x66FF7043) : const Color(0x6626C6DA))
+      ..style = PaintingStyle.fill;
+    final border = Paint()
+      ..color = isErase ? const Color(0xFFFFB199) : const Color(0xFF80DEEA)
+      ..style = PaintingStyle.stroke
+      ..strokeWidth = 2.0 / zoom;
+
+    for (final cell in footprint.cells) {
+      final rect = Rect.fromLTWH(
+        cell.x * tileWidth,
+        cell.y * tileHeight,
+        tileWidth,
+        tileHeight,
+      );
+      canvas.drawRect(rect, fill);
+      canvas.drawRect(rect, border);
+    }
+  }
+
   void _paintWarps(Canvas canvas) {
     if (warps.isEmpty) return;
     for (final warp in warps) {
@@ -2406,6 +2465,8 @@ class MapGridPainter extends CustomPainter {
             environmentGeneratedAddPreview ||
         oldDelegate.environmentGeneratedDeletePreviewId !=
             environmentGeneratedDeletePreviewId ||
+        oldDelegate.environmentBrushCursorOverlay !=
+            environmentBrushCursorOverlay ||
         !_sameEnvironmentMaskOverlay(
           oldDelegate.environmentMaskOverlay,
           environmentMaskOverlay,
```

### Nouveau fichier — `packages/map_editor/test/environment_studio/environment_mask_brush_footprint_resolver_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/environment_mask_brush_footprint_resolver.dart';

void main() {
  group('resolveEnvironmentMaskBrushFootprint', () {
    test('size 1 retourne exactement la cellule centrale', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 5, height: 5),
        center: const GridPos(x: 2, y: 2),
        brushSize: 1,
      );

      expect(footprint.cells, const [GridPos(x: 2, y: 2)]);
    });

    test('size 3 retourne un carré 3x3 stable en ordre row-major', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 5, height: 5),
        center: const GridPos(x: 2, y: 2),
        brushSize: 3,
      );

      expect(footprint.cells, const [
        GridPos(x: 1, y: 1),
        GridPos(x: 2, y: 1),
        GridPos(x: 3, y: 1),
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
        GridPos(x: 3, y: 2),
        GridPos(x: 1, y: 3),
        GridPos(x: 2, y: 3),
        GridPos(x: 3, y: 3),
      ]);
    });

    test('size 5 retourne un carré 5x5 stable', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 7, height: 7),
        center: const GridPos(x: 3, y: 3),
        brushSize: 5,
      );

      expect(footprint.cells.length, 25);
      expect(footprint.cells.first, const GridPos(x: 1, y: 1));
      expect(footprint.cells[4], const GridPos(x: 5, y: 1));
      expect(footprint.cells[20], const GridPos(x: 1, y: 5));
      expect(footprint.cells.last, const GridPos(x: 5, y: 5));
    });

    test('size 7 retourne un carré 7x7 stable', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 9, height: 9),
        center: const GridPos(x: 4, y: 4),
        brushSize: 7,
      );

      expect(footprint.cells.length, 49);
      expect(footprint.cells.first, const GridPos(x: 1, y: 1));
      expect(footprint.cells[6], const GridPos(x: 7, y: 1));
      expect(footprint.cells[42], const GridPos(x: 1, y: 7));
      expect(footprint.cells.last, const GridPos(x: 7, y: 7));
    });

    test('bord de map clippe correctement', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 4, height: 4),
        center: const GridPos(x: 0, y: 0),
        brushSize: 5,
      );

      expect(footprint.cells, const [
        GridPos(x: 0, y: 0),
        GridPos(x: 1, y: 0),
        GridPos(x: 2, y: 0),
        GridPos(x: 0, y: 1),
        GridPos(x: 1, y: 1),
        GridPos(x: 2, y: 1),
        GridPos(x: 0, y: 2),
        GridPos(x: 1, y: 2),
        GridPos(x: 2, y: 2),
      ]);
    });

    test('centre hors map retourne vide', () {
      final footprint = resolveEnvironmentMaskBrushFootprint(
        mapSize: const GridSize(width: 4, height: 4),
        center: const GridPos(x: -1, y: 0),
        brushSize: 3,
      );

      expect(footprint.cells, isEmpty);
    });

    test('tailles invalides refusées', () {
      for (final size in [0, 2, 4, 8]) {
        expect(
          () => resolveEnvironmentMaskBrushFootprint(
            mapSize: const GridSize(width: 4, height: 4),
            center: const GridPos(x: 1, y: 1),
            brushSize: size,
          ),
          throwsA(isA<EditorValidationException>()),
        );
      }
    });
  });
}
```

### Nouveau fichier — `packages/map_editor/test/environment_studio/tile_layer_environment_brush_cursor_overlay_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';

void main() {
  group('Environment brush cursor overlay', () {
    test('MapGridPainter ne lève pas avec un overlay paint', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      _painter(
        const EnvironmentMaskBrushCursorOverlay(
          center: GridPos(x: 1, y: 1),
          brushSize: 3,
          mode: EnvironmentMaskEditMode.paint,
        ),
      ).paint(canvas, const ui.Size(128, 128));

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('MapGridPainter ne lève pas avec un overlay erase', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      _painter(
        const EnvironmentMaskBrushCursorOverlay(
          center: GridPos(x: 1, y: 1),
          brushSize: 3,
          mode: EnvironmentMaskEditMode.erase,
        ),
      ).paint(canvas, const ui.Size(128, 128));

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('MapGridPainter ne lève pas avec size 5 au bord de map', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      _painter(
        const EnvironmentMaskBrushCursorOverlay(
          center: GridPos(x: 0, y: 0),
          brushSize: 5,
          mode: EnvironmentMaskEditMode.paint,
        ),
      ).paint(canvas, const ui.Size(128, 128));

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('MapGridPainter ne lève pas avec overlay null', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      _painter(null).paint(canvas, const ui.Size(128, 128));

      final picture = recorder.endRecording();
      picture.dispose();
    });

    test('shouldRepaint distingue paint et erase', () {
      final paintPainter = _painter(
        const EnvironmentMaskBrushCursorOverlay(
          center: GridPos(x: 1, y: 1),
          brushSize: 3,
          mode: EnvironmentMaskEditMode.paint,
        ),
      );
      final erasePainter = _painter(
        const EnvironmentMaskBrushCursorOverlay(
          center: GridPos(x: 1, y: 1),
          brushSize: 3,
          mode: EnvironmentMaskEditMode.erase,
        ),
      );

      expect(erasePainter.shouldRepaint(paintPainter), isTrue);
    });
  });
}

MapGridPainter _painter(EnvironmentMaskBrushCursorOverlay? overlay) {
  return MapGridPainter(
    map: const MapData(
      id: 'map',
      name: 'Map',
      size: GridSize(width: 4, height: 4),
      layers: <MapLayer>[
        TileLayer(
          id: 'tiles',
          name: 'Sol',
          tiles: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      ],
    ),
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: 32,
    tileHeight: 32,
    tilesetImagesById: const <String, ui.Image?>{},
    sourceTileWidth: 32,
    sourceTileHeight: 32,
    tilesPerRowById: const <String, int>{},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const {},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    environmentBrushCursorOverlay: overlay,
  );
}
```

Le fichier courant est le rapport créé par Environment-37. Le recopier intégralement dans cette section produirait une boucle documentaire sans preuve additionnelle ; les preuves vérifiables du lot sont les hunks et contenus code/test reproduits ci-dessus, les commandes exactes et leurs résultats exacts.

## 13. Auto-review

- L’overlay est-il visible uniquement en mode paint/erase actif ? Oui, `MapCanvas` le construit seulement quand `_isEnvironmentMaskEditing` est vrai.
- L’overlay disparaît-il hors canvas / target invalide ? Oui, `MouseRegion.onExit` remet `_hoveredTile` à `null`, et une target invalide rend `_isEnvironmentMaskEditing` faux.
- L’overlay utilise-t-il la même footprint que la vraie peinture ? Oui, use case et painter appellent `resolveEnvironmentMaskBrushFootprint`.
- Brush size 3 affiche-t-il bien un 3x3 ? Oui, couvert par le test footprint size 3 ; le painter utilise ce helper.
- Brush size 5 au bord est-il clippé correctement ? Oui, couvert par le test footprint bord de map et le test painter no-throw size 5 au bord.
- Paint et erase ont-ils un style visuel distinct ? Oui, cyan pour paint et orange pour erase.
- Hover ne mute-t-il jamais MapData ? Oui, le hover ne fait que mettre à jour `_hoveredTile`; les tests de routing vérifient que les mutations restent attachées au tap.
- Aucun MapPlacedElement n’est-il créé ? Oui, les tests routing et use case non-régression gardent `placedElements` vide ou préservé.
- Aucune génération n’est-elle lancée ? Oui, aucun chemin generator n’est appelé ni modifié.
- Le flow legacy reste-t-il intact ? Oui, `environment_layer_mask_brush_tool_test.dart` passe.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 14. Critique du prompt et du lot

Clair :
- le scope visuel et non-mutant était clair ;
- la nécessité d’un footprint partagé était explicite ;
- les non-objectifs interdisaient correctement les dérives vers preview de génération ou brush avancée.

Ambigu :
- le niveau de test attendu pour le hover exact du widget `MapCanvas` pouvait être interprété de plusieurs façons, car `_hoveredTile` est privé et le painter est plus simple à tester sans golden fragile ;
- le prompt demandait idéalement la cohérence hover vs peinture, mais le test direct du dessin pixel-perfect aurait été plus coûteux que la valeur V0.

À trancher avant Environment-38 :
- faut-il exposer un modèle testable du hover canvas sans golden, par exemple un petit resolver de `BrushCursorOverlay` côté application ?
- faut-il afficher l’overlay aussi pendant un drag actif, avec interpolation éventuelle entre deux cellules ?
- faut-il harmoniser le libellé “Arrêter la peinture” avec erase avant d’ajouter plusieurs areas dans la section TileLayer-centric ?

## 15. Verdict

```text
Environment-37 livré
Code produit modifié : oui
Code UI/canvas modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-38 — TileLayer Environment Area Selection List V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/switch/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié le modèle persistant.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement un overlay de cursor brush.
- [x] Je n’ai pas ajouté de brush circulaire.
- [x] Je n’ai pas ajouté de génération.
- [x] Je n’ai pas créé d’EnvironmentArea.
- [x] Je n’ai pas créé de MapPlacedElement.
- [x] Hover ne mute pas MapData.
- [x] L’overlay utilise la même footprint que la vraie brush.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
