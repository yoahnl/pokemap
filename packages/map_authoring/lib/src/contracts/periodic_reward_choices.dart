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

enum PeriodicRewardNodeVariant { item, encounter }

final class PeriodicRewardNodeChoice {
  const PeriodicRewardNodeChoice({
    required this.nodeId,
    required this.label,
    required String this.itemId,
    required int this.quantity,
    required this.reference,
    required this.revision,
  }) : variant = PeriodicRewardNodeVariant.item;

  const PeriodicRewardNodeChoice.encounter({
    required this.nodeId,
    required this.label,
    required this.reference,
    required this.revision,
  })  : variant = PeriodicRewardNodeVariant.encounter,
        itemId = null,
        quantity = null;

  factory PeriodicRewardNodeChoice.fromJson(Map<String, dynamic> json) {
    final nodeId = requireContractString(json['nodeId'], 'nodeId');
    final label = requireContractString(json['label'], 'label');
    final reference = PeriodicRewardReference.fromJson(
        Map<String, dynamic>.from(json['reference'] as Map));
    final revision = requireContractString(json['revision'], 'revision');
    if (json['variant'] == 'encounter') {
      if (json.containsKey('itemId') ||
          json.containsKey('quantity') ||
          json.containsKey('itemLabel')) {
        throw const FormatException(
            'An encounter choice cannot contain item fields.');
      }
      return PeriodicRewardNodeChoice.encounter(
          nodeId: nodeId,
          label: label,
          reference: reference,
          revision: revision);
    }
    if (json.containsKey('variant') && json['variant'] != 'item') {
      throw const FormatException(
          'Unsupported periodic reward choice variant.');
    }
    return PeriodicRewardNodeChoice(
        nodeId: nodeId,
        label: label,
        itemId: requireContractString(json['itemId'], 'itemId'),
        quantity: requirePositiveContractVersion(json['quantity'], 'quantity'),
        reference: reference,
        revision: revision);
  }

  final String nodeId;
  final String label;
  final PeriodicRewardNodeVariant variant;
  final String? itemId;
  String get itemLabel => label;
  final int? quantity;
  final PeriodicRewardReference reference;
  final String revision;

  Map<String, Object?> toJson() => {
        'id': nodeId,
        'resourceKind': 'periodicRewardNode',
        'nodeId': nodeId,
        'label': label,
        if (variant == PeriodicRewardNodeVariant.item) ...{
          'itemId': itemId,
          'itemLabel': itemLabel,
          'quantity': quantity,
        } else
          'variant': 'encounter',
        'reference': reference.toJson(),
        'revision': revision,
      };
}

const periodicRewardConditionChoiceContract = <String, Object?>{
  'kind': 'periodicRewardAvailable',
  'rewardReference': {
    'schemaVersion': 1,
    'required': ['sceneId', 'nodeId', 'rewardId'],
    'rewardId': 'derivedFromSelectedPublishedClaimSource'
  },
  'sourceVariants': ['item', 'encounter'],
  'sourceChoices': ['periodicRewardScene', 'periodicRewardNode'],
  'sourceGraphDependencies': 'notExecutionDependencies',
  'itemLabelSource': 'publishedRewardDefinitionLabel',
  'unresolvedReference': 'refuseBeforePersistence',
  'unavailableCalendar': 'unknownForBothExpectations',
  'effects': 'none',
};
