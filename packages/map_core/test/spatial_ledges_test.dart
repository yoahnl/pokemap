import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('ledges preserve navigation JSON value semantics and bounds', () {
    final ledge = SpatialLedge(
      id: 'drop',
      x: 3,
      z: 2,
      direction: SpatialRampDirection.south,
    );
    final profile = SpatialNavigationProfile(ledges: [ledge]);
    final copy = SpatialNavigationProfile.fromJson(
      jsonDecode(jsonEncode(profile.toJson())) as Map<String, dynamic>,
    );
    expect(copy, profile);
    expect(copy.hashCode, profile.hashCode);
    expect(copy.copyWith().ledges.single, ledge);
    expect(ledge.landingX, 3);
    expect(ledge.landingZ, 4);
    expect(
      () => SpatialNavigationProfile(ledges: [ledge, ledge]),
      throwsFormatException,
    );
    expect(
      () => MapSpatialScene(width: 4, depth: 4, navigation: profile),
      throwsFormatException,
    );
  });
  test('uphill jumps and invalid geometry are rejected', () {
    final ledge = SpatialLedge(
      id: 'drop',
      x: 2,
      z: 1,
      direction: SpatialRampDirection.south,
    );
    expect(
      () => MapSpatialScene(
        width: 6,
        depth: 6,
        navigation: SpatialNavigationProfile(ledges: [ledge]),
        heightLevels: [
          for (var z = 0; z < 6; z++)
            for (var x = 0; x < 6; x++) z >= 3 ? 1 : 0,
        ],
      ),
      throwsFormatException,
    );
    for (final bad in [double.nan, 0.0, 5.0]) {
      expect(
        () => SpatialLedge(
          id: 'drop',
          x: 2,
          z: 1,
          direction: SpatialRampDirection.south,
          height: bad,
        ),
        throwsFormatException,
      );
    }
  });
}
