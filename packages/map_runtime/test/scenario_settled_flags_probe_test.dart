import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/dialogue_runtime_models.dart';

const _mapId = 'probe_map';
const _entityId = 'probe_npc';
const _dialogueId = 'probe_dialogue';
const _before = 'probe_before_dialogue';
const _after = 'probe_after_dialogue';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('both Scenario halves survive a dialogue suspension', () async {
    final game = _Probe(
      bundle: _bundle(),
      projectFilePath: '/tmp/probe/project.json',
      dialogueSessionLoader: (_) async => DialogueSession.start(
        <YarnNode>[
          YarnNode(title: 'Start', steps: <YarnStep>[YarnStepLine('Probe.')]),
        ],
        'Start',
      )!,
    );
    game.onGameResize(Vector2(640, 480));
    await game.onLoad().timeout(const Duration(seconds: 5));
    await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);

    expect(
      game.handleRuntimeInputEvent(
        const RuntimeInputEvent.press(RuntimeInputControl.primary),
      ),
      isTrue,
    );
    await _pumpUntil(game, () => game.debugFlowPhaseName == 'dialogue');
    game.handleRuntimeInputEvent(
      const RuntimeInputEvent.press(RuntimeInputControl.primary),
    );
    await _pumpUntil(game, () => game.debugFlowPhaseName == 'overworld');
    for (var i = 0; i < 40; i++) {
      game.update(0.016);
      await Future<void>.delayed(Duration.zero);
    }

    expect(
      game.gameStateSnapshot.storyFlags.activeFlags,
      containsAll(<String>[_before, _after]),
    );
  });
}

RuntimeMapBundle _bundle() {
  final manifest = ProjectManifest(
    name: 'probe',
    settings: const ProjectSettings(tileWidth: 16, tileHeight: 16),
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(id: _mapId, name: _mapId, relativePath: 'maps/m.json'),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: _dialogueId,
        name: _dialogueId,
        relativePath: 'dialogues/d.yarn',
      ),
    ],
    scenarios: <ScenarioAsset>[
      ScenarioAsset(
        id: 'probe_scenario',
        name: 'probe',
        scope: ScenarioScope.localEventFlow,
        entryNodeId: 'source',
        nodes: const <ScenarioNode>[
          ScenarioNode(
            id: 'source',
            type: ScenarioNodeType.reference,
            payload: ScenarioNodePayload(
              actionKind: kScenarioSourceEntityInteract,
            ),
            binding: ScenarioNodeBinding(mapId: _mapId, entityId: _entityId),
          ),
          ScenarioNode(
            id: 'set_before',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(flagName: _before),
          ),
          ScenarioNode(
            id: 'dialogue',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(
              actionKind: kScenarioActionOpenDialogue,
            ),
            binding: ScenarioNodeBinding(dialogueId: _dialogueId),
          ),
          ScenarioNode(
            id: 'set_after',
            type: ScenarioNodeType.action,
            payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
            binding: ScenarioNodeBinding(flagName: _after),
          ),
          ScenarioNode(id: 'end', type: ScenarioNodeType.end),
        ],
        edges: const <ScenarioEdge>[
          ScenarioEdge(
            id: 'e1',
            fromNodeId: 'source',
            toNodeId: 'set_before',
          ),
          ScenarioEdge(
            id: 'e2',
            fromNodeId: 'set_before',
            toNodeId: 'dialogue',
          ),
          ScenarioEdge(id: 'e3', fromNodeId: 'dialogue', toNodeId: 'set_after'),
          ScenarioEdge(id: 'e4', fromNodeId: 'set_after', toNodeId: 'end'),
        ],
      ),
    ],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const <NarrativeEventRecord>[],
      legacyClaims: const <LegacySourceClaim>[],
    ),
  );
  return RuntimeMapBundle(
    manifest: manifest,
    map: MapData(
      id: _mapId,
      name: _mapId,
      size: const GridSize(width: 4, height: 3),
      layers: const <MapLayer>[MapLayer.object(id: 'objects', name: 'Objects')],
      entities: const <MapEntity>[
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 1),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        MapEntity(
          id: _entityId,
          name: 'Probe npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 1, y: 1),
          blocksMovement: true,
        ),
      ],
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/probe',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 360,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('probe timed out');
}

final class _Probe extends PlayableMapGame {
  _Probe({
    required super.bundle,
    required super.projectFilePath,
    super.dialogueSessionLoader,
  });

  bool _loaded = false;

  @override
  bool get isLoaded => _loaded;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _loaded = true;
  }
}
