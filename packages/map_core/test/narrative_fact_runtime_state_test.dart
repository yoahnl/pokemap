import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('NarrativeFactRuntimeState', () {
    test('defaults to an empty immutable override map', () {
      const state = NarrativeFactRuntimeState.empty();

      expect(state.overridesByFactId, isEmpty);
      expect(
        () => state.overridesByFactId['fact_test'] = true,
        throwsUnsupportedError,
      );
    });

    test('defensively copies overrides and keeps explicit booleans', () {
      final input = <String, bool>{
        'fact_true': true,
        'fact_false': false,
      };
      final state = NarrativeFactRuntimeState(overridesByFactId: input);

      input['fact_true'] = false;
      input['fact_new'] = true;

      expect(state.overridesByFactId, {
        'fact_false': false,
        'fact_true': true,
      });
      expect(
        () => state.overridesByFactId['fact_true'] = false,
        throwsUnsupportedError,
      );
    });

    test('encodes override keys in stable lexical order', () {
      final state = NarrativeFactRuntimeState(
        overridesByFactId: const {
          'fact_z': true,
          'fact_a': false,
          'fact_m': true,
        },
      );

      final overrides = state.toJson()['overridesByFactId'] as Map;

      expect(overrides.keys, ['fact_a', 'fact_m', 'fact_z']);
      expect(
        jsonEncode(state.toJson()),
        '{"overridesByFactId":{"fact_a":false,"fact_m":true,"fact_z":true}}',
      );
    });

    test('rejects empty and non trim-exact fact IDs', () {
      expect(
        () => NarrativeFactRuntimeState(
          overridesByFactId: const {'': true},
        ),
        throwsArgumentError,
      );
      expect(
        () => NarrativeFactRuntimeState(
          overridesByFactId: const {' fact_test ': false},
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid JSON values and shape', () {
      expect(
        () => NarrativeFactRuntimeState.fromJson({
          'overridesByFactId': {'fact_test': 'false'},
        }),
        throwsFormatException,
      );
      expect(
        () => NarrativeFactRuntimeState.fromJson(const {}),
        throwsFormatException,
      );
      expect(
        () => NarrativeFactRuntimeState.fromJson({
          'overridesByFactId': <String, dynamic>{},
          'unexpected': true,
        }),
        throwsFormatException,
      );
      expect(
        () => NarrativeFactRuntimeState.fromJson({
          'overridesByFactId': {' fact_test ': false},
        }),
        throwsFormatException,
      );
    });

    test('round-trips orphan and default-equal overrides without dropping', () {
      final state = NarrativeFactRuntimeState(
        overridesByFactId: const {
          'fact_default_false': false,
          'fact_orphan': true,
        },
      );

      final decoded = NarrativeFactRuntimeState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );

      expect(decoded, state);
      expect(decoded.hashCode, state.hashCode);
      expect(decoded.overridesByFactId['fact_default_false'], isFalse);
      expect(decoded.overridesByFactId['fact_orphan'], isTrue);
    });
  });

  group('NarrativeFactRuntimeState persistence defaults', () {
    test('old GameState JSON without the subtree loads empty', () {
      final state = GameState.fromJson({'saveId': 'legacy_game_state'});

      expect(state.narrativeFactRuntimeState.overridesByFactId, isEmpty);
    });

    test('old SaveData JSON without the subtree loads empty', () {
      final save = SaveData.fromJson({'saveId': 'legacy_save_data'});

      expect(save.narrativeFactRuntimeState.overridesByFactId, isEmpty);
    });

    test('explicit null subtree is rejected by GameState and SaveData', () {
      expect(
        () => GameState.fromJson({
          'saveId': 'invalid_game_state',
          'narrativeFactRuntimeState': null,
        }),
        throwsFormatException,
      );
      expect(
        () => SaveData.fromJson({
          'saveId': 'invalid_save_data',
          'narrativeFactRuntimeState': null,
        }),
        throwsFormatException,
      );
    });

    test('GameState round-trip preserves true false and orphan overrides', () {
      final state = GameState(
        saveId: 'fact_state',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {
            'fact_false': false,
            'fact_orphan': true,
          },
        ),
      );

      final decoded = GameState.fromJson(
        jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
      );

      expect(
          decoded.narrativeFactRuntimeState, state.narrativeFactRuntimeState);
    });

    test('SaveData round-trip preserves true false and orphan overrides', () {
      final save = SaveData(
        saveId: 'fact_save',
        narrativeFactRuntimeState: NarrativeFactRuntimeState(
          overridesByFactId: const {
            'fact_false': false,
            'fact_orphan': true,
          },
        ),
      );

      final decoded = SaveData.fromJson(
        jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.narrativeFactRuntimeState, save.narrativeFactRuntimeState);
    });
  });
}
