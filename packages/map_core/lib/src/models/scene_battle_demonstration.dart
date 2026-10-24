import 'save_data.dart';

final class SceneBattleDemonstrationChoice {
  SceneBattleDemonstrationChoice.fight(int index)
    : kind = 'fight', moveIndex = index, itemId = null {
    if (index < 0 || index > 3) throw ArgumentError.value(index, 'moveIndex');
  }

  SceneBattleDemonstrationChoice.capture(String id)
    : kind = 'capture', itemId = id, moveIndex = null {
    if (id.trim().isEmpty) throw ArgumentError.value(id, 'itemId');
  }

  factory SceneBattleDemonstrationChoice.fromJson(Map<String, dynamic> json) {
    try {
      switch (json['kind']) {
        case 'fight':
          _fields(json, {'kind', 'moveIndex'});
          if (json['moveIndex'] case final int index) {
            return SceneBattleDemonstrationChoice.fight(index);
          }
        case 'capture':
          _fields(json, {'kind', 'itemId'});
          if (json['itemId'] case final String id) {
            return SceneBattleDemonstrationChoice.capture(id);
          }
      }
    } on ArgumentError catch (error) {
      throw FormatException('Invalid demonstration choice: $error');
    }
    throw const FormatException('Invalid demonstration choice.');
  }

  final String kind;
  final int? moveIndex;
  final String? itemId;

  Map<String, dynamic> toJson() => {
    'kind': kind,
    if (moveIndex != null) 'moveIndex': moveIndex,
    if (itemId != null) 'itemId': itemId,
  };

  @override
  bool operator ==(Object other) => other is SceneBattleDemonstrationChoice &&
      other.kind == kind && other.moveIndex == moveIndex && other.itemId == itemId;

  @override
  int get hashCode => Object.hash(kind, moveIndex, itemId);
}

final class SceneBattleDemonstration {
  static const capabilityId = 'battle.demonstration@1';
  SceneBattleDemonstration({
    required this.playerTrainerId,
    required List<BagEntry> bagItems,
    required List<SceneBattleDemonstrationChoice> choices,
    this.captureAlwaysSucceeds = false,
    this.stepDelayMs = 500,
  }) : bagItems = List.unmodifiable(bagItems), choices = List.unmodifiable(choices) {
    if (playerTrainerId.trim().isEmpty) throw ArgumentError.value(playerTrainerId, 'playerTrainerId');
    if (choices.isEmpty || choices.length > 100) throw ArgumentError.value(choices.length, 'choices');
    if (stepDelayMs < 50 || stepDelayMs > 10000) throw ArgumentError.value(stepDelayMs, 'stepDelayMs');
    final ids = <String>{};
    for (final item in bagItems) {
      if (item.itemId.trim().isEmpty || item.quantity < 1 || !ids.add(item.itemId)) {
        throw ArgumentError.value(item.toJson(), 'bagItems');
      }
    }
  }

  factory SceneBattleDemonstration.fromJson(Map<String, dynamic> json) {
    _fields(json, {'playerTrainerId', 'bagItems', 'choices', 'captureAlwaysSucceeds', 'stepDelayMs'});
    final trainer = json['playerTrainerId'];
    final items = json['bagItems'];
    final choices = json['choices'];
    final capture = json['captureAlwaysSucceeds'] ?? false;
    final delay = json['stepDelayMs'] ?? 500;
    if (trainer is! String || items is! List || choices is! List || capture is! bool || delay is! int) {
      throw const FormatException('Invalid demonstration configuration.');
    }
    try {
      return SceneBattleDemonstration(
        playerTrainerId: trainer,
        bagItems: [for (final item in items) _bagItem(item)],
        choices: [for (final choice in choices) SceneBattleDemonstrationChoice.fromJson(_object(choice))],
        captureAlwaysSucceeds: capture,
        stepDelayMs: delay,
      );
    } on ArgumentError catch (error) {
      throw FormatException('Invalid demonstration configuration: $error');
    }
  }

  final String playerTrainerId;
  final List<BagEntry> bagItems;
  final List<SceneBattleDemonstrationChoice> choices;
  final bool captureAlwaysSucceeds;
  final int stepDelayMs;

  Map<String, dynamic> toJson() => {
    'playerTrainerId': playerTrainerId,
    'bagItems': [for (final item in bagItems) item.toJson()],
    'choices': [for (final choice in choices) choice.toJson()],
    'captureAlwaysSucceeds': captureAlwaysSucceeds,
    'stepDelayMs': stepDelayMs,
  };

  @override
  bool operator ==(Object other) => other is SceneBattleDemonstration &&
      other.playerTrainerId == playerTrainerId &&
      other.captureAlwaysSucceeds == captureAlwaysSucceeds && other.stepDelayMs == stepDelayMs &&
      _same(other.bagItems, bagItems) && _same(other.choices, choices);

  @override
  int get hashCode => Object.hash(playerTrainerId, captureAlwaysSucceeds, stepDelayMs,
      Object.hashAll(bagItems), Object.hashAll(choices));
}

bool _same(List<Object> left, List<Object> right) => left.length == right.length &&
    Iterable<int>.generate(left.length).every((index) => left[index] == right[index]);

Map<String, dynamic> _object(Object? value) {
  if (value is! Map<String, dynamic>) throw const FormatException('Expected a demonstration object.');
  return value;
}

void _fields(Map<String, dynamic> json, Set<String> allowed) {
  if (json.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Unknown demonstration fields.');
  }
}

BagEntry _bagItem(Object? value) {
  final json = _object(value);
  _fields(json, {'itemId', 'quantity'});
  if (json['itemId'] is! String || json['quantity'] is! int) {
    throw const FormatException('Invalid demonstration bag item.');
  }
  return BagEntry.fromJson(json);
}
