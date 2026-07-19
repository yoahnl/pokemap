# NSC-10 — Routes enfants et intents de navigation

Date de clôture technique : 2026-07-19  
Branche : `main`  
Lot : **NSC-10 — Routes enfants et intents de navigation**  
Statut proposé : **DONE**

## Résumé exécutif

NSC-10 dote Narrative Studio d'un contrat de navigation typé et réversible. La
destination principale, la sous-route, l'asset ciblé, le contexte source et le
retour attendu sont maintenant séparés. Les usages de l'index NSC-01 peuvent
ouvrir une cible exacte sans recopier la logique métier dans les workspaces.

Les pilotes livrés couvrent Scene vers Dialogue/Cinématique, Event vers Map
Editor, diagnostic vers asset exact et Map Events comme enfant de la destination
Events. Le retour restaure la sélection, le scroll et le focus seulement lorsque
la restauration réelle a abouti. Une cible supprimée ou incompatible échoue de
façon visible, sans fallback silencieux vers le premier asset disponible.

La clôture est proposée parce que les tests ciblés, les deux suites complètes,
les analyses statiques, le format, l'hygiène du diff et le build macOS debug sont
verts. Les quatre captures modifiées ont été limitées aux nouveaux contrôles de
navigation attendus.

## Scope confirmé

Inclus :

- contrats typés pour destination, route enfant, sélection et retour ;
- adaptateur exhaustif des intents neutres de `map_core` vers l'éditeur ;
- Map Events exposé comme enfant d'Events, jamais comme destination principale ;
- parcours Scene vers Dialogue et Cinématique avec retour Scene/noeud exact ;
- parcours Event vers Map avec retour Event exact, scroll et focus ;
- parcours diagnostic vers Fact, World Rule, Storyline/Chapter/Step, Event, Scene,
  Dialogue, Cinématique et Map ;
- Storyline Chapter/Step routés vers la Structure canonique ;
- validation des cibles au moment de l'ouverture et au retour ;
- consommation du retour seulement après restauration observable ;
- réinitialisation du contexte lors d'un changement de projet ;
- tests lifecycle, cibles obsolètes, navigation clavier/focus et non-régression ;
- mise à jour des quatre références visuelles intentionnellement affectées.

Hors scope volontaire :

- sérialisation des deep links en URL persistante ;
- historique global de navigation entre sessions ;
- refonte des données narratives ou création d'entités physiques depuis Event
  Builder ;
- généralisation automatique d'un retour contextuel au clic top-level Maps ;
- remplacement des deux couches transitoires route typée / `EditorWorkspaceMode`,
  qui restent synchronisées pendant la migration.

## Audit initial

### Constat

- le shell savait sélectionner une destination principale, mais ne portait pas
  une sous-route, une cible et un retour dans un même contrat ;
- plusieurs workspaces conservaient des demandes de focus ad hoc ;
- les diagnostics pouvaient ouvrir un domaine sans garantir l'asset exact ;
- Scene et Event ne disposaient pas d'un retour externe vérifiable ;
- les cibles supprimées risquaient de retomber silencieusement sur un autre asset ;
- Chapter et Step risquaient d'être dirigés vers la route Step historique au lieu
  de la structure Storyline canonique.

### Risques identifiés avant modification

1. divergence entre destination typée et mode de workspace historique ;
2. consommation anticipée d'un retour avant matérialisation de la ligne/noeud ;
3. chargement de la mauvaise map avant d'armer le retour ;
4. fallback silencieux sur le premier asset après suppression de la cible ;
5. fuite d'un contexte de navigation lors du chargement d'un autre projet ;
6. régression des routes et goldens existants ;
7. duplication de la hiérarchie métier déjà indexée par NSC-01.

### Décisions d'architecture

- `map_core` reste neutre vis-à-vis de Flutter et décrit l'intent avec son scope,
  son type source et sa hiérarchie canonique ;
- `map_editor` résout l'intent en route UI et vérifie l'existence de la cible ;
- une demande de retour est un état explicite acquitté par le consumer, pas un
  callback implicite ;
- les demandes de focus/scroll utilisent des retries bornés et restent en attente
  si la restauration n'a pas pu être prouvée ;
- la destination top-level reste stable : Map Events est une sous-route d'Events.

## État git initial

Les changements suivants existaient avant NSC-10 et ont été explicitement
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

Le test `selbrume_lighthouse_retry_integration_test.dart` était déjà indexé. Le
commit de NSC-10 utilise `git commit --only` avec la liste exacte du lot afin de
le laisser indexé sans le committer.

## Inventaire complet des fichiers du lot

### Contrats Core

- `packages/map_core/lib/src/read_models/narrative_dependency_index.dart` —
  enrichissement de l'intent de navigation, portée/source/map/root et hiérarchie
  canonique Chapter/Step ;
- `packages/map_core/test/narrative_dependency_index_test.dart` — couverture des
  intents enrichis, qualifiants et parents canoniques.

### Contrat et orchestration de navigation Editor

- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_destination.dart`
  — types destination, sous-route, target, contexte source et retour ;
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart`
  — nouveau contrôleur de navigation, résolution interne/externe/diagnostic,
  restauration et reset projet ;
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_navigation.dart`
  — Map Events enfant d'Events et sélection de sous-route ;
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart`
  — propagation de la route typée au shell ;
- `packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_route_presentation.dart`
  — présentation et breadcrumbs des sous-routes/cibles ;
- `packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart` —
  adaptateurs, résolution des intents NSC-01 et branchement des workspaces ;
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` —
  token de session projet exact et feedback explicite des cibles obsolètes ;
- `packages/map_editor/lib/src/ui/editor_shell_page.dart` — cycle de vie du
  contrôleur, synchronisation du mode historique et identité projet ;
- `packages/map_editor/lib/src/ui/design_system/pokemap_sidebar_item.dart` —
  primitive d'enfant de navigation réutilisable.

### Consumers et restauration

- `packages/map_editor/lib/src/ui/canvas/scenes_workspace.dart` — ouverture
  Dialogue/Cinématique, retour Scene/noeud exact, focus et cible obsolète ;
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_graph_read_only_view.dart` —
  focus node externe et sélection restaurable ;
- `packages/map_editor/lib/src/ui/canvas/scenes/scene_node_read_only_inspector.dart`
  — actions d'ouverture des références ;
- `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
  — sélection typée, invalidation stale et conservation lifecycle locale ;
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_product_route.dart`
  — ouverture Map et retour Event exact ;
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_project_list.dart`
  — matérialisation/focus de la ligne Event ;
- `packages/map_editor/lib/src/ui/canvas/events_v2/event_builder_v2_workspace.dart`
  — propagation de la demande de restauration ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` — insertion du bandeau
  de retour contextuel ;
- `packages/map_editor/lib/src/ui/canvas/map_canvas/narrative_event_map_banner.dart`
  — retour Event/diagnostic avec validation du contexte Map ;
- `packages/map_editor/lib/src/ui/canvas/facts_world_rules/facts_world_rules_workspace.dart`
  — sélection Fact/Rule exacte et cible obsolète ;
- `packages/map_editor/lib/src/ui/canvas/storylines_workspace.dart` — sélection
  Storyline/Chapter/Step exacte ;
- `packages/map_editor/lib/src/ui/canvas/storylines/storylines_structure_view.dart`
  — focus de l'élément structurel ;
- `packages/map_editor/lib/src/ui/canvas/narrative_validator_workspace.dart` —
  navigation diagnostic exacte, rematérialisation et focus ;
### Tests modifiés ou créés

- `packages/map_editor/test/ui/canvas/narrative_studio_destination_test.dart` ;
- `packages/map_editor/test/ui/canvas/narrative_studio_navigation_test.dart` ;
- `packages/map_editor/test/ui/canvas/narrative_studio_shell_contract_test.dart` ;
- `packages/map_editor/test/ui/canvas/narrative_studio_specialized_routes_test.dart` ;
- `packages/map_editor/test/ui/canvas/narrative_studio_cinematics_route_test.dart` ;
- `packages/map_editor/test/narrative_validator_workspace_test.dart` ;
- `packages/map_editor/test/ui/canvas/narrative_validator_route_test.dart` ;
- `packages/map_editor/test/ui/canvas/event_builder_v2_product_route_test.dart` ;
- `packages/map_editor/test/ui/canvas/event_builder_v2_validation_navigation_test.dart` ;
- `packages/map_editor/test/scenes_workspace_shell_test.dart`.

### Références visuelles modifiées

- `packages/map_editor/test/goldens/event_builder_v2/phase_1/event_builder_v2_full_product_route_1672x941.png` ;
- `packages/map_editor/test/goldens/narrative_studio/events/event_builder_legacy_full_product_route_1672x941.png` ;
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_30_scene_node_payload_editing_v0.png` ;
- `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_39_cinematic_scene_builder_picker_v0.png`.

## Zones précises et impact

| Zone | Modification | Impact |
|---|---|---|
| index Core | métadonnées de portée/source/parent et intents enrichis | deep links calculés depuis la source de vérité NSC-01 |
| destination Editor | valeurs typées et invariants de combinaison | états impossibles refusés tôt |
| contrôleur Editor | résolution, transition, retour, consume/reset | cycle de navigation testable et réversible |
| shell/rail | sous-route Map Events | hiérarchie produit cohérente sans destination top-level supplémentaire |
| Scene/Cinematic | CTA, sélection/focus, stale explicite | parcours inter-asset exact |
| Event/Map | chargement vérifié, scroll/focus, bandeau retour | aucun retour armé sur une mauvaise map |
| Validator/assets | cible exacte, rematérialisation, focus | diagnostic actionnable et sans fallback |
| Storyline | parent/root canonique | Chapter/Step ouverts dans Structure |
| tests/goldens | pilotes, lifecycle et régressions | comportement et rendu verrouillés |

## Critères Done et preuves

| Critère NSC-10 | Statut | Preuve |
|---|---:|---|
| destination, sous-route, asset et retour séparés | PASS | value objects et contrôleur typés, tests d'invariants |
| Map Events enfant d'Events | PASS | rail enfant testé, aucune destination top-level ajoutée |
| Scene vers Cinematic/Dialogue | PASS | tests ouverture, cible exacte, retour Scene/noeud/focus |
| Event vers Map | PASS | tests chargement, retour Event, scroll/focus et stale |
| diagnostic vers asset exact | PASS | Fact, Rule, Storyline, Event, Scene, Dialogue, Cinematic et Map |
| restauration sélection/scroll/focus | PASS | acquittement seulement après restauration réelle |
| routes et goldens existants conservés | PASS | suite Editor complète et quatre goldens intentionnels |
| chaque usage NSC-01 a un deep link stable/réversible | PASS | adaptateur exhaustif et revue architecture indépendante |

## Commandes et résultats exacts

### Tests ciblés Core

```text
cd packages/map_core
dart test test/narrative_dependency_index_test.dart
+40: All tests passed!
```

### Suite complète et analyse Core

```text
cd packages/map_core
dart test
+3119: All tests passed!
```

```text
cd packages/map_core
dart analyze
No issues found!
```

### Tests ciblés Editor finaux

```text
cd packages/map_editor
flutter test --concurrency=1 \
  test/ui/canvas/narrative_studio_destination_test.dart \
  test/ui/canvas/narrative_studio_navigation_test.dart \
  test/ui/canvas/narrative_studio_shell_contract_test.dart \
  test/ui/canvas/narrative_studio_specialized_routes_test.dart \
  test/ui/canvas/narrative_studio_cinematics_route_test.dart \
  test/cinematics_library_workspace_test.dart \
  test/narrative_validator_workspace_test.dart \
  test/ui/canvas/narrative_validator_route_test.dart \
  test/ui/canvas/event_builder_v2_product_route_test.dart \
  test/ui/canvas/event_builder_v2_validation_navigation_test.dart \
  test/scene_cinematic_picker_test.dart \
  test/scenes_workspace_shell_test.dart
+266: All tests passed!
```

### Suite complète et analyse Editor

```text
cd packages/map_editor
flutter test --concurrency=1 --reporter compact
+3465: All tests passed! (12 min 4 s)
```

```text
cd packages/map_editor
flutter analyze
Analyzing map_editor...
No issues found! (ran in 5.1s)
```

### Format, hygiène et build

```text
dart format --output=none --set-exit-if-changed [32 fichiers Dart du lot]
Formatted 32 files (0 changed) in 0.21 seconds.
```

```text
cd packages/map_core
dart format --output=none --set-exit-if-changed [2 fichiers Dart du lot]
Formatted 2 files (0 changed) in 0.03 seconds.
```

```text
git diff --check
(exit 0, aucune sortie)
```

```text
cd packages/map_editor
flutter build macos --debug
Building macOS application...
✓ Built build/macos/Build/Products/Debug/map_editor.app

codesign --verify --deep --strict build/macos/Build/Products/Debug/map_editor.app
(exit 0, aucune sortie)

file build/macos/Build/Products/Debug/map_editor.app/Contents/MacOS/map_editor
Mach-O 64-bit executable arm64
```

## Échecs intermédiaires et corrections

- le premier cycle RED a confirmé l'absence des types/routes/adaptateurs puis des
  actions Scene, du retour Event et de la sélection diagnostic ;
- le premier groupe UI a révélé trois différences golden intentionnelles : Event
  `0,62 % / 9 787 px` et Scene `2,46 % / 31 836 px` ;
- la mise à jour concurrente des goldens a échoué dans les outils natifs/codesign ;
  la même opération séquentielle a réussi ;
- une première assertion Event utilisait un finder non matérialisé ; le scénario
  corrigé a exposé le vrai RED : offset attendu `2248`, obtenu `2187,5` ;
- le diagnostic ouvrait initialement le premier asset ; la résolution exacte a
  remplacé ce fallback ;
- Chapter/Step ont d'abord exposé des champs de chemin/contexte manquants puis ont
  été routés vers la Structure canonique ;
- le pilote diagnostic vers Map a révélé une course de chargement et un usage de
  contexte après await ; le chargement est maintenant vérifié et `context.mounted`
  gardé ;
- deux suites complètes ont été interrompues volontairement (`exit 130`) lorsque
  les revues ont identifié des blockers encore ouverts ; elles ne constituent pas
  des validations finales ;
- la première suite complète stabilisée a fini à `+3454 -6` : un golden
  Cinématique `1,81 % / 37 436 px`, une régression Scene historique et quatre
  régressions lifecycle Cinématiques ;
- une relance d'identification interrompue a produit à l'arrêt un artefact de test
  `Bad state: Cannot close sink while adding stream`, sans défaut produit associé ;
- après correction, les quatre tests lifecycle Cinématiques, les 85 tests Scene,
  le golden V1-39 et les 3 460 tests Editor sont passés ;
- la revue finale a ensuite trouvé quatre risques de lifecycle : ancien deep link
  Scene réappliqué après un choix local, diagnostic Dialogue/Event obsolète,
  restauration sans consumer et collision d'identité de session ; chacun a été
  reproduit par un test RED, corrigé, puis validé dans la suite finale à 3 465.

## Revues indépendantes

| Passe | Verdict | Conclusion |
|---|---:|---|
| architecture finale | PASS | contrats neutres, adaptateur exhaustif, hiérarchie et reset projet corrects |
| parcours Scene | PASS | ouverture exacte, stale fail-closed, retour/focus et lifecycle couverts |
| parcours Cinématique | PASS | sélection typée et mutations de projet sans fallback régressif |
| revue tests initiale | CONCERNS puis résolu | stale Scene/Cinematic et route Chapter/Step corrigés avant validation finale |
| build/validation finale | PASS | suite complète, analyse, build arm64 et signature locale vérifiée |
| auto-critique finale | CONCERNS puis PASS | quatre cas lifecycle identifiés, reproduits et corrigés avant commit |

## État git avant commit

Le commit est préparé avec la liste exacte des fichiers NSC-10 et le présent
Evidence Pack. Les neuf changements Selbrume préexistants restent exclus ; le
nouveau test lighthouse reste indexé mais ne sera pas inclus grâce à
`git commit --only`.

## Risques et limites résiduels

- route typée et `EditorWorkspaceMode` restent deux couches synchronisées pendant
  la migration ;
- l'identité fonctionnelle conserve nom/IDs de maps ou chemin racine, mais chaque
  création/rechargement ajoute désormais une révision de session renouvelée ;
- les retries de matérialisation sont bornés à douze frames ; en cas d'échec, la
  demande reste en attente au lieu de produire un faux succès ;
- les deep links sont stables dans la session, pas encore sérialisés comme URL ;
- le bouton Maps générique n'arme pas un retour contextuel ; seuls les parcours
  externes pilotes le font ;
- l'accessibilité exhaustive du shell et la localisation appartiennent à NSC-12.

## Auto-critique

Le lot est plus transversal que l'estimation M : la sécurité du retour exigeait
de toucher chaque consumer pilote et ses cycles de vie. Ce choix évite toutefois
un contrat abstrait non éprouvé. Le principal coût restant est la coexistence du
nouveau modèle typé avec le mode de workspace historique. Cette dette est visible,
testée et bornée ; la retirer dans NSC-10 aurait élargi le lot en refonte du shell.

La matérialisation bornée est pragmatique pour les listes virtualisées, mais une
abstraction commune de reveal/focus pourra être extraite si d'autres workspaces
répètent ce mécanisme. Aucun fallback silencieux n'a été conservé pour masquer un
échec de restauration.

## Proposition de statut

**NSC-10 peut être marqué DONE.** Le prochain lot est **NSC-11 — Pickers de
références et inspecteur de dépendances partagés**.

## Annexe A — Contenu complet du nouveau fichier de production

Fichier :
`packages/map_editor/lib/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import 'narrative_studio_destination.dart';

@immutable
final class NarrativeStudioReturnExpectation {
  NarrativeStudioReturnExpectation({
    required this.location,
    this.scrollOffset,
    this.focusAnchorId,
  }) {
    if (scrollOffset != null &&
        (!scrollOffset!.isFinite || scrollOffset! < 0)) {
      throw ArgumentError.value(
        scrollOffset,
        'scrollOffset',
        'Must be finite and non-negative',
      );
    }
    if (focusAnchorId != null && focusAnchorId!.trim().isEmpty) {
      throw ArgumentError.value(
        focusAnchorId,
        'focusAnchorId',
        'Must not be blank',
      );
    }
  }

  final NarrativeStudioRouteLocation location;
  final double? scrollOffset;
  final String? focusAnchorId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeStudioReturnExpectation &&
          other.location == location &&
          other.scrollOffset == scrollOffset &&
          other.focusAnchorId == focusAnchorId;

  @override
  int get hashCode => Object.hash(location, scrollOffset, focusAnchorId);
}

@immutable
final class NarrativeStudioRestorationRequest {
  const NarrativeStudioRestorationRequest({
    required this.expectation,
    required this.revision,
  });

  final NarrativeStudioReturnExpectation expectation;
  final int revision;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeStudioRestorationRequest &&
          other.expectation == expectation &&
          other.revision == revision;

  @override
  int get hashCode => Object.hash(expectation, revision);
}

@immutable
final class NarrativeStudioNavigationState {
  const NarrativeStudioNavigationState({
    required this.location,
    this.projectIdentity,
    this.pendingReturn,
    this.restorationRequest,
    this.revision = 0,
  });

  factory NarrativeStudioNavigationState.initial() =>
      NarrativeStudioNavigationState(
        location: NarrativeStudioRouteLocation.overview(),
      );

  final NarrativeStudioRouteLocation location;
  final String? projectIdentity;
  final NarrativeStudioReturnExpectation? pendingReturn;
  final NarrativeStudioRestorationRequest? restorationRequest;
  final int revision;

  NarrativeStudioNavigationState copyWith({
    NarrativeStudioRouteLocation? location,
    String? projectIdentity,
    bool clearProjectIdentity = false,
    NarrativeStudioReturnExpectation? pendingReturn,
    bool clearPendingReturn = false,
    NarrativeStudioRestorationRequest? restorationRequest,
    bool clearRestorationRequest = false,
    int? revision,
  }) =>
      NarrativeStudioNavigationState(
        location: location ?? this.location,
        projectIdentity: clearProjectIdentity
            ? null
            : projectIdentity ?? this.projectIdentity,
        pendingReturn:
            clearPendingReturn ? null : pendingReturn ?? this.pendingReturn,
        restorationRequest: clearRestorationRequest
            ? null
            : restorationRequest ?? this.restorationRequest,
        revision: revision ?? this.revision,
      );
}

class NarrativeStudioNavigationController
    extends StateNotifier<NarrativeStudioNavigationState> {
  NarrativeStudioNavigationController()
      : super(NarrativeStudioNavigationState.initial());

  void replace(NarrativeStudioRouteLocation location) {
    state = state.copyWith(
      location: location,
      clearPendingReturn: true,
      clearRestorationRequest: true,
      revision: state.revision + 1,
    );
  }

  void navigate(
    NarrativeStudioRouteLocation location, {
    NarrativeStudioReturnExpectation? returnExpectation,
  }) {
    state = state.copyWith(
      location: location,
      pendingReturn: returnExpectation,
      clearPendingReturn: returnExpectation == null,
      clearRestorationRequest: true,
      revision: state.revision + 1,
    );
  }

  void rememberExternalReturn(NarrativeStudioReturnExpectation expectation) {
    state = state.copyWith(
      pendingReturn: expectation,
      clearRestorationRequest: true,
      revision: state.revision + 1,
    );
  }

  /// Resolves an NSC-01 dependency intent and applies internal deep links.
  ///
  /// External Map Editor targets are returned to the caller because opening a
  /// physical map requires editor services that deliberately stay outside
  /// this route-only controller.
  NarrativeStudioNavigationResolution navigateToDependency(
    NarrativeDependencyNavigationIntent intent, {
    NarrativeStudioReturnExpectation? returnExpectation,
  }) {
    final resolution = resolveNarrativeDependencyNavigationIntent(intent);
    final location = resolution.location;
    if (resolution.kind == NarrativeStudioNavigationResolutionKind.internal &&
        location != null) {
      navigate(location, returnExpectation: returnExpectation);
    }
    return resolution;
  }

  NarrativeStudioReturnExpectation? restoreReturn() {
    final expectation = state.pendingReturn;
    if (expectation == null) return null;
    final revision = state.revision + 1;
    final requiresViewportRestoration =
        expectation.scrollOffset != null || expectation.focusAnchorId != null;
    state = state.copyWith(
      location: expectation.location,
      clearPendingReturn: true,
      restorationRequest: requiresViewportRestoration
          ? NarrativeStudioRestorationRequest(
              expectation: expectation,
              revision: revision,
            )
          : null,
      clearRestorationRequest: !requiresViewportRestoration,
      revision: revision,
    );
    return expectation;
  }

  bool consumeRestoration(int revision) {
    if (state.restorationRequest?.revision != revision) return false;
    state = state.copyWith(clearRestorationRequest: true);
    return true;
  }

  void resetForProject(
    String? projectIdentity, {
    NarrativeStudioRouteLocation? initialLocation,
  }) {
    final normalized = projectIdentity?.trim();
    if (state.projectIdentity == normalized) return;
    state = NarrativeStudioNavigationState(
      location: initialLocation ?? NarrativeStudioRouteLocation.overview(),
      projectIdentity: normalized,
      revision: state.revision + 1,
    );
  }
}

final narrativeStudioNavigationControllerProvider = StateNotifierProvider<
    NarrativeStudioNavigationController, NarrativeStudioNavigationState>(
  (ref) => NarrativeStudioNavigationController(),
);

enum NarrativeStudioNavigationResolutionKind {
  internal,
  externalMap,
  unavailable,
}

@immutable
final class NarrativeStudioExternalMapTarget {
  const NarrativeStudioExternalMapTarget({
    required this.mapId,
    required this.sourceKind,
    required this.sourceId,
  });

  final String mapId;
  final String sourceKind;
  final String sourceId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NarrativeStudioExternalMapTarget &&
          other.mapId == mapId &&
          other.sourceKind == sourceKind &&
          other.sourceId == sourceId;

  @override
  int get hashCode => Object.hash(mapId, sourceKind, sourceId);
}

@immutable
final class NarrativeStudioNavigationResolution {
  const NarrativeStudioNavigationResolution.internal(this.location)
      : kind = NarrativeStudioNavigationResolutionKind.internal,
        externalMapTarget = null,
        reason = null;

  const NarrativeStudioNavigationResolution.externalMap(
    this.externalMapTarget,
  )   : kind = NarrativeStudioNavigationResolutionKind.externalMap,
        location = null,
        reason = null;

  const NarrativeStudioNavigationResolution.unavailable(this.reason)
      : kind = NarrativeStudioNavigationResolutionKind.unavailable,
        location = null,
        externalMapTarget = null;

  final NarrativeStudioNavigationResolutionKind kind;
  final NarrativeStudioRouteLocation? location;
  final NarrativeStudioExternalMapTarget? externalMapTarget;
  final String? reason;
}

NarrativeStudioNavigationResolution resolveNarrativeDependencyNavigationIntent(
  NarrativeDependencyNavigationIntent intent,
) {
  final id = _nonBlank(intent.assetId);
  if (id == null) {
    return const NarrativeStudioNavigationResolution.unavailable(
      'La cible narrative ne possède pas d’identifiant exploitable.',
    );
  }
  final parentId = _nonBlank(intent.parentId);
  final rootId = _nonBlank(intent.rootId);
  final context = _nonBlank(intent.context);
  NarrativeStudioAssetSelection selection(NarrativeStudioAssetKind kind) =>
      NarrativeStudioAssetSelection(
        kind: kind,
        assetId: id,
        parentId: parentId,
        rootId: rootId,
        sourceContext: context,
      );

  return switch (intent.kind) {
    NarrativeDependencyTargetKind.fact =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.facts(
          selection: selection(NarrativeStudioAssetKind.fact),
        ),
      ),
    NarrativeDependencyTargetKind.eventV2 =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.events(
          selection: selection(NarrativeStudioAssetKind.event),
        ),
      ),
    NarrativeDependencyTargetKind.scene =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.scenes(
          selection: selection(NarrativeStudioAssetKind.scene),
        ),
      ),
    NarrativeDependencyTargetKind.dialogue =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.dialogues(
          selection: selection(NarrativeStudioAssetKind.dialogue),
        ),
      ),
    NarrativeDependencyTargetKind.cinematic =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.cinematics(
          childRoute: NarrativeStudioChildRoute.cinematicBuilder,
          selection: selection(NarrativeStudioAssetKind.cinematic),
        ),
      ),
    NarrativeDependencyTargetKind.storyline =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.storylines(
          selection: selection(NarrativeStudioAssetKind.storyline),
        ),
      ),
    NarrativeDependencyTargetKind.chapter =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.storylines(
          selection: selection(NarrativeStudioAssetKind.chapter),
        ),
      ),
    NarrativeDependencyTargetKind.step =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.storylines(
          selection: selection(NarrativeStudioAssetKind.step),
        ),
      ),
    NarrativeDependencyTargetKind.worldRule =>
      NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.worldRules(
          selection: selection(NarrativeStudioAssetKind.worldRule),
        ),
      ),
    NarrativeDependencyTargetKind.sourceMap => _resolveExternalMap(intent, id),
  };
}

NarrativeStudioNavigationResolution resolveNarrativeProjectDiagnostic(
  NarrativeProjectDiagnostic diagnostic,
) {
  NarrativeStudioAssetSelection? selected(
    NarrativeStudioAssetKind kind,
    String? assetId, {
    String? parentId,
    String? rootId,
  }) {
    final id = _nonBlank(assetId);
    if (id == null) return null;
    return NarrativeStudioAssetSelection(
      kind: kind,
      assetId: id,
      parentId: _nonBlank(parentId),
      rootId: _nonBlank(rootId),
      sourceContext: _nonBlank(diagnostic.path),
    );
  }

  NarrativeStudioNavigationResolution missing(String label) =>
      NarrativeStudioNavigationResolution.unavailable(
        'Le diagnostic ne précise pas la cible $label.',
      );

  switch (diagnostic.destination) {
    case NarrativeProjectDiagnosticDestination.overview:
      return NarrativeStudioNavigationResolution.internal(
        NarrativeStudioRouteLocation.overview(),
      );
    case NarrativeProjectDiagnosticDestination.map:
      final mapId = _nonBlank(diagnostic.mapId);
      return mapId == null
          ? missing('map')
          : NarrativeStudioNavigationResolution.externalMap(
              NarrativeStudioExternalMapTarget(
                mapId: mapId,
                sourceKind: 'map',
                sourceId: mapId,
              ),
            );
    case NarrativeProjectDiagnosticDestination.event:
      final selection = selected(
        NarrativeStudioAssetKind.event,
        diagnostic.eventId,
        parentId: diagnostic.mapId,
      );
      return selection == null
          ? missing('événement')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.events(selection: selection),
            );
    case NarrativeProjectDiagnosticDestination.scene:
      final selection = selected(
        NarrativeStudioAssetKind.scene,
        diagnostic.sceneId,
      );
      return selection == null
          ? missing('scène')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.scenes(selection: selection),
            );
    case NarrativeProjectDiagnosticDestination.storyline:
      final selection = diagnostic.stepId != null
          ? selected(
              NarrativeStudioAssetKind.step,
              diagnostic.stepId,
              parentId: diagnostic.chapterId,
              rootId: diagnostic.storylineId,
            )
          : diagnostic.chapterId != null
              ? selected(
                  NarrativeStudioAssetKind.chapter,
                  diagnostic.chapterId,
                  parentId: diagnostic.storylineId,
                )
              : selected(
                  NarrativeStudioAssetKind.storyline,
                  diagnostic.storylineId,
                );
      return selection == null
          ? missing('storyline')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.storylines(
                childRoute: NarrativeStudioChildRoute.storylineLibrary,
                selection: selection,
              ),
            );
    case NarrativeProjectDiagnosticDestination.dialogue:
      final selection = selected(
        NarrativeStudioAssetKind.dialogue,
        diagnostic.dialogueId,
        parentId: diagnostic.sceneId,
      );
      return selection == null
          ? missing('dialogue')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.dialogues(selection: selection),
            );
    case NarrativeProjectDiagnosticDestination.cinematic:
      final selection = selected(
        NarrativeStudioAssetKind.cinematic,
        diagnostic.cinematicId,
      );
      return selection == null
          ? missing('cinématique')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.cinematics(
                childRoute: NarrativeStudioChildRoute.cinematicBuilder,
                selection: selection,
              ),
            );
    case NarrativeProjectDiagnosticDestination.fact:
      final selection = selected(
        NarrativeStudioAssetKind.fact,
        diagnostic.factId,
      );
      return selection == null
          ? missing('fact')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.facts(selection: selection),
            );
    case NarrativeProjectDiagnosticDestination.worldRule:
      final selection = selected(
        NarrativeStudioAssetKind.worldRule,
        diagnostic.worldRuleId,
      );
      return selection == null
          ? missing('règle du monde')
          : NarrativeStudioNavigationResolution.internal(
              NarrativeStudioRouteLocation.worldRules(selection: selection),
            );
  }
}

NarrativeStudioNavigationResolution _resolveExternalMap(
  NarrativeDependencyNavigationIntent intent,
  String sourceId,
) {
  if (intent.scope != 'map') {
    return const NarrativeStudioNavigationResolution.unavailable(
      'La référence ne désigne pas une source physique ouvrable dans une map.',
    );
  }
  final mapId = _nonBlank(intent.mapId) ?? _nonBlank(intent.parentId);
  final sourceKind = _nonBlank(intent.sourceKind);
  if (mapId == null || sourceKind == null) {
    return const NarrativeStudioNavigationResolution.unavailable(
      'La référence ne désigne pas une source physique ouvrable dans une map.',
    );
  }
  return NarrativeStudioNavigationResolution.externalMap(
    NarrativeStudioExternalMapTarget(
      mapId: mapId,
      sourceKind: sourceKind,
      sourceId: sourceId,
    ),
  );
}

String? _nonBlank(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
```

## Annexe B — Contenu complet du nouveau fichier de test

Fichier :
`packages/map_editor/test/ui/canvas/narrative_studio_navigation_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_navigation.dart';

void main() {
  group('NSC-10 navigation session', () {
    test('restores a single-use route selection scroll and focus snapshot', () {
      final controller = NarrativeStudioNavigationController();
      final source = NarrativeStudioRouteLocation.events(
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.event,
          assetId: 'evt_port',
          parentId: 'map_port',
        ),
      );
      final target = NarrativeStudioRouteLocation.scenes(
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.scene,
          assetId: 'scene_depart',
        ),
      );
      final expectedReturn = NarrativeStudioReturnExpectation(
        location: source,
        scrollOffset: 236,
        focusAnchorId: 'v2:evt_port',
      );

      controller.navigate(target, returnExpectation: expectedReturn);
      expect(controller.state.location, target);
      expect(controller.state.pendingReturn, expectedReturn);

      final restored = controller.restoreReturn();
      expect(restored, expectedReturn);
      expect(controller.state.location, source);
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.restorationRequest?.expectation, expectedReturn);

      final revision = controller.state.restorationRequest!.revision;
      expect(controller.consumeRestoration(revision), isTrue);
      expect(controller.state.restorationRequest, isNull);
      expect(controller.restoreReturn(), isNull);
    });

    test('top-level replacement clears stale return and restoration state', () {
      final controller = NarrativeStudioNavigationController();
      final source = NarrativeStudioRouteLocation.scenes();
      final target = NarrativeStudioRouteLocation.dialogues(
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.dialogue,
          assetId: 'dialogue_lysa',
        ),
      );

      controller.navigate(
        target,
        returnExpectation: NarrativeStudioReturnExpectation(
          location: source,
          scrollOffset: 0,
          focusAnchorId: 'scene_node_dialogue',
        ),
      );
      controller.restoreReturn();
      controller.replace(NarrativeStudioRouteLocation.overview());

      expect(
        controller.state.location,
        NarrativeStudioRouteLocation.overview(),
      );
      expect(controller.state.pendingReturn, isNull);
      expect(controller.state.restorationRequest, isNull);
    });

    test('selection-only returns do not create a restoration request', () {
      final controller = NarrativeStudioNavigationController();
      final source = NarrativeStudioRouteLocation.cinematics(
        childRoute: NarrativeStudioChildRoute.cinematicLibrary,
        selection: NarrativeStudioAssetSelection(
          kind: NarrativeStudioAssetKind.cinematic,
          assetId: 'cinematic_intro',
        ),
      );

      controller.navigate(
        NarrativeStudioRouteLocation.dialogues(),
        returnExpectation: NarrativeStudioReturnExpectation(location: source),
      );

      expect(controller.restoreReturn()?.location, source);
      expect(controller.state.location, source);
      expect(controller.state.pendingReturn, isNull);
      expect(
        controller.state.restorationRequest,
        isNull,
        reason:
            'La sélection est portée par la route et ne requiert aucun ack.',
      );
    });

    test('reset prevents return context leaking into another project', () {
      final controller = NarrativeStudioNavigationController();
      controller.navigate(
        NarrativeStudioRouteLocation.cinematics(
          childRoute: NarrativeStudioChildRoute.cinematicBuilder,
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.cinematic,
            assetId: 'cinematic_intro',
          ),
        ),
        returnExpectation: NarrativeStudioReturnExpectation(
          location: NarrativeStudioRouteLocation.scenes(),
          scrollOffset: 12,
          focusAnchorId: 'scene_intro',
        ),
      );

      controller.resetForProject('project_b');

      expect(controller.state.projectIdentity, 'project_b');
      expect(
        controller.state.location,
        NarrativeStudioRouteLocation.overview(),
      );
      expect(controller.restoreReturn(), isNull);
    });
  });

  group('NSC-10 canonical intent adapter', () {
    test('resolves Scene, Cinematic and Dialogue to exact internal assets', () {
      final cases = <NarrativeDependencyNavigationIntent,
          ({
        NarrativeStudioDestination destination,
        NarrativeStudioChildRoute child,
        NarrativeStudioAssetKind kind,
      })>{
        const NarrativeDependencyNavigationIntent(
          kind: NarrativeDependencyTargetKind.scene,
          assetId: 'scene.port',
        ): (
          destination: NarrativeStudioDestination.scenes,
          child: NarrativeStudioChildRoute.sceneBuilder,
          kind: NarrativeStudioAssetKind.scene,
        ),
        const NarrativeDependencyNavigationIntent(
          kind: NarrativeDependencyTargetKind.cinematic,
          assetId: 'cine.depart',
        ): (
          destination: NarrativeStudioDestination.cinematics,
          child: NarrativeStudioChildRoute.cinematicBuilder,
          kind: NarrativeStudioAssetKind.cinematic,
        ),
        const NarrativeDependencyNavigationIntent(
          kind: NarrativeDependencyTargetKind.dialogue,
          assetId: 'dialogue.lysa',
        ): (
          destination: NarrativeStudioDestination.dialogues,
          child: NarrativeStudioChildRoute.dialogueEditor,
          kind: NarrativeStudioAssetKind.dialogue,
        ),
      };

      for (final entry in cases.entries) {
        final resolution = resolveNarrativeDependencyNavigationIntent(
          entry.key,
        );
        expect(
            resolution.kind, NarrativeStudioNavigationResolutionKind.internal);
        expect(resolution.location?.destination, entry.value.destination);
        expect(resolution.location?.childRoute, entry.value.child);
        expect(resolution.location?.selection?.kind, entry.value.kind);
        expect(resolution.location?.selection?.assetId, entry.key.assetId);
      }
    });

    test('resolves an Event to a physical Map without losing qualifiers', () {
      const intent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.sourceMap,
        assetId: 'npc.lysa',
        parentId: 'map.port',
        scope: 'map',
        sourceKind: 'entity',
        mapId: 'map.port',
      );

      final resolution = resolveNarrativeDependencyNavigationIntent(intent);

      expect(
          resolution.kind, NarrativeStudioNavigationResolutionKind.externalMap);
      expect(
        resolution.externalMapTarget,
        const NarrativeStudioExternalMapTarget(
          mapId: 'map.port',
          sourceKind: 'entity',
          sourceId: 'npc.lysa',
        ),
      );
    });

    test('keeps Chapter and Step hierarchy in their authoring selections', () {
      const chapterIntent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.chapter,
        assetId: 'chapter.port',
        parentId: 'story.main',
      );
      const stepIntent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.step,
        assetId: 'step.departure',
        parentId: 'chapter.port',
        rootId: 'story.main',
      );

      final chapterResolution = resolveNarrativeDependencyNavigationIntent(
        chapterIntent,
      );
      final resolution = resolveNarrativeDependencyNavigationIntent(stepIntent);

      expect(
        chapterResolution.location,
        NarrativeStudioRouteLocation.storylines(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.chapter,
            assetId: 'chapter.port',
            parentId: 'story.main',
          ),
        ),
      );
      expect(
        resolution.location,
        NarrativeStudioRouteLocation.storylines(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.step,
            assetId: 'step.departure',
            parentId: 'chapter.port',
            rootId: 'story.main',
          ),
        ),
      );
    });

    test('controller directly consumes internal canonical dependency intents',
        () {
      final controller = NarrativeStudioNavigationController();
      const intent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.scene,
        assetId: 'scene.port',
      );

      final resolution = controller.navigateToDependency(intent);

      expect(resolution.kind, NarrativeStudioNavigationResolutionKind.internal);
      expect(
        controller.state.location,
        NarrativeStudioRouteLocation.scenes(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.scene,
            assetId: 'scene.port',
          ),
        ),
      );
    });

    test('controller consumes a navigation intent emitted by the real index',
        () {
      final project = ProjectManifest(
        name: 'Canonical navigation chain',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        scenes: <SceneAsset>[
          SceneAsset(
            id: 'scene.indexed',
            name: 'Indexed Scene',
            graph: SceneGraph(
              startNodeId: 'start',
              nodes: <SceneNode>[
                SceneNode(id: 'start', kind: SceneNodeKind.start),
              ],
            ),
          ),
        ],
      );
      final index = buildNarrativeDependencyIndex(project: project);
      final intent = index
          .definitionsFor(
            const NarrativeDependencyKey(
              NarrativeDependencyTargetKind.scene,
              'scene.indexed',
            ),
          )
          .single
          .navigationIntent!;
      final controller = NarrativeStudioNavigationController();
      final expectedReturn = NarrativeStudioReturnExpectation(
        location: NarrativeStudioRouteLocation.overview(),
      );

      controller.navigateToDependency(
        intent,
        returnExpectation: expectedReturn,
      );

      expect(
        controller.state.location,
        NarrativeStudioRouteLocation.scenes(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.scene,
            assetId: 'scene.indexed',
            sourceContext: 'scenes[scene.indexed]',
          ),
        ),
      );
      expect(controller.state.pendingReturn, expectedReturn);
    });

    test('fails closed when a physical source has no usable map identity', () {
      const intent = NarrativeDependencyNavigationIntent(
        kind: NarrativeDependencyTargetKind.sourceMap,
        assetId: 'legacy.scenario',
        scope: 'legacy',
        sourceKind: 'scenario',
        mapId: 'map.fabricated',
      );

      final resolution = resolveNarrativeDependencyNavigationIntent(intent);

      expect(
        resolution.kind,
        NarrativeStudioNavigationResolutionKind.unavailable,
      );
      expect(resolution.location, isNull);
      expect(resolution.externalMapTarget, isNull);
      expect(resolution.reason, isNotEmpty);
    });

    test('maps a diagnostic to the exact asset instead of only its workspace',
        () {
      const diagnostic = NarrativeProjectDiagnostic(
        code: 'scene.dialogue.missing',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.dialogue,
        message: 'Dialogue missing',
        path: 'scenes[scene.port].nodes[node.lysa]',
        destination: NarrativeProjectDiagnosticDestination.dialogue,
        sceneId: 'scene.port',
        dialogueId: 'dialogue.lysa',
      );

      final resolution = resolveNarrativeProjectDiagnostic(diagnostic);

      expect(
          resolution.location,
          NarrativeStudioRouteLocation.dialogues(
            selection: NarrativeStudioAssetSelection(
              kind: NarrativeStudioAssetKind.dialogue,
              assetId: 'dialogue.lysa',
              parentId: 'scene.port',
              sourceContext: 'scenes[scene.port].nodes[node.lysa]',
            ),
          ));
    });

    test('maps a Step diagnostic to canonical Storyline Structure', () {
      const diagnostic = NarrativeProjectDiagnostic(
        code: 'storylineStepNeverCompleted',
        severity: NarrativeProjectDiagnosticSeverity.error,
        domain: NarrativeProjectDiagnosticDomain.storyline,
        message: 'Step unreachable',
        path:
            'storylines[story.main].chapters[chapter.port].steps[step.departure]',
        destination: NarrativeProjectDiagnosticDestination.storyline,
        storylineId: 'story.main',
        chapterId: 'chapter.port',
        stepId: 'step.departure',
      );

      final resolution = resolveNarrativeProjectDiagnostic(diagnostic);

      expect(
        resolution.location,
        NarrativeStudioRouteLocation.storylines(
          selection: NarrativeStudioAssetSelection(
            kind: NarrativeStudioAssetKind.step,
            assetId: 'step.departure',
            parentId: 'chapter.port',
            rootId: 'story.main',
            sourceContext:
                'storylines[story.main].chapters[chapter.port].steps[step.departure]',
          ),
        ),
      );
    });
  });
}
```

Le présent Evidence Pack est lui-même le troisième fichier créé par le lot. Son
contenu intégral est le document courant ; il n'est pas récursivement reproduit.
