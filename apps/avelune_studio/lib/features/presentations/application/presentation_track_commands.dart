import 'package:map_authoring/map_authoring_presentation_editing.dart';
import 'package:map_core/map_core_domain.dart';

PresentationTimelineClipCommand presentationTrackUpdateCommand(
  PresentationCinematicAsset asset,
  PresentationTrack track, {
  required String label,
  required String holdPolicy,
}) => PresentationTimelineClipCommand(
  actionId: 'presentationTrack.update',
  parameters: {
    'cinematicId': asset.id,
    'track': {
      'id': track.id,
      'label': label,
      'kind': track.kind.name,
      'holdPolicy': holdPolicy,
      'clips': track.clips.map(encodePresentationClip).toList(),
    },
  },
);

PresentationTimelineClipCommand? presentationTrackMoveCommand(
  PresentationCinematicAsset asset,
  PresentationTrack track,
  int offset,
) {
  final index = asset.tracks.indexOf(track) + offset;
  if (index < 0 || index >= asset.tracks.length) return null;
  return PresentationTimelineClipCommand(
    actionId: 'presentationTrack.move',
    parameters: {
      'cinematicId': asset.id,
      'trackId': track.id,
      'insertionIndex': index,
    },
  );
}

String? runPresentationTimelineCommand(
  PresentationTimelineClipCommand Function() action,
  void Function(PresentationTimelineClipCommand) onCommand,
) {
  try {
    onCommand(action());
    return null;
  } catch (error) {
    return 'Opération refusée : $error';
  }
}
