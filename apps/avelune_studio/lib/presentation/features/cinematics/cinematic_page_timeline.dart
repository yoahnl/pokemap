part of 'cinematic_workspace_page.dart';

extension _CinematicPageTimeline on _CinematicWorkspacePageState {
  Widget timeline(CinematicAsset asset, CinematicViewState state) =>
      CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.delete): deleteSteps,
          const SingleActivator(LogicalKeyboardKey.backspace): deleteSteps,
          const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): undo,
          const SingleActivator(
            LogicalKeyboardKey.keyZ,
            meta: true,
            shift: true,
          ): redo,
          const SingleActivator(LogicalKeyboardKey.keyC, meta: true): copy,
          const SingleActivator(LogicalKeyboardKey.keyV, meta: true): paste,
          const SingleActivator(LogicalKeyboardKey.keyZ, control: true): undo,
          const SingleActivator(
            LogicalKeyboardKey.keyZ,
            control: true,
            shift: true,
          ): redo,
          const SingleActivator(LogicalKeyboardKey.keyC, control: true): copy,
          const SingleActivator(LogicalKeyboardKey.keyV, control: true): paste,
          const SingleActivator(LogicalKeyboardKey.keyD, meta: true):
              duplicateSelection,
          const SingleActivator(LogicalKeyboardKey.keyD, control: true):
              duplicateSelection,
          const SingleActivator(LogicalKeyboardKey.space): play,
        },
        child: CinematicTimelineEditor(
          asset: asset,
          view: state,
          transport: controller.transport,
          changed: refresh,
          onPlay: play,
          beforeSelection: flush,
          onSelect: (id) {
            if (!flush()) return;
            state.selection
              ..clear()
              ..add(id);
            final block = controller.transport.plan?.timelineItems
                .where((b) => b.stepId == id)
                .firstOrNull;
            if (block != null) controller.transport.seek(block.startMs);
            refresh();
          },
          onMove: (index) {
            if (flush()) controller.moveSteps(state.selection, index);
          },
          onDuration: (id, ms) {
            if (flush()) controller.updateDuration(id, ms);
          },
        ),
      );
  void duplicateSelection() {
    if (flush()) controller.duplicateSteps(view!.selection);
  }
}
