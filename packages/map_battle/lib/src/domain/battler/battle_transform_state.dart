/// Transform and illusion placeholders for the PSDK lane.
///
/// FIGHT-02 only stores the battle-visible state required by Pokemon SDK move
/// families. Transform, Illusion and form-copy behavior remain future explicit
/// move/effect work; keeping this as a passive value object prevents the engine
/// from pretending that those mechanics are already implemented.
final class PsdkBattleTransformState {
  const PsdkBattleTransformState({
    this.transformedFromSpeciesId,
    this.illusionSpeciesId,
    this.illusionDisplayName,
  });

  final String? transformedFromSpeciesId;
  final String? illusionSpeciesId;
  final String? illusionDisplayName;

  bool get isTransformed => transformedFromSpeciesId != null;
  bool get hasIllusion => illusionSpeciesId != null;
}
