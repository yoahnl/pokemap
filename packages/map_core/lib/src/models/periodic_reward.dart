import 'gameplay_calendar.dart';

final class PeriodicItemRewardDefinition {
  PeriodicItemRewardDefinition({
    required this.rewardId,
    required this.label,
    required this.itemId,
    required this.quantity,
  }) {
    _identity(rewardId);
    _identity(label);
    _identity(itemId);
    _integerRange(quantity, 1);
  }

  factory PeriodicItemRewardDefinition.fromJson(Map<String, dynamic> json) {
    _fields(json, {'schemaVersion', 'rewardId', 'label', 'itemId', 'quantity'});
    _version(json);
    return PeriodicItemRewardDefinition(
      rewardId: _string(json, 'rewardId'),
      label: _string(json, 'label'),
      itemId: _string(json, 'itemId'),
      quantity: _integer(json, 'quantity'),
    );
  }

  final String rewardId, label, itemId;
  final int quantity;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'rewardId': rewardId,
    'label': label,
    'itemId': itemId,
    'quantity': quantity,
  };

  @override
  bool operator ==(Object other) =>
      other is PeriodicItemRewardDefinition &&
      rewardId == other.rewardId &&
      label == other.label &&
      itemId == other.itemId &&
      quantity == other.quantity;

  @override
  int get hashCode => Object.hash(rewardId, label, itemId, quantity);
}

final class PeriodicRewardClaim {
  PeriodicRewardClaim({
    required this.revision,
    required this.lastClaimDayRevision,
    required this.lastClaimLocalDay,
  }) {
    _integerRange(revision, 1);
    _integerRange(lastClaimDayRevision, 0);
    GameplayCalendarState.localDayNumber(lastClaimLocalDay);
  }

  factory PeriodicRewardClaim.fromJson(Map<String, dynamic> json) {
    _fields(json, {'revision', 'lastClaimDayRevision', 'lastClaimLocalDay'});
    return PeriodicRewardClaim(
      revision: _integer(json, 'revision'),
      lastClaimDayRevision: _integer(json, 'lastClaimDayRevision'),
      lastClaimLocalDay: _string(json, 'lastClaimLocalDay'),
    );
  }

  final int revision, lastClaimDayRevision;
  final String lastClaimLocalDay;

  Map<String, dynamic> toJson() => {
    'revision': revision,
    'lastClaimDayRevision': lastClaimDayRevision,
    'lastClaimLocalDay': lastClaimLocalDay,
  };

  @override
  bool operator ==(Object other) =>
      other is PeriodicRewardClaim &&
      revision == other.revision &&
      lastClaimDayRevision == other.lastClaimDayRevision &&
      lastClaimLocalDay == other.lastClaimLocalDay;

  @override
  int get hashCode =>
      Object.hash(revision, lastClaimDayRevision, lastClaimLocalDay);
}

final class PeriodicRewardState {
  const PeriodicRewardState.empty() : claimsById = const {};

  PeriodicRewardState({required Map<String, PeriodicRewardClaim> claimsById})
    : claimsById = Map.unmodifiable(claimsById) {
    for (final id in claimsById.keys) {
      _identity(id);
    }
  }

  factory PeriodicRewardState.fromJson(Map<String, dynamic> json) {
    _fields(json, {'schemaVersion', 'claimsById'});
    _version(json);
    final claims = _object(json['claimsById']);
    return PeriodicRewardState(
      claimsById: {
        for (final entry in claims.entries)
          entry.key: PeriodicRewardClaim.fromJson(_object(entry.value)),
      },
    );
  }

  final Map<String, PeriodicRewardClaim> claimsById;

  PeriodicRewardClaim? claimFor(String rewardId) => claimsById[rewardId];

  PeriodicRewardState withClaim(String rewardId, PeriodicRewardClaim claim) =>
      PeriodicRewardState(claimsById: {...claimsById, rewardId: claim});

  void validateCalendar(GameplayCalendarState calendar) {
    if (claimsById.values.any(
      (claim) =>
          !calendar.isInitialized ||
          claim.lastClaimDayRevision > calendar.dayRevision,
    )) {
      throw const FormatException(
        'Periodic rewards and calendar are inconsistent.',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'claimsById': {
      for (final entry in claimsById.entries) entry.key: entry.value.toJson(),
    },
  };

  @override
  bool operator ==(Object other) =>
      other is PeriodicRewardState &&
      claimsById.length == other.claimsById.length &&
      claimsById.entries.every(
        (entry) => other.claimsById[entry.key] == entry.value,
      );

  @override
  int get hashCode => Object.hashAllUnordered(
    claimsById.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

Object? readPeriodicRewardStateJson(Map<dynamic, dynamic> json, String key) {
  return json.containsKey(key) ? _object(json[key]) : null;
}

void _fields(Map<String, dynamic> json, Set<String> fields) {
  if (json.length != fields.length || !json.keys.toSet().containsAll(fields)) {
    throw const FormatException('Invalid periodic reward fields.');
  }
}

void _version(Map<String, dynamic> json) {
  if (json['schemaVersion'] is! int || json['schemaVersion'] != 1) {
    throw const FormatException('Unsupported periodic reward schema.');
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Periodic rewards require a JSON object.');
  }
  return Map<String, dynamic>.from(value);
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('Reward $key must be a string.');
  return value;
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('Reward $key must be an integer.');
  return value;
}

void _identity(String value) {
  if (value.isEmpty || value.trim() != value) {
    throw const FormatException(
      'Reward identities and labels must be nonempty and trim-exact.',
    );
  }
}

void _integerRange(int value, int minimum) {
  if (value < minimum || value > GameplayCalendarState.maximumRevision) {
    throw const FormatException('Periodic reward integer is out of range.');
  }
}
