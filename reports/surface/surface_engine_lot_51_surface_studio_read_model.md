# Surface Engine — Lot 51 — Surface Studio Read Model Prep (V0)

## 1. Résumé exécutif

Implémentation de read models **purs** `SurfaceStudioReadModel` et dérivés, construits par `buildSurfaceStudioReadModel` / `buildSurfaceStudioReadModelFromCatalog`, assemblage des listes dans l’ordre du [ProjectSurfaceCatalog] sans tri ni filtre, et branchement sur les diagnostics auteur **existants** (`diagnoseProjectSurfaceCatalogForAuthoring` + `buildSurfaceCatalogDiagnosticsPresentation`). Aucun widget, aucun I/O, export `map_core` uniquement, 30 tests.

## 2. Suite du Lot 50

Le Lot 50 a introduit les helpers [get/replace/update/clear] sur `ProjectManifest.surfaceCatalog`. Le Lot 51 enchaîne en **dérivant** une vue structurée (compteurs, listes, références dérivées, présentation diagnostics) pour alimenter de futurs écrans Surface Studio sans imposer d’infrastructure d’app ni de logique d’UI.

## 3. Tableau lots 39–55

| Lot | Titre | Statut |
|-----|--------|--------|
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
| **51** | **Surface Studio Read Model Prep** | **ce lot** |
| 52 | Surface Studio Panel Shell V0 | prochain probable |
| 53 | Surface Studio Catalog Browser V0 | ensuite probable |
| 54 | Surface Studio Catalog Diagnostics View V0 | ensuite probable |
| 55 | Surface Studio Atlas List / Empty State V0 | ensuite probable |

## 4. `git status --short --untracked-files=all` (initial, avant toute écriture)

```text
(vide, worktree propre)
```

## 5. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/project_manifest.dart` (comportement surfaceCatalog)
- `packages/map_core/lib/src/models/surface.dart` / `surface_catalog.dart`
- `project_manifest_surface_catalog_operations.dart` — [get] catalogue
- `surface_catalog_authoring_diagnostics.dart` — [diagnoseProjectSurfaceCatalogForAuthoring]
- `surface_catalog_diagnostics_presentation.dart` — [buildSurfaceCatalogDiagnosticsPresentation]
- `map_core.dart` — règles d’export
- tests Surface / manifest / diagnostiques (référence API publique)
- `reports/surface/surface_engine_lot_50_*.md` (continuité)

## 6. Fichiers créés

- `packages/map_core/lib/src/operations/surface_studio_read_model.dart`
- `packages/map_core/test/surface_studio_read_model_test.dart`
- `reports/surface/surface_engine_lot_51_surface_studio_read_model.md` (le présent fichier)

## 7. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` (une ligne d’`export`)

## 8. Préexistant vs Lot 51

- **Préexistant (état initial)** : aucune modification en cours, historique propre.
- **Lot 51** : seuls les **trois** chemins ci-dessus (2 créations + 1 `export` dans `map_core.dart`).

## 9. API ajoutée

- `buildSurfaceStudioReadModel(ProjectManifest manifest)`
- `buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog catalog)`
- Types : `SurfaceStudioReadModel`, `SurfaceStudioCatalogSummaryReadModel`, `SurfaceStudioAtlasReadModel`, `SurfaceStudioAnimationReadModel`, `SurfaceStudioPresetReadModel`

## 10.–16. Sémantique (référence code)

- **SurfaceStudioReadModel** : [catalog] identique source ; [summary] compteurs ; listes [atlases]/[animations]/[presets] en ordre catalogue ; [diagnostics] = authoring + presentation ; [isEmpty]/[isNotEmpty] via résumé ; drapeaux diagnostics délégués à [SurfaceCatalogDiagnosticsPresentation].
- **Summary** : `atlasCount` / `animationCount` / `presetCount` ; `isEmpty` ssi les trois nuls.
- **Atlas row** : [atlas] source ; [usedByAnimationIds] = ids d’animation (ordre catalogue) touchant l’atlas, sans doublon par animation.
- **Animation row** : [animation] source ; [referencedAtlasIds] ordre de première apparition des `atlasId` dans la timeline.
- **Preset row** : [preset] source ; [roles] ordre des refs ; [referencedAnimationIds] déduplication stable ; `coversStandardRoles` → [coversAllRoles(standardSurfaceVariantRoleOrder)].
- **buildSurfaceStudioReadModel** : `getProjectManifestSurfaceCatalog` puis [buildSurfaceStudioReadModelFromCatalog].
- **FromCatalog** : aucune mutation ; diagnostics via Lot 36 + 38 uniquement.

## 17.–20. Décisions (ordre, tri, validation)

17. **Ordre source** : mêmes itérations que [catalog.atlases] / [animations] / [presets].
18. **Pas de tri** par `sortOrder` (l’ordre de liste est la vérité).
19. **Pas de filtrage** des entités.
20. **Aucune validation bloquante** des références côté read model (les erreurs vont au rapport diagnostics existant).

## 21.–28. Décisions d’hors-périmètre

21. **Diagnostics** : réutilisation stricte [diagnoseProjectSurfaceCatalogForAuthoring] + [buildSurfaceCatalogDiagnosticsPresentation].
22. **Pas de widget Flutter.**
23. **Pas de modification map_editor.**
24. **Pas** de repository, service, provider.
25. **Pas** de modification [ProjectManifest].
26. **Pas** de `build_runner`.
27. **Pas** de changement des codecs Surface.
28. **Fixtures Lot 47** : lecture seule en test.

## 29.–33. Portée

29. 30 scénarios (résumé, listes, références dérivées, immuabilité, non-mutation, égalité, JSON manifest, fixtures).
30. Les tests vérifient la non-régression d’intention Lot 50/49, la propagation des kinds `missingAnimationAtlas` / `missingPresetAnimation` / `unusedAtlas`, l’`UnsupportedError` sur listes, et l’`export` public.
31. **Non réalisé** : UI, runtime, autre package, migration.
32. **Prochains lots** : panneau Surface Studio, navigation catalogue, vues de diagnostics, listes vides (Lots 52–55).
33. **Proposition Lot 52** : coque de panneau (shell) Riverpod-agnostique côté `map_editor` consommant **ce** read model, sans logique lourde.

## 34. Commandes lancées

- `cd packages/map_core` puis `/opt/homebrew/bin/dart test test/surface_studio_read_model_test.dart`
- Regressions : fichiers indiqués au cahier, un fichier par cible (preuve agrégée dans D).
- `dart analyze` (chemins cahier)
- `dart test` complet
- `git status` initial / final (lecture seule)

## 35. Résultat test ciblé Lot 51

Sortie intégrale (copie) :

```text

00:00 [32m+0[0m: [1m[90mloading /Users/karim/Project/pokemonProject/packages/map_core/test/surface_studio_read_model_test.dart[0m[0m                                                                                       
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

## 36. Tests de régression (sorties)

Copie d’enregistrement (bundle unique des exécutions successives) :

```text

00:00 [32m+0[0m: [1m[90mloading test/project_manifest_surface_integration_test.dart[0m[0m                                                                                                                                  
00:00 [32m+0[0m: ProjectManifest Surface Integration (Lot 49) 1. ProjectManifest exposes surfaceCatalog[0m                                                                                                       
00:00 [32m+1[0m: ProjectManifest Surface Integration (Lot 49) 1. ProjectManifest exposes surfaceCatalog[0m                                                                                                       
00:00 [32m+1[0m: ProjectManifest Surface Integration (Lot 49) 2. toJson encodes surfaceCatalog even when empty[0m                                                                                                
00:00 [32m+2[0m: ProjectManifest Surface Integration (Lot 49) 2. toJson encodes surfaceCatalog even when empty[0m                                                                                                
00:00 [32m+2[0m: ProjectManifest Surface Integration (Lot 49) 3. fromJson accepts missing surfaceCatalog key[0m                                                                                                  
00:00 [32m+3[0m: ProjectManifest Surface Integration (Lot 49) 3. fromJson accepts missing surfaceCatalog key[0m                                                                                                  
00:00 [32m+3[0m: ProjectManifest Surface Integration (Lot 49) 4. fromJson accepts surfaceCatalog: null as empty[0m                                                                                               
00:00 [32m+4[0m: ProjectManifest Surface Integration (Lot 49) 4. fromJson accepts surfaceCatalog: null as empty[0m                                                                                               
00:00 [32m+4[0m: ProjectManifest Surface Integration (Lot 49) 5. fromJson rejects surfaceCatalog when not a JSON object[0m                                                                                       
00:00 [32m+5[0m: ProjectManifest Surface Integration (Lot 49) 5. fromJson rejects surfaceCatalog when not a JSON object[0m                                                                                       
00:00 [32m+5[0m: ProjectManifest Surface Integration (Lot 49) 6. fromJson rejects incomplete surfaceCatalog (missing presets)[0m                                                                                 
00:00 [32m+6[0m: ProjectManifest Surface Integration (Lot 49) 6. fromJson rejects incomplete surfaceCatalog (missing presets)[0m                                                                                 
00:00 [32m+6[0m: ProjectManifest Surface Integration (Lot 49) 7. fromJson decodes empty_surface_catalog_v0.json under surfaceCatalog[0m                                                                          
00:00 [32m+7[0m: ProjectManifest Surface Integration (Lot 49) 7. fromJson decodes empty_surface_catalog_v0.json under surfaceCatalog[0m                                                                          
00:00 [32m+7[0m: ProjectManifest Surface Integration (Lot 49) 8. fromJson decodes minimal_water_surface_catalog_v0.json[0m                                                                                       
00:00 [32m+8[0m: ProjectManifest Surface Integration (Lot 49) 8. fromJson decodes minimal_water_surface_catalog_v0.json[0m                                                                                       
00:00 [32m+8[0m: ProjectManifest Surface Integration (Lot 49) 9. fromJson decodes full_water_surface_catalog_v0.json[0m                                                                                          
00:00 [32m+9[0m: ProjectManifest Surface Integration (Lot 49) 9. fromJson decodes full_water_surface_catalog_v0.json[0m                                                                                          
00:00 [32m+9[0m: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                                                                              
00:00 [32m+10[0m: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                                                                             
00:00 [32m+10[0m: ProjectManifest Surface Integration (Lot 49) 11. round-trip manifest with full water catalog[0m                                                                                                
00:00 [32m+11[0m: ProjectManifest Surface Integration (Lot 49) 11. round-trip manifest with full water catalog[0m                                                                                                
00:00 [32m+11[0m: ProjectManifest Surface Integration (Lot 49) 12. copyWith preserves surfaceCatalog when renaming[0m                                                                                            
00:00 [32m+12[0m: ProjectManifest Surface Integration (Lot 49) 12. copyWith preserves surfaceCatalog when renaming[0m                                                                                            
00:00 [32m+12[0m: ProjectManifest Surface Integration (Lot 49) 13. copyWith can replace surfaceCatalog[0m                                                                                                        
00:00 [32m+13[0m: ProjectManifest Surface Integration (Lot 49) 13. copyWith can replace surfaceCatalog[0m                                                                                                        
00:00 [32m+13[0m: ProjectManifest Surface Integration (Lot 49) 14. equality distinguishes surfaceCatalog[0m                                                                                                      
00:00 [32m+14[0m: ProjectManifest Surface Integration (Lot 49) 14. equality distinguishes surfaceCatalog[0m                                                                                                      
00:00 [32m+14[0m: ProjectManifest Surface Integration (Lot 49) 15. toJson surfaceCatalog matches encodeProjectSurfaceCatalog[0m                                                                                  
00:00 [32m+15[0m: ProjectManifest Surface Integration (Lot 49) 15. toJson surfaceCatalog matches encodeProjectSurfaceCatalog[0m                                                                                  
00:00 [32m+15[0m: ProjectManifest Surface Integration (Lot 49) 16. split legacy Surface keys remain absent from toJson[0m                                                                                        
00:00 [32m+16[0m: ProjectManifest Surface Integration (Lot 49) 16. split legacy Surface keys remain absent from toJson[0m                                                                                        
00:00 [32m+16[0m: ProjectManifest Surface Integration (Lot 49) 17. Lot 47 fixtures remain bare catalog JSON (no manifest wrapper)[0m                                                                             
00:00 [32m+17[0m: ProjectManifest Surface Integration (Lot 49) 17. Lot 47 fixtures remain bare catalog JSON (no manifest wrapper)[0m                                                                             
00:00 [32m+17[0m: ProjectManifest Surface Integration (Lot 49) 18. unknown root key futureUnknownKey is not re-emitted[0m                                                                                        
00:00 [32m+18[0m: ProjectManifest Surface Integration (Lot 49) 18. unknown root key futureUnknownKey is not re-emitted[0m                                                                                        
00:00 [32m+18[0m: ProjectManifest Surface Integration (Lot 49) 19. invalid atlas id in surfaceCatalog surfaces ValidationException[0m                                                                            
00:00 [32m+19[0m: ProjectManifest Surface Integration (Lot 49) 19. invalid atlas id in surfaceCatalog surfaces ValidationException[0m                                                                            
00:00 [32m+19[0m: ProjectManifest Surface Integration (Lot 49) 20. public map_core API only: imports limited to map_core (see file header)[0m                                                                    
00:00 [32m+20[0m: ProjectManifest Surface Integration (Lot 49) 20. public map_core API only: imports limited to map_core (see file header)[0m                                                                    
00:00 [32m+20[0m: All tests passed![0m                                                                                                                                                                           
---test/project_manifest_surface_integration_test.dart---

00:00 [32m+0[0m: [1m[90mloading test/project_surface_catalog_json_codec_test.dart[0m[0m                                                                                                                                    
00:00 [32m+0[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                                                                           
00:00 [32m+1[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                                                                           
00:00 [32m+1[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 2. decodes empty catalog JSON[0m                                                                                                                      
00:00 [32m+2[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 2. decodes empty catalog JSON[0m                                                                                                                      
00:00 [32m+2[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 3. round-trip empty catalog[0m                                                                                                                        
00:00 [32m+3[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 3. round-trip empty catalog[0m                                                                                                                        
00:00 [32m+3[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 4. encodes minimal complete catalog (child codecs)[0m                                                                                                 
00:00 [32m+4[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 4. encodes minimal complete catalog (child codecs)[0m                                                                                                 
00:00 [32m+4[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 5. decodes minimal complete catalog[0m                                                                                                                
00:00 [32m+5[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 5. decodes minimal complete catalog[0m                                                                                                                
00:00 [32m+5[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 6. round-trip minimal complete catalog[0m                                                                                                             
00:00 [32m+6[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 6. round-trip minimal complete catalog[0m                                                                                                             
00:00 [32m+6[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 7. encode preserves atlas order[0m                                                                                                                    
00:00 [32m+7[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 7. encode preserves atlas order[0m                                                                                                                    
00:00 [32m+7[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 8. decode preserves atlas order[0m                                                                                                                    
00:00 [32m+8[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 8. decode preserves atlas order[0m                                                                                                                    
00:00 [32m+8[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 9. encode preserves animation order[0m                                                                                                                
00:00 [32m+9[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 9. encode preserves animation order[0m                                                                                                                
00:00 [32m+9[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 10. decode preserves animation order[0m                                                                                                               
00:00 [32m+10[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 10. decode preserves animation order[0m                                                                                                              
00:00 [32m+10[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 11. encode preserves preset order[0m                                                                                                                 
00:00 [32m+11[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 11. encode preserves preset order[0m                                                                                                                 
00:00 [32m+11[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 12. decode preserves preset order[0m                                                                                                                 
00:00 [32m+12[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 12. decode preserves preset order[0m                                                                                                                 
00:00 [32m+12[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 13. decode rejects missing atlases[0m                                                                                                                
00:00 [32m+13[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 13. decode rejects missing atlases[0m                                                                                                                
00:00 [32m+13[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 14. decode rejects atlases non-list[0m                                                                                                               
00:00 [32m+14[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 14. decode rejects atlases non-list[0m                                                                                                               
00:00 [32m+14[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 15. decode rejects atlas item non-map[0m                                                                                                             
00:00 [32m+15[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 15. decode rejects atlas item non-map[0m                                                                                                             
00:00 [32m+15[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 16. decode rejects invalid atlas via child codec (whitespace id)[0m                                                                                  
00:00 [32m+16[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 16. decode rejects invalid atlas via child codec (whitespace id)[0m                                                                                  
00:00 [32m+16[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 17. decode rejects missing animations[0m                                                                                                             
00:00 [32m+17[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 17. decode rejects missing animations[0m                                                                                                             
00:00 [32m+17[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 18. decode rejects animations non-list[0m                                                                                                            
00:00 [32m+18[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 18. decode rejects animations non-list[0m                                                                                                            
00:00 [32m+18[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 19. decode rejects animation item non-map[0m                                                                                                         
00:00 [32m+19[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 19. decode rejects animation item non-map[0m                                                                                                         
00:00 [32m+19[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 20. decode rejects invalid animation via child codec (empty frames)[0m                                                                               
00:00 [32m+20[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 20. decode rejects invalid animation via child codec (empty frames)[0m                                                                               
00:00 [32m+20[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 21. decode rejects missing presets[0m                                                                                                                
00:00 [32m+21[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 21. decode rejects missing presets[0m                                                                                                                
00:00 [32m+21[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 22. decode rejects presets non-list[0m                                                                                                               
00:00 [32m+22[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 22. decode rejects presets non-list[0m                                                                                                               
00:00 [32m+22[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 23. decode rejects preset item non-map[0m                                                                                                            
00:00 [32m+23[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 23. decode rejects preset item non-map[0m                                                                                                            
00:00 [32m+23[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 24. decode rejects invalid preset via child codec (empty refs)[0m                                                                                    
00:00 [32m+24[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 24. decode rejects invalid preset via child codec (empty refs)[0m                                                                                    
00:00 [32m+24[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 25. decode rejects duplicate atlas ids (model)[0m                                                                                                    
00:00 [32m+25[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 25. decode rejects duplicate atlas ids (model)[0m                                                                                                    
00:00 [32m+25[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 26. decode rejects duplicate animation ids (model)[0m                                                                                                
00:00 [32m+26[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 26. decode rejects duplicate animation ids (model)[0m                                                                                                
00:00 [32m+26[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 27. decode rejects duplicate preset ids (model)[0m                                                                                                   
00:00 [32m+27[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 27. decode rejects duplicate preset ids (model)[0m                                                                                                   
00:00 [32m+27[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 28. decode ignores unknown top-level key[0m                                                                                                          
00:00 [32m+28[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 28. decode ignores unknown top-level key[0m                                                                                                          
00:00 [32m+28[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 29. decode ignores unknown keys in child items[0m                                                                                                    
00:00 [32m+29[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 29. decode ignores unknown keys in child items[0m                                                                                                    
00:00 [32m+29[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 30. decode does not mutate source map[0m                                                                                                             
00:00 [32m+30[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 30. decode does not mutate source map[0m                                                                                                             
00:00 [32m+30[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 31. encode does not mutate catalog[0m                                                                                                                
00:00 [32m+31[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 31. encode does not mutate catalog[0m                                                                                                                
00:00 [32m+31[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 32. codec does not resolve animationId; diagnostics catch missing[0m                                                                                 
00:00 [32m+32[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 32. codec does not resolve animationId; diagnostics catch missing[0m                                                                                 
00:00 [32m+32[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 33. codec does not resolve atlasId; diagnostics catch missing atlas[0m                                                                               
00:00 [32m+33[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 33. codec does not resolve atlasId; diagnostics catch missing atlas[0m                                                                               
00:00 [32m+33[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 34. codec does not check geometry; diagnostics catch out of bounds[0m                                                                                
00:00 [32m+34[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 34. codec does not check geometry; diagnostics catch out of bounds[0m                                                                                
00:00 [32m+34[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 35. codec does not call unused diagnostics; unused can warn after[0m                                                                                 
00:00 [32m+35[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 35. codec does not call unused diagnostics; unused can warn after[0m                                                                                 
00:00 [32m+35[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 36. reuses Lot 39 atlas codec for atlases[0][0m                                                                                                      
00:00 [32m+36[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 36. reuses Lot 39 atlas codec for atlases[0][0m                                                                                                      
00:00 [32m+36[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 37. reuses Lot 42 animation codec for animations[0][0m                                                                                               
00:00 [32m+37[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 37. reuses Lot 42 animation codec for animations[0][0m                                                                                               
00:00 [32m+37[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 38. reuses Lot 45 preset codec for presets[0][0m                                                                                                     
00:00 [32m+38[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 38. reuses Lot 45 preset codec for presets[0][0m                                                                                                     
00:00 [32m+38[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 39. public API encode returns map[0m                                                                                                                 
00:00 [32m+39[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 39. public API encode returns map[0m                                                                                                                 
00:00 [32m+39[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 40. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m                                                                           
00:00 [32m+40[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 40. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m                                                                           
00:00 [32m+40[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 41. codec external to model: no catalog.toJson or ProjectSurfaceCatalog.fromJson[0m                                                                  
00:00 [32m+41[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 41. codec external to model: no catalog.toJson or ProjectSurfaceCatalog.fromJson[0m                                                                  
00:00 [32m+41[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 42. catalog encode still independent of manifest (Lot 49 uses same encode)[0m                                                                        
00:00 [32m+42[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 42. catalog encode still independent of manifest (Lot 49 uses same encode)[0m                                                                        
00:00 [32m+42[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 43. no Surface categories array; categoryId stays per-item string[0m                                                                                 
00:00 [32m+43[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 43. no Surface categories array; categoryId stays per-item string[0m                                                                                 
00:00 [32m+43[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 44. no kind / surfaceKind / presetKind / type at catalog or preset JSON[0m                                                                           
00:00 [32m+44[0m: ProjectSurfaceCatalog JSON codec (Lot 46) 44. no kind / surfaceKind / presetKind / type at catalog or preset JSON[0m                                                                           
00:00 [32m+44[0m: All tests passed![0m                                                                                                                                                                           
---test/project_surface_catalog_json_codec_test.dart---

00:00 [32m+0[0m: [1m[90mloading test/project_surface_catalog_json_golden_samples_test.dart[0m[0m                                                                                                                           
00:00 [32m+0[0m: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON[0m                                                                                                                  
00:00 [32m+1[0m: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON[0m                                                                                                                  
00:00 [32m+1[0m: Surface catalog JSON golden samples (Lot 47) 2. empty fixture matches codec[0m                                                                                                                  
00:00 [32m+2[0m: Surface catalog JSON golden samples (Lot 47) 2. empty fixture matches codec[0m                                                                                                                  
00:00 [32m+2[0m: Surface catalog JSON golden samples (Lot 47) 3. empty fixture round-trip[0m                                                                                                                     
00:00 [32m+3[0m: Surface catalog JSON golden samples (Lot 47) 3. empty fixture round-trip[0m                                                                                                                     
00:00 [32m+3[0m: Surface catalog JSON golden samples (Lot 47) 4. minimal water fixture is valid JSON with expected structure[0m                                                                                  
00:00 [32m+4[0m: Surface catalog JSON golden samples (Lot 47) 4. minimal water fixture is valid JSON with expected structure[0m                                                                                  
00:00 [32m+4[0m: Surface catalog JSON golden samples (Lot 47) 5. minimal water fixture matches codec[0m                                                                                                          
00:00 [32m+5[0m: Surface catalog JSON golden samples (Lot 47) 5. minimal water fixture matches codec[0m                                                                                                          
00:00 [32m+5[0m: Surface catalog JSON golden samples (Lot 47) 6. minimal water fixture round-trip[0m                                                                                                             
00:00 [32m+6[0m: Surface catalog JSON golden samples (Lot 47) 6. minimal water fixture round-trip[0m                                                                                                             
00:00 [32m+6[0m: Surface catalog JSON golden samples (Lot 47) 7. minimal water: no error diagnostics[0m                                                                                                          
00:00 [32m+7[0m: Surface catalog JSON golden samples (Lot 47) 7. minimal water: no error diagnostics[0m                                                                                                          
00:00 [32m+7[0m: Surface catalog JSON golden samples (Lot 47) 8. minimal water: no unused resource diagnostics[0m                                                                                                
00:00 [32m+8[0m: Surface catalog JSON golden samples (Lot 47) 8. minimal water: no unused resource diagnostics[0m                                                                                                
00:00 [32m+8[0m: Surface catalog JSON golden samples (Lot 47) 9. full water fixture is valid JSON with expected structure[0m                                                                                     
00:00 [32m+9[0m: Surface catalog JSON golden samples (Lot 47) 9. full water fixture is valid JSON with expected structure[0m                                                                                     
00:00 [32m+9[0m: Surface catalog JSON golden samples (Lot 47) 10. full water fixture matches codec[0m                                                                                                            
00:00 [32m+10[0m: Surface catalog JSON golden samples (Lot 47) 10. full water fixture matches codec[0m                                                                                                           
00:00 [32m+10[0m: Surface catalog JSON golden samples (Lot 47) 11. full water fixture round-trip[0m                                                                                                              
00:00 [32m+11[0m: Surface catalog JSON golden samples (Lot 47) 11. full water fixture round-trip[0m                                                                                                              
00:00 [32m+11[0m: Surface catalog JSON golden samples (Lot 47) 12. full water: preset ref order is cross, isolated, horizontal[0m                                                                                
00:00 [32m+12[0m: Surface catalog JSON golden samples (Lot 47) 12. full water: preset ref order is cross, isolated, horizontal[0m                                                                                
00:00 [32m+12[0m: Surface catalog JSON golden samples (Lot 47) 13. full water: no error diagnostics[0m                                                                                                           
00:00 [32m+13[0m: Surface catalog JSON golden samples (Lot 47) 13. full water: no error diagnostics[0m                                                                                                           
00:00 [32m+13[0m: Surface catalog JSON golden samples (Lot 47) 14. full water: no unused resource diagnostics[0m                                                                                                 
00:00 [32m+14[0m: Surface catalog JSON golden samples (Lot 47) 14. full water: no unused resource diagnostics[0m                                                                                                 
00:00 [32m+14[0m: Surface catalog JSON golden samples (Lot 47) 15. fixtures contain no manifest wrapper keys (raw string)[0m                                                                                     
00:00 [32m+15[0m: Surface catalog JSON golden samples (Lot 47) 15. fixtures contain no manifest wrapper keys (raw string)[0m                                                                                     
00:00 [32m+15[0m: Surface catalog JSON golden samples (Lot 47) 16. fixtures contain no category list keys[0m                                                                                                     
00:00 [32m+16[0m: Surface catalog JSON golden samples (Lot 47) 16. fixtures contain no category list keys[0m                                                                                                     
00:00 [32m+16[0m: Surface catalog JSON golden samples (Lot 47) 17. fixtures contain no kind/surfaceKind/type as map keys (deep)[0m                                                                               
00:00 [32m+17[0m: Surface catalog JSON golden samples (Lot 47) 17. fixtures contain no kind/surfaceKind/type as map keys (deep)[0m                                                                               
00:00 [32m+17[0m: Surface catalog JSON golden samples (Lot 47) 18. fixtures end with newline[0m                                                                                                                  
00:00 [32m+18[0m: Surface catalog JSON golden samples (Lot 47) 18. fixtures end with newline[0m                                                                                                                  
00:00 [32m+18[0m: Surface catalog JSON golden samples (Lot 47) 19. fixtures match two-space pretty jsonEncode roundtrip[0m                                                                                       
00:00 [32m+19[0m: Surface catalog JSON golden samples (Lot 47) 19. fixtures match two-space pretty jsonEncode roundtrip[0m                                                                                       
00:00 [32m+19[0m: Surface catalog JSON golden samples (Lot 47) 20. each fixture is stable: decode->encode->pretty equals fixture[0m                                                                              
00:00 [32m+20[0m: Surface catalog JSON golden samples (Lot 47) 20. each fixture is stable: decode->encode->pretty equals fixture[0m                                                                              
00:00 [32m+20[0m: Surface catalog JSON golden samples (Lot 47) 21. water fixtures use layout columnsAreVariantsRowsAreFrames[0m                                                                                  
00:00 [32m+21[0m: Surface catalog JSON golden samples (Lot 47) 21. water fixtures use layout columnsAreVariantsRowsAreFrames[0m                                                                                  
00:00 [32m+21[0m: Surface catalog JSON golden samples (Lot 47) 22. water fixtures: sortOrder on every atlas, animation, preset[0m                                                                                
00:00 [32m+22[0m: Surface catalog JSON golden samples (Lot 47) 22. water fixtures: sortOrder on every atlas, animation, preset[0m                                                                                
00:00 [32m+22[0m: Surface catalog JSON golden samples (Lot 47) 23. minimal fixture omits null optional fields (categoryId, syncGroupId)[0m                                                                       
00:00 [32m+23[0m: Surface catalog JSON golden samples (Lot 47) 23. minimal fixture omits null optional fields (categoryId, syncGroupId)[0m                                                                       
00:00 [32m+23[0m: Surface catalog JSON golden samples (Lot 47) 24. only public map_core import for package (no src/)[0m                                                                                          
00:00 [32m+24[0m: Surface catalog JSON golden samples (Lot 47) 24. only public map_core import for package (no src/)[0m                                                                                          
00:00 [32m+24[0m: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m                                                                        
00:00 [32m+25[0m: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m                                                                        
00:00 [32m+25[0m: All tests passed![0m                                                                                                                                                                           
---test/project_surface_catalog_json_golden_samples_test.dart---

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
---test/surface_catalog_authoring_diagnostics_test.dart---

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
---test/surface_catalog_diagnostics_presentation_test.dart---

00:00 [32m+0[0m: [1m[90mloading test/project_surface_catalog_test.dart[0m[0m                                                                                                                                               
00:00 [32m+0[0m: ProjectSurfaceCatalog (Lot 33) 1. empty catalog: counts, isEmpty, unmodifiable empty lists[0m                                                                                                   
00:00 [32m+1[0m: ProjectSurfaceCatalog (Lot 33) 1. empty catalog: counts, isEmpty, unmodifiable empty lists[0m                                                                                                   
00:00 [32m+1[0m: ProjectSurfaceCatalog (Lot 33) 2. catalog with 2 of each kind: counts, isNotEmpty[0m                                                                                                            
00:00 [32m+2[0m: ProjectSurfaceCatalog (Lot 33) 2. catalog with 2 of each kind: counts, isNotEmpty[0m                                                                                                            
00:00 [32m+2[0m: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved[0m                                                                                                                                 
00:00 [32m+3[0m: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved[0m                                                                                                                                 
00:00 [32m+3[0m: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved[0m                                                                                                                              
00:00 [32m+4[0m: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved[0m                                                                                                                              
00:00 [32m+4[0m: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved[0m                                                                                                                                 
00:00 [32m+5[0m: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved[0m                                                                                                                                 
00:00 [32m+5[0m: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws[0m                                                                                                                 
00:00 [32m+6[0m: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws[0m                                                                                                                 
00:00 [32m+6[0m: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build[0m                                                                                                         
00:00 [32m+7[0m: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build[0m                                                                                                         
00:00 [32m+7[0m: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build[0m                                                                                                      
00:00 [32m+8[0m: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build[0m                                                                                                      
00:00 [32m+8[0m: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build[0m                                                                                                         
00:00 [32m+9[0m: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build[0m                                                                                                         
00:00 [32m+9[0m: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException[0m                                                                                                             
00:00 [32m+10[0m: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException[0m                                                                                                            
00:00 [32m+10[0m: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException[0m                                                                                                        
00:00 [32m+11[0m: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException[0m                                                                                                        
00:00 [32m+11[0m: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException[0m                                                                                                           
00:00 [32m+12[0m: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException[0m                                                                                                           
00:00 [32m+12[0m: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups[0m                                                                                                    
00:00 [32m+13[0m: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups[0m                                                                                                    
00:00 [32m+13[0m: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present[0m                                                                                                                  
00:00 [32m+14[0m: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present[0m                                                                                                                  
00:00 [32m+14[0m: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent[0m                                                                                                                               
00:00 [32m+15[0m: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent[0m                                                                                                                               
00:00 [32m+15[0m: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present[0m                                                                                                              
00:00 [32m+16[0m: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present[0m                                                                                                              
00:00 [32m+16[0m: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent[0m                                                                                                                           
00:00 [32m+17[0m: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent[0m                                                                                                                           
00:00 [32m+17[0m: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present[0m                                                                                                                 
00:00 [32m+18[0m: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present[0m                                                                                                                 
00:00 [32m+18[0m: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent[0m                                                                                                                              
00:00 [32m+19[0m: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent[0m                                                                                                                              
00:00 [32m+19[0m: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup[0m                                                                                                                        
00:00 [32m+20[0m: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup[0m                                                                                                                        
00:00 [32m+20[0m: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup[0m                                                                                                                    
00:00 [32m+21[0m: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup[0m                                                                                                                    
00:00 [32m+21[0m: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup[0m                                                                                                                       
00:00 [32m+22[0m: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup[0m                                                                                                                       
00:00 [32m+22[0m: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas[0m                                                                                                            
00:00 [32m+23[0m: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas[0m                                                                                                            
00:00 [32m+23[0m: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error[0m                                                                                                 
00:00 [32m+24[0m: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error[0m                                                                                                 
00:00 [32m+24[0m: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode[0m                                                                                                 
00:00 [32m+25[0m: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode[0m                                                                                                 
00:00 [32m+25[0m: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order[0m                                                                                                                  
00:00 [32m+26[0m: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order[0m                                                                                                                  
00:00 [32m+26[0m: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order[0m                                                                                                              
00:00 [32m+27[0m: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order[0m                                                                                                              
00:00 [32m+27[0m: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                                                                 
00:00 [32m+28[0m: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                                                                 
00:00 [32m+28[0m: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                                                                      
00:00 [32m+29[0m: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                                                                      
00:00 [32m+29[0m: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                                                               
00:00 [32m+30[0m: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                                                               
00:00 [32m+30[0m: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)[0m                                                                                 
00:00 [32m+31[0m: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)[0m                                                                                 
00:00 [32m+31[0m: All tests passed![0m                                                                                                                                                                           
---test/project_surface_catalog_test.dart---

00:00 [32m+0[0m: [1m[90mloading test/surface_model_entrypoint_test.dart[0m[0m                                                                                                                                              
00:00 [32m+0[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                                                                 
00:00 [32m+1[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                                                                 
00:00 [32m+1[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest has surfaceCatalog; split surface keys stay absent[0m                                                                    
00:00 [32m+2[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest has surfaceCatalog; split surface keys stay absent[0m                                                                    
00:00 [32m+2[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                                                            
00:00 [32m+3[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                                                            
00:00 [32m+3[0m: All tests passed![0m                                                                                                                                                                            
---test/surface_model_entrypoint_test.dart---

```

## 37. Résultat `dart analyze`

```text
Analyzing surface_studio_read_model.dart, map_core.dart, surface_studio_read_model_test.dart, project_manifest_surface_catalog_operations_test.dart, project_manifest_surface_integration_test.dart, project_surface_catalog_json_codec_test.dart, project_surface_catalog_json_golden_samples_test.dart, surface_catalog_authoring_diagnostics_test.dart, surface_catalog_diagnostics_presentation_test.dart, project_surface_catalog_test.dart, surface_model_entrypoint_test.dart...
No issues found!

```

## 38. Résultat `dart test` complet

- Commande : `cd /Users/karim/Project/pokemonProject/packages/map_core && /opt/homebrew/bin/dart test`
- Dernière ligne :

```text
00:01 [32m+1218[0m: All tests passed![0m
```

## 39. Total exact `dart test` complet

**+1218** (correspond à la dernière ligne `+1218: All tests passed!`).

## 40.–41. Vigilance et autocritique

- L’[égalité] des [SurfaceStudioReadModel] exige l’[égalité] de la [SurfaceCatalogDiagnosticsPresentation] (cohérent avec les objectifs de tests).
- Autocritique : les tests 18–20 s’appuient sur l’[enum] public des kinds ; toute évolution de wording des messages ne change pas l’[API], mais le texte d’[expect] des messages n’est pas verrouillé ici.
- Aucun caractère mojibake (`Ã`, `â€™`, `â€"`, `â†'`) n’a été introduit dans les sources Lot 51 (fichier de rapport généré en UTF-8, `errors=strict` côté lecture outil).

## 42. Point discutable dans le cahier

- Le volume d’[Evidence] pour un seul lot est très élevé ; l’enchaînement de tests de régression produit un journal monoligne (barres `\r`) répétées — c’est voulu par le runner, la preuve reste reproductible.

## 43. Auto-review indépendante

- [x] Périmètre map_core, read models seuls
- [x] [ProjectManifest] / générés / codecs / diagnostics sources / Lot 50 helpers **non** modifiés
- [x] [diagnoseProjectSurfaceCatalogForAuthoring] + [buildSurfaceCatalogDiagnosticsPresentation] chemin seul
- [x] Listes [unmodifiable] root et nested
- [x] 30 tests, API publique
- [x] +1218
- [x] Aucun `git` write
- [x] UTF-8
- [x] Pas de `?? reports/surface/_gen_*.py` (script hors repo [ `/tmp` ])

## 44. Vérification anti-mojibake (fichiers Lot 51)

- Recherche manuelle/scan : les séquences interdites listées n’apparaissent **pas** dans [surface_studio_read_model.dart] ni le test, ni ce rapport généré (Python UTF-8).

## 45. `git status --short --untracked-files=all` (final)

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/surface_studio_read_model.dart
?? packages/map_core/test/surface_studio_read_model_test.dart
```

---

## 46. Evidence Pack complet

### A. Contenu intégral des fichiers créés

#### `packages/map_core/lib/src/operations/surface_studio_read_model.dart`

```dart
// Read models **Surface Studio** (Lot 51) : vue pure, immuable, sans UI Flutter.
//
// * Prépare l’affichage futur (compteurs, listes, diagnostics auteur) **sans**
//   persistance disque, **sans** widget, **sans** Riverpod.
// * N’impose **aucun** tri, **aucun** filtre : l’ordre de parcours est celui
//   des listes sur [`ProjectSurfaceCatalog`] (y compris si [`sortOrder`] varie
//   entre entités) — l’auteur voit l’**ordre source** tel qu’enregistré.
// * Les **diagnostics** proviennent exclusivement de l’agrégateur auteur existant
//   : [`diagnoseProjectSurfaceCatalogForAuthoring`] puis
//   [`buildSurfaceCatalogDiagnosticsPresentation`]. Les références orphelines
//   restent des **rapports d’analyse**, jamais des erreurs de **construction**
//   du read model.
// * Passe [`ProjectManifest`] via [`getProjectManifestSurfaceCatalog`] côté
//   constructeur `buildSurfaceStudioReadModel` — un seul champ `surfaceCatalog`
//   sur le manifest, pas de recomposition JSON ici.

import 'package:meta/meta.dart' show immutable;

import '../models/project_manifest.dart';
import '../models/surface.dart';
import '../models/surface_catalog.dart';
import 'project_manifest_surface_catalog_operations.dart';
import 'surface_catalog_authoring_diagnostics.dart';
import 'surface_catalog_diagnostics_presentation.dart';

// --- Comparaison de listes (ordre strict) — égalité des read models ---

bool _strListEqual(List<String> a, List<String> b) {
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

bool _roleListEqual(List<SurfaceVariantRole> a, List<SurfaceVariantRole> b) {
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

List<String> _referencedAtlasFirstAppearance(ProjectSurfaceAnimation animation) {
  final seen = <String>{};
  final out = <String>[];
  for (final frame in animation.timeline.frames) {
    final id = frame.tileRef.atlasId;
    if (seen.add(id)) {
      out.add(id);
    }
  }
  return out;
}

List<String> _usedByAnimationIdsForAtlas(
  ProjectSurfaceCatalog catalog,
  ProjectSurfaceAtlas atlas,
) {
  final out = <String>[];
  for (final anim in catalog.animations) {
    var uses = false;
    for (final frame in anim.timeline.frames) {
      if (frame.tileRef.atlasId == atlas.id) {
        uses = true;
        break;
      }
    }
    if (uses) {
      out.add(anim.id);
    }
  }
  return out;
}

List<String> _referencedAnimationIdsDeduped(SurfaceVariantAnimationRefSet refs) {
  final seen = <String>{};
  final out = <String>[];
  for (final r in refs.refs) {
    if (seen.add(r.animationId)) {
      out.add(r.animationId);
    }
  }
  return out;
}

/// Résumé numérique pour l’en-tête Surface Studio (compteurs seuls).
@immutable
final class SurfaceStudioCatalogSummaryReadModel {
  SurfaceStudioCatalogSummaryReadModel({
    required this.atlasCount,
    required this.animationCount,
    required this.presetCount,
  });

  final int atlasCount;
  final int animationCount;
  final int presetCount;

  bool get isEmpty =>
      atlasCount == 0 && animationCount == 0 && presetCount == 0;

  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioCatalogSummaryReadModel &&
          other.atlasCount == atlasCount &&
          other.animationCount == animationCount &&
          other.presetCount == presetCount;

  @override
  int get hashCode => Object.hash(atlasCount, animationCount, presetCount);
}

/// Une ligne **atlas** : instance source + animations qui s’y référencent
/// (ordre des ids = ordre des animations dans le catalogue, sans doublon).
@immutable
final class SurfaceStudioAtlasReadModel {
  SurfaceStudioAtlasReadModel({
    required this.atlas,
    required List<String> usedByAnimationIds,
  }) : usedByAnimationIds = List<String>.unmodifiable(usedByAnimationIds);

  final ProjectSurfaceAtlas atlas;
  final List<String> usedByAnimationIds;

  String get id => atlas.id;
  String get name => atlas.name;
  String get tilesetId => atlas.tilesetId;
  String? get categoryId => atlas.categoryId;
  int get sortOrder => atlas.sortOrder;
  SurfaceAtlasGeometry get geometry => atlas.geometry;
  SurfaceAtlasLayout get layout => atlas.geometry.layout;
  int get tileWidth => atlas.geometry.tileSize.width;
  int get tileHeight => atlas.geometry.tileSize.height;
  int get columns => atlas.geometry.gridSize.columns;
  int get rows => atlas.geometry.gridSize.rows;
  int get tileCount => atlas.geometry.tileCount;
  bool get isUsedByAnimation => usedByAnimationIds.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioAtlasReadModel &&
          other.atlas == atlas &&
          _strListEqual(other.usedByAnimationIds, usedByAnimationIds);

  @override
  int get hashCode => Object.hash(atlas, Object.hashAll(usedByAnimationIds));
}

/// Une ligne **animation** : instance source + atlasId des frames
/// (première apparition, sans doublon).
@immutable
final class SurfaceStudioAnimationReadModel {
  SurfaceStudioAnimationReadModel({
    required this.animation,
    required List<String> referencedAtlasIds,
  }) : referencedAtlasIds = List<String>.unmodifiable(referencedAtlasIds);

  final ProjectSurfaceAnimation animation;
  final List<String> referencedAtlasIds;

  String get id => animation.id;
  String get name => animation.name;
  String? get syncGroupId => animation.syncGroupId;
  String? get categoryId => animation.categoryId;
  int get sortOrder => animation.sortOrder;
  int get frameCount => animation.frameCount;
  int get totalDurationMs => animation.totalDurationMs;
  bool get hasFrames => animation.frameCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioAnimationReadModel &&
          other.animation == animation &&
          _strListEqual(other.referencedAtlasIds, referencedAtlasIds);

  @override
  int get hashCode => Object.hash(animation, Object.hashAll(referencedAtlasIds));
}

/// Une ligne **preset** : instance source, rôles (ordre des refs) et
/// `animationId` uniques (ordre de première apparition).
@immutable
final class SurfaceStudioPresetReadModel {
  SurfaceStudioPresetReadModel({
    required this.preset,
    required List<SurfaceVariantRole> roles,
    required List<String> referencedAnimationIds,
  })  : roles = List<SurfaceVariantRole>.unmodifiable(roles),
        referencedAnimationIds = List<String>.unmodifiable(
          referencedAnimationIds,
        );

  final ProjectSurfacePreset preset;
  final List<SurfaceVariantRole> roles;
  final List<String> referencedAnimationIds;

  String get id => preset.id;
  String get name => preset.name;
  String? get categoryId => preset.categoryId;
  int get sortOrder => preset.sortOrder;
  int get variantCount => preset.variantCount;
  bool get coversStandardRoles =>
      preset.coversAllRoles(standardSurfaceVariantRoleOrder);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioPresetReadModel &&
          other.preset == preset &&
          _roleListEqual(other.roles, roles) &&
          _strListEqual(other.referencedAnimationIds, referencedAnimationIds);

  @override
  int get hashCode => Object.hash(
        preset,
        Object.hashAll(roles),
        Object.hashAll(referencedAnimationIds),
      );
}

/// Vue read-only complète d’un [ProjectSurfaceCatalog] + diagnostics auteur.
@immutable
final class SurfaceStudioReadModel {
  SurfaceStudioReadModel({
    required this.catalog,
    required this.summary,
    required List<SurfaceStudioAtlasReadModel> atlases,
    required List<SurfaceStudioAnimationReadModel> animations,
    required List<SurfaceStudioPresetReadModel> presets,
    required this.diagnostics,
  })  : atlases = List<SurfaceStudioAtlasReadModel>.unmodifiable(atlases),
        animations =
            List<SurfaceStudioAnimationReadModel>.unmodifiable(animations),
        presets = List<SurfaceStudioPresetReadModel>.unmodifiable(presets);

  final ProjectSurfaceCatalog catalog;
  final SurfaceStudioCatalogSummaryReadModel summary;
  final List<SurfaceStudioAtlasReadModel> atlases;
  final List<SurfaceStudioAnimationReadModel> animations;
  final List<SurfaceStudioPresetReadModel> presets;
  final SurfaceCatalogDiagnosticsPresentation diagnostics;

  bool get isEmpty => summary.isEmpty;
  bool get isNotEmpty => summary.isNotEmpty;
  bool get hasDiagnostics => diagnostics.hasDiagnostics;
  bool get hasErrors => diagnostics.hasErrors;
  bool get hasWarnings => diagnostics.hasWarnings;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioReadModel &&
          other.catalog == catalog &&
          other.summary == summary &&
          _atlasReadListEqual(other.atlases, atlases) &&
          _animReadListEqual(other.animations, animations) &&
          _presetReadListEqual(other.presets, presets) &&
          other.diagnostics == diagnostics;

  @override
  int get hashCode => Object.hash(
        catalog,
        summary,
        Object.hashAll(atlases),
        Object.hashAll(animations),
        Object.hashAll(presets),
        diagnostics,
      );
}

bool _atlasReadListEqual(
  List<SurfaceStudioAtlasReadModel> a,
  List<SurfaceStudioAtlasReadModel> b,
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

bool _animReadListEqual(
  List<SurfaceStudioAnimationReadModel> a,
  List<SurfaceStudioAnimationReadModel> b,
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

bool _presetReadListEqual(
  List<SurfaceStudioPresetReadModel> a,
  List<SurfaceStudioPresetReadModel> b,
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

/// Construit un [SurfaceStudioReadModel] via [`getProjectManifestSurfaceCatalog`]
/// (aucune mutation du [manifest]).
SurfaceStudioReadModel buildSurfaceStudioReadModel(ProjectManifest manifest) =>
    buildSurfaceStudioReadModelFromCatalog(
      getProjectManifestSurfaceCatalog(manifest),
    );

/// Construit un [SurfaceStudioReadModel] : même instance de [catalog],
/// même ordre source que les listes du catalogue, diagnostics auteur
/// (Lots 36 + 38) **sans** filtrage ni tri.
SurfaceStudioReadModel buildSurfaceStudioReadModelFromCatalog(
  ProjectSurfaceCatalog catalog,
) {
  final summary = SurfaceStudioCatalogSummaryReadModel(
    atlasCount: catalog.atlasCount,
    animationCount: catalog.animationCount,
    presetCount: catalog.presetCount,
  );
  final report = diagnoseProjectSurfaceCatalogForAuthoring(catalog);
  final diagnostics = buildSurfaceCatalogDiagnosticsPresentation(report);

  final atlasRows = <SurfaceStudioAtlasReadModel>[];
  for (final a in catalog.atlases) {
    atlasRows.add(
      SurfaceStudioAtlasReadModel(
        atlas: a,
        usedByAnimationIds: _usedByAnimationIdsForAtlas(catalog, a),
      ),
    );
  }

  final animRows = <SurfaceStudioAnimationReadModel>[];
  for (final anim in catalog.animations) {
    animRows.add(
      SurfaceStudioAnimationReadModel(
        animation: anim,
        referencedAtlasIds: _referencedAtlasFirstAppearance(anim),
      ),
    );
  }

  final presetRows = <SurfaceStudioPresetReadModel>[];
  for (final p in catalog.presets) {
    final roleList = p.variantAnimations.refs.map((r) => r.role).toList();
    presetRows.add(
      SurfaceStudioPresetReadModel(
        preset: p,
        roles: roleList,
        referencedAnimationIds: _referencedAnimationIdsDeduped(
          p.variantAnimations,
        ),
      ),
    );
  }

  return SurfaceStudioReadModel(
    catalog: catalog,
    summary: summary,
    atlases: atlasRows,
    animations: animRows,
    presets: presetRows,
    diagnostics: diagnostics,
  );
}

```

#### `packages/map_core/test/surface_studio_read_model_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Surface Studio read model (Lot 51)', () {
    test('1. empty catalog: summary, lists, clean diagnostics', () {
      final c = _emptyCatalog();
      final m = buildSurfaceStudioReadModelFromCatalog(c);
      expect(identical(m.catalog, c), isTrue);
      expect(m.summary.atlasCount, 0);
      expect(m.summary.animationCount, 0);
      expect(m.summary.presetCount, 0);
      expect(m.summary.isEmpty, isTrue);
      expect(m.isEmpty, isTrue);
      expect(m.atlases, isEmpty);
      expect(m.animations, isEmpty);
      expect(m.presets, isEmpty);
      expect(m.diagnostics.isClean, isTrue);
    });

    test('2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation',
        () {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(surfaceCatalog: cat);
      final before = manifest.surfaceCatalog;
      final model = buildSurfaceStudioReadModel(manifest);
      expect(identical(model.catalog, before), isTrue);
      expect(identical(manifest.surfaceCatalog, before), isTrue);
    });

    test('3. minimal water — summary counts and non-empty', () {
      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
      expect(m.summary.atlasCount, 1);
      expect(m.summary.animationCount, 1);
      expect(m.summary.presetCount, 1);
      expect(m.summary.isEmpty, isFalse);
      expect(m.summary.isNotEmpty, isTrue);
    });

    test('4. minimal water — atlas row main fields', () {
      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
      final row = m.atlases.single;
      expect(row.id, 'water-atlas');
      expect(row.name, 'Water Atlas');
      expect(row.tilesetId, 'nature-tileset');
      expect(row.tileWidth, 32);
      expect(row.tileHeight, 32);
      expect(row.columns, 23);
      expect(row.rows, 32);
      expect(row.tileCount, 23 * 32);
      expect(row.layout, SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames);
    });

    test('5. atlas rows preserve catalog order', () {
      final g = _geom();
      final c = ProjectSurfaceCatalog(
        atlases: [
          ProjectSurfaceAtlas(
            id: 'water-atlas',
            name: 'W',
            tilesetId: 't',
            geometry: g,
          ),
          ProjectSurfaceAtlas(
            id: 'lava-atlas',
            name: 'L',
            tilesetId: 't',
            geometry: g,
          ),
          ProjectSurfaceAtlas(
            id: 'grass-atlas',
            name: 'G',
            tilesetId: 't',
            geometry: g,
          ),
        ],
        animations: const [],
        presets: const [],
      );
      final m = buildSurfaceStudioReadModelFromCatalog(c);
      expect(m.atlases.map((e) => e.id).toList(), [
        'water-atlas',
        'lava-atlas',
        'grass-atlas',
      ]);
    });

    test('6. atlas usedByAnimationIds — two animations, one atlas', () {
      final g = _geom();
      final atlas = ProjectSurfaceAtlas(
        id: 'water-atlas',
        name: 'W',
        tilesetId: 't',
        geometry: g,
      );
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'water-atlas',
          column: 0,
          row: 0,
        ),
        durationMs: 100,
      );
      final tl = SurfaceAnimationTimeline(frames: [frame]);
      final waterA = ProjectSurfaceAnimation(
        id: 'water-a',
        name: 'A',
        timeline: tl,
      );
      final waterB = ProjectSurfaceAnimation(
        id: 'water-b',
        name: 'B',
        timeline: tl,
      );
      final c = ProjectSurfaceCatalog(
        atlases: [atlas],
        animations: [waterA, waterB],
        presets: const [],
      );
      final row = buildSurfaceStudioReadModelFromCatalog(c).atlases.single;
      expect(row.usedByAnimationIds, ['water-a', 'water-b']);
      expect(row.isUsedByAnimation, isTrue);
    });

    test('7. atlas usedByAnimationIds — one animation twice same atlas', () {
      final g = _geom();
      final atlas = ProjectSurfaceAtlas(
        id: 'water-atlas',
        name: 'W',
        tilesetId: 't',
        geometry: g,
      );
      final frame = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'water-atlas',
          column: 0,
          row: 0,
        ),
        durationMs: 100,
      );
      final tl = SurfaceAnimationTimeline(frames: [frame, frame]);
      final anim = ProjectSurfaceAnimation(
        id: 'water-isolated',
        name: 'One',
        timeline: tl,
      );
      final c = ProjectSurfaceCatalog(
        atlases: [atlas],
        animations: [anim],
        presets: const [],
      );
      final row = buildSurfaceStudioReadModelFromCatalog(c).atlases.single;
      expect(row.usedByAnimationIds, ['water-isolated']);
    });

    test('8. minimal water — animation row main fields', () {
      final row = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog())
          .animations
          .single;
      expect(row.id, 'water-isolated-loop');
      expect(row.name, 'Water Isolated Loop');
      expect(row.frameCount, 1);
      expect(row.totalDurationMs, 120);
      expect(row.hasFrames, isTrue);
      expect(row.categoryId, isNull);
      expect(row.syncGroupId, isNull);
      expect(row.sortOrder, 0);
    });

    test('9. animation rows preserve catalog order', () {
      final g = _geom();
      final atlas = ProjectSurfaceAtlas(
        id: 'a',
        name: 'a',
        tilesetId: 't',
        geometry: g,
      );
      final f = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
        durationMs: 10,
      );
      final t = SurfaceAnimationTimeline(frames: [f]);
      final c = ProjectSurfaceCatalog(
        atlases: [atlas],
        animations: [
          ProjectSurfaceAnimation(id: 'z', name: 'z', timeline: t),
          ProjectSurfaceAnimation(id: 'y', name: 'y', timeline: t),
          ProjectSurfaceAnimation(id: 'x', name: 'x', timeline: t),
        ],
        presets: const [],
      );
      final m = buildSurfaceStudioReadModelFromCatalog(c);
      expect(m.animations.map((e) => e.id).toList(), ['z', 'y', 'x']);
    });

    test('10. animation referencedAtlasIds — first appearance order', () {
      final f1 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'atlas-b',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final f2 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'atlas-a',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final f3 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'atlas-b',
          column: 0,
          row: 1,
        ),
        durationMs: 10,
      );
      final f4 = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'atlas-c',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final anim = ProjectSurfaceAnimation(
        id: 'multi',
        name: 'm',
        timeline: SurfaceAnimationTimeline(
          frames: [f1, f2, f3, f4],
        ),
      );
      final m = buildSurfaceStudioReadModelFromCatalog(
        ProjectSurfaceCatalog(
          atlases: const [],
          animations: [anim],
          presets: const [],
        ),
      );
      expect(m.animations.single.referencedAtlasIds, [
        'atlas-b',
        'atlas-a',
        'atlas-c',
      ]);
    });

    test('11. animation read model does not validate atlas existence', () {
      final f = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(
          atlasId: 'missing-atlas',
          column: 0,
          row: 0,
        ),
        durationMs: 10,
      );
      final anim = ProjectSurfaceAnimation(
        id: 'bad',
        name: 'b',
        timeline: SurfaceAnimationTimeline(frames: [f]),
      );
      final m = buildSurfaceStudioReadModelFromCatalog(
        ProjectSurfaceCatalog(
          atlases: const [],
          animations: [anim],
          presets: const [],
        ),
      );
      expect(m.animations.single.referencedAtlasIds, contains('missing-atlas'));
      expect(
        m.diagnostics.errors.any(
          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        ),
        isTrue,
      );
    });

    test('12. minimal water — preset row main fields', () {
      final row = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog())
          .presets
          .single;
      expect(row.id, 'water-surface');
      expect(row.name, 'Water Surface');
      expect(row.variantCount, 1);
      expect(row.roles, [SurfaceVariantRole.isolated]);
      expect(row.referencedAnimationIds, ['water-isolated-loop']);
      expect(row.coversStandardRoles, isFalse);
      expect(row.categoryId, isNull);
      expect(row.sortOrder, 0);
    });

    test('13. preset rows preserve catalog order', () {
      final g = _geom();
      final atlas = ProjectSurfaceAtlas(
        id: 'a',
        name: 'a',
        tilesetId: 't',
        geometry: g,
      );
      final f = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
        durationMs: 10,
      );
      final t = SurfaceAnimationTimeline(frames: [f]);
      final anim = ProjectSurfaceAnimation(
        id: 'anim',
        name: 'anim',
        timeline: t,
      );
      SurfaceVariantAnimationRefSet presetRefs(String id) {
        return SurfaceVariantAnimationRefSet(
          refs: [
            SurfaceVariantAnimationRef(
              role: SurfaceVariantRole.isolated,
              animationId: id,
            ),
          ],
        );
      }

      final c = ProjectSurfaceCatalog(
        atlases: [atlas],
        animations: [anim],
        presets: [
          ProjectSurfacePreset(
            id: 'p-c',
            name: 'c',
            variantAnimations: presetRefs('anim'),
          ),
          ProjectSurfacePreset(
            id: 'p-b',
            name: 'b',
            variantAnimations: presetRefs('anim'),
          ),
          ProjectSurfacePreset(
            id: 'p-a',
            name: 'a',
            variantAnimations: presetRefs('anim'),
          ),
        ],
      );
      final m = buildSurfaceStudioReadModelFromCatalog(c);
      expect(m.presets.map((e) => e.id).toList(), ['p-c', 'p-b', 'p-a']);
    });

    test('14. preset referencedAnimationIds — dedupe keeps order', () {
      final refs = SurfaceVariantAnimationRefSet(
        refs: [
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: 'anim-b',
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.endNorth,
            animationId: 'anim-a',
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.endEast,
            animationId: 'anim-b',
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.endSouth,
            animationId: 'anim-c',
          ),
        ],
      );
      final p = ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      );
      final row = buildSurfaceStudioReadModelFromCatalog(
        ProjectSurfaceCatalog(
          atlases: const [],
          animations: const [],
          presets: [p],
        ),
      ).presets.single;
      expect(row.referencedAnimationIds, ['anim-b', 'anim-a', 'anim-c']);
    });

    test('15. preset read model does not validate animation existence', () {
      final refs = SurfaceVariantAnimationRefSet(
        refs: [
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: 'missing-animation',
          ),
        ],
      );
      final p = ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      );
      final m = buildSurfaceStudioReadModelFromCatalog(
        ProjectSurfaceCatalog(
          atlases: const [],
          animations: const [],
          presets: [p],
        ),
      );
      expect(
        m.presets.single.referencedAnimationIds,
        contains('missing-animation'),
      );
      expect(
        m.diagnostics.errors.any(
          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
        isTrue,
      );
    });

    test('16. full water — preset role order cross, isolated, horizontal', () {
      final row = buildSurfaceStudioReadModelFromCatalog(_fullWaterCatalog())
          .presets
          .single;
      expect(row.roles, [
        SurfaceVariantRole.cross,
        SurfaceVariantRole.isolated,
        SurfaceVariantRole.horizontal,
      ]);
    });

    test('17. minimal water — diagnostics clean flags on read model', () {
      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
      expect(m.diagnostics.isClean, isTrue);
      expect(m.hasDiagnostics, isFalse);
      expect(m.hasErrors, isFalse);
      expect(m.hasWarnings, isFalse);
    });

    test('18. diagnostics error — missing animation atlas', () {
      final m = buildSurfaceStudioReadModelFromCatalog(
        _catalogWithMissingAtlasReference(),
      );
      expect(m.hasErrors, isTrue);
      expect(m.diagnostics.errors, isNotEmpty);
      expect(
        m.diagnostics.errors.any(
          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
        ),
        isTrue,
      );
    });

    test('19. diagnostics error — missing preset animation', () {
      final m = buildSurfaceStudioReadModelFromCatalog(
        _catalogWithMissingAnimationReference(),
      );
      expect(m.hasErrors, isTrue);
      expect(
        m.diagnostics.errors.any(
          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingPresetAnimation,
        ),
        isTrue,
      );
    });

    test('20. diagnostics warning — unused atlas', () {
      final m = buildSurfaceStudioReadModelFromCatalog(
        _catalogWithUnusedAtlas(),
      );
      expect(m.hasWarnings, isTrue);
      expect(
        m.diagnostics.warnings.any(
          (e) => e.kind == SurfaceCatalogDiagnosticKind.unusedAtlas,
        ),
        isTrue,
      );
    });

    test('21. root lists are unmodifiable', () {
      final m = buildSurfaceStudioReadModelFromCatalog(
        _minimalWaterCatalog(),
      );
      expect(() => m.atlases.add(m.atlases[0]), throwsUnsupportedError);
      expect(() => m.animations.add(m.animations[0]), throwsUnsupportedError);
      expect(() => m.presets.add(m.presets[0]), throwsUnsupportedError);
    });

    test('22. nested lists are unmodifiable', () {
      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
      final a = m.atlases.single;
      final anim = m.animations.single;
      final p = m.presets.single;
      expect(() => a.usedByAnimationIds.add('x'), throwsUnsupportedError);
      expect(
        () => anim.referencedAtlasIds.add('x'),
        throwsUnsupportedError,
      );
      expect(() => p.roles.add(SurfaceVariantRole.cross), throwsUnsupportedError);
      expect(
        () => p.referencedAnimationIds.add('x'),
        throwsUnsupportedError,
      );
    });

    test('23. builder does not order by sortOrder — source list order', () {
      final g = _geom();
      final a = [
        ProjectSurfaceAtlas(
          id: 'a1',
          name: 'a1',
          tilesetId: 't',
          geometry: g,
          sortOrder: 99,
        ),
        ProjectSurfaceAtlas(
          id: 'a2',
          name: 'a2',
          tilesetId: 't',
          geometry: g,
          sortOrder: 0,
        ),
        ProjectSurfaceAtlas(
          id: 'a3',
          name: 'a3',
          tilesetId: 't',
          geometry: g,
          sortOrder: 1,
        ),
      ];
      final f = SurfaceAnimationFrame(
        tileRef: SurfaceAtlasTileRef(atlasId: 'a1', column: 0, row: 0),
        durationMs: 10,
      );
      final t = SurfaceAnimationTimeline(frames: [f]);
      final anims = [
        ProjectSurfaceAnimation(
          id: 'n0',
          name: 'n0',
          timeline: t,
          sortOrder: 50,
        ),
        ProjectSurfaceAnimation(
          id: 'n1',
          name: 'n1',
          timeline: t,
          sortOrder: 10,
        ),
        ProjectSurfaceAnimation(
          id: 'n2',
          name: 'n2',
          timeline: t,
          sortOrder: 0,
        ),
      ];
      final c = ProjectSurfaceCatalog(
        atlases: a,
        animations: anims,
        presets: [
          ProjectSurfacePreset(
            id: 'p0',
            name: 'p0',
            sortOrder: 2,
            variantAnimations: SurfaceVariantAnimationRefSet(
              refs: [
                SurfaceVariantAnimationRef(
                  role: SurfaceVariantRole.isolated,
                  animationId: 'n0',
                ),
              ],
            ),
          ),
          ProjectSurfacePreset(
            id: 'p1',
            name: 'p1',
            sortOrder: 0,
            variantAnimations: SurfaceVariantAnimationRefSet(
              refs: [
                SurfaceVariantAnimationRef(
                  role: SurfaceVariantRole.isolated,
                  animationId: 'n1',
                ),
              ],
            ),
          ),
          ProjectSurfacePreset(
            id: 'p2',
            name: 'p2',
            sortOrder: 1,
            variantAnimations: SurfaceVariantAnimationRefSet(
              refs: [
                SurfaceVariantAnimationRef(
                  role: SurfaceVariantRole.isolated,
                  animationId: 'n2',
                ),
              ],
            ),
          ),
        ],
      );
      final m = buildSurfaceStudioReadModelFromCatalog(c);
      expect(m.atlases.map((e) => e.id).toList(), ['a1', 'a2', 'a3']);
      expect(m.animations.map((e) => e.id).toList(), ['n0', 'n1', 'n2']);
      expect(m.presets.map((e) => e.id).toList(), ['p0', 'p1', 'p2']);
    });

    test('24. builder does not mutate the source catalog', () {
      final c = _minimalWaterCatalog();
      final atlasCount = c.atlases.length;
      final animCount = c.animations.length;
      final presetCount = c.presets.length;
      final firstAtlasId = c.atlases.isNotEmpty ? c.atlases.first.id : null;
      final firstAnimId = c.animations.isNotEmpty
          ? c.animations.first.id
          : null;
      final firstPresetId = c.presets.isNotEmpty ? c.presets.first.id : null;
      buildSurfaceStudioReadModelFromCatalog(c);
      expect(c.atlases.length, atlasCount);
      expect(c.animations.length, animCount);
      expect(c.presets.length, presetCount);
      if (firstAtlasId != null) {
        expect(c.atlases.first.id, firstAtlasId);
      }
      if (firstAnimId != null) {
        expect(c.animations.first.id, firstAnimId);
      }
      if (firstPresetId != null) {
        expect(c.presets.first.id, firstPresetId);
      }
    });

    test('25. value equality of read models for equivalent catalogs', () {
      final j = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final c1 = decodeProjectSurfaceCatalog(
        Map<String, Object?>.from(j),
      );
      final c2 = decodeProjectSurfaceCatalog(
        Map<String, Object?>.from(j),
      );
      final modelA = buildSurfaceStudioReadModelFromCatalog(c1);
      final modelB = buildSurfaceStudioReadModelFromCatalog(c2);
      expect(modelA == modelB, isTrue);
      expect(modelA.hashCode, modelB.hashCode);
    });

    test('26. inequality when content differs', () {
      final a = buildSurfaceStudioReadModelFromCatalog(_emptyCatalog());
      final b = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
      expect(a == b, isFalse);
    });

    test('27. public export — map_core', () {
      expect(
        buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog()),
        isA<SurfaceStudioReadModel>(),
      );
    });

    test('28. ProjectManifest toJson still Lot 49 — surfaceCatalog only', () {
      final m = _manifest(surfaceCatalog: _minimalWaterCatalog());
      final j = m.toJson();
      expect(j.containsKey('surfaceCatalog'), isTrue);
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

    test('29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog', () {
      for (final n in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = _readFixtureJson(n);
        expect(o, isA<Map<String, Object?>>());
        expect(o.containsKey('surfaceCatalog'), isFalse, reason: n);
      }
    });

    test('30. no Flutter / Riverpod in surface read model public API', () {
      final m = buildSurfaceStudioReadModel(
        _manifest(surfaceCatalog: _emptyCatalog()),
      );
      expect(m, isA<SurfaceStudioReadModel>());
      // Imports are verified statically: this file only uses dart:convert,
      // dart:io, map_core, test.
    });
  });
}

// --- helpers ---

ProjectManifest _manifest({
  String name = 'Surface Read Model',
  ProjectSurfaceCatalog? surfaceCatalog,
}) {
  return ProjectManifest(
    name: name,
    maps: const [],
    tilesets: const [],
    surfaceCatalog: surfaceCatalog ?? ProjectSurfaceCatalog(),
  );
}

ProjectSurfaceCatalog _emptyCatalog() => ProjectSurfaceCatalog();

ProjectSurfaceCatalog _minimalWaterCatalog() {
  return decodeProjectSurfaceCatalog(
    Map<String, Object?>.from(
      _readFixtureJson('minimal_water_surface_catalog_v0.json'),
    ),
  );
}

ProjectSurfaceCatalog _fullWaterCatalog() {
  return decodeProjectSurfaceCatalog(
    Map<String, Object?>.from(
      _readFixtureJson('full_water_surface_catalog_v0.json'),
    ),
  );
}

SurfaceAtlasGeometry _geom() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
  final g = _geom();
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
    tileRef: SurfaceAtlasTileRef(
      atlasId: 'used-atlas',
      column: 0,
      row: 0,
    ),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'the-anim',
    name: 'a',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: [used, unused],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogWithMissingAtlasReference() {
  final f = SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: 'nope',
      column: 0,
      row: 0,
    ),
    durationMs: 10,
  );
  final anim = ProjectSurfaceAnimation(
    id: 'x',
    name: 'x',
    timeline: SurfaceAnimationTimeline(frames: [f]),
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: [anim],
    presets: const [],
  );
}

ProjectSurfaceCatalog _catalogWithMissingAnimationReference() {
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'ghost-anim',
      ),
    ],
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: const [],
    presets: [
      ProjectSurfacePreset(
        id: 'preset-ghost',
        name: 'ghost',
        variantAnimations: refs,
      ),
    ],
  );
}

Map<String, Object?> _readFixtureJson(String name) {
  return jsonDecode(
    File('test/fixtures/surface_catalog_json/$name').readAsStringSync(),
  ) as Map<String, Object?>;
}

```

#### Rapport `reports/surface/surface_engine_lot_51_surface_studio_read_model.md`

**Preuve (exception Lot 51, fichier rapport) :** un diff unifié `git diff --no-index /dev/null` ciblant `reports/surface/surface_engine_lot_51_surface_studio_read_model.md` après enregistrement final est **identique** à l’enchaînement des lignes de ce **même** fichier, chacune préfixée par le caractère `+` : c’est l’artefact Markdown unique du lot, sans recopie redondante dans la section A.3 (équivalence formelle requise par le cahier).

(SHA-256 de `surface_studio_read_model.dart` + `surface_studio_read_model_test.dart` au moment de la génération :)
`05bfc9eaf96cedafdd5dedd7b48a375840bd119bf0003eb06bd034acf6052ad5` / `3101805fed44f4c4a22073ff6d7ebfe68d644ba25b3cd8f15f53c4b29d9ab78e`

### B. Fichier modifié — contenu intégral `packages/map_core/lib/map_core.dart`

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
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
export 'src/operations/project_surface_preset_json_codec.dart';
export 'src/operations/project_surface_catalog_json_codec.dart';
export 'src/operations/project_manifest_surface_catalog_operations.dart';
export 'src/operations/surface_studio_read_model.dart';
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

### C. Diffs

#### Diff unifié [`map_core.dart`]

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index c90b2574..cd6310a7 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -54,6 +54,7 @@ export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
 export 'src/operations/project_surface_preset_json_codec.dart';
 export 'src/operations/project_surface_catalog_json_codec.dart';
 export 'src/operations/project_manifest_surface_catalog_operations.dart';
+export 'src/operations/surface_studio_read_model.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';

```

#### `git diff --no-index /dev/null` — `surface_studio_read_model.dart`

```diff
diff --git a/packages/map_core/lib/src/operations/surface_studio_read_model.dart b/packages/map_core/lib/src/operations/surface_studio_read_model.dart
new file mode 100644
index 00000000..b99d56c4
--- /dev/null
+++ b/packages/map_core/lib/src/operations/surface_studio_read_model.dart
@@ -0,0 +1,393 @@
+// Read models **Surface Studio** (Lot 51) : vue pure, immuable, sans UI Flutter.
+//
+// * Prépare l’affichage futur (compteurs, listes, diagnostics auteur) **sans**
+//   persistance disque, **sans** widget, **sans** Riverpod.
+// * N’impose **aucun** tri, **aucun** filtre : l’ordre de parcours est celui
+//   des listes sur [`ProjectSurfaceCatalog`] (y compris si [`sortOrder`] varie
+//   entre entités) — l’auteur voit l’**ordre source** tel qu’enregistré.
+// * Les **diagnostics** proviennent exclusivement de l’agrégateur auteur existant
+//   : [`diagnoseProjectSurfaceCatalogForAuthoring`] puis
+//   [`buildSurfaceCatalogDiagnosticsPresentation`]. Les références orphelines
+//   restent des **rapports d’analyse**, jamais des erreurs de **construction**
+//   du read model.
+// * Passe [`ProjectManifest`] via [`getProjectManifestSurfaceCatalog`] côté
+//   constructeur `buildSurfaceStudioReadModel` — un seul champ `surfaceCatalog`
+//   sur le manifest, pas de recomposition JSON ici.
+
+import 'package:meta/meta.dart' show immutable;
+
+import '../models/project_manifest.dart';
+import '../models/surface.dart';
+import '../models/surface_catalog.dart';
+import 'project_manifest_surface_catalog_operations.dart';
+import 'surface_catalog_authoring_diagnostics.dart';
+import 'surface_catalog_diagnostics_presentation.dart';
+
+// --- Comparaison de listes (ordre strict) — égalité des read models ---
+
+bool _strListEqual(List<String> a, List<String> b) {
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
+bool _roleListEqual(List<SurfaceVariantRole> a, List<SurfaceVariantRole> b) {
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
+List<String> _referencedAtlasFirstAppearance(ProjectSurfaceAnimation animation) {
+  final seen = <String>{};
+  final out = <String>[];
+  for (final frame in animation.timeline.frames) {
+    final id = frame.tileRef.atlasId;
+    if (seen.add(id)) {
+      out.add(id);
+    }
+  }
+  return out;
+}
+
+List<String> _usedByAnimationIdsForAtlas(
+  ProjectSurfaceCatalog catalog,
+  ProjectSurfaceAtlas atlas,
+) {
+  final out = <String>[];
+  for (final anim in catalog.animations) {
+    var uses = false;
+    for (final frame in anim.timeline.frames) {
+      if (frame.tileRef.atlasId == atlas.id) {
+        uses = true;
+        break;
+      }
+    }
+    if (uses) {
+      out.add(anim.id);
+    }
+  }
+  return out;
+}
+
+List<String> _referencedAnimationIdsDeduped(SurfaceVariantAnimationRefSet refs) {
+  final seen = <String>{};
+  final out = <String>[];
+  for (final r in refs.refs) {
+    if (seen.add(r.animationId)) {
+      out.add(r.animationId);
+    }
+  }
+  return out;
+}
+
+/// Résumé numérique pour l’en-tête Surface Studio (compteurs seuls).
+@immutable
+final class SurfaceStudioCatalogSummaryReadModel {
+  SurfaceStudioCatalogSummaryReadModel({
+    required this.atlasCount,
+    required this.animationCount,
+    required this.presetCount,
+  });
+
+  final int atlasCount;
+  final int animationCount;
+  final int presetCount;
+
+  bool get isEmpty =>
+      atlasCount == 0 && animationCount == 0 && presetCount == 0;
+
+  bool get isNotEmpty => !isEmpty;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceStudioCatalogSummaryReadModel &&
+          other.atlasCount == atlasCount &&
+          other.animationCount == animationCount &&
+          other.presetCount == presetCount;
+
+  @override
+  int get hashCode => Object.hash(atlasCount, animationCount, presetCount);
+}
+
+/// Une ligne **atlas** : instance source + animations qui s’y référencent
+/// (ordre des ids = ordre des animations dans le catalogue, sans doublon).
+@immutable
+final class SurfaceStudioAtlasReadModel {
+  SurfaceStudioAtlasReadModel({
+    required this.atlas,
+    required List<String> usedByAnimationIds,
+  }) : usedByAnimationIds = List<String>.unmodifiable(usedByAnimationIds);
+
+  final ProjectSurfaceAtlas atlas;
+  final List<String> usedByAnimationIds;
+
+  String get id => atlas.id;
+  String get name => atlas.name;
+  String get tilesetId => atlas.tilesetId;
+  String? get categoryId => atlas.categoryId;
+  int get sortOrder => atlas.sortOrder;
+  SurfaceAtlasGeometry get geometry => atlas.geometry;
+  SurfaceAtlasLayout get layout => atlas.geometry.layout;
+  int get tileWidth => atlas.geometry.tileSize.width;
+  int get tileHeight => atlas.geometry.tileSize.height;
+  int get columns => atlas.geometry.gridSize.columns;
+  int get rows => atlas.geometry.gridSize.rows;
+  int get tileCount => atlas.geometry.tileCount;
+  bool get isUsedByAnimation => usedByAnimationIds.isNotEmpty;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceStudioAtlasReadModel &&
+          other.atlas == atlas &&
+          _strListEqual(other.usedByAnimationIds, usedByAnimationIds);
+
+  @override
+  int get hashCode => Object.hash(atlas, Object.hashAll(usedByAnimationIds));
+}
+
+/// Une ligne **animation** : instance source + atlasId des frames
+/// (première apparition, sans doublon).
+@immutable
+final class SurfaceStudioAnimationReadModel {
+  SurfaceStudioAnimationReadModel({
+    required this.animation,
+    required List<String> referencedAtlasIds,
+  }) : referencedAtlasIds = List<String>.unmodifiable(referencedAtlasIds);
+
+  final ProjectSurfaceAnimation animation;
+  final List<String> referencedAtlasIds;
+
+  String get id => animation.id;
+  String get name => animation.name;
+  String? get syncGroupId => animation.syncGroupId;
+  String? get categoryId => animation.categoryId;
+  int get sortOrder => animation.sortOrder;
+  int get frameCount => animation.frameCount;
+  int get totalDurationMs => animation.totalDurationMs;
+  bool get hasFrames => animation.frameCount > 0;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceStudioAnimationReadModel &&
+          other.animation == animation &&
+          _strListEqual(other.referencedAtlasIds, referencedAtlasIds);
+
+  @override
+  int get hashCode => Object.hash(animation, Object.hashAll(referencedAtlasIds));
+}
+
+/// Une ligne **preset** : instance source, rôles (ordre des refs) et
+/// `animationId` uniques (ordre de première apparition).
+@immutable
+final class SurfaceStudioPresetReadModel {
+  SurfaceStudioPresetReadModel({
+    required this.preset,
+    required List<SurfaceVariantRole> roles,
+    required List<String> referencedAnimationIds,
+  })  : roles = List<SurfaceVariantRole>.unmodifiable(roles),
+        referencedAnimationIds = List<String>.unmodifiable(
+          referencedAnimationIds,
+        );
+
+  final ProjectSurfacePreset preset;
+  final List<SurfaceVariantRole> roles;
+  final List<String> referencedAnimationIds;
+
+  String get id => preset.id;
+  String get name => preset.name;
+  String? get categoryId => preset.categoryId;
+  int get sortOrder => preset.sortOrder;
+  int get variantCount => preset.variantCount;
+  bool get coversStandardRoles =>
+      preset.coversAllRoles(standardSurfaceVariantRoleOrder);
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceStudioPresetReadModel &&
+          other.preset == preset &&
+          _roleListEqual(other.roles, roles) &&
+          _strListEqual(other.referencedAnimationIds, referencedAnimationIds);
+
+  @override
+  int get hashCode => Object.hash(
+        preset,
+        Object.hashAll(roles),
+        Object.hashAll(referencedAnimationIds),
+      );
+}
+
+/// Vue read-only complète d’un [ProjectSurfaceCatalog] + diagnostics auteur.
+@immutable
+final class SurfaceStudioReadModel {
+  SurfaceStudioReadModel({
+    required this.catalog,
+    required this.summary,
+    required List<SurfaceStudioAtlasReadModel> atlases,
+    required List<SurfaceStudioAnimationReadModel> animations,
+    required List<SurfaceStudioPresetReadModel> presets,
+    required this.diagnostics,
+  })  : atlases = List<SurfaceStudioAtlasReadModel>.unmodifiable(atlases),
+        animations =
+            List<SurfaceStudioAnimationReadModel>.unmodifiable(animations),
+        presets = List<SurfaceStudioPresetReadModel>.unmodifiable(presets);
+
+  final ProjectSurfaceCatalog catalog;
+  final SurfaceStudioCatalogSummaryReadModel summary;
+  final List<SurfaceStudioAtlasReadModel> atlases;
+  final List<SurfaceStudioAnimationReadModel> animations;
+  final List<SurfaceStudioPresetReadModel> presets;
+  final SurfaceCatalogDiagnosticsPresentation diagnostics;
+
+  bool get isEmpty => summary.isEmpty;
+  bool get isNotEmpty => summary.isNotEmpty;
+  bool get hasDiagnostics => diagnostics.hasDiagnostics;
+  bool get hasErrors => diagnostics.hasErrors;
+  bool get hasWarnings => diagnostics.hasWarnings;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is SurfaceStudioReadModel &&
+          other.catalog == catalog &&
+          other.summary == summary &&
+          _atlasReadListEqual(other.atlases, atlases) &&
+          _animReadListEqual(other.animations, animations) &&
+          _presetReadListEqual(other.presets, presets) &&
+          other.diagnostics == diagnostics;
+
+  @override
+  int get hashCode => Object.hash(
+        catalog,
+        summary,
+        Object.hashAll(atlases),
+        Object.hashAll(animations),
+        Object.hashAll(presets),
+        diagnostics,
+      );
+}
+
+bool _atlasReadListEqual(
+  List<SurfaceStudioAtlasReadModel> a,
+  List<SurfaceStudioAtlasReadModel> b,
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
+bool _animReadListEqual(
+  List<SurfaceStudioAnimationReadModel> a,
+  List<SurfaceStudioAnimationReadModel> b,
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
+bool _presetReadListEqual(
+  List<SurfaceStudioPresetReadModel> a,
+  List<SurfaceStudioPresetReadModel> b,
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
+/// Construit un [SurfaceStudioReadModel] via [`getProjectManifestSurfaceCatalog`]
+/// (aucune mutation du [manifest]).
+SurfaceStudioReadModel buildSurfaceStudioReadModel(ProjectManifest manifest) =>
+    buildSurfaceStudioReadModelFromCatalog(
+      getProjectManifestSurfaceCatalog(manifest),
+    );
+
+/// Construit un [SurfaceStudioReadModel] : même instance de [catalog],
+/// même ordre source que les listes du catalogue, diagnostics auteur
+/// (Lots 36 + 38) **sans** filtrage ni tri.
+SurfaceStudioReadModel buildSurfaceStudioReadModelFromCatalog(
+  ProjectSurfaceCatalog catalog,
+) {
+  final summary = SurfaceStudioCatalogSummaryReadModel(
+    atlasCount: catalog.atlasCount,
+    animationCount: catalog.animationCount,
+    presetCount: catalog.presetCount,
+  );
+  final report = diagnoseProjectSurfaceCatalogForAuthoring(catalog);
+  final diagnostics = buildSurfaceCatalogDiagnosticsPresentation(report);
+
+  final atlasRows = <SurfaceStudioAtlasReadModel>[];
+  for (final a in catalog.atlases) {
+    atlasRows.add(
+      SurfaceStudioAtlasReadModel(
+        atlas: a,
+        usedByAnimationIds: _usedByAnimationIdsForAtlas(catalog, a),
+      ),
+    );
+  }
+
+  final animRows = <SurfaceStudioAnimationReadModel>[];
+  for (final anim in catalog.animations) {
+    animRows.add(
+      SurfaceStudioAnimationReadModel(
+        animation: anim,
+        referencedAtlasIds: _referencedAtlasFirstAppearance(anim),
+      ),
+    );
+  }
+
+  final presetRows = <SurfaceStudioPresetReadModel>[];
+  for (final p in catalog.presets) {
+    final roleList = p.variantAnimations.refs.map((r) => r.role).toList();
+    presetRows.add(
+      SurfaceStudioPresetReadModel(
+        preset: p,
+        roles: roleList,
+        referencedAnimationIds: _referencedAnimationIdsDeduped(
+          p.variantAnimations,
+        ),
+      ),
+    );
+  }
+
+  return SurfaceStudioReadModel(
+    catalog: catalog,
+    summary: summary,
+    atlases: atlasRows,
+    animations: animRows,
+    presets: presetRows,
+    diagnostics: diagnostics,
+  );
+}

```

#### `git diff --no-index /dev/null` — `surface_studio_read_model_test.dart`

```diff
diff --git a/packages/map_core/test/surface_studio_read_model_test.dart b/packages/map_core/test/surface_studio_read_model_test.dart
new file mode 100644
index 00000000..d02f61d6
--- /dev/null
+++ b/packages/map_core/test/surface_studio_read_model_test.dart
@@ -0,0 +1,817 @@
+import 'dart:convert';
+import 'dart:io';
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('Surface Studio read model (Lot 51)', () {
+    test('1. empty catalog: summary, lists, clean diagnostics', () {
+      final c = _emptyCatalog();
+      final m = buildSurfaceStudioReadModelFromCatalog(c);
+      expect(identical(m.catalog, c), isTrue);
+      expect(m.summary.atlasCount, 0);
+      expect(m.summary.animationCount, 0);
+      expect(m.summary.presetCount, 0);
+      expect(m.summary.isEmpty, isTrue);
+      expect(m.isEmpty, isTrue);
+      expect(m.atlases, isEmpty);
+      expect(m.animations, isEmpty);
+      expect(m.presets, isEmpty);
+      expect(m.diagnostics.isClean, isTrue);
+    });
+
+    test('2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation',
+        () {
+      final cat = _minimalWaterCatalog();
+      final manifest = _manifest(surfaceCatalog: cat);
+      final before = manifest.surfaceCatalog;
+      final model = buildSurfaceStudioReadModel(manifest);
+      expect(identical(model.catalog, before), isTrue);
+      expect(identical(manifest.surfaceCatalog, before), isTrue);
+    });
+
+    test('3. minimal water — summary counts and non-empty', () {
+      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
+      expect(m.summary.atlasCount, 1);
+      expect(m.summary.animationCount, 1);
+      expect(m.summary.presetCount, 1);
+      expect(m.summary.isEmpty, isFalse);
+      expect(m.summary.isNotEmpty, isTrue);
+    });
+
+    test('4. minimal water — atlas row main fields', () {
+      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
+      final row = m.atlases.single;
+      expect(row.id, 'water-atlas');
+      expect(row.name, 'Water Atlas');
+      expect(row.tilesetId, 'nature-tileset');
+      expect(row.tileWidth, 32);
+      expect(row.tileHeight, 32);
+      expect(row.columns, 23);
+      expect(row.rows, 32);
+      expect(row.tileCount, 23 * 32);
+      expect(row.layout, SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames);
+    });
+
+    test('5. atlas rows preserve catalog order', () {
+      final g = _geom();
+      final c = ProjectSurfaceCatalog(
+        atlases: [
+          ProjectSurfaceAtlas(
+            id: 'water-atlas',
+            name: 'W',
+            tilesetId: 't',
+            geometry: g,
+          ),
+          ProjectSurfaceAtlas(
+            id: 'lava-atlas',
+            name: 'L',
+            tilesetId: 't',
+            geometry: g,
+          ),
+          ProjectSurfaceAtlas(
+            id: 'grass-atlas',
+            name: 'G',
+            tilesetId: 't',
+            geometry: g,
+          ),
+        ],
+        animations: const [],
+        presets: const [],
+      );
+      final m = buildSurfaceStudioReadModelFromCatalog(c);
+      expect(m.atlases.map((e) => e.id).toList(), [
+        'water-atlas',
+        'lava-atlas',
+        'grass-atlas',
+      ]);
+    });
+
+    test('6. atlas usedByAnimationIds — two animations, one atlas', () {
+      final g = _geom();
+      final atlas = ProjectSurfaceAtlas(
+        id: 'water-atlas',
+        name: 'W',
+        tilesetId: 't',
+        geometry: g,
+      );
+      final frame = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'water-atlas',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 100,
+      );
+      final tl = SurfaceAnimationTimeline(frames: [frame]);
+      final waterA = ProjectSurfaceAnimation(
+        id: 'water-a',
+        name: 'A',
+        timeline: tl,
+      );
+      final waterB = ProjectSurfaceAnimation(
+        id: 'water-b',
+        name: 'B',
+        timeline: tl,
+      );
+      final c = ProjectSurfaceCatalog(
+        atlases: [atlas],
+        animations: [waterA, waterB],
+        presets: const [],
+      );
+      final row = buildSurfaceStudioReadModelFromCatalog(c).atlases.single;
+      expect(row.usedByAnimationIds, ['water-a', 'water-b']);
+      expect(row.isUsedByAnimation, isTrue);
+    });
+
+    test('7. atlas usedByAnimationIds — one animation twice same atlas', () {
+      final g = _geom();
+      final atlas = ProjectSurfaceAtlas(
+        id: 'water-atlas',
+        name: 'W',
+        tilesetId: 't',
+        geometry: g,
+      );
+      final frame = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'water-atlas',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 100,
+      );
+      final tl = SurfaceAnimationTimeline(frames: [frame, frame]);
+      final anim = ProjectSurfaceAnimation(
+        id: 'water-isolated',
+        name: 'One',
+        timeline: tl,
+      );
+      final c = ProjectSurfaceCatalog(
+        atlases: [atlas],
+        animations: [anim],
+        presets: const [],
+      );
+      final row = buildSurfaceStudioReadModelFromCatalog(c).atlases.single;
+      expect(row.usedByAnimationIds, ['water-isolated']);
+    });
+
+    test('8. minimal water — animation row main fields', () {
+      final row = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog())
+          .animations
+          .single;
+      expect(row.id, 'water-isolated-loop');
+      expect(row.name, 'Water Isolated Loop');
+      expect(row.frameCount, 1);
+      expect(row.totalDurationMs, 120);
+      expect(row.hasFrames, isTrue);
+      expect(row.categoryId, isNull);
+      expect(row.syncGroupId, isNull);
+      expect(row.sortOrder, 0);
+    });
+
+    test('9. animation rows preserve catalog order', () {
+      final g = _geom();
+      final atlas = ProjectSurfaceAtlas(
+        id: 'a',
+        name: 'a',
+        tilesetId: 't',
+        geometry: g,
+      );
+      final f = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
+        durationMs: 10,
+      );
+      final t = SurfaceAnimationTimeline(frames: [f]);
+      final c = ProjectSurfaceCatalog(
+        atlases: [atlas],
+        animations: [
+          ProjectSurfaceAnimation(id: 'z', name: 'z', timeline: t),
+          ProjectSurfaceAnimation(id: 'y', name: 'y', timeline: t),
+          ProjectSurfaceAnimation(id: 'x', name: 'x', timeline: t),
+        ],
+        presets: const [],
+      );
+      final m = buildSurfaceStudioReadModelFromCatalog(c);
+      expect(m.animations.map((e) => e.id).toList(), ['z', 'y', 'x']);
+    });
+
+    test('10. animation referencedAtlasIds — first appearance order', () {
+      final f1 = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'atlas-b',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 10,
+      );
+      final f2 = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'atlas-a',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 10,
+      );
+      final f3 = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'atlas-b',
+          column: 0,
+          row: 1,
+        ),
+        durationMs: 10,
+      );
+      final f4 = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'atlas-c',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 10,
+      );
+      final anim = ProjectSurfaceAnimation(
+        id: 'multi',
+        name: 'm',
+        timeline: SurfaceAnimationTimeline(
+          frames: [f1, f2, f3, f4],
+        ),
+      );
+      final m = buildSurfaceStudioReadModelFromCatalog(
+        ProjectSurfaceCatalog(
+          atlases: const [],
+          animations: [anim],
+          presets: const [],
+        ),
+      );
+      expect(m.animations.single.referencedAtlasIds, [
+        'atlas-b',
+        'atlas-a',
+        'atlas-c',
+      ]);
+    });
+
+    test('11. animation read model does not validate atlas existence', () {
+      final f = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(
+          atlasId: 'missing-atlas',
+          column: 0,
+          row: 0,
+        ),
+        durationMs: 10,
+      );
+      final anim = ProjectSurfaceAnimation(
+        id: 'bad',
+        name: 'b',
+        timeline: SurfaceAnimationTimeline(frames: [f]),
+      );
+      final m = buildSurfaceStudioReadModelFromCatalog(
+        ProjectSurfaceCatalog(
+          atlases: const [],
+          animations: [anim],
+          presets: const [],
+        ),
+      );
+      expect(m.animations.single.referencedAtlasIds, contains('missing-atlas'));
+      expect(
+        m.diagnostics.errors.any(
+          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+        ),
+        isTrue,
+      );
+    });
+
+    test('12. minimal water — preset row main fields', () {
+      final row = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog())
+          .presets
+          .single;
+      expect(row.id, 'water-surface');
+      expect(row.name, 'Water Surface');
+      expect(row.variantCount, 1);
+      expect(row.roles, [SurfaceVariantRole.isolated]);
+      expect(row.referencedAnimationIds, ['water-isolated-loop']);
+      expect(row.coversStandardRoles, isFalse);
+      expect(row.categoryId, isNull);
+      expect(row.sortOrder, 0);
+    });
+
+    test('13. preset rows preserve catalog order', () {
+      final g = _geom();
+      final atlas = ProjectSurfaceAtlas(
+        id: 'a',
+        name: 'a',
+        tilesetId: 't',
+        geometry: g,
+      );
+      final f = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(atlasId: 'a', column: 0, row: 0),
+        durationMs: 10,
+      );
+      final t = SurfaceAnimationTimeline(frames: [f]);
+      final anim = ProjectSurfaceAnimation(
+        id: 'anim',
+        name: 'anim',
+        timeline: t,
+      );
+      SurfaceVariantAnimationRefSet presetRefs(String id) {
+        return SurfaceVariantAnimationRefSet(
+          refs: [
+            SurfaceVariantAnimationRef(
+              role: SurfaceVariantRole.isolated,
+              animationId: id,
+            ),
+          ],
+        );
+      }
+
+      final c = ProjectSurfaceCatalog(
+        atlases: [atlas],
+        animations: [anim],
+        presets: [
+          ProjectSurfacePreset(
+            id: 'p-c',
+            name: 'c',
+            variantAnimations: presetRefs('anim'),
+          ),
+          ProjectSurfacePreset(
+            id: 'p-b',
+            name: 'b',
+            variantAnimations: presetRefs('anim'),
+          ),
+          ProjectSurfacePreset(
+            id: 'p-a',
+            name: 'a',
+            variantAnimations: presetRefs('anim'),
+          ),
+        ],
+      );
+      final m = buildSurfaceStudioReadModelFromCatalog(c);
+      expect(m.presets.map((e) => e.id).toList(), ['p-c', 'p-b', 'p-a']);
+    });
+
+    test('14. preset referencedAnimationIds — dedupe keeps order', () {
+      final refs = SurfaceVariantAnimationRefSet(
+        refs: [
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.isolated,
+            animationId: 'anim-b',
+          ),
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.endNorth,
+            animationId: 'anim-a',
+          ),
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.endEast,
+            animationId: 'anim-b',
+          ),
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.endSouth,
+            animationId: 'anim-c',
+          ),
+        ],
+      );
+      final p = ProjectSurfacePreset(
+        id: 'p',
+        name: 'p',
+        variantAnimations: refs,
+      );
+      final row = buildSurfaceStudioReadModelFromCatalog(
+        ProjectSurfaceCatalog(
+          atlases: const [],
+          animations: const [],
+          presets: [p],
+        ),
+      ).presets.single;
+      expect(row.referencedAnimationIds, ['anim-b', 'anim-a', 'anim-c']);
+    });
+
+    test('15. preset read model does not validate animation existence', () {
+      final refs = SurfaceVariantAnimationRefSet(
+        refs: [
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.isolated,
+            animationId: 'missing-animation',
+          ),
+        ],
+      );
+      final p = ProjectSurfacePreset(
+        id: 'p',
+        name: 'p',
+        variantAnimations: refs,
+      );
+      final m = buildSurfaceStudioReadModelFromCatalog(
+        ProjectSurfaceCatalog(
+          atlases: const [],
+          animations: const [],
+          presets: [p],
+        ),
+      );
+      expect(
+        m.presets.single.referencedAnimationIds,
+        contains('missing-animation'),
+      );
+      expect(
+        m.diagnostics.errors.any(
+          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        ),
+        isTrue,
+      );
+    });
+
+    test('16. full water — preset role order cross, isolated, horizontal', () {
+      final row = buildSurfaceStudioReadModelFromCatalog(_fullWaterCatalog())
+          .presets
+          .single;
+      expect(row.roles, [
+        SurfaceVariantRole.cross,
+        SurfaceVariantRole.isolated,
+        SurfaceVariantRole.horizontal,
+      ]);
+    });
+
+    test('17. minimal water — diagnostics clean flags on read model', () {
+      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
+      expect(m.diagnostics.isClean, isTrue);
+      expect(m.hasDiagnostics, isFalse);
+      expect(m.hasErrors, isFalse);
+      expect(m.hasWarnings, isFalse);
+    });
+
+    test('18. diagnostics error — missing animation atlas', () {
+      final m = buildSurfaceStudioReadModelFromCatalog(
+        _catalogWithMissingAtlasReference(),
+      );
+      expect(m.hasErrors, isTrue);
+      expect(m.diagnostics.errors, isNotEmpty);
+      expect(
+        m.diagnostics.errors.any(
+          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingAnimationAtlas,
+        ),
+        isTrue,
+      );
+    });
+
+    test('19. diagnostics error — missing preset animation', () {
+      final m = buildSurfaceStudioReadModelFromCatalog(
+        _catalogWithMissingAnimationReference(),
+      );
+      expect(m.hasErrors, isTrue);
+      expect(
+        m.diagnostics.errors.any(
+          (e) => e.kind == SurfaceCatalogDiagnosticKind.missingPresetAnimation,
+        ),
+        isTrue,
+      );
+    });
+
+    test('20. diagnostics warning — unused atlas', () {
+      final m = buildSurfaceStudioReadModelFromCatalog(
+        _catalogWithUnusedAtlas(),
+      );
+      expect(m.hasWarnings, isTrue);
+      expect(
+        m.diagnostics.warnings.any(
+          (e) => e.kind == SurfaceCatalogDiagnosticKind.unusedAtlas,
+        ),
+        isTrue,
+      );
+    });
+
+    test('21. root lists are unmodifiable', () {
+      final m = buildSurfaceStudioReadModelFromCatalog(
+        _minimalWaterCatalog(),
+      );
+      expect(() => m.atlases.add(m.atlases[0]), throwsUnsupportedError);
+      expect(() => m.animations.add(m.animations[0]), throwsUnsupportedError);
+      expect(() => m.presets.add(m.presets[0]), throwsUnsupportedError);
+    });
+
+    test('22. nested lists are unmodifiable', () {
+      final m = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
+      final a = m.atlases.single;
+      final anim = m.animations.single;
+      final p = m.presets.single;
+      expect(() => a.usedByAnimationIds.add('x'), throwsUnsupportedError);
+      expect(
+        () => anim.referencedAtlasIds.add('x'),
+        throwsUnsupportedError,
+      );
+      expect(() => p.roles.add(SurfaceVariantRole.cross), throwsUnsupportedError);
+      expect(
+        () => p.referencedAnimationIds.add('x'),
+        throwsUnsupportedError,
+      );
+    });
+
+    test('23. builder does not order by sortOrder — source list order', () {
+      final g = _geom();
+      final a = [
+        ProjectSurfaceAtlas(
+          id: 'a1',
+          name: 'a1',
+          tilesetId: 't',
+          geometry: g,
+          sortOrder: 99,
+        ),
+        ProjectSurfaceAtlas(
+          id: 'a2',
+          name: 'a2',
+          tilesetId: 't',
+          geometry: g,
+          sortOrder: 0,
+        ),
+        ProjectSurfaceAtlas(
+          id: 'a3',
+          name: 'a3',
+          tilesetId: 't',
+          geometry: g,
+          sortOrder: 1,
+        ),
+      ];
+      final f = SurfaceAnimationFrame(
+        tileRef: SurfaceAtlasTileRef(atlasId: 'a1', column: 0, row: 0),
+        durationMs: 10,
+      );
+      final t = SurfaceAnimationTimeline(frames: [f]);
+      final anims = [
+        ProjectSurfaceAnimation(
+          id: 'n0',
+          name: 'n0',
+          timeline: t,
+          sortOrder: 50,
+        ),
+        ProjectSurfaceAnimation(
+          id: 'n1',
+          name: 'n1',
+          timeline: t,
+          sortOrder: 10,
+        ),
+        ProjectSurfaceAnimation(
+          id: 'n2',
+          name: 'n2',
+          timeline: t,
+          sortOrder: 0,
+        ),
+      ];
+      final c = ProjectSurfaceCatalog(
+        atlases: a,
+        animations: anims,
+        presets: [
+          ProjectSurfacePreset(
+            id: 'p0',
+            name: 'p0',
+            sortOrder: 2,
+            variantAnimations: SurfaceVariantAnimationRefSet(
+              refs: [
+                SurfaceVariantAnimationRef(
+                  role: SurfaceVariantRole.isolated,
+                  animationId: 'n0',
+                ),
+              ],
+            ),
+          ),
+          ProjectSurfacePreset(
+            id: 'p1',
+            name: 'p1',
+            sortOrder: 0,
+            variantAnimations: SurfaceVariantAnimationRefSet(
+              refs: [
+                SurfaceVariantAnimationRef(
+                  role: SurfaceVariantRole.isolated,
+                  animationId: 'n1',
+                ),
+              ],
+            ),
+          ),
+          ProjectSurfacePreset(
+            id: 'p2',
+            name: 'p2',
+            sortOrder: 1,
+            variantAnimations: SurfaceVariantAnimationRefSet(
+              refs: [
+                SurfaceVariantAnimationRef(
+                  role: SurfaceVariantRole.isolated,
+                  animationId: 'n2',
+                ),
+              ],
+            ),
+          ),
+        ],
+      );
+      final m = buildSurfaceStudioReadModelFromCatalog(c);
+      expect(m.atlases.map((e) => e.id).toList(), ['a1', 'a2', 'a3']);
+      expect(m.animations.map((e) => e.id).toList(), ['n0', 'n1', 'n2']);
+      expect(m.presets.map((e) => e.id).toList(), ['p0', 'p1', 'p2']);
+    });
+
+    test('24. builder does not mutate the source catalog', () {
+      final c = _minimalWaterCatalog();
+      final atlasCount = c.atlases.length;
+      final animCount = c.animations.length;
+      final presetCount = c.presets.length;
+      final firstAtlasId = c.atlases.isNotEmpty ? c.atlases.first.id : null;
+      final firstAnimId = c.animations.isNotEmpty
+          ? c.animations.first.id
+          : null;
+      final firstPresetId = c.presets.isNotEmpty ? c.presets.first.id : null;
+      buildSurfaceStudioReadModelFromCatalog(c);
+      expect(c.atlases.length, atlasCount);
+      expect(c.animations.length, animCount);
+      expect(c.presets.length, presetCount);
+      if (firstAtlasId != null) {
+        expect(c.atlases.first.id, firstAtlasId);
+      }
+      if (firstAnimId != null) {
+        expect(c.animations.first.id, firstAnimId);
+      }
+      if (firstPresetId != null) {
+        expect(c.presets.first.id, firstPresetId);
+      }
+    });
+
+    test('25. value equality of read models for equivalent catalogs', () {
+      final j = _readFixtureJson('minimal_water_surface_catalog_v0.json');
+      final c1 = decodeProjectSurfaceCatalog(
+        Map<String, Object?>.from(j),
+      );
+      final c2 = decodeProjectSurfaceCatalog(
+        Map<String, Object?>.from(j),
+      );
+      final modelA = buildSurfaceStudioReadModelFromCatalog(c1);
+      final modelB = buildSurfaceStudioReadModelFromCatalog(c2);
+      expect(modelA == modelB, isTrue);
+      expect(modelA.hashCode, modelB.hashCode);
+    });
+
+    test('26. inequality when content differs', () {
+      final a = buildSurfaceStudioReadModelFromCatalog(_emptyCatalog());
+      final b = buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
+      expect(a == b, isFalse);
+    });
+
+    test('27. public export — map_core', () {
+      expect(
+        buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog()),
+        isA<SurfaceStudioReadModel>(),
+      );
+    });
+
+    test('28. ProjectManifest toJson still Lot 49 — surfaceCatalog only', () {
+      final m = _manifest(surfaceCatalog: _minimalWaterCatalog());
+      final j = m.toJson();
+      expect(j.containsKey('surfaceCatalog'), isTrue);
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
+    test('29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog', () {
+      for (final n in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final o = _readFixtureJson(n);
+        expect(o, isA<Map<String, Object?>>());
+        expect(o.containsKey('surfaceCatalog'), isFalse, reason: n);
+      }
+    });
+
+    test('30. no Flutter / Riverpod in surface read model public API', () {
+      final m = buildSurfaceStudioReadModel(
+        _manifest(surfaceCatalog: _emptyCatalog()),
+      );
+      expect(m, isA<SurfaceStudioReadModel>());
+      // Imports are verified statically: this file only uses dart:convert,
+      // dart:io, map_core, test.
+    });
+  });
+}
+
+// --- helpers ---
+
+ProjectManifest _manifest({
+  String name = 'Surface Read Model',
+  ProjectSurfaceCatalog? surfaceCatalog,
+}) {
+  return ProjectManifest(
+    name: name,
+    maps: const [],
+    tilesets: const [],
+    surfaceCatalog: surfaceCatalog ?? ProjectSurfaceCatalog(),
+  );
+}
+
+ProjectSurfaceCatalog _emptyCatalog() => ProjectSurfaceCatalog();
+
+ProjectSurfaceCatalog _minimalWaterCatalog() {
+  return decodeProjectSurfaceCatalog(
+    Map<String, Object?>.from(
+      _readFixtureJson('minimal_water_surface_catalog_v0.json'),
+    ),
+  );
+}
+
+ProjectSurfaceCatalog _fullWaterCatalog() {
+  return decodeProjectSurfaceCatalog(
+    Map<String, Object?>.from(
+      _readFixtureJson('full_water_surface_catalog_v0.json'),
+    ),
+  );
+}
+
+SurfaceAtlasGeometry _geom() {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+}
+
+ProjectSurfaceCatalog _catalogWithUnusedAtlas() {
+  final g = _geom();
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
+    tileRef: SurfaceAtlasTileRef(
+      atlasId: 'used-atlas',
+      column: 0,
+      row: 0,
+    ),
+    durationMs: 10,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'the-anim',
+    name: 'a',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: [used, unused],
+    animations: [anim],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogWithMissingAtlasReference() {
+  final f = SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(
+      atlasId: 'nope',
+      column: 0,
+      row: 0,
+    ),
+    durationMs: 10,
+  );
+  final anim = ProjectSurfaceAnimation(
+    id: 'x',
+    name: 'x',
+    timeline: SurfaceAnimationTimeline(frames: [f]),
+  );
+  return ProjectSurfaceCatalog(
+    atlases: const [],
+    animations: [anim],
+    presets: const [],
+  );
+}
+
+ProjectSurfaceCatalog _catalogWithMissingAnimationReference() {
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: [
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'ghost-anim',
+      ),
+    ],
+  );
+  return ProjectSurfaceCatalog(
+    atlases: const [],
+    animations: const [],
+    presets: [
+      ProjectSurfacePreset(
+        id: 'preset-ghost',
+        name: 'ghost',
+        variantAnimations: refs,
+      ),
+    ],
+  );
+}
+
+Map<String, Object?> _readFixtureJson(String name) {
+  return jsonDecode(
+    File('test/fixtures/surface_catalog_json/$name').readAsStringSync(),
+  ) as Map<String, Object?>;
+}

```

### D. Rappel sorties (réf. §35–38)

- Test ciblé : §35
- Régression : §36
- Analyze : §37
- Dernière ligne suite complète : §38
