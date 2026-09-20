part of 'cinematic_workspace_page.dart';

extension _CinematicPageHeader on _CinematicWorkspacePageState {
  Widget header(bool small) {
    final session = controller.active, state = view;
    return StudioPageHeader(
      title: 'Cinématique sur carte',
      prominent: !small,
      description: small
          ? null
          : 'Mettez vos acteurs en scène. Réglez leurs déplacements et le rythme.',
      alignActionsToEnd: true,
      actions: [
        StudioTool(
          label: 'Retour à ${widget.backLabel}',
          icon: Icons.arrow_back,
          onPressed: () {
            if (flush()) {
              controller.transport.pause();
              widget.onBack();
            }
          },
        ),
        StudioTool(
          label: 'Bibliothèque de cinématiques',
          icon: Icons.view_sidebar,
          onPressed: () {
            if (state != null && flush()) {
              state.libraryOpen = !state.libraryOpen;
              state.inspectorOpen = false;
              refresh();
            }
          },
        ),
        StudioTool(
          label: 'Inspecteur de cinématique',
          icon: Icons.tune,
          onPressed: state == null
              ? null
              : () {
                  if (flush()) {
                    state.inspectorOpen = !state.inspectorOpen;
                    state.libraryOpen = false;
                    refresh();
                  }
                },
        ),
        StudioTool(
          label: 'Annuler la cinématique',
          icon: Icons.undo,
          onPressed: controller.canUndo ? undo : null,
        ),
        StudioTool(
          label: 'Rétablir la cinématique',
          icon: Icons.redo,
          onPressed: controller.canRedo ? redo : null,
        ),
        StudioButton(
          label: 'Prévisualiser',
          icon: Icons.play_arrow,
          secondary: true,
          onPressed: session == null ? null : play,
        ),
        StudioButton(
          label: 'Enregistrer',
          icon: Icons.save_outlined,
          onPressed: session == null || controller.busy ? null : save,
        ),
      ],
    );
  }
}
