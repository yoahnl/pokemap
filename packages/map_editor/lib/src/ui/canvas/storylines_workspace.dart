import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/models/editor_workspace_mode.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import 'narrative_studio/narrative_studio_destination.dart';
import 'narrative_studio/narrative_studio_route_presentation.dart';
import 'narrative_studio/narrative_studio_workspace_page.dart';
import 'storylines/storylines_graph_model.dart';
import 'storylines/storylines_graph_view.dart';
import 'storylines/storylines_structure_view.dart';

class StorylinesWorkspace extends ConsumerStatefulWidget {
  const StorylinesWorkspace({
    super.key,
    required this.projection,
    required this.selectedGlobalStoryId,
    this.requestedSelection,
    this.requestedSelectionNonce,
  });

  final NarrativeWorkspaceProjection projection;
  final String? selectedGlobalStoryId;
  final NarrativeStudioAssetSelection? requestedSelection;
  final int? requestedSelectionNonce;

  @override
  ConsumerState<StorylinesWorkspace> createState() =>
      _StorylinesWorkspaceState();
}

class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
  static const _closedChapterSelectionId = '__storylines_closed_chapter__';

  final FocusNode _createStorylineFocusNode = FocusNode(
    debugLabel: 'Storylines create launcher',
  );
  _StorylineContentTab _selectedTab = _StorylineContentTab.graph;
  String? _selectedStorylineId;
  String? _selectedChapterId;
  String? _selectedStepId;
  Object? _lastAppliedSelectionRequest;
  bool _requestedSelectionUnavailable = false;

  @override
  void dispose() {
    _createStorylineFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorNotifierProvider);
    final project = editorState.project;
    final storylines = project?.storylines ?? const <StorylineAsset>[];
    _applyRequestedSelection(storylines);
    if (_requestedSelectionUnavailable) {
      return NarrativeStudioWorkspacePage(
        presentation: narrativeStudioRoutePresentationFor(
          EditorWorkspaceMode.globalStory,
        )!,
        body: PokeMapPageSurface(
          key: const ValueKey('storylines-requested-unavailable'),
          child: PokeMapEmptyState(
            title: 'Cible de storyline introuvable',
            description:
                'La cible ${widget.requestedSelection?.assetId} n’existe plus dans le projet.',
            icon: const Icon(CupertinoIcons.exclamationmark_triangle),
          ),
        ),
      );
    }
    final selectedStoryline = _selectedStoryline(storylines);
    final selectedChapter = _selectedChapter(selectedStoryline);
    final legacyGlobalStory = widget.projection.globalStories.isEmpty
        ? null
        : widget.projection.globalStories.first;
    final legacyStep =
        widget.projection.steps.isEmpty ? null : widget.projection.steps.first;
    final legacyStepCount = widget.projection.steps.length;
    final legacyPreview =
        project == null ? null : buildLegacyGlobalStoryImportPreview(project);
    // Preview stays read-only: only this explicit header action may promote one
    // legacy Global Story, and imported sources disappear from the next choice.
    final pendingLegacyCandidates = legacyPreview == null
        ? const <StorylineLegacyGlobalStoryImportCandidate>[]
        : legacyPreview.candidates.where(
            (candidate) => !storylines.any(
              (storyline) =>
                  storyline.legacySource?.kind == 'scenario.globalStory' &&
                  storyline.legacySource?.sourceId ==
                      candidate.sourceScenarioId &&
                  storyline.legacySource?.metadata['imported'] == 'true',
            ),
          );
    final legacyImportCandidate =
        pendingLegacyCandidates.isEmpty ? null : pendingLegacyCandidates.first;

    return NarrativeStudioWorkspacePage(
      presentation: narrativeStudioRoutePresentationFor(
        EditorWorkspaceMode.globalStory,
      )!,
      actions: [
        if (project != null && legacyImportCandidate != null)
          PokeMapButton(
            key: const ValueKey('storylines-import-legacy-action'),
            onPressed: () => _importLegacyGlobalStory(
              project,
              legacyImportCandidate.sourceScenarioId,
            ),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.compact,
            leading: const Icon(CupertinoIcons.arrow_down_doc, size: 16),
            child: const Text('Importer la Global Story'),
          ),
        PokeMapButton(
          key: const ValueKey('storylines-create-main-cta'),
          focusNode: _createStorylineFocusNode,
          onPressed: project == null
              ? null
              : () => _openCreateStorylineDialog(project),
          variant: PokeMapButtonVariant.success,
          size: PokeMapButtonSize.compact,
          leading: const Icon(CupertinoIcons.plus, size: 16),
          child: const Text('Nouvelle storyline'),
        ),
      ],
      body: PokeMapPageSurface(
        key: const ValueKey('storylines-workspace-shell'),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 240,
              child: _StorylinesV1SecondaryPanel(
                storylines: storylines,
                selectedStorylineId: selectedStoryline?.id,
                legacyGlobalStory: legacyGlobalStory,
                onStorylineSelected: _selectStoryline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StorylinesV1MainPanel(
                project: project,
                selectedStoryline: selectedStoryline,
                selectedChapter: selectedChapter,
                selectedStepId: _selectedStepId,
                storylines: storylines,
                selectedTab: _selectedTab,
                legacyGlobalStory: legacyGlobalStory,
                legacyStep: legacyStep,
                legacyStepCount: legacyStepCount,
                onTabSelected: _selectTab,
                onChapterSelected: _selectChapter,
                onCreateChapter: project == null || selectedStoryline == null
                    ? null
                    : () =>
                        _openCreateChapterDialog(project, selectedStoryline),
                onEditChapter: project == null || selectedStoryline == null
                    ? null
                    : (chapter) => _openEditChapterDialog(
                          project,
                          selectedStoryline,
                          chapter,
                        ),
                onDuplicateChapter: project == null || selectedStoryline == null
                    ? null
                    : (chapter) => _duplicateChapter(
                          project,
                          selectedStoryline,
                          chapter,
                        ),
                onMoveChapter: project == null || selectedStoryline == null
                    ? null
                    : (chapter, direction) => _moveChapter(
                          project,
                          selectedStoryline,
                          chapter,
                          direction,
                        ),
                onCreateStep: project == null ||
                        selectedStoryline == null ||
                        selectedChapter == null
                    ? null
                    : () => _openCreateStepDialog(
                          project,
                          selectedStoryline,
                          selectedChapter,
                        ),
                onEditStep: project == null || selectedStoryline == null
                    ? null
                    : (chapter, step) => _openEditStepDialog(
                          project,
                          selectedStoryline,
                          chapter,
                          step,
                        ),
                onReorderSteps: project == null || selectedStoryline == null
                    ? null
                    : (chapter, oldIndex, newIndex) => _reorderSteps(
                          project,
                          selectedStoryline,
                          chapter,
                          oldIndex,
                          newIndex,
                        ),
                onAttachSideQuest: project == null ||
                        selectedStoryline == null ||
                        selectedStoryline.type != StorylineType.sideQuest
                    ? null
                    : () => _openAttachSideQuestDialog(
                          project,
                          selectedStoryline,
                        ),
                onGraphConnect: project == null || selectedStoryline == null
                    ? null
                    : (request) => _connectGraphEdge(project, request),
                onGraphDisconnect: project == null || selectedStoryline == null
                    ? null
                    : (edgeId) => _disconnectGraphEdge(
                          project,
                          selectedStoryline.id,
                          edgeId,
                        ),
                onGraphNodeSelected: _selectGraphNode,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 280,
              child: _StorylinesV1InspectorPanel(
                selectedStoryline: selectedStoryline,
                selectedChapter: selectedChapter,
                onEdit: project == null || selectedStoryline == null
                    ? null
                    : () => _openEditStorylineDialog(
                          project,
                          selectedStoryline,
                        ),
                onDuplicate: project == null || selectedStoryline == null
                    ? null
                    : () => _duplicateSelectedStoryline(
                          project,
                          selectedStoryline,
                        ),
                onArchive: project == null || selectedStoryline == null
                    ? null
                    : () => _archiveSelectedStoryline(
                          project,
                          selectedStoryline,
                        ),
                onDelete: project == null || selectedStoryline == null
                    ? null
                    : () => _deleteSelectedStoryline(
                          project,
                          selectedStoryline,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  StorylineAsset? _selectedStoryline(List<StorylineAsset> storylines) {
    final targetId = _selectedStorylineId;
    if (targetId != null) {
      for (final storyline in storylines) {
        if (storyline.id == targetId) {
          return storyline;
        }
      }
    }
    return storylines.isEmpty ? null : storylines.first;
  }

  StorylineChapter? _selectedChapter(StorylineAsset? storyline) {
    if (storyline == null || storyline.chapters.isEmpty) {
      return null;
    }
    final targetId = _selectedChapterId;
    if (targetId == _closedChapterSelectionId) {
      return null;
    }
    if (targetId != null) {
      for (final chapter in storyline.chapters) {
        if (chapter.id == targetId) {
          return chapter;
        }
      }
    }
    return storyline.chapters.first;
  }

  void _applyRequestedSelection(List<StorylineAsset> storylines) {
    final request = (
      widget.requestedSelection,
      widget.requestedSelectionNonce,
    );
    final selection = widget.requestedSelection;
    if (selection == null) {
      _requestedSelectionUnavailable = false;
      _lastAppliedSelectionRequest = request;
      return;
    }

    StorylineAsset? selectedStoryline;
    StorylineChapter? selectedChapter;
    StorylineStep? selectedStep;
    switch (selection.kind) {
      case NarrativeStudioAssetKind.storyline:
        selectedStoryline = _findStoryline(storylines, selection.assetId);
      case NarrativeStudioAssetKind.chapter:
        final expectedStorylineId = selection.parentId;
        for (final storyline in storylines) {
          if (expectedStorylineId != null &&
              storyline.id != expectedStorylineId) {
            continue;
          }
          final chapter = _findChapter(storyline, selection.assetId);
          if (chapter != null) {
            selectedStoryline = storyline;
            selectedChapter = chapter;
            break;
          }
        }
      case NarrativeStudioAssetKind.step:
        final expectedStorylineId = selection.rootId;
        final expectedChapterId = selection.parentId;
        for (final storyline in storylines) {
          if (expectedStorylineId != null &&
              storyline.id != expectedStorylineId) {
            continue;
          }
          for (final chapter in storyline.chapters) {
            if (expectedChapterId != null && chapter.id != expectedChapterId) {
              continue;
            }
            final step = _findStep(chapter, selection.assetId);
            if (step != null) {
              selectedStoryline = storyline;
              selectedChapter = chapter;
              selectedStep = step;
              break;
            }
          }
          if (selectedStep != null) break;
        }
      case NarrativeStudioAssetKind.scene ||
            NarrativeStudioAssetKind.event ||
            NarrativeStudioAssetKind.cinematic ||
            NarrativeStudioAssetKind.dialogue ||
            NarrativeStudioAssetKind.fact ||
            NarrativeStudioAssetKind.worldRule ||
            NarrativeStudioAssetKind.map ||
            NarrativeStudioAssetKind.diagnostic:
        _requestedSelectionUnavailable = true;
        _selectedStorylineId = null;
        _selectedChapterId = null;
        _selectedStepId = null;
        _lastAppliedSelectionRequest = request;
        return;
    }
    if (selectedStoryline == null) {
      _requestedSelectionUnavailable = true;
      _selectedStorylineId = null;
      _selectedChapterId = null;
      _selectedStepId = null;
      _lastAppliedSelectionRequest = request;
      return;
    }
    _requestedSelectionUnavailable = false;
    if (_lastAppliedSelectionRequest == request) return;
    _lastAppliedSelectionRequest = request;

    _selectedStorylineId = selectedStoryline.id;
    if (selectedChapter == null) {
      _selectedChapterId = selectedStoryline.chapters.isEmpty
          ? null
          : selectedStoryline.chapters.first.id;
      _selectedStepId = null;
      _selectedTab = _StorylineContentTab.graph;
      return;
    }
    _selectedChapterId = selectedChapter.id;
    _selectedStepId = selectedStep?.id;
    _selectedTab = _StorylineContentTab.structure;
  }

  void _selectStoryline(StorylineAsset storyline) {
    if (_selectedStorylineId == storyline.id) {
      return;
    }
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId =
          storyline.chapters.isEmpty ? null : storyline.chapters.first.id;
      _selectedStepId = null;
    });
  }

  void _selectChapter(StorylineChapter? chapter) {
    final nextChapterId = chapter?.id ?? _closedChapterSelectionId;
    if (_selectedChapterId == nextChapterId) {
      return;
    }
    setState(() {
      _selectedChapterId = nextChapterId;
      _selectedStepId = null;
    });
  }

  void _selectTab(_StorylineContentTab tab) {
    if (_selectedTab == tab) {
      return;
    }
    setState(() {
      _selectedTab = tab;
    });
  }

  Future<void> _openCreateStorylineDialog(ProjectManifest project) async {
    final draft = await showCupertinoDialog<_CreateStorylineDraft>(
      context: context,
      builder: (context) => _CreateStorylineDialog(
        storylines: project.storylines,
      ),
    );
    if (mounted) {
      _createStorylineFocusNode.requestFocus();
    }
    if (draft == null || !mounted) {
      return;
    }
    final storyline = StorylineAsset(
      id: _generateStorylineId(draft.title, draft.type, project.storylines),
      type: draft.type,
      status: StorylineStatus.draft,
      title: draft.title,
      description: draft.description,
    );
    final result = createStoryline(project, storyline: storyline);
    if (!result.isApplied) {
      await _showStorylineMutationFailure(result);
      return;
    }
    _applyStorylineMutation(
      result,
      statusMessage: 'Storyline créée',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = null;
      _selectedTab = draft.type == StorylineType.sideQuest
          ? _StorylineContentTab.structure
          : _StorylineContentTab.graph;
    });
  }

  Future<void> _importLegacyGlobalStory(
    ProjectManifest project,
    String sourceScenarioId,
  ) async {
    final result = applyLegacyGlobalStoryImport(
      project,
      sourceScenarioId: sourceScenarioId,
    );
    if (result.disposition == StorylineLegacyImportDisposition.rejected) {
      await _showStorylineMessage(
        title: 'Import impossible',
        message: result.message ?? 'La Global Story ne peut pas être importée.',
      );
      return;
    }
    final imported = result.importedStoryline;
    if (result.disposition != StorylineLegacyImportDisposition.imported ||
        imported == null) {
      return;
    }
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          result.after,
          statusMessage: 'Global Story importée explicitement',
        );
    setState(() {
      _selectedStorylineId = imported.id;
      _selectedChapterId =
          imported.chapters.isEmpty ? null : imported.chapters.first.id;
      _selectedStepId = null;
      _selectedTab = _StorylineContentTab.graph;
    });
  }

  Future<void> _openEditStorylineDialog(
    ProjectManifest project,
    StorylineAsset storyline,
  ) async {
    final draft = await showCupertinoDialog<_StorylineEditDraft>(
      context: context,
      builder: (context) => _EditStorylineDialog(storyline: storyline),
    );
    if (draft == null || !mounted) return;
    final result = updateStoryline(
      project,
      storylineId: storyline.id,
      storyline: storyline.copyWith(
        type: draft.type,
        status: draft.status,
        title: draft.title,
        description: draft.description,
        authorNotes: draft.authorNotes,
      ),
    );
    if (!result.isApplied) {
      if (result.disposition == StorylineMutationDisposition.rejected) {
        await _showStorylineMutationFailure(result);
      }
      return;
    }
    _applyStorylineMutation(result, statusMessage: 'Storyline modifiée');
  }

  Future<void> _duplicateSelectedStoryline(
    ProjectManifest project,
    StorylineAsset storyline,
  ) async {
    final title = '${storyline.title} (copie)';
    final result = duplicateStoryline(
      project,
      storylineId: storyline.id,
      duplicateId:
          _generateStorylineId(title, storyline.type, project.storylines),
      title: title,
    );
    if (!result.isApplied || result.storyline == null) {
      await _showStorylineMutationFailure(result);
      return;
    }
    _applyStorylineMutation(result, statusMessage: 'Storyline dupliquée');
    setState(() {
      _selectedStorylineId = result.storyline!.id;
      _selectedChapterId = result.storyline!.chapters.isEmpty
          ? null
          : result.storyline!.chapters.first.id;
      _selectedStepId = null;
    });
  }

  Future<void> _archiveSelectedStoryline(
    ProjectManifest project,
    StorylineAsset storyline,
  ) async {
    final result = archiveStoryline(project, storylineId: storyline.id);
    if (result.disposition == StorylineMutationDisposition.rejected) {
      await _showStorylineMutationFailure(result);
      return;
    }
    if (result.isApplied) {
      _applyStorylineMutation(result, statusMessage: 'Storyline archivée');
    }
  }

  Future<void> _deleteSelectedStoryline(
    ProjectManifest project,
    StorylineAsset storyline,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => _ConfirmStructureDeleteDialog(
        title: 'Supprimer la storyline',
        message:
            'La storyline "${storyline.title}" sera supprimée uniquement si aucun élément narratif ne la référence.',
      ),
    );
    if (confirmed != true || !mounted) return;
    final result = deleteStoryline(project, storylineId: storyline.id);
    if (!result.isApplied) {
      await _showStorylineMutationFailure(result);
      return;
    }
    _applyStorylineMutation(result, statusMessage: 'Storyline supprimée');
    final remaining = result.after.storylines;
    setState(() {
      _selectedStorylineId = remaining.isEmpty ? null : remaining.first.id;
      _selectedChapterId = remaining.isEmpty || remaining.first.chapters.isEmpty
          ? null
          : remaining.first.chapters.first.id;
      _selectedStepId = null;
    });
  }

  void _applyStorylineMutation(
    StorylineMutationResult result, {
    required String statusMessage,
  }) {
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          result.after,
          statusMessage: statusMessage,
        );
  }

  Future<bool> _connectGraphEdge(
    ProjectManifest project,
    StorylineProgressionConnectRequest request,
  ) async {
    final result = connectStorylineProgressionEdge(project, request);
    if (result.disposition != StorylineProgressionMutationDisposition.applied) {
      await _showStorylineMessage(
        title: 'Connexion impossible',
        message: result.message ?? 'La relation canonique a été refusée.',
      );
      return false;
    }
    return ref.read(editorNotifierProvider.notifier).applyNarrativeDocumentEdit(
          result.after,
          operationId:
              'storyline_graph_connect_${DateTime.now().microsecondsSinceEpoch}',
          label: 'Connecter une relation de progression Storyline',
          statusMessage: 'Relation de progression connectée.',
        );
  }

  Future<bool> _disconnectGraphEdge(
    ProjectManifest project,
    String storylineId,
    String edgeId,
  ) async {
    final result = disconnectStorylineProgressionEdge(
      project,
      storylineId: storylineId,
      edgeId: edgeId,
    );
    if (result.disposition != StorylineProgressionMutationDisposition.applied) {
      await _showStorylineMessage(
        title: result.code == 'edgeReadOnly'
            ? 'Relation en lecture seule'
            : 'Déconnexion impossible',
        message: result.message ?? 'La relation canonique a été refusée.',
      );
      return false;
    }
    return ref.read(editorNotifierProvider.notifier).applyNarrativeDocumentEdit(
          result.after,
          operationId:
              'storyline_graph_disconnect_${DateTime.now().microsecondsSinceEpoch}',
          label: 'Déconnecter une relation de progression Storyline',
          statusMessage: 'Relation de progression déconnectée.',
        );
  }

  void _selectGraphNode(StorylineGraphNode node) {
    if (!mounted) return;
    setState(() {
      if (node.kind == StorylineGraphNodeKind.chapter) {
        _selectedChapterId = node.canonicalId;
        _selectedStepId = null;
      } else if (node.kind == StorylineGraphNodeKind.step) {
        _selectedChapterId = node.chapterId;
        _selectedStepId = node.canonicalId;
      }
    });
  }

  Future<void> _showStorylineMutationFailure(
    StorylineMutationResult result,
  ) {
    final consumers = result.referencePaths.isEmpty
        ? ''
        : '\n\nConsommateurs :\n${result.referencePaths.join('\n')}';
    return _showStorylineMessage(
      title: result.code == 'storylineReferenced'
          ? 'Suppression protégée'
          : 'Modification impossible',
      message:
          '${result.message ?? 'La modification a été refusée.'}$consumers',
    );
  }

  Future<void> _showStorylineMessage({
    required String title,
    required String message,
  }) {
    return showCupertinoDialog<void>(
      context: context,
      builder: (context) => _StorylineMessageDialog(
        title: title,
        message: message,
      ),
    );
  }

  Future<void> _openCreateChapterDialog(
    ProjectManifest project,
    StorylineAsset storyline,
  ) async {
    final draft = await showCupertinoDialog<_StructureItemDraft>(
      context: context,
      builder: (context) => const _CreateStructureItemDialog(
        dialogKey: ValueKey('storylines-create-chapter-dialog'),
        title: 'Nouveau chapitre',
        titleFieldKey: ValueKey('storylines-create-chapter-title-field'),
        descriptionFieldKey: ValueKey(
          'storylines-create-chapter-description-field',
        ),
        cancelKey: ValueKey('storylines-create-chapter-cancel'),
        submitKey: ValueKey('storylines-create-chapter-submit'),
        showLifecycleFields: true,
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final chapter = StorylineChapter(
      id: _generateScopedId(
        prefix: 'chapter',
        title: draft.title,
        existingIds: storyline.chapters.map((chapter) => chapter.id).toSet(),
      ),
      title: draft.title,
      description: draft.description,
      order: _nextChapterOrder(storyline),
      status: draft.status,
      authorNotes: draft.authorNotes,
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: [...storyline.chapters, chapter],
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Chapitre créé',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _openCreateStepDialog(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
  ) async {
    final draft = await showCupertinoDialog<_StorylineStepDraft>(
      context: context,
      builder: (context) => _StorylineStepEditorDialog(
        project: project,
        storyline: storyline,
        initialChapterId: chapter.id,
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final targetChapter = storyline.chapters.singleWhere(
      (item) => item.id == draft.targetChapterId,
      orElse: () => chapter,
    );
    final step = StorylineStep(
      id: _generateScopedId(
        prefix: 'step',
        title: draft.title,
        existingIds: _storylineStepIds(storyline),
      ),
      title: draft.title,
      description: draft.description,
      order: _nextStepOrder(targetChapter),
      entryCondition: draft.entryCondition,
      completionCondition: draft.completionCondition,
      sceneLinkIds: draft.sceneLinkIds,
      expectedOutcomeIds: draft.expectedOutcomeIds,
      status: draft.status,
      authorNotes: draft.authorNotes,
    );
    final updatedChapter = _copyChapterWith(
      targetChapter,
      steps: [...targetChapter.steps, step],
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) =>
                current.id == targetChapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Étape narrative créée',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = targetChapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _openEditChapterDialog(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
  ) async {
    final draft = await showCupertinoDialog<_StructureItemDraft>(
      context: context,
      builder: (context) => _CreateStructureItemDialog(
        dialogKey: const ValueKey('storylines-edit-chapter-dialog'),
        title: 'Modifier le chapitre',
        titleFieldKey: const ValueKey('storylines-edit-chapter-title-field'),
        descriptionFieldKey: const ValueKey(
          'storylines-edit-chapter-description-field',
        ),
        cancelKey: const ValueKey('storylines-edit-chapter-cancel'),
        submitKey: const ValueKey('storylines-edit-chapter-submit'),
        deleteKey: const ValueKey('storylines-edit-chapter-delete-action'),
        initialTitle: chapter.title,
        initialDescription: chapter.description,
        initialStatus: chapter.status,
        initialAuthorNotes: chapter.authorNotes,
        showLifecycleFields: true,
        submitLabel: 'Enregistrer',
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    if (draft.deleteRequested) {
      await _deleteChapter(project, storyline, chapter);
      return;
    }
    final result = updateStorylineChapter(
      project,
      storylineId: storyline.id,
      chapterId: chapter.id,
      chapter: chapter.copyWith(
        title: draft.title,
        description: draft.description,
        status: draft.status,
        authorNotes: draft.authorNotes,
      ),
    );
    if (!result.isApplied) {
      if (result.disposition == StorylineMutationDisposition.rejected) {
        await _showStorylineMutationFailure(result);
      }
      return;
    }
    _applyStorylineMutation(result, statusMessage: 'Chapitre modifié');
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _deleteChapter(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => _ConfirmStructureDeleteDialog(
        title: 'Supprimer le chapitre',
        message:
            'Le chapitre "${chapter.title}" et ses étapes narratives seront retirés de cette storyline.',
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final removedIndex =
        storyline.chapters.indexWhere((current) => current.id == chapter.id);
    final result = deleteStorylineChapter(
      project,
      storylineId: storyline.id,
      chapterId: chapter.id,
    );
    if (!result.isApplied || result.storyline == null) {
      await _showStorylineMutationFailure(result);
      return;
    }
    _applyStorylineMutation(result, statusMessage: 'Chapitre supprimé');
    final normalized = result.storyline!.chapters;
    setState(() {
      _selectedStorylineId = storyline.id;
      if (normalized.isEmpty) {
        _selectedChapterId = null;
      } else {
        final nextIndex = removedIndex >= normalized.length
            ? normalized.length - 1
            : removedIndex;
        _selectedChapterId = normalized[nextIndex].id;
      }
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _duplicateChapter(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
  ) async {
    final duplicateTitle = '${chapter.title} (copie)';
    final result = duplicateStorylineChapter(
      project,
      storylineId: storyline.id,
      chapterId: chapter.id,
      duplicateChapterId: _generateScopedId(
        prefix: 'chapter',
        title: duplicateTitle,
        existingIds: storyline.chapters.map((item) => item.id).toSet(),
      ),
      title: duplicateTitle,
    );
    if (!result.isApplied || result.chapter == null) {
      await _showStorylineMutationFailure(result);
      return;
    }
    _applyStorylineMutation(result, statusMessage: 'Chapitre dupliqué');
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = result.chapter!.id;
      _selectedStepId = null;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  void _moveChapter(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
    int direction,
  ) {
    final chapters = [...storyline.chapters]
      ..sort((left, right) => left.order.compareTo(right.order));
    final index = chapters.indexWhere((item) => item.id == chapter.id);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= chapters.length) return;
    final moved = chapters.removeAt(index);
    chapters.insert(target, moved);
    final result = reorderStorylineChapters(
      project,
      storylineId: storyline.id,
      orderedChapterIds:
          chapters.map((item) => item.id).toList(growable: false),
    );
    if (!result.isApplied) return;
    _applyStorylineMutation(result, statusMessage: 'Chapitres réordonnés');
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _openEditStepDialog(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
    StorylineStep step,
  ) async {
    final draft = await showCupertinoDialog<_StorylineStepDraft>(
      context: context,
      builder: (context) => _StorylineStepEditorDialog(
        project: project,
        storyline: storyline,
        initialChapterId: chapter.id,
        step: step,
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    if (draft.deleteRequested) {
      await _deleteStep(project, storyline, chapter, step);
      return;
    }
    if (draft.duplicateRequested) {
      final duplicateTitle = '${step.title} (copie)';
      final result = duplicateStorylineStep(
        project,
        storylineId: storyline.id,
        chapterId: chapter.id,
        stepId: step.id,
        duplicateStepId: _generateScopedId(
          prefix: 'step',
          title: duplicateTitle,
          existingIds: _storylineStepIds(storyline),
        ),
        title: duplicateTitle,
      );
      if (!result.isApplied || result.step == null) {
        await _showStorylineMutationFailure(result);
        return;
      }
      _applyStorylineMutation(result, statusMessage: 'Étape dupliquée');
      setState(() {
        _selectedStorylineId = storyline.id;
        _selectedChapterId = chapter.id;
        _selectedStepId = result.step!.id;
        _selectedTab = _StorylineContentTab.structure;
      });
      return;
    }
    final update = updateStorylineStep(
      project,
      storylineId: storyline.id,
      chapterId: chapter.id,
      stepId: step.id,
      step: step.copyWith(
        title: draft.title,
        description: draft.description,
        entryCondition: draft.entryCondition,
        completionCondition: draft.completionCondition,
        sceneLinkIds: draft.sceneLinkIds,
        expectedOutcomeIds: draft.expectedOutcomeIds,
        status: draft.status,
        authorNotes: draft.authorNotes,
      ),
    );
    if (update.disposition == StorylineMutationDisposition.rejected) {
      await _showStorylineMutationFailure(update);
      return;
    }
    var result = update;
    if (draft.targetChapterId != chapter.id) {
      final moveSource = update.after;
      final targetChapter = update.storyline!.chapters.singleWhere(
        (item) => item.id == draft.targetChapterId,
      );
      result = moveStorylineStep(
        moveSource,
        storylineId: storyline.id,
        sourceChapterId: chapter.id,
        targetChapterId: targetChapter.id,
        stepId: step.id,
        targetIndex: targetChapter.steps.length,
      );
      if (!result.isApplied) {
        await _showStorylineMutationFailure(result);
        return;
      }
    }
    if (result.isApplied) {
      _applyStorylineMutation(
        result,
        statusMessage: draft.targetChapterId == chapter.id
            ? 'Étape narrative modifiée'
            : 'Étape déplacée et modifiée',
      );
    }
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = draft.targetChapterId;
      _selectedStepId = step.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _deleteStep(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
    StorylineStep step,
  ) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => _ConfirmStructureDeleteDialog(
        title: 'Supprimer l’étape narrative',
        message:
            'L’étape "${step.title}" sera retirée de ce chapitre sans créer ni supprimer de scène.',
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final result = deleteStorylineStep(
      project,
      storylineId: storyline.id,
      chapterId: chapter.id,
      stepId: step.id,
    );
    if (!result.isApplied) {
      await _showStorylineMutationFailure(result);
      return;
    }
    _applyStorylineMutation(result, statusMessage: 'Étape narrative supprimée');
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  void _reorderSteps(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
    int oldIndex,
    int newIndex,
  ) {
    final steps = _orderedStepsForMutation(chapter);
    if (oldIndex < 0 || oldIndex >= steps.length) {
      return;
    }
    var targetIndex = newIndex;
    if (targetIndex < 0) {
      targetIndex = 0;
    }
    if (targetIndex >= steps.length) {
      targetIndex = steps.length - 1;
    }
    final moved = steps.removeAt(oldIndex);
    steps.insert(targetIndex, moved);
    final result = reorderStorylineSteps(
      project,
      storylineId: storyline.id,
      chapterId: chapter.id,
      orderedStepIds: steps.map((step) => step.id).toList(growable: false),
    );
    if (!result.isApplied) return;
    _applyStorylineMutation(
      result,
      statusMessage: 'Étapes narratives réordonnées',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
      _selectedTab = _StorylineContentTab.structure;
    });
  }

  Future<void> _openAttachSideQuestDialog(
    ProjectManifest project,
    StorylineAsset sideQuest,
  ) async {
    if (_sideQuestMainAttachment(sideQuest) != null) {
      return;
    }
    final draft = await showCupertinoDialog<_SideQuestAttachmentDraft>(
      context: context,
      builder: (context) => _AttachSideQuestDialog(
        sideQuest: sideQuest,
        storylines: project.storylines,
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final anchor = StorylineAnchor(
      kind: draft.anchor.kind,
      targetId: draft.anchor.targetId,
    );
    final relationship = StorylineRelationship(
      id: _generateRelationshipId(
        sideQuest,
        draft.mainStoryline,
        anchor,
      ),
      kind: StorylineRelationshipKind.sideQuestAvailableDuring,
      sourceStorylineId: sideQuest.id,
      targetStorylineId: draft.mainStoryline.id,
      anchor: anchor,
      availability: SideQuestAvailability(startAnchor: anchor),
      notes: 'Side quest available from ${draft.anchor.label}.',
    );
    final updatedSideQuest = _copyStorylineWith(
      sideQuest,
      relationships: [...sideQuest.relationships, relationship],
    );
    _applyStorylineUpdate(
      project,
      updatedSideQuest,
      statusMessage: 'Quête annexe attachée',
    );
    setState(() {
      _selectedStorylineId = sideQuest.id;
      _selectedChapterId =
          sideQuest.chapters.isEmpty ? null : sideQuest.chapters.first.id;
      _selectedTab = _StorylineContentTab.graph;
    });
  }

  String _generateStorylineId(
    String title,
    StorylineType type,
    List<StorylineAsset> storylines,
  ) {
    final existingIds = storylines.map((storyline) => storyline.id).toSet();
    return _generateScopedId(
      prefix: type == StorylineType.sideQuest ? 'sidequest' : 'storyline',
      title: title,
      existingIds: existingIds,
      fallback: type == StorylineType.sideQuest ? 'sidequest' : 'main',
    );
  }

  String _generateRelationshipId(
    StorylineAsset sideQuest,
    StorylineAsset mainStoryline,
    StorylineAnchor anchor,
  ) {
    final existingIds =
        sideQuest.relationships.map((relationship) => relationship.id).toSet();
    return _generateScopedId(
      prefix: 'sidequest_attach',
      title: '${sideQuest.id}_${mainStoryline.id}_${anchor.targetId}',
      existingIds: existingIds,
      fallback: 'main',
    );
  }

  String _generateScopedId({
    required String prefix,
    required String title,
    required Set<String> existingIds,
    String fallback = 'item',
  }) {
    final slug = _slugifyStorylineTitle(title);
    final base = '${prefix}_${slug.isEmpty ? fallback : slug}';
    if (!existingIds.contains(base)) {
      return base;
    }
    var suffix = 2;
    while (existingIds.contains('${base}_$suffix')) {
      suffix += 1;
    }
    return '${base}_$suffix';
  }

  Set<String> _storylineStepIds(StorylineAsset storyline) {
    return {
      for (final chapter in storyline.chapters)
        for (final step in chapter.steps) step.id,
    };
  }

  int _nextChapterOrder(StorylineAsset storyline) {
    var nextOrder = 0;
    for (final chapter in storyline.chapters) {
      if (chapter.order >= nextOrder) {
        nextOrder = chapter.order + 1;
      }
    }
    return nextOrder;
  }

  int _nextStepOrder(StorylineChapter chapter) {
    var nextOrder = 0;
    for (final step in chapter.steps) {
      if (step.order >= nextOrder) {
        nextOrder = step.order + 1;
      }
    }
    return nextOrder;
  }

  void _applyStorylineUpdate(
    ProjectManifest project,
    StorylineAsset updatedStoryline, {
    required String statusMessage,
  }) {
    final updated = project.copyWith(
      storylines: project.storylines
          .map(
            (storyline) => storyline.id == updatedStoryline.id
                ? updatedStoryline
                : storyline,
          )
          .toList(growable: false),
    );
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          updated,
          statusMessage: statusMessage,
        );
  }

  String _slugifyStorylineTitle(String title) {
    final normalized = title.trim().toLowerCase();
    final buffer = StringBuffer();
    var lastWasSeparator = false;
    for (final rune in normalized.runes) {
      final char = String.fromCharCode(rune);
      final replacement = switch (char) {
        'à' || 'á' || 'â' || 'ä' || 'ã' || 'å' => 'a',
        'ç' => 'c',
        'è' || 'é' || 'ê' || 'ë' => 'e',
        'ì' || 'í' || 'î' || 'ï' => 'i',
        'ñ' => 'n',
        'ò' || 'ó' || 'ô' || 'ö' || 'õ' => 'o',
        'ù' || 'ú' || 'û' || 'ü' => 'u',
        'ý' || 'ÿ' => 'y',
        _ => char,
      };
      final isAlphaNumeric = RegExp(r'[a-z0-9]').hasMatch(replacement);
      if (isAlphaNumeric) {
        buffer.write(replacement);
        lastWasSeparator = false;
      } else if (!lastWasSeparator && buffer.isNotEmpty) {
        buffer.write('_');
        lastWasSeparator = true;
      }
    }
    return buffer.toString().replaceAll(RegExp(r'_+$'), '');
  }
}

StorylineAsset _copyStorylineWith(
  StorylineAsset storyline, {
  List<StorylineChapter>? chapters,
  List<StorylineRelationship>? relationships,
}) {
  return StorylineAsset(
    id: storyline.id,
    schemaVersion: storyline.schemaVersion,
    type: storyline.type,
    status: storyline.status,
    title: storyline.title,
    description: storyline.description,
    sortOrder: storyline.sortOrder,
    locale: storyline.locale,
    chapters: chapters ?? storyline.chapters,
    sceneLinks: storyline.sceneLinks,
    relationships: relationships ?? storyline.relationships,
    legacySource: storyline.legacySource,
    authorNotes: storyline.authorNotes,
    metadata: storyline.metadata,
  );
}

StorylineChapter _copyChapterWith(
  StorylineChapter chapter, {
  String? title,
  String? description,
  bool replaceDescription = false,
  int? order,
  List<StorylineStep>? steps,
}) {
  return StorylineChapter(
    id: chapter.id,
    title: title ?? chapter.title,
    description:
        replaceDescription ? description : description ?? chapter.description,
    order: order ?? chapter.order,
    steps: steps ?? chapter.steps,
    directSceneLinkIds: chapter.directSceneLinkIds,
    status: chapter.status,
    authorNotes: chapter.authorNotes,
    metadata: chapter.metadata,
  );
}

List<StorylineStep> _orderedStepsForMutation(StorylineChapter chapter) {
  return [...chapter.steps]..sort(_compareStepsByAuthorOrder);
}

int _storylineStepCount(StorylineAsset storyline) {
  return storyline.chapters.fold<int>(
    0,
    (total, chapter) => total + chapter.steps.length,
  );
}

int _chapterSceneLinkCount(StorylineChapter chapter) {
  return chapter.directSceneLinkIds.length +
      chapter.steps.fold<int>(
        0,
        (total, step) => total + step.sceneLinkIds.length,
      );
}

String _formatCount(int count, String singular, String plural) {
  return '$count ${count == 1 ? singular : plural}';
}

StorylineRelationship? _sideQuestMainAttachment(StorylineAsset storyline) {
  if (storyline.type != StorylineType.sideQuest) {
    return null;
  }
  for (final relationship in storyline.relationships) {
    if (relationship.kind ==
            StorylineRelationshipKind.sideQuestAvailableDuring ||
        relationship.kind == StorylineRelationshipKind.sideQuestUnlockedBy) {
      return relationship;
    }
  }
  return null;
}

String _sideQuestAttachmentStatus(StorylineAsset storyline) {
  return _sideQuestMainAttachment(storyline) == null
      ? 'Non reliée au graph principal'
      : 'Reliée au graph principal';
}

List<_SideQuestAnchorChoice> _anchorChoicesFor(StorylineAsset mainStoryline) {
  final chapters = [...mainStoryline.chapters]
    ..sort(_compareChaptersByAuthorOrder);
  return [
    for (final chapter in chapters) ...[
      _SideQuestAnchorChoice(
        kind: StorylineAnchorKind.chapter,
        targetId: chapter.id,
        label: 'Chapitre · ${chapter.title}',
        description: 'Disponible au début de ce chapitre.',
      ),
      for (final step in ([...chapter.steps]..sort(_compareStepsByAuthorOrder)))
        _SideQuestAnchorChoice(
          kind: StorylineAnchorKind.step,
          targetId: step.id,
          label: 'Étape · ${step.title}',
          description: 'Disponible à cette étape narrative.',
        ),
    ],
  ];
}

String _anchorKey(_SideQuestAnchorChoice anchor) {
  return '${anchor.kind.name}-${anchor.targetId}';
}

int _compareChaptersByAuthorOrder(
  StorylineChapter left,
  StorylineChapter right,
) {
  final order = left.order.compareTo(right.order);
  if (order != 0) return order;
  final title = left.title.compareTo(right.title);
  if (title != 0) return title;
  return left.id.compareTo(right.id);
}

int _compareStepsByAuthorOrder(StorylineStep left, StorylineStep right) {
  final order = left.order.compareTo(right.order);
  if (order != 0) return order;
  final title = left.title.compareTo(right.title);
  if (title != 0) return title;
  return left.id.compareTo(right.id);
}

StorylineAsset? _findStoryline(
  List<StorylineAsset> storylines,
  String storylineId,
) {
  for (final storyline in storylines) {
    if (storyline.id == storylineId) return storyline;
  }
  return null;
}

StorylineChapter? _findChapter(
  StorylineAsset storyline,
  String chapterId,
) {
  for (final chapter in storyline.chapters) {
    if (chapter.id == chapterId) return chapter;
  }
  return null;
}

StorylineStep? _findStep(StorylineChapter chapter, String stepId) {
  for (final step in chapter.steps) {
    if (step.id == stepId) return step;
  }
  return null;
}

class _StorylinesV1SecondaryPanel extends StatelessWidget {
  const _StorylinesV1SecondaryPanel({
    required this.storylines,
    required this.selectedStorylineId,
    required this.legacyGlobalStory,
    required this.onStorylineSelected,
  });

  final List<StorylineAsset> storylines;
  final String? selectedStorylineId;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final ValueChanged<StorylineAsset> onStorylineSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final mainStorylines = storylines
        .where((storyline) => storyline.type == StorylineType.main)
        .toList(growable: false);
    final sideQuests = storylines
        .where((storyline) => storyline.type == StorylineType.sideQuest)
        .toList(growable: false);
    final otherStorylines = storylines
        .where(
          (storyline) =>
              storyline.type != StorylineType.main &&
              storyline.type != StorylineType.sideQuest,
        )
        .toList(growable: false);
    return PokeMapPanel(
      key: const ValueKey('storylines-secondary-panel'),
      expandChild: true,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StorylinesSectionLabel(
            label: 'STORYLINES',
            color: colors.textMuted,
          ),
          const SizedBox(height: 12),
          if (storylines.isEmpty)
            const _StorylinesV1EmptyList()
          else ...[
            _StorylinesSectionLabel(
              label: 'HISTOIRE PRINCIPALE',
              color: colors.textMuted,
            ),
            const SizedBox(height: 8),
            if (mainStorylines.isEmpty)
              const _StorylinesV1CompactEmpty(
                title: 'Aucune histoire principale',
                body:
                    'Créez une histoire principale depuis Nouvelle storyline.',
              )
            else
              ...mainStorylines.map(
                (storyline) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StorylinesV1Row(
                    storyline: storyline,
                    selected: storyline.id == selectedStorylineId,
                    onTap: () => onStorylineSelected(storyline),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            _StorylinesSectionLabel(
              label: 'QUÊTES ANNEXES',
              color: colors.textMuted,
            ),
            const SizedBox(height: 8),
            if (sideQuests.isEmpty)
              const _StorylinesV1CompactEmpty(
                title: 'Aucune quête annexe',
                body: 'Créez une quête annexe depuis Nouvelle storyline.',
              )
            else
              ...sideQuests.map(
                (storyline) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StorylinesV1Row(
                    storyline: storyline,
                    selected: storyline.id == selectedStorylineId,
                    onTap: () => onStorylineSelected(storyline),
                  ),
                ),
              ),
            if (otherStorylines.isNotEmpty) ...[
              const SizedBox(height: 8),
              _StorylinesSectionLabel(
                label: 'AUTRES RÉCITS',
                color: colors.textMuted,
              ),
              const SizedBox(height: 8),
              ...otherStorylines.map(
                (storyline) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StorylinesV1Row(
                    storyline: storyline,
                    selected: storyline.id == selectedStorylineId,
                    onTap: () => onStorylineSelected(storyline),
                  ),
                ),
              ),
            ],
          ],
          const Spacer(),
          if (storylines.isEmpty && legacyGlobalStory != null)
            PokeMapCard(
              key: const ValueKey('storylines-legacy-global-story-note'),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ancienne Global Story détectée',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    legacyGlobalStory!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Import explicite disponible dans la barre d’actions.',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StorylinesV1EmptyList extends StatelessWidget {
  const _StorylinesV1EmptyList();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-v1-secondary-empty'),
      padding: const EdgeInsets.all(12),
      child: Text(
        'Aucune storyline auteur',
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StorylinesV1CompactEmpty extends StatelessWidget {
  const _StorylinesV1CompactEmpty({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylinesV1Row extends StatelessWidget {
  const _StorylinesV1Row({
    required this.storyline,
    required this.selected,
    required this.onTap,
  });

  final StorylineAsset storyline;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return KeyedSubtree(
      key: ValueKey('storylines-v1-row-${storyline.id}'),
      child: PokeMapCard(
        padding: const EdgeInsets.all(12),
        selected: selected,
        onTap: onTap,
        child: Row(
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.book,
              tone: PokeMapTone.narrative,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storyline.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _storylineTypeLabel(storyline.type),
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  if (storyline.type == StorylineType.sideQuest) ...[
                    const SizedBox(height: 3),
                    Text(
                      _sideQuestAttachmentStatus(storyline),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (storyline.chapters.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      "${_formatCount(storyline.chapters.length, 'chapitre', 'chapitres')} · ${_formatCount(_storylineStepCount(storyline), 'étape', 'étapes')}",
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesV1MainPanel extends StatelessWidget {
  const _StorylinesV1MainPanel({
    required this.project,
    required this.selectedStoryline,
    required this.selectedChapter,
    required this.selectedStepId,
    required this.storylines,
    required this.selectedTab,
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
    required this.onTabSelected,
    required this.onChapterSelected,
    required this.onCreateChapter,
    required this.onEditChapter,
    required this.onDuplicateChapter,
    required this.onMoveChapter,
    required this.onCreateStep,
    required this.onEditStep,
    required this.onReorderSteps,
    required this.onAttachSideQuest,
    required this.onGraphConnect,
    required this.onGraphDisconnect,
    required this.onGraphNodeSelected,
  });

  final ProjectManifest? project;
  final StorylineAsset? selectedStoryline;
  final StorylineChapter? selectedChapter;
  final String? selectedStepId;
  final List<StorylineAsset> storylines;
  final _StorylineContentTab selectedTab;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;
  final ValueChanged<_StorylineContentTab> onTabSelected;
  final ValueChanged<StorylineChapter?> onChapterSelected;
  final VoidCallback? onCreateChapter;
  final ValueChanged<StorylineChapter>? onEditChapter;
  final ValueChanged<StorylineChapter>? onDuplicateChapter;
  final StorylineChapterMove? onMoveChapter;
  final VoidCallback? onCreateStep;
  final StorylineStepAction? onEditStep;
  final StorylineStepReorder? onReorderSteps;
  final VoidCallback? onAttachSideQuest;
  final Future<bool> Function(StorylineProgressionConnectRequest request)?
      onGraphConnect;
  final Future<bool> Function(String edgeId)? onGraphDisconnect;
  final ValueChanged<StorylineGraphNode> onGraphNodeSelected;

  @override
  Widget build(BuildContext context) {
    final compactMode = switch (selectedTab) {
      _StorylineContentTab.graph || _StorylineContentTab.structure => true,
    };
    return PokeMapPanel(
      key: const ValueKey('storylines-main-panel'),
      expandChild: true,
      padding: EdgeInsets.all(compactMode ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StorylinesV1Header(
            selectedStoryline: selectedStoryline,
            compact: compactMode,
          ),
          SizedBox(height: compactMode ? 8 : 12),
          _StorylineTabsRow(
            selectedTab: selectedTab,
            onTabSelected: onTabSelected,
          ),
          SizedBox(height: compactMode ? 6 : 12),
          _StorylinesV1KpiStrip(
            storylines: storylines,
            compact: compactMode,
          ),
          SizedBox(height: compactMode ? 6 : 16),
          Expanded(
            child: switch (selectedTab) {
              _StorylineContentTab.structure => StorylinesStructureView(
                  storyline: selectedStoryline,
                  selectedChapter: selectedChapter,
                  selectedStepId: selectedStepId,
                  onChapterSelected: onChapterSelected,
                  onCreateChapter: onCreateChapter,
                  onEditChapter: onEditChapter,
                  onDuplicateChapter: onDuplicateChapter,
                  onMoveChapter: onMoveChapter,
                  onCreateStep: onCreateStep,
                  onEditStep: onEditStep,
                  onReorderSteps: onReorderSteps,
                  onAttachSideQuest: onAttachSideQuest,
                ),
              _StorylineContentTab.graph => _StorylinesV1GraphSection(
                  project: project,
                  storyline: selectedStoryline,
                  storylines: storylines,
                  legacyGlobalStory: legacyGlobalStory,
                  legacyStep: legacyStep,
                  legacyStepCount: legacyStepCount,
                  onConnectEdge: onGraphConnect,
                  onDisconnectEdge: onGraphDisconnect,
                  onNodeSelected: onGraphNodeSelected,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _StorylinesV1Header extends StatelessWidget {
  const _StorylinesV1Header({
    required this.selectedStoryline,
    required this.compact,
  });

  final StorylineAsset? selectedStoryline;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final title = selectedStoryline?.title ?? 'Storylines';
    if (compact) {
      return KeyedSubtree(
        key: const ValueKey('storylines-header-section'),
        child: Row(
          key: const ValueKey('storylines-header-section-compact'),
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (selectedStoryline != null) ...[
                    _StorylinesV1Badge(
                      label: _storylineTypeLabel(selectedStoryline!.type),
                    ),
                    _StorylinesV1Badge(
                      label: _storylineStatusLabel(selectedStoryline!.status),
                    ),
                    if (selectedStoryline!.type == StorylineType.sideQuest)
                      _StorylinesV1Badge(
                        label: _sideQuestAttachmentStatus(selectedStoryline!),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('storylines-header-section'),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                if (selectedStoryline != null) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _StorylinesV1Badge(
                        label: _storylineTypeLabel(selectedStoryline!.type),
                      ),
                      _StorylinesV1Badge(
                        label: _storylineStatusLabel(selectedStoryline!.status),
                      ),
                      if (selectedStoryline!.type == StorylineType.sideQuest)
                        _StorylinesV1Badge(
                          label: _sideQuestAttachmentStatus(
                            selectedStoryline!,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Text(
                  selectedStoryline == null
                      ? 'Créez une histoire principale pour commencer à structurer votre jeu.'
                      : selectedStoryline!.description ??
                          (selectedStoryline!.type == StorylineType.sideQuest
                              ? 'Quête annexe prête à structurer.'
                              : 'Storyline principale prête à structurer.'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StorylinesV1KpiStrip extends StatelessWidget {
  const _StorylinesV1KpiStrip({
    required this.storylines,
    required this.compact,
  });

  final List<StorylineAsset> storylines;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final chapterCount = storylines.fold<int>(
      0,
      (total, storyline) => total + storyline.chapters.length,
    );
    final stepCount = storylines.fold<int>(
      0,
      (total, storyline) =>
          total +
          storyline.chapters.fold<int>(
            0,
            (chapterTotal, chapter) => chapterTotal + chapter.steps.length,
          ),
    );
    final sceneLinkCount = storylines.fold<int>(
      0,
      (total, storyline) => total + storyline.sceneLinks.length,
    );
    if (compact) {
      return KeyedSubtree(
        key: const ValueKey('storylines-kpi-strip'),
        child: SizedBox(
          key: const ValueKey('storylines-kpi-strip-compact'),
          height: 34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.controlSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    child: _StorylinesV1CompactKpi(
                      label: 'Storylines',
                      value: storylines.length.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StorylinesV1CompactKpi(
                      label: 'Chapters',
                      value: chapterCount.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StorylinesV1CompactKpi(
                      label: 'Story Steps',
                      value: stepCount.toString(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StorylinesV1CompactKpi(
                      label: 'Scene Links',
                      value: sceneLinkCount.toString(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return KeyedSubtree(
      key: const ValueKey('storylines-kpi-strip'),
      child: SizedBox(
        height: 128,
        child: Row(
          children: [
            Expanded(
              child: PokeMapMetricCard(
                title: 'Storylines',
                value: storylines.length.toString(),
                icon: CupertinoIcons.book,
                tone: PokeMapTone.narrative,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapMetricCard(
                title: 'Chapters',
                value: chapterCount.toString(),
                icon: CupertinoIcons.square_list,
                tone: PokeMapTone.neutral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapMetricCard(
                title: 'Story Steps',
                value: stepCount.toString(),
                icon: CupertinoIcons.list_bullet,
                tone: PokeMapTone.neutral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PokeMapMetricCard(
                title: 'Scene Links',
                value: sceneLinkCount.toString(),
                icon: CupertinoIcons.link,
                tone: PokeMapTone.neutral,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesV1CompactKpi extends StatelessWidget {
  const _StorylinesV1CompactKpi({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StorylinesV1GraphSection extends StatelessWidget {
  const _StorylinesV1GraphSection({
    required this.project,
    required this.storyline,
    required this.storylines,
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
    required this.onConnectEdge,
    required this.onDisconnectEdge,
    required this.onNodeSelected,
  });

  final ProjectManifest? project;
  final StorylineAsset? storyline;
  final List<StorylineAsset> storylines;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;
  final Future<bool> Function(StorylineProgressionConnectRequest request)?
      onConnectEdge;
  final Future<bool> Function(String edgeId)? onDisconnectEdge;
  final ValueChanged<StorylineGraphNode> onNodeSelected;

  @override
  Widget build(BuildContext context) {
    final selectedStoryline = storyline;
    if (selectedStoryline == null) {
      return PokeMapCard(
        key: const ValueKey('storylines-graph-target-read-only'),
        padding: const EdgeInsets.all(18),
        child: _StorylinesV1NoStorylineState(
          legacyGlobalStory: legacyGlobalStory,
          legacyStep: legacyStep,
          legacyStepCount: legacyStepCount,
        ),
      );
    }
    final sideQuestCountOutsideSelected =
        selectedStoryline.type == StorylineType.main
            ? storylines
                .where((storyline) => storyline.type == StorylineType.sideQuest)
                .length
            : 0;
    return StorylinesGraphView(
      project: project,
      storyline: selectedStoryline,
      storylines: storylines,
      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
      onConnectEdge: onConnectEdge,
      onDisconnectEdge: onDisconnectEdge,
      onNodeSelected: onNodeSelected,
    );
  }
}

class _StorylinesV1NoStorylineState extends StatelessWidget {
  const _StorylinesV1NoStorylineState({
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
  });

  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PokeMapIconTile(
              icon: CupertinoIcons.book,
              tone: PokeMapTone.narrative,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              'Aucune storyline auteur',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Créez une histoire principale pour commencer à structurer votre jeu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (legacyGlobalStory != null) ...[
              const SizedBox(height: 12),
              Text(
                'Une ancienne Global Story peut exister dans les scénarios legacy. Elle ne sera pas importée automatiquement.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              PokeMapCard(
                key: const ValueKey('storylines-v1-legacy-preview-card'),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode lecture seule',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      legacyGlobalStory!.name,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (legacyGlobalStory!.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        legacyGlobalStory!.description,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Graph read-only',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (legacyStep != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        legacyStep!.name,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      legacyStepCount.toString(),
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StorylinesV1Badge extends StatelessWidget {
  const _StorylinesV1Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _StorylinesV1InspectorPanel extends StatelessWidget {
  const _StorylinesV1InspectorPanel({
    required this.selectedStoryline,
    required this.selectedChapter,
    required this.onEdit,
    required this.onDuplicate,
    required this.onArchive,
    required this.onDelete,
  });

  final StorylineAsset? selectedStoryline;
  final StorylineChapter? selectedChapter;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final chapter = selectedChapter;
    return PokeMapPanel(
      key: const ValueKey('storylines-inspector-read-only'),
      expandChild: true,
      padding: const EdgeInsets.all(14),
      child: selectedStoryline == null
          ? Center(
              child: Text(
                'Aucune storyline sélectionnée.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
            )
          : chapter != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DÉTAILS DU CHAPITRE',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      chapter.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      chapter.description ?? 'Aucune description.',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StorylineInspectorTextLine(
                      label: 'Storyline',
                      value: selectedStoryline!.title,
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Ordre',
                      value: chapter.order.toString(),
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Étapes',
                      value: chapter.steps.length.toString(),
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Scene links',
                      value: _chapterSceneLinkCount(chapter).toString(),
                    ),
                    const _StorylineInspectorTextLine(
                      label: 'Scènes liées',
                      value: 'À venir',
                    ),
                  ],
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'DÉTAILS STORYLINE',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        selectedStoryline!.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        selectedStoryline!.description ?? 'Aucune description.',
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StorylineInspectorTextLine(
                        label: 'Type',
                        value: _storylineTypeLabel(selectedStoryline!.type),
                      ),
                      _StorylineInspectorTextLine(
                        label: 'Statut',
                        value: _storylineStatusLabel(selectedStoryline!.status),
                      ),
                      _StorylineInspectorTextLine(
                        label: 'Chapitres',
                        value: selectedStoryline!.chapters.length.toString(),
                      ),
                      _StorylineInspectorTextLine(
                        label: 'Étapes',
                        value:
                            _storylineStepCount(selectedStoryline!).toString(),
                      ),
                      _StorylineInspectorTextLine(
                        label: 'Scene links',
                        value: selectedStoryline!.sceneLinks.length.toString(),
                      ),
                      if (selectedStoryline!.type == StorylineType.sideQuest)
                        _StorylineInspectorTextLine(
                          label: 'Relation principale',
                          value: _sideQuestMainAttachment(selectedStoryline!) ==
                                  null
                              ? 'Non reliée'
                              : 'Reliée',
                        ),
                      if (selectedStoryline!.authorNotes != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          selectedStoryline!.authorNotes!,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      PokeMapButton(
                        key: const ValueKey('storylines-edit-storyline-action'),
                        onPressed: onEdit,
                        variant: PokeMapButtonVariant.primary,
                        leading: const Icon(CupertinoIcons.pencil, size: 15),
                        child: const Text('Modifier'),
                      ),
                      const SizedBox(height: 8),
                      PokeMapButton(
                        key: const ValueKey('storylines-duplicate-action'),
                        onPressed: onDuplicate,
                        variant: PokeMapButtonVariant.secondary,
                        leading:
                            const Icon(CupertinoIcons.doc_on_doc, size: 15),
                        child: const Text('Dupliquer'),
                      ),
                      const SizedBox(height: 8),
                      PokeMapButton(
                        key: const ValueKey('storylines-archive-action'),
                        onPressed: onArchive,
                        variant: PokeMapButtonVariant.secondary,
                        leading:
                            const Icon(CupertinoIcons.archivebox, size: 15),
                        child: const Text('Archiver'),
                      ),
                      const SizedBox(height: 8),
                      PokeMapButton(
                        key: const ValueKey('storylines-delete-action'),
                        onPressed: onDelete,
                        variant: PokeMapButtonVariant.danger,
                        leading: const Icon(CupertinoIcons.trash, size: 15),
                        child: const Text('Supprimer'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _CreateStorylineDraft {
  const _CreateStorylineDraft({
    required this.type,
    required this.title,
    required this.description,
  });

  final StorylineType type;
  final String title;
  final String? description;
}

class _StorylineEditDraft {
  const _StorylineEditDraft({
    required this.type,
    required this.status,
    required this.title,
    required this.description,
    required this.authorNotes,
  });

  final StorylineType type;
  final StorylineStatus status;
  final String title;
  final String? description;
  final String? authorNotes;
}

class _StructureItemDraft {
  const _StructureItemDraft({
    required this.title,
    required this.description,
    this.status,
    this.authorNotes,
  }) : deleteRequested = false;

  const _StructureItemDraft.delete()
      : title = '',
        description = null,
        status = null,
        authorNotes = null,
        deleteRequested = true;

  final String title;
  final String? description;
  final StorylineStatus? status;
  final String? authorNotes;
  final bool deleteRequested;
}

class _StorylineStepDraft {
  const _StorylineStepDraft({
    required this.title,
    required this.description,
    required this.targetChapterId,
    required this.entryCondition,
    required this.completionCondition,
    required this.sceneLinkIds,
    required this.expectedOutcomeIds,
    required this.status,
    required this.authorNotes,
  })  : deleteRequested = false,
        duplicateRequested = false;

  const _StorylineStepDraft.delete()
      : title = '',
        description = null,
        targetChapterId = '',
        entryCondition = null,
        completionCondition = null,
        sceneLinkIds = const [],
        expectedOutcomeIds = const [],
        status = null,
        authorNotes = null,
        deleteRequested = true,
        duplicateRequested = false;

  const _StorylineStepDraft.duplicate()
      : title = '',
        description = null,
        targetChapterId = '',
        entryCondition = null,
        completionCondition = null,
        sceneLinkIds = const [],
        expectedOutcomeIds = const [],
        status = null,
        authorNotes = null,
        deleteRequested = false,
        duplicateRequested = true;

  final String title;
  final String? description;
  final String targetChapterId;
  final ScriptCondition? entryCondition;
  final ScriptCondition? completionCondition;
  final List<String> sceneLinkIds;
  final List<String> expectedOutcomeIds;
  final StorylineStatus? status;
  final String? authorNotes;
  final bool deleteRequested;
  final bool duplicateRequested;
}

class _SideQuestAttachmentDraft {
  const _SideQuestAttachmentDraft({
    required this.mainStoryline,
    required this.anchor,
  });

  final StorylineAsset mainStoryline;
  final _SideQuestAnchorChoice anchor;
}

class _SideQuestAnchorChoice {
  const _SideQuestAnchorChoice({
    required this.kind,
    required this.targetId,
    required this.label,
    required this.description,
  });

  final StorylineAnchorKind kind;
  final String targetId;
  final String label;
  final String description;
}

class _AttachSideQuestDialog extends StatefulWidget {
  const _AttachSideQuestDialog({
    required this.sideQuest,
    required this.storylines,
  });

  final StorylineAsset sideQuest;
  final List<StorylineAsset> storylines;

  @override
  State<_AttachSideQuestDialog> createState() => _AttachSideQuestDialogState();
}

class _AttachSideQuestDialogState extends State<_AttachSideQuestDialog> {
  String? _selectedMainId;
  String? _selectedAnchorId;

  @override
  void initState() {
    super.initState();
    final mainStorylines = _mainStorylines;
    if (mainStorylines.isNotEmpty) {
      _selectedMainId = mainStorylines.first.id;
      final anchors = _anchorChoicesFor(mainStorylines.first);
      if (anchors.isNotEmpty) {
        _selectedAnchorId = _anchorKey(anchors.first);
      }
    }
  }

  List<StorylineAsset> get _mainStorylines {
    return widget.storylines
        .where((storyline) => storyline.type == StorylineType.main)
        .toList(growable: false);
  }

  StorylineAsset? get _selectedMainStoryline {
    for (final storyline in _mainStorylines) {
      if (storyline.id == _selectedMainId) {
        return storyline;
      }
    }
    return _mainStorylines.isEmpty ? null : _mainStorylines.first;
  }

  _SideQuestAnchorChoice? get _selectedAnchor {
    final mainStoryline = _selectedMainStoryline;
    if (mainStoryline == null) return null;
    final anchors = _anchorChoicesFor(mainStoryline);
    for (final anchor in anchors) {
      if (_anchorKey(anchor) == _selectedAnchorId) {
        return anchor;
      }
    }
    return anchors.isEmpty ? null : anchors.first;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final mainStorylines = _mainStorylines;
    final mainStoryline = _selectedMainStoryline;
    final anchors = mainStoryline == null
        ? const <_SideQuestAnchorChoice>[]
        : _anchorChoicesFor(mainStoryline);
    final selectedAnchor = _selectedAnchor;
    final canSubmit = mainStoryline != null && selectedAnchor != null;
    return Center(
      child: SizedBox(
        width: 560,
        child: PokeMapPanel(
          key: const ValueKey('storylines-attach-sidequest-dialog'),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Attacher la quête annexe',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.sideQuest.title,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Histoire principale cible',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (mainStorylines.isEmpty)
                Text(
                  'Créez d’abord une histoire principale.',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                )
              else
                ...mainStorylines.map(
                  (storyline) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _StorylineTypeChoice(
                      key: ValueKey('storylines-attach-main-${storyline.id}'),
                      label: storyline.title,
                      description: _formatCount(
                        storyline.chapters.length,
                        'chapitre disponible',
                        'chapitres disponibles',
                      ),
                      selected: storyline.id == mainStoryline?.id,
                      enabled: true,
                      disabledReason: null,
                      onTap: () => setState(() {
                        _selectedMainId = storyline.id;
                        final nextAnchors = _anchorChoicesFor(storyline);
                        _selectedAnchorId = nextAnchors.isEmpty
                            ? null
                            : _anchorKey(nextAnchors.first);
                      }),
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                'Point d’ancrage',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (anchors.isEmpty)
                Text(
                  'Créez un chapitre ou une étape dans l’histoire principale avant d’attacher une quête annexe.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        for (final anchor in anchors)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _StorylineTypeChoice(
                              key: ValueKey(
                                'storylines-attach-anchor-${_anchorKey(anchor)}',
                              ),
                              label: anchor.label,
                              description: anchor.description,
                              selected: _anchorKey(anchor) == _selectedAnchorId,
                              enabled: true,
                              disabledReason: null,
                              onTap: () => setState(() {
                                _selectedAnchorId = _anchorKey(anchor);
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PokeMapButton(
                    key: const ValueKey('storylines-attach-cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  PokeMapButton(
                    key: const ValueKey('storylines-attach-submit'),
                    onPressed: canSubmit
                        ? () => Navigator.of(context).pop(
                              _SideQuestAttachmentDraft(
                                mainStoryline: mainStoryline,
                                anchor: selectedAnchor,
                              ),
                            )
                        : null,
                    variant: PokeMapButtonVariant.primary,
                    child: const Text('Attacher'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorylineStepEditorDialog extends StatefulWidget {
  const _StorylineStepEditorDialog({
    required this.project,
    required this.storyline,
    required this.initialChapterId,
    this.step,
  });

  final ProjectManifest project;
  final StorylineAsset storyline;
  final String initialChapterId;
  final StorylineStep? step;

  @override
  State<_StorylineStepEditorDialog> createState() =>
      _StorylineStepEditorDialogState();
}

class _StorylineStepEditorDialogState
    extends State<_StorylineStepEditorDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  late String _targetChapterId;
  ScriptCondition? _entryCondition;
  ScriptCondition? _completionCondition;
  late List<String> _sceneLinkIds;
  late List<String> _expectedOutcomeIds;
  StorylineStatus? _status;

  bool get _editing => widget.step != null;

  @override
  void initState() {
    super.initState();
    final step = widget.step;
    _titleController.text = step?.title ?? '';
    _descriptionController.text = step?.description ?? '';
    _notesController.text = step?.authorNotes ?? '';
    _targetChapterId = widget.initialChapterId;
    _entryCondition = step?.entryCondition;
    _completionCondition = step?.completionCondition;
    _sceneLinkIds = [...?step?.sceneLinkIds];
    _expectedOutcomeIds = [...?step?.expectedOutcomeIds];
    _status = step?.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final title = _titleController.text.trim();
    final maxDialogHeight =
        (MediaQuery.sizeOf(context).height - 48).clamp(420.0, 860.0);
    return Center(
      child: SizedBox(
        width: 680,
        child: PokeMapPanel(
          key: ValueKey(
            _editing
                ? 'storylines-edit-step-dialog'
                : 'storylines-create-step-dialog',
          ),
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _editing
                      ? 'Modifier l’étape narrative'
                      : 'Nouvelle étape narrative',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    key: const ValueKey(
                      'storylines-step-editor-dialog-scroll',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StorylinesV1TextField(
                          key: ValueKey(
                            _editing
                                ? 'storylines-edit-step-title-field'
                                : 'storylines-create-step-title-field',
                          ),
                          controller: _titleController,
                          placeholder: 'Titre',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        _StorylinesV1TextField(
                          key: ValueKey(
                            _editing
                                ? 'storylines-edit-step-description-field'
                                : 'storylines-create-step-description-field',
                          ),
                          controller: _descriptionController,
                          placeholder: 'Description optionnelle',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        _StorylinesV1TextField(
                          key: const ValueKey('storylines-step-notes-field'),
                          controller: _notesController,
                          placeholder: 'Notes auteur optionnelles',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 14),
                        _chapterSection(context),
                        const SizedBox(height: 14),
                        _statusSection(context),
                        const SizedBox(height: 14),
                        _conditionSection(
                          context,
                          label: 'Condition d’entrée',
                          keyPrefix: 'entry',
                          condition: _entryCondition,
                          onChanged: (value) =>
                              setState(() => _entryCondition = value),
                        ),
                        const SizedBox(height: 14),
                        _conditionSection(
                          context,
                          label: 'Condition de complétion',
                          keyPrefix: 'completion',
                          condition: _completionCondition,
                          onChanged: (value) =>
                              setState(() => _completionCondition = value),
                        ),
                        const SizedBox(height: 14),
                        _StorylineStepSceneLinksSection(
                          sceneLinkIds: _sceneLinkIds,
                          availableScenes: widget.project.scenes,
                          onLinkScene: _linkScene,
                          onUnlinkScene: _unlinkScene,
                        ),
                        const SizedBox(height: 14),
                        _outcomesSection(context),
                        if (title.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Titre obligatoire.',
                            style: TextStyle(
                              color: colors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (_editing)
                      PokeMapButton(
                        key: const ValueKey(
                          'storylines-edit-step-delete-action',
                        ),
                        onPressed: () => Navigator.of(context).pop(
                          const _StorylineStepDraft.delete(),
                        ),
                        variant: PokeMapButtonVariant.danger,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.trash),
                        child: const Text('Supprimer'),
                      ),
                    if (_editing)
                      PokeMapButton(
                        key: const ValueKey(
                          'storylines-edit-step-duplicate-action',
                        ),
                        onPressed: () => Navigator.of(context).pop(
                          const _StorylineStepDraft.duplicate(),
                        ),
                        variant: PokeMapButtonVariant.secondary,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.doc_on_doc),
                        child: const Text('Dupliquer'),
                      ),
                    PokeMapButton(
                      key: ValueKey(
                        _editing
                            ? 'storylines-edit-step-cancel'
                            : 'storylines-create-step-cancel',
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      variant: PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      child: const Text('Annuler'),
                    ),
                    PokeMapButton(
                      key: ValueKey(
                        _editing
                            ? 'storylines-edit-step-submit'
                            : 'storylines-create-step-submit',
                      ),
                      onPressed: title.isEmpty ? null : () => _submit(title),
                      variant: PokeMapButtonVariant.primary,
                      size: PokeMapButtonSize.small,
                      child: Text(_editing ? 'Enregistrer' : 'Créer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chapterSection(BuildContext context) {
    final colors = context.pokeMapColors;
    final chapters = [...widget.storyline.chapters]
      ..sort((left, right) => left.order.compareTo(right.order));
    return PokeMapCard(
      key: const ValueKey('storylines-step-chapter-section'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chapitre propriétaire',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chapter in chapters)
                PokeMapButton(
                  key: ValueKey(
                    'storylines-step-target-chapter-${chapter.id}',
                  ),
                  onPressed: () =>
                      setState(() => _targetChapterId = chapter.id),
                  variant: _targetChapterId == chapter.id
                      ? PokeMapButtonVariant.primary
                      : PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  child: Text(chapter.title),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusSection(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: const ValueKey('storylines-step-status-section'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Statut',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PokeMapButton(
                key: const ValueKey('storylines-step-status-inherited'),
                onPressed: () => setState(() => _status = null),
                variant: _status == null
                    ? PokeMapButtonVariant.primary
                    : PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                child: const Text('Hérité'),
              ),
              for (final status in StorylineStatus.values)
                PokeMapButton(
                  key: ValueKey('storylines-step-status-${status.name}'),
                  onPressed: () => setState(() => _status = status),
                  variant: _status == status
                      ? PokeMapButtonVariant.primary
                      : PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  child: Text(_storylineStatusLabel(status)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conditionSection(
    BuildContext context, {
    required String label,
    required String keyPrefix,
    required ScriptCondition? condition,
    required ValueChanged<ScriptCondition?> onChanged,
  }) {
    final colors = context.pokeMapColors;
    final factId = _simpleFactId(condition);
    NarrativeFactDefinition? knownFact;
    if (factId != null) {
      for (final fact in widget.project.facts) {
        if (fact.id == factId) {
          knownFact = fact;
          break;
        }
      }
    }
    final advanced = condition != null && factId == null;
    return PokeMapCard(
      key: ValueKey('storylines-step-$keyPrefix-condition-section'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (condition != null)
                PokeMapButton(
                  key: ValueKey(
                    'storylines-step-$keyPrefix-condition-clear',
                  ),
                  onPressed: () => onChanged(null),
                  variant: PokeMapButtonVariant.secondary,
                  size: PokeMapButtonSize.small,
                  child: const Text('Retirer'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (condition == null)
            Text(
              'Aucune condition : l’étape est disponible sans prérequis.',
              style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
            )
          else if (advanced)
            Text(
              'Condition avancée conservée · ${condition.type.name}',
              style: TextStyle(color: colors.warning, fontSize: 11.5),
            )
          else if (knownFact == null)
            Text(
              'Fact introuvable · $factId',
              key: ValueKey(
                'storylines-step-$keyPrefix-missing-fact-$factId',
              ),
              style: TextStyle(color: colors.warning, fontSize: 11.5),
            )
          else
            Text(
              '${knownFact.label} · ${condition.type == ScriptConditionType.flagIsSet ? 'vrai' : 'faux'}',
              style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
            ),
          const SizedBox(height: 10),
          if (widget.project.facts.isEmpty)
            Text(
              'Aucun Fact déclaré dans le projet.',
              style: TextStyle(color: colors.textMuted, fontSize: 11.5),
            )
          else
            for (final fact in widget.project.facts)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fact.label,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    PokeMapButton(
                      key: ValueKey(
                        'storylines-step-$keyPrefix-fact-set-${fact.id}',
                      ),
                      onPressed: () => onChanged(
                        ScriptConditionFactory.flagIsSet(fact.id),
                      ),
                      variant: factId == fact.id &&
                              condition?.type == ScriptConditionType.flagIsSet
                          ? PokeMapButtonVariant.primary
                          : PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      child: const Text('Vrai'),
                    ),
                    const SizedBox(width: 6),
                    PokeMapButton(
                      key: ValueKey(
                        'storylines-step-$keyPrefix-fact-unset-${fact.id}',
                      ),
                      onPressed: () => onChanged(
                        ScriptConditionFactory.flagIsUnset(fact.id),
                      ),
                      variant: factId == fact.id &&
                              condition?.type == ScriptConditionType.flagIsUnset
                          ? PokeMapButtonVariant.primary
                          : PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      child: const Text('Faux'),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _outcomesSection(BuildContext context) {
    final colors = context.pokeMapColors;
    final choices = _outcomeChoices(widget.project.scenes);
    final knownIds = choices.map((choice) => choice.outcomeId).toSet();
    final missing = _expectedOutcomeIds
        .where((outcomeId) => !knownIds.contains(outcomeId))
        .toList(growable: false);
    return PokeMapCard(
      key: const ValueKey('storylines-step-outcomes-section'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Outcomes attendus',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (final outcomeId in missing)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Outcome introuvable · $outcomeId',
                key: ValueKey(
                  'storylines-step-missing-outcome-$outcomeId',
                ),
                style: TextStyle(color: colors.warning, fontSize: 11.5),
              ),
            ),
          if (choices.isEmpty)
            Text(
              'Aucun outcome déclaré dans les Scenes du projet.',
              style: TextStyle(color: colors.textMuted, fontSize: 11.5),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in choices)
                  PokeMapButton(
                    key: ValueKey(
                      'storylines-step-outcome-${choice.sceneId}-${choice.outcomeId}',
                    ),
                    onPressed: () => _toggleOutcome(choice.outcomeId),
                    variant: _expectedOutcomeIds.contains(choice.outcomeId)
                        ? PokeMapButtonVariant.primary
                        : PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    child: Text('${choice.label} · ${choice.sceneLabel}'),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  void _linkScene(String sceneId) {
    if (_sceneLinkIds.contains(sceneId)) return;
    setState(() => _sceneLinkIds = [..._sceneLinkIds, sceneId]);
  }

  void _unlinkScene(String sceneId) {
    setState(() {
      _sceneLinkIds = _sceneLinkIds
          .where((current) => current != sceneId)
          .toList(growable: false);
    });
  }

  void _toggleOutcome(String outcomeId) {
    setState(() {
      if (_expectedOutcomeIds.contains(outcomeId)) {
        _expectedOutcomeIds = _expectedOutcomeIds
            .where((current) => current != outcomeId)
            .toList(growable: false);
      } else {
        _expectedOutcomeIds = [..._expectedOutcomeIds, outcomeId];
      }
    });
  }

  void _submit(String title) {
    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();
    Navigator.of(context).pop(
      _StorylineStepDraft(
        title: title,
        description: description.isEmpty ? null : description,
        targetChapterId: _targetChapterId,
        entryCondition: _entryCondition,
        completionCondition: _completionCondition,
        sceneLinkIds: List<String>.unmodifiable(_sceneLinkIds),
        expectedOutcomeIds: List<String>.unmodifiable(_expectedOutcomeIds),
        status: _status,
        authorNotes: notes.isEmpty ? null : notes,
      ),
    );
  }
}

class _StorylineOutcomeChoice {
  const _StorylineOutcomeChoice({
    required this.sceneId,
    required this.sceneLabel,
    required this.outcomeId,
    required this.label,
  });

  final String sceneId;
  final String sceneLabel;
  final String outcomeId;
  final String label;
}

List<_StorylineOutcomeChoice> _outcomeChoices(List<SceneAsset> scenes) {
  final choices = <_StorylineOutcomeChoice>[];
  final seen = <String>{};
  for (final scene in scenes) {
    for (final outcome in scene.declaredOutcomes) {
      if (!seen.add(outcome.id)) continue;
      choices.add(
        _StorylineOutcomeChoice(
          sceneId: scene.id,
          sceneLabel: scene.name,
          outcomeId: outcome.id,
          label: outcome.label,
        ),
      );
    }
  }
  choices.sort((left, right) {
    final scene = left.sceneLabel.compareTo(right.sceneLabel);
    return scene != 0 ? scene : left.label.compareTo(right.label);
  });
  return choices;
}

String? _simpleFactId(ScriptCondition? condition) {
  if (condition == null ||
      (condition.type != ScriptConditionType.flagIsSet &&
          condition.type != ScriptConditionType.flagIsUnset)) {
    return null;
  }
  return condition.params[ScriptConditionParams.flagName];
}

class _CreateStructureItemDialog extends StatefulWidget {
  const _CreateStructureItemDialog({
    required this.dialogKey,
    required this.title,
    required this.titleFieldKey,
    required this.descriptionFieldKey,
    required this.cancelKey,
    required this.submitKey,
    this.deleteKey,
    this.initialTitle,
    this.initialDescription,
    this.initialStatus,
    this.initialAuthorNotes,
    this.showLifecycleFields = false,
    this.submitLabel = 'Créer',
  });

  final Key dialogKey;
  final String title;
  final Key titleFieldKey;
  final Key descriptionFieldKey;
  final Key cancelKey;
  final Key submitKey;
  final Key? deleteKey;
  final String? initialTitle;
  final String? initialDescription;
  final StorylineStatus? initialStatus;
  final String? initialAuthorNotes;
  final bool showLifecycleFields;
  final String submitLabel;

  @override
  State<_CreateStructureItemDialog> createState() =>
      _CreateStructureItemDialogState();
}

class _CreateStructureItemDialogState
    extends State<_CreateStructureItemDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  StorylineStatus? _status;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
    _notesController.text = widget.initialAuthorNotes ?? '';
    _status = widget.initialStatus;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final title = _titleController.text.trim();
    final maxDialogHeight =
        (MediaQuery.sizeOf(context).height - 48).clamp(320.0, 720.0);
    return Center(
      child: SizedBox(
        width: 460,
        child: PokeMapPanel(
          key: widget.dialogKey,
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    key: const ValueKey(
                      'storylines-structure-item-dialog-scroll',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StorylinesV1TextField(
                          key: widget.titleFieldKey,
                          controller: _titleController,
                          placeholder: 'Titre',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        _StorylinesV1TextField(
                          key: widget.descriptionFieldKey,
                          controller: _descriptionController,
                          placeholder: 'Description optionnelle',
                          maxLines: 3,
                        ),
                        if (widget.showLifecycleFields) ...[
                          const SizedBox(height: 10),
                          _StorylinesV1TextField(
                            key: const ValueKey(
                              'storylines-chapter-notes-field',
                            ),
                            controller: _notesController,
                            placeholder: 'Notes auteur optionnelles',
                            maxLines: 3,
                          ),
                          const SizedBox(height: 14),
                          _StorylinesSectionLabel(
                            label: 'STATUT',
                            color: colors.textMuted,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              PokeMapButton(
                                key: const ValueKey(
                                  'storylines-chapter-status-inherited',
                                ),
                                onPressed: () => setState(() => _status = null),
                                variant: _status == null
                                    ? PokeMapButtonVariant.primary
                                    : PokeMapButtonVariant.secondary,
                                size: PokeMapButtonSize.small,
                                child: const Text('Hérité'),
                              ),
                              for (final status in StorylineStatus.values)
                                PokeMapButton(
                                  key: ValueKey(
                                    'storylines-chapter-status-${status.name}',
                                  ),
                                  onPressed: () =>
                                      setState(() => _status = status),
                                  variant: _status == status
                                      ? PokeMapButtonVariant.primary
                                      : PokeMapButtonVariant.secondary,
                                  size: PokeMapButtonSize.small,
                                  child: Text(_storylineStatusLabel(status)),
                                ),
                            ],
                          ),
                        ],
                        if (title.isEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Titre obligatoire.',
                            style: TextStyle(
                              color: colors.warning,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (widget.deleteKey != null)
                      PokeMapButton(
                        key: widget.deleteKey,
                        onPressed: () => Navigator.of(context).pop(
                          const _StructureItemDraft.delete(),
                        ),
                        variant: PokeMapButtonVariant.danger,
                        size: PokeMapButtonSize.small,
                        leading: const Icon(CupertinoIcons.trash),
                        child: const Text('Supprimer'),
                      ),
                    PokeMapButton(
                      key: widget.cancelKey,
                      onPressed: () => Navigator.of(context).pop(),
                      variant: PokeMapButtonVariant.secondary,
                      size: PokeMapButtonSize.small,
                      child: const Text('Annuler'),
                    ),
                    PokeMapButton(
                      key: widget.submitKey,
                      onPressed: title.isEmpty
                          ? null
                          : () {
                              final description =
                                  _descriptionController.text.trim();
                              final notes = _notesController.text.trim();
                              Navigator.of(context).pop(
                                _StructureItemDraft(
                                  title: title,
                                  description:
                                      description.isEmpty ? null : description,
                                  status: _status,
                                  authorNotes: notes.isEmpty ? null : notes,
                                ),
                              );
                            },
                      variant: PokeMapButtonVariant.primary,
                      size: PokeMapButtonSize.small,
                      child: Text(widget.submitLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StorylineStepSceneLinksSection extends StatelessWidget {
  const _StorylineStepSceneLinksSection({
    required this.sceneLinkIds,
    required this.availableScenes,
    required this.onLinkScene,
    required this.onUnlinkScene,
  });

  final List<String> sceneLinkIds;
  final List<SceneAsset> availableScenes;
  final ValueChanged<String> onLinkScene;
  final ValueChanged<String> onUnlinkScene;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final scenesById = {
      for (final scene in availableScenes) scene.id: scene,
    };
    final orderedScenes = [...availableScenes]..sort((left, right) {
        final label = left.name.compareTo(right.name);
        if (label != 0) return label;
        return left.id.compareTo(right.id);
      });
    return PokeMapCard(
      key: const ValueKey('storylines-step-scene-links-section'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const PokeMapIconTile(
                icon: CupertinoIcons.link,
                tone: PokeMapTone.narrative,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Scènes liées',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StorylinesV1Badge(label: sceneLinkIds.length.toString()),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            StorylineStepSceneLinksReadModel.authoringOnlyMessage,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          if (sceneLinkIds.isEmpty)
            PokeMapCard(
              key: const ValueKey('storylines-step-scene-link-empty'),
              padding: const EdgeInsets.all(10),
              child: Text(
                'Aucune Scene liée à cette étape.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            )
          else
            ...sceneLinkIds.map(
              (sceneId) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _StorylineLinkedSceneRow(
                  sceneId: sceneId,
                  scene: scenesById[sceneId],
                  onUnlinkScene: onUnlinkScene,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            'Ajouter une Scene existante',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (orderedScenes.isEmpty)
            Text(
              'Créez une Scene dans le workspace Scènes avant de la lier.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.5,
                height: 1.35,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final scene in orderedScenes)
                  PokeMapButton(
                    key: ValueKey('storylines-step-link-scene-${scene.id}'),
                    onPressed: sceneLinkIds.contains(scene.id)
                        ? null
                        : () => onLinkScene(scene.id),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.small,
                    leading: const Icon(CupertinoIcons.plus),
                    child: Text(scene.name),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StorylineLinkedSceneRow extends StatelessWidget {
  const _StorylineLinkedSceneRow({
    required this.sceneId,
    required this.scene,
    required this.onUnlinkScene,
  });

  final String sceneId;
  final SceneAsset? scene;
  final ValueChanged<String> onUnlinkScene;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final scene = this.scene;
    return PokeMapCard(
      key: ValueKey('storylines-step-scene-link-row-$sceneId'),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          PokeMapIconTile(
            icon: scene == null
                ? CupertinoIcons.exclamationmark_triangle
                : CupertinoIcons.square_list,
            tone: scene == null ? PokeMapTone.warning : PokeMapTone.narrative,
            size: 26,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scene?.name ?? 'Scene introuvable',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sceneId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: scene == null ? colors.warning : colors.textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            key: ValueKey('storylines-step-unlink-scene-$sceneId'),
            onPressed: () => onUnlinkScene(sceneId),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.xmark),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
  }
}

class _ConfirmStructureDeleteDialog extends StatelessWidget {
  const _ConfirmStructureDeleteDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Center(
      child: SizedBox(
        width: 460,
        child: PokeMapPanel(
          key: const ValueKey('storylines-confirm-delete-dialog'),
          padding: const EdgeInsets.all(18),
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
                  fontSize: 12.5,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PokeMapButton(
                    key: const ValueKey('storylines-confirm-delete-cancel'),
                    onPressed: () => Navigator.of(context).pop(false),
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  PokeMapButton(
                    key: const ValueKey('storylines-confirm-delete-submit'),
                    onPressed: () => Navigator.of(context).pop(true),
                    variant: PokeMapButtonVariant.danger,
                    child: const Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorylineMessageDialog extends StatelessWidget {
  const _StorylineMessageDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Center(
      child: SizedBox(
        width: 480,
        child: PokeMapPanel(
          key: const ValueKey('storylines-message-dialog'),
          padding: const EdgeInsets.all(18),
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
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: PokeMapButton(
                  key: const ValueKey('storylines-message-close'),
                  onPressed: () => Navigator.of(context).pop(),
                  variant: PokeMapButtonVariant.primary,
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditStorylineDialog extends StatefulWidget {
  const _EditStorylineDialog({required this.storyline});

  final StorylineAsset storyline;

  @override
  State<_EditStorylineDialog> createState() => _EditStorylineDialogState();
}

class _EditStorylineDialogState extends State<_EditStorylineDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;
  late StorylineType _type;
  late StorylineStatus _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.storyline.title);
    _descriptionController =
        TextEditingController(text: widget.storyline.description ?? '');
    _notesController =
        TextEditingController(text: widget.storyline.authorNotes ?? '');
    _type = widget.storyline.type;
    _status = widget.storyline.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final title = _titleController.text.trim();
    final maxDialogHeight =
        (MediaQuery.sizeOf(context).height - 48).clamp(420.0, 820.0);
    return Center(
      child: SizedBox(
        width: 560,
        child: PokeMapPanel(
          key: const ValueKey('storylines-edit-dialog'),
          padding: const EdgeInsets.all(18),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxDialogHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Modifier la storyline',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StorylinesV1TextField(
                          key: const ValueKey('storylines-edit-title-field'),
                          controller: _titleController,
                          placeholder: 'Titre',
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 10),
                        _StorylinesV1TextField(
                          key: const ValueKey(
                            'storylines-edit-description-field',
                          ),
                          controller: _descriptionController,
                          placeholder: 'Description optionnelle',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 10),
                        _StorylinesV1TextField(
                          key: const ValueKey('storylines-edit-notes-field'),
                          controller: _notesController,
                          placeholder: 'Notes auteur optionnelles',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _StorylinesSectionLabel(
                          label: 'TYPE',
                          color: colors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        for (final type in StorylineType.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _StorylineTypeChoice(
                              key: ValueKey(
                                'storylines-edit-type-${type.name.toLowerCase()}',
                              ),
                              label: _storylineTypeLabel(type),
                              description: _storylineTypeDescription(type),
                              selected: _type == type,
                              enabled: true,
                              disabledReason: null,
                              onTap: () => setState(() => _type = type),
                            ),
                          ),
                        const SizedBox(height: 8),
                        _StorylinesSectionLabel(
                          label: 'STATUT',
                          color: colors.textMuted,
                        ),
                        const SizedBox(height: 8),
                        for (final status in StorylineStatus.values)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _StorylineTypeChoice(
                              key: ValueKey(
                                'storylines-edit-status-${status.name}',
                              ),
                              label: _storylineStatusLabel(status),
                              description: _storylineStatusDescription(status),
                              selected: _status == status,
                              enabled: true,
                              disabledReason: null,
                              onTap: () => setState(() => _status = status),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PokeMapButton(
                      key: const ValueKey('storylines-edit-cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                      variant: PokeMapButtonVariant.secondary,
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 10),
                    PokeMapButton(
                      key: const ValueKey('storylines-edit-submit'),
                      onPressed: title.isEmpty
                          ? null
                          : () {
                              final description =
                                  _descriptionController.text.trim();
                              final notes = _notesController.text.trim();
                              Navigator.of(context).pop(
                                _StorylineEditDraft(
                                  type: _type,
                                  status: _status,
                                  title: title,
                                  description:
                                      description.isEmpty ? null : description,
                                  authorNotes: notes.isEmpty ? null : notes,
                                ),
                              );
                            },
                      variant: PokeMapButtonVariant.primary,
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateStorylineDialog extends StatefulWidget {
  const _CreateStorylineDialog({required this.storylines});

  final List<StorylineAsset> storylines;

  @override
  State<_CreateStorylineDialog> createState() => _CreateStorylineDialogState();
}

class _CreateStorylineDialogState extends State<_CreateStorylineDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late StorylineType _selectedType;

  bool get _hasMainStoryline => widget.storylines
      .any((storyline) => storyline.type == StorylineType.main);

  bool get _canCreateMain => !_hasMainStoryline;

  bool get _canCreateSideQuest => _hasMainStoryline;

  bool get _canCreateSelectedType {
    return switch (_selectedType) {
      StorylineType.main => _canCreateMain,
      StorylineType.sideQuest => _canCreateSideQuest,
      _ => true,
    };
  }

  @override
  void initState() {
    super.initState();
    _selectedType =
        _hasMainStoryline ? StorylineType.sideQuest : StorylineType.main;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final title = _titleController.text.trim();
    final canSubmit = title.isNotEmpty && _canCreateSelectedType;
    return Center(
      child: SizedBox(
        width: 520,
        child: PokeMapPanel(
          key: const ValueKey('storylines-create-main-dialog'),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nouvelle storyline',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  key: const ValueKey('storylines-create-type-scroll'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final type in StorylineType.values)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _StorylineTypeChoice(
                            key: ValueKey(
                              'storylines-create-type-${type.name.toLowerCase()}',
                            ),
                            label: _storylineTypeLabel(type),
                            description: _storylineTypeDescription(type),
                            selected: _selectedType == type,
                            enabled: switch (type) {
                              StorylineType.main => _canCreateMain,
                              StorylineType.sideQuest => _canCreateSideQuest,
                              _ => true,
                            },
                            disabledReason: switch (type) {
                              StorylineType.main when _hasMainStoryline =>
                                'Une histoire principale existe déjà.',
                              StorylineType.sideQuest
                                  when !_canCreateSideQuest =>
                                'Créez d’abord une histoire principale pour organiser les quêtes annexes.',
                              _ => null,
                            },
                            onTap: () => setState(() {
                              _selectedType = type;
                            }),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _StorylinesV1TextField(
                key: const ValueKey('storylines-create-title-field'),
                controller: _titleController,
                placeholder: 'Titre',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _StorylinesV1TextField(
                key: const ValueKey('storylines-create-description-field'),
                controller: _descriptionController,
                placeholder: 'Description optionnelle',
                maxLines: 3,
              ),
              if (title.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Titre obligatoire.',
                  style: TextStyle(
                    color: colors.warning,
                    fontSize: 12,
                  ),
                ),
              ],
              if (!_canCreateSelectedType) ...[
                const SizedBox(height: 8),
                Text(
                  _selectedType == StorylineType.sideQuest
                      ? 'Créez d’abord une histoire principale.'
                      : 'Une histoire principale existe déjà.',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  PokeMapButton(
                    key: const ValueKey('storylines-create-cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 10),
                  PokeMapButton(
                    key: const ValueKey('storylines-create-submit'),
                    onPressed: !canSubmit
                        ? null
                        : () {
                            final description =
                                _descriptionController.text.trim();
                            Navigator.of(context).pop(
                              _CreateStorylineDraft(
                                type: _selectedType,
                                title: title,
                                description:
                                    description.isEmpty ? null : description,
                              ),
                            );
                          },
                    variant: PokeMapButtonVariant.primary,
                    child: const Text('Créer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorylineTypeChoice extends StatelessWidget {
  const _StorylineTypeChoice({
    super.key,
    required this.label,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.disabledReason,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final bool enabled;
  final String? disabledReason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      selected: selected,
      padding: const EdgeInsets.all(12),
      onTap: enabled ? onTap : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: enabled ? colors.textPrimary : colors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: enabled ? colors.textSecondary : colors.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (!enabled && disabledReason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    disabledReason!,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (selected)
            const _StorylinesV1Badge(label: 'Sélectionné')
          else if (!enabled)
            const _StorylinesV1Badge(label: 'Indisponible'),
        ],
      ),
    );
  }
}

class _StorylinesV1TextField extends StatelessWidget {
  const _StorylinesV1TextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String placeholder;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return CupertinoTextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      placeholder: placeholder,
      style: TextStyle(color: colors.textPrimary, fontSize: 13),
      placeholderStyle: TextStyle(color: colors.textMuted, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.controlSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.borderSubtle),
      ),
    );
  }
}

String _storylineTypeLabel(StorylineType type) {
  return switch (type) {
    StorylineType.main => 'Histoire principale',
    StorylineType.sideQuest => 'Quête annexe',
    StorylineType.tutorial => 'Tutoriel',
    StorylineType.epilogue => 'Épilogue',
    StorylineType.episode => 'Épisode',
    StorylineType.postGame => 'Post-game',
    StorylineType.hiddenEvent => 'Événement caché',
  };
}

String _storylineTypeDescription(StorylineType type) {
  return switch (type) {
    StorylineType.main => 'Structure principale du jeu.',
    StorylineType.sideQuest => 'Histoire secondaire optionnelle.',
    StorylineType.tutorial => 'Parcours guidé pour apprendre une mécanique.',
    StorylineType.epilogue => 'Conclusion narrative après l’histoire.',
    StorylineType.episode => 'Arc narratif autonome ou sérialisé.',
    StorylineType.postGame => 'Contenu narratif débloqué après la fin.',
    StorylineType.hiddenEvent => 'Récit secret déclenché par des conditions.',
  };
}

String _storylineStatusLabel(StorylineStatus status) {
  return switch (status) {
    StorylineStatus.draft => 'Brouillon',
    StorylineStatus.active => 'Actif',
    StorylineStatus.archived => 'Archivé',
    StorylineStatus.disabled => 'Désactivé',
  };
}

String _storylineStatusDescription(StorylineStatus status) {
  return switch (status) {
    StorylineStatus.draft => 'En construction et non prête à publier.',
    StorylineStatus.active => 'Disponible pour la progression narrative.',
    StorylineStatus.archived => 'Conservée hors du parcours actif.',
    StorylineStatus.disabled => 'Temporairement désactivée sans suppression.',
  };
}

enum _StorylineContentTab { graph, structure }

class _StorylineTabsRow extends StatelessWidget {
  const _StorylineTabsRow({
    required this.selectedTab,
    required this.onTabSelected,
  });

  final _StorylineContentTab selectedTab;
  final ValueChanged<_StorylineContentTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('storylines-tabs'),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: PokeMapSegmentedTabs(
          tabs: [
            PokeMapSegmentedTab(
              label: 'Graph',
              selected: selectedTab == _StorylineContentTab.graph,
              icon: CupertinoIcons.arrow_branch,
              onTap: () => onTabSelected(_StorylineContentTab.graph),
            ),
            PokeMapSegmentedTab(
              label: 'Structure',
              selected: selectedTab == _StorylineContentTab.structure,
              icon: CupertinoIcons.square_list,
              onTap: () => onTabSelected(_StorylineContentTab.structure),
            ),
          ],
        ),
      ),
    );
  }
}

class _StorylinesSectionLabel extends StatelessWidget {
  const _StorylinesSectionLabel({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _StorylineInspectorTextLine extends StatelessWidget {
  const _StorylineInspectorTextLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
