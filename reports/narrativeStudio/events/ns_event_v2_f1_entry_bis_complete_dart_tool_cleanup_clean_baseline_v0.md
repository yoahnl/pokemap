# NS-EVENT-V2 - F1-ENTRY-BIS - Complete Tracked .dart_tool Cleanup & Clean Baseline Validation V0

## 1. Résumé exécutif

```text
F1-ENTRY-BIS : BLOCKED

Tracked artifacts discovered : 3
Tracked artifact deletions prepared : PASS
Deleted paths exact : PASS
Ignore rules changed : NO
Ignore rules effective : PASS
pubspec.lock changed : NO
pubspec.lock preserved : PASS

Clean map_core : PASS
Clean map_gameplay : PASS
Clean map_runtime : BLOCKED
Clean runtime host : PASS
macOS build : PASS

Previous 45 runtime failures : INCONCLUSIVE

Functional Event V2 code modified : NO
Selbrume data modified by this lot : NO
Dependencies intentionally changed : NO
Build runner executed : NO
Git index modified : NO
Git commit created : NO

Phase F1 : BLOCKED
Phase F2 : NOT READY
```

Le nettoyage repository demandé est correctement préparé : les trois artefacts
suivis sont absents du filesystem, les règles d'ignore et le lockfile sont
inchangés, et l'index Git n'a pas été écrit. La baseline propre ne ferme
toutefois pas le gate : la suite complète `map_runtime` termine avec 1 609
tests réussis, 1 ignoré et 17 échecs. Le critère normatif interdit donc
`CLOSED` et interdit aussi `READY AFTER USER COMMIT`.

## 2. Baseline

```text
Repository : /Users/karim/Project/pokemonProject
Branch : main
Baseline SHA : 07f566fa478eb64418df448e148b5799ee992a55
Baseline subject : docs(event-v2): report NS-EVENT-V2 F1-ENTRY blocker
Functional parent : 7ad2351c6892e8386c9f412cb340f11f3d732a51
Functional parent subject : feat(event-v2): close NS-EVENT-V2 F1-PREREQ
```

L'archive de validation représente exactement `07f566fa`, avec uniquement le
dossier suivi `packages/map_gameplay/.dart_tool` retiré dans l'archive. Aucun
drift local n'a été injecté.

## 3. Blocker F1-ENTRY repris

Le rapport historique
`reports/narrativeStudio/events/ns_event_v2_f1_entry_repository_hygiene_clean_baseline_v0.md`
est conservé sans modification. Il avait correctement arrêté F1-ENTRY parce
que l'hypothèse de deux artefacts était fausse : un troisième fichier suivi,
le snapshot binaire du runner Dart, existait également.

Ce bis reprend donc exactement trois artefacts et ne reprend aucun contrat
fonctionnel fermé par F1-PREREQ.

## 4. Nuance Git index/worktree

Les suppressions sont uniquement des suppressions filesystem. L'état final
pré-commit attendu est ` D` dans le worktree, pas `D ` dans l'index.

```text
HEAD/index : les trois chemins restent suivis.
Worktree   : les trois fichiers sont absents.
Index      : inchangé; git diff --cached est vide.
```

Ainsi, `git ls-files` continue légitimement à lister les trois chemins jusqu'au
futur commit utilisateur. La preuve correcte avant commit est
`git ls-files --deleted`, qui retourne exactement les trois chemins.

## 5. Gate 0 exact

Le Gate 0 a été exécuté avant suppression.

```bash
pwd
git branch --show-current
git status --short --untracked-files=all
git diff --stat
git diff --name-only
git diff --name-status
git diff --check
git log --oneline -n 15
```

Sorties :

````text
/Users/karim/Project/pokemonProject
main

git status --short --untracked-files=all
<empty>

git diff --stat
<empty>

git diff --name-only
<empty>

git diff --name-status
<empty>

git diff --check
<empty>

07f566fa docs(event-v2): report NS-EVENT-V2 F1-ENTRY blocker
7ad2351c feat(event-v2): close NS-EVENT-V2 F1-PREREQ
a2ee6bbd docs(event-v2): report NS-EVENT-V2 Phase F1 blocker
5bf62901 feat(event-v2): close NS-EVENT-V2 Phase E-bis
5d920469 feat(event-v2): complete NS-EVENT-V2 Phase E
e932d9a2 feat(event-v2): enhance migration plan with context validation and strict JSON parsing
025bf9bc feat(event-v2): complete NS-EVENT-V2 Phase D
39a9f7bb ```text feat(selbrume): add forest layer to map bourg selbrume ```
56fd6342 feat(editor): use dropdown for layer creation type
85008b90 feat(selbrume): add terrain layer and update paths in map bourg selbrume
1fc32b4f feat(editor): allow confirmed bulk deletion of map layers and update selbrume project assets
e0e4876e test(editor): add smoke test for terrain preset dropdown menus
02de2ffe feat(editor): add design-system dropdown field
816671f7 feat: refine Port des Brisants visuals and editor controls
928cccae test(selbrume): add Port des Brisants visual refinement tests
````

Inventaire suivi exact au Gate 0 :

```text
packages/map_gameplay/.dart_tool/package_config.json
packages/map_gameplay/.dart_tool/package_graph.json
packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot
```

`git ls-files -s` :

```text
100644 3424753b5da896eeb2200c6c094edd6b046aaa74 0 packages/map_gameplay/.dart_tool/package_config.json
100644 d475e0bf48e4a4126516ee6bb1913b68bd0a7945 0 packages/map_gameplay/.dart_tool/package_graph.json
100644 a71b31997bb1b6055a9c620afd942c099603283e 0 packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot
```

Aucune condition STOP initiale n'était présente.

## 6. Drifts concurrents

Le worktree était entièrement propre au Gate 0. Il n'existait donc aucun drift
préexistant ou concurrent à préserver ou à autoriser dans le Gate final. Les
anciens drifts `map_editor`/Selbrume observés par F1-ENTRY n'étaient plus
présents et ne sont pas repris comme exceptions.

## 7. Inventaire des trois artefacts

| Chemin | Taille | SHA-256 | Type | Blob |
|---|---:|---|---|---|
| `packages/map_gameplay/.dart_tool/package_config.json` | 9 957 octets | `3d83ef811cee2c52ebdf49cf7ca406d325f3a4f232784b4cd1ef80dba684594f` | JSON | `3424753b5da896eeb2200c6c094edd6b046aaa74` |
| `packages/map_gameplay/.dart_tool/package_graph.json` | 8 835 octets | `4d8e2ee0797190710451311ee78b57643fa34bed147093c68c6ab852b879f62d` | JSON | `d475e0bf48e4a4126516ee6bb1913b68bd0a7945` |
| `packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot` | 25 421 840 octets | `9291e482842b3d7f995346c8efee360f51c4e62c7b6d106c1109d4680f13493f` | données binaires | `a71b31997bb1b6055a9c620afd942c099603283e` |

Total supprimé du filesystem : 25 440 632 octets. Aucun quatrième chemin
`.dart_tool` n'est suivi.

## 8. Ignore rules

Les règles existantes ont été contrôlées :

```text
.gitignore:17                      **/.dart_tool/
.gitignore:25                      .dart_tool/
packages/map_gameplay/.gitignore:1 .dart_tool/
```

`git check-ignore --no-index -v` associe les trois chemins à la règle package.
Les diffs de `.gitignore` et `packages/map_gameplay/.gitignore` sont vides.
Verdict : règles inchangées et effectives, `PASS`.

## 9. Cleanup filesystem

Commande exécutée après PASS du Gate 0 :

```bash
rm -f \
  packages/map_gameplay/.dart_tool/package_config.json \
  packages/map_gameplay/.dart_tool/package_graph.json \
  packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot
```

Les trois `test ! -e` passent. Le dossier `.dart_tool` entier n'a pas été
supprimé : cinq autres fichiers locaux ignorés sont restés hors diff et hors
scope.

## 10. Suppressions préparées pour commit utilisateur

```text
 D packages/map_gameplay/.dart_tool/package_config.json
 D packages/map_gameplay/.dart_tool/package_graph.json
 D packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot
```

`git ls-files --deleted -- packages/map_gameplay/.dart_tool` retourne
exactement ces trois chemins. `git diff --cached --name-status` est vide.
Les suppressions sont préparées dans le worktree pour le futur commit
utilisateur; elles ne sont pas encore retirées de HEAD ni de l'index.

## 11. Lockfile

`packages/map_gameplay/pubspec.lock` reste présent, suivi et inchangé.

```text
Taille : 12 248 octets
Blob : 852a94450a6ee51f2aa20683fa19f43184d3de12
SHA-256 : ef1601ab55e8a3361fceb8c4d19071c752bccfc12f345190816f4afd4dbaaac5
git diff -- packages/map_gameplay/pubspec.lock : <empty>
```

Dans l'archive, `dart pub get` a conservé le lockfile byte-identique
(`cmp` exit 0 et même SHA-256). Aucun lockfile n'a été recopié.

## 12. MCP Dart

Le MCP Dart n'était pas disponible dans les outils de cette session. Aucun
usage MCP fictif n'est revendiqué. Les validations ont utilisé les exécutables
Dart/Flutter locaux et le filesystem.

## 13. Sous-agents et incidents

Quatre sous-agents spécialisés et l'orchestrateur principal ont été utilisés :

| Rôle | Travail | Verdict |
|---|---|---|
| Agent A - Exact Cleanup | inventaire, hashes, ignores, suppression et contrôle Git | PASS |
| Agent B - Core & Gameplay Baseline | suites complètes dans l'archive | PASS |
| Agent C - Runtime & Host Baseline | runtime complet, host complet, analyze et build | BLOCKED sur runtime; host/build PASS |
| Agent D - Scope & Evidence | comparaison Gate 0/final, lockfile, anti-faux-PASS | BLOCKED global conforme |
| Orchestrateur | Gate 0, archive, consolidation, nettoyage et rapport | PASS d'exécution |

Aucun timeout, Bad Request ou worker interrompu n'a réduit les critères. Agent
D n'avait pas accès à un transcript brut autonome du Gate 0 et l'a signalé
`PARTIAL`; l'orchestrateur avait capturé les sorties exactes ci-dessus avant
toute suppression. Aucun agent n'a écrit l'index Git ni lancé `build_runner`.

Les deux reviewers contradictoires sont documentés aux sections 26 et 27.

## 14. Méthode archive propre

```bash
BASELINE_SHA="07f566fa478eb64418df448e148b5799ee992a55"
BASELINE_DIR="$(mktemp -d -t pokemap-f1-entry-bis.XXXXXXXXXX)"
git archive "$BASELINE_SHA" | tar -x -C "$BASELINE_DIR"
rm -rf "$BASELINE_DIR/packages/map_gameplay/.dart_tool"
```

Archive utilisée :

```text
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/pokemap-f1-entry-bis.ZQw8OteFhh
```

Le chemin était non vide, extérieur au repository, différent de `/`, et les
quatre `pubspec.yaml` requis ainsi que le lockfile gameplay étaient présents.
`find "$BASELINE_DIR" -path '*/.dart_tool/*' -print` était vide avant
validation. Les `pub get` ont ensuite recréé des caches uniquement dans cette
archive.

## 15. map_core complet

Version :

```text
Dart SDK version: 3.12.1 (stable) (Tue May 26 01:02:21 2026 -0700) on "macos_arm64"
```

| Commande | Exit | Durée | Résultat |
|---|---:|---:|---|
| `dart pub get` | 0 | 0,666 s | `Changed 73 dependencies!` dans l'archive |
| `dart test --reporter=compact` | 0 | 16,438 s | `00:12 +2955: All tests passed!` |
| `dart analyze` | 0 | 3,916 s | `No issues found!` |

Le `pub get` signale 20 packages plus récents incompatibles avec les contraintes,
sans échec ni modification du repository principal. Verdict `PASS`.

## 16. map_gameplay complet

| Commande | Exit | Durée | Résultat |
|---|---:|---:|---|
| `dart pub get` | 0 | 0,128 s | `Got dependencies!` |
| `dart pub deps` | 0 | 0,055 s | arbre complet produit |
| `dart test --reporter=compact` | 0 | 5,026 s | `00:02 +245: All tests passed!` |
| `dart analyze` | 0 | 1,530 s | `No issues found!` |

Après `pub get`, `.dart_tool/package_config.json` existe uniquement dans
l'archive, est un JSON version 2 avec 54 packages, et mesure 9 957 octets.
Résolution vérifiée :

```text
map_gameplay -> map_core -> uuid 4.5.3 -> fixnum 1.1.1
uuid   : transitive, hosted pub.dev, language 3.0
fixnum : transitive, hosted pub.dev, language 3.1
```

Le lockfile de l'archive est byte-identique avant/après. Le `pub get` signale
11 packages plus récents incompatibles avec les contraintes. Verdict `PASS`.

## 17. map_runtime complet

Version :

```text
Flutter 3.46.0-0.3.pre, channel beta, revision 677d472756
Engine 0ea68a0ce37b911029779bab0917a1375bfde69c
Dart 3.13.0-167.1.beta
DevTools 2.59.0
```

| Commande | Exit | Durée | Résultat |
|---|---:|---:|---|
| `flutter pub get` | 0 | 1 s | dépendances résolues; 15 contraintes avec versions plus récentes |
| `flutter test --reporter=compact` | 1 | 48 s | `00:44 +1609 ~1 -17: Some tests failed.` |
| `flutter analyze --no-fatal-infos` | 0 | 16 s | 348 infos, 0 warning, 0 erreur |

La suite complète, et non un sous-ensemble, a été exécutée. Les 17 échecs
touchent sept fichiers :

1. `selbrume_map_catalog_integrity_test.dart`, 3 : placement
   `pe_port_nid_goelise` absent dans deux contrats; Bourg expose
   `selbrume_objectif` au lieu d'un `tilesetId` vide.
2. `p6_selbrume_first_trainer_battle_golden_slice_test.dart`, 1 :
   `dratini` est présent là où `metapod` est attendu.
3. `selbrume_map_navigation_contract_test.dart`, 3 : ancre Port non connectée,
   cellule Bourg `(26,54)` passable, et aucune paire de bordures alignées entre
   Bourg sud et Port.
4. `selbrume_asset_integrity_contract_test.dart`, 4 :
   `ts_selbrume_open_sea_loop` absent avec null-check associé, atlas Port
   `1536x2368x4` au lieu de `1536x1408x4`, et atlas Bourg ambigu.
5. `p6_selbrume_beta_validator_pass_test.dart`, 1 : même divergence
   `dratini`/`metapod`.
6. `selbrume_map_render_smoke_test.dart`, 2 : position Port `(0,21)` au lieu
   de `(0,22)`; atlas Bourg `selbrum_maison_1` absent.
7. `selbrume_port_visual_invariants_test.dart`, 3 : eau/trou transparent en
   `(44,25)` et 1 374 pixels transparents dans `c1_full_map`.

Les 348 diagnostics analyze sont uniquement des informations :
319 `prefer_const_constructors`, 12 imports relatifs, 11 déclarations const,
5 identifiants locaux et 1 API dépréciée. Verdict runtime `BLOCKED`.

## 18. Reclassification des 45 anciens échecs

F1-PREREQ avait observé 45 erreurs qui échouaient toutes au chargement avec :

```text
Invalid argument(s): v2 is not one of the supported values: v1
```

Dans l'archive propre :

```text
Ancienne signature de cause : 0 occurrence
Validations du manifeste Selbrume réussies : 139 occurrences
Anciens noms documentés : 45
Échecs actuels : 17
Chevauchement exact de noms : 11
Anciens noms non rouges maintenant : 34
Nouveaux noms rouges : 6
```

La cause de chargement commune aux 45 ne se reproduit donc pas. Cependant,
11 noms restent rouges pour des divergences de données/contrats, 32 autres ne
sont plus rouges, et les deux anciens `setUpAll` passent mais exposent six
échecs enfants nouveaux. Le total de la suite a aussi évolué, de 1 605 à
1 627 résultats, ce qui empêche une comparaison agrégée strictement un-à-un.

Le prompt n'autorise `WORKTREE CONTAMINATION PROVEN` que si la suite complète
propre est verte. Elle ne l'est pas. Les mêmes 45 échecs ne se reproduisent pas
non plus, donc `CLEAN BASELINE FAILURE PROVEN` ne décrit pas ces 45.

```text
Previous 45 runtime failures : INCONCLUSIVE
```

Indépendamment de cette reclassification, une baseline propre rouge avec 17
échecs est bien prouvée.

## 19. Runtime host complet

Inventaire frais des 20 fichiers :

```text
test/in_game_menu_test.dart
test/p3_narrative_smoke_slice_test.dart
test/p5_runtime_project_disk_smoke_test.dart
test/phase_a_golden_slice_launch_test.dart
test/project_loader_page_test.dart
test/runtime_battle_command_overlay_visibility_test.dart
test/runtime_demo_party_seed_test.dart
test/runtime_gamepad_bridge_test.dart
test/runtime_gamepad_presence_test.dart
test/runtime_ios_controller_bridge_test.dart
test/runtime_ios_project_picker_test.dart
test/runtime_launch_save_test.dart
test/runtime_party_builder_test.dart
test/runtime_pokedex_loader_test.dart
test/runtime_project_picker_test.dart
test/runtime_projects_directory_test.dart
test/runtime_touch_controls_test.dart
test/runtime_touch_controls_visibility_test.dart
test/runtime_touch_input_driver_test.dart
test/widget_test.dart
```

| Commande | Exit | Durée | Résultat |
|---|---:|---:|---|
| `flutter pub get` | 0 | 1 s | dépendances résolues |
| `find test -maxdepth 3 -type f -name '*test.dart' \| sort` | 0 | 0 s | 20 fichiers |
| `flutter test --reporter=compact` | 0 | 15 s | `00:12 +48: All tests passed!` |
| `flutter analyze --no-fatal-infos` | 0 | 5 s | 1 info, 0 warning, 0 erreur |

L'unique diagnostic analyze est `prefer_const_constructors`. Verdict host
`PASS`.

## 20. Build macOS

Commande exécutée dans l'archive :

```bash
flutter build macos --debug
```

Résultat :

```text
Exit : 0
Durée : 31 s
Ligne finale : ✓ Built build/macos/Build/Products/Debug/playable_runtime_host.app
Chemin produit :
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/pokemap-f1-entry-bis.ZQw8OteFhh/examples/playable_runtime_host/build/macos/Build/Products/Debug/playable_runtime_host.app
Taille observée avant nettoyage : 163M
```

Warnings non bloquants : API `allowedFileTypes` dépréciée dans
`file_selector_macos`, enfant `1024.png` non assigné dans `AppIcon`, et phase
`Run Script` sans outputs déclarés. Le build a été supprimé avec l'archive.
Verdict build `PASS`.

## 21. Pollution check du worktree principal

Après tous les `pub get`, tests, analyses et le build exécutés en archive :

```text
 D packages/map_gameplay/.dart_tool/package_config.json
 D packages/map_gameplay/.dart_tool/package_graph.json
 D packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot
```

`git diff --check` est vide. Aucun cache, lockfile, build, code, test, asset ou
donnée Selbrume supplémentaire n'est apparu dans le repository principal.
Verdict pollution `PASS`.

## 22. Nettoyage archive temporaire

Après capture des preuves, le chemin a été revalidé comme non vide, extérieur
au repository et différent de `/`, puis supprimé :

```text
Temporary archive removed : PASS
Removed path :
/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/pokemap-f1-entry-bis.ZQw8OteFhh
test ! -e "$BASELINE_DIR" : PASS
```

## 23. Fichiers créés/modifiés/supprimés

Créé :

```text
reports/narrativeStudio/events/ns_event_v2_f1_entry_bis_complete_dart_tool_cleanup_clean_baseline_v0.md
```

Supprimés du filesystem et préparés pour le commit utilisateur :

```text
packages/map_gameplay/.dart_tool/package_config.json
packages/map_gameplay/.dart_tool/package_graph.json
packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot
```

Modifiés : aucun fichier. Aucun code, test, fixture, dépendance, lockfile,
`.gitignore`, projet Selbrume ou roadmap n'a été modifié.

Ce rapport est l'unique fichier créé. Son contenu complet est le présent
document; l'imbriquer intégralement en lui-même produirait une récursion sans
fin. Les trois autres changements sont des suppressions binaires/JSON, donc
n'ont pas de contenu final à reproduire.

## 24. Gate Git final

Une première capture a été faite avant les reviews. Après intégration des
findings R1 et R2, le Gate Git final a été relancé. Les sorties vérifiées sont :

```text
git status --short --untracked-files=all
 D packages/map_gameplay/.dart_tool/package_config.json
 D packages/map_gameplay/.dart_tool/package_graph.json
 D packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot
?? reports/narrativeStudio/events/ns_event_v2_f1_entry_bis_complete_dart_tool_cleanup_clean_baseline_v0.md

git diff --stat
 .../map_gameplay/.dart_tool/package_config.json    | 332 --------------
 .../map_gameplay/.dart_tool/package_graph.json     | 490 ---------------------
 .../pub/bin/test/test.dart-3.11.4.snapshot         | Bin 25421840 -> 0 bytes
 3 files changed, 822 deletions(-)

git diff --name-only
packages/map_gameplay/.dart_tool/package_config.json
packages/map_gameplay/.dart_tool/package_graph.json
packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot

git diff --name-status
D	packages/map_gameplay/.dart_tool/package_config.json
D	packages/map_gameplay/.dart_tool/package_graph.json
D	packages/map_gameplay/.dart_tool/pub/bin/test/test.dart-3.11.4.snapshot

git diff --check
<empty>

git diff --cached --name-status
<empty>
```

`git ls-files --deleted -- packages/map_gameplay/.dart_tool` et le diff
`--name-status` limité à ce dossier retournent exactement les trois chemins.
Les diffs lockfile et ignores sont vides. `git ls-files` normal continue de
les lister, ce qui est attendu avant commit.

## 25. Scope final

L'anti-scope demandé est vide pour :

```text
packages/map_core
packages/map_gameplay/lib
packages/map_gameplay/test
packages/map_gameplay/pubspec.yaml
packages/map_runtime
packages/map_editor
packages/map_battle
examples/playable_runtime_host
selbrume
assets
```

Non-objectifs respectés : aucune fonctionnalité Event V2, aucun changement de
contrat, aucune roadmap, aucun `build_runner`, aucun nettoyage de cache
supplémentaire, aucune commande Git d'écriture.

`codex_rule.md` demande normalement des commentaires et des tests modifiés.
La spécification directe de ce lot interdit explicitement tout fichier de code
ou test et n'autorise que trois suppressions et ce rapport. La règle la plus
spécifique et la plus stricte a donc été suivie; les suites existantes complètes
ont servi de preuve sans modifier leurs sources.

## 26. Review R1

Première passe R1 : `BLOCKER documentaire` uniquement.

R1 a confirmé : exactement trois artefacts suivis/supprimés du worktree, aucun
quatrième, index vide, ignores inchangés, lockfile conservé, archive absente,
anti-scope vide et aucun cache/build nouveau dans le repository principal.

Findings :

1. les sections R1/R2 étaient encore `PENDING` alors que le Gate se disait
   postérieur aux reviews;
2. la sortie `git diff --stat` manquait dans la transcription finale.

Corrections intégrées : chronologie réécrite, findings des deux reviews
consignés et sortie `git diff --stat` ajoutée. La re-review a confirmé les
trois suppressions exactes, l'index vide, les ignores et le lockfile inchangés,
l'anti-scope vide et l'archive absente.

Verdict final R1 : `PASS`.

## 27. Review R2

Première passe R2 : `BLOCKER documentaire` uniquement.

R2 n'a détecté aucun faux PASS technique : suites fraîches et complètes,
runtime correctement rouge, classification `INCONCLUSIVE` des 45 anciens
échecs, host complet, build exécuté, et statuts F1-ENTRY-BIS/F1 `BLOCKED`.

Le seul finding était la chronologie prématurée du Gate final alors que les
reviews étaient encore `PENDING`. La chronologie a été corrigée et le Gate Git
final relancé après intégration des reviews. La re-review n'a trouvé aucun
blocker restant sur la vérité des validations.

Verdict final R2 : `PASS`.

## 28. Risques résiduels

1. La baseline `map_runtime` a 17 tests rouges sur des contrats/données
   Selbrume; aucune reprise F1 ne peut être autorisée tant que ce gate n'est pas
   traité par un lot séparé.
2. La cause de chargement commune aux 45 anciens échecs a disparu, mais le
   prompt interdit de conclure à la contamination tant que la suite complète
   reste rouge; leur statut demeure `INCONCLUSIVE`.
3. Les trois chemins restent suivis dans HEAD et l'index jusqu'au commit
   utilisateur. Après commit/push, GitHub devra confirmer l'absence de tout
   `.dart_tool` suivi.
4. Cinq fichiers locaux ignorés restent dans le `.dart_tool` principal; ils
   étaient hors allowlist et ne doivent pas être confondus avec des fichiers
   suivis.
5. Les 348 infos analyze runtime, l'info host et les trois warnings build sont
   non bloquants pour la compilation, mais constituent une dette distincte.

Auto-critique : le nettoyage repository lui-même est complet et étroit, mais
ce lot ne peut satisfaire sa mission de baseline verte. Aucun correctif
Selbrume n'a été tenté, conformément au scope; le prochain travail doit d'abord
ratifier ou réaligner les 17 contrats sans les mélanger à F1.

## 29. Gate de reprise F1

```text
Tracked cleanup prepared : PASS
Clean core/gameplay : PASS
Clean runtime host/build : PASS
Clean map_runtime : BLOCKED (17 failures)
User commit prerequisite : NOT REACHED AS SUFFICIENT GATE

Phase F1 : BLOCKED
Phase F2 : NOT READY
```

Prochain lot recommandé, sans l'implémenter :

```text
NS-EVENT-V2 - F1-ENTRY-TER
Selbrume Clean Runtime Baseline Contract Reconciliation V0
```

Ce lot devra décider explicitement si les fixtures Selbrume du commit ou les
17 assertions constituent la source canonique, puis obtenir une suite runtime
complète verte avant de reprendre F1.

## 30. Verdict

```text
F1-ENTRY-BIS : BLOCKED

Tracked .dart_tool deletion prepared : PASS
Exactly three tracked artifacts deleted : PASS
Ignore rules unchanged and effective : PASS
pubspec.lock preserved : PASS

Clean map_core baseline : PASS
Clean map_gameplay baseline : PASS
Clean map_runtime baseline : BLOCKED
Clean runtime host baseline : PASS
macOS build : PASS

Previous 45 runtime failures : INCONCLUSIVE

Phase F1 : BLOCKED
Phase F2 : NOT READY
```

Aucun code fonctionnel, test, projet Selbrume, dépendance, index ou commit Git
n'a été modifié par F1-ENTRY-BIS.
