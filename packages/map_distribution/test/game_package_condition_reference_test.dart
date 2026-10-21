import 'dart:convert';
import 'dart:typed_data';

import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

void main() {
  const validator = GamePackageContentValidator(GamePackageSecurityPolicy());

  void validate(String path, Map<String, Object?> condition) {
    final bytes = Uint8List.fromList(utf8.encode(jsonEncode({
      'payload': {'conditionSource': condition},
    })));
    validator.validate(
      GamePackageFileEntry(
        path: path,
        size: bytes.length,
        sha256: '0' * 64,
        mediaType: 'application/json',
      ),
      bytes,
    );
  }

  for (final path in [
    'project/project.json',
    'project/catalog/objects/${'a' * 64}.json',
  ]) {
    for (final sourceId in [
      'hgss:sprout_tower_completed',
      'trainer_defeated:hgss-violet-elie',
    ]) {
      test('accepts the story flag $sourceId in $path', () {
        expect(
          () => validate(path, {
            'sourceKind': 'factLikeStoryFlag',
            'sourceId': sourceId,
            'operator': 'isTrue',
          }),
          returnsNormally,
        );
      });
    }
  }

  for (final value in [
    '../../outside.png',
    '/tmp/outside',
    r'\server\outside',
    'file:///tmp/outside',
    'https://example.test/outside',
    'hgss:../outside',
  ]) {
    test('rejects an escaping story flag reference $value', () {
      expect(
        () => validate('project/project.json', {
          'sourceKind': 'factLikeStoryFlag',
          'sourceId': value,
          'operator': 'isTrue',
        }),
        throwsA(isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'referenceEscapesRoot',
        )),
      );
    });
  }

  for (final condition in [
    {'sourceKind': 'map', 'sourceId': 'hgss:sprout_tower_completed'},
    {'sourceKind': 'factLikeStoryFlag', 'assetPath': 'hgss:outside'},
    {
      'sourceKind': 'factLikeStoryFlag',
      'sourceId': 'hgss:sprout_tower_completed',
      'assetPath': '../outside.png',
    },
  ]) {
    test('retains file reference checks for $condition', () {
      expect(
        () => validate('project/project.json', condition),
        throwsA(isA<GamePackageFormatException>().having(
          (error) => error.code,
          'code',
          'referenceEscapesRoot',
        )),
      );
    });
  }

  test('retains secret checks in story flag identifiers', () {
    expect(
      () => validate('project/project.json', {
        'sourceKind': 'factLikeStoryFlag',
        'sourceId': 'story:sk-ABCDEFGHIJKLMNOP',
        'operator': 'isTrue',
      }),
      throwsA(isA<GamePackageFormatException>().having(
        (error) => error.code,
        'code',
        'probableSecret',
      )),
    );
  });
}
