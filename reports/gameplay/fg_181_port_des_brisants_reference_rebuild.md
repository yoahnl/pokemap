# FG-181 — Port des Brisants reference rebuild

## Résumé exécutif

Le sous-lot visuel `map_port_brisants` a été repris depuis la référence utilisateur, sans underlay runtime et sans modifier une autre carte. Le résultat est une map PokeMap native de 45×34 cellules avec 68 placements, 35 éléments Port normalisés, trois quais jouables, une côte continue, une forêt déterministe via Environment, le preset existant `pavement_path` réellement rendu et une mer organique de huit frames.

Le verdict produit est **GO pour les demandes finales pavement/eau**. La map reste volontairement `candidate_pending_owner_approval` et n’est pas présentée comme une reproduction 1:1 : la connexion réciproque vers le Bourg impose une sortie nord centrée, contrairement à la sortie nord-est de l’image.

Le lot roadmap parent `FG-181 — Golden Slice Fangame Fixture V0` reste **PARTIAL**. Cette carte ne fournit pas à elle seule la mini-aventure, le starter, les combats, la capture, le shop/heal, le badge/field unlock et le walkthrough exigés par le DoD.

## Scope confirmé

- Carte modifiée : `map_port_brisants` uniquement.
- Manifeste partagé modifié uniquement pour enregistrer les nouveaux assets/presets Environment/eau du Port.
- Aucun autre JSON de map modifié.
- Aucun worktree séparé, conformément à la correction explicite du propriétaire.
- Les events, dialogues, combats et mécaniques ne sont pas implémentés dans ce sous-lot.
- Après le dernier retour propriétaire, aucune modification supplémentaire de collision n’a été faite. Le skill traite désormais les collisions existantes comme gelées et exige un lot explicitement autorisé pour toute évolution future.
- Le fichier préexistant `examples/playable_runtime_host/pubspec.lock` reste hors scope, non restauré et non inclus au commit.

## Audit du prompt et décision de scope

La demande initiale couvrait toutes les maps de la bêta, puis le propriétaire a explicitement demandé de repartir du début et de ne traiter que le Port des Brisants. Cette réduction a été retenue comme instruction la plus récente et la plus sûre.

L’audit initial a établi :

1. La map précédente possédait surtout des aplats herbe/route et manquait de masses architecturales, côtières et portuaires.
2. Le projet contient un vrai système Environment, qui devait produire la forêt au lieu de simples arbres manuels.
3. Le preset natif `pavement_path` et son tileset existaient déjà ; les copies temporaires du pavé étaient donc redondantes.
4. Le runtime peignait historiquement tous les paths avant tous les tile layers, ce qui faisait recouvrir le pavé éditable par le sol. Une option strictement limitée à la première couche de sol était nécessaire.
5. Les contrats à préserver étaient la connexion nord vers `map_bourg_selbrume`, 3 entités, 4 triggers, 2 gameplay zones et les IDs `pe_port_bateau`, `pe_port_hangar`, `pe_port_nid_goelise`.
6. L’eau Port précédente utilisait des tirets horizontaux intermittents ; elle manquait de courbure, de profondeur et de continuité perceptuelle.
7. La référence devait rester `reference-only`, hashée et interdite comme underlay.

## État Git initial

Branche : `main`.

Changement préexistant hors scope observé et conservé :

```text
 M examples/playable_runtime_host/pubspec.lock
```

Les changements Port listés plus bas appartiennent au présent sous-lot. Aucun `git reset`, `restore`, `stash` ou worktree n’a été utilisé.

## Verdicts des sub-agents / passes indépendantes

| Passe | Mission | Verdict |
|---|---|---|
| Audit / architecture | Contrats de map, pavement natif, atlas et couches runtime | PASS : base herbe → pavement natif → eau, atlas sol 2112×32, suppression des copies pavées |
| Skill forward test | Appliquer le skill comme si la map n’était pas encore construite | PASS avec gates stricts : provenance, brief, Environment, eau, round-trip et nettoyage hash-locké |
| Eau | Diagnostiquer l’animation et proposer un mouvement naturel minimal | PASS : 72 vaguelettes persistantes, arcs brisés, ombre, pulse progressif, dérive locale ≤1 px |
| Implémentation | Revue indépendante du diff et des artefacts générés | PASS : assets/map déterministes, 68 placements, contrats narratifs et Environment cohérents |
| Tests / rendu différé | Revue de `paintAfterTileLayerId` | Premier verdict P1 corrigé : le path ne recouvre plus les éléments placés et les ombres conservent leur ordre |
| Build / validation | Rejouer checks, tests skill et validateur authored | PASS : assets/map à jour, 10 tests skill, maps valides ; quick validator bloqué par PyYAML absent |
| QA visuelle finale | Comparer capture, cible et GIF d’eau | GO : pavement 4,5/5, eau 4,1/5, style 4,5/5, identité 4,5/5 |
| Critique finale | Chercher effets de bord, fichiers accidentels et affirmations non prouvées | GO fonctionnel après correction des P1 ; retouches documentaires finales appliquées avant staging explicite. Candidate et FG-181 restent PARTIAL |

## Architecture et décisions

### Map native

- 11 couches PokeMap : terrain sémantique, sol, pavement, eau, décors au sol, backdrop, 2 Environment layers, overhead, structures, collisions.
- 382 cellules de pavement utilisent `pavement_path` ; aucune texture copiée n’est incluse dans l’atlas sol.
- 560 cellules d’eau utilisent `path_selbrume_port_water_v3` en `always_active`.
- 11 placements de forêt proviennent du vrai use case Environment, avec seeds et IDs stables.
- Les bâtiments, quais, bateaux, côte, mousse et props sont des `ProjectElementEntry` / `MapPlacedElement`, pas une image plein écran.
- `referenceRuntimeUnderlay=false` est persisté et testé.

### Pavement éditable

Le runtime garde son comportement historique sauf lorsqu’un path cible explicitement la première couche tile visible via `paintAfterTileLayerId`. Dans ce cas précis :

```text
terrain / eau / surfaces
→ pixels du sol cible
→ path pavement différé
→ ombres
→ éléments placés du sol
→ autres tile layers / éléments / entités
```

Le garde-fou limite l’option à la première couche de fond non-foreground. Une cible absente, invisible, overhead ou plus haute retombe sur le comportement historique.

### Eau organique

- Fond bleu accepté immobile.
- 8 frames de 256×256 px, 180 ms chacune, boucle 1,44 s.
- Vaguelettes courbes, fragmentées et persistantes.
- Intensité `1,1,2,3,3,2,1,1` ; rare éclat clair.
- Ombre sous la crête et dérive horizontale maximale d’un pixel.
- Pas de scroll global, pas de disparition pendant la moitié de la boucle.
- Coutures spatiales exactes et transition frame 7→0 testée.

## Inventaire complet des fichiers

### Fichiers modifiés

| Fichier | Zones modifiées | Raison / impact |
|---|---|---|
| `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart` | ordre des passes terrain/path/ombres/éléments | Donner à l’éditeur le même rendu opt-in que le runtime sans changer les maps historiques |
| `packages/map_editor/test/map_grid_painter_test.dart` | test pixel pavement/sol/prop/structure | Prouver la parité éditeur et la hiérarchie visuelle complète |
| `packages/map_editor/test/selbrume_editor_repository_roundtrip_test.dart` | tailles/compteurs attendus | Prouver le round-trip des 722 placements, dont 68 au Port |
| `packages/map_editor/tool/generate_selbrume_canonical_maps.dart` | contrat authored Port | Valider 45×34, couches v3, placements et Environment |
| `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart` | `render`, helpers tile/collision | Rendre un path éditable au-dessus du premier sol sans recouvrir props/ombres/structures |
| `packages/map_runtime/test/map_layers_component_path_pattern_render_test.dart` | tests d’ordre path/sol/prop/structure/cible invalide | Positif, négatif et non-régression de l’option runtime ; animation explicitement `alwaysActive` |
| `packages/map_runtime/test/path_pattern_water_animated_runtime_golden_slice_test.dart` | fixture PathLayer animée | Expliciter `alwaysActive` pour tester une eau réellement active au lieu du mode triggered statique |
| `packages/map_runtime/test/selbrume_asset_integrity_contract_test.dart` | famille Port v3 | Vérifier atlas, provenance, 35 éléments et eau 8×180 ms ; ancien contrat documenté/skippé |
| `packages/map_runtime/test/selbrume_map_catalog_integrity_test.dart` | contrat Port | Taille, 11 couches, types, zones et landmarks |
| `packages/map_runtime/test/selbrume_map_navigation_contract_test.dart` | ancres/navigation Port | Prouver accès, quais passables et bassin bloqué sur l’empreinte complète du bateau dérivée du sprite |
| `packages/map_runtime/test/selbrume_map_render_smoke_test.dart` | rendu Port | Charger/rendre les nouveaux assets/landmarks |
| `packages/map_runtime/test/support/selbrume_map_test_fixture.dart` | fixture Port | Dimensions, tilesets et landmarks v3 |
| `packages/map_runtime/tool/selbrume_map_capture_test.dart` | crops Port | Captures reproductibles overview/collision/nest/bateau/hangar |
| `selbrume/maps/map_port_brisants.json` | map complète générée | Carte 45×34, 11 couches et 68 placements ; état collision produit avant le dernier gel propriétaire, sans retouche ultérieure |
| `selbrume/project.json` | catalogues Port | 3 tilesets v3, 35 éléments, eau/pattern, 2 presets Environment |
| `skills/creating-pokemap-maps-from-reference/SKILL.md` | gates et workflow collisions | Geler les collisions existantes, valider en lecture seule et arrêter plutôt que déduire une géométrie depuis l’image |
| `skills/creating-pokemap-maps-from-reference/scripts/audit_project_asset_usage.py` | classification provenance/sources et exclusion du manifeste | Interdire la suppression des provenances, reconnaître `sources/` et rendre l’audit hash-locké reproductible |
| `skills/creating-pokemap-maps-from-reference/scripts/test_scripts.py` | tests provenance, `sources/`, auto-référence et apply | Non-régressions destructives du skill |

`examples/playable_runtime_host/pubspec.lock` est explicitement exclu : modification préexistante et sans rapport.

### Fichiers texte créés

- `packages/map_editor/tool/build_selbrume_port_reference_assets.dart` — builder déterministe des trois atlas et de leur provenance.
- `packages/map_editor/tool/rebuild_selbrume_port_brisants_from_reference.dart` — rebuild déterministe map/manifeste, Environment et contrats.
- `packages/map_editor/test/selbrume_port_reference_assets_builder_test.dart` — alpha, dimensions, déterminisme, eau et provenance.
- `packages/map_editor/test/selbrume_port_reference_rebuild_test.dart` — map native, gameplay, layers, pavement, eau et déterminisme.
- `reports/gameplay/evidence/fg_181_selbrume_port_rebuild/reference_brief.md` — brief complet.
- `reports/gameplay/evidence/fg_181_selbrume_port_rebuild/reference_inventory.json` — inventaire strict de la référence.
- `reports/gameplay/evidence/fg_181_selbrume_port_rebuild/reference_provenance.json` — autorisation/provenance de la référence.
- `reports/gameplay/evidence/fg_181_selbrume_port_rebuild/asset_usage.json` — audit de 5660 fichiers, zéro candidat final à supprimer.
- `reports/gameplay/annexes/fg_181_selbrume_port_rebuild_created_text_files_full_content.txt` — contenu complet regroupé des fichiers texte créés, hors auto-inclusion impossible.
- `reports/gameplay/fg_181_port_des_brisants_reference_rebuild.md` — présent rapport.
- `selbrume/assets/provenance/selbrume_port_reference_v3.json` — briefs/synthèses de prompts, sources, hashes, atlas et 35 rectangles.

Le contenu complet des neuf fichiers texte créés hors rapport est regroupé dans l’annexe dédiée indiquée ci-dessus (55 358 lignes, 1 761 710 octets, SHA `7ef0032b0c28dff11a7914d840e83e2b6ee4eade5948a0c9e9456988250254a4`). L’annexe ne s’inclut pas elle-même et le présent rapport reste la source de vérité pour son propre contenu afin d’éviter une récursion sans fin. Les binaires sont inventoriés ci-dessous avec dimensions et hashes.

### Preuves raster durables créées

```text
reports/gameplay/evidence/fg_181_selbrume_port_rebuild/
  map_port_brisants_overview.png   1440×1088  SHA 4d1bc78e…d57e
  map_port_brisants_collision.png  1440×1088  SHA b502df85…5939
  water_organic.gif                512×512    SHA 7c093940…a5a
```

### Assets raster créés

Sources normalisées :

```text
selbrume/assets/sources/port_reference_v3/
  architecture_sheet_alpha.png
  architecture_sheet_chroma.png
  coast_sheet_alpha.png
  coast_sheet_chroma.png
  docks_boats_sheet_alpha.png
  docks_boats_sheet_chroma.png
  grass_texture_owner.png
  natural_coast_alpha.png
  natural_coast_chroma.png
  nature_sheet_alpha.png
  nature_sheet_chroma.png
  nest_alpha.png
  nest_chroma.png
  shore_foam_alpha.png
  shore_foam_chroma.png
  small_harbor_props_alpha.png
  small_harbor_props_chroma.png
  small_props_alpha.png
  small_props_chroma.png
```

Sorties runtime :

```text
selbrume/assets/tilesets/port_reference_v3/
  selbrume_port_reference_v3.png   1536×1408  SHA e097f0a1…8952
  selbrume_port_ground_v3.png      2112×32    SHA 444251b7…617
  selbrume_port_water_v3.png       2048×256   SHA 61399414…56f6
```

### Assets supprimés

```text
selbrume/assets/sources/port_reference_v3/pavement_path_a.png
selbrume/assets/sources/port_reference_v3/pavement_path_b.png
```

Ces deux copies non suivies n’étaient plus référencées après le passage au preset natif. Le dry-run final du skill classe les 5660 fichiers restants : 5546 runtime-used, 105 reference-retained, 8 test-only, 1 atlas-source-used, 0 delete. Deux exécutions successives ont produit des bytes identiques : SHA fichier `103dcf3ff5388c54b7b8836bde08ed27310fb3523e85d71c2666c90302d28674`, hash canonique `bcfa7727fac97edcf19cbd7836c72af8be6052f41ae4e75c1c8fe0c4fb612126`. Le manifeste lui-même est exclu du scan/fingerprint ; l’annexe de contenu complet, située hors de la racine de preuve scannée, ne peut pas protéger artificiellement un asset.

Commande exécutée deux fois à l’identique avec `--force` :

```text
PYTHONDONTWRITEBYTECODE=1 python3 \
  skills/creating-pokemap-maps-from-reference/scripts/audit_project_asset_usage.py \
  --project-root selbrume --asset-root assets --dry-run \
  --manifest reports/gameplay/evidence/fg_181_selbrume_port_rebuild/asset_usage.json \
  --test-root packages/map_editor/test \
  --test-root packages/map_runtime/test \
  --test-root examples/playable_runtime_host/test \
  --reference-root packages/map_editor/tool \
  --reference-root packages/map_runtime/tool \
  --reference-root reports/gameplay/evidence/fg_181_selbrume_port_rebuild \
  --reference-root selbrume/assets \
  --reference-root /Users/karim/Desktop/assets/Selbrume/chatGPT/map/map_port_brisants \
  --force
```

## Tests créés ou modifiés

### Red/green ciblé

- Atlas sol attendu 2112×32 : RED à 2240×32, puis GREEN après retrait des copies pavées.
- Pavement visible : RED (`false`), puis GREEN avec `pavement_path` natif.
- Eau courbe/ombrée : test des paires diagonales et de l’ombre, GREEN après le nouvel algorithme.
- Path au-dessus du sol : RED (pixel vert au lieu du pavé), puis GREEN.
- Parité éditeur : RED (sol opaque au lieu du pavé), puis GREEN avec la même option étroite que le runtime.
- Prop posé sur le sol cible : RED (pavé au lieu du prop), puis GREEN après séparation tile/path/shadow/placed-elements.
- Masques pavement/eau : RED sur une cellule côtière masquée, puis GREEN avec 0 intersection.
- Audit auto-référent : RED sur deux manifests successifs, puis GREEN après exclusion explicite du manifeste du scan et du fingerprint.
- Répertoire `sources/` : RED classé `delete`, puis GREEN classé `atlas-source-used`.

### Commandes et résultats

```text
cd packages/map_editor
flutter test test/selbrume_port_reference_assets_builder_test.dart \
  test/selbrume_port_reference_rebuild_test.dart \
  test/selbrume_editor_repository_roundtrip_test.dart \
  test/map_grid_painter_test.dart
→ exit 0, 20 tests passed

cd packages/map_runtime
flutter test test/map_layers_component_path_pattern_render_test.dart \
  test/map_layers_component_render_pass_test.dart \
  test/surface/surface_runtime_ordering_test.dart \
  test/shadow/shadow_runtime_renderer_integration_test.dart
→ exit 0, 25 tests passed

cd packages/map_runtime
flutter test test/selbrume_map_catalog_integrity_test.dart \
  test/selbrume_map_navigation_contract_test.dart \
  test/selbrume_map_render_smoke_test.dart \
  test/selbrume_asset_integrity_contract_test.dart
→ exit 0, 83 tests passed, 1 documented legacy test skipped

cd packages/map_runtime
SELBRUME_MAP_CAPTURE_OUTPUT_DIR=/tmp/selbrume-port-v7-capture \
SELBRUME_MAP_CAPTURE_MAP_IDS=map_port_brisants \
SELBRUME_MAP_CAPTURE_LOGICAL_TILE_PX=32 \
flutter test tool/selbrume_map_capture_test.dart
→ exit 0, 1 test passed, 5 PNG generated

PYTHONDONTWRITEBYTECODE=1 python3 -m unittest \
  skills/creating-pokemap-maps-from-reference/scripts/test_scripts.py -v
→ exit 0, 10 tests passed en 1,082 s
```

Une première tentative de lancer simultanément les deux groupes runtime a échoué avant exécution des tests : les deux processus Flutter partageaient `build/native_assets` et l’un a retiré un fichier temporaire utilisé par l’autre (`native_assets.json` / `objective_c.dylib`). Les mêmes commandes ont été relancées séquentiellement, sans `flutter clean`, et ont produit les résultats verts de 25 puis 83 tests ci-dessus. Ce conflit d’orchestration n’est pas présenté comme un échec produit.

```text
cd packages/map_runtime
flutter test
→ exit 1, 1600 tests passed, 1 skipped, 2 failed
→ seules erreurs restantes :
  p6_selbrume_beta_validator_pass_test.dart:130
  p6_selbrume_first_trainer_battle_golden_slice_test.dart:67
→ les deux attendent `metapod`, tandis que le manifest HEAD contient déjà `dratini` ;
  échec préexistant, hors Port, reproduit isolément

flutter test test/path_pattern_water_animated_runtime_golden_slice_test.dart
→ passe dans la relance isolée après explicitation de `alwaysActive`
```

## Génération, checks et validation authored

```text
cd packages/map_editor
dart run tool/build_selbrume_port_reference_assets.dart \
  --project-root ../../selbrume --write
dart run tool/build_selbrume_port_reference_assets.dart \
  --project-root ../../selbrume --check
→ exit 0, Port reference assets are up to date.

dart run tool/rebuild_selbrume_port_brisants_from_reference.dart \
  --project-root ../../selbrume --write
dart run tool/rebuild_selbrume_port_brisants_from_reference.dart \
  --project-root ../../selbrume --check
→ exit 0, 68 placements, 35 reference elements, up to date.

dart run tool/generate_selbrume_canonical_maps.dart \
  --project-root ../../selbrume --validate-authored
→ exit 0, Selbrume authored maps are valid.

dart run tool/generate_selbrume_canonical_maps.dart \
  --project-root ../../selbrume --through task16 --check
→ exit 2 attendu : divergence historique sur `map_bourg_selbrume.json`,
  `map_port_brisants.json` et `project.json`.
→ ce générateur legacy n’est pas le check Port ; aucun `--write-historical` lancé.
```

Deux writes consécutifs et le check propre produisent les mêmes bytes et les mêmes IDs Environment.

## Analyse et build

```text
cd packages/map_editor
dart analyze \
  lib/src/ui/canvas/map_canvas/map_grid_painter.dart \
  test/map_grid_painter_test.dart \
  test/selbrume_editor_repository_roundtrip_test.dart \
  test/selbrume_port_reference_assets_builder_test.dart \
  test/selbrume_port_reference_rebuild_test.dart \
  tool/generate_selbrume_canonical_maps.dart \
  tool/build_selbrume_port_reference_assets.dart \
  tool/rebuild_selbrume_port_brisants_from_reference.dart
→ exit 0, 6 infos `prefer_const_constructors`, dont la ligne 968 du nouveau
  test painter ; 0 warning, 0 error

cd packages/map_runtime
dart analyze \
  lib/src/presentation/flame/map_layers_component.dart \
  test/map_layers_component_path_pattern_render_test.dart \
  test/path_pattern_water_animated_runtime_golden_slice_test.dart \
  test/selbrume_asset_integrity_contract_test.dart \
  test/selbrume_map_catalog_integrity_test.dart \
  test/selbrume_map_navigation_contract_test.dart \
  test/selbrume_map_render_smoke_test.dart \
  test/support/selbrume_map_test_fixture.dart \
  tool/selbrume_map_capture_test.dart
→ exit 0, 18 infos `prefer_const_constructors`, dont la ligne 217 du test
  path modifié ; 0 warning, 0 error

cd packages/map_runtime
flutter analyze
→ exit 1, 348 infos lint préexistantes, 0 warning/error rapporté

cd packages/map_editor
flutter analyze
→ exit 1, 452 issues dont des erreurs préexistantes dans
  pokemon_sdk_move_catalog_converter.dart et sync_pokemon_sdk_moves_catalog_use_case.dart ;
  aucun fichier du lot dans les erreurs

cd packages/map_editor
flutter build macos --debug
→ exit 0, ✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Le `quick_validate.py` système du skill retourne exit 1 avant validation avec `ModuleNotFoundError: No module named 'yaml'`. Aucun package n’a été installé silencieusement. Les 10 tests fonctionnels du skill passent.

## Preuves visuelles

- Overview final : `reports/gameplay/evidence/fg_181_selbrume_port_rebuild/map_port_brisants_overview.png`, 1440×1088, SHA `4d1bc78e…d57e`.
- Collision : `reports/gameplay/evidence/fg_181_selbrume_port_rebuild/map_port_brisants_collision.png`, 1440×1088, SHA `b502df85…5939`.
- Eau animée : `reports/gameplay/evidence/fg_181_selbrume_port_rebuild/water_organic.gif`, 512×512, 8 frames, SHA `7c093940…a5a`.

Scores indépendants : composition stricte 3,5/5 ; style 4,5/5 ; navigation 4,2/5 ; identité 4,5/5 ; finition 4,0/5 ; pavement 4,5/5 ; eau 4,1/5.

## Limites conservées

- Sortie nord centrée pour préserver la connexion réciproque avec le Bourg.
- Quais plus symétriques que la référence pour conserver les routes/collisions existantes.
- Canopée nord moins profonde et pointe sud-est plus sableuse que l’objectif.
- Candidate non marquée `approved` avant retour explicite sur la capture finale.
- Aucun event/combat/dialogue/quest ajouté.
- Les anciens assets Port suivis restent conservés quand des générateurs/tests historiques les référencent ; le nettoyage final n’a aucun candidat sûr restant.

## Auto-critique et risques

1. La fidélité de composition n’atteint pas 4/5 strict : le résultat est un Port jouable inspiré fidèlement, pas un décalque.
2. `paintAfterTileLayerId` est un contrat opt-in consommé à la fois par l’éditeur et le runtime, mais pas un champ de modèle typé. Les tests pixel couvrent la chaîne actuelle ; une généralisation future devrait devenir un vrai contrat de couche.
3. Les sources image générées sont volumineuses mais nécessaires à la reproductibilité/provenance ; les copies réellement redondantes ont été supprimées.
4. L’analyse globale des packages n’est pas verte à cause de dette hors scope. Les fichiers touchés sont analysés proprement et le build macOS passe.
5. Le GIF QA peut introduire un léger miroitement de quantification absent de l’atlas PNG consommé en jeu.
6. La couche collision actuellement versionnée a été produite avant le dernier retour propriétaire. Elle n’a pas été retouchée ensuite ; le skill interdit désormais toute nouvelle déduction ou réécriture de collision sans autorisation séparée.

## Prochaines étapes proposées, non implémentées

1. Obtenir l’approbation explicite de la capture finale et seulement alors passer le statut provenance à `approved`.
2. Si une dernière passe visuelle est demandée : densifier légèrement la canopée nord, casser la symétrie des quais et rocheifier la pointe sud-est, sans déplacer la connexion.
3. Traiter séparément les erreurs globales Pokémon SDK avant de réclamer une analyse package entièrement verte.
4. Continuer FG-181 avec les mécaniques et le walkthrough ; ne pas marquer le lot parent DONE sur la seule base de cette map.

## Annexes — contenu complet des petits fichiers de preuve créés

### `reference_provenance.json`

```json
{
  "schemaVersion": 1,
  "assets": {
    "ChatGPT Image Jun 6, 2026, 07_10_04 PM.png": {
      "source": "user-supplied Port des Brisants objective image",
      "license": "user-authorized reference and derivative asset use for Selbrume",
      "status": "approved"
    }
  }
}
```

### `reference_inventory.json`

```json
{
  "schemaVersion": 1,
  "rootLabel": "map_port_brisants_reference",
  "summary": {
    "imageCount": 1,
    "totalBytes": 2984552,
    "duplicateGroupCount": 0,
    "decodeErrorCount": 0,
    "inspectionWarningCount": 0,
    "missingProvenanceCount": 0,
    "unapprovedProvenanceCount": 0,
    "realTransparencyCount": 0
  },
  "duplicateGroups": [],
  "decodeErrors": [],
  "inspectionWarnings": [],
  "missingProvenance": [],
  "unapprovedProvenance": [],
  "assets": [
    {
      "path": "ChatGPT Image Jun 6, 2026, 07_10_04 PM.png",
      "sizeBytes": 2984552,
      "sha256": "25fdc9419850028a6e79787ac53dd8e34dcf457ed2d90c1126b5e9b60ecfb219",
      "provenance": {
        "source": "user-supplied Port des Brisants objective image",
        "license": "user-authorized reference and derivative asset use for Selbrume",
        "status": "approved"
      },
      "format": "png",
      "width": 1448,
      "height": 1086,
      "bitDepth": 8,
      "colorType": 2,
      "declaresAlpha": false,
      "alphaInspection": "not-applicable",
      "transparentPixels": null,
      "translucentPixels": null
    }
  ]
}
```

## État Git final avant commit

État porcelain réel après validations et avant staging :

```text
19 entrées `M`  : 18 fichiers du scope + le lock hors scope ci-dessous
36 entrées `??` : 36 fichiers du scope, tous inventoriés dans ce rapport
0 entrée staged, deleted ou renamed
```

La liste de staging est construite explicitement à partir des 54 fichiers du scope ; `git add .` n’est pas utilisé. Après commit/push, le seul changement attendu et à vérifier comme non committé est :

```text
 M examples/playable_runtime_host/pubspec.lock
```
