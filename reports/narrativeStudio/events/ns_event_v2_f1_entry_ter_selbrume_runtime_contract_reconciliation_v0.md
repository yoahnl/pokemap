# NS-EVENT-V2 - F1-ENTRY-TER - Selbrume Runtime Contract Reconciliation V0

## 1. Resume executif

Baseline auditee : `a47e2195630f0bf9c44fa89528ac03227a26f0fa`.

```text
F1-ENTRY-TER : CLOSED

Selbrume runtime contracts reconciled : PASS
map_runtime complete : PASS
runtime host : PASS
macOS build : PASS

Phase F1 : READY
Phase F2 : NOT READY
```

La suite complete `map_runtime` reproduisait exactement 17 cas rouges. Les
causes etaient mixtes : regressions de donnees Selbrume, references manifestes
pendantes et attentes de tests devenues obsoletes apres les passes visuelles
Port/Bourg. La correction conserve la composition recente du Bourg, retablit
ses contrats jouables et narratifs, restaure les ressources encore referencees,
et actualise seulement les attentes dont l'historique prouve l'obsolescence.

Aucun code Event V2, runtime generique, core, gameplay, battle ou UI n'a ete
modifie. Aucun commit, staging ou push n'a ete effectue.

## 2. Gate 0

Commandes executees avant modification :

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git log --oneline -n 20
```

Sortie utile exacte :

```text
/Users/karim/Project/pokemonProject
main
HEAD = a47e2195630f0bf9c44fa89528ac03227a26f0fa
git status = vide
git diff --stat = vide
git diff --name-only = vide
```

Le Gate 0 etait donc propre sur la baseline demandee.

## 3. Audit initial et passes contradictoires

Quatre passes read-only specialisees ont ete menees en parallele :

- Agent A : `PASS`, restauration du nid/open-sea et mise a jour des deux
  attentes Port recentes ;
- Agent B : `PASS avec corrections`, conservation du Bourg recent mais retrait
  de l'underlay, restauration des landmarks et corridors ;
- Agent C : `PASS avec reserve`, analyse Grant en faveur de la donnee recente ;
- Agent D : `NON-PASS initial`, arbitrage contraire retenant le contrat P6
  `metapod` et signalant la non-durabilite du refiner Port ;
- Review finale : `NON-PASS initial` sur un test de provenance affaibli et le
  ponton non fige. Resolution : egalite manifeste/provenance restauree,
  sous-ensemble actif exact fige et test direct du ponton ajoute ;
- Contre-review de closure apres corrections : `PASS`.

Verdicts des passes obligatoires :

| Passe | Verdict | Preuve |
|---|---|---|
| Audit | PASS | 17 echecs reproduits et attribues |
| Implementation | PASS | Corrections limitees aux donnees/tests Selbrume |
| Tests | PASS | Cibles puis suite runtime complete vertes |
| Build/Validation | PASS | Analyze exit 0, host 48/48, macOS build produit |
| Critique finale | PASS apres corrections | Contrat Port renforce et ponton fige |

Les agents ont diverge sur Grant. L'arbitrage retient `metapod` : P6-05 et
P6-07 le contractent explicitement ; `e093213f` a introduit `dratini` sans lot
de ratification, et l'inventaire SEL-MAP-001 qualifiait encore cet ecart de
hors-scope, pas de nouveau canon.

Le MCP Dart n'etait pas expose dans les outils disponibles de cette session.
L'audit a ete compense par `rg`, `jq`, `git show`, les rapports historiques et
les tests Flutter frais.

## 4. Reproduction des 17 echecs

Commande :

```bash
cd packages/map_runtime
flutter test --reporter=compact
```

Resultat initial exact :

```text
00:39 +1609 ~1 -17: Some tests failed.
```

| # | Cas rouge initial | Decision canonique | Correction |
|---:|---|---|---|
| 1 | Catalogue Port : nid absent | Donnee obsolete | Restaurer `pe_port_nid_goelise` a `(7,9)` |
| 2 | Catalogue Bourg : ancien snapshot incompatible | Mixte | Conserver les couches recentes ; retirer l'underlay `objectif` interdit |
| 3 | Placements narratifs/landmarks | Donnee obsolete | Retablir nid et quatre IDs Bourg stables |
| 4 | P6-05 Grant `metapod/dratini` | Donnee obsolete | Restaurer le roster P6 `metapod` |
| 5 | Navigation Port-Bourg | Donnee Bourg obsolete | Rouvrir le corridor sud Bourg |
| 6 | Cellule Bourg `(26,54)` bloquee | Donnee obsolete | Rendre `x=26..30, y=54` marchable et connecte |
| 7 | Connectivite des dix maps | Donnee obsolete | Reconnecter les sorties sud et est au spawn |
| 8 | Catalogue assets : open sea absent | Donnee obsolete | Restaurer tileset, PNG et preset de base |
| 9 | Asset open sea introuvable | Donnee obsolete | Meme correction, SHA-256 verifie |
| 10 | Atlas Port `1408/2368` | Test obsolete | Attendre l'atlas append-only `1536x2368` |
| 11 | Resolution assets Bourg | Mixte | Supprimer la dependance `objectif`, tester les atlas actifs |
| 12 | P6-07 Grant `metapod/dratini` | Donnee obsolete | Meme restauration P6 |
| 13 | Bateau Port `y=22/21` | Test obsolete | Attendre la position visuelle ratifiee `(0,21)` |
| 14 | Landmark Bourg absent au rendu | Donnee obsolete | Retablir IDs et Centre Pokemon |
| 15 | Eau absente a `(44,25)` | Donnee obsolete | Completer le masque `l_path_secondary` |
| 16 | Pixel transparent a `(44,25)` | Donnee obsolete | Meme correction de masque |
| 17 | Crop Port avec 1374 pixels transparents | Donnee obsolete | Meme correction, puis rendu revalide |

Les premiers correctifs ont aussi revele trois contrats masques par les echecs
precedents : preset `nouveau-chemin` supprime mais encore reference, asset
`ponton_selbrume` absent malgre ses references legacy et inventaire de placements Port qui confondait
elements manifestes et elements encore poses. Ils ont ete reconciles dans le
meme perimetre de donnees et tests directement concerne.

## 5. Sources canoniques consultees

- `selbrume/docs/map_production/selbrume_map_blueprints.md` ;
- `selbrume/docs/map_production/legacy_map_inventory.md` ;
- `reports/gameplay/fg_181_port_des_brisants_reference_rebuild.md` ;
- `reports/gameplay/fg_181_selbrume_map_asset_foundation.md` ;
- `reports/gameplay/evidence/fg_181_selbrume_port_visual_correction/blueprint.md` ;
- rapports P6-05 et P6-07 ;
- historique `e093213f`, `1fc32b4f`, `816671f7`, `85008b90`, `39a9f7bb` ;
- provenance `selbrume_port_reference_v3.json`.

## 6. Corrections appliquees

### Bourg de Selbrume

- retrait du `tilesetId` global `selbrume_objectif` ;
- retrait de la couche et du placement reference `l_tile_objectif` ;
- conservation des six couches d'authoring recentes ;
- restauration des quatre IDs de landmarks contractuels ;
- ajout du Centre Pokemon manquant a `(29,22)` ;
- ouverture du corridor sud `x=26..30` vers le Port ;
- ouverture du corridor est `y=24..28` vers le Bois ;
- retrait de dix arbres generes qui recouvraient physiquement le corridor est.

### Port des Brisants

- restauration du nid Goelise narratif a `(7,9)` ;
- completion des deux cellules d'eau manquantes a l'est ;
- conservation du bateau a sa position visuelle recente `(0,21)` ;
- conservation de l'atlas Port recent `1536x2368`.

### Manifeste et assets

- restauration de `ts_selbrume_open_sea_loop` et de son PNG ;
- restauration du path preset `nouveau-chemin` encore requis par le pattern ;
- restauration du PNG `ponton_selbrume` pour preserver ses references legacy ;
- restauration du roster Grant P6 : `bulbasaur`, `metapod`, `ivysaur`.

## 7. Fichiers modifies

```text
packages/map_runtime/test/selbrume_asset_integrity_contract_test.dart
packages/map_runtime/test/selbrume_map_catalog_integrity_test.dart
packages/map_runtime/test/selbrume_map_navigation_contract_test.dart
packages/map_runtime/test/selbrume_map_render_smoke_test.dart
selbrume/maps/map_bourg_selbrume.json
selbrume/maps/map_port_brisants.json
selbrume/project.json
```

Fichiers binaires crees :

```text
selbrume/assets/tilesets/selbrume_open_sea_loop.png
source exacte : selbrume/assets/tilesets/selbrume_open_sea_true_loop.png
SHA-256 : e083a51d5f6c5df36d49bb75bb42613c96a779b07fffc8cb5d8090431f4d4750
format : PNG RGBA 2048x64

selbrume/assets/tilesets/ponton_selbrume.png
source exacte : blob conserve avant 1fc32b4f
SHA-256 : 3ccdece08c4961ccdc23d903213b1064d7086585740fbb0c27a715b639efc21c
format : PNG RGBA 280x230
```

Les binaires ne peuvent pas etre reproduits textuellement dans ce rapport ;
leurs hashes, leurs sources identifiees et leurs contrats de dimensions
constituent leur contenu probant. Le present rapport est l'autre fichier cree et son contenu
integral est ce document.

### Inventaire detaille des zones modifiees

| Fichier | Zones | Raison | Impact/diff |
|---|---|---|---|
| `selbrume/project.json` | `tilesets`, `elements`, `pathPresets`, trainer `grant` | References pendantes et roster P6 | Ajout open-sea/preset, preservation ponton, retour Metapod |
| `map_bourg_selbrume.json` | `tilesetId`, layers, paths, placements | Underlay interdit, sorties bloquees, IDs perdus | 6 couches recentes conservees, objectif retire, 2 corridors et 4 landmarks retablis |
| `map_port_brisants.json` | `l_path_secondary`, `placedElements` | Trou transparent et nid supprime | 2 cellules d'eau et 1 placement narratif restaures |
| `selbrume_map_catalog_integrity_test.dart` | contrats Port/Bourg | Snapshot structurel obsolete | Bateau `y=21`, couches Bourg recentes et 84 placements actifs |
| `selbrume_map_navigation_contract_test.dart` | position bateau | Attente visuelle obsolete | `y=22` vers `y=21`; connectivite intacte |
| `selbrume_asset_integrity_contract_test.dart` | open-sea, ponton, atlas/provenance, Bourg | Assets pendants et atlas recent | Ponton direct, 35 elements et 24 actifs exacts, atlas `2368` |
| `selbrume_map_render_smoke_test.dart` | inventaires Port/Bourg | Composites devenus couches/patterns | Sous-ensembles actuels sans supprimer le smoke visuel |
| `selbrume_open_sea_loop.png` | fichier complet | Pattern actif sans PNG | Copie canonique 2048x64 |
| `ponton_selbrume.png` | fichier complet | Compatibilite legacy sans PNG | Blob historique 280x230 |
| present rapport | document complet | Cloture et Evidence Pack | Audit, decisions, validations, risques et Git final |

## 8. Tests ajustes sans affaiblissement metier

- catalogue Bourg aligne sur ses couches recentes, tout en gardant les IDs,
  positions, connexions, warps et validations canoniques ;
- attentes bateau et atlas Port alignees sur les sorties recentes prouvees ;
- provenance Port conservee a 35 entrees, avec validation de chaque element
  manifeste et du sous-ensemble exact de 24 placements actifs ;
- ponton legacy protege par un test de chemin, decodage et dimensions ;
- rendu Bourg aligne sur ses deux atlas actifs apres suppression de l'underlay.

Les tests P6 Grant et les invariants de transparence Port n'ont pas ete modifies.

## 9. Validations executees

### Sept fichiers initialement rouges

```bash
flutter test --reporter=compact \
  test/selbrume_map_catalog_integrity_test.dart \
  test/p6_selbrume_first_trainer_battle_golden_slice_test.dart \
  test/selbrume_map_navigation_contract_test.dart \
  test/selbrume_asset_integrity_contract_test.dart \
  test/p6_selbrume_beta_validator_pass_test.dart \
  test/selbrume_map_render_smoke_test.dart \
  test/selbrume_port_visual_invariants_test.dart
```

```text
00:09 +92 ~1: 1 skipped test.
00:09 +92 ~1: All other tests passed!
```

### Suite complete map_runtime

```bash
cd packages/map_runtime
flutter test --reporter=compact
```

```text
00:40 +1627 ~1: 1 skipped test.
00:40 +1627 ~1: All other tests passed!
```

### Analyse map_runtime

```bash
flutter analyze --no-fatal-infos
```

```text
348 issues found. (ran in 4.0s)
exit code 0
```

Les 348 diagnostics sont des infos lint preexistantes ; aucune erreur ou warning
fatal n'est signale. Aucun de ces lints hors scope n'a ete modifie.

### Runtime host

```bash
cd examples/playable_runtime_host
flutter test --reporter=compact
```

```text
00:06 +48: All tests passed!
```

### Build macOS debug

```bash
flutter build macos --debug
```

```text
Building macOS application...
Built build/macos/Build/Products/Debug/playable_runtime_host.app
```

## 10. Non-objectifs respectes

- aucun code Event V2 fonctionnel ;
- aucun `map_core`, `map_gameplay`, `map_battle` ;
- aucune logique runtime generique ;
- aucune UI ou dependance ;
- aucun lockfile, fichier genere ou `.dart_tool` ;
- aucun changement de roadmap ;
- aucun commit, staging ou push ;
- Phase F1 non commencee.

## 11. Risques residuels

Le refiner historique `refine_selbrume_port_brisants_visuals.dart` contient
encore les anciennes decisions qui suppriment le nid et recreent le trou d'eau.
Il est hors du scope explicitement autorise de ce lot. Le relancer en ecriture
pourrait donc reintroduire ces deux regressions. Un lot de durcissement du
generateur devra aligner cet outil sur les contrats runtime maintenant verts.

Le Bourg conserve sa composition recente a six couches. Le lot n'a pas tente de
restaurer aveuglement l'ancien snapshot a huit couches et 306 placements.

## 12. Evidence Pack et auto-critique

Preuves principales : baseline propre, reproduction fraiche `-17`, historique
des commits fautifs, rapports FG/P6, checksums d'assets, sept fichiers cibles
verts, suite runtime complete verte, host vert et build macOS produit.

Auto-critique : la reconciliation Bourg a exige de retirer dix arbres pour
degager visuellement et physiquement la sortie est. C'est plus large qu'un
simple basculement de masque, mais necessaire pour satisfaire le contrat
no-code : une sortie annoncee doit etre visible et traversable. La correction
du refiner Port n'a volontairement pas ete embarquee car elle aurait franchi le
scope vers `map_editor`.

## 13. Verdict final

Gate Git final :

```text
 M packages/map_runtime/test/selbrume_asset_integrity_contract_test.dart
 M packages/map_runtime/test/selbrume_map_catalog_integrity_test.dart
 M packages/map_runtime/test/selbrume_map_navigation_contract_test.dart
 M packages/map_runtime/test/selbrume_map_render_smoke_test.dart
 M selbrume/maps/map_bourg_selbrume.json
 M selbrume/maps/map_port_brisants.json
 M selbrume/project.json
?? reports/narrativeStudio/events/ns_event_v2_f1_entry_ter_selbrume_runtime_contract_reconciliation_v0.md
?? selbrume/assets/tilesets/selbrume_open_sea_loop.png
?? selbrume/assets/tilesets/ponton_selbrume.png
```

`git diff --check` : vide. L'anti-scope sur `map_core`, `map_gameplay`,
`map_battle`, `map_runtime/lib`, `map_editor`, `examples` et `pubspec.yaml` est
vide. Les artefacts de build sont ignores et aucun lockfile n'a derive.

```text
F1-ENTRY-TER : CLOSED
Selbrume runtime contracts reconciled : PASS
map_runtime complete : PASS
runtime host : PASS
macOS build : PASS
Phase F1 : READY
Phase F2 : NOT READY
```
