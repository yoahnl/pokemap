# Evidence Pack — Phase 0, restauration des gates fiables

Date de clôture technique : 2026-07-26
Périmètre : `RM-001`, `RM-002`, `RM-003`, `RM-004`
Roadmap source : `reports/gameplay/fg_000_remediation_and_personalization_roadmap.md`

## 1. Verdict

**Phase 0 : PASS technique, clôture `DONE` proposée pour les quatre lots.**

| Lot | Verdict proposé | Preuve principale |
|---|---|---|
| `RM-001` | `DONE` | cohorte Lysa à source partagée ordonnée, collision exacte rejetée avant dispatch, save/reload one-shot prouvé |
| `RM-002` | `DONE` | solveur borné et fail-closed, corrélations préservées, Selbrume canonique prouvable |
| `RM-003` | `DONE` pour le refresh de baseline | reçu recréé après les suites complètes, fingerprint exact, contre-validation post-reçu |
| `RM-004` | `DONE` V0 | matrice machine-readable complète, références réelles editor/runtime/player/tests, gate fail-closed |

Ce verdict ne promeut pas la release gameplay :

- `FG-185` reste **`PARTIAL / NO-GO`** ;
- le reçu final porte explicitement `PARTIAL / NO-GO baseline: runtime smoke only; FG-185 is not promoted.` ;
- `PH-007` reste une gate de personnalisation distincte ;
- les phases suivantes de la roadmap restent nécessaires.

## 2. Audit initial et reproductions rouges

### 2.1 État Git initial

L'arbre était déjà dirty avant l'implémentation :

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
?? reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md
?? reports/gameplay/fg_000_remediation_and_personalization_roadmap.md
```

Ces changements préexistants ont été préservés. La roadmap, déjà non suivie au départ, a seulement été amendée dans la zone `RM-001` afin de refléter le contrat réel découvert pendant le diagnostic.

### 2.2 Rouges initiaux

| Constat | Symptôme | Cause |
|---|---|---|
| `RM-001` | `Too many elements` sur la cohorte Lysa | le test supposait à tort une unicité de source ; le produit autorise plusieurs Events partageant une source si leur rang diffère |
| `RM-002` | verdict `indeterminate` exactement à `16 384` états | produit cartésien entre histoire principale et quêtes optionnelles indépendantes |
| `RM-003` | reçu obsolète/non autoritaire | ancien fingerprint `sha256:0c4aaff…`, aucune limitation explicite, date 2026-07-23 |
| `RM-004` | absence de vérité traversante exploitable par machine | le catalogue déclarait des capacités, sans objet unique exigeant auteur, contrat, runtime, surface joueur et preuves positive/négative |

Un rouge supplémentaire a été découvert pendant la suite host finale :

```text
Expected: sha256:8827f2e81335...
Actual:   sha256:d3a8d38e05fa...
```

Le commit déjà présent `9321238fc feat(selbrume): prove dynamic shop progression` avait modifié `selbrume/project.json` de 117 lignes sans actualiser le hash du test Golden. Seule la constante de test a été alignée sur le fichier canonique suivi par Git ; la Golden Slice isolée et la suite host complète ont ensuite repassé.

## 3. Décisions et changements

### 3.1 `RM-001` — autorité Lysa

- L'invariant exact est l'unicité du tuple `source + priority + order`, pas l'unicité de `source`.
- Le `singleWhere` strict est conservé sur cette clé d'autorité.
- La fixture contient deux événements Lysa légitimes sur la même source, classés de manière déterministe.
- Une collision exacte est rejetée par `NarrativeEventDispatchAuthority.prepare` avant toute planification/dispatch.
- Le test runtime exécute un vrai save/reload puis prouve que la scène one-shot reste consommée et ne se réarme pas.

### 3.2 `RM-002` — solveur symbolique

- Les Events sont ordonnés selon la priorité et l'ordre runtime canoniques.
- Les storylines optionnelles indépendantes sont factorisées au lieu de multiplier toutes leurs branches avec l'histoire principale.
- Les lots optionnels couplés restent fusionnés ; une écriture optionnelle lue par le chemin obligatoire est promue dans le composant obligatoire.
- Les preuves utilisent les frontières d'Events et de storylines, pas un état transitoire intra-scène.
- Les états projetés conservent toutes leurs origines compatibles.
- Un index de provenance relie exactement une branche optionnelle aux descendants compatibles de l'histoire principale.
- Les conjonctions entre composants sont acceptées uniquement lorsque leurs graines principales sont compatibles.
- `completedStepIds` agrège également les composants indépendants.
- Les limites juste sous et exactement au budget sont testées ; l'épuisement reste `indeterminate`, jamais `pass`.
- Les déduplications de frontière et d'origine utilisent maintenant des index `Set`, supprimant deux boucles quadratiques.

Mesures observées :

- diagnostic après factorisation : `9 364` états symboliques, marge `7 020` sous la borne `16 384` ;
- matrice canonique avant optimisation finale : `401.24 s` ;
- même matrice après indexation : `138.84 s`, deux tests verts ;
- validateur éditeur canonique isolé : `64.76 s`, puis `62 s` dans la suite série finale.

Ces durées sont des observations sur la machine de validation, pas des garanties contractuelles.

### 3.3 `RM-003` — reçu frais

La chronologie obligatoire a été respectée :

1. suites runtime et editor complètes vertes ;
2. build macOS Debug vert ;
3. exécution de l'outil de production ;
4. écriture du reçu ;
5. contre-validation editor post-reçu ;
6. test d'intégration du reçu.

Reçu remplacé suivi dans `HEAD` :

```json
{
  "schemaVersion": 1,
  "projectFingerprint": "sha256:0c4aaff915b201f171eeb0ef12aff36276595efa029a38646bad319929183fcf",
  "validatorVersion": "narrative-validator-v1",
  "profileId": "selbrume-release-v1",
  "profileVersion": 1,
  "suiteIds": [
    "selbrume-lighthouse-retry",
    "selbrume-player-journey"
  ],
  "fixtureId": "selbrume",
  "result": "pass",
  "completedAt": "2026-07-23T04:53:20.569408Z",
  "limitations": []
}
```

Baseline intermédiaire avant la séquence finale :

- SHA-256 fichier : `6610de5dd4fc037d984995fe59bbecda98b2997f0012decf9047e771254d240d` ;
- fingerprint projet : `sha256:d7845c6efce07848022decbef072ae0d2652306fdd8c52d1bef418c3f7d2ba83` ;
- date : `2026-07-26T13:25:54.925385Z` ;
- limitation déjà fail-closed.

Reçu final :

- SHA-256 fichier : `c9eed7a46be309fbef9125aba7a7f6f52fe25092e9749554b1759bc306ba2f03` ;
- fingerprint projet : `sha256:d7845c6efce07848022decbef072ae0d2652306fdd8c52d1bef418c3f7d2ba83` ;
- résultat : `pass` ;
- date : `2026-07-26T15:27:44.848418Z` ;
- suites : `selbrume-lighthouse-retry`, `selbrume-player-journey` ;
- limitation : `PARTIAL / NO-GO baseline: runtime smoke only; FG-185 is not promoted.`

### 3.4 `RM-004` — Capability Truth Gate V0

Le nouveau contrat Core expose les colonnes exigées :

```text
capabilityId
authoringControl
contractField
runtimeConsumer
playerSurface
positiveTest
negativeTest
status
```

La gate :

- exige un ensemble explicite de capacités attendues ;
- rejette matrice vide, partielle, inattendue ou dupliquée ;
- rejette toute capacité promue sans l'une des six références ;
- exige une raison pour une capacité différée ;
- rejette une matrice sans aucune capacité promue ;
- produit JSON et Markdown déterministes.

Les attestations V0 pointent vers des types réellement importés :

- auteur : `SceneActionBuilder` ;
- consommateurs : `SceneConsequenceRuntimeWriter`, `SceneInteractiveCommandRuntimeExecutor`, `SceneRuntimeHostCallbacks` ;
- surface joueur : `PlayableMapGame` ;
- preuves : tests de palette, runtime parity, collector host et tests négatifs correspondants.

## 4. Inventaire des fichiers de Phase 0

### 4.1 Fichiers modifiés

| Fichier | Zone précise |
|---|---|
| `reports/gameplay/fg_000_remediation_and_personalization_roadmap.md` | contrat `RM-001` amendé vers `source + priority + order` |
| `packages/map_core/lib/map_core.dart` | export de `project_capability_truth.dart` |
| `packages/map_core/lib/src/operations/narrative_symbolic_reachability_solver.dart` | partition des composants, projection/origines, compatibilité, déduplication indexée, preuves agrégées |
| `packages/map_core/test/narrative_symbolic_reachability_solver_test.dart` | budget, indépendance, corrélation, origines projetées et conjonctions exclusives |
| `packages/map_core/test/narrative_event_dispatch_authority_test.dart` | collision exacte rejetée avant planning |
| `packages/map_core/test/event_builder_authoring_operations_test.dart` | attente de caractérisation alignée sur `storyStepCompleted` |
| `packages/map_runtime/lib/map_runtime.dart` | exports des attestations runtime/player |
| `packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart` | cohorte Lysa classée, save/reload réel et non-réarmement |
| `packages/map_runtime/test/support/selbrume_event_v2_test_fixture.dart` | ID du rematch Lysa |
| `packages/map_runtime/test/narrative_command_runtime_parity_test.dart` | matrice traversante positive/négative et gate fail-closed |
| `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart` | publication conditionnée par une vérité complète explicite |
| `packages/map_editor/test/ui/canvas/narrative_command_palette_test.dart` | cas complets et refus des preuves partielles |
| `examples/playable_runtime_host/lib/src/project_gameplay_readiness_collector.dart` | vérité de capacité explicite, sans défaut fictif |
| `examples/playable_runtime_host/test/project_gameplay_readiness_collector_test.dart` | refus absence/partiel et collecte complète |
| `examples/playable_runtime_host/test/narrative_runtime_smoke_receipt_integration_test.dart` | limitation NO-GO et suites obligatoires |
| `examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart` | hash Golden aligné sur le manifeste suivi actuel |
| `examples/playable_runtime_host/tool/verify_narrative_project.dart` | limitation NO-GO obligatoire dans le reçu |
| `selbrume/.pokemap/validation/narrative_runtime_smoke_receipt.json` | reçu de production frais |

### 4.2 Fichiers créés

| Fichier | Rôle |
|---|---|
| `packages/map_core/lib/src/read_models/project_capability_truth.dart` | contrat et évaluateur de vérité de capacité |
| `packages/map_core/test/project_capability_truth_test.dart` | tests fail-closed du contrat |
| `packages/map_editor/lib/narrative_capability_evidence.dart` | barrel public editor |
| `packages/map_editor/lib/src/ui/canvas/scenes/narrative_command_authoring_capability_evidence.dart` | attestation du contrôle auteur réel |
| `packages/map_runtime/lib/src/application/scene_runtime/narrative_command_runtime_capability_evidence.dart` | attestation des consommateurs runtime |
| `packages/map_runtime/lib/src/presentation/flame/narrative_command_player_surface_capability_evidence.dart` | attestation de la surface joueur |
| `reports/gameplay/fg_000_phase_0_remediation_evidence.md` | présent Evidence Pack |

Le présent fichier constitue lui-même son contenu intégral. Le contenu intégral des six autres fichiers créés figure en annexe A.

### 4.3 Changements préexistants laissés hors périmètre

Les cinq fichiers `apps/pokemap_hub/...`, les deux fichiers `packages/map_player_ui/...` et `reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md` étaient déjà modifiés/non suivis avant Phase 0. Ils n'ont pas été édités pour cette clôture.

## 5. Commandes et résultats exacts

### 5.1 Tests ciblés

| Commande | Résultat |
|---|---|
| `dart test test/narrative_event_dispatch_authority_test.dart` (`map_core`) | `+23`, pass |
| `flutter test test/selbrume_event_v2_three_source_integration_test.dart` (`map_runtime`) | `+8`, pass |
| `dart test test/narrative_symbolic_reachability_solver_test.dart` (`map_core`) | `+16`, pass |
| `dart test test/project_capability_truth_test.dart` (`map_core`) | `+6`, pass |
| `flutter test test/ui/canvas/narrative_command_palette_test.dart` (`map_editor`) | `+6`, pass |
| `flutter test test/narrative_command_runtime_parity_test.dart` (`map_runtime`) | `+7`, pass |
| tests collector/reçu ciblés (`playable_runtime_host`) | `+7`, pass |
| `flutter test test/selbrume_narrative_campaign_outcome_matrix_test.dart` | `+2`, pass, `real 138.84 s` |
| `flutter test test/selbrume_narrative_validator_test.dart` | `+1`, pass, `real 64.76 s` |
| Golden Slice Lysa isolée après correction du hash | `+1`, pass |

### 5.2 Suites complètes finales

| Package | Commande | Résultat |
|---|---|---|
| `map_core` | `dart test` | `+4454`, tous passés |
| `map_core` | `dart analyze` | `No issues found!` |
| `map_runtime` | `flutter test` | `+2170`, `~1`, tous passés |
| `map_runtime` | `flutter analyze` | `No issues found! (ran in 4.8s)` |
| `map_editor` | `flutter test --concurrency=1` | `+4147`, tous passés en `18:38` |
| `map_editor` | `flutter analyze` | `No issues found! (ran in 6.1s)` |
| `playable_runtime_host` | première suite complète | `+253 ~2 -1`, rouge uniquement sur le hash Golden obsolète |
| `playable_runtime_host` | suite complète après correction | `+254 ~2`, tous passés en `4:08` |
| `playable_runtime_host` | `flutter analyze` | `No issues found! (ran in 6.3s)` |

Les suites Flutter ont été exécutées séquentiellement. Les passages concurrents antérieurs ayant provoqué des erreurs de harnais `stream_channel` ne sont pas utilisés comme preuves.

### 5.3 Build

Commande :

```bash
cd examples/playable_runtime_host
flutter build macos --debug
```

Résultat :

```text
✓ Built build/macos/Build/Products/Debug/PokeMap Selbrume.app
```

### 5.4 Production receipt et contre-validation

Commande de production :

```bash
cd examples/playable_runtime_host
dart run tool/verify_narrative_project.dart \
  --project-root ../../selbrume \
  --profile selbrume-release-v1 \
  --write-receipt
```

Résultats :

```text
selbrume-lighthouse-retry: +3, All tests passed!
selbrume-player-journey: +6, All tests passed!
receipt result: pass
completedAt: 2026-07-26T15:27:44.848418Z
```

Contre-validations :

```text
packages/map_editor:
flutter test test/selbrume_narrative_validator_test.dart
01:02 +1: All tests passed!

examples/playable_runtime_host:
flutter test test/narrative_runtime_smoke_receipt_integration_test.dart
+2: All tests passed!
```

### 5.5 Hygiène

- `dart format` exécuté sur les fichiers Dart touchés ;
- analyses ciblées puis complètes sans issue ;
- `git diff --check` sans erreur avant la séquence complète ; une nouvelle vérification finale est consignée en section 8 ;
- aucune commande Git d'écriture exécutée ;
- aucun commit, stash, reset, checkout, merge ou push effectué.

## 6. Verdicts des passes indépendantes

| Passe | Verdict et suite donnée |
|---|---|
| Revue architecture (`phase0_architecture_review`) | `GO` après correction des contrats ; a exigé de garder les gates release séparées et les références réelles |
| Revue validation (`phase0_validation_review`) | a confirmé `RM-004`, puis trouvé le faux négatif exact lié aux origines projetées ; défaut reproduit, corrigé et couvert |
| Critique finale (`phase0_final_critique`) | a trouvé plusieurs cas subtils de corrélation ; après correction de l'origine multi-branche, seul le séquencement procédural `RM-003` restait |
| Passe d'implémentation locale | tous les points des revues ont été intégrés ; aucune objection technique ouverte |

Les reviewers de validation et critique ont été interrompus après leurs verdicts utiles afin d'empêcher des processus Flutter concurrents pendant les suites de clôture. Leurs objections bloquantes avaient déjà été reproduites et corrigées avant les suites complètes.

## 7. Auto-critique, limites et risques

### 7.1 Ce qui est solide

- Les corrections sont appuyées par tests négatifs, pas seulement par des Golden positifs.
- Le solveur reste fail-closed aux bornes et conserve les corrélations de branches.
- Le reçu est issu de l'outil de production après les suites complètes.
- La matrice de capacité ne peut pas inventer de références par défaut.
- Les quatre packages touchés ont des suites et analyses finales vertes.

### 7.2 Risques résiduels

1. **Performance du solveur.** La matrice exhaustive isolée reste à environ 139 secondes. C'est borné et nettement amélioré, mais encore coûteux pour un feedback interactif fréquent.
2. **Gate V0 basée sur attestations.** Les références sont ancrées à des types réellement importés et vérifiées par tests, mais V0 n'effectue pas encore une résolution AST/build graph exhaustive de chaque symbole.
3. **Build limité au Debug macOS.** Aucun build release signé, installation sur appareil ni walkthrough humain n'a été effectué ; cela appartient à `RM-071`/`RM-073`.
4. **Baseline et non release.** Le reçu prouve un smoke runtime réel, pas la complétude Pokémon ni la readiness de distribution.
5. **Arbre dirty.** Des changements utilisateur préexistants restent présents. Aucun SHA ne doit être présenté comme signature d'un arbre propre.
6. **Portée mécanique restante.** `RM-010` et les phases gameplay/personnalisation suivantes restent nécessaires ; Phase 0 restaure la confiance dans les gates, elle ne livre pas ces fonctions.

### 7.3 Non-objectifs respectés

- pas de promotion de `FG-185` ;
- pas de travail sur le Personalization Hub ;
- pas de refactor visuel ;
- pas de modification des changements Hub/player UI préexistants ;
- pas de changement de plafond symbolique pour masquer l'explosion ;
- pas de remplacement d'un invariant strict par `.firstWhere`.

## 8. État Git final et vérification finale

L'état exact est capturé après création de ce rapport par une dernière commande :

```bash
git status --short --untracked-files=all
git diff --check
```

Le résultat est reporté ci-dessous lors de la dernière passe de clôture.

`git diff --check` : exit `0`, aucune erreur.

```text
 M apps/pokemap_hub/lib/src/ui/hub_app.dart
 M apps/pokemap_hub/lib/src/ui/hub_shell.dart
 M apps/pokemap_hub/test/ui/hub_app_player_navigation_test.dart
 M apps/pokemap_hub/test/ui/hub_preferences_store_test.dart
 M apps/pokemap_hub/test/ui/hub_shell_test.dart
 M examples/playable_runtime_host/lib/src/project_gameplay_readiness_collector.dart
 M examples/playable_runtime_host/test/narrative_runtime_smoke_receipt_integration_test.dart
 M examples/playable_runtime_host/test/project_gameplay_readiness_collector_test.dart
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
 M examples/playable_runtime_host/tool/verify_narrative_project.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_core/lib/src/operations/narrative_symbolic_reachability_solver.dart
 M packages/map_core/test/event_builder_authoring_operations_test.dart
 M packages/map_core/test/narrative_event_dispatch_authority_test.dart
 M packages/map_core/test/narrative_symbolic_reachability_solver_test.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_command_palette.dart
 M packages/map_editor/test/ui/canvas/narrative_command_palette_test.dart
 M packages/map_player_ui/lib/src/localization/player_localizations.dart
 M packages/map_player_ui/lib/src/preferences/player_preferences.dart
 M packages/map_runtime/lib/map_runtime.dart
 M packages/map_runtime/test/narrative_command_runtime_parity_test.dart
 M packages/map_runtime/test/selbrume_event_v2_three_source_integration_test.dart
 M packages/map_runtime/test/support/selbrume_event_v2_test_fixture.dart
 M selbrume/.pokemap/validation/narrative_runtime_smoke_receipt.json
?? packages/map_core/lib/src/read_models/project_capability_truth.dart
?? packages/map_core/test/project_capability_truth_test.dart
?? packages/map_editor/lib/narrative_capability_evidence.dart
?? packages/map_editor/lib/src/ui/canvas/scenes/narrative_command_authoring_capability_evidence.dart
?? packages/map_runtime/lib/src/application/scene_runtime/narrative_command_runtime_capability_evidence.dart
?? packages/map_runtime/lib/src/presentation/flame/narrative_command_player_surface_capability_evidence.dart
?? reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md
?? reports/gameplay/fg_000_phase_0_remediation_evidence.md
?? reports/gameplay/fg_000_remediation_and_personalization_roadmap.md
```

## Annexe A — contenu intégral des fichiers créés

### A.1 `packages/map_core/lib/src/read_models/project_capability_truth.dart`

```dart
import 'narrative_command_catalog.dart';

enum ProjectCapabilityTruthStatus { promoted, deferred }

enum ProjectCapabilityTruthIssueCode {
  duplicateCapabilityId,
  missingCapabilityId,
  missingExpectedCapability,
  unexpectedCapability,
  noPromotedCapabilities,
  missingAuthoringControl,
  missingContractField,
  missingRuntimeConsumer,
  missingPlayerSurface,
  missingPositiveTest,
  missingNegativeTest,
  missingDeferredReason,
}

final class ProjectCapabilityTruthAttestation {
  ProjectCapabilityTruthAttestation({
    required Map<String, String> referencesByCapabilityId,
  }) : referencesByCapabilityId = Map.unmodifiable(referencesByCapabilityId);

  final Map<String, String> referencesByCapabilityId;

  String referenceFor(String capabilityId) =>
      referencesByCapabilityId[capabilityId] ?? '';
}

final class ProjectCapabilityTruthRecord {
  const ProjectCapabilityTruthRecord.promoted({
    required this.capabilityId,
    required this.authoringControl,
    required this.contractField,
    required this.runtimeConsumer,
    required this.playerSurface,
    required this.positiveTest,
    required this.negativeTest,
  })  : status = ProjectCapabilityTruthStatus.promoted,
        reason = null;

  const ProjectCapabilityTruthRecord.deferred({
    required this.capabilityId,
    required this.reason,
  })  : status = ProjectCapabilityTruthStatus.deferred,
        authoringControl = null,
        contractField = null,
        runtimeConsumer = null,
        playerSurface = null,
        positiveTest = null,
        negativeTest = null;

  final String capabilityId;
  final String? authoringControl;
  final String? contractField;
  final String? runtimeConsumer;
  final String? playerSurface;
  final String? positiveTest;
  final String? negativeTest;
  final ProjectCapabilityTruthStatus status;
  final String? reason;

  Map<String, Object?> toJson() => {
        'capabilityId': capabilityId,
        'authoringControl': authoringControl,
        'contractField': contractField,
        'runtimeConsumer': runtimeConsumer,
        'playerSurface': playerSurface,
        'positiveTest': positiveTest,
        'negativeTest': negativeTest,
        'status': status.name,
        'reason': reason,
      };
}

final class ProjectCapabilityTruthIssue {
  const ProjectCapabilityTruthIssue({
    required this.code,
    required this.capabilityId,
    required this.message,
  });

  final ProjectCapabilityTruthIssueCode code;
  final String capabilityId;
  final String message;

  Map<String, Object?> toJson() => {
        'code': code.name,
        'capabilityId': capabilityId,
        'message': message,
      };
}

final class ProjectCapabilityTruthReport {
  ProjectCapabilityTruthReport._({
    required List<ProjectCapabilityTruthRecord> capabilities,
    required List<ProjectCapabilityTruthIssue> issues,
  })  : capabilities = List.unmodifiable(capabilities),
        issues = List.unmodifiable(issues);

  factory ProjectCapabilityTruthReport.evaluate(
    Iterable<ProjectCapabilityTruthRecord> records, {
    required Set<String> requiredCapabilityIds,
  }) {
    final capabilities = records.toList()
      ..sort(
        (left, right) => left.capabilityId.compareTo(right.capabilityId),
      );
    final issues = <ProjectCapabilityTruthIssue>[];
    final countsById = <String, int>{};
    final normalizedRequiredIds = {
      for (final capabilityId in requiredCapabilityIds)
        if (capabilityId.trim().isNotEmpty) capabilityId.trim(),
    };
    for (final record in capabilities) {
      countsById.update(
        record.capabilityId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
      if (record.capabilityId.trim().isEmpty) {
        issues.add(
          const ProjectCapabilityTruthIssue(
            code: ProjectCapabilityTruthIssueCode.missingCapabilityId,
            capabilityId: '',
            message: 'Capability ID is required.',
          ),
        );
      }
      if (record.status == ProjectCapabilityTruthStatus.deferred) {
        if (_isBlank(record.reason)) {
          issues.add(
            ProjectCapabilityTruthIssue(
              code: ProjectCapabilityTruthIssueCode.missingDeferredReason,
              capabilityId: record.capabilityId,
              message: 'A deferred capability requires a reason.',
            ),
          );
        }
        continue;
      }
      _requireReference(
        issues,
        record,
        value: record.authoringControl,
        code: ProjectCapabilityTruthIssueCode.missingAuthoringControl,
        label: 'authoring control',
      );
      _requireReference(
        issues,
        record,
        value: record.contractField,
        code: ProjectCapabilityTruthIssueCode.missingContractField,
        label: 'contract field',
      );
      _requireReference(
        issues,
        record,
        value: record.runtimeConsumer,
        code: ProjectCapabilityTruthIssueCode.missingRuntimeConsumer,
        label: 'runtime consumer',
      );
      _requireReference(
        issues,
        record,
        value: record.playerSurface,
        code: ProjectCapabilityTruthIssueCode.missingPlayerSurface,
        label: 'player surface',
      );
      _requireReference(
        issues,
        record,
        value: record.positiveTest,
        code: ProjectCapabilityTruthIssueCode.missingPositiveTest,
        label: 'positive test',
      );
      _requireReference(
        issues,
        record,
        value: record.negativeTest,
        code: ProjectCapabilityTruthIssueCode.missingNegativeTest,
        label: 'negative test',
      );
    }
    for (final entry in countsById.entries) {
      if (entry.value < 2) continue;
      issues.add(
        ProjectCapabilityTruthIssue(
          code: ProjectCapabilityTruthIssueCode.duplicateCapabilityId,
          capabilityId: entry.key,
          message: 'Capability ${entry.key} is declared ${entry.value} times.',
        ),
      );
    }
    for (final capabilityId in normalizedRequiredIds) {
      if (countsById.containsKey(capabilityId)) continue;
      issues.add(
        ProjectCapabilityTruthIssue(
          code: ProjectCapabilityTruthIssueCode.missingExpectedCapability,
          capabilityId: capabilityId,
          message: 'Required capability $capabilityId is not declared.',
        ),
      );
    }
    for (final capabilityId in countsById.keys) {
      if (normalizedRequiredIds.contains(capabilityId)) continue;
      issues.add(
        ProjectCapabilityTruthIssue(
          code: ProjectCapabilityTruthIssueCode.unexpectedCapability,
          capabilityId: capabilityId,
          message: 'Capability $capabilityId is outside the required set.',
        ),
      );
    }
    if (normalizedRequiredIds.isEmpty ||
        !capabilities.any(
          (record) => record.status == ProjectCapabilityTruthStatus.promoted,
        )) {
      issues.add(
        const ProjectCapabilityTruthIssue(
          code: ProjectCapabilityTruthIssueCode.noPromotedCapabilities,
          capabilityId: '*',
          message:
              'A capability truth gate requires at least one promoted capability.',
        ),
      );
    }
    issues.sort((left, right) {
      final capability = left.capabilityId.compareTo(right.capabilityId);
      return capability != 0
          ? capability
          : left.code.name.compareTo(right.code.name);
    });
    return ProjectCapabilityTruthReport._(
      capabilities: capabilities,
      issues: issues,
    );
  }

  final List<ProjectCapabilityTruthRecord> capabilities;
  final List<ProjectCapabilityTruthIssue> issues;

  bool get isPassing => issues.isEmpty;

  Map<String, Object?> toJson() => {
        'schemaVersion': 1,
        'status': isPassing ? 'pass' : 'fail',
        'capabilities': [
          for (final capability in capabilities) capability.toJson(),
        ],
        'issues': [for (final issue in issues) issue.toJson()],
      };

  String get agentMarkdown {
    final buffer = StringBuffer()
      ..writeln('# Project Capability Truth')
      ..writeln()
      ..writeln('| Capability | Status | Runtime | Positive | Negative |')
      ..writeln('|---|---|---|---|---|');
    for (final capability in capabilities) {
      buffer.writeln(
        '| `${capability.capabilityId}` | `${capability.status.name}` | '
        '${_cell(capability.runtimeConsumer)} | '
        '${_cell(capability.positiveTest)} | '
        '${_cell(capability.negativeTest)} |',
      );
    }
    if (issues.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## Blocking issues');
      for (final issue in issues) {
        buffer.writeln(
          '- `${issue.code.name}` · `${issue.capabilityId}` · ${issue.message}',
        );
      }
    }
    return buffer.toString().trimRight();
  }
}

List<ProjectCapabilityTruthRecord> buildNarrativeCommandCapabilityTruthMatrix({
  NarrativeCommandCatalog? catalog,
  required ProjectCapabilityTruthAttestation authoring,
  required ProjectCapabilityTruthAttestation runtime,
  required ProjectCapabilityTruthAttestation playerSurface,
  required ProjectCapabilityTruthAttestation positiveTests,
  required ProjectCapabilityTruthAttestation negativeTests,
}) {
  final resolvedCatalog = catalog ?? NarrativeCommandCatalog.canonical();
  return List.unmodifiable([
    for (final command in resolvedCatalog.commands)
      if (command.isPublishable)
        ProjectCapabilityTruthRecord.promoted(
          capabilityId: narrativeCommandCapabilityId(command.id),
          authoringControl: authoring.referenceFor(command.id),
          contractField: command.wireId,
          runtimeConsumer: runtime.referenceFor(command.id),
          playerSurface: playerSurface.referenceFor(command.id),
          positiveTest: positiveTests.referenceFor(command.id),
          negativeTest: negativeTests.referenceFor(command.id),
        )
      else
        ProjectCapabilityTruthRecord.deferred(
          capabilityId: narrativeCommandCapabilityId(command.id),
          reason: command.capabilities.reason ??
              'The command is not supported across every required layer.',
        ),
  ]);
}

String narrativeCommandCapabilityId(String commandId) =>
    'narrative.command.$commandId';

Set<String> requiredNarrativeCommandCapabilityIds({
  NarrativeCommandCatalog? catalog,
}) =>
    Set.unmodifiable(
      (catalog ?? NarrativeCommandCatalog.canonical())
          .commands
          .map((command) => narrativeCommandCapabilityId(command.id)),
    );

void _requireReference(
  List<ProjectCapabilityTruthIssue> target,
  ProjectCapabilityTruthRecord record, {
  required String? value,
  required ProjectCapabilityTruthIssueCode code,
  required String label,
}) {
  if (!_isBlank(value)) return;
  target.add(
    ProjectCapabilityTruthIssue(
      code: code,
      capabilityId: record.capabilityId,
      message: 'Promoted capability requires a $label reference.',
    ),
  );
}

bool _isBlank(String? value) => value == null || value.trim().isEmpty;

String _cell(String? value) =>
    (value == null || value.trim().isEmpty ? '—' : value)
        .replaceAll('|', r'\|')
        .replaceAll('\n', ' ');
```

### A.2 `packages/map_core/test/project_capability_truth_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project capability truth gate', () {
    test('rejects a promoted capability without a runtime consumer', () {
      final report = ProjectCapabilityTruthReport.evaluate(
        [
          const ProjectCapabilityTruthRecord.promoted(
            capabilityId: 'trainer.difficulty',
            authoringControl: 'Trainer difficulty selector',
            contractField: 'TrainerDefinition.battleDifficulty',
            runtimeConsumer: '',
            playerSurface: 'Trainer battle',
            positiveTest: 'trainer_difficulty_runtime_test.dart',
            negativeTest: 'trainer_difficulty_unsupported_test.dart',
          ),
        ],
        requiredCapabilityIds: const {'trainer.difficulty'},
      );

      expect(report.isPassing, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.missingRuntimeConsumer),
      );
    });

    test('rejects a promoted capability without positive or negative proof',
        () {
      final report = ProjectCapabilityTruthReport.evaluate(
        [
          const ProjectCapabilityTruthRecord.promoted(
            capabilityId: 'trainer.difficulty',
            authoringControl: 'Trainer difficulty selector',
            contractField: 'TrainerDefinition.battleDifficulty',
            runtimeConsumer: 'TrainerBattleCoordinator',
            playerSurface: 'Trainer battle',
            positiveTest: '',
            negativeTest: '',
          ),
        ],
        requiredCapabilityIds: const {'trainer.difficulty'},
      );

      expect(report.isPassing, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        containsAll(<ProjectCapabilityTruthIssueCode>[
          ProjectCapabilityTruthIssueCode.missingPositiveTest,
          ProjectCapabilityTruthIssueCode.missingNegativeTest,
        ]),
      );
    });

    test('rejects duplicate capability ids', () {
      const record = ProjectCapabilityTruthRecord.deferred(
        capabilityId: 'battle.held-items',
        reason: 'Runtime bridge not delivered.',
      );

      final report = ProjectCapabilityTruthReport.evaluate(
        const [record, record],
        requiredCapabilityIds: const {'battle.held-items'},
      );

      expect(report.isPassing, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.duplicateCapabilityId),
      );
    });

    test('serializes deferred capabilities without pretending support', () {
      final report = ProjectCapabilityTruthReport.evaluate(
        const [
          ProjectCapabilityTruthRecord.deferred(
            capabilityId: 'battle.held-items',
            reason: 'Runtime bridge not delivered.',
          ),
        ],
        requiredCapabilityIds: const {'battle.held-items'},
      );

      expect(report.isPassing, isFalse);
      expect(
        report.issues.map((issue) => issue.code),
        contains(ProjectCapabilityTruthIssueCode.noPromotedCapabilities),
      );
      expect(
        report.toJson()['capabilities'],
        [
          {
            'capabilityId': 'battle.held-items',
            'authoringControl': null,
            'contractField': null,
            'runtimeConsumer': null,
            'playerSurface': null,
            'positiveTest': null,
            'negativeTest': null,
            'status': 'deferred',
            'reason': 'Runtime bridge not delivered.',
          },
        ],
      );
    });

    test('rejects empty and partial matrices against the required set', () {
      final empty = ProjectCapabilityTruthReport.evaluate(
        const [],
        requiredCapabilityIds: const {
          'narrative.command.setFact',
          'narrative.command.dialogue',
        },
      );
      final partial = ProjectCapabilityTruthReport.evaluate(
        const [
          ProjectCapabilityTruthRecord.promoted(
            capabilityId: 'narrative.command.setFact',
            authoringControl: 'authoring.dart#builder',
            contractField: 'setFact',
            runtimeConsumer: 'runtime.dart#writer',
            playerSurface: 'runtime.dart#surface',
            positiveTest: 'positive_test.dart#case',
            negativeTest: 'negative_test.dart#case',
          ),
        ],
        requiredCapabilityIds: const {
          'narrative.command.setFact',
          'narrative.command.dialogue',
        },
      );

      expect(empty.isPassing, isFalse);
      expect(
        empty.issues
            .where(
              (issue) =>
                  issue.code ==
                  ProjectCapabilityTruthIssueCode.missingExpectedCapability,
            )
            .map((issue) => issue.capabilityId),
        unorderedEquals(
          const {
            'narrative.command.setFact',
            'narrative.command.dialogue',
          },
        ),
      );
      expect(partial.isPassing, isFalse);
      expect(
        partial.issues.map((issue) => issue.capabilityId),
        contains('narrative.command.dialogue'),
      );
    });

    test('canonical narrative command matrix is complete and fail-closed', () {
      final catalog = NarrativeCommandCatalog.canonical();
      final attestation = _attestation(catalog);
      final matrix = buildNarrativeCommandCapabilityTruthMatrix(
        catalog: catalog,
        authoring: attestation,
        runtime: attestation,
        playerSurface: attestation,
        positiveTests: attestation,
        negativeTests: attestation,
      );
      final report = ProjectCapabilityTruthReport.evaluate(
        matrix,
        requiredCapabilityIds: requiredNarrativeCommandCapabilityIds(
          catalog: catalog,
        ),
      );

      expect(report.isPassing, isTrue, reason: report.agentMarkdown);
      expect(
        matrix
            .where(
              (record) =>
                  record.status == ProjectCapabilityTruthStatus.promoted,
            )
            .map((record) => record.capabilityId),
        unorderedEquals(
          catalog.publishable.map(
            (command) => 'narrative.command.${command.id}',
          ),
        ),
      );
      expect(
        matrix
            .singleWhere(
              (record) =>
                  record.capabilityId ==
                  'narrative.command.${NarrativeCommandIds.setNpcPresence}',
            )
            .status,
        ProjectCapabilityTruthStatus.deferred,
      );
    });
  });
}

ProjectCapabilityTruthAttestation _attestation(
  NarrativeCommandCatalog catalog,
) =>
    ProjectCapabilityTruthAttestation(
      referencesByCapabilityId: {
        for (final command in catalog.publishable)
          command.id: 'proof.dart#${command.id}',
      },
    );
```

### A.3 `packages/map_editor/lib/narrative_capability_evidence.dart`

```dart
library narrative_capability_evidence;

export 'src/ui/canvas/scenes/narrative_command_authoring_capability_evidence.dart'
    show buildMapEditorNarrativeCommandAuthoringAttestation;
```

### A.4 `packages/map_editor/lib/src/ui/canvas/scenes/narrative_command_authoring_capability_evidence.dart`

```dart
import 'package:map_core/map_core.dart';

import 'scene_action_builder.dart';

const _sceneActionBuilderPath = 'packages/map_editor/lib/src/ui/canvas/scenes/'
    'scene_action_builder.dart';

ProjectCapabilityTruthAttestation
    buildMapEditorNarrativeCommandAuthoringAttestation({
  NarrativeCommandCatalog? catalog,
}) {
  final resolvedCatalog = catalog ?? NarrativeCommandCatalog.canonical();
  const Type controlType = SceneActionBuilder;
  final controlSymbol = controlType.toString();
  return ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in resolvedCatalog.publishable)
        if (command.capabilities.editor ==
            NarrativeCommandCapabilityStatus.supported)
          command.id: '$_sceneActionBuilderPath#$controlSymbol',
    },
  );
}
```

### A.5 `packages/map_runtime/lib/src/application/scene_runtime/narrative_command_runtime_capability_evidence.dart`

```dart
import 'package:map_core/map_core.dart';

import 'scene_consequence_runtime_writer.dart';
import 'scene_interactive_command_runtime_executor.dart';
import 'scene_runtime_host_callbacks.dart';

ProjectCapabilityTruthAttestation
    buildMapRuntimeNarrativeCommandConsumerAttestation({
  NarrativeCommandCatalog? catalog,
}) {
  final resolvedCatalog = catalog ?? NarrativeCommandCatalog.canonical();
  return ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in resolvedCatalog.publishable)
        if (command.capabilities.runtime ==
            NarrativeCommandCapabilityStatus.supported)
          command.id: _runtimeReference(command.backend),
    },
  );
}

String _runtimeReference(NarrativeCommandBackend backend) {
  const base = 'packages/map_runtime/lib/src/application/scene_runtime/';
  final (fileName, Type runtimeType) = switch (backend) {
    NarrativeCommandBackend.sceneConsequence => (
        'scene_consequence_runtime_writer.dart',
        SceneConsequenceRuntimeWriter
      ),
    NarrativeCommandBackend.interactiveRuntimeCommand => (
        'scene_interactive_command_runtime_executor.dart',
        SceneInteractiveCommandRuntimeExecutor,
      ),
    NarrativeCommandBackend.dedicatedSceneNode => (
        'scene_runtime_host_callbacks.dart',
        SceneRuntimeHostCallbacks
      ),
  };
  return '$base$fileName#${runtimeType.toString()}';
}
```

### A.6 `packages/map_runtime/lib/src/presentation/flame/narrative_command_player_surface_capability_evidence.dart`

```dart
import 'package:map_core/map_core.dart';

import 'playable_map_game.dart';

const _playableMapGamePath =
    'packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart';

ProjectCapabilityTruthAttestation
    buildMapRuntimeNarrativeCommandPlayerSurfaceAttestation({
  NarrativeCommandCatalog? catalog,
}) {
  final resolvedCatalog = catalog ?? NarrativeCommandCatalog.canonical();
  const Type playerSurfaceType = PlayableMapGame;
  final playerSurfaceSymbol = playerSurfaceType.toString();
  return ProjectCapabilityTruthAttestation(
    referencesByCapabilityId: {
      for (final command in resolvedCatalog.publishable)
        if (command.capabilities.runtime ==
            NarrativeCommandCapabilityStatus.supported)
          command.id: '$_playableMapGamePath#$playerSurfaceSymbol',
    },
  );
}
```
