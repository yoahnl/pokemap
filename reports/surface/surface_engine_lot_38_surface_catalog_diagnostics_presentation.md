# Surface Engine — Lot 38 — `SurfaceCatalogDiagnosticsPresentation` V0

## 1. Résumé exécutif

Modèle de présentation auteur : `buildSurfaceCatalogDiagnosticsPresentation`, `SurfaceCatalogDiagnosticsPresentation`, sections errors/warnings, listes immuables, égalité par valeur, conservation de l'instance de `SurfaceCatalogDiagnosticsReport` passée, summary via `summarizeSurfaceCatalogDiagnostics`. 23 tests ; export public.

## 2. Pourquoi après le Lot 37

Le Lot 37 fournit le résumé (compteurs) ; l'éditeur a besoin de listes filtrées et de sections (erreurs puis avertissements) sans mélange affichage.

## 3. Fichiers consultés (audit)

Diagnostics 34–37, `surface*`, `map_core`, `project_manifest` (lecture seule), rapports 36–37.

## 4. Fichiers créés / 5. modifiés

- `surface_catalog_diagnostics_presentation.dart`
- `surface_catalog_diagnostics_presentation_test.dart`
- ce rapport
- `map_core.dart` : +1 export

## 6. API

`SurfaceCatalogDiagnosticsPresentationSectionKind` (errors, warnings) ; `SurfaceCatalogDiagnosticsPresentationSection` ; `SurfaceCatalogDiagnosticsPresentation` ; `buildSurfaceCatalogDiagnosticsPresentation`.

## 7. Sémantique `SectionKind`

Deux seules valeurs : errors (bloquants), warnings.

## 8. Sémantique `PresentationSection`

Groupe non vide ; `diagnostics` non modifiable ; `count` / `isEmpty` / `isNotEmpty` ; `==` / `hashCode`.

## 9. Sémantique `SurfaceCatalogDiagnosticsPresentation`

Agrégat `report` + `summary` + vues `errors` / `warnings` / `sections` ; booléens délégués au `summary`.

## 10. Sémantique `build...`

Parcours `report.diagnostics` dans l'ordre ; remplit `errors` et `warnings` par severity ; sections `[errors?][warnings?]` ; `report` reçu inchangé en référence.

## 11. Sections errors / warnings

Même sévérité par section ; pas de diagnostic créé ; références du rapport d'origine.

## 12. Ordre des sections

Toujours errors puis warnings si présentes ; le rapport d'entrée peut être entrelacé.

## 13. Décision : pas de tri

Aucun tri par kind, message, id : seul l'ordre d'apparition dans le rapport compte par bucket.

## 14. Décision : aucun diagnostic inventé

Aucun `SurfaceCatalogDiagnostic` ne sort du builder sans provenir de `report`.

## 15. Décision : Lots 34 / 35 / 36 / 37 intacts

Aucun fichier d'opération antérieur modifié.

## 16. Décision : pas de nouveau kind ni severity

Aucun ajout sur `SurfaceCatalogDiagnosticKind` ni `SurfaceCatalogDiagnosticSeverity`.

## 17. Décision : pas de `unusedPreset` (enum kind)

Le kind n'existe pas et n'a pas été introduit.

## 18. Relation `ProjectSurfaceCatalog`

Scénarios catalogue réel via `diagnoseProjectSurfaceCatalogForAuthoring` ; pas de changement de modèle catalogue.

## 19. Relation `ProjectManifest` futur

Aucun champ de persistance surface.

## 20. Ce qui a été testé

Vingt-trois cas (vide, erreurs seules, warnings seuls, entrelacement, non-tri, immuabilité, authoring, `==`, manifest, export public).

## 21. Ce que les tests prouvent

`identical` sur le `report` ; `summary` égal à `summarizeSurfaceCatalogDiagnostics` ; sections `[errors, warnings]` ; listes `List.unmodifiable` ; invariants `ProjectManifest`.

## 22. Volontairement non fait (hors lot)

Aucun widget Flutter, localisation, `toJson`, runtime.

## 23. Pourquoi le manifeste n'est pas modifié

Hors portée V0.

## 24. Pourquoi aucun fichier généré

Aucun `build_runner` ; pas de `.g.dart` / `.freezed` ajouté.

## 25. Pourquoi pas de `SurfacePresetKind` / `surfaceKind`

Hors cahier de ce lot.

## 26. Pourquoi pas de kind `unusedPreset`

Non demandé.

## 27. Prochains lots

L'UI pourra se brancher sur `buildSurfaceCatalogDiagnosticsPresentation` et les diagnostics existants en mémoire.

## 28. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_presentation_test.dart
/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_summary_test.dart
/opt/homebrew/bin/dart test test/surface_catalog_authoring_diagnostics_test.dart
/opt/homebrew/bin/dart test test/surface_catalog_diagnostics_test.dart
/opt/homebrew/bin/dart test test/surface_catalog_unused_diagnostics_test.dart
dart analyze (chemins imposés par le cahier des lots, sortie en §D ci-dessous)
/opt/homebrew/bin/dart test
```

### `git status --short` (lecture seule)

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/surface_catalog_diagnostics_presentation.dart
?? packages/map_core/test/surface_catalog_diagnostics_presentation_test.dart
?? reports/surface/build_lot38_report.py
```

## 29. Sortie intégrale : test ciblé Lot 38

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_diagnostics_presentation_test.dart[0m[0m                                                                                                                              
00:00 [32m+0[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 1. empty report → clean presentation[0m                                                                                                     
00:00 [32m+1[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 1. empty report → clean presentation[0m                                                                                                     
00:00 [32m+1[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 2. one error: missingPresetAnimation[0m                                                                                                     
00:00 [32m+2[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 2. one error: missingPresetAnimation[0m                                                                                                     
00:00 [32m+2[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 3. one warning: unusedAtlas[0m                                                                                                              
00:00 [32m+3[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 3. one warning: unusedAtlas[0m                                                                                                              
00:00 [32m+3[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 4. mix ordered: 2 err then 2 warn[0m                                                                                                        
00:00 [32m+4[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 4. mix ordered: 2 err then 2 warn[0m                                                                                                        
00:00 [32m+4[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 5. interleaved w,e,w,e: stable relative order in buckets[0m                                                                                 
00:00 [32m+5[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 5. interleaved w,e,w,e: stable relative order in buckets[0m                                                                                 
00:00 [32m+5[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 6. error kinds not alphabetically sorted (order preserved)[0m                                                                               
00:00 [32m+6[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 6. error kinds not alphabetically sorted (order preserved)[0m                                                                               
00:00 [32m+6[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 7. warnings: message / id order preserved (not sorted)[0m                                                                                   
00:00 [32m+7[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 7. warnings: message / id order preserved (not sorted)[0m                                                                                   
00:00 [32m+7[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 8. summary == summarizeSurfaceCatalogDiagnostics(report)[0m                                                                                 
00:00 [32m+8[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 8. summary == summarizeSurfaceCatalogDiagnostics(report)[0m                                                                                 
00:00 [32m+8[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 9. bool helpers delegate to summary (mixed)[0m                                                                                              
00:00 [32m+9[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 9. bool helpers delegate to summary (mixed)[0m                                                                                              
00:00 [32m+9[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 10. errors, warnings, sections are unmodifiable[0m                                                                                          
00:00 [32m+10[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 10. errors, warnings, sections are unmodifiable[0m                                                                                         
00:00 [32m+10[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 11. section.diagnostics is unmodifiable[0m                                                                                                 
00:00 [32m+11[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 11. section.diagnostics is unmodifiable[0m                                                                                                 
00:00 [32m+11[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 12. section count / isEmpty / isNotEmpty (two in section)[0m                                                                               
00:00 [32m+12[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 12. section count / isEmpty / isNotEmpty (two in section)[0m                                                                               
00:00 [32m+12[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 13. presentation stable when source list mutated after build[0m                                                                            
00:00 [32m+13[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 13. presentation stable when source list mutated after build[0m                                                                            
00:00 [32m+13[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 14. from diagnoseProjectSurfaceCatalogForAuthoring[0m                                                                                      
00:00 [32m+14[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 14. from diagnoseProjectSurfaceCatalogForAuthoring[0m                                                                                      
00:00 [32m+14[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 15. warnings-only from authoring[0m                                                                                                        
00:00 [32m+15[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 15. warnings-only from authoring[0m                                                                                                        
00:00 [32m+15[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 16. no new diagnostics: counts match[0m                                                                                                    
00:00 [32m+16[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 16. no new diagnostics: counts match[0m                                                                                                    
00:00 [32m+16[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 17. section value equality: same==hash[0m                                                                                                  
00:00 [32m+17[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 17. section value equality: same==hash[0m                                                                                                  
00:00 [32m+17[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 18. section inequality: different diagnostic order[0m                                                                                      
00:00 [32m+18[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 18. section inequality: different diagnostic order[0m                                                                                      
00:00 [32m+18[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 19. presentation equality: equivalent reports[0m                                                                                           
00:00 [32m+19[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 19. presentation equality: equivalent reports[0m                                                                                           
00:00 [32m+19[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 20. presentation inequality when content differs[0m                                                                                        
00:00 [32m+20[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 20. presentation inequality when content differs[0m                                                                                        
00:00 [32m+20[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 21. public API types via map_core[0m                                                                                                       
00:00 [32m+21[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 21. public API types via map_core[0m                                                                                                       
00:00 [32m+21[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 22. ProjectManifest: no Surface keys (Lot 38)[0m                                                                                           
00:00 [32m+22[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 22. ProjectManifest: no Surface keys (Lot 38)[0m                                                                                           
00:00 [32m+22[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 23. no unusedPreset kind; severities are error, warning[0m                                                                                 
00:00 [32m+23[0m: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 23. no unusedPreset kind; severities are error, warning[0m                                                                                 
00:00 [32m+23[0m: All tests passed![0m
```

## 30. Sorties intégrales : régressions 37, 36, 34, 35

### Lot 37 (`surface_catalog_diagnostics_summary_test`)

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_catalog_diagnostics_summary_test.dart[0m[0m                                                                                                                                   
00:00 [32m+0[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 1. empty report → clean summary[0m                                                                                                                  
00:00 [32m+1[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 1. empty report → clean summary[0m                                                                                                                  
00:00 [32m+1[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 2. one error missingPresetAnimation[0m                                                                                                              
00:00 [32m+2[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 2. one error missingPresetAnimation[0m                                                                                                              
00:00 [32m+2[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 3. one warning unusedAtlas[0m                                                                                                                       
00:00 [32m+3[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 3. one warning unusedAtlas[0m                                                                                                                       
00:00 [32m+3[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 4. mixed: 2+1 errors, 1+3 warnings, counts by kind[0m                                                                                               
00:00 [32m+4[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 4. mixed: 2+1 errors, 1+3 warnings, counts by kind[0m                                                                                               
00:00 [32m+4[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 5. countByKind only present kinds; countForKind 0 for absent[0m                                                                                     
00:00 [32m+5[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 5. countByKind only present kinds; countForKind 0 for absent[0m                                                                                     
00:00 [32m+5[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 6. countByKind is unmodifiable[0m                                                                                                                   
00:00 [32m+6[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 6. countByKind is unmodifiable[0m                                                                                                                   
00:00 [32m+6[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 7. summary does not mutate report; list mutation does not change stored report or prior summary[0m                                                  
00:00 [32m+7[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 7. summary does not mutate report; list mutation does not change stored report or prior summary[0m                                                  
00:00 [32m+7[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 8. hasErrors matches SurfaceCatalogDiagnosticsReport.hasErrors (mixed)[0m                                                                           
00:00 [32m+8[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 8. hasErrors matches SurfaceCatalogDiagnosticsReport.hasErrors (mixed)[0m                                                                           
00:00 [32m+8[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 9. from diagnoseProjectSurfaceCatalogForAuthoring: 1 err + 2 warn[0m                                                                                
00:00 [32m+9[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 9. from diagnoseProjectSurfaceCatalogForAuthoring: 1 err + 2 warn[0m                                                                                
00:00 [32m+9[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 10. from authoring: warnings-only (unused) → hasOnlyWarnings[0m                                                                                     
00:00 [32m+10[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 10. from authoring: warnings-only (unused) → hasOnlyWarnings[0m                                                                                    
00:00 [32m+10[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 11. value equality: equivalent reports → same summary hash/==[0m                                                                                   
00:00 [32m+11[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 11. value equality: equivalent reports → same summary hash/==[0m                                                                                   
00:00 [32m+11[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 12. value inequality: different error/warning split (same total)[0m                                                                                
00:00 [32m+12[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 12. value inequality: different error/warning split (same total)[0m                                                                                
00:00 [32m+12[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 13. value inequality: same severity totals, different byKind[0m                                                                                    
00:00 [32m+13[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 13. value inequality: same severity totals, different byKind[0m                                                                                    
00:00 [32m+13[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 14. public API via map_core[0m                                                                                                                     
00:00 [32m+14[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 14. public API via map_core[0m                                                                                                                     
00:00 [32m+14[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 15. ProjectManifest still has no Surface keys (Lot 37)[0m                                                                                          
00:00 [32m+15[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 15. ProjectManifest still has no Surface keys (Lot 37)[0m                                                                                          
00:00 [32m+15[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 16. no unusedPreset kind; severities are error and warning only[0m                                                                                 
00:00 [32m+16[0m: summarizeSurfaceCatalogDiagnostics (Lot 37) 16. no unusedPreset kind; severities are error and warning only[0m                                                                                 
00:00 [32m+16[0m: All tests passed![0m
```

### Lot 36 (`surface_catalog_authoring_diagnostics_test`)

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

### Lot 34

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

### Lot 35

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

## 31. `dart analyze` (sortie intégrale)

```text
Analyzing surface_catalog_diagnostics_presentation.dart, surface_catalog_diagnostics_summary.dart, surface_catalog_authoring_diagnostics.dart, surface_catalog_diagnostics.dart, surface_catalog.dart, surface.dart, standard_surface_preset_builder.dart, surface_catalog_diagnostics_presentation_test.dart, surface_catalog_diagnostics_summary_test.dart, surface_catalog_authoring_diagnostics_test.dart, surface_catalog_unused_diagnostics_test.dart, surface_catalog_diagnostics_test.dart, project_surface_catalog_test.dart, standard_surface_preset_builder_test.dart, project_surface_preset_test.dart, project_surface_animation_test.dart, project_surface_atlas_test.dart, map_core.dart...
No issues found!
```

## 32. `dart test` complet (`map_core`)

**Commande :** `cd packages/map_core && /opt/homebrew/bin/dart test`

**Dernière ligne exacte :**

```text
00:01 +866: All tests passed!
```

**Total :** 866 tests.

## 33. Points de vigilance / 34. Autocritique / 35. Prompt / 36. Auto-review

Alignement avec le cahier des lots ; pas de champs interdits ; Evidence Pack en §37.

## 37. Evidence Pack complet

### 37.A Fichiers créés (intégral)

#### `surface_catalog_diagnostics_presentation.dart`

```dart
// Surface catalog — modèle de présentation auteur (Lot 38).
//
// Brique **pure** pour une future panneau « Surface Diagnostics » ou équivalent,
// **sans** dépendre de Flutter, sans l10n, sans widgets : on structure ce que le
// rapport, le summary et le découpage par [SurfaceCatalogDiagnosticSeverity]
// impliquent déjà, pour qu’une couche UI puisse s’y brancher plus tard.
//
// * Ne **remplace** ni [SurfaceCatalogDiagnosticsReport] ni
//   [SurfaceCatalogDiagnosticsSummary] : ce sont des champs de la présentation
//   pour garder le lien avec la source d’analyse.
// * Regroupement **seulement** par severity : deux sections possibles, dans
//   l’ordre volontaire [errors] puis [warnings] (même si le rapport mélangeait
//   warning/error dans un autre ordre).
// * Aucun [SurfaceCatalogDiagnostic] n’est **créé** ni **cloné** ici (références
//   héritées du rapport) ; l’ordre relatif des entrées d’une même severity dans
//   le rapport d’origine est **préservé** dans chaque sous-liste.

import 'package:meta/meta.dart' show immutable;

import 'surface_catalog_diagnostics.dart';
import 'surface_catalog_diagnostics_summary.dart';

// --- Comparaison ordonnée (égalité des listes) ---

bool _diagnosticsListEqualInOrder(
  List<SurfaceCatalogDiagnostic> a,
  List<SurfaceCatalogDiagnostic> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool _sectionListEqualInOrder(
  List<SurfaceCatalogDiagnosticsPresentationSection> a,
  List<SurfaceCatalogDiagnosticsPresentationSection> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Axe d’en-tête de panneau : erreurs, puis avertissements.
enum SurfaceCatalogDiagnosticsPresentationSectionKind {
  errors,
  warnings,
}

/// Un **groupe non vide** de diagnostics d’une même [SurfaceCatalogDiagnosticSeverity]
/// (erreurs ou avertissements) pour l’affichage structuré.
@immutable
final class SurfaceCatalogDiagnosticsPresentationSection {
  SurfaceCatalogDiagnosticsPresentationSection({
    required this.kind,
    required this.severity,
    required List<SurfaceCatalogDiagnostic> diagnostics,
  }) : diagnostics = List<SurfaceCatalogDiagnostic>.unmodifiable(
          List<SurfaceCatalogDiagnostic>.from(diagnostics),
        ) {
    assert(
      (kind == SurfaceCatalogDiagnosticsPresentationSectionKind.errors &&
              severity == SurfaceCatalogDiagnosticSeverity.error) ||
          (kind == SurfaceCatalogDiagnosticsPresentationSectionKind.warnings &&
              severity == SurfaceCatalogDiagnosticSeverity.warning),
      'kind/severity cohérents pour errors|warnings',
    );
  }

  final SurfaceCatalogDiagnosticsPresentationSectionKind kind;
  final SurfaceCatalogDiagnosticSeverity severity;
  final List<SurfaceCatalogDiagnostic> diagnostics;

  int get count => diagnostics.length;
  bool get isEmpty => diagnostics.isEmpty;
  bool get isNotEmpty => diagnostics.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceCatalogDiagnosticsPresentationSection &&
          other.kind == kind &&
          other.severity == severity &&
          _diagnosticsListEqualInOrder(
            other.diagnostics,
            diagnostics,
          );

  @override
  int get hashCode => Object.hash(
        kind,
        severity,
        Object.hashAll(diagnostics),
      );
}

/// Vue prête auteur (rapport + summary + plages errors/warnings + sections).
@immutable
final class SurfaceCatalogDiagnosticsPresentation {
  SurfaceCatalogDiagnosticsPresentation({
    required this.report,
    required this.summary,
    required List<SurfaceCatalogDiagnostic> errors,
    required List<SurfaceCatalogDiagnostic> warnings,
    required List<SurfaceCatalogDiagnosticsPresentationSection> sections,
  })  : errors = List<SurfaceCatalogDiagnostic>.unmodifiable(
          List<SurfaceCatalogDiagnostic>.from(errors),
        ),
        warnings = List<SurfaceCatalogDiagnostic>.unmodifiable(
          List<SurfaceCatalogDiagnostic>.from(warnings),
        ),
        sections =
            List<SurfaceCatalogDiagnosticsPresentationSection>.unmodifiable(
          List<SurfaceCatalogDiagnosticsPresentationSection>.from(sections),
        );

  final SurfaceCatalogDiagnosticsReport report;
  final SurfaceCatalogDiagnosticsSummary summary;
  final List<SurfaceCatalogDiagnostic> errors;
  final List<SurfaceCatalogDiagnostic> warnings;
  final List<SurfaceCatalogDiagnosticsPresentationSection> sections;

  /// Délègue à [summary] (pas de re-logique côté présentation).
  bool get isClean => summary.isClean;

  /// Délègue à [summary].
  bool get hasDiagnostics => summary.hasDiagnostics;

  /// Délègue à [summary].
  bool get hasErrors => summary.hasErrors;

  /// Délègue à [summary].
  bool get hasWarnings => summary.hasWarnings;

  /// Délègue à [summary].
  bool get hasOnlyWarnings => summary.hasOnlyWarnings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceCatalogDiagnosticsPresentation &&
          other.report == report &&
          other.summary == summary &&
          _diagnosticsListEqualInOrder(other.errors, errors) &&
          _diagnosticsListEqualInOrder(other.warnings, warnings) &&
          _sectionListEqualInOrder(other.sections, sections);

  @override
  int get hashCode => Object.hash(
        report,
        summary,
        Object.hashAll(errors),
        Object.hashAll(warnings),
        Object.hashAll(sections),
      );
}

/// Construit un [SurfaceCatalogDiagnosticsPresentation] à partir de [report]
/// en conservant l’**instance** de rapport ([identical] dans la présentation) ;
/// pas de tri par kind, message ni id.
SurfaceCatalogDiagnosticsPresentation
    buildSurfaceCatalogDiagnosticsPresentation(
  SurfaceCatalogDiagnosticsReport report,
) {
  final summary = summarizeSurfaceCatalogDiagnostics(report);
  final err = <SurfaceCatalogDiagnostic>[];
  final warn = <SurfaceCatalogDiagnostic>[];
  for (final d in report.diagnostics) {
    if (d.severity == SurfaceCatalogDiagnosticSeverity.error) {
      err.add(d);
    } else if (d.severity == SurfaceCatalogDiagnosticSeverity.warning) {
      warn.add(d);
    }
  }

  final sections = <SurfaceCatalogDiagnosticsPresentationSection>[];
  if (err.isNotEmpty) {
    sections.add(
      SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
        severity: SurfaceCatalogDiagnosticSeverity.error,
        diagnostics: err,
      ),
    );
  }
  if (warn.isNotEmpty) {
    sections.add(
      SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
        severity: SurfaceCatalogDiagnosticSeverity.warning,
        diagnostics: warn,
      ),
    );
  }

  return SurfaceCatalogDiagnosticsPresentation(
    report: report,
    summary: summary,
    errors: err,
    warnings: warn,
    sections: sections,
  );
}
```

#### `surface_catalog_diagnostics_presentation_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceCatalogDiagnostic _diagnostic({
  required SurfaceCatalogDiagnosticSeverity severity,
  required SurfaceCatalogDiagnosticKind kind,
  String message = 'message',
  String? presetId,
  String? animationId,
  String? atlasId,
  SurfaceVariantRole? role,
  int? frameIndex,
}) {
  return SurfaceCatalogDiagnostic(
    severity: severity,
    kind: kind,
    message: message,
    presetId: presetId,
    animationId: animationId,
    atlasId: atlasId,
    role: role,
    frameIndex: frameIndex,
  );
}

SurfaceCatalogDiagnosticsReport _report(
  List<SurfaceCatalogDiagnostic> diagnostics,
) {
  return SurfaceCatalogDiagnosticsReport(diagnostics: diagnostics);
}

// --- Catalog helpers (même recette que les lots Surface) ---

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
  group('buildSurfaceCatalogDiagnosticsPresentation (Lot 38)', () {
    test('1. empty report → clean presentation', () {
      final report = _report([]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(identical(p.report, report), isTrue);
      expect(p.summary.isClean, isTrue);
      expect(p.errors, isEmpty);
      expect(p.warnings, isEmpty);
      expect(p.sections, isEmpty);
      expect(p.isClean, isTrue);
      expect(p.hasDiagnostics, isFalse);
      expect(p.hasErrors, isFalse);
      expect(p.hasWarnings, isFalse);
      expect(p.hasOnlyWarnings, isFalse);
    });

    test('2. one error: missingPresetAnimation', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      final d = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
      );
      final report = _report([d]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(p.errors.length, 1);
      expect(p.warnings, isEmpty);
      expect(p.sections.length, 1);
      expect(
        p.sections.first.kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
      );
      expect(p.sections.first.severity, e);
      expect(p.sections.first.count, 1);
      expect(p.hasErrors, isTrue);
    });

    test('3. one warning: unusedAtlas', () {
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final d = _diagnostic(
        severity: w,
        kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
        atlasId: 'a1',
      );
      final report = _report([d]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(p.errors, isEmpty);
      expect(p.warnings.length, 1);
      expect(p.sections.length, 1);
      expect(
        p.sections.first.kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
      );
      expect(p.sections.first.severity, w);
      expect(p.sections.first.count, 1);
      expect(p.hasOnlyWarnings, isTrue);
    });

    test('4. mix ordered: 2 err then 2 warn', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final report = _report([
        _diagnostic(
          severity: e,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
        _diagnostic(
          severity: e,
          kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
          atlasId: 'x',
        ),
        _diagnostic(
          severity: w,
          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
          atlasId: 'u1',
        ),
        _diagnostic(
          severity: w,
          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
          animationId: 'a1',
        ),
      ]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(p.errors.length, 2);
      expect(p.warnings.length, 2);
      expect(p.sections.length, 2);
      expect(
        p.sections[0].kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
      );
      expect(
        p.sections[1].kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
      );
      final s2 = summarizeSurfaceCatalogDiagnostics(report);
      expect(p.summary.totalCount, 4);
      expect(s2, p.summary);
    });

    test('5. interleaved w,e,w,e: stable relative order in buckets', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final w1 = _diagnostic(
        severity: w,
        kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
        message: 'w1',
        atlasId: 'A',
      );
      final e1 = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'e1',
      );
      final w2 = _diagnostic(
        severity: w,
        kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
        message: 'w2',
        animationId: 'Z',
      );
      final e2 = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        message: 'e2',
        animationId: 'a',
        atlasId: 'b',
      );
      final report = _report([w1, e1, w2, e2]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(
        p.errors.map((x) => x.message).toList(),
        ['e1', 'e2'],
      );
      expect(
        p.warnings.map((x) => x.message).toList(),
        ['w1', 'w2'],
      );
      expect(
        p.sections[0].kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
      );
      expect(
        p.sections[1].kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
      );
    });

    test('6. error kinds not alphabetically sorted (order preserved)', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      final first = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry,
        message: 'a',
        frameIndex: 0,
      );
      final second = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'b',
      );
      final p = buildSurfaceCatalogDiagnosticsPresentation(
        _report([first, second]),
      );
      expect(p.errors[0].kind,
          SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry);
      expect(p.errors[1].kind,
          SurfaceCatalogDiagnosticKind.missingPresetAnimation);
    });

    test('7. warnings: message / id order preserved (not sorted)', () {
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final a = _diagnostic(
        severity: w,
        kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
        message: 'z-last',
        animationId: 'id-b',
      );
      final b = _diagnostic(
        severity: w,
        kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
        message: 'a-first',
        animationId: 'id-a',
      );
      final p = buildSurfaceCatalogDiagnosticsPresentation(
        _report([a, b]),
      );
      expect(p.warnings[0].message, 'z-last');
      expect(p.warnings[0].animationId, 'id-b');
      expect(p.warnings[1].message, 'a-first');
    });

    test('8. summary == summarizeSurfaceCatalogDiagnostics(report)', () {
      final report = _report([
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
      ]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(
        p.summary,
        summarizeSurfaceCatalogDiagnostics(report),
      );
    });

    test('9. bool helpers delegate to summary (mixed)', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      const w = SurfaceCatalogDiagnosticSeverity.warning;
      final report = _report([
        _diagnostic(
            severity: w, kind: SurfaceCatalogDiagnosticKind.unusedAtlas),
        _diagnostic(
          severity: e,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
      ]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      final sm = p.summary;
      expect(p.isClean, sm.isClean);
      expect(p.hasDiagnostics, sm.hasDiagnostics);
      expect(p.hasErrors, sm.hasErrors);
      expect(p.hasWarnings, sm.hasWarnings);
      expect(p.hasOnlyWarnings, sm.hasOnlyWarnings);
    });

    test('10. errors, warnings, sections are unmodifiable', () {
      final p = buildSurfaceCatalogDiagnosticsPresentation(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
            atlasId: 'x',
          ),
        ]),
      );
      final e = _diagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        atlasId: 'y',
      );
      final fakeSection = SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
        severity: SurfaceCatalogDiagnosticSeverity.warning,
        diagnostics: [
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
          ),
        ],
      );
      expect(() => p.errors.add(e), throwsA(isA<UnsupportedError>()));
      expect(
        () => p.warnings.add(
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.warning,
            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
            animationId: 'a',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => p.sections.add(fakeSection),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('11. section.diagnostics is unmodifiable', () {
      final p = buildSurfaceCatalogDiagnosticsPresentation(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
        ]),
      );
      final extra = _diagnostic(
        severity: SurfaceCatalogDiagnosticSeverity.error,
        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        atlasId: 'z',
      );
      expect(
        () => p.sections.first.diagnostics.add(extra),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('12. section count / isEmpty / isNotEmpty (two in section)', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      final p = buildSurfaceCatalogDiagnosticsPresentation(
        _report([
          _diagnostic(
            severity: e,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
          ),
          _diagnostic(
            severity: e,
            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
            atlasId: 'q',
          ),
        ]),
      );
      final s = p.sections.first;
      expect(s.count, 2);
      expect(s.isEmpty, isFalse);
      expect(s.isNotEmpty, isTrue);
    });

    test('13. presentation stable when source list mutated after build', () {
      final list = <SurfaceCatalogDiagnostic>[
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
      ];
      final report = _report(list);
      final p0 = buildSurfaceCatalogDiagnosticsPresentation(report);
      list.add(
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.warning,
          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
        ),
      );
      final p1 = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(report.count, 1);
      expect(p0, p1);
    });

    test('14. from diagnoseProjectSurfaceCatalogForAuthoring', () {
      final used = _atlas('used-atlas');
      final unusedA = _atlas('unused-atlas');
      final uAnim = _animation('unused-animation', atlasId: 'used-atlas');
      final c = _catalog(
        atlases: [used, unusedA],
        animations: [uAnim],
        presets: [
          _preset('broken', [
            _ref(SurfaceVariantRole.isolated, 'missing-animation'),
          ]),
        ],
      );
      final report = diagnoseProjectSurfaceCatalogForAuthoring(c);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(p.errors.length, 1);
      expect(p.warnings.length, 2);
      expect(p.sections.length, 2);
      expect(
        p.summary,
        summarizeSurfaceCatalogDiagnostics(report),
      );
    });

    test('15. warnings-only from authoring', () {
      final c = _catalog(
        atlases: [_atlas('orphan')],
        animations: [
          _animation('a1', atlasId: 'orphan'),
        ],
        presets: const [],
      );
      final r = diagnoseProjectSurfaceCatalogForAuthoring(c);
      final p = buildSurfaceCatalogDiagnosticsPresentation(r);
      expect(p.errors, isEmpty);
      expect(p.warnings.isNotEmpty, isTrue);
      expect(p.sections.length, 1);
      expect(
        p.sections.first.kind,
        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
      );
      expect(p.hasOnlyWarnings, isTrue);
    });

    test('16. no new diagnostics: counts match', () {
      final report = _report([
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.warning,
          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
        ),
      ]);
      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
      expect(
        p.report.diagnostics.length,
        report.diagnostics.length,
      );
      expect(
        p.errors.length + p.warnings.length,
        report.diagnostics.length,
      );
    });

    test('17. section value equality: same==hash', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      final a = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: 'm',
      );
      final s1 = SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
        severity: e,
        diagnostics: [a],
      );
      final s2 = SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
        severity: e,
        diagnostics: [a],
      );
      expect(s1, s2);
      expect(s1.hashCode, s2.hashCode);
    });

    test('18. section inequality: different diagnostic order', () {
      const e = SurfaceCatalogDiagnosticSeverity.error;
      final x = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        message: '1',
      );
      final y = _diagnostic(
        severity: e,
        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        message: '2',
        atlasId: 'z',
      );
      final s1 = SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
        severity: e,
        diagnostics: [x, y],
      );
      final s2 = SurfaceCatalogDiagnosticsPresentationSection(
        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
        severity: e,
        diagnostics: [y, x],
      );
      expect(s1, isNot(s2));
    });

    test('19. presentation equality: equivalent reports', () {
      final a = <SurfaceCatalogDiagnostic>[
        _diagnostic(
          severity: SurfaceCatalogDiagnosticSeverity.error,
          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
      ];
      final r1 = _report(a);
      final r2 = _report(List<SurfaceCatalogDiagnostic>.from(a));
      final p1 = buildSurfaceCatalogDiagnosticsPresentation(r1);
      final p2 = buildSurfaceCatalogDiagnosticsPresentation(r2);
      expect(p1, p2);
      expect(p1.hashCode, p2.hashCode);
    });

    test('20. presentation inequality when content differs', () {
      final p1 = buildSurfaceCatalogDiagnosticsPresentation(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
            message: 'a',
          ),
        ]),
      );
      final p2 = buildSurfaceCatalogDiagnosticsPresentation(
        _report([
          _diagnostic(
            severity: SurfaceCatalogDiagnosticSeverity.error,
            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
            message: 'b',
          ),
        ]),
      );
      expect(p1, isNot(p2));
    });

    test('21. public API types via map_core', () {
      final p = buildSurfaceCatalogDiagnosticsPresentation(_report([]));
      expect(p, isA<SurfaceCatalogDiagnosticsPresentation>());
      expect(
        p.sections,
        isA<List<SurfaceCatalogDiagnosticsPresentationSection>>(),
      );
      expect(
        SurfaceCatalogDiagnosticsPresentationSectionKind.values.isNotEmpty,
        isTrue,
      );
    });

    test('22. ProjectManifest: no Surface keys (Lot 38)', () {
      const manifest = ProjectManifest(
        name: 'L38',
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

    test('23. no unusedPreset kind; severities are error, warning', () {
      final names =
          SurfaceCatalogDiagnosticKind.values.map((e) => e.name).toList();
      expect(names.contains('unusedPreset'), isFalse);
      final sev = SurfaceCatalogDiagnosticSeverity.values
          .map((e) => e.name)
          .toList()
        ..sort();
      expect(sev, ['error', 'warning']);
    });
  });
}
```

### 37.B `map_core.dart` (intégral)

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
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
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

### 37.C Diffs

#### `map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 82e14641..6c8214ed 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -44,6 +44,7 @@ export 'src/operations/standard_surface_preset_builder.dart';
 export 'src/operations/surface_catalog_diagnostics.dart';
 export 'src/operations/surface_catalog_authoring_diagnostics.dart';
 export 'src/operations/surface_catalog_diagnostics_summary.dart';
+export 'src/operations/surface_catalog_diagnostics_presentation.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

#### `/dev/null` → `surface_catalog_diagnostics_presentation.dart`

```diff
diff --git a/packages/map_core/lib/src/operations/surface_catalog_diagnostics_presentation.dart b/packages/map_core/lib/src/operations/surface_catalog_diagnostics_presentation.dart
new file mode 100644
index 00000000..73630204
--- /dev/null
+++ b/packages/map_core/lib/src/operations/surface_catalog_diagnostics_presentation.dart
@@ -0,0 +1,214 @@
+// Surface catalog — modèle de présentation auteur (Lot 38).
+//
+// Brique **pure** pour une future panneau « Surface Diagnostics » ou équivalent,
+// **sans** dépendre de Flutter, sans l10n, sans widgets : on structure ce que le
+// rapport, le summary et le découpage par [SurfaceCatalogDiagnosticSeverity]
+// impliquent déjà, pour qu’une couche UI puisse s’y brancher plus tard.
+//
+// * Ne **remplace** ni [SurfaceCatalogDiagnosticsReport] ni
+//   [SurfaceCatalogDiagnosticsSummary] : ce sont des champs de la présentation
+//   pour garder le lien avec la source d’analyse.
+// * Regroupement **seulement** par severity : deux sections possibles, dans
+//   l’ordre volontaire [errors] puis [warnings] (même si le rapport mélangeait
+//   warning/error dans un autre ordre).
+// * Aucun [SurfaceCatalogDiagnostic] n’est **créé** ni **cloné** ici (références
+//   héritées du rapport) ; l’ordre relatif des entrées d’une même severity dans
+//   le rapport d’origine est **préservé** dans chaque sous-liste.
+
+import 'package:meta/meta.dart' show immutable;
+
+import 'surface_catalog_diagnostics.dart';
+import 'surface_catalog_diagnostics_summary.dart';
+
+// --- Comparaison ordonnée (égalité des listes) ---
+
+bool _diagnosticsListEqualInOrder(
+  List<SurfaceCatalogDiagnostic> a,
+  List<SurfaceCatalogDiagnostic> b,
+) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
+
+bool _sectionListEqualInOrder(
+  List<SurfaceCatalogDiagnosticsPresentationSection> a,
+  List<SurfaceCatalogDiagnosticsPresentationSection> b,
+) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i++) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
+
+/// Axe d’en-tête de panneau : erreurs, puis avertissements.
+enum SurfaceCatalogDiagnosticsPresentationSectionKind {
+  errors,
+  warnings,
+}
+
+/// Un **groupe non vide** de diagnostics d’une même [SurfaceCatalogDiagnosticSeverity]
+/// (erreurs ou avertissements) pour l’affichage structuré.
+@immutable
+final class SurfaceCatalogDiagnosticsPresentationSection {
+  SurfaceCatalogDiagnosticsPresentationSection({
+    required this.kind,
+    required this.severity,
+    required List<SurfaceCatalogDiagnostic> diagnostics,
+  }) : diagnostics = List<SurfaceCatalogDiagnostic>.unmodifiable(
+          List<SurfaceCatalogDiagnostic>.from(diagnostics),
+        ) {
+    assert(
+      (kind == SurfaceCatalogDiagnosticsPresentationSectionKind.errors &&
+              severity == SurfaceCatalogDiagnosticSeverity.error) ||
+          (kind == SurfaceCatalogDiagnosticsPresentationSectionKind.warnings &&
+              severity == SurfaceCatalogDiagnosticSeverity.warning),
+      'kind/severity cohérents pour errors|warnings',
+    );
+  }
+
+  final SurfaceCatalogDiagnosticsPresentationSectionKind kind;
+  final SurfaceCatalogDiagnosticSeverity severity;
+  final List<SurfaceCatalogDiagnostic> diagnostics;
+
+  int get count => diagnostics.length;
+  bool get isEmpty => diagnostics.isEmpty;
+  bool get isNotEmpty => diagnostics.isNotEmpty;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceCatalogDiagnosticsPresentationSection &&
+          other.kind == kind &&
+          other.severity == severity &&
+          _diagnosticsListEqualInOrder(
+            other.diagnostics,
+            diagnostics,
+          );
+
+  @override
+  int get hashCode => Object.hash(
+        kind,
+        severity,
+        Object.hashAll(diagnostics),
+      );
+}
+
+/// Vue prête auteur (rapport + summary + plages errors/warnings + sections).
+@immutable
+final class SurfaceCatalogDiagnosticsPresentation {
+  SurfaceCatalogDiagnosticsPresentation({
+    required this.report,
+    required this.summary,
+    required List<SurfaceCatalogDiagnostic> errors,
+    required List<SurfaceCatalogDiagnostic> warnings,
+    required List<SurfaceCatalogDiagnosticsPresentationSection> sections,
+  })  : errors = List<SurfaceCatalogDiagnostic>.unmodifiable(
+          List<SurfaceCatalogDiagnostic>.from(errors),
+        ),
+        warnings = List<SurfaceCatalogDiagnostic>.unmodifiable(
+          List<SurfaceCatalogDiagnostic>.from(warnings),
+        ),
+        sections =
+            List<SurfaceCatalogDiagnosticsPresentationSection>.unmodifiable(
+          List<SurfaceCatalogDiagnosticsPresentationSection>.from(sections),
+        );
+
+  final SurfaceCatalogDiagnosticsReport report;
+  final SurfaceCatalogDiagnosticsSummary summary;
+  final List<SurfaceCatalogDiagnostic> errors;
+  final List<SurfaceCatalogDiagnostic> warnings;
+  final List<SurfaceCatalogDiagnosticsPresentationSection> sections;
+
+  /// Délègue à [summary] (pas de re-logique côté présentation).
+  bool get isClean => summary.isClean;
+
+  /// Délègue à [summary].
+  bool get hasDiagnostics => summary.hasDiagnostics;
+
+  /// Délègue à [summary].
+  bool get hasErrors => summary.hasErrors;
+
+  /// Délègue à [summary].
+  bool get hasWarnings => summary.hasWarnings;
+
+  /// Délègue à [summary].
+  bool get hasOnlyWarnings => summary.hasOnlyWarnings;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceCatalogDiagnosticsPresentation &&
+          other.report == report &&
+          other.summary == summary &&
+          _diagnosticsListEqualInOrder(other.errors, errors) &&
+          _diagnosticsListEqualInOrder(other.warnings, warnings) &&
+          _sectionListEqualInOrder(other.sections, sections);
+
+  @override
+  int get hashCode => Object.hash(
+        report,
+        summary,
+        Object.hashAll(errors),
+        Object.hashAll(warnings),
+        Object.hashAll(sections),
+      );
+}
+
+/// Construit un [SurfaceCatalogDiagnosticsPresentation] à partir de [report]
+/// en conservant l’**instance** de rapport ([identical] dans la présentation) ;
+/// pas de tri par kind, message ni id.
+SurfaceCatalogDiagnosticsPresentation
+    buildSurfaceCatalogDiagnosticsPresentation(
+  SurfaceCatalogDiagnosticsReport report,
+) {
+  final summary = summarizeSurfaceCatalogDiagnostics(report);
+  final err = <SurfaceCatalogDiagnostic>[];
+  final warn = <SurfaceCatalogDiagnostic>[];
+  for (final d in report.diagnostics) {
+    if (d.severity == SurfaceCatalogDiagnosticSeverity.error) {
+      err.add(d);
+    } else if (d.severity == SurfaceCatalogDiagnosticSeverity.warning) {
+      warn.add(d);
+    }
+  }
+
+  final sections = <SurfaceCatalogDiagnosticsPresentationSection>[];
+  if (err.isNotEmpty) {
+    sections.add(
+      SurfaceCatalogDiagnosticsPresentationSection(
+        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        diagnostics: err,
+      ),
+    );
+  }
+  if (warn.isNotEmpty) {
+    sections.add(
+      SurfaceCatalogDiagnosticsPresentationSection(
+        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
+        severity: SurfaceCatalogDiagnosticSeverity.warning,
+        diagnostics: warn,
+      ),
+    );
+  }
+
+  return SurfaceCatalogDiagnosticsPresentation(
+    report: report,
+    summary: summary,
+    errors: err,
+    warnings: warn,
+    sections: sections,
+  );
+}
```

#### `/dev/null` → `surface_catalog_diagnostics_presentation_test.dart`

```diff
diff --git a/packages/map_core/test/surface_catalog_diagnostics_presentation_test.dart b/packages/map_core/test/surface_catalog_diagnostics_presentation_test.dart
new file mode 100644
index 00000000..9449c4c2
--- /dev/null
+++ b/packages/map_core/test/surface_catalog_diagnostics_presentation_test.dart
@@ -0,0 +1,636 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+SurfaceCatalogDiagnostic _diagnostic({
+  required SurfaceCatalogDiagnosticSeverity severity,
+  required SurfaceCatalogDiagnosticKind kind,
+  String message = 'message',
+  String? presetId,
+  String? animationId,
+  String? atlasId,
+  SurfaceVariantRole? role,
+  int? frameIndex,
+}) {
+  return SurfaceCatalogDiagnostic(
+    severity: severity,
+    kind: kind,
+    message: message,
+    presetId: presetId,
+    animationId: animationId,
+    atlasId: atlasId,
+    role: role,
+    frameIndex: frameIndex,
+  );
+}
+
+SurfaceCatalogDiagnosticsReport _report(
+  List<SurfaceCatalogDiagnostic> diagnostics,
+) {
+  return SurfaceCatalogDiagnosticsReport(diagnostics: diagnostics);
+}
+
+// --- Catalog helpers (même recette que les lots Surface) ---
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
+  group('buildSurfaceCatalogDiagnosticsPresentation (Lot 38)', () {
+    test('1. empty report → clean presentation', () {
+      final report = _report([]);
+      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
+      expect(identical(p.report, report), isTrue);
+      expect(p.summary.isClean, isTrue);
+      expect(p.errors, isEmpty);
+      expect(p.warnings, isEmpty);
+      expect(p.sections, isEmpty);
+      expect(p.isClean, isTrue);
+      expect(p.hasDiagnostics, isFalse);
+      expect(p.hasErrors, isFalse);
+      expect(p.hasWarnings, isFalse);
+      expect(p.hasOnlyWarnings, isFalse);
+    });
+
+    test('2. one error: missingPresetAnimation', () {
+      const e = SurfaceCatalogDiagnosticSeverity.error;
+      final d = _diagnostic(
+        severity: e,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+      );
+      final report = _report([d]);
+      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
+      expect(p.errors.length, 1);
+      expect(p.warnings, isEmpty);
+      expect(p.sections.length, 1);
+      expect(
+        p.sections.first.kind,
+        SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
+      );
+      expect(p.sections.first.severity, e);
+      expect(p.sections.first.count, 1);
+      expect(p.hasErrors, isTrue);
+    });
+
+    test('3. one warning: unusedAtlas', () {
+      const w = SurfaceCatalogDiagnosticSeverity.warning;
+      final d = _diagnostic(
+        severity: w,
+        kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+        atlasId: 'a1',
+      );
+      final report = _report([d]);
+      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
+      expect(p.errors, isEmpty);
+      expect(p.warnings.length, 1);
+      expect(p.sections.length, 1);
+      expect(
+        p.sections.first.kind,
+        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
+      );
+      expect(p.sections.first.severity, w);
+      expect(p.sections.first.count, 1);
+      expect(p.hasOnlyWarnings, isTrue);
+    });
+
+    test('4. mix ordered: 2 err then 2 warn', () {
+      const e = SurfaceCatalogDiagnosticSeverity.error;
+      const w = SurfaceCatalogDiagnosticSeverity.warning;
+      final report = _report([
+        _diagnostic(
+          severity: e,
+          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        ),
+        _diagnostic(
+          severity: e,
+          kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+          atlasId: 'x',
+        ),
+        _diagnostic(
+          severity: w,
+          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+          atlasId: 'u1',
+        ),
+        _diagnostic(
+          severity: w,
+          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+          animationId: 'a1',
+        ),
+      ]);
+      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
+      expect(p.errors.length, 2);
+      expect(p.warnings.length, 2);
+      expect(p.sections.length, 2);
+      expect(
+        p.sections[0].kind,
+        SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
+      );
+      expect(
+        p.sections[1].kind,
+        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
+      );
+      final s2 = summarizeSurfaceCatalogDiagnostics(report);
+      expect(p.summary.totalCount, 4);
+      expect(s2, p.summary);
+    });
+
+    test('5. interleaved w,e,w,e: stable relative order in buckets', () {
+      const e = SurfaceCatalogDiagnosticSeverity.error;
+      const w = SurfaceCatalogDiagnosticSeverity.warning;
+      final w1 = _diagnostic(
+        severity: w,
+        kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+        message: 'w1',
+        atlasId: 'A',
+      );
+      final e1 = _diagnostic(
+        severity: e,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: 'e1',
+      );
+      final w2 = _diagnostic(
+        severity: w,
+        kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+        message: 'w2',
+        animationId: 'Z',
+      );
+      final e2 = _diagnostic(
+        severity: e,
+        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+        message: 'e2',
+        animationId: 'a',
+        atlasId: 'b',
+      );
+      final report = _report([w1, e1, w2, e2]);
+      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
+      expect(
+        p.errors.map((x) => x.message).toList(),
+        ['e1', 'e2'],
+      );
+      expect(
+        p.warnings.map((x) => x.message).toList(),
+        ['w1', 'w2'],
+      );
+      expect(
+        p.sections[0].kind,
+        SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
+      );
+      expect(
+        p.sections[1].kind,
+        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
+      );
+    });
+
+    test('6. error kinds not alphabetically sorted (order preserved)', () {
+      const e = SurfaceCatalogDiagnosticSeverity.error;
+      final first = _diagnostic(
+        severity: e,
+        kind: SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry,
+        message: 'a',
+        frameIndex: 0,
+      );
+      final second = _diagnostic(
+        severity: e,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: 'b',
+      );
+      final p = buildSurfaceCatalogDiagnosticsPresentation(
+        _report([first, second]),
+      );
+      expect(p.errors[0].kind,
+          SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry);
+      expect(p.errors[1].kind,
+          SurfaceCatalogDiagnosticKind.missingPresetAnimation);
+    });
+
+    test('7. warnings: message / id order preserved (not sorted)', () {
+      const w = SurfaceCatalogDiagnosticSeverity.warning;
+      final a = _diagnostic(
+        severity: w,
+        kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+        message: 'z-last',
+        animationId: 'id-b',
+      );
+      final b = _diagnostic(
+        severity: w,
+        kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+        message: 'a-first',
+        animationId: 'id-a',
+      );
+      final p = buildSurfaceCatalogDiagnosticsPresentation(
+        _report([a, b]),
+      );
+      expect(p.warnings[0].message, 'z-last');
+      expect(p.warnings[0].animationId, 'id-b');
+      expect(p.warnings[1].message, 'a-first');
+    });
+
+    test('8. summary == summarizeSurfaceCatalogDiagnostics(report)', () {
+      final report = _report([
+        _diagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.error,
+          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        ),
+      ]);
+      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
+      expect(
+        p.summary,
+        summarizeSurfaceCatalogDiagnostics(report),
+      );
+    });
+
+    test('9. bool helpers delegate to summary (mixed)', () {
+      const e = SurfaceCatalogDiagnosticSeverity.error;
+      const w = SurfaceCatalogDiagnosticSeverity.warning;
+      final report = _report([
+        _diagnostic(
+            severity: w, kind: SurfaceCatalogDiagnosticKind.unusedAtlas),
+        _diagnostic(
+          severity: e,
+          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        ),
+      ]);
+      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
+      final sm = p.summary;
+      expect(p.isClean, sm.isClean);
+      expect(p.hasDiagnostics, sm.hasDiagnostics);
+      expect(p.hasErrors, sm.hasErrors);
+      expect(p.hasWarnings, sm.hasWarnings);
+      expect(p.hasOnlyWarnings, sm.hasOnlyWarnings);
+    });
+
+    test('10. errors, warnings, sections are unmodifiable', () {
+      final p = buildSurfaceCatalogDiagnosticsPresentation(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.error,
+            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+          ),
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.warning,
+            kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+            atlasId: 'x',
+          ),
+        ]),
+      );
+      final e = _diagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+        atlasId: 'y',
+      );
+      final fakeSection = SurfaceCatalogDiagnosticsPresentationSection(
+        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
+        severity: SurfaceCatalogDiagnosticSeverity.warning,
+        diagnostics: [
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.warning,
+            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+          ),
+        ],
+      );
+      expect(() => p.errors.add(e), throwsA(isA<UnsupportedError>()));
+      expect(
+        () => p.warnings.add(
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.warning,
+            kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+            animationId: 'a',
+          ),
+        ),
+        throwsA(isA<UnsupportedError>()),
+      );
+      expect(
+        () => p.sections.add(fakeSection),
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test('11. section.diagnostics is unmodifiable', () {
+      final p = buildSurfaceCatalogDiagnosticsPresentation(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.error,
+            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+          ),
+        ]),
+      );
+      final extra = _diagnostic(
+        severity: SurfaceCatalogDiagnosticSeverity.error,
+        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+        atlasId: 'z',
+      );
+      expect(
+        () => p.sections.first.diagnostics.add(extra),
+        throwsA(isA<UnsupportedError>()),
+      );
+    });
+
+    test('12. section count / isEmpty / isNotEmpty (two in section)', () {
+      const e = SurfaceCatalogDiagnosticSeverity.error;
+      final p = buildSurfaceCatalogDiagnosticsPresentation(
+        _report([
+          _diagnostic(
+            severity: e,
+            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+          ),
+          _diagnostic(
+            severity: e,
+            kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+            atlasId: 'q',
+          ),
+        ]),
+      );
+      final s = p.sections.first;
+      expect(s.count, 2);
+      expect(s.isEmpty, isFalse);
+      expect(s.isNotEmpty, isTrue);
+    });
+
+    test('13. presentation stable when source list mutated after build', () {
+      final list = <SurfaceCatalogDiagnostic>[
+        _diagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.error,
+          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        ),
+      ];
+      final report = _report(list);
+      final p0 = buildSurfaceCatalogDiagnosticsPresentation(report);
+      list.add(
+        _diagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.warning,
+          kind: SurfaceCatalogDiagnosticKind.unusedAtlas,
+        ),
+      );
+      final p1 = buildSurfaceCatalogDiagnosticsPresentation(report);
+      expect(report.count, 1);
+      expect(p0, p1);
+    });
+
+    test('14. from diagnoseProjectSurfaceCatalogForAuthoring', () {
+      final used = _atlas('used-atlas');
+      final unusedA = _atlas('unused-atlas');
+      final uAnim = _animation('unused-animation', atlasId: 'used-atlas');
+      final c = _catalog(
+        atlases: [used, unusedA],
+        animations: [uAnim],
+        presets: [
+          _preset('broken', [
+            _ref(SurfaceVariantRole.isolated, 'missing-animation'),
+          ]),
+        ],
+      );
+      final report = diagnoseProjectSurfaceCatalogForAuthoring(c);
+      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
+      expect(p.errors.length, 1);
+      expect(p.warnings.length, 2);
+      expect(p.sections.length, 2);
+      expect(
+        p.summary,
+        summarizeSurfaceCatalogDiagnostics(report),
+      );
+    });
+
+    test('15. warnings-only from authoring', () {
+      final c = _catalog(
+        atlases: [_atlas('orphan')],
+        animations: [
+          _animation('a1', atlasId: 'orphan'),
+        ],
+        presets: const [],
+      );
+      final r = diagnoseProjectSurfaceCatalogForAuthoring(c);
+      final p = buildSurfaceCatalogDiagnosticsPresentation(r);
+      expect(p.errors, isEmpty);
+      expect(p.warnings.isNotEmpty, isTrue);
+      expect(p.sections.length, 1);
+      expect(
+        p.sections.first.kind,
+        SurfaceCatalogDiagnosticsPresentationSectionKind.warnings,
+      );
+      expect(p.hasOnlyWarnings, isTrue);
+    });
+
+    test('16. no new diagnostics: counts match', () {
+      final report = _report([
+        _diagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.error,
+          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        ),
+        _diagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.warning,
+          kind: SurfaceCatalogDiagnosticKind.unusedAnimation,
+        ),
+      ]);
+      final p = buildSurfaceCatalogDiagnosticsPresentation(report);
+      expect(
+        p.report.diagnostics.length,
+        report.diagnostics.length,
+      );
+      expect(
+        p.errors.length + p.warnings.length,
+        report.diagnostics.length,
+      );
+    });
+
+    test('17. section value equality: same==hash', () {
+      const e = SurfaceCatalogDiagnosticSeverity.error;
+      final a = _diagnostic(
+        severity: e,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: 'm',
+      );
+      final s1 = SurfaceCatalogDiagnosticsPresentationSection(
+        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
+        severity: e,
+        diagnostics: [a],
+      );
+      final s2 = SurfaceCatalogDiagnosticsPresentationSection(
+        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
+        severity: e,
+        diagnostics: [a],
+      );
+      expect(s1, s2);
+      expect(s1.hashCode, s2.hashCode);
+    });
+
+    test('18. section inequality: different diagnostic order', () {
+      const e = SurfaceCatalogDiagnosticSeverity.error;
+      final x = _diagnostic(
+        severity: e,
+        kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        message: '1',
+      );
+      final y = _diagnostic(
+        severity: e,
+        kind: SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+        message: '2',
+        atlasId: 'z',
+      );
+      final s1 = SurfaceCatalogDiagnosticsPresentationSection(
+        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
+        severity: e,
+        diagnostics: [x, y],
+      );
+      final s2 = SurfaceCatalogDiagnosticsPresentationSection(
+        kind: SurfaceCatalogDiagnosticsPresentationSectionKind.errors,
+        severity: e,
+        diagnostics: [y, x],
+      );
+      expect(s1, isNot(s2));
+    });
+
+    test('19. presentation equality: equivalent reports', () {
+      final a = <SurfaceCatalogDiagnostic>[
+        _diagnostic(
+          severity: SurfaceCatalogDiagnosticSeverity.error,
+          kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        ),
+      ];
+      final r1 = _report(a);
+      final r2 = _report(List<SurfaceCatalogDiagnostic>.from(a));
+      final p1 = buildSurfaceCatalogDiagnosticsPresentation(r1);
+      final p2 = buildSurfaceCatalogDiagnosticsPresentation(r2);
+      expect(p1, p2);
+      expect(p1.hashCode, p2.hashCode);
+    });
+
+    test('20. presentation inequality when content differs', () {
+      final p1 = buildSurfaceCatalogDiagnosticsPresentation(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.error,
+            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+            message: 'a',
+          ),
+        ]),
+      );
+      final p2 = buildSurfaceCatalogDiagnosticsPresentation(
+        _report([
+          _diagnostic(
+            severity: SurfaceCatalogDiagnosticSeverity.error,
+            kind: SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+            message: 'b',
+          ),
+        ]),
+      );
+      expect(p1, isNot(p2));
+    });
+
+    test('21. public API types via map_core', () {
+      final p = buildSurfaceCatalogDiagnosticsPresentation(_report([]));
+      expect(p, isA<SurfaceCatalogDiagnosticsPresentation>());
+      expect(
+        p.sections,
+        isA<List<SurfaceCatalogDiagnosticsPresentationSection>>(),
+      );
+      expect(
+        SurfaceCatalogDiagnosticsPresentationSectionKind.values.isNotEmpty,
+        isTrue,
+      );
+    });
+
+    test('22. ProjectManifest: no Surface keys (Lot 38)', () {
+      const manifest = ProjectManifest(
+        name: 'L38',
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
+    test('23. no unusedPreset kind; severities are error, warning', () {
+      final names =
+          SurfaceCatalogDiagnosticKind.values.map((e) => e.name).toList();
+      expect(names.contains('unusedPreset'), isFalse);
+      final sev = SurfaceCatalogDiagnosticSeverity.values
+          .map((e) => e.name)
+          .toList()
+        ..sort();
+      expect(sev, ['error', 'warning']);
+    });
+  });
+}
```

#### Rapport (exception contractuelle, fichier lui-même)

Un `git diff --no-index /dev/null` sur ce `.md` équivaut à préfixer chaque ligne du corps par `+` ; le contenu prouvé est le présent document en entier (§1–38).

## 38. Auto-check (substituts de preuve)

Recherche des formulations d'évidence listées en en-tête de lot (sans recopier la liste ici) : **aucun** emploi pour remplacer une preuve exigée.

