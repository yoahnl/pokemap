import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../application/use_cases/project_scenario_use_cases.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/narrative/application/global_story_studio_authoring.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../features/narrative/application/step_studio_authoring.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

/// Callback typé pour le renommage d'un chapitre (id + nouveau nom).
///
/// Utilisé car [ValueChanged] de Flutter ne prend qu'un seul argument.
typedef _ChapterRenameCallback = void Function(String chapterId, String name);

/// Workspace central "Global Story Studio v1".
///
/// Rôle produit:
/// - visualiser et éditer la structure macro du jeu (un seul Global Story);
/// - garder Step Studio pour la logique locale des steps;
/// - garder Cutscene Studio pour l'exécution de scène.
///
/// Rôle technique:
/// - charger/éditer deux documents complémentaires:
///   1) [StepStudioDocument] (identité + ordre des steps),
///   2) [GlobalStoryStudioDocument] (liens macro entre steps).
class GlobalStoryStudioWorkspace extends StatefulWidget {
  const GlobalStoryStudioWorkspace({
    super.key,
    required this.editorNotifier,
    required this.project,
    required this.projection,
    required this.selectedGlobalStoryId,
    required this.selectedStepId,
    required this.onSelectGlobalStory,
    required this.onSelectStep,
    required this.onOpenStepStudio,
  });

  final EditorNotifier editorNotifier;
  final ProjectManifest? project;
  final NarrativeWorkspaceProjection projection;
  final String? selectedGlobalStoryId;
  final String? selectedStepId;
  final ValueChanged<String?> onSelectGlobalStory;
  final ValueChanged<String?> onSelectStep;
  final ValueChanged<String> onOpenStepStudio;

  @override
  State<GlobalStoryStudioWorkspace> createState() =>
      _GlobalStoryStudioWorkspaceState();
}

class _GlobalStoryStudioWorkspaceState
    extends State<GlobalStoryStudioWorkspace> {
  StepStudioDocument? _savedStepDocument;
  StepStudioDocument? _draftStepDocument;

  GlobalStoryStudioDocument? _savedGlobalDocument;
  GlobalStoryStudioDocument? _draftGlobalDocument;

  String? _loadedGlobalScenarioId;
  String? _selectedStepId;
  String? _selectedChapterId;
  bool _busy = false;
  
  // Ensemble des IDs des chapitres ouverts (fonctionnalité accordéon)
  final Set<String> _expandedChapters = <String>{};
  
  // Constantes pour le chapitre par défaut
  static const String _defaultChapterId = 'chapter_main';
  static const String _defaultChapterName = 'Histoire principale';

  List<String> _loadWarnings = const <String>[];
  bool _usedStepLegacyFallback = false;
  bool _usedGlobalLegacyFallback = false;

  // ---------------------------------------------------------------------------
  // Synchronisation provider-safe (meme pattern que Step Studio):
  // - aucune mutation provider pendant build/initState;
  // - dispatch des selections uniquement apres frame.
  // ---------------------------------------------------------------------------
  String? _lastDispatchedGlobalSelection;
  String? _queuedGlobalSelection;
  bool _globalDispatchScheduled = false;

  String? _lastDispatchedStepSelection;
  String? _queuedStepSelection;
  bool _stepDispatchScheduled = false;

  @override
  void initState() {
    super.initState();
    _hydrateFromProject();
  }

  @override
  void didUpdateWidget(covariant GlobalStoryStudioWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    final projectChanged = oldWidget.project != widget.project;
    final projectionChanged = oldWidget.projection != widget.projection;
    final selectedGlobalChanged =
        oldWidget.selectedGlobalStoryId != widget.selectedGlobalStoryId;
    final selectedStepChanged =
        oldWidget.selectedStepId != widget.selectedStepId;

    if (projectChanged || projectionChanged || selectedGlobalChanged) {
      _hydrateFromProject();
      return;
    }

    if (selectedStepChanged) {
      final requestedStepId = widget.selectedStepId;
      if (requestedStepId != null && _containsStep(requestedStepId)) {
        setState(() {
          _selectedStepId = requestedStepId;
        });
      }
    }
  }

  void _hydrateFromProject() {
    final project = widget.project;
    if (project == null) {
      setState(() {
        _savedStepDocument = null;
        _draftStepDocument = null;
        _savedGlobalDocument = null;
        _draftGlobalDocument = null;
        _loadedGlobalScenarioId = null;
        _selectedStepId = null;
        _loadWarnings = const <String>[];
        _usedStepLegacyFallback = false;
        _usedGlobalLegacyFallback = false;
        _busy = false;
      });
      _dispatchGlobalSelectionAfterFrame(null);
      _dispatchStepSelectionAfterFrame(null);
      return;
    }

    final globalStories = project.scenarios
        .where((scenario) => scenario.scope == ScenarioScope.globalStory)
        .toList(growable: false);
    if (globalStories.isEmpty) {
      setState(() {
        _savedStepDocument = null;
        _draftStepDocument = null;
        _savedGlobalDocument = null;
        _draftGlobalDocument = null;
        _loadedGlobalScenarioId = null;
        _selectedStepId = null;
        _loadWarnings = const <String>[];
        _usedStepLegacyFallback = false;
        _usedGlobalLegacyFallback = false;
      });
      _dispatchGlobalSelectionAfterFrame(null);
      _dispatchStepSelectionAfterFrame(null);
      return;
    }

    final primaryGlobal = globalStories.first;
    final stepParse = parseStepStudioDocumentFromGlobalScenario(primaryGlobal);
    final globalParse = parseGlobalStoryStudioDocumentFromGlobalScenario(
      primaryGlobal,
      stepDocument: stepParse.document,
    );

    final mergedWarnings = <String>[
      ...stepParse.warnings,
      ...globalParse.warnings,
    ];

    final resolvedSelection = _resolveInitialStepSelection(
      stepDocument: stepParse.document,
      globalDocument: globalParse.document,
      preferredStepId: widget.selectedStepId,
      fallbackStepId: _selectedStepId,
    );

    setState(() {
      _savedStepDocument = stepParse.document;
      _draftStepDocument = stepParse.document;
      _savedGlobalDocument = globalParse.document;
      _draftGlobalDocument = globalParse.document;
      _loadedGlobalScenarioId = primaryGlobal.id;
      _selectedStepId = resolvedSelection;
      _loadWarnings = mergedWarnings;
      _usedStepLegacyFallback = stepParse.usedLegacyFallback;
      _usedGlobalLegacyFallback = globalParse.usedLegacyFallback;
      _busy = false;
    });

    _dispatchGlobalSelectionAfterFrame(primaryGlobal.id);
    _dispatchStepSelectionAfterFrame(resolvedSelection);
  }

  void _dispatchGlobalSelectionAfterFrame(String? scenarioId) {
    _queuedGlobalSelection = scenarioId;
    if (_globalDispatchScheduled) {
      return;
    }
    _globalDispatchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _globalDispatchScheduled = false;
      if (!mounted) {
        return;
      }
      final next = _queuedGlobalSelection;
      _queuedGlobalSelection = null;
      if (next == _lastDispatchedGlobalSelection) {
        return;
      }
      _lastDispatchedGlobalSelection = next;
      widget.onSelectGlobalStory(next);
    });
  }

  void _dispatchStepSelectionAfterFrame(String? stepId) {
    _queuedStepSelection = stepId;
    if (_stepDispatchScheduled) {
      return;
    }
    _stepDispatchScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _stepDispatchScheduled = false;
      if (!mounted) {
        return;
      }
      final next = _queuedStepSelection;
      _queuedStepSelection = null;
      if (next == _lastDispatchedStepSelection) {
        return;
      }
      _lastDispatchedStepSelection = next;
      widget.onSelectStep(next);
    });
  }

  String? _resolveInitialStepSelection({
    required StepStudioDocument stepDocument,
    required GlobalStoryStudioDocument globalDocument,
    String? preferredStepId,
    String? fallbackStepId,
  }) {
    if (stepDocument.steps.isEmpty) {
      return null;
    }
    final stepIds = stepDocument.steps.map((entry) => entry.id).toSet();
    if (preferredStepId != null && stepIds.contains(preferredStepId)) {
      return preferredStepId;
    }
    if (fallbackStepId != null && stepIds.contains(fallbackStepId)) {
      return fallbackStepId;
    }
    if (stepIds.contains(globalDocument.entryStepId)) {
      return globalDocument.entryStepId;
    }
    return stepDocument.steps.first.id;
  }

  bool _containsStep(String stepId) {
    final stepDoc = _draftStepDocument;
    if (stepDoc == null) {
      return false;
    }
    return stepDoc.steps.any((entry) => entry.id == stepId);
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

  StepStudioStep? _stepById(String? stepId) {
    final stepDoc = _draftStepDocument;
    if (stepDoc == null || stepId == null) {
      return null;
    }
    for (final step in stepDoc.steps) {
      if (step.id == stepId) {
        return step;
      }
    }
    return null;
  }

  GlobalStoryStepNode? _nodeByStepId(String? stepId) {
    final globalDoc = _draftGlobalDocument;
    if (globalDoc == null || stepId == null) {
      return null;
    }
    for (final node in globalDoc.nodes) {
      if (node.stepId == stepId) {
        return node;
      }
    }
    return null;
  }

  bool get _canEdit =>
      !_busy &&
      _draftStepDocument != null &&
      _draftGlobalDocument != null &&
      _loadedGlobalScenarioId != null;

  bool get _hasUnsavedChanges =>
      _savedStepDocument != null &&
      _draftStepDocument != null &&
      _savedGlobalDocument != null &&
      _draftGlobalDocument != null &&
      (_savedStepDocument != _draftStepDocument ||
          _savedGlobalDocument != _draftGlobalDocument);

  /// Réconcilie les documents Step Studio et Global Story Studio pour garantir
  /// la cohérence entre steps, nodes et chapitres.
  ///
  /// Invariants garantis :
  /// - chaque step existante a un node correspondant
  /// - chaque step est assignée à exactement un chapitre
  /// - aucune step orpheline (non assignée)
  /// - entryStepId est valide
  /// - les ordres sont cohérents
  /// - pas de duplications ou incohérences
  GlobalStoryStudioDocument _reconcileGlobalStoryDocument({
    required StepStudioDocument stepDocument,
    required GlobalStoryStudioDocument globalDocument,
  }) {
    // Créer un ensemble de tous les step IDs du Step Studio
    final stepIds = stepDocument.steps.map((step) => step.id).toSet();
    
    // Normaliser les nodes - s'assurer que chaque step a un node
    final nodeMap = <String, GlobalStoryStepNode>{};
    for (final node in globalDocument.nodes) {
      if (stepIds.contains(node.stepId)) {
        nodeMap[node.stepId] = node;
      }
    }
    
    // Ajouter des nodes pour les steps sans node
    for (final step in stepDocument.steps) {
      if (!nodeMap.containsKey(step.id)) {
        nodeMap[step.id] = GlobalStoryStepNode(
          stepId: step.id,
          exitMode: GlobalStoryStepExitMode.linear,
          links: const [],
        );
      }
    }
    
    // Normaliser les chapitres - s'assurer que chaque step est dans un chapitre
    final allAssignedStepIds = <String>{};
    final normalizedChapters = <GlobalStoryChapter>[];
    
    for (final chapter in globalDocument.chapters) {
      final validStepIds = chapter.stepIds
          .where((id) => stepIds.contains(id) && !allAssignedStepIds.contains(id))
          .toList();
      
      // Marquer les steps assignées
      allAssignedStepIds.addAll(validStepIds);
      
      normalizedChapters.add(chapter.copyWith(stepIds: validStepIds));
    }
    
    // Trouver les steps non assignées
    final unassignedStepIds = stepIds
        .where((id) => !allAssignedStepIds.contains(id))
        .toList();
    
    // Si des steps sont non assignées, les ajouter à un chapitre par défaut
    if (unassignedStepIds.isNotEmpty) {
      // Trouver ou créer le chapitre par défaut
      final defaultChapterIndex = normalizedChapters.indexWhere(
        (c) => c.id == _defaultChapterId,
      );
      
      if (defaultChapterIndex >= 0) {
        // Ajouter les steps non assignées au chapitre par défaut
        final existingChapter = normalizedChapters[defaultChapterIndex];
        normalizedChapters[defaultChapterIndex] = existingChapter.copyWith(
          stepIds: [...existingChapter.stepIds, ...unassignedStepIds],
        );
      } else {
        // Créer un nouveau chapitre par défaut
        normalizedChapters.add(GlobalStoryChapter(
          id: _defaultChapterId,
          name: _defaultChapterName,
          description: 'Chapitre par défaut pour les steps non assignées',
          stepIds: unassignedStepIds,
          order: normalizedChapters.length,
        ));
      }
    }
    
    // S'assurer que l'entryStepId est valide
    final entryStepId = stepIds.contains(globalDocument.entryStepId)
        ? globalDocument.entryStepId
        : (stepDocument.steps.isNotEmpty ? stepDocument.steps.first.id : '');
    
    // Retourner le document réconcilié
    return globalDocument.copyWith(
      entryStepId: entryStepId,
      nodes: nodeMap.values.toList(),
      chapters: normalizedChapters,
    );
  }

  /// Méthode de remplacement des documents avec réconciliation garantie
  /// pour assurer la cohérence entre Step Studio et Global Story Studio.
  void _replaceDraftDocuments({
    required StepStudioDocument nextStepDocument,
    required GlobalStoryStudioDocument nextGlobalDocument,
  }) {
    // Appliquer la réconciliation pour garantir la cohérence complète
    final reconciledGlobal = _reconcileGlobalStoryDocument(
      stepDocument: nextStepDocument,
      globalDocument: nextGlobalDocument,
    );
    
    if (_draftStepDocument == nextStepDocument &&
        _draftGlobalDocument == reconciledGlobal) {
      return;
    }
    
    setState(() {
      _draftStepDocument = nextStepDocument;
      _draftGlobalDocument = reconciledGlobal;
    });
  }

  void _selectStep(String? stepId) {
    if (_selectedStepId == stepId) {
      return;
    }
    setState(() {
      _selectedStepId = stepId;
    });
    _lastDispatchedStepSelection = stepId;
    widget.onSelectStep(stepId);
  }

  /// Bascule l'état d'expansion d'un chapitre (accordéon).
  void _toggleChapterExpansion(String chapterId) {
    setState(() {
      if (_expandedChapters.contains(chapterId)) {
        _expandedChapters.remove(chapterId);
      } else {
        _expandedChapters.add(chapterId);
      }
    });
  }

  Future<void> _createGlobalStoryAndBootstrap() async {
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
      description: 'Colonne vertebrale narrative du jeu.',
      scope: ScenarioScope.globalStory,
      entryNodeId: 'start',
      nodes: const <ScenarioNode>[
        ScenarioNode(id: 'start', type: ScenarioNodeType.start, title: 'Start'),
        ScenarioNode(id: 'end', type: ScenarioNodeType.end, title: 'End'),
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

    final stepDocument = createDefaultStepStudioDocument(
      globalStoryScenarioId: scenarioId,
    );
    final globalDocument = createDefaultGlobalStoryStudioDocument(
      globalStoryScenarioId: scenarioId,
      stepDocument: stepDocument,
    );
    scenario = applyStepStudioDocumentToGlobalScenario(scenario, stepDocument);
    scenario = applyGlobalStoryStudioDocumentToGlobalScenario(
      scenario,
      globalDocument,
      stepDocument: stepDocument,
    );

    await widget.editorNotifier.createProjectScenario(scenario);
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
    });
  }

  void _addStepAfterSelection() {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    if (stepDoc == null || globalDoc == null) {
      return;
    }

    final ordered = stepDoc.steps.toList(growable: true)
      ..sort((a, b) => a.order.compareTo(b.order));
    final selectedId = _selectedStepId;
    final selectedIndex = selectedId == null
        ? ordered.length - 1
        : ordered.indexWhere((entry) => entry.id == selectedId);
    final insertionIndex =
        selectedIndex < 0 ? ordered.length : selectedIndex + 1;

    final nextStepId = generateUniqueStepId(
      'step_${ordered.length + 1}',
      existingIds: ordered.map((entry) => entry.id),
    );
    final newStep = StepStudioStep(
      id: nextStepId,
      name: 'Nouvelle step ${ordered.length + 1}',
      description: '',
      order: insertionIndex,
      activation: insertionIndex == 0
          ? const StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            )
          : const StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
      completion: const StepStudioCompletionRule(
        mode: StepStudioCompletionMode.manual,
      ),
    );

    ordered.insert(insertionIndex, newStep);
    final normalizedSteps = <StepStudioStep>[];
    for (var index = 0; index < ordered.length; index++) {
      normalizedSteps.add(ordered[index].copyWith(order: index));
    }
    final nextStepDocument = stepDoc.copyWith(steps: normalizedSteps);

    final nodeByStepId = <String, GlobalStoryStepNode>{
      for (final node in globalDoc.nodes) node.stepId: node,
    };
    final selectedNode = selectedId == null ? null : nodeByStepId[selectedId];
    final createdNode = const GlobalStoryStepNode(
      stepId: '',
      exitMode: GlobalStoryStepExitMode.linear,
      links: <GlobalStoryStepLink>[],
    ).copyWith(stepId: nextStepId);
    nodeByStepId[nextStepId] = createdNode;

    if (selectedNode != null) {
      if (selectedNode.exitMode == GlobalStoryStepExitMode.linear) {
        final previousLinks = selectedNode.links;
        nodeByStepId[selectedNode.stepId] = selectedNode.copyWith(
          links: <GlobalStoryStepLink>[
            GlobalStoryStepLink(toStepId: nextStepId),
          ],
        );
        nodeByStepId[nextStepId] = createdNode.copyWith(links: previousLinks);
      } else if (selectedNode.links.isEmpty) {
        nodeByStepId[selectedNode.stepId] = selectedNode.copyWith(
          links: <GlobalStoryStepLink>[
            GlobalStoryStepLink(toStepId: nextStepId),
          ],
        );
      }
    }

    final nextGlobalDocument = globalDoc.copyWith(
      nodes: normalizedSteps
          .map(
            (step) =>
                nodeByStepId[step.id] ?? GlobalStoryStepNode(stepId: step.id),
          )
          .toList(growable: false),
    );

    _replaceDraftDocuments(
      nextStepDocument: nextStepDocument,
      nextGlobalDocument: nextGlobalDocument,
    );
    _selectStep(nextStepId);
  }

  void _deleteSelectedStep() {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    final selectedStep = _stepById(_selectedStepId);
    if (stepDoc == null ||
        globalDoc == null ||
        selectedStep == null ||
        stepDoc.steps.length <= 1) {
      return;
    }

    final nextSteps = stepDoc.steps
        .where((step) => step.id != selectedStep.id)
        .toList(growable: false);
    final normalizedSteps = <StepStudioStep>[];
    for (var index = 0; index < nextSteps.length; index++) {
      normalizedSteps.add(nextSteps[index].copyWith(order: index));
    }
    final nextStepDocument = stepDoc.copyWith(steps: normalizedSteps);

    final nextNodes = globalDoc.nodes
        .where((node) => node.stepId != selectedStep.id)
        .map(
          (node) => node.copyWith(
            links: node.links
                .where((link) => link.toStepId != selectedStep.id)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);

    final nextEntryStepId = globalDoc.entryStepId == selectedStep.id
        ? normalizedSteps.first.id
        : globalDoc.entryStepId;

    final nextGlobalDocument = globalDoc.copyWith(
      entryStepId: nextEntryStepId,
      nodes: nextNodes,
    );

    _replaceDraftDocuments(
      nextStepDocument: nextStepDocument,
      nextGlobalDocument: nextGlobalDocument,
    );
    _selectStep(normalizedSteps.first.id);
  }

  void _moveSelectedStep(int delta) {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    final selectedStep = _stepById(_selectedStepId);
    if (stepDoc == null || globalDoc == null || selectedStep == null) {
      return;
    }

    final ordered = stepDoc.steps.toList(growable: true)
      ..sort((a, b) => a.order.compareTo(b.order));
    final currentIndex =
        ordered.indexWhere((entry) => entry.id == selectedStep.id);
    if (currentIndex < 0) {
      return;
    }
    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= ordered.length) {
      return;
    }

    final moving = ordered.removeAt(currentIndex);
    ordered.insert(nextIndex, moving);
    final normalized = <StepStudioStep>[];
    for (var index = 0; index < ordered.length; index++) {
      normalized.add(ordered[index].copyWith(order: index));
    }
    _replaceDraftDocuments(
      nextStepDocument: stepDoc.copyWith(steps: normalized),
      nextGlobalDocument: globalDoc,
    );
  }

  void _updateSelectedStepIdentity({
    String? name,
    String? description,
  }) {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    final selectedStep = _stepById(_selectedStepId);
    if (stepDoc == null || globalDoc == null || selectedStep == null) {
      return;
    }

    final nextSteps = stepDoc.steps
        .map(
          (step) => step.id == selectedStep.id
              ? step.copyWith(
                  name: name ?? step.name,
                  description: description ?? step.description,
                )
              : step,
        )
        .toList(growable: false);
    _replaceDraftDocuments(
      nextStepDocument: stepDoc.copyWith(steps: nextSteps),
      nextGlobalDocument: globalDoc,
    );
  }

  void _setEntryStep(String stepId) {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    if (stepDoc == null || globalDoc == null) {
      return;
    }
    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(entryStepId: stepId),
    );
    _selectStep(stepId);
  }

  void _updateSelectedNodeExitMode(GlobalStoryStepExitMode exitMode) {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    final selectedNode = _nodeByStepId(_selectedStepId);
    if (stepDoc == null || globalDoc == null || selectedNode == null) {
      return;
    }
    final nextLinks = (exitMode == GlobalStoryStepExitMode.linear ||
            exitMode == GlobalStoryStepExitMode.converge)
        ? (selectedNode.links.isEmpty
            ? const <GlobalStoryStepLink>[]
            : <GlobalStoryStepLink>[selectedNode.links.first])
        : selectedNode.links;

    final nextNodes = globalDoc.nodes
        .map(
          (node) => node.stepId == selectedNode.stepId
              ? node.copyWith(exitMode: exitMode, links: nextLinks)
              : node,
        )
        .toList(growable: false);
    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(nodes: nextNodes),
    );
  }

  void _addLinkFromSelectedStep() {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    final selectedNode = _nodeByStepId(_selectedStepId);
    if (stepDoc == null || globalDoc == null || selectedNode == null) {
      return;
    }
    final availableTargets = stepDoc.steps
        .map((entry) => entry.id)
        .where((id) => id != selectedNode.stepId)
        .where((id) => !selectedNode.links.any((link) => link.toStepId == id))
        .toList(growable: false);
    if (availableTargets.isEmpty) {
      return;
    }
    final nextLinks = <GlobalStoryStepLink>[
      ...selectedNode.links,
      GlobalStoryStepLink(toStepId: availableTargets.first),
    ];
    final nextNodes = globalDoc.nodes
        .map(
          (node) => node.stepId == selectedNode.stepId
              ? node.copyWith(links: nextLinks)
              : node,
        )
        .toList(growable: false);
    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(nodes: nextNodes),
    );
  }

  void _removeLinkFromSelectedStep(int linkIndex) {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    final selectedNode = _nodeByStepId(_selectedStepId);
    if (stepDoc == null || globalDoc == null || selectedNode == null) {
      return;
    }
    if (linkIndex < 0 || linkIndex >= selectedNode.links.length) {
      return;
    }
    final nextLinks = selectedNode.links.toList(growable: true)
      ..removeAt(linkIndex);
    final nextNodes = globalDoc.nodes
        .map(
          (node) => node.stepId == selectedNode.stepId
              ? node.copyWith(links: nextLinks)
              : node,
        )
        .toList(growable: false);
    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(nodes: nextNodes),
    );
  }

  void _updateLinkFromSelectedStep({
    required int linkIndex,
    String? toStepId,
    Object? conditionLabel = _unset,
    Object? requiredOutcomeId = _unset,
  }) {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    final selectedNode = _nodeByStepId(_selectedStepId);
    if (stepDoc == null || globalDoc == null || selectedNode == null) {
      return;
    }
    if (linkIndex < 0 || linkIndex >= selectedNode.links.length) {
      return;
    }
    final nextLinks = selectedNode.links.toList(growable: true);
    nextLinks[linkIndex] = nextLinks[linkIndex].copyWith(
      toStepId: toStepId,
      conditionLabel: conditionLabel,
      requiredOutcomeId: requiredOutcomeId,
    );
    final nextNodes = globalDoc.nodes
        .map(
          (node) => node.stepId == selectedNode.stepId
              ? node.copyWith(links: nextLinks)
              : node,
        )
        .toList(growable: false);
    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(nodes: nextNodes),
    );
  }

  Future<void> _saveDraft() async {
    final scenario = _selectedGlobalScenario;
    final draftStep = _draftStepDocument;
    final draftGlobal = _draftGlobalDocument;
    if (scenario == null || draftStep == null || draftGlobal == null) {
      return;
    }

    setState(() {
      _busy = true;
    });

    // Etape 1: normalisation officielle du Step document via pipeline existante.
    final withStepDocument =
        applyStepStudioDocumentToGlobalScenario(scenario, draftStep);
    final normalizedStepParse =
        parseStepStudioDocumentFromGlobalScenario(withStepDocument);
    final normalizedStepDocument = normalizedStepParse.document;

    // Etape 2: normalisation du document macro en fonction des steps
    // (important pour garder un lien structure <-> identité parfaitement sync).
    final normalizedGlobalDocument = normalizeGlobalStoryStudioDocument(
      document: draftGlobal,
      stepDocument: normalizedStepDocument,
    );

    // Etape 3: écriture finale scenario metadata.
    final finalScenario = applyGlobalStoryStudioDocumentToGlobalScenario(
      withStepDocument,
      normalizedGlobalDocument,
      stepDocument: normalizedStepDocument,
    );
    await widget.editorNotifier.updateProjectScenario(
      scenarioId: scenario.id,
      scenario: finalScenario,
    );

    if (!mounted) {
      return;
    }

    final diagnostics = computeGlobalStoryStudioDiagnostics(
      document: normalizedGlobalDocument,
      stepDocument: normalizedStepDocument,
      existingWarnings: <String>[
        ...normalizedStepParse.warnings,
      ],
    );

    setState(() {
      _savedStepDocument = normalizedStepDocument;
      _draftStepDocument = normalizedStepDocument;
      _savedGlobalDocument = normalizedGlobalDocument;
      _draftGlobalDocument = normalizedGlobalDocument;
      _loadWarnings = diagnostics;
      _usedStepLegacyFallback = false;
      _usedGlobalLegacyFallback = false;
      _busy = false;
    });
  }

  void _resetDraft() {
    final savedStep = _savedStepDocument;
    final savedGlobal = _savedGlobalDocument;
    if (savedStep == null || savedGlobal == null) {
      return;
    }
    final selectedStep = _resolveInitialStepSelection(
      stepDocument: savedStep,
      globalDocument: savedGlobal,
      preferredStepId: _selectedStepId,
      fallbackStepId: savedGlobal.entryStepId,
    );
    setState(() {
      _draftStepDocument = savedStep;
      _draftGlobalDocument = savedGlobal;
      _selectedStepId = selectedStep;
    });
    _lastDispatchedStepSelection = selectedStep;
    widget.onSelectStep(selectedStep);
  }

  // ===========================================================================
  // GESTION DES CHAPITRES (nouveau concept v1.1)
  // ===========================================================================
  //
  // Ces méthodes permettent de gérer les chapitres / arcs narratifs dans
  // le Global Story Studio. Elles modifient UNIQUEMENT le document macro
  // (GlobalStoryStudioDocument), pas le Step Studio document.

  /// Sélectionne un chapitre pour mise en surbrillance dans l'UI.
  /// C'est une sélection purement visuelle — pas de mutation provider.
  void _selectChapter(String chapterId) {
    setState(() {
      _selectedChapterId = chapterId;
    });
  }

  /// État pour le sélecteur de step existante à insérer.
  ///
  /// Quand non null, le sélecteur de step existante est affiché sous forme
  /// d'un popup intégré au-dessus de la step concernée.

  /// Renomme un chapitre existant.
  void _renameChapter(String chapterId, String newName) {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    if (globalDoc == null || stepDoc == null) return;

    final nextChapters = globalDoc.chapters
        .map((chapter) =>
            chapter.id == chapterId ? chapter.copyWith(name: newName) : chapter)
        .toList(growable: false);
    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(chapters: nextChapters),
    );
  }

  /// Déplace un chapitre vers le haut ou le bas (change son ordre).
  void _moveChapter(int delta) {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    final selectedId = _selectedChapterId;
    if (globalDoc == null || stepDoc == null || selectedId == null) return;

    final ordered = globalDoc.chapters.toList(growable: true)
      ..sort((a, b) => a.order.compareTo(b.order));
    final currentIndex = ordered.indexWhere((c) => c.id == selectedId);
    if (currentIndex < 0) return;
    final nextIndex = currentIndex + delta;
    if (nextIndex < 0 || nextIndex >= ordered.length) return;

    // Échange les orders.
    final tempOrder = ordered[nextIndex].order;
    ordered[nextIndex] = ordered[nextIndex].copyWith(order: ordered[currentIndex].order);
    ordered[currentIndex] = ordered[currentIndex].copyWith(order: tempOrder);

    // Re-trie et re-normalize les orders.
    ordered.sort((a, b) => a.order.compareTo(b.order));
    final normalized = ordered
        .asMap()
        .entries
        .map((e) => e.value.copyWith(order: e.key))
        .toList(growable: false);

    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(chapters: normalized),
    );
  }

  /// Ajoute un nouveau chapitre vide après le dernier existant.
  void _addChapter() {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    if (globalDoc == null || stepDoc == null) return;

    final ordered = globalDoc.chapters.toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
    final nextOrder = ordered.isEmpty ? 0 : ordered.last.order + 1;
    final chapterCount = ordered.length + 1;

    final newChapter = GlobalStoryChapter(
      id: 'chapter_${chapterCount}',
      name: 'Nouveau chapitre $chapterCount',
      description: '',
      stepIds: const <String>[],
      order: nextOrder,
    );

    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(
        chapters: <GlobalStoryChapter>[...ordered, newChapter],
      ),
    );
    _selectChapter(newChapter.id);
  }

  /// Supprime un chapitre vide. On ne supprime PAS un chapitre contenant des steps.
  void _deleteChapter(String chapterId) {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    if (globalDoc == null || stepDoc == null) return;

    final chapter =
        globalDoc.chapters.where((c) => c.id == chapterId).cast<GlobalStoryChapter?>().firstWhere((c) => c != null, orElse: () => null);
    if (chapter == null) return;
    // On ne supprime que les chapitres vides ou le dernier chapitre.
    // Les steps doivent être déplacées ailleurs avant de supprimer un chapitre non vide.
    if (chapter.stepIds.isNotEmpty) return;

    final nextChapters = globalDoc.chapters
        .where((c) => c.id != chapterId)
        .toList(growable: false);
    // Re-normalize les orders.
    final ordered = nextChapters.toList(growable: true)
      ..sort((a, b) => a.order.compareTo(b.order));
    final normalized = ordered
        .asMap()
        .entries
        .map((e) => e.value.copyWith(order: e.key))
        .toList(growable: false);

    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(chapters: normalized),
    );
    if (_selectedChapterId == chapterId) {
      _selectedChapterId = null;
    }
  }

  /// Met à jour le lien d'une step (raccourci pour le callback du UI compact).
  void _updateLinkFromSelectedStepToStep(int linkIndex, String? toStepId) {
    _updateLinkFromSelectedStep(
      linkIndex: linkIndex,
      toStepId: toStepId,
    );
  }

  // ===========================================================================
  // CRÉATION / INSERTION DE STEPS (séparation explicite)
  // ===========================================================================
  //
  // Le bouton "Insérer" de l'ancienne UX faisait DEUX choses à la fois:
  // 1) créer une nouvelle step
  // 2) l'insérer dans le flux
  //
  // C'était trompeur: le texte disait "Insérer" mais le code faisait "Créer".
  //
  // Maintenant on sépare explicitement:
  // - _createNewStepAfter : crée une NOUVELLE step après une step donnée
  // - _insertExistingStepAfter : insère une step EXISTANTE après une step donnée
  //   (pas de création, pas de duplication)

  /// Crée une NOUVELLE step après la step spécifiée.
  ///
  /// C'est l'action "Créer une nouvelle step" — elle crée une step vierge
  /// et l'insère dans le flux global après `afterStepId`.
  void _createNewStepAfter(String afterStepId) {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    if (stepDoc == null || globalDoc == null) return;

    final ordered = stepDoc.steps.toList(growable: true)
      ..sort((a, b) => a.order.compareTo(b.order));
    final selectedIndex =
        ordered.indexWhere((entry) => entry.id == afterStepId);
    final insertionIndex =
        selectedIndex < 0 ? ordered.length : selectedIndex + 1;

    final nextStepId = generateUniqueStepId(
      'step_${ordered.length + 1}',
      existingIds: ordered.map((entry) => entry.id),
    );
    final newStep = StepStudioStep(
      id: nextStepId,
      name: 'Nouvelle step ${ordered.length + 1}',
      description: '',
      order: insertionIndex,
      activation: insertionIndex == 0
          ? const StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            )
          : const StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
      completion: const StepStudioCompletionRule(
        mode: StepStudioCompletionMode.manual,
      ),
    );

    ordered.insert(insertionIndex, newStep);
    final normalizedSteps = <StepStudioStep>[];
    for (var index = 0; index < ordered.length; index++) {
      normalizedSteps.add(ordered[index].copyWith(order: index));
    }
    final nextStepDocument = stepDoc.copyWith(steps: normalizedSteps);

    // Mise à jour des noeuds macro (flux global).
    final nodeByStepId = <String, GlobalStoryStepNode>{
      for (final node in globalDoc.nodes) node.stepId: node,
    };
    final selectedNode = nodeByStepId[afterStepId];
    final createdNode = const GlobalStoryStepNode(
      stepId: '',
      exitMode: GlobalStoryStepExitMode.linear,
      links: <GlobalStoryStepLink>[],
    ).copyWith(stepId: nextStepId);
    nodeByStepId[nextStepId] = createdNode;

    if (selectedNode != null) {
      if (selectedNode.exitMode == GlobalStoryStepExitMode.linear) {
        final previousLinks = selectedNode.links;
        nodeByStepId[selectedNode.stepId] = selectedNode.copyWith(
          links: <GlobalStoryStepLink>[
            GlobalStoryStepLink(toStepId: nextStepId),
          ],
        );
        nodeByStepId[nextStepId] = createdNode.copyWith(links: previousLinks);
      } else if (selectedNode.links.isEmpty) {
        nodeByStepId[selectedNode.stepId] = selectedNode.copyWith(
          links: <GlobalStoryStepLink>[
            GlobalStoryStepLink(toStepId: nextStepId),
          ],
        );
      }
    }

    final nextGlobalDocument = globalDoc.copyWith(
      nodes: normalizedSteps
          .map(
            (step) =>
                nodeByStepId[step.id] ?? GlobalStoryStepNode(stepId: step.id),
          )
          .toList(growable: false),
    );

    _replaceDraftDocuments(
      nextStepDocument: nextStepDocument,
      nextGlobalDocument: nextGlobalDocument,
    );

    // Ajout de la nouvelle step au chapitre de la step source.
    _addStepToChapterOfStep(afterStepId, nextStepId);

    _selectStep(nextStepId);
  }

  /// Insère une step EXISTANTE après la step spécifiée dans le flux global.
  ///
  /// Cette méthode NE CRÉE PAS de nouvelle step.
  /// Elle prend une step existante (`existingStepId`) et la repositionne
  /// dans le flux global après `afterStepId`.
  ///
  /// Comportement précis:
  /// - la step existante est retirée de sa position actuelle (ordre + chapitre)
  /// - elle est réinsérée après `afterStepId`
  /// - les ordres sont re-normalisés
  /// - les liens globaux sont mis à jour
  /// - la step reste unique (pas de duplication)
  void _insertExistingStepAfter(String afterStepId, String existingStepId) {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    if (stepDoc == null || globalDoc == null) return;
    // Garde de sécurité: on n'insère pas une step après elle-même.
    if (afterStepId == existingStepId) return;

    final ordered = stepDoc.steps.toList(growable: true)
      ..sort((a, b) => a.order.compareTo(b.order));

    // Vérifier que les deux steps existent.
    final afterIndex = ordered.indexWhere((s) => s.id == afterStepId);
    final existingIndex = ordered.indexWhere((s) => s.id == existingStepId);
    if (afterIndex < 0 || existingIndex < 0) return;

    // Retirer la step existante de sa position actuelle.
    final existingStep = ordered.removeAt(existingIndex);

    // Recalculer l'index d'insertion (peut avoir changé après le remove).
    final newAfterIndex =
        ordered.indexWhere((s) => s.id == afterStepId);
    final insertionIndex =
        newAfterIndex < 0 ? ordered.length : newAfterIndex + 1;

    // Insérer la step existante après la step cible.
    ordered.insert(insertionIndex, existingStep);

    // Re-normaliser les ordres.
    final normalizedSteps = <StepStudioStep>[];
    for (var index = 0; index < ordered.length; index++) {
      normalizedSteps.add(ordered[index].copyWith(order: index));
    }

    final nextStepDocument = stepDoc.copyWith(steps: normalizedSteps);

    // --- Mise à jour des noeuds macro (flux global) ---
    final nodeByStepId = <String, GlobalStoryStepNode>{
      for (final node in globalDoc.nodes) node.stepId: node,
    };

    final afterNode = nodeByStepId[afterStepId];
    final existingNode = nodeByStepId[existingStepId];

    if (afterNode != null && existingNode != null) {
      // La step existante prend les liens de la step source (en mode linéaire)
      // ou s'ajoute comme nouvelle destination.
      if (afterNode.exitMode == GlobalStoryStepExitMode.linear) {
        final previousLinks = afterNode.links;
        nodeByStepId[afterNode.stepId] = afterNode.copyWith(
          links: <GlobalStoryStepLink>[
            GlobalStoryStepLink(toStepId: existingStepId),
          ],
        );
        // La step insérée hérite des liens précédents.
        nodeByStepId[existingStepId] = existingNode.copyWith(
          links: previousLinks,
        );
      } else if (afterNode.links.isEmpty) {
        // Mode branching avec aucun lien: on ajoute simplement le lien.
        nodeByStepId[afterNode.stepId] = afterNode.copyWith(
          links: <GlobalStoryStepLink>[
            GlobalStoryStepLink(toStepId: existingStepId),
          ],
        );
      }
    }

    // Supprimer les liens pointant vers la step insérée depuis d'autres noeuds
    // pour éviter les références circulaires involontaires.
    for (final entry in nodeByStepId.entries) {
      if (entry.key == existingStepId) continue;
      final cleanedLinks = entry.value.links
          .where((link) => link.toStepId != existingStepId)
          .toList(growable: false);
      if (cleanedLinks.length != entry.value.links.length) {
        nodeByStepId[entry.key] = entry.value.copyWith(links: cleanedLinks);
      }
    }

    final nextGlobalDocument = globalDoc.copyWith(
      nodes: normalizedSteps
          .map(
            (step) =>
                nodeByStepId[step.id] ?? GlobalStoryStepNode(stepId: step.id),
          )
          .toList(growable: false),
    );

    _replaceDraftDocuments(
      nextStepDocument: nextStepDocument,
      nextGlobalDocument: nextGlobalDocument,
    );

    // --- Mise à jour des chapitres ---
    // Déplacer la step insérée dans le même chapitre que la step source.
    _moveStepToChapterOfStep(afterStepId, existingStepId);

    _selectStep(existingStepId);
  }

  /// Ajoute une step (`newStepId`) au même chapitre que `referenceStepId`.
  ///
  /// Utilisé après la création d'une nouvelle step pour qu'elle apparaisse
  /// dans le bon chapitre immédiatement.
  void _addStepToChapterOfStep(String referenceStepId, String newStepId) {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    if (globalDoc == null || stepDoc == null) return;

    final chapterIdx = globalDoc.chapters.indexWhere(
      (c) => c.stepIds.contains(referenceStepId),
    );
    if (chapterIdx < 0) return;

    final chapter = globalDoc.chapters[chapterIdx];
    final nextChapters = globalDoc.chapters
        .asMap()
        .entries
        .map((e) => e.key == chapterIdx
            ? chapter.copyWith(
                stepIds: <String>[...chapter.stepIds, newStepId])
            : e.value)
        .toList(growable: false);

    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(chapters: nextChapters),
    );
  }

  /// Déplace une step (`stepIdToMove`) dans le même chapitre que `referenceStepId`.
  ///
  /// Utilisé après l'insertion d'une step existante pour mettre à jour
  /// l'appartenance au chapitre.
  void _moveStepToChapterOfStep(String referenceStepId, String stepIdToMove) {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    if (globalDoc == null || stepDoc == null) return;

    // Trouver le chapitre source (contenant referenceStepId).
    final sourceChapterIdx = globalDoc.chapters.indexWhere(
      (c) => c.stepIds.contains(referenceStepId),
    );
    // Trouver le chapitre actuel de la step à déplacer.
    final currentChapterIdx = globalDoc.chapters.indexWhere(
      (c) => c.stepIds.contains(stepIdToMove),
    );

    if (sourceChapterIdx < 0 || currentChapterIdx < 0) return;
    // Même chapitre: rien à faire.
    if (sourceChapterIdx == currentChapterIdx) return;

    final sourceChapter = globalDoc.chapters[sourceChapterIdx];
    final currentChapter = globalDoc.chapters[currentChapterIdx];

    final nextChapters = globalDoc.chapters
        .asMap()
        .entries
        .map((e) {
          if (e.key == currentChapterIdx) {
            // Retirer la step de son chapitre actuel.
            return currentChapter.copyWith(
              stepIds: currentChapter.stepIds
                  .where((id) => id != stepIdToMove)
                  .toList(growable: false),
            );
          }
          if (e.key == sourceChapterIdx) {
            // Ajouter la step au chapitre cible.
            // Insérer après la referenceStepId pour maintenir l'ordre visuel.
            final refIndex = sourceChapter.stepIds
                .indexWhere((id) => id == referenceStepId);
            final newStepIds = <String>[...sourceChapter.stepIds];
            final insertAt = refIndex >= 0 ? refIndex + 1 : newStepIds.length;
            newStepIds.insert(insertAt, stepIdToMove);
            return sourceChapter.copyWith(stepIds: newStepIds);
          }
          return e.value;
        })
        .toList(growable: false);

    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(chapters: nextChapters),
    );
  }


  List<_SimpleOption> _stepOptions({String? excludeStepId}) {
    final stepDoc = _draftStepDocument;
    if (stepDoc == null) {
      return const <_SimpleOption>[];
    }
    final ordered = stepDoc.steps.toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
    return ordered
        .where((step) => step.id != excludeStepId)
        .map(
          (step) => _SimpleOption(
            id: step.id,
            label: '${step.order + 1}. ${step.name}',
          ),
        )
        .toList(growable: false);
  }

  List<_SimpleOption> _outcomeOptions() {
    final stepDoc = _draftStepDocument;
    final outcomeIds = <String>{
      for (final outcome in widget.projection.outcomes) outcome.id,
      if (stepDoc != null)
        for (final step in stepDoc.steps)
          for (final outcome in step.outcomes) outcome.outcomeId,
    };
    return outcomeIds
        .where((id) => id.trim().isNotEmpty)
        .map((id) => _SimpleOption(id: id, label: id))
        .toList(growable: false)
      ..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  }

  List<String> _diagnostics() {
    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    if (stepDoc == null || globalDoc == null) {
      return _loadWarnings;
    }
    return computeGlobalStoryStudioDiagnostics(
      document: globalDoc,
      stepDocument: stepDoc,
      existingWarnings: _loadWarnings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    if (project == null) {
      return const EditorPaneSurface(
        radius: 20,
        tint: EditorChrome.islandWarmTint,
        child: Center(
          child: Text(
            'Chargez un projet pour editer le scenario global.',
          ),
        ),
      );
    }

    final globalStories = project.scenarios
        .where((scenario) => scenario.scope == ScenarioScope.globalStory)
        .toList(growable: false);
    if (globalStories.isEmpty) {
      return _buildNoGlobalStoryState(context);
    }

    final stepDoc = _draftStepDocument;
    final globalDoc = _draftGlobalDocument;
    // NOTE: Le Global Story Studio est une vue de STRUCTURE (chapitres + steps).
    // Il ne nécessite PAS de step sélectionnée pour afficher l'arbre narratif.
    // Si aucune step n'est sélectionnée, on affiche quand même la structure.
    final selectedStep = _stepById(_selectedStepId);

    // Affichage principal: arbre narratif vertical avec chapitres.
    // Cette UI est VOLONTAIREMENT très différente du Step Studio:
    // - le Step Studio = fiche détaillée d'une step (activation, validation, etc.)
    // - le Global Story Studio = arbre narratif (chapitres, steps, flux)
    return Column(
      children: [
        if (stepDoc != null && globalDoc != null)
          Expanded(
            child: _buildNarrativeTree(
              context: context,
              globalStories: globalStories,
              stepDocument: stepDoc,
              globalDocument: globalDoc,
              selectedStep: selectedStep,
            ),
          )
        else
          Expanded(
            child: _buildNoStepSelectedState(context),
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
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                CupertinoIcons.link_circle_fill,
                size: 36,
                color: EditorChrome.inspectorJoyCyan,
              ),
              const SizedBox(height: 10),
              Text(
                'Aucun Global Story',
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Le produit fonctionne avec un scenario global unique. Creez-le pour ouvrir le Global Story Studio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: 320,
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyCyan,
                  icon: CupertinoIcons.plus_circle_fill,
                  label: 'Creer le Global Story unique',
                  prominent: true,
                  enabled: !_busy,
                  onPressed: _createGlobalStoryAndBootstrap,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
              'Selectionnez une step',
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 240,
              child: InspectorEmbeddedPrimaryCapsule(
                accent: EditorChrome.inspectorJoyMint,
                icon: CupertinoIcons.plus_circle_fill,
                label: 'Ajouter une step globale',
                enabled: _canEdit,
                onPressed: _addStepAfterSelection,
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
    required StepStudioDocument? stepDocument,
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
            'Global Story (unique)',
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
            const _InlineInfoBanner(
              accent: EditorChrome.inspectorJoyCoral,
              text:
                  'Plusieurs scenarios globaux detectes. Le studio edite uniquement le premier pour respecter la regle metier.',
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyMint,
                  icon: CupertinoIcons.plus_circle_fill,
                  label: 'Ajouter step',
                  enabled: _canEdit,
                  onPressed: _addStepAfterSelection,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyCoral,
                  icon: CupertinoIcons.delete,
                  label: 'Supprimer',
                  enabled: _canEdit &&
                      stepDocument != null &&
                      stepDocument.steps.length > 1 &&
                      selectedStep != null,
                  onPressed: _deleteSelectedStep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: stepDocument == null || stepDocument.steps.isEmpty
                ? Center(
                    child: Text(
                      'Aucune step globale.',
                      style: TextStyle(
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: stepDocument.steps.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final step = stepDocument.steps[index];
                      final node = _nodeByStepId(step.id);
                      final isEntry =
                          _draftGlobalDocument?.entryStepId == step.id;
                      return EditorSidebarListRow(
                        selected: selectedStep?.id == step.id,
                        onTap: () => _selectStep(step.id),
                        leading: Icon(
                          isEntry
                              ? CupertinoIcons.location_solid
                              : CupertinoIcons.link,
                        ),
                        title: Text('${step.order + 1}. ${step.name}'),
                        subtitle: Text(
                          '${globalStoryStepExitModeLabel(node?.exitMode ?? GlobalStoryStepExitMode.linear)} • ${node?.links.length ?? 0} suite(s)',
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

  // ===========================================================================
  // ARBRE NARRATIF PRINCIPAL (nouvelle UX orientée chapitres + structure)
  // ===========================================================================
  //
  // Cette méthode remplace l'ancien `_buildGlobalStoryEditor` qui ressemblait
  // trop à une fiche de formulaire de step. L'objectif est de donner une
  // sensation de "carte routière narrative" verticale avec:
  // - une zone haute de résumé macro,
  // - des chapitres clairement séparés,
  // - des steps compactes dans chaque chapitre,
  // - des indicateurs de flux entre les steps.

  Widget _buildNarrativeTree({
    required BuildContext context,
    required List<ScenarioAsset> globalStories,
    required StepStudioDocument stepDocument,
    required GlobalStoryStudioDocument globalDocument,
    required StepStudioStep? selectedStep,
  }) {
    final orderedSteps = stepDocument.steps.toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
    final chapters = globalDocument.chapters.isEmpty
        ? <GlobalStoryChapter>[]
        : globalDocument.chapters.toList(growable: false)
          ..sort((a, b) => a.order.compareTo(b.order));
    final diagnostics = _diagnostics();
    final globalName = globalStories.first.name.trim().isEmpty
        ? globalStories.first.id
        : globalStories.first.name;

    // Compte les branches et convergences pour le résumé macro.
    var branchCount = 0;
    var convergeCount = 0;
    for (final node in globalDocument.nodes) {
      if (node.exitMode == GlobalStoryStepExitMode.branchExclusive ||
          node.exitMode == GlobalStoryStepExitMode.branchConditional) {
        branchCount++;
      }
      if (node.exitMode == GlobalStoryStepExitMode.converge) {
        convergeCount++;
      }
    }

    return EditorPaneSurface(
      radius: 20,
      tint: EditorChrome.islandWarmTint,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          // ZONE HAUTE: résumé macro du scénario global.
          _NarrativeTreeHeader(
            globalName: globalName,
            chapterCount: chapters.length,
            totalStepCount: orderedSteps.length,
            branchCount: branchCount,
            convergeCount: convergeCount,
            hasUnsavedChanges: _hasUnsavedChanges,
            canEdit: _canEdit,
            onSave: _saveDraft,
            onReset: _resetDraft,
          ),
          const SizedBox(height: 16),
          // ZONE PRINCIPALE: arbre vertical par chapitres.
          Expanded(
            child: ListView(
              children: [
                if (_usedStepLegacyFallback || _usedGlobalLegacyFallback) ...[
                  const _InlineInfoBanner(
                    accent: EditorChrome.inspectorJoyAmber,
                    text:
                        'Des donnees historiques ont ete converties en mode compatibilite. Sauvegardez pour stabiliser le document Global Story v1.',
                  ),
                  const SizedBox(height: 10),
                ],
                for (final warning in diagnostics) ...[
                  _InlineInfoBanner(
                    accent: EditorChrome.inspectorJoyCoral,
                    text: warning,
                  ),
                  const SizedBox(height: 8),
                ],
                // Affichage des chapitres avec leurs steps.
                for (final entry in chapters.asMap().entries) ...[
                  if (entry.key > 0) const _ChapterGap(),
                  _NarrativeChapterSection(
                    chapter: entry.value,
                    chapterIndex: entry.key,
                    totalChapters: chapters.length,
                    steps: entry.value.stepIds
                        .map((stepId) => orderedSteps
                            .where((s) => s.id == stepId)
                            .cast<StepStudioStep?>()
                            .firstWhere((s) => s != null, orElse: () => null))
                        .whereType<StepStudioStep>()
                        .toList(growable: false),
                    allProjectSteps: orderedSteps,
                    globalDocument: globalDocument,
                    selectedStepId: selectedStep?.id,
                    canEdit: _canEdit,
                    onTapChapter: (id) => _selectChapter(id),
                    onRenameChapter: (id, name) => _renameChapter(id, name),
                    onMoveChapterUp: () => _moveChapter(-1),
                    onMoveChapterDown: () => _moveChapter(1),
                    onAddChapter: _addChapter,
                    onDeleteChapter: () => _deleteChapter(entry.value.id),
                    onSelectStep: _selectStep,
                    onOpenStepStudio: widget.onOpenStepStudio,
                    onSetEntryStep: _setEntryStep,
                    onCreateNewStep: _createNewStepAfter,
                    onInsertExistingStep: _insertExistingStepAfter,
                    onChangeStepExitMode: _updateSelectedNodeExitMode,
                    onAddLink: _addLinkFromSelectedStep,
                    onRemoveLink: _removeLinkFromSelectedStep,
                    onUpdateLinkTarget: _updateLinkFromSelectedStepToStep,
                    isExpanded: _expandedChapters.contains(entry.value.id),
                    onToggleExpansion: () => _toggleChapterExpansion(entry.value.id),
                  ),
                ],
                // S'il n'y a aucun chapitre mais des steps existent,
                // on affiche un message invitant à créer un chapitre.
                if (chapters.isEmpty && orderedSteps.isNotEmpty) ...[
                  _NoChaptersHint(
                    stepCount: orderedSteps.length,
                    onAddChapter: _addChapter,
                    enabled: _canEdit,
                  ),
                ],
                const SizedBox(height: 12),
                const InspectorEmbeddedFootnote(
                  text:
                      'Global Story = structure macro (chapitres + steps). Step = logique locale. Cutscene = execution.',
                  accent: EditorChrome.inspectorJoyCyan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader({
    required BuildContext context,
    required List<ScenarioAsset> globalStories,
    required StepStudioStep selectedStep,
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
                      'Global Story Studio',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scenario global unique: $globalName',
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
                    'Non sauvegarde',
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
          Text(
            'Step selectionnee: ${selectedStep.order + 1}. ${selectedStep.name}',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
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
                  label: 'Reinitialiser',
                  enabled: _canEdit && _hasUnsavedChanges,
                  onPressed: _resetDraft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyMint,
                  icon: CupertinoIcons.plus_circle_fill,
                  label: 'Inserer step',
                  enabled: _canEdit,
                  onPressed: _addStepAfterSelection,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlobalStorySectionCard extends StatelessWidget {
  const _GlobalStorySectionCard({
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

class _GlobalStoryStepCard extends StatelessWidget {
  const _GlobalStoryStepCard({
    required this.step,
    required this.node,
    required this.isSelected,
    required this.isEntryStep,
    required this.stepOptions,
    required this.outcomeOptions,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onTap,
    required this.onMarkAsEntry,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRenameStep,
    required this.onDescribeStep,
    required this.onChangeExitMode,
    required this.onAddLink,
    required this.onUpdateLinkTarget,
    required this.onUpdateLinkCondition,
    required this.onUpdateLinkOutcome,
    required this.onRemoveLink,
    required this.onInsertAfter,
    required this.onOpenStepStudio,
    required this.enabled,
  });

  final StepStudioStep step;
  final GlobalStoryStepNode node;
  final bool isSelected;
  final bool isEntryStep;
  final List<_SimpleOption> stepOptions;
  final List<_SimpleOption> outcomeOptions;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onTap;
  final VoidCallback onMarkAsEntry;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final ValueChanged<String> onRenameStep;
  final ValueChanged<String> onDescribeStep;
  final ValueChanged<GlobalStoryStepExitMode> onChangeExitMode;
  final VoidCallback onAddLink;
  final void Function(int index, String? value) onUpdateLinkTarget;
  final void Function(int index, String value) onUpdateLinkCondition;
  final void Function(int index, String? value) onUpdateLinkOutcome;
  final ValueChanged<int> onRemoveLink;
  final VoidCallback onInsertAfter;
  final VoidCallback onOpenStepStudio;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? EditorChrome.inspectorJoyBlue
        : EditorChrome.inspectorJoyCyan;
    final isBranching =
        node.exitMode == GlobalStoryStepExitMode.branchExclusive ||
            node.exitMode == GlobalStoryStepExitMode.branchConditional;
    final isConverge = node.exitMode == GlobalStoryStepExitMode.converge;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: accent.withValues(alpha: isSelected ? 0.15 : 0.06),
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accent.withValues(alpha: isSelected ? 0.55 : 0.3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    '#${step.order + 1}',
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                if (isEntryStep)
                  const _StepBadge(
                    label: 'Depart',
                    accent: EditorChrome.inspectorJoyMint,
                  ),
                if (isBranching) ...[
                  const SizedBox(width: 6),
                  const _StepBadge(
                    label: 'Branche',
                    accent: EditorChrome.inspectorJoyAmber,
                  ),
                ],
                if (isConverge) ...[
                  const SizedBox(width: 6),
                  const _StepBadge(
                    label: 'Convergence',
                    accent: EditorChrome.inspectorJoyCoral,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (isSelected) ...[
              _InlineTextField(
                label: 'Nom de step',
                value: step.name,
                enabled: enabled,
                onChanged: onRenameStep,
              ),
              const SizedBox(height: 6),
              _InlineTextField(
                label: 'Resume',
                value: step.description,
                enabled: enabled,
                minLines: 2,
                maxLines: 3,
                onChanged: onDescribeStep,
              ),
            ] else ...[
              Text(
                step.name,
                style: TextStyle(
                  color: EditorChrome.primaryLabel(context),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step.description.trim().isEmpty
                    ? 'Aucune description'
                    : step.description,
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InspectorEmbeddedSecondaryCapsule(
                    accent: EditorChrome.inspectorJoyMint,
                    icon: CupertinoIcons.location_solid,
                    label: isEntryStep ? 'Step de depart' : 'Definir depart',
                    enabled: enabled && !isEntryStep,
                    onPressed: onMarkAsEntry,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InspectorEmbeddedSecondaryCapsule(
                    accent: EditorChrome.inspectorJoyAmber,
                    icon: CupertinoIcons.plus_circle,
                    label: 'Inserer apres',
                    enabled: enabled,
                    onPressed: onInsertAfter,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: InspectorEmbeddedSecondaryCapsule(
                    accent: EditorChrome.inspectorJoyBlue,
                    icon: CupertinoIcons.arrow_up,
                    label: 'Monter',
                    enabled: enabled && canMoveUp && isSelected,
                    onPressed: onMoveUp,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InspectorEmbeddedSecondaryCapsule(
                    accent: EditorChrome.inspectorJoyBlue,
                    icon: CupertinoIcons.arrow_down,
                    label: 'Descendre',
                    enabled: enabled && canMoveDown && isSelected,
                    onPressed: onMoveDown,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: InspectorEmbeddedSecondaryCapsule(
                    accent: EditorChrome.inspectorJoyPlum,
                    icon: CupertinoIcons.square_stack_3d_up,
                    label: 'Ouvrir Step',
                    enabled: enabled,
                    onPressed: onOpenStepStudio,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _EnumDropdown<GlobalStoryStepExitMode>(
              accent: EditorChrome.inspectorJoyCyan,
              fieldLabel: 'Sortie globale',
              value: node.exitMode,
              values: GlobalStoryStepExitMode.values,
              labelBuilder: globalStoryStepExitModeLabel,
              enabled: enabled && isSelected,
              onChanged: onChangeExitMode,
            ),
            const SizedBox(height: 8),
            if (node.links.isEmpty)
              const _InlineInfoBanner(
                accent: EditorChrome.inspectorJoyAmber,
                text:
                    'Aucune destination configuree. Ajoutez au moins une suite globale.',
              ),
            for (final linkEntry in node.links.asMap().entries) ...[
              const SizedBox(height: 6),
              _GlobalLinkRow(
                index: linkEntry.key,
                link: linkEntry.value,
                mode: node.exitMode,
                stepOptions: stepOptions,
                outcomeOptions: outcomeOptions,
                enabled: enabled && isSelected,
                onUpdateTarget: (value) =>
                    onUpdateLinkTarget(linkEntry.key, value),
                onUpdateCondition: (value) =>
                    onUpdateLinkCondition(linkEntry.key, value),
                onUpdateOutcome: (value) =>
                    onUpdateLinkOutcome(linkEntry.key, value),
                onRemove: () => onRemoveLink(linkEntry.key),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: InspectorEmbeddedSecondaryCapsule(
                accent: EditorChrome.inspectorJoyCyan,
                icon: CupertinoIcons.add_circled,
                label: 'Ajouter une destination',
                enabled: enabled && isSelected && stepOptions.isNotEmpty,
                onPressed: onAddLink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalLinkRow extends StatelessWidget {
  const _GlobalLinkRow({
    required this.index,
    required this.link,
    required this.mode,
    required this.stepOptions,
    required this.outcomeOptions,
    required this.enabled,
    required this.onUpdateTarget,
    required this.onUpdateCondition,
    required this.onUpdateOutcome,
    required this.onRemove,
  });

  final int index;
  final GlobalStoryStepLink link;
  final GlobalStoryStepExitMode mode;
  final List<_SimpleOption> stepOptions;
  final List<_SimpleOption> outcomeOptions;
  final bool enabled;
  final ValueChanged<String?> onUpdateTarget;
  final ValueChanged<String> onUpdateCondition;
  final ValueChanged<String?> onUpdateOutcome;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Destination ${index + 1}',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          _SimpleDropdown(
            accent: EditorChrome.inspectorJoyBlue,
            fieldLabel: 'Step suivante',
            options: stepOptions,
            selectedId: link.toStepId,
            emptyLabel: 'Aucune step',
            enabled: enabled && stepOptions.isNotEmpty,
            onSelected: onUpdateTarget,
          ),
          if (mode == GlobalStoryStepExitMode.branchConditional) ...[
            const SizedBox(height: 6),
            _InlineTextField(
              label: 'Condition lisible',
              value: link.conditionLabel ?? '',
              enabled: enabled,
              onChanged: onUpdateCondition,
            ),
            const SizedBox(height: 6),
            _SimpleDropdown(
              accent: EditorChrome.inspectorJoyAmber,
              fieldLabel: 'Outcome requis (optionnel)',
              options: outcomeOptions,
              selectedId: link.requiredOutcomeId,
              emptyLabel: 'Aucun outcome',
              enabled: enabled && outcomeOptions.isNotEmpty,
              onSelected: onUpdateOutcome,
            ),
          ],
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: InspectorEmbeddedSecondaryCapsule(
              accent: EditorChrome.inspectorJoyCoral,
              icon: CupertinoIcons.minus_circle,
              label: 'Retirer ce lien',
              enabled: enabled,
              onPressed: onRemove,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowConnectorHint extends StatelessWidget {
  const _FlowConnectorHint({
    required this.sourceStepName,
    required this.destinationLabels,
  });

  final String sourceStepName;
  final List<String> destinationLabels;

  @override
  Widget build(BuildContext context) {
    final next = destinationLabels.isEmpty
        ? 'Aucune destination'
        : destinationLabels.join(' / ');
    return Row(
      children: [
        const SizedBox(width: 12),
        Icon(
          CupertinoIcons.arrow_down,
          size: 14,
          color: EditorChrome.subtleLabel(context),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '$sourceStepName -> $next',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.label,
    required this.accent,
  });

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: EditorChrome.primaryLabel(context),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
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

const Object _unset = Object();

// =============================================================================
// NOUVEAUX WIDGETS POUR L'ARBRE NARRATIF (Global Story Studio v2)
// =============================================================================
//
// Ces widgets remplacent l'ancien `_GlobalStoryStepCard` qui ressemblait
// trop à une fiche de formulaire de step. L'objectif est d'avoir une
// représentation visuelle de type "carte routière narrative".

/// Zone haute du Global Story Studio: résumé macro du scénario global.
///
/// Montre immédiatement:
/// - le nom du scénario global unique,
/// - le nombre de chapitres, de steps, de branches, de convergences,
/// - les actions globales (sauvegarder, réinitialiser).
class _NarrativeTreeHeader extends StatelessWidget {
  const _NarrativeTreeHeader({
    required this.globalName,
    required this.chapterCount,
    required this.totalStepCount,
    required this.branchCount,
    required this.convergeCount,
    required this.hasUnsavedChanges,
    required this.canEdit,
    required this.onSave,
    required this.onReset,
  });

  final String globalName;
  final int chapterCount;
  final int totalStepCount;
  final int branchCount;
  final int convergeCount;
  final bool hasUnsavedChanges;
  final bool canEdit;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Couleur cyan pour le Global Story (distinct du mint du Step Studio).
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.3),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.map_fill,
                color: EditorChrome.inspectorJoyCyan,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  globalName,
                  style: TextStyle(
                    color: EditorChrome.primaryLabel(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (hasUnsavedChanges)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        EditorChrome.inspectorJoyCoral.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color:
                          EditorChrome.inspectorJoyCoral.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Text(
                    'Modifié',
                    style: TextStyle(
                      color: EditorChrome.inspectorJoyCoral,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Badges de résumé macro.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _MacroBadge(
                icon: CupertinoIcons.book_fill,
                label: '$chapterCount chapitre${chapterCount > 1 ? 's' : ''}',
                accent: EditorChrome.inspectorJoyCyan,
              ),
              _MacroBadge(
                icon: CupertinoIcons.flag_fill,
                label: '$totalStepCount step${totalStepCount > 1 ? 's' : ''}',
                accent: EditorChrome.inspectorJoyMint,
              ),
              if (branchCount > 0)
                _MacroBadge(
                  icon: CupertinoIcons.share,
                  label: '$branchCount branche${branchCount > 1 ? 's' : ''}',
                  accent: EditorChrome.inspectorJoyAmber,
                ),
              if (convergeCount > 0)
                _MacroBadge(
                  icon: CupertinoIcons.arrow_merge,
                  label:
                      '$convergeCount convergence${convergeCount > 1 ? 's' : ''}',
                  accent: EditorChrome.inspectorJoyCoral,
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
                  enabled: canEdit && hasUnsavedChanges,
                  onPressed: onSave,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyCyan,
                  icon: CupertinoIcons.arrow_uturn_left,
                  label: 'Réinitialiser',
                  enabled: canEdit && hasUnsavedChanges,
                  onPressed: onReset,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Petit badge de résumé macro dans le header du Global Story Studio.
class _MacroBadge extends StatelessWidget {
  const _MacroBadge({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Séparateur visuel entre deux chapitres dans l'arbre narratif.
class _ChapterGap extends StatelessWidget {
  const _ChapterGap();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: EditorChrome.subtleLabel(context).withValues(alpha: 0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: EditorChrome.subtleLabel(context),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: EditorChrome.subtleLabel(context).withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Message affiché quand des steps existent mais aucun chapitre n'est défini.
class _NoChaptersHint extends StatelessWidget {
  const _NoChaptersHint({
    required this.stepCount,
    required this.onAddChapter,
    required this.enabled,
  });

  final int stepCount;
  final VoidCallback onAddChapter;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyAmber.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '$stepCount step(s) sans chapitre',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Organisez vos steps en chapitres pour une lecture narrative claire.',
            style: TextStyle(
              color: EditorChrome.subtleLabel(context),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: InspectorEmbeddedPrimaryCapsule(
              accent: EditorChrome.inspectorJoyAmber,
              icon: CupertinoIcons.book_fill,
              label: 'Créer un chapitre',
              enabled: enabled,
              onPressed: onAddChapter,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section de chapitre dans l'arbre narratif.
///
/// Affiche:
/// - un header de chapitre fort et visible,
/// - les steps compactes dans ce chapitre,
/// - les indicateurs de flux entre les steps.
///
/// C'est le widget CENTRAL de la nouvelle UX Global Story Studio.
///
/// Converti en StatefulWidget pour gérer l'état du sélecteur d'insertion
/// de step existante (quel step affiche le picker en ce moment).
class _NarrativeChapterSection extends StatefulWidget {
  const _NarrativeChapterSection({
    required this.chapter,
    required this.chapterIndex,
    required this.totalChapters,
    required this.steps,
    required this.allProjectSteps,
    required this.globalDocument,
    required this.selectedStepId,
    required this.canEdit,
    required this.onTapChapter,
    required this.onRenameChapter,
    required this.onMoveChapterUp,
    required this.onMoveChapterDown,
    required this.onAddChapter,
    required this.onDeleteChapter,
    required this.onSelectStep,
    required this.onOpenStepStudio,
    required this.onSetEntryStep,
    required this.onCreateNewStep,
    required this.onInsertExistingStep,
    required this.onChangeStepExitMode,
    required this.onAddLink,
    required this.onRemoveLink,
    required this.onUpdateLinkTarget,
    required this.isExpanded,
    required this.onToggleExpansion,
  });

  final GlobalStoryChapter chapter;
  final int chapterIndex;
  final int totalChapters;
  
  /// Steps dans ce chapitre uniquement
  final List<StepStudioStep> steps;
  
  /// TOUTES les steps du projet (pour le picker d'insertion)
  final List<StepStudioStep> allProjectSteps;
  
  final GlobalStoryStudioDocument globalDocument;
  final String? selectedStepId;
  final bool canEdit;
  final ValueChanged<String> onTapChapter;
  final _ChapterRenameCallback onRenameChapter;
  final VoidCallback onMoveChapterUp;
  final VoidCallback onMoveChapterDown;
  final VoidCallback onAddChapter;
  final VoidCallback onDeleteChapter;
  final ValueChanged<String?> onSelectStep;
  final ValueChanged<String> onOpenStepStudio;
  final ValueChanged<String> onSetEntryStep;

  // Callback pour CRÉER une nouvelle step après une step donnée.
  final ValueChanged<String> onCreateNewStep;

  // Callback pour INSÉRER une step existante après une step donnée
  // (l'ID de la step à insérer est passée via le picker).
  final void Function(String afterStepId, String existingStepId)
      onInsertExistingStep;

  final ValueChanged<GlobalStoryStepExitMode> onChangeStepExitMode;
  final VoidCallback onAddLink;
  final ValueChanged<int> onRemoveLink;
  final void Function(int, String?) onUpdateLinkTarget;
  final bool isExpanded;
  final VoidCallback onToggleExpansion;

  @override
  State<_NarrativeChapterSection> createState() =>
      _NarrativeChapterSectionState();
}

class _NarrativeChapterSectionState extends State<_NarrativeChapterSection> {
  // ID de la step qui affiche actuellement le sélecteur de step existante.
  // Une seule step à la fois peut avoir le picker ouvert.
  String? _insertPickerStepId;

  GlobalStoryStepNode? _nodeByStepId(String? stepId) {
    if (stepId == null) return null;
    for (final node in widget.globalDocument.nodes) {
      if (node.stepId == stepId) return node;
    }
    return null;
  }

  void _togglePicker(String stepId) {
    setState(() {
      _insertPickerStepId = _insertPickerStepId == stepId ? null : stepId;
    });
  }

  void _cancelPicker() {
    setState(() {
      _insertPickerStepId = null;
    });
  }

  void _pickExistingStep(String afterStepId, String existingStepId) {
    widget.onInsertExistingStep(afterStepId, existingStepId);
    _cancelPicker();
  }

  /// Génère la liste des steps existantes disponibles pour insertion.
  ///
  /// IMPORTANT : utilise [allProjectSteps] (toutes les steps du projet)
  /// et PAS [widget.steps] (steps du chapitre uniquement).
  ///
  /// Exclut la step courante pour éviter l'auto-insertion.
  List<_SimpleOption> _availableStepsFor(String currentStepId) {
    return widget.allProjectSteps
        .where((s) => s.id != currentStepId)
        .map((s) => _SimpleOption(
              id: s.id,
              label: '#${s.order + 1}. ${s.name}',
            ))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ============================================
        // ZONE 1: HEADER FIXE (toujours visible)
        // ============================================
        // Le header contient:
        // - le chevron animé (toggle expansion)
        // - le nom du chapitre (sélection)
        // - les badges et actions
        _ChapterHeader(
          chapter: widget.chapter,
          chapterIndex: widget.chapterIndex,
          totalChapters: widget.totalChapters,
          stepCount: widget.steps.length,
          isSelected: false,
          canEdit: widget.canEdit,
          onRename: (name) => widget.onRenameChapter(widget.chapter.id, name),
          onMoveUp: widget.onMoveChapterUp,
          onMoveDown: widget.onMoveChapterDown,
          onAddChapter: widget.onAddChapter,
          onDelete: widget.chapter.stepIds.isEmpty
              ? widget.onDeleteChapter
              : null,
          showExpansionIcon: true,
          isExpanded: widget.isExpanded,
          onExpansionTap: widget.onToggleExpansion,
        ),
        
        // ============================================
        // ZONE 2: RÉSUMÉ STABLE (toujours visible)
        // ============================================
        // Affiche un résumé compact du chapitre:
        // - nombre de steps
        // - description si disponible
        // Opacité légèrement réduite quand le chapitre est ouvert
        // pour laisser la place visuelle aux steps.
        _ChapterSummary(
          stepCount: widget.steps.length,
          chapter: widget.chapter,
          isExpanded: widget.isExpanded,
        ),
        
        const SizedBox(height: 6),
        
        // ============================================
        // ZONE 3: CONTENU DES STEPS (ANIMÉ)
        // ============================================
        // Cette zone s'ouvre et se ferme avec une animation fluide.
        // Utilise ClipRect + AnimatedSize pour:
        // - une transition de hauteur douce et naturelle
        // - pas de débordement visuel pendant l'animation
        // - alignment par le haut (lecture top-down)
        ClipRect(
          child: AnimatedSize(
            // Duration: 300ms pour une animation fluide mais réactive
            duration: const Duration(milliseconds: 300),
            // Curve: easeInOut pour un mouvement naturel
            curve: Curves.easeInOut,
            // Alignment: topCenter pour que l'animation parte du haut
            // (cohérent avec la lecture top-down du Global Story)
            alignment: Alignment.topCenter,
            // Si le chapitre est ouvert: affiche les steps
            // Si le chapitre est fermé: SizedBox.shrink() (hauteur 0)
            child: widget.isExpanded
              ? _buildStepsContent(context)
              : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  /// Construit le contenu des steps du chapitre.
  ///
  /// Cette méthode est séparée du build() principal pour:
  /// - clarifier la responsabilité (zone animée vs structure)
  /// - faciliter la maintenance
  /// - garder le build() lisible
  Widget _buildStepsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // STEPS DU CHAPITRE: cartes compactes en flux vertical.
        for (final entry in widget.steps.asMap().entries) ...[
          if (entry.key > 0)
            _StepFlowArrow(
              sourceName: widget.steps[entry.key - 1].name,
              destinationName: entry.value.name,
              node: _nodeByStepId(widget.steps[entry.key - 1].id),
            ),
          _CompactStepCard(
            step: entry.value,
            node: _nodeByStepId(entry.value.id) ??
                GlobalStoryStepNode(stepId: entry.value.id),
            isSelected: entry.value.id == widget.selectedStepId,
            isEntryStep: widget.globalDocument.entryStepId == entry.value.id,
            canEdit: widget.canEdit,
            onTap: () => widget.onSelectStep(entry.value.id),
            onOpenStepStudio: () => widget.onOpenStepStudio(entry.value.id),
            onSetEntryStep: () => widget.onSetEntryStep(entry.value.id),
            // Bouton "Nouvelle step" — crée explicitement une nouvelle step.
            onCreateNewStep: () => widget.onCreateNewStep(entry.value.id),
            // Bouton "Insérer" — ouvre le sélecteur de step existante.
            onInsertExistingStep: () => _togglePicker(entry.value.id),
            // État du picker pour cette step.
            insertPickerVisible: _insertPickerStepId == entry.value.id,
            onTogglePicker: () => _togglePicker(entry.value.id),
            onPickExistingStep: (existingStepId) =>
                _pickExistingStep(entry.value.id, existingStepId),
            availableSteps: _availableStepsFor(entry.value.id),
          ),
        ],
        // Si le chapitre est vide, afficher un message.
        if (widget.steps.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: EditorChrome.largeIslandSurfaceColor(
                context,
                tint: EditorChrome.subtleLabel(context).withValues(alpha: 0.04),
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: EditorChrome.subtleLabel(context).withValues(alpha: 0.15),
                style: BorderStyle.solid,
              ),
            ),
            child: Text(
              'Aucune step dans ce chapitre',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

/// Header de chapitre: titre fort, badge de step count, actions.
///
/// C'est le marqueur visuel le plus important de la hiérarchie
/// du Global Story Studio. Il doit être IMPOSSIBLE de le confondre
/// avec une step individuelle.
class _ChapterHeader extends StatelessWidget {
  const _ChapterHeader({
    required this.chapter,
    required this.chapterIndex,
    required this.totalChapters,
    required this.stepCount,
    required this.isSelected,
    required this.canEdit,
    required this.onRename,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onAddChapter,
    this.onDelete,
    this.showExpansionIcon = false,
    this.isExpanded = false,
    this.onExpansionTap,
  });

  final GlobalStoryChapter chapter;
  final int chapterIndex;
  final int totalChapters;
  final int stepCount;
  final bool isSelected;
  final bool canEdit;
  final ValueChanged<String> onRename;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onAddChapter;
  final VoidCallback? onDelete;
  final bool showExpansionIcon;
  final bool isExpanded;
  final VoidCallback? onExpansionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // Fond violet profond pour les chapitres (distinct du cyan du header global).
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ============================================
          // ZONE TOGGLE ACCORDÉON (toute la barre sauf actions)
          // ============================================
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onExpansionTap,
              child: Row(
                children: [
                  // Icône d'expansion avec animation fluide
                  if (showExpansionIcon) ...[
                    AnimatedRotation(
                      // turns: 0.5 = 90° (chevron_down), 0.0 = 0° (chevron_right)
                      turns: isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 16,
                        color: EditorChrome.primaryLabel(context),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  // Numéro de chapitre.
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: EditorChrome.inspectorJoyPlum.withValues(
                          alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CH. ${chapterIndex + 1}',
                      style: TextStyle(
                        color: EditorChrome.inspectorJoyPlum,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Nom du chapitre avec double-clic pour renommage
                  Expanded(
                    child: _ChapterNameDisplay(
                      name: chapter.name,
                      onRename: onRename,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge de step count.
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: EditorChrome.inspectorJoyMint.withValues(
                          alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$stepCount step${stepCount > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: EditorChrome.inspectorJoyMint,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ============================================
          // ZONE ACTIONS (ne toggle pas l'accordéon)
          // ============================================
          if (canEdit) ...[
            const SizedBox(width: 8),
            // Boutons d'action — chaque bouton a son propre GestureDetector
            Row(
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed: onMoveUp,
                  child: Icon(
                    CupertinoIcons.chevron_up,
                    size: 18,
                    color: EditorChrome.inspectorJoyPlum,
                  ),
                ),
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed: onMoveDown,
                  child: Icon(
                    CupertinoIcons.chevron_down,
                    size: 18,
                    color: EditorChrome.inspectorJoyPlum,
                  ),
                ),
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed: onDelete,
                  child: Icon(
                    CupertinoIcons.delete,
                    size: 18,
                    color: EditorChrome.inspectorJoyCoral,
                  ),
                ),
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 28,
                  onPressed: onAddChapter,
                  child: Icon(
                    CupertinoIcons.add_circled,
                    size: 20,
                    color: EditorChrome.inspectorJoyCyan,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Flèche de flux entre deux steps consécutives.
///
/// Montre visuellement la progression narrative d'une step à l'autre
/// à l'intérieur d'un chapitre.
class _StepFlowArrow extends StatelessWidget {
  const _StepFlowArrow({
    required this.sourceName,
    required this.destinationName,
    this.node,
  });

  final String sourceName;
  final String destinationName;
  final GlobalStoryStepNode? node;

  @override
  Widget build(BuildContext context) {
    final isBranching = node != null &&
        (node!.exitMode == GlobalStoryStepExitMode.branchExclusive ||
            node!.exitMode == GlobalStoryStepExitMode.branchConditional);
    final isConverge =
        node != null && node!.exitMode == GlobalStoryStepExitMode.converge;
    final destCount = node?.links.length ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Indenteur visuel.
          const SizedBox(width: 24),
          // Icône de flux.
          Icon(
            isBranching
                ? CupertinoIcons.share
                : isConverge
                    ? CupertinoIcons.arrow_merge
                    : CupertinoIcons.arrow_down,
            size: 12,
            color: isBranching
                ? EditorChrome.inspectorJoyAmber
                : isConverge
                    ? EditorChrome.inspectorJoyCoral
                    : EditorChrome.subtleLabel(context).withValues(alpha: 0.5),
          ),
          const SizedBox(width: 6),
          // Label de destination.
          Expanded(
            child: Text(
              destCount > 1
                  ? '$sourceName → $destCount destinations'
                  : '$sourceName → $destinationName',
              style: TextStyle(
                color: EditorChrome.subtleLabel(context),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Résumé compact d'un chapitre, toujours visible sous le header.
///
/// Ce widget affiche un résumé stable du chapitre (nombre de steps, etc.)
/// et reste visible que le chapitre soit ouvert ou fermé.
/// Quand le chapitre est ouvert, l'opacité est légèrement réduite pour
/// laisser la place aux steps tout en restant lisible.
///
/// Rôle produit:
/// - donner une information immédiate sur le contenu du chapitre
/// - rester stable visuellement (pas de swap brutal)
/// - renforcer la lecture macro (Global Story ≠ Step Studio)
class _ChapterSummary extends StatelessWidget {
  const _ChapterSummary({
    required this.stepCount,
    required this.chapter,
    this.isExpanded = false,
  });

  /// Nombre de steps dans le chapitre
  final int stepCount;

  /// Chapitre concerné
  final GlobalStoryChapter chapter;

  /// État d'expansion (pour ajuster l'opacité)
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    // Opacité réduite quand le chapitre est ouvert pour laisser la place aux steps
    final summaryOpacity = isExpanded ? 0.6 : 1.0;

    return AnimatedOpacity(
      opacity: summaryOpacity,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(
          children: [
            // Badge du nombre de steps
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$stepCount step${stepCount > 1 ? 's' : ''}',
                style: TextStyle(
                  color: EditorChrome.inspectorJoyMint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Séparateur visuel si le chapitre a une description
            if (chapter.description.trim().isNotEmpty) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  chapter.description,
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Affichage du nom du chapitre avec support de renommage inline par double-clic.
///
/// Comportement UX :
/// - simple clic = ne fait rien (le toggle est géré par le parent)
/// - double-clic = démarre le mode édition inline
/// - Enter = valide le nouveau nom
/// - Escape = annule et restaure l'ancien nom
/// - perte de focus = annule et restaure l'ancien nom
///
/// Style macOS : sélection automatique du texte, pas de modal.
class _ChapterNameDisplay extends StatefulWidget {
  const _ChapterNameDisplay({
    required this.name,
    required this.onRename,
  });

  final String name;
  final ValueChanged<String> onRename;

  @override
  State<_ChapterNameDisplay> createState() => _ChapterNameDisplayState();
}

class _ChapterNameDisplayState extends State<_ChapterNameDisplay> {
  bool _isEditing = false;
  late TextEditingController _controller;
  late String _originalName;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.name);
    _originalName = widget.name;
    // Annule l'édition si le champ perd le focus
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && _isEditing) {
        _cancelEdit();
      }
    });
    // Gère les touches spéciales (Escape)
    _focusNode.onKeyEvent = _onEditKeyEvent;
  }

  @override
  void didUpdateWidget(covariant _ChapterNameDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name) {
      _controller.text = widget.name;
      _originalName = widget.name;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _originalName = widget.name;
      _controller.text = widget.name;
    });
    // Sélectionne tout le texte après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
        _focusNode.requestFocus();
      }
    });
  }

  /// Gère les événements clavier quand le champ a le focus.
  /// Retourne [KeyEventResult.handled] si l'événement est consommé.
  KeyEventResult _onEditKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelEdit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _commitEdit() {
    final newName = _controller.text.trim();
    if (newName.isNotEmpty && newName != _originalName) {
      widget.onRename(newName);
    }
    setState(() {
      _isEditing = false;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _controller.text = _originalName;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      // Mode édition : champ de saisie inline
      // GestureDetector empêche le tap de se propager au toggle accordéon
      return GestureDetector(
        onTap: () {},
        child: CupertinoTextField(
          controller: _controller,
          focusNode: _focusNode,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: EditorChrome.largeIslandSurfaceColor(
              context,
              tint: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.05),
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.4),
            ),
          ),
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          // Enter valide
          onSubmitted: (_) => _commitEdit(),
        ),
      );
    }

    // Mode affichage : texte normal avec double-clic
    return GestureDetector(
      onDoubleTap: _startEditing,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Text(
          widget.name,
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Carte de step COMPACTE dans le Global Story Studio.
///
/// CONTRAIREMENT au Step Studio qui affiche tous les détails d'une step,
/// cette carte ne montre que l'essentiel pour la lecture macro:
/// - numéro d'ordre,
/// - nom,
/// - description courte,
/// - type de sortie (badge),
/// - bouton "Ouvrir Step" pour accéder au détail.
///
/// C'est la différence visuelle CLÉ entre Global Story et Step Studio.
class _CompactStepCard extends StatelessWidget {
  const _CompactStepCard({
    required this.step,
    required this.node,
    required this.isSelected,
    required this.isEntryStep,
    required this.canEdit,
    required this.onTap,
    required this.onOpenStepStudio,
    required this.onSetEntryStep,
    required this.onCreateNewStep,
    required this.onInsertExistingStep,
    required this.insertPickerVisible,
    required this.onTogglePicker,
    required this.onPickExistingStep,
    required this.availableSteps,
  });

  final StepStudioStep step;
  final GlobalStoryStepNode node;
  final bool isSelected;
  final bool isEntryStep;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback onOpenStepStudio;
  final VoidCallback onSetEntryStep;

  // Callback pour "Créer une nouvelle step" — action explicite de création.
  final VoidCallback onCreateNewStep;

  // Callback pour "Insérer une step existante" — ouvre le sélecteur.
  final VoidCallback onInsertExistingStep;

  // État du sélecteur de step existante (affiché ou non).
  final bool insertPickerVisible;

  // Toggle du sélecteur.
  final VoidCallback onTogglePicker;

  // Callback quand l'utilisateur choisit une step existante dans le picker.
  final ValueChanged<String> onPickExistingStep;

  // Liste des steps existantes disponibles pour insertion (exclut la step courante).
  final List<_SimpleOption> availableSteps;

  @override
  Widget build(BuildContext context) {
    final accent = isSelected
        ? EditorChrome.inspectorJoyBlue
        : EditorChrome.inspectorJoyCyan;
    final exitLabel = globalStoryStepExitModeLabel(node.exitMode);
    final destCount = node.links.length;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(left: 16),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: accent.withValues(alpha: isSelected ? 0.12 : 0.04),
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent.withValues(alpha: isSelected ? 0.45 : 0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Numéro d'ordre.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${step.order + 1}',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Nom de la step.
                Expanded(
                  child: Text(
                    step.name,
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                // Badge de type de sortie.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: EditorChrome.inspectorJoyPlum.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    exitLabel,
                    style: TextStyle(
                      color: EditorChrome.inspectorJoyPlum,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isEntryStep) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    CupertinoIcons.location_solid,
                    size: 12,
                    color: EditorChrome.inspectorJoyMint,
                  ),
                ],
              ],
            ),
            // Description courte.
            if (step.description.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                step.description,
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Info de destination.
            if (destCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                destCount == 1
                    ? 'Suite: ${node.links.first.toStepId}'
                    : '$destCount suites possibles',
                style: TextStyle(
                  color: EditorChrome.subtleLabel(context),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // Actions rapides.
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: InspectorEmbeddedSecondaryCapsule(
                    accent: EditorChrome.inspectorJoyPlum,
                    icon: CupertinoIcons.square_stack_3d_up,
                    label: 'Ouvrir Step',
                    enabled: canEdit,
                    onPressed: onOpenStepStudio,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InspectorEmbeddedSecondaryCapsule(
                    accent: EditorChrome.inspectorJoyMint,
                    icon: CupertinoIcons.plus_app,
                    // Libellé EXPLICITE: ce bouton CRÉE une nouvelle step.
                    label: 'Nouvelle',
                    enabled: canEdit,
                    onPressed: onCreateNewStep,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: InspectorEmbeddedSecondaryCapsule(
                    accent: EditorChrome.inspectorJoyBlue,
                    icon: CupertinoIcons.arrow_down_right,
                    // Libellé EXPLICITE: ce bouton insère une step EXISTANTE.
                    label: 'Insérer',
                    enabled: canEdit,
                    onPressed: onInsertExistingStep,
                  ),
                ),
              ],
            ),
            // Sélecteur de step existante (affiché quand l'utilisateur clique
            // sur "Insérer" pour choisir quelle step existante insérer).
            if (insertPickerVisible) ...[
              const SizedBox(height: 6),
              _InsertStepPicker(
                availableSteps: availableSteps,
                onPickStep: onPickExistingStep,
                onCancel: onTogglePicker,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Sélecteur de step existante pour insertion.
///
/// Ce widget est affiché INLINE sous la carte de step quand l'utilisateur
/// clique sur "Insérer". Il propose une liste de steps existantes
/// (excluant la step courante) dans un menu déroulant simple.
///
/// Design:
/// - compact, intégré au style actuel (pas de popup/modale agressive)
/// - dropdown + bouton confirmer + bouton annuler
/// - clairement orienté "structure macro"
class _InsertStepPicker extends StatefulWidget {
  const _InsertStepPicker({
    required this.availableSteps,
    required this.onPickStep,
    required this.onCancel,
  });

  final List<_SimpleOption> availableSteps;
  final ValueChanged<String> onPickStep;
  final VoidCallback onCancel;

  @override
  State<_InsertStepPicker> createState() => _InsertStepPickerState();
}

class _InsertStepPickerState extends State<_InsertStepPicker> {
  String? _selectedStepId;

  @override
  Widget build(BuildContext context) {
    if (widget.availableSteps.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: EditorChrome.subtleLabel(context).withValues(alpha: 0.04),
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: EditorChrome.subtleLabel(context).withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          'Aucune step disponible pour insertion.',
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 11,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Pré-sélectionner la première option par défaut.
    _selectedStepId ??= widget.availableSteps.first.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.06),
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Insérer une step existante après celle-ci',
            style: TextStyle(
              color: EditorChrome.primaryLabel(context),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          // Dropdown de sélection de step.
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 32,
            onPressed: () => _showStepPickerMenu(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: EditorChrome.largeIslandSurfaceColor(
                  context,
                  tint: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.08),
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: EditorChrome.inspectorJoyBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedStepLabel,
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 12,
                    color: EditorChrome.subtleLabel(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: EditorChrome.inspectorJoyBlue,
                  icon: CupertinoIcons.arrow_down_right,
                  label: 'Insérer',
                  enabled: true,
                  onPressed: _confirmSelection,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyCoral,
                  icon: CupertinoIcons.xmark,
                  label: 'Annuler',
                  enabled: true,
                  onPressed: widget.onCancel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _selectedStepLabel {
    final selected = widget.availableSteps
        .where((s) => s.id == _selectedStepId)
        .cast<_SimpleOption?>()
        .firstWhere((s) => s != null, orElse: () => null);
    return selected?.label ?? '—';
  }

  void _showStepPickerMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Choisir une step à insérer'),
        message: Text(
          'Sélectionnez la step existante à insérer après cette step.',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
            fontSize: 12,
          ),
        ),
        actions: widget.availableSteps
            .map(
              (option) => CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _selectedStepId = option.id;
                  });
                  Navigator.of(context).pop();
                },
                child: Text(option.label),
              ),
            )
            .toList(growable: false),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ),
    );
  }

  void _confirmSelection() {
    final selected = _selectedStepId;
    if (selected != null) {
      widget.onPickStep(selected);
    }
  }
}
