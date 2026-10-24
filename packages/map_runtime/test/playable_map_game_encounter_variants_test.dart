import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'playable_map_game_flash_test.dart' show tickUntil;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final (minute, eligible) in [(239, false), (240, true), (599, true), (600, false), (1200, false), (0, false)]) {
    test('production movement uses injected local clock and persisted version at minute $minute', () async {
      final root = await Directory.systemTemp.createTemp('runtime-encounter-variants-');
      addTearDown(() => root.delete(recursive: true));
      final table = ProjectEncounterTable(id: 'route', name: 'Route', encounterKind: EncounterKind.walk,
        chancePerStep: 0,
        variants: [ProjectEncounterVariant(id: 'morning', name: 'Morning',
          conditions: [ScriptConditionFactory.factEquals('edition', const NarrativeValue.string('soulsilver'))],
          timeWindows: [const LocalTimeWindow(startMinute: 240, endMinute: 600)],
          entries: [const ProjectEncounterEntry(speciesId: 'sentret', minLevel: 2, maxLevel: 3)])]);
      const map = MapData(id: 'route', name: 'Route', size: GridSize(width: 4, height: 2),
        gameplayZones: [MapGameplayZone(id: 'patch', kind: GameplayZoneKind.encounter,
          area: MapRect(pos: GridPos(x: 1, y: 0), size: GridSize(width: 1, height: 1)),
          cellMask: [GridPos(x: 0, y: 0)],
          encounter: EncounterZonePayload(encounterTableId: 'route'))]);
      final manifest = ProjectManifest(name: 'Variants', maps: [const ProjectMapEntry(id: 'route', name: 'Route', relativePath: 'route.json')],
        tilesets: [], encounterTables: [table], facts: [NarrativeFactDefinition(id: 'edition', label: 'Edition', initialValue: const NarrativeValue.string('heartgold'))]);
      final file = File('${root.path}/project.json');
      await file.writeAsString(jsonEncode(manifest.toJson()));
      final initial = GameState.fromJson(GameState(saveId: 'variants', currentMapId: 'route',
        narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(valuesByFactId: {'edition': const NarrativeValue.string('soulsilver')})).toJson());
      final random = _CountingRandom();
      var clockCalls = 0;
      final game = _Game(bundle: RuntimeMapBundle(manifest: manifest, map: map,
        projectRootDirectory: root.path, tilesetAbsolutePathsById: {}),
        projectFilePath: file.path, initialGameState: initial,
        encounterRandom: random, encounterClock: () {
          clockCalls++;
          return DateTime(2026, 1, 1, minute ~/ 60, minute % 60);
        });
      addTearDown(game.onRemove);
      game.onGameResize(Vector2(640, 480));
      await game.onLoad();
      await tickUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
      game.handleRuntimeInputEvent(const RuntimeInputEvent.press(RuntimeInputControl.right));
      game.update(.016);
      game.handleRuntimeInputEvent(const RuntimeInputEvent.release(RuntimeInputControl.right));
      await tickUntil(game, () => !game.debugIsPlayerStepping);
      expect(game.gameStateSnapshot.playerPosition, const GridPos(x: 1, y: 0));
      expect(game.debugEncounterCheckCount, 1);
      expect(clockCalls, greaterThan(0));
      expect(random.calls, eligible ? 1 : 0);
      expect(game.debugPendingBattleRequest, isNull);
      expect(game.debugActiveBattleRequest, isNull);
      expect(game.gameStateSnapshot.bag, initial.bag);
      expect(game.gameStateSnapshot.narrativeFactRuntimeState, initial.narrativeFactRuntimeState);
    });
  }
}

final class _Game extends PlayableMapGame {
  _Game({required super.bundle, required super.projectFilePath, super.initialGameState,
    super.encounterRandom, super.encounterClock});
  @override
  bool get isLoaded => true;
}

final class _CountingRandom implements Random {
  int calls = 0;
  @override
  double nextDouble() { calls++; return .5; }
  @override
  int nextInt(int max) => throw StateError('No candidate may be selected with chance zero');
  @override
  bool nextBool() => throw StateError('Unexpected RNG');
}
