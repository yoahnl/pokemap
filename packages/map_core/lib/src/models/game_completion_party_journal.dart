import 'package:meta/meta.dart';

import 'save_data.dart';

@immutable
final class GameCompletionPartyJournal {
  const GameCompletionPartyJournal.empty() : records = const [];

  GameCompletionPartyJournal({
    Iterable<GameCompletionPartyRecord> records = const [],
  }) : records = List.unmodifiable(records) {
    final ids = <String>{};
    for (final record in this.records) {
      if (!ids.add(record.endingId)) {
        throw const FormatException(
          'A completion ending may only be recorded once.',
        );
      }
    }
  }

  factory GameCompletionPartyJournal.fromJson(Map<String, dynamic> json) {
    _fields(json, const {'schemaVersion', 'records'}, 'journal');
    if (json['schemaVersion'] is! int || json['schemaVersion'] != 1) {
      throw const FormatException(
        'Unsupported completion party journal schema.',
      );
    }
    final records = json['records'];
    if (records is! List) {
      throw const FormatException('Completion party records must be an array.');
    }
    return GameCompletionPartyJournal(
      records: [
        for (final record in records)
          GameCompletionPartyRecord.fromJson(_object(record, 'record')),
      ],
    );
  }

  int get schemaVersion => 1;
  final List<GameCompletionPartyRecord> records;

  GameCompletionPartyJournal record(GameCompletionPartyRecord record) {
    if (records.any((existing) => existing.endingId == record.endingId))
      return this;
    return GameCompletionPartyJournal(records: [...records, record]);
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'records': records.map((record) => record.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameCompletionPartyJournal &&
          records.length == other.records.length &&
          List.generate(
            records.length,
            (index) => records[index] == other.records[index],
          ).every((equal) => equal);

  @override
  int get hashCode => Object.hash(schemaVersion, Object.hashAll(records));
}

@immutable
final class GameCompletionPartyRecord {
  const GameCompletionPartyRecord._({
    required this.endingId,
    required this.completedAtEpochMs,
    required this.mapId,
    required this.trainerName,
    required this.party,
  });

  factory GameCompletionPartyRecord.snapshot({
    required String endingId,
    required int completedAtEpochMs,
    required String mapId,
    required String trainerName,
    required PlayerParty party,
  }) {
    _identifier(endingId, 'endingId');
    _integer(completedAtEpochMs, 'completedAtEpochMs');
    _identifier(mapId, 'mapId');
    if (trainerName.trim().isEmpty || _control.hasMatch(trainerName)) {
      throw const FormatException(
        'The completion trainer name must be present.',
      );
    }
    final snapshot = _partyFromJson(party.toJson());
    return GameCompletionPartyRecord._(
      endingId: endingId,
      completedAtEpochMs: completedAtEpochMs,
      mapId: mapId,
      trainerName: trainerName,
      party: snapshot,
    );
  }

  factory GameCompletionPartyRecord.fromJson(Map<String, dynamic> json) {
    _fields(json, const {
      'endingId',
      'completedAtEpochMs',
      'mapId',
      'trainerName',
      'party',
    }, 'record');
    final ending = json['endingId'];
    final map = json['mapId'];
    final trainer = json['trainerName'];
    if (ending is! String || map is! String || trainer is! String) {
      throw const FormatException(
        'Completion record identities must be strings.',
      );
    }
    final time = _integer(json['completedAtEpochMs'], 'completedAtEpochMs');
    return GameCompletionPartyRecord.snapshot(
      endingId: ending,
      completedAtEpochMs: time,
      mapId: map,
      trainerName: trainer,
      party: _partyFromJson(_object(json['party'], 'party')),
    );
  }

  final String endingId;
  final int completedAtEpochMs;
  final String mapId;
  final String trainerName;
  final PlayerParty party;

  Map<String, dynamic> toJson() => {
    'endingId': endingId,
    'completedAtEpochMs': completedAtEpochMs,
    'mapId': mapId,
    'trainerName': trainerName,
    'party': party.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameCompletionPartyRecord &&
          endingId == other.endingId &&
          completedAtEpochMs == other.completedAtEpochMs &&
          mapId == other.mapId &&
          trainerName == other.trainerName &&
          party == other.party;

  @override
  int get hashCode =>
      Object.hash(endingId, completedAtEpochMs, mapId, trainerName, party);
}

const _pokemonFields = {
  'individualId',
  'speciesId',
  'formId',
  'natureId',
  'abilityId',
  'gender',
  'level',
  'ivs',
  'evs',
  'knownMoveIds',
  'experience',
  'currentPpByMoveId',
  'currentHp',
  'statusId',
  'isShiny',
  'heldItemId',
  'nickname',
  'friendship',
  'provenance',
};
const _stats = {
  'hp',
  'attack',
  'defense',
  'specialAttack',
  'specialDefense',
  'speed',
};
final _control = RegExp(r'[\x00-\x1f\x7f]');
final _whitespace = RegExp(r'\s');

PlayerParty _partyFromJson(Map<String, dynamic> json) {
  _fields(json, const {'members'}, 'party');
  final raw = json['members'];
  if (raw is! List || raw.isEmpty || raw.length > maxPlayerPartySize) {
    throw const FormatException(
      'A completion party requires one to six Pokemon.',
    );
  }
  final members = <PlayerPokemon>[];
  final ids = <String>{};
  for (final value in raw) {
    final member = _object(value, 'Pokemon');
    _fields(member, _pokemonFields, 'Pokemon');
    for (final field in [
      'individualId',
      'speciesId',
      'formId',
      'natureId',
      'abilityId',
      'statusId',
      'heldItemId',
      'nickname',
    ]) {
      if (member[field] is! String)
        throw FormatException('Pokemon $field must be a string.');
    }
    for (final field in [
      'individualId',
      'speciesId',
      'natureId',
      'abilityId',
    ]) {
      _identifier(member[field] as String, field);
    }
    for (final field in ['formId', 'statusId', 'heldItemId']) {
      final id = member[field] as String;
      if (id.isNotEmpty) _identifier(id, field);
    }
    if (!ids.add(member['individualId'] as String))
      throw const FormatException(
        'Completion Pokemon identities must be unique.',
      );
    if (member['gender'] != null && member['gender'] is! String)
      throw const FormatException('Pokemon gender must be a string or null.');
    if (member['isShiny'] is! bool)
      throw const FormatException('Pokemon isShiny must be a boolean.');
    _integer(member['level'], 'level', minimum: 1, maximum: 100);
    _integer(member['currentHp'], 'currentHp');
    _integer(member['friendship'], 'friendship', maximum: 255);
    if (member['experience'] != null)
      _integer(member['experience'], 'experience');
    for (final field in ['ivs', 'evs']) {
      final stats = _object(member[field], field);
      _fields(stats, _stats, field);
      for (final name in _stats) {
        _integer(stats[name], '$field.$name');
      }
    }
    final moves = member['knownMoveIds'];
    if (moves is! List || moves.length > 4)
      throw const FormatException(
        'Pokemon moves must be an array of at most four identities.',
      );
    final moveIds = <String>{};
    for (final move in moves) {
      if (move is! String)
        throw const FormatException(
          'A Pokemon move identity must be a string.',
        );
      _identifier(move, 'knownMoveIds');
      if (!moveIds.add(move))
        throw const FormatException('Pokemon move identities must be unique.');
    }
    final pp = member['currentPpByMoveId'];
    if (pp != null) {
      final values = _object(pp, 'currentPpByMoveId');
      for (final entry in values.entries) {
        _identifier(entry.key, 'currentPpByMoveId');
        _integer(entry.value, 'currentPpByMoveId.${entry.key}');
      }
    }
    final provenance = member['provenance'];
    if (provenance != null) {
      final origin = _object(provenance, 'provenance');
      _fields(origin, const {
        'kind',
        'mapId',
        'sourceId',
        'ballItemId',
        'metLevel',
      }, 'provenance');
      if (origin['kind'] is! String ||
          !PlayerPokemonOriginKind.values.any(
            (kind) => kind.name == origin['kind'],
          ))
        throw const FormatException('Invalid Pokemon origin kind.');
      for (final field in ['mapId', 'sourceId', 'ballItemId']) {
        final value = origin[field];
        if (value is! String ||
            value != value.trim() ||
            _control.hasMatch(value))
          throw FormatException('Invalid provenance $field.');
      }
      if (origin['metLevel'] != null)
        _integer(origin['metLevel'], 'metLevel', minimum: 1, maximum: 100);
    }
    try {
      final pokemon = PlayerPokemon.fromJson(member);
      members.add(
        pokemon.copyWith(
          knownMoveIds: List.unmodifiable(pokemon.knownMoveIds),
          currentPpByMoveId: pokemon.currentPpByMoveId == null
              ? null
              : Map.unmodifiable(pokemon.currentPpByMoveId!),
        ),
      );
    } on Object catch (error) {
      throw FormatException('Invalid completion Pokemon: $error');
    }
  }
  return PlayerParty(members: List.unmodifiable(members));
}

Map<String, dynamic> _object(Object? value, String field) {
  if (value is! Map || value.keys.any((key) => key is! String))
    throw FormatException('$field must be a JSON object.');
  return Map<String, dynamic>.from(value);
}

void _fields(Map<String, dynamic> json, Set<String> expected, String field) {
  if (json.length != expected.length || !expected.every(json.containsKey))
    throw FormatException('$field has unknown or missing fields.');
}

void _identifier(String value, String field) {
  if (value.isEmpty ||
      value != value.trim() ||
      _control.hasMatch(value) ||
      _whitespace.hasMatch(value))
    throw FormatException('Invalid $field identity.');
}

int _integer(
  Object? value,
  String field, {
  int minimum = 0,
  int maximum = 9007199254740991,
}) {
  if (value is! int || value < minimum || value > maximum)
    throw FormatException(
      '$field must be an exact safe integer from $minimum to $maximum.',
    );
  return value;
}
