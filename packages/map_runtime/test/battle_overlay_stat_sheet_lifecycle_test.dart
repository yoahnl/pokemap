import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('late stat sheet bytes cannot restore images after overlay removal',
      () async {
    final pending = <Completer<ByteData>>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = utf8.decode(message!.buffer
          .asUint8List(message.offsetInBytes, message.lengthInBytes));
      final file = File(key.replaceFirst('packages/map_runtime/', ''));
      if (!await file.exists()) return null;
      final bytes = ByteData.sublistView(await file.readAsBytes());
      if (key.contains('/battle/stats/')) {
        final gate = Completer<ByteData>();
        pending.add(gate);
        return gate.future.then((_) => bytes);
      }
      return bytes;
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    final overlay = BattleOverlayComponent(
      itemCapabilityResolver: ItemCapabilityResolver(
          ItemCatalogSnapshot.fromCatalog(mvpItemCatalog)),
      session: createBattleSession(BattleSetup.pokeMapBetaV1ForTest(
          playerPokemon: _combatant('player'),
          enemyPokemon: _combatant('enemy'),
          isTrainerBattle: false,
          trainerId: null,
          allowCapture: false)),
      viewportSize: Vector2(960, 540),
      onPlayerChoice: (_) {},
    );
    await overlay.onLoad();
    for (var i = 0; i < 100 && pending.length < 2; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(pending.length, 2);
    overlay.onRemove();
    for (final gate in pending) {
      gate.complete(ByteData(0));
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(overlay.debugStatSheetCount, 0);
  });
}

BattleCombatantData _combatant(String speciesId) => BattleCombatantData(
      speciesId: speciesId,
      lineupIndex: 0,
      level: 30,
      maxHp: 40,
      currentHp: 40,
      stats: const BattleStatsSnapshot(
          attack: 60,
          defense: 60,
          specialAttack: 60,
          specialDefense: 60,
          speed: 50),
      moves: const [
        BattleMoveData(
            id: 'wait',
            name: 'Wait',
            power: 0,
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.self,
            accuracy: BattleMoveAccuracy.alwaysHits())
      ],
    );
