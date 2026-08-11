import 'dart:convert';

import 'package:crypto/crypto.dart';

enum ItemSystemProofLevel {
  schemaL0,
  authoringL1,
  persistenceL2,
  runtimeL3,
  playerUxL4,
  mcpParityL5,
  goldenFlowL6,
}

extension ItemSystemProofLevelWireName on ItemSystemProofLevel {
  String get wireName => switch (this) {
    ItemSystemProofLevel.schemaL0 => 'L0',
    ItemSystemProofLevel.authoringL1 => 'L1',
    ItemSystemProofLevel.persistenceL2 => 'L2',
    ItemSystemProofLevel.runtimeL3 => 'L3',
    ItemSystemProofLevel.playerUxL4 => 'L4',
    ItemSystemProofLevel.mcpParityL5 => 'L5',
    ItemSystemProofLevel.goldenFlowL6 => 'L6',
  };
}

enum ItemSystemCertificationStatus {
  certified,
  partial,
  notWired,
  missing,
  unverified,
  regressed,
  deferred,
  blocked,
}

extension ItemSystemCertificationStatusWireName
    on ItemSystemCertificationStatus {
  String get wireName => switch (this) {
    ItemSystemCertificationStatus.certified => 'CERTIFIED',
    ItemSystemCertificationStatus.partial => 'PARTIAL',
    ItemSystemCertificationStatus.notWired => 'NOT_WIRED',
    ItemSystemCertificationStatus.missing => 'MISSING',
    ItemSystemCertificationStatus.unverified => 'UNVERIFIED',
    ItemSystemCertificationStatus.regressed => 'REGRESSED',
    ItemSystemCertificationStatus.deferred => 'DEFERRED',
    ItemSystemCertificationStatus.blocked => 'BLOCKED',
  };
}

enum ItemSystemTransport { directApi, jsonl, editor, mcp }

extension ItemSystemTransportWireName on ItemSystemTransport {
  String get wireName => switch (this) {
    ItemSystemTransport.directApi => 'direct_api',
    ItemSystemTransport.jsonl => 'jsonl',
    ItemSystemTransport.editor => 'editor',
    ItemSystemTransport.mcp => 'mcp',
  };
}

final class ItemSystemV1CertificationProfile {
  const ItemSystemV1CertificationProfile._();

  static const requiredItemActionIds = <String>{
    'item.clone',
    'item.create',
    'item.delete_apply',
    'item.set_battle_effect',
    'item.set_capture_effect',
    'item.set_held_effect',
    'item.set_overworld_effect',
    'item.set_tm_hm_move',
    'item.update',
  };

  static const requiredGoldenSteps = <String>[
    'new_game',
    'initial_items',
    'pickup',
    'overworld_heal',
    'buy',
    'sell',
    'battle_item',
    'capture_attempt',
    'equip_held_item',
    'learn_move_tm',
    'battle_reward',
    'save_reload',
  ];

  static const requiredGoldenObservations = <String>{
    'new_game_from_project',
    'initial_bag_strict',
    'pickup_scenario_applied',
    'pickup_scenario_idempotent',
    'status_cured_overworld',
    'pp_restored_overworld',
    'hp_healed_overworld',
    'shop_purchase_applied',
    'shop_sale_applied',
    'battle_damage_applied',
    'battle_item_applied',
    'capture_succeeded',
    'held_item_equipped',
    'tm_learned',
    'trainer_reward_applied',
    'party_member_fainted_in_battle',
    'revived_overworld',
    'key_item_gate_preserved',
    'passive_item_preserved',
    'strict_save_wire_written',
    'runtime_save_reloaded',
  };

  static Set<String> requiredCapabilitiesFor(ItemSystemProofLevel level) {
    return Set<String>.unmodifiable(switch (level) {
      ItemSystemProofLevel.schemaL0 => const <String>{
        'catalog_schema',
        'bag_schema',
        'save_schema',
        'legacy_rejection',
      },
      ItemSystemProofLevel.authoringL1 => const <String>{
        'catalog_crud',
        'effect_authoring',
        'usage_readiness',
        'reference_guards',
      },
      ItemSystemProofLevel.persistenceL2 => const <String>{
        'new_game_items',
        'pickup_items',
        'shop_items',
        'reward_items',
        'save_reload',
      },
      ItemSystemProofLevel.runtimeL3 => const <String>{
        'overworld_medicine',
        'battle_medicine',
        'capture',
        'key_item_gate',
        'move_machine',
        'held_item',
        'passive_item',
      },
      ItemSystemProofLevel.playerUxL4 => const <String>{
        'bag_menu',
        'target_picker',
        'shop_controls',
        'capture_controls',
        'move_machine_controls',
        'held_item_controls',
      },
      ItemSystemProofLevel.mcpParityL5 => requiredItemActionIds,
      ItemSystemProofLevel.goldenFlowL6 => requiredGoldenObservations,
    });
  }
}

final class ItemSystemLevelEvidence {
  const ItemSystemLevelEvidence({
    required this.sourceRevision,
    required this.evidenceSha256,
    required this.executedCapabilities,
    this.failedCapabilities = const <String>{},
    this.wired = true,
  });

  final String sourceRevision;
  final String evidenceSha256;
  final Set<String> executedCapabilities;
  final Set<String> failedCapabilities;
  final bool wired;
}

final class ItemSystemTransportEvidence {
  const ItemSystemTransportEvidence({
    required this.sourceRevision,
    required this.evidenceSha256,
    required this.executedTransportsByAction,
    this.failedTransportsByAction = const <String, Set<ItemSystemTransport>>{},
    this.wired = true,
  });

  final String sourceRevision;
  final String evidenceSha256;
  final Map<String, Set<ItemSystemTransport>> executedTransportsByAction;
  final Map<String, Set<ItemSystemTransport>> failedTransportsByAction;
  final bool wired;
}

final class ItemSystemGoldenFlowReceipt {
  ItemSystemGoldenFlowReceipt._({
    required this.sourceRevision,
    required this.fixtureSha256,
    required this.finalStateSha256,
    required this.steps,
    required this.observations,
    required Map<String, Object?> canonicalJson,
  }) : _canonicalJson = Map<String, Object?>.unmodifiable(canonicalJson);

  factory ItemSystemGoldenFlowReceipt.fromJson(Map<String, Object?> json) {
    _requireExactKeys(json, const <String>{
      'schemaVersion',
      'projectId',
      'sourceRevision',
      'rngSeed',
      'fixtureSha256',
      'finalStateSha256',
      'steps',
      'observations',
      'finalBagQuantities',
      'finalMoney',
      'finalPartySpeciesIds',
      'finalHeldItemIds',
      'finalKnownMoveIds',
      'completedStepIds',
      'storyFlagIds',
    }, 'Golden flow receipt');
    if (json['schemaVersion'] != 1 ||
        json['projectId'] != 'golden_item_system' ||
        json['rngSeed'] is! int ||
        json['finalMoney'] is! int) {
      throw const FormatException('Golden flow receipt identity is invalid.');
    }
    final sourceRevision = _requiredRevision(json['sourceRevision']);
    final fixtureSha256 = _requiredSha(json['fixtureSha256'], 'fixtureSha256');
    final finalStateSha256 = _requiredSha(
      json['finalStateSha256'],
      'finalStateSha256',
    );
    final steps = _requiredStringList(json['steps'], 'steps');
    if (!_sameOrderedStrings(
      steps,
      ItemSystemV1CertificationProfile.requiredGoldenSteps,
    )) {
      throw const FormatException('Golden flow receipt steps are incomplete.');
    }
    final observations = _requiredStringList(
      json['observations'],
      'observations',
    );
    if (!observations.toSet().containsAll(
      ItemSystemV1CertificationProfile.requiredGoldenObservations,
    )) {
      throw const FormatException(
        'Golden flow receipt observations are incomplete.',
      );
    }
    _validateGoldenFinalState(json);
    final canonicalJson = _canonicalJsonMap(json);
    return ItemSystemGoldenFlowReceipt._(
      sourceRevision: sourceRevision,
      fixtureSha256: fixtureSha256,
      finalStateSha256: finalStateSha256,
      steps: List<String>.unmodifiable(steps),
      observations: List<String>.unmodifiable(observations),
      canonicalJson: canonicalJson,
    );
  }

  final String sourceRevision;
  final String fixtureSha256;
  final String finalStateSha256;
  final List<String> steps;
  final List<String> observations;
  final Map<String, Object?> _canonicalJson;

  String get receiptSha256 =>
      sha256.convert(utf8.encode(jsonEncode(_canonicalJson))).toString();

  Map<String, Object?> toJson() => Map<String, Object?>.from(_canonicalJson);
}

final class ItemSystemCertificationRequest {
  const ItemSystemCertificationRequest({
    required this.sourceRevision,
    this.levelEvidence =
        const <ItemSystemProofLevel, ItemSystemLevelEvidence>{},
    this.transportEvidence,
    this.goldenFlowReceipt,
    this.blockedLevels = const <ItemSystemProofLevel>{},
    this.deferredLevels = const <ItemSystemProofLevel>{},
  });

  final String sourceRevision;
  final Map<ItemSystemProofLevel, ItemSystemLevelEvidence> levelEvidence;
  final ItemSystemTransportEvidence? transportEvidence;
  final ItemSystemGoldenFlowReceipt? goldenFlowReceipt;
  final Set<ItemSystemProofLevel> blockedLevels;
  final Set<ItemSystemProofLevel> deferredLevels;
}

final class ItemSystemCertificationLevelResult {
  const ItemSystemCertificationLevelResult({
    required this.level,
    required this.status,
    this.missingEvidenceIds = const <String>[],
  });

  final ItemSystemProofLevel level;
  final ItemSystemCertificationStatus status;
  final List<String> missingEvidenceIds;

  Map<String, Object> toJson() => <String, Object>{
    'level': level.wireName,
    'status': status.wireName,
    'missingEvidenceIds': missingEvidenceIds,
  };
}

final class ItemSystemCertificationResult {
  ItemSystemCertificationResult({
    required this.sourceRevision,
    required this.levelResults,
    required this.overallStatus,
    required this.goldenFlowReceiptSha256,
  });

  final String sourceRevision;
  final List<ItemSystemCertificationLevelResult> levelResults;
  final ItemSystemCertificationStatus overallStatus;
  final String? goldenFlowReceiptSha256;

  ItemSystemCertificationStatus statusFor(ItemSystemProofLevel level) {
    return levelResults.singleWhere((result) => result.level == level).status;
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 1,
    'domain': 'item_system_v1',
    'sourceRevision': sourceRevision,
    'overallStatus': overallStatus.wireName,
    'goldenFlowReceiptSha256': goldenFlowReceiptSha256,
    'levels': levelResults
        .map((result) => result.toJson())
        .toList(growable: false),
  };
}

final class ItemSystemCertificationEvaluator {
  const ItemSystemCertificationEvaluator();

  ItemSystemCertificationResult evaluate(ItemSystemCertificationRequest input) {
    final sourceRevision = _requiredRevision(input.sourceRevision);
    final levelResults = <ItemSystemCertificationLevelResult>[
      for (final level in ItemSystemProofLevel.values)
        _evaluateLevel(level, input, sourceRevision),
    ];
    return ItemSystemCertificationResult(
      sourceRevision: sourceRevision,
      levelResults: List<ItemSystemCertificationLevelResult>.unmodifiable(
        levelResults,
      ),
      overallStatus: _overallStatus(levelResults),
      goldenFlowReceiptSha256: input.goldenFlowReceipt?.receiptSha256,
    );
  }

  ItemSystemCertificationLevelResult _evaluateLevel(
    ItemSystemProofLevel level,
    ItemSystemCertificationRequest input,
    String sourceRevision,
  ) {
    if (input.blockedLevels.contains(level)) {
      return ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.blocked,
      );
    }
    if (input.deferredLevels.contains(level)) {
      return ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.deferred,
      );
    }
    return switch (level) {
      ItemSystemProofLevel.mcpParityL5 => _evaluateTransports(
        input.transportEvidence,
        sourceRevision,
      ),
      ItemSystemProofLevel.goldenFlowL6 => _evaluateGoldenFlow(
        input.goldenFlowReceipt,
        sourceRevision,
      ),
      _ => _evaluateCapabilityEvidence(
        level,
        input.levelEvidence[level],
        sourceRevision,
      ),
    };
  }

  ItemSystemCertificationLevelResult _evaluateCapabilityEvidence(
    ItemSystemProofLevel level,
    ItemSystemLevelEvidence? evidence,
    String sourceRevision,
  ) {
    if (evidence == null) {
      return ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.missing,
      );
    }
    if (!evidence.wired) {
      return ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.notWired,
      );
    }
    if (evidence.sourceRevision != sourceRevision) {
      return ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.regressed,
      );
    }
    if (!_isSha256(evidence.evidenceSha256) ||
        evidence.executedCapabilities.isEmpty) {
      return ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.unverified,
      );
    }
    final required = ItemSystemV1CertificationProfile.requiredCapabilitiesFor(
      level,
    );
    if (evidence.failedCapabilities.any(required.contains)) {
      return ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.regressed,
      );
    }
    final missing = required.difference(evidence.executedCapabilities).toList()
      ..sort();
    return ItemSystemCertificationLevelResult(
      level: level,
      status: missing.isEmpty
          ? ItemSystemCertificationStatus.certified
          : ItemSystemCertificationStatus.partial,
      missingEvidenceIds: List<String>.unmodifiable(missing),
    );
  }

  ItemSystemCertificationLevelResult _evaluateTransports(
    ItemSystemTransportEvidence? evidence,
    String sourceRevision,
  ) {
    const level = ItemSystemProofLevel.mcpParityL5;
    if (evidence == null) {
      return const ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.missing,
      );
    }
    if (!evidence.wired) {
      return const ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.notWired,
      );
    }
    if (evidence.sourceRevision != sourceRevision) {
      return const ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.regressed,
      );
    }
    if (!_isSha256(evidence.evidenceSha256)) {
      return const ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.unverified,
      );
    }
    final missing = <String>[];
    var executedPairCount = 0;
    for (final actionId
        in ItemSystemV1CertificationProfile.requiredItemActionIds) {
      final executed =
          evidence.executedTransportsByAction[actionId] ??
          const <ItemSystemTransport>{};
      final failed =
          evidence.failedTransportsByAction[actionId] ??
          const <ItemSystemTransport>{};
      for (final transport in ItemSystemTransport.values) {
        final pairId = '$actionId@${transport.wireName}';
        if (failed.contains(transport)) {
          return const ItemSystemCertificationLevelResult(
            level: level,
            status: ItemSystemCertificationStatus.regressed,
          );
        }
        if (executed.contains(transport)) {
          executedPairCount += 1;
        } else {
          missing.add(pairId);
        }
      }
    }
    missing.sort();
    return ItemSystemCertificationLevelResult(
      level: level,
      status: executedPairCount == 0
          ? ItemSystemCertificationStatus.unverified
          : missing.isEmpty
          ? ItemSystemCertificationStatus.certified
          : ItemSystemCertificationStatus.partial,
      missingEvidenceIds: List<String>.unmodifiable(missing),
    );
  }

  ItemSystemCertificationLevelResult _evaluateGoldenFlow(
    ItemSystemGoldenFlowReceipt? receipt,
    String sourceRevision,
  ) {
    const level = ItemSystemProofLevel.goldenFlowL6;
    if (receipt == null) {
      return const ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.missing,
      );
    }
    if (receipt.sourceRevision != sourceRevision) {
      return const ItemSystemCertificationLevelResult(
        level: level,
        status: ItemSystemCertificationStatus.regressed,
      );
    }
    return const ItemSystemCertificationLevelResult(
      level: level,
      status: ItemSystemCertificationStatus.certified,
    );
  }
}

ItemSystemCertificationStatus _overallStatus(
  List<ItemSystemCertificationLevelResult> results,
) {
  final statuses = results.map((result) => result.status).toSet();
  if (statuses.length == 1 &&
      statuses.single == ItemSystemCertificationStatus.certified) {
    return ItemSystemCertificationStatus.certified;
  }
  for (final status in const <ItemSystemCertificationStatus>[
    ItemSystemCertificationStatus.regressed,
    ItemSystemCertificationStatus.blocked,
    ItemSystemCertificationStatus.notWired,
    ItemSystemCertificationStatus.missing,
  ]) {
    if (statuses.contains(status)) return status;
  }
  if (statuses.contains(ItemSystemCertificationStatus.partial) ||
      statuses.contains(ItemSystemCertificationStatus.unverified)) {
    return ItemSystemCertificationStatus.partial;
  }
  return ItemSystemCertificationStatus.deferred;
}

void _validateGoldenFinalState(Map<String, Object?> json) {
  final bag = json['finalBagQuantities'];
  final party = _requiredStringList(
    json['finalPartySpeciesIds'],
    'finalPartySpeciesIds',
  );
  final held = _requiredStringList(
    json['finalHeldItemIds'],
    'finalHeldItemIds',
  );
  final completed = _requiredStringList(
    json['completedStepIds'],
    'completedStepIds',
  );
  final flags = _requiredStringList(json['storyFlagIds'], 'storyFlagIds');
  final moves = json['finalKnownMoveIds'];
  final canonicalBag = bag is Map
      ? <String, int>{
          for (final entry in bag.entries)
            if (entry.key is String && entry.value is int)
              entry.key as String: entry.value as int,
        }
      : const <String, int>{};
  if (json['finalMoney'] != 1090 ||
      bag is! Map ||
      canonicalBag.length != bag.length ||
      !_sameIntMap(canonicalBag, const <String, int>{
        'ether': 1,
        'lab-key': 1,
        'lucky-charm': 1,
        'poke-ball': 2,
      }) ||
      !_sameOrderedStrings(party, const <String>['sproutle', 'sparkitten']) ||
      !_sameOrderedStrings(held, const <String>['leftovers', '']) ||
      moves is! List ||
      moves.length != 2 ||
      !_requiredStringList(
        moves.first,
        'finalKnownMoveIds[0]',
      ).contains('protect') ||
      !completed.contains('golden_item.pickup') ||
      !flags.contains('golden_item.pickup_collected')) {
    throw const FormatException('Golden flow final state is invalid.');
  }
}

Map<String, Object?> _canonicalJsonMap(Map<String, Object?> json) {
  return Map<String, Object?>.from(
    _canonicalJson(json) as Map<String, Object?>,
  );
}

Object? _canonicalJson(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return <String, Object?>{
      for (final key in keys) key: _canonicalJson(value[key]),
    };
  }
  if (value is List) return value.map(_canonicalJson).toList(growable: false);
  return value;
}

List<String> _requiredStringList(Object? value, String field) {
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('$field must be a string list.');
  }
  return value.cast<String>().toList(growable: false);
}

String _requiredRevision(Object? value) {
  if (value is! String || !RegExp(r'^[0-9a-f]{40,64}$').hasMatch(value)) {
    throw const FormatException('Source revision must be a Git object id.');
  }
  return value;
}

String _requiredSha(Object? value, String field) {
  if (value is! String || !_isSha256(value)) {
    throw FormatException('$field must be a SHA-256 digest.');
  }
  return value;
}

bool _isSha256(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

bool _sameOrderedStrings(List<String> left, List<String> right) =>
    left.length == right.length &&
    List<bool>.generate(
      left.length,
      (index) => left[index] == right[index],
    ).every((same) => same);

bool _sameIntMap(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  return left.entries.every((entry) => right[entry.key] == entry.value);
}

void _requireExactKeys(
  Map<String, Object?> json,
  Set<String> expected,
  String owner,
) {
  if (json.keys.toSet().length != expected.length ||
      !json.keys.toSet().containsAll(expected)) {
    throw FormatException('$owner keys are invalid.');
  }
}
