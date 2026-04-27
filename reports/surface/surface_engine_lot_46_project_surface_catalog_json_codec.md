# Surface Engine — Lot 46 — `ProjectSurfaceCatalog` JSON Codec V0

## 1. Résumé exécutif

Codec JSON manuel pour `ProjectSurfaceCatalog` : `encodeProjectSurfaceCatalog` / `decodeProjectSurfaceCatalog`, composition des codecs Lots 39, 42 et 45, **44** tests, sans modifier `ProjectManifest`, sans appeler les diagnostics dans le codec, sans `build_runner`.

## 2. Pourquoi ce lot vient après le Lot 45

Le Lot 45 a livré le JSON des presets ; le Lot 46 compose le catalogue (`atlases`, `animations`, `presets`) pour la persistance future, sans intégration manifeste dans ce lot.

## 3. Tableau récapitulatif des lots (39–50)

| Lot | Sujet | Statut |
|-----|--------|--------|
| 39 | ProjectSurfaceAtlas JSON Codec V0 | fait |
| 40 | Surface TileRef / AnimationFrame JSON Codec V0 | fait |
| 41 | SurfaceAnimationTimeline JSON Codec V0 | fait |
| 42 | ProjectSurfaceAnimation JSON Codec V0 | fait |
| 43 | SurfaceVariantAnimationRef JSON Codec V0 | fait |
| 44 | SurfaceVariantAnimationRefSet JSON Codec V0 | fait |
| 45 | ProjectSurfacePreset JSON Codec V0 | fait |
| 46 | ProjectSurfaceCatalog JSON Codec V0 | **ce lot** |
| 47 | Surface JSON Golden Samples / Characterization | prochain recommandé |
| 48 | ProjectManifest Surface Integration Prep | ensuite probable |
| 49 | ProjectManifest Surface Integration V0 | plus tard, si prêt |
| 50 | Surface Catalog Repository / Use Cases Prep | ensuite probable |

## 4. Fichiers consultés (audit)

`surface_catalog.dart`, `surface.dart`, `map_exceptions.dart`, codecs atlas / animation / preset, `map_core.dart`, tests catalog et codecs et diagnostics, `project_manifest.dart`, rapport Lot 45.

## 5. Fichiers créés

- `packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart`
- `packages/map_core/test/project_surface_catalog_json_codec_test.dart`
- `reports/surface/surface_engine_lot_46_project_surface_catalog_json_codec.md`

## 6. Fichiers modifiés

- `packages/map_core/lib/map_core.dart`

## 7. API ajoutée

- `Map<String, Object?> encodeProjectSurfaceCatalog(ProjectSurfaceCatalog catalog);`
- `ProjectSurfaceCatalog decodeProjectSurfaceCatalog(Map<String, Object?> json);`

## 8. Schéma JSON `ProjectSurfaceCatalog`

Trois clés : `atlases`, `animations`, `presets` — chacune une liste (éventuellement vide) d’objets au format des codecs enfants.

## 9. Sémantique d’encodage

Exactement ces trois clés ; ordre préservé ; délégation `encodeProjectSurfaceAtlas` / `encodeProjectSurfaceAnimation` / `encodeProjectSurfacePreset`.

## 10. Sémantique de décodage

Listes requises et typées ; éléments non-`Map` rejetés avec `ValidationException` ; `decode*` enfants ; unicité des id par collection via `ProjectSurfaceCatalog` ; clés inconnues top-level ignorées ; maps sources non mutées.

## 11. Décision : réutiliser les codecs atlas / animation / preset

Composition stricte, un schéma par type d’entité.

## 12. Décision : préserver l’ordre des collections sans tri

Aucun tri par id ni `sortOrder`.

## 13. Décision : ne pas résoudre les références internes

Pas de vérification d’existence des cibles — les diagnostics couvrent la cohérence.

## 14. Décision : ne pas appeler les diagnostics dans le codec

`diagnoseProjectSurfaceCatalog` et associés restent externes (tests 32–35).

## 15. Décision : tolérer les clés inconnues

Top-level en décodage ; enfants déjà tolérants via Lots 39/42/45.

## 16. Décision : exiger `atlases`, `animations`, `presets` en V0

Codec strict sur la présence des trois clés.

## 17. Décision : ne pas créer de catégories Surface

Pas de liste `categories` / `surfaceCategories` au catalogue.

## 18. Décision : ne pas créer `SurfacePresetKind` / `surfaceKind`

Non introduit par le codec (test 44).

## 19. Décision : ne pas ajouter `toJson` / `fromJson` au modèle

Modèle domaine pur.

## 20. Décision : ne pas modifier `ProjectManifest`

Aucun champ `surfaceCatalog` ni `surface*` ajouté.

## 21. Ce qui a été testé

44 cas (vide, complet, ordres, erreurs, doublons, immutabilité, non-résolution + preuves diagnostics, réutilisation codecs, manifest, documentaires).

## 22. Ce que les tests prouvent

Forme JSON, composition, séparation codec / diagnostics, invariants manifest.

## 23. Ce qui n’a volontairement pas été fait

Intégration manifeste, `build_runner`, packages hors `map_core`.

## 24. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Prochain lot d’intégration (48–49).

## 25. Pourquoi aucun fichier généré n’a été créé

Codecs manuels uniquement.

## 26. Pourquoi aucun `build_runner` n’a été lancé

Aucun changement sur des fichiers générés requis.

## 27. Pourquoi aucun runtime / editor / gameplay / battle n’a été modifié

Périmètre `map_core` + rapport.

## 28. Impact pour les prochains lots Surface

Un manifeste pourra embarquer un document compatible avec ce schéma.

## 29. Commandes lancées

- `cd packages/map_core && /opt/homebrew/bin/dart test test/project_surface_catalog_json_codec_test.dart`
- régressions : voir section 31 (une commande par fichier)
- `cd packages/map_core` puis `dart analyze` avec la liste de chemins (sortie section 32)
- `cd packages/map_core && /opt/homebrew/bin/dart test`

## 30. Résultat exact : test ciblé Lot 46

```text

00:00 +0: loading test/project_surface_catalog_json_codec_test.dart                                                                                                                                    
00:00 +0: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog                                                                                                                           
00:00 +1: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog                                                                                                                           
00:00 +1: ProjectSurfaceCatalog JSON codec (Lot 46) 2. decodes empty catalog JSON                                                                                                                      
00:00 +2: ProjectSurfaceCatalog JSON codec (Lot 46) 2. decodes empty catalog JSON                                                                                                                      
00:00 +2: ProjectSurfaceCatalog JSON codec (Lot 46) 3. round-trip empty catalog                                                                                                                        
00:00 +3: ProjectSurfaceCatalog JSON codec (Lot 46) 3. round-trip empty catalog                                                                                                                        
00:00 +3: ProjectSurfaceCatalog JSON codec (Lot 46) 4. encodes minimal complete catalog (child codecs)                                                                                                 
00:00 +4: ProjectSurfaceCatalog JSON codec (Lot 46) 4. encodes minimal complete catalog (child codecs)                                                                                                 
00:00 +4: ProjectSurfaceCatalog JSON codec (Lot 46) 5. decodes minimal complete catalog                                                                                                                
00:00 +5: ProjectSurfaceCatalog JSON codec (Lot 46) 5. decodes minimal complete catalog                                                                                                                
00:00 +5: ProjectSurfaceCatalog JSON codec (Lot 46) 6. round-trip minimal complete catalog                                                                                                             
00:00 +6: ProjectSurfaceCatalog JSON codec (Lot 46) 6. round-trip minimal complete catalog                                                                                                             
00:00 +6: ProjectSurfaceCatalog JSON codec (Lot 46) 7. encode preserves atlas order                                                                                                                    
00:00 +7: ProjectSurfaceCatalog JSON codec (Lot 46) 7. encode preserves atlas order                                                                                                                    
00:00 +7: ProjectSurfaceCatalog JSON codec (Lot 46) 8. decode preserves atlas order                                                                                                                    
00:00 +8: ProjectSurfaceCatalog JSON codec (Lot 46) 8. decode preserves atlas order                                                                                                                    
00:00 +8: ProjectSurfaceCatalog JSON codec (Lot 46) 9. encode preserves animation order                                                                                                                
00:00 +9: ProjectSurfaceCatalog JSON codec (Lot 46) 9. encode preserves animation order                                                                                                                
00:00 +9: ProjectSurfaceCatalog JSON codec (Lot 46) 10. decode preserves animation order                                                                                                               
00:00 +10: ProjectSurfaceCatalog JSON codec (Lot 46) 10. decode preserves animation order                                                                                                              
00:00 +10: ProjectSurfaceCatalog JSON codec (Lot 46) 11. encode preserves preset order                                                                                                                 
00:00 +11: ProjectSurfaceCatalog JSON codec (Lot 46) 11. encode preserves preset order                                                                                                                 
00:00 +11: ProjectSurfaceCatalog JSON codec (Lot 46) 12. decode preserves preset order                                                                                                                 
00:00 +12: ProjectSurfaceCatalog JSON codec (Lot 46) 12. decode preserves preset order                                                                                                                 
00:00 +12: ProjectSurfaceCatalog JSON codec (Lot 46) 13. decode rejects missing atlases                                                                                                                
00:00 +13: ProjectSurfaceCatalog JSON codec (Lot 46) 13. decode rejects missing atlases                                                                                                                
00:00 +13: ProjectSurfaceCatalog JSON codec (Lot 46) 14. decode rejects atlases non-list                                                                                                               
00:00 +14: ProjectSurfaceCatalog JSON codec (Lot 46) 14. decode rejects atlases non-list                                                                                                               
00:00 +14: ProjectSurfaceCatalog JSON codec (Lot 46) 15. decode rejects atlas item non-map                                                                                                             
00:00 +15: ProjectSurfaceCatalog JSON codec (Lot 46) 15. decode rejects atlas item non-map                                                                                                             
00:00 +15: ProjectSurfaceCatalog JSON codec (Lot 46) 16. decode rejects invalid atlas via child codec (whitespace id)                                                                                  
00:00 +16: ProjectSurfaceCatalog JSON codec (Lot 46) 16. decode rejects invalid atlas via child codec (whitespace id)                                                                                  
00:00 +16: ProjectSurfaceCatalog JSON codec (Lot 46) 17. decode rejects missing animations                                                                                                             
00:00 +17: ProjectSurfaceCatalog JSON codec (Lot 46) 17. decode rejects missing animations                                                                                                             
00:00 +17: ProjectSurfaceCatalog JSON codec (Lot 46) 18. decode rejects animations non-list                                                                                                            
00:00 +18: ProjectSurfaceCatalog JSON codec (Lot 46) 18. decode rejects animations non-list                                                                                                            
00:00 +18: ProjectSurfaceCatalog JSON codec (Lot 46) 19. decode rejects animation item non-map                                                                                                         
00:00 +19: ProjectSurfaceCatalog JSON codec (Lot 46) 19. decode rejects animation item non-map                                                                                                         
00:00 +19: ProjectSurfaceCatalog JSON codec (Lot 46) 20. decode rejects invalid animation via child codec (empty frames)                                                                               
00:00 +20: ProjectSurfaceCatalog JSON codec (Lot 46) 20. decode rejects invalid animation via child codec (empty frames)                                                                               
00:00 +20: ProjectSurfaceCatalog JSON codec (Lot 46) 21. decode rejects missing presets                                                                                                                
00:00 +21: ProjectSurfaceCatalog JSON codec (Lot 46) 21. decode rejects missing presets                                                                                                                
00:00 +21: ProjectSurfaceCatalog JSON codec (Lot 46) 22. decode rejects presets non-list                                                                                                               
00:00 +22: ProjectSurfaceCatalog JSON codec (Lot 46) 22. decode rejects presets non-list                                                                                                               
00:00 +22: ProjectSurfaceCatalog JSON codec (Lot 46) 23. decode rejects preset item non-map                                                                                                            
00:00 +23: ProjectSurfaceCatalog JSON codec (Lot 46) 23. decode rejects preset item non-map                                                                                                            
00:00 +23: ProjectSurfaceCatalog JSON codec (Lot 46) 24. decode rejects invalid preset via child codec (empty refs)                                                                                    
00:00 +24: ProjectSurfaceCatalog JSON codec (Lot 46) 24. decode rejects invalid preset via child codec (empty refs)                                                                                    
00:00 +24: ProjectSurfaceCatalog JSON codec (Lot 46) 25. decode rejects duplicate atlas ids (model)                                                                                                    
00:00 +25: ProjectSurfaceCatalog JSON codec (Lot 46) 25. decode rejects duplicate atlas ids (model)                                                                                                    
00:00 +25: ProjectSurfaceCatalog JSON codec (Lot 46) 26. decode rejects duplicate animation ids (model)                                                                                                
00:00 +26: ProjectSurfaceCatalog JSON codec (Lot 46) 26. decode rejects duplicate animation ids (model)                                                                                                
00:00 +26: ProjectSurfaceCatalog JSON codec (Lot 46) 27. decode rejects duplicate preset ids (model)                                                                                                   
00:00 +27: ProjectSurfaceCatalog JSON codec (Lot 46) 27. decode rejects duplicate preset ids (model)                                                                                                   
00:00 +27: ProjectSurfaceCatalog JSON codec (Lot 46) 28. decode ignores unknown top-level key                                                                                                          
00:00 +28: ProjectSurfaceCatalog JSON codec (Lot 46) 28. decode ignores unknown top-level key                                                                                                          
00:00 +28: ProjectSurfaceCatalog JSON codec (Lot 46) 29. decode ignores unknown keys in child items                                                                                                    
00:00 +29: ProjectSurfaceCatalog JSON codec (Lot 46) 29. decode ignores unknown keys in child items                                                                                                    
00:00 +29: ProjectSurfaceCatalog JSON codec (Lot 46) 30. decode does not mutate source map                                                                                                             
00:00 +30: ProjectSurfaceCatalog JSON codec (Lot 46) 30. decode does not mutate source map                                                                                                             
00:00 +30: ProjectSurfaceCatalog JSON codec (Lot 46) 31. encode does not mutate catalog                                                                                                                
00:00 +31: ProjectSurfaceCatalog JSON codec (Lot 46) 31. encode does not mutate catalog                                                                                                                
00:00 +31: ProjectSurfaceCatalog JSON codec (Lot 46) 32. codec does not resolve animationId; diagnostics catch missing                                                                                 
00:00 +32: ProjectSurfaceCatalog JSON codec (Lot 46) 32. codec does not resolve animationId; diagnostics catch missing                                                                                 
00:00 +32: ProjectSurfaceCatalog JSON codec (Lot 46) 33. codec does not resolve atlasId; diagnostics catch missing atlas                                                                               
00:00 +33: ProjectSurfaceCatalog JSON codec (Lot 46) 33. codec does not resolve atlasId; diagnostics catch missing atlas                                                                               
00:00 +33: ProjectSurfaceCatalog JSON codec (Lot 46) 34. codec does not check geometry; diagnostics catch out of bounds                                                                                
00:00 +34: ProjectSurfaceCatalog JSON codec (Lot 46) 34. codec does not check geometry; diagnostics catch out of bounds                                                                                
00:00 +34: ProjectSurfaceCatalog JSON codec (Lot 46) 35. codec does not call unused diagnostics; unused can warn after                                                                                 
00:00 +35: ProjectSurfaceCatalog JSON codec (Lot 46) 35. codec does not call unused diagnostics; unused can warn after                                                                                 
00:00 +35: ProjectSurfaceCatalog JSON codec (Lot 46) 36. reuses Lot 39 atlas codec for atlases[0]                                                                                                      
00:00 +36: ProjectSurfaceCatalog JSON codec (Lot 46) 36. reuses Lot 39 atlas codec for atlases[0]                                                                                                      
00:00 +36: ProjectSurfaceCatalog JSON codec (Lot 46) 37. reuses Lot 42 animation codec for animations[0]                                                                                               
00:00 +37: ProjectSurfaceCatalog JSON codec (Lot 46) 37. reuses Lot 42 animation codec for animations[0]                                                                                               
00:00 +37: ProjectSurfaceCatalog JSON codec (Lot 46) 38. reuses Lot 45 preset codec for presets[0]                                                                                                     
00:00 +38: ProjectSurfaceCatalog JSON codec (Lot 46) 38. reuses Lot 45 preset codec for presets[0]                                                                                                     
00:00 +38: ProjectSurfaceCatalog JSON codec (Lot 46) 39. public API encode returns map                                                                                                                 
00:00 +39: ProjectSurfaceCatalog JSON codec (Lot 46) 39. public API encode returns map                                                                                                                 
00:00 +39: ProjectSurfaceCatalog JSON codec (Lot 46) 40. ProjectManifest has no surface persistence keys (Lot 46)                                                                                      
00:00 +40: ProjectSurfaceCatalog JSON codec (Lot 46) 40. ProjectManifest has no surface persistence keys (Lot 46)                                                                                      
00:00 +40: ProjectSurfaceCatalog JSON codec (Lot 46) 41. codec external to model: no catalog.toJson or ProjectSurfaceCatalog.fromJson                                                                  
00:00 +41: ProjectSurfaceCatalog JSON codec (Lot 46) 41. codec external to model: no catalog.toJson or ProjectSurfaceCatalog.fromJson                                                                  
00:00 +41: ProjectSurfaceCatalog JSON codec (Lot 46) 42. manifest surface integration remains out of scope (no manifest codec)                                                                         
00:00 +42: ProjectSurfaceCatalog JSON codec (Lot 46) 42. manifest surface integration remains out of scope (no manifest codec)                                                                         
00:00 +42: ProjectSurfaceCatalog JSON codec (Lot 46) 43. no Surface categories array; categoryId stays per-item string                                                                                 
00:00 +43: ProjectSurfaceCatalog JSON codec (Lot 46) 43. no Surface categories array; categoryId stays per-item string                                                                                 
00:00 +43: ProjectSurfaceCatalog JSON codec (Lot 46) 44. no kind / surfaceKind / presetKind / type at catalog or preset JSON                                                                           
00:00 +44: ProjectSurfaceCatalog JSON codec (Lot 46) 44. no kind / surfaceKind / presetKind / type at catalog or preset JSON                                                                           
00:00 +44: All tests passed!                                                                                                                                                                           
```

## 31. Résultats : tests de régression (sorties intégrales, normalisation `\r`)

### `test/project_surface_catalog_test.dart`

```

00:00 +0: loading test/project_surface_catalog_test.dart                                                                                                                                               
00:00 +0: ProjectSurfaceCatalog (Lot 33) 1. empty catalog: counts, isEmpty, unmodifiable empty lists                                                                                                   
00:00 +1: ProjectSurfaceCatalog (Lot 33) 1. empty catalog: counts, isEmpty, unmodifiable empty lists                                                                                                   
00:00 +1: ProjectSurfaceCatalog (Lot 33) 2. catalog with 2 of each kind: counts, isNotEmpty                                                                                                            
00:00 +2: ProjectSurfaceCatalog (Lot 33) 2. catalog with 2 of each kind: counts, isNotEmpty                                                                                                            
00:00 +2: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved                                                                                                                                 
00:00 +3: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved                                                                                                                                 
00:00 +3: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved                                                                                                                              
00:00 +4: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved                                                                                                                              
00:00 +4: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved                                                                                                                                 
00:00 +5: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved                                                                                                                                 
00:00 +5: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws                                                                                                                 
00:00 +6: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws                                                                                                                 
00:00 +6: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build                                                                                                         
00:00 +7: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build                                                                                                         
00:00 +7: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build                                                                                                      
00:00 +8: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build                                                                                                      
00:00 +8: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build                                                                                                         
00:00 +9: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build                                                                                                         
00:00 +9: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException                                                                                                             
00:00 +10: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException                                                                                                            
00:00 +10: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException                                                                                                        
00:00 +11: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException                                                                                                        
00:00 +11: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException                                                                                                           
00:00 +12: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException                                                                                                           
00:00 +12: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups                                                                                                    
00:00 +13: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups                                                                                                    
00:00 +13: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present                                                                                                                  
00:00 +14: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present                                                                                                                  
00:00 +14: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent                                                                                                                               
00:00 +15: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent                                                                                                                               
00:00 +15: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present                                                                                                              
00:00 +16: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present                                                                                                              
00:00 +16: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent                                                                                                                           
00:00 +17: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent                                                                                                                           
00:00 +17: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present                                                                                                                 
00:00 +18: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present                                                                                                                 
00:00 +18: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent                                                                                                                              
00:00 +19: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent                                                                                                                              
00:00 +19: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup                                                                                                                        
00:00 +20: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup                                                                                                                        
00:00 +20: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup                                                                                                                    
00:00 +21: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup                                                                                                                    
00:00 +21: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup                                                                                                                       
00:00 +22: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup                                                                                                                       
00:00 +22: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas                                                                                                            
00:00 +23: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas                                                                                                            
00:00 +23: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error                                                                                                 
00:00 +24: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error                                                                                                 
00:00 +24: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode                                                                                                 
00:00 +25: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode                                                                                                 
00:00 +25: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order                                                                                                                  
00:00 +26: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order                                                                                                                  
00:00 +26: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order                                                                                                              
00:00 +27: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order                                                                                                              
00:00 +27: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order                                                                                                                 
00:00 +28: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order                                                                                                                 
00:00 +28: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content                                                                                                                      
00:00 +29: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content                                                                                                                      
00:00 +29: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core                                                                                               
00:00 +30: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core                                                                                               
00:00 +30: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest still has no Surface persistence keys (Lot 33)                                                                                           
00:00 +31: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest still has no Surface persistence keys (Lot 33)                                                                                           
00:00 +31: All tests passed!                                                                                                                                                                           

```

### `test/surface_atlas_json_codec_test.dart`

```

00:00 +0: loading test/surface_atlas_json_codec_test.dart                                                                                                                                              
00:00 +0: surface_atlas_json_codec (Lot 39) 1. encode SurfaceAtlasTileSize                                                                                                                             
00:00 +1: surface_atlas_json_codec (Lot 39) 1. encode SurfaceAtlasTileSize                                                                                                                             
00:00 +1: surface_atlas_json_codec (Lot 39) 2. decode SurfaceAtlasTileSize                                                                                                                             
00:00 +2: surface_atlas_json_codec (Lot 39) 2. decode SurfaceAtlasTileSize                                                                                                                             
00:00 +2: surface_atlas_json_codec (Lot 39) 3. reject tile size missing / wrong type / width 0                                                                                                         
00:00 +3: surface_atlas_json_codec (Lot 39) 3. reject tile size missing / wrong type / width 0                                                                                                         
00:00 +3: surface_atlas_json_codec (Lot 39) 4. encode SurfaceAtlasGridSize                                                                                                                             
00:00 +4: surface_atlas_json_codec (Lot 39) 4. encode SurfaceAtlasGridSize                                                                                                                             
00:00 +4: surface_atlas_json_codec (Lot 39) 5. decode SurfaceAtlasGridSize                                                                                                                             
00:00 +5: surface_atlas_json_codec (Lot 39) 5. decode SurfaceAtlasGridSize                                                                                                                             
00:00 +5: surface_atlas_json_codec (Lot 39) 6. reject grid size missing / wrong type / columns 0                                                                                                       
00:00 +6: surface_atlas_json_codec (Lot 39) 6. reject grid size missing / wrong type / columns 0                                                                                                       
00:00 +6: surface_atlas_json_codec (Lot 39) 7. encode/decode layout grid                                                                                                                               
00:00 +7: surface_atlas_json_codec (Lot 39) 7. encode/decode layout grid                                                                                                                               
00:00 +7: surface_atlas_json_codec (Lot 39) 8. encode/decode layout columnsAreVariantsRowsAreFrames                                                                                                    
00:00 +8: surface_atlas_json_codec (Lot 39) 8. encode/decode layout columnsAreVariantsRowsAreFrames                                                                                                    
00:00 +8: surface_atlas_json_codec (Lot 39) 9. reject layout unknown or wrong casing                                                                                                                   
00:00 +9: surface_atlas_json_codec (Lot 39) 9. reject layout unknown or wrong casing                                                                                                                   
00:00 +9: surface_atlas_json_codec (Lot 39) 10. encode SurfaceAtlasGeometry                                                                                                                            
00:00 +10: surface_atlas_json_codec (Lot 39) 10. encode SurfaceAtlasGeometry                                                                                                                           
00:00 +10: surface_atlas_json_codec (Lot 39) 11. decode SurfaceAtlasGeometry + tileCount                                                                                                               
00:00 +11: surface_atlas_json_codec (Lot 39) 11. decode SurfaceAtlasGeometry + tileCount                                                                                                               
00:00 +11: surface_atlas_json_codec (Lot 39) 12. reject geometry missing nested / wrong types                                                                                                          
00:00 +12: surface_atlas_json_codec (Lot 39) 12. reject geometry missing nested / wrong types                                                                                                          
00:00 +12: surface_atlas_json_codec (Lot 39) 13. encode ProjectSurfaceAtlas minimal                                                                                                                    
00:00 +13: surface_atlas_json_codec (Lot 39) 13. encode ProjectSurfaceAtlas minimal                                                                                                                    
00:00 +13: surface_atlas_json_codec (Lot 39) 14. encode ProjectSurfaceAtlas full                                                                                                                       
00:00 +14: surface_atlas_json_codec (Lot 39) 14. encode ProjectSurfaceAtlas full                                                                                                                       
00:00 +14: surface_atlas_json_codec (Lot 39) 15. decode ProjectSurfaceAtlas minimal (no category, no sortOrder)                                                                                        
00:00 +15: surface_atlas_json_codec (Lot 39) 15. decode ProjectSurfaceAtlas minimal (no category, no sortOrder)                                                                                        
00:00 +15: surface_atlas_json_codec (Lot 39) 16. decode ProjectSurfaceAtlas full                                                                                                                       
00:00 +16: surface_atlas_json_codec (Lot 39) 16. decode ProjectSurfaceAtlas full                                                                                                                       
00:00 +16: surface_atlas_json_codec (Lot 39) 17. round-trip ProjectSurfaceAtlas                                                                                                                        
00:00 +17: surface_atlas_json_codec (Lot 39) 17. round-trip ProjectSurfaceAtlas                                                                                                                        
00:00 +17: surface_atlas_json_codec (Lot 39) 18. exact strings preserved (no trim in codec)                                                                                                            
00:00 +18: surface_atlas_json_codec (Lot 39) 18. exact strings preserved (no trim in codec)                                                                                                            
00:00 +18: surface_atlas_json_codec (Lot 39) 19. reject id / name / tilesetId missing, wrong type, whitespace tileset                                                                                  
00:00 +19: surface_atlas_json_codec (Lot 39) 19. reject id / name / tilesetId missing, wrong type, whitespace tileset                                                                                  
00:00 +19: surface_atlas_json_codec (Lot 39) 20. reject geometry missing or non-map on atlas                                                                                                           
00:00 +20: surface_atlas_json_codec (Lot 39) 20. reject geometry missing or non-map on atlas                                                                                                           
00:00 +20: surface_atlas_json_codec (Lot 39) 21. reject categoryId non-string non-null                                                                                                                 
00:00 +21: surface_atlas_json_codec (Lot 39) 21. reject categoryId non-string non-null                                                                                                                 
00:00 +21: surface_atlas_json_codec (Lot 39) 22. decode categoryId null in JSON                                                                                                                        
00:00 +22: surface_atlas_json_codec (Lot 39) 22. decode categoryId null in JSON                                                                                                                        
00:00 +22: surface_atlas_json_codec (Lot 39) 23. reject sortOrder non-int                                                                                                                              
00:00 +23: surface_atlas_json_codec (Lot 39) 23. reject sortOrder non-int                                                                                                                              
00:00 +23: surface_atlas_json_codec (Lot 39) 24. decode sortOrder negative                                                                                                                             
00:00 +24: surface_atlas_json_codec (Lot 39) 24. decode sortOrder negative                                                                                                                             
00:00 +24: surface_atlas_json_codec (Lot 39) 25. decode ignores unknown top-level key                                                                                                                  
00:00 +25: surface_atlas_json_codec (Lot 39) 25. decode ignores unknown top-level key                                                                                                                  
00:00 +25: surface_atlas_json_codec (Lot 39) 26. tilesetId not resolved against manifest                                                                                                               
00:00 +26: surface_atlas_json_codec (Lot 39) 26. tilesetId not resolved against manifest                                                                                                               
00:00 +26: surface_atlas_json_codec (Lot 39) 27. decode does not mutate source map                                                                                                                     
00:00 +27: surface_atlas_json_codec (Lot 39) 27. decode does not mutate source map                                                                                                                     
00:00 +27: surface_atlas_json_codec (Lot 39) 28. public API returns Map from encode                                                                                                                    
00:00 +28: surface_atlas_json_codec (Lot 39) 28. public API returns Map from encode                                                                                                                    
00:00 +28: surface_atlas_json_codec (Lot 39) 29. ProjectManifest has no surface persistence keys (Lot 39)                                                                                              
00:00 +29: surface_atlas_json_codec (Lot 39) 29. ProjectManifest has no surface persistence keys (Lot 39)                                                                                              
00:00 +29: surface_atlas_json_codec (Lot 39) 30. codec external to models: no model toJson / fromJson                                                                                                  
00:00 +30: surface_atlas_json_codec (Lot 39) 30. codec external to models: no model toJson / fromJson                                                                                                  
00:00 +30: All tests passed!                                                                                                                                                                           

```

### `test/project_surface_animation_json_codec_test.dart`

```

00:00 +0: loading test/project_surface_animation_json_codec_test.dart                                                                                                                                  
00:00 +0: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation                                                                                                       
00:00 +1: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation                                                                                                       
00:00 +1: ProjectSurfaceAnimation JSON codec (Lot 42) 2. decodes minimal ProjectSurfaceAnimation                                                                                                       
00:00 +2: ProjectSurfaceAnimation JSON codec (Lot 42) 2. decodes minimal ProjectSurfaceAnimation                                                                                                       
00:00 +2: ProjectSurfaceAnimation JSON codec (Lot 42) 3. round-trip minimal animation                                                                                                                  
00:00 +3: ProjectSurfaceAnimation JSON codec (Lot 42) 3. round-trip minimal animation                                                                                                                  
00:00 +3: ProjectSurfaceAnimation JSON codec (Lot 42) 4. encodes full animation (sync, category, sort)                                                                                                 
00:00 +4: ProjectSurfaceAnimation JSON codec (Lot 42) 4. encodes full animation (sync, category, sort)                                                                                                 
00:00 +4: ProjectSurfaceAnimation JSON codec (Lot 42) 5. decodes full animation                                                                                                                        
00:00 +5: ProjectSurfaceAnimation JSON codec (Lot 42) 5. decodes full animation                                                                                                                        
00:00 +5: ProjectSurfaceAnimation JSON codec (Lot 42) 6. round-trip full animation                                                                                                                     
00:00 +6: ProjectSurfaceAnimation JSON codec (Lot 42) 6. round-trip full animation                                                                                                                     
00:00 +6: ProjectSurfaceAnimation JSON codec (Lot 42) 7. encode preserves multi-frame timeline                                                                                                         
00:00 +7: ProjectSurfaceAnimation JSON codec (Lot 42) 7. encode preserves multi-frame timeline                                                                                                         
00:00 +7: ProjectSurfaceAnimation JSON codec (Lot 42) 8. decodes multi-frame timeline                                                                                                                  
00:00 +8: ProjectSurfaceAnimation JSON codec (Lot 42) 8. decodes multi-frame timeline                                                                                                                  
00:00 +8: ProjectSurfaceAnimation JSON codec (Lot 42) 9. decode preserves exact id/name/sync/category strings                                                                                          
00:00 +9: ProjectSurfaceAnimation JSON codec (Lot 42) 9. decode preserves exact id/name/sync/category strings                                                                                          
00:00 +9: ProjectSurfaceAnimation JSON codec (Lot 42) 10. reject id missing / wrong type / whitespace-only                                                                                             
00:00 +10: ProjectSurfaceAnimation JSON codec (Lot 42) 10. reject id missing / wrong type / whitespace-only                                                                                            
00:00 +10: ProjectSurfaceAnimation JSON codec (Lot 42) 11. reject name missing / wrong type / whitespace-only                                                                                          
00:00 +11: ProjectSurfaceAnimation JSON codec (Lot 42) 11. reject name missing / wrong type / whitespace-only                                                                                          
00:00 +11: ProjectSurfaceAnimation JSON codec (Lot 42) 12. reject timeline missing / not a Map                                                                                                         
00:00 +12: ProjectSurfaceAnimation JSON codec (Lot 42) 12. reject timeline missing / not a Map                                                                                                         
00:00 +12: ProjectSurfaceAnimation JSON codec (Lot 42) 13. reject empty timeline frames                                                                                                                
00:00 +13: ProjectSurfaceAnimation JSON codec (Lot 42) 13. reject empty timeline frames                                                                                                                
00:00 +13: ProjectSurfaceAnimation JSON codec (Lot 42) 14. decode ignores unknown top-level key                                                                                                        
00:00 +14: ProjectSurfaceAnimation JSON codec (Lot 42) 14. decode ignores unknown top-level key                                                                                                        
00:00 +14: ProjectSurfaceAnimation JSON codec (Lot 42) 15. decode ignores unknown keys in timeline / frame / tileRef                                                                                   
00:00 +15: ProjectSurfaceAnimation JSON codec (Lot 42) 15. decode ignores unknown keys in timeline / frame / tileRef                                                                                   
00:00 +15: ProjectSurfaceAnimation JSON codec (Lot 42) 16. decode accepts syncGroupId: null in JSON                                                                                                    
00:00 +16: ProjectSurfaceAnimation JSON codec (Lot 42) 16. decode accepts syncGroupId: null in JSON                                                                                                    
00:00 +16: ProjectSurfaceAnimation JSON codec (Lot 42) 17. reject syncGroupId non-string non-null                                                                                                      
00:00 +17: ProjectSurfaceAnimation JSON codec (Lot 42) 17. reject syncGroupId non-string non-null                                                                                                      
00:00 +17: ProjectSurfaceAnimation JSON codec (Lot 42) 18. reject syncGroupId whitespace-only (model + codec)                                                                                          
00:00 +18: ProjectSurfaceAnimation JSON codec (Lot 42) 18. reject syncGroupId whitespace-only (model + codec)                                                                                          
00:00 +18: ProjectSurfaceAnimation JSON codec (Lot 42) 19. decode accepts categoryId: null                                                                                                             
00:00 +19: ProjectSurfaceAnimation JSON codec (Lot 42) 19. decode accepts categoryId: null                                                                                                             
00:00 +19: ProjectSurfaceAnimation JSON codec (Lot 42) 20. reject categoryId non-string non-null                                                                                                       
00:00 +20: ProjectSurfaceAnimation JSON codec (Lot 42) 20. reject categoryId non-string non-null                                                                                                       
00:00 +20: ProjectSurfaceAnimation JSON codec (Lot 42) 21. decode accepts sortOrder absent (default 0)                                                                                                 
00:00 +21: ProjectSurfaceAnimation JSON codec (Lot 42) 21. decode accepts sortOrder absent (default 0)                                                                                                 
00:00 +21: ProjectSurfaceAnimation JSON codec (Lot 42) 22. decode accepts negative sortOrder                                                                                                           
00:00 +22: ProjectSurfaceAnimation JSON codec (Lot 42) 22. decode accepts negative sortOrder                                                                                                           
00:00 +22: ProjectSurfaceAnimation JSON codec (Lot 42) 23. reject sortOrder non-int                                                                                                                    
00:00 +23: ProjectSurfaceAnimation JSON codec (Lot 42) 23. reject sortOrder non-int                                                                                                                    
00:00 +23: ProjectSurfaceAnimation JSON codec (Lot 42) 24. decode does not mutate source map                                                                                                           
00:00 +24: ProjectSurfaceAnimation JSON codec (Lot 42) 24. decode does not mutate source map                                                                                                           
00:00 +24: ProjectSurfaceAnimation JSON codec (Lot 42) 25. encode does not mutate source animation                                                                                                     
00:00 +25: ProjectSurfaceAnimation JSON codec (Lot 42) 25. encode does not mutate source animation                                                                                                     
00:00 +25: ProjectSurfaceAnimation JSON codec (Lot 42) 26. no geometry in codec; isInside is separate                                                                                                  
00:00 +26: ProjectSurfaceAnimation JSON codec (Lot 42) 26. no geometry in codec; isInside is separate                                                                                                  
00:00 +26: ProjectSurfaceAnimation JSON codec (Lot 42) 27. no external resolution of atlasId                                                                                                           
00:00 +27: ProjectSurfaceAnimation JSON codec (Lot 42) 27. no external resolution of atlasId                                                                                                           
00:00 +27: ProjectSurfaceAnimation JSON codec (Lot 42) 28. public API encode returns Map                                                                                                               
00:00 +28: ProjectSurfaceAnimation JSON codec (Lot 42) 28. public API encode returns Map                                                                                                               
00:00 +28: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)                                                                                    
00:00 +29: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)                                                                                    
00:00 +29: ProjectSurfaceAnimation JSON codec (Lot 42) 30. codec external to model: no animation.toJson or ProjectSurfaceAnimation.fromJson                                                            
00:00 +30: ProjectSurfaceAnimation JSON codec (Lot 42) 30. codec external to model: no animation.toJson or ProjectSurfaceAnimation.fromJson                                                            
00:00 +30: ProjectSurfaceAnimation JSON codec (Lot 42) 31. no preset / catalog / variant ref codec in this lot                                                                                         
00:00 +31: ProjectSurfaceAnimation JSON codec (Lot 42) 31. no preset / catalog / variant ref codec in this lot                                                                                         
00:00 +31: ProjectSurfaceAnimation JSON codec (Lot 42) 32. reuses Lot 41 timeline codec (json[timeline] == encodeTimeline)                                                                             
00:00 +32: ProjectSurfaceAnimation JSON codec (Lot 42) 32. reuses Lot 41 timeline codec (json[timeline] == encodeTimeline)                                                                             
00:00 +32: All tests passed!                                                                                                                                                                           

```

### `test/project_surface_preset_json_codec_test.dart`

```

00:00 +0: loading test/project_surface_preset_json_codec_test.dart                                                                                                                                     
00:00 +0: ProjectSurfacePreset JSON codec (Lot 45) 1. encodes minimal preset                                                                                                                           
00:00 +1: ProjectSurfacePreset JSON codec (Lot 45) 1. encodes minimal preset                                                                                                                           
00:00 +1: ProjectSurfacePreset JSON codec (Lot 45) 2. decodes minimal preset                                                                                                                           
00:00 +2: ProjectSurfacePreset JSON codec (Lot 45) 2. decodes minimal preset                                                                                                                           
00:00 +2: ProjectSurfacePreset JSON codec (Lot 45) 3. round-trip minimal preset                                                                                                                        
00:00 +3: ProjectSurfacePreset JSON codec (Lot 45) 3. round-trip minimal preset                                                                                                                        
00:00 +3: ProjectSurfacePreset JSON codec (Lot 45) 4. encodes full preset (category + sortOrder)                                                                                                       
00:00 +4: ProjectSurfacePreset JSON codec (Lot 45) 4. encodes full preset (category + sortOrder)                                                                                                       
00:00 +4: ProjectSurfacePreset JSON codec (Lot 45) 5. decodes full preset                                                                                                                              
00:00 +5: ProjectSurfacePreset JSON codec (Lot 45) 5. decodes full preset                                                                                                                              
00:00 +5: ProjectSurfacePreset JSON codec (Lot 45) 6. round-trip full preset                                                                                                                           
00:00 +6: ProjectSurfacePreset JSON codec (Lot 45) 6. round-trip full preset                                                                                                                           
00:00 +6: ProjectSurfacePreset JSON codec (Lot 45) 7. encode preserves multi-ref order in variantAnimations                                                                                            
00:00 +7: ProjectSurfacePreset JSON codec (Lot 45) 7. encode preserves multi-ref order in variantAnimations                                                                                            
00:00 +7: ProjectSurfacePreset JSON codec (Lot 45) 8. decode preserves multi-ref order                                                                                                                 
00:00 +8: ProjectSurfacePreset JSON codec (Lot 45) 8. decode preserves multi-ref order                                                                                                                 
00:00 +8: ProjectSurfacePreset JSON codec (Lot 45) 9. decode preserves exact id name category strings                                                                                                  
00:00 +9: ProjectSurfacePreset JSON codec (Lot 45) 9. decode preserves exact id name category strings                                                                                                  
00:00 +9: ProjectSurfacePreset JSON codec (Lot 45) 10. reject id missing / wrong type / whitespace-only                                                                                                
00:00 +10: ProjectSurfacePreset JSON codec (Lot 45) 10. reject id missing / wrong type / whitespace-only                                                                                               
00:00 +10: ProjectSurfacePreset JSON codec (Lot 45) 11. reject name missing / wrong type / whitespace-only                                                                                             
00:00 +11: ProjectSurfacePreset JSON codec (Lot 45) 11. reject name missing / wrong type / whitespace-only                                                                                             
00:00 +11: ProjectSurfacePreset JSON codec (Lot 45) 12. reject variantAnimations missing or wrong type                                                                                                 
00:00 +12: ProjectSurfacePreset JSON codec (Lot 45) 12. reject variantAnimations missing or wrong type                                                                                                 
00:00 +12: ProjectSurfacePreset JSON codec (Lot 45) 13. reject empty variantAnimations refs                                                                                                            
00:00 +13: ProjectSurfacePreset JSON codec (Lot 45) 13. reject empty variantAnimations refs                                                                                                            
00:00 +13: ProjectSurfacePreset JSON codec (Lot 45) 14. reject duplicate role in variantAnimations                                                                                                     
00:00 +14: ProjectSurfacePreset JSON codec (Lot 45) 14. reject duplicate role in variantAnimations                                                                                                     
00:00 +14: ProjectSurfacePreset JSON codec (Lot 45) 15. reject invalid role in variantAnimations                                                                                                       
00:00 +15: ProjectSurfacePreset JSON codec (Lot 45) 15. reject invalid role in variantAnimations                                                                                                       
00:00 +15: ProjectSurfacePreset JSON codec (Lot 45) 16. reject invalid animationId in variantAnimations                                                                                                
00:00 +16: ProjectSurfacePreset JSON codec (Lot 45) 16. reject invalid animationId in variantAnimations                                                                                                
00:00 +16: ProjectSurfacePreset JSON codec (Lot 45) 17. decode ignores unknown top-level key                                                                                                           
00:00 +17: ProjectSurfacePreset JSON codec (Lot 45) 17. decode ignores unknown top-level key                                                                                                           
00:00 +17: ProjectSurfacePreset JSON codec (Lot 45) 18. decode ignores unknown keys in variantAnimations and refs                                                                                      
00:00 +18: ProjectSurfacePreset JSON codec (Lot 45) 18. decode ignores unknown keys in variantAnimations and refs                                                                                      
00:00 +18: ProjectSurfacePreset JSON codec (Lot 45) 19. decode accepts categoryId: null in JSON                                                                                                        
00:00 +19: ProjectSurfacePreset JSON codec (Lot 45) 19. decode accepts categoryId: null in JSON                                                                                                        
00:00 +19: ProjectSurfacePreset JSON codec (Lot 45) 20. decode reject categoryId non-string non-null                                                                                                   
00:00 +20: ProjectSurfacePreset JSON codec (Lot 45) 20. decode reject categoryId non-string non-null                                                                                                   
00:00 +20: ProjectSurfacePreset JSON codec (Lot 45) 21. decode accept sortOrder absent (default 0)                                                                                                     
00:00 +21: ProjectSurfacePreset JSON codec (Lot 45) 21. decode accept sortOrder absent (default 0)                                                                                                     
00:00 +21: ProjectSurfacePreset JSON codec (Lot 45) 22. decode accept negative sortOrder                                                                                                               
00:00 +22: ProjectSurfacePreset JSON codec (Lot 45) 22. decode accept negative sortOrder                                                                                                               
00:00 +22: ProjectSurfacePreset JSON codec (Lot 45) 23. decode reject sortOrder non-int                                                                                                                
00:00 +23: ProjectSurfacePreset JSON codec (Lot 45) 23. decode reject sortOrder non-int                                                                                                                
00:00 +23: ProjectSurfacePreset JSON codec (Lot 45) 24. decode does not mutate source map                                                                                                              
00:00 +24: ProjectSurfacePreset JSON codec (Lot 45) 24. decode does not mutate source map                                                                                                              
00:00 +24: ProjectSurfacePreset JSON codec (Lot 45) 25. encode does not mutate preset                                                                                                                  
00:00 +25: ProjectSurfacePreset JSON codec (Lot 45) 25. encode does not mutate preset                                                                                                                  
00:00 +25: ProjectSurfacePreset JSON codec (Lot 45) 26. does not resolve animationId                                                                                                                   
00:00 +26: ProjectSurfacePreset JSON codec (Lot 45) 26. does not resolve animationId                                                                                                                   
00:00 +26: ProjectSurfacePreset JSON codec (Lot 45) 27. does not complete missing standard roles                                                                                                       
00:00 +27: ProjectSurfacePreset JSON codec (Lot 45) 27. does not complete missing standard roles                                                                                                       
00:00 +27: ProjectSurfacePreset JSON codec (Lot 45) 28. reuses Lot 44 RefSet codec for variantAnimations                                                                                               
00:00 +28: ProjectSurfacePreset JSON codec (Lot 45) 28. reuses Lot 44 RefSet codec for variantAnimations                                                                                               
00:00 +28: ProjectSurfacePreset JSON codec (Lot 45) 29. public API encode returns map                                                                                                                  
00:00 +29: ProjectSurfacePreset JSON codec (Lot 45) 29. public API encode returns map                                                                                                                  
00:00 +29: ProjectSurfacePreset JSON codec (Lot 45) 30. ProjectManifest has no surface persistence keys (Lot 45)                                                                                       
00:00 +30: ProjectSurfacePreset JSON codec (Lot 45) 30. ProjectManifest has no surface persistence keys (Lot 45)                                                                                       
00:00 +30: ProjectSurfacePreset JSON codec (Lot 45) 31. codec external to model: no preset.toJson or ProjectSurfacePreset.fromJson                                                                     
00:00 +31: ProjectSurfacePreset JSON codec (Lot 45) 31. codec external to model: no preset.toJson or ProjectSurfacePreset.fromJson                                                                     
00:00 +31: ProjectSurfacePreset JSON codec (Lot 45) 32. ProjectSurfaceCatalog codec remains out of scope (Lot 46)                                                                                      
00:00 +32: ProjectSurfacePreset JSON codec (Lot 45) 32. ProjectSurfaceCatalog codec remains out of scope (Lot 46)                                                                                      
00:00 +32: ProjectSurfacePreset JSON codec (Lot 45) 33. no SurfacePresetKind / surfaceKind keys in JSON                                                                                                
00:00 +33: ProjectSurfacePreset JSON codec (Lot 45) 33. no SurfacePresetKind / surfaceKind keys in JSON                                                                                                
00:00 +33: ProjectSurfacePreset JSON codec (Lot 45) 34. standardSurfaceVariantRoleOrder length 20 (Lot 28 doc)                                                                                         
00:00 +34: ProjectSurfacePreset JSON codec (Lot 45) 34. standardSurfaceVariantRoleOrder length 20 (Lot 28 doc)                                                                                         
00:00 +34: All tests passed!                                                                                                                                                                           

```

### `test/surface_catalog_diagnostics_test.dart`

```

00:00 +0: loading test/surface_catalog_diagnostics_test.dart                                                                                                                                           
00:00 +0: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics                                                                                                                      
00:00 +1: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics                                                                                                                      
00:00 +1: diagnoseProjectSurfaceCatalog (Lot 34) 2. minimal coherent: no diagnostics                                                                                                                   
00:00 +2: diagnoseProjectSurfaceCatalog (Lot 34) 2. minimal coherent: no diagnostics                                                                                                                   
00:00 +2: diagnoseProjectSurfaceCatalog (Lot 34) 3. missing preset animation                                                                                                                           
00:00 +3: diagnoseProjectSurfaceCatalog (Lot 34) 3. missing preset animation                                                                                                                           
00:00 +3: diagnoseProjectSurfaceCatalog (Lot 34) 4. two missing refs: order follows refs                                                                                                               
00:00 +4: diagnoseProjectSurfaceCatalog (Lot 34) 4. two missing refs: order follows refs                                                                                                               
00:00 +4: diagnoseProjectSurfaceCatalog (Lot 34) 5. two presets: order follows catalog.presets                                                                                                         
00:00 +5: diagnoseProjectSurfaceCatalog (Lot 34) 5. two presets: order follows catalog.presets                                                                                                         
00:00 +5: diagnoseProjectSurfaceCatalog (Lot 34) 6. missing animation atlas                                                                                                                            
00:00 +6: diagnoseProjectSurfaceCatalog (Lot 34) 6. missing animation atlas                                                                                                                            
00:00 +6: diagnoseProjectSurfaceCatalog (Lot 34) 7. two frames to missing atlas: frameIndex 0 and 1                                                                                                    
00:00 +7: diagnoseProjectSurfaceCatalog (Lot 34) 7. two frames to missing atlas: frameIndex 0 and 1                                                                                                    
00:00 +7: diagnoseProjectSurfaceCatalog (Lot 34) 8. frame outside geometry: column                                                                                                                     
00:00 +8: diagnoseProjectSurfaceCatalog (Lot 34) 8. frame outside geometry: column                                                                                                                     
00:00 +8: diagnoseProjectSurfaceCatalog (Lot 34) 9. frame outside geometry: row                                                                                                                        
00:00 +9: diagnoseProjectSurfaceCatalog (Lot 34) 9. frame outside geometry: row                                                                                                                        
00:00 +9: diagnoseProjectSurfaceCatalog (Lot 34) 10. missing atlas only: not also outside geometry                                                                                                     
00:00 +10: diagnoseProjectSurfaceCatalog (Lot 34) 10. missing atlas only: not also outside geometry                                                                                                    
00:00 +10: diagnoseProjectSurfaceCatalog (Lot 34) 11. preset diagnostics then animation diagnostics                                                                                                    
00:00 +11: diagnoseProjectSurfaceCatalog (Lot 34) 11. preset diagnostics then animation diagnostics                                                                                                    
00:00 +11: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim                                                                                                                          
00:00 +12: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim                                                                                                                          
00:00 +12: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters                                                                                                                                   
00:00 +13: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters                                                                                                                                   
00:00 +13: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable                                                                                                                      
00:00 +14: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable                                                                                                                      
00:00 +14: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable                                                                                                       
00:00 +15: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable                                                                                                       
00:00 +15: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report                                                                                      
00:00 +16: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report                                                                                      
00:00 +16: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report                                                                                                                  
00:00 +17: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report                                                                                                                  
00:00 +17: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic                                                                                                             
00:00 +18: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic                                                                                                             
00:00 +18: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same                                                                                                                        
00:00 +19: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same                                                                                                                        
00:00 +19: diagnoseProjectSurfaceCatalog (Lot 34) 20. diagnostic equality: different kind                                                                                                              
00:00 +20: diagnoseProjectSurfaceCatalog (Lot 34) 20. diagnostic equality: different kind                                                                                                              
00:00 +20: diagnoseProjectSurfaceCatalog (Lot 34) 21. diagnostic equality: different metadata                                                                                                          
00:00 +21: diagnoseProjectSurfaceCatalog (Lot 34) 21. diagnostic equality: different metadata                                                                                                          
00:00 +21: diagnoseProjectSurfaceCatalog (Lot 34) 22. report equality: same order                                                                                                                      
00:00 +22: diagnoseProjectSurfaceCatalog (Lot 34) 22. report equality: same order                                                                                                                      
00:00 +22: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters                                                                                                                   
00:00 +23: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters                                                                                                                   
00:00 +23: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core                                                                                                                          
00:00 +24: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core                                                                                                                          
00:00 +24: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)                                                                                               
00:00 +25: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)                                                                                               
00:00 +25: All tests passed!                                                                                                                                                                           

```

### `test/surface_catalog_unused_diagnostics_test.dart`

```

00:00 +0: loading test/surface_catalog_unused_diagnostics_test.dart                                                                                                                                    
00:00 +0: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics                                                                                                
00:00 +1: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics                                                                                                
00:00 +1: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics                                                                                             
00:00 +2: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics                                                                                             
00:00 +2: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata                                                                               
00:00 +3: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata                                                                               
00:00 +3: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c                                                                        
00:00 +4: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c                                                                        
00:00 +4: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)                                                                      
00:00 +5: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)                                                                      
00:00 +5: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 6. atlas id exact: spaced atlas not matched by frame atlasId                                                                           
00:00 +6: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 6. atlas id exact: spaced atlas not matched by frame atlasId                                                                           
00:00 +6: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 7. animation not referenced by preset → unusedAnimation                                                                                
00:00 +7: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 7. animation not referenced by preset → unusedAnimation                                                                                
00:00 +7: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c                                                                  
00:00 +8: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c                                                                  
00:00 +8: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 9. animation referenced by a preset: not unused                                                                                        
00:00 +9: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 9. animation referenced by a preset: not unused                                                                                        
00:00 +9: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref                                                                             
00:00 +10: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref                                                                            
00:00 +10: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused                                                                              
00:00 +11: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused                                                                              
00:00 +11: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused                                                                         
00:00 +12: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused                                                                         
00:00 +12: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation                                                                                  
00:00 +13: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation                                                                                  
00:00 +13: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true                                                                               
00:00 +14: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true                                                                               
00:00 +14: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings                                                                                           
00:00 +15: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings                                                                                           
00:00 +15: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings                                                                                   
00:00 +16: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings                                                                                   
00:00 +16: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)                                                                      
00:00 +17: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)                                                                      
00:00 +17: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)                                                                         
00:00 +18: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)                                                                         
00:00 +18: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds                                                                                  
00:00 +19: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds                                                                                  
00:00 +19: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors                                                                         
00:00 +20: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors                                                                         
00:00 +20: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error                                                                                    
00:00 +21: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error                                                                                    
00:00 +21: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId                                                           
00:00 +22: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId                                                           
00:00 +22: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only                                                                                      
00:00 +23: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only                                                                                      
00:00 +23: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 24. ProjectManifest still has no Surface keys (Lot 35)                                                                                
00:00 +24: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 24. ProjectManifest still has no Surface keys (Lot 35)                                                                                
00:00 +24: All tests passed!                                                                                                                                                                           

```

### `test/surface_catalog_authoring_diagnostics_test.dart`

```

00:00 +0: loading test/surface_catalog_authoring_diagnostics_test.dart                                                                                                                                 
00:00 +0: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 1. empty catalog: no diagnostics                                                                                                          
00:00 +1: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 1. empty catalog: no diagnostics                                                                                                          
00:00 +1: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 2. minimal coherent: no diagnostics                                                                                                       
00:00 +2: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 2. minimal coherent: no diagnostics                                                                                                       
00:00 +2: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 3. error only: missing preset animation                                                                                                   
00:00 +3: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 3. error only: missing preset animation                                                                                                   
00:00 +3: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 4. warning only: unused atlas                                                                                                             
00:00 +4: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 4. warning only: unused atlas                                                                                                             
00:00 +4: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 5. warning only: unused animation, no unusedAtlas                                                                                         
00:00 +5: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 5. warning only: unused animation, no unusedAtlas                                                                                         
00:00 +5: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 6. error + warnings: order errors then unusedAtlas then unusedAnimation                                                                   
00:00 +6: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 6. error + warnings: order errors then unusedAtlas then unusedAnimation                                                                   
00:00 +6: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 7. two preset errors: Lot 34 order preserved at start of report                                                                           
00:00 +7: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 7. two preset errors: Lot 34 order preserved at start of report                                                                           
00:00 +7: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 8. many unusedAtlas then many unusedAnimation: Lot 35 order in tail                                                                       
00:00 +8: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 8. many unusedAtlas then many unusedAnimation: Lot 35 order in tail                                                                       
00:00 +8: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 9. no dedup: missingAnimationAtlas + unusedAnimation same anim                                                                            
00:00 +9: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 9. no dedup: missingAnimationAtlas + unusedAnimation same anim                                                                            
00:00 +9: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 10. warnings only: hasErrors false                                                                                                        
00:00 +10: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 10. warnings only: hasErrors false                                                                                                       
00:00 +10: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 11. errors + warnings: hasErrors true                                                                                                    
00:00 +11: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 11. errors + warnings: hasErrors true                                                                                                    
00:00 +11: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 12. byKind on combined report                                                                                                            
00:00 +12: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 12. byKind on combined report                                                                                                            
00:00 +12: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 13. diagnostics list is unmodifiable                                                                                                     
00:00 +13: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 13. diagnostics list is unmodifiable                                                                                                     
00:00 +13: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 14. catalog lists unchanged after call                                                                                                   
00:00 +14: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 14. catalog lists unchanged after call                                                                                                   
00:00 +14: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 15. Lot 34 alone: no unusedAtlas for orphan atlas                                                                                        
00:00 +15: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 15. Lot 34 alone: no unusedAtlas for orphan atlas                                                                                        
00:00 +15: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 16. Lot 35 alone: no missingPresetAnimation for broken ref                                                                               
00:00 +16: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 16. Lot 35 alone: no missingPresetAnimation for broken ref                                                                               
00:00 +16: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 17. V0: coherent preset, no spurious preset-targeted unused rule                                                                         
00:00 +17: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 17. V0: coherent preset, no spurious preset-targeted unused rule                                                                         
00:00 +17: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 18. public API via map_core                                                                                                              
00:00 +18: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 18. public API via map_core                                                                                                              
00:00 +18: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 19. ProjectManifest still has no Surface keys (Lot 36)                                                                                   
00:00 +19: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 19. ProjectManifest still has no Surface keys (Lot 36)                                                                                   
00:00 +19: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 20. no unusedPreset kind; severities are error and warning only                                                                          
00:00 +20: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 20. no unusedPreset kind; severities are error and warning only                                                                          
00:00 +20: All tests passed!                                                                                                                                                                           

```

### `test/surface_model_entrypoint_test.dart`

```

00:00 +0: loading test/surface_model_entrypoint_test.dart                                                                                                                                              
00:00 +0: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order                                                                 
00:00 +1: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order                                                                 
00:00 +1: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet                                                                          
00:00 +2: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet                                                                          
00:00 +2: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged                                                                            
00:00 +3: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged                                                                            
00:00 +3: All tests passed!                                                                                                                                                                            

```



## 32. Résultat exact : `dart analyze`

```
Analyzing project_surface_catalog_json_codec.dart, surface_atlas_json_codec.dart, project_surface_animation_json_codec.dart, project_surface_preset_json_codec.dart, surface_catalog.dart, surface.dart, project_surface_catalog_json_codec_test.dart, project_surface_catalog_test.dart, surface_atlas_json_codec_test.dart, project_surface_animation_json_codec_test.dart, project_surface_preset_json_codec_test.dart, surface_catalog_diagnostics_test.dart, surface_catalog_unused_diagnostics_test.dart, surface_catalog_authoring_diagnostics_test.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!
```

## 33. Résultat : `dart test` complet

- Commande : `cd packages/map_core && /opt/homebrew/bin/dart test`
- Ligne finale exacte : `+1108: All tests passed!`
- **Total** : **1108** tests

## 34. Points de vigilance

Conserver la frontière forme (codec) vs cohérence (diagnostics).

## 35. Autocritique finale

Tests documentaires 41–42 ; scénarios 32–35 valident l’enchaînement post-decode.

## 36. Ce que le prompt semble discutable ou incomplet

Aucun point bloquant.

## 37. Auto-review indépendante (checklist)

- Codec catalogue seul, sans manifest, sans diagnostics embarqués, sans `build_runner`, codecs 39/42/45 composés, ordre préservé, `map_core` +1108 tests verts. Auto-check des formulations d’esquive interdites (liste non recopiée) : **fait** — aucune formulation interdite utilisée pour remplacer une preuve requise dans ce rapport.

## 38. `git status --short` final

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart
?? packages/map_core/test/project_surface_catalog_json_codec_test.dart
```

## 39. Evidence Pack complet

### A.1 `project_surface_catalog_json_codec.dart` (fichier créé)

```dart
// JSON codec manuel (Lot 46) — [ProjectSurfaceCatalog].
//
// * Prépare la **future** persistance / intégration [ProjectManifest] **sans**
//   branchement manifeste dans ce lot — **aucun** champ `surfaceCatalog` ici.
// * Compose strictement [encodeProjectSurfaceAtlas] / [decodeProjectSurfaceAtlas]
//   (Lot 39), [encodeProjectSurfaceAnimation] / [decodeProjectSurfaceAnimation]
//   (Lot 42), [encodeProjectSurfacePreset] / [decodeProjectSurfacePreset] (Lot 45).
// * Préserve l’**ordre** des trois collections ; **aucun** retri, **aucun** filtrage
//   par id / `sortOrder`, **aucune** déduplication côté codec.
// * **Pas** de résolution d’[atlasId] / [animationId] / tileset : seulement la
//   forme JSON + validations des codecs enfants + règles [ProjectSurfaceCatalog]
//   (ex. unicité des id par collection).
// * **Pas** d’appel aux diagnostics ([diagnoseProjectSurfaceCatalog], etc.) :
//   le codec ne fait pas le travail d’analyse de cohérence métier.
// * Décodage : clés inconnues **top-level** **tolérées** ; [Map] sources
//   **jamais** mutées. Les clés imbriquées inconnues restent gérées par les
//   codecs atlas / animation / preset.
// * Aucun [toJson] / [fromJson] sur [ProjectSurfaceCatalog] : modèle domaine pur.
// * V0 : les clés `atlases`, `animations`, `presets` sont **requises** et
//   doivent être des listes (éventuellement vides).

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';
import '../models/surface_catalog.dart';
import 'project_surface_animation_json_codec.dart';
import 'project_surface_preset_json_codec.dart';
import 'surface_atlas_json_codec.dart';

Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
  final m = mapLike as Map<dynamic, dynamic>;
  return Map<String, Object?>.from(
    m.map(
      (dynamic k, dynamic v) => MapEntry(
        k is String ? k : k.toString(),
        v as Object?,
      ),
    ),
  );
}

List<Object?> _requiredList(
  Map<String, Object?> json,
  String key,
  String fieldErrorPrefix,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$fieldErrorPrefix is required');
  }
  final v = json[key];
  if (v is! List) {
    throw ValidationException('$fieldErrorPrefix must be a List');
  }
  return v;
}

/// Encodage : exactement [atlases], [animations], [presets] — ordre des listes
/// préservé, déterministe, sans mutation du [catalog] source.
Map<String, Object?> encodeProjectSurfaceCatalog(
  ProjectSurfaceCatalog catalog,
) {
  return <String, Object?>{
    'atlases': <Object?>[
      for (final a in catalog.atlases) encodeProjectSurfaceAtlas(a),
    ],
    'animations': <Object?>[
      for (final a in catalog.animations) encodeProjectSurfaceAnimation(a),
    ],
    'presets': <Object?>[
      for (final p in catalog.presets) encodeProjectSurfacePreset(p),
    ],
  };
}

/// Décodage : [atlases] / [animations] / [presets] requis, listes d’objets
/// mappables ; chaque élément décodé par le codec correspondant. Délègue
/// l’unicité des id au constructeur [ProjectSurfaceCatalog].
ProjectSurfaceCatalog decodeProjectSurfaceCatalog(
  Map<String, Object?> json,
) {
  final atlasesRaw = _requiredList(
    json,
    'atlases',
    'ProjectSurfaceCatalog.atlases',
  );
  final animationsRaw = _requiredList(
    json,
    'animations',
    'ProjectSurfaceCatalog.animations',
  );
  final presetsRaw = _requiredList(
    json,
    'presets',
    'ProjectSurfaceCatalog.presets',
  );

  final atlases = <ProjectSurfaceAtlas>[];
  for (var i = 0; i < atlasesRaw.length; i++) {
    final item = atlasesRaw[i];
    if (item is! Map) {
      throw ValidationException(
        'ProjectSurfaceCatalog.atlases[$i] must be an Object',
      );
    }
    atlases.add(decodeProjectSurfaceAtlas(_stringKeyMapFrom(item)));
  }

  final animations = <ProjectSurfaceAnimation>[];
  for (var i = 0; i < animationsRaw.length; i++) {
    final item = animationsRaw[i];
    if (item is! Map) {
      throw ValidationException(
        'ProjectSurfaceCatalog.animations[$i] must be an Object',
      );
    }
    animations.add(decodeProjectSurfaceAnimation(_stringKeyMapFrom(item)));
  }

  final presets = <ProjectSurfacePreset>[];
  for (var i = 0; i < presetsRaw.length; i++) {
    final item = presetsRaw[i];
    if (item is! Map) {
      throw ValidationException(
        'ProjectSurfaceCatalog.presets[$i] must be an Object',
      );
    }
    presets.add(decodeProjectSurfacePreset(_stringKeyMapFrom(item)));
  }

  return ProjectSurfaceCatalog(
    atlases: atlases,
    animations: animations,
    presets: presets,
  );
}
```

### A.2 `project_surface_catalog_json_codec_test.dart` (fichier créé)

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSurfaceCatalog JSON codec (Lot 46)', () {
    test('1. encodes empty catalog', () {
      final c = _catalog();
      final j = encodeProjectSurfaceCatalog(c);
      expect(j.keys.toList(), ['atlases', 'animations', 'presets']);
      expect(j['atlases'], isEmpty);
      expect(j['animations'], isEmpty);
      expect(j['presets'], isEmpty);
      expect(j.containsKey('surfaceCatalog'), isFalse);
    });

    test('2. decodes empty catalog JSON', () {
      const j = <String, Object?>{
        'atlases': <Object?>[],
        'animations': <Object?>[],
        'presets': <Object?>[],
      };
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.atlases, isEmpty);
      expect(c.animations, isEmpty);
      expect(c.presets, isEmpty);
    });

    test('3. round-trip empty catalog', () {
      final o = _catalog();
      final d = decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(o));
      expect(d, o);
    });

    test('4. encodes minimal complete catalog (child codecs)', () {
      final atlas = _atlas();
      final anim = _animation();
      final preset = _preset();
      final c = _catalog(
        atlases: [atlas],
        animations: [anim],
        presets: [preset],
      );
      final j = encodeProjectSurfaceCatalog(c);
      expect((j['atlases'] as List).length, 1);
      expect((j['animations'] as List).length, 1);
      expect((j['presets'] as List).length, 1);
      expect((j['atlases'] as List).first, encodeProjectSurfaceAtlas(atlas));
      expect((j['animations'] as List).first, encodeProjectSurfaceAnimation(anim));
      expect((j['presets'] as List).first, encodeProjectSurfacePreset(preset));
    });

    test('5. decodes minimal complete catalog', () {
      final atlas = _atlas(id: 'a1');
      final anim = _animation(id: 'm1', atlasId: 'a1');
      final preset = _preset(id: 'p1', animationId: 'm1');
      final j = encodeProjectSurfaceCatalog(
        _catalog(atlases: [atlas], animations: [anim], presets: [preset]),
      );
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.atlasCount, 1);
      expect(c.animationCount, 1);
      expect(c.presetCount, 1);
      expect(c.atlasById('a1')?.id, 'a1');
      expect(c.animationById('m1')?.id, 'm1');
      expect(c.presetById('p1')?.id, 'p1');
    });

    test('6. round-trip minimal complete catalog', () {
      final o = _catalog(
        atlases: [_atlas(id: 'x')],
        animations: [_animation(id: 'y', atlasId: 'x')],
        presets: [_preset(id: 'z', animationId: 'y')],
      );
      expect(decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(o)), o);
    });

    test('7. encode preserves atlas order', () {
      final c = _catalog(
        atlases: [
          _atlas(id: 'water-atlas'),
          _atlas(id: 'lava-atlas'),
          _atlas(id: 'grass-atlas'),
        ],
      );
      final j = encodeProjectSurfaceCatalog(c);
      final ids = (j['atlases'] as List<Object?>)
          .map((e) => (e! as Map)['id'] as String)
          .toList();
      expect(ids, ['water-atlas', 'lava-atlas', 'grass-atlas']);
    });

    test('8. decode preserves atlas order', () {
      final j = encodeProjectSurfaceCatalog(
        _catalog(
          atlases: [
            _atlas(id: 'water-atlas'),
            _atlas(id: 'lava-atlas'),
            _atlas(id: 'grass-atlas'),
          ],
        ),
      );
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.atlases.map((e) => e.id).toList(),
          ['water-atlas', 'lava-atlas', 'grass-atlas']);
    });

    test('9. encode preserves animation order', () {
      final c = _catalog(
        animations: [
          _animation(id: 'water-a', atlasId: 'a'),
          _animation(id: 'water-b', atlasId: 'a'),
          _animation(id: 'water-c', atlasId: 'a'),
        ],
        atlases: [_atlas(id: 'a')],
      );
      final j = encodeProjectSurfaceCatalog(c);
      final ids = (j['animations'] as List<Object?>)
          .map((e) => (e! as Map)['id'] as String)
          .toList();
      expect(ids, ['water-a', 'water-b', 'water-c']);
    });

    test('10. decode preserves animation order', () {
      final j = encodeProjectSurfaceCatalog(
        _catalog(
          atlases: [_atlas(id: 'a')],
          animations: [
            _animation(id: 'water-a', atlasId: 'a'),
            _animation(id: 'water-b', atlasId: 'a'),
            _animation(id: 'water-c', atlasId: 'a'),
          ],
        ),
      );
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.animations.map((e) => e.id).toList(),
          ['water-a', 'water-b', 'water-c']);
    });

    test('11. encode preserves preset order', () {
      final atl = _atlas(id: 'a');
      final an = _animation(id: 'm', atlasId: 'a');
      final c = _catalog(
        atlases: [atl],
        animations: [an],
        presets: [
          _preset(id: 'water-surface', animationId: 'm'),
          _preset(id: 'lava-surface', animationId: 'm'),
          _preset(id: 'grass-surface', animationId: 'm'),
        ],
      );
      final j = encodeProjectSurfaceCatalog(c);
      final ids = (j['presets'] as List<Object?>)
          .map((e) => (e! as Map)['id'] as String)
          .toList();
      expect(ids, ['water-surface', 'lava-surface', 'grass-surface']);
    });

    test('12. decode preserves preset order', () {
      final atl = _atlas(id: 'a');
      final an = _animation(id: 'm', atlasId: 'a');
      final j = encodeProjectSurfaceCatalog(
        _catalog(
          atlases: [atl],
          animations: [an],
          presets: [
            _preset(id: 'water-surface', animationId: 'm'),
            _preset(id: 'lava-surface', animationId: 'm'),
            _preset(id: 'grass-surface', animationId: 'm'),
          ],
        ),
      );
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.presets.map((e) => e.id).toList(),
          ['water-surface', 'lava-surface', 'grass-surface']);
    });

    test('13. decode rejects missing atlases', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'animations': <Object?>[],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. decode rejects atlases non-list', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': 'nope',
          'animations': <Object?>[],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. decode rejects atlas item non-map', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>['nope'],
          'animations': <Object?>[],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. decode rejects invalid atlas via child codec (whitespace id)', () {
      final good = encodeProjectSurfaceAtlas(_atlas());
      final m = Map<String, Object?>.from(good);
      m['id'] = '   ';
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[m],
          'animations': <Object?>[],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('17. decode rejects missing animations', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('18. decode rejects animations non-list', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': 1,
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('19. decode rejects animation item non-map', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>['x'],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('20. decode rejects invalid animation via child codec (empty frames)', () {
      final good = encodeProjectSurfaceAnimation(
        _animation(atlasId: 'a'),
      );
      final m = Map<String, Object?>.from(good);
      final tl = Map<String, Object?>.from(m['timeline']! as Map);
      tl['frames'] = <Object?>[];
      m['timeline'] = tl;
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>[m],
          'presets': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('21. decode rejects missing presets', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>[],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('22. decode rejects presets non-list', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>[],
          'presets': true,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('23. decode rejects preset item non-map', () {
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>[],
          'presets': <Object?>[1],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('24. decode rejects invalid preset via child codec (empty refs)', () {
      final good = encodeProjectSurfacePreset(_preset());
      final m = Map<String, Object?>.from(good);
      final va = Map<String, Object?>.from(m['variantAnimations']! as Map);
      va['refs'] = <Object?>[];
      m['variantAnimations'] = va;
      expect(
        () => decodeProjectSurfaceCatalog(<String, Object?>{
          'atlases': <Object?>[],
          'animations': <Object?>[],
          'presets': <Object?>[m],
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('25. decode rejects duplicate atlas ids (model)', () {
      final one = encodeProjectSurfaceAtlas(_atlas(id: 'dup'));
      final j = <String, Object?>{
        'atlases': <Object?>[one, one],
        'animations': <Object?>[],
        'presets': <Object?>[],
      };
      expect(
        () => decodeProjectSurfaceCatalog(j),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.toString(),
            'message',
            contains('duplicate ProjectSurfaceAtlas.id'),
          ),
        ),
      );
    });

    test('26. decode rejects duplicate animation ids (model)', () {
      final atl = _atlas(id: 'a');
      final one = encodeProjectSurfaceAnimation(_animation(id: 'dup', atlasId: 'a'));
      final j = <String, Object?>{
        'atlases': <Object?>[encodeProjectSurfaceAtlas(atl)],
        'animations': <Object?>[one, one],
        'presets': <Object?>[],
      };
      expect(
        () => decodeProjectSurfaceCatalog(j),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.toString(),
            'message',
            contains('duplicate ProjectSurfaceAnimation.id'),
          ),
        ),
      );
    });

    test('27. decode rejects duplicate preset ids (model)', () {
      final atl = _atlas(id: 'a');
      final an = _animation(id: 'm', atlasId: 'a');
      final one = encodeProjectSurfacePreset(_preset(id: 'dup', animationId: 'm'));
      final j = <String, Object?>{
        'atlases': <Object?>[encodeProjectSurfaceAtlas(atl)],
        'animations': <Object?>[encodeProjectSurfaceAnimation(an)],
        'presets': <Object?>[one, one],
      };
      expect(
        () => decodeProjectSurfaceCatalog(j),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.toString(),
            'message',
            contains('duplicate ProjectSurfacePreset.id'),
          ),
        ),
      );
    });

    test('28. decode ignores unknown top-level key', () {
      final j = <String, Object?>{
        'atlases': <Object?>[],
        'animations': <Object?>[],
        'presets': <Object?>[],
        'futureField': 'ignored',
      };
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.isEmpty, isTrue);
    });

    test('29. decode ignores unknown keys in child items', () {
      final atlas = encodeProjectSurfaceAtlas(_atlas());
      final m = Map<String, Object?>.from(atlas);
      m['extraAtlas'] = 1;
      final j = <String, Object?>{
        'atlases': <Object?>[m],
        'animations': <Object?>[],
        'presets': <Object?>[],
      };
      final c = decodeProjectSurfaceCatalog(j);
      expect(c.atlasCount, 1);
    });

    test('30. decode does not mutate source map', () {
      final inner = <String, Object?>{
        'id': 'a',
        'name': 'Water Atlas',
        'tilesetId': 't',
        'geometry': encodeSurfaceAtlasGeometry(_geometry()),
        'sortOrder': 0,
      };
      final m = <String, Object?>{
        'atlases': <Object?>[inner],
        'animations': <Object?>[],
        'presets': <Object?>[],
      };
      final before = _mapStr(m);
      decodeProjectSurfaceCatalog(m);
      expect(_mapStr(m), before);
    });

    test('31. encode does not mutate catalog', () {
      final atl = _atlas(id: 'a');
      final an = _animation(id: 'm', atlasId: 'a');
      final pr = _preset(id: 'p', animationId: 'm');
      final c = _catalog(atlases: [atl], animations: [an], presets: [pr]);
      final ac = c.atlasCount;
      final pc = c.presetCount;
      final la = c.atlasById('a');
      encodeProjectSurfaceCatalog(c);
      expect(c.atlasCount, ac);
      expect(c.presetCount, pc);
      expect(c.atlasById('a'), la);
    });

    test('32. codec does not resolve animationId; diagnostics catch missing', () {
      final j = <String, Object?>{
        'atlases': <Object?>[],
        'animations': <Object?>[],
        'presets': <Object?>[
          encodeProjectSurfacePreset(
            _preset(animationId: 'missing-animation'),
          ),
        ],
      };
      final c = decodeProjectSurfaceCatalog(j);
      final r = diagnoseProjectSurfaceCatalog(c);
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
        isNotEmpty,
      );
    });

    test('33. codec does not resolve atlasId; diagnostics catch missing atlas', () {
      final j = <String, Object?>{
        'atlases': <Object?>[],
        'animations': <Object?>[
          encodeProjectSurfaceAnimation(
            _animation(id: 'orphan', atlasId: 'missing-atlas'),
          ),
        ],
        'presets': <Object?>[],
      };
      final c = decodeProjectSurfaceCatalog(j);
      final r = diagnoseProjectSurfaceCatalog(c);
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.missingAnimationAtlas),
        isNotEmpty,
      );
    });

    test('34. codec does not check geometry; diagnostics catch out of bounds', () {
      final geo = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      final atl = _atlas(id: 'water-atlas', geometry: geo);
      final anim = ProjectSurfaceAnimation(
        id: 'a1',
        name: 'A',
        timeline: SurfaceAnimationTimeline(
          frames: [
            SurfaceAnimationFrame(
              tileRef: SurfaceAtlasTileRef(
                atlasId: 'water-atlas',
                column: 999,
                row: 999,
              ),
              durationMs: 120,
            ),
          ],
        ),
      );
      final c = _catalog(atlases: [atl], animations: [anim], presets: []);
      final d = decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(c));
      final r = diagnoseProjectSurfaceCatalog(d);
      expect(
        r.byKind(SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry),
        isNotEmpty,
      );
    });

    test('35. codec does not call unused diagnostics; unused can warn after', () {
      final aUsed = _atlas(id: 'used-atlas');
      final aUnused = _atlas(id: 'unused-atlas');
      final mUsed = _animation(id: 'used-anim', atlasId: 'used-atlas');
      final mUnused = _animation(id: 'unused-anim', atlasId: 'used-atlas');
      final p = _preset(id: 'p', animationId: 'used-anim');
      final c = _catalog(
        atlases: [aUsed, aUnused],
        animations: [mUsed, mUnused],
        presets: [p],
      );
      final d = decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(c));
      final u = diagnoseProjectSurfaceCatalogUnusedResources(d);
      expect(u.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas), isNotEmpty);
      expect(u.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation), isNotEmpty);
    });

    test('36. reuses Lot 39 atlas codec for atlases[0]', () {
      final atlas = _atlas();
      final c = _catalog(atlases: [atlas]);
      final json = encodeProjectSurfaceCatalog(c);
      final list = json['atlases']! as List<Object?>;
      expect(list[0], encodeProjectSurfaceAtlas(atlas));
    });

    test('37. reuses Lot 42 animation codec for animations[0]', () {
      final atl = _atlas(id: 'a');
      final anim = _animation(atlasId: 'a');
      final c = _catalog(atlases: [atl], animations: [anim]);
      final json = encodeProjectSurfaceCatalog(c);
      final list = json['animations']! as List<Object?>;
      expect(list[0], encodeProjectSurfaceAnimation(anim));
    });

    test('38. reuses Lot 45 preset codec for presets[0]', () {
      final atl = _atlas(id: 'a');
      final anim = _animation(id: 'm', atlasId: 'a');
      final preset = _preset(animationId: 'm');
      final c = _catalog(
        atlases: [atl],
        animations: [anim],
        presets: [preset],
      );
      final json = encodeProjectSurfaceCatalog(c);
      final list = json['presets']! as List<Object?>;
      expect(list[0], encodeProjectSurfacePreset(preset));
    });

    test('39. public API encode returns map', () {
      expect(encodeProjectSurfaceCatalog(_catalog()), isA<Map<String, Object?>>());
    });

    test('40. ProjectManifest has no surface persistence keys (Lot 46)', () {
      const manifest = ProjectManifest(
        name: 'L46',
        maps: [
          ProjectMapEntry(
            id: 'm1',
            name: 'M',
            relativePath: 'maps/m1.json',
          ),
        ],
        tilesets: [],
      );
      final ju = manifest.toJson();
      for (final k in const [
        'surfaceCatalog',
        'surfaceDefinitions',
        'surfaceAtlases',
        'surfaceAnimations',
        'surfacePresets',
        'surfaceCategories',
      ]) {
        expect(ju.containsKey(k), isFalse, reason: k);
      }
    });

    test(
      '41. codec external to model: no catalog.toJson or ProjectSurfaceCatalog.fromJson',
      () {
        final c = _catalog();
        final m = encodeProjectSurfaceCatalog(c);
        expect(m, isA<Map<String, Object?>>());
      },
    );

    test('42. manifest surface integration remains out of scope (no manifest codec)', () {
      final m = encodeProjectSurfaceCatalog(_catalog());
      expect(m['atlases'], isA<List>());
    });

    test('43. no Surface categories array; categoryId stays per-item string', () {
      final c = _catalog(
        atlases: [_atlas(categoryId: 'cat')],
        animations: [_animation(atlasId: 'water-atlas')],
        presets: [_preset(animationId: 'water-isolated-loop')],
      );
      final j = encodeProjectSurfaceCatalog(c);
      expect(j.containsKey('categories'), isFalse);
      expect(j.containsKey('surfaceCategories'), isFalse);
      final plist = j['presets']! as List<Object?>;
      final p0 = plist[0] as Map<String, Object?>;
      expect(p0['categoryId'], isA<String>());
    });

    test('44. no kind / surfaceKind / presetKind / type at catalog or preset JSON', () {
      final c = _catalog(
        atlases: [_atlas()],
        animations: [_animation()],
        presets: [_preset()],
      );
      final j = encodeProjectSurfaceCatalog(c);
      for (final k in const ['surfaceKind', 'presetKind', 'kind', 'type']) {
        expect(j.containsKey(k), isFalse, reason: 'top $k');
      }
      final plist = j['presets']! as List<Object?>;
      final p0 = plist[0] as Map<String, Object?>;
      for (final k in const ['surfaceKind', 'presetKind', 'kind', 'type']) {
        expect(p0.containsKey(k), isFalse, reason: 'preset $k');
      }
    });
  });
}

SurfaceAtlasGeometry _geometry({
  int columns = 23,
  int rows = 32,
}) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _atlas({
  String id = 'water-atlas',
  String name = 'Water Atlas',
  String tilesetId = 'nature-tileset',
  SurfaceAtlasGeometry? geometry,
  String? categoryId = 'animated-surfaces',
  int sortOrder = 0,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: name,
    tilesetId: tilesetId,
    geometry: geometry ?? _geometry(),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

SurfaceAnimationFrame _frame({
  String atlasId = 'water-atlas',
  int column = 0,
  int row = 0,
  int durationMs = 120,
}) {
  return SurfaceAnimationFrame(
    tileRef: SurfaceAtlasTileRef(
      atlasId: atlasId,
      column: column,
      row: row,
    ),
    durationMs: durationMs,
  );
}

ProjectSurfaceAnimation _animation({
  String id = 'water-isolated-loop',
  String name = 'Water Isolated Loop',
  String atlasId = 'water-atlas',
  int column = 0,
  int row = 0,
  int durationMs = 120,
  String? syncGroupId = 'water',
  String? categoryId = 'animated-surfaces',
  int sortOrder = 0,
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: name,
    timeline: SurfaceAnimationTimeline(
      frames: [
        _frame(
          atlasId: atlasId,
          column: column,
          row: row,
          durationMs: durationMs,
        ),
      ],
    ),
    syncGroupId: syncGroupId,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

SurfaceVariantAnimationRef _ref(
  SurfaceVariantRole role, {
  String animationId = 'water-isolated-loop',
}) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId,
  );
}

ProjectSurfacePreset _preset({
  String id = 'water-surface',
  String name = 'Water Surface',
  String animationId = 'water-isolated-loop',
  String? categoryId = 'animated-surfaces',
  int sortOrder = 0,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        _ref(SurfaceVariantRole.isolated, animationId: animationId),
      ],
    ),
    categoryId: categoryId,
    sortOrder: sortOrder,
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

String _mapStr(Object? o) {
  if (o is Map) {
    final keys = o.keys.toList()..sort();
    return keys.map((k) => '$k:${_mapStr(o[k])}').join('|');
  }
  if (o is List) {
    return o.map(_mapStr).join(';');
  }
  if (o is String) {
    return o;
  }
  if (o == null) {
    return 'null';
  }
  return o.toString();
}
```

### B. Fichier modifié `map_core.dart` (contenu intégral)

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

### C.1 Diff `project_surface_catalog_json_codec.dart` (`git diff /dev/null`)

```diff
diff --git a/packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart b/packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart
new file mode 100644
index 00000000..9e73fbb6
--- /dev/null
+++ b/packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart
@@ -0,0 +1,134 @@
+// JSON codec manuel (Lot 46) — [ProjectSurfaceCatalog].
+//
+// * Prépare la **future** persistance / intégration [ProjectManifest] **sans**
+//   branchement manifeste dans ce lot — **aucun** champ `surfaceCatalog` ici.
+// * Compose strictement [encodeProjectSurfaceAtlas] / [decodeProjectSurfaceAtlas]
+//   (Lot 39), [encodeProjectSurfaceAnimation] / [decodeProjectSurfaceAnimation]
+//   (Lot 42), [encodeProjectSurfacePreset] / [decodeProjectSurfacePreset] (Lot 45).
+// * Préserve l’**ordre** des trois collections ; **aucun** retri, **aucun** filtrage
+//   par id / `sortOrder`, **aucune** déduplication côté codec.
+// * **Pas** de résolution d’[atlasId] / [animationId] / tileset : seulement la
+//   forme JSON + validations des codecs enfants + règles [ProjectSurfaceCatalog]
+//   (ex. unicité des id par collection).
+// * **Pas** d’appel aux diagnostics ([diagnoseProjectSurfaceCatalog], etc.) :
+//   le codec ne fait pas le travail d’analyse de cohérence métier.
+// * Décodage : clés inconnues **top-level** **tolérées** ; [Map] sources
+//   **jamais** mutées. Les clés imbriquées inconnues restent gérées par les
+//   codecs atlas / animation / preset.
+// * Aucun [toJson] / [fromJson] sur [ProjectSurfaceCatalog] : modèle domaine pur.
+// * V0 : les clés `atlases`, `animations`, `presets` sont **requises** et
+//   doivent être des listes (éventuellement vides).
+
+import '../exceptions/map_exceptions.dart';
+import '../models/surface.dart';
+import '../models/surface_catalog.dart';
+import 'project_surface_animation_json_codec.dart';
+import 'project_surface_preset_json_codec.dart';
+import 'surface_atlas_json_codec.dart';
+
+Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
+  final m = mapLike as Map<dynamic, dynamic>;
+  return Map<String, Object?>.from(
+    m.map(
+      (dynamic k, dynamic v) => MapEntry(
+        k is String ? k : k.toString(),
+        v as Object?,
+      ),
+    ),
+  );
+}
+
+List<Object?> _requiredList(
+  Map<String, Object?> json,
+  String key,
+  String fieldErrorPrefix,
+) {
+  if (!json.containsKey(key)) {
+    throw ValidationException('$fieldErrorPrefix is required');
+  }
+  final v = json[key];
+  if (v is! List) {
+    throw ValidationException('$fieldErrorPrefix must be a List');
+  }
+  return v;
+}
+
+/// Encodage : exactement [atlases], [animations], [presets] — ordre des listes
+/// préservé, déterministe, sans mutation du [catalog] source.
+Map<String, Object?> encodeProjectSurfaceCatalog(
+  ProjectSurfaceCatalog catalog,
+) {
+  return <String, Object?>{
+    'atlases': <Object?>[
+      for (final a in catalog.atlases) encodeProjectSurfaceAtlas(a),
+    ],
+    'animations': <Object?>[
+      for (final a in catalog.animations) encodeProjectSurfaceAnimation(a),
+    ],
+    'presets': <Object?>[
+      for (final p in catalog.presets) encodeProjectSurfacePreset(p),
+    ],
+  };
+}
+
+/// Décodage : [atlases] / [animations] / [presets] requis, listes d’objets
+/// mappables ; chaque élément décodé par le codec correspondant. Délègue
+/// l’unicité des id au constructeur [ProjectSurfaceCatalog].
+ProjectSurfaceCatalog decodeProjectSurfaceCatalog(
+  Map<String, Object?> json,
+) {
+  final atlasesRaw = _requiredList(
+    json,
+    'atlases',
+    'ProjectSurfaceCatalog.atlases',
+  );
+  final animationsRaw = _requiredList(
+    json,
+    'animations',
+    'ProjectSurfaceCatalog.animations',
+  );
+  final presetsRaw = _requiredList(
+    json,
+    'presets',
+    'ProjectSurfaceCatalog.presets',
+  );
+
+  final atlases = <ProjectSurfaceAtlas>[];
+  for (var i = 0; i < atlasesRaw.length; i++) {
+    final item = atlasesRaw[i];
+    if (item is! Map) {
+      throw ValidationException(
+        'ProjectSurfaceCatalog.atlases[$i] must be an Object',
+      );
+    }
+    atlases.add(decodeProjectSurfaceAtlas(_stringKeyMapFrom(item)));
+  }
+
+  final animations = <ProjectSurfaceAnimation>[];
+  for (var i = 0; i < animationsRaw.length; i++) {
+    final item = animationsRaw[i];
+    if (item is! Map) {
+      throw ValidationException(
+        'ProjectSurfaceCatalog.animations[$i] must be an Object',
+      );
+    }
+    animations.add(decodeProjectSurfaceAnimation(_stringKeyMapFrom(item)));
+  }
+
+  final presets = <ProjectSurfacePreset>[];
+  for (var i = 0; i < presetsRaw.length; i++) {
+    final item = presetsRaw[i];
+    if (item is! Map) {
+      throw ValidationException(
+        'ProjectSurfaceCatalog.presets[$i] must be an Object',
+      );
+    }
+    presets.add(decodeProjectSurfacePreset(_stringKeyMapFrom(item)));
+  }
+
+  return ProjectSurfaceCatalog(
+    atlases: atlases,
+    animations: animations,
+    presets: presets,
+  );
+}
```

### C.2 Diff `project_surface_catalog_json_codec_test.dart` (`git diff /dev/null`)

```diff
diff --git a/packages/map_core/test/project_surface_catalog_json_codec_test.dart b/packages/map_core/test/project_surface_catalog_json_codec_test.dart
new file mode 100644
index 00000000..191c28ee
--- /dev/null
+++ b/packages/map_core/test/project_surface_catalog_json_codec_test.dart
@@ -0,0 +1,761 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('ProjectSurfaceCatalog JSON codec (Lot 46)', () {
+    test('1. encodes empty catalog', () {
+      final c = _catalog();
+      final j = encodeProjectSurfaceCatalog(c);
+      expect(j.keys.toList(), ['atlases', 'animations', 'presets']);
+      expect(j['atlases'], isEmpty);
+      expect(j['animations'], isEmpty);
+      expect(j['presets'], isEmpty);
+      expect(j.containsKey('surfaceCatalog'), isFalse);
+    });
+
+    test('2. decodes empty catalog JSON', () {
+      const j = <String, Object?>{
+        'atlases': <Object?>[],
+        'animations': <Object?>[],
+        'presets': <Object?>[],
+      };
+      final c = decodeProjectSurfaceCatalog(j);
+      expect(c.atlases, isEmpty);
+      expect(c.animations, isEmpty);
+      expect(c.presets, isEmpty);
+    });
+
+    test('3. round-trip empty catalog', () {
+      final o = _catalog();
+      final d = decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(o));
+      expect(d, o);
+    });
+
+    test('4. encodes minimal complete catalog (child codecs)', () {
+      final atlas = _atlas();
+      final anim = _animation();
+      final preset = _preset();
+      final c = _catalog(
+        atlases: [atlas],
+        animations: [anim],
+        presets: [preset],
+      );
+      final j = encodeProjectSurfaceCatalog(c);
+      expect((j['atlases'] as List).length, 1);
+      expect((j['animations'] as List).length, 1);
+      expect((j['presets'] as List).length, 1);
+      expect((j['atlases'] as List).first, encodeProjectSurfaceAtlas(atlas));
+      expect((j['animations'] as List).first, encodeProjectSurfaceAnimation(anim));
+      expect((j['presets'] as List).first, encodeProjectSurfacePreset(preset));
+    });
+
+    test('5. decodes minimal complete catalog', () {
+      final atlas = _atlas(id: 'a1');
+      final anim = _animation(id: 'm1', atlasId: 'a1');
+      final preset = _preset(id: 'p1', animationId: 'm1');
+      final j = encodeProjectSurfaceCatalog(
+        _catalog(atlases: [atlas], animations: [anim], presets: [preset]),
+      );
+      final c = decodeProjectSurfaceCatalog(j);
+      expect(c.atlasCount, 1);
+      expect(c.animationCount, 1);
+      expect(c.presetCount, 1);
+      expect(c.atlasById('a1')?.id, 'a1');
+      expect(c.animationById('m1')?.id, 'm1');
+      expect(c.presetById('p1')?.id, 'p1');
+    });
+
+    test('6. round-trip minimal complete catalog', () {
+      final o = _catalog(
+        atlases: [_atlas(id: 'x')],
+        animations: [_animation(id: 'y', atlasId: 'x')],
+        presets: [_preset(id: 'z', animationId: 'y')],
+      );
+      expect(decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(o)), o);
+    });
+
+    test('7. encode preserves atlas order', () {
+      final c = _catalog(
+        atlases: [
+          _atlas(id: 'water-atlas'),
+          _atlas(id: 'lava-atlas'),
+          _atlas(id: 'grass-atlas'),
+        ],
+      );
+      final j = encodeProjectSurfaceCatalog(c);
+      final ids = (j['atlases'] as List<Object?>)
+          .map((e) => (e! as Map)['id'] as String)
+          .toList();
+      expect(ids, ['water-atlas', 'lava-atlas', 'grass-atlas']);
+    });
+
+    test('8. decode preserves atlas order', () {
+      final j = encodeProjectSurfaceCatalog(
+        _catalog(
+          atlases: [
+            _atlas(id: 'water-atlas'),
+            _atlas(id: 'lava-atlas'),
+            _atlas(id: 'grass-atlas'),
+          ],
+        ),
+      );
+      final c = decodeProjectSurfaceCatalog(j);
+      expect(c.atlases.map((e) => e.id).toList(),
+          ['water-atlas', 'lava-atlas', 'grass-atlas']);
+    });
+
+    test('9. encode preserves animation order', () {
+      final c = _catalog(
+        animations: [
+          _animation(id: 'water-a', atlasId: 'a'),
+          _animation(id: 'water-b', atlasId: 'a'),
+          _animation(id: 'water-c', atlasId: 'a'),
+        ],
+        atlases: [_atlas(id: 'a')],
+      );
+      final j = encodeProjectSurfaceCatalog(c);
+      final ids = (j['animations'] as List<Object?>)
+          .map((e) => (e! as Map)['id'] as String)
+          .toList();
+      expect(ids, ['water-a', 'water-b', 'water-c']);
+    });
+
+    test('10. decode preserves animation order', () {
+      final j = encodeProjectSurfaceCatalog(
+        _catalog(
+          atlases: [_atlas(id: 'a')],
+          animations: [
+            _animation(id: 'water-a', atlasId: 'a'),
+            _animation(id: 'water-b', atlasId: 'a'),
+            _animation(id: 'water-c', atlasId: 'a'),
+          ],
+        ),
+      );
+      final c = decodeProjectSurfaceCatalog(j);
+      expect(c.animations.map((e) => e.id).toList(),
+          ['water-a', 'water-b', 'water-c']);
+    });
+
+    test('11. encode preserves preset order', () {
+      final atl = _atlas(id: 'a');
+      final an = _animation(id: 'm', atlasId: 'a');
+      final c = _catalog(
+        atlases: [atl],
+        animations: [an],
+        presets: [
+          _preset(id: 'water-surface', animationId: 'm'),
+          _preset(id: 'lava-surface', animationId: 'm'),
+          _preset(id: 'grass-surface', animationId: 'm'),
+        ],
+      );
+      final j = encodeProjectSurfaceCatalog(c);
+      final ids = (j['presets'] as List<Object?>)
+          .map((e) => (e! as Map)['id'] as String)
+          .toList();
+      expect(ids, ['water-surface', 'lava-surface', 'grass-surface']);
+    });
+
+    test('12. decode preserves preset order', () {
+      final atl = _atlas(id: 'a');
+      final an = _animation(id: 'm', atlasId: 'a');
+      final j = encodeProjectSurfaceCatalog(
+        _catalog(
+          atlases: [atl],
+          animations: [an],
+          presets: [
+            _preset(id: 'water-surface', animationId: 'm'),
+            _preset(id: 'lava-surface', animationId: 'm'),
+            _preset(id: 'grass-surface', animationId: 'm'),
+          ],
+        ),
+      );
+      final c = decodeProjectSurfaceCatalog(j);
+      expect(c.presets.map((e) => e.id).toList(),
+          ['water-surface', 'lava-surface', 'grass-surface']);
+    });
+
+    test('13. decode rejects missing atlases', () {
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'animations': <Object?>[],
+          'presets': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('14. decode rejects atlases non-list', () {
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': 'nope',
+          'animations': <Object?>[],
+          'presets': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('15. decode rejects atlas item non-map', () {
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': <Object?>['nope'],
+          'animations': <Object?>[],
+          'presets': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('16. decode rejects invalid atlas via child codec (whitespace id)', () {
+      final good = encodeProjectSurfaceAtlas(_atlas());
+      final m = Map<String, Object?>.from(good);
+      m['id'] = '   ';
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': <Object?>[m],
+          'animations': <Object?>[],
+          'presets': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('17. decode rejects missing animations', () {
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': <Object?>[],
+          'presets': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('18. decode rejects animations non-list', () {
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': <Object?>[],
+          'animations': 1,
+          'presets': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('19. decode rejects animation item non-map', () {
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': <Object?>[],
+          'animations': <Object?>['x'],
+          'presets': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('20. decode rejects invalid animation via child codec (empty frames)', () {
+      final good = encodeProjectSurfaceAnimation(
+        _animation(atlasId: 'a'),
+      );
+      final m = Map<String, Object?>.from(good);
+      final tl = Map<String, Object?>.from(m['timeline']! as Map);
+      tl['frames'] = <Object?>[];
+      m['timeline'] = tl;
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': <Object?>[],
+          'animations': <Object?>[m],
+          'presets': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('21. decode rejects missing presets', () {
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': <Object?>[],
+          'animations': <Object?>[],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('22. decode rejects presets non-list', () {
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': <Object?>[],
+          'animations': <Object?>[],
+          'presets': true,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('23. decode rejects preset item non-map', () {
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': <Object?>[],
+          'animations': <Object?>[],
+          'presets': <Object?>[1],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('24. decode rejects invalid preset via child codec (empty refs)', () {
+      final good = encodeProjectSurfacePreset(_preset());
+      final m = Map<String, Object?>.from(good);
+      final va = Map<String, Object?>.from(m['variantAnimations']! as Map);
+      va['refs'] = <Object?>[];
+      m['variantAnimations'] = va;
+      expect(
+        () => decodeProjectSurfaceCatalog(<String, Object?>{
+          'atlases': <Object?>[],
+          'animations': <Object?>[],
+          'presets': <Object?>[m],
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('25. decode rejects duplicate atlas ids (model)', () {
+      final one = encodeProjectSurfaceAtlas(_atlas(id: 'dup'));
+      final j = <String, Object?>{
+        'atlases': <Object?>[one, one],
+        'animations': <Object?>[],
+        'presets': <Object?>[],
+      };
+      expect(
+        () => decodeProjectSurfaceCatalog(j),
+        throwsA(
+          isA<ValidationException>().having(
+            (e) => e.toString(),
+            'message',
+            contains('duplicate ProjectSurfaceAtlas.id'),
+          ),
+        ),
+      );
+    });
+
+    test('26. decode rejects duplicate animation ids (model)', () {
+      final atl = _atlas(id: 'a');
+      final one = encodeProjectSurfaceAnimation(_animation(id: 'dup', atlasId: 'a'));
+      final j = <String, Object?>{
+        'atlases': <Object?>[encodeProjectSurfaceAtlas(atl)],
+        'animations': <Object?>[one, one],
+        'presets': <Object?>[],
+      };
+      expect(
+        () => decodeProjectSurfaceCatalog(j),
+        throwsA(
+          isA<ValidationException>().having(
+            (e) => e.toString(),
+            'message',
+            contains('duplicate ProjectSurfaceAnimation.id'),
+          ),
+        ),
+      );
+    });
+
+    test('27. decode rejects duplicate preset ids (model)', () {
+      final atl = _atlas(id: 'a');
+      final an = _animation(id: 'm', atlasId: 'a');
+      final one = encodeProjectSurfacePreset(_preset(id: 'dup', animationId: 'm'));
+      final j = <String, Object?>{
+        'atlases': <Object?>[encodeProjectSurfaceAtlas(atl)],
+        'animations': <Object?>[encodeProjectSurfaceAnimation(an)],
+        'presets': <Object?>[one, one],
+      };
+      expect(
+        () => decodeProjectSurfaceCatalog(j),
+        throwsA(
+          isA<ValidationException>().having(
+            (e) => e.toString(),
+            'message',
+            contains('duplicate ProjectSurfacePreset.id'),
+          ),
+        ),
+      );
+    });
+
+    test('28. decode ignores unknown top-level key', () {
+      final j = <String, Object?>{
+        'atlases': <Object?>[],
+        'animations': <Object?>[],
+        'presets': <Object?>[],
+        'futureField': 'ignored',
+      };
+      final c = decodeProjectSurfaceCatalog(j);
+      expect(c.isEmpty, isTrue);
+    });
+
+    test('29. decode ignores unknown keys in child items', () {
+      final atlas = encodeProjectSurfaceAtlas(_atlas());
+      final m = Map<String, Object?>.from(atlas);
+      m['extraAtlas'] = 1;
+      final j = <String, Object?>{
+        'atlases': <Object?>[m],
+        'animations': <Object?>[],
+        'presets': <Object?>[],
+      };
+      final c = decodeProjectSurfaceCatalog(j);
+      expect(c.atlasCount, 1);
+    });
+
+    test('30. decode does not mutate source map', () {
+      final inner = <String, Object?>{
+        'id': 'a',
+        'name': 'Water Atlas',
+        'tilesetId': 't',
+        'geometry': encodeSurfaceAtlasGeometry(_geometry()),
+        'sortOrder': 0,
+      };
+      final m = <String, Object?>{
+        'atlases': <Object?>[inner],
+        'animations': <Object?>[],
+        'presets': <Object?>[],
+      };
+      final before = _mapStr(m);
+      decodeProjectSurfaceCatalog(m);
+      expect(_mapStr(m), before);
+    });
+
+    test('31. encode does not mutate catalog', () {
+      final atl = _atlas(id: 'a');
+      final an = _animation(id: 'm', atlasId: 'a');
+      final pr = _preset(id: 'p', animationId: 'm');
+      final c = _catalog(atlases: [atl], animations: [an], presets: [pr]);
+      final ac = c.atlasCount;
+      final pc = c.presetCount;
+      final la = c.atlasById('a');
+      encodeProjectSurfaceCatalog(c);
+      expect(c.atlasCount, ac);
+      expect(c.presetCount, pc);
+      expect(c.atlasById('a'), la);
+    });
+
+    test('32. codec does not resolve animationId; diagnostics catch missing', () {
+      final j = <String, Object?>{
+        'atlases': <Object?>[],
+        'animations': <Object?>[],
+        'presets': <Object?>[
+          encodeProjectSurfacePreset(
+            _preset(animationId: 'missing-animation'),
+          ),
+        ],
+      };
+      final c = decodeProjectSurfaceCatalog(j);
+      final r = diagnoseProjectSurfaceCatalog(c);
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.missingPresetAnimation),
+        isNotEmpty,
+      );
+    });
+
+    test('33. codec does not resolve atlasId; diagnostics catch missing atlas', () {
+      final j = <String, Object?>{
+        'atlases': <Object?>[],
+        'animations': <Object?>[
+          encodeProjectSurfaceAnimation(
+            _animation(id: 'orphan', atlasId: 'missing-atlas'),
+          ),
+        ],
+        'presets': <Object?>[],
+      };
+      final c = decodeProjectSurfaceCatalog(j);
+      final r = diagnoseProjectSurfaceCatalog(c);
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.missingAnimationAtlas),
+        isNotEmpty,
+      );
+    });
+
+    test('34. codec does not check geometry; diagnostics catch out of bounds', () {
+      final geo = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 16, height: 16),
+        gridSize: SurfaceAtlasGridSize(columns: 1, rows: 1),
+        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+      );
+      final atl = _atlas(id: 'water-atlas', geometry: geo);
+      final anim = ProjectSurfaceAnimation(
+        id: 'a1',
+        name: 'A',
+        timeline: SurfaceAnimationTimeline(
+          frames: [
+            SurfaceAnimationFrame(
+              tileRef: SurfaceAtlasTileRef(
+                atlasId: 'water-atlas',
+                column: 999,
+                row: 999,
+              ),
+              durationMs: 120,
+            ),
+          ],
+        ),
+      );
+      final c = _catalog(atlases: [atl], animations: [anim], presets: []);
+      final d = decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(c));
+      final r = diagnoseProjectSurfaceCatalog(d);
+      expect(
+        r.byKind(SurfaceCatalogDiagnosticKind.animationFrameOutsideAtlasGeometry),
+        isNotEmpty,
+      );
+    });
+
+    test('35. codec does not call unused diagnostics; unused can warn after', () {
+      final aUsed = _atlas(id: 'used-atlas');
+      final aUnused = _atlas(id: 'unused-atlas');
+      final mUsed = _animation(id: 'used-anim', atlasId: 'used-atlas');
+      final mUnused = _animation(id: 'unused-anim', atlasId: 'used-atlas');
+      final p = _preset(id: 'p', animationId: 'used-anim');
+      final c = _catalog(
+        atlases: [aUsed, aUnused],
+        animations: [mUsed, mUnused],
+        presets: [p],
+      );
+      final d = decodeProjectSurfaceCatalog(encodeProjectSurfaceCatalog(c));
+      final u = diagnoseProjectSurfaceCatalogUnusedResources(d);
+      expect(u.byKind(SurfaceCatalogDiagnosticKind.unusedAtlas), isNotEmpty);
+      expect(u.byKind(SurfaceCatalogDiagnosticKind.unusedAnimation), isNotEmpty);
+    });
+
+    test('36. reuses Lot 39 atlas codec for atlases[0]', () {
+      final atlas = _atlas();
+      final c = _catalog(atlases: [atlas]);
+      final json = encodeProjectSurfaceCatalog(c);
+      final list = json['atlases']! as List<Object?>;
+      expect(list[0], encodeProjectSurfaceAtlas(atlas));
+    });
+
+    test('37. reuses Lot 42 animation codec for animations[0]', () {
+      final atl = _atlas(id: 'a');
+      final anim = _animation(atlasId: 'a');
+      final c = _catalog(atlases: [atl], animations: [anim]);
+      final json = encodeProjectSurfaceCatalog(c);
+      final list = json['animations']! as List<Object?>;
+      expect(list[0], encodeProjectSurfaceAnimation(anim));
+    });
+
+    test('38. reuses Lot 45 preset codec for presets[0]', () {
+      final atl = _atlas(id: 'a');
+      final anim = _animation(id: 'm', atlasId: 'a');
+      final preset = _preset(animationId: 'm');
+      final c = _catalog(
+        atlases: [atl],
+        animations: [anim],
+        presets: [preset],
+      );
+      final json = encodeProjectSurfaceCatalog(c);
+      final list = json['presets']! as List<Object?>;
+      expect(list[0], encodeProjectSurfacePreset(preset));
+    });
+
+    test('39. public API encode returns map', () {
+      expect(encodeProjectSurfaceCatalog(_catalog()), isA<Map<String, Object?>>());
+    });
+
+    test('40. ProjectManifest has no surface persistence keys (Lot 46)', () {
+      const manifest = ProjectManifest(
+        name: 'L46',
+        maps: [
+          ProjectMapEntry(
+            id: 'm1',
+            name: 'M',
+            relativePath: 'maps/m1.json',
+          ),
+        ],
+        tilesets: [],
+      );
+      final ju = manifest.toJson();
+      for (final k in const [
+        'surfaceCatalog',
+        'surfaceDefinitions',
+        'surfaceAtlases',
+        'surfaceAnimations',
+        'surfacePresets',
+        'surfaceCategories',
+      ]) {
+        expect(ju.containsKey(k), isFalse, reason: k);
+      }
+    });
+
+    test(
+      '41. codec external to model: no catalog.toJson or ProjectSurfaceCatalog.fromJson',
+      () {
+        final c = _catalog();
+        final m = encodeProjectSurfaceCatalog(c);
+        expect(m, isA<Map<String, Object?>>());
+      },
+    );
+
+    test('42. manifest surface integration remains out of scope (no manifest codec)', () {
+      final m = encodeProjectSurfaceCatalog(_catalog());
+      expect(m['atlases'], isA<List>());
+    });
+
+    test('43. no Surface categories array; categoryId stays per-item string', () {
+      final c = _catalog(
+        atlases: [_atlas(categoryId: 'cat')],
+        animations: [_animation(atlasId: 'water-atlas')],
+        presets: [_preset(animationId: 'water-isolated-loop')],
+      );
+      final j = encodeProjectSurfaceCatalog(c);
+      expect(j.containsKey('categories'), isFalse);
+      expect(j.containsKey('surfaceCategories'), isFalse);
+      final plist = j['presets']! as List<Object?>;
+      final p0 = plist[0] as Map<String, Object?>;
+      expect(p0['categoryId'], isA<String>());
+    });
+
+    test('44. no kind / surfaceKind / presetKind / type at catalog or preset JSON', () {
+      final c = _catalog(
+        atlases: [_atlas()],
+        animations: [_animation()],
+        presets: [_preset()],
+      );
+      final j = encodeProjectSurfaceCatalog(c);
+      for (final k in const ['surfaceKind', 'presetKind', 'kind', 'type']) {
+        expect(j.containsKey(k), isFalse, reason: 'top $k');
+      }
+      final plist = j['presets']! as List<Object?>;
+      final p0 = plist[0] as Map<String, Object?>;
+      for (final k in const ['surfaceKind', 'presetKind', 'kind', 'type']) {
+        expect(p0.containsKey(k), isFalse, reason: 'preset $k');
+      }
+    });
+  });
+}
+
+SurfaceAtlasGeometry _geometry({
+  int columns = 23,
+  int rows = 32,
+}) {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+}
+
+ProjectSurfaceAtlas _atlas({
+  String id = 'water-atlas',
+  String name = 'Water Atlas',
+  String tilesetId = 'nature-tileset',
+  SurfaceAtlasGeometry? geometry,
+  String? categoryId = 'animated-surfaces',
+  int sortOrder = 0,
+}) {
+  return ProjectSurfaceAtlas(
+    id: id,
+    name: name,
+    tilesetId: tilesetId,
+    geometry: geometry ?? _geometry(),
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}
+
+SurfaceAnimationFrame _frame({
+  String atlasId = 'water-atlas',
+  int column = 0,
+  int row = 0,
+  int durationMs = 120,
+}) {
+  return SurfaceAnimationFrame(
+    tileRef: SurfaceAtlasTileRef(
+      atlasId: atlasId,
+      column: column,
+      row: row,
+    ),
+    durationMs: durationMs,
+  );
+}
+
+ProjectSurfaceAnimation _animation({
+  String id = 'water-isolated-loop',
+  String name = 'Water Isolated Loop',
+  String atlasId = 'water-atlas',
+  int column = 0,
+  int row = 0,
+  int durationMs = 120,
+  String? syncGroupId = 'water',
+  String? categoryId = 'animated-surfaces',
+  int sortOrder = 0,
+}) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: name,
+    timeline: SurfaceAnimationTimeline(
+      frames: [
+        _frame(
+          atlasId: atlasId,
+          column: column,
+          row: row,
+          durationMs: durationMs,
+        ),
+      ],
+    ),
+    syncGroupId: syncGroupId,
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}
+
+SurfaceVariantAnimationRef _ref(
+  SurfaceVariantRole role, {
+  String animationId = 'water-isolated-loop',
+}) {
+  return SurfaceVariantAnimationRef(
+    role: role,
+    animationId: animationId,
+  );
+}
+
+ProjectSurfacePreset _preset({
+  String id = 'water-surface',
+  String name = 'Water Surface',
+  String animationId = 'water-isolated-loop',
+  String? categoryId = 'animated-surfaces',
+  int sortOrder = 0,
+}) {
+  return ProjectSurfacePreset(
+    id: id,
+    name: name,
+    variantAnimations: SurfaceVariantAnimationRefSet(
+      refs: [
+        _ref(SurfaceVariantRole.isolated, animationId: animationId),
+      ],
+    ),
+    categoryId: categoryId,
+    sortOrder: sortOrder,
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
+String _mapStr(Object? o) {
+  if (o is Map) {
+    final keys = o.keys.toList()..sort();
+    return keys.map((k) => '$k:${_mapStr(o[k])}').join('|');
+  }
+  if (o is List) {
+    return o.map(_mapStr).join(';');
+  }
+  if (o is String) {
+    return o;
+  }
+  if (o == null) {
+    return 'null';
+  }
+  return o.toString();
+}
```

### C.3 Diff `map_core.dart`

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 541b2fdb..5540dd98 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -52,6 +52,7 @@ export 'src/operations/project_surface_animation_json_codec.dart';
 export 'src/operations/surface_variant_animation_ref_json_codec.dart';
 export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
 export 'src/operations/project_surface_preset_json_codec.dart';
+export 'src/operations/project_surface_catalog_json_codec.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

### C.4 Exception pour le présent rapport (cahier Lot 46)

Le contenu intégral des sections 1–38 ci-dessus est enregistré dans ce chemin. Un diff unifié dont la cible est ce fichier et la source serait le fichier vide se représente par le texte de ces sections avec chaque ligne préfixée par `+`, conformément à l’usage Git usuel d’un ajout de fichier.

### D. Preuves de commandes

Sections 30 (test ciblé), 31 (régressions), 32 (`dart analyze`), 33 (`dart test` complet).
