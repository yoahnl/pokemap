import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('selectRuntimePresentationVideo', () {
    const landscape = ProjectVideoVariantProfile(
      videoPath: 'presentation/landscape.mp4',
      posterPath: 'presentation/landscape.png',
      durationMilliseconds: 7000,
      width: 1920,
      height: 1080,
      bitrateKbps: 3000,
      sizeBytes: 5000000,
      videoCodec: 'h264',
    );
    const portrait = ProjectVideoVariantProfile(
      videoPath: 'presentation/portrait.mp4',
      posterPath: 'presentation/portrait.png',
      durationMilliseconds: 7000,
      width: 1080,
      height: 1920,
      bitrateKbps: 3000,
      sizeBytes: 5000000,
      videoCodec: 'h264',
    );

    test('selects the authored portrait variant on a portrait viewport', () {
      const media = ProjectResponsiveVideoProfile(
        landscape: landscape,
        portrait: portrait,
      );

      final selected = selectRuntimePresentationVideo(
        media,
        RuntimePresentationOrientation.portrait,
      );

      expect(selected.variant, portrait);
      expect(selected.orientation, RuntimePresentationOrientation.portrait);
      expect(selected.usedLandscapeFallback, isFalse);
    });

    test('falls back to landscape when no portrait variant is authored', () {
      const media = ProjectResponsiveVideoProfile(landscape: landscape);

      final selected = selectRuntimePresentationVideo(
        media,
        RuntimePresentationOrientation.portrait,
      );

      expect(selected.variant, landscape);
      expect(selected.orientation, RuntimePresentationOrientation.landscape);
      expect(selected.usedLandscapeFallback, isTrue);
    });

    test('keeps landscape selected on a landscape viewport', () {
      const media = ProjectResponsiveVideoProfile(
        landscape: landscape,
        portrait: portrait,
      );

      final selected = selectRuntimePresentationVideo(
        media,
        RuntimePresentationOrientation.landscape,
      );

      expect(selected.variant, landscape);
      expect(selected.orientation, RuntimePresentationOrientation.landscape);
      expect(selected.usedLandscapeFallback, isFalse);
    });
  });
}
