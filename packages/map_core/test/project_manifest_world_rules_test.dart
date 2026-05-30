import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectManifest worldRules integration', () {
    test('decodes absent null and empty worldRules as empty list', () {
      expect(
          ProjectManifest.fromJson(_minimalProjectJson()).worldRules, isEmpty);
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'worldRules': null,
        }).worldRules,
        isEmpty,
      );
      expect(
        ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'worldRules': <Object?>[],
        }).worldRules,
        isEmpty,
      );
    });

    test('round-trips world rules through ProjectManifest JSON', () {
      final manifest = ProjectManifest(
        name: 'Project',
        maps: const [],
        tilesets: const [],
        worldRules: [
          WorldRuleDefinition(
            id: 'world_rule_hide_actor',
            label: 'Masquer un acteur',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.fact,
              sourceId: 'fact_actor_hidden',
              predicate: WorldRuleSourcePredicate.isTrue,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map_test',
              entityId: 'entity_actor',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );

      final json =
          jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>;
      final decoded = ProjectManifest.fromJson(json);

      expect(decoded.worldRules, equals(manifest.worldRules));
      expect(decoded.toJson()['worldRules'], isA<List<dynamic>>());
      expect((decoded.toJson()['worldRules'] as List).single['label'],
          'Masquer un acteur');
    });

    test('rejects invalid worldRules JSON shape', () {
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'worldRules': 'not-a-list',
        }),
        throwsA(isA<Object>()),
      );
      expect(
        () => ProjectManifest.fromJson({
          ..._minimalProjectJson(),
          'worldRules': ['not-an-object'],
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
