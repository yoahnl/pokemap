import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../application/use_cases/project_scenario_use_cases.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../features/narrative/application/step_studio_authoring.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';
import 'step_studio/step_flow_canvas.dart';
import 'step_studio/step_flow_focus.dart';
import 'step_studio/step_flow_palette.dart';

// -----------------------------------------------------------------------------
// step_studio_workspace.dart — périmètre volontairement large
// -----------------------------------------------------------------------------
//
// Ce fichier concentre tout le cycle Step Studio **dans l’éditeur** : hydratation
// depuis le scénario global, brouillon, sauvegarde, liste des steps, assemblage
// palette + canvas + inspecteur, et les sections techniques (`activation`,
// `completion`, liens cutscene, outcomes, monde).
//
// Découpage additionnel n’est pas gratuit ici : les blocs (`_buildActivationSection`,
// `_OutcomeRow`, etc.) ne sont réutilisés nulle part ailleurs ; les extraire
// augmenterait la surface sans second consommateur. Si un second écran édite les
// mêmes champs, extraire alors les sections partagées.
//
// Rappel : les champs `flow*Label` et `flowUnlocksStepId` sont édités ici mais
// sont des **annotations auteur** (voir `step_studio_authoring.dart`), pas une
// couche runtime.
//
// Passe 3 : le canvas (`StepFlowCanvas`) n’affiche plus `flowUnlocksStepId` pour
// éviter un faux « lien » visuel ; le mémo reste éditable dans l’inspecteur.

/// Workspace central **Step Studio** — logique de progression d’une étape.
///
/// RÔLE PRODUIT (à ne pas confondre avec Cutscene Studio ni Global Story) :
/// - **Global Story** : macro-progression, arcs, quelle step est débloquée.
/// - **Step (ici)** : objectif, activation, completion, outcomes, références
///   cutscene, changements monde ; notes auteur (`flow*`) séparées des règles.
/// - **Cutscene** : mise en scène concrète (dialogue, move, caméra…).
///
/// L’UI est structurée en **3 zones** :
/// - palette gauche : raccourcis « blocs métier » (pas blocs d’exécution);
/// - canvas central : flux vertical lisible façon « Scratch métier »;
/// - inspecteur droit : champs détaillés du bloc sélectionné.
///
/// Les cutscenes ne s’éditent **pas** ici : on ne fait que les lier et
/// proposer d’ouvrir Cutscene Studio.
class StepStudioWorkspace extends StatefulWidget {
  const StepStudioWorkspace({
    super.key,
    required this.editorNotifier,
    required this.project,
    required this.activeMap,
    required this.projection,
    required this.selectedStepId,
    required this.onSelectStep,
    required this.onSelectOutcome,
    this.onOpenCutsceneStudio,
  });

  final EditorNotifier editorNotifier;
  final ProjectManifest? project;
  final MapData? activeMap;
  final NarrativeWorkspaceProjection projection;
  final String? selectedStepId;
  final ValueChanged<String?> onSelectStep;
  final ValueChanged<String?> onSelectOutcome;

  /// Bascule vers Cutscene Studio sur une cutscene donnée (référence Step).
  final void Function(String cutsceneScenarioId)? onOpenCutsceneStudio;

  @override
  State<StepStudioWorkspace> createState() => _StepStudioWorkspaceState();
}

class _StepStudioWorkspaceState extends State<StepStudioWorkspace> {
  StepStudioDocument? _savedDocument;
  StepStudioDocument? _draftDocument;
  String? _loadedGlobalScenarioId;
  String? _selectedStepId;
  bool _busy = false;

  /// Bloc du flux central actuellement détaillé dans l’inspecteur droit.
  StepFlowFocus? _flowInspectorFocus;

  // Informations de compatibilité / migration affichées dans l'UI.
  List<String> _loadWarnings = const <String>[];
  bool _usedLegacyFallback = false;

  // Cache map -> entités pour les dropdowns de présence conditionnelle.
  final Map<String, List<MapEntity>> _entitiesByMapId =
      <String, List<MapEntity>>{};
  // Maps en cours de chargement d'entités.
  //
  // Ce garde empêche les relances concurrentes d'un même chargement si des
  // rebuilds surviennent pendant qu'un Future est toujours en vol.
  final Set<String> _entityMapsLoading = <String>{};
  bool _isLoadingEntities = false;
  String? _entityLookupError;

  // ---------------------------------------------------------------------------
  // Synchronisation sélection (local -> provider parent) en mode "provider-safe".
  // ---------------------------------------------------------------------------
  //
  // Pourquoi ce mécanisme existe:
  // - Riverpod interdit les mutations provider pendant build/initState.
  // - Le Step Studio hydrate son état interne dès initState et peut décider
  //   d'une auto-sélection initiale de step.
  // - Cette auto-sélection doit être propagée au parent, MAIS uniquement
  //   après la frame courante.
  //
  // Stratégie:
  // - on queue la valeur cible;
  // - on flush en `addPostFrameCallback`;
  // - on déduplique pour éviter les re-notifications inutiles.
  String? _lastDispatchedSelection;
  String? _queuedSelectionToDispatch;
  bool _selectionDispatchScheduled = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromProject();
  }

  @override
  void didUpdateWidget(covariant StepStudioWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final projectChanged = oldWidget.project != widget.project;
    final projectionChanged = oldWidget.projection != widget.projection;
    final activeMapChanged = oldWidget.activeMap != widget.activeMap;
    final selectedStepChanged =
        oldWidget.selectedStepId != widget.selectedStepId;

    if (projectChanged || projectionChanged) {
      _hydrateFromProject();
      return;
    }

    if (selectedStepChanged) {
      final requestedStepId = widget.selectedStepId;
      if (requestedStepId != null && _containsStep(requestedStepId)) {
        setState(() {
          _selectedStepId = requestedStepId;
          _flowInspectorFocus = null;
        });
        // Aucun side-effect dans build: on prime les entités ici.
        _warmupEntityLookupsForStep(_stepById(requestedStepId));
      }
    }

    if (activeMapChanged) {
      final active = widget.activeMap;
      if (active != null) {
        _entitiesByMapId[active.id] = _sortedWorldEntities(active.entities);
      }
    }
  }

  void _hydrateFromProject() {
    final project = widget.project;
    if (project == null) {
      setState(() {
        _savedDocument = null;
        _draftDocument = null;
        _loadedGlobalScenarioId = null;
        _selectedStepId = null;
        _loadWarnings = const <String>[];
        _usedLegacyFallback = false;
        _busy = false;
        _entitiesByMapId.clear();
        _entityLookupError = null;
        _isLoadingEntities = false;
        _entityMapsLoading.clear();
      });
      // Important: ne pas muter le provider parent ici (init/build en cours).
      // On planifie une sync post-frame.
      _dispatchSelectionAfterFrame(null);
      return;
    }

    final globalScenarios = project.scenarios
        .where((scenario) => scenario.scope == ScenarioScope.globalStory)
        .toList(growable: false);
    if (globalScenarios.isEmpty) {
      setState(() {
        _savedDocument = null;
        _draftDocument = null;
        _loadedGlobalScenarioId = null;
        _selectedStepId = null;
        _loadWarnings = const <String>[];
        _usedLegacyFallback = false;
        _entitiesByMapId.clear();
        _entityLookupError = null;
        _isLoadingEntities = false;
        _entityMapsLoading.clear();
      });
      // Important: idem, aucune mutation provider synchrone ici.
      _dispatchSelectionAfterFrame(null);
      return;
    }

    final primary = globalScenarios.first;
    final parse = parseStepStudioDocumentFromGlobalScenario(primary);
    final document = parse.document;

    final preferredSelection = widget.selectedStepId;
    final resolvedSelection = _resolveInitialStepSelection(
      document: document,
      preferredStepId: preferredSelection,
      fallbackStepId: _selectedStepId,
    );

    setState(() {
      _savedDocument = document;
      _draftDocument = document;
      _loadedGlobalScenarioId = primary.id;
      _selectedStepId = resolvedSelection;
      _loadWarnings = parse.warnings;
      _usedLegacyFallback = parse.usedLegacyFallback;
      _entityLookupError = null;
      _isLoadingEntities = false;
      _entityMapsLoading.clear();
    });

    // Propagation sélection vers le provider parent uniquement après frame.
    _dispatchSelectionAfterFrame(resolvedSelection);
    // Prime les entités de la step active hors build (completion + world changes).
    _warmupEntityLookupsForStep(_stepById(resolvedSelection));

    final active = widget.activeMap;
    if (active != null) {
      _entitiesByMapId[active.id] = _sortedWorldEntities(active.entities);
    }

    // Important: on évite un préchargement global "toutes steps / toutes maps"
    // qui peut exploser en coût mémoire sur de gros projets.
    //
    // On reste volontairement ciblé:
    // - prime de la step active (ci-dessus);
    // - prime à la demande lors des actions utilisateur map-centriques.
  }

  /// Déclenche une synchronisation de sélection "provider-safe".
  ///
  /// Cette méthode est volontairement utilisée pour les auto-sélections
  /// (hydrate/reset) qui peuvent survenir pendant des phases de build.
  /// Les interactions utilisateur directes restent synchrones via `_selectStep`.
  void _dispatchSelectionAfterFrame(String? stepId) {
    _queuedSelectionToDispatch = stepId;
    if (_selectionDispatchScheduled) {
      return;
    }
    _selectionDispatchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectionDispatchScheduled = false;
      if (!mounted) {
        return;
      }
      final nextSelection = _queuedSelectionToDispatch;
      _queuedSelectionToDispatch = null;

      // Déduplication pour éviter du bruit côté provider parent.
      if (nextSelection == _lastDispatchedSelection) {
        return;
      }
      _lastDispatchedSelection = nextSelection;
      widget.onSelectStep(nextSelection);
    });
  }

  bool _containsStep(String stepId) {
    final doc = _draftDocument;
    if (doc == null) return false;
    return doc.steps.any((entry) => entry.id == stepId);
  }

  StepStudioStep? _stepById(String? stepId) {
    if (stepId == null) {
      return null;
    }
    final doc = _draftDocument;
    if (doc == null) {
      return null;
    }
    for (final step in doc.steps) {
      if (step.id == stepId) {
        return step;
      }
    }
    return null;
  }

  void _warmupEntityLookupsForStep(StepStudioStep? step) {
    if (step == null) {
      return;
    }
    final mapIds = <String>{};
    // Ne prime la map d'interaction QUE si la completion l'utilise réellement.
    // Cela évite de charger des maps via d'anciennes données legacy résiduelles
    // (interactionId stocké mais mode courant != whenInteractionDone).
    if (step.completion.mode == StepStudioCompletionMode.whenInteractionDone) {
      final interactionRef =
          _decodeInteractionRef(step.completion.interactionId);
      final interactionMapId = interactionRef.mapId?.trim();
      if (interactionMapId != null && interactionMapId.isNotEmpty) {
        mapIds.add(interactionMapId);
      }
    }
    for (final change in step.worldChanges) {
      final mapId = change.mapId.trim();
      if (mapId.isNotEmpty) {
        mapIds.add(mapId);
      }
    }
    for (final mapId in mapIds) {
      unawaited(_ensureEntitiesLoadedForMap(mapId));
    }
  }

  String? _resolveInitialStepSelection({
    required StepStudioDocument document,
    String? preferredStepId,
    String? fallbackStepId,
  }) {
    if (document.steps.isEmpty) {
      return null;
    }
    if (preferredStepId != null &&
        document.steps.any((entry) => entry.id == preferredStepId)) {
      return preferredStepId;
    }
    if (fallbackStepId != null &&
        document.steps.any((entry) => entry.id == fallbackStepId)) {
      return fallbackStepId;
    }
    return document.steps.first.id;
  }

  List<ProjectMapEntry> get _projectMaps {
    final project = widget.project;
    if (project == null) {
      return const <ProjectMapEntry>[];
    }
    final entries = project.maps.toList(growable: false)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return entries;
  }

  List<MapEntity> _sortedWorldEntities(Iterable<MapEntity> entities) {
    return entities
        .where(
          (entity) =>
              entity.kind == MapEntityKind.npc ||
              entity.kind == MapEntityKind.spawn,
        )
        .toList(growable: false)
      ..sort(
        (a, b) => a.inspectorHeadline
            .toLowerCase()
            .compareTo(b.inspectorHeadline.toLowerCase()),
      );
  }

  Future<void> _ensureEntitiesLoadedForMap(String mapId) async {
    final normalizedMapId = mapId.trim();
    if (normalizedMapId.isEmpty) {
      return;
    }

    // Protection anti-boucle/re-entrance:
    // - déjà en cache => rien à faire
    // - déjà en vol => ne pas relancer une 2e requête identique
    if (_entitiesByMapId.containsKey(normalizedMapId) ||
        _entityMapsLoading.contains(normalizedMapId)) {
      return;
    }

    final active = widget.activeMap;
    if (active != null && active.id == normalizedMapId) {
      setState(() {
        _entitiesByMapId[normalizedMapId] =
            _sortedWorldEntities(active.entities);
        _entityLookupError = null;
      });
      return;
    }

    setState(() {
      _entityMapsLoading.add(normalizedMapId);
      _isLoadingEntities = true;
      _entityLookupError = null;
    });

    MapData? snapshot;
    try {
      snapshot =
          await widget.editorNotifier.loadMapSnapshotById(normalizedMapId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _entitiesByMapId[normalizedMapId] = const <MapEntity>[];
        _entityMapsLoading.remove(normalizedMapId);
        _isLoadingEntities = _entityMapsLoading.isNotEmpty;
        _entityLookupError =
            'Impossible de charger les entités de la map "$normalizedMapId": $error';
      });
      return;
    }
    if (!mounted) {
      return;
    }

    final resolvedSnapshot = snapshot;
    if (resolvedSnapshot == null) {
      setState(() {
        _entitiesByMapId[normalizedMapId] = const <MapEntity>[];
        _entityMapsLoading.remove(normalizedMapId);
        _isLoadingEntities = _entityMapsLoading.isNotEmpty;
        _entityLookupError =
            'Impossible de charger les entités de la map "$normalizedMapId".';
      });
      return;
    }

    setState(() {
      _entitiesByMapId[normalizedMapId] =
          _sortedWorldEntities(resolvedSnapshot.entities);
      _entityMapsLoading.remove(normalizedMapId);
      _isLoadingEntities = _entityMapsLoading.isNotEmpty;
      _entityLookupError = null;
    });
  }

  bool get _hasUnsavedChanges =>
      _savedDocument != null &&
      _draftDocument != null &&
      _savedDocument != _draftDocument;

  bool get _canEdit =>
      !_busy && _draftDocument != null && _loadedGlobalScenarioId != null;

  StepStudioStep? get _selectedStep {
    final doc = _draftDocument;
    final selectedStepId = _selectedStepId;
    if (doc == null || selectedStepId == null) {
      return null;
    }
    for (final step in doc.steps) {
      if (step.id == selectedStepId) {
        return step;
      }
    }
    return null;
  }

  ScenarioAsset? get _selectedGlobalScenario {
    final project = widget.project;
    final scenarioId = _loadedGlobalScenarioId;
    if (project == null || scenarioId == null) {
      return null;
    }
    for (final scenario in project.scenarios) {
      if (scenario.id == scenarioId) {
        return scenario;
      }
    }
    return null;
  }

  void _replaceDraft(StepStudioDocument next) {
    // Garde anti-boucle:
    // certains callbacks UI (ex. dropdown/text) peuvent réémettre la même
    // valeur. Sans ce check, on enchaîne des setState() inutiles.
    //
    // Quand cette situation se produit en cascade avec plusieurs widgets,
    // l'éditeur peut entrer dans une tempête de rebuilds et faire gonfler
    // fortement la mémoire. On coupe donc court si le draft est inchangé.
    if (_draftDocument == next) {
      return;
    }
    setState(() {
      _draftDocument = next;
    });
  }

  void _replaceSelectedStep(StepStudioStep nextStep) {
    final doc = _draftDocument;
    if (doc == null) {
      return;
    }
    final current = _selectedStep;
    // Garde anti ping-pong:
    // si la step cible est déjà strictement identique, on ne pousse pas
    // une nouvelle copie de document.
    if (current != null && current.id == nextStep.id && current == nextStep) {
      return;
    }
    final nextSteps = <StepStudioStep>[];
    for (final step in doc.steps) {
      if (step.id == nextStep.id) {
        nextSteps.add(nextStep);
      } else {
        nextSteps.add(step);
      }
    }
    _replaceDraft(doc.copyWith(steps: nextSteps));
  }

  Future<void> _createGlobalStoryAndBootstrapStepStudio() async {
    if (_busy) return;
    final project = widget.project;
    if (project == null) return;

    setState(() {
      _busy = true;
    });

    final scenarioId = generateUniqueScenarioId(project, 'global_story');
    var scenario = ScenarioAsset(
      id: scenarioId,
      name: 'Global Story',
      description: 'Colonne vertébrale narrative du jeu.',
      scope: ScenarioScope.globalStory,
      entryNodeId: 'start',
      nodes: const <ScenarioNode>[
        ScenarioNode(
          id: 'start',
          type: ScenarioNodeType.start,
          title: 'Start',
        ),
        ScenarioNode(
          id: 'end',
          type: ScenarioNodeType.end,
          title: 'End',
        ),
      ],
      edges: const <ScenarioEdge>[
        ScenarioEdge(
          id: 'edge_start_end',
          fromNodeId: 'start',
          toNodeId: 'end',
          kind: ScenarioEdgeKind.next,
          order: 0,
        ),
      ],
    );
    final bootstrap = createDefaultStepStudioDocument(
      globalStoryScenarioId: scenarioId,
    );
    scenario = applyStepStudioDocumentToGlobalScenario(scenario, bootstrap);

    await widget.editorNotifier.createProjectScenario(scenario);

    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
    });
  }

  void _selectStep(String? stepId) {
    // Pas de re-sélection inutile: évite les callbacks parent redondants.
    if (_selectedStepId == stepId) {
      return;
    }
    setState(() {
      _selectedStepId = stepId;
      _flowInspectorFocus = null;
    });
    _warmupEntityLookupsForStep(_stepById(stepId));
    // Interaction utilisateur: callback immédiat (pas dans build/initState).
    _lastDispatchedSelection = stepId;
    widget.onSelectStep(stepId);
  }

  void _addStep() {
    final doc = _draftDocument;
    if (doc == null) return;

    final nextId = generateUniqueStepId(
      'step_${doc.steps.length + 1}',
      existingIds: doc.steps.map((entry) => entry.id),
    );
    final nextOrder = doc.steps.length;
    final nextStep = StepStudioStep(
      id: nextId,
      name: 'Nouvelle step ${nextOrder + 1}',
      description: '',
      order: nextOrder,
      activation: nextOrder == 0
          ? const StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            )
          : const StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
      completion: const StepStudioCompletionRule(
        mode: StepStudioCompletionMode.manual,
      ),
      cutscenes: const <StepStudioCutsceneLink>[],
      outcomes: const <StepStudioOutcomeDefinition>[],
      worldChanges: const <StepStudioWorldChange>[],
    );
    final nextDoc = doc.copyWith(
      steps: <StepStudioStep>[
        ...doc.steps,
        nextStep,
      ],
    );
    _replaceDraft(nextDoc);
    _selectStep(nextId);
  }

  void _deleteSelectedStep() {
    final doc = _draftDocument;
    final selected = _selectedStep;
    if (doc == null || selected == null || doc.steps.length <= 1) {
      return;
    }

    final nextSteps = doc.steps
        .where((entry) => entry.id != selected.id)
        .toList(growable: false);
    final normalizedSteps = <StepStudioStep>[];
    for (var i = 0; i < nextSteps.length; i++) {
      normalizedSteps.add(nextSteps[i].copyWith(order: i));
    }

    final nextDoc = doc.copyWith(steps: normalizedSteps);
    _replaceDraft(nextDoc);
    _selectStep(normalizedSteps.first.id);
  }

  void _moveSelectedStep(int delta) {
    final doc = _draftDocument;
    final selected = _selectedStep;
    if (doc == null || selected == null) {
      return;
    }
    final currentIndex =
        doc.steps.indexWhere((entry) => entry.id == selected.id);
    if (currentIndex < 0) {
      return;
    }
    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= doc.steps.length) {
      return;
    }

    final mutable = doc.steps.toList(growable: true);
    final removed = mutable.removeAt(currentIndex);
    mutable.insert(nextIndex, removed);
    final normalized = <StepStudioStep>[];
    for (var i = 0; i < mutable.length; i++) {
      normalized.add(mutable[i].copyWith(order: i));
    }
    _replaceDraft(doc.copyWith(steps: normalized));
  }

  // ---------------------------------------------------------------------------
  // Step Studio — flux 3 colonnes : actions palette / résolution noms cutscene
  // ---------------------------------------------------------------------------

  String _cutsceneDisplayName(String cutsceneId) {
    for (final s in widget.projection.localEventFlows) {
      if (s.id == cutsceneId) {
        return s.name;
      }
    }
    return cutsceneId;
  }

  void _appendOutcome(StepStudioOutcomeScope scope) {
    final selectedStep = _selectedStep;
    if (selectedStep == null || !_canEdit) {
      return;
    }
    final outcomes = selectedStep.outcomes;
    final label = switch (scope) {
      StepStudioOutcomeScope.local => 'Nouveau choix local',
      StepStudioOutcomeScope.progression => 'Nouveau résultat de progression',
      StepStudioOutcomeScope.world => 'Nouveau résultat monde',
    };
    final outcome = StepStudioOutcomeDefinition(
      label: label,
      scope: scope,
      outcomeId: generateOutcomeIdFromLabel(
        stepId: selectedStep.id,
        label: label,
        scope: scope,
      ),
    );
    final newIndex = outcomes.length;
    _replaceSelectedStep(
      selectedStep.copyWith(
        outcomes: <StepStudioOutcomeDefinition>[...outcomes, outcome],
      ),
    );
    setState(() {
      _flowInspectorFocus = StepFlowFocus(
        scope == StepStudioOutcomeScope.local
            ? StepFlowSlot.localOutcome
            : StepFlowSlot.progressionOutcome,
        newIndex,
      );
    });
  }

  void _addCutsceneLinkForFlow() {
    final selectedStep = _selectedStep;
    if (selectedStep == null || !_canEdit) {
      return;
    }
    final options = _cutsceneOptions();
    if (options.isEmpty) {
      return;
    }
    final defaultCutsceneId = options.first.id;
    final nextLinks = <StepStudioCutsceneLink>[
      ...selectedStep.cutscenes,
      StepStudioCutsceneLink(
        cutsceneId: defaultCutsceneId,
        role: StepStudioCutsceneRole.main,
      ),
    ];
    final newIndex = nextLinks.length - 1;
    _replaceSelectedStep(selectedStep.copyWith(cutscenes: nextLinks));
    setState(() {
      _flowInspectorFocus = StepFlowFocus(StepFlowSlot.cutsceneLink, newIndex);
    });
  }

  void _addWorldChangeForFlow() {
    final selectedStep = _selectedStep;
    if (selectedStep == null || !_canEdit) {
      return;
    }
    final mapOptions = _projectMaps;
    if (mapOptions.isEmpty) {
      return;
    }
    final defaultMapId = mapOptions.first.id;
    unawaited(_ensureEntitiesLoadedForMap(defaultMapId));
    final nextChange = StepStudioWorldChange(
      mapId: defaultMapId,
      entityId: '',
      presenceRule: StepStudioPresenceRule.visibleAfterStepCompletion,
      note: '',
    );
    final next = <StepStudioWorldChange>[
      ...selectedStep.worldChanges,
      nextChange,
    ];
    _replaceSelectedStep(selectedStep.copyWith(worldChanges: next));
    setState(() {
      _flowInspectorFocus =
          StepFlowFocus(StepFlowSlot.worldChangeItem, next.length - 1);
    });
  }

  /// Gabarit « Choix du starter » : remplit surtout **données structurées**
  /// (`outcomes`, `completion`) + **annotations canvas** (`flow*Label`, mémo
  /// `flowUnlocksStepId`). Les textes flux ne remplacent pas la logique runtime.
  void _applyStarterChoiceDemoTemplate() {
    final selectedStep = _selectedStep;
    final doc = _draftDocument;
    if (selectedStep == null || doc == null || !_canEdit) {
      return;
    }

    String? unlocks;
    for (final s in doc.steps) {
      if (s.id == selectedStep.id) {
        continue;
      }
      final n = s.name.toLowerCase();
      if (n.contains('rival') || n.contains('combat')) {
        unlocks = s.id;
        break;
      }
    }
    if (unlocks == null && doc.steps.length > 1) {
      for (final s in doc.steps) {
        if (s.id != selectedStep.id) {
          unlocks = s.id;
          break;
        }
      }
    }

    final fire = StepStudioOutcomeDefinition(
      label: 'Starter feu',
      scope: StepStudioOutcomeScope.local,
      outcomeId: 'starter.selected.fire',
    );
    final water = StepStudioOutcomeDefinition(
      label: 'Starter eau',
      scope: StepStudioOutcomeScope.local,
      outcomeId: 'starter.selected.water',
    );
    final grass = StepStudioOutcomeDefinition(
      label: 'Starter plante',
      scope: StepStudioOutcomeScope.local,
      outcomeId: 'starter.selected.grass',
    );
    final chapter = StepStudioOutcomeDefinition(
      label: 'Chapitre 1 — starter choisi',
      scope: StepStudioOutcomeScope.progression,
      outcomeId: 'chapter_1.starter_chosen',
    );

    final keepWorld = selectedStep.outcomes
        .where((o) => o.scope == StepStudioOutcomeScope.world)
        .toList();

    _replaceSelectedStep(
      selectedStep.copyWith(
        name: 'Choix du starter',
        description:
            'Le joueur doit sélectionner son premier Pokémon auprès du professeur.',
        flowEntryLabel: 'Le professeur a été rencontré.',
        flowObjectiveLabel: 'Choisir un starter.',
        flowValidationLabel: 'Un starter a été attribué au joueur.',
        flowExitLabel: 'Débloquer la step « Combat rival ».',
        flowUnlocksStepId: unlocks,
        outcomes: <StepStudioOutcomeDefinition>[
          fire,
          water,
          grass,
          chapter,
          ...keepWorld,
        ],
        completion: const StepStudioCompletionRule(
          mode: StepStudioCompletionMode.whenOutcomeEmitted,
          outcomeId: 'chapter_1.starter_chosen',
        ),
      ),
    );
    setState(() {
      _flowInspectorFocus = const StepFlowFocus(StepFlowSlot.objective);
    });
  }

  Future<void> _saveDraft() async {
    final scenario = _selectedGlobalScenario;
    final draft = _draftDocument;
    if (scenario == null || draft == null) {
      return;
    }
    setState(() {
      _busy = true;
    });

    final nextScenario =
        applyStepStudioDocumentToGlobalScenario(scenario, draft);
    await widget.editorNotifier.updateProjectScenario(
      scenarioId: scenario.id,
      scenario: nextScenario,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _savedDocument = draft;
      _busy = false;
    });
  }

  void _resetDraft() {
    final saved = _savedDocument;
    if (saved == null) {
      return;
    }
    setState(() {
      _draftDocument = saved;
      _selectedStepId = _resolveInitialStepSelection(
        document: saved,
        preferredStepId: _selectedStepId,
        fallbackStepId: saved.steps.isEmpty ? null : saved.steps.first.id,
      );
    });
    _warmupEntityLookupsForStep(_stepById(_selectedStepId));
    // Le reset est déclenché par action utilisateur, on peut notifier direct.
    _lastDispatchedSelection = _selectedStepId;
    widget.onSelectStep(_selectedStepId);
  }

  List<_SimpleOption> _cutsceneOptions() {
    final options = widget.projection.localEventFlows
        .map(
          (scenario) => _SimpleOption(
            id: scenario.id,
            label: scenario.name,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return options;
  }

  List<_SimpleOption> _outcomeOptions() {
    final doc = _draftDocument;
    final outcomeIds = <String>{
      for (final outcome in widget.projection.outcomes) outcome.id,
      if (doc != null)
        for (final step in doc.steps)
          for (final outcome in step.outcomes) outcome.outcomeId,
    };
    final options = outcomeIds
        .where((entry) => entry.trim().isNotEmpty)
        .map(
          (entry) => _SimpleOption(
            id: entry,
            label: entry,
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return options;
  }

  List<_SimpleOption> _stepOptions({String? excludeStepId}) {
    final doc = _draftDocument;
    if (doc == null) {
      return const <_SimpleOption>[];
    }
    return doc.steps
        .where((entry) => entry.id != excludeStepId)
        .map(
          (entry) => _SimpleOption(
            id: entry.id,
            label: '${entry.order + 1}. ${entry.name}',
          ),
        )
        .toList(growable: false);
  }

  List<MapEntity> _entitiesForMap(String? mapId) {
    final normalized = mapId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return const <MapEntity>[];
    }
    final active = widget.activeMap;
    if (active != null && active.id == normalized) {
      return _sortedWorldEntities(active.entities);
    }
    return _entitiesByMapId[normalized] ?? const <MapEntity>[];
  }

  String _entityLabel(MapEntity entity) {
    final kindLabel = switch (entity.kind) {
      MapEntityKind.npc => 'PNJ',
      MapEntityKind.spawn => 'Spawn',
      MapEntityKind.sign => 'Panneau',
      MapEntityKind.item => 'Objet',
      _ => 'Entité',
    };
    return '$kindLabel • ${entity.inspectorHeadline}';
  }

  _InteractionRef _decodeInteractionRef(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) {
      return const _InteractionRef();
    }
    final parts = value.split('::');
    if (parts.length != 2) {
      return const _InteractionRef();
    }
    final mapId = parts[0].trim();
    final entityId = parts[1].trim();
    if (mapId.isEmpty || entityId.isEmpty) {
      return const _InteractionRef();
    }
    return _InteractionRef(mapId: mapId, entityId: entityId);
  }

  String _encodeInteractionRef({
    required String mapId,
    required String entityId,
  }) {
    return '${mapId.trim()}::${entityId.trim()}';
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    if (project == null) {
      return const EditorPaneSurface(
        radius: 20,
        tint: EditorChrome.islandWarmTint,
        child: Center(
          child: Text('Chargez un projet pour éditer les steps.'),
        ),
      );
    }

    final globalStories = project.scenarios
        .where((entry) => entry.scope == ScenarioScope.globalStory)
        .toList(growable: false);
    if (globalStories.isEmpty) {
      return _buildNoGlobalStoryState(context);
    }

    final selectedStep = _selectedStep;
    final draft = _draftDocument;

    return Row(
      children: [
        SizedBox(
          width: 320,
          child: _buildStepNavigatorCard(
            context: context,
            globalStories: globalStories,
            draft: draft,
            selectedStep: selectedStep,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: draft == null || selectedStep == null
              ? _buildNoStepSelectedState(context)
              : _buildStepEditor(context, draft, selectedStep, globalStories),
        ),
      ],
    );
  }

  Widget _buildNoGlobalStoryState(BuildContext context) {
    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandWarmTint,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.link_circle_fill,
                size: 34,
                color: EditorChrome.inspectorJoyCyan,
              ),
              const SizedBox(height: 10),
              Text(
                'Aucun scénario global',
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le produit impose un scénario global unique. Créez-le pour démarrer le Step Studio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 280,
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyCyan,
                  icon: CupertinoIcons.plus_circle_fill,
                  label: 'Créer le scénario global',
                  prominent: true,
                  enabled: !_busy,
                  onPressed: _createGlobalStoryAndBootstrapStepStudio,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoStepSelectedState(BuildContext context) {
    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandWarmTint,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.square_stack_3d_up_fill,
              color: EditorChrome.inspectorJoyAmber,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez une step',
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 220,
              child: InspectorEmbeddedPrimaryCapsule(
                accent: EditorChrome.inspectorJoyAmber,
                icon: CupertinoIcons.plus_circle_fill,
                label: 'Créer une step',
                enabled: _canEdit,
                onPressed: _addStep,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepNavigatorCard({
    required BuildContext context,
    required List<ScenarioAsset> globalStories,
    required StepStudioDocument? draft,
    required StepStudioStep? selectedStep,
  }) {
    final globalTitle = globalStories.first.name.trim().isEmpty
        ? globalStories.first.id
        : globalStories.first.name;
    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandNeutralTint,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Steps du scénario global',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            globalTitle,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
            ),
          ),
          if (globalStories.length > 1) ...[
            const SizedBox(height: 8),
            _InlineInfoBanner(
              accent: EditorChrome.inspectorJoyCoral,
              text:
                  'Plusieurs scénarios globaux détectés. Step Studio édite uniquement le premier (règle produit: scénario global unique).',
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyMint,
                  icon: CupertinoIcons.plus_circle_fill,
                  label: 'Nouvelle step',
                  enabled: _canEdit,
                  onPressed: _addStep,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyCoral,
                  icon: CupertinoIcons.delete,
                  label: 'Supprimer',
                  enabled: _canEdit && draft != null && draft.steps.length > 1,
                  onPressed: _deleteSelectedStep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: draft == null || draft.steps.isEmpty
                ? Center(
                    child: Text(
                      'Aucune step.',
                      style: TextStyle(
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: draft.steps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final step = draft.steps[index];
                      return EditorSidebarListRow(
                        selected: selectedStep?.id == step.id,
                        onTap: () => _selectStep(step.id),
                        leading: const Icon(CupertinoIcons.flag_fill),
                        title: Text('${step.order + 1}. ${step.name}'),
                        subtitle: Text(
                          '${step.cutscenes.length} cutscene(s) • ${step.outcomes.length} résultat(s) • ${step.worldChanges.length} changement(s) monde',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Assemble les 3 colonnes : palette métier | canvas de flux | inspecteur.
  Widget _buildStepEditor(
    BuildContext context,
    StepStudioDocument draft,
    StepStudioStep selectedStep,
    List<ScenarioAsset> globalStories,
  ) {
    final cutsceneOptions = _cutsceneOptions();
    final outcomeOptions = _outcomeOptions();
    final previousStepOptions = _stepOptions(excludeStepId: selectedStep.id);
    final mapOptions = _projectMaps
        .map(
          (entry) => _SimpleOption(
            id: entry.id,
            label: '${entry.name} (${entry.id})',
          ),
        )
        .toList(growable: false);

    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandWarmTint,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            context: context,
            selectedStep: selectedStep,
            globalStories: globalStories,
          ),
          const SizedBox(height: 12),
          if (_usedLegacyFallback) ...[
            const _InlineInfoBanner(
              accent: EditorChrome.inspectorJoyAmber,
              text:
                  'Cette donnée provient d\'un fallback legacy (metadata step.*). Sauvegardez pour migrer vers Step Studio v1.',
            ),
            const SizedBox(height: 10),
          ],
          for (final warning in _loadWarnings) ...[
            _InlineInfoBanner(
              accent: EditorChrome.inspectorJoyCoral,
              text: warning,
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Largeur fixe des colonnes latérales + gouttières (~560). En surface
                // étroite (tests widget 800px, sidebar 320px → ~440px pour l’éditeur),
                // un Row horizontal déborde : on empile palette / canvas / inspecteur.
                const lateral = 232.0 + 308.0 + 20.0;
                final useStackedLayout =
                    constraints.maxWidth < lateral + 160;

                final palette = StepFlowPalette(
                  enabled: _canEdit,
                  onFocus: (f) => setState(() => _flowInspectorFocus = f),
                  onAddCutsceneLink: _addCutsceneLinkForFlow,
                  onAddLocalOutcome: () =>
                      _appendOutcome(StepStudioOutcomeScope.local),
                  onAddProgressionOutcome: () =>
                      _appendOutcome(StepStudioOutcomeScope.progression),
                  onAddWorldChange: _addWorldChangeForFlow,
                  canAddCutscene: cutsceneOptions.isNotEmpty,
                  canAddWorldChange: mapOptions.isNotEmpty,
                );

                final canvas = StepFlowCanvas(
                  step: selectedStep,
                  selected: _flowInspectorFocus,
                  onSelect: (f) => setState(() => _flowInspectorFocus = f),
                  resolveCutsceneName: _cutsceneDisplayName,
                );

                final inspector = _buildFlowInspectorColumn(
                  context,
                  selectedStep: selectedStep,
                  cutsceneOptions: cutsceneOptions,
                  outcomeOptions: outcomeOptions,
                  previousStepOptions: previousStepOptions,
                  mapOptions: mapOptions,
                );

                if (useStackedLayout) {
                  // Pas de hauteurs fixes : en tests la zone utile peut être très basse.
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: palette,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 4,
                        child: canvas,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 3,
                        child: inspector,
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 232, child: palette),
                    const SizedBox(width: 10),
                    Expanded(child: canvas),
                    const SizedBox(width: 10),
                    SizedBox(width: 308, child: inspector),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          const InspectorEmbeddedFootnote(
            text:
                'Notes « flux » = auteur. Règles structurées : activation, completion, outcomes, cutscenes.',
            accent: EditorChrome.inspectorJoyCyan,
          ),
        ],
      ),
    );
  }

  /// Panneau droit : détail du bloc sélectionné sur le canvas (données Step).
  Widget _buildFlowInspectorColumn(
    BuildContext context, {
    required StepStudioStep selectedStep,
    required List<_SimpleOption> cutsceneOptions,
    required List<_SimpleOption> outcomeOptions,
    required List<_SimpleOption> previousStepOptions,
    required List<_SimpleOption> mapOptions,
  }) {
    final focus = _flowInspectorFocus;
    return EditorPaneSurface(
      radius: 16,
      tint: EditorChrome.islandNeutralTint,
      padding: const EdgeInsets.fromLTRB(11, 12, 11, 12),
      child: focus == null
          ? Center(
              child: Text(
                'Sélectionnez une carte du flux ou un raccourci à gauche.\n'
                'Pas de mise en scène ici (Cutscene Studio).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            )
          : SingleChildScrollView(
              child: _buildFlowInspectorContent(
                context,
                focus: focus,
                selectedStep: selectedStep,
                cutsceneOptions: cutsceneOptions,
                outcomeOptions: outcomeOptions,
                previousStepOptions: previousStepOptions,
                mapOptions: mapOptions,
              ),
            ),
    );
  }

  Widget _buildFlowInspectorContent(
    BuildContext context, {
    required StepFlowFocus focus,
    required StepStudioStep selectedStep,
    required List<_SimpleOption> cutsceneOptions,
    required List<_SimpleOption> outcomeOptions,
    required List<_SimpleOption> previousStepOptions,
    required List<_SimpleOption> mapOptions,
  }) {
    switch (focus.slot) {
      case StepFlowSlot.flowEntry:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepSectionCard(
              title: 'Entrée & activation',
              subtitle:
                  'Champ ci-dessous : note auteur (canvas). Section suivante : activation (structurée).',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _InlineTextField(
                    label: 'Note (canvas), pas une règle runtime',
                    value: selectedStep.flowEntryLabel,
                    enabled: _canEdit,
                    minLines: 2,
                    maxLines: 5,
                    onChanged: (v) => _replaceSelectedStep(
                      selectedStep.copyWith(flowEntryLabel: v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Activation : ${summarizeStepActivation(selectedStep)}',
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildActivationSection(
              context,
              selectedStep,
              previousStepOptions: previousStepOptions,
              outcomeOptions: outcomeOptions,
              cutsceneOptions: cutsceneOptions,
            ),
          ],
        );

      case StepFlowSlot.objective:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIdentitySection(context, selectedStep),
            const SizedBox(height: 10),
            _StepSectionCard(
              title: 'Objectif',
              subtitle:
                  'Identité = nom + description. Ligne suivante = note canvas optionnelle.',
              child: _InlineTextField(
                label: 'Ligne canvas (optionnel, note auteur)',
                value: selectedStep.flowObjectiveLabel,
                enabled: _canEdit,
                minLines: 2,
                maxLines: 4,
                onChanged: (v) => _replaceSelectedStep(
                  selectedStep.copyWith(flowObjectiveLabel: v),
                ),
              ),
            ),
          ],
        );

      case StepFlowSlot.cutsceneLink:
        final idx = focus.listIndex;
        final links = selectedStep.cutscenes;
        if (idx == null || idx < 0 || idx >= links.length) {
          return Text(
            'Lien cutscene introuvable.',
            style: TextStyle(color: EditorChrome.subtleLabel(context)),
          );
        }
        final link = links[idx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepSectionCard(
              title: 'Cutscene (référence)',
              subtitle: 'Id + rôle. Contenu scène : Cutscene Studio.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CutsceneLinkRow(
                    link: link,
                    cutsceneOptions: cutsceneOptions,
                    enabled: _canEdit,
                    onRoleChanged: (role) {
                      final next = links.toList(growable: true);
                      next[idx] = next[idx].copyWith(role: role);
                      _replaceSelectedStep(
                        selectedStep.copyWith(cutscenes: next),
                      );
                    },
                    onCutsceneChanged: (cutsceneId) {
                      if (cutsceneId == null) {
                        return;
                      }
                      final next = links.toList(growable: true);
                      next[idx] = next[idx].copyWith(cutsceneId: cutsceneId);
                      _replaceSelectedStep(
                        selectedStep.copyWith(cutscenes: next),
                      );
                    },
                    onRemove: () {
                      final next = links.toList(growable: true)..removeAt(idx);
                      _replaceSelectedStep(
                        selectedStep.copyWith(cutscenes: next),
                      );
                      setState(() => _flowInspectorFocus = null);
                    },
                  ),
                  if (widget.onOpenCutsceneStudio != null) ...[
                    const SizedBox(height: 10),
                    InspectorEmbeddedSecondaryCapsule(
                      accent: EditorChrome.inspectorJoyPlum,
                      icon: CupertinoIcons.arrow_right_square,
                      label: 'Ouvrir dans Cutscene Studio',
                      enabled: _canEdit,
                      onPressed: () =>
                          widget.onOpenCutsceneStudio!(link.cutsceneId),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

      case StepFlowSlot.localBranches:
        return _StepSectionCard(
          title: 'Outcomes locaux',
          subtitle:
              'Donnée structurée : liste outcomes (scope local). Pas une branche d’exécution scène.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final o in selectedStep.outcomes.where(
                (x) => x.scope == StepStudioOutcomeScope.local,
              ))
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    onPressed: () {
                      final i = selectedStep.outcomes.indexOf(o);
                      setState(() {
                        _flowInspectorFocus =
                            StepFlowFocus(StepFlowSlot.localOutcome, i);
                      });
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '• ${o.label} (${o.outcomeId})',
                        style: TextStyle(
                          color: EditorChrome.primaryLabel(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              InspectorEmbeddedSecondaryCapsule(
                accent: EditorChrome.inspectorJoyOrchid,
                icon: CupertinoIcons.plus_circle_fill,
                label: 'Ajouter un résultat local',
                enabled: _canEdit,
                onPressed: () => _appendOutcome(StepStudioOutcomeScope.local),
              ),
            ],
          ),
        );

      case StepFlowSlot.localOutcome:
        final i = focus.listIndex;
        final outcomes = selectedStep.outcomes;
        if (i == null || i < 0 || i >= outcomes.length) {
          return const SizedBox.shrink();
        }
        final o = outcomes[i];
        if (o.scope != StepStudioOutcomeScope.local) {
          return Text(
            'Ce résultat n’est pas de portée locale.',
            style: TextStyle(color: EditorChrome.subtleLabel(context)),
          );
        }
        return _OutcomeRow(
          outcome: o,
          enabled: _canEdit,
          onLabelChanged: (label) {
            final generated = generateOutcomeIdFromLabel(
              stepId: selectedStep.id,
              label: label,
              scope: o.scope,
            );
            final next = outcomes.toList(growable: true);
            next[i] = o.copyWith(label: label, outcomeId: generated);
            _replaceSelectedStep(selectedStep.copyWith(outcomes: next));
          },
          onScopeChanged: (scope) {
            final generated = generateOutcomeIdFromLabel(
              stepId: selectedStep.id,
              label: o.label,
              scope: scope,
            );
            final next = outcomes.toList(growable: true);
            next[i] = o.copyWith(scope: scope, outcomeId: generated);
            _replaceSelectedStep(selectedStep.copyWith(outcomes: next));
          },
          onTapOutcomeId: () => widget.onSelectOutcome(o.outcomeId),
          onRemove: () {
            final next = outcomes.toList(growable: true)..removeAt(i);
            _replaceSelectedStep(selectedStep.copyWith(outcomes: next));
            setState(() => _flowInspectorFocus = null);
          },
        );

      case StepFlowSlot.validationEngine:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepSectionCard(
              title: 'Validation',
              subtitle: 'Note auteur puis règle completion (structurée).',
              child: _InlineTextField(
                label: 'Note (canvas), pas la règle seule',
                value: selectedStep.flowValidationLabel,
                enabled: _canEdit,
                minLines: 2,
                maxLines: 4,
                onChanged: (v) => _replaceSelectedStep(
                  selectedStep.copyWith(flowValidationLabel: v),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _buildCompletionSection(
              context,
              selectedStep,
              outcomeOptions: outcomeOptions,
              cutsceneOptions: cutsceneOptions,
            ),
          ],
        );

      case StepFlowSlot.progressionOutcome:
        final i = focus.listIndex;
        final outcomes = selectedStep.outcomes;
        if (i == null || i < 0 || i >= outcomes.length) {
          return const SizedBox.shrink();
        }
        final o = outcomes[i];
        if (o.scope != StepStudioOutcomeScope.progression) {
          return Text(
            'Sélectionnez un résultat « Progression » sur le canvas.',
            style: TextStyle(color: EditorChrome.subtleLabel(context)),
          );
        }
        return _OutcomeRow(
          outcome: o,
          enabled: _canEdit,
          onLabelChanged: (label) {
            final generated = generateOutcomeIdFromLabel(
              stepId: selectedStep.id,
              label: label,
              scope: o.scope,
            );
            final next = outcomes.toList(growable: true);
            next[i] = o.copyWith(label: label, outcomeId: generated);
            _replaceSelectedStep(selectedStep.copyWith(outcomes: next));
          },
          onScopeChanged: (scope) {
            final generated = generateOutcomeIdFromLabel(
              stepId: selectedStep.id,
              label: o.label,
              scope: scope,
            );
            final next = outcomes.toList(growable: true);
            next[i] = o.copyWith(scope: scope, outcomeId: generated);
            _replaceSelectedStep(selectedStep.copyWith(outcomes: next));
          },
          onTapOutcomeId: () => widget.onSelectOutcome(o.outcomeId),
          onRemove: () {
            final next = outcomes.toList(growable: true)..removeAt(i);
            _replaceSelectedStep(selectedStep.copyWith(outcomes: next));
            setState(() => _flowInspectorFocus = null);
          },
        );

      case StepFlowSlot.exitNext:
        return _StepSectionCard(
          title: 'Notes sortie',
          subtitle:
              'Annotation + mémo id. Aucun des deux ne débloque une step (voir activation de la step cible).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InlineTextField(
                label: 'Texte (visible sur le canvas)',
                value: selectedStep.flowExitLabel,
                enabled: _canEdit,
                minLines: 2,
                maxLines: 4,
                onChanged: (v) => _replaceSelectedStep(
                  selectedStep.copyWith(flowExitLabel: v),
                ),
              ),
              const SizedBox(height: 10),
              _SimpleDropdown(
                accent: EditorChrome.inspectorJoyCyan,
                fieldLabel: 'Mémo : id d’une autre step (éditeur, sans effet runtime)',
                options: previousStepOptions,
                selectedId: selectedStep.flowUnlocksStepId,
                emptyLabel: '— Aucune —',
                enabled: _canEdit,
                onSelected: (id) {
                  _replaceSelectedStep(
                    selectedStep.copyWith(flowUnlocksStepId: id),
                  );
                },
              ),
            ],
          ),
        );

      case StepFlowSlot.worldPersistence:
        return _buildWorldPersistenceSection(context, selectedStep);

      case StepFlowSlot.worldChangeItem:
        final i = focus.listIndex;
        final changes = selectedStep.worldChanges;
        if (i == null || i < 0 || i >= changes.length) {
          return const SizedBox.shrink();
        }
        return _WorldChangeRow(
          change: changes[i],
          mapOptions: mapOptions,
          entityOptions: _entitiesForMap(changes[i].mapId)
              .map(
                (entity) => _SimpleOption(
                  id: entity.id,
                  label: _entityLabel(entity),
                ),
              )
              .toList(growable: false),
          loadingEntities: _isLoadingEntities,
          enabled: _canEdit,
          onMapChanged: (mapId) {
            if (mapId == null) {
              return;
            }
            unawaited(_ensureEntitiesLoadedForMap(mapId));
            final next = changes.toList(growable: true);
            next[i] = next[i].copyWith(mapId: mapId, entityId: '');
            _replaceSelectedStep(selectedStep.copyWith(worldChanges: next));
          },
          onEntityChanged: (entityId) {
            if (entityId == null) {
              return;
            }
            final next = changes.toList(growable: true);
            next[i] = next[i].copyWith(entityId: entityId);
            _replaceSelectedStep(selectedStep.copyWith(worldChanges: next));
          },
          onRuleChanged: (rule) {
            final next = changes.toList(growable: true);
            next[i] = next[i].copyWith(presenceRule: rule);
            _replaceSelectedStep(selectedStep.copyWith(worldChanges: next));
          },
          onNoteChanged: (note) {
            final next = changes.toList(growable: true);
            next[i] = next[i].copyWith(note: note);
            _replaceSelectedStep(selectedStep.copyWith(worldChanges: next));
          },
          onRemove: () {
            final next = changes.toList(growable: true)..removeAt(i);
            _replaceSelectedStep(selectedStep.copyWith(worldChanges: next));
            setState(() => _flowInspectorFocus = null);
          },
        );
    }
  }

  Widget _buildHeader({
    required BuildContext context,
    required StepStudioStep selectedStep,
    required List<ScenarioAsset> globalStories,
  }) {
    final globalName = globalStories.first.name.trim().isEmpty
        ? globalStories.first.id
        : globalStories.first.name;
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.35),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedStep.name,
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scénario global unique: $globalName',
                      style: TextStyle(
                        color: EditorChrome.subtleLabel(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hasUnsavedChanges)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        EditorChrome.inspectorJoyCoral.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: EditorChrome.inspectorJoyCoral
                          .withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Text(
                    'Non sauvegardé',
                    style: TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyBlue,
                  icon: CupertinoIcons.floppy_disk,
                  label: 'Sauvegarder',
                  prominent: true,
                  enabled: _canEdit && _hasUnsavedChanges,
                  onPressed: _saveDraft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyCyan,
                  icon: CupertinoIcons.arrow_uturn_left,
                  label: 'Réinitialiser',
                  enabled: _canEdit && _hasUnsavedChanges,
                  onPressed: _resetDraft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyMint,
                  icon: CupertinoIcons.plus_circle_fill,
                  label: 'Ajouter une step',
                  enabled: _canEdit,
                  onPressed: _addStep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Gabarit pédagogique §11 : remplit objectifs / outcomes / validation
          // pour illustrer la séparation Step (métier) vs Cutscene (mise en scène).
          // Les cutscenes starter_intro / starter_selection restent à lier manuellement.
          InspectorEmbeddedSecondaryCapsule(
            accent: EditorChrome.inspectorJoyOrchid,
            icon: CupertinoIcons.wand_stars,
            label: 'Gabarit produit : Choix du starter',
            enabled: _canEdit,
            onPressed: _applyStarterChoiceDemoTemplate,
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection(
      BuildContext context, StepStudioStep selectedStep) {
    return _StepSectionCard(
      title: '1. Identité',
      subtitle:
          'Cette fiche décrit l’objectif métier de la step. Les IDs restent secondaires.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InlineTextField(
            label: 'Nom de la step',
            value: selectedStep.name,
            enabled: _canEdit,
            onChanged: (value) {
              _replaceSelectedStep(selectedStep.copyWith(name: value));
            },
          ),
          const SizedBox(height: 8),
          _InlineTextField(
            label: 'Description courte',
            value: selectedStep.description,
            enabled: _canEdit,
            minLines: 2,
            maxLines: 4,
            onChanged: (value) {
              _replaceSelectedStep(selectedStep.copyWith(description: value));
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.06),
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Identifiant interne (généré)',
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  selectedStep.id,
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyAmber,
                  icon: CupertinoIcons.arrow_up,
                  label: 'Monter',
                  enabled: _canEdit && selectedStep.order > 0,
                  onPressed: () => _moveSelectedStep(-1),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyAmber,
                  icon: CupertinoIcons.arrow_down,
                  label: 'Descendre',
                  enabled: _canEdit &&
                      _draftDocument != null &&
                      selectedStep.order < _draftDocument!.steps.length - 1,
                  onPressed: () => _moveSelectedStep(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivationSection(
    BuildContext context,
    StepStudioStep selectedStep, {
    required List<_SimpleOption> previousStepOptions,
    required List<_SimpleOption> outcomeOptions,
    required List<_SimpleOption> cutsceneOptions,
  }) {
    final activation = selectedStep.activation;
    return _StepSectionCard(
      title: '2. Activation',
      subtitle:
          'Définit comment cette step devient active dans le scénario global.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EnumDropdown<StepStudioActivationMode>(
            accent: EditorChrome.inspectorJoyMint,
            fieldLabel: 'Mode d’activation',
            value: activation.mode,
            values: StepStudioActivationMode.values,
            labelBuilder: stepStudioActivationModeLabel,
            enabled: _canEdit,
            onChanged: (mode) {
              _replaceSelectedStep(
                selectedStep.copyWith(
                  activation: StepStudioActivationRule(mode: mode),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          if (activation.mode == StepStudioActivationMode.afterStep ||
              activation.mode == StepStudioActivationMode.afterPreviousStep)
            _SimpleDropdown(
              accent: EditorChrome.inspectorJoyMint,
              fieldLabel:
                  activation.mode == StepStudioActivationMode.afterPreviousStep
                      ? 'Step précédente'
                      : 'Step requise',
              options: previousStepOptions,
              selectedId: activation.stepId,
              emptyLabel: 'Aucune step disponible',
              enabled: _canEdit && previousStepOptions.isNotEmpty,
              onSelected: (id) {
                _replaceSelectedStep(
                  selectedStep.copyWith(
                    activation: activation.copyWith(stepId: id),
                  ),
                );
              },
            ),
          if (activation.mode == StepStudioActivationMode.afterOutcome)
            _SimpleDropdown(
              accent: EditorChrome.inspectorJoyMint,
              fieldLabel: 'Résultat déclencheur',
              options: outcomeOptions,
              selectedId: activation.outcomeId,
              emptyLabel: 'Aucun résultat disponible',
              enabled: _canEdit && outcomeOptions.isNotEmpty,
              onSelected: (id) {
                _replaceSelectedStep(
                  selectedStep.copyWith(
                    activation: activation.copyWith(outcomeId: id),
                  ),
                );
              },
            ),
          if (activation.mode == StepStudioActivationMode.afterCutscene)
            _SimpleDropdown(
              accent: EditorChrome.inspectorJoyMint,
              fieldLabel: 'Cutscene déclencheuse',
              options: cutsceneOptions,
              selectedId: activation.cutsceneId,
              emptyLabel: 'Aucune cutscene disponible',
              enabled: _canEdit && cutsceneOptions.isNotEmpty,
              onSelected: (id) {
                _replaceSelectedStep(
                  selectedStep.copyWith(
                    activation: activation.copyWith(cutsceneId: id),
                  ),
                );
              },
            ),
          if (activation.mode == StepStudioActivationMode.whenFlagTrue)
            _InlineTextField(
              label: 'État monde attendu',
              value: activation.flagName ?? '',
              enabled: _canEdit,
              onChanged: (value) {
                _replaceSelectedStep(
                  selectedStep.copyWith(
                    activation: activation.copyWith(flagName: value),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCompletionSection(
    BuildContext context,
    StepStudioStep selectedStep, {
    required List<_SimpleOption> outcomeOptions,
    required List<_SimpleOption> cutsceneOptions,
  }) {
    final completion = selectedStep.completion;
    final interactionRef = _decodeInteractionRef(completion.interactionId);
    final mapOptions = _projectMaps
        .map(
          (entry) => _SimpleOption(
            id: entry.id,
            label: '${entry.name} (${entry.id})',
          ),
        )
        .toList(growable: false);

    final interactionEntityOptions = _entitiesForMap(interactionRef.mapId)
        .map(
          (entity) => _SimpleOption(
            id: entity.id,
            label: _entityLabel(entity),
          ),
        )
        .toList(growable: false);

    return _StepSectionCard(
      title: '3. Validation',
      subtitle: 'Définit quand la step est considérée comme terminée.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EnumDropdown<StepStudioCompletionMode>(
            accent: EditorChrome.inspectorJoyBlue,
            fieldLabel: 'Condition de fin',
            value: completion.mode,
            values: StepStudioCompletionMode.values,
            labelBuilder: stepStudioCompletionModeLabel,
            enabled: _canEdit,
            onChanged: (mode) {
              _replaceSelectedStep(
                selectedStep.copyWith(
                  completion: StepStudioCompletionRule(mode: mode),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          if (completion.mode == StepStudioCompletionMode.whenCutsceneEnds)
            _SimpleDropdown(
              accent: EditorChrome.inspectorJoyBlue,
              fieldLabel: 'Cutscene de validation',
              options: cutsceneOptions,
              selectedId: completion.cutsceneId,
              emptyLabel: 'Aucune cutscene disponible',
              enabled: _canEdit && cutsceneOptions.isNotEmpty,
              onSelected: (id) {
                _replaceSelectedStep(
                  selectedStep.copyWith(
                    completion: completion.copyWith(cutsceneId: id),
                  ),
                );
              },
            ),
          if (completion.mode == StepStudioCompletionMode.whenOutcomeEmitted)
            _SimpleDropdown(
              accent: EditorChrome.inspectorJoyBlue,
              fieldLabel: 'Résultat attendu',
              options: outcomeOptions,
              selectedId: completion.outcomeId,
              emptyLabel: 'Aucun résultat disponible',
              enabled: _canEdit && outcomeOptions.isNotEmpty,
              onSelected: (id) {
                _replaceSelectedStep(
                  selectedStep.copyWith(
                    completion: completion.copyWith(outcomeId: id),
                  ),
                );
              },
            ),
          if (completion.mode == StepStudioCompletionMode.whenInteractionDone)
            Column(
              children: [
                _SimpleDropdown(
                  accent: EditorChrome.inspectorJoyBlue,
                  fieldLabel: 'Map d’interaction',
                  options: mapOptions,
                  selectedId: interactionRef.mapId,
                  emptyLabel: 'Aucune map',
                  enabled: _canEdit && mapOptions.isNotEmpty,
                  onSelected: (mapId) {
                    if (mapId == null) return;
                    unawaited(_ensureEntitiesLoadedForMap(mapId));
                    _replaceSelectedStep(
                      selectedStep.copyWith(
                        completion: completion.copyWith(
                          interactionId: _encodeInteractionRef(
                            mapId: mapId,
                            entityId: '',
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _SimpleDropdown(
                  accent: EditorChrome.inspectorJoyBlue,
                  fieldLabel: 'Entité d’interaction',
                  options: interactionEntityOptions,
                  selectedId: interactionRef.entityId,
                  emptyLabel: _isLoadingEntities
                      ? 'Chargement des entités...'
                      : 'Aucune entité sur cette map',
                  enabled: _canEdit &&
                      interactionRef.mapId != null &&
                      interactionEntityOptions.isNotEmpty,
                  onSelected: (entityId) {
                    final mapId = interactionRef.mapId;
                    if (mapId == null || entityId == null) return;
                    _replaceSelectedStep(
                      selectedStep.copyWith(
                        completion: completion.copyWith(
                          interactionId: _encodeInteractionRef(
                            mapId: mapId,
                            entityId: entityId,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          if (completion.mode == StepStudioCompletionMode.whenFlagTrue)
            _InlineTextField(
              label: 'État monde attendu',
              value: completion.flagName ?? '',
              enabled: _canEdit,
              onChanged: (value) {
                _replaceSelectedStep(
                  selectedStep.copyWith(
                    completion: completion.copyWith(flagName: value),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              summarizeStepCompletion(selectedStep),
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldPersistenceSection(
    BuildContext context,
    StepStudioStep selectedStep,
  ) {
    final worldChanges = selectedStep.worldChanges;
    final mapOptions = _projectMaps
        .map(
          (entry) => _SimpleOption(
            id: entry.id,
            label: '${entry.name} (${entry.id})',
          ),
        )
        .toList(growable: false);

    return _StepSectionCard(
      title: '6. Monde / persistance',
      subtitle:
          'Déclare les changements persistants de présence d’entités pilotés par la progression.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (worldChanges.isEmpty)
            const _EmptySectionHint(
              text:
                  'Aucun changement persistant. Exemple: Emma dehors invisible après la step, Emma labo visible.',
            ),
          // GARDE anti-boucle: même motif — `.asMap().entries` protège
          // contre l'oubli de `++` qui causait la boucle infinie build().
          for (final entry in worldChanges.asMap().entries)
            ...[
              _WorldChangeRow(
                change: entry.value,
                mapOptions: mapOptions,
                entityOptions: _entitiesForMap(worldChanges[entry.key].mapId)
                    .map((entity) => _SimpleOption(
                          id: entity.id,
                          label: _entityLabel(entity),
                        ))
                    .toList(growable: false),
                loadingEntities: _isLoadingEntities,
                enabled: _canEdit,
                onMapChanged: (mapId) {
                  if (mapId == null) return;
                  unawaited(_ensureEntitiesLoadedForMap(mapId));
                  final next = worldChanges.toList(growable: true);
                  next[entry.key] = next[entry.key].copyWith(
                    mapId: mapId,
                    entityId: '',
                  );
                  _replaceSelectedStep(
                      selectedStep.copyWith(worldChanges: next));
                },
                onEntityChanged: (entityId) {
                  if (entityId == null) return;
                  final next = worldChanges.toList(growable: true);
                  next[entry.key] = next[entry.key].copyWith(entityId: entityId);
                  _replaceSelectedStep(
                      selectedStep.copyWith(worldChanges: next));
                },
                onRuleChanged: (rule) {
                  final next = worldChanges.toList(growable: true);
                  next[entry.key] = next[entry.key].copyWith(presenceRule: rule);
                  _replaceSelectedStep(
                      selectedStep.copyWith(worldChanges: next));
                },
                onNoteChanged: (note) {
                  final next = worldChanges.toList(growable: true);
                  next[entry.key] = next[entry.key].copyWith(note: note);
                  _replaceSelectedStep(
                      selectedStep.copyWith(worldChanges: next));
                },
                onRemove: () {
                  final next = worldChanges.toList(growable: true)
                    ..removeAt(entry.key);
                  _replaceSelectedStep(
                      selectedStep.copyWith(worldChanges: next));
                },
              ),
              const SizedBox(height: 8),
            ],
          SizedBox(
            width: double.infinity,
            child: InspectorEmbeddedSecondaryCapsule(
              accent: EditorChrome.inspectorJoyCyan,
              icon: CupertinoIcons.plus_circle_fill,
              label: 'Ajouter un changement monde',
              enabled: _canEdit && mapOptions.isNotEmpty,
              onPressed: () {
                final defaultMapId = mapOptions.first.id;
                unawaited(_ensureEntitiesLoadedForMap(defaultMapId));
                final nextChange = StepStudioWorldChange(
                  mapId: defaultMapId,
                  entityId: '',
                  presenceRule:
                      StepStudioPresenceRule.visibleAfterStepCompletion,
                  note: '',
                );
                _replaceSelectedStep(
                  selectedStep.copyWith(
                    worldChanges: <StepStudioWorldChange>[
                      ...worldChanges,
                      nextChange,
                    ],
                  ),
                );
              },
            ),
          ),
          if (_entityLookupError != null) ...[
            const SizedBox(height: 8),
            _InlineInfoBanner(
              accent: EditorChrome.inspectorJoyCoral,
              text: _entityLookupError!,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepSectionCard extends StatelessWidget {
  const _StepSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.04),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.25),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InlineInfoBanner extends StatelessWidget {
  const _InlineInfoBanner({
    required this.accent,
    required this.text,
  });

  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: accent.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptySectionHint extends StatelessWidget {
  const _EmptySectionHint({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InlineTextField extends StatefulWidget {
  const _InlineTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final int minLines;
  final int maxLines;

  @override
  State<_InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<_InlineTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _InlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorEmbeddedSectionLabel(widget.label),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: _controller,
          enabled: widget.enabled,
          minLines: widget.minLines,
          maxLines: widget.maxLines,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          onChanged: widget.onChanged,
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          decoration: BoxDecoration(
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.3),
            ),
          ),
        ),
      ],
    );
  }
}

class _SimpleOption {
  const _SimpleOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class _SimpleDropdown extends StatelessWidget {
  const _SimpleDropdown({
    required this.accent,
    required this.fieldLabel,
    required this.options,
    required this.selectedId,
    required this.emptyLabel,
    required this.enabled,
    required this.onSelected,
  });

  final Color accent;
  final String fieldLabel;
  final List<_SimpleOption> options;
  final String? selectedId;
  final String emptyLabel;
  final bool enabled;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return InspectorEmbeddedDropdown(
        accent: accent,
        fieldLabel: fieldLabel,
        valueLabel: emptyLabel,
        orderedIds: const <String>[],
        selectedMenuValue: '',
        idToLabel: (_) => '',
        onSelected: (_) {},
      );
    }
    final selected = options.firstWhere(
      (entry) => entry.id == selectedId,
      orElse: () => options.first,
    );
    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.65,
        child: InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: fieldLabel,
          valueLabel: selected.label,
          orderedIds: options.map((entry) => entry.id).toList(growable: false),
          selectedMenuValue: selected.id,
          selectedIdForCheck: selected.id,
          idToLabel: (id) {
            for (final entry in options) {
              if (entry.id == id) {
                return entry.label;
              }
            }
            return id;
          },
          onSelected: (id) => onSelected(id),
        ),
      ),
    );
  }
}

class _EnumDropdown<T extends Enum> extends StatelessWidget {
  const _EnumDropdown({
    required this.accent,
    required this.fieldLabel,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.enabled,
    required this.onChanged,
  });

  final Color accent;
  final String fieldLabel;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final bool enabled;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SimpleDropdown(
      accent: accent,
      fieldLabel: fieldLabel,
      options: values
          .map(
            (entry) => _SimpleOption(
              id: entry.name,
              label: labelBuilder(entry),
            ),
          )
          .toList(growable: false),
      selectedId: value.name,
      emptyLabel: '—',
      enabled: enabled,
      onSelected: (id) {
        if (id == null) return;
        for (final entry in values) {
          if (entry.name == id) {
            onChanged(entry);
            return;
          }
        }
      },
    );
  }
}

class _CutsceneLinkRow extends StatelessWidget {
  const _CutsceneLinkRow({
    required this.link,
    required this.cutsceneOptions,
    required this.enabled,
    required this.onRoleChanged,
    required this.onCutsceneChanged,
    required this.onRemove,
  });

  final StepStudioCutsceneLink link;
  final List<_SimpleOption> cutsceneOptions;
  final bool enabled;
  final ValueChanged<StepStudioCutsceneRole> onRoleChanged;
  final ValueChanged<String?> onCutsceneChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          _EnumDropdown<StepStudioCutsceneRole>(
            accent: EditorChrome.inspectorJoyPlum,
            fieldLabel: 'Rôle',
            value: link.role,
            values: StepStudioCutsceneRole.values,
            labelBuilder: stepStudioCutsceneRoleLabel,
            enabled: enabled,
            onChanged: onRoleChanged,
          ),
          const SizedBox(height: 6),
          _SimpleDropdown(
            accent: EditorChrome.inspectorJoyPlum,
            fieldLabel: 'Cutscene',
            options: cutsceneOptions,
            selectedId: link.cutsceneId,
            emptyLabel: 'Aucune cutscene',
            enabled: enabled && cutsceneOptions.isNotEmpty,
            onSelected: onCutsceneChanged,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: InspectorEmbeddedSecondaryCapsule(
              accent: EditorChrome.inspectorJoyCoral,
              icon: CupertinoIcons.minus_circle,
              label: 'Retirer cette cutscene',
              enabled: enabled,
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutcomeRow extends StatelessWidget {
  const _OutcomeRow({
    required this.outcome,
    required this.enabled,
    required this.onLabelChanged,
    required this.onScopeChanged,
    required this.onTapOutcomeId,
    required this.onRemove,
  });

  final StepStudioOutcomeDefinition outcome;
  final bool enabled;
  final ValueChanged<String> onLabelChanged;
  final ValueChanged<StepStudioOutcomeScope> onScopeChanged;
  final VoidCallback onTapOutcomeId;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyOrchid.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyOrchid.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InlineTextField(
            label: 'Libellé humain',
            value: outcome.label,
            enabled: enabled,
            onChanged: onLabelChanged,
          ),
          const SizedBox(height: 6),
          _EnumDropdown<StepStudioOutcomeScope>(
            accent: EditorChrome.inspectorJoyOrchid,
            fieldLabel: 'Portée',
            value: outcome.scope,
            values: StepStudioOutcomeScope.values,
            labelBuilder: stepStudioOutcomeScopeLabel,
            enabled: enabled,
            onChanged: onScopeChanged,
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTapOutcomeId,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: EditorChrome.largeIslandSurfaceColor(
                  context,
                  tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID technique (généré automatiquement)',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    outcome.outcomeId,
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: InspectorEmbeddedSecondaryCapsule(
              accent: EditorChrome.inspectorJoyCoral,
              icon: CupertinoIcons.minus_circle,
              label: 'Retirer ce résultat',
              enabled: enabled,
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldChangeRow extends StatelessWidget {
  const _WorldChangeRow({
    required this.change,
    required this.mapOptions,
    required this.entityOptions,
    required this.loadingEntities,
    required this.enabled,
    required this.onMapChanged,
    required this.onEntityChanged,
    required this.onRuleChanged,
    required this.onNoteChanged,
    required this.onRemove,
  });

  final StepStudioWorldChange change;
  final List<_SimpleOption> mapOptions;
  final List<_SimpleOption> entityOptions;
  final bool loadingEntities;
  final bool enabled;
  final ValueChanged<String?> onMapChanged;
  final ValueChanged<String?> onEntityChanged;
  final ValueChanged<StepStudioPresenceRule> onRuleChanged;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SimpleDropdown(
            accent: EditorChrome.inspectorJoyCyan,
            fieldLabel: 'Map',
            options: mapOptions,
            selectedId: change.mapId,
            emptyLabel: 'Aucune map',
            enabled: enabled && mapOptions.isNotEmpty,
            onSelected: onMapChanged,
          ),
          const SizedBox(height: 6),
          _SimpleDropdown(
            accent: EditorChrome.inspectorJoyCyan,
            fieldLabel: 'Entité',
            options: entityOptions,
            selectedId: change.entityId,
            emptyLabel:
                loadingEntities ? 'Chargement des entités...' : 'Aucune entité',
            enabled: enabled && entityOptions.isNotEmpty,
            onSelected: onEntityChanged,
          ),
          const SizedBox(height: 6),
          _EnumDropdown<StepStudioPresenceRule>(
            accent: EditorChrome.inspectorJoyCyan,
            fieldLabel: 'Règle de présence',
            value: change.presenceRule,
            values: StepStudioPresenceRule.values,
            labelBuilder: stepStudioPresenceRuleLabel,
            enabled: enabled,
            onChanged: onRuleChanged,
          ),
          const SizedBox(height: 6),
          _InlineTextField(
            label: 'Note (optionnelle)',
            value: change.note ?? '',
            enabled: enabled,
            onChanged: onNoteChanged,
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: InspectorEmbeddedSecondaryCapsule(
              accent: EditorChrome.inspectorJoyCoral,
              icon: CupertinoIcons.minus_circle,
              label: 'Retirer ce changement',
              enabled: enabled,
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

@immutable
class _InteractionRef {
  const _InteractionRef({
    this.mapId,
    this.entityId,
  });

  final String? mapId;
  final String? entityId;
}
