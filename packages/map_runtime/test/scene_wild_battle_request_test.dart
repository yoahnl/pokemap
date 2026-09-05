import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_battle_runtime_outcome_adapter.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_battle_runtime_outcome_result.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_wild_battle_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const request = SceneBattleRuntimeBattleRequest(
    requestId: 'scene-zigzagoon',
    createdAtEpochMs: 1742,
    trainerId: '',
    npcEntityId: 'zigzagoon-bag',
    battleKind: 'wild',
    battleTemplateId: 'zigzagoon-fixed',
  );
  const returnContext = OverworldReturnContext(
    mapId: 'sanctuary',
    playerPos: GridPos(x: 8, y: 6),
    playerFacing: Direction.south,
  );
  ProjectManifest manifest(List<ProjectEncounterEntry> entries) => ProjectManifest(
    name: 'Wild scene fixture',
    maps: const [],
    tilesets: const [],
    encounterTables: [ProjectEncounterTable(
      id: 'zigzagoon-fixed',
      name: 'Zigzaton de la sacoche',
      encounterKind: EncounterKind.special,
      entries: entries,
    )],
  );

  test('a scripted Pokemon uses the wild pipeline and retains capture data', () {
    final result = buildSceneWildBattleRequest(
      request: request,
      manifest: manifest(const [ProjectEncounterEntry(speciesId: 'zigzagoon', minLevel: 4, maxLevel: 4)]),
      returnContext: returnContext,
    );
    expect(result.kind, RuntimeBattleKind.wild);
    expect(result.speciesId, 'zigzagoon');
    expect(result.level, 4);
    expect(result.encounterKind, EncounterKind.special);
    expect(result.returnContext, returnContext);
    expect(result.pokemonOverrides, isNull);
    expect(result.generationSeed, 1742);
  });

  test('an ambiguous authored encounter is rejected before battle starts', () {
    for (final entries in <List<ProjectEncounterEntry>>[
      [],
      const [ProjectEncounterEntry(speciesId: 'zigzagoon', minLevel: 4, maxLevel: 5)],
      const [
        ProjectEncounterEntry(speciesId: 'zigzagoon', minLevel: 4, maxLevel: 4),
        ProjectEncounterEntry(speciesId: 'pidgey', minLevel: 4, maxLevel: 4),
      ],
    ]) {
      expect(() => buildSceneWildBattleRequest(request: request, manifest: manifest(entries), returnContext: returnContext), throwsStateError);
    }
  });

  test('capture and escape return explicit scene branches', () {
    expect(const SceneBattleRuntimeOutcomeResult.completed(port: SceneBattleRuntimeOutcomePort.captured).scenePortId, 'captured');
    expect(const SceneBattleRuntimeOutcomeResult.completed(port: SceneBattleRuntimeOutcomePort.runaway).scenePortId, 'runaway');
  });
}
