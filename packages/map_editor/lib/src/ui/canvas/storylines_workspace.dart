import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/narrative/application/narrative_workspace_projection.dart';
import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import 'storylines/storylines_graph_view.dart';
import 'storylines/storylines_structure_view.dart';

class StorylinesWorkspace extends ConsumerStatefulWidget {
  const StorylinesWorkspace({
    super.key,
    required this.projection,
    required this.selectedGlobalStoryId,
  });

  final NarrativeWorkspaceProjection projection;
  final String? selectedGlobalStoryId;

  @override
  ConsumerState<StorylinesWorkspace> createState() =>
      _StorylinesWorkspaceState();
}

class _StorylinesWorkspaceState extends ConsumerState<StorylinesWorkspace> {
  static const _closedChapterSelectionId = '__storylines_closed_chapter__';

  _StorylineContentTab _selectedTab = _StorylineContentTab.graph;
  String? _selectedStorylineId;
  String? _selectedChapterId;

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorNotifierProvider);
    final project = editorState.project;
    final storylines = project?.storylines ?? const <StorylineAsset>[];
    final selectedStoryline = _selectedStoryline(storylines);
    final selectedChapter = _selectedChapter(selectedStoryline);
    final legacyGlobalStory = widget.projection.globalStories.isEmpty
        ? null
        : widget.projection.globalStories.first;
    final legacyStep =
        widget.projection.steps.isEmpty ? null : widget.projection.steps.first;
    final legacyStepCount = widget.projection.steps.length;

    return PokeMapPageSurface(
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
              selectedStoryline: selectedStoryline,
              selectedChapter: selectedChapter,
              storylines: storylines,
              selectedTab: _selectedTab,
              legacyGlobalStory: legacyGlobalStory,
              legacyStep: legacyStep,
              legacyStepCount: legacyStepCount,
              canCreateStoryline: project != null,
              onTabSelected: _selectTab,
              onChapterSelected: _selectChapter,
              onCreateStoryline: project == null
                  ? null
                  : () => _openCreateStorylineDialog(project),
              onCreateChapter: project == null || selectedStoryline == null
                  ? null
                  : () => _openCreateChapterDialog(project, selectedStoryline),
              onEditChapter: project == null || selectedStoryline == null
                  ? null
                  : (chapter) => _openEditChapterDialog(
                        project,
                        selectedStoryline,
                        chapter,
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
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 280,
            child: _StorylinesV1InspectorPanel(
              selectedStoryline: selectedStoryline,
              selectedChapter: _selectedTab == _StorylineContentTab.structure
                  ? selectedChapter
                  : null,
            ),
          ),
        ],
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

  void _selectStoryline(StorylineAsset storyline) {
    if (_selectedStorylineId == storyline.id) {
      return;
    }
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId =
          storyline.chapters.isEmpty ? null : storyline.chapters.first.id;
    });
  }

  void _selectChapter(StorylineChapter? chapter) {
    final nextChapterId = chapter?.id ?? _closedChapterSelectionId;
    if (_selectedChapterId == nextChapterId) {
      return;
    }
    setState(() {
      _selectedChapterId = nextChapterId;
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
    final updated = project.copyWith(
      storylines: [...project.storylines, storyline],
    );
    ref.read(editorNotifierProvider.notifier).applyInMemoryProjectManifest(
          updated,
          statusMessage: draft.type == StorylineType.sideQuest
              ? 'Quête annexe créée'
              : 'Storyline principale créée',
        );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = null;
      _selectedTab = draft.type == StorylineType.sideQuest
          ? _StorylineContentTab.structure
          : _StorylineContentTab.graph;
    });
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
    final draft = await showCupertinoDialog<_StructureItemDraft>(
      context: context,
      builder: (context) => const _CreateStructureItemDialog(
        dialogKey: ValueKey('storylines-create-step-dialog'),
        title: 'Nouvelle étape narrative',
        titleFieldKey: ValueKey('storylines-create-step-title-field'),
        descriptionFieldKey: ValueKey(
          'storylines-create-step-description-field',
        ),
        cancelKey: ValueKey('storylines-create-step-cancel'),
        submitKey: ValueKey('storylines-create-step-submit'),
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    final step = StorylineStep(
      id: _generateScopedId(
        prefix: 'step',
        title: draft.title,
        existingIds: _storylineStepIds(storyline),
      ),
      title: draft.title,
      description: draft.description,
      order: _nextStepOrder(chapter),
    );
    final updatedChapter = _copyChapterWith(
      chapter,
      steps: [...chapter.steps, step],
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) => current.id == chapter.id ? updatedChapter : current,
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
      _selectedChapterId = chapter.id;
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
    final updatedChapter = _copyChapterWith(
      chapter,
      title: draft.title,
      description: draft.description,
      replaceDescription: true,
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) => current.id == chapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Chapitre modifié',
    );
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
    final remaining = storyline.chapters
        .where((current) => current.id != chapter.id)
        .toList(growable: false);
    final normalized = _normalizeChapterOrders(remaining);
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: normalized,
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Chapitre supprimé',
    );
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

  Future<void> _openEditStepDialog(
    ProjectManifest project,
    StorylineAsset storyline,
    StorylineChapter chapter,
    StorylineStep step,
  ) async {
    final draft = await showCupertinoDialog<_StructureItemDraft>(
      context: context,
      builder: (context) => _CreateStructureItemDialog(
        dialogKey: const ValueKey('storylines-edit-step-dialog'),
        title: 'Modifier l’étape narrative',
        titleFieldKey: const ValueKey('storylines-edit-step-title-field'),
        descriptionFieldKey: const ValueKey(
          'storylines-edit-step-description-field',
        ),
        cancelKey: const ValueKey('storylines-edit-step-cancel'),
        submitKey: const ValueKey('storylines-edit-step-submit'),
        deleteKey: const ValueKey('storylines-edit-step-delete-action'),
        initialTitle: step.title,
        initialDescription: step.description,
        initialSceneLinkIds: step.sceneLinkIds,
        availableScenes: project.scenes,
        submitLabel: 'Enregistrer',
      ),
    );
    if (draft == null || !mounted) {
      return;
    }
    if (draft.deleteRequested) {
      await _deleteStep(project, storyline, chapter, step);
      return;
    }
    var workingProject = project;
    var workingStoryline = storyline;
    var workingChapter = chapter;
    var workingStep = step;
    final draftSceneLinkIds = draft.sceneLinkIds;
    if (draftSceneLinkIds != null &&
        !_stringListEquals(draftSceneLinkIds, step.sceneLinkIds)) {
      final result = replaceStorylineStepSceneLinks(
        project,
        storylineId: storyline.id,
        chapterId: chapter.id,
        stepId: step.id,
        sceneIds: draftSceneLinkIds,
      );
      workingProject = result.updatedProject;
      workingStoryline = result.updatedStoryline;
      workingChapter = workingStoryline.chapters
          .singleWhere((current) => current.id == chapter.id);
      workingStep = result.updatedStep;
    }
    final updatedStep = _copyStepWith(
      workingStep,
      title: draft.title,
      description: draft.description,
      replaceDescription: true,
    );
    final updatedChapter = _copyChapterWith(
      workingChapter,
      steps: workingChapter.steps
          .map(
            (current) => current.id == workingStep.id ? updatedStep : current,
          )
          .toList(growable: false),
    );
    final updatedStoryline = _copyStorylineWith(
      workingStoryline,
      chapters: workingStoryline.chapters
          .map(
            (current) =>
                current.id == workingChapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      workingProject,
      updatedStoryline,
      statusMessage: 'Étape narrative modifiée',
    );
    setState(() {
      _selectedStorylineId = storyline.id;
      _selectedChapterId = chapter.id;
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
    final updatedSteps = _normalizeStepOrders(
      chapter.steps
          .where((current) => current.id != step.id)
          .toList(growable: false),
    );
    final updatedChapter = _copyChapterWith(chapter, steps: updatedSteps);
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) => current.id == chapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
      statusMessage: 'Étape narrative supprimée',
    );
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
    final updatedChapter = _copyChapterWith(
      chapter,
      steps: _normalizeStepOrders(steps),
    );
    final updatedStoryline = _copyStorylineWith(
      storyline,
      chapters: storyline.chapters
          .map(
            (current) => current.id == chapter.id ? updatedChapter : current,
          )
          .toList(growable: false),
    );
    _applyStorylineUpdate(
      project,
      updatedStoryline,
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

StorylineStep _copyStepWith(
  StorylineStep step, {
  String? title,
  String? description,
  bool replaceDescription = false,
  int? order,
  List<String>? sceneLinkIds,
}) {
  return StorylineStep(
    id: step.id,
    title: title ?? step.title,
    description:
        replaceDescription ? description : description ?? step.description,
    order: order ?? step.order,
    entryCondition: step.entryCondition,
    completionCondition: step.completionCondition,
    sceneLinkIds: sceneLinkIds ?? step.sceneLinkIds,
    expectedOutcomeIds: step.expectedOutcomeIds,
    status: step.status,
    authorNotes: step.authorNotes,
    metadata: step.metadata,
  );
}

bool _stringListEquals(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

List<StorylineChapter> _normalizeChapterOrders(
  List<StorylineChapter> chapters,
) {
  return [
    for (var index = 0; index < chapters.length; index += 1)
      _copyChapterWith(chapters[index], order: index),
  ];
}

List<StorylineStep> _normalizeStepOrders(List<StorylineStep> steps) {
  return [
    for (var index = 0; index < steps.length; index += 1)
      _copyStepWith(steps[index], order: index),
  ];
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
                    'Import manuel à venir.',
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
    required this.selectedStoryline,
    required this.selectedChapter,
    required this.storylines,
    required this.selectedTab,
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
    required this.canCreateStoryline,
    required this.onTabSelected,
    required this.onChapterSelected,
    required this.onCreateStoryline,
    required this.onCreateChapter,
    required this.onEditChapter,
    required this.onCreateStep,
    required this.onEditStep,
    required this.onReorderSteps,
    required this.onAttachSideQuest,
  });

  final StorylineAsset? selectedStoryline;
  final StorylineChapter? selectedChapter;
  final List<StorylineAsset> storylines;
  final _StorylineContentTab selectedTab;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;
  final bool canCreateStoryline;
  final ValueChanged<_StorylineContentTab> onTabSelected;
  final ValueChanged<StorylineChapter?> onChapterSelected;
  final VoidCallback? onCreateStoryline;
  final VoidCallback? onCreateChapter;
  final ValueChanged<StorylineChapter>? onEditChapter;
  final VoidCallback? onCreateStep;
  final StorylineStepAction? onEditStep;
  final StorylineStepReorder? onReorderSteps;
  final VoidCallback? onAttachSideQuest;

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
            canCreateStoryline: canCreateStoryline,
            onCreateStoryline: onCreateStoryline,
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
                  onChapterSelected: onChapterSelected,
                  onCreateChapter: onCreateChapter,
                  onEditChapter: onEditChapter,
                  onCreateStep: onCreateStep,
                  onEditStep: onEditStep,
                  onReorderSteps: onReorderSteps,
                  onAttachSideQuest: onAttachSideQuest,
                ),
              _StorylineContentTab.graph => _StorylinesV1GraphSection(
                  storyline: selectedStoryline,
                  storylines: storylines,
                  legacyGlobalStory: legacyGlobalStory,
                  legacyStep: legacyStep,
                  legacyStepCount: legacyStepCount,
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
    required this.canCreateStoryline,
    required this.onCreateStoryline,
    required this.compact,
  });

  final StorylineAsset? selectedStoryline;
  final bool canCreateStoryline;
  final VoidCallback? onCreateStoryline;
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
                    const _StorylinesV1Badge(label: 'Brouillon'),
                    if (selectedStoryline!.type == StorylineType.sideQuest)
                      _StorylinesV1Badge(
                        label: _sideQuestAttachmentStatus(selectedStoryline!),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            PokeMapButton(
              key: const ValueKey('storylines-create-main-cta'),
              onPressed: canCreateStoryline ? onCreateStoryline : null,
              variant: PokeMapButtonVariant.primary,
              leading: const Icon(CupertinoIcons.plus, size: 16),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Nouvelle'),
                  Text(' storyline'),
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
                      const _StorylinesV1Badge(label: 'Brouillon'),
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
          const SizedBox(width: 12),
          PokeMapButton(
            key: const ValueKey('storylines-create-main-cta'),
            onPressed: canCreateStoryline ? onCreateStoryline : null,
            variant: PokeMapButtonVariant.primary,
            leading: const Icon(CupertinoIcons.plus, size: 16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Nouvelle'),
                Text(' storyline'),
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
    required this.storyline,
    required this.storylines,
    required this.legacyGlobalStory,
    required this.legacyStep,
    required this.legacyStepCount,
  });

  final StorylineAsset? storyline;
  final List<StorylineAsset> storylines;
  final NarrativeScenarioSummary? legacyGlobalStory;
  final NarrativeStepSummary? legacyStep;
  final int legacyStepCount;

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
      storyline: selectedStoryline,
      storylines: storylines,
      sideQuestCountOutsideSelected: sideQuestCountOutsideSelected,
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
  });

  final StorylineAsset? selectedStoryline;
  final StorylineChapter? selectedChapter;

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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const _StorylineInspectorTextLine(
                      label: 'Statut',
                      value: 'Draft',
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Chapitres',
                      value: selectedStoryline!.chapters.length.toString(),
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Étapes',
                      value: _storylineStepCount(selectedStoryline!).toString(),
                    ),
                    _StorylineInspectorTextLine(
                      label: 'Scene links',
                      value: selectedStoryline!.sceneLinks.length.toString(),
                    ),
                    if (selectedStoryline!.type == StorylineType.sideQuest)
                      _StorylineInspectorTextLine(
                        label: 'Relation principale',
                        value:
                            _sideQuestMainAttachment(selectedStoryline!) == null
                                ? 'Non reliée'
                                : 'Reliée',
                      ),
                  ],
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

class _StructureItemDraft {
  const _StructureItemDraft({
    required this.title,
    required this.description,
    this.sceneLinkIds,
  }) : deleteRequested = false;

  const _StructureItemDraft.delete()
      : title = '',
        description = null,
        sceneLinkIds = null,
        deleteRequested = true;

  final String title;
  final String? description;
  final List<String>? sceneLinkIds;
  final bool deleteRequested;
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
    this.initialSceneLinkIds,
    this.availableScenes,
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
  final List<String>? initialSceneLinkIds;
  final List<SceneAsset>? availableScenes;
  final String submitLabel;

  @override
  State<_CreateStructureItemDialog> createState() =>
      _CreateStructureItemDialogState();
}

class _CreateStructureItemDialogState
    extends State<_CreateStructureItemDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late final List<String> _initialSceneLinkIds;
  late List<String> _sceneLinkIds;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
    _initialSceneLinkIds =
        List<String>.unmodifiable(widget.initialSceneLinkIds ?? const []);
    _sceneLinkIds = [..._initialSceneLinkIds];
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
    return Center(
      child: SizedBox(
        width: 460,
        child: PokeMapPanel(
          key: widget.dialogKey,
          padding: const EdgeInsets.all(18),
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
              if (widget.availableScenes != null) ...[
                const SizedBox(height: 14),
                _StorylineStepSceneLinksSection(
                  sceneLinkIds: _sceneLinkIds,
                  availableScenes: widget.availableScenes!,
                  onLinkScene: _linkScene,
                  onUnlinkScene: _unlinkScene,
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
                            Navigator.of(context).pop(
                              _StructureItemDraft(
                                title: title,
                                description:
                                    description.isEmpty ? null : description,
                                sceneLinkIds: widget.availableScenes == null
                                    ? null
                                    : List<String>.unmodifiable(_sceneLinkIds),
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
    );
  }

  void _linkScene(String sceneId) {
    if (_sceneLinkIds.contains(sceneId)) {
      return;
    }
    setState(() {
      _sceneLinkIds = [..._sceneLinkIds, sceneId];
    });
  }

  void _unlinkScene(String sceneId) {
    setState(() {
      _sceneLinkIds = _sceneLinkIds
          .where((current) => current != sceneId)
          .toList(growable: false);
    });
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
      _ => false,
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
              _StorylineTypeChoice(
                key: const ValueKey('storylines-create-type-main'),
                label: 'Histoire principale',
                description: 'Structure principale du jeu.',
                selected: _selectedType == StorylineType.main,
                enabled: _canCreateMain,
                disabledReason: _hasMainStoryline
                    ? 'Une histoire principale existe déjà.'
                    : null,
                onTap: () => setState(() {
                  _selectedType = StorylineType.main;
                }),
              ),
              const SizedBox(height: 8),
              _StorylineTypeChoice(
                key: const ValueKey('storylines-create-type-sidequest'),
                label: 'Quête annexe',
                description: 'Histoire secondaire optionnelle.',
                selected: _selectedType == StorylineType.sideQuest,
                enabled: _canCreateSideQuest,
                disabledReason: _canCreateSideQuest
                    ? null
                    : 'Créez d’abord une histoire principale pour organiser les quêtes annexes.',
                onTap: () => setState(() {
                  _selectedType = StorylineType.sideQuest;
                }),
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
