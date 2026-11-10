import 'package:avelune_studio/features/pokemon/domain/pokemon_workspace_models.dart';
import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_pokemon_gift_moves_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('avatar reopening and repair preserve the exact metadata and original choice', () {
    final project = _avatarProject();
    final original = SceneActionPayload.consequence(
      SceneConsequence.setPlayerAvatar(
        characterId: 'costume',
        label: 'Costume de scène',
        notes: 'Restaurer après la cérémonie',
      ),
      actionKind: 'custom-label',
      parameters: const {'annotation': 'keep'},
    );
    final draft = _draft(project, current: original);
    expect(draft.options(NarrativeCommandParameterKind.character), {
      'hero': 'Tenue de voyage',
      'costume': 'Tenue de soirée',
    });
    expect(draft.valid, isTrue);
    expect(draft.buildPayload(), original);
    draft.changeParameter('characterId', 'hero');
    final result = draft.buildPayload() as SceneActionPayload;
    expect(result.parameters, original.parameters);
    expect(result.actionKind, original.actionKind);
    expect(
      result.consequence,
      SceneConsequence.setPlayerAvatar(
        characterId: 'hero',
        label: 'Costume de scène',
        notes: 'Restaurer après la cérémonie',
      ),
    );
    expect(draft.current, same(original));
    expect(
      (original.consequence as SceneSetPlayerAvatarConsequence).characterId,
      'costume',
    );
  });

  test(
    'new avatar selection excludes ambiguous and invalid animation definitions',
    () {
      final project = _avatarProject();
      final draft = _draft(
        project.copyWith(
          characters: [
            ...project.characters,
            _character('duplicate', 'A'),
            _character('duplicate', 'B'),
            const ProjectCharacterEntry(
              id: 'missing_walk',
              name: 'Sans marche',
              tilesetId: 'unused',
            ),
            _character(
              'invalid_frame',
              'Cadre invalide',
            ).copyWith(frameWidth: 0),
          ],
        ),
      );
      draft.choose(NarrativeCommandIds.setPlayerAvatar);
      expect(draft.valid, isFalse);
      expect(draft.options(NarrativeCommandParameterKind.character), {
        'hero': 'Tenue de voyage',
        'costume': 'Tenue de soirée',
      });
      draft.changeParameter('characterId', 'costume');
      expect(draft.valid, isTrue);
      expect(
        (draft.buildPayload() as SceneActionPayload).consequence,
        SceneConsequence.setPlayerAvatar(characterId: 'costume'),
      );
    },
  );

  test('missing avatar remains selected across catalogue removal restoration and explicit repair', () {
    final project = _avatarProject();
    final original = SceneActionPayload.consequence(
      SceneConsequence.setPlayerAvatar(characterId: 'costume'),
    );
    final draft = _draft(project, current: original);
    _configure(draft, project.copyWith(characters: [project.characters.first]));
    expect(draft.values['characterId'], 'costume');
    expect(draft.valid, isFalse);
    expect(draft.current, same(original));
    _configure(draft, project);
    expect(draft.valid, isTrue);
    expect(draft.buildPayload(), original);
    _configure(draft, project.copyWith(characters: [project.characters.first]));
    draft.changeParameter('characterId', 'hero');
    expect(draft.valid, isTrue);
    expect(
      (draft.buildPayload() as SceneActionPayload).consequence,
      SceneConsequence.setPlayerAvatar(characterId: 'hero'),
    );
    expect(draft.current, same(original));
  });

  test('an avatar already missing at opening remains unchanged until repaired', () {
    final original = SceneActionPayload.consequence(
      SceneConsequence.setPlayerAvatar(characterId: 'missing'),
    );
    final draft = _draft(_avatarProject(), current: original);
    expect(draft.values['characterId'], 'missing');
    expect(draft.options(NarrativeCommandParameterKind.character), isNot(contains('missing')));
    expect(draft.valid, isFalse);
    expect(draft.current, same(original));
    draft.changeParameter('characterId', 'hero');
    expect(draft.valid, isTrue);
    expect(
      (draft.buildPayload() as SceneActionPayload).consequence,
      SceneConsequence.setPlayerAvatar(characterId: 'hero'),
    );
    expect(
      (original.consequence as SceneSetPlayerAvatarConsequence).characterId,
      'missing',
    );
  });

  test('route wait selects an exact map and rejects missing duplicate or 3D references', () {
    final project = _project();
    final original = SceneActionPayload.interactive(
      SceneInteractiveCommand.fromJson({
        'kind': 'waitForActorRoutes',
        'mapId': 'room',
      }),
      actionKind: 'author-label',
      parameters: const {'annotation': 'keep'},
    );
    final draft = _draft(project, current: original);
    expect(draft.valid, isTrue);
    draft.changeParameter('mapId', 'forest');
    final result = draft.buildPayload() as SceneActionPayload;
    expect(result.interactiveCommand!.toJson(), {
      'kind': 'waitForActorRoutes',
      'mapId': 'forest',
    });
    expect(result.actionKind, original.actionKind);
    expect(result.parameters, original.parameters);
    expect(original.interactiveCommand!.toJson()['mapId'], 'room');
    for (final invalid in [
      project.copyWith(maps: []),
      project.copyWith(maps: [...project.maps, project.maps.first]),
    ]) {
      final unavailable = _draft(invalid, current: original);
      expect(unavailable.values['mapId'], 'room');
      expect(unavailable.valid, isFalse);
      expect(unavailable.current, same(original));
    }
    final spatial = _draft(
      project.copyWith(
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      ),
      current: original,
    );
    expect(
      spatial.commands.map((entry) => entry.id),
      isNot(contains(NarrativeCommandIds.waitForActorRoutes)),
    );
    expect(spatial.valid, isFalse);
    expect(spatial.current, same(original));
  });

  test(
    'local memory resolves the native owner and blocks a removed entity',
    () async {
      final original = SceneActionPayload.consequence(
        SceneConsequence.setMapEventInstanceBoolean(
          mapId: 'room',
          eventId: 'owner',
          key: 'opened',
          value: true,
        ),
      );
      var exists = true;
      final draft = _draft(
        _project(),
        current: original,
        loadMap: (id) async => MapData(
          id: id,
          name: 'Room',
          size: const GridSize(width: 5, height: 5),
          entities: [
            if (exists)
              const MapEntity(
                id: 'owner',
                name: 'Guide',
                kind: MapEntityKind.custom,
                pos: GridPos(x: 1, y: 1),
              ),
          ],
        ),
      );
      await _settle();
      expect(draft.options(NarrativeCommandParameterKind.mapEntityReference), {
        'owner': 'Guide',
      });
      expect(draft.valid, isTrue);
      expect(draft.buildPayload(), original);
      exists = false;
      draft.loadReferenceMap();
      await _settle();
      expect(draft.valid, isFalse);
      expect(draft.values['eventId'], 'owner');
      expect(draft.current, same(original));
    },
  );

  for (final existing in [false, true]) {
    test(
      'periodic reward keeps stable identity typed quantity and a single catalogue load existing=$existing',
      () async {
        var loads = 0;
        final original = SceneActionPayload.interactive(
          SceneInteractiveCommand.claimPeriodicReward(
            definition: PeriodicItemRewardDefinition(
              rewardId: 'saved-reward',
              label: 'Fruit',
              itemId: 'fruit',
              quantity: 2,
            ),
          ),
        );
        final draft = _draft(
          _project(),
          current: existing ? original : null,
          loadItems: () async {
            loads++;
            return {'fruit': 'Noigrume rouge', 'ball': 'Poké Ball'};
          },
        );
        if (!existing) draft.choose(NarrativeCommandIds.claimPeriodicReward);
        await _settle();
        expect(draft.options(NarrativeCommandParameterKind.item), {
          'fruit': 'Noigrume rouge',
          'ball': 'Poké Ball',
        });
        draft.changeParameter('label', 'Récolte du jardin');
        draft.changeParameter('itemId', 'ball');
        draft.changeParameter('quantity', '3');
        expect(draft.valid, isTrue);
        final first =
            ((draft.buildPayload() as SceneActionPayload).interactiveCommand
                    as SceneClaimPeriodicRewardInteractiveCommand)
                .definition;
        expect(
          first.rewardId,
          existing ? 'saved-reward' : startsWith('reward-'),
        );
        expect(first.label, 'Récolte du jardin');
        expect(first.itemId, 'ball');
        expect(first.quantity, 3);
        draft.changeParameter('quantity', '0');
        expect(draft.valid, isFalse);
        draft.changeParameter('quantity', '4');
        expect(draft.valid, isTrue);
        final second =
            ((draft.buildPayload() as SceneActionPayload).interactiveCommand
                    as SceneClaimPeriodicRewardInteractiveCommand)
                .definition;
        expect(second.rewardId, first.rewardId);
        expect(second.quantity, 4);
        expect(loads, 1);
        expect(draft.current, same(existing ? original : null));
      },
    );
  }

  test(
    'a missing reward item cannot replace its saved identity or quantity',
    () async {
      final original = SceneActionPayload.interactive(
        SceneInteractiveCommand.claimPeriodicReward(
          definition: PeriodicItemRewardDefinition(
            rewardId: 'saved-reward',
            label: 'Fruit',
            itemId: 'removed',
            quantity: 2,
          ),
        ),
      );
      final draft = _draft(
        _project(),
        current: original,
        loadItems: () async => {'fruit': 'Fruit'},
      );
      await _settle();
      expect(draft.values['rewardId'], 'saved-reward');
      expect(draft.values['itemId'], 'removed');
      expect(draft.valid, isFalse);
      expect(draft.current, same(original));
    },
  );

  test('fact edits and unsupported replacement retain opaque data until application', () {
    final project = _project().copyWith(
      facts: [
        NarrativeFactDefinition(id: 'departure', label: 'Départ autorisé'),
      ],
    );
    final original = SceneActionPayload.consequence(
      SceneConsequence.setFact(factId: 'departure', value: true),
      actionKind: 'author-label',
      parameters: const {'annotation': 'keep'},
    );
    final draft = _draft(project, current: original);
    draft.changeParameter('value', 'false');
    expect(draft.current, same(original));
    final result = draft.buildPayload() as SceneActionPayload;
    expect(
      result.consequence,
      SceneConsequence.setFact(factId: 'departure', value: false),
    );
    expect(result.parameters, original.parameters);
    expect(result.actionKind, original.actionKind);
    final missing = _draft(project.copyWith(facts: []), current: original);
    expect(missing.values['factId'], 'departure');
    expect(missing.valid, isFalse);
    final opaque = SceneActionPayload(
      actionKind: 'custom-untouched',
      parameters: const {'private': 'value'},
    );
    final replacement = _draft(project, current: opaque);
    expect(replacement.unsupported, isTrue);
    expect(replacement.valid, isFalse);
    replacement.choose(NarrativeCommandIds.giveMoney);
    replacement.changeParameter('amount', 'invalide');
    expect(replacement.valid, isFalse);
    replacement.changeParameter('amount', '42');
    expect(replacement.valid, isTrue);
    expect(
      (replacement.buildPayload() as SceneActionPayload).consequence,
      SceneConsequence.giveMoney(amount: 42),
    );
    expect(replacement.current, same(opaque));
    expect(opaque.parameters, {'private': 'value'});
  });

  test(
    '3D scene music keeps the scene lifetime and canonical stop command',
    () {
      final command = SceneMusicInteractiveCommand(
        operation: SceneMusicOperation.stop,
      );
      final draft = _draft(
        _project().copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        ),
        current: SceneActionPayload.interactive(command),
      );
      expect(
        draft
            .options(
              draft.command!.parameters
                  .singleWhere((field) => field.id == 'channel')
                  .kind,
            )
            .keys,
        ['music'],
      );
      expect(
        draft
            .options(
              draft.command!.parameters
                  .singleWhere((field) => field.id == 'scope')
                  .kind,
            )
            .keys,
        ['scene'],
      );
      expect(draft.valid, isTrue);
      expect(
        (draft.buildPayload() as SceneActionPayload).interactiveCommand,
        command,
      );
    },
  );

  for (final dimension in ProjectDimension.values) {
    test(
      'whiteOut command availability and typed default follow $dimension',
      () {
        final draft = _draft(
          _project().copyWith(settings: ProjectSettings(dimension: dimension)),
        );
        expect(
          draft.commands
              .map((entry) => entry.id)
              .contains(NarrativeCommandIds.whiteOut),
          dimension == ProjectDimension.twoD,
        );
        if (dimension == ProjectDimension.twoD) {
          draft.choose(NarrativeCommandIds.whiteOut);
          expect(draft.valid, isTrue);
          expect(
            (draft.buildPayload() as SceneActionPayload).interactiveCommand!
                .toJson(),
            {'kind': 'whiteOut'},
          );
        }
      },
    );
  }

  for (final interactive in [false, true]) {
    test(
      'catalogue gift composition retains ordered moves interactive=$interactive',
      () async {
        final draft = SceneActionDraft(
          project: _project(),
          changed: () {},
          loadSpecies: _species,
        );
        addTearDown(draft.dispose);
        draft.choose(
          interactive
              ? NarrativeCommandIds.receivePokemonFromCatalog
              : NarrativeCommandIds.givePokemonFromCatalog,
        );
        await _settle();
        draft.changeParameter('speciesId', 'bird');
        expect(draft.options(NarrativeCommandParameterKind.speciesForm).keys, [
          'base',
        ]);
        draft.setGiftMoves(['exceptional', 'tackle']);
        final moves = ScenePokemonGiftMovesDraft(
          value: draft.giftMoves,
          changed: () {},
          onChanged: draft.setGiftMoves,
          onValidityChanged: draft.setGiftMovesValid,
          loadMoves: () async => {
            'exceptional': 'Capacité exceptionnelle',
            'tackle': 'Charge',
          },
        );
        addTearDown(moves.dispose);
        await moves.load();
        moves.swap(0, 1);
        expect(draft.valid, isTrue);
        final payload = draft.buildPayload() as SceneActionPayload;
        expect(
          (payload.consequence?.toJson() ??
              payload.interactiveCommand!.toJson())['moveIds'],
          ['tackle', 'exceptional'],
        );
      },
    );
  }

  test(
    'an imposed missing gift move stays recorded and prevents applying',
    () async {
      final original = SceneActionPayload.consequence(
        SceneConsequence.givePokemonFromCatalog(
          speciesId: 'bird',
          formId: 'base',
          level: 8,
          moveIds: ['removed', 'tackle'],
        ),
      );
      final draft = SceneActionDraft(
        project: _project(),
        current: original,
        changed: () {},
        loadSpecies: _species,
      );
      addTearDown(draft.dispose);
      final moves = ScenePokemonGiftMovesDraft(
        value: draft.giftMoves,
        changed: () {},
        onChanged: draft.setGiftMoves,
        onValidityChanged: draft.setGiftMovesValid,
        loadMoves: () async => {'tackle': 'Charge'},
      );
      addTearDown(moves.dispose);
      await _settle();
      expect(moves.value, ['removed', 'tackle']);
      expect(moves.valid, isFalse);
      expect(draft.giftMoves, ['removed', 'tackle']);
      expect(draft.valid, isFalse);
      expect(draft.current, same(original));
    },
  );

  test('gift catalogue scope changes invalidate imposed moves while equal projections do not reload', () async {
    final project = _project();
    var catalogue = {'tackle': 'Charge'};
    var loads = 0;
    Future<Map<String, String>> load() async {
      loads++;
      return catalogue;
    }

    final original = SceneActionPayload.consequence(
      SceneConsequence.givePokemonFromCatalog(
        speciesId: 'bird',
        formId: 'base',
        level: 8,
        moveIds: ['tackle'],
      ),
    );
    final draft = SceneActionDraft(
      project: project,
      current: original,
      changed: () {},
      loadSpecies: _species,
    );
    addTearDown(draft.dispose);
    final moves = ScenePokemonGiftMovesDraft(
      value: draft.giftMoves,
      catalogueScope: project,
      changed: () {},
      onChanged: draft.setGiftMoves,
      onValidityChanged: draft.setGiftMovesValid,
      loadMoves: load,
    );
    addTearDown(moves.dispose);
    await _settle();
    expect(draft.valid, isTrue);
    expect(loads, 1);
    moves.configure(
      value: draft.giftMoves,
      catalogueScope: project.copyWith(),
      loadMoves: load,
    );
    await _settle();
    expect(loads, 1);
    catalogue = {'surf': 'Surf'};
    moves.configure(
      value: draft.giftMoves,
      catalogueScope: project.copyWith(name: 'Other project'),
      loadMoves: load,
    );
    await _settle();
    expect(loads, 2);
    expect(moves.value, ['tackle']);
    expect(moves.moves, {'surf': 'Surf'});
    expect(moves.valid, isFalse);
    expect(draft.valid, isFalse);
    expect(draft.current, same(original));
  });
}

SceneActionDraft _draft(
  ProjectManifest project, {
  SceneNodePayload? current,
  Future<MapData> Function(String)? loadMap,
  Future<Map<String, String>> Function()? loadItems,
}) {
  final draft = SceneActionDraft(
    project: project,
    current: current,
    changed: () {},
    loadMap: loadMap,
    loadItems: loadItems,
  );
  addTearDown(draft.dispose);
  return draft;
}

void _configure(SceneActionDraft draft, ProjectManifest project) =>
    draft.configure(
      project: project,
      current: draft.current,
      loadMap: draft.loadMap,
      loadMoves: draft.loadMoves,
      loadItems: draft.loadItems,
      loadSpecies: draft.loadSpecies,
      commandCatalog: draft.commandCatalog,
    );
Future<void> _settle() => Future<void>.delayed(Duration.zero);
ProjectManifest _project() => const ProjectManifest(
  name: 'Actions',
  tilesets: [],
  maps: [
    ProjectMapEntry(id: 'room', name: 'Room', relativePath: 'maps/room.json'),
    ProjectMapEntry(
      id: 'forest',
      name: 'Bois',
      relativePath: 'maps/forest.json',
    ),
  ],
);
ProjectManifest _avatarProject() => _project().copyWith(
  characters: [
    _character('hero', 'Tenue de voyage'),
    _character('costume', 'Tenue de soirée'),
  ],
);
ProjectCharacterEntry _character(String id, String name) =>
    ProjectCharacterEntry(
      id: id,
      name: name,
      tilesetId: 'unused',
      animations: [
        for (final direction in EntityFacing.values)
          CharacterAnimation(
            state: CharacterAnimationState.walk,
            direction: direction,
            sourceAssetId: id,
            frames: [
              CharacterAnimationFrame(
                source: const TilesetSourceRect(
                  x: 0,
                  y: 0,
                  width: 32,
                  height: 32,
                ),
                durationMs: 100,
              ),
            ],
          ),
      ],
    );
Future<List<PokemonSpeciesSummary>> _species() async => const [
  PokemonSpeciesSummary(
    id: 'bird',
    name: 'Oiseau',
    nationalDex: 1,
    generation: 1,
    types: ['normal'],
    formIds: ['base', 'sunny'],
    baseFormId: 'base',
    mediaRelativePath: '',
    enabled: true,
    relativePath: 'bird.json',
  ),
];
