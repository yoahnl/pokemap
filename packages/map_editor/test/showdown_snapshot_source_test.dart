import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/infrastructure/external/showdown_snapshot_source.dart';

void main() {
  group('ShowdownSnapshotSource', () {
    test('extracts species and loads structured snapshots', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/pokedex.json')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'bulbasaur': <String, Object?>{
                'name': 'Bulbasaur',
                'num': 1,
                'types': <String>['Grass', 'Poison'],
              },
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        if (request.url.path.endsWith('/learnsets.json')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'bulbasaur': <String, Object?>{
                'learnset': <String, Object?>{
                  'tackle': <String>['9L1']
                },
              },
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        if (request.url.path.endsWith('/moves.json')) {
          return http.Response(
            jsonEncode(<String, Object?>{
              'tackle': <String, Object?>{'name': 'Tackle'},
            }),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        return http.Response('not found', 404);
      });

      final source = ShowdownSnapshotSource(
        client: client,
        baseUri: 'https://showdown.test/data',
      );

      final species = await source.fetchSpecies('bulbasaur');
      final learnsets = await source.fetchLearnsetsSnapshot();
      final moves = await source.fetchMovesSnapshot();

      expect(species['id'], 'bulbasaur');
      expect(species['name'], 'Bulbasaur');
      expect(learnsets.containsKey('bulbasaur'), isTrue);
      expect(moves.containsKey('tackle'), isTrue);
    });

    test('surfaces a missing species cleanly', () async {
      final source = ShowdownSnapshotSource(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode(<String, Object?>{}),
            200,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }),
        baseUri: 'https://showdown.test/data',
      );

      await expectLater(
        () => source.fetchSpecies('missingno'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External Showdown species payload not found for species "missingno"',
          ),
        ),
      );
    });
  });
}
