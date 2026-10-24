import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('empty journal is const and round trips schema one', () {
    const journal = GameCompletionPartyJournal.empty();
    expect(journal.schemaVersion, 1);
    expect(journal.records, isEmpty);
    expect(journal.toJson(), {'schemaVersion': 1, 'records': []});
    expect(GameCompletionPartyJournal.fromJson(journal.toJson()), journal);
    expect(() => journal.records.add(_record()), throwsUnsupportedError);
  });

  test(
    'snapshot preserves every Pokemon field and detaches mutable inputs',
    () {
      final moves = ['surf', 'bite'];
      final pp = {'surf': 9, 'bite': 17};
      final members = [_pokemon(moves: moves, pp: pp)];
      final source = PlayerParty(members: members);
      final original = jsonDecode(jsonEncode(source.toJson()));
      final record = _record(party: source);
      moves[0] = 'tackle';
      pp['surf'] = 0;
      members.clear();
      expect(record.party.toJson(), original);
      expect(() => record.party.members.clear(), throwsUnsupportedError);
      expect(
        () => record.party.members.single.knownMoveIds.add('growl'),
        throwsUnsupportedError,
      );
      expect(
        () => record.party.members.single.currentPpByMoveId!['surf'] = 0,
        throwsUnsupportedError,
      );
      final json = record.toJson();
      final decoded = GameCompletionPartyRecord.fromJson(json);
      (json['party'] as Map)['members'] = [];
      expect(decoded, record);
      expect(decoded.hashCode, record.hashCode);
      expect(decoded.party.members.single.nickname, ' Lumière ');
    },
  );

  test(
    'journal detaches its record collection and records each ending once',
    () {
      final first = _record();
      final records = [first];
      final journal = GameCompletionPartyJournal(records: records);
      records.clear();
      expect(journal.records, [first]);
      final replacement = _record(time: 999, trainer: 'Autre');
      expect(identical(journal.record(replacement), journal), isTrue);
      expect(journal.record(replacement).records.single, first);
      final second = _record(ending: 'postgame', time: 456);
      final appended = journal.record(second);
      expect(journal.records, [first]);
      expect(appended.records, [first, second]);
      final restored = GameCompletionPartyJournal.fromJson(
        jsonDecode(jsonEncode(appended.toJson())) as Map<String, dynamic>,
      );
      expect(restored, appended);
      expect(restored.hashCode, appended.hashCode);
    },
  );

  test(
    'records accept one through six and preserve order fainted and null data',
    () {
      for (final count in [1, 6]) {
        final party = PlayerParty(
          members: [
            for (var i = 0; i < count; i++)
              _pokemon(id: 'pkm_$i').copyWith(
                currentHp: i,
                experience: null,
                currentPpByMoveId: null,
                provenance: null,
              ),
          ],
        );
        final record = _record(party: party);
        expect(record.party, party);
        expect(GameCompletionPartyRecord.fromJson(record.toJson()), record);
      }
    },
  );

  test('rejects malformed record identities timestamps and party sizes', () {
    for (final ending in ['', ' ', ' ending', 'ending\n']) {
      expect(() => _record(ending: ending), throwsFormatException);
    }
    for (final time in [-1, 9007199254740992]) {
      expect(() => _record(time: time), throwsFormatException);
    }
    expect(_record(time: 0).completedAtEpochMs, 0);
    expect(
      _record(time: 9007199254740991).completedAtEpochMs,
      9007199254740991,
    );
    for (final size in [0, 7]) {
      expect(
        () => _record(
          party: PlayerParty(
            members: [for (var i = 0; i < size; i++) _pokemon(id: 'pkm_$i')],
          ),
        ),
        throwsFormatException,
      );
    }
    for (final id in ['', ' ', ' pkm_1', 'pkm_1 ', 'pkm\n1']) {
      expect(
        () => _record(
          party: PlayerParty(members: [_pokemon(id: id)]),
        ),
        throwsFormatException,
      );
    }
    expect(
      () => _record(party: PlayerParty(members: [_pokemon(), _pokemon()])),
      throwsFormatException,
    );
  });

  test('archives runtime forms gender values and nulls without coercion', () {
    for (final gender in [null, 'male', 'female', 'genderless']) {
      for (final form in ['', 'wash', 'origin-form']) {
        final pokemon = _pokemon().copyWith(formId: form, gender: gender);
        final record = _record(party: PlayerParty(members: [pokemon]));
        final restored = GameCompletionPartyRecord.fromJson(record.toJson());
        expect(restored.party.members.single, pokemon);
        expect(restored.party.members.single.formId, form);
        expect(restored.party.members.single.gender, gender);
      }
    }
  });

  test(
    'mutating serialized nested fields cannot alter the captured record',
    () {
      final record = _record();
      final expected = jsonDecode(jsonEncode(record.toJson()));
      final beforeHash = record.hashCode;
      final raw = record.toJson();
      final pokemon = ((raw['party'] as Map)['members'] as List).single as Map;
      (pokemon['ivs'] as Map)['hp'] = 0;
      (pokemon['evs'] as Map)['attack'] = 0;
      (pokemon['provenance'] as Map)['metLevel'] = 100;
      pokemon['knownMoveIds'] = ['tackle'];
      pokemon['currentPpByMoveId'] = {'surf': 0};
      expect(record.toJson(), expected);
      expect(record.hashCode, beforeHash);
    },
  );

  test('rejects invalid Pokemon state without normalizing the team', () {
    for (final pokemon in [
      _pokemon().copyWith(speciesId: ' totodile'),
      _pokemon().copyWith(level: 0),
      _pokemon().copyWith(level: 101),
      _pokemon().copyWith(currentHp: -1),
      _pokemon().copyWith(friendship: 256),
      _pokemon().copyWith(experience: -1),
      _pokemon().copyWith(experience: 9007199254740992),
      _pokemon().copyWith(ivs: const PokemonStatSpread(hp: -1)),
      _pokemon().copyWith(knownMoveIds: ['surf', 'surf']),
      _pokemon().copyWith(knownMoveIds: ['surf ']),
      _pokemon().copyWith(knownMoveIds: ['a', 'b', 'c', 'd', 'e']),
      _pokemon().copyWith(currentPpByMoveId: {'surf': -1}),
      _pokemon().copyWith(currentPpByMoveId: {'surf': 9007199254740992}),
      _pokemon().copyWith(
        provenance: const PlayerPokemonProvenance(metLevel: 101),
      ),
    ]) {
      expect(
        () => _record(party: PlayerParty(members: [pokemon])),
        throwsFormatException,
      );
    }
  });

  test(
    'strict readers reject unknown keys missing keys wrong types and coercions',
    () {
      final valid = _record().toJson();
      Map<String, dynamic> fresh() =>
          jsonDecode(jsonEncode(valid)) as Map<String, dynamic>;
      final cases = <Map<String, dynamic>>[];
      cases.add({...fresh(), 'unknown': true});
      cases.add(fresh()..remove('trainerName'));
      cases.add({...fresh(), 'completedAtEpochMs': 1.5});
      cases.add({...fresh(), 'completedAtEpochMs': '123'});
      cases.add({...fresh(), 'mapId': ''});
      cases.add({...fresh(), 'trainerName': '   '});
      for (final field in ['level', 'currentHp', 'friendship', 'experience']) {
        final raw = fresh();
        ((raw['party'] as Map)['members'] as List).first[field] = 1.5;
        cases.add(raw);
      }
      for (final change in [
        (Map party) => party['unknown'] = true,
        (Map party) => (party['members'] as List).first['unknown'] = true,
        (Map party) =>
            ((party['members'] as List).first['ivs'] as Map)['unknown'] = 1,
        (Map party) =>
            ((party['members'] as List).first['provenance'] as Map)['unknown'] =
                1,
        (Map party) =>
            ((party['members'] as List).first['ivs'] as Map)['hp'] = 1.5,
        (Map party) =>
            ((party['members'] as List).first['provenance']
                    as Map)['metLevel'] =
                1.5,
        (Map party) =>
            ((party['members'] as List).first['currentPpByMoveId']
                    as Map)['surf'] =
                1.5,
        (Map party) => (party['members'] as List).first.remove('individualId'),
      ]) {
        final raw = fresh();
        change(raw['party'] as Map);
        cases.add(raw);
      }
      for (final json in cases) {
        expect(
          () => GameCompletionPartyRecord.fromJson(json),
          throwsFormatException,
          reason: jsonEncode(json),
        );
      }
      final raw = fresh();
      final restored = GameCompletionPartyRecord.fromJson(raw);
      ((raw['party'] as Map)['members'] as List).first['knownMoveIds'].clear();
      ((raw['party'] as Map)['members'] as List).first['currentPpByMoveId']
          .clear();
      expect(restored, _record());
    },
  );

  test('journal rejects future malformed or duplicate-ending wire data', () {
    final record = _record();
    for (final json in [
      <String, dynamic>{},
      {'schemaVersion': 2, 'records': []},
      {'schemaVersion': 1.0, 'records': []},
      {'schemaVersion': 1, 'records': null},
      {'schemaVersion': 1, 'records': {}},
      {'schemaVersion': 1, 'records': [], 'unknown': false},
      {
        'schemaVersion': 1,
        'records': [false],
      },
      {
        'schemaVersion': 1,
        'records': [record.toJson(), record.toJson()],
      },
    ]) {
      expect(
        () => GameCompletionPartyJournal.fromJson(json),
        throwsFormatException,
      );
    }
    expect(
      () => GameCompletionPartyJournal(records: [record, record]),
      throwsFormatException,
    );
  });
}

GameCompletionPartyRecord _record({
  String ending = 'johto-league',
  int time = 123,
  String trainer = 'Yoahn',
  PlayerParty? party,
}) => GameCompletionPartyRecord.snapshot(
  endingId: ending,
  completedAtEpochMs: time,
  mapId: 'hall-of-fame',
  trainerName: trainer,
  party: party ?? PlayerParty(members: [_pokemon()]),
);

PlayerPokemon _pokemon({
  String id = 'pkm_123',
  List<String>? moves,
  Map<String, int>? pp,
}) => PlayerPokemon(
  individualId: id,
  speciesId: 'totodile',
  formId: 'totodile',
  natureId: 'jolly',
  abilityId: 'torrent',
  gender: 'male',
  level: 48,
  ivs: const PokemonStatSpread(
    hp: 31,
    attack: 30,
    defense: 29,
    specialAttack: 28,
    specialDefense: 27,
    speed: 26,
  ),
  evs: const PokemonStatSpread(hp: 120, attack: 252, speed: 136),
  knownMoveIds: moves ?? ['surf', 'bite'],
  experience: 90000,
  currentPpByMoveId: pp ?? {'surf': 9, 'bite': 17},
  currentHp: 0,
  statusId: 'poison',
  isShiny: true,
  heldItemId: 'mystic-water',
  nickname: ' Lumière ',
  friendship: 222,
  provenance: const PlayerPokemonProvenance(
    kind: PlayerPokemonOriginKind.starter,
    mapId: 'elm-lab',
    sourceId: 'starter',
    ballItemId: 'poke-ball',
    metLevel: 5,
  ),
);
