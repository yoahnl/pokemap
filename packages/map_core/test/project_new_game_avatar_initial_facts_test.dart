import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ProjectManifest avatarInitialFactsProject(
  Map<String, Object?> mapping, {
  String? existingPartyFactId,
}) => ProjectManifest(
  name: 'Avatar initial facts',
  maps: const [
    ProjectMapEntry(id: 'home', name: 'Home', relativePath: 'maps/home.json'),
  ],
  tilesets: const [
    ProjectTilesetEntry(
      id: 'actors',
      name: 'Actors',
      relativePath: 'assets/actors.png',
    ),
  ],
  characters: const [
    ProjectCharacterEntry(id: 'avatar-a', name: 'A', tilesetId: 'actors'),
    ProjectCharacterEntry(id: 'avatar-b', name: 'B', tilesetId: 'actors'),
  ],
  facts: [
    NarrativeFactDefinition(
      id: 'identity',
      label: 'Source identity',
      initialValue: NarrativeValue.integer(-1),
    ),
    NarrativeFactDefinition(
      id: 'paired',
      label: 'Correlated value',
      initialValue: NarrativeValue.integer(-1),
    ),
    NarrativeFactDefinition(id: 'party', label: 'Existing party'),
  ],
  newGame: ProjectNewGameConfig.fromJson({
    'enabled': true,
    'startMapId': 'home',
    'playerAvatarCharacterIds': ['avatar-a', 'avatar-b'],
    'factSchemaVersion': 2,
    'initialFactValues': {'identity': NarrativeValue.integer(-1).toJson()},
    'initialFactValuesByAvatarCharacterId': mapping,
    'existingPartyFactId': ?existingPartyFactId,
  }),
);

void main() {
  test('empty avatar mapping is omitted from unrelated configurations', () {
    expect(
      const ProjectNewGameConfig().toJson(),
      isNot(contains('initialFactValuesByAvatarCharacterId')),
    );
  });
  final mapping = <String, Object?>{
    'avatar-a': {'identity': NarrativeValue.integer(0).toJson()},
    'avatar-b': {'identity': NarrativeValue.integer(1).toJson()},
  };
  test(
    'avatar-scoped typed facts survive JSON and participate in equality',
    () {
      final config = avatarInitialFactsProject(mapping).newGame;
      expect(config.toJson()['initialFactValuesByAvatarCharacterId'], mapping);
      final decoded = ProjectNewGameConfig.fromJson(config.toJson());
      expect(decoded, config);
      expect(decoded.hashCode, config.hashCode);
      expect(config, isNot(avatarInitialFactsProject({}).newGame));
      expect(
        () => ProjectValidator.validate(avatarInitialFactsProject(mapping)),
        returnsNormally,
      );
    },
  );
  test(
    'symbolic initial states preserve avatar correlation without impossible pairs',
    () {
      final project = avatarInitialFactsProject({
        for (final (avatar, value) in [('avatar-a', 0), ('avatar-b', 1)])
          avatar: {
            'identity': NarrativeValue.integer(value).toJson(),
            'paired': NarrativeValue.integer(value).toJson(),
          },
      });
      final report = solveNarrativeSymbolicReachability(
        project,
        maps: const [],
      );
      final rows = report.evidenceStates
          .map(
            (state) =>
                '${state.factValues['identity']!.intValue}:${state.factValues['paired']!.intValue}',
          )
          .toSet();
      expect(rows, {'0:0', '1:1'});
      expect(rows, isNot(contains('0:1')));
      expect(rows, isNot(contains('1:0')));
    },
  );
  test('avatar seeds respect the existing symbolic exploration budget', () {
    final report = solveNarrativeSymbolicReachability(
      avatarInitialFactsProject(mapping),
      maps: const [],
      explorationBudget: 1,
    );
    expect(report.verdict, NarrativeSymbolicVerdict.indeterminate);
    expect(
      report.issues.map((issue) => issue.code),
      contains(NarrativeSymbolicIssueCode.budgetExceeded),
    );
  });
  test('indexes each avatar Fact reference with its precise owner path', () {
    final index = buildNarrativeDependencyIndex(
      project: avatarInitialFactsProject(mapping),
    );
    final paths = index
        .usagesFor(
          const NarrativeDependencyKey(
            NarrativeDependencyTargetKind.fact,
            'identity',
          ),
        )
        .map((usage) => usage.path);
    expect(
      paths,
      containsAll([
        'newGame.initialFactValuesByAvatarCharacterId[avatar-a][identity]',
        'newGame.initialFactValuesByAvatarCharacterId[avatar-b][identity]',
      ]),
    );
  });
  test('world rule diagnostics admit a value initialized by one avatar', () {
    final project = avatarInitialFactsProject(mapping).copyWith(
      worldRules: [
        WorldRuleDefinition(
          id: 'identity-rule',
          label: 'Identity',
          source: WorldRuleSource.factValue(
            factId: 'identity',
            operator: NarrativeFactOperator.equals,
            expectedValue: NarrativeValue.integer(1),
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'home',
            entityId: 'npc',
          ),
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.entityVisible,
          ),
        ),
      ],
    );
    final report = diagnoseWorldRules(
      project,
      maps: [
        MapData(
          id: 'home',
          name: 'Home',
          size: const GridSize(width: 3, height: 3),
          entities: const [
            MapEntity(
              id: 'npc',
              kind: MapEntityKind.npc,
              pos: GridPos(x: 1, y: 1),
              npc: MapEntityNpcData(characterId: 'avatar-a'),
            ),
          ],
        ),
      ],
    );
    expect(
      report.byCode(WorldRuleDiagnosticCode.worldRuleSourceNeverProduced),
      isEmpty,
    );
  });
  test(
    'replacing a pre-session scene preserves avatar initialization rows',
    () {
      SceneAsset scene(String id) => SceneAsset(
        id: id,
        name: id,
        executionProfile: SceneExecutionProfile.preSession,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start-end',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      );
      final original = avatarInitialFactsProject(mapping);
      final config = ProjectNewGameConfig.fromJson({
        ...original.newGame.toJson(),
        'preSessionSceneId': 'old',
      });
      final project = original.copyWith(
        newGame: config,
        scenes: [scene('old'), scene('new')],
      );
      final result = deleteSceneFromProject(
        project,
        sceneId: 'old',
        replacementSceneId: 'new',
      );
      expect(result.disposition, SceneLibraryMutationDisposition.applied);
      expect(
        result.after.newGame.initialFactValuesByAvatarCharacterId,
        config.initialFactValuesByAvatarCharacterId,
      );
      expect(result.after.newGame.preSessionSceneId, 'new');
    },
  );
  for (final (name, invalid) in <(String, Map<String, Object?>)>[
    (
      'undeclared avatar',
      {
        'missing-avatar': {'identity': NarrativeValue.integer(0).toJson()},
      },
    ),
    (
      'undeclared fact',
      {
        'avatar-a': {'missing-fact': NarrativeValue.integer(0).toJson()},
      },
    ),
    (
      'wrong typed value',
      {
        'avatar-a': {'identity': const NarrativeValue.boolean(true).toJson()},
      },
    ),
    (
      'derived party conflict',
      {
        'avatar-a': {'party': const NarrativeValue.boolean(true).toJson()},
      },
    ),
  ]) {
    test('rejects $name before a new game starts', () {
      expect(
        () => ProjectValidator.validate(
          avatarInitialFactsProject(
            invalid,
            existingPartyFactId: name == 'derived party conflict'
                ? 'party'
                : null,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  }
  for (final invalid in [
    <Object?>[],
    {'avatar-a': 0},
    {
      'avatar-a': {'identity': double.nan},
    },
  ]) {
    test('rejects malformed mapping $invalid', () {
      expect(
        () => ProjectNewGameConfig.fromJson({
          'initialFactValuesByAvatarCharacterId': invalid,
        }),
        throwsFormatException,
      );
    });
  }
}
