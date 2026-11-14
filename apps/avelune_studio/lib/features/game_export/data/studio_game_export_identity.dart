part of 'studio_game_export_controller.dart';

StudioGameExportMetadata? _metadataOf(GamePackageExportProfile? profile) =>
    profile == null
    ? null
    : StudioGameExportMetadata(
        gameId: profile.gameId,
        title: profile.title,
        version: profile.gameVersion,
        author: profile.authorName,
        locale: profile.defaultLocale,
        locales: profile.supportedLocales.join(', '),
      );

GamePackageExportProfile _profileFrom(
  GamePackageExportProfile? base,
  StudioGameExportMetadata metadata,
) {
  final locales = metadata.locales
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  return base == null
      ? GamePackageExportProfile(
          gameId: metadata.gameId.trim(),
          gameVersion: metadata.version.trim(),
          title: metadata.title.trim(),
          authorName: metadata.author.trim(),
          defaultLocale: metadata.locale.trim(),
          supportedLocales: locales,
        )
      : base.copyWith(
          gameId: metadata.gameId.trim(),
          gameVersion: metadata.version.trim(),
          title: metadata.title.trim(),
          authorName: metadata.author.trim(),
          defaultLocale: metadata.locale.trim(),
          supportedLocales: locales,
        );
}

StudioGameIdentityProblem studioGameIdentityProblem(
  String code,
  StudioGameExportMetadata metadata,
) {
  final locales = metadata.locales
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toSet();
  return switch (code) {
    'invalidGameId' => const StudioGameIdentityProblem(
      StudioGameIdentityField.gameId,
      'Identifiant technique invalide : utilisez par exemple '
      'games.studio.auteur.jeu.',
    ),
    'invalidGameVersion' => const StudioGameIdentityProblem(
      StudioGameIdentityField.version,
      'Version du contenu invalide : utilisez le format 1.0.0.',
    ),
    'invalidTitle' => const StudioGameIdentityProblem(
      StudioGameIdentityField.title,
      'Le titre doit contenir de 1 à 120 caractères.',
    ),
    'invalidAuthor' => const StudioGameIdentityProblem(
      StudioGameIdentityField.author,
      'Indiquez un auteur ou une équipe, en 120 caractères au plus.',
    ),
    'invalidLocales' when !locales.contains(metadata.locale.trim()) =>
      const StudioGameIdentityProblem(
        StudioGameIdentityField.locale,
        'La langue principale doit figurer parmi les langues disponibles.',
      ),
    'invalidLocales' => const StudioGameIdentityProblem(
      StudioGameIdentityField.locales,
      'Langues invalides : des codes uniques comme fr, en ou fr-FR, '
      'séparés par des virgules.',
    ),
    _ => StudioGameIdentityProblem(null, 'Identité refusée : $code.'),
  };
}
