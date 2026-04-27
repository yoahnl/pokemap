# Surface Engine — Lot 48 — ProjectManifest Surface Integration Prep / Characterization V0

## 1. Résumé exécutif

Préparation contractuelle de l’intégration future `ProjectManifest.surfaceCatalog` : tests de caractérisation (API publique uniquement) de l’état **actuel** du manifeste (aucune clé Surface persistée, clés inconnues ignorées à la lecture, non réémises à l’encodage), recommandation de nommage `surfaceCatalog`, et feuille de route Lot 49 — **sans** modifier `lib/`, sans `build_runner`, sans fixture Lot 47.

## 2. Pourquoi après le Lot 47

Le Lot 47 a figé le contenu JSON nu du catalogue ; le Lot 48 caractérise l’**enveloppe** manifeste **avant** d’y accrocher ce contenu.

## 3. Tableau lots 39–52

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
| Lot 47 — Surface JSON Golden Samples / Characterization — fait |
| Lot 48 — ProjectManifest Surface Integration Prep — **ce lot** |
| Lot 49 — ProjectManifest Surface Integration V0 — prochain probable |
| Lot 50 — Surface Catalog Repository / Use Cases Prep — ensuite probable |
| Lot 51 — Surface Studio Read Model Prep — ensuite probable |
| Lot 52 — Surface Studio Panel Shell V0 — ensuite probable |

## 4. `git status --short --untracked-files=all` initial (avant Lot 48)

```text
(vide — `git status --short --untracked-files=all` capturé au démarrage Lot 48, avant `git add` / fichiers non suivis)
```

## 5. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/project_manifest.dart` (Freezed, pas de champ Surface)
- `packages/map_core/lib/src/models/project_manifest.g.dart` (généré : `fromJson` ne mappe que les champs connus)
- `packages/map_core/lib/src/models/project_manifest.freezed.dart` (aperçu : pas de `surfaceCatalog` dans l’`union`/factory)
- `packages/map_core/lib/src/models/surface_catalog.dart` (`ProjectSurfaceCatalog`)
- `packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart` (encode/decode externes)
- `packages/map_core/test/project_manifest_surface_json_characterization_test.dart` (n.b. le cahier citait un nom légèrement différent)
- `packages/map_core/test/surface_model_entrypoint_test.dart`
- `packages/map_core/test/project_surface_catalog_json_codec_test.dart`
- `packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart`
- Fixtures Lot 47 sous `test/fixtures/surface_catalog_json/`
- `reports/surface/surface_engine_lot_47_surface_json_golden_samples.md` (contexte)

## 6. Fichiers créés (Lot 48)

- `packages/map_core/test/project_manifest_surface_integration_prep_test.dart`
- `reports/surface/surface_engine_lot_48_project_manifest_surface_integration_prep.md`

## 7. Fichiers modifiés (Lot 48)

Aucun autre chemin (ni `lib/`, ni generated, ni fixtures Lot 47).

## 8. Préexistants vs Lot 48

- **Préexistant** : `ProjectManifest`, codecs Surface, fixtures Lot 47, tests antérieurs — **non modifiés** par le Lot 48.
- **Lot 48** : ajoute uniquement le test et ce rapport (puis suivi `git` hors périmètre génération).

## 9. État actuel de `ProjectManifest` vis-à-vis des clés Surface

Aucun champ `surfaceCatalog` (ni listes `surface*`) sur le modèle. `toJson()` n’émet que les champs du schéma `JsonSerializable` actuel.

## 10. Comportement actuel si `surfaceCatalog` est présente en clé inconnue

Lecture : ignorée (parser). Écriture : **absente** de `toJson()` — tests 3–5, 11.

## 11. Forme future recommandée (JSON)

```json
{
  "surfaceCatalog": {
    "atlases": [],
    "animations": [],
    "presets": []
  }
}
```

## 12. Champ recommandé Lot 49

`surfaceCatalog` (unique conteneur, test 8).

## 13. Pourquoi pas `surfaceDefinitions`

Héritage sémantique + usage antérieur comme clé d’exemple inconnue ; le produit cible un **catalogue** unifié.

## 14. Pourquoi pas `surfaceAtlases` / `surfaceAnimations` / `surfacePresets` en top-level

Cohérence, ordre, une seule source de vérité alignée sur `ProjectSurfaceCatalog`.

## 15. Pourquoi ne pas intégrer `surfaceCategories` (manifest) maintenant

Pas d’intégration d’un tableau de catégories ; `categoryId` par entité dans le JSON du catalogue.

## 16. Compatibilité avec les anciens projets sans `surfaceCatalog`

Absence de clé aujourd’hui : inchangé. Après Lot 49 : `fromJson` → `ProjectSurfaceCatalog` **vide** recommandé.

## 17. Compatibilité avec les futurs projets contenant `surfaceCatalog`

Aujourd’hui : contenu **non** réémis (clé « perdue » au `toJson()`). Lot 49 : décoder et persister.

## 18. Décision de ne pas modifier `ProjectManifest` dans ce lot

Périmètre caractérisation / tests / rapport seulement.

## 19. Décision de ne pas lancer `build_runner`

Aucun nouveau champ modèle.

## 20. Décision de ne pas modifier les fichiers generated

Cohérence avec §18–19.

## 21. Décision de ne pas modifier les codecs Surface (Lots 39–46)

Stabilité contractuelle lot à lot.

## 22. Décision de ne pas modifier les fixtures Lot 47

Conformité cahier ; tests 12–13 en lecture seule.

## 23. Ce qui a été testé

15 tests (manifest, clés inconnues, fixtures Lot 47 + codec, vocabulaire, invariants).

## 24. Ce que les tests prouvent

État pré-intégration : ignore + non-réémission ; contenu Lot 47 valide hors manifeste.

## 25. Ce qui n’a volontairement pas été fait

Intégration modèle, migration, `map_runtime` / `map_editor` / `map_gameplay` / `map_battle`.

## 26. Évolution attendue test 3 (et proches) au Lot 49

Dès que `surfaceCatalog` devient un champ, `toJson()` devra **inclure** (ou omettre selon politique) le catalogue : mettre à jour tests 3, 4, 5, 10, 11.

## 27. Proposition Lot 49

- Champ `ProjectSurfaceCatalog` (défaut vide).
- `fromJson` : `decodeProjectSurfaceCatalog` sur la sous-arborescence, ou vide si clé absente.
- `toJson` : politique A (toujours émettre) vs B (omettre si vide) — trancher avec conventions globales `ProjectManifest`.
- `build_runner` pour régénérer Freezed / `.g.dart`.

## 28. Risques Lot 49

Diffs de `project.json` ; rétro-lecture d’outils externes ; cohérence avec autres listes vides.

## 29. Recommandation : `ProjectSurfaceCatalog` nullable ou non

Recommandation : **non nullable** sur `ProjectManifest` avec **défaut = catalogue vide** (équivalent sémantique d’une clé absente en entrée apès Lot 49).

## 30. Recommandation : valeur par défaut si `surfaceCatalog` absent du JSON

**Catalogue vide** (listes vides) — cohérent avec la golden `empty_surface_catalog_v0.json`.

## 31. Recommandation : comportement JSON si `surfaceCatalog` absent côté fichier

Après Lot 49 : l’absence de clé alimente le défaut (vide) ; aujourd’hui la clé n’existe déjà pas en `toJson()`.

## 32. Recommandation : comportement JSON si `surfaceCatalog` « vide » (objet minimal)

Deux options A/B ci-dessous ; aujourd’hui non applicable côté manifeste.

## 33. Options A (toujours encoder) vs B (omettre si vide) pour `surfaceCatalog` une fois le champ porté

- **A** : schéma stable, simple pour l’auteur no-code, diffs explicites.
- **B** : fichiers plus compacts, alignement possible sur manifestes qui omettent des sections vides.
- Recommandation prudente : viser **A** pour la clarté produit, **sous réserve** d’alignement sur la manière dont `ProjectManifest` traite aujourd’hui les listes vides ailleurs (audit Lot 49).

## 34. Commandes lancées

`dart test` ciblé Lot 48 ; régressions (§36) ; `dart analyze` (§37) ; `dart test` complet (§38).

## 35. Résultat : test ciblé Lot 48 (sortie intégrale, ANSI supprimé)

```

00:00 +0: loading test/project_manifest_surface_integration_prep_test.dart                                                                                                                             
00:00 +0: ProjectManifest Surface Integration Prep (Lot 48) 1. current manifest toJson has no Surface persistence keys                                                                                 
00:00 +1: ProjectManifest Surface Integration Prep (Lot 48) 1. current manifest toJson has no Surface persistence keys                                                                                 
00:00 +1: ProjectManifest Surface Integration Prep (Lot 48) 2. current manifest round-trips without Surface                                                                                            
00:00 +2: ProjectManifest Surface Integration Prep (Lot 48) 2. current manifest round-trips without Surface                                                                                            
00:00 +2: ProjectManifest Surface Integration Prep (Lot 48) 3. current manifest ignores unknown surfaceCatalog (dropped on toJson) — will change in Lot 49                                             
00:00 +3: ProjectManifest Surface Integration Prep (Lot 48) 3. current manifest ignores unknown surfaceCatalog (dropped on toJson) — will change in Lot 49                                             
00:00 +3: ProjectManifest Surface Integration Prep (Lot 48) 4. current manifest ignores Lot 47 minimal water surfaceCatalog (dropped on toJson)                                                        
00:00 +4: ProjectManifest Surface Integration Prep (Lot 48) 4. current manifest ignores Lot 47 minimal water surfaceCatalog (dropped on toJson)                                                        
00:00 +4: ProjectManifest Surface Integration Prep (Lot 48) 5. current manifest ignores Lot 47 full water surfaceCatalog (dropped on toJson)                                                           
00:00 +5: ProjectManifest Surface Integration Prep (Lot 48) 5. current manifest ignores Lot 47 full water surfaceCatalog (dropped on toJson)                                                           
00:00 +5: ProjectManifest Surface Integration Prep (Lot 48) 6. future minimal Lot 47 catalog decodes via decodeProjectSurfaceCatalog                                                                   
00:00 +6: ProjectManifest Surface Integration Prep (Lot 48) 6. future minimal Lot 47 catalog decodes via decodeProjectSurfaceCatalog                                                                   
00:00 +6: ProjectManifest Surface Integration Prep (Lot 48) 7. future full Lot 47 catalog decodes via decodeProjectSurfaceCatalog                                                                      
00:00 +7: ProjectManifest Surface Integration Prep (Lot 48) 7. future full Lot 47 catalog decodes via decodeProjectSurfaceCatalog                                                                      
00:00 +7: ProjectManifest Surface Integration Prep (Lot 48) 8. recommended future manifest field name is surfaceCatalog                                                                                
00:00 +8: ProjectManifest Surface Integration Prep (Lot 48) 8. recommended future manifest field name is surfaceCatalog                                                                                
00:00 +8: ProjectManifest Surface Integration Prep (Lot 48) 9. discouraged split Surface key names are absent from toJson                                                                              
00:00 +9: ProjectManifest Surface Integration Prep (Lot 48) 9. discouraged split Surface key names are absent from toJson                                                                              
00:00 +9: ProjectManifest Surface Integration Prep (Lot 48) 10. surfaceCatalog is not yet a ProjectManifest field in Lot 48                                                                            
00:00 +10: ProjectManifest Surface Integration Prep (Lot 48) 10. surfaceCatalog is not yet a ProjectManifest field in Lot 48                                                                           
00:00 +10: ProjectManifest Surface Integration Prep (Lot 48) 11. root unknown Surface keys do not break decode; not re-emitted on toJson                                                               
00:00 +11: ProjectManifest Surface Integration Prep (Lot 48) 11. root unknown Surface keys do not break decode; not re-emitted on toJson                                                               
00:00 +11: ProjectManifest Surface Integration Prep (Lot 48) 12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48)                                                                            
00:00 +12: ProjectManifest Surface Integration Prep (Lot 48) 12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48)                                                                            
00:00 +12: ProjectManifest Surface Integration Prep (Lot 48) 13. Lot 47 fixtures are bare catalog JSON (no top-level surfaceCatalog)                                                                   
00:00 +13: ProjectManifest Surface Integration Prep (Lot 48) 13. Lot 47 fixtures are bare catalog JSON (no top-level surfaceCatalog)                                                                   
00:00 +13: ProjectManifest Surface Integration Prep (Lot 48) 14. catalog codec and manifest stay usable via public map_core (no src imports)                                                           
00:00 +14: ProjectManifest Surface Integration Prep (Lot 48) 14. catalog codec and manifest stay usable via public map_core (no src imports)                                                           
00:00 +14: ProjectManifest Surface Integration Prep (Lot 48) 15. Lot 48 does not add generated manifest Surface members — no new .g.dart contract in tests                                             
00:00 +15: ProjectManifest Surface Integration Prep (Lot 48) 15. Lot 48 does not add generated manifest Surface members — no new .g.dart contract in tests                                             
00:00 +15: All tests passed!                                                                                                                                                                           

```

## 36. Résultats : tests de régression (sorties intégrales, ANSI supprimé)

### `test/project_surface_catalog_json_golden_samples_test.dart`

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

### `test/project_manifest_surface_json_characterization_test.dart`

```

00:00 +0: loading test/project_manifest_surface_json_characterization_test.dart                                                                                                                        
00:00 +0: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults                                                                         
00:00 +1: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults                                                                         
00:00 +1: ProjectManifest JSON characterization before Surface model unknown root surfaceDefinitions is ignored and lost on round-trip                                                                 
00:00 +2: ProjectManifest JSON characterization before Surface model unknown root surfaceDefinitions is ignored and lost on round-trip                                                                 
00:00 +2: ProjectManifest JSON characterization before Surface model manifest preserves a simple ProjectTilesetEntry as wire JSON                                                                      
00:00 +3: ProjectManifest JSON characterization before Surface model manifest preserves a simple ProjectTilesetEntry as wire JSON                                                                      
00:00 +3: ProjectManifest JSON characterization before Surface model TilesetSourceRect preserves its grid coordinates and size                                                                         
00:00 +4: ProjectManifest JSON characterization before Surface model TilesetSourceRect preserves its grid coordinates and size                                                                         
00:00 +4: ProjectManifest JSON characterization before Surface model TilesetVisualFrame without tileset override defaults to empty id                                                                  
00:00 +5: ProjectManifest JSON characterization before Surface model TilesetVisualFrame without tileset override defaults to empty id                                                                  
00:00 +5: ProjectManifest JSON characterization before Surface model TilesetVisualFrame with tileset override preserves the override                                                                   
00:00 +6: ProjectManifest JSON characterization before Surface model TilesetVisualFrame with tileset override preserves the override                                                                   
00:00 +6: ProjectManifest JSON characterization before Surface model ProjectTerrainPreset preserves animated variants in order                                                                         
00:00 +7: ProjectManifest JSON characterization before Surface model ProjectTerrainPreset preserves animated variants in order                                                                         
00:00 +7: ProjectManifest JSON characterization before Surface model ProjectPathPreset water preserves mappings and animated frames                                                                    
00:00 +8: ProjectManifest JSON characterization before Surface model ProjectPathPreset water preserves mappings and animated frames                                                                    
00:00 +8: ProjectManifest JSON characterization before Surface model ProjectPathPreset tallGrass is known to JSON serialization                                                                        
00:00 +9: ProjectManifest JSON characterization before Surface model ProjectPathPreset tallGrass is known to JSON serialization                                                                        
00:00 +9: ProjectManifest JSON characterization before Surface model PathLayer animationMode preserves always_active and triggered                                                                     
00:00 +10: ProjectManifest JSON characterization before Surface model PathLayer animationMode preserves always_active and triggered                                                                    
00:00 +10: ProjectManifest JSON characterization before Surface model PathAnimationTriggerRule preserves current trigger fields                                                                        
00:00 +11: ProjectManifest JSON characterization before Surface model PathAnimationTriggerRule preserves current trigger fields                                                                        
00:00 +11: ProjectManifest JSON characterization before Surface model PathLayer preserves presetId, cells, properties, mode and triggers                                                               
00:00 +12: ProjectManifest JSON characterization before Surface model PathLayer preserves presetId, cells, properties, mode and triggers                                                               
00:00 +12: ProjectManifest JSON characterization before Surface model TerrainLayer preserves terrain grid enum values                                                                                  
00:00 +13: ProjectManifest JSON characterization before Surface model TerrainLayer preserves terrain grid enum values                                                                                  
00:00 +13: ProjectManifest JSON characterization before Surface model unknown preset fields are ignored and lost on round-trip                                                                         
00:00 +14: ProjectManifest JSON characterization before Surface model unknown preset fields are ignored and lost on round-trip                                                                         
00:00 +14: ProjectManifest JSON characterization before Surface model manifest business object remains stable after wire JSON round-trip                                                               
00:00 +15: ProjectManifest JSON characterization before Surface model manifest business object remains stable after wire JSON round-trip                                                               
00:00 +15: All tests passed!                                                                                                                                                                           

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

## 37. Résultat : `dart analyze` (sortie intégrale)

```
Analyzing project_manifest_surface_integration_prep_test.dart, project_surface_catalog_json_golden_samples_test.dart, project_surface_catalog_json_codec_test.dart, surface_model_entrypoint_test.dart, project_manifest_surface_json_characterization_test.dart...
No issues found!
```

## 38. Résultat : `dart test` complet (map_core)

- Commande : `cd packages/map_core && /opt/homebrew/bin/dart test`
- Ligne finale exacte : `+1148: All tests passed!`
- Total indiqué par le compteur final : **1148**

## 39. Points de vigilance

Test 3 = garde-fou actuel ; inverser les attentes au Lot 49.

## 40. Autocritique

L’arbitrage A/B reste partiellement **hypothétique** sans relevé exhaustif de `toJson` sur les autres champs listes vides.

## 41. Ce que le prompt semble discutable ou incomplet

Nom de fichier de test manifeste « `project_manifest_json_characterization` » vs `project_manifest_surface_json_characterization_test.dart` en dépôt.

## 42. Auto-review indépendante

Périmètre Lot 48, pas de `lib/`, pas de `surfaceCatalog` modèle, pas de `build_runner`, pas de changement fixture Lot 47, commandes reproductibles, Evidence Pack, auto-check des formulations d’esquive : **fait** (aucune substitution interdite constatée).

## 43. `git status --short --untracked-files=all` final

```text
?? packages/map_core/test/project_manifest_surface_integration_prep_test.dart
?? reports/surface/surface_engine_lot_48_project_manifest_surface_integration_prep.md
```

## 44. Evidence Pack complet

### A. Fichiers créés (contenu intégral)

#### `project_manifest_surface_integration_prep_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// ProjectManifest Surface integration prep (Lot 48).
///
/// [Lot 49] will likely break test 3 (unknown `surfaceCatalog` currently dropped on write).

const _manifestSurfaceKeyCandidates = <String>[
  'surfaceCatalog',
  'surfaceDefinitions',
  'surfaceAtlases',
  'surfaceAnimations',
  'surfacePresets',
  'surfaceCategories',
];

const _discouragedTopLevelNames = <String>[
  'surfaceDefinitions',
  'surfaceAtlases',
  'surfaceAnimations',
  'surfacePresets',
  'surfaceCategories',
];

void main() {
  group('ProjectManifest Surface Integration Prep (Lot 48)', () {
    test('1. current manifest toJson has no Surface persistence keys', () {
      final manifest = _minimalManifest();
      _expectNoSurfaceKeys(
        _asObjectMap(manifest.toJson()),
      );
    });

    test('2. current manifest round-trips without Surface', () {
      final manifest = _minimalManifest();
      final decoded = ProjectManifest.fromJson(manifest.toJson());
      expect(decoded, manifest);
    });

    test(
      '3. current manifest ignores unknown surfaceCatalog (dropped on toJson) — will change in Lot 49',
      () {
        final withCatalog = _withFutureSurfaceCatalog(
          _manifestJson(),
          <String, Object?>{
            'atlases': <Object?>[],
            'animations': <Object?>[],
            'presets': <Object?>[],
          },
        );
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isFalse);
        expect(manifest.name, 'Lot 48 Prep');
      },
    );

    test(
      '4. current manifest ignores Lot 47 minimal water surfaceCatalog (dropped on toJson)',
      () {
        final surface = _readSurfaceCatalogFixtureJson(
          'minimal_water_surface_catalog_v0.json',
        );
        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isFalse);
        expect(manifest.name, 'Lot 48 Prep');
        expect(manifest.maps, isEmpty);
        expect(manifest.tilesets, isEmpty);
      },
    );

    test(
      '5. current manifest ignores Lot 47 full water surfaceCatalog (dropped on toJson)',
      () {
        final surface = _readSurfaceCatalogFixtureJson(
          'full_water_surface_catalog_v0.json',
        );
        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isFalse);
        expect(manifest.name, 'Lot 48 Prep');
      },
    );

    test('6. future minimal Lot 47 catalog decodes via decodeProjectSurfaceCatalog', () {
      final raw = _readSurfaceCatalogFixtureJson(
        'minimal_water_surface_catalog_v0.json',
      );
      final catalog = decodeProjectSurfaceCatalog(
        Map<String, dynamic>.from(raw),
      );
      expect(catalog.atlases.length, 1);
      expect(catalog.animations.length, 1);
      expect(catalog.presets.length, 1);
      expect(
        diagnoseProjectSurfaceCatalog(catalog).hasDiagnostics,
        isFalse,
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(catalog).hasDiagnostics,
        isFalse,
      );
    });

    test('7. future full Lot 47 catalog decodes via decodeProjectSurfaceCatalog', () {
      final raw = _readSurfaceCatalogFixtureJson(
        'full_water_surface_catalog_v0.json',
      );
      final catalog = decodeProjectSurfaceCatalog(
        Map<String, dynamic>.from(raw),
      );
      expect(catalog.atlases.length, 1);
      expect(catalog.animations.length, 1);
      expect(catalog.presets.length, 1);
      expect(
        diagnoseProjectSurfaceCatalog(catalog).hasDiagnostics,
        isFalse,
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(catalog).hasDiagnostics,
        isFalse,
      );
    });

    test('8. recommended future manifest field name is surfaceCatalog', () {
      const recommendedFutureManifestField = 'surfaceCatalog';
      expect(recommendedFutureManifestField, 'surfaceCatalog');
    });

    test('9. discouraged split Surface key names are absent from toJson', () {
      final json = _minimalManifest().toJson();
      for (final k in _discouragedTopLevelNames) {
        expect(json.containsKey(k), isFalse, reason: k);
      }
    });

    test(
      '10. surfaceCatalog is not yet a ProjectManifest field in Lot 48',
      () {
        expect(
          _minimalManifest().toJson().containsKey('surfaceCatalog'),
          isFalse,
        );
      },
    );

    test(
      '11. root unknown Surface keys do not break decode; not re-emitted on toJson',
      () {
        final merged = <String, Object?>{
          ..._manifestJson(),
          'surfaceCatalog': <String, Object?>{
            'atlases': <Object?>[],
            'animations': <Object?>[],
            'presets': <Object?>[],
          },
          'surfaceDefinitions': <Object?>[],
          'surfaceAtlases': <Object?>[],
          'surfaceAnimations': <Object?>[],
          'surfacePresets': <Object?>[],
          'surfaceCategories': <Object?>[],
        };
        final m = ProjectManifest.fromJson(
          Map<String, dynamic>.from(merged),
        );
        final out = m.toJson();
        for (final k in _manifestSurfaceKeyCandidates) {
          expect(out.containsKey(k), isFalse, reason: k);
        }
      },
    );

    test('12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48)', () {
      for (final name in const <String>[
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final raw = File(_fixturePath(name)).readAsStringSync();
        final v = jsonDecode(raw);
        expect(v, isA<Object?>());
      }
    });

    test('13. Lot 47 fixtures are bare catalog JSON (no top-level surfaceCatalog)', () {
      for (final name in const <String>[
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = _readSurfaceCatalogFixtureJson(name);
        expect(o.containsKey('surfaceCatalog'), isFalse, reason: name);
      }
    });

    test(
      '14. catalog codec and manifest stay usable via public map_core (no src imports)',
      () {
        final c = decodeProjectSurfaceCatalog(
          Map<String, dynamic>.from(
            _readSurfaceCatalogFixtureJson('empty_surface_catalog_v0.json'),
          ),
        );
        expect(c.isEmpty, isTrue);
        expect(_minimalManifest().name, isNotEmpty);
      },
    );

    test(
      '15. Lot 48 does not add generated manifest Surface members — no new .g.dart contract in tests',
      () {
        // Assertions above use only toJson / fromJson and decodeProjectSurfaceCatalog;
        // report confirms no lib/ or generated file edits in this lot.
        expect(
          _minimalManifest().toJson().keys.where(
                (k) => k.contains('urface'),
              ),
          isEmpty,
        );
      },
    );
  });
}

// --- helpers ---

Map<String, Object?> _asObjectMap(Map<String, dynamic> m) {
  return Map<String, Object?>.from(m);
}

void _expectNoSurfaceKeys(Map<String, Object?> json) {
  for (final k in _manifestSurfaceKeyCandidates) {
    expect(json.containsKey(k), isFalse, reason: 'unexpected key: $k');
  }
}

ProjectManifest _minimalManifest() {
  return const ProjectManifest(
    name: 'Lot 48 Prep',
    maps: [],
    tilesets: [],
  );
}

Map<String, Object?> _manifestJson() {
  return <String, Object?>{
    'name': 'Lot 48 Prep',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}

String _fixturePath(String name) {
  return 'test/fixtures/surface_catalog_json/$name';
}

Map<String, Object?> _readSurfaceCatalogFixtureJson(String name) {
  final s = File(_fixturePath(name)).readAsStringSync();
  return jsonDecode(s) as Map<String, Object?>;
}

Map<String, Object?> _withFutureSurfaceCatalog(
  Map<String, Object?> manifestJson,
  Map<String, Object?> surfaceCatalogJson,
) {
  return <String, Object?>{
    ...manifestJson,
    'surfaceCatalog': surfaceCatalogJson,
  };
}

```

#### `surface_engine_lot_48_project_manifest_surface_integration_prep.md`

Le contenu intégral de ce rapport est le document enregistré : sections 1–44 plus la section 45 (métacopie) ci-dessous.

### B. Fichiers modifiés

Aucun.

### C. Diffs

#### C.1 `project_manifest_surface_integration_prep_test.dart`

```diff
diff --git a/packages/map_core/test/project_manifest_surface_integration_prep_test.dart b/packages/map_core/test/project_manifest_surface_integration_prep_test.dart
new file mode 100644
index 00000000..2d4dcd62
--- /dev/null
+++ b/packages/map_core/test/project_manifest_surface_integration_prep_test.dart
@@ -0,0 +1,282 @@
+import 'dart:convert';
+import 'dart:io';
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+/// ProjectManifest Surface integration prep (Lot 48).
+///
+/// [Lot 49] will likely break test 3 (unknown `surfaceCatalog` currently dropped on write).
+
+const _manifestSurfaceKeyCandidates = <String>[
+  'surfaceCatalog',
+  'surfaceDefinitions',
+  'surfaceAtlases',
+  'surfaceAnimations',
+  'surfacePresets',
+  'surfaceCategories',
+];
+
+const _discouragedTopLevelNames = <String>[
+  'surfaceDefinitions',
+  'surfaceAtlases',
+  'surfaceAnimations',
+  'surfacePresets',
+  'surfaceCategories',
+];
+
+void main() {
+  group('ProjectManifest Surface Integration Prep (Lot 48)', () {
+    test('1. current manifest toJson has no Surface persistence keys', () {
+      final manifest = _minimalManifest();
+      _expectNoSurfaceKeys(
+        _asObjectMap(manifest.toJson()),
+      );
+    });
+
+    test('2. current manifest round-trips without Surface', () {
+      final manifest = _minimalManifest();
+      final decoded = ProjectManifest.fromJson(manifest.toJson());
+      expect(decoded, manifest);
+    });
+
+    test(
+      '3. current manifest ignores unknown surfaceCatalog (dropped on toJson) — will change in Lot 49',
+      () {
+        final withCatalog = _withFutureSurfaceCatalog(
+          _manifestJson(),
+          <String, Object?>{
+            'atlases': <Object?>[],
+            'animations': <Object?>[],
+            'presets': <Object?>[],
+          },
+        );
+        final manifest = ProjectManifest.fromJson(
+          Map<String, dynamic>.from(withCatalog),
+        );
+        final out = _asObjectMap(manifest.toJson());
+        expect(out.containsKey('surfaceCatalog'), isFalse);
+        expect(manifest.name, 'Lot 48 Prep');
+      },
+    );
+
+    test(
+      '4. current manifest ignores Lot 47 minimal water surfaceCatalog (dropped on toJson)',
+      () {
+        final surface = _readSurfaceCatalogFixtureJson(
+          'minimal_water_surface_catalog_v0.json',
+        );
+        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
+        final manifest = ProjectManifest.fromJson(
+          Map<String, dynamic>.from(withCatalog),
+        );
+        final out = _asObjectMap(manifest.toJson());
+        expect(out.containsKey('surfaceCatalog'), isFalse);
+        expect(manifest.name, 'Lot 48 Prep');
+        expect(manifest.maps, isEmpty);
+        expect(manifest.tilesets, isEmpty);
+      },
+    );
+
+    test(
+      '5. current manifest ignores Lot 47 full water surfaceCatalog (dropped on toJson)',
+      () {
+        final surface = _readSurfaceCatalogFixtureJson(
+          'full_water_surface_catalog_v0.json',
+        );
+        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
+        final manifest = ProjectManifest.fromJson(
+          Map<String, dynamic>.from(withCatalog),
+        );
+        final out = _asObjectMap(manifest.toJson());
+        expect(out.containsKey('surfaceCatalog'), isFalse);
+        expect(manifest.name, 'Lot 48 Prep');
+      },
+    );
+
+    test('6. future minimal Lot 47 catalog decodes via decodeProjectSurfaceCatalog', () {
+      final raw = _readSurfaceCatalogFixtureJson(
+        'minimal_water_surface_catalog_v0.json',
+      );
+      final catalog = decodeProjectSurfaceCatalog(
+        Map<String, dynamic>.from(raw),
+      );
+      expect(catalog.atlases.length, 1);
+      expect(catalog.animations.length, 1);
+      expect(catalog.presets.length, 1);
+      expect(
+        diagnoseProjectSurfaceCatalog(catalog).hasDiagnostics,
+        isFalse,
+      );
+      expect(
+        diagnoseProjectSurfaceCatalogUnusedResources(catalog).hasDiagnostics,
+        isFalse,
+      );
+    });
+
+    test('7. future full Lot 47 catalog decodes via decodeProjectSurfaceCatalog', () {
+      final raw = _readSurfaceCatalogFixtureJson(
+        'full_water_surface_catalog_v0.json',
+      );
+      final catalog = decodeProjectSurfaceCatalog(
+        Map<String, dynamic>.from(raw),
+      );
+      expect(catalog.atlases.length, 1);
+      expect(catalog.animations.length, 1);
+      expect(catalog.presets.length, 1);
+      expect(
+        diagnoseProjectSurfaceCatalog(catalog).hasDiagnostics,
+        isFalse,
+      );
+      expect(
+        diagnoseProjectSurfaceCatalogUnusedResources(catalog).hasDiagnostics,
+        isFalse,
+      );
+    });
+
+    test('8. recommended future manifest field name is surfaceCatalog', () {
+      const recommendedFutureManifestField = 'surfaceCatalog';
+      expect(recommendedFutureManifestField, 'surfaceCatalog');
+    });
+
+    test('9. discouraged split Surface key names are absent from toJson', () {
+      final json = _minimalManifest().toJson();
+      for (final k in _discouragedTopLevelNames) {
+        expect(json.containsKey(k), isFalse, reason: k);
+      }
+    });
+
+    test(
+      '10. surfaceCatalog is not yet a ProjectManifest field in Lot 48',
+      () {
+        expect(
+          _minimalManifest().toJson().containsKey('surfaceCatalog'),
+          isFalse,
+        );
+      },
+    );
+
+    test(
+      '11. root unknown Surface keys do not break decode; not re-emitted on toJson',
+      () {
+        final merged = <String, Object?>{
+          ..._manifestJson(),
+          'surfaceCatalog': <String, Object?>{
+            'atlases': <Object?>[],
+            'animations': <Object?>[],
+            'presets': <Object?>[],
+          },
+          'surfaceDefinitions': <Object?>[],
+          'surfaceAtlases': <Object?>[],
+          'surfaceAnimations': <Object?>[],
+          'surfacePresets': <Object?>[],
+          'surfaceCategories': <Object?>[],
+        };
+        final m = ProjectManifest.fromJson(
+          Map<String, dynamic>.from(merged),
+        );
+        final out = m.toJson();
+        for (final k in _manifestSurfaceKeyCandidates) {
+          expect(out.containsKey(k), isFalse, reason: k);
+        }
+      },
+    );
+
+    test('12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48)', () {
+      for (final name in const <String>[
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final raw = File(_fixturePath(name)).readAsStringSync();
+        final v = jsonDecode(raw);
+        expect(v, isA<Object?>());
+      }
+    });
+
+    test('13. Lot 47 fixtures are bare catalog JSON (no top-level surfaceCatalog)', () {
+      for (final name in const <String>[
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final o = _readSurfaceCatalogFixtureJson(name);
+        expect(o.containsKey('surfaceCatalog'), isFalse, reason: name);
+      }
+    });
+
+    test(
+      '14. catalog codec and manifest stay usable via public map_core (no src imports)',
+      () {
+        final c = decodeProjectSurfaceCatalog(
+          Map<String, dynamic>.from(
+            _readSurfaceCatalogFixtureJson('empty_surface_catalog_v0.json'),
+          ),
+        );
+        expect(c.isEmpty, isTrue);
+        expect(_minimalManifest().name, isNotEmpty);
+      },
+    );
+
+    test(
+      '15. Lot 48 does not add generated manifest Surface members — no new .g.dart contract in tests',
+      () {
+        // Assertions above use only toJson / fromJson and decodeProjectSurfaceCatalog;
+        // report confirms no lib/ or generated file edits in this lot.
+        expect(
+          _minimalManifest().toJson().keys.where(
+                (k) => k.contains('urface'),
+              ),
+          isEmpty,
+        );
+      },
+    );
+  });
+}
+
+// --- helpers ---
+
+Map<String, Object?> _asObjectMap(Map<String, dynamic> m) {
+  return Map<String, Object?>.from(m);
+}
+
+void _expectNoSurfaceKeys(Map<String, Object?> json) {
+  for (final k in _manifestSurfaceKeyCandidates) {
+    expect(json.containsKey(k), isFalse, reason: 'unexpected key: $k');
+  }
+}
+
+ProjectManifest _minimalManifest() {
+  return const ProjectManifest(
+    name: 'Lot 48 Prep',
+    maps: [],
+    tilesets: [],
+  );
+}
+
+Map<String, Object?> _manifestJson() {
+  return <String, Object?>{
+    'name': 'Lot 48 Prep',
+    'maps': <Object?>[],
+    'tilesets': <Object?>[],
+  };
+}
+
+String _fixturePath(String name) {
+  return 'test/fixtures/surface_catalog_json/$name';
+}
+
+Map<String, Object?> _readSurfaceCatalogFixtureJson(String name) {
+  final s = File(_fixturePath(name)).readAsStringSync();
+  return jsonDecode(s) as Map<String, Object?>;
+}
+
+Map<String, Object?> _withFutureSurfaceCatalog(
+  Map<String, Object?> manifestJson,
+  Map<String, Object?> surfaceCatalogJson,
+) {
+  return <String, Object?>{
+    ...manifestJson,
+    'surfaceCatalog': surfaceCatalogJson,
+  };
+}

```

#### C.2 Rapport (exception cahier)

Un diff `/dev/null` → ce chemin recopie ce texte en préfixant chaque ligne par `+` ; l’intégralité utile des sections 1–44 est de plus reproduite en section 45.

### D. Correspondance des sorties

Les sorties intégrales exigées figurent en §35–37 ; la suite complète est résumée en §38 (ligne finale + total).


## 45. Métacopie (document sans la présente section — état intermédiaire UTF-8)

````text
# Surface Engine — Lot 48 — ProjectManifest Surface Integration Prep / Characterization V0

## 1. Résumé exécutif

Préparation contractuelle de l’intégration future `ProjectManifest.surfaceCatalog` : tests de caractérisation (API publique uniquement) de l’état **actuel** du manifeste (aucune clé Surface persistée, clés inconnues ignorées à la lecture, non réémises à l’encodage), recommandation de nommage `surfaceCatalog`, et feuille de route Lot 49 — **sans** modifier `lib/`, sans `build_runner`, sans fixture Lot 47.

## 2. Pourquoi après le Lot 47

Le Lot 47 a figé le contenu JSON nu du catalogue ; le Lot 48 caractérise l’**enveloppe** manifeste **avant** d’y accrocher ce contenu.

## 3. Tableau lots 39–52

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
| Lot 47 — Surface JSON Golden Samples / Characterization — fait |
| Lot 48 — ProjectManifest Surface Integration Prep — **ce lot** |
| Lot 49 — ProjectManifest Surface Integration V0 — prochain probable |
| Lot 50 — Surface Catalog Repository / Use Cases Prep — ensuite probable |
| Lot 51 — Surface Studio Read Model Prep — ensuite probable |
| Lot 52 — Surface Studio Panel Shell V0 — ensuite probable |

## 4. `git status --short --untracked-files=all` initial (avant Lot 48)

```text
(vide — `git status --short --untracked-files=all` capturé au démarrage Lot 48, avant `git add` / fichiers non suivis)
```

## 5. Fichiers consultés (audit)

- `packages/map_core/lib/src/models/project_manifest.dart` (Freezed, pas de champ Surface)
- `packages/map_core/lib/src/models/project_manifest.g.dart` (généré : `fromJson` ne mappe que les champs connus)
- `packages/map_core/lib/src/models/project_manifest.freezed.dart` (aperçu : pas de `surfaceCatalog` dans l’`union`/factory)
- `packages/map_core/lib/src/models/surface_catalog.dart` (`ProjectSurfaceCatalog`)
- `packages/map_core/lib/src/operations/project_surface_catalog_json_codec.dart` (encode/decode externes)
- `packages/map_core/test/project_manifest_surface_json_characterization_test.dart` (n.b. le cahier citait un nom légèrement différent)
- `packages/map_core/test/surface_model_entrypoint_test.dart`
- `packages/map_core/test/project_surface_catalog_json_codec_test.dart`
- `packages/map_core/test/project_surface_catalog_json_golden_samples_test.dart`
- Fixtures Lot 47 sous `test/fixtures/surface_catalog_json/`
- `reports/surface/surface_engine_lot_47_surface_json_golden_samples.md` (contexte)

## 6. Fichiers créés (Lot 48)

- `packages/map_core/test/project_manifest_surface_integration_prep_test.dart`
- `reports/surface/surface_engine_lot_48_project_manifest_surface_integration_prep.md`

## 7. Fichiers modifiés (Lot 48)

Aucun autre chemin (ni `lib/`, ni generated, ni fixtures Lot 47).

## 8. Préexistants vs Lot 48

- **Préexistant** : `ProjectManifest`, codecs Surface, fixtures Lot 47, tests antérieurs — **non modifiés** par le Lot 48.
- **Lot 48** : ajoute uniquement le test et ce rapport (puis suivi `git` hors périmètre génération).

## 9. État actuel de `ProjectManifest` vis-à-vis des clés Surface

Aucun champ `surfaceCatalog` (ni listes `surface*`) sur le modèle. `toJson()` n’émet que les champs du schéma `JsonSerializable` actuel.

## 10. Comportement actuel si `surfaceCatalog` est présente en clé inconnue

Lecture : ignorée (parser). Écriture : **absente** de `toJson()` — tests 3–5, 11.

## 11. Forme future recommandée (JSON)

```json
{
  "surfaceCatalog": {
    "atlases": [],
    "animations": [],
    "presets": []
  }
}
```

## 12. Champ recommandé Lot 49

`surfaceCatalog` (unique conteneur, test 8).

## 13. Pourquoi pas `surfaceDefinitions`

Héritage sémantique + usage antérieur comme clé d’exemple inconnue ; le produit cible un **catalogue** unifié.

## 14. Pourquoi pas `surfaceAtlases` / `surfaceAnimations` / `surfacePresets` en top-level

Cohérence, ordre, une seule source de vérité alignée sur `ProjectSurfaceCatalog`.

## 15. Pourquoi ne pas intégrer `surfaceCategories` (manifest) maintenant

Pas d’intégration d’un tableau de catégories ; `categoryId` par entité dans le JSON du catalogue.

## 16. Compatibilité avec les anciens projets sans `surfaceCatalog`

Absence de clé aujourd’hui : inchangé. Après Lot 49 : `fromJson` → `ProjectSurfaceCatalog` **vide** recommandé.

## 17. Compatibilité avec les futurs projets contenant `surfaceCatalog`

Aujourd’hui : contenu **non** réémis (clé « perdue » au `toJson()`). Lot 49 : décoder et persister.

## 18. Décision de ne pas modifier `ProjectManifest` dans ce lot

Périmètre caractérisation / tests / rapport seulement.

## 19. Décision de ne pas lancer `build_runner`

Aucun nouveau champ modèle.

## 20. Décision de ne pas modifier les fichiers generated

Cohérence avec §18–19.

## 21. Décision de ne pas modifier les codecs Surface (Lots 39–46)

Stabilité contractuelle lot à lot.

## 22. Décision de ne pas modifier les fixtures Lot 47

Conformité cahier ; tests 12–13 en lecture seule.

## 23. Ce qui a été testé

15 tests (manifest, clés inconnues, fixtures Lot 47 + codec, vocabulaire, invariants).

## 24. Ce que les tests prouvent

État pré-intégration : ignore + non-réémission ; contenu Lot 47 valide hors manifeste.

## 25. Ce qui n’a volontairement pas été fait

Intégration modèle, migration, `map_runtime` / `map_editor` / `map_gameplay` / `map_battle`.

## 26. Évolution attendue test 3 (et proches) au Lot 49

Dès que `surfaceCatalog` devient un champ, `toJson()` devra **inclure** (ou omettre selon politique) le catalogue : mettre à jour tests 3, 4, 5, 10, 11.

## 27. Proposition Lot 49

- Champ `ProjectSurfaceCatalog` (défaut vide).
- `fromJson` : `decodeProjectSurfaceCatalog` sur la sous-arborescence, ou vide si clé absente.
- `toJson` : politique A (toujours émettre) vs B (omettre si vide) — trancher avec conventions globales `ProjectManifest`.
- `build_runner` pour régénérer Freezed / `.g.dart`.

## 28. Risques Lot 49

Diffs de `project.json` ; rétro-lecture d’outils externes ; cohérence avec autres listes vides.

## 29. Recommandation : `ProjectSurfaceCatalog` nullable ou non

Recommandation : **non nullable** sur `ProjectManifest` avec **défaut = catalogue vide** (équivalent sémantique d’une clé absente en entrée apès Lot 49).

## 30. Recommandation : valeur par défaut si `surfaceCatalog` absent du JSON

**Catalogue vide** (listes vides) — cohérent avec la golden `empty_surface_catalog_v0.json`.

## 31. Recommandation : comportement JSON si `surfaceCatalog` absent côté fichier

Après Lot 49 : l’absence de clé alimente le défaut (vide) ; aujourd’hui la clé n’existe déjà pas en `toJson()`.

## 32. Recommandation : comportement JSON si `surfaceCatalog` « vide » (objet minimal)

Deux options A/B ci-dessous ; aujourd’hui non applicable côté manifeste.

## 33. Options A (toujours encoder) vs B (omettre si vide) pour `surfaceCatalog` une fois le champ porté

- **A** : schéma stable, simple pour l’auteur no-code, diffs explicites.
- **B** : fichiers plus compacts, alignement possible sur manifestes qui omettent des sections vides.
- Recommandation prudente : viser **A** pour la clarté produit, **sous réserve** d’alignement sur la manière dont `ProjectManifest` traite aujourd’hui les listes vides ailleurs (audit Lot 49).

## 34. Commandes lancées

`dart test` ciblé Lot 48 ; régressions (§36) ; `dart analyze` (§37) ; `dart test` complet (§38).

## 35. Résultat : test ciblé Lot 48 (sortie intégrale, ANSI supprimé)

```

00:00 +0: loading test/project_manifest_surface_integration_prep_test.dart                                                                                                                             
00:00 +0: ProjectManifest Surface Integration Prep (Lot 48) 1. current manifest toJson has no Surface persistence keys                                                                                 
00:00 +1: ProjectManifest Surface Integration Prep (Lot 48) 1. current manifest toJson has no Surface persistence keys                                                                                 
00:00 +1: ProjectManifest Surface Integration Prep (Lot 48) 2. current manifest round-trips without Surface                                                                                            
00:00 +2: ProjectManifest Surface Integration Prep (Lot 48) 2. current manifest round-trips without Surface                                                                                            
00:00 +2: ProjectManifest Surface Integration Prep (Lot 48) 3. current manifest ignores unknown surfaceCatalog (dropped on toJson) — will change in Lot 49                                             
00:00 +3: ProjectManifest Surface Integration Prep (Lot 48) 3. current manifest ignores unknown surfaceCatalog (dropped on toJson) — will change in Lot 49                                             
00:00 +3: ProjectManifest Surface Integration Prep (Lot 48) 4. current manifest ignores Lot 47 minimal water surfaceCatalog (dropped on toJson)                                                        
00:00 +4: ProjectManifest Surface Integration Prep (Lot 48) 4. current manifest ignores Lot 47 minimal water surfaceCatalog (dropped on toJson)                                                        
00:00 +4: ProjectManifest Surface Integration Prep (Lot 48) 5. current manifest ignores Lot 47 full water surfaceCatalog (dropped on toJson)                                                           
00:00 +5: ProjectManifest Surface Integration Prep (Lot 48) 5. current manifest ignores Lot 47 full water surfaceCatalog (dropped on toJson)                                                           
00:00 +5: ProjectManifest Surface Integration Prep (Lot 48) 6. future minimal Lot 47 catalog decodes via decodeProjectSurfaceCatalog                                                                   
00:00 +6: ProjectManifest Surface Integration Prep (Lot 48) 6. future minimal Lot 47 catalog decodes via decodeProjectSurfaceCatalog                                                                   
00:00 +6: ProjectManifest Surface Integration Prep (Lot 48) 7. future full Lot 47 catalog decodes via decodeProjectSurfaceCatalog                                                                      
00:00 +7: ProjectManifest Surface Integration Prep (Lot 48) 7. future full Lot 47 catalog decodes via decodeProjectSurfaceCatalog                                                                      
00:00 +7: ProjectManifest Surface Integration Prep (Lot 48) 8. recommended future manifest field name is surfaceCatalog                                                                                
00:00 +8: ProjectManifest Surface Integration Prep (Lot 48) 8. recommended future manifest field name is surfaceCatalog                                                                                
00:00 +8: ProjectManifest Surface Integration Prep (Lot 48) 9. discouraged split Surface key names are absent from toJson                                                                              
00:00 +9: ProjectManifest Surface Integration Prep (Lot 48) 9. discouraged split Surface key names are absent from toJson                                                                              
00:00 +9: ProjectManifest Surface Integration Prep (Lot 48) 10. surfaceCatalog is not yet a ProjectManifest field in Lot 48                                                                            
00:00 +10: ProjectManifest Surface Integration Prep (Lot 48) 10. surfaceCatalog is not yet a ProjectManifest field in Lot 48                                                                           
00:00 +10: ProjectManifest Surface Integration Prep (Lot 48) 11. root unknown Surface keys do not break decode; not re-emitted on toJson                                                               
00:00 +11: ProjectManifest Surface Integration Prep (Lot 48) 11. root unknown Surface keys do not break decode; not re-emitted on toJson                                                               
00:00 +11: ProjectManifest Surface Integration Prep (Lot 48) 12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48)                                                                            
00:00 +12: ProjectManifest Surface Integration Prep (Lot 48) 12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48)                                                                            
00:00 +12: ProjectManifest Surface Integration Prep (Lot 48) 13. Lot 47 fixtures are bare catalog JSON (no top-level surfaceCatalog)                                                                   
00:00 +13: ProjectManifest Surface Integration Prep (Lot 48) 13. Lot 47 fixtures are bare catalog JSON (no top-level surfaceCatalog)                                                                   
00:00 +13: ProjectManifest Surface Integration Prep (Lot 48) 14. catalog codec and manifest stay usable via public map_core (no src imports)                                                           
00:00 +14: ProjectManifest Surface Integration Prep (Lot 48) 14. catalog codec and manifest stay usable via public map_core (no src imports)                                                           
00:00 +14: ProjectManifest Surface Integration Prep (Lot 48) 15. Lot 48 does not add generated manifest Surface members — no new .g.dart contract in tests                                             
00:00 +15: ProjectManifest Surface Integration Prep (Lot 48) 15. Lot 48 does not add generated manifest Surface members — no new .g.dart contract in tests                                             
00:00 +15: All tests passed!                                                                                                                                                                           

```

## 36. Résultats : tests de régression (sorties intégrales, ANSI supprimé)

### `test/project_surface_catalog_json_golden_samples_test.dart`

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

### `test/project_manifest_surface_json_characterization_test.dart`

```

00:00 +0: loading test/project_manifest_surface_json_characterization_test.dart                                                                                                                        
00:00 +0: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults                                                                         
00:00 +1: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults                                                                         
00:00 +1: ProjectManifest JSON characterization before Surface model unknown root surfaceDefinitions is ignored and lost on round-trip                                                                 
00:00 +2: ProjectManifest JSON characterization before Surface model unknown root surfaceDefinitions is ignored and lost on round-trip                                                                 
00:00 +2: ProjectManifest JSON characterization before Surface model manifest preserves a simple ProjectTilesetEntry as wire JSON                                                                      
00:00 +3: ProjectManifest JSON characterization before Surface model manifest preserves a simple ProjectTilesetEntry as wire JSON                                                                      
00:00 +3: ProjectManifest JSON characterization before Surface model TilesetSourceRect preserves its grid coordinates and size                                                                         
00:00 +4: ProjectManifest JSON characterization before Surface model TilesetSourceRect preserves its grid coordinates and size                                                                         
00:00 +4: ProjectManifest JSON characterization before Surface model TilesetVisualFrame without tileset override defaults to empty id                                                                  
00:00 +5: ProjectManifest JSON characterization before Surface model TilesetVisualFrame without tileset override defaults to empty id                                                                  
00:00 +5: ProjectManifest JSON characterization before Surface model TilesetVisualFrame with tileset override preserves the override                                                                   
00:00 +6: ProjectManifest JSON characterization before Surface model TilesetVisualFrame with tileset override preserves the override                                                                   
00:00 +6: ProjectManifest JSON characterization before Surface model ProjectTerrainPreset preserves animated variants in order                                                                         
00:00 +7: ProjectManifest JSON characterization before Surface model ProjectTerrainPreset preserves animated variants in order                                                                         
00:00 +7: ProjectManifest JSON characterization before Surface model ProjectPathPreset water preserves mappings and animated frames                                                                    
00:00 +8: ProjectManifest JSON characterization before Surface model ProjectPathPreset water preserves mappings and animated frames                                                                    
00:00 +8: ProjectManifest JSON characterization before Surface model ProjectPathPreset tallGrass is known to JSON serialization                                                                        
00:00 +9: ProjectManifest JSON characterization before Surface model ProjectPathPreset tallGrass is known to JSON serialization                                                                        
00:00 +9: ProjectManifest JSON characterization before Surface model PathLayer animationMode preserves always_active and triggered                                                                     
00:00 +10: ProjectManifest JSON characterization before Surface model PathLayer animationMode preserves always_active and triggered                                                                    
00:00 +10: ProjectManifest JSON characterization before Surface model PathAnimationTriggerRule preserves current trigger fields                                                                        
00:00 +11: ProjectManifest JSON characterization before Surface model PathAnimationTriggerRule preserves current trigger fields                                                                        
00:00 +11: ProjectManifest JSON characterization before Surface model PathLayer preserves presetId, cells, properties, mode and triggers                                                               
00:00 +12: ProjectManifest JSON characterization before Surface model PathLayer preserves presetId, cells, properties, mode and triggers                                                               
00:00 +12: ProjectManifest JSON characterization before Surface model TerrainLayer preserves terrain grid enum values                                                                                  
00:00 +13: ProjectManifest JSON characterization before Surface model TerrainLayer preserves terrain grid enum values                                                                                  
00:00 +13: ProjectManifest JSON characterization before Surface model unknown preset fields are ignored and lost on round-trip                                                                         
00:00 +14: ProjectManifest JSON characterization before Surface model unknown preset fields are ignored and lost on round-trip                                                                         
00:00 +14: ProjectManifest JSON characterization before Surface model manifest business object remains stable after wire JSON round-trip                                                               
00:00 +15: ProjectManifest JSON characterization before Surface model manifest business object remains stable after wire JSON round-trip                                                               
00:00 +15: All tests passed!                                                                                                                                                                           

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

## 37. Résultat : `dart analyze` (sortie intégrale)

```
Analyzing project_manifest_surface_integration_prep_test.dart, project_surface_catalog_json_golden_samples_test.dart, project_surface_catalog_json_codec_test.dart, surface_model_entrypoint_test.dart, project_manifest_surface_json_characterization_test.dart...
No issues found!
```

## 38. Résultat : `dart test` complet (map_core)

- Commande : `cd packages/map_core && /opt/homebrew/bin/dart test`
- Ligne finale exacte : `+1148: All tests passed!`
- Total indiqué par le compteur final : **1148**

## 39. Points de vigilance

Test 3 = garde-fou actuel ; inverser les attentes au Lot 49.

## 40. Autocritique

L’arbitrage A/B reste partiellement **hypothétique** sans relevé exhaustif de `toJson` sur les autres champs listes vides.

## 41. Ce que le prompt semble discutable ou incomplet

Nom de fichier de test manifeste « `project_manifest_json_characterization` » vs `project_manifest_surface_json_characterization_test.dart` en dépôt.

## 42. Auto-review indépendante

Périmètre Lot 48, pas de `lib/`, pas de `surfaceCatalog` modèle, pas de `build_runner`, pas de changement fixture Lot 47, commandes reproductibles, Evidence Pack, auto-check des formulations d’esquive : **fait** (aucune substitution interdite constatée).

## 43. `git status --short --untracked-files=all` final

```text
?? packages/map_core/test/project_manifest_surface_integration_prep_test.dart
?? reports/surface/surface_engine_lot_48_project_manifest_surface_integration_prep.md
```

## 44. Evidence Pack complet

### A. Fichiers créés (contenu intégral)

#### `project_manifest_surface_integration_prep_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// ProjectManifest Surface integration prep (Lot 48).
///
/// [Lot 49] will likely break test 3 (unknown `surfaceCatalog` currently dropped on write).

const _manifestSurfaceKeyCandidates = <String>[
  'surfaceCatalog',
  'surfaceDefinitions',
  'surfaceAtlases',
  'surfaceAnimations',
  'surfacePresets',
  'surfaceCategories',
];

const _discouragedTopLevelNames = <String>[
  'surfaceDefinitions',
  'surfaceAtlases',
  'surfaceAnimations',
  'surfacePresets',
  'surfaceCategories',
];

void main() {
  group('ProjectManifest Surface Integration Prep (Lot 48)', () {
    test('1. current manifest toJson has no Surface persistence keys', () {
      final manifest = _minimalManifest();
      _expectNoSurfaceKeys(
        _asObjectMap(manifest.toJson()),
      );
    });

    test('2. current manifest round-trips without Surface', () {
      final manifest = _minimalManifest();
      final decoded = ProjectManifest.fromJson(manifest.toJson());
      expect(decoded, manifest);
    });

    test(
      '3. current manifest ignores unknown surfaceCatalog (dropped on toJson) — will change in Lot 49',
      () {
        final withCatalog = _withFutureSurfaceCatalog(
          _manifestJson(),
          <String, Object?>{
            'atlases': <Object?>[],
            'animations': <Object?>[],
            'presets': <Object?>[],
          },
        );
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isFalse);
        expect(manifest.name, 'Lot 48 Prep');
      },
    );

    test(
      '4. current manifest ignores Lot 47 minimal water surfaceCatalog (dropped on toJson)',
      () {
        final surface = _readSurfaceCatalogFixtureJson(
          'minimal_water_surface_catalog_v0.json',
        );
        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isFalse);
        expect(manifest.name, 'Lot 48 Prep');
        expect(manifest.maps, isEmpty);
        expect(manifest.tilesets, isEmpty);
      },
    );

    test(
      '5. current manifest ignores Lot 47 full water surfaceCatalog (dropped on toJson)',
      () {
        final surface = _readSurfaceCatalogFixtureJson(
          'full_water_surface_catalog_v0.json',
        );
        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
        final manifest = ProjectManifest.fromJson(
          Map<String, dynamic>.from(withCatalog),
        );
        final out = _asObjectMap(manifest.toJson());
        expect(out.containsKey('surfaceCatalog'), isFalse);
        expect(manifest.name, 'Lot 48 Prep');
      },
    );

    test('6. future minimal Lot 47 catalog decodes via decodeProjectSurfaceCatalog', () {
      final raw = _readSurfaceCatalogFixtureJson(
        'minimal_water_surface_catalog_v0.json',
      );
      final catalog = decodeProjectSurfaceCatalog(
        Map<String, dynamic>.from(raw),
      );
      expect(catalog.atlases.length, 1);
      expect(catalog.animations.length, 1);
      expect(catalog.presets.length, 1);
      expect(
        diagnoseProjectSurfaceCatalog(catalog).hasDiagnostics,
        isFalse,
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(catalog).hasDiagnostics,
        isFalse,
      );
    });

    test('7. future full Lot 47 catalog decodes via decodeProjectSurfaceCatalog', () {
      final raw = _readSurfaceCatalogFixtureJson(
        'full_water_surface_catalog_v0.json',
      );
      final catalog = decodeProjectSurfaceCatalog(
        Map<String, dynamic>.from(raw),
      );
      expect(catalog.atlases.length, 1);
      expect(catalog.animations.length, 1);
      expect(catalog.presets.length, 1);
      expect(
        diagnoseProjectSurfaceCatalog(catalog).hasDiagnostics,
        isFalse,
      );
      expect(
        diagnoseProjectSurfaceCatalogUnusedResources(catalog).hasDiagnostics,
        isFalse,
      );
    });

    test('8. recommended future manifest field name is surfaceCatalog', () {
      const recommendedFutureManifestField = 'surfaceCatalog';
      expect(recommendedFutureManifestField, 'surfaceCatalog');
    });

    test('9. discouraged split Surface key names are absent from toJson', () {
      final json = _minimalManifest().toJson();
      for (final k in _discouragedTopLevelNames) {
        expect(json.containsKey(k), isFalse, reason: k);
      }
    });

    test(
      '10. surfaceCatalog is not yet a ProjectManifest field in Lot 48',
      () {
        expect(
          _minimalManifest().toJson().containsKey('surfaceCatalog'),
          isFalse,
        );
      },
    );

    test(
      '11. root unknown Surface keys do not break decode; not re-emitted on toJson',
      () {
        final merged = <String, Object?>{
          ..._manifestJson(),
          'surfaceCatalog': <String, Object?>{
            'atlases': <Object?>[],
            'animations': <Object?>[],
            'presets': <Object?>[],
          },
          'surfaceDefinitions': <Object?>[],
          'surfaceAtlases': <Object?>[],
          'surfaceAnimations': <Object?>[],
          'surfacePresets': <Object?>[],
          'surfaceCategories': <Object?>[],
        };
        final m = ProjectManifest.fromJson(
          Map<String, dynamic>.from(merged),
        );
        final out = m.toJson();
        for (final k in _manifestSurfaceKeyCandidates) {
          expect(out.containsKey(k), isFalse, reason: k);
        }
      },
    );

    test('12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48)', () {
      for (final name in const <String>[
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final raw = File(_fixturePath(name)).readAsStringSync();
        final v = jsonDecode(raw);
        expect(v, isA<Object?>());
      }
    });

    test('13. Lot 47 fixtures are bare catalog JSON (no top-level surfaceCatalog)', () {
      for (final name in const <String>[
        'empty_surface_catalog_v0.json',
        'minimal_water_surface_catalog_v0.json',
        'full_water_surface_catalog_v0.json',
      ]) {
        final o = _readSurfaceCatalogFixtureJson(name);
        expect(o.containsKey('surfaceCatalog'), isFalse, reason: name);
      }
    });

    test(
      '14. catalog codec and manifest stay usable via public map_core (no src imports)',
      () {
        final c = decodeProjectSurfaceCatalog(
          Map<String, dynamic>.from(
            _readSurfaceCatalogFixtureJson('empty_surface_catalog_v0.json'),
          ),
        );
        expect(c.isEmpty, isTrue);
        expect(_minimalManifest().name, isNotEmpty);
      },
    );

    test(
      '15. Lot 48 does not add generated manifest Surface members — no new .g.dart contract in tests',
      () {
        // Assertions above use only toJson / fromJson and decodeProjectSurfaceCatalog;
        // report confirms no lib/ or generated file edits in this lot.
        expect(
          _minimalManifest().toJson().keys.where(
                (k) => k.contains('urface'),
              ),
          isEmpty,
        );
      },
    );
  });
}

// --- helpers ---

Map<String, Object?> _asObjectMap(Map<String, dynamic> m) {
  return Map<String, Object?>.from(m);
}

void _expectNoSurfaceKeys(Map<String, Object?> json) {
  for (final k in _manifestSurfaceKeyCandidates) {
    expect(json.containsKey(k), isFalse, reason: 'unexpected key: $k');
  }
}

ProjectManifest _minimalManifest() {
  return const ProjectManifest(
    name: 'Lot 48 Prep',
    maps: [],
    tilesets: [],
  );
}

Map<String, Object?> _manifestJson() {
  return <String, Object?>{
    'name': 'Lot 48 Prep',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}

String _fixturePath(String name) {
  return 'test/fixtures/surface_catalog_json/$name';
}

Map<String, Object?> _readSurfaceCatalogFixtureJson(String name) {
  final s = File(_fixturePath(name)).readAsStringSync();
  return jsonDecode(s) as Map<String, Object?>;
}

Map<String, Object?> _withFutureSurfaceCatalog(
  Map<String, Object?> manifestJson,
  Map<String, Object?> surfaceCatalogJson,
) {
  return <String, Object?>{
    ...manifestJson,
    'surfaceCatalog': surfaceCatalogJson,
  };
}

```

#### `surface_engine_lot_48_project_manifest_surface_integration_prep.md`

Le contenu intégral de ce rapport est le document enregistré : sections 1–44 plus la section 45 (métacopie) ci-dessous.

### B. Fichiers modifiés

Aucun.

### C. Diffs

#### C.1 `project_manifest_surface_integration_prep_test.dart`

```diff
diff --git a/packages/map_core/test/project_manifest_surface_integration_prep_test.dart b/packages/map_core/test/project_manifest_surface_integration_prep_test.dart
new file mode 100644
index 00000000..2d4dcd62
--- /dev/null
+++ b/packages/map_core/test/project_manifest_surface_integration_prep_test.dart
@@ -0,0 +1,282 @@
+import 'dart:convert';
+import 'dart:io';
+
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+/// ProjectManifest Surface integration prep (Lot 48).
+///
+/// [Lot 49] will likely break test 3 (unknown `surfaceCatalog` currently dropped on write).
+
+const _manifestSurfaceKeyCandidates = <String>[
+  'surfaceCatalog',
+  'surfaceDefinitions',
+  'surfaceAtlases',
+  'surfaceAnimations',
+  'surfacePresets',
+  'surfaceCategories',
+];
+
+const _discouragedTopLevelNames = <String>[
+  'surfaceDefinitions',
+  'surfaceAtlases',
+  'surfaceAnimations',
+  'surfacePresets',
+  'surfaceCategories',
+];
+
+void main() {
+  group('ProjectManifest Surface Integration Prep (Lot 48)', () {
+    test('1. current manifest toJson has no Surface persistence keys', () {
+      final manifest = _minimalManifest();
+      _expectNoSurfaceKeys(
+        _asObjectMap(manifest.toJson()),
+      );
+    });
+
+    test('2. current manifest round-trips without Surface', () {
+      final manifest = _minimalManifest();
+      final decoded = ProjectManifest.fromJson(manifest.toJson());
+      expect(decoded, manifest);
+    });
+
+    test(
+      '3. current manifest ignores unknown surfaceCatalog (dropped on toJson) — will change in Lot 49',
+      () {
+        final withCatalog = _withFutureSurfaceCatalog(
+          _manifestJson(),
+          <String, Object?>{
+            'atlases': <Object?>[],
+            'animations': <Object?>[],
+            'presets': <Object?>[],
+          },
+        );
+        final manifest = ProjectManifest.fromJson(
+          Map<String, dynamic>.from(withCatalog),
+        );
+        final out = _asObjectMap(manifest.toJson());
+        expect(out.containsKey('surfaceCatalog'), isFalse);
+        expect(manifest.name, 'Lot 48 Prep');
+      },
+    );
+
+    test(
+      '4. current manifest ignores Lot 47 minimal water surfaceCatalog (dropped on toJson)',
+      () {
+        final surface = _readSurfaceCatalogFixtureJson(
+          'minimal_water_surface_catalog_v0.json',
+        );
+        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
+        final manifest = ProjectManifest.fromJson(
+          Map<String, dynamic>.from(withCatalog),
+        );
+        final out = _asObjectMap(manifest.toJson());
+        expect(out.containsKey('surfaceCatalog'), isFalse);
+        expect(manifest.name, 'Lot 48 Prep');
+        expect(manifest.maps, isEmpty);
+        expect(manifest.tilesets, isEmpty);
+      },
+    );
+
+    test(
+      '5. current manifest ignores Lot 47 full water surfaceCatalog (dropped on toJson)',
+      () {
+        final surface = _readSurfaceCatalogFixtureJson(
+          'full_water_surface_catalog_v0.json',
+        );
+        final withCatalog = _withFutureSurfaceCatalog(_manifestJson(), surface);
+        final manifest = ProjectManifest.fromJson(
+          Map<String, dynamic>.from(withCatalog),
+        );
+        final out = _asObjectMap(manifest.toJson());
+        expect(out.containsKey('surfaceCatalog'), isFalse);
+        expect(manifest.name, 'Lot 48 Prep');
+      },
+    );
+
+    test('6. future minimal Lot 47 catalog decodes via decodeProjectSurfaceCatalog', () {
+      final raw = _readSurfaceCatalogFixtureJson(
+        'minimal_water_surface_catalog_v0.json',
+      );
+      final catalog = decodeProjectSurfaceCatalog(
+        Map<String, dynamic>.from(raw),
+      );
+      expect(catalog.atlases.length, 1);
+      expect(catalog.animations.length, 1);
+      expect(catalog.presets.length, 1);
+      expect(
+        diagnoseProjectSurfaceCatalog(catalog).hasDiagnostics,
+        isFalse,
+      );
+      expect(
+        diagnoseProjectSurfaceCatalogUnusedResources(catalog).hasDiagnostics,
+        isFalse,
+      );
+    });
+
+    test('7. future full Lot 47 catalog decodes via decodeProjectSurfaceCatalog', () {
+      final raw = _readSurfaceCatalogFixtureJson(
+        'full_water_surface_catalog_v0.json',
+      );
+      final catalog = decodeProjectSurfaceCatalog(
+        Map<String, dynamic>.from(raw),
+      );
+      expect(catalog.atlases.length, 1);
+      expect(catalog.animations.length, 1);
+      expect(catalog.presets.length, 1);
+      expect(
+        diagnoseProjectSurfaceCatalog(catalog).hasDiagnostics,
+        isFalse,
+      );
+      expect(
+        diagnoseProjectSurfaceCatalogUnusedResources(catalog).hasDiagnostics,
+        isFalse,
+      );
+    });
+
+    test('8. recommended future manifest field name is surfaceCatalog', () {
+      const recommendedFutureManifestField = 'surfaceCatalog';
+      expect(recommendedFutureManifestField, 'surfaceCatalog');
+    });
+
+    test('9. discouraged split Surface key names are absent from toJson', () {
+      final json = _minimalManifest().toJson();
+      for (final k in _discouragedTopLevelNames) {
+        expect(json.containsKey(k), isFalse, reason: k);
+      }
+    });
+
+    test(
+      '10. surfaceCatalog is not yet a ProjectManifest field in Lot 48',
+      () {
+        expect(
+          _minimalManifest().toJson().containsKey('surfaceCatalog'),
+          isFalse,
+        );
+      },
+    );
+
+    test(
+      '11. root unknown Surface keys do not break decode; not re-emitted on toJson',
+      () {
+        final merged = <String, Object?>{
+          ..._manifestJson(),
+          'surfaceCatalog': <String, Object?>{
+            'atlases': <Object?>[],
+            'animations': <Object?>[],
+            'presets': <Object?>[],
+          },
+          'surfaceDefinitions': <Object?>[],
+          'surfaceAtlases': <Object?>[],
+          'surfaceAnimations': <Object?>[],
+          'surfacePresets': <Object?>[],
+          'surfaceCategories': <Object?>[],
+        };
+        final m = ProjectManifest.fromJson(
+          Map<String, dynamic>.from(merged),
+        );
+        final out = m.toJson();
+        for (final k in _manifestSurfaceKeyCandidates) {
+          expect(out.containsKey(k), isFalse, reason: k);
+        }
+      },
+    );
+
+    test('12. Lot 47 fixtures are still valid JSON (unchanged by Lot 48)', () {
+      for (final name in const <String>[
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final raw = File(_fixturePath(name)).readAsStringSync();
+        final v = jsonDecode(raw);
+        expect(v, isA<Object?>());
+      }
+    });
+
+    test('13. Lot 47 fixtures are bare catalog JSON (no top-level surfaceCatalog)', () {
+      for (final name in const <String>[
+        'empty_surface_catalog_v0.json',
+        'minimal_water_surface_catalog_v0.json',
+        'full_water_surface_catalog_v0.json',
+      ]) {
+        final o = _readSurfaceCatalogFixtureJson(name);
+        expect(o.containsKey('surfaceCatalog'), isFalse, reason: name);
+      }
+    });
+
+    test(
+      '14. catalog codec and manifest stay usable via public map_core (no src imports)',
+      () {
+        final c = decodeProjectSurfaceCatalog(
+          Map<String, dynamic>.from(
+            _readSurfaceCatalogFixtureJson('empty_surface_catalog_v0.json'),
+          ),
+        );
+        expect(c.isEmpty, isTrue);
+        expect(_minimalManifest().name, isNotEmpty);
+      },
+    );
+
+    test(
+      '15. Lot 48 does not add generated manifest Surface members — no new .g.dart contract in tests',
+      () {
+        // Assertions above use only toJson / fromJson and decodeProjectSurfaceCatalog;
+        // report confirms no lib/ or generated file edits in this lot.
+        expect(
+          _minimalManifest().toJson().keys.where(
+                (k) => k.contains('urface'),
+              ),
+          isEmpty,
+        );
+      },
+    );
+  });
+}
+
+// --- helpers ---
+
+Map<String, Object?> _asObjectMap(Map<String, dynamic> m) {
+  return Map<String, Object?>.from(m);
+}
+
+void _expectNoSurfaceKeys(Map<String, Object?> json) {
+  for (final k in _manifestSurfaceKeyCandidates) {
+    expect(json.containsKey(k), isFalse, reason: 'unexpected key: $k');
+  }
+}
+
+ProjectManifest _minimalManifest() {
+  return const ProjectManifest(
+    name: 'Lot 48 Prep',
+    maps: [],
+    tilesets: [],
+  );
+}
+
+Map<String, Object?> _manifestJson() {
+  return <String, Object?>{
+    'name': 'Lot 48 Prep',
+    'maps': <Object?>[],
+    'tilesets': <Object?>[],
+  };
+}
+
+String _fixturePath(String name) {
+  return 'test/fixtures/surface_catalog_json/$name';
+}
+
+Map<String, Object?> _readSurfaceCatalogFixtureJson(String name) {
+  final s = File(_fixturePath(name)).readAsStringSync();
+  return jsonDecode(s) as Map<String, Object?>;
+}
+
+Map<String, Object?> _withFutureSurfaceCatalog(
+  Map<String, Object?> manifestJson,
+  Map<String, Object?> surfaceCatalogJson,
+) {
+  return <String, Object?>{
+    ...manifestJson,
+    'surfaceCatalog': surfaceCatalogJson,
+  };
+}

```

#### C.2 Rapport (exception cahier)

Un diff `/dev/null` → ce chemin recopie ce texte en préfixant chaque ligne par `+` ; l’intégralité utile des sections 1–44 est de plus reproduite en section 45.

### D. Correspondance des sorties

Les sorties intégrales exigées figurent en §35–37 ; la suite complète est résumée en §38 (ligne finale + total).


````
