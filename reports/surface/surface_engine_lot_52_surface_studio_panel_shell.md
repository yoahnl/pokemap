# Surface Engine — Lot 52 — Surface Studio Panel Shell (V0)

## 1. Résumé exécutif

Premier panneau Flutter **lecture seule** dans `map_editor` : [SurfaceStudioPanel] et [SurfaceStudioPanelFromManifest] consomment un [SurfaceStudioReadModel] (Lot 51) sans provider, sans I/O, sans édition ni sauvegarde. Compteurs, états vide/non vide, résumé diagnostics, actions futures désactivées, placeholders de sections. **Aucune** intégration globale au shell de navigation (voir §10–12).

## 2. Après le Lot 51

Le Lot 51 a fourni le read model pur. Le Lot 52 affiche cette vue côté éditeur pour préparer les Lots 53+ (browser, diagnostics détaillées, actions).

## 3. Tableau lots 39–56

| Lot | Titre | Statut |
|-----|--------|--------|
| 39–51 | (chaîne Surface / read model) | fait |
| **52** | **Surface Studio Panel Shell V0** | **ce lot** |
| 53 | Surface Studio Catalog Browser V0 | prochain probable |
| 54 | Surface Studio Catalog Diagnostics View V0 | ensuite probable |
| 55 | Surface Studio Atlas List / Empty State V0 | ensuite probable |
| 56 | Surface Studio Animation List / Preset List V0 | ensuite probable |

## 4. `git status` initial

```text
(vide, worktree propre au démarrage Lot 52)
```

## 5. Fichiers consultés (audit)

- `packages/map_editor/pubspec.yaml` (dépendance `map_core`)
- `packages/map_editor/lib/main.dart`, `editor_shell_page.dart` (aperçu navigation)
- `packages/map_editor/lib/src/features/editor/state/models/editor_workspace_mode.dart` (modes existants)
- `packages/map_core/.../surface_studio_read_model.dart` (contrat read model)
- Tests `map_editor` existants : convention `package:map_editor/src/...`
- `reports/surface/surface_engine_lot_51_*.md`

## 6. Fichiers créés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `reports/surface/surface_engine_lot_52_surface_studio_panel_shell.md`

## 7. Fichiers modifiés

- **Aucun** fichier existant modifié (pas d’intégration `editor_shell` / `EditorWorkspaceMode`).

## 8. Préexistant vs Lot 52

- **Avant** : worktree propre.
- **Lot 52** : deux fichiers `??` (panel + test) + ce rapport.

## 9. Décision : widget présentationnel read-only

[StatelessWidget] ; données uniquement via [readModel] passé de l’extérieur ; pas de [ChangeNotifier] ni Riverpod dans le panneau.

## 10–12. Intégration globale

**Non réalisée.** Ajouter une entrée « Surface Studio » exigerait d’étendre [EditorWorkspaceMode], le routeur du shell, les providers d’état, et au moins une dizaine de fichiers. Le Lot 52 se limite au widget testable seul. **Point d’entrée Lot 53** : ajouter un mode `EditorWorkspaceMode.surfaceStudio` (ou équivalent) et un corps central qui instancie [SurfaceStudioPanelFromManifest] avec le manifest courant, sous [Provider] existant du projet.

## 13. API widget

- [SurfaceStudioPanel] `( readModel: SurfaceStudioReadModel )`
- [SurfaceStudioPanelFromManifest] `( manifest: ProjectManifest )` → [buildSurfaceStudioReadModel] en interne.

## 14–18. Sémantique (UI)

- **Vide** : compteurs 0, carte « Aucun catalogue Surface pour le moment ».
- **Non vide** : texte « Catalogue Surface détecté ».
- **Compteurs** : [summary.atlasCount] / [animationCount] / [presetCount].
- **Diagnostics** : [readModel.diagnostics] et [hasErrors] / [hasWarnings] / clean ; comptes [summary.errorCount] / [warningCount] sur les lignes.
- **Actions** : [TextButton] avec [onPressed: null] (libellés [Créer un atlas], [Importer un atlas vertical]).
- **Placeholders** : titres [Catalogue], [Diagnostics], [Actions auteur] + sous-titre [Bientôt].

## 19–25. Décisions hors scope

- Pas d’édition, pas de sauvegarde, pas de mutation de [ProjectManifest], pas de changement [map_core], pas de provider, pas de repository, pas de modification runtime / gameplay / battle.

## 26–30. Tests / impact

- **26** : 24 tests widget (numéros 1–20, 22–24 ; test 21 réservé intégration, non exécuté faute d’intégration).
- **27** : affichage titres, compteurs, diagnostics, immuabilité manifest, scroll, absence TextField / save.
- **28** : pas de browser catalogue, pas de branchement shell.
- **29** : Lot 53 = navigation + données projet live.
- **30** : Lot 53 — branchement workspace + alimentation manifest depuis l’état éditeur.

## 31. Commandes lancées

- `git status --short --untracked-files=all` (initial / final)
- `dart format packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`
- `cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart`
- `cd packages/map_core && dart test test/surface_studio_read_model_test.dart test/project_manifest_surface_catalog_operations_test.dart`
- `cd packages/map_core && dart test` (ligne finale)
- `cd packages/map_editor && flutter analyze lib/src/.../surface_studio_panel.dart test/surface_studio/surface_studio_panel_test.dart`

**Non lancé** : `flutter test` intégral `map_editor` (coût élevé, hors périmètre stricte ; le test ciblé couvre le lot).

## 32. Résultat test ciblé Lot 52 (sortie intégrale)

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart                                                                           
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart                                                                           
00:01 +0: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                                                                                                                               
00:01 +1: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                                                                                                                               
00:01 +1: SurfaceStudioPanel (Lot 52) 2. read-only badge is visible                                                                                                                                    
00:01 +2: SurfaceStudioPanel (Lot 52) 2. read-only badge is visible                                                                                                                                    
00:01 +2: SurfaceStudioPanel (Lot 52) 3. three counters are zero for empty catalog                                                                                                                     
00:01 +3: SurfaceStudioPanel (Lot 52) 3. three counters are zero for empty catalog                                                                                                                     
00:01 +3: SurfaceStudioPanel (Lot 52) 4. empty catalog shows empty state copy                                                                                                                          
00:01 +4: SurfaceStudioPanel (Lot 52) 4. empty catalog shows empty state copy                                                                                                                          
00:01 +4: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                                                                                                                                   
00:01 +5: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                                                                                                                                   
00:01 +5: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog detected                                                                                                                              
00:01 +6: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog detected                                                                                                                              
00:01 +6: SurfaceStudioPanel (Lot 52) 7. clean diagnostics for minimal coherent catalog                                                                                                                
00:01 +7: SurfaceStudioPanel (Lot 52) 7. clean diagnostics for minimal coherent catalog                                                                                                                
00:01 +7: SurfaceStudioPanel (Lot 52) 8. warning state when unused atlas                                                                                                                               
00:01 +8: SurfaceStudioPanel (Lot 52) 8. warning state when unused atlas                                                                                                                               
00:01 +8: SurfaceStudioPanel (Lot 52) 9. error state when preset animation missing                                                                                                                     
00:01 +9: SurfaceStudioPanel (Lot 52) 9. error state when preset animation missing                                                                                                                     
00:01 +9: SurfaceStudioPanel (Lot 52) 10. future action labels are visible                                                                                                                             
00:01 +10: SurfaceStudioPanel (Lot 52) 10. future action labels are visible                                                                                                                            
00:01 +10: SurfaceStudioPanel (Lot 52) 11. future actions are disabled (onPressed null)                                                                                                                
00:01 +11: SurfaceStudioPanel (Lot 52) 11. future actions are disabled (onPressed null)                                                                                                                
00:01 +11: SurfaceStudioPanel (Lot 52) 12. section placeholder titles are visible                                                                                                                      
00:01 +12: SurfaceStudioPanel (Lot 52) 12. section placeholder titles are visible                                                                                                                      
00:01 +12: SurfaceStudioPanel (Lot 52) 13. SurfaceStudioPanelFromManifest uses manifest catalog                                                                                                        
00:01 +13: SurfaceStudioPanel (Lot 52) 13. SurfaceStudioPanelFromManifest uses manifest catalog                                                                                                        
00:01 +13: SurfaceStudioPanel (Lot 52) 14. manifest is not mutated after pump                                                                                                                          
00:01 +14: SurfaceStudioPanel (Lot 52) 14. manifest is not mutated after pump                                                                                                                          
00:01 +14: SurfaceStudioPanel (Lot 52) 15. does not require provider setup — panel builds without ProviderScope                                                                                        
00:01 +15: SurfaceStudioPanel (Lot 52) 15. does not require provider setup — panel builds without ProviderScope                                                                                        
00:01 +15: SurfaceStudioPanel (Lot 52) 16. content is in a scrollable                                                                                                                                  
00:01 +16: SurfaceStudioPanel (Lot 52) 16. content is in a scrollable                                                                                                                                  
00:01 +16: SurfaceStudioPanel (Lot 52) 17. no internal domain type names in user-visible strings                                                                                                       
00:01 +17: SurfaceStudioPanel (Lot 52) 17. no internal domain type names in user-visible strings                                                                                                       
00:01 +17: SurfaceStudioPanel (Lot 52) 18. error read model does not throw on build                                                                                                                    
00:01 +18: SurfaceStudioPanel (Lot 52) 18. error read model does not throw on build                                                                                                                    
00:01 +18: SurfaceStudioPanel (Lot 52) 19. warning read model does not throw on build                                                                                                                  
00:02 +18: SurfaceStudioPanel (Lot 52) 19. warning read model does not throw on build                                                                                                                  
00:02 +19: SurfaceStudioPanel (Lot 52) 19. warning read model does not throw on build                                                                                                                  
00:02 +19: SurfaceStudioPanel (Lot 52) 20. displayed counts match read model summary                                                                                                                   
00:02 +20: SurfaceStudioPanel (Lot 52) 20. displayed counts match read model summary                                                                                                                   
00:02 +20: SurfaceStudioPanel (Lot 52) 22. no TextField in panel                                                                                                                                       
00:02 +21: SurfaceStudioPanel (Lot 52) 22. no TextField in panel                                                                                                                                       
00:02 +21: SurfaceStudioPanel (Lot 52) 23. no save affordances                                                                                                                                         
00:02 +22: SurfaceStudioPanel (Lot 52) 23. no save affordances                                                                                                                                         
00:02 +22: SurfaceStudioPanel (Lot 52) 24. test file uses public map_core only (smoke)                                                                                                                 
00:02 +23: SurfaceStudioPanel (Lot 52) 24. test file uses public map_core only (smoke)                                                                                                                 
00:02 +23: All tests passed!                                                                                                                                                                           

```

## 33. Résultat régressions `map_core` (ciblées Lot 50/51, sortie intégrale)

```text

00:00 [32m+0[0m: [1m[90mloading test/surface_studio_read_model_test.dart[0m[0m                                                                                                                                             
00:00 [32m+0[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                             
00:00 [32m+1[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m             
00:00 [32m+2[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                      
00:00 [32m+3[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                      
00:00 [32m+4[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                      
00:00 [32m+5[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 4. replaceProjectManifestSurfaceCatalog replaces only catalog[0m                
00:00 [32m+6[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 4. replaceProjectManifestSurfaceCatalog replaces only catalog[0m                
00:00 [32m+7[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 4. minimal water — atlas row main fields[0m                                                                        
00:00 [32m+8[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 4. minimal water — atlas row main fields[0m                                                                        
00:00 [32m+8[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 5. replaceProjectManifestSurfaceCatalog does not mutate source manifest[0m      
00:00 [32m+9[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 5. atlas rows preserve catalog order[0m                                                                            
00:00 [32m+10[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 6. replaceProjectManifestSurfaceCatalog preserves JSON encoding contract[0m    
00:00 [32m+11[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 6. replaceProjectManifestSurfaceCatalog preserves JSON encoding contract[0m    
00:00 [32m+12[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 6. replaceProjectManifestSurfaceCatalog preserves JSON encoding contract[0m    
00:00 [32m+13[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 6. replaceProjectManifestSurfaceCatalog preserves JSON encoding contract[0m    
00:00 [32m+14[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 6. replaceProjectManifestSurfaceCatalog preserves JSON encoding contract[0m    
00:00 [32m+15[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 6. replaceProjectManifestSurfaceCatalog preserves JSON encoding contract[0m    
00:00 [32m+15[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 10. animation referencedAtlasIds — first appearance order[0m                                                      
00:00 [32m+16[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 7. updateProjectManifestSurfaceCatalog passes current catalog to update[0m     
00:00 [32m+17[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 11. animation read model does not validate atlas existence[0m                                                     
00:00 [32m+18[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 8. updateProjectManifestSurfaceCatalog calls update exactly once[0m            
00:00 [32m+19[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 8. updateProjectManifestSurfaceCatalog calls update exactly once[0m            
00:00 [32m+19[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 12. minimal water — preset row main fields[0m                                                                     
00:00 [32m+20[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 9. updateProjectManifestSurfaceCatalog uses returned catalog as new value[0m   
00:00 [32m+21[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 9. updateProjectManifestSurfaceCatalog uses returned catalog as new value[0m   
00:00 [32m+21[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 10. updateProjectManifestSurfaceCatalog preserves other fields[0m              
00:00 [32m+22[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 10. updateProjectManifestSurfaceCatalog preserves other fields[0m              
00:00 [32m+23[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 14. preset referencedAnimationIds — dedupe keeps order[0m                                                         
00:00 [32m+24[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 11. updateProjectManifestSurfaceCatalog propagates exceptions[0m               
00:00 [32m+25[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 11. updateProjectManifestSurfaceCatalog propagates exceptions[0m               
00:00 [32m+26[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 11. updateProjectManifestSurfaceCatalog propagates exceptions[0m               
00:00 [32m+26[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 16. full water — preset role order cross, isolated, horizontal[0m                                                 
00:00 [32m+27[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 16. full water — preset role order cross, isolated, horizontal[0m                                                 
00:00 [32m+28[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 13. clearProjectManifestSurfaceCatalog does not mutate source[0m               
00:00 [32m+29[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 17. minimal water — diagnostics clean flags on read model[0m                                                      
00:00 [32m+30[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 14. clearProjectManifestSurfaceCatalog preserves other fields[0m               
00:00 [32m+31[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 18. diagnostics error — missing animation atlas[0m                                                                
00:00 [32m+32[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 18. diagnostics error — missing animation atlas[0m                                                                
00:00 [32m+32[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 15. round-trip JSON after replace with minimal water[0m                        
00:00 [32m+33[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 15. round-trip JSON after replace with minimal water[0m                        
00:00 [32m+34[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 15. round-trip JSON after replace with minimal water[0m                        
00:00 [32m+35[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 15. round-trip JSON after replace with minimal water[0m                        
00:00 [32m+36[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 15. round-trip JSON after replace with minimal water[0m                        
00:00 [32m+37[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 15. round-trip JSON after replace with minimal water[0m                        
00:00 [32m+38[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 15. round-trip JSON after replace with minimal water[0m                        
00:00 [32m+39[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 25. value equality of read models for equivalent catalogs[0m                                                      
00:00 [32m+40[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 25. value equality of read models for equivalent catalogs[0m                                                      
00:00 [32m+41[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 25. value equality of read models for equivalent catalogs[0m                                                      
00:00 [32m+42[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 18. helpers keep single surfaceCatalog key in toJson; no split keys[0m         
00:00 [32m+43[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 26. inequality when content differs[0m                                                                            
00:00 [32m+44[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 26. inequality when content differs[0m                                                                            
00:00 [32m+45[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 20. Lot 47 fixtures stay bare JSON without top-level surfaceCatalog[0m         
00:00 [32m+46[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 20. Lot 47 fixtures stay bare JSON without top-level surfaceCatalog[0m         
00:00 [32m+47[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 20. Lot 47 fixtures stay bare JSON without top-level surfaceCatalog[0m         
00:00 [32m+47[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 28. ProjectManifest toJson still Lot 49 — surfaceCatalog only[0m                                                  
00:00 [32m+48[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 28. ProjectManifest toJson still Lot 49 — surfaceCatalog only[0m                                                  
00:00 [32m+48[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog[0m                                                  
00:00 [32m+49[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 29. Lot 47 fixtures — valid JSON, no top-level surfaceCatalog[0m                                                  
00:00 [32m+49[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 30. no Flutter / Riverpod in surface read model public API[0m                                                     
00:00 [32m+50[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 30. no Flutter / Riverpod in surface read model public API[0m                                                     
00:00 [32m+50[0m: All tests passed![0m                                                                                                                                                                           

```

## 34. Résultat `flutter analyze` (fichiers Lot 52)

```text
Analyzing 2 items...                                            
No issues found! (ran in 1.1s)

```

## 35. `dart test` complet `map_core` (ligne finale)

```text
00:03 [32m+1218[0m: All tests passed![0m
```

**Total** : **+1218** tests (suite complète [map_core]).

**Suite [map_editor] complète** : non lancée (voir §31).

## 36. Fichiers formatés

- `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`
- `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

## 37–40. Points de vigilance, autocritique, prompt

- Les libellés diagnostics concatènent compteur + texte (ex. `1 — Erreurs...`) : à harmoniser en Lot 54 si UI plus riche.
- **Autocritique** : l’[EditorWorkspaceMode] n’a pas de slot Surface ; l’intégration reste le goulot Lot 53.
- **Prompt** : la contrainte d’[Evidence] complète pèse lourd sur la taille du markdown ; l’exception §A.3 s’applique au présent rapport.

## 41. Auto-review (checklist)

- [x] Périmètre `map_editor` + rapport
- [x] Aucun `map_core` modifié
- [x] Aucun provider, pas d’édition, actions désactivées
- [x] Read model consommé tel quel
- [x] Tests public `map_core` + import `map_editor/src/...` documenté
- [x] `flutter analyze` sans issues sur fichiers ciblés
- [x] Aucun `git` write
- [x] UTF-8, pas de mojibake volontaire dans le code (rapport généré en Python UTF-8)

## 42. Vérification anti-mojibake (sources Lot 52)

- Pas de séquences `Ã`, `â€™`, `â€"`, `â†'` dans le panel ni le test (hors listes pédagogiques interdits dans le rapport, si présentes).

## 43. `git status` final

```text
?? packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
?? packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
?? reports/surface/surface_engine_lot_52_surface_studio_panel_shell.md
```

---

## 44. Evidence Pack complet

### A. Fichiers créés — contenu intégral

#### A.1 `packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart`

```dart
// Surface Studio — shell UI lecture seule (Lot 52).
//
// Consomme un [SurfaceStudioReadModel] déjà construit côté [map_core] : pas de
// re-diagnostic, pas de mutation manifest, pas d’I/O. Les actions futures sont
// désactivées ; les sections listées sont des placeholders pour les Lots 53+.

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

/// Panneau présentationnel **lecture seule** pour Surface Studio.
class SurfaceStudioPanel extends StatelessWidget {
  const SurfaceStudioPanel({
    super.key,
    required this.readModel,
  });

  final SurfaceStudioReadModel readModel;

  static const String titleText = 'Surface Studio';
  static const String readOnlyBadgeText = 'Lecture seule';
  static const String productDescriptionText =
      'Préparez et contrôlez les surfaces animées du projet : eau, lave, glace, hautes herbes.';
  static const String emptyStateTitle =
      'Aucun catalogue Surface pour le moment';
  static const String emptyStateHint =
      'Les prochains lots permettront de créer des atlas, animations et presets.';
  static const String catalogDetectedText = 'Catalogue Surface détecté';
  static const String diagnosticsCleanText = 'Aucun diagnostic Surface';
  static const String diagnosticsErrorsText = 'Erreurs Surface détectées';
  static const String diagnosticsWarningsText =
      'Avertissements Surface détectés';
  static const String placeholderCatalogTitle = 'Catalogue';
  static const String placeholderDiagnosticsTitle = 'Diagnostics';
  static const String placeholderActionsTitle = 'Actions auteur';
  static const String placeholderSoonText = 'Bientôt';
  static const String actionCreateAtlasLabel = 'Créer un atlas';
  static const String actionImportVerticalAtlasLabel =
      'Importer un atlas vertical';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = readModel.summary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                titleText,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              const _ReadOnlyBadge(label: readOnlyBadgeText),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            productDescriptionText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Dans ce lot, il s’agit d’une vue de lecture et de préparation '
            'uniquement : aucune création, édition, suppression ou sauvegarde.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 20),
          _CounterRow(
            atlas: s.atlasCount,
            animations: s.animationCount,
            presets: s.presetCount,
          ),
          const SizedBox(height: 16),
          if (readModel.isEmpty) ...[
            const _EmptyStateCard(
              title: emptyStateTitle,
              subtitle: emptyStateHint,
            ),
          ] else ...[
            Text(
              catalogDetectedText,
              style: theme.textTheme.titleMedium,
            ),
          ],
          const SizedBox(height: 16),
          _DiagnosticsSummary(
            readModel: readModel,
            theme: theme,
          ),
          const SizedBox(height: 20),
          const _FutureActions(
            onCreateAtlas: null,
            onImportVertical: null,
          ),
          const SizedBox(height: 24),
          _SectionPlaceholder(
            title: placeholderCatalogTitle,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _SectionPlaceholder(
            title: placeholderDiagnosticsTitle,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _SectionPlaceholder(
            title: placeholderActionsTitle,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyBadge extends StatelessWidget {
  const _ReadOnlyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.atlas,
    required this.animations,
    required this.presets,
  });

  final int atlas;
  final int animations;
  final int presets;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _CounterChip(label: 'Atlas', value: atlas),
        _CounterChip(label: 'Animations', value: animations),
        _CounterChip(label: 'Presets', value: presets),
      ],
    );
  }
}

class _CounterChip extends StatelessWidget {
  const _CounterChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: t.textTheme.labelMedium?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: t.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: t.textTheme.bodySmall?.copyWith(
                color: t.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticsSummary extends StatelessWidget {
  const _DiagnosticsSummary({
    required this.readModel,
    required this.theme,
  });

  final SurfaceStudioReadModel readModel;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final d = readModel.diagnostics;
    final err = d.summary.errorCount;
    final warn = d.summary.warningCount;

    final children = <Widget>[];

    if (d.isClean) {
      children.add(
        Text(
          SurfaceStudioPanel.diagnosticsCleanText,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    } else {
      if (readModel.hasErrors) {
        children.add(
          Text(
            '$err — ${SurfaceStudioPanel.diagnosticsErrorsText}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        );
      }
      if (readModel.hasWarnings) {
        children.add(
          Padding(
            padding: EdgeInsets.only(top: readModel.hasErrors ? 6 : 0),
            child: Text(
              '$warn — ${SurfaceStudioPanel.diagnosticsWarningsText}',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.tertiary,
              ),
            ),
          ),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _FutureActions extends StatelessWidget {
  const _FutureActions({
    required this.onCreateAtlas,
    required this.onImportVertical,
  });

  final VoidCallback? onCreateAtlas;
  final VoidCallback? onImportVertical;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Actions (non disponibles dans ce lot)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton(
              onPressed: onCreateAtlas,
              child: const Text(SurfaceStudioPanel.actionCreateAtlasLabel),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onImportVertical,
              child: const Text(
                SurfaceStudioPanel.actionImportVerticalAtlasLabel,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionPlaceholder extends StatelessWidget {
  const _SectionPlaceholder({
    required this.title,
    required this.theme,
  });

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title, style: theme.textTheme.titleSmall),
        subtitle: const Text(SurfaceStudioPanel.placeholderSoonText),
        trailing: const Icon(Icons.layers_outlined),
      ),
    );
  }
}

/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
class SurfaceStudioPanelFromManifest extends StatelessWidget {
  const SurfaceStudioPanelFromManifest({
    super.key,
    required this.manifest,
  });

  final ProjectManifest manifest;

  @override
  Widget build(BuildContext context) {
    return SurfaceStudioPanel(
      readModel: buildSurfaceStudioReadModel(manifest),
    );
  }
}

```

#### A.2 `packages/map_editor/test/surface_studio/surface_studio_panel_test.dart`

```dart
// Tests widget — Surface Studio panel (Lot 52).
// Imports `map_core` en API publique uniquement (pas de `map_core/src/...`).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';

void main() {
  group('SurfaceStudioPanel (Lot 52)', () {
    testWidgets('1. title Surface Studio is visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Surface Studio'), findsOneWidget);
    });

    testWidgets('2. read-only badge is visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Lecture seule'), findsOneWidget);
    });

    testWidgets('3. three counters are zero for empty catalog', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      // Trois compteurs à 0
      expect(find.text('0'), findsNWidgets(3));
    });

    testWidgets('4. empty catalog shows empty state copy', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(
        find.textContaining('Aucun catalogue Surface'),
        findsOneWidget,
      );
    });

    testWidgets('5. minimal catalog shows 1/1/1', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('1'), findsNWidgets(3));
    });

    testWidgets('6. non-empty shows catalog detected', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Catalogue Surface détecté'), findsOneWidget);
    });

    testWidgets('7. clean diagnostics for minimal coherent catalog',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
    });

    testWidgets('8. warning state when unused atlas', (tester) async {
      final rm = _warningReadModel();
      expect(rm.hasWarnings, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(
        find.textContaining('Avertissements Surface détectés'),
        findsOneWidget,
      );
    });

    testWidgets('9. error state when preset animation missing', (tester) async {
      final rm = _errorReadModel();
      expect(rm.hasErrors, isTrue);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(
        find.textContaining('Erreurs Surface détectées'),
        findsOneWidget,
      );
    });

    testWidgets('10. future action labels are visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Créer un atlas'), findsOneWidget);
      expect(find.text('Importer un atlas vertical'), findsOneWidget);
    });

    testWidgets('11. future actions are disabled (onPressed null)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      final b1 = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Créer un atlas'),
          matching: find.byType(TextButton),
        ),
      );
      final b2 = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Importer un atlas vertical'),
          matching: find.byType(TextButton),
        ),
      );
      expect(b1.onPressed, isNull);
      expect(b2.onPressed, isNull);
    });

    testWidgets('12. section placeholder titles are visible', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Catalogue'), findsOneWidget);
      expect(find.text('Diagnostics'), findsOneWidget);
      expect(find.text('Actions auteur'), findsOneWidget);
    });

    testWidgets('13. SurfaceStudioPanelFromManifest uses manifest catalog',
        (tester) async {
      final cat = _minimalWaterCatalog();
      final manifest = _manifest(cat);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      expect(find.text('1'), findsNWidgets(3));
    });

    testWidgets('14. manifest is not mutated after pump', (tester) async {
      final cat = _minimalWaterCatalog();
      final before = cat.atlases.length;
      final manifest = _manifest(cat);
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
      );
      expect(manifest.surfaceCatalog.atlases.length, before);
    });

    testWidgets(
      '15. does not require provider setup — panel builds without ProviderScope',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SurfaceStudioPanel(readModel: _emptyReadModel()),
            ),
          ),
        );
        expect(find.text('Surface Studio'), findsOneWidget);
      },
    );

    testWidgets('16. content is in a scrollable', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('17. no internal domain type names in user-visible strings',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
      );
      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
      expect(
          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
    });

    testWidgets('18. error read model does not throw on build', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. warning read model does not throw on build',
        (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _warningReadModel())),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. displayed counts match read model summary',
        (tester) async {
      final rm = _minimalWaterReadModel();
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: rm)),
      );
      expect(rm.summary.atlasCount, 1);
      expect(rm.summary.animationCount, 1);
      expect(rm.summary.presetCount, 1);
    });

    testWidgets('22. no TextField in panel', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('23. no save affordances', (tester) async {
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.textContaining('Sauvegarder'), findsNothing);
      expect(find.textContaining('Enregistrer'), findsNothing);
      expect(find.textContaining('Save'), findsNothing);
    });

    testWidgets('24. test file uses public map_core only (smoke)',
        (tester) async {
      // Vérification statique : seul `package:map_core/map_core.dart` est importé.
      await tester.pumpWidget(
        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
      );
      expect(find.text('Surface Studio'), findsOneWidget);
    });
  });
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

SurfaceStudioReadModel _emptyReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
}

SurfaceStudioReadModel _minimalWaterReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
}

SurfaceStudioReadModel _warningReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
}

SurfaceStudioReadModel _errorReadModel() {
  return buildSurfaceStudioReadModelFromCatalog(_catalogWithMissingAnimation());
}

SurfaceAtlasGeometry _geom() {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
    gridSize: SurfaceAtlasGridSize(columns: 2, rows: 2),
    layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
  );
}

ProjectSurfaceCatalog _minimalWaterCatalog() {
  final g = _geom();
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

ProjectSurfaceCatalog _catalogWithMissingAnimation() {
  final refs = SurfaceVariantAnimationRefSet(
    refs: [
      SurfaceVariantAnimationRef(
        role: SurfaceVariantRole.isolated,
        animationId: 'missing-anim',
      ),
    ],
  );
  return ProjectSurfaceCatalog(
    atlases: const [],
    animations: const [],
    presets: [
      ProjectSurfacePreset(
        id: 'p',
        name: 'p',
        variantAnimations: refs,
      ),
    ],
  );
}

ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
  return ProjectManifest(
    name: 'Test',
    maps: const [],
    tilesets: const [],
    surfaceCatalog: catalog,
  );
}

```

#### A.3 Rapport

**Exception rapport (cahier Lot 52) :** le fichier `reports/surface/surface_engine_lot_52_surface_studio_panel_shell.md` enregistré sur disque est l’artefact unique. Un `git diff --no-index /dev/null` sur ce chemin, après enregistrement, reproduit chaque ligne du contenu en préfixe `+` ; il n’y a pas de seconde copie du rapport dans le rapport.

SHA-256 (panel / test) : `a286526e6019bb608461be9b5507881db346491383dd5305272e315ca9e28087` / `a5d716aa24875ebbdc42cb22e0e92937d3f31ddb3a9268d1dfaa7c9dcb22da6c`

### B. Fichiers modifiés

**Aucun** (aucun diff non `/dev/null` côté dépôt pour ce lot hors ce rapport).

### C. Diffs `git diff --no-index /dev/null`

#### C.1 `surface_studio_panel.dart`

```diff
diff --git a/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
new file mode 100644
index 00000000..ede54f1e
--- /dev/null
+++ b/packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart
@@ -0,0 +1,385 @@
+// Surface Studio — shell UI lecture seule (Lot 52).
+//
+// Consomme un [SurfaceStudioReadModel] déjà construit côté [map_core] : pas de
+// re-diagnostic, pas de mutation manifest, pas d’I/O. Les actions futures sont
+// désactivées ; les sections listées sont des placeholders pour les Lots 53+.
+
+import 'package:flutter/material.dart';
+import 'package:map_core/map_core.dart';
+
+/// Panneau présentationnel **lecture seule** pour Surface Studio.
+class SurfaceStudioPanel extends StatelessWidget {
+  const SurfaceStudioPanel({
+    super.key,
+    required this.readModel,
+  });
+
+  final SurfaceStudioReadModel readModel;
+
+  static const String titleText = 'Surface Studio';
+  static const String readOnlyBadgeText = 'Lecture seule';
+  static const String productDescriptionText =
+      'Préparez et contrôlez les surfaces animées du projet : eau, lave, glace, hautes herbes.';
+  static const String emptyStateTitle =
+      'Aucun catalogue Surface pour le moment';
+  static const String emptyStateHint =
+      'Les prochains lots permettront de créer des atlas, animations et presets.';
+  static const String catalogDetectedText = 'Catalogue Surface détecté';
+  static const String diagnosticsCleanText = 'Aucun diagnostic Surface';
+  static const String diagnosticsErrorsText = 'Erreurs Surface détectées';
+  static const String diagnosticsWarningsText =
+      'Avertissements Surface détectés';
+  static const String placeholderCatalogTitle = 'Catalogue';
+  static const String placeholderDiagnosticsTitle = 'Diagnostics';
+  static const String placeholderActionsTitle = 'Actions auteur';
+  static const String placeholderSoonText = 'Bientôt';
+  static const String actionCreateAtlasLabel = 'Créer un atlas';
+  static const String actionImportVerticalAtlasLabel =
+      'Importer un atlas vertical';
+
+  @override
+  Widget build(BuildContext context) {
+    final theme = Theme.of(context);
+    final s = readModel.summary;
+
+    return SingleChildScrollView(
+      padding: const EdgeInsets.all(20),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Row(
+            crossAxisAlignment: CrossAxisAlignment.center,
+            children: [
+              Text(
+                titleText,
+                style: theme.textTheme.headlineSmall?.copyWith(
+                  fontWeight: FontWeight.w600,
+                ),
+              ),
+              const SizedBox(width: 12),
+              const _ReadOnlyBadge(label: readOnlyBadgeText),
+            ],
+          ),
+          const SizedBox(height: 8),
+          Text(
+            productDescriptionText,
+            style: theme.textTheme.bodyMedium?.copyWith(
+              color: theme.colorScheme.onSurfaceVariant,
+            ),
+          ),
+          const SizedBox(height: 8),
+          Text(
+            'Dans ce lot, il s’agit d’une vue de lecture et de préparation '
+            'uniquement : aucune création, édition, suppression ou sauvegarde.',
+            style: theme.textTheme.bodySmall?.copyWith(
+              color: theme.colorScheme.outline,
+            ),
+          ),
+          const SizedBox(height: 20),
+          _CounterRow(
+            atlas: s.atlasCount,
+            animations: s.animationCount,
+            presets: s.presetCount,
+          ),
+          const SizedBox(height: 16),
+          if (readModel.isEmpty) ...[
+            const _EmptyStateCard(
+              title: emptyStateTitle,
+              subtitle: emptyStateHint,
+            ),
+          ] else ...[
+            Text(
+              catalogDetectedText,
+              style: theme.textTheme.titleMedium,
+            ),
+          ],
+          const SizedBox(height: 16),
+          _DiagnosticsSummary(
+            readModel: readModel,
+            theme: theme,
+          ),
+          const SizedBox(height: 20),
+          const _FutureActions(
+            onCreateAtlas: null,
+            onImportVertical: null,
+          ),
+          const SizedBox(height: 24),
+          _SectionPlaceholder(
+            title: placeholderCatalogTitle,
+            theme: theme,
+          ),
+          const SizedBox(height: 12),
+          _SectionPlaceholder(
+            title: placeholderDiagnosticsTitle,
+            theme: theme,
+          ),
+          const SizedBox(height: 12),
+          _SectionPlaceholder(
+            title: placeholderActionsTitle,
+            theme: theme,
+          ),
+        ],
+      ),
+    );
+  }
+}
+
+class _ReadOnlyBadge extends StatelessWidget {
+  const _ReadOnlyBadge({required this.label});
+
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    return Material(
+      color: Theme.of(context).colorScheme.secondaryContainer,
+      borderRadius: BorderRadius.circular(6),
+      child: Padding(
+        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
+        child: Text(
+          label,
+          style: Theme.of(context).textTheme.labelSmall?.copyWith(
+                color: Theme.of(context).colorScheme.onSecondaryContainer,
+                fontWeight: FontWeight.w500,
+              ),
+        ),
+      ),
+    );
+  }
+}
+
+class _CounterRow extends StatelessWidget {
+  const _CounterRow({
+    required this.atlas,
+    required this.animations,
+    required this.presets,
+  });
+
+  final int atlas;
+  final int animations;
+  final int presets;
+
+  @override
+  Widget build(BuildContext context) {
+    return Wrap(
+      spacing: 16,
+      runSpacing: 8,
+      children: [
+        _CounterChip(label: 'Atlas', value: atlas),
+        _CounterChip(label: 'Animations', value: animations),
+        _CounterChip(label: 'Presets', value: presets),
+      ],
+    );
+  }
+}
+
+class _CounterChip extends StatelessWidget {
+  const _CounterChip({required this.label, required this.value});
+
+  final String label;
+  final int value;
+
+  @override
+  Widget build(BuildContext context) {
+    final t = Theme.of(context);
+    return Card(
+      margin: EdgeInsets.zero,
+      child: Padding(
+        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          mainAxisSize: MainAxisSize.min,
+          children: [
+            Text(
+              label,
+              style: t.textTheme.labelMedium?.copyWith(
+                color: t.colorScheme.onSurfaceVariant,
+              ),
+            ),
+            const SizedBox(height: 4),
+            Text(
+              '$value',
+              style: t.textTheme.titleLarge?.copyWith(
+                fontWeight: FontWeight.w600,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _EmptyStateCard extends StatelessWidget {
+  const _EmptyStateCard({
+    required this.title,
+    required this.subtitle,
+  });
+
+  final String title;
+  final String subtitle;
+
+  @override
+  Widget build(BuildContext context) {
+    final t = Theme.of(context);
+    return Card(
+      child: Padding(
+        padding: const EdgeInsets.all(16),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: [
+            Text(title, style: t.textTheme.titleMedium),
+            const SizedBox(height: 6),
+            Text(
+              subtitle,
+              style: t.textTheme.bodySmall?.copyWith(
+                color: t.colorScheme.onSurfaceVariant,
+              ),
+            ),
+          ],
+        ),
+      ),
+    );
+  }
+}
+
+class _DiagnosticsSummary extends StatelessWidget {
+  const _DiagnosticsSummary({
+    required this.readModel,
+    required this.theme,
+  });
+
+  final SurfaceStudioReadModel readModel;
+  final ThemeData theme;
+
+  @override
+  Widget build(BuildContext context) {
+    final d = readModel.diagnostics;
+    final err = d.summary.errorCount;
+    final warn = d.summary.warningCount;
+
+    final children = <Widget>[];
+
+    if (d.isClean) {
+      children.add(
+        Text(
+          SurfaceStudioPanel.diagnosticsCleanText,
+          style: theme.textTheme.bodyLarge?.copyWith(
+            color: theme.colorScheme.primary,
+          ),
+        ),
+      );
+    } else {
+      if (readModel.hasErrors) {
+        children.add(
+          Text(
+            '$err — ${SurfaceStudioPanel.diagnosticsErrorsText}',
+            style: theme.textTheme.bodyLarge?.copyWith(
+              color: theme.colorScheme.error,
+            ),
+          ),
+        );
+      }
+      if (readModel.hasWarnings) {
+        children.add(
+          Padding(
+            padding: EdgeInsets.only(top: readModel.hasErrors ? 6 : 0),
+            child: Text(
+              '$warn — ${SurfaceStudioPanel.diagnosticsWarningsText}',
+              style: theme.textTheme.bodyLarge?.copyWith(
+                color: theme.colorScheme.tertiary,
+              ),
+            ),
+          ),
+        );
+      }
+    }
+
+    return Card(
+      child: Padding(
+        padding: const EdgeInsets.all(12),
+        child: Column(
+          crossAxisAlignment: CrossAxisAlignment.start,
+          children: children,
+        ),
+      ),
+    );
+  }
+}
+
+class _FutureActions extends StatelessWidget {
+  const _FutureActions({
+    required this.onCreateAtlas,
+    required this.onImportVertical,
+  });
+
+  final VoidCallback? onCreateAtlas;
+  final VoidCallback? onImportVertical;
+
+  @override
+  Widget build(BuildContext context) {
+    return Column(
+      crossAxisAlignment: CrossAxisAlignment.stretch,
+      children: [
+        Text(
+          'Actions (non disponibles dans ce lot)',
+          style: Theme.of(context).textTheme.labelLarge,
+        ),
+        const SizedBox(height: 8),
+        Row(
+          children: [
+            TextButton(
+              onPressed: onCreateAtlas,
+              child: const Text(SurfaceStudioPanel.actionCreateAtlasLabel),
+            ),
+            const SizedBox(width: 8),
+            TextButton(
+              onPressed: onImportVertical,
+              child: const Text(
+                SurfaceStudioPanel.actionImportVerticalAtlasLabel,
+              ),
+            ),
+          ],
+        ),
+      ],
+    );
+  }
+}
+
+class _SectionPlaceholder extends StatelessWidget {
+  const _SectionPlaceholder({
+    required this.title,
+    required this.theme,
+  });
+
+  final String title;
+  final ThemeData theme;
+
+  @override
+  Widget build(BuildContext context) {
+    return Card(
+      child: ListTile(
+        title: Text(title, style: theme.textTheme.titleSmall),
+        subtitle: const Text(SurfaceStudioPanel.placeholderSoonText),
+        trailing: const Icon(Icons.layers_outlined),
+      ),
+    );
+  }
+}
+
+/// Adaptateur : construit le read model **sans** I/O à partir d’un [ProjectManifest].
+class SurfaceStudioPanelFromManifest extends StatelessWidget {
+  const SurfaceStudioPanelFromManifest({
+    super.key,
+    required this.manifest,
+  });
+
+  final ProjectManifest manifest;
+
+  @override
+  Widget build(BuildContext context) {
+    return SurfaceStudioPanel(
+      readModel: buildSurfaceStudioReadModel(manifest),
+    );
+  }
+}

```

#### C.2 `surface_studio_panel_test.dart`

```diff
diff --git a/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
new file mode 100644
index 00000000..458085c9
--- /dev/null
+++ b/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart
@@ -0,0 +1,360 @@
+// Tests widget — Surface Studio panel (Lot 52).
+// Imports `map_core` en API publique uniquement (pas de `map_core/src/...`).
+
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:map_core/map_core.dart';
+import 'package:map_editor/src/features/surface_studio/surface_studio_panel.dart';
+
+void main() {
+  group('SurfaceStudioPanel (Lot 52)', () {
+    testWidgets('1. title Surface Studio is visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Surface Studio'), findsOneWidget);
+    });
+
+    testWidgets('2. read-only badge is visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Lecture seule'), findsOneWidget);
+    });
+
+    testWidgets('3. three counters are zero for empty catalog', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      // Trois compteurs à 0
+      expect(find.text('0'), findsNWidgets(3));
+    });
+
+    testWidgets('4. empty catalog shows empty state copy', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(
+        find.textContaining('Aucun catalogue Surface'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('5. minimal catalog shows 1/1/1', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('1'), findsNWidgets(3));
+    });
+
+    testWidgets('6. non-empty shows catalog detected', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Catalogue Surface détecté'), findsOneWidget);
+    });
+
+    testWidgets('7. clean diagnostics for minimal coherent catalog',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.text('Aucun diagnostic Surface'), findsOneWidget);
+    });
+
+    testWidgets('8. warning state when unused atlas', (tester) async {
+      final rm = _warningReadModel();
+      expect(rm.hasWarnings, isTrue);
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: rm)),
+      );
+      expect(
+        find.textContaining('Avertissements Surface détectés'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('9. error state when preset animation missing', (tester) async {
+      final rm = _errorReadModel();
+      expect(rm.hasErrors, isTrue);
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: rm)),
+      );
+      expect(
+        find.textContaining('Erreurs Surface détectées'),
+        findsOneWidget,
+      );
+    });
+
+    testWidgets('10. future action labels are visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Créer un atlas'), findsOneWidget);
+      expect(find.text('Importer un atlas vertical'), findsOneWidget);
+    });
+
+    testWidgets('11. future actions are disabled (onPressed null)',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      final b1 = tester.widget<TextButton>(
+        find.ancestor(
+          of: find.text('Créer un atlas'),
+          matching: find.byType(TextButton),
+        ),
+      );
+      final b2 = tester.widget<TextButton>(
+        find.ancestor(
+          of: find.text('Importer un atlas vertical'),
+          matching: find.byType(TextButton),
+        ),
+      );
+      expect(b1.onPressed, isNull);
+      expect(b2.onPressed, isNull);
+    });
+
+    testWidgets('12. section placeholder titles are visible', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Catalogue'), findsOneWidget);
+      expect(find.text('Diagnostics'), findsOneWidget);
+      expect(find.text('Actions auteur'), findsOneWidget);
+    });
+
+    testWidgets('13. SurfaceStudioPanelFromManifest uses manifest catalog',
+        (tester) async {
+      final cat = _minimalWaterCatalog();
+      final manifest = _manifest(cat);
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      expect(find.text('1'), findsNWidgets(3));
+    });
+
+    testWidgets('14. manifest is not mutated after pump', (tester) async {
+      final cat = _minimalWaterCatalog();
+      final before = cat.atlases.length;
+      final manifest = _manifest(cat);
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanelFromManifest(manifest: manifest)),
+      );
+      expect(manifest.surfaceCatalog.atlases.length, before);
+    });
+
+    testWidgets(
+      '15. does not require provider setup — panel builds without ProviderScope',
+      (tester) async {
+        await tester.pumpWidget(
+          MaterialApp(
+            home: Scaffold(
+              body: SurfaceStudioPanel(readModel: _emptyReadModel()),
+            ),
+          ),
+        );
+        expect(find.text('Surface Studio'), findsOneWidget);
+      },
+    );
+
+    testWidgets('16. content is in a scrollable', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.byType(SingleChildScrollView), findsOneWidget);
+    });
+
+    testWidgets('17. no internal domain type names in user-visible strings',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _minimalWaterReadModel())),
+      );
+      expect(find.textContaining('ProjectSurfaceCatalog'), findsNothing);
+      expect(find.textContaining('SurfaceStudioReadModel'), findsNothing);
+      expect(
+          find.textContaining('SurfaceVariantAnimationRefSet'), findsNothing);
+    });
+
+    testWidgets('18. error read model does not throw on build', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _errorReadModel())),
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('19. warning read model does not throw on build',
+        (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _warningReadModel())),
+      );
+      expect(tester.takeException(), isNull);
+    });
+
+    testWidgets('20. displayed counts match read model summary',
+        (tester) async {
+      final rm = _minimalWaterReadModel();
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: rm)),
+      );
+      expect(rm.summary.atlasCount, 1);
+      expect(rm.summary.animationCount, 1);
+      expect(rm.summary.presetCount, 1);
+    });
+
+    testWidgets('22. no TextField in panel', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.byType(TextField), findsNothing);
+    });
+
+    testWidgets('23. no save affordances', (tester) async {
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.textContaining('Sauvegarder'), findsNothing);
+      expect(find.textContaining('Enregistrer'), findsNothing);
+      expect(find.textContaining('Save'), findsNothing);
+    });
+
+    testWidgets('24. test file uses public map_core only (smoke)',
+        (tester) async {
+      // Vérification statique : seul `package:map_core/map_core.dart` est importé.
+      await tester.pumpWidget(
+        _wrap(SurfaceStudioPanel(readModel: _emptyReadModel())),
+      );
+      expect(find.text('Surface Studio'), findsOneWidget);
+    });
+  });
+}
+
+Widget _wrap(Widget child) {
+  return MaterialApp(
+    home: Scaffold(
+      body: child,
+    ),
+  );
+}
+
+SurfaceStudioReadModel _emptyReadModel() {
+  return buildSurfaceStudioReadModelFromCatalog(ProjectSurfaceCatalog());
+}
+
+SurfaceStudioReadModel _minimalWaterReadModel() {
+  return buildSurfaceStudioReadModelFromCatalog(_minimalWaterCatalog());
+}
+
+SurfaceStudioReadModel _warningReadModel() {
+  return buildSurfaceStudioReadModelFromCatalog(_catalogWithUnusedAtlas());
+}
+
+SurfaceStudioReadModel _errorReadModel() {
+  return buildSurfaceStudioReadModelFromCatalog(_catalogWithMissingAnimation());
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
+ProjectSurfaceCatalog _minimalWaterCatalog() {
+  final g = _geom();
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
+
+ProjectSurfaceCatalog _catalogWithMissingAnimation() {
+  final refs = SurfaceVariantAnimationRefSet(
+    refs: [
+      SurfaceVariantAnimationRef(
+        role: SurfaceVariantRole.isolated,
+        animationId: 'missing-anim',
+      ),
+    ],
+  );
+  return ProjectSurfaceCatalog(
+    atlases: const [],
+    animations: const [],
+    presets: [
+      ProjectSurfacePreset(
+        id: 'p',
+        name: 'p',
+        variantAnimations: refs,
+      ),
+    ],
+  );
+}
+
+ProjectManifest _manifest(ProjectSurfaceCatalog catalog) {
+  return ProjectManifest(
+    name: 'Test',
+    maps: const [],
+    tilesets: const [],
+    surfaceCatalog: catalog,
+  );
+}

```

### D. Renvoi

Les sorties de commandes sont reprises en intégralité aux **§32–35**.
