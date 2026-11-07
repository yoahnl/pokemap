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
        if (widget.onPresentations != null)
          StudioButton(
            label: 'Présentation',
            secondary: true,
            onPressed: () {
              if (flush()) {
                controller.transport.pause();
                widget.onPresentations!();
              }
            },
          ),
        if (session != null &&
            widget.triggerScenes != null &&
            widget.onTriggerScene != null)
          StudioButton(
            label: 'Scène déclenchante',
            icon: Icons.account_tree_outlined,
            secondary: true,
            onPressed: () => openTriggerScene(session.asset.id),
          ),
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

  Future<void> openTriggerScene(String cinematicId) async {
    final references = widget.triggerScenes!(cinematicId);
    final chosen = await chooseSceneNodeReference(
      context,
      title: 'Scènes qui jouent cette cinématique',
      empty: 'Aucune scène ne joue encore cette cinématique. Ajoutez un bloc Cinématique dans une scène pour la déclencher.',
      references: references,
    );
    if (chosen == null || !mounted || !flush()) return;
    controller.transport.pause();
    final error = await widget.onTriggerScene!(chosen);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }
}
