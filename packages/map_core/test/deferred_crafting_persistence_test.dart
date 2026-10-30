import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('strict save restores deferred orders and observed calendar', () {
    final json = strictGameStateSaveJson(const GameState(saveId: 'craft-save'));
    json['gameplayCalendarState'] = {
      'schemaVersion': 1,
      'observedLocalDay': '2026-10-30',
      'dayRevision': 4,
    };
    json['deferredCraftingState'] = {
      'schemaVersion': 1,
      'servicesById': {
        'artisan': {
          'revision': 1,
          'pendingOrder': {
            'schemaVersion': 1,
            'orderId': 'artisan:1',
            'recipeId': 'red',
            'inputItemId': 'red-fruit',
            'inputQuantity': 3,
            'outputItemId': 'red-ball',
            'outputQuantity': 3,
            'submittedDayRevision': 4,
            'requiredDayChanges': 1,
          },
        },
      },
    };
    final before = jsonEncode(json);
    final state = gameStateFromStrictSaveJson(json);
    expect(
      state.toJson()['gameplayCalendarState'],
      json['gameplayCalendarState'],
    );
    expect(
      state.toJson()['deferredCraftingState'],
      json['deferredCraftingState'],
    );
    final restored = gameStateFromSaveData(
      SaveData.fromJson(saveDataFromGameState(state).toJson()),
    );
    expect(
      restored.toJson()['gameplayCalendarState'],
      json['gameplayCalendarState'],
    );
    expect(
      restored.toJson()['deferredCraftingState'],
      json['deferredCraftingState'],
    );
    expect(jsonEncode(json), before);
  });
  test(
    'signed save envelope retains orders and rejects future state without rewriting bytes',
    () {
      const mapper = GameStateSaveEnvelopeMapper();
      const codec = SaveEnvelopeCodec();
      const saveId = '018f255f-2d50-4f4f-8aa2-c893ae06b8c1';
      final state = GameState(
        saveId: saveId,
        gameplayCalendarState: GameplayCalendarState(
          observedLocalDay: '2026-10-30',
          dayRevision: 4,
        ),
        deferredCraftingState: DeferredCraftingState(
          servicesById: {
            'artisan': DeferredCraftingServiceState(
              revision: 1,
              pendingOrder: DeferredCraftingOrder(
                orderId: 'artisan:1',
                recipeId: 'fruit',
                inputItemId: 'fruit',
                inputQuantity: 3,
                outputItemId: 'ball',
                outputQuantity: 3,
                submittedDayRevision: 4,
                requiredDayChanges: 1,
              ),
            ),
          },
        ),
      );
      final envelope = mapper.create(
        identity: GameIdentity(
          gameId: 'games.example.crafting',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v8,
          saveFormat: SaveEnvelopeCodec.currentSaveFormat,
          compatibilityId: 'crafting-v1',
        ),
        profileId: 'player-1',
        slotId: 'slot-1',
        saveId: saveId,
        createdAt: DateTime.utc(2026, 10, 30),
        updatedAt: DateTime.utc(2026, 10, 30),
        status: SaveStatus.active,
        playTimeSeconds: 0,
        gameState: state,
      );
      final restored = mapper.restore(
        codec.decodeUtf8(utf8.encode(codec.encode(envelope))),
      );
      expect(restored.gameplayCalendarState, state.gameplayCalendarState);
      expect(restored.deferredCraftingState, state.deferredCraftingState);
      expect(codec.verifyChecksum(envelope), isTrue);
      for (final field in ['gameplayCalendarState', 'deferredCraftingState']) {
        final future =
            jsonDecode(codec.encode(envelope)) as Map<String, dynamic>;
        final futureState = future['state'] as Map<String, dynamic>;
        (futureState[field] as Map<String, dynamic>)['schemaVersion'] = 999;
        future['checksum'] = {
          'algorithm': 'sha256',
          'value': codec.computeChecksum(future),
        };
        final bytes = utf8.encode(jsonEncode(future));
        final before = List<int>.of(bytes);
        final decoded = codec.decodeUtf8(bytes);
        final originalEnvelope = codec.encode(decoded);
        expect(
          () => mapper.restore(decoded),
          throwsA(isA<SaveContractException>()),
        );
        expect(bytes, before);
        expect(codec.encode(decoded), originalEnvelope);
      }
    },
  );
}
