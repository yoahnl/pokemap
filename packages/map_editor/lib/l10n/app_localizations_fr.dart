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

  @override
  String get migrationCenterSemantics =>
      'Centre de migration legacy Narrative Studio';

  @override
  String get migrationCenterTitle => 'Migration Narrative Studio';

  @override
  String migrationCenterDryRunSummary(
      int schemaVersion, String minimumVersion) {
    return 'Dry-run schema $schemaVersion • projet minimum $minimumVersion';
  }

  @override
  String get migrationCenterClose => 'Fermer';

  @override
  String get migrationCenterRefresh => 'Relancer le dry-run';

  @override
  String get migrationCenterCreateBackup => 'Créer le backup';

  @override
  String get migrationCenterLegacyRemaining => 'legacy restant';

  @override
  String get migrationCenterBlockers => 'blocages';

  @override
  String get migrationCenterLossRisks => 'risques de perte';

  @override
  String get migrationCenterReadersRetirable => 'Readers legacy retirables';

  @override
  String get migrationCenterCompatibilityReadOnly =>
      'Compatibilité legacy conservée en lecture seule';

  @override
  String get migrationCenterCanonicalMessage =>
      'Chaque domaine possède désormais une source canonique.';

  @override
  String get migrationCenterReadOnlyMessage =>
      'Les anciens studios restent visibles pour vérification et rollback. Ils ne doivent plus être une source d’authoring concurrente.';

  @override
  String get migrationCenterStorylineDomain => 'Storylines / GlobalStory';

  @override
  String get migrationCenterEventDomain => 'Events / MapEvent';

  @override
  String get migrationCenterCinematicDomain => 'Cinematics / Cutscene Studio';

  @override
  String migrationCenterDomainSummary(int remaining, int ready) {
    return '$remaining restant(s) • $ready prêt(s)';
  }

  @override
  String get migrationCenterCanonical => 'Canonique';

  @override
  String get migrationCenterLegacyVisible => 'Legacy visible';

  @override
  String migrationCenterBlockerDependencySummary(
      int blockers, int dependencies) {
    return '$blockers blocage(s) • $dependencies dépendance(s)';
  }

  @override
  String get migrationCenterExamine => 'Examiner';

  @override
  String get migrationCenterRollbackHint =>
      'Rollback : le backup précède toute écriture. Une interruption conserve les domaines déjà attestés et permet soit la reprise, soit le retour exact au snapshot initial.';

  @override
  String get commandPaletteBarrier => 'Fermer la palette de commandes';

  @override
  String get commandPaletteSemantics => 'Recherche globale Narrative Studio';

  @override
  String get commandPaletteTitle => 'Aller à…';

  @override
  String get commandPaletteSearchHint =>
      'Rechercher un asset, ID ou diagnostic…';

  @override
  String get commandPaletteSearchSemantics => 'Recherche globale';

  @override
  String get commandPaletteNoResults => 'Aucun résultat';

  @override
  String get commandPaletteNoResultsHint =>
      'Essayez un label, un ID, un tag ou une map.';

  @override
  String sceneGraphInputPortSemantics(String nodeId) {
    return 'Port d’entrée du nœud $nodeId';
  }

  @override
  String sceneGraphOutputPortSemantics(String portLabel, String nodeId) {
    return 'Port de sortie $portLabel du nœud $nodeId';
  }

  @override
  String get commandPaletteKindMap => 'Map';

  @override
  String get commandPaletteKindStoryline => 'Storyline';

  @override
  String get commandPaletteKindChapter => 'Chapitre';

  @override
  String get commandPaletteKindStep => 'Étape';

  @override
  String get commandPaletteKindScene => 'Scène';

  @override
  String get commandPaletteKindEvent => 'Événement';

  @override
  String get commandPaletteKindCinematic => 'Cinématique';

  @override
  String get commandPaletteKindDialogue => 'Dialogue';

  @override
  String get commandPaletteKindFact => 'Fact';

  @override
  String get commandPaletteKindWorldRule => 'World Rule';

  @override
  String get commandPaletteKindMedia => 'Média';

  @override
  String get commandPaletteKindDiagnostic => 'Diagnostic';

  @override
  String get commandPaletteActionNavigation => 'Navigation';

  @override
  String get commandPaletteActionCreate => 'Créer';

  @override
  String get commandPaletteActionValidate => 'Valider';

  @override
  String get commandPaletteActionPreview => 'Aperçu';

  @override
  String get commandPaletteActionSave => 'Enregistrer';

  @override
  String get commandPaletteTooltip => 'Recherche globale (⌘K)';
}
