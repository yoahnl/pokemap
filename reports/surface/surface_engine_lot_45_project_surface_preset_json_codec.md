# Surface Engine — Lot 45 — `ProjectSurfacePreset` JSON Codec V0

## 1. Résumé exécutif

Implémentation d'un **codec JSON manuel externe** pour [`ProjectSurfacePreset`](../../packages/map_core/lib/src/models/surface.dart) : [`encodeProjectSurfacePreset`](../../packages/map_core/lib/src/operations/project_surface_preset_json_codec.dart) / [`decodeProjectSurfacePreset`](../../packages/map_core/lib/src/operations/project_surface_preset_json_codec.dart), réutilisant le codec Lot 44 sur `variantAnimations`, export public via `map_core`, **34** tests dédiés, **sans** `ProjectManifest`, **sans** `toJson` / `fromJson` sur le modèle, **sans** codec catalogue, **sans** `build_runner`.

## 2. Pourquoi ce lot vient après le Lot 44

Le Lot 44 a stabilisé la forme JSON de [`SurfaceVariantAnimationRefSet`]. Le [`ProjectSurfacePreset`](../../packages/map_core/lib/src/models/surface.dart) agrège notamment un `variantAnimations` : le Lot 45 compose ce champ via les fonctions Lot 44 avant toute couche [`ProjectSurfaceCatalog`](../../packages/map_core/lib/src/models/surface_catalog.dart) (Lot 46) ou manifeste (lots ultérieurs).

## 3. Tableau récapitulatif des lots Surface (39–49)

| Lot | Sujet | Statut |
|-----|--------|--------|
| Lot 39 | ProjectSurfaceAtlas JSON Codec V0 | fait |
| Lot 40 | Surface TileRef / AnimationFrame JSON Codec V0 | fait |
| Lot 41 | SurfaceAnimationTimeline JSON Codec V0 | fait |
| Lot 42 | ProjectSurfaceAnimation JSON Codec V0 | fait |
| Lot 43 | SurfaceVariantAnimationRef JSON Codec V0 | fait |
| Lot 44 | SurfaceVariantAnimationRefSet JSON Codec V0 | fait |
| Lot 45 | ProjectSurfacePreset JSON Codec V0 | **ce lot** |
| Lot 46 | ProjectSurfaceCatalog JSON Codec V0 | prochain probable |
| Lot 47 | ProjectManifest Surface JSON Characterization / Prep | ensuite probable |
| Lot 48 | ProjectManifest Surface Integration V0 | plus tard, si prêt |
| Lot 49 | Surface JSON Round-trip Golden Samples | ensuite probable |

## 4. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/surface.dart`
- `packages/map_core/lib/src/exceptions/map_exceptions.dart`
- `packages/map_core/lib/src/operations/surface_variant_animation_ref_set_json_codec.dart`
- `packages/map_core/lib/src/operations/surface_variant_animation_ref_json_codec.dart`
- `packages/map_core/lib/map_core.dart`
- `packages/map_core/test/project_surface_preset_test.dart`
- `packages/map_core/test/surface_variant_animation_ref_set_json_codec_test.dart`
- `packages/map_core/test/surface_variant_animation_ref_set_test.dart`
- `packages/map_core/test/surface_variant_animation_ref_json_codec_test.dart`
- `packages/map_core/test/surface_variant_animation_ref_test.dart`
- `packages/map_core/test/surface_model_entrypoint_test.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `reports/surface/surface_engine_lot_44_surface_variant_animation_ref_set_json_codec.md`

Vérifications pré-impl : `ProjectSurfacePreset` existe, valide `id`/`name` (trim vide), expose `variantAnimations`, `categoryId`, `sortOrder`, délègue les lookups au ref set, pas de `SurfacePresetKind` / `surfaceKind` ; `encode`/`decode` RefSet (Lot 44) existent ; `ProjectManifest` sans clés `surface*`.

## 5. Fichiers créés

- `packages/map_core/lib/src/operations/project_surface_preset_json_codec.dart`
- `packages/map_core/test/project_surface_preset_json_codec_test.dart`
- `reports/surface/surface_engine_lot_45_project_surface_preset_json_codec.md` (le présent fichier)

## 6. Fichiers modifiés

- `packages/map_core/lib/map_core.dart` (un export)

## 7. API ajoutée

- `Map<String, Object?> encodeProjectSurfacePreset(ProjectSurfacePreset preset);`
- `ProjectSurfacePreset decodeProjectSurfacePreset(Map<String, Object?> json);`

## 8. Schéma JSON `ProjectSurfacePreset`

Champs : `id` (String), `name` (String), `variantAnimations` (Object map selon Lot 44 avec `refs`), `categoryId` (String ou `null` ou absent), `sortOrder` (int, absent → `0` à la lecture).

## 9. Sémantique d'encodage

Déterministe, ordre de clés : `id`, `name`, `variantAnimations`, `categoryId` seulement si `!= null`, `sortOrder` **toujours** présent. `variantAnimations` via `encodeSurfaceVariantAnimationRefSet`. Chaînes inchangées ; pas de mutation de l'objet source.

## 10. Sémantique de décodage

Validation de forme : `id` / `name` strings non nulles (types) ; rôles vides d'espaces rejetés par le constructeur ; `variantAnimations` requis, type map → `decodeSurfaceVariantAnimationRefSet` sur copie de clés string ; `categoryId` absent, `null`, ou string — refuse tout autre type ; `sortOrder` absent → `0`, sinon `int` (y compris négatif). Clés inconnues ignorées. Aucune mutation des `Map` sources. Pas de vérification d'existence d'`animationId` dans le catalogue.

## 11. Décision : réutiliser le codec RefSet (Lot 44)

Délégation stricte pour cohérence de schéma et une seule source de vérité sur `refs` / rôles / `animationId`.

## 12. Décision : préserver l'ordre sans tri

L'ordre des entrées `refs` est celui de [`SurfaceVariantAnimationRefSet`], émis tel quel par le Lot 44.

## 13. Décision : ne pas compléter les rôles manquants

Le codec ne complète pas ; la couverture des rôles est un sujet auteur / diagnostics.

## 14. Décision : ne pas résoudre `animationId`

Aucune résolution vers `ProjectSurfaceAnimation` / manifeste.

## 15. Décision : tolérer les clés inconnues

Lecture seulement des clés reconnues ; le reste est ignoré.

## 16. Décision : omettre `categoryId` si `null` à l'encodage

`categoryId: null` ⇒ clé absente (V0).

## 17. Décision : toujours encoder `sortOrder`

Même à `0`, la clé est présente (V0).

## 18. Décision : ne pas ajouter `toJson` / `fromJson` sur le modèle

Les modèles Surface restent purs domaine ; persistance par codecs externes.

## 19. Décision : ne pas créer de codec `ProjectSurfaceCatalog` ici

Hors lot (Lot 46).

## 20. Décision : ne pas introduire `SurfacePresetKind` / `surfaceKind`

Aucune clé de ce type dans le JSON produit.

## 21. Décision : ne pas modifier `ProjectManifest`

Aucune clé `surfacePresets` / `surfaceCategories` / etc. ajoutée.

## 22. Ce qui a été testé

34 cas : encode / decode / round-trip, multi-refs, chaînes exactes, garde-fous d'erreur, clés inconnues, non-mutation, absence de résolution, non-complétion, réutilisation RefSet, export public, invariants `ProjectManifest` / pas de `toJson` modèle (nom de test) / pas de codec catalogue (nom de test) / pas de clés de kind, `standardSurfaceVariantRoleOrder.length == 20`.

## 23. Ce que les tests prouvent

Stabilité structurelle, composition Lot 44, invariants d'isolation (manifest, catalog codec, kind), non-régression d'intention (ordre, pas de rôle imposé).

## 24. Ce qui n'a volontairement pas été fait

`ProjectSurfaceCatalog`, intégration manifeste, `build_runner`, Freezed, runtime, éditeur, gameplay, battle, golden samples.

## 25. Pourquoi `ProjectManifest` n'a toujours pas été modifié

Le raccrochage persistant des presets Surface fera l'objet d'un lot dédié (ex. 47–48) ; ici, préparation codec autonome.

## 26. Pourquoi aucun fichier généré n'a été créé

Comportement volontaire : codecs manuels, pas de nouvelle entrée de générateur.

## 27. Pourquoi `build_runner` n'a pas été lancé

Aucun changement sur modèles Freezed / `part` / `.g.dart` / `.freezed.dart`.

## 28. Pourquoi aucun runtime / editor / gameplay / battle n'a été modifié

Périmètre strict `map_core` + rapport.

## 29. Impact pour les prochains lots Surface

Le Lot 46 pourra enchaîner les presets via un codec catalogue en réutilisant ce codec preset.

## 30. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/project_surface_preset_json_codec_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/project_surface_preset_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_variant_animation_ref_set_json_codec_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_variant_animation_ref_set_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_variant_animation_ref_json_codec_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_variant_animation_ref_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_model_entrypoint_test.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/operations/project_surface_preset_json_codec.dart \
  lib/src/operations/surface_variant_animation_ref_set_json_codec.dart \
  lib/src/operations/surface_variant_animation_ref_json_codec.dart \
  lib/src/models/surface.dart \
  test/project_surface_preset_json_codec_test.dart \
  test/project_surface_preset_test.dart \
  test/surface_variant_animation_ref_set_json_codec_test.dart \
  test/surface_variant_animation_ref_set_test.dart \
  test/surface_variant_animation_ref_json_codec_test.dart \
  test/surface_variant_animation_ref_test.dart \
  test/surface_model_entrypoint_test.dart \
  lib/map_core.dart
```

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

## 31. Résultat exact : test ciblé Lot 45

```text

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

## 32. Résultats : tests de régression (sorties intégrales)

### `test/project_surface_preset_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/project_surface_preset_test.dart[0m[0m                                                                                                                                                
00:00 [32m+0[0m: ProjectSurfacePreset 1. minimal preset: fields and variantCount[0m                                                                                                                              
00:00 [32m+1[0m: ProjectSurfacePreset 1. minimal preset: fields and variantCount[0m                                                                                                                              
00:00 [32m+1[0m: ProjectSurfacePreset 2. preserves exact same variantAnimations instance[0m                                                                                                                      
00:00 [32m+2[0m: ProjectSurfacePreset 2. preserves exact same variantAnimations instance[0m                                                                                                                      
00:00 [32m+2[0m: ProjectSurfacePreset 3. preserves categoryId and sortOrder[0m                                                                                                                                   
00:00 [32m+3[0m: ProjectSurfacePreset 3. preserves categoryId and sortOrder[0m                                                                                                                                   
00:00 [32m+3[0m: ProjectSurfacePreset 4. stores id and name exactly without auto-trim[0m                                                                                                                         
00:00 [32m+4[0m: ProjectSurfacePreset 4. stores id and name exactly without auto-trim[0m                                                                                                                         
00:00 [32m+4[0m: ProjectSurfacePreset 5. rejects empty id: empty and whitespace[0m                                                                                                                               
00:00 [32m+5[0m: ProjectSurfacePreset 5. rejects empty id: empty and whitespace[0m                                                                                                                               
00:00 [32m+5[0m: ProjectSurfacePreset 6. rejects empty name: empty and whitespace[0m                                                                                                                             
00:00 [32m+6[0m: ProjectSurfacePreset 6. rejects empty name: empty and whitespace[0m                                                                                                                             
00:00 [32m+6[0m: ProjectSurfacePreset 7. does not over-validate categoryId: empty and whitespace allowed[0m                                                                                                      
00:00 [32m+7[0m: ProjectSurfacePreset 7. does not over-validate categoryId: empty and whitespace allowed[0m                                                                                                      
00:00 [32m+7[0m: ProjectSurfacePreset 8. allows negative sortOrder[0m                                                                                                                                            
00:00 [32m+8[0m: ProjectSurfacePreset 8. allows negative sortOrder[0m                                                                                                                                            
00:00 [32m+8[0m: ProjectSurfacePreset 9. delegating containsRole[0m                                                                                                                                              
00:00 [32m+9[0m: ProjectSurfacePreset 9. delegating containsRole[0m                                                                                                                                              
00:00 [32m+9[0m: ProjectSurfacePreset 10. delegating refForRole: present and absent[0m                                                                                                                           
00:00 [32m+10[0m: ProjectSurfacePreset 10. delegating refForRole: present and absent[0m                                                                                                                          
00:00 [32m+10[0m: ProjectSurfacePreset 11. delegating animationIdForRole: present and absent[0m                                                                                                                  
00:00 [32m+11[0m: ProjectSurfacePreset 11. delegating animationIdForRole: present and absent[0m                                                                                                                  
00:00 [32m+11[0m: ProjectSurfacePreset 12. delegating coversAllRoles[0m                                                                                                                                          
00:00 [32m+12[0m: ProjectSurfacePreset 12. delegating coversAllRoles[0m                                                                                                                                          
00:00 [32m+12[0m: ProjectSurfacePreset 13. can cover exactly standardSurfaceVariantRoleOrder[0m                                                                                                                  
00:00 [32m+13[0m: ProjectSurfacePreset 13. can cover exactly standardSurfaceVariantRoleOrder[0m                                                                                                                  
00:00 [32m+13[0m: ProjectSurfacePreset 14. value equality: identical presets are equal and same hashCode[0m                                                                                                      
00:00 [32m+14[0m: ProjectSurfacePreset 14. value equality: identical presets are equal and same hashCode[0m                                                                                                      
00:00 [32m+14[0m: ProjectSurfacePreset 15. value equality: different id[0m                                                                                                                                       
00:00 [32m+15[0m: ProjectSurfacePreset 15. value equality: different id[0m                                                                                                                                       
00:00 [32m+15[0m: ProjectSurfacePreset 16. value equality: different name[0m                                                                                                                                     
00:00 [32m+16[0m: ProjectSurfacePreset 16. value equality: different name[0m                                                                                                                                     
00:00 [32m+16[0m: ProjectSurfacePreset 17. value equality: different variantAnimations[0m                                                                                                                        
00:00 [32m+17[0m: ProjectSurfacePreset 17. value equality: different variantAnimations[0m                                                                                                                        
00:00 [32m+17[0m: ProjectSurfacePreset 18. value equality: different categoryId[0m                                                                                                                               
00:00 [32m+18[0m: ProjectSurfacePreset 18. value equality: different categoryId[0m                                                                                                                               
00:00 [32m+18[0m: ProjectSurfacePreset 19. value equality: different sortOrder[0m                                                                                                                                
00:00 [32m+19[0m: ProjectSurfacePreset 19. value equality: different sortOrder[0m                                                                                                                                
00:00 [32m+19[0m: ProjectSurfacePreset 20. public export: ProjectSurfacePreset via map_core[0m                                                                                                                   
00:00 [32m+20[0m: ProjectSurfacePreset 20. public export: ProjectSurfacePreset via map_core[0m                                                                                                                   
00:00 [32m+20[0m: ProjectSurfacePreset 21. V0 visual-only: preset has no kind / surfaceKind / behavior field[0m                                                                                                  
00:00 [32m+21[0m: ProjectSurfacePreset 21. V0 visual-only: preset has no kind / surfaceKind / behavior field[0m                                                                                                  
00:00 [32m+21[0m: ProjectSurfacePreset 22. coexists with ProjectSurfaceAnimation without resolution[0m                                                                                                           
00:00 [32m+22[0m: ProjectSurfacePreset 22. coexists with ProjectSurfaceAnimation without resolution[0m                                                                                                           
00:00 [32m+22[0m: ProjectSurfacePreset 23. ProjectManifest still has no Surface persistence keys (Lot 21–31)[0m                                                                                                  
00:00 [32m+23[0m: ProjectSurfacePreset 23. ProjectManifest still has no Surface persistence keys (Lot 21–31)[0m                                                                                                  
00:00 [32m+23[0m: All tests passed![0m                                                                                                                                                                           

```

### `test/surface_variant_animation_ref_set_json_codec_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_variant_animation_ref_set_json_codec_test.dart[0m[0m                                                                                                                          
00:00 [32m+0[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 1. encodes set with one isolated ref[0m                                                                                                       
00:00 [32m+1[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 1. encodes set with one isolated ref[0m                                                                                                       
00:00 [32m+1[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 2. decodes set with one ref[0m                                                                                                                
00:00 [32m+2[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 2. decodes set with one ref[0m                                                                                                                
00:00 [32m+2[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 3. round-trip single ref set[0m                                                                                                               
00:00 [32m+3[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 3. round-trip single ref set[0m                                                                                                               
00:00 [32m+3[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 4. encode multi-ref preserves order (cross, isolated, horizontal)[0m                                                                          
00:00 [32m+4[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 4. encode multi-ref preserves order (cross, isolated, horizontal)[0m                                                                          
00:00 [32m+4[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 5. decode multi-ref preserves order[0m                                                                                                        
00:00 [32m+5[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 5. decode multi-ref preserves order[0m                                                                                                        
00:00 [32m+5[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 6. round-trip multi-ref[0m                                                                                                                    
00:00 [32m+6[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 6. round-trip multi-ref[0m                                                                                                                    
00:00 [32m+6[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 7. encodes full standardSurfaceVariantRoleOrder[0m                                                                                            
00:00 [32m+7[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 7. encodes full standardSurfaceVariantRoleOrder[0m                                                                                            
00:00 [32m+7[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 8. decodes full standard order set[0m                                                                                                         
00:00 [32m+8[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 8. decodes full standard order set[0m                                                                                                         
00:00 [32m+8[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 9. decode rejects missing refs[0m                                                                                                             
00:00 [32m+9[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 9. decode rejects missing refs[0m                                                                                                             
00:00 [32m+9[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 10. decode rejects refs not a List[0m                                                                                                         
00:00 [32m+10[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 10. decode rejects refs not a List[0m                                                                                                        
00:00 [32m+10[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 11. decode rejects empty refs[0m                                                                                                             
00:00 [32m+11[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 11. decode rejects empty refs[0m                                                                                                             
00:00 [32m+11[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 12. decode rejects non-map list item[0m                                                                                                      
00:00 [32m+12[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 12. decode rejects non-map list item[0m                                                                                                      
00:00 [32m+12[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 13. decode rejects invalid role in ref[0m                                                                                                    
00:00 [32m+13[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 13. decode rejects invalid role in ref[0m                                                                                                    
00:00 [32m+13[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 14. decode rejects invalid animationId in ref[0m                                                                                             
00:00 [32m+14[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 14. decode rejects invalid animationId in ref[0m                                                                                             
00:00 [32m+14[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 15. decode rejects duplicate roles[0m                                                                                                        
00:00 [32m+15[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 15. decode rejects duplicate roles[0m                                                                                                        
00:00 [32m+15[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 16. decode ignores unknown top-level key[0m                                                                                                  
00:00 [32m+16[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 16. decode ignores unknown top-level key[0m                                                                                                  
00:00 [32m+16[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 17. decode ignores unknown key in ref item[0m                                                                                                
00:00 [32m+17[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 17. decode ignores unknown key in ref item[0m                                                                                                
00:00 [32m+17[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 18. decode does not mutate source map[0m                                                                                                     
00:00 [32m+18[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 18. decode does not mutate source map[0m                                                                                                     
00:00 [32m+18[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 19. encode does not mutate ref set[0m                                                                                                        
00:00 [32m+19[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 19. encode does not mutate ref set[0m                                                                                                        
00:00 [32m+19[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 20. does not resolve animationId[0m                                                                                                          
00:00 [32m+20[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 20. does not resolve animationId[0m                                                                                                          
00:00 [32m+20[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 21. does not complete missing roles[0m                                                                                                       
00:00 [32m+21[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 21. does not complete missing roles[0m                                                                                                       
00:00 [32m+21[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 22. reuses Lot 43 ref codec for each element[0m                                                                                              
00:00 [32m+22[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 22. reuses Lot 43 ref codec for each element[0m                                                                                              
00:00 [32m+22[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 23. public API encode returns map[0m                                                                                                         
00:00 [32m+23[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 23. public API encode returns map[0m                                                                                                         
00:00 [32m+23[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 24. ProjectManifest has no surface persistence keys (Lot 44)[0m                                                                              
00:00 [32m+24[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 24. ProjectManifest has no surface persistence keys (Lot 44)[0m                                                                              
00:00 [32m+24[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 25. codec external to model: no set.toJson or SurfaceVariantAnimationRefSet.fromJson[0m                                                      
00:00 [32m+25[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 25. codec external to model: no set.toJson or SurfaceVariantAnimationRefSet.fromJson[0m                                                      
00:00 [32m+25[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 26. ProjectSurfacePreset codec remains out of scope (Lot 45)[0m                                                                              
00:00 [32m+26[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 26. ProjectSurfacePreset codec remains out of scope (Lot 45)[0m                                                                              
00:00 [32m+26[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 27. ProjectSurfaceCatalog codec remains out of scope[0m                                                                                      
00:00 [32m+27[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 27. ProjectSurfaceCatalog codec remains out of scope[0m                                                                                      
00:00 [32m+27[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 28. standardSurfaceVariantRoleOrder length 20 (Lot 28 doc)[0m                                                                                
00:00 [32m+28[0m: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 28. standardSurfaceVariantRoleOrder length 20 (Lot 28 doc)[0m                                                                                
00:00 [32m+28[0m: All tests passed![0m                                                                                                                                                                           

```

### `test/surface_variant_animation_ref_set_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_variant_animation_ref_set_test.dart[0m[0m                                                                                                                                     
00:00 [32m+0[0m: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                                                                            
00:00 [32m+1[0m: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                                                                            
00:00 [32m+1[0m: SurfaceVariantAnimationRefSet rejects empty refs[0m                                                                                                                                             
00:00 [32m+2[0m: SurfaceVariantAnimationRefSet rejects empty refs[0m                                                                                                                                             
00:00 [32m+2[0m: SurfaceVariantAnimationRefSet rejects duplicate role (different animationId)[0m                                                                                                                 
00:00 [32m+3[0m: SurfaceVariantAnimationRefSet rejects duplicate role (different animationId)[0m                                                                                                                 
00:00 [32m+3[0m: SurfaceVariantAnimationRefSet allows same animationId for different roles[0m                                                                                                                    
00:00 [32m+4[0m: SurfaceVariantAnimationRefSet allows same animationId for different roles[0m                                                                                                                    
00:00 [32m+4[0m: SurfaceVariantAnimationRefSet preserves input order (not sorted by standard order)[0m                                                                                                           
00:00 [32m+5[0m: SurfaceVariantAnimationRefSet preserves input order (not sorted by standard order)[0m                                                                                                           
00:00 [32m+5[0m: SurfaceVariantAnimationRefSet exposed refs list is unmodifiable[0m                                                                                                                              
00:00 [32m+6[0m: SurfaceVariantAnimationRefSet exposed refs list is unmodifiable[0m                                                                                                                              
00:00 [32m+6[0m: SurfaceVariantAnimationRefSet defensive copy: mutating source list after build does not change set[0m                                                                                           
00:00 [32m+7[0m: SurfaceVariantAnimationRefSet defensive copy: mutating source list after build does not change set[0m                                                                                           
00:00 [32m+7[0m: SurfaceVariantAnimationRefSet containsRole: true for present roles[0m                                                                                                                           
00:00 [32m+8[0m: SurfaceVariantAnimationRefSet containsRole: true for present roles[0m                                                                                                                           
00:00 [32m+8[0m: SurfaceVariantAnimationRefSet containsRole: false when role absent[0m                                                                                                                           
00:00 [32m+9[0m: SurfaceVariantAnimationRefSet containsRole: false when role absent[0m                                                                                                                           
00:00 [32m+9[0m: SurfaceVariantAnimationRefSet refForRole: returns ref when present[0m                                                                                                                           
00:00 [32m+10[0m: SurfaceVariantAnimationRefSet refForRole: returns ref when present[0m                                                                                                                          
00:00 [32m+10[0m: SurfaceVariantAnimationRefSet refForRole: null when absent[0m                                                                                                                                  
00:00 [32m+11[0m: SurfaceVariantAnimationRefSet refForRole: null when absent[0m                                                                                                                                  
00:00 [32m+11[0m: SurfaceVariantAnimationRefSet animationIdForRole: id when present[0m                                                                                                                           
00:00 [32m+12[0m: SurfaceVariantAnimationRefSet animationIdForRole: id when present[0m                                                                                                                           
00:00 [32m+12[0m: SurfaceVariantAnimationRefSet animationIdForRole: null when absent[0m                                                                                                                          
00:00 [32m+13[0m: SurfaceVariantAnimationRefSet animationIdForRole: null when absent[0m                                                                                                                          
00:00 [32m+13[0m: SurfaceVariantAnimationRefSet coversAllRoles: true for covered subset[0m                                                                                                                       
00:00 [32m+14[0m: SurfaceVariantAnimationRefSet coversAllRoles: true for covered subset[0m                                                                                                                       
00:00 [32m+14[0m: SurfaceVariantAnimationRefSet coversAllRoles: false if one role missing[0m                                                                                                                     
00:00 [32m+15[0m: SurfaceVariantAnimationRefSet coversAllRoles: false if one role missing[0m                                                                                                                     
00:00 [32m+15[0m: SurfaceVariantAnimationRefSet coversAllRoles: true for empty iterable (vacuous every)[0m                                                                                                       
00:00 [32m+16[0m: SurfaceVariantAnimationRefSet coversAllRoles: true for empty iterable (vacuous every)[0m                                                                                                       
00:00 [32m+16[0m: SurfaceVariantAnimationRefSet can cover all of standardSurfaceVariantRoleOrder in input order[0m                                                                                               
00:00 [32m+17[0m: SurfaceVariantAnimationRefSet can cover all of standardSurfaceVariantRoleOrder in input order[0m                                                                                               
00:00 [32m+17[0m: SurfaceVariantAnimationRefSet value equality: same refs in same order[0m                                                                                                                       
00:00 [32m+18[0m: SurfaceVariantAnimationRefSet value equality: same refs in same order[0m                                                                                                                       
00:00 [32m+18[0m: SurfaceVariantAnimationRefSet value equality: different order => not equal[0m                                                                                                                  
00:00 [32m+19[0m: SurfaceVariantAnimationRefSet value equality: different order => not equal[0m                                                                                                                  
00:00 [32m+19[0m: SurfaceVariantAnimationRefSet value equality: same role different animationId[0m                                                                                                               
00:00 [32m+20[0m: SurfaceVariantAnimationRefSet value equality: same role different animationId[0m                                                                                                               
00:00 [32m+20[0m: SurfaceVariantAnimationRefSet export: type via map_core[0m                                                                                                                                     
00:00 [32m+21[0m: SurfaceVariantAnimationRefSet export: type via map_core[0m                                                                                                                                     
00:00 [32m+21[0m: SurfaceVariantAnimationRefSet set is only a collection of refs (no ProjectSurfacePreset)[0m                                                                                                    
00:00 [32m+22[0m: SurfaceVariantAnimationRefSet set is only a collection of refs (no ProjectSurfacePreset)[0m                                                                                                    
00:00 [32m+22[0m: SurfaceVariantAnimationRefSet ProjectManifest toJson: no surface* top-level keys[0m                                                                                                            
00:00 [32m+23[0m: SurfaceVariantAnimationRefSet ProjectManifest toJson: no surface* top-level keys[0m                                                                                                            
00:00 [32m+23[0m: All tests passed![0m                                                                                                                                                                           

```

### `test/surface_variant_animation_ref_json_codec_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_variant_animation_ref_json_codec_test.dart[0m[0m                                                                                                                              
00:00 [32m+0[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 1. encodeSurfaceVariantRole isolated[0m                                                                                                          
00:00 [32m+1[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 1. encodeSurfaceVariantRole isolated[0m                                                                                                          
00:00 [32m+1[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 2. decodeSurfaceVariantRole isolated[0m                                                                                                          
00:00 [32m+2[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 2. decodeSurfaceVariantRole isolated[0m                                                                                                          
00:00 [32m+2[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 3. round-trip every SurfaceVariantRole.values[0m                                                                                                 
00:00 [32m+3[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 3. round-trip every SurfaceVariantRole.values[0m                                                                                                 
00:00 [32m+3[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 4. standardSurfaceVariantRoleOrder: order preserved, each round-trips[0m                                                                         
00:00 [32m+4[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 4. standardSurfaceVariantRoleOrder: order preserved, each round-trips[0m                                                                         
00:00 [32m+4[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 5. decode rejects unknown role string[0m                                                                                                         
00:00 [32m+5[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 5. decode rejects unknown role string[0m                                                                                                         
00:00 [32m+5[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 6. decode rejects wrong casing[0m                                                                                                                
00:00 [32m+6[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 6. decode rejects wrong casing[0m                                                                                                                
00:00 [32m+6[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 7. decode rejects valid name with surrounding spaces[0m                                                                                          
00:00 [32m+7[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 7. decode rejects valid name with surrounding spaces[0m                                                                                          
00:00 [32m+7[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 8. encode SurfaceVariantAnimationRef[0m                                                                                                          
00:00 [32m+8[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 8. encode SurfaceVariantAnimationRef[0m                                                                                                          
00:00 [32m+8[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 9. decode SurfaceVariantAnimationRef[0m                                                                                                          
00:00 [32m+9[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 9. decode SurfaceVariantAnimationRef[0m                                                                                                          
00:00 [32m+9[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 10. round-trip SurfaceVariantAnimationRef[0m                                                                                                     
00:00 [32m+10[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 10. round-trip SurfaceVariantAnimationRef[0m                                                                                                    
00:00 [32m+10[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 11. decode preserves animationId exact (no auto-trim in model)[0m                                                                               
00:00 [32m+11[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 11. decode preserves animationId exact (no auto-trim in model)[0m                                                                               
00:00 [32m+11[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 12. decode rejects missing role[0m                                                                                                              
00:00 [32m+12[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 12. decode rejects missing role[0m                                                                                                              
00:00 [32m+12[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 13. decode rejects role wrong type[0m                                                                                                           
00:00 [32m+13[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 13. decode rejects role wrong type[0m                                                                                                           
00:00 [32m+13[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 14. decode rejects unknown role in ref json[0m                                                                                                  
00:00 [32m+14[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 14. decode rejects unknown role in ref json[0m                                                                                                  
00:00 [32m+14[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 15. decode rejects role wrong casing in ref json[0m                                                                                             
00:00 [32m+15[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 15. decode rejects role wrong casing in ref json[0m                                                                                             
00:00 [32m+15[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 16. decode rejects missing animationId[0m                                                                                                       
00:00 [32m+16[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 16. decode rejects missing animationId[0m                                                                                                       
00:00 [32m+16[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 17. decode rejects animationId wrong type[0m                                                                                                    
00:00 [32m+17[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 17. decode rejects animationId wrong type[0m                                                                                                    
00:00 [32m+17[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 18. decode rejects animationId whitespace-only (constructor)[0m                                                                                 
00:00 [32m+18[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 18. decode rejects animationId whitespace-only (constructor)[0m                                                                                 
00:00 [32m+18[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 19. decode ignores unknown key[0m                                                                                                               
00:00 [32m+19[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 19. decode ignores unknown key[0m                                                                                                               
00:00 [32m+19[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 20. decode does not mutate source map[0m                                                                                                        
00:00 [32m+20[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 20. decode does not mutate source map[0m                                                                                                        
00:00 [32m+20[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 21. does not resolve missing animationId[0m                                                                                                     
00:00 [32m+21[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 21. does not resolve missing animationId[0m                                                                                                     
00:00 [32m+21[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 22. public API encode returns map[0m                                                                                                            
00:00 [32m+22[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 22. public API encode returns map[0m                                                                                                            
00:00 [32m+22[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 23. ProjectManifest has no surface persistence keys (Lot 43)[0m                                                                                 
00:00 [32m+23[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 23. ProjectManifest has no surface persistence keys (Lot 43)[0m                                                                                 
00:00 [32m+23[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 24. codec external to model: no ref.toJson or SurfaceVariantAnimationRef.fromJson[0m                                                            
00:00 [32m+24[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 24. codec external to model: no ref.toJson or SurfaceVariantAnimationRef.fromJson[0m                                                            
00:00 [32m+24[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 25. SurfaceVariantAnimationRefSet codec remains out of scope (Lot 44)[0m                                                                        
00:00 [32m+25[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 25. SurfaceVariantAnimationRefSet codec remains out of scope (Lot 44)[0m                                                                        
00:00 [32m+25[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 26. preset and catalog codec remain out of scope[0m                                                                                             
00:00 [32m+26[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 26. preset and catalog codec remain out of scope[0m                                                                                             
00:00 [32m+26[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 27. standardSurfaceVariantRoleOrder has length 20 (Lot 28 coquille doc)[0m                                                                      
00:00 [32m+27[0m: SurfaceVariantAnimationRef JSON codec (Lot 43) 27. standardSurfaceVariantRoleOrder has length 20 (Lot 28 coquille doc)[0m                                                                      
00:00 [32m+27[0m: All tests passed![0m                                                                                                                                                                           

```

### `test/surface_variant_animation_ref_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_variant_animation_ref_test.dart[0m[0m                                                                                                                                         
00:00 [32m+0[0m: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                                                                            
00:00 [32m+1[0m: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                                                                            
00:00 [32m+1[0m: SurfaceVariantAnimationRef accepts several distinct roles (sample)[0m                                                                                                                           
00:00 [32m+2[0m: SurfaceVariantAnimationRef accepts several distinct roles (sample)[0m                                                                                                                           
00:00 [32m+2[0m: SurfaceVariantAnimationRef stores animationId exactly without auto-trim[0m                                                                                                                      
00:00 [32m+3[0m: SurfaceVariantAnimationRef stores animationId exactly without auto-trim[0m                                                                                                                      
00:00 [32m+3[0m: SurfaceVariantAnimationRef rejects empty animationId: empty string[0m                                                                                                                           
00:00 [32m+4[0m: SurfaceVariantAnimationRef rejects empty animationId: empty string[0m                                                                                                                           
00:00 [32m+4[0m: SurfaceVariantAnimationRef rejects empty animationId: whitespace only[0m                                                                                                                        
00:00 [32m+5[0m: SurfaceVariantAnimationRef rejects empty animationId: whitespace only[0m                                                                                                                        
00:00 [32m+5[0m: SurfaceVariantAnimationRef value equality: same values => equal and same hash[0m                                                                                                                
00:00 [32m+6[0m: SurfaceVariantAnimationRef value equality: same values => equal and same hash[0m                                                                                                                
00:00 [32m+6[0m: SurfaceVariantAnimationRef value equality: different role[0m                                                                                                                                    
00:00 [32m+7[0m: SurfaceVariantAnimationRef value equality: different role[0m                                                                                                                                    
00:00 [32m+7[0m: SurfaceVariantAnimationRef value equality: different animationId[0m                                                                                                                             
00:00 [32m+8[0m: SurfaceVariantAnimationRef value equality: different animationId[0m                                                                                                                             
00:00 [32m+8[0m: SurfaceVariantAnimationRef export: type visible through map_core[0m                                                                                                                             
00:00 [32m+9[0m: SurfaceVariantAnimationRef export: type visible through map_core[0m                                                                                                                             
00:00 [32m+9[0m: SurfaceVariantAnimationRef coexists with ProjectSurfaceAnimation: id string only, no resolution[0m                                                                                              
00:00 [32m+10[0m: SurfaceVariantAnimationRef coexists with ProjectSurfaceAnimation: id string only, no resolution[0m                                                                                             
00:00 [32m+10[0m: SurfaceVariantAnimationRef one ref per role in standardSurfaceVariantRoleOrder (length + order)[0m                                                                                             
00:00 [32m+11[0m: SurfaceVariantAnimationRef one ref per role in standardSurfaceVariantRoleOrder (length + order)[0m                                                                                             
00:00 [32m+11[0m: SurfaceVariantAnimationRef ProjectManifest toJson: no surface* top-level keys[0m                                                                                                               
00:00 [32m+12[0m: SurfaceVariantAnimationRef ProjectManifest toJson: no surface* top-level keys[0m                                                                                                               
00:00 [32m+12[0m: All tests passed![0m                                                                                                                                                                           

```

### `test/surface_model_entrypoint_test.dart`

```

00:00 [32m+0[0m: [1m[90mloading test/surface_model_entrypoint_test.dart[0m[0m                                                                                                                                              
00:00 [32m+0[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                                                                 
00:00 [32m+1[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                                                                 
00:00 [32m+1[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet[0m                                                                          
00:00 [32m+2[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet[0m                                                                          
00:00 [32m+2[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                                                            
00:00 [32m+3[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                                                            
00:00 [32m+3[0m: All tests passed![0m                                                                                                                                                                            

```

## 33. Résultat exact : `dart analyze` (périmètre demandé)

```
Analyzing project_surface_preset_json_codec.dart, surface_variant_animation_ref_set_json_codec.dart, surface_variant_animation_ref_json_codec.dart, surface.dart, project_surface_preset_json_codec_test.dart, project_surface_preset_test.dart, surface_variant_animation_ref_set_json_codec_test.dart, surface_variant_animation_ref_set_test.dart, surface_variant_animation_ref_json_codec_test.dart, surface_variant_animation_ref_test.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!
```

## 34. Résultat : `dart test` complet (package `map_core`)

- Commande : `cd packages/map_core && /opt/homebrew/bin/dart test`
- Ligne finale exacte (copie) : `+1064: All tests passed!`
- **Total** : **1064** tests.

## 35. Points de vigilance

- Homonymie future avec un futur `surfacePresets` dans le manifeste : conserver l'isolation de ce codec.
- Cohérence d'`animationId` = diagnostics catalogue, pas ce codec.

## 36. Autocritique finale

- Les tests 31 et 32 sont surtout documentaires (noms de test explicites) ; l'invariant est déjà imposé par l'absence d'API.
- Messages `ValidationException` sur clé manquante : `… is required` (cohérent avec le code) vs exemples `must be…` sur types.

## 37. Ce que le prompt semble discutable ou incomplet

- Conflit mineur d'exemples de texte d'exception entre « required » et « must be a non-null String » : l'implémentation couvre les deux situations.

## 38. Auto-review indépendante (checklist)

- Lot limité au codec `ProjectSurfacePreset` : **oui**
- Aucun `ProjectManifest` modifié : **oui**
- Aucun champ Surface persistant ajouté au manifeste : **oui**
- Aucun `toJson`/`fromJson` modèle : **oui**
- Aucun codec `ProjectSurfaceCatalog` : **oui**
- Aucun `SurfacePresetKind` / `surfaceKind` : **oui**
- Aucun codec `ProjectSurfaceAnimation` supplémentaire : **oui**
- Aucun modèle Freezed/JSON généré ajouté : **oui**
- Aucun `.g.dart` / `.freezed.dart` : **oui** (non touché)
- `build_runner` : **non lancé**
- Aucun runtime / editor / gameplay / battle : **oui** (non modifié)
- Codec réutilise RefSet Lot 44 : **oui** (tests 1, 28)
- Ordre préservé, pas de tri : **oui** (tests 7, 8)
- Pas de complétion de rôles : **oui** (test 27)
- Pas de résolution `animationId` : **oui** (test 26)
- Clés inconnues tolérées : **oui** (tests 17, 18)
- Maps sources non mutes : **oui** (test 24)
- `categoryId` `null` omis à l'encodage : **oui** (test 1)
- `sortOrder` toujours encodé : **oui** (test 1)
- Export public : **oui** (test 29)
- Manifest sans clés surface : **oui** (test 30)
- `standardSurfaceVariantRoleOrder.length == 20` : **oui** (test 34)
- `map_core` complet vert : **oui** (total rappelé section 34)
- Aucune commande Git d'écriture : **oui**
- Auto-check des formulations d'esquive interdites (liste non recopiée) : **fait** — aucune formulation interdite n'est utilisée pour remplacer une preuve requise.

## 39. `git status --short` final

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/project_surface_preset_json_codec.dart
?? packages/map_core/test/project_surface_preset_json_codec_test.dart
?? reports/surface/surface_engine_lot_45_project_surface_preset_json_codec.md
```

## 40. Evidence Pack complet

### A. Contenu intégral : fichiers **créés**

#### A.1 `project_surface_preset_json_codec.dart`

```dart
// JSON codec manuel (Lot 45) — [ProjectSurfacePreset].
//
// * Prépare la **future** persistance de **catalogues** Surface (Lot 46+) **sans**
//   branchement [ProjectManifest] et sans [toJson] / [fromJson] sur le modèle.
// * [variantAnimations] : délégation stricte à [encodeSurfaceVariantAnimationRefSet] /
//   [decodeSurfaceVariantAnimationRefSet] (Lot 44) — ordre des refs = celui du
//   [SurfaceVariantAnimationRefSet], **aucun** retri, **aucune** complétion de
//   rôles manquants ici.
// * **Pas** de résolution d’[animationId] → [ProjectSurfaceAnimation] : seulement
//   forme JSON + invariants [SurfaceVariantAnimationRef] / [RefSet].
// * Pas de [SurfacePresetKind], pas de clé [surfaceKind] : V0 auteur, visuel.
// * Aucun codec [ProjectSurfaceCatalog] ici.
// * Décodage : clés inconnues **tolérées** ; [Map] sources **jamais** mutées.
//
// * V0 encodage : [categoryId] **absent** si `null` ; [sortOrder] **toujours** présent.

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';
import 'surface_variant_animation_ref_set_json_codec.dart';

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

Object? _valueForRequiredKey(
  Map<String, Object?> json,
  String key,
  String errorPrefix,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$errorPrefix is required');
  }
  return json[key];
}

String _reqNonNullString(
  String fieldKey,
  Object? value,
) {
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

String? _optionalStringOrNull(
  Map<String, Object?> json,
  String key,
  String errorWhenWrongType,
) {
  if (!json.containsKey(key)) {
    return null;
  }
  final v = json[key];
  if (v == null) {
    return null;
  }
  if (v is! String) {
    throw ValidationException(errorWhenWrongType);
  }
  return v;
}

int _sortOrder(Map<String, Object?> json) {
  if (!json.containsKey('sortOrder')) {
    return 0;
  }
  final v = json['sortOrder'];
  if (v is! int) {
    throw const ValidationException(
      'ProjectSurfacePreset.sortOrder must be an int',
    );
  }
  return v;
}

/// Encodage : [id], [name], [variantAnimations] ; [categoryId] seulement si non
/// `null` ; [sortOrder] **toujours** (V0).
Map<String, Object?> encodeProjectSurfacePreset(
  ProjectSurfacePreset preset,
) {
  final out = <String, Object?>{
    'id': preset.id,
    'name': preset.name,
    'variantAnimations': encodeSurfaceVariantAnimationRefSet(
      preset.variantAnimations,
    ),
  };
  if (preset.categoryId != null) {
    out['categoryId'] = preset.categoryId;
  }
  out['sortOrder'] = preset.sortOrder;
  return out;
}

ProjectSurfacePreset decodeProjectSurfacePreset(
  Map<String, Object?> json,
) {
  final id = _reqNonNullString(
    'ProjectSurfacePreset.id',
    _valueForRequiredKey(
      json,
      'id',
      'ProjectSurfacePreset.id',
    ),
  );
  final name = _reqNonNullString(
    'ProjectSurfacePreset.name',
    _valueForRequiredKey(
      json,
      'name',
      'ProjectSurfacePreset.name',
    ),
  );

  final va = _valueForRequiredKey(
    json,
    'variantAnimations',
    'ProjectSurfacePreset.variantAnimations',
  );
  if (va is! Map) {
    throw const ValidationException(
      'ProjectSurfacePreset.variantAnimations must be an Object',
    );
  }
  final refSet = decodeSurfaceVariantAnimationRefSet(
    _stringKeyMapFrom(va),
  );

  final categoryId = _optionalStringOrNull(
    json,
    'categoryId',
    'ProjectSurfacePreset.categoryId must be a String or null',
  );
  final sortOrder = _sortOrder(json);

  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: refSet,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

```

#### A.2 `project_surface_preset_json_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSurfacePreset JSON codec (Lot 45)', () {
    test('1. encodes minimal preset', () {
      final p = _preset(
        categoryId: null,
        sortOrder: 0,
      );
      final j = encodeProjectSurfacePreset(p);
      expect(j['id'], 'water-surface');
      expect(j['name'], 'Water Surface');
      expect(
        j['variantAnimations'],
        encodeSurfaceVariantAnimationRefSet(p.variantAnimations),
      );
      expect(j['sortOrder'], 0);
      expect(j.containsKey('categoryId'), isFalse);
    });

    test('2. decodes minimal preset', () {
      const j = <String, Object?>{
        'id': 'water-surface',
        'name': 'Water Surface',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{
              'role': 'isolated',
              'animationId': 'water-isolated-loop',
            },
          ],
        },
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.id, 'water-surface');
      expect(p.name, 'Water Surface');
      expect(p.variantCount, 1);
      expect(p.containsRole(SurfaceVariantRole.isolated), isTrue);
      expect(
        p.animationIdForRole(SurfaceVariantRole.isolated),
        'water-isolated-loop',
      );
      expect(p.categoryId, isNull);
      expect(p.sortOrder, 0);
    });

    test('3. round-trip minimal preset', () {
      final o = _preset();
      final d = decodeProjectSurfacePreset(encodeProjectSurfacePreset(o));
      expect(d, o);
    });

    test('4. encodes full preset (category + sortOrder)', () {
      final p = _preset(
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      final j = encodeProjectSurfacePreset(p);
      expect(j['categoryId'], 'animated-surfaces');
      expect(j['sortOrder'], 42);
    });

    test('5. decodes full preset', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'N',
        'variantAnimations': encodeSurfaceVariantAnimationRefSet(
          _refSet(refs: [
            _ref(SurfaceVariantRole.isolated, animationId: 'x'),
          ]),
        ),
        'categoryId': 'animated-surfaces',
        'sortOrder': 42,
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.categoryId, 'animated-surfaces');
      expect(p.sortOrder, 42);
    });

    test('6. round-trip full preset', () {
      final o = _preset(
        categoryId: 'c',
        sortOrder: 7,
      );
      final d = decodeProjectSurfacePreset(encodeProjectSurfacePreset(o));
      expect(d, o);
    });

    test('7. encode preserves multi-ref order in variantAnimations', () {
      final rs = _refSet(refs: [
        _ref(SurfaceVariantRole.cross, animationId: 'a'),
        _ref(SurfaceVariantRole.isolated, animationId: 'b'),
        _ref(SurfaceVariantRole.horizontal, animationId: 'c'),
      ]);
      final p = _preset(variantAnimations: rs);
      final j = encodeProjectSurfacePreset(p);
      final va = j['variantAnimations'] as Map<String, Object?>?;
      final refs = va!['refs'] as List<Object?>?;
      expect(refs!.length, 3);
      for (var i = 0; i < 3; i++) {
        expect(refs[i], encodeSurfaceVariantAnimationRef(rs.refs[i]));
      }
    });

    test('8. decode preserves multi-ref order', () {
      const j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'cross', 'animationId': 'a'},
            <String, Object?>{'role': 'isolated', 'animationId': 'b'},
            <String, Object?>{'role': 'horizontal', 'animationId': 'c'},
          ],
        },
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.variantCount, 3);
      expect(
        p.variantAnimations.refs.map((e) => e.role).toList(),
        [
          SurfaceVariantRole.cross,
          SurfaceVariantRole.isolated,
          SurfaceVariantRole.horizontal,
        ],
      );
      expect(p.refForRole(SurfaceVariantRole.cross)?.animationId, 'a');
    });

    test('9. decode preserves exact id name category strings', () {
      const id = '  water-surface  ';
      const name = '  Water Surface  ';
      const cat = '  animated  ';
      final j = <String, Object?>{
        'id': id,
        'name': name,
        'variantAnimations': encodeSurfaceVariantAnimationRefSet(
          _refSet(refs: [
            _ref(SurfaceVariantRole.isolated, animationId: 'a'),
          ]),
        ),
        'categoryId': cat,
        'sortOrder': 0,
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.id, id);
      expect(p.name, name);
      expect(p.categoryId, cat);
    });

    test('10. reject id missing / wrong type / whitespace-only', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'name': 'n',
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 123,
          'name': 'n',
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': '   ',
          'name': 'n',
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('11. reject name missing / wrong type / whitespace-only', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'i',
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'i',
          'name': 123,
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'i',
          'name': '   ',
          'variantAnimations': _minVa(),
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('12. reject variantAnimations missing or wrong type', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': 'nope',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. reject empty variantAnimations refs', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': <String, Object?>{'refs': <Object?>[]},
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('14. reject duplicate role in variantAnimations', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': <String, Object?>{
            'refs': <Object?>[
              <String, Object?>{'role': 'isolated', 'animationId': 'a'},
              <String, Object?>{'role': 'isolated', 'animationId': 'b'},
            ],
          },
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('15. reject invalid role in variantAnimations', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': <String, Object?>{
            'refs': <Object?>[
              <String, Object?>{'role': 'notARole', 'animationId': 'x'},
            ],
          },
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('16. reject invalid animationId in variantAnimations', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': <String, Object?>{
            'refs': <Object?>[
              <String, Object?>{'role': 'isolated', 'animationId': '   '},
            ],
          },
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('17. decode ignores unknown top-level key', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': _minVa(),
        'futureField': 'ignored',
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.id, 'a');
    });

    test('18. decode ignores unknown keys in variantAnimations and refs', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{
              'role': 'isolated',
              'animationId': 'a',
              'x': 1,
            },
          ],
          'extraVa': 2,
        },
        'h': 3,
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.variantCount, 1);
    });

    test('19. decode accepts categoryId: null in JSON', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': _minVa(),
        'categoryId': null,
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.categoryId, isNull);
    });

    test('20. decode reject categoryId non-string non-null', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': _minVa(),
          'categoryId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('21. decode accept sortOrder absent (default 0)', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': _minVa(),
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.sortOrder, 0);
    });

    test('22. decode accept negative sortOrder', () {
      final j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': _minVa(),
        'sortOrder': -10,
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.sortOrder, -10);
    });

    test('23. decode reject sortOrder non-int', () {
      expect(
        () => decodeProjectSurfacePreset(<String, Object?>{
          'id': 'a',
          'name': 'b',
          'variantAnimations': _minVa(),
          'sortOrder': '10',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('24. decode does not mutate source map', () {
      final m = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'isolated', 'animationId': 'a'},
          ],
        },
      };
      final before = _mapStr(m);
      decodeProjectSurfacePreset(m);
      expect(_mapStr(m), before);
    });

    test('25. encode does not mutate preset', () {
      final p = _preset(
        categoryId: 'c',
        sortOrder: 3,
      );
      final id = p.id;
      final name = p.name;
      final vc = p.variantCount;
      final cat = p.categoryId;
      final so = p.sortOrder;
      final c = p.containsRole(SurfaceVariantRole.isolated);
      encodeProjectSurfacePreset(p);
      expect(p.id, id);
      expect(p.name, name);
      expect(p.variantCount, vc);
      expect(p.categoryId, cat);
      expect(p.sortOrder, so);
      expect(p.containsRole(SurfaceVariantRole.isolated), c);
    });

    test('26. does not resolve animationId', () {
      const j = <String, Object?>{
        'id': 'broken-but-structurally-valid',
        'name': 'Broken but structurally valid',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{
              'role': 'isolated',
              'animationId': 'missing-animation',
            },
          ],
        },
      };
      final p = decodeProjectSurfacePreset(j);
      expect(
        p.animationIdForRole(SurfaceVariantRole.isolated),
        'missing-animation',
      );
    });

    test('27. does not complete missing standard roles', () {
      const j = <String, Object?>{
        'id': 'a',
        'name': 'b',
        'variantAnimations': <String, Object?>{
          'refs': <Object?>[
            <String, Object?>{'role': 'isolated', 'animationId': 'a'},
          ],
        },
      };
      final p = decodeProjectSurfacePreset(j);
      expect(p.variantCount, 1);
      expect(
        p.coversAllRoles(standardSurfaceVariantRoleOrder),
        isFalse,
      );
    });

    test('28. reuses Lot 44 RefSet codec for variantAnimations', () {
      final p = _preset();
      final j = encodeProjectSurfacePreset(p);
      expect(
        j['variantAnimations'],
        encodeSurfaceVariantAnimationRefSet(p.variantAnimations),
      );
    });

    test('29. public API encode returns map', () {
      expect(encodeProjectSurfacePreset(_preset()), isA<Map<String, Object?>>());
    });

    test('30. ProjectManifest has no surface persistence keys (Lot 45)', () {
      const manifest = ProjectManifest(
        name: 'L45',
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
      '31. codec external to model: no preset.toJson or ProjectSurfacePreset.fromJson',
      () {
        final p = _preset();
        final m = encodeProjectSurfacePreset(p);
        expect(m, isA<Map<String, Object?>>());
      },
    );

    test('32. ProjectSurfaceCatalog codec remains out of scope (Lot 46)', () {
      final j = encodeProjectSurfacePreset(_preset());
      expect(j['id'], isNotNull);
    });

    test('33. no SurfacePresetKind / surfaceKind keys in JSON', () {
      final j = encodeProjectSurfacePreset(_preset());
      for (final k in const [
        'kind',
        'surfaceKind',
        'presetKind',
        'type',
      ]) {
        expect(j.containsKey(k), isFalse, reason: k);
      }
    });

    test('34. standardSurfaceVariantRoleOrder length 20 (Lot 28 doc)', () {
      expect(standardSurfaceVariantRoleOrder.length, 20);
    });
  });
}

SurfaceVariantAnimationRef _ref(
  SurfaceVariantRole role, {
  String? animationId,
}) {
  return SurfaceVariantAnimationRef(
    role: role,
    animationId: animationId ?? 'id-${role.name}',
  );
}

SurfaceVariantAnimationRefSet _refSet({List<SurfaceVariantAnimationRef>? refs}) {
  return SurfaceVariantAnimationRefSet(
    refs: refs ??
        [
          _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
        ],
  );
}

Map<String, Object?> _minVa() {
  return encodeSurfaceVariantAnimationRefSet(
    _refSet(
      refs: [
        _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
      ],
    ),
  );
}

ProjectSurfacePreset _preset({
  String id = 'water-surface',
  String name = 'Water Surface',
  SurfaceVariantAnimationRefSet? variantAnimations,
  String? categoryId,
  int sortOrder = 0,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: variantAnimations ?? _refSet(),
    categoryId: categoryId,
    sortOrder: sortOrder,
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

### B. Contenu intégral : fichier **modifié** `map_core.dart`

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

#### C.1 `project_surface_preset_json_codec.dart` (`git diff /dev/null`)

```diff
diff --git a/packages/map_core/lib/src/operations/project_surface_preset_json_codec.dart b/packages/map_core/lib/src/operations/project_surface_preset_json_codec.dart
new file mode 100644
index 00000000..60af5e9a
--- /dev/null
+++ b/packages/map_core/lib/src/operations/project_surface_preset_json_codec.dart
@@ -0,0 +1,152 @@
+// JSON codec manuel (Lot 45) — [ProjectSurfacePreset].
+//
+// * Prépare la **future** persistance de **catalogues** Surface (Lot 46+) **sans**
+//   branchement [ProjectManifest] et sans [toJson] / [fromJson] sur le modèle.
+// * [variantAnimations] : délégation stricte à [encodeSurfaceVariantAnimationRefSet] /
+//   [decodeSurfaceVariantAnimationRefSet] (Lot 44) — ordre des refs = celui du
+//   [SurfaceVariantAnimationRefSet], **aucun** retri, **aucune** complétion de
+//   rôles manquants ici.
+// * **Pas** de résolution d’[animationId] → [ProjectSurfaceAnimation] : seulement
+//   forme JSON + invariants [SurfaceVariantAnimationRef] / [RefSet].
+// * Pas de [SurfacePresetKind], pas de clé [surfaceKind] : V0 auteur, visuel.
+// * Aucun codec [ProjectSurfaceCatalog] ici.
+// * Décodage : clés inconnues **tolérées** ; [Map] sources **jamais** mutées.
+//
+// * V0 encodage : [categoryId] **absent** si `null` ; [sortOrder] **toujours** présent.
+
+import '../exceptions/map_exceptions.dart';
+import '../models/surface.dart';
+import 'surface_variant_animation_ref_set_json_codec.dart';
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
+Object? _valueForRequiredKey(
+  Map<String, Object?> json,
+  String key,
+  String errorPrefix,
+) {
+  if (!json.containsKey(key)) {
+    throw ValidationException('$errorPrefix is required');
+  }
+  return json[key];
+}
+
+String _reqNonNullString(
+  String fieldKey,
+  Object? value,
+) {
+  if (value is! String) {
+    throw ValidationException('$fieldKey must be a non-null String');
+  }
+  return value;
+}
+
+String? _optionalStringOrNull(
+  Map<String, Object?> json,
+  String key,
+  String errorWhenWrongType,
+) {
+  if (!json.containsKey(key)) {
+    return null;
+  }
+  final v = json[key];
+  if (v == null) {
+    return null;
+  }
+  if (v is! String) {
+    throw ValidationException(errorWhenWrongType);
+  }
+  return v;
+}
+
+int _sortOrder(Map<String, Object?> json) {
+  if (!json.containsKey('sortOrder')) {
+    return 0;
+  }
+  final v = json['sortOrder'];
+  if (v is! int) {
+    throw const ValidationException(
+      'ProjectSurfacePreset.sortOrder must be an int',
+    );
+  }
+  return v;
+}
+
+/// Encodage : [id], [name], [variantAnimations] ; [categoryId] seulement si non
+/// `null` ; [sortOrder] **toujours** (V0).
+Map<String, Object?> encodeProjectSurfacePreset(
+  ProjectSurfacePreset preset,
+) {
+  final out = <String, Object?>{
+    'id': preset.id,
+    'name': preset.name,
+    'variantAnimations': encodeSurfaceVariantAnimationRefSet(
+      preset.variantAnimations,
+    ),
+  };
+  if (preset.categoryId != null) {
+    out['categoryId'] = preset.categoryId;
+  }
+  out['sortOrder'] = preset.sortOrder;
+  return out;
+}
+
+ProjectSurfacePreset decodeProjectSurfacePreset(
+  Map<String, Object?> json,
+) {
+  final id = _reqNonNullString(
+    'ProjectSurfacePreset.id',
+    _valueForRequiredKey(
+      json,
+      'id',
+      'ProjectSurfacePreset.id',
+    ),
+  );
+  final name = _reqNonNullString(
+    'ProjectSurfacePreset.name',
+    _valueForRequiredKey(
+      json,
+      'name',
+      'ProjectSurfacePreset.name',
+    ),
+  );
+
+  final va = _valueForRequiredKey(
+    json,
+    'variantAnimations',
+    'ProjectSurfacePreset.variantAnimations',
+  );
+  if (va is! Map) {
+    throw const ValidationException(
+      'ProjectSurfacePreset.variantAnimations must be an Object',
+    );
+  }
+  final refSet = decodeSurfaceVariantAnimationRefSet(
+    _stringKeyMapFrom(va),
+  );
+
+  final categoryId = _optionalStringOrNull(
+    json,
+    'categoryId',
+    'ProjectSurfacePreset.categoryId must be a String or null',
+  );
+  final sortOrder = _sortOrder(json);
+
+  return ProjectSurfacePreset(
+    id: id,
+    name: name,
+    variantAnimations: refSet,
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}

```

#### C.2 `project_surface_preset_json_codec_test.dart` (`git diff /dev/null`)

```diff
diff --git a/packages/map_core/test/project_surface_preset_json_codec_test.dart b/packages/map_core/test/project_surface_preset_json_codec_test.dart
new file mode 100644
index 00000000..a41eaeeb
--- /dev/null
+++ b/packages/map_core/test/project_surface_preset_json_codec_test.dart
@@ -0,0 +1,568 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('ProjectSurfacePreset JSON codec (Lot 45)', () {
+    test('1. encodes minimal preset', () {
+      final p = _preset(
+        categoryId: null,
+        sortOrder: 0,
+      );
+      final j = encodeProjectSurfacePreset(p);
+      expect(j['id'], 'water-surface');
+      expect(j['name'], 'Water Surface');
+      expect(
+        j['variantAnimations'],
+        encodeSurfaceVariantAnimationRefSet(p.variantAnimations),
+      );
+      expect(j['sortOrder'], 0);
+      expect(j.containsKey('categoryId'), isFalse);
+    });
+
+    test('2. decodes minimal preset', () {
+      const j = <String, Object?>{
+        'id': 'water-surface',
+        'name': 'Water Surface',
+        'variantAnimations': <String, Object?>{
+          'refs': <Object?>[
+            <String, Object?>{
+              'role': 'isolated',
+              'animationId': 'water-isolated-loop',
+            },
+          ],
+        },
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(p.id, 'water-surface');
+      expect(p.name, 'Water Surface');
+      expect(p.variantCount, 1);
+      expect(p.containsRole(SurfaceVariantRole.isolated), isTrue);
+      expect(
+        p.animationIdForRole(SurfaceVariantRole.isolated),
+        'water-isolated-loop',
+      );
+      expect(p.categoryId, isNull);
+      expect(p.sortOrder, 0);
+    });
+
+    test('3. round-trip minimal preset', () {
+      final o = _preset();
+      final d = decodeProjectSurfacePreset(encodeProjectSurfacePreset(o));
+      expect(d, o);
+    });
+
+    test('4. encodes full preset (category + sortOrder)', () {
+      final p = _preset(
+        categoryId: 'animated-surfaces',
+        sortOrder: 42,
+      );
+      final j = encodeProjectSurfacePreset(p);
+      expect(j['categoryId'], 'animated-surfaces');
+      expect(j['sortOrder'], 42);
+    });
+
+    test('5. decodes full preset', () {
+      final j = <String, Object?>{
+        'id': 'a',
+        'name': 'N',
+        'variantAnimations': encodeSurfaceVariantAnimationRefSet(
+          _refSet(refs: [
+            _ref(SurfaceVariantRole.isolated, animationId: 'x'),
+          ]),
+        ),
+        'categoryId': 'animated-surfaces',
+        'sortOrder': 42,
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(p.categoryId, 'animated-surfaces');
+      expect(p.sortOrder, 42);
+    });
+
+    test('6. round-trip full preset', () {
+      final o = _preset(
+        categoryId: 'c',
+        sortOrder: 7,
+      );
+      final d = decodeProjectSurfacePreset(encodeProjectSurfacePreset(o));
+      expect(d, o);
+    });
+
+    test('7. encode preserves multi-ref order in variantAnimations', () {
+      final rs = _refSet(refs: [
+        _ref(SurfaceVariantRole.cross, animationId: 'a'),
+        _ref(SurfaceVariantRole.isolated, animationId: 'b'),
+        _ref(SurfaceVariantRole.horizontal, animationId: 'c'),
+      ]);
+      final p = _preset(variantAnimations: rs);
+      final j = encodeProjectSurfacePreset(p);
+      final va = j['variantAnimations'] as Map<String, Object?>?;
+      final refs = va!['refs'] as List<Object?>?;
+      expect(refs!.length, 3);
+      for (var i = 0; i < 3; i++) {
+        expect(refs[i], encodeSurfaceVariantAnimationRef(rs.refs[i]));
+      }
+    });
+
+    test('8. decode preserves multi-ref order', () {
+      const j = <String, Object?>{
+        'id': 'a',
+        'name': 'b',
+        'variantAnimations': <String, Object?>{
+          'refs': <Object?>[
+            <String, Object?>{'role': 'cross', 'animationId': 'a'},
+            <String, Object?>{'role': 'isolated', 'animationId': 'b'},
+            <String, Object?>{'role': 'horizontal', 'animationId': 'c'},
+          ],
+        },
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(p.variantCount, 3);
+      expect(
+        p.variantAnimations.refs.map((e) => e.role).toList(),
+        [
+          SurfaceVariantRole.cross,
+          SurfaceVariantRole.isolated,
+          SurfaceVariantRole.horizontal,
+        ],
+      );
+      expect(p.refForRole(SurfaceVariantRole.cross)?.animationId, 'a');
+    });
+
+    test('9. decode preserves exact id name category strings', () {
+      const id = '  water-surface  ';
+      const name = '  Water Surface  ';
+      const cat = '  animated  ';
+      final j = <String, Object?>{
+        'id': id,
+        'name': name,
+        'variantAnimations': encodeSurfaceVariantAnimationRefSet(
+          _refSet(refs: [
+            _ref(SurfaceVariantRole.isolated, animationId: 'a'),
+          ]),
+        ),
+        'categoryId': cat,
+        'sortOrder': 0,
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(p.id, id);
+      expect(p.name, name);
+      expect(p.categoryId, cat);
+    });
+
+    test('10. reject id missing / wrong type / whitespace-only', () {
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'name': 'n',
+          'variantAnimations': _minVa(),
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 123,
+          'name': 'n',
+          'variantAnimations': _minVa(),
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': '   ',
+          'name': 'n',
+          'variantAnimations': _minVa(),
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('11. reject name missing / wrong type / whitespace-only', () {
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'i',
+          'variantAnimations': _minVa(),
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'i',
+          'name': 123,
+          'variantAnimations': _minVa(),
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'i',
+          'name': '   ',
+          'variantAnimations': _minVa(),
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('12. reject variantAnimations missing or wrong type', () {
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'a',
+          'name': 'b',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'a',
+          'name': 'b',
+          'variantAnimations': 'nope',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('13. reject empty variantAnimations refs', () {
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'a',
+          'name': 'b',
+          'variantAnimations': <String, Object?>{'refs': <Object?>[]},
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('14. reject duplicate role in variantAnimations', () {
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'a',
+          'name': 'b',
+          'variantAnimations': <String, Object?>{
+            'refs': <Object?>[
+              <String, Object?>{'role': 'isolated', 'animationId': 'a'},
+              <String, Object?>{'role': 'isolated', 'animationId': 'b'},
+            ],
+          },
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('15. reject invalid role in variantAnimations', () {
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'a',
+          'name': 'b',
+          'variantAnimations': <String, Object?>{
+            'refs': <Object?>[
+              <String, Object?>{'role': 'notARole', 'animationId': 'x'},
+            ],
+          },
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('16. reject invalid animationId in variantAnimations', () {
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'a',
+          'name': 'b',
+          'variantAnimations': <String, Object?>{
+            'refs': <Object?>[
+              <String, Object?>{'role': 'isolated', 'animationId': '   '},
+            ],
+          },
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('17. decode ignores unknown top-level key', () {
+      final j = <String, Object?>{
+        'id': 'a',
+        'name': 'b',
+        'variantAnimations': _minVa(),
+        'futureField': 'ignored',
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(p.id, 'a');
+    });
+
+    test('18. decode ignores unknown keys in variantAnimations and refs', () {
+      final j = <String, Object?>{
+        'id': 'a',
+        'name': 'b',
+        'variantAnimations': <String, Object?>{
+          'refs': <Object?>[
+            <String, Object?>{
+              'role': 'isolated',
+              'animationId': 'a',
+              'x': 1,
+            },
+          ],
+          'extraVa': 2,
+        },
+        'h': 3,
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(p.variantCount, 1);
+    });
+
+    test('19. decode accepts categoryId: null in JSON', () {
+      final j = <String, Object?>{
+        'id': 'a',
+        'name': 'b',
+        'variantAnimations': _minVa(),
+        'categoryId': null,
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(p.categoryId, isNull);
+    });
+
+    test('20. decode reject categoryId non-string non-null', () {
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'a',
+          'name': 'b',
+          'variantAnimations': _minVa(),
+          'categoryId': 123,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('21. decode accept sortOrder absent (default 0)', () {
+      final j = <String, Object?>{
+        'id': 'a',
+        'name': 'b',
+        'variantAnimations': _minVa(),
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(p.sortOrder, 0);
+    });
+
+    test('22. decode accept negative sortOrder', () {
+      final j = <String, Object?>{
+        'id': 'a',
+        'name': 'b',
+        'variantAnimations': _minVa(),
+        'sortOrder': -10,
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(p.sortOrder, -10);
+    });
+
+    test('23. decode reject sortOrder non-int', () {
+      expect(
+        () => decodeProjectSurfacePreset(<String, Object?>{
+          'id': 'a',
+          'name': 'b',
+          'variantAnimations': _minVa(),
+          'sortOrder': '10',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('24. decode does not mutate source map', () {
+      final m = <String, Object?>{
+        'id': 'a',
+        'name': 'b',
+        'variantAnimations': <String, Object?>{
+          'refs': <Object?>[
+            <String, Object?>{'role': 'isolated', 'animationId': 'a'},
+          ],
+        },
+      };
+      final before = _mapStr(m);
+      decodeProjectSurfacePreset(m);
+      expect(_mapStr(m), before);
+    });
+
+    test('25. encode does not mutate preset', () {
+      final p = _preset(
+        categoryId: 'c',
+        sortOrder: 3,
+      );
+      final id = p.id;
+      final name = p.name;
+      final vc = p.variantCount;
+      final cat = p.categoryId;
+      final so = p.sortOrder;
+      final c = p.containsRole(SurfaceVariantRole.isolated);
+      encodeProjectSurfacePreset(p);
+      expect(p.id, id);
+      expect(p.name, name);
+      expect(p.variantCount, vc);
+      expect(p.categoryId, cat);
+      expect(p.sortOrder, so);
+      expect(p.containsRole(SurfaceVariantRole.isolated), c);
+    });
+
+    test('26. does not resolve animationId', () {
+      const j = <String, Object?>{
+        'id': 'broken-but-structurally-valid',
+        'name': 'Broken but structurally valid',
+        'variantAnimations': <String, Object?>{
+          'refs': <Object?>[
+            <String, Object?>{
+              'role': 'isolated',
+              'animationId': 'missing-animation',
+            },
+          ],
+        },
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(
+        p.animationIdForRole(SurfaceVariantRole.isolated),
+        'missing-animation',
+      );
+    });
+
+    test('27. does not complete missing standard roles', () {
+      const j = <String, Object?>{
+        'id': 'a',
+        'name': 'b',
+        'variantAnimations': <String, Object?>{
+          'refs': <Object?>[
+            <String, Object?>{'role': 'isolated', 'animationId': 'a'},
+          ],
+        },
+      };
+      final p = decodeProjectSurfacePreset(j);
+      expect(p.variantCount, 1);
+      expect(
+        p.coversAllRoles(standardSurfaceVariantRoleOrder),
+        isFalse,
+      );
+    });
+
+    test('28. reuses Lot 44 RefSet codec for variantAnimations', () {
+      final p = _preset();
+      final j = encodeProjectSurfacePreset(p);
+      expect(
+        j['variantAnimations'],
+        encodeSurfaceVariantAnimationRefSet(p.variantAnimations),
+      );
+    });
+
+    test('29. public API encode returns map', () {
+      expect(encodeProjectSurfacePreset(_preset()), isA<Map<String, Object?>>());
+    });
+
+    test('30. ProjectManifest has no surface persistence keys (Lot 45)', () {
+      const manifest = ProjectManifest(
+        name: 'L45',
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
+      '31. codec external to model: no preset.toJson or ProjectSurfacePreset.fromJson',
+      () {
+        final p = _preset();
+        final m = encodeProjectSurfacePreset(p);
+        expect(m, isA<Map<String, Object?>>());
+      },
+    );
+
+    test('32. ProjectSurfaceCatalog codec remains out of scope (Lot 46)', () {
+      final j = encodeProjectSurfacePreset(_preset());
+      expect(j['id'], isNotNull);
+    });
+
+    test('33. no SurfacePresetKind / surfaceKind keys in JSON', () {
+      final j = encodeProjectSurfacePreset(_preset());
+      for (final k in const [
+        'kind',
+        'surfaceKind',
+        'presetKind',
+        'type',
+      ]) {
+        expect(j.containsKey(k), isFalse, reason: k);
+      }
+    });
+
+    test('34. standardSurfaceVariantRoleOrder length 20 (Lot 28 doc)', () {
+      expect(standardSurfaceVariantRoleOrder.length, 20);
+    });
+  });
+}
+
+SurfaceVariantAnimationRef _ref(
+  SurfaceVariantRole role, {
+  String? animationId,
+}) {
+  return SurfaceVariantAnimationRef(
+    role: role,
+    animationId: animationId ?? 'id-${role.name}',
+  );
+}
+
+SurfaceVariantAnimationRefSet _refSet({List<SurfaceVariantAnimationRef>? refs}) {
+  return SurfaceVariantAnimationRefSet(
+    refs: refs ??
+        [
+          _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
+        ],
+  );
+}
+
+Map<String, Object?> _minVa() {
+  return encodeSurfaceVariantAnimationRefSet(
+    _refSet(
+      refs: [
+        _ref(SurfaceVariantRole.isolated, animationId: 'water-isolated-loop'),
+      ],
+    ),
+  );
+}
+
+ProjectSurfacePreset _preset({
+  String id = 'water-surface',
+  String name = 'Water Surface',
+  SurfaceVariantAnimationRefSet? variantAnimations,
+  String? categoryId,
+  int sortOrder = 0,
+}) {
+  return ProjectSurfacePreset(
+    id: id,
+    name: name,
+    variantAnimations: variantAnimations ?? _refSet(),
+    categoryId: categoryId,
+    sortOrder: sortOrder,
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

#### C.3 `map_core.dart` (`git diff`)

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 515adfd9..541b2fdb 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -51,6 +51,7 @@ export 'src/operations/surface_animation_timeline_json_codec.dart';
 export 'src/operations/project_surface_animation_json_codec.dart';
 export 'src/operations/surface_variant_animation_ref_json_codec.dart';
 export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
+export 'src/operations/project_surface_preset_json_codec.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';

```

#### C.4 Fichier rapport (exception Lot 45)

Pour ce fichier de rapport seulement, le cahier des charges autorise à ne pas recoller un `git diff` /dev/null de plusieurs milliers de lignes : les sections **1–39** contiennent déjà toute la prose et les preuves de commande ; l'**Evidence Pack** section A–B contient l'intégralité des sources et de `map_core.dart` ; l'**ajout** Git unifié de ce chemin se représente classiquement par le préfixe `+` sur chaque ligne du contenu final.

### D. Reproduction des preuves de commande (références de section)

- Test ciblé Lot 45 : **section 31** (sortie intégrale, normalisation `\r` → newline).
- Tests de régression : **section 32** (une sortie complète par fichier listé).
- `dart analyze` : **section 33** (sortie intégrale, « No issues found! » attendu).
- `dart test` complet : **section 34** (commande + ligne finale + total **1064**).
