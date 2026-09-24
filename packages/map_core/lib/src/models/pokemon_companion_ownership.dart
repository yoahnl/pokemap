enum PokemonCompanionOwnership { owned, ambiguous, foreign }

PokemonCompanionOwnership resolvePokemonCompanionOwnership({
  required String ownerSpeciesId,
  required String reference,
  required String declaredSpeciesId,
  required Set<String> knownSpeciesIds,
  required Set<String> referencingSpeciesIds,
  bool media = false,
  String ownerBaseFormId = '',
  bool ownerIsBaseForm = true,
}) {
  if (!referencingSpeciesIds.contains(ownerSpeciesId)) {
    return PokemonCompanionOwnership.foreign;
  }
  if (declaredSpeciesId == ownerSpeciesId) {
    return PokemonCompanionOwnership.owned;
  }
  if (media &&
      !ownerIsBaseForm &&
      ownerBaseFormId == declaredSpeciesId &&
      knownSpeciesIds.contains(declaredSpeciesId) &&
      referencingSpeciesIds.contains(declaredSpeciesId)) {
    return PokemonCompanionOwnership.owned;
  }
  if (declaredSpeciesId != reference || knownSpeciesIds.contains(reference)) {
    return PokemonCompanionOwnership.foreign;
  }
  return referencingSpeciesIds.length == 1
      ? PokemonCompanionOwnership.owned
      : PokemonCompanionOwnership.ambiguous;
}
