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
          .where(
              (id) => stepIds.contains(id) && !allAssignedStepIds.contains(id))
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
    ordered[nextIndex] =
        ordered[nextIndex].copyWith(order: ordered[currentIndex].order);
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

    final nextChapters = globalDoc.chapters.map((c) {
      if (c.id != chapterId) return c;
      return c.copyWith(
        stepIds: c.stepIds.where((id) => id != stepId).toList(),
      );
    }).toList(growable: false);

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
}
