import 'package:map_core/map_core.dart';

/// Summary level used by the Personalization Studio publication gate.
enum PersonalizationReadinessStatus {
  ready,
  attention,
  blocked,
}

enum PersonalizationCorrectionKind {
  openCategory,
  useSafeTheme,
}

/// A normalized publication issue, independent from its future presentation.
final class PersonalizationReadinessIssue {
  const PersonalizationReadinessIssue({
    required this.code,
    required this.category,
    required this.severity,
    required this.path,
    required this.message,
  });

  factory PersonalizationReadinessIssue.fromDiagnostic(
    ProjectPresentationDiagnostic diagnostic,
  ) =>
      PersonalizationReadinessIssue(
        code: diagnostic.code,
        category: diagnostic.category,
        severity: diagnostic.severity,
        path: diagnostic.path,
        message: diagnostic.message,
      );

  final String code;
  final ProjectPresentationCategory category;
  final ProjectPresentationDiagnosticSeverity severity;
  final String path;
  final String message;

  bool get isBlocker => severity == ProjectPresentationDiagnosticSeverity.error;

  String get title => switch (code) {
        'presentationVersionUnsupported' => 'Version non prise en charge',
        'presentationAssetPathUnsafe' => 'Fichier hors du projet',
        'presentationAccentColorInvalid' => 'Couleur d’accent invalide',
        'presentationLayoutUnsupported' => 'Disposition non prise en charge',
        'introPosterRequired' => 'Poster de secours manquant',
        'introContainerUnsupported' => 'Conteneur vidéo non pris en charge',
        'introPosterFormatUnsupported' => 'Format du poster non pris en charge',
        'introCaptionsFormatUnsupported' =>
          'Format des sous-titres non pris en charge',
        'introDurationExceeded' => 'Durée de l’intro non prise en charge',
        'introResolutionExceeded' => 'Résolution de l’intro trop élevée',
        'introBitrateExceeded' => 'Débit de l’intro trop élevé',
        'introSizeExceeded' => 'Vidéo d’intro trop volumineuse',
        'introVideoCodecUnsupported' => 'Codec vidéo non pris en charge',
        'introAudioCodecUnsupported' => 'Codec audio non pris en charge',
        'introReducedMotionBehaviorUnsupported' =>
          'Alternative sans animation invalide',
        'introCaptionsRecommended' => 'Sous-titres recommandés',
        'typographyFallbackRequired' => 'Police de secours manquante',
        'typographyFormatUnsupported' => 'Format de police non pris en charge',
        'typographyFamilyRequired' => 'Famille de police manquante',
        'typographyLicenseRequired' => 'Licence de police manquante',
        'typographyRedistributionRequired' =>
          'Redistribution de la police non confirmée',
        'typographyGlyphCoverageIncomplete' =>
          'Couverture de caractères incomplète',
        'themeColorInvalid' => 'Couleur de thème invalide',
        'themeContrastInsufficient' => 'Contraste insuffisant',
        'presentationAssetMissing' => 'Fichier introuvable',
        'presentationAssetNotRegular' => 'Fichier non autorisé',
        'presentationAssetUnreadable' => 'Fichier illisible',
        'brandingImageCorrupt' => 'Image de branding invalide',
        'titleMusicSignatureInvalid' => 'Musique du titre invalide',
        'introCodecSignatureInvalid' => 'Vidéo d’intro invalide',
        'introAudioSignatureMismatch' => 'Piste audio incohérente',
        'introPosterInvalid' => 'Poster de l’intro invalide',
        'introCaptionsInvalid' => 'Sous-titres invalides',
        'fontSignatureInvalid' => 'Fichier de police invalide',
        'fontLicenseInvalid' => 'Licence de police invalide',
        _ => 'Vérification requise',
      };

  String get explanation => switch (code) {
        'presentationAccentColorInvalid' =>
          'La couleur d’accent doit utiliser une valeur hexadécimale, '
              'par exemple #6750A4.',
        'presentationAssetPathUnsafe' =>
          'Choisissez un fichier situé dans le dossier du projet.',
        'introPosterRequired' =>
          'Ajoutez un poster afin de garantir un affichage de secours.',
        'introCaptionsRecommended' =>
          'Ajoutez des sous-titres WebVTT lorsque l’audio contient une voix '
              'ou une information importante.',
        'typographyLicenseRequired' =>
          'Joignez le texte de licence autorisant la redistribution de cette '
              'police avec le jeu.',
        'typographyRedistributionRequired' =>
          'Confirmez que la licence autorise la redistribution de cette '
              'police avec le jeu.',
        'themeContrastInsufficient' =>
          'Ajustez les couleurs concernées ou appliquez la palette sûre pour '
              'rétablir les contrastes requis.',
        'themeColorInvalid' =>
          'Utilisez une couleur hexadécimale opaque ou appliquez la palette '
              'sûre.',
        'presentationAssetMissing' =>
          'Le fichier référencé est introuvable dans le projet.',
        'presentationAssetNotRegular' =>
          'Choisissez un fichier ordinaire situé dans le projet, sans lien '
              'symbolique.',
        'presentationAssetUnreadable' =>
          'Vérifiez les autorisations de lecture du fichier.',
        'brandingImageCorrupt' =>
          'Réimportez une image PNG, JPEG ou WebP valide.',
        'titleMusicSignatureInvalid' =>
          'Réimportez une piste audio dont le contenu correspond à son format.',
        'introCodecSignatureInvalid' =>
          'Réimportez une vidéo MP4 encodée en H.264.',
        'introAudioSignatureMismatch' =>
          'Réimportez la vidéo afin de mettre à jour les informations de sa '
              'piste audio.',
        'introPosterInvalid' =>
          'Réimportez un poster PNG, JPEG ou WebP valide.',
        'introCaptionsInvalid' =>
          'Réimportez des sous-titres WebVTT encodés en UTF-8.',
        'fontSignatureInvalid' =>
          'Réimportez un fichier de police TTF ou OTF valide.',
        'fontLicenseInvalid' =>
          'Joignez un fichier de licence texte UTF-8 non vide.',
        _ => message,
      };

  PersonalizationCorrectionKind get correctionKind =>
      category == ProjectPresentationCategory.theme &&
              const <String>{
                'themeColorInvalid',
                'themeContrastInsufficient',
              }.contains(code)
          ? PersonalizationCorrectionKind.useSafeTheme
          : PersonalizationCorrectionKind.openCategory;

  String get correctionLabel => switch (correctionKind) {
        PersonalizationCorrectionKind.useSafeTheme =>
          'Appliquer la palette sûre',
        PersonalizationCorrectionKind.openCategory =>
          'Corriger dans ${_categoryLabel(category)}',
      };
}

/// Readiness of one stable Personalization Studio category.
final class PersonalizationCategoryReadiness {
  PersonalizationCategoryReadiness({
    required this.category,
    required this.isConfigured,
    required Iterable<PersonalizationReadinessIssue> issues,
  }) : issues = List<PersonalizationReadinessIssue>.unmodifiable(issues);

  final ProjectPresentationCategory category;
  final bool isConfigured;
  final List<PersonalizationReadinessIssue> issues;

  int get blockerCount => issues.where((issue) => issue.isBlocker).length;

  int get warningCount => issues.length - blockerCount;

  PersonalizationReadinessStatus get status {
    if (blockerCount > 0) return PersonalizationReadinessStatus.blocked;
    if (warningCount > 0) return PersonalizationReadinessStatus.attention;
    return PersonalizationReadinessStatus.ready;
  }
}

/// Pure, deterministic projection used by the Studio readiness dashboard.
final class PersonalizationPublishReadiness {
  PersonalizationPublishReadiness._({
    required this.profile,
    required Iterable<PersonalizationReadinessIssue> issues,
  })  : issues = List<PersonalizationReadinessIssue>.unmodifiable(issues),
        categories = List<PersonalizationCategoryReadiness>.unmodifiable(
          ProjectPresentationCategory.values.map(
            (category) => PersonalizationCategoryReadiness(
              category: category,
              isConfigured: profile.configuredCategories.contains(category),
              issues: issues.where((issue) => issue.category == category),
            ),
          ),
        );

  factory PersonalizationPublishReadiness.fromProfile(
    ProjectPresentationProfile profile,
  ) =>
      PersonalizationPublishReadiness._(
        profile: profile,
        issues: validateProjectPresentationProfile(profile)
            .map(PersonalizationReadinessIssue.fromDiagnostic),
      );

  factory PersonalizationPublishReadiness.fromIssues({
    required ProjectPresentationProfile profile,
    required Iterable<PersonalizationReadinessIssue> issues,
  }) =>
      PersonalizationPublishReadiness._(
        profile: profile,
        issues: issues,
      );

  final ProjectPresentationProfile profile;
  final List<PersonalizationReadinessIssue> issues;
  final List<PersonalizationCategoryReadiness> categories;

  int get blockerCount => issues.where((issue) => issue.isBlocker).length;

  int get warningCount => issues.length - blockerCount;

  bool get isReadyToExport => blockerCount == 0;

  PersonalizationReadinessStatus get status {
    if (blockerCount > 0) return PersonalizationReadinessStatus.blocked;
    if (warningCount > 0) return PersonalizationReadinessStatus.attention;
    return PersonalizationReadinessStatus.ready;
  }

  PersonalizationCategoryReadiness forCategory(
    ProjectPresentationCategory category,
  ) =>
      categories.firstWhere((item) => item.category == category);
}

String _categoryLabel(ProjectPresentationCategory category) =>
    switch (category) {
      ProjectPresentationCategory.branding => 'Branding',
      ProjectPresentationCategory.intro => 'Intro vidéo',
      ProjectPresentationCategory.typography => 'Typographie',
      ProjectPresentationCategory.theme => 'Thème & HUD',
    };
