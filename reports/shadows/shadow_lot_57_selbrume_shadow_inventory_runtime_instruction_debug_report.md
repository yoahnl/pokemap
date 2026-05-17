# Shadow-57 - Selbrume Shadow Inventory & Runtime Instruction Debug Report

## 1. Resume executif

Shadow-57 est un audit uniquement. Aucun code de production n'a ete modifie, aucun fichier Selbrume n'a ete modifie, et aucun renderer/profil/family/calibration n'a ete touche.

Diagnostic court :

- Shadow-56 est bien en place : `map_runtime` n'appelle plus `applyElementAutoShadowPolicyToProject`.
- Selbrume contient 63 elements, dont 25 avec une config Shadow authoree.
- Selbrume contient 2105 placements.
- 112 placements referencent un element source avec config Shadow.
- Le runtime produit 111 instructions statiques `groundStatic`.
- Les 111 instructions statiques ont `shapeKind = projectedPolygon`.
- 101 instructions sont de vraies projections diagonales.
- 10 instructions sont des contact ledges de buildings, mais elles restent rendues via `projectedPolygon`.
- Les principaux coupables restants sont authores dans `project.json`, pas injectes par le runtime.
- Les deux arbres `arbre_pixellab_1` et `arbre_pixellab_2` produisent 95 instructions a eux seuls, toutes en `family null -> genericProjection`, donc grandes projections diagonales.
- Le panneau produit une projection diagonale visible et doit etre desactive en premier.
- Le lampadaire produit 4 projections diagonales plus petites mais conceptuellement mauvaises pour ce type de prop.

Conclusion produit :

Le rendu reste mauvais apres Shadow-56 parce que Selbrume porte deja des configs Shadow authorees dangereuses. Le runtime n'invente plus les ombres, mais il consomme encore des ombres authorees qui demandent une neutralisation ou une revision artistique.

## 2. Rappel Shadow-56

Shadow-56 a retire du runtime l'appel silencieux :

```dart
applyElementAutoShadowPolicyToProject(manifest).project
```

La frontiere actuelle est :

```text
Runtime = consomme le manifest authore.
Editor = peut proposer ou appliquer explicitement.
Utilisateur = valide les choix visuels.
```

Shadow-57 verifie donc ce qui reste visible lorsque le runtime lit seulement le manifest authore.

## 3. Etat initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie :

```text
```

Il n'y avait aucun fichier modifie ou non suivi au debut de Shadow-57.

Commande :

```bash
find .. -name AGENTS.md -print
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Seul `/Users/karim/Project/pokemonProject/AGENTS.md` est applicable au repo courant.

## 4. Methode d'audit

Passes effectuees :

1. Verification Git et AGENTS.
2. Verification Shadow-56 par `rg`.
3. Lecture du chemin runtime Shadow.
4. Lecture des operations core de geometrie, projection, family et contact ledge.
5. Audit Selbrume en lecture seule avec `jq`.
6. Probe runtime temporaire via `flutter test /tmp/shadow57_probe_test.dart`.
7. Inventaire detaille via script Python temporaire hors repo.
8. Tests de non-regression.
9. Creation de ce rapport.

Flame docs :

```text
Recherche Flame MCP: "Flame Component render method Canvas drawPath drawOval render order priority PositionComponent"
Resultat: No results found

Recherche Flame MCP: "priority render order component"
Resultat: No results found
```

La documentation Flame MCP n'a pas donne de resultat exploitable pour ce lot. L'audit du rendu s'appuie donc sur le code local existant, notamment `ShadowRuntimeRenderer`, qui appelle `Canvas.drawOval` pour ellipse/contactBlob et `Canvas.drawPath` pour `projectedPolygon`.

Probe Dart direct :

```bash
cd packages/map_runtime && dart run /tmp/shadow57_probe.dart
```

Resultat utile :

```text
Running build hooks...Error: Running build hooks failed.
Error: Unknown option '-isysroot'
Usage: swiftly <subcommand>
```

Cause observee : le hook natif `objective_c` tente d'utiliser `/opt/homebrew/Cellar/swiftly/1.1.1/bin/swiftly` comme compilateur et celui-ci rejette `-isysroot`. Je n'ai pas corrige l'environnement, car le lot est audit-only.

Probe Flutter temporaire reussi :

```bash
cd packages/map_runtime && flutter test /tmp/shadow57_probe_test.dart --plain-name 'shadow57 probe'
```

Sortie :

```text
00:00 +0: loading /tmp/shadow57_probe_test.dart
00:00 +0: shadow57 probe
SHADOW57_DIRECT manifestElements=63 placements=2105 sources=2104 instructions=111 groundStatic=111 actorContact=0
00:00 +1: All tests passed!
```

Le fichier `/tmp/shadow57_probe_test.dart` et le script `/tmp/shadow57_inventory.py` etaient temporaires et hors repo.

## 5. Confirmation que runtime auto-apply est absent

Commande :

```bash
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
```

Sortie exacte :

```text
packages/map_core/lib/src/operations/element_auto_shadow_policy.dart:142:ElementAutoShadowBackfillResult applyElementAutoShadowPolicyToProject(
packages/map_editor/test/application/shadow/element_auto_shadow_backfill_test.dart:451:      final coreResult = applyElementAutoShadowPolicyToProject(project);
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:142:  group('applyElementAutoShadowPolicyToProject', () {
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:144:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:169:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:194:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:221:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:256:      final result = applyElementAutoShadowPolicyToProject(
packages/map_core/test/shadow/element_auto_shadow_policy_test.dart:293:      final result = applyElementAutoShadowPolicyToProject(
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:8:        applyElementAutoShadowPolicyToProject;
packages/map_editor/lib/src/application/shadow/element_auto_shadow_backfill.dart:13:  return applyElementAutoShadowPolicyToProject(project);
```

Interpretation :

- `map_runtime` : aucun appel.
- `map_core` : definition et tests seulement.
- `map_editor` : backfill explicite via application/editor.

Shadow-56 est donc confirme.

## 6. Chaine runtime reelle de generation des instructions Shadow

Chemin reel audite :

```text
/Users/karim/Desktop/selbrume/project.json
-> loadProjectManifestFromFile(...)
-> ProjectValidator.validate(manifest)
-> manifest authore retourne tel quel

/Users/karim/Desktop/selbrume/maps/Selbrume.json
-> loadMapDataFromFile(...)
-> MapData

RuntimeMapBundle
-> buildRuntimeStaticPlacedElementShadowSources(bundle)
-> filtre layers TileLayer visibles et opacity > 0
-> pour chaque MapPlacedElement visible :
   - element source via elementId
   - frame source first
   - metrics worldLeft/worldTop/visualWidth/visualHeight
   - elementShadow = element.shadow
   - placedOverride = placed.shadowOverride

buildRuntimeStaticPlacedElementShadowCollection(...)
-> resolveShadowConfig(catalog, elementShadow, placedOverride)
-> StaticPlacedElementShadowRuntimeInput
-> resolveStaticPlacedElementShadowRuntimeInstruction(...)
-> resolveStaticShadowGeometry(...)
-> resolveStaticShadowFamily(...)
-> if family == building: resolveBuildingStaticShadowContactLedgeGeometry(...)
-> else: resolveProjectedStaticShadowGeometry(...)
-> ShadowRuntimeRenderInstruction(shape: projectedPolygon, renderPass: groundStatic)
-> ShadowRuntimeRenderer.renderCollectionPass(...)
-> Canvas.drawPath(...) for projectedPolygon
```

Point critique :

Dans le runtime statique actuel, meme les profils `ellipse` et `contactBlob` ne produisent plus des ovals pour les elements statiques. Ils passent par la family et sortent en `ShadowRuntimeShapeKind.projectedPolygon`. Les buildings passent par une geometrie `contactLedge`, mais la shape runtime reste `projectedPolygon`.

## 7. Inventaire project.json Selbrume

Commandes principales :

```bash
jq -r '.elements | length' /Users/karim/Desktop/selbrume/project.json
jq -r '[.elements[] | select(.shadow != null)] | length' /Users/karim/Desktop/selbrume/project.json
jq -r '[.elements[] | select(.shadow == null)] | length' /Users/karim/Desktop/selbrume/project.json
```

Sorties :

```text
63
25
38
```

Inventaire calcule :

```json
{
  "project_total_elements": 63,
  "project_with_shadow": 25,
  "project_without_shadow": 38,
  "project_casts_true": 25,
  "project_casts_false": 0,
  "project_family_null_with_shadow": 4,
  "project_with_footprint": 25,
  "project_without_footprint_among_shadow": 0,
  "project_projected_polygon_potential_elements": 9,
  "project_contact_ledge_potential_elements": 16,
  "project_with_opacity_non_null": 25,
  "project_with_scale_custom": 22,
  "project_with_offset_custom": 25
}
```

Comptes par family :

```json
{
  "building": 16,
  "tallProp": 2,
  "null": 4,
  "compactProp": 3
}
```

Comptes par profil :

```json
{
  "default-ground-wide-ellipse": 20,
  "default-ground-contact-blob": 2,
  "default-ground-soft-ellipse": 3
}
```

Liste TSV des elements avec Shadow :

```text
test_maison_pkm	test maison pkm	6	7	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
test	test	45	33	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
custom_cliff_selbrume	custom cliff  selbrume	3	13	true	default-ground-contact-blob	tallProp	0.2	0.8	0.55
selbrum_maison_1	selbrum maison 1	5	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
selbrum_maison_2	selbrum maison  2	6	7	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
selbrum_maison_3	selbrum maison 3	8	7	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
selbrum_maison_4	selbrum maison  4	5	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
selbrum_maison_7	selbrum maison  7	6	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
selbrum_maison_8	selbrum maison  8	11	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
objectif	objectif	45	33	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
selbrume_centre_pok_mon	selbrume centre pokémon	8	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
selbrume_maison_5	selbrume maison 5	7	6	true	default-ground-soft-ellipse	null	0.22	null	null
selbrume_maison_6	selbrume maison 6	6	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
le_puits	le puits	4	5	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
kiosque_l_gumes	kiosque à légumes	6	6	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
for_t_1	forêt 1	25	11	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
barri_re_pierre	barrière pierre	13	6	true	default-ground-wide-ellipse	compactProp	0.2	0.74	0.5
parasol	parasol	4	4	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
lampadaire	lampadaire	3	5	true	default-ground-contact-blob	tallProp	0.2	0.8	0.55
rock_cliff_1	rock cliff 1	3	4	true	default-ground-wide-ellipse	building	0.2	0.72	0.48
rock_cliff_2	rock cliff  2	7	2	true	default-ground-wide-ellipse	compactProp	0.2	0.74	0.5
rock_cliff_3	rock cliff  3	9	3	true	default-ground-wide-ellipse	compactProp	0.2	0.74	0.5
arbre_pixellab_1	arbre  pixelLab 1	7	7	true	default-ground-soft-ellipse	null	0.25	null	null
arbre_pixellab_2	arbre  pixelLab 2	5	8	true	default-ground-soft-ellipse	null	0.25	null	null
panneau	panneau	3	3	true	default-ground-wide-ellipse	null	0.27	0.92	0.75
```

## 8. Inventaire Selbrume.json placements

Commande :

```bash
jq -r '[.. | objects | select(has("shadowOverride"))] as $placed | [$placed|length, ($placed|map(select(.shadowOverride != null))|length), ($placed|map(select(.shadowOverride == null))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Sortie :

```text
2105	0	2105
```

Calcul source shadow :

```text
total placements	source element has shadow	source element has no shadow
2105	        112	                1993
```

Synthese :

```json
{
  "map_total_placements": 2105,
  "map_source_shadow_placements": 112,
  "map_no_source_shadow_placements": 1993,
  "map_shadow_override_non_null": 0,
  "map_shadow_override_disabled": 0,
  "map_shadow_override_custom": 0,
  "map_inherit_no_override": 2105
}
```

Top elements places avec Shadow authoring :

| elementId | name | placements | family | profile |
| --- | --- | --- | --- | --- |
| arbre_pixellab_2 | arbre  pixelLab 2 | 49 | null | default-ground-soft-ellipse |
| arbre_pixellab_1 | arbre  pixelLab 1 | 46 | null | default-ground-soft-ellipse |
| lampadaire | lampadaire | 4 | tallProp | default-ground-contact-blob |
| selbrum_maison_4 | selbrum maison  4 | 2 | building | default-ground-wide-ellipse |
| selbrum_maison_3 | selbrum maison 3 | 1 | building | default-ground-wide-ellipse |
| selbrume_maison_5 | selbrume maison 5 | 1 | null | default-ground-soft-ellipse |
| selbrum_maison_1 | selbrum maison 1 | 1 | building | default-ground-wide-ellipse |
| selbrume_centre_pok_mon | selbrume centre pokémon | 1 | building | default-ground-wide-ellipse |
| selbrum_maison_7 | selbrum maison  7 | 1 | building | default-ground-wide-ellipse |
| panneau | panneau | 1 | null | default-ground-wide-ellipse |
| le_puits | le puits | 1 | building | default-ground-wide-ellipse |
| selbrum_maison_2 | selbrum maison  2 | 1 | building | default-ground-wide-ellipse |
| selbrum_maison_8 | selbrum maison  8 | 1 | building | default-ground-wide-ellipse |
| kiosque_l_gumes | kiosque à légumes | 1 | building | default-ground-wide-ellipse |
| test | test | 1 | building | default-ground-wide-ellipse |

Note : le runtime probe retourne 2104 sources car un placement est ignore par le builder runtime, probablement hors layer TileLayer visible ou sans frame/tileset exploitable. Les instructions finales sont 111.

## 9. Inventaire des instructions runtime generees

Probe runtime direct :

```text
SHADOW57_DIRECT manifestElements=63 placements=2105 sources=2104 instructions=111 groundStatic=111 actorContact=0
```

Inventaire detaille reconstruit depuis le code audite, avec `cellWidth = 96` et `cellHeight = 96` (`tileWidth 32 * displayScale 3`).

```json
{
  "by_shape": {
    "projectedPolygon": 111
  },
  "by_geometry_type": {
    "projectedPolygon": 101,
    "contactLedge": 10
  },
  "by_render_pass": {
    "groundStatic": 111
  },
  "by_profile": {
    "default-ground-soft-ellipse": 96,
    "default-ground-contact-blob": 4,
    "default-ground-wide-ellipse": 11
  },
  "by_family": {
    "genericProjection": 97,
    "tallProp": 4,
    "building": 10
  },
  "area_average": 120365.08,
  "area_max": 187303.33,
  "opacity_average": 0.24,
  "opacity_max": 0.27
}
```

Lecture produit :

- `projectedPolygon`: 111/111 instructions, donc 100% des ombres statiques.
- `genericProjection`: 97 instructions, dont 95 viennent des deux arbres.
- `contactLedge`: 10 instructions, uniquement buildings visibles places.
- `actorContact`: 0 dans cet inventaire statique Selbrume. Les actor contact shadows restent un systeme separe.

Top 30 plus grandes instructions :

```text
1. selbrume_maison_5 selbrume maison 5 placement=l_tile_maison_selbrume::36::16 area=187303.33 size=364.98x513.19 family=genericProjection geom=projectedPolygon opacity=0.22
2. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_38_8_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
3. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_43_15_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
4. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_47_19_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
5. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_45_22_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
6. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_47_22_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
7. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_45_24_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
8. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_48_33_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
9. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_7_2_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
10. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_19_2_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
11. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_32_2_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
12. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_14_3_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
13. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_25_3_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
14. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_43_13_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
15. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_12_14_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
16. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_9_0_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
17. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_22_0_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
18. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_30_0_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
19. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_35_0_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
20. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_42_0_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
21. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_4_0_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
22. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_20_4_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
23. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_8_5_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
24. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_14_5_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
25. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_22_5_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
26. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_44_5_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
27. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_19_6_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
28. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_25_6_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
29. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_32_6_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
30. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_11_7_arbre_pixellab_1 area=167985.36 size=364.04x461.45 family=genericProjection geom=projectedPolygon opacity=0.25
```

Top 30 plus opaques :

```text
1. panneau panneau placement=l_tile_maison_selbrume::22::24 opacity=0.27 area=36654.19 family=genericProjection geom=projectedPolygon
2. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_38_8_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
3. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_43_15_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
4. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_47_19_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
5. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_45_22_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
6. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_47_22_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
7. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_45_24_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
8. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_48_33_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
9. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_7_2_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
10. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_19_2_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
11. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_32_2_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
12. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_14_3_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
13. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_25_3_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
14. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_43_13_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
15. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_12_14_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
16. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_9_0_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
17. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_22_0_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
18. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_30_0_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
19. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_35_0_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
20. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_42_0_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
21. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_4_0_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
22. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_20_4_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
23. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_8_5_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
24. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_14_5_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
25. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_22_5_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
26. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_44_5_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
27. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_19_6_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
28. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_25_6_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
29. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_32_6_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
30. arbre_pixellab_1 arbre  pixelLab 1 placement=env_gen_env_area_foret_11_7_arbre_pixellab_1 opacity=0.25 area=167985.36 family=genericProjection geom=projectedPolygon
```

## 10. Top elements suspects

Il n'y a que 14 elements source qui produisent des instructions runtime statiques dans Selbrume. La table demandee "top 30" est donc complete avec ces 14 lignes.

| rank | elementId | elementName | frameWidth | frameHeight | placementCount | castsShadow | shadowProfileId | family | shapeKind | geometryType | renderPass | offsetX | offsetY | scaleX | scaleY | opacity | footprint summary | instructionCount | maxInstructionWidth | maxInstructionHeight | maxInstructionArea | suspicionReason | recommendedAction |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | panneau | panneau | 3 | 3 | 1 | true | default-ground-wide-ellipse | null | projectedPolygon | projectedPolygon | groundStatic | 0 | 0 | 0.92 | 0.75 | 0.27 | ax=0.5, ay=0.95, w=0.72, h=0.1 | 1 | 166.24 | 220.49 | 36654.19 | projectedPolygon rendu par drawPath; projection diagonale; family null/generic; aire grande; opacite elevee; petit prop a risque | disable |
| 2 | arbre_pixellab_1 | arbre  pixelLab 1 | 7 | 7 | 46 | true | default-ground-soft-ellipse | null | projectedPolygon | projectedPolygon | groundStatic | null | -10 | null | null | 0.25 | ax=0.5, ay=0.92, w=0.58, h=0.1 | 46 | 364.04 | 461.45 | 167985.36 | projectedPolygon; projection diagonale; family null/generic; aire tres grande; defaut multiplie | manual-review |
| 3 | arbre_pixellab_2 | arbre  pixelLab 2 | 5 | 8 | 49 | true | default-ground-soft-ellipse | null | projectedPolygon | projectedPolygon | groundStatic | null | -10 | null | null | 0.25 | ax=0.5, ay=0.92, w=0.5, h=0.1 | 49 | 327.53 | 330.66 | 108298.16 | projectedPolygon; projection diagonale; family null/generic; aire tres grande; defaut multiplie | manual-review |
| 4 | selbrume_maison_5 | selbrume maison 5 | 7 | 6 | 1 | true | default-ground-soft-ellipse | null | projectedPolygon | projectedPolygon | groundStatic | null | -6 | null | null | 0.22 | ax=0.5, ay=0.96, w=0.68, h=0.08 | 1 | 364.98 | 513.19 | 187303.33 | maison en family null -> projection diagonale massive | manual-review |
| 5 | lampadaire | lampadaire | 3 | 5 | 4 | true | default-ground-contact-blob | tallProp | projectedPolygon | projectedPolygon | groundStatic | 0 | 0 | 0.8 | 0.55 | 0.2 | ax=0.5, ay=1, w=0.28, h=0.05 | 4 | 68.47 | 52.86 | 3619.57 | projection diagonale sur prop fin | disable |
| 6 | selbrum_maison_8 | selbrum maison  8 | 11 | 6 | 1 | true | default-ground-wide-ellipse | building | projectedPolygon | contactLedge | groundStatic | 0 | 0 | 0.72 | 0.48 | 0.2 | ax=0.5, ay=0.98, w=0.6, h=0.06 | 1 | 656.92 | 22.99 | 15099.87 | contact ledge large, rendu drawPath | manual-review |
| 7 | selbrum_maison_3 | selbrum maison 3 | 8 | 7 | 1 | true | default-ground-wide-ellipse | building | projectedPolygon | contactLedge | groundStatic | 0 | 0 | 0.72 | 0.48 | 0.2 | ax=0.5, ay=0.98, w=0.6, h=0.06 | 1 | 477.76 | 23.48 | 11219.49 | contact ledge, rendu drawPath | manual-review |
| 8 | selbrume_centre_pok_mon | selbrume centre pokémon | 8 | 6 | 1 | true | default-ground-wide-ellipse | building | projectedPolygon | contactLedge | groundStatic | 0 | 0 | 0.72 | 0.48 | 0.2 | ax=0.5, ay=0.98, w=0.6, h=0.06 | 1 | 477.76 | 22.99 | 10981.72 | contact ledge, rendu drawPath | manual-review |
| 9 | selbrum_maison_2 | selbrum maison  2 | 6 | 7 | 1 | true | default-ground-wide-ellipse | building | projectedPolygon | contactLedge | groundStatic | 0 | 0 | 0.72 | 0.48 | 0.2 | ax=0.5, ay=0.98, w=0.6, h=0.06 | 1 | 358.32 | 23.48 | 8414.62 | contact ledge, rendu drawPath | manual-review |
| 10 | kiosque_l_gumes | kiosque à légumes | 6 | 6 | 1 | true | default-ground-wide-ellipse | building | projectedPolygon | contactLedge | groundStatic | 0 | 0 | 0.72 | 0.48 | 0.2 | ax=0.5, ay=0.98, w=0.6, h=0.06 | 1 | 358.32 | 22.99 | 8236.29 | contact ledge, rendu drawPath | manual-review |
| 11 | selbrum_maison_7 | selbrum maison  7 | 6 | 6 | 1 | true | default-ground-wide-ellipse | building | projectedPolygon | contactLedge | groundStatic | 0 | 0 | 0.72 | 0.48 | 0.2 | ax=0.5, ay=0.98, w=0.6, h=0.06 | 1 | 358.32 | 22.99 | 8236.29 | contact ledge, rendu drawPath | manual-review |
| 12 | selbrum_maison_4 | selbrum maison  4 | 5 | 6 | 2 | true | default-ground-wide-ellipse | building | projectedPolygon | contactLedge | groundStatic | 0 | 0 | 0.72 | 0.48 | 0.2 | ax=0.5, ay=0.98, w=0.6, h=0.06 | 2 | 298.60 | 22.99 | 6863.58 | contact ledge, rendu drawPath | manual-review |
| 13 | selbrum_maison_1 | selbrum maison 1 | 5 | 6 | 1 | true | default-ground-wide-ellipse | building | projectedPolygon | contactLedge | groundStatic | 0 | 0 | 0.72 | 0.48 | 0.2 | ax=0.5, ay=0.98, w=0.6, h=0.06 | 1 | 298.60 | 22.99 | 6863.58 | contact ledge, rendu drawPath | manual-review |
| 14 | le_puits | le puits | 4 | 5 | 1 | true | default-ground-wide-ellipse | building | projectedPolygon | contactLedge | groundStatic | 0 | 0 | 0.72 | 0.48 | 0.2 | ax=0.5, ay=0.98, w=0.6, h=0.06 | 1 | 238.88 | 22.49 | 5371.98 | contact ledge sur petit objet, rendu drawPath | manual-review |

## 11. Top instructions suspectes

La table suivante contient les 50 instructions runtime les plus suspectes selon score visuel. Les lignes 2 a 47 sont volontairement repetitives : elles montrent que le probleme le plus massif est la multiplication des ombres d'arbres en projection generique.

| rank | mapId | placementId/index | elementId | elementName | worldX | worldY | instructionLeft | instructionTop | instructionWidth | instructionHeight | instructionArea | opacity | shapeKind | renderPass | colorHexRgb | family | shadowProfileId | reason | recommendedAction |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Selbrume | l_tile_maison_selbrume::22::24 / 103 | panneau | panneau | 2112.00 | 2304.00 | 2219.99 | 2497.57 | 166.24 | 220.49 | 36654.19 | 0.27 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-wide-ellipse | projectedPolygon; projection diagonale; family null/generic; aire grande; opacite elevee; petit prop a risque | disable |
| 2 | Selbrume | env_gen_env_area_foret_38_8_arbre_pixellab_1 / 55 | arbre_pixellab_1 | arbre  pixelLab 1 | 3648.00 | 768.00 | 3910.43 | 1212.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 3 | Selbrume | env_gen_env_area_foret_43_15_arbre_pixellab_1 / 74 | arbre_pixellab_1 | arbre  pixelLab 1 | 4128.00 | 1440.00 | 4390.43 | 1884.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 4 | Selbrume | env_gen_env_area_foret_47_19_arbre_pixellab_1 / 79 | arbre_pixellab_1 | arbre  pixelLab 1 | 4512.00 | 1824.00 | 4774.43 | 2268.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 5 | Selbrume | env_gen_env_area_foret_45_22_arbre_pixellab_1 / 80 | arbre_pixellab_1 | arbre  pixelLab 1 | 4320.00 | 2112.00 | 4582.43 | 2556.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 6 | Selbrume | env_gen_env_area_foret_47_22_arbre_pixellab_1 / 81 | arbre_pixellab_1 | arbre  pixelLab 1 | 4512.00 | 2112.00 | 4774.43 | 2556.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 7 | Selbrume | env_gen_env_area_foret_45_24_arbre_pixellab_1 / 82 | arbre_pixellab_1 | arbre  pixelLab 1 | 4320.00 | 2304.00 | 4582.43 | 2748.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 8 | Selbrume | env_gen_env_area_foret_48_33_arbre_pixellab_1 / 85 | arbre_pixellab_1 | arbre  pixelLab 1 | 4608.00 | 3168.00 | 4870.43 | 3612.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 9 | Selbrume | env_gen_env_area_foret_7_2_arbre_pixellab_1 / 15 | arbre_pixellab_1 | arbre  pixelLab 1 | 672.00 | 192.00 | 934.43 | 636.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 10 | Selbrume | env_gen_env_area_foret_19_2_arbre_pixellab_1 / 17 | arbre_pixellab_1 | arbre  pixelLab 1 | 1824.00 | 192.00 | 2086.43 | 636.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 11 | Selbrume | env_gen_env_area_foret_32_2_arbre_pixellab_1 / 20 | arbre_pixellab_1 | arbre  pixelLab 1 | 3072.00 | 192.00 | 3334.43 | 636.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 12 | Selbrume | env_gen_env_area_foret_14_3_arbre_pixellab_1 / 25 | arbre_pixellab_1 | arbre  pixelLab 1 | 1344.00 | 288.00 | 1606.43 | 732.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 13 | Selbrume | env_gen_env_area_foret_25_3_arbre_pixellab_1 / 26 | arbre_pixellab_1 | arbre  pixelLab 1 | 2400.00 | 288.00 | 2662.43 | 732.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 14 | Selbrume | env_gen_env_area_foret_43_13_arbre_pixellab_1 / 71 | arbre_pixellab_1 | arbre  pixelLab 1 | 4128.00 | 1248.00 | 4390.43 | 1692.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 15 | Selbrume | env_gen_env_area_foret_12_14_arbre_pixellab_1 / 73 | arbre_pixellab_1 | arbre  pixelLab 1 | 1152.00 | 1344.00 | 1414.43 | 1788.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 16 | Selbrume | env_gen_env_area_foret_9_0_arbre_pixellab_1 / 2 | arbre_pixellab_1 | arbre  pixelLab 1 | 864.00 | 0.00 | 1126.43 | 444.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 17 | Selbrume | env_gen_env_area_foret_22_0_arbre_pixellab_1 / 7 | arbre_pixellab_1 | arbre  pixelLab 1 | 2112.00 | 0.00 | 2374.43 | 444.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 18 | Selbrume | env_gen_env_area_foret_30_0_arbre_pixellab_1 / 9 | arbre_pixellab_1 | arbre  pixelLab 1 | 2880.00 | 0.00 | 3142.43 | 444.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 19 | Selbrume | env_gen_env_area_foret_35_0_arbre_pixellab_1 / 11 | arbre_pixellab_1 | arbre  pixelLab 1 | 3360.00 | 0.00 | 3622.43 | 444.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 20 | Selbrume | env_gen_env_area_foret_42_0_arbre_pixellab_1 / 12 | arbre_pixellab_1 | arbre  pixelLab 1 | 4032.00 | 0.00 | 4294.43 | 444.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 21 | Selbrume | env_gen_env_area_foret_4_0_arbre_pixellab_1 / 0 | arbre_pixellab_1 | arbre  pixelLab 1 | 384.00 | 0.00 | 646.43 | 444.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 22 | Selbrume | env_gen_env_area_foret_20_4_arbre_pixellab_1 / 27 | arbre_pixellab_1 | arbre  pixelLab 1 | 1920.00 | 384.00 | 2182.43 | 828.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 23 | Selbrume | env_gen_env_area_foret_8_5_arbre_pixellab_1 / 35 | arbre_pixellab_1 | arbre  pixelLab 1 | 768.00 | 480.00 | 1030.43 | 924.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 24 | Selbrume | env_gen_env_area_foret_14_5_arbre_pixellab_1 / 37 | arbre_pixellab_1 | arbre  pixelLab 1 | 1344.00 | 480.00 | 1606.43 | 924.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 25 | Selbrume | env_gen_env_area_foret_22_5_arbre_pixellab_1 / 39 | arbre_pixellab_1 | arbre  pixelLab 1 | 2112.00 | 480.00 | 2374.43 | 924.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 26 | Selbrume | env_gen_env_area_foret_44_5_arbre_pixellab_1 / 40 | arbre_pixellab_1 | arbre  pixelLab 1 | 4224.00 | 480.00 | 4486.43 | 924.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 27 | Selbrume | env_gen_env_area_foret_19_6_arbre_pixellab_1 / 42 | arbre_pixellab_1 | arbre  pixelLab 1 | 1824.00 | 576.00 | 2086.43 | 1020.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 28 | Selbrume | env_gen_env_area_foret_25_6_arbre_pixellab_1 / 43 | arbre_pixellab_1 | arbre  pixelLab 1 | 2400.00 | 576.00 | 2662.43 | 1020.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 29 | Selbrume | env_gen_env_area_foret_32_6_arbre_pixellab_1 / 44 | arbre_pixellab_1 | arbre  pixelLab 1 | 3072.00 | 576.00 | 3334.43 | 1020.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 30 | Selbrume | env_gen_env_area_foret_11_7_arbre_pixellab_1 / 46 | arbre_pixellab_1 | arbre  pixelLab 1 | 1056.00 | 672.00 | 1318.43 | 1116.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 31 | Selbrume | env_gen_env_area_foret_22_7_arbre_pixellab_1 / 47 | arbre_pixellab_1 | arbre  pixelLab 1 | 2112.00 | 672.00 | 2374.43 | 1116.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 32 | Selbrume | env_gen_env_area_foret_24_8_arbre_pixellab_1 / 52 | arbre_pixellab_1 | arbre  pixelLab 1 | 2304.00 | 768.00 | 2566.43 | 1212.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 33 | Selbrume | env_gen_env_area_foret_31_8_arbre_pixellab_1 / 53 | arbre_pixellab_1 | arbre  pixelLab 1 | 2976.00 | 768.00 | 3238.43 | 1212.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 34 | Selbrume | env_gen_env_area_foret_33_8_arbre_pixellab_1 / 54 | arbre_pixellab_1 | arbre  pixelLab 1 | 3168.00 | 768.00 | 3430.43 | 1212.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 35 | Selbrume | env_gen_env_area_foret_47_8_arbre_pixellab_1 / 56 | arbre_pixellab_1 | arbre  pixelLab 1 | 4512.00 | 768.00 | 4774.43 | 1212.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 36 | Selbrume | env_gen_env_area_foret_8_9_arbre_pixellab_1 / 58 | arbre_pixellab_1 | arbre  pixelLab 1 | 768.00 | 864.00 | 1030.43 | 1308.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 37 | Selbrume | env_gen_env_area_foret_41_9_arbre_pixellab_1 / 60 | arbre_pixellab_1 | arbre  pixelLab 1 | 3936.00 | 864.00 | 4198.43 | 1308.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 38 | Selbrume | env_gen_env_area_foret_43_9_arbre_pixellab_1 / 61 | arbre_pixellab_1 | arbre  pixelLab 1 | 4128.00 | 864.00 | 4390.43 | 1308.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 39 | Selbrume | env_gen_env_area_foret_36_10_arbre_pixellab_1 / 65 | arbre_pixellab_1 | arbre  pixelLab 1 | 3456.00 | 960.00 | 3718.43 | 1404.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 40 | Selbrume | env_gen_env_area_foret_46_11_arbre_pixellab_1 / 68 | arbre_pixellab_1 | arbre  pixelLab 1 | 4416.00 | 1056.00 | 4678.43 | 1500.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 41 | Selbrume | env_gen_env_area_foret_48_11_arbre_pixellab_1 / 69 | arbre_pixellab_1 | arbre  pixelLab 1 | 4608.00 | 1056.00 | 4870.43 | 1500.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 42 | Selbrume | env_gen_env_area_foret_45_35_arbre_pixellab_1 / 93 | arbre_pixellab_1 | arbre  pixelLab 1 | 4320.00 | 3360.00 | 4582.43 | 3804.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 43 | Selbrume | env_gen_env_area_foret_4_5_arbre_pixellab_1 / 34 | arbre_pixellab_1 | arbre  pixelLab 1 | 384.00 | 480.00 | 646.43 | 924.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 44 | Selbrume | env_gen_env_area_foret_17_5_arbre_pixellab_1 / 38 | arbre_pixellab_1 | arbre  pixelLab 1 | 1632.00 | 480.00 | 1894.43 | 924.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 45 | Selbrume | env_gen_env_area_foret_17_10_arbre_pixellab_1 / 63 | arbre_pixellab_1 | arbre  pixelLab 1 | 1632.00 | 960.00 | 1894.43 | 1404.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 46 | Selbrume | env_gen_env_area_foret_48_43_arbre_pixellab_1 / 90 | arbre_pixellab_1 | arbre  pixelLab 1 | 4608.00 | 4128.00 | 4870.43 | 4572.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 47 | Selbrume | env_gen_env_area_foret_46_45_arbre_pixellab_1 / 92 | arbre_pixellab_1 | arbre  pixelLab 1 | 4416.00 | 4320.00 | 4678.43 | 4764.74 | 364.04 | 461.45 | 167985.36 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 48 | Selbrume | env_gen_env_area_foret_47_16_arbre_pixellab_2 / 75 | arbre_pixellab_2 | arbre  pixelLab 2 | 4512.00 | 1536.00 | 4706.70 | 2131.88 | 327.53 | 330.66 | 108298.16 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 49 | Selbrume | env_gen_env_area_foret_50_16_arbre_pixellab_2 / 76 | arbre_pixellab_2 | arbre  pixelLab 2 | 4800.00 | 1536.00 | 4994.70 | 2131.88 | 327.53 | 330.66 | 108298.16 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |
| 50 | Selbrume | env_gen_env_area_foret_50_18_arbre_pixellab_2 / 77 | arbre_pixellab_2 | arbre  pixelLab 2 | 4800.00 | 1728.00 | 4994.70 | 2323.88 | 327.53 | 330.66 | 108298.16 | 0.25 | projectedPolygon | groundStatic | 000000 | genericProjection | default-ground-soft-ellipse | projection diagonale family null/generic, aire massive | manual-review |

## 12. Diagnostic racine apres Shadow-56

Reponses obligatoires :

1. Apres Shadow-56, Selbrume genere encore 111 ombres statiques runtime.
2. Oui, ces ombres viennent du manifest authore : aucun override instance et aucun auto-apply runtime.
3. Oui, il reste des `projectedPolygon` : 111 instructions runtime ont cette shape.
4. La family la plus dangereuse dans Selbrume est `genericProjection`, parce que `family null` y tombe automatiquement et genere 97 instructions.
5. Les elements a desactiver en premier : `panneau`, puis `lampadaire`. Ensuite, reviser les arbres `arbre_pixellab_1` et `arbre_pixellab_2`.
6. Peu d'elements peuvent rester sans risque. Les actor contact shadows ne sont pas en cause. Les contact ledges de buildings sont moins catastrophiques que les projections d'arbres, mais doivent rester en manual-review.
7. Les buildings devraient rester sur une logique contact ledge minimal, mais pas tous les objets classes `building` ne sont forcement de vrais buildings (`le_puits`, `parasol`, `rock_cliff_1` dans project.json sont suspects meme s'ils ne sont pas tous visibles ici).
8. Oui, certains petits props ont encore des ombres : `panneau`, `lampadaire`, et potentiellement d'autres configs non placees ou non visibles.
9. Oui, les panneaux/lampadaires ont encore des ombres : 1 panneau + 4 lampadaires visibles en runtime.
10. Cause principale restante : configs authorees dangereuses, surtout `family null -> genericProjection` sur arbres et maison, plus des petits props qui gardent une projection.
11. Shadow-58 doit neutraliser les familles/projections dangereuses dans la policy et proposer un nettoyage cible des configs authorees Selbrume, sans retoucher le renderer.

## 13. Ce qui est maintenant prouve

- Le runtime n'applique plus la policy automatique.
- Selbrume a 0 `shadowOverride` instance.
- Les 111 instructions visibles viennent des configs source authorees.
- La collection runtime statique produit 111 instructions `groundStatic`.
- 100% des instructions statiques runtime sont rendues comme `projectedPolygon`.
- Les arbres generent 95 instructions et dominent le probleme visuel.
- Le panneau et le lampadaire sont de mauvais candidats a projection automatique.

## 14. Ce qui reste incertain

- Le script detaille reconstruit les dimensions par placement a partir des constantes auditees, car `ShadowRuntimeRenderInstruction` ne garde pas `elementId`, `family`, ni `shadowProfileId`. Le probe Flutter confirme le total runtime reel, mais les tables detaillees ajoutent les metadonnees par reconstruction.
- Les captures utilisateur peuvent inclure des zones hors viewport auditees ici, mais Selbrume.json complet a bien ete inventorie.
- Certaines configs `project.json` non placees ou ignorees par layer visible restent dangereuses pour de futures maps.

## 15. Recommandations pour Shadow-58

Shadow-58 doit etre un lot de stabilisation visuelle, pas un nouveau renderer.

Actions recommandees :

1. Desactiver par defaut les projections statiques pour `family null/genericProjection` dans les suggestions editor et les backfills.
2. Ajouter un audit/cleanup explicite pour les configs authorees de Selbrume les plus dangereuses, sans mutation runtime.
3. Neutraliser les ombres des petits props : panneau, lampadaire, barriere, rocks, parasol.
4. Mettre les arbres en `manual-review` ou en approche asset-driven ulterieure, pas en generic projection automatique.
5. Garder les buildings en contact ledge minimal, mais classer `le_puits`, `parasol`, `rock_cliff_*` hors building automatique.
6. Ne pas toucher au renderer tant que les donnees authorees dangereuses n'ont pas ete nettoyees.

## 16. Tests / commandes lancees

Commandes d'audit :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "applyElementAutoShadowPolicyToProject" packages/map_runtime packages/map_editor packages/map_core
rg -n "ShadowRuntimeRenderInstruction|ShadowRuntimeShapeKind|resolveStatic|runtimeStatic|staticPlaced|drawPath|drawOval|projectedPolygon|contactLedge" packages/map_runtime/lib/src packages/map_core/lib/src
jq -r '.elements | length' /Users/karim/Desktop/selbrume/project.json
jq -r '[.elements[] | select(.shadow != null)] | length' /Users/karim/Desktop/selbrume/project.json
jq -r '[.elements[] | select(.shadow == null)] | length' /Users/karim/Desktop/selbrume/project.json
jq -r '.elements[] | select(.shadow != null) | [.id, .name, (.frames[0].source.width // "?"), (.frames[0].source.height // "?"), (.shadow.castsShadow // "null"), (.shadow.shadowProfileId // "null"), (.shadow.family // "null"), (.shadow.opacity // "null"), (.shadow.scaleX // "null"), (.shadow.scaleY // "null")] | @tsv' /Users/karim/Desktop/selbrume/project.json
jq -r '[.. | objects | select(has("shadowOverride"))] as $placed | [$placed|length, ($placed|map(select(.shadowOverride != null))|length), ($placed|map(select(.shadowOverride == null))|length)] | @tsv' /Users/karim/Desktop/selbrume/maps/Selbrume.json
python3 /tmp/shadow57_inventory.py > /tmp/shadow57_inventory.md
cd packages/map_runtime && flutter test /tmp/shadow57_probe_test.dart --plain-name 'shadow57 probe'
```

Commandes de tests :

```bash
cd packages/map_runtime && flutter test test/application/load_runtime_map_bundle_shadow_policy_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_core && dart test test/shadow
cd packages/map_editor && flutter test test/application/shadow
```

## 17. Resultats des tests

Test cible load runtime Shadow-56 :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/application/load_runtime_map_bundle_shadow_policy_test.dart
00:00 +0: loadProjectManifestFromFile authored shadow manifest keeps missing shadow configs absent at runtime load
00:00 +1: loadProjectManifestFromFile authored shadow manifest preserves recognized old auto shadows as authored data
00:00 +2: loadProjectManifestFromFile authored shadow manifest preserves manual and disabled shadows
00:00 +3: All tests passed!
```

Ligne finale runtime shadow :

```text
00:02 +233: All tests passed!
```

Ligne finale map_core shadow :

```text
00:00 +283: All tests passed!
```

Ligne finale map_editor application shadow :

```text
00:00 +96: All tests passed!
```

## 18. git diff --stat

Commande finale :

```bash
git diff --stat
```

Sortie finale :

```text
```

Le rapport est non suivi. `git diff --stat` ne liste pas les fichiers non suivis tant qu'ils ne sont pas stages.

## 19. git diff --name-status

Commande finale :

```bash
git diff --name-status
```

Sortie finale :

```text
```

Le rapport est non suivi. `git diff --name-status` ne liste pas les fichiers non suivis tant qu'ils ne sont pas stages.

## 20. git diff --check

Commande finale :

```bash
git diff --check
```

Sortie finale :

```text
```

Aucune modification suivie n'existe.

## 21. git status final

Commande finale :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? reports/shadows/shadow_lot_57_selbrume_shadow_inventory_runtime_instruction_debug_report.md
```

## 22. Risques / reserves

- La cause visuelle principale est maintenant dans les donnees authorees. Un lot de code seul ne suffira pas si les configs Selbrume restent dangereuses.
- Les projections polygonales peuvent rester utiles pour quelques cas asset-driven, mais elles sont trop dangereuses comme comportement par defaut.
- Les buildings en contact ledge sont moins mauvais, mais encore rendus via `drawPath` et peuvent former des rectangles trop visibles sur chemins clairs.
- Les arbres demandent probablement une solution artistique separee : soit pas d'ombre, soit sprite shadow asset, soit contact tres discret, mais pas generic projection.

## 23. Auto-critique

- L'audit ne corrige volontairement rien.
- Le probe runtime direct confirme les totaux mais pas chaque ligne de table, car les instructions finales ne gardent pas l'element source. J'ai donc reconstruit les metadonnees depuis le placement et l'element source.
- La table des 50 instructions suspectes est repetitive, mais c'est precisement une preuve du probleme : deux elements d'arbres multiplient la meme mauvaise projection.
- Le prochain lot doit resister a la tentation de rajouter une nouvelle couche. Il doit d'abord reduire le bruit visuel.

## 24. Regard critique sur le prompt

Le prompt est sain : il impose un audit avant de continuer a coder. La seule difficulte est la demande "instructions runtime reellement generees" alors que le modele runtime ne conserve pas les metadonnees source. Pour satisfaire l'intention, j'ai combine :

- probe runtime direct pour le total reel ;
- reconstruction detaillee depuis sources, configs et constantes auditees ;
- classement explicite des limites.

## 25. Proposition de prompt pour Shadow-58

```md
# Shadow-58 - Disable Unsafe Authored Static Shadows / Selbrume Recovery Pass V0

Objectif :

Rendre Selbrume immediatement moins moche en neutralisant les configs Shadow authorees les plus dangereuses identifiees par Shadow-57, sans retoucher au renderer et sans reactiver d'auto-apply runtime.

Périmètre :

- Ne pas modifier map_runtime renderer.
- Ne pas modifier les profils Shadow globaux.
- Ne pas modifier la geometrie core.
- Ne pas modifier les fichiers Selbrume directement sans instruction explicite.
- Ajouter de preference un outil/audit ou une action editor explicite permettant de lister et neutraliser les configs dangereuses.

Cibles prioritaires :

- `panneau`: disable static shadow.
- `lampadaire`: disable static projected shadow, conserver seulement actor/player contact shadows si applicable.
- `arbre_pixellab_1` et `arbre_pixellab_2`: retirer `family null -> genericProjection`; classer manual-review ou disable pour Selbrume.
- `selbrume_maison_5`: convertir en building/contact ledge minimal ou manual-review, mais ne pas rester en genericProjection.

Critère produit :

Mieux vaut aucune ombre qu'une mauvaise ombre.

Tests :

- les shadows runtime continuent de consommer le manifest authore ;
- aucun auto-apply runtime ;
- les elements unsafe ne produisent plus de projectedPolygon massif dans l'audit Selbrume ;
- actor contact shadows restent intactes.
```
