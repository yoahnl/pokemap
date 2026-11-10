part of 'cinematic_workspace_page.dart';

extension _CinematicPageCommands on _CinematicWorkspacePageState {
  void save() {
    if (flush()) unawaited(controller.save());
  }

  void undo() {
    if (flush()) controller.undo();
  }

  void redo() {
    if (flush()) controller.redo();
  }

  void copy() {
    if (flush()) clipboard = controller.copySteps(view!.selection);
  }

  void paste() {
    if (flush() && clipboard != null) {
      final a = controller.active!.asset;
      final index = a.timeline.steps.indexWhere((s) => s.id == view!.stepId);
      controller.pasteSteps(
        clipboard!,
        index < 0 ? a.timeline.steps.length : index + 1,
      );
    }
  }

  void deleteSteps() {
    if (flush()) controller.deleteSteps(view!.selection);
  }

  void open(String id) {
    if (!flush()) return;
    controller.transport.pause();
    unawaited(controller.open(id));
  }

  Future<void> create() async {
    if (!flush()) return;
    final name = await askNarrativeName(
      context,
      'Nouvelle cinématique sur carte',
    );
    if (name != null && mounted) {
      await controller.create(
        name,
        folderId: widget.views.folderId.isEmpty ? null : widget.views.folderId,
      );
    }
  }

  void duplicate() {
    if (flush()) unawaited(controller.duplicate(controller.activeId!));
  }

  Future<bool> confirm(String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            StudioButton(
              label: 'Annuler',
              secondary: true,
              onPressed: () => Navigator.pop(context, false),
            ),
            StudioButton(
              label: 'Confirmer',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> delete() async {
    if (!flush()) return;
    final owner = controller.active;
    if (await confirm(
      'Supprimer la cinématique ?',
      'Les scènes qui l’utilisent empêchent sa suppression.',
    )) {
      if (mounted &&
          controller.activeId == owner?.asset.id &&
          controller.active?.revision == owner?.revision) {
        await controller.delete(owner!.asset.id);
      }
    }
  }

  Future<void> reload() async {
    if (!flush()) return;
    final owner = controller.active!;
    if (controller.active!.dirty &&
        !await confirm(
          'Recharger ?',
          'Le brouillon de cette cinématique sera remplacé par la version enregistrée.',
        )) {
      return;
    }
    if (mounted &&
        controller.activeId == owner.asset.id &&
        controller.active?.revision == owner.revision) {
      await controller.reload();
    }
  }

  Future<void> archive() async {
    if (!flush()) return;
    await controller.setArchived(
      controller.project.cinematicLibraryCatalog.entries
              .where(
                (e) =>
                    e.family == CinematicLibraryFamily.world &&
                    e.cinematicId == controller.activeId,
              )
              .firstOrNull
              ?.isArchived !=
          true,
    );
  }

  void play() {
    if (!flush()) return;
    if (controller.transport.playing) {
      controller.transport.pause();
      return;
    }
    preparePlan();
    controller.transport.play();
  }

  Future<void> addAction(CinematicTimelineStepKind kind) async {
    if (!flush()) return;
    final state = view!;
    final id = await controller.addAction(
      kind,
      actorId: state.actorId,
      afterStepId: state.stepId,
      actorDisplay: model?.actors,
      choose: choose,
      isActive: () => mounted,
    );
    if (state.actorId != null &&
        (kind == CinematicTimelineStepKind.actorMove ||
            kind == CinematicTimelineStepKind.actorJump)) {
      state.mode = CinematicMapMode.destination;
    }
    if (!mounted) return;
    if (id == null && controller.error != null)
      state.actionError = controller.error;
    if (id != null) {
      state.selection
        ..clear()
        ..add(id);
      state.actionError = null;
    }
    refresh();
  }

  Future<String?> choose(String title, Map<String, String> options) =>
      showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(title),
          children: options.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Aucune ressource de ce type dans le projet.'),
                  ),
                ]
              : [
                  for (final entry in options.entries)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, entry.key),
                      child: Text(entry.value),
                    ),
                ],
        ),
      );
}
