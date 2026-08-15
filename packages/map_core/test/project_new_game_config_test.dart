import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Project new game config', () {
    test('legacy manifests default to a disabled config', () {
      final manifest = ProjectManifest.fromJson({
        'name': 'legacy',
        'version': 'v6',
        'maps': <Object?>[],
        'tilesets': <Object?>[],
      });

      expect(manifest.newGame.enabled, isFalse);
      expect(manifest.newGame.initialParty, isEmpty);
      expect(manifest.newGame.starterOptions, isEmpty);
      expect(manifest.toJson()['newGame'], isA<Map<String, dynamic>>());
    });

    test('round-trips spawn, inventory, facts, party and starter options', () {
      const config = ProjectNewGameConfig(
        enabled: true,
        startMapId: 'map_start',
        startSpawnId: 'spawn_home',
        playerName: 'Maël',
        playerAvatarCharacterIds: ['hero_a', 'hero_b'],
        playerPronounSet: PlayerPronounSet.feminine,
        startingMoney: 500,
        initialBag: [
          BagEntry(itemId: 'potion', quantity: 2),
        ],
        initialParty: [
          PlayerPokemon(
            speciesId: 'eevee',
            natureId: 'hardy',
            abilityId: 'run-away',
            level: 5,
            currentHp: 20,
          ),
        ],
        initialFacts: {'fact_intro_active': true},
        existingPartyFactId: 'fact_existing_party',
        preSessionSceneId: 'scene_starter_choice',
        starterOptions: [
          ProjectStarterOption(
            id: 'starter_bulbasaur',
            label: 'Bulbizarre',
            pokemon: PlayerPokemon(
              speciesId: 'bulbasaur',
              natureId: 'hardy',
              abilityId: 'overgrow',
              level: 5,
              currentHp: 20,
            ),
          ),
        ],
      );
      final manifest = _manifest(config);

      final decoded = ProjectManifest.fromJson(manifest.toJson());

      expect(decoded.newGame, config);
      expect(decoded.newGame.starterOptions.single.id, 'starter_bulbasaur');
      expect(
        decoded.newGame.playerAvatarCharacterIds,
        const ['hero_a', 'hero_b'],
      );
      expect(
        decoded.newGame.playerPronounSet,
        PlayerPronounSet.feminine,
      );
    });

    test('round-trips versioned typed initial Fact values', () {
      final config = ProjectNewGameConfig(
        enabled: true,
        startMapId: 'map_start',
        initialFactValues: {
          'fact_intro_active': const NarrativeValue.boolean(false),
          'fact_tide': NarrativeValue.integer(3),
          'fact_harbor': const NarrativeValue.string('Brisants'),
        },
      );
      final manifest = _manifest(
        config,
        additionalFacts: [
          NarrativeFactDefinition(
            id: 'fact_tide',
            label: 'Tide',
            initialValue: NarrativeValue.integer(0),
          ),
          NarrativeFactDefinition(
            id: 'fact_harbor',
            label: 'Harbor',
            initialValue: const NarrativeValue.string(''),
          ),
        ],
      );

      final json = manifest.toJson();
      final decoded = ProjectManifest.fromJson(json);

      expect((json['newGame'] as Map)['factSchemaVersion'], 2);
      expect(decoded.newGame, config);
      expect(
        decoded.newGame.resolvedInitialFactValues['fact_tide'],
        NarrativeValue.integer(3),
      );
      expect(() => ProjectValidator.validate(decoded), returnsNormally);
    });

    test('validator constrains existingPartyFactId to a bool Fact', () {
      final manifest = _manifest(
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          existingPartyFactId: 'fact_existing_party',
        ),
        existingPartyFact: NarrativeFactDefinition(
          id: 'fact_existing_party',
          label: 'Existing party count',
          initialValue: NarrativeValue.integer(0),
        ),
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validator rejects references and structurally invalid values', () {
      final invalidConfigs = <ProjectNewGameConfig>[
        const ProjectNewGameConfig(enabled: true),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'missing_map',
        ),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          startingMoney: -1,
        ),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          initialBag: [
            BagEntry(itemId: 'potion', quantity: 0),
          ],
        ),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          existingPartyFactId: 'missing_fact',
        ),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          preSessionSceneId: 'missing_scene',
        ),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          playerAvatarCharacterIds: ['missing_character'],
        ),
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          playerAvatarCharacterIds: ['hero_a', 'hero_a'],
        ),
      ];

      for (final config in invalidConfigs) {
        expect(
          () => ProjectValidator.validate(_manifest(config)),
          throwsA(isA<ValidationException>()),
          reason: config.toString(),
        );
      }
    });

    test('validator accepts both empty-party and existing-party starts', () {
      for (final initialParty in <List<PlayerPokemon>>[
        const [],
        const [
          PlayerPokemon(
            speciesId: 'eevee',
            natureId: 'hardy',
            abilityId: 'run-away',
            level: 5,
            currentHp: 20,
          ),
        ],
      ]) {
        final manifest = _manifest(
          ProjectNewGameConfig(
            enabled: true,
            startMapId: 'map_start',
            existingPartyFactId: 'fact_existing_party',
            initialParty: initialParty,
            preSessionSceneId: 'scene_starter_choice',
            starterOptions: const [
              ProjectStarterOption(
                id: 'starter_bulbasaur',
                label: 'Bulbizarre',
                pokemon: PlayerPokemon(
                  speciesId: 'bulbasaur',
                  natureId: 'hardy',
                  abilityId: 'overgrow',
                  level: 5,
                  currentHp: 20,
                ),
              ),
            ],
          ),
        );

        expect(() => ProjectValidator.validate(manifest), returnsNormally);
      }
    });

    test('rejects the legacy entrypoint field instead of dual-reading it', () {
      expect(
        () => ProjectNewGameConfig.fromJson(const <String, dynamic>{
          'starterSelectionSceneId': 'scene_starter_choice',
        }),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('new_game_legacy_entrypoint_unsupported'),
              contains('starterSelectionSceneId'),
            ),
          ),
        ),
      );
    });

    test('requires project v7 when a pre-session entrypoint is present', () {
      final json = _manifest(
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          preSessionSceneId: 'scene_starter_choice',
        ),
      ).toJson()
        ..['version'] = 'v6';

      expect(
        () => ProjectManifest.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('cinematic_v2_project_v7_required'),
              contains(r'$.newGame.preSessionSceneId'),
            ),
          ),
        ),
      );
    });

    test('requires the entrypoint to reference a pre-session Scene', () {
      final manifest = _manifest(
        const ProjectNewGameConfig(
          enabled: true,
          startMapId: 'map_start',
          preSessionSceneId: 'scene_starter_choice',
        ),
        sceneProfile: SceneExecutionProfile.world,
      );

      expect(
        () => ProjectValidator.validate(manifest),
        throwsA(
          isA<ValidationException>()
              .having(
                (error) => error.code,
                'code',
                'new_game_pre_session_profile_required',
              )
              .having(
                (error) => error.message,
                'message',
                contains('scene_starter_choice'),
              ),
        ),
      );
    });

    test('keeps a v7 project without an entrypoint valid', () {
      final manifest = _manifest(
        const ProjectNewGameConfig(enabled: true, startMapId: 'map_start'),
      );

      expect(manifest.newGame.preSessionSceneId, isNull);
      expect(() => ProjectValidator.validate(manifest), returnsNormally);
      expect(ProjectManifest.fromJson(manifest.toJson()), manifest);
    });
  });
}

ProjectManifest _manifest(
  ProjectNewGameConfig newGame, {
  List<NarrativeFactDefinition> additionalFacts = const [],
  NarrativeFactDefinition? existingPartyFact,
  SceneExecutionProfile sceneProfile = SceneExecutionProfile.preSession,
}) {
  return ProjectManifest(
    name: 'new game config test',
    version: ProjectVersion.v7,
    maps: const [
      ProjectMapEntry(
        id: 'map_start',
        name: 'Start',
        relativePath: 'maps/map_start.json',
      ),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'characters',
        name: 'Personnages',
        relativePath: 'assets/characters.png',
      ),
    ],
    characters: const [
      ProjectCharacterEntry(
        id: 'hero_a',
        name: 'Héroïne A',
        tilesetId: 'characters',
      ),
      ProjectCharacterEntry(
        id: 'hero_b',
        name: 'Héros B',
        tilesetId: 'characters',
      ),
    ],
    facts: [
      NarrativeFactDefinition(
        id: 'fact_intro_active',
        label: 'Introduction active',
      ),
      existingPartyFact ??
          NarrativeFactDefinition(
            id: 'fact_existing_party',
            label: 'Équipe existante',
          ),
      ...additionalFacts,
    ],
    scenes: [
      SceneAsset(
        id: 'scene_starter_choice',
        name: 'Starter choice',
        executionProfile: sceneProfile,
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'edge_start_end',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.defaultFlow,
            ),
          ],
        ),
      ),
    ],
    newGame: newGame,
  );
}
