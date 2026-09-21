part of 'presentation_timeline.dart';

extension _PresentationTrackControls on _PresentationTimelineState {
  void command(PresentationTimelineClipCommand Function() action) {
    if (widget.beforeSelection?.call() == false) return;
    try {
      widget.onCommand(action());
      widget.view.actionError = null;
    } catch (error) {
      widget.view.actionError = 'Opération refusée : $error';
    }
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
        PresentationTimelineClipCommand(
          actionId: 'presentationTrack.update',
          parameters: {
            'cinematicId': owner.id,
            'track': {
              'id': track.id,
              'label': label,
              'kind': track.kind.name,
              'holdPolicy': hold,
              'clips': track.clips.map(encodePresentationClip).toList(),
            },
          },
        ),
      );
    } else {
      final index = owner.tracks.indexOf(track) + (result == 'up' ? -1 : 1);
      if (index < 0 || index >= owner.tracks.length) return;
      widget.onCommand(
        PresentationTimelineClipCommand(
          actionId: 'presentationTrack.move',
          parameters: {
            'cinematicId': owner.id,
            'trackId': track.id,
            'insertionIndex': index,
          },
        ),
      );
    }
    widget.changed();
  }
}
