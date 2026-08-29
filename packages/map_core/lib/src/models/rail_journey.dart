import 'package:freezed_annotation/freezed_annotation.dart';

import 'geometry.dart';

part 'rail_journey.freezed.dart';
part 'rail_journey.g.dart';

const railJourneySchemaVersion = 1;

enum RailJourneyDirection {
  @JsonValue('outbound')
  outbound,
  @JsonValue('return')
  returnJourney,
}

enum RailJourneyLifecycle {
  @JsonValue('idle_at_origin')
  idleAtOrigin,
  boarding,
  @JsonValue('in_transit')
  inTransit,
  arrived,
  disembarked,
}

enum RailJourneyDoorSide { west, east }

enum RailJourneyOperationKind {
  begin,
  @JsonValue('doors_closed')
  doorsClosed,
  @JsonValue('arrival_reached')
  arrivalReached,
  @JsonValue('destination_door_used')
  destinationDoorUsed,
  acknowledge,
}

enum RailProgressionOperationKind {
  @JsonValue('grant_currency')
  grantCurrency,
  @JsonValue('grant_stamp')
  grantStamp,
}

enum RailJourneyVehicleVariant {
  regular,
  @JsonValue('restored_railcar')
  restoredRailcar,
}

enum RailJourneyFarePolicy {
  @JsonValue('first_unlock_only')
  firstUnlockOnly,
  @JsonValue('story_free')
  storyFree,
  @JsonValue('epilogue_free')
  epilogueFree,
}

@freezed
abstract class RailJourneyEndpointDoor with _$RailJourneyEndpointDoor {
  const RailJourneyEndpointDoor._();

  const factory RailJourneyEndpointDoor({
    required RailJourneyDoorSide side,
    required String stationPlacedElementId,
    required String vehiclePlacedElementId,
  }) = _RailJourneyEndpointDoor;

  factory RailJourneyEndpointDoor.fromJson(Map<String, dynamic> json) =>
      _$RailJourneyEndpointDoorFromJson(json).validated();

  RailJourneyEndpointDoor validated() {
    return copyWith(
      stationPlacedElementId: _requiredId(
        stationPlacedElementId,
        'RailJourneyEndpointDoor.stationPlacedElementId',
      ),
      vehiclePlacedElementId: _requiredId(
        vehiclePlacedElementId,
        'RailJourneyEndpointDoor.vehiclePlacedElementId',
      ),
    );
  }
}

@freezed
abstract class RailJourneyFare with _$RailJourneyFare {
  const RailJourneyFare._();

  const factory RailJourneyFare({
    required RailJourneyFarePolicy policy,
    String? semanticCurrencyId,
    @JsonKey(fromJson: _railJourneyIntFromJson) @Default(0) int amount,
  }) = _RailJourneyFare;

  factory RailJourneyFare.fromJson(Map<String, dynamic> json) =>
      _$RailJourneyFareFromJson(json).validated();

  RailJourneyFare validated() {
    final currencyId = _trimOptional(semanticCurrencyId);
    switch (policy) {
      case RailJourneyFarePolicy.firstUnlockOnly:
        if (currencyId == null || amount <= 0) {
          throw StateError(
            'A first-unlock fare requires a currency and positive amount.',
          );
        }
      case RailJourneyFarePolicy.storyFree ||
          RailJourneyFarePolicy.epilogueFree:
        if (currencyId != null || amount != 0) {
          throw StateError('A free journey cannot carry a debit.');
        }
    }
    return copyWith(semanticCurrencyId: currencyId);
  }
}

@freezed
abstract class RailJourneyRequirements with _$RailJourneyRequirements {
  const RailJourneyRequirements._();

  const factory RailJourneyRequirements({
    @Default(<String>{}) Set<String> completedStoryStepIds,
    @Default(<String>{}) Set<String> requiredFactIds,
    @Default(<String>{}) Set<String> requiredAnyFactIds,
    @Default(<String>{}) Set<String> requiredItemIds,
    @Default(<String>{}) Set<String> requiredStampIds,
  }) = _RailJourneyRequirements;

  factory RailJourneyRequirements.fromJson(Map<String, dynamic> json) =>
      _$RailJourneyRequirementsFromJson(json).validated();

  RailJourneyRequirements validated() {
    return copyWith(
      completedStoryStepIds: _validatedIds(
        completedStoryStepIds,
        'completedStoryStepIds',
      ),
      requiredFactIds: _validatedIds(requiredFactIds, 'requiredFactIds'),
      requiredAnyFactIds: _validatedIds(
        requiredAnyFactIds,
        'requiredAnyFactIds',
      ),
      requiredItemIds: _validatedIds(requiredItemIds, 'requiredItemIds'),
      requiredStampIds: _validatedIds(requiredStampIds, 'requiredStampIds'),
    );
  }
}

@freezed
abstract class RailJourneyEndpoint with _$RailJourneyEndpoint {
  const RailJourneyEndpoint._();

  @JsonSerializable(explicitToJson: true)
  const factory RailJourneyEndpoint({
    required String stationMapId,
    @JsonKey(fromJson: _mapRectFromJson, toJson: _mapRectToJson)
    required MapRect boardingArea,
    required GridPos trainEntryPos,
    required GridPos stationArrivalPos,
    required List<RailJourneyEndpointDoor> doors,
  }) = _RailJourneyEndpoint;

  factory RailJourneyEndpoint.fromJson(Map<String, dynamic> json) =>
      _$RailJourneyEndpointFromJson(json).validated();

  RailJourneyEndpoint validated() {
    final mapId = _requiredId(stationMapId, 'stationMapId');
    if (boardingArea.pos.x < 0 ||
        boardingArea.pos.y < 0 ||
        boardingArea.size.width <= 0 ||
        boardingArea.size.height <= 0) {
      throw StateError('A boarding area must be positive and inside the map.');
    }
    if (trainEntryPos.x < 0 ||
        trainEntryPos.y < 0 ||
        stationArrivalPos.x < 0 ||
        stationArrivalPos.y < 0) {
      throw StateError('Journey spawn positions cannot be negative.');
    }
    if (doors.isEmpty) {
      throw StateError('A journey endpoint requires at least one exact door.');
    }
    final normalizedDoors = <RailJourneyEndpointDoor>[];
    final sides = <RailJourneyDoorSide>{};
    final stationPlacedElementIds = <String>{};
    final vehiclePlacedElementIds = <String>{};
    for (final door in doors) {
      final normalizedDoor = door.validated();
      if (!sides.add(normalizedDoor.side)) {
        throw StateError(
          'A journey endpoint cannot bind the same door side twice.',
        );
      }
      if (!stationPlacedElementIds.add(normalizedDoor.stationPlacedElementId)) {
        throw StateError(
          'A journey endpoint cannot reuse a station door instance.',
        );
      }
      if (!vehiclePlacedElementIds.add(normalizedDoor.vehiclePlacedElementId)) {
        throw StateError(
          'A journey endpoint cannot reuse a vehicle door instance.',
        );
      }
      normalizedDoors.add(normalizedDoor);
    }
    return copyWith(
      stationMapId: mapId,
      doors: List.unmodifiable(normalizedDoors),
    );
  }

  RailJourneyEndpointDoor? doorForSide(RailJourneyDoorSide side) {
    for (final door in doors) {
      if (door.side == side) {
        return door;
      }
    }
    return null;
  }
}

@freezed
abstract class RailJourneyDefinition with _$RailJourneyDefinition {
  const RailJourneyDefinition._();

  @JsonSerializable(explicitToJson: true)
  const factory RailJourneyDefinition({
    required String id,
    required String label,
    required RailJourneyEndpoint origin,
    required RailJourneyEndpoint destination,
    required String vehicleMapId,
    required RailJourneyVehicleVariant vehicleVariant,
    required String shellState,
    required RailJourneyFare fare,
    @Default(RailJourneyRequirements()) RailJourneyRequirements requirements,
  }) = _RailJourneyDefinition;

  factory RailJourneyDefinition.fromJson(Map<String, dynamic> json) =>
      _$RailJourneyDefinitionFromJson(json).validated();

  RailJourneyDefinition validated() {
    final normalizedOrigin = origin.validated();
    final normalizedDestination = destination.validated();
    if (normalizedOrigin.stationMapId == normalizedDestination.stationMapId) {
      throw StateError('Journey origin and destination maps must differ.');
    }
    return copyWith(
      id: _requiredId(id, 'RailJourneyDefinition.id'),
      label: _requiredId(label, 'RailJourneyDefinition.label'),
      origin: normalizedOrigin,
      destination: normalizedDestination,
      vehicleMapId: _requiredId(
        vehicleMapId,
        'RailJourneyDefinition.vehicleMapId',
      ),
      shellState: _requiredId(shellState, 'RailJourneyDefinition.shellState'),
      fare: fare.validated(),
      requirements: requirements.validated(),
    );
  }
}

@freezed
abstract class RailJourneyCatalog with _$RailJourneyCatalog {
  const RailJourneyCatalog._();

  @JsonSerializable(explicitToJson: true)
  const factory RailJourneyCatalog({
    @JsonKey(fromJson: _railJourneyIntFromJson)
    @Default(railJourneySchemaVersion)
    int schemaVersion,
    @Default(<RailJourneyDefinition>[]) List<RailJourneyDefinition> journeys,
  }) = _RailJourneyCatalog;

  factory RailJourneyCatalog.fromJson(Map<String, dynamic> json) =>
      _$RailJourneyCatalogFromJson(json).validated();

  RailJourneyCatalog validated() {
    if (schemaVersion != railJourneySchemaVersion) {
      throw StateError(
        'Unsupported RailJourney schema version $schemaVersion.',
      );
    }
    if (journeys.isEmpty) {
      throw StateError('A RailJourney catalog cannot be empty.');
    }
    final ids = <String>{};
    final normalized = <RailJourneyDefinition>[];
    for (final journey in journeys) {
      final validatedJourney = journey.validated();
      if (!ids.add(validatedJourney.id)) {
        throw StateError(
          'RailJourney catalog repeats id "${validatedJourney.id}".',
        );
      }
      normalized.add(validatedJourney);
    }
    return copyWith(journeys: List.unmodifiable(normalized));
  }
}

@freezed
abstract class RailJourneyOperationBinding with _$RailJourneyOperationBinding {
  const RailJourneyOperationBinding._();

  const factory RailJourneyOperationBinding({
    required RailJourneyOperationKind kind,
    required String journeyId,
    required RailJourneyDirection direction,
    String? stationMapId,
    RailJourneyDoorSide? doorSide,
  }) = _RailJourneyOperationBinding;

  factory RailJourneyOperationBinding.fromJson(Map<String, dynamic> json) =>
      _$RailJourneyOperationBindingFromJson(json).validated();

  RailJourneyOperationBinding validated() {
    final normalizedStationMapId = _trimOptional(stationMapId);
    switch (kind) {
      case RailJourneyOperationKind.begin:
        if (normalizedStationMapId == null || doorSide == null) {
          throw StateError(
            'A begin operation requires a station map and door side.',
          );
        }
      case RailJourneyOperationKind.destinationDoorUsed:
        if (normalizedStationMapId != null || doorSide == null) {
          throw StateError(
            'A destination-door operation requires only a door side.',
          );
        }
      case RailJourneyOperationKind.doorsClosed ||
          RailJourneyOperationKind.arrivalReached ||
          RailJourneyOperationKind.acknowledge:
        if (normalizedStationMapId != null || doorSide != null) {
          throw StateError(
            'This rail operation cannot carry station or door payload.',
          );
        }
    }
    return copyWith(
      journeyId: _requiredId(
        journeyId,
        'RailJourneyOperationBinding.journeyId',
      ),
      stationMapId: normalizedStationMapId,
    );
  }
}

@freezed
abstract class RailProgressionOperationBinding
    with _$RailProgressionOperationBinding {
  const RailProgressionOperationBinding._();

  const factory RailProgressionOperationBinding({
    required RailProgressionOperationKind kind,
    required String semanticId,
    @JsonKey(fromJson: _railJourneyIntFromJson) @Default(0) int amount,
  }) = _RailProgressionOperationBinding;

  factory RailProgressionOperationBinding.fromJson(Map<String, dynamic> json) =>
      _$RailProgressionOperationBindingFromJson(json).validated();

  RailProgressionOperationBinding validated() {
    switch (kind) {
      case RailProgressionOperationKind.grantCurrency:
        if (amount <= 0) {
          throw StateError('A rail currency grant requires a positive amount.');
        }
      case RailProgressionOperationKind.grantStamp:
        if (amount != 0) {
          throw StateError('A rail stamp grant cannot carry an amount.');
        }
    }
    return copyWith(
      semanticId: _requiredId(
        semanticId,
        'RailProgressionOperationBinding.semanticId',
      ),
    );
  }
}

@freezed
abstract class RailJourneyProgress with _$RailJourneyProgress {
  const RailJourneyProgress._();

  @JsonSerializable(explicitToJson: true)
  const factory RailJourneyProgress({
    String? activeJourneyId,
    RailJourneyDirection? direction,
    @Default(RailJourneyLifecycle.idleAtOrigin) RailJourneyLifecycle lifecycle,
    @Default(<String>{}) Set<String> unlockedJourneyIds,
    @Default(<String>{}) Set<String> firstUnlockPaidJourneyIds,
    @Default(<String>{}) Set<String> unlockedStationMapIds,
    @Default(<String>{}) Set<String> earnedStampIds,
    @JsonKey(
      fromJson: _currencyBalancesFromJson,
      toJson: _currencyBalancesToJson,
    )
    @Default(<String, int>{})
    Map<String, int> semanticCurrencyBalances,
    @Default(<String, RailJourneyOperationBinding>{})
    Map<String, RailJourneyOperationBinding> appliedOperations,
    @Default(<String, RailProgressionOperationBinding>{})
    Map<String, RailProgressionOperationBinding> appliedProgressionOperations,
  }) = _RailJourneyProgress;

  factory RailJourneyProgress.fromJson(Map<String, dynamic> json) =>
      _$RailJourneyProgressFromJson(json).validated();

  RailJourneyProgress validated() {
    final activeId = _trimOptional(activeJourneyId);
    if ((activeId == null) != (direction == null)) {
      throw StateError(
        'Active journey id and direction must either both exist or both be null.',
      );
    }
    final unlocked = _validatedIds(unlockedJourneyIds, 'unlockedJourneyIds');
    if (lifecycle == RailJourneyLifecycle.idleAtOrigin && activeId != null) {
      throw StateError('An idle journey cannot retain an active journey.');
    }
    if (lifecycle != RailJourneyLifecycle.idleAtOrigin && activeId == null) {
      throw StateError('An active lifecycle requires an active journey.');
    }
    if (activeId != null && !unlocked.contains(activeId)) {
      throw StateError('The active journey must already be unlocked.');
    }
    final paid = _validatedIds(
      firstUnlockPaidJourneyIds,
      'firstUnlockPaidJourneyIds',
    );
    if (!unlocked.containsAll(paid)) {
      throw StateError('Paid journey ids must also be unlocked.');
    }
    final unlockedStations = _validatedIds(
      unlockedStationMapIds,
      'unlockedStationMapIds',
    );
    final earnedStamps = _validatedIds(earnedStampIds, 'earnedStampIds');
    final operations = _validatedOperationBindings(appliedOperations);
    for (final binding in operations.values) {
      if (!unlocked.contains(binding.journeyId)) {
        throw StateError(
          'Applied operation journey ids must already be unlocked.',
        );
      }
      if (binding.stationMapId != null &&
          !unlockedStations.contains(binding.stationMapId)) {
        throw StateError(
          'Applied operation station map ids must already be unlocked.',
        );
      }
    }
    return copyWith(
      activeJourneyId: activeId,
      unlockedJourneyIds: unlocked,
      firstUnlockPaidJourneyIds: paid,
      unlockedStationMapIds: unlockedStations,
      earnedStampIds: earnedStamps,
      semanticCurrencyBalances: _validatedCurrencyBalances(
        semanticCurrencyBalances,
      ),
      appliedOperations: operations,
      appliedProgressionOperations: _validatedProgressionOperationBindings(
        appliedProgressionOperations,
      ),
    );
  }
}

int _railJourneyIntFromJson(Object? value) {
  if (value is! int) {
    throw FormatException(
      'RailJourney numeric values must be integers.',
      value,
    );
  }
  return value;
}

Map<String, int> _currencyBalancesFromJson(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw FormatException(
      'semanticCurrencyBalances must be a JSON object.',
      value,
    );
  }
  return value.map(
    (key, amount) => MapEntry(key, _railJourneyIntFromJson(amount)),
  );
}

Map<String, int> _currencyBalancesToJson(Map<String, int> value) => value;

MapRect _mapRectFromJson(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('boardingArea must be a JSON object.', value);
  }
  return MapRect.fromJson(value);
}

Map<String, dynamic> _mapRectToJson(MapRect value) => <String, dynamic>{
  'pos': value.pos.toJson(),
  'size': value.size.toJson(),
};

Set<String> _validatedIds(Iterable<String> values, String field) {
  final normalized = <String>{};
  for (final value in values) {
    final id = _requiredId(value, field);
    if (!normalized.add(id)) {
      throw StateError('$field repeats id "$id".');
    }
  }
  return Set.unmodifiable(normalized);
}

Map<String, int> _validatedCurrencyBalances(Map<String, int> values) {
  final normalized = <String, int>{};
  for (final entry in values.entries) {
    final id = _requiredId(entry.key, 'semanticCurrencyBalances');
    if (entry.value < 0) {
      throw StateError('Currency balance "$id" cannot be negative.');
    }
    if (normalized.containsKey(id)) {
      throw StateError('semanticCurrencyBalances repeats id "$id".');
    }
    normalized[id] = entry.value;
  }
  return Map.unmodifiable(normalized);
}

Map<String, RailJourneyOperationBinding> _validatedOperationBindings(
  Map<String, RailJourneyOperationBinding> values,
) {
  final normalized = <String, RailJourneyOperationBinding>{};
  for (final entry in values.entries) {
    final operationId = _requiredId(entry.key, 'appliedOperations');
    if (normalized.containsKey(operationId)) {
      throw StateError('appliedOperations repeats id "$operationId".');
    }
    normalized[operationId] = entry.value.validated();
  }
  return Map.unmodifiable(normalized);
}

Map<String, RailProgressionOperationBinding>
_validatedProgressionOperationBindings(
  Map<String, RailProgressionOperationBinding> values,
) {
  final normalized = <String, RailProgressionOperationBinding>{};
  for (final entry in values.entries) {
    final operationId = _requiredId(entry.key, 'appliedProgressionOperations');
    if (normalized.containsKey(operationId)) {
      throw StateError(
        'appliedProgressionOperations repeats id "$operationId".',
      );
    }
    normalized[operationId] = entry.value.validated();
  }
  return Map.unmodifiable(normalized);
}

String _requiredId(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw StateError('$field must not be empty.');
  }
  return normalized;
}

String? _trimOptional(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
