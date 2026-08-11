import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_item_effect_definition.freezed.dart';
part 'project_item_effect_definition.g.dart';

enum ProjectItemAmountMode { flat, full }

enum ProjectItemStatusCureMode { listed, all }

@Freezed(unionKey: 'kind', unionValueCase: FreezedUnionCase.snake)
abstract class ProjectItemEffectDefinition with _$ProjectItemEffectDefinition {
  const ProjectItemEffectDefinition._();

  @JsonSerializable(explicitToJson: true)
  const factory ProjectItemEffectDefinition.healHp({
    required ProjectItemAmountMode mode,
    int? amount,
  }) = ProjectItemHealHpEffectDefinition;

  @JsonSerializable(explicitToJson: true)
  const factory ProjectItemEffectDefinition.cureStatus({
    required ProjectItemStatusCureMode mode,
    @Default(<String>{}) Set<String> statusIds,
  }) = ProjectItemCureStatusEffectDefinition;

  @JsonSerializable(explicitToJson: true)
  const factory ProjectItemEffectDefinition.revive({
    required int rateNumerator,
    required int rateDenominator,
  }) = ProjectItemReviveEffectDefinition;

  @JsonSerializable(explicitToJson: true)
  const factory ProjectItemEffectDefinition.restorePp({
    required ProjectItemAmountMode mode,
    int? amount,
  }) = ProjectItemRestorePpEffectDefinition;

  @JsonSerializable(explicitToJson: true)
  const factory ProjectItemEffectDefinition.repel({required int steps}) =
      ProjectItemRepelEffectDefinition;

  @JsonSerializable(explicitToJson: true)
  const factory ProjectItemEffectDefinition.semanticAction({
    required String actionId,
  }) = ProjectItemSemanticActionEffectDefinition;

  factory ProjectItemEffectDefinition.fromJson(Map<String, dynamic> json) =>
      _$ProjectItemEffectDefinitionFromJson(json).normalized();

  ProjectItemEffectDefinition normalized() {
    return map(
      healHp: (effect) => _normalizeAmountEffect(
        effect,
        mode: effect.mode,
        amount: effect.amount,
      ),
      cureStatus: (effect) {
        final statusIds = effect.statusIds
            .map((statusId) => statusId.trim())
            .where((statusId) => statusId.isNotEmpty)
            .toSet();
        if (effect.mode == ProjectItemStatusCureMode.listed &&
            statusIds.isEmpty) {
          throw StateError(
            'ProjectItemEffectDefinition.cureStatus listed mode requires statusIds',
          );
        }
        if (effect.mode == ProjectItemStatusCureMode.all &&
            statusIds.isNotEmpty) {
          throw StateError(
            'ProjectItemEffectDefinition.cureStatus all mode forbids statusIds',
          );
        }
        return effect.copyWith(statusIds: statusIds);
      },
      revive: (effect) {
        final divisor = _positiveRatioDivisor(
          effect.rateNumerator,
          effect.rateDenominator,
          'ProjectItemEffectDefinition.revive',
        );
        return effect.copyWith(
          rateNumerator: effect.rateNumerator ~/ divisor,
          rateDenominator: effect.rateDenominator ~/ divisor,
        );
      },
      restorePp: (effect) => _normalizeAmountEffect(
        effect,
        mode: effect.mode,
        amount: effect.amount,
      ),
      repel: (effect) {
        if (effect.steps <= 0) {
          throw StateError(
            'ProjectItemEffectDefinition.repel steps must be strictly positive',
          );
        }
        return effect;
      },
      semanticAction: (effect) {
        final actionId = effect.actionId.trim();
        if (actionId.isEmpty) {
          throw StateError(
            'ProjectItemEffectDefinition.semanticAction actionId must not be empty',
          );
        }
        return effect.copyWith(actionId: actionId);
      },
    );
  }

  ProjectItemEffectDefinition requireDeclaredSemanticAction(
    Set<String> declaredActionIds,
  ) {
    final normalizedEffect = normalized();
    if (normalizedEffect is! ProjectItemSemanticActionEffectDefinition) {
      return normalizedEffect;
    }
    final normalizedRegistry = declaredActionIds
        .map((actionId) => actionId.trim())
        .where((actionId) => actionId.isNotEmpty)
        .toSet();
    if (!normalizedRegistry.contains(normalizedEffect.actionId)) {
      throw StateError(
        'Unsupported semantic item action: ${normalizedEffect.actionId}',
      );
    }
    return normalizedEffect;
  }
}

ProjectItemEffectDefinition _normalizeAmountEffect(
  ProjectItemEffectDefinition effect, {
  required ProjectItemAmountMode mode,
  required int? amount,
}) {
  if (mode == ProjectItemAmountMode.flat && (amount == null || amount <= 0)) {
    throw StateError('Flat item effects require a strictly positive amount');
  }
  if (mode == ProjectItemAmountMode.full && amount != null) {
    throw StateError('Full item effects forbid an amount');
  }
  return effect;
}

int _positiveRatioDivisor(int numerator, int denominator, String label) {
  if (numerator <= 0 || denominator <= 0) {
    throw StateError('$label ratio must be strictly positive');
  }
  var left = numerator;
  var right = denominator;
  while (right != 0) {
    final remainder = left % right;
    left = right;
    right = remainder;
  }
  return left;
}
