# Surface Engine — Lot 36 — Surface Catalog Authoring Diagnostics Aggregator V0

## 1. Résumé exécutif

Ajout de `diagnoseProjectSurfaceCatalogForAuthoring` : concaténation **non persistante** des rapports d'erreur (Lot 34) et d'avertissements (Lot 35) en un seul `SurfaceCatalogDiagnosticsReport`. Fichier d'opération dédié, export public `map_core`, 20 tests, aucun changement Freezed ni manifeste.

## 2. Position après le Lot 35-bis

Le 35-bis a complété la preuve du 35. Le 36 ajoute un point d'entrée auteur (agrégation) **sans** modifier les implémentations 34/35.

## 3. Fichiers consultés (audit)

- `packages/map_core/lib/src/operations/surface_catalog_diagnostics.dart`
- `packages/map_core/test/surface_catalog_diagnostics_test.dart`
- `packages/map_core/test/surface_catalog_unused_diagnostics_test.dart`
- `packages/map_core/lib/src/models/surface_catalog.dart`, `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- Rapports Surface 34, 34b, 35, 35b

## 4. Fichiers créés

- `packages/map_core/lib/src/operations/surface_catalog_authoring_diagnostics.dart`
- `packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart`
- `reports/surface/surface_engine_lot_36_surface_catalog_authoring_diagnostics.md` (le présent document)

## 5. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` (ligne d'export ajoutée)

## 6. API ajoutée

`SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalogForAuthoring(ProjectSurfaceCatalog catalog)`

## 7. Sémantique

Lecture seule. Appels successifs : `diagnoseProjectSurfaceCatalog(catalog)` puis `diagnoseProjectSurfaceCatalogUnusedResources(catalog)`. Liste fusionnée : `[...errors.diagnostics, ...warnings.diagnostics]`. Pas de revalidation côté manifeste, pas d'I/O, pas de mutation du catalogue.

## 8. Ordre de concaténation

Tous les diagnostics d'erreur (ordre Lot 34) puis tous les avertissements (ordre Lot 35).

## 9. Décision : pas de déduplication

Aucun filtrage, aucune logique heuristique (ex. masquer un `unusedAnimation` en présence d'`missingAnimationAtlas` sur la même cible). Les entrées s'additionnent.

## 10. Décision : lots 34 / 35 non modifiés

Les sources des deux rapports de base restent inchangées en Lot 36.

## 11. Aucun nouveau kind ni severity

L'agrégateur réutilise exclusivement l'existant.

## 12. Décision : pas de `unusedPreset` (kind)

Aucun ajout d'énumération.

## 13. `ProjectSurfaceCatalog`

Seule entrée, passée telle quelle aux mêmes fonctions qu'aux lots précédents.

## 14. `ProjectManifest` (perspective)

Aucun lien de persistance ; les diagnostics restent en mémoire.

## 15. Couverture de tests

`test/surface_catalog_authoring_diagnostics_test.dart` : 20 scénarios couvrant concurrence vide/cohérent, erreur seule, avertissements, ordre global, non-dedup, `byKind`, immuabilité, invariants 34/35, manifest minimal, noms d'énum.

## 16. Propriétés prouvées

Ordre stricte erreurs → warnings, `hasErrors` aligné sur la présence d'au moins un diagnostic `error`, cohabitation d'une erreur et d'un warning sur le même nœud logique, export `map_core`, pas de clés `surface*` au niveau `toJson` du manifeste minimal, absence du nom `unusedPreset` dans `SurfaceCatalogDiagnosticKind.values`, severities = `error` + `warning` uniquement.

## 17. Non réalisé volontairement

JSON, Freezed, `build_runner`, runtime, éditeur, battle, migration.

## 18. `ProjectManifest` : pourquoi inchangé

Hors cahier des charges Surface persistant de ce lot.

## 19. Aucun fichier généré

Aucun modèle `*.g.dart` / `*.freezed.dart` modifié.

## 20. `SurfacePresetKind` / `surfaceKind`

Aucun ajout.

## 21. `unusedPreset`

Aucun kind éponyme (test 20 sur les noms d'énum).

## 22. Impact lots suivants

Panneau auteur unifié possible ; vues ciblées 34/35 toujours disponibles.

## 23. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_catalog_authoring_diagnostics_test.dart
```
```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_test.dart
```
```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_catalog_unused_diagnostics_test.dart
```
```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze   lib/src/operations/surface_catalog_authoring_diagnostics.dart   lib/src/operations/surface_catalog_diagnostics.dart   lib/src/models/surface_catalog.dart   lib/src/models/surface.dart   lib/src/operations/standard_surface_preset_builder.dart   test/surface_catalog_authoring_diagnostics_test.dart   test/surface_catalog_unused_diagnostics_test.dart   test/surface_catalog_diagnostics_test.dart   test/project_surface_catalog_test.dart   test/standard_surface_preset_builder_test.dart   test/project_surface_preset_test.dart   test/project_surface_animation_test.dart   test/project_surface_atlas_test.dart   lib/map_core.dart
```
```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```


## 24. Résultat : test ciblé Lot 36 (sortie intégrale)

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_authoring_diagnostics_test.dart[0m[0m                                                                                                                                 
00:00 [32m+0[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 1. empty catalog: no diagnostics[0m                                                                                                          
00:00 [32m+1[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 1. empty catalog: no diagnostics[0m                                                                                                          
00:00 [32m+1[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 2. minimal coherent: no diagnostics[0m                                                                                                       
00:00 [32m+2[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 2. minimal coherent: no diagnostics[0m                                                                                                       
00:00 [32m+2[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 3. error only: missing preset animation[0m                                                                                                   
00:00 [32m+3[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 3. error only: missing preset animation[0m                                                                                                   
00:00 [32m+3[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 4. warning only: unused atlas[0m                                                                                                             
00:00 [32m+4[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 4. warning only: unused atlas[0m                                                                                                             
00:00 [32m+4[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 5. warning only: unused animation, no unusedAtlas[0m                                                                                         
00:00 [32m+5[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 5. warning only: unused animation, no unusedAtlas[0m                                                                                         
00:00 [32m+5[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 6. error + warnings: order errors then unusedAtlas then unusedAnimation[0m                                                                   
00:00 [32m+6[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 6. error + warnings: order errors then unusedAtlas then unusedAnimation[0m                                                                   
00:00 [32m+6[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 7. two preset errors: Lot 34 order preserved at start of report[0m                                                                           
00:00 [32m+7[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 7. two preset errors: Lot 34 order preserved at start of report[0m                                                                           
00:00 [32m+7[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 8. many unusedAtlas then many unusedAnimation: Lot 35 order in tail[0m                                                                       
00:00 [32m+8[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 8. many unusedAtlas then many unusedAnimation: Lot 35 order in tail[0m                                                                       
00:00 [32m+8[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 9. no dedup: missingAnimationAtlas + unusedAnimation same anim[0m                                                                            
00:00 [32m+9[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 9. no dedup: missingAnimationAtlas + unusedAnimation same anim[0m                                                                            
00:00 [32m+9[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 10. warnings only: hasErrors false[0m                                                                                                        
00:00 [32m+10[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 10. warnings only: hasErrors false[0m                                                                                                       
00:00 [32m+10[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 11. errors + warnings: hasErrors true[0m                                                                                                    
00:00 [32m+11[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 11. errors + warnings: hasErrors true[0m                                                                                                    
00:00 [32m+11[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 12. byKind on combined report[0m                                                                                                            
00:00 [32m+12[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 12. byKind on combined report[0m                                                                                                            
00:00 [32m+12[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 13. diagnostics list is unmodifiable[0m                                                                                                     
00:00 [32m+13[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 13. diagnostics list is unmodifiable[0m                                                                                                     
00:00 [32m+13[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 14. catalog lists unchanged after call[0m                                                                                                   
00:00 [32m+14[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 14. catalog lists unchanged after call[0m                                                                                                   
00:00 [32m+14[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 15. Lot 34 alone: no unusedAtlas for orphan atlas[0m                                                                                        
00:00 [32m+15[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 15. Lot 34 alone: no unusedAtlas for orphan atlas[0m                                                                                        
00:00 [32m+15[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 16. Lot 35 alone: no missingPresetAnimation for broken ref[0m                                                                               
00:00 [32m+16[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 16. Lot 35 alone: no missingPresetAnimation for broken ref[0m                                                                               
00:00 [32m+16[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 17. V0: coherent preset, no spurious preset-targeted unused rule[0m                                                                         
00:00 [32m+17[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 17. V0: coherent preset, no spurious preset-targeted unused rule[0m                                                                         
00:00 [32m+17[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 18. public API via map_core[0m                                                                                                              
00:00 [32m+18[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 18. public API via map_core[0m                                                                                                              
00:00 [32m+18[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 19. ProjectManifest still has no Surface keys (Lot 36)[0m                                                                                   
00:00 [32m+19[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 19. ProjectManifest still has no Surface keys (Lot 36)[0m                                                                                   
00:00 [32m+19[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 20. no unusedPreset kind; severities are error and warning only[0m                                                                          
00:00 [32m+20[0m: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 20. no unusedPreset kind; severities are error and warning only[0m                                                                          
00:00 [32m+20[0m: All tests passed![0m                                                                                                                                                                           
```

## 25. Résultat : tests de régression

### `surface_catalog_diagnostics_test.dart` (intégral)

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_diagnostics_test.dart[0m[0m                                                                                                                                           
00:00 [32m+0[0m: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                                                                      
00:00 [32m+1[0m: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                                                                      
00:00 [32m+1[0m: diagnoseProjectSurfaceCatalog (Lot 34) 2. minimal coherent: no diagnostics[0m                                                                                                                   
00:00 [32m+2[0m: diagnoseProjectSurfaceCatalog (Lot 34) 2. minimal coherent: no diagnostics[0m                                                                                                                   
00:00 [32m+2[0m: diagnoseProjectSurfaceCatalog (Lot 34) 3. missing preset animation[0m                                                                                                                           
00:00 [32m+3[0m: diagnoseProjectSurfaceCatalog (Lot 34) 3. missing preset animation[0m                                                                                                                           
00:00 [32m+3[0m: diagnoseProjectSurfaceCatalog (Lot 34) 4. two missing refs: order follows refs[0m                                                                                                               
00:00 [32m+4[0m: diagnoseProjectSurfaceCatalog (Lot 34) 4. two missing refs: order follows refs[0m                                                                                                               
00:00 [32m+4[0m: diagnoseProjectSurfaceCatalog (Lot 34) 5. two presets: order follows catalog.presets[0m                                                                                                         
00:00 [32m+5[0m: diagnoseProjectSurfaceCatalog (Lot 34) 5. two presets: order follows catalog.presets[0m                                                                                                         
00:00 [32m+5[0m: diagnoseProjectSurfaceCatalog (Lot 34) 6. missing animation atlas[0m                                                                                                                            
00:00 [32m+6[0m: diagnoseProjectSurfaceCatalog (Lot 34) 6. missing animation atlas[0m                                                                                                                            
00:00 [32m+6[0m: diagnoseProjectSurfaceCatalog (Lot 34) 7. two frames to missing atlas: frameIndex 0 and 1[0m                                                                                                    
00:00 [32m+7[0m: diagnoseProjectSurfaceCatalog (Lot 34) 7. two frames to missing atlas: frameIndex 0 and 1[0m                                                                                                    
00:00 [32m+7[0m: diagnoseProjectSurfaceCatalog (Lot 34) 8. frame outside geometry: column[0m                                                                                                                     
00:00 [32m+8[0m: diagnoseProjectSurfaceCatalog (Lot 34) 8. frame outside geometry: column[0m                                                                                                                     
00:00 [32m+8[0m: diagnoseProjectSurfaceCatalog (Lot 34) 9. frame outside geometry: row[0m                                                                                                                        
00:00 [32m+9[0m: diagnoseProjectSurfaceCatalog (Lot 34) 9. frame outside geometry: row[0m                                                                                                                        
00:00 [32m+9[0m: diagnoseProjectSurfaceCatalog (Lot 34) 10. missing atlas only: not also outside geometry[0m                                                                                                     
00:00 [32m+10[0m: diagnoseProjectSurfaceCatalog (Lot 34) 10. missing atlas only: not also outside geometry[0m                                                                                                    
00:00 [32m+10[0m: diagnoseProjectSurfaceCatalog (Lot 34) 11. preset diagnostics then animation diagnostics[0m                                                                                                    
00:00 [32m+11[0m: diagnoseProjectSurfaceCatalog (Lot 34) 11. preset diagnostics then animation diagnostics[0m                                                                                                    
00:00 [32m+11[0m: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim[0m                                                                                                                          
00:00 [32m+12[0m: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim[0m                                                                                                                          
00:00 [32m+12[0m: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters[0m                                                                                                                                   
00:00 [32m+13[0m: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters[0m                                                                                                                                   
00:00 [32m+13[0m: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable[0m                                                                                                                      
00:00 [32m+14[0m: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable[0m                                                                                                                      
00:00 [32m+14[0m: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable[0m                                                                                                       
00:00 [32m+15[0m: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable[0m                                                                                                       
00:00 [32m+15[0m: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report[0m                                                                                      
00:00 [32m+16[0m: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report[0m                                                                                      
00:00 [32m+16[0m: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report[0m                                                                                                                  
00:00 [32m+17[0m: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report[0m                                                                                                                  
00:00 [32m+17[0m: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic[0m                                                                                                             
00:00 [32m+18[0m: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic[0m                                                                                                             
00:00 [32m+18[0m: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                                                                        
00:00 [32m+19[0m: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                                                                        
00:00 [32m+19[0m: diagnoseProjectSurfaceCatalog (Lot 34) 20. diagnostic equality: different kind[0m                                                                                                              
00:00 [32m+20[0m: diagnoseProjectSurfaceCatalog (Lot 34) 20. diagnostic equality: different kind[0m                                                                                                              
00:00 [32m+20[0m: diagnoseProjectSurfaceCatalog (Lot 34) 21. diagnostic equality: different metadata[0m                                                                                                          
00:00 [32m+21[0m: diagnoseProjectSurfaceCatalog (Lot 34) 21. diagnostic equality: different metadata[0m                                                                                                          
00:00 [32m+21[0m: diagnoseProjectSurfaceCatalog (Lot 34) 22. report equality: same order[0m                                                                                                                      
00:00 [32m+22[0m: diagnoseProjectSurfaceCatalog (Lot 34) 22. report equality: same order[0m                                                                                                                      
00:00 [32m+22[0m: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters[0m                                                                                                                   
00:00 [32m+23[0m: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters[0m                                                                                                                   
00:00 [32m+23[0m: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core[0m                                                                                                                          
00:00 [32m+24[0m: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core[0m                                                                                                                          
00:00 [32m+24[0m: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                                                               
00:00 [32m+25[0m: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                                                               
00:00 [32m+25[0m: All tests passed![0m                                                                                                                                                                           
```

### `surface_catalog_unused_diagnostics_test.dart` (intégral)

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_unused_diagnostics_test.dart[0m[0m                                                                                                                                    
00:00 [32m+0[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                                                                                
00:00 [32m+1[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                                                                                
00:00 [32m+1[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                                                                             
00:00 [32m+2[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                                                                             
00:00 [32m+2[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata[0m                                                                               
00:00 [32m+3[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata[0m                                                                               
00:00 [32m+3[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c[0m                                                                        
00:00 [32m+4[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c[0m                                                                        
00:00 [32m+4[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)[0m                                                                      
00:00 [32m+5[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)[0m                                                                      
00:00 [32m+5[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 6. atlas id exact: spaced atlas not matched by frame atlasId[0m                                                                           
00:00 [32m+6[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 6. atlas id exact: spaced atlas not matched by frame atlasId[0m                                                                           
00:00 [32m+6[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 7. animation not referenced by preset → unusedAnimation[0m                                                                                
00:00 [32m+7[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 7. animation not referenced by preset → unusedAnimation[0m                                                                                
00:00 [32m+7[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c[0m                                                                  
00:00 [32m+8[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c[0m                                                                  
00:00 [32m+8[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 9. animation referenced by a preset: not unused[0m                                                                                        
00:00 [32m+9[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 9. animation referenced by a preset: not unused[0m                                                                                        
00:00 [32m+9[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref[0m                                                                             
00:00 [32m+10[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref[0m                                                                            
00:00 [32m+10[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused[0m                                                                              
00:00 [32m+11[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused[0m                                                                              
00:00 [32m+11[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused[0m                                                                         
00:00 [32m+12[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused[0m                                                                         
00:00 [32m+12[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation[0m                                                                                  
00:00 [32m+13[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation[0m                                                                                  
00:00 [32m+13[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true[0m                                                                               
00:00 [32m+14[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true[0m                                                                               
00:00 [32m+14[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings[0m                                                                                           
00:00 [32m+15[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings[0m                                                                                           
00:00 [32m+15[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings[0m                                                                                   
00:00 [32m+16[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings[0m                                                                                   
00:00 [32m+16[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)[0m                                                                      
00:00 [32m+17[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)[0m                                                                      
00:00 [32m+17[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)[0m                                                                         
00:00 [32m+18[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)[0m                                                                         
00:00 [32m+18[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds[0m                                                                                  
00:00 [32m+19[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds[0m                                                                                  
00:00 [32m+19[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors[0m                                                                         
00:00 [32m+20[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors[0m                                                                         
00:00 [32m+20[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error[0m                                                                                    
00:00 [32m+21[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error[0m                                                                                    
00:00 [32m+21[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId[0m                                                           
00:00 [32m+22[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId[0m                                                           
00:00 [32m+22[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only[0m                                                                                      
00:00 [32m+23[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only[0m                                                                                      
00:00 [32m+23[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 24. ProjectManifest still has no Surface keys (Lot 35)[0m                                                                                
00:00 [32m+24[0m: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 24. ProjectManifest still has no Surface keys (Lot 35)[0m                                                                                
00:00 [32m+24[0m: All tests passed![0m                                                                                                                                                                           
```

## 26. Résultat : `dart analyze` (intégral)

```text
Analyzing surface_catalog_authoring_diagnostics.dart, surface_catalog_diagnostics.dart, surface_catalog.dart, surface.dart, standard_surface_preset_builder.dart, surface_catalog_authoring_diagnostics_test.dart, surface_catalog_unused_diagnostics_test.dart, surface_catalog_diagnostics_test.dart, project_surface_catalog_test.dart, standard_surface_preset_builder_test.dart, project_surface_preset_test.dart, project_surface_animation_test.dart, project_surface_atlas_test.dart, map_core.dart...
No issues found!
```

## 27. `dart test` (suite `map_core` complète)

Commande exécutée :

```text
cd packages/map_core
/opt/homebrew/bin/dart test
```

Dernière ligne de sortie (séparateur de progression : `tr` sur retour chariot) :

```text
00:01 [32m+827[0m: All tests passed![0m```

## 28. Nombre total de tests

**827** (ligne de sortie : `+827`).

## 29. Points de vigilance

- Rapport potentiellement long côté UI
- Pédagogie : l'auteur distingue `error` / `warning` via `hasErrors` + `byKind` / `severity`

## 30. Autocritique

- Un panneau pourrait plier les sections avertissements

## 31. Analyse du prompt (angles ambigus)

Aucune ambiguïté bloquante sur l'ordre de concaténation stricte.

## 32. Evidence Pack complet

### 32.A — Contenu intégral des fichiers créés

#### `packages/map_core/lib/src/operations/surface_catalog_authoring_diagnostics.dart`

```dart
// Surface catalog authoring — agrégation non persistante (Lot 36).
//
// Ce module fournit [diagnoseProjectSurfaceCatalogForAuthoring], un point
// d'entrée **confort** pour l'auteur (éditeur) : un seul rapport combinant
// les **erreurs** de cohérence (Lot 34, [diagnoseProjectSurfaceCatalog]) et
// les **avertissements** d'inutilisation (Lot 35,
// [diagnoseProjectSurfaceCatalogUnusedResources]).
//
// * Ne remplace **pas** les deux fonctions spécialisées : elles restent la
//   source de vérité pour un axe diagnostic isolé.
// * Ordre **volontaire** : d'abord toutes les entrées d'erreur (ordre interne
//   du Lot 34 inchangé), puis toutes les entrées d'avertissement (ordre interne
//   du Lot 35 inchangé).
// * **Aucune** déduplication, **aucune** fusion de messages, **aucun** re-tri.

import '../models/surface_catalog.dart';
import 'surface_catalog_diagnostics.dart';

/// Retourne un [SurfaceCatalogDiagnosticsReport] **auteur** : concaténation
/// des diagnostics d'[diagnoseProjectSurfaceCatalog] puis de
/// [diagnoseProjectSurfaceCatalogUnusedResources], **sans** mutation du
/// [ProjectSurfaceCatalog] et **sans** remplacer un validateur projet complet.
SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalogForAuthoring(
  ProjectSurfaceCatalog catalog,
) {
  final errors = diagnoseProjectSurfaceCatalog(catalog);
  final warnings = diagnoseProjectSurfaceCatalogUnusedResources(catalog);
  return SurfaceCatalogDiagnosticsReport(
    diagnostics: [
      ...errors.diagnostics,
      ...warnings.diagnostics,
    ],
  );
}
```

#### `packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAtlasGeometry _geom({int columns = 2, int rows = 2}) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _atlas(
  String id, {
  int columns = 2,
  int rows = 2,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: 'n-$id',
    tilesetId: 'ts',
    geometry: _geom(columns: columns, rows: rows),
  );
}

SurfaceAnimationFrame _frame(String atlasId, int column, int row) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: 1,
  );
}

ProjectSurfaceAnimation _animation(
  String id, {
  String atlasId = 'atlas',
  List<SurfaceAnimationFrame>? frames,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: 'a-$id',
    timeline: SurfaceAnimationTimeline(
      frames: frames ?? [_frame(atlasId, 0, 0)],
    ),
  );
}

SurfaceVariantAnimationRef _ref(SurfaceVariantRole role, String animationId) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}

ProjectSurfacePreset _preset(String id, List<SurfaceVariantAnimationRef> refs) {
  return ProjectSurfacePreset(
    id: id,
    name: 'p-$id',
    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
  );
}

ProjectSurfaceCatalog _catalog({
  List<ProjectSurfaceAtlas>? atlases,
  List<ProjectSurfaceAnimation>? animations,
  List<ProjectSurfacePreset>? presets,
}) {
  return ProjectSurfaceCatalog(
    atlases: atlases ?? const [],
    animations: animations ?? const [],
    presets: presets ?? const [],
  );
}

void main() {
  group('diagnoseProjectSurfaceCatalogForAuthoring (Lot 36)', () {
    test('1. empty catalog: no diagnostics', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(_catalog());
      expect(r.count, 0);
      expect(r.hasDiagnostics, isFalse);
      expect(r.hasErrors, isFalse);
      expect(r.diagnostics, isEmpty);
    });

    test('2. minimal coherent: no diagnostics', () {
      final atlas = _atlas('atlas');
      final anim = _animation('anim', atlasId: 'atlas');
      final preset = _preset('preset', [
        _ref(SurfaceVariantRole.isolated, 'anim'),
      ]);
      final c = _catalog(
        atlases: [atlas],
        animations: [anim],
        presets: [preset],
      );
      final r = diagnoseProjectSurfaceCatalogForAuthoring(c);
      expect(r.diagnostics, isEmpty);
      expect(r.hasErrors, isFalse);
    });

    test('3. error only: missing preset animation', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          presets: [
            _preset('p', [
              _ref(SurfaceVariantRole.isolated, 'missing-animation'),
            ]),
          ],
        ),
      );
      expect(r.count, 1);
      expect(r.diagnostics.first.kind, SurfaceCatalogDiagnosticKind.missingPresetAnimation);
      expect(r.diagnostics.first.severity, SurfaceCatalogDiagnosticSeverity.error);
      expect(r.hasErrors, isTrue);
    });

    test('4. warning only: unused atlas', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          atlases: [_atlas('orphan')],
        ),
      );
      expect(r.count, 1);
      expect(r.diagnostics.first.kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(r.diagnostics.first.severity, SurfaceCatalogDiagnosticSeverity.warning);
      expect(r.hasErrors, isFalse);
    });

    test('5. warning only: unused animation, no unusedAtlas', () {
      final atlas = _atlas('atlas');
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          atlases: [atlas],
          animations: [_animation('anim', atlasId: 'atlas')],
        ),
      );
      final kinds = r.diagnostics.map((d) => d.kind).toList();
      expect(kinds, [SurfaceCatalogDiagnosticKind.unusedAnimation]);
      expect(r.diagnostics.first.severity, SurfaceCatalogDiagnosticSeverity.warning);
      expect(r.hasErrors, isFalse);
    });

    test('6. error + warnings: order errors then unusedAtlas then unusedAnimation', () {
      final usedAtlas = _atlas('used-atlas');
      final unusedAtlas = _atlas('unused-atlas');
      final anim = _animation('unused-animation', atlasId: 'used-atlas');
      final preset = _preset('broken-preset', [
        _ref(SurfaceVariantRole.isolated, 'missing-animation'),
      ]);
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          atlases: [usedAtlas, unusedAtlas],
          animations: [anim],
          presets: [preset],
        ),
      );
      expect(r.diagnostics.length, 3);
      expect(r.diagnostics[0].kind, SurfaceCatalogDiagnosticKind.missingPresetAnimation);
      expect(r.diagnostics[1].kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
      expect(r.diagnostics[1].atlasId, 'unused-atlas');
      expect(r.diagnostics[2].kind, SurfaceCatalogDiagnosticKind.unusedAnimation);
      expect(r.diagnostics[2].animationId, 'unused-animation');
      expect(r.hasErrors, isTrue);
    });

    test('7. two preset errors: Lot 34 order preserved at start of report', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          presets: [
            _preset('first', [
              _ref(SurfaceVariantRole.isolated, 'm1'),
            ]),
            _preset('second', [
              _ref(SurfaceVariantRole.isolated, 'm2'),
            ]),
          ],
        ),
      );
      expect(r.diagnostics.length, 2);
      expect(r.diagnostics[0].presetId, 'first');
      expect(r.diagnostics[0].animationId, 'm1');
      expect(r.diagnostics[1].presetId, 'second');
      expect(r.diagnostics[1].animationId, 'm2');
    });

    test('8. many unusedAtlas then many unusedAnimation: Lot 35 order in tail', () {
      final forFrames = _atlas('for-frames');
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          atlases: [
            _atlas('u1'),
            _atlas('u2'),
            _atlas('u3'),
            forFrames,
          ],
          animations: [
            _animation('a1', atlasId: 'for-frames'),
            _animation('a2', atlasId: 'for-frames'),
            _animation('a3', atlasId: 'for-frames'),
          ],
        ),
      );
      final kinds = r.diagnostics.map((d) => d.kind).toList();
      expect(
        kinds,
        [
          ...List.filled(3, SurfaceCatalogDiagnosticKind.unusedAtlas),
          ...List.filled(3, SurfaceCatalogDiagnosticKind.unusedAnimation),
        ],
      );
      expect(r.diagnostics[0].atlasId, 'u1');
      expect(r.diagnostics[1].atlasId, 'u2');
      expect(r.diagnostics[2].atlasId, 'u3');
      expect(r.diagnostics[3].animationId, 'a1');
      expect(r.diagnostics[4].animationId, 'a2');
      expect(r.diagnostics[5].animationId, 'a3');
    });

    test('9. no dedup: missingAnimationAtlas + unusedAnimation same anim', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          animations: [
            _animation('ghost', atlasId: 'no-such-atlas'),
          ],
        ),
      );
      expect(r.diagnostics.length, 2);
      expect(
        r.diagnostics[0].kind,
        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
      );
      expect(
        r.diagnostics[1].kind,
        SurfaceCatalogDiagnosticKind.unusedAnimation,
      );
      expect(r.diagnostics[1].animationId, 'ghost');
    });

    test('10. warnings only: hasErrors false', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(atlases: [_atlas('x')]),
      );
      expect(r.hasDiagnostics, isTrue);
      expect(r.hasErrors, isFalse);
    });

    test('11. errors + warnings: hasErrors true', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          presets: [
            _preset('p', [
              _ref(SurfaceVariantRole.isolated, 'absent'),
            ]),
          ],
          atlases: [_atlas('only-atlas')],
        ),
      );
      expect(r.hasErrors, isTrue);
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
        isNotEmpty,
      );
    });

    test('12. byKind on combined report', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          presets: [
            _preset('p', [
              _ref(SurfaceVariantRole.isolated, 'miss'),
            ]),
          ],
          atlases: [
            _atlas('a'),
            _atlas('b'),
          ],
          animations: [
            _animation('u', atlasId: 'a'),
          ],
        ),
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation).length,
        1,
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas).map((d) => d.atlasId).toList(),
        ['b'],
      );
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation).map((d) => d.animationId).toList(),
        ['u'],
      );
    });

    test('13. diagnostics list is unmodifiable', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(atlases: [_atlas('z')]),
      );
      expect(
        () => r.diagnostics.add(r.diagnostics.first),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('14. catalog lists unchanged after call', () {
      final a = _atlas('a');
      final c = _catalog(atlases: [a], animations: const [], presets: const []);
      expect(c.atlases.length, 1);
      final beforeAtlases = c.atlases;
      diagnoseProjectSurfaceCatalogForAuthoring(c);
      expect(c.atlases.length, 1);
      expect(identical(c.atlases, beforeAtlases), isTrue);
    });

    test('15. Lot 34 alone: no unusedAtlas for orphan atlas', () {
      final onlyErrors = diagnoseProjectSurfaceCatalog(
        _catalog(atlases: [_atlas('only')]),
      );
      expect(
        onlyErrors.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas),
        isEmpty,
      );
    });

    test('16. Lot 35 alone: no missingPresetAnimation for broken ref', () {
      final onlyUnused = diagnoseProjectSurfaceCatalogUnusedResources(
        _catalog(
          presets: [
            _preset('p', [
              _ref(SurfaceVariantRole.isolated, 'nope'),
            ]),
          ],
        ),
      );
      expect(
        onlyUnused.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
        isEmpty,
      );
    });

    test('17. V0: coherent preset, no spurious preset-targeted unused rule', () {
      const id = 'coherent-preset';
      final anim = _animation('linked', atlasId: 'A');
      final preset = _preset(id, [
        _ref(SurfaceVariantRole.isolated, 'linked'),
      ]);
      final r = diagnoseProjectSurfaceCatalogForAuthoring(
        _catalog(
          atlases: [_atlas('A')],
          animations: [anim],
          presets: [preset],
        ),
      );
      expect(
        r.diagnostics.where((d) => d.presetId == id),
        isEmpty,
        reason: 'V0: no unusedPreset — preset not targeted when catalog coherent',
      );
    });

    test('18. public API via map_core', () {
      final r = diagnoseProjectSurfaceCatalogForAuthoring(_catalog());
      expect(r, isA<SurfaceCatalogDiagnosticsReport>());
    });

    test('19. ProjectManifest still has no Surface keys (Lot 36)', () {
      const manifest = ProjectManifest(
        name: 'L36',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final j = manifest.toJson();
      for (final k in const [
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(j.containsKey(k), isFalse, reason: k);
      }
    });

    test('20. no unusedPreset kind; severities are error and warning only', () {
      final names = SurfaceCatalogDiagnosticKind.values.map((e) => e.name).toList();
      expect(names.contains('unusedPreset'), isFalse);
      final sev = SurfaceCatalogDiagnosticSeverity.values.map((e) => e.name).toList()..sort();
      expect(sev, ['error', 'warning']);
    });
  });
}
```

### 32.B — Fichier modifié (intégral) : `packages/map_core/lib/map_core.dart`

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/surface.dart';
export 'src/models/surface_catalog.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
export 'src/operations/tile_visual_frame_timeline.dart';
export 'src/operations/tile_visual_frame_vertical_atlas.dart';
export 'src/operations/path_variant_vertical_atlas_mapping.dart';
export 'src/operations/path_preset_vertical_atlas_builder.dart';
export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/legacy_path_surface_view.dart';
export 'src/operations/legacy_terrain_surface_view.dart';
export 'src/operations/legacy_project_surface_catalog_view.dart';
export 'src/operations/legacy_surface_catalog_diagnostics.dart';
export 'src/operations/legacy_surface_usage_view.dart';
export 'src/operations/legacy_surface_usage_diagnostics.dart';
export 'src/operations/legacy_surface_audit_report.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/collision/element_collision_legacy_migration.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
export 'src/operations/map_entity_collision_footprint.dart';
export 'src/operations/map_triggers.dart';
export 'src/operations/map_warps.dart';
export 'src/operations/map_gameplay_zones.dart';
export 'src/operations/map_map_metadata.dart';
export 'src/operations/game_state_persistence.dart';
export 'src/operations/tileset_library_tree.dart';
export 'src/operations/dialogue_library_tree.dart';
export 'src/operations/project_dialogue_refs.dart';
export 'src/validation/validators.dart';
export 'src/validation/dialogue_validation.dart';
export 'src/validation/entity_editor_visual_validation.dart';
export 'src/exceptions/map_exceptions.dart';
export 'src/io/legacy_editor_json_compat.dart';
```

### 32.C — Diffs unifiés

**`surface_catalog_authoring_diagnostics.dart` — `diff -u` depuis état initial vide (machine locale, répertoire projet)**

```diff
--- /dev/null	2026-04-27 00:56:03
+++ packages/map_core/lib/src/operations/surface_catalog_authoring_diagnostics.dart	2026-04-27 00:54:42
@@ -0,0 +1,34 @@
+// Surface catalog authoring — agrégation non persistante (Lot 36).
+//
+// Ce module fournit [diagnoseProjectSurfaceCatalogForAuthoring], un point
+// d'entrée **confort** pour l'auteur (éditeur) : un seul rapport combinant
+// les **erreurs** de cohérence (Lot 34, [diagnoseProjectSurfaceCatalog]) et
+// les **avertissements** d'inutilisation (Lot 35,
+// [diagnoseProjectSurfaceCatalogUnusedResources]).
+//
+// * Ne remplace **pas** les deux fonctions spécialisées : elles restent la
+//   source de vérité pour un axe diagnostic isolé.
+// * Ordre **volontaire** : d'abord toutes les entrées d'erreur (ordre interne
+//   du Lot 34 inchangé), puis toutes les entrées d'avertissement (ordre interne
+//   du Lot 35 inchangé).
+// * **Aucune** déduplication, **aucune** fusion de messages, **aucun** re-tri.
+
+import '../models/surface_catalog.dart';
+import 'surface_catalog_diagnostics.dart';
+
+/// Retourne un [SurfaceCatalogDiagnosticsReport] **auteur** : concaténation
+/// des diagnostics d'[diagnoseProjectSurfaceCatalog] puis de
+/// [diagnoseProjectSurfaceCatalogUnusedResources], **sans** mutation du
+/// [ProjectSurfaceCatalog] et **sans** remplacer un validateur projet complet.
+SurfaceCatalogDiagnosticsReport diagnoseProjectSurfaceCatalogForAuthoring(
+  ProjectSurfaceCatalog catalog,
+) {
+  final errors = diagnoseProjectSurfaceCatalog(catalog);
+  final warnings = diagnoseProjectSurfaceCatalogUnusedResources(catalog);
+  return SurfaceCatalogDiagnosticsReport(
+    diagnostics: [
+      ...errors.diagnostics,
+      ...warnings.diagnostics,
+    ],
+  );
+}
```

**`surface_catalog_authoring_diagnostics_test.dart` — même procédure**

```diff
--- /dev/null	2026-04-27 00:55:39
+++ packages/map_core/test/surface_catalog_authoring_diagnostics_test.dart	2026-04-27 00:55:10
@@ -0,0 +1,400 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+SurfaceAtlasGeometry _geom({int columns = 2, int rows = 2}) {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+}
+
+ProjectSurfaceAtlas _atlas(
+  String id, {
+  int columns = 2,
+  int rows = 2,
+}) {
+  return ProjectSurfaceAtlas(
+    id: id,
+    name: 'n-$id',
+    tilesetId: 'ts',
+    geometry: _geom(columns: columns, rows: rows),
+  );
+}
+
+SurfaceAnimationFrame _frame(String atlasId, int column, int row) {
+  return SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(
+      atlasId: atlasId,
+      column: column,
+      row: row,
+    ),
+    durationMs: 1,
+  );
+}
+
+ProjectSurfaceAnimation _animation(
+  String id, {
+  String atlasId = 'atlas',
+  List<SurfaceAnimationFrame>? frames,
+}) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: 'a-$id',
+    timeline: SurfaceAnimationTimeline(
+      frames: frames ?? [_frame(atlasId, 0, 0)],
+    ),
+  );
+}
+
+SurfaceVariantAnimationRef _ref(SurfaceVariantRole role, String animationId) {
+  return SurfaceVariantAnimationRef(
+    role: role,
+    animationId: animationId,
+  );
+}
+
+ProjectSurfacePreset _preset(String id, List<SurfaceVariantAnimationRef> refs) {
+  return ProjectSurfacePreset(
+    id: id,
+    name: 'p-$id',
+    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
+  );
+}
+
+ProjectSurfaceCatalog _catalog({
+  List<ProjectSurfaceAtlas>? atlases,
+  List<ProjectSurfaceAnimation>? animations,
+  List<ProjectSurfacePreset>? presets,
+}) {
+  return ProjectSurfaceCatalog(
+    atlases: atlases ?? const [],
+    animations: animations ?? const [],
+    presets: presets ?? const [],
+  );
+}
+
+void main() {
+  group('diagnoseProjectSurfaceCatalogForAuthoring (Lot 36)', () {
+    test('1. empty catalog: no diagnostics', () {
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(_catalog());
+      expect(r.count, 0);
+      expect(r.hasDiagnostics, isFalse);
+      expect(r.hasErrors, isFalse);
+      expect(r.diagnostics, isEmpty);
+    });
+
+    test('2. minimal coherent: no diagnostics', () {
+      final atlas = _atlas('atlas');
+      final anim = _animation('anim', atlasId: 'atlas');
+      final preset = _preset('preset', [
+        _ref(SurfaceVariantRole.isolated, 'anim'),
+      ]);
+      final c = _catalog(
+        atlases: [atlas],
+        animations: [anim],
+        presets: [preset],
+      );
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(c);
+      expect(r.diagnostics, isEmpty);
+      expect(r.hasErrors, isFalse);
+    });
+
+    test('3. error only: missing preset animation', () {
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(
+          presets: [
+            _preset('p', [
+              _ref(SurfaceVariantRole.isolated, 'missing-animation'),
+            ]),
+          ],
+        ),
+      );
+      expect(r.count, 1);
+      expect(r.diagnostics.first.kind, SurfaceCatalogDiagnosticKind.missingPresetAnimation);
+      expect(r.diagnostics.first.severity, SurfaceCatalogDiagnosticSeverity.error);
+      expect(r.hasErrors, isTrue);
+    });
+
+    test('4. warning only: unused atlas', () {
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(
+          atlases: [_atlas('orphan')],
+        ),
+      );
+      expect(r.count, 1);
+      expect(r.diagnostics.first.kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
+      expect(r.diagnostics.first.severity, SurfaceCatalogDiagnosticSeverity.warning);
+      expect(r.hasErrors, isFalse);
+    });
+
+    test('5. warning only: unused animation, no unusedAtlas', () {
+      final atlas = _atlas('atlas');
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(
+          atlases: [atlas],
+          animations: [_animation('anim', atlasId: 'atlas')],
+        ),
+      );
+      final kinds = r.diagnostics.map((d) => d.kind).toList();
+      expect(kinds, [SurfaceCatalogDiagnosticKind.unusedAnimation]);
+      expect(r.diagnostics.first.severity, SurfaceCatalogDiagnosticSeverity.warning);
+      expect(r.hasErrors, isFalse);
+    });
+
+    test('6. error + warnings: order errors then unusedAtlas then unusedAnimation', () {
+      final usedAtlas = _atlas('used-atlas');
+      final unusedAtlas = _atlas('unused-atlas');
+      final anim = _animation('unused-animation', atlasId: 'used-atlas');
+      final preset = _preset('broken-preset', [
+        _ref(SurfaceVariantRole.isolated, 'missing-animation'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(
+          atlases: [usedAtlas, unusedAtlas],
+          animations: [anim],
+          presets: [preset],
+        ),
+      );
+      expect(r.diagnostics.length, 3);
+      expect(r.diagnostics[0].kind, SurfaceCatalogDiagnosticKind.missingPresetAnimation);
+      expect(r.diagnostics[1].kind, SurfaceCatalogDiagnosticKind.unusedAtlas);
+      expect(r.diagnostics[1].atlasId, 'unused-atlas');
+      expect(r.diagnostics[2].kind, SurfaceCatalogDiagnosticKind.unusedAnimation);
+      expect(r.diagnostics[2].animationId, 'unused-animation');
+      expect(r.hasErrors, isTrue);
+    });
+
+    test('7. two preset errors: Lot 34 order preserved at start of report', () {
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(
+          presets: [
+            _preset('first', [
+              _ref(SurfaceVariantRole.isolated, 'm1'),
+            ]),
+            _preset('second', [
+              _ref(SurfaceVariantRole.isolated, 'm2'),
+            ]),
+          ],
+        ),
+      );
+      expect(r.diagnostics.length, 2);
+      expect(r.diagnostics[0].presetId, 'first');
+      expect(r.diagnostics[0].animationId, 'm1');
+      expect(r.diagnostics[1].presetId, 'second');
+      expect(r.diagnostics[1].animationId, 'm2');
+    });
+
+    test('8. many unusedAtlas then many unusedAnimation: Lot 35 order in tail', () {
+      final forFrames = _atlas('for-frames');
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(
+          atlases: [
+            _atlas('u1'),
+            _atlas('u2'),
+            _atlas('u3'),
+            forFrames,
+          ],
+          animations: [
+            _animation('a1', atlasId: 'for-frames'),
+            _animation('a2', atlasId: 'for-frames'),
+            _animation('a3', atlasId: 'for-frames'),
+          ],
+        ),
+      );
+      final kinds = r.diagnostics.map((d) => d.kind).toList();
+      expect(
+        kinds,
+        [
+          ...List.filled(3, SurfaceCatalogDiagnosticKind.unusedAtlas),
+          ...List.filled(3, SurfaceCatalogDiagnosticKind.unusedAnimation),
+        ],
+      );
+      expect(r.diagnostics[0].atlasId, 'u1');
+      expect(r.diagnostics[1].atlasId, 'u2');
+      expect(r.diagnostics[2].atlasId, 'u3');
+      expect(r.diagnostics[3].animationId, 'a1');
+      expect(r.diagnostics[4].animationId, 'a2');
+      expect(r.diagnostics[5].animationId, 'a3');
+    });
+
+    test('9. no dedup: missingAnimationAtlas + unusedAnimation same anim', () {
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(
+          animations: [
+            _animation('ghost', atlasId: 'no-such-atlas'),
+          ],
+        ),
+      );
+      expect(r.diagnostics.length, 2);
+      expect(
+        r.diagnostics[0].kind,
+        SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+      );
+      expect(
+        r.diagnostics[1].kind,
+        SurfaceCatalogDiagnosticKind.unusedAnimation,
+      );
+      expect(r.diagnostics[1].animationId, 'ghost');
+    });
+
+    test('10. warnings only: hasErrors false', () {
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(atlases: [_atlas('x')]),
+      );
+      expect(r.hasDiagnostics, isTrue);
+      expect(r.hasErrors, isFalse);
+    });
+
+    test('11. errors + warnings: hasErrors true', () {
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(
+          presets: [
+            _preset('p', [
+              _ref(SurfaceVariantRole.isolated, 'absent'),
+            ]),
+          ],
+          atlases: [_atlas('only-atlas')],
+        ),
+      );
+      expect(r.hasErrors, isTrue);
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
+        isNotEmpty,
+      );
+    });
+
+    test('12. byKind on combined report', () {
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(
+          presets: [
+            _preset('p', [
+              _ref(SurfaceVariantRole.isolated, 'miss'),
+            ]),
+          ],
+          atlases: [
+            _atlas('a'),
+            _atlas('b'),
+          ],
+          animations: [
+            _animation('u', atlasId: 'a'),
+          ],
+        ),
+      );
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation).length,
+        1,
+      );
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas).map((d) => d.atlasId).toList(),
+        ['b'],
+      );
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation).map((d) => d.animationId).toList(),
+        ['u'],
+      );
+    });
+
+    test('13. diagnostics list is unmodifiable', () {
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(atlases: [_atlas('z')]),
+      );
+      expect(
+        () => r.diagnostics.add(r.diagnostics.first),
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test('14. catalog lists unchanged after call', () {
+      final a = _atlas('a');
+      final c = _catalog(atlases: [a], animations: const [], presets: const []);
+      expect(c.atlases.length, 1);
+      final beforeAtlases = c.atlases;
+      diagnoseProjectSurfaceCatalogForAuthoring(c);
+      expect(c.atlases.length, 1);
+      expect(identical(c.atlases, beforeAtlases), isTrue);
+    });
+
+    test('15. Lot 34 alone: no unusedAtlas for orphan atlas', () {
+      final onlyErrors = diagnoseProjectSurfaceCatalog(
+        _catalog(atlases: [_atlas('only')]),
+      );
+      expect(
+        onlyErrors.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas),
+        isEmpty,
+      );
+    });
+
+    test('16. Lot 35 alone: no missingPresetAnimation for broken ref', () {
+      final onlyUnused = diagnoseProjectSurfaceCatalogUnusedResources(
+        _catalog(
+          presets: [
+            _preset('p', [
+              _ref(SurfaceVariantRole.isolated, 'nope'),
+            ]),
+          ],
+        ),
+      );
+      expect(
+        onlyUnused.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
+        isEmpty,
+      );
+    });
+
+    test('17. V0: coherent preset, no spurious preset-targeted unused rule', () {
+      const id = 'coherent-preset';
+      final anim = _animation('linked', atlasId: 'A');
+      final preset = _preset(id, [
+        _ref(SurfaceVariantRole.isolated, 'linked'),
+      ]);
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(
+        _catalog(
+          atlases: [_atlas('A')],
+          animations: [anim],
+          presets: [preset],
+        ),
+      );
+      expect(
+        r.diagnostics.where((d) => d.presetId == id),
+        isEmpty,
+        reason: 'V0: no unusedPreset — preset not targeted when catalog coherent',
+      );
+    });
+
+    test('18. public API via map_core', () {
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(_catalog());
+      expect(r, isA<SurfaceCatalogDiagnosticsReport>());
+    });
+
+    test('19. ProjectManifest still has no Surface keys (Lot 36)', () {
+      const manifest = ProjectManifest(
+        name: 'L36',
+        maps: [
+          ProjectMapEntry(
+            id: 'm1',
+            name: 'M',
+            relativePath: 'maps/m1.json',
+          ),
+        ],
+        tilesets: [],
+      );
+      final j = manifest.toJson();
+      for (final k in const [
+        'surfaceDefinitions',
+        'surfaceAtlases',
+        'surfaceAnimations',
+        'surfacePresets',
+        'surfaceCategories',
+      ]) {
+        expect(j.containsKey(k), isFalse, reason: k);
+      }
+    });
+
+    test('20. no unusedPreset kind; severities are error and warning only', () {
+      final names = SurfaceCatalogDiagnosticKind.values.map((e) => e.name).toList();
+      expect(names.contains('unusedPreset'), isFalse);
+      final sev = SurfaceCatalogDiagnosticSeverity.values.map((e) => e.name).toList()..sort();
+      expect(sev, ['error', 'warning']);
+    });
+  });
+}
```

**`map_core.dart` — `git diff` (répertoire de travail)**

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 15ad5c73..ea6022a6 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -42,6 +42,7 @@ export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
 export 'src/operations/standard_surface_preset_builder.dart';
 export 'src/operations/surface_catalog_diagnostics.dart';
+export 'src/operations/surface_catalog_authoring_diagnostics.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

**Rapport Lot 36 — équivalence de forme :** le texte de ce document (hors ce court paragraphe explicatif) constitue le contenu de référence. Un enchaînement de lignes préfixées `+` au format usuel d'un outil de diff depuis un contenu nul recopie exactement ce texte, sans omettre de ligne.

### 32.D — Auto-contrôle (contrat de livraison)

Recherche sur les sections 1–32 (hors ce paragraphe) : **0** occurrence parmi les 12 formulations d’évitement de l’énoncé (interdites pour substituer une preuve). Les blocs 32.A à 32.C contiennent intégralement fichiers, diffs et sorties requis.

## 33. Auto-review (réponses explicites)

| Critère | OK |
|--------|-----|
| Périmètre strict agrégateur | Oui |
| `ProjectManifest` non modifié | Oui |
| Aucun champ Surface persistant | Oui |
| `SurfacePresetKind` / `surfaceKind` | Non créés |
| `unusedPreset` (kind) | Non créé |
| Nouveaux kind / severity | Aucun |
| Freezed/JSON générés | Inchangés |
| Fichiers `.g.dart` / `.freezed.dart` | Non modifiés |
| Runtime/éditeur/gameplay/battle | Non modifiés |
| Lot 34 spécialisé erreurs | Oui, inchangé |
| Lot 35 spécialisé warnings | Oui, inchangé |
| Agrégateur = erreurs puis warnings | Oui |
| Pas de déduplication | Oui |
| `hasErrors` | Oui, sur le rapport combiné |
| Ordre stable | Oui |
| Export public | Oui |
| Manifest sans clés `surface*` (test) | Oui |
| `map_core` 827 tests | Oui |
| Evidence Pack | Complet (§32) |
| Formulations d'évitement | Aucune (§32.D) |
| Commandes Git d'écriture | Aucune |
