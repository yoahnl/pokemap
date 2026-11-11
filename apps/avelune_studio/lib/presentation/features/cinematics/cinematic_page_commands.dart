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
      controller.pasteSteps(
        clipboard!,
        cinematicPasteIndex(controller.active!.asset, view!.stepId),
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
        folderId: cinematicLibraryFolderOrRoot(widget.views.folderId),
      );
    }
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
  void play() {
    if (!flush()) return;
    if (controller.transport.playing) {
      controller.transport.pause();
      return;
    }
    preparePlan();
    controller.transport.play();
  }
}
