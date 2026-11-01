import 'package:map_core/map_core.dart';

import 'json_contract_support.dart';

final class PeriodicRewardSceneChoice {
  const PeriodicRewardSceneChoice({
    required this.sceneId,
    required this.label,
    required this.revision,
  });

  factory PeriodicRewardSceneChoice.fromJson(Map<String, dynamic> json) =>
      PeriodicRewardSceneChoice(
        sceneId: requireContractString(json['sceneId'], 'sceneId'),
        label: requireContractString(json['label'], 'label'),
        revision: requireContractString(json['revision'], 'revision'),
      );

  final String sceneId;
  final String label;
  final String revision;

  Map<String, Object?> toJson() => {
        'id': sceneId,
        'resourceKind': 'periodicRewardScene',
        'sceneId': sceneId,
        'label': label,
        'revision': revision,
      };
}

final class PeriodicRewardNodeChoice {
  const PeriodicRewardNodeChoice({
    required this.nodeId,
    required this.label,
    required this.itemId,
    required this.quantity,
    required this.reference,
    required this.revision,
  });

  factory PeriodicRewardNodeChoice.fromJson(Map<String, dynamic> json) =>
      PeriodicRewardNodeChoice(
        nodeId: requireContractString(json['nodeId'], 'nodeId'),
        label: requireContractString(json['label'], 'label'),
        itemId: requireContractString(json['itemId'], 'itemId'),
        quantity: requirePositiveContractVersion(json['quantity'], 'quantity'),
        reference: PeriodicRewardReference.fromJson(
          Map<String, dynamic>.from(json['reference'] as Map),
        ),
        revision: requireContractString(json['revision'], 'revision'),
      );

  final String nodeId;
  final String label;
  final String itemId;
  String get itemLabel => label;
  final int quantity;
  final PeriodicRewardReference reference;
  final String revision;

  Map<String, Object?> toJson() => {
        'id': nodeId,
        'resourceKind': 'periodicRewardNode',
        'nodeId': nodeId,
        'label': label,
        'itemId': itemId,
        'itemLabel': itemLabel,
        'quantity': quantity,
        'reference': reference.toJson(),
        'revision': revision,
      };
}

const periodicRewardConditionChoiceContract = <String, Object?>{
  'kind': 'periodicRewardAvailable',
  'rewardReference': {'schemaVersion': 1, 'required': ['sceneId', 'nodeId', 'rewardId'], 'rewardId': 'derivedFromSelectedPublishedClaimCommand'},
  'sourceChoices': ['periodicRewardScene', 'periodicRewardNode'],
  'sourceGraphDependencies': 'notExecutionDependencies',
  'itemLabelSource': 'publishedRewardDefinitionLabel',
  'unresolvedReference': 'refuseBeforePersistence',
  'unavailableCalendar': 'unknownForBothExpectations',
  'effects': 'none',
};
