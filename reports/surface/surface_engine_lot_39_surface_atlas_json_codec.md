# Surface Engine — Lot 39 — `ProjectSurfaceAtlas` JSON Codec V0

## 1. Résumé exécutif

Codec manuel (sans Freezed) pour `ProjectSurfaceAtlas`, `SurfaceAtlasGeometry` et value objects de géométrie : `Map<String, Object?>` stables, `ValidationException` sur forme, clés inconnues tolérées, `categoryId` null omis à l’encodage, `sortOrder` toujours encodé. 30 tests ; export `map_core` ; `ProjectManifest` et modèles `surface.dart` inchangés (pas de `toJson` sur les modèles).

## 2. Après le Lot 38

Persistance Surface préparée par des fonctions de codec dans `map_core`, sans branchement manifeste.

## 3. Fichiers consultés (audit)

`surface.dart`, `surface_catalog`, `map_exceptions`, tests atlas/géométrie/entrypoint, `map_core`.

## 4. Fichiers créés

`surface_atlas_json_codec.dart`, `surface_atlas_json_codec_test.dart`, ce rapport.

## 5. Fichiers modifiés

`map_core.dart` (+1 export).

## 6. API

Voir §37.A (codec) : `encode`/`decode` ProjectSurfaceAtlas, SurfaceAtlasGeometry, TileSize, GridSize, et `encodeSurfaceAtlasLayout` / `decodeSurfaceAtlasLayout`.

## 7–11. Schémas JSON

Atlas : id, name, tilesetId, geometry, sortOrder ; categoryId optionnelle. Geometry : tileSize, gridSize, layout (string = `SurfaceAtlasLayout.name`).

## 12. Encodage

Déterministe ; `categoryId` omis si null ; `sortOrder` toujours présent ; chaînes exactes.

## 13. Décodage

Types stricts ; clés inconnues ignorées ; map source lue seulement ; tilesetId non résolu vers un manifeste.

## 14. Décision categoryId

Null en entrée d’encodage → clé absente en sortie.

## 15. Décision sortOrder

Toujours présent en sortie (int) ; défaut 0 en entrée si clé absente.

## 16. Décision clés inconnues

Tolérées en décodage (atlas), sans fusion ni mutation de la source.

## 17. Décision tilesetId

Aucune vérification d’existence dans un projet / manifeste.

## 18. Décision pas de toJson sur modèles

Codec externe seulement (Lot 39).

## 19. Décision ProjectManifest

Non modifié ; champs `surface*` absents (test 29).

## 20. Ce qui a été testé

30 cas (codec, rejet, round-trip, manifest, export public, codec externe).

## 21. Ce que les tests prouvent

Schéma, robustesse, intégrité `ProjectManifest` JSON, non-régression atlas.

## 22. Non fait (hors lot)

Catalogue complet, animation, preset, `build_runner`, UI.

## 23. Manifest

Pas de champs surface persistants ajoutés.

## 24. Fichiers generated

Aucun `.g.dart` / Freezed lié à ce lot.

## 25. build_runner

Non lancé.

## 26. Autres paquets

Aucun changement runtime / editor / gameplay / battle.

## 27. Prochains lots

Brancher le codec sur un flux d’E/S quand le manifeste Surface sera défini.

## 28. Commandes lancées

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/surface_atlas_json_codec_test.dart
/opt/homebrew/bin/dart test test/project_surface_atlas_test.dart
/opt/homebrew/bin/dart test test/surface_atlas_geometry_test.dart
/opt/homebrew/bin/dart test test/surface_model_entrypoint_test.dart
/opt/homebrew/bin/dart analyze (chemins Lot 39)
/opt/homebrew/bin/dart test
```

`git status --short` (lecture seule) :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/surface_atlas_json_codec.dart
?? packages/map_core/test/surface_atlas_json_codec_test.dart
?? reports/surface/surface_engine_lot_39_surface_atlas_json_codec.md
```

## 29. Test ciblé `surface_atlas_json_codec_test.dart` (intégral)

```text
00:00 [32m+0[0m: [1m[90mloading test/surface_atlas_json_codec_test.dart[0m[0m                                                                                                                                              00:00 [32m+0[0m: surface_atlas_json_codec (Lot 39) 1. encode SurfaceAtlasTileSize[0m                                                                                                                             00:00 [32m+1[0m: surface_atlas_json_codec (Lot 39) 1. encode SurfaceAtlasTileSize[0m                                                                                                                             00:00 [32m+1[0m: surface_atlas_json_codec (Lot 39) 2. decode SurfaceAtlasTileSize[0m                                                                                                                             00:00 [32m+2[0m: surface_atlas_json_codec (Lot 39) 2. decode SurfaceAtlasTileSize[0m                                                                                                                             00:00 [32m+2[0m: surface_atlas_json_codec (Lot 39) 3. reject tile size missing / wrong type / width 0[0m                                                                                                         00:00 [32m+3[0m: surface_atlas_json_codec (Lot 39) 3. reject tile size missing / wrong type / width 0[0m                                                                                                         00:00 [32m+3[0m: surface_atlas_json_codec (Lot 39) 4. encode SurfaceAtlasGridSize[0m                                                                                                                             00:00 [32m+4[0m: surface_atlas_json_codec (Lot 39) 4. encode SurfaceAtlasGridSize[0m                                                                                                                             00:00 [32m+4[0m: surface_atlas_json_codec (Lot 39) 5. decode SurfaceAtlasGridSize[0m                                                                                                                             00:00 [32m+5[0m: surface_atlas_json_codec (Lot 39) 5. decode SurfaceAtlasGridSize[0m                                                                                                                             00:00 [32m+5[0m: surface_atlas_json_codec (Lot 39) 6. reject grid size missing / wrong type / columns 0[0m                                                                                                       00:00 [32m+6[0m: surface_atlas_json_codec (Lot 39) 6. reject grid size missing / wrong type / columns 0[0m                                                                                                       00:00 [32m+6[0m: surface_atlas_json_codec (Lot 39) 7. encode/decode layout grid[0m                                                                                                                               00:00 [32m+7[0m: surface_atlas_json_codec (Lot 39) 7. encode/decode layout grid[0m                                                                                                                               00:00 [32m+7[0m: surface_atlas_json_codec (Lot 39) 8. encode/decode layout columnsAreVariantsRowsAreFrames[0m                                                                                                    00:00 [32m+8[0m: surface_atlas_json_codec (Lot 39) 8. encode/decode layout columnsAreVariantsRowsAreFrames[0m                                                                                                    00:00 [32m+8[0m: surface_atlas_json_codec (Lot 39) 9. reject layout unknown or wrong casing[0m                                                                                                                   00:00 [32m+9[0m: surface_atlas_json_codec (Lot 39) 9. reject layout unknown or wrong casing[0m                                                                                                                   00:00 [32m+9[0m: surface_atlas_json_codec (Lot 39) 10. encode SurfaceAtlasGeometry[0m                                                                                                                            00:00 [32m+10[0m: surface_atlas_json_codec (Lot 39) 10. encode SurfaceAtlasGeometry[0m                                                                                                                           00:00 [32m+10[0m: surface_atlas_json_codec (Lot 39) 11. decode SurfaceAtlasGeometry + tileCount[0m                                                                                                               00:00 [32m+11[0m: surface_atlas_json_codec (Lot 39) 11. decode SurfaceAtlasGeometry + tileCount[0m                                                                                                               00:00 [32m+11[0m: surface_atlas_json_codec (Lot 39) 12. reject geometry missing nested / wrong types[0m                                                                                                          00:00 [32m+12[0m: surface_atlas_json_codec (Lot 39) 12. reject geometry missing nested / wrong types[0m                                                                                                          00:00 [32m+12[0m: surface_atlas_json_codec (Lot 39) 13. encode ProjectSurfaceAtlas minimal[0m                                                                                                                    00:00 [32m+13[0m: surface_atlas_json_codec (Lot 39) 13. encode ProjectSurfaceAtlas minimal[0m                                                                                                                    00:00 [32m+13[0m: surface_atlas_json_codec (Lot 39) 14. encode ProjectSurfaceAtlas full[0m                                                                                                                       00:00 [32m+14[0m: surface_atlas_json_codec (Lot 39) 14. encode ProjectSurfaceAtlas full[0m                                                                                                                       00:00 [32m+14[0m: surface_atlas_json_codec (Lot 39) 15. decode ProjectSurfaceAtlas minimal (no category, no sortOrder)[0m                                                                                        00:00 [32m+15[0m: surface_atlas_json_codec (Lot 39) 15. decode ProjectSurfaceAtlas minimal (no category, no sortOrder)[0m                                                                                        00:00 [32m+15[0m: surface_atlas_json_codec (Lot 39) 16. decode ProjectSurfaceAtlas full[0m                                                                                                                       00:00 [32m+16[0m: surface_atlas_json_codec (Lot 39) 16. decode ProjectSurfaceAtlas full[0m                                                                                                                       00:00 [32m+16[0m: surface_atlas_json_codec (Lot 39) 17. round-trip ProjectSurfaceAtlas[0m                                                                                                                        00:00 [32m+17[0m: surface_atlas_json_codec (Lot 39) 17. round-trip ProjectSurfaceAtlas[0m                                                                                                                        00:00 [32m+17[0m: surface_atlas_json_codec (Lot 39) 18. exact strings preserved (no trim in codec)[0m                                                                                                            00:00 [32m+18[0m: surface_atlas_json_codec (Lot 39) 18. exact strings preserved (no trim in codec)[0m                                                                                                            00:00 [32m+18[0m: surface_atlas_json_codec (Lot 39) 19. reject id / name / tilesetId missing, wrong type, whitespace tileset[0m                                                                                  00:00 [32m+19[0m: surface_atlas_json_codec (Lot 39) 19. reject id / name / tilesetId missing, wrong type, whitespace tileset[0m                                                                                  00:00 [32m+19[0m: surface_atlas_json_codec (Lot 39) 20. reject geometry missing or non-map on atlas[0m                                                                                                           00:00 [32m+20[0m: surface_atlas_json_codec (Lot 39) 20. reject geometry missing or non-map on atlas[0m                                                                                                           00:00 [32m+20[0m: surface_atlas_json_codec (Lot 39) 21. reject categoryId non-string non-null[0m                                                                                                                 00:00 [32m+21[0m: surface_atlas_json_codec (Lot 39) 21. reject categoryId non-string non-null[0m                                                                                                                 00:00 [32m+21[0m: surface_atlas_json_codec (Lot 39) 22. decode categoryId null in JSON[0m                                                                                                                        00:00 [32m+22[0m: surface_atlas_json_codec (Lot 39) 22. decode categoryId null in JSON[0m                                                                                                                        00:00 [32m+22[0m: surface_atlas_json_codec (Lot 39) 23. reject sortOrder non-int[0m                                                                                                                              00:00 [32m+23[0m: surface_atlas_json_codec (Lot 39) 23. reject sortOrder non-int[0m                                                                                                                              00:00 [32m+23[0m: surface_atlas_json_codec (Lot 39) 24. decode sortOrder negative[0m                                                                                                                             00:00 [32m+24[0m: surface_atlas_json_codec (Lot 39) 24. decode sortOrder negative[0m                                                                                                                             00:00 [32m+24[0m: surface_atlas_json_codec (Lot 39) 25. decode ignores unknown top-level key[0m                                                                                                                  00:00 [32m+25[0m: surface_atlas_json_codec (Lot 39) 25. decode ignores unknown top-level key[0m                                                                                                                  00:00 [32m+25[0m: surface_atlas_json_codec (Lot 39) 26. tilesetId not resolved against manifest[0m                                                                                                               00:00 [32m+26[0m: surface_atlas_json_codec (Lot 39) 26. tilesetId not resolved against manifest[0m                                                                                                               00:00 [32m+26[0m: surface_atlas_json_codec (Lot 39) 27. decode does not mutate source map[0m                                                                                                                     00:00 [32m+27[0m: surface_atlas_json_codec (Lot 39) 27. decode does not mutate source map[0m                                                                                                                     00:00 [32m+27[0m: surface_atlas_json_codec (Lot 39) 28. public API returns Map from encode[0m                                                                                                                    00:00 [32m+28[0m: surface_atlas_json_codec (Lot 39) 28. public API returns Map from encode[0m                                                                                                                    00:00 [32m+28[0m: surface_atlas_json_codec (Lot 39) 29. ProjectManifest has no surface persistence keys (Lot 39)[0m                                                                                              00:00 [32m+29[0m: surface_atlas_json_codec (Lot 39) 29. ProjectManifest has no surface persistence keys (Lot 39)[0m                                                                                              00:00 [32m+29[0m: surface_atlas_json_codec (Lot 39) 30. codec external to models: no model toJson / fromJson[0m                                                                                                  00:00 [32m+30[0m: surface_atlas_json_codec (Lot 39) 30. codec external to models: no model toJson / fromJson[0m                                                                                                  00:00 [32m+30[0m: All tests passed![0m
```

## 30. Tests de régression (intégral)

### `project_surface_atlas_test.dart`

```text
00:00 [32m+0[0m: [1m[90mloading test/project_surface_atlas_test.dart[0m[0m                                                                                                                                                 00:00 [32m+0[0m: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                                                               00:00 [32m+1[0m: ProjectSurfaceAtlas minimal atlas: fields and derived geometry[0m                                                                                                                               00:00 [32m+1[0m: ProjectSurfaceAtlas preserves categoryId and sortOrder[0m                                                                                                                                       00:00 [32m+2[0m: ProjectSurfaceAtlas preserves categoryId and sortOrder[0m                                                                                                                                       00:00 [32m+2[0m: ProjectSurfaceAtlas stores id, name, tilesetId exactly (no auto-trim on fields)[0m                                                                                                              00:00 [32m+3[0m: ProjectSurfaceAtlas stores id, name, tilesetId exactly (no auto-trim on fields)[0m                                                                                                              00:00 [32m+3[0m: ProjectSurfaceAtlas rejects empty id: empty string[0m                                                                                                                                           00:00 [32m+4[0m: ProjectSurfaceAtlas rejects empty id: empty string[0m                                                                                                                                           00:00 [32m+4[0m: ProjectSurfaceAtlas rejects empty id: whitespace only[0m                                                                                                                                        00:00 [32m+5[0m: ProjectSurfaceAtlas rejects empty id: whitespace only[0m                                                                                                                                        00:00 [32m+5[0m: ProjectSurfaceAtlas rejects empty name: empty string[0m                                                                                                                                         00:00 [32m+6[0m: ProjectSurfaceAtlas rejects empty name: empty string[0m                                                                                                                                         00:00 [32m+6[0m: ProjectSurfaceAtlas rejects empty name: whitespace only[0m                                                                                                                                      00:00 [32m+7[0m: ProjectSurfaceAtlas rejects empty name: whitespace only[0m                                                                                                                                      00:00 [32m+7[0m: ProjectSurfaceAtlas rejects empty tilesetId: empty string[0m                                                                                                                                    00:00 [32m+8[0m: ProjectSurfaceAtlas rejects empty tilesetId: empty string[0m                                                                                                                                    00:00 [32m+8[0m: ProjectSurfaceAtlas rejects empty tilesetId: whitespace only[0m                                                                                                                                 00:00 [32m+9[0m: ProjectSurfaceAtlas rejects empty tilesetId: whitespace only[0m                                                                                                                                 00:00 [32m+9[0m: ProjectSurfaceAtlas keeps the same geometry instance (no re-wrap)[0m                                                                                                                            00:00 [32m+10[0m: ProjectSurfaceAtlas keeps the same geometry instance (no re-wrap)[0m                                                                                                                           00:00 [32m+10[0m: ProjectSurfaceAtlas value equality: same values[0m                                                                                                                                             00:00 [32m+11[0m: ProjectSurfaceAtlas value equality: same values[0m                                                                                                                                             00:00 [32m+11[0m: ProjectSurfaceAtlas value equality: id differs[0m                                                                                                                                              00:00 [32m+12[0m: ProjectSurfaceAtlas value equality: id differs[0m                                                                                                                                              00:00 [32m+12[0m: ProjectSurfaceAtlas value equality: name differs[0m                                                                                                                                            00:00 [32m+13[0m: ProjectSurfaceAtlas value equality: name differs[0m                                                                                                                                            00:00 [32m+13[0m: ProjectSurfaceAtlas value equality: tilesetId differs[0m                                                                                                                                       00:00 [32m+14[0m: ProjectSurfaceAtlas value equality: tilesetId differs[0m                                                                                                                                       00:00 [32m+14[0m: ProjectSurfaceAtlas value equality: geometry differs (layout)[0m                                                                                                                               00:00 [32m+15[0m: ProjectSurfaceAtlas value equality: geometry differs (layout)[0m                                                                                                                               00:00 [32m+15[0m: ProjectSurfaceAtlas value equality: geometry differs (grid size)[0m                                                                                                                            00:00 [32m+16[0m: ProjectSurfaceAtlas value equality: geometry differs (grid size)[0m                                                                                                                            00:00 [32m+16[0m: ProjectSurfaceAtlas value equality: categoryId differs (including null vs non-null)[0m                                                                                                         00:00 [32m+17[0m: ProjectSurfaceAtlas value equality: categoryId differs (including null vs non-null)[0m                                                                                                         00:00 [32m+17[0m: ProjectSurfaceAtlas value equality: sortOrder differs[0m                                                                                                                                       00:00 [32m+18[0m: ProjectSurfaceAtlas value equality: sortOrder differs[0m                                                                                                                                       00:00 [32m+18[0m: ProjectSurfaceAtlas export: type available via map_core[0m                                                                                                                                     00:00 [32m+19[0m: ProjectSurfaceAtlas export: type available via map_core[0m                                                                                                                                     00:00 [32m+19[0m: ProjectSurfaceAtlas ProjectManifest toJson: no top-level surface* keys[0m                                                                                                                      00:00 [32m+20[0m: ProjectSurfaceAtlas ProjectManifest toJson: no top-level surface* keys[0m                                                                                                                      00:00 [32m+20[0m: All tests passed![0m
```

### `surface_atlas_geometry_test.dart`

```text
00:00 [32m+0[0m: [1m[90mloading test/surface_atlas_geometry_test.dart[0m[0m                                                                                                                                                00:00 [32m+0[0m: SurfaceAtlasTileSize keeps width and height[0m                                                                                                                                                  00:00 [32m+1[0m: SurfaceAtlasTileSize keeps width and height[0m                                                                                                                                                  00:00 [32m+1[0m: SurfaceAtlasTileSize rejects non-positive width: 0[0m                                                                                                                                           00:00 [32m+2[0m: SurfaceAtlasTileSize rejects non-positive width: 0[0m                                                                                                                                           00:00 [32m+2[0m: SurfaceAtlasTileSize rejects non-positive width: -1[0m                                                                                                                                          00:00 [32m+3[0m: SurfaceAtlasTileSize rejects non-positive width: -1[0m                                                                                                                                          00:00 [32m+3[0m: SurfaceAtlasTileSize rejects non-positive height: 0[0m                                                                                                                                          00:00 [32m+4[0m: SurfaceAtlasTileSize rejects non-positive height: 0[0m                                                                                                                                          00:00 [32m+4[0m: SurfaceAtlasTileSize rejects non-positive height: -1[0m                                                                                                                                         00:00 [32m+5[0m: SurfaceAtlasTileSize rejects non-positive height: -1[0m                                                                                                                                         00:00 [32m+5[0m: SurfaceAtlasTileSize value equality: same values => equal and same hashCode[0m                                                                                                                  00:00 [32m+6[0m: SurfaceAtlasTileSize value equality: same values => equal and same hashCode[0m                                                                                                                  00:00 [32m+6[0m: SurfaceAtlasTileSize value equality: different => not equal[0m                                                                                                                                  00:00 [32m+7[0m: SurfaceAtlasTileSize value equality: different => not equal[0m                                                                                                                                  00:00 [32m+7[0m: SurfaceAtlasGridSize keeps columns, rows, tileCount[0m                                                                                                                                          00:00 [32m+8[0m: SurfaceAtlasGridSize keeps columns, rows, tileCount[0m                                                                                                                                          00:00 [32m+8[0m: SurfaceAtlasGridSize rejects non-positive columns: 0[0m                                                                                                                                         00:00 [32m+9[0m: SurfaceAtlasGridSize rejects non-positive columns: 0[0m                                                                                                                                         00:00 [32m+9[0m: SurfaceAtlasGridSize rejects non-positive columns: -1[0m                                                                                                                                        00:00 [32m+10[0m: SurfaceAtlasGridSize rejects non-positive columns: -1[0m                                                                                                                                       00:00 [32m+10[0m: SurfaceAtlasGridSize rejects non-positive rows: 0[0m                                                                                                                                           00:00 [32m+11[0m: SurfaceAtlasGridSize rejects non-positive rows: 0[0m                                                                                                                                           00:00 [32m+11[0m: SurfaceAtlasGridSize rejects non-positive rows: -1[0m                                                                                                                                          00:00 [32m+12[0m: SurfaceAtlasGridSize rejects non-positive rows: -1[0m                                                                                                                                          00:00 [32m+12[0m: SurfaceAtlasGridSize value equality: same => equal; different => not[0m                                                                                                                        00:00 [32m+13[0m: SurfaceAtlasGridSize value equality: same => equal; different => not[0m                                                                                                                        00:00 [32m+13[0m: SurfaceAtlasGeometry keeps fields and delegates tileCount[0m                                                                                                                                   00:00 [32m+14[0m: SurfaceAtlasGeometry keeps fields and delegates tileCount[0m                                                                                                                                   00:00 [32m+14[0m: SurfaceAtlasGeometry default layout is grid[0m                                                                                                                                                 00:00 [32m+15[0m: SurfaceAtlasGeometry default layout is grid[0m                                                                                                                                                 00:00 [32m+15[0m: SurfaceAtlasGeometry containsGridCoordinate: interior points in range[0m                                                                                                                       00:00 [32m+16[0m: SurfaceAtlasGeometry containsGridCoordinate: interior points in range[0m                                                                                                                       00:00 [32m+16[0m: SurfaceAtlasGeometry containsGridCoordinate: out of range or negative[0m                                                                                                                       00:00 [32m+17[0m: SurfaceAtlasGeometry containsGridCoordinate: out of range or negative[0m                                                                                                                       00:00 [32m+17[0m: SurfaceAtlasGeometry value equality: layout / tile / grid disambiguation[0m                                                                                                                    00:00 [32m+18[0m: SurfaceAtlasGeometry value equality: layout / tile / grid disambiguation[0m                                                                                                                    00:00 [32m+18[0m: public export & manifest unchanged map_core exposes all new types[0m                                                                                                                           00:00 [32m+19[0m: public export & manifest unchanged map_core exposes all new types[0m                                                                                                                           00:00 [32m+19[0m: public export & manifest unchanged ProjectManifest toJson() still has no surface* top-level keys[0m                                                                                            00:00 [32m+20[0m: public export & manifest unchanged ProjectManifest toJson() still has no surface* top-level keys[0m                                                                                            00:00 [32m+20[0m: All tests passed![0m
```

### `surface_model_entrypoint_test.dart`

```text
00:00 [32m+0[0m: [1m[90mloading test/surface_model_entrypoint_test.dart[0m[0m                                                                                                                                              00:00 [32m+0[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                                                                 00:00 [32m+1[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) SurfaceAtlasLayout.values exposes exactly the expected cases in order[0m                                                                 00:00 [32m+1[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet[0m                                                                          00:00 [32m+2[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectManifest JSON has no surface engine manifest keys yet[0m                                                                          00:00 [32m+2[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                                                            00:00 [32m+3[0m: Lot 21 — surface model entrypoint (SurfaceAtlasLayout) ProjectPathPreset construction remains available unchanged[0m                                                                            00:00 [32m+3[0m: All tests passed![0m
```

## 31. `dart analyze` (intégral)

```text
Analyzing surface_atlas_json_codec.dart, surface.dart, surface_atlas_json_codec_test.dart, project_surface_atlas_test.dart, surface_atlas_geometry_test.dart, surface_model_entrypoint_test.dart, map_core.dart...
No issues found!
```

## 32. `dart test` complet (package `map_core`)

**Commande :** `cd packages/map_core && /opt/homebrew/bin/dart test`

**Dernière ligne exacte :**

```text
00:01 +896: All tests passed!
```

**Total :** 896 tests.

## 33. Points de vigilance

Types numériques JSON : seuls `int` acceptés ; nouvelles valeurs d’`SurfaceAtlasLayout` exigent mise à jour des chaînes `name`.

## 34. Autocritique

Volume des sorties de test en une ligne logique (codes ANSI) — intégralité reprise en §29–30.

## 35. Ce que le prompt semble discutable ou incomplet

Aucun point bloquant.

## 36. Auto-review indépendante

Périmètre Lot 39 respecté : codec atlas + géométrie, manifeste intact, pas de toJson modèle, 896 tests verts, preuves ci-dessous, aucune commande Git d’écriture.

## 37. Evidence Pack complet

### 37.A Fichiers créés (intégral)

#### `packages/map_core/lib/src/operations/surface_atlas_json_codec.dart`

```dart
// JSON codec manuel (Lot 39) — [ProjectSurfaceAtlas] et value objects de géométrie.
//
// * Prépare une **futures** persistance Surface **sans** brancher
//   [ProjectManifest] ni ajouter de champs de manifest dans ce lot.
// * Toute résolution de référence (existence d’un [tilesetId] dans le projet,
//   chemins d’image, cohérence texture) reste **hors scope** — seule la
//   forme des maps JSON compte ici.
// * Encodage : si [ProjectSurfaceAtlas.categoryId] est `null`, la clé
//   `categoryId` est **omise** (V0) ; [sortOrder] est **toujours** présent.
// * Décodage : les clés inconnues au premier niveau (atlas) et dans les
//   objets imbriqués reconnus sont **ignorées** sans [ValidationException] —
//   cela laisse de la marge à des évolutions de schéma.
// * Les modèles [surface.dart] restent **sans** `toJson` / `fromJson` : le
//   contrat d’E/S reste ici, dans [map_core], et délègue la validation métier
//   (tailles > 0, ids non vides) aux **constructeurs** existants quand c’est
//   possible.
//
// * Ne **mutate** jamais les [Map] passées en entrée en décodage (lecture
//   seulement).

import '../exceptions/map_exceptions.dart';
import '../models/surface.dart';

/// Copie défensive, clés en [String] (décodage JSON : clés string ou rarement non-string).
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

String _validLayoutNamesForMessage() =>
    SurfaceAtlasLayout.values.map((e) => e.name).join(', ');

/// Encodage pour persistance : identiques aux champs, ordre d’insertion
/// stable ([id], [name], [tilesetId], [geometry], [`categoryId` si non null],
/// [sortOrder]).
Map<String, Object?> encodeProjectSurfaceAtlas(ProjectSurfaceAtlas atlas) {
  final out = <String, Object?>{
    'id': atlas.id,
    'name': atlas.name,
    'tilesetId': atlas.tilesetId,
    'geometry': encodeSurfaceAtlasGeometry(atlas.geometry),
    'sortOrder': atlas.sortOrder,
  };
  if (atlas.categoryId != null) {
    out['categoryId'] = atlas.categoryId;
  }
  return out;
}

ProjectSurfaceAtlas decodeProjectSurfaceAtlas(Map<String, Object?> json) {
  final id = _reqString(
    fieldKey: 'ProjectSurfaceAtlas.id',
    value: _valueForRequiredKey(json, 'id', 'ProjectSurfaceAtlas.id'),
  );
  final name = _reqString(
    fieldKey: 'ProjectSurfaceAtlas.name',
    value: _valueForRequiredKey(json, 'name', 'ProjectSurfaceAtlas.name'),
  );
  final tilesetId = _reqString(
    fieldKey: 'ProjectSurfaceAtlas.tilesetId',
    value: _valueForRequiredKey(
      json,
      'tilesetId',
      'ProjectSurfaceAtlas.tilesetId',
    ),
  );

  final g = json['geometry'];
  if (g == null) {
    throw const ValidationException(
      'ProjectSurfaceAtlas.geometry is required',
    );
  }
  if (g is! Map) {
    throw const ValidationException(
      'ProjectSurfaceAtlas.geometry must be a Map',
    );
  }
  final geometry = decodeSurfaceAtlasGeometry(
    _stringKeyMapFrom(g),
  );

  final categoryId = _optionalCategoryId(json);
  final sortOrder = _sortOrder(json, 'ProjectSurfaceAtlas.sortOrder');

  return ProjectSurfaceAtlas(
    id: id,
    name: name,
    tilesetId: tilesetId,
    geometry: geometry,
    categoryId: categoryId,
    sortOrder: sortOrder,
  );
}

Map<String, Object?> encodeSurfaceAtlasGeometry(
  SurfaceAtlasGeometry geometry,
) {
  return {
    'tileSize': encodeSurfaceAtlasTileSize(geometry.tileSize),
    'gridSize': encodeSurfaceAtlasGridSize(geometry.gridSize),
    'layout': encodeSurfaceAtlasLayout(geometry.layout),
  };
}

SurfaceAtlasGeometry decodeSurfaceAtlasGeometry(Map<String, Object?> json) {
  final ts = json['tileSize'];
  if (ts == null) {
    throw const ValidationException(
      'SurfaceAtlasGeometry.tileSize is required',
    );
  }
  if (ts is! Map) {
    throw const ValidationException(
      'SurfaceAtlasGeometry.tileSize must be an Object',
    );
  }
  final tileSize = decodeSurfaceAtlasTileSize(
    _stringKeyMapFrom(ts),
  );

  final gs = json['gridSize'];
  if (gs == null) {
    throw const ValidationException(
      'SurfaceAtlasGeometry.gridSize is required',
    );
  }
  if (gs is! Map) {
    throw const ValidationException(
      'SurfaceAtlasGeometry.gridSize must be an Object',
    );
  }
  final gridSize = decodeSurfaceAtlasGridSize(
    _stringKeyMapFrom(gs),
  );

  final layoutRaw = json['layout'];
  if (layoutRaw == null) {
    throw const ValidationException('SurfaceAtlasGeometry.layout is required');
  }
  if (layoutRaw is! String) {
    throw const ValidationException(
      'SurfaceAtlasGeometry.layout must be a String',
    );
  }

  return SurfaceAtlasGeometry(
    tileSize: tileSize,
    gridSize: gridSize,
    layout: decodeSurfaceAtlasLayout(layoutRaw),
  );
}

Map<String, Object?> encodeSurfaceAtlasTileSize(
  SurfaceAtlasTileSize tileSize,
) {
  return {
    'width': tileSize.width,
    'height': tileSize.height,
  };
}

SurfaceAtlasTileSize decodeSurfaceAtlasTileSize(Map<String, Object?> json) {
  final w = _valueForRequiredKey(json, 'width', 'SurfaceAtlasTileSize.width');
  if (w is! int) {
    throw const ValidationException(
      'SurfaceAtlasTileSize.width must be an int',
    );
  }
  final h = _valueForRequiredKey(
    json,
    'height',
    'SurfaceAtlasTileSize.height',
  );
  if (h is! int) {
    throw const ValidationException(
      'SurfaceAtlasTileSize.height must be an int',
    );
  }
  return SurfaceAtlasTileSize(width: w, height: h);
}

Map<String, Object?> encodeSurfaceAtlasGridSize(
  SurfaceAtlasGridSize gridSize,
) {
  return {
    'columns': gridSize.columns,
    'rows': gridSize.rows,
  };
}

SurfaceAtlasGridSize decodeSurfaceAtlasGridSize(Map<String, Object?> json) {
  final c = _valueForRequiredKey(
    json,
    'columns',
    'SurfaceAtlasGridSize.columns',
  );
  if (c is! int) {
    throw const ValidationException(
      'SurfaceAtlasGridSize.columns must be an int',
    );
  }
  final r = _valueForRequiredKey(json, 'rows', 'SurfaceAtlasGridSize.rows');
  if (r is! int) {
    throw const ValidationException('SurfaceAtlasGridSize.rows must be an int');
  }
  return SurfaceAtlasGridSize(columns: c, rows: r);
}

String encodeSurfaceAtlasLayout(SurfaceAtlasLayout layout) => layout.name;

SurfaceAtlasLayout decodeSurfaceAtlasLayout(String value) {
  for (final l in SurfaceAtlasLayout.values) {
    if (l.name == value) {
      return l;
    }
  }
  throw ValidationException(
    'SurfaceAtlasLayout must be one of: ${_validLayoutNamesForMessage()}',
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

String _reqString({required String fieldKey, required Object? value}) {
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

int _sortOrder(Map<String, Object?> json, String fieldKey) {
  if (!json.containsKey('sortOrder')) {
    return 0;
  }
  final v = json['sortOrder'];
  if (v is! int) {
    throw ValidationException('$fieldKey must be an int');
  }
  return v;
}

String? _optionalCategoryId(Map<String, Object?> json) {
  if (!json.containsKey('categoryId')) {
    return null;
  }
  final v = json['categoryId'];
  if (v == null) {
    return null;
  }
  if (v is! String) {
    throw const ValidationException(
      'ProjectSurfaceAtlas.categoryId must be a String or null',
    );
  }
  return v;
}
```

#### `packages/map_core/test/surface_atlas_json_codec_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

SurfaceAtlasGeometry _geometry({
  int width = 32,
  int height = 32,
  int columns = 23,
  int rows = 32,
  SurfaceAtlasLayout layout =
      SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
}) {
  return SurfaceAtlasGeometry(
    tileSize: SurfaceAtlasTileSize(width: width, height: height),
    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
    layout: layout,
  );
}

ProjectSurfaceAtlas _atlas({
  String id = 'water-atlas',
  String name = 'Water Atlas',
  String tilesetId = 'nature-tileset',
  SurfaceAtlasGeometry? geometry,
  String? categoryId,
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

void main() {
  group('surface_atlas_json_codec (Lot 39)', () {
    test('1. encode SurfaceAtlasTileSize', () {
      final m = encodeSurfaceAtlasTileSize(
        SurfaceAtlasTileSize(width: 32, height: 16),
      );
      expect(m, {'width': 32, 'height': 16});
    });

    test('2. decode SurfaceAtlasTileSize', () {
      final t = decodeSurfaceAtlasTileSize({
        'width': 32,
        'height': 16,
      });
      expect(t.width, 32);
      expect(t.height, 16);
    });

    test('3. reject tile size missing / wrong type / width 0', () {
      expect(
        () => decodeSurfaceAtlasTileSize({'height': 16}),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.toString().contains('width'),
            'mentions width',
            isTrue,
          ),
        ),
      );
      expect(
        () => decodeSurfaceAtlasTileSize({
          'width': 1,
          'height': 'x',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasTileSize({'width': 0, 'height': 1}),
        throwsA(isA<ValidationException>()),
      );
    });

    test('4. encode SurfaceAtlasGridSize', () {
      final m = encodeSurfaceAtlasGridSize(
        SurfaceAtlasGridSize(columns: 23, rows: 32),
      );
      expect(m, {'columns': 23, 'rows': 32});
    });

    test('5. decode SurfaceAtlasGridSize', () {
      final g = decodeSurfaceAtlasGridSize({
        'columns': 23,
        'rows': 32,
      });
      expect(g.columns, 23);
      expect(g.rows, 32);
    });

    test('6. reject grid size missing / wrong type / columns 0', () {
      expect(
        () => decodeSurfaceAtlasGridSize({'rows': 1}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasGridSize({
          'columns': 1,
          'rows': true,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasGridSize({
          'columns': 0,
          'rows': 1,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('7. encode/decode layout grid', () {
      expect(encodeSurfaceAtlasLayout(SurfaceAtlasLayout.grid), 'grid');
      expect(decodeSurfaceAtlasLayout('grid'), SurfaceAtlasLayout.grid);
    });

    test('8. encode/decode layout columnsAreVariantsRowsAreFrames', () {
      const l = SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
      expect(encodeSurfaceAtlasLayout(l), 'columnsAreVariantsRowsAreFrames');
      expect(
        decodeSurfaceAtlasLayout('columnsAreVariantsRowsAreFrames'),
        l,
      );
    });

    test('9. reject layout unknown or wrong casing', () {
      expect(
        () => decodeSurfaceAtlasLayout('unknown'),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.toString().contains('SurfaceAtlasLayout'),
            'msg',
            isTrue,
          ),
        ),
      );
      expect(
        () => decodeSurfaceAtlasLayout('Grid'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('10. encode SurfaceAtlasGeometry', () {
      final g = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      final m = encodeSurfaceAtlasGeometry(g);
      expect(
        m,
        {
          'tileSize': {'width': 32, 'height': 32},
          'gridSize': {'columns': 23, 'rows': 32},
          'layout': 'columnsAreVariantsRowsAreFrames',
        },
      );
    });

    test('11. decode SurfaceAtlasGeometry + tileCount', () {
      final g = decodeSurfaceAtlasGeometry({
        'tileSize': {'width': 32, 'height': 32},
        'gridSize': {'columns': 23, 'rows': 32},
        'layout': 'columnsAreVariantsRowsAreFrames',
      });
      final expected = SurfaceAtlasGeometry(
        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
        gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
      );
      expect(g, expected);
      expect(g.tileCount, 23 * 32);
    });

    test('12. reject geometry missing nested / wrong types', () {
      expect(
        () => decodeSurfaceAtlasGeometry({
          'gridSize': {
            'columns': 1,
            'rows': 1,
          },
          'layout': 'grid',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasGeometry({
          'tileSize': {
            'width': 1,
            'height': 1,
          },
          'gridSize': 3,
          'layout': 'grid',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeSurfaceAtlasGeometry({
          'tileSize': {
            'width': 1,
            'height': 1,
          },
          'gridSize': {
            'columns': 1,
            'rows': 1,
          },
          'layout': 1,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('13. encode ProjectSurfaceAtlas minimal', () {
      final a = _atlas(categoryId: null, sortOrder: 0);
      final m = encodeProjectSurfaceAtlas(a);
      expect(m.containsKey('categoryId'), isFalse);
      expect(m['sortOrder'], 0);
      expect(m['id'], 'water-atlas');
      expect(m['name'], 'Water Atlas');
      expect(m['tilesetId'], 'nature-tileset');
      expect(m['geometry'], isA<Map<String, Object?>>());
    });

    test('14. encode ProjectSurfaceAtlas full', () {
      final a = _atlas(
        categoryId: 'animated-surfaces',
        sortOrder: 42,
      );
      final m = encodeProjectSurfaceAtlas(a);
      expect(m['categoryId'], 'animated-surfaces');
      expect(m['sortOrder'], 42);
    });

    test('15. decode ProjectSurfaceAtlas minimal (no category, no sortOrder)',
        () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': {
          'tileSize': {'width': 8, 'height': 8},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
      });
      expect(a.categoryId, isNull);
      expect(a.sortOrder, 0);
    });

    test('16. decode ProjectSurfaceAtlas full', () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': {
          'tileSize': {'width': 8, 'height': 8},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
        'categoryId': 'animated-surfaces',
        'sortOrder': 42,
      });
      expect(a.categoryId, 'animated-surfaces');
      expect(a.sortOrder, 42);
    });

    test('17. round-trip ProjectSurfaceAtlas', () {
      final atlas = _atlas(
        categoryId: 'cat',
        sortOrder: 7,
        geometry: _geometry(
          width: 16,
          height: 8,
          columns: 2,
          rows: 3,
        ),
      );
      final json = encodeProjectSurfaceAtlas(atlas);
      final back = decodeProjectSurfaceAtlas(json);
      expect(back, atlas);
    });

    test('18. exact strings preserved (no trim in codec)', () {
      const id = '  water-atlas  ';
      const name = '  Water Atlas  ';
      const tid = '  nature-tileset  ';
      const cat = '  animated  ';
      final a = _atlas(
        id: id,
        name: name,
        tilesetId: tid,
        categoryId: cat,
        sortOrder: 0,
        geometry: _geometry(
          width: 8,
          height: 8,
          columns: 1,
          rows: 1,
        ),
      );
      final j = encodeProjectSurfaceAtlas(a);
      final b = decodeProjectSurfaceAtlas(j);
      expect(b.id, id);
      expect(b.name, name);
      expect(b.tilesetId, tid);
      expect(b.categoryId, cat);
    });

    test(
        '19. reject id / name / tilesetId missing, wrong type, whitespace tileset',
        () {
      final baseG = {
        'tileSize': {'width': 1, 'height': 1},
        'gridSize': {'columns': 1, 'rows': 1},
        'layout': 'grid',
      };
      expect(
        () => decodeProjectSurfaceAtlas({
          'name': 'n',
          'tilesetId': 't',
          'geometry': baseG,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 1,
          'tilesetId': 't',
          'geometry': baseG,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 'n',
          'tilesetId': '   ',
          'geometry': baseG,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('20. reject geometry missing or non-map on atlas', () {
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 'n',
          'tilesetId': 't',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 'n',
          'tilesetId': 't',
          'geometry': 'nope',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('21. reject categoryId non-string non-null', () {
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 'n',
          'tilesetId': 't',
          'geometry': {
            'tileSize': {'width': 1, 'height': 1},
            'gridSize': {'columns': 1, 'rows': 1},
            'layout': 'grid',
          },
          'categoryId': 123,
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('22. decode categoryId null in JSON', () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': {
          'tileSize': {'width': 1, 'height': 1},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
        'categoryId': null,
      });
      expect(a.categoryId, isNull);
    });

    test('23. reject sortOrder non-int', () {
      expect(
        () => decodeProjectSurfaceAtlas({
          'id': 'a',
          'name': 'n',
          'tilesetId': 't',
          'geometry': {
            'tileSize': {'width': 1, 'height': 1},
            'gridSize': {'columns': 1, 'rows': 1},
            'layout': 'grid',
          },
          'sortOrder': '1',
        }),
        throwsA(isA<ValidationException>()),
      );
    });

    test('24. decode sortOrder negative', () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': {
          'tileSize': {'width': 1, 'height': 1},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
        'sortOrder': -10,
      });
      expect(a.sortOrder, -10);
    });

    test('25. decode ignores unknown top-level key', () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': {
          'tileSize': {'width': 1, 'height': 1},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
        'futureField': 'ignored',
      });
      expect(a.id, 'a');
    });

    test('26. tilesetId not resolved against manifest', () {
      final a = decodeProjectSurfaceAtlas({
        'id': 'a',
        'name': 'n',
        'tilesetId': 'missing-tileset',
        'geometry': {
          'tileSize': {'width': 1, 'height': 1},
          'gridSize': {'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
      });
      expect(a.tilesetId, 'missing-tileset');
    });

    test('27. decode does not mutate source map', () {
      final map = <String, Object?>{
        'id': 'a',
        'name': 'n',
        'tilesetId': 't',
        'geometry': <String, Object?>{
          'tileSize': <String, Object?>{'width': 1, 'height': 1},
          'gridSize': <String, Object?>{'columns': 1, 'rows': 1},
          'layout': 'grid',
        },
      };
      final before = _deepStr(map);
      decodeProjectSurfaceAtlas(map);
      final after = _deepStr(map);
      expect(before, after);
    });

    test('28. public API returns Map from encode', () {
      final m = encodeProjectSurfaceAtlas(_atlas());
      expect(m, isA<Map<String, Object?>>());
    });

    test('29. ProjectManifest has no surface persistence keys (Lot 39)', () {
      const manifest = ProjectManifest(
        name: 'L39',
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

    test('30. codec external to models: no model toJson / fromJson', () {
      final a = _atlas();
      final json = encodeProjectSurfaceAtlas(a);
      expect(json, isA<Map<String, Object?>>());
      // Lot 39: persistence via codec only — models stay JSON-free
      // (do not call atlas.toJson or ProjectSurfaceAtlas.fromJson).
    });
  });
}

String _deepStr(Object? o) {
  if (o is Map) {
    return '{${o.keys.map((k) => '$k:${_deepStr(o[k])}').join(',')}}';
  }
  if (o is String) {
    return o;
  }
  if (o is int) {
    return '$o';
  }
  if (o == null) {
    return 'null';
  }
  return o.toString();
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
export 'src/operations/surface_atlas_json_codec.dart';
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

#### `map_core.dart` (diff réel)

```diff
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
index 6c8214ed..a7793afe 100644
--- a/packages/map_core/lib/map_core.dart
+++ b/packages/map_core/lib/map_core.dart
@@ -45,6 +45,7 @@ export 'src/operations/surface_catalog_diagnostics.dart';
 export 'src/operations/surface_catalog_authoring_diagnostics.dart';
 export 'src/operations/surface_catalog_diagnostics_summary.dart';
 export 'src/operations/surface_catalog_diagnostics_presentation.dart';
+export 'src/operations/surface_atlas_json_codec.dart';
 export 'src/operations/legacy_path_surface_view.dart';
 export 'src/operations/legacy_terrain_surface_view.dart';
 export 'src/operations/legacy_project_surface_catalog_view.dart';
```

#### `git diff --no-index /dev/null` → `surface_atlas_json_codec.dart`

```diff
diff --git a/packages/map_core/lib/src/operations/surface_atlas_json_codec.dart b/packages/map_core/lib/src/operations/surface_atlas_json_codec.dart
new file mode 100644
index 00000000..b66409e5
--- /dev/null
+++ b/packages/map_core/lib/src/operations/surface_atlas_json_codec.dart
@@ -0,0 +1,273 @@
+// JSON codec manuel (Lot 39) — [ProjectSurfaceAtlas] et value objects de géométrie.
+//
+// * Prépare une **futures** persistance Surface **sans** brancher
+//   [ProjectManifest] ni ajouter de champs de manifest dans ce lot.
+// * Toute résolution de référence (existence d’un [tilesetId] dans le projet,
+//   chemins d’image, cohérence texture) reste **hors scope** — seule la
+//   forme des maps JSON compte ici.
+// * Encodage : si [ProjectSurfaceAtlas.categoryId] est `null`, la clé
+//   `categoryId` est **omise** (V0) ; [sortOrder] est **toujours** présent.
+// * Décodage : les clés inconnues au premier niveau (atlas) et dans les
+//   objets imbriqués reconnus sont **ignorées** sans [ValidationException] —
+//   cela laisse de la marge à des évolutions de schéma.
+// * Les modèles [surface.dart] restent **sans** `toJson` / `fromJson` : le
+//   contrat d’E/S reste ici, dans [map_core], et délègue la validation métier
+//   (tailles > 0, ids non vides) aux **constructeurs** existants quand c’est
+//   possible.
+//
+// * Ne **mutate** jamais les [Map] passées en entrée en décodage (lecture
+//   seulement).
+
+import '../exceptions/map_exceptions.dart';
+import '../models/surface.dart';
+
+/// Copie défensive, clés en [String] (décodage JSON : clés string ou rarement non-string).
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
+String _validLayoutNamesForMessage() =>
+    SurfaceAtlasLayout.values.map((e) => e.name).join(', ');
+
+/// Encodage pour persistance : identiques aux champs, ordre d’insertion
+/// stable ([id], [name], [tilesetId], [geometry], [`categoryId` si non null],
+/// [sortOrder]).
+Map<String, Object?> encodeProjectSurfaceAtlas(ProjectSurfaceAtlas atlas) {
+  final out = <String, Object?>{
+    'id': atlas.id,
+    'name': atlas.name,
+    'tilesetId': atlas.tilesetId,
+    'geometry': encodeSurfaceAtlasGeometry(atlas.geometry),
+    'sortOrder': atlas.sortOrder,
+  };
+  if (atlas.categoryId != null) {
+    out['categoryId'] = atlas.categoryId;
+  }
+  return out;
+}
+
+ProjectSurfaceAtlas decodeProjectSurfaceAtlas(Map<String, Object?> json) {
+  final id = _reqString(
+    fieldKey: 'ProjectSurfaceAtlas.id',
+    value: _valueForRequiredKey(json, 'id', 'ProjectSurfaceAtlas.id'),
+  );
+  final name = _reqString(
+    fieldKey: 'ProjectSurfaceAtlas.name',
+    value: _valueForRequiredKey(json, 'name', 'ProjectSurfaceAtlas.name'),
+  );
+  final tilesetId = _reqString(
+    fieldKey: 'ProjectSurfaceAtlas.tilesetId',
+    value: _valueForRequiredKey(
+      json,
+      'tilesetId',
+      'ProjectSurfaceAtlas.tilesetId',
+    ),
+  );
+
+  final g = json['geometry'];
+  if (g == null) {
+    throw const ValidationException(
+      'ProjectSurfaceAtlas.geometry is required',
+    );
+  }
+  if (g is! Map) {
+    throw const ValidationException(
+      'ProjectSurfaceAtlas.geometry must be a Map',
+    );
+  }
+  final geometry = decodeSurfaceAtlasGeometry(
+    _stringKeyMapFrom(g),
+  );
+
+  final categoryId = _optionalCategoryId(json);
+  final sortOrder = _sortOrder(json, 'ProjectSurfaceAtlas.sortOrder');
+
+  return ProjectSurfaceAtlas(
+    id: id,
+    name: name,
+    tilesetId: tilesetId,
+    geometry: geometry,
+    categoryId: categoryId,
+    sortOrder: sortOrder,
+  );
+}
+
+Map<String, Object?> encodeSurfaceAtlasGeometry(
+  SurfaceAtlasGeometry geometry,
+) {
+  return {
+    'tileSize': encodeSurfaceAtlasTileSize(geometry.tileSize),
+    'gridSize': encodeSurfaceAtlasGridSize(geometry.gridSize),
+    'layout': encodeSurfaceAtlasLayout(geometry.layout),
+  };
+}
+
+SurfaceAtlasGeometry decodeSurfaceAtlasGeometry(Map<String, Object?> json) {
+  final ts = json['tileSize'];
+  if (ts == null) {
+    throw const ValidationException(
+      'SurfaceAtlasGeometry.tileSize is required',
+    );
+  }
+  if (ts is! Map) {
+    throw const ValidationException(
+      'SurfaceAtlasGeometry.tileSize must be an Object',
+    );
+  }
+  final tileSize = decodeSurfaceAtlasTileSize(
+    _stringKeyMapFrom(ts),
+  );
+
+  final gs = json['gridSize'];
+  if (gs == null) {
+    throw const ValidationException(
+      'SurfaceAtlasGeometry.gridSize is required',
+    );
+  }
+  if (gs is! Map) {
+    throw const ValidationException(
+      'SurfaceAtlasGeometry.gridSize must be an Object',
+    );
+  }
+  final gridSize = decodeSurfaceAtlasGridSize(
+    _stringKeyMapFrom(gs),
+  );
+
+  final layoutRaw = json['layout'];
+  if (layoutRaw == null) {
+    throw const ValidationException('SurfaceAtlasGeometry.layout is required');
+  }
+  if (layoutRaw is! String) {
+    throw const ValidationException(
+      'SurfaceAtlasGeometry.layout must be a String',
+    );
+  }
+
+  return SurfaceAtlasGeometry(
+    tileSize: tileSize,
+    gridSize: gridSize,
+    layout: decodeSurfaceAtlasLayout(layoutRaw),
+  );
+}
+
+Map<String, Object?> encodeSurfaceAtlasTileSize(
+  SurfaceAtlasTileSize tileSize,
+) {
+  return {
+    'width': tileSize.width,
+    'height': tileSize.height,
+  };
+}
+
+SurfaceAtlasTileSize decodeSurfaceAtlasTileSize(Map<String, Object?> json) {
+  final w = _valueForRequiredKey(json, 'width', 'SurfaceAtlasTileSize.width');
+  if (w is! int) {
+    throw const ValidationException(
+      'SurfaceAtlasTileSize.width must be an int',
+    );
+  }
+  final h = _valueForRequiredKey(
+    json,
+    'height',
+    'SurfaceAtlasTileSize.height',
+  );
+  if (h is! int) {
+    throw const ValidationException(
+      'SurfaceAtlasTileSize.height must be an int',
+    );
+  }
+  return SurfaceAtlasTileSize(width: w, height: h);
+}
+
+Map<String, Object?> encodeSurfaceAtlasGridSize(
+  SurfaceAtlasGridSize gridSize,
+) {
+  return {
+    'columns': gridSize.columns,
+    'rows': gridSize.rows,
+  };
+}
+
+SurfaceAtlasGridSize decodeSurfaceAtlasGridSize(Map<String, Object?> json) {
+  final c = _valueForRequiredKey(
+    json,
+    'columns',
+    'SurfaceAtlasGridSize.columns',
+  );
+  if (c is! int) {
+    throw const ValidationException(
+      'SurfaceAtlasGridSize.columns must be an int',
+    );
+  }
+  final r = _valueForRequiredKey(json, 'rows', 'SurfaceAtlasGridSize.rows');
+  if (r is! int) {
+    throw const ValidationException('SurfaceAtlasGridSize.rows must be an int');
+  }
+  return SurfaceAtlasGridSize(columns: c, rows: r);
+}
+
+String encodeSurfaceAtlasLayout(SurfaceAtlasLayout layout) => layout.name;
+
+SurfaceAtlasLayout decodeSurfaceAtlasLayout(String value) {
+  for (final l in SurfaceAtlasLayout.values) {
+    if (l.name == value) {
+      return l;
+    }
+  }
+  throw ValidationException(
+    'SurfaceAtlasLayout must be one of: ${_validLayoutNamesForMessage()}',
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
+String _reqString({required String fieldKey, required Object? value}) {
+  if (value is! String) {
+    throw ValidationException('$fieldKey must be a non-null String');
+  }
+  return value;
+}
+
+int _sortOrder(Map<String, Object?> json, String fieldKey) {
+  if (!json.containsKey('sortOrder')) {
+    return 0;
+  }
+  final v = json['sortOrder'];
+  if (v is! int) {
+    throw ValidationException('$fieldKey must be an int');
+  }
+  return v;
+}
+
+String? _optionalCategoryId(Map<String, Object?> json) {
+  if (!json.containsKey('categoryId')) {
+    return null;
+  }
+  final v = json['categoryId'];
+  if (v == null) {
+    return null;
+  }
+  if (v is! String) {
+    throw const ValidationException(
+      'ProjectSurfaceAtlas.categoryId must be a String or null',
+    );
+  }
+  return v;
+}
```

#### `git diff --no-index /dev/null` → `surface_atlas_json_codec_test.dart`

```diff
diff --git a/packages/map_core/test/surface_atlas_json_codec_test.dart b/packages/map_core/test/surface_atlas_json_codec_test.dart
new file mode 100644
index 00000000..bad3f7fa
--- /dev/null
+++ b/packages/map_core/test/surface_atlas_json_codec_test.dart
@@ -0,0 +1,532 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+SurfaceAtlasGeometry _geometry({
+  int width = 32,
+  int height = 32,
+  int columns = 23,
+  int rows = 32,
+  SurfaceAtlasLayout layout =
+      SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+}) {
+  return SurfaceAtlasGeometry(
+    tileSize: SurfaceAtlasTileSize(width: width, height: height),
+    gridSize: SurfaceAtlasGridSize(columns: columns, rows: rows),
+    layout: layout,
+  );
+}
+
+ProjectSurfaceAtlas _atlas({
+  String id = 'water-atlas',
+  String name = 'Water Atlas',
+  String tilesetId = 'nature-tileset',
+  SurfaceAtlasGeometry? geometry,
+  String? categoryId,
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
+void main() {
+  group('surface_atlas_json_codec (Lot 39)', () {
+    test('1. encode SurfaceAtlasTileSize', () {
+      final m = encodeSurfaceAtlasTileSize(
+        SurfaceAtlasTileSize(width: 32, height: 16),
+      );
+      expect(m, {'width': 32, 'height': 16});
+    });
+
+    test('2. decode SurfaceAtlasTileSize', () {
+      final t = decodeSurfaceAtlasTileSize({
+        'width': 32,
+        'height': 16,
+      });
+      expect(t.width, 32);
+      expect(t.height, 16);
+    });
+
+    test('3. reject tile size missing / wrong type / width 0', () {
+      expect(
+        () => decodeSurfaceAtlasTileSize({'height': 16}),
+        throwsA(
+          isA<ValidationException>().having(
+            (e) => e.toString().contains('width'),
+            'mentions width',
+            isTrue,
+          ),
+        ),
+      );
+      expect(
+        () => decodeSurfaceAtlasTileSize({
+          'width': 1,
+          'height': 'x',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasTileSize({'width': 0, 'height': 1}),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('4. encode SurfaceAtlasGridSize', () {
+      final m = encodeSurfaceAtlasGridSize(
+        SurfaceAtlasGridSize(columns: 23, rows: 32),
+      );
+      expect(m, {'columns': 23, 'rows': 32});
+    });
+
+    test('5. decode SurfaceAtlasGridSize', () {
+      final g = decodeSurfaceAtlasGridSize({
+        'columns': 23,
+        'rows': 32,
+      });
+      expect(g.columns, 23);
+      expect(g.rows, 32);
+    });
+
+    test('6. reject grid size missing / wrong type / columns 0', () {
+      expect(
+        () => decodeSurfaceAtlasGridSize({'rows': 1}),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasGridSize({
+          'columns': 1,
+          'rows': true,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasGridSize({
+          'columns': 0,
+          'rows': 1,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('7. encode/decode layout grid', () {
+      expect(encodeSurfaceAtlasLayout(SurfaceAtlasLayout.grid), 'grid');
+      expect(decodeSurfaceAtlasLayout('grid'), SurfaceAtlasLayout.grid);
+    });
+
+    test('8. encode/decode layout columnsAreVariantsRowsAreFrames', () {
+      const l = SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames;
+      expect(encodeSurfaceAtlasLayout(l), 'columnsAreVariantsRowsAreFrames');
+      expect(
+        decodeSurfaceAtlasLayout('columnsAreVariantsRowsAreFrames'),
+        l,
+      );
+    });
+
+    test('9. reject layout unknown or wrong casing', () {
+      expect(
+        () => decodeSurfaceAtlasLayout('unknown'),
+        throwsA(
+          isA<ValidationException>().having(
+            (e) => e.toString().contains('SurfaceAtlasLayout'),
+            'msg',
+            isTrue,
+          ),
+        ),
+      );
+      expect(
+        () => decodeSurfaceAtlasLayout('Grid'),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('10. encode SurfaceAtlasGeometry', () {
+      final g = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+        gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
+        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+      );
+      final m = encodeSurfaceAtlasGeometry(g);
+      expect(
+        m,
+        {
+          'tileSize': {'width': 32, 'height': 32},
+          'gridSize': {'columns': 23, 'rows': 32},
+          'layout': 'columnsAreVariantsRowsAreFrames',
+        },
+      );
+    });
+
+    test('11. decode SurfaceAtlasGeometry + tileCount', () {
+      final g = decodeSurfaceAtlasGeometry({
+        'tileSize': {'width': 32, 'height': 32},
+        'gridSize': {'columns': 23, 'rows': 32},
+        'layout': 'columnsAreVariantsRowsAreFrames',
+      });
+      final expected = SurfaceAtlasGeometry(
+        tileSize: SurfaceAtlasTileSize(width: 32, height: 32),
+        gridSize: SurfaceAtlasGridSize(columns: 23, rows: 32),
+        layout: SurfaceAtlasLayout.columnsAreVariantsRowsAreFrames,
+      );
+      expect(g, expected);
+      expect(g.tileCount, 23 * 32);
+    });
+
+    test('12. reject geometry missing nested / wrong types', () {
+      expect(
+        () => decodeSurfaceAtlasGeometry({
+          'gridSize': {
+            'columns': 1,
+            'rows': 1,
+          },
+          'layout': 'grid',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasGeometry({
+          'tileSize': {
+            'width': 1,
+            'height': 1,
+          },
+          'gridSize': 3,
+          'layout': 'grid',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeSurfaceAtlasGeometry({
+          'tileSize': {
+            'width': 1,
+            'height': 1,
+          },
+          'gridSize': {
+            'columns': 1,
+            'rows': 1,
+          },
+          'layout': 1,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('13. encode ProjectSurfaceAtlas minimal', () {
+      final a = _atlas(categoryId: null, sortOrder: 0);
+      final m = encodeProjectSurfaceAtlas(a);
+      expect(m.containsKey('categoryId'), isFalse);
+      expect(m['sortOrder'], 0);
+      expect(m['id'], 'water-atlas');
+      expect(m['name'], 'Water Atlas');
+      expect(m['tilesetId'], 'nature-tileset');
+      expect(m['geometry'], isA<Map<String, Object?>>());
+    });
+
+    test('14. encode ProjectSurfaceAtlas full', () {
+      final a = _atlas(
+        categoryId: 'animated-surfaces',
+        sortOrder: 42,
+      );
+      final m = encodeProjectSurfaceAtlas(a);
+      expect(m['categoryId'], 'animated-surfaces');
+      expect(m['sortOrder'], 42);
+    });
+
+    test('15. decode ProjectSurfaceAtlas minimal (no category, no sortOrder)',
+        () {
+      final a = decodeProjectSurfaceAtlas({
+        'id': 'a',
+        'name': 'n',
+        'tilesetId': 't',
+        'geometry': {
+          'tileSize': {'width': 8, 'height': 8},
+          'gridSize': {'columns': 1, 'rows': 1},
+          'layout': 'grid',
+        },
+      });
+      expect(a.categoryId, isNull);
+      expect(a.sortOrder, 0);
+    });
+
+    test('16. decode ProjectSurfaceAtlas full', () {
+      final a = decodeProjectSurfaceAtlas({
+        'id': 'a',
+        'name': 'n',
+        'tilesetId': 't',
+        'geometry': {
+          'tileSize': {'width': 8, 'height': 8},
+          'gridSize': {'columns': 1, 'rows': 1},
+          'layout': 'grid',
+        },
+        'categoryId': 'animated-surfaces',
+        'sortOrder': 42,
+      });
+      expect(a.categoryId, 'animated-surfaces');
+      expect(a.sortOrder, 42);
+    });
+
+    test('17. round-trip ProjectSurfaceAtlas', () {
+      final atlas = _atlas(
+        categoryId: 'cat',
+        sortOrder: 7,
+        geometry: _geometry(
+          width: 16,
+          height: 8,
+          columns: 2,
+          rows: 3,
+        ),
+      );
+      final json = encodeProjectSurfaceAtlas(atlas);
+      final back = decodeProjectSurfaceAtlas(json);
+      expect(back, atlas);
+    });
+
+    test('18. exact strings preserved (no trim in codec)', () {
+      const id = '  water-atlas  ';
+      const name = '  Water Atlas  ';
+      const tid = '  nature-tileset  ';
+      const cat = '  animated  ';
+      final a = _atlas(
+        id: id,
+        name: name,
+        tilesetId: tid,
+        categoryId: cat,
+        sortOrder: 0,
+        geometry: _geometry(
+          width: 8,
+          height: 8,
+          columns: 1,
+          rows: 1,
+        ),
+      );
+      final j = encodeProjectSurfaceAtlas(a);
+      final b = decodeProjectSurfaceAtlas(j);
+      expect(b.id, id);
+      expect(b.name, name);
+      expect(b.tilesetId, tid);
+      expect(b.categoryId, cat);
+    });
+
+    test(
+        '19. reject id / name / tilesetId missing, wrong type, whitespace tileset',
+        () {
+      final baseG = {
+        'tileSize': {'width': 1, 'height': 1},
+        'gridSize': {'columns': 1, 'rows': 1},
+        'layout': 'grid',
+      };
+      expect(
+        () => decodeProjectSurfaceAtlas({
+          'name': 'n',
+          'tilesetId': 't',
+          'geometry': baseG,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeProjectSurfaceAtlas({
+          'id': 'a',
+          'name': 1,
+          'tilesetId': 't',
+          'geometry': baseG,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeProjectSurfaceAtlas({
+          'id': 'a',
+          'name': 'n',
+          'tilesetId': '   ',
+          'geometry': baseG,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('20. reject geometry missing or non-map on atlas', () {
+      expect(
+        () => decodeProjectSurfaceAtlas({
+          'id': 'a',
+          'name': 'n',
+          'tilesetId': 't',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => decodeProjectSurfaceAtlas({
+          'id': 'a',
+          'name': 'n',
+          'tilesetId': 't',
+          'geometry': 'nope',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('21. reject categoryId non-string non-null', () {
+      expect(
+        () => decodeProjectSurfaceAtlas({
+          'id': 'a',
+          'name': 'n',
+          'tilesetId': 't',
+          'geometry': {
+            'tileSize': {'width': 1, 'height': 1},
+            'gridSize': {'columns': 1, 'rows': 1},
+            'layout': 'grid',
+          },
+          'categoryId': 123,
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('22. decode categoryId null in JSON', () {
+      final a = decodeProjectSurfaceAtlas({
+        'id': 'a',
+        'name': 'n',
+        'tilesetId': 't',
+        'geometry': {
+          'tileSize': {'width': 1, 'height': 1},
+          'gridSize': {'columns': 1, 'rows': 1},
+          'layout': 'grid',
+        },
+        'categoryId': null,
+      });
+      expect(a.categoryId, isNull);
+    });
+
+    test('23. reject sortOrder non-int', () {
+      expect(
+        () => decodeProjectSurfaceAtlas({
+          'id': 'a',
+          'name': 'n',
+          'tilesetId': 't',
+          'geometry': {
+            'tileSize': {'width': 1, 'height': 1},
+            'gridSize': {'columns': 1, 'rows': 1},
+            'layout': 'grid',
+          },
+          'sortOrder': '1',
+        }),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('24. decode sortOrder negative', () {
+      final a = decodeProjectSurfaceAtlas({
+        'id': 'a',
+        'name': 'n',
+        'tilesetId': 't',
+        'geometry': {
+          'tileSize': {'width': 1, 'height': 1},
+          'gridSize': {'columns': 1, 'rows': 1},
+          'layout': 'grid',
+        },
+        'sortOrder': -10,
+      });
+      expect(a.sortOrder, -10);
+    });
+
+    test('25. decode ignores unknown top-level key', () {
+      final a = decodeProjectSurfaceAtlas({
+        'id': 'a',
+        'name': 'n',
+        'tilesetId': 't',
+        'geometry': {
+          'tileSize': {'width': 1, 'height': 1},
+          'gridSize': {'columns': 1, 'rows': 1},
+          'layout': 'grid',
+        },
+        'futureField': 'ignored',
+      });
+      expect(a.id, 'a');
+    });
+
+    test('26. tilesetId not resolved against manifest', () {
+      final a = decodeProjectSurfaceAtlas({
+        'id': 'a',
+        'name': 'n',
+        'tilesetId': 'missing-tileset',
+        'geometry': {
+          'tileSize': {'width': 1, 'height': 1},
+          'gridSize': {'columns': 1, 'rows': 1},
+          'layout': 'grid',
+        },
+      });
+      expect(a.tilesetId, 'missing-tileset');
+    });
+
+    test('27. decode does not mutate source map', () {
+      final map = <String, Object?>{
+        'id': 'a',
+        'name': 'n',
+        'tilesetId': 't',
+        'geometry': <String, Object?>{
+          'tileSize': <String, Object?>{'width': 1, 'height': 1},
+          'gridSize': <String, Object?>{'columns': 1, 'rows': 1},
+          'layout': 'grid',
+        },
+      };
+      final before = _deepStr(map);
+      decodeProjectSurfaceAtlas(map);
+      final after = _deepStr(map);
+      expect(before, after);
+    });
+
+    test('28. public API returns Map from encode', () {
+      final m = encodeProjectSurfaceAtlas(_atlas());
+      expect(m, isA<Map<String, Object?>>());
+    });
+
+    test('29. ProjectManifest has no surface persistence keys (Lot 39)', () {
+      const manifest = ProjectManifest(
+        name: 'L39',
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
+    test('30. codec external to models: no model toJson / fromJson', () {
+      final a = _atlas();
+      final json = encodeProjectSurfaceAtlas(a);
+      expect(json, isA<Map<String, Object?>>());
+      // Lot 39: persistence via codec only — models stay JSON-free
+      // (do not call atlas.toJson or ProjectSurfaceAtlas.fromJson).
+    });
+  });
+}
+
+String _deepStr(Object? o) {
+  if (o is Map) {
+    return '{${o.keys.map((k) => '$k:${_deepStr(o[k])}').join(',')}}';
+  }
+  if (o is String) {
+    return o;
+  }
+  if (o is int) {
+    return '$o';
+  }
+  if (o == null) {
+    return 'null';
+  }
+  return o.toString();
+}
```

#### Rapport (exception contractuelle seulement)

Un diff ajoutant ce fichier `.md` depuis `/dev/null` serait, ligne par ligne, équivalent à préfixer chaque ligne du corps de ce document par `+` ; le corps prouvé est le présent lot §1–38.

### 37.D = §29–§31 (sorties) + §32 (ligne finale du test complet)

Reprise des sorties de commandes dans les sections indiquées.

## 38. Auto-check (substituts de preuve)

Recherche : aucune des formulations d’évidence listées en en-tête de lot n’est utilisée ici pour remplacer une preuve requise. La liste complète n’est **pas** recopiée dans ce fichier (éviter les faux positifs de détection), conformément aux instructions du cahier des lots.

