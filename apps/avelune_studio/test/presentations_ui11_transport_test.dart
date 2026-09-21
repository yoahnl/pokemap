import 'package:avelune_studio/features/presentations/application/presentation_preview_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test(
    'canonical clock preserves pauses, exclusive ends and seek without mutation',
    () {
      final asset = _asset('a');
      final bytes = encodePresentationCinematicAsset(asset);
      final transport = PresentationPreviewTransport()..install(asset);
      addTearDown(transport.dispose);
      transport.play();
      transport.advance(500000);
      expect(transport.timeUs, 500000);
      expect(transport.frame!.texts, hasLength(1));
      transport.pause();
      transport.advance(100000);
      expect(transport.timeUs, 500000);
      transport.play();
      transport.advance(500000);
      expect(transport.timeUs, 1000000);
      expect(transport.frame!.texts, isEmpty);
      expect(transport.playing, isFalse);
      transport.seek(250000);
      expect(transport.frame!.texts, hasLength(1));
      expect(transport.playing, isFalse);
      transport.stop();
      expect(transport.timeUs, 0);
      expect(encodePresentationCinematicAsset(asset), bytes);
    },
  );

  test('document replacement and manual scrubs invalidate media epochs', () {
    final transport = PresentationPreviewTransport()..install(_asset('a'));
    addTearDown(transport.dispose);
    final initial = transport.mediaEpoch;
    transport.seek(600000);
    expect(transport.mediaEpoch, initial + 1);
    transport.install(_asset('b'));
    expect(transport.timeUs, 0);
    expect(transport.frame!.cinematicId, 'b');
    expect(transport.mediaEpoch, initial + 2);
    transport.clear();
    expect(transport.frame, isNull);
    expect(transport.playing, isFalse);
  });

  test('step and loop use shared microsecond transport semantics', () {
    final transport = PresentationPreviewTransport()..install(_asset('a'));
    addTearDown(transport.dispose);
    transport.stepForward();
    expect(transport.timeUs, 33333);
    transport.stepBackward();
    expect(transport.timeUs, 0);
    transport.setLoop(true);
    transport.play();
    transport.advance(1250000);
    expect(transport.timeUs, 250000);
    expect(transport.playing, isTrue);
  });
}

PresentationCinematicAsset _asset(String id) => PresentationCinematicAsset(
  id: id,
  title: 'Titre',
  durationUs: 1000000,
  layers: [PresentationLayer(id: 'text', label: 'Titre', zIndex: 0)],
  tracks: [
    PresentationTrack(
      id: 'visuals',
      label: 'Titre',
      kind: PresentationTrackKind.visual,
      clips: [
        PresentationTextClip(
          id: 'title',
          startUs: 0,
          durationUs: 1000000,
          layerId: 'text',
          text: 'Introduction',
        ),
      ],
    ),
  ],
);
