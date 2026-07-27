# RM-069 — Golden Journey 19 Criteria Gate

Date : 2026-07-27  
Liens canoniques : `FG-181`, `FG-182`  
Verdict du lot : **DONE proposé**

## Résultat

Le gate 7A exporte désormais le projet Selbrume en `.pokemapgame`, inspecte et
installe ce package par les services réels du Hub, résout
`project/project.json` dans la version installée, puis exécute le scénario
certifiant `MVP-01` à `MVP-19` depuis cette copie.

La preuve exige :

- le smoke d'installation ;
- l'égalité du SHA-256 exporté et installé ;
- un chemin canonique contenu dans le support root du Hub et distinct de la
  source ;
- exactement 19 critères uniques et tous réussis ;
- le niveau `releaseEvidence` sans raccourci ;
- la fin `ending.selbrume-sauvee`, la victoire, le résultat, les crédits et la
  destination Hub.

## Audit initial

État Git initial :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
```

Ces sept fichiers sont des modifications utilisateur préexistantes. Ils sont
hors périmètre, conservés et exclus du commit du lot.

Pendant la validation, ils ont été commités séparément sur
`cc212a9d716bc9fa484517defa3738a84f6786b5` (`feat(personalization): add
preference to launch most recent game on startup`). Le commit `RM-069` part
donc de cette nouvelle base sans reprendre leur diff.

Constats :

1. `mvp_certification.json` déclarait déjà exactement les 19 critères.
2. `SelbrumeEvaluationDriver` traversait les hooks runtime réels.
3. `selbrume_player_journey_e2e_test.dart` validait déjà fin, résultat,
   crédits et retour Hub.
4. Aucune preuve ne liait encore ce parcours au projet extrait d'un package
   réellement installé.

## Passes indépendantes

La règle de dépôt demandant plusieurs passes a été appliquée localement sous
des rôles séparés, les sub-agents n'étant pas autorisés dans ce contexte.

| Passe | Verdict |
|---|---|
| Audit / Architecture | Le manque se situe entre l'export et le point d'entrée du driver, sans besoin de modifier les moteurs gameplay. |
| Implémentation | Dépendances de test uniquement ; aucune dépendance de production ajoutée au host. |
| Tests | Deux RED diagnostiques, puis GREEN complet en `04:51`. |
| Build / Validation | Test ciblé vert ; analyse du package exécutée avant commit. |
| Critique finale | Le scénario de gate reste stocké côté harness, mais le projet, les maps et assets consommés viennent exclusivement de la version installée. |

## Fichiers

### Créé

- `examples/playable_runtime_host/test/phase_7a_installed_golden_journey_test.dart`

### Modifiés

- `examples/playable_runtime_host/pubspec.yaml`
  - ajout de `map_distribution`, `map_editor`, `pokemap_hub` et `pub_semver`
    en dépendances de développement ;
- `examples/playable_runtime_host/pubspec.lock`
  - résolution cohérente des dépendances du gate d'intégration ;
- `examples/playable_runtime_host/macos/Flutter/GeneratedPluginRegistrant.swift`
  - régénération Flutter des plugins macOS transitifs apportés par les
    dépendances de développement.

## Zones de diff

```diff
 dev_dependencies:
+  map_distribution:
+    path: ../../packages/map_distribution
+  map_editor:
+    path: ../../packages/map_editor
+  pokemap_hub:
+    path: ../../apps/pokemap_hub
+  pub_semver: ^2.2.0
```

```diff
+import file_picker
+import screen_retriever_macos
+import video_player_avfoundation
+import window_manager
```

Le test créé couvre la chaîne :

```text
source Selbrume
  -> GamePackageExportService
  -> GamePackageInspector
  -> GamePackageInstaller
  -> InstalledGameLaunchResolver
  -> SelbrumeEvaluationDriver(installedProjectRoot)
  -> EvaluationScenarioRunner
  -> MVP-01..MVP-19 + completion/result/credits/Hub
```

## Contenu complet du fichier créé

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_editor/game_export.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_hub/pokemap_hub_player.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_receipt.dart';
import 'package:pokemap_loader/src/evaluation/driver/selbrume_evaluation_driver.dart';
import 'package:pokemap_loader/src/evaluation/runner/evaluation_scenario_runner.dart';
import 'package:pokemap_loader/src/evaluation/scenario/evaluation_scenario_parser.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Phase 7A certifies all 19 MVP criteria from the installed package',
    () async {
      final repositoryRoot = _findRepositoryRoot();
      final sourceProjectRoot = Directory(
        p.join(repositoryRoot.path, 'selbrume'),
      );
      final temporaryRoot = await Directory.systemTemp.createTemp(
        'pokemap-phase-7a-installed-golden-',
      );
      addTearDown(() => temporaryRoot.delete(recursive: true));

      final packageFile = File(
        p.join(temporaryRoot.path, 'selbrume.pokemapgame'),
      );
      final artifact = await const GamePackageExportService().exportToFile(
        projectRoot: sourceProjectRoot,
        profile: GamePackageExportProfile(
          gameId: 'games.pokemap.selbrume',
          gameVersion: '1.0.0',
          title: 'Selbrume',
          description: 'Golden gameplay journey for the PokeMap MVP.',
          authorName: 'PokeMap',
          defaultLocale: 'fr',
          supportedLocales: const <String>['fr'],
          requiredCapabilities: const <String>[
            'dialogue.choices@1',
            'map@1',
            'overworld.menu@1',
            'world.shop@1',
          ],
        ),
        outputFile: packageFile,
      );
      final compatibility = _hostCompatibility(
        artifact.manifest.compatibility.projectFormat,
      );
      final inspector = GamePackageInspector(
        hostCompatibility: compatibility,
      );
      final supportRoot = Directory(
        p.join(temporaryRoot.path, 'PokeMap'),
      );
      var loadSmokePassed = false;
      final installation = await GamePackageInstaller(
        supportRoot: supportRoot,
        inspector: inspector,
        availableDiskBytes: (_) async => 2 * 1024 * 1024 * 1024,
        loadSmoke: (_, __) async {
          loadSmokePassed = true;
        },
        prepareSavesForUpdate: (_, __) async =>
            const SaveUpdatePreparation(),
        now: () => DateTime.utc(2026, 7, 27, 12),
      ).install(
        packageFile,
        source: GamePackageInstallSource.localFile,
      );
      final launch = await InstalledGameLaunchResolver(
        supportRoot: supportRoot,
        hostCompatibility: compatibility,
      ).resolve(installation.game);
      final installedProjectFile = await launch.assets.resolveReference(
        launch.project,
      );
      final installedProjectRoot = installedProjectFile.parent;
      final canonicalSupportRoot = await supportRoot.resolveSymbolicLinks();

      expect(loadSmokePassed, isTrue);
      expect(artifact.certification.isCertified, isTrue);
      expect(
        installation.receipt.packageSha256,
        artifact.packageSha256,
      );
      expect(
        p.isWithin(canonicalSupportRoot, installedProjectFile.path),
        isTrue,
        reason: 'The certified run must use the Hub-installed project.',
      );
      expect(
        p.equals(installedProjectRoot.path, sourceProjectRoot.path),
        isFalse,
      );

      final scenario = const EvaluationScenarioParser().parseString(
        File(
          p.join(
            'evaluation',
            'scenarios',
            'selbrume',
            'mvp_certification.json',
          ),
        ).readAsStringSync(),
      );
      final driver = await SelbrumeEvaluationDriver.start(
        projectRoot: installedProjectRoot,
        runId: 'phase-7a-installed-golden',
      );
      addTearDown(driver.dispose);
      final result = await EvaluationScenarioRunner(
        driver: driver,
        runIdFactory: () => 'phase-7a-installed-golden',
      ).run(scenario);

      final expectedCriterionIds = <String>{
        for (var index = 1; index <= 19; index += 1)
          'MVP-${index.toString().padLeft(2, '0')}',
      };
      expect(result.status, EvaluationRunStatus.succeeded);
      expect(result.evidenceLevel, EvaluationEvidenceLevel.releaseEvidence);
      expect(result.shortcutsUsed, isEmpty);
      expect(
        scenario.criteria.map((criterion) => criterion.id).toSet(),
        expectedCriterionIds,
      );
      expect(result.productCriteria, hasLength(19));
      expect(
        result.productCriteria.map((criterion) => criterion.id).toSet(),
        expectedCriterionIds,
      );
      expect(
        result.productCriteria,
        everyElement(
          isA<EvaluationProductCriterionResult>().having(
            (criterion) => criterion.passed,
            'passed',
            isTrue,
          ),
        ),
      );

      expect(driver.gameCompletionRequests, hasLength(1));
      final completion = driver.gameCompletionRequests.single;
      expect(completion.endingId, 'ending.selbrume-sauvee');
      expect(completion.outcome, GameCompletionOutcome.victory);
      expect(completion.result.title, 'Selbrume est sauvée');
      expect(completion.credits.title, 'Crédits — Selbrume');
      expect(completion.destination, GameCompletionDestination.hub);
      expect(completion.allowPostGameContinue, isFalse);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

GamePackageHostCompatibility _hostCompatibility(String projectFormat) =>
    GamePackageHostCompatibility(
      hubVersion: Version.parse('1.2.0'),
      runtimeApiVersion: Version.parse('1.4.0'),
      capabilities: const <String>{
        'dialogue.choices@1',
        'map@1',
        'overworld.menu@1',
        'world.shop@1',
      },
      supportedProjectFormats: <String>{projectFormat},
      currentProjectFormat: projectFormat,
      supportedSaveFormats: const <int>{1},
    );

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        Directory(p.join(current.path, 'selbrume')).existsSync()) {
      return current;
    }
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate the PokeMap repository root.');
    }
    current = parent;
  }
}
```

## Commandes et résultats exacts

```text
cd examples/playable_runtime_host
flutter pub get
Résultat : exit 0, 30 dépendances ajustées pour le host de test.

flutter test test/phase_7a_installed_golden_journey_test.dart
Résultat RED 1 : exit 1 en 03:00.
Cause : comparaison `/tmp` avec sa forme canonique `/private/tmp`.

flutter test test/phase_7a_installed_golden_journey_test.dart
Résultat RED 2 : exit 1 en 02:12.
Cause : TestWidgetsFlutterBinding non initialisé avant le premier dialogue.

dart format test/phase_7a_installed_golden_journey_test.dart
Résultat : exit 0, 1 fichier formaté.

flutter test test/phase_7a_installed_golden_journey_test.dart
Résultat final : exit 0, "04:51 +1: All tests passed!".

flutter analyze
Résultat : exit 0, "No issues found! (ran in 6.9s)".
```

## Décisions et non-objectifs

- Le scénario de certification reste un asset du harness de release ; il n'est
  pas copié dans le jeu distribué.
- Les contenus effectivement chargés sont ceux de la version installée.
- Aucun moteur gameplay, runtime ou Hub n'a été modifié.
- Le lot ne signe pas encore une release : les gates monorepo, build et receipt
  relèvent de `RM-070` à `RM-073`.

## Auto-critique et risques

- Le test dure environ cinq minutes et produit beaucoup de traces runtime.
- Il dépend de l'exporteur Editor et du Hub en dev-dependencies, ce qui alourdit
  la résolution du host sans coupler ses dépendances de production.
- Le test prouve l'exécution headless du package installé, pas un walkthrough
  humain dans le binaire macOS.
- Le scénario externe pourrait théoriquement diverger du package ; l'égalité
  du SHA installé et l'exécution de tous les hooks limitent ce risque, tandis
  que `RM-073` devra lier le scenario/version au receipt final.

## État du lot

`RM-069` peut être proposé **DONE** sur preuve fraîche. `FG-181` et `FG-182`
restent couverts ; aucun verdict `FG-185` n'est encore accordé.

État Git attendu après commit du lot : aucun diff `RM-069` restant ; les lots
suivants repartent du commit dédié créé à partir de `cc212a9d7`.
