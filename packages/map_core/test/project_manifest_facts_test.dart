import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest facts integration', () {
    test('decodes absent null and empty facts as empty list', () {
      expect(ProjectManifest.fromJson(_minimalProjectJson()).facts, isEmpty);
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'facts': null,
        }).facts,
        isEmpty,
      );
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'facts': <Object?>[],
        }).facts,
        isEmpty,
      );
    });

    test('round-trips facts through ProjectManifest JSON', () {
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        facts: [
          NarrativeFactDefinition(
            id: 'fact_harbor_fog_seen',
            label: 'Brume vue au port',
            description: 'Etat narratif lisible.',
            category: 'Port',
            defaultValue: true,
            tags: const ['brume'],
            legacyFlagName: 'story_flag.harbor_fog_seen',
          ),
        ],
      );

      final json =
          jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(json);

      expect(decoded.facts, equals(manifest.facts));
      expect(decoded.toJson()['facts'], isA<List<dynamic>>());
      expect((decoded.toJson()['facts'] as List).single['label'],
          'Brume vue au port');
    });

    test('rejects invalid facts JSON shape', () {
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'facts': 'not-a-list',
        }),
        throwsA(isA<Object>()),
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'facts': ['not-an-object'],
        }),
        throwsA(isA<Object>()),
      );
    });
  });
}

Map<String, dynamic> _minimalProjectJson() {
  return {
    'name': 'Project',
    'maps': <Object?>[],
    'tilesets': <Object?>[],
  };
}
