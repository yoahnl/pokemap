# BORD-07 — Clôture du cycle d’édition des bordures

## 1. Verdict exécutif

**Lot : BORD-07 — Overrides, fraîcheur, relink, localité et cycle de vie au resize.**

Le lot est proposé **DONE** sur son périmètre. Une bordure créée depuis World
Maps peut désormais être corrigée localement, rematérialisée ou conservée,
reliée à un autre blueprint compatible, régénérée dans un halo physique borné
et adaptée à un redimensionnement de carte. Les opérations destructrices ou
potentiellement obsolètes restent derrière une prévisualisation explicite et
des gardes optimistes d’identité, de révision et de fingerprint.

Le résultat respecte les deux frontières non négociables du lot :

- aucune génération au runtime ;
- aucune nouvelle logique BORD de génération ou d’authoring de collisions ;
  le resize des tableaux Collision reste strictement celui du resize legacy.

La revue finale indépendante conclut **APPROVED, aucun finding actionnable**.
Les suites Border core et éditeur passent deux fois, le package `map_core`
complet passe, les analyses ciblées sont propres et l’application macOS est
construite. L’analyse globale de `map_editor` conserve honnêtement 451
diagnostics hors périmètre ; aucun ne cible un fichier BORD-07.

## 2. Scope confirmé

Inclus :

- **10A** — overrides de slots, variation locale et keep-outs ;
- **10B** — fraîcheur, paramètres/keep-outs éditables, `Update preview` et
  `Conserver la matérialisation` ;
- **10C** — relink même famille et reset inter-familles explicitement confirmé ;
- **10D** — dirty halo, résolution locale physique, lineage stable et parité
  avec la résolution canonique ;
- **10E** — crop/pad de carte, clipping/splitting de strokes, rétention
  conservative des snapshots et diagnostics éditeur localisés ;
- corrections locales et Update intégrés au flux Preview / Apply partagé de
  World Maps ; relink gardé dans sa preview/confirmation atomique dédiée ;
- build macOS réel de `map_editor`.

Explicitement exclus :

- nouvelle logique BORD de collisions/walkability ; le resize des tableaux
  Collision reste délégué sans divergence au comportement legacy ;
- génération ou réparation au runtime ;
- édition directe du grand JSON par l’utilisateur ;
- optimisation totale des réductions globales de topologie/fingerprint ;
- nettoyage des diagnostics historiques du package éditeur ;
- changement du chantier concurrent présent dans le worktree principal.

## 3. Audit initial

Le lot a démarré sur `6bde50f0` (`feat(border): complete BORD-06 linear
templates`) dans le worktree isolé `feature-border-studio-v1`.

Contrats réutilisés :

- `BorderBlueprintRevision`, `BorderFeature`, `BorderMaterialization`,
  `BorderVisualSnapshot`, `BorderSlotOverride` et `BorderKeepOutRegion` dans
  `map_core` ;
- les trois solveurs spécialisés BORD-05/BORD-06 et leur dispatch fermé ;
- les fingerprints d’entrée/sortie et la validation canonique de résultat ;
- `BorderPreviewController`, la transaction Preview / Apply optimiste et
  l’historique unique de l’éditeur ;
- le calque Border dédié de World Maps et les composants/tokens du design
  system PokeMap ;
- le resize de carte existant, enrichi sans créer une seconde mutation.

Risques identifiés avant implémentation :

- appliquer une correction sur une preview devenue obsolète ;
- relier une feature à une révision publiée différente de celle prévisualisée ;
- perdre la géométrie ou masquer les pertes pendant un changement de famille ;
- prétendre à une résolution locale tout en relançant le solveur complet ;
- modifier les IDs/RNG de fragments distants après une édition locale ;
- conserver des placements/sols hors carte après resize ;
- produire plusieurs entrées d’historique pour un seul geste ;
- deviner une taille de tuile quand le projet n’est pas disponible ;
- toucher accidentellement aux collisions malgré l’interdiction explicite.

Décision d’architecture : toutes les transformations restent pures dans
`map_core`. Les corrections locales et Update réutilisent l’Apply partagé ; le
relink conserve une preview/confirmation dédiée avant sa mutation atomique.
La localité s’appuie sur une baseline éphémère chaînable ; elle ne change pas
le JSON persistant et ne déplace aucune génération au runtime.

## 4. État Git initial

```text
HEAD 6bde50f0
branch feature/border-studio-v1
M examples/.DS_Store
M packages/.DS_Store
M packages/map_editor/pubspec.lock
```

Ces trois fichiers appartenaient à des changements externes/préexistants. Ils
ont été conservés, exclus du diff fonctionnel, du staging et du commit BORD-07.

## 5. Résultat fonctionnel par sous-lot

### 10A — Corrections locales et keep-outs

`resolveBorderOverrides(...)` applique de façon déterministe les suppressions,
remplacements, déplacements, transforms, variations locales, locks et zones
interdites. Les trois solveurs passent par cette opération commune. L’ordre de
sortie, les orphelins, la couverture, le canvas et les couloirs de déplacement
sont validés sans fallback silencieux.

L’inspecteur World Maps expose six actions guidées :

1. `Nouvelle variation locale` ;
2. `Remplacer` ;
3. `Déplacer` ;
4. `Retirer` ;
5. `Verrouiller` ;
6. `Zone interdite`.

Ces actions ne modifient ni la carte ni l’historique avant l’Apply partagé.

### 10B — Fraîcheur et décision Update / Keep

`updateBorderFeatureParameters(...)` et
`updateBorderFeatureKeepOutRegions(...)` complètent les opérations pures de
feature. Les changements savent explicitement effacer une valeur optionnelle.
Les fingerprints d’entrée/sortie continuent de porter la fraîcheur réelle de
la matérialisation.

L’utilisateur choisit entre `Update preview`, qui régénère la proposition, et
`Conserver la matérialisation`, qui conserve le résultat visuel persisté. Les
no-ops ne créent pas d’historique.

### 10C — Relink sûr des blueprints

`prepareBorderFeatureRelink(...)` prépare sans mutation :

- un relink canonique pour une famille de géométrie compatible ;
- un reset explicite inter-familles avec la liste exacte des pertes réelles.

`applyBorderFeatureRelinkPreview(...)` et
`applyBorderFeatureFamilyReset(...)` sont atomiques. Ils refusent un état dont
l’identité de carte, les dimensions, la feature ou le fingerprint ont dérivé.
Le contrôleur éditeur vérifie en plus la révision publiée du catalogue avant
chacune des trois entrées d’application. Une source blueprint supprimée est
inférée depuis la géométrie persistée au lieu de rendre la feature inutilisable.

### 10D — Localité physique et lineage stable

`resolveBorderFeatureLocalBaseline(...)` produit la baseline complète
nécessaire au premier geste. `resolveBorderFeatureLocally(...)` régénère ensuite
uniquement le halo sale et renvoie un `nextState` chaînable.

Le halo tient compte :

- de la formule de placement du blueprint ;
- de `ground.edgeBandCells` pour les côtes organiques ;
- des anciennes et nouvelles bounds opaques d’un déplacement manuel ;
- du corridor balayé entre les deux positions ;
- des suppressions et keep-outs locaux.

Le chemin local n’appelle pas `resolveBorderFeature(...)`. Les placements et
cellules de sol distants sont réutilisés byte pour byte. Le lineage persisté
est checksummé sous la forme
`__border_lineage_v1_p1_o<offset>_w<n|wrap>_h<sha256>` : offsets imbriqués,
wrap, ordre de traversal et namespace RNG restent stables.

### 10E — Resize et cycle de vie éditeur

`resizeBorderLayerContent(...)` crop/pad les régions et keep-outs, clippe et
sépare les strokes linéaires, retire les placements/ground hors cadre,
recalcule le fingerprint de sortie et supprime la matérialisation devenue vide.
Les IDs de fragments restent stables et sans ambiguïté.

La rétention de snapshots est conservative : une suppression physique n’est
proposée que lorsque le manifeste est déclaré exhaustif **et** que toutes les
maps listées dans ce manifeste sont effectivement chargées. Le snapshot ne
doit alors plus être référencé. L’opération retourne les IDs concernés ; la
couche de stockage reste responsable de la suppression physique.

`ResizeMapUseCase` utilise la taille de tuile du projet et refuse de la deviner
si un calque Border existe sans projet chargé. Un resize rejeté ne mute rien,
n’ajoute rien à l’historique et laisse un `BorderResizeFeedback` lié à
l’identité exacte de la carte source. L’inspecteur affiche les 19 diagnostics
resize en français avec le design system.

## 6. Passes et verdicts indépendants

| Passe | Verdict | Preuve principale |
|---|---|---|
| Audit / Architecture | PASS | opérations pures core, Apply partagé pour corrections/Update, confirmation dédiée pour relink, frontières runtime/collision confirmées |
| Implémentation 10A | PASS | six actions, validation des overrides, preview-only et Apply partagé |
| Implémentation 10B | PASS | paramètres/keep-outs, fraîcheur, Update/Keep et no-op sans historique |
| Implémentation 10C | PASS après hardening | identité de carte, fingerprint feature et révision catalogue gardés |
| Implémentation 10D | APPROVED | résolution locale physique, parité canonique et lineage checksummé |
| Audit 10E initial | CORRECTIONS REQUISES | resize éditeur legacy rejetait Border ; diagnostics non présentés |
| Implémentation 10E après corrections | PASS | use case Border-aware, mutation unique, feedback lié à l’identité, 19 diagnostics FR |
| Tests racine | PASS | core Border deux fois `702/702`, éditeur deux fois `128/128`, core complet `3465/3465` |
| Build / Validation | PASS sur le scope | analyses ciblées propres, diff propre, application macOS construite |
| Critique finale indépendante | APPROVED | aucun finding actionnable ; gardes, atomicité, design system et exclusions confirmés |

La critique indépendante finale a aussi relancé neuf suites core (`169` tests),
les suites fraîcheur/validation (`38`), sept suites éditeur (`63`) et les deux
analyses ciblées. Aucun fichier n’a été modifié pendant cette revue.

## 7. Inventaire complet des fichiers modifiés

### `map_core` — production et API publique

| Fichier | Classes / fonctions / zones modifiées | Raison et impact |
|---|---|---|
| `packages/map_core/lib/map_core.dart` | exports Border | expose overrides, relink et localité sans exposer le scope interne |
| `packages/map_core/lib/src/operations/border_catalog_operations.dart` | `BorderVisualSnapshotRetentionResult`, `cleanupUnreferencedBorderVisualSnapshots` | n’autorise une suppression que depuis un manifeste exhaustif dont toutes les maps sont chargées |
| `packages/map_core/lib/src/operations/border_feature_update_operations.dart` | paramètres, keep-outs, fingerprint et Apply | fournit les mutations pures 10A/10B et les no-ops optimistes |
| `packages/map_core/lib/src/operations/border_ground_resolution.dart` | résolution bornée et réutilisation distante | permet le ground organique local sans branche de génération distante |
| `packages/map_core/lib/src/operations/border_linear_lattice.dart` | fragments, offsets et lineage | préserve l’identité et le namespace RNG après split/local update |
| `packages/map_core/lib/src/operations/border_resize.dart` | `resizeBorderLayerContent`, diagnostics, crop/pad et clipping | rend le cycle de vie Border au resize déterministe sans gérer lui-même la rétention catalogue |
| `packages/map_core/lib/src/operations/border_stroke_editing.dart` | helpers de lineage et IDs de fragments | partage les invariants d’identité ; le clipping resize reste spécialisé dans `border_resize.dart` |
| `packages/map_core/lib/src/operations/masonry_line_border_resolver.dart` | overrides et scope local | active 10A et 10D sur les murets sans solveur parallèle |
| `packages/map_core/lib/src/operations/organic_edge_border_resolver.dart` | overrides, edge band et scope local | active 10A/10D pour les côtes et conserve le sol organique |
| `packages/map_core/lib/src/operations/post_and_rail_line_border_resolver.dart` | overrides et scope local | active 10A et 10D sur les clôtures |

### `map_core` — tests existants étendus

| Fichier | Couverture ajoutée |
|---|---|
| `packages/map_core/test/border/border_catalog_operations_test.dart` | rétention conservative, manifeste exhaustif/incomplet et liste de maps chargées |
| `packages/map_core/test/border/border_feature_update_operations_test.dart` | paramètres, effacement explicite, keep-outs et no-ops |
| `packages/map_core/test/border/border_resize_test.dart` | crop/pad, clip/split, culling ground/placements, fingerprint, matérialisation vide, absence de régénération et byte-équivalence au resize legacy |
| `packages/map_core/test/border/border_stroke_editing_test.dart` | lineage et fragmentation stable |
| `packages/map_core/test/border/masonry_line_border_resolver_test.dart` | overrides et résolution bornée masonry |
| `packages/map_core/test/border/organic_edge_border_resolver_test.dart` | overrides, sol et résolution bornée organique |
| `packages/map_core/test/border/post_and_rail_line_border_resolver_test.dart` | overrides et résolution bornée fence |

### `map_editor` — production

| Fichier | Classes / fonctions / zones modifiées | Raison et impact |
|---|---|---|
| `packages/map_editor/lib/src/application/use_cases/map_use_cases.dart` | `ResizeMapUseCase` et résultat Border-aware | transmet `tileSizePx`, diagnostics et résultat atomique |
| `packages/map_editor/lib/src/features/border_map_editing/application/border_feature_authoring_controller.dart` | six corrections et `BorderBlueprintChangePreview`/relink | prépare les drafts et garde l’identité/révision cible sans mutation anticipée |
| `packages/map_editor/lib/src/features/border_map_editing/application/border_preview_controller.dart` | `beginUpdatePreview`, `previewFeatureDraft`, `apply`, `keepMaterialized` | porte Update/Keep et garde les corrections locales preview-only |
| `packages/map_editor/lib/src/features/border_map_editing/presentation/border_diagnostic_presentation.dart` | 19 diagnostics resize | fournit libellés et remédiations FR exacts |
| `packages/map_editor/lib/src/features/border_map_editing/presentation/border_layer_inspector_panel.dart` | formulaires guidés, Update/Keep, relink et feedback resize | expose le cycle 10A–10E sans JSON manuel ni primitives UI ad hoc |
| `packages/map_editor/lib/src/features/border_map_editing/state/border_preview_providers.dart` | `BorderResizeFeedback`, `borderResizeFeedbackProvider` et import `map_core` | lie le feedback resize transitoire à l’identité exacte de la carte |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | relink, resize et gardes catalogue | garantit une mutation/historique unique et refuse les previews obsolètes |

### `map_editor` — tests existants étendus

| Fichier | Couverture ajoutée |
|---|---|
| `packages/map_editor/test/border_layer_inspector_test.dart` | six actions, Update/Keep, relink, Cancel/Apply et feedback resize lié à la carte |
| `packages/map_editor/test/border_map_editing/border_diagnostic_presentation_test.dart` | catalogue FR des diagnostics resize |
| `packages/map_editor/test/border_map_editing/border_feature_authoring_controller_test.dart` | corrections, no-ops, locks, keep-outs et lifecycle |
| `packages/map_editor/test/border_map_editing/border_feature_editor_integration_test.dart` | identité projet/carte, drift catalogue, relink et historique atomique |
| `packages/map_editor/test/border_map_editing/border_preview_controller_test.dart` | draft preview-only, Apply et Cancel |
| `packages/map_editor/test/border_map_editing/map_canvas_border_selection_test.dart` | sélection par ID authored malgré le lineage persistant |

Aucune couleur produit codée en dur n’a été ajoutée. La recherche des lignes
ajoutées sur `Color(0x` et `Colors.` est vide.

## 8. Fichiers créés

### Production core

- `packages/map_core/lib/src/operations/border_local_resolution_scope.dart` :
  baseline interne, capture de génération et état local public minimal.
- `packages/map_core/lib/src/operations/border_locality.dart` : dirty halo,
  baseline initiale, résolution locale et fusion canonique.
- `packages/map_core/lib/src/operations/border_override_resolution.dart` :
  pipeline commun d’overrides, keep-outs, locks et réutilisation locale.
- `packages/map_core/lib/src/operations/border_relink_operations.dart` : preview
  même famille, pertes inter-familles et Apply/reset optimistes.

### Tests

- `packages/map_core/test/border/border_locality_test.dart`
- `packages/map_core/test/border/border_override_resolution_test.dart`
- `packages/map_core/test/border/border_relink_operations_test.dart`
- `packages/map_editor/test/border_map_editing/border_resize_editor_integration_test.dart`

## 9. Manifeste byte-complet des fichiers créés

Les fichiers créés sont les sources de vérité versionnées. Le manifeste donne
leur empreinte byte pour byte ; l’Annexe B reproduit intégralement leurs 4 300
lignes et les SHA-256 vérifient que chaque copie est identique à sa source. Le
contenu reste aussi récupérable par `git show <commit>:<chemin>` après commit.

| Fichier | Lignes | Octets | SHA-256 |
|---|---:|---:|---|
| `border_local_resolution_scope.dart` | 183 | 6436 | `0d6a801bd02e1c52df87b300891baa154fad13b6740134e8a6b6c218634a54c8` |
| `border_locality.dart` | 411 | 15057 | `99c320ee41ba4d061f427a3e3590e465503c9d19ca84960acdaa454325c578fd` |
| `border_override_resolution.dart` | 886 | 28175 | `c50e7ecf45301a05425da5154890eb47d1acbd4d6ccb8bbef0d99c7a0501ba6a` |
| `border_relink_operations.dart` | 395 | 12836 | `e68da586c01eff78f5704e6f2c76893aa85e95a610b9a46df70422c3fa3a4f8b` |
| `border_locality_test.dart` | 1160 | 41361 | `31921ea174a9abef584a11cecb5732875921b448bf6958f68866e213d25d2f83` |
| `border_override_resolution_test.dart` | 694 | 23578 | `c837d1b792193971d644551c3a7c0981bcf4b81b578889cf70a684e710142616` |
| `border_relink_operations_test.dart` | 321 | 11818 | `bc804767b1913bd618d78653748ba337d45aa3135b10908c678a6b6c1c086025` |
| `border_resize_editor_integration_test.dart` | 250 | 8293 | `a023c9361f5448d1824c5f6ec3cc3b7f6e654013d6b1af96da9f7ebbeff277e5` |

Le rapport lui-même est ajouté au même commit ; son hash n’est volontairement
pas auto-référencé.

## 10. Zones précises du diff

| Zone | Transformation vérifiée |
|---|---|
| Résolution | base solver → `resolveBorderOverrides` → validation/couverture canonique |
| Mutation de feature | copie immuable ciblée par `layerId` + `featureId`, no-op si fingerprint divergent |
| Relink | `prepareBorderFeatureRelink` → confirmation UI → Apply même famille ou reset explicite |
| Localité | baseline pré-override/résolue → halo sale → génération bornée → fusion distante byte-identique |
| Resize | resize générique de carte → adaptation Border pure → un seul remplacement de carte dans l’historique |
| UI | champs guidés design-system → draft preview → transaction Apply/Cancel existante |
| Diagnostics | codes core stables → présentation FR → feedback transitoire lié à l’identité de carte |

Le diff fonctionnel contient 30 fichiers suivis modifiés et 8 fichiers créés,
avant ajout de ce rapport. Il ne contient aucun fichier `map_runtime` ni fichier
de modèle collision. Les trois occurrences ajoutées du mot `collision` sont
toutes dans des tests :

- l’expression de test `collision-free ids`, qui concerne l’unicité des IDs de
  fragments ;
- un fixture de resize enrichi pour vérifier que les tableaux Collision sont
  byte-équivalents au résultat du resize legacy et que l’ordre des calques est
  inchangé ;
- le helper `_map(collision: collision)` d’un test d’intégration, qui fournit
  un contexte de carte sans ajouter de comportement collision.

Aucune nouvelle logique BORD de génération ou d’authoring de collisions n’a
été introduite ; le résultat des tableaux Collision reste byte-équivalent au
resize legacy.

## 11. Tests et résultats exacts

### Suites Border core — deux processus frais

```bash
cd packages/map_core
dart test test/border -r compact
```

```text
pass 1 : 702/702 — All tests passed!
pass 2 : 702/702 — All tests passed!
```

### Corpus BORD-07 éditeur — deux processus frais

```bash
cd packages/map_editor
flutter test --no-pub -r compact \
  test/border_map_editing \
  test/border_layer_inspector_test.dart \
  test/border_layer_dispatch_integration_test.dart
```

```text
pass 1 : 128/128 — All tests passed!
pass 2 : 128/128 — All tests passed!
```

### Suite complète du package core

```bash
cd packages/map_core
dart test -r compact
```

```text
3465/3465 — All tests passed!
```

### Preuves ciblées produites pendant les corrections

```text
localité seule                         : 15/15 — All tests passed!
7 suites core localité/résolveurs      : 127/127 — All tests passed!
sélection éditeur après lineage        : 9/9 — All tests passed!
resize core                            : 23/23 — All tests passed!
resize + authoring + intégration       : 18/18 — All tests passed!
corpus éditeur avant hardening final   : 122/122 — All tests passed!
revue indépendante, 9 suites core      : 169/169 — All tests passed!
revue indépendante, fraîcheur/valid.   : 38/38 — All tests passed!
revue indépendante, 7 suites éditeur   : 63/63 — All tests passed!
```

Les tests couvrent les chemins positifs, les rejets, les conflits optimistes,
les no-ops, les identités obsolètes, la non-régression distante, le resize vide
et l’absence de mutation/historique avant Apply.

## 12. Analyse et build

### `map_core`

```bash
cd packages/map_core && dart analyze
```

```text
Analyzing map_core...
No issues found!
exit 0
```

### Analyse ciblée des 14 fichiers éditeur BORD-07

```bash
cd packages/map_editor
flutter analyze --no-pub <14 fichiers production/tests BORD-07>
```

```text
Analyzing 14 items...
No issues found! (ran in 2.8s)
exit 0
```

### Analyse globale de `map_editor`

```bash
cd packages/map_editor && flutter analyze --no-pub
```

```text
451 issues found. (ran in 4.7s)
exit 1
```

Les erreurs commencent notamment dans
`lib/src/application/services/pokemon_sdk_move_catalog_converter.dart`
(`dbSymbol`, `battleEngineAimedTarget`, `PokemonMoveAimedTarget`,
`PokemonMoveFlags`, etc.). Ces fichiers ne figurent pas dans le diff BORD-07.
L’analyse ciblée de tous les fichiers éditeur modifiés par le lot est propre ;
le résultat global n’est donc pas présenté comme vert.

### Build obligatoire

```bash
cd packages/map_editor
flutter build macos --debug --no-pub
```

```text
✓ Built build/macos/Build/Products/Debug/map_editor.app
exit 0
```

### Vérifications mécaniques

```text
git diff --check                                      => exit 0
lignes UI ajoutées avec Color(0x ou Colors.           => 0
fichiers map_runtime modifiés                         => 0
fichiers de modèle collision modifiés                 => 0
appel resolveBorderFeature dans le chemin local       => 0
```

## 13. État Git avant commit

```text
30 fichiers BORD-07 suivis modifiés
8 fichiers BORD-07 créés
1 Evidence Pack BORD-07 créé
3 fichiers externes laissés hors lot :
  M examples/.DS_Store
  M packages/.DS_Store
  M packages/map_editor/pubspec.lock
```

Le staging et le commit doivent inclure uniquement les 39 fichiers BORD-07
inventoriés, rapport compris. Après commit, les trois entrées externes doivent
rester visibles et intactes dans le worktree.

## 14. Limites conservées et risques restants

- Après rechargement du projet, une résolution complète initiale reste
  nécessaire pour reconstruire la baseline éphémère ; les gestes suivants
  utilisent ensuite `nextState` localement.
- La génération coûteuse de placements/ground est locale. Les réductions
  globales de topologie, couverture, tri, diagnostics et fingerprint parcourent
  encore la trace fusionnée. Une optimisation mesurée appartient à BORD-08.
- La rétention de snapshots fournit les IDs supprimables ; la suppression
  physique reste volontairement la responsabilité du stockage/manifest.
- Un remplacement de primitive proposé par l’UI reste validé par le solveur ;
  une combinaison de transform incompatible produit un diagnostic au lieu
  d’être inventée ou normalisée silencieusement.
- L’analyse globale de l’éditeur conserve 451 diagnostics hors Border.
- Les tests prouvent les contrats et goldens existants, pas la qualité
  artistique d’un catalogue d’assets futur.

## 15. Auto-critique finale

Points solides : le lot ne crée ni second Apply pour les corrections/Update,
ni état persistant caché, ni fallback runtime. Le relink garde explicitement sa
confirmation atomique dédiée. Les conflits d’identité/révision sont testés, la localité est
prouvée par parité canonique et réutilisation distante, le resize est atomique,
et deux revues ont effectivement bloqué 10E jusqu’à son intégration éditeur
réelle.

Points perfectibles : `border_override_resolution.dart` et les solveurs restent
volumineux. Une abstraction supplémentaire pendant BORD-07 aurait toutefois
augmenté le risque de divergence entre les trois familles. La baseline locale
est volontairement éphémère et peut coûter une résolution complète après
reload ; ce compromis garde le JSON simple et respecte la décision de ne jamais
générer au runtime.

Le manifeste SHA-256 et l’Annexe B rendent les huit fichiers créés vérifiables
et les reproduisent intégralement. Cette duplication alourdit le rapport mais
respecte littéralement la règle de clôture ; les sources versionnées restent le
contenu opposable.

## 16. Prochaine étape proposée

**BORD-08** peut maintenant se concentrer sur la robustesse et l’usage réel :

1. profilage des très longues bordures et réduction des parcours globaux
   restants ;
2. tests de charge et budgets déterministes ;
3. polish ergonomique issu d’une session d’utilisation réelle dans World Maps ;
4. documentation utilisateur du format d’assets et des diagnostics.

Toujours sans nouvelle logique BORD de collision et sans génération au runtime.

## Annexe A — Index exact des hunks des fichiers modifiés

Cet index est produit par `git diff --unified=0 6bde50f0` en excluant les
trois fichiers externes. Chaque en-tête `@@` donne les lignes source et cible
exactes de la zone modifiée ; les sections 7 et 10 expliquent leur fonction.

```text
diff --git a/packages/map_core/lib/map_core.dart b/packages/map_core/lib/map_core.dart
@@ -71,0 +72,2 @@ export 'src/operations/border_resize.dart';
@@ -77,0 +80,3 @@ export 'src/operations/border_linear_lattice.dart';
diff --git a/packages/map_core/lib/src/operations/border_catalog_operations.dart b/packages/map_core/lib/src/operations/border_catalog_operations.dart
@@ -3,0 +4,132 @@ import '../models/border_catalog.dart';
diff --git a/packages/map_core/lib/src/operations/border_feature_update_operations.dart b/packages/map_core/lib/src/operations/border_feature_update_operations.dart
@@ -7,0 +8 @@ import '../models/border_signed_int64.dart';
@@ -56,0 +58,48 @@ MapData updateBorderFeatureOverrides(
diff --git a/packages/map_core/lib/src/operations/border_ground_resolution.dart b/packages/map_core/lib/src/operations/border_ground_resolution.dart
@@ -5,0 +6,3 @@ import '../models/border_materialization.dart';
@@ -50,0 +54,130 @@ List<BorderResolvedGroundCell> resolveBorderGroundBand({
diff --git a/packages/map_core/lib/src/operations/border_linear_lattice.dart b/packages/map_core/lib/src/operations/border_linear_lattice.dart
@@ -0,0 +1,3 @@
@@ -9,0 +13,182 @@ final BigInt _maximumPortableJsonInteger = BigInt.parse('9007199254740991');
@@ -73,0 +259 @@ final class BorderLinearEdge {
@@ -83,0 +270 @@ final class BorderLinearEdge {
@@ -98 +285,2 @@ final class BorderLinearEdge {
@@ -109,0 +298 @@ final class BorderLinearEdge {
@@ -117,0 +307,5 @@ final class BorderLinearStrokeLattice {
@@ -124,0 +319 @@ final class BorderLinearStrokeLattice {
@@ -125,0 +321,9 @@ final class BorderLinearStrokeLattice {
@@ -138,0 +343,5 @@ final class BorderLinearStrokeLattice {
@@ -146,0 +356,5 @@ final class BorderLinearStrokeLattice {
@@ -171 +385,2 @@ BorderLinearStrokeLattice buildBorderLinearLatticeV1({
@@ -176,2 +391,5 @@ BorderLinearStrokeLattice buildBorderLinearLatticeV1({
@@ -199,0 +418,10 @@ BorderLinearStrokeLattice buildBorderLinearLatticeV1({
@@ -209,0 +438 @@ BorderLinearStrokeLattice buildBorderLinearLatticeV1({
@@ -219 +448 @@ BorderLinearStrokeLattice buildBorderLinearLatticeV1({
@@ -249,2 +478,7 @@ BorderLinearStrokeLattice buildBorderLinearLatticeV1({
@@ -285,0 +520,47 @@ void _requirePortableInt(int value, String field) {
diff --git a/packages/map_core/lib/src/operations/border_resize.dart b/packages/map_core/lib/src/operations/border_resize.dart
@@ -9,0 +10 @@ import 'border_fingerprints.dart';
@@ -12,0 +14 @@ const int _maximumPortableInteger = 9007199254740991;
@@ -54,3 +56,3 @@ final class BorderLayerResizeResult {
@@ -88 +89,0 @@ BorderLayerResizeResult resizeBorderLayerContent({
@@ -204 +204,0 @@ void _preflightFeature({
@@ -228,23 +228,2 @@ void _preflightFeature({
@@ -337 +316,7 @@ BorderFeature _resizeFeature({
@@ -374,0 +360,200 @@ BorderFeature _resizeFeature({
diff --git a/packages/map_core/lib/src/operations/border_stroke_editing.dart b/packages/map_core/lib/src/operations/border_stroke_editing.dart
@@ -2,0 +3 @@ import '../models/geometry.dart';
@@ -4,0 +6,2 @@ import 'border_stroke_canonicalization.dart';
@@ -82,2 +85,3 @@ final class BorderStrokeEditingDraft {
@@ -94,0 +99 @@ final class BorderStrokeEditingDraft {
@@ -100 +105 @@ final class BorderStrokeEditingDraft {
@@ -102,2 +107,2 @@ final class BorderStrokeEditingDraft {
@@ -105 +110 @@ final class BorderStrokeEditingDraft {
@@ -107 +112 @@ final class BorderStrokeEditingDraft {
@@ -109 +114 @@ final class BorderStrokeEditingDraft {
@@ -111,4 +116,5 @@ final class BorderStrokeEditingDraft {
@@ -126 +132,3 @@ String _firstFreeStrokeId(BorderStrokeGeometry geometry) {
@@ -166 +174 @@ List<GridPos> _rasterizeGesture(List<GridPos> samples) {
@@ -170 +178 @@ List<List<GridPos>> _splitOpenStroke(
@@ -172 +180,3 @@ List<List<GridPos>> _splitOpenStroke(
@@ -174 +184,3 @@ List<List<GridPos>> _splitOpenStroke(
@@ -175,0 +188 @@ List<List<GridPos>> _splitOpenStroke(
@@ -176,0 +190 @@ List<List<GridPos>> _splitOpenStroke(
@@ -180 +194,3 @@ List<List<GridPos>> _splitOpenStroke(
@@ -184 +200 @@ List<List<GridPos>> _splitOpenStroke(
@@ -189 +205 @@ List<List<GridPos>> _splitTouchedClosedStroke(
@@ -190,0 +207 @@ List<List<GridPos>> _splitTouchedClosedStroke(
@@ -192 +209,2 @@ List<List<GridPos>> _splitTouchedClosedStroke(
@@ -194 +212,3 @@ List<List<GridPos>> _splitTouchedClosedStroke(
@@ -195,0 +216 @@ List<List<GridPos>> _splitTouchedClosedStroke(
@@ -196,0 +218 @@ List<List<GridPos>> _splitTouchedClosedStroke(
@@ -200 +222,3 @@ List<List<GridPos>> _splitTouchedClosedStroke(
diff --git a/packages/map_core/lib/src/operations/masonry_line_border_resolver.dart b/packages/map_core/lib/src/operations/masonry_line_border_resolver.dart
@@ -14,0 +15,2 @@ import 'border_linear_lattice.dart';
@@ -89,2 +91,3 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -130,16 +132,0 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -156,0 +144 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -169 +157 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -175,0 +164 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -181 +170 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -186 +175 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -202 +191 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -254 +243,12 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -257,0 +258,26 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -260 +286,9 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -269 +303 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -275 +309 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -283 +317 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -295 +329 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -301 +335,2 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -330,49 +364,0 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -384,0 +371 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -391,0 +379 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -394,0 +383,47 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -446,0 +482,98 @@ MasonryLineBorderResolutionEvidence resolveMasonryLineBorderWithEvidence(
@@ -620 +753 @@ List<int> _sitesForEdge(
@@ -641 +774 @@ List<int> _sitesForEdge(
@@ -666 +799,2 @@ _GeneratedLinePlacement? _resolveStructuralPlacement({
@@ -678,0 +813 @@ _GeneratedLinePlacement? _resolveStructuralPlacement({
@@ -684 +819 @@ _GeneratedLinePlacement? _resolveStructuralPlacement({
@@ -696 +831 @@ _GeneratedLinePlacement? _resolveStructuralPlacement({
@@ -718 +853 @@ _GeneratedLinePlacement? _resolveStructuralPlacement({
@@ -727 +862 @@ _GeneratedLinePlacement? _resolveStructuralPlacement({
@@ -736 +871 @@ _GeneratedLinePlacement? _resolveStructuralPlacement({
@@ -751 +886 @@ _GeneratedLinePlacement? _resolveStructuralPlacement({
@@ -780 +915 @@ _GeneratedLinePlacement? _resolveStructuralPlacement({
@@ -797,0 +933 @@ _GeneratedLinePlacement? _resolveStructuralPlacement({
@@ -820,0 +957 @@ void _resolveTerminations({
@@ -863,0 +1001,5 @@ void _resolveTerminations({
@@ -899 +1041 @@ void _resolveTerminations({
@@ -917,0 +1060 @@ void _resolveTerminations({
@@ -942,0 +1086 @@ void _resolveSurfacePatches({
@@ -951,2 +1095,10 @@ void _resolveSurfacePatches({
@@ -958 +1110 @@ void _resolveSurfacePatches({
@@ -962 +1114 @@ void _resolveSurfacePatches({
@@ -970 +1122 @@ void _resolveSurfacePatches({
@@ -978 +1130 @@ void _resolveSurfacePatches({
@@ -990 +1142,2 @@ void _resolveSurfacePatches({
@@ -1059,0 +1213 @@ _EdgeCoverage _assessEdgeCoverage({
@@ -1084,0 +1239,11 @@ _EdgeCoverage _assessEdgeCoverage({
@@ -1086,0 +1252 @@ _EdgeCoverage _assessEdgeCoverage({
@@ -1093,0 +1260 @@ _EdgeCoverage _assessCoverageDomain({
@@ -1100,17 +1267,24 @@ _EdgeCoverage _assessCoverageDomain({
@@ -1118 +1292 @@ _EdgeCoverage _assessCoverageDomain({
@@ -1333,0 +1508,65 @@ List<_Interval> _mergeIntervals(Iterable<_Interval> source) {
@@ -1384 +1623 @@ BorderDeterministicRng _decisionRng(
@@ -1393 +1632 @@ BorderDeterministicRng _decisionRng(
@@ -1444,0 +1684,6 @@ BorderPixelPos _cellCenterWorldPx(
@@ -1561,0 +1807,60 @@ BorderDiagnostic _warning(
@@ -1563,0 +1869 @@ final class _GeneratedLinePlacement {
@@ -1568,0 +1875 @@ final class _GeneratedLinePlacement {
diff --git a/packages/map_core/lib/src/operations/organic_edge_border_resolver.dart b/packages/map_core/lib/src/operations/organic_edge_border_resolver.dart
@@ -16,0 +17,2 @@ import 'border_ground_resolution.dart';
@@ -177,2 +179,3 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -233,9 +235,0 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -305,8 +299,15 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -316 +317,12 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -374,0 +387,8 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -465,0 +486,8 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -498,0 +527,39 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -502,0 +570,2 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -527 +596,2 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -548 +618 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -559 +629 @@ OrganicEdgeBorderResolutionEvidence resolveOrganicEdgeBorderWithEvidence(
@@ -1120,0 +1191,96 @@ int _floorDiv(int value, int positiveDivisor) {
@@ -1274,0 +1441,2 @@ List<OrganicEdgeContourEvidence> _diagnoseCoverage(
@@ -1284,5 +1452,17 @@ List<OrganicEdgeContourEvidence> _diagnoseCoverage(
@@ -1353,0 +1534,52 @@ List<OrganicEdgeContourEvidence> _diagnoseCoverage(
diff --git a/packages/map_core/lib/src/operations/post_and_rail_line_border_resolver.dart b/packages/map_core/lib/src/operations/post_and_rail_line_border_resolver.dart
@@ -14,0 +15,2 @@ import 'border_linear_lattice.dart';
@@ -93,3 +95,3 @@ PostAndRailLineBorderResolutionEvidence
@@ -143,20 +144,0 @@ PostAndRailLineBorderResolutionEvidence
@@ -175,0 +158 @@ PostAndRailLineBorderResolutionEvidence
@@ -189 +172 @@ PostAndRailLineBorderResolutionEvidence
@@ -196,0 +180 @@ PostAndRailLineBorderResolutionEvidence
@@ -202 +186 @@ PostAndRailLineBorderResolutionEvidence
@@ -208 +192 @@ PostAndRailLineBorderResolutionEvidence
@@ -226 +210 @@ PostAndRailLineBorderResolutionEvidence
@@ -305 +289,12 @@ PostAndRailLineBorderResolutionEvidence
@@ -307 +302,5 @@ PostAndRailLineBorderResolutionEvidence
@@ -309 +307,0 @@ PostAndRailLineBorderResolutionEvidence
@@ -310,0 +309,5 @@ PostAndRailLineBorderResolutionEvidence
@@ -313 +316 @@ PostAndRailLineBorderResolutionEvidence
@@ -352 +355,2 @@ PostAndRailLineBorderResolutionEvidence
@@ -377,54 +380,0 @@ PostAndRailLineBorderResolutionEvidence
@@ -433,0 +384,5 @@ PostAndRailLineBorderResolutionEvidence
@@ -440,0 +396 @@ PostAndRailLineBorderResolutionEvidence
@@ -444 +400 @@ PostAndRailLineBorderResolutionEvidence
@@ -449 +405 @@ PostAndRailLineBorderResolutionEvidence
@@ -454 +410 @@ PostAndRailLineBorderResolutionEvidence
@@ -459 +415 @@ PostAndRailLineBorderResolutionEvidence
@@ -465 +421,2 @@ PostAndRailLineBorderResolutionEvidence
@@ -470 +427 @@ PostAndRailLineBorderResolutionEvidence
@@ -496,0 +454 @@ PostAndRailLineBorderResolutionEvidence
@@ -499,0 +458,47 @@ PostAndRailLineBorderResolutionEvidence
@@ -553,0 +559,102 @@ PostAndRailLineBorderResolutionEvidence
@@ -695 +802 @@ _SpanPacking? _packSpans({
@@ -703 +810 @@ _SpanPacking? _packSpans({
@@ -719 +826 @@ _SpanPacking? _packSpans({
@@ -743 +850 @@ _SpanPackingAttempt? _packSpanPrimitive({
@@ -750 +857 @@ _SpanPackingAttempt? _packSpanPrimitive({
@@ -860 +967,2 @@ _GeneratedPlacement? _spanPlacement({
@@ -886 +994,2 @@ _GeneratedPlacement? _spanPlacement({
@@ -903,0 +1013 @@ void _resolveOptionalDetails({
@@ -906,0 +1017,5 @@ void _resolveOptionalDetails({
@@ -927 +1042 @@ void _resolveOptionalDetails({
@@ -939 +1054 @@ void _resolveOptionalDetails({
@@ -949 +1064 @@ void _resolveOptionalDetails({
@@ -960 +1075,2 @@ void _resolveOptionalDetails({
@@ -977 +1093 @@ BorderPublishedPrimitive _choosePrimitive(
@@ -991 +1107 @@ BorderPublishedPrimitive _choosePrimitive(
@@ -1012 +1128 @@ BorderSpriteTransform _chooseTransform(
@@ -1025 +1141 @@ BorderSpriteTransform _chooseTransform(
@@ -1041 +1157,2 @@ _GeneratedPlacement? _placementForEdge({
@@ -1069 +1186 @@ _GeneratedPlacement? _placementForEdge({
@@ -1097,0 +1215 @@ _GeneratedPlacement? _placementForEdge({
@@ -1107,0 +1226,23 @@ _Coverage _assessEdgeCoverage({
@@ -1127,4 +1268 @@ _Coverage _assessEdgeCoverage({
@@ -1136,0 +1275,24 @@ _Coverage _assessStrokeCoverage({
@@ -1170,5 +1332 @@ _Coverage _assessStrokeCoverage({
@@ -1178,0 +1337 @@ _Coverage _assessIntervals({
@@ -1201,15 +1360,27 @@ _Coverage _assessIntervals({
@@ -1218 +1389 @@ _Coverage _assessIntervals({
@@ -1431,0 +1603,64 @@ List<_Interval> _mergeIntervals(Iterable<_Interval> source) {
@@ -1451 +1686 @@ BorderDeterministicRng _decisionRng(
@@ -1460 +1695 @@ BorderDeterministicRng _decisionRng(
@@ -1472 +1707 @@ bool _passesPermille(
@@ -1484 +1719 @@ bool _passesPermille(
@@ -1657,0 +1893,60 @@ final class _SpanPackingAttempt {
@@ -1659,0 +1955 @@ final class _GeneratedPlacement {
@@ -1664,0 +1961 @@ final class _GeneratedPlacement {
diff --git a/packages/map_core/test/border/border_catalog_operations_test.dart b/packages/map_core/test/border/border_catalog_operations_test.dart
@@ -426,0 +427,81 @@ void main() {
@@ -436,0 +518 @@ BorderBlueprintRecord _record(
@@ -437,0 +520 @@ BorderBlueprintRecord _record(
@@ -442 +525 @@ BorderBlueprintRecord _record(
@@ -453 +536 @@ BorderBlueprintRecord _record(
@@ -461 +544,4 @@ BorderBlueprintRecord _record(
@@ -469,0 +556,21 @@ BorderBlueprintRecord _record(
@@ -492,0 +600,167 @@ BorderVisualSnapshot _snapshot(String digit) {
diff --git a/packages/map_core/test/border/border_feature_update_operations_test.dart b/packages/map_core/test/border/border_feature_update_operations_test.dart
@@ -15,2 +15 @@ void main() {
@@ -25,0 +25,4 @@ void main() {
@@ -66,0 +70,26 @@ void main() {
@@ -75,2 +104,8 @@ void main() {
@@ -82,0 +118,14 @@ void main() {
diff --git a/packages/map_core/test/border/border_resize_test.dart b/packages/map_core/test/border/border_resize_test.dart
@@ -60,0 +61 @@ void main() {
@@ -335 +336,101 @@ void main() {
@@ -343 +444 @@ void main() {
@@ -347,0 +449,6 @@ void main() {
@@ -350,0 +458,14 @@ void main() {
@@ -356,2 +477,2 @@ void main() {
@@ -362,11 +483,99 @@ void main() {
@@ -742,12 +951 @@ void main() {
@@ -825,2 +1023,2 @@ void main() {
@@ -827,0 +1026 @@ void main() {
@@ -847,0 +1047 @@ void main() {
@@ -848,0 +1049,4 @@ void main() {
@@ -873,0 +1078 @@ BorderFeature _feature({
@@ -881 +1086 @@ BorderFeature _feature({
@@ -1009,0 +1215,5 @@ MapData _mapWithCollisionLayersAndBorder() => MapData(
@@ -1030,0 +1241 @@ MapData _mapWithCollisionLayersAndBorder() => MapData(
diff --git a/packages/map_core/test/border/border_stroke_editing_test.dart b/packages/map_core/test/border/border_stroke_editing_test.dart
@@ -96,0 +97,3 @@ void main() {
@@ -98 +101 @@ void main() {
@@ -100,0 +104,8 @@ void main() {
@@ -120 +131 @@ void main() {
@@ -132 +143,6 @@ void main() {
@@ -172 +188,7 @@ void main() {
@@ -198,0 +221,3 @@ void main() {
@@ -200 +225 @@ void main() {
@@ -202,0 +228,4 @@ void main() {
diff --git a/packages/map_core/test/border/masonry_line_border_resolver_test.dart b/packages/map_core/test/border/masonry_line_border_resolver_test.dart
@@ -682 +682 @@ void main() {
@@ -683,0 +684,2 @@ void main() {
@@ -690 +692,2 @@ void main() {
@@ -694,2 +697 @@ void main() {
@@ -699 +701 @@ void main() {
@@ -705,0 +708,2 @@ void main() {
@@ -707,0 +712,28 @@ void main() {
@@ -718 +750 @@ void main() {
@@ -720,14 +752,6 @@ void main() {
diff --git a/packages/map_core/test/border/organic_edge_border_resolver_test.dart b/packages/map_core/test/border/organic_edge_border_resolver_test.dart
@@ -709,2 +709,8 @@ void main() {
@@ -711,0 +718,10 @@ void main() {
@@ -714 +730 @@ void main() {
@@ -721,0 +738 @@ void main() {
@@ -723 +740,6 @@ void main() {
@@ -726 +748,16 @@ void main() {
diff --git a/packages/map_core/test/border/post_and_rail_line_border_resolver_test.dart b/packages/map_core/test/border/post_and_rail_line_border_resolver_test.dart
@@ -795 +795,6 @@ void main() {
@@ -800 +805 @@ void main() {
@@ -816 +821,4 @@ void main() {
@@ -822,3 +829,0 @@ void main() {
@@ -829 +833,0 @@ void main() {
@@ -831,2 +835,3 @@ void main() {
@@ -835,2 +840,3 @@ void main() {
@@ -839,2 +845,2 @@ void main() {
@@ -841,0 +848,9 @@ void main() {
diff --git a/packages/map_editor/lib/src/application/use_cases/map_use_cases.dart b/packages/map_editor/lib/src/application/use_cases/map_use_cases.dart
@@ -121,4 +121,17 @@ class ResizeMapUseCase {
diff --git a/packages/map_editor/lib/src/features/border_map_editing/application/border_feature_authoring_controller.dart b/packages/map_editor/lib/src/features/border_map_editing/application/border_feature_authoring_controller.dart
@@ -33,2 +33 @@ final class BorderBlueprintFeaturePreviewState {
@@ -36,0 +36 @@ final class BorderBlueprintChangePreview {
@@ -40,0 +41,2 @@ final class BorderBlueprintChangePreview {
@@ -47,0 +50,2 @@ final class BorderBlueprintChangePreview {
@@ -51,0 +56,2 @@ final class BorderBlueprintChangePreview {
@@ -61,0 +68 @@ final class BorderBlueprintChangePreview {
@@ -157,0 +165,146 @@ final class BorderFeatureAuthoringController {
@@ -163,0 +317,3 @@ final class BorderFeatureAuthoringController {
@@ -167,2 +323,10 @@ final class BorderFeatureAuthoringController {
@@ -174,47 +338,36 @@ final class BorderFeatureAuthoringController {
@@ -222,0 +376 @@ final class BorderFeatureAuthoringController {
@@ -235,6 +389,5 @@ final class BorderFeatureAuthoringController {
@@ -256 +409 @@ final class BorderFeatureAuthoringController {
@@ -258,2 +411 @@ final class BorderFeatureAuthoringController {
@@ -273 +425 @@ final class BorderFeatureAuthoringController {
@@ -275,2 +427 @@ final class BorderFeatureAuthoringController {
@@ -287 +438,3 @@ final class BorderFeatureAuthoringController {
@@ -376,4 +529,72 @@ BorderFeature _copyFeature(
@@ -383 +604 @@ BorderFeature _relinkFeature(
@@ -389 +610 @@ BorderFeature _relinkFeature(
@@ -392,26 +613,12 @@ BorderFeature _relinkFeature(
@@ -422,0 +630,5 @@ void _assertPreviewIsCurrent(
diff --git a/packages/map_editor/lib/src/features/border_map_editing/application/border_preview_controller.dart b/packages/map_editor/lib/src/features/border_map_editing/application/border_preview_controller.dart
@@ -20,0 +21,28 @@ final class BorderPreviewController extends StateNotifier<BorderPreviewState> {
@@ -93,0 +122,49 @@ final class BorderPreviewController extends StateNotifier<BorderPreviewState> {
@@ -209,0 +287,3 @@ final class BorderPreviewController extends StateNotifier<BorderPreviewState> {
diff --git a/packages/map_editor/lib/src/features/border_map_editing/presentation/border_diagnostic_presentation.dart b/packages/map_editor/lib/src/features/border_map_editing/presentation/border_diagnostic_presentation.dart
@@ -86,0 +87,34 @@ String localizeEditorBorderDiagnostic(BorderDiagnostic diagnostic) {
diff --git a/packages/map_editor/lib/src/features/border_map_editing/presentation/border_layer_inspector_panel.dart b/packages/map_editor/lib/src/features/border_map_editing/presentation/border_layer_inspector_panel.dart
@@ -31,0 +32,4 @@ class _BorderLayerInspectorPanelState
@@ -37,0 +42 @@ class _BorderLayerInspectorPanelState
@@ -95,0 +101,4 @@ class _BorderLayerInspectorPanelState
@@ -105 +114,2 @@ class _BorderLayerInspectorPanelState
@@ -118,0 +129,5 @@ class _BorderLayerInspectorPanelState
@@ -126,0 +142,38 @@ class _BorderLayerInspectorPanelState
@@ -143,0 +197,4 @@ class _BorderLayerInspectorPanelState
@@ -232,0 +290,20 @@ class _BorderLayerInspectorPanelState
@@ -238 +315 @@ class _BorderLayerInspectorPanelState
@@ -547,0 +625,72 @@ class _BorderLayerInspectorPanelState
@@ -668,0 +818,267 @@ class _BorderLayerInspectorPanelState
@@ -732,0 +1149,21 @@ class _BorderLayerInspectorPanelState
@@ -991,0 +1429,63 @@ String _featurePreviewStateLabel(BorderBlueprintFeaturePreviewState state) {
diff --git a/packages/map_editor/lib/src/features/border_map_editing/state/border_preview_providers.dart b/packages/map_editor/lib/src/features/border_map_editing/state/border_preview_providers.dart
@@ -1,0 +2 @@ import 'package:flutter_riverpod/flutter_riverpod.dart';
@@ -14,0 +16,21 @@ final pendingBorderSaveGuardProvider = Provider<PendingBorderSaveGuard>((ref) {
diff --git a/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart b/packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
@@ -840,0 +841 @@ class EditorNotifier extends _$EditorNotifier {
@@ -843 +843,0 @@ class EditorNotifier extends _$EditorNotifier {
@@ -844,0 +845,46 @@ class EditorNotifier extends _$EditorNotifier {
@@ -851,2 +897 @@ class EditorNotifier extends _$EditorNotifier {
@@ -876,0 +922,10 @@ class EditorNotifier extends _$EditorNotifier {
@@ -7572,0 +7628 @@ class EditorNotifier extends _$EditorNotifier {
@@ -7598,0 +7655 @@ class EditorNotifier extends _$EditorNotifier {
@@ -7637,0 +7695 @@ class EditorNotifier extends _$EditorNotifier {
@@ -7673,0 +7732,11 @@ class EditorNotifier extends _$EditorNotifier {
@@ -7680,0 +7750,114 @@ class EditorNotifier extends _$EditorNotifier {
diff --git a/packages/map_editor/test/border_layer_inspector_test.dart b/packages/map_editor/test/border_layer_inspector_test.dart
@@ -87 +87,14 @@ void main() {
@@ -168 +181 @@ void main() {
@@ -202 +215 @@ void main() {
@@ -210,0 +224,20 @@ void main() {
@@ -269,0 +303,152 @@ void main() {
@@ -467,0 +653,63 @@ void main() {
@@ -573 +821,4 @@ ProjectManifest _project(List<BorderBlueprintRecord> records) =>
@@ -604 +855,6 @@ BorderBlueprintRecord _record(
@@ -657 +913,22 @@ BorderMaterialization _materialization() => BorderMaterialization(
@@ -658,0 +936,37 @@ BorderMaterialization _materialization() => BorderMaterialization(
diff --git a/packages/map_editor/test/border_map_editing/border_diagnostic_presentation_test.dart b/packages/map_editor/test/border_map_editing/border_diagnostic_presentation_test.dart
@@ -79,0 +80,39 @@ void main() {
diff --git a/packages/map_editor/test/border_map_editing/border_feature_authoring_controller_test.dart b/packages/map_editor/test/border_map_editing/border_feature_authoring_controller_test.dart
@@ -129,3 +129 @@ void main() {
@@ -136,17 +134,67 @@ void main() {
@@ -154 +202 @@ void main() {
@@ -156 +204 @@ void main() {
@@ -158,2 +205,0 @@ void main() {
@@ -165,9 +211,6 @@ void main() {
@@ -178 +221 @@ void main() {
@@ -183,7 +226,7 @@ void main() {
@@ -191,0 +235,12 @@ void main() {
@@ -203,4 +258,5 @@ void main() {
@@ -252,0 +309,2 @@ void main() {
@@ -257,0 +316,9 @@ void main() {
@@ -270,0 +338 @@ void main() {
@@ -302,0 +371,164 @@ void main() {
@@ -321,0 +554,2 @@ BorderBlueprintRecord _record({
@@ -344 +578 @@ BorderBlueprintRecord _record({
@@ -362,0 +597,37 @@ BorderGenerationParams _params() => BorderGenerationParams(
@@ -430,0 +702,21 @@ BorderMaterialization _materialization() => BorderMaterialization(
diff --git a/packages/map_editor/test/border_map_editing/border_feature_editor_integration_test.dart b/packages/map_editor/test/border_map_editing/border_feature_editor_integration_test.dart
@@ -4,0 +5,2 @@ import 'package:map_editor/src/features/border_map_editing/application/border_fe
@@ -5,0 +8 @@ import 'package:map_editor/src/features/border_map_editing/state/border_map_edit
@@ -69 +72,24 @@ void main() {
@@ -76,0 +103,2 @@ void main() {
@@ -78,0 +107 @@ void main() {
@@ -79,0 +109 @@ void main() {
@@ -177,0 +208,2 @@ void main() {
@@ -197 +229,11 @@ void main() {
@@ -206,0 +249,129 @@ void main() {
@@ -215 +386,4 @@ ProjectManifest _project(List<BorderBlueprintRecord> records) =>
@@ -245 +419,3 @@ BorderBlueprintRecord _record(
@@ -262,0 +439,65 @@ BorderGenerationParams _params() => BorderGenerationParams(
diff --git a/packages/map_editor/test/border_map_editing/border_preview_controller_test.dart b/packages/map_editor/test/border_map_editing/border_preview_controller_test.dart
@@ -147,0 +148,128 @@ void main() {
@@ -358,0 +487,42 @@ void main() {
diff --git a/packages/map_editor/test/border_map_editing/map_canvas_border_selection_test.dart b/packages/map_editor/test/border_map_editing/map_canvas_border_selection_test.dart
@@ -582 +582 @@ void main() {
@@ -584,0 +585,9 @@ void main() {
```

## Annexe B — Contenu intégral des fichiers créés

Les huit sources créées sont reproduites ci-dessous intégralement, en plus du
manifeste SHA-256 de la section 9.

### `packages/map_core/lib/src/operations/border_local_resolution_scope.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';

/// Canonical pre/post-override evidence required by later local edits.
final class BorderLocalResolutionState {
  BorderLocalResolutionState._({
    required this.request,
    required this.result,
    required List<BorderResolvedGroundCell> baseGround,
    required List<BorderResolvedPlacement> basePlacements,
  })  : _baseGround = List<BorderResolvedGroundCell>.unmodifiable(baseGround),
        _basePlacements =
            List<BorderResolvedPlacement>.unmodifiable(basePlacements) {
    if (result.materialization == null) {
      throw const ValidationException(
        'Border local baseline requires an applicable canonical result',
      );
    }
  }

  final BorderResolutionRequest request;
  final BorderResolutionResult result;
  final List<BorderResolvedGroundCell> _baseGround;
  final List<BorderResolvedPlacement> _basePlacements;

  BorderMaterialization get materialization => result.materialization!;

  List<BorderResolvedGroundCell> get baseGround => _baseGround;

  List<BorderResolvedPlacement> get basePlacements => _basePlacements;

  Map<String, BorderResolvedPlacement> get resolvedPlacementsBySlot =>
      <String, BorderResolvedPlacement>{
        for (final placement in materialization.placements)
          placement.slotKey: placement,
      };

  Set<String> get suppressedPlacementSlotKeys {
    final visible = <String>{
      for (final placement in materialization.placements) placement.slotKey,
    };
    return <String>{
      for (final placement in _basePlacements)
        if (!visible.contains(placement.slotKey)) placement.slotKey,
    };
  }
}

/// Mutable sink used only while producing one full local-edit baseline.
final class BorderLocalResolutionCapture {
  List<BorderResolvedGroundCell>? _baseGround;
  List<BorderResolvedPlacement>? _basePlacements;

  void recordBase({
    required Iterable<BorderResolvedGroundCell> ground,
    required Iterable<BorderResolvedPlacement> placements,
  }) {
    if (_baseGround != null || _basePlacements != null) {
      throw StateError('Border local base trace was already recorded');
    }
    _baseGround = ground.toList(growable: false);
    _basePlacements = placements.toList(growable: false);
  }

  BorderLocalResolutionState finish({
    required BorderResolutionRequest request,
    required BorderResolutionResult result,
  }) {
    final ground = _baseGround;
    final placements = _basePlacements;
    if (ground == null || placements == null) {
      throw const ValidationException(
        'Border local baseline could not capture pre-override output',
      );
    }
    return BorderLocalResolutionState._(
      request: request,
      result: result,
      baseGround: ground,
      basePlacements: placements,
    );
  }
}

/// Internal regeneration boundary shared by the three V1 template solvers.
///
/// The scope never resolves a Border itself. It only partitions persisted
/// output and records the source cells whose generation branch was entered.
final class BorderLocalResolutionScope {
  BorderLocalResolutionScope({
    required this.previousState,
    required Iterable<BorderPixelRect> affectedBoundsPx,
  }) : _affectedBoundsPx = List<BorderPixelRect>.unmodifiable(
          affectedBoundsPx,
        ) {
    final resolvedBySlot = previousState.resolvedPlacementsBySlot;
    for (final base in previousState.basePlacements) {
      final resolved = resolvedBySlot[base.slotKey];
      if (intersectsBounds(base.opaqueWorldBoundsPx) ||
          (resolved != null &&
              intersectsBounds(resolved.opaqueWorldBoundsPx))) {
        _forcedSourceCells.add(base.anchorCell);
      }
    }
  }

  final BorderLocalResolutionState previousState;
  final List<BorderPixelRect> _affectedBoundsPx;
  final Set<GridPos> _recomputedSourceCells = <GridPos>{};
  final Set<GridPos> _forcedSourceCells = <GridPos>{};

  List<BorderPixelRect> get affectedBoundsPx => _affectedBoundsPx;

  BorderMaterialization get previousMaterialization =>
      previousState.materialization;

  List<BorderResolvedGroundCell> get previousBaseGround =>
      previousState.baseGround;

  List<BorderResolvedPlacement> get previousBasePlacements =>
      previousState.basePlacements;

  Map<String, BorderResolvedPlacement> get previousResolvedPlacementsBySlot =>
      previousState.resolvedPlacementsBySlot;

  Set<String> get previousSuppressedPlacementSlotKeys =>
      previousState.suppressedPlacementSlotKeys;

  List<GridPos> get recomputedSourceCells {
    final values = _recomputedSourceCells.toList(growable: false)
      ..sort((first, second) {
        final row = first.y.compareTo(second.y);
        return row != 0 ? row : first.x.compareTo(second.x);
      });
    return List<GridPos>.unmodifiable(values);
  }

  bool intersectsBounds(BorderPixelRect bounds) =>
      _affectedBoundsPx.any((dirty) => _rectanglesIntersect(dirty, bounds));

  bool recomputesCell(GridPos cell, GridSize tileSizePx) =>
      _forcedSourceCells.contains(cell) ||
      intersectsBounds(_cellBounds(cell, tileSizePx));

  bool retainsBasePlacement(
    BorderResolvedPlacement placement,
    GridSize tileSizePx,
  ) {
    final resolved = previousResolvedPlacementsBySlot[placement.slotKey];
    return !intersectsBounds(placement.opaqueWorldBoundsPx) &&
        (resolved == null || !intersectsBounds(resolved.opaqueWorldBoundsPx)) &&
        !recomputesCell(placement.anchorCell, tileSizePx);
  }

  bool retainsGround(
    BorderResolvedGroundCell cell,
    GridSize tileSizePx,
  ) =>
      !intersectsBounds(
        _cellBounds(GridPos(x: cell.x, y: cell.y), tileSizePx),
      );

  void recordRecomputedCell(GridPos cell) {
    _recomputedSourceCells.add(GridPos(x: cell.x, y: cell.y));
  }
}

BorderPixelRect _cellBounds(GridPos cell, GridSize tileSizePx) =>
    BorderPixelRect(
      x: (BigInt.from(cell.x) * BigInt.from(tileSizePx.width)).toInt(),
      y: (BigInt.from(cell.y) * BigInt.from(tileSizePx.height)).toInt(),
      width: tileSizePx.width,
      height: tileSizePx.height,
    );

bool _rectanglesIntersect(BorderPixelRect first, BorderPixelRect second) =>
    first.x < second.right &&
    first.right > second.x &&
    first.y < second.bottom &&
    first.bottom > second.y;
```

### `packages/map_core/lib/src/operations/border_locality.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/border_feature.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_fingerprints.dart';
import 'border_local_resolution_scope.dart';
import 'masonry_line_border_resolver.dart';
import 'organic_edge_border_resolver.dart';
import 'post_and_rail_line_border_resolver.dart';
import 'border_sprite_geometry.dart';

/// One authoring edit expressed as the pixel domains it can influence.
final class BorderLocalEdit {
  BorderLocalEdit._(List<BorderPixelRect> sourceBoundsPx)
      : _sourceBoundsPx = List<BorderPixelRect>.unmodifiable(sourceBoundsPx);

  /// Describes a manual placement move, including its complete swept domain.
  factory BorderLocalEdit.forManualMove({
    required BorderPixelRect oldOpaqueBoundsPx,
    required BorderPixelRect newOpaqueBoundsPx,
  }) =>
      BorderLocalEdit._(<BorderPixelRect>[
        oldOpaqueBoundsPx,
        newOpaqueBoundsPx,
        _boundingEnvelope(oldOpaqueBoundsPx, newOpaqueBoundsPx),
      ]);

  /// Describes region paint/erase or stroke cells changed by one gesture.
  factory BorderLocalEdit.forCells({
    required Iterable<GridPos> cells,
    required GridSize tileSizePx,
  }) {
    if (tileSizePx.width <= 0 || tileSizePx.height <= 0) {
      throw const ValidationException(
        'Border local edit tile dimensions must be > 0',
      );
    }
    final canonicalCells = cells.toSet().toList(growable: false)
      ..sort((first, second) {
        final row = first.y.compareTo(second.y);
        return row != 0 ? row : first.x.compareTo(second.x);
      });
    if (canonicalCells.isEmpty) {
      throw const ValidationException(
        'Border local edit requires at least one changed cell',
      );
    }
    return BorderLocalEdit._(<BorderPixelRect>[
      for (final cell in canonicalCells)
        BorderPixelRect(
          x: (BigInt.from(cell.x) * BigInt.from(tileSizePx.width)).toInt(),
          y: (BigInt.from(cell.y) * BigInt.from(tileSizePx.height)).toInt(),
          width: tileSizePx.width,
          height: tileSizePx.height,
        ),
    ]);
  }

  final List<BorderPixelRect> _sourceBoundsPx;

  List<BorderPixelRect> get sourceBoundsPx => _sourceBoundsPx;
}

/// Conservative pixel region containing every subproblem affected by edits.
final class BorderDirtyHalo {
  BorderDirtyHalo._({
    required this.radiusPx,
    required List<BorderPixelRect> affectedBoundsPx,
  }) : _affectedBoundsPx = List<BorderPixelRect>.unmodifiable(affectedBoundsPx);

  final int radiusPx;
  final List<BorderPixelRect> _affectedBoundsPx;

  List<BorderPixelRect> get affectedBoundsPx => _affectedBoundsPx;

  bool intersects(BorderPixelRect bounds) =>
      _affectedBoundsPx.any((dirty) => _rectanglesIntersect(dirty, bounds));
}

/// Canonical resolution rebuilt with identity-preserved distant output.
final class BorderLocalResolutionResult {
  BorderLocalResolutionResult._({
    required this.dirtyHalo,
    required this.result,
    required this.nextState,
    required List<String> reusedDistantPlacementSlotKeys,
    required List<(int, int)> reusedDistantGroundCoordinates,
    required List<GridPos> recomputedSourceCells,
  })  : _reusedDistantPlacementSlotKeys =
            List<String>.unmodifiable(reusedDistantPlacementSlotKeys),
        _reusedDistantGroundCoordinates =
            List<(int, int)>.unmodifiable(reusedDistantGroundCoordinates),
        _recomputedSourceCells =
            List<GridPos>.unmodifiable(recomputedSourceCells);

  final BorderDirtyHalo dirtyHalo;
  final BorderResolutionResult result;
  final BorderLocalResolutionState? nextState;
  final List<String> _reusedDistantPlacementSlotKeys;
  final List<(int, int)> _reusedDistantGroundCoordinates;
  final List<GridPos> _recomputedSourceCells;

  List<String> get reusedDistantPlacementSlotKeys =>
      _reusedDistantPlacementSlotKeys;

  List<(int, int)> get reusedDistantGroundCoordinates =>
      _reusedDistantGroundCoordinates;

  /// Source cells whose placement or ground generation branch was entered.
  List<GridPos> get recomputedSourceCells => _recomputedSourceCells;
}

/// Computes the approved V1 dirty-halo radius from one complete request.
///
/// Border locality is pixel-only. For non-square tiles, the larger axis is
/// used conservatively for both the depth and jitter terms.
int computeBorderDirtyHaloRadiusForRequestPx(
  BorderResolutionRequest request,
) {
  final revision = request.blueprintRevision;
  if (revision == null) {
    throw const ValidationException(
      'Border locality requires a published blueprint revision',
    );
  }
  final parameters =
      request.feature.paramsOverride ?? revision.definition.defaults;
  final tileSizePx = request.tileSizePx.width > request.tileSizePx.height
      ? request.tileSizePx.width
      : request.tileSizePx.height;
  final placementRadius = computeBorderDirtyHaloRadiusPx(
    depthRows: parameters.depthRows,
    tileSizePx: tileSizePx,
    largestTransformedOpaqueExtentPx: maximumBorderTransformedOpaqueExtentPx(
      revision.definition.primitives.map(
        (primitive) => primitive.publishedMetrics,
      ),
    ),
    jitterMaxPx: computeBorderJitterMaxPx(
      irregularityPermille: parameters.irregularityPermille,
      tileSizePx: tileSizePx,
    ),
    maxOverlapPx: parameters.maxOverlapPx,
    gapTolerancePx: parameters.gapTolerancePx,
  );
  final groundRadius = revision.definition.ground == null
      ? 0
      : revision.definition.ground!.edgeBandCells * tileSizePx;
  return placementRadius > groundRadius ? placementRadius : groundRadius;
}

/// Expands every edit source by the approved request-local pixel radius.
BorderDirtyHalo computeBorderDirtyHalo({
  required BorderResolutionRequest request,
  required Iterable<BorderLocalEdit> edits,
}) {
  final editList = edits.toList(growable: false);
  if (editList.isEmpty) {
    throw const ValidationException(
      'Border dirty halo requires at least one local edit',
    );
  }
  final radiusPx = computeBorderDirtyHaloRadiusForRequestPx(request);
  return BorderDirtyHalo._(
    radiusPx: radiusPx,
    affectedBoundsPx: <BorderPixelRect>[
      for (final edit in editList)
        for (final bounds in edit.sourceBoundsPx) _expand(bounds, radiusPx),
    ],
  );
}

/// Produces the canonical pre/post-override baseline required by local edits.
///
/// This is the explicit full-resolution entrypoint. Later calls to
/// [resolveBorderFeatureLocally] never invoke a complete template solver.
BorderLocalResolutionState resolveBorderFeatureLocalBaseline(
  BorderResolutionRequest request,
) {
  final revision = request.blueprintRevision;
  if (revision == null) {
    throw const ValidationException(
      'Border local baseline requires a published blueprint revision',
    );
  }
  final capture = BorderLocalResolutionCapture();
  final result = switch (revision.definition.template) {
    BorderBlueprintTemplate.organicEdge => resolveOrganicEdgeBorderWithEvidence(
        request,
        localCapture: capture,
      ).result,
    BorderBlueprintTemplate.masonryLine => resolveMasonryLineBorderWithEvidence(
        request,
        localCapture: capture,
      ).result,
    BorderBlueprintTemplate.postAndRailLine =>
      resolvePostAndRailLineBorderWithEvidence(
        request,
        localCapture: capture,
      ).result,
  };
  return capture.finish(request: request, result: result);
}

/// Regenerates only subproblems intersecting the conservative dirty halo.
///
/// Validation, coverage reductions, sorting, and fingerprints still consume
/// the merged global trace; no distant placement or ground generation branch
/// is entered.
BorderLocalResolutionResult resolveBorderFeatureLocally({
  required BorderResolutionRequest request,
  required BorderLocalResolutionState previousState,
  required Iterable<BorderLocalEdit> edits,
}) {
  _validateLocalBaselineCompatibility(request, previousState);
  final dirtyHalo = computeBorderDirtyHalo(request: request, edits: edits);
  final changedOverrideSlotKeys = _validateChangedOverrideInputs(
    request: request,
    previousState: previousState,
    dirtyHalo: dirtyHalo,
  );
  final revision = request.blueprintRevision!;
  final capture = BorderLocalResolutionCapture();
  final scope = BorderLocalResolutionScope(
    previousState: previousState,
    affectedBoundsPx: dirtyHalo.affectedBoundsPx,
  );
  final result = switch (revision.definition.template) {
    BorderBlueprintTemplate.organicEdge => resolveOrganicEdgeBorderWithEvidence(
        request,
        localScope: scope,
        localCapture: capture,
      ).result,
    BorderBlueprintTemplate.masonryLine => resolveMasonryLineBorderWithEvidence(
        request,
        localScope: scope,
        localCapture: capture,
      ).result,
    BorderBlueprintTemplate.postAndRailLine =>
      resolvePostAndRailLineBorderWithEvidence(
        request,
        localScope: scope,
        localCapture: capture,
      ).result,
  };
  final materialization = result.materialization;
  if (materialization == null) {
    return BorderLocalResolutionResult._(
      dirtyHalo: dirtyHalo,
      result: result,
      nextState: null,
      reusedDistantPlacementSlotKeys: const <String>[],
      reusedDistantGroundCoordinates: const <(int, int)>[],
      recomputedSourceCells: scope.recomputedSourceCells,
    );
  }
  _validateChangedOverrideOutputs(
    changedSlotKeys: changedOverrideSlotKeys,
    materialization: materialization,
    dirtyHalo: dirtyHalo,
  );
  final nextState = capture.finish(request: request, result: result);
  final previousMaterialization = previousState.materialization;
  final previousPlacements = <String, BorderResolvedPlacement>{
    for (final placement in previousMaterialization.placements)
      placement.slotKey: placement,
  };
  final previousGround = <(int, int), BorderResolvedGroundCell>{
    for (final cell in previousMaterialization.ground) (cell.x, cell.y): cell,
  };
  return BorderLocalResolutionResult._(
    dirtyHalo: dirtyHalo,
    result: result,
    nextState: nextState,
    reusedDistantPlacementSlotKeys: <String>[
      for (final placement in materialization.placements)
        if (identical(previousPlacements[placement.slotKey], placement))
          placement.slotKey,
    ],
    reusedDistantGroundCoordinates: <(int, int)>[
      for (final cell in materialization.ground)
        if (identical(previousGround[(cell.x, cell.y)], cell)) (cell.x, cell.y),
    ],
    recomputedSourceCells: scope.recomputedSourceCells,
  );
}

void _validateLocalBaselineCompatibility(
  BorderResolutionRequest request,
  BorderLocalResolutionState previousState,
) {
  final revision = request.blueprintRevision;
  if (revision == null) {
    throw const ValidationException(
      'Border local regeneration requires a published blueprint revision',
    );
  }
  final previousRequest = previousState.request;
  final previousReceipt = previousState.materialization.receipt;
  final current = computeBorderInputFingerprints(request);
  final compatible =
      request.resolverVersion == previousReceipt.resolverVersion &&
          revision.revision == previousReceipt.blueprintRevision &&
          request.blueprintId == previousRequest.blueprintId &&
          request.feature.id == previousRequest.feature.id &&
          request.feature.seed == previousRequest.feature.seed &&
          current.blueprint == previousReceipt.components.blueprint &&
          current.parameters == previousReceipt.components.parameters &&
          current.mapContext == previousReceipt.components.mapContext &&
          current.visualSnapshots == previousReceipt.components.visualSnapshots;
  if (!compatible) {
    throw const ValidationException(
      'Border local regeneration only accepts geometry, override, or '
      'keep-out edits from its canonical baseline',
    );
  }
}

Set<String> _validateChangedOverrideInputs({
  required BorderResolutionRequest request,
  required BorderLocalResolutionState previousState,
  required BorderDirtyHalo dirtyHalo,
}) {
  final previous = <String, BorderSlotOverride>{
    for (final override in previousState.request.feature.overrides)
      override.slotKey: override,
  };
  final current = <String, BorderSlotOverride>{
    for (final override in request.feature.overrides)
      override.slotKey: override,
  };
  final changed = <String>{
    for (final slotKey in <String>{...previous.keys, ...current.keys})
      if (previous[slotKey] != current[slotKey]) slotKey,
  };
  if (changed.isEmpty) return changed;

  final baseBySlot = <String, BorderResolvedPlacement>{
    for (final placement in previousState.basePlacements)
      placement.slotKey: placement,
  };
  final resolvedBySlot = previousState.resolvedPlacementsBySlot;
  for (final slotKey in changed) {
    final base = baseBySlot[slotKey];
    final resolved = resolvedBySlot[slotKey];
    if ((base == null || !dirtyHalo.intersects(base.opaqueWorldBoundsPx)) &&
        (resolved == null ||
            !dirtyHalo.intersects(resolved.opaqueWorldBoundsPx))) {
      throw ValidationException(
        'Changed Border override $slotKey lies outside the declared local '
        'edit halo',
      );
    }
  }
  return changed;
}

void _validateChangedOverrideOutputs({
  required Set<String> changedSlotKeys,
  required BorderMaterialization materialization,
  required BorderDirtyHalo dirtyHalo,
}) {
  if (changedSlotKeys.isEmpty) return;
  for (final placement in materialization.placements) {
    if (changedSlotKeys.contains(placement.slotKey) &&
        !dirtyHalo.intersects(placement.opaqueWorldBoundsPx)) {
      throw ValidationException(
        'Changed Border override ${placement.slotKey} resolved outside the '
        'declared local edit halo',
      );
    }
  }
}

BorderPixelRect _boundingEnvelope(
  BorderPixelRect first,
  BorderPixelRect second,
) {
  final left = first.x < second.x ? first.x : second.x;
  final top = first.y < second.y ? first.y : second.y;
  final right = first.right > second.right ? first.right : second.right;
  final bottom = first.bottom > second.bottom ? first.bottom : second.bottom;
  return BorderPixelRect(
    x: left,
    y: top,
    width: right - left,
    height: bottom - top,
  );
}

BorderPixelRect _expand(BorderPixelRect bounds, int radiusPx) {
  final radius = BigInt.from(radiusPx);
  final left = BigInt.from(bounds.x) - radius;
  final top = BigInt.from(bounds.y) - radius;
  final width = BigInt.from(bounds.width) + radius * BigInt.two;
  final height = BigInt.from(bounds.height) + radius * BigInt.two;
  return BorderPixelRect(
    x: left.toInt(),
    y: top.toInt(),
    width: width.toInt(),
    height: height.toInt(),
  );
}

bool _rectanglesIntersect(BorderPixelRect first, BorderPixelRect second) =>
    first.x < second.right &&
    first.right > second.x &&
    first.y < second.bottom &&
    first.bottom > second.y;
```

### `packages/map_core/lib/src/operations/border_override_resolution.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_feature.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_signed_int64.dart';
import '../models/border_value_objects.dart';
import '../models/geometry.dart';
import 'border_deterministic_rng.dart';
import 'border_rle_codec.dart';
import 'border_sprite_geometry.dart';

/// Final shared V1 pass for stable-slot overrides and keep-out masks.
@immutable
final class BorderOverrideResolution {
  BorderOverrideResolution._({
    required List<BorderResolvedGroundCell> ground,
    required List<BorderResolvedPlacement> placements,
    required this.diagnosticReport,
    required Set<String> orphanedSlotKeys,
    required Set<String> intentionalGapSlotKeys,
  })  : _ground = List<BorderResolvedGroundCell>.unmodifiable(ground),
        _placements = List<BorderResolvedPlacement>.unmodifiable(placements),
        _orphanedSlotKeys = _sortedUnmodifiableSet(orphanedSlotKeys),
        _intentionalGapSlotKeys =
            _sortedUnmodifiableSet(intentionalGapSlotKeys);

  final List<BorderResolvedGroundCell> _ground;
  final List<BorderResolvedPlacement> _placements;
  final Set<String> _orphanedSlotKeys;
  final Set<String> _intentionalGapSlotKeys;

  List<BorderResolvedGroundCell> get ground => _ground;

  List<BorderResolvedPlacement> get placements => _placements;

  final BorderDiagnosticsReport diagnosticReport;

  List<BorderDiagnostic> get diagnostics => diagnosticReport.diagnostics;

  Set<String> get orphanedSlotKeys => _orphanedSlotKeys;

  /// Slots deliberately removed by a suppression or keep-out.
  Set<String> get intentionalGapSlotKeys => _intentionalGapSlotKeys;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderOverrideResolution &&
          _listsEqual(_ground, other._ground) &&
          _listsEqual(_placements, other._placements) &&
          diagnosticReport == other.diagnosticReport &&
          _setsEqual(_orphanedSlotKeys, other._orphanedSlotKeys) &&
          _setsEqual(
            _intentionalGapSlotKeys,
            other._intentionalGapSlotKeys,
          );

  @override
  int get hashCode => Object.hash(
        Object.hashAll(_ground),
        Object.hashAll(_placements),
        diagnosticReport,
        Object.hashAllUnordered(_orphanedSlotKeys),
        Object.hashAllUnordered(_intentionalGapSlotKeys),
      );
}

/// Applies persisted overrides to already-generated slots, then masks output.
///
/// Base generation remains independent from overrides. This keeps slot
/// allocation and every placement outside the locally edited slots stable.
BorderOverrideResolution resolveBorderOverrides({
  required BorderResolutionRequest request,
  required Iterable<BorderResolvedGroundCell> baseGround,
  required Iterable<BorderResolvedPlacement> basePlacements,
  Set<String> alreadyResolvedSlotKeys = const <String>{},
  Map<String, BorderResolvedPlacement> previouslyResolvedPlacementsBySlot =
      const <String, BorderResolvedPlacement>{},
  Set<String> previouslySuppressedSlotKeys = const <String>{},
}) {
  final ground = baseGround.toList(growable: false);
  final placements = basePlacements.toList(growable: false);
  final diagnostics = <BorderDiagnostic>[];
  final orphaned = <String>{};
  final intentionalGaps = <String>{};
  final revision = request.blueprintRevision;
  if (revision == null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.blueprint_unavailable',
        scope: BorderDiagnosticScope.blueprint,
        action: 'border.action.publish_blueprint',
      ),
    );
    return BorderOverrideResolution._(
      ground: ground,
      placements: placements,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
      orphanedSlotKeys: orphaned,
      intentionalGapSlotKeys: intentionalGaps,
    );
  }
  if (request.feature.overrides.isEmpty &&
      request.feature.keepOutRegions.isEmpty) {
    return BorderOverrideResolution._(
      ground: ground,
      placements: placements,
      diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
      orphanedSlotKeys: orphaned,
      intentionalGapSlotKeys: intentionalGaps,
    );
  }

  final keepOutMask = _buildKeepOutMask(request, diagnostics);
  final hasKeepOutCells = keepOutMask.contains(true);

  final primitives = <String, BorderPublishedPrimitive>{
    for (final primitive in revision.definition.primitives)
      primitive.id: primitive,
  };
  final overridesBySlot = <String, BorderSlotOverride>{
    for (final override in request.feature.overrides)
      override.slotKey: override,
  };
  final baseSlots = <String>{
    for (final placement in placements) placement.slotKey,
  };
  for (final override in request.feature.overrides) {
    if (baseSlots.contains(override.slotKey)) {
      continue;
    }
    _validateOrphanOverrideReferences(
      request: request,
      override: override,
      primitives: primitives,
      diagnostics: diagnostics,
    );
    orphaned.add(override.slotKey);
    diagnostics.add(
      _warning(
        request,
        code: 'border.resolution.override_orphaned',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        action: 'border.action.remove_or_retarget_override',
      ),
    );
  }

  final resolvedPlacements = <BorderResolvedPlacement>[];
  for (final base in placements) {
    if (alreadyResolvedSlotKeys.contains(base.slotKey)) {
      if (previouslySuppressedSlotKeys.contains(base.slotKey)) {
        intentionalGaps.add(base.slotKey);
        continue;
      }
      final previous = previouslyResolvedPlacementsBySlot[base.slotKey];
      if (previous == null) {
        throw StateError(
          'Missing prior resolved Border placement for ${base.slotKey}',
        );
      }
      resolvedPlacements.add(previous);
      continue;
    }
    final override = overridesBySlot[base.slotKey];
    if (override?.suppressed ?? false) {
      intentionalGaps.add(base.slotKey);
      continue;
    }
    final resolved = override == null
        ? base
        : _resolvePlacementOverride(
            request: request,
            base: base,
            override: override,
            primitives: primitives,
            diagnostics: diagnostics,
          );
    final primitive = primitives[resolved.primitiveId];
    if (hasKeepOutCells &&
        primitive != null &&
        _placementIntersectsKeepOut(
          placement: resolved,
          primitive: primitive,
          keepOutMask: keepOutMask,
          mapSize: request.mapSize,
          tileSizePx: request.tileSizePx,
        )) {
      intentionalGaps.add(base.slotKey);
      continue;
    }
    resolvedPlacements.add(resolved);
  }
  resolvedPlacements.sort(
    (left, right) => left.stableOrderKey.compareTo(right.stableOrderKey),
  );

  final resolvedGround = <BorderResolvedGroundCell>[
    for (final cell in ground)
      if (!hasKeepOutCells ||
          !_cellIsKeptOut(
            x: cell.x,
            y: cell.y,
            keepOutMask: keepOutMask,
            mapWidth: request.mapSize.width,
            mapHeight: request.mapSize.height,
          ))
        cell,
  ];

  return BorderOverrideResolution._(
    ground: resolvedGround,
    placements: resolvedPlacements,
    diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
    orphanedSlotKeys: orphaned,
    intentionalGapSlotKeys: intentionalGaps,
  );
}

BorderResolvedPlacement _resolvePlacementOverride({
  required BorderResolutionRequest request,
  required BorderResolvedPlacement base,
  required BorderSlotOverride override,
  required Map<String, BorderPublishedPrimitive> primitives,
  required List<BorderDiagnostic> diagnostics,
}) {
  final basePrimitive = primitives[base.primitiveId];
  if (basePrimitive == null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_base_primitive_missing',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{'primitiveId': base.primitiveId},
        action: 'border.action.republish_blueprint',
      ),
    );
    return base;
  }

  final locked = override.lockedPlacement;
  if (locked != null) {
    return _validateLockedPlacement(
      request: request,
      base: base,
      locked: locked,
      primitives: primitives,
      diagnostics: diagnostics,
    )
        ? locked
        : base;
  }

  var primitive = basePrimitive;
  final transform = override.transformOverride ?? base.transform;
  final replacementId = override.replacementPrimitiveId;
  if (replacementId != null) {
    final replacement = primitives[replacementId];
    if (replacement == null) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_primitive_missing',
          scope: BorderDiagnosticScope.slot,
          slotKey: override.slotKey,
          parameters: <String, Object?>{'primitiveId': replacementId},
          action: 'border.action.remove_or_retarget_override',
        ),
      );
      return base;
    }
    if (replacement.role != basePrimitive.role) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_primitive_role_mismatch',
          scope: BorderDiagnosticScope.slot,
          slotKey: override.slotKey,
          parameters: <String, Object?>{'primitiveId': replacementId},
          action: 'border.action.choose_compatible_primitive',
        ),
      );
      return base;
    }
    primitive = replacement;
  } else if (override.variationSalt != BorderSignedInt64.zero) {
    final candidates = primitives.values.where(
      (candidate) =>
          candidate.role == basePrimitive.role &&
          _transformAllowed(candidate, transform),
    );
    final selected = chooseBorderWeightedCandidate(
      BorderDeterministicRng.fromComponents(<BorderRngKeyComponent>[
        BorderRngKeyComponent.text(request.feature.id),
        BorderRngKeyComponent.text(base.slotKey),
        BorderRngKeyComponent.signedInt64(request.feature.seed),
        BorderRngKeyComponent.signedInt64(override.variationSalt),
        const BorderRngKeyComponent.text('override-local-variation'),
      ]),
      <BorderWeightedCandidate<BorderPublishedPrimitive>>[
        for (final candidate in candidates)
          BorderWeightedCandidate<BorderPublishedPrimitive>(
            id: candidate.id,
            value: candidate,
            weight: candidate.weight,
          ),
      ],
    );
    if (selected != null) {
      primitive = selected.value;
    }
  }

  if (!_transformAllowed(primitive, transform)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_transform_not_allowed',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{
          'primitiveId': primitive.id,
          'quarterTurns': transform.quarterTurns,
          'flipX': transform.flipX,
        },
        action: 'border.action.choose_allowed_transform',
      ),
    );
    return base;
  }
  if (!_snapshotValidForPrimitive(request, primitive)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_snapshot_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{
          'snapshotId': primitive.visualSnapshotId,
        },
        action: 'border.action.restore_or_republish_snapshot',
      ),
    );
    return base;
  }

  final offset = override.offsetDeltaPx ?? const BorderPixelOffset(x: 0, y: 0);
  if (!_offsetInsideCorridor(request, offset.x, offset.y)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_outside_corridor',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{'offsetX': offset.x, 'offsetY': offset.y},
        action: 'border.action.move_override_inside_corridor',
      ),
    );
    return base;
  }

  try {
    final baseOrigin = resolveBorderSpriteGeometry(
      metrics: basePrimitive.publishedMetrics,
      sourceAnchorPx: basePrimitive.anchorPx,
      transform: base.transform,
      targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
    );
    final target = BorderPixelPos(
      x: base.topLeftWorldPx.x - baseOrigin.topLeftWorldPx.x + offset.x,
      y: base.topLeftWorldPx.y - baseOrigin.topLeftWorldPx.y + offset.y,
    );
    final sprite = resolveBorderSpriteGeometry(
      metrics: primitive.publishedMetrics,
      sourceAnchorPx: primitive.anchorPx,
      transform: transform,
      targetAnchorWorldPx: target,
    );
    if (!_intersectsCanvas(request, sprite.opaqueWorldBoundsPx)) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_outside_canvas',
          scope: BorderDiagnosticScope.slot,
          slotKey: override.slotKey,
          action: 'border.action.move_override_inside_canvas',
        ),
      );
      return base;
    }
    return BorderResolvedPlacement(
      id: base.id,
      slotKey: base.slotKey,
      primitiveId: primitive.id,
      visualSnapshotId: primitive.visualSnapshotId,
      anchorCell: base.anchorCell,
      topLeftWorldPx: sprite.topLeftWorldPx,
      opaqueWorldBoundsPx: sprite.opaqueWorldBoundsPx,
      transform: transform,
      drawBand: base.drawBand,
      stableOrderKey: base.stableOrderKey,
    );
  } on ValidationException {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_geometry_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        action: 'border.action.reset_override_geometry',
      ),
    );
    return base;
  }
}

bool _validateLockedPlacement({
  required BorderResolutionRequest request,
  required BorderResolvedPlacement base,
  required BorderResolvedPlacement locked,
  required Map<String, BorderPublishedPrimitive> primitives,
  required List<BorderDiagnostic> diagnostics,
}) {
  final basePrimitive = primitives[base.primitiveId];
  if (basePrimitive == null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_base_primitive_missing',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        parameters: <String, Object?>{'primitiveId': base.primitiveId},
        action: 'border.action.republish_blueprint',
      ),
    );
    return false;
  }
  final primitive = primitives[locked.primitiveId];
  if (primitive == null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_primitive_missing',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        parameters: <String, Object?>{'primitiveId': locked.primitiveId},
        action: 'border.action.remove_or_retarget_override',
      ),
    );
    return false;
  }
  if (primitive.role != basePrimitive.role) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_primitive_role_mismatch',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.choose_compatible_primitive',
      ),
    );
    return false;
  }
  if (locked.id != base.id ||
      locked.anchorCell != base.anchorCell ||
      locked.drawBand != base.drawBand ||
      locked.stableOrderKey != base.stableOrderKey) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_anchor_or_order_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        action: 'border.action.relock_current_slot',
      ),
    );
    return false;
  }
  if (locked.visualSnapshotId != primitive.visualSnapshotId ||
      !_snapshotValidForPrimitive(request, primitive)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_snapshot_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        parameters: <String, Object?>{
          'snapshotId': locked.visualSnapshotId,
        },
        action: 'border.action.restore_or_remove_locked_override',
      ),
    );
    return false;
  }
  if (!_transformAllowed(primitive, locked.transform)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_transform_not_allowed',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        action: 'border.action.choose_allowed_transform',
      ),
    );
    return false;
  }
  try {
    final baseTarget = _targetAnchorWorldPx(
      placement: base,
      primitive: basePrimitive,
    );
    final lockedTarget = _targetAnchorWorldPx(
      placement: locked,
      primitive: primitive,
    );
    final expected = resolveBorderSpriteGeometry(
      metrics: primitive.publishedMetrics,
      sourceAnchorPx: primitive.anchorPx,
      transform: locked.transform,
      targetAnchorWorldPx: lockedTarget,
    );
    if (expected.opaqueWorldBoundsPx != locked.opaqueWorldBoundsPx) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_geometry_invalid',
          scope: BorderDiagnosticScope.slot,
          slotKey: locked.slotKey,
          action: 'border.action.relock_current_slot',
        ),
      );
      return false;
    }
    final deltaX = lockedTarget.x - baseTarget.x;
    final deltaY = lockedTarget.y - baseTarget.y;
    if (!_offsetInsideCorridor(request, deltaX, deltaY)) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_outside_corridor',
          scope: BorderDiagnosticScope.slot,
          slotKey: locked.slotKey,
          action: 'border.action.move_override_inside_corridor',
        ),
      );
      return false;
    }
    if (!_intersectsCanvas(request, locked.opaqueWorldBoundsPx)) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.override_outside_canvas',
          scope: BorderDiagnosticScope.slot,
          slotKey: locked.slotKey,
          action: 'border.action.move_override_inside_canvas',
        ),
      );
      return false;
    }
  } on ValidationException {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_geometry_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: locked.slotKey,
        action: 'border.action.relock_current_slot',
      ),
    );
    return false;
  }
  return true;
}

void _validateOrphanOverrideReferences({
  required BorderResolutionRequest request,
  required BorderSlotOverride override,
  required Map<String, BorderPublishedPrimitive> primitives,
  required List<BorderDiagnostic> diagnostics,
}) {
  if (override.suppressed) {
    return;
  }
  final locked = override.lockedPlacement;
  final primitiveId = locked?.primitiveId ?? override.replacementPrimitiveId;
  if (primitiveId == null) {
    return;
  }
  final primitive = primitives[primitiveId];
  if (primitive == null) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_primitive_missing',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{'primitiveId': primitiveId},
        action: 'border.action.remove_or_retarget_override',
      ),
    );
    return;
  }
  if (!_snapshotValidForPrimitive(request, primitive) ||
      (locked != null &&
          locked.visualSnapshotId != primitive.visualSnapshotId)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_snapshot_invalid',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{
          'snapshotId': locked?.visualSnapshotId ?? primitive.visualSnapshotId,
        },
        action: 'border.action.restore_or_remove_locked_override',
      ),
    );
    return;
  }
  final transform = locked?.transform ?? override.transformOverride;
  if (transform != null && !_transformAllowed(primitive, transform)) {
    diagnostics.add(
      _error(
        request,
        code: 'border.resolution.override_transform_not_allowed',
        scope: BorderDiagnosticScope.slot,
        slotKey: override.slotKey,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.choose_allowed_transform',
      ),
    );
  }
}

BorderPixelPos _targetAnchorWorldPx({
  required BorderResolvedPlacement placement,
  required BorderPublishedPrimitive primitive,
}) {
  final origin = resolveBorderSpriteGeometry(
    metrics: primitive.publishedMetrics,
    sourceAnchorPx: primitive.anchorPx,
    transform: placement.transform,
    targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
  );
  return BorderPixelPos(
    x: placement.topLeftWorldPx.x - origin.topLeftWorldPx.x,
    y: placement.topLeftWorldPx.y - origin.topLeftWorldPx.y,
  );
}

List<bool> _buildKeepOutMask(
  BorderResolutionRequest request,
  List<BorderDiagnostic> diagnostics,
) {
  final mask = List<bool>.filled(
    request.mapSize.width * request.mapSize.height,
    false,
    growable: false,
  );
  for (final keepOut in request.feature.keepOutRegions) {
    if (keepOut.region.width != request.mapSize.width ||
        keepOut.region.height != request.mapSize.height) {
      diagnostics.add(
        _error(
          request,
          code: 'border.resolution.keep_out_size_mismatch',
          scope: BorderDiagnosticScope.geometry,
          parameters: <String, Object?>{'keepOutId': keepOut.id},
          action: 'border.action.resize_keep_out_to_map',
        ),
      );
      continue;
    }
    for (var index = 0; index < mask.length; index += 1) {
      mask[index] = mask[index] || keepOut.region.cells[index];
    }
  }
  return mask;
}

bool _placementIntersectsKeepOut({
  required BorderResolvedPlacement placement,
  required BorderPublishedPrimitive primitive,
  required List<bool> keepOutMask,
  required GridSize mapSize,
  required GridSize tileSizePx,
}) {
  final metrics = primitive.publishedMetrics;
  final width = metrics.pixelSize.width;
  final height = metrics.pixelSize.height;
  var intersects = false;
  visitBorderRleTrueRuns(
    metrics.occupancyMaskRle,
    expectedLength: checkedBorderRleCellCount(
      width: width,
      height: height,
      path: r'$.publishedMetrics.pixelSize',
    ),
    path: r'$.publishedMetrics.occupancyMaskRle',
    visitor: (start, end) {
      for (var index = start; index < end && !intersects; index += 1) {
        final transformed = _transformSourcePixel(
          x: index % width,
          y: index ~/ width,
          width: width,
          height: height,
          transform: placement.transform,
        );
        final worldX = placement.topLeftWorldPx.x + transformed.$1;
        final worldY = placement.topLeftWorldPx.y + transformed.$2;
        if (worldX < 0 || worldY < 0) {
          continue;
        }
        final cellX = worldX ~/ tileSizePx.width;
        final cellY = worldY ~/ tileSizePx.height;
        if (cellX >= mapSize.width || cellY >= mapSize.height) {
          continue;
        }
        intersects = keepOutMask[cellY * mapSize.width + cellX];
      }
    },
  );
  return intersects;
}

(int, int) _transformSourcePixel({
  required int x,
  required int y,
  required int width,
  required int height,
  required BorderSpriteTransform transform,
}) {
  final flippedX = transform.flipX ? width - 1 - x : x;
  return switch (transform.quarterTurns) {
    0 => (flippedX, y),
    1 => (height - 1 - y, flippedX),
    2 => (width - 1 - flippedX, height - 1 - y),
    3 => (y, width - 1 - flippedX),
    _ => throw const ValidationException(
        'Border quarterTurns must be between 0 and 3',
      ),
  };
}

bool _offsetInsideCorridor(
  BorderResolutionRequest request,
  int deltaX,
  int deltaY,
) {
  final definition = request.blueprintRevision!.definition;
  final parameters = request.feature.paramsOverride ?? definition.defaults;
  final tileSize = request.tileSizePx.width > request.tileSizePx.height
      ? request.tileSizePx.width
      : request.tileSizePx.height;
  final radius = computeBorderDirtyHaloRadiusPx(
    depthRows: parameters.depthRows,
    tileSizePx: tileSize,
    largestTransformedOpaqueExtentPx: maximumBorderTransformedOpaqueExtentPx(
      definition.primitives.map((primitive) => primitive.publishedMetrics),
    ),
    jitterMaxPx: computeBorderJitterMaxPx(
      irregularityPermille: parameters.irregularityPermille,
      tileSizePx: tileSize,
    ),
    maxOverlapPx: parameters.maxOverlapPx,
    gapTolerancePx: parameters.gapTolerancePx,
  );
  final absoluteX = BigInt.from(deltaX).abs();
  final absoluteY = BigInt.from(deltaY).abs();
  final bound = BigInt.from(radius);
  return absoluteX <= bound && absoluteY <= bound;
}

bool _transformAllowed(
  BorderPublishedPrimitive primitive,
  BorderSpriteTransform transform,
) =>
    primitive.transforms.allowedQuarterTurns.contains(transform.quarterTurns) &&
    (!transform.flipX || primitive.transforms.allowFlipX);

bool _snapshotValidForPrimitive(
  BorderResolutionRequest request,
  BorderPublishedPrimitive primitive,
) {
  final snapshot = request.visualSnapshotById(primitive.visualSnapshotId);
  if (snapshot == null) {
    return false;
  }
  final size = primitive.publishedMetrics.pixelSize;
  return snapshot.frames.every(
    (frame) =>
        frame.sourceRectPx.width == size.width &&
        frame.sourceRectPx.height == size.height,
  );
}

bool _intersectsCanvas(
  BorderResolutionRequest request,
  BorderPixelRect bounds,
) =>
    borderPixelRectIntersectsCanvas(
      rect: bounds,
      canvasSizePx: GridSize(
        width: request.mapSize.width * request.tileSizePx.width,
        height: request.mapSize.height * request.tileSizePx.height,
      ),
    );

bool _cellIsKeptOut({
  required int x,
  required int y,
  required List<bool> keepOutMask,
  required int mapWidth,
  required int mapHeight,
}) =>
    x >= 0 &&
    y >= 0 &&
    x < mapWidth &&
    y < mapHeight &&
    keepOutMask[y * mapWidth + x];

BorderDiagnostic _error(
  BorderResolutionRequest request, {
  required String code,
  required BorderDiagnosticScope scope,
  String? slotKey,
  Map<String, Object?> parameters = const <String, Object?>{},
  required String action,
}) =>
    BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.error,
      phase: BorderDiagnosticPhase.resolution,
      scope: scope,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      slotKey: slotKey,
      parameters: parameters,
      suggestedAction: action,
    );

BorderDiagnostic _warning(
  BorderResolutionRequest request, {
  required String code,
  required BorderDiagnosticScope scope,
  String? slotKey,
  required String action,
}) =>
    BorderDiagnostic(
      code: code,
      severity: BorderDiagnosticSeverity.warning,
      phase: BorderDiagnosticPhase.resolution,
      scope: scope,
      blueprintId: request.blueprintId,
      featureId: request.feature.id,
      slotKey: slotKey,
      suggestedAction: action,
    );

bool _listsEqual<T>(List<T> first, List<T> second) {
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

bool _setsEqual<T>(Set<T> first, Set<T> second) =>
    first.length == second.length && first.containsAll(second);

Set<String> _sortedUnmodifiableSet(Iterable<String> values) {
  final sorted = values.toList(growable: false)..sort();
  return Set<String>.unmodifiable(sorted);
}
```

### `packages/map_core/lib/src/operations/border_relink_operations.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_layer.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/geometry.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import 'border_feature_update_operations.dart';
import 'border_resolver.dart';

/// The two persisted geometry families supported by Border V1.
enum BorderGeometryFamily { region, linear }

/// Whether a blueprint change retains geometry or needs an explicit reset.
enum BorderRelinkKind { sameFamily, requiresFamilyReset }

/// Information actually discarded by a confirmed cross-family reset.
enum BorderRelinkLoss {
  geometry,
  parameters,
  overrides,
  keepOutRegions,
  materialization,
}

/// Immutable, non-mutating proposal for changing one feature blueprint.
final class BorderFeatureRelinkPreview {
  BorderFeatureRelinkPreview._({
    required this.expectedMapId,
    required this.expectedMapSize,
    required this.layerId,
    required this.featureId,
    required this.expectedBaseFeatureFingerprint,
    required this.sourceFamily,
    required this.targetFamily,
    required this.kind,
    required List<BorderRelinkLoss> losses,
    required this.proposedFeature,
    required this.proposedRequest,
    required this.proposedResult,
  }) : losses = List<BorderRelinkLoss>.unmodifiable(losses);

  final String expectedMapId;
  final GridSize expectedMapSize;
  final String layerId;
  final String featureId;
  final String expectedBaseFeatureFingerprint;
  final BorderGeometryFamily sourceFamily;
  final BorderGeometryFamily targetFamily;
  final BorderRelinkKind kind;
  final List<BorderRelinkLoss> losses;
  final BorderFeature proposedFeature;
  final BorderResolutionRequest? proposedRequest;
  final BorderResolutionResult? proposedResult;

  bool get canApplyResolvedRelink =>
      kind == BorderRelinkKind.sameFamily &&
      proposedRequest != null &&
      proposedResult?.canApply == true;
}

/// Prepares either a canonical same-family preview or an explicit reset plan.
///
/// The source family comes from persisted geometry, so a removed source
/// blueprint leaves its materialization renderable until the user applies a
/// replacement. This operation itself never mutates [map].
BorderFeatureRelinkPreview prepareBorderFeatureRelink({
  required MapData map,
  required String layerId,
  required String featureId,
  required String targetBlueprintId,
  required BorderBlueprintRevision targetBlueprintRevision,
  required Iterable<BorderVisualSnapshot> visualSnapshots,
  required GridSize tileSizePx,
  required int resolverVersion,
}) {
  final normalizedLayerId = _stableId(layerId, 'layerId');
  final normalizedFeatureId = _stableId(featureId, 'featureId');
  final normalizedTargetId = _stableId(targetBlueprintId, 'targetBlueprintId');
  final feature =
      _feature(_borderLayer(map, normalizedLayerId), normalizedFeatureId);
  if (feature.blueprintId == normalizedTargetId) {
    throw const ValidationException(
      'A Border relink target must differ from the current blueprint',
    );
  }

  final sourceFamily = borderGeometryFamily(feature.geometry);
  final targetFamily =
      borderTemplateGeometryFamily(targetBlueprintRevision.definition.template);
  final baseFingerprint = computeBorderFeatureEditFingerprint(feature);

  if (sourceFamily != targetFamily) {
    final resetFeature = BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: normalizedTargetId,
      seed: feature.seed,
      geometry: _emptyGeometryFor(targetFamily, mapSize: map.size),
      paramsOverride: null,
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
      materialization: null,
    );
    return BorderFeatureRelinkPreview._(
      expectedMapId: map.id,
      expectedMapSize: map.size,
      layerId: normalizedLayerId,
      featureId: normalizedFeatureId,
      expectedBaseFeatureFingerprint: baseFingerprint,
      sourceFamily: sourceFamily,
      targetFamily: targetFamily,
      kind: BorderRelinkKind.requiresFamilyReset,
      losses: _actualResetLosses(feature),
      proposedFeature: resetFeature,
      proposedRequest: null,
      proposedResult: null,
    );
  }

  final targetFeature = BorderFeature(
    id: feature.id,
    name: feature.name,
    blueprintId: normalizedTargetId,
    seed: feature.seed,
    geometry: feature.geometry,
    paramsOverride: feature.paramsOverride,
    overrides: feature.overrides,
    keepOutRegions: feature.keepOutRegions,
    materialization: null,
  );
  final request = BorderResolutionRequest(
    mapSize: map.size,
    tileSizePx: tileSizePx,
    blueprintId: normalizedTargetId,
    blueprintRevision: targetBlueprintRevision,
    feature: targetFeature,
    visualSnapshots: visualSnapshots,
    resolverVersion: resolverVersion,
  );
  final result = resolveBorderFeature(request);
  return BorderFeatureRelinkPreview._(
    expectedMapId: map.id,
    expectedMapSize: map.size,
    layerId: normalizedLayerId,
    featureId: normalizedFeatureId,
    expectedBaseFeatureFingerprint: baseFingerprint,
    sourceFamily: sourceFamily,
    targetFamily: targetFamily,
    kind: BorderRelinkKind.sameFamily,
    losses: const <BorderRelinkLoss>[],
    proposedFeature: targetFeature,
    proposedRequest: request,
    proposedResult: result,
  );
}

/// Atomically applies a canonical same-family relink preview.
///
/// Expected-state conflicts are identity-preserving no-ops. Cross-family
/// previews are rejected and require [applyBorderFeatureFamilyReset].
MapData applyBorderFeatureRelinkPreview(
  MapData map, {
  required BorderFeatureRelinkPreview preview,
}) {
  if (preview.kind != BorderRelinkKind.sameFamily) {
    throw StateError(
      'A cross-family Border change requires explicit reset confirmation',
    );
  }
  final request = preview.proposedRequest;
  final result = preview.proposedResult;
  if (request == null || result == null || !result.canApply) {
    return map;
  }
  final target = _currentTargetOrNull(map, preview);
  if (target == null) {
    return map;
  }
  final feature = target.feature;
  if (!_fingerprintMatches(feature, preview.expectedBaseFeatureFingerprint)) {
    return map;
  }
  if (borderGeometryFamily(feature.geometry) != preview.sourceFamily ||
      preview.sourceFamily != preview.targetFamily ||
      request.mapSize != map.size ||
      request.feature.id != feature.id ||
      request.feature.blueprintId != preview.proposedFeature.blueprintId ||
      request.feature.seed != feature.seed ||
      request.feature.geometry != feature.geometry ||
      request.feature.paramsOverride != feature.paramsOverride ||
      !_listEquals(request.feature.overrides, feature.overrides) ||
      !_listEquals(request.feature.keepOutRegions, feature.keepOutRegions)) {
    return map;
  }
  final canonicalValidation = validateBorderResolutionResultForRequest(
    request: request,
    proposedResult: result,
  );
  if (canonicalValidation.hasErrors) {
    throw const ValidationException(
      'Border relink preview result does not match canonical resolution',
    );
  }

  return _replaceFeature(
    map,
    layerIndex: target.layerIndex,
    featureIndex: target.featureIndex,
    layer: target.layer,
    feature: BorderFeature(
      id: feature.id,
      name: feature.name,
      blueprintId: request.blueprintId,
      seed: feature.seed,
      geometry: feature.geometry,
      paramsOverride: feature.paramsOverride,
      overrides: feature.overrides,
      keepOutRegions: feature.keepOutRegions,
      materialization: result.materialization,
    ),
  );
}

/// Applies the destructive half of a cross-family blueprint change.
MapData applyBorderFeatureFamilyReset(
  MapData map, {
  required BorderFeatureRelinkPreview preview,
}) {
  if (preview.kind != BorderRelinkKind.requiresFamilyReset) {
    throw StateError('A same-family Border relink must apply its preview');
  }
  final target = _currentTargetOrNull(map, preview);
  if (target == null) {
    return map;
  }
  final feature = target.feature;
  if (!_fingerprintMatches(feature, preview.expectedBaseFeatureFingerprint) ||
      borderGeometryFamily(feature.geometry) != preview.sourceFamily ||
      preview.sourceFamily == preview.targetFamily) {
    return map;
  }
  return _replaceFeature(
    map,
    layerIndex: target.layerIndex,
    featureIndex: target.featureIndex,
    layer: target.layer,
    feature: preview.proposedFeature,
  );
}

BorderGeometryFamily borderGeometryFamily(BorderFeatureGeometry geometry) =>
    switch (geometry) {
      BorderRegionGeometry() => BorderGeometryFamily.region,
      BorderStrokeGeometry() => BorderGeometryFamily.linear,
    };

BorderGeometryFamily borderTemplateGeometryFamily(
  BorderBlueprintTemplate template,
) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge => BorderGeometryFamily.region,
      BorderBlueprintTemplate.masonryLine ||
      BorderBlueprintTemplate.postAndRailLine =>
        BorderGeometryFamily.linear,
    };

BorderFeatureGeometry _emptyGeometryFor(
  BorderGeometryFamily family, {
  required GridSize mapSize,
}) =>
    switch (family) {
      BorderGeometryFamily.region => BorderRegionGeometry(
          width: mapSize.width,
          height: mapSize.height,
          cells: List<bool>.filled(mapSize.width * mapSize.height, false),
        ),
      BorderGeometryFamily.linear =>
        BorderStrokeGeometry(strokes: const <BorderStroke>[]),
    };

List<BorderRelinkLoss> _actualResetLosses(BorderFeature feature) =>
    <BorderRelinkLoss>[
      BorderRelinkLoss.geometry,
      if (feature.paramsOverride != null) BorderRelinkLoss.parameters,
      if (feature.overrides.isNotEmpty) BorderRelinkLoss.overrides,
      if (feature.keepOutRegions.isNotEmpty) BorderRelinkLoss.keepOutRegions,
      if (feature.materialization != null) BorderRelinkLoss.materialization,
    ];

({
  int layerIndex,
  int featureIndex,
  BorderLayer layer,
  BorderFeature feature,
})? _currentTargetOrNull(
  MapData map,
  BorderFeatureRelinkPreview preview,
) {
  if (map.id != preview.expectedMapId || map.size != preview.expectedMapSize) {
    return null;
  }
  final layerIndex =
      map.layers.indexWhere((layer) => layer.id == preview.layerId);
  if (layerIndex < 0 || map.layers[layerIndex] is! BorderLayer) {
    return null;
  }
  final layer = map.layers[layerIndex] as BorderLayer;
  final featureIndex = layer.content.features
      .indexWhere((feature) => feature.id == preview.featureId);
  if (featureIndex < 0) {
    return null;
  }
  return (
    layerIndex: layerIndex,
    featureIndex: featureIndex,
    layer: layer,
    feature: layer.content.features[featureIndex],
  );
}

MapData _replaceFeature(
  MapData map, {
  required int layerIndex,
  required int featureIndex,
  required BorderLayer layer,
  required BorderFeature feature,
}) {
  final features = List<BorderFeature>.from(layer.content.features);
  features[featureIndex] = feature;
  final layers = List<MapLayer>.from(map.layers);
  layers[layerIndex] = layer.copyWith(
    content: BorderLayerContent(
      formatVersion: layer.content.formatVersion,
      features: features,
    ),
  );
  return map.copyWith(layers: layers);
}

BorderLayer _borderLayer(MapData map, String layerId) {
  final layer = map.layers.where((layer) => layer.id == layerId).firstOrNull;
  if (layer is! BorderLayer) {
    throw ValidationException('Border layer not found: $layerId');
  }
  return layer;
}

BorderFeature _feature(BorderLayer layer, String featureId) {
  final feature = layer.content.features
      .where((feature) => feature.id == featureId)
      .firstOrNull;
  if (feature == null) {
    throw ValidationException(
      'Border feature not found in layer ${layer.id}: $featureId',
    );
  }
  return feature;
}

String _stableId(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ValidationException('$field must be nonblank and already trimmed');
  }
  return value;
}

bool _fingerprintMatches(BorderFeature feature, String expected) {
  try {
    return computeBorderFeatureEditFingerprint(feature) == expected;
  } on FormatException {
    return false;
  } on ValidationException {
    return false;
  }
}

bool _listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}
```

### `packages/map_core/test/border/border_locality_test.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/masonry_line_fixture.dart';
import '../fixtures/border/organic_edge_reference_coast_fixture.dart';
import '../fixtures/border/post_and_rail_line_fixture.dart';

void main() {
  group('Border dirty halo', () {
    test('computes the approved request pixel radius', () {
      final request = MasonryLineFixture(
        parameters: masonryParameters(
          irregularityPermille: 1000,
          maxOverlapPx: 3,
          gapTolerancePx: 2,
          depthRows: 2,
        ),
      ).request;

      expect(computeBorderDirtyHaloRadiusForRequestPx(request), 53);
    });

    test('covers old and new move bounds plus their connecting corridor', () {
      final request = MasonryLineFixture().request;
      final oldBounds = BorderPixelRect(x: 0, y: 20, width: 10, height: 8);
      final newBounds = BorderPixelRect(x: 200, y: 20, width: 10, height: 8);
      final edit = BorderLocalEdit.forManualMove(
        oldOpaqueBoundsPx: oldBounds,
        newOpaqueBoundsPx: newBounds,
      );

      final halo = computeBorderDirtyHalo(
        request: request,
        edits: <BorderLocalEdit>[edit],
      );

      expect(
          edit.sourceBoundsPx,
          containsAll(<BorderPixelRect>[
            oldBounds,
            newBounds,
          ]));
      expect(halo.intersects(oldBounds), isTrue);
      expect(halo.intersects(newBounds), isTrue);
      expect(
        halo.intersects(
          BorderPixelRect(x: 104, y: 22, width: 2, height: 2),
        ),
        isTrue,
        reason: 'the swept corridor must be dirty between both positions',
      );
      expect(
        halo.intersects(
          BorderPixelRect(x: 260, y: 22, width: 2, height: 2),
        ),
        isFalse,
      );
    });

    test('converts paint or erase cells to canonical pixel bounds', () {
      final edit = BorderLocalEdit.forCells(
        cells: const <GridPos>[
          GridPos(x: 4, y: 5),
          GridPos(x: 2, y: 3),
          GridPos(x: 4, y: 5),
        ],
        tileSizePx: const GridSize(width: 16, height: 12),
      );

      expect(edit.sourceBoundsPx, <BorderPixelRect>[
        BorderPixelRect(x: 32, y: 36, width: 16, height: 12),
        BorderPixelRect(x: 64, y: 60, width: 16, height: 12),
      ]);
    });

    test('derives one stable namespace across nested stroke fragments', () {
      expect(borderStrokeLineageNamespaceV1('wall'), 'wall');
      expect(borderStrokeLineageNamespaceV1('wall__fragment_2'), 'wall');
      expect(
        borderStrokeLineageNamespaceV1(
          'wall__fragment_2__fragment_3',
        ),
        'wall',
      );
      expect(
        borderStrokeLineageNamespaceV1('wall__fragment_custom'),
        'wall__fragment_custom',
      );

      final lattice = buildBorderLinearLatticeV1(
        stroke: _horizontalStroke('wall__fragment_2', 4, 6, y: 2),
        tileSizePx: const GridSize(width: 16, height: 16),
      );
      expect(lattice.strokeId, 'wall__fragment_2');
      expect(lattice.lineageNamespace, 'wall');

      const preservedPoints = <GridPos>[
        GridPos(x: 4, y: 2),
        GridPos(x: 3, y: 2),
        GridPos(x: 2, y: 2),
      ];
      final preservedStroke = BorderStroke(
        id: buildBorderPreservedStrokeIdV1(
          authoredStrokeId: 'wall__fragment_2',
          sourceEdgeOffset: 17,
          wrapLength: null,
          orderedPoints: preservedPoints,
        ),
        points: preservedPoints,
        closed: false,
      );
      final preserved = buildBorderLinearLatticeV1(
        stroke: preservedStroke,
        tileSizePx: const GridSize(width: 16, height: 16),
      );
      expect(preserved.strokeId, 'wall__fragment_2');
      expect(preserved.persistedStrokeId, preservedStroke.id);
      expect(preserved.lineageNamespace, 'wall');
      expect(preserved.preservesTraversal, isTrue);
      expect(preserved.sourceEdgeOffset, 17);
      expect(preserved.edges.first.direction, BorderCardinalDirection.west);
      expect(preserved.edges.first.generationEdgeIndex, 17);

      final invalidMarker = BorderStroke(
        id: '${preservedStroke.id.substring(0, preservedStroke.id.length - 1)}'
            '${preservedStroke.id.endsWith('0') ? '1' : '0'}',
        points: preservedPoints,
        closed: false,
      );
      expect(
        () => buildBorderLinearLatticeV1(
          stroke: invalidMarker,
          tileSizePx: const GridSize(width: 16, height: 16),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('composes source offsets across nested open and wrapped erases', () {
      final firstOpenErase = BorderStrokeEditingDraft.begin(
        baseGeometry: BorderStrokeGeometry(
          strokes: <BorderStroke>[
            _horizontalStroke('wall', 2, 34, y: 4),
          ],
        ),
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 18, y: 4),
      ).previewGeometry!;
      final nestedOpenErase = BorderStrokeEditingDraft.begin(
        baseGeometry: firstOpenErase,
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 25, y: 4),
      ).previewGeometry!;
      final openIdentities = nestedOpenErase.strokes
          .map(resolveBorderStrokeLineageIdentityV1)
          .toList(growable: false);
      expect(
        openIdentities.map((identity) => identity.authoredStrokeId),
        <String>[
          'wall',
          'wall__fragment_2',
          'wall__fragment_2__fragment_2',
        ],
      );
      expect(
        openIdentities.map((identity) => identity.lineageNamespace),
        everyElement('wall'),
      );
      expect(
        openIdentities.map((identity) => identity.sourceEdgeOffset),
        <int>[0, 17, 24],
      );
      expect(
        nestedOpenErase.strokes.map(
          (stroke) => buildBorderLinearLatticeV1(
            stroke: stroke,
            tileSizePx: const GridSize(width: 16, height: 16),
          ).edges.first.generationEdgeIndex,
        ),
        <int>[0, 17, 24],
      );

      final openedLoop = BorderStrokeEditingDraft.begin(
        baseGeometry: BorderStrokeGeometry(
          strokes: <BorderStroke>[_largeClosedLoopStroke('loop')],
        ),
        mode: BorderStrokeEditingMode.erase,
        pointerDown: const GridPos(x: 20, y: 2),
      ).previewGeometry!;
      final openedPoints = openedLoop.strokes.single.points;
      final nestedWrappedErase = BorderStrokeEditingDraft.begin(
        baseGeometry: openedLoop,
        mode: BorderStrokeEditingMode.erase,
        pointerDown: openedPoints[60],
      ).previewGeometry!;
      final wrappedIdentities = nestedWrappedErase.strokes
          .map(resolveBorderStrokeLineageIdentityV1)
          .toList(growable: false);
      expect(
        wrappedIdentities.map((identity) => identity.authoredStrokeId),
        <String>['loop', 'loop__fragment_2'],
      );
      expect(
        wrappedIdentities.map((identity) => identity.sourceEdgeOffset),
        <int>[19, 80],
      );
      expect(
        wrappedIdentities.map((identity) => identity.wrapLength),
        everyElement(108),
      );
      expect(
        nestedWrappedErase.strokes.map(
          (stroke) => buildBorderLinearLatticeV1(
            stroke: stroke,
            tileSizePx: const GridSize(width: 16, height: 16),
          ).edges.first.generationEdgeIndex,
        ),
        <int>[19, 80],
      );
    });
  });

  group('Border local regeneration', () {
    test('paint and erase reuse byte-identical distant placements', () {
      final fixture = OrganicEdgeReferenceCoastFixture();
      final baseRequest = fixture.referenceCoastRequest();
      final baseGeometry = baseRequest.feature.geometry as BorderRegionGeometry;
      final paintedCells = baseGeometry.cells.toList(growable: false);
      paintedCells[0] = true;
      final paintedRequest = _copyRequestWithGeometry(
        baseRequest,
        BorderRegionGeometry(
          width: baseGeometry.width,
          height: baseGeometry.height,
          cells: paintedCells,
        ),
      );
      final baseState = resolveBorderFeatureLocalBaseline(baseRequest);
      final paintedState = resolveBorderFeatureLocalBaseline(paintedRequest);
      final baseResult = baseState.result;
      final paintedResult = paintedState.result;
      expect(baseResult.canApply, isTrue);
      expect(paintedResult.canApply, isTrue);

      for (final scenario in <({
        String name,
        BorderResolutionRequest request,
        BorderLocalResolutionState previousState,
      })>[
        (
          name: 'paint',
          request: paintedRequest,
          previousState: baseState,
        ),
        (
          name: 'erase',
          request: baseRequest,
          previousState: paintedState,
        ),
      ]) {
        final local = resolveBorderFeatureLocally(
          request: scenario.request,
          previousState: scenario.previousState,
          edits: <BorderLocalEdit>[
            BorderLocalEdit.forCells(
              cells: const <GridPos>[GridPos(x: 0, y: 0)],
              tileSizePx: scenario.request.tileSizePx,
            ),
          ],
        );
        final full = resolveBorderFeature(scenario.request);

        expect(local.result, full, reason: scenario.name);
        expect(
          local.reusedDistantPlacementSlotKeys,
          isNotEmpty,
          reason: scenario.name,
        );
        expect(local.recomputedSourceCells, isNotEmpty, reason: scenario.name);
        final previousBySlot = <String, BorderResolvedPlacement>{
          for (final placement
              in scenario.previousState.materialization.placements)
            placement.slotKey: placement,
        };
        final localBySlot = <String, BorderResolvedPlacement>{
          for (final placement in local.result.materialization!.placements)
            placement.slotKey: placement,
        };
        for (final slotKey in local.reusedDistantPlacementSlotKeys) {
          final previous = previousBySlot[slotKey]!;
          final retained = localBySlot[slotKey]!;
          expect(retained, same(previous), reason: '$scenario.name:$slotKey');
          expect(retained.id, previous.id);
          expect(retained.slotKey, previous.slotKey);
          expect(retained.stableOrderKey, previous.stableOrderKey);
          expect(retained.primitiveId, previous.primitiveId);
          expect(retained.visualSnapshotId, previous.visualSnapshotId);
          expect(_placementBytes(retained), _placementBytes(previous));
          expect(
            local.recomputedSourceCells,
            isNot(contains(retained.anchorCell)),
            reason: 'distant source branch must not run: $slotKey',
          );
        }
      }
    });

    test('chains local baselines without a complete intermediate solve', () {
      final fixture = OrganicEdgeReferenceCoastFixture();
      final baseRequest = fixture.referenceCoastRequest();
      final baseGeometry = baseRequest.feature.geometry as BorderRegionGeometry;
      final paintedCells = baseGeometry.cells.toList(growable: false);
      paintedCells[0] = true;
      final paintedRequest = _copyRequestWithGeometry(
        baseRequest,
        BorderRegionGeometry(
          width: baseGeometry.width,
          height: baseGeometry.height,
          cells: paintedCells,
        ),
      );
      final edit = BorderLocalEdit.forCells(
        cells: const <GridPos>[GridPos(x: 0, y: 0)],
        tileSizePx: baseRequest.tileSizePx,
      );
      final initialState = resolveBorderFeatureLocalBaseline(baseRequest);

      final painted = resolveBorderFeatureLocally(
        request: paintedRequest,
        previousState: initialState,
        edits: <BorderLocalEdit>[edit],
      );
      expect(painted.result, resolveBorderFeature(paintedRequest));
      expect(painted.nextState, isNotNull);

      final erased = resolveBorderFeatureLocally(
        request: baseRequest,
        previousState: painted.nextState!,
        edits: <BorderLocalEdit>[edit],
      );
      expect(erased.result, resolveBorderFeature(baseRequest));
      expect(erased.nextState, isNotNull);
      expect(erased.reusedDistantPlacementSlotKeys, isNotEmpty);
    });

    test('placement-only forced anchors do not discard distant ground', () {
      final request =
          OrganicEdgeReferenceCoastFixture().referenceCoastRequest();
      final previousState = resolveBorderFeatureLocalBaseline(request);
      final previous = previousState.materialization;
      final groundCoordinates = <(int, int)>{
        for (final cell in previous.ground) (cell.x, cell.y),
      };
      final radius = computeBorderDirtyHaloRadiusForRequestPx(request);
      late final BorderResolvedPlacement target;
      late final BorderPixelRect probe;
      for (final placement in previous.placements) {
        final anchor = BorderPixelRect(
          x: placement.anchorCell.x * request.tileSizePx.width,
          y: placement.anchorCell.y * request.tileSizePx.height,
          width: request.tileSizePx.width,
          height: request.tileSizePx.height,
        );
        if (!groundCoordinates.contains(
          (placement.anchorCell.x, placement.anchorCell.y),
        )) {
          continue;
        }
        final opaque = placement.opaqueWorldBoundsPx;
        if (opaque.x < anchor.x) {
          target = placement;
          probe = BorderPixelRect(
            x: anchor.x - radius - 1,
            y: opaque.y,
            width: 1,
            height: 1,
          );
          break;
        }
        if (opaque.right > anchor.right) {
          target = placement;
          probe = BorderPixelRect(
            x: anchor.right + radius,
            y: opaque.y,
            width: 1,
            height: 1,
          );
          break;
        }
        if (opaque.y < anchor.y) {
          target = placement;
          probe = BorderPixelRect(
            x: opaque.x,
            y: anchor.y - radius - 1,
            width: 1,
            height: 1,
          );
          break;
        }
        if (opaque.bottom > anchor.bottom) {
          target = placement;
          probe = BorderPixelRect(
            x: opaque.x,
            y: anchor.bottom + radius,
            width: 1,
            height: 1,
          );
          break;
        }
      }
      final edit = BorderLocalEdit.forManualMove(
        oldOpaqueBoundsPx: probe,
        newOpaqueBoundsPx: probe,
      );
      final halo = computeBorderDirtyHalo(
        request: request,
        edits: <BorderLocalEdit>[edit],
      );
      final anchorBounds = BorderPixelRect(
        x: target.anchorCell.x * request.tileSizePx.width,
        y: target.anchorCell.y * request.tileSizePx.height,
        width: request.tileSizePx.width,
        height: request.tileSizePx.height,
      );
      expect(halo.intersects(target.opaqueWorldBoundsPx), isTrue);
      expect(halo.intersects(anchorBounds), isFalse);

      final local = resolveBorderFeatureLocally(
        request: request,
        previousState: previousState,
        edits: <BorderLocalEdit>[edit],
      );
      final full = resolveBorderFeature(request);

      expect(local.result, full);
      expect(local.recomputedSourceCells, contains(target.anchorCell));
      expect(
        local.reusedDistantGroundCoordinates,
        contains((target.anchorCell.x, target.anchorCell.y)),
      );
    });

    test('manual move changes only swept-halo subproblems', () {
      final baseRequest = PostAndRailLineFixture(
        mapSize: const GridSize(width: 30, height: 8),
        strokes: <BorderStroke>[_horizontalStroke('main', 1, 25, y: 4)],
        parameters: fenceParameters(maxOverlapPx: 8, gapTolerancePx: 8),
      ).request;
      final beforeState = resolveBorderFeatureLocalBaseline(baseRequest);
      final before = beforeState.materialization;
      final target = before.placements.firstWhere(
        (placement) => placement.anchorCell.x == 13,
      );
      final movedRequest = _copyRequestWithOverrides(
        baseRequest,
        <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: target.slotKey,
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: false,
            offsetDeltaPx: const BorderPixelOffset(x: 8, y: -4),
          ),
        ],
      );
      final full = resolveBorderFeature(movedRequest);
      expect(
        full.canApply,
        isTrue,
        reason: full.diagnostics
            .map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}')
            .join('\n'),
      );
      final moved = full.materialization!.placements.singleWhere(
        (placement) => placement.slotKey == target.slotKey,
      );
      expect(moved.opaqueWorldBoundsPx, isNot(target.opaqueWorldBoundsPx));

      final local = resolveBorderFeatureLocally(
        request: movedRequest,
        previousState: beforeState,
        edits: <BorderLocalEdit>[
          BorderLocalEdit.forManualMove(
            oldOpaqueBoundsPx: target.opaqueWorldBoundsPx,
            newOpaqueBoundsPx: moved.opaqueWorldBoundsPx,
          ),
        ],
      );

      expect(local.result, full);
      expect(
        local.reusedDistantPlacementSlotKeys,
        isNot(contains(target.slotKey)),
      );
      expect(local.recomputedSourceCells, contains(target.anchorCell));
      expect(local.reusedDistantPlacementSlotKeys, isNotEmpty);
      final beforeBySlot = <String, BorderResolvedPlacement>{
        for (final placement in before.placements) placement.slotKey: placement,
      };
      for (final placement in local.result.materialization!.placements) {
        if (local.reusedDistantPlacementSlotKeys.contains(placement.slotKey)) {
          expect(placement, same(beforeBySlot[placement.slotKey]));
        }
      }
    });

    test('retains distant suppressed override base evidence', () {
      final longStroke = _horizontalStroke('main', 2, 34, y: 4);
      final masonrySource = MasonryLineFixture().request;
      final scenarios = <({
        String name,
        BorderResolutionRequest request,
        GridPos editCell,
      })>[
        (
          name: 'organic',
          request: OrganicEdgeReferenceCoastFixture().referenceCoastRequest(),
          editCell: const GridPos(x: 0, y: 0),
        ),
        (
          name: 'masonry',
          request: _copyRequestWithGeometryAndMapSize(
            masonrySource,
            BorderStrokeGeometry(strokes: <BorderStroke>[longStroke]),
            const GridSize(width: 40, height: 8),
          ),
          editCell: const GridPos(x: 2, y: 4),
        ),
        (
          name: 'post-and-rail',
          request: PostAndRailLineFixture(
            mapSize: const GridSize(width: 40, height: 8),
            strokes: <BorderStroke>[longStroke],
          ).request,
          editCell: const GridPos(x: 2, y: 4),
        ),
      ];

      for (final scenario in scenarios) {
        final unsuppressed = resolveBorderFeature(scenario.request);
        expect(unsuppressed.canApply, isTrue, reason: scenario.name);
        final edit = BorderLocalEdit.forCells(
          cells: <GridPos>[scenario.editCell],
          tileSizePx: scenario.request.tileSizePx,
        );
        final halo = computeBorderDirtyHalo(
          request: scenario.request,
          edits: <BorderLocalEdit>[edit],
        );
        final target = unsuppressed.materialization!.placements.firstWhere(
          (placement) =>
              !halo.intersects(placement.opaqueWorldBoundsPx) &&
              !halo.intersects(
                BorderPixelRect(
                  x: placement.anchorCell.x * scenario.request.tileSizePx.width,
                  y: placement.anchorCell.y *
                      scenario.request.tileSizePx.height,
                  width: scenario.request.tileSizePx.width,
                  height: scenario.request.tileSizePx.height,
                ),
              ),
        );
        final suppressedRequest = _copyRequestWithOverrides(
          scenario.request,
          <BorderSlotOverride>[
            BorderSlotOverride(
              slotKey: target.slotKey,
              variationSalt: BorderSignedInt64.zero,
              suppressed: true,
              locked: false,
            ),
          ],
        );
        final previousState = resolveBorderFeatureLocalBaseline(
          suppressedRequest,
        );
        expect(
          previousState.materialization.placements
              .map((placement) => placement.slotKey),
          isNot(contains(target.slotKey)),
          reason: scenario.name,
        );
        expect(
          previousState.basePlacements.map((placement) => placement.slotKey),
          contains(target.slotKey),
          reason: scenario.name,
        );

        final local = resolveBorderFeatureLocally(
          request: suppressedRequest,
          previousState: previousState,
          edits: <BorderLocalEdit>[edit],
        );
        final full = resolveBorderFeature(suppressedRequest);

        expect(local.result, full, reason: scenario.name);
        expect(
          local.result.diagnostics.map((diagnostic) => diagnostic.code),
          isNot(contains('border.resolution.override_orphaned')),
          reason: scenario.name,
        );
        expect(
          local.recomputedSourceCells,
          isNot(contains(target.anchorCell)),
          reason: '${scenario.name}: suppressed distant branch must not run',
        );
      }
    });

    test('rejects global input changes against a local baseline', () {
      final request = MasonryLineFixture().request;
      final previousState = resolveBorderFeatureLocalBaseline(request);
      final changedSeed = _copyRequestWithSeed(
        request,
        BorderSignedInt64.fromInt(999),
      );

      expect(
        () => resolveBorderFeatureLocally(
          request: changedSeed,
          previousState: previousState,
          edits: <BorderLocalEdit>[
            BorderLocalEdit.forCells(
              cells: const <GridPos>[GridPos(x: 2, y: 2)],
              tileSizePx: request.tileSizePx,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects override changes outside the declared edit halo', () {
      final request = PostAndRailLineFixture(
        mapSize: const GridSize(width: 40, height: 8),
        strokes: <BorderStroke>[
          _horizontalStroke('main', 2, 34, y: 4),
        ],
      ).request;
      final previousState = resolveBorderFeatureLocalBaseline(request);
      final target = previousState.materialization.placements.firstWhere(
        (placement) => placement.anchorCell.x >= 25,
      );
      final changed = _copyRequestWithOverrides(
        request,
        <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: target.slotKey,
            variationSalt: BorderSignedInt64.zero,
            suppressed: false,
            locked: false,
            offsetDeltaPx: const BorderPixelOffset(x: 1, y: 0),
          ),
        ],
      );

      expect(
        () => resolveBorderFeatureLocally(
          request: changed,
          previousState: previousState,
          edits: <BorderLocalEdit>[
            BorderLocalEdit.forCells(
              cells: const <GridPos>[GridPos(x: 2, y: 4)],
              tileSizePx: request.tileSizePx,
            ),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('linear erase keeps distant fragments in their lineage namespace', () {
      final stroke = _horizontalStroke('wall', 2, 34, y: 4);
      final masonrySource = MasonryLineFixture().request;
      final requests = <({String name, BorderResolutionRequest request})>[
        (
          name: 'masonry',
          request: _copyRequestWithGeometryAndMapSize(
            masonrySource,
            BorderStrokeGeometry(strokes: <BorderStroke>[stroke]),
            const GridSize(width: 40, height: 8),
          ),
        ),
        (
          name: 'post-and-rail',
          request: PostAndRailLineFixture(
            mapSize: const GridSize(width: 40, height: 8),
            strokes: <BorderStroke>[stroke],
          ).request,
        ),
      ];

      for (final scenario in requests) {
        final baseRequest = scenario.request;
        final beforeState = resolveBorderFeatureLocalBaseline(baseRequest);
        final beforeResult = beforeState.result;
        expect(
          beforeResult.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${beforeResult.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        final before = beforeResult.materialization!;
        final erasedGeometry = BorderStrokeEditingDraft.begin(
          baseGeometry: baseRequest.feature.geometry as BorderStrokeGeometry,
          mode: BorderStrokeEditingMode.erase,
          pointerDown: const GridPos(x: 18, y: 4),
        ).previewGeometry!;
        final identities = erasedGeometry.strokes
            .map(resolveBorderStrokeLineageIdentityV1)
            .toList(growable: false);
        expect(
          identities.map((identity) => identity.authoredStrokeId),
          <String>['wall', 'wall__fragment_2'],
          reason: scenario.name,
        );
        expect(
          identities.map((identity) => identity.sourceEdgeOffset),
          <int>[0, 17],
          reason: scenario.name,
        );
        final erasedRequest = _copyRequestWithGeometry(
          baseRequest,
          erasedGeometry,
        );
        final full = resolveBorderFeature(erasedRequest);
        expect(
          full.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${full.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        late final List<String> evidenceStrokeIds;
        late final int evidenceEdgeCount;
        if (scenario.name == 'masonry') {
          final evidence = resolveMasonryLineBorderWithEvidence(erasedRequest);
          evidenceStrokeIds = evidence.edges
              .map((edge) => edge.strokeId)
              .toList(growable: false);
          evidenceEdgeCount = evidence.edges.length;
        } else {
          final evidence =
              resolvePostAndRailLineBorderWithEvidence(erasedRequest);
          evidenceStrokeIds = evidence.edges
              .map((edge) => edge.strokeId)
              .toList(growable: false);
          evidenceEdgeCount = evidence.edges.length;
        }
        expect(evidenceEdgeCount, 30, reason: scenario.name);
        expect(
          evidenceStrokeIds.toSet(),
          <String>{'wall', 'wall__fragment_2'},
          reason: scenario.name,
        );

        final local = resolveBorderFeatureLocally(
          request: erasedRequest,
          previousState: beforeState,
          edits: <BorderLocalEdit>[
            BorderLocalEdit.forCells(
              cells: const <GridPos>[GridPos(x: 18, y: 4)],
              tileSizePx: erasedRequest.tileSizePx,
            ),
          ],
        );

        expect(local.result, full, reason: scenario.name);
        final distantRight = before.placements.where(
          (placement) => placement.anchorCell.x >= 25,
        );
        expect(distantRight, isNotEmpty, reason: scenario.name);
        final localBySlot = <String, BorderResolvedPlacement>{
          for (final placement in local.result.materialization!.placements)
            placement.slotKey: placement,
        };
        for (final placement in distantRight) {
          expect(
            local.reusedDistantPlacementSlotKeys,
            contains(placement.slotKey),
            reason: scenario.name,
          );
          expect(
            localBySlot[placement.slotKey],
            same(placement),
            reason: scenario.name,
          );
          expect(
            _placementBytes(localBySlot[placement.slotKey]!),
            _placementBytes(placement),
            reason: scenario.name,
          );
          expect(
            local.recomputedSourceCells,
            isNot(contains(placement.anchorCell)),
            reason: '${scenario.name}: distant source branch must not run',
          );
        }
      }
    });

    test('curved split preserves a canonically reversed distant fragment', () {
      final stroke = _reversingSplitStroke('wall');
      final masonrySource = MasonryLineFixture(
        parameters: masonryParameters(gapTolerancePx: 5),
      ).request;
      final requests = <({String name, BorderResolutionRequest request})>[
        (
          name: 'masonry',
          request: _copyRequestWithGeometryAndMapSize(
            masonrySource,
            BorderStrokeGeometry(strokes: <BorderStroke>[stroke]),
            const GridSize(width: 44, height: 24),
          ),
        ),
        (
          name: 'post-and-rail',
          request: PostAndRailLineFixture(
            mapSize: const GridSize(width: 44, height: 24),
            strokes: <BorderStroke>[stroke],
          ).request,
        ),
      ];

      for (final scenario in requests) {
        final baseRequest = scenario.request;
        final beforeState = resolveBorderFeatureLocalBaseline(baseRequest);
        final beforeResult = beforeState.result;
        expect(
          beforeResult.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${beforeResult.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        final before = beforeResult.materialization!;
        final erasedGeometry = BorderStrokeEditingDraft.begin(
          baseGeometry: baseRequest.feature.geometry as BorderStrokeGeometry,
          mode: BorderStrokeEditingMode.erase,
          pointerDown: const GridPos(x: 20, y: 12),
        ).previewGeometry!;
        final identities = erasedGeometry.strokes
            .map(resolveBorderStrokeLineageIdentityV1)
            .toList(growable: false);
        expect(
          identities.map((identity) => identity.authoredStrokeId),
          <String>['wall', 'wall__fragment_2'],
          reason: scenario.name,
        );
        expect(
          erasedGeometry.strokes.last.points.first,
          const GridPos(x: 20, y: 13),
          reason: 'the detached fragment must retain source traversal',
        );
        expect(
          canonicalizeBorderStrokeV1(
            id: 'probe',
            sampledPoints: erasedGeometry.strokes.last.points,
            closed: false,
          ).points.first,
          const GridPos(x: 38, y: 4),
          reason: 'ordinary canonicalization would reverse this fragment',
        );
        final erasedRequest = _copyRequestWithGeometry(
          baseRequest,
          erasedGeometry,
        );
        final full = resolveBorderFeature(erasedRequest);
        expect(
          full.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${full.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        final edit = BorderLocalEdit.forCells(
          cells: const <GridPos>[GridPos(x: 20, y: 12)],
          tileSizePx: erasedRequest.tileSizePx,
        );

        final local = resolveBorderFeatureLocally(
          request: erasedRequest,
          previousState: beforeState,
          edits: <BorderLocalEdit>[edit],
        );

        expect(local.result, full, reason: scenario.name);
        final distantSlots = before.placements
            .where(
              (placement) =>
                  placement.anchorCell.x >= 30 &&
                  placement.anchorCell.y >= 18 &&
                  !local.dirtyHalo.intersects(
                    placement.opaqueWorldBoundsPx,
                  ),
            )
            .map((placement) => placement.slotKey)
            .toList(growable: false);
        expect(distantSlots, isNotEmpty, reason: scenario.name);
        expect(
          local.reusedDistantPlacementSlotKeys,
          containsAll(distantSlots),
          reason: scenario.name,
        );
        final beforeBySlot = <String, BorderResolvedPlacement>{
          for (final placement in before.placements)
            placement.slotKey: placement,
        };
        expect(
          local.recomputedSourceCells,
          isNot(contains(beforeBySlot[distantSlots.first]!.anchorCell)),
          reason: '${scenario.name}: distant curve branch must not run',
        );
      }
    });

    test('opening a closed loop preserves its distant perimeter', () {
      final stroke = _largeClosedLoopStroke('wall');
      final masonrySource = MasonryLineFixture(
        parameters: masonryParameters(gapTolerancePx: 7),
      ).request;
      final requests = <({String name, BorderResolutionRequest request})>[
        (
          name: 'masonry',
          request: _copyRequestWithGeometryAndMapSize(
            masonrySource,
            BorderStrokeGeometry(strokes: <BorderStroke>[stroke]),
            const GridSize(width: 44, height: 24),
          ),
        ),
        (
          name: 'post-and-rail',
          request: PostAndRailLineFixture(
            mapSize: const GridSize(width: 44, height: 24),
            strokes: <BorderStroke>[stroke],
          ).request,
        ),
      ];

      for (final scenario in requests) {
        final baseRequest = scenario.request;
        final beforeState = resolveBorderFeatureLocalBaseline(baseRequest);
        final beforeResult = beforeState.result;
        expect(
          beforeResult.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${beforeResult.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        final before = beforeResult.materialization!;
        final erasedGeometry = BorderStrokeEditingDraft.begin(
          baseGeometry: baseRequest.feature.geometry as BorderStrokeGeometry,
          mode: BorderStrokeEditingMode.erase,
          pointerDown: const GridPos(x: 20, y: 2),
        ).previewGeometry!;
        expect(erasedGeometry.strokes, hasLength(1), reason: scenario.name);
        final identity = resolveBorderStrokeLineageIdentityV1(
          erasedGeometry.strokes.single,
        );
        expect(identity.authoredStrokeId, 'wall', reason: scenario.name);
        expect(identity.sourceEdgeOffset, 19, reason: scenario.name);
        expect(identity.wrapLength, 108, reason: scenario.name);
        expect(erasedGeometry.strokes.single.closed, isFalse);
        expect(
          erasedGeometry.strokes.single.points.first,
          const GridPos(x: 21, y: 2),
          reason: 'opening must retain the closed source traversal',
        );
        expect(
          canonicalizeBorderStrokeV1(
            id: 'probe',
            sampledPoints: erasedGeometry.strokes.single.points,
            closed: false,
          ).points.first,
          const GridPos(x: 19, y: 2),
          reason: 'ordinary canonicalization would reverse the opened loop',
        );
        final erasedRequest = _copyRequestWithGeometry(
          baseRequest,
          erasedGeometry,
        );
        final full = resolveBorderFeature(erasedRequest);
        expect(
          full.canApply,
          isTrue,
          reason: '${scenario.name}: '
              '${full.diagnostics.map((diagnostic) => '${diagnostic.code}:${diagnostic.parameters}').join(', ')}',
        );
        final edit = BorderLocalEdit.forCells(
          cells: const <GridPos>[GridPos(x: 20, y: 2)],
          tileSizePx: erasedRequest.tileSizePx,
        );

        final local = resolveBorderFeatureLocally(
          request: erasedRequest,
          previousState: beforeState,
          edits: <BorderLocalEdit>[edit],
        );

        expect(local.result, full, reason: scenario.name);
        final distantSlots = before.placements
            .where(
              (placement) =>
                  placement.anchorCell.y >= 18 &&
                  !local.dirtyHalo.intersects(
                    placement.opaqueWorldBoundsPx,
                  ),
            )
            .map((placement) => placement.slotKey)
            .toList(growable: false);
        expect(distantSlots, isNotEmpty, reason: scenario.name);
        expect(
          local.reusedDistantPlacementSlotKeys,
          containsAll(distantSlots),
          reason: scenario.name,
        );
        final beforeBySlot = <String, BorderResolvedPlacement>{
          for (final placement in before.placements)
            placement.slotKey: placement,
        };
        expect(
          local.recomputedSourceCells,
          isNot(contains(beforeBySlot[distantSlots.first]!.anchorCell)),
          reason: '${scenario.name}: distant loop branch must not run',
        );
      }
    });
  });
}

BorderResolutionRequest _copyRequestWithGeometry(
  BorderResolutionRequest source,
  BorderFeatureGeometry geometry,
) =>
    BorderResolutionRequest(
      mapSize: source.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: source.feature.seed,
        geometry: geometry,
        paramsOverride: source.feature.paramsOverride,
        overrides: source.feature.overrides,
        keepOutRegions: source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

BorderResolutionRequest _copyRequestWithGeometryAndMapSize(
  BorderResolutionRequest source,
  BorderFeatureGeometry geometry,
  GridSize mapSize,
) =>
    BorderResolutionRequest(
      mapSize: mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: source.feature.seed,
        geometry: geometry,
        paramsOverride: source.feature.paramsOverride,
        overrides: source.feature.overrides,
        keepOutRegions: source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

String _placementBytes(BorderResolvedPlacement placement) =>
    jsonEncode(encodeBorderResolvedPlacementJson(placement));

BorderResolutionRequest _copyRequestWithOverrides(
  BorderResolutionRequest source,
  List<BorderSlotOverride> overrides,
) =>
    BorderResolutionRequest(
      mapSize: source.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: source.feature.seed,
        geometry: source.feature.geometry,
        paramsOverride: source.feature.paramsOverride,
        overrides: overrides,
        keepOutRegions: source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

BorderResolutionRequest _copyRequestWithSeed(
  BorderResolutionRequest source,
  BorderSignedInt64 seed,
) =>
    BorderResolutionRequest(
      mapSize: source.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: seed,
        geometry: source.feature.geometry,
        paramsOverride: source.feature.paramsOverride,
        overrides: source.feature.overrides,
        keepOutRegions: source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

BorderStroke _horizontalStroke(
  String id,
  int fromX,
  int toX, {
  required int y,
}) =>
    BorderStroke(
      id: id,
      points: <GridPos>[
        for (var x = fromX; x <= toX; x += 1) GridPos(x: x, y: y),
      ],
      closed: false,
    );

BorderStroke _reversingSplitStroke(String id) => BorderStroke(
      id: id,
      points: <GridPos>[
        for (var x = 2; x <= 20; x += 1) GridPos(x: x, y: 2),
        for (var y = 3; y <= 20; y += 1) GridPos(x: 20, y: y),
        for (var x = 21; x <= 38; x += 1) GridPos(x: x, y: 20),
        for (var y = 19; y >= 4; y -= 1) GridPos(x: 38, y: y),
      ],
      closed: false,
    );

BorderStroke _largeClosedLoopStroke(String id) => BorderStroke(
      id: id,
      points: <GridPos>[
        for (var x = 2; x <= 38; x += 1) GridPos(x: x, y: 2),
        for (var y = 3; y <= 20; y += 1) GridPos(x: 38, y: y),
        for (var x = 37; x >= 2; x -= 1) GridPos(x: x, y: 20),
        for (var y = 19; y >= 3; y -= 1) GridPos(x: 2, y: y),
      ],
      closed: true,
    );
```

### `packages/map_core/test/border/border_override_resolution_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/masonry_line_fixture.dart';

void main() {
  group('resolveBorderOverrides', () {
    test('preserves an override-free base resolution exactly', () {
      final request = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(request).materialization!;

      final resolved = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(resolved.ground, base.ground);
      expect(resolved.placements, base.placements);
      expect(resolved.diagnosticReport.hasDiagnostics, isFalse);
      expect(resolved.orphanedSlotKeys, isEmpty);
      expect(resolved.intentionalGapSlotKeys, isEmpty);
    });

    test('suppresses one stable slot without changing any other slot', () {
      final baseRequest = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements[base.placements.length ~/ 2];
      final request = _copyRequest(
        baseRequest,
        overrides: <BorderSlotOverride>[
          _override(slotKey: target.slotKey, suppressed: true),
        ],
      );

      final resolved = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(
        resolved.placements,
        base.placements
            .where((placement) => placement.slotKey != target.slotKey),
      );
      expect(resolved.intentionalGapSlotKeys, <String>{target.slotKey});
      expect(resolved.diagnosticReport.hasDiagnostics, isFalse);
    });

    test('replaces, moves, and transforms one slot while preserving its key',
        () {
      final primitives = <BorderPublishedPrimitive>[
        masonryPrimitive(
          id: 'a-base',
          fingerprintCharacter: '1',
          allowFlipX: true,
        ),
        masonryPrimitive(
          id: 'z-replacement',
          fingerprintCharacter: '2',
          allowFlipX: true,
        ),
      ];
      final baseRequest = MasonryLineFixture(
        primitives: primitives,
        parameters: masonryParameters(variationPermille: 0),
      ).request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements.first;
      final request = _copyRequest(
        baseRequest,
        overrides: <BorderSlotOverride>[
          _override(
            slotKey: target.slotKey,
            replacementPrimitiveId: 'z-replacement',
            offsetDeltaPx: const BorderPixelOffset(x: 2, y: -1),
            transformOverride: BorderSpriteTransform(
              quarterTurns: target.transform.quarterTurns,
              flipX: true,
            ),
          ),
        ],
      );

      final resolved = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(resolved.diagnosticReport.hasDiagnostics, isFalse);
      final changed = resolved.placements.singleWhere(
        (placement) => placement.slotKey == target.slotKey,
      );
      expect(changed.id, target.id);
      expect(changed.slotKey, target.slotKey);
      expect(changed.stableOrderKey, target.stableOrderKey);
      expect(changed.anchorCell, target.anchorCell);
      expect(changed.primitiveId, 'z-replacement');
      expect(changed.visualSnapshotId, primitives.last.visualSnapshotId);
      expect(changed.transform.flipX, isTrue);
      final oldTarget = _targetAnchorWorldPx(target, primitives.first);
      final newTarget = _targetAnchorWorldPx(changed, primitives.last);
      expect(newTarget.x, oldTarget.x + 2);
      expect(newTarget.y, oldTarget.y - 1);
      expect(
        resolved.placements
            .where((placement) => placement.slotKey != target.slotKey),
        base.placements
            .where((placement) => placement.slotKey != target.slotKey),
      );
    });

    test('uses variationSalt deterministically and only for its local slot',
        () {
      final primitives = <BorderPublishedPrimitive>[
        masonryPrimitive(
          id: 'a-base',
          fingerprintCharacter: '3',
          weight: 1,
        ),
        masonryPrimitive(
          id: 'z-local-variant',
          fingerprintCharacter: '4',
          weight: 1000,
        ),
      ];
      final baseRequest = MasonryLineFixture(
        primitives: primitives,
        parameters: masonryParameters(variationPermille: 0),
      ).request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements.first;
      final request = _copyRequest(
        baseRequest,
        overrides: <BorderSlotOverride>[
          _override(
            slotKey: target.slotKey,
            variationSalt: BorderSignedInt64.fromInt(9),
          ),
        ],
      );

      BorderOverrideResolution resolve() => resolveBorderOverrides(
            request: request,
            baseGround: base.ground,
            basePlacements: base.placements,
          );

      final first = resolve();
      final second = resolve();
      expect(first, second);
      expect(
        first.placements
            .singleWhere(
              (placement) => placement.slotKey == target.slotKey,
            )
            .primitiveId,
        'z-local-variant',
      );
      expect(
        first.placements
            .where((placement) => placement.slotKey != target.slotKey),
        base.placements
            .where((placement) => placement.slotKey != target.slotKey),
      );
    });

    test('honors a locked placement byte-for-byte including exact order', () {
      final baseRequest = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements.first;
      final locked = _movePlacement(target, x: 1, y: 0);
      final request = _copyRequest(
        baseRequest,
        overrides: <BorderSlotOverride>[
          _override(
            slotKey: target.slotKey,
            locked: true,
            lockedPlacement: locked,
            replacementPrimitiveId: locked.primitiveId,
            offsetDeltaPx: const BorderPixelOffset(x: 1, y: 0),
            transformOverride: locked.transform,
          ),
        ],
      );

      final resolved = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(resolved.diagnosticReport.hasDiagnostics, isFalse);
      expect(
        resolved.placements.singleWhere(
          (placement) => placement.slotKey == target.slotKey,
        ),
        locked,
      );
    });

    test('keeps orphan overrides attached and diagnoses them deterministically',
        () {
      final baseRequest = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final request = _copyRequest(
        baseRequest,
        overrides: <BorderSlotOverride>[
          _override(slotKey: 'orphan-z', suppressed: true),
          _override(slotKey: 'orphan-a', suppressed: true),
        ],
      );

      final first = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );
      final second = resolveBorderOverrides(
        request: request,
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(first, second);
      expect(first.placements, base.placements);
      expect(first.orphanedSlotKeys, <String>{'orphan-a', 'orphan-z'});
      expect(first.orphanedSlotKeys.toList(), <String>['orphan-a', 'orphan-z']);
      expect(
        first.diagnostics.map((diagnostic) => diagnostic.code),
        everyElement('border.resolution.override_orphaned'),
      );
      expect(
        first.diagnostics.map((diagnostic) => diagnostic.slotKey),
        <String>['orphan-a', 'orphan-z'],
      );
      expect(first.diagnosticReport.hasErrors, isFalse);
      expect(first.diagnosticReport.hasWarnings, isTrue);
    });

    test('validates published references before diagnosing an orphan', () {
      final baseRequest = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final resolved = resolveBorderOverrides(
        request: _copyRequest(
          baseRequest,
          overrides: <BorderSlotOverride>[
            _override(
              slotKey: 'orphan-with-missing-primitive',
              replacementPrimitiveId: 'missing-primitive',
            ),
          ],
        ),
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(resolved.placements, base.placements);
      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll(<String>[
          'border.resolution.override_primitive_missing',
          'border.resolution.override_orphaned',
        ]),
      );
      expect(resolved.diagnosticReport.hasErrors, isTrue);
    });

    test('validates primitive, transform, snapshot, corridor, and canvas', () {
      final baseRequest = MasonryLineFixture(
        parameters: masonryParameters(variationPermille: 0),
      ).request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements.first;
      final cases = <BorderSlotOverride>[
        _override(
          slotKey: target.slotKey,
          replacementPrimitiveId: 'missing-primitive',
        ),
        _override(
          slotKey: target.slotKey,
          transformOverride: BorderSpriteTransform(
            quarterTurns: target.transform.quarterTurns,
            flipX: true,
          ),
        ),
        _override(
          slotKey: target.slotKey,
          offsetDeltaPx: const BorderPixelOffset(x: 10000, y: 0),
        ),
        _override(
          slotKey: target.slotKey,
          locked: true,
          lockedPlacement: _copyPlacement(
            target,
            visualSnapshotId: _snapshotId('f'),
          ),
        ),
      ];
      final expectedCodes = <String>[
        'border.resolution.override_primitive_missing',
        'border.resolution.override_transform_not_allowed',
        'border.resolution.override_outside_corridor',
        'border.resolution.override_snapshot_invalid',
      ];

      for (var index = 0; index < cases.length; index += 1) {
        final resolved = resolveBorderOverrides(
          request: _copyRequest(
            baseRequest,
            overrides: <BorderSlotOverride>[cases[index]],
          ),
          baseGround: base.ground,
          basePlacements: base.placements,
        );

        expect(
          resolved.diagnostics.map((diagnostic) => diagnostic.code),
          contains(expectedCodes[index]),
          reason: 'case $index: ${resolved.diagnostics}',
        );
        expect(resolved.diagnosticReport.hasErrors, isTrue);
      }
    });

    test('rejects a moved placement whose opaque pixels leave the canvas', () {
      final primitive = masonryPrimitive(
        id: 'canvas-check',
        fingerprintCharacter: '6',
      );
      final baseRequest = MasonryLineFixture(
        primitives: <BorderPublishedPrimitive>[primitive],
      ).request;
      final basePlacement = _placementForPrimitive(
        primitive,
        topLeft: const BorderPixelPos(x: 5, y: 5),
      );
      final resolved = resolveBorderOverrides(
        request: _copyRequest(
          baseRequest,
          overrides: <BorderSlotOverride>[
            _override(
              slotKey: basePlacement.slotKey,
              offsetDeltaPx: const BorderPixelOffset(x: -17, y: 0),
            ),
          ],
        ),
        baseGround: const <BorderResolvedGroundCell>[],
        basePlacements: <BorderResolvedPlacement>[basePlacement],
      );

      expect(resolved.placements, <BorderResolvedPlacement>[basePlacement]);
      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.override_outside_canvas'),
      );
    });

    test('accepts the exact movement-corridor bound and rejects one pixel past',
        () {
      final primitive = masonryPrimitive(
        id: 'corridor-check',
        fingerprintCharacter: '9',
      );
      final baseRequest = MasonryLineFixture(
        primitives: <BorderPublishedPrimitive>[primitive],
      ).request;
      final basePlacement = _placementForPrimitive(
        primitive,
        topLeft: const BorderPixelPos(x: 40, y: 40),
      );
      final radius = _corridorRadius(baseRequest);

      BorderOverrideResolution resolve(int deltaX) => resolveBorderOverrides(
            request: _copyRequest(
              baseRequest,
              overrides: <BorderSlotOverride>[
                _override(
                  slotKey: basePlacement.slotKey,
                  offsetDeltaPx: BorderPixelOffset(x: deltaX, y: 0),
                ),
              ],
            ),
            baseGround: const <BorderResolvedGroundCell>[],
            basePlacements: <BorderResolvedPlacement>[basePlacement],
          );

      final atBoundary = resolve(radius);
      final outside = resolve(radius + 1);

      expect(atBoundary.diagnosticReport.hasDiagnostics, isFalse);
      expect(
        _targetAnchorWorldPx(atBoundary.placements.single, primitive).x,
        _targetAnchorWorldPx(basePlacement, primitive).x + radius,
      );
      expect(outside.placements, <BorderResolvedPlacement>[basePlacement]);
      expect(
        outside.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.override_outside_corridor'),
      );
    });

    test('rejects a locked primitive whose role changes the stable slot', () {
      final structure = masonryPrimitive(
        id: 'structure',
        fingerprintCharacter: '7',
      );
      final surfacePatch = masonryPrimitive(
        id: 'surface-patch',
        fingerprintCharacter: '8',
        role: BorderPrimitiveRole.surfacePatch,
      );
      final baseRequest = MasonryLineFixture(
        primitives: <BorderPublishedPrimitive>[structure, surfacePatch],
        parameters: masonryParameters(
          detailDensityPermille: 0,
          variationPermille: 0,
        ),
      ).request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final target = base.placements.first;
      final locked = _copyPlacement(
        target,
        primitiveId: surfacePatch.id,
        visualSnapshotId: surfacePatch.visualSnapshotId,
      );
      final resolved = resolveBorderOverrides(
        request: _copyRequest(
          baseRequest,
          overrides: <BorderSlotOverride>[
            _override(
              slotKey: target.slotKey,
              locked: true,
              lockedPlacement: locked,
            ),
          ],
        ),
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.override_primitive_role_mismatch'),
      );
      expect(resolved.diagnosticReport.hasErrors, isTrue);
      expect(
        resolved.placements.singleWhere(
          (placement) => placement.slotKey == target.slotKey,
        ),
        target,
      );
    });

    test('uses transformed real opaque pixels for keep-out filtering', () {
      final transparentAtKeepOut = List<bool>.filled(16, false)..[3] = true;
      final opaqueAtKeepOut = List<bool>.filled(16, false)..[5] = true;
      final transform = BorderSpriteTransform(quarterTurns: 1, flipX: true);

      BorderOverrideResolution resolve(List<bool> occupancy) {
        final primitive = masonryPrimitive(
          id: 'sparse',
          fingerprintCharacter: '5',
          width: 4,
          height: 4,
          allowFlipX: true,
          anchorPx: const BorderPixelPos(x: 0, y: 0),
          opaqueBounds: BorderPixelRect(x: 0, y: 0, width: 4, height: 4),
          occupancy: occupancy,
        );
        final source = MasonryLineFixture(
          primitives: <BorderPublishedPrimitive>[primitive],
          keepOutRegions: <BorderKeepOutRegion>[_keepOutCell(1, 1)],
        ).request;
        final placement = _placementForPrimitive(
          primitive,
          topLeft: const BorderPixelPos(x: 15, y: 15),
          transform: transform,
        );
        return resolveBorderOverrides(
          request: source,
          baseGround: const <BorderResolvedGroundCell>[],
          basePlacements: <BorderResolvedPlacement>[placement],
        );
      }

      final transparent = resolve(transparentAtKeepOut);
      final opaque = resolve(opaqueAtKeepOut);

      expect(transparent.diagnosticReport.hasDiagnostics, isFalse);
      expect(transparent.placements, hasLength(1));
      expect(opaque.diagnosticReport.hasDiagnostics, isFalse);
      expect(opaque.placements, isEmpty);
      expect(opaque.intentionalGapSlotKeys, <String>{'slot-sparse'});
    });

    test('rejects a keep-out whose stable mask does not match the canvas', () {
      final baseRequest = MasonryLineFixture().request;
      final base = resolveMasonryLineBorder(baseRequest).materialization!;
      final badKeepOut = BorderKeepOutRegion(
        id: 'bad-size',
        region: BorderRegionGeometry(
          width: 1,
          height: 1,
          cells: const <bool>[true],
        ),
      );

      final resolved = resolveBorderOverrides(
        request: _copyRequest(
          baseRequest,
          keepOutRegions: <BorderKeepOutRegion>[badKeepOut],
        ),
        baseGround: base.ground,
        basePlacements: base.placements,
      );

      expect(resolved.diagnosticReport.hasErrors, isTrue);
      expect(
        resolved.diagnostics.map((diagnostic) => diagnostic.code),
        contains('border.resolution.keep_out_size_mismatch'),
      );
      expect(resolved.placements, base.placements);
    });
  });
}

BorderSlotOverride _override({
  required String slotKey,
  BorderSignedInt64? variationSalt,
  bool suppressed = false,
  bool locked = false,
  BorderResolvedPlacement? lockedPlacement,
  String? replacementPrimitiveId,
  BorderPixelOffset? offsetDeltaPx,
  BorderSpriteTransform? transformOverride,
}) =>
    BorderSlotOverride(
      slotKey: slotKey,
      variationSalt: variationSalt ?? BorderSignedInt64.zero,
      suppressed: suppressed,
      locked: locked,
      lockedPlacement: lockedPlacement,
      replacementPrimitiveId: replacementPrimitiveId,
      offsetDeltaPx: offsetDeltaPx,
      transformOverride: transformOverride,
    );

BorderResolutionRequest _copyRequest(
  BorderResolutionRequest source, {
  List<BorderSlotOverride>? overrides,
  List<BorderKeepOutRegion>? keepOutRegions,
}) =>
    BorderResolutionRequest(
      mapSize: source.mapSize,
      tileSizePx: source.tileSizePx,
      blueprintId: source.blueprintId,
      blueprintRevision: source.blueprintRevision,
      feature: BorderFeature(
        id: source.feature.id,
        name: source.feature.name,
        blueprintId: source.feature.blueprintId,
        seed: source.feature.seed,
        geometry: source.feature.geometry,
        paramsOverride: source.feature.paramsOverride,
        overrides: overrides ?? source.feature.overrides,
        keepOutRegions: keepOutRegions ?? source.feature.keepOutRegions,
      ),
      visualSnapshots: source.visualSnapshots,
      resolverVersion: source.resolverVersion,
    );

BorderResolvedPlacement _movePlacement(
  BorderResolvedPlacement source, {
  required int x,
  required int y,
}) =>
    _copyPlacement(
      source,
      topLeftWorldPx: BorderPixelPos(
        x: source.topLeftWorldPx.x + x,
        y: source.topLeftWorldPx.y + y,
      ),
      opaqueWorldBoundsPx: BorderPixelRect(
        x: source.opaqueWorldBoundsPx.x + x,
        y: source.opaqueWorldBoundsPx.y + y,
        width: source.opaqueWorldBoundsPx.width,
        height: source.opaqueWorldBoundsPx.height,
      ),
    );

BorderResolvedPlacement _copyPlacement(
  BorderResolvedPlacement source, {
  String? primitiveId,
  String? visualSnapshotId,
  BorderPixelPos? topLeftWorldPx,
  BorderPixelRect? opaqueWorldBoundsPx,
}) =>
    BorderResolvedPlacement(
      id: source.id,
      slotKey: source.slotKey,
      primitiveId: primitiveId ?? source.primitiveId,
      visualSnapshotId: visualSnapshotId ?? source.visualSnapshotId,
      anchorCell: source.anchorCell,
      topLeftWorldPx: topLeftWorldPx ?? source.topLeftWorldPx,
      opaqueWorldBoundsPx: opaqueWorldBoundsPx ?? source.opaqueWorldBoundsPx,
      transform: source.transform,
      drawBand: source.drawBand,
      stableOrderKey: source.stableOrderKey,
    );

BorderResolvedPlacement _placementForPrimitive(
  BorderPublishedPrimitive primitive, {
  required BorderPixelPos topLeft,
  BorderSpriteTransform? transform,
}) =>
    BorderResolvedPlacement(
      id: 'placement-sparse',
      slotKey: 'slot-sparse',
      primitiveId: primitive.id,
      visualSnapshotId: primitive.visualSnapshotId,
      anchorCell: const GridPos(x: 1, y: 1),
      topLeftWorldPx: topLeft,
      opaqueWorldBoundsPx: BorderPixelRect(
        x: topLeft.x,
        y: topLeft.y,
        width: 4,
        height: 4,
      ),
      transform:
          transform ?? BorderSpriteTransform(quarterTurns: 0, flipX: false),
      drawBand: BorderDrawBand.structure,
      stableOrderKey: BorderStableOrderKey(
        drawBandIndex: borderDrawBandV1Index(BorderDrawBand.structure),
        anchorRowMajor: 9,
        passIndex: 0,
        rank: 0,
        ordinalLocal: 0,
        slotKey: 'slot-sparse',
      ),
    );

BorderKeepOutRegion _keepOutCell(int x, int y) => BorderKeepOutRegion(
      id: 'keep-out-$x-$y',
      region: BorderRegionGeometry(
        width: 8,
        height: 8,
        cells: <bool>[
          for (var index = 0; index < 64; index += 1) index == y * 8 + x,
        ],
      ),
    );

String _snapshotId(String character) =>
    'border-snapshot-sha256:${character * 64}';

BorderPixelPos _targetAnchorWorldPx(
  BorderResolvedPlacement placement,
  BorderPublishedPrimitive primitive,
) {
  final origin = resolveBorderSpriteGeometry(
    metrics: primitive.publishedMetrics,
    sourceAnchorPx: primitive.anchorPx,
    transform: placement.transform,
    targetAnchorWorldPx: const BorderPixelPos(x: 0, y: 0),
  );
  return BorderPixelPos(
    x: placement.topLeftWorldPx.x - origin.topLeftWorldPx.x,
    y: placement.topLeftWorldPx.y - origin.topLeftWorldPx.y,
  );
}

int _corridorRadius(BorderResolutionRequest request) {
  final definition = request.blueprintRevision!.definition;
  final parameters = request.feature.paramsOverride ?? definition.defaults;
  final tileSize = request.tileSizePx.width > request.tileSizePx.height
      ? request.tileSizePx.width
      : request.tileSizePx.height;
  return computeBorderDirtyHaloRadiusPx(
    depthRows: parameters.depthRows,
    tileSizePx: tileSize,
    largestTransformedOpaqueExtentPx: maximumBorderTransformedOpaqueExtentPx(
      definition.primitives.map((primitive) => primitive.publishedMetrics),
    ),
    jitterMaxPx: computeBorderJitterMaxPx(
      irregularityPermille: parameters.irregularityPermille,
      tileSizePx: tileSize,
    ),
    maxOverlapPx: parameters.maxOverlapPx,
    gapTolerancePx: parameters.gapTolerancePx,
  );
}
```

### `packages/map_core/test/border/border_relink_operations_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../fixtures/border/masonry_line_fixture.dart';
import '../fixtures/border/post_and_rail_line_fixture.dart';

void main() {
  group('Border blueprint relink preview', () {
    test('linear-to-linear preserves authored data and applies atomically', () {
      final sourceRequest = MasonryLineFixture(
        parameters: masonryParameters(),
      ).request;
      final sourceResult = resolveBorderFeature(sourceRequest);
      expect(sourceResult.canApply, isTrue);
      final sourceFeature = _copyFeature(
        sourceRequest.feature,
        materialization: sourceResult.materialization,
      );
      final map = _mapWith(sourceFeature);
      final targetFixture = PostAndRailLineFixture(
        mapSize: map.size,
        geometry: sourceFeature.geometry,
      );

      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: sourceFeature.id,
        targetBlueprintId: 'fence-target',
        targetBlueprintRevision: targetFixture.request.blueprintRevision!,
        visualSnapshots: targetFixture.request.visualSnapshots,
        tileSizePx: targetFixture.request.tileSizePx,
        resolverVersion: targetFixture.request.resolverVersion,
      );

      expect(preview.kind, BorderRelinkKind.sameFamily);
      expect(preview.losses, isEmpty);
      expect(preview.canApplyResolvedRelink, isTrue);
      expect(preview.proposedRequest, isNotNull);
      expect(preview.proposedResult?.canApply, isTrue);
      expect(_featureOf(map), same(sourceFeature),
          reason: 'preview must not mutate the source map');

      final updated = applyBorderFeatureRelinkPreview(map, preview: preview);
      final applied = _featureOf(updated);

      expect(applied.blueprintId, 'fence-target');
      expect(applied.id, sourceFeature.id);
      expect(applied.name, sourceFeature.name);
      expect(applied.seed, sourceFeature.seed);
      expect(applied.geometry, same(sourceFeature.geometry));
      expect(applied.paramsOverride, same(sourceFeature.paramsOverride));
      expect(applied.overrides, sourceFeature.overrides);
      expect(applied.keepOutRegions, sourceFeature.keepOutRegions);
      expect(applied.materialization,
          same(preview.proposedResult!.materialization));
      expect(updated.layers[1], same(map.layers[1]),
          reason: 'unrelated layers, including collision, stay untouched');
    });

    test('missing source blueprint still infers the family from geometry', () {
      final sourceRequest = MasonryLineFixture().request;
      final missingSourceFeature = _copyFeature(
        sourceRequest.feature,
        blueprintId: 'removed-blueprint',
      );
      final map = _mapWith(missingSourceFeature);
      final targetFixture = PostAndRailLineFixture(
        mapSize: map.size,
        geometry: missingSourceFeature.geometry,
      );

      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: missingSourceFeature.id,
        targetBlueprintId: 'replacement-fence',
        targetBlueprintRevision: targetFixture.request.blueprintRevision!,
        visualSnapshots: targetFixture.request.visualSnapshots,
        tileSizePx: targetFixture.request.tileSizePx,
        resolverVersion: targetFixture.request.resolverVersion,
      );

      expect(preview.kind, BorderRelinkKind.sameFamily);
      expect(preview.sourceFamily, BorderGeometryFamily.linear);
      expect(preview.targetFamily, BorderGeometryFamily.linear);
      expect(preview.canApplyResolvedRelink, isTrue);
      expect(_featureOf(map).blueprintId, 'removed-blueprint');
    });

    test('cross-family change requires explicit reset with an exact loss list',
        () {
      final sourceRequest = MasonryLineFixture(
        parameters: masonryParameters(),
      ).request;
      final sourceResult = resolveBorderFeature(sourceRequest);
      final sourceFeature = BorderFeature(
        id: sourceRequest.feature.id,
        name: sourceRequest.feature.name,
        blueprintId: sourceRequest.feature.blueprintId,
        seed: sourceRequest.feature.seed,
        geometry: sourceRequest.feature.geometry,
        paramsOverride: sourceRequest.feature.paramsOverride,
        overrides: <BorderSlotOverride>[
          BorderSlotOverride(
            slotKey: 'old-orphan-slot',
            variationSalt: BorderSignedInt64.fromInt(9),
            suppressed: true,
            locked: false,
          ),
        ],
        keepOutRegions: <BorderKeepOutRegion>[
          BorderKeepOutRegion(
            id: 'old-keep-out',
            region: BorderRegionGeometry(
              width: 8,
              height: 8,
              cells: <bool>[
                true,
                ...List<bool>.filled(63, false),
              ],
            ),
          ),
        ],
        materialization: sourceResult.materialization,
      );
      final map = _mapWith(sourceFeature);

      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: sourceFeature.id,
        targetBlueprintId: 'organic-target',
        targetBlueprintRevision: _organicRevision(),
        visualSnapshots: const <BorderVisualSnapshot>[],
        tileSizePx: const GridSize(width: 16, height: 16),
        resolverVersion: borderResolverVersion,
      );

      expect(preview.kind, BorderRelinkKind.requiresFamilyReset);
      expect(preview.canApplyResolvedRelink, isFalse);
      expect(preview.proposedRequest, isNull);
      expect(preview.proposedResult, isNull);
      expect(
        preview.losses,
        <BorderRelinkLoss>[
          BorderRelinkLoss.geometry,
          BorderRelinkLoss.parameters,
          BorderRelinkLoss.overrides,
          BorderRelinkLoss.keepOutRegions,
          BorderRelinkLoss.materialization,
        ],
      );
      expect(
        () => applyBorderFeatureRelinkPreview(map, preview: preview),
        throwsStateError,
      );

      final reset = applyBorderFeatureFamilyReset(map, preview: preview);
      final applied = _featureOf(reset);
      expect(applied.id, sourceFeature.id);
      expect(applied.name, sourceFeature.name);
      expect(applied.seed, sourceFeature.seed);
      expect(applied.blueprintId, 'organic-target');
      expect(applied.geometry, isA<BorderRegionGeometry>());
      final region = applied.geometry as BorderRegionGeometry;
      expect((region.width, region.height), (8, 8));
      expect(region.cells, everyElement(isFalse));
      expect(applied.paramsOverride, isNull);
      expect(applied.overrides, isEmpty);
      expect(applied.keepOutRegions, isEmpty);
      expect(applied.materialization, isNull);
      expect(reset.layers[1], same(map.layers[1]));
    });

    test('optimistic fingerprint conflict leaves the map unchanged', () {
      final sourceRequest = MasonryLineFixture().request;
      final map = _mapWith(sourceRequest.feature);
      final targetFixture = PostAndRailLineFixture(
        mapSize: map.size,
        geometry: sourceRequest.feature.geometry,
      );
      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: sourceRequest.feature.id,
        targetBlueprintId: 'fence-target',
        targetBlueprintRevision: targetFixture.request.blueprintRevision!,
        visualSnapshots: targetFixture.request.visualSnapshots,
        tileSizePx: targetFixture.request.tileSizePx,
        resolverVersion: targetFixture.request.resolverVersion,
      );
      final changed = updateBorderFeatureSeed(
        map,
        layerId: 'border',
        featureId: sourceRequest.feature.id,
        seed: BorderSignedInt64.fromInt(999),
      );

      expect(
        applyBorderFeatureRelinkPreview(changed, preview: preview),
        same(changed),
      );
    });

    test('region-to-line reset is explicit and fingerprint protected', () {
      final regionFeature = BorderFeature(
        id: 'region-feature',
        name: 'Coast',
        blueprintId: 'old-organic',
        seed: BorderSignedInt64.fromInt(77),
        geometry: BorderRegionGeometry(
          width: 8,
          height: 8,
          cells: <bool>[true, ...List<bool>.filled(63, false)],
        ),
        overrides: const <BorderSlotOverride>[],
        keepOutRegions: const <BorderKeepOutRegion>[],
      );
      final map = _mapWith(regionFeature);
      final target = MasonryLineFixture().request;
      final preview = prepareBorderFeatureRelink(
        map: map,
        layerId: 'border',
        featureId: regionFeature.id,
        targetBlueprintId: 'new-masonry',
        targetBlueprintRevision: target.blueprintRevision!,
        visualSnapshots: target.visualSnapshots,
        tileSizePx: target.tileSizePx,
        resolverVersion: target.resolverVersion,
      );

      expect(preview.kind, BorderRelinkKind.requiresFamilyReset);
      expect(preview.losses, <BorderRelinkLoss>[BorderRelinkLoss.geometry]);
      final applied = applyBorderFeatureFamilyReset(map, preview: preview);
      final geometry = _featureOf(applied).geometry as BorderStrokeGeometry;
      expect(geometry.strokes, isEmpty);

      final conflicted = updateBorderFeatureSeed(
        map,
        layerId: 'border',
        featureId: regionFeature.id,
        seed: BorderSignedInt64.fromInt(78),
      );
      expect(
        applyBorderFeatureFamilyReset(conflicted, preview: preview),
        same(conflicted),
      );
    });

    test('same blueprint is rejected before a misleading preview is built', () {
      final sourceRequest = MasonryLineFixture().request;
      final map = _mapWith(sourceRequest.feature);

      expect(
        () => prepareBorderFeatureRelink(
          map: map,
          layerId: 'border',
          featureId: sourceRequest.feature.id,
          targetBlueprintId: sourceRequest.feature.blueprintId,
          targetBlueprintRevision: sourceRequest.blueprintRevision!,
          visualSnapshots: sourceRequest.visualSnapshots,
          tileSizePx: sourceRequest.tileSizePx,
          resolverVersion: sourceRequest.resolverVersion,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

MapData _mapWith(BorderFeature feature) => MapData(
      id: 'relink-map',
      name: 'Relink map',
      size: const GridSize(width: 8, height: 8),
      version: ProjectVersion.v2,
      layers: <MapLayer>[
        MapLayer.border(
          id: 'border',
          name: 'Borders',
          content: BorderLayerContent(features: <BorderFeature>[feature]),
        ),
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(64, false),
        ),
      ],
    );

BorderFeature _copyFeature(
  BorderFeature source, {
  String? blueprintId,
  BorderMaterialization? materialization,
}) =>
    BorderFeature(
      id: source.id,
      name: source.name,
      blueprintId: blueprintId ?? source.blueprintId,
      seed: source.seed,
      geometry: source.geometry,
      paramsOverride: source.paramsOverride,
      overrides: source.overrides,
      keepOutRegions: source.keepOutRegions,
      materialization: materialization ?? source.materialization,
    );

BorderFeature _featureOf(MapData map) =>
    (map.layers.first as BorderLayer).content.features.single;

BorderBlueprintRevision _organicRevision() => BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: 'Organic target',
        previewSeed: BorderSignedInt64.zero,
        template: BorderBlueprintTemplate.organicEdge,
        primitives: const <BorderPublishedPrimitive>[],
        defaults: masonryParameters(),
        sortOrder: 0,
      ),
    );
```

### `packages/map_editor/test/border_map_editing/border_resize_editor_integration_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/use_case_providers.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_preview_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('ResizeMapUseCase returns the atomic Border-aware result', () {
    final source = _borderMap();

    final result = ResizeMapUseCase().execute(
      source,
      2,
      1,
      tileSizePx: const GridSize(width: 24, height: 20),
    );

    expect(result.canApply, isTrue);
    expect(result.map, isNotNull);
    expect(result.map!.size, const GridSize(width: 2, height: 1));
    expect(
      result.diagnosticReport.diagnostics.map((value) => value.code),
      contains('region_cell_clipped'),
    );
    expect(source.size, const GridSize(width: 3, height: 1));
    expect(
      (source.layers
              .whereType<BorderLayer>()
              .single
              .content
              .features
              .single
              .geometry as BorderRegionGeometry)
          .width,
      3,
    );
  });

  test(
      'resizeActiveMap commits once, uses project tile size, and binds feedback to the new map',
      () async {
    final useCase = _RecordingResizeMapUseCase();
    final container = ProviderContainer(
      overrides: <Override>[
        resizeMapUseCaseProvider.overrideWith((ref) => useCase),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = _borderMap();
    notifier.state = EditorState(
      project: _project(tileWidth: 24, tileHeight: 20),
      activeMap: source,
      activeLayerId: 'borders',
      hoveredTile: const GridPos(x: 2, y: 0),
    );

    await notifier.resizeActiveMap(2, 1);

    final resized = notifier.state.activeMap!;
    expect(useCase.receivedTileSize, const GridSize(width: 24, height: 20));
    expect(resized, isNot(same(source)));
    expect(resized.size, const GridSize(width: 2, height: 1));
    expect(notifier.state.mapUndoStack, hasLength(1));
    expect(notifier.state.mapUndoStack.single.map, same(source));
    expect(notifier.state.hoveredTile, isNull);

    final feedback = container.read(borderResizeFeedbackProvider);
    expect(feedback, isNotNull);
    expect(feedback!.mapIdentity, same(resized));
    expect(feedback.appliesTo(resized), isTrue);
    expect(
      feedback.diagnosticReport.diagnostics.map((value) => value.code),
      contains('region_cell_clipped'),
    );

    final collision = resized.layers.whereType<CollisionLayer>().single;
    expect(collision.collisions, const <bool>[true, false]);
    expect(resized.layers.whereType<CollisionLayer>(), hasLength(1));
    expect(
      resized.layers
          .whereType<BorderLayer>()
          .single
          .content
          .features
          .single
          .materialization,
      isNull,
      reason: 'resize must not synthesize runtime or collision output',
    );
  });

  test('resizeActiveMap rejects Border errors without mutation or history',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final malformed = _borderMap(regionWidth: 2);
    notifier.state = EditorState(
      project: _project(),
      activeMap: malformed,
      activeLayerId: 'borders',
    );
    container.read(borderResizeFeedbackProvider.notifier).state =
        _staleFeedback(malformed);

    await notifier.resizeActiveMap(2, 1);

    expect(notifier.state.activeMap, same(malformed));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.errorMessage, contains('1'));
    final feedback = container.read(borderResizeFeedbackProvider);
    expect(feedback, isNotNull);
    expect(feedback!.appliesTo(malformed), isTrue);
    expect(feedback.diagnosticReport.hasErrors, isTrue);
    expect(
      feedback.diagnosticReport.diagnostics.map((value) => value.code),
      contains('region_size_mismatch'),
    );
  });

  test('resizeActiveMap refuses to guess Border tile size without a project',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = _borderMap();
    notifier.state = EditorState(
      activeMap: source,
      activeLayerId: 'borders',
    );

    await notifier.resizeActiveMap(2, 1);

    expect(notifier.state.activeMap, same(source));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.errorMessage, contains('réglages de tuile'));
    expect(container.read(borderResizeFeedbackProvider), isNull);
  });

  test('resizeActiveMap treats same-size resize as a history-free no-op',
      () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(editorNotifierProvider.notifier);
    final source = _borderMap();
    notifier.state = EditorState(
      project: _project(),
      activeMap: source,
      activeLayerId: 'borders',
    );
    container.read(borderResizeFeedbackProvider.notifier).state =
        _staleFeedback(source);

    await notifier.resizeActiveMap(3, 1);

    expect(notifier.state.activeMap, same(source));
    expect(notifier.state.mapUndoStack, isEmpty);
    expect(notifier.state.statusMessage, contains('déjà'));
    expect(container.read(borderResizeFeedbackProvider), isNull);
  });
}

final class _RecordingResizeMapUseCase extends ResizeMapUseCase {
  GridSize? receivedTileSize;

  @override
  MapResizeWithBorderDiagnosticsResult execute(
    MapData map,
    int width,
    int height, {
    required GridSize tileSizePx,
  }) {
    receivedTileSize = tileSizePx;
    return super.execute(
      map,
      width,
      height,
      tileSizePx: tileSizePx,
    );
  }
}

ProjectManifest _project({int tileWidth = 16, int tileHeight = 16}) =>
    ProjectManifest(
      name: 'Resize project',
      version: ProjectVersion.v2,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      settings: ProjectSettings(
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      ),
    );

MapData _borderMap({int regionWidth = 3}) => MapData(
      id: 'map',
      name: 'Border resize map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 3, height: 1),
      layers: <MapLayer>[
        const MapLayer.collision(
          id: 'collision',
          name: 'Collisions',
          collisions: <bool>[true, false, true],
        ),
        MapLayer.border(
          id: 'borders',
          name: 'Bordures',
          content: BorderLayerContent(
            features: <BorderFeature>[
              BorderFeature(
                id: 'coast',
                name: 'Côte',
                blueprintId: 'coast-blueprint',
                seed: BorderSignedInt64.zero,
                geometry: BorderRegionGeometry(
                  width: regionWidth,
                  height: 1,
                  cells: regionWidth == 3
                      ? const <bool>[false, false, true]
                      : const <bool>[false, false],
                ),
                overrides: const <BorderSlotOverride>[],
                keepOutRegions: const <BorderKeepOutRegion>[],
              ),
            ],
          ),
        ),
      ],
    );

BorderResizeFeedback _staleFeedback(MapData map) => BorderResizeFeedback(
      mapIdentity: map,
      diagnosticReport: BorderDiagnosticsReport(
        diagnostics: <BorderDiagnostic>[
          BorderDiagnostic(
            code: 'region_cell_clipped',
            severity: BorderDiagnosticSeverity.warning,
            phase: BorderDiagnosticPhase.resize,
            scope: BorderDiagnosticScope.geometry,
            featureId: 'coast',
            suggestedAction: 'border.resize.review_clipped_cells',
          ),
        ],
      ),
    );
```
