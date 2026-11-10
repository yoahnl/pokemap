import 'package:avelune_studio/features/presentations/application/presentation_gesture_projection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test('a gesture changes only its clip and preserves the complete asset', () {
    final selected = PresentationTextClip(
      id: 'title',
      layerId: 'heading',
      startUs: 0,
      durationUs: 1000000,
      text: 'Rencontre',
    );
    final untouched = PresentationTextClip(
      id: 'subtitle',
      layerId: 'heading',
      startUs: 1000000,
      durationUs: 1000000,
      text: 'Le guide',
    );
    final asset = PresentationCinematicAsset(
      id: 'intro',
      title: 'Introduction',
      description: 'Préserver le document',
      durationUs: 3000000,
      layers: [PresentationLayer(id: 'heading', label: 'Titres', zIndex: 2)],
      tracks: [
        PresentationTrack(
          id: 'text',
          label: 'Titres',
          kind: selected.trackKind,
          clips: [selected, untouched],
        ),
      ],
    );
    final before = encodePresentationCinematicAsset(asset);
    final projected = projectPresentationGesture(asset, selected, {
      'from': {'translateX': .25},
    });
    final changed = projected.tracks.single.clips.first as PresentationTextClip;
    expect(changed.from.translateX, .25);
    expect(changed.text, selected.text);
    expect(projected.tracks.single.clips.last, same(untouched));
    expect(projected.layers, asset.layers);
    expect(projected.description, asset.description);
    expect(projected.durationUs, asset.durationUs);
    expect(encodePresentationCinematicAsset(asset), before);
  });
}
