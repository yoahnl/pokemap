import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/project_map_id_policy.dart';

void main() {
  const policy = ProjectMapIdPolicy();

  group('ProjectMapIdPolicy', () {
    test('accepts canonical lowercase IDs used by current projects', () {
      for (final mapId in <String>[
        'town',
        'route_01',
        'route-2',
        'a' * ProjectMapIdPolicy.maxLength,
      ]) {
        expect(policy.requireValid(mapId), mapId);
      }
    });

    test(
      'rejects empty, surrounding whitespace, separators and traversal',
      () {
        for (final mapId in <String>[
          '',
          ' town',
          'town ',
          'town square',
          'town/route',
          r'town\route',
          '.',
          '..',
          '../town',
          'town/../route',
          '_town',
          'town_',
          '-town',
          'town-',
          'a' * (ProjectMapIdPolicy.maxLength + 1),
        ]) {
          expect(
            () => policy.requireValid(mapId),
            throwsA(isA<EditorValidationException>()),
            reason: '"$mapId" must not be accepted as an authoring map ID',
          );
        }
      },
    );

    test(
      'rejects absolute paths, extensions, uppercase and reserved names',
      () {
        for (final mapId in <String>[
          '/town',
          r'C:\town',
          'C:/town',
          'town.json',
          'Town',
          'con',
          'prn',
          'aux',
          'nul',
          'com1',
          'com9',
          'lpt1',
          'lpt9',
        ]) {
          expect(
            () => policy.requireValid(mapId),
            throwsA(isA<EditorValidationException>()),
            reason: '"$mapId" must not be accepted as an authoring map ID',
          );
        }
      },
    );

    test('detects conflicts case-insensitively', () {
      expect(
        () => policy.requireAvailable('town', const <String>['Town']),
        throwsA(isA<EditorConflictException>()),
      );

      expect(
        () => policy.requireAvailable(
          'town',
          const <String>['Town', 'route_01'],
          excludingId: 'Town',
        ),
        returnsNormally,
      );
      expect(
        () => policy.requireAvailable(
          'town',
          const <String>['Town', 'town'],
          excludingId: 'Town',
        ),
        throwsA(isA<EditorConflictException>()),
      );
      expect(
        () => policy.requireAvailable(
          'harbor',
          const <String>['Town', 'route_01'],
        ),
        returnsNormally,
      );
      expect(
        () => policy.requireAvailable('../harbor', const <String>[]),
        throwsA(isA<EditorValidationException>()),
      );
    });

    test('creates a bounded canonical copy ID', () {
      expect(
        policy.nextCopyId('town', const <String>['route_01']),
        'town_copy',
      );
      expect(
        policy.nextCopyId('town', const <String>['TOWN_COPY']),
        'town_copy_1',
      );

      final sourceId = 'a' * ProjectMapIdPolicy.maxLength;
      final firstCandidate = '${'a' * 59}_copy';
      final candidate = policy.nextCopyId(
        sourceId,
        <String>[firstCandidate.toUpperCase()],
      );

      expect(candidate, '${'a' * 57}_copy_1');
      expect(candidate, hasLength(ProjectMapIdPolicy.maxLength));
      expect(policy.requireValid(candidate), candidate);
    });

    test('identifies legacy IDs without rewriting persisted values', () {
      final ids = <String>['town', 'Town', '../legacy', 'route-1'];

      expect(
        policy.nonCanonicalIds(ids),
        <String>['Town', '../legacy'],
      );
      expect(ids, <String>['town', 'Town', '../legacy', 'route-1']);
    });
  });
}
