import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/presentation/features/player/pages/hub_spatial_render_resolution.dart';

void main() {
  test('high density handhelds render the 3D pass at half resolution', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      expect(
        hubSpatialRenderResolutionScale(platform: platform, devicePixelRatio: 3),
        .5,
      );
      expect(
        hubSpatialRenderResolutionScale(
          platform: platform,
          devicePixelRatio: 2.3,
        ),
        .5,
      );
    }
  });

  test('low density handhelds keep native resolution', () {
    expect(
      hubSpatialRenderResolutionScale(
        platform: TargetPlatform.android,
        devicePixelRatio: 1.5,
      ),
      1,
    );
  });

  test('desktop players keep native resolution', () {
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      expect(
        hubSpatialRenderResolutionScale(platform: platform, devicePixelRatio: 2),
        1,
      );
    }
  });
}
