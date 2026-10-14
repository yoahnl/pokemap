import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('project settings preserve an explicit logical retention policy', () {
    final policy = <String, dynamic>{
      'schemaVersion': 1,
      'viewportWidthTiles': 16,
      'viewportHeightTiles': 12,
      'marginTiles': 6,
      'clampViewportToMapIds': ['center'],
    };
    final settings = ProjectSettings.fromJson({
      'mapInstanceRetentionPolicy': policy,
    });
    expect(settings.toJson()['mapInstanceRetentionPolicy'], policy);
  });
  test('a project without a policy has no implicit logical viewport', () {
    final settings = ProjectSettings.fromJson({});
    expect(settings.mapInstanceRetentionPolicy, isNull);
    expect(
      settings.toJson().containsKey('mapInstanceRetentionPolicy'),
      isFalse,
    );
    expect(
      ProjectSettings.fromJson({'mapInstanceRetentionPolicy': null}),
      settings,
    );
  });

  test(
    'policy constructor copies its map identifiers and serializes sorted',
    () {
      final identifiers = <String>['outside', 'center'];
      final policy = MapInstanceRetentionPolicy(
        viewportWidthTiles: 16,
        viewportHeightTiles: 12,
        marginTiles: 6,
        clampViewportToMapIds: identifiers,
      );
      identifiers.clear();
      expect(policy.clampViewportToMapIds, {'center', 'outside'});
      expect(
        () => policy.clampViewportToMapIds.clear(),
        throwsUnsupportedError,
      );
      expect(policy.toJson()['clampViewportToMapIds'], ['center', 'outside']);
      final restored = MapInstanceRetentionPolicy.fromJson(policy.toJson());
      expect(restored, policy);
      expect(restored.hashCode, policy.hashCode);
      expect(
        ProjectSettings(
          mapInstanceRetentionPolicy: policy,
        ).copyWith(displayScale: 3).mapInstanceRetentionPolicy,
        policy,
      );
    },
  );

  test('policy equality treats map identifiers as a set', () {
    final left = _policy(['center', 'outside']);
    final right = _policy(['outside', 'center']);
    expect(left, right);
    expect(left.hashCode, right.hashCode);
  });

  for (final field in [
    'viewportWidthTiles',
    'viewportHeightTiles',
    'marginTiles',
  ]) {
    for (final value in [null, '16', 16.0, true, -1, 2147483648]) {
      test('policy rejects $field=$value', () {
        final json = _policy().toJson()..[field] = value;
        expect(
          () => MapInstanceRetentionPolicy.fromJson(json),
          throwsFormatException,
        );
        expect(
          () => ProjectSettings.fromJson({'mapInstanceRetentionPolicy': json}),
          throwsFormatException,
        );
      });
    }
  }

  test('zero viewport dimensions are rejected while zero margin is valid', () {
    for (final field in ['viewportWidthTiles', 'viewportHeightTiles']) {
      final json = _policy().toJson()..[field] = 0;
      expect(
        () => MapInstanceRetentionPolicy.fromJson(json),
        throwsFormatException,
      );
    }
    final json = _policy().toJson()..['marginTiles'] = 0;
    expect(MapInstanceRetentionPolicy.fromJson(json).marginTiles, 0);
  });

  test('policy rejects unsupported schema missing and unknown keys', () {
    for (final version in [null, 0, 2, 1.0, '1']) {
      final json = _policy().toJson()..['schemaVersion'] = version;
      expect(
        () => MapInstanceRetentionPolicy.fromJson(json),
        throwsFormatException,
      );
    }
    final missing = _policy().toJson()..remove('marginTiles');
    final extra = _policy().toJson()..['sourceFormat'] = 'Ruby';
    expect(
      () => MapInstanceRetentionPolicy.fromJson(missing),
      throwsFormatException,
    );
    expect(
      () => MapInstanceRetentionPolicy.fromJson(extra),
      throwsFormatException,
    );
  });

  test(
    'policy rejects malformed noncanonical or duplicate map identifiers',
    () {
      for (final value in [
        null,
        {},
        [1],
        [''],
        [' center'],
        ['center '],
        ['center', 'center'],
      ]) {
        final json = _policy().toJson()..['clampViewportToMapIds'] = value;
        expect(
          () => MapInstanceRetentionPolicy.fromJson(json),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'constructor validates native sizes and identities independently of JSON',
    () {
      expect(
        () => MapInstanceRetentionPolicy(
          viewportWidthTiles: 0,
          viewportHeightTiles: 12,
          marginTiles: 6,
        ),
        throwsArgumentError,
      );
      expect(
        () => MapInstanceRetentionPolicy(
          viewportWidthTiles: 16,
          viewportHeightTiles: 12,
          marginTiles: -1,
        ),
        throwsArgumentError,
      );
      expect(() => _policy([' center']), throwsArgumentError);
    },
  );
}

MapInstanceRetentionPolicy _policy([Iterable<String> mapIds = const []]) =>
    MapInstanceRetentionPolicy(
      viewportWidthTiles: 16,
      viewportHeightTiles: 12,
      marginTiles: 6,
      clampViewportToMapIds: mapIds,
    );
