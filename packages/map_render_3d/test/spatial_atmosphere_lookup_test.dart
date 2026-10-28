import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/spatial_atmosphere.dart';

void main() {
  test('water targets match by instance and material', () {
    final profile = SpatialAtmosphereProfile(
      waterTargets: const [
        SpatialAtmosphereTarget(instanceId: 'pond', materialName: 'water'),
        SpatialAtmosphereTarget.groundTileset('sea'),
      ],
    );

    expect(profile.isWater('pond', 'water'), isTrue);
    expect(profile.isWater('pond', 'stone'), isFalse);
    expect(profile.isWater('lake', 'water'), isFalse);
    expect(profile.isWater(null, 'ground:sea'), isTrue);
    expect(profile.isWater('', 'ground:sea'), isTrue);
    expect(profile.isWater('pond', null), isFalse);
  });

  test('window lookups return the last glow declared for a target', () {
    const target = SpatialAtmosphereTarget(
      instanceId: 'house',
      materialName: 'glass',
    );
    final first = SpatialWindowGlow(
      target: target,
      uvRects: const [Rect.fromLTRB(0, 0, .5, .5)],
    );
    final last = SpatialWindowGlow(
      target: target,
      uvRects: const [Rect.fromLTRB(.5, .5, 1, 1)],
      strength: 1.2,
    );
    final profile = SpatialAtmosphereProfile(windows: [first, last]);

    expect(profile.window('house', 'glass'), same(last));
    expect(profile.window('house', 'roof'), isNull);
    expect(profile.window(null, 'glass'), isNull);
  });
}
