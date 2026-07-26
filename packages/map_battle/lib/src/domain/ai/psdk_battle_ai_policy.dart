import 'psdk_battle_ai.dart';

/// Whether a trainer profile may consider a voluntary tactical switch.
enum PsdkBattleAiSwitchPolicy {
  never,
  tactical,
}

/// Whether a trainer profile may consume explicitly authored battle items.
enum PsdkBattleAiItemPolicy {
  disabled,
  authoredOptionsOnly,
}

/// Deterministic PSDK AI configuration selected from product difficulty.
///
/// This policy deliberately does not manufacture trainer items. Even a high
/// difficulty trainer receives item actions only when a caller provides an
/// explicit authored option list.
final class PsdkBattleAiPolicy {
  const PsdkBattleAiPolicy({
    required this.profileId,
    required this.productDifficulty,
    required this.aiLevel,
    required this.switchPolicy,
    required this.itemPolicy,
  });

  final String profileId;
  final int? productDifficulty;
  final int aiLevel;
  final PsdkBattleAiSwitchPolicy switchPolicy;
  final PsdkBattleAiItemPolicy itemPolicy;

  PsdkBattleAi createAi({
    List<PsdkBattleAiItemOption> itemOptions =
        const <PsdkBattleAiItemOption>[],
  }) {
    final authoredItemsEnabled =
        itemPolicy == PsdkBattleAiItemPolicy.authoredOptionsOnly &&
            itemOptions.isNotEmpty;
    return PsdkBattleAi(
      level: aiLevel,
      canSwitch: switchPolicy == PsdkBattleAiSwitchPolicy.tactical,
      canUseItem: authoredItemsEnabled,
      // A trainer battle never exposes flee as an opponent policy.
      canFlee: false,
      itemOptions: authoredItemsEnabled
          ? List<PsdkBattleAiItemOption>.unmodifiable(itemOptions)
          : const <PsdkBattleAiItemOption>[],
    );
  }
}

/// Maps the authored `1..10` value to three stable product profiles.
///
/// `null` preserves the historical basic trainer behavior. Values outside the
/// validated product range are clamped defensively because this pure engine
/// boundary may also be called by tests or imported legacy data.
PsdkBattleAiPolicy psdkBattleAiPolicyForDifficulty(int? difficulty) {
  final normalized = difficulty?.clamp(1, 10).toInt();
  if (normalized == null || normalized <= 3) {
    return PsdkBattleAiPolicy(
      profileId: 'basic',
      productDifficulty: normalized,
      aiLevel: 1,
      switchPolicy: PsdkBattleAiSwitchPolicy.never,
      itemPolicy: PsdkBattleAiItemPolicy.disabled,
    );
  }
  if (normalized <= 7) {
    return PsdkBattleAiPolicy(
      profileId: 'tactical',
      productDifficulty: normalized,
      aiLevel: 2,
      switchPolicy: PsdkBattleAiSwitchPolicy.tactical,
      itemPolicy: PsdkBattleAiItemPolicy.authoredOptionsOnly,
    );
  }
  return PsdkBattleAiPolicy(
    profileId: 'advanced',
    productDifficulty: normalized,
    aiLevel: 3,
    switchPolicy: PsdkBattleAiSwitchPolicy.tactical,
    itemPolicy: PsdkBattleAiItemPolicy.authoredOptionsOnly,
  );
}
