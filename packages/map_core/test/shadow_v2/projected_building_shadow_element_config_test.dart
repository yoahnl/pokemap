import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementProjectedBuildingShadowConfig', () {
    test('accepts enabled true and stores all values', () {
      final anchor = ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98);
      final offset = ProjectedShadowOffset(x: 4, y: -2);

      final config = ProjectElementProjectedBuildingShadowConfig(
        enabled: true,
        presetId: 'short-west',
        anchor: anchor,
        localOffset: offset,
      );

      expect(config.enabled, isTrue);
      expect(config.presetId, 'short-west');
      expect(config.anchor, same(anchor));
      expect(config.localOffset, same(offset));
    });

    test('accepts enabled false and preserves preset intent', () {
      final config = _config(enabled: false);

      expect(config.enabled, isFalse);
      expect(config.presetId, 'short-west');
    });

    test('rejects blank preset ids', () {
      expect(
        () => _config(presetId: ''),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => _config(presetId: '   '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('stores spaced preset ids unchanged', () {
      final config = _config(presetId: ' short-west ');

      expect(config.presetId, ' short-west ');
    });

    test('composes valid anchor and positive or negative offsets', () {
      final positiveOffset = _config(
        anchor: ProjectedShadowAnchor(xRatio: 0, yRatio: 1),
        localOffset: ProjectedShadowOffset(x: 12, y: 6),
      );
      final negativeOffset = _config(
        anchor: ProjectedShadowAnchor(xRatio: 1, yRatio: 0),
        localOffset: ProjectedShadowOffset(x: -12, y: -6),
      );

      expect(positiveOffset.anchor.xRatio, 0);
      expect(positiveOffset.anchor.yRatio, 1);
      expect(positiveOffset.localOffset.x, 12);
      expect(positiveOffset.localOffset.y, 6);
      expect(negativeOffset.anchor.xRatio, 1);
      expect(negativeOffset.anchor.yRatio, 0);
      expect(negativeOffset.localOffset.x, -12);
      expect(negativeOffset.localOffset.y, -6);
    });

    test('uses value equality and matching hashCode', () {
      final a = _config();
      final b = _config();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('value equality includes enabled', () {
      expect(_config(enabled: true), isNot(_config(enabled: false)));
    });

    test('value equality includes presetId', () {
      expect(
        _config(presetId: 'short-west'),
        isNot(_config(presetId: 'long-east')),
      );
    });

    test('value equality includes anchor', () {
      expect(
        _config(anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98)),
        isNot(_config(anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.9))),
      );
    });

    test('value equality includes localOffset', () {
      expect(
        _config(localOffset: ProjectedShadowOffset(x: 0, y: 0)),
        isNot(_config(localOffset: ProjectedShadowOffset(x: 1, y: 0))),
      );
    });
  });
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'short-west',
  ProjectedShadowAnchor? anchor,
  ProjectedShadowOffset? localOffset,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: anchor ?? ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
    localOffset: localOffset ?? ProjectedShadowOffset(x: 0, y: 0),
  );
}
