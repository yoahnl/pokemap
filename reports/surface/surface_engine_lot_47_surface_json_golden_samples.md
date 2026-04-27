# Surface Engine — Lot 47 — Surface JSON Golden Samples / Characterization V0

## 1. Résumé exécutif

Trois fixtures JSON canoniques (`empty`, `minimal` eau, `full` eau) et un test de caractérisation (`project_surface_catalog_json_golden_samples_test.dart`) qui verrouillent le JSON V0 de `ProjectSurfaceCatalog` via `encodeProjectSurfaceCatalog` / `decodeProjectSurfaceCatalog`, sans modifier le code de production ni le manifeste.

## 2. Pourquoi ce lot vient après le Lot 46

Le Lot 46 a figé le codec catalogue ; le Lot 47 fige des **échantillons** lisibles et des assertions de non-régression (`pretty` = fixture, round-trip, diagnostics).

## 3. Tableau récapitulatif des lots Surface 39–51

| Rappel |
|--------|
| Lot 39 — ProjectSurfaceAtlas JSON Codec V0 — fait |
| Lot 40 — Surface TileRef / AnimationFrame JSON Codec V0 — fait |
| Lot 41 — SurfaceAnimationTimeline JSON Codec V0 — fait |
| Lot 42 — ProjectSurfaceAnimation JSON Codec V0 — fait |
| Lot 43 — SurfaceVariantAnimationRef JSON Codec V0 — fait |
| Lot 44 — SurfaceVariantAnimationRefSet JSON Codec V0 — fait |
| Lot 45 — ProjectSurfacePreset JSON Codec V0 — fait |
| Lot 46 — ProjectSurfaceCatalog JSON Codec V0 — fait |
| Lot 47 — Surface JSON Golden Samples / Characterization — **ce lot** |
| Lot 48 — ProjectManifest Surface Integration Prep — prochain recommandé |
| Lot 49 — ProjectManifest Surface Integration V0 — plus tard, si prêt |
| Lot 50 — Surface Catalog Repository / Use Cases Prep — ensuite probable |
| Lot 51 — Surface Studio Read Model Prep — ensuite probable |

## 4. Fichiers consultés

Codecs Lot 46, `ProjectSurfaceCatalog`, diagnostics Surface, tests codec existants.

## 5. Fichiers créés (Lot 47)

- `test/fixtures/surface_catalog_json/empty_surface_catalog_v0.json`
- `test/fixtures/surface_catalog_json/minimal_water_surface_catalog_v0.json`
- `test/fixtures/surface_catalog_json/full_water_surface_catalog_v0.json`
- `test/project_surface_catalog_json_golden_samples_test.dart`
- `reports/surface/surface_engine_lot_47_surface_json_golden_samples.md`

## 6. Fichiers modifiés (Lot 47)

Aucun fichier `lib/` ni `map_core.dart` — **aucun fichier de production modifié**.

## 7. Liste des fixtures

1. `empty_surface_catalog_v0.json` — catalogue vide.
2. `minimal_water_surface_catalog_v0.json` — 1 atlas, 1 animation, 1 preset (eau minimal, sans `categoryId` / `syncGroupId` optionnels).
3. `full_water_surface_catalog_v0.json` — options explicites, 2 frames, 3 refs (ordre cross → isolated → horizontal).

## 8. Schéma `empty_surface_catalog_v0.json`

Trois clés `atlases`, `animations`, `presets` — tableaux vides. Indentation 2 espaces — voir Evidence A pour le texte exact.

## 9–10. Schémas minimal / full

Voir fichiers complets en Evidence Pack A. Le sample **full** aligne l’ordre des clés **atlas** sur le codec Lot 39 : `sortOrder` puis `categoryId` (le schéma indicatif du cahier avait l’ordre inverse ; la golden suit le **pretty-print du codec**).

## 11. Décision : ne pas modifier de code de production

Lot fixtures + tests uniquement.

## 12. Décision : ne pas modifier `ProjectManifest`

## 13. Décision : pas de golden writer / updater automatique

Les fixtures sont des fichiers statiques versionnés.

## 14. Décision : `JsonEncoder.withIndent('  ')`

## 15. Décision : newline finale sur chaque fixture

## 16–17. Minimal vs full (optionnels null / présents)

Documenté par les fichiers et tests 4, 9, 23.

## 18. Contenu nu sans enveloppe manifest

Pas de clé `surfaceCatalog` autour du JSON.

## 19–20. Pas de catégories Surface structurées / pas de `SurfacePresetKind`

Tests 16–17.

## 21–25. Tests, non-faits, manifest, generated, build_runner, autres packages

Voir sections 21–27 ci-dessous synthétiques ; preuves en commandes.

## 21. Ce qui a été testé

25 tests (golden, diagnostics post-decode, manifest minimal).

## 22. Ce que les tests prouvent

Équivalence fixture ↔ codec, stabilité round-trip, exemples propres pour diagnostics.

## 23. Ce qui n’a pas été fait

Intégration manifest, migration, runtime.

## 24. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Hors périmètre : ce lot isole le contenu `ProjectSurfaceCatalog` en JSON nu pour servir de contrat de lecture ; l’enveloppe manifeste attend le Lot 48+.

## 25. Pourquoi aucun fichier generated n’a été créé

Aucun modèle `*.g.dart` / Freezed à (re)générer : uniquement JSON et tests.

## 26. Pourquoi aucun `build_runner` n’a été lancé

Aucun changement dans les sources générées.

## 27. Pourquoi aucun runtime / editor / gameplay / battle n’a été modifié

Lot limité à `map_core` — fixtures de test + rapport, sans intégration moteur ni outil.

## 28. Impact prochains lots

Référence stable pour l’intégration manifeste (Lot 48+).

## 29. Commandes lancées

`dart test test/project_surface_catalog_json_golden_samples_test.dart` ; régressions (section 31) ; `dart analyze` (section 32) ; `dart test` complet (section 33).

## 30. Résultat : test ciblé Lot 47

```

00:00 +0: loading test/project_surface_catalog_json_golden_samples_test.dart                                                                                                                           
00:00 +0: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON                                                                                                                  
00:00 +1: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON                                                                                                                  
00:00 +1: Surface catalog JSON golden samples (Lot 47) 2. empty fixture matches codec                                                                                                                  
00:00 +2: Surface catalog JSON golden samples (Lot 47) 2. empty fixture matches codec                                                                                                                  
00:00 +2: Surface catalog JSON golden samples (Lot 47) 3. empty fixture round-trip                                                                                                                     
00:00 +3: Surface catalog JSON golden samples (Lot 47) 3. empty fixture round-trip                                                                                                                     
00:00 +3: Surface catalog JSON golden samples (Lot 47) 4. minimal water fixture is valid JSON with expected structure                                                                                  
00:00 +4: Surface catalog JSON golden samples (Lot 47) 4. minimal water fixture is valid JSON with expected structure                                                                                  
00:00 +4: Surface catalog JSON golden samples (Lot 47) 5. minimal water fixture matches codec                                                                                                          
00:00 +5: Surface catalog JSON golden samples (Lot 47) 5. minimal water fixture matches codec                                                                                                          
00:00 +5: Surface catalog JSON golden samples (Lot 47) 6. minimal water fixture round-trip                                                                                                             
00:00 +6: Surface catalog JSON golden samples (Lot 47) 6. minimal water fixture round-trip                                                                                                             
00:00 +6: Surface catalog JSON golden samples (Lot 47) 7. minimal water: no error diagnostics                                                                                                          
00:00 +7: Surface catalog JSON golden samples (Lot 47) 7. minimal water: no error diagnostics                                                                                                          
00:00 +7: Surface catalog JSON golden samples (Lot 47) 8. minimal water: no unused resource diagnostics                                                                                                
00:00 +8: Surface catalog JSON golden samples (Lot 47) 8. minimal water: no unused resource diagnostics                                                                                                
00:00 +8: Surface catalog JSON golden samples (Lot 47) 9. full water fixture is valid JSON with expected structure                                                                                     
00:00 +9: Surface catalog JSON golden samples (Lot 47) 9. full water fixture is valid JSON with expected structure                                                                                     
00:00 +9: Surface catalog JSON golden samples (Lot 47) 10. full water fixture matches codec                                                                                                            
00:00 +10: Surface catalog JSON golden samples (Lot 47) 10. full water fixture matches codec                                                                                                           
00:00 +10: Surface catalog JSON golden samples (Lot 47) 11. full water fixture round-trip                                                                                                              
00:00 +11: Surface catalog JSON golden samples (Lot 47) 11. full water fixture round-trip                                                                                                              
00:00 +11: Surface catalog JSON golden samples (Lot 47) 12. full water: preset ref order is cross, isolated, horizontal                                                                                
00:00 +12: Surface catalog JSON golden samples (Lot 47) 12. full water: preset ref order is cross, isolated, horizontal                                                                                
00:00 +12: Surface catalog JSON golden samples (Lot 47) 13. full water: no error diagnostics                                                                                                           
00:00 +13: Surface catalog JSON golden samples (Lot 47) 13. full water: no error diagnostics                                                                                                           
00:00 +13: Surface catalog JSON golden samples (Lot 47) 14. full water: no unused resource diagnostics                                                                                                 
00:00 +14: Surface catalog JSON golden samples (Lot 47) 14. full water: no unused resource diagnostics                                                                                                 
00:00 +14: Surface catalog JSON golden samples (Lot 47) 15. fixtures contain no manifest wrapper keys (raw string)                                                                                     
00:00 +15: Surface catalog JSON golden samples (Lot 47) 15. fixtures contain no manifest wrapper keys (raw string)                                                                                     
00:00 +15: Surface catalog JSON golden samples (Lot 47) 16. fixtures contain no category list keys                                                                                                     
00:00 +16: Surface catalog JSON golden samples (Lot 47) 16. fixtures contain no category list keys                                                                                                     
00:00 +16: Surface catalog JSON golden samples (Lot 47) 17. fixtures contain no kind/surfaceKind/type as map keys (deep)                                                                               
00:00 +17: Surface catalog JSON golden samples (Lot 47) 17. fixtures contain no kind/surfaceKind/type as map keys (deep)                                                                               
00:00 +17: Surface catalog JSON golden samples (Lot 47) 18. fixtures end with newline                                                                                                                  
00:00 +18: Surface catalog JSON golden samples (Lot 47) 18. fixtures end with newline                                                                                                                  
00:00 +18: Surface catalog JSON golden samples (Lot 47) 19. fixtures match two-space pretty jsonEncode roundtrip                                                                                       
00:00 +19: Surface catalog JSON golden samples (Lot 47) 19. fixtures match two-space pretty jsonEncode roundtrip                                                                                       
00:00 +19: Surface catalog JSON golden samples (Lot 47) 20. each fixture is stable: decode->encode->pretty equals fixture                                                                              
00:00 +20: Surface catalog JSON golden samples (Lot 47) 20. each fixture is stable: decode->encode->pretty equals fixture                                                                              
00:00 +20: Surface catalog JSON golden samples (Lot 47) 21. water fixtures use layout columnsAreVariantsRowsAreFrames                                                                                  
00:00 +21: Surface catalog JSON golden samples (Lot 47) 21. water fixtures use layout columnsAreVariantsRowsAreFrames                                                                                  
00:00 +21: Surface catalog JSON golden samples (Lot 47) 22. water fixtures: sortOrder on every atlas, animation, preset                                                                                
00:00 +22: Surface catalog JSON golden samples (Lot 47) 22. water fixtures: sortOrder on every atlas, animation, preset                                                                                
00:00 +22: Surface catalog JSON golden samples (Lot 47) 23. minimal fixture omits null optional fields (categoryId, syncGroupId)                                                                       
00:00 +23: Surface catalog JSON golden samples (Lot 47) 23. minimal fixture omits null optional fields (categoryId, syncGroupId)                                                                       
00:00 +23: Surface catalog JSON golden samples (Lot 47) 24. only public map_core import for package (no src/)                                                                                          
00:00 +24: Surface catalog JSON golden samples (Lot 47) 24. only public map_core import for package (no src/)                                                                                          
00:00 +24: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest has no surface persistence keys (Lot 47)                                                                                   
00:00 +25: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest has no surface persistence keys (Lot 47)                                                                                   
00:00 +25: All tests passed!                                                                                                                                                                           
```

## 31. Régressions (sorties intégrales)

### `test/project_surface_catalog_json_codec_test.dart`

```

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



## 32. `dart analyze`

```
Analyzing project_surface_catalog_json_golden_samples_test.dart, project_surface_catalog_json_codec_test.dart, project_surface_catalog_test.dart, surface_catalog_diagnostics_test.dart, surface_catalog_unused_diagnostics_test.dart, surface_catalog_authoring_diagnostics_test.dart, surface_model_entrypoint_test.dart...
No issues found!
```

## 33. `dart test` complet

- Commande : `cd packages/map_core && /opt/homebrew/bin/dart test`
- Ligne finale : `+1133: All tests passed!`
- Total : **1133**

## 34. Points de vigilance

Toute évolution d’ordre de clés dans les codecs enfants peut exiger une mise à jour des golden (hors scope implicite).

## 35. Autocritique

Le schéma « full » du prompt d’origine pour l’atlas (`categoryId` avant `sortOrder`) a été ajusté pour coller au codec Lot 39 ; c’est documenté en §9–10.

## 36. Prompt discutable

Désalignement mineur ordre de clés atlas entre schéma indicatif et encodeur réel — résolu en faveur du codec.

## 37. Auto-review indépendante

Checklist cahier Lot 47 (périmètre, `lib/`, manifest, codecs, API publique, fixtures, diagnostics, commandes) : entièrement cochée. Auto-check : aucune formulation interdite (liste cahier) n’est utilisée pour remplacer une preuve requise.

## 38. `git status --short` initial (avant travail Lot 47 sur ce worktree)

```text
M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart
?? packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
?? reports/surface/surface_engine_lot_15_standard_path_preset_vertical_atlas_builder.md
```

## 39. `git status --short` final

```text
?? packages/map_core/test/fixtures/
?? packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart
?? reports/surface/surface_engine_lot_47_surface_json_golden_samples.md
```

## 40. Distinction changements préexistants / Lot 47

- **Hors lot (lignes initial)** : modifications ou fichiers issus d’autres lots (ex. trace Lot 15 listée en initial) — ce n’est **pas** le livrable Lot 47.
- **Lot 47** (chemins autorisés uniquement) : `test/fixtures/surface_catalog_json/empty_surface_catalog_v0.json`, `minimal_water_surface_catalog_v0.json`, `full_water_surface_catalog_v0.json`, `test/project_surface_catalog_json_golden_samples_test.dart`, `reports/surface/surface_engine_lot_47_surface_json_golden_samples.md`. Aucun `lib/`, aucun `map_core.dart`, aucun codec des lots 39–46 modifié.

## 41. Evidence Pack complet

### A. Fichiers créés (contenu intégral)

#### `empty_surface_catalog_v0.json`

```json
{
  "atlases": [],
  "animations": [],
  "presets": []
}
```

#### `minimal_water_surface_catalog_v0.json`

```json
{
  "atlases": [
    {
      "id": "water-atlas",
      "name": "Water Atlas",
      "tilesetId": "nature-tileset",
      "geometry": {
        "tileSize": {
          "width": 32,
          "height": 32
        },
        "gridSize": {
          "columns": 23,
          "rows": 32
        },
        "layout": "columnsAreVariantsRowsAreFrames"
      },
      "sortOrder": 0
    }
  ],
  "animations": [
    {
      "id": "water-isolated-loop",
      "name": "Water Isolated Loop",
      "timeline": {
        "frames": [
          {
            "tileRef": {
              "atlasId": "water-atlas",
              "column": 0,
              "row": 0
            },
            "durationMs": 120
          }
        ]
      },
      "sortOrder": 0
    }
  ],
  "presets": [
    {
      "id": "water-surface",
      "name": "Water Surface",
      "variantAnimations": {
        "refs": [
          {
            "role": "isolated",
            "animationId": "water-isolated-loop"
          }
        ]
      },
      "sortOrder": 0
    }
  ]
}
```

#### `full_water_surface_catalog_v0.json`

```json
{
  "atlases": [
    {
      "id": "water-atlas",
      "name": "Water Atlas",
      "tilesetId": "nature-tileset",
      "geometry": {
        "tileSize": {
          "width": 32,
          "height": 32
        },
        "gridSize": {
          "columns": 23,
          "rows": 32
        },
        "layout": "columnsAreVariantsRowsAreFrames"
      },
      "sortOrder": 10,
      "categoryId": "animated-surfaces"
    }
  ],
  "animations": [
    {
      "id": "water-loop",
      "name": "Water Loop",
      "timeline": {
        "frames": [
          {
            "tileRef": {
              "atlasId": "water-atlas",
              "column": 0,
              "row": 0
            },
            "durationMs": 120
          },
          {
            "tileRef": {
              "atlasId": "water-atlas",
              "column": 0,
              "row": 1
            },
            "durationMs": 120
          }
        ]
      },
      "syncGroupId": "water",
      "categoryId": "animated-surfaces",
      "sortOrder": 20
    }
  ],
  "presets": [
    {
      "id": "water-surface",
      "name": "Water Surface",
      "variantAnimations": {
        "refs": [
          {
            "role": "cross",
            "animationId": "water-loop"
          },
          {
            "role": "isolated",
            "animationId": "water-loop"
          },
          {
            "role": "horizontal",
            "animationId": "water-loop"
          }
        ]
      },
      "categoryId": "animated-surfaces",
      "sortOrder": 30
    }
  ]
}
```

#### `project_surface_catalog_json_golden_samples_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Surface catalog JSON golden samples (Lot 47)', () {
    const manifestKeys = <String>[
      'surfaceCatalog',
      'surfaceDefinitions',
      'surfaceAtlases',
      'surfaceAnimations',
      'surfacePresets',
      'surfaceCategories',
    ];

    const categoryListKeys = <String>['categories', 'surfaceCategories'];

    const forbiddenKindKeys = <String>['surfaceKind', 'presetKind', 'kind', 'type'];

    test('1. empty fixture is valid JSON', () {
      final raw = _readFixture('empty_surface_catalog_v0.json');
      final o = jsonDecode(raw);
      expect(o, isA<Map<String, Object?>>());
      final m = o as Map<String, Object?>;
      expect(m.keys.toSet(), <String>{'atlases', 'animations', 'presets'});
      expect(m['atlases'], isA<List>());
      expect(m['animations'], isA<List>());
      expect(m['presets'], isA<List>());
      expect(m['atlases'], isEmpty);
      expect(m['animations'], isEmpty);
      expect(m['presets'], isEmpty);
    });

    test('2. empty fixture matches codec', () {
      final catalog = ProjectSurfaceCatalog();
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
      final fixture = _readFixture('empty_surface_catalog_v0.json');
      expect(pretty, fixture);
    });

    test('3. empty fixture round-trip', () {
      final fixture = _readFixture('empty_surface_catalog_v0.json');
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('empty_surface_catalog_v0.json'),
      );
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
      expect(pretty, fixture);
    });

    test('4. minimal water fixture is valid JSON with expected structure', () {
      final raw = _readFixture('minimal_water_surface_catalog_v0.json');
      final m = jsonDecode(raw) as Map<String, Object?>;
      expect((m['atlases'] as List).length, 1);
      expect((m['animations'] as List).length, 1);
      expect((m['presets'] as List).length, 1);
      final a0 = (m['atlases']! as List)[0] as Map<String, Object?>;
      final n0 = (m['animations']! as List)[0] as Map<String, Object?>;
      final p0 = (m['presets']! as List)[0] as Map<String, Object?>;
      expect(a0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('syncGroupId'), isFalse);
      expect(p0.containsKey('categoryId'), isFalse);
      expect(a0['sortOrder'], 0);
      expect(n0['sortOrder'], 0);
      expect(p0['sortOrder'], 0);
    });

    test('5. minimal water fixture matches codec', () {
      final catalog = _minimalWaterCatalog();
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
      final fixture = _readFixture('minimal_water_surface_catalog_v0.json');
      expect(pretty, fixture);
    });

    test('6. minimal water fixture round-trip', () {
      final fixture = _readFixture('minimal_water_surface_catalog_v0.json');
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
      );
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
      expect(pretty, fixture);
    });

    test('7. minimal water: no error diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
      );
      final r = diagnoseProjectSurfaceCatalog(c);
      expect(r.hasDiagnostics, isFalse);
    });

    test('8. minimal water: no unused resource diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
      );
      final r = diagnoseProjectSurfaceCatalogUnusedResources(c);
      expect(r.hasDiagnostics, isFalse);
    });

    test('9. full water fixture is valid JSON with expected structure', () {
      final raw = _readFixture('full_water_surface_catalog_v0.json');
      final m = jsonDecode(raw) as Map<String, Object?>;
      expect((m['atlases'] as List).length, 1);
      expect((m['animations'] as List).length, 1);
      expect((m['presets'] as List).length, 1);
      final a0 = (m['atlases']! as List)[0] as Map<String, Object?>;
      final n0 = (m['animations']! as List)[0] as Map<String, Object?>;
      final p0 = (m['presets']! as List)[0] as Map<String, Object?>;
      expect(a0['categoryId'], 'animated-surfaces');
      expect(n0['syncGroupId'], 'water');
      expect(n0['categoryId'], 'animated-surfaces');
      expect(p0['categoryId'], 'animated-surfaces');
      final frames = (n0['timeline']! as Map)['frames']! as List;
      expect(frames.length, 2);
      final refs = (p0['variantAnimations']! as Map)['refs']! as List;
      expect(refs.length, 3);
    });

    test('10. full water fixture matches codec', () {
      final catalog = _fullWaterCatalog();
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
      final fixture = _readFixture('full_water_surface_catalog_v0.json');
      expect(pretty, fixture);
    });

    test('11. full water fixture round-trip', () {
      final fixture = _readFixture('full_water_surface_catalog_v0.json');
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
      expect(pretty, fixture);
    });

    test('12. full water: preset ref order is cross, isolated, horizontal', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      final roles = c.presets.first.variantAnimations.refs
          .map((r) => r.role)
          .toList();
      expect(roles, [
        SurfaceVariantRole.cross,
        SurfaceVariantRole.isolated,
        SurfaceVariantRole.horizontal,
      ]);
    });

    test('13. full water: no error diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      expect(diagnoseProjectSurfaceCatalog(c).hasDiagnostics, isFalse);
    });

    test('14. full water: no unused resource diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(c).hasDiagnostics,
        isFalse,
      );
    });

    test('15. fixtures contain no manifest wrapper keys (raw string)', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(f);
        for (final k in manifestKeys) {
          expect(s.contains('"$k"'), isFalse, reason: '$f must not key $k');
        }
      }
    });

    test('16. fixtures contain no category list keys', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(f);
        for (final k in categoryListKeys) {
          expect(s.contains('"$k"'), isFalse, reason: '$f $k');
        }
      }
    });

    test('17. fixtures contain no kind/surfaceKind/type as map keys (deep)', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = jsonDecode(_readFixture(f)) as Object?;
        expect(_mapContainsAnyKeyFrom(o, forbiddenKindKeys.toSet()), isFalse);
      }
    });

    test('18. fixtures end with newline', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(f);
        expect(s.endsWith('\n'), isTrue, reason: f);
      }
    });

    test('19. fixtures match two-space pretty jsonEncode roundtrip', () {
      for (final name in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final raw = _readFixture(name);
        final decoded = jsonDecode(raw) as Object?;
        const encoder = JsonEncoder.withIndent('  ');
        final repretty = _withTrailingNewline(encoder.convert(decoded));
        expect(repretty, raw, reason: name);
      }
    });

    test('20. each fixture is stable: decode->encode->pretty equals fixture', () {
      for (final name in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final raw = _readFixture(name);
        final m = _readFixtureJson(name);
        final c = decodeProjectSurfaceCatalog(m);
        final out = _prettyJson(encodeProjectSurfaceCatalog(c));
        expect(out, raw, reason: name);
      }
    });

    test('21. water fixtures use layout columnsAreVariantsRowsAreFrames', () {
      for (final name in const [
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(name);
        expect(
          s.contains('columnsAreVariantsRowsAreFrames'),
          isTrue,
          reason: name,
        );
        expect(s.contains('"grid"'), isFalse, reason: name);
      }
    });

    test('22. water fixtures: sortOrder on every atlas, animation, preset', () {
      for (final name in const [
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final m = jsonDecode(_readFixture(name)) as Map<String, Object?>;
        for (final listKey in const ['atlases', 'animations', 'presets']) {
          for (final item in m[listKey]! as List) {
            final o = item as Map<String, Object?>;
            expect(o.containsKey('sortOrder'), isTrue, reason: '$name $listKey');
          }
        }
      }
    });

    test('23. minimal fixture omits null optional fields (categoryId, syncGroupId)', () {
      final m = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final a0 = (m['atlases']! as List)[0]! as Map<String, Object?>;
      final n0 = (m['animations']! as List)[0]! as Map<String, Object?>;
      final p0 = (m['presets']! as List)[0]! as Map<String, Object?>;
      expect(a0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('syncGroupId'), isFalse);
      expect(p0.containsKey('categoryId'), isFalse);
    });

    test('24. only public map_core import for package (no src/)', () {
      // Ce fichier n'importe que `package:map_core/map_core.dart` (aucun `package:map_core/src/`).
      expect(encodeProjectSurfaceCatalog(_minimalWaterCatalog()), isA<Map<String, Object?>>());
    });

    test('25. ProjectManifest has no surface persistence keys (Lot 47)', () {
      const manifest = ProjectManifest(
        name: 'L47',
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
  });
}

String _fixturePath(String name) => 'test/fixtures/surface_catalog_json/$name';

String _readFixture(String name) => File(_fixturePath(name)).readAsStringSync();

Map<String, Object?> _readFixtureJson(String name) {
  return jsonDecode(_readFixture(name)) as Map<String, Object?>;
}

String _prettyJson(Map<String, Object?> json) {
  const encoder = JsonEncoder.withIndent('  ');
  return _withTrailingNewline(encoder.convert(json));
}

String _withTrailingNewline(String value) {
  if (value.endsWith('\n')) {
    return value;
  }
  return '$value\n';
}

/// Parcourt maps JSON ; ne considère que les clés de map (pas le contenu des strings).
bool _mapContainsAnyKeyFrom(Object? o, Set<String> forbidden) {
  if (o is Map) {
    for (final e in o.entries) {
      if (e.key is String && forbidden.contains(e.key! as String)) {
        return true;
      }
      if (_mapContainsAnyKeyFrom(e.value, forbidden)) {
        return true;
      }
    }
  } else if (o is List) {
    for (final e in o) {
      if (_mapContainsAnyKeyFrom(e, forbidden)) {
        return true;
      }
    }
  }
  return false;
}

SurfaceAtlasGeometry _sharedWaterGeometry() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _waterAtlas({
  String id = 'water-atlas',
  String name = 'Water Atlas',
  String tilesetId = 'nature-tileset',
  String? categoryId = 'animated-surfaces',
  int sortOrder = 10,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: name,
    tilesetId: tilesetId,
    geometry: _sharedWaterGeometry(),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectSurfaceAnimation _waterAnimation({
  String id = 'water-loop',
  String name = 'Water Loop',
  int sortOrder = 20,
  String? syncGroupId = 'water',
  String? categoryId = 'animated-surfaces',
  bool twoFrames = true,
  String atlasId = 'water-atlas',
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: name,
    timeline: SurfaceAnimationTimeline(
      frames: twoFrames
          ? [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: 0,
                  row: 0,
                ),
                durationMs: 120,
              ),
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: 0,
                  row: 1,
                ),
                durationMs: 120,
              ),
            ]
          : [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: 0,
                  row: 0,
                ),
                durationMs: 120,
              ),
            ],
    ),
    syncGroupId: syncGroupId,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectSurfacePreset _waterPreset({
  String id = 'water-surface',
  String name = 'Water Surface',
  String? categoryId = 'animated-surfaces',
  int sortOrder = 30,
  String animationId = 'water-loop',
  bool multiRef = true,
}) {
  final refs = multiRef
      ? <SurfaceVariantAnimationRef>[
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.cross,
            animationId: animationId,
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: animationId,
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.horizontal,
            animationId: animationId,
          ),
        ]
      : <SurfaceVariantAnimationRef>[
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: animationId,
          ),
        ];
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectSurfaceCatalog _minimalWaterCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      _waterAtlas(
        categoryId: null,
        sortOrder: 0,
      ),
    ],
    animations: [
      _waterAnimation(
        id: 'water-isolated-loop',
        name: 'Water Isolated Loop',
        sortOrder: 0,
        syncGroupId: null,
        categoryId: null,
        twoFrames: false,
        atlasId: 'water-atlas',
      ),
    ],
    presets: [
      _waterPreset(
        categoryId: null,
        sortOrder: 0,
        animationId: 'water-isolated-loop',
        multiRef: false,
      ),
    ],
  );
}

ProjectSurfaceCatalog _fullWaterCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      _waterAtlas(
        sortOrder: 10,
        categoryId: 'animated-surfaces',
      ),
    ],
    animations: [
      _waterAnimation(
        id: 'water-loop',
        name: 'Water Loop',
        sortOrder: 20,
        twoFrames: true,
      ),
    ],
    presets: [
      _waterPreset(
        sortOrder: 30,
        multiRef: true,
        animationId: 'water-loop',
      ),
    ],
  );
}
```

#### `surface_engine_lot_47_surface_json_golden_samples.md`

Cinquième fichier créé : le présent document. Le texte intégral **hors** section 42 (Métacopie) est constitué des sections 1–41 ; la **section 42** du fichier enregistré sur disque contient en bloc le document entier **avant** l’ajout de la section 42 (métacopie intégrale, preuve reproductible de l’intégralité du `.md`).

### B. Fichiers modifiés

Aucun.

### C. Diffs `/dev/null`

#### C.1 `empty_surface_catalog_v0.json`

```diff
diff --git a/packages/map_core/test/fixtures/surface_catalog_json/empty_surface_catalog_v0.json b/packages/map_core/test/fixtures/surface_catalog_json/empty_surface_catalog_v0.json
new file mode 100644
index 00000000..336c650c
--- /dev/null
+++ b/packages/map_core/test/fixtures/surface_catalog_json/empty_surface_catalog_v0.json
@@ -0,0 +1,5 @@
+{
+  "atlases": [],
+  "animations": [],
+  "presets": []
+}
```

#### C.2 `minimal_water_surface_catalog_v0.json`

```diff
diff --git a/packages/map_core/test/fixtures/surface_catalog_json/minimal_water_surface_catalog_v0.json b/packages/map_core/test/fixtures/surface_catalog_json/minimal_water_surface_catalog_v0.json
new file mode 100644
index 00000000..3a64f399
--- /dev/null
+++ b/packages/map_core/test/fixtures/surface_catalog_json/minimal_water_surface_catalog_v0.json
@@ -0,0 +1,55 @@
+{
+  "atlases": [
+    {
+      "id": "water-atlas",
+      "name": "Water Atlas",
+      "tilesetId": "nature-tileset",
+      "geometry": {
+        "tileSize": {
+          "width": 32,
+          "height": 32
+        },
+        "gridSize": {
+          "columns": 23,
+          "rows": 32
+        },
+        "layout": "columnsAreVariantsRowsAreFrames"
+      },
+      "sortOrder": 0
+    }
+  ],
+  "animations": [
+    {
+      "id": "water-isolated-loop",
+      "name": "Water Isolated Loop",
+      "timeline": {
+        "frames": [
+          {
+            "tileRef": {
+              "atlasId": "water-atlas",
+              "column": 0,
+              "row": 0
+            },
+            "durationMs": 120
+          }
+        ]
+      },
+      "sortOrder": 0
+    }
+  ],
+  "presets": [
+    {
+      "id": "water-surface",
+      "name": "Water Surface",
+      "variantAnimations": {
+        "refs": [
+          {
+            "role": "isolated",
+            "animationId": "water-isolated-loop"
+          }
+        ]
+      },
+      "sortOrder": 0
+    }
+  ]
+}
```

#### C.3 `full_water_surface_catalog_v0.json`

```diff
diff --git a/packages/map_core/test/fixtures/surface_catalog_json/full_water_surface_catalog_v0.json b/packages/map_core/test/fixtures/surface_catalog_json/full_water_surface_catalog_v0.json
new file mode 100644
index 00000000..57237bfa
--- /dev/null
+++ b/packages/map_core/test/fixtures/surface_catalog_json/full_water_surface_catalog_v0.json
@@ -0,0 +1,75 @@
+{
+  "atlases": [
+    {
+      "id": "water-atlas",
+      "name": "Water Atlas",
+      "tilesetId": "nature-tileset",
+      "geometry": {
+        "tileSize": {
+          "width": 32,
+          "height": 32
+        },
+        "gridSize": {
+          "columns": 23,
+          "rows": 32
+        },
+        "layout": "columnsAreVariantsRowsAreFrames"
+      },
+      "sortOrder": 10,
+      "categoryId": "animated-surfaces"
+    }
+  ],
+  "animations": [
+    {
+      "id": "water-loop",
+      "name": "Water Loop",
+      "timeline": {
+        "frames": [
+          {
+            "tileRef": {
+              "atlasId": "water-atlas",
+              "column": 0,
+              "row": 0
+            },
+            "durationMs": 120
+          },
+          {
+            "tileRef": {
+              "atlasId": "water-atlas",
+              "column": 0,
+              "row": 1
+            },
+            "durationMs": 120
+          }
+        ]
+      },
+      "syncGroupId": "water",
+      "categoryId": "animated-surfaces",
+      "sortOrder": 20
+    }
+  ],
+  "presets": [
+    {
+      "id": "water-surface",
+      "name": "Water Surface",
+      "variantAnimations": {
+        "refs": [
+          {
+            "role": "cross",
+            "animationId": "water-loop"
+          },
+          {
+            "role": "isolated",
+            "animationId": "water-loop"
+          },
+          {
+            "role": "horizontal",
+            "animationId": "water-loop"
+          }
+        ]
+      },
+      "categoryId": "animated-surfaces",
+      "sortOrder": 30
+    }
+  ]
+}
```

#### C.4 `project_surface_catalog_json_golden_samples_test.dart`

```diff
diff --git a/packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart b/packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart
new file mode 100644
index 00000000..2d99afb5
--- /dev/null
+++ b/packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart
@@ -0,0 +1,524 @@
+import 'dart:convert';
+import 'dart:io';
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('Surface catalog JSON golden samples (Lot 47)', () {
+    const manifestKeys = <String>[
+      'surfaceCatalog',
+      'surfaceDefinitions',
+      'surfaceAtlases',
+      'surfaceAnimations',
+      'surfacePresets',
+      'surfaceCategories',
+    ];
+
+    const categoryListKeys = <String>['categories', 'surfaceCategories'];
+
+    const forbiddenKindKeys = <String>['surfaceKind', 'presetKind', 'kind', 'type'];
+
+    test('1. empty fixture is valid JSON', () {
+      final raw = _readFixture('empty_surface_catalog_v0.json');
+      final o = jsonDecode(raw);
+      expect(o, isA<Map<String, Object?>>());
+      final m = o as Map<String, Object?>;
+      expect(m.keys.toSet(), <String>{'atlases', 'animations', 'presets'});
+      expect(m['atlases'], isA<List>());
+      expect(m['animations'], isA<List>());
+      expect(m['presets'], isA<List>());
+      expect(m['atlases'], isEmpty);
+      expect(m['animations'], isEmpty);
+      expect(m['presets'], isEmpty);
+    });
+
+    test('2. empty fixture matches codec', () {
+      final catalog = ProjectSurfaceCatalog();
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
+      final fixture = _readFixture('empty_surface_catalog_v0.json');
+      expect(pretty, fixture);
+    });
+
+    test('3. empty fixture round-trip', () {
+      final fixture = _readFixture('empty_surface_catalog_v0.json');
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('empty_surface_catalog_v0.json'),
+      );
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
+      expect(pretty, fixture);
+    });
+
+    test('4. minimal water fixture is valid JSON with expected structure', () {
+      final raw = _readFixture('minimal_water_surface_catalog_v0.json');
+      final m = jsonDecode(raw) as Map<String, Object?>;
+      expect((m['atlases'] as List).length, 1);
+      expect((m['animations'] as List).length, 1);
+      expect((m['presets'] as List).length, 1);
+      final a0 = (m['atlases']! as List)[0] as Map<String, Object?>;
+      final n0 = (m['animations']! as List)[0] as Map<String, Object?>;
+      final p0 = (m['presets']! as List)[0] as Map<String, Object?>;
+      expect(a0.containsKey('categoryId'), isFalse);
+      expect(n0.containsKey('categoryId'), isFalse);
+      expect(n0.containsKey('syncGroupId'), isFalse);
+      expect(p0.containsKey('categoryId'), isFalse);
+      expect(a0['sortOrder'], 0);
+      expect(n0['sortOrder'], 0);
+      expect(p0['sortOrder'], 0);
+    });
+
+    test('5. minimal water fixture matches codec', () {
+      final catalog = _minimalWaterCatalog();
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
+      final fixture = _readFixture('minimal_water_surface_catalog_v0.json');
+      expect(pretty, fixture);
+    });
+
+    test('6. minimal water fixture round-trip', () {
+      final fixture = _readFixture('minimal_water_surface_catalog_v0.json');
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
+      );
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
+      expect(pretty, fixture);
+    });
+
+    test('7. minimal water: no error diagnostics', () {
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
+      );
+      final r = diagnoseProjectSurfaceCatalog(c);
+      expect(r.hasDiagnostics, isFalse);
+    });
+
+    test('8. minimal water: no unused resource diagnostics', () {
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
+      );
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(c);
+      expect(r.hasDiagnostics, isFalse);
+    });
+
+    test('9. full water fixture is valid JSON with expected structure', () {
+      final raw = _readFixture('full_water_surface_catalog_v0.json');
+      final m = jsonDecode(raw) as Map<String, Object?>;
+      expect((m['atlases'] as List).length, 1);
+      expect((m['animations'] as List).length, 1);
+      expect((m['presets'] as List).length, 1);
+      final a0 = (m['atlases']! as List)[0] as Map<String, Object?>;
+      final n0 = (m['animations']! as List)[0] as Map<String, Object?>;
+      final p0 = (m['presets']! as List)[0] as Map<String, Object?>;
+      expect(a0['categoryId'], 'animated-surfaces');
+      expect(n0['syncGroupId'], 'water');
+      expect(n0['categoryId'], 'animated-surfaces');
+      expect(p0['categoryId'], 'animated-surfaces');
+      final frames = (n0['timeline']! as Map)['frames']! as List;
+      expect(frames.length, 2);
+      final refs = (p0['variantAnimations']! as Map)['refs']! as List;
+      expect(refs.length, 3);
+    });
+
+    test('10. full water fixture matches codec', () {
+      final catalog = _fullWaterCatalog();
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
+      final fixture = _readFixture('full_water_surface_catalog_v0.json');
+      expect(pretty, fixture);
+    });
+
+    test('11. full water fixture round-trip', () {
+      final fixture = _readFixture('full_water_surface_catalog_v0.json');
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('full_water_surface_catalog_v0.json'),
+      );
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
+      expect(pretty, fixture);
+    });
+
+    test('12. full water: preset ref order is cross, isolated, horizontal', () {
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('full_water_surface_catalog_v0.json'),
+      );
+      final roles = c.presets.first.variantAnimations.refs
+          .map((r) => r.role)
+          .toList();
+      expect(roles, [
+        SurfaceVariantRole.cross,
+        SurfaceVariantRole.isolated,
+        SurfaceVariantRole.horizontal,
+      ]);
+    });
+
+    test('13. full water: no error diagnostics', () {
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('full_water_surface_catalog_v0.json'),
+      );
+      expect(diagnoseProjectSurfaceCatalog(c).hasDiagnostics, isFalse);
+    });
+
+    test('14. full water: no unused resource diagnostics', () {
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('full_water_surface_catalog_v0.json'),
+      );
+      expect(
+        diagnoseProjectSurfaceCatalogUnusedResources(c).hasDiagnostics,
+        isFalse,
+      );
+    });
+
+    test('15. fixtures contain no manifest wrapper keys (raw string)', () {
+      for (final f in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final s = _readFixture(f);
+        for (final k in manifestKeys) {
+          expect(s.contains('"$k"'), isFalse, reason: '$f must not key $k');
+        }
+      }
+    });
+
+    test('16. fixtures contain no category list keys', () {
+      for (final f in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final s = _readFixture(f);
+        for (final k in categoryListKeys) {
+          expect(s.contains('"$k"'), isFalse, reason: '$f $k');
+        }
+      }
+    });
+
+    test('17. fixtures contain no kind/surfaceKind/type as map keys (deep)', () {
+      for (final f in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final o = jsonDecode(_readFixture(f)) as Object?;
+        expect(_mapContainsAnyKeyFrom(o, forbiddenKindKeys.toSet()), isFalse);
+      }
+    });
+
+    test('18. fixtures end with newline', () {
+      for (final f in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final s = _readFixture(f);
+        expect(s.endsWith('\n'), isTrue, reason: f);
+      }
+    });
+
+    test('19. fixtures match two-space pretty jsonEncode roundtrip', () {
+      for (final name in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final raw = _readFixture(name);
+        final decoded = jsonDecode(raw) as Object?;
+        const encoder = JsonEncoder.withIndent('  ');
+        final repretty = _withTrailingNewline(encoder.convert(decoded));
+        expect(repretty, raw, reason: name);
+      }
+    });
+
+    test('20. each fixture is stable: decode->encode->pretty equals fixture', () {
+      for (final name in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final raw = _readFixture(name);
+        final m = _readFixtureJson(name);
+        final c = decodeProjectSurfaceCatalog(m);
+        final out = _prettyJson(encodeProjectSurfaceCatalog(c));
+        expect(out, raw, reason: name);
+      }
+    });
+
+    test('21. water fixtures use layout columnsAreVariantsRowsAreFrames', () {
+      for (final name in const [
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final s = _readFixture(name);
+        expect(
+          s.contains('columnsAreVariantsRowsAreFrames'),
+          isTrue,
+          reason: name,
+        );
+        expect(s.contains('"grid"'), isFalse, reason: name);
+      }
+    });
+
+    test('22. water fixtures: sortOrder on every atlas, animation, preset', () {
+      for (final name in const [
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final m = jsonDecode(_readFixture(name)) as Map<String, Object?>;
+        for (final listKey in const ['atlases', 'animations', 'presets']) {
+          for (final item in m[listKey]! as List) {
+            final o = item as Map<String, Object?>;
+            expect(o.containsKey('sortOrder'), isTrue, reason: '$name $listKey');
+          }
+        }
+      }
+    });
+
+    test('23. minimal fixture omits null optional fields (categoryId, syncGroupId)', () {
+      final m = _readFixtureJson('minimal_water_surface_catalog_v0.json');
+      final a0 = (m['atlases']! as List)[0]! as Map<String, Object?>;
+      final n0 = (m['animations']! as List)[0]! as Map<String, Object?>;
+      final p0 = (m['presets']! as List)[0]! as Map<String, Object?>;
+      expect(a0.containsKey('categoryId'), isFalse);
+      expect(n0.containsKey('categoryId'), isFalse);
+      expect(n0.containsKey('syncGroupId'), isFalse);
+      expect(p0.containsKey('categoryId'), isFalse);
+    });
+
+    test('24. only public map_core import for package (no src/)', () {
+      // Ce fichier n'importe que `package:map_core/map_core.dart` (aucun `package:map_core/src/`).
+      expect(encodeProjectSurfaceCatalog(_minimalWaterCatalog()), isA<Map<String, Object?>>());
+    });
+
+    test('25. ProjectManifest has no surface persistence keys (Lot 47)', () {
+      const manifest = ProjectManifest(
+        name: 'L47',
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
+  });
+}
+
+String _fixturePath(String name) => 'test/fixtures/surface_catalog_json/$name';
+
+String _readFixture(String name) => File(_fixturePath(name)).readAsStringSync();
+
+Map<String, Object?> _readFixtureJson(String name) {
+  return jsonDecode(_readFixture(name)) as Map<String, Object?>;
+}
+
+String _prettyJson(Map<String, Object?> json) {
+  const encoder = JsonEncoder.withIndent('  ');
+  return _withTrailingNewline(encoder.convert(json));
+}
+
+String _withTrailingNewline(String value) {
+  if (value.endsWith('\n')) {
+    return value;
+  }
+  return '$value\n';
+}
+
+/// Parcourt maps JSON ; ne considère que les clés de map (pas le contenu des strings).
+bool _mapContainsAnyKeyFrom(Object? o, Set<String> forbidden) {
+  if (o is Map) {
+    for (final e in o.entries) {
+      if (e.key is String && forbidden.contains(e.key! as String)) {
+        return true;
+      }
+      if (_mapContainsAnyKeyFrom(e.value, forbidden)) {
+        return true;
+      }
+    }
+  } else if (o is List) {
+    for (final e in o) {
+      if (_mapContainsAnyKeyFrom(e, forbidden)) {
+        return true;
+      }
+    }
+  }
+  return false;
+}
+
+SurfaceAtlasGeometry _sharedWaterGeometry() {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+}
+
+ProjectSurfaceAtlas _waterAtlas({
+  String id = 'water-atlas',
+  String name = 'Water Atlas',
+  String tilesetId = 'nature-tileset',
+  String? categoryId = 'animated-surfaces',
+  int sortOrder = 10,
+}) {
+  return ProjectSurfaceAtlas(
+    id: id,
+    name: name,
+    tilesetId: tilesetId,
+    geometry: _sharedWaterGeometry(),
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}
+
+ProjectSurfaceAnimation _waterAnimation({
+  String id = 'water-loop',
+  String name = 'Water Loop',
+  int sortOrder = 20,
+  String? syncGroupId = 'water',
+  String? categoryId = 'animated-surfaces',
+  bool twoFrames = true,
+  String atlasId = 'water-atlas',
+}) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: name,
+    timeline: SurfaceAnimationTimeline(
+      frames: twoFrames
+          ? [
+              SurfaceAnimationFrame(
+                tileRef: SurfaceAtlasTileRef(
+                  atlasId: atlasId,
+                  column: 0,
+                  row: 0,
+                ),
+                durationMs: 120,
+              ),
+              SurfaceAnimationFrame(
+                tileRef: SurfaceAtlasTileRef(
+                  atlasId: atlasId,
+                  column: 0,
+                  row: 1,
+                ),
+                durationMs: 120,
+              ),
+            ]
+          : [
+              SurfaceAnimationFrame(
+                tileRef: SurfaceAtlasTileRef(
+                  atlasId: atlasId,
+                  column: 0,
+                  row: 0,
+                ),
+                durationMs: 120,
+              ),
+            ],
+    ),
+    syncGroupId: syncGroupId,
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}
+
+ProjectSurfacePreset _waterPreset({
+  String id = 'water-surface',
+  String name = 'Water Surface',
+  String? categoryId = 'animated-surfaces',
+  int sortOrder = 30,
+  String animationId = 'water-loop',
+  bool multiRef = true,
+}) {
+  final refs = multiRef
+      ? <SurfaceVariantAnimationRef>[
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.cross,
+            animationId: animationId,
+          ),
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.isolated,
+            animationId: animationId,
+          ),
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.horizontal,
+            animationId: animationId,
+          ),
+        ]
+      : <SurfaceVariantAnimationRef>[
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.isolated,
+            animationId: animationId,
+          ),
+        ];
+  return ProjectSurfacePreset(
+    id: id,
+    name: name,
+    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}
+
+ProjectSurfaceCatalog _minimalWaterCatalog() {
+  return ProjectSurfaceCatalog(
+    atlases: [
+      _waterAtlas(
+        categoryId: null,
+        sortOrder: 0,
+      ),
+    ],
+    animations: [
+      _waterAnimation(
+        id: 'water-isolated-loop',
+        name: 'Water Isolated Loop',
+        sortOrder: 0,
+        syncGroupId: null,
+        categoryId: null,
+        twoFrames: false,
+        atlasId: 'water-atlas',
+      ),
+    ],
+    presets: [
+      _waterPreset(
+        categoryId: null,
+        sortOrder: 0,
+        animationId: 'water-isolated-loop',
+        multiRef: false,
+      ),
+    ],
+  );
+}
+
+ProjectSurfaceCatalog _fullWaterCatalog() {
+  return ProjectSurfaceCatalog(
+    atlases: [
+      _waterAtlas(
+        sortOrder: 10,
+        categoryId: 'animated-surfaces',
+      ),
+    ],
+    animations: [
+      _waterAnimation(
+        id: 'water-loop',
+        name: 'Water Loop',
+        sortOrder: 20,
+        twoFrames: true,
+      ),
+    ],
+    presets: [
+      _waterPreset(
+        sortOrder: 30,
+        multiRef: true,
+        animationId: 'water-loop',
+      ),
+    ],
+  );
+}
```

#### C.5 Rapport Lot 47 (exception cahier : diff unifié)

Un diff `/dev/null` → ce chemin recopierait chaque ligne du fichier avec préfixe `+` ; le détail est en section A (dont métacopie intégrale en §42) et les sorties en §30–33.

### D. Sorties de commandes

Sections 30–33.

## 42. Métacopie intégrale (état document immédiatement avant cette section)

Bloc texte suivant = copie intégrale du document sans la présente section 42 (même UTF-8, mêmes fins de ligne que la génération intermédiaire).

````text
# Surface Engine — Lot 47 — Surface JSON Golden Samples / Characterization V0

## 1. Résumé exécutif

Trois fixtures JSON canoniques (`empty`, `minimal` eau, `full` eau) et un test de caractérisation (`project_surface_catalog_json_golden_samples_test.dart`) qui verrouillent le JSON V0 de `ProjectSurfaceCatalog` via `encodeProjectSurfaceCatalog` / `decodeProjectSurfaceCatalog`, sans modifier le code de production ni le manifeste.

## 2. Pourquoi ce lot vient après le Lot 46

Le Lot 46 a figé le codec catalogue ; le Lot 47 fige des **échantillons** lisibles et des assertions de non-régression (`pretty` = fixture, round-trip, diagnostics).

## 3. Tableau récapitulatif des lots Surface 39–51

| Rappel |
|--------|
| Lot 39 — ProjectSurfaceAtlas JSON Codec V0 — fait |
| Lot 40 — Surface TileRef / AnimationFrame JSON Codec V0 — fait |
| Lot 41 — SurfaceAnimationTimeline JSON Codec V0 — fait |
| Lot 42 — ProjectSurfaceAnimation JSON Codec V0 — fait |
| Lot 43 — SurfaceVariantAnimationRef JSON Codec V0 — fait |
| Lot 44 — SurfaceVariantAnimationRefSet JSON Codec V0 — fait |
| Lot 45 — ProjectSurfacePreset JSON Codec V0 — fait |
| Lot 46 — ProjectSurfaceCatalog JSON Codec V0 — fait |
| Lot 47 — Surface JSON Golden Samples / Characterization — **ce lot** |
| Lot 48 — ProjectManifest Surface Integration Prep — prochain recommandé |
| Lot 49 — ProjectManifest Surface Integration V0 — plus tard, si prêt |
| Lot 50 — Surface Catalog Repository / Use Cases Prep — ensuite probable |
| Lot 51 — Surface Studio Read Model Prep — ensuite probable |

## 4. Fichiers consultés

Codecs Lot 46, `ProjectSurfaceCatalog`, diagnostics Surface, tests codec existants.

## 5. Fichiers créés (Lot 47)

- `test/fixtures/surface_catalog_json/empty_surface_catalog_v0.json`
- `test/fixtures/surface_catalog_json/minimal_water_surface_catalog_v0.json`
- `test/fixtures/surface_catalog_json/full_water_surface_catalog_v0.json`
- `test/project_surface_catalog_json_golden_samples_test.dart`
- `reports/surface/surface_engine_lot_47_surface_json_golden_samples.md`

## 6. Fichiers modifiés (Lot 47)

Aucun fichier `lib/` ni `map_core.dart` — **aucun fichier de production modifié**.

## 7. Liste des fixtures

1. `empty_surface_catalog_v0.json` — catalogue vide.
2. `minimal_water_surface_catalog_v0.json` — 1 atlas, 1 animation, 1 preset (eau minimal, sans `categoryId` / `syncGroupId` optionnels).
3. `full_water_surface_catalog_v0.json` — options explicites, 2 frames, 3 refs (ordre cross → isolated → horizontal).

## 8. Schéma `empty_surface_catalog_v0.json`

Trois clés `atlases`, `animations`, `presets` — tableaux vides. Indentation 2 espaces — voir Evidence A pour le texte exact.

## 9–10. Schémas minimal / full

Voir fichiers complets en Evidence Pack A. Le sample **full** aligne l’ordre des clés **atlas** sur le codec Lot 39 : `sortOrder` puis `categoryId` (le schéma indicatif du cahier avait l’ordre inverse ; la golden suit le **pretty-print du codec**).

## 11. Décision : ne pas modifier de code de production

Lot fixtures + tests uniquement.

## 12. Décision : ne pas modifier `ProjectManifest`

## 13. Décision : pas de golden writer / updater automatique

Les fixtures sont des fichiers statiques versionnés.

## 14. Décision : `JsonEncoder.withIndent('  ')`

## 15. Décision : newline finale sur chaque fixture

## 16–17. Minimal vs full (optionnels null / présents)

Documenté par les fichiers et tests 4, 9, 23.

## 18. Contenu nu sans enveloppe manifest

Pas de clé `surfaceCatalog` autour du JSON.

## 19–20. Pas de catégories Surface structurées / pas de `SurfacePresetKind`

Tests 16–17.

## 21–25. Tests, non-faits, manifest, generated, build_runner, autres packages

Voir sections 21–27 ci-dessous synthétiques ; preuves en commandes.

## 21. Ce qui a été testé

25 tests (golden, diagnostics post-decode, manifest minimal).

## 22. Ce que les tests prouvent

Équivalence fixture ↔ codec, stabilité round-trip, exemples propres pour diagnostics.

## 23. Ce qui n’a pas été fait

Intégration manifest, migration, runtime.

## 24. Pourquoi `ProjectManifest` n’a toujours pas été modifié

Hors périmètre : ce lot isole le contenu `ProjectSurfaceCatalog` en JSON nu pour servir de contrat de lecture ; l’enveloppe manifeste attend le Lot 48+.

## 25. Pourquoi aucun fichier generated n’a été créé

Aucun modèle `*.g.dart` / Freezed à (re)générer : uniquement JSON et tests.

## 26. Pourquoi aucun `build_runner` n’a été lancé

Aucun changement dans les sources générées.

## 27. Pourquoi aucun runtime / editor / gameplay / battle n’a été modifié

Lot limité à `map_core` — fixtures de test + rapport, sans intégration moteur ni outil.

## 28. Impact prochains lots

Référence stable pour l’intégration manifeste (Lot 48+).

## 29. Commandes lancées

`dart test test/project_surface_catalog_json_golden_samples_test.dart` ; régressions (section 31) ; `dart analyze` (section 32) ; `dart test` complet (section 33).

## 30. Résultat : test ciblé Lot 47

```

00:00 +0: loading test/project_surface_catalog_json_golden_samples_test.dart                                                                                                                           
00:00 +0: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON                                                                                                                  
00:00 +1: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON                                                                                                                  
00:00 +1: Surface catalog JSON golden samples (Lot 47) 2. empty fixture matches codec                                                                                                                  
00:00 +2: Surface catalog JSON golden samples (Lot 47) 2. empty fixture matches codec                                                                                                                  
00:00 +2: Surface catalog JSON golden samples (Lot 47) 3. empty fixture round-trip                                                                                                                     
00:00 +3: Surface catalog JSON golden samples (Lot 47) 3. empty fixture round-trip                                                                                                                     
00:00 +3: Surface catalog JSON golden samples (Lot 47) 4. minimal water fixture is valid JSON with expected structure                                                                                  
00:00 +4: Surface catalog JSON golden samples (Lot 47) 4. minimal water fixture is valid JSON with expected structure                                                                                  
00:00 +4: Surface catalog JSON golden samples (Lot 47) 5. minimal water fixture matches codec                                                                                                          
00:00 +5: Surface catalog JSON golden samples (Lot 47) 5. minimal water fixture matches codec                                                                                                          
00:00 +5: Surface catalog JSON golden samples (Lot 47) 6. minimal water fixture round-trip                                                                                                             
00:00 +6: Surface catalog JSON golden samples (Lot 47) 6. minimal water fixture round-trip                                                                                                             
00:00 +6: Surface catalog JSON golden samples (Lot 47) 7. minimal water: no error diagnostics                                                                                                          
00:00 +7: Surface catalog JSON golden samples (Lot 47) 7. minimal water: no error diagnostics                                                                                                          
00:00 +7: Surface catalog JSON golden samples (Lot 47) 8. minimal water: no unused resource diagnostics                                                                                                
00:00 +8: Surface catalog JSON golden samples (Lot 47) 8. minimal water: no unused resource diagnostics                                                                                                
00:00 +8: Surface catalog JSON golden samples (Lot 47) 9. full water fixture is valid JSON with expected structure                                                                                     
00:00 +9: Surface catalog JSON golden samples (Lot 47) 9. full water fixture is valid JSON with expected structure                                                                                     
00:00 +9: Surface catalog JSON golden samples (Lot 47) 10. full water fixture matches codec                                                                                                            
00:00 +10: Surface catalog JSON golden samples (Lot 47) 10. full water fixture matches codec                                                                                                           
00:00 +10: Surface catalog JSON golden samples (Lot 47) 11. full water fixture round-trip                                                                                                              
00:00 +11: Surface catalog JSON golden samples (Lot 47) 11. full water fixture round-trip                                                                                                              
00:00 +11: Surface catalog JSON golden samples (Lot 47) 12. full water: preset ref order is cross, isolated, horizontal                                                                                
00:00 +12: Surface catalog JSON golden samples (Lot 47) 12. full water: preset ref order is cross, isolated, horizontal                                                                                
00:00 +12: Surface catalog JSON golden samples (Lot 47) 13. full water: no error diagnostics                                                                                                           
00:00 +13: Surface catalog JSON golden samples (Lot 47) 13. full water: no error diagnostics                                                                                                           
00:00 +13: Surface catalog JSON golden samples (Lot 47) 14. full water: no unused resource diagnostics                                                                                                 
00:00 +14: Surface catalog JSON golden samples (Lot 47) 14. full water: no unused resource diagnostics                                                                                                 
00:00 +14: Surface catalog JSON golden samples (Lot 47) 15. fixtures contain no manifest wrapper keys (raw string)                                                                                     
00:00 +15: Surface catalog JSON golden samples (Lot 47) 15. fixtures contain no manifest wrapper keys (raw string)                                                                                     
00:00 +15: Surface catalog JSON golden samples (Lot 47) 16. fixtures contain no category list keys                                                                                                     
00:00 +16: Surface catalog JSON golden samples (Lot 47) 16. fixtures contain no category list keys                                                                                                     
00:00 +16: Surface catalog JSON golden samples (Lot 47) 17. fixtures contain no kind/surfaceKind/type as map keys (deep)                                                                               
00:00 +17: Surface catalog JSON golden samples (Lot 47) 17. fixtures contain no kind/surfaceKind/type as map keys (deep)                                                                               
00:00 +17: Surface catalog JSON golden samples (Lot 47) 18. fixtures end with newline                                                                                                                  
00:00 +18: Surface catalog JSON golden samples (Lot 47) 18. fixtures end with newline                                                                                                                  
00:00 +18: Surface catalog JSON golden samples (Lot 47) 19. fixtures match two-space pretty jsonEncode roundtrip                                                                                       
00:00 +19: Surface catalog JSON golden samples (Lot 47) 19. fixtures match two-space pretty jsonEncode roundtrip                                                                                       
00:00 +19: Surface catalog JSON golden samples (Lot 47) 20. each fixture is stable: decode->encode->pretty equals fixture                                                                              
00:00 +20: Surface catalog JSON golden samples (Lot 47) 20. each fixture is stable: decode->encode->pretty equals fixture                                                                              
00:00 +20: Surface catalog JSON golden samples (Lot 47) 21. water fixtures use layout columnsAreVariantsRowsAreFrames                                                                                  
00:00 +21: Surface catalog JSON golden samples (Lot 47) 21. water fixtures use layout columnsAreVariantsRowsAreFrames                                                                                  
00:00 +21: Surface catalog JSON golden samples (Lot 47) 22. water fixtures: sortOrder on every atlas, animation, preset                                                                                
00:00 +22: Surface catalog JSON golden samples (Lot 47) 22. water fixtures: sortOrder on every atlas, animation, preset                                                                                
00:00 +22: Surface catalog JSON golden samples (Lot 47) 23. minimal fixture omits null optional fields (categoryId, syncGroupId)                                                                       
00:00 +23: Surface catalog JSON golden samples (Lot 47) 23. minimal fixture omits null optional fields (categoryId, syncGroupId)                                                                       
00:00 +23: Surface catalog JSON golden samples (Lot 47) 24. only public map_core import for package (no src/)                                                                                          
00:00 +24: Surface catalog JSON golden samples (Lot 47) 24. only public map_core import for package (no src/)                                                                                          
00:00 +24: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest has no surface persistence keys (Lot 47)                                                                                   
00:00 +25: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest has no surface persistence keys (Lot 47)                                                                                   
00:00 +25: All tests passed!                                                                                                                                                                           
```

## 31. Régressions (sorties intégrales)

### `test/project_surface_catalog_json_codec_test.dart`

```

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



## 32. `dart analyze`

```
Analyzing project_surface_catalog_json_golden_samples_test.dart, project_surface_catalog_json_codec_test.dart, project_surface_catalog_test.dart, surface_catalog_diagnostics_test.dart, surface_catalog_unused_diagnostics_test.dart, surface_catalog_authoring_diagnostics_test.dart, surface_model_entrypoint_test.dart...
No issues found!
```

## 33. `dart test` complet

- Commande : `cd packages/map_core && /opt/homebrew/bin/dart test`
- Ligne finale : `+1133: All tests passed!`
- Total : **1133**

## 34. Points de vigilance

Toute évolution d’ordre de clés dans les codecs enfants peut exiger une mise à jour des golden (hors scope implicite).

## 35. Autocritique

Le schéma « full » du prompt d’origine pour l’atlas (`categoryId` avant `sortOrder`) a été ajusté pour coller au codec Lot 39 ; c’est documenté en §9–10.

## 36. Prompt discutable

Désalignement mineur ordre de clés atlas entre schéma indicatif et encodeur réel — résolu en faveur du codec.

## 37. Auto-review indépendante

Checklist cahier Lot 47 (périmètre, `lib/`, manifest, codecs, API publique, fixtures, diagnostics, commandes) : entièrement cochée. Auto-check : aucune formulation interdite (liste cahier) n’est utilisée pour remplacer une preuve requise.

## 38. `git status --short` initial (avant travail Lot 47 sur ce worktree)

```text
M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/standard_path_preset_vertical_atlas_builder.dart
?? packages/map_core/test/standard_path_preset_vertical_atlas_builder_test.dart
?? reports/surface/surface_engine_lot_15_standard_path_preset_vertical_atlas_builder.md
```

## 39. `git status --short` final

```text
?? packages/map_core/test/fixtures/
?? packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart
?? reports/surface/surface_engine_lot_47_surface_json_golden_samples.md
```

## 40. Distinction changements préexistants / Lot 47

- **Hors lot (lignes initial)** : modifications ou fichiers issus d’autres lots (ex. trace Lot 15 listée en initial) — ce n’est **pas** le livrable Lot 47.
- **Lot 47** (chemins autorisés uniquement) : `test/fixtures/surface_catalog_json/empty_surface_catalog_v0.json`, `minimal_water_surface_catalog_v0.json`, `full_water_surface_catalog_v0.json`, `test/project_surface_catalog_json_golden_samples_test.dart`, `reports/surface/surface_engine_lot_47_surface_json_golden_samples.md`. Aucun `lib/`, aucun `map_core.dart`, aucun codec des lots 39–46 modifié.

## 41. Evidence Pack complet

### A. Fichiers créés (contenu intégral)

#### `empty_surface_catalog_v0.json`

```json
{
  "atlases": [],
  "animations": [],
  "presets": []
}
```

#### `minimal_water_surface_catalog_v0.json`

```json
{
  "atlases": [
    {
      "id": "water-atlas",
      "name": "Water Atlas",
      "tilesetId": "nature-tileset",
      "geometry": {
        "tileSize": {
          "width": 32,
          "height": 32
        },
        "gridSize": {
          "columns": 23,
          "rows": 32
        },
        "layout": "columnsAreVariantsRowsAreFrames"
      },
      "sortOrder": 0
    }
  ],
  "animations": [
    {
      "id": "water-isolated-loop",
      "name": "Water Isolated Loop",
      "timeline": {
        "frames": [
          {
            "tileRef": {
              "atlasId": "water-atlas",
              "column": 0,
              "row": 0
            },
            "durationMs": 120
          }
        ]
      },
      "sortOrder": 0
    }
  ],
  "presets": [
    {
      "id": "water-surface",
      "name": "Water Surface",
      "variantAnimations": {
        "refs": [
          {
            "role": "isolated",
            "animationId": "water-isolated-loop"
          }
        ]
      },
      "sortOrder": 0
    }
  ]
}
```

#### `full_water_surface_catalog_v0.json`

```json
{
  "atlases": [
    {
      "id": "water-atlas",
      "name": "Water Atlas",
      "tilesetId": "nature-tileset",
      "geometry": {
        "tileSize": {
          "width": 32,
          "height": 32
        },
        "gridSize": {
          "columns": 23,
          "rows": 32
        },
        "layout": "columnsAreVariantsRowsAreFrames"
      },
      "sortOrder": 10,
      "categoryId": "animated-surfaces"
    }
  ],
  "animations": [
    {
      "id": "water-loop",
      "name": "Water Loop",
      "timeline": {
        "frames": [
          {
            "tileRef": {
              "atlasId": "water-atlas",
              "column": 0,
              "row": 0
            },
            "durationMs": 120
          },
          {
            "tileRef": {
              "atlasId": "water-atlas",
              "column": 0,
              "row": 1
            },
            "durationMs": 120
          }
        ]
      },
      "syncGroupId": "water",
      "categoryId": "animated-surfaces",
      "sortOrder": 20
    }
  ],
  "presets": [
    {
      "id": "water-surface",
      "name": "Water Surface",
      "variantAnimations": {
        "refs": [
          {
            "role": "cross",
            "animationId": "water-loop"
          },
          {
            "role": "isolated",
            "animationId": "water-loop"
          },
          {
            "role": "horizontal",
            "animationId": "water-loop"
          }
        ]
      },
      "categoryId": "animated-surfaces",
      "sortOrder": 30
    }
  ]
}
```

#### `project_surface_catalog_json_golden_samples_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Surface catalog JSON golden samples (Lot 47)', () {
    const manifestKeys = <String>[
      'surfaceCatalog',
      'surfaceDefinitions',
      'surfaceAtlases',
      'surfaceAnimations',
      'surfacePresets',
      'surfaceCategories',
    ];

    const categoryListKeys = <String>['categories', 'surfaceCategories'];

    const forbiddenKindKeys = <String>['surfaceKind', 'presetKind', 'kind', 'type'];

    test('1. empty fixture is valid JSON', () {
      final raw = _readFixture('empty_surface_catalog_v0.json');
      final o = jsonDecode(raw);
      expect(o, isA<Map<String, Object?>>());
      final m = o as Map<String, Object?>;
      expect(m.keys.toSet(), <String>{'atlases', 'animations', 'presets'});
      expect(m['atlases'], isA<List>());
      expect(m['animations'], isA<List>());
      expect(m['presets'], isA<List>());
      expect(m['atlases'], isEmpty);
      expect(m['animations'], isEmpty);
      expect(m['presets'], isEmpty);
    });

    test('2. empty fixture matches codec', () {
      final catalog = ProjectSurfaceCatalog();
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
      final fixture = _readFixture('empty_surface_catalog_v0.json');
      expect(pretty, fixture);
    });

    test('3. empty fixture round-trip', () {
      final fixture = _readFixture('empty_surface_catalog_v0.json');
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('empty_surface_catalog_v0.json'),
      );
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
      expect(pretty, fixture);
    });

    test('4. minimal water fixture is valid JSON with expected structure', () {
      final raw = _readFixture('minimal_water_surface_catalog_v0.json');
      final m = jsonDecode(raw) as Map<String, Object?>;
      expect((m['atlases'] as List).length, 1);
      expect((m['animations'] as List).length, 1);
      expect((m['presets'] as List).length, 1);
      final a0 = (m['atlases']! as List)[0] as Map<String, Object?>;
      final n0 = (m['animations']! as List)[0] as Map<String, Object?>;
      final p0 = (m['presets']! as List)[0] as Map<String, Object?>;
      expect(a0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('syncGroupId'), isFalse);
      expect(p0.containsKey('categoryId'), isFalse);
      expect(a0['sortOrder'], 0);
      expect(n0['sortOrder'], 0);
      expect(p0['sortOrder'], 0);
    });

    test('5. minimal water fixture matches codec', () {
      final catalog = _minimalWaterCatalog();
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
      final fixture = _readFixture('minimal_water_surface_catalog_v0.json');
      expect(pretty, fixture);
    });

    test('6. minimal water fixture round-trip', () {
      final fixture = _readFixture('minimal_water_surface_catalog_v0.json');
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
      );
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
      expect(pretty, fixture);
    });

    test('7. minimal water: no error diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
      );
      final r = diagnoseProjectSurfaceCatalog(c);
      expect(r.hasDiagnostics, isFalse);
    });

    test('8. minimal water: no unused resource diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
      );
      final r = diagnoseProjectSurfaceCatalogUnusedResources(c);
      expect(r.hasDiagnostics, isFalse);
    });

    test('9. full water fixture is valid JSON with expected structure', () {
      final raw = _readFixture('full_water_surface_catalog_v0.json');
      final m = jsonDecode(raw) as Map<String, Object?>;
      expect((m['atlases'] as List).length, 1);
      expect((m['animations'] as List).length, 1);
      expect((m['presets'] as List).length, 1);
      final a0 = (m['atlases']! as List)[0] as Map<String, Object?>;
      final n0 = (m['animations']! as List)[0] as Map<String, Object?>;
      final p0 = (m['presets']! as List)[0] as Map<String, Object?>;
      expect(a0['categoryId'], 'animated-surfaces');
      expect(n0['syncGroupId'], 'water');
      expect(n0['categoryId'], 'animated-surfaces');
      expect(p0['categoryId'], 'animated-surfaces');
      final frames = (n0['timeline']! as Map)['frames']! as List;
      expect(frames.length, 2);
      final refs = (p0['variantAnimations']! as Map)['refs']! as List;
      expect(refs.length, 3);
    });

    test('10. full water fixture matches codec', () {
      final catalog = _fullWaterCatalog();
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
      final fixture = _readFixture('full_water_surface_catalog_v0.json');
      expect(pretty, fixture);
    });

    test('11. full water fixture round-trip', () {
      final fixture = _readFixture('full_water_surface_catalog_v0.json');
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
      expect(pretty, fixture);
    });

    test('12. full water: preset ref order is cross, isolated, horizontal', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      final roles = c.presets.first.variantAnimations.refs
          .map((r) => r.role)
          .toList();
      expect(roles, [
        SurfaceVariantRole.cross,
        SurfaceVariantRole.isolated,
        SurfaceVariantRole.horizontal,
      ]);
    });

    test('13. full water: no error diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      expect(diagnoseProjectSurfaceCatalog(c).hasDiagnostics, isFalse);
    });

    test('14. full water: no unused resource diagnostics', () {
      final c = decodeProjectSurfaceCatalog(
        _readFixtureJson('full_water_surface_catalog_v0.json'),
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(c).hasDiagnostics,
        isFalse,
      );
    });

    test('15. fixtures contain no manifest wrapper keys (raw string)', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(f);
        for (final k in manifestKeys) {
          expect(s.contains('"$k"'), isFalse, reason: '$f must not key $k');
        }
      }
    });

    test('16. fixtures contain no category list keys', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(f);
        for (final k in categoryListKeys) {
          expect(s.contains('"$k"'), isFalse, reason: '$f $k');
        }
      }
    });

    test('17. fixtures contain no kind/surfaceKind/type as map keys (deep)', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = jsonDecode(_readFixture(f)) as Object?;
        expect(_mapContainsAnyKeyFrom(o, forbiddenKindKeys.toSet()), isFalse);
      }
    });

    test('18. fixtures end with newline', () {
      for (final f in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(f);
        expect(s.endsWith('\n'), isTrue, reason: f);
      }
    });

    test('19. fixtures match two-space pretty jsonEncode roundtrip', () {
      for (final name in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final raw = _readFixture(name);
        final decoded = jsonDecode(raw) as Object?;
        const encoder = JsonEncoder.withIndent('  ');
        final repretty = _withTrailingNewline(encoder.convert(decoded));
        expect(repretty, raw, reason: name);
      }
    });

    test('20. each fixture is stable: decode->encode->pretty equals fixture', () {
      for (final name in const [
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final raw = _readFixture(name);
        final m = _readFixtureJson(name);
        final c = decodeProjectSurfaceCatalog(m);
        final out = _prettyJson(encodeProjectSurfaceCatalog(c));
        expect(out, raw, reason: name);
      }
    });

    test('21. water fixtures use layout columnsAreVariantsRowsAreFrames', () {
      for (final name in const [
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final s = _readFixture(name);
        expect(
          s.contains('columnsAreVariantsRowsAreFrames'),
          isTrue,
          reason: name,
        );
        expect(s.contains('"grid"'), isFalse, reason: name);
      }
    });

    test('22. water fixtures: sortOrder on every atlas, animation, preset', () {
      for (final name in const [
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final m = jsonDecode(_readFixture(name)) as Map<String, Object?>;
        for (final listKey in const ['atlases', 'animations', 'presets']) {
          for (final item in m[listKey]! as List) {
            final o = item as Map<String, Object?>;
            expect(o.containsKey('sortOrder'), isTrue, reason: '$name $listKey');
          }
        }
      }
    });

    test('23. minimal fixture omits null optional fields (categoryId, syncGroupId)', () {
      final m = _readFixtureJson('minimal_water_surface_catalog_v0.json');
      final a0 = (m['atlases']! as List)[0]! as Map<String, Object?>;
      final n0 = (m['animations']! as List)[0]! as Map<String, Object?>;
      final p0 = (m['presets']! as List)[0]! as Map<String, Object?>;
      expect(a0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('categoryId'), isFalse);
      expect(n0.containsKey('syncGroupId'), isFalse);
      expect(p0.containsKey('categoryId'), isFalse);
    });

    test('24. only public map_core import for package (no src/)', () {
      // Ce fichier n'importe que `package:map_core/map_core.dart` (aucun `package:map_core/src/`).
      expect(encodeProjectSurfaceCatalog(_minimalWaterCatalog()), isA<Map<String, Object?>>());
    });

    test('25. ProjectManifest has no surface persistence keys (Lot 47)', () {
      const manifest = ProjectManifest(
        name: 'L47',
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
  });
}

String _fixturePath(String name) => 'test/fixtures/surface_catalog_json/$name';

String _readFixture(String name) => File(_fixturePath(name)).readAsStringSync();

Map<String, Object?> _readFixtureJson(String name) {
  return jsonDecode(_readFixture(name)) as Map<String, Object?>;
}

String _prettyJson(Map<String, Object?> json) {
  const encoder = JsonEncoder.withIndent('  ');
  return _withTrailingNewline(encoder.convert(json));
}

String _withTrailingNewline(String value) {
  if (value.endsWith('\n')) {
    return value;
  }
  return '$value\n';
}

/// Parcourt maps JSON ; ne considère que les clés de map (pas le contenu des strings).
bool _mapContainsAnyKeyFrom(Object? o, Set<String> forbidden) {
  if (o is Map) {
    for (final e in o.entries) {
      if (e.key is String && forbidden.contains(e.key! as String)) {
        return true;
      }
      if (_mapContainsAnyKeyFrom(e.value, forbidden)) {
        return true;
      }
    }
  } else if (o is List) {
    for (final e in o) {
      if (_mapContainsAnyKeyFrom(e, forbidden)) {
        return true;
      }
    }
  }
  return false;
}

SurfaceAtlasGeometry _sharedWaterGeometry() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceAtlas _waterAtlas({
  String id = 'water-atlas',
  String name = 'Water Atlas',
  String tilesetId = 'nature-tileset',
  String? categoryId = 'animated-surfaces',
  int sortOrder = 10,
}) {
  return ProjectSurfaceAtlas(
    id: id,
    name: name,
    tilesetId: tilesetId,
    geometry: _sharedWaterGeometry(),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectSurfaceAnimation _waterAnimation({
  String id = 'water-loop',
  String name = 'Water Loop',
  int sortOrder = 20,
  String? syncGroupId = 'water',
  String? categoryId = 'animated-surfaces',
  bool twoFrames = true,
  String atlasId = 'water-atlas',
}) {
  return ProjectSurfaceAnimation(
    id: id,
    name: name,
    timeline: SurfaceAnimationTimeline(
      frames: twoFrames
          ? [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: 0,
                  row: 0,
                ),
                durationMs: 120,
              ),
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: 0,
                  row: 1,
                ),
                durationMs: 120,
              ),
            ]
          : [
              SurfaceAnimationFrame(
                tileRef: SurfaceAtlasTileRef(
                  atlasId: atlasId,
                  column: 0,
                  row: 0,
                ),
                durationMs: 120,
              ),
            ],
    ),
    syncGroupId: syncGroupId,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectSurfacePreset _waterPreset({
  String id = 'water-surface',
  String name = 'Water Surface',
  String? categoryId = 'animated-surfaces',
  int sortOrder = 30,
  String animationId = 'water-loop',
  bool multiRef = true,
}) {
  final refs = multiRef
      ? <SurfaceVariantAnimationRef>[
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.cross,
            animationId: animationId,
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: animationId,
          ),
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.horizontal,
            animationId: animationId,
          ),
        ]
      : <SurfaceVariantAnimationRef>[
          SurfaceVariantAnimationRef(
            role: SurfaceVariantRole.isolated,
            animationId: animationId,
          ),
        ];
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

ProjectSurfaceCatalog _minimalWaterCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      _waterAtlas(
        categoryId: null,
        sortOrder: 0,
      ),
    ],
    animations: [
      _waterAnimation(
        id: 'water-isolated-loop',
        name: 'Water Isolated Loop',
        sortOrder: 0,
        syncGroupId: null,
        categoryId: null,
        twoFrames: false,
        atlasId: 'water-atlas',
      ),
    ],
    presets: [
      _waterPreset(
        categoryId: null,
        sortOrder: 0,
        animationId: 'water-isolated-loop',
        multiRef: false,
      ),
    ],
  );
}

ProjectSurfaceCatalog _fullWaterCatalog() {
  return ProjectSurfaceCatalog(
    atlases: [
      _waterAtlas(
        sortOrder: 10,
        categoryId: 'animated-surfaces',
      ),
    ],
    animations: [
      _waterAnimation(
        id: 'water-loop',
        name: 'Water Loop',
        sortOrder: 20,
        twoFrames: true,
      ),
    ],
    presets: [
      _waterPreset(
        sortOrder: 30,
        multiRef: true,
        animationId: 'water-loop',
      ),
    ],
  );
}
```

#### `surface_engine_lot_47_surface_json_golden_samples.md`

Cinquième fichier créé : le présent document. Le texte intégral **hors** section 42 (Métacopie) est constitué des sections 1–41 ; la **section 42** du fichier enregistré sur disque contient en bloc le document entier **avant** l’ajout de la section 42 (métacopie intégrale, preuve reproductible de l’intégralité du `.md`).

### B. Fichiers modifiés

Aucun.

### C. Diffs `/dev/null`

#### C.1 `empty_surface_catalog_v0.json`

```diff
diff --git a/packages/map_core/test/fixtures/surface_catalog_json/empty_surface_catalog_v0.json b/packages/map_core/test/fixtures/surface_catalog_json/empty_surface_catalog_v0.json
new file mode 100644
index 00000000..336c650c
--- /dev/null
+++ b/packages/map_core/test/fixtures/surface_catalog_json/empty_surface_catalog_v0.json
@@ -0,0 +1,5 @@
+{
+  "atlases": [],
+  "animations": [],
+  "presets": []
+}
```

#### C.2 `minimal_water_surface_catalog_v0.json`

```diff
diff --git a/packages/map_core/test/fixtures/surface_catalog_json/minimal_water_surface_catalog_v0.json b/packages/map_core/test/fixtures/surface_catalog_json/minimal_water_surface_catalog_v0.json
new file mode 100644
index 00000000..3a64f399
--- /dev/null
+++ b/packages/map_core/test/fixtures/surface_catalog_json/minimal_water_surface_catalog_v0.json
@@ -0,0 +1,55 @@
+{
+  "atlases": [
+    {
+      "id": "water-atlas",
+      "name": "Water Atlas",
+      "tilesetId": "nature-tileset",
+      "geometry": {
+        "tileSize": {
+          "width": 32,
+          "height": 32
+        },
+        "gridSize": {
+          "columns": 23,
+          "rows": 32
+        },
+        "layout": "columnsAreVariantsRowsAreFrames"
+      },
+      "sortOrder": 0
+    }
+  ],
+  "animations": [
+    {
+      "id": "water-isolated-loop",
+      "name": "Water Isolated Loop",
+      "timeline": {
+        "frames": [
+          {
+            "tileRef": {
+              "atlasId": "water-atlas",
+              "column": 0,
+              "row": 0
+            },
+            "durationMs": 120
+          }
+        ]
+      },
+      "sortOrder": 0
+    }
+  ],
+  "presets": [
+    {
+      "id": "water-surface",
+      "name": "Water Surface",
+      "variantAnimations": {
+        "refs": [
+          {
+            "role": "isolated",
+            "animationId": "water-isolated-loop"
+          }
+        ]
+      },
+      "sortOrder": 0
+    }
+  ]
+}
```

#### C.3 `full_water_surface_catalog_v0.json`

```diff
diff --git a/packages/map_core/test/fixtures/surface_catalog_json/full_water_surface_catalog_v0.json b/packages/map_core/test/fixtures/surface_catalog_json/full_water_surface_catalog_v0.json
new file mode 100644
index 00000000..57237bfa
--- /dev/null
+++ b/packages/map_core/test/fixtures/surface_catalog_json/full_water_surface_catalog_v0.json
@@ -0,0 +1,75 @@
+{
+  "atlases": [
+    {
+      "id": "water-atlas",
+      "name": "Water Atlas",
+      "tilesetId": "nature-tileset",
+      "geometry": {
+        "tileSize": {
+          "width": 32,
+          "height": 32
+        },
+        "gridSize": {
+          "columns": 23,
+          "rows": 32
+        },
+        "layout": "columnsAreVariantsRowsAreFrames"
+      },
+      "sortOrder": 10,
+      "categoryId": "animated-surfaces"
+    }
+  ],
+  "animations": [
+    {
+      "id": "water-loop",
+      "name": "Water Loop",
+      "timeline": {
+        "frames": [
+          {
+            "tileRef": {
+              "atlasId": "water-atlas",
+              "column": 0,
+              "row": 0
+            },
+            "durationMs": 120
+          },
+          {
+            "tileRef": {
+              "atlasId": "water-atlas",
+              "column": 0,
+              "row": 1
+            },
+            "durationMs": 120
+          }
+        ]
+      },
+      "syncGroupId": "water",
+      "categoryId": "animated-surfaces",
+      "sortOrder": 20
+    }
+  ],
+  "presets": [
+    {
+      "id": "water-surface",
+      "name": "Water Surface",
+      "variantAnimations": {
+        "refs": [
+          {
+            "role": "cross",
+            "animationId": "water-loop"
+          },
+          {
+            "role": "isolated",
+            "animationId": "water-loop"
+          },
+          {
+            "role": "horizontal",
+            "animationId": "water-loop"
+          }
+        ]
+      },
+      "categoryId": "animated-surfaces",
+      "sortOrder": 30
+    }
+  ]
+}
```

#### C.4 `project_surface_catalog_json_golden_samples_test.dart`

```diff
diff --git a/packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart b/packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart
new file mode 100644
index 00000000..2d99afb5
--- /dev/null
+++ b/packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart
@@ -0,0 +1,524 @@
+import 'dart:convert';
+import 'dart:io';
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('Surface catalog JSON golden samples (Lot 47)', () {
+    const manifestKeys = <String>[
+      'surfaceCatalog',
+      'surfaceDefinitions',
+      'surfaceAtlases',
+      'surfaceAnimations',
+      'surfacePresets',
+      'surfaceCategories',
+    ];
+
+    const categoryListKeys = <String>['categories', 'surfaceCategories'];
+
+    const forbiddenKindKeys = <String>['surfaceKind', 'presetKind', 'kind', 'type'];
+
+    test('1. empty fixture is valid JSON', () {
+      final raw = _readFixture('empty_surface_catalog_v0.json');
+      final o = jsonDecode(raw);
+      expect(o, isA<Map<String, Object?>>());
+      final m = o as Map<String, Object?>;
+      expect(m.keys.toSet(), <String>{'atlases', 'animations', 'presets'});
+      expect(m['atlases'], isA<List>());
+      expect(m['animations'], isA<List>());
+      expect(m['presets'], isA<List>());
+      expect(m['atlases'], isEmpty);
+      expect(m['animations'], isEmpty);
+      expect(m['presets'], isEmpty);
+    });
+
+    test('2. empty fixture matches codec', () {
+      final catalog = ProjectSurfaceCatalog();
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
+      final fixture = _readFixture('empty_surface_catalog_v0.json');
+      expect(pretty, fixture);
+    });
+
+    test('3. empty fixture round-trip', () {
+      final fixture = _readFixture('empty_surface_catalog_v0.json');
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('empty_surface_catalog_v0.json'),
+      );
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
+      expect(pretty, fixture);
+    });
+
+    test('4. minimal water fixture is valid JSON with expected structure', () {
+      final raw = _readFixture('minimal_water_surface_catalog_v0.json');
+      final m = jsonDecode(raw) as Map<String, Object?>;
+      expect((m['atlases'] as List).length, 1);
+      expect((m['animations'] as List).length, 1);
+      expect((m['presets'] as List).length, 1);
+      final a0 = (m['atlases']! as List)[0] as Map<String, Object?>;
+      final n0 = (m['animations']! as List)[0] as Map<String, Object?>;
+      final p0 = (m['presets']! as List)[0] as Map<String, Object?>;
+      expect(a0.containsKey('categoryId'), isFalse);
+      expect(n0.containsKey('categoryId'), isFalse);
+      expect(n0.containsKey('syncGroupId'), isFalse);
+      expect(p0.containsKey('categoryId'), isFalse);
+      expect(a0['sortOrder'], 0);
+      expect(n0['sortOrder'], 0);
+      expect(p0['sortOrder'], 0);
+    });
+
+    test('5. minimal water fixture matches codec', () {
+      final catalog = _minimalWaterCatalog();
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
+      final fixture = _readFixture('minimal_water_surface_catalog_v0.json');
+      expect(pretty, fixture);
+    });
+
+    test('6. minimal water fixture round-trip', () {
+      final fixture = _readFixture('minimal_water_surface_catalog_v0.json');
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
+      );
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
+      expect(pretty, fixture);
+    });
+
+    test('7. minimal water: no error diagnostics', () {
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
+      );
+      final r = diagnoseProjectSurfaceCatalog(c);
+      expect(r.hasDiagnostics, isFalse);
+    });
+
+    test('8. minimal water: no unused resource diagnostics', () {
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('minimal_water_surface_catalog_v0.json'),
+      );
+      final r = diagnoseProjectSurfaceCatalogUnusedResources(c);
+      expect(r.hasDiagnostics, isFalse);
+    });
+
+    test('9. full water fixture is valid JSON with expected structure', () {
+      final raw = _readFixture('full_water_surface_catalog_v0.json');
+      final m = jsonDecode(raw) as Map<String, Object?>;
+      expect((m['atlases'] as List).length, 1);
+      expect((m['animations'] as List).length, 1);
+      expect((m['presets'] as List).length, 1);
+      final a0 = (m['atlases']! as List)[0] as Map<String, Object?>;
+      final n0 = (m['animations']! as List)[0] as Map<String, Object?>;
+      final p0 = (m['presets']! as List)[0] as Map<String, Object?>;
+      expect(a0['categoryId'], 'animated-surfaces');
+      expect(n0['syncGroupId'], 'water');
+      expect(n0['categoryId'], 'animated-surfaces');
+      expect(p0['categoryId'], 'animated-surfaces');
+      final frames = (n0['timeline']! as Map)['frames']! as List;
+      expect(frames.length, 2);
+      final refs = (p0['variantAnimations']! as Map)['refs']! as List;
+      expect(refs.length, 3);
+    });
+
+    test('10. full water fixture matches codec', () {
+      final catalog = _fullWaterCatalog();
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(catalog));
+      final fixture = _readFixture('full_water_surface_catalog_v0.json');
+      expect(pretty, fixture);
+    });
+
+    test('11. full water fixture round-trip', () {
+      final fixture = _readFixture('full_water_surface_catalog_v0.json');
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('full_water_surface_catalog_v0.json'),
+      );
+      final pretty = _prettyJson(encodeProjectSurfaceCatalog(c));
+      expect(pretty, fixture);
+    });
+
+    test('12. full water: preset ref order is cross, isolated, horizontal', () {
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('full_water_surface_catalog_v0.json'),
+      );
+      final roles = c.presets.first.variantAnimations.refs
+          .map((r) => r.role)
+          .toList();
+      expect(roles, [
+        SurfaceVariantRole.cross,
+        SurfaceVariantRole.isolated,
+        SurfaceVariantRole.horizontal,
+      ]);
+    });
+
+    test('13. full water: no error diagnostics', () {
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('full_water_surface_catalog_v0.json'),
+      );
+      expect(diagnoseProjectSurfaceCatalog(c).hasDiagnostics, isFalse);
+    });
+
+    test('14. full water: no unused resource diagnostics', () {
+      final c = decodeProjectSurfaceCatalog(
+        _readFixtureJson('full_water_surface_catalog_v0.json'),
+      );
+      expect(
+        diagnoseProjectSurfaceCatalogUnusedResources(c).hasDiagnostics,
+        isFalse,
+      );
+    });
+
+    test('15. fixtures contain no manifest wrapper keys (raw string)', () {
+      for (final f in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final s = _readFixture(f);
+        for (final k in manifestKeys) {
+          expect(s.contains('"$k"'), isFalse, reason: '$f must not key $k');
+        }
+      }
+    });
+
+    test('16. fixtures contain no category list keys', () {
+      for (final f in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final s = _readFixture(f);
+        for (final k in categoryListKeys) {
+          expect(s.contains('"$k"'), isFalse, reason: '$f $k');
+        }
+      }
+    });
+
+    test('17. fixtures contain no kind/surfaceKind/type as map keys (deep)', () {
+      for (final f in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final o = jsonDecode(_readFixture(f)) as Object?;
+        expect(_mapContainsAnyKeyFrom(o, forbiddenKindKeys.toSet()), isFalse);
+      }
+    });
+
+    test('18. fixtures end with newline', () {
+      for (final f in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final s = _readFixture(f);
+        expect(s.endsWith('\n'), isTrue, reason: f);
+      }
+    });
+
+    test('19. fixtures match two-space pretty jsonEncode roundtrip', () {
+      for (final name in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final raw = _readFixture(name);
+        final decoded = jsonDecode(raw) as Object?;
+        const encoder = JsonEncoder.withIndent('  ');
+        final repretty = _withTrailingNewline(encoder.convert(decoded));
+        expect(repretty, raw, reason: name);
+      }
+    });
+
+    test('20. each fixture is stable: decode->encode->pretty equals fixture', () {
+      for (final name in const [
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final raw = _readFixture(name);
+        final m = _readFixtureJson(name);
+        final c = decodeProjectSurfaceCatalog(m);
+        final out = _prettyJson(encodeProjectSurfaceCatalog(c));
+        expect(out, raw, reason: name);
+      }
+    });
+
+    test('21. water fixtures use layout columnsAreVariantsRowsAreFrames', () {
+      for (final name in const [
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final s = _readFixture(name);
+        expect(
+          s.contains('columnsAreVariantsRowsAreFrames'),
+          isTrue,
+          reason: name,
+        );
+        expect(s.contains('"grid"'), isFalse, reason: name);
+      }
+    });
+
+    test('22. water fixtures: sortOrder on every atlas, animation, preset', () {
+      for (final name in const [
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final m = jsonDecode(_readFixture(name)) as Map<String, Object?>;
+        for (final listKey in const ['atlases', 'animations', 'presets']) {
+          for (final item in m[listKey]! as List) {
+            final o = item as Map<String, Object?>;
+            expect(o.containsKey('sortOrder'), isTrue, reason: '$name $listKey');
+          }
+        }
+      }
+    });
+
+    test('23. minimal fixture omits null optional fields (categoryId, syncGroupId)', () {
+      final m = _readFixtureJson('minimal_water_surface_catalog_v0.json');
+      final a0 = (m['atlases']! as List)[0]! as Map<String, Object?>;
+      final n0 = (m['animations']! as List)[0]! as Map<String, Object?>;
+      final p0 = (m['presets']! as List)[0]! as Map<String, Object?>;
+      expect(a0.containsKey('categoryId'), isFalse);
+      expect(n0.containsKey('categoryId'), isFalse);
+      expect(n0.containsKey('syncGroupId'), isFalse);
+      expect(p0.containsKey('categoryId'), isFalse);
+    });
+
+    test('24. only public map_core import for package (no src/)', () {
+      // Ce fichier n'importe que `package:map_core/map_core.dart` (aucun `package:map_core/src/`).
+      expect(encodeProjectSurfaceCatalog(_minimalWaterCatalog()), isA<Map<String, Object?>>());
+    });
+
+    test('25. ProjectManifest has no surface persistence keys (Lot 47)', () {
+      const manifest = ProjectManifest(
+        name: 'L47',
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
+  });
+}
+
+String _fixturePath(String name) => 'test/fixtures/surface_catalog_json/$name';
+
+String _readFixture(String name) => File(_fixturePath(name)).readAsStringSync();
+
+Map<String, Object?> _readFixtureJson(String name) {
+  return jsonDecode(_readFixture(name)) as Map<String, Object?>;
+}
+
+String _prettyJson(Map<String, Object?> json) {
+  const encoder = JsonEncoder.withIndent('  ');
+  return _withTrailingNewline(encoder.convert(json));
+}
+
+String _withTrailingNewline(String value) {
+  if (value.endsWith('\n')) {
+    return value;
+  }
+  return '$value\n';
+}
+
+/// Parcourt maps JSON ; ne considère que les clés de map (pas le contenu des strings).
+bool _mapContainsAnyKeyFrom(Object? o, Set<String> forbidden) {
+  if (o is Map) {
+    for (final e in o.entries) {
+      if (e.key is String && forbidden.contains(e.key! as String)) {
+        return true;
+      }
+      if (_mapContainsAnyKeyFrom(e.value, forbidden)) {
+        return true;
+      }
+    }
+  } else if (o is List) {
+    for (final e in o) {
+      if (_mapContainsAnyKeyFrom(e, forbidden)) {
+        return true;
+      }
+    }
+  }
+  return false;
+}
+
+SurfaceAtlasGeometry _sharedWaterGeometry() {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+    gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
+    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+  );
+}
+
+ProjectSurfaceAtlas _waterAtlas({
+  String id = 'water-atlas',
+  String name = 'Water Atlas',
+  String tilesetId = 'nature-tileset',
+  String? categoryId = 'animated-surfaces',
+  int sortOrder = 10,
+}) {
+  return ProjectSurfaceAtlas(
+    id: id,
+    name: name,
+    tilesetId: tilesetId,
+    geometry: _sharedWaterGeometry(),
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}
+
+ProjectSurfaceAnimation _waterAnimation({
+  String id = 'water-loop',
+  String name = 'Water Loop',
+  int sortOrder = 20,
+  String? syncGroupId = 'water',
+  String? categoryId = 'animated-surfaces',
+  bool twoFrames = true,
+  String atlasId = 'water-atlas',
+}) {
+  return ProjectSurfaceAnimation(
+    id: id,
+    name: name,
+    timeline: SurfaceAnimationTimeline(
+      frames: twoFrames
+          ? [
+              SurfaceAnimationFrame(
+                tileRef: SurfaceAtlasTileRef(
+                  atlasId: atlasId,
+                  column: 0,
+                  row: 0,
+                ),
+                durationMs: 120,
+              ),
+              SurfaceAnimationFrame(
+                tileRef: SurfaceAtlasTileRef(
+                  atlasId: atlasId,
+                  column: 0,
+                  row: 1,
+                ),
+                durationMs: 120,
+              ),
+            ]
+          : [
+              SurfaceAnimationFrame(
+                tileRef: SurfaceAtlasTileRef(
+                  atlasId: atlasId,
+                  column: 0,
+                  row: 0,
+                ),
+                durationMs: 120,
+              ),
+            ],
+    ),
+    syncGroupId: syncGroupId,
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}
+
+ProjectSurfacePreset _waterPreset({
+  String id = 'water-surface',
+  String name = 'Water Surface',
+  String? categoryId = 'animated-surfaces',
+  int sortOrder = 30,
+  String animationId = 'water-loop',
+  bool multiRef = true,
+}) {
+  final refs = multiRef
+      ? <SurfaceVariantAnimationRef>[
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.cross,
+            animationId: animationId,
+          ),
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.isolated,
+            animationId: animationId,
+          ),
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.horizontal,
+            animationId: animationId,
+          ),
+        ]
+      : <SurfaceVariantAnimationRef>[
+          SurfaceVariantAnimationRef(
+            role: SurfaceVariantRole.isolated,
+            animationId: animationId,
+          ),
+        ];
+  return ProjectSurfacePreset(
+    id: id,
+    name: name,
+    variantAnimations: SurfaceVariantAnimationRefSet(refs: refs),
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}
+
+ProjectSurfaceCatalog _minimalWaterCatalog() {
+  return ProjectSurfaceCatalog(
+    atlases: [
+      _waterAtlas(
+        categoryId: null,
+        sortOrder: 0,
+      ),
+    ],
+    animations: [
+      _waterAnimation(
+        id: 'water-isolated-loop',
+        name: 'Water Isolated Loop',
+        sortOrder: 0,
+        syncGroupId: null,
+        categoryId: null,
+        twoFrames: false,
+        atlasId: 'water-atlas',
+      ),
+    ],
+    presets: [
+      _waterPreset(
+        categoryId: null,
+        sortOrder: 0,
+        animationId: 'water-isolated-loop',
+        multiRef: false,
+      ),
+    ],
+  );
+}
+
+ProjectSurfaceCatalog _fullWaterCatalog() {
+  return ProjectSurfaceCatalog(
+    atlases: [
+      _waterAtlas(
+        sortOrder: 10,
+        categoryId: 'animated-surfaces',
+      ),
+    ],
+    animations: [
+      _waterAnimation(
+        id: 'water-loop',
+        name: 'Water Loop',
+        sortOrder: 20,
+        twoFrames: true,
+      ),
+    ],
+    presets: [
+      _waterPreset(
+        sortOrder: 30,
+        multiRef: true,
+        animationId: 'water-loop',
+      ),
+    ],
+  );
+}
```

#### C.5 Rapport Lot 47 (exception cahier : diff unifié)

Un diff `/dev/null` → ce chemin recopierait chaque ligne du fichier avec préfixe `+` ; le détail est en section A (dont métacopie intégrale en §42) et les sorties en §30–33.

### D. Sorties de commandes

Sections 30–33.


````
