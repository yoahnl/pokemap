import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeFactDefinition', () {
    test('creates a bool-first fact definition with stable metadata', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_harbor_fog_seen',
        label: 'Brume vue au port',
        description: 'Le joueur a vu la brume pour la première fois.',
        category: 'Port',
        defaultValue: true,
        tags: const ['intro', 'brume', 'intro'],
        legacyFlagName: 'story_flag.harbor_fog_seen',
      );

      expect(fact.id, 'fact_harbor_fog_seen');
      expect(fact.label, 'Brume vue au port');
      expect(fact.defaultValue, isTrue);
      expect(fact.tags, ['intro', 'brume']);
      expect(fact.legacyFlagName, 'story_flag.harbor_fog_seen');
    });

    test('rejects empty id and label', () {
      expect(
        () => NarrativeFactDefinition(id: '', label: 'Fact'),
        throwsArgumentError,
      );
      expect(
        () => NarrativeFactDefinition(id: 'fact_valid', label: '  '),
        throwsArgumentError,
      );
    });

    test('round-trips through JSON', () {
      final fact = NarrativeFactDefinition(
        id: 'fact_intro_complete',
        label: 'Introduction terminée',
        description: 'Fin de la première séquence.',
        category: 'Progression',
        defaultValue: false,
        tags: const ['story'],
        legacyFlagName: 'story_flag.intro_complete',
      );

      final json =
          jsonDecode(jsonEncode(fact.toJson())) as Map<String, dynamic>;
      final decoded = NarrativeFactDefinition.fromJson(json);

      expect(decoded, equals(fact));
      expect(decoded.toJson()['id'], 'fact_intro_complete');
      expect(decoded.toJson()['defaultValue'], isFalse);
    });
  });
}
