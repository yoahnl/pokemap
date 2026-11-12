// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get languageMenu => 'Langue';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get languageName => 'Français';

  @override
  String get topBarUndo => 'Annuler la modification';

  @override
  String get topBarRedo => 'Rétablir la modification';

  @override
  String get topBarContent => 'Contenu';

  @override
  String get topBarMapSettings => 'Réglages de carte';

  @override
  String get topBarSave => 'Enregistrer';

  @override
  String get topBarTestMap => 'Tester la carte';

  @override
  String get topBarTestMapLater =>
      'Le test de la carte sera branché à une prochaine étape';

  @override
  String get topBarChangeMap => 'Changer de carte';

  @override
  String get topBarNoMap => 'Aucune carte';

  @override
  String get saveStateSaved => 'Enregistré';

  @override
  String get saveStateUnsaved => 'Non enregistré';

  @override
  String get saveStateSaving => 'Enregistrement…';

  @override
  String get saveStateFailed => 'Échec de l’enregistrement';

  @override
  String get railHome => 'Accueil du projet';

  @override
  String get railMapBuilder => 'Constructeur de carte';

  @override
  String get railRegionalMap => 'Carte régionale';

  @override
  String get railResources => 'Gérer les ressources';

  @override
  String get railStory => 'Histoire';

  @override
  String get railHelp => 'Raccourcis et aide';

  @override
  String get railProjectSettings => 'Réglages du projet';

  @override
  String get homeImportProject => 'Importer un projet';

  @override
  String get homePickerFailed =>
      'Le sélecteur de dossier n’a pas pu s’ouvrir. Réessayez.';

  @override
  String get openProblemInvalidPath => 'Ce chemin de projet n’est pas valide.';

  @override
  String get openProblemPathNotPreserved =>
      'Le Studio ne peut pas conserver l’accès à ce dossier.';

  @override
  String get openProblemDirectoryUnavailable => 'Ce dossier est introuvable.';

  @override
  String get openProblemManifestMissing =>
      'Ce dossier ne contient pas de projet Avelune.';

  @override
  String get openProblemManifestInvalid =>
      'Le fichier du projet est illisible ou incompatible.';

  @override
  String get openProblemAccessDenied =>
      'Le Studio n’a pas l’autorisation d’ouvrir ce dossier.';

  @override
  String get openProblemReadFailed => 'Le projet n’a pas pu être lu.';

  @override
  String notAvailableYet(String label) {
    return '$label — pas encore disponible';
  }

  @override
  String notAvailableInNewStudio(String label) {
    return '$label — pas encore disponible dans le nouveau Studio';
  }
}
