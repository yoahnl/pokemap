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
  _ => 'L’installation n’a pas pu être terminée.',
};
