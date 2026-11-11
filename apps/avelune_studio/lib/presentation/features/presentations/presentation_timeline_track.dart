part of 'presentation_timeline.dart';

extension _PresentationTrackControls on _PresentationTimelineState {
  void command(PresentationTimelineClipCommand Function() action) {
    if (widget.beforeSelection?.call() == false) return;
    widget.view.actionError = runPresentationTimelineCommand(
      action,
      widget.onCommand,
    );
    widget.changed();
  }

  Future<void> editTrack(PresentationTrack track) async {
    if (widget.beforeSelection?.call() == false) return;
    final owner = widget.asset;
    String label = track.label, hold = track.holdPolicy.name;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Piste temporelle'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudioCommitField(
                label: 'Nom de la piste',
                value: label,
                onCommit: (value) => label = value,
              ),
              const SizedBox(height: 12),
              StudioSelect(
                label: 'Pendant une interaction',
                value: hold,
                options: const {
                  'frozen': 'Suspendre avec la présentation',
                  'ambientContinues': 'Continuer les boucles ambiantes',
                },
                onChanged: (value) => hold = value,
              ),
              const SizedBox(height: 12),
              const Text(
                'L’ordre des pistes ne change ni les apparitions ni l’ordre visuel.',
              ),
            ],
          ),
        ),
        actions: [
          StudioButton(
            label: 'Monter',
            secondary: true,
            onPressed: () => Navigator.pop(context, 'up'),
          ),
          StudioButton(
            label: 'Descendre',
            secondary: true,
            onPressed: () => Navigator.pop(context, 'down'),
          ),
          StudioButton(
            label: 'Appliquer',
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              FocusManager.instance.applyFocusChangesIfNeeded();
              Navigator.pop(context, 'update');
            },
          ),
        ],
      ),
    );
    if (!mounted || result == null || !identical(owner, widget.asset)) return;
    if (result == 'update') {
      widget.onCommand(
        presentationTrackUpdateCommand(
          owner,
          track,
          label: label,
          holdPolicy: hold,
        ),
      );
    } else {
      final move = presentationTrackMoveCommand(
        owner,
        track,
        result == 'up' ? -1 : 1,
      );
      if (move == null) return;
      widget.onCommand(move);
    }
    widget.changed();
  }
}
