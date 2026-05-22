import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementProjectedBuildingShadowConfig casterKind', () {
    test('defaults to null', () {
      final config = _config();

      expect(config.casterKind, isNull);
    });

    test('stores building casterKind', () {
      final config = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      expect(config.casterKind, ProjectedBuildingShadowCasterKind.building);
    });

    test('stores largeVolume casterKind', () {
      final config = _config(
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      expect(config.casterKind, ProjectedBuildingShadowCasterKind.largeVolume);
    });

    test('disabled config preserves casterKind', () {
      final config = _config(
        enabled: false,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      expect(config.enabled, isFalse);
      expect(config.casterKind, ProjectedBuildingShadowCasterKind.building);
    });

    test('equality includes casterKind', () {
      final withoutCaster = _config();
      final sameWithoutCaster = _config();
      final withBuilding = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );
      final sameWithBuilding = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );
      final withLargeVolume = _config(
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      expect(withoutCaster, sameWithoutCaster);
      expect(withBuilding, sameWithBuilding);
      expect(withoutCaster, isNot(withBuilding));
      expect(withBuilding, isNot(withLargeVolume));
    });

    test('hashCode includes casterKind', () {
      final first = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );
      final same = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );
      final changed = _config(
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      expect(first.hashCode, same.hashCode);
      expect(first, isNot(changed));
    });

    test('still rejects blank presetId with casterKind', () {
      expect(
        () => _config(
          presetId: '',
          casterKind: ProjectedBuildingShadowCasterKind.building,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'pokemon-building-shadow-footprint-adaptive',
  ProjectedBuildingShadowCasterKind? casterKind,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
    casterKind: casterKind,
  );
}
