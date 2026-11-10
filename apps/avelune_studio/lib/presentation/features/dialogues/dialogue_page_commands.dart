part of 'dialogue_workspace_page.dart';

extension _DialoguePageCommands on _DialogueWorkspacePageState {
  Widget portrait(String? character, String? state, double size) =>
      DialoguePortraitImage(
        port: controller.port,
        characterId: character,
        stateId: state,
        size: size,
      );

  void undo() {
    flush();
    controller.undo();
  }

  void redo() {
    flush();
    controller.redo();
  }

  Future<void> connect(String id, String target) async {
    flush();
    await controller.connectSelection(
      id,
      target,
      confirmReplacement: () => confirm(
        'Remplacer la destination ?',
        'Le texte et le résultat de la réponse sont conservés. Seule sa destination change.',
      ),
      isActive: () => mounted,
    );
  }

  void save() {
    if (!flush()) return;
    unawaited(controller.save());
  }

  Future<void> open(String id) async {
    flush();
    await controller.open(id);
    if (mounted) {
      widget.views.libraryOpen = false;
      refresh();
    }
  }

  Future<void> create() async {
    flush();
    final name = await askNarrativeName(context, 'Nouveau dialogue');
    if (!mounted || name == null) return;
    await controller.create(
      name,
      folderId: widget.views.folderId.isEmpty ? null : widget.views.folderId,
    );
    if (mounted) refresh();
  }

  Future<void> rename() async {
    flush();
    final id = controller.activeId;
    final name = await askNarrativeName(context, 'Renommer le dialogue');
    if (mounted && name != null && controller.activeId == id) {
      controller.rename(name);
    }
  }

  void duplicate() {
    flush();
    if (controller.activeId case final id?) unawaited(controller.duplicate(id));
  }

  Future<bool> confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
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
  Future<void> deleteDialogue() async {
    flush();
    final id = controller.activeId;
    if (id == null) return;
    if (await confirm(
          'Supprimer ce dialogue ?',
          'Les dialogues encore utilisés resteront protégés.',
        ) &&
        mounted &&
        controller.activeId == id) {
      await controller.delete(id);
    }
  }

  Future<void> reload() async {
    flush();
    final id = controller.activeId;
    if (controller.active?.dirty == true &&
        !await confirm(
          'Recharger depuis le projet ?',
          'Le brouillon de ce dialogue sera abandonné.',
        )) {
      return;
    }
    if (mounted && id == controller.activeId) await controller.reload();
  }

  Future<void> addNode() async {
    flush();
    final owner = controller.activeId;
    final name = await askNarrativeName(context, 'Nouvelle suite');
    if (!mounted || owner != controller.activeId || name == null) return;
    final id = controller.addNode(name);
    if (id != null) {
      view!.select(id);
      widget.views.inspectorOpen = true;
      refresh();
    }
  }

  void addLine(bool narration) {
    flush();
    final id = view?.nodeId;
    if (id == null) return;
    final step = controller.addLine(
      id,
      text: narration ? 'Une nouvelle narration.' : 'Bonjour !',
      narration: narration,
    );
    view!.select(id, step: step);
    widget.views.inspectorOpen = true;
    refresh();
  }

  void addChoice() {
    flush();
    final id = view?.nodeId;
    if (id == null) return;
    final choice = controller.addChoice(id);
    if (choice == null) return;
    controller.addResponse(choice, 'Oui');
    controller.addResponse(choice, 'Non');
    view!.select(id, step: choice);
    widget.views.inspectorOpen = true;
    refresh();
  }

  Future<void> addOutcome() async {
    flush();
    final owner = controller.activeId, branch = view?.branchId;
    final label = await askNarrativeName(context, 'Nouveau résultat public');
    if (!mounted || label == null || owner != controller.activeId) return;
    final id = controller.addOutcome(label);
    if (id != null && branch != null) controller.assignOutcome(branch, id);
  }

  void deleteSelection() {
    flush();
    final state = view;
    if (state == null) return;
    controller.deleteSelection(
      wireId: state.wireId,
      branchId: state.branchId,
      stepId: state.stepId,
      nodeId: state.nodeId,
    );
    if (state.wireId != null) {
      state.wireId = null;
    } else if (state.branchId != null) {
      state.branchId = null;
    } else if (state.stepId != null) {
      state.stepId = null;
    }
    refresh();
  }
}
