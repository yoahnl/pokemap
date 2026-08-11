import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums.dart';
import 'project_item_effect_definition.dart';

part 'project_item_capabilities.freezed.dart';
part 'project_item_capabilities.g.dart';

enum ProjectItemUseContext { overworld, battle }

enum ProjectItemTargetKind {
  @JsonValue('party_member')
  partyMember,
  @JsonValue('party_move')
  partyMove,
  world,
  none,
}

enum ProjectItemConsumptionPolicy {
  @JsonValue('on_applied')
  onApplied,
  never,
}

enum ProjectMoveMachineKind { tm, hm }

@freezed
abstract class ProjectItemUseDefinition with _$ProjectItemUseDefinition {
  const ProjectItemUseDefinition._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectItemUseDefinition({
    required Set<ProjectItemUseContext> contexts,
    required ProjectItemTargetKind target,
    required ProjectItemConsumptionPolicy consumption,
    required ProjectItemEffectDefinition effect,
  }) = _ProjectItemUseDefinition;

  factory ProjectItemUseDefinition.fromJson(Map<String, dynamic> json) =>
      _$ProjectItemUseDefinitionFromJson(json).normalized();

  ProjectItemUseDefinition normalized() {
    if (contexts.isEmpty) {
      throw StateError('ProjectItemUseDefinition contexts must not be empty');
    }
    return copyWith(
      contexts: Set.unmodifiable(contexts),
      effect: effect.normalized(),
    );
  }
}

@freezed
abstract class ProjectCaptureItemDefinition
    with _$ProjectCaptureItemDefinition {
  const ProjectCaptureItemDefinition._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectCaptureItemDefinition({
    required int rateNumerator,
    required int rateDenominator,
    required Set<EncounterKind> allowedEncounterKinds,
  }) = _ProjectCaptureItemDefinition;

  factory ProjectCaptureItemDefinition.fromJson(Map<String, dynamic> json) =>
      _$ProjectCaptureItemDefinitionFromJson(json).normalized();

  ProjectCaptureItemDefinition normalized() {
    if (rateNumerator <= 0 || rateDenominator <= 0) {
      throw StateError(
        'ProjectCaptureItemDefinition ratio must be strictly positive',
      );
    }
    if (allowedEncounterKinds.isEmpty) {
      throw StateError(
        'ProjectCaptureItemDefinition allowedEncounterKinds must not be empty',
      );
    }
    var left = rateNumerator;
    var right = rateDenominator;
    while (right != 0) {
      final remainder = left % right;
      left = right;
      right = remainder;
    }
    return copyWith(
      rateNumerator: rateNumerator ~/ left,
      rateDenominator: rateDenominator ~/ left,
      allowedEncounterKinds: Set.unmodifiable(allowedEncounterKinds),
    );
  }
}

@freezed
abstract class ProjectMoveMachineItemDefinition
    with _$ProjectMoveMachineItemDefinition {
  const ProjectMoveMachineItemDefinition._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectMoveMachineItemDefinition({
    required String moveId,
    required ProjectMoveMachineKind kind,
    required bool consumable,
  }) = _ProjectMoveMachineItemDefinition;

  factory ProjectMoveMachineItemDefinition.fromJson(
    Map<String, dynamic> json,
  ) => _$ProjectMoveMachineItemDefinitionFromJson(json).normalized();

  ProjectMoveMachineItemDefinition normalized() {
    final normalizedMoveId = moveId.trim();
    if (normalizedMoveId.isEmpty) {
      throw StateError(
        'ProjectMoveMachineItemDefinition moveId must not be empty',
      );
    }
    if (kind == ProjectMoveMachineKind.hm && consumable) {
      throw StateError(
        'ProjectMoveMachineItemDefinition HM must not be consumable',
      );
    }
    return copyWith(moveId: normalizedMoveId);
  }
}
