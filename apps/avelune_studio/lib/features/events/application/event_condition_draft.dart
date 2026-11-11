import 'package:map_core/map_core_domain.dart';

enum EventConditionInputKind { fact, event, instance, periodicReward }

bool isEventConditionEditable(NarrativeEventCondition condition) =>
    condition.rewardReference == null;

List<EventConditionInputKind> eventConditionCreationKinds({
  String? mapId,
  String? entityId,
}) => [
  EventConditionInputKind.fact,
  EventConditionInputKind.event,
  if (mapId != null && entityId != null) EventConditionInputKind.instance,
];

class EventConditionDraft {
  EventConditionDraft({
    required this.facts,
    this.mapId,
    this.entityId,
    NarrativeEventCondition? initial,
  }) {
    initial?.whenTyped<void>(
      periodicRewardAvailable: (reference, expected) {
        kind = EventConditionInputKind.periodicReward;
        rewardReference = reference;
        boolean = expected;
      },
      fact: (id, operator, value) {
        sourceId = id;
        comparison = operator;
        if (value.kind == NarrativeValueKind.boolean) {
          boolean = value.boolValue;
        } else {
          text = value.toJson().toString();
        }
      },
      narrativeEventConsumed: (id, expected) {
        kind = EventConditionInputKind.event;
        sourceId = id;
        boolean = expected;
      },
      mapEventInstanceBoolean: (map, owner, key, expected) {
        kind = EventConditionInputKind.instance;
        mapId = map;
        entityId = owner;
        sourceId = key;
        boolean = expected;
      },
    );
  }

  final List<NarrativeFactDefinition> facts;
  EventConditionInputKind kind = EventConditionInputKind.fact;
  String? sourceId, mapId, entityId;
  NarrativeFactOperator comparison = NarrativeFactOperator.equals;
  bool boolean = true;
  String text = '';
  PeriodicRewardReference? rewardReference;

  NarrativeFactDefinition? get fact =>
      facts.where((fact) => fact.id == sourceId).firstOrNull;

  NarrativeEventCondition get condition {
    if (kind == EventConditionInputKind.periodicReward) {
      final reference = rewardReference;
      if (reference == null) throw StateError('Choisissez une référence.');
      return NarrativeEventCondition.periodicRewardAvailable(
        reference: reference,
        expectedValue: boolean,
      );
    }
    final id = sourceId;
    if (id == null) throw StateError('Choisissez une référence.');
    final selected = fact;
    final value = switch (selected?.valueKind) {
      NarrativeValueKind.integer => NarrativeValue.integer(int.parse(text)),
      NarrativeValueKind.string => NarrativeValue.string(text),
      _ => NarrativeValue.boolean(boolean),
    };
    if (kind == EventConditionInputKind.fact && selected == null) {
      throw StateError('Cet état est introuvable.');
    }
    return switch (kind) {
      EventConditionInputKind.instance =>
        NarrativeEventCondition.mapEventInstanceBoolean(
          mapId: mapId!,
          eventId: entityId!,
          key: id,
          expectedValue: boolean,
        ),
      EventConditionInputKind.event =>
        NarrativeEventCondition.narrativeEventConsumed(id, boolean),
      _ => NarrativeEventCondition.factValue(
        id,
        operator: comparison,
        expectedValue: value,
      ),
    };
  }
}
