# NSC-02 — Transactions atomiques d’authoring narratif

Date de clôture technique : 2026-07-19  
Branche : `main`  
Lot : **NSC-02 — Transactions atomiques d’authoring narratif**  
Statut proposé : **DONE**

## Résumé exécutif

NSC-02 introduit une frontière transactionnelle partagée entre `map_core` et
`map_editor` pour créer, modifier, cloner et supprimer un asset narratif sans
annoncer une sauvegarde avant sa confirmation disque. Le pilote fonctionnel est
la bibliothèque des cinématiques : ses opérations de création, d’édition de
métadonnées et de suppression utilisent désormais la même mutation pure,
validation stricte, détection de dépendances, compare-and-swap et écriture
atomique.

La clôture est proposée parce que les invariants du lot sont prouvés par des
tests ciblés et les suites complètes : **3 116 tests `map_core`** et
**3 428 tests `map_editor`**, analyses statiques sans diagnostic, format
inchangé, diff propre et build macOS debug réussi.

## Scope confirmé

Inclus :

- résultats immuables `Created / Updated / Deleted / Rejected / NoChange` ;
- génération d’identifiants de cinématiques stable et résistante aux collisions ;
- mise à jour à identifiant stable et clonage intégral sans réécriture implicite ;
- suppression bloquée lorsqu’un chemin canonique dépend de l’asset ;
- remplacement explicite avec réécriture de toutes les références
  `SceneCinematicPayload`, validation des types et réindexation postcondition ;
- transaction applicative et passerelle de persistance partagées ;
- compare-and-swap sémantique et octet, verrou partagé, fichier temporaire dans
  le même dossier, flush, hash, rename et vérification finale ;
- conservation des champs inconnus à la racine et du registre Event brut ;
- protections contre symlink, double exécution, changement de session projet,
  sauvegarde générique concurrente et faux succès après échec ;
- branchement de la bibliothèque Cinématiques au flux transactionnel ;
- retours UI honnêtes lorsque la mutation reste locale et non enregistrée.

Hors scope volontaire :

- l’édition de la timeline, des acteurs et des bindings cinématiques reste sur
  le flux historique en mémoire ;
- l’élargissement aux Storylines, Scenes, Events et Dialogues appartient aux lots
  d’authoring spécialisés ultérieurs ;
- une reprise automatique après conflit/erreur d’I/O n’est pas fournie : un
  rechargement sûr du projet est encore requis ;
- le codec Event strict continue à rejeter les champs inconnus internes au
  registre Event ; seule la racine du manifeste et le registre brut déjà pris
  en charge sont préservés.

## Audit initial

### Contrats et fichiers repérés

- `map_core` possédait déjà les opérations cinématiques historiques, le
  validateur de projet, les payloads de Scene et, depuis NSC-01, l’index canonique
  des dépendances narratives.
- `map_editor` possédait plusieurs chemins de sauvegarde spécialisés, mais pas
  de contrat transactionnel commun pour l’authoring narratif.
- la bibliothèque Cinématiques appliquait les changements en mémoire et pouvait
  afficher un succès sans confirmation de persistance ;
- le repository fichier possédait déjà le verrou et la barrière de récupération
  du registre Event : ils devaient être réutilisés pour éviter deux domaines de
  concurrence indépendants.

### Risques identifiés avant modification

1. écrasement d’une révision externe entre lecture et écriture ;
2. faux succès UI si le disque refuse la mutation ;
3. sauvegarde générique contournant le compare-and-swap après un échec ;
4. résultat asynchrone d’un ancien projet appliqué à une nouvelle session ;
5. symlink remplacé au lieu de mettre à jour sa cible ;
6. exception après rename laissant un résultat disque ambigu ;
7. suppression d’une cinématique encore référencée ;
8. perte des champs inconnus ou du registre Event lors du round-trip.

### Décision d’architecture

La stricte validation `ProjectValidator` est conservée. Le lot n’autorise pas
une mutation sur un manifeste déjà invalide afin de ne pas rendre persistante une
dette de validation silencieuse. Les fixtures UI historiques invalides ont été
réduites au sous-ensemble canonique nécessaire dans les tests, sans assouplir le
contrat produit.

## État git initial

Les changements suivants existaient avant NSC-02 et ont été explicitement
exclus du lot :

```text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
```

Le fichier `selbrume_lighthouse_retry_integration_test.dart` était déjà indexé.
Le commit de NSC-02 utilisera `git commit --only` avec la liste exacte des
fichiers du lot afin de le laisser indexé sans le committer.

## Inventaire des fichiers du lot et zones précises

| Fichier | Zone modifiée ou créée | Raison et impact |
|---|---|---|
| `packages/map_core/lib/map_core.dart` | exports authoring | Expose les nouveaux contrats publics de mutation/réécriture. |
| `packages/map_core/lib/src/authoring/narrative_asset_mutation.dart` | fichier complet ; résultats scellés et CRUD cinématique | Porte la mutation pure, la validation, les IDs, dépendances et postconditions. |
| `packages/map_core/lib/src/authoring/narrative_reference_rewrite.dart` | fichier complet ; valeur `replaceWith` | Rend le remplacement explicite et non nullable. |
| `packages/map_core/test/narrative_asset_mutation_test.dart` | fichier complet | Prouve chemins positifs, refus, ambiguïtés, clonage intégral et réécriture. |
| `packages/map_editor/lib/src/application/models/narrative_authoring_transaction.dart` | fichier complet | Modélise snapshot avant/après, statuts de persistance et résultat applicatif. |
| `packages/map_editor/lib/src/application/ports/narrative_authoring_persistence_gateway.dart` | fichier complet | Définit le port applicatif sans dépendance infrastructure. |
| `packages/map_editor/lib/src/application/use_cases/execute_narrative_authoring_transaction.dart` | fichier complet ; `execute` | Classe les no-op/refus avant le verrou busy et sérialise les écritures applicables. |
| `packages/map_editor/lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart` | fichier complet ; `persist`, `_persistLocked`, checkpoints | Implémente CAS, verrou partagé, écriture atomique, symlink canonique et récupération. |
| `packages/map_editor/lib/src/app/providers/core/repository_providers.dart` | providers de passerelle et use case | Fournit des singletons partageables par les workspaces. |
| `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart` | constructeur et getter du repository projet | Branche la persistance atomique sur le repository et ses verrous Event existants. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | identité de session, interlock, `executeNarrativeAuthoringMutation`, garde de sauvegarde | Rend la mutation visible/dirty avant écriture, propre seulement après commit exact, et empêche les faux succès/écrasements. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | callbacks create/update/delete Cinématiques | Remplace l’application en mémoire directe par la transaction partagée. |
| `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart` | suppression référencée et messages d’échec | Laisse la transaction expliquer le refus et ne ment plus sur l’enregistrement. |
| `packages/map_editor/test/atomic_project_manifest_persistence_test.dart` | fichier complet | Couvre CAS, octets, symlink, checkpoints, rename ambigu, champs inconnus et récupération. |
| `packages/map_editor/test/narrative_authoring_transaction_test.dart` | fichier complet | Couvre classification, busy, notifier, dirty state, session switch et interlock. |
| `packages/map_editor/test/cinematics_library_workspace_test.dart` | scénario de suppression référencée | Vérifie le refus visible et la conservation de l’asset. |
| `packages/map_editor/test/editor_shell_page_smoke_test.dart` | raccourci sauvegarde + repository mémoire immédiat | Isole le comportement du raccourci sans I/O réel dans la fake-time Flutter. |
| `packages/map_editor/test/ui/canvas/narrative_studio_cinematics_route_test.dart` | CRUD persistant et retry no-op après échec | Prouve le flux UI→notifier→gateway→disque et l’absence de faux “sauvegardé”. |

### Découpage des modifications existantes

- `map_core.dart` : ajout de deux exports contigus dans le barrel authoring.
- `repository_providers.dart` : ajout des imports puis de
  `narrativeAuthoringPersistenceGatewayProvider` et
  `executeNarrativeAuthoringTransactionProvider`.
- `file_repositories.dart` : ajout du champ/initialiseur/getter de
  `AtomicProjectManifestPersistence`, en réutilisant verrou et recovery gate.
- `editor_notifier.dart` : ajout des trois états privés de lease/session/interlock,
  réinitialisation lors de create/load, méthode transactionnelle, garde
  `saveProjectManifest`, contrôle d’identité avant adoption et type privé
  `_NarrativeAuthoringSaveInterlock`.
- `narrative_workspace_canvas.dart` : remplacement des trois callbacks
  Cinématiques ; suppression du générateur d’ID local au profit du cœur.
- `cinematics_library_workspace.dart` : le bouton de suppression reste
  actionnable pour fournir un diagnostic canonique ; messages de création,
  édition et suppression reformulés pour distinguer succès et mutation locale.
- tests existants : assertions adaptées uniquement aux nouveaux contrats et
  scénarios de non-régression ajoutés.

## Tests créés ou modifiés

### Créés

- `narrative_asset_mutation_test.dart` : 13 tests ciblés.
- `atomic_project_manifest_persistence_test.dart` et
  `narrative_authoring_transaction_test.dart` : 22 tests ciblés combinés lors
  de la dernière passe infrastructure/application.

### Modifiés

- `cinematics_library_workspace_test.dart` ;
- `editor_shell_page_smoke_test.dart` ;
- `narrative_studio_cinematics_route_test.dart`, dont deux scénarios
  d’intégration : CRUD confirmé disque et échec suivi d’un retry no-op honnête.

## Commandes et résultats exacts

### Tests ciblés finaux

```text
cd packages/map_core
dart test test/narrative_asset_mutation_test.dart
+13: All tests passed!
```

```text
cd packages/map_editor
flutter test --concurrency=1 test/narrative_authoring_transaction_test.dart test/atomic_project_manifest_persistence_test.dart test/cinematics_library_workspace_test.dart test/ui/canvas/narrative_studio_cinematics_route_test.dart test/editor_shell_page_smoke_test.dart
+63: All tests passed!
```

Après les correctifs de sûreté CAS/session :

```text
flutter test --concurrency=1 test/narrative_authoring_transaction_test.dart test/atomic_project_manifest_persistence_test.dart
+22: All tests passed!
```

Après le correctif du faux succès dirty/no-op :

```text
flutter test --concurrency=1 test/narrative_authoring_transaction_test.dart test/ui/canvas/narrative_studio_cinematics_route_test.dart
+20: All tests passed!
```

### Suites complètes finales

```text
cd packages/map_core
dart test
+3116: All tests passed!
```

```text
cd packages/map_editor
flutter test
+3428: All tests passed!
```

### Analyse statique finale

```text
cd packages/map_core
dart analyze
No issues found!
```

```text
cd packages/map_editor
flutter analyze
Analyzing map_editor...
No issues found! (ran in 5.4s)
```

### Format et hygiène finale

```text
cd packages/map_core
dart format --output=none --set-exit-if-changed [4 fichiers du lot]
Formatted 4 files (0 changed) in 0.03 seconds.
```

```text
cd packages/map_editor
dart format --output=none --set-exit-if-changed [14 fichiers du lot]
Formatted 14 files (0 changed) in 0.22 seconds.
```

```text
git diff --check
(exit 0, aucune sortie)
```

### Build final

```text
cd packages/map_editor
flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

### Échecs intermédiaires documentés

- Les premières suites complètes `map_core` se sont arrêtées vers
  `+1639 -108` avec des erreurs de chargement `No space left on device` :
  ce n’était pas un défaut logique du lot. `flutter clean` a été exécuté
  uniquement dans `examples/playable_runtime_host` pour supprimer ses
  artefacts ignorés ; la relance séquentielle puis la relance finale ont atteint
  `+3116`.
- Une première suite complète `map_editor` a fini à `+3422 -1` sur un
  timeout `pumpAndSettle` dans `editor_shell_page_smoke_test.dart`. L’I/O
  fichier réelle, démarrée depuis la zone fake-time Flutter après l’ajout de
  l’état `isSaving`, ne pouvait pas progresser correctement. Le test de
  raccourci utilise désormais un repository mémoire immédiat ; la vraie
  persistance est couverte séparément. La relance intermédiaire a atteint
  `+3423`, puis la suite finale enrichie `+3428`.

## Passes sub-agents et verdicts

| Passe | Audit initial / remarques | Verdict final |
|---|---|---|
| Audit / Architecture | A confirmé l’index NSC-01 comme source canonique et la bibliothèque Cinématiques comme pilote le plus petit. | PASS |
| Implémentation cœur | A contrôlé création, update, clone, delete, réécriture et immutabilité. | PASS, aucun résidu |
| Implémentation persistance/concurrence | A initialement trouvé : contournement CAS par sauvegarde générique, fork de symlink, ambiguïté après rename, contamination entre sessions, mauvais ordre busy/no-op. Tous ont été corrigés et retestés. | PASS, aucun P0–P3 |
| Tests / critique produit | A initialement trouvé qu’un retry no-op sur snapshot dirty pouvait afficher un faux succès. Le notifier et le widget test ont été corrigés. | PASS |
| Build / Validation | A vérifié tests ciblés, suites complètes, analyses, format, diff et build macOS. | PASS |
| Critique finale | A recherché scope mélangé, effets de bord, faux messages, comportements non prouvés et fichiers accidentels. | PASS avec limites déclarées |

## État git final avant commit

Snapshot immédiatement avant l’indexation sélective du lot :

```text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_core/lib/map_core.dart
 M packages/map_editor/lib/src/app/providers/core/repository_providers.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/test/ui/canvas/narrative_studio_cinematics_route_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? packages/map_core/lib/src/authoring/narrative_asset_mutation.dart
?? packages/map_core/lib/src/authoring/narrative_reference_rewrite.dart
?? packages/map_core/test/narrative_asset_mutation_test.dart
?? packages/map_editor/lib/src/application/models/narrative_authoring_transaction.dart
?? packages/map_editor/lib/src/application/ports/narrative_authoring_persistence_gateway.dart
?? packages/map_editor/lib/src/application/use_cases/execute_narrative_authoring_transaction.dart
?? packages/map_editor/lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart
?? packages/map_editor/test/atomic_project_manifest_persistence_test.dart
?? packages/map_editor/test/narrative_authoring_transaction_test.dart
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
?? reports/narrativeStudio/completion/nsc_02_atomic_authoring_transactions_evidence_pack.md
```

Après commit sélectif, les 18 fichiers de code/test et ce rapport doivent
disparaître de ce statut ; les changements Selbrume préexistants doivent rester
strictement inchangés, y compris le fichier déjà indexé.

## Limites conservées

1. Le pilote porte uniquement sur create/update métadonnées/delete de la
   bibliothèque Cinématiques.
2. Timeline, acteurs et bindings utilisent encore les flux historiques.
3. Après échec de persistance, la sûreté prime : la sauvegarde générique est
   interlockée et l’utilisateur doit recharger. Il n’existe pas encore de
   résolution interactive de conflit ou de retry CAS.
4. Une mutation locale après échec peut donc être perdue volontairement au
   rechargement si l’utilisateur ne la reporte pas manuellement.
5. L’atomicité concerne le manifeste `project.json`, pas une transaction
   multi-fichiers généralisée.

## Auto-critique finale

La solution est plus volumineuse qu’un simple branchement CRUD, car une
persistance déclarée “atomique” sans garde de session, CAS et comportement
post-rename aurait été trompeuse. Cette complexité est maintenant concentrée
derrière un port et un use case uniques. Le coût principal restant est
l’ergonomie de récupération : l’interlock protège les données externes, mais ne
propose pas encore de comparaison ni de fusion guidée des snapshots.

Le test du raccourci de sauvegarde est intentionnellement un test unitaire avec
repository immédiat. Il ne remplace pas les tests d’intégration du gateway
atomique ; les deux niveaux sont nécessaires et présents.

Aucun fichier Selbrume préexistant n’est intégré au scope ou au commit NSC-02.

## Risques restants

- les futurs workspaces pourraient contourner la transaction s’ils appellent
  encore `applyInMemoryProjectManifest` directement ;
- l’extension multi-asset demandera une politique de réécriture propre à chaque
  type, sans transformer le cœur en switch monolithique ;
- la conservation d’inconnus à l’intérieur du registre Event reste limitée par
  son codec strict existant ;
- le callback de récupération doit devenir visible et actionnable avant de
  généraliser le flux à des éditeurs plus complexes.

## Prochaines étapes proposées, non implémentées dans ce lot

1. NSC-10 : navigation narrative typée et contexte de retour.
2. NSC-11 : liens “ouvrir la dépendance” depuis l’index canonique.
3. NSC-12 : navigation secondaire cohérente dans tous les workspaces.
4. NSC-13 : durcissement responsive, focus, raccourcis et états vides.
5. Étendre la transaction aux prochains lots d’authoring après stabilisation du
   modèle de navigation.

## Annexe — contenu complet des fichiers créés

### `packages/map_core/lib/src/authoring/narrative_asset_mutation.dart`

```dart
import 'package:meta/meta.dart' show immutable;

import '../models/cinematic_asset.dart';
import '../models/project_manifest.dart';
import '../models/scene_asset.dart';
import '../read_models/narrative_dependency_index.dart';
import '../validation/validators.dart';
import 'narrative_reference_rewrite.dart';
import 'scene_authoring_operations.dart';

@immutable
sealed class NarrativeAssetMutationResult {
  const NarrativeAssetMutationResult({
    required this.before,
    required this.after,
  });

  final ProjectManifest before;
  final ProjectManifest after;

  bool get isApplicable =>
      this is NarrativeAssetCreated ||
      this is NarrativeAssetUpdated ||
      this is NarrativeAssetDeleted;
}

@immutable
final class NarrativeAssetCreated extends NarrativeAssetMutationResult {
  const NarrativeAssetCreated({
    required super.before,
    required super.after,
    required this.asset,
  });

  final CinematicAsset asset;
}

@immutable
final class NarrativeAssetUpdated extends NarrativeAssetMutationResult {
  const NarrativeAssetUpdated({
    required super.before,
    required super.after,
    required this.previousAsset,
    required this.asset,
  });

  final CinematicAsset previousAsset;
  final CinematicAsset asset;
}

@immutable
final class NarrativeAssetDeleted extends NarrativeAssetMutationResult {
  NarrativeAssetDeleted({
    required super.before,
    required super.after,
    required this.asset,
    Iterable<String> rewrittenReferencePaths = const <String>[],
  }) : rewrittenReferencePaths = List<String>.unmodifiable(
          rewrittenReferencePaths,
        );

  final CinematicAsset asset;
  final List<String> rewrittenReferencePaths;
}

@immutable
final class NarrativeAssetRejected extends NarrativeAssetMutationResult {
  NarrativeAssetRejected({
    required ProjectManifest project,
    required this.code,
    required this.message,
    Iterable<String> referencePaths = const <String>[],
  })  : referencePaths = List<String>.unmodifiable(referencePaths),
        super(before: project, after: project);

  final String code;
  final String message;
  final List<String> referencePaths;
}

@immutable
final class NarrativeAssetNoChange extends NarrativeAssetMutationResult {
  const NarrativeAssetNoChange({
    required ProjectManifest project,
    required this.asset,
    required this.reason,
  }) : super(before: project, after: project);

  final CinematicAsset asset;
  final String reason;
}

/// Pure, Cinematic-only mutation boundary for Narrative Studio authoring.
///
/// Other narrative asset families deliberately remain unsupported until they
/// migrate to the same validate/persist/publish transaction contract.
abstract final class NarrativeAssetMutation {
  static NarrativeAssetMutationResult createCinematic(
    ProjectManifest project, {
    required String title,
    String? description,
  }) {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      return _rejected(
        project,
        code: 'blankTitle',
        message: 'A cinematic title is required.',
      );
    }
    try {
      final asset = CinematicAsset(
        id: _nextCinematicId(project, cleanTitle),
        title: cleanTitle,
        description: _trimOptional(description),
        timeline: CinematicTimeline(),
      );
      final after = project.copyWith(
        cinematics: [...project.cinematics, asset],
      );
      ProjectValidator.validate(after);
      return NarrativeAssetCreated(
        before: project,
        after: after,
        asset: asset,
      );
    } on Object catch (error) {
      return _invalidProjection(project, error);
    }
  }

  static NarrativeAssetMutationResult updateCinematic(
    ProjectManifest project, {
    required String cinematicId,
    required CinematicAsset cinematic,
  }) {
    final id = cinematicId.trim();
    if (id != cinematic.id) {
      return _rejected(
        project,
        code: 'idMismatch',
        message: 'A cinematic update cannot change its stable id.',
      );
    }
    final matches =
        project.cinematics.where((asset) => asset.id == id).toList();
    if (matches.isEmpty) {
      return _rejected(
        project,
        code: 'assetNotFound',
        message: 'The cinematic to update does not exist.',
      );
    }
    if (matches.length > 1) {
      return _rejected(
        project,
        code: 'assetIdAmbiguous',
        message: 'The cinematic id is ambiguous.',
      );
    }
    final previous = matches.single;
    if (previous == cinematic) {
      return NarrativeAssetNoChange(
        project: project,
        asset: previous,
        reason: 'The cinematic already has these values.',
      );
    }
    try {
      final after = project.copyWith(
        cinematics: [
          for (final asset in project.cinematics)
            if (asset.id == id) cinematic else asset,
        ],
      );
      ProjectValidator.validate(after);
      return NarrativeAssetUpdated(
        before: project,
        after: after,
        previousAsset: previous,
        asset: cinematic,
      );
    } on Object catch (error) {
      return _invalidProjection(project, error);
    }
  }

  static NarrativeAssetMutationResult cloneCinematic(
    ProjectManifest project, {
    required String cinematicId,
    String? title,
  }) {
    final matches = project.cinematics
        .where((asset) => asset.id == cinematicId.trim())
        .toList();
    if (matches.isEmpty) {
      return _rejected(
        project,
        code: 'assetNotFound',
        message: 'The cinematic to clone does not exist.',
      );
    }
    if (matches.length > 1) {
      return _rejected(
        project,
        code: 'assetIdAmbiguous',
        message: 'The cinematic id is ambiguous.',
      );
    }
    final source = matches.single;
    final cloneTitle = title?.trim().isNotEmpty == true
        ? title!.trim()
        : '${source.title} (copie)';
    try {
      final clone = CinematicAsset(
        id: _nextCinematicId(project, cloneTitle),
        title: cloneTitle,
        description: source.description,
        storylineId: source.storylineId,
        chapterId: source.chapterId,
        mapId: source.mapId,
        tags: source.tags,
        requiredActors: source.requiredActors,
        movementTargets: source.movementTargets,
        stageContext: source.stageContext,
        timeline: source.timeline,
        notes: source.notes,
        metadata: source.metadata,
        legacyBridge: source.legacyBridge,
      );
      final after = project.copyWith(
        cinematics: [...project.cinematics, clone],
      );
      ProjectValidator.validate(after);
      return NarrativeAssetCreated(
        before: project,
        after: after,
        asset: clone,
      );
    } on Object catch (error) {
      return _invalidProjection(project, error);
    }
  }

  static NarrativeAssetMutationResult deleteCinematic(
    ProjectManifest project, {
    required String cinematicId,
    NarrativeReferenceRewrite rewrite =
        const NarrativeReferenceRewrite.rejectIfReferenced(),
  }) {
    final id = cinematicId.trim();
    final matches =
        project.cinematics.where((asset) => asset.id == id).toList();
    if (matches.isEmpty) {
      return _rejected(
        project,
        code: 'assetNotFound',
        message: 'The cinematic to delete does not exist.',
      );
    }
    if (matches.length > 1) {
      return _rejected(
        project,
        code: 'assetIdAmbiguous',
        message: 'The cinematic id is ambiguous.',
      );
    }

    final source = matches.single;
    final references = _cinematicReferencePaths(project, id);
    final replacementId = rewrite.replacementAssetId?.trim();
    if (references.isNotEmpty && rewrite.rejectsReferences) {
      return NarrativeAssetRejected(
        project: project,
        code: 'assetReferenced',
        message: 'The cinematic is still referenced by Scene nodes.',
        referencePaths: references,
      );
    }
    if (replacementId != null) {
      if (replacementId.isEmpty) {
        return _rejected(
          project,
          code: 'rewriteTargetMissing',
          message: 'A replacement cinematic id is required.',
        );
      }
      if (replacementId == id) {
        return _rejected(
          project,
          code: 'selfRewrite',
          message: 'A cinematic cannot replace itself during deletion.',
        );
      }
      final replacements = project.cinematics
          .where((asset) => asset.id == replacementId)
          .toList();
      if (replacements.isEmpty) {
        final replacementExistsInAnotherNamespace =
            buildNarrativeDependencyIndex(project: project).definitions.any(
                  (definition) =>
                      definition.key.id == replacementId &&
                      definition.key.kind !=
                          NarrativeDependencyTargetKind.cinematic,
                );
        return _rejected(
          project,
          code: replacementExistsInAnotherNamespace
              ? 'rewriteTargetTypeMismatch'
              : 'rewriteTargetMissing',
          message: replacementExistsInAnotherNamespace
              ? 'The replacement id belongs to another asset type.'
              : 'The replacement cinematic does not exist.',
        );
      }
      if (replacements.length > 1) {
        return _rejected(
          project,
          code: 'rewriteTargetAmbiguous',
          message: 'The replacement cinematic id is ambiguous.',
        );
      }
    }

    try {
      var rewrittenScenes = project.scenes;
      if (replacementId != null && references.isNotEmpty) {
        rewrittenScenes = [
          for (final scene in project.scenes)
            _rewriteSceneCinematicReferences(
              scene,
              sourceId: id,
              replacementId: replacementId,
              project: project,
            ),
        ];
      }
      final after = project.copyWith(
        cinematics: [
          for (final asset in project.cinematics)
            if (asset.id != id) asset,
        ],
        scenes: rewrittenScenes,
      );
      if (_cinematicReferencePaths(after, id).isNotEmpty) {
        return _rejected(
          project,
          code: 'unsupportedReferenceRewrite',
          message: 'At least one cinematic reference could not be rewritten.',
        );
      }
      ProjectValidator.validate(after);
      return NarrativeAssetDeleted(
        before: project,
        after: after,
        asset: source,
        rewrittenReferencePaths:
            replacementId == null ? const <String>[] : references,
      );
    } on Object catch (error) {
      return _invalidProjection(project, error);
    }
  }
}

NarrativeAssetRejected _rejected(
  ProjectManifest project, {
  required String code,
  required String message,
}) {
  return NarrativeAssetRejected(
    project: project,
    code: code,
    message: message,
  );
}

NarrativeAssetRejected _invalidProjection(
  ProjectManifest project,
  Object error,
) {
  return _rejected(
    project,
    code: 'invalidProjectedProject',
    message: 'The projected project is invalid: $error',
  );
}

List<String> _cinematicReferencePaths(
  ProjectManifest project,
  String cinematicId,
) {
  final key = NarrativeDependencyKey(
    NarrativeDependencyTargetKind.cinematic,
    cinematicId,
  );
  return buildNarrativeDependencyIndex(project: project)
      .usagesFor(key)
      .map((usage) => usage.path)
      .toList(growable: false);
}

SceneAsset _rewriteSceneCinematicReferences(
  SceneAsset source, {
  required String sourceId,
  required String replacementId,
  required ProjectManifest project,
}) {
  var scene = source;
  final nodeIds = [
    for (final node in source.graph.nodes)
      if (node.payload case SceneCinematicPayload(:final cinematicId))
        if (cinematicId == sourceId) node.id,
  ];
  for (final nodeId in nodeIds) {
    scene = updateSceneCinematicPayload(
      scene,
      nodeId: nodeId,
      cinematicId: replacementId,
      project: project,
    ).updatedScene;
  }
  return scene;
}

String _nextCinematicId(ProjectManifest project, String title) {
  final slug = title
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  final base = slug.isEmpty ? 'cinematic' : 'cinematic_$slug';
  final existingIds = project.cinematics.map((asset) => asset.id).toSet();
  if (!existingIds.contains(base)) return base;
  var index = 2;
  while (existingIds.contains('${base}_$index')) {
    index++;
  }
  return '${base}_$index';
}

String? _trimOptional(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
```

### `packages/map_core/lib/src/authoring/narrative_reference_rewrite.dart`

```dart
import 'package:meta/meta.dart' show immutable;

/// Explicit policy used when deleting an authored narrative asset.
///
/// Deletion is conservative by default. References are only rewritten when a
/// caller provides a canonical replacement asset id.
@immutable
final class NarrativeReferenceRewrite {
  const NarrativeReferenceRewrite.rejectIfReferenced()
      : replacementAssetId = null;

  const NarrativeReferenceRewrite.replaceWith(String this.replacementAssetId);

  final String? replacementAssetId;

  bool get rejectsReferences => replacementAssetId == null;
}
```

### `packages/map_core/test/narrative_asset_mutation_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeAssetMutation cinematic assets', () {
    test('create trims the title and generates a collision-safe stable id', () {
      final project = _project(
        cinematics: [
          _cinematic(id: 'cinematic_port_intro', title: 'Existing'),
          _cinematic(id: 'cinematic_port_intro_2', title: 'Existing copy'),
        ],
      );

      final result = NarrativeAssetMutation.createCinematic(
        project,
        title: '  Port Intro  ',
      );

      expect(result, isA<NarrativeAssetCreated>());
      final created = result as NarrativeAssetCreated;
      expect(created.asset.id, 'cinematic_port_intro_3');
      expect(created.asset.title, 'Port Intro');
      expect(created.before, same(project));
      expect(created.after.cinematics.last, same(created.asset));
      expect(project.cinematics, hasLength(2));
    });

    test('create rejects a blank title without changing project identity', () {
      final project = _project();

      final result = NarrativeAssetMutation.createCinematic(
        project,
        title: '   ',
      );

      expect(result, isA<NarrativeAssetRejected>());
      expect(result.before, same(project));
      expect(result.after, same(project));
      expect((result as NarrativeAssetRejected).code, 'blankTitle');
    });

    test('update keeps the id stable and returns NoChange for equality', () {
      final original = _cinematic(id: 'cinematic_intro', title: 'Intro');
      final project = _project(cinematics: [original]);
      final updated = _cinematic(id: original.id, title: 'Opening');

      final changed = NarrativeAssetMutation.updateCinematic(
        project,
        cinematicId: original.id,
        cinematic: updated,
      );
      final unchanged = NarrativeAssetMutation.updateCinematic(
        changed.after,
        cinematicId: original.id,
        cinematic: updated,
      );

      expect(changed, isA<NarrativeAssetUpdated>());
      expect(changed.after.cinematics.single.id, original.id);
      expect(changed.after.cinematics.single.title, 'Opening');
      expect(unchanged, isA<NarrativeAssetNoChange>());
      expect(unchanged.after, same(changed.after));
    });

    test('update rejects an id mismatch and an unknown cinematic', () {
      final project = _project(
        cinematics: [_cinematic(id: 'cinematic_intro')],
      );

      final mismatch = NarrativeAssetMutation.updateCinematic(
        project,
        cinematicId: 'cinematic_intro',
        cinematic: _cinematic(id: 'cinematic_other'),
      );
      final missing = NarrativeAssetMutation.updateCinematic(
        project,
        cinematicId: 'cinematic_missing',
        cinematic: _cinematic(id: 'cinematic_missing'),
      );

      expect(mismatch, isA<NarrativeAssetRejected>());
      expect((mismatch as NarrativeAssetRejected).code, 'idMismatch');
      expect(mismatch.after, same(project));
      expect((missing as NarrativeAssetRejected).code, 'assetNotFound');
      expect(missing.after, same(project));
    });

    test('clone gets a new id and does not retarget external references', () {
      final source = CinematicAsset(
        id: 'cinematic_intro',
        title: 'Intro',
        description: 'Ouverture complète',
        storylineId: 'story_main',
        chapterId: 'chapter_port',
        mapId: 'map_port',
        tags: const ['intro', 'port'],
        requiredActors: [
          CinematicActorRef(
            actorId: 'actor_rival',
            label: 'Rival',
            entityId: 'npc_rival',
            role: 'opponent',
          ),
        ],
        movementTargets: [
          CinematicMovementTargetRef(
            targetId: 'target_quay',
            label: 'Quai',
            description: 'Point de rendez-vous',
          ),
        ],
        stageContext: CinematicStageContext(
          backdropMode: CinematicStageBackdropMode.projectMap,
        ),
        timeline: CinematicTimeline(
          steps: [
            CinematicTimelineStep(
              id: 'wait_1',
              kind: CinematicTimelineStepKind.wait,
              durationMs: 250,
            ),
          ],
        ),
        notes: 'Ne pas déplacer le rival.',
        metadata: const {'camera': 'wide'},
        legacyBridge: CinematicLegacyBridge(
          sourceKind: CinematicLegacyBridgeSourceKind.cutsceneStudio,
          scenarioId: 'legacy_intro',
          cutsceneSchema: 'cutscene_v2',
          notes: 'Provenance uniquement.',
        ),
      );
      final project = _project(
        cinematics: [source],
        scenes: [
          _sceneWithCinematics('scene_intro', [source.id])
        ],
      );

      final result = NarrativeAssetMutation.cloneCinematic(
        project,
        cinematicId: source.id,
      );

      expect(result, isA<NarrativeAssetCreated>());
      final created = result as NarrativeAssetCreated;
      expect(created.asset.id, 'cinematic_intro_copie');
      expect(created.asset.title, 'Intro (copie)');
      expect(
        created.asset.toJson(),
        Map<String, dynamic>.from(source.toJson())
          ..['id'] = 'cinematic_intro_copie'
          ..['title'] = 'Intro (copie)',
      );
      expect(
        created.after.scenes.single.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneCinematicPayload>()
            .single
            .cinematicId,
        source.id,
      );
    });

    test('delete rejects every reference path by default', () {
      final project = _referencedProject();

      final result = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
      );

      expect(result, isA<NarrativeAssetRejected>());
      final rejected = result as NarrativeAssetRejected;
      expect(rejected.code, 'assetReferenced');
      expect(rejected.after, same(project));
      expect(rejected.referencePaths, [
        'scenes[scene_a].graph.nodes[1].payload.cinematicId',
        'scenes[scene_b].graph.nodes[1].payload.cinematicId',
        'scenes[scene_b].graph.nodes[2].payload.cinematicId',
      ]);
    });

    test('delete with replaceWith rewrites all SceneCinematicPayload refs', () {
      final project = _referencedProject();

      final result = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_replacement',
        ),
      );

      expect(result, isA<NarrativeAssetDeleted>());
      final deleted = result as NarrativeAssetDeleted;
      expect(
        deleted.after.cinematics.map((asset) => asset.id),
        ['cinematic_replacement'],
      );
      expect(deleted.rewrittenReferencePaths, hasLength(3));
      expect(
        deleted.after.scenes
            .expand((scene) => scene.graph.nodes)
            .map((node) => node.payload)
            .whereType<SceneCinematicPayload>()
            .map((payload) => payload.cinematicId),
        everyElement('cinematic_replacement'),
      );
    });

    test('replaceWith rejects missing target and self rewrite by identity', () {
      final project = _referencedProject();

      final missing = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_missing',
        ),
      );
      final self = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_intro',
        ),
      );

      expect((missing as NarrativeAssetRejected).code, 'rewriteTargetMissing');
      expect(missing.after, same(project));
      expect((self as NarrativeAssetRejected).code, 'selfRewrite');
      expect(self.after, same(project));
    });

    test('ambiguous source, target and blank replacement are rejected', () {
      final duplicateSource = _project(
        cinematics: [
          _cinematic(id: 'cinematic_intro'),
          _cinematic(id: 'cinematic_intro'),
        ],
      );
      final ambiguousSource = NarrativeAssetMutation.deleteCinematic(
        duplicateSource,
        cinematicId: 'cinematic_intro',
      );

      final base = _referencedProject();
      final duplicateTarget = base.copyWith(
        cinematics: [
          ...base.cinematics,
          _cinematic(id: 'cinematic_replacement', title: 'Duplicate'),
        ],
      );
      final ambiguousTarget = NarrativeAssetMutation.deleteCinematic(
        duplicateTarget,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_replacement',
        ),
      );
      final blankTarget = NarrativeAssetMutation.deleteCinematic(
        base,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith('   '),
      );

      expect(
        (ambiguousSource as NarrativeAssetRejected).code,
        'assetIdAmbiguous',
      );
      expect(
        (ambiguousTarget as NarrativeAssetRejected).code,
        'rewriteTargetAmbiguous',
      );
      expect(
        (blankTarget as NarrativeAssetRejected).code,
        'rewriteTargetMissing',
      );
    });

    test('replaceWith rejects an id owned by another asset type', () {
      final base = _referencedProject();
      final project = base.copyWith(
        cinematics: [base.cinematics.first],
        scenes: [
          ...base.scenes,
          _sceneWithCinematics('cinematic_replacement', const []),
        ],
      );

      final result = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_replacement',
        ),
      );

      expect(result, isA<NarrativeAssetRejected>());
      expect(
        (result as NarrativeAssetRejected).code,
        'rewriteTargetTypeMismatch',
      );
      expect(result.after, same(project));
    });

    test('delete unreferenced asset succeeds and unknown asset is rejected',
        () {
      final project = _project(
        cinematics: [_cinematic(id: 'cinematic_intro')],
      );

      final deleted = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_intro',
      );
      final missing = NarrativeAssetMutation.deleteCinematic(
        project,
        cinematicId: 'cinematic_missing',
      );

      expect(deleted, isA<NarrativeAssetDeleted>());
      expect(deleted.after.cinematics, isEmpty);
      expect((missing as NarrativeAssetRejected).code, 'assetNotFound');
      expect(missing.after, same(project));
    });

    test('rejects a projected project that fails structural validation', () {
      final project = _project().copyWith(
        scenarios: const [
          ScenarioAsset(
            id: 'invalid_scenario',
            name: 'Invalid scenario',
            entryNodeId: 'missing',
          ),
        ],
      );

      final result = NarrativeAssetMutation.createCinematic(
        project,
        title: 'Cannot persist',
      );

      expect(result, isA<NarrativeAssetRejected>());
      expect(
        (result as NarrativeAssetRejected).code,
        'invalidProjectedProject',
      );
      expect(result.after, same(project));
    });

    test('reference path collections are immutable', () {
      final rejected = NarrativeAssetMutation.deleteCinematic(
        _referencedProject(),
        cinematicId: 'cinematic_intro',
      ) as NarrativeAssetRejected;
      final deleted = NarrativeAssetMutation.deleteCinematic(
        _referencedProject(),
        cinematicId: 'cinematic_intro',
        rewrite: const NarrativeReferenceRewrite.replaceWith(
          'cinematic_replacement',
        ),
      ) as NarrativeAssetDeleted;

      expect(
        () => rejected.referencePaths.add('unexpected'),
        throwsUnsupportedError,
      );
      expect(
        () => deleted.rewrittenReferencePaths.add('unexpected'),
        throwsUnsupportedError,
      );
    });
  });
}

ProjectManifest _referencedProject() {
  return _project(
    cinematics: [
      _cinematic(id: 'cinematic_intro', title: 'Intro'),
      _cinematic(id: 'cinematic_replacement', title: 'Replacement'),
    ],
    scenes: [
      _sceneWithCinematics('scene_a', ['cinematic_intro']),
      _sceneWithCinematics(
        'scene_b',
        ['cinematic_intro', 'cinematic_intro'],
      ),
    ],
  );
}

ProjectManifest _project({
  List<CinematicAsset> cinematics = const [],
  List<SceneAsset> scenes = const [],
}) {
  return ProjectManifest(
    name: 'Narrative mutation test',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics,
    scenes: scenes,
  );
}

CinematicAsset _cinematic({
  required String id,
  String title = 'Cinematic',
}) {
  return CinematicAsset(
    id: id,
    title: title,
    description: 'Description',
    timeline: CinematicTimeline(),
    metadata: const {'test': 'true'},
  );
}

SceneAsset _sceneWithCinematics(String id, List<String> cinematicIds) {
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start, title: 'Start'),
    for (var index = 0; index < cinematicIds.length; index++)
      SceneNode(
        id: 'cinematic_$index',
        kind: SceneNodeKind.cinematic,
        title: 'Cinematic $index',
        payload: SceneCinematicPayload(cinematicId: cinematicIds[index]),
      ),
    SceneNode(id: 'end', kind: SceneNodeKind.end, title: 'End'),
  ];
  return SceneAsset(
    id: id,
    name: id,
    graph: SceneGraph(startNodeId: 'start', nodes: nodes),
  );
}
```

### `packages/map_editor/lib/src/application/models/narrative_authoring_transaction.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

/// Immutable persistence request for one validated Narrative Studio mutation.
///
/// [before] is the compare-and-swap baseline and [after] is the exact manifest
/// that may be persisted. Both are captured from [mutation] so callers cannot
/// accidentally combine a mutation with unrelated project snapshots.
@immutable
final class NarrativeAuthoringTransaction {
  const NarrativeAuthoringTransaction._({
    required this.projectPath,
    required this.operationId,
    required this.before,
    required this.after,
    required this.mutation,
  });

  factory NarrativeAuthoringTransaction.fromMutation({
    required String projectPath,
    required String operationId,
    required NarrativeAssetMutationResult mutation,
  }) {
    return NarrativeAuthoringTransaction._(
      projectPath: _requiredIdentity(projectPath, 'projectPath'),
      operationId: _requiredIdentity(operationId, 'operationId'),
      before: mutation.before,
      after: mutation.after,
      mutation: mutation,
    );
  }

  final String projectPath;
  final String operationId;
  final ProjectManifest before;
  final ProjectManifest after;
  final NarrativeAssetMutationResult mutation;

  bool get isApplicable => mutation.isApplicable;
}

enum NarrativeAuthoringPersistenceStatus {
  committed,
  persistenceFailed,
  recoveryRequired,
}

/// Infrastructure-neutral outcome returned by the atomic persistence port.
@immutable
final class NarrativeAuthoringPersistenceResult {
  const NarrativeAuthoringPersistenceResult({
    required this.status,
    required this.code,
    required this.message,
  });

  const NarrativeAuthoringPersistenceResult.committed({
    this.code = 'committed',
    this.message = 'The narrative mutation was persisted.',
  }) : status = NarrativeAuthoringPersistenceStatus.committed;

  final NarrativeAuthoringPersistenceStatus status;
  final String code;
  final String message;

  bool get succeeded => status == NarrativeAuthoringPersistenceStatus.committed;
}

enum NarrativeAuthoringTransactionStatus {
  rejected,
  noChange,
  busy,
  committed,
  persistenceFailed,
  recoveryRequired,
}

/// Product-facing outcome of the validate -> persist transaction boundary.
@immutable
final class NarrativeAuthoringTransactionResult {
  const NarrativeAuthoringTransactionResult({
    required this.status,
    required this.code,
    required this.message,
    required this.transaction,
    this.persistenceResult,
    this.persistenceError,
    this.persistenceStackTrace,
  });

  final NarrativeAuthoringTransactionStatus status;
  final String code;
  final String message;
  final NarrativeAuthoringTransaction transaction;
  final NarrativeAuthoringPersistenceResult? persistenceResult;
  final Object? persistenceError;
  final StackTrace? persistenceStackTrace;

  bool get succeeded => status == NarrativeAuthoringTransactionStatus.committed;
}

String _requiredIdentity(String value, String field) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  return trimmed;
}
```

### `packages/map_editor/lib/src/application/ports/narrative_authoring_persistence_gateway.dart`

```dart
import '../models/narrative_authoring_transaction.dart';

/// Atomic project-manifest persistence boundary for Narrative Studio writes.
abstract interface class NarrativeAuthoringPersistenceGateway {
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  );
}
```

### `packages/map_editor/lib/src/application/use_cases/execute_narrative_authoring_transaction.dart`

```dart
import 'package:map_core/map_core.dart';

import '../models/narrative_authoring_transaction.dart';
import '../ports/narrative_authoring_persistence_gateway.dart';

/// Serializes validated narrative mutations through the persistence boundary.
///
/// Pure rejections and no-ops are returned locally. Applicable mutations reach
/// the gateway exactly once, and a second call is refused while that await is
/// in flight so one use-case instance cannot overlap project writes.
final class ExecuteNarrativeAuthoringTransaction {
  ExecuteNarrativeAuthoringTransaction(this._persistenceGateway);

  final NarrativeAuthoringPersistenceGateway _persistenceGateway;
  bool _busy = false;

  bool get isBusy => _busy;

  Future<NarrativeAuthoringTransactionResult> execute({
    required String projectPath,
    required String operationId,
    required NarrativeAssetMutationResult mutation,
  }) async {
    final transaction = NarrativeAuthoringTransaction.fromMutation(
      projectPath: projectPath,
      operationId: operationId,
      mutation: mutation,
    );

    switch (mutation) {
      case NarrativeAssetRejected(:final code, :final message):
        return NarrativeAuthoringTransactionResult(
          status: NarrativeAuthoringTransactionStatus.rejected,
          code: code,
          message: message,
          transaction: transaction,
        );
      case NarrativeAssetNoChange(:final reason):
        return NarrativeAuthoringTransactionResult(
          status: NarrativeAuthoringTransactionStatus.noChange,
          code: 'noChange',
          message: reason,
          transaction: transaction,
        );
      case NarrativeAssetCreated() ||
            NarrativeAssetUpdated() ||
            NarrativeAssetDeleted():
        break;
    }

    // Rejections and no-ops are pure local answers and must keep their exact
    // diagnostics even while another applicable write is awaiting I/O.
    if (_busy) {
      return NarrativeAuthoringTransactionResult(
        status: NarrativeAuthoringTransactionStatus.busy,
        code: 'transactionBusy',
        message: 'Another narrative mutation is already being persisted.',
        transaction: transaction,
      );
    }

    _busy = true;
    try {
      final persistenceResult = await _persistenceGateway.persist(transaction);
      return NarrativeAuthoringTransactionResult(
        status: _transactionStatus(persistenceResult.status),
        code: persistenceResult.code,
        message: persistenceResult.message,
        transaction: transaction,
        persistenceResult: persistenceResult,
      );
    } on Object catch (error, stackTrace) {
      return NarrativeAuthoringTransactionResult(
        status: NarrativeAuthoringTransactionStatus.persistenceFailed,
        code: 'unexpectedPersistenceFailure',
        message: 'The narrative mutation could not be persisted.',
        transaction: transaction,
        persistenceError: error,
        persistenceStackTrace: stackTrace,
      );
    } finally {
      _busy = false;
    }
  }
}

NarrativeAuthoringTransactionStatus _transactionStatus(
  NarrativeAuthoringPersistenceStatus status,
) {
  return switch (status) {
    NarrativeAuthoringPersistenceStatus.committed =>
      NarrativeAuthoringTransactionStatus.committed,
    NarrativeAuthoringPersistenceStatus.persistenceFailed =>
      NarrativeAuthoringTransactionStatus.persistenceFailed,
    NarrativeAuthoringPersistenceStatus.recoveryRequired =>
      NarrativeAuthoringTransactionStatus.recoveryRequired,
  };
}
```

### `packages/map_editor/lib/src/infrastructure/repositories/atomic_project_manifest_persistence.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../application/models/narrative_authoring_transaction.dart';
import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/models/narrative_event_registry_persistence_models.dart';
import '../../application/ports/narrative_authoring_persistence_gateway.dart';
import 'narrative_event_registry_persistence.dart';
import 'project_manifest_write_lock.dart';

enum AtomicProjectManifestWriteCheckpoint {
  afterInitialRead,
  afterTempFlushed,
  beforeSecondCompareAndSwap,
  afterProjectRenamed,
  beforeCommitVerification,
}

final class AtomicProjectManifestWriteContext {
  const AtomicProjectManifestWriteContext({
    required this.projectPath,
    required this.tempPath,
    required this.beforeRevision,
    required this.expectedAfterRevision,
  });

  final String projectPath;
  final String tempPath;
  final String beforeRevision;
  final String expectedAfterRevision;
}

typedef AtomicProjectManifestFaultInjector = FutureOr<void> Function(
  AtomicProjectManifestWriteCheckpoint checkpoint,
  AtomicProjectManifestWriteContext context,
);

/// Atomically replaces one project manifest after two compare-and-swap checks.
///
/// The writer intentionally preserves root members unknown to the current
/// model and the exact decoded `eventRegistry` value already present on disk.
/// Narrative Event authoring owns changes to that registry through its own
/// journalled writer.
final class AtomicProjectManifestPersistence
    implements NarrativeAuthoringPersistenceGateway {
  const AtomicProjectManifestPersistence({
    this.faultInjector,
    this.eventRegistryPersistence,
  });

  final AtomicProjectManifestFaultInjector? faultInjector;
  final NarrativeEventRegistryPersistence? eventRegistryPersistence;

  @override
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  ) async {
    if (!transaction.isApplicable) {
      return _failed(
        'transactionNotApplicable',
        'Only an applicable narrative mutation can be persisted.',
      );
    }
    try {
      ProjectValidator.validate(transaction.after);
    } on Object catch (error) {
      return _failed(
        'invalidTargetProject',
        'The projected manifest is invalid: $error',
      );
    }

    late final String canonicalProjectPath;
    try {
      final requestedProject = File(transaction.projectPath);
      if (!await requestedProject.exists()) {
        return _failed(
          'projectManifestMissing',
          'The project manifest does not exist.',
        );
      }
      // Resolve once before locking and use that same target for every later
      // read, temp and rename. Otherwise renaming onto a symlink path would
      // replace the link itself and fork the project away from its real file.
      canonicalProjectPath = p.normalize(
        await requestedProject.resolveSymbolicLinks(),
      );
    } on Object catch (error) {
      return _failed(
        'projectManifestPathResolutionFailed',
        'The project manifest path cannot be resolved safely: $error',
      );
    }

    try {
      return await withProjectManifestWriteLock(
        canonicalProjectPath,
        () => _persistLocked(
          transaction,
          canonicalProjectPath: canonicalProjectPath,
        ),
      );
    } on Object catch (error) {
      return _failed(
        'projectManifestWriteFailed',
        'The project manifest could not be persisted: $error',
      );
    }
  }

  Future<NarrativeAuthoringPersistenceResult> _persistLocked(
    NarrativeAuthoringTransaction transaction, {
    required String canonicalProjectPath,
  }) async {
    final recoveryInspection =
        await (eventRegistryPersistence ?? NarrativeEventRegistryPersistence())
            .inspectProjectAlreadyLocked(canonicalProjectPath);
    switch (recoveryInspection.status) {
      case NarrativeEventRegistryRecoveryGateStatus.recoveryRequired:
        return _recoveryRequired(
          'eventRegistryRecoveryRequired',
          _eventRecoveryMessage(
            'An interrupted Event write must be recovered first.',
            recoveryInspection,
          ),
        );
      case NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked:
        return _recoveryRequired(
          'eventRegistryRecoveryBlocked',
          _eventRecoveryMessage(
            'Event recovery is blocked and must be inspected first.',
            recoveryInspection,
          ),
        );
      case NarrativeEventRegistryRecoveryGateStatus.clear:
        break;
    }
    final projectFile = File(canonicalProjectPath);
    if (!await projectFile.exists()) {
      return _failed(
        'projectManifestMissing',
        'The project manifest does not exist.',
      );
    }

    late final List<int> beforeBytes;
    late final String beforeRevision;
    late final ValidatedNarrativeEventAuthoringProject current;
    late final Map<String, Object?> currentRoot;
    try {
      beforeBytes = await projectFile.readAsBytes();
      beforeRevision = narrativeEventBytesFingerprint(beforeBytes);
      current = decodeValidatedNarrativeEventAuthoringProject(beforeBytes);
      currentRoot = _strictObject(
        decodeNarrativeEventJsonStrict(utf8.decode(beforeBytes)),
      );
    } on Object catch (error) {
      return _failed(
        'invalidCurrentProject',
        'The current project manifest cannot be updated safely: $error',
      );
    }

    final tempPath = _tempPath(
      canonicalProjectPath,
      transaction.operationId,
    );
    final placeholderContext = AtomicProjectManifestWriteContext(
      projectPath: projectFile.path,
      tempPath: tempPath,
      beforeRevision: beforeRevision,
      expectedAfterRevision: beforeRevision,
    );
    await _checkpoint(
      AtomicProjectManifestWriteCheckpoint.afterInitialRead,
      placeholderContext,
    );
    if (current.manifest != transaction.before) {
      return _failed(
        'staleProjectRevision',
        'The project changed since this narrative edit started.',
      );
    }
    if (!_sameRegistry(
      current.registryState.registryOrNull,
      transaction.after.eventRegistry,
    )) {
      return _failed(
        'eventRegistryMismatch',
        'Generic narrative persistence cannot change the Event registry.',
      );
    }

    late final List<int> afterBytes;
    try {
      final serializedAfter = _strictObject(
        jsonDecode(jsonEncode(transaction.after.toJson())),
      );
      final nextRoot = Map<String, Object?>.from(currentRoot)
        ..addAll(serializedAfter);
      if (currentRoot.containsKey('eventRegistry')) {
        nextRoot['eventRegistry'] = currentRoot['eventRegistry'];
      } else {
        nextRoot.remove('eventRegistry');
      }
      canonicalizeNarrativeEventJson(nextRoot);
      afterBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(nextRoot),
      );
      final projected = decodeValidatedNarrativeEventAuthoringProject(
        afterBytes,
      );
      if (projected.manifest != transaction.after) {
        return _failed(
          'projectedManifestMismatch',
          'The persisted projection does not match the validated mutation.',
        );
      }
    } on Object catch (error) {
      return _failed(
        'invalidTargetProject',
        'The projected manifest cannot be encoded safely: $error',
      );
    }

    final expectedAfterRevision = narrativeEventBytesFingerprint(afterBytes);
    final context = AtomicProjectManifestWriteContext(
      projectPath: projectFile.path,
      tempPath: tempPath,
      beforeRevision: beforeRevision,
      expectedAfterRevision: expectedAfterRevision,
    );
    final tempFile = File(tempPath);
    var renameVisible = false;
    try {
      await tempFile.parent.create(recursive: true);
      final handle = await tempFile.open(mode: FileMode.write);
      try {
        await handle.writeFrom(afterBytes);
        await handle.flush();
      } finally {
        await handle.close();
      }
      await _checkpoint(
        AtomicProjectManifestWriteCheckpoint.afterTempFlushed,
        context,
      );
      final tempRevision = narrativeEventBytesFingerprint(
        await tempFile.readAsBytes(),
      );
      if (tempRevision != expectedAfterRevision) {
        await _deleteTemp(tempFile);
        return _failed(
          'projectManifestTempVerificationFailed',
          'The flushed temporary manifest does not match its source bytes.',
        );
      }

      await _checkpoint(
        AtomicProjectManifestWriteCheckpoint.beforeSecondCompareAndSwap,
        context,
      );
      final liveRevision = narrativeEventBytesFingerprint(
        await projectFile.readAsBytes(),
      );
      if (liveRevision != beforeRevision) {
        await _deleteTemp(tempFile);
        return _failed(
          'projectChangedBeforeCommit',
          'The project changed while the narrative edit was being saved.',
        );
      }

      await tempFile.rename(projectFile.path);
      renameVisible = true;
      await _checkpoint(
        AtomicProjectManifestWriteCheckpoint.afterProjectRenamed,
        context,
      );
      await _checkpoint(
        AtomicProjectManifestWriteCheckpoint.beforeCommitVerification,
        context,
      );
      final committedRevision = narrativeEventBytesFingerprint(
        await projectFile.readAsBytes(),
      );
      if (committedRevision != expectedAfterRevision) {
        return _recoveryRequired(
          'projectManifestVerificationFailed',
          'The renamed project manifest could not be verified.',
        );
      }
      return const NarrativeAuthoringPersistenceResult.committed(
        code: 'projectManifestCommitted',
        message: 'The narrative mutation was persisted atomically.',
      );
    } on Object catch (error) {
      if (!renameVisible) {
        await _deleteTemp(tempFile);
        return _failed(
          'projectManifestWriteFailed',
          'The project manifest was not replaced: $error',
        );
      }
      // A callback or final read can fail after the atomic rename even though
      // the exact requested bytes are already durable and readable. Verify
      // once more before declaring ambiguity so the UI never reports a known
      // committed document as "not saved".
      try {
        final committedRevision = narrativeEventBytesFingerprint(
          await projectFile.readAsBytes(),
        );
        if (committedRevision == expectedAfterRevision) {
          return const NarrativeAuthoringPersistenceResult.committed(
            code: 'projectManifestCommittedAfterInterruptedVerification',
            message: 'The narrative mutation was persisted and verified '
                'after an interrupted commit callback.',
          );
        }
      } on Object {
        // The state really is indeterminate; keep the recovery interlock.
      }
      return _recoveryRequired(
        'projectManifestCommitAmbiguous',
        'The project was replaced but final verification was interrupted: '
            '$error',
      );
    }
  }

  Future<void> _checkpoint(
    AtomicProjectManifestWriteCheckpoint checkpoint,
    AtomicProjectManifestWriteContext context,
  ) async {
    await faultInjector?.call(checkpoint, context);
  }
}

String _tempPath(String projectPath, String operationId) {
  final identity = narrativeEventBytesFingerprint(
    utf8.encode(
      '${p.normalize(projectPath)}\u0000$operationId',
    ),
  ).substring(7, 23);
  return p.join(
    p.dirname(projectPath),
    '.pokemap-project-$identity.tmp',
  );
}

Map<String, Object?> _strictObject(Object? value) {
  if (value is! Map) {
    throw const FormatException('Project root must be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw const FormatException('Project keys must be strings.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

bool _sameRegistry(
  NarrativeEventRegistry? left,
  NarrativeEventRegistry? right,
) {
  return canonicalizeNarrativeEventJson(left?.toJson()) ==
      canonicalizeNarrativeEventJson(right?.toJson());
}

Future<void> _deleteTemp(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // A same-directory temp is not user-visible state. A later attempt with
    // the same operation id truncates and verifies it before commit.
  }
}

NarrativeAuthoringPersistenceResult _failed(String code, String message) {
  return NarrativeAuthoringPersistenceResult(
    status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
    code: code,
    message: message,
  );
}

NarrativeAuthoringPersistenceResult _recoveryRequired(
  String code,
  String message,
) {
  return NarrativeAuthoringPersistenceResult(
    status: NarrativeAuthoringPersistenceStatus.recoveryRequired,
    code: code,
    message: message,
  );
}

String _eventRecoveryMessage(
  String summary,
  NarrativeEventRegistryRecoveryInspection inspection,
) {
  if (inspection.issues.isEmpty) return summary;
  final issue = inspection.issues.first;
  final path = issue.path == null ? '' : ' File: ${issue.path}.';
  return '$summary Cause: ${issue.code}. ${issue.message}$path';
}
```

### `packages/map_editor/test/atomic_project_manifest_persistence_test.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_authoring_transaction.dart';
import 'package:map_editor/src/application/models/narrative_event_registry_persistence_models.dart';
import 'package:map_editor/src/infrastructure/repositories/atomic_project_manifest_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_registry_persistence.dart';
import 'package:map_editor/src/infrastructure/repositories/project_manifest_write_lock.dart';

import 'support/event_registry_persistence_fixtures.dart';

void main() {
  group('AtomicProjectManifestPersistence', () {
    test('commits atomically while preserving unknown root and Event data',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final eventRegistryBefore = fixture.initialRoot['eventRegistry'];
      String? tempPath;
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, context) async {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.afterTempFlushed) {
            tempPath = context.tempPath;
            expect(
              File(context.tempPath).parent.path,
              File(await fixture.file.resolveSymbolicLinks()).parent.path,
            );
            expect(await File(context.tempPath).exists(), isTrue);
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(result.status, NarrativeAuthoringPersistenceStatus.committed);
      expect(result.code, 'projectManifestCommitted');
      final stored = await fixture.readRoot();
      expect(stored['futureRoot'], fixture.initialRoot['futureRoot']);
      expect(
        (stored['futureRoot'] as Map)['nested'],
        <Object?>['preserve', 7, true],
      );
      expect(stored['eventRegistry'], eventRegistryBefore);
      expect((stored['cinematics'] as List), hasLength(1));
      expect(
        (stored['cinematics'] as List).single,
        fixture.transaction.after.cinematics.single.toJson(),
      );
      expect(tempPath, isNotNull);
      expect(await File(tempPath!).exists(), isFalse);
    });

    test('rejects a stale semantic before snapshot without changing disk',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final external = fixture.before.copyWith(name: 'External change');
      await fixture.writeRoot(
        Map<String, Object?>.from(fixture.initialRoot)
          ..addAll(external.toJson())
          ..['eventRegistry'] = fixture.initialRoot['eventRegistry'],
      );
      final externalBytes = await fixture.file.readAsBytes();

      final result = await const AtomicProjectManifestPersistence().persist(
        fixture.transaction,
      );

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.persistenceFailed,
      );
      expect(result.code, 'staleProjectRevision');
      expect(await fixture.file.readAsBytes(), externalBytes);
      expect(await fixture.tempFiles(), isEmpty);
    });

    test('refuses to write while Event recovery is required', () async {
      final fixture = await createPersistenceFixture();
      addTearDown(fixture.dispose);
      final eventWriter = NarrativeEventRegistryPersistence(
        faultInjector: (checkpoint) async {
          if (checkpoint ==
              NarrativeEventRegistryWriteCheckpoint.afterJournalPrepared) {
            throw const FileSystemException('Injected prepared Event write');
          }
        },
      );
      final interrupted = await eventWriter.write(
        persistenceRequest(
          fixture: fixture,
          operationId: 'atomic_gate_required',
          previousRegistry: null,
          nextRegistry: persistenceRegistry(),
        ),
      );
      expect(
        interrupted.status,
        NarrativeEventRegistryPersistenceStatus.ioFailure,
      );
      final bytesBeforeAtomicWrite = await fixture.readBytes();
      final mutation = NarrativeAssetMutation.createCinematic(
        fixture.session.manifest,
        title: 'Blocked cinematic',
      );
      final transaction = NarrativeAuthoringTransaction.fromMutation(
        projectPath: fixture.projectPath,
        operationId: 'blocked-by-event-recovery',
        mutation: mutation,
      );

      final result = await const AtomicProjectManifestPersistence().persist(
        transaction,
      );

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.recoveryRequired,
      );
      expect(result.code, 'eventRegistryRecoveryRequired');
      expect(await fixture.readBytes(), bytesBeforeAtomicWrite);
    });

    test('refuses to write while Event recovery is blocked', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final journalPath = narrativeEventRegistryJournalPath(
        await fixture.file.resolveSymbolicLinks(),
        'atomic_gate_blocked',
      );
      await File(journalPath).writeAsString('{}', flush: true);
      final beforeBytes = await fixture.file.readAsBytes();
      final inspection = await NarrativeEventRegistryPersistence()
          .inspectProject(fixture.file.path);
      expect(
        inspection.status,
        NarrativeEventRegistryRecoveryGateStatus.recoveryBlocked,
      );

      final result = await const AtomicProjectManifestPersistence().persist(
        fixture.transaction,
      );

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.recoveryRequired,
      );
      expect(result.code, 'eventRegistryRecoveryBlocked');
      expect(await fixture.file.readAsBytes(), beforeBytes);
    });

    test('second CAS detects a byte-level concurrent change before rename',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      List<int>? concurrentBytes;
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) async {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.beforeSecondCompareAndSwap) {
            final concurrentRoot = Map<String, Object?>.from(
              await fixture.readRoot(),
            )..['concurrentFuture'] = <String, Object?>{'kept': true};
            await fixture.writeRoot(concurrentRoot);
            concurrentBytes = await fixture.file.readAsBytes();
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.persistenceFailed,
      );
      expect(result.code, 'projectChangedBeforeCommit');
      expect(concurrentBytes, isNotNull);
      expect(await fixture.file.readAsBytes(), concurrentBytes);
      expect(await fixture.tempFiles(), isEmpty);
    });

    test('a failure before rename leaves project bytes unchanged', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final beforeBytes = await fixture.file.readAsBytes();
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.afterTempFlushed) {
            throw const FileSystemException('Injected pre-rename failure');
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.persistenceFailed,
      );
      expect(result.code, 'projectManifestWriteFailed');
      expect(await fixture.file.readAsBytes(), beforeBytes);
      expect(await fixture.tempFiles(), isEmpty);
    });

    test('a post-rename callback failure is verified as committed', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.afterProjectRenamed) {
            throw const FileSystemException('Injected post-rename failure');
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.committed,
      );
      expect(
        result.code,
        'projectManifestCommittedAfterInterruptedVerification',
      );
      final stored = await fixture.readProject();
      expect(stored, fixture.transaction.after);
    });

    test('a divergent post-rename callback failure remains recovery required',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) async {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.afterProjectRenamed) {
            await fixture.file.writeAsString(
              '{"divergent":true}',
              flush: true,
            );
            throw const FileSystemException('Injected divergent commit');
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.recoveryRequired,
      );
      expect(result.code, 'projectManifestCommitAmbiguous');
      expect(await fixture.file.readAsString(), '{"divergent":true}');
    });

    test('re-reads the renamed file and requires recovery on hash mismatch',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) async {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.beforeCommitVerification) {
            await fixture.file.writeAsString(
              '{"interrupted":true}',
              flush: true,
            );
          }
        },
      );

      final result = await persistence.persist(fixture.transaction);

      expect(
        result.status,
        NarrativeAuthoringPersistenceStatus.recoveryRequired,
      );
      expect(result.code, 'projectManifestVerificationFailed');
      expect(await fixture.file.readAsString(), '{"interrupted":true}');
    });

    test('a symlink manifest updates its canonical target without forking',
        () async {
      if (Platform.isWindows) return;
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final aliasRoot = await Directory.systemTemp.createTemp(
        'pokemap_atomic_manifest_alias_',
      );
      addTearDown(() => aliasRoot.delete(recursive: true));
      final aliasPath = '${aliasRoot.path}/project.json';
      await Link(aliasPath).create(fixture.file.path);
      final transaction = NarrativeAuthoringTransaction.fromMutation(
        projectPath: aliasPath,
        operationId: 'create-through-symlink',
        mutation: fixture.transaction.mutation,
      );

      final result =
          await const AtomicProjectManifestPersistence().persist(transaction);

      expect(result.status, NarrativeAuthoringPersistenceStatus.committed);
      expect(
        await FileSystemEntity.type(aliasPath, followLinks: false),
        FileSystemEntityType.link,
      );
      expect(await fixture.readProject(), transaction.after);
      expect(
        await File(aliasPath).readAsString(),
        await fixture.file.readAsString(),
      );
    });

    test('shares the project manifest lock with existing writers', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final releasePersistence = Completer<void>();
      final persistenceReachedLock = Completer<void>();
      final secondWriterEntered = Completer<void>();
      final persistence = AtomicProjectManifestPersistence(
        faultInjector: (checkpoint, _) async {
          if (checkpoint ==
              AtomicProjectManifestWriteCheckpoint.afterInitialRead) {
            persistenceReachedLock.complete();
            await releasePersistence.future;
          }
        },
      );

      final first = persistence.persist(fixture.transaction);
      await persistenceReachedLock.future;
      final second = withProjectManifestWriteLock(fixture.file.path, () async {
        secondWriterEntered.complete();
      });
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(secondWriterEntered.isCompleted, isFalse);
      releasePersistence.complete();
      expect((await first).succeeded, isTrue);
      await second;
      expect(secondWriterEntered.isCompleted, isTrue);
    });
  });
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.file,
    required this.before,
    required this.initialRoot,
    required this.transaction,
  });

  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_atomic_manifest_',
    );
    final file = File('${root.path}/project.json');
    final registry = NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const [],
      legacyClaims: const [],
    );
    final before = ProjectManifest(
      name: 'Atomic persistence test',
      maps: const [],
      tilesets: const [],
      eventRegistry: registry,
    );
    final initialRoot = <String, Object?>{
      ...before.toJson(),
      'futureRoot': <String, Object?>{
        'nested': <Object?>['preserve', 7, true],
      },
    };
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(initialRoot),
      flush: true,
    );
    final mutation = NarrativeAssetMutation.createCinematic(
      before,
      title: 'Arrivée au port',
    );
    final transaction = NarrativeAuthoringTransaction.fromMutation(
      projectPath: file.path,
      operationId: 'create-cinematic-port',
      mutation: mutation,
    );
    return _Fixture(
      root: root,
      file: file,
      before: before,
      initialRoot: initialRoot,
      transaction: transaction,
    );
  }

  final Directory root;
  final File file;
  final ProjectManifest before;
  final Map<String, Object?> initialRoot;
  final NarrativeAuthoringTransaction transaction;

  Future<Map<String, Object?>> readRoot() async {
    final decoded = jsonDecode(await file.readAsString()) as Map;
    return <String, Object?>{
      for (final entry in decoded.entries) entry.key as String: entry.value,
    };
  }

  Future<ProjectManifest> readProject() async {
    final root = await readRoot();
    return ProjectManifest.fromJson(Map<String, dynamic>.from(root));
  }

  Future<void> writeRoot(Map<String, Object?> root) {
    return file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(root),
      flush: true,
    );
  }

  Future<List<FileSystemEntity>> tempFiles() async {
    return root
        .list(followLinks: false)
        .where((entry) => entry.path.endsWith('.tmp'))
        .toList();
  }

  Future<void> dispose() => root.delete(recursive: true);
}
```

### `packages/map_editor/test/narrative_authoring_transaction_test.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/application/models/narrative_authoring_transaction.dart';
import 'package:map_editor/src/application/ports/narrative_authoring_persistence_gateway.dart';
import 'package:map_editor/src/application/use_cases/execute_narrative_authoring_transaction.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  group('ExecuteNarrativeAuthoringTransaction', () {
    test('Rejected and NoChange never reach persistence', () async {
      final gateway = _RecordingGateway();
      final execute = ExecuteNarrativeAuthoringTransaction(gateway);
      final project = _project();
      final asset = _cinematic();
      final projectWithAsset = _project(cinematics: [asset]);

      final rejected = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'reject-1',
        mutation: NarrativeAssetMutation.createCinematic(
          project,
          title: '   ',
        ),
      );
      final noChange = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'no-change-1',
        mutation: NarrativeAssetMutation.updateCinematic(
          projectWithAsset,
          cinematicId: asset.id,
          cinematic: asset,
        ),
      );

      expect(rejected.status, NarrativeAuthoringTransactionStatus.rejected);
      expect(rejected.transaction.before, same(project));
      expect(rejected.transaction.after, same(project));
      expect(rejected.transaction.mutation, isA<NarrativeAssetRejected>());
      expect(noChange.status, NarrativeAuthoringTransactionStatus.noChange);
      expect(noChange.transaction.before, same(projectWithAsset));
      expect(noChange.transaction.after, same(projectWithAsset));
      expect(noChange.transaction.mutation, isA<NarrativeAssetNoChange>());
      expect(gateway.calls, 0);
    });

    test('an applicable mutation is persisted exactly once', () async {
      final gateway = _RecordingGateway();
      final execute = ExecuteNarrativeAuthoringTransaction(gateway);
      final project = _project();
      final mutation = NarrativeAssetMutation.createCinematic(
        project,
        title: 'Arrivée au port',
      );

      final result = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'create-cinematic-1',
        mutation: mutation,
      );

      expect(result.status, NarrativeAuthoringTransactionStatus.committed);
      expect(result.succeeded, isTrue);
      expect(gateway.calls, 1);
      expect(gateway.lastTransaction, same(result.transaction));
      expect(result.transaction.projectPath, '/projects/selbrume');
      expect(result.transaction.operationId, 'create-cinematic-1');
      expect(result.transaction.before, same(mutation.before));
      expect(result.transaction.after, same(mutation.after));
      expect(result.transaction.mutation, same(mutation));
      expect(result.persistenceResult, same(gateway.result));
    });

    test('persistence failure and recovery-required statuses are preserved',
        () async {
      final cases = <(
        NarrativeAuthoringPersistenceStatus,
        NarrativeAuthoringTransactionStatus,
      )>[
        (
          NarrativeAuthoringPersistenceStatus.persistenceFailed,
          NarrativeAuthoringTransactionStatus.persistenceFailed,
        ),
        (
          NarrativeAuthoringPersistenceStatus.recoveryRequired,
          NarrativeAuthoringTransactionStatus.recoveryRequired,
        ),
      ];

      for (final (persistenceStatus, expectedStatus) in cases) {
        final gateway = _RecordingGateway(
          result: NarrativeAuthoringPersistenceResult(
            status: persistenceStatus,
            code: persistenceStatus.name,
            message: 'Persistence outcome: ${persistenceStatus.name}',
          ),
        );
        final result =
            await ExecuteNarrativeAuthoringTransaction(gateway).execute(
          projectPath: '/projects/selbrume',
          operationId: 'failure-${persistenceStatus.name}',
          mutation: NarrativeAssetMutation.createCinematic(
            _project(),
            title: 'Tempête',
          ),
        );

        expect(result.status, expectedStatus);
        expect(result.code, persistenceStatus.name);
        expect(result.succeeded, isFalse);
        expect(gateway.calls, 1);
      }
    });

    test('a reentrant transaction is refused while persistence is pending',
        () async {
      final persistence = Completer<NarrativeAuthoringPersistenceResult>();
      final gateway = _RecordingGateway(handler: (_) => persistence.future);
      final execute = ExecuteNarrativeAuthoringTransaction(gateway);
      final firstMutation = NarrativeAssetMutation.createCinematic(
        _project(),
        title: 'Première',
      );
      final secondMutation = NarrativeAssetMutation.createCinematic(
        _project(),
        title: 'Deuxième',
      );

      final first = execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'first',
        mutation: firstMutation,
      );
      await gateway.started.future;

      final rejectedWhileBusy = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'rejected-while-busy',
        mutation: NarrativeAssetMutation.createCinematic(
          _project(),
          title: '   ',
        ),
      );
      final existing = _cinematic();
      final projectWithExisting = _project(cinematics: [existing]);
      final noChangeWhileBusy = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'no-change-while-busy',
        mutation: NarrativeAssetMutation.updateCinematic(
          projectWithExisting,
          cinematicId: existing.id,
          cinematic: existing,
        ),
      );

      final second = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'second',
        mutation: secondMutation,
      );

      expect(second.status, NarrativeAuthoringTransactionStatus.busy);
      expect(second.code, 'transactionBusy');
      expect(second.transaction.mutation, same(secondMutation));
      expect(
        rejectedWhileBusy.status,
        NarrativeAuthoringTransactionStatus.rejected,
      );
      expect(
        noChangeWhileBusy.status,
        NarrativeAuthoringTransactionStatus.noChange,
      );
      expect(gateway.calls, 1);

      persistence
          .complete(const NarrativeAuthoringPersistenceResult.committed());
      expect(
        (await first).status,
        NarrativeAuthoringTransactionStatus.committed,
      );

      final third = await execute.execute(
        projectPath: '/projects/selbrume',
        operationId: 'third',
        mutation: NarrativeAssetMutation.createCinematic(
          _project(),
          title: 'Troisième',
        ),
      );
      expect(third.status, NarrativeAuthoringTransactionStatus.committed);
      expect(gateway.calls, 2);
    });

    test('an unexpected gateway error becomes a persistence failure', () async {
      final gateway = _RecordingGateway(
        handler: (_) => Future<NarrativeAuthoringPersistenceResult>.error(
          const FormatException('disk payload'),
        ),
      );

      final result =
          await ExecuteNarrativeAuthoringTransaction(gateway).execute(
        projectPath: '/projects/selbrume',
        operationId: 'throws',
        mutation: NarrativeAssetMutation.createCinematic(
          _project(),
          title: 'Erreur',
        ),
      );

      expect(
        result.status,
        NarrativeAuthoringTransactionStatus.persistenceFailed,
      );
      expect(result.code, 'unexpectedPersistenceFailure');
      expect(result.persistenceError, isA<FormatException>());
      expect(gateway.calls, 1);
    });
  });

  group('NarrativeAuthoringTransaction', () {
    test('rejects blank persistence identities', () {
      final mutation = NarrativeAssetMutation.createCinematic(
        _project(),
        title: 'Intro',
      );

      expect(
        () => NarrativeAuthoringTransaction.fromMutation(
          projectPath: ' ',
          operationId: 'operation',
          mutation: mutation,
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeAuthoringTransaction.fromMutation(
          projectPath: '/projects/selbrume',
          operationId: ' ',
          mutation: mutation,
        ),
        throwsArgumentError,
      );
    });
  });

  group('EditorNotifier narrative authoring adoption', () {
    test(
        'publishes dirty state before commit and cleans only after confirmation',
        () async {
      final root = await Directory.systemTemp.createTemp('narrative_tx_state_');
      addTearDown(() => root.delete(recursive: true));
      final persistence = Completer<NarrativeAuthoringPersistenceResult>();
      final gateway = _RecordingGateway(handler: (_) => persistence.future);
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final before = _project();
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: before,
      );

      final pending = notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.createCinematic(
          project,
          title: 'Port',
        ),
        operationId: 'create-port',
      );
      await gateway.started.future;

      expect(notifier.state.project!.cinematics.single.title, 'Port');
      expect(notifier.state.isProjectDirty, isTrue);
      expect(notifier.state.isSaving, isTrue);
      expect(
        notifier.state.statusMessage,
        isNot(contains('enregistrée.')),
      );

      persistence.complete(
        const NarrativeAuthoringPersistenceResult.committed(),
      );
      final result = await pending;

      expect(result!.status, NarrativeAuthoringTransactionStatus.committed);
      expect(notifier.state.isProjectDirty, isFalse);
      expect(notifier.state.isSaving, isFalse);
      expect(
          notifier.state.statusMessage, 'Modification narrative enregistrée.');
    });

    test('persistence failure keeps the authored document visible and dirty',
        () async {
      final root = await Directory.systemTemp.createTemp('narrative_tx_fail_');
      addTearDown(() => root.delete(recursive: true));
      final gateway = _RecordingGateway(
        result: const NarrativeAuthoringPersistenceResult(
          status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
          code: 'staleProjectRevision',
          message: 'The project changed externally.',
        ),
      );
      final projectRepository = _RecordingProjectRepository();
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
          projectRepositoryProvider.overrideWithValue(projectRepository),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: _project(),
      );

      final result = await notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.createCinematic(
          project,
          title: 'Local only',
        ),
        operationId: 'create-local-only',
      );

      expect(
        result!.status,
        NarrativeAuthoringTransactionStatus.persistenceFailed,
      );
      expect(notifier.state.project!.cinematics.single.title, 'Local only');
      expect(notifier.state.isProjectDirty, isTrue);
      expect(notifier.state.isSaving, isFalse);
      expect(
        notifier.state.errorMessage,
        contains('Modification locale conservée'),
      );

      final genericSave = await notifier.saveProjectManifest();

      expect(genericSave, isFalse);
      expect(projectRepository.calls, 0);
      expect(
          notifier.state.errorMessage, contains('Sauvegarde projet bloquée'));
      expect(notifier.state.errorMessage, contains('Rechargez le projet'));
    });

    test('a dirty no-op retry cannot become a false persistence success',
        () async {
      final root = await Directory.systemTemp.createTemp('narrative_tx_retry_');
      addTearDown(() => root.delete(recursive: true));
      final gateway = _RecordingGateway(
        result: const NarrativeAuthoringPersistenceResult(
          status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
          code: 'staleProjectRevision',
          message: 'The project changed externally.',
        ),
      );
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final original = _cinematic();
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: _project(cinematics: [original]),
      );

      final first = await notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.updateCinematic(
          project,
          cinematicId: original.id,
          cinematic: CinematicAsset(
            id: original.id,
            title: 'Intro locale',
            timeline: original.timeline,
          ),
        ),
        operationId: 'update-local-first',
      );
      final localAsset = notifier.state.project!.cinematics.single;
      final retry = await notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.updateCinematic(
          project,
          cinematicId: localAsset.id,
          cinematic: localAsset,
        ),
        operationId: 'update-local-retry',
      );

      expect(
        first!.status,
        NarrativeAuthoringTransactionStatus.persistenceFailed,
      );
      expect(retry!.status, NarrativeAuthoringTransactionStatus.rejected);
      expect(retry.code, 'unsavedLocalSnapshot');
      expect(gateway.calls, 1);
      expect(notifier.state.isProjectDirty, isTrue);
      expect(notifier.state.project!.cinematics.single.title, 'Intro locale');
      expect(notifier.state.errorMessage, contains('seulement localement'));
      expect(notifier.state.statusMessage, isNot('Modification enregistrée.'));
    });

    test('a newer local edit remains dirty after the older snapshot commits',
        () async {
      final root = await Directory.systemTemp.createTemp('narrative_tx_race_');
      addTearDown(() => root.delete(recursive: true));
      final persistence = Completer<NarrativeAuthoringPersistenceResult>();
      final gateway = _RecordingGateway(handler: (_) => persistence.future);
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: _project(),
      );

      final pending = notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.createCinematic(
          project,
          title: 'Persisted snapshot',
        ),
        operationId: 'persist-snapshot',
      );
      await gateway.started.future;
      final newer = notifier.state.project!.copyWith(name: 'Newer local edit');
      notifier.applyInMemoryProjectManifest(newer);
      persistence.complete(
        const NarrativeAuthoringPersistenceResult.committed(),
      );
      await pending;

      expect(notifier.state.project, same(newer));
      expect(notifier.state.isProjectDirty, isTrue);
      expect(notifier.state.statusMessage, contains('plus récentes'));
    });

    test('a result from the previous project cannot contaminate a new session',
        () async {
      final rootA = await Directory.systemTemp.createTemp('narrative_tx_a_');
      final rootB = await Directory.systemTemp.createTemp('narrative_tx_b_');
      addTearDown(() => rootA.delete(recursive: true));
      addTearDown(() => rootB.delete(recursive: true));
      final persistence = Completer<NarrativeAuthoringPersistenceResult>();
      final gateway = _RecordingGateway(handler: (_) => persistence.future);
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        projectRootPath: rootA.path,
        project: _project(),
      );

      final pending = notifier.executeNarrativeAuthoringMutation(
        (project) => NarrativeAssetMutation.createCinematic(
          project,
          title: 'Projet A',
        ),
        operationId: 'project-a-write',
      );
      await gateway.started.future;
      final projectB = _project().copyWith(name: 'Projet B');
      notifier.state = EditorState(
        projectRootPath: rootB.path,
        project: projectB,
        statusMessage: 'Projet B actif',
      );
      persistence.complete(
        const NarrativeAuthoringPersistenceResult(
          status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
          code: 'staleProjectRevision',
          message: 'Projet A obsolète.',
        ),
      );

      final supersededResult = await pending;

      expect(supersededResult, isNull);
      expect(notifier.state.project, same(projectB));
      expect(notifier.state.projectRootPath, rootB.path);
      expect(notifier.state.isProjectDirty, isFalse);
      expect(notifier.state.isSaving, isFalse);
      expect(notifier.state.statusMessage, 'Projet B actif');
      expect(notifier.state.errorMessage, isNull);
    });

    test('referenced delete is rejected before persistence with exact path',
        () async {
      final root = await Directory.systemTemp.createTemp('narrative_tx_refs_');
      addTearDown(() => root.delete(recursive: true));
      final gateway = _RecordingGateway();
      final container = ProviderContainer(
        overrides: [
          narrativeAuthoringPersistenceGatewayProvider.overrideWithValue(
            gateway,
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final cinematic = _cinematic();
      final scene = SceneAsset(
        id: 'scene_intro',
        name: 'Intro',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'cinematic',
              kind: SceneNodeKind.cinematic,
              payload: SceneCinematicPayload(cinematicId: cinematic.id),
            ),
          ],
        ),
      );
      final project = _project(cinematics: [cinematic]).copyWith(
        scenes: [scene],
      );
      notifier.state = EditorState(
        projectRootPath: root.path,
        project: project,
      );

      final result = await notifier.executeNarrativeAuthoringMutation(
        (current) => NarrativeAssetMutation.deleteCinematic(
          current,
          cinematicId: cinematic.id,
        ),
        operationId: 'delete-referenced',
      );

      expect(result!.status, NarrativeAuthoringTransactionStatus.rejected);
      expect(result.transaction.mutation, isA<NarrativeAssetRejected>());
      expect(notifier.state.project, same(project));
      expect(notifier.state.isProjectDirty, isFalse);
      expect(gateway.calls, 0);
      expect(
        notifier.state.errorMessage,
        contains('scenes[scene_intro].graph.nodes[1].payload.cinematicId'),
      );
    });
  });
}

final class _RecordingGateway implements NarrativeAuthoringPersistenceGateway {
  _RecordingGateway({
    NarrativeAuthoringPersistenceResult? result,
    this.handler,
  }) : result = result ?? const NarrativeAuthoringPersistenceResult.committed();

  final NarrativeAuthoringPersistenceResult result;
  final Future<NarrativeAuthoringPersistenceResult> Function(
    NarrativeAuthoringTransaction transaction,
  )? handler;
  final Completer<void> started = Completer<void>();
  int calls = 0;
  NarrativeAuthoringTransaction? lastTransaction;

  @override
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  ) {
    calls += 1;
    lastTransaction = transaction;
    if (!started.isCompleted) started.complete();
    return handler?.call(transaction) ?? Future.value(result);
  }
}

final class _RecordingProjectRepository implements ProjectRepository {
  int calls = 0;

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    calls += 1;
  }
}

ProjectManifest _project({
  List<CinematicAsset> cinematics = const <CinematicAsset>[],
}) {
  return ProjectManifest(
    name: 'Narrative transaction test',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics,
  );
}

CinematicAsset _cinematic() {
  return CinematicAsset(
    id: 'cinematic_intro',
    title: 'Intro',
    timeline: CinematicTimeline(),
  );
}
```

