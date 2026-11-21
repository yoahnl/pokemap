import '../domain/entities/game_installation_diagnostic.dart';

String gameInstallationMessage(
  GameInstallationDiagnostic diagnostic,
) => switch (diagnostic.code) {
  GameInstallationErrorCode.releaseConflict =>
    'Une version${diagnostic.gameVersion == null ? '' : ' ${diagnostic.gameVersion}'} de ce jeu est déjà installée, mais ce fichier contient un contenu différent sous le même numéro. Télécharge une version plus récente du jeu. Ton jeu installé et tes sauvegardes sont conservés.',
  GameInstallationErrorCode.cancelled =>
    'L’installation a été annulée sans modifier le jeu actuel.',
  GameInstallationErrorCode.incompatible =>
    'Ce jeu n’est pas compatible avec cette version du Player.',
  GameInstallationErrorCode.insufficientDisk =>
    'L’espace disque est insuffisant pour installer ce jeu.',
  GameInstallationErrorCode.integrityFailed ||
  GameInstallationErrorCode.sourceChanged =>
    'Le package est incomplet ou a été modifié.',
  GameInstallationErrorCode.notAnUpdate =>
    'Ce fichier ne contient pas une version plus récente du jeu installé.',
  GameInstallationErrorCode.alreadyInstalled =>
    'Cette version du jeu est déjà installée.',
  GameInstallationErrorCode.extractionFailed =>
    'Le jeu n’a pas pu être décompressé sur cet appareil. Réessaie l’installation : ton jeu actuel et tes sauvegardes n’ont pas été modifiés.',
  GameInstallationErrorCode.smokeFailed =>
    'Le jeu a été décompressé, mais il n’a pas pu démarrer pendant sa vérification. Réessaie l’installation : ton jeu actuel et tes sauvegardes n’ont pas été modifiés.',
  GameInstallationErrorCode.savePreparationFailed =>
    'Tes sauvegardes n’ont pas pu être préparées pour cette version. Rien n’a été changé : ton jeu actuel et tes sauvegardes sont conservés.',
  GameInstallationErrorCode.unsafePath =>
    'Le dossier des jeux d’Avelune sur cet appareil n’est pas utilisable. Aucun fichier n’a été modifié.',
  GameInstallationErrorCode.storageFailure =>
    'L’enregistrement du jeu sur l’appareil a échoué en fin d’installation. Relance l’installation du même fichier pour réparer le jeu.',
  GameInstallationErrorCode.operationInProgress =>
    'Une autre opération est en cours sur ce jeu. Attends qu’elle se termine, puis réessaie.',
  GameInstallationErrorCode.notInstalled =>
    'Ce jeu ou cette version n’est plus installé sur cet appareil.',
  GameInstallationErrorCode.currentPointerCorrupt ||
  GameInstallationErrorCode.receiptMissing ||
  GameInstallationErrorCode.installationCorrupt =>
    'L’installation de ce jeu est endommagée. Réinstalle-le depuis son fichier pour la réparer.',
  GameInstallationErrorCode.repairIdentityMismatch =>
    'Ce fichier ne correspond pas exactement au jeu à réparer. Utilise le fichier d’origine de cette version.',
  GameInstallationErrorCode.rollbackConfirmationRequired =>
    'Revenir à une version plus ancienne doit être confirmé avant de continuer.',
  GameInstallationErrorCode.rollbackSnapshotUnavailable =>
    'Les sauvegardes de cette ancienne version ne sont plus disponibles : impossible d’y revenir. Ton jeu actuel est conservé.',
  GameInstallationErrorCode.uninstallFallbackRequired =>
    'Choisis la version à garder avant de désinstaller la version en cours.',
};
