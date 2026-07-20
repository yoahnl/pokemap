// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Éditeur de cartes RPG';

  @override
  String get brandName => 'PokeMap';

  @override
  String get narrativeStudio => 'Narrative Studio';

  @override
  String get beta => 'beta';

  @override
  String get back => 'Retour';

  @override
  String get maps => 'Maps';

  @override
  String get overview => 'Aperçu';

  @override
  String get storylines => 'Storylines';

  @override
  String get scenes => 'Scènes';

  @override
  String get events => 'Événements';

  @override
  String get cinematics => 'Cinématiques';

  @override
  String get dialogues => 'Dialogues';

  @override
  String get facts => 'Facts';

  @override
  String get worldRules => 'Règles du monde';

  @override
  String get validator => 'Validateur';

  @override
  String get eventBuilder => 'Event Builder';

  @override
  String get mapEvents => 'Événements par map';

  @override
  String get shellSemantics => 'PokeMap, Narrative Studio';

  @override
  String get validate => 'Valider';

  @override
  String get allChangesSaved => 'Tous les changements enregistrés';

  @override
  String get unsavedChanges => 'Modifications non enregistrées';

  @override
  String get narrativeUnsavedTitle => 'Modifications Cinématiques en attente';

  @override
  String get narrativeUnsavedMessage =>
      'Enregistrez ou abandonnez les modifications locales avant de quitter ce contexte narratif.';

  @override
  String get narrativeStayHere => 'Rester ici';

  @override
  String get narrativeDiscard => 'Abandonner';

  @override
  String get narrativeSave => 'Enregistrer';

  @override
  String get narrativeStatusSaved => 'Enregistré';

  @override
  String get narrativeStatusDirty => 'Modifié';

  @override
  String get narrativeStatusSaving => 'Enregistrement…';

  @override
  String get narrativeStatusFailed => 'Échec';

  @override
  String get narrativeStatusConflicted => 'Conflit';

  @override
  String get narrativeStatusRecovered => 'Récupéré';

  @override
  String get narrativeUndoTooltip => 'Annuler la dernière intention narrative';

  @override
  String get narrativeRedoTooltip => 'Rétablir la dernière intention narrative';

  @override
  String get narrativeSaveTooltip => 'Enregistrer les modifications narratives';

  @override
  String get narrativeAutosaveDisableTooltip =>
      'Désactiver l’enregistrement automatique';

  @override
  String get narrativeAutosaveEnableTooltip =>
      'Activer l’enregistrement automatique';

  @override
  String get narrativeCompareTooltip =>
      'Comparer les versions locale et externe';

  @override
  String get narrativeReloadTooltip => 'Recharger la version externe';

  @override
  String get narrativeKeepLocalTooltip =>
      'Conserver la version locale sur la nouvelle base';

  @override
  String get narrativeDiscardTooltip =>
      'Abandonner les modifications narratives locales';

  @override
  String get narrativeCompareTitle => 'Comparer les versions Cinématiques';

  @override
  String get narrativeCompareSemantics => 'Comparaison des versions narratives';

  @override
  String get narrativeCompareBaseline => 'Base de la session';

  @override
  String get narrativeCompareLocal => 'Version locale récupérable';

  @override
  String get narrativeCompareExternal => 'Version externe sur disque';

  @override
  String get narrativeNoCinematics => 'Aucune cinématique';

  @override
  String narrativeCinematicCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cinématiques',
      one: '1 cinématique',
      zero: 'Aucune cinématique',
    );
    return '$_temp0';
  }
}
