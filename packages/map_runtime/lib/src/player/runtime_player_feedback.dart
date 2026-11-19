part 'runtime_overworld_feedback.dart';
part 'runtime_service_feedback.dart';

typedef RuntimePlayerFeedbackLocalizer = String? Function(
  String locale,
  RuntimePlayerFeedback feedback,
  Map<String, Object> arguments,
);

sealed class RuntimePlayerFeedback {
  String get fallbackText;
}

extension RuntimePlayerFeedbackResolution on RuntimePlayerFeedback {
  static final _placeholder = RegExp(r'\{(\w+)\}');

  String resolve(
    RuntimePlayerFeedbackLocalizer? localizer,
    String locale, [
    Map<String, Object> arguments = const {},
  ]) =>
      localizer?.call(locale, this, arguments) ??
      (arguments.isEmpty
          ? fallbackText
          : fallbackText.replaceAllMapped(
              _placeholder,
              (match) => arguments[match[1]]?.toString() ?? match[0]!,
            ));
}

enum RuntimeNavigationFeedback implements RuntimePlayerFeedback {
  saveUnavailablePostGameContinuationRefused(
    'Cette fin n’autorise pas de reprise après la fin du jeu.',
  ),
  saveUnavailableMigrationRequired(
    'Cette sauvegarde doit être migrée avant de pouvoir être chargée.',
  ),
  saveUnavailableIncompatibleVersion(
    'Cette sauvegarde n’est pas compatible avec la version installée.',
  ),
  saveUnavailableCorrupt(
    'Cette sauvegarde est endommagée et n’a pas pu être récupérée depuis '
    'sa copie de secours.',
  ),
  saveUnavailableMissing('Aucune sauvegarde n’existe dans cet emplacement.'),
  saveUnavailableTemporarilyUnavailable(
    'Cette sauvegarde est temporairement indisponible.',
  ),
  saveInProgress('Une sauvegarde est déjà en cours.'),
  favoritesBagChanged('Le sac a changé avant l’arrivée de cette action.'),
  favoritesUnavailable('Les favoris sont indisponibles pour cet objet.'),
  favoritesSaveFailed('Les favoris n’ont pas pu être enregistrés. Réessayez.'),
  playerActionStale(
    'La surface joueur a changé avant l’arrivée de cette action.',
  ),
  regionalMapCloseFirst(
    'Fermez la carte régionale avant de reprendre une action du menu.',
  ),
  playerActionUnavailable('This player action is unavailable.'),
  newGameSlotRequired(
    'Un profil et un emplacement sont requis pour une nouvelle partie.',
  ),
  noCompatibleSave(
    'Aucune sauvegarde compatible n’est disponible pour continuer.',
  ),
  loadSlotRequired(
    'Un profil et un emplacement sont requis pour charger une sauvegarde.',
  ),
  selectedSaveUnavailable(
    'La sauvegarde choisie est indisponible ou incompatible.',
  ),
  finalSaveFailed('La sauvegarde finale n’a pas pu être enregistrée.'),
  partyMembersRequired('Deux membres de l’équipe valides sont requis.'),
  playerCommandUnavailable(
    'Cette commande n’est pas disponible sur cet écran.',
  ),
  playerPreferencesRequired('Des préférences joueur valides sont requises.'),
  playerPreferencesSaveFailed(
    'Les préférences du joueur n’ont pas pu être sauvegardées.',
  ),
  saveWriteFailed('La sauvegarde n’a pas pu être enregistrée.'),
  creditsUnavailable('Aucun générique de fin n’est disponible.'),
  surfaceActionUnavailable(
    'This action is not available on the current surface.',
  ),
  playerResponseStale('La surface joueur a changé avant l’arrivée du retour.'),
  returnToHostFailed('Le joueur n’a pas pu revenir à son hôte.'),
  playerDataRefreshFailed(
    'Les données du joueur n’ont pas pu être actualisées.',
  ),
  sessionCloseFailed('La session de jeu n’a pas pu être fermée proprement.'),
  explorationMapChanged(
    'La carte a changé pendant le chargement. Relancez l’exploration.',
  ),
  newGamePreparationChanged(
    'Le contenu du jeu a changé pendant la préparation. Relancez la création de la partie.',
  ),
  newGameSetupInvalid(
    'La configuration de départ est incomplète ou incohérente. La partie n’a pas été créée.',
  ),
  newGameContentChanged(
    'Le contenu du jeu a changé pendant le chargement. Relancez la création de la partie.',
  ),
  newGameResourceLimit(
    'Les ressources graphiques de cette carte dépassent le budget du Player. Signalez ce code au créateur du jeu.',
  ),
  newGameSaveReadFailed(
    'Impossible de lire les sauvegardes. Vérifiez l’accès au stockage de l’application.',
  ),
  newGamePreloadFailed(
    'Impossible de charger les données ou les ressources de la carte de départ. Réinstallez le jeu si le problème persiste.',
  ),
  newGameSceneFailed(
    'La scène de début du jeu n’a pas pu être exécutée. Signalez le code ci-dessous au créateur du jeu.',
  ),
  newGameSetupFailed(
    'La configuration de départ du jeu n’a pas pu être appliquée. Signalez le code ci-dessous au créateur du jeu.',
  ),
  saveOpenFailed(
    'La sauvegarde sélectionnée n’a pas pu être ouverte en sécurité.',
  ),
  sessionLaunchFailed('La session de jeu n’a pas pu être lancée.'),
  playerDataLoadFailed('Les données du joueur n’ont pas pu être chargées.'),
  sessionFailed('La session joueur a échoué.'),
  explorationSaveUnavailable(
    'L’exploration 3D ne propose pas encore de sauvegarde.',
  ),
  noCompatibleGameSave(
    'Aucune sauvegarde compatible n’est disponible pour ce jeu.',
  ),
  playerMapUnavailable('This game does not provide a player map.'),
  unusableSaveNotSelected('Aucune sauvegarde à réparer n’est sélectionnée.'),
  serviceNotActive('Aucun service contextuel n’est actif.'),
  bagRequiresPause('Le sac n’est disponible que depuis le menu pause.'),
  bagItemCheckpointFailed('L’objet a été utilisé mais la sauvegarde a échoué.'),
  sessionEventStreamFailed('Le canal d’évènements du runtime a échoué.'),
  sessionPrepareTimedOut('La session joueur ne s’est pas préparée à temps.'),
  sessionPrepareFailed('La session joueur n’a pas pu être préparée.'),
  sessionStartTimedOut('La session joueur n’a pas démarré à temps.'),
  sessionStartFailed('La session joueur n’a pas pu démarrer.'),
  sessionSignalInvalid('Le signal de session était invalide.'),
  sessionEndingMismatch(
    'L’évènement de fin ne correspond pas à cette session.',
  ),
  sessionEndingInvalid('L’évènement de fin est arrivé dans un état invalide.'),
  previousSessionCloseFailed(
    'La session précédente ne s’est pas fermée proprement.',
  );

  const RuntimeNavigationFeedback(this.fallbackText);

  @override
  final String fallbackText;
}
