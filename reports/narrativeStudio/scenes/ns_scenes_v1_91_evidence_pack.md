# NS-SCENES-V1-91 — Evidence Pack

## 1. Gate 0 complet

Commande :
```bash
pwd && git branch --show-current && git status --short --untracked-files=all && git diff --stat && git diff --name-only && git log --oneline -n 15
```

Sortie capturee :
```text
/Users/karim/Project/pokemonProject
main
3e767d80 feat(narrative): auto-commit changes
3a3689df feat(narrative): auto-commit changes
12e52f7a update selbrume
1ac4186f update selbrume
a085d128 feat(narrative): auto-commit changes
103cc837 feat(narrative): auto-commit changes
fd10cce7 feat(narrative): auto-commit changes
c730bef3 feat(narrative): auto-commit changes
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df6 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
1b311e81 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-29-81)
122fe0c7 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-81-BIS)
```

`git status`, `git diff --stat` et `git diff --name-only` etaient vides au Gate 0.

## 2. Liste des fichiers lus

- `AGENTS.md`
- `skills/README.md`
- `skills/test-driven-development/SKILL.md`
- `skills/writing-plans/SKILL.md`
- `skills/subagent-driven-development/SKILL.md`
- `skills/verification-before-completion/SKILL.md`
- `packages/map_core/lib/src/models/cinematic_asset.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/project_trainer.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_event_definition.dart`
- `packages/map_core/lib/src/models/map_entity_payloads.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/models/geometry.dart`
- `packages/map_core/lib/src/authoring/cinematic_authoring_operations.dart`
- `packages/map_core/lib/src/read_models/cinematic_stage_map_source_catalog.dart`
- `packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart`
- `packages/map_core/test/cinematic_stage_map_source_catalog_test.dart`
- `packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 3. Notes de sub-agents / passes specialisees

- A / Core Model Design : style map_core confirme (`@immutable`, `final class`, listes unmodifiable, builder pur), sources canoniques et risque principal de confondre read model et renderer.
- B / Actor Sources : `requiredActors.actorId` est canonique ; ne jamais resoudre depuis `CinematicActorRef.entityId`; orphelins et doublons a diagnostiquer en first-wins.
- C / Position : `fromMapEntity` lit `CinematicActorBinding.mapEntityId -> MapData.entities.pos`; `fromMovementTarget` lit `movementTargetBindings` vers entity/event; `abstractPoint`, `target_center`, `target_exit` ne portent aucune coordonnee implicite.
- D / Appearance : player via `ProjectSettings.defaultPlayerCharacterId`, mapEntity via `MapEntityNpcData.characterId` puis trainer fallback, cinematicOnly via `actorAppearanceBindings`; tileset/idle purement metadata.
- E / Direction : premier `actorFace` lu en data-only via `metadata['actor.direction']`; mapping up/down/left/right vers north/south/west/east; `actorMove` ignore.
- F / Tests / Anti-scope : tests read model compacts + checks anti imports/runtime/playback/renderer/fake position ; evidence pack avec code complet.

## 4. RED test output

Commande :
```bash
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Sortie RED :
```text
00:00 +0: loading test/cinematic_actor_display_preview_model_test.dart
00:00 +0 -1: loading test/cinematic_actor_display_preview_model_test.dart [E]
Failed to load "test/cinematic_actor_display_preview_model_test.dart":
test/cinematic_actor_display_preview_model_test.dart:725:1: Error: Type 'CinematicActorDisplayPreviewModel' not found.
CinematicActorDisplayPreviewModel _singleActorModel({
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:11:23: Error: Method not found: 'buildCinematicActorDisplayPreviewModel'.
        final model = buildCinematicActorDisplayPreviewModel(
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:92:38: Error: Undefined name 'CinematicActorDisplayBindingStatus'.
        expect(player.bindingStatus, CinematicActorDisplayBindingStatus.player);
                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:93:40: Error: Undefined name 'CinematicActorPreviewPositionStatus'.
        expect(player.position.status, CinematicActorPreviewPositionStatus.resolved);
                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:98:11: Error: Undefined name 'CinematicActorPreviewAppearanceStatus'.
          CinematicActorPreviewAppearanceStatus.spriteReady,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:103:37: Error: Undefined name 'CinematicActorDisplayBindingStatus'.
        expect(guard.bindingStatus, CinematicActorDisplayBindingStatus.mapEntity);
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:107:33: Error: Undefined name 'CinematicActorPreviewDirection'.
        expect(guard.direction, CinematicActorPreviewDirection.east);
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:112:11: Error: Undefined name 'CinematicActorDisplayBindingStatus'.
          CinematicActorDisplayBindingStatus.cinematicOnly,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:117:33: Error: Undefined name 'CinematicActorPreviewRenderHint'.
        expect(liza.renderHint, CinematicActorPreviewRenderHint.sprite);
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:120:39: Error: Undefined name 'CinematicActorDisplayBindingStatus'.
        expect(unbound.bindingStatus, CinematicActorDisplayBindingStatus.unbound);
                                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:121:41: Error: Undefined name 'CinematicActorPreviewPositionStatus'.
        expect(unbound.position.status, CinematicActorPreviewPositionStatus.unbound);
                                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:124:11: Error: Undefined name 'CinematicActorPreviewAppearanceStatus'.
          CinematicActorPreviewAppearanceStatus.notRequired,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:126:36: Error: Undefined name 'CinematicActorPreviewRenderHint'.
        expect(unbound.renderHint, CinematicActorPreviewRenderHint.hidden);
                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:132:21: Error: Method not found: 'buildCinematicActorDisplayPreviewModel'.
      final model = buildCinematicActorDisplayPreviewModel(
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:139:28: Error: Undefined name 'CinematicActorDisplayPreviewStatus'.
      expect(model.status, CinematicActorDisplayPreviewStatus.noActors);
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:143:18: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
        contains(CinematicActorDisplayPreviewDiagnosticCode.actorDisplayNoActors),
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:148:21: Error: Method not found: 'buildCinematicActorDisplayPreviewModel'.
      final model = buildCinematicActorDisplayPreviewModel(
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:156:35: Error: Undefined name 'CinematicActorDisplayBindingStatus'.
      expect(actor.bindingStatus, CinematicActorDisplayBindingStatus.missing);
                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:160:11: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
          CinematicActorDisplayPreviewDiagnosticCode.actorDisplayMissingBinding,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:175:35: Error: Undefined name 'CinematicActorDisplayBindingStatus'.
      expect(actor.bindingStatus, CinematicActorDisplayBindingStatus.unbound);
                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:177:32: Error: Undefined name 'CinematicActorPreviewRenderHint'.
      expect(actor.renderHint, CinematicActorPreviewRenderHint.hidden);
                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:180:18: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
        contains(CinematicActorDisplayPreviewDiagnosticCode.actorDisplayUnboundActor),
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:199:31: Error: Undefined name 'CinematicActorPreviewPositionStatus'.
      expect(position.status, CinematicActorPreviewPositionStatus.resolved);
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:220:37: Error: Undefined name 'CinematicActorPreviewPositionStatus'.
      expect(actor.position.status, CinematicActorPreviewPositionStatus.missingSource);
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:224:11: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
          CinematicActorDisplayPreviewDiagnosticCode.actorDisplayMissingMapEntity,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:256:33: Error: Undefined name 'CinematicActorPreviewAppearanceStatus'.
      expect(appearance.status, CinematicActorPreviewAppearanceStatus.spriteReady);
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:273:9: Error: Undefined name 'CinematicActorPreviewAppearanceStatus'.
        CinematicActorPreviewAppearanceStatus.placeholderOnly,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:278:11: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
          CinematicActorDisplayPreviewDiagnosticCode.actorDisplayMissingAppearance,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:299:9: Error: Undefined name 'CinematicActorPreviewAppearanceStatus'.
        CinematicActorPreviewAppearanceStatus.missingCharacter,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:304:11: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
          CinematicActorDisplayPreviewDiagnosticCode.actorDisplayUnknownCharacter,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:324:9: Error: Undefined name 'CinematicActorPreviewAppearanceStatus'.
        CinematicActorPreviewAppearanceStatus.missingTileset,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:329:11: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
          CinematicActorDisplayPreviewDiagnosticCode
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:350:9: Error: Undefined name 'CinematicActorPreviewAppearanceStatus'.
        CinematicActorPreviewAppearanceStatus.missingIdleAnimation,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:355:11: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
          CinematicActorDisplayPreviewDiagnosticCode
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:384:33: Error: Undefined name 'CinematicActorPreviewAppearanceStatus'.
      expect(appearance.status, CinematicActorPreviewAppearanceStatus.spriteReady);
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:401:9: Error: Undefined name 'CinematicActorPreviewAppearanceStatus'.
        CinematicActorPreviewAppearanceStatus.placeholderOnly,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:403:32: Error: Undefined name 'CinematicActorPreviewRenderHint'.
      expect(actor.renderHint, CinematicActorPreviewRenderHint.placeholder);
                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:429:31: Error: Undefined name 'CinematicActorPreviewPositionStatus'.
      expect(position.status, CinematicActorPreviewPositionStatus.resolved);
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:457:31: Error: Undefined name 'CinematicActorPreviewPositionStatus'.
      expect(position.status, CinematicActorPreviewPositionStatus.resolved);
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:484:31: Error: Undefined name 'CinematicActorPreviewPositionStatus'.
      expect(position.status, CinematicActorPreviewPositionStatus.abstractOnly);
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:505:31: Error: Undefined name 'CinematicActorPreviewPositionStatus'.
      expect(position.status, CinematicActorPreviewPositionStatus.missingSource);
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:522:9: Error: Undefined name 'CinematicActorPreviewPositionStatus'.
        CinematicActorPreviewPositionStatus.missingInitialPlacement,
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:543:37: Error: Undefined name 'CinematicActorPreviewPositionStatus'.
      expect(actor.position.status, CinematicActorPreviewPositionStatus.outOfMapBounds);
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:547:11: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
          CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOutOfMapBounds,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:576:31: Error: Undefined name 'CinematicActorPreviewDirection'.
      expect(actor.direction, CinematicActorPreviewDirection.west);
                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:577:37: Error: Undefined name 'CinematicActorPreviewDirectionSource'.
      expect(actor.directionSource, CinematicActorPreviewDirectionSource.actorFace);
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:616:21: Error: Method not found: 'buildCinematicActorDisplayPreviewModel'.
      final model = buildCinematicActorDisplayPreviewModel(
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:635:18: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
        contains(CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOrphanBinding),
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:640:21: Error: Method not found: 'buildCinematicActorDisplayPreviewModel'.
      final model = buildCinematicActorDisplayPreviewModel(
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:660:11: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
          CinematicActorDisplayPreviewDiagnosticCode
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:667:21: Error: Method not found: 'buildCinematicActorDisplayPreviewModel'.
      final model = buildCinematicActorDisplayPreviewModel(
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:687:11: Error: Undefined name 'CinematicActorDisplayPreviewDiagnosticCode'.
          CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOrphanPlacement,
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
test/cinematic_actor_display_preview_model_test.dart:735:10: Error: Method not found: 'buildCinematicActorDisplayPreviewModel'.
  return buildCinematicActorDisplayPreviewModel(
         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
To run this test again: dart test test/cinematic_actor_display_preview_model_test.dart -p vm --plain-name 'loading test/cinematic_actor_display_preview_model_test.dart'
00:00 +0 -1: Some tests failed.
```

## 5. GREEN test output

### GREEN ciblé V1-91

Commande :
```bash
dart test --reporter=compact test/cinematic_actor_display_preview_model_test.dart
```

Code de sortie : `0`

Sortie :
```text

00:00 [32m+0[0m: [1m[90mloading test/cinematic_actor_display_preview_model_test.dart[0m[0m                                                                                                                                 
00:00 [32m+0[0m: CinematicActorDisplayPreviewModel builds actor display preview model for cinematic actors without rendering them[0m                                                                             
00:00 [32m+1[0m: CinematicActorDisplayPreviewModel builds actor display preview model for cinematic actors without rendering them[0m                                                                             
00:00 [32m+1[0m: CinematicActorDisplayPreviewModel returns no actors status when cinematic has no required actors[0m                                                                                             
00:00 [32m+2[0m: CinematicActorDisplayPreviewModel returns no actors status when cinematic has no required actors[0m                                                                                             
00:00 [32m+2[0m: CinematicActorDisplayPreviewModel reports missing binding for actor without stage binding[0m                                                                                                    
00:00 [32m+3[0m: CinematicActorDisplayPreviewModel reports missing binding for actor without stage binding[0m                                                                                                    
00:00 [32m+3[0m: CinematicActorDisplayPreviewModel marks unbound actor as non renderable[0m                                                                                                                      
00:00 [32m+4[0m: CinematicActorDisplayPreviewModel marks unbound actor as non renderable[0m                                                                                                                      
00:00 [32m+4[0m: CinematicActorDisplayPreviewModel resolves map entity actor position from map data entity[0m                                                                                                    
00:00 [32m+5[0m: CinematicActorDisplayPreviewModel resolves map entity actor position from map data entity[0m                                                                                                    
00:00 [32m+5[0m: CinematicActorDisplayPreviewModel reports missing map entity when binding points to unknown entity[0m                                                                                           
00:00 [32m+6[0m: CinematicActorDisplayPreviewModel reports missing map entity when binding points to unknown entity[0m                                                                                           
00:00 [32m+6[0m: CinematicActorDisplayPreviewModel resolves cinematic only actor appearance from character library binding[0m                                                                                    
00:00 [32m+7[0m: CinematicActorDisplayPreviewModel resolves cinematic only actor appearance from character library binding[0m                                                                                    
00:00 [32m+7[0m: CinematicActorDisplayPreviewModel reports missing appearance binding for cinematic only actor[0m                                                                                                
00:00 [32m+8[0m: CinematicActorDisplayPreviewModel reports missing appearance binding for cinematic only actor[0m                                                                                                
00:00 [32m+8[0m: CinematicActorDisplayPreviewModel reports unknown character reference[0m                                                                                                                        
00:00 [32m+9[0m: CinematicActorDisplayPreviewModel reports unknown character reference[0m                                                                                                                        
00:00 [32m+9[0m: CinematicActorDisplayPreviewModel reports character missing tileset[0m                                                                                                                          
00:00 [32m+10[0m: CinematicActorDisplayPreviewModel reports character missing tileset[0m                                                                                                                         
00:00 [32m+10[0m: CinematicActorDisplayPreviewModel reports character missing idle animation[0m                                                                                                                  
00:00 [32m+11[0m: CinematicActorDisplayPreviewModel reports character missing idle animation[0m                                                                                                                  
00:00 [32m+11[0m: CinematicActorDisplayPreviewModel uses player default character when available without GameState[0m                                                                                            
00:00 [32m+12[0m: CinematicActorDisplayPreviewModel uses player default character when available without GameState[0m                                                                                            
00:00 [32m+12[0m: CinematicActorDisplayPreviewModel falls back to placeholder for player without default character[0m                                                                                            
00:00 [32m+13[0m: CinematicActorDisplayPreviewModel falls back to placeholder for player without default character[0m                                                                                            
00:00 [32m+13[0m: CinematicActorDisplayPreviewModel resolves from movement target bound to map entity[0m                                                                                                         
00:00 [32m+14[0m: CinematicActorDisplayPreviewModel resolves from movement target bound to map entity[0m                                                                                                         
00:00 [32m+14[0m: CinematicActorDisplayPreviewModel resolves from movement target bound to map event when position exists[0m                                                                                     
00:00 [32m+15[0m: CinematicActorDisplayPreviewModel resolves from movement target bound to map event when position exists[0m                                                                                     
00:00 [32m+15[0m: CinematicActorDisplayPreviewModel does not resolve abstract movement target to fake coordinates[0m                                                                                             
00:00 [32m+16[0m: CinematicActorDisplayPreviewModel does not resolve abstract movement target to fake coordinates[0m                                                                                             
00:00 [32m+16[0m: CinematicActorDisplayPreviewModel does not treat target_center as map coordinates[0m                                                                                                           
00:00 [32m+17[0m: CinematicActorDisplayPreviewModel does not treat target_center as map coordinates[0m                                                                                                           
00:00 [32m+17[0m: CinematicActorDisplayPreviewModel does not invent center map fallback for missing placement[0m                                                                                                 
00:00 [32m+18[0m: CinematicActorDisplayPreviewModel does not invent center map fallback for missing placement[0m                                                                                                 
00:00 [32m+18[0m: CinematicActorDisplayPreviewModel reports out of bounds position[0m                                                                                                                            
00:00 [32m+19[0m: CinematicActorDisplayPreviewModel reports out of bounds position[0m                                                                                                                            
00:00 [32m+19[0m: CinematicActorDisplayPreviewModel uses actorFace as static direction hint without playback[0m                                                                                                  
00:00 [32m+20[0m: CinematicActorDisplayPreviewModel uses actorFace as static direction hint without playback[0m                                                                                                  
00:00 [32m+20[0m: CinematicActorDisplayPreviewModel ignores actorMove for initial position[0m                                                                                                                    
00:00 [32m+21[0m: CinematicActorDisplayPreviewModel ignores actorMove for initial position[0m                                                                                                                    
00:00 [32m+21[0m: CinematicActorDisplayPreviewModel reports orphan actor binding[0m                                                                                                                              
00:00 [32m+22[0m: CinematicActorDisplayPreviewModel reports orphan actor binding[0m                                                                                                                              
00:00 [32m+22[0m: CinematicActorDisplayPreviewModel reports orphan actor appearance binding[0m                                                                                                                   
00:00 [32m+23[0m: CinematicActorDisplayPreviewModel reports orphan actor appearance binding[0m                                                                                                                   
00:00 [32m+23[0m: CinematicActorDisplayPreviewModel reports orphan initial placement[0m                                                                                                                          
00:00 [32m+24[0m: CinematicActorDisplayPreviewModel reports orphan initial placement[0m                                                                                                                          
00:00 [32m+24[0m: CinematicActorDisplayPreviewModel keeps model pure without Flutter Flame runtime imports[0m                                                                                                    
00:00 [32m+25[0m: CinematicActorDisplayPreviewModel keeps model pure without Flutter Flame runtime imports[0m                                                                                                    
00:00 [32m+25[0m: All tests passed![0m
```

### Regression backdrop

Commande :
```bash
dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
```

Code de sortie : `0`

Sortie :
```text

00:00 [32m+0[0m: [1m[90mloading test/cinematic_map_backdrop_preview_model_test.dart[0m[0m                                                                                                                                  
00:00 [32m+0[0m: CinematicMapBackdropPreviewModel builds available cinematic map backdrop preview model from project map and map data[0m                                                                         
00:00 [32m+1[0m: CinematicMapBackdropPreviewModel builds available cinematic map backdrop preview model from project map and map data[0m                                                                         
00:00 [32m+1[0m: CinematicMapBackdropPreviewModel returns backdrop disabled when backdrop mode is none[0m                                                                                                        
00:00 [32m+2[0m: CinematicMapBackdropPreviewModel returns backdrop disabled when backdrop mode is none[0m                                                                                                        
00:00 [32m+2[0m: CinematicMapBackdropPreviewModel returns missing stage map when project map backdrop has no map id[0m                                                                                           
00:00 [32m+3[0m: CinematicMapBackdropPreviewModel returns missing stage map when project map backdrop has no map id[0m                                                                                           
00:00 [32m+3[0m: CinematicMapBackdropPreviewModel returns stage map unknown when map id has no project map entry[0m                                                                                              
00:00 [32m+4[0m: CinematicMapBackdropPreviewModel returns stage map unknown when map id has no project map entry[0m                                                                                              
00:00 [32m+4[0m: CinematicMapBackdropPreviewModel returns map data unavailable when stage map has no map data[0m                                                                                                 
00:00 [32m+5[0m: CinematicMapBackdropPreviewModel returns map data unavailable when stage map has no map data[0m                                                                                                 
00:00 [32m+5[0m: CinematicMapBackdropPreviewModel returns map data mismatch when map data id differs from stage map[0m                                                                                           
00:00 [32m+6[0m: CinematicMapBackdropPreviewModel returns map data mismatch when map data id differs from stage map[0m                                                                                           
00:00 [32m+6[0m: CinematicMapBackdropPreviewModel returns tileset unavailable when tileset ids are provided and missing[0m                                                                                       
00:00 [32m+7[0m: CinematicMapBackdropPreviewModel returns tileset unavailable when tileset ids are provided and missing[0m                                                                                       
00:00 [32m+7[0m: CinematicMapBackdropPreviewModel does not diagnose tileset missing when available tilesets are not provided[0m                                                                                  
00:00 [32m+8[0m: CinematicMapBackdropPreviewModel does not diagnose tileset missing when available tilesets are not provided[0m                                                                                  
00:00 [32m+8[0m: CinematicMapBackdropPreviewModel projects visual layers from map data[0m                                                                                                                        
00:00 [32m+9[0m: CinematicMapBackdropPreviewModel projects visual layers from map data[0m                                                                                                                        
00:00 [32m+9[0m: CinematicMapBackdropPreviewModel builds visual primitives from positioned MapData layers[0m                                                                                                     
00:00 [32m+10[0m: CinematicMapBackdropPreviewModel builds visual primitives from positioned MapData layers[0m                                                                                                    
00:00 [32m+10[0m: CinematicMapBackdropPreviewModel builds object anchors only from placed element coordinates[0m                                                                                                 
00:00 [32m+11[0m: CinematicMapBackdropPreviewModel builds object anchors only from placed element coordinates[0m                                                                                                 
00:00 [32m+11[0m: CinematicMapBackdropPreviewModel falls back to layer summary when no spatial data is available[0m                                                                                              
00:00 [32m+12[0m: CinematicMapBackdropPreviewModel falls back to layer summary when no spatial data is available[0m                                                                                              
00:00 [32m+12[0m: CinematicMapBackdropPreviewModel does not create fake primitives when map data has no visual layers[0m                                                                                         
00:00 [32m+13[0m: CinematicMapBackdropPreviewModel does not create fake primitives when map data has no visual layers[0m                                                                                         
00:00 [32m+13[0m: CinematicMapBackdropPreviewModel excludes entities events triggers warps and gameplay zones from visual layers[0m                                                                              
00:00 [32m+14[0m: CinematicMapBackdropPreviewModel excludes entities events triggers warps and gameplay zones from visual layers[0m                                                                              
00:00 [32m+14[0m: CinematicMapBackdropPreviewModel builds human map label from project map entry[0m                                                                                                              
00:00 [32m+15[0m: CinematicMapBackdropPreviewModel builds human map label from project map entry[0m                                                                                                              
00:00 [32m+15[0m: CinematicMapBackdropPreviewModel falls back to map id when label is missing[0m                                                                                                                 
00:00 [32m+16[0m: CinematicMapBackdropPreviewModel falls back to map id when label is missing[0m                                                                                                                 
00:00 [32m+16[0m: CinematicMapBackdropPreviewModel builds size summary from map dimensions[0m                                                                                                                    
00:00 [32m+17[0m: CinematicMapBackdropPreviewModel builds size summary from map dimensions[0m                                                                                                                    
00:00 [32m+17[0m: CinematicMapBackdropPreviewModel builds viewport recommendation without Flutter or Flame[0m                                                                                                    
00:00 [32m+18[0m: CinematicMapBackdropPreviewModel builds viewport recommendation without Flutter or Flame[0m                                                                                                    
00:00 [32m+18[0m: CinematicMapBackdropPreviewModel does not require runtime state[0m                                                                                                                             
00:00 [32m+19[0m: CinematicMapBackdropPreviewModel does not require runtime state[0m                                                                                                                             
00:00 [32m+19[0m: All tests passed![0m
```

### Regression stage catalog

Commande :
```bash
dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
```

Code de sortie : `0`

Sortie :
```text

00:00 [32m+0[0m: [1m[90mloading test/cinematic_stage_map_source_catalog_test.dart[0m[0m                                                                                                                                    
00:00 [32m+0[0m: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data[0m                                                                                                  
00:00 [32m+1[0m: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data[0m                                                                                                  
00:00 [32m+1[0m: CinematicStageMapSourceCatalog returns missing stage map status without stage map[0m                                                                                                            
00:00 [32m+2[0m: CinematicStageMapSourceCatalog returns missing stage map status without stage map[0m                                                                                                            
00:00 [32m+2[0m: CinematicStageMapSourceCatalog returns unavailable status without map data[0m                                                                                                                   
00:00 [32m+3[0m: CinematicStageMapSourceCatalog returns unavailable status without map data[0m                                                                                                                   
00:00 [32m+3[0m: CinematicStageMapSourceCatalog returns map id mismatch status when map data does not match stage map[0m                                                                                         
00:00 [32m+4[0m: CinematicStageMapSourceCatalog returns map id mismatch status when map data does not match stage map[0m                                                                                         
00:00 [32m+4[0m: CinematicStageMapSourceCatalog uses entity id as fallback label only when no better label exists[0m                                                                                             
00:00 [32m+5[0m: CinematicStageMapSourceCatalog uses entity id as fallback label only when no better label exists[0m                                                                                             
00:00 [32m+5[0m: CinematicStageMapSourceCatalog uses event id as fallback label only when title is empty[0m                                                                                                      
00:00 [32m+6[0m: CinematicStageMapSourceCatalog uses event id as fallback label only when title is empty[0m                                                                                                      
00:00 [32m+6[0m: CinematicStageMapSourceCatalog handles empty entity and event lists[0m                                                                                                                          
00:00 [32m+7[0m: CinematicStageMapSourceCatalog handles empty entity and event lists[0m                                                                                                                          
00:00 [32m+7[0m: All tests passed![0m
```

### Regression cinematic asset

Commande :
```bash
dart test --reporter=compact test/cinematic_asset_test.dart
```

Code de sortie : `0`

Sortie :
```text

00:00 [32m+0[0m: [1m[90mloading test/cinematic_asset_test.dart[0m[0m                                                                                                                                                       
00:00 [32m+0[0m: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                                                             
00:00 [32m+1[0m: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                                                             
00:00 [32m+1[0m: CinematicAsset serializes cinematic stage context without duplicating map id[0m                                                                                                                 
00:00 [32m+2[0m: CinematicAsset serializes cinematic stage context without duplicating map id[0m                                                                                                                 
00:00 [32m+2[0m: CinematicAsset serializes cinematic actor appearance binding for cinematic only actor[0m                                                                                                        
00:00 [32m+3[0m: CinematicAsset serializes cinematic actor appearance binding for cinematic only actor[0m                                                                                                        
00:00 [32m+3[0m: CinematicAsset deserializes cinematic asset without actor appearance bindings[0m                                                                                                                
00:00 [32m+4[0m: CinematicAsset deserializes cinematic asset without actor appearance bindings[0m                                                                                                                
00:00 [32m+4[0m: CinematicAsset does not store character id inside actor binding[0m                                                                                                                              
00:00 [32m+5[0m: CinematicAsset does not store character id inside actor binding[0m                                                                                                                              
00:00 [32m+5[0m: CinematicAsset roundtrips actor appearance bindings in stage context[0m                                                                                                                         
00:00 [32m+6[0m: CinematicAsset roundtrips actor appearance bindings in stage context[0m                                                                                                                         
00:00 [32m+6[0m: CinematicAsset keeps actorAppearanceBindings empty by default[0m                                                                                                                                
00:00 [32m+7[0m: CinematicAsset keeps actorAppearanceBindings empty by default[0m                                                                                                                                
00:00 [32m+7[0m: CinematicAsset does not persist startMs or endMs for actor appearance binding[0m                                                                                                                
00:00 [32m+8[0m: CinematicAsset does not persist startMs or endMs for actor appearance binding[0m                                                                                                                
00:00 [32m+8[0m: CinematicAsset defaults missing movement targets to an empty list[0m                                                                                                                            
00:00 [32m+9[0m: CinematicAsset defaults missing movement targets to an empty list[0m                                                                                                                            
00:00 [32m+9[0m: CinematicAsset deserializes cinematic asset without stage context[0m                                                                                                                            
00:00 [32m+10[0m: CinematicAsset deserializes cinematic asset without stage context[0m                                                                                                                           
00:00 [32m+10[0m: CinematicAsset serializes all V0 stage context enum variants[0m                                                                                                                                
00:00 [32m+11[0m: CinematicAsset serializes all V0 stage context enum variants[0m                                                                                                                                
00:00 [32m+11[0m: CinematicAsset keeps timeline steps linear and rejects branch/gameplay step kinds[0m                                                                                                           
00:00 [32m+12[0m: CinematicAsset keeps timeline steps linear and rejects branch/gameplay step kinds[0m                                                                                                           
00:00 [32m+12[0m: CinematicAsset requires stable id and readable title[0m                                                                                                                                        
00:00 [32m+13[0m: CinematicAsset requires stable id and readable title[0m                                                                                                                                        
00:00 [32m+13[0m: CinematicAsset does not import Flutter, Flame, runtime, or editor packages[0m                                                                                                                  
00:00 [32m+14[0m: CinematicAsset does not import Flutter, Flame, runtime, or editor packages[0m                                                                                                                  
00:00 [32m+14[0m: All tests passed![0m
```

### Regression manifest cinematics

Commande :
```bash
dart test --reporter=compact test/project_manifest_cinematics_test.dart
```

Code de sortie : `0`

Sortie :
```text

00:00 [32m+0[0m: [1m[90mloading test/project_manifest_cinematics_test.dart[0m[0m                                                                                                                                           
00:00 [32m+0[0m: ProjectManifest cinematics integration decodes old project JSON without cinematics as empty list[0m                                                                                             
00:00 [32m+1[0m: ProjectManifest cinematics integration decodes old project JSON without cinematics as empty list[0m                                                                                             
00:00 [32m+1[0m: ProjectManifest cinematics integration decodes cinematics null and empty cinematics as empty list[0m                                                                                            
00:00 [32m+2[0m: ProjectManifest cinematics integration decodes cinematics null and empty cinematics as empty list[0m                                                                                            
00:00 [32m+2[0m: ProjectManifest cinematics integration round-trips manifest with cinematics through JSON[0m                                                                                                     
00:00 [32m+3[0m: ProjectManifest cinematics integration round-trips manifest with cinematics through JSON[0m                                                                                                     
00:00 [32m+3[0m: ProjectManifest cinematics integration round-trips cinematic stage context through manifest JSON[0m                                                                                             
00:00 [32m+4[0m: ProjectManifest cinematics integration round-trips cinematic stage context through manifest JSON[0m                                                                                             
00:00 [32m+4[0m: ProjectManifest cinematics integration project manifest roundtrips cinematic actor appearance bindings[0m                                                                                       
00:00 [32m+5[0m: ProjectManifest cinematics integration project manifest roundtrips cinematic actor appearance bindings[0m                                                                                       
00:00 [32m+5[0m: ProjectManifest cinematics integration project manifest old cinematic without appearance bindings still loads[0m                                                                                
00:00 [32m+6[0m: ProjectManifest cinematics integration project manifest old cinematic without appearance bindings still loads[0m                                                                                
00:00 [32m+6[0m: ProjectManifest cinematics integration diagnostics can resolve character ids from ProjectManifest.characters[0m                                                                                 
00:00 [32m+7[0m: ProjectManifest cinematics integration diagnostics can resolve character ids from ProjectManifest.characters[0m                                                                                 
00:00 [32m+7[0m: ProjectManifest cinematics integration keeps scenarios and scenes independent from cinematics[0m                                                                                                
00:00 [32m+8[0m: ProjectManifest cinematics integration keeps scenarios and scenes independent from cinematics[0m                                                                                                
00:00 [32m+8[0m: ProjectManifest cinematics integration rejects invalid cinematics JSON shape[0m                                                                                                                 
00:00 [32m+9[0m: ProjectManifest cinematics integration rejects invalid cinematics JSON shape[0m                                                                                                                 
00:00 [32m+9[0m: All tests passed![0m
```

### Suite complete map_core final line

Commande :
```bash
set -o pipefail; dart test --reporter=compact 2>&1 | tail -n 1
```

Code de sortie : `0`

Sortie :
```text

00:00 [32m+0[0m: [1m[90mloading test/placed_element_animation_test.dart[0m[0m                                                                                                                                              
00:00 [32m+0[0m: test/placed_element_animation_test.dart: MapPlacedElementAnimation serialization serializes and deserializes on placed element[0m                                                               
00:00 [32m+1[0m: test/game_state_persistence_test.dart: gameStateFromSaveData migrates legacy save fields to GameState[0m                                                                                        
00:00 [32m+2[0m: test/game_state_persistence_test.dart: gameStateFromSaveData migrates legacy save fields to GameState[0m                                                                                        
00:00 [32m+3[0m: test/game_state_persistence_test.dart: gameStateFromSaveData migrates legacy save fields to GameState[0m                                                                                        
00:00 [32m+4[0m: test/game_state_persistence_test.dart: gameStateFromSaveData migrates legacy save fields to GameState[0m                                                                                        
00:00 [32m+5[0m: test/world_rule_test.dart: WorldRuleDefinition creates a declarative authoring rule with stable metadata[0m                                                                                     
00:00 [32m+6[0m: test/world_rule_test.dart: WorldRuleDefinition creates a declarative authoring rule with stable metadata[0m                                                                                     
00:00 [32m+7[0m: test/world_rule_test.dart: WorldRuleDefinition creates a declarative authoring rule with stable metadata[0m                                                                                     
00:00 [32m+8[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity defaults to fully opaque and round-trips through json[0m                                                                        
00:00 [32m+9[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity defaults to fully opaque and round-trips through json[0m                                                                        
00:00 [32m+10[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity defaults to fully opaque and round-trips through json[0m                                                                       
00:00 [32m+11[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity defaults to fully opaque and round-trips through json[0m                                                                       
00:00 [32m+12[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity defaults to fully opaque and round-trips through json[0m                                                                       
00:00 [32m+13[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity defaults to fully opaque and round-trips through json[0m                                                                       
00:00 [32m+14[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity defaults to fully opaque and round-trips through json[0m                                                                       
00:00 [32m+15[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity defaults to fully opaque and round-trips through json[0m                                                                       
00:00 [32m+16[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity defaults to fully opaque and round-trips through json[0m                                                                       
00:00 [32m+17[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity defaults to fully opaque and round-trips through json[0m                                                                       
00:00 [32m+17[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity legacy instance without opacity still deserializes as opaque[0m                                                                
00:00 [32m+18[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity legacy instance without opacity still deserializes as opaque[0m                                                                
00:00 [32m+18[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity setMapPlacedElementOpacity updates only the targeted instance[0m                                                               
00:00 [32m+19[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity setMapPlacedElementOpacity updates only the targeted instance[0m                                                               
00:00 [32m+19[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity setMapPlacedElementOpacity rejects values outside 0..1[0m                                                                      
00:00 [32m+20[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity setMapPlacedElementOpacity rejects values outside 0..1[0m                                                                      
00:00 [32m+20[0m: test/placed_element_opacity_test.dart: MapPlacedElement opacity MapValidator rejects invalid placed element opacity[0m                                                                         
00:00 [32m+21[0m: test/save_data_test.dart: PokemonStatSpread serialization round-trip[0m                                                                                                                        
00:00 [32m+22[0m: test/save_data_test.dart: PokemonStatSpread serialization round-trip[0m                                                                                                                        
00:00 [32m+22[0m: test/save_data_test.dart: PlayerPokemon serialization round-trip[0m                                                                                                                            
00:00 [32m+23[0m: test/save_data_test.dart: PlayerPokemon serialization round-trip[0m                                                                                                                            
00:00 [32m+23[0m: test/save_data_test.dart: PlayerPokemon defaults are coherent[0m                                                                                                                               
00:00 [32m+24[0m: test/save_data_test.dart: PlayerPokemon defaults are coherent[0m                                                                                                                               
00:00 [32m+24[0m: test/save_data_test.dart: PlayerPokemon JSON keys match expected structure[0m                                                                                                                  
00:00 [32m+25[0m: test/save_data_test.dart: PlayerPokemon JSON keys match expected structure[0m                                                                                                                  
00:00 [32m+25[0m: test/save_data_test.dart: PlayerPokemon normalizes an optional authored gender without inventing one[0m                                                                                        
00:00 [32m+26[0m: test/save_data_test.dart: PlayerPokemon normalizes an optional authored gender without inventing one[0m                                                                                        
00:00 [32m+26[0m: test/save_data_test.dart: PlayerPokemon normalized rejects more than four moves[0m                                                                                                             
00:00 [32m+27[0m: test/save_data_test.dart: PlayerPokemon normalized rejects more than four moves[0m                                                                                                             
00:00 [32m+27[0m: test/save_data_test.dart: PlayerPokemon legacy JSON migrates missing phase 9 fields[0m                                                                                                         
00:00 [32m+28[0m: test/save_data_test.dart: PlayerPokemon legacy JSON migrates missing phase 9 fields[0m                                                                                                         
00:00 [32m+28[0m: test/save_data_test.dart: PlayerPokemon non legacy JSON missing phase 9 fields still fails[0m                                                                                                  
00:00 [32m+29[0m: test/save_data_test.dart: PlayerPokemon non legacy JSON missing phase 9 fields still fails[0m                                                                                                  
00:00 [32m+29[0m: test/save_data_test.dart: PlayerParty serialization round-trip[0m                                                                                                                              
00:00 [32m+30[0m: test/save_data_test.dart: PlayerParty serialization round-trip[0m                                                                                                                              
00:00 [32m+30[0m: test/save_data_test.dart: PlayerParty default is empty party[0m                                                                                                                                
00:00 [32m+31[0m: test/save_data_test.dart: PlayerParty default is empty party[0m                                                                                                                                
00:00 [32m+31[0m: test/save_data_test.dart: PokemonStorage serialization round-trip[0m                                                                                                                           
00:00 [32m+32[0m: test/save_data_test.dart: PokemonStorage serialization round-trip[0m                                                                                                                           
00:00 [32m+32[0m: test/save_data_test.dart: PokemonStorage default is empty storage[0m                                                                                                                           
00:00 [32m+33[0m: test/save_data_test.dart: PokemonStorage default is empty storage[0m                                                                                                                           
00:00 [32m+33[0m: test/save_data_test.dart: PlayerProgression serialization round-trip[0m                                                                                                                        
00:00 [32m+34[0m: test/save_data_test.dart: PlayerProgression serialization round-trip[0m                                                                                                                        
00:00 [32m+34[0m: test/save_data_test.dart: PlayerProgression defaults are empty[0m                                                                                                                              
00:00 [32m+35[0m: test/save_data_test.dart: PlayerProgression defaults are empty[0m                                                                                                                              
00:00 [32m+35[0m: test/save_data_test.dart: PlayerProgression normalized keeps caught as subset of seen[0m                                                                                                       
00:00 [32m+36[0m: test/save_data_test.dart: PlayerProgression normalized keeps caught as subset of seen[0m                                                                                                       
00:00 [32m+36[0m: test/save_data_test.dart: TrainerProfile serialization round-trip[0m                                                                                                                           
00:00 [32m+37[0m: test/save_data_test.dart: TrainerProfile serialization round-trip[0m                                                                                                                           
00:00 [32m+37[0m: test/save_data_test.dart: TrainerProfile normalized badges are stable[0m                                                                                                                       
00:00 [32m+38[0m: test/save_data_test.dart: TrainerProfile normalized badges are stable[0m                                                                                                                       
00:00 [32m+38[0m: test/save_data_test.dart: TrainerProfile normalized rejects empty names[0m                                                                                                                     
00:00 [32m+39[0m: test/save_data_test.dart: TrainerProfile normalized rejects empty names[0m                                                                                                                     
00:00 [32m+39[0m: test/save_data_test.dart: Bag serialization round-trip[0m                                                                                                                                      
00:00 [32m+40[0m: test/save_data_test.dart: Bag serialization round-trip[0m                                                                                                                                      
00:00 [32m+40[0m: test/save_data_test.dart: Bag normalized entries merge duplicates deterministically[0m                                                                                                         
00:00 [32m+41[0m: test/save_data_test.dart: Bag normalized entries merge duplicates deterministically[0m                                                                                                         
00:00 [32m+41[0m: test/save_data_test.dart: Bag normalized rejects non-positive quantities[0m                                                                                                                    
00:00 [32m+42[0m: test/save_data_test.dart: Bag normalized rejects non-positive quantities[0m                                                                                                                    
00:00 [32m+42[0m: test/save_data_test.dart: SaveData serialization round-trip[0m                                                                                                                                 
00:00 [32m+43[0m: test/save_data_test.dart: SaveData serialization round-trip[0m                                                                                                                                 
00:00 [32m+43[0m: test/save_data_test.dart: SaveData defaults are coherent[0m                                                                                                                                    
00:00 [32m+44[0m: test/save_data_test.dart: SaveData defaults are coherent[0m                                                                                                                                    
00:00 [32m+44[0m: test/save_data_test.dart: SaveData copyWith preserves unmodified fields[0m                                                                                                                     
00:00 [32m+45[0m: test/save_data_test.dart: SaveData copyWith preserves unmodified fields[0m                                                                                                                     
00:00 [32m+45[0m: test/save_data_test.dart: FieldAbility JSON values match expected strings[0m                                                                                                                   
00:00 [32m+46[0m: test/save_data_test.dart: FieldAbility JSON values match expected strings[0m                                                                                                                   
00:00 [32m+46[0m: [1m[90mloading test/project_manifest_surface_integration_test.dart[0m[0m                                                                                                                                 
00:00 [32m+46[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 1. ProjectManifest exposes surfaceCatalog[0m                                                 
00:00 [32m+47[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 1. ProjectManifest exposes surfaceCatalog[0m                                                 
00:00 [32m+47[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 2. toJson encodes surfaceCatalog even when empty[0m                                          
00:00 [32m+48[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration decodes absent null and empty worldRules as empty list[0m                                                  
00:00 [32m+49[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration decodes absent null and empty worldRules as empty list[0m                                                  
00:00 [32m+50[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration decodes absent null and empty worldRules as empty list[0m                                                  
00:00 [32m+51[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration decodes absent null and empty worldRules as empty list[0m                                                  
00:00 [32m+52[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration decodes absent null and empty worldRules as empty list[0m                                                  
00:00 [32m+53[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 7. fromJson decodes empty_surface_catalog_v0.json under surfaceCatalog[0m                    
00:00 [32m+54[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration round-trips world rules through ProjectManifest JSON[0m                                                    
00:00 [32m+55[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration round-trips world rules through ProjectManifest JSON[0m                                                    
00:00 [32m+56[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration round-trips world rules through ProjectManifest JSON[0m                                                    
00:00 [32m+57[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration round-trips world rules through ProjectManifest JSON[0m                                                    
00:00 [32m+58[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration round-trips world rules through ProjectManifest JSON[0m                                                    
00:00 [32m+59[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 9. fromJson decodes full_water_surface_catalog_v0.json[0m                                    
00:00 [32m+60[0m: test/storyline_asset_test.dart: StorylineAsset field validation rejects blank StorylineAsset id and title[0m                                                                                   
00:00 [32m+61[0m: test/project_manifest_world_rules_test.dart: ProjectManifest worldRules integration rejects invalid worldRules JSON shape[0m                                                                   
00:00 [32m+62[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                        
00:00 [32m+63[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                        
00:00 [32m+64[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                        
00:00 [32m+65[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                        
00:00 [32m+66[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                        
00:00 [32m+67[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                        
00:00 [32m+68[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                        
00:00 [32m+69[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                        
00:00 [32m+70[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                        
00:00 [32m+71[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 10. round-trip manifest with minimal water catalog[0m                                        
00:00 [32m+72[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem accepts valid item[0m                                                                                                           
00:00 [32m+73[0m: test/storyline_asset_test.dart: StorylineAsset local uniqueness rejects duplicate relationship ids[0m                                                                                          
00:00 [32m+74[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 11. round-trip manifest with full water catalog[0m                                           
00:00 [32m+75[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 11. round-trip manifest with full water catalog[0m                                           
00:00 [32m+76[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 11. round-trip manifest with full water catalog[0m                                           
00:00 [32m+77[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 11. round-trip manifest with full water catalog[0m                                           
00:00 [32m+78[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem rejects empty elementId[0m                                                                                                      
00:00 [32m+79[0m: test/storyline_asset_test.dart: StorylineAsset internal references requires scene link stepId to belong to the referenced chapter[0m                                                           
00:00 [32m+80[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 12. copyWith preserves surfaceCatalog when renaming[0m                                       
00:00 [32m+81[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 12. copyWith preserves surfaceCatalog when renaming[0m                                       
00:00 [32m+82[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 12. copyWith preserves surfaceCatalog when renaming[0m                                       
00:00 [32m+83[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 12. copyWith preserves surfaceCatalog when renaming[0m                                       
00:00 [32m+84[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 12. copyWith preserves surfaceCatalog when renaming[0m                                       
00:00 [32m+85[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 12. copyWith preserves surfaceCatalog when renaming[0m                                       
00:00 [32m+86[0m: test/storyline_asset_test.dart: StorylineSceneLink state rules placeholder rejects sceneRef[0m                                                                                                 
00:00 [32m+87[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem copies tags defensively[0m                                                                                                      
00:00 [32m+88[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 13. copyWith can replace surfaceCatalog[0m                                                   
00:00 [32m+89[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 13. copyWith can replace surfaceCatalog[0m                                                   
00:00 [32m+90[0m: test/storyline_asset_test.dart: StorylineSceneLink state rules linkedScenario requires scenario sceneRef[0m                                                                                    
00:00 [32m+91[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem rejects empty tag[0m                                                                                                            
00:00 [32m+92[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem rejects empty tag[0m                                                                                                            
00:00 [32m+93[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 14. equality distinguishes surfaceCatalog[0m                                                 
00:00 [32m+94[0m: test/storyline_asset_test.dart: StorylineSceneLink state rules brokenLink accepts null or stale sceneRef for diagnostics[0m                                                                    
00:00 [32m+95[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality[0m                                                                                                               
00:00 [32m+96[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality[0m                                                                                                               
00:00 [32m+97[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality[0m                                                                                                               
00:00 [32m+98[0m: test/environment_core_models_test.dart: EnvironmentPaletteItem value equality[0m                                                                                                               
00:00 [32m+99[0m: test/storyline_asset_test.dart: StorylineAsset immutability exposes unmodifiable collections[0m                                                                                                
00:00 [32m+100[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 17. Lot 47 fixtures remain bare catalog JSON (no manifest wrapper)[0m                       
00:00 [32m+101[0m: test/project_manifest_surface_integration_test.dart: ProjectManifest Surface Integration (Lot 49) 17. Lot 47 fixtures remain bare catalog JSON (no manifest wrapper)[0m                       
00:00 [32m+102[0m: test/storyline_asset_test.dart: StorylineAsset immutability supports value equality for equivalent models[0m                                                                                  
00:00 [32m+103[0m: test/storyline_asset_test.dart: StorylineAsset immutability supports value equality for equivalent models[0m                                                                                  
00:00 [32m+104[0m: test/storyline_asset_test.dart: StorylineAsset immutability supports value equality for equivalent models[0m                                                                                  
00:00 [32m+105[0m: test/storyline_asset_test.dart: StorylineAsset immutability supports value equality for equivalent models[0m                                                                                  
00:00 [32m+106[0m: test/storyline_asset_test.dart: StorylineAsset immutability supports value equality for equivalent models[0m                                                                                  
00:00 [32m+107[0m: test/storyline_asset_test.dart: StorylineAsset immutability supports value equality for equivalent models[0m                                                                                  
00:00 [32m+108[0m: test/storyline_asset_test.dart: StorylineAsset immutability supports value equality for equivalent models[0m                                                                                  
00:00 [32m+109[0m: test/storyline_asset_test.dart: StorylineAsset immutability supports value equality for equivalent models[0m                                                                                  
00:00 [32m+110[0m: test/storyline_asset_test.dart: StorylineAsset immutability supports value equality for equivalent models[0m                                                                                  
00:00 [32m+111[0m: test/environment_core_models_test.dart: EnvironmentGenerationParams value equality[0m                                                                                                         
00:00 [32m+112[0m: test/storyline_asset_test.dart: StorylineAsset V1-04 scope guards exposes JSON codec without manifest integration[0m                                                                          
00:00 [32m+113[0m: test/environment_core_models_test.dart: EnvironmentAreaMask accepts valid mask[0m                                                                                                             
00:00 [32m+114[0m: test/environment_core_models_test.dart: EnvironmentAreaMask accepts valid mask[0m                                                                                                             
00:00 [32m+114[0m: test/environment_core_models_test.dart: EnvironmentAreaMask rejects width <= 0[0m                                                                                                             
00:00 [32m+115[0m: test/environment_core_models_test.dart: EnvironmentAreaMask rejects width <= 0[0m                                                                                                             
00:00 [32m+115[0m: test/environment_core_models_test.dart: EnvironmentAreaMask rejects height <= 0[0m                                                                                                            
00:00 [32m+116[0m: test/environment_core_models_test.dart: EnvironmentAreaMask rejects height <= 0[0m                                                                                                            
00:00 [32m+116[0m: test/environment_core_models_test.dart: EnvironmentAreaMask rejects wrong cells length[0m                                                                                                     
00:00 [32m+117[0m: test/environment_core_models_test.dart: EnvironmentAreaMask rejects wrong cells length[0m                                                                                                     
00:00 [32m+117[0m: test/environment_core_models_test.dart: EnvironmentAreaMask cells copied defensively[0m                                                                                                       
00:00 [32m+118[0m: test/environment_core_models_test.dart: EnvironmentAreaMask cells copied defensively[0m                                                                                                       
00:00 [32m+118[0m: test/environment_core_models_test.dart: EnvironmentAreaMask cells list is unmodifiable[0m                                                                                                     
00:00 [32m+119[0m: test/environment_core_models_test.dart: EnvironmentAreaMask cells list is unmodifiable[0m                                                                                                     
00:00 [32m+119[0m: test/environment_core_models_test.dart: EnvironmentAreaMask hasAnyActiveCell[0m                                                                                                               
00:00 [32m+120[0m: test/environment_core_models_test.dart: EnvironmentAreaMask hasAnyActiveCell[0m                                                                                                               
00:00 [32m+120[0m: test/environment_core_models_test.dart: EnvironmentAreaMask activeCellCount[0m                                                                                                                
00:00 [32m+121[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+122[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+123[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+124[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+125[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+126[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+127[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+128[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+129[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+130[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+131[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+132[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+133[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+134[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+135[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+136[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+137[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+138[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+139[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+140[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+141[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+142[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+143[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+144[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+145[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks does not report pages without scene target[0m                                                                            
00:00 [32m+145[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks accepts a scene target referencing an existing scene[0m                                                                  
00:00 [32m+146[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks accepts a scene target referencing an existing scene[0m                                                                  
00:00 [32m+146[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks reports missing and empty scene targets as errors[0m                                                                     
00:00 [32m+147[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks reports missing and empty scene targets as errors[0m                                                                     
00:00 [32m+147[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks warns when a disabled page targets a scene[0m                                                                            
00:00 [32m+148[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks warns when a disabled page targets a scene[0m                                                                            
00:00 [32m+148[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks warns when the target scene has scene diagnostics errors[0m                                                              
00:00 [32m+149[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks warns when the target scene has scene diagnostics errors[0m                                                              
00:00 [32m+149[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks errors when the target scene cannot build a runtime plan[0m                                                              
00:00 [32m+150[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks errors when the target scene cannot build a runtime plan[0m                                                              
00:00 [32m+150[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks warns when legacy message or script coexist with scene target[0m                                                         
00:00 [32m+151[0m: test/event_scene_link_diagnostics_test.dart: diagnoseEventSceneLinks warns when legacy message or script coexist with scene target[0m                                                         
00:00 [32m+151[0m: [1m[90mloading test/environment_layer_map_layer_integration_test.dart[0m[0m                                                                                                                             
00:00 [32m+151[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m                                                                            
00:00 [32m+152[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment valeurs par défaut et content vide[0m                                                                            
00:00 [32m+152[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m                                                                                     
00:00 [32m+153[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment toJson/fromJson roundtrip[0m                                                                                     
00:00 [32m+153[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment fromJson sans content => content vide[0m                                                                         
00:00 [32m+154[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment fromJson sans content => content vide[0m                                                                         
00:00 [32m+154[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment copyWith préserve content et properties si non passés[0m                                                         
00:00 [32m+155[0m: test/environment_layer_map_layer_integration_test.dart: MapLayer.environment copyWith préserve content et properties si non passés[0m                                                         
00:00 [32m+155[0m: test/environment_layer_map_layer_integration_test.dart: addMapLayer MapLayerKind.environment crée EnvironmentLayer avec ids normalisés et content vide[0m                                     
00:00 [32m+156[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+157[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+158[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+159[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+160[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+161[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+162[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+163[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+164[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+165[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+166[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+167[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+168[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+169[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+170[0m: test/cinematic_timeline_lane_read_model_test.dart: buildCinematicTimelineLaneReadModel groups timeline steps into deterministic lanes without mutation[0m                                     
00:00 [32m+171[0m: test/facts_world_rules_manager_read_model_test.dart: Facts and World Rules manager read model lists facts with usages from scenes and world rules[0m                                          
00:00 [32m+172[0m: test/facts_world_rules_manager_read_model_test.dart: Facts and World Rules manager read model lists facts with usages from scenes and world rules[0m                                          
00:00 [32m+173[0m: test/facts_world_rules_manager_read_model_test.dart: Facts and World Rules manager read model lists facts with usages from scenes and world rules[0m                                          
00:00 [32m+174[0m: test/facts_world_rules_manager_read_model_test.dart: Facts and World Rules manager read model lists facts with usages from scenes and world rules[0m                                          
00:00 [32m+175[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset[0m                                     
00:00 [32m+176[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples minimal 1x1 golden decodes to the expected preset[0m                                     
00:00 [32m+177[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content[0m                                                                                       
00:00 [32m+178[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts empty content[0m                                                                                       
00:00 [32m+179[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples complete 2x2 golden decodes to the expected preset[0m                                    
00:00 [32m+180[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples complete 2x2 golden decodes to the expected preset[0m                                    
00:00 [32m+181[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples complete 2x2 golden decodes to the expected preset[0m                                    
00:00 [32m+182[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent construction rejects targetTileLayerId whitespace only[0m                                                                   
00:00 [32m+183[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples complete 2x2 golden matches encode output[0m                                             
00:00 [32m+184[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent construction accepts valid areas and preserves order[0m                                                                     
00:00 [32m+185[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens roundtrip through decode and encode[0m                                           
00:00 [32m+186[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens roundtrip through decode and encode[0m                                           
00:00 [32m+187[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent defensive copy and immutability copies areas list defensively[0m                                                            
00:00 [32m+188[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline[0m                         
00:00 [32m+189[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline[0m                         
00:00 [32m+190[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline[0m                         
00:00 [32m+191[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline[0m                         
00:00 [32m+192[0m: test/project_path_pattern_preset_json_golden_test.dart: ProjectPathPatternPreset JSON golden samples goldens use two-space canonical formatting with final newline[0m                         
00:00 [32m+193[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaCount[0m                                                                                                        
00:00 [32m+194[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaCount[0m                                                                                                        
00:00 [32m+194[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea known id[0m                                                                                            
00:00 [32m+195[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea known id[0m                                                                                            
00:00 [32m+195[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea trims argument[0m                                                                                      
00:00 [32m+196[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea trims argument[0m                                                                                      
00:00 [32m+196[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea false for unknown[0m                                                                                   
00:00 [32m+197[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea false for unknown[0m                                                                                   
00:00 [32m+197[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea false for empty or whitespace id[0m                                                                    
00:00 [32m+198[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers containsArea false for empty or whitespace id[0m                                                                    
00:00 [32m+198[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById returns area[0m                                                                                            
00:00 [32m+199[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById returns area[0m                                                                                            
00:00 [32m+199[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById trims argument[0m                                                                                          
00:00 [32m+200[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById trims argument[0m                                                                                          
00:00 [32m+200[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById null for unknown[0m                                                                                        
00:00 [32m+201[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById null for unknown[0m                                                                                        
00:00 [32m+201[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById null for empty or whitespace[0m                                                                            
00:00 [32m+202[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent helpers areaById null for empty or whitespace[0m                                                                            
00:00 [32m+202[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate hasGeneratedPlacements false when none[0m                                                    
00:00 [32m+203[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate hasGeneratedPlacements false when none[0m                                                    
00:00 [32m+203[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate hasGeneratedPlacements true when any area has ids[0m                                         
00:00 [32m+204[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate hasGeneratedPlacements true when any area has ids[0m                                         
00:00 [32m+204[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate generatedPlacementIds order: areas then inner order[0m                                       
00:00 [32m+205[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate generatedPlacementIds order: areas then inner order[0m                                       
00:00 [32m+205[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate generatedPlacementIds returns unmodifiable list[0m                                           
00:00 [32m+206[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent generated placements aggregate generatedPlacementIds returns unmodifiable list[0m                                           
00:00 [32m+206[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal[0m                                                                                
00:00 [32m+207[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent equality two identical contents are equal[0m                                                                                
00:00 [32m+207[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent equality different targetTileLayerId not equal[0m                                                                           
00:00 [32m+208[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent equality different targetTileLayerId not equal[0m                                                                           
00:00 [32m+208[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent equality different areas order not equal[0m                                                                                 
00:00 [32m+209[0m: test/environment_layer_content_test.dart: EnvironmentLayerContent equality different areas order not equal[0m                                                                                 
00:00 [32m+209[0m: [1m[90mloading test/pokemon_move_test.dart[0m[0m                                                                                                                                                        
00:00 [32m+209[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a simple damage move[0m                                                                                                          
00:00 [32m+210[0m: test/storyline_legacy_import_preview_test.dart: buildLegacyGlobalStoryImportPreview reports no legacy globalStory when manifest has none[0m                                                   
00:00 [32m+211[0m: test/pokemon_move_test.dart: PokemonMove round-trip JSON for a move with a secondary status effect[0m                                                                                         
00:00 [32m+212[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: SurfaceGameplayZoneGenerationAssessmentPolicy default policy is valid[0m                                                       
00:00 [32m+213[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: SurfaceGameplayZoneGenerationAssessmentPolicy default policy is valid[0m                                                       
00:00 [32m+214[0m: test/storyline_legacy_import_preview_test.dart: buildLegacyGlobalStoryImportPreview builds a minimal main draft candidate from globalStory[0m                                                 
00:00 [32m+215[0m: test/storyline_legacy_import_preview_test.dart: buildLegacyGlobalStoryImportPreview builds a minimal main draft candidate from globalStory[0m                                                 
00:00 [32m+216[0m: test/storyline_legacy_import_preview_test.dart: buildLegacyGlobalStoryImportPreview builds a minimal main draft candidate from globalStory[0m                                                 
00:00 [32m+217[0m: test/storyline_legacy_import_preview_test.dart: buildLegacyGlobalStoryImportPreview builds a minimal main draft candidate from globalStory[0m                                                 
00:00 [32m+218[0m: test/storyline_legacy_import_preview_test.dart: buildLegacyGlobalStoryImportPreview builds a minimal main draft candidate from globalStory[0m                                                 
00:00 [32m+219[0m: test/storyline_legacy_import_preview_test.dart: buildLegacyGlobalStoryImportPreview builds a minimal main draft candidate from globalStory[0m                                                 
00:00 [32m+220[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: assessSurfaceGameplayZoneGenerationPlan ready marks an exact greedy rectangle plan ready[0m                                    
00:00 [32m+221[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: assessSurfaceGameplayZoneGenerationPlan ready marks an exact greedy rectangle plan ready[0m                                    
00:00 [32m+222[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: assessSurfaceGameplayZoneGenerationPlan ready marks an exact greedy rectangle plan ready[0m                                    
00:00 [32m+223[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: assessSurfaceGameplayZoneGenerationPlan ready marks an exact greedy rectangle plan ready[0m                                    
00:00 [32m+224[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: assessSurfaceGameplayZoneGenerationPlan ready marks an exact greedy rectangle plan ready[0m                                    
00:00 [32m+225[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: assessSurfaceGameplayZoneGenerationPlan ready marks an exact greedy rectangle plan ready[0m                                    
00:00 [32m+226[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: assessSurfaceGameplayZoneGenerationPlan ready marks an exact greedy rectangle plan ready[0m                                    
00:00 [32m+227[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: assessSurfaceGameplayZoneGenerationPlan ready marks an exact greedy rectangle plan ready[0m                                    
00:00 [32m+228[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: assessSurfaceGameplayZoneGenerationPlan ready marks an exact greedy rectangle plan ready[0m                                    
00:00 [32m+229[0m: test/surface_to_gameplay_zone_generation_assessment_test.dart: assessSurfaceGameplayZoneGenerationPlan ready marks an exact greedy rectangle plan ready[0m                                    
00:00 [32m+230[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+231[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+232[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+233[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+234[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+235[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+236[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+237[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+238[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+239[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+240[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+241[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+242[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+243[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+244[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+245[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+246[0m: test/path_pattern_visual_resolution_test.dart: resolvePathPatternVisual center-only 1x1 uses center pattern for multiple variants when no mapping exists[0m                                   
00:00 [32m+247[0m: test/storyline_legacy_import_preview_test.dart: buildLegacyGlobalStoryImportPreview imports legacy chapters and attached steps when metadata is valid[0m                                      
00:00 [32m+248[0m: test/storyline_legacy_import_preview_test.dart: buildLegacyGlobalStoryImportPreview imports legacy chapters and attached steps when metadata is valid[0m                                      
00:00 [32m+249[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+250[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+251[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+252[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+253[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+254[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+255[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+256[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+257[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+258[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+259[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+260[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+261[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+262[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+263[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+264[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+265[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+266[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize keeps width and height[0m                                                                                                         
00:00 [32m+266[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive width: 0[0m                                                                                                  
00:00 [32m+267[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive width: 0[0m                                                                                                  
00:00 [32m+267[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive width: -1[0m                                                                                                 
00:00 [32m+268[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive width: -1[0m                                                                                                 
00:00 [32m+268[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive height: 0[0m                                                                                                 
00:00 [32m+269[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive height: 0[0m                                                                                                 
00:00 [32m+269[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive height: -1[0m                                                                                                
00:00 [32m+270[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize rejects non-positive height: -1[0m                                                                                                
00:00 [32m+270[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize value equality: same values => equal and same hashCode[0m                                                                         
00:00 [32m+271[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize value equality: same values => equal and same hashCode[0m                                                                         
00:00 [32m+271[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize value equality: different => not equal[0m                                                                                         
00:00 [32m+272[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasTileSize value equality: different => not equal[0m                                                                                         
00:00 [32m+272[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize keeps columns, rows, tileCount[0m                                                                                                 
00:00 [32m+273[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize keeps columns, rows, tileCount[0m                                                                                                 
00:00 [32m+273[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize rejects non-positive columns: 0[0m                                                                                                
00:00 [32m+274[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize rejects non-positive columns: 0[0m                                                                                                
00:00 [32m+274[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize rejects non-positive columns: -1[0m                                                                                               
00:00 [32m+275[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize rejects non-positive columns: -1[0m                                                                                               
00:00 [32m+275[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize rejects non-positive rows: 0[0m                                                                                                   
00:00 [32m+276[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize rejects non-positive rows: 0[0m                                                                                                   
00:00 [32m+276[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize rejects non-positive rows: -1[0m                                                                                                  
00:00 [32m+277[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize rejects non-positive rows: -1[0m                                                                                                  
00:00 [32m+277[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize value equality: same => equal; different => not[0m                                                                                
00:00 [32m+278[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGridSize value equality: same => equal; different => not[0m                                                                                
00:00 [32m+278[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGeometry keeps fields and delegates tileCount[0m                                                                                           
00:00 [32m+279[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGeometry keeps fields and delegates tileCount[0m                                                                                           
00:00 [32m+279[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGeometry default layout is grid[0m                                                                                                         
00:00 [32m+280[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGeometry default layout is grid[0m                                                                                                         
00:00 [32m+280[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGeometry containsGridCoordinate: interior points in range[0m                                                                               
00:00 [32m+281[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGeometry containsGridCoordinate: interior points in range[0m                                                                               
00:00 [32m+281[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGeometry containsGridCoordinate: out of range or negative[0m                                                                               
00:00 [32m+282[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGeometry containsGridCoordinate: out of range or negative[0m                                                                               
00:00 [32m+282[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGeometry value equality: layout / tile / grid disambiguation[0m                                                                            
00:00 [32m+283[0m: test/surface_atlas_geometry_test.dart: SurfaceAtlasGeometry value equality: layout / tile / grid disambiguation[0m                                                                            
00:00 [32m+283[0m: test/surface_atlas_geometry_test.dart: public export & manifest unchanged map_core exposes all new types[0m                                                                                   
00:00 [32m+284[0m: test/surface_atlas_geometry_test.dart: public export & manifest unchanged map_core exposes all new types[0m                                                                                   
00:00 [32m+284[0m: test/surface_atlas_geometry_test.dart: public export & manifest unchanged ProjectManifest toJson() still has no surface* top-level keys[0m                                                    
00:00 [32m+285[0m: test/surface_atlas_geometry_test.dart: public export & manifest unchanged ProjectManifest toJson() still has no surface* top-level keys[0m                                                    
00:00 [32m+285[0m: [1m[90mloading test/project_surface_preset_json_codec_test.dart[0m[0m                                                                                                                                   
00:00 [32m+285[0m: test/project_surface_preset_json_codec_test.dart: ProjectSurfacePreset JSON codec (Lot 45) 1. encodes minimal preset[0m                                                                       
00:00 [32m+286[0m: test/project_surface_preset_json_codec_test.dart: ProjectSurfacePreset JSON codec (Lot 45) 1. encodes minimal preset[0m                                                                       
00:00 [32m+286[0m: test/project_surface_preset_json_codec_test.dart: ProjectSurfacePreset JSON codec (Lot 45) 2. decodes minimal preset[0m                                                                       
00:00 [32m+287[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+288[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+289[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+290[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+291[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+292[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+293[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+294[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+295[0m: test/scenario_assets_test.dart: ScenarioAsset serialization round-trips scenario with bindings and condition payload[0m                                                                       
00:00 [32m+296[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+297[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+298[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+299[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+300[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+301[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+302[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+303[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+304[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+305[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+306[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+307[0m: test/tall_grass_authoring_view_test.dart: TallGrassAuthoringView collects existing project signals without merging contracts[0m                                                               
00:00 [32m+308[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+309[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+310[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+311[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+312[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+313[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+314[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+315[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+316[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+317[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+318[0m: test/dialogue_library_tree_test.dart: buildDialogueLibraryTree nests folders and assigns dialogues to correct parents[0m                                                                      
00:00 [32m+319[0m: test/scenario_assets_test.dart: ScenarioAsset validation rejects global story scenario that uses world source hook[0m                                                                         
00:00 [32m+320[0m: test/scenario_assets_test.dart: ScenarioAsset validation rejects global story scenario that uses world source hook[0m                                                                         
00:00 [32m+321[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+322[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+323[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+324[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+325[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+326[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+327[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+328[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+329[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+330[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+331[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+332[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy interaction message migrates to behavior[0m                                                               
00:00 [32m+332[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy behavior list without ids receives stable non-empty ids[0m                                                
00:00 [32m+333[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy behavior list without ids receives stable non-empty ids[0m                                                
00:00 [32m+333[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration parses onExit and onNear triggers from json[0m                                                                   
00:00 [32m+334[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration parses onExit and onNear triggers from json[0m                                                                   
00:00 [32m+334[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration serializes and deserializes optional cooldownMs[0m                                                               
00:00 [32m+335[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration serializes and deserializes optional cooldownMs[0m                                                               
00:00 [32m+335[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy behavior json without cooldownMs/triggerScope keeps defaults[0m                                           
00:00 [32m+336[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior migration legacy behavior json without cooldownMs/triggerScope keeps defaults[0m                                           
00:00 [32m+336[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects behavior with empty id[0m                                                                               
00:00 [32m+337[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects behavior with empty id[0m                                                                               
00:00 [32m+337[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects showMessage without text[0m                                                                             
00:00 [32m+338[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects showMessage without text[0m                                                                             
00:00 [32m+338[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects openDialogue without dialogue ref[0m                                                                    
00:00 [32m+339[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects openDialogue without dialogue ref[0m                                                                    
00:00 [32m+339[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects setAnimationEnabled without value[0m                                                                    
00:00 [32m+340[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects setAnimationEnabled without value[0m                                                                    
00:00 [32m+340[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects duplicate behavior ids in same instance[0m                                                              
00:00 [32m+341[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects duplicate behavior ids in same instance[0m                                                              
00:00 [32m+341[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects behavior with negative cooldownMs[0m                                                                    
00:00 [32m+342[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects behavior with negative cooldownMs[0m                                                                    
00:00 [32m+342[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects behavior with excessive cooldownMs[0m                                                                   
00:00 [32m+343[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects behavior with excessive cooldownMs[0m                                                                   
00:00 [32m+343[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects facingOnly scope on unsupported trigger[0m                                                              
00:00 [32m+344[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects facingOnly scope on unsupported trigger[0m                                                              
00:00 [32m+344[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects nearCardinalOnly scope on unsupported trigger[0m                                                        
00:00 [32m+345[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior validation rejects nearCardinalOnly scope on unsupported trigger[0m                                                        
00:00 [32m+345[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior operations add/update/remove behavior by index[0m                                                                          
00:00 [32m+346[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior operations add/update/remove behavior by index[0m                                                                          
00:01 [32m+346[0m: test/placed_element_behaviors_test.dart: MapPlacedElement behavior operations add/update/remove behavior by index[0m                                                                          
00:01 [32m+346[0m: [1m[90mloading test/project_trainer_validation_test.dart[0m[0m                                                                                                                                          
00:01 [32m+346[0m: test/project_trainer_validation_test.dart: ProjectTrainerEntry validation rejects battleDifficulty values outside the authored 1..10 range[0m                                                 
00:01 [32m+347[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile collisionMask wins over contradictory legacy cells[0m                                                   
00:01 [32m+348[0m: test/project_trainer_validation_test.dart: ProjectTrainerEntry validation rejects trainer battle background paths that escape the project[0m                                                  
00:01 [32m+349[0m: test/project_trainer_validation_test.dart: ProjectTrainerEntry validation rejects trainer battle background paths that escape the project[0m                                                  
00:01 [32m+350[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile collisionMask projection matches ElementCollisionMaskCodec contract[0m                                  
00:01 [32m+351[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile collisionMask projection matches ElementCollisionMaskCodec contract[0m                                  
00:01 [32m+351[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile collisionMask preserves visualMask and occlusionMask[0m                                                 
00:01 [32m+352[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile collisionMask preserves visualMask and occlusionMask[0m                                                 
00:01 [32m+352[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile visualMask does not create collision cells[0m                                                           
00:01 [32m+353[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile visualMask does not create collision cells[0m                                                           
00:01 [32m+353[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile occlusionMask does not create collision cells[0m                                                        
00:01 [32m+354[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile occlusionMask does not create collision cells[0m                                                        
00:01 [32m+354[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile legacy manualAddedCells rebuild cells when shapeCells is empty[0m                                       
00:01 [32m+355[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile legacy manualAddedCells rebuild cells when shapeCells is empty[0m                                       
00:01 [32m+355[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile legacy shapeCells plus manualAddedCells minus manualRemovedCells[0m                                     
00:01 [32m+356[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile legacy shapeCells plus manualAddedCells minus manualRemovedCells[0m                                     
00:01 [32m+356[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile keeps cells unchanged when no legacy authoring intent exists[0m                                         
00:01 [32m+357[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile keeps cells unchanged when no legacy authoring intent exists[0m                                         
00:01 [32m+357[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile sorts rebuilt legacy cells by y then x[0m                                                               
00:01 [32m+358[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile sorts rebuilt legacy cells by y then x[0m                                                               
00:01 [32m+358[0m: test/element_collision_profile_normalizer_test.dart: normalizeElementCollisionProfile rejects non-positive tileSize[0m                                                                        
00:01 [32m+359[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration decodes old project JSON without cinematics as empty list[0m                                               
00:01 [32m+360[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration decodes old project JSON without cinematics as empty list[0m                                               
00:01 [32m+361[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration decodes old project JSON without cinematics as empty list[0m                                               
00:01 [32m+361[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration decodes cinematics null and empty cinematics as empty list[0m                                              
00:01 [32m+362[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration decodes cinematics null and empty cinematics as empty list[0m                                              
00:01 [32m+362[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration round-trips manifest with cinematics through JSON[0m                                                       
00:01 [32m+363[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration round-trips manifest with cinematics through JSON[0m                                                       
00:01 [32m+364[0m: test/world_rule_projection_test.dart: World rule projection projects enabled matching fact rules without mutating inputs[0m                                                                   
00:01 [32m+365[0m: test/world_rule_projection_test.dart: World rule projection projects enabled matching fact rules without mutating inputs[0m                                                                   
00:01 [32m+366[0m: test/surface_model_entrypoint_test.dart: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest has surfaceCatalog; split surface keys stay absent[0m                         
00:01 [32m+367[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration project manifest roundtrips cinematic actor appearance bindings[0m                                         
00:01 [32m+368[0m: test/world_rule_projection_test.dart: World rule projection supports story step completion and consumed event sources[0m                                                                      
00:01 [32m+369[0m: test/world_rule_projection_test.dart: World rule projection supports story step completion and consumed event sources[0m                                                                      
00:01 [32m+370[0m: test/world_rule_projection_test.dart: World rule projection supports story step completion and consumed event sources[0m                                                                      
00:01 [32m+371[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration diagnostics can resolve character ids from ProjectManifest.characters[0m                                   
00:01 [32m+372[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration diagnostics can resolve character ids from ProjectManifest.characters[0m                                   
00:01 [32m+373[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration diagnostics can resolve character ids from ProjectManifest.characters[0m                                   
00:01 [32m+373[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration keeps scenarios and scenes independent from cinematics[0m                                                  
00:01 [32m+374[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration keeps scenarios and scenes independent from cinematics[0m                                                  
00:01 [32m+374[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration rejects invalid cinematics JSON shape[0m                                                                   
00:01 [32m+375[0m: test/project_manifest_cinematics_test.dart: ProjectManifest cinematics integration rejects invalid cinematics JSON shape[0m                                                                   
00:01 [32m+375[0m: [1m[90mloading test/element_collision_building_golden_slice_test.dart[0m[0m                                                                                                                             
00:01 [32m+375[0m: test/element_collision_building_golden_slice_test.dart: building collision golden slice normalizes legacy building profile with full cells and manual silhouette[0m                           
00:01 [32m+376[0m: test/element_collision_building_golden_slice_test.dart: building collision golden slice normalizes legacy building profile with full cells and manual silhouette[0m                           
00:01 [32m+376[0m: test/element_collision_building_golden_slice_test.dart: building collision golden slice building normalization preserves visual and occlusion masks without making them collision[0m          
00:01 [32m+377[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec encodes a minimal preset[0m                                                                        
00:01 [32m+378[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec encodes a minimal preset[0m                                                                        
00:01 [32m+379[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec encodes a minimal preset[0m                                                                        
00:01 [32m+379[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec decodes a minimal preset[0m                                                                        
00:01 [32m+380[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec decodes a minimal preset[0m                                                                        
00:01 [32m+380[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec roundtrips a minimal preset[0m                                                                     
00:01 [32m+381[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec roundtrips a minimal preset[0m                                                                     
00:01 [32m+381[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec encodes a complete 2x2 preset in row-major cell order[0m                                           
00:01 [32m+382[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec encodes a complete 2x2 preset in row-major cell order[0m                                           
00:01 [32m+382[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec roundtrips a complete 2x2 preset[0m                                                                
00:01 [32m+383[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec roundtrips a complete 2x2 preset[0m                                                                
00:01 [32m+383[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec canonicalizes transparentColor after decode and encode[0m                                          
00:01 [32m+384[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec canonicalizes transparentColor after decode and encode[0m                                          
00:01 [32m+384[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec roundtrips frame tileset overrides[0m                                                              
00:01 [32m+385[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec roundtrips frame tileset overrides[0m                                                              
00:01 [32m+385[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec roundtrips null and non-null frame durations[0m                                                    
00:01 [32m+386[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec roundtrips null and non-null frame durations[0m                                                    
00:01 [32m+386[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec rejects invalid JSON[0m                                                                            
00:01 [32m+387[0m: test/project_path_pattern_preset_json_codec_test.dart: ProjectPathPatternPreset JSON codec rejects invalid JSON[0m                                                                            
00:01 [32m+387[0m: [1m[90mloading test/environment_layer_content_json_codec_test.dart[0m[0m                                                                                                                                
00:01 [32m+387[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent[0m                                                                        
00:01 [32m+388[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode null => emptyContent[0m                                                                        
00:01 [32m+388[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec decode map minimal => content vide[0m                                                                 
00:01 [32m+389[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload exposes slide and movementCost effect kinds[0m                                                            
00:01 [32m+390[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload exposes slide and movementCost effect kinds[0m                                                            
00:01 [32m+391[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload exposes slide and movementCost effect kinds[0m                                                            
00:01 [32m+392[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload exposes slide and movementCost effect kinds[0m                                                            
00:01 [32m+393[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload exposes slide and movementCost effect kinds[0m                                                            
00:01 [32m+394[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload exposes slide and movementCost effect kinds[0m                                                            
00:01 [32m+395[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload exposes slide and movementCost effect kinds[0m                                                            
00:01 [32m+396[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload exposes slide and movementCost effect kinds[0m                                                            
00:01 [32m+397[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload exposes slide and movementCost effect kinds[0m                                                            
00:01 [32m+398[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload exposes slide and movementCost effect kinds[0m                                                            
00:01 [32m+398[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec json non-map rejeté[0m                                                                                
00:01 [32m+399[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload slide defaults to a valid payload[0m                                                                      
00:01 [32m+400[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec areas non-list rejeté[0m                                                                              
00:01 [32m+401[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec areas non-list rejeté[0m                                                                              
00:01 [32m+401[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload movementCost supports positive cost and value equality[0m                                                 
00:01 [32m+402[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload movementCost supports positive cost and value equality[0m                                                 
00:01 [32m+403[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec codec strict int decode seed double => FormatException[0m                                             
00:01 [32m+404[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload encodes and decodes slide JSON[0m                                                                         
00:01 [32m+405[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload encodes and decodes slide JSON[0m                                                                         
00:01 [32m+406[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload encodes and decodes slide JSON[0m                                                                         
00:01 [32m+407[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload encodes and decodes slide JSON[0m                                                                         
00:01 [32m+408[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec codec strict int decode paramsOverride density hors plage => FormatException[0m                       
00:01 [32m+409[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MovementEffectZonePayload encodes and decodes movementCost JSON[0m                                                                  
00:01 [32m+410[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict generatedPlacementIds avec int => FormatException[0m            
00:01 [32m+411[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict generatedPlacementIds avec int => FormatException[0m            
00:01 [32m+411[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: MapGameplayZone movementEffect payload can carry a movementEffect zone payload[0m                                                   
00:01 [32m+412[0m: test/environment_layer_content_json_codec_test.dart: EnvironmentLayerContent JSON codec generatedPlacementIds et areas strict generatedPlacementIds string vide => FormatException[0m         
00:01 [32m+413[0m: test/element_collision_mask_codec_test.dart: ElementCollisionMaskCodec packed bits roundtrip preserves mask[0m                                                                                
00:01 [32m+414[0m: test/element_collision_mask_codec_test.dart: ElementCollisionMaskCodec packed bits roundtrip preserves mask[0m                                                                                
00:01 [32m+415[0m: test/element_collision_mask_codec_test.dart: ElementCollisionMaskCodec packed bits roundtrip preserves mask[0m                                                                                
00:01 [32m+416[0m: test/element_collision_mask_codec_test.dart: ElementCollisionMaskCodec packed bits roundtrip preserves mask[0m                                                                                
00:01 [32m+417[0m: test/element_collision_mask_codec_test.dart: ElementCollisionMaskCodec packed bits roundtrip preserves mask[0m                                                                                
00:01 [32m+418[0m: test/element_collision_mask_codec_test.dart: ElementCollisionMaskCodec packed bits roundtrip preserves mask[0m                                                                                
00:01 [32m+419[0m: test/element_collision_mask_codec_test.dart: ElementCollisionMaskCodec packed bits roundtrip preserves mask[0m                                                                                
00:01 [32m+420[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation updateGameplayZoneOnMap accepts a valid movementEffect zone[0m                              
00:01 [32m+421[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation updateGameplayZoneOnMap accepts a valid movementEffect zone[0m                              
00:01 [32m+421[0m: test/element_collision_mask_codec_test.dart: ElementCollisionMaskCodec cellsFromPixelMask projects blocking cells from mask[0m                                                                
00:01 [32m+422[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation MapValidator accepts a valid movementEffect zone[0m                                         
00:01 [32m+423[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation MapValidator accepts a valid movementEffect zone[0m                                         
00:01 [32m+424[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation MapValidator accepts a valid movementEffect zone[0m                                         
00:01 [32m+425[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation MapValidator accepts a valid movementEffect zone[0m                                         
00:01 [32m+426[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation MapValidator accepts a valid movementEffect zone[0m                                         
00:01 [32m+427[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation MapValidator accepts a valid movementEffect zone[0m                                         
00:01 [32m+427[0m: test/element_collision_mask_codec_test.dart: ElementCollisionMaskCodec cellsFromPixelMask accepts cells dense enough for minimum ratio[0m                                                     
00:01 [32m+428[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation rejects movementEffect kind without payload[0m                                              
00:01 [32m+429[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation rejects movementEffect kind without payload[0m                                              
00:01 [32m+430[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation rejects movementEffect kind without payload[0m                                              
00:01 [32m+430[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation rejects non-positive movementCost[0m                                                        
00:01 [32m+431[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation rejects non-positive movementCost[0m                                                        
00:01 [32m+431[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation keeps duplicate id and invalid area validation intact[0m                                    
00:01 [32m+432[0m: test/map_gameplay_zone_movement_effect_payload_test.dart: movementEffect gameplay zone validation keeps duplicate id and invalid area validation intact[0m                                    
00:01 [32m+432[0m: [1m[90mloading test/project_element_frames_test.dart[0m[0m                                                                                                                                              
00:01 [32m+432[0m: test/project_element_frames_test.dart: ProjectElementEntry frames serializes and deserializes multi-frame element[0m                                                                          
00:01 [32m+433[0m: test/project_element_frames_test.dart: ProjectElementEntry frames serializes and deserializes multi-frame element[0m                                                                          
00:01 [32m+433[0m: test/project_element_frames_test.dart: ProjectElementEntry frames validator rejects non-positive frame duration[0m                                                                            
00:01 [32m+434[0m: test/project_element_frames_test.dart: ProjectElementEntry frames validator rejects non-positive frame duration[0m                                                                            
00:01 [32m+434[0m: [1m[90mloading test/environment_layer_usage_diagnostics_test.dart[0m[0m                                                                                                                                 
00:01 [32m+434[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m                                                                                            
00:01 [32m+435[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport vide[0m                                                                                            
00:01 [32m+435[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport copie défensive et liste immuable[0m                                                               
00:01 [32m+436[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport copie défensive et liste immuable[0m                                                               
00:01 [32m+436[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport counts et diagnosticsForLayer / Area / Kind[0m                                                     
00:01 [32m+437[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport counts et diagnosticsForLayer / Area / Kind[0m                                                     
00:01 [32m+437[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport égalité[0m                                                                                         
00:01 [32m+438[0m: test/environment_layer_usage_diagnostics_test.dart: EnvironmentLayerUsageDiagnosticsReport égalité[0m                                                                                         
00:01 [32m+438[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset preset présent => rien[0m                                                                                               
00:01 [32m+439[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset preset présent => rien[0m                                                                                               
00:01 [32m+439[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset preset absent => error[0m                                                                                               
00:01 [32m+440[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset preset absent => error[0m                                                                                               
00:01 [32m+440[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset deux areas même preset absent => deux diagnostics[0m                                                                    
00:01 [32m+441[0m: test/environment_layer_usage_diagnostics_test.dart: missingAreaPreset deux areas même preset absent => deux diagnostics[0m                                                                    
00:01 [32m+441[0m: test/environment_layer_usage_diagnostics_test.dart: missingTargetTileLayerId sans area => pas de warning[0m                                                                                   
00:01 [32m+442[0m: test/environment_layer_usage_diagnostics_test.dart: missingTargetTileLayerId sans area => pas de warning[0m                                                                                   
00:01 [32m+442[0m: test/environment_layer_usage_diagnostics_test.dart: missingTargetTileLayerId avec area sans target => warning[0m                                                                              
00:01 [32m+443[0m: test/environment_layer_usage_diagnostics_test.dart: missingTargetTileLayerId avec area sans target => warning[0m                                                                              
00:01 [32m+443[0m: test/environment_layer_usage_diagnostics_test.dart: unknownTargetTileLayer TileLayer existant => rien[0m                                                                                      
00:01 [32m+444[0m: test/environment_layer_usage_diagnostics_test.dart: unknownTargetTileLayer TileLayer existant => rien[0m                                                                                      
00:01 [32m+444[0m: test/environment_layer_usage_diagnostics_test.dart: unknownTargetTileLayer cible inexistante => error[0m                                                                                      
00:01 [32m+445[0m: test/environment_layer_usage_diagnostics_test.dart: unknownTargetTileLayer cible inexistante => error[0m                                                                                      
00:01 [32m+445[0m: test/environment_layer_usage_diagnostics_test.dart: targetLayerIsNotTileLayer ObjectLayer => error[0m                                                                                         
00:01 [32m+446[0m: test/environment_layer_usage_diagnostics_test.dart: targetLayerIsNotTileLayer ObjectLayer => error[0m                                                                                         
00:01 [32m+446[0m: test/environment_layer_usage_diagnostics_test.dart: targetLayerIsNotTileLayer self EnvironmentLayer => error[0m                                                                               
00:01 [32m+447[0m: test/environment_layer_usage_diagnostics_test.dart: targetLayerIsNotTileLayer self EnvironmentLayer => error[0m                                                                               
00:01 [32m+447[0m: test/environment_layer_usage_diagnostics_test.dart: areaMaskSizeMismatch taille ok => rien[0m                                                                                                 
00:01 [32m+448[0m: test/environment_layer_usage_diagnostics_test.dart: areaMaskSizeMismatch taille ok => rien[0m                                                                                                 
00:01 [32m+448[0m: test/environment_layer_usage_diagnostics_test.dart: areaMaskSizeMismatch width différent[0m                                                                                                   
00:01 [32m+449[0m: test/environment_layer_usage_diagnostics_test.dart: areaMaskSizeMismatch width différent[0m                                                                                                   
00:01 [32m+449[0m: test/environment_layer_usage_diagnostics_test.dart: areaMaskSizeMismatch height différent[0m                                                                                                  
00:01 [32m+450[0m: test/environment_layer_usage_diagnostics_test.dart: areaMaskSizeMismatch height différent[0m                                                                                                  
00:01 [32m+450[0m: [1m[90mloading test/surface_layer_placements_test.dart[0m[0m                                                                                                                                            
00:01 [32m+450[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations identifies SurfaceLayer and exposes its sparse placements[0m                                                       
00:01 [32m+451[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations identifies SurfaceLayer and exposes its sparse placements[0m                                                       
00:01 [32m+452[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations identifies SurfaceLayer and exposes its sparse placements[0m                                                       
00:01 [32m+453[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations identifies SurfaceLayer and exposes its sparse placements[0m                                                       
00:01 [32m+454[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations identifies SurfaceLayer and exposes its sparse placements[0m                                                       
00:01 [32m+455[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations identifies SurfaceLayer and exposes its sparse placements[0m                                                       
00:01 [32m+456[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations identifies SurfaceLayer and exposes its sparse placements[0m                                                       
00:01 [32m+457[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations identifies SurfaceLayer and exposes its sparse placements[0m                                                       
00:01 [32m+457[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations paintSurfacePlacement adds a placement and trims the preset id[0m                                                  
00:01 [32m+458[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations paintSurfacePlacement adds a placement and trims the preset id[0m                                                  
00:01 [32m+458[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations paintSurfacePlacement replaces an existing placement at the same cell[0m                                           
00:01 [32m+459[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations paintSurfacePlacement replaces an existing placement at the same cell[0m                                           
00:01 [32m+459[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations paintSurfacePlacement accepts different presets at different cells[0m                                              
00:01 [32m+460[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations paintSurfacePlacement accepts different presets at different cells[0m                                              
00:01 [32m+460[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations paintSurfacePlacement refuses coordinates outside the map[0m                                                       
00:01 [32m+461[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations paintSurfacePlacement refuses coordinates outside the map[0m                                                       
00:01 [32m+461[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations paintSurfacePlacement refuses an empty surfacePresetId[0m                                                          
00:01 [32m+462[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations paintSurfacePlacement refuses an empty surfacePresetId[0m                                                          
00:01 [32m+462[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations eraseSurfacePlacement removes an existing placement[0m                                                             
00:01 [32m+463[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual defaults to background entity rendering[0m                                                                                     
00:01 [32m+464[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual defaults to background entity rendering[0m                                                                                     
00:01 [32m+465[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual defaults to background entity rendering[0m                                                                                     
00:01 [32m+466[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual defaults to background entity rendering[0m                                                                                     
00:01 [32m+467[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual defaults to background entity rendering[0m                                                                                     
00:01 [32m+468[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual defaults to background entity rendering[0m                                                                                     
00:01 [32m+469[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual defaults to background entity rendering[0m                                                                                     
00:01 [32m+470[0m: test/surface_layer_placements_test.dart: SurfaceLayer placement operations generic MapLayer helpers tolerate SurfaceLayer[0m                                                                  
00:01 [32m+471[0m: test/map_entity_editor_visual_test.dart: MapEntityEditorVisual serializes and exposes the foreground render flag[0m                                                                           
00:01 [32m+472[0m: test/project_manifest_storylines_test.dart: ProjectManifest storylines integration decodes old project JSON without storylines as empty list[0m                                               
00:01 [32m+473[0m: test/project_manifest_storylines_test.dart: ProjectManifest storylines integration decodes old project JSON without storylines as empty list[0m                                               
00:01 [32m+473[0m: test/project_manifest_storylines_test.dart: ProjectManifest storylines integration decodes project JSON with main and side quest storylines[0m                                                
00:01 [32m+474[0m: test/scene_asset_test.dart: SceneAsset construction accepts a minimal scene with start and end nodes[0m                                                                                       
00:01 [32m+475[0m: test/scene_asset_test.dart: SceneAsset construction accepts a minimal scene with start and end nodes[0m                                                                                       
00:01 [32m+476[0m: test/scene_asset_test.dart: SceneAsset construction accepts a minimal scene with start and end nodes[0m                                                                                       
00:01 [32m+476[0m: test/project_manifest_storylines_test.dart: ProjectManifest storylines integration does not import legacy globalStory scenarios automatically[0m                                              
00:01 [32m+477[0m: test/project_manifest_storylines_test.dart: ProjectManifest storylines integration does not import legacy globalStory scenarios automatically[0m                                              
00:01 [32m+478[0m: test/project_manifest_storylines_test.dart: ProjectManifest storylines integration does not import legacy globalStory scenarios automatically[0m                                              
00:01 [32m+479[0m: test/scene_asset_test.dart: SceneAsset validation rejects blank core identifiers and names[0m                                                                                                 
00:01 [32m+480[0m: test/project_manifest_storylines_test.dart: ProjectManifest storylines integration does not promote localEventFlow scenario to side quest[0m                                                  
00:01 [32m+481[0m: test/scene_asset_test.dart: SceneAsset validation rejects duplicate graph, layout and outcome ids[0m                                                                                          
00:01 [32m+482[0m: test/project_manifest_storylines_test.dart: ProjectManifest storylines integration rejects invalid storylines JSON shape[0m                                                                   
00:01 [32m+483[0m: test/project_manifest_storylines_test.dart: ProjectManifest storylines integration rejects invalid storylines JSON shape[0m                                                                   
00:01 [32m+484[0m: test/project_manifest_storylines_test.dart: ProjectManifest storylines integration rejects invalid storylines JSON shape[0m                                                                   
00:01 [32m+485[0m: test/scene_asset_test.dart: SceneAsset authoring guarantees keeps ids stable when user-facing names are renamed[0m                                                                            
00:01 [32m+486[0m: test/scene_asset_test.dart: SceneAsset authoring guarantees keeps ids stable when user-facing names are renamed[0m                                                                            
00:01 [32m+486[0m: test/scene_asset_test.dart: SceneAsset authoring guarantees keeps metadata non-critical and string-only[0m                                                                                    
00:01 [32m+487[0m: test/scene_asset_test.dart: SceneAsset authoring guarantees keeps metadata non-critical and string-only[0m                                                                                    
00:01 [32m+487[0m: [1m[90mloading test/project_surface_animation_test.dart[0m[0m                                                                                                                                           
00:01 [32m+487[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation minimal animation: fields and delegation[0m                                                                                 
00:01 [32m+488[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation minimal animation: fields and delegation[0m                                                                                 
00:01 [32m+488[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation preserves the exact same timeline instance[0m                                                                               
00:01 [32m+489[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation preserves the exact same timeline instance[0m                                                                               
00:01 [32m+489[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation preserves syncGroupId, categoryId, sortOrder[0m                                                                             
00:01 [32m+490[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation preserves syncGroupId, categoryId, sortOrder[0m                                                                             
00:01 [32m+490[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation stores id, name, syncGroupId strings exactly without auto-trim[0m                                                           
00:01 [32m+491[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation stores id, name, syncGroupId strings exactly without auto-trim[0m                                                           
00:01 [32m+491[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects empty id: empty string[0m                                                                                           
00:01 [32m+492[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects empty id: empty string[0m                                                                                           
00:01 [32m+492[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects empty id: whitespace only[0m                                                                                        
00:01 [32m+493[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects empty id: whitespace only[0m                                                                                        
00:01 [32m+493[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects empty name: empty string[0m                                                                                         
00:01 [32m+494[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects empty name: empty string[0m                                                                                         
00:01 [32m+494[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects empty name: whitespace only[0m                                                                                      
00:01 [32m+495[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects empty name: whitespace only[0m                                                                                      
00:01 [32m+495[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects non-null syncGroupId that is only whitespace: empty[0m                                                              
00:01 [32m+496[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects non-null syncGroupId that is only whitespace: empty[0m                                                              
00:01 [32m+496[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects non-null syncGroupId that is only whitespace: spaces[0m                                                             
00:01 [32m+497[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation rejects non-null syncGroupId that is only whitespace: spaces[0m                                                             
00:01 [32m+497[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation allows syncGroupId == null[0m                                                                                               
00:01 [32m+498[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation allows syncGroupId == null[0m                                                                                               
00:01 [32m+498[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation categoryId: accepts empty and whitespace (ProjectSurfaceAtlas policy)[0m                                                    
00:01 [32m+499[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation categoryId: accepts empty and whitespace (ProjectSurfaceAtlas policy)[0m                                                    
00:01 [32m+499[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation sortOrder: preserves negative value[0m                                                                                      
00:01 [32m+500[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation sortOrder: preserves negative value[0m                                                                                      
00:01 [32m+500[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation frameCount delegates to timeline (3 frames)[0m                                                                              
00:01 [32m+501[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation frameCount delegates to timeline (3 frames)[0m                                                                              
00:01 [32m+501[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation totalDurationMs delegates: 50 + 100 + 150 = 300[0m                                                                          
00:01 [32m+502[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation totalDurationMs delegates: 50 + 100 + 150 = 300[0m                                                                          
00:01 [32m+502[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation isInside: true when all tiles inside grid[0m                                                                                
00:01 [32m+503[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation isInside: true when all tiles inside grid[0m                                                                                
00:01 [32m+503[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation isInside: false when one frame out of grid[0m                                                                               
00:01 [32m+504[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation isInside: false when one frame out of grid[0m                                                                               
00:01 [32m+504[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation isInside: independent of SurfaceAtlasLayout[0m                                                                              
00:01 [32m+505[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation isInside: independent of SurfaceAtlasLayout[0m                                                                              
00:01 [32m+505[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: same values => equal and same hash[0m                                                                       
00:01 [32m+506[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: same values => equal and same hash[0m                                                                       
00:01 [32m+506[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: id differs[0m                                                                                               
00:01 [32m+507[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: id differs[0m                                                                                               
00:01 [32m+507[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: name differs[0m                                                                                             
00:01 [32m+508[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: name differs[0m                                                                                             
00:01 [32m+508[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: timeline differs (duration)[0m                                                                              
00:01 [32m+509[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: timeline differs (duration)[0m                                                                              
00:01 [32m+509[0m: test/project_surface_animation_test.dart: ProjectSurfaceAnimation value equality: syncGroupId differs[0m                                                                                      
00:01 [32m+510[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation[0m                                                
00:01 [32m+511[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation[0m                                                
00:01 [32m+512[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation[0m                                                
00:01 [32m+513[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation[0m                                                
00:01 [32m+514[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation[0m                                                
00:01 [32m+515[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation[0m                                                
00:01 [32m+516[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 1. encodes minimal ProjectSurfaceAnimation[0m                                                
00:01 [32m+516[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 2. decodes minimal ProjectSurfaceAnimation[0m                                                
00:01 [32m+517[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 2. decodes minimal ProjectSurfaceAnimation[0m                                                
00:01 [32m+517[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 3. round-trip minimal animation[0m                                                           
00:01 [32m+518[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 3. round-trip minimal animation[0m                                                           
00:01 [32m+518[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 4. encodes full animation (sync, category, sort)[0m                                          
00:01 [32m+519[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 4. encodes full animation (sync, category, sort)[0m                                          
00:01 [32m+519[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 5. decodes full animation[0m                                                                 
00:01 [32m+520[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+521[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+522[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+523[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+524[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+525[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+526[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+527[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+528[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+529[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+530[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+531[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+532[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+533[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+534[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+535[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+536[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 1. encodes one-frame timeline[0m                                                           
00:01 [32m+536[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 21. decode accepts sortOrder absent (default 0)[0m                                           
00:01 [32m+537[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 2. decodes one-frame timeline[0m                                                           
00:01 [32m+538[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 2. decodes one-frame timeline[0m                                                           
00:01 [32m+539[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 2. decodes one-frame timeline[0m                                                           
00:01 [32m+540[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 24. decode does not mutate source map[0m                                                     
00:01 [32m+541[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 24. decode does not mutate source map[0m                                                     
00:01 [32m+542[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 4. encodes multi-frame timeline (order + durations)[0m                                     
00:01 [32m+543[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 4. encodes multi-frame timeline (order + durations)[0m                                     
00:01 [32m+544[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 26. no geometry in codec; isInside is separate[0m                                            
00:01 [32m+545[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 26. no geometry in codec; isInside is separate[0m                                            
00:01 [32m+546[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 6. round-trip multi-frame timeline[0m                                                      
00:01 [32m+547[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 27. no external resolution of atlasId[0m                                                     
00:01 [32m+548[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 7. decode preserves exact nested atlasId string[0m                                         
00:01 [32m+549[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 28. public API encode returns Map[0m                                                         
00:01 [32m+550[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 8. reject frames key missing[0m                                                            
00:01 [32m+551[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                              
00:01 [32m+552[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                              
00:01 [32m+553[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                              
00:01 [32m+554[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                              
00:01 [32m+555[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                              
00:01 [32m+556[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                              
00:01 [32m+557[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                              
00:01 [32m+558[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                              
00:01 [32m+559[0m: test/project_surface_animation_json_codec_test.dart: ProjectSurfaceAnimation JSON codec (Lot 42) 29. ProjectManifest has no surface persistence keys (Lot 42)[0m                              
00:01 [32m+560[0m: test/project_path_preset_center_pattern_adapter_test.dart: createLegacyProjectPathPresetCenterPatternView uses cross by default and creates a 1x1 center pattern[0m                           
00:01 [32m+561[0m: test/project_path_preset_center_pattern_adapter_test.dart: createLegacyProjectPathPresetCenterPatternView uses cross by default and creates a 1x1 center pattern[0m                           
00:01 [32m+562[0m: test/project_path_preset_center_pattern_adapter_test.dart: createLegacyProjectPathPresetCenterPatternView uses cross by default and creates a 1x1 center pattern[0m                           
00:01 [32m+563[0m: test/project_path_preset_center_pattern_adapter_test.dart: createLegacyProjectPathPresetCenterPatternView uses cross by default and creates a 1x1 center pattern[0m                           
00:01 [32m+564[0m: test/project_path_preset_center_pattern_adapter_test.dart: createLegacyProjectPathPresetCenterPatternView uses cross by default and creates a 1x1 center pattern[0m                           
00:01 [32m+565[0m: test/project_path_preset_center_pattern_adapter_test.dart: createLegacyProjectPathPresetCenterPatternView uses cross by default and creates a 1x1 center pattern[0m                           
00:01 [32m+566[0m: test/project_path_preset_center_pattern_adapter_test.dart: createLegacyProjectPathPresetCenterPatternView uses cross by default and creates a 1x1 center pattern[0m                           
00:01 [32m+567[0m: test/project_path_preset_center_pattern_adapter_test.dart: createLegacyProjectPathPresetCenterPatternView uses cross by default and creates a 1x1 center pattern[0m                           
00:01 [32m+568[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 21. ProjectManifest has no surface persistence keys (Lot 41)[0m                            
00:01 [32m+569[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 21. ProjectManifest has no surface persistence keys (Lot 41)[0m                            
00:01 [32m+570[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 21. ProjectManifest has no surface persistence keys (Lot 41)[0m                            
00:01 [32m+571[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 21. ProjectManifest has no surface persistence keys (Lot 41)[0m                            
00:01 [32m+571[0m: test/project_path_preset_center_pattern_adapter_test.dart: createLegacyProjectPathPresetCenterPatternView preserves frame order and durations[0m                                              
00:01 [32m+572[0m: test/surface_animation_timeline_json_codec_test.dart: SurfaceAnimationTimeline JSON codec (Lot 41) 22. codec external to model: no timeline toJson or SurfaceAnimationTimeline.fromJson[0m    
00:01 [32m+573[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks does not report a step with no scene links[0m                                                                    
00:01 [32m+574[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks does not report a step with no scene links[0m                                                                    
00:01 [32m+575[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks does not report a step with no scene links[0m                                                                    
00:01 [32m+576[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks does not report a step with no scene links[0m                                                                    
00:01 [32m+577[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks does not report a step with no scene links[0m                                                                    
00:01 [32m+578[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks does not report a step with no scene links[0m                                                                    
00:01 [32m+579[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks does not report a step with no scene links[0m                                                                    
00:01 [32m+580[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks does not report a step with no scene links[0m                                                                    
00:01 [32m+581[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks does not report a step with no scene links[0m                                                                    
00:01 [32m+581[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks accepts known scene links[0m                                                                                     
00:01 [32m+582[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks accepts known scene links[0m                                                                                     
00:01 [32m+582[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks reports unknown scene links as errors[0m                                                                         
00:01 [32m+583[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks reports unknown scene links as errors[0m                                                                         
00:01 [32m+583[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks warns when a linked scene has scene diagnostics errors[0m                                                        
00:01 [32m+584[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks warns when a linked scene has scene diagnostics errors[0m                                                        
00:01 [32m+584[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks warns when a linked scene cannot build a runtime plan[0m                                                         
00:01 [32m+585[0m: test/storyline_scene_link_diagnostics_test.dart: diagnoseStorylineSceneLinks warns when a linked scene cannot build a runtime plan[0m                                                         
00:01 [32m+585[0m: [1m[90mloading test/terrain_path_variant_vertical_atlas_layout_test.dart[0m[0m                                                                                                                          
00:01 [32m+585[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:01 [32m+586[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder covers exactly the TerrainPathVariant enum values once[0m                             
00:01 [32m+586[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder uses the explicit V0 atlas order[0m                                                   
00:01 [32m+587[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: standardTerrainPathVariantVerticalAtlasOrder uses the explicit V0 atlas order[0m                                                   
00:01 [32m+587[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns generates columns from zero[0m                                                
00:01 [32m+588[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns generates columns from zero[0m                                                
00:01 [32m+588[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns respects firstColumn[0m                                                       
00:01 [32m+589[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns respects firstColumn[0m                                                       
00:01 [32m+589[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns respects startRow[0m                                                          
00:01 [32m+590[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns respects startRow[0m                                                          
00:01 [32m+590[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns generates a sub-layout[0m                                                     
00:01 [32m+591[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns generates a sub-layout[0m                                                     
00:01 [32m+591[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns generates a sub-layout with firstColumn[0m                                    
00:01 [32m+592[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns generates a sub-layout with firstColumn[0m                                    
00:01 [32m+592[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns returns an unmodifiable list[0m                                               
00:01 [32m+593[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns returns an unmodifiable list[0m                                               
00:01 [32m+593[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns is compatible with createPathVariantMappingsFromVerticalAtlas[0m              
00:01 [32m+594[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns is compatible with createPathVariantMappingsFromVerticalAtlas[0m              
00:01 [32m+594[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns is compatible with createProjectPathPresetFromVerticalAtlas[0m                
00:01 [32m+595[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns is compatible with createProjectPathPresetFromVerticalAtlas[0m                
00:01 [32m+595[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns rejects negative firstColumn[0m                                               
00:01 [32m+596[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns rejects negative firstColumn[0m                                               
00:01 [32m+596[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns rejects negative startRow[0m                                                  
00:01 [32m+597[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns rejects negative startRow[0m                                                  
00:01 [32m+597[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns rejects empty variants[0m                                                     
00:01 [32m+598[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns rejects empty variants[0m                                                     
00:01 [32m+598[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns rejects duplicate variants[0m                                                 
00:01 [32m+599[0m: test/terrain_path_variant_vertical_atlas_layout_test.dart: createStandardTerrainPathVariantVerticalAtlasColumns rejects duplicate variants[0m                                                 
00:01 [32m+599[0m: [1m[90mloading test/surface_atlas_tile_ref_test.dart[0m[0m                                                                                                                                              
00:01 [32m+599[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:01 [32m+600[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef minimal ref holds fields[0m                                                                                                        
00:01 [32m+600[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef stores atlasId exactly without trimming the stored value[0m                                                                        
00:01 [32m+601[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef stores atlasId exactly without trimming the stored value[0m                                                                        
00:01 [32m+601[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects empty atlasId: empty string[0m                                                                                             
00:01 [32m+602[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects empty atlasId: empty string[0m                                                                                             
00:01 [32m+602[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects empty atlasId: whitespace only[0m                                                                                          
00:01 [32m+603[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects empty atlasId: whitespace only[0m                                                                                          
00:01 [32m+603[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects negative column[0m                                                                                                         
00:01 [32m+604[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects negative column[0m                                                                                                         
00:01 [32m+604[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects negative row[0m                                                                                                            
00:01 [32m+605[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef rejects negative row[0m                                                                                                            
00:01 [32m+605[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef accepts column and row zero[0m                                                                                                     
00:01 [32m+606[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef accepts column and row zero[0m                                                                                                     
00:01 [32m+606[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: true for interior cells[0m                                                                                               
00:01 [32m+607[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: true for interior cells[0m                                                                                               
00:01 [32m+607[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: false when out of grid[0m                                                                                                
00:01 [32m+608[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: false when out of grid[0m                                                                                                
00:01 [32m+608[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: same column/row independent of layout enum[0m                                                                            
00:01 [32m+609[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef isInside: same column/row independent of layout enum[0m                                                                            
00:01 [32m+609[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef value equality: same values and hashCode[0m                                                                                        
00:01 [32m+610[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef value equality: same values and hashCode[0m                                                                                        
00:01 [32m+610[0m: test/surface_atlas_tile_ref_test.dart: SurfaceAtlasTileRef value equality: atlasId differs[0m                                                                                                 
00:01 [32m+611[0m: test/storyline_asset_json_test.dart: StorylineAsset JSON roundtrip round-trips minimal main draft[0m                                                                                          
00:01 [32m+612[0m: test/storyline_asset_json_test.dart: StorylineAsset JSON roundtrip round-trips minimal main draft[0m                                                                                          
00:01 [32m+613[0m: test/storyline_asset_json_test.dart: StorylineAsset JSON roundtrip round-trips minimal main draft[0m                                                                                          
00:01 [32m+614[0m: test/storyline_asset_json_test.dart: StorylineAsset JSON roundtrip round-trips minimal main draft[0m                                                                                          
00:01 [32m+615[0m: test/storyline_asset_json_test.dart: StorylineAsset JSON roundtrip round-trips minimal main draft[0m                                                                                          
00:01 [32m+616[0m: test/storyline_asset_json_test.dart: StorylineAsset JSON roundtrip round-trips minimal main draft[0m                                                                                          
00:01 [32m+616[0m: test/storyline_asset_json_test.dart: StorylineAsset JSON roundtrip round-trips minimal side quest draft[0m                                                                                    
00:01 [32m+617[0m: test/storyline_asset_json_test.dart: StorylineAsset JSON roundtrip round-trips minimal side quest draft[0m                                                                                    
00:01 [32m+617[0m: test/storyline_asset_json_test.dart: StorylineAsset JSON roundtrip round-trips complete authoring shape[0m                                                                                    
00:01 [32m+618[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order[0m                        
00:01 [32m+619[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order[0m                        
00:01 [32m+620[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order[0m                        
00:01 [32m+621[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order[0m                        
00:01 [32m+622[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order[0m                        
00:01 [32m+623[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations read returns the manifest pathPatternPresets in order[0m                        
00:01 [32m+624[0m: test/storyline_asset_json_test.dart: StorylineAsset JSON constructor validation rejects scene link references to missing chapter or step[0m                                                   
00:01 [32m+625[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations replace swaps the list, preserves other fields, and keeps order[0m              
00:01 [32m+626[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations replace swaps the list, preserves other fields, and keeps order[0m              
00:01 [32m+627[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames generates frames with correct vertical positions[0m                           
00:01 [32m+628[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames generates frames with correct vertical positions[0m                           
00:01 [32m+629[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames generates frames with correct vertical positions[0m                           
00:01 [32m+630[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames generates frames with correct vertical positions[0m                           
00:01 [32m+631[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames generates frames with correct vertical positions[0m                           
00:01 [32m+632[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames generates frames with correct vertical positions[0m                           
00:01 [32m+633[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames generates frames with correct vertical positions[0m                           
00:01 [32m+634[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations remove deletes an existing id and preserves order[0m                            
00:01 [32m+635[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas simple vertical frames respects startRow parameter[0m                                                
00:01 [32m+636[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations remove missing id is a no-op with an equivalent new manifest[0m                 
00:01 [32m+637[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations remove missing id is a no-op with an equivalent new manifest[0m                 
00:01 [32m+638[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations remove missing id is a no-op with an equivalent new manifest[0m                 
00:01 [32m+639[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations remove missing id is a no-op with an equivalent new manifest[0m                 
00:01 [32m+640[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas frame durations applies per-frame durations[0m                                                       
00:01 [32m+641[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas frame durations applies per-frame durations[0m                                                       
00:01 [32m+641[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations remove rejects blank ids and duplicate matching ids[0m                          
00:01 [32m+642[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations remove rejects blank ids and duplicate matching ids[0m                          
00:01 [32m+643[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas immutability returns unmodifiable list[0m                                                            
00:01 [32m+644[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas immutability returns unmodifiable list[0m                                                            
00:01 [32m+645[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations lookup helpers find exact ids, report missing ids, and reject blanks[0m         
00:01 [32m+646[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas immutability does not mutate input frameDurationsMs[0m                                               
00:01 [32m+647[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations lookup helpers reject duplicate exact ids[0m                                    
00:01 [32m+648[0m: test/tile_visual_frame_vertical_atlas_test.dart: createTileVisualFramesFromVerticalAtlas compatibility with timeline resolver generated frames work with resolveTileVisualFrameTimeline[0m    
00:01 [32m+649[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations operations keep pathPatternPresets JSON stable[0m                               
00:01 [32m+650[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations operations keep pathPatternPresets JSON stable[0m                               
00:01 [32m+651[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations operations keep pathPatternPresets JSON stable[0m                               
00:01 [32m+652[0m: test/project_manifest_path_pattern_preset_operations_test.dart: ProjectManifest PathPattern preset operations operations keep pathPatternPresets JSON stable[0m                               
00:01 [32m+653[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+654[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+655[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+656[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+657[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+658[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+659[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+660[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+661[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+662[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+663[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+664[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 1x1 always resolves to the single local cell[0m                                                                     
00:01 [32m+664[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size[0m                                                            
00:01 [32m+665[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell 2x2 uses absolute map coordinates modulo pattern size[0m                                                            
00:01 [32m+665[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns[0m                                                                  
00:01 [32m+666[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell rectangular 3x2 does not assume square patterns[0m                                                                  
00:01 [32m+666[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates[0m                                                             
00:01 [32m+667[0m: test/path_center_pattern_resolver_test.dart: resolvePathCenterPatternCell invalid coordinates rejects negative map coordinates[0m                                                             
00:01 [32m+667[0m: test/path_center_pattern_resolver_test.dart: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell[0m                                                   
00:01 [32m+668[0m: test/path_center_pattern_resolver_test.dart: PathCenterPatternCellResolution keeps map coordinates, local coordinates, and selected cell[0m                                                   
00:01 [32m+668[0m: test/path_center_pattern_resolver_test.dart: PathCenterPatternCellResolution uses value equality and stable hashCode[0m                                                                       
00:01 [32m+669[0m: test/path_center_pattern_resolver_test.dart: PathCenterPatternCellResolution uses value equality and stable hashCode[0m                                                                       
00:01 [32m+669[0m: [1m[90mloading test/narrative_validator_authoring_adapter_test.dart[0m[0m                                                                                                                               
00:01 [32m+669[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps declaredOutcomeNeverEmitted to outcome authoring view[0m                                     
00:01 [32m+670[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps declaredOutcomeNeverEmitted to outcome authoring view[0m                                     
00:01 [32m+670[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps emitOutcomeNotDeclared to outcome authoring view[0m                                          
00:01 [32m+671[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps emitOutcomeNotDeclared to outcome authoring view[0m                                          
00:01 [32m+671[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps predicate diagnostics to predicate authoring views[0m                                        
00:01 [32m+672[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps predicate diagnostics to predicate authoring views[0m                                        
00:01 [32m+672[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps unsupported choice node to runtime support view[0m                                           
00:01 [32m+673[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps unsupported choice node to runtime support view[0m                                           
00:01 [32m+673[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter preserves severity and technical context fields[0m                                                
00:01 [32m+674[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter preserves severity and technical context fields[0m                                                
00:01 [32m+674[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps trainer battle diagnostics to trainer battle reference view[0m                               
00:01 [32m+675[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps trainer battle diagnostics to trainer battle reference view[0m                               
00:01 [32m+675[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps unmapped diagnostics to unknown without automatic fix[0m                                     
00:01 [32m+676[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter maps unmapped diagnostics to unknown without automatic fix[0m                                     
00:01 [32m+676[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter builds stable immutable lists without auto-fix metadata[0m                                        
00:01 [32m+677[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter builds stable immutable lists without auto-fix metadata[0m                                        
00:01 [32m+677[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter does not hardcode Selbrume identifiers[0m                                                         
00:01 [32m+678[0m: test/narrative_validator_authoring_adapter_test.dart: Narrative validator authoring adapter does not hardcode Selbrume identifiers[0m                                                         
00:01 [32m+678[0m: [1m[90mloading test/surface_variant_role_test.dart[0m[0m                                                                                                                                                
00:01 [32m+678[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:01 [32m+679[0m: test/surface_variant_role_test.dart: SurfaceVariantRole SurfaceVariantRole.values is exactly the expected order[0m                                                                            
00:01 [32m+679[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standardSurfaceVariantRoleOrder matches expected explicit list[0m                                                                     
00:01 [32m+680[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standardSurfaceVariantRoleOrder matches expected explicit list[0m                                                                     
00:01 [32m+680[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standard list covers all enum values once (set + length)[0m                                                                           
00:01 [32m+681[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standard list covers all enum values once (set + length)[0m                                                                           
00:01 [32m+681[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standardSurfaceVariantRoleOrder is not growable (const list)[0m                                                                       
00:01 [32m+682[0m: test/surface_variant_role_test.dart: SurfaceVariantRole standardSurfaceVariantRoleOrder is not growable (const list)[0m                                                                       
00:01 [32m+682[0m: test/surface_variant_role_test.dart: SurfaceVariantRole export: types from map_core only[0m                                                                                                   
00:01 [32m+683[0m: test/surface_variant_role_test.dart: SurfaceVariantRole export: types from map_core only[0m                                                                                                   
00:01 [32m+683[0m: test/surface_variant_role_test.dart: SurfaceVariantRole ProjectManifest toJson: no surface* top-level keys[0m                                                                                 
00:01 [32m+684[0m: test/tall_grass_model_characterization_test.dart: Tall grass model characterization uses terrain visuals and encounter zones as separate contracts[0m                                         
00:01 [32m+685[0m: test/tall_grass_model_characterization_test.dart: Tall grass model characterization uses terrain visuals and encounter zones as separate contracts[0m                                         
00:01 [32m+686[0m: test/surface_variant_animation_ref_set_json_codec_test.dart: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 1. encodes set with one isolated ref[0m                                        
00:01 [32m+687[0m: test/surface_variant_animation_ref_set_json_codec_test.dart: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 1. encodes set with one isolated ref[0m                                        
00:01 [32m+687[0m: test/surface_variant_animation_ref_set_json_codec_test.dart: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 2. decodes set with one ref[0m                                                 
00:01 [32m+688[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+689[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+690[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+691[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+692[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+693[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+694[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+695[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+696[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+697[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+698[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+699[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+700[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+701[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+702[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes legacy placed element JSON without shadowOverride as null[0m                               
00:01 [32m+703[0m: test/surface_variant_animation_ref_set_json_codec_test.dart: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 17. decode ignores unknown key in ref item[0m                                  
00:01 [32m+704[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes null, inherit, disabled, and custom overrides[0m                                           
00:01 [32m+705[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes null, inherit, disabled, and custom overrides[0m                                           
00:01 [32m+706[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes null, inherit, disabled, and custom overrides[0m                                           
00:01 [32m+707[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON decodes null, inherit, disabled, and custom overrides[0m                                           
00:01 [32m+708[0m: test/surface_variant_animation_ref_set_json_codec_test.dart: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 21. does not complete missing roles[0m                                         
00:01 [32m+709[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON encodes non-null and null shadowOverride using existing style[0m                                   
00:01 [32m+710[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON encodes non-null and null shadowOverride using existing style[0m                                   
00:01 [32m+711[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON encodes non-null and null shadowOverride using existing style[0m                                   
00:01 [32m+712[0m: test/surface_variant_animation_ref_set_json_codec_test.dart: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 24. ProjectManifest has no surface persistence keys (Lot 44)[0m                
00:01 [32m+713[0m: test/surface_variant_animation_ref_set_json_codec_test.dart: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 24. ProjectManifest has no surface persistence keys (Lot 44)[0m                
00:01 [32m+714[0m: test/surface_variant_animation_ref_set_json_codec_test.dart: SurfaceVariantAnimationRefSet JSON codec (Lot 44) 24. ProjectManifest has no surface persistence keys (Lot 44)[0m                
00:01 [32m+715[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON MapData JSON preserves placed element shadowOverride[0m                                            
00:01 [32m+716[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON MapData JSON preserves placed element shadowOverride[0m                                            
00:01 [32m+717[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON MapData JSON preserves placed element shadowOverride[0m                                            
00:01 [32m+718[0m: test/shadow/map_placed_element_shadow_json_test.dart: MapPlacedElement shadowOverride JSON MapData JSON preserves placed element shadowOverride[0m                                            
00:01 [32m+719[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig base behavior elementShadow null and override null yields no shadow[0m                                                      
00:01 [32m+720[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig base behavior elementShadow null and override null yields no shadow[0m                                                      
00:01 [32m+721[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig base behavior elementShadow null and override null yields no shadow[0m                                                      
00:01 [32m+722[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig base behavior elementShadow null and override null yields no shadow[0m                                                      
00:01 [32m+722[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig base behavior castsShadow false and override null yields no shadow[0m                                                       
00:01 [32m+723[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig base behavior castsShadow false and override null yields no shadow[0m                                                       
00:01 [32m+723[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig base behavior castsShadow true with existing profile resolves profile fields[0m                                             
00:01 [32m+724[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig base behavior castsShadow true with existing profile resolves profile fields[0m                                             
00:01 [32m+724[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig base behavior profile mode none yields no shadow and no diagnostics[0m                                                      
00:01 [32m+725[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig base behavior profile mode none yields no shadow and no diagnostics[0m                                                      
00:01 [32m+725[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig element overrides element overrides replace profile numeric fields[0m                                                       
00:01 [32m+726[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig element overrides element overrides replace profile numeric fields[0m                                                       
00:01 [32m+726[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig element overrides partial element overrides preserve profile fallback values[0m                                             
00:01 [32m+727[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig element overrides partial element overrides preserve profile fallback values[0m                                             
00:01 [32m+727[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig inherit and disabled overrides placedOverride null and inherit are equivalent[0m                                            
00:01 [32m+728[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig inherit and disabled overrides placedOverride null and inherit are equivalent[0m                                            
00:01 [32m+728[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig inherit and disabled overrides disabled always wins and emits no diagnostics[0m                                             
00:01 [32m+729[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig inherit and disabled overrides disabled always wins and emits no diagnostics[0m                                             
00:01 [32m+729[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig custom instance overrides custom shadowProfileId replaces the element profile[0m                                            
00:01 [32m+730[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig custom instance overrides custom shadowProfileId replaces the element profile[0m                                            
00:01 [32m+730[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig custom instance overrides custom numeric overrides replace values after element overrides[0m                                
00:01 [32m+731[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig custom instance overrides custom numeric overrides replace values after element overrides[0m                                
00:01 [32m+731[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig custom instance overrides custom partial overrides keep remaining element/profile values[0m                                 
00:01 [32m+732[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig custom instance overrides custom partial overrides keep remaining element/profile values[0m                                 
00:01 [32m+732[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig custom instance overrides custom without profile keeps the element profile[0m                                               
00:01 [32m+733[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig custom instance overrides custom without profile keeps the element profile[0m                                               
00:01 [32m+733[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig custom instance overrides custom with profile can activate when element has no active shadow[0m                             
00:01 [32m+734[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig custom instance overrides custom with profile can activate when element has no active shadow[0m                             
00:01 [32m+734[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig diagnostics missing element profile produces missingShadowProfile diagnostic[0m                                             
00:01 [32m+735[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig diagnostics missing element profile produces missingShadowProfile diagnostic[0m                                             
00:01 [32m+735[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig diagnostics missing custom override profile produces missingShadowProfile[0m                                                
00:01 [32m+736[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig diagnostics missing custom override profile produces missingShadowProfile[0m                                                
00:01 [32m+736[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig diagnostics custom numeric override without base produces diagnostic[0m                                                     
00:01 [32m+737[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig diagnostics custom numeric override without base produces diagnostic[0m                                                     
00:01 [32m+737[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig diagnostics empty custom override without base is none without diagnostics[0m                                               
00:01 [32m+738[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig diagnostics empty custom override without base is none without diagnostics[0m                                               
00:01 [32m+738[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig diagnostics diagnostics list is immutable[0m                                                                                
00:01 [32m+739[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig diagnostics diagnostics list is immutable[0m                                                                                
00:01 [32m+739[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig value equality ResolvedShadowConfig equality and hashCode[0m                                                                
00:01 [32m+740[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig value equality ResolvedShadowConfig equality and hashCode[0m                                                                
00:01 [32m+740[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig value equality ShadowConfigResolution equality and hashCode[0m                                                              
00:01 [32m+741[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig value equality ShadowConfigResolution equality and hashCode[0m                                                              
00:01 [32m+741[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig value equality ShadowConfigResolutionDiagnostic equality and hashCode[0m                                                    
00:01 [32m+742[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig value equality ShadowConfigResolutionDiagnostic equality and hashCode[0m                                                    
00:01 [32m+742[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig side effects and scope does not mutate input value objects[0m                                                               
00:01 [32m+743[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig side effects and scope does not mutate input value objects[0m                                                               
00:01 [32m+743[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig side effects and scope generic resolver requires no ProjectManifest or MapPlacedElement[0m                                  
00:01 [32m+744[0m: test/shadow/shadow_config_resolver_test.dart: resolveShadowConfig side effects and scope generic resolver requires no ProjectManifest or MapPlacedElement[0m                                  
00:01 [32m+744[0m: [1m[90mloading test/shadow/element_auto_shadow_policy_test.dart[0m[0m                                                                                                                                   
00:01 [32m+744[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion small square and default prop return null[0m                                                               
00:01 [32m+745[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion small square and default prop return null[0m                                                               
00:01 [32m+745[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion wide low returns null under safe default policy[0m                                                         
00:01 [32m+746[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion wide low returns null under safe default policy[0m                                                         
00:01 [32m+746[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion tall thin returns null while building receives suggestion[0m                                               
00:01 [32m+747[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion tall thin returns null while building receives suggestion[0m                                               
00:01 [32m+747[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion Selbrume lamp proportions receive no automatic shadow[0m                                                   
00:01 [32m+748[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion Selbrume lamp proportions receive no automatic shadow[0m                                                   
00:01 [32m+748[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion Selbrume wide barriers receive no automatic shadow[0m                                                      
00:01 [32m+749[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion Selbrume wide barriers receive no automatic shadow[0m                                                      
00:01 [32m+749[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion panneau-like small wide props receive no automatic shadow[0m                                               
00:01 [32m+750[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion panneau-like small wide props receive no automatic shadow[0m                                               
00:01 [32m+750[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion Selbrume houses receive calibrated building config[0m                                                      
00:01 [32m+751[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion Selbrume houses receive calibrated building config[0m                                                      
00:01 [32m+751[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion Shadow-54 building auto config projects far less area than legacy broad[0m                                 
00:01 [32m+752[0m: test/shadow/element_auto_shadow_policy_test.dart: buildElementAutoShadowSuggestion Shadow-54 building auto config projects far less area than legacy broad[0m                                 
00:01 [32m+752[0m: test/shadow/element_auto_shadow_policy_test.dart: applyElementAutoShadowPolicyToProject backfill clears recognized old auto shadows without suggestion[0m                                     
00:01 [32m+753[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics accepts valid metrics[0m                                                                                              
00:01 [32m+754[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics accepts valid metrics[0m                                                                                              
00:01 [32m+755[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics accepts valid metrics[0m                                                                                              
00:01 [32m+756[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics accepts valid metrics[0m                                                                                              
00:01 [32m+757[0m: test/shadow/element_auto_shadow_policy_test.dart: applyElementAutoShadowPolicyToProject backfill replaces broad legacy Selbrume building shadow[0m                                            
00:01 [32m+758[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics rejects non-finite left and top[0m                                                                                    
00:01 [32m+759[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics rejects non-finite left and top[0m                                                                                    
00:01 [32m+760[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics rejects non-finite left and top[0m                                                                                    
00:01 [32m+760[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics rejects invalid visual sizes[0m                                                                                       
00:01 [32m+761[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics rejects invalid visual sizes[0m                                                                                       
00:01 [32m+761[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics equality and hashCode include all fields[0m                                                                           
00:01 [32m+762[0m: test/shadow/static_shadow_geometry_test.dart: StaticShadowVisualMetrics equality and hashCode include all fields[0m                                                                           
00:01 [32m+762[0m: test/shadow/static_shadow_geometry_test.dart: ResolvedStaticShadowFootprint defaults match current V0 ratios[0m                                                                               
00:01 [32m+763[0m: test/shadow/static_shadow_geometry_test.dart: ResolvedStaticShadowFootprint defaults match current V0 ratios[0m                                                                               
00:01 [32m+763[0m: test/shadow/static_shadow_geometry_test.dart: ResolvedStaticShadowFootprint element footprint overrides defaults field by field[0m                                                            
00:01 [32m+764[0m: test/shadow/static_shadow_geometry_test.dart: ResolvedStaticShadowFootprint element footprint overrides defaults field by field[0m                                                            
00:01 [32m+764[0m: test/shadow/static_shadow_geometry_test.dart: ResolvedStaticShadowFootprint override footprint wins over element footprint field by field[0m                                                  
00:01 [32m+765[0m: test/shadow/static_shadow_geometry_test.dart: ResolvedStaticShadowFootprint override footprint wins over element footprint field by field[0m                                                  
00:01 [32m+765[0m: test/shadow/static_shadow_geometry_test.dart: ResolvedStaticShadowFootprint rejects invalid direct resolved ratios[0m                                                                         
00:01 [32m+766[0m: test/shadow/static_shadow_geometry_test.dart: ResolvedStaticShadowFootprint rejects invalid direct resolved ratios[0m                                                                         
00:01 [32m+766[0m: test/shadow/static_shadow_geometry_test.dart: ResolvedStaticShadowFootprint equality and hashCode include all fields[0m                                                                       
00:01 [32m+767[0m: test/shadow/static_shadow_geometry_test.dart: ResolvedStaticShadowFootprint equality and hashCode include all fields[0m                                                                       
00:01 [32m+767[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry without footprint reproduces current V0 formula[0m                                                                  
00:01 [32m+768[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry without footprint reproduces current V0 formula[0m                                                                  
00:01 [32m+768[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry element footprint changes anchor and footprint size[0m                                                              
00:01 [32m+769[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry element footprint changes anchor and footprint size[0m                                                              
00:01 [32m+769[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry override footprint wins while partial override keeps element fields[0m                                              
00:01 [32m+770[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry override footprint wins while partial override keeps element fields[0m                                              
00:01 [32m+770[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry offset and scale apply after footprint[0m                                                                           
00:01 [32m+771[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry offset and scale apply after footprint[0m                                                                           
00:01 [32m+771[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry mode renderPass opacity color and softness do not affect geometry[0m                                                
00:01 [32m+772[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry mode renderPass opacity color and softness do not affect geometry[0m                                                
00:01 [32m+772[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry rejects invalid direct geometry values[0m                                                                           
00:01 [32m+773[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry rejects invalid direct geometry values[0m                                                                           
00:01 [32m+773[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry equality and hashCode include all fields[0m                                                                         
00:01 [32m+774[0m: test/shadow/static_shadow_geometry_test.dart: resolveStaticShadowGeometry equality and hashCode include all fields[0m                                                                         
00:01 [32m+774[0m: test/shadow/static_shadow_geometry_test.dart: static shadow geometry integration with existing configs ProjectElementShadowConfig footprint can be passed directly[0m                         
00:01 [32m+775[0m: test/shadow/static_shadow_geometry_test.dart: static shadow geometry integration with existing configs ProjectElementShadowConfig footprint can be passed directly[0m                         
00:01 [32m+775[0m: test/shadow/static_shadow_geometry_test.dart: static shadow geometry integration with existing configs MapPlacedElementShadowOverride footprint can be passed directly[0m                     
00:01 [32m+776[0m: test/shadow/static_shadow_geometry_test.dart: static shadow geometry integration with existing configs MapPlacedElementShadowOverride footprint can be passed directly[0m                     
00:01 [32m+776[0m: test/shadow/static_shadow_geometry_test.dart: static shadow geometry integration with existing configs custom override with null footprint uses element or default footprint[0m               
00:01 [32m+777[0m: test/shadow/static_shadow_geometry_test.dart: static shadow geometry integration with existing configs custom override with null footprint uses element or default footprint[0m               
00:01 [32m+777[0m: [1m[90mloading test/shadow/project_element_entry_shadow_json_test.dart[0m[0m                                                                                                                            
00:01 [32m+777[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON decodes legacy element JSON without shadow as null[0m                                                
00:01 [32m+778[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON decodes legacy element JSON without shadow as null[0m                                                
00:01 [32m+778[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON decodes element JSON with null shadow as null[0m                                                     
00:01 [32m+779[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON decodes element JSON with null shadow as null[0m                                                     
00:01 [32m+779[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON decodes castsShadow false config[0m                                                                  
00:01 [32m+780[0m: test/shadow/static_shadow_footprint_config_json_codec_test.dart: StaticShadowFootprintConfig JSON codec encodes null and empty footprint as null[0m                                           
00:01 [32m+781[0m: test/shadow/static_shadow_footprint_config_json_codec_test.dart: StaticShadowFootprintConfig JSON codec encodes null and empty footprint as null[0m                                           
00:01 [32m+782[0m: test/shadow/static_shadow_footprint_config_json_codec_test.dart: StaticShadowFootprintConfig JSON codec encodes null and empty footprint as null[0m                                           
00:01 [32m+783[0m: test/shadow/static_shadow_footprint_config_json_codec_test.dart: StaticShadowFootprintConfig JSON codec encodes null and empty footprint as null[0m                                           
00:01 [32m+784[0m: test/shadow/static_shadow_footprint_config_json_codec_test.dart: StaticShadowFootprintConfig JSON codec encodes null and empty footprint as null[0m                                           
00:01 [32m+785[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON legacy ProjectManifest JSON decodes element shadow as null[0m                                        
00:01 [32m+786[0m: test/shadow/static_shadow_footprint_config_json_codec_test.dart: StaticShadowFootprintConfig JSON codec encodes non-empty footprints with only non-null fields[0m                             
00:01 [32m+787[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON ProjectManifest JSON preserves element shadow[0m                                                     
00:01 [32m+788[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON ProjectManifest JSON preserves element shadow[0m                                                     
00:01 [32m+789[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON ProjectManifest JSON preserves element shadow[0m                                                     
00:01 [32m+790[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON ProjectManifest JSON preserves element shadow[0m                                                     
00:01 [32m+791[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON ProjectManifest JSON preserves element shadow[0m                                                     
00:01 [32m+792[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON ProjectManifest JSON preserves element shadow[0m                                                     
00:01 [32m+792[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON adding shadow does not modify collision profile[0m                                                   
00:01 [32m+793[0m: test/shadow/project_element_entry_shadow_json_test.dart: ProjectElementEntry shadow JSON adding shadow does not modify collision profile[0m                                                   
00:01 [32m+793[0m: [1m[90mloading test/shadow/project_shadow_profile_test.dart[0m[0m                                                                                                                                       
00:01 [32m+793[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile creates a valid profile with explicit values[0m                                                                            
00:01 [32m+794[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile creates a valid profile with explicit values[0m                                                                            
00:01 [32m+794[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile applies V0 defaults[0m                                                                                                     
00:01 [32m+795[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile applies V0 defaults[0m                                                                                                     
00:01 [32m+795[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile rejects blank id values[0m                                                                                                 
00:01 [32m+796[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile rejects blank id values[0m                                                                                                 
00:01 [32m+796[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile rejects blank name values[0m                                                                                               
00:01 [32m+797[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile rejects blank name values[0m                                                                                               
00:01 [32m+797[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile rejects non-positive scale values[0m                                                                                       
00:01 [32m+798[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile rejects non-positive scale values[0m                                                                                       
00:01 [32m+798[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile validates opacity bounds[0m                                                                                                
00:01 [32m+799[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile validates opacity bounds[0m                                                                                                
00:01 [32m+799[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile rejects non-finite double values[0m                                                                                        
00:01 [32m+800[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile rejects non-finite double values[0m                                                                                        
00:01 [32m+800[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile validates colorHexRgb[0m                                                                                                   
00:01 [32m+801[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile validates colorHexRgb[0m                                                                                                   
00:01 [32m+801[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile normalizes lowercase colorHexRgb to uppercase[0m                                                                           
00:01 [32m+802[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile normalizes lowercase colorHexRgb to uppercase[0m                                                                           
00:01 [32m+802[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile uses value equality and matching hashCode[0m                                                                               
00:01 [32m+803[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile uses value equality and matching hashCode[0m                                                                               
00:01 [32m+803[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile does not expose runtimeBlur in ShadowSoftnessMode V0[0m                                                                    
00:01 [32m+804[0m: test/shadow/project_shadow_profile_test.dart: ProjectShadowProfile does not expose runtimeBlur in ShadowSoftnessMode V0[0m                                                                    
00:01 [32m+804[0m: [1m[90mloading test/shadow/default_shadow_profiles_test.dart[0m[0m                                                                                                                                      
00:01 [32m+804[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles default profile ids are stable and unique[0m                                                             
00:01 [32m+805[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles default profile ids are stable and unique[0m                                                             
00:01 [32m+805[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles default profiles are valid groundStatic element profiles[0m                                              
00:01 [32m+806[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles default profiles are valid groundStatic element profiles[0m                                              
00:01 [32m+806[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles profile compatibility requires groundStatic and non-none mode[0m                                         
00:01 [32m+807[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles profile compatibility requires groundStatic and non-none mode[0m                                         
00:01 [32m+807[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles catalog compatibility ignores actorContact and none profiles[0m                                          
00:01 [32m+808[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles catalog compatibility ignores actorContact and none profiles[0m                                          
00:01 [32m+808[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles ensure defaults adds defaults to an empty catalog[0m                                                     
00:01 [32m+809[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles ensure defaults adds defaults to an empty catalog[0m                                                     
00:01 [32m+809[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles ensure defaults preserves incompatible custom profiles before defaults[0m                                
00:01 [32m+810[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles ensure defaults preserves incompatible custom profiles before defaults[0m                                
00:01 [32m+810[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles ensure defaults does not modify a catalog with a compatible profile[0m                                   
00:01 [32m+811[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles ensure defaults does not modify a catalog with a compatible profile[0m                                   
00:01 [32m+811[0m: test/shadow/default_shadow_profiles_test.dart: default ground static shadow profiles ensure defaults does not duplicate default ids when seeding[0m                                           
00:01 [32m+812[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: building static shadow contact ledge constants defaults match Shadow-54 visible contact tuning[0m                                 
00:01 [32m+813[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: building static shadow contact ledge constants defaults match Shadow-54 visible contact tuning[0m                                 
00:01 [32m+814[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: building static shadow contact ledge constants defaults match Shadow-54 visible contact tuning[0m                                 
00:01 [32m+814[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry creates a shallow four point contact ledge[0m                                     
00:01 [32m+815[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry creates a shallow four point contact ledge[0m                                     
00:01 [32m+815[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry matches the Shadow-54 runtime formula exactly[0m                                  
00:01 [32m+816[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry matches the Shadow-54 runtime formula exactly[0m                                  
00:01 [32m+816[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry uses base footprint width[0m                                                      
00:01 [32m+817[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry uses base footprint width[0m                                                      
00:01 [32m+817[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry applies offset and scale only through base geometry[0m                            
00:01 [32m+818[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry applies offset and scale only through base geometry[0m                            
00:01 [32m+818[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry clamps minimum and maximum depth[0m                                               
00:01 [32m+819[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry clamps minimum and maximum depth[0m                                               
00:01 [32m+819[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry clamps maximum skew[0m                                                            
00:01 [32m+820[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry clamps maximum skew[0m                                                            
00:01 [32m+820[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry geometry is immutable and all points are finite[0m                                
00:01 [32m+821[0m: test/shadow/static_shadow_contact_ledge_geometry_test.dart: resolveBuildingStaticShadowContactLedgeGeometry geometry is immutable and all points are finite[0m                                
00:01 [32m+821[0m: [1m[90mloading test/shadow/static_shadow_footprint_config_test.dart[0m[0m                                                                                                                               
00:01 [32m+821[0m: test/shadow/static_shadow_footprint_config_test.dart: StaticShadowFootprintConfig constructor all null is empty[0m                                                                            
00:01 [32m+822[0m: test/shadow/static_shadow_footprint_config_test.dart: StaticShadowFootprintConfig constructor all null is empty[0m                                                                            
00:01 [32m+822[0m: test/shadow/static_shadow_footprint_config_test.dart: StaticShadowFootprintConfig accepts anchor ratios at bounds[0m                                                                          
00:01 [32m+823[0m: test/shadow/static_shadow_footprint_config_test.dart: StaticShadowFootprintConfig accepts anchor ratios at bounds[0m                                                                          
00:01 [32m+823[0m: test/shadow/static_shadow_footprint_config_test.dart: StaticShadowFootprintConfig rejects anchor ratios outside 0 to 1 or non-finite[0m                                                       
00:01 [32m+824[0m: test/shadow/static_shadow_footprint_config_test.dart: StaticShadowFootprintConfig rejects anchor ratios outside 0 to 1 or non-finite[0m                                                       
00:01 [32m+824[0m: test/shadow/static_shadow_footprint_config_test.dart: StaticShadowFootprintConfig accepts positive footprint ratios[0m                                                                        
00:01 [32m+825[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations shadowCatalogForProject returns the manifest catalog[0m                           
00:01 [32m+826[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations shadowCatalogForProject returns the manifest catalog[0m                           
00:01 [32m+827[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations shadowCatalogForProject returns the manifest catalog[0m                           
00:01 [32m+828[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations shadowCatalogForProject returns the manifest catalog[0m                           
00:01 [32m+828[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations projectHasShadowProfiles reflects catalog emptiness[0m                            
00:01 [32m+829[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations projectHasShadowProfiles reflects catalog emptiness[0m                            
00:01 [32m+829[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations replaceProjectShadowCatalog replaces only shadowCatalog[0m                        
00:01 [32m+830[0m: test/shadow/static_shadow_family_json_codec_test.dart: StaticShadowFamily JSON codec encodes null as null[0m                                                                                  
00:01 [32m+831[0m: test/shadow/static_shadow_family_json_codec_test.dart: StaticShadowFamily JSON codec encodes null as null[0m                                                                                  
00:01 [32m+832[0m: test/shadow/static_shadow_family_json_codec_test.dart: StaticShadowFamily JSON codec encodes null as null[0m                                                                                  
00:01 [32m+833[0m: test/shadow/static_shadow_family_json_codec_test.dart: StaticShadowFamily JSON codec encodes null as null[0m                                                                                  
00:01 [32m+834[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations operations preserve JSON roundtrip contract[0m                                    
00:01 [32m+835[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations operations preserve JSON roundtrip contract[0m                                    
00:01 [32m+836[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations operations preserve JSON roundtrip contract[0m                                    
00:01 [32m+837[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations operations preserve JSON roundtrip contract[0m                                    
00:01 [32m+838[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations operations preserve JSON roundtrip contract[0m                                    
00:01 [32m+839[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations operations preserve JSON roundtrip contract[0m                                    
00:02 [32m+840[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations operations preserve JSON roundtrip contract[0m                                    
00:02 [32m+840[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations adding shadowCatalog does not modify element collision data[0m                    
00:02 [32m+841[0m: test/shadow/project_manifest_shadow_catalog_operations_test.dart: ProjectManifest shadow catalog operations adding shadowCatalog does not modify element collision data[0m                    
00:02 [32m+841[0m: [1m[90mloading test/shadow/static_shadow_family_projection_test.dart[0m[0m                                                                                                                              
00:02 [32m+841[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamily uses generic projection when no family is provided[0m                                                        
00:02 [32m+842[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamily uses generic projection when no family is provided[0m                                                        
00:02 [32m+842[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamily uses element family when no override family is provided[0m                                                   
00:02 [32m+843[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamily uses element family when no override family is provided[0m                                                   
00:02 [32m+843[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamily uses override family over element family[0m                                                                  
00:02 [32m+844[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamily uses override family over element family[0m                                                                  
00:02 [32m+844[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamilyProjectionSpec genericProjection returns the base projection unchanged[0m                                     
00:02 [32m+845[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamilyProjectionSpec genericProjection returns the base projection unchanged[0m                                     
00:02 [32m+845[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamilyProjectionSpec preserves base direction for every non-generic family[0m                                       
00:02 [32m+846[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamilyProjectionSpec preserves base direction for every non-generic family[0m                                       
00:02 [32m+846[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamilyProjectionSpec compact props are shorter and tighter than generic projection[0m                               
00:02 [32m+847[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamilyProjectionSpec compact props are shorter and tighter than generic projection[0m                               
00:02 [32m+847[0m: test/shadow/static_shadow_family_projection_test.dart: resolveStaticShadowFamilyProjectionSpec tall props are narrow and shorter than generic[0m                                              
00:02 [32m+848[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+849[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+850[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+851[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+852[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+853[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+854[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+855[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+856[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+857[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+858[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+859[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+860[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+861[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes a complete config to canonical JSON[0m                                          
00:02 [32m+861[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec decodes a complete config[0m                                                            
00:02 [32m+862[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec decodes a complete config[0m                                                            
00:02 [32m+862[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec old JSON without footprint decodes footprint null[0m                                    
00:02 [32m+863[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec old JSON without footprint decodes footprint null[0m                                    
00:02 [32m+863[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec old JSON without family decodes family null[0m                                          
00:02 [32m+864[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec old JSON without family decodes family null[0m                                          
00:02 [32m+864[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes and decodes family when present[0m                                              
00:02 [32m+865[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes and decodes family when present[0m                                              
00:02 [32m+865[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes null and empty footprint by omitting footprint key[0m                           
00:02 [32m+866[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec encodes null and empty footprint by omitting footprint key[0m                           
00:02 [32m+866[0m: test/shadow/project_element_shadow_config_json_codec_test.dart: ProjectElementShadowConfig JSON codec equality includes footprint[0m                                                          
00:02 [32m+867[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes legacy manifest JSON without shadowCatalog as empty[0m                                 
00:02 [32m+868[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes legacy manifest JSON without shadowCatalog as empty[0m                                 
00:02 [32m+869[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes legacy manifest JSON without shadowCatalog as empty[0m                                 
00:02 [32m+870[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes legacy manifest JSON without shadowCatalog as empty[0m                                 
00:02 [32m+871[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes legacy manifest JSON without shadowCatalog as empty[0m                                 
00:02 [32m+872[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes legacy manifest JSON without shadowCatalog as empty[0m                                 
00:02 [32m+873[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes legacy manifest JSON without shadowCatalog as empty[0m                                 
00:02 [32m+874[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes legacy manifest JSON without shadowCatalog as empty[0m                                 
00:02 [32m+875[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes legacy manifest JSON without shadowCatalog as empty[0m                                 
00:02 [32m+876[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes legacy manifest JSON without shadowCatalog as empty[0m                                 
00:02 [32m+876[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes null, empty object, and empty profiles as empty[0m                                     
00:02 [32m+877[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes null, empty object, and empty profiles as empty[0m                                     
00:02 [32m+877[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes a complete shadow catalog[0m                                                           
00:02 [32m+878[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON decodes a complete shadow catalog[0m                                                           
00:02 [32m+878[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON toJson preserves a complete shadow catalog[0m                                                  
00:02 [32m+879[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON toJson preserves a complete shadow catalog[0m                                                  
00:02 [32m+879[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON toJson encodes an empty shadow catalog canonically[0m                                          
00:02 [32m+880[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON toJson encodes an empty shadow catalog canonically[0m                                          
00:02 [32m+880[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON copyWith replaces shadowCatalog[0m                                                             
00:02 [32m+881[0m: test/shadow/project_shadow_profile_json_codec_test.dart: ProjectShadowProfile JSON codec encodes a complete profile into canonical JSON[0m                                                    
00:02 [32m+882[0m: test/shadow/project_shadow_profile_json_codec_test.dart: ProjectShadowProfile JSON codec encodes a complete profile into canonical JSON[0m                                                    
00:02 [32m+883[0m: test/shadow/project_shadow_profile_json_codec_test.dart: ProjectShadowProfile JSON codec encodes a complete profile into canonical JSON[0m                                                    
00:02 [32m+884[0m: test/shadow/project_shadow_profile_json_codec_test.dart: ProjectShadowProfile JSON codec encodes a complete profile into canonical JSON[0m                                                    
00:02 [32m+885[0m: test/shadow/project_shadow_profile_json_codec_test.dart: ProjectShadowProfile JSON codec encodes a complete profile into canonical JSON[0m                                                    
00:02 [32m+886[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON roundtrips element shadow and catalog through JSON[0m                                          
00:02 [32m+887[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON roundtrips element shadow and catalog through JSON[0m                                          
00:02 [32m+888[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON roundtrips element shadow and catalog through JSON[0m                                          
00:02 [32m+889[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON roundtrips element shadow and catalog through JSON[0m                                          
00:02 [32m+890[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON roundtrips element shadow and catalog through JSON[0m                                          
00:02 [32m+891[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON roundtrips element shadow and catalog through JSON[0m                                          
00:02 [32m+892[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON roundtrips element shadow and catalog through JSON[0m                                          
00:02 [32m+893[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON roundtrips element shadow and catalog through JSON[0m                                          
00:02 [32m+894[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON roundtrips element shadow and catalog through JSON[0m                                          
00:02 [32m+895[0m: test/shadow/project_manifest_shadow_catalog_json_test.dart: ProjectManifest.shadowCatalog JSON roundtrips element shadow and catalog through JSON[0m                                          
00:02 [32m+896[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec encodes an empty catalog canonically[0m                                                              
00:02 [32m+897[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec encodes an empty catalog canonically[0m                                                              
00:02 [32m+898[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec encodes an empty catalog canonically[0m                                                              
00:02 [32m+899[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec encodes an empty catalog canonically[0m                                                              
00:02 [32m+900[0m: test/shadow/project_shadow_profile_json_codec_test.dart: ProjectShadowProfile JSON codec ignores unknown fields while encode emits only canonical fields[0m                                   
00:02 [32m+901[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec decodes null, empty object, and empty profiles as empty catalog[0m                                   
00:02 [32m+902[0m: test/shadow/project_shadow_profile_json_codec_test.dart: ProjectShadowProfile JSON codec rejects non-object JSON root[0m                                                                      
00:02 [32m+903[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec encodes a complete catalog preserving order[0m                                                       
00:02 [32m+904[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec encodes a complete catalog preserving order[0m                                                       
00:02 [32m+904[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec decodes a complete catalog preserving order[0m                                                       
00:02 [32m+905[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec decodes a complete catalog preserving order[0m                                                       
00:02 [32m+905[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec roundtrips encode then decode without changing value[0m                                              
00:02 [32m+906[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec roundtrips encode then decode without changing value[0m                                              
00:02 [32m+906[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec roundtrips decode then encode into canonical JSON[0m                                                 
00:02 [32m+907[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec roundtrips decode then encode into canonical JSON[0m                                                 
00:02 [32m+907[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec profileById works after decode[0m                                                                    
00:02 [32m+908[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec profileById works after decode[0m                                                                    
00:02 [32m+908[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec keeps lookup case-sensitive after decode[0m                                                          
00:02 [32m+909[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec keeps lookup case-sensitive after decode[0m                                                          
00:02 [32m+909[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec rejects invalid profiles collection shapes[0m                                                        
00:02 [32m+910[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec rejects invalid profiles collection shapes[0m                                                        
00:02 [32m+910[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec rejects duplicate ids[0m                                                                             
00:02 [32m+911[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec rejects duplicate ids[0m                                                                             
00:02 [32m+911[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec rejects invalid profile items[0m                                                                     
00:02 [32m+912[0m: test/shadow/project_shadow_catalog_json_codec_test.dart: ProjectShadowCatalog JSON codec rejects invalid profile items[0m                                                                     
00:02 [32m+912[0m: [1m[90mloading test/shadow/map_placed_element_shadow_override_json_codec_test.dart[0m[0m                                                                                                                
00:02 [32m+912[0m: test/shadow/map_placed_element_shadow_override_json_codec_test.dart: MapPlacedElementShadowOverride JSON codec encodes inherit, disabled, and custom canonically[0m                           
00:02 [32m+913[0m: test/shadow/map_placed_element_shadow_override_json_codec_test.dart: MapPlacedElementShadowOverride JSON codec encodes inherit, disabled, and custom canonically[0m                           
00:02 [32m+913[0m: test/shadow/map_placed_element_shadow_override_json_codec_test.dart: MapPlacedElementShadowOverride JSON codec decodes inherit, disabled, and custom[0m                                       
00:02 [32m+914[0m: test/shadow/map_placed_element_shadow_override_json_codec_test.dart: MapPlacedElementShadowOverride JSON codec decodes inherit, disabled, and custom[0m                                       
00:02 [32m+914[0m: test/shadow/map_placed_element_shadow_override_json_codec_test.dart: MapPlacedElementShadowOverride JSON codec old JSON without footprint decodes footprint null[0m                           
00:02 [32m+915[0m: test/shadow/map_placed_element_shadow_override_json_codec_test.dart: MapPlacedElementShadowOverride JSON codec old JSON without footprint decodes footprint null[0m                           
00:02 [32m+915[0m: test/shadow/map_placed_element_shadow_override_json_codec_test.dart: MapPlacedElementShadowOverride JSON codec old JSON without family decodes family null[0m                                 
00:02 [32m+916[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride updates only the targeted placed element[0m                                             
00:02 [32m+917[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride updates only the targeted placed element[0m                                             
00:02 [32m+918[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride updates only the targeted placed element[0m                                             
00:02 [32m+919[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride updates only the targeted placed element[0m                                             
00:02 [32m+920[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride updates only the targeted placed element[0m                                             
00:02 [32m+921[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride updates only the targeted placed element[0m                                             
00:02 [32m+922[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride updates only the targeted placed element[0m                                             
00:02 [32m+923[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride updates only the targeted placed element[0m                                             
00:02 [32m+924[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride updates only the targeted placed element[0m                                             
00:02 [32m+925[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride updates only the targeted placed element[0m                                             
00:02 [32m+925[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride reset with null clears only the targeted override[0m                                    
00:02 [32m+926[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride reset with null clears only the targeted override[0m                                    
00:02 [32m+926[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride rejects empty instance id[0m                                                            
00:02 [32m+927[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride rejects empty instance id[0m                                                            
00:02 [32m+927[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride rejects unknown instance id[0m                                                          
00:02 [32m+928[0m: test/shadow/map_placed_element_shadow_override_operation_test.dart: setMapPlacedElementShadowOverride rejects unknown instance id[0m                                                          
00:02 [32m+928[0m: [1m[90mloading test/shadow/project_shadow_catalog_test.dart[0m[0m                                                                                                                                       
00:02 [32m+928[0m: test/shadow/project_shadow_catalog_test.dart: ProjectShadowCatalog accepts an empty catalog[0m                                                                                                
00:02 [32m+929[0m: test/shadow/project_shadow_catalog_test.dart: ProjectShadowCatalog accepts an empty catalog[0m                                                                                                
00:02 [32m+929[0m: test/shadow/project_shadow_catalog_test.dart: ProjectShadowCatalog preserves profile order[0m                                                                                                 
00:02 [32m+930[0m: test/shadow/project_shadow_catalog_test.dart: ProjectShadowCatalog preserves profile order[0m                                                                                                 
00:02 [32m+930[0m: test/shadow/project_shadow_catalog_test.dart: ProjectShadowCatalog defensively copies the source list[0m                                                                                      
00:02 [32m+931[0m: test/shadow/project_shadow_catalog_test.dart: ProjectShadowCatalog defensively copies the source list[0m                                                                                      
00:02 [32m+931[0m: test/shadow/project_shadow_catalog_test.dart: ProjectShadowCatalog exposes an unmodifiable profiles list[0m                                                                                   
00:02 [32m+932[0m: test/shadow/project_shadow_catalog_test.dart: ProjectShadowCatalog exposes an unmodifiable profiles list[0m                                                                                   
00:02 [32m+932[0m: test/shadow/project_shadow_catalog_test.dart: ProjectShadowCatalog profileById returns the expected profile[0m                                                                                
00:02 [32m+933[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics manifest without element shadows has no diagnostics[0m                                                       
00:02 [32m+934[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics manifest without element shadows has no diagnostics[0m                                                       
00:02 [32m+935[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics manifest without element shadows has no diagnostics[0m                                                       
00:02 [32m+936[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics manifest without element shadows has no diagnostics[0m                                                       
00:02 [32m+937[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics manifest without element shadows has no diagnostics[0m                                                       
00:02 [32m+938[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics manifest without element shadows has no diagnostics[0m                                                       
00:02 [32m+939[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics manifest without element shadows has no diagnostics[0m                                                       
00:02 [32m+939[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics ignores null shadow and castsShadow false[0m                                                                 
00:02 [32m+940[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics ignores null shadow and castsShadow false[0m                                                                 
00:02 [32m+940[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics castsShadow true with existing profile has no diagnostics[0m                                                 
00:02 [32m+941[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics castsShadow true with existing profile has no diagnostics[0m                                                 
00:02 [32m+941[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics castsShadow true with missing profile produces a diagnostic[0m                                               
00:02 [32m+942[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics castsShadow true with missing profile produces a diagnostic[0m                                               
00:02 [32m+942[0m: test/shadow/shadow_authoring_diagnostics_test.dart: Shadow authoring diagnostics emits one diagnostic per element in manifest order[0m                                                        
00:02 [32m+943[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride defaults to inherit[0m                                                                               
00:02 [32m+944[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride defaults to inherit[0m                                                                               
00:02 [32m+945[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride defaults to inherit[0m                                                                               
00:02 [32m+946[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride defaults to inherit[0m                                                                               
00:02 [32m+947[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride defaults to inherit[0m                                                                               
00:02 [32m+947[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride accepts disabled override[0m                                                                         
00:02 [32m+948[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride accepts disabled override[0m                                                                         
00:02 [32m+948[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride accepts custom override with profile id[0m                                                           
00:02 [32m+949[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride accepts custom override with profile id[0m                                                           
00:02 [32m+949[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride accepts custom numeric overrides without profile id[0m                                               
00:02 [32m+950[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride accepts custom numeric overrides without profile id[0m                                               
00:02 [32m+950[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride accepts custom override with family[0m                                                               
00:02 [32m+951[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride accepts custom override with family[0m                                                               
00:02 [32m+951[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride accepts opacity bounds on custom override[0m                                                         
00:02 [32m+952[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride accepts opacity bounds on custom override[0m                                                         
00:02 [32m+952[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects blank profile ids when provided[0m                                                           
00:02 [32m+953[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects blank profile ids when provided[0m                                                           
00:02 [32m+953[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects inherit with any override fields[0m                                                          
00:02 [32m+954[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects inherit with any override fields[0m                                                          
00:02 [32m+954[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects disabled with any override fields[0m                                                         
00:02 [32m+955[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects disabled with any override fields[0m                                                         
00:02 [32m+955[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects non-finite offsets[0m                                                                        
00:02 [32m+956[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects non-finite offsets[0m                                                                        
00:02 [32m+956[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects invalid scale overrides[0m                                                                   
00:02 [32m+957[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects invalid scale overrides[0m                                                                   
00:02 [32m+957[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects invalid opacity overrides[0m                                                                 
00:02 [32m+958[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride rejects invalid opacity overrides[0m                                                                 
00:02 [32m+958[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride uses value equality[0m                                                                               
00:02 [32m+959[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride uses value equality[0m                                                                               
00:02 [32m+959[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride value equality includes family[0m                                                                    
00:02 [32m+960[0m: test/shadow/map_placed_element_shadow_override_test.dart: MapPlacedElementShadowOverride value equality includes family[0m                                                                    
00:02 [32m+960[0m: [1m[90mloading test/shadow/static_shadow_projection_geometry_test.dart[0m[0m                                                                                                                            
00:02 [32m+960[0m: test/shadow/static_shadow_projection_geometry_test.dart: ProjectedStaticShadowPoint valid point accepted[0m                                                                                   
00:02 [32m+961[0m: test/shadow/static_shadow_projection_geometry_test.dart: ProjectedStaticShadowPoint valid point accepted[0m                                                                                   
00:02 [32m+961[0m: test/shadow/static_shadow_projection_geometry_test.dart: ProjectedStaticShadowPoint rejects non-finite coordinates[0m                                                                         
00:02 [32m+962[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+963[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+964[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+965[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+966[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+967[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+968[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+969[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+970[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+971[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+972[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig defaults to not casting a shadow[0m                                                                           
00:02 [32m+972[0m: test/shadow/static_shadow_projection_geometry_test.dart: ProjectedStaticShadowOpacityBand rejects invalid opacity band inputs[0m                                                              
00:02 [32m+973[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig keeps a profile id when castsShadow is false[0m                                                               
00:02 [32m+974[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig keeps a profile id when castsShadow is false[0m                                                               
00:02 [32m+975[0m: test/shadow/static_shadow_projection_geometry_test.dart: ProjectedStaticShadowGeometry valid four-point polygon accepted[0m                                                                   
00:02 [32m+976[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig accepts castsShadow true with a profile id[0m                                                                 
00:02 [32m+977[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig accepts castsShadow true with a profile id[0m                                                                 
00:02 [32m+977[0m: test/shadow/static_shadow_projection_geometry_test.dart: ProjectedStaticShadowGeometry rejects degenerate polygon[0m                                                                          
00:02 [32m+978[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig accepts valid numeric overrides[0m                                                                            
00:02 [32m+979[0m: test/shadow/static_shadow_projection_geometry_test.dart: ProjectedStaticShadowGeometry points getter returns ordered polygon points[0m                                                        
00:02 [32m+980[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig castsShadow false can carry family[0m                                                                         
00:02 [32m+981[0m: test/shadow/static_shadow_projection_geometry_test.dart: ProjectedStaticShadowGeometry equality and hashCode include all four points[0m                                                       
00:02 [32m+982[0m: test/shadow/static_shadow_projection_geometry_test.dart: ProjectedStaticShadowGeometry equality and hashCode include all four points[0m                                                       
00:02 [32m+983[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig rejects blank profile ids when provided[0m                                                                    
00:02 [32m+984[0m: test/shadow/static_shadow_projection_geometry_test.dart: resolveProjectedStaticShadowGeometry default projection moves far edge down-right[0m                                                 
00:02 [32m+985[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig rejects castsShadow true without a profile id[0m                                                              
00:02 [32m+986[0m: test/shadow/static_shadow_projection_geometry_test.dart: resolveProjectedStaticShadowGeometry custom down-left direction moves far edge down-left[0m                                          
00:02 [32m+987[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig rejects non-finite offsets[0m                                                                                 
00:02 [32m+988[0m: test/shadow/static_shadow_projection_geometry_test.dart: resolveProjectedStaticShadowGeometry projection length uses metrics visualHeight[0m                                                  
00:02 [32m+989[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig rejects invalid scale overrides[0m                                                                            
00:02 [32m+990[0m: test/shadow/static_shadow_projection_geometry_test.dart: resolveProjectedStaticShadowGeometry near and far widths use base width multipliers[0m                                               
00:02 [32m+991[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig rejects invalid opacity overrides[0m                                                                          
00:02 [32m+992[0m: test/shadow/static_shadow_projection_geometry_test.dart: resolveProjectedStaticShadowGeometry changing base height does not change polygon width[0m                                           
00:02 [32m+993[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig uses value equality[0m                                                                                        
00:02 [32m+994[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig uses value equality[0m                                                                                        
00:02 [32m+995[0m: test/shadow/project_element_shadow_config_test.dart: ProjectElementShadowConfig uses value equality[0m                                                                                        
00:02 [32m+996[0m: test/shadow/static_shadow_projection_geometry_test.dart: resolveProjectedStaticShadowGeometry composes with resolveStaticShadowGeometry without double scaling[0m                             
00:02 [32m+997[0m: test/shadow/static_shadow_projection_geometry_test.dart: resolveProjectedStaticShadowGeometry composes with resolveStaticShadowGeometry without double scaling[0m                             
00:02 [32m+998[0m: test/shadow/static_shadow_projection_geometry_test.dart: resolveProjectedStaticShadowGeometry composes with resolveStaticShadowGeometry without double scaling[0m                             
00:02 [32m+998[0m: [1m[90mloading test/surface_catalog_authoring_diagnostics_test.dart[0m[0m                                                                                                                               
00:02 [32m+998[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 1. empty catalog: no diagnostics[0m                                                  
00:02 [32m+999[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 1. empty catalog: no diagnostics[0m                                                  
00:02 [32m+999[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 2. minimal coherent: no diagnostics[0m                                               
00:02 [32m+1000[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 2. minimal coherent: no diagnostics[0m                                              
00:02 [32m+1000[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 3. error only: missing preset animation[0m                                          
00:02 [32m+1001[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 3. error only: missing preset animation[0m                                          
00:02 [32m+1001[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 4. warning only: unused atlas[0m                                                    
00:02 [32m+1002[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 4. warning only: unused atlas[0m                                                    
00:02 [32m+1002[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 5. warning only: unused animation, no unusedAtlas[0m                                
00:02 [32m+1003[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 5. warning only: unused animation, no unusedAtlas[0m                                
00:02 [32m+1003[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 6. error + warnings: order errors then unusedAtlas then unusedAnimation[0m          
00:02 [32m+1004[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 6. error + warnings: order errors then unusedAtlas then unusedAnimation[0m          
00:02 [32m+1004[0m: test/surface_catalog_authoring_diagnostics_test.dart: diagnoseProjectSurfaceCatalogForAuthoring (Lot 36) 7. two preset errors: Lot 34 order preserved at start of report[0m                  
00:02 [32m+1005[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1006[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1007[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1008[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1009[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1010[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1011[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1012[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1013[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1014[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1015[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1016[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1017[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1018[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1019[0m: test/beta_playability_validator_test.dart: validateBetaPlayability accepts a minimal beta-ready project without blocking errors[0m                                                           
00:02 [32m+1019[0m: test/beta_playability_validator_test.dart: validateBetaPlayability diagnoses an empty manifest map list[0m                                                                                   
00:02 [32m+1020[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1021[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1022[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1023[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1024[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1025[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1026[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1027[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1028[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1029[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1030[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1031[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel lists canonical CinematicAsset and scenario bridges separately[0m                                              
00:02 [32m+1031[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel attaches diagnostics and reports empty timeline metrics[0m                                                     
00:02 [32m+1032[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel attaches diagnostics and reports empty timeline metrics[0m                                                     
00:02 [32m+1032[0m: test/cinematics_library_read_model_test.dart: buildCinematicsLibraryReadModel reports canonical, bridge, and unknown Scene references[0m                                                     
00:02 [32m+1033[0m: test/cinematic_timeline_time_layout_read_model_test.dart: buildCinematicTimelineTimeLayoutReadModel derives block timing from linear order with fallback durations[0m                        
00:02 [32m+1034[0m: test/cinematic_timeline_time_layout_read_model_test.dart: buildCinematicTimelineTimeLayoutReadModel derives block timing from linear order with fallback durations[0m                        
00:02 [32m+1035[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor construction accepts RGB components in the 0..255 range[0m                                                                 
00:02 [32m+1036[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor construction accepts RGB components in the 0..255 range[0m                                                                 
00:02 [32m+1037[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor construction accepts RGB components in the 0..255 range[0m                                                                 
00:02 [32m+1038[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor construction accepts RGB components in the 0..255 range[0m                                                                 
00:02 [32m+1039[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor construction accepts RGB components in the 0..255 range[0m                                                                 
00:02 [32m+1039[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor construction rejects RGB components outside the 0..255 range[0m                                                            
00:02 [32m+1040[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor construction rejects RGB components outside the 0..255 range[0m                                                            
00:02 [32m+1040[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor hex parsing accepts lowercase, uppercase, and optional # RGB values[0m                                                     
00:02 [32m+1041[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor hex parsing accepts lowercase, uppercase, and optional # RGB values[0m                                                     
00:02 [32m+1041[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor hex parsing returns canonical lowercase RGB without # and with padding[0m                                                  
00:02 [32m+1042[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor hex parsing returns canonical lowercase RGB without # and with padding[0m                                                  
00:02 [32m+1042[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor hex parsing rejects invalid hex RGB strings[0m                                                                             
00:02 [32m+1043[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor hex parsing rejects invalid hex RGB strings[0m                                                                             
00:02 [32m+1043[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor matching matches RGB components exactly[0m                                                                                 
00:02 [32m+1044[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor matching matches RGB components exactly[0m                                                                                 
00:02 [32m+1044[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor matching matches ARGB 32-bit values while ignoring alpha[0m                                                                
00:02 [32m+1045[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor matching matches ARGB 32-bit values while ignoring alpha[0m                                                                
00:02 [32m+1045[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor equality uses value equality and stable hashCode[0m                                                                        
00:02 [32m+1046[0m: test/tileset_transparent_color_test.dart: TilesetTransparentColor equality uses value equality and stable hashCode[0m                                                                        
00:02 [32m+1046[0m: test/tileset_transparent_color_test.dart: ProjectTilesetEntry transparentColor serializes transparent color as lowercase hex RGB[0m                                                          
00:02 [32m+1047[0m: test/tileset_transparent_color_test.dart: ProjectTilesetEntry transparentColor serializes transparent color as lowercase hex RGB[0m                                                          
00:02 [32m+1047[0m: test/tileset_transparent_color_test.dart: ProjectTilesetEntry transparentColor deserializes transparent color from hex RGB[0m                                                                
00:02 [32m+1048[0m: test/tileset_transparent_color_test.dart: ProjectTilesetEntry transparentColor deserializes transparent color from hex RGB[0m                                                                
00:02 [32m+1048[0m: [1m[90mloading test/scene_runtime_executor_test.dart[0m[0m                                                                                                                                             
00:02 [32m+1048[0m: test/scene_runtime_executor_test.dart: SceneRuntimeExecutor MVP executes start to end[0m                                                                                                     
00:02 [32m+1049[0m: test/scene_runtime_executor_test.dart: SceneRuntimeExecutor MVP executes start to end[0m                                                                                                     
00:02 [32m+1049[0m: test/scene_runtime_executor_test.dart: SceneRuntimeExecutor MVP exposes final scene outcome id from end intent[0m                                                                            
00:02 [32m+1050[0m: test/scene_runtime_executor_test.dart: SceneRuntimeExecutor MVP exposes final scene outcome id from end intent[0m                                                                            
00:02 [32m+1050[0m: test/scene_runtime_executor_test.dart: SceneRuntimeExecutor MVP executes a plan built from a SceneAsset without ProjectManifest[0m                                                           
00:02 [32m+1051[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1052[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1053[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1054[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1055[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1056[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1057[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1058[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1059[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1060[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1061[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1062[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1063[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1064[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1065[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1066[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1067[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports empty timeline as authoring warning[0m                                                                                   
00:02 [32m+1067[0m: test/scene_runtime_executor_test.dart: SceneRuntimeExecutor MVP fails when maxSteps is exceeded[0m                                                                                           
00:02 [32m+1068[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports duplicate step ids and invalid durations[0m                                                                              
00:02 [32m+1069[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports duplicate step ids and invalid durations[0m                                                                              
00:02 [32m+1070[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics reports duplicate step ids and invalid durations[0m                                                                              
00:02 [32m+1070[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics diagnoses wait duration below minimum[0m                                                                                         
00:02 [32m+1071[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics diagnoses wait duration below minimum[0m                                                                                         
00:02 [32m+1071[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics diagnoses actorMove duration below minimum[0m                                                                                    
00:02 [32m+1072[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics diagnoses actorMove duration below minimum[0m                                                                                    
00:02 [32m+1072[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics diagnoses duration above maximum[0m                                                                                              
00:02 [32m+1073[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics diagnoses duration above maximum[0m                                                                                              
00:02 [32m+1073[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics does not diagnose missing duration when fallback is allowed[0m                                                                   
00:02 [32m+1074[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics does not diagnose missing duration when fallback is allowed[0m                                                                   
00:02 [32m+1074[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics does not diagnose marker draft without duration as duration error[0m                                                             
00:02 [32m+1075[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics does not diagnose marker draft without duration as duration error[0m                                                             
00:02 [32m+1075[0m: test/cinematic_diagnostics_test.dart: Cinematic diagnostics diagnostics use the same bounds as authoring validation[0m                                                                       
00:02 [32m+1076[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1077[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1078[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1079[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1080[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1081[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1082[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1083[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1084[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1085[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1086[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1087[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1088[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1089[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1090[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1091[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1092[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1093[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1094[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1095[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1096[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1097[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1098[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1099[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1100[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1101[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1102[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1103[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1104[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1105[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1106[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1107[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1108[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1109[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1110[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1111[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1112[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1113[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1114[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1115[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1116[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1117[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1118[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1119[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1120[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1121[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1122[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1123[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1124[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1125[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1126[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1127[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1128[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1129[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1130[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness proves a controlled event to scene dialogue battle chain[0m                                                                      
00:02 [32m+1130[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness reports missing scene, dialogue, trainer, plan and world rule gaps[0m                                                            
00:02 [32m+1131[0m: test/golden_slice_readiness_test.dart: GoldenSliceReadiness reports missing scene, dialogue, trainer, plan and world rule gaps[0m                                                            
00:02 [32m+1131[0m: [1m[90mloading test/linked_asset_public_contracts_test.dart[0m[0m                                                                                                                                      
00:02 [32m+1131[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts builds dialogue contracts from manifest dialogues[0m                                                             
00:02 [32m+1132[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts builds dialogue contracts from manifest dialogues[0m                                                             
00:02 [32m+1132[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts reports a diagnostic when dialogue label falls back to technical id[0m                                           
00:02 [32m+1133[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts reports a diagnostic when dialogue label falls back to technical id[0m                                           
00:02 [32m+1133[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts builds trainer battle contracts without exposing map_battle types[0m                                             
00:02 [32m+1134[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts builds trainer battle contracts without exposing map_battle types[0m                                             
00:02 [32m+1134[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts warns when a trainer battle has an empty team[0m                                                                 
00:02 [32m+1135[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts warns when a trainer battle has an empty team[0m                                                                 
00:02 [32m+1135[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts builds cinematic scenario bridge contracts from cutscene metadata[0m                                             
00:02 [32m+1136[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts builds cinematic scenario bridge contracts from cutscene metadata[0m                                             
00:02 [32m+1136[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts builds canonical cinematic asset contracts separately from bridges[0m                                            
00:02 [32m+1137[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts builds canonical cinematic asset contracts separately from bridges[0m                                            
00:02 [32m+1137[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts does not expose regular scenarios as cinematic contracts[0m                                                      
00:02 [32m+1138[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts does not expose regular scenarios as cinematic contracts[0m                                                      
00:02 [32m+1138[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts snapshot aggregates contracts and keeps action and branch disabled[0m                                            
00:02 [32m+1139[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts snapshot aggregates contracts and keeps action and branch disabled[0m                                            
00:02 [32m+1139[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts builders are deterministic and do not mutate the manifest[0m                                                     
00:02 [32m+1140[0m: test/linked_asset_public_contracts_test.dart: Linked asset public contracts builders are deterministic and do not mutate the manifest[0m                                                     
00:02 [32m+1140[0m: [1m[90mloading test/narrative_reference_picker_read_models_test.dart[0m[0m                                                                                                                             
00:02 [32m+1140[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds scenario picker options with stable labels and counts[0m                                
00:02 [32m+1141[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds scenario picker options with stable labels and counts[0m                                
00:02 [32m+1141[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds outcome picker options from declared emitted and consumed ids[0m                        
00:02 [32m+1142[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds outcome picker options from declared emitted and consumed ids[0m                        
00:02 [32m+1142[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds battle reference picker options from trainer battle nodes[0m                            
00:02 [32m+1143[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 1. encodes SurfaceAtlasTileRef[0m                                              
00:02 [32m+1144[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 1. encodes SurfaceAtlasTileRef[0m                                              
00:02 [32m+1145[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 1. encodes SurfaceAtlasTileRef[0m                                              
00:02 [32m+1146[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds event source picker options from maps entities and outcomes[0m                          
00:02 [32m+1147[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds event source picker options from maps entities and outcomes[0m                          
00:02 [32m+1148[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds event source picker options from maps entities and outcomes[0m                          
00:02 [32m+1149[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds event source picker options from maps entities and outcomes[0m                          
00:02 [32m+1150[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds event source picker options from maps entities and outcomes[0m                          
00:02 [32m+1150[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 5. rejects atlasId missing, wrong type, whitespace-only[0m                     
00:02 [32m+1151[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds predicate reference picker options from derived facts[0m                                
00:02 [32m+1152[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds predicate reference picker options from derived facts[0m                                
00:02 [32m+1153[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds predicate reference picker options from derived facts[0m                                
00:02 [32m+1154[0m: test/narrative_reference_picker_read_models_test.dart: Narrative reference picker read models builds predicate reference picker options from derived facts[0m                                
00:02 [32m+1155[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1156[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1157[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1158[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1159[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1160[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1161[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1162[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1163[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1164[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1165[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig defaults to idle with safe values[0m                                                                               
00:02 [32m+1166[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 18. does not verify geometry; isInside is separate[0m                          
00:02 [32m+1167[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig serializes and deserializes patrol configuration[0m                                                                
00:02 [32m+1168[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig serializes and deserializes patrol configuration[0m                                                                
00:02 [32m+1169[0m: test/map_entity_npc_movement_config_test.dart: MapEntityNpcMovementConfig serializes and deserializes patrol configuration[0m                                                                
00:02 [32m+1170[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 21. ProjectManifest has no surface persistence keys (Lot 40)[0m                
00:02 [32m+1171[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 21. ProjectManifest has no surface persistence keys (Lot 40)[0m                
00:02 [32m+1172[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 21. ProjectManifest has no surface persistence keys (Lot 40)[0m                
00:02 [32m+1172[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 22. codec external to models: no Surface toJson or fromJson on ref/frame[0m    
00:02 [32m+1173[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 22. codec external to models: no Surface toJson or fromJson on ref/frame[0m    
00:02 [32m+1173[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 23. no timeline or ProjectSurfaceAnimation codec in this lot[0m                
00:02 [32m+1174[0m: test/surface_animation_frame_json_codec_test.dart: Surface Atlas TileRef / AnimationFrame JSON codec (Lot 40) 23. no timeline or ProjectSurfaceAnimation codec in this lot[0m                
00:02 [32m+1174[0m: [1m[90mloading test/map_core_test.dart[0m[0m                                                                                                                                                           
00:02 [32m+1174[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                              
00:02 [32m+1175[0m: test/map_core_test.dart: MapCore Strict Tests MapLayer serialization (Union)[0m                                                                                                              
00:02 [32m+1175[0m: test/map_core_test.dart: MapCore Strict Tests ProjectValidator detects duplicates[0m                                                                                                         
00:02 [32m+1176[0m: test/map_core_test.dart: MapCore Strict Tests ProjectValidator detects duplicates[0m                                                                                                         
00:02 [32m+1176[0m: test/map_core_test.dart: MapCore Strict Tests MapValidator detects layer size mismatch[0m                                                                                                    
00:02 [32m+1177[0m: test/map_core_test.dart: MapCore Strict Tests MapValidator detects layer size mismatch[0m                                                                                                    
00:02 [32m+1177[0m: test/map_core_test.dart: MapCore Strict Tests MapValidator detects entity out of bounds[0m                                                                                                   
00:02 [32m+1178[0m: test/map_core_test.dart: MapCore Strict Tests MapValidator detects entity out of bounds[0m                                                                                                   
00:02 [32m+1178[0m: [1m[90mloading test/scene_authoring_operations_test.dart[0m[0m                                                                                                                                         
00:02 [32m+1178[0m: test/scene_authoring_operations_test.dart: Scene authoring operations creates a minimal scene draft in ProjectManifest.scenes[0m                                                             
00:02 [32m+1179[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                           
00:02 [32m+1180[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                           
00:02 [32m+1181[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef minimal ref holds role and animationId[0m                                                                           
00:02 [32m+1182[0m: test/scene_authoring_operations_test.dart: Scene authoring operations does not touch scenarios or storylines[0m                                                                              
00:02 [32m+1183[0m: test/scene_authoring_operations_test.dart: Scene authoring operations does not touch scenarios or storylines[0m                                                                              
00:02 [32m+1184[0m: test/scene_authoring_operations_test.dart: Scene authoring operations does not touch scenarios or storylines[0m                                                                              
00:02 [32m+1185[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef rejects empty animationId: empty string[0m                                                                          
00:02 [32m+1186[0m: test/surface_variant_animation_ref_test.dart: SurfaceVariantAnimationRef rejects empty animationId: empty string[0m                                                                          
00:02 [32m+1186[0m: test/scene_authoring_operations_test.dart: Scene authoring operations adds a condition node draft without mutating the original scene[0m                                                     
00:02 [32m+1187[0m: test/scene_authoring_operations_test.dart: Scene authoring operations adds a condition node draft without mutating the original scene[0m                                                     
00:02 [32m+1188[0m: test/scene_authoring_operations_test.dart: Scene authoring operations adds a condition node draft without mutating the original scene[0m                                                     
00:02 [32m+1189[0m: test/scene_authoring_operations_test.dart: Scene authoring operations adds a condition node draft without mutating the original scene[0m                                                     
00:02 [32m+1190[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1191[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1192[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1193[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1194[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1195[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1196[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1197[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1198[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1199[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1200[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1201[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1202[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1203[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1204[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1205[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1206[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1207[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1208[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1209[0m: test/world_rule_authoring_operations_test.dart: World rule authoring operations adds a world rule with stable id without mutating manifest[0m                                                
00:02 [32m+1210[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1211[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1212[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1213[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1214[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1215[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1216[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1217[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1218[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1219[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1220[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1221[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1222[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1223[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1224[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1225[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unknown source and unknown target references[0m                                                                        
00:02 [32m+1225[0m: test/scene_authoring_operations_test.dart: Scene authoring operations removes a dialogue node draft and its connected edges[0m                                                               
00:02 [32m+1226[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports effect target mismatch and raw technical labels[0m                                                                     
00:02 [32m+1227[0m: test/scene_authoring_operations_test.dart: Scene authoring operations removes a battle node draft and its victory defeat edges[0m                                                            
00:02 [32m+1228[0m: test/world_rule_diagnostics_test.dart: World rule diagnostics reports unsupported predicates and conflicting same target priority[0m                                                         
00:02 [32m+1229[0m: test/scene_authoring_operations_test.dart: Scene authoring operations rejects empty node id, start node, unknown node and last end[0m                                                        
00:02 [32m+1230[0m: test/scene_authoring_operations_test.dart: Scene authoring operations rejects empty node id, start node, unknown node and last end[0m                                                        
00:02 [32m+1230[0m: test/scene_authoring_operations_test.dart: Scene authoring operations rejects invalid edge drafts in V0[0m                                                                                   
00:02 [32m+1231[0m: test/scene_authoring_operations_test.dart: Scene authoring operations rejects invalid edge drafts in V0[0m                                                                                   
00:02 [32m+1231[0m: test/scene_authoring_operations_test.dart: Scene authoring operations rejects duplicate dialogue and battle source ports[0m                                                                  
00:02 [32m+1232[0m: test/scene_authoring_operations_test.dart: Scene authoring operations rejects duplicate dialogue and battle source ports[0m                                                                  
00:02 [32m+1232[0m: test/scene_authoring_operations_test.dart: Scene authoring operations updates an existing node layout without mutating graph logic[0m                                                        
00:02 [32m+1233[0m: test/scene_authoring_operations_test.dart: Scene authoring operations updates an existing node layout without mutating graph logic[0m                                                        
00:02 [32m+1233[0m: test/scene_authoring_operations_test.dart: Scene authoring operations creates a missing node layout and rejects unknown nodes[0m                                                             
00:02 [32m+1234[0m: test/scene_authoring_operations_test.dart: Scene authoring operations creates a missing node layout and rejects unknown nodes[0m                                                             
00:02 [32m+1234[0m: test/scene_authoring_operations_test.dart: Scene authoring operations updates a condition node with a fact-like story flag source[0m                                                         
00:02 [32m+1235[0m: test/scene_authoring_operations_test.dart: Scene authoring operations updates a condition node with a fact-like story flag source[0m                                                         
00:02 [32m+1235[0m: test/scene_authoring_operations_test.dart: Scene authoring operations updates a condition node with a story step completion source[0m                                                        
00:02 [32m+1236[0m: test/scene_authoring_operations_test.dart: Scene authoring operations updates a condition node with a story step completion source[0m                                                        
00:02 [32m+1236[0m: test/scene_authoring_operations_test.dart: Scene authoring operations rejects invalid condition source updates[0m                                                                            
00:02 [32m+1237[0m: test/scene_authoring_operations_test.dart: Scene authoring operations rejects invalid condition source updates[0m                                                                            
00:02 [32m+1237[0m: [1m[90mloading test/storyline_scene_link_test.dart[0m[0m                                                                                                                                               
00:02 [32m+1237[0m: test/storyline_scene_link_test.dart: StorylineStep sceneLinkIds decodes missing sceneLinkIds as an empty list[0m                                                                             
00:02 [32m+1238[0m: test/storyline_scene_link_test.dart: StorylineStep sceneLinkIds decodes missing sceneLinkIds as an empty list[0m                                                                             
00:02 [32m+1238[0m: test/storyline_scene_link_test.dart: StorylineStep sceneLinkIds round-trips sceneLinkIds without changing order[0m                                                                           
00:02 [32m+1239[0m: test/storyline_scene_link_test.dart: StorylineStep sceneLinkIds round-trips sceneLinkIds without changing order[0m                                                                           
00:02 [32m+1239[0m: [1m[90mloading test/project_manifest_path_pattern_presets_test.dart[0m[0m                                                                                                                              
00:02 [32m+1239[0m: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets decodes old manifests without pathPatternPresets as empty[0m                                        
00:02 [32m+1240[0m: test/project_manifest_surface_integration_prep_test.dart: ... Surface Integration Prep: Lot 48 → Lot 49 transition 1. Lot 48: no top-level surface keys; Lot 49: surfaceCatalog + no split[0m
00:02 [32m+1241[0m: test/project_manifest_surface_integration_prep_test.dart: ... Surface Integration Prep: Lot 48 → Lot 49 transition 1. Lot 48: no top-level surface keys; Lot 49: surfaceCatalog + no split[0m
00:02 [32m+1242[0m: test/project_manifest_surface_integration_prep_test.dart: ... Surface Integration Prep: Lot 48 → Lot 49 transition 1. Lot 48: no top-level surface keys; Lot 49: surfaceCatalog + no split[0m
00:02 [32m+1243[0m: test/project_manifest_surface_integration_prep_test.dart: ... Surface Integration Prep: Lot 48 → Lot 49 transition 1. Lot 48: no top-level surface keys; Lot 49: surfaceCatalog + no split[0m
00:02 [32m+1244[0m: test/surface_atlas_json_codec_test.dart: surface_atlas_json_codec (Lot 39) 1. encode SurfaceAtlasTileSize[0m                                                                                 
00:02 [32m+1245[0m: test/surface_atlas_json_codec_test.dart: surface_atlas_json_codec (Lot 39) 1. encode SurfaceAtlasTileSize[0m                                                                                 
00:02 [32m+1246[0m: test/surface_atlas_json_codec_test.dart: surface_atlas_json_codec (Lot 39) 1. encode SurfaceAtlasTileSize[0m                                                                                 
00:02 [32m+1247[0m: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets roundtrips manifest pathPatternPresets without changing order[0m                                    
00:02 [32m+1248[0m: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets roundtrips manifest pathPatternPresets without changing order[0m                                    
00:02 [32m+1249[0m: test/project_manifest_path_pattern_presets_test.dart: ProjectManifest pathPatternPresets roundtrips manifest pathPatternPresets without changing order[0m                                    
00:02 [32m+1250[0m: test/surface_atlas_json_codec_test.dart: surface_atlas_json_codec (Lot 39) 3. reject tile size missing / wrong type / width 0[0m                                                             
00:02 [32m+1251[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1252[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1253[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1254[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1255[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1256[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1257[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1258[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1259[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1260[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1261[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1262[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1263[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1264[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1265[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1266[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1267[0m: test/project_manifest_surface_integration_prep_test.dart: ... Integration Prep: Lot 48 → Lot 49 transition 4. Lot 47 minimal water: Lot 49 keeps catalog on manifest (was dropped in 48)[0m  
00:02 [32m+1268[0m: test/world_rule_target_context_read_model_test.dart: WorldRuleTargetContextReadModel finds rules targeting a map event and filters other contexts[0m                                         
00:02 [32m+1269[0m: test/world_rule_target_context_read_model_test.dart: WorldRuleTargetContextReadModel finds rules targeting a map event and filters other contexts[0m                                         
00:02 [32m+1270[0m: test/world_rule_target_context_read_model_test.dart: WorldRuleTargetContextReadModel finds rules targeting a map event and filters other contexts[0m                                         
00:02 [32m+1271[0m: test/world_rule_target_context_read_model_test.dart: WorldRuleTargetContextReadModel finds rules targeting a map event and filters other contexts[0m                                         
00:02 [32m+1272[0m: test/world_rule_target_context_read_model_test.dart: WorldRuleTargetContextReadModel finds rules targeting a map event and filters other contexts[0m                                         
00:02 [32m+1273[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1274[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1275[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1276[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1277[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1278[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1279[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1280[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1281[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1282[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1283[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1284[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1285[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1286[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1287[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1288[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1289[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1290[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1291[0m: test/map_gameplay_zone_validation_test.dart: Map gameplay zone battle background validation rejects encounter zone backgrounds that escape the project[0m                                    
00:02 [32m+1292[0m: test/world_rule_target_context_read_model_test.dart: WorldRuleTargetContextReadModel does not mutate ProjectManifest or require GameState[0m                                                 
00:02 [32m+1293[0m: test/world_rule_target_context_read_model_test.dart: WorldRuleTargetContextReadModel does not mutate ProjectManifest or require GameState[0m                                                 
00:02 [32m+1294[0m: test/world_rule_target_context_read_model_test.dart: WorldRuleTargetContextReadModel does not mutate ProjectManifest or require GameState[0m                                                 
00:02 [32m+1295[0m: test/surface_atlas_json_codec_test.dart: surface_atlas_json_codec (Lot 39) 29. ProjectManifest has no surface persistence keys (Lot 39)[0m                                                   
00:02 [32m+1296[0m: test/surface_atlas_json_codec_test.dart: surface_atlas_json_codec (Lot 39) 29. ProjectManifest has no surface persistence keys (Lot 39)[0m                                                   
00:02 [32m+1297[0m: test/surface_atlas_json_codec_test.dart: surface_atlas_json_codec (Lot 39) 29. ProjectManifest has no surface persistence keys (Lot 39)[0m                                                   
00:02 [32m+1297[0m: test/surface_atlas_json_codec_test.dart: surface_atlas_json_codec (Lot 39) 30. codec external to models: no model toJson / fromJson[0m                                                       
00:02 [32m+1298[0m: test/surface_atlas_json_codec_test.dart: surface_atlas_json_codec (Lot 39) 30. codec external to models: no model toJson / fromJson[0m                                                       
00:02 [32m+1298[0m: [1m[90mloading test/scene_cinematic_authoring_test.dart[0m[0m                                                                                                                                          
00:02 [32m+1298[0m: test/scene_cinematic_authoring_test.dart: Scene cinematic authoring adds a cinematic node from a canonical CinematicAsset[0m                                                                 
00:02 [32m+1299[0m: test/element_collision_profile_pixel_mask_json_test.dart: ElementCollisionProfile mask JSON supports pixelMask[0m                                                                            
00:02 [32m+1300[0m: test/element_collision_profile_pixel_mask_json_test.dart: ElementCollisionProfile mask JSON supports pixelMask[0m                                                                            
00:02 [32m+1301[0m: test/element_collision_profile_pixel_mask_json_test.dart: ElementCollisionProfile mask JSON supports pixelMask[0m                                                                            
00:02 [32m+1302[0m: test/element_collision_profile_pixel_mask_json_test.dart: ElementCollisionProfile mask JSON supports pixelMask[0m                                                                            
00:02 [32m+1303[0m: test/element_collision_profile_pixel_mask_json_test.dart: ElementCollisionProfile mask JSON supports pixelMask[0m                                                                            
00:02 [32m+1304[0m: test/element_collision_profile_pixel_mask_json_test.dart: ElementCollisionProfile mask JSON supports pixelMask[0m                                                                            
00:02 [32m+1304[0m: test/element_collision_profile_pixel_mask_json_test.dart: ElementCollisionProfile mask JSON ignores legacy non-map pixelMask while preserving cells[0m                                       
00:02 [32m+1305[0m: test/element_collision_profile_pixel_mask_json_test.dart: ElementCollisionProfile mask JSON ignores legacy non-map pixelMask while preserving cells[0m                                       
00:02 [32m+1305[0m: [1m[90mloading test/surface_catalog_diagnostics_presentation_test.dart[0m[0m                                                                                                                           
00:02 [32m+1305[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 1. empty report → clean presentation[0m                                         
00:02 [32m+1306[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 1. empty report → clean presentation[0m                                         
00:02 [32m+1307[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 1. empty report → clean presentation[0m                                         
00:02 [32m+1308[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 1. empty report → clean presentation[0m                                         
00:02 [32m+1309[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 1. empty report → clean presentation[0m                                         
00:02 [32m+1310[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 1. empty report → clean presentation[0m                                         
00:02 [32m+1310[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 2. one error: missingPresetAnimation[0m                                         
00:02 [32m+1311[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 2. one error: missingPresetAnimation[0m                                         
00:02 [32m+1311[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 3. one warning: unusedAtlas[0m                                                  
00:02 [32m+1312[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 3. one warning: unusedAtlas[0m                                                  
00:02 [32m+1312[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 4. mix ordered: 2 err then 2 warn[0m                                            
00:02 [32m+1313[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m                                                        
00:02 [32m+1314[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m                                                        
00:02 [32m+1315[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m                                                        
00:02 [32m+1316[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m                                                        
00:02 [32m+1317[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m                                                        
00:02 [32m+1318[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m                                                        
00:02 [32m+1319[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m                                                        
00:02 [32m+1320[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m                                                        
00:02 [32m+1321[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m                                                        
00:02 [32m+1322[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport vide : hasDiagnostics / erreurs / warnings[0m                                                        
00:02 [32m+1323[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 14. from diagnoseProjectSurfaceCatalogForAuthoring[0m                           
00:02 [32m+1324[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 14. from diagnoseProjectSurfaceCatalogForAuthoring[0m                           
00:02 [32m+1325[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 14. from diagnoseProjectSurfaceCatalogForAuthoring[0m                           
00:02 [32m+1326[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1327[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1328[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1329[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1330[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1331[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1332[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1333[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1334[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1335[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1336[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1337[0m: test/project_json_migrations_test.dart: project JSON migrations project manifest migration is exported and currently preserves input[0m                                                      
00:02 [32m+1338[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsReport égalité de valeur du rapport[0m                                                                      
00:02 [32m+1339[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 20. presentation inequality when content differs[0m                             
00:02 [32m+1340[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 20. presentation inequality when content differs[0m                             
00:02 [32m+1341[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsSummary vide : compteurs à 0[0m                                                                             
00:02 [32m+1342[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsSummary vide : compteurs à 0[0m                                                                             
00:02 [32m+1342[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 21. public API types via map_core[0m                                            
00:02 [32m+1343[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsSummary hasDiagnostics / hasErrors / hasWarnings[0m                                                         
00:02 [32m+1344[0m: test/environment_authoring_diagnostics_test.dart: EnvironmentAuthoringDiagnosticsSummary hasDiagnostics / hasErrors / hasWarnings[0m                                                         
00:02 [32m+1344[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 22. ProjectManifest: no Surface keys (Lot 38)[0m                                
00:02 [32m+1345[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 22. ProjectManifest: no Surface keys (Lot 38)[0m                                
00:02 [32m+1346[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 22. ProjectManifest: no Surface keys (Lot 38)[0m                                
00:02 [32m+1347[0m: test/surface_catalog_diagnostics_presentation_test.dart: buildSurfaceCatalogDiagnosticsPresentation (Lot 38) 22. ProjectManifest: no Surface keys (Lot 38)[0m                                
00:02 [32m+1347[0m: test/environment_authoring_diagnostics_test.dart: mapping usage diagnostic missingAreaPreset conservé[0m                                                                                     
00:02 [32m+1348[0m: test/environment_authoring_diagnostics_test.dart: mapping usage diagnostic missingAreaPreset conservé[0m                                                                                     
00:02 [32m+1349[0m: test/environment_authoring_diagnostics_test.dart: mapping usage diagnostic missingAreaPreset conservé[0m                                                                                     
00:02 [32m+1349[0m: test/environment_authoring_diagnostics_test.dart: ordre stable preset puis maps dans l’ordre fourni, ordre interne usage inchangé[0m                                                         
00:03 [32m+1350[0m: test/environment_authoring_diagnostics_test.dart: ordre stable preset puis maps dans l’ordre fourni, ordre interne usage inchangé[0m                                                         
00:03 [32m+1350[0m: test/environment_authoring_diagnostics_test.dart: diagnoseProjectEnvironmentAuthoring maps vide : seulement diagnostics preset[0m                                                            
00:03 [32m+1351[0m: test/environment_authoring_diagnostics_test.dart: diagnoseProjectEnvironmentAuthoring maps vide : seulement diagnostics preset[0m                                                            
00:03 [32m+1351[0m: test/environment_authoring_diagnostics_test.dart: diagnoseProjectEnvironmentAuthoring manifest et maps sans problème : rapport vide[0m                                                       
00:03 [32m+1352[0m: test/environment_authoring_diagnostics_test.dart: diagnoseProjectEnvironmentAuthoring manifest et maps sans problème : rapport vide[0m                                                       
00:03 [32m+1352[0m: test/environment_authoring_diagnostics_test.dart: diagnoseProjectEnvironmentAuthoring agrège preset + usage[0m                                                                               
00:03 [32m+1353[0m: test/environment_authoring_diagnostics_test.dart: diagnoseProjectEnvironmentAuthoring agrège preset + usage[0m                                                                               
00:03 [32m+1353[0m: test/environment_authoring_diagnostics_test.dart: diagnoseProjectEnvironmentAuthoring knownTemplateIds transmis à diagnoseProjectEnvironmentPresets[0m                                       
00:03 [32m+1354[0m: test/environment_authoring_diagnostics_test.dart: diagnoseProjectEnvironmentAuthoring knownTemplateIds transmis à diagnoseProjectEnvironmentPresets[0m                                       
00:03 [32m+1354[0m: [1m[90mloading test/project_manifest_surface_json_characterization_test.dart[0m[0m                                                                                                                     
00:03 [32m+1354[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model minimal current manifest parses and materializes defaults[0m       
00:03 [32m+1355[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 builds a pure plan for a minimal valid start to end scene[0m                                                                        
00:03 [32m+1356[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 builds a pure plan for a minimal valid start to end scene[0m                                                                        
00:03 [32m+1357[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 builds a pure plan for a minimal valid start to end scene[0m                                                                        
00:03 [32m+1358[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 builds a pure plan for a minimal valid start to end scene[0m                                                                        
00:03 [32m+1358[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model TilesetSourceRect preserves its grid coordinates and size[0m       
00:03 [32m+1359[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 ignores SceneGraphLayout when building the plan[0m                                                                                  
00:03 [32m+1360[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 ignores SceneGraphLayout when building the plan[0m                                                                                  
00:03 [32m+1361[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model TilesetVisualFrame with tileset override preserves the override[0m 
00:03 [32m+1362[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 preserves deterministic node and edge order from SceneGraph[0m                                                                      
00:03 [32m+1363[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model ProjectTerrainPreset preserves animated variants in order[0m       
00:03 [32m+1364[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 scene diagnostics errors block plan building cleanly[0m                                                                             
00:03 [32m+1365[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model ProjectPathPreset water preserves mappings and animated frames[0m  
00:03 [32m+1366[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model ProjectPathPreset water preserves mappings and animated frames[0m  
00:03 [32m+1367[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model ProjectPathPreset water preserves mappings and animated frames[0m  
00:03 [32m+1368[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 yarn dialogue payload becomes showDialogue intent without outcomes invented[0m                                                      
00:03 [32m+1369[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 yarn dialogue payload becomes showDialogue intent without outcomes invented[0m                                                      
00:03 [32m+1369[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model ProjectPathPreset tallGrass is known to JSON serialization[0m      
00:03 [32m+1370[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 battle payload becomes startBattle intent without importing battle runtime[0m                                                       
00:03 [32m+1371[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model PathLayer animationMode preserves always_active and triggered[0m   
00:03 [32m+1372[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model PathLayer animationMode preserves always_active and triggered[0m   
00:03 [32m+1373[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model PathLayer animationMode preserves always_active and triggered[0m   
00:03 [32m+1374[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model PathLayer animationMode preserves always_active and triggered[0m   
00:03 [32m+1375[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 typed setFact action nodes become applyConsequence intents[0m                                                                       
00:03 [32m+1376[0m: test/project_manifest_surface_json_characterization_test.dart: ProjectManifest JSON characterization before Surface model PathAnimationTriggerRule preserves current trigger fields[0m       
00:03 [32m+1377[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 typed markEventConsumed action nodes preserve consequence payload[0m                                                                
00:03 [32m+1378[0m: test/project_manifest_surface_json_characterization_test.dart: ... JSON characterization before Surface model PathLayer preserves presetId, cells, properties, mode and triggers[0m          
00:03 [32m+1379[0m: test/project_manifest_surface_json_characterization_test.dart: ... JSON characterization before Surface model PathLayer preserves presetId, cells, properties, mode and triggers[0m          
00:03 [32m+1380[0m: test/project_manifest_surface_json_characterization_test.dart: ... JSON characterization before Surface model PathLayer preserves presetId, cells, properties, mode and triggers[0m          
00:03 [32m+1380[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 does not mutate the original SceneAsset[0m                                                                                          
00:03 [32m+1381[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 does not mutate the original SceneAsset[0m                                                                                          
00:03 [32m+1382[0m: test/scene_runtime_plan_test.dart: Scene runtime plan V0 does not mutate the original SceneAsset[0m                                                                                          
00:03 [32m+1383[0m: test/project_manifest_surface_json_characterization_test.dart: ... JSON characterization before Surface model manifest business object remains stable after wire JSON round-trip[0m          
00:03 [32m+1384[0m: test/project_manifest_surface_json_characterization_test.dart: ... JSON characterization before Surface model manifest business object remains stable after wire JSON round-trip[0m          
00:03 [32m+1384[0m: [1m[90mloading test/scene_diagnostics_test.dart[0m[0m                                                                                                                                                  
00:03 [32m+1384[0m: test/scene_diagnostics_test.dart: Scene diagnostics V1-08 minimal draft has no blocking error[0m                                                                                             
00:03 [32m+1385[0m: test/path_center_pattern_test.dart: PathCenterPatternSize accepts 1x1 and 2x2 sizes[0m                                                                                                       
00:03 [32m+1386[0m: test/path_center_pattern_test.dart: PathCenterPatternSize accepts 1x1 and 2x2 sizes[0m                                                                                                       
00:03 [32m+1387[0m: test/path_center_pattern_test.dart: PathCenterPatternSize accepts 1x1 and 2x2 sizes[0m                                                                                                       
00:03 [32m+1388[0m: test/path_center_pattern_test.dart: PathCenterPatternSize accepts 1x1 and 2x2 sizes[0m                                                                                                       
00:03 [32m+1389[0m: test/path_center_pattern_test.dart: PathCenterPatternSize accepts 1x1 and 2x2 sizes[0m                                                                                                       
00:03 [32m+1390[0m: test/path_center_pattern_test.dart: PathCenterPatternSize accepts 1x1 and 2x2 sizes[0m                                                                                                       
00:03 [32m+1391[0m: test/scene_diagnostics_test.dart: Scene diagnostics condition node without source emits blocking diagnostic[0m                                                                               
00:03 [32m+1392[0m: test/path_center_pattern_test.dart: PathCenterPatternSize rejects non-positive dimensions[0m                                                                                                 
00:03 [32m+1393[0m: test/scene_diagnostics_test.dart: Scene diagnostics configured V0 condition source has no condition error[0m                                                                                 
00:03 [32m+1394[0m: test/path_center_pattern_test.dart: PathCenterPatternSize reports tile count and coordinate containment[0m                                                                                   
00:03 [32m+1395[0m: test/scene_diagnostics_test.dart: Scene diagnostics incompatible edge port emits blocking diagnostic[0m                                                                                      
00:03 [32m+1396[0m: test/path_center_pattern_test.dart: PathCenterPatternSize uses value equality and stable hashCode[0m                                                                                         
00:03 [32m+1397[0m: test/path_center_pattern_test.dart: PathCenterPatternSize uses value equality and stable hashCode[0m                                                                                         
00:03 [32m+1398[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1399[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1400[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1401[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1402[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1403[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1404[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1405[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1406[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1407[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1408[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1409[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1410[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1411[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1412[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1413[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1414[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1415[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1416[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1417[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1418[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1419[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1420[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1421[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1422[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1423[0m: test/element_collision_profile_model_test.dart: ElementCollisionProfile model serializes shape-authored collisions while keeping final cells[0m                                              
00:03 [32m+1424[0m: test/scene_diagnostics_test.dart: Scene diagnostics fact source references must resolve against ProjectManifest facts[0m                                                                     
00:03 [32m+1425[0m: test/scene_diagnostics_test.dart: Scene diagnostics fact source references must resolve against ProjectManifest facts[0m                                                                     
00:03 [32m+1426[0m: test/scene_diagnostics_test.dart: Scene diagnostics fact source references must resolve against ProjectManifest facts[0m                                                                     
00:03 [32m+1426[0m: test/scene_diagnostics_test.dart: Scene diagnostics setFact consequence references must resolve against facts[0m                                                                             
00:03 [32m+1427[0m: test/scene_diagnostics_test.dart: Scene diagnostics setFact consequence references must resolve against facts[0m                                                                             
00:03 [32m+1427[0m: test/scene_diagnostics_test.dart: Scene diagnostics markEventConsumed consequence references must resolve against maps[0m                                                                    
00:03 [32m+1428[0m: test/scene_diagnostics_test.dart: Scene diagnostics markEventConsumed consequence references must resolve against maps[0m                                                                    
00:03 [32m+1428[0m: test/scene_diagnostics_test.dart: Scene diagnostics future and incomplete condition sources are diagnosed[0m                                                                                 
00:03 [32m+1429[0m: test/scene_diagnostics_test.dart: Scene diagnostics future and incomplete condition sources are diagnosed[0m                                                                                 
00:03 [32m+1429[0m: [1m[90mloading test/surface_animation_timeline_test.dart[0m[0m                                                                                                                                         
00:03 [32m+1429[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline minimal timeline with one frame[0m                                                                                       
00:03 [32m+1430[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline minimal timeline with one frame[0m                                                                                       
00:03 [32m+1430[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline rejects empty frames list[0m                                                                                             
00:03 [32m+1431[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline rejects empty frames list[0m                                                                                             
00:03 [32m+1431[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline preserves frame order[0m                                                                                                 
00:03 [32m+1432[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline preserves frame order[0m                                                                                                 
00:03 [32m+1432[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline totalDurationMs sums frame durations[0m                                                                                  
00:03 [32m+1433[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline totalDurationMs sums frame durations[0m                                                                                  
00:03 [32m+1433[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline exposed frames list is unmodifiable[0m                                                                                   
00:03 [32m+1434[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline exposed frames list is unmodifiable[0m                                                                                   
00:03 [32m+1434[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline defensive copy: mutating source after construction does not affect timeline[0m                                           
00:03 [32m+1435[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline defensive copy: mutating source after construction does not affect timeline[0m                                           
00:03 [32m+1435[0m: test/surface_animation_timeline_test.dart: SurfaceAnimationTimeline isInside: true when all frames are inside grid[0m                                                                        
00:03 [32m+1436[0m: test/cinematic_asset_test.dart: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                          
00:03 [32m+1437[0m: test/cinematic_asset_test.dart: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                          
00:03 [32m+1438[0m: test/cinematic_asset_test.dart: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                          
00:03 [32m+1439[0m: test/cinematic_asset_test.dart: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                          
00:03 [32m+1440[0m: test/cinematic_asset_test.dart: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                          
00:03 [32m+1441[0m: test/cinematic_asset_test.dart: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                          
00:03 [32m+1442[0m: test/cinematic_asset_test.dart: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                          
00:03 [32m+1443[0m: test/cinematic_asset_test.dart: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                          
00:03 [32m+1444[0m: test/cinematic_asset_test.dart: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                          
00:03 [32m+1445[0m: test/cinematic_asset_test.dart: CinematicAsset round-trips a linear cinematic asset through JSON[0m                                                                                          
00:03 [32m+1445[0m: test/cinematic_asset_test.dart: CinematicAsset serializes cinematic stage context without duplicating map id[0m                                                                              
00:03 [32m+1446[0m: test/cinematic_asset_test.dart: CinematicAsset serializes cinematic stage context without duplicating map id[0m                                                                              
00:03 [32m+1446[0m: test/cinematic_asset_test.dart: CinematicAsset serializes cinematic actor appearance binding for cinematic only actor[0m                                                                     
00:03 [32m+1447[0m: test/cinematic_asset_test.dart: CinematicAsset serializes cinematic actor appearance binding for cinematic only actor[0m                                                                     
00:03 [32m+1447[0m: test/cinematic_asset_test.dart: CinematicAsset deserializes cinematic asset without actor appearance bindings[0m                                                                             
00:03 [32m+1448[0m: test/cinematic_asset_test.dart: CinematicAsset deserializes cinematic asset without actor appearance bindings[0m                                                                             
00:03 [32m+1448[0m: test/cinematic_asset_test.dart: CinematicAsset does not store character id inside actor binding[0m                                                                                           
00:03 [32m+1449[0m: test/cinematic_asset_test.dart: CinematicAsset does not store character id inside actor binding[0m                                                                                           
00:03 [32m+1449[0m: test/cinematic_asset_test.dart: CinematicAsset roundtrips actor appearance bindings in stage context[0m                                                                                      
00:03 [32m+1450[0m: test/cinematic_asset_test.dart: CinematicAsset roundtrips actor appearance bindings in stage context[0m                                                                                      
00:03 [32m+1450[0m: test/cinematic_asset_test.dart: CinematicAsset keeps actorAppearanceBindings empty by default[0m                                                                                             
00:03 [32m+1451[0m: test/cinematic_asset_test.dart: CinematicAsset keeps actorAppearanceBindings empty by default[0m                                                                                             
00:03 [32m+1451[0m: test/cinematic_asset_test.dart: CinematicAsset does not persist startMs or endMs for actor appearance binding[0m                                                                             
00:03 [32m+1452[0m: test/cinematic_asset_test.dart: CinematicAsset does not persist startMs or endMs for actor appearance binding[0m                                                                             
00:03 [32m+1452[0m: test/cinematic_asset_test.dart: CinematicAsset defaults missing movement targets to an empty list[0m                                                                                         
00:03 [32m+1453[0m: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics[0m                                                                               
00:03 [32m+1454[0m: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics[0m                                                                               
00:03 [32m+1455[0m: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics[0m                                                                               
00:03 [32m+1456[0m: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics[0m                                                                               
00:03 [32m+1457[0m: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport vide : pas de diagnostics[0m                                                                               
00:03 [32m+1458[0m: test/cinematic_asset_test.dart: CinematicAsset does not import Flutter, Flame, runtime, or editor packages[0m                                                                                
00:03 [32m+1459[0m: test/cinematic_asset_test.dart: CinematicAsset does not import Flutter, Flame, runtime, or editor packages[0m                                                                                
00:03 [32m+1460[0m: test/environment_preset_diagnostics_test.dart: EnvironmentPresetDiagnosticsReport errorCount / warningCount / diagnosticCount[0m                                                             
00:03 [32m+1461[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1462[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1463[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1464[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1465[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1466[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1467[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1468[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1469[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1470[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1471[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1472[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1473[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1474[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1475[0m: test/map_entity_runtime_rules_serialization_test.dart: Règles runtime PNJ (JSON) roundtrip visibilité + variantes dialogue + completedCutsceneIds[0m                                         
00:03 [32m+1476[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                       
00:03 [32m+1477[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                       
00:03 [32m+1478[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                       
00:03 [32m+1479[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                       
00:03 [32m+1480[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                       
00:03 [32m+1481[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                       
00:03 [32m+1482[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                       
00:03 [32m+1483[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 1. empty catalog: no diagnostics[0m                                                                       
00:03 [32m+1483[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 2. minimal coherent: no diagnostics[0m                                                                    
00:03 [32m+1484[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 2. minimal coherent: no diagnostics[0m                                                                    
00:03 [32m+1484[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 3. missing preset animation[0m                                                                            
00:03 [32m+1485[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 3. missing preset animation[0m                                                                            
00:03 [32m+1485[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 4. two missing refs: order follows refs[0m                                                                
00:03 [32m+1486[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 4. two missing refs: order follows refs[0m                                                                
00:03 [32m+1486[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 5. two presets: order follows catalog.presets[0m                                                          
00:03 [32m+1487[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 5. two presets: order follows catalog.presets[0m                                                          
00:03 [32m+1487[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 6. missing animation atlas[0m                                                                             
00:03 [32m+1488[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 6. missing animation atlas[0m                                                                             
00:03 [32m+1488[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 7. two frames to missing atlas: frameIndex 0 and 1[0m                                                     
00:03 [32m+1489[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 7. two frames to missing atlas: frameIndex 0 and 1[0m                                                     
00:03 [32m+1489[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 8. frame outside geometry: column[0m                                                                      
00:03 [32m+1490[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 8. frame outside geometry: column[0m                                                                      
00:03 [32m+1490[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 9. frame outside geometry: row[0m                                                                         
00:03 [32m+1491[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 9. frame outside geometry: row[0m                                                                         
00:03 [32m+1491[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 10. missing atlas only: not also outside geometry[0m                                                      
00:03 [32m+1492[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 10. missing atlas only: not also outside geometry[0m                                                      
00:03 [32m+1492[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 11. preset diagnostics then animation diagnostics[0m                                                      
00:03 [32m+1493[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 11. preset diagnostics then animation diagnostics[0m                                                      
00:03 [32m+1493[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim[0m                                                                            
00:03 [32m+1494[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 12. exact atlas id: no trim[0m                                                                            
00:03 [32m+1494[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters[0m                                                                                     
00:03 [32m+1495[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 13. byKind filters[0m                                                                                     
00:03 [32m+1495[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable[0m                                                                        
00:03 [32m+1496[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 14. byKind list is unmodifiable[0m                                                                        
00:03 [32m+1496[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable[0m                                                         
00:03 [32m+1497[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 15. diagnostics list on report is unmodifiable[0m                                                         
00:03 [32m+1497[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report[0m                                        
00:03 [32m+1498[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 16. defensive copy: mutating source list does not change report[0m                                        
00:03 [32m+1498[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report[0m                                                                    
00:03 [32m+1499[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 17. hasErrors false on empty report[0m                                                                    
00:03 [32m+1499[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic[0m                                                               
00:03 [32m+1500[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 18. hasErrors true when error diagnostic[0m                                                               
00:03 [32m+1500[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                          
00:03 [32m+1501[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 19. diagnostic equality: same[0m                                                                          
00:03 [32m+1501[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 20. diagnostic equality: different kind[0m                                                                
00:03 [32m+1502[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 20. diagnostic equality: different kind[0m                                                                
00:03 [32m+1502[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 21. diagnostic equality: different metadata[0m                                                            
00:03 [32m+1503[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 21. diagnostic equality: different metadata[0m                                                            
00:03 [32m+1503[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 22. report equality: same order[0m                                                                        
00:03 [32m+1504[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 22. report equality: same order[0m                                                                        
00:03 [32m+1504[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters[0m                                                                     
00:03 [32m+1505[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 23. report equality: order matters[0m                                                                     
00:03 [32m+1505[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core[0m                                                                            
00:03 [32m+1506[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 24. public API via map_core[0m                                                                            
00:03 [32m+1506[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                 
00:03 [32m+1507[0m: test/surface_catalog_diagnostics_test.dart: diagnoseProjectSurfaceCatalog (Lot 34) 25. ProjectManifest still has no Surface keys (Lot 34)[0m                                                 
00:03 [32m+1507[0m: [1m[90mloading test/project_manifest_environment_presets_test.dart[0m[0m                                                                                                                               
00:03 [32m+1507[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson sans environmentPresets => [][0m                                                       
00:03 [32m+1508[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson sans environmentPresets => [][0m                                                       
00:03 [32m+1508[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson avec environmentPresets null => [][0m                                                  
00:03 [32m+1509[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson avec environmentPresets null => [][0m                                                  
00:03 [32m+1509[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson avec environmentPresets complet => liste[0m                                            
00:03 [32m+1510[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON fromJson avec environmentPresets complet => liste[0m                                            
00:03 [32m+1510[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON toJson inclut environmentPresets[0m                                                             
00:03 [32m+1511[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON toJson inclut environmentPresets[0m                                                             
00:03 [32m+1511[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON JSON roundtrip avec un preset complet[0m                                                        
00:03 [32m+1512[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON JSON roundtrip avec un preset complet[0m                                                        
00:03 [32m+1512[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON environmentPresets non-list => FormatException[0m                                               
00:03 [32m+1513[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON environmentPresets non-list => FormatException[0m                                               
00:03 [32m+1513[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON environmentPresets avec item invalide => FormatException[0m                                     
00:03 [32m+1514[0m: test/project_manifest_environment_presets_test.dart: ProjectManifest environmentPresets JSON environmentPresets avec item invalide => FormatException[0m                                     
00:03 [32m+1514[0m: test/project_manifest_environment_presets_test.dart: project_manifest_environment_preset_operations readProjectEnvironmentPresets retourne la liste[0m                                       
00:03 [32m+1515[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations converts picker options into source drafts[0m                                        
00:03 [32m+1516[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations converts picker options into source drafts[0m                                        
00:03 [32m+1517[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations converts picker options into source drafts[0m                                        
00:03 [32m+1518[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations converts picker options into source drafts[0m                                        
00:03 [32m+1519[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations converts picker options into source drafts[0m                                        
00:03 [32m+1520[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations converts picker options into source drafts[0m                                        
00:03 [32m+1521[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations converts picker options into source drafts[0m                                        
00:03 [32m+1522[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations converts picker options into source drafts[0m                                        
00:03 [32m+1523[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations converts picker options into source drafts[0m                                        
00:03 [32m+1524[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                      
00:03 [32m+1525[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                      
00:03 [32m+1526[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                      
00:03 [32m+1527[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                      
00:03 [32m+1528[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                      
00:03 [32m+1529[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations compiles updated drafts with the correct source node for every source[0m             
00:03 [32m+1530[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations compiles updated drafts with the correct source node for every source[0m             
00:03 [32m+1530[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas preserves categoryId and sortOrder[0m                                                                                              
00:03 [32m+1531[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations does not hardcode Selbrume identifiers[0m                                            
00:03 [32m+1532[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations does not hardcode Selbrume identifiers[0m                                            
00:03 [32m+1533[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations does not hardcode Selbrume identifiers[0m                                            
00:03 [32m+1534[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations does not hardcode Selbrume identifiers[0m                                            
00:03 [32m+1535[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations does not hardcode Selbrume identifiers[0m                                            
00:03 [32m+1536[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations does not hardcode Selbrume identifiers[0m                                            
00:03 [32m+1537[0m: test/narrative_event_source_authoring_operations_test.dart: Narrative event source authoring operations does not hardcode Selbrume identifiers[0m                                            
00:03 [32m+1538[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas rejects empty tilesetId: whitespace only[0m                                                                                        
00:03 [32m+1539[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1540[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1541[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1542[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1543[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1544[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1545[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1546[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1547[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1548[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1549[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline empty frames staticFrame resolves to a completed empty result[0m                                                          
00:03 [32m+1550[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas ProjectManifest toJson: no top-level surface* keys[0m                                                                              
00:03 [32m+1551[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas ProjectManifest toJson: no top-level surface* keys[0m                                                                              
00:03 [32m+1552[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas ProjectManifest toJson: no top-level surface* keys[0m                                                                              
00:03 [32m+1553[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas ProjectManifest toJson: no top-level surface* keys[0m                                                                              
00:03 [32m+1554[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas ProjectManifest toJson: no top-level surface* keys[0m                                                                              
00:03 [32m+1555[0m: test/project_surface_atlas_test.dart: ProjectSurfaceAtlas ProjectManifest toJson: no top-level surface* keys[0m                                                                              
00:03 [32m+1556[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline staticFrame with multiple frames always returns the first frame[0m                                                        
00:03 [32m+1557[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline staticFrame with multiple frames always returns the first frame[0m                                                        
00:03 [32m+1557[0m: test/tile_visual_frame_timeline_test.dart: TileVisualFrameTimeline loop with two equal frames follows frame boundaries[0m                                                                    
00:03 [32m+1558[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves an isolated placement[0m                                                                        
00:03 [32m+1559[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves an isolated placement[0m                                                                        
00:03 [32m+1560[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves an isolated placement[0m                                                                        
00:03 [32m+1561[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves an isolated placement[0m                                                                        
00:03 [32m+1562[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves an isolated placement[0m                                                                        
00:03 [32m+1563[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves an isolated placement[0m                                                                        
00:03 [32m+1564[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves an isolated placement[0m                                                                        
00:03 [32m+1565[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves an isolated placement[0m                                                                        
00:03 [32m+1566[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves an isolated placement[0m                                                                        
00:03 [32m+1567[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves an isolated placement[0m                                                                        
00:03 [32m+1567[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves the middle of a horizontal line[0m                                                              
00:03 [32m+1568[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves the middle of a horizontal line[0m                                                              
00:03 [32m+1568[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves the middle of a vertical line[0m                                                                
00:03 [32m+1569[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves the middle of a vertical line[0m                                                                
00:03 [32m+1569[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves the center of a full 3x3 block as cross[0m                                                      
00:03 [32m+1570[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves the center of a full 3x3 block as cross[0m                                                      
00:03 [32m+1570[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves a cardinal corner when two adjacent neighbors match[0m                                          
00:03 [32m+1571[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement resolves a cardinal corner when two adjacent neighbors match[0m                                          
00:03 [32m+1571[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement does not connect adjacent placements from another preset[0m                                              
00:03 [32m+1572[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement does not connect adjacent placements from another preset[0m                                              
00:03 [32m+1572[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement is independent from placement ordering[0m                                                                
00:03 [32m+1573[0m: test/surface_variant_role_resolver_test.dart: resolveSurfaceVariantRoleForPlacement is independent from placement ordering[0m                                                                
00:03 [32m+1573[0m: [1m[90mloading test/project_path_pattern_preset_test.dart[0m[0m                                                                                                                                        
00:03 [32m+1573[0m: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset creates a minimal preset with defaults[0m                                                                               
00:03 [32m+1574[0m: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset creates a minimal preset with defaults[0m                                                                               
00:03 [32m+1574[0m: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset creates a complete preset with a 2x2 center pattern[0m                                                                  
00:03 [32m+1575[0m: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset creates a complete preset with a 2x2 center pattern[0m                                                                  
00:03 [32m+1575[0m: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset rejects blank identity fields[0m                                                                                        
00:03 [32m+1576[0m: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset rejects blank identity fields[0m                                                                                        
00:03 [32m+1576[0m: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset validates with trim but stores original strings[0m                                                                      
00:03 [32m+1577[0m: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset validates with trim but stores original strings[0m                                                                      
00:03 [32m+1577[0m: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset supports value equality and stable hashCode[0m                                                                          
00:03 [32m+1578[0m: test/project_path_pattern_preset_test.dart: ProjectPathPatternPreset supports value equality and stable hashCode[0m                                                                          
00:03 [32m+1578[0m: [1m[90mloading test/surface_catalog_diagnostics_summary_test.dart[0m[0m                                                                                                                                
00:03 [32m+1578[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 1. empty report → clean summary[0m                                                           
00:03 [32m+1579[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 1. empty report → clean summary[0m                                                           
00:03 [32m+1579[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 2. one error missingPresetAnimation[0m                                                       
00:03 [32m+1580[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 2. one error missingPresetAnimation[0m                                                       
00:03 [32m+1580[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 3. one warning unusedAtlas[0m                                                                
00:03 [32m+1581[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 3. one warning unusedAtlas[0m                                                                
00:03 [32m+1581[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 4. mixed: 2+1 errors, 1+3 warnings, counts by kind[0m                                        
00:03 [32m+1582[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 4. mixed: 2+1 errors, 1+3 warnings, counts by kind[0m                                        
00:03 [32m+1582[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 5. countByKind only present kinds; countForKind 0 for absent[0m                              
00:03 [32m+1583[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 5. countByKind only present kinds; countForKind 0 for absent[0m                              
00:03 [32m+1583[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 6. countByKind is unmodifiable[0m                                                            
00:03 [32m+1584[0m: test/surface_to_gameplay_zone_generation_plan_test.dart: SurfaceGameplayZoneGenerationSource rejects an empty source[0m                                                                      
00:03 [32m+1585[0m: test/surface_to_gameplay_zone_generation_plan_test.dart: SurfaceGameplayZoneGenerationSource rejects an empty source[0m                                                                      
00:03 [32m+1586[0m: test/surface_to_gameplay_zone_generation_plan_test.dart: SurfaceGameplayZoneGenerationSource rejects an empty source[0m                                                                      
00:03 [32m+1587[0m: test/surface_to_gameplay_zone_generation_plan_test.dart: SurfaceGameplayZoneGenerationSource rejects an empty source[0m                                                                      
00:03 [32m+1588[0m: test/surface_to_gameplay_zone_generation_plan_test.dart: SurfaceGameplayZoneGenerationSource rejects an empty source[0m                                                                      
00:03 [32m+1589[0m: test/surface_to_gameplay_zone_generation_plan_test.dart: SurfaceGameplayZoneGenerationSource rejects an empty source[0m                                                                      
00:03 [32m+1590[0m: test/surface_to_gameplay_zone_generation_plan_test.dart: SurfaceGameplayZoneGenerationSource rejects an empty source[0m                                                                      
00:03 [32m+1591[0m: test/surface_to_gameplay_zone_generation_plan_test.dart: SurfaceGameplayZoneGenerationSource rejects an empty source[0m                                                                      
00:03 [32m+1592[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 14. public API via map_core[0m                                                               
00:03 [32m+1593[0m: test/surface_to_gameplay_zone_generation_plan_test.dart: SurfaceGameplayZoneGenerationSource rejects an empty surfacePresetId[0m                                                             
00:03 [32m+1594[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 15. ProjectManifest still has no Surface keys (Lot 37)[0m                                    
00:03 [32m+1595[0m: test/surface_catalog_diagnostics_summary_test.dart: summarizeSurfaceCatalogDiagnostics (Lot 37) 15. ProjectManifest still has no Surface keys (Lot 37)[0m                                    
00:03 [32m+1596[0m: test/surface_to_gameplay_zone_generation_plan_test.dart: createSurfaceGameplayZoneGenerationPlan boundingBox generates one exact zone for a full rectangle[0m                                
00:03 [32m+1597[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1598[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1599[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1600[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1601[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1602[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1603[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1604[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1605[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1606[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1607[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1608[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1609[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1610[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep adds an existing scene id[0m                                               
00:03 [32m+1611[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation accepts a minimal authoring draft[0m                                                           
00:03 [32m+1612[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation accepts a minimal authoring draft[0m                                                           
00:03 [32m+1613[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation accepts a minimal authoring draft[0m                                                           
00:03 [32m+1614[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation accepts a minimal authoring draft[0m                                                           
00:03 [32m+1614[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations linkSceneToStorylineStep refuses unknown scene id[0m                                                
00:03 [32m+1615[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation rejects empty scenario id and name[0m                                                          
00:03 [32m+1616[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation rejects empty scenario id and name[0m                                                          
00:03 [32m+1617[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations unlinkSceneFromStorylineStep removes only selected scene id[0m                                      
00:03 [32m+1618[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation rejects missing source and required source references[0m                                       
00:03 [32m+1619[0m: test/storyline_authoring_operations_test.dart: Storyline scene link authoring operations replaceStorylineStepSceneLinks preserves order without duplicates[0m                                
00:03 [32m+1620[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation rejects actions with missing required references[0m                                            
00:03 [32m+1621[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation rejects actions with missing required references[0m                                            
00:03 [32m+1621[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation detects emitted and declared outcome drift[0m                                                  
00:03 [32m+1622[0m: test/narrative_scenario_authoring_draft_test.dart: NarrativeScenarioAuthoringDraft validation detects emitted and declared outcome drift[0m                                                  
00:03 [32m+1622[0m: test/narrative_scenario_authoring_draft_test.dart: compileNarrativeScenarioAuthoringDraftToScenarioAsset compiles mapEnter with linear actions into a deterministic asset[0m                 
00:03 [32m+1623[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                          
00:03 [32m+1624[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                          
00:03 [32m+1625[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                          
00:03 [32m+1626[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                          
00:03 [32m+1627[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 1. empty catalog: summary, lists, clean diagnostics[0m                                                          
00:03 [32m+1627[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                   
00:03 [32m+1628[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 2. buildSurfaceStudioReadModel uses manifest catalog; no manifest mutation[0m                                   
00:03 [32m+1628[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 3. minimal water — summary counts and non-empty[0m                                                              
00:03 [32m+1629[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 3. minimal water — summary counts and non-empty[0m                                                              
00:03 [32m+1629[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 4. minimal water — atlas row main fields[0m                                                                     
00:03 [32m+1630[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 4. minimal water — atlas row main fields[0m                                                                     
00:03 [32m+1630[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 5. atlas rows preserve catalog order[0m                                                                         
00:03 [32m+1631[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 5. atlas rows preserve catalog order[0m                                                                         
00:03 [32m+1631[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 6. atlas usedByAnimationIds — two animations, one atlas[0m                                                      
00:03 [32m+1632[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 6. atlas usedByAnimationIds — two animations, one atlas[0m                                                      
00:03 [32m+1632[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 7. atlas usedByAnimationIds — one animation twice same atlas[0m                                                 
00:03 [32m+1633[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 7. atlas usedByAnimationIds — one animation twice same atlas[0m                                                 
00:03 [32m+1633[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 8. minimal water — animation row main fields[0m                                                                 
00:03 [32m+1634[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 8. minimal water — animation row main fields[0m                                                                 
00:03 [32m+1634[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 9. animation rows preserve catalog order[0m                                                                     
00:03 [32m+1635[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 9. animation rows preserve catalog order[0m                                                                     
00:03 [32m+1635[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 10. animation referencedAtlasIds — first appearance order[0m                                                    
00:03 [32m+1636[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 10. animation referencedAtlasIds — first appearance order[0m                                                    
00:03 [32m+1636[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 11. animation read model does not validate atlas existence[0m                                                   
00:03 [32m+1637[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 11. animation read model does not validate atlas existence[0m                                                   
00:03 [32m+1637[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 12. minimal water — preset row main fields[0m                                                                   
00:03 [32m+1638[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 12. minimal water — preset row main fields[0m                                                                   
00:03 [32m+1638[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 13. preset rows preserve catalog order[0m                                                                       
00:03 [32m+1639[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 13. preset rows preserve catalog order[0m                                                                       
00:03 [32m+1639[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 14. preset referencedAnimationIds — dedupe keeps order[0m                                                       
00:03 [32m+1640[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 14. preset referencedAnimationIds — dedupe keeps order[0m                                                       
00:03 [32m+1640[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 15. preset read model does not validate animation existence[0m                                                  
00:03 [32m+1641[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 15. preset read model does not validate animation existence[0m                                                  
00:03 [32m+1641[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 16. full water — preset role order cross, isolated, horizontal[0m                                               
00:03 [32m+1642[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 16. full water — preset role order cross, isolated, horizontal[0m                                               
00:03 [32m+1642[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 17. minimal water — diagnostics clean flags on read model[0m                                                    
00:03 [32m+1643[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 17. minimal water — diagnostics clean flags on read model[0m                                                    
00:03 [32m+1643[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 18. diagnostics error — missing animation atlas[0m                                                              
00:03 [32m+1644[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 18. diagnostics error — missing animation atlas[0m                                                              
00:03 [32m+1644[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 19. diagnostics error — missing preset animation[0m                                                             
00:03 [32m+1645[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 19. diagnostics error — missing preset animation[0m                                                             
00:03 [32m+1645[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 20. diagnostics warning — unused atlas[0m                                                                       
00:03 [32m+1646[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 20. diagnostics warning — unused atlas[0m                                                                       
00:03 [32m+1646[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 21. root lists are unmodifiable[0m                                                                              
00:03 [32m+1647[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 21. root lists are unmodifiable[0m                                                                              
00:03 [32m+1647[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 22. nested lists are unmodifiable[0m                                                                            
00:03 [32m+1648[0m: test/placed_element_animation_one_shot_test.dart: resolvePlacedElementAnimationOneShotFrame advances one cycle then marks as completed[0m                                                    
00:03 [32m+1649[0m: test/placed_element_animation_one_shot_test.dart: resolvePlacedElementAnimationOneShotFrame advances one cycle then marks as completed[0m                                                    
00:03 [32m+1650[0m: test/placed_element_animation_one_shot_test.dart: resolvePlacedElementAnimationOneShotFrame advances one cycle then marks as completed[0m                                                    
00:03 [32m+1651[0m: test/placed_element_animation_one_shot_test.dart: resolvePlacedElementAnimationOneShotFrame advances one cycle then marks as completed[0m                                                    
00:03 [32m+1652[0m: test/placed_element_animation_one_shot_test.dart: resolvePlacedElementAnimationOneShotFrame advances one cycle then marks as completed[0m                                                    
00:03 [32m+1653[0m: test/placed_element_animation_one_shot_test.dart: resolvePlacedElementAnimationOneShotFrame advances one cycle then marks as completed[0m                                                    
00:03 [32m+1654[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 28. ProjectManifest toJson still Lot 49 — surfaceCatalog only[0m                                                
00:03 [32m+1655[0m: test/surface_studio_read_model_test.dart: Surface Studio read model (Lot 51) 28. ProjectManifest toJson still Lot 49 — surfaceCatalog only[0m                                                
00:03 [32m+1656[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 1. encodeSurfaceVariantRole isolated[0m                                              
00:03 [32m+1657[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 1. encodeSurfaceVariantRole isolated[0m                                              
00:03 [32m+1658[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 1. encodeSurfaceVariantRole isolated[0m                                              
00:03 [32m+1659[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 1. encodeSurfaceVariantRole isolated[0m                                              
00:03 [32m+1659[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 2. decodeSurfaceVariantRole isolated[0m                                              
00:03 [32m+1660[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 2. decodeSurfaceVariantRole isolated[0m                                              
00:03 [32m+1660[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 3. round-trip every SurfaceVariantRole.values[0m                                     
00:03 [32m+1661[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 3. round-trip every SurfaceVariantRole.values[0m                                     
00:03 [32m+1661[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 4. standardSurfaceVariantRoleOrder: order preserved, each round-trips[0m             
00:03 [32m+1662[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 4. standardSurfaceVariantRoleOrder: order preserved, each round-trips[0m             
00:03 [32m+1662[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 5. decode rejects unknown role string[0m                                             
00:03 [32m+1663[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 5. decode rejects unknown role string[0m                                             
00:03 [32m+1663[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 6. decode rejects wrong casing[0m                                                    
00:03 [32m+1664[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 6. decode rejects wrong casing[0m                                                    
00:03 [32m+1664[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 7. decode rejects valid name with surrounding spaces[0m                              
00:03 [32m+1665[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 7. decode rejects valid name with surrounding spaces[0m                              
00:03 [32m+1665[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 8. encode SurfaceVariantAnimationRef[0m                                              
00:03 [32m+1666[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 8. encode SurfaceVariantAnimationRef[0m                                              
00:03 [32m+1666[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 9. decode SurfaceVariantAnimationRef[0m                                              
00:03 [32m+1667[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1668[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1669[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1670[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1671[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1672[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1673[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1674[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1675[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1676[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1677[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1678[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1679[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1680[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 1. encodes empty catalog[0m                                                                     
00:03 [32m+1681[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 23. ProjectManifest has no surface persistence keys (Lot 43)[0m                      
00:03 [32m+1682[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 23. ProjectManifest has no surface persistence keys (Lot 43)[0m                      
00:03 [32m+1683[0m: test/surface_variant_animation_ref_json_codec_test.dart: SurfaceVariantAnimationRef JSON codec (Lot 43) 23. ProjectManifest has no surface persistence keys (Lot 43)[0m                      
00:03 [32m+1684[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1685[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1686[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1687[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1688[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1689[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1690[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1691[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1692[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1693[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1694[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1695[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1696[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1697[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1698[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1699[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1700[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1701[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1702[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1703[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1704[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1705[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1706[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1707[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1708[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1709[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel lists linked scenes with labels and available picker options[0m                                       
00:03 [32m+1710[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 25. decode rejects duplicate atlas ids (model)[0m                                               
00:03 [32m+1711[0m: test/storyline_scene_links_read_model_test.dart: buildStorylineStepSceneLinksReadModel reports missing linked scenes without requiring runtime state[0m                                      
00:03 [32m+1712[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 26. decode rejects duplicate animation ids (model)[0m                                           
00:03 [32m+1713[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 26. decode rejects duplicate animation ids (model)[0m                                           
00:03 [32m+1713[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 27. decode rejects duplicate preset ids (model)[0m                                              
00:03 [32m+1714[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 27. decode rejects duplicate preset ids (model)[0m                                              
00:03 [32m+1714[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 28. decode ignores unknown top-level key[0m                                                     
00:03 [32m+1715[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 28. decode ignores unknown top-level key[0m                                                     
00:03 [32m+1715[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 29. decode ignores unknown keys in child items[0m                                               
00:03 [32m+1716[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 29. decode ignores unknown keys in child items[0m                                               
00:03 [32m+1716[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 30. decode does not mutate source map[0m                                                        
00:03 [32m+1717[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 30. decode does not mutate source map[0m                                                        
00:03 [32m+1717[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 31. encode does not mutate catalog[0m                                                           
00:03 [32m+1718[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 31. encode does not mutate catalog[0m                                                           
00:03 [32m+1718[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 32. codec does not resolve animationId; diagnostics catch missing[0m                            
00:03 [32m+1719[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 32. codec does not resolve animationId; diagnostics catch missing[0m                            
00:03 [32m+1719[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 33. codec does not resolve atlasId; diagnostics catch missing atlas[0m                          
00:03 [32m+1720[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 33. codec does not resolve atlasId; diagnostics catch missing atlas[0m                          
00:03 [32m+1720[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 34. codec does not check geometry; diagnostics catch out of bounds[0m                           
00:03 [32m+1721[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 34. codec does not check geometry; diagnostics catch out of bounds[0m                           
00:03 [32m+1721[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 35. codec does not call unused diagnostics; unused can warn after[0m                            
00:03 [32m+1722[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 35. codec does not call unused diagnostics; unused can warn after[0m                            
00:03 [32m+1722[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 36. reuses Lot 39 atlas codec for atlases[0][0m                                                 
00:03 [32m+1723[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 36. reuses Lot 39 atlas codec for atlases[0][0m                                                 
00:03 [32m+1723[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 37. reuses Lot 42 animation codec for animations[0][0m                                          
00:03 [32m+1724[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 37. reuses Lot 42 animation codec for animations[0][0m                                          
00:03 [32m+1724[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 38. reuses Lot 45 preset codec for presets[0][0m                                                
00:03 [32m+1725[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 38. reuses Lot 45 preset codec for presets[0][0m                                                
00:03 [32m+1725[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 39. public API encode returns map[0m                                                            
00:03 [32m+1726[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 39. public API encode returns map[0m                                                            
00:03 [32m+1726[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 40. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m                      
00:03 [32m+1727[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 40. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m                      
00:03 [32m+1727[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 41. codec external to model: no catalog.toJson or ProjectSurfaceCatalog.fromJson[0m             
00:03 [32m+1728[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 41. codec external to model: no catalog.toJson or ProjectSurfaceCatalog.fromJson[0m             
00:03 [32m+1728[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 42. catalog encode still independent of manifest (Lot 49 uses same encode)[0m                   
00:03 [32m+1729[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 42. catalog encode still independent of manifest (Lot 49 uses same encode)[0m                   
00:03 [32m+1729[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 43. no Surface categories array; categoryId stays per-item string[0m                            
00:03 [32m+1730[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 43. no Surface categories array; categoryId stays per-item string[0m                            
00:03 [32m+1730[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 44. no kind / surfaceKind / presetKind / type at catalog or preset JSON[0m                      
00:03 [32m+1731[0m: test/project_surface_catalog_json_codec_test.dart: ProjectSurfaceCatalog JSON codec (Lot 46) 44. no kind / surfaceKind / presetKind / type at catalog or preset JSON[0m                      
00:03 [32m+1731[0m: [1m[90mloading test/surface_animation_frame_test.dart[0m[0m                                                                                                                                            
00:03 [32m+1731[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                  
00:03 [32m+1732[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame minimal frame holds tileRef and durationMs[0m                                                                                  
00:03 [32m+1732[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame preserves the exact same tileRef instance (identity)[0m                                                                        
00:03 [32m+1733[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1734[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1735[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1736[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1737[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1738[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1739[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1740[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1741[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1742[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1743[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1744[0m: test/narrative_fact_test.dart: NarrativeFactDefinition creates a bool-first fact definition with stable metadata[0m                                                                          
00:03 [32m+1745[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame ProjectManifest toJson: no surface* top-level keys[0m                                                                          
00:03 [32m+1746[0m: test/surface_animation_frame_test.dart: SurfaceAnimationFrame ProjectManifest toJson: no surface* top-level keys[0m                                                                          
00:03 [32m+1747[0m: test/narrative_fact_test.dart: NarrativeFactDefinition round-trips through JSON[0m                                                                                                           
00:03 [32m+1748[0m: test/narrative_fact_test.dart: NarrativeFactDefinition round-trips through JSON[0m                                                                                                           
00:03 [32m+1748[0m: [1m[90mloading test/cinematic_map_backdrop_preview_model_test.dart[0m[0m                                                                                                                               
00:03 [32m+1748[0m: test/cinematic_map_backdrop_preview_model_test.dart: CinematicMapBackdropPreviewModel builds available cinematic map backdrop preview model from project map and map data[0m                 
00:03 [32m+1749[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1750[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1751[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1752[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1753[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1754[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1755[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1756[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1757[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1758[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1759[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1760[0m: test/map_events_test.dart: map event scene targets reads older page JSON without sceneTarget as null[0m                                                                                      
00:03 [32m+1760[0m: test/cinematic_map_backdrop_preview_model_test.dart: CinematicMapBackdropPreviewModel falls back to layer summary when no spatial data is available[0m                                       
00:03 [32m+1761[0m: test/map_events_test.dart: map event scene targets round-trips page JSON with sceneTarget[0m                                                                                                 
00:03 [32m+1762[0m: test/map_events_test.dart: map event scene targets round-trips page JSON with sceneTarget[0m                                                                                                 
00:03 [32m+1763[0m: test/map_events_test.dart: map event scene targets round-trips page JSON with sceneTarget[0m                                                                                                 
00:03 [32m+1764[0m: test/cinematic_map_backdrop_preview_model_test.dart: CinematicMapBackdropPreviewModel builds human map label from project map entry[0m                                                       
00:03 [32m+1765[0m: test/map_events_test.dart: map event scene targets copyWith preserves sceneTarget[0m                                                                                                         
00:03 [32m+1766[0m: test/map_events_test.dart: map event scene targets copyWith preserves sceneTarget[0m                                                                                                         
00:03 [32m+1767[0m: test/map_events_test.dart: map event scene targets copyWith preserves sceneTarget[0m                                                                                                         
00:03 [32m+1768[0m: test/cinematic_map_backdrop_preview_model_test.dart: CinematicMapBackdropPreviewModel builds viewport recommendation without Flutter or Flame[0m                                             
00:03 [32m+1769[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                          
00:03 [32m+1770[0m: test/map_events_test.dart: map events operations add update and remove map event[0m                                                                                                          
00:03 [32m+1771[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics[0m                                                                      
00:03 [32m+1772[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics[0m                                                                      
00:03 [32m+1773[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics[0m                                                                      
00:03 [32m+1774[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics[0m                                                                      
00:03 [32m+1775[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics[0m                                                                      
00:03 [32m+1776[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics[0m                                                                      
00:03 [32m+1777[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics[0m                                                                      
00:03 [32m+1778[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 valid minimal golden slice returns no diagnostics[0m                                                                      
00:03 [32m+1778[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 unknown edge target produces error[0m                                                                                     
00:03 [32m+1779[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 unknown edge target produces error[0m                                                                                     
00:03 [32m+1779[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 unreachable node produces warning[0m                                                                                      
00:03 [32m+1780[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 unreachable node produces warning[0m                                                                                      
00:03 [32m+1780[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 scenario without source produces error[0m                                                                                 
00:03 [32m+1781[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 scenario without source produces error[0m                                                                                 
00:03 [32m+1781[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 openDialogue with unknown dialogue produces error[0m                                                                      
00:03 [32m+1782[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 openDialogue with unknown dialogue produces error[0m                                                                      
00:03 [32m+1782[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 startTrainerBattle with unknown trainer produces error[0m                                                                 
00:03 [32m+1783[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 startTrainerBattle with unknown trainer produces error[0m                                                                 
00:03 [32m+1783[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 startTrainerBattle with blank trainerId produces error[0m                                                                 
00:03 [32m+1784[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 startTrainerBattle with blank trainerId produces error[0m                                                                 
00:03 [32m+1784[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 startTrainerBattle with blank npcEntityId produces error[0m                                                               
00:03 [32m+1785[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 startTrainerBattle with blank npcEntityId produces error[0m                                                               
00:03 [32m+1785[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 startTrainerBattle with explicit blank battleId produces error[0m                                                         
00:03 [32m+1786[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 startTrainerBattle with explicit blank battleId produces error[0m                                                         
00:03 [32m+1786[0m: test/narrative_validator_test.dart: Narrative Validator Minimal V0 source entityInteract with unknown map produces error[0m                                                                  
00:03 [32m+1787[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1788[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1789[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1790[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1791[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1792[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1793[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1794[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1795[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1796[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1797[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1798[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1799[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1800[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1801[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice fixture JSON se décode et reste canonique[0m                                                
00:03 [32m+1802[0m: test/narrative_outcome_authoring_operations_test.dart: Narrative outcome authoring operations creates outcomeReceived source from outcome picker option[0m                                   
00:03 [32m+1803[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice roundtrip conserve eau 2x2 animée, variants partiels, cross et override[0m                  
00:03 [32m+1804[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice roundtrip conserve eau 2x2 animée, variants partiels, cross et override[0m                  
00:03 [32m+1805[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice roundtrip conserve eau 2x2 animée, variants partiels, cross et override[0m                  
00:03 [32m+1806[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice roundtrip conserve eau 2x2 animée, variants partiels, cross et override[0m                  
00:03 [32m+1807[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice roundtrip conserve eau 2x2 animée, variants partiels, cross et override[0m                  
00:03 [32m+1808[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice roundtrip conserve eau 2x2 animée, variants partiels, cross et override[0m                  
00:03 [32m+1809[0m: test/path_pattern_water_animated_golden_slice_test.dart: PathPattern water animated golden slice roundtrip conserve eau 2x2 animée, variants partiels, cross et override[0m                  
00:03 [32m+1810[0m: test/narrative_outcome_authoring_operations_test.dart: Narrative outcome authoring operations throws for empty direct flag references[0m                                                     
00:03 [32m+1811[0m: test/narrative_outcome_authoring_operations_test.dart: Narrative outcome authoring operations throws for empty direct flag references[0m                                                     
00:03 [32m+1811[0m: test/narrative_outcome_authoring_operations_test.dart: Narrative outcome authoring operations does not hardcode Selbrume identifiers[0m                                                      
00:03 [32m+1812[0m: test/placed_elements_test.dart: placedElements identity buildMapPlacedElementId is stable across element changes[0m                                                                          
00:03 [32m+1813[0m: test/placed_elements_test.dart: placedElements identity buildMapPlacedElementId is stable across element changes[0m                                                                          
00:03 [32m+1813[0m: test/placed_elements_test.dart: placedElements operations removeMapLayer removes placed elements tied to layer[0m                                                                            
00:03 [32m+1814[0m: test/placed_elements_test.dart: placedElements operations removeMapLayer removes placed elements tied to layer[0m                                                                            
00:03 [32m+1814[0m: test/placed_elements_test.dart: placedElements operations resizeMapData removes placed elements with origin outside bounds[0m                                                                
00:03 [32m+1815[0m: test/placed_elements_test.dart: placedElements operations resizeMapData removes placed elements with origin outside bounds[0m                                                                
00:03 [32m+1815[0m: test/placed_elements_test.dart: placedElements validation MapValidator rejects mismatch between layer tileset and element[0m                                                                 
00:03 [32m+1816[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 1. minimal preset: fields and variantCount[0m                                                                                    
00:03 [32m+1817[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 1. minimal preset: fields and variantCount[0m                                                                                    
00:03 [32m+1818[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 1. minimal preset: fields and variantCount[0m                                                                                    
00:03 [32m+1818[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 2. preserves exact same variantAnimations instance[0m                                                                            
00:03 [32m+1819[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 2. preserves exact same variantAnimations instance[0m                                                                            
00:03 [32m+1819[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 3. preserves categoryId and sortOrder[0m                                                                                         
00:03 [32m+1820[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 3. preserves categoryId and sortOrder[0m                                                                                         
00:03 [32m+1820[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 4. stores id and name exactly without auto-trim[0m                                                                               
00:03 [32m+1821[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 4. stores id and name exactly without auto-trim[0m                                                                               
00:03 [32m+1821[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 5. rejects empty id: empty and whitespace[0m                                                                                     
00:03 [32m+1822[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 5. rejects empty id: empty and whitespace[0m                                                                                     
00:03 [32m+1822[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 6. rejects empty name: empty and whitespace[0m                                                                                   
00:03 [32m+1823[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 6. rejects empty name: empty and whitespace[0m                                                                                   
00:03 [32m+1823[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 7. does not over-validate categoryId: empty and whitespace allowed[0m                                                            
00:03 [32m+1824[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 7. does not over-validate categoryId: empty and whitespace allowed[0m                                                            
00:03 [32m+1824[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 8. allows negative sortOrder[0m                                                                                                  
00:03 [32m+1825[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 8. allows negative sortOrder[0m                                                                                                  
00:03 [32m+1825[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 9. delegating containsRole[0m                                                                                                    
00:03 [32m+1826[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 9. delegating containsRole[0m                                                                                                    
00:03 [32m+1826[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 10. delegating refForRole: present and absent[0m                                                                                 
00:03 [32m+1827[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 10. delegating refForRole: present and absent[0m                                                                                 
00:03 [32m+1827[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 11. delegating animationIdForRole: present and absent[0m                                                                         
00:03 [32m+1828[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 11. delegating animationIdForRole: present and absent[0m                                                                         
00:03 [32m+1828[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 12. delegating coversAllRoles[0m                                                                                                 
00:03 [32m+1829[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 12. delegating coversAllRoles[0m                                                                                                 
00:03 [32m+1829[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 13. can cover exactly standardSurfaceVariantRoleOrder[0m                                                                         
00:03 [32m+1830[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 13. can cover exactly standardSurfaceVariantRoleOrder[0m                                                                         
00:03 [32m+1830[0m: test/project_surface_preset_test.dart: ProjectSurfacePreset 14. value equality: identical presets are equal and same hashCode[0m                                                             
00:03 [32m+1831[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1832[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1833[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1834[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1835[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1836[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1837[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1838[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1839[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1840[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1841[0m: test/path_animation_triggers_test.dart: Path animation triggers serializes and deserializes animationTriggers on PathLayer[0m                                                                
00:03 [32m+1841[0m: test/path_animation_triggers_test.dart: Path animation triggers legacy PathLayer without animationTriggers remains valid[0m                                                                  
00:03 [32m+1842[0m: test/path_animation_triggers_test.dart: Path animation triggers legacy PathLayer without animationTriggers remains valid[0m                                                                  
00:03 [32m+1842[0m: test/path_animation_triggers_test.dart: Path animation triggers validator rejects invalid whileInside/mode combinations on PathLayer[0m                                                      
00:03 [32m+1843[0m: test/path_animation_triggers_test.dart: Path animation triggers validator rejects invalid whileInside/mode combinations on PathLayer[0m                                                      
00:03 [32m+1843[0m: test/path_animation_triggers_test.dart: Path animation triggers scope defaults to wholeLayer[0m                                                                                              
00:03 [32m+1844[0m: test/path_animation_triggers_test.dart: Path animation triggers scope defaults to wholeLayer[0m                                                                                              
00:03 [32m+1844[0m: test/path_animation_triggers_test.dart: Path animation triggers scope can be set to cellOnly[0m                                                                                              
00:03 [32m+1845[0m: test/path_animation_triggers_test.dart: Path animation triggers scope can be set to cellOnly[0m                                                                                              
00:03 [32m+1845[0m: test/path_animation_triggers_test.dart: Path animation triggers scope serializes and deserializes[0m                                                                                         
00:03 [32m+1846[0m: test/path_animation_triggers_test.dart: Path animation triggers scope serializes and deserializes[0m                                                                                         
00:03 [32m+1846[0m: [1m[90mloading test/surface_layer_model_test.dart[0m[0m                                                                                                                                                
00:03 [32m+1846[0m: test/surface_layer_model_test.dart: SurfaceCellPlacement stores sparse cell coordinates and a surfacePresetId[0m                                                                             
00:03 [32m+1847[0m: test/surface_layer_model_test.dart: SurfaceCellPlacement stores sparse cell coordinates and a surfacePresetId[0m                                                                             
00:03 [32m+1847[0m: test/surface_layer_model_test.dart: SurfaceCellPlacement round-trips JSON with only V0 placement fields[0m                                                                                   
00:03 [32m+1848[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1849[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1850[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1851[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1852[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1853[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1854[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1855[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1856[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1857[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1858[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1859[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1860[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1861[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1862[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1863[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1864[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1865[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1866[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1867[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1868[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1869[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1870[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1871[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1872[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1873[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1874[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1875[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1876[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1877[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1878[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1879[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1880[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1881[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1882[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1883[0m: test/narrative_authoring_golden_path_test.dart: P4-07 minimal authoring golden path chains read models, drafts, operations, predicates, validation, and authoring diagnostics[0m             
00:03 [32m+1884[0m: test/scene_project_diagnostics_test.dart: Scene project diagnostics detects missing dialogue reference without parsing Yarn[0m                                                               
00:03 [32m+1885[0m: test/scene_project_diagnostics_test.dart: Scene project diagnostics detects missing dialogue reference without parsing Yarn[0m                                                               
00:03 [32m+1886[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                           
00:03 [32m+1887[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                           
00:03 [32m+1888[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                           
00:03 [32m+1889[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                           
00:03 [32m+1890[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames serializes and deserializes animated variant frames[0m                                                                           
00:03 [32m+1891[0m: test/scene_project_diagnostics_test.dart: Scene project diagnostics detects missing world rule reference from future world state source[0m                                                   
00:03 [32m+1892[0m: test/scene_project_diagnostics_test.dart: Scene project diagnostics detects missing world rule reference from future world state source[0m                                                   
00:03 [32m+1893[0m: test/path_preset_frames_test.dart: ProjectPathPreset frames validator rejects non-positive path frame durations[0m                                                                           
00:03 [32m+1894[0m: test/scene_project_diagnostics_test.dart: Scene project diagnostics does not import runtime or battle packages[0m                                                                            
00:03 [32m+1895[0m: test/scene_project_diagnostics_test.dart: Scene project diagnostics does not import runtime or battle packages[0m                                                                            
00:03 [32m+1895[0m: [1m[90mloading test/environment_preset_json_codec_test.dart[0m[0m                                                                                                                                      
00:03 [32m+1895[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m                                                                                          
00:03 [32m+1896[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode preset complet[0m                                                                                          
00:03 [32m+1896[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet[0m                                                                                          
00:03 [32m+1897[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec encode preset complet[0m                                                                                          
00:03 [32m+1897[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec roundtrip preset complet[0m                                                                                       
00:03 [32m+1898[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec roundtrip preset complet[0m                                                                                       
00:03 [32m+1898[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode categoryId absent/null => null[0m                                                                          
00:03 [32m+1899[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode categoryId absent/null => null[0m                                                                          
00:03 [32m+1899[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode collisionMode absent/null => useElementDefault[0m                                                          
00:03 [32m+1900[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode collisionMode absent/null => useElementDefault[0m                                                          
00:03 [32m+1900[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode collisionMode inconnu => FormatException[0m                                                                
00:03 [32m+1901[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode collisionMode inconnu => FormatException[0m                                                                
00:03 [32m+1901[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tags absent/null => set vide[0m                                                                            
00:03 [32m+1902[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tags absent/null => set vide[0m                                                                            
00:03 [32m+1902[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tag non-string => FormatException[0m                                                                       
00:03 [32m+1903[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tag non-string => FormatException[0m                                                                       
00:03 [32m+1903[0m: test/environment_preset_json_codec_test.dart: EnvironmentPreset JSON codec decode tag vide/whitespace => FormatException[0m                                                                  
00:03 [32m+1904[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1905[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1906[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1907[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1908[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1909[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1910[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1911[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1912[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1913[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1914[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping generates single mapping with correct variant[0m                               
00:03 [32m+1914[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping preserves input order of columns[0m                                            
00:03 [32m+1915[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping preserves input order of columns[0m                                            
00:03 [32m+1915[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping respects startRow per column[0m                                                
00:03 [32m+1916[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping respects startRow per column[0m                                                
00:03 [32m+1916[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping respects sourceWidth and sourceHeight[0m                                       
00:03 [32m+1917[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping respects sourceWidth and sourceHeight[0m                                       
00:03 [32m+1917[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas simple mapping preserves tilesetId[0m                                                         
00:03 [32m+1918[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:03 [32m+1919[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1920[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1921[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1922[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1923[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1924[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1925[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1926[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1927[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1928[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1929[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft creates predicate drafts from reference picker options[0m                                            
00:04 [32m+1930[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas validation throws ValidationException for negative startRow[0m                                
00:04 [32m+1931[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft compiles predicate drafts to runtime predicates[0m                                                   
00:04 [32m+1932[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft compiles predicate drafts to runtime predicates[0m                                                   
00:04 [32m+1933[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas validation throws ValidationException for non-positive frameCount[0m                          
00:04 [32m+1934[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft diagnoses empty predicate reference ids[0m                                                           
00:04 [32m+1935[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft diagnoses empty predicate reference ids[0m                                                           
00:04 [32m+1936[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas validation throws ValidationException for non-positive sourceHeight[0m                        
00:04 [32m+1937[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft compiles visibleWhen visibility rule to NPC visibility rule[0m                                       
00:04 [32m+1938[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft compiles visibleWhen visibility rule to NPC visibility rule[0m                                       
00:04 [32m+1939[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft compiles visibleWhen visibility rule to NPC visibility rule[0m                                       
00:04 [32m+1940[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft compiles visibleWhen visibility rule to NPC visibility rule[0m                                       
00:04 [32m+1940[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas validation throws ValidationException for non-positive frame durations[0m                     
00:04 [32m+1941[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas validation throws ValidationException for non-positive frame durations[0m                     
00:04 [32m+1942[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas validation throws ValidationException for non-positive frame durations[0m                     
00:04 [32m+1942[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft compiles conditional dialogue to runtime conditional dialogue[0m                                     
00:04 [32m+1943[0m: test/narrative_predicate_authoring_draft_test.dart: Narrative predicate authoring draft compiles conditional dialogue to runtime conditional dialogue[0m                                     
00:04 [32m+1944[0m: test/path_variant_vertical_atlas_mapping_test.dart: createPathVariantMappingsFromVerticalAtlas edge cases handles multiple variants[0m                                                       
00:04 [32m+1945[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data[0m                                            
00:04 [32m+1946[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data[0m                                            
00:04 [32m+1947[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data[0m                                            
00:04 [32m+1948[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data[0m                                            
00:04 [32m+1949[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data[0m                                            
00:04 [32m+1950[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data[0m                                            
00:04 [32m+1951[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data[0m                                            
00:04 [32m+1952[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog builds cinematic stage map source catalog from real map data[0m                                            
00:04 [32m+1952[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog returns missing stage map status without stage map[0m                                                      
00:04 [32m+1953[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog returns missing stage map status without stage map[0m                                                      
00:04 [32m+1953[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog returns unavailable status without map data[0m                                                             
00:04 [32m+1954[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog returns unavailable status without map data[0m                                                             
00:04 [32m+1954[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog returns map id mismatch status when map data does not match stage map[0m                                   
00:04 [32m+1955[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog returns map id mismatch status when map data does not match stage map[0m                                   
00:04 [32m+1955[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog uses entity id as fallback label only when no better label exists[0m                                       
00:04 [32m+1956[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog uses entity id as fallback label only when no better label exists[0m                                       
00:04 [32m+1956[0m: test/cinematic_stage_map_source_catalog_test.dart: CinematicStageMapSourceCatalog uses event id as fallback label only when title is empty[0m                                                
00:04 [32m+1957[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                       
00:04 [32m+1958[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                       
00:04 [32m+1959[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet minimal set: length, isEmpty, isNotEmpty, first ref[0m                                                       
00:04 [32m+1959[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet rejects empty refs[0m                                                                                        
00:04 [32m+1960[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet rejects empty refs[0m                                                                                        
00:04 [32m+1960[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet rejects duplicate role (different animationId)[0m                                                            
00:04 [32m+1961[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet rejects duplicate role (different animationId)[0m                                                            
00:04 [32m+1961[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet allows same animationId for different roles[0m                                                               
00:04 [32m+1962[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet allows same animationId for different roles[0m                                                               
00:04 [32m+1962[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet preserves input order (not sorted by standard order)[0m                                                      
00:04 [32m+1963[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet preserves input order (not sorted by standard order)[0m                                                      
00:04 [32m+1963[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet exposed refs list is unmodifiable[0m                                                                         
00:04 [32m+1964[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet exposed refs list is unmodifiable[0m                                                                         
00:04 [32m+1964[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet defensive copy: mutating source list after build does not change set[0m                                      
00:04 [32m+1965[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet defensive copy: mutating source list after build does not change set[0m                                      
00:04 [32m+1965[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet containsRole: true for present roles[0m                                                                      
00:04 [32m+1966[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet containsRole: true for present roles[0m                                                                      
00:04 [32m+1966[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet containsRole: false when role absent[0m                                                                      
00:04 [32m+1967[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet containsRole: false when role absent[0m                                                                      
00:04 [32m+1967[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet refForRole: returns ref when present[0m                                                                      
00:04 [32m+1968[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet refForRole: returns ref when present[0m                                                                      
00:04 [32m+1968[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet refForRole: null when absent[0m                                                                              
00:04 [32m+1969[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet refForRole: null when absent[0m                                                                              
00:04 [32m+1969[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet animationIdForRole: id when present[0m                                                                       
00:04 [32m+1970[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet animationIdForRole: id when present[0m                                                                       
00:04 [32m+1970[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet animationIdForRole: null when absent[0m                                                                      
00:04 [32m+1971[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet animationIdForRole: null when absent[0m                                                                      
00:04 [32m+1971[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: true for covered subset[0m                                                                   
00:04 [32m+1972[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: true for covered subset[0m                                                                   
00:04 [32m+1972[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: false if one role missing[0m                                                                 
00:04 [32m+1973[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: false if one role missing[0m                                                                 
00:04 [32m+1973[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: true for empty iterable (vacuous every)[0m                                                   
00:04 [32m+1974[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet coversAllRoles: true for empty iterable (vacuous every)[0m                                                   
00:04 [32m+1974[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet can cover all of standardSurfaceVariantRoleOrder in input order[0m                                           
00:04 [32m+1975[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet can cover all of standardSurfaceVariantRoleOrder in input order[0m                                           
00:04 [32m+1975[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: same refs in same order[0m                                                                   
00:04 [32m+1976[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: same refs in same order[0m                                                                   
00:04 [32m+1976[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: different order => not equal[0m                                                              
00:04 [32m+1977[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: different order => not equal[0m                                                              
00:04 [32m+1977[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: same role different animationId[0m                                                           
00:04 [32m+1978[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet value equality: same role different animationId[0m                                                           
00:04 [32m+1978[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet export: type via map_core[0m                                                                                 
00:04 [32m+1979[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet export: type via map_core[0m                                                                                 
00:04 [32m+1979[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet set is only a collection of refs (no ProjectSurfacePreset)[0m                                                
00:04 [32m+1980[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet set is only a collection of refs (no ProjectSurfacePreset)[0m                                                
00:04 [32m+1980[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet ProjectManifest toJson: no surface* top-level keys[0m                                                        
00:04 [32m+1981[0m: test/surface_variant_animation_ref_set_test.dart: SurfaceVariantAnimationRefSet ProjectManifest toJson: no surface* top-level keys[0m                                                        
00:04 [32m+1981[0m: [1m[90mloading test/project_manifest_scenes_test.dart[0m[0m                                                                                                                                            
00:04 [32m+1981[0m: test/project_manifest_scenes_test.dart: ProjectManifest scenes integration decodes old project JSON without scenes as empty list[0m                                                          
00:04 [32m+1982[0m: test/project_manifest_scenes_test.dart: ProjectManifest scenes integration decodes old project JSON without scenes as empty list[0m                                                          
00:04 [32m+1982[0m: test/project_manifest_scenes_test.dart: ProjectManifest scenes integration decodes scenes null and empty scenes as empty list[0m                                                             
00:04 [32m+1983[0m: test/project_manifest_scenes_test.dart: ProjectManifest scenes integration decodes scenes null and empty scenes as empty list[0m                                                             
00:04 [32m+1983[0m: test/project_manifest_scenes_test.dart: ProjectManifest scenes integration decodes project JSON with a SceneAsset[0m                                                                         
00:04 [32m+1984[0m: test/project_manifest_scenes_test.dart: ProjectManifest scenes integration decodes project JSON with a SceneAsset[0m                                                                         
00:04 [32m+1984[0m: test/project_manifest_scenes_test.dart: ProjectManifest scenes integration round-trips manifest with scenes through JSON[0m                                                                  
00:04 [32m+1985[0m: test/map_entity_collision_footprint_test.dart: map entity collision footprint defaults npc 1x1 keeps 1x1 collision at anchor[0m                                                              
00:04 [32m+1986[0m: test/project_manifest_scenes_test.dart: ProjectManifest scenes integration keeps scenarios and storylines independent from scenes[0m                                                         
00:04 [32m+1987[0m: test/project_manifest_scenes_test.dart: ProjectManifest scenes integration keeps scenarios and storylines independent from scenes[0m                                                         
00:04 [32m+1988[0m: test/project_manifest_facts_test.dart: ProjectManifest facts integration decodes absent null and empty facts as empty list[0m                                                                
00:04 [32m+1989[0m: test/project_manifest_facts_test.dart: ProjectManifest facts integration decodes absent null and empty facts as empty list[0m                                                                
00:04 [32m+1990[0m: test/project_manifest_facts_test.dart: ProjectManifest facts integration decodes absent null and empty facts as empty list[0m                                                                
00:04 [32m+1990[0m: test/project_manifest_facts_test.dart: ProjectManifest facts integration round-trips facts through ProjectManifest JSON[0m                                                                   
00:04 [32m+1991[0m: test/project_manifest_facts_test.dart: ProjectManifest facts integration round-trips facts through ProjectManifest JSON[0m                                                                   
00:04 [32m+1992[0m: test/project_manifest_facts_test.dart: ProjectManifest facts integration round-trips facts through ProjectManifest JSON[0m                                                                   
00:04 [32m+1993[0m: test/scene_consequence_model_test.dart: SceneConsequence V0 setFact JSON round-trips[0m                                                                                                      
00:04 [32m+1994[0m: test/scene_consequence_model_test.dart: SceneConsequence V0 setFact JSON round-trips[0m                                                                                                      
00:04 [32m+1995[0m: test/scene_consequence_model_test.dart: SceneConsequence V0 setFact JSON round-trips[0m                                                                                                      
00:04 [32m+1995[0m: test/scene_consequence_model_test.dart: SceneConsequence V0 markEventConsumed JSON round-trips[0m                                                                                            
00:04 [32m+1996[0m: test/scene_consequence_model_test.dart: SceneConsequence V0 markEventConsumed JSON round-trips[0m                                                                                            
00:04 [32m+1996[0m: test/scene_consequence_model_test.dart: SceneConsequence V0 rejects unknown consequence kind[0m                                                                                              
00:04 [32m+1997[0m: test/scene_consequence_model_test.dart: SceneConsequence V0 rejects unknown consequence kind[0m                                                                                              
00:04 [32m+1997[0m: test/scene_consequence_model_test.dart: SceneActionPayload typed consequences can carry typed setFact consequence[0m                                                                         
00:04 [32m+1998[0m: test/scene_consequence_model_test.dart: SceneActionPayload typed consequences can carry typed setFact consequence[0m                                                                         
00:04 [32m+1998[0m: test/scene_consequence_model_test.dart: SceneActionPayload typed consequences can carry typed markEventConsumed consequence[0m                                                               
00:04 [32m+1999[0m: test/scene_consequence_model_test.dart: SceneActionPayload typed consequences can carry typed markEventConsumed consequence[0m                                                               
00:04 [32m+1999[0m: test/scene_consequence_model_test.dart: SceneActionPayload typed consequences legacy actionKind payload still deserializes[0m                                                                
00:04 [32m+2000[0m: test/scene_consequence_model_test.dart: SceneActionPayload typed consequences legacy actionKind payload still deserializes[0m                                                                
00:04 [32m+2000[0m: [1m[90mloading test/cinematic_authoring_operations_test.dart[0m[0m                                                                                                                                     
00:04 [32m+2000[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations addCinematicAsset adds an asset without mutating project[0m                                                    
00:04 [32m+2001[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations addCinematicAsset adds an asset without mutating project[0m                                                    
00:04 [32m+2001[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations addCinematicAsset refuses duplicate ids[0m                                                                     
00:04 [32m+2002[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations addCinematicAsset refuses duplicate ids[0m                                                                     
00:04 [32m+2002[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations addCinematicRequiredActor creates a minimal required actor[0m                                                  
00:04 [32m+2003[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations addCinematicRequiredActor creates a minimal required actor[0m                                                  
00:04 [32m+2003[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations addCinematicRequiredActor refuses empty labels[0m                                                              
00:04 [32m+2004[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations addCinematicRequiredActor refuses empty labels[0m                                                              
00:04 [32m+2004[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations renameCinematicRequiredActor updates label without changing refs[0m                                            
00:04 [32m+2005[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations renameCinematicRequiredActor updates label without changing refs[0m                                            
00:04 [32m+2005[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations renameCinematicRequiredActor refuses empty labels[0m                                                           
00:04 [32m+2006[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations renameCinematicRequiredActor refuses empty labels[0m                                                           
00:04 [32m+2006[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations removeCinematicRequiredActor cleans unused stage refs only[0m                                                  
00:04 [32m+2007[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations removeCinematicRequiredActor cleans unused stage refs only[0m                                                  
00:04 [32m+2007[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations removeCinematicRequiredActor refuses actor used by timeline[0m                                                 
00:04 [32m+2008[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations removeCinematicRequiredActor refuses actor used by timeline[0m                                                 
00:04 [32m+2008[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations addCinematicMovementTarget creates a stable authoring target[0m                                                
00:04 [32m+2009[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations addCinematicMovementTarget creates a stable authoring target[0m                                                
00:04 [32m+2009[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations movement target operations validate labels and usage[0m                                                        
00:04 [32m+2010[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations movement target operations validate labels and usage[0m                                                        
00:04 [32m+2010[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations renamed movement target updates actorMove lane labels only by read model[0m                                    
00:04 [32m+2011[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations renamed movement target updates actorMove lane labels only by read model[0m                                    
00:04 [32m+2011[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations updateCinematicAsset replaces an existing asset only[0m                                                        
00:04 [32m+2012[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations updateCinematicAsset replaces an existing asset only[0m                                                        
00:04 [32m+2012[0m: test/cinematic_authoring_operations_test.dart: Cinematic authoring operations removeCinematicAsset removes unused asset[0m                                                                   
00:04 [32m+2013[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2014[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2015[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2016[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2017[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2018[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2019[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2020[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2021[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2022[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2023[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2024[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2025[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2026[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2027[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2028[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2029[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2030[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2031[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2032[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2033[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2034[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2035[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2036[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2037[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2038[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2039[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2040[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2041[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 1. getProjectManifestSurfaceCatalog returns the manifest catalog[0m          
00:04 [32m+2042[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2043[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2044[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2045[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2046[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2047[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2048[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2049[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2050[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2051[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2052[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2053[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2054[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2055[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2056[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2057[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2058[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2059[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2060[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2061[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2062[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2063[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2064[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2065[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2066[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2067[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression roundtrip conserve path presets, patterns, frames et variantes[0m          
00:04 [32m+2068[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning uses footprint V0 defaults[0m                                                            
00:04 [32m+2069[0m: test/project_manifest_surface_catalog_operations_test.dart: ProjectManifest surface catalog operations (Lot 50) 15. round-trip JSON after replace with minimal water[0m                      
00:04 [32m+2070[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2071[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2072[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2073[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2074[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2075[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2076[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2077[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2078[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2079[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2080[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2081[0m: test/project_manifest_path_pattern_save_reload_test.dart: ProjectManifest PathPattern save/reload JSON regression fixture golden 2x2 animé se décode avec les données attendues[0m           
00:04 [32m+2082[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode defaults to directional geometry mode[0m                                     
00:04 [32m+2083[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode defaults to directional geometry mode[0m                                     
00:04 [32m+2084[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode defaults to directional geometry mode[0m                                     
00:04 [32m+2084[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode accepts directional without footprint[0m                                     
00:04 [32m+2085[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode accepts directional without footprint[0m                                     
00:04 [32m+2085[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode rejects directional with footprint[0m                                        
00:04 [32m+2086[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode rejects directional with footprint[0m                                        
00:04 [32m+2086[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode accepts footprint with footprint tuning[0m                                   
00:04 [32m+2087[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode accepts footprint with footprint tuning[0m                                   
00:04 [32m+2087[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode rejects footprint without footprint tuning[0m                                
00:04 [32m+2088[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode rejects footprint without footprint tuning[0m                                
00:04 [32m+2088[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode equality and hashCode include geometryMode and footprint[0m                  
00:04 [32m+2089[0m: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode equality and hashCode include geometryMode and footprint[0m                  
00:04 [32m+2089[0m: [1m[90mloading test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart[0m[0m                                                                                                   
00:04 [32m+2089[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... without projectedBuildingShadowCatalog decodes an empty catalog and omits the root on toJson[0m         
00:04 [32m+2090[0m: test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec encodes an empty catalog canonically[0m                            
00:04 [32m+2091[0m: test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec encodes an empty catalog canonically[0m                            
00:04 [32m+2092[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... integration ProjectManifest rejects an object projectedBuildingShadowCatalog without presets[0m         
00:04 [32m+2093[0m: test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec decodes an empty catalog[0m                                        
00:04 [32m+2094[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... with empty projectedBuildingShadowCatalog presets decodes empty and omits the root on toJson[0m         
00:04 [32m+2095[0m: test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec encodes multiple presets preserving order[0m                       
00:04 [32m+2096[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root[0m         
00:04 [32m+2097[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root[0m         
00:04 [32m+2098[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root[0m         
00:04 [32m+2099[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root[0m         
00:04 [32m+2100[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root[0m         
00:04 [32m+2101[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root[0m         
00:04 [32m+2102[0m: test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection accepts a valid direction and preserves authored values[0m                                        
00:04 [32m+2103[0m: test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection accepts a valid direction and preserves authored values[0m                                        
00:04 [32m+2104[0m: test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection accepts a valid direction and preserves authored values[0m                                        
00:04 [32m+2105[0m: test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection accepts a valid direction and preserves authored values[0m                                        
00:04 [32m+2106[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... integration ProjectElementEntry with projectedBuildingShadow round-trips and emits the field[0m         
00:04 [32m+2107[0m: test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection refuses non-finite values[0m                                                                      
00:04 [32m+2108[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... integration ProjectElementEntry preserves V1 shadow and V2 projectedBuildingShadow together[0m          
00:04 [32m+2109[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... integration ProjectElementEntry preserves V1 shadow and V2 projectedBuildingShadow together[0m          
00:04 [32m+2110[0m: test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection exposes a normalized direction without mutating authored values[0m                                
00:04 [32m+2111[0m: test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection exposes a normalized direction without mutating authored values[0m                                
00:04 [32m+2111[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... integration existing V1-only manifest round-trip stays free of projected building shadow output[0m      
00:04 [32m+2112[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... integration existing V1-only manifest round-trip stays free of projected building shadow output[0m      
00:04 [32m+2113[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... integration existing V1-only manifest round-trip stays free of projected building shadow output[0m      
00:04 [32m+2114[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... integration existing V1-only manifest round-trip stays free of projected building shadow output[0m      
00:04 [32m+2115[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... integration existing V1-only manifest round-trip stays free of projected building shadow output[0m      
00:04 [32m+2116[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... integration existing V1-only manifest round-trip stays free of projected building shadow output[0m      
00:04 [32m+2116[0m: test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowAnchor uses value equality[0m                                                                               
00:04 [32m+2117[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... manifest and element persistence integration copyWith can replace manifest catalog and element config[0m
00:04 [32m+2118[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... manifest and element persistence integration copyWith can replace manifest catalog and element config[0m
00:04 [32m+2119[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... manifest and element persistence integration copyWith can replace manifest catalog and element config[0m
00:04 [32m+2120[0m: test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ... manifest and element persistence integration copyWith can replace manifest catalog and element config[0m
00:04 [32m+2121[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2122[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2123[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2124[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2125[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2126[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2127[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2128[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2129[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2130[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2131[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2132[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true[0m   
00:04 [32m+2132[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ... JSON codec encodes enabled false while keeping explicit preset and placement[0m                    
00:04 [32m+2133[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ... JSON codec encodes enabled false while keeping explicit preset and placement[0m                    
00:04 [32m+2133[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec omits casterKind when null[0m                   
00:04 [32m+2134[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec omits casterKind when null[0m                   
00:04 [32m+2134[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes building casterKind[0m                  
00:04 [32m+2135[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes building casterKind[0m                  
00:04 [32m+2135[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes largeVolume casterKind[0m               
00:04 [32m+2136[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes largeVolume casterKind[0m               
00:04 [32m+2136[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled true[0m   
00:04 [32m+2137[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled true[0m   
00:04 [32m+2137[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec decodes missing casterKind as null[0m           
00:04 [32m+2138[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec decodes missing casterKind as null[0m           
00:04 [32m+2138[0m: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec decodes explicit null casterKind as null[0m     
00:04 [32m+2139[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2140[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2141[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2142[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2143[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2144[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2145[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2146[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2147[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2148[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2149[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2150[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId[0m                               
00:04 [32m+2150[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes categoryId when non-null and always emits sortOrder[0m                    
00:04 [32m+2151[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes categoryId when non-null and always emits sortOrder[0m                    
00:04 [32m+2151[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec decodes canonical preset JSON with defaults for omitted optionals[0m              
00:04 [32m+2152[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec decodes canonical preset JSON with defaults for omitted optionals[0m              
00:04 [32m+2152[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec decodes categoryId null as null[0m                                                
00:04 [32m+2153[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec decodes categoryId null as null[0m                                                
00:04 [32m+2153[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec round-trips preset instances through canonical JSON[0m                            
00:04 [32m+2154[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec round-trips preset instances through canonical JSON[0m                            
00:04 [32m+2154[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec round-trips JSON without re-emitting unknown keys[0m                              
00:04 [32m+2155[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec round-trips JSON without re-emitting unknown keys[0m                              
00:04 [32m+2155[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects null and non-map preset JSON[0m                                           
00:04 [32m+2156[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects null and non-map preset JSON[0m                                           
00:04 [32m+2156[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects missing required fields[0m                                                
00:04 [32m+2157[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects missing required fields[0m                                                
00:04 [32m+2157[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects invalid field types[0m                                                    
00:04 [32m+2158[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects invalid field types[0m                                                    
00:04 [32m+2158[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects invalid values delegated to model and atomic codecs[0m                    
00:04 [32m+2159[0m: test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects invalid values delegated to model and atomic codecs[0m                    
00:04 [32m+2159[0m: [1m[90mloading test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart[0m[0m                                                                                                                
00:04 [32m+2159[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec encodes the canonical x/y object[0m                                                  
00:04 [32m+2160[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec encodes the canonical x/y object[0m                                                  
00:04 [32m+2160[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec decodes the canonical x/y object and ignores unknown keys[0m                         
00:04 [32m+2161[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec decodes the canonical x/y object and ignores unknown keys[0m                         
00:04 [32m+2161[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec round-trips through the canonical object[0m                                          
00:04 [32m+2162[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec round-trips through the canonical object[0m                                          
00:04 [32m+2162[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec rejects invalid JSON shape and required fields[0m                                    
00:04 [32m+2163[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2164[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2165[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2166[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2167[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2168[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2169[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2170[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2171[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2172[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2173[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2174[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2175[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2176[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2177[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2178[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values[0m                                 
00:04 [32m+2179[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAppearance JSON codec accepts opacity boundaries[0m                                                       
00:04 [32m+2180[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled false and preserves preset intent[0m                          
00:04 [32m+2181[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAppearance JSON codec rejects missing fields and invalid appearance values[0m                             
00:04 [32m+2182[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig rejects blank preset ids[0m                                                   
00:04 [32m+2183[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig rejects blank preset ids[0m                                                   
00:04 [32m+2184[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig rejects blank preset ids[0m                                                   
00:04 [32m+2185[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowTimeOfDayMode JSON codec rejects unknown, non-string, and wrongly-cased values[0m                         
00:04 [32m+2186[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowTimeOfDayMode JSON codec rejects unknown, non-string, and wrongly-cased values[0m                         
00:04 [32m+2187[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowTimeOfDayMode JSON codec rejects unknown, non-string, and wrongly-cased values[0m                         
00:04 [32m+2187[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig composes valid anchor and positive or negative offsets[0m                     
00:04 [32m+2188[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig composes valid anchor and positive or negative offsets[0m                     
00:04 [32m+2189[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedBuildingShadowCasterKind JSON codec encodes largeVolume[0m                                                      
00:04 [32m+2190[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig uses value equality and matching hashCode[0m                                  
00:04 [32m+2191[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig uses value equality and matching hashCode[0m                                  
00:04 [32m+2192[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig uses value equality and matching hashCode[0m                                  
00:04 [32m+2193[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig uses value equality and matching hashCode[0m                                  
00:04 [32m+2194[0m: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedBuildingShadowCasterKind JSON codec rejects non-string[0m                                                       
00:04 [32m+2195[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig value equality includes enabled[0m                                            
00:04 [32m+2196[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig value equality includes enabled[0m                                            
00:04 [32m+2197[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig value equality includes enabled[0m                                            
00:04 [32m+2197[0m: test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig value equality includes presetId[0m                                           
00:04 [32m+2198[0m: test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ... ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data[0m
00:04 [32m+2199[0m: test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ... ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data[0m
00:04 [32m+2200[0m: test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ... ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data[0m
00:04 [32m+2201[0m: test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ... ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data[0m
00:04 [32m+2202[0m: test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ... ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data[0m
00:04 [32m+2203[0m: test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ... ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data[0m
00:04 [32m+2204[0m: test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ... ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data[0m
00:04 [32m+2205[0m: test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ... ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data[0m
00:04 [32m+2206[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2207[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2208[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2209[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2210[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2211[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2212[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2213[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2214[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2215[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2216[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2217[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2218[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2219[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2220[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2221[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2222[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2223[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2224[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2225[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2226[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields[0m                                             
00:04 [32m+2226[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores a non-null category id[0m                                                                      
00:04 [32m+2227[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores a non-null category id[0m                                                                      
00:04 [32m+2227[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset uses sortOrder zero by default[0m                                                                     
00:04 [32m+2228[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset uses sortOrder zero by default[0m                                                                     
00:04 [32m+2228[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset refuses blank id values while preserving valid raw ids[0m                                             
00:04 [32m+2229[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset refuses blank id values while preserving valid raw ids[0m                                             
00:04 [32m+2229[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset refuses blank name values while preserving valid raw names[0m                                         
00:04 [32m+2230[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset refuses blank name values while preserving valid raw names[0m                                         
00:04 [32m+2230[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset validates optional category id[0m                                                                     
00:04 [32m+2231[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset validates optional category id[0m                                                                     
00:04 [32m+2231[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset uses value equality for identical presets[0m                                                          
00:04 [32m+2232[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset uses value equality for identical presets[0m                                                          
00:04 [32m+2232[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes id[0m                                                                         
00:04 [32m+2233[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes id[0m                                                                         
00:04 [32m+2233[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes name[0m                                                                       
00:04 [32m+2234[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes name[0m                                                                       
00:04 [32m+2234[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes direction[0m                                                                  
00:04 [32m+2235[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes direction[0m                                                                  
00:04 [32m+2235[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes shape[0m                                                                      
00:04 [32m+2236[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes shape[0m                                                                      
00:04 [32m+2236[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes appearance[0m                                                                 
00:04 [32m+2237[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes appearance[0m                                                                 
00:04 [32m+2237[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes timeOfDayMode[0m                                                              
00:04 [32m+2238[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes timeOfDayMode[0m                                                              
00:04 [32m+2238[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes categoryId[0m                                                                 
00:04 [32m+2239[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes categoryId[0m                                                                 
00:04 [32m+2239[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes sortOrder[0m                                                                  
00:04 [32m+2240[0m: test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes sortOrder[0m                                                                  
00:04 [32m+2240[0m: [1m[90mloading test/shadow_v2/projected_building_shadow_diagnostics_test.dart[0m[0m                                                                                                                    
00:04 [32m+2240[0m: test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics returns no diagnostics for active element referencing existing preset[0m               
00:04 [32m+2241[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2242[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2243[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2244[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2245[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2246[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2247[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2248[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2249[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2250[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2251[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2252[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null[0m                                           
00:04 [32m+2253[0m: test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics diagnostic equality includes all fields[0m                                             
00:04 [32m+2254[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind stores building casterKind[0m                                 
00:04 [32m+2255[0m: test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics returned diagnostics list is unmodifiable[0m                                           
00:04 [32m+2256[0m: test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics returned diagnostics list is unmodifiable[0m                                           
00:04 [32m+2257[0m: test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics returned diagnostics list is unmodifiable[0m                                           
00:04 [32m+2258[0m: test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics returned diagnostics list is unmodifiable[0m                                           
00:04 [32m+2258[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind equality includes casterKind[0m                               
00:04 [32m+2259[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind equality includes casterKind[0m                               
00:04 [32m+2259[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind hashCode includes casterKind[0m                               
00:04 [32m+2260[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind hashCode includes casterKind[0m                               
00:04 [32m+2260[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind still rejects blank presetId with casterKind[0m               
00:04 [32m+2261[0m: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind still rejects blank presetId with casterKind[0m               
00:04 [32m+2261[0m: [1m[90mloading test/shadow_v2/projected_shadow_footprint_strategy_test.dart[0m[0m                                                                                                                      
00:04 [32m+2261[0m: test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintFixedTuning stores explicit tuning[0m                                                                  
00:04 [32m+2262[0m: test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintFixedTuning stores explicit tuning[0m                                                                  
00:04 [32m+2262[0m: test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintFixedTuning equality includes tuning[0m                                                                
00:04 [32m+2263[0m: test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintFixedTuning equality includes tuning[0m                                                                
00:04 [32m+2263[0m: test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintFixedTuning hashCode includes tuning[0m                                                                
00:04 [32m+2264[0m: test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintFixedTuning hashCode includes tuning[0m                                                                
00:04 [32m+2264[0m: test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate uses canonical defaults[0m                                                                    
00:04 [32m+2265[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2266[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2267[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2268[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2269[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2270[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2271[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2272[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2273[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2274[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2275[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2276[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2277[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2278[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2279[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2280[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2281[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2282[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2283[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2284[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth[0m       
00:04 [32m+2285[0m: test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintTuning defaults remain unchanged[0m                                                                    
00:04 [32m+2286[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprintStrategy null[0m             
00:04 [32m+2287[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprintStrategy null[0m             
00:04 [32m+2287[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy directional rejects footprintStrategy[0m                           
00:04 [32m+2288[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy directional rejects footprintStrategy[0m                           
00:04 [32m+2288[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy directional still rejects footprint[0m                             
00:04 [32m+2289[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy directional still rejects footprint[0m                             
00:04 [32m+2289[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy directional accepts no footprint and no footprintStrategy[0m       
00:04 [32m+2290[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy directional accepts no footprint and no footprintStrategy[0m       
00:04 [32m+2290[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ... footprintStrategy footprint rejects missing footprint and missing footprintStrategy[0m                       
00:04 [32m+2291[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ... footprintStrategy footprint rejects missing footprint and missing footprintStrategy[0m                       
00:04 [32m+2291[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy footprint accepts adaptive footprintStrategy with null footprint[0m
00:04 [32m+2292[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy footprint accepts adaptive footprintStrategy with null footprint[0m
00:04 [32m+2292[0m: test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart: ProjectBuildingShadowPreset footprintStrategy footprint adaptive rejects non-null footprint[0m                   
00:04 [32m+2293[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry disabled config returns null[0m                                                              
00:04 [32m+2294[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry disabled config returns null[0m                                                              
00:04 [32m+2295[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry disabled config returns null[0m                                                              
00:04 [32m+2296[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry disabled config returns null[0m                                                              
00:04 [32m+2297[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry disabled config returns null[0m                                                              
00:04 [32m+2297[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves basic horizontal geometry with stable point order[0m                                
00:04 [32m+2298[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves basic horizontal geometry with stable point order[0m                                
00:04 [32m+2298[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry normalizes direction before applying length[0m                                               
00:04 [32m+2299[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry normalizes direction before applying length[0m                                               
00:04 [32m+2299[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves vertical direction geometry[0m                                                      
00:04 [32m+2300[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves vertical direction geometry[0m                                                      
00:04 [32m+2300[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry localOffset shifts all points[0m                                                             
00:04 [32m+2301[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry localOffset shifts all points[0m                                                             
00:04 [32m+2301[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry shape ratios control length and widths[0m                                                    
00:04 [32m+2302[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry shape ratios control length and widths[0m                                                    
00:04 [32m+2302[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry propagates preset appearance[0m                                                              
00:04 [32m+2303[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry propagates preset appearance[0m                                                              
00:04 [32m+2303[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry followsSun uses preset direction as fixed in V0[0m                                           
00:04 [32m+2304[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry followsSun uses preset direction as fixed in V0[0m                                           
00:04 [32m+2304[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves pokemon-building-shadow-v0 geometry with calibrated points[0m                       
00:04 [32m+2305[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves pokemon-building-shadow-v0 geometry with calibrated points[0m                       
00:04 [32m+2305[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves footprint geometry with attached skewed rectangle points[0m                         
00:04 [32m+2306[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves footprint geometry with attached skewed rectangle points[0m                         
00:04 [32m+2306[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves pokemon-building-shadow-footprint-v1 geometry with selected calibration points[0m   
00:04 [32m+2307[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves pokemon-building-shadow-footprint-v1 geometry with selected calibration points[0m   
00:04 [32m+2307[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry footprint geometry localOffset shifts all points[0m                                          
00:04 [32m+2308[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry footprint geometry localOffset shifts all points[0m                                          
00:04 [32m+2308[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry footprint geometry ignores anchor[0m                                                         
00:04 [32m+2309[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry footprint geometry ignores anchor[0m                                                         
00:04 [32m+2309[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry defensively copies points and exposes an immutable list[0m                          
00:04 [32m+2310[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry defensively copies points and exposes an immutable list[0m                          
00:04 [32m+2310[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry point and geometry equality include ordered values[0m                                        
00:04 [32m+2311[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry point and geometry equality include ordered values[0m                                        
00:04 [32m+2311[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry validates points, opacity, and color[0m                                             
00:04 [32m+2312[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry validates points, opacity, and color[0m                                             
00:04 [32m+2312[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry source stays independent from runtime editor and manifest[0m                        
00:04 [32m+2313[0m: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry source stays independent from runtime editor and manifest[0m                        
00:04 [32m+2313[0m: [1m[90mloading test/shadow_v2/projected_building_shadow_preset_catalog_test.dart[0m[0m                                                                                                                 
00:04 [32m+2313[0m: test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog accepts an empty catalog[0m                                                            
00:04 [32m+2314[0m: test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog accepts an empty catalog[0m                                                            
00:04 [32m+2314[0m: test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog accepts presets and preserves order[0m                                                 
00:04 [32m+2315[0m: test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog accepts presets and preserves order[0m                                                 
00:04 [32m+2315[0m: test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog looks up presets by exact id[0m                                                        
00:04 [32m+2316[0m: test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog looks up presets by exact id[0m                                                        
00:04 [32m+2316[0m: test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog rejects duplicate preset ids[0m                                                        
00:04 [32m+2317[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON[0m                                                   
00:04 [32m+2318[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON[0m                                                   
00:04 [32m+2319[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON[0m                                                   
00:04 [32m+2320[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON[0m                                                   
00:04 [32m+2321[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 1. empty fixture is valid JSON[0m                                                   
00:04 [32m+2321[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 2. empty fixture matches codec[0m                                                   
00:04 [32m+2322[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 2. empty fixture matches codec[0m                                                   
00:04 [32m+2322[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 3. empty fixture round-trip[0m                                                      
00:04 [32m+2323[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 3. empty fixture round-trip[0m                                                      
00:04 [32m+2323[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 4. minimal water fixture is valid JSON with expected structure[0m                   
00:04 [32m+2324[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 4. minimal water fixture is valid JSON with expected structure[0m                   
00:04 [32m+2324[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 5. minimal water fixture matches codec[0m                                           
00:04 [32m+2325[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2326[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2327[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2328[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2329[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2330[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2331[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2332[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2333[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2334[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2335[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2336[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2337[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2338[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2339[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2340[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2341[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2342[0m: test/scene_asset_json_test.dart: SceneAsset JSON roundtrip round-trips a complete V0 authoring shape[0m                                                                                      
00:04 [32m+2343[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations adds a fact with a stable slug id without mutating manifest[0m                                       
00:04 [32m+2344[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations adds a fact with a stable slug id without mutating manifest[0m                                       
00:04 [32m+2345[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations adds a fact with a stable slug id without mutating manifest[0m                                       
00:04 [32m+2346[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations adds a fact with a stable slug id without mutating manifest[0m                                       
00:04 [32m+2347[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations adds a fact with a stable slug id without mutating manifest[0m                                       
00:04 [32m+2348[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m          
00:04 [32m+2349[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m          
00:04 [32m+2350[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m          
00:04 [32m+2351[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m          
00:04 [32m+2352[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m          
00:04 [32m+2353[0m: test/project_surface_catalog_json_golden_samples_test.dart: Surface catalog JSON golden samples (Lot 47) 25. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 49)[0m          
00:04 [32m+2354[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations updates a fact without mutating other manifest data[0m                                               
00:04 [32m+2355[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations updates a fact without mutating other manifest data[0m                                               
00:04 [32m+2356[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations updates a fact without mutating other manifest data[0m                                               
00:04 [32m+2356[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations removes an unreferenced fact and refuses referenced facts[0m                                         
00:04 [32m+2357[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations removes an unreferenced fact and refuses referenced facts[0m                                         
00:04 [32m+2357[0m: test/narrative_fact_authoring_operations_test.dart: Narrative fact authoring operations refuses facts used by world rules or scene consequences[0m                                           
00:04 [32m+2358[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                          
00:04 [32m+2359[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 1. empty catalog: no unused diagnostics[0m                                          
00:04 [32m+2359[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                       
00:04 [32m+2360[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 2. minimal coherent: no unused diagnostics[0m                                       
00:04 [32m+2360[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata[0m                         
00:04 [32m+2361[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 3. unreferenced atlas → unusedAtlas warning and metadata[0m                         
00:04 [32m+2361[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c[0m                  
00:04 [32m+2362[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 4. multiple unused atlases: order follows catalog.atlases a,b,c[0m                  
00:04 [32m+2362[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)[0m                
00:04 [32m+2363[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 5. atlas used by a frame: no unusedAtlas (may be unusedAnimation)[0m                
00:04 [32m+2363[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 6. atlas id exact: spaced atlas not matched by frame atlasId[0m                     
00:04 [32m+2364[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 6. atlas id exact: spaced atlas not matched by frame atlasId[0m                     
00:04 [32m+2364[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 7. animation not referenced by preset → unusedAnimation[0m                          
00:04 [32m+2365[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 7. animation not referenced by preset → unusedAnimation[0m                          
00:04 [32m+2365[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c[0m            
00:04 [32m+2366[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 8. multiple unused animations: order follows catalog.animations a,b,c[0m            
00:04 [32m+2366[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 9. animation referenced by a preset: not unused[0m                                  
00:04 [32m+2367[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 9. animation referenced by a preset: not unused[0m                                  
00:04 [32m+2367[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref[0m                       
00:04 [32m+2368[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 10. animationId exact: spaced id not matched by preset ref[0m                       
00:04 [32m+2368[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused[0m                         
00:04 [32m+2369[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 11. same animation referenced by two presets: not unused[0m                         
00:04 [32m+2369[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused[0m                    
00:04 [32m+2370[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 12. same atlas referenced by two animations: atlas not unused[0m                    
00:04 [32m+2370[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation[0m                             
00:04 [32m+2371[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 13. global order: unusedAtlas before unusedAnimation[0m                             
00:04 [32m+2371[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true[0m                          
00:04 [32m+2372[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 14. warnings only: hasErrors false, hasDiagnostics true[0m                          
00:04 [32m+2372[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings[0m                                      
00:04 [32m+2373[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 15. byKind(unusedAtlas) only atlas warnings[0m                                      
00:04 [32m+2373[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings[0m                              
00:04 [32m+2374[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 16. byKind(unusedAnimation) only animation warnings[0m                              
00:04 [32m+2374[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)[0m                 
00:04 [32m+2375[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 17. byKind returns an unmodifiable list (add → UnsupportedError)[0m                 
00:04 [32m+2375[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)[0m                    
00:04 [32m+2376[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 18. diagnostics list is unmodifiable (add → UnsupportedError)[0m                    
00:04 [32m+2376[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds[0m                             
00:04 [32m+2377[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 19. unused function does not emit Lot 34 error kinds[0m                             
00:04 [32m+2377[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors[0m                    
00:04 [32m+2378[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 20. Lot 34 diagnoseProjectSurfaceCatalog still returns errors[0m                    
00:04 [32m+2378[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error[0m                               
00:04 [32m+2379[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 21. warning severity exists and differs from error[0m                               
00:04 [32m+2379[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId[0m      
00:04 [32m+2380[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) V0 does not diagnose unused presets yet: isolated preset, no false presetId[0m      
00:04 [32m+2380[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only[0m                                 
00:04 [32m+2381[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 23. public API: unused + kinds via map_core only[0m                                 
00:04 [32m+2381[0m: test/surface_catalog_unused_diagnostics_test.dart: diagnoseProjectSurfaceCatalogUnusedResources (Lot 35) 24. ProjectManifest still has no Surface keys (Lot 35)[0m                           
00:04 [32m+2382[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel builds actor display preview model for cinematic actors without rendering them[0m                    
00:04 [32m+2383[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel builds actor display preview model for cinematic actors without rendering them[0m                    
00:04 [32m+2383[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel returns no actors status when cinematic has no required actors[0m                                    
00:04 [32m+2384[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel returns no actors status when cinematic has no required actors[0m                                    
00:04 [32m+2384[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports missing binding for actor without stage binding[0m                                           
00:04 [32m+2385[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports missing binding for actor without stage binding[0m                                           
00:04 [32m+2385[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel marks unbound actor as non renderable[0m                                                             
00:04 [32m+2386[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel marks unbound actor as non renderable[0m                                                             
00:04 [32m+2386[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel resolves map entity actor position from map data entity[0m                                           
00:04 [32m+2387[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel resolves map entity actor position from map data entity[0m                                           
00:04 [32m+2387[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports missing map entity when binding points to unknown entity[0m                                  
00:04 [32m+2388[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports missing map entity when binding points to unknown entity[0m                                  
00:04 [32m+2388[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel resolves cinematic only actor appearance from character library binding[0m                           
00:04 [32m+2389[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel resolves cinematic only actor appearance from character library binding[0m                           
00:04 [32m+2389[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports missing appearance binding for cinematic only actor[0m                                       
00:04 [32m+2390[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports missing appearance binding for cinematic only actor[0m                                       
00:04 [32m+2390[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports unknown character reference[0m                                                               
00:04 [32m+2391[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports unknown character reference[0m                                                               
00:04 [32m+2391[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports character missing tileset[0m                                                                 
00:04 [32m+2392[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports character missing tileset[0m                                                                 
00:04 [32m+2392[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports character missing idle animation[0m                                                          
00:04 [32m+2393[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports character missing idle animation[0m                                                          
00:04 [32m+2393[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel uses player default character when available without GameState[0m                                    
00:04 [32m+2394[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel uses player default character when available without GameState[0m                                    
00:04 [32m+2394[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel falls back to placeholder for player without default character[0m                                    
00:04 [32m+2395[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel falls back to placeholder for player without default character[0m                                    
00:04 [32m+2395[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel resolves from movement target bound to map entity[0m                                                 
00:04 [32m+2396[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel resolves from movement target bound to map entity[0m                                                 
00:04 [32m+2396[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel resolves from movement target bound to map event when position exists[0m                             
00:04 [32m+2397[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel resolves from movement target bound to map event when position exists[0m                             
00:04 [32m+2397[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel does not resolve abstract movement target to fake coordinates[0m                                     
00:04 [32m+2398[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel does not resolve abstract movement target to fake coordinates[0m                                     
00:04 [32m+2398[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel does not treat target_center as map coordinates[0m                                                   
00:04 [32m+2399[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel does not treat target_center as map coordinates[0m                                                   
00:04 [32m+2399[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel does not invent center map fallback for missing placement[0m                                         
00:04 [32m+2400[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel does not invent center map fallback for missing placement[0m                                         
00:04 [32m+2400[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports out of bounds position[0m                                                                    
00:04 [32m+2401[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports out of bounds position[0m                                                                    
00:04 [32m+2401[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel uses actorFace as static direction hint without playback[0m                                          
00:04 [32m+2402[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel uses actorFace as static direction hint without playback[0m                                          
00:04 [32m+2402[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel ignores actorMove for initial position[0m                                                            
00:04 [32m+2403[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel ignores actorMove for initial position[0m                                                            
00:04 [32m+2403[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports orphan actor binding[0m                                                                      
00:04 [32m+2404[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports orphan actor binding[0m                                                                      
00:04 [32m+2404[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports orphan actor appearance binding[0m                                                           
00:04 [32m+2405[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports orphan actor appearance binding[0m                                                           
00:04 [32m+2405[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports orphan initial placement[0m                                                                  
00:04 [32m+2406[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel reports orphan initial placement[0m                                                                  
00:04 [32m+2406[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel keeps model pure without Flutter Flame runtime imports[0m                                            
00:04 [32m+2407[0m: test/cinematic_actor_display_preview_model_test.dart: CinematicActorDisplayPreviewModel keeps model pure without Flutter Flame runtime imports[0m                                            
00:04 [32m+2407[0m: [1m[90mloading test/project_surface_catalog_test.dart[0m[0m                                                                                                                                            
00:04 [32m+2407[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 1. empty catalog: counts, isEmpty, unmodifiable empty lists[0m                                                        
00:04 [32m+2408[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 1. empty catalog: counts, isEmpty, unmodifiable empty lists[0m                                                        
00:04 [32m+2408[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 2. catalog with 2 of each kind: counts, isNotEmpty[0m                                                                 
00:04 [32m+2409[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 2. catalog with 2 of each kind: counts, isNotEmpty[0m                                                                 
00:04 [32m+2409[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved[0m                                                                                      
00:04 [32m+2410[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 3. order of atlases preserved[0m                                                                                      
00:04 [32m+2410[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved[0m                                                                                   
00:04 [32m+2411[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 4. order of animations preserved[0m                                                                                   
00:04 [32m+2411[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved[0m                                                                                      
00:04 [32m+2412[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 5. order of presets preserved[0m                                                                                      
00:04 [32m+2412[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws[0m                                                                      
00:04 [32m+2413[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 6. exposed lists are unmodifiable: add throws[0m                                                                      
00:04 [32m+2413[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build[0m                                                              
00:04 [32m+2414[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 7. defensive copy: atlases source mutated after build[0m                                                              
00:04 [32m+2414[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build[0m                                                           
00:04 [32m+2415[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 8. defensive copy: animations source mutated after build[0m                                                           
00:04 [32m+2415[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build[0m                                                              
00:04 [32m+2416[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 9. defensive copy: presets source mutated after build[0m                                                              
00:04 [32m+2416[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException[0m                                                                  
00:04 [32m+2417[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 10. duplicate atlas id throws ValidationException[0m                                                                  
00:04 [32m+2417[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException[0m                                                              
00:04 [32m+2418[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 11. duplicate animation id throws ValidationException[0m                                                              
00:04 [32m+2418[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException[0m                                                                 
00:04 [32m+2419[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 12. duplicate preset id throws ValidationException[0m                                                                 
00:04 [32m+2419[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups[0m                                                          
00:04 [32m+2420[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 13. same id string across collections is allowed; lookups[0m                                                          
00:04 [32m+2420[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present[0m                                                                        
00:04 [32m+2421[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 14. atlasById returns instance when present[0m                                                                        
00:04 [32m+2421[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent[0m                                                                                     
00:04 [32m+2422[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 15. atlasById null when absent[0m                                                                                     
00:04 [32m+2422[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present[0m                                                                    
00:04 [32m+2423[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 16. animationById returns instance when present[0m                                                                    
00:04 [32m+2423[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent[0m                                                                                 
00:04 [32m+2424[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 17. animationById null when absent[0m                                                                                 
00:04 [32m+2424[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present[0m                                                                       
00:04 [32m+2425[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 18. presetById returns instance when present[0m                                                                       
00:04 [32m+2425[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent[0m                                                                                    
00:04 [32m+2426[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 19. presetById null when absent[0m                                                                                    
00:04 [32m+2426[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup[0m                                                                              
00:04 [32m+2427[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 20. containsAtlas delegates to lookup[0m                                                                              
00:04 [32m+2427[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup[0m                                                                          
00:04 [32m+2428[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 21. containsAnimation delegates to lookup[0m                                                                          
00:04 [32m+2428[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup[0m                                                                             
00:04 [32m+2429[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 22. containsPreset delegates to lookup[0m                                                                             
00:04 [32m+2429[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas[0m                                                                  
00:04 [32m+2430[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 23. lookups use exact id string (no trim) — atlas[0m                                                                  
00:04 [32m+2430[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error[0m                                                       
00:04 [32m+2431[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 24. does not resolve missing animationId on preset; no error[0m                                                       
00:04 [32m+2431[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode[0m                                                       
00:04 [32m+2432[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 25. value equality: same content same order: == and hashCode[0m                                                       
00:04 [32m+2432[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order[0m                                                                        
00:04 [32m+2433[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 26. value inequality: different atlas order[0m                                                                        
00:04 [32m+2433[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order[0m                                                                    
00:04 [32m+2434[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 27. value inequality: different animation order[0m                                                                    
00:04 [32m+2434[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                       
00:04 [32m+2435[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 28. value inequality: different preset order[0m                                                                       
00:04 [32m+2435[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                            
00:04 [32m+2436[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 29. value inequality: different content[0m                                                                            
00:04 [32m+2436[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                     
00:04 [32m+2437[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 30. public surface export: ProjectSurfaceCatalog from map_core[0m                                                     
00:04 [32m+2437[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)[0m                                       
00:04 [32m+2438[0m: test/project_surface_catalog_test.dart: ProjectSurfaceCatalog (Lot 33) 31. ProjectManifest: surfaceCatalog key; no split surface keys (Lot 33 → 49)[0m                                       
00:04 [32m+2438[0m: All tests passed![0m
```

## 6. Sortie exacte de l analyze

### Analyze map_core

Commande :
```bash
dart analyze
```

Code de sortie : `0`

Sortie :
```text
Analyzing map_core...
No issues found!
```

## 7. Checks anti-scope

### Anti-scope packages hors lot

Commande :
```bash
git diff --name-only -- packages/map_editor packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
```

Code de sortie : `0`

Sortie :
```text
Sortie vide.
```
### Anti Flutter runtime source

Commande :
```bash
rg -n "package:flutter|dart:ui|ui\.Image|Canvas|CustomPainter|Widget|BuildContext|package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|CameraComponent|MapLayersComponent|PlayerComponent|OverworldActorComponent|GameState|SceneCinematicRuntimeAwaitableAdapter|map_runtime|map_editor" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true
```

Code de sortie : `0`

Sortie :
```text
Sortie vide.
```
### Anti playback source

Commande :
```bash
rg -n "startPlayback|stopPlayback|playbackTimeMs|currentTimeMs|isPlaying|Timer\(|Ticker|AnimationController|seek|scrub|scrubber" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true
```

Code de sortie : `0`

Sortie :
```text
Sortie vide.
```
### Anti renderer actor source

Commande :
```bash
rg -n "drawActor|renderActor|ActorSprite|CharacterSprite|spritePainter|actorRenderer|ImageProvider|Sprite|drawImageRect" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true
```

Code de sortie : `0`

Sortie :
```text
packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart:93:  actorDisplaySpriteUnavailable,
packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart:164:  bool get isSpriteReady =>
```
### Anti fake position source

Commande :
```bash
rg -n "center.*map|map.*center|fallback.*center|default.*position|0\.5.*width|0\.5.*height|positionSummary" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true
```

Code de sortie : `0`

Sortie :
```text
packages/map_core/test/cinematic_actor_display_preview_model_test.dart:522:    test('does not treat target_center as map coordinates', () {
packages/map_core/test/cinematic_actor_display_preview_model_test.dart:544:    test('does not invent center map fallback for missing placement', () {
```
### Anti Selbrume source

Commande :
```bash
rg -n "selbrume|mael|maël|lysa|port_brisants|bourg_selbrume|phare|brume|marais" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true
```

Code de sortie : `0`

Sortie :
```text
Sortie vide.
```
### Anti image IA source

Commande :
```bash
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart packages/map_core/test/cinematic_actor_display_preview_model_test.dart packages/map_core/lib/map_core.dart || true
```

Code de sortie : `0`

Sortie :
```text
Sortie vide.
```
### git diff --check

Commande :
```bash
git diff --check
```

Code de sortie : `0`

Sortie :
```text
Sortie vide.
```
### git diff --stat

Commande :
```bash
git diff --stat
```

Code de sortie : `0`

Sortie :
```text
 packages/map_core/lib/map_core.dart                |  1 +
 .../scenes/road_map_scene_builder_authoring.md     | 25 ++++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 29 +++++++++++++++++-----
 3 files changed, 46 insertions(+), 9 deletions(-)
```
### git diff --name-only

Commande :
```bash
git diff --name-only
```

Code de sortie : `0`

Sortie :
```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```
### git status final avant rapports

Commande :
```bash
git status --short --untracked-files=all
```

Code de sortie : `0`

Sortie :
```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
?? packages/map_core/test/cinematic_actor_display_preview_model_test.dart
```

Note anti fake position : les occurrences restantes sont dans les tests de non-regression qui verifient explicitement l absence de faux centre implicite.

## 8. Contenu complet du nouveau fichier source

### packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart

```dart
import 'package:meta/meta.dart' show immutable;

import '../models/cinematic_asset.dart';
import '../models/enums.dart';
import '../models/map_data.dart';
import '../models/map_event_definition.dart';
import '../models/project_manifest.dart';
import '../models/project_trainer.dart';
import 'cinematic_stage_map_source_catalog.dart';

enum CinematicActorDisplayPreviewStatus {
  ready,
  incomplete,
  blocked,
  noActors,
}

enum CinematicActorDisplayBindingStatus {
  player,
  mapEntity,
  cinematicOnly,
  unbound,
  missing,
}

enum CinematicActorPreviewPositionStatus {
  resolved,
  missingInitialPlacement,
  missingSource,
  abstractOnly,
  outOfMapBounds,
  unbound,
}

enum CinematicActorPreviewPositionSourceKind {
  none,
  mapEntity,
  mapEvent,
  movementTarget,
}

enum CinematicActorPreviewAppearanceStatus {
  spriteReady,
  placeholderOnly,
  missingCharacter,
  missingTileset,
  missingIdleAnimation,
  notRequired,
  unsupported,
}

enum CinematicActorPreviewRenderHint {
  sprite,
  placeholder,
  hidden,
  missing,
}

enum CinematicActorPreviewDirection {
  north,
  south,
  east,
  west,
  unknown,
}

enum CinematicActorPreviewDirectionSource {
  actorFace,
  mapEntityFacing,
  fallback,
}

enum CinematicActorDisplayPreviewDiagnosticSeverity {
  info,
  warning,
  error,
}

enum CinematicActorDisplayPreviewDiagnosticCode {
  actorDisplayNoActors,
  actorDisplayUnknownActor,
  actorDisplayMissingBinding,
  actorDisplayUnboundActor,
  actorDisplayMissingInitialPlacement,
  actorDisplayMissingMapEntity,
  actorDisplayMissingMovementTarget,
  actorDisplayAbstractTargetOnly,
  actorDisplayOutOfMapBounds,
  actorDisplayMissingAppearance,
  actorDisplayUnknownCharacter,
  actorDisplayCharacterMissingTileset,
  actorDisplayCharacterMissingIdleAnimation,
  actorDisplaySpriteUnavailable,
  actorDisplayRuntimeUnsupported,
  actorDisplayDirectionFallback,
  actorDisplayDuplicateActor,
  actorDisplayDuplicateBinding,
  actorDisplayDuplicatePlacement,
  actorDisplayDuplicateAppearance,
  actorDisplayDuplicateMovementTargetBinding,
  actorDisplayOrphanBinding,
  actorDisplayOrphanAppearance,
  actorDisplayOrphanPlacement,
  actorDisplayOrphanMovementTargetBinding,
}

@immutable
final class CinematicActorDisplayPreviewDiagnostic {
  const CinematicActorDisplayPreviewDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.actorId,
    this.sourceId,
  });

  final CinematicActorDisplayPreviewDiagnosticCode code;
  final CinematicActorDisplayPreviewDiagnosticSeverity severity;
  final String message;
  final String? actorId;
  final String? sourceId;

  bool get isBlocking =>
      severity == CinematicActorDisplayPreviewDiagnosticSeverity.error;
}

@immutable
final class CinematicActorPreviewPosition {
  const CinematicActorPreviewPosition({
    required this.status,
    required this.sourceKind,
    this.x,
    this.y,
    this.sourceId,
    this.sourceLabel,
  });

  final CinematicActorPreviewPositionStatus status;
  final CinematicActorPreviewPositionSourceKind sourceKind;
  final int? x;
  final int? y;
  final String? sourceId;
  final String? sourceLabel;

  bool get isResolved => status == CinematicActorPreviewPositionStatus.resolved;
}

@immutable
final class CinematicActorPreviewAppearance {
  const CinematicActorPreviewAppearance({
    required this.status,
    this.characterId,
    this.characterLabel,
    this.tilesetId,
    this.sourceLabel,
  });

  final CinematicActorPreviewAppearanceStatus status;
  final String? characterId;
  final String? characterLabel;
  final String? tilesetId;
  final String? sourceLabel;

  bool get isSpriteReady =>
      status == CinematicActorPreviewAppearanceStatus.spriteReady;
}

@immutable
final class CinematicActorDisplayPreviewActor {
  CinematicActorDisplayPreviewActor({
    required this.actorId,
    required this.label,
    required this.role,
    required this.bindingStatus,
    required this.bindingKind,
    required this.bindingSourceId,
    required this.bindingSourceLabel,
    required this.position,
    required this.appearance,
    required this.direction,
    required this.directionSource,
    required this.renderHint,
    required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  }) : diagnostics = List<CinematicActorDisplayPreviewDiagnostic>.unmodifiable(
          diagnostics,
        );

  final String actorId;
  final String label;
  final String? role;
  final CinematicActorDisplayBindingStatus bindingStatus;
  final CinematicActorBindingKind? bindingKind;
  final String? bindingSourceId;
  final String? bindingSourceLabel;
  final CinematicActorPreviewPosition position;
  final CinematicActorPreviewAppearance appearance;
  final CinematicActorPreviewDirection direction;
  final CinematicActorPreviewDirectionSource directionSource;
  final CinematicActorPreviewRenderHint renderHint;
  final List<CinematicActorDisplayPreviewDiagnostic> diagnostics;

  bool get isRenderable {
    if (!position.isResolved) {
      return false;
    }
    return renderHint == CinematicActorPreviewRenderHint.sprite ||
        renderHint == CinematicActorPreviewRenderHint.placeholder;
  }
}

@immutable
final class CinematicActorDisplayPreviewModel {
  CinematicActorDisplayPreviewModel({
    required this.status,
    required this.summary,
    required List<CinematicActorDisplayPreviewActor> actors,
    required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  })  : actors = List<CinematicActorDisplayPreviewActor>.unmodifiable(actors),
        diagnostics = List<CinematicActorDisplayPreviewDiagnostic>.unmodifiable(
          diagnostics,
        );

  final CinematicActorDisplayPreviewStatus status;
  final String summary;
  final List<CinematicActorDisplayPreviewActor> actors;
  final List<CinematicActorDisplayPreviewDiagnostic> diagnostics;

  bool get isReady => status == CinematicActorDisplayPreviewStatus.ready;

  int get renderableActorCount =>
      actors.where((actor) => actor.isRenderable).length;

  CinematicActorDisplayPreviewActor? actorById(String actorId) {
    final normalizedId = actorId.trim();
    for (final actor in actors) {
      if (actor.actorId == normalizedId) {
        return actor;
      }
    }
    return null;
  }
}

CinematicActorDisplayPreviewModel buildCinematicActorDisplayPreviewModel({
  required CinematicAsset cinematic,
  required ProjectManifest project,
  required ProjectMapEntry? stageMap,
  required MapData? mapData,
  CinematicStageMapSourceCatalog? stageMapSourceCatalog,
}) {
  final sourceCatalog = stageMapSourceCatalog ??
      buildCinematicStageMapSourceCatalog(
        stageMap: stageMap,
        mapData: mapData,
      );
  final canUseMapData = sourceCatalog.isAvailable &&
      _canUseMapData(stageMap: stageMap, mapData: mapData);
  final context = cinematic.stageContext ?? CinematicStageContext();
  final diagnostics = <CinematicActorDisplayPreviewDiagnostic>[];
  final requiredActors = <CinematicActorRef>[];
  final requiredActorIds = <String>{};

  for (final actor in cinematic.requiredActors) {
    final actorId = actor.actorId.trim();
    if (requiredActorIds.add(actorId)) {
      requiredActors.add(actor);
    } else {
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayDuplicateActor,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: 'Acteur requis en doublon ignore: $actorId.',
          actorId: actorId,
        ),
      );
    }
  }

  if (requiredActors.isEmpty) {
    return CinematicActorDisplayPreviewModel(
      status: CinematicActorDisplayPreviewStatus.noActors,
      summary: 'Aucun acteur requis.',
      actors: const [],
      diagnostics: const [
        CinematicActorDisplayPreviewDiagnostic(
          code: CinematicActorDisplayPreviewDiagnosticCode.actorDisplayNoActors,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.info,
          message: 'La cinematique ne declare aucun acteur requis.',
        ),
      ],
    );
  }

  final actorBindings = _firstByActorId<CinematicActorBinding>(
    context.actorBindings,
    actorIdOf: (binding) => binding.actorId,
    duplicateCode:
        CinematicActorDisplayPreviewDiagnosticCode.actorDisplayDuplicateBinding,
    requiredActorIds: requiredActorIds,
    diagnostics: diagnostics,
    duplicateMessage: 'Binding acteur en doublon ignore.',
    orphanCode:
        CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOrphanBinding,
    orphanMessage: 'Binding acteur orphelin ignore.',
  );
  final appearanceBindings = _firstByActorId<CinematicActorAppearanceBinding>(
    context.actorAppearanceBindings,
    actorIdOf: (binding) => binding.actorId,
    duplicateCode: CinematicActorDisplayPreviewDiagnosticCode
        .actorDisplayDuplicateAppearance,
    requiredActorIds: requiredActorIds,
    diagnostics: diagnostics,
    duplicateMessage: 'Binding apparence en doublon ignore.',
    orphanCode:
        CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOrphanAppearance,
    orphanMessage: 'Binding apparence orphelin ignore.',
  );
  final placements = _firstByActorId<CinematicActorInitialPlacement>(
    context.initialPlacements,
    actorIdOf: (placement) => placement.actorId,
    duplicateCode: CinematicActorDisplayPreviewDiagnosticCode
        .actorDisplayDuplicatePlacement,
    requiredActorIds: requiredActorIds,
    diagnostics: diagnostics,
    duplicateMessage: 'Placement initial en doublon ignore.',
    orphanCode:
        CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOrphanPlacement,
    orphanMessage: 'Placement initial orphelin ignore.',
  );
  final movementTargets = <String>{};
  for (final target in cinematic.movementTargets) {
    movementTargets.add(target.targetId.trim());
  }
  final movementTargetBindings =
      _firstByMovementTargetId<CinematicMovementTargetBinding>(
    context.movementTargetBindings,
    targetIdOf: (binding) => binding.targetId,
    duplicateCode: CinematicActorDisplayPreviewDiagnosticCode
        .actorDisplayDuplicateMovementTargetBinding,
    knownTargetIds: movementTargets,
    diagnostics: diagnostics,
  );

  final actors = <CinematicActorDisplayPreviewActor>[];
  for (final actorRef in requiredActors) {
    final actorId = actorRef.actorId.trim();
    final actorDiagnostics = <CinematicActorDisplayPreviewDiagnostic>[];
    final binding = actorBindings[actorId];
    final bindingStatus = _bindingStatusOf(binding);
    final bindingEntity = _resolveBindingEntity(
      binding: binding,
      mapData: canUseMapData ? mapData : null,
    );
    final position = _resolvePosition(
      actorId: actorId,
      binding: binding,
      bindingEntity: bindingEntity,
      placement: placements[actorId],
      movementTargetIds: movementTargets,
      movementTargetBindings: movementTargetBindings,
      mapData: canUseMapData ? mapData : null,
      diagnostics: actorDiagnostics,
    );
    final directionResolution = _resolveDirection(
      cinematic: cinematic,
      actorId: actorId,
      bindingEntity: bindingEntity,
      diagnostics: actorDiagnostics,
    );
    final appearance = _resolveAppearance(
      actorId: actorId,
      binding: binding,
      bindingEntity: bindingEntity,
      appearanceBinding: appearanceBindings[actorId],
      project: project,
      direction: directionResolution.direction,
      diagnostics: actorDiagnostics,
    );
    final renderHint = _renderHintFor(
      bindingStatus: bindingStatus,
      position: position,
      appearance: appearance,
    );
    final bindingSourceId = binding?.mapEntityId?.trim();
    actors.add(
      CinematicActorDisplayPreviewActor(
        actorId: actorId,
        label: _labelOrId(actorRef.label, actorId),
        role: actorRef.role,
        bindingStatus: bindingStatus,
        bindingKind: binding?.kind,
        bindingSourceId: bindingSourceId,
        bindingSourceLabel: bindingEntity == null
            ? bindingSourceId
            : _entityLabel(bindingEntity),
        position: position,
        appearance: appearance,
        direction: directionResolution.direction,
        directionSource: directionResolution.source,
        renderHint: renderHint,
        diagnostics: actorDiagnostics,
      ),
    );
    diagnostics.addAll(actorDiagnostics);
  }

  final status = _modelStatusFor(actors, diagnostics);
  final summary =
      '${actors.length} acteur(s), ${actors.where((actor) => actor.isRenderable).length} projetable(s).';

  return CinematicActorDisplayPreviewModel(
    status: status,
    summary: summary,
    actors: actors,
    diagnostics: diagnostics,
  );
}

CinematicActorDisplayPreviewStatus _modelStatusFor(
  List<CinematicActorDisplayPreviewActor> actors,
  List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
) {
  if (diagnostics.any((diagnostic) => diagnostic.isBlocking)) {
    return CinematicActorDisplayPreviewStatus.blocked;
  }
  if (actors.every((actor) => actor.isRenderable) &&
      diagnostics.every((diagnostic) =>
          diagnostic.severity ==
          CinematicActorDisplayPreviewDiagnosticSeverity.info)) {
    return CinematicActorDisplayPreviewStatus.ready;
  }
  return CinematicActorDisplayPreviewStatus.incomplete;
}

Map<String, T> _firstByActorId<T>(
  Iterable<T> values, {
  required String Function(T value) actorIdOf,
  required CinematicActorDisplayPreviewDiagnosticCode duplicateCode,
  required Set<String> requiredActorIds,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  required String duplicateMessage,
  required CinematicActorDisplayPreviewDiagnosticCode orphanCode,
  required String orphanMessage,
}) {
  final byActorId = <String, T>{};
  for (final value in values) {
    final actorId = actorIdOf(value).trim();
    if (!requiredActorIds.contains(actorId)) {
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: orphanCode,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: '$orphanMessage ActorId: $actorId.',
          actorId: actorId,
        ),
      );
      continue;
    }
    if (byActorId.containsKey(actorId)) {
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: duplicateCode,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: '$duplicateMessage ActorId: $actorId.',
          actorId: actorId,
        ),
      );
      continue;
    }
    byActorId[actorId] = value;
  }
  return byActorId;
}

Map<String, T> _firstByMovementTargetId<T>(
  Iterable<T> values, {
  required String Function(T value) targetIdOf,
  required CinematicActorDisplayPreviewDiagnosticCode duplicateCode,
  required Set<String> knownTargetIds,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  final byTargetId = <String, T>{};
  for (final value in values) {
    final targetId = targetIdOf(value).trim();
    if (!knownTargetIds.contains(targetId)) {
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayOrphanMovementTargetBinding,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: 'Binding de cible deplacement orphelin ignore: $targetId.',
          sourceId: targetId,
        ),
      );
      continue;
    }
    if (byTargetId.containsKey(targetId)) {
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: duplicateCode,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: 'Binding de cible deplacement en doublon ignore: $targetId.',
          sourceId: targetId,
        ),
      );
      continue;
    }
    byTargetId[targetId] = value;
  }
  return byTargetId;
}

CinematicActorDisplayBindingStatus _bindingStatusOf(
  CinematicActorBinding? binding,
) {
  if (binding == null) {
    return CinematicActorDisplayBindingStatus.missing;
  }
  return switch (binding.kind) {
    CinematicActorBindingKind.player =>
      CinematicActorDisplayBindingStatus.player,
    CinematicActorBindingKind.mapEntity =>
      CinematicActorDisplayBindingStatus.mapEntity,
    CinematicActorBindingKind.cinematicOnly =>
      CinematicActorDisplayBindingStatus.cinematicOnly,
    CinematicActorBindingKind.unbound =>
      CinematicActorDisplayBindingStatus.unbound,
  };
}

MapEntity? _resolveBindingEntity({
  required CinematicActorBinding? binding,
  required MapData? mapData,
}) {
  if (binding?.kind != CinematicActorBindingKind.mapEntity || mapData == null) {
    return null;
  }
  final entityId = binding?.mapEntityId?.trim();
  if (entityId == null || entityId.isEmpty) {
    return null;
  }
  return _entityById(mapData, entityId);
}

CinematicActorPreviewPosition _resolvePosition({
  required String actorId,
  required CinematicActorBinding? binding,
  required MapEntity? bindingEntity,
  required CinematicActorInitialPlacement? placement,
  required Set<String> movementTargetIds,
  required Map<String, CinematicMovementTargetBinding> movementTargetBindings,
  required MapData? mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  if (binding == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingBinding,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Aucun binding de scene pour cet acteur.',
        actorId: actorId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingInitialPlacement,
      sourceKind: CinematicActorPreviewPositionSourceKind.none,
    );
  }
  if (binding.kind == CinematicActorBindingKind.unbound) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code:
            CinematicActorDisplayPreviewDiagnosticCode.actorDisplayUnboundActor,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Acteur non lie volontairement, aucun rendu recommande.',
        actorId: actorId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.unbound,
      sourceKind: CinematicActorPreviewPositionSourceKind.none,
    );
  }
  if (placement == null ||
      placement.kind == CinematicActorInitialPlacementKind.unset) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingInitialPlacement,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Aucun placement initial explicite pour cet acteur.',
        actorId: actorId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingInitialPlacement,
      sourceKind: CinematicActorPreviewPositionSourceKind.none,
    );
  }

  return switch (placement.kind) {
    CinematicActorInitialPlacementKind.unset =>
      const CinematicActorPreviewPosition(
        status: CinematicActorPreviewPositionStatus.missingInitialPlacement,
        sourceKind: CinematicActorPreviewPositionSourceKind.none,
      ),
    CinematicActorInitialPlacementKind.fromMapEntity => _positionFromMapEntity(
        actorId: actorId,
        binding: binding,
        entity: bindingEntity,
        mapData: mapData,
        diagnostics: diagnostics,
      ),
    CinematicActorInitialPlacementKind.fromMovementTarget =>
      _positionFromMovementTarget(
        actorId: actorId,
        targetId: placement.targetId,
        movementTargetIds: movementTargetIds,
        movementTargetBindings: movementTargetBindings,
        mapData: mapData,
        diagnostics: diagnostics,
      ),
  };
}

CinematicActorPreviewPosition _positionFromMapEntity({
  required String actorId,
  required CinematicActorBinding binding,
  required MapEntity? entity,
  required MapData? mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  if (binding.kind != CinematicActorBindingKind.mapEntity ||
      binding.mapEntityId == null ||
      entity == null ||
      mapData == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMapEntity,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'Le binding mapEntity ne pointe vers aucune entite valide.',
        actorId: actorId,
        sourceId: binding.mapEntityId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
    );
  }
  return _positionForEntity(
    actorId: actorId,
    entity: entity,
    mapData: mapData,
    diagnostics: diagnostics,
  );
}

CinematicActorPreviewPosition _positionFromMovementTarget({
  required String actorId,
  required String? targetId,
  required Set<String> movementTargetIds,
  required Map<String, CinematicMovementTargetBinding> movementTargetBindings,
  required MapData? mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  final normalizedTargetId = targetId?.trim();
  if (normalizedTargetId == null ||
      normalizedTargetId.isEmpty ||
      !movementTargetIds.contains(normalizedTargetId)) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMovementTarget,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'La cible de placement initial est inconnue.',
        actorId: actorId,
        sourceId: normalizedTargetId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
    );
  }
  final binding = movementTargetBindings[normalizedTargetId];
  if (binding == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMovementTarget,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'La cible de placement initial n a pas de binding.',
        actorId: actorId,
        sourceId: normalizedTargetId,
      ),
    );
    return const CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
    );
  }
  if (binding.kind == CinematicMovementTargetBindingKind.abstractPoint) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayAbstractTargetOnly,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'La cible de placement est abstraite et sans coordonnees.',
        actorId: actorId,
        sourceId: normalizedTargetId,
      ),
    );
    return CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.abstractOnly,
      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
      sourceId: normalizedTargetId,
    );
  }
  final sourceId = binding.sourceId?.trim();
  if (sourceId == null || sourceId.isEmpty || mapData == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMovementTarget,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'La cible de placement n a pas de source de map valide.',
        actorId: actorId,
        sourceId: normalizedTargetId,
      ),
    );
    return CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
      sourceId: normalizedTargetId,
    );
  }
  return switch (binding.kind) {
    CinematicMovementTargetBindingKind.abstractPoint =>
      CinematicActorPreviewPosition(
        status: CinematicActorPreviewPositionStatus.abstractOnly,
        sourceKind: CinematicActorPreviewPositionSourceKind.movementTarget,
        sourceId: normalizedTargetId,
      ),
    CinematicMovementTargetBindingKind.mapEntity => _positionForEntity(
        actorId: actorId,
        entity: _entityById(mapData, sourceId),
        mapData: mapData,
        diagnostics: diagnostics,
        targetId: normalizedTargetId,
      ),
    CinematicMovementTargetBindingKind.mapEvent => _positionForEvent(
        actorId: actorId,
        event: _eventById(mapData, sourceId),
        mapData: mapData,
        diagnostics: diagnostics,
        targetId: normalizedTargetId,
      ),
  };
}

CinematicActorPreviewPosition _positionForEntity({
  required String actorId,
  required MapEntity? entity,
  required MapData mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  String? targetId,
}) {
  if (entity == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMapEntity,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'Entite source introuvable pour l acteur.',
        actorId: actorId,
        sourceId: targetId,
      ),
    );
    return CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
      sourceId: targetId,
    );
  }
  final status = _entityInBounds(entity, mapData)
      ? CinematicActorPreviewPositionStatus.resolved
      : CinematicActorPreviewPositionStatus.outOfMapBounds;
  if (status == CinematicActorPreviewPositionStatus.outOfMapBounds) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayOutOfMapBounds,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Position acteur hors limites de map.',
        actorId: actorId,
        sourceId: entity.id,
      ),
    );
  }
  return CinematicActorPreviewPosition(
    status: status,
    sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
    x: entity.pos.x,
    y: entity.pos.y,
    sourceId: entity.id.trim(),
    sourceLabel: _entityLabel(entity),
  );
}

CinematicActorPreviewPosition _positionForEvent({
  required String actorId,
  required MapEventDefinition? event,
  required MapData mapData,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  String? targetId,
}) {
  if (event == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayMissingMovementTarget,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.error,
        message: 'Event source introuvable pour la cible de placement.',
        actorId: actorId,
        sourceId: targetId,
      ),
    );
    return CinematicActorPreviewPosition(
      status: CinematicActorPreviewPositionStatus.missingSource,
      sourceKind: CinematicActorPreviewPositionSourceKind.mapEvent,
      sourceId: targetId,
    );
  }
  final x = event.position.x;
  final y = event.position.y;
  final status = _pointInBounds(x: x, y: y, mapData: mapData)
      ? CinematicActorPreviewPositionStatus.resolved
      : CinematicActorPreviewPositionStatus.outOfMapBounds;
  if (status == CinematicActorPreviewPositionStatus.outOfMapBounds) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayOutOfMapBounds,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Position event hors limites de map.',
        actorId: actorId,
        sourceId: event.id,
      ),
    );
  }
  return CinematicActorPreviewPosition(
    status: status,
    sourceKind: CinematicActorPreviewPositionSourceKind.mapEvent,
    x: x,
    y: y,
    sourceId: event.id.trim(),
    sourceLabel: _labelOrId(event.title, event.id),
  );
}

_DirectionResolution _resolveDirection({
  required CinematicAsset cinematic,
  required String actorId,
  required MapEntity? bindingEntity,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  for (final step in cinematic.timeline.steps) {
    if (step.kind != CinematicTimelineStepKind.actorFace ||
        step.actorId?.trim() != actorId) {
      continue;
    }
    final direction = _directionFromActorFaceMetadata(step.metadata);
    if (direction != null) {
      return _DirectionResolution(
        direction: direction,
        source: CinematicActorPreviewDirectionSource.actorFace,
      );
    }
  }

  final facing = bindingEntity?.npc?.facing;
  if (facing != null) {
    return _DirectionResolution(
      direction: _directionFromEntityFacing(facing),
      source: CinematicActorPreviewDirectionSource.mapEntityFacing,
    );
  }

  diagnostics.add(
    CinematicActorDisplayPreviewDiagnostic(
      code: CinematicActorDisplayPreviewDiagnosticCode
          .actorDisplayDirectionFallback,
      severity: CinematicActorDisplayPreviewDiagnosticSeverity.info,
      message: 'Direction statique absente, fallback south.',
      actorId: actorId,
    ),
  );
  return const _DirectionResolution(
    direction: CinematicActorPreviewDirection.south,
    source: CinematicActorPreviewDirectionSource.fallback,
  );
}

CinematicActorPreviewAppearance _resolveAppearance({
  required String actorId,
  required CinematicActorBinding? binding,
  required MapEntity? bindingEntity,
  required CinematicActorAppearanceBinding? appearanceBinding,
  required ProjectManifest project,
  required CinematicActorPreviewDirection direction,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
}) {
  if (binding == null) {
    return const CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.unsupported,
    );
  }
  switch (binding.kind) {
    case CinematicActorBindingKind.unbound:
      return const CinematicActorPreviewAppearance(
        status: CinematicActorPreviewAppearanceStatus.notRequired,
      );
    case CinematicActorBindingKind.player:
      final characterId = project.settings.defaultPlayerCharacterId?.trim();
      if (characterId == null || characterId.isEmpty) {
        diagnostics.add(
          CinematicActorDisplayPreviewDiagnostic(
            code: CinematicActorDisplayPreviewDiagnosticCode
                .actorDisplayMissingAppearance,
            severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
            message: 'Aucun character par defaut pour le joueur.',
            actorId: actorId,
          ),
        );
        return const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
          sourceLabel: 'Joueur',
        );
      }
      return _appearanceFromCharacterId(
        actorId: actorId,
        characterId: characterId,
        project: project,
        direction: direction,
        diagnostics: diagnostics,
        sourceLabel: 'Joueur',
      );
    case CinematicActorBindingKind.cinematicOnly:
      final characterId = appearanceBinding?.characterId.trim();
      if (characterId == null || characterId.isEmpty) {
        diagnostics.add(
          CinematicActorDisplayPreviewDiagnostic(
            code: CinematicActorDisplayPreviewDiagnosticCode
                .actorDisplayMissingAppearance,
            severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
            message: 'Aucun character lie a cet acteur cinematicOnly.',
            actorId: actorId,
          ),
        );
        return const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
          sourceLabel: 'Cinematic only',
        );
      }
      return _appearanceFromCharacterId(
        actorId: actorId,
        characterId: characterId,
        project: project,
        direction: direction,
        diagnostics: diagnostics,
        sourceLabel: 'Character Library',
      );
    case CinematicActorBindingKind.mapEntity:
      if (bindingEntity == null) {
        return const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.unsupported,
          sourceLabel: 'Map entity',
        );
      }
      final directCharacterId = bindingEntity.npc?.characterId?.trim();
      if (directCharacterId != null && directCharacterId.isNotEmpty) {
        return _appearanceFromCharacterId(
          actorId: actorId,
          characterId: directCharacterId,
          project: project,
          direction: direction,
          diagnostics: diagnostics,
          sourceLabel: 'Map entity NPC',
        );
      }
      final trainerId = bindingEntity.npc?.trainerId?.trim();
      if (trainerId != null && trainerId.isNotEmpty) {
        final trainer = _trainerById(project, trainerId);
        final trainerCharacterId = trainer?.characterId?.trim();
        if (trainerCharacterId != null && trainerCharacterId.isNotEmpty) {
          return _appearanceFromCharacterId(
            actorId: actorId,
            characterId: trainerCharacterId,
            project: project,
            direction: direction,
            diagnostics: diagnostics,
            sourceLabel: 'Trainer',
          );
        }
      }
      if ((bindingEntity.npc?.visualElementId.trim() ?? '').isNotEmpty ||
          bindingEntity.resolvedProjectElementIdForEditor != null) {
        return CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
          sourceLabel: _entityLabel(bindingEntity),
        );
      }
      diagnostics.add(
        CinematicActorDisplayPreviewDiagnostic(
          code: CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayMissingAppearance,
          severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
          message: 'La mapEntity n expose aucun character exploitable.',
          actorId: actorId,
          sourceId: bindingEntity.id,
        ),
      );
      return CinematicActorPreviewAppearance(
        status: CinematicActorPreviewAppearanceStatus.placeholderOnly,
        sourceLabel: _entityLabel(bindingEntity),
      );
  }
}

CinematicActorPreviewAppearance _appearanceFromCharacterId({
  required String actorId,
  required String characterId,
  required ProjectManifest project,
  required CinematicActorPreviewDirection direction,
  required List<CinematicActorDisplayPreviewDiagnostic> diagnostics,
  required String sourceLabel,
}) {
  final character = _characterById(project, characterId);
  if (character == null) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayUnknownCharacter,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Character introuvable pour l acteur.',
        actorId: actorId,
        sourceId: characterId,
      ),
    );
    return CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.missingCharacter,
      characterId: characterId,
      sourceLabel: sourceLabel,
    );
  }
  final tilesetId = character.tilesetId.trim();
  if (tilesetId.isEmpty || !_projectHasTileset(project, tilesetId)) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayCharacterMissingTileset,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Character sans tileset exploitable.',
        actorId: actorId,
        sourceId: characterId,
      ),
    );
    return CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.missingTileset,
      characterId: character.id,
      characterLabel: character.name,
      sourceLabel: sourceLabel,
    );
  }
  if (!_hasIdleAnimation(character, direction)) {
    diagnostics.add(
      CinematicActorDisplayPreviewDiagnostic(
        code: CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayCharacterMissingIdleAnimation,
        severity: CinematicActorDisplayPreviewDiagnosticSeverity.warning,
        message: 'Character sans animation idle exploitable.',
        actorId: actorId,
        sourceId: characterId,
      ),
    );
    return CinematicActorPreviewAppearance(
      status: CinematicActorPreviewAppearanceStatus.missingIdleAnimation,
      characterId: character.id,
      characterLabel: character.name,
      tilesetId: tilesetId,
      sourceLabel: sourceLabel,
    );
  }
  return CinematicActorPreviewAppearance(
    status: CinematicActorPreviewAppearanceStatus.spriteReady,
    characterId: character.id,
    characterLabel: character.name,
    tilesetId: tilesetId,
    sourceLabel: sourceLabel,
  );
}

CinematicActorPreviewRenderHint _renderHintFor({
  required CinematicActorDisplayBindingStatus bindingStatus,
  required CinematicActorPreviewPosition position,
  required CinematicActorPreviewAppearance appearance,
}) {
  if (bindingStatus == CinematicActorDisplayBindingStatus.unbound ||
      appearance.status == CinematicActorPreviewAppearanceStatus.notRequired) {
    return CinematicActorPreviewRenderHint.hidden;
  }
  if (bindingStatus == CinematicActorDisplayBindingStatus.missing) {
    return CinematicActorPreviewRenderHint.missing;
  }
  if (appearance.status == CinematicActorPreviewAppearanceStatus.spriteReady) {
    return position.isResolved
        ? CinematicActorPreviewRenderHint.sprite
        : CinematicActorPreviewRenderHint.missing;
  }
  if (appearance.status ==
      CinematicActorPreviewAppearanceStatus.placeholderOnly) {
    return position.isResolved
        ? CinematicActorPreviewRenderHint.placeholder
        : CinematicActorPreviewRenderHint.missing;
  }
  return CinematicActorPreviewRenderHint.missing;
}

bool _canUseMapData({
  required ProjectMapEntry? stageMap,
  required MapData? mapData,
}) {
  if (stageMap == null || mapData == null) {
    return false;
  }
  return stageMap.id.trim() == mapData.id.trim();
}

MapEntity? _entityById(MapData mapData, String entityId) {
  final normalizedId = entityId.trim();
  for (final entity in mapData.entities) {
    if (entity.id.trim() == normalizedId) {
      return entity;
    }
  }
  return null;
}

MapEventDefinition? _eventById(MapData mapData, String eventId) {
  final normalizedId = eventId.trim();
  for (final event in mapData.events) {
    if (event.id.trim() == normalizedId) {
      return event;
    }
  }
  return null;
}

ProjectCharacterEntry? _characterById(
  ProjectManifest project,
  String characterId,
) {
  final normalizedId = characterId.trim();
  for (final character in project.characters) {
    if (character.id.trim() == normalizedId) {
      return character;
    }
  }
  return null;
}

ProjectTrainerEntry? _trainerById(ProjectManifest project, String trainerId) {
  final normalizedId = trainerId.trim();
  for (final trainer in project.trainers) {
    if (trainer.id.trim() == normalizedId) {
      return trainer;
    }
  }
  return null;
}

bool _projectHasTileset(ProjectManifest project, String tilesetId) {
  final normalizedId = tilesetId.trim();
  for (final tileset in project.tilesets) {
    if (tileset.id.trim() == normalizedId) {
      return true;
    }
  }
  return false;
}

bool _hasIdleAnimation(
  ProjectCharacterEntry character,
  CinematicActorPreviewDirection direction,
) {
  final preferredFacing = _entityFacingFromPreviewDirection(direction);
  var hasAnyIdle = false;
  for (final animation in character.animations) {
    if (animation.state != CharacterAnimationState.idle ||
        animation.frames.isEmpty) {
      continue;
    }
    hasAnyIdle = true;
    if (preferredFacing == null || animation.direction == preferredFacing) {
      return true;
    }
  }
  return hasAnyIdle;
}

bool _entityInBounds(MapEntity entity, MapData mapData) {
  return entity.pos.x >= 0 &&
      entity.pos.y >= 0 &&
      entity.pos.x + entity.size.width <= mapData.size.width &&
      entity.pos.y + entity.size.height <= mapData.size.height;
}

bool _pointInBounds({
  required int x,
  required int y,
  required MapData mapData,
}) {
  return x >= 0 && y >= 0 && x < mapData.size.width && y < mapData.size.height;
}

CinematicActorPreviewDirection? _directionFromActorFaceMetadata(
  Map<String, String> metadata,
) {
  return switch (metadata['actor.direction']) {
    'up' => CinematicActorPreviewDirection.north,
    'down' => CinematicActorPreviewDirection.south,
    'left' => CinematicActorPreviewDirection.west,
    'right' => CinematicActorPreviewDirection.east,
    _ => null,
  };
}

CinematicActorPreviewDirection _directionFromEntityFacing(
  EntityFacing facing,
) {
  return switch (facing) {
    EntityFacing.north => CinematicActorPreviewDirection.north,
    EntityFacing.south => CinematicActorPreviewDirection.south,
    EntityFacing.east => CinematicActorPreviewDirection.east,
    EntityFacing.west => CinematicActorPreviewDirection.west,
  };
}

EntityFacing? _entityFacingFromPreviewDirection(
  CinematicActorPreviewDirection direction,
) {
  return switch (direction) {
    CinematicActorPreviewDirection.north => EntityFacing.north,
    CinematicActorPreviewDirection.south => EntityFacing.south,
    CinematicActorPreviewDirection.east => EntityFacing.east,
    CinematicActorPreviewDirection.west => EntityFacing.west,
    CinematicActorPreviewDirection.unknown => null,
  };
}

String _labelOrId(String? label, String id) {
  final trimmed = label?.trim();
  if (trimmed != null && trimmed.isNotEmpty) {
    return trimmed;
  }
  return id.trim();
}

String _entityLabel(MapEntity entity) {
  final headline = entity.inspectorHeadline.trim();
  return headline.isNotEmpty ? headline : entity.id.trim();
}

@immutable
final class _DirectionResolution {
  const _DirectionResolution({
    required this.direction,
    required this.source,
  });

  final CinematicActorPreviewDirection direction;
  final CinematicActorPreviewDirectionSource source;
}

```

## 9. Contenu complet du nouveau fichier de test

### packages/map_core/test/cinematic_actor_display_preview_model_test.dart

```dart
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('CinematicActorDisplayPreviewModel', () {
    test(
      'builds actor display preview model for cinematic actors without rendering them',
      () {
        final model = buildCinematicActorDisplayPreviewModel(
          cinematic: _cinematic(
            requiredActors: [
              _actor('player', label: 'Player'),
              _actor('guard', label: 'Guard'),
              _actor('liza', label: 'Liza'),
              _actor('unbound', label: 'Unbound'),
            ],
            movementTargets: [
              _target('target_player_spawn'),
              _target('target_event_arrival'),
            ],
            stageContext: CinematicStageContext(
              actorBindings: [
                CinematicActorBinding(
                  actorId: 'player',
                  kind: CinematicActorBindingKind.player,
                ),
                CinematicActorBinding(
                  actorId: 'guard',
                  kind: CinematicActorBindingKind.mapEntity,
                  mapEntityId: 'entity_guard',
                ),
                CinematicActorBinding(
                  actorId: 'liza',
                  kind: CinematicActorBindingKind.cinematicOnly,
                ),
                CinematicActorBinding(
                  actorId: 'unbound',
                  kind: CinematicActorBindingKind.unbound,
                ),
              ],
              actorAppearanceBindings: [
                CinematicActorAppearanceBinding(
                  actorId: 'liza',
                  characterId: 'liza_character',
                ),
              ],
              initialPlacements: [
                CinematicActorInitialPlacement(
                  actorId: 'player',
                  kind: CinematicActorInitialPlacementKind.fromMovementTarget,
                  targetId: 'target_player_spawn',
                ),
                CinematicActorInitialPlacement(
                  actorId: 'guard',
                  kind: CinematicActorInitialPlacementKind.fromMapEntity,
                ),
                CinematicActorInitialPlacement(
                  actorId: 'liza',
                  kind: CinematicActorInitialPlacementKind.fromMovementTarget,
                  targetId: 'target_event_arrival',
                ),
              ],
              movementTargetBindings: [
                CinematicMovementTargetBinding(
                  targetId: 'target_player_spawn',
                  kind: CinematicMovementTargetBindingKind.mapEntity,
                  sourceId: 'entity_spawn',
                ),
                CinematicMovementTargetBinding(
                  targetId: 'target_event_arrival',
                  kind: CinematicMovementTargetBindingKind.mapEvent,
                  sourceId: 'event_arrival',
                ),
              ],
            ),
          ),
          project: _project(),
          stageMap: _stageMap(),
          mapData: _mapData(),
        );

        expect(model.actors.map((actor) => actor.actorId), [
          'player',
          'guard',
          'liza',
          'unbound',
        ]);

        final player = model.actorById('player')!;
        expect(player.bindingStatus, CinematicActorDisplayBindingStatus.player);
        expect(player.position.status,
            CinematicActorPreviewPositionStatus.resolved);
        expect(player.position.x, 2);
        expect(player.position.y, 3);
        expect(
          player.appearance.status,
          CinematicActorPreviewAppearanceStatus.spriteReady,
        );
        expect(player.appearance.characterId, 'hero_character');

        final guard = model.actorById('guard')!;
        expect(
            guard.bindingStatus, CinematicActorDisplayBindingStatus.mapEntity);
        expect(guard.position.x, 6);
        expect(guard.position.y, 4);
        expect(guard.appearance.characterId, 'guard_character');
        expect(guard.direction, CinematicActorPreviewDirection.east);

        final liza = model.actorById('liza')!;
        expect(
          liza.bindingStatus,
          CinematicActorDisplayBindingStatus.cinematicOnly,
        );
        expect(liza.position.x, 9);
        expect(liza.position.y, 5);
        expect(liza.appearance.characterId, 'liza_character');
        expect(liza.renderHint, CinematicActorPreviewRenderHint.sprite);

        final unbound = model.actorById('unbound')!;
        expect(
            unbound.bindingStatus, CinematicActorDisplayBindingStatus.unbound);
        expect(unbound.position.status,
            CinematicActorPreviewPositionStatus.unbound);
        expect(
          unbound.appearance.status,
          CinematicActorPreviewAppearanceStatus.notRequired,
        );
        expect(unbound.renderHint, CinematicActorPreviewRenderHint.hidden);
        expect(unbound.isRenderable, isFalse);
      },
    );

    test('returns no actors status when cinematic has no required actors', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(model.status, CinematicActorDisplayPreviewStatus.noActors);
      expect(model.actors, isEmpty);
      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
            CinematicActorDisplayPreviewDiagnosticCode.actorDisplayNoActors),
      );
    });

    test('reports missing binding for actor without stage binding', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(requiredActors: [_actor('guard')]),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      final actor = model.actorById('guard')!;
      expect(actor.bindingStatus, CinematicActorDisplayBindingStatus.missing);
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode.actorDisplayMissingBinding,
        ),
      );
    });

    test('marks unbound actor as non renderable', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.unbound,
        ),
      );

      final actor = model.actorById('actor')!;
      expect(actor.bindingStatus, CinematicActorDisplayBindingStatus.unbound);
      expect(actor.isRenderable, isFalse);
      expect(actor.renderHint, CinematicActorPreviewRenderHint.hidden);
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayUnboundActor),
      );
    });

    test('resolves map entity actor position from map data entity', () {
      final model = _singleActorModel(
        actorId: 'guard',
        binding: CinematicActorBinding(
          actorId: 'guard',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_guard',
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'guard',
          kind: CinematicActorInitialPlacementKind.fromMapEntity,
        ),
      );

      final position = model.actorById('guard')!.position;
      expect(position.status, CinematicActorPreviewPositionStatus.resolved);
      expect(position.x, 6);
      expect(position.y, 4);
      expect(position.sourceId, 'entity_guard');
    });

    test('reports missing map entity when binding points to unknown entity',
        () {
      final model = _singleActorModel(
        actorId: 'guard',
        binding: CinematicActorBinding(
          actorId: 'guard',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_missing',
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'guard',
          kind: CinematicActorInitialPlacementKind.fromMapEntity,
        ),
      );

      final actor = model.actorById('guard')!;
      expect(actor.position.status,
          CinematicActorPreviewPositionStatus.missingSource);
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayMissingMapEntity,
        ),
      );
    });

    test(
        'resolves cinematic only actor appearance from character library binding',
        () {
      final model = _singleActorModel(
        actorId: 'liza',
        binding: CinematicActorBinding(
          actorId: 'liza',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'liza',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_event_arrival',
        ),
        appearance: CinematicActorAppearanceBinding(
          actorId: 'liza',
          characterId: 'liza_character',
        ),
        movementTargets: [_target('target_event_arrival')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_event_arrival',
            kind: CinematicMovementTargetBindingKind.mapEvent,
            sourceId: 'event_arrival',
          ),
        ],
      );

      final appearance = model.actorById('liza')!.appearance;
      expect(
          appearance.status, CinematicActorPreviewAppearanceStatus.spriteReady);
      expect(appearance.characterId, 'liza_character');
      expect(appearance.tilesetId, 'characters');
    });

    test('reports missing appearance binding for cinematic only actor', () {
      final model = _singleActorModel(
        actorId: 'liza',
        binding: CinematicActorBinding(
          actorId: 'liza',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
      );

      final actor = model.actorById('liza')!;
      expect(
        actor.appearance.status,
        CinematicActorPreviewAppearanceStatus.placeholderOnly,
      );
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayMissingAppearance,
        ),
      );
    });

    test('reports unknown character reference', () {
      final model = _singleActorModel(
        actorId: 'liza',
        binding: CinematicActorBinding(
          actorId: 'liza',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        appearance: CinematicActorAppearanceBinding(
          actorId: 'liza',
          characterId: 'missing_character',
        ),
      );

      final actor = model.actorById('liza')!;
      expect(
        actor.appearance.status,
        CinematicActorPreviewAppearanceStatus.missingCharacter,
      );
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayUnknownCharacter,
        ),
      );
    });

    test('reports character missing tileset', () {
      final model = _singleActorModel(
        actorId: 'liza',
        binding: CinematicActorBinding(
          actorId: 'liza',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        appearance: CinematicActorAppearanceBinding(
          actorId: 'liza',
          characterId: 'character_without_tileset',
        ),
      );

      expect(
        model.actorById('liza')!.appearance.status,
        CinematicActorPreviewAppearanceStatus.missingTileset,
      );
      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayCharacterMissingTileset,
        ),
      );
    });

    test('reports character missing idle animation', () {
      final model = _singleActorModel(
        actorId: 'liza',
        binding: CinematicActorBinding(
          actorId: 'liza',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        appearance: CinematicActorAppearanceBinding(
          actorId: 'liza',
          characterId: 'character_without_idle',
        ),
      );

      expect(
        model.actorById('liza')!.appearance.status,
        CinematicActorPreviewAppearanceStatus.missingIdleAnimation,
      );
      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayCharacterMissingIdleAnimation,
        ),
      );
    });

    test(
        'uses player default character when available without '
        'Game'
        'State', () {
      final model = _singleActorModel(
        actorId: 'player',
        binding: CinematicActorBinding(
          actorId: 'player',
          kind: CinematicActorBindingKind.player,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'player',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_player_spawn',
        ),
        movementTargets: [_target('target_player_spawn')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_player_spawn',
            kind: CinematicMovementTargetBindingKind.mapEntity,
            sourceId: 'entity_spawn',
          ),
        ],
      );

      final appearance = model.actorById('player')!.appearance;
      expect(
          appearance.status, CinematicActorPreviewAppearanceStatus.spriteReady);
      expect(appearance.characterId, 'hero_character');
    });

    test('falls back to placeholder for player without default character', () {
      final model = _singleActorModel(
        actorId: 'player',
        binding: CinematicActorBinding(
          actorId: 'player',
          kind: CinematicActorBindingKind.player,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'player',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_player_spawn',
        ),
        movementTargets: [_target('target_player_spawn')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_player_spawn',
            kind: CinematicMovementTargetBindingKind.mapEntity,
            sourceId: 'entity_spawn',
          ),
        ],
        project: _project(defaultPlayerCharacterId: null),
      );

      final actor = model.actorById('player')!;
      expect(
        actor.appearance.status,
        CinematicActorPreviewAppearanceStatus.placeholderOnly,
      );
      expect(actor.renderHint, CinematicActorPreviewRenderHint.placeholder);
    });

    test('resolves from movement target bound to map entity', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_entity',
        ),
        movementTargets: [_target('target_entity')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_entity',
            kind: CinematicMovementTargetBindingKind.mapEntity,
            sourceId: 'entity_spawn',
          ),
        ],
      );

      final position = model.actorById('actor')!.position;
      expect(position.status, CinematicActorPreviewPositionStatus.resolved);
      expect(position.x, 2);
      expect(position.y, 3);
    });

    test(
        'resolves from movement target bound to map event when position exists',
        () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_event_arrival',
        ),
        movementTargets: [_target('target_event_arrival')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_event_arrival',
            kind: CinematicMovementTargetBindingKind.mapEvent,
            sourceId: 'event_arrival',
          ),
        ],
      );

      final position = model.actorById('actor')!.position;
      expect(position.status, CinematicActorPreviewPositionStatus.resolved);
      expect(position.x, 9);
      expect(position.y, 5);
    });

    test('does not resolve abstract movement target to fake coordinates', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_abstract',
        ),
        movementTargets: [_target('target_abstract')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_abstract',
            kind: CinematicMovementTargetBindingKind.abstractPoint,
          ),
        ],
      );

      final position = model.actorById('actor')!.position;
      expect(position.status, CinematicActorPreviewPositionStatus.abstractOnly);
      expect(position.x, isNull);
      expect(position.y, isNull);
    });

    test('does not treat target_center as map coordinates', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMovementTarget,
          targetId: 'target_center',
        ),
        movementTargets: [_target('target_center')],
      );

      final position = model.actorById('actor')!.position;
      expect(
          position.status, CinematicActorPreviewPositionStatus.missingSource);
      expect(position.x, isNull);
      expect(position.y, isNull);
    });

    test('does not invent center map fallback for missing placement', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
      );

      final position = model.actorById('actor')!.position;
      expect(
        position.status,
        CinematicActorPreviewPositionStatus.missingInitialPlacement,
      );
      expect(position.x, isNull);
      expect(position.y, isNull);
    });

    test('reports out of bounds position', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_outside',
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMapEntity,
        ),
      );

      final actor = model.actorById('actor')!;
      expect(actor.position.status,
          CinematicActorPreviewPositionStatus.outOfMapBounds);
      expect(
        actor.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode.actorDisplayOutOfMapBounds,
        ),
      );
    });

    test('uses actorFace as static direction hint without playback', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.cinematicOnly,
        ),
        timelineSteps: [
          _actorFaceStep(actorId: 'actor', direction: 'left'),
          CinematicTimelineStep(
            id: 'move_actor',
            kind: CinematicTimelineStepKind.actorMove,
            actorId: 'actor',
            targetId: 'target_exit',
            metadata: const {
              'authoring.source': 'cinematic-builder-v0',
              'authoring.kind': 'basicBlock',
              'authoring.block': 'actorMove',
            },
          ),
        ],
      );

      final actor = model.actorById('actor')!;
      expect(actor.direction, CinematicActorPreviewDirection.west);
      expect(actor.directionSource,
          CinematicActorPreviewDirectionSource.actorFace);
    });

    test('ignores actorMove for initial position', () {
      final model = _singleActorModel(
        actorId: 'actor',
        binding: CinematicActorBinding(
          actorId: 'actor',
          kind: CinematicActorBindingKind.mapEntity,
          mapEntityId: 'entity_guard',
        ),
        placement: CinematicActorInitialPlacement(
          actorId: 'actor',
          kind: CinematicActorInitialPlacementKind.fromMapEntity,
        ),
        movementTargets: [_target('target_exit')],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'target_exit',
            kind: CinematicMovementTargetBindingKind.mapEntity,
            sourceId: 'entity_exit',
          ),
        ],
        timelineSteps: [
          CinematicTimelineStep(
            id: 'move_actor',
            kind: CinematicTimelineStepKind.actorMove,
            actorId: 'actor',
            targetId: 'target_exit',
          ),
        ],
      );

      final position = model.actorById('actor')!.position;
      expect(position.x, 6);
      expect(position.y, 4);
    });

    test('reports orphan actor binding', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(
          requiredActors: [_actor('actor')],
          stageContext: CinematicStageContext(
            actorBindings: [
              CinematicActorBinding(
                actorId: 'actor_orphan',
                kind: CinematicActorBindingKind.player,
              ),
            ],
          ),
        ),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(CinematicActorDisplayPreviewDiagnosticCode
            .actorDisplayOrphanBinding),
      );
    });

    test('reports orphan actor appearance binding', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(
          requiredActors: [_actor('actor')],
          stageContext: CinematicStageContext(
            actorAppearanceBindings: [
              CinematicActorAppearanceBinding(
                actorId: 'actor_orphan',
                characterId: 'hero_character',
              ),
            ],
          ),
        ),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayOrphanAppearance,
        ),
      );
    });

    test('reports orphan initial placement', () {
      final model = buildCinematicActorDisplayPreviewModel(
        cinematic: _cinematic(
          requiredActors: [_actor('actor')],
          stageContext: CinematicStageContext(
            initialPlacements: [
              CinematicActorInitialPlacement(
                actorId: 'actor_orphan',
                kind: CinematicActorInitialPlacementKind.fromMapEntity,
              ),
            ],
          ),
        ),
        project: _project(),
        stageMap: _stageMap(),
        mapData: _mapData(),
      );

      expect(
        model.diagnostics.map((diagnostic) => diagnostic.code),
        contains(
          CinematicActorDisplayPreviewDiagnosticCode
              .actorDisplayOrphanPlacement,
        ),
      );
    });

    test('keeps model pure without Flutter Flame runtime imports', () {
      final sourceFiles = [
        File('lib/src/read_models/cinematic_actor_display_preview_model.dart'),
        File('test/cinematic_actor_display_preview_model_test.dart'),
      ];
      final forbiddenFragments = [
        'package:' 'flutter',
        'dart:' 'ui',
        'ui.' 'Image',
        'Can' 'vas',
        'Custom' 'Painter',
        'Wid' 'get',
        'Build' 'Context',
        'package:' 'flame',
        'Game' 'State',
        'map_' 'runtime',
        'map_' 'editor',
      ];

      for (final file in sourceFiles) {
        final content = file.readAsStringSync();
        for (final fragment in forbiddenFragments) {
          expect(
            content.contains(fragment),
            isFalse,
            reason: '${file.path} must not contain $fragment',
          );
        }
      }
    });
  });
}

CinematicActorDisplayPreviewModel _singleActorModel({
  required String actorId,
  required CinematicActorBinding binding,
  CinematicActorInitialPlacement? placement,
  CinematicActorAppearanceBinding? appearance,
  List<CinematicMovementTargetRef> movementTargets = const [],
  List<CinematicMovementTargetBinding> movementTargetBindings = const [],
  List<CinematicTimelineStep> timelineSteps = const [],
  ProjectManifest? project,
}) {
  return buildCinematicActorDisplayPreviewModel(
    cinematic: _cinematic(
      requiredActors: [_actor(actorId)],
      movementTargets: movementTargets,
      timelineSteps: timelineSteps,
      stageContext: CinematicStageContext(
        actorBindings: [binding],
        actorAppearanceBindings: [
          if (appearance != null) appearance,
        ],
        initialPlacements: [
          if (placement != null) placement,
        ],
        movementTargetBindings: movementTargetBindings,
      ),
    ),
    project: project ?? _project(),
    stageMap: _stageMap(),
    mapData: _mapData(),
  );
}

CinematicActorRef _actor(String actorId, {String? label}) {
  return CinematicActorRef(actorId: actorId, label: label);
}

CinematicMovementTargetRef _target(String targetId) {
  return CinematicMovementTargetRef(targetId: targetId, label: targetId);
}

CinematicAsset _cinematic({
  List<CinematicActorRef> requiredActors = const [],
  List<CinematicMovementTargetRef> movementTargets = const [],
  CinematicStageContext? stageContext,
  List<CinematicTimelineStep> timelineSteps = const [],
}) {
  return CinematicAsset(
    id: 'cinematic_test',
    title: 'Cinematic Test',
    mapId: 'map_lab',
    requiredActors: requiredActors,
    movementTargets: movementTargets,
    stageContext: stageContext,
    timeline: CinematicTimeline(steps: timelineSteps),
  );
}

CinematicTimelineStep _actorFaceStep({
  required String actorId,
  required String direction,
}) {
  return CinematicTimelineStep(
    id: 'face_$actorId',
    kind: CinematicTimelineStepKind.actorFace,
    actorId: actorId,
    metadata: {
      'authoring.source': 'cinematic-builder-v0',
      'authoring.kind': 'basicBlock',
      'authoring.block': 'actorFace',
      'actor.direction': direction,
    },
  );
}

ProjectManifest _project(
    {String? defaultPlayerCharacterId = 'hero_character'}) {
  return ProjectManifest(
    name: 'Test Project',
    maps: [_stageMap()],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'characters',
        name: 'Characters',
        relativePath: 'tilesets/characters.png',
      ),
    ],
    characters: [
      _character('hero_character', 'Hero'),
      _character('guard_character', 'Guard'),
      _character('liza_character', 'Liza'),
      _character(
        'character_without_tileset',
        'Missing Tileset',
        tilesetId: '',
      ),
      _character(
        'character_without_idle',
        'Missing Idle',
        animations: [
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: EntityFacing.south,
            frames: [_frame()],
          ),
        ],
      ),
    ],
    trainers: const [
      ProjectTrainerEntry(
        id: 'trainer_guard',
        name: 'Guard Trainer',
        trainerClass: 'Guard',
        characterId: 'guard_character',
      ),
    ],
    settings: ProjectSettings(
      defaultPlayerCharacterId: defaultPlayerCharacterId,
    ),
  );
}

ProjectCharacterEntry _character(
  String id,
  String name, {
  String tilesetId = 'characters',
  List<CharacterAnimation>? animations,
}) {
  return ProjectCharacterEntry(
    id: id,
    name: name,
    tilesetId: tilesetId,
    animations: animations ??
        [
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.south,
            frames: [_frame()],
          ),
          CharacterAnimation(
            state: CharacterAnimationState.idle,
            direction: EntityFacing.east,
            frames: [_frame(x: 1)],
          ),
        ],
  );
}

CharacterAnimationFrame _frame({int x = 0, int y = 0}) {
  return CharacterAnimationFrame(
    source: TilesetSourceRect(x: x, y: y),
  );
}

ProjectMapEntry _stageMap() {
  return const ProjectMapEntry(
    id: 'map_lab',
    name: 'Research Lab',
    relativePath: 'maps/research_lab.json',
  );
}

MapData _mapData() {
  return const MapData(
    id: 'map_lab',
    name: 'Research Lab',
    size: GridSize(width: 12, height: 10),
    entities: [
      MapEntity(
        id: 'entity_spawn',
        name: 'Player spawn',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 3),
        spawn: MapEntitySpawnData(spawnKey: 'default'),
      ),
      MapEntity(
        id: 'entity_guard',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 6, y: 4),
        npc: MapEntityNpcData(
          displayName: 'Guard',
          facing: EntityFacing.east,
          characterId: 'guard_character',
        ),
      ),
      MapEntity(
        id: 'entity_exit',
        name: 'Exit',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 10, y: 8),
      ),
      MapEntity(
        id: 'entity_outside',
        name: 'Outside',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 16, y: 4),
      ),
    ],
    events: [
      MapEventDefinition(
        id: 'event_arrival',
        title: 'Arrival',
        pages: [MapEventPage(pageNumber: 0)],
        position: EventPosition(layerId: 'ground', x: 9, y: 5),
      ),
    ],
  );
}

```

## 10. Hunks complets des fichiers modifies

### packages/map_core/lib/map_core.dart

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 86b4e460..eebf383c 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -99,6 +99,7 @@ export 'src/read_models/linked_asset_public_contracts.dart';
 export 'src/read_models/cinematics_library_read_model.dart';
 export 'src/read_models/cinematic_timeline_lane_read_model.dart';
 export 'src/read_models/cinematic_timeline_time_layout_read_model.dart';
+export 'src/read_models/cinematic_actor_display_preview_model.dart';
 export 'src/read_models/cinematic_map_backdrop_preview_model.dart';
 export 'src/read_models/cinematic_stage_map_source_catalog.dart';
 export 'src/read_models/storyline_scene_links_read_model.dart';
```

### roadmaps

```diff
diff --git a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
index 7f4d3330..d5ec75ac 100644
--- a/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
+++ b/reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
@@ -9,7 +9,7 @@ Le runtime reste indispensable, mais le prochain blocage produit est plus basiqu
 ## Prochain lot exact recommande
 
 ```text
-NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0
+NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0
 ```
 
 ## Principes
@@ -124,8 +124,27 @@ NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0
 | NS-SCENES-V1-88 | Cinematic Map Backdrop Real Tile Renderer V0 | editor / preview-sandbox | Afficher les vraies tiles/assets de la map dans le Cinematic Builder via un renderer read-only editor-only, avec images resolues en amont et diagnostics visibles. | Pas de runtime/Flame, `PlayableMapGame`, playback, acteurs rendus, pathfinding/collision, mutation map/projet, donnees Selbrume ou image IA. | Builder cinematics, renderer cinematic, asset registry/cache editor-only, tests widget, rapport, Visual Gate. | DONE : rendu `TileLayer` visible via instructions bitmap, registre asset editor-only, fallback structurel diagnostique, proportions V1-86 preservees, tests/Visual Gate. | Divergence visuelle avec Map Editor ; cache image perime ; fallback silencieux ; timeline reduite. | DONE : vraie map statique affichable sans lancer la cinematique. | V1-87. |
 | NS-SCENES-V1-89 | Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0 | editor / preview-sandbox | Brancher le renderer bitmap V1-88 au vrai workspace editor : resolver tileset parent, chargement async borne, fallback diagnostique et fidelity TileLayer durcie. | Pas d'acteurs rendus, runtime/Flame, playback/interpolation, pathfinding/collision, donnee Selbrume hardcodee ou mutation runtime/map/projet. | Library/Builder cinematics, `narrative_workspace_canvas.dart`, loader asset, tests widget/plan, rapports, screenshot. | DONE : success/fallback/collecteur/fidelite, Visual Gate 1663x926, anti-scope runtime/Flame. | Fallback silencieux ; stale cache ; charger des images dans build/paint ; reduire la timeline. | DONE : vraies tiles resolues depuis le parent editor et affichees dans le Builder. | V1-88. |
 | NS-SCENES-V1-90 | Cinematic Actor Display Preview Prep Contract | doc-only / architecture-review | Cadrer l'affichage statique futur des acteurs une fois le vrai decor map rendu : sources actor bindings/placements/Character Library, positions, apparences, overlay/viewport et diagnostics. | Pas de code produit, package, test, screenshot, rendu acteur actif, runtime/Flame, playback/interpolation, pathfinding/collision, donnee Selbrume ou mutation runtime/map/projet. | Rapport V1-90, Evidence Pack, roadmaps. | DONE : sub-agents A-F, Option C retenue, contrat actor display read model, positions, apparences, overlay, diagnostics/tests/Visual Gate V1-91, anti-scope runtime. | Confondre acteur statique et gameplay ; cacher les gaps Character Library ; casser le decor V1-89 ; coder un renderer trop tot. | DONE : contrat pret pour read model Actor Display statique futur, sans rendre d'acteur. | V1-89. |
-| NS-SCENES-V1-91 | Cinematic Actor Display Preview Read Model V0 | core / read-model | Creer un read model pur des acteurs affichables dans la preview cinematic : acteurs, bindings, positions resolues ou manquantes, apparences, placeholders, diagnostics et summary. | Pas de renderer UI, sprite actor affiche, playback, runtime/Flame, GameState, pathfinding/collision, mutation MapData/ProjectManifest ou screenshot. | `map_core` read model actor display, tests purs, rapport. | TODO : modeliser les acteurs statiques sans UI. | Melanger read model et painter ; inventer des positions ; utiliser le runtime pour simplifier. | TODO : actor display projetable et testable, sans rendu. | V1-90. |
-| NS-SCENES-V1-92 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | Backlog post Actor Display Read Model. |
+| NS-SCENES-V1-91 | Cinematic Actor Display Preview Read Model V0 | core / read-model | Creer un read model pur des acteurs affichables dans la preview cinematic : acteurs, bindings, positions resolues ou manquantes, apparences, placeholders, diagnostics et summary. | Pas de renderer UI, sprite actor affiche, playback, runtime/Flame, GameState, pathfinding/collision, mutation MapData/ProjectManifest ou screenshot. | `map_core` read model actor display, tests purs, rapport. | DONE : `CinematicActorDisplayPreviewModel`, builder pur depuis `CinematicAsset`/manifest/stage map/MapData, diagnostics locaux, positions/apparences/directions/render hints et tests/analyze core verts. | Melanger read model et painter ; inventer des positions ; utiliser le runtime pour simplifier. | DONE : actor display projetable et testable, sans rendu. | V1-90. |
+| NS-SCENES-V1-92 | Cinematic Actor Display Preview Renderer V0 | editor / preview-sandbox | Brancher le read model V1-91 dans le Cinematic Builder pour afficher des acteurs statiques sous forme de placeholders ou sprites si les assets sont resolus, par-dessus le decor V1-89. | Pas de playback, actorMove interpolation, runtime/Flame, GameState, pathfinding/collision, mutation MapData/ProjectManifest ou lancement de cinematique. | Builder cinematics, renderer actor display, tests widget, rapport, screenshot. | TODO : rendu statique des acteurs depuis le read model V1-91. | Confondre projection statique et playback ; charger les sprites dans core ; casser les proportions preview/timeline. | TODO : actors visibles en preview editor-only, sans runtime. | V1-91. |
+| NS-SCENES-V1-93 | Cinematic Timeline Scroll / Visibility Polish V0 | editor / ui-polish | Backlog futur : polir la visibilite des blocs/repere/selection quand les interactions clavier ou souris placent l'element cible hors de la vue utile. | Pas de playback, seek runtime, scrubber runtime, transport fonctionnel, drag/resize/reorder, mutation JSON, runtime, zoom temporel ou changement de modele. | Builder cinematics, tests widget, rapport, screenshot. | TODO : scroll automatique/visibilite controles, proportions timeline preservees, selection/probe non mutants. | Casser les proportions visees ; confondre scroll de vue et navigation temporelle ; ajouter un pouvoir de montage. | TODO : visibilite plus fiable, sans nouveau pouvoir temporel. | Backlog post Actor Display Renderer. |
+
+## Mise a jour V1-91
+
+Statut : `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0` est DONE.
+
+Demande : Karim a fourni le prompt V1-91 et a demande un read model pur avant tout renderer. Le lot materialise la projection testable des acteurs sans rendu UI.
+
+Decision : `map_core` expose `CinematicActorDisplayPreviewModel` et `buildCinematicActorDisplayPreviewModel({cinematic, project, stageMap, mapData, stageMapSourceCatalog})`. Le builder ne lit aucun fichier, ne charge aucun sprite, ne depend ni de Flutter/Flame/runtime/editor et ne simule pas la timeline.
+
+Scope realise : inventaire `requiredActors`, bindings player/mapEntity/cinematicOnly/unbound, positions fromMapEntity/fromMovementTarget mapEntity/mapEvent, abstractPoint sans coordonnees, apparences player/Character Library/mapEntity NPC/trainer, directions actorFace statiques, actorMove ignore, render hints abstraits, diagnostics locaux et summary.
+
+Preuve : RED attendu sur API absente, 25 tests V1-91 verts, tests non-regression `cinematic_map_backdrop_preview_model_test.dart`, `cinematic_stage_map_source_catalog_test.dart`, `cinematic_asset_test.dart`, `project_manifest_cinematics_test.dart` verts, `dart analyze` map_core sans issue et suite complete map_core verte.
+
+Limites : aucun acteur n'est affiche, aucun renderer n'est ajoute, aucun sprite n'est charge, aucun runtime/playback/pathfinding/collision n'est touche, aucune donnee Selbrume ni image IA n'est utilisee.
+
+Prochain lot exact recommande : `NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0`.
+
+Le polish scroll/visibility est repousse explicitement a `NS-SCENES-V1-93 — Cinematic Timeline Scroll / Visibility Polish V0`.
 
 ## Mise a jour V1-90
 
diff --git a/reports/narrativeStudio/scenes/road_map_scenes.md b/reports/narrativeStudio/scenes/road_map_scenes.md
index 94e883b6..19625a5d 100644
--- a/reports/narrativeStudio/scenes/road_map_scenes.md
+++ b/reports/narrativeStudio/scenes/road_map_scenes.md
@@ -145,20 +145,37 @@ Ces briques sont utiles, mais elles ne constituent pas encore une Scene V1 propr
 | NS-SCENES-V1-88 — Cinematic Map Backdrop Real Tile Renderer V0 | DONE | Renderer bitmap editor-only read-only pour la preview du Cinematic Builder : instructions tiles derivees de `MapData`, images tileset resolues en amont, painter dedie proportionnel, diagnostics/fallbacks, Visual Gate 1663x926, tests builder/library/core et analyse ciblee verts, sans runtime, Flame, playback, acteurs rendus, pathfinding, collision, mutation projet/map, donnees Selbrume ni image IA. |
 | NS-SCENES-V1-89 — Cinematic Map Backdrop Real Tile Renderer Integration / Fidelity Polish V0 | DONE | Integre le renderer bitmap V1-88 au vrai workspace editor : resolution tileset via parent/editor notifier, fallback structurel uniquement diagnostique, fidelity TileLayer durcie, Visual Gate 1663x926, sans acteurs/playback/runtime. |
 | NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract | DONE | Lot documentaire demande par Karim : audit actor sources/stage bindings, positions/placements, Character Library/appearances, overlay/viewport, anti-runtime/Flame et UX ; Option C retenue, contrat futur read model actor display, diagnostics/tests/Visual Gate V1-91 cadres, sans code produit, packages, tests, screenshot, rendu acteur, runtime, playback, pathfinding/collision ni donnee Selbrume. |
-| NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0 | TODO | Creer un read model pur des acteurs affichables dans la preview cinematic : acteurs, bindings, positions resolues ou manquantes, apparences, placeholders, diagnostics et summary, sans encore rendre les acteurs en UI. |
-| NS-SCENES-V1-92 — Cinematic Timeline Scroll / Visibility Polish V0 | TODO | Backlog futur déplacé depuis V1-80/V1-91 : polir le scroll automatique et la visibilite des blocs/selection/probe apres le read model Actor Display, en preservant les proportions de timeline demandees par Karim. |
+| NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0 | DONE | Read model pur `map_core` `CinematicActorDisplayPreviewModel` demande par Karim : inventaire `requiredActors`, bindings player/mapEntity/cinematicOnly/unbound, positions resolues/manquantes, apparences Character Library/player/mapEntity, directions statiques, render hints abstraits, diagnostics locaux, tests/analyze core verts, sans renderer UI, sprite affiche, runtime, Flame, playback, pathfinding/collision ni donnee Selbrume. |
+| NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0 | TODO | Brancher le read model V1-91 dans le Cinematic Builder pour afficher des acteurs statiques sous forme de placeholders ou sprites si les assets sont resolus, par-dessus le decor V1-89, sans playback, sans actorMove interpolation, sans runtime et sans Flame. |
+| NS-SCENES-V1-93 — Cinematic Timeline Scroll / Visibility Polish V0 | TODO | Backlog futur deplace depuis V1-80/V1-91 : polir le scroll automatique et la visibilite des blocs/selection/probe apres le renderer Actor Display, en preservant les proportions de timeline demandees par Karim. |
 
 ## Prochain lot recommande
 
-`NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0`
+`NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0`
 
-Raison : V1-90 a tranche le contrat d'affichage statique futur des acteurs et retient un read model pur avant tout renderer. Le prochain verrou logique est de materialiser ce modele : inventaire acteurs, bindings, positions resolues ou manquantes, apparences, placeholders et diagnostics, sans encore dessiner d'acteur.
+Raison : V1-91 materialise maintenant le contrat d'affichage statique futur des acteurs sous forme de read model pur. Le prochain verrou logique est de brancher ce modele dans le Builder pour afficher les acteurs statiques, sans playback ni runtime.
 
-Ordre apres V1-90 : `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0`, puis `NS-SCENES-V1-92 — Cinematic Timeline Scroll / Visibility Polish V0` reste un backlog futur.
+Ordre apres V1-91 : `NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0`, puis `NS-SCENES-V1-93 — Cinematic Timeline Scroll / Visibility Polish V0` reste un backlog futur.
 
 Le lot `NS-SCENES-V1-78 — Cinematic Stage Source Drift Diagnostics Polish V0` précédemment recommandé est repoussé après la séquence Character Library Binding. Il reste pertinent, mais il ne doit plus occuper V1-78.
 
-Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` precedemment recommande est remplace par `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`, puis deplace en backlog futur. Il etait stocke comme `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0`; V1-72 devient maintenant le modele core Stage/Map Context. Le polish scroll/visibility a ensuite occupe le slot V1-80, mais V1-80 est maintenant reserve au Character Library Picker ; V1-90 est maintenant reserve a Actor Display Prep apres le lot V1-89 demande par Karim, puis V1-91 est pris par Actor Display Read Model. Le polish scroll/visibility est donc deplace explicitement en `NS-SCENES-V1-92 — Cinematic Timeline Scroll / Visibility Polish V0`.
+Le lot `NS-SCENES-V1-67 — Cinematic Timeline Scroll / Visibility Polish V0` precedemment recommande est remplace par `NS-SCENES-V1-67 — Cinematic Timeline Duration Editing / Resize Prep Contract`, puis deplace en backlog futur. Il etait stocke comme `NS-SCENES-V1-72 — Cinematic Timeline Scroll / Visibility Polish V0`; V1-72 devient maintenant le modele core Stage/Map Context. Le polish scroll/visibility a ensuite occupe le slot V1-80, mais V1-80 est maintenant reserve au Character Library Picker ; V1-90 est reserve a Actor Display Prep apres le lot V1-89 demande par Karim, V1-91 est pris par Actor Display Read Model, et V1-92 devient le renderer Actor Display. Le polish scroll/visibility est donc deplace explicitement en `NS-SCENES-V1-93 — Cinematic Timeline Scroll / Visibility Polish V0`.
+
+## Mise a jour V1-91
+
+Statut : `NS-SCENES-V1-91 — Cinematic Actor Display Preview Read Model V0` est DONE.
+
+Demande : Karim a fourni le prompt V1-91 et a demande un read model pur avant tout renderer. Le lot devait construire la projection testable des acteurs, tout en confirmant que V1-91 ne rend toujours aucun acteur dans l'interface.
+
+Decision : le read model vit dans `map_core` et consomme seulement des donnees deja chargees : `CinematicAsset`, `ProjectManifest`, `ProjectMapEntry`, `MapData` et, optionnellement, `CinematicStageMapSourceCatalog`. `requiredActors` reste l'inventaire canonique ; `actorBindings`, `actorAppearanceBindings`, `initialPlacements` et `movementTargetBindings` resolvent ou diagnostiquent bindings, apparences et positions.
+
+Scope realise : `CinematicActorDisplayPreviewModel`, acteurs projetables, statuts globaux, positions fromMapEntity/fromMovementTarget mapEntity/mapEvent, abstractPoint sans coordonnees inventees, player sans GameState, mapEntity via NPC/trainer character, cinematicOnly via Character Library, unbound hidden, directions actorFace statiques, actorMove ignore, render hints abstraits et diagnostics locaux.
+
+Preuve : RED test compile attendu, 25 tests V1-91 verts, tests core non-regression cibles verts, `dart analyze` map_core vert et suite complete `dart test --reporter=compact` map_core verte.
+
+Limites : V1-91 n'ajoute aucun renderer UI, ne charge aucun sprite, n'affiche aucun acteur, n'importe ni Flutter, ni dart:ui, ni Flame, ne touche pas au runtime, n'ajoute aucun playback, currentTimeMs/playbackTimeMs/isPlaying, pathfinding/collision, image IA ou donnee Selbrume.
+
+Prochain lot exact recommande : `NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0`.
 
 ## Mise a jour V1-90
```

## 11. Sorties finales git

### git diff --check final

Commande :
```bash
git diff --check
```

Code de sortie : `0`

Sortie :
```text
Sortie vide.
```
### git diff --stat final

Commande :
```bash
git diff --stat
```

Code de sortie : `0`

Sortie :
```text
 packages/map_core/lib/map_core.dart                |  1 +
 .../scenes/road_map_scene_builder_authoring.md     | 25 ++++++++++++++++---
 reports/narrativeStudio/scenes/road_map_scenes.md  | 29 +++++++++++++++++-----
 3 files changed, 46 insertions(+), 9 deletions(-)
```
### git diff --name-only final

Commande :
```bash
git diff --name-only
```

Code de sortie : `0`

Sortie :
```text
packages/map_core/lib/map_core.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```
### git status final

Commande :
```bash
git status --short --untracked-files=all
```

Code de sortie : `0`

Sortie :
```text
 M packages/map_core/lib/map_core.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart
?? packages/map_core/test/cinematic_actor_display_preview_model_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_read_model_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_91_evidence_pack.md
```

## 12. Auto-review critique

- 1. Est-ce que V1-91 a modifie map_editor ? Non.
- 2. Est-ce que V1-91 a modifie map_runtime ? Non.
- 3. Est-ce que V1-91 a modifie map_gameplay/map_battle/examples ? Non.
- 4. Est-ce que V1-91 a modifie selbrume ? Non.
- 5. Est-ce que V1-91 a importe Flutter ? Non.
- 6. Est-ce que V1-91 a importe dart:ui ? Non.
- 7. Est-ce que V1-91 a importe Flame ? Non.
- 8. Est-ce que V1-91 a importe map_runtime ? Non.
- 9. Est-ce que V1-91 a utilise GameState ? Non.
- 10. Est-ce que V1-91 a ajoute une UI ? Non.
- 11. Est-ce que V1-91 a rendu un acteur ? Non.
- 12. Est-ce que V1-91 a charge un sprite ? Non.
- 13. Est-ce que V1-91 a ajoute du playback ? Non.
- 14. Est-ce que V1-91 a ajoute currentTimeMs/playbackTimeMs/isPlaying ? Non.
- 15. Est-ce que requiredActors reste l inventaire canonique ? Oui.
- 16. Est-ce que les bindings orphelins sont diagnostiques ? Oui.
- 17. Est-ce que les placements orphelins sont diagnostiques ? Oui.
- 18. Est-ce que les appearances orphelines sont diagnostiquees ? Oui.
- 19. Est-ce que fromMapEntity est teste ? Oui.
- 20. Est-ce que fromMovementTarget mapEntity est teste ? Oui.
- 21. Est-ce que fromMovementTarget mapEvent est teste ? Oui.
- 22. Est-ce que abstractPoint est teste sans coordonnee inventee ? Oui.
- 23. Est-ce que missing placement n invente pas le centre de map ? Oui.
- 24. Est-ce que actorMove est ignore pour la position initiale ? Oui.
- 25. Est-ce que actorFace est utilise seulement comme direction hint ? Oui.
- 26. Est-ce que Character Library missing/tileset/idle est teste ? Oui.
- 27. Est-ce que map_core analyze passe ? Oui, No issues found.
- 28. Est-ce que l Evidence Pack est complet sans placeholders ? Oui : code source complet inclus et sorties commande capturees.
- 29. Quel est le prochain lot exact recommande ? NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0.

## 13. Fichiers crees

- `packages/map_core/lib/src/read_models/cinematic_actor_display_preview_model.dart`
- `packages/map_core/test/cinematic_actor_display_preview_model_test.dart`
- `reports/narrativeStudio/scenes/ns_scenes_v1_91_cinematic_actor_display_preview_read_model_v0.md`
- `reports/narrativeStudio/scenes/ns_scenes_v1_91_evidence_pack.md`

## 14. Fichiers modifies

- `packages/map_core/lib/map_core.dart`
- `reports/narrativeStudio/scenes/road_map_scenes.md`
- `reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md`

## 15. Recommandation prochain lot

`NS-SCENES-V1-92 — Cinematic Actor Display Preview Renderer V0`
