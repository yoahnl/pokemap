import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_depth_of_field.dart';

void main() {
  test('sharp zone follows camera depth with a gradual bounded blur', () {
    final profile = SpatialDepthOfFieldProfile(
      enabled: true,
      strength: .5,
      focusRange: 12,
    );
    for (final depth in [34.0, 38.0, 40.0, 42.0, 46.0]) {
      expect(profile.blurAtDepth(depth, focusDepth: 40), 0);
    }
    expect(profile.blurAtDepth(49, focusDepth: 40), closeTo(.25, .000001));
    expect(profile.blurAtDepth(52, focusDepth: 40), .5);
    expect(profile.blurAtDepth(28, focusDepth: 40), .5);
    expect(profile.blurAtDepth(70, focusDepth: 70), 0);
  });

  test('disabled or zero strength leaves every depth sharp', () {
    for (final profile in [
      SpatialDepthOfFieldProfile(),
      SpatialDepthOfFieldProfile(enabled: true, strength: 0),
    ]) {
      expect(profile.active, isFalse);
      expect(profile.blurAtDepth(100, focusDepth: 30), 0);
    }
  });

  test('invalid and nonfinite profiles are rejected', () {
    for (final strength in [-.1, 1.1, double.nan, double.infinity]) {
      expect(
        () => SpatialDepthOfFieldProfile(strength: strength),
        throwsArgumentError,
      );
    }
    for (final range in [1.9, 40.1, double.nan, double.infinity]) {
      expect(
        () => SpatialDepthOfFieldProfile(focusRange: range),
        throwsArgumentError,
      );
    }
  });
}
