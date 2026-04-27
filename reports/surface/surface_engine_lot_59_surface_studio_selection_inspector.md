# Lot 59 — Surface Studio Inspector / Authoring Prep

## Evidence Pack — génération automatique (fichiers sources et diffs intégrés)

Les sections A–D ci-dessous sont produites à partir du worktree local au moment de la finalisation.

## Résumé exécutif

`SurfaceStudioSelectionInspector` affiche, en lecture seule, le détail structuré de l'atlas, animation ou preset couramment sélectionné, ou les états « aucune sélection » / « sélection introuvable ». Intégration dans `SurfaceStudioPanel` entre le résumé de sélection (Lot 58) et le catalogue. Aucune mutation manifest/catalogue, pas de `map_core` modifié, pas de provider.

## Tableau des lots 39–63

| Lot | Intitulé | Statut |
|-----|----------|--------|
| 39 | ProjectSurfaceAtlas JSON Codec V0 | fait |
| 40 | Surface TileRef / AnimationFrame JSON Codec V0 | fait |
| 41 | SurfaceAnimationTimeline JSON Codec V0 | fait |
| 42 | ProjectSurfaceAnimation JSON Codec V0 | fait |
| 43 | SurfaceVariantAnimationRef JSON Codec V0 | fait |
| 44 | SurfaceVariantAnimationRefSet JSON Codec V0 | fait |
| 45 | ProjectSurfacePreset JSON Codec V0 | fait |
| 46 | ProjectSurfaceCatalog JSON Codec V0 | fait |
| 47 | Surface JSON Golden Samples / Characterization | fait |
| 48 | ProjectManifest Surface Integration Prep | fait |
| 49 | ProjectManifest Surface Integration V0 | fait |
| 50 | Surface Catalog Manifest Operations / Use Cases Prep | fait |
| 51 | Surface Studio Read Model Prep | fait |
| 52 | Surface Studio Panel Shell V0 | fait |
| 53 | Surface Studio Workspace Entry V0 | fait |
| 54 | Surface Studio Catalog Browser V0 | fait |
| 55 | Surface Studio Catalog Diagnostics View V0 | fait |
| 56 | Surface Studio Atlas Detail / Empty State V0 | fait |
| 57 | Surface Studio Animation Detail / Preset Detail V0 | fait |
| 58 | Surface Studio Selection State V0 | fait |
| **59** | **Surface Studio Inspector / Authoring Prep** | **ce lot** |
| 60 | Surface Studio Atlas Authoring Prep V0 | prochain probable |
| 61 | Surface Studio Animation Authoring Prep V0 | ensuite probable |
| 62 | Surface Studio Preset Authoring Prep V0 | ensuite probable |
| 63 | Surface Studio Authoring Save Flow Prep V0 | ensuite probable |

## Distinction changements préexistants (hors objectif isolé Lot 59) / Lot 59

- **Périmètre Lot 59 (fichiers livrés par ce lot)** :  
  - création `surface_studio_selection_inspector.dart`, `surface_studio_selection_inspector_test.dart` ;  
  - modifications ciblées `surface_studio_panel.dart`, `surface_studio_panel_test.dart`, `surface_studio_workspace_entry_test.dart` ;  
  - création de ce rapport `surface_engine_lot_59_surface_studio_selection_inspector.md`.  
- **Même worktree, lots antérieurs non commités** : sélection / résumé / browser (Lot 58), vues détail (56–55), etc. Le `git diff` sur `surface_studio_panel.dart` et assimiles **peut cumuler** Lot 58 et 59 ; seules les hunk d’**insertion de l’inspecteur** relèvent strictement du Lot 59.
- **Autre chantier possible** : les lignes `map_core` du statut initial (Lot 15) ne font pas partie du contrat d’implémentation de l’inspecteur.

## Passes (audit, implémentation, tests, review, evidence)

1. Audit des vues détail (Lots 56–57) et du panneau Lot 58.
2. Widget inspecteur + tests + intégration panel/workspace.
3. `flutter test` ciblés, suite `test/surface_studio`, `dart test` map_core read model, `flutter analyze` 20 chemins.
4. Auto-review (section dédiée).
5. Rapport (ce fichier).

## git status initial (snapshot au début de la session de conversation / environnement fourni, avant finalisation du Lot 59)

Ces entrées proviennent de l’état `git` figé en ouverture de fil (lot Lot 15 `map_core` + rapport associé) ; le worktree a ensuite intégré les lots Surface 58/59 côté `map_editor` non commités.

```
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart
?? packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
?? reports/surface/surface_engine_lot_15_standard_path_preset_vertical_atlas_builder.md
```

## Pourquoi l'inspecteur est read-only

Aucun champ `TextField`, pas d'`onTap` de mutation, pas d'appel aux opérations manifest : uniquement de la projection des lignes read model (atlas / animation / preset).

## Pourquoi l'inspecteur ne persiste pas la sélection

La sélection est l'état local du `StatefulWidget` du panneau (Lot 58) ; l'inspecteur est `StatelessWidget` et n'embarque que `readModel` + `selection` passés en paramètres.

## Pourquoi pas de `map_core` ici

La résolution id → entité se fait par recherche linéaire dans les listes du `SurfaceStudioReadModel` fourni.

## Pourquoi l’inspecteur prépare l’authoring sans ouvrir l’édition

Il **matérialise** les mêmes libellés et formats que les fiches détail (atlas / animation / preset) pour que l’utilisateur s’oriente avant d’éventuels formulaires (Lots 60–63) ; il n’expose **aucun** contrôle actif de modification, aucun pipeline de sauvegarde, aucun mode « brouillon ».

## Où la sélection est stockée / où l’inspecteur est branché

- **Sélection** : état privé `_selection` du `State` de `SurfaceStudioPanel` (Lot 58), mis à jour par les taps du `SurfaceStudioCatalogBrowser`.
- **Résumé** : `SurfaceStudioSelectionSummary(selection: _selection)` au-dessus de l’inspecteur.
- **Inspecteur** : `SurfaceStudioSelectionInspector(readModel: widget.readModel, selection: _selection)` inséré **entre** résumé et catalogue, comme spécifié.

## Commandes lancées (résultats)

- `dart format` : chemins ciblés (lib + tests Lot 59).
- `cd packages/map_editor && flutter test test/surface_studio/surface_studio_selection_inspector_test.dart`  
  Dernière ligne : `+15: All tests passed!`
- Suite combinée 11 fichiers `test/surface_studio/…` : `+217: All tests passed!` (dernière ligne).
- `cd packages/map_core && dart test test/surface_studio_read_model_test.dart` : `+30: All tests passed!`
- `cd packages/map_editor && flutter analyze` (20 chemins) : sortie intégrale en section E ci-dessous — `No issues found! (ran in 2.0s)`
- Suite Surface Studio 11 fichiers : dernière ligne `+217: All tests passed!`
- `cd packages/map_core && dart test test/surface_studio_read_model_test.dart` : dernière ligne `+30: All tests passed!`
- `cd packages/map_editor && flutter test` (package entier) : dernière ligne `01:09 +690 -41: Some tests failed.` — échecs de **compilation** sur plusieurs tests (paramètre `surfaceCatalog` requis) ; détente hors Lot 59 ; les tests ciblés Surface Studio passent.

## Fichiers formatés (dart format)

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart`
- `packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart`
- (autres modifiés si reformatés : panel, tests panel/workspace)

## Sortie complète — test inspecteur

```

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart                                                             
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart                                                             
00:01 +0: SurfaceStudioSelectionInspector (Lot 59) 1. titre Inspecteur Surface                                                                                                                         
00:02 +0: SurfaceStudioSelectionInspector (Lot 59) 1. titre Inspecteur Surface                                                                                                                         
00:02 +1: SurfaceStudioSelectionInspector (Lot 59) 1. titre Inspecteur Surface                                                                                                                         
00:02 +1: SurfaceStudioSelectionInspector (Lot 59) 2. badge Lecture seule                                                                                                                              
00:02 +2: SurfaceStudioSelectionInspector (Lot 59) 2. badge Lecture seule                                                                                                                              
00:02 +2: SurfaceStudioSelectionInspector (Lot 59) 3. état none                                                                                                                                        
00:02 +3: SurfaceStudioSelectionInspector (Lot 59) 3. état none                                                                                                                                        
00:02 +3: SurfaceStudioSelectionInspector (Lot 59) 4. atlas introuvable                                                                                                                                
00:02 +4: SurfaceStudioSelectionInspector (Lot 59) 4. atlas introuvable                                                                                                                                
00:02 +4: SurfaceStudioSelectionInspector (Lot 59) 5. animation introuvable                                                                                                                            
00:02 +5: SurfaceStudioSelectionInspector (Lot 59) 5. animation introuvable                                                                                                                            
00:02 +5: SurfaceStudioSelectionInspector (Lot 59) 6. preset introuvable                                                                                                                               
00:02 +6: SurfaceStudioSelectionInspector (Lot 59) 6. preset introuvable                                                                                                                               
00:02 +6: SurfaceStudioSelectionInspector (Lot 59) 7–9. atlas sélectionné — identité et champs                                                                                                         
00:02 +7: SurfaceStudioSelectionInspector (Lot 59) 7–9. atlas sélectionné — identité et champs                                                                                                         
00:02 +7: SurfaceStudioSelectionInspector (Lot 59) 10–11. animation sélectionnée                                                                                                                       
00:02 +8: SurfaceStudioSelectionInspector (Lot 59) 10–11. animation sélectionnée                                                                                                                       
00:02 +8: SurfaceStudioSelectionInspector (Lot 59) 12–13. preset sélectionné                                                                                                                           
00:02 +9: SurfaceStudioSelectionInspector (Lot 59) 12–13. preset sélectionné                                                                                                                           
00:02 +9: SurfaceStudioSelectionInspector (Lot 59) 14. pas de TextField                                                                                                                                
00:02 +10: SurfaceStudioSelectionInspector (Lot 59) 14. pas de TextField                                                                                                                               
00:02 +10: SurfaceStudioSelectionInspector (Lot 59) 15. pas de libellés édition / save                                                                                                                 
00:02 +11: SurfaceStudioSelectionInspector (Lot 59) 15. pas de libellés édition / save                                                                                                                 
00:02 +11: SurfaceStudioSelectionInspector (Lot 59) 16. pas de noms de types internes en texte                                                                                                         
00:02 +12: SurfaceStudioSelectionInspector (Lot 59) 16. pas de noms de types internes en texte                                                                                                         
00:02 +12: SurfaceStudioSelectionInspector (Lot 59) 17. sans ProviderScope                                                                                                                             
00:02 +13: SurfaceStudioSelectionInspector (Lot 59) 17. sans ProviderScope                                                                                                                             
00:02 +13: SurfaceStudioSelectionInspector (Lot 59) 18. largeur contrainte                                                                                                                             
00:02 +14: SurfaceStudioSelectionInspector (Lot 59) 18. largeur contrainte                                                                                                                             
00:02 +14: SurfaceStudioSelectionInspector (Lot 59) 19. read model avec diagnostics, sélection valide                                                                                                  
00:02 +15: SurfaceStudioSelectionInspector (Lot 59) 19. read model avec diagnostics, sélection valide                                                                                                  
00:02 +15: All tests passed!                                                                                                                                                                           

```

## E. Autres sorties de commandes (intégrales, telles qu’enregistrées)

### `flutter analyze` (20 chemins)

```
Analyzing 20 items...                                           
No issues found! (ran in 2.0s)
EXIT:0
```

### `dart test` — Lot 51 `test/surface_studio_read_model_test.dart` (intégrale)

```

00:00 [32m+0[0m: [1m[90mloading test/surface_studio_read_model_test.dart[0m[0m                                                                                                                                             
00:00 [32m+0[0m: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                                                                       
00:00 [32m+1[0m: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                                                                       
00:00 [32m+1[0m: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                                                                
00:00 [32m+2[0m: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                                                                
00:00 [32m+2[0m: Surface Studio read model (Lot 51) 3. minimal water — summary counts and non-empty[0m                                                                                                           
00:00 [32m+3[0m: Surface Studio read model (Lot 51) 3. minimal water — summary counts and non-empty[0m                                                                                                           
00:00 [32m+3[0m: Surface Studio read model (Lot 51) 4. minimal water — atlas row main fields[0m                                                                                                                  
00:00 [32m+4[0m: Surface Studio read model (Lot 51) 4. minimal water — atlas row main fields[0m                                                                                                                  
00:00 [32m+4[0m: Surface Studio read model (Lot 51) 5. atlas rows preserve catalog order[0m                                                                                                                      
00:00 [32m+5[0m: Surface Studio read model (Lot 51) 5. atlas rows preserve catalog order[0m                                                                                                                      
00:00 [32m+5[0m: Surface Studio read model (Lot 51) 6. atlas usedByAnimationIds — two animations, one atlas[0m                                                                                                   
00:00 [32m+6[0m: Surface Studio read model (Lot 51) 6. atlas usedByAnimationIds — two animations, one atlas[0m                                                                                                   
00:00 [32m+6[0m: Surface Studio read model (Lot 51) 7. atlas usedByAnimationIds — one animation twice same atlas[0m                                                                                              
00:00 [32m+7[0m: Surface Studio read model (Lot 51) 7. atlas usedByAnimationIds — one animation twice same atlas[0m                                                                                              
00:00 [32m+7[0m: Surface Studio read model (Lot 51) 8. minimal water — animation row main fields[0m                                                                                                              
00:00 [32m+8[0m: Surface Studio read model (Lot 51) 8. minimal water — animation row main fields[0m                                                                                                              
00:00 [32m+8[0m: Surface Studio read model (Lot 51) 9. animation rows preserve catalog order[0m                                                                                                                  
00:00 [32m+9[0m: Surface Studio read model (Lot 51) 9. animation rows preserve catalog order[0m                                                                                                                  
00:00 [32m+9[0m: Surface Studio read model (Lot 51) 10. animation referencedAtlasIds — first appearance order[0m                                                                                                 
00:00 [32m+10[0m: Surface Studio read model (Lot 51) 10. animation referencedAtlasIds — first appearance order[0m                                                                                                
00:00 [32m+10[0m: Surface Studio read model (Lot 51) 11. animation read model does not validate atlas existence[0m                                                                                               
00:00 [32m+11[0m: Surface Studio read model (Lot 51) 11. animation read model does not validate atlas existence[0m                                                                                               
00:00 [32m+11[0m: Surface Studio read model (Lot 51) 12. minimal water — preset row main fields[0m                                                                                                               
00:00 [32m+12[0m: Surface Studio read model (Lot 51) 12. minimal water — preset row main fields[0m                                                                                                               
00:00 [32m+12[0m: Surface Studio read model (Lot 51) 13. preset rows preserve catalog order[0m                                                                                                                   
00:00 [32m+13[0m: Surface Studio read model (Lot 51) 13. preset rows preserve catalog order[0m                                                                                                                   
00:00 [32m+13[0m: Surface Studio read model (Lot 51) 14. preset referencedAnimationIds — dedupe keeps order[0m                                                                                                   
00:00 [32m+14[0m: Surface Studio read model (Lot 51) 14. preset referencedAnimationIds — dedupe keeps order[0m                                                                                                   
00:00 [32m+14[0m: Surface Studio read model (Lot 51) 15. preset read model does not validate animation existence[0m                                                                                              
00:00 [32m+15[0m: Surface Studio read model (Lot 51) 15. preset read model does not validate animation existence[0m                                                                                              
00:00 [32m+15[0m: Surface Studio read model (Lot 51) 16. full water — preset role order cross, isolated, horizontal[0m                                                                                           
00:00 [32m+16[0m: Surface Studio read model (Lot 51) 16. full water — preset role order cross, isolated, horizontal[0m                                                                                           
00:00 [32m+16[0m: Surface Studio read model (Lot 51) 17. minimal water — diagnostics clean flags on read model[0m                                                                                                
00:00 [32m+17[0m: Surface Studio read model (Lot 51) 17. minimal water — diagnostics clean flags on read model[0m                                                                                                
00:00 [32m+17[0m: Surface Studio read model (Lot 51) 18. diagnostics error — missing animation atlas[0m                                                                                                          
00:00 [32m+18[0m: Surface Studio read model (Lot 51) 18. diagnostics error — missing animation atlas[0m                                                                                                          
00:00 [32m+18[0m: Surface Studio read model (Lot 51) 19. diagnostics error — missing preset animation[0m                                                                                                         
00:00 [32m+19[0m: Surface Studio read model (Lot 51) 19. diagnostics error — missing preset animation[0m                                                                                                         
00:00 [32m+19[0m: Surface Studio read model (Lot 51) 20. diagnostics warning — unused atlas[0m                                                                                                                   
00:00 [32m+20[0m: Surface Studio read model (Lot 51) 20. diagnostics warning — unused atlas[0m                                                                                                                   
00:00 [32m+20[0m: Surface Studio read model (Lot 51) 21. root lists are unmodifiable[0m                                                                                                                          
00:00 [32m+21[0m: Surface Studio read model (Lot 51) 21. root lists are unmodifiable[0m                                                                                                                          
00:00 [32m+21[0m: Surface Studio read model (Lot 51) 22. nested lists are unmodifiable[0m                                                                                                                        
00:00 [32m+22[0m: Surface Studio read model (Lot 51) 22. nested lists are unmodifiable[0m                                                                                                                        
00:00 [32m+22[0m: Surface Studio read model (Lot 51) 23. builder does not order by sortOrder — source list order[0m                                                                                              
00:00 [32m+23[0m: Surface Studio read model (Lot 51) 23. builder does not order by sortOrder — source list order[0m                                                                                              
00:00 [32m+23[0m: Surface Studio read model (Lot 51) 24. builder does not mutate the source catalog[0m                                                                                                           
00:00 [32m+24[0m: Surface Studio read model (Lot 51) 24. builder does not mutate the source catalog[0m                                                                                                           
00:00 [32m+24[0m: Surface Studio read model (Lot 51) 25. value equality of read models for equivalent catalogs[0m                                                                                                
00:00 [32m+25[0m: Surface Studio read model (Lot 51) 25. value equality of read models for equivalent catalogs[0m                                                                                                
00:00 [32m+25[0m: Surface Studio read model (Lot 51) 26. inequality when content differs[0m                                                                                                                      
00:00 [32m+26[0m: Surface Studio read model (Lot 51) 26. inequality when content differs[0m                                                                                                                      
00:00 [32m+26[0m: Surface Studio read model (Lot 51) 27. public export — map_core[0m                                                                                                                             
00:00 [32m+27[0m: Surface Studio read model (Lot 51) 27. public export — map_core[0m                                                                                                                             
00:00 [32m+27[0m: Surface Studio read model (Lot 51) 28. ProjectManifest toJson still Lot 49 — surfaceCatalog only[0m                                                                                            
00:00 [32m+28[0m: Surface Studio read model (Lot 51) 28. ProjectManifest toJson still Lot 49 — surfaceCatalog only[0m                                                                                            
00:00 [32m+28[0m: Surface Studio read model (Lot 51) 29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog[0m                                                                                            
00:00 [32m+29[0m: Surface Studio read model (Lot 51) 29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog[0m                                                                                            
00:00 [32m+29[0m: Surface Studio read model (Lot 51) 30. no Flutter / Riverpod in surface read model public API[0m                                                                                               
00:00 [32m+30[0m: Surface Studio read model (Lot 51) 30. no Flutter / Riverpod in surface read model public API[0m                                                                                               
00:00 [32m+30[0m: All tests passed![0m                                                                                                                                                                           

```

### Suite combinée 11 `test/surface_studio/*.dart` — sortie intégrale (console)

```

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart                                                             
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart                                                             
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart                                                             
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_test.dart                                                                       
00:02 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_test.dart: SurfaceStudioSelection (Lot 58 model) 1. none — aucune sélection             
00:02 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart: ... (Lot 59) 1. titre Inspecteur Surface                           
00:02 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart: ... (Lot 59) 1. titre Inspecteur Surface                           
00:02 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart: ... (Lot 59) 1. titre Inspecteur Surface                           
00:02 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart: ... (Lot 59) 1. titre Inspecteur Surface                           
00:02 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart: ... (Lot 59) 1. titre Inspecteur Surface                           
00:02 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart: ... (Lot 59) 1. titre Inspecteur Surface                           
00:02 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart: ... (Lot 59) 1. titre Inspecteur Surface                           
00:02 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint                                                   
00:03 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint                                                   
00:03 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint                                                   
00:03 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint                                                  
00:03 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint                                                  
00:03 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint                                                  
00:03 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint                                                  
00:03 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                        
00:03 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                        
00:03 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none     
00:03 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none     
00:03 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none     
00:03 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none     
00:03 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none     
00:03 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none     
00:03 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 8. atlas sans badge si none     
00:03 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 4. simple: name and id
00:03 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 4. simple: name and id
00:03 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 4. simple: name and id
00:03 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: ... sélectionnables (Lot 58) 9. atlas affiche état sélectionné  
00:03 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart: ... (Lot 59) 16. pas de noms de types internes en texte           
00:03 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 5. simple: 1 frame    
00:03 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 10. tap atlas déclenche callback
00:03 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 10. tap atlas déclenche callback
00:03 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 10. tap atlas déclenche callback
00:04 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 10. tap atlas déclenche callback
00:04 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 10. tap atlas déclenche callback
00:04 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 10. tap atlas déclenche callback
00:04 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 10. tap atlas déclenche callback
00:04 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: Fiches sélectionnables (Lot 58) 10. tap atlas déclenche callback
00:04 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 9. no sync group      
00:04 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: ... (Lot 58) 11. animation affiche état sélectionné             
00:04 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 10. sync group water  
00:04 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: ... (Lot 58) 12. tap animation déclenche callback               
00:04 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 11. no category       
00:04 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: ... sélectionnables (Lot 58) 13. preset affiche état sélectionné
00:04 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: ... sélectionnables (Lot 58) 13. preset affiche état sélectionné
00:04 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: ... sélectionnables (Lot 58) 13. preset affiche état sélectionné
00:04 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 13. sortOrder         
00:04 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: SurfaceStudioAnimationDetailView (Lot 57) 13. sortOrder         
00:04 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: ... sélection (Lot 58) 15. browser transmet sélection atlas     
00:04 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart: ... sélection (Lot 58) 15. browser transmet sélection atlas     
00:04 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 24. empty: main message     
00:04 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 24. empty: main message     
00:04 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 25. empty: explainer        
00:04 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 25. empty: explainer        
00:04 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 26. simple: name and id     
00:04 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 26. simple: name and id     
00:04 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 27. 1 variante              
00:04 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 27. 1 variante              
00:04 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 28. isolated role humanized 
00:04 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 28. isolated role humanized 
00:04 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 29. multiple roles order    
00:04 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 29. multiple roles order    
00:04 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 30. one linked animation    
00:04 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 30. one linked animation    
00:04 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: ... (Lot 57) 31. two linked animations order                       
00:05 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: ... (Lot 57) 31. two linked animations order                       
00:05 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: ... (Lot 57) 31. two linked animations order                       
00:05 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 32. covers standard false   
00:05 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 32. covers standard false   
00:05 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 33. covers standard true    
00:05 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 33. covers standard true    
00:05 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 34. no category             
00:05 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 34. no category             
00:05 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 35. category                
00:05 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:05 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:05 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:05 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:05 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:05 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:05 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:05 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:05 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:05 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface        
00:05 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:05 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:05 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:05 +85: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:05 +86: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:05 +87: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:05 +88: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:05 +89: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:05 +90: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 1. title Diagnostics Surface   
00:05 +91: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:05 +92: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:05 +93: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:05 +94: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:05 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:06 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:06 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:06 +97: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:06 +98: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:06 +99: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:06 +100: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:06 +101: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:06 +102: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:06 +103: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                 
00:06 +104: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 3. empty catalog: per-section empty lines               
00:06 +105: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 6. error missingAnimationAtlas
00:06 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: ... (Lot 56) 16. animation id order preserved (b, a, c)            
00:06 +107: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 2. read-only badge is visible                      
00:06 +108: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 2. read-only badge is visible                      
00:06 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible             
00:06 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible             
00:06 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 4. minimal catalog: section headers visible             
00:06 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 3. three counters are zero for empty catalog       
00:06 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: ... (Lot 56) 18. not sorted by sortOrder (First before Second)     
00:06 +114: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: ... (Lot 56) 18. not sorted by sortOrder (First before Second)     
00:06 +115: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 5. minimal catalog: atlas details (736-tile grid)       
00:06 +116: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 5. minimal catalog: atlas details (736-tile grid)       
00:06 +117: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 5. minimal catalog: atlas details (736-tile grid)       
00:06 +118: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 4. empty catalog shows empty state copy            
00:06 +119: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 11. mixed: summary counts     
00:06 +120: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 20. no active edit/save copy 
00:06 +121: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 6. minimal catalog: animation details                   
00:06 +122: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                     
00:06 +123: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                     
00:06 +124: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                     
00:06 +125: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 7. minimal catalog: preset details                      
00:06 +126: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 7. minimal catalog: preset details                      
00:06 +127: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_diagnostics_view_test.dart: SurfaceStudioDiagnosticsView (Lot 55) 13. warning order preserved   
00:06 +128: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content         
00:06 +129: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content         
00:06 +130: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content         
00:06 +131: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content         
00:06 +132: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content         
00:06 +133: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 28. bounded width, no throw  
00:06 +134: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 28. bounded width, no throw  
00:06 +135: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: SurfaceStudioCatalogBrowser (Lot 54) 9. atlas used by two animations 
00:06 +136: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +137: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +138: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +139: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +140: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +141: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +142: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +143: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +144: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +145: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +146: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +147: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +148: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +149: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +150: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +151: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +153: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +154: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +155: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +156: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +157: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +158: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +159: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +160: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +161: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +162: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +163: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +164: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +165: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +166: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +167: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +168: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:06 +169: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +169: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +170: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +171: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +172: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +173: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +174: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +175: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +176: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +177: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +178: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +179: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +180: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +181: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +182: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +183: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +184: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +185: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +186: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +187: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +188: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +189: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer 
00:07 +190: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 58.21 — Aucune sélection au départ (catalogue minimal)            
00:07 +191: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)  
00:07 +192: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)  
00:08 +192: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)  
00:08 +193: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)  
00:08 +194: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 58.24 — sélection preset après tap                 
00:08 +195: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:08 +196: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:08 +197: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Terrain / Surface Studio / Path Library order in column 
00:08 +198: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 58.27 — pas de TextField après sélections          
00:08 +199: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:08 +200: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:08 +201: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:08 +202: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:08 +203: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:08 +204: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:08 +205: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:08 +206: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:08 +207: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:08 +208: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.27 — pas de libellés édition/save (Lot 59)      
00:08 +209: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:08 +210: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:08 +211: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:08 +211: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:09 +211: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:09 +212: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:09 +212: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) panel shows 1/1/1 from manifest when catalog is minimal 
00:09 +213: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) panel shows 1/1/1 from manifest when catalog is minimal 
00:09 +213: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... future action CupertinoButtons are disabled, no TextField        
00:09 +214: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... future action CupertinoButtons are disabled, no TextField        
00:09 +214: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:09 +215: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:09 +215: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:09 +216: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:09 +216: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:09 +217: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:09 +217: All tests passed!                                                                                                                                                                          

```

Dernière ligne de synthèse : `+217: All tests passed!`.

### `flutter test` (intégralité du package `map_editor`) — dernière ligne

```
01:09 +690 -41: Some tests failed.                                                                                                                                                                     
```

Exemple d’erreur de compilation rencontrée (dette existante) : `Error: Required named parameter 'surfaceCatalog' must be provided` dans `test/pokemon_catalogs_workspace_ui_test.dart` et d’autres.

## Auto-review

- [x] `SurfaceStudioSelectionInspector` existe, états none / missing / atlas / anim / preset.
- [x] Pas de `TextField`, pas de libellés édition, pas de provider.
- [x] Fichiers **introduits ou modifiés par le Lot 59** : uniquement chemins `map_editor` listés en section « Fichiers concernés » et ce rapport ; `map_core` n’est pas modifié **pour l’objectif inspecteur** (le snapshot initial montre d’éventuels changements d’un autre lot non lié).

## Vérification anti-mojibake

Aucun motif `Ã`, `â€™`, etc. dans les sources Lot 59.

## Proposition Lot 60 (Atlas Authoring Prep)

Introduire un flux **édition brouillon** réservé à un atlas (champs alignés sur les lignes du read model), avec validation locale et **sans** persistance manifest tant que le Lot 63 « Save flow » n’est pas livré — en réutilisant la zone inspecteur comme ancrage UX.

## Ce que le prompt jugeait discutable

- Contrainte d'Evidence Pack monolithique : ce fichier regroupe le maximum demandé ; le diff unifié sur `surface_studio_panel.dart` peut mélanger Lot 58+59 tant qu'il n'y a pas de commit intermédiaire.
- Exiger le **contenu intégral** du présent rapport **dans** la réponse chat en plus du fichier : redondant avec le livrable Markdown versionné ici.

---

# A. Contenu intégral des fichiers créés (Lot 59)

## surface_studio_selection_inspector.dart

```dart
// Inspecteur Surface Studio (Lot 59) — **lecture seule**.
//
// Consomme [SurfaceStudioReadModel] + [SurfaceStudioSelection] : n’en déduit pas
// de recalcul métier, ne mutera ni catalogue ni manifest, pas d’I/O, pas d’authoring
// ici. Prépare les lots d’édition en affichant la même sémantique visuelle que les
// fiches détail, dans une zone d’inspection unifiée.

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../ui/shared/cupertino_editor_widgets.dart';
import 'surface_studio_animation_detail_view.dart';
import 'surface_studio_atlas_detail_view.dart';
import 'surface_studio_preset_detail_view.dart';
import 'surface_studio_selection.dart';

/// Textes d’en-tête (aucun nom de type produit en chaîne).
class SurfaceStudioSelectionInspectorLabels {
  const SurfaceStudioSelectionInspectorLabels._();

  static const String title = 'Inspecteur Surface';
  static const String readOnly = 'Lecture seule';
  static const String noneTitle = 'Aucune sélection à inspecter';
  static const String noneHint =
      'Sélectionnez un atlas, une animation ou un preset pour afficher ses détails.';

  static const String missingTitle = 'Sélection introuvable';
  static const String missingBody =
      'L’élément sélectionné n’existe plus dans le catalogue.';
}

const Color _kInspectorAccent = Color(0xFF2DD4BF);

const ValueKey<String> kSurfaceStudioSelectionInspectorKey =
    ValueKey<String>('SurfaceStudioSelectionInspector');

/// Bloc d’inspection : résout la ligne de catalogue à partir de [selection] et
/// affiche les champs dérivés tels qu’exposés par le read model.
class SurfaceStudioSelectionInspector extends StatelessWidget {
  const SurfaceStudioSelectionInspector({
    super.key,
    required this.readModel,
    required this.selection,
  });

  final SurfaceStudioReadModel readModel;

  final SurfaceStudioSelection selection;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    const accent = _kInspectorAccent;
    return Container(
      key: kSurfaceStudioSelectionInspectorKey,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: EditorChrome.elevatedPanelBackground(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selection.isNone
              ? EditorChrome.editorIslandRim(context)
              : Color.lerp(
                  EditorChrome.editorIslandRim(context),
                  accent,
                  0.4,
                )!,
          width: selection.isNone ? 1 : 1.15,
        ),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  SurfaceStudioSelectionInspectorLabels.title,
                  style: TextStyle(
                    color: label,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color.lerp(
                    EditorChrome.islandFillElevated(context),
                    accent,
                    0.12,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.45),
                    width: 1,
                  ),
                ),
                child: Text(
                  SurfaceStudioSelectionInspectorLabels.readOnly,
                  style: TextStyle(
                    color: label,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (selection.isNone) ...[
            Text(
              SurfaceStudioSelectionInspectorLabels.noneTitle,
              style: TextStyle(
                color: subtle,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              SurfaceStudioSelectionInspectorLabels.noneHint,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ] else
            _InspectorBody(
              readModel: readModel,
              selection: selection,
              label: label,
              subtle: subtle,
              accent: accent,
            ),
        ],
      ),
    );
  }
}

class _InspectorBody extends StatelessWidget {
  const _InspectorBody({
    required this.readModel,
    required this.selection,
    required this.label,
    required this.subtle,
    required this.accent,
  });

  final SurfaceStudioReadModel readModel;
  final SurfaceStudioSelection selection;
  final Color label;
  final Color subtle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (selection.isAtlas) {
      final id = selection.id!;
      final row = _atlasById(readModel, id);
      if (row == null) {
        return _MissingBlock(id: id, label: label, subtle: subtle);
      }
      return _AtlasInspect(
        row: row,
        label: label,
        subtle: subtle,
        accent: accent,
      );
    }
    if (selection.isAnimation) {
      final id = selection.id!;
      final row = _animationById(readModel, id);
      if (row == null) {
        return _MissingBlock(id: id, label: label, subtle: subtle);
      }
      return _AnimationInspect(
        row: row,
        label: label,
        subtle: subtle,
        accent: accent,
      );
    }
    if (selection.isPreset) {
      final id = selection.id!;
      final row = _presetById(readModel, id);
      if (row == null) {
        return _MissingBlock(id: id, label: label, subtle: subtle);
      }
      return _PresetInspect(
        row: row,
        label: label,
        subtle: subtle,
        accent: accent,
      );
    }
    return const SizedBox.shrink();
  }
}

class _MissingBlock extends StatelessWidget {
  const _MissingBlock({
    required this.id,
    required this.label,
    required this.subtle,
  });

  final String id;
  final Color label;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SurfaceStudioSelectionInspectorLabels.missingTitle,
          style: TextStyle(
            color: label,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          SurfaceStudioSelectionInspectorLabels.missingBody,
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          id,
          style: TextStyle(
            color: label,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _K extends StatelessWidget {
  const _K({required this.k, required this.v, required this.valueColor});

  final String k;
  final String v;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Text(
        '$k : $v',
        style: TextStyle(
          color: valueColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

SurfaceStudioAtlasReadModel? _atlasById(
  SurfaceStudioReadModel m,
  String id,
) {
  for (final a in m.atlases) {
    if (a.id == id) {
      return a;
    }
  }
  return null;
}

SurfaceStudioAnimationReadModel? _animationById(
  SurfaceStudioReadModel m,
  String id,
) {
  for (final a in m.animations) {
    if (a.id == id) {
      return a;
    }
  }
  return null;
}

SurfaceStudioPresetReadModel? _presetById(
  SurfaceStudioReadModel m,
  String id,
) {
  for (final p in m.presets) {
    if (p.id == id) {
      return p;
    }
  }
  return null;
}

class _AtlasInspect extends StatelessWidget {
  const _AtlasInspect({
    required this.row,
    required this.label,
    required this.subtle,
    required this.accent,
  });

  final SurfaceStudioAtlasReadModel row;
  final Color label;
  final Color subtle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final nAnim = row.usedByAnimationIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SurfaceStudioAtlasDetailViewLabels.badgeSelected,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          row.name,
          style: TextStyle(
            color: label,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelIdentifiant,
          v: row.id,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelTileset,
          v: row.tilesetId,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelTile,
          v: '${row.tileWidth}×${row.tileHeight}',
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelGrille,
          v: '${row.columns}×${row.rows}',
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelTuiles,
          v: SurfaceStudioAtlasDetailViewLabels.tileCountLigne(row.tileCount),
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelLayout,
          v: SurfaceStudioAtlasDetailViewLabels.layoutHumain(row.layout),
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelCategorie,
          v: row.categoryId == null || row.categoryId!.isEmpty
              ? SurfaceStudioAtlasDetailViewLabels.categorieAucune
              : row.categoryId!,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelOrdre,
          v: row.sortOrder.toString(),
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAtlasDetailViewLabels.labelUtilisation,
          v: SurfaceStudioAtlasDetailViewLabels.utilisationLigne(nAnim),
          valueColor: label,
        ),
        if (nAnim > 0) ...[
          const SizedBox(height: 4),
          Text(
            SurfaceStudioAtlasDetailViewLabels.labelAnimationsUtilisatrices,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          ...row.usedByAnimationIds.map(
            (id) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                id,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnimationInspect extends StatelessWidget {
  const _AnimationInspect({
    required this.row,
    required this.label,
    required this.subtle,
    required this.accent,
  });

  final SurfaceStudioAnimationReadModel row;
  final Color label;
  final Color subtle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final refIds = row.referencedAtlasIds;
    final nAtlas = refIds.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SurfaceStudioAnimationDetailViewLabels.badgeSelected,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          row.name,
          style: TextStyle(
            color: label,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelIdentifiant,
          v: row.id,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelFrames,
          v: SurfaceStudioAnimationDetailViewLabels.framesLigne(
            row.frameCount,
          ),
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelDureeTotale,
          v: '${row.totalDurationMs} ms',
          valueColor: label,
        ),
        const SizedBox(height: 4),
        Text(
          SurfaceStudioAnimationDetailViewLabels.labelAtlasRef,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            SurfaceStudioAnimationDetailViewLabels.atlasRefSummary(nAtlas),
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (nAtlas > 0)
          ...refIds.map(
            (id) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                id,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelSync,
          v: row.syncGroupId == null || row.syncGroupId!.isEmpty
              ? SurfaceStudioAnimationDetailViewLabels.syncAucun
              : row.syncGroupId!,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelCategorie,
          v: row.categoryId == null || row.categoryId!.isEmpty
              ? SurfaceStudioAnimationDetailViewLabels.categorieAucune
              : row.categoryId!,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioAnimationDetailViewLabels.labelOrdre,
          v: row.sortOrder.toString(),
          valueColor: label,
        ),
      ],
    );
  }
}

class _PresetInspect extends StatelessWidget {
  const _PresetInspect({
    required this.row,
    required this.label,
    required this.subtle,
    required this.accent,
  });

  final SurfaceStudioPresetReadModel row;
  final Color label;
  final Color subtle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final animIds = row.referencedAnimationIds;
    final nAnim = animIds.length;
    final roleLabels = row.roles.map(surfaceStudioSurfaceVariantRoleLabel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SurfaceStudioPresetDetailViewLabels.badgeSelected,
          style: TextStyle(
            color: accent,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          row.name,
          style: TextStyle(
            color: label,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        _K(
          k: SurfaceStudioPresetDetailViewLabels.labelIdentifiant,
          v: row.id,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioPresetDetailViewLabels.labelVariantes,
          v: SurfaceStudioPresetDetailViewLabels.variantesLigne(
            row.variantCount,
          ),
          valueColor: label,
        ),
        const SizedBox(height: 4),
        Text(
          SurfaceStudioPresetDetailViewLabels.labelRoles,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        ...roleLabels.map(
          (r) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              r,
              style: TextStyle(
                color: label,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          SurfaceStudioPresetDetailViewLabels.labelAnimationsLiees,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            SurfaceStudioPresetDetailViewLabels.animationsLieesSummary(
              nAnim,
            ),
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (nAnim > 0)
          ...animIds.map(
            (id) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                id,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          SurfaceStudioPresetDetailViewLabels.labelCouverture,
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            row.coversStandardRoles
                ? SurfaceStudioPresetDetailViewLabels.couverturePleine
                : SurfaceStudioPresetDetailViewLabels.couverturePartielle,
            style: TextStyle(
              color: label,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _K(
          k: SurfaceStudioPresetDetailViewLabels.labelCategorie,
          v: row.categoryId == null || row.categoryId!.isEmpty
              ? SurfaceStudioPresetDetailViewLabels.categorieAucune
              : row.categoryId!,
          valueColor: label,
        ),
        _K(
          k: SurfaceStudioPresetDetailViewLabels.labelOrdre,
          v: row.sortOrder.toString(),
          valueColor: label,
        ),
      ],
    );
  }
}

```

## surface_studio_selection_inspector_test.dart

```dart
// Tests widget — [SurfaceStudioSelectionInspector] (Lot 59).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';

void main() {
  group('SurfaceStudioSelectionInspector (Lot 59)', () {
    testWidgets('1. titre Inspecteur Surface', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Inspecteur Surface'), findsOneWidget);
    });

    testWidgets('2. badge Lecture seule', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Lecture seule'), findsOneWidget);
    });

    testWidgets('3. état none', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
      expect(
        find.textContaining('Sélectionnez un atlas'),
        findsOneWidget,
      );
    });

    testWidgets('4. atlas introuvable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('missing-atlas'),
          ),
        ),
      );
      expect(find.text('Sélection introuvable'), findsOneWidget);
      expect(find.text('missing-atlas'), findsOneWidget);
    });

    testWidgets('5. animation introuvable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.animation('missing-animation'),
          ),
        ),
      );
      expect(find.text('missing-animation'), findsOneWidget);
    });

    testWidgets('6. preset introuvable', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.preset('missing-preset'),
          ),
        ),
      );
      expect(find.text('missing-preset'), findsOneWidget);
    });

    testWidgets('7–9. atlas sélectionné — identité et champs', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      expect(find.text('Atlas sélectionné'), findsWidgets);
      expect(find.text('Water Atlas'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-atlas'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Tileset : nature-tileset'),
        findsOneWidget,
      );
      expect(find.textContaining('Tile : 32×32'), findsOneWidget);
      expect(find.textContaining('Grille : 2×2'), findsOneWidget);
      expect(find.textContaining('4 tuiles'), findsOneWidget);
      expect(
        find.textContaining('Colonnes = variantes, lignes = frames'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
      expect(find.textContaining('Ordre : 0'), findsOneWidget);
      expect(
        find.textContaining('Utilisé par 1 animation'),
        findsOneWidget,
      );
      expect(find.text('water-isolated-loop'), findsWidgets);
    });

    testWidgets('10–11. animation sélectionnée', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
          ),
        ),
      );
      expect(find.text('Animation sélectionnée'), findsWidgets);
      expect(find.text('Water Isolated Loop'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-isolated-loop'),
        findsOneWidget,
      );
      expect(find.textContaining('Frames : 1 frame'), findsOneWidget);
      expect(
        find.textContaining('Durée totale : 120 ms'),
        findsOneWidget,
      );
      expect(find.text('water-atlas'), findsWidgets);
      expect(
        find.textContaining('Groupe de synchronisation : Aucun groupe'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('12–13. preset sélectionné', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.preset('water-surface'),
          ),
        ),
      );
      expect(find.text('Preset sélectionné'), findsWidgets);
      expect(find.text('Water Surface'), findsOneWidget);
      expect(
        find.textContaining('Identifiant : water-surface'),
        findsOneWidget,
      );
      expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
      expect(find.text('Isolé'), findsWidgets);
      expect(
        find.textContaining('Rôles standards incomplets'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Catégorie : Aucune catégorie'),
        findsOneWidget,
      );
    });

    testWidgets('14. pas de TextField', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('15. pas de libellés édition / save', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.preset('water-surface'),
          ),
        ),
      );
      for (final s in <String>[
        'Modifier',
        'Supprimer',
        'Enregistrer',
        'Sauvegarder',
        'Save',
        'Edit',
        'Delete',
      ]) {
        expect(find.text(s), findsNothing);
      }
    });

    testWidgets('16. pas de noms de types internes en texte', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: SurfaceStudioSelection.atlas('water-atlas'),
          ),
        ),
      );
      for (final term in <String>[
        'ProjectSurfaceCatalog',
        'ProjectSurfaceAtlas',
        'ProjectSurfaceAnimation',
        'ProjectSurfacePreset',
        'SurfaceStudioReadModel',
        'SurfaceStudioSelection',
        'SurfaceStudioSelectionInspector',
        'SurfaceVariantAnimationRefSet',
        'SurfaceAnimationTimeline',
      ]) {
        expect(
          find.descendant(
            of: find.byKey(kSurfaceStudioSelectionInspectorKey),
            matching: find.textContaining(term),
          ),
          findsNothing,
        );
      }
    });

    testWidgets('17. sans ProviderScope', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: _minimalRead(),
            selection: const SurfaceStudioSelection.none(),
          ),
        ),
      );
      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
    });

    testWidgets('18. largeur contrainte', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 320,
              child: SurfaceStudioSelectionInspector(
                readModel: _minimalRead(),
                selection: SurfaceStudioSelection.preset('water-surface'),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Water Surface'), findsOneWidget);
    });

    testWidgets('19. read model avec diagnostics, sélection valide', (
      tester,
    ) async {
      final rm = buildSurfaceStudioReadModelFromCatalog(
        _catalogWithUnusedAtlas(),
      );
      expect(rm.diagnostics.hasErrors, isFalse);
      await tester.pumpWidget(
        _wrap(
          SurfaceStudioSelectionInspector(
            readModel: rm,
            selection: SurfaceStudioSelection.atlas('used-atlas'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
          matching: find.text('Diagnostics Surface'),
        ),
        findsNothing,
      );
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    ),
  );
}

SurfaceStudioReadModel _minimalRead() {
  return buildSurfaceStudioReadModelFromCatalog(_minimalCatalog());
}

ProjectSurfaceCatalog _minimalCatalog() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final atlas = ProjectSurfaceAtlas(
    id: 'water-atlas',
    name: 'Water Atlas',
    tilesetId: 'nature-tileset',
    geometry: g,
  );
  final frame = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
    durationMs: 120,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'water-isolated-loop',
    name: 'Water Isolated Loop',
    timeline: SurfaceAnimationTimeline(frames: [frame]),
  );
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'water-isolated-loop',
      ),
    ],
  );
  final preset = ProjectSurfacePreset(
    id: 'water-surface',
    name: 'Water Surface',
    variantAnimations: refs,
  );
  return ProjectSurfaceCatalog(
    atlases: [atlas],
    animations: [anim],
    presets: [preset],
  );
}

/// Catalogue avec atlas inutilisé (avertissements, pas d’erreur bloquante).
ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
  final g = SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
  final used = ProjectSurfaceAtlas(
    id: 'used-atlas',
    name: 'U',
    tilesetId: 't',
    geometry: g,
  );
  final unused = ProjectSurfaceAtlas(
    id: 'orphan-atlas',
    name: 'O',
    tilesetId: 't',
    geometry: g,
  );
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(atlasId: 'used-atlas', column: 0, row: 0),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'a',
    name: 'a',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: [used, unused],
    animations: [anim],
    presets: const [],
  );
}

```

# B. Diffs git

## surface_studio_panel.dart

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
index fc85f5ef..3000ae62 100644
--- a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -15,12 +15,15 @@ import 'package:map_core/map_core.dart';
 import '../../ui/shared/cupertino_editor_widgets.dart';
 import 'surface_studio_catalog_browser.dart';
 import 'surface_studio_diagnostics_view.dart';
+import 'surface_studio_selection.dart';
+import 'surface_studio_selection_inspector.dart';
+import 'surface_studio_selection_summary.dart';
 
 /// Accent produit Surface Studio (même base que la tuile World Explorer).
 const Color _surfaceStudioAccent = Color(0xFF2DD4BF);
 
 /// Panneau présentationnel **lecture seule** pour Surface Studio.
-class SurfaceStudioPanel extends StatelessWidget {
+class SurfaceStudioPanel extends StatefulWidget {
   const SurfaceStudioPanel({
     super.key,
     required this.readModel,
@@ -38,9 +41,17 @@ class SurfaceStudioPanel extends StatelessWidget {
   static const String actionImportVerticalAtlasLabel =
       'Importer un atlas vertical';
 
+  @override
+  State<SurfaceStudioPanel> createState() => _SurfaceStudioPanelState();
+}
+
+class _SurfaceStudioPanelState extends State<SurfaceStudioPanel> {
+  /// Sélection d’inspection : locale au widget, jamais écrite dans le manifest.
+  SurfaceStudioSelection _selection = const SurfaceStudioSelection.none();
+
   @override
   Widget build(BuildContext context) {
-    final s = readModel.summary;
+    final s = widget.readModel.summary;
     final label = EditorChrome.primaryLabel(context);
     final subtle = EditorChrome.subtleLabel(context);
 
@@ -56,7 +67,7 @@ class SurfaceStudioPanel extends StatelessWidget {
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
-                  titleText,
+                  SurfaceStudioPanel.titleText,
                   style: TextStyle(
                     color: label,
                     fontSize: 22,
@@ -65,12 +76,12 @@ class SurfaceStudioPanel extends StatelessWidget {
                   ),
                 ),
               ),
-              const _ReadOnlyBadge(label: readOnlyBadgeText),
+              const _ReadOnlyBadge(label: SurfaceStudioPanel.readOnlyBadgeText),
             ],
           ),
           const SizedBox(height: 12),
           Text(
-            productDescriptionText,
+            SurfaceStudioPanel.productDescriptionText,
             style: TextStyle(
               color: subtle,
               fontSize: 13,
@@ -95,10 +106,23 @@ class SurfaceStudioPanel extends StatelessWidget {
             animations: s.animationCount,
             presets: s.presetCount,
           ),
+          const SizedBox(height: 12),
+          SurfaceStudioSelectionSummary(selection: _selection),
+          const SizedBox(height: 12),
+          SurfaceStudioSelectionInspector(
+            readModel: widget.readModel,
+            selection: _selection,
+          ),
+          const SizedBox(height: 12),
+          SurfaceStudioCatalogBrowser(
+            readModel: widget.readModel,
+            selection: _selection,
+            onSelectionChanged: (v) {
+              setState(() => _selection = v);
+            },
+          ),
           const SizedBox(height: 16),
-          SurfaceStudioCatalogBrowser(readModel: readModel),
-          const SizedBox(height: 16),
-          SurfaceStudioDiagnosticsView(readModel: readModel),
+          SurfaceStudioDiagnosticsView(readModel: widget.readModel),
           const SizedBox(height: 20),
           const _FutureActions(
             onCreateAtlas: null,
```

## surface_studio_panel_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
index b7249e85..f3aa8f46 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -7,6 +7,7 @@ import 'package:flutter_test/flutter_test.dart';
 import 'package:macos_ui/macos_ui.dart';
 import 'package:map_core/map_core.dart';
 import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';
 
 void main() {
   group('SurfaceStudioPanel (Lot 52)', () {
@@ -21,7 +22,8 @@ void main() {
       await tester.pumpWidget(
         _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
       );
-      expect(find.text('Lecture seule'), findsOneWidget);
+      // Bandeau panneau + inspecteur (Lot 59).
+      expect(find.text('Lecture seule'), findsNWidgets(2));
     });
 
     testWidgets('3. three counters are zero for empty catalog', (tester) async {
@@ -289,6 +291,255 @@ void main() {
       expect(find.text('Diagnostics Surface'), findsOneWidget);
     });
 
+    testWidgets('58.21 — Aucune sélection au départ (catalogue minimal)',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Aucune sélection'), findsOneWidget);
+    });
+
+    testWidgets('58.22 — sélection atlas après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      expect(find.text('Atlas sélectionné'), findsWidgets);
+      expect(find.text('water-atlas'), findsWidgets);
+    });
+
+    testWidgets('58.23 — sélection animation après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Isolated Loop'));
+      await tester.tap(find.text('Water Isolated Loop'));
+      await tester.pump();
+      expect(find.text('Animation sélectionnée'), findsWidgets);
+      expect(find.text('water-isolated-loop'), findsWidgets);
+    });
+
+    testWidgets('58.24 — sélection preset après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      expect(find.text('Preset sélectionné'), findsWidgets);
+      expect(find.text('water-surface'), findsWidgets);
+    });
+
+    testWidgets('58.25 — changement de sélection remplace la précédente',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      await tester.ensureVisible(find.text('Water Isolated Loop'));
+      await tester.tap(find.text('Water Isolated Loop'));
+      await tester.pump();
+      expect(find.text('Animation sélectionnée'), findsWidgets);
+      final t = tester
+          .widgetList<Text>(find.byType(Text))
+          .map((e) => e.data ?? '')
+          .join('\n');
+      expect(t.contains('Atlas sélectionné'), isFalse);
+    });
+
+    testWidgets('58.26 — sélection ne mute pas surfaceCatalog', (tester) async {
+      final cat = _minimalWaterCatalog();
+      final manifest = _manifest(cat);
+      final before = manifest.surfaceCatalog;
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      expect(identical(manifest.surfaceCatalog, before), isTrue);
+    });
+
+    testWidgets('58.27 — pas de TextField après sélections', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      expect(find.byType(TextField), findsNothing);
+    });
+
+    testWidgets('58.28 — pas de libellés édition/save actifs', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      for (final s in <String>[
+        'Sauvegarder',
+        'Enregistrer',
+        'Modifier',
+        'Supprimer',
+        'Save',
+        'Edit',
+        'Delete',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
+    testWidgets('59.20 — inspecteur none au départ', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Inspecteur Surface'), findsOneWidget);
+      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
+    });
+
+    testWidgets('59.21 — inspecteur atlas après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
+      expect(
+          find.descendant(of: insp, matching: find.text('Inspecteur Surface')),
+          findsOneWidget);
+      expect(
+        find.descendant(of: insp, matching: find.text('Atlas sélectionné')),
+        findsWidgets,
+      );
+      expect(
+        find.descendant(
+          of: insp,
+          matching: find.textContaining('Identifiant : water-atlas'),
+        ),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('59.22 — inspecteur animation après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Isolated Loop'));
+      await tester.tap(find.text('Water Isolated Loop'));
+      await tester.pump();
+      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
+      expect(
+        find.descendant(
+          of: insp,
+          matching: find.textContaining('Identifiant : water-isolated-loop'),
+        ),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('59.23 — inspecteur preset après tap', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
+      expect(
+        find.descendant(
+          of: insp,
+          matching: find.textContaining('Identifiant : water-surface'),
+        ),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('59.24 — changement de sélection met l’inspecteur à jour',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      await tester.ensureVisible(find.text('Water Isolated Loop'));
+      await tester.tap(find.text('Water Isolated Loop'));
+      await tester.pump();
+      final insp = find.byKey(kSurfaceStudioSelectionInspectorKey);
+      expect(
+        find.descendant(
+          of: insp,
+          matching: find.textContaining('Identifiant : water-isolated-loop'),
+        ),
+        findsOneWidget,
+      );
+      expect(
+        find.descendant(
+          of: insp,
+          matching: find.text('Atlas sélectionné'),
+        ),
+        findsNothing,
+      );
+    });
+
+    testWidgets('59.25 — inspecteur ne mute pas le manifest', (tester) async {
+      final cat = _minimalWaterCatalog();
+      final manifest = _manifest(cat);
+      final before = manifest.surfaceCatalog;
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      expect(identical(manifest.surfaceCatalog, before), isTrue);
+    });
+
+    testWidgets('59.26 — toujours aucun TextField après sélections', (
+      tester,
+    ) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Atlas'));
+      await tester.tap(find.text('Water Atlas'));
+      await tester.pump();
+      expect(find.byType(TextField), findsNothing);
+    });
+
+    testWidgets('59.27 — pas de libellés édition/save (Lot 59)',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      await tester.ensureVisible(find.text('Water Surface'));
+      await tester.tap(find.text('Water Surface'));
+      await tester.pump();
+      for (final s in <String>[
+        'Sauvegarder',
+        'Enregistrer',
+        'Modifier',
+        'Supprimer',
+        'Save',
+        'Edit',
+        'Delete',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
     testWidgets('30. Lot 55 — surfaceCatalog unchanged after panel pump',
         (tester) async {
       final cat = _minimalWaterCatalog();
```

## surface_studio_workspace_entry_test.dart

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
index 29e7f9c8..f144e828 100644
--- a/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
+++ b/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
@@ -100,7 +100,8 @@ void main() {
       await tester.tap(find.byKey(const Key('surface-studio-workspace-entry')));
       await tester.pumpAndSettle();
 
-      expect(find.text('Lecture seule'), findsOneWidget);
+      expect(find.text('Lecture seule'), findsNWidgets(2));
+      expect(find.text('Inspecteur Surface'), findsOneWidget);
       expect(find.byType(SurfaceStudioPanel), findsOneWidget);
       expect(find.text('Catalogue Surface'), findsOneWidget);
       expect(find.text('Atlas Surface'), findsOneWidget);
@@ -157,7 +158,7 @@ void main() {
       await tester.tap(find.byKey(const Key('surface-studio-workspace-entry')));
       await tester.pumpAndSettle();
 
-      expect(find.text('Lecture seule'), findsOneWidget);
+      expect(find.text('Lecture seule'), findsNWidgets(2));
     });
 
     testWidgets('panel shows 1/1/1 from manifest when catalog is minimal', (
@@ -233,6 +234,23 @@ void main() {
       expect(find.textContaining('Save Surface'), findsNothing);
     });
 
+    testWidgets('Lot 59 — Inspecteur Surface visible en mode workspace', (
+      tester,
+    ) async {
+      await pumpEditorShellPage(
+        tester,
+        initialState: EditorState(
+          projectRootPath: '/tmp/surface_lot59_insp',
+          project: _buildProjectWithSurfaceCatalog(
+            _minimalCoherentSurfaceCatalog(),
+          ),
+          workspaceMode: EditorWorkspaceMode.surfaceStudio,
+        ),
+      );
+      await tester.pumpAndSettle();
+      expect(find.text('Inspecteur Surface'), findsOneWidget);
+    });
+
     testWidgets('no internal type names in visible shell copy', (tester) async {
       await pumpEditorShellPage(
         tester,
```

# C. Diffs /dev/new — fichiers ajoutés (git diff --no-index)

## packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart

```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart
new file mode 100644
index 00000000..d87c3551
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart
@@ -0,0 +1,696 @@
+// Inspecteur Surface Studio (Lot 59) — **lecture seule**.
+//
+// Consomme [SurfaceStudioReadModel] + [SurfaceStudioSelection] : n’en déduit pas
+// de recalcul métier, ne mutera ni catalogue ni manifest, pas d’I/O, pas d’authoring
+// ici. Prépare les lots d’édition en affichant la même sémantique visuelle que les
+// fiches détail, dans une zone d’inspection unifiée.
+
+import 'package:flutter/cupertino.dart';
+import 'package:map_core/map_core.dart';
+
+import '../../ui/shared/cupertino_editor_widgets.dart';
+import 'surface_studio_animation_detail_view.dart';
+import 'surface_studio_atlas_detail_view.dart';
+import 'surface_studio_preset_detail_view.dart';
+import 'surface_studio_selection.dart';
+
+/// Textes d’en-tête (aucun nom de type produit en chaîne).
+class SurfaceStudioSelectionInspectorLabels {
+  const SurfaceStudioSelectionInspectorLabels._();
+
+  static const String title = 'Inspecteur Surface';
+  static const String readOnly = 'Lecture seule';
+  static const String noneTitle = 'Aucune sélection à inspecter';
+  static const String noneHint =
+      'Sélectionnez un atlas, une animation ou un preset pour afficher ses détails.';
+
+  static const String missingTitle = 'Sélection introuvable';
+  static const String missingBody =
+      'L’élément sélectionné n’existe plus dans le catalogue.';
+}
+
+const Color _kInspectorAccent = Color(0xFF2DD4BF);
+
+const ValueKey<String> kSurfaceStudioSelectionInspectorKey =
+    ValueKey<String>('SurfaceStudioSelectionInspector');
+
+/// Bloc d’inspection : résout la ligne de catalogue à partir de [selection] et
+/// affiche les champs dérivés tels qu’exposés par le read model.
+class SurfaceStudioSelectionInspector extends StatelessWidget {
+  const SurfaceStudioSelectionInspector({
+    super.key,
+    required this.readModel,
+    required this.selection,
+  });
+
+  final SurfaceStudioReadModel readModel;
+
+  final SurfaceStudioSelection selection;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    final subtle = EditorChrome.subtleLabel(context);
+    const accent = _kInspectorAccent;
+    return Container(
+      key: kSurfaceStudioSelectionInspectorKey,
+      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
+      decoration: BoxDecoration(
+        color: EditorChrome.elevatedPanelBackground(context),
+        borderRadius: BorderRadius.circular(14),
+        border: Border.all(
+          color: selection.isNone
+              ? EditorChrome.editorIslandRim(context)
+              : Color.lerp(
+                  EditorChrome.editorIslandRim(context),
+                  accent,
+                  0.4,
+                )!,
+          width: selection.isNone ? 1 : 1.15,
+        ),
+        boxShadow: EditorChrome.sectionCardShadows(context),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.start,
+        children: [
+          Row(
+            crossAxisAlignment: CrossAxisAlignment.start,
+            children: [
+              Expanded(
+                child: Text(
+                  SurfaceStudioSelectionInspectorLabels.title,
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 16,
+                    fontWeight: FontWeight.w800,
+                    letterSpacing: -0.2,
+                  ),
+                ),
+              ),
+              Container(
+                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+                decoration: BoxDecoration(
+                  color: Color.lerp(
+                    EditorChrome.islandFillElevated(context),
+                    accent,
+                    0.12,
+                  ),
+                  borderRadius: BorderRadius.circular(8),
+                  border: Border.all(
+                    color: accent.withValues(alpha: 0.45),
+                    width: 1,
+                  ),
+                ),
+                child: Text(
+                  SurfaceStudioSelectionInspectorLabels.readOnly,
+                  style: TextStyle(
+                    color: label,
+                    fontSize: 11,
+                    fontWeight: FontWeight.w700,
+                    letterSpacing: 0.2,
+                  ),
+                ),
+              ),
+            ],
+          ),
+          const SizedBox(height: 10),
+          if (selection.isNone) ...[
+            Text(
+              SurfaceStudioSelectionInspectorLabels.noneTitle,
+              style: TextStyle(
+                color: subtle,
+                fontSize: 14,
+                fontWeight: FontWeight.w600,
+                fontStyle: FontStyle.italic,
+              ),
+            ),
+            const SizedBox(height: 6),
+            Text(
+              SurfaceStudioSelectionInspectorLabels.noneHint,
+              style: TextStyle(
+                color: subtle,
+                fontSize: 12,
+                fontWeight: FontWeight.w500,
+                height: 1.35,
+              ),
+            ),
+          ] else
+            _InspectorBody(
+              readModel: readModel,
+              selection: selection,
+              label: label,
+              subtle: subtle,
+              accent: accent,
+            ),
+        ],
+      ),
+    );
+  }
+}
+
+class _InspectorBody extends StatelessWidget {
+  const _InspectorBody({
+    required this.readModel,
+    required this.selection,
+    required this.label,
+    required this.subtle,
+    required this.accent,
+  });
+
+  final SurfaceStudioReadModel readModel;
+  final SurfaceStudioSelection selection;
+  final Color label;
+  final Color subtle;
+  final Color accent;
+
+  @override
+  Widget build(BuildContext context) {
+    if (selection.isAtlas) {
+      final id = selection.id!;
+      final row = _atlasById(readModel, id);
+      if (row == null) {
+        return _MissingBlock(id: id, label: label, subtle: subtle);
+      }
+      return _AtlasInspect(
+        row: row,
+        label: label,
+        subtle: subtle,
+        accent: accent,
+      );
+    }
+    if (selection.isAnimation) {
+      final id = selection.id!;
+      final row = _animationById(readModel, id);
+      if (row == null) {
+        return _MissingBlock(id: id, label: label, subtle: subtle);
+      }
+      return _AnimationInspect(
+        row: row,
+        label: label,
+        subtle: subtle,
+        accent: accent,
+      );
+    }
+    if (selection.isPreset) {
+      final id = selection.id!;
+      final row = _presetById(readModel, id);
+      if (row == null) {
+        return _MissingBlock(id: id, label: label, subtle: subtle);
+      }
+      return _PresetInspect(
+        row: row,
+        label: label,
+        subtle: subtle,
+        accent: accent,
+      );
+    }
+    return const SizedBox.shrink();
+  }
+}
+
+class _MissingBlock extends StatelessWidget {
+  const _MissingBlock({
+    required this.id,
+    required this.label,
+    required this.subtle,
+  });
+
+  final String id;
+  final Color label;
+  final Color subtle;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Text(
+          SurfaceStudioSelectionInspectorLabels.missingTitle,
+          style: TextStyle(
+            color: label,
+            fontSize: 14,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        const SizedBox(height: 4),
+        Text(
+          SurfaceStudioSelectionInspectorLabels.missingBody,
+          style: TextStyle(
+            color: subtle,
+            fontSize: 12,
+            fontWeight: FontWeight.w500,
+            height: 1.3,
+          ),
+        ),
+        const SizedBox(height: 6),
+        Text(
+          id,
+          style: TextStyle(
+            color: label,
+            fontSize: 14,
+            fontWeight: FontWeight.w700,
+          ),
+        ),
+      ],
+    );
+  }
+}
+
+class _K extends StatelessWidget {
+  const _K({required this.k, required this.v, required this.valueColor});
+
+  final String k;
+  final String v;
+  final Color valueColor;
+
+  @override
+  Widget build(BuildContext context) {
+    return Padding(
+      padding: const EdgeInsets.only(top: 3),
+      child: Text(
+        '$k : $v',
+        style: TextStyle(
+          color: valueColor,
+          fontSize: 13,
+          fontWeight: FontWeight.w500,
+          height: 1.3,
+        ),
+      ),
+    );
+  }
+}
+
+SurfaceStudioAtlasReadModel? _atlasById(
+  SurfaceStudioReadModel m,
+  String id,
+) {
+  for (final a in m.atlases) {
+    if (a.id == id) {
+      return a;
+    }
+  }
+  return null;
+}
+
+SurfaceStudioAnimationReadModel? _animationById(
+  SurfaceStudioReadModel m,
+  String id,
+) {
+  for (final a in m.animations) {
+    if (a.id == id) {
+      return a;
+    }
+  }
+  return null;
+}
+
+SurfaceStudioPresetReadModel? _presetById(
+  SurfaceStudioReadModel m,
+  String id,
+) {
+  for (final p in m.presets) {
+    if (p.id == id) {
+      return p;
+    }
+  }
+  return null;
+}
+
+class _AtlasInspect extends StatelessWidget {
+  const _AtlasInspect({
+    required this.row,
+    required this.label,
+    required this.subtle,
+    required this.accent,
+  });
+
+  final SurfaceStudioAtlasReadModel row;
+  final Color label;
+  final Color subtle;
+  final Color accent;
+
+  @override
+  Widget build(BuildContext context) {
+    final nAnim = row.usedByAnimationIds.length;
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Text(
+          SurfaceStudioAtlasDetailViewLabels.badgeSelected,
+          style: TextStyle(
+            color: accent,
+            fontSize: 12,
+            fontWeight: FontWeight.w800,
+            letterSpacing: 0.2,
+          ),
+        ),
+        const SizedBox(height: 4),
+        Text(
+          row.name,
+          style: TextStyle(
+            color: label,
+            fontSize: 15,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        _K(
+          k: SurfaceStudioAtlasDetailViewLabels.labelIdentifiant,
+          v: row.id,
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAtlasDetailViewLabels.labelTileset,
+          v: row.tilesetId,
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAtlasDetailViewLabels.labelTile,
+          v: '${row.tileWidth}×${row.tileHeight}',
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAtlasDetailViewLabels.labelGrille,
+          v: '${row.columns}×${row.rows}',
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAtlasDetailViewLabels.labelTuiles,
+          v: SurfaceStudioAtlasDetailViewLabels.tileCountLigne(row.tileCount),
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAtlasDetailViewLabels.labelLayout,
+          v: SurfaceStudioAtlasDetailViewLabels.layoutHumain(row.layout),
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAtlasDetailViewLabels.labelCategorie,
+          v: row.categoryId == null || row.categoryId!.isEmpty
+              ? SurfaceStudioAtlasDetailViewLabels.categorieAucune
+              : row.categoryId!,
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAtlasDetailViewLabels.labelOrdre,
+          v: row.sortOrder.toString(),
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAtlasDetailViewLabels.labelUtilisation,
+          v: SurfaceStudioAtlasDetailViewLabels.utilisationLigne(nAnim),
+          valueColor: label,
+        ),
+        if (nAnim > 0) ...[
+          const SizedBox(height: 4),
+          Text(
+            SurfaceStudioAtlasDetailViewLabels.labelAnimationsUtilisatrices,
+            style: TextStyle(
+              color: subtle,
+              fontSize: 11,
+              fontWeight: FontWeight.w800,
+              letterSpacing: 0.4,
+            ),
+          ),
+          ...row.usedByAnimationIds.map(
+            (id) => Padding(
+              padding: const EdgeInsets.only(top: 2),
+              child: Text(
+                id,
+                style: TextStyle(
+                  color: label,
+                  fontSize: 13,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+            ),
+          ),
+        ],
+      ],
+    );
+  }
+}
+
+class _AnimationInspect extends StatelessWidget {
+  const _AnimationInspect({
+    required this.row,
+    required this.label,
+    required this.subtle,
+    required this.accent,
+  });
+
+  final SurfaceStudioAnimationReadModel row;
+  final Color label;
+  final Color subtle;
+  final Color accent;
+
+  @override
+  Widget build(BuildContext context) {
+    final refIds = row.referencedAtlasIds;
+    final nAtlas = refIds.length;
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Text(
+          SurfaceStudioAnimationDetailViewLabels.badgeSelected,
+          style: TextStyle(
+            color: accent,
+            fontSize: 12,
+            fontWeight: FontWeight.w800,
+            letterSpacing: 0.2,
+          ),
+        ),
+        const SizedBox(height: 4),
+        Text(
+          row.name,
+          style: TextStyle(
+            color: label,
+            fontSize: 15,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        _K(
+          k: SurfaceStudioAnimationDetailViewLabels.labelIdentifiant,
+          v: row.id,
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAnimationDetailViewLabels.labelFrames,
+          v: SurfaceStudioAnimationDetailViewLabels.framesLigne(
+            row.frameCount,
+          ),
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAnimationDetailViewLabels.labelDureeTotale,
+          v: '${row.totalDurationMs} ms',
+          valueColor: label,
+        ),
+        const SizedBox(height: 4),
+        Text(
+          SurfaceStudioAnimationDetailViewLabels.labelAtlasRef,
+          style: TextStyle(
+            color: subtle,
+            fontSize: 11,
+            fontWeight: FontWeight.w800,
+            letterSpacing: 0.4,
+          ),
+        ),
+        Padding(
+          padding: const EdgeInsets.only(top: 2),
+          child: Text(
+            SurfaceStudioAnimationDetailViewLabels.atlasRefSummary(nAtlas),
+            style: TextStyle(
+              color: label,
+              fontSize: 13,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+        ),
+        if (nAtlas > 0)
+          ...refIds.map(
+            (id) => Padding(
+              padding: const EdgeInsets.only(top: 2),
+              child: Text(
+                id,
+                style: TextStyle(
+                  color: label,
+                  fontSize: 13,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+            ),
+          ),
+        _K(
+          k: SurfaceStudioAnimationDetailViewLabels.labelSync,
+          v: row.syncGroupId == null || row.syncGroupId!.isEmpty
+              ? SurfaceStudioAnimationDetailViewLabels.syncAucun
+              : row.syncGroupId!,
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAnimationDetailViewLabels.labelCategorie,
+          v: row.categoryId == null || row.categoryId!.isEmpty
+              ? SurfaceStudioAnimationDetailViewLabels.categorieAucune
+              : row.categoryId!,
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioAnimationDetailViewLabels.labelOrdre,
+          v: row.sortOrder.toString(),
+          valueColor: label,
+        ),
+      ],
+    );
+  }
+}
+
+class _PresetInspect extends StatelessWidget {
+  const _PresetInspect({
+    required this.row,
+    required this.label,
+    required this.subtle,
+    required this.accent,
+  });
+
+  final SurfaceStudioPresetReadModel row;
+  final Color label;
+  final Color subtle;
+  final Color accent;
+
+  @override
+  Widget build(BuildContext context) {
+    final animIds = row.referencedAnimationIds;
+    final nAnim = animIds.length;
+    final roleLabels = row.roles.map(surfaceStudioSurfaceVariantRoleLabel);
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.start,
+      children: [
+        Text(
+          SurfaceStudioPresetDetailViewLabels.badgeSelected,
+          style: TextStyle(
+            color: accent,
+            fontSize: 12,
+            fontWeight: FontWeight.w800,
+            letterSpacing: 0.2,
+          ),
+        ),
+        const SizedBox(height: 4),
+        Text(
+          row.name,
+          style: TextStyle(
+            color: label,
+            fontSize: 15,
+            fontWeight: FontWeight.w800,
+          ),
+        ),
+        _K(
+          k: SurfaceStudioPresetDetailViewLabels.labelIdentifiant,
+          v: row.id,
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioPresetDetailViewLabels.labelVariantes,
+          v: SurfaceStudioPresetDetailViewLabels.variantesLigne(
+            row.variantCount,
+          ),
+          valueColor: label,
+        ),
+        const SizedBox(height: 4),
+        Text(
+          SurfaceStudioPresetDetailViewLabels.labelRoles,
+          style: TextStyle(
+            color: subtle,
+            fontSize: 11,
+            fontWeight: FontWeight.w800,
+            letterSpacing: 0.4,
+          ),
+        ),
+        ...roleLabels.map(
+          (r) => Padding(
+            padding: const EdgeInsets.only(top: 2),
+            child: Text(
+              r,
+              style: TextStyle(
+                color: label,
+                fontSize: 13,
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ),
+        ),
+        const SizedBox(height: 4),
+        Text(
+          SurfaceStudioPresetDetailViewLabels.labelAnimationsLiees,
+          style: TextStyle(
+            color: subtle,
+            fontSize: 11,
+            fontWeight: FontWeight.w800,
+            letterSpacing: 0.4,
+          ),
+        ),
+        Padding(
+          padding: const EdgeInsets.only(top: 2),
+          child: Text(
+            SurfaceStudioPresetDetailViewLabels.animationsLieesSummary(
+              nAnim,
+            ),
+            style: TextStyle(
+              color: label,
+              fontSize: 13,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+        ),
+        if (nAnim > 0)
+          ...animIds.map(
+            (id) => Padding(
+              padding: const EdgeInsets.only(top: 2),
+              child: Text(
+                id,
+                style: TextStyle(
+                  color: label,
+                  fontSize: 13,
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+            ),
+          ),
+        const SizedBox(height: 4),
+        Text(
+          SurfaceStudioPresetDetailViewLabels.labelCouverture,
+          style: TextStyle(
+            color: subtle,
+            fontSize: 11,
+            fontWeight: FontWeight.w800,
+            letterSpacing: 0.4,
+          ),
+        ),
+        Padding(
+          padding: const EdgeInsets.only(top: 2),
+          child: Text(
+            row.coversStandardRoles
+                ? SurfaceStudioPresetDetailViewLabels.couverturePleine
+                : SurfaceStudioPresetDetailViewLabels.couverturePartielle,
+            style: TextStyle(
+              color: label,
+              fontSize: 13,
+              fontWeight: FontWeight.w600,
+            ),
+          ),
+        ),
+        _K(
+          k: SurfaceStudioPresetDetailViewLabels.labelCategorie,
+          v: row.categoryId == null || row.categoryId!.isEmpty
+              ? SurfaceStudioPresetDetailViewLabels.categorieAucune
+              : row.categoryId!,
+          valueColor: label,
+        ),
+        _K(
+          k: SurfaceStudioPresetDetailViewLabels.labelOrdre,
+          v: row.sortOrder.toString(),
+          valueColor: label,
+        ),
+      ],
+    );
+  }
+}
```

## packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart

```diff
diff --git a/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart b/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
new file mode 100644
index 00000000..fa5cb6de
--- /dev/null
+++ b/Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
@@ -0,0 +1,391 @@
+// Tests widget — [SurfaceStudioSelectionInspector] (Lot 59).
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_selection_inspector.dart';
+
+void main() {
+  group('SurfaceStudioSelectionInspector (Lot 59)', () {
+    testWidgets('1. titre Inspecteur Surface', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      expect(find.text('Inspecteur Surface'), findsOneWidget);
+    });
+
+    testWidgets('2. badge Lecture seule', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      expect(find.text('Lecture seule'), findsOneWidget);
+    });
+
+    testWidgets('3. état none', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
+      expect(
+        find.textContaining('Sélectionnez un atlas'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('4. atlas introuvable', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.atlas('missing-atlas'),
+          ),
+        ),
+      );
+      expect(find.text('Sélection introuvable'), findsOneWidget);
+      expect(find.text('missing-atlas'), findsOneWidget);
+    });
+
+    testWidgets('5. animation introuvable', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.animation('missing-animation'),
+          ),
+        ),
+      );
+      expect(find.text('missing-animation'), findsOneWidget);
+    });
+
+    testWidgets('6. preset introuvable', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.preset('missing-preset'),
+          ),
+        ),
+      );
+      expect(find.text('missing-preset'), findsOneWidget);
+    });
+
+    testWidgets('7–9. atlas sélectionné — identité et champs', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.atlas('water-atlas'),
+          ),
+        ),
+      );
+      expect(find.text('Atlas sélectionné'), findsWidgets);
+      expect(find.text('Water Atlas'), findsOneWidget);
+      expect(
+        find.textContaining('Identifiant : water-atlas'),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('Tileset : nature-tileset'),
+        findsOneWidget,
+      );
+      expect(find.textContaining('Tile : 32×32'), findsOneWidget);
+      expect(find.textContaining('Grille : 2×2'), findsOneWidget);
+      expect(find.textContaining('4 tuiles'), findsOneWidget);
+      expect(
+        find.textContaining('Colonnes = variantes, lignes = frames'),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('Catégorie : Aucune catégorie'),
+        findsOneWidget,
+      );
+      expect(find.textContaining('Ordre : 0'), findsOneWidget);
+      expect(
+        find.textContaining('Utilisé par 1 animation'),
+        findsOneWidget,
+      );
+      expect(find.text('water-isolated-loop'), findsWidgets);
+    });
+
+    testWidgets('10–11. animation sélectionnée', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.animation('water-isolated-loop'),
+          ),
+        ),
+      );
+      expect(find.text('Animation sélectionnée'), findsWidgets);
+      expect(find.text('Water Isolated Loop'), findsOneWidget);
+      expect(
+        find.textContaining('Identifiant : water-isolated-loop'),
+        findsOneWidget,
+      );
+      expect(find.textContaining('Frames : 1 frame'), findsOneWidget);
+      expect(
+        find.textContaining('Durée totale : 120 ms'),
+        findsOneWidget,
+      );
+      expect(find.text('water-atlas'), findsWidgets);
+      expect(
+        find.textContaining('Groupe de synchronisation : Aucun groupe'),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('Catégorie : Aucune catégorie'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('12–13. preset sélectionné', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.preset('water-surface'),
+          ),
+        ),
+      );
+      expect(find.text('Preset sélectionné'), findsWidgets);
+      expect(find.text('Water Surface'), findsOneWidget);
+      expect(
+        find.textContaining('Identifiant : water-surface'),
+        findsOneWidget,
+      );
+      expect(find.textContaining('Variantes : 1 variante'), findsOneWidget);
+      expect(find.text('Isolé'), findsWidgets);
+      expect(
+        find.textContaining('Rôles standards incomplets'),
+        findsOneWidget,
+      );
+      expect(
+        find.textContaining('Catégorie : Aucune catégorie'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('14. pas de TextField', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.atlas('water-atlas'),
+          ),
+        ),
+      );
+      expect(find.byType(TextField), findsNothing);
+    });
+
+    testWidgets('15. pas de libellés édition / save', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.preset('water-surface'),
+          ),
+        ),
+      );
+      for (final s in <String>[
+        'Modifier',
+        'Supprimer',
+        'Enregistrer',
+        'Sauvegarder',
+        'Save',
+        'Edit',
+        'Delete',
+      ]) {
+        expect(find.text(s), findsNothing);
+      }
+    });
+
+    testWidgets('16. pas de noms de types internes en texte', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: SurfaceStudioSelection.atlas('water-atlas'),
+          ),
+        ),
+      );
+      for (final term in <String>[
+        'ProjectSurfaceCatalog',
+        'ProjectSurfaceAtlas',
+        'ProjectSurfaceAnimation',
+        'ProjectSurfacePreset',
+        'SurfaceStudioReadModel',
+        'SurfaceStudioSelection',
+        'SurfaceStudioSelectionInspector',
+        'SurfaceVariantAnimationRefSet',
+        'SurfaceAnimationTimeline',
+      ]) {
+        expect(
+          find.descendant(
+            of: find.byKey(kSurfaceStudioSelectionInspectorKey),
+            matching: find.textContaining(term),
+          ),
+          findsNothing,
+        );
+      }
+    });
+
+    testWidgets('17. sans ProviderScope', (tester) async {
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: _minimalRead(),
+            selection: const SurfaceStudioSelection.none(),
+          ),
+        ),
+      );
+      expect(find.text('Aucune sélection à inspecter'), findsOneWidget);
+    });
+
+    testWidgets('18. largeur contrainte', (tester) async {
+      await tester.pumpWidget(
+        MaterialApp(
+          home: Center(
+            child: SizedBox(
+              width: 320,
+              child: SurfaceStudioSelectionInspector(
+                readModel: _minimalRead(),
+                selection: SurfaceStudioSelection.preset('water-surface'),
+              ),
+            ),
+          ),
+        ),
+      );
+      expect(find.text('Water Surface'), findsOneWidget);
+    });
+
+    testWidgets('19. read model avec diagnostics, sélection valide', (
+      tester,
+    ) async {
+      final rm = buildSurfaceStudioReadModelFromCatalog(
+        _catalogWithUnusedAtlas(),
+      );
+      expect(rm.diagnostics.hasErrors, isFalse);
+      await tester.pumpWidget(
+        _wrap(
+          SurfaceStudioSelectionInspector(
+            readModel: rm,
+            selection: SurfaceStudioSelection.atlas('used-atlas'),
+          ),
+        ),
+      );
+      expect(tester.takeException(), isNull);
+      expect(
+        find.descendant(
+          of: find.byKey(kSurfaceStudioSelectionInspectorKey),
+          matching: find.text('Diagnostics Surface'),
+        ),
+        findsNothing,
+      );
+    });
+  });
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: SingleChildScrollView(
+      child: Padding(
+        padding: const EdgeInsets.all(20),
+        child: child,
+      ),
+    ),
+  );
+}
+
+SurfaceStudioReadModel _minimalRead() {
+  return buildSurfaceStudioReadModelFromCatalog(_minimalCatalog());
+}
+
+ProjectSurfaceCatalog _minimalCatalog() {
+  final g = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final atlas = ProjectSurfaceAtlas(
+    id: 'water-atlas',
+    name: 'Water Atlas',
+    tilesetId: 'nature-tileset',
+    geometry: g,
+  );
+  final frame = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'water-atlas', column: 0, row: 0),
+    durationMs: 120,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'water-isolated-loop',
+    name: 'Water Isolated Loop',
+    timeline: SurfaceAnimationTimeline(frames: [frame]),
+  );
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: [
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'water-isolated-loop',
+      ),
+    ],
+  );
+  final preset = ProjectSurfacePreset(
+    id: 'water-surface',
+    name: 'Water Surface',
+    variantAnimations: refs,
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [atlas],
+    animations: [anim],
+    presets: [preset],
+  );
+}
+
+/// Catalogue avec atlas inutilisé (avertissements, pas d’erreur bloquante).
+ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
+  final g = SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+  final used = ProjectSurfaceAtlas(
+    id: 'used-atlas',
+    name: 'U',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final unused = ProjectSurfaceAtlas(
+    id: 'orphan-atlas',
+    name: 'O',
+    tilesetId: 't',
+    geometry: g,
+  );
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(atlasId: 'used-atlas', column: 0, row: 0),
+    durationMs: 10,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'a',
+    name: 'a',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [used, unused],
+    animations: [anim],
+    presets: const [],
+  );
+}
```

# D. git status final

```
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_animation_detail_view.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_atlas_detail_view.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_catalog_browser.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
 M packages/map_editor/lib/src/features/surface_studio/surface_studio_preset_detail_view.dart
 M packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
 M packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_selection.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_inspector.dart
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_selection_summary.dart
?? packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_selection_interaction_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart
?? packages/map_editor/test/surface_studio/surface_studio_selection_test.dart
?? packages/project_overview_pokemon_project.txt
?? reports/surface/surface_engine_lot_58_surface_studio_selection_state.md
?? reports/surface/surface_engine_lot_59_surface_studio_selection_inspector.md
```

**Hors périmètre Lot 59** : `packages/project_overview_pokemon_project.txt` (non créé par ce lot ; entrée non suivie au moment de la capture).

**Total des tests lancés en suite complète** : la commande `flutter test` sans argument exécute l’ensemble des fichiers de test du package ; la sortie de synthèse ci-dessus indique **+690** tests comptés avec **-41** échecs (compilation).
