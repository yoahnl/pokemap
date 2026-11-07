enum StudioCheckFamily {
  input('Erreur de saisie'),
  resources('Validation des ressources'),
  runtimeCapabilities('Capacités du jeu'),
  launch('Lancement'),
  saveCompatibility('Compatibilité des sauvegardes');

  const StudioCheckFamily(this.label);
  final String label;
}

enum StudioFailureOwner {
  general('Réglages du projet › Général', 'Ouvrir Général'),
  image('Réglages du projet › Image et caméra', 'Ouvrir Image et caméra'),
  timeWeather('Réglages du projet › Temps et météo', 'Ouvrir Temps et météo'),
  exportDestination('Export › Fichier de destination', 'Choisir un fichier'),
  exportMode('Export › Options d’export', 'Choisir Test local'),
  resources('Ressources', 'Ouvrir les ressources'),
  pokemon('Pokémon', 'Ouvrir Pokémon'),
  regionalMap('Carte régionale', 'Ouvrir la carte régionale'),
  story('Histoire', 'Ouvrir Histoire'),
  presentations('Histoire › Présentations', 'Ouvrir les présentations'),
  map('Carte', 'Ouvrir la carte'),
  verification('Vérifications', 'Ouvrir les vérifications');

  const StudioFailureOwner(this.label, this.action);
  final String label;
  final String action;
}

final class StudioFailureDiagnosis {
  const StudioFailureDiagnosis({
    required this.summary,
    required this.detail,
    this.family,
    this.owner,
  });

  final StudioCheckFamily? family;
  final StudioFailureOwner? owner;
  final String summary;
  final String detail;

  bool get determined => family != null;
}

final class StudioLaunchProblem implements Exception {
  const StudioLaunchProblem(this.message, {this.owner});
  final String message;
  final StudioFailureOwner? owner;

  @override
  String toString() => message;
}

StudioFailureDiagnosis diagnoseExportFailure({
  required String code,
  required String summary,
  String? path,
  Iterable<String> readinessCodes = const [],
}) {
  final detail = [code, ?path].join(' · ');
  if (code == 'gameplayReadinessFailed') {
    final owners = {
      for (final reason in readinessCodes) ?_readinessOwner(reason),
    };
    return StudioFailureDiagnosis(
      family: StudioCheckFamily.launch,
      owner: owners.length == 1 ? owners.single : null,
      summary: summary,
      detail: [detail, ...readinessCodes].join(' · '),
    );
  }
  if (code == 'missingProjectFile' || code == 'missingFile') {
    final asset =
        path != null &&
        (path.startsWith('assets/') || path.startsWith('project/assets/'));
    return StudioFailureDiagnosis(
      family: StudioCheckFamily.resources,
      owner: asset ? StudioFailureOwner.resources : null,
      summary: summary,
      detail: detail,
    );
  }
  final known = _exportCodes[code] ?? _exportPrefixes(code);
  return StudioFailureDiagnosis(
    family: known?.$1,
    owner: known?.$2,
    summary: summary,
    detail: detail,
  );
}

StudioFailureDiagnosis diagnoseLaunchFailure(Object failure) =>
    switch (failure) {
      StudioLaunchProblem(:final message, :final owner) =>
        StudioFailureDiagnosis(
          family: StudioCheckFamily.launch,
          owner: owner,
          summary: message,
          detail: message,
        ),
      StateError(:final message)
          when _requiredCapability.firstMatch(message) != null =>
        StudioFailureDiagnosis(
          family: StudioCheckFamily.runtimeCapabilities,
          summary:
              'Ce test n’accorde pas la capacité '
              '${_requiredCapability.firstMatch(message)!.group(1)} que le '
              'projet utilise.',
          detail: message,
        ),
      _ => StudioFailureDiagnosis(
        summary: 'Le test n’a pas pu démarrer.',
        detail: '$failure',
      ),
    };

final _requiredCapability = RegExp(r'^The project requires ([\w.@-]+)\.$');

StudioFailureOwner? _readinessOwner(String code) => switch (code) {
  'exportNewGameDisabled' ||
  'exportNewGameStartMapUnavailable' ||
  'exportNewGameStartSpawnRequired' ||
  'dive.arrival_unsafe' => StudioFailureOwner.map,
  'exportPreSessionSceneUnavailable' ||
  'exportStoryEndUnreachable' => StudioFailureOwner.story,
  'exportPlayablePartyPokemonUnavailable' ||
  'periodicRewardUnknownItem' => StudioFailureOwner.pokemon,
  _ => null,
};

const _input = StudioCheckFamily.input;
const _resources = StudioCheckFamily.resources;
const _runtime = StudioCheckFamily.runtimeCapabilities;
const _launch = StudioCheckFamily.launch;

const _exportCodes = <String, (StudioCheckFamily, StudioFailureOwner?)>{
  'invalidGameId': (_input, StudioFailureOwner.general),
  'invalidGameVersion': (_input, StudioFailureOwner.general),
  'invalidTitle': (_input, StudioFailureOwner.general),
  'invalidAuthor': (_input, StudioFailureOwner.general),
  'invalidLocales': (_input, StudioFailureOwner.general),
  'invalidExportProfile': (_input, null),
  'missingExportProfile': (_input, StudioFailureOwner.general),
  'exportDestinationExists': (_input, StudioFailureOwner.exportDestination),
  'invalidExportDestination': (_input, StudioFailureOwner.exportDestination),
  'exportPathInvalid': (_input, StudioFailureOwner.exportDestination),
  'exportPathOutsideAllowedRoots': (
    _input,
    StudioFailureOwner.exportDestination,
  ),
  'exportPathSymlinkForbidden': (_input, StudioFailureOwner.exportDestination),
  'exportWriteFailed': (_input, StudioFailureOwner.exportDestination),
  'visual_settings.invalid': (_input, StudioFailureOwner.image),
  'atmosphere.invalid': (_input, StudioFailureOwner.map),
  'resource_library.invalid': (_resources, StudioFailureOwner.resources),
  'resource_library.usage_incomplete': (
    _resources,
    StudioFailureOwner.resources,
  ),
  'invalidAssetCatalog': (_resources, StudioFailureOwner.resources),
  'assetBlobIntegrityMismatch': (_resources, StudioFailureOwner.resources),
  'excludedRuntimeReference': (_resources, null),
  'runtimeMediaAliasCollision': (_resources, null),
  'exterior_decoration.invalid': (_resources, StudioFailureOwner.map),
  'exterior_decoration.orphan': (_resources, StudioFailureOwner.map),
  'regional_map.image_invalid': (_resources, StudioFailureOwner.regionalMap),
  'invalidPresentationMediaCatalog': (
    _resources,
    StudioFailureOwner.presentations,
  ),
  'presentationMediaSourceMissing': (
    _resources,
    StudioFailureOwner.presentations,
  ),
  'presentationMediaSourceMetadataMismatch': (
    _resources,
    StudioFailureOwner.presentations,
  ),
  'presentationMediaSourceContentMismatch': (
    _resources,
    StudioFailureOwner.presentations,
  ),
  'invalidIntroCaptions': (_resources, StudioFailureOwner.presentations),
  'invalidIntroVideo': (_resources, StudioFailureOwner.presentations),
  'invalidTitleMusic': (_resources, null),
  'invalidMenuBackground': (_resources, null),
  'invalidBrandingAsset': (_resources, null),
  'invalidTypographyFont': (_resources, null),
  'invalidTypographyLicense': (_resources, null),
  'invalidLegalText': (_resources, null),
  'runtime3d.publication_unsupported': (
    _runtime,
    StudioFailureOwner.exportMode,
  ),
  'runtimeAtlasRepackUnsupported': (_runtime, null),
  'pokemon.capture.contextual_ruleset_required': (
    _runtime,
    StudioFailureOwner.pokemon,
  ),
  'exportNewGameDisabled': (_launch, StudioFailureOwner.map),
  'exportNewGameStartMapUnavailable': (_launch, StudioFailureOwner.map),
  'exportNewGameStartSpawnRequired': (_launch, StudioFailureOwner.map),
  'exportProfileReferenceInvalid': (_launch, StudioFailureOwner.map),
  'exportPreSessionSceneUnavailable': (_launch, StudioFailureOwner.story),
  'exportStoryEndUnreachable': (_launch, StudioFailureOwner.story),
};

(StudioCheckFamily, StudioFailureOwner?)? _exportPrefixes(String code) {
  if (code.startsWith('pokemon.')) {
    return (_resources, StudioFailureOwner.pokemon);
  }
  if (code.startsWith('battle_recipe.') ||
      code.startsWith('gen5_battle_source.')) {
    return (_resources, null);
  }
  return null;
}
