# Lot 64-bis — Analyze / Evidence Coverage Fix Only

## Résumé exécutif

Le Lot 64-bis ne modifie aucun code. Il complète la preuve d’analyse manquante du rapport Lot 64 : une commande `flutter analyze` ciblée inclut explicitement `lib/src/ui/canvas/editor_canvas_host.dart` et `lib/src/features/editor/state/editor_notifier.dart` en plus de `lib/src/features/surface_studio` et de `test/surface_studio`. L’analyse passe. Les tests Surface Studio ciblés, la suite `test/surface_studio` et le test `map_core` `surface_studio_read_model` sont relancés et passent. Le Lot 64 peut être fermé au regard de la réserve d’analyse.

## Question à clarifier

Le Lot 64 a modifié `editor_canvas_host.dart` et `editor_notifier.dart` hors de l’arborescence `lib/src/features/surface_studio/`.

Le rapport Lot 64 documentait principalement l’analyse :

`cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio`

Cette commande n’inclut pas des chemins explicites par fichier vers `editor_canvas_host.dart` et `editor_notifier.dart` (dépend de la façon dont l’outil d’analyse regroupe les répertoires ; la réserve est que la preuve écrite ne listait pas ces deux fichiers par chemin explicite).

Le Lot 64-bis lance la commande exigée par le contrat avec chemins explicites pour recouvrir tout le périmètre Dart des fichiers modifiés listés.

## Périmètre

- Un seul fichier créé : `reports/surface/surface_engine_lot_64_bis_analyze_evidence_coverage.md`
- Aucun fichier de code modifié
- Rapport Lot 64 non modifié

## Commandes exécutées

Séquence exécutée depuis la machine d’audit (emplacement du clone) pour ce lot, avant rédaction finale de ce document :

- `pwd`
- `git branch --show-current`
- `git status --short --untracked-files=all`
- `git diff --stat`
- `git log --oneline -n 5`
- `test -e` et `grep` (rapport Lot 64)
- `test -e` (fichiers Lot 64)
- `git diff` (cinq chemins)
- `find` (fichiers temporaires)
- `flutter analyze` (commande large Lot 64-bis)
- `flutter test` (workspace, panel, `test/surface_studio`, `map_core` read model)
- `git status` / `git diff --stat` (final, après génération de ce rapport)

## Git status actuel frais

*Capture exécutée **avant** l’ajout de ce rapport sur le disque, pour isoler l’état worktree d’intégration du Lot 64 sans le fichier 64-bis.*

**Commande** : `git status --short --untracked-files=all`  
**Sortie exacte** :

```
Sortie : <vide>
```

*Si la ligne ci-dessus est `Sortie : <vide>`, l’arbre de travail était propre (aucun `M` ni `??`) au moment de la capture pré-rapport.*

**Commande** : `git diff --stat`  
**Sortie exacte** :

```
Sortie : <vide>
```

**`pwd`** : `/Users/karim/Project/pokemonProject`

**`git branch --show-current`** : `codex/psdk-fight-next-move-wave`

**`git log --oneline -n 5`** :

```
ec35c497 feat(map_editor): Surface Studio manifest save wiring in memory (Lot 64)
69faacc4 update tests
7ad7e847 feat(map_editor): Surface Studio save flow prep (Lot 63) + rapport 63-bis
9fe386ba feat(map_editor): Surface Studio work catalog state hardening (Lot 62)
4977cfa3 feat(map_editor): Surface Studio création atlas catalogue de travail (Lot 61)

```

## Audit du rapport Lot 64

**Commande** : `test -e reports/surface/surface_engine_lot_64_surface_studio_manifest_save_wiring.md; echo "lot64_report_exists=$?"`  
**Sortie exacte** : `lot64_report_exists=0`

**Commande** : `grep -n "flutter analyze" reports/surface/surface_engine_lot_64_surface_studio_manifest_save_wiring.md || true`  
**Sortie exacte** : (extraits, lignes concernées)

```
54:| `cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio` | Dernière ligne : `No issues found!` |
58:- `cd packages/map_editor && flutter analyze lib/src/features/surface_studio test/surface_studio`
603:- `flutter analyze` ciblé ? **Oui** (No issues)

```

**Commande** : `grep -n "editor_canvas_host" reports/surface/surface_engine_lot_64_surface_studio_manifest_save_wiring.md || true`  
**Sortie exacte** : (même principe)

```
9:- Fichiers modifiés : `surface_studio_panel.dart`, `editor_canvas_host.dart`, `editor_notifier.dart`, `surface_studio_panel_test.dart`, `surface_studio_workspace_entry_test.dart`
33:- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
99: M packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
110: .../lib/src/ui/canvas/editor_canvas_host.dart      |   9 +-
266:diff --git a/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart b/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
268:--- a/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
269:+++ b/packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart
604:- Rapport evidence complet (diffs + sorties) ? **Oui** (diff `git` intégral, sorties de commandes, `editor_canvas_host` et `surface_studio_panel` intégraux dans ce document)
614:### `editor_canvas_host.dart` (fichier entier, 48 lignes)

```

**Commande** : `grep -n "editor_notifier" reports/surface/surface_engine_lot_64_surface_studio_manifest_save_wiring.md || true`  
**Sortie exacte** :

```
9:- Fichiers modifiés : `surface_studio_panel.dart`, `editor_canvas_host.dart`, `editor_notifier.dart`, `surface_studio_panel_test.dart`, `surface_studio_workspace_entry_test.dart`
34:- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
97: M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
108: .../src/features/editor/state/editor_notifier.dart |   4 +
127:diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
129:--- a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
130:+++ b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
486:+import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
620:import '../../features/editor/state/editor_notifier.dart';

```

Ces preuves établissent que le rapport Lot 64 mentionne `editor_canvas_host` et `editor_notifier` (contenu, diffs) tout en consignant l’analyse sous la forme `flutter analyze lib/src/features/surface_studio test/surface_studio` dans le tableau des résultats.

## Audit des fichiers Lot 64

**Existence** (`test -e` ; code de sortie 0 = fichier présent) :

- `surface_studio_panel_exists=0`
- `editor_canvas_host_exists=0`
- `editor_notifier_exists=0`
- `surface_studio_panel_test_exists=0`
- `surface_studio_workspace_entry_test_exists=0`

**`git diff` actuels** (arbre propre = aucun diff local ; les modifications Lot 64 sont sur `HEAD`) :

`packages/map_editor/lib/src/features/surface_studio/surface_studio_panel.dart` :

```
Sortie : <vide>
```

`packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart` :

```
Sortie : <vide>
```

`packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` :

```
Sortie : <vide>
```

`packages/map_editor/test/surface_studio/surface_studio_panel_test.dart` :

```
Sortie : <vide>
```

`packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart` :

```
Sortie : <vide>
```

*Interprétation* : l’absence de diff indique qu’il n’y a pas de modification locale en attente sur ces chemins par rapport à `HEAD` ; le contenu des lots 63/64 est déjà intégré en commit. Le Lot 64-bis n’applique aucun patch.

## Analyse ciblée complète

**Commande exacte** :

```bash
cd packages/map_editor && flutter analyze \
  lib/src/features/surface_studio \
  lib/src/ui/canvas/editor_canvas_host.dart \
  lib/src/features/editor/state/editor_notifier.dart \
  test/surface_studio
```

**Sortie intégrale (stdout+stderr, code de sortie 0)** :

```
Analyzing 4 items...                                            
No issues found! (ran in 4.9s)

```

*Remarque* : `flutter analyze` annonce `Analyzing 4 items` : les entrées regroupent les répertoires et les deux fichiers `.dart` explicites en un jeu d’unités d’analyse.

Cette exécution couvre **explicitement** `editor_canvas_host.dart` et `editor_notifier.dart` tels qu’inscrits sur la ligne de commande, ainsi que l’intégralité de `lib/src/features/surface_studio` et de `test/surface_studio`.

## Tests relancés

### 1) `test/surface_studio/surface_studio_workspace_entry_test.dart`

**Commande** : `cd packages/map_editor && flutter test test/surface_studio/surface_studio_workspace_entry_test.dart`

**Sortie intégrale** :

```

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart                                                                 
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart                                                                 
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart                                                                 
00:02 +0: Surface Studio workspace entry (Lot 53) EditorWorkspaceMode.surfaceStudio exists in enum                                                                                                     
00:02 +1: Surface Studio workspace entry (Lot 53) EditorWorkspaceMode.surfaceStudio exists in enum                                                                                                     
00:02 +1: Surface Studio workspace entry (Lot 53) entry title Surface Studio is visible in explorer                                                                                                    
00:03 +1: Surface Studio workspace entry (Lot 53) entry title Surface Studio is visible in explorer                                                                                                    
00:03 +2: Surface Studio workspace entry (Lot 53) entry title Surface Studio is visible in explorer                                                                                                    
00:03 +2: Surface Studio workspace entry (Lot 53) subtitle mentions animated surfaces (Surfaces animées)                                                                                               
00:03 +3: Surface Studio workspace entry (Lot 53) subtitle mentions animated surfaces (Surfaces animées)                                                                                               
00:03 +3: Surface Studio workspace entry (Lot 53) Terrain / Surface Studio / Path Library order in column                                                                                              
00:04 +3: Surface Studio workspace entry (Lot 53) Terrain / Surface Studio / Path Library order in column                                                                                              
00:04 +4: Surface Studio workspace entry (Lot 53) Terrain / Surface Studio / Path Library order in column                                                                                              
00:04 +4: Surface Studio workspace entry (Lot 53) tap entry opens center panel with Lecture seule                                                                                                      
00:04 +5: Surface Studio workspace entry (Lot 53) tap entry opens center panel with Lecture seule                                                                                                      
00:04 +5: Surface Studio workspace entry (Lot 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode                                                                                           
00:05 +5: Surface Studio workspace entry (Lot 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode                                                                                           
00:05 +6: Surface Studio workspace entry (Lot 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode                                                                                           
00:05 +6: Surface Studio workspace entry (Lot 53) works without an active map (no map required)                                                                                                        
00:06 +6: Surface Studio workspace entry (Lot 53) works without an active map (no map required)                                                                                                        
00:06 +7: Surface Studio workspace entry (Lot 53) works without an active map (no map required)                                                                                                        
00:06 +7: Surface Studio workspace entry (Lot 53) panel shows 1/1/1 from manifest when catalog is minimal                                                                                              
00:06 +8: Surface Studio workspace entry (Lot 53) panel shows 1/1/1 from manifest when catalog is minimal                                                                                              
00:06 +8: Surface Studio workspace entry (Lot 53) read-only: actions désactivées; TextField seulement brouillon Lot 60                                                                                 
00:06 +9: Surface Studio workspace entry (Lot 53) read-only: actions désactivées; TextField seulement brouillon Lot 60                                                                                 
00:06 +9: Surface Studio workspace entry (Lot 53) no Surface save button labels                                                                                                                        
00:06 +10: Surface Studio workspace entry (Lot 53) no Surface save button labels                                                                                                                       
00:06 +10: Surface Studio workspace entry (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace                                                                                               
00:07 +10: Surface Studio workspace entry (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace                                                                                               
00:07 +11: Surface Studio workspace entry (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace                                                                                               
00:07 +11: Surface Studio workspace entry (Lot 53) no internal type names in visible shell copy                                                                                                        
00:07 +12: Surface Studio workspace entry (Lot 53) no internal type names in visible shell copy                                                                                                        
00:07 +12: Surface Studio workspace entry (Lot 53) Lot 64 — préparer sauvegarde : manifest en mémoire (notifier) sans disque                                                                           
00:08 +12: Surface Studio workspace entry (Lot 53) Lot 64 — préparer sauvegarde : manifest en mémoire (notifier) sans disque                                                                           
00:08 +13: Surface Studio workspace entry (Lot 53) Lot 64 — préparer sauvegarde : manifest en mémoire (notifier) sans disque                                                                           
00:08 +13: All tests passed!                                                                                                                                                                           

```

### 2) `test/surface_studio/surface_studio_panel_test.dart`

**Commande** : `cd packages/map_editor && flutter test test/surface_studio/surface_studio_panel_test.dart`

**Sortie intégrale** (longueur 30801 caractères) :

```

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart                                                                           
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart                                                                           
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart                                                                           
00:02 +0: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                                                                                                                               
00:03 +0: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                                                                                                                               
00:03 +1: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                                                                                                                               
00:03 +1: SurfaceStudioPanel (Lot 52) 2. read-only badge is visible                                                                                                                                    
00:03 +2: SurfaceStudioPanel (Lot 52) 2. read-only badge is visible                                                                                                                                    
00:03 +2: SurfaceStudioPanel (Lot 52) 3. three counters are zero for empty catalog                                                                                                                     
00:04 +2: SurfaceStudioPanel (Lot 52) 3. three counters are zero for empty catalog                                                                                                                     
00:04 +3: SurfaceStudioPanel (Lot 52) 3. three counters are zero for empty catalog                                                                                                                     
00:04 +3: SurfaceStudioPanel (Lot 52) 4. empty catalog shows empty state copy                                                                                                                          
00:04 +4: SurfaceStudioPanel (Lot 52) 4. empty catalog shows empty state copy                                                                                                                          
00:04 +4: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                                                                                                                                   
00:04 +5: SurfaceStudioPanel (Lot 52) 5. minimal catalog shows 1/1/1                                                                                                                                   
00:04 +5: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content                                                                                                                       
00:04 +6: SurfaceStudioPanel (Lot 52) 6. non-empty shows catalog browser content                                                                                                                       
00:04 +6: SurfaceStudioPanel (Lot 52) 7. clean diagnostics for minimal coherent catalog                                                                                                                
00:04 +7: SurfaceStudioPanel (Lot 52) 7. clean diagnostics for minimal coherent catalog                                                                                                                
00:04 +7: SurfaceStudioPanel (Lot 52) 8. warning state when unused atlas                                                                                                                               
00:04 +8: SurfaceStudioPanel (Lot 52) 8. warning state when unused atlas                                                                                                                               
00:04 +8: SurfaceStudioPanel (Lot 52) 9. error state when preset animation missing                                                                                                                     
00:05 +8: SurfaceStudioPanel (Lot 52) 9. error state when preset animation missing                                                                                                                     
00:05 +9: SurfaceStudioPanel (Lot 52) 9. error state when preset animation missing                                                                                                                     
00:05 +9: SurfaceStudioPanel (Lot 52) 10. future action label import visible (pas Créer un atlas)                                                                                                      
00:05 +10: SurfaceStudioPanel (Lot 52) 10. future action label import visible (pas Créer un atlas)                                                                                                     
00:05 +10: SurfaceStudioPanel (Lot 52) 11. future import action disabled (onPressed null)                                                                                                              
00:05 +11: SurfaceStudioPanel (Lot 52) 11. future import action disabled (onPressed null)                                                                                                              
00:05 +11: SurfaceStudioPanel (Lot 52) 12. section placeholder titles are visible                                                                                                                      
00:05 +12: SurfaceStudioPanel (Lot 52) 12. section placeholder titles are visible                                                                                                                      
00:05 +12: SurfaceStudioPanel (Lot 52) 13. SurfaceStudioPanelFromManifest uses manifest catalog                                                                                                        
00:05 +13: SurfaceStudioPanel (Lot 52) 13. SurfaceStudioPanelFromManifest uses manifest catalog                                                                                                        
00:05 +13: SurfaceStudioPanel (Lot 52) 14. manifest is not mutated after pump                                                                                                                          
00:05 +14: SurfaceStudioPanel (Lot 52) 14. manifest is not mutated after pump                                                                                                                          
00:05 +14: SurfaceStudioPanel (Lot 52) 15. does not require provider setup — panel builds without ProviderScope                                                                                        
00:06 +14: SurfaceStudioPanel (Lot 52) 15. does not require provider setup — panel builds without ProviderScope                                                                                        
00:06 +15: SurfaceStudioPanel (Lot 52) 15. does not require provider setup — panel builds without ProviderScope                                                                                        
00:06 +15: SurfaceStudioPanel (Lot 52) 16. content is in a scrollable                                                                                                                                  
00:06 +16: SurfaceStudioPanel (Lot 52) 16. content is in a scrollable                                                                                                                                  
00:06 +16: SurfaceStudioPanel (Lot 52) 17. no internal domain type names in user-visible strings                                                                                                       
00:06 +17: SurfaceStudioPanel (Lot 52) 17. no internal domain type names in user-visible strings                                                                                                       
00:06 +17: SurfaceStudioPanel (Lot 52) 18. error read model does not throw on build                                                                                                                    
00:06 +18: SurfaceStudioPanel (Lot 52) 18. error read model does not throw on build                                                                                                                    
00:06 +18: SurfaceStudioPanel (Lot 52) 19. warning read model does not throw on build                                                                                                                  
00:06 +19: SurfaceStudioPanel (Lot 52) 19. warning read model does not throw on build                                                                                                                  
00:06 +19: SurfaceStudioPanel (Lot 52) 20. displayed counts match read model summary                                                                                                                   
00:06 +20: SurfaceStudioPanel (Lot 52) 20. displayed counts match read model summary                                                                                                                   
00:06 +20: SurfaceStudioPanel (Lot 52) 22. TextField seulement zone brouillon (Lot 60), pas dans inspecteur                                                                                            
00:07 +20: SurfaceStudioPanel (Lot 52) 22. TextField seulement zone brouillon (Lot 60), pas dans inspecteur                                                                                            
00:07 +21: SurfaceStudioPanel (Lot 52) 22. TextField seulement zone brouillon (Lot 60), pas dans inspecteur                                                                                            
00:07 +21: SurfaceStudioPanel (Lot 52) 23. no save affordances                                                                                                                                         
00:07 +22: SurfaceStudioPanel (Lot 52) 23. no save affordances                                                                                                                                         
00:07 +22: SurfaceStudioPanel (Lot 52) 22. panel shows catalog browser for minimal catalog                                                                                                             
00:07 +23: SurfaceStudioPanel (Lot 52) 22. panel shows catalog browser for minimal catalog                                                                                                             
00:07 +23: SurfaceStudioPanel (Lot 52) 24. test file uses public map_core only (smoke)                                                                                                                 
00:07 +24: SurfaceStudioPanel (Lot 52) 24. test file uses public map_core only (smoke)                                                                                                                 
00:07 +24: SurfaceStudioPanel (Lot 52) 25. Lot 55 — clean diagnostics view in panel                                                                                                                    
00:07 +25: SurfaceStudioPanel (Lot 52) 25. Lot 55 — clean diagnostics view in panel                                                                                                                    
00:07 +25: SurfaceStudioPanel (Lot 52) 26. Lot 55 — error diagnostics visible in panel                                                                                                                 
00:08 +25: SurfaceStudioPanel (Lot 52) 26. Lot 55 — error diagnostics visible in panel                                                                                                                 
00:08 +26: SurfaceStudioPanel (Lot 52) 26. Lot 55 — error diagnostics visible in panel                                                                                                                 
00:08 +26: SurfaceStudioPanel (Lot 52) 27. Lot 55 — browser and diagnostics cohabit (minimal cat)                                                                                                      
00:08 +27: SurfaceStudioPanel (Lot 52) 27. Lot 55 — browser and diagnostics cohabit (minimal cat)                                                                                                      
00:08 +27: SurfaceStudioPanel (Lot 52) 48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics                                                                                             
00:08 +28: SurfaceStudioPanel (Lot 52) 48. Lot 57 — panel shows Atlas / Animations / Presets / Diagnostics                                                                                             
00:08 +28: SurfaceStudioPanel (Lot 52) 58.21 — Aucune sélection au départ (catalogue minimal)                                                                                                          
00:08 +29: SurfaceStudioPanel (Lot 52) 58.21 — Aucune sélection au départ (catalogue minimal)                                                                                                          
00:08 +29: SurfaceStudioPanel (Lot 52) 58.22 — sélection atlas après tap                                                                                                                               
00:08 +30: SurfaceStudioPanel (Lot 52) 58.22 — sélection atlas après tap                                                                                                                               
00:08 +30: SurfaceStudioPanel (Lot 52) 58.23 — sélection animation après tap                                                                                                                           
00:09 +30: SurfaceStudioPanel (Lot 52) 58.23 — sélection animation après tap                                                                                                                           
00:09 +31: SurfaceStudioPanel (Lot 52) 58.23 — sélection animation après tap                                                                                                                           
00:09 +31: SurfaceStudioPanel (Lot 52) 58.24 — sélection preset après tap                                                                                                                              
00:09 +32: SurfaceStudioPanel (Lot 52) 58.24 — sélection preset après tap                                                                                                                              
00:09 +32: SurfaceStudioPanel (Lot 52) 58.25 — changement de sélection remplace la précédente                                                                                                          
00:09 +33: SurfaceStudioPanel (Lot 52) 58.25 — changement de sélection remplace la précédente                                                                                                          
00:09 +33: SurfaceStudioPanel (Lot 52) 58.26 — sélection ne mute pas surfaceCatalog                                                                                                                    
00:09 +34: SurfaceStudioPanel (Lot 52) 58.26 — sélection ne mute pas surfaceCatalog                                                                                                                    
00:09 +34: SurfaceStudioPanel (Lot 52) 58.27 — pas de TextField dans inspecteur après sélections                                                                                                       
00:09 +35: SurfaceStudioPanel (Lot 52) 58.27 — pas de TextField dans inspecteur après sélections                                                                                                       
00:09 +35: SurfaceStudioPanel (Lot 52) 58.28 — pas de libellés édition/save actifs                                                                                                                     
00:10 +35: SurfaceStudioPanel (Lot 52) 58.28 — pas de libellés édition/save actifs                                                                                                                     
00:10 +36: SurfaceStudioPanel (Lot 52) 58.28 — pas de libellés édition/save actifs                                                                                                                     
00:10 +36: SurfaceStudioPanel (Lot 52) 59.20 — inspecteur none au départ                                                                                                                               
00:10 +37: SurfaceStudioPanel (Lot 52) 59.20 — inspecteur none au départ                                                                                                                               
00:10 +37: SurfaceStudioPanel (Lot 52) 59.21 — inspecteur atlas après tap                                                                                                                              
00:10 +38: SurfaceStudioPanel (Lot 52) 59.21 — inspecteur atlas après tap                                                                                                                              
00:10 +38: SurfaceStudioPanel (Lot 52) 59.22 — inspecteur animation après tap                                                                                                                          
00:10 +39: SurfaceStudioPanel (Lot 52) 59.22 — inspecteur animation après tap                                                                                                                          
00:10 +39: SurfaceStudioPanel (Lot 52) 59.23 — inspecteur preset après tap                                                                                                                             
00:10 +40: SurfaceStudioPanel (Lot 52) 59.23 — inspecteur preset après tap                                                                                                                             
00:10 +40: SurfaceStudioPanel (Lot 52) 59.24 — changement de sélection met l’inspecteur à jour                                                                                                         
00:10 +41: SurfaceStudioPanel (Lot 52) 59.24 — changement de sélection met l’inspecteur à jour                                                                                                         
00:10 +41: SurfaceStudioPanel (Lot 52) 59.25 — inspecteur ne mute pas le manifest                                                                                                                      
00:11 +41: SurfaceStudioPanel (Lot 52) 59.25 — inspecteur ne mute pas le manifest                                                                                                                      
00:11 +42: SurfaceStudioPanel (Lot 52) 59.25 — inspecteur ne mute pas le manifest                                                                                                                      
00:11 +42: SurfaceStudioPanel (Lot 52) 59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)                                                                                            
00:11 +43: SurfaceStudioPanel (Lot 52) 59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)                                                                                            
00:11 +43: SurfaceStudioPanel (Lot 52) 59.27 — pas de libellés édition/save (Lot 59)                                                                                                                   
00:11 +44: SurfaceStudioPanel (Lot 52) 59.27 — pas de libellés édition/save (Lot 59)                                                                                                                   
00:11 +44: SurfaceStudioPanel (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump                                                                                                          
00:11 +45: SurfaceStudioPanel (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump                                                                                                          
00:11 +45: SurfaceStudioPanel (Lot 52) 60.1 — Préparation atlas (brouillon) visible                                                                                                                    
00:11 +46: SurfaceStudioPanel (Lot 52) 60.1 — Préparation atlas (brouillon) visible                                                                                                                    
00:11 +46: SurfaceStudioPanel (Lot 52) 61.1 — action création atlas dans le catalogue de travail                                                                                                       
00:11 +47: SurfaceStudioPanel (Lot 52) 61.1 — action création atlas dans le catalogue de travail                                                                                                       
00:11 +47: SurfaceStudioPanel (Lot 52) 61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, inspecteur                                                                                     
00:11 +48: SurfaceStudioPanel (Lot 52) 61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, inspecteur                                                                                     
00:11 +48: SurfaceStudioPanel (Lot 52) 61.3 — créer second atlas : compteur 2, animations/presets inchangés                                                                                            
00:12 +48: SurfaceStudioPanel (Lot 52) 61.3 — créer second atlas : compteur 2, animations/presets inchangés                                                                                            
00:12 +49: SurfaceStudioPanel (Lot 52) 61.3 — créer second atlas : compteur 2, animations/presets inchangés                                                                                            
00:12 +49: SurfaceStudioPanel (Lot 52) 62.0 — pas de dirty au départ (vide + minimal)                                                                                                                  
00:12 +50: SurfaceStudioPanel (Lot 52) 62.0 — pas de dirty au départ (vide + minimal)                                                                                                                  
00:12 +50: SurfaceStudioPanel (Lot 52) 62.1 — dirty après création locale                                                                                                                              
00:12 +51: SurfaceStudioPanel (Lot 52) 62.1 — dirty après création locale                                                                                                                              
00:12 +51: SurfaceStudioPanel (Lot 52) 62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off                                                                                        
00:13 +51: SurfaceStudioPanel (Lot 52) 62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off                                                                                        
00:13 +52: SurfaceStudioPanel (Lot 52) 62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off                                                                                        
00:13 +52: SurfaceStudioPanel (Lot 52) 62.3 — reset depuis minimal : revient à Water, Grass absent, 1/1/1                                                                                              
00:13 +53: SurfaceStudioPanel (Lot 52) 62.3 — reset depuis minimal : revient à Water, Grass absent, 1/1/1                                                                                              
00:13 +53: SurfaceStudioPanel (Lot 52) 62.4 — A puis B puis reset (source vide)                                                                                                                        
00:13 +54: SurfaceStudioPanel (Lot 52) 62.4 — A puis B puis reset (source vide)                                                                                                                        
00:13 +54: SurfaceStudioPanel (Lot 52) 62.5 — readModel parent change : resync, dirty off, X absent                                                                                                    
00:14 +54: SurfaceStudioPanel (Lot 52) 62.5 — readModel parent change : resync, dirty off, X absent                                                                                                    
00:14 +55: SurfaceStudioPanel (Lot 52) 62.5 — readModel parent change : resync, dirty off, X absent                                                                                                    
00:14 +55: SurfaceStudioPanel (Lot 52) 62.6 — pas d’action fantôme Créer un atlas, vraie action présente                                                                                               
00:14 +56: SurfaceStudioPanel (Lot 52) 62.6 — pas d’action fantôme Créer un atlas, vraie action présente                                                                                               
00:14 +56: SurfaceStudioPanel (Lot 52) 62.7 — no save flow libellés interdits                                                                                                                          
00:14 +57: SurfaceStudioPanel (Lot 52) 62.7 — no save flow libellés interdits                                                                                                                          
00:14 +57: SurfaceStudioPanel (Lot 63) 63.1 — sans modification : pas d’action préparation, callback jamais                                                                                            
00:14 +58: SurfaceStudioPanel (Lot 63) 63.1 — sans modification : pas d’action préparation, callback jamais                                                                                            
00:14 +58: SurfaceStudioPanel (Lot 63) 63.2 — dirty + callback : action, un appel, catalogue complet, dirty et accusé                                                                                  
00:15 +58: SurfaceStudioPanel (Lot 63) 63.2 — dirty + callback : action, un appel, catalogue complet, dirty et accusé                                                                                  
00:15 +59: SurfaceStudioPanel (Lot 63) 63.2 — dirty + callback : action, un appel, catalogue complet, dirty et accusé                                                                                  
00:15 +59: SurfaceStudioPanel (Lot 63) 63.3 — sans callback : stable, message not connected, pas de bouton                                                                                             
00:15 +60: SurfaceStudioPanel (Lot 63) 63.3 — sans callback : stable, message not connected, pas de bouton                                                                                             
00:15 +60: SurfaceStudioPanel (Lot 63) 63.4 — resync parent : dirty off, atlas source, pas d’accusé                                                                                                    
00:15 +61: SurfaceStudioPanel (Lot 63) 63.4 — resync parent : dirty off, atlas source, pas d’accusé                                                                                                    
00:15 +61: SurfaceStudioPanel (Lot 63) 63.5 — reset après préparation : clean, accusé nettoyé, vide                                                                                                    
00:16 +61: SurfaceStudioPanel (Lot 63) 63.5 — reset après préparation : clean, accusé nettoyé, vide                                                                                                    
00:16 +62: SurfaceStudioPanel (Lot 63) 63.5 — reset après préparation : clean, accusé nettoyé, vide                                                                                                    
00:16 +62: SurfaceStudioPanel (Lot 63) 63.6 — A puis B puis préparation : ordre des atlas                                                                                                              
00:17 +62: SurfaceStudioPanel (Lot 63) 63.6 — A puis B puis préparation : ordre des atlas                                                                                                              
00:17 +63: SurfaceStudioPanel (Lot 63) 63.6 — A puis B puis préparation : ordre des atlas                                                                                                              
00:17 +63: SurfaceStudioPanel (Lot 64) 64.1 — FromManifest : préparer sauvegarde, manifest mémoire, dirty off                                                                                          
00:17 +64: SurfaceStudioPanel (Lot 64) 64.1 — FromManifest : préparer sauvegarde, manifest mémoire, dirty off                                                                                          
00:17 +64: SurfaceStudioPanel (Lot 64) 64.2 — onProjectManifestChanged une fois, atlas dans manifest                                                                                                   
00:17 +65: SurfaceStudioPanel (Lot 64) 64.2 — onProjectManifestChanged une fois, atlas dans manifest                                                                                                   
00:17 +65: SurfaceStudioPanel (Lot 64) 64.3 — onProjectManifestChanged absent : pas d’exception                                                                                                        
00:17 +66: SurfaceStudioPanel (Lot 64) 64.3 — onProjectManifestChanged absent : pas d’exception                                                                                                        
00:17 +66: SurfaceStudioPanel (Lot 64) 64.4 — changement de manifest parent externe (FromManifest) : resync                                                                                            
00:18 +66: SurfaceStudioPanel (Lot 64) 64.4 — changement de manifest parent externe (FromManifest) : resync                                                                                            
00:18 +67: SurfaceStudioPanel (Lot 64) 64.4 — changement de manifest parent externe (FromManifest) : resync                                                                                            
00:18 +67: All tests passed!                                                                                                                                                                           

```

### 3) Suite `test/surface_studio` (groupée)

**Commande** : `cd packages/map_editor && flutter test test/surface_studio`

**Dernière ligne** (ligne de synthèse exacte) :

`00:18 +258: All tests passed!`

*La sortie complète du runner occupe un flux monoligne d’environ 61801 caractères ; le corps intégral est recopié ci-dessous sans retrait de caractère.*

```

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart                                                               
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart                                                               
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart                                                               
00:02 +0: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_summary_test.dart: résumé none + hint                                                   
00:02 +1: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart: ... (Lot 59) 1. titre Inspecteur Surface                           
00:02 +2: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_selection_inspector_test.dart: ... (Lot 59) 1. titre Inspecteur Surface                           
00:02 +3: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1               
00:03 +4: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1               
00:03 +5: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1               
00:03 +6: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1               
00:03 +7: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1               
00:03 +8: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1               
00:03 +9: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1               
00:03 +10: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +11: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +12: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +13: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +14: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +15: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +16: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +17: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +18: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +19: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +20: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +21: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +22: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +23: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +24: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +25: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +26: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +27: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +28: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +29: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +30: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +31: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +32: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +33: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +34: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) titre, brouillon local, défauts 32/1/1              
00:03 +35: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +36: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +37: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +38: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +39: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 1. title Surface Studio is visible                  
00:03 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) taille tuile x non entier: erreur                   
00:04 +40: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) taille tuile x non entier: erreur                   
00:04 +41: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +42: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +43: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_preset_detail_view_test.dart: SurfaceStudioPresetDetailView (Lot 57) 23. title Presets Surface   
00:04 +44: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +45: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +46: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +47: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +48: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +49: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +50: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +51: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +52: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +53: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +54: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) hauteur / colonnes / lignes <= 0: erreur            
00:04 +55: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +56: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +57: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +58: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +59: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +60: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +61: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +62: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +63: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +64: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +65: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +66: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +67: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +68: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +69: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +70: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +71: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:04 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +72: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +73: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +74: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +75: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +76: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +77: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +78: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +79: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +80: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +81: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +82: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +83: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +84: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +85: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +86: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +87: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) entry title Surface Studio is visible in explorer  
00:05 +88: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) sélection animation: brouillon stable + note        
00:05 +89: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) sélection animation: brouillon stable + note        
00:05 +90: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 10. future action label import visible (pas Créer un atlas)        
00:05 +91: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 10. future action label import visible (pas Créer un atlas)        
00:05 +92: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 10. future action label import visible (pas Créer un atlas)        
00:05 +93: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 10. future action label import visible (pas Créer un atlas)        
00:05 +94: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 10. future action label import visible (pas Créer un atlas)        
00:05 +95: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 10. future action label import visible (pas Créer un atlas)        
00:05 +96: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:05 +97: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:05 +98: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:05 +99: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) subtitle mentions animated surfaces (Surfaces animées)   
00:05 +100: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) pas de libellés d’action dangereux                 
00:05 +101: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... (Lot 60) pas de libellés d’action dangereux                 
00:05 +102: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 11. future import action disabled (onPressed null) 
00:05 +103: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 11. future import action disabled (onPressed null) 
00:05 +104: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 11. future import action disabled (onPressed null) 
00:05 +105: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 11. future import action disabled (onPressed null) 
00:05 +106: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface       
00:05 +107: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface       
00:05 +108: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface       
00:05 +109: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface       
00:05 +110: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface       
00:05 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface       
00:06 +111: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_detail_view_test.dart: SurfaceStudioAtlasDetailView (Lot 56) 1. title Atlas Surface       
00:06 +112: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +113: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +114: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +115: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +116: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +117: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +118: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +119: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +120: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +121: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +122: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +123: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +124: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +125: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +126: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +127: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +128: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +129: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +130: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +131: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +132: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +133: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +134: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +135: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +136: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +137: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +138: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +139: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +140: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) tap entry opens center panel with Lecture seule   
00:06 +141: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                       
00:06 +142: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                       
00:06 +143: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                       
00:06 +144: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                       
00:06 +145: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                       
00:06 +146: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                       
00:06 +147: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                       
00:07 +147: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_animation_detail_view_test.dart: ... (Lot 57) 1. title Animations Surface                       
00:07 +148: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... depuis sélection: même id = doublon; nouvel id = ajout      
00:07 +149: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... depuis sélection: même id = doublon; nouvel id = ajout      
00:07 +150: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... depuis sélection: même id = doublon; nouvel id = ajout      
00:07 +151: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_atlas_authoring_prep_test.dart: ... depuis sélection: même id = doublon; nouvel id = ajout      
00:07 +152: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +153: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +154: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +155: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +156: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +157: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +158: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +159: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +160: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... 53) EditorCanvasHost builds SurfaceStudioPanel in surface mode   
00:07 +161: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 20. displayed counts match read model summary      
00:07 +162: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 20. displayed counts match read model summary      
00:07 +163: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +164: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +165: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +166: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +167: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +168: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +169: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +170: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +171: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +172: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +173: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +174: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +175: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +176: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +177: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) works without an active map (no map required)     
00:07 +178: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 22. panel shows catalog browser for minimal catalog
00:08 +178: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 22. panel shows catalog browser for minimal catalog
00:08 +179: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                
00:08 +180: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                
00:08 +181: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                
00:08 +182: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 1. browser shows title Catalogue Surface                
00:08 +183: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... actions désactivées; TextField seulement brouillon Lot 60        
00:08 +184: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... actions désactivées; TextField seulement brouillon Lot 60        
00:08 +185: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... actions désactivées; TextField seulement brouillon Lot 60        
00:08 +186: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... actions désactivées; TextField seulement brouillon Lot 60        
00:08 +187: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... actions désactivées; TextField seulement brouillon Lot 60        
00:08 +188: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 27. Lot 55 — browser and diagnostics cohabit (minimal cat)        
00:08 +189: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_catalog_browser_test.dart: ... (Lot 54) 5. minimal catalog: atlas details (736-tile grid)       
00:08 +190: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:08 +191: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:08 +192: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:08 +193: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:08 +194: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:08 +195: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:08 +196: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:08 +197: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: Surface Studio workspace entry (Lot 53) no Surface save button labels
00:08 +198: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 58.21 — Aucune sélection au départ (catalogue minimal)            
00:08 +199: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 58.21 — Aucune sélection au départ (catalogue minimal)            
00:08 +200: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:08 +201: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:08 +202: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:09 +202: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:09 +203: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:09 +204: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:09 +205: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:09 +206: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:09 +207: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:09 +208: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... (Lot 53) Lot 59 — Inspecteur Surface visible en mode workspace   
00:09 +209: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 58.22 — sélection atlas après tap                  
00:09 +210: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 58.22 — sélection atlas après tap                  
00:09 +211: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 58.22 — sélection atlas après tap                  
00:09 +212: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 58.22 — sélection atlas après tap                  
00:09 +213: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:09 +214: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:09 +215: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:09 +216: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:09 +217: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:09 +218: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:09 +219: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... entry (Lot 53) no internal type names in visible shell copy      
00:09 +220: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 58.23 — sélection animation après tap              
00:09 +221: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... préparer sauvegarde : manifest en mémoire (notifier) sans disque 
00:09 +222: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... préparer sauvegarde : manifest en mémoire (notifier) sans disque 
00:09 +223: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... préparer sauvegarde : manifest en mémoire (notifier) sans disque 
00:10 +223: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... préparer sauvegarde : manifest en mémoire (notifier) sans disque 
00:10 +224: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... préparer sauvegarde : manifest en mémoire (notifier) sans disque 
00:10 +225: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_workspace_entry_test.dart: ... préparer sauvegarde : manifest en mémoire (notifier) sans disque 
00:10 +226: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 58.28 — pas de libellés édition/save actifs        
00:10 +227: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 58.28 — pas de libellés édition/save actifs        
00:10 +227: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.20 — inspecteur none au départ                  
00:10 +228: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.20 — inspecteur none au départ                  
00:10 +228: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.21 — inspecteur atlas après tap                 
00:10 +229: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.21 — inspecteur atlas après tap                 
00:10 +229: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.22 — inspecteur animation après tap             
00:10 +230: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.22 — inspecteur animation après tap             
00:10 +230: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.23 — inspecteur preset après tap                
00:10 +231: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.23 — inspecteur preset après tap                
00:10 +231: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 59.24 — changement de sélection met l’inspecteur à jour           
00:11 +231: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 59.24 — changement de sélection met l’inspecteur à jour           
00:11 +232: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 59.24 — changement de sélection met l’inspecteur à jour           
00:11 +232: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.25 — inspecteur ne mute pas le manifest         
00:11 +233: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.25 — inspecteur ne mute pas le manifest         
00:11 +233: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 52) 59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)   
00:11 +234: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 52) 59.26 — inspecteur read-only : aucun TextField (Lot 60 brouillon ok)   
00:11 +234: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.27 — pas de libellés édition/save (Lot 59)      
00:11 +235: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 59.27 — pas de libellés édition/save (Lot 59)      
00:11 +235: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump            
00:11 +236: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 30. Lot 55 — surfaceCatalog unchanged after panel pump            
00:11 +236: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 60.1 — Préparation atlas (brouillon) visible       
00:11 +237: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 60.1 — Préparation atlas (brouillon) visible       
00:11 +237: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 61.1 — action création atlas dans le catalogue de travail         
00:11 +238: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 61.1 — action création atlas dans le catalogue de travail         
00:11 +238: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, inspecteur
00:12 +238: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, inspecteur
00:12 +239: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 61.2 — créer atlas (catalogue vide) : compteur atlas 1, browser, inspecteur
00:12 +239: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 52) 61.3 — créer second atlas : compteur 2, animations/presets inchangés   
00:12 +240: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 52) 61.3 — créer second atlas : compteur 2, animations/presets inchangés   
00:12 +240: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 62.0 — pas de dirty au départ (vide + minimal)     
00:12 +241: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 62.0 — pas de dirty au départ (vide + minimal)     
00:12 +241: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 62.1 — dirty après création locale                 
00:12 +242: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 62.1 — dirty après création locale                 
00:12 +242: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off   
00:13 +242: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off   
00:13 +243: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 62.2 — reset depuis catalogue vide : compteur 0, atlas absent, dirty off   
00:13 +243: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 62.3 — reset depuis minimal : revient à Water, Grass absent, 1/1/1
00:13 +244: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 62.3 — reset depuis minimal : revient à Water, Grass absent, 1/1/1
00:13 +244: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 62.4 — A puis B puis reset (source vide)           
00:14 +244: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 62.4 — A puis B puis reset (source vide)           
00:14 +245: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 62.4 — A puis B puis reset (source vide)           
00:14 +245: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 62.5 — readModel parent change : resync, dirty off, X absent      
00:14 +246: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 62.5 — readModel parent change : resync, dirty off, X absent      
00:14 +246: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 62.6 — pas d’action fantôme Créer un atlas, vraie action présente 
00:14 +247: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 52) 62.6 — pas d’action fantôme Créer un atlas, vraie action présente 
00:14 +247: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 62.7 — no save flow libellés interdits             
00:14 +248: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 52) 62.7 — no save flow libellés interdits             
00:14 +248: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 63) 63.1 — sans modification : pas d’action préparation, callback jamais   
00:15 +248: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 63) 63.1 — sans modification : pas d’action préparation, callback jamais   
00:15 +249: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 63) 63.1 — sans modification : pas d’action préparation, callback jamais   
00:15 +249: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... — dirty + callback : action, un appel, catalogue complet, dirty et accusé  
00:15 +250: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... — dirty + callback : action, un appel, catalogue complet, dirty et accusé  
00:15 +250: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 63) 63.3 — sans callback : stable, message not connected, pas de bouton    
00:15 +251: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 63) 63.3 — sans callback : stable, message not connected, pas de bouton    
00:15 +251: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 63) 63.4 — resync parent : dirty off, atlas source, pas d’accusé      
00:16 +251: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 63) 63.4 — resync parent : dirty off, atlas source, pas d’accusé      
00:16 +252: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 63) 63.4 — resync parent : dirty off, atlas source, pas d’accusé      
00:16 +252: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 63) 63.5 — reset après préparation : clean, accusé nettoyé, vide      
00:16 +253: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 63) 63.5 — reset après préparation : clean, accusé nettoyé, vide      
00:16 +253: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 63) 63.6 — A puis B puis préparation : ordre des atlas 
00:17 +253: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 63) 63.6 — A puis B puis préparation : ordre des atlas 
00:17 +254: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: SurfaceStudioPanel (Lot 63) 63.6 — A puis B puis préparation : ordre des atlas 
00:17 +254: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 64) 64.1 — FromManifest : préparer sauvegarde, manifest mémoire, dirty off 
00:17 +255: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 64) 64.1 — FromManifest : préparer sauvegarde, manifest mémoire, dirty off 
00:17 +255: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 64) 64.2 — onProjectManifestChanged une fois, atlas dans manifest     
00:17 +256: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 64) 64.2 — onProjectManifestChanged une fois, atlas dans manifest     
00:17 +256: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 64) 64.3 — onProjectManifestChanged absent : pas d’exception          
00:18 +256: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 64) 64.3 — onProjectManifestChanged absent : pas d’exception          
00:18 +257: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... (Lot 64) 64.3 — onProjectManifestChanged absent : pas d’exception          
00:18 +257: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 64) 64.4 — changement de manifest parent externe (FromManifest) : resync   
00:18 +258: /Users/karim/Project/pokemonProject/packages/map_editor/test/surface_studio/surface_studio_panel_test.dart: ... 64) 64.4 — changement de manifest parent externe (FromManifest) : resync   
00:18 +258: All tests passed!                                                                                                                                                                          

```

### 4) `map_core` — `test/surface_studio_read_model_test.dart`

**Commande** : `cd packages/map_core && dart test test/surface_studio_read_model_test.dart`

**Sortie intégrale** :

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

## Vérification fichiers temporaires

**Commande** : `find . -type f \( -name '_gen_*.py' -o -name 'build_*.py' -o -name '*.tmp' \) -print` (depuis la racine du dépôt)

**Sortie exacte** :

```
Sortie : <vide>
```

## Git status final

*Après enregistrement de ce rapport sous `reports/surface/surface_engine_lot_64_bis_analyze_evidence_coverage.md` et avant toute opération `git` d’écriture.*

**Commande** : `git status --short --untracked-files=all`  
*À exécuter post-écriture : voir exécution de fin de script.*

**Commande** : `git diff --stat`  
*Idem.*

## Analyse

**Confirmé** :

- L’analyse ciblée complète inclut en arguments explicites `lib/src/ui/canvas/editor_canvas_host.dart` et `lib/src/features/editor/state/editor_notifier.dart` ; l’analyse se termine sans problème.
- L’analyse couvre toujours `lib/src/features/surface_studio` (répertoire) et `test/surface_studio` (répertoire).
- Aucun code n’est modifié par le 64-bis.
- Le statut de travail reste borné au dépôt attendu (rapports seulement une fois le fichier 64-bis ajouté).

**Non prouvé** : Sortie : <vide>

**Exclu** : modification de `map_core` ; persistance disque ; nouveau provider ; correction de tests ou d’UI dans ce lot.

## Impact sur le Lot 64

- **Réserve d’analyse** : levée : la preuve 64-bis attache une commande `flutter analyze` qui nomme explicitement les deux chemins `lib/.../editor_canvas_host.dart` et `lib/.../editor_notifier.dart` et montre un passage sans issue.
- **Code et tests du Lot 64** : non remis en cause par ce 64-bis.
- Aucune correction de feature : conformément au contrat, aucun patch appliqué.

## Recommandation

- **Lot 64** : peut être fermé au regard de la couverture d’analyse documentaire complétée par ce 64-bis.
- **Lot 65** : peut être préparé (aucun blocage issu de ce 64-bis).

## Fichiers créés

- `reports/surface/surface_engine_lot_64_bis_analyze_evidence_coverage.md` (ce fichier)

## Fichiers modifiés

- Sortie : <vide> (hors l’ajout de ce rapport, aucun fichier de code modifié par le 64-bis)

## Fichiers supprimés

- Sortie : <vide>

## Périmètre explicitement non touché (64-bis)

- aucun code modifié par le 64-bis
- rapport Lot 64 non modifié
- map_core non modifié
- ProjectManifest modèle non modifié
- ProjectManifest generated non modifiés
- generated files non modifiés
- build_runner non lancé
- fixtures Surface JSON non modifiées
- aucun codec Surface modifié
- aucun provider Riverpod créé
- aucun repository/service créé
- aucune sauvegarde disque créée
- aucune écriture `project.json`
- aucune suppression/édition d’atlas
- aucune animation/preset modifié
- aucun runtime/gameplay/battle modifié
- aucun painter map
- aucun `SurfaceLayer`
- aucun import d’atlas vertical
- aucun `clearProjectManifestSurfaceCatalog` ajouté
- aucune modification des opérations `map_core` existantes

## Auto-review

- Est-ce que du code a été modifié par le 64-bis ? **Non.**
- Est-ce que le rapport Lot 64 a été modifié ? **Non.**
- Est-ce qu’une commande Git d’écriture a été utilisée ? **Non.**
- Est-ce que l’analyse couvre maintenant `editor_canvas_host.dart` ? **Oui** (argument explicite + succès).
- Est-ce que l’analyse couvre maintenant `editor_notifier.dart` ? **Oui** (idem).
- Est-ce que l’analyse couvre toujours `surface_studio` sous `lib` et `test` ? **Oui** (répertoires passés en argument).
- Est-ce que les tests ciblés relancés passent ? **Oui** (voir sections ci-dessus et lignes `All tests passed!`).
- Est-ce que le status actuel est fourni ? **Oui.**
- Est-ce que le status final est fourni ? **Oui** (bloc exécuté post-écriture, voir fin).
- Est-ce que les fichiers modifiés actuels correspondent au Lot 64 ? **Oui** (aucun diff local : Lot 64 intégré en commit) ; seul l’`??` du rapport 64-bis s’ajoute.
- Est-ce que le Lot 64 peut être fermé après ce 64-bis ? **Oui.**
- Est-ce que le Lot 65 peut démarrer ? **Oui** (côté preuve 64/64-bis).

## Critique du prompt

- **Diff `git` / `dev/null` de ce rapport** : un document qui inclut l’intégralité de sa propre sortie génère une limite récursive ; ici, le contenu de ce livrable est le texte de ce même fichier enregistré sur disque ; toute vérification repose sur la relecture octet-à-octet du fichier `reports/surface/surface_engine_lot_64_bis_analyze_evidence_coverage.md` produit, sans qu’il soit nécessaire de dupliquer le fichier dans le fichier.

---

## Evidence Pack (synthèse des numéros)

- Commandes d’audit : voir les blocs de sortie exacts ci-dessus.
- `git status` / `git diff` vides : arbre propre = pas de reprise de travail en cours sur les chemins Lot 64.
- `flutter analyze` : sortie intégrale.
- Tests : sorties intégrales (workspace, panel, suite, map_core) dans les blocs.
- Aucune commande `git` d’écriture.
- Fichiers temporaires : aucun.
- Vérification mojibake : effectuée en ne recopiant pas les séquences corrompues interdites dans le corps du texte.

### Git status final (exécution après enregistrement de ce rapport)

**Commande** : `git status --short --untracked-files=all`

```
?? reports/surface/surface_engine_lot_64_bis_analyze_evidence_coverage.md
```

**Commande** : `git diff --stat`

```
```
