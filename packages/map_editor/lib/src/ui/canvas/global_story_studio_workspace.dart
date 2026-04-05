import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../application/use_cases/project_scenario_use_cases.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/narrative/application/global_story_studio_authoring.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../features/narrative/application/step_studio_authoring.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';
import 'global_story_studio/global_story_studio_shell.dart';

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
  bool _busy = false;

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
    
    // Chapitres triés par [order] : même ordre que la nav / [normalizeGlobalStoryStudioDocument].
    // Sinon le « premier chapitre qui garde un doublon » dépend de l’ordre brut en mémoire
    // et les étapes « sautent » visuellement vers un autre chapitre.
    final sortedChapters = globalDocument.chapters.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    final allAssignedStepIds = <String>{};
    final normalizedChapters = <GlobalStoryChapter>[];

    for (final chapter in sortedChapters) {
      final validStepIds = chapter.stepIds
          .where((id) => stepIds.contains(id) && !allAssignedStepIds.contains(id))
          .toList();

      allAssignedStepIds.addAll(validStepIds);

      normalizedChapters.add(chapter.copyWith(stepIds: validStepIds));
    }

    final unassignedStepIds = stepIds
        .where((id) => !allAssignedStepIds.contains(id))
        .toList(growable: false);

    if (unassignedStepIds.isNotEmpty) {
      final defaultChapterIndex = normalizedChapters.indexWhere(
        (c) => c.id == _defaultChapterId,
      );

      if (defaultChapterIndex >= 0) {
        final existingChapter = normalizedChapters[defaultChapterIndex];
        normalizedChapters[defaultChapterIndex] = existingChapter.copyWith(
          stepIds: <String>[...existingChapter.stepIds, ...unassignedStepIds],
        );
      } else if (normalizedChapters.isEmpty) {
        normalizedChapters.add(GlobalStoryChapter(
          id: _defaultChapterId,
          name: _defaultChapterName,
          description: 'Chapitre par défaut pour les steps non assignées',
          stepIds: unassignedStepIds,
          order: 0,
        ));
      } else {
        // Pas de chapter_main : rattacher au premier chapitre affiché plutôt que
        // d’inventer un bloc « Histoire principale » en queue (effet « tout part au ch.2 »).
        final first = normalizedChapters.first;
        normalizedChapters[0] = first.copyWith(
          stepIds: <String>[...first.stepIds, ...unassignedStepIds],
        );
      }
    }

    final orderedSteps = stepDocument.steps.toList(growable: false)
      ..sort((a, b) => a.order.compareTo(b.order));
    final entryStepId = stepIds.contains(globalDocument.entryStepId)
        ? globalDocument.entryStepId
        : (orderedSteps.isNotEmpty ? orderedSteps.first.id : '');

    final renumberedChapters = normalizedChapters
        .asMap()
        .entries
        .map((e) => e.value.copyWith(order: e.key))
        .toList(growable: false);

    return globalDocument.copyWith(
      entryStepId: entryStepId,
      nodes: nodeMap.values.toList(),
      chapters: renumberedChapters,
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
    
    // Ne pas court-circuiter sur l'égalité des valeurs : la réconciliation peut
    // produire un document == à l'ancien (ex. suppression du seul chapitre qui
    // recrée `chapter_main` à l'identique) alors que l'utilisateur attend une mutation.

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
  void _moveChapter(String chapterId, int delta) {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    if (globalDoc == null || stepDoc == null) return;

    final ordered = globalDoc.chapters.toList(growable: true)
      ..sort((a, b) => a.order.compareTo(b.order));
    final currentIndex = ordered.indexWhere((c) => c.id == chapterId);
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
      id: 'chapter_$chapterCount',
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
  }

  /// Supprime un chapitre. Les étapes qu’il contenait sont **rattachées au premier
  /// chapitre restant** (ordre d’affichage), sinon comportement « un seul chapitre »
  /// comme avant — ainsi elles ne restent pas « en l’air » puis réassignées au mauvais
  /// endroit par la réconciliation.
  void _deleteChapter(String chapterId) {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    if (globalDoc == null || stepDoc == null) return;

    GlobalStoryChapter? victim;
    for (final c in globalDoc.chapters) {
      if (c.id == chapterId) {
        victim = c;
        break;
      }
    }
    if (victim == null) return;
    final chapter = victim;

    final orphanStepIds = List<String>.from(chapter.stepIds);

    final nextChapters = globalDoc.chapters
        .where((c) => c.id != chapterId)
        .toList(growable: false);
    final ordered = nextChapters.toList(growable: true)
      ..sort((a, b) => a.order.compareTo(b.order));
    var normalized = ordered
        .asMap()
        .entries
        .map((e) => e.value.copyWith(order: e.key))
        .toList(growable: false);

    if (normalized.isNotEmpty && orphanStepIds.isNotEmpty) {
      final first = normalized.first;
      normalized = <GlobalStoryChapter>[
        first.copyWith(
          stepIds: <String>[...first.stepIds, ...orphanStepIds],
        ),
        ...normalized.skip(1),
      ];
    }

    if (normalized.isEmpty && stepDoc.steps.isNotEmpty) {
      final orderedSteps = stepDoc.steps.toList(growable: false)
        ..sort((a, b) => a.order.compareTo(b.order));
      final reserved = normalized.map((c) => c.id).toSet();
      normalized = <GlobalStoryChapter>[
        GlobalStoryChapter(
          id: _allocateUniqueChapterId(reserved),
          name: 'Nouveau chapitre',
          description: '',
          stepIds: orderedSteps.map((s) => s.id).toList(growable: false),
          order: 0,
        ),
      ];
    }

    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(chapters: normalized),
    );
  }

  /// Id de chapitre stable du type `chapter_N` absent de [reservedIds].
  String _allocateUniqueChapterId(Set<String> reservedIds) {
    for (var n = 1; n < 100000; n++) {
      final id = 'chapter_$n';
      if (!reservedIds.contains(id)) {
        return id;
      }
    }
    return 'chapter_${DateTime.now().microsecondsSinceEpoch}';
  }

  /// Place [stepId] dans [chapterId] (retirée des autres chapitres), en fin de liste.
  void _addStepToChapter(String chapterId, String stepId) {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    if (globalDoc == null || stepDoc == null) return;
    if (!stepDoc.steps.any((s) => s.id == stepId)) return;

    final strippedChapters = globalDoc.chapters
        .map(
          (c) => c.copyWith(
            stepIds: c.stepIds.where((id) => id != stepId).toList(),
          ),
        )
        .toList(growable: false);

    final chapterIdx = strippedChapters.indexWhere((c) => c.id == chapterId);
    if (chapterIdx < 0) return;

    final chapter = strippedChapters[chapterIdx];
    if (chapter.stepIds.contains(stepId)) return;

    final nextStepIds = <String>[...chapter.stepIds, stepId];
    final nextChapters = strippedChapters
        .asMap()
        .entries
        .map((e) => e.key == chapterIdx
            ? chapter.copyWith(stepIds: nextStepIds)
            : e.value)
        .toList(growable: false);

    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(chapters: nextChapters),
    );
  }

  void _removeStepFromChapter(String chapterId, String stepId) {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    if (globalDoc == null || stepDoc == null) return;

    final nextChapters = globalDoc.chapters
        .map((c) {
          if (c.id != chapterId) return c;
          return c.copyWith(
            stepIds: c.stepIds.where((id) => id != stepId).toList(),
          );
        })
        .toList(growable: false);

    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(chapters: nextChapters),
    );
  }

  void _moveStepInChapter(String chapterId, int fromIndex, int toIndex) {
    final globalDoc = _draftGlobalDocument;
    final stepDoc = _draftStepDocument;
    if (globalDoc == null || stepDoc == null) return;

    final chapterIdx = globalDoc.chapters.indexWhere((c) => c.id == chapterId);
    if (chapterIdx < 0) return;
    final chapter = globalDoc.chapters[chapterIdx];
    if (fromIndex < 0 || fromIndex >= chapter.stepIds.length) return;
    if (toIndex < 0 || toIndex >= chapter.stepIds.length) return;
    if (fromIndex == toIndex) return;

    // L’UI ne propose que des swaps adjacents (↑ / ↓). removeAt + insert sur indices
    // absolus provoquait des inversions avec la réconciliation / longueurs variables.
    final list = List<String>.from(chapter.stepIds);
    final tmp = list[fromIndex];
    list[fromIndex] = list[toIndex];
    list[toIndex] = tmp;

    final nextChapters = globalDoc.chapters
        .asMap()
        .entries
        .map((e) =>
            e.key == chapterIdx ? chapter.copyWith(stepIds: list) : e.value)
        .toList(growable: false);

    _replaceDraftDocuments(
      nextStepDocument: stepDoc,
      nextGlobalDocument: globalDoc.copyWith(chapters: nextChapters),
    );
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

    final strippedChapters = globalDoc.chapters
        .map(
          (c) => c.copyWith(
            stepIds: c.stepIds.where((id) => id != newStepId).toList(),
          ),
        )
        .toList(growable: false);

    final chapterIdx = strippedChapters.indexWhere(
      (c) => c.stepIds.contains(referenceStepId),
    );
    if (chapterIdx < 0) return;

    final chapter = strippedChapters[chapterIdx];
    final inserted = chapterStepIdsInsertingAfterReference(
      chapter.stepIds,
      referenceStepId,
      newStepId,
    );
    final nextStepIds = inserted ?? <String>[...chapter.stepIds, newStepId];

    final nextChapters = strippedChapters
        .asMap()
        .entries
        .map((e) => e.key == chapterIdx
            ? chapter.copyWith(stepIds: nextStepIds)
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
  ///
  /// Cas **même chapitre** : on réordonne uniquement [GlobalStoryChapter.stepIds]
  /// pour refléter l'insertion après `referenceStepId` (l'ordre global des
  /// [StepStudioStep] a déjà été mis à jour par [_insertExistingStepAfter]).
  /// Sans cette étape, l'UI du chapitre restait figée sur l'ancien ordre.
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

    // ── Même chapitre : réordonner stepIds (retirer puis réinsérer après la référence).
    if (sourceChapterIdx == currentChapterIdx) {
      final chapter = globalDoc.chapters[sourceChapterIdx];
      final reordered = reorderChapterStepIdsAfterMovingWithinSameChapter(
        chapter.stepIds,
        referenceStepId: referenceStepId,
        stepIdToMove: stepIdToMove,
      );
      if (reordered == null) return;
      final nextChapters = globalDoc.chapters
          .asMap()
          .entries
          .map((e) => e.key == sourceChapterIdx
              ? chapter.copyWith(stepIds: reordered)
              : e.value)
          .toList(growable: false);
      _replaceDraftDocuments(
        nextStepDocument: stepDoc,
        nextGlobalDocument: globalDoc.copyWith(chapters: nextChapters),
      );
      return;
    }

    final sourceChapter = globalDoc.chapters[sourceChapterIdx];
    final currentChapter = globalDoc.chapters[currentChapterIdx];

    final nextChapters = globalDoc.chapters
        .asMap()
        .entries
        .map((e) {
          if (e.key == currentChapterIdx) {
            return currentChapter.copyWith(
              stepIds: chapterStepIdsRemovingOnce(
                currentChapter.stepIds,
                stepIdToMove,
              ),
            );
          }
          if (e.key == sourceChapterIdx) {
            final newStepIds = chapterStepIdsInsertingAfterReference(
              sourceChapter.stepIds,
              referenceStepId,
              stepIdToMove,
            );
            if (newStepIds == null) {
              return sourceChapter;
            }
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
    // Affichage principal: studio narratif (navigation + fil + détail).
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

  /// Studio Histoire globale : [GlobalStoryStudioShell].
  Widget _buildNarrativeTree({
    required BuildContext context,
    required List<ScenarioAsset> globalStories,
    required StepStudioDocument stepDocument,
    required GlobalStoryStudioDocument globalDocument,
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

    final storylineChoices = <({String id, String label})>[
      for (final s in globalStories)
        (
          id: s.id,
          label: s.name.trim().isEmpty ? s.id : s.name.trim(),
        ),
    ];

    return GlobalStoryStudioShell(
      globalStoryName: globalName,
      storylineChoices: storylineChoices,
      selectedStorylineId: globalStories.length == 1
          ? globalStories.first.id
          : (widget.selectedGlobalStoryId ??
              (globalStories.isNotEmpty ? globalStories.first.id : null)),
      onSelectStoryline: (id) {
        if (id != null && id.trim().isNotEmpty) {
          widget.onSelectGlobalStory(id);
        }
      },
      orderedSteps: orderedSteps,
      chapters: chapters,
      globalDocument: globalDocument,
      projection: widget.projection,
      selectedStepId: _selectedStepId,
      hasUnsavedChanges: _hasUnsavedChanges,
      canEdit: _canEdit,
      warnings: diagnostics,
      showLegacyBanner: _usedStepLegacyFallback || _usedGlobalLegacyFallback,
      onSave: _saveDraft,
      onReset: _resetDraft,
      onAddChapter: _addChapter,
      onDeleteChapter: _deleteChapter,
      onRenameChapter: _renameChapter,
      onMoveChapter: _moveChapter,
      onAddStepToChapter: _addStepToChapter,
      onRemoveStepFromChapter: _removeStepFromChapter,
      onMoveStepInChapter: _moveStepInChapter,
      onSelectStep: _selectStep,
      onOpenStepStudio: widget.onOpenStepStudio,
      onSetEntryStep: _setEntryStep,
      onCreateStep: _addStepAfterSelection,
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
