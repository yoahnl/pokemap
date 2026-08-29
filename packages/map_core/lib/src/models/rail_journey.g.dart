// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rail_journey.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RailJourneyEndpointDoor _$RailJourneyEndpointDoorFromJson(
  Map<String, dynamic> json,
) => _RailJourneyEndpointDoor(
  side: $enumDecode(_$RailJourneyDoorSideEnumMap, json['side']),
  stationPlacedElementId: json['stationPlacedElementId'] as String,
  vehiclePlacedElementId: json['vehiclePlacedElementId'] as String,
);

Map<String, dynamic> _$RailJourneyEndpointDoorToJson(
  _RailJourneyEndpointDoor instance,
) => <String, dynamic>{
  'side': _$RailJourneyDoorSideEnumMap[instance.side]!,
  'stationPlacedElementId': instance.stationPlacedElementId,
  'vehiclePlacedElementId': instance.vehiclePlacedElementId,
};

const _$RailJourneyDoorSideEnumMap = {
  RailJourneyDoorSide.west: 'west',
  RailJourneyDoorSide.east: 'east',
};

_RailJourneyFare _$RailJourneyFareFromJson(Map<String, dynamic> json) =>
    _RailJourneyFare(
      policy: $enumDecode(_$RailJourneyFarePolicyEnumMap, json['policy']),
      semanticCurrencyId: json['semanticCurrencyId'] as String?,
      amount: json['amount'] == null
          ? 0
          : _railJourneyIntFromJson(json['amount']),
    );

Map<String, dynamic> _$RailJourneyFareToJson(_RailJourneyFare instance) =>
    <String, dynamic>{
      'policy': _$RailJourneyFarePolicyEnumMap[instance.policy]!,
      'semanticCurrencyId': instance.semanticCurrencyId,
      'amount': instance.amount,
    };

const _$RailJourneyFarePolicyEnumMap = {
  RailJourneyFarePolicy.firstUnlockOnly: 'first_unlock_only',
  RailJourneyFarePolicy.storyFree: 'story_free',
  RailJourneyFarePolicy.epilogueFree: 'epilogue_free',
};

_RailJourneyRequirements _$RailJourneyRequirementsFromJson(
  Map<String, dynamic> json,
) => _RailJourneyRequirements(
  completedStoryStepIds:
      (json['completedStoryStepIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const <String>{},
  requiredFactIds:
      (json['requiredFactIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const <String>{},
  requiredAnyFactIds:
      (json['requiredAnyFactIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const <String>{},
  requiredItemIds:
      (json['requiredItemIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const <String>{},
  requiredStampIds:
      (json['requiredStampIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const <String>{},
);

Map<String, dynamic> _$RailJourneyRequirementsToJson(
  _RailJourneyRequirements instance,
) => <String, dynamic>{
  'completedStoryStepIds': instance.completedStoryStepIds.toList(),
  'requiredFactIds': instance.requiredFactIds.toList(),
  'requiredAnyFactIds': instance.requiredAnyFactIds.toList(),
  'requiredItemIds': instance.requiredItemIds.toList(),
  'requiredStampIds': instance.requiredStampIds.toList(),
};

_RailJourneyEndpoint _$RailJourneyEndpointFromJson(Map<String, dynamic> json) =>
    _RailJourneyEndpoint(
      stationMapId: json['stationMapId'] as String,
      boardingArea: _mapRectFromJson(json['boardingArea']),
      trainEntryPos: GridPos.fromJson(
        json['trainEntryPos'] as Map<String, dynamic>,
      ),
      stationArrivalPos: GridPos.fromJson(
        json['stationArrivalPos'] as Map<String, dynamic>,
      ),
      doors: (json['doors'] as List<dynamic>)
          .map(
            (e) => RailJourneyEndpointDoor.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );

Map<String, dynamic> _$RailJourneyEndpointToJson(
  _RailJourneyEndpoint instance,
) => <String, dynamic>{
  'stationMapId': instance.stationMapId,
  'boardingArea': _mapRectToJson(instance.boardingArea),
  'trainEntryPos': instance.trainEntryPos.toJson(),
  'stationArrivalPos': instance.stationArrivalPos.toJson(),
  'doors': instance.doors.map((e) => e.toJson()).toList(),
};

_RailJourneyDefinition _$RailJourneyDefinitionFromJson(
  Map<String, dynamic> json,
) => _RailJourneyDefinition(
  id: json['id'] as String,
  label: json['label'] as String,
  origin: RailJourneyEndpoint.fromJson(json['origin'] as Map<String, dynamic>),
  destination: RailJourneyEndpoint.fromJson(
    json['destination'] as Map<String, dynamic>,
  ),
  vehicleMapId: json['vehicleMapId'] as String,
  vehicleVariant: $enumDecode(
    _$RailJourneyVehicleVariantEnumMap,
    json['vehicleVariant'],
  ),
  shellState: json['shellState'] as String,
  fare: RailJourneyFare.fromJson(json['fare'] as Map<String, dynamic>),
  requirements: json['requirements'] == null
      ? const RailJourneyRequirements()
      : RailJourneyRequirements.fromJson(
          json['requirements'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$RailJourneyDefinitionToJson(
  _RailJourneyDefinition instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'origin': instance.origin.toJson(),
  'destination': instance.destination.toJson(),
  'vehicleMapId': instance.vehicleMapId,
  'vehicleVariant':
      _$RailJourneyVehicleVariantEnumMap[instance.vehicleVariant]!,
  'shellState': instance.shellState,
  'fare': instance.fare.toJson(),
  'requirements': instance.requirements.toJson(),
};

const _$RailJourneyVehicleVariantEnumMap = {
  RailJourneyVehicleVariant.regular: 'regular',
  RailJourneyVehicleVariant.restoredRailcar: 'restored_railcar',
};

_RailJourneyCatalog _$RailJourneyCatalogFromJson(Map<String, dynamic> json) =>
    _RailJourneyCatalog(
      schemaVersion: json['schemaVersion'] == null
          ? railJourneySchemaVersion
          : _railJourneyIntFromJson(json['schemaVersion']),
      journeys:
          (json['journeys'] as List<dynamic>?)
              ?.map(
                (e) =>
                    RailJourneyDefinition.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const <RailJourneyDefinition>[],
    );

Map<String, dynamic> _$RailJourneyCatalogToJson(_RailJourneyCatalog instance) =>
    <String, dynamic>{
      'schemaVersion': instance.schemaVersion,
      'journeys': instance.journeys.map((e) => e.toJson()).toList(),
    };

_RailJourneyOperationBinding _$RailJourneyOperationBindingFromJson(
  Map<String, dynamic> json,
) => _RailJourneyOperationBinding(
  kind: $enumDecode(_$RailJourneyOperationKindEnumMap, json['kind']),
  journeyId: json['journeyId'] as String,
  direction: $enumDecode(_$RailJourneyDirectionEnumMap, json['direction']),
  stationMapId: json['stationMapId'] as String?,
  doorSide: $enumDecodeNullable(_$RailJourneyDoorSideEnumMap, json['doorSide']),
);

Map<String, dynamic> _$RailJourneyOperationBindingToJson(
  _RailJourneyOperationBinding instance,
) => <String, dynamic>{
  'kind': _$RailJourneyOperationKindEnumMap[instance.kind]!,
  'journeyId': instance.journeyId,
  'direction': _$RailJourneyDirectionEnumMap[instance.direction]!,
  'stationMapId': instance.stationMapId,
  'doorSide': _$RailJourneyDoorSideEnumMap[instance.doorSide],
};

const _$RailJourneyOperationKindEnumMap = {
  RailJourneyOperationKind.begin: 'begin',
  RailJourneyOperationKind.doorsClosed: 'doors_closed',
  RailJourneyOperationKind.arrivalReached: 'arrival_reached',
  RailJourneyOperationKind.destinationDoorUsed: 'destination_door_used',
  RailJourneyOperationKind.acknowledge: 'acknowledge',
};

const _$RailJourneyDirectionEnumMap = {
  RailJourneyDirection.outbound: 'outbound',
  RailJourneyDirection.returnJourney: 'return',
};

_RailProgressionOperationBinding _$RailProgressionOperationBindingFromJson(
  Map<String, dynamic> json,
) => _RailProgressionOperationBinding(
  kind: $enumDecode(_$RailProgressionOperationKindEnumMap, json['kind']),
  semanticId: json['semanticId'] as String,
  amount: json['amount'] == null ? 0 : _railJourneyIntFromJson(json['amount']),
);

Map<String, dynamic> _$RailProgressionOperationBindingToJson(
  _RailProgressionOperationBinding instance,
) => <String, dynamic>{
  'kind': _$RailProgressionOperationKindEnumMap[instance.kind]!,
  'semanticId': instance.semanticId,
  'amount': instance.amount,
};

const _$RailProgressionOperationKindEnumMap = {
  RailProgressionOperationKind.grantCurrency: 'grant_currency',
  RailProgressionOperationKind.grantStamp: 'grant_stamp',
};

_RailJourneyProgress _$RailJourneyProgressFromJson(
  Map<String, dynamic> json,
) => _RailJourneyProgress(
  activeJourneyId: json['activeJourneyId'] as String?,
  direction: $enumDecodeNullable(
    _$RailJourneyDirectionEnumMap,
    json['direction'],
  ),
  lifecycle:
      $enumDecodeNullable(_$RailJourneyLifecycleEnumMap, json['lifecycle']) ??
      RailJourneyLifecycle.idleAtOrigin,
  unlockedJourneyIds:
      (json['unlockedJourneyIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const <String>{},
  firstUnlockPaidJourneyIds:
      (json['firstUnlockPaidJourneyIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const <String>{},
  unlockedStationMapIds:
      (json['unlockedStationMapIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const <String>{},
  earnedStampIds:
      (json['earnedStampIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const <String>{},
  semanticCurrencyBalances: json['semanticCurrencyBalances'] == null
      ? const <String, int>{}
      : _currencyBalancesFromJson(json['semanticCurrencyBalances']),
  appliedOperations:
      (json['appliedOperations'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          RailJourneyOperationBinding.fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const <String, RailJourneyOperationBinding>{},
  appliedProgressionOperations:
      (json['appliedProgressionOperations'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          RailProgressionOperationBinding.fromJson(e as Map<String, dynamic>),
        ),
      ) ??
      const <String, RailProgressionOperationBinding>{},
);

Map<String, dynamic> _$RailJourneyProgressToJson(
  _RailJourneyProgress instance,
) => <String, dynamic>{
  'activeJourneyId': instance.activeJourneyId,
  'direction': _$RailJourneyDirectionEnumMap[instance.direction],
  'lifecycle': _$RailJourneyLifecycleEnumMap[instance.lifecycle]!,
  'unlockedJourneyIds': instance.unlockedJourneyIds.toList(),
  'firstUnlockPaidJourneyIds': instance.firstUnlockPaidJourneyIds.toList(),
  'unlockedStationMapIds': instance.unlockedStationMapIds.toList(),
  'earnedStampIds': instance.earnedStampIds.toList(),
  'semanticCurrencyBalances': _currencyBalancesToJson(
    instance.semanticCurrencyBalances,
  ),
  'appliedOperations': instance.appliedOperations.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
  'appliedProgressionOperations': instance.appliedProgressionOperations.map(
    (k, e) => MapEntry(k, e.toJson()),
  ),
};

const _$RailJourneyLifecycleEnumMap = {
  RailJourneyLifecycle.idleAtOrigin: 'idle_at_origin',
  RailJourneyLifecycle.boarding: 'boarding',
  RailJourneyLifecycle.inTransit: 'in_transit',
  RailJourneyLifecycle.arrived: 'arrived',
  RailJourneyLifecycle.disembarked: 'disembarked',
};
