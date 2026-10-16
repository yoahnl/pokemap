import 'package:map_core/map_core.dart';

enum FieldAbilityGateStatus {
  unsupported,
  missingMove,
  locked,
  usable,
}

final class FieldAbilityGateResult {
  const FieldAbilityGateResult._(this.status, {this.partyIndex});

  final FieldAbilityGateStatus status;
  final int? partyIndex;
}

FieldAbilityGateResult evaluateFieldAbilityGate({
  required FieldAbility ability,
  required Set<FieldAbility> supportedAbilities,
  required Set<FieldAbility> unlockedFieldAbilities,
  required PlayerParty party,
}) {
  if (!supportedAbilities.contains(ability)) {
    return const FieldAbilityGateResult._(FieldAbilityGateStatus.unsupported);
  }
  final partyIndex = _usableFieldMovePartyIndex(party, ability);
  if (partyIndex == null) {
    return const FieldAbilityGateResult._(FieldAbilityGateStatus.missingMove);
  }
  if (!unlockedFieldAbilities.contains(ability)) {
    return const FieldAbilityGateResult._(FieldAbilityGateStatus.locked);
  }
  return FieldAbilityGateResult._(
    FieldAbilityGateStatus.usable,
    partyIndex: partyIndex,
  );
}

bool partyHasUsableFieldMove(PlayerParty party, FieldAbility ability) =>
    _usableFieldMovePartyIndex(party, ability) != null;

int? _usableFieldMovePartyIndex(PlayerParty party, FieldAbility ability) {
  final index = party.members.indexWhere((pokemon) =>
      !pokemon.isFainted && pokemon.knownMoveIds.contains(ability.moveId));
  return index < 0 ? null : index;
}
