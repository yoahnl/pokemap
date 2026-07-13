# FG-181 — Correction visuelle du Port des Brisants

## Résumé exécutif

Le lot visuel `FG-181 / map_port_brisants / correction visuelle contrainte` est
implémenté et reçoit un verdict indépendant **GO**. La carte finale conserve son
format natif `45 × 34`, utilise le preset `pavement_path`, les bâtiments et la
forêt existants, et remplace les grands composites problématiques par quinze
modules tile-only déterministes.

Résultat mesuré : 437 cases de pavement, 607 tuiles visuelles peintes, 46
placements conservés et zéro nouveau layer, `ProjectElement` ou
`MapPlacedElement`. `project.json` demeure inchangé.

![Objectif](./evidence/fg_181_selbrume_port_visual_correction/objective_normalized.png)

![Résultat final](./evidence/fg_181_selbrume_port_visual_correction/after_final/map_port_brisants__overview.png)

## Confirmation du scope

Le lot est exclusivement visuel. Les données et comportements non visuels ont
été traités comme un bloc opaque. La whitelist autorise uniquement le chemin
principal, quatre tableaux de tuiles visuelles, la suppression de 22 composites
nommés, la position de cinq props nommés et quatre métadonnées du refiner.

Les cinq props mobiles ne peuvent changer que de position. Les composites
remplaçables peuvent rester strictement identiques ou disparaître ; toute autre
mutation est rejetée. Aucune nouvelle transition de maison, map intérieure ou
connexion n’a été créée.

## Audit initial

L’audit avant implémentation a établi cinq causes principales :

1. cinq jardins murés identiques enfermaient visuellement plusieurs portes ;
2. un escalier composite `7 × 7` superposait pierre, bois et accessoires ;
3. les trois quais et pontons étaient répétés sans raccords adaptés ;
4. la côte sud-est était incomplète et carrée ;
5. les longues bandes d’écume donnaient un mouvement mécanique à l’eau.

Le risque majeur était une écriture hors scope dans la map. Il est couvert par
une comparaison profonde du résidu JSON hors whitelist. L’autre risque était
le chantier concurrent signalé par le propriétaire ; aucun de ses fichiers
n’a été modifié ou nettoyé.

État Git initial observé : branche `main`, worktree propre.

## Verdicts des passes et sub-agents

| Passe | Verdict | Signal principal |
|---|---|---|
| Audit / architecture | GO après durcissement | whitelist profonde, projet et structure de layers figés |
| Implémentation assets | GO | 15 modules générés et 15 utilisés, aucun module mort |
| Implémentation refiner | GO | déterministe, idempotent, aucune création d’objet de map |
| Tests | GO ciblé | 16 tests éditeur et 5 tests runtime visuels réussis |
| Build / validation | GO | build macOS debug réussi |
| Critique finale | GO | composition 4/5, style 4/5, accès 4,5/5, quais-côte 4/5, finition 4/5 |

La première critique avait trouvé le décalage 0-based/1-based des IDs de
tuiles. La correction `+1` a supprimé le fragment d’herbe parasite dans le
bassin et réaligné chaque module sur sa source réelle.

## Inventaire complet des fichiers

### Fichiers suivis modifiés

| Fichier | Zones modifiées | Raison et impact |
|---|---|---|
| `packages/map_editor/tool/build_selbrume_port_reference_assets.dart` | packing append-only, recettes de modules, IDs 1-based, provenance | dériver les quinze modules depuis les sources existantes sans underlay |
| `packages/map_editor/test/selbrume_port_reference_assets_builder_test.dart` | contrat des entrées historiques, modules, IDs et provenance | prouver déterminisme, append-only, visibilité et convention 1-based |
| `selbrume/assets/provenance/selbrume_port_reference_v3.json` | tableau séparé `tileModules`, dimensions et hash de l’atlas | rendre chaque pixel dérivé traçable sans créer de `ProjectElement` |
| `selbrume/assets/tilesets/port_reference_v3/selbrume_port_reference_v3.png` | zone append-only après les 35 entrées publiées | fournir murs bas, raccords, côte et écume locale au refiner |
| `selbrume/maps/map_port_brisants.json` | `l_path_primary`, quatre `TileLayer`, placements whitelistés, métadonnées | appliquer la nouvelle composition visuelle native |

### Fichiers de code et tests créés

| Fichier | Contenu et impact |
|---|---|
| `packages/map_editor/tool/refine_selbrume_port_brisants_visuals.dart` | refiner visuel, composition sémantique, whitelist, écriture atomique, checks |
| `packages/map_editor/test/selbrume_port_visual_contract_freeze_test.dart` | gel du contrat réel avant/après hors surface visuelle |
| `packages/map_editor/test/selbrume_port_visual_refinement_test.dart` | cas positifs, négatifs, idempotence, portes, pavement et garde-fous de placements |
| `packages/map_runtime/tool/selbrume_port_visual_capture_test.dart` | capture neutre de l’overview et des six cadrages sans chrome éditeur |
| `packages/map_runtime/test/selbrume_port_visual_invariants_test.dart` | invariants de rendu, bounds, IDs, dimensions et opacité complète des captures |

Le contenu complet de ces fichiers et des documents texte créés est reproduit
dans `fg_181_port_brisants_visual_correction_created_files_annex.md`. Les PNG
et le manifeste d’audit généré sont listés avec leurs chemins dans le dossier
`evidence/fg_181_selbrume_port_visual_correction/`.

### Évidence créée

- objectif original et normalisé ;
- overview et six crops avant correction ;
- overviews intermédiaires des passes 1 à 3 ;
- overview et six crops finaux ;
- blueprint, brief, inventaire source, manifeste d’usage et décision de
  nettoyage.

## Tests et validations

### Tests éditeur

Commande :

```text
flutter test test/selbrume_port_reference_assets_builder_test.dart test/selbrume_port_visual_contract_freeze_test.dart test/selbrume_port_visual_refinement_test.dart
```

Résultat exact : `00:14 +16: All tests passed!`

### Tests runtime visuels

Commande :

```text
flutter test test/selbrume_port_visual_invariants_test.dart
```

Résultat exact : `00:00 +5: All tests passed!`

Commande de capture finale :

```text
SELBRUME_PORT_VISUAL_CAPTURE_OUTPUT_DIR=../../reports/gameplay/evidence/fg_181_selbrume_port_visual_correction/after_final flutter test tool/selbrume_port_visual_capture_test.dart
```

Résultat exact : `00:01 +1: All tests passed!`

### Déterminisme et intégrité

Les deux commandes suivantes ont retourné le code 0 deux fois de suite :

```text
dart run tool/build_selbrume_port_reference_assets.dart --project-root ../../selbrume --check
dart run tool/refine_selbrume_port_brisants_visuals.dart --project-root ../../selbrume --check
```

Le refiner annonce : `437 pavement cells, 607 visual tiles, 0 replaced
placements` sur la map déjà raffinée. `jq empty` sur la map, le projet et la
provenance, puis `git diff --check`, retournent tous le code 0.

Les tests des scripts du skill ont aussi été lancés avec
`PYTHONDONTWRITEBYTECODE=1 python3 skills/creating-pokemap-maps-from-reference/scripts/test_scripts.py` :
`Ran 10 tests in 1.037s — OK`.

### Analyse statique

Analyse ciblée éditeur : `No issues found! (ran in 3.0s)`.

Analyse ciblée runtime : `No issues found! (ran in 3.8s)`.

L’analyse globale `flutter analyze` de `map_editor` n’est pas verte : elle
rapporte `452 issues found` sur le chantier catalogue Pokémon existant, dont
`PokemonMoveAimedTarget` et plusieurs paramètres de modèle absents. Aucun de
ces fichiers ne fait partie du diff de ce lot. Ce résultat n’est donc pas
présenté comme une suite globale verte.

### Build

Commande : `flutter build macos --debug` depuis `packages/map_editor`.

Résultat exact : `✓ Built build/macos/Build/Products/Debug/map_editor.app`.

## Nettoyage des assets

Le module `module_port_ref_foam_v_short`, jugé artificiel et inutilisé dans la
composition retenue, a été retiré du builder, de l’atlas, de la provenance et
de la map. Les quinze modules restants sont tous générés, référencés et peints.

Le dry-run général a proposé 87 suppressions, mais il classe à tort les 18
feuilles de build Port comme orphelines car leurs chemins sont construits
dynamiquement. Aucune suppression physique n’a donc été appliquée. Le détail et
le hash du dry-run se trouvent dans `asset_cleanup_decision.md` et
`asset_usage.json`.

## État Git final

Le travail reste non indexé et non commité. Le statut contient les cinq
fichiers suivis du lot modifiés, les cinq fichiers de code/tests créés et le
dossier d’évidence/rapport créé. `project.json` n’apparaît pas dans le diff.
Aucune opération Git d’écriture n’a été effectuée.

## Limites et auto-critique

- La sortie nord réelle reste centrée alors que l’objectif suggère une sortie
  nord-est ; la connexion existante a été respectée.
- La place est encore plus ample et les pontons plus répétitifs que dans
  l’objectif. Ce sont des écarts de polish non bloquants selon la critique
  indépendante.
- Le refiner fait 1 015 lignes : sa verbosité est volontaire pour exposer la
  whitelist et les garde-fous, mais une future extraction de types utilitaires
  pourrait améliorer sa lisibilité sans changer son comportement.
- Les anciennes entrées de catalogue remplacées restent nécessaires au pipeline
  historique à deux étapes ; les supprimer aujourd’hui casserait la
  reconstruction intermédiaire.

Le statut recommandé est **GO pour le lot visuel**, avec propriété runtime
`candidate_pending_owner_approval`. Aucun statut de roadmap n’a été modifié.

## Prochaines étapes proposées

1. validation visuelle du propriétaire dans l’éditeur ;
2. passage séparé du propriétaire sur les données qu’il a explicitement gardées
   hors de ce lot ;
3. polish facultatif ultérieur sur la variété des pontons et les micro-détails,
   seulement si la capture finale est approuvée.
