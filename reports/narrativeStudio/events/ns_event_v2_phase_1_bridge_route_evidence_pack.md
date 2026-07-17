# NS-EVENT-V2 — Phase 1 — Bridge, route produit et liste projet

Date : 2026-07-16
Révision auditée : `2f68328a38bf218c843e497940f8dd24a7a9c194`
Branche : `main`
Lots : `G0`, `V0`, `H1`, `H2`

Verdict : **IMPLEMENTATION CANDIDATE / FORMAL CLOSURE NOT ELIGIBLE**

## 1. Résumé exécutif

La Phase 1 est techniquement livrée : la vraie route produit choisit V1 ou V2
selon le mode, V2 charge un snapshot projet attesté depuis le disque, la liste
présente tous les Events du projet sans dépendre de la map active, et les deux
round-trips Event ↔ Map sont couverts sur le vrai `MapCanvas`. Le contrat visuel
canonique est versionné et testé.

La phase ne peut toutefois pas être déclarée `DONE` dans la roadmap. S0 n'a
pas été fermé et aucun checkpoint récupérable n'a été autorisé. Par transitivité,
les lots futurs restent formellement `NOT STARTED`. V0 attend aussi
l'approbation explicite de l'écart P2 proposé pour l'Inspecteur, et G0 conserve
des captures exhaustives manquantes. Le code est donc un candidat technique
complet, sans faux reclassement documentaire.

| Lot | Résultat technique | Statut formel | Réserve |
|---|---|---|---|
| G0 | `PASS` ciblé | `NOT STARTED` | S0, checkpoint et captures exhaustives |
| V0 | `VERIFYING` | `NOT STARTED` | approbation utilisateur de l'exception P2 |
| H1 | `PASS` technique | `NOT STARTED` | dépend de V0/G0 formellement fermés |
| H2 | `PASS` technique | `NOT STARTED` | dépend de H1 formellement fermé |
| Phase 1 | implémentation candidate complète | pas `DONE` | gate formel non éligible |

Le dashboard normatif reste donc à `0/24 lots DONE` et `0/7 phases DONE`.

## 2. Audit critique initial

L'ordre demandé « faire la Phase 1 » sautait S0, alors que la roadmap impose
qu'une dépendance non `DONE` maintienne le lot suivant en `NOT STARTED`. Le
travail a continué sous l'interprétation minimale suivante : implémenter et
valider techniquement G0/V0/H1/H2, sans inventer le checkpoint ni modifier le
tableau maître.

Constats initiaux :

- G existait avec une matrice fonctionnelle ciblée, mais sa clôture formelle
  restait bloquée ;
- la référence visuelle n'était pas protégée par un contrat V0 autonome ;
- la route produit `NarrativeWorkspaceCanvas` montait encore V1 ;
- le state/workspace V2 existait, mais la liste projet n'était pas prouvée sur
  un projet disque réel ;
- le checkout était déjà très chargé par F2, G, H/K/L et des changements hors
  Event ; ils ont été préservés.

Contrats préservés : `Event ≠ Scene`, source physique créée sur la map, map
dérivée de la source atomique, aucune création de géométrie depuis l'Event
Builder, aucun picker map indépendant et aucun write legacy en `v2Only`.

## 3. Scope et non-objectifs

Inclus :

- politique de montage `legacyOnly → V1`, `dualRead/v2Only → V2` ;
- loader production attesté par racine projet et fingerprint du manifest ;
- erreur fail-closed, retry explicite et garde contre une map non sauvegardée ;
- sélection unique détenue par le bridge ;
- Event spatial → Map → même Event ;
- draft sans source → Map → création physique → même draft ;
- liste projet complète, groupes map/Global, statuts, recherche et filtres ;
- référence 1672×941, hash, huit rectangles et tolérances P0/P1/P2.

Hors scope conservé : authoring détaillé H3/H4, migration I, runtime J,
fermeture pixel-perfect K, gate L, correction des diagnostics globaux du
package et toute opération Git d'écriture.

## 4. État Git initial

```text
HEAD : 2f68328a38bf218c843e497940f8dd24a7a9c194
Branche : main
Tracked modified : 42
Untracked : 84
Total : 126
```

Aucun `git add`, commit, branche, stash, reset, restore ou worktree n'a été
créé. La demande utilisateur précisait qu'un worktree dédié n'était pas
nécessaire ; elle n'autorisait pas d'autre écriture Git.

## 5. Verdicts des passes et sub-agents

| Passe | Verdict | Conséquence |
|---|---|---|
| Audit / Architecture | `CANDIDATE ONLY` | S0 empêche toute clôture formelle |
| Audit H2 | `PRODUCTION SUFFISANTE, PREUVE À AJOUTER` | ajout du corpus disque et de quatre tests dédiés |
| Implémentation | `PASS TECHNIQUE` | route, provider, garde dirty et round-trips livrés |
| Tests | `PASS CIBLÉ` | matrice groupée finale `446/446` |
| Build / Validation | `PASS CIBLÉ` | analyse Phase 1 propre et build macOS vert |
| Critique H1 finale | `VALIDÉE TECHNIQUEMENT` | aucun défaut P0/P1 ; deux risques P2 documentés |
| Audit preuves | `FORMAL CLOSURE NOT ELIGIBLE` | S0/checkpoint, approbation V0 et captures G restent requis |

La critique finale a détecté une fuite possible du contexte d'un draft sans
source entre deux racines projet. Le cache a été borné par `projectRootPath` et
un test de non-régression a été ajouté. Elle a aussi relevé que le contrat V0
auto-ratifiait son propre écart de 1 px : le texte exige désormais une
approbation utilisateur explicite et le test fige les valeurs numériques.

## 6. Preuves G0

La matrice canonique G a été rejouée avant le gate groupé : `410/410`. Les
invariants couverts comprennent source existante, focus caméra, retour exact,
création physique guidée, journal préparé avant mutation, retry, cleanup,
dirty/saving, interlocks et absence de writer concurrent.

L'addendum append-only de
`ns_event_v2_phase_g_evidence_pack.md` ajoute les preuves de la route H1 sans
effacer son verdict historique. G0 reste formellement bloqué par S0 et par les
captures exhaustives MapEntity/MapTrigger/mapEnter demandées par la roadmap.

## 7. Preuves V0

Référence canonique :

```text
Fichier : event_builder_v2_reference_1672x941.png
Dimensions : 1672 × 941
SHA-256 : 2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885
Test final : +3, All tests passed!
```

Le test exécutable fige les octets, la taille, l'état de fixture, les huit
rectangles et les tolérances numériques. L'écart `Inspecteur x=1275` contre le
bord visuel proche de `1274` est une proposition P2, pas une auto-approbation.

## 8. Preuves H1

Le provider production construit sa requête à partir de la racine normalisée
et du fingerprint canonique du manifest. Il appelle
`NarrativeEventAuthoringSession.prepare(project.json)` et refuse un snapshot
dont le manifest disque a dérivé. La route :

- ne monte qu'un workspace autorisé ;
- ne retourne jamais silencieusement à V1 sur erreur ;
- invalide explicitement le provider lors d'un retry ;
- suspend la lecture disque lorsque la map active contient des changements non
  sauvegardés, puis recharge après sauvegarde ;
- conserve le contexte map des drafts sans source, sans fuite inter-projets ;
- délègue la sélection au bridge ;
- affiche les échecs de navigation au lieu de les avaler.

Le test produit final contient neuf scénarios. Il monte `EditorCanvasHost`, le
vrai `NarrativeWorkspaceCanvas` et le vrai `MapCanvas`. La lecture production
par défaut est aussi rejouée après persistance pour prouver que la nouvelle
source `map_port` vient bien du disque.

Limite P2 : le geste de tap carte qui prépare la proposition reste couvert par
la matrice G ; le scénario H1 appelle directement le contrôleur pour cette
étape, puis exerce les contrôles UI de confirmation et de retour.

## 9. Preuves H2

Le corpus temporaire réel possède deux maps et six Events : actifs, inactif,
draft, source manquante, Global et compatibilité legacy. Les quatre tests
dédiés prouvent :

- visibilité de tous les groupes indépendamment de la map active ;
- statuts et lieu dérivés exclusivement de la source ;
- absence de raw ID et de picker map ;
- sélection conservée à travers recherche, filtres et refresh ;
- lecture production complète depuis le disque ;
- mismatch manifest/disque rejeté fail-closed.

H2 reste en lecture seule : aucune mutation du registre n'est introduite dans
la liste.

## 10. Inventaire des fichiers du lot

### Créés

- `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart`
  — clé de snapshot et provider disque attesté ;
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart`
  — route produit V2, guards et round-trips ;
- `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart`
  — projet disque réel à deux maps ;
- `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`
  — neuf tests H1 et capture conditionnelle ;
- `packages/map_editor/test/ui/canvas/event_builder_v2_project_list_test.dart`
  — quatre tests H2 ;
- `packages/map_editor/test/ui/canvas/event_builder_v2_reference_contract_test.dart`
  — trois tests V0 ;
- `packages/map_editor/test/goldens/event_builder_v2/reference/event_builder_v2_reference_1672x941.png`
  — raster canonique ;
- `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_product_route_1672x941.png`
  — capture de route métier réelle ;
- `reports/narrativeStudio/events/ns_event_v2_v0_visual_contract.md`
  — contrat de comparaison ;
- le présent Evidence Pack.

### Modifiés

- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` :
  la branche Event choisit désormais V1 ou `EventBuilderV2ProductRoute` selon
  `EventSystemMode`, avec une seule instance montée ;
- `reports/narrativeStudio/events/ns_event_v2_phase_g_evidence_pack.md` :
  addendum append-only des preuves Phase 1, sans réécriture historique.

Les autres changements visibles dans Git sont antérieurs ou étrangers à ce
lot et n'ont pas été restaurés, nettoyés ou revendiqués.

## 11. TDD et commandes exactes

RED V0 :

```text
flutter test --no-pub test/ui/canvas/event_builder_v2_reference_contract_test.dart
00:00 +1 -2: Some tests failed.
```

Les deux échecs attendaient la référence et le contrat absents.

GREEN final groupé :

```text
flutter test --no-pub --reporter=compact <matrice G + V0 + H1 + H2>
01:50 +446: All tests passed!
```

Relance V0 après durcissement numérique :

```text
flutter test --no-pub --reporter=compact \
  test/ui/canvas/event_builder_v2_reference_contract_test.dart
00:04 +3: All tests passed!
```

Capture réelle conditionnelle :

```text
flutter test --no-pub --update-goldens \
  --dart-define=NS_EVENT_V2_PHASE_1_CAPTURE=true \
  --reporter=compact --concurrency=1 \
  test/ui/canvas/event_builder_v2_product_route_test.dart
00:07 +9: All tests passed!
```

Analyse ciblée finale :

```text
flutter analyze --no-pub <7 fichiers Dart Phase 1>
Analyzing 7 items...
No issues found! (ran in 3.3s)
```

Analyse complète du package :

```text
flutter analyze --no-pub
451 issues found. (ran in 10.9s)
```

Ces 451 diagnostics correspondent à la dette globale déjà observée avant les
dernières corrections Phase 1. Faute de baseline S0 formelle, le présent pack
ne prétend pas démontrer leur antériorité diagnostic par diagnostic. Les sept
fichiers Dart du lot sont propres.

Format :

```text
dart format --output=none --set-exit-if-changed <7 fichiers Dart Phase 1>
Formatted 7 files (0 changed) in 0.03 seconds.
```

Build :

```text
flutter build macos --debug --no-pub
✓ Built build/macos/Build/Products/Debug/map_editor.app
```

Hygiène :

```text
git diff --check : exit 0
trailing whitespace, fichiers texte Phase 1 : aucune occurrence
packages/map_editor/test/failures : aucun fichier
selbrume/*.lock : aucun fichier
journal/temp/backup sous map_editor hors build/.dart_tool : aucun fichier
```

## 12. Capture et comparaison visuelle

```text
Candidate Phase 1 :
  dimensions : 1672 × 941
  SHA-256 : 659ffee22cd5440254b1711c9f4a6bc866029a422a0ff18db0564f841a36e131

Référence :
  dimensions : 1672 × 941
  SHA-256 : 2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885
```

La candidate est une capture de la composition métier réelle et lisible en
cinq colonnes. Elle ne constitue pas la fermeture visuelle globale : elle ne
capture ni le header marque ni la barre contexte/actions de la fenêtre
complète, et son origine verticale diffère donc de V0. Cette dette appartient
à K et n'est pas maquillée en réussite Phase 1.

## 13. Décisions et non-régressions

- aucun fallback V1 sur un snapshot V2 incohérent ;
- aucune sélection map indépendante de la source ;
- aucun writer registry exposé par H2 ;
- aucune fuite de contexte draft entre projets ;
- aucun read snapshot disque pendant une map non sauvegardée ;
- aucune dépendance de production au harness visuel K ;
- aucune modification Event/Scene/runtime hors scope.

## 14. Auto-critique et risques restants

1. La capture conditionnelle est un test volontairement neutre sans le
   `dart-define`; la preuve visuelle n'existe que dans la commande explicite.
2. La capture porte sur le workspace métier, pas la fenêtre complète V0.
3. Le contrat V0 reste dépendant d'une police système Arial pour la capture.
4. L'exception P2 de 1 px n'est pas approuvée par l'utilisateur.
5. G0 manque encore ses captures exhaustives par famille de source.
6. S0 et son checkpoint récupérable restent le blocker transversal.
7. La dette globale de 451 diagnostics n'est pas corrigée par ce lot.

La revue indépendante ne trouve aucun P0/P1 dans H1. Les points ci-dessus sont
des limites de preuve, de gate formel ou des risques P2 explicitement conservés.

## 15. État Git final

Après création du présent pack, l'état final vérifié est de 42 fichiers suivis
modifiés, 94 non suivis, soit 136 entrées. Les changements sans rapport restent
présents et aucune opération Git d'écriture n'a été exécutée.

## 16. Statut proposé et prochaine étape

Statut honnête : `PHASE 1 IMPLEMENTATION CANDIDATE`, pas `DONE`.

La prochaine étape unique pour rendre la clôture possible est de revenir au
gate S0 : choisir et autoriser un checkpoint récupérable, établir la baseline,
puis ratifier ou refuser explicitement l'exception V0. Ensuite seulement les
lots G0 → V0 → H1 → H2 pourront être fermés dans l'ordre.

## 17. Annexes de contenu complet

Le présent Evidence Pack est exclu de sa propre annexe pour éviter une
récursion documentaire. Les PNG sont des binaires : leur contenu complet est
attesté par leurs dimensions et SHA-256 en section 12. Le fichier G est un
rapport préexistant modifié uniquement par l'addendum montré en section 6 ; le
fichier suivi `narrative_workspace_canvas.dart` est décrit précisément en
section 10. Tous les autres fichiers texte créés sont reproduits intégralement
ci-dessous.


### Annexe — `packages/map_editor/lib/src/features/narrative/state/narrative_event_builder_v2_providers.dart`

~~~~dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../../application/models/narrative_event_authoring_session.dart';

/// Immutable cache key for one attested Event Builder project snapshot.
///
/// The semantic fingerprint deliberately changes whenever the in-memory
/// manifest changes. This prevents a successful registry write from leaving
/// the product route attached to an older disk read model.
final class NarrativeEventBuilderV2SnapshotRequest {
  const NarrativeEventBuilderV2SnapshotRequest({
    required this.projectRootPath,
    required this.expectedManifestFingerprint,
  });

  factory NarrativeEventBuilderV2SnapshotRequest.fromProject({
    required String projectRootPath,
    required ProjectManifest project,
  }) {
    return NarrativeEventBuilderV2SnapshotRequest(
      projectRootPath: p.normalize(projectRootPath),
      expectedManifestFingerprint:
          narrativeEventBuilderV2ManifestFingerprint(project),
    );
  }

  final String projectRootPath;
  final String expectedManifestFingerprint;

  @override
  bool operator ==(Object other) {
    return other is NarrativeEventBuilderV2SnapshotRequest &&
        other.projectRootPath == projectRootPath &&
        other.expectedManifestFingerprint == expectedManifestFingerprint;
  }

  @override
  int get hashCode => Object.hash(
        projectRootPath,
        expectedManifestFingerprint,
      );
}

String narrativeEventBuilderV2ManifestFingerprint(ProjectManifest project) {
  return narrativeEventBytesFingerprint(
    canonicalizeNarrativeEventJsonUtf8(project.toJson()),
  );
}

/// Typed failure used instead of silently falling back to the legacy writer.
final class NarrativeEventBuilderV2SnapshotMismatch implements Exception {
  const NarrativeEventBuilderV2SnapshotMismatch();

  @override
  String toString() =>
      'Le projet en mémoire et le projet enregistré ne correspondent plus.';
}

typedef LoadNarrativeEventBuilderV2ReadModel
    = Future<NarrativeEventBuilderProjectReadModel> Function(
  NarrativeEventBuilderV2SnapshotRequest request,
);

/// Replaceable I/O seam used by the product route and focused widget tests.
///
/// It composes the existing attested session and canonical map_core read model;
/// it owns no registry mutation and therefore cannot become a second engine.
final narrativeEventBuilderV2ReadModelLoaderProvider =
    Provider<LoadNarrativeEventBuilderV2ReadModel>((ref) {
  return (request) async {
    final session = await NarrativeEventAuthoringSession.prepare(
      p.join(request.projectRootPath, 'project.json'),
    );
    if (narrativeEventBuilderV2ManifestFingerprint(session.manifest) !=
        request.expectedManifestFingerprint) {
      throw const NarrativeEventBuilderV2SnapshotMismatch();
    }
    return buildNarrativeEventBuilderProjectReadModel(
      project: session.manifest,
      maps: session.maps,
    );
  };
});

final narrativeEventBuilderV2ReadModelProvider = FutureProvider.autoDispose
    .family<NarrativeEventBuilderProjectReadModel,
        NarrativeEventBuilderV2SnapshotRequest>((ref, request) {
  return ref.watch(narrativeEventBuilderV2ReadModelLoaderProvider)(request);
});
~~~~

### Annexe — `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart`

~~~~dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/narrative_event_map_bridge_models.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../features/editor/state/editor_state.dart';
import '../../../features/narrative/state/narrative_event_builder_v2_providers.dart';
import '../../../features/narrative/state/narrative_event_builder_v2_state.dart';
import '../../../features/narrative/state/narrative_event_map_bridge_state.dart';
import '../../design_system/design_system.dart';
import 'event_builder_v2_element_library.dart';
import 'event_builder_v2_workspace.dart';

/// Production composition boundary for Event Builder V2.
///
/// This widget reads one complete, attested project snapshot and delegates all
/// Map navigation/selection to the Phase G bridge. It deliberately contains no
/// registry writer and no active-map-derived list fallback.
class EventBuilderV2ProductRoute extends ConsumerStatefulWidget {
  const EventBuilderV2ProductRoute({
    super.key,
    required this.viewportWidth,
  });

  final double viewportWidth;

  @override
  ConsumerState<EventBuilderV2ProductRoute> createState() =>
      _EventBuilderV2ProductRouteState();
}

class _EventBuilderV2ProductRouteState
    extends ConsumerState<EventBuilderV2ProductRoute> {
  String _query = '';
  NarrativeEventBuilderV2Filter _filter = NarrativeEventBuilderV2Filter.all;
  String? _selectedCompatibilityStableKey;
  final _sourceLessMapContexts = <String, NarrativeEventGroupContext>{};
  String? _sourceLessContextProjectRoot;

  @override
  Widget build(BuildContext context) {
    final editor = ref.watch(editorNotifierProvider);
    final project = editor.project;
    final projectRootPath = editor.projectRootPath?.trim();
    if (project == null || projectRootPath == null || projectRootPath.isEmpty) {
      return const PokeMapPageSurface(
        child: PokeMapEmptyState(
          title: 'Projet indisponible',
          description:
              'Ouvrez un projet enregistré pour charger ses événements.',
          icon: Icon(CupertinoIcons.folder),
        ),
      );
    }
    if (_sourceLessContextProjectRoot != projectRootPath) {
      _sourceLessContextProjectRoot = projectRootPath;
      _sourceLessMapContexts.clear();
    }

    final mode = project.eventRegistry?.mode ?? EventSystemMode.legacyOnly;
    if (mode == EventSystemMode.legacyOnly) {
      // The parent router owns the legacy/V2 policy. Failing closed here keeps
      // a future integration mistake from mounting a second authoring engine.
      return const PokeMapPageSurface(
        child: PokeMapEmptyState(
          title: 'Mode historique',
          description: 'Le projet utilise l’éditeur d’événements historique.',
          icon: Icon(CupertinoIcons.archivebox),
        ),
      );
    }
    if (editor.isDirty) {
      return const PokeMapPageSurface(
        key: ValueKey('event-builder-v2-unsaved-map-gate'),
        child: Center(
          child: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            title: 'Map non enregistrée',
            message: 'Enregistrez la map active avant de charger les '
                'événements du projet. La vue Event ne réutilise jamais un '
                'snapshot disque devenu obsolète.',
          ),
        ),
      );
    }

    final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
      projectRootPath: projectRootPath,
      project: project,
    );
    final readModel = ref.watch(
      narrativeEventBuilderV2ReadModelProvider(request),
    );
    return readModel.when(
      loading: _buildLoading,
      error: (error, _) => _buildError(error, request),
      data: (value) => _buildWorkspace(
        context,
        editor: editor,
        readModel: value,
        mode: mode,
      ),
    );
  }

  Widget _buildLoading() {
    return PokeMapPageSurface(
      key: const ValueKey('event-builder-v2-product-loading'),
      child: Center(
        child: Semantics(
          label: 'Chargement des événements du projet',
          child: const CupertinoActivityIndicator(),
        ),
      ),
    );
  }

  Widget _buildError(
    Object error,
    NarrativeEventBuilderV2SnapshotRequest request,
  ) {
    final mismatch = error is NarrativeEventBuilderV2SnapshotMismatch;
    return PokeMapPageSurface(
      key: const ValueKey('event-builder-v2-product-error'),
      child: Center(
        child: PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.error,
          title: mismatch
              ? 'Projet modifié pendant le chargement'
              : 'Événements indisponibles',
          message: mismatch
              ? 'Enregistrez ou rechargez le projet avant de continuer.'
              : 'Le projet ne peut pas préparer une vue Event V2 sûre. '
                  'Aucun éditeur historique n’a été ouvert à la place.',
          actionLabel: 'Réessayer',
          onAction: () => ref.invalidate(
            narrativeEventBuilderV2ReadModelProvider(request),
          ),
        ),
      ),
    );
  }

  Widget _buildWorkspace(
    BuildContext context, {
    required EditorState editor,
    required NarrativeEventBuilderProjectReadModel readModel,
    required EventSystemMode mode,
  }) {
    final bridge = ref.watch(narrativeEventMapBridgeControllerProvider);
    final state = NarrativeEventBuilderV2State(
      readModel: readModel,
      query: _query,
      filter: _filter,
      selectedCompatibilityStableKey: _selectedCompatibilityStableKey,
    );
    final selected = selectedNarrativeEventBuilderV2Event(
      state: state,
      bridgeState: bridge,
    );
    final canMutateSelected = !state.isReadOnly && selected?.readOnly == false;

    final workspace = EventBuilderV2Workspace(
      state: state,
      mode: mode,
      selectedStableKey: selected?.stableKey,
      viewportWidth: widget.viewportWidth,
      onQueryChanged: (value) => setState(() => _query = value),
      onFilterChanged: (value) => setState(() => _filter = value),
      onSelectEvent: _selectEvent,
      // H3 owns creation/persistence. Keeping the CTA disabled is truthful and
      // also guarantees that v2Only never calls the legacy draft writer.
      onCreateEvent: null,
      onOpenLibrary: () => _openLibrary(context, selected),
      onChangeSource: canMutateSelected && _canChangeSource(selected!, bridge)
          ? () => _changeSource(selected)
          : null,
      onSeeOnMap: _canSeeOnMap(selected)
          ? () => _openMapForEvent(
                selected!,
                NarrativeEventMapNavigationMode.view,
              )
          : null,
      // Detailed Event/Scene authoring remains H3/H4. Null callbacks render
      // disabled controls instead of fake interactions.
      onAddCondition: null,
      onChangeScene: null,
      onOpenScene: null,
      onChangeBehavior: null,
      onManageEvaluationOrder: null,
    );
    final navigationFailure = bridge.lastNavigationResult;
    if (navigationFailure == null || navigationFailure.succeeded) {
      return workspace;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: PokeMapDiagnosticCallout(
            key: const ValueKey('event-builder-v2-navigation-error'),
            severity: PokeMapDiagnosticSeverity.warning,
            title: 'Navigation vers la map impossible',
            message: navigationFailure.message,
          ),
        ),
        Expanded(child: workspace),
      ],
    );
  }

  void _selectEvent(NarrativeEventProjectSummary event) {
    if (event.readOnly || event.eventId == null) {
      setState(() => _selectedCompatibilityStableKey = event.stableKey);
      return;
    }

    final editor = ref.read(editorNotifierProvider);
    final project = editor.project;
    if (project == null) return;
    final bridge = ref.read(narrativeEventMapBridgeControllerProvider);
    final previousEventId = bridge.selectedNarrativeEventV2Id;
    final previousGroup = bridge.selectedGroupContext;
    if (previousEventId != null &&
        previousGroup?.kind == NarrativeEventGroupContextKind.map) {
      _sourceLessMapContexts[previousEventId] = previousGroup!;
    }
    var groupContext = narrativeEventGroupContextForSummary(event);
    // A source-less draft created from Map Editor carries its intended map in
    // the bridge. Preserve that atomic context instead of inventing a picker.
    if (event.source.source == null &&
        bridge.selectedNarrativeEventV2Id == event.eventId &&
        bridge.selectedGroupContext != null) {
      groupContext = bridge.selectedGroupContext!;
    } else if (event.source.source == null) {
      groupContext = _sourceLessMapContexts[event.eventId] ?? groupContext;
    }
    final selected = ref
        .read(narrativeEventMapBridgeControllerProvider.notifier)
        .selectNarrativeEventV2(
          project,
          event.eventId!,
          groupContext: groupContext,
        );
    if (selected) {
      if (event.source.source == null &&
          groupContext.kind == NarrativeEventGroupContextKind.map) {
        _sourceLessMapContexts[event.eventId!] = groupContext;
      }
      setState(() => _selectedCompatibilityStableKey = null);
    }
  }

  bool _canChangeSource(
    NarrativeEventProjectSummary event,
    NarrativeEventMapBridgeState bridge,
  ) {
    if (event.eventId == null || event.readOnly) return false;
    final source = event.source.source;
    if (source == null) {
      return bridge.selectedNarrativeEventV2Id == event.eventId &&
          bridge.selectedGroupContext?.kind ==
              NarrativeEventGroupContextKind.map;
    }
    return event.source.available &&
        source.kind != NarrativeEventSourceKind.outcomeReceived &&
        event.source.mapId != null;
  }

  bool _canSeeOnMap(NarrativeEventProjectSummary? event) {
    final source = event?.source.source;
    return event?.eventId != null &&
        event?.source.available == true &&
        source != null &&
        source.kind != NarrativeEventSourceKind.outcomeReceived;
  }

  Future<void> _changeSource(NarrativeEventProjectSummary event) async {
    final source = event.source.source;
    if (source == null) {
      await _openMapForMissingSource(event);
      return;
    }
    await _openMapForEvent(
      event,
      NarrativeEventMapNavigationMode.choose,
    );
  }

  Future<void> _openMapForEvent(
    NarrativeEventProjectSummary event,
    NarrativeEventMapNavigationMode mode,
  ) async {
    final eventId = event.eventId;
    final project = ref.read(editorNotifierProvider).project;
    if (eventId == null || project == null || !_canSeeOnMap(event)) return;
    final editor = ref.read(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final controller = ref.read(
      narrativeEventMapBridgeControllerProvider.notifier,
    );
    final result = await controller.openMapForEvent(
      eventId: eventId,
      groupContext: narrativeEventGroupContextForSummary(event),
      mode: mode,
      project: project,
      activeMap: editor.activeMap,
      mapDirty: editor.isDirty,
      loadMapSnapshot: notifier.loadMapSnapshotById,
      activateMapSnapshot: notifier.activateNarrativeEventMapSnapshot,
      applyFocus: notifier.focusNarrativeEventMapSource,
    );
    if (!result.succeeded || !mounted) return;
    await _inspectPendingSourceCreation(controller);
    if (mounted) notifier.selectMapWorkspace();
  }

  Future<void> _openMapForMissingSource(
    NarrativeEventProjectSummary event,
  ) async {
    final eventId = event.eventId;
    final editor = ref.read(editorNotifierProvider);
    final project = editor.project;
    final groupContext = ref
        .read(narrativeEventMapBridgeControllerProvider)
        .selectedGroupContext;
    if (eventId == null ||
        project == null ||
        groupContext?.kind != NarrativeEventGroupContextKind.map) {
      return;
    }
    final notifier = ref.read(editorNotifierProvider.notifier);
    final controller = ref.read(
      narrativeEventMapBridgeControllerProvider.notifier,
    );
    final result = await controller.openMapForMissingSource(
      eventId: eventId,
      groupContext: groupContext!,
      project: project,
      activeMap: editor.activeMap,
      mapDirty: editor.isDirty,
      loadMapSnapshot: notifier.loadMapSnapshotById,
      activateMapSnapshot: notifier.activateNarrativeEventMapSnapshot,
    );
    if (!result.succeeded || !mounted) return;
    await _inspectPendingSourceCreation(controller);
    if (mounted) notifier.selectMapWorkspace();
  }

  Future<void> _inspectPendingSourceCreation(
    NarrativeEventMapBridgeController controller,
  ) async {
    final editor = ref.read(editorNotifierProvider);
    await controller.inspectPendingSourceCreation(
      projectRootPath: editor.projectRootPath,
      mapDirty: editor.isDirty,
      projectDirty: editor.isProjectDirty,
      saving: editor.isSaving,
    );
  }

  Future<void> _openLibrary(
    BuildContext context,
    NarrativeEventProjectSummary? selected,
  ) {
    return showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Bibliothèque d’éléments',
      semanticLabel: 'Bibliothèque d’éléments de l’événement',
      barrierLabel: 'Fermer la bibliothèque d’éléments',
      width: 420,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(8),
        child: EventBuilderV2ElementLibrary(
          hasLinkedScene: selected?.scene.sceneId != null,
          onOpenScene: null,
        ),
      ),
    );
  }
}
~~~~

### Annexe — `packages/map_editor/test/support/event_builder_v2_product_route_fixture.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_spatial_source_creation_gateway.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:path/path.dart' as p;

const productRoutePortEventId = 'evt_00000000-0000-7000-8000-000000000201';
const productRouteForestEventId = 'evt_00000000-0000-7000-8000-000000000202';
const productRouteDraftEventId = 'evt_00000000-0000-7000-8000-000000000203';
const productRouteMissingEventId = 'evt_00000000-0000-7000-8000-000000000204';
const productRouteOutcomeEventId = 'evt_00000000-0000-7000-8000-000000000205';

/// Real on-disk project snapshot used by H1/H2 route tests.
///
/// Keeping this fixture on disk is intentional: a synthetic read model would
/// only re-test the Phase K harness and could not prove that the product route
/// reads every map from one attested authoring session.
final class EventBuilderV2ProductRouteFixture {
  EventBuilderV2ProductRouteFixture._({
    required this.root,
    required this.projectPath,
    required this.project,
    required this.portMap,
    required this.forestMap,
    required this.readModel,
  });

  final Directory root;
  final String projectPath;
  final ProjectManifest project;
  final MapData portMap;
  final MapData forestMap;
  final NarrativeEventBuilderProjectReadModel readModel;

  static Future<EventBuilderV2ProductRouteFixture> create({
    required EventSystemMode mode,
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_event_v2_product_route_',
    );
    final portMap = _map(
      id: 'map_port',
      name: 'Port Selbrume',
      entityId: 'npc_rival',
      entityName: 'Rival',
      legacyEvent: const MapEventDefinition(
        id: 'legacy_port',
        title: 'Ancienne rumeur au port',
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_action'),
          ),
        ],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    );
    final forestMap = _map(
      id: 'map_forest',
      name: 'Forêt Brumeuse',
      entityId: 'npc_spirit',
      entityName: 'Esprit de la forêt',
    );
    final project = ProjectManifest(
      name: 'Selbrume Route Test',
      maps: const [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port Selbrume',
          relativePath: 'maps/port.json',
        ),
        ProjectMapEntry(
          id: 'map_forest',
          name: 'Forêt Brumeuse',
          relativePath: 'maps/forest.json',
        ),
      ],
      tilesets: const [],
      scenes: [
        _scene('scene_action', 'Rencontre'),
        _scene('scene_rival', 'Duel du rival', outcomeId: 'victory'),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: mode,
        records: [
          _configured(
            productRoutePortEventId,
            'Rencontre rival au port',
            NarrativeEventSourceRef.entityInteract('map_port', 'npc_rival'),
            enabled: true,
          ),
          _configured(
            productRouteForestEventId,
            'Écho dans la brume',
            NarrativeEventSourceRef.entityInteract(
              'map_forest',
              'npc_spirit',
            ),
            enabled: false,
          ),
          _draft(productRouteDraftEventId, 'Événement à préparer'),
          _draft(
            productRouteMissingEventId,
            'Objet disparu',
            source: NarrativeEventSourceRef.entityInteract(
              'map_port',
              'npc_absent',
            ),
          ),
          _configured(
            productRouteOutcomeEventId,
            'Après la victoire',
            NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.scene,
                producerId: 'scene_rival',
                outcomeId: 'victory',
              ),
            ),
            enabled: true,
          ),
        ],
        legacyClaims: const [],
      ),
    );
    final projectPath = p.join(root.path, 'project.json');
    await _writeJson(File(projectPath), project.toJson());
    await _writeJson(
      File(p.join(root.path, 'maps', 'port.json')),
      portMap.toJson(),
    );
    await _writeJson(
      File(p.join(root.path, 'maps', 'forest.json')),
      forestMap.toJson(),
    );
    final session = await NarrativeEventAuthoringSession.prepare(projectPath);
    final readModel = buildNarrativeEventBuilderProjectReadModel(
      project: session.manifest,
      maps: session.maps,
    );
    return EventBuilderV2ProductRouteFixture._(
      root: root,
      projectPath: projectPath,
      project: project,
      portMap: portMap,
      forestMap: forestMap,
      readModel: readModel,
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Future<EventBuilderV2ProductRouteFixture>
    createEventBuilderV2ProductRouteFixture(
  WidgetTester tester, {
  required EventSystemMode mode,
}) async {
  final fixture = await tester.runAsync(
    () => EventBuilderV2ProductRouteFixture.create(mode: mode),
  );
  if (fixture == null) {
    throw TestFailure('The on-disk Event Builder fixture was not created.');
  }
  addTearDown(() => tester.runAsync(fixture.dispose));
  return fixture;
}

Future<ProviderContainer> pumpEventBuilderV2ProductRoute(
  WidgetTester tester, {
  required EventBuilderV2ProductRouteFixture fixture,
  MapData? activeMap,
  Size viewport = const Size(1672, 941),
  String? fontFamily,
  LoadNarrativeEventBuilderV2ReadModel? readModelLoader,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final container = ProviderContainer(
    overrides: [
      // Widget tests run in FakeAsync. The fixture above already passed the
      // production attested-session loader in real async, so the UI receives
      // that exact read model through the replaceable I/O seam.
      narrativeEventBuilderV2ReadModelLoaderProvider.overrideWithValue(
        readModelLoader ?? (_) => Future.value(fixture.readModel),
      ),
      narrativeEventSpatialSourceCreationGatewayProvider.overrideWithValue(
        _InitialClearSourceCreationGateway(
          NarrativeEventSpatialLinkJournalRepository(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  final subscription = container.listen(editorNotifierProvider, (_, __) {});
  addTearDown(subscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    projectRootPath: fixture.root.path,
    project: fixture.project,
    workspaceMode: EditorWorkspaceMode.events,
    activeMap: activeMap ?? fixture.portMap,
    activeLayerId: 'events',
  );

  final baseTheme = PokeMapTheme.dark();
  final theme = fontFamily == null
      ? baseTheme
      : baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(fontFamily: fontFamily),
          primaryTextTheme:
              baseTheme.primaryTextTheme.apply(fontFamily: fontFamily),
        );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(
          body: SizedBox.expand(child: EditorCanvasHost()),
        ),
      ),
    ),
  );
  await pumpEventBuilderV2ProductRouteFrames(
    tester,
    container: container,
  );
  return container;
}

/// Advances a bounded number of frames instead of waiting on unrelated
/// repeating chrome animations that can keep [pumpAndSettle] alive forever.
Future<void> pumpEventBuilderV2ProductRouteFrames(
  WidgetTester tester, {
  ProviderContainer? container,
  int count = 2,
}) async {
  for (var index = 0; index < count; index++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  // The last real-async interval can complete a provider future; one final
  // frame is required to render that AsyncValue.
  await tester.pump();
}

Future<void> waitForEventBuilderV2BridgeIdle(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 200; attempt++) {
      final bridge = container.read(narrativeEventMapBridgeControllerProvider);
      if (!bridge.isSourceCreationBusy && !bridge.isLinkingSource) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    throw TestFailure('The Event/Map bridge did not become idle.');
  });
  await tester.pump();
}

MapData _map({
  required String id,
  required String name,
  required String entityId,
  required String entityName,
  MapEventDefinition? legacyEvent,
}) {
  return MapData(
    id: id,
    name: name,
    size: const GridSize(width: 8, height: 8),
    layers: const [MapLayer.object(id: 'events', name: 'Événements')],
    entities: [
      MapEntity(
        id: entityId,
        name: entityName,
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 1, y: 1),
      ),
    ],
    events: [if (legacyEvent != null) legacyEvent],
  );
}

NarrativeEventRecord _configured(
  String id,
  String name,
  NarrativeEventSourceRef source, {
  required bool enabled,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: const [],
      sceneId: 'scene_action',
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

NarrativeEventRecord _draft(
  String id,
  String name, {
  NarrativeEventSourceRef? source,
}) {
  return NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: id,
      name: name,
      source: source,
      conditions: const [],
      priority: 0,
      order: 0,
    ),
  );
}

SceneAsset _scene(String id, String name, {String? outcomeId}) {
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
    declaredOutcomes: outcomeId == null
        ? const []
        : [SceneOutcome(id: outcomeId, label: 'Victoire')],
  );
}

Future<void> _writeJson(File file, Map<String, Object?> json) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(json),
    flush: true,
  );
}

/// Keeps the first recovery probe deterministic under WidgetTest's FakeAsync,
/// then delegates every durable operation to the production journal gateway.
///
/// The product fixture is freshly created and therefore cannot contain a
/// pending spatial-link journal before navigation. Subsequent inspections must
/// remain real because source creation uses them to acknowledge its two-step
/// map/registry commit.
final class _InitialClearSourceCreationGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  _InitialClearSourceCreationGateway(this._delegate);

  final NarrativeEventSpatialSourceCreationGateway _delegate;
  var _firstInspection = true;

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) {
    if (_firstInspection) {
      _firstInspection = false;
      return Future.value(
        NarrativeEventSpatialLinkInspection(
          status: NarrativeEventSpatialLinkInspectionStatus.clear,
        ),
      );
    }
    return _delegate.inspectProject(projectPath);
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) =>
      _delegate.commitMap(request);

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) =>
      _delegate.recoverProject(
        projectPath: projectPath,
        expectedOperationId: expectedOperationId,
        expectedEventId: expectedEventId,
        expectedMapId: expectedMapId,
        expectedSource: expectedSource,
      );

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) =>
      _delegate.markEventCommitted(
        projectPath: projectPath,
        operationId: operationId,
      );

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) =>
      _delegate.acknowledgeEventCommitted(
        projectPath: projectPath,
        operationId: operationId,
      );

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) =>
      _delegate.cleanupSource(
        projectPath: projectPath,
        operationId: operationId,
        confirmed: confirmed,
      );
}
~~~~

### Annexe — `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart`

~~~~dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_source_creation_models.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/ui/canvas/events/event_builder_workspace.dart';
import 'package:map_editor/src/ui/canvas/events_v2/event_builder_v2_workspace.dart';
import 'package:map_editor/src/ui/canvas/map_canvas.dart';
import 'package:map_editor/src/ui/canvas/narrative_workspace_canvas.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../support/event_builder_v2_product_route_fixture.dart';
import '../../support/event_builder_v2_visual_harness.dart';

const _capturePhase1 = bool.fromEnvironment('NS_EVENT_V2_PHASE_1_CAPTURE');

void main() {
  group('NS-EVENT-V2 H1 product route', () {
    for (final mode in EventSystemMode.values) {
      testWidgets('routes ${mode.name} to its single authorized workspace',
          (tester) async {
        final fixture = await createEventBuilderV2ProductRouteFixture(
          tester,
          mode: mode,
        );

        await pumpEventBuilderV2ProductRoute(tester, fixture: fixture);

        final usesV1 = mode == EventSystemMode.legacyOnly;
        expect(
          find.byType(EventBuilderWorkspace),
          usesV1 ? findsOne : findsNothing,
        );
        expect(
          find.byType(EventBuilderV2Workspace),
          usesV1 ? findsNothing : findsOne,
        );
        if (!usesV1) {
          // V2 modes must not leave a hidden legacy write path mounted.
          expect(
            find.byKey(const ValueKey('event-builder-create-event-button')),
            findsNothing,
          );
          expect(
            find.byKey(const ValueKey('event-builder-new-event-button')),
            findsNothing,
          );
        }
      });
    }

    testWidgets('fails closed on snapshot drift and retries without V1',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      var attempts = 0;
      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) {
          attempts++;
          if (attempts == 1) {
            return Future.error(
              const NarrativeEventBuilderV2SnapshotMismatch(),
            );
          }
          return Future.value(fixture.readModel);
        },
      );

      expect(
        find.byKey(const ValueKey('event-builder-v2-product-error')),
        findsOneWidget,
      );
      expect(find.byType(EventBuilderWorkspace), findsNothing);
      await tester.tap(find.text('Réessayer'));
      await pumpEventBuilderV2ProductRouteFrames(tester);

      expect(attempts, 2);
      expect(find.byType(EventBuilderV2Workspace), findsOneWidget);
      expect(find.byType(EventBuilderWorkspace), findsNothing);
    });

    testWidgets('reloads its disk snapshot after an unsaved map gate',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      var loads = 0;
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) {
          loads++;
          return Future.value(fixture.readModel);
        },
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      expect(loads, 1);

      notifier.state = notifier.state.copyWith(isDirty: true);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('event-builder-v2-unsaved-map-gate')),
        findsOneWidget,
      );
      expect(find.byType(EventBuilderV2Workspace), findsNothing);

      notifier.state = notifier.state.copyWith(isDirty: false);
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );
      expect(loads, 2);
      expect(find.byType(EventBuilderV2Workspace), findsOneWidget);
    });

    testWidgets('does not leak a source-less map context across projects',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
      );
      final bridge = container.read(
        narrativeEventMapBridgeControllerProvider.notifier,
      );
      expect(
        bridge.selectNarrativeEventV2(
          fixture.project,
          productRouteDraftEventId,
          groupContext: const NarrativeEventGroupContext.map('map_port'),
        ),
        isTrue,
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRoutePortEventId',
          ),
        ),
      );
      await tester.pump();

      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = notifier.state.copyWith(
        projectRootPath: '${fixture.root.path}/second_project',
      );
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRouteDraftEventId',
          ),
        ),
      );
      await tester.pump();

      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedGroupContext,
        const NarrativeEventGroupContext.global(),
      );
    });

    testWidgets('round-trips a spatial Event through the Map bridge exactly',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
      );

      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRoutePortEventId',
          ),
        ),
      );
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );
      await tester.tap(find.text('Voir sur la carte').first);
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );
      await waitForEventBuilderV2BridgeIdle(tester, container);

      final bridge = container.read(narrativeEventMapBridgeControllerProvider);
      expect(bridge.selectedNarrativeEventV2Id, productRoutePortEventId);
      expect(
        bridge.selectedGroupContext,
        const NarrativeEventGroupContext.map('map_port'),
      );
      expect(bridge.pendingReturn?.eventId, productRoutePortEventId);
      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.map,
      );
      expect(find.byType(MapCanvas), findsOneWidget);
      expect(
        find.byKey(const ValueKey('narrative-event-map-banner')),
        findsOneWidget,
      );
      expect(bridge.focusRequest?.focusTarget.kind,
          NarrativeEditorFocusTargetKind.entity);
      expect(bridge.focusRequest?.focusTarget.mapId, 'map_port');
      expect(bridge.focusRequest?.focusTarget.ownerId, 'npc_rival');
      expect(bridge.focusRequest?.cameraApplied, isTrue);

      await tester.tap(
        find.byKey(const ValueKey('narrative-event-map-return')),
      );
      await pumpEventBuilderV2ProductRouteFrames(tester);

      expect(find.byType(EventBuilderV2Workspace), findsOneWidget);
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedNarrativeEventV2Id,
        productRoutePortEventId,
      );
      expect(find.text('Rencontre rival au port'), findsWidgets);
    });

    testWidgets(
        'creates a missing physical source and returns to the same draft',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
      );
      final bridgeController = container.read(
        narrativeEventMapBridgeControllerProvider.notifier,
      );
      final notifier = container.read(editorNotifierProvider.notifier);

      expect(
        bridgeController.selectNarrativeEventV2(
          fixture.project,
          productRouteDraftEventId,
          groupContext: const NarrativeEventGroupContext.map('map_port'),
        ),
        isTrue,
      );
      await pumpEventBuilderV2ProductRouteFrames(tester);
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRoutePortEventId',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRouteDraftEventId',
          ),
        ),
      );
      await tester.pump();
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .selectedGroupContext,
        const NarrativeEventGroupContext.map('map_port'),
      );
      await tester.tap(find.text('Choisir un élément').first);
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );
      await waitForEventBuilderV2BridgeIdle(tester, container);

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.map,
      );
      expect(find.byType(MapCanvas), findsOneWidget);
      expect(
        find.byKey(const ValueKey('narrative-event-map-banner')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('narrative-event-create-kind-npc')),
      );
      await tester.pump();
      final proposal = notifier.proposeNarrativeEventSourceAt(
        position: const GridPos(x: 3, y: 3),
        kind: NarrativeEventPhysicalSourceKind.npc,
      );
      expect(proposal, isNotNull);
      expect(
        bridgeController.previewSourceCreationProposal(proposal!),
        isTrue,
      );
      await tester.pump();
      expect(
        container
            .read(narrativeEventMapBridgeControllerProvider)
            .sourceCreationProposal,
        isNotNull,
      );
      final confirm = tester.widget<PokeMapButton>(
        find.byKey(const ValueKey('narrative-event-create-confirm')),
      );
      expect(confirm.onPressed, isNotNull);
      await tester.runAsync(() async {
        confirm.onPressed!();
        for (var attempt = 0; attempt < 400; attempt++) {
          final bridge =
              container.read(narrativeEventMapBridgeControllerProvider);
          if (!bridge.isSourceCreationBusy &&
              bridge.lastSourceCreationResult != null) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        fail('The product source-creation flow did not complete.');
      });
      await pumpEventBuilderV2ProductRouteFrames(tester);

      final afterReturn = container.read(
        narrativeEventMapBridgeControllerProvider,
      );
      expect(afterReturn.lastSourceCreationResult?.status.name, 'committed');
      expect(afterReturn.selectedNarrativeEventV2Id, productRouteDraftEventId);
      expect(
        afterReturn.selectedGroupContext,
        const NarrativeEventGroupContext.map('map_port'),
      );
      expect(find.byType(EventBuilderV2Workspace), findsOneWidget);
      expect(find.text('Événement à préparer'), findsWidgets);

      final refreshed = await tester.runAsync(() async {
        final freshContainer = ProviderContainer();
        try {
          final editor = container.read(editorNotifierProvider);
          final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
            projectRootPath: fixture.root.path,
            project: editor.project!,
          );
          return await freshContainer.read(
            narrativeEventBuilderV2ReadModelProvider(request).future,
          );
        } finally {
          freshContainer.dispose();
        }
      });
      final persistedDraft = refreshed!.events.singleWhere(
        (event) => event.eventId == productRouteDraftEventId,
      );
      expect(persistedDraft.source.available, isTrue);
      expect(persistedDraft.source.mapId, 'map_port');
    });

    testWidgets('conditionally captures the actual V2 product route',
        (tester) async {
      if (!_capturePhase1) return;
      await loadEventBuilderV2PhaseKCaptureFonts();
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.dualRead,
      );
      final container = await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        fontFamily: eventBuilderV2PhaseKCaptureFontFamily,
      );
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRoutePortEventId',
          ),
        ),
      );
      await pumpEventBuilderV2ProductRouteFrames(
        tester,
        container: container,
      );

      final route = find.byType(NarrativeWorkspaceCanvas);
      expect(tester.getSize(route), const Size(1672, 941));
      final output = File(
        'test/goldens/event_builder_v2/phase_1/'
        'event_builder_v2_product_route_1672x941.png',
      );
      output.parent.createSync(recursive: true);
      await expectLater(
        route,
        matchesGoldenFile(output.absolute.path),
      );
    });
  });
}
~~~~

### Annexe — `packages/map_editor/test/ui/canvas/event_builder_v2_project_list_test.dart`

~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_map_bridge_models.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';

import '../../support/event_builder_v2_product_route_fixture.dart';

void main() {
  group('NS-EVENT-V2 H2 product project list', () {
    testWidgets(
      'shows every project group independently from the active map',
      (tester) async {
        final fixture = await createEventBuilderV2ProductRouteFixture(
          tester,
          mode: EventSystemMode.dualRead,
        );
        final container = await pumpEventBuilderV2ProductRoute(
          tester,
          fixture: fixture,
          activeMap: fixture.forestMap,
        );

        expect(fixture.readModel.events, hasLength(6));
        for (final event in fixture.readModel.events) {
          expect(
            find.byKey(
              ValueKey('event-builder-v2-event-${event.stableKey}'),
            ),
            findsOneWidget,
          );
        }
        expect(find.text('Port Selbrume'), findsWidgets);
        expect(find.text('Forêt Brumeuse'), findsWidgets);
        expect(find.text('Événements globaux'), findsOneWidget);
        expect(find.text('Brouillons à terminer'), findsOneWidget);
        expect(find.text('Références à réparer'), findsOneWidget);
        expect(find.text('Ancien format à convertir'), findsOneWidget);
        final list = find.byKey(const ValueKey('event-builder-v2-list'));
        expect(
          find.descendant(of: list, matching: find.text('Actif')),
          findsNWidgets(2),
        );
        expect(
          find.descendant(of: list, matching: find.text('Inactif')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: list, matching: find.text('Brouillon')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: list, matching: find.text('Manquant')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: list, matching: find.text('Ancien')),
          findsOneWidget,
        );

        await tester.tap(
          find.byKey(
            const ValueKey(
              'event-builder-v2-event-v2:$productRoutePortEventId',
            ),
          ),
        );
        await pumpEventBuilderV2ProductRouteFrames(
          tester,
          container: container,
        );

        final bridge =
            container.read(narrativeEventMapBridgeControllerProvider);
        expect(
          bridge.selectedGroupContext,
          const NarrativeEventGroupContext.map('map_port'),
        );
        final sourceBlock = find.byKey(
          const ValueKey('event-builder-v2-source-block'),
        );
        expect(
          find.descendant(of: sourceBlock, matching: find.text('Lieu')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: sourceBlock,
            matching: find.text('Port Selbrume'),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('map_port'), findsNothing);
        expect(find.textContaining('npc_rival'), findsNothing);
        expect(find.text('Choisir une map'), findsNothing);
      },
    );

    testWidgets(
      'keeps bridge selection across search, filter and snapshot refresh',
      (tester) async {
        final fixture = await createEventBuilderV2ProductRouteFixture(
          tester,
          mode: EventSystemMode.dualRead,
        );
        final container = await pumpEventBuilderV2ProductRoute(
          tester,
          fixture: fixture,
        );
        const portKey = ValueKey(
          'event-builder-v2-event-v2:$productRoutePortEventId',
        );

        await tester.tap(find.byKey(portKey));
        await pumpEventBuilderV2ProductRouteFrames(
          tester,
          container: container,
        );
        await tester.enterText(
          find.byKey(const ValueKey('event-builder-v2-search')),
          'esprit',
        );
        await tester.pump();

        expect(find.byKey(portKey), findsNothing);
        expect(find.text('Écho dans la brume'), findsOneWidget);
        expect(
          container
              .read(narrativeEventMapBridgeControllerProvider)
              .selectedNarrativeEventV2Id,
          productRoutePortEventId,
        );

        await tester.enterText(
          find.byKey(const ValueKey('event-builder-v2-search')),
          '',
        );
        await tester.pump();
        await tester.tap(
          find.byKey(const ValueKey('event-builder-v2-filter-button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Actifs'));
        await tester.pumpAndSettle();

        expect(find.byKey(portKey), findsOneWidget);
        expect(find.text('Après la victoire'), findsOneWidget);
        expect(find.text('Écho dans la brume'), findsNothing);
        expect(find.text('Événement à préparer'), findsNothing);
        expect(find.text('Objet disparu'), findsNothing);
        expect(find.text('Ancienne rumeur au port'), findsNothing);
        expect(
          container
              .read(narrativeEventMapBridgeControllerProvider)
              .selectedNarrativeEventV2Id,
          productRoutePortEventId,
        );

        final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
          projectRootPath: fixture.root.path,
          project: fixture.project,
        );
        container.invalidate(
          narrativeEventBuilderV2ReadModelProvider(request),
        );
        await pumpEventBuilderV2ProductRouteFrames(
          tester,
          container: container,
        );

        expect(find.byKey(portKey), findsOneWidget);
        expect(
          container
              .read(narrativeEventMapBridgeControllerProvider)
              .selectedNarrativeEventV2Id,
          productRoutePortEventId,
        );
      },
    );

    test('loads the complete list through the production disk snapshot',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
        projectRootPath: fixture.root.path,
        project: fixture.project,
      );

      final readModel = await container.read(
        narrativeEventBuilderV2ReadModelProvider(request).future,
      );

      expect(readModel.events, hasLength(6));
      expect(
        readModel.events.map((event) => event.title),
        containsAll(<String>[
          'Rencontre rival au port',
          'Écho dans la brume',
          'Après la victoire',
          'Événement à préparer',
          'Objet disparu',
          'Ancienne rumeur au port',
        ]),
      );
      expect(
        readModel.groups
            .where((group) => group.kind == NarrativeEventProjectGroupKind.map)
            .map((group) => group.label),
        containsAll(<String>['Port Selbrume', 'Forêt Brumeuse']),
      );
    });

    test('rejects a disk snapshot that drifted from the editor manifest',
        () async {
      final fixture = await EventBuilderV2ProductRouteFixture.create(
        mode: EventSystemMode.dualRead,
      );
      addTearDown(fixture.dispose);
      final request = NarrativeEventBuilderV2SnapshotRequest.fromProject(
        projectRootPath: fixture.root.path,
        project: fixture.project,
      );
      final projectFile = File(fixture.projectPath);
      final json =
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
      json['name'] = 'Selbrume changé sur disque';
      await projectFile.writeAsString(jsonEncode(json), flush: true);
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await expectLater(
        container.read(
          narrativeEventBuilderV2ReadModelProvider(request).future,
        ),
        throwsA(isA<NarrativeEventBuilderV2SnapshotMismatch>()),
      );
    });
  });
}
~~~~

### Annexe — `packages/map_editor/test/ui/canvas/event_builder_v2_reference_contract_test.dart`

~~~~dart
import 'dart:io';

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import '../../support/event_builder_v2_visual_harness.dart';

const _referencePath = 'test/goldens/event_builder_v2/reference/'
    'event_builder_v2_reference_1672x941.png';
const _contractPath = '../../reports/narrativeStudio/events/'
    'ns_event_v2_v0_visual_contract.md';
const _referenceFingerprint =
    'sha256:2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885';

void main() {
  group('NS-EVENT-V2 V0 visual reference contract', () {
    test('pins the supplied north-star bytes and dimensions', () {
      final reference = File(_referencePath);

      expect(
        reference.existsSync(),
        isTrue,
        reason: 'The supplied product reference must be versioned in-repo.',
      );
      final bytes = reference.readAsBytesSync();
      expect(narrativeEventBytesFingerprint(bytes), _referenceFingerprint);

      final decoded = image.decodePng(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 1672);
      expect(decoded.height, 941);
    });

    test('pins the reproducible fixture state used for comparisons', () {
      expect(
        eventBuilderV2PhaseKReferenceViewport,
        const Size(1672, 941),
      );

      final fixture = buildEventBuilderV2PhaseKReadModel();
      final selected = fixture.eventByStableKey(
        eventBuilderV2PhaseKSelectedStableKey,
      );

      expect(selected, isNotNull);
      expect(selected!.title, 'Rencontre rival au port');
      expect(selected.source.mapLabel, 'Port Selbrume');
      expect(selected.scene.humanLabel, 'Rencontre rival');
      expect(selected.enabled, isTrue);
    });

    test('documents all eight zones and numeric severity tolerances', () {
      final contract = File(_contractPath);

      expect(contract.existsSync(), isTrue);
      final markdown = contract.readAsStringSync();
      // Keep every measured rectangle executable: a prose-only marker test
      // would stay green if a coordinate drifted while H/K still trusted it.
      for (final requiredMarker in const <String>[
        '| 1 | Enveloppe fenêtre | `0, 0, 1672, 941` |',
        '| 2 | Header marque | `0, 0, 1672, 50` |',
        '| 3 | Barre contexte/actions | `207, 50, 1465, 52` |',
        '| 4 | Navigation produit | `8, 102, 191, 817` |',
        '| 5 | Colonne Événements | `207, 102, 266, 817` |',
        '| 6 | Bibliothèque | `481, 102, 213, 817` |',
        '| 7 | Éditeur central | `702, 102, 565, 817` |',
        '| 8 | Inspecteur | `1275, 102, 388, 817` |',
        'bord de panneau : `±4 px` maximum',
        'gouttière : `±2 px` maximum',
        'hauteur de chrome : `±3 px` maximum',
        'largeur de colonne : `±1,5 %` maximum',
        'géométrie interne et padding : `±2 px`',
        'taille ou hauteur de texte : `±1 px`',
        'text scale 1.0',
        'reste en attente d\'une approbation explicite',
      ]) {
        expect(markdown, contains(requiredMarker));
      }
    });
  });
}
~~~~

### Annexe — `reports/narrativeStudio/events/ns_event_v2_v0_visual_contract.md`

~~~~markdown
# NS-EVENT-V2 V0 — Contrat visuel de référence

## 1. Lot, statut et verdict exécutif

- **Lot exact :** `V0 — Figer le contrat visuel avant l’intégration UI`.
- **Statut à cette révision :** `VERIFYING` après replay vert du gate Phase 1,
  dans l'attente de l'approbation utilisateur de l'exception P2 proposée.
- **Référence canonique :**
  `packages/map_editor/test/goldens/event_builder_v2/reference/event_builder_v2_reference_1672x941.png`.
- **Dimensions :** `1672 × 941` pixels.
- **SHA-256 :**
  `2072679b3b861a63c068628450705d39e70ad59dc5067e0a0bf91c0bcbe8c885`.

Ce contrat fige la composition, la densité, la hiérarchie et l’état métier à
comparer. Il ne déclare pas que la route produit actuelle correspond déjà à
la référence. La mesure de l’écart réel, les corrections et l’overlay final
restent respectivement les lots K1, K2 et K3.

## 2. Scope confirmé et décisions produit

V0 ne modifie aucun contrat Event, Scene, Map ou runtime et n’applique aucun
polish à la production. Il conserve les décisions déjà ratifiées avec
l’utilisateur :

- `Event ≠ Scene` ;
- l’Event référence une source physique déjà créée sur une map ;
- la map est dérivée de la source atomique, jamais choisie dans un sélecteur
  indépendant de l’Event Builder ;
- les résultats, réactions, combats, dialogues, cinématiques, inventaire et
  changements du monde appartiennent à la Scene liée et sont projetés en
  lecture seule ;
- les cibles de drop visibles dans l’image ne deviennent pas de faux contrôles
  tant qu’un drag-and-drop réel, clavier et testé n’existe pas.

Ces divergences fonctionnelles conservent la hiérarchie visuelle de la
référence sans mentir sur l’ownership métier.

## 3. Provenance et reproductibilité

La provenance historique est documentée dans
`ns_event_reset_00_event_builder_v2_reference_ui_spec_v0.md`. La copie de ce
contrat est autonome : aucun test ne dépend d’un chemin Desktop ou d’un asset
extérieur au dépôt.

État de comparaison figé :

- plateforme de capture : macOS ;
- viewport physique : `1672 × 941` ;
- device pixel ratio : `1.0` ;
- text scale : `text scale 1.0` ;
- thème : PokeMap sombre ;
- locale et libellés : français ;
- police de capture candidate :
  `NsEventV2PhaseKCaptureFont` chargée depuis Arial système ;
- mode : `EventSystemMode.dualRead` ;
- projet : `Selbrume Demo` ;
- recherche vide, filtre `all`, side sheet fermé ;
- Event sélectionné : `event:rival`, « Rencontre rival au port », actif ;
- groupe : « Port Selbrume » ;
- source : interaction avec le Rival sur Port Selbrume ;
- deux conditions, Scene « Rencontre rival », projections en lecture seule et
  réutilisation one-shot ;
- scrolls à zéro, aucune animation en cours, aucun hover et aucun focus forcé.

Le builder de fixture `buildEventBuilderV2PhaseKReadModel()` reste un support
de comparaison déterministe. Son chrome synthétique n’est jamais une preuve de
route produit : K doit capturer l’application réellement montée.

## 4. Les huit zones normatives

Coordonnées au format `x, y, largeur, hauteur` :

| Ordre | Zone | Rectangle normatif |
|---:|---|---:|
| 1 | Enveloppe fenêtre | `0, 0, 1672, 941` |
| 2 | Header marque | `0, 0, 1672, 50` |
| 3 | Barre contexte/actions | `207, 50, 1465, 52` |
| 4 | Navigation produit | `8, 102, 191, 817` |
| 5 | Colonne Événements | `207, 102, 266, 817` |
| 6 | Bibliothèque | `481, 102, 213, 817` |
| 7 | Éditeur central | `702, 102, 565, 817` |
| 8 | Inspecteur | `1275, 102, 388, 817` |

La lecture du raster place visuellement le premier bord de l’Inspecteur autour
de `x = 1274`. Le contrat Flutter retient `x = 1275`, seule valeur cohérente
avec trois gouttières structurelles de 8 px :

```text
207 + 266 + 8 + 213 + 8 + 565 + 8 = 1275
```

Cette différence de bord de 1 px est une exception P2 **proposée** par le
présent contrat. Elle reste en attente d'une approbation explicite de
l'utilisateur et ne peut pas masquer un écart de largeur ou une gouttière
incorrecte.

Ordre obligatoire à droite de la navigation :

```text
Événements → Bibliothèque → Éditeur → Inspecteur
```

## 5. Grille et espacements structurants

- origine verticale du workspace : `y = 102 px` ;
- hauteur utile des panneaux : `817 px` ;
- gouttières métier : `8 px` ;
- largeur métier totale entre `x = 207` et le bord droit : `1456 px` ;
- la colonne centrale absorbe en priorité les écarts de largeur ;
- aucune barre de défilement horizontale cachée ;
- à `1672 × 941`, les quatre panneaux métier restent simultanément visibles ;
- le sélecteur de projet visible en haut de la navigation reste inclus dans le
  chrome de navigation, mais ne devient pas une neuvième zone de comparaison.

## 6. Sévérités et tolérances

### P0 — Bloquant, tolérance zéro

Un seul de ces écarts invalide la comparaison :

- mauvais fichier, hash, dimensions, viewport, mode, projet ou Event ;
- zone normative absente, réordonnée ou remplacée ;
- overflow, clipping majeur ou panneau inaccessible ;
- contrôle visiblement interactif sans comportement réel ;
- violation de `Event ≠ Scene` ou map sélectionnée indépendamment de la source ;
- capture K issue d’un harness au lieu de la route produit ;
- perte de sélection, de contexte ou de données projet lors du flow principal.

### P1 — Structure et géométrie

- bord de panneau : `±4 px` maximum ;
- gouttière : `±2 px` maximum ;
- hauteur de chrome : `±3 px` maximum ;
- baseline de titre : `±3 px` maximum ;
- largeur de colonne : `±1,5 %` maximum ;
- aucune différence de hiérarchie principale.

Tout dépassement P1 exige une correction avant clôture K2 ; il ne peut pas
être reclassé silencieusement en détail cosmétique.

### P2 — Détail visible

- géométrie interne et padding : `±2 px` ;
- taille ou hauteur de texte : `±1 px` ;
- épaisseur de bordure : `±1 px` ;
- rayon : `±2 px` ;
- icônes, ports, densité et accents : comparaison visuelle contextualisée ;
- couleurs : tokens sémantiques PokeMap et contraste AA, sans exiger une
  égalité RGB avec la maquette.

Un écart P2 au-delà de ces seuils doit être corrigé ou consigné comme exception
explicitement approuvée. La proposition `Inspecteur x = 1275` ci-dessus est la
seule exception géométrique initiale et ne sera considérée comme approuvée
qu'après confirmation explicite de l'utilisateur.

## 7. Méthode de comparaison K

1. ouvrir la vraie route produit sur le projet et l’Event figés ;
2. stabiliser viewport, DPR, text scale, police, scrolls et animations ;
3. capturer l’application complète, pas seulement le workspace ;
4. créer une image côte-à-côte référence/candidate à taille identique ;
5. créer un overlay 50 % ;
6. classer chaque écart P0, P1 ou P2 ;
7. corriger, recapturer et comparer de nouveau ;
8. conserver les artefacts et hashes de la capture finale.

Une capture seule n’est pas un QA visuel. La référence et la candidate doivent
être inspectées ensemble.

## 8. Audit initial et verdicts indépendants

État Git initial de la Phase 1 : `42` fichiers suivis modifiés, `84` fichiers
non suivis, soit `126` entrées. Le checkout contenait déjà F2, G, la candidate
H/K, les preuves L et des changements non Event ; aucune opération Git
d’écriture n’a été exécutée.

- **Audit / Architecture :** G est implémenté mais attend sa preuve route ; V0
  était absent ; la route produit montait toujours V1 ; H2 n’existait que dans
  un harness/state isolé.
- **Tests :** les tests K existants validaient la géométrie candidate mais pas
  les octets de la référence ni la route produit.
- **Audit visuel :** dimensions et SHA-256 confirmés ; huit zones et seuils
  P0/P1/P2 proposés ; le bord Inspecteur `1274/1275` a été identifié avant H.

## 9. Fichiers du lot V0

### Créés

- `packages/map_editor/test/goldens/event_builder_v2/reference/event_builder_v2_reference_1672x941.png`
  — copie binaire canonique ; contenu identifié par le hash et les dimensions
  de la section 1 ;
- `packages/map_editor/test/ui/canvas/event_builder_v2_reference_contract_test.dart`
  — garde automatisée du hash, des dimensions, de la fixture et du contrat ;
- `reports/narrativeStudio/events/ns_event_v2_v0_visual_contract.md`
  — présent contrat.

### Modifiés

Aucun fichier de production n’est modifié par V0.

## 10. Tests, analyse et build du lot

RED observé avant l’ajout des artefacts :

```text
flutter test --no-pub test/ui/canvas/event_builder_v2_reference_contract_test.dart
00:00 +1 -2: Some tests failed.
```

Les deux échecs attendus étaient l’absence de la référence versionnée et du
présent contrat. Les résultats GREEN, l’analyse, le format, le build et l’état
Git final sont consignés dans l’Evidence Pack vivant de la Phase 1 après H2,
afin de ne pas figer ici des preuves périmées par les modifications suivantes.

## 11. Limites, auto-critique et risques conservés

- La police de capture dépend encore d’Arial macOS ; une police de projet
  versionnée rendrait la capture portable.
- La fixture porte encore un nom Phase K bien que V0 la réutilise ; ce renommage
  serait cosmétique et reste hors scope de ce lot.
- Le contrat ne valide pas le rendu actuel : il protège uniquement la cible.
- Les défauts globaux préexistants du package editor ne sont ni masqués ni
  corrigés par V0.
- Le binaire ne peut pas être reproduit comme texte intégral dans un rapport ;
  son contenu complet est attesté par le SHA-256 canonique et son décodage PNG.

Prochaine étape de clôture : obtenir l'approbation utilisateur de l'exception
P2 proposée, puis fermer les dépendances formelles dans l'ordre prévu.
~~~~
