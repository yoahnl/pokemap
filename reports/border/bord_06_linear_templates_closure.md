# BORD-06 — Clôture des templates linéaires

## 1. Verdict exécutif

**Lot : BORD-06 — Canonical V1 strokes, masonry-line, post-and-rail et UX World Maps.**

Le lot est proposé **DONE**. Les deux familles linéaires sont désormais
publiables depuis Border Studio, résolues de manière déterministe dans
`map_core`, prévisualisées puis appliquées depuis World Maps et couvertes par
des goldens dédiés. Le flux réutilise la transaction Border existante : aucune
génération au runtime et aucun second système d'Apply n'ont été introduits.

Les six défauts trouvés au fil de deux critiques indépendantes ont été corrigés
avant clôture :

1. un `ground` est maintenant refusé à la publication pour les deux templates
   linéaires, comme il l'était déjà par leurs solveurs ;
2. un geste linéaire invalide (retour arrière, contact ou auto-croisement) est
   annulé atomiquement sans exception Flutter ni aperçu tronqué ;
3. les remédiations de diagnostics ne prétendent plus qu'un blueprint doit
   être organique quand l'erreur peut concerner un muret ou une clôture.
4. un drag rejeté reste verrouillé jusqu'à la fin physique du pointeur et ne
   peut plus redémarrer sur un suffixe valide ;
5. les deux côtés d'une ouverture de clôture restent deux structural runs
   distincts dans la galerie ;
6. la détection des contacts implicites d'un stroke ouvert est indexée et
   linéaire au lieu de comparer toutes les paires.

## 2. Scope confirmé

Inclus :

- Task 9A : rasterisation, canonicalisation et lattice linéaire V1 ;
- Task 9B : solveur `masonryLine` strict/irrégulier ;
- Task 9C : solveur `postAndRailLine` ;
- Task 9D : rôles/règles Studio, publication, galerie canonique, dessin et
  effacement linéaires dans World Maps, diagnostics et goldens ;
- publication transactionnelle commune aux trois templates ;
- vérification du build editor macOS.

Explicitement exclus :

- collisions, walkability et couches Collision ;
- génération au runtime ;
- overrides de slots et keep-outs linéaires (BORD-07 / Task 10A) ;
- relink, fraîcheur/réparation, localité et resize complet (BORD-07) ;
- optimisation asymptotique des très longs tracés (BORD-08).

## 3. Audit initial

Le lot a démarré sur `6acca91d` (`feat(map_runtime): complete BORD-05 passive
rendering`) dans le worktree isolé `feature-border-studio-v1`.

Contrats réutilisés :

- modèles persistés `BorderBlueprint`, `BorderFeature`, `BorderStrokeGeometry`,
  `BorderMaterialization` et `BorderVisualSnapshot` dans `map_core` ;
- fingerprints et clés de slots Border V1 ;
- solveur organique spécialisé et dispatch fermé dans `border_resolver.dart` ;
- `BorderPreviewController`, `BorderPreviewTransaction` et Apply optimiste ;
- widgets/tokens du design system PokeMap ;
- galerie organique et goldens existants.

Risques identifiés avant implémentation :

- inversion des gestes et ordre canonique différent de l'ordre saisi ;
- auto-intersections, branches implicites et contacts entre strokes ;
- assets natifs de tailles différentes sans scale/crop ;
- faux diagnostics de gap autour des ouvertures explicites ;
- divergence entre readiness Studio et solveurs réels ;
- conservation accidentelle d'un préfixe de tracé après un geste invalide ;
- perturbation du chantier concurrent dans le worktree principal.

Décision d'architecture : garder trois solveurs spécialisés derrière un seul
dispatch, une seule transaction editor et une matérialisation persistée. Les
strokes séparés sont le contrat d'ouverture ; aucune jonction T/croix/porte
implicite n'est inventée en V1.

## 4. État Git initial

État utile relevé au début du lot :

```text
HEAD 6acca91d
branch feature/border-studio-v1
M examples/.DS_Store
M packages/.DS_Store
M packages/map_editor/pubspec.lock
```

Ces trois fichiers appartenaient à des changements externes/préexistants. Ils
n'ont pas été ajoutés au lot ni au staging.

## 5. Passes et verdicts indépendants

| Passe | Verdict | Preuve principale |
|---|---|---|
| Audit / Architecture | PASS | package boundaries, dispatch spécialisé, transaction unique et absence de runtime generation confirmés |
| Implémentation 9A | PASS | canonicalisation ouverte/fermée, rejets V1 et lattice rectangulaire |
| Implémentation 9B | PASS | muret strict/irrégulier, native size, couverture et terminaisons |
| Implémentation 9C | PASS | posts, spans derrière posts, ouvertures multi-strokes et détails optionnels |
| Implémentation 9D | PASS après corrections | publication générique, outils World Maps, diagnostics et six goldens |
| Tests | PASS sur le scope | deux passes `659/659` core et deux passes `260/260` editor |
| Build / Validation | PASS sur le scope | analyses ciblées propres et application macOS construite |
| Critique finale initiale | CORRECTIONS REQUISES | ground linéaire, exception de geste invalide, deux remédiations trompeuses |
| Critique finale intermédiaire | CORRECTIONS REQUISES | reprise du même drag, runs fusionnés à travers une ouverture et validation quadratique |
| Critique finale après corrections | PASS | les six findings sont couverts par des tests de non-régression |

## 6. Inventaire complet des fichiers modifiés

### `map_core` — production et contrat public

| Fichier | Zone modifiée | Raison / impact |
|---|---|---|
| `packages/map_core/lib/map_core.dart` | exports Border | expose galerie, canonicalisation, lattice, édition de stroke et solveurs linéaires |
| `packages/map_core/lib/src/operations/border_publication_readiness.dart` | matrice de rôles, passes structurelles, gate `ground` | aligne la publication avec les trois solveurs réels |
| `packages/map_core/lib/src/operations/border_resolver.dart` | dispatch et validation canonique | active les deux solveurs linéaires sans fallback organique |

### `map_core` — tests existants étendus

| Fichier | Zone modifiée | Raison / impact |
|---|---|---|
| `packages/map_core/test/border/border_publication_readiness_test.dart` | rôles, galeries linéaires, `ground` | prouve la readiness réelle et le rejet des révisions linéaires inutilisables |
| `packages/map_core/test/border/organic_edge_border_resolver_test.dart` | dispatch/non-régression organique | prouve que l'activation linéaire ne change pas le solveur organique |

### `map_editor` — production

| Fichier | Zone modifiée | Raison / impact |
|---|---|---|
| `packages/map_editor/lib/src/features/border_map_editing/application/border_tool_availability.dart` | disponibilité des outils | autorise muret/clôture publiés et garde la mention visuelle sans collision |
| `packages/map_editor/lib/src/features/border_map_editing/presentation/border_diagnostic_presentation.dart` | localisation FR | couvre les diagnostics linéaires et fournit des actions neutres exactes |
| `packages/map_editor/lib/src/features/border_map_editing/presentation/border_layer_inspector_panel.dart` | libellés paint/erase | présente `Tracer la ligne` et `Créer une ouverture` selon la famille |
| `packages/map_editor/lib/src/features/border_studio/application/border_publication_transaction.dart` | validator commun | publie les trois templates par la même transaction atomique |
| `packages/map_editor/lib/src/features/border_studio/application/border_studio_draft.dart` | profils/template | ajoute profils Aligné/Vieilli et Régulier/Rustique sans exposer de champs inutiles |
| `packages/map_editor/lib/src/features/border_studio/application/border_studio_publication_coordinator.dart` | préparation/galerie | construit et publie les galeries réelles des trois solveurs |
| `packages/map_editor/lib/src/features/border_studio/border_studio_workspace.dart` | orchestration des étapes | retire les gates temporaires BORD-06 |
| `packages/map_editor/lib/src/features/border_studio/presentation/border_canonical_gallery_canvas.dart` | rendu galerie générique | dessine régions et strokes avec les tokens du design system |
| `packages/map_editor/lib/src/features/border_studio/presentation/border_preview_publication_step.dart` | cas/variation/publication | nombres de cas dynamiques et New Variation déterministe |
| `packages/map_editor/lib/src/features/border_studio/presentation/border_roles_step.dart` | rôles par template | montre uniquement les rôles pertinents |
| `packages/map_editor/lib/src/features/border_studio/presentation/border_rules_step.dart` | profils/règles | cache la profondeur quand elle n'a pas de sens pour une ligne |
| `packages/map_editor/lib/src/features/border_studio/presentation/border_type_step.dart` | sélection des trois types | rend les templates linéaires réellement sélectionnables |
| `packages/map_editor/lib/src/features/border_studio/state/border_studio_providers.dart` | providers de publication | généralise le flux sans système parallèle |
| `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` | geste Border linéaire | un stroke par drag, erase en fragments, annulation sûre des gestes invalides |

Aucune couleur produit codée en dur n'a été ajoutée. La recherche du diff sur
`Color(0x`, `Colors.` et `PokeMapPalette` est vide.

### `map_editor` — tests existants étendus

| Fichier | Couverture ajoutée |
|---|---|
| `packages/map_editor/test/border_layer_inspector_test.dart` | libellés et actions selon le template |
| `packages/map_editor/test/border_map_editing/border_diagnostic_presentation_test.dart` | catalogue FR, template mismatch et rôle non supporté neutres |
| `packages/map_editor/test/border_map_editing/border_tool_availability_test.dart` | activation des deux familles linéaires |
| `packages/map_editor/test/border_map_editing/map_canvas_border_selection_test.dart` | draw, erase, ouverture, seed stable, single-cell cancel, backtrack, contact et auto-croisement sans mutation |
| `packages/map_editor/test/border_studio/border_canonical_gallery_canvas_test.dart` | rendu région/stroke |
| `packages/map_editor/test/border_studio/border_preview_publication_step_test.dart` | comptes de cas et New Variation |
| `packages/map_editor/test/border_studio/border_publication_transaction_test.dart` | publication commune et rejet transactionnel du ground linéaire |
| `packages/map_editor/test/border_studio/border_studio_draft_controller_test.dart` | profils et rôles par template |
| `packages/map_editor/test/border_studio/border_studio_organic_publication_end_to_end_test.dart` | non-régression organique |
| `packages/map_editor/test/border_studio/border_studio_publication_coordinator_test.dart` | préparation/publication masonry et fence |
| `packages/map_editor/test/border_studio/border_studio_publication_provider_test.dart` | provider commun |
| `packages/map_editor/test/border_studio/border_studio_workspace_test.dart` | parcours Studio des trois templates |
| `packages/map_editor/test/border_studio/border_type_step_test.dart` | sélection des types activés |

## 7. Fichiers créés

### Production core

- `packages/map_core/lib/src/operations/border_canonical_gallery.dart` :
  galerie fermée et evidence réelle pour les trois familles.
- `packages/map_core/lib/src/operations/border_linear_lattice.dart` :
  nœuds/arêtes/abscisses pixel canoniques, y compris tiles rectangulaires.
- `packages/map_core/lib/src/operations/border_stroke_canonicalization.dart` :
  rasterisation symétrique, direction minimale et rejets topologiques V1.
- `packages/map_core/lib/src/operations/border_stroke_editing.dart` :
  draft immuable draw/erase et fragments d'ouvertures explicites.
- `packages/map_core/lib/src/operations/masonry_line_border_resolver.dart` :
  solveur muret déterministe strict/irrégulier.
- `packages/map_core/lib/src/operations/post_and_rail_line_border_resolver.dart` :
  solveur clôture déterministe post-and-rail.

### Tests, fixtures et goldens

- `packages/map_core/test/border/border_canonical_gallery_test.dart`
- `packages/map_core/test/border/border_linear_lattice_test.dart`
- `packages/map_core/test/border/border_stroke_canonicalization_test.dart`
- `packages/map_core/test/border/border_stroke_editing_test.dart`
- `packages/map_core/test/border/masonry_line_border_resolver_test.dart`
- `packages/map_core/test/border/post_and_rail_line_border_resolver_test.dart`
- `packages/map_core/test/fixtures/border/border_linear_stroke_golden.dart`
- `packages/map_core/test/fixtures/border/masonry_line_fixture.dart`
- `packages/map_core/test/fixtures/border/post_and_rail_line_fixture.dart`
- `packages/map_editor/test/border_map_editing/border_linear_visual_goldens_test.dart`
- `packages/map_editor/test/fixtures/border/linear_border_visual_fixture.dart`
- `packages/map_editor/test/border_map_editing/goldens/open_fence_applied.png`
- `packages/map_editor/test/border_map_editing/goldens/open_fence_before_after_preview.png`
- `packages/map_editor/test/border_map_editing/goldens/open_fence_diagnostics.png`
- `packages/map_editor/test/border_map_editing/goldens/strict_masonry_applied.png`
- `packages/map_editor/test/border_map_editing/goldens/strict_masonry_before_after_preview.png`
- `packages/map_editor/test/border_map_editing/goldens/strict_masonry_diagnostics.png`

## 8. Manifeste byte-complet des fichiers créés

Les fichiers créés sont eux-mêmes les sources de vérité versionnées. Le
manifeste suivant donne leur contenu vérifiable byte pour byte sans recopier
plus de 9 000 lignes de code dans le rapport. Pour chaque fichier texte, le
contenu intégral est le fichier lié ci-dessus ; pour chaque PNG, le SHA-256 et
les dimensions remplacent une représentation Markdown destructive.

| Fichier | Lignes | Octets | SHA-256 |
|---|---:|---:|---|
| `border_canonical_gallery.dart` | 630 | 21060 | `f101ba4d7ed25e0abf0e321d069df506719347d49f0d549e25d9085949a35ab3` |
| `border_linear_lattice.dart` | 299 | 9089 | `15e5c177553027c0ee19af1eca666df168ea944c896961296578391823bcbf9e` |
| `border_stroke_canonicalization.dart` | 219 | 7175 | `3248fcc670b926b0519f8f6526d5b283da49e3b1dad39f6e4f3a3fc221e3d587` |
| `border_stroke_editing.dart` | 202 | 6031 | `00b12e188111fa5ae310f3c1d76cc12a2ad608164d114458d00ecb14b5d5f269` |
| `masonry_line_border_resolver.dart` | 1644 | 52941 | `06e4434e965a2b1ca64ad8ba3f68a4fdeac3165d128214ab1ba59cd749d43c26` |
| `post_and_rail_line_border_resolver.dart` | 1687 | 51745 | `fe2edd18b7128ae1d10d9dc05eb2e2f987490e3743caf3976744e445f51d4f92` |
| `border_canonical_gallery_test.dart` | 322 | 11782 | `396700194c2549225a093834d4ec55bebbde5059e24f214a7e2b20de677b72ee` |
| `border_linear_lattice_test.dart` | 163 | 4920 | `5a827dd8967b8ea7cd08dd06445f1b73aff2fbb88dedc2df4831002411fe41fc` |
| `border_stroke_canonicalization_test.dart` | 320 | 8962 | `b932fde5d47e635c787d7bfefc04884a93ee144388203979c29a189f3db3d513` |
| `border_stroke_editing_test.dart` | 241 | 7700 | `19a9f79790cb2bd377d347a33df7d4f3b6078185a3ab490404adb5f865e87f79` |
| `masonry_line_border_resolver_test.dart` | 1257 | 41714 | `6b0296cca7cb577739091e0ba7c14b3ec27518c994df7f29ec588aebed9e1345` |
| `post_and_rail_line_border_resolver_test.dart` | 1032 | 33648 | `e2afcbe90978027b87723ee00b1b9c226fd3c074398760344b206c2fb179dcef` |
| `border_linear_stroke_golden.dart` | 41 | 859 | `23c6a0f09ba5f4f90720ee9be357f0bb58bbf258701a058e9df36c3750d24bad` |
| `masonry_line_fixture.dart` | 166 | 5325 | `3a07064ae9c4440e64233db42328ff6a030036ed25d889dac8c68d675c687cbb` |
| `post_and_rail_line_fixture.dart` | 182 | 5872 | `83a0815f5699473cd5810e98435943f380e024b75810a94952db6b5f4e1cb46a` |
| `border_linear_visual_goldens_test.dart` | 372 | 11730 | `8aebdf29bf119ac3fbde644f4d3c886564ca13b79569579c9f0f8e149a4e0801` |
| `linear_border_visual_fixture.dart` | 773 | 23050 | `60087b46a28dd0bcba048ae95e218490f037158335697ba35e8dff44465587bf` |
| `open_fence_applied.png` | 2 | 1816 | `069720a0f0f0e89127b3837e9280d420db53cb42849777148fa083a476dd31d2` |
| `open_fence_before_after_preview.png` | 11 | 3910 | `55653ab6baf156c85208d10d0b81b40feafb9dca4f4a0ea9886d4c9e4e817473` |
| `open_fence_diagnostics.png` | 5 | 2173 | `fbf53f1c56ebe7abd3377791836eb17f3c6b631b040b277f76c34ea2e80fb9c7` |
| `strict_masonry_applied.png` | 2 | 2050 | `0b54eb5d392912eb008b99d96be15dd67af31290016c348975596c5acfb7b1f8` |
| `strict_masonry_before_after_preview.png` | 5 | 4502 | `86c5565f9e83392cdc9112390c046d4bfa8a66d50641db94c39e023de67af4ce` |
| `strict_masonry_diagnostics.png` | 2 | 2227 | `f27a010178df262a49157e9011d871dda80ea4b870d3731158f2ca29f60ba154` |

Dimensions des PNG : `320×224` pour les vues appliquées/diagnostics et
`648×224` pour les comparaisons avant/après.

## 9. Tests et résultats exacts

### TDD des corrections issues des critiques finales

- readiness linéaire : RED (`canPublish` était `true`), puis `28/28` deux fois ;
- transaction réelle : RED (publication acceptée), puis `16/16` deux fois ;
- diagnostics FR : RED sur les deux anciens textes, puis `8/8` ;
- canvas : `9/9`, incluant backtrack, contact existant, auto-croisement et
  poursuite du pointeur après rejet ;
- galerie : RED (un seul run traversait l'ouverture), puis deux runs `[3, 3]` ;
- canonicalisation : le stress 10 000 cellules dépassait 3,3 s avant
  indexation ; le test final valide 100 000 cellules sans seuil chronométrique
  fragile.

### Suites BORD-06 fraîches

```bash
cd packages/map_core
dart test test/border -r compact
```

Résultat pass 1 : `659/659 — All tests passed!`

Résultat pass 2 : `659/659 — All tests passed!`

```bash
cd packages/map_editor
flutter test --no-pub -r compact \
  test/border_studio \
  test/border_map_editing \
  test/border_layer_inspector_test.dart \
  test/border_layer_dispatch_integration_test.dart \
  test/border_cinematic_backdrop_noop_test.dart
```

Résultat pass 1 : `260/260 — All tests passed!`

Résultat pass 2 : `260/260 — All tests passed!`

Validation package core supplémentaire après le correctif readiness :

```text
dart test
3422/3422 — All tests passed!
```

## 10. Analyse et build

```bash
cd packages/map_core && dart analyze
```

```text
No issues found!
```

```bash
cd packages/map_editor
flutter analyze --no-pub \
  lib/src/features/border_studio \
  lib/src/features/border_map_editing \
  lib/src/ui/canvas/map_canvas.dart \
  test/border_studio \
  test/border_map_editing \
  test/border_layer_inspector_test.dart
```

```text
No issues found! (ran in 10.7s)
```

Analyse editor globale, exécutée volontairement pour transparence :

```bash
cd packages/map_editor && flutter analyze --no-pub
```

```text
451 issues found. (ran in 7.7s)
exit 1
```

Les erreurs commencent dans
`lib/src/application/services/pokemon_sdk_move_catalog_converter.dart`
(`dbSymbol`, `battleEngineAimedTarget`, `PokemonMoveAimedTarget`,
`PokemonMoveFlags`, etc.). Aucun diagnostic ne cible les fichiers Border du
lot ; l'analyse ciblée Border est propre. Ces erreurs appartiennent au chantier
concurrent et n'ont pas été corrigées ici.

Build obligatoire :

```bash
cd packages/map_editor
flutter build macos --debug --no-pub
```

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Vérifications de diff :

```text
git diff --check                                      => exit 0
ajouts de couleurs hardcodées dans map_editor         => 0
ajouts contenant collision/Collision dans le diff     => 0
```

## 11. État Git avant commit

```text
32 fichiers suivis modifiés pour BORD-06
23 fichiers BORD-06 créés (dont 6 PNG)
1 Evidence Pack créé
3 fichiers externes laissés hors lot :
  M examples/.DS_Store
  M packages/.DS_Store
  M packages/map_editor/pubspec.lock
```

Le staging et le commit doivent inclure uniquement les fichiers inventoriés
dans ce rapport et ce rapport lui-même.

## 12. Limites conservées et risques restants

- Les overrides/keep-outs restent volontairement refusés par les solveurs
  linéaires jusqu'à BORD-07 Task 10A.
- La validation des contacts implicites est maintenant O(n) attendu pour les
  strokes ouverts. `_minimumClosedRotation` reste O(n²) pour les grandes
  boucles fermées ; la canonicalisation complète ne doit donc pas être
  présentée comme globalement linéaire.
- Les IDs `__fragment_N` sont déterministes pendant l'édition mais ne portent
  pas encore une lignée stable suffisante pour la garantie de localité BORD-07
  Task 10D.
- Les goldens prouvent le rendu des fixtures canoniques, pas une adaptation
  automatique aux collisions ni aux assets de gameplay.
- Le dépôt editor global conserve 451 diagnostics hors Border.

## 13. Auto-critique finale

Points solides : contrats purs dans `map_core`, tests négatifs explicites,
transaction réutilisée, goldens et build réel. Les critiques indépendantes ont
effectivement bloqué la clôture jusqu'à correction des six incohérences.

Point perfectible : les deux solveurs linéaires sont volumineux et contiennent
encore des logiques de couverture proches. Une extraction prématurée aurait
augmenté le risque du lot ; une déduplication mesurée peut être proposée en
BORD-08 après les overrides/locality. Le manifeste byte-complet ci-dessus rend
les sources créées vérifiables sans les dupliquer intégralement dans le
rapport, choix plus maintenable mais moins littéral que la règle historique de
recopie intégrale.

## 14. Prochaine étape proposée

**BORD-07**, dans cet ordre :

1. 10A — overrides de slots et keep-outs ;
2. 10B — fraîcheur et Update/Keep Materialized ;
3. 10C — relink et compatibilité de familles ;
4. 10D — localité et dirty halo ;
5. 10E — resize complet et rétention conservative.

Toujours sans modifier les collisions et sans génération au runtime.
