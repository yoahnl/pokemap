import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('L15 persistent player avatar', () {
    test('round-trips the typed consequence without extra state', () {
      final json = <String, dynamic>{
        'kind': 'setPlayerAvatar',
        'characterId': 'costume',
        'label': 'Change outfit',
        'notes': 'Persistent selection',
      };
      final consequence = SceneConsequence.fromJson(json);

      expect(consequence.kind.name, 'setPlayerAvatar');
      expect(jsonDecode(jsonEncode(consequence.toJson())), json);
      expect(SceneConsequence.fromJson(consequence.toJson()), consequence);
    });

    test('publishes a persistent guided avatar command', () {
      final command = NarrativeCommandCatalog.canonical().commands
          .where((command) => command.id == 'setPlayerAvatar')
          .single;

      expect(command.isPublishable, isTrue);
      expect(command.isPersistent, isTrue);
      expect(command.backend, NarrativeCommandBackend.sceneConsequence);
      expect(command.parameters.single.id, 'characterId');
      expect(command.parameters.single.kind.name, 'character');
      expect(SpatialGameplayCapabilities.commandIds, contains(command.id));
    });

    for (final invalid in <Map<String, dynamic>>[
      {},
      {'characterId': null},
      {'characterId': 1},
      {'characterId': ''},
      {'characterId': '  '},
      {'characterId': 'costume', 'temporary': true},
      {'characterId': 'costume', 'label': 1},
      {'characterId': 'costume', 'notes': false},
    ]) {
      test('rejects malformed avatar JSON $invalid', () {
        expect(
          () => SceneConsequence.fromJson({
            'kind': 'setPlayerAvatar',
            ...invalid,
          }),
          throwsFormatException,
        );
      });
    }

    test('normalizes selection and builds the guided payload', () {
      final payload =
          buildScenePayloadForNarrativeCommand(
                commandId: NarrativeCommandIds.setPlayerAvatar,
                parameters: {'characterId': ' costume '},
              )
              as SceneActionPayload;

      expect(
        payload.consequence,
        SceneConsequence.setPlayerAvatar(characterId: 'costume'),
      );
      expect(
        () => SceneConsequence.setPlayerAvatar(characterId: ' '),
        throwsArgumentError,
      );
      expect(
        () => buildScenePayloadForNarrativeCommand(
          commandId: NarrativeCommandIds.setPlayerAvatar,
          parameters: {},
        ),
        throwsArgumentError,
      );
    });

    test('resolves arbitrary positive visual dimensions', () {
      final character = _character(
        'costume',
      ).copyWith(frameWidth: 3, frameHeight: 5);
      expect(
        resolveScenePlayerAvatarCharacter(
          _project(characters: [character]),
          'costume',
        ),
        same(character),
      );
    });

    test('accepts dedicated animation sources without a grid tileset', () {
      final character = _character('costume', sourceAssetId: 'asset-avatar');
      expect(
        resolveScenePlayerAvatarCharacter(
          _project(characters: [character], tilesets: []),
          'costume',
        ),
        same(character),
      );
    });

    final invalidCharacters = <String, List<ProjectCharacterEntry>>{
      'missing': [],
      'ambiguous': [_character('costume'), _character('costume')],
      'invalid dimensions': [_character('costume').copyWith(frameWidth: 0)],
      'missing directions': [_character('costume').copyWith(animations: [])],
      'duplicate direction': [
        _character('costume').copyWith(
          animations: [
            ..._character('costume').animations,
            _character('costume').animations.first,
          ],
        ),
      ],
      'empty frames': [
        _character('costume').copyWith(
          animations: [
            for (final animation in _character('costume').animations)
              animation.copyWith(frames: []),
          ],
        ),
      ],
      'invalid frame duration': [
        _character('costume').copyWith(
          animations: [
            for (final animation in _character('costume').animations)
              animation.copyWith(
                frames: [animation.frames.single.copyWith(durationMs: 0)],
              ),
          ],
        ),
      ],
      'invalid source': [
        _character('costume').copyWith(
          animations: [
            for (final animation in _character('costume').animations)
              animation.copyWith(
                frames: [
                  const CharacterAnimationFrame(
                    source: TilesetSourceRect(x: -1, y: 0, width: 1, height: 1),
                  ),
                ],
              ),
          ],
        ),
      ],
    };
    for (final entry in invalidCharacters.entries) {
      test('rejects ${entry.key} before execution', () {
        final project = _project(characters: entry.value);
        expect(
          () => resolveScenePlayerAvatarCharacter(project, 'costume'),
          throwsFormatException,
        );
        expect(
          diagnoseSceneAgainstProject(
            _scene(['costume']),
            project,
          ).byCode(SceneDiagnosticCode.consequenceInvalidPlayerAvatar),
          hasLength(1),
        );
      });
    }

    test('rejects absent or ambiguous fallback tilesets', () {
      final project = _project();
      for (final tilesets in <List<ProjectTilesetEntry>>[
        [],
        [...project.tilesets, ...project.tilesets],
      ]) {
        expect(
          () => resolveScenePlayerAvatarCharacter(
            project.copyWith(tilesets: tilesets),
            'costume',
          ),
          throwsFormatException,
        );
      }
    });

    test('compiles, previews change and restores by explicit selection', () {
      final scene = _scene(['costume', 'original']);
      final project = _project(scenes: [scene]);
      final diagnostics = diagnoseSceneAgainstProject(scene, project);
      expect(
        diagnostics.hasErrors,
        isFalse,
        reason: diagnostics.diagnostics
            .map((issue) => issue.message)
            .join('\n'),
      );
      final built = buildSceneRuntimePlan(scene);
      expect(built.plan, isNotNull);
      final preview = previewSceneRuntimePath(
        built.plan!,
        input: SceneDryRunInputState(
          consequenceState: SceneDryRunConsequenceState(
            playerAvatarCharacterId: 'original',
            money: 42,
            itemQuantityById: {'potion': 2},
          ),
        ),
      );

      expect(preview.status, SceneDryRunPreviewStatus.completed);
      expect(preview.consequenceState.playerAvatarCharacterId, 'original');
      expect(preview.consequenceState.money, 42);
      expect(preview.consequenceState.itemQuantityById, {'potion': 2});
      expect(preview.consequenceChanges.map((change) => change.afterSummary), [
        'avatar=costume',
        'avatar=original',
      ]);
      expect(preview.consequenceChanges.first.beforeSummary, 'avatar=original');
      expect(
        buildSceneRuntimePlan(
          SceneAsset.fromJson({
            ...scene.toJson(),
            'executionProfile': 'preSession',
          }),
        ).plan,
        isNull,
      );
    });

    test('indexes persistent avatar references for deletion safeguards', () {
      final scene = _scene(['costume']);
      final index = buildCharacterStudioReferenceIndex(
        _project(scenes: [scene]),
      );
      final reference = index
          .referencesTo(CharacterStudioReferenceTargetKind.character, 'costume')
          .single;

      expect(
        reference.sourceKind,
        CharacterStudioReferenceSourceKind.scenePlayerAvatar,
      );
      expect(reference.sourceId, 'scene-avatar:avatar_0');
      expect(
        reference.path,
        r'$.scenes[0].graph.nodes[1].payload.consequence.characterId',
      );
    });

  });
}

ProjectCharacterEntry _character(String id, {String? sourceAssetId}) =>
    ProjectCharacterEntry(
      id: id,
      name: id,
      tilesetId: 'sprites',
      animations: [
        for (final direction in EntityFacing.values)
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: direction,
            sourceAssetId: sourceAssetId,
            frames: [
              const CharacterAnimationFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 1),
              ),
            ],
          ),
      ],
    );

ProjectManifest _project({
  List<ProjectCharacterEntry>? characters,
  List<ProjectTilesetEntry>? tilesets,
  List<SceneAsset> scenes = const [],
}) => ProjectManifest(
  name: 'Avatar contract',
  maps: [],
  tilesets:
      tilesets ??
      [
        const ProjectTilesetEntry(
          id: 'sprites',
          name: 'Sprites',
          relativePath: 'assets/sprites.png',
        ),
      ],
  characters: characters ?? [_character('original'), _character('costume')],
  scenes: scenes,
);

SceneAsset _scene(List<String> characterIds) {
  final nodes = [
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    for (var index = 0; index < characterIds.length; index++)
      SceneNode(
        id: 'avatar_$index',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setPlayerAvatar(characterId: characterIds[index]),
        ),
      ),
    SceneNode(id: 'end', kind: SceneNodeKind.end),
  ];
  return SceneAsset(
    id: 'scene-avatar',
    name: 'Avatar scene',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var index = 0; index < nodes.length - 1; index++)
          SceneEdge(
            id: 'edge_$index',
            fromNodeId: nodes[index].id,
            fromPortId: 'completed',
            toNodeId: nodes[index + 1].id,
            kind: index == 0
                ? SceneEdgeKind.defaultFlow
                : SceneEdgeKind.actionCompleted,
          ),
      ],
    ),
    layout: SceneGraphLayout(
      nodeLayouts: [
        for (var index = 0; index < nodes.length; index++)
          SceneNodeLayout(nodeId: nodes[index].id, x: index * 200, y: 0),
      ],
    ),
  );
}
