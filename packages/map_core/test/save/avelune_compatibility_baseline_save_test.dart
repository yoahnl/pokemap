import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _fixtureDirectory =
    'test/fixtures/compatibility/avelune_studio_0_3_31_331';
const _fixtureHashes = <String, String>{
  'active-2d-save.json':
      '5576df1325856bf213e690a8b7f8a59548fb187868d7230a677b006d5a27e07f',
  'completed-spatial-save.json':
      'b88fa0dfb34f366336545e4def5ea7cf82066d9f11ed6888b941f71b1d37c326',
};

void main() {
  const codec = SaveEnvelopeCodec();
  const mapper = GameStateSaveEnvelopeMapper();

  group('Avelune Studio 0.3.31+331 frozen save contracts', () {
    for (final fixture in _fixtureHashes.entries) {
      test('${fixture.key} retains its exact baseline bytes', () {
        expect(
          sha256.convert(_readBytes(fixture.key)).toString(),
          fixture.value,
        );
      });
    }

    test('Continue restores the active 2D baseline progression', () {
      final bytes = _readBytes('active-2d-save.json');
      final originalBytes = List<int>.of(bytes);
      final envelope = codec.decodeUtf8(
        bytes,
        expectedAddress: SaveSlotAddress(
          gameId: 'games.example.baseline',
          profileId: 'player-1',
          slotId: 'slot-1',
        ),
      );
      final state = mapper.restore(envelope);

      _expectEnvelopeIdentity(envelope, ProjectFormat.v8);
      _expectProgression(state);
      expect(envelope.status, SaveStatus.active);
      expect(envelope.completedAt, isNull);
      expect(state.currentMapId, 'harbor');
      expect(state.playerPixelPosition, const PixelOffset(x: 72, y: 120));
      expect(state.playerSpatialPosition, isNull);
      expect(state.completionPartyJournal.records, isEmpty);
      expect(codec.verifyChecksum(envelope), isTrue);
      expect(bytes, originalBytes);
      expect(_readBytes('active-2d-save.json'), originalBytes);
    });

    test(
      'Continue restores completed 3D state and the original winning party',
      () {
        final bytes = _readBytes('completed-spatial-save.json');
        final originalBytes = List<int>.of(bytes);
        final envelope = codec.decodeUtf8(bytes);
        final state = mapper.restore(envelope);

        _expectEnvelopeIdentity(envelope, ProjectFormat.v9);
        _expectProgression(state);
        expect(envelope.gameId, 'games.example.baseline-spatial');
        expect(envelope.status, SaveStatus.completed);
        expect(envelope.completedAt, DateTime.utc(2026, 10, 24, 12));
        expect(state.currentMapId, 'victory-hall-3d');
        expect(state.playerPixelPosition, isNull);
        expect(state.playerSpatialPosition?.x, 4.25);
        expect(state.playerSpatialPosition?.z, 7.75);
        state.playerSpatialPosition!.validateGridPosition(state.playerPosition);
        final gate = state.spatialWorldState.modelState(
          'victory-hall-3d',
          'gate-1',
        );
        expect(gate?.modelId, 'harbor-gate');
        expect(gate?.animationIndex, 1);
        expect(gate?.normalizedTime, 0.75);
        expect(gate?.blocksMovement, isFalse);
        final guide = state.spatialWorldState.actorState(
          'victory-hall-3d',
          'guide',
        );
        expect(guide?.x, 6.5);
        expect(guide?.z, 8.25);
        expect(guide?.facing, EntityFacing.west);
        final record = state.completionPartyJournal.records.single;
        expect(record.endingId, 'harbor-victory');
        expect(
          record.completedAtEpochMs,
          DateTime.utc(2026, 10, 24, 12).millisecondsSinceEpoch,
        );
        expect(record.mapId, 'victory-hall-3d');
        expect(record.trainerName, 'Alice');
        _expectStarter(record.party.members.single);
        expect(codec.verifyChecksum(envelope), isTrue);
        expect(bytes, originalBytes);
        expect(_readBytes('completed-spatial-save.json'), originalBytes);
      },
    );

    for (final field in ['schemaVersion', 'saveFormat']) {
      test('rejects an unknown future $field without changing source data', () {
        final json = _readJson('active-2d-save.json')..[field] = 999;
        if (field == 'schemaVersion') {
          json['futureEnvelopeField'] = {'revision': 999};
        } else {
          json['projectFormat'] = 'v999';
          json['futureEnvelopeField'] = {'revision': 999};
        }
        json['checksum'] = {
          'algorithm': 'sha256',
          'value': codec.computeChecksum(json),
        };
        final original = jsonEncode(json);
        final bytes = utf8.encode(original);
        final originalBytes = List<int>.of(bytes);
        final expectedCode = field == 'schemaVersion'
            ? SaveContractErrorCode.unsupportedSchema
            : SaveContractErrorCode.unsupportedSaveFormat;

        expect(() => codec.decodeJson(json), throwsA(_error(expectedCode)));
        expect(() => codec.decodeUtf8(bytes), throwsA(_error(expectedCode)));
        expect(jsonEncode(json), original);
        expect(bytes, originalBytes);
      });
    }

    test('rejects corrupted progress without accepting the old checksum', () {
      final json = _readJson('active-2d-save.json');
      final state = json['state']! as Map<String, dynamic>;
      final trainer = state['trainerProfile']! as Map<String, dynamic>;
      trainer['money'] = 999999;
      final original = jsonEncode(json);
      final bytes = utf8.encode(original);
      final originalBytes = List<int>.of(bytes);

      expect(
        () => codec.decodeJson(json),
        throwsA(_error(SaveContractErrorCode.checksumMismatch)),
      );
      expect(
        () => codec.decodeUtf8(bytes),
        throwsA(_error(SaveContractErrorCode.checksumMismatch)),
      );
      expect(jsonEncode(json), original);
      expect(bytes, originalBytes);
    });

    test(
      'rejects a validly signed future nested schema without rewriting it',
      () {
        final json = _readJson('completed-spatial-save.json');
        final state = json['state']! as Map<String, dynamic>;
        final journal =
            state['completionPartyJournal']! as Map<String, dynamic>;
        journal['schemaVersion'] = 999;
        json['checksum'] = {
          'algorithm': 'sha256',
          'value': codec.computeChecksum(json),
        };
        final original = jsonEncode(json);
        final envelope = codec.decodeJson(json);
        final beforeRestore = codec.encode(envelope);

        expect(codec.verifyChecksum(envelope), isTrue);
        expect(
          () => mapper.restore(envelope),
          throwsA(_error(SaveContractErrorCode.invalidField)),
        );
        expect(jsonEncode(json), original);
        expect(codec.encode(envelope), beforeRestore);
      },
    );
  });
}

List<int> _readBytes(String name) =>
    File('$_fixtureDirectory/$name').readAsBytesSync();

Map<String, dynamic> _readJson(String name) =>
    jsonDecode(utf8.decode(_readBytes(name))) as Map<String, dynamic>;

Matcher _error(SaveContractErrorCode code) =>
    isA<SaveContractException>().having((error) => error.code, 'code', code);

void _expectEnvelopeIdentity(
  SaveEnvelope envelope,
  ProjectFormat projectFormat,
) {
  expect(envelope.schemaVersion, 1);
  expect(envelope.saveFormat, 2);
  expect(envelope.projectFormat, projectFormat);
  expect(envelope.gameVersion, '1.2.0');
  expect(envelope.compatibilityId, 'baseline-campaign');
  expect(envelope.profileId, 'player-1');
  expect(envelope.slotId, 'slot-1');
  expect(envelope.saveId, '65edb580-8467-4ee5-9ad3-03a9f266dd95');
  expect(envelope.createdAt, DateTime.utc(2026, 10, 24, 10));
  expect(envelope.updatedAt, DateTime.utc(2026, 10, 24, 12));
  expect(envelope.playTimeSeconds, 7265);
}

void _expectProgression(GameState state) {
  expect(state.saveId, '65edb580-8467-4ee5-9ad3-03a9f266dd95');
  expect(state.metadata['compatibilityBaseline'], 'avelune-studio-0.3.31+331');
  expect(state.metadata['producerVersion'], '0.3.31+331');
  expect(state.playerPosition, const GridPos(x: 4, y: 7));
  expect(state.playerFacing, EntityFacing.east);
  expect(state.playerMovementMode, MovementMode.walk);
  expect(state.trainerProfile.name, 'Alice');
  expect(state.trainerProfile.avatarCharacterId, 'trainer-alice');
  expect(state.trainerProfile.money, 4321);
  expect(state.trainerProfile.playtimeSeconds, 7265);
  expect(state.trainerProfile.badgeIds, ['harbor-badge']);
  expect(
    {for (final entry in state.bag.entries) entry.itemId: entry.quantity},
    {'potion': 7, 'poke-ball': 3, 'harbor-key': 1},
  );
  expect(state.storyFlags.activeFlags, {'intro-complete', 'harbor-gate-open'});
  expect(state.progression.storyFlags, ['starter-received']);
  expect(state.progression.completedStepIds, [
    'meet-professor',
    'win-harbor-gym',
  ]);
  expect(state.progression.completedCutsceneIds, ['harbor-opening']);
  expect(state.progression.seenSpeciesIds, ['eevee', 'pidgey', 'pikachu']);
  expect(state.progression.caughtSpeciesIds, ['eevee', 'pikachu']);
  expect(state.progression.shopPurchaseCounts, {'harbor-shop:potion': 4});
  expect(
    state.scriptVariables.values['rival-battles'],
    const ScriptVariableValue.int(2),
  );
  expect(
    state.scriptVariables.values['ferry-ticket'],
    const ScriptVariableValue.bool(true),
  );
  expect(
    state.scriptVariables.values['chosen-starter'],
    const ScriptVariableValue.string('pikachu'),
  );
  expect(
    state.narrativeFactRuntimeState.valueFor('story.harbor.open')?.boolValue,
    isTrue,
  );
  expect(
    state.narrativeFactRuntimeState.valueFor('story.badge.count')?.intValue,
    1,
  );
  expect(
    state.narrativeFactRuntimeState
        .valueFor('story.ferry.destination')
        ?.stringValue,
    'island',
  );
  expect(state.completedBattleRequestIds, {'battle-harbor-leader-001'});
  expect(state.appliedPokemonGrantOperationIds, {'starter-grant-001'});
  expect(state.consumedEventIds, {'harbor-hidden-potion'});
  _expectStarter(state.party.members.single);
  final box = state.pokemonStorage.boxes.single;
  expect(box.id, 'box-1');
  expect(box.label, 'Équipe de réserve');
  expect(box.capacity, 30);
  final boxed = box.pokemon.single;
  expect(boxed.individualId, 'baseline-boxed-001');
  expect(boxed.speciesId, 'eevee');
  expect(boxed.natureId, 'calm');
  expect(boxed.abilityId, 'run-away');
  expect(boxed.level, 12);
  expect(boxed.experience, 1728);
  expect(boxed.currentHp, 34);
  expect(boxed.knownMoveIds, ['tackle']);
  expect(boxed.currentPpByMoveId, {'tackle': 21});
  expect(boxed.nickname, 'Nuage');
  expect(boxed.friendship, 80);
}

void _expectStarter(PlayerPokemon pokemon) {
  expect(pokemon.individualId, 'baseline-starter-001');
  expect(pokemon.speciesId, 'pikachu');
  expect(pokemon.natureId, 'hardy');
  expect(pokemon.abilityId, 'static');
  expect(pokemon.level, 18);
  expect(pokemon.experience, 5832);
  expect(pokemon.currentHp, 27);
  expect(pokemon.statusId, 'paralysis');
  expect(pokemon.knownMoveIds, ['thunder-shock', 'quick-attack']);
  expect(pokemon.currentPpByMoveId, {'thunder-shock': 19, 'quick-attack': 12});
  expect(pokemon.nickname, 'Étincelle');
  expect(pokemon.friendship, 120);
  expect(pokemon.heldItemId, 'oran-berry');
  expect(pokemon.isShiny, isTrue);
  expect(
    pokemon.ivs,
    const PokemonStatSpread(
      hp: 17,
      attack: 22,
      defense: 13,
      specialAttack: 29,
      specialDefense: 21,
      speed: 31,
    ),
  );
  expect(
    pokemon.evs,
    const PokemonStatSpread(
      hp: 4,
      attack: 16,
      defense: 0,
      specialAttack: 12,
      specialDefense: 0,
      speed: 28,
    ),
  );
}
