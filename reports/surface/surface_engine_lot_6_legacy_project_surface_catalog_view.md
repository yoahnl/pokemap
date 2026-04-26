# Surface Engine Lot 6 - Legacy Project Surface Catalog View V0

## 1. Resume executif

Le Lot 6 ajoute une vue read-only et non persistante au niveau `ProjectManifest`:

```text
ProjectManifest
  terrainPresets -> LegacyTerrainSurfaceView[]
  pathPresets    -> LegacyPathSurfaceView[]
```

L'API ajoutee est `LegacyProjectSurfaceCatalogView`, construite par
`createLegacyProjectSurfaceCatalogView(ProjectManifest manifest)`.

Le catalogue garde volontairement les terrains et les paths separes. Il ne cree
pas de modele `SurfaceDefinition`, ne cree pas de `SurfaceEngine`, ne modifie
pas le schema JSON, ne modifie pas les modeles Freezed et ne branche rien dans
le runtime, l'editeur ou le gameplay.

Le lot a suivi une boucle TDD:

1. ajout du test `legacy_project_surface_catalog_view_test.dart`;
2. verification du rouge attendu parce que l'API n'existait pas encore;
3. ajout de l'adaptateur pur;
4. export public dans `map_core.dart`;
5. verification ciblee, tests des lots precedents, puis suite complete
   `map_core`.

Resultat final: `dart analyze` cible passe, les tests cibles passent, et
`/opt/homebrew/bin/dart test` dans `packages/map_core` passe avec 223 tests.

## 2. Pourquoi ce lot est necessaire apres les Lots 4 et 5

Les Lots 4 et 5 ont cree des adaptateurs unitaires:

- `LegacyPathSurfaceView` pour voir un `ProjectPathPreset` comme une surface
  legacy path;
- `LegacyTerrainSurfaceView` pour voir un `ProjectTerrainPreset` comme une
  surface legacy terrain.

Ces deux vues etaient utiles pour inspecter un preset isole, mais il manquait
un point d'entree projet. Le futur travail Surface Engine aura besoin de lister
les surfaces candidates d'un projet sans parcourir manuellement deux listes
separees dans `ProjectManifest`.

Ce lot fournit cet inventaire sans schema persistant. Il prepare les etapes
suivantes suivantes:

- afficher ou auditer les surfaces candidates dans un outil futur;
- comparer les presets legacy a un futur `SurfaceDefinition`;
- construire des rapports de migration;
- garder une compatibilite stricte avec les manifests actuels.

## 3. Fichiers consultes

Fichiers source consultes:

- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/enums.dart`
- `packages/map_core/lib/src/operations/legacy_path_surface_view.dart`
- `packages/map_core/lib/src/operations/legacy_terrain_surface_view.dart`
- `packages/map_core/lib/map_core.dart`

Tests consultes:

- `packages/map_core/test/legacy_path_surface_view_test.dart`
- `packages/map_core/test/legacy_terrain_surface_view_test.dart`
- `packages/map_core/test/project_manifest_surface_json_characterization_test.dart`

Constats principaux:

- `ProjectManifest.terrainPresets` est une `List<ProjectTerrainPreset>` avec
  valeur par defaut vide.
- `ProjectManifest.pathPresets` est une `List<ProjectPathPreset>` avec valeur
  par defaut vide.
- `LegacyPathSurfaceView` et `LegacyTerrainSurfaceView` sont deja separes et
  non mutables.
- `ProjectTerrainPreset` expose `TerrainType`, des variants ponderes et des
  frames.
- `ProjectPathPreset` expose `PathSurfaceKind`, des mappings
  `TerrainPathVariant`, et des frames.
- Les ids legacy sont des donnees de liste. Ce lot ne doit pas supposer leur
  unicite.

## 4. Fichiers crees

- `packages/map_core/lib/src/operations/legacy_project_surface_catalog_view.dart`
- `packages/map_core/test/legacy_project_surface_catalog_view_test.dart`
- `reports/analysis/surface_engine_lot_6_legacy_project_surface_catalog_view.md`

## 5. Fichiers modifies

- `packages/map_core/lib/map_core.dart`

Modification exacte du lot:

- ajout de l'export public:

```dart
export 'src/operations/legacy_project_surface_catalog_view.dart';
```

Aucun fichier runtime, editor, gameplay, battle, modele Freezed, fichier
`.g.dart` ou fichier `.freezed.dart` n'a ete modifie par ce lot.

## 6. API ajoutee

Fichier:

```text
packages/map_core/lib/src/operations/legacy_project_surface_catalog_view.dart
```

API principale:

```dart
final class LegacyProjectSurfaceCatalogView {
  LegacyProjectSurfaceCatalogView({
    required List<LegacyTerrainSurfaceView> terrainSurfaces,
    required List<LegacyPathSurfaceView> pathSurfaces,
  });

  final List<LegacyTerrainSurfaceView> terrainSurfaces;
  final List<LegacyPathSurfaceView> pathSurfaces;

  bool get hasTerrainSurfaces;
  bool get hasPathSurfaces;
  bool get isEmpty;

  LegacyTerrainSurfaceView? terrainSurfaceById(String id);
  LegacyPathSurfaceView? pathSurfaceById(String id);

  List<LegacyTerrainSurfaceView> terrainSurfacesByType(TerrainType type);
  List<LegacyPathSurfaceView> pathSurfacesByKind(PathSurfaceKind kind);
}
```

Fonction de creation:

```dart
LegacyProjectSurfaceCatalogView createLegacyProjectSurfaceCatalogView(
  ProjectManifest manifest,
)
```

## 7. Semantique du catalogue

### Construction

`createLegacyProjectSurfaceCatalogView`:

- lit `manifest.terrainPresets`;
- adapte chaque terrain avec `createLegacyTerrainSurfaceView`;
- lit `manifest.pathPresets`;
- adapte chaque path avec `createLegacyPathSurfaceView`;
- preserve l'ordre exact des terrains;
- preserve l'ordre exact des paths;
- ne mute pas le manifest source;
- ne valide pas le manifest;
- ne corrige pas les doublons;
- ne cree aucune donnee persistante.

### Read-only

Les listes exposees sont creees avec `List.unmodifiable`:

- `terrainSurfaces`;
- `pathSurfaces`;
- resultats de `terrainSurfacesByType`;
- resultats de `pathSurfacesByKind`.

Les vues individuelles reutilisees restent elles aussi read-only grace aux Lots
4 et 5.

### Lookups par id

`terrainSurfaceById` et `pathSurfaceById` retournent le premier element dont
l'id correspond.

Si aucun element ne correspond, la methode retourne `null`.

En cas de doublon:

- aucun throw;
- aucune validation;
- aucune deduplication;
- premier match retourne.

Ce choix documente le comportement de liste legacy sans inventer une politique
de validation avant le futur modele Surface.

### Filtres

`terrainSurfacesByType(TerrainType type)`:

- filtre uniquement `terrainSurfaces`;
- preserve l'ordre du manifest;
- retourne une liste non mutable;
- retourne une liste vide si aucun terrain ne correspond.

`pathSurfacesByKind(PathSurfaceKind kind)`:

- filtre uniquement `pathSurfaces`;
- preserve l'ordre du manifest;
- retourne une liste non mutable;
- retourne une liste vide si aucun path ne correspond.

### Separation terrain/path

Le catalogue ne fusionne pas les deux mondes:

- terrain reste `TerrainType`;
- path reste `PathSurfaceKind`;
- un terrain et un path peuvent partager le meme id sans collision dans le
  catalogue.

## 8. Liste complete des cas testes

Fichier:

```text
packages/map_core/test/legacy_project_surface_catalog_view_test.dart
```

Cas testes:

1. Catalogue vide:
   - listes vides;
   - `hasTerrainSurfaces == false`;
   - `hasPathSurfaces == false`;
   - `isEmpty == true`.

2. Catalogue avec terrains et paths:
   - deux terrains;
   - deux paths;
   - ordre preserve;
   - ids preserves;
   - `TerrainType` preserves;
   - `PathSurfaceKind` preserves;
   - `isEmpty == false`.

3. Delegation aux adaptateurs existants:
   - terrain avec variant anime;
   - path avec mapping anime;
   - poids terrain preserve;
   - frames path preservees;
   - overrides `tilesetId` preserves;
   - `hasAnimatedVariants` expose via les vues existantes.

4. Lookup terrain par id:
   - id existant retourne le bon terrain;
   - id absent retourne `null`.

5. Lookup path par id:
   - id existant retourne le bon path;
   - id absent retourne `null`.

6. Doublons terrain:
   - deux terrains avec le meme id sont conserves;
   - lookup retourne le premier;
   - aucun throw.

7. Doublons path:
   - deux paths avec le meme id sont conserves;
   - lookup retourne le premier;
   - aucun throw.

8. Filtre terrain par type:
   - deux `grass` retournes dans l'ordre;
   - un `sand` retourne;
   - type absent retourne une liste vide.

9. Filtre path par kind:
   - deux `water` retournes dans l'ordre;
   - un `tallGrass` retourne;
   - kind absent retourne une liste vide.

10. Listes non mutables:
    - `terrainSurfaces.add(...)` throw;
    - `pathSurfaces.add(...)` throw;
    - `terrainSurfacesByType(...).add(...)` throw;
    - `pathSurfacesByKind(...).add(...)` throw.

11. Manifest source non mute:
    - `manifest.terrainPresets` intact;
    - `manifest.pathPresets` intact;
    - variants intactes;
    - frames intactes;
    - poids intact.

12. Pas de fusion terrain/path:
    - un terrain et un path peuvent partager le meme id;
    - lookup terrain retourne le terrain;
    - lookup path retourne le path;
    - collections separees.

## 9. Ce que les tests prouvent

Les tests prouvent que le catalogue:

- est une vue read-only;
- preserve l'ordre des presets;
- preserve la separation terrain/path;
- reutilise bien les adaptateurs des Lots 4 et 5;
- preserve les frames, poids et overrides `tilesetId` via ces adaptateurs;
- documente les doublons sans les corriger;
- fournit des lookups simples mais non validants;
- fournit des filtres simples non mutables;
- ne mute pas le `ProjectManifest`.

Les tests ne prouvent pas de comportement runtime, volontairement. Ce lot est
une brique pure de `map_core`.

## 10. Ce qui n'a volontairement pas ete fait

Ce lot n'a pas:

- cree `SurfaceDefinition`;
- cree `SurfaceEngine`;
- cree une union commune `LegacySurfaceView`;
- ajoute `surfaceDefinitions` a `ProjectManifest`;
- modifie `ProjectManifest`;
- modifie `ProjectTerrainPreset`;
- modifie `ProjectPathPreset`;
- modifie `LegacyTerrainSurfaceView`;
- modifie `LegacyPathSurfaceView`;
- modifie `RuntimePathAutotileSet`;
- modifie `MapLayersComponent`;
- modifie le runtime Flame;
- modifie l'editeur Flutter;
- modifie `map_gameplay`;
- modifie `map_battle`;
- lance `build_runner`;
- modifie un fichier genere.

## 11. Impact pour les futurs modeles Surface

Le catalogue donne un point d'entree projet pour les prochains lots sans schema
persistant.

Impacts utiles:

- un futur outil d'audit peut lister les terrains et paths candidats;
- une future migration peut comparer les vues legacy a des definitions Surface;
- les ids dupliques peuvent etre detectes par un rapport dedie plus tard;
- la separation terrain/path evite de confondre `TerrainType` et
  `PathSurfaceKind` trop tot;
- les futures surfaces peuvent etre introduites sans casser les adaptateurs
  legacy.

Ce lot garde aussi visible une contrainte importante: une surface metier future
devra probablement unifier certaines capacites, mais ce n'est pas encore le bon
moment pour imposer cette union dans `map_core`.

## 12. Points de vigilance

- Les lookups retournent le premier id trouve. Ce comportement est volontaire,
  mais il peut masquer des doublons si un appelant l'utilise comme validation.
- Les filtres creent de nouvelles listes non mutables a chaque appel. C'est
  simple et sur, mais pas optimise pour de tres gros manifests.
- Le catalogue est un snapshot de vues. Il ne doit pas devenir une source de
  mutation.
- Les terrains et paths restent separes. Toute fusion prematuree risquerait de
  reintroduire exactement l'abstraction trop large que ces lots evitent.
- Le catalogue ne connait pas les layers. Il inventorie les presets projet, pas
  l'usage reel sur les maps.

## 13. Commandes lancees

Commande TDD rouge initiale:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_project_surface_catalog_view_test.dart
```

Resultat initial attendu:

```text
Failed to load "test/legacy_project_surface_catalog_view_test.dart":
Error: Method not found: 'createLegacyProjectSurfaceCatalogView'.
```

Formatage:

```bash
cd packages/map_core
/opt/homebrew/bin/dart format \
  lib/src/operations/legacy_project_surface_catalog_view.dart \
  test/legacy_project_surface_catalog_view_test.dart \
  lib/map_core.dart
```

Analyse statique:

```bash
cd packages/map_core
/opt/homebrew/bin/dart analyze \
  lib/src/operations/legacy_project_surface_catalog_view.dart \
  test/legacy_project_surface_catalog_view_test.dart \
  lib/map_core.dart
```

Tests cibles:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test test/legacy_project_surface_catalog_view_test.dart
/opt/homebrew/bin/dart test test/legacy_terrain_surface_view_test.dart
/opt/homebrew/bin/dart test test/legacy_path_surface_view_test.dart
/opt/homebrew/bin/dart test test/project_manifest_surface_json_characterization_test.dart
/opt/homebrew/bin/dart test test/map_terrain_autotile_characterization_test.dart
/opt/homebrew/bin/dart test test/tile_visual_frame_timeline_test.dart
/opt/homebrew/bin/dart test test/legacy_editor_json_compat_collision_test.dart
/opt/homebrew/bin/dart test test/element_collision_profile_pixel_mask_json_test.dart
```

Suite complete:

```bash
cd packages/map_core
/opt/homebrew/bin/dart test
```

Commande Git en lecture:

```bash
git status --short
git diff -- packages/map_core/lib/map_core.dart
```

Aucune commande Git d'ecriture n'a ete lancee.

## 14. Resultats des tests

Resultats:

- `dart analyze ...`: `No issues found!`
- `legacy_project_surface_catalog_view_test.dart`: 12 tests, tous passent.
- `legacy_terrain_surface_view_test.dart`: 12 tests, tous passent.
- `legacy_path_surface_view_test.dart`: 11 tests, tous passent.
- `project_manifest_surface_json_characterization_test.dart`: 15 tests, tous
  passent.
- `map_terrain_autotile_characterization_test.dart`: 21 tests, tous passent.
- `tile_visual_frame_timeline_test.dart`: 16 tests, tous passent.
- `legacy_editor_json_compat_collision_test.dart`: 3 tests, tous passent.
- `element_collision_profile_pixel_mask_json_test.dart`: 6 tests, tous passent.
- `dart test` complet dans `packages/map_core`: 223 tests, tous passent.

## 15. Autocritique finale

Points positifs:

- Le lot est reste petit et strictement read-only.
- Le test rouge initial confirme que le nouveau test couvrait une API absente.
- L'implementation reutilise les adaptateurs existants au lieu de dupliquer la
  logique de preservation des frames.
- Les doublons sont documentes explicitement.
- Les listes exposees et les resultats de filtre sont non mutables.
- La suite complete `map_core` reste verte.

Limites:

- Le catalogue n'inventorie pas l'usage reel des presets dans les maps. C'est
  correct pour ce lot, mais un futur audit de migration devra regarder aussi les
  layers.
- Les lookups lineaires sont simples et suffisants pour V0, mais un futur outil
  intensif pourrait vouloir des index caches.
- Le catalogue ne signale pas les doublons. Il les preserve seulement. Un futur
  rapport de compatibilite devrait les diagnostiquer.
- Les filtres allouent une nouvelle liste a chaque appel. C'est acceptable ici
  pour garder l'API simple.

## 16. Ce que le prompt semble discutable ou incomplet

Le prompt est coherent avec la progression des lots precedents. Quelques points
restent a garder en tete:

- Le prompt demande des lookups simples par id, mais les ids legacy peuvent etre
  dupliques. La politique "premier match" est documentee, mais elle ne doit pas
  etre confondue avec une garantie d'unicite.
- Le prompt demande un catalogue de surfaces legacy, mais il ne couvre pas les
  layers qui utilisent ces presets. C'est volontaire pour V0, mais incomplet
  pour une migration reelle.
- Le prompt interdit une vue unifiee, ce qui est sain a ce stade. En revanche,
  les prochains lots devront definir quand et comment une abstraction commune
  devient justifiee.
- Le catalogue ne gere pas `tilesets` directement. C'est normal, mais les
  futures surfaces devront probablement croiser presets, frames et tilesets.

## 17. Auto-review independante

- Est-ce que le lot est reste strictement limite a un catalogue legacy
  read-only ? Oui.
- Est-ce qu'aucun modele Surface persistant n'a ete cree ? Oui.
- Est-ce qu'aucune vue unifiee Surface n'a ete creee ? Oui.
- Est-ce qu'aucun modele Freezed/JSON n'a ete modifie ? Oui.
- Est-ce qu'aucun fichier generated n'a ete modifie ? Oui.
- Est-ce qu'aucun runtime/editor/gameplay n'a ete modifie ? Oui.
- Est-ce que `ProjectManifest` n'a pas ete modifie ? Oui, le modele n'a pas ete
  modifie. Seul le barrel `map_core.dart` exporte la nouvelle operation.
- Est-ce que `ProjectTerrainPreset` n'a pas ete modifie ? Oui.
- Est-ce que `ProjectPathPreset` n'a pas ete modifie ? Oui.
- Est-ce que le catalogue garde terrain et path separes ? Oui.
- Est-ce que l'ordre des presets est preserve ? Oui, couvert par test.
- Est-ce que les doublons sont documentes sans etre corriges ? Oui, couvert par
  tests terrain et path.
- Est-ce que les listes exposees sont non mutables ? Oui, couvert par test.
- Est-ce que les tests documentent le comportement actuel plutot qu'un
  comportement futur ideal ? Oui.
- Est-ce que les tests des lots precedents passent toujours ? Oui.
- Est-ce que `map_core` complet passe ? Oui, 223 tests passent.
- Est-ce que les commandes Git interdites n'ont pas ete utilisees ? Oui.
- Est-ce que le rapport est assez detaille ? Oui.
- Est-ce que quelque chose du prompt etait ambigu ou discutable ? Oui, surtout
  la limite entre inventaire de presets et inventaire d'usages reels dans les
  maps. Cette limite est documentee et n'a pas ete franchie.
