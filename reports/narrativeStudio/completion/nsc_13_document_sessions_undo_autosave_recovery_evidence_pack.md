# Evidence Pack — NSC-13 — Sessions document, undo/redo, autosave et recovery

Date : 2026-07-19
Package : `packages/map_editor`
Roadmap : `docs/superpowers/plans/2026-07-19-narrative-studio-completion-roadmap.md`
Verdict proposé : **DONE**. Le Gate de Phase 1 peut être proposé comme franchi après le commit isolé.

## 1. Résumé exécutif

NSC-13 introduit une session documentaire crash-safe commune au Narrative Studio et l’adopte sur un premier pilote strict : **Cinématiques**. Une intention utilisateur produit une entrée undo/redo complète, le document local n’est publié qu’après écriture du journal de recovery, une sauvegarde passe par compare-and-swap, et l’état `saved` n’est publié qu’après relecture de la révision durable exacte.

Le shell partagé expose les statuts `dirty`, `saving`, `saved`, `failed`, `conflicted` et `recovered`, la sauvegarde manuelle, l’autosave configurable, undo/redo, discard, compare/reload/keep-local et un garde de navigation. Les raccourcis et contrôles d’historique restent volontairement confinés à Cinématiques ; une session bloquante récupérée reste visible afin de pouvoir être résolue.

La preuve finale comprend 23 tests exactement demandés par la roadmap, une matrice ciblée élargie de 128 tests, la suite complète `map_editor` à 3 533 tests, une analyse Flutter sans erreur, un build macOS debug propre, une signature profonde valide et un exécutable arm64.

## 2. Confirmation et challenge du scope

La roadmap nommait cinq fichiers principaux, mais ses critères de fin exigeaient aussi une vraie persistance CAS, un journal disque, une UI de conflit/localisation et des tests d’intégration. Le scope a donc été élargi uniquement aux frontières nécessaires : composition Riverpod, infrastructure disque, shell partagé, design system, l10n et tests existants directement impactés.

Décisions de périmètre :

- pilote unique : modification d’une **Cinématique existante** ;
- création, suppression, réordonnancement et mutations multi-assets restent sur la transaction narrative atomique existante ; après commit structurel, la session est rebasée ;
- aucun modèle `map_core`, format runtime ou donnée Selbrume n’est modifié ;
- pas de préférence autosave persistée entre lancements dans ce lot ;
- pas de dialogue natif de fermeture de fenêtre : les navigations internes sont gardées et une fermeture brutale est couverte par le journal durable.

## 3. Audit initial

### Contrats trouvés

- `EditorState.isProjectDirty` / `isSaving` portaient déjà l’état global, sans historique documentaire commun.
- `ExecuteNarrativeAuthoringTransaction` et `NarrativeAuthoringPersistenceGateway` fournissaient déjà la frontière atomique de persistance narrative.
- `FileProjectRepository.narrativeAuthoringPersistence` possédait les garde-fous de révision et de commit durable à réutiliser.
- `NarrativeWorkspaceCanvas` persistait les opérations structurelles Cinématiques immédiatement et appliquait les autres modifications en mémoire.
- `NarrativeStudioProductShell` restait provider-free et disposait d’un header extensible sans logique métier.
- Le design system disposait des panels, boutons, badges et side sheets, mais pas d’un dialogue de confirmation typé générique.

### Risques identifiés avant implémentation

- faux statut « sauvegardé » avant confirmation disque ;
- écrasement d’une révision externe entre lecture et commit ;
- perte d’un edit si le journal est écrit après publication UI ;
- callback de save/autosave ancien remplaçant un document plus récent ;
- mélange entre modifications Cinématiques sous session et modifications externes au pilote ;
- historique Cinématiques accidentellement actif dans Storylines/Events ;
- journal illisible effacé silencieusement ;
- tests widget utilisant de vraies E/S dans la zone temporelle simulée Flutter.

### Verdict Audit / Architecture

**PASS** : les frontières existantes suffisaient. La stratégie retenue compose un service générique, un store disque et un adaptateur CAS sans déplacer les règles vers `map_core` ou le runtime.

## 4. État Git initial

HEAD initial : `a27ce07b feat(narrative): harden shared studio shell`.

Changements préexistants explicitement hors lot :

~~~text
 M examples/playable_runtime_host/test/selbrume_event_v2_promoted_project_test.dart
A  examples/playable_runtime_host/test/selbrume_lighthouse_retry_integration_test.dart
 M examples/playable_runtime_host/test/selbrume_player_journey_e2e_test.dart
 M packages/map_editor/test/selbrume_canonical_narrative_seed_test.dart
 M packages/map_editor/tool/seed_selbrume_canonical_narrative_content.dart
 M packages/map_runtime/test/selbrume_event_v2_trigger_battle_anchor_integration_test.dart
 M packages/map_runtime/test/selbrume_static_boss_playable_map_game_integration_test.dart
 M selbrume/project.json
?? reports/gameplay/fg_000_narrative_studio_selbrume_readiness_reaudit_2026-07-19.md
~~~

Le test lighthouse était déjà indexé avant NSC-13. Il doit rester indexé et hors du commit.

## 5. Architecture livrée et invariants

Flux de publication :

1. construire une intention immutable `before → after` ;
2. écrire et `flush` le journal de recovery ;
3. publier le document local et son statut ;
4. sauvegarder avec révision attendue et snapshot `before` exacts ;
5. relire la version durable ;
6. publier `saved` puis effacer le journal seulement après confirmation exacte.

Invariants :

- un échec d’écriture du journal refuse la publication visible ;
- un save concurrent ne déclenche pas un second appel gateway ;
- un résultat durable différent du snapshot demandé est un échec explicite ;
- un conflit conserve baseline, local et externe pour compare/reload/keep-local ;
- un journal malformé est conservé, sauf discard explicite de l’utilisateur ;
- les callbacks périmés sont neutralisés par génération ;
- un document visible ayant dérivé désactive l’historique du pilote ;
- aucun écran adopté ne peut annoncer `saved` avant confirmation.

## 6. Inventaire complet des fichiers du lot

### Fichiers créés

| Fichier | Zones / classes | Raison et impact |
|---|---|---|
| `packages/map_editor/lib/src/application/services/narrative_document_session.dart` | états, gateway/store contracts, `NarrativeDocumentSession<T>` | Cycle de vie, CAS, autosave, recovery, conflits et publication fail-closed. |
| `packages/map_editor/lib/src/application/services/narrative_undo_stack.dart` | `NarrativeUndoEntry`, `NarrativeUndoStack`, transitions | Historique immutable borné par intention avec contrôle de drift. |
| `packages/map_editor/lib/src/infrastructure/repositories/file_narrative_document_recovery_store.dart` | `FileNarrativeDocumentRecoveryStore<T>` | Journal JSON complet écrit via temp, flush, validation et rename. |
| `packages/map_editor/lib/src/infrastructure/repositories/project_manifest_narrative_document_gateway.dart` | `ProjectManifestNarrativeDocumentGateway` | Adaptateur CAS limité à une Cinématique existante, réutilisant la persistance narrative. |
| `packages/map_editor/lib/src/ui/design_system/pokemap_confirmation_dialog.dart` | action typée et dialogue DS | Garde de navigation accessible, token-driven et réutilisable. |
| `packages/map_editor/test/narrative_document_persistence_test.dart` | store + gateway | Round-trip, journal corrompu, scope pilote, stale conflict, durable exact. |
| `packages/map_editor/test/narrative_document_session_test.dart` | 14 scénarios service | Positif, pannes, concurrence, recovery, conflit, autosave, discard. |
| `packages/map_editor/test/narrative_document_session_workspace_adoption_test.dart` | 3 scénarios notifier | Adoption Cinématiques, réouverture recovery, rebase structurel et confinement de l’historique. |
| `packages/map_editor/test/narrative_undo_stack_test.dart` | 6 scénarios historique | Undo/redo, branches, capacité, no-op, immutabilité et drift. |
| `packages/map_editor/test/ui/design_system/pokemap_confirmation_dialog_test.dart` | widget test | Retour typé de l’action choisie. |
| `packages/map_editor/test/ui/shell/narrative_document_controls_test.dart` | 2 parcours shell | Contrôles, garde, save/undo/redo/discard, compare/reload et confinement du pilote. |

### Fichiers modifiés — zones précises

| Fichier | Zones modifiées | Raison / impact |
|---|---|---|
| `packages/map_editor/lib/l10n/app_fr.arb` | clés `narrativeStatus*`, actions, guard et compare | Libellés français du cycle documentaire. |
| `packages/map_editor/lib/l10n/app_en.arb` | mêmes clés | Parité anglaise. |
| `packages/map_editor/lib/l10n/app_localizations.dart` | accessors générés | API l10n générée. |
| `packages/map_editor/lib/l10n/app_localizations_fr.dart` | implémentations générées | Valeurs françaises. |
| `packages/map_editor/lib/l10n/app_localizations_en.dart` | implémentations générées | Valeurs anglaises. |
| `packages/map_editor/lib/src/app/providers/core/repository_providers.dart` | lignes 44–80, factory session | Composition gateway + recovery sous `.pokemap/recovery/narrative-cinematics.json`. |
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | champs 101–110 ; init create/load ; API 539–726 ; rebase transaction ; save global | Ownership/lifecycle, projections UI, protection contre drift, session save et rebase structurel. |
| `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart` | constructeur/champs/header `documentActions` | Slot provider-free pour les actions documentaires. |
| `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` | `_CinematicsWorkspaceBodyState`, metadata/timeline/bindings, `_applyCinematicDocumentEdit` | Toutes les éditions internes existantes deviennent des intentions journalisées ; create/delete restent atomiques. |
| `packages/map_editor/lib/src/ui/design_system/design_system.dart` | export dialogue | Rend la primitive disponible au shell. |
| `packages/map_editor/lib/src/ui/editor_shell_page.dart` | keys 39–53 ; guard 158–187 ; shortcuts 386–428 ; slot header ; contrôles 1649+ | Navigation protégée, raccourcis confinés au pilote, statuts/actions/conflits et comparaison. |
| `packages/map_editor/test/narrative_studio_localization_test.dart` | matrice de clés | Ratchet FR/EN pour toutes les nouvelles chaînes. |
| `packages/map_editor/test/shell_chrome_test_harness.dart` | `settleInitialFrame` | Permet les scénarios asynchrones sans attendre une animation persistante. |
| `packages/map_editor/test/ui/canvas/narrative_studio_cinematics_route_test.dart` | callbacks async, échec explicite, compare | Adapte la route réelle au journal disque et interdit le faux succès. |
| `packages/map_editor/test/ui/canvas/narrative_studio_shell_contract_test.dart` | slot `documentActions` | Contrat provider-free du header. |
| `packages/map_editor/test/ui/canvas/narrative_studio_specialized_routes_test.dart` | fixture manifeste + `runAsync` | Le reload réel exécute les E/S hors fake async ; non-régression du timeout découvert. |
| `reports/narrativeStudio/completion/nsc_13_document_sessions_undo_autosave_recovery_evidence_pack.md` | document courant | Audit, preuves, inventaire, verdicts et annexes complètes. |

Stat des seuls fichiers déjà suivis avant la correction critique : **1 344 insertions / 129 suppressions**. Les 11 nouveaux fichiers totalisaient environ 3 010 lignes avant les dernières assertions. Les suppressions de `narrative_workspace_canvas.dart` correspondent principalement au remplacement mécanique des callbacks locaux par l’adaptateur d’intention.

## 7. Tests créés ou modifiés

Couverture positive : initialisation disque, edit journalisé, undo/redo, save confirmé, autosave, keep-local, reload externe, rebase après création structurelle et contrôles UI.

Couverture négative : panne journal, panne save, save concurrent, journal malformé, mutation hors pilote, création/suppression/multi-update refusées, révision externe stale, mismatch durable et conflit.

Garde-fous/non-régression : recovery après réouverture, journal conservé, aucun faux `saved`, historique désactivé si le document visible dérive, contrôles absents hors Cinématiques, route reload avec vraies E/S, matrice responsive/goldens existants.

## 8. Commandes et résultats exacts

### Génération

~~~text
cd packages/map_editor && flutter gen-l10n
Because l10n.yaml exists, the options defined there will be used instead.
To use the command line arguments, delete the l10n.yaml file in the Flutter project.
=> exit 0
~~~

### Tests ciblés exacts de la roadmap

~~~text
flutter test test/narrative_document_session_test.dart test/narrative_undo_stack_test.dart test/narrative_document_session_workspace_adoption_test.dart
00:02 +23: All tests passed!
~~~

### Matrice ciblée élargie finale

~~~text
flutter test test/narrative_document_session_test.dart test/narrative_undo_stack_test.dart test/narrative_document_session_workspace_adoption_test.dart test/narrative_document_persistence_test.dart test/ui/design_system/pokemap_confirmation_dialog_test.dart test/ui/shell/narrative_document_controls_test.dart test/ui/canvas/narrative_studio_shell_contract_test.dart test/ui/canvas/narrative_studio_cinematics_route_test.dart test/ui/canvas/narrative_studio_specialized_routes_test.dart test/narrative_studio_localization_test.dart
00:15 +128: All tests passed!
~~~

### Incident de suite complète diagnostiqué et corrigé

Une première relance après reprise a atteint 3 460 tests puis le test suivant a expiré :

~~~text
narrative_studio_specialized_routes_test.dart: reloading the same project starts a fresh navigation session
TimeoutException after 0:10:00.000000: Test timed out after 10 minutes.
Guarded function conflict.
10:25 +3532 -1: Some tests failed.
~~~

Cause : le nouveau chargement eager de session effectue une lecture disque réelle, tandis que l’ancien widget test attendait cette Future dans la zone temporelle simulée et ne créait pas réellement `project.json`. Correction : fixture manifeste réelle et `tester.runAsync`.

Preuve isolée après correction :

~~~text
flutter test test/ui/canvas/narrative_studio_specialized_routes_test.dart --plain-name 'reloading the same project starts a fresh navigation session'
00:01 +1: All tests passed!
~~~

### Suite complète finale

~~~text
cd packages/map_editor && flutter test
03:34 +3533: All tests passed!
~~~

Une relance complète intermédiaire après le premier correctif avait également terminé à `03:38 +3533: All tests passed!`.

### Analyse et hygiène

~~~text
cd packages/map_editor && flutter analyze
Analyzing map_editor...
No issues found! (ran in 19.6s)

git diff --check
=> exit 0, aucune sortie

git diff -U0 -- <surfaces UI NSC-13> | rg '^\+.*(Color\(0x|Colors\.)'
=> uniquement context.pokeMapColors.textMuted / textSecondary ; aucune couleur ad hoc ajoutée
~~~

### Build macOS propre

~~~text
flutter clean
=> exit 0

flutter pub get
Got dependencies!
37 packages have newer versions incompatible with dependency constraints.
=> exit 0

flutter gen-l10n
=> exit 0

flutter build macos --debug
warning: The app icon set "AppIcon" has an unassigned child.
warning: Run script build phase 'Run Script' will be run during every build because it does not specify any outputs.
✓ Built build/macos/Build/Products/Debug/map_editor.app
~~~

Validation artefact :

~~~text
test -d build/macos/Build/Products/Debug/map_editor.app
=> exit 0

codesign --verify --deep --strict --verbose=2 build/macos/Build/Products/Debug/map_editor.app
build/macos/Build/Products/Debug/map_editor.app: valid on disk
build/macos/Build/Products/Debug/map_editor.app: satisfies its Designated Requirement

file build/macos/Build/Products/Debug/map_editor.app/Contents/MacOS/map_editor
=> Mach-O 64-bit executable arm64
~~~

Un premier build incrémental avait produit deux frameworks individuellement valides mais un sceau externe obsolète. Le rebuild propre documenté ci-dessus est la preuve finale ; ce problème était limité au cache de build.

## 9. Verdict des cinq passes obligatoires

| Passe locale séparée | Verdict | Preuve / décision |
|---|---|---|
| Audit / Architecture | **PASS** | Frontières existantes réutilisées ; aucun modèle core/runtime touché ; pilote borné. |
| Implémentation | **PASS** | Ordre journal→publication→CAS→confirmation→cleanup et génération anti-callback périmé. |
| Tests | **PASS** | 23 ciblés roadmap, 128 ciblés élargis, 3 533 complets ; timeout ancien reproduit, expliqué et corrigé. |
| Build / Validation | **PASS avec warnings connus** | Analyze vert, diff propre, app macOS produite, signature valide, arm64. |
| Critique finale | **PASS après correction** | A détecté l’historique/raccourci Cinématiques exposé hors pilote ; confinement ajouté et revalidé. |

Les instructions d’environnement interdisaient de lancer des sub-agents sans demande utilisateur explicite. Conformément à `codex_rule.md`, les cinq contrôles ont donc été exécutés comme passes locales séparées et nommées.

## 10. État Git final avant commit et isolement

Le working tree contient les fichiers NSC-13 de la section 6, plus exactement les changements Selbrume préexistants de la section 4. Le commit doit utiliser `git commit --only` avec les seuls chemins NSC-13 afin de préserver l’index lighthouse déjà présent.

État attendu et à contrôler après commit isolé : aucun fichier NSC-13 ne reste modifié. Restent uniquement les neuf chemins préexistants de la section 4 ; le fichier lighthouse reste staged.

## 11. Limites conservées et risques restants

- Seule l’édition d’une Cinématique existante est persistée par la session CAS. Les autres workspaces adopteront le contrat dans leurs lots dédiés.
- Create/delete/reorder/multi-update restent sur la transaction atomique existante ; l’adaptateur CAS les refuse explicitement.
- Le toggle autosave est session-local et revient désactivé à la prochaine ouverture.
- Le garde couvre la navigation interne. Une fermeture OS brutale ne montre pas de modal, mais le journal écrit avant publication permet la récupération.
- La comparaison présente baseline/local/externe de manière lisible au niveau manifeste/Cinématiques ; ce n’est pas encore un diff sémantique champ par champ.
- Le journal embarque les snapshots complets et un historique borné à 100 intentions ; de très gros manifests pourront motiver un format delta dans un lot ultérieur.
- Les deux warnings Xcode (icône non assignée et phase Run Script sans outputs) préexistent et ne sont pas corrigés ici.

## 12. Auto-critique finale

Le premier montage des raccourcis s’appuyait sur « workspace narratif » au sens large. C’était trop large pour un pilote Cinématiques : un historique déjà sauvegardé aurait pu être proposé depuis Storylines, et `Cmd/Ctrl+S` aurait pu sélectionner une session propre plutôt qu’une modification globale. La passe critique a resserré undo/redo et les contrôles au workspace Cinématiques, utilise la session au save seulement lorsqu’elle bloque réellement, et désactive l’historique si le document visible a dérivé.

Le service générique reste situé dans `map_editor` et utilise `ChangeNotifier`; il n’est donc pas encore partageable avec un package Dart pur. Ce choix est volontaire pour NSC-13, qui vise la coordination d’authoring Flutter et non une règle de gameplay.

Aucun changement Selbrume, runtime ou gameplay n’a été inclus. Aucun pourcentage de couverture ou mesure non vérifiée n’est revendiqué.

## 13. Prochaine étape proposée, non implémentée

Le prochain lot de la roadmap est **NSC-20 — Cycle de vie Storyline et consolidation de la vérité legacy**. Il pourra adopter le contrat NSC-13 après avoir caractérisé `ProjectManifest.storylines` et `GlobalStory`, dans un commit séparé.

## 14. Annexes — contenu complet des fichiers créés

Le présent Evidence Pack n’est pas répété dans lui-même afin d’éviter une annexe auto-référentielle. Tous les autres fichiers créés par NSC-13 sont reproduits intégralement ci-dessous.

### `packages/map_editor/lib/src/application/services/narrative_document_session.dart`

~~~dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'narrative_undo_stack.dart';

/// Product-visible lifecycle for one Narrative Studio authoring document.
///
/// There is deliberately no optimistic `saved` alias: the state reaches
/// [saved] only after the gateway returned the exact durable revision.
enum NarrativeDocumentSessionStatus {
  dirty,
  saving,
  saved,
  failed,
  conflicted,
  recovered,
}

@immutable
final class NarrativeDocumentVersion<T> {
  const NarrativeDocumentVersion({
    required this.revision,
    required this.document,
  });

  final String revision;
  final T document;
}

sealed class NarrativeDocumentSaveResult<T> {
  const NarrativeDocumentSaveResult();

  const factory NarrativeDocumentSaveResult.saved(
    NarrativeDocumentVersion<T> version,
  ) = NarrativeDocumentSaved<T>;

  const factory NarrativeDocumentSaveResult.failed({
    required String code,
    required String message,
  }) = NarrativeDocumentSaveFailed<T>;

  const factory NarrativeDocumentSaveResult.conflicted({
    required String code,
    required String message,
    required NarrativeDocumentVersion<T> external,
  }) = NarrativeDocumentSaveConflicted<T>;
}

final class NarrativeDocumentSaved<T> extends NarrativeDocumentSaveResult<T> {
  const NarrativeDocumentSaved(this.version);

  final NarrativeDocumentVersion<T> version;
}

final class NarrativeDocumentSaveFailed<T>
    extends NarrativeDocumentSaveResult<T> {
  const NarrativeDocumentSaveFailed({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;
}

final class NarrativeDocumentSaveConflicted<T>
    extends NarrativeDocumentSaveResult<T> {
  const NarrativeDocumentSaveConflicted({
    required this.code,
    required this.message,
    required this.external,
  });

  final String code;
  final String message;
  final NarrativeDocumentVersion<T> external;
}

/// Compare-and-swap boundary used by the document session.
abstract interface class NarrativeDocumentGateway<T> {
  Future<NarrativeDocumentVersion<T>> read();

  Future<NarrativeDocumentSaveResult<T>> save({
    required String expectedRevision,
    required T before,
    required T after,
    required String operationId,
  });
}

/// Durable crash-recovery envelope.
///
/// The full before/current/history snapshots make recovery deterministic. The
/// infrastructure codec is responsible for validating the concrete document.
@immutable
final class NarrativeDocumentRecoveryRecord<T> {
  const NarrativeDocumentRecoveryRecord({
    this.schemaVersion = 1,
    required this.documentId,
    required this.baseRevision,
    required this.baseline,
    required this.document,
    this.undoEntries = const [],
    this.redoEntries = const [],
  });

  final int schemaVersion;
  final String documentId;
  final String baseRevision;
  final T baseline;
  final T document;
  final List<NarrativeUndoEntry<T>> undoEntries;
  final List<NarrativeUndoEntry<T>> redoEntries;
}

abstract interface class NarrativeDocumentRecoveryStore<T> {
  Future<NarrativeDocumentRecoveryRecord<T>?> read();
  Future<void> write(NarrativeDocumentRecoveryRecord<T> record);
  Future<void> clear();
}

abstract interface class NarrativeDocumentAutosaveHandle {
  void cancel();
}

typedef NarrativeDocumentAutosaveScheduler = NarrativeDocumentAutosaveHandle
    Function(
  Duration delay,
  Future<void> Function() callback,
);

@immutable
final class NarrativeDocumentComparison<T> {
  const NarrativeDocumentComparison({
    required this.baseline,
    required this.local,
    required this.external,
  });

  final T baseline;
  final T local;
  final T external;
}

@immutable
final class NarrativeDocumentSessionState<T> {
  const NarrativeDocumentSessionState({
    required this.documentId,
    required this.document,
    required this.baseline,
    required this.baselineRevision,
    required this.status,
    required this.history,
    required this.autosaveEnabled,
    required this.isInitialized,
    this.externalVersion,
    this.code,
    this.message,
  });

  final String documentId;
  final T document;
  final T baseline;
  final String? baselineRevision;
  final NarrativeDocumentSessionStatus status;
  final NarrativeUndoStack<T> history;
  final bool autosaveEnabled;
  final bool isInitialized;
  final NarrativeDocumentVersion<T>? externalVersion;
  final String? code;
  final String? message;

  bool get canUndo => history.canUndo;
  bool get canRedo => history.canRedo;
  bool get isDirty => document != baseline;

  /// Navigation must not silently discard an in-flight, failed or recovered
  /// edit even when an unusual failure left the snapshots equal.
  bool get blocksNavigation => status != NarrativeDocumentSessionStatus.saved;

  NarrativeDocumentSessionState<T> copyWith({
    T? document,
    T? baseline,
    Object? baselineRevision = _notProvided,
    NarrativeDocumentSessionStatus? status,
    NarrativeUndoStack<T>? history,
    bool? autosaveEnabled,
    bool? isInitialized,
    Object? externalVersion = _notProvided,
    Object? code = _notProvided,
    Object? message = _notProvided,
  }) {
    return NarrativeDocumentSessionState<T>(
      documentId: documentId,
      document: document ?? this.document,
      baseline: baseline ?? this.baseline,
      baselineRevision: identical(baselineRevision, _notProvided)
          ? this.baselineRevision
          : baselineRevision as String?,
      status: status ?? this.status,
      history: history ?? this.history,
      autosaveEnabled: autosaveEnabled ?? this.autosaveEnabled,
      isInitialized: isInitialized ?? this.isInitialized,
      externalVersion: identical(externalVersion, _notProvided)
          ? this.externalVersion
          : externalVersion as NarrativeDocumentVersion<T>?,
      code: identical(code, _notProvided) ? this.code : code as String?,
      message:
          identical(message, _notProvided) ? this.message : message as String?,
    );
  }
}

const Object _notProvided = Object();

/// Stateful coordinator for safe Narrative Studio document editing.
///
/// Publication ordering is the central invariant:
/// 1. write/flush recovery evidence;
/// 2. publish the local document;
/// 3. persist through compare-and-swap;
/// 4. clear recovery only after the exact durable revision is confirmed.
final class NarrativeDocumentSession<T> extends ChangeNotifier {
  NarrativeDocumentSession({
    required String documentId,
    required T initialDocument,
    required NarrativeDocumentGateway<T> gateway,
    required NarrativeDocumentRecoveryStore<T> recoveryStore,
    this.autosaveDelay = const Duration(seconds: 3),
    NarrativeDocumentAutosaveScheduler? autosaveScheduler,
    bool autosaveEnabled = false,
    int historyCapacity = 100,
  })  : assert(historyCapacity > 0),
        _gateway = gateway,
        _recoveryStore = recoveryStore,
        _historyCapacity = historyCapacity,
        _autosaveScheduler = autosaveScheduler ?? _scheduleWithTimer,
        _state = NarrativeDocumentSessionState<T>(
          documentId: _requiredText(documentId, 'documentId'),
          document: initialDocument,
          baseline: initialDocument,
          baselineRevision: null,
          status: NarrativeDocumentSessionStatus.saved,
          history: NarrativeUndoStack<T>(capacity: historyCapacity),
          autosaveEnabled: autosaveEnabled,
          isInitialized: false,
        );

  final NarrativeDocumentGateway<T> _gateway;
  final NarrativeDocumentRecoveryStore<T> _recoveryStore;
  final int _historyCapacity;
  final NarrativeDocumentAutosaveScheduler _autosaveScheduler;
  final Duration autosaveDelay;

  NarrativeDocumentSessionState<T> _state;
  NarrativeDocumentAutosaveHandle? _autosaveHandle;
  Future<void>? _initialization;
  bool _disposed = false;
  int _operationGeneration = 0;
  int _autosaveSequence = 0;

  NarrativeDocumentSessionState<T> get state => _state;

  NarrativeDocumentComparison<T>? get comparison {
    final external = _state.externalVersion;
    if (external == null) return null;
    return NarrativeDocumentComparison<T>(
      baseline: _state.baseline,
      local: _state.document,
      external: external.document,
    );
  }

  Future<void> initialize() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    final generation = _operationGeneration;
    try {
      final disk = await _gateway.read();
      final recovery = await _recoveryStore.read();
      if (!_canAdopt(generation)) return;

      if (recovery == null) {
        _publish(
          _state.copyWith(
            document: disk.document,
            baseline: disk.document,
            baselineRevision: disk.revision,
            status: NarrativeDocumentSessionStatus.saved,
            history: NarrativeUndoStack<T>(capacity: _historyCapacity),
            isInitialized: true,
            externalVersion: null,
            code: null,
            message: null,
          ),
        );
        return;
      }
      if (recovery.schemaVersion != 1 ||
          recovery.documentId.trim() != _state.documentId) {
        _publishFailure(
          code: 'invalidRecoveryRecord',
          message: 'The recovery journal does not belong to this document.',
          initialized: true,
        );
        return;
      }

      final history = NarrativeUndoStack<T>(
        undoEntries: recovery.undoEntries,
        redoEntries: recovery.redoEntries,
        capacity: _historyCapacity,
      );
      if (recovery.baseRevision == disk.revision) {
        _publish(
          _state.copyWith(
            document: recovery.document,
            baseline: recovery.baseline,
            baselineRevision: recovery.baseRevision,
            status: NarrativeDocumentSessionStatus.recovered,
            history: history,
            isInitialized: true,
            externalVersion: null,
            code: 'recoveryRestored',
            message: 'Recovered unsaved narrative changes.',
          ),
        );
        _scheduleAutosaveIfNeeded();
        return;
      }
      if (recovery.document == disk.document) {
        await _recoveryStore.clear();
        if (!_canAdopt(generation)) return;
        _publish(
          _state.copyWith(
            document: disk.document,
            baseline: disk.document,
            baselineRevision: disk.revision,
            status: NarrativeDocumentSessionStatus.saved,
            history: NarrativeUndoStack<T>(capacity: _historyCapacity),
            isInitialized: true,
            externalVersion: null,
            code: null,
            message: null,
          ),
        );
        return;
      }

      _publish(
        _state.copyWith(
          document: recovery.document,
          baseline: recovery.baseline,
          baselineRevision: recovery.baseRevision,
          status: NarrativeDocumentSessionStatus.conflicted,
          history: history,
          isInitialized: true,
          externalVersion: disk,
          code: 'externalRevisionConflict',
          message: 'The project changed after the local recovery snapshot.',
        ),
      );
    } on Object catch (error) {
      if (!_canAdopt(generation)) return;
      _publishFailure(
        code: 'sessionInitializationFailed',
        message: 'The narrative document session could not start: $error',
        initialized: true,
      );
    }
  }

  Future<bool> apply({
    required String operationId,
    required String label,
    required T document,
  }) async {
    if (!_state.isInitialized ||
        _state.status == NarrativeDocumentSessionStatus.saving ||
        _state.status == NarrativeDocumentSessionStatus.conflicted ||
        _disposed) {
      return false;
    }
    if (document == _state.document) return true;

    late final NarrativeUndoStack<T> history;
    try {
      history = _state.history.record(
        operationId: operationId,
        label: label,
        before: _state.document,
        after: document,
      );
    } on Object catch (error) {
      _publishFailure(
        code: 'invalidEditIntent',
        message: 'The edit intention is invalid: $error',
      );
      return false;
    }
    final candidate = _state.copyWith(
      document: document,
      status: NarrativeDocumentSessionStatus.dirty,
      history: history,
      externalVersion: null,
      code: null,
      message: 'Narrative changes are waiting to be saved.',
    );
    return _commitLocalCandidate(candidate);
  }

  Future<bool> undo() async {
    if (!_canMutateHistory()) return false;
    late final NarrativeUndoTransition<T>? transition;
    try {
      transition = _state.history.undo(_state.document);
    } on Object catch (error) {
      _publishFailure(
        code: 'undoDocumentDrift',
        message: 'Undo was blocked because the document drifted: $error',
      );
      return false;
    }
    if (transition == null) return false;
    final candidate = _state.copyWith(
      document: transition.document,
      status: transition.document == _state.baseline
          ? NarrativeDocumentSessionStatus.saved
          : NarrativeDocumentSessionStatus.dirty,
      history: transition.stack,
      externalVersion: null,
      code: null,
      message: 'Undo: ${transition.entry.label}',
    );
    return _commitLocalCandidate(candidate);
  }

  Future<bool> redo() async {
    if (!_canMutateHistory()) return false;
    late final NarrativeUndoTransition<T>? transition;
    try {
      transition = _state.history.redo(_state.document);
    } on Object catch (error) {
      _publishFailure(
        code: 'redoDocumentDrift',
        message: 'Redo was blocked because the document drifted: $error',
      );
      return false;
    }
    if (transition == null) return false;
    final candidate = _state.copyWith(
      document: transition.document,
      status: transition.document == _state.baseline
          ? NarrativeDocumentSessionStatus.saved
          : NarrativeDocumentSessionStatus.dirty,
      history: transition.stack,
      externalVersion: null,
      code: null,
      message: 'Redo: ${transition.entry.label}',
    );
    return _commitLocalCandidate(candidate);
  }

  Future<bool> save({required String operationId}) async {
    if (!_state.isInitialized ||
        _disposed ||
        _state.status == NarrativeDocumentSessionStatus.saving ||
        _state.status == NarrativeDocumentSessionStatus.conflicted) {
      return false;
    }
    final baselineRevision = _state.baselineRevision;
    if (baselineRevision == null) return false;
    if (!_state.isDirty) {
      if (_state.status == NarrativeDocumentSessionStatus.recovered) {
        try {
          await _recoveryStore.clear();
          _publish(_state.copyWith(
            status: NarrativeDocumentSessionStatus.saved,
            code: null,
            message: null,
          ));
        } on Object catch (error) {
          _publishFailure(
            code: 'recoveryCleanupFailed',
            message: 'The stale recovery journal could not be cleared: $error',
          );
          return false;
        }
      }
      return true;
    }

    final normalizedOperationId = _requiredText(operationId, 'operationId');
    _cancelAutosave();
    final generation = ++_operationGeneration;
    final savingSnapshot = _state;
    _publish(
      _state.copyWith(
        status: NarrativeDocumentSessionStatus.saving,
        code: null,
        message: 'Saving narrative changes…',
      ),
    );
    try {
      final result = await _gateway.save(
        expectedRevision: baselineRevision,
        before: savingSnapshot.baseline,
        after: savingSnapshot.document,
        operationId: normalizedOperationId,
      );
      if (!_canAdopt(generation)) return false;
      return switch (result) {
        NarrativeDocumentSaved<T>(:final version) =>
          await _adoptSaved(version, savingSnapshot),
        NarrativeDocumentSaveFailed<T>(:final code, :final message) =>
          _adoptSaveFailure(
            savingSnapshot,
            code: code,
            message: message,
          ),
        NarrativeDocumentSaveConflicted<T>(
          :final code,
          :final message,
          :final external,
        ) =>
          _adoptConflict(
            savingSnapshot,
            code: code,
            message: message,
            external: external,
          ),
      };
    } on Object catch (error) {
      if (!_canAdopt(generation)) return false;
      return _adoptSaveFailure(
        savingSnapshot,
        code: 'unexpectedSaveFailure',
        message: 'The narrative document could not be saved: $error',
      );
    }
  }

  Future<bool> _adoptSaved(
    NarrativeDocumentVersion<T> version,
    NarrativeDocumentSessionState<T> savingSnapshot,
  ) async {
    if (version.document != savingSnapshot.document) {
      return _adoptSaveFailure(
        savingSnapshot,
        code: 'savedDocumentMismatch',
        message: 'The durable document does not match the requested snapshot.',
      );
    }
    final saved = savingSnapshot.copyWith(
      document: version.document,
      baseline: version.document,
      baselineRevision: version.revision,
      status: NarrativeDocumentSessionStatus.saved,
      externalVersion: null,
      code: null,
      message: 'Narrative changes saved.',
    );
    try {
      // Recovery is cleared only after the durable revision above is known.
      await _recoveryStore.clear();
      _publish(saved);
      return true;
    } on Object catch (error) {
      _publish(
        saved.copyWith(
          status: NarrativeDocumentSessionStatus.recovered,
          code: 'recoveryCleanupFailed',
          message: 'The document is durable but its recovery journal remains: '
              '$error',
        ),
      );
      return false;
    }
  }

  bool _adoptSaveFailure(
    NarrativeDocumentSessionState<T> savingSnapshot, {
    required String code,
    required String message,
  }) {
    _publish(
      savingSnapshot.copyWith(
        status: NarrativeDocumentSessionStatus.failed,
        code: code,
        message: message,
      ),
    );
    return false;
  }

  bool _adoptConflict(
    NarrativeDocumentSessionState<T> savingSnapshot, {
    required String code,
    required String message,
    required NarrativeDocumentVersion<T> external,
  }) {
    _publish(
      savingSnapshot.copyWith(
        status: NarrativeDocumentSessionStatus.conflicted,
        externalVersion: external,
        code: code,
        message: message,
      ),
    );
    return false;
  }

  Future<bool> keepLocal() async {
    final external = _state.externalVersion;
    if (_state.status != NarrativeDocumentSessionStatus.conflicted ||
        external == null ||
        _disposed) {
      return false;
    }
    final candidate = _state.copyWith(
      baseline: external.document,
      baselineRevision: external.revision,
      status: NarrativeDocumentSessionStatus.dirty,
      externalVersion: null,
      code: null,
      message: 'Local changes kept on top of the external revision.',
    );
    return _commitLocalCandidate(candidate);
  }

  Future<bool> reloadExternal() async {
    final external = _state.externalVersion;
    if (_state.status != NarrativeDocumentSessionStatus.conflicted ||
        external == null ||
        _disposed) {
      return false;
    }
    final history = _state.history.record(
      operationId: 'reload_external_${++_autosaveSequence}',
      label: 'Recharger la version externe',
      before: _state.document,
      after: external.document,
    );
    try {
      await _recoveryStore.clear();
    } on Object catch (error) {
      _publishFailure(
        code: 'recoveryCleanupFailed',
        message: 'The external version could not be adopted safely: $error',
      );
      return false;
    }
    _publish(
      _state.copyWith(
        document: external.document,
        baseline: external.document,
        baselineRevision: external.revision,
        status: NarrativeDocumentSessionStatus.saved,
        history: history,
        externalVersion: null,
        code: null,
        message: 'External narrative version reloaded.',
      ),
    );
    return true;
  }

  Future<bool> discard() async {
    if (!_state.isInitialized ||
        _disposed ||
        _state.status == NarrativeDocumentSessionStatus.saving) {
      return false;
    }
    final external = _state.externalVersion;
    var baseline = external?.document ?? _state.baseline;
    var revision = external?.revision ?? _state.baselineRevision;
    if (revision == null) {
      // Initialization may have failed while decoding the recovery journal,
      // before a durable revision could be adopted. Explicit discard is the
      // user's authorization to clear that evidence and restart from disk.
      try {
        final disk = await _gateway.read();
        if (_disposed) return false;
        baseline = disk.document;
        revision = disk.revision;
      } on Object catch (error) {
        _publishFailure(
          code: 'discardReloadFailed',
          message: 'The durable narrative document could not be reloaded: '
              '$error',
        );
        return false;
      }
    }
    try {
      await _recoveryStore.clear();
    } on Object catch (error) {
      _publishFailure(
        code: 'recoveryCleanupFailed',
        message: 'Local changes could not be discarded safely: $error',
      );
      return false;
    }
    _cancelAutosave();
    _publish(
      _state.copyWith(
        document: baseline,
        baseline: baseline,
        baselineRevision: revision,
        status: NarrativeDocumentSessionStatus.saved,
        history: NarrativeUndoStack<T>(capacity: _historyCapacity),
        externalVersion: null,
        code: null,
        message: 'Local narrative changes discarded.',
      ),
    );
    return true;
  }

  void setAutosaveEnabled(bool enabled) {
    if (_disposed || _state.autosaveEnabled == enabled) return;
    if (!enabled) _cancelAutosave();
    _publish(_state.copyWith(autosaveEnabled: enabled));
    if (enabled) _scheduleAutosaveIfNeeded();
  }

  bool _canMutateHistory() {
    return _state.isInitialized &&
        !_disposed &&
        _state.status != NarrativeDocumentSessionStatus.saving &&
        _state.status != NarrativeDocumentSessionStatus.conflicted;
  }

  Future<bool> _commitLocalCandidate(
    NarrativeDocumentSessionState<T> candidate,
  ) async {
    _cancelAutosave();
    try {
      if (candidate.document == candidate.baseline) {
        await _recoveryStore.clear();
      } else {
        await _recoveryStore.write(_recordFor(candidate));
      }
      if (_disposed) return false;
      _publish(candidate);
      _scheduleAutosaveIfNeeded();
      return true;
    } on Object catch (error) {
      if (!_disposed) {
        _publishFailure(
          code: 'recoveryWriteFailed',
          message: 'The edit was not published because recovery evidence '
              'could not be written: $error',
        );
      }
      return false;
    }
  }

  NarrativeDocumentRecoveryRecord<T> _recordFor(
    NarrativeDocumentSessionState<T> candidate,
  ) {
    final revision = candidate.baselineRevision;
    if (revision == null) {
      throw StateError('Cannot journal a document without a base revision.');
    }
    return NarrativeDocumentRecoveryRecord<T>(
      documentId: candidate.documentId,
      baseRevision: revision,
      baseline: candidate.baseline,
      document: candidate.document,
      undoEntries: candidate.history.undoEntries,
      redoEntries: candidate.history.redoEntries,
    );
  }

  void _scheduleAutosaveIfNeeded() {
    if (!_state.autosaveEnabled ||
        !_state.isDirty ||
        _disposed ||
        _state.status == NarrativeDocumentSessionStatus.saving ||
        _state.status == NarrativeDocumentSessionStatus.conflicted) {
      return;
    }
    _cancelAutosave();
    final sequence = ++_autosaveSequence;
    _autosaveHandle = _autosaveScheduler(autosaveDelay, () async {
      _autosaveHandle = null;
      if (_disposed || sequence != _autosaveSequence) return;
      await save(
        operationId: 'autosave_${_state.documentId}_$sequence',
      );
    });
  }

  void _cancelAutosave() {
    _autosaveHandle?.cancel();
    _autosaveHandle = null;
  }

  bool _canAdopt(int generation) {
    return !_disposed && generation == _operationGeneration;
  }

  void _publishFailure({
    required String code,
    required String message,
    bool? initialized,
  }) {
    _publish(
      _state.copyWith(
        status: NarrativeDocumentSessionStatus.failed,
        isInitialized: initialized,
        code: code,
        message: message,
      ),
    );
  }

  void _publish(NarrativeDocumentSessionState<T> next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _operationGeneration++;
    _cancelAutosave();
    super.dispose();
  }
}

NarrativeDocumentAutosaveHandle _scheduleWithTimer(
  Duration delay,
  Future<void> Function() callback,
) {
  return _TimerAutosaveHandle(Timer(delay, () => unawaited(callback())));
}

final class _TimerAutosaveHandle implements NarrativeDocumentAutosaveHandle {
  const _TimerAutosaveHandle(this._timer);

  final Timer _timer;

  @override
  void cancel() => _timer.cancel();
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  return normalized;
}
~~~

### `packages/map_editor/lib/src/application/services/narrative_undo_stack.dart`

~~~dart
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// One complete user intention captured as immutable before/after documents.
///
/// The session deliberately stores whole authoring documents at this boundary:
/// a graph edit or a preset application must undo as one product action, not as
/// a sequence of implementation-field mutations.
@immutable
final class NarrativeUndoEntry<T> {
  const NarrativeUndoEntry({
    required this.operationId,
    required this.label,
    required this.before,
    required this.after,
  });

  final String operationId;
  final String label;
  final T before;
  final T after;
}

/// Result of applying one undo or redo transition.
@immutable
final class NarrativeUndoTransition<T> {
  const NarrativeUndoTransition({
    required this.document,
    required this.stack,
    required this.entry,
  });

  final T document;
  final NarrativeUndoStack<T> stack;
  final NarrativeUndoEntry<T> entry;
}

/// Immutable, bounded undo/redo history for Narrative Studio documents.
///
/// Entries are ordered oldest to newest. Drift checks are intentionally strict:
/// applying an entry to an unexpected visible document would silently replace a
/// newer edit, so the stack fails closed with [StateError] instead.
@immutable
final class NarrativeUndoStack<T> {
  const NarrativeUndoStack({
    List<NarrativeUndoEntry<T>> undoEntries = const [],
    List<NarrativeUndoEntry<T>> redoEntries = const [],
    this.capacity = 100,
  })  : assert(capacity > 0),
        _undoEntries = undoEntries,
        _redoEntries = redoEntries;

  final List<NarrativeUndoEntry<T>> _undoEntries;
  final List<NarrativeUndoEntry<T>> _redoEntries;
  final int capacity;

  List<NarrativeUndoEntry<T>> get undoEntries =>
      UnmodifiableListView(_undoEntries);

  List<NarrativeUndoEntry<T>> get redoEntries =>
      UnmodifiableListView(_redoEntries);

  bool get canUndo => _undoEntries.isNotEmpty;
  bool get canRedo => _redoEntries.isNotEmpty;

  NarrativeUndoStack<T> record({
    required String operationId,
    required String label,
    required T before,
    required T after,
  }) {
    final normalizedOperationId = _requiredText(
      operationId,
      'operationId',
    );
    final normalizedLabel = _requiredText(label, 'label');
    if (before == after) {
      return this;
    }

    final nextUndo = <NarrativeUndoEntry<T>>[
      ..._undoEntries,
      NarrativeUndoEntry<T>(
        operationId: normalizedOperationId,
        label: normalizedLabel,
        before: before,
        after: after,
      ),
    ];
    final overflow = nextUndo.length - capacity;
    return NarrativeUndoStack<T>(
      undoEntries: overflow > 0 ? nextUndo.sublist(overflow) : nextUndo,
      // A new product intention creates a new history branch. Retaining redo
      // here would let users resurrect a document that no longer descends from
      // the visible state.
      redoEntries: const [],
      capacity: capacity,
    );
  }

  NarrativeUndoTransition<T>? undo(T current) {
    if (_undoEntries.isEmpty) {
      return null;
    }
    final entry = _undoEntries.last;
    if (current != entry.after) {
      throw StateError(
        'Cannot undo ${entry.operationId}: the visible document drifted.',
      );
    }
    return NarrativeUndoTransition<T>(
      document: entry.before,
      entry: entry,
      stack: NarrativeUndoStack<T>(
        undoEntries: _undoEntries.sublist(0, _undoEntries.length - 1),
        redoEntries: <NarrativeUndoEntry<T>>[..._redoEntries, entry],
        capacity: capacity,
      ),
    );
  }

  NarrativeUndoTransition<T>? redo(T current) {
    if (_redoEntries.isEmpty) {
      return null;
    }
    final entry = _redoEntries.last;
    if (current != entry.before) {
      throw StateError(
        'Cannot redo ${entry.operationId}: the visible document drifted.',
      );
    }
    final nextUndo = <NarrativeUndoEntry<T>>[..._undoEntries, entry];
    final overflow = nextUndo.length - capacity;
    return NarrativeUndoTransition<T>(
      document: entry.after,
      entry: entry,
      stack: NarrativeUndoStack<T>(
        undoEntries: overflow > 0 ? nextUndo.sublist(overflow) : nextUndo,
        redoEntries: _redoEntries.sublist(0, _redoEntries.length - 1),
        capacity: capacity,
      ),
    );
  }
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  return normalized;
}
~~~

### `packages/map_editor/lib/src/infrastructure/repositories/file_narrative_document_recovery_store.dart`

~~~dart
import 'dart:convert';
import 'dart:io';

import '../../application/services/narrative_document_session.dart';
import '../../application/services/narrative_undo_stack.dart';

typedef NarrativeRecoveryDocumentEncoder<T> = Object? Function(T document);
typedef NarrativeRecoveryDocumentDecoder<T> = T Function(Object? value);

/// File-backed crash-recovery journal for one narrative document session.
///
/// The journal is written through a flushed sibling file then atomically
/// renamed. Invalid evidence is deliberately retained for inspection instead
/// of being silently discarded.
final class FileNarrativeDocumentRecoveryStore<T>
    implements NarrativeDocumentRecoveryStore<T> {
  FileNarrativeDocumentRecoveryStore({
    required String journalPath,
    required NarrativeRecoveryDocumentEncoder<T> encodeDocument,
    required NarrativeRecoveryDocumentDecoder<T> decodeDocument,
  })  : _journal = File(_requiredPath(journalPath)),
        _encodeDocument = encodeDocument,
        _decodeDocument = decodeDocument;

  final File _journal;
  final NarrativeRecoveryDocumentEncoder<T> _encodeDocument;
  final NarrativeRecoveryDocumentDecoder<T> _decodeDocument;

  String get journalPath => _journal.path;

  @override
  Future<NarrativeDocumentRecoveryRecord<T>?> read() async {
    if (!await _journal.exists()) {
      return null;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(await _journal.readAsString());
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Recovery journal cannot be decoded: $error');
    }
    return _decodeRecord(_object(decoded, 'journal'));
  }

  @override
  Future<void> write(NarrativeDocumentRecoveryRecord<T> record) async {
    final temp = File('${_journal.path}.tmp');
    await _journal.parent.create(recursive: true);
    final bytes = utf8.encode(jsonEncode(_encodeRecord(record)));
    final handle = await temp.open(mode: FileMode.write);
    try {
      await handle.writeFrom(bytes);
      await handle.flush();
    } finally {
      await handle.close();
    }

    // Verify the exact flushed envelope before exposing it as recovery data.
    try {
      final verification = jsonDecode(await temp.readAsString());
      _decodeRecord(_object(verification, 'journal'));
      await temp.rename(_journal.path);
    } on Object {
      if (await temp.exists()) {
        await temp.delete();
      }
      rethrow;
    }
  }

  @override
  Future<void> clear() async {
    if (await _journal.exists()) {
      await _journal.delete();
    }
    final temp = File('${_journal.path}.tmp');
    if (await temp.exists()) {
      await temp.delete();
    }
  }

  Map<String, Object?> _encodeRecord(
    NarrativeDocumentRecoveryRecord<T> record,
  ) {
    return <String, Object?>{
      'schemaVersion': record.schemaVersion,
      'documentId': record.documentId,
      'baseRevision': record.baseRevision,
      'baseline': _encodeDocument(record.baseline),
      'document': _encodeDocument(record.document),
      'undoEntries': record.undoEntries.map(_encodeEntry).toList(),
      'redoEntries': record.redoEntries.map(_encodeEntry).toList(),
    };
  }

  Map<String, Object?> _encodeEntry(NarrativeUndoEntry<T> entry) {
    return <String, Object?>{
      'operationId': entry.operationId,
      'label': entry.label,
      'before': _encodeDocument(entry.before),
      'after': _encodeDocument(entry.after),
    };
  }

  NarrativeDocumentRecoveryRecord<T> _decodeRecord(
    Map<String, Object?> json,
  ) {
    final schemaVersion = _integer(json['schemaVersion'], 'schemaVersion');
    if (schemaVersion != 1) {
      throw FormatException(
        'Unsupported recovery journal schemaVersion: $schemaVersion.',
      );
    }
    return NarrativeDocumentRecoveryRecord<T>(
      schemaVersion: schemaVersion,
      documentId: _text(json['documentId'], 'documentId'),
      baseRevision: _text(json['baseRevision'], 'baseRevision'),
      baseline: _decodeDocument(json['baseline']),
      document: _decodeDocument(json['document']),
      undoEntries: _decodeEntries(json['undoEntries'], 'undoEntries'),
      redoEntries: _decodeEntries(json['redoEntries'], 'redoEntries'),
    );
  }

  List<NarrativeUndoEntry<T>> _decodeEntries(Object? value, String field) {
    if (value is! List) {
      throw FormatException('$field must be a JSON list.');
    }
    return List<NarrativeUndoEntry<T>>.unmodifiable(
      value.map((item) {
        final json = _object(item, field);
        return NarrativeUndoEntry<T>(
          operationId: _text(json['operationId'], '$field.operationId'),
          label: _text(json['label'], '$field.label'),
          before: _decodeDocument(json['before']),
          after: _decodeDocument(json['after']),
        );
      }),
    );
  }
}

String _requiredPath(String value) {
  final path = value.trim();
  if (path.isEmpty) {
    throw ArgumentError.value(value, 'journalPath', 'must not be empty');
  }
  return path;
}

Map<String, Object?> _object(Object? value, String field) {
  if (value is! Map) {
    throw FormatException('$field must be a JSON object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$field contains a non-string key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _text(Object? value, String field) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string.');
  }
  return value.trim();
}

int _integer(Object? value, String field) {
  if (value is! int) {
    throw FormatException('$field must be an integer.');
  }
  return value;
}
~~~

### `packages/map_editor/lib/src/infrastructure/repositories/project_manifest_narrative_document_gateway.dart`

~~~dart
import 'dart:io';

import 'package:map_core/map_core.dart';

import '../../application/models/narrative_authoring_transaction.dart';
import '../../application/models/narrative_event_authoring_session.dart';
import '../../application/ports/narrative_authoring_persistence_gateway.dart';
import '../../application/services/narrative_document_session.dart';

/// Compare-and-swap adapter for the first document-session pilot.
///
/// NSC-13 deliberately allows only one existing Cinematic to change per save.
/// Creation, deletion, reordering, multi-asset changes and every other manifest
/// field remain on their existing transactional authoring paths.
final class ProjectManifestNarrativeDocumentGateway
    implements NarrativeDocumentGateway<ProjectManifest> {
  ProjectManifestNarrativeDocumentGateway({
    required String projectPath,
    required NarrativeAuthoringPersistenceGateway persistence,
  })  : projectPath = _requiredText(projectPath, 'projectPath'),
        _persistence = persistence;

  final String projectPath;
  final NarrativeAuthoringPersistenceGateway _persistence;

  @override
  Future<NarrativeDocumentVersion<ProjectManifest>> read() async {
    final bytes = await File(projectPath).readAsBytes();
    return NarrativeDocumentVersion<ProjectManifest>(
      revision: narrativeEventBytesFingerprint(bytes),
      document: decodeValidatedNarrativeEventAuthoringProject(bytes).manifest,
    );
  }

  @override
  Future<NarrativeDocumentSaveResult<ProjectManifest>> save({
    required String expectedRevision,
    required ProjectManifest before,
    required ProjectManifest after,
    required String operationId,
  }) async {
    final current = await _readOrFailure();
    if (current case NarrativeDocumentSaveFailed<ProjectManifest>()) {
      return current;
    }
    final live = current as NarrativeDocumentVersion<ProjectManifest>;
    if (live.revision != expectedRevision || live.document != before) {
      return NarrativeDocumentSaveResult<ProjectManifest>.conflicted(
        code: 'staleProjectRevision',
        message: 'The project changed since this document session started.',
        external: live,
      );
    }

    final mutation = _singleCinematicUpdate(before, after);
    if (mutation == null) {
      return const NarrativeDocumentSaveResult<ProjectManifest>.failed(
        code: 'unsupportedDocumentMutation',
        message: 'This document session can persist exactly one existing '
            'Cinematic update and no other project change.',
      );
    }

    late final NarrativeAuthoringPersistenceResult persistenceResult;
    try {
      persistenceResult = await _persistence.persist(
        NarrativeAuthoringTransaction.fromMutation(
          projectPath: projectPath,
          operationId: operationId,
          mutation: mutation,
        ),
      );
    } on Object catch (error) {
      return NarrativeDocumentSaveResult<ProjectManifest>.failed(
        code: 'projectManifestWriteFailed',
        message: 'The project manifest could not be persisted: $error',
      );
    }

    if (persistenceResult.status ==
        NarrativeAuthoringPersistenceStatus.committed) {
      final durable = await _readOrFailure();
      if (durable case NarrativeDocumentSaveFailed<ProjectManifest>()) {
        return durable;
      }
      final version = durable as NarrativeDocumentVersion<ProjectManifest>;
      if (version.document != after) {
        return const NarrativeDocumentSaveResult<ProjectManifest>.failed(
          code: 'durableDocumentMismatch',
          message: 'Persistence completed but the durable document does not '
              'match the requested Cinematic update.',
        );
      }
      return NarrativeDocumentSaveResult<ProjectManifest>.saved(version);
    }

    if (_isConflictCode(persistenceResult.code)) {
      final external = await _readOrFailure();
      if (external case NarrativeDocumentSaveFailed<ProjectManifest>()) {
        return external;
      }
      return NarrativeDocumentSaveResult<ProjectManifest>.conflicted(
        code: persistenceResult.code,
        message: persistenceResult.message,
        external: external as NarrativeDocumentVersion<ProjectManifest>,
      );
    }
    return NarrativeDocumentSaveResult<ProjectManifest>.failed(
      code: persistenceResult.code,
      message: persistenceResult.message,
    );
  }

  Future<Object> _readOrFailure() async {
    try {
      return await read();
    } on Object catch (error) {
      return NarrativeDocumentSaveResult<ProjectManifest>.failed(
        code: 'projectManifestReadFailed',
        message: 'The project manifest cannot be read safely: $error',
      );
    }
  }
}

NarrativeAssetUpdated? _singleCinematicUpdate(
  ProjectManifest before,
  ProjectManifest after,
) {
  if (before.copyWith(cinematics: after.cinematics) != after ||
      before.cinematics.length != after.cinematics.length) {
    return null;
  }
  final beforeIds = [for (final asset in before.cinematics) asset.id];
  final afterIds = [for (final asset in after.cinematics) asset.id];
  if (!_sameStrings(beforeIds, afterIds)) {
    return null;
  }
  final changedIndexes = <int>[];
  for (var index = 0; index < before.cinematics.length; index++) {
    if (before.cinematics[index] != after.cinematics[index]) {
      changedIndexes.add(index);
    }
  }
  if (changedIndexes.length != 1) {
    return null;
  }
  final index = changedIndexes.single;
  return NarrativeAssetUpdated(
    before: before,
    after: after,
    previousAsset: before.cinematics[index],
    asset: after.cinematics[index],
  );
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _isConflictCode(String code) {
  return code == 'staleProjectRevision' || code == 'projectChangedBeforeCommit';
}

String _requiredText(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, field, 'must not be empty');
  }
  return normalized;
}
~~~

### `packages/map_editor/lib/src/ui/design_system/pokemap_confirmation_dialog.dart`

~~~dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/theme.dart';
import 'pokemap_button.dart';
import 'pokemap_panel.dart';

const pokeMapConfirmationDialogKey =
    ValueKey<String>('pokemap-confirmation-dialog');

@immutable
final class PokeMapDialogAction<T> {
  const PokeMapDialogAction({
    required this.label,
    required this.value,
    this.variant = PokeMapButtonVariant.secondary,
  });

  final String label;
  final T value;
  final PokeMapButtonVariant variant;
}

/// Opens a token-driven, keyboard-dismissible decision dialog.
Future<T?> showPokeMapConfirmationDialog<T>({
  required BuildContext context,
  required String title,
  required String message,
  required List<PokeMapDialogAction<T>> actions,
  String barrierLabel = 'Fermer la confirmation',
}) {
  assert(actions.isNotEmpty);
  final colors = context.pokeMapColors;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: colors.chromeBackground.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 140),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _PokeMapConfirmationDialog<T>(
        title: title,
        message: message,
        actions: actions,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final class _PokeMapConfirmationDialog<T> extends StatelessWidget {
  const _PokeMapConfirmationDialog({
    required this.title,
    required this.message,
    required this.actions,
  });

  final String title;
  final String message;
  final List<PokeMapDialogAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return SafeArea(
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.of(context).pop(),
        },
        child: FocusTraversalGroup(
          child: Center(
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                key: pokeMapConfirmationDialogKey,
                container: true,
                scopesRoute: true,
                namesRoute: true,
                label: title,
                explicitChildNodes: true,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: PokeMapPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final action in actions)
                              PokeMapButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(action.value),
                                variant: action.variant,
                                size: PokeMapButtonSize.compact,
                                child: Text(action.label),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
~~~

### `packages/map_editor/test/narrative_document_persistence_test.dart`

~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_authoring_transaction.dart';
import 'package:map_editor/src/application/ports/narrative_authoring_persistence_gateway.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/application/services/narrative_undo_stack.dart';
import 'package:map_editor/src/infrastructure/repositories/file_narrative_document_recovery_store.dart';
import 'package:map_editor/src/infrastructure/repositories/project_manifest_narrative_document_gateway.dart';

void main() {
  group('FileNarrativeDocumentRecoveryStore', () {
    late Directory directory;
    late String journalPath;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('narrative-recovery-');
      journalPath = '${directory.path}/.pokemap/narrative-session.json';
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('round-trips the complete recovery envelope atomically', () async {
      final store = FileNarrativeDocumentRecoveryStore<String>(
        journalPath: journalPath,
        encodeDocument: (document) => document,
        decodeDocument: (value) => value! as String,
      );
      const entry = NarrativeUndoEntry<String>(
        operationId: 'cinematic-title-1',
        label: 'Renommer la cinématique',
        before: 'avant',
        after: 'après',
      );
      const record = NarrativeDocumentRecoveryRecord<String>(
        documentId: 'cinematics',
        baseRevision: 'revision-A',
        baseline: 'avant',
        document: 'après',
        undoEntries: [entry],
        redoEntries: [entry],
      );

      await store.write(record);

      final restored = await store.read();
      expect(restored, isNotNull);
      expect(restored!.documentId, 'cinematics');
      expect(restored.baseRevision, 'revision-A');
      expect(restored.baseline, 'avant');
      expect(restored.document, 'après');
      expect(restored.undoEntries.single.operationId, 'cinematic-title-1');
      expect(restored.redoEntries.single.after, 'après');
      expect(await File('$journalPath.tmp').exists(), isFalse);

      await store.clear();
      expect(await File(journalPath).exists(), isFalse);
    });

    test('reports malformed evidence without deleting it', () async {
      final journal = File(journalPath);
      await journal.parent.create(recursive: true);
      await journal.writeAsString('{not-json', flush: true);
      final store = FileNarrativeDocumentRecoveryStore<String>(
        journalPath: journalPath,
        encodeDocument: (document) => document,
        decodeDocument: (value) => value! as String,
      );

      await expectLater(store.read(), throwsFormatException);

      expect(await journal.exists(), isTrue);
      expect(await journal.readAsString(), '{not-json');
    });
  });

  group('ProjectManifestNarrativeDocumentGateway', () {
    late Directory directory;
    late File projectFile;
    late ProjectManifest before;
    late CinematicAsset cinematic;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('narrative-gateway-');
      projectFile = File('${directory.path}/project.json');
      cinematic = _cinematic(title: 'Introduction');
      before = _project(cinematics: [cinematic]);
      await _writeManifest(projectFile, before);
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('refuses a manifest change outside the Cinematics pilot', () async {
      final persistence = _RecordingPersistence();
      final gateway = ProjectManifestNarrativeDocumentGateway(
        projectPath: projectFile.path,
        persistence: persistence,
      );
      final version = await gateway.read();
      final after = before.copyWith(name: 'Projet remplacé');

      final result = await gateway.save(
        expectedRevision: version.revision,
        before: before,
        after: after,
        operationId: 'rename-project',
      );

      expect(result, isA<NarrativeDocumentSaveFailed<ProjectManifest>>());
      expect(
        (result as NarrativeDocumentSaveFailed<ProjectManifest>).code,
        'unsupportedDocumentMutation',
      );
      expect(persistence.calls, 0);
    });

    test('refuses create, delete and multiple Cinematic changes', () async {
      final persistence = _RecordingPersistence();
      final gateway = ProjectManifestNarrativeDocumentGateway(
        projectPath: projectFile.path,
        persistence: persistence,
      );
      final version = await gateway.read();
      final second = _cinematic(id: 'cinematic_second', title: 'Seconde');
      final cases = <ProjectManifest>[
        before.copyWith(cinematics: [cinematic, second]),
        before.copyWith(cinematics: const []),
        before.copyWith(cinematics: [
          _cinematic(title: 'Introduction modifiée'),
          second,
        ]),
      ];

      for (final after in cases) {
        final result = await gateway.save(
          expectedRevision: version.revision,
          before: before,
          after: after,
          operationId: 'unsupported-cinematic-shape',
        );
        expect(result, isA<NarrativeDocumentSaveFailed<ProjectManifest>>());
      }
      expect(persistence.calls, 0);
    });

    test('maps stale persistence to a conflict with the external document',
        () async {
      final external = _project(
        cinematics: [_cinematic(title: 'Modification externe')],
      );
      final persistence = _RecordingPersistence(
        handler: (_) async {
          await _writeManifest(projectFile, external);
          return const NarrativeAuthoringPersistenceResult(
            status: NarrativeAuthoringPersistenceStatus.persistenceFailed,
            code: 'projectChangedBeforeCommit',
            message: 'Concurrent write.',
          );
        },
      );
      final gateway = ProjectManifestNarrativeDocumentGateway(
        projectPath: projectFile.path,
        persistence: persistence,
      );
      final version = await gateway.read();
      final after = before.copyWith(
        cinematics: [_cinematic(title: 'Modification locale')],
      );

      final result = await gateway.save(
        expectedRevision: version.revision,
        before: before,
        after: after,
        operationId: 'cinematic-title-local',
      );

      expect(result, isA<NarrativeDocumentSaveConflicted<ProjectManifest>>());
      final conflict =
          result as NarrativeDocumentSaveConflicted<ProjectManifest>;
      expect(conflict.code, 'projectChangedBeforeCommit');
      expect(conflict.external.document, external);
      expect(persistence.calls, 1);
    });

    test('returns the exact durable document and revision after commit',
        () async {
      late ProjectManifest after;
      final persistence = _RecordingPersistence(
        handler: (transaction) async {
          await _writeManifest(projectFile, transaction.after);
          return const NarrativeAuthoringPersistenceResult.committed();
        },
      );
      final gateway = ProjectManifestNarrativeDocumentGateway(
        projectPath: projectFile.path,
        persistence: persistence,
      );
      final version = await gateway.read();
      after = before.copyWith(
        cinematics: [_cinematic(title: 'Introduction enregistrée')],
      );

      final result = await gateway.save(
        expectedRevision: version.revision,
        before: before,
        after: after,
        operationId: 'cinematic-title-save',
      );

      expect(result, isA<NarrativeDocumentSaved<ProjectManifest>>());
      final saved = result as NarrativeDocumentSaved<ProjectManifest>;
      final durableBytes = await projectFile.readAsBytes();
      expect(saved.version.document, after);
      expect(
        saved.version.revision,
        narrativeEventBytesFingerprint(durableBytes),
      );
      expect(persistence.calls, 1);
      expect(
          persistence.lastTransaction!.mutation, isA<NarrativeAssetUpdated>());
    });
  });
}

final class _RecordingPersistence
    implements NarrativeAuthoringPersistenceGateway {
  _RecordingPersistence({this.handler});

  final Future<NarrativeAuthoringPersistenceResult> Function(
    NarrativeAuthoringTransaction transaction,
  )? handler;
  int calls = 0;
  NarrativeAuthoringTransaction? lastTransaction;

  @override
  Future<NarrativeAuthoringPersistenceResult> persist(
    NarrativeAuthoringTransaction transaction,
  ) async {
    calls++;
    lastTransaction = transaction;
    if (handler case final callback?) {
      return callback(transaction);
    }
    return const NarrativeAuthoringPersistenceResult.committed();
  }
}

ProjectManifest _project({
  List<CinematicAsset> cinematics = const <CinematicAsset>[],
}) {
  return ProjectManifest(
    name: 'Narrative persistence test',
    maps: const [],
    tilesets: const [],
    cinematics: cinematics,
  );
}

CinematicAsset _cinematic({
  String id = 'cinematic_intro',
  required String title,
}) {
  return CinematicAsset(
    id: id,
    title: title,
    timeline: CinematicTimeline(),
  );
}

Future<void> _writeManifest(File file, ProjectManifest manifest) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    flush: true,
  );
}
~~~

### `packages/map_editor/test/narrative_document_session_test.dart`

~~~dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/application/services/narrative_undo_stack.dart';

void main() {
  group('NarrativeDocumentSession', () {
    test('initializes from disk as saved when no recovery exists', () async {
      final fixture = _fixture(diskDocument: 'disk-A', diskRevision: 'rev-A');

      await fixture.session.initialize();

      expect(fixture.session.state.isInitialized, isTrue);
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
      expect(fixture.session.state.document, 'disk-A');
      expect(fixture.session.state.baseline, 'disk-A');
      expect(fixture.session.state.baselineRevision, 'rev-A');
      expect(fixture.session.state.isDirty, isFalse);
    });

    test('journals an edit before publishing the dirty document', () async {
      final fixture = _fixture();
      await fixture.session.initialize();
      final visibleDuringWrite = <String>[];
      fixture.store.onWrite = (_) {
        visibleDuringWrite.add(fixture.session.state.document);
      };

      final applied = await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier la timeline',
        document: 'local-B',
      );

      expect(applied, isTrue);
      expect(visibleDuringWrite, ['disk-A']);
      expect(fixture.store.writeCount, 1);
      expect(fixture.store.record!.document, 'local-B');
      expect(fixture.session.state.document, 'local-B');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.dirty,
      );
      expect(fixture.session.state.canUndo, isTrue);
    });

    test('stays saving until persistence confirms and clears recovery after it',
        () async {
      final persistence = Completer<NarrativeDocumentSaveResult<String>>();
      final fixture = _fixture(saveHandler: (_) => persistence.future);
      await fixture.session.initialize();
      await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );

      final pending = fixture.session.save(operationId: 'save-1');
      await fixture.gateway.saveStarted.future;

      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saving,
      );
      expect(fixture.store.clearCount, 0);
      persistence.complete(
        const NarrativeDocumentSaveResult<String>.saved(
          NarrativeDocumentVersion(revision: 'rev-B', document: 'local-B'),
        ),
      );

      expect(await pending, isTrue);
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
      expect(fixture.session.state.baselineRevision, 'rev-B');
      expect(fixture.session.state.isDirty, isFalse);
      expect(fixture.store.clearCount, 1);
    });

    test('failed save keeps the exact local snapshot and recovery journal',
        () async {
      final fixture = _fixture(
        saveHandler: (_) async =>
            const NarrativeDocumentSaveResult<String>.failed(
          code: 'diskFull',
          message: 'Disk full',
        ),
      );
      await fixture.session.initialize();
      await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );

      final saved = await fixture.session.save(operationId: 'save-1');

      expect(saved, isFalse);
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.failed,
      );
      expect(fixture.session.state.document, 'local-B');
      expect(fixture.session.state.isDirty, isTrue);
      expect(fixture.session.state.code, 'diskFull');
      expect(fixture.store.record, isNotNull);
      expect(fixture.store.clearCount, 0);
    });

    test('refuses a concurrent save without a second gateway call', () async {
      final persistence = Completer<NarrativeDocumentSaveResult<String>>();
      final fixture = _fixture(saveHandler: (_) => persistence.future);
      await fixture.session.initialize();
      await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );

      final first = fixture.session.save(operationId: 'save-1');
      await fixture.gateway.saveStarted.future;
      final second = await fixture.session.save(operationId: 'save-2');

      expect(second, isFalse);
      expect(fixture.gateway.saveCount, 1);
      persistence.complete(
        const NarrativeDocumentSaveResult<String>.saved(
          NarrativeDocumentVersion(revision: 'rev-B', document: 'local-B'),
        ),
      );
      expect(await first, isTrue);
    });

    test('recovers the document and both history branches on matching base',
        () async {
      const first = NarrativeUndoEntry<String>(
        operationId: 'edit-1',
        label: 'Première',
        before: 'disk-A',
        after: 'local-B',
      );
      const second = NarrativeUndoEntry<String>(
        operationId: 'edit-2',
        label: 'Deuxième',
        before: 'local-B',
        after: 'local-C',
      );
      final fixture = _fixture(
        recovery: const NarrativeDocumentRecoveryRecord<String>(
          documentId: 'cinematics',
          baseRevision: 'rev-A',
          baseline: 'disk-A',
          document: 'local-B',
          undoEntries: [first],
          redoEntries: [second],
        ),
      );

      await fixture.session.initialize();

      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.recovered,
      );
      expect(fixture.session.state.document, 'local-B');
      expect(fixture.session.state.canUndo, isTrue);
      expect(fixture.session.state.canRedo, isTrue);
      expect(fixture.store.clearCount, 0);
    });

    test('clears a stale journal when its current document is already durable',
        () async {
      final fixture = _fixture(
        diskDocument: 'local-B',
        diskRevision: 'rev-B',
        recovery: const NarrativeDocumentRecoveryRecord<String>(
          documentId: 'cinematics',
          baseRevision: 'rev-A',
          baseline: 'disk-A',
          document: 'local-B',
        ),
      );

      await fixture.session.initialize();

      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
      expect(fixture.session.state.baselineRevision, 'rev-B');
      expect(fixture.store.clearCount, 1);
    });

    test('surfaces divergent recovery as a conflict with exact comparison',
        () async {
      final fixture = _fixture(
        diskDocument: 'external-C',
        diskRevision: 'rev-C',
        recovery: const NarrativeDocumentRecoveryRecord<String>(
          documentId: 'cinematics',
          baseRevision: 'rev-A',
          baseline: 'disk-A',
          document: 'local-B',
        ),
      );

      await fixture.session.initialize();

      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.conflicted,
      );
      expect(fixture.session.state.document, 'local-B');
      expect(fixture.session.comparison!.baseline, 'disk-A');
      expect(fixture.session.comparison!.local, 'local-B');
      expect(fixture.session.comparison!.external, 'external-C');
      expect(fixture.store.clearCount, 0);
    });

    test('keep local rebases on external revision and saves with CAS',
        () async {
      final fixture = _fixture(
        diskDocument: 'external-C',
        diskRevision: 'rev-C',
        recovery: const NarrativeDocumentRecoveryRecord<String>(
          documentId: 'cinematics',
          baseRevision: 'rev-A',
          baseline: 'disk-A',
          document: 'local-B',
        ),
        saveHandler: (_) async =>
            const NarrativeDocumentSaveResult<String>.saved(
          NarrativeDocumentVersion(revision: 'rev-D', document: 'local-B'),
        ),
      );
      await fixture.session.initialize();

      expect(await fixture.session.keepLocal(), isTrue);
      expect(fixture.session.state.baseline, 'external-C');
      expect(fixture.session.state.baselineRevision, 'rev-C');
      expect(fixture.session.state.document, 'local-B');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.dirty,
      );

      expect(await fixture.session.save(operationId: 'save-local'), isTrue);
      expect(fixture.gateway.lastSave!.expectedRevision, 'rev-C');
    });

    test('reload external is undoable and undo restores the local document',
        () async {
      final fixture = _fixture(
        diskDocument: 'external-C',
        diskRevision: 'rev-C',
        recovery: const NarrativeDocumentRecoveryRecord<String>(
          documentId: 'cinematics',
          baseRevision: 'rev-A',
          baseline: 'disk-A',
          document: 'local-B',
        ),
      );
      await fixture.session.initialize();

      expect(await fixture.session.reloadExternal(), isTrue);
      expect(fixture.session.state.document, 'external-C');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
      expect(fixture.session.state.canUndo, isTrue);

      expect(await fixture.session.undo(), isTrue);
      expect(fixture.session.state.document, 'local-B');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.dirty,
      );
      expect(fixture.store.record!.document, 'local-B');
    });

    test('recovery write failure refuses the visible edit', () async {
      final fixture = _fixture();
      await fixture.session.initialize();
      fixture.store.writeError = const FileSystemException('read only');

      final applied = await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );

      expect(applied, isFalse);
      expect(fixture.session.state.document, 'disk-A');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.failed,
      );
      expect(fixture.session.state.code, 'recoveryWriteFailed');
    });

    test('configurable autosave replaces its pending scheduled action',
        () async {
      final scheduler = _ManualScheduler();
      final fixture = _fixture(scheduler: scheduler.schedule);
      await fixture.session.initialize();

      await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );
      expect(scheduler.pending, isEmpty);

      fixture.session.setAutosaveEnabled(true);
      expect(scheduler.pending, hasLength(1));
      await fixture.session.apply(
        operationId: 'edit-2',
        label: 'Modifier encore',
        document: 'local-C',
      );

      expect(scheduler.cancelCount, 1);
      expect(scheduler.pending.where((task) => !task.cancelled), hasLength(1));
      await scheduler.runLatest();
      expect(fixture.gateway.saveCount, 1);
      expect(
          fixture.session.state.status, NarrativeDocumentSessionStatus.saved);
    });

    test('discard restores the durable baseline and clears both histories',
        () async {
      final fixture = _fixture();
      await fixture.session.initialize();
      await fixture.session.apply(
        operationId: 'edit-1',
        label: 'Modifier',
        document: 'local-B',
      );
      await fixture.session.undo();
      await fixture.session.redo();
      final clearsBeforeDiscard = fixture.store.clearCount;

      expect(await fixture.session.discard(), isTrue);
      expect(fixture.session.state.document, 'disk-A');
      expect(fixture.session.state.canUndo, isFalse);
      expect(fixture.session.state.canRedo, isFalse);
      expect(
          fixture.session.state.status, NarrativeDocumentSessionStatus.saved);
      expect(fixture.store.clearCount, clearsBeforeDiscard + 1);
    });

    test('explicit discard recovers from an unreadable recovery journal',
        () async {
      final fixture = _fixture();
      fixture.store.readError = const FormatException('broken journal');
      await fixture.session.initialize();

      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.failed,
      );
      expect(fixture.session.state.baselineRevision, isNull);

      fixture.store.readError = null;
      expect(await fixture.session.discard(), isTrue);
      expect(fixture.session.state.document, 'disk-A');
      expect(fixture.session.state.baselineRevision, 'rev-A');
      expect(
        fixture.session.state.status,
        NarrativeDocumentSessionStatus.saved,
      );
      expect(fixture.store.clearCount, 1);
    });
  });
}

_Fixture _fixture({
  String diskDocument = 'disk-A',
  String diskRevision = 'rev-A',
  NarrativeDocumentRecoveryRecord<String>? recovery,
  Future<NarrativeDocumentSaveResult<String>> Function(_SaveCall call)?
      saveHandler,
  NarrativeDocumentAutosaveScheduler? scheduler,
}) {
  final gateway = _FakeGateway(
    version: NarrativeDocumentVersion(
      revision: diskRevision,
      document: diskDocument,
    ),
    saveHandler: saveHandler,
  );
  final store = _FakeStore(record: recovery);
  return _Fixture(
    gateway: gateway,
    store: store,
    session: NarrativeDocumentSession<String>(
      documentId: 'cinematics',
      initialDocument: diskDocument,
      gateway: gateway,
      recoveryStore: store,
      autosaveDelay: const Duration(seconds: 2),
      autosaveScheduler: scheduler,
    ),
  );
}

final class _Fixture {
  const _Fixture({
    required this.gateway,
    required this.store,
    required this.session,
  });

  final _FakeGateway gateway;
  final _FakeStore store;
  final NarrativeDocumentSession<String> session;
}

typedef _SaveCall = ({
  String expectedRevision,
  String before,
  String after,
  String operationId,
});

final class _FakeGateway implements NarrativeDocumentGateway<String> {
  _FakeGateway({required this.version, this.saveHandler});

  NarrativeDocumentVersion<String> version;
  final Future<NarrativeDocumentSaveResult<String>> Function(_SaveCall call)?
      saveHandler;
  final Completer<void> saveStarted = Completer<void>();
  int readCount = 0;
  int saveCount = 0;
  _SaveCall? lastSave;

  @override
  Future<NarrativeDocumentVersion<String>> read() async {
    readCount++;
    return version;
  }

  @override
  Future<NarrativeDocumentSaveResult<String>> save({
    required String expectedRevision,
    required String before,
    required String after,
    required String operationId,
  }) async {
    saveCount++;
    final call = (
      expectedRevision: expectedRevision,
      before: before,
      after: after,
      operationId: operationId,
    );
    lastSave = call;
    if (!saveStarted.isCompleted) saveStarted.complete();
    final result = await (saveHandler?.call(call) ??
        Future.value(
          NarrativeDocumentSaveResult<String>.saved(
            NarrativeDocumentVersion(
              revision: 'rev-saved-$saveCount',
              document: after,
            ),
          ),
        ));
    if (result case NarrativeDocumentSaved<String>(:final version)) {
      this.version = version;
    }
    return result;
  }
}

final class _FakeStore implements NarrativeDocumentRecoveryStore<String> {
  _FakeStore({this.record});

  NarrativeDocumentRecoveryRecord<String>? record;
  Object? writeError;
  Object? readError;
  void Function(NarrativeDocumentRecoveryRecord<String> record)? onWrite;
  int readCount = 0;
  int writeCount = 0;
  int clearCount = 0;

  @override
  Future<NarrativeDocumentRecoveryRecord<String>?> read() async {
    readCount++;
    if (readError case final error?) throw error;
    return record;
  }

  @override
  Future<void> write(NarrativeDocumentRecoveryRecord<String> next) async {
    writeCount++;
    onWrite?.call(next);
    if (writeError case final error?) throw error;
    record = next;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    record = null;
  }
}

final class _ManualTask implements NarrativeDocumentAutosaveHandle {
  _ManualTask(this.callback, this.onCancel);

  final Future<void> Function() callback;
  final VoidCallback onCancel;
  bool cancelled = false;

  @override
  void cancel() {
    if (cancelled) return;
    cancelled = true;
    onCancel();
  }
}

final class _ManualScheduler {
  final List<_ManualTask> pending = [];
  int cancelCount = 0;

  NarrativeDocumentAutosaveHandle schedule(
    Duration _,
    Future<void> Function() callback,
  ) {
    final task = _ManualTask(callback, () => cancelCount++);
    pending.add(task);
    return task;
  }

  Future<void> runLatest() async {
    final task = pending.lastWhere((candidate) => !candidate.cancelled);
    await task.callback();
  }
}
~~~

### `packages/map_editor/test/narrative_document_session_workspace_adoption_test.dart`

~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_authoring_transaction.dart';
import 'package:map_editor/src/application/services/narrative_document_session.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

void main() {
  test('Cinematics pilot journals, undoes, redoes and saves through CAS',
      () async {
    final root = await Directory.systemTemp.createTemp('narrative-editor-');
    addTearDown(() => root.delete(recursive: true));
    final before = _project(title: 'Introduction');
    final after = _project(title: 'Introduction locale');
    await _writeProject(root, before);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(editorNotifierProvider, (_, __) {});
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(projectRootPath: root.path, project: before);

    final applied = await notifier.applyNarrativeDocumentEdit(
      after,
      operationId: 'cinematic-title-edit',
      label: 'Renommer la cinématique',
      statusMessage: 'Titre de la cinématique modifié.',
    );

    expect(
      applied,
      isTrue,
      reason: 'status=${notifier.narrativeDocumentStatus} '
          'error=${notifier.state.errorMessage} '
          'message=${notifier.state.statusMessage}',
    );
    expect(notifier.state.project, after);
    expect(notifier.state.isProjectDirty, isTrue);
    expect(notifier.canUndoNarrativeDocument, isTrue);
    expect(
      await File('${root.path}/.pokemap/recovery/narrative-cinematics.json')
          .exists(),
      isTrue,
    );
    expect((await _readProject(root)).cinematics.single.title, 'Introduction');

    expect(await notifier.undoNarrativeDocument(), isTrue);
    expect(notifier.state.project, before);
    expect(await notifier.redoNarrativeDocument(), isTrue);
    expect(notifier.state.project, after);

    expect(await notifier.saveNarrativeDocument(), isTrue);
    expect(notifier.state.isProjectDirty, isFalse);
    expect(
      notifier.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.saved,
    );
    expect(
      (await _readProject(root)).cinematics.single.title,
      'Introduction locale',
    );
    expect(
      await File('${root.path}/.pokemap/recovery/narrative-cinematics.json')
          .exists(),
      isFalse,
    );

    // A later non-session workspace edit must not expose the old Cinematics
    // history through the shared shell shortcuts.
    notifier.state = notifier.state.copyWith(
      project: after.copyWith(name: 'Unrelated Storyline edit'),
      isProjectDirty: true,
    );
    expect(notifier.canUndoNarrativeDocument, isFalse);
    expect(notifier.canRedoNarrativeDocument, isFalse);
  });

  test('a new editor session restores an unsaved Cinematics journal', () async {
    final root = await Directory.systemTemp.createTemp('narrative-reopen-');
    addTearDown(() => root.delete(recursive: true));
    final before = _project(title: 'Introduction');
    final recovered = _project(title: 'Récupérée');
    await _writeProject(root, before);

    final firstContainer = ProviderContainer();
    firstContainer.listen(editorNotifierProvider, (_, __) {});
    final first = firstContainer.read(editorNotifierProvider.notifier);
    first.state = EditorState(projectRootPath: root.path, project: before);
    final applied = await first.applyNarrativeDocumentEdit(
      recovered,
      operationId: 'cinematic-recovery-edit',
      label: 'Modifier avant fermeture',
    );
    expect(
      applied,
      isTrue,
      reason: 'status=${first.narrativeDocumentStatus} '
          'error=${first.state.errorMessage} '
          'message=${first.state.statusMessage}',
    );
    firstContainer.dispose();

    final secondContainer = ProviderContainer();
    addTearDown(secondContainer.dispose);
    secondContainer.listen(editorNotifierProvider, (_, __) {});
    final second = secondContainer.read(editorNotifierProvider.notifier);
    second.state = EditorState(projectRootPath: root.path, project: before);

    await second.initializeNarrativeDocumentSession();

    expect(second.state.project, recovered);
    expect(second.state.isProjectDirty, isTrue);
    expect(
      second.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.recovered,
    );
  });

  test('a committed structural mutation rebases the Cinematics pilot session',
      () async {
    final root = await Directory.systemTemp.createTemp('narrative-rebase-');
    addTearDown(() => root.delete(recursive: true));
    final before = _project(title: 'Introduction');
    await _writeProject(root, before);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(editorNotifierProvider, (_, __) {});
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(projectRootPath: root.path, project: before);
    await notifier.initializeNarrativeDocumentSession();

    final created = await notifier.executeNarrativeAuthoringMutation(
      (project) => NarrativeAssetMutation.createCinematic(
        project,
        title: 'Deuxième cinématique',
      ),
      operationId: 'create-second-cinematic',
    );

    expect(created!.status, NarrativeAuthoringTransactionStatus.committed);
    expect(notifier.state.project!.cinematics, hasLength(2));
    expect(
      notifier.narrativeDocumentStatus,
      NarrativeDocumentSessionStatus.saved,
    );

    final rebased = notifier.state.project!;
    final first = rebased.cinematics.first;
    final edited = rebased.copyWith(
      cinematics: [
        CinematicAsset(
          id: first.id,
          title: 'Introduction après création',
          timeline: first.timeline,
        ),
        rebased.cinematics.last,
      ],
    );
    expect(
      await notifier.applyNarrativeDocumentEdit(
        edited,
        operationId: 'edit-after-structural-change',
        label: 'Modifier après une création',
      ),
      isTrue,
    );
    expect(await notifier.saveNarrativeDocument(), isTrue);
    expect(
      (await _readProject(root)).cinematics.first.title,
      'Introduction après création',
    );
  });
}

ProjectManifest _project({required String title}) {
  return ProjectManifest(
    name: 'Narrative editor test',
    maps: const [],
    tilesets: const [],
    cinematics: [
      CinematicAsset(
        id: 'cinematic_intro',
        title: title,
        timeline: CinematicTimeline(),
      ),
    ],
  );
}

Future<void> _writeProject(Directory root, ProjectManifest project) {
  return File('${root.path}/project.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(project.toJson()),
    flush: true,
  );
}

Future<ProjectManifest> _readProject(Directory root) async {
  final json =
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>;
  return ProjectManifest.fromJson(json);
}
~~~

### `packages/map_editor/test/narrative_undo_stack_test.dart`

~~~dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/services/narrative_undo_stack.dart';

void main() {
  group('NarrativeUndoStack', () {
    test('records one complete intention and restores it through undo and redo',
        () {
      const stack = NarrativeUndoStack<String>(capacity: 3);

      final recorded = stack.record(
        operationId: 'rename-1',
        label: 'Renommer la cinématique',
        before: 'A',
        after: 'B',
      );
      final undo = recorded.undo('B');
      final redo = undo!.stack.redo('A');

      expect(recorded.canUndo, isTrue);
      expect(recorded.canRedo, isFalse);
      expect(undo.document, 'A');
      expect(undo.entry.operationId, 'rename-1');
      expect(undo.stack.canUndo, isFalse);
      expect(undo.stack.canRedo, isTrue);
      expect(redo!.document, 'B');
      expect(redo.stack.canUndo, isTrue);
      expect(redo.stack.canRedo, isFalse);
    });

    test('a new intention after undo clears the redo branch', () {
      const stack = NarrativeUndoStack<String>();
      final recorded = stack
          .record(
            operationId: 'edit-1',
            label: 'Première édition',
            before: 'A',
            after: 'B',
          )
          .record(
            operationId: 'edit-2',
            label: 'Deuxième édition',
            before: 'B',
            after: 'C',
          );
      final undone = recorded.undo('C')!;

      final branched = undone.stack.record(
        operationId: 'edit-3',
        label: 'Branche locale',
        before: undone.document,
        after: 'D',
      );

      expect(branched.canUndo, isTrue);
      expect(branched.canRedo, isFalse);
      expect(branched.undoEntries.map((entry) => entry.operationId), [
        'edit-1',
        'edit-3',
      ]);
    });

    test('capacity evicts the oldest intention and collections are immutable',
        () {
      var stack = const NarrativeUndoStack<String>(capacity: 2);
      for (var index = 0; index < 3; index++) {
        stack = stack.record(
          operationId: 'edit-$index',
          label: 'Édition $index',
          before: '$index',
          after: '${index + 1}',
        );
      }

      expect(
        stack.undoEntries.map((entry) => entry.operationId),
        ['edit-1', 'edit-2'],
      );
      expect(
        () => stack.undoEntries.add(
          const NarrativeUndoEntry(
            operationId: 'forbidden',
            label: 'Interdit',
            before: 'x',
            after: 'y',
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('a no-op preserves identity and blank intent metadata is rejected', () {
      const stack = NarrativeUndoStack<String>();

      expect(
        stack.record(
          operationId: 'same',
          label: 'Aucun changement',
          before: 'A',
          after: 'A',
        ),
        same(stack),
      );
      expect(
        () => stack.record(
          operationId: ' ',
          label: 'Libellé',
          before: 'A',
          after: 'B',
        ),
        throwsArgumentError,
      );
      expect(
        () => stack.record(
          operationId: 'edit',
          label: ' ',
          before: 'A',
          after: 'B',
        ),
        throwsArgumentError,
      );
    });

    test('undo and redo fail closed when the visible document drifted', () {
      final recorded = const NarrativeUndoStack<String>().record(
        operationId: 'edit',
        label: 'Édition',
        before: 'A',
        after: 'B',
      );
      final undone = recorded.undo('B')!;

      expect(() => recorded.undo('external'), throwsStateError);
      expect(() => undone.stack.redo('external'), throwsStateError);
    });

    test('a reconstructed stack preserves both recovery branches', () {
      const first = NarrativeUndoEntry<String>(
        operationId: 'first',
        label: 'Première',
        before: 'A',
        after: 'B',
      );
      const second = NarrativeUndoEntry<String>(
        operationId: 'second',
        label: 'Deuxième',
        before: 'B',
        after: 'C',
      );
      const restored = NarrativeUndoStack<String>(
        undoEntries: [first],
        redoEntries: [second],
        capacity: 5,
      );

      expect(restored.canUndo, isTrue);
      expect(restored.canRedo, isTrue);
      expect(restored.undoEntries.single, same(first));
      expect(restored.redoEntries.single, same(second));
    });
  });
}
~~~

### `packages/map_editor/test/ui/design_system/pokemap_confirmation_dialog_test.dart`

~~~dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('returns the typed action selected by the user', (tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Builder(
          builder: (context) => PokeMapButton(
            onPressed: () async {
              result = await showPokeMapConfirmationDialog<String>(
                context: context,
                title: 'Modifications en attente',
                message: 'Enregistrer avant de continuer ?',
                actions: const [
                  PokeMapDialogAction(label: 'Annuler', value: 'cancel'),
                  PokeMapDialogAction(
                    label: 'Ignorer',
                    value: 'discard',
                    variant: PokeMapButtonVariant.danger,
                  ),
                  PokeMapDialogAction(
                    label: 'Enregistrer',
                    value: 'save',
                    variant: PokeMapButtonVariant.success,
                  ),
                ],
              );
            },
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(find.byKey(pokeMapConfirmationDialogKey), findsOneWidget);
    expect(find.text('Modifications en attente'), findsOneWidget);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(result, 'save');
    expect(find.byKey(pokeMapConfirmationDialogKey), findsNothing);
  });
}
~~~

### `packages/map_editor/test/ui/shell/narrative_document_controls_test.dart`

~~~dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/editor_shell_page.dart';

import '../../shell_chrome_test_harness.dart';

void main() {
  testWidgets('chrome controls drive undo, redo, save and navigation guard',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    addTearDown(() => tester.runAsync(fixture.dispose));
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: fixture.root.path,
        project: fixture.before,
        workspaceMode: EditorWorkspaceMode.cutscene,
      ),
      surfaceSize: const Size(1672, 941),
      settleInitialFrame: false,
    );
    final notifier = container.read(editorNotifierProvider.notifier);
    await tester.runAsync(() async {
      await notifier.initializeNarrativeDocumentSession();
      await notifier.applyNarrativeDocumentEdit(
        fixture.local,
        operationId: 'ui-cinematic-edit',
        label: 'Renommer depuis le test UI',
      );
    });
    await _pumpUi(tester);

    expect(find.text('Modifié'), findsOneWidget);
    for (final key in [
      narrativeDocumentUndoActionKey,
      narrativeDocumentRedoActionKey,
      narrativeDocumentSaveActionKey,
      narrativeDocumentAutosaveActionKey,
      narrativeDocumentDiscardActionKey,
    ]) {
      expect(find.byKey(key), findsOneWidget);
    }

    await _invokeIconAction(
      tester,
      narrativeDocumentUndoActionKey,
      waitUntil: () =>
          notifier.state.project!.cinematics.single.title == 'Introduction',
    );
    await _pumpUi(tester);
    expect(notifier.state.project!.cinematics.single.title, 'Introduction');
    await _invokeIconAction(
      tester,
      narrativeDocumentRedoActionKey,
      waitUntil: () =>
          notifier.state.project!.cinematics.single.title == 'Version locale',
    );
    await _pumpUi(tester);
    expect(notifier.state.project!.cinematics.single.title, 'Version locale');

    await _invokeIconAction(
      tester,
      narrativeDocumentSaveActionKey,
      waitUntil: () => !notifier.narrativeDocumentBlocksNavigation,
    );
    final durableTitle = await tester.runAsync(
      () => _readCinematicTitle(fixture.root),
    );
    expect(durableTitle, 'Version locale');
    await tester.runAsync(() async {
      final current = notifier.state.project!;
      await notifier.applyNarrativeDocumentEdit(
        current.copyWith(cinematics: fixture.before.cinematics),
        operationId: 'ui-cinematic-second-edit',
        label: 'Préparer le garde de navigation',
      );
    });
    await _pumpUi(tester);

    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-product-nav-overview')),
    );
    await _pumpUi(tester);
    expect(find.text('Modifications Cinématiques en attente'), findsOneWidget);
    await tester.tap(find.text('Rester ici'));
    await _pumpUi(tester);
    expect(notifier.state.workspaceMode, EditorWorkspaceMode.cutscene);

    await _invokeIconAction(
      tester,
      narrativeDocumentDiscardActionKey,
      waitUntil: () =>
          notifier.state.project!.cinematics.single.title == 'Version locale' &&
          !notifier.narrativeDocumentBlocksNavigation,
    );
    await _pumpUi(tester);
    await tester.tap(
      find.byKey(const ValueKey('narrative-studio-product-nav-overview')),
    );
    await _pumpUi(tester);
    expect(notifier.state.workspaceMode, EditorWorkspaceMode.narrativeOverview);
    expect(notifier.state.project!.cinematics.single.title, 'Version locale');
    expect(find.byKey(narrativeDocumentUndoActionKey), findsNothing);
    expect(find.byKey(narrativeDocumentSaveActionKey), findsNothing);
  });

  testWidgets('conflict controls compare and reload the external version',
      (tester) async {
    final fixture = (await tester.runAsync(_fixture))!;
    addTearDown(() => tester.runAsync(fixture.dispose));
    final container = await pumpEditorShellPage(
      tester,
      initialState: EditorState(
        projectRootPath: fixture.root.path,
        project: fixture.before,
        workspaceMode: EditorWorkspaceMode.cutscene,
      ),
      surfaceSize: const Size(1672, 941),
      settleInitialFrame: false,
    );
    final notifier = container.read(editorNotifierProvider.notifier);
    final saved = await tester.runAsync(() async {
      await notifier.initializeNarrativeDocumentSession();
      await notifier.applyNarrativeDocumentEdit(
        fixture.local,
        operationId: 'ui-conflict-edit',
        label: 'Préparer un conflit',
      );
      await _writeProject(fixture.root, fixture.external);
      return notifier.saveNarrativeDocument();
    });

    expect(saved, isFalse);
    await _pumpUi(tester);

    expect(find.text('Conflit'), findsOneWidget);
    expect(find.byKey(narrativeDocumentCompareActionKey), findsOneWidget);
    expect(find.byKey(narrativeDocumentReloadActionKey), findsOneWidget);
    expect(find.byKey(narrativeDocumentKeepLocalActionKey), findsOneWidget);

    await tester.tap(find.byKey(narrativeDocumentCompareActionKey));
    await _pumpUi(tester);
    expect(find.text('Comparer les versions Cinématiques'), findsOneWidget);
    expect(find.text('Base de la session'), findsOneWidget);
    expect(find.text('Version locale récupérable'), findsOneWidget);
    expect(find.text('Version externe sur disque'), findsOneWidget);
    await tester.tap(find.byTooltip('Fermer'));
    await _pumpUi(tester);

    await _invokeIconAction(
      tester,
      narrativeDocumentReloadActionKey,
      waitUntil: () =>
          notifier.state.project!.cinematics.single.title == 'Version externe',
    );
    await _pumpUi(tester);
    expect(notifier.state.project!.cinematics.single.title, 'Version externe');
    expect(find.text('Enregistré'), findsOneWidget);
  });
}

final class _Fixture {
  const _Fixture({
    required this.root,
    required this.before,
    required this.local,
    required this.external,
  });

  final Directory root;
  final ProjectManifest before;
  final ProjectManifest local;
  final ProjectManifest external;

  Future<void> dispose() => root.delete(recursive: true);
}

Future<_Fixture> _fixture() async {
  final root = await Directory.systemTemp.createTemp('narrative-ui-session-');
  final before = _project('Introduction');
  final local = _project('Version locale');
  final external = _project('Version externe');
  await _writeProject(root, before);
  return _Fixture(
    root: root,
    before: before,
    local: local,
    external: external,
  );
}

ProjectManifest _project(String title) {
  return ProjectManifest(
    name: 'Narrative UI session',
    maps: const [],
    tilesets: const [],
    cinematics: [
      CinematicAsset(
        id: 'cinematic_intro',
        title: title,
        timeline: CinematicTimeline(),
      ),
    ],
  );
}

Future<void> _writeProject(Directory root, ProjectManifest project) {
  return File('${root.path}/project.json').writeAsString(
    const JsonEncoder.withIndent('  ').convert(project.toJson()),
    flush: true,
  );
}

Future<String> _readCinematicTitle(Directory root) async {
  final json =
      jsonDecode(await File('${root.path}/project.json').readAsString())
          as Map<String, dynamic>;
  return ProjectManifest.fromJson(json).cinematics.single.title;
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 220));
}

Future<void> _invokeIconAction(
  WidgetTester tester,
  Key key, {
  required bool Function() waitUntil,
}) async {
  final button = tester.widget<PokeMapIconButton>(find.byKey(key));
  await tester.runAsync(() async {
    button.onPressed!.call();
    await _waitUntil(waitUntil);
  });
}

Future<void> _waitUntil(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('The asynchronous UI action did not complete.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}
~~~
