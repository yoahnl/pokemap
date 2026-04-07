import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../lib/src/application/npc_runtime_presence.dart';
import '../lib/src/application/step_studio_completion_runtime.dart';
import '../lib/src/application/step_studio_world_presence_runtime.dart';

const _doc = '''
{"schemaVersion":"step_studio_v1","globalStoryScenarioId":"global_story","steps":[
  {
    "id":"step_2",
    "name":"Step 2",
    "description":"Cas réel",
    "order":0,
    "activation":{"mode":"atGameStart","stepId":null,"outcomeId":null,"cutsceneId":null,"flagName":null},
    "completion":{"mode":"whenCutsceneEnds","cutsceneId":"premier_dialogue_avec_le_professeur_emma","outcomeId":null,"interactionId":null,"flagName":null},
    "worldChanges":[
      {"mapId":"Bourivka center","entityId":"emma","presenceRule":"hiddenAfterStepCompletion","note":""}
    ]
  }
]}''';

MapEntity _emma() => const MapEntity(
      id: 'emma',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 26, y: 12),
      size: GridSize(width: 1, height: 1),
      npc: MapEntityNpcData(),
    );

void main() {
  test(
    'intégration data flow: cutscene terminée -> step_2 complétée -> save/reload -> Emma absente',
    () {
      final scenario = ScenarioAsset(
        id: 'global_story',
        name: 'Global Story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        metadata: const <String, String>{
          kStepStudioDocumentMetadataKey: _doc,
        },
      );
      final manifest = ProjectManifest(
        name: 'test',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        scenarios: <ScenarioAsset>[scenario],
      );

      final index = buildStepCompletionCutsceneIndex(manifest.scenarios);
      final stepId = index.stepIdToCompleteWhenCutsceneEnds(
        'premier_dialogue_avec_le_professeur_emma',
      );
      expect(stepId, 'step_2');

      final initial = const GameState(saveId: 's0');
      final completed = initial.copyWith(
        progression: initial.progression.copyWith(
          completedStepIds: appendCompletedStepIdIfAbsent(
            initial.progression.completedStepIds,
            stepId!,
          ),
          completedCutsceneIds: appendCompletedCutsceneIdIfAbsent(
            initial.progression.completedCutsceneIds,
            'premier_dialogue_avec_le_professeur_emma',
          ),
        ),
      );

      final reloaded = normalizeLoadedGameState(
        GameState.fromJson(completed.toJson()),
      );
      expect(reloaded.progression.completedStepIds, contains('step_2'));

      final rules = buildStepStudioWorldPresenceRuleList(manifest.scenarios);
      final present = isNpcRuntimePresentOnMap(
        gameState: reloaded,
        manifest: manifest,
        stepStudioWorldRules: rules,
        mapId: 'Bourivka center',
        entity: _emma(),
      );
      expect(present, isFalse);
    },
  );
}
