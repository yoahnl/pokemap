part of 'story_page.dart';

extension _StoryPageMemory on _StoryPageState {
  Future<bool> _openMemoryUsage(NarrativeOwner owner, String factId) async {
    final navigation = ++_memoryNavigation;
    final parentNavigation = widget.navigationState?.call();
    final revision = widget.staging.revision;
    bool current() =>
        mounted &&
        navigation == _memoryNavigation &&
        parentNavigation == widget.navigationState?.call() &&
        identical(revision, widget.staging.revision);
    await widget.beforeNavigation?.call();
    if (!current()) return true;
    switch (owner.kind) {
      case NarrativeOwnerKind.event:
        if (widget.behaviourCatalog == null) {
          return widget.behaviours.open(owner.id);
        }
        _showMemorySection(StorySection.behaviours, () {});
        return _openCatalogBehaviour(owner.id);
      case NarrativeOwnerKind.scene:
        final open = widget.openScene;
        if (open == null) return false;
        if (widget.staging.draft.isLoaded(StoryDraftKind.scene, owner.id)) {
          if (widget.staging.draft.currentOf(StoryDraftKind.scene, owner.id) ==
              null) {
            return false;
          }
        } else {
          await (widget.catalog?.readDocument(owner.id) ??
              widget.port!.sceneDocument(owner.id));
        }
        if (!current()) return true;
        open(owner.id, null);
        return true;
      case NarrativeOwnerKind.worldRule:
        final memory = _memory;
        if (memory == null) return false;
        await memory.rules.open();
        if (!current()) return true;
        if (!memory.rules.rows.any((row) => row.rule.id == owner.id)) {
          return false;
        }
        _showMemorySection(
          StorySection.rules,
          () => memory.rules.select(owner.id),
        );
        return mounted;
      case NarrativeOwnerKind.dialogue:
        _openSection(StorySection.dialogues);
        final dialogues = _dialogues;
        if (dialogues == null) return false;
        await dialogues.open();
        if (!current()) return true;
        await dialogues.load(owner.id);
        if (!current()) return true;
        if (dialogues.document(owner.id) == null) return false;
        _showMemorySection(
          StorySection.dialogues,
          () => dialogues.select(owner.id),
        );
        return mounted;
      case NarrativeOwnerKind.storyline:
        final trame = widget.trame;
        final memory = _memory;
        if (trame == null || memory == null) return false;
        final targets = await memory.storyUsageTargets(owner, factId);
        if (!current()) return true;
        if (targets.isEmpty) return false;
        final target = targets.length == 1
            ? targets.single
            : await _chooseMemoryTarget(targets);
        if (!current()) return true;
        if (target == null) return true;
        await trame.open();
        if (!current()) return true;
        final story = trame.view?.outline.storylines
            .where((story) => story.id == owner.id)
            .firstOrNull;
        if (story == null ||
            (target.stepId != null &&
                !story.chapters
                    .expand((chapter) => chapter.milestones)
                    .any((step) => step.id == target.stepId))) {
          return false;
        }
        _showMemorySection(
          StorySection.trame,
          () =>
              trame.usageFocus = (storylineId: owner.id, stepId: target.stepId),
        );
        return mounted;
      case NarrativeOwnerKind.cinematic:
        return false;
    }
  }

  void _showMemorySection(StorySection section, VoidCallback select) {
    _openSection(section);
    _workspace = _workspace.select(section);
    select();
    _changed();
  }

  Future<GameMemoryUsageTarget?> _chooseMemoryTarget(
    List<GameMemoryUsageTarget> targets,
  ) {
    GameMemoryUsageTarget? selected;
    return showDialog<GameMemoryUsageTarget>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSelection) => StudioReviewDialog(
          key: const ValueKey('memory-usage-targets'),
          title: context.l10n.memoryChooseUsage,
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final target in targets)
                  StudioChoice(
                    key: ValueKey(
                      target.stepId == null
                          ? 'memory-usage-target-root'
                          : 'memory-usage-target-step-${target.stepId}',
                    ),
                    label: target.title,
                    selected: selected == target,
                    onTap: () => setSelection(() => selected = target),
                  ),
              ],
            ),
          ),
          confirmLabel: context.l10n.memoryOpen,
          cancelLabel: context.l10n.memoryCancel,
          onConfirmed: selected == null
              ? null
              : () => Navigator.of(context).pop(selected),
          onCancelled: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}
