import 'package:avelune_studio/features/presentations/coordination/presentation_editing_sessions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

PresentationCinematicAsset _asset({bool removeClip = false, int start = 0}) =>
    PresentationCinematicAsset(
      id: 'presentation',
      title: removeClip ? 'Revised' : 'Initial',
      durationUs: 1000000,
      layers: [PresentationLayer(id: 'image', label: 'Image', zIndex: 0)],
      tracks: [
        PresentationTrack(
          id: 'track',
          label: 'Image',
          kind: PresentationTrackKind.visual,
          clips: [
            PresentationVisualClip(
              id: 'keep',
              startUs: start,
              durationUs: 250000,
              layerId: 'image',
              resourceId: 'image-source',
            ),
            if (!removeClip)
              PresentationVisualClip(
                id: 'remove',
                startUs: 500000,
                durationUs: 250000,
                layerId: 'image',
                resourceId: 'image-source',
              ),
          ],
        ),
      ],
    );

void main() {
  test('an asset revision preserves its editor and clipboard while reconciling clip selection', () {
    final sessions = PresentationEditingSessions();
    addTearDown(sessions.dispose);
    final editor = sessions.forAsset(_asset());
    editor.selectClip('keep');
    editor.selectClip('remove', additive: true);
    editor.copySelection();
    final revised = _asset(removeClip: true, start: 100000);
    final current = sessions.forAsset(revised);
    expect(current, same(editor));
    expect(current.asset, same(revised));
    expect(current.sourceClip('keep').startUs, 100000);
    expect(current.selectedClipIds, {'keep'});
    expect(current.hasClipboard, isTrue);
    expect(sessions.forAsset(revised), same(current));
    expect(current.selectedClipIds, {'keep'});
  });
}
