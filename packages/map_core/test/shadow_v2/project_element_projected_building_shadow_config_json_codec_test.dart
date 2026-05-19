import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementProjectedBuildingShadowConfig JSON codec', () {
    test('encodes canonical config with enabled true', () {
      final config = _config();

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(config),
        _configJson(),
      );
    });

    test('encodes enabled false while keeping explicit preset and placement',
        () {
      final config = _config(enabled: false);

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(config),
        _configJson(enabled: false),
      );
    });

    test('decodes canonical config with enabled true', () {
      final config = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(),
      );

      expect(config.enabled, isTrue);
      expect(config.presetId, 'short-west-building-shadow');
      expect(config.anchor, ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98));
      expect(config.localOffset, ProjectedShadowOffset(x: 0, y: 0));
    });

    test('decodes canonical config with enabled false', () {
      final config = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(enabled: false),
      );

      expect(config, _config(enabled: false));
    });

    test('round-trips config instances through canonical JSON', () {
      final config = _config(
        enabled: false,
        presetId: 'long-east-building-shadow',
        anchorXRatio: 0.25,
        anchorYRatio: 0.9,
        offsetX: 3,
        offsetY: -2.5,
      );

      expect(
        decodeProjectElementProjectedBuildingShadowConfig(
          encodeProjectElementProjectedBuildingShadowConfig(config),
        ),
        config,
      );
    });

    test('round-trips JSON without re-emitting unknown keys', () {
      final json = _configJson(
        localOffset: _offsetJson(x: 3, y: -2.5),
      )
        ..['futureField'] = 'ignored'
        ..['anchor'] = (_anchorJson()..['futureAnchorField'] = true)
        ..['localOffset'] =
            (_offsetJson(x: 3, y: -2.5)..['futureOffsetField'] = true);

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(
          decodeProjectElementProjectedBuildingShadowConfig(json),
        ),
        _configJson(localOffset: _offsetJson(x: 3, y: -2.5)),
      );
    });

    test('rejects missing required fields', () {
      for (final field in <String>[
        'enabled',
        'presetId',
        'anchor',
        'localOffset',
      ]) {
        expect(
          () => decodeProjectElementProjectedBuildingShadowConfig(
            _without(_configJson(), field),
          ),
          throwsA(isA<ValidationException>()),
          reason: '$field should be required',
        );
      }
    });

    test('rejects invalid field types', () {
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(enabled: 'yes'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(presetId: 42),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(anchor: 'south-door'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(localOffset: 'origin'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid values delegated to model and value objects', () {
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(presetId: ''),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(
            anchor: _anchorJson(xRatio: 1.01),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(
            localOffset: _offsetJson(x: double.nan),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'short-west-building-shadow',
  double anchorXRatio = 0.5,
  double anchorYRatio = 0.98,
  double offsetX = 0,
  double offsetY = 0,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(
      xRatio: anchorXRatio,
      yRatio: anchorYRatio,
    ),
    localOffset: ProjectedShadowOffset(x: offsetX, y: offsetY),
  );
}

Map<String, Object?> _configJson({
  Object? enabled = true,
  Object? presetId = 'short-west-building-shadow',
  Object? anchor,
  Object? localOffset,
}) {
  return <String, Object?>{
    'enabled': enabled,
    'presetId': presetId,
    'anchor': anchor ?? _anchorJson(),
    'localOffset': localOffset ?? _offsetJson(),
  };
}

Map<String, Object?> _anchorJson({
  Object? xRatio = 0.5,
  Object? yRatio = 0.98,
}) {
  return <String, Object?>{
    'xRatio': xRatio,
    'yRatio': yRatio,
  };
}

Map<String, Object?> _offsetJson({
  Object? x = 0,
  Object? y = 0,
}) {
  return <String, Object?>{
    'x': x,
    'y': y,
  };
}

Map<String, Object?> _without(Map<String, Object?> source, String key) {
  return Map<String, Object?>.from(source)..remove(key);
}
