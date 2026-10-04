# POST-CI-001 — Rétablir les quick checks sans affaiblir les contrôles

Evidence Pack du 30 septembre 2026. Verdict technique : PASS, correction déjà présente, aucune modification de sources nécessaire. Ticket prêt pour TO REVIEW ; DONE reste la décision de Yoahn après revue.

## Résultat et périmètre

Le HEAD local et distant de `main` est `f559e55c6815844ad0e0c08b2ed661733156e703`. Le véritable [run quick checks 36647921551](https://github.com/yoahnl/pokemap/actions/runs/36647921551) sur ce SHA a exécuté Hub, Core, Editor et Studio avec succès. Le parcours local exact du workflow a également réussi avec le SDK CI épinglé : 91 tests réussis, aucun échec, aucun ignoré et quatre analyses sans diagnostic.

Le lint historique est corrigé par le commit préexistant [fbf286ade3b519841a36058e6f10bf73f8b40b2c](https://github.com/yoahnl/pokemap/commit/fbf286ade3b519841a36058e6f10bf73f8b40b2c). Cette intervention n'a changé ni source, ni test, ni dépendance versionnée, ni workflow, ni règle d'analyse. Elle produit uniquement ce rapport et actualise le ticket Notion existant, domaine Systèmes transverses, hors gate bêta.

Pas de commit, push, merge, rebase, tag, release, déclenchement ou relance de CI. Le run existant correspond exactement aux sources finales inchangées. Le rapport seul n'est pas dans les filtres de déclenchement du workflow.

## A. Audit initial

État observé avant toute modification :

```text
git branch --show-current
main

git rev-parse HEAD main
f559e55c6815844ad0e0c08b2ed661733156e703
f559e55c6815844ad0e0c08b2ed661733156e703

git status --short --untracked-files=all
```

La dernière commande n'a produit aucun caractère. `git diff` était également vide. Aucun changement local préexistant. Les lectures intermédiaires et la vérification après les quatre `pub get` sont restées propres. Les remotes `origin` et `github` pointent sur `git@github.com:yoahnl/pokemap.git`. L'API GitHub confirme le même SHA pour `main` ; aucun fetch ou changement de branche n'a été effectué.

Documents lus : `AGENTS.md`, `codex_rule.md`, `skills/README.md`, skills `systematic-debugging` et `verification-before-completion`. Audit du prompt : son hypothèse historique est correctement présentée comme à revérifier. Les obligations génériques de créer des tests et de modifier le code ne justifient aucune mutation lorsque les sources sont déjà corrigées ; la demande explicite de zéro changement inutile prévaut. Le build desktop ne fait pas partie des quick checks. Les validations de compilation apportées par les tests sont décrites séparément d'un build de distribution.

Fichiers et contrats inspectés :

- `.github/workflows/pokemap_quick_checks.yml`, intégralement : installation SDK et quatre blocs de commandes.
- `apps/pokemap_hub/lib/presentation/features/home/widgets/avelune_game_shelf.dart`, notamment import ligne 4 et appel `scrollCacheExtent`.
- `apps/pokemap_hub/test/release/intro_codec_fixture_test.dart`, détection de `ffprobe` et condition de skip.
- Historique des deux fichiers workflow/shelf, correctif `fbf286ade`, comparaison avec `2e1bc223`.
- `analysis_options.yaml` des quatre packages : aucun changement entre la référence et le HEAD dans la comparaison de critique.
- SDK Flutter épinglé, chaîne d'exports de `ScrollCacheExtent`.
- `tools/scripts/check_markdown_hygiene.sh` et rapports antérieurs retrouvant le diagnostic Hub.
- Ticket Notion POST-CI-001 et schéma de son backlog, avant actualisation.

Risques principaux : utiliser le mauvais SDK local, retirer un import nécessaire sur ce SDK différent, confondre un job réussi avec l'exécution de toutes ses étapes, ignorer le skip codec préexistant, modifier des travaux concurrents. Ces points ont été vérifiés explicitement.

### SDK

| Élément | SDK CI utilisé pour les validations | SDK par défaut de la machine, non utilisé pour conclure |
|---|---|---|
| Flutter | `3.48.0-0.4.pre` | `3.47.5` |
| Révision framework | `e3005e3402d9cfa2043114c8bc53c59d12e9b98e` | `6a19cca56475dbfba1478ee68d7bd0c2ef891da1` |
| Dart | `3.14.0 (build 3.14.0-95.2.beta)` | `3.13.4` |
| Racine | `/tmp/avelune-flutter-348` (`/private/tmp/avelune-flutter-348`) | `/opt/homebrew/share/flutter-3.47.5` |

Le SDK CI existait déjà localement. `git -C /tmp/avelune-flutter-348 rev-parse HEAD` et `flutter --version --machine` confirment la révision. Les commandes ont été exécutées avec `/tmp/avelune-flutter-348/bin` en tête du PATH, incluant le `dart` fourni par ce Flutter. Aucun pin ni SDK global modifié. La reproduction préalable `flutter analyze --no-pub lib test/release` dans Hub sort avec 0 et `No issues found! (ran in 7.8s)` : le diagnostic historique n'existe plus au HEAD.

### Runs consultés

| Run | SHA | Conclusion / étapes |
|---|---|---|
| [36506168877](https://github.com/yoahnl/pokemap/actions/runs/36506168877) | `2e1bc223a2c9d958c6c43d45c5d50e04f9f7c495` | FAIL Hub après 11 tests réussis et 1 ignoré ; Core/Editor/Studio skipped |
| [36645024906](https://github.com/yoahnl/pokemap/actions/runs/36645024906) | `94227c2ad773796abe7c00858b5628e4b34061ce` | Même lint Hub, encore rouge le 29 septembre à 23:26:08 UTC |
| [36645290462](https://github.com/yoahnl/pokemap/actions/runs/36645290462) | `fbf286ade3b519841a36058e6f10bf73f8b40b2c` | SUCCESS, les quatre étapes exécutées |
| [36647921551](https://github.com/yoahnl/pokemap/actions/runs/36647921551) | `f559e55c6815844ad0e0c08b2ed661733156e703` | Dernier quick check observé : SUCCESS, les quatre étapes exécutées |

## B. Cause racine et résolution préexistante

Diagnostic extrait du run historique :

```text
🎉 11 tests passed, 1 skipped.
info • The import of 'package:flutter/rendering.dart' is unnecessary because all of the used elements are also provided by the import of 'package:flutter/material.dart'. Try removing the import directive • lib/presentation/features/home/widgets/avelune_game_shelf.dart:4:8 • unnecessary_import
##[error]Process completed with exit code 1.
```

Avec Flutter CI, `material.dart:200` exporte `widgets.dart`, lequel exporte `src/widgets/viewport.dart:184`. Ce dernier exporte `ScrollCacheExtent` depuis `rendering.dart` aux lignes 19–20. L'import direct non préfixé était donc redondant : l'appel non qualifié était également résolu par `material.dart`. Flutter `3.47.5` n'offre pas cette même réexportation dans `viewport.dart:19` ; une suppression guidée par un SDK différent aurait été une mauvaise preuve.

Le commit préexistant `fbf286ade` du 29 septembre à 23:27:17 UTC n'affecte qu'un fichier, avec deux insertions et deux suppressions. Son diff fonctionnel intégral est :

```diff
-import 'package:flutter/rendering.dart' show ScrollCacheExtent;
+import 'package:flutter/rendering.dart' as rendering show ScrollCacheExtent;

-          scrollCacheExtent: ScrollCacheExtent.pixels(
+          scrollCacheExtent: rendering.ScrollCacheExtent.pixels(
```

L'accès qualifié utilise réellement l'import direct. La classe, le constructeur, les arguments et le comportement de cache restent les mêmes. Il n'y a ni ignore, ni règle désactivée, ni interception de code de sortie. L'analyse locale avec le SDK épinglé et les deux runs GitHub verts prouvent sa validité pour la CI. La structure des exports explique également pourquoi conserver l'accès direct est cohérent avec le SDK local différent ; aucune validation complète de ce second SDK n'est revendiquée.

Le workflow comporte un unique job et des steps séquentiels. L'analyse Hub retournait 1 ; les étapes suivantes, soumises à la condition implicite de succès GitHub Actions, étaient donc skipped. Ce n'était pas un défaut de sélection de packages. Le correctif rétablit le parcours sans changer ces garde-fous.

## C. Fichiers créés ou modifiés pendant cette intervention

| Fichier | Action | Raison / zones / impact |
|---|---|---|
| `documentation/reports/ci/post_ci_001_quick_checks_evidence_pack.md` | Créé | Unique rapport demandé ; audit, commandes, preuves, limites, état Git et verdicts |

Aucun fichier de code, test, workflow, configuration ou lockfile créé ou modifié. Il n'y a donc aucun contenu intégral de source modifiée à recopier, ni diff correctif fabriqué. Le diff ci-dessus est explicitement historique. Le présent document est le livrable intégral, directement consultable ; aucun fichier de snapshot des sources n'est créé.

Logs et instrumentation temporaires de validation sont hors dépôt dans `/tmp/post-ci-001-*`. Ils ne sont pas des fichiers produits pour intégration. Les commandes et résultats utiles sont intégralement consignés ci-dessous ; ces logs restent consultables sur cette machine mais ne sont pas des pièces versionnées durables.

## D. Commandes et résultats locaux

Préparation SDK :

```bash
export PATH="/tmp/avelune-flutter-348/bin:$PATH"
git -C /tmp/avelune-flutter-348 rev-parse HEAD
flutter --version --machine
dart --version
```

Les trois lectures de version/révision sortent avec 0. Les lectures du SDK par défaut, de la seconde copie `/tmp/avelune-flutter-3.48`, de l'historique Git, des instructions et des fichiers ont servi à l'audit, pas à remplacer une validation. Aucun checkout SDK réalisé.

Reproduction minimale avant le parcours complet : dans `apps/pokemap_hub`, `flutter analyze --no-pub lib test/release` : exit 0, 9,12 s, aucun diagnostic. Puis commandes exactes, package par package, dans l'ordre Hub → Core → Editor → Studio :

```bash
cd /Users/karim/Project/pokemonProject/apps/pokemap_hub
flutter pub get
flutter test --no-pub --timeout 2m \
  test/release/ci_cost_workflow_test.dart \
  test/release/desktop_platform_release_gate_test.dart \
  test/release/intro_codec_fixture_test.dart \
  test/release/mobile_platform_release_gate_test.dart \
  test/release/performance_observation_workflow_test.dart
flutter analyze --no-pub lib test/release

cd /Users/karim/Project/pokemonProject/packages/map_core
dart pub get
dart test \
  test/gameplay_roadmap_dashboard_test.dart \
  test/gameplay_roadmap_dashboard_cli_test.dart \
  test/gameplay_roadmap_repository_consistency_test.dart
dart analyze \
  lib/src/tooling/gameplay_roadmap_dashboard.dart \
  tool/generate_gameplay_roadmap_dashboard.dart \
  test/gameplay_roadmap_dashboard_test.dart \
  test/gameplay_roadmap_dashboard_cli_test.dart \
  test/gameplay_roadmap_repository_consistency_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter pub get
flutter test --no-pub --timeout 2m \
  test/release/github_distribution_workflow_test.dart \
  test/tileset_grid_metrics_test.dart \
  test/map_editing_controller_test.dart
flutter analyze --no-pub lib test/release

cd /Users/karim/Project/pokemonProject/apps/avelune_studio
flutter pub get
flutter test --no-pub --timeout 2m \
  test/app/studio_bootstrap_test.dart \
  test/home/recent_projects_test.dart \
  test/project_session/scoped_project_session_adapter_test.dart \
  test/presentation/studio_app_test.dart \
  test/map_workspace/map_tool_strip_state_host_test.dart
flutter analyze --no-pub lib
```

| Package / commande | Exit | Durée totale | Résultat exact utile |
|---|---:|---:|---|
| Hub `flutter pub get` | 0 | 1,96 s | Dépendances résolues, état Git inchangé |
| Hub `flutter test` ci-dessus | 0 | 4,47 s | `00:00 +12: All tests passed!` ; 12 réussis / 0 échoué / 0 ignoré |
| Hub `flutter analyze` | 0 | 7,09 s | `No issues found! (ran in 5.9s)` |
| Core `dart pub get` | 0 | 0,85 s | Dépendances résolues, état Git inchangé |
| Core `dart test` ci-dessus | 0 | 26,73 s | `00:25 +33: All tests passed!` ; 33 / 0 / 0 |
| Core `dart analyze` | 0 | 3,41 s | `No issues found!` |
| Editor `flutter pub get` | 0 | 1,68 s | Dépendances résolues, état Git inchangé |
| Editor `flutter test` ci-dessus | 0 | 5,86 s | `00:02 +20: All tests passed!` ; 20 / 0 / 0 |
| Editor `flutter analyze` | 0 | 24,13 s | `No issues found! (ran in 23.0s)` |
| Studio `flutter pub get` | 0 | 1,30 s | Dépendances résolues, état Git inchangé |
| Studio `flutter test` ci-dessus | 0 | 20,50 s | `00:14 +26: All tests passed!` ; 26 / 0 / 0 |
| Studio `flutter analyze` | 0 | 8,33 s | `No issues found! (ran in 7.1s)` |

Journaux locaux : `/tmp/post-ci-001-{hub,core,editor,studio}-{pub-get,test,analyze}.log`, reproduction `/tmp/post-ci-001-hub-repro-analyze.log`. Métadonnées détaillées : `/tmp/post-ci-001-validation-results.json`. Les durées sont celles du processus complet, distinctes des durées affichées par les outils. Les compteurs de tests sont lus dans les sorties finales, aucune extrapolation de couverture.

Le runner et ses descendants ont été suivis par PID, UID, heure de démarrage et commande. Runners tests : Hub 67862, Core 68363, Editor 69082, Studio 70034. Inspection après chaque run : aucun processus descendant résiduel prouvé à terminer, aucun kill effectué, aucune suppression globale de processus. Aucun serveur MCP n'a été arrêté pour ce ticket.

Build : aucune commande `flutter build` lancée. Elle n'est pas appelée par ce workflow et aucun code n'a changé. Les tests Flutter ont compilé et exécuté leurs suites sélectionnées avec le SDK exact ; cela prouve leur compilation, pas un binaire desktop distribuable. Certification, benchmarks et suites complètes non lancés : ils dépassent le signal rapide demandé.

Vérifications finales à la racine, après la création du seul rapport :

```bash
git diff --check
POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh
git status --short --untracked-files=all
git rev-parse HEAD
```

`git diff --check` : exit 0, sortie vide. Hygiène Markdown : exit 0, `Markdown hygiene: 1 new Markdown file(s), all in canonical locations.` Budget explicitement limité au seul Evidence Pack demandé. Aucun fichier source modifié après les validations.

## E. Couverture réelle du workflow

| Étape | Exécutée local / CI | Résultat | Preuve / couverture |
|---|---|---|---|
| Hub | oui / oui | PASS | 12 / 11+1 ignoré ; cinq fichiers de contrats release/CI ; analyse `lib test/release` |
| Core | oui / oui | PASS | 33 / 33 ; trois tests dashboard CLI/cohérence roadmap ; analyse uniquement les cinq chemins listés |
| Editor | oui / oui | PASS | 20 / 20 ; contrat distribution, métriques grille tileset, contrôleur édition ; analyse `lib test/release` |
| Studio | oui / oui | PASS | 26 / 26 ; bootstrap, projets récents, session scoped, app, barre outils map ; analyse `lib` |

Les noms de steps ne constituent pas la preuve : les commandes et logs ci-dessus sont contrôlés. Le workflow n'analyse pas tout Core et ne lance pas toutes les suites des quatre packages. `packages/**` dans un filtre déclencheur ne signifie pas que chaque package est testé. `map_runtime`, `map_gameplay`, `map_battle` et le host ne disposent pas de step dédiée ici.

Configuration inspectée :

- Déclenchement `pull_request` sur chemins filtrés ; `push` sur `main` avec les mêmes filtres.
- Filtres : `apps/pokemap_hub/**`, `apps/avelune_studio/**`, `packages/**`, `examples/playable_runtime_host/**`, `tools/pokemap_product_certification/**`, `.github/workflows/**`.
- Permissions `contents: read`.
- Concurrency `pokemap-quick-${{ github.event.pull_request.number || github.ref }}`, `cancel-in-progress: true`. Une nouvelle exécution du même groupe peut annuler la précédente ; le run retenu est achevé avec succès.
- Job unique `repository-contracts`, Ubuntu `24.04`, timeout 15 minutes. Pas de `needs`, matrice, `if` explicite, `continue-on-error` ni sortie interceptée.
- Checkout action épinglée `11bd71901bbe5b1630ceea73d27597364c9af683`.
- Installation du tag Flutter puis vérification de la révision exacte ; pas de script partagé appelé par les quatre blocs de validation.
- Timeout des tests Flutter inchangé à `2m` ; `dart test` Core sans timeout supplémentaire dans le workflow.
- Diff workflow historique → HEAD : seulement ajout de `test/map_workspace/map_tool_strip_state_host_test.dart`. Aucun retrait de contrôle.

## F. GitHub Actions : preuve au SHA final

[Run 36647921551](https://github.com/yoahnl/pokemap/actions/runs/36647921551), [job 109675108182](https://github.com/yoahnl/pokemap/actions/runs/36647921551/job/109675108182), SHA `f559e55c6815844ad0e0c08b2ed661733156e703`, conclusion `success`. Job du 29 septembre 23:58:05 au 30 septembre 00:01:22 UTC, soit 3 min 17 s.

| Step importante | Horaires UTC | Conclusion | Résultat logs |
|---|---|---|---|
| Hub workflow contracts | 23:58:28 → 23:59:23 | success | 11 réussis, 1 ignoré ; `No issues found! (ran in 15.0s)` |
| Core roadmap contracts | 23:59:23 → 00:00:00 | success | 33 réussis ; `No issues found!` |
| Editor smoke and static checks | 00:00:00 → 00:00:35 | success | 20 réussis ; `No issues found! (ran in 22.9s)` |
| Studio smoke and static checks | 00:00:35 → 00:01:19 | success | 26 réussis ; `No issues found! (ran in 9.4s)` |

Aucune étape du job skipped, installation et nettoyage terminés avec succès. Le workflow local et celui de `main` distant sont identiques, blob `a8b8a6e4f3b4124b6e66666927874f27ecbedbbb`. Aucun contrôle important devenu non bloquant. Le run vert précédent sur le commit correctif apporte une preuve indépendante de l'effet de ce correctif.

Commandes principales d'audit GitHub exécutées, toutes exit 0 :

```bash
gh api repos/yoahnl/pokemap/commits/main
gh api 'repos/yoahnl/pokemap/contents/.github/workflows/pokemap_quick_checks.yml?ref=main'
gh run list --repo yoahnl/pokemap --workflow pokemap_quick_checks.yml --limit 10 \
  --json databaseId,headSha,headBranch,conclusion,status,event,url,createdAt,updatedAt
gh run view 36506168877 --repo yoahnl/pokemap --json databaseId,headSha,conclusion,status,url,jobs
gh run view 36647921551 --repo yoahnl/pokemap --json databaseId,headSha,conclusion,status,url,jobs
gh run view 36645290462 --repo yoahnl/pokemap --json databaseId,headSha,conclusion,status,url,jobs
gh run view 36506168877 --repo yoahnl/pokemap --log
gh run view 36645024906 --repo yoahnl/pokemap --log
gh run view 36647921551 --repo yoahnl/pokemap --log
git log -5 --oneline -- apps/pokemap_hub/lib/presentation/features/home/widgets/avelune_game_shelf.dart
git diff 2e1bc223a2c9d958c6c43d45c5d50e04f9f7c495 HEAD -- .github/workflows/pokemap_quick_checks.yml
git diff 2e1bc223a2c9d958c6c43d45c5d50e04f9f7c495 HEAD -- apps/pokemap_hub/lib/presentation/features/home/widgets/avelune_game_shelf.dart
git show --format=fuller --stat fbf286ade3b519841a36058e6f10bf73f8b40b2c
git show fbf286ade3b519841a36058e6f10bf73f8b40b2c -- apps/pokemap_hub/lib/presentation/features/home/widgets/avelune_game_shelf.dart
```

Lectures de fichiers via `cat`, `git show HEAD:<chemin>` et recherches ciblées `rg` ont complété cet audit. Les gros logs ont été traités via context-mode pour extraire les diagnostics, compteurs et steps, sans substituer un résumé à la vérification des codes de sortie.

## G. Limites et critique

Le seul test ignoré dans la CI est `certification intro fixtures contain H.264 video and AAC audio`, dans `intro_codec_fixture_test.dart`. Les lignes 5–11 détectent `ffprobe` ; la ligne 26 utilise `skip: !_ffprobeAvailable`. Ce test et son skip existaient déjà dans le run historique, sans modification par le correctif. Localement, `ffprobe` est présent et le test passe, d'où 12 tests Hub plutôt que 11+1. Le contrat du workflow codec reste testé sur GitHub ; la vérification effective des fichiers codec n'est pas prouvée par ce runner sans `ffprobe`.

Ces quick checks sont un signal rapide de contrats, tests sélectionnés et analyses ciblées. Ils ne remplacent pas :

- les Golden Gates, la certification produit et les suites complètes ;
- les builds de distribution, signatures, notarisation, installation ou publication ;
- les recettes natives macOS/iOS/Android et les parcours Player installés ;
- les benchmarks, performances et certifications longues ;
- une validation artistique ou une preuve d'exécution gameplay/MCP.

Exécution locale sur macOS arm64, CI sur Ubuntu 24.04 : même SDK et commandes, systèmes différents. L'Evidence Pack distingue ces deux preuves. Le run GitHub ne contient pas le rapport non commité ; il contient exactement les sources finales validées, qui n'ont pas changé.

Auto-critique : aucun nouveau mécanisme anti-régression ajouté, conformément au scope minimal et à la demande de ne pas fabriquer de modifications. Le signal existant est rétabli et fonctionne. Le skip codec reste une limite connue, aucune extension à la CI proposée ici. Pas de second défaut bloquant révélé dans les étapes aval. Le rapport et les liens GitHub sont durables ; les logs `/tmp` sont des preuves locales temporaires. MCP authoring parity et roadmap FG : non applicables, aucune sémantique d'authoring ou mécanique modifiée.

## Verdicts des agents et passes

| Rôle | Responsable | Verdict |
|---|---|---|
| Audit / Architecture | Agent `audit` | PASS : main distant identique, cause historique confirmée, dernier run intégralement exécuté |
| Implémentation | Passe du parent Tom | Aucun patch nécessaire : correctif déjà présent ; zéro source modifiée |
| Tests | Agent `tests` | PASS : commandes exactes, SDK exact, 91 tests locaux, quatre analyses propres |
| Build / Validation | Passe du parent avec preuves de l'agent Tests | Compilations des suites PASS ; build distribution non applicable au workflow et non revendiqué |
| Critique finale | Agent `critique` | PASS : aucune suppression, règle affaiblie, erreur masquée ou modification inutile ; limite codec explicitée |

Trois vrais agents indépendants et deux passes du parent couvrent les cinq rôles demandés, sans prétendre à cinq agents distincts.

## H. État Git final et traçabilité

SHA final inchangé : `f559e55c6815844ad0e0c08b2ed661733156e703`, branche `main`.

Sortie exacte de `git status --short --untracked-files=all` après création de ce rapport :

```text
?? documentation/reports/ci/post_ci_001_quick_checks_evidence_pack.md
```

Aucun changement préexistant, aucun changement concurrent observé ni écrasé. Le rapport reste non suivi pour revue ; aucun staging ou commit. `git diff` des fichiers suivis reste vide. `git diff --check` ne couvre pas le contenu d'un fichier non suivi ; le contrôle d'hygiène Markdown valide sa place et son budget, et sa revue critique vérifie le contenu.

Ticket existant : [POST-CI-001](https://app.notion.com/p/3ea197a7bfa581048b5ecb45edeb1505), domaine Systèmes transverses, `Gate bêta` conservé faux. Projection finale : TO REVIEW avec SHA, preuves locales, run GitHub, fichiers et limites ; aucune création de ticket ou modification de scope bêta. Tous les critères techniques sont satisfaits ; prochaine action : revue de Yoahn et décision de clôture. Aucun chantier complémentaire requis pour restaurer ce workflow.
