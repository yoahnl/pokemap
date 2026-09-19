import '../application/project_session.dart';

String projectOpenMessage(ProjectOpenProblem? problem) => switch (problem) {
  ProjectOpenProblem.invalidPath => 'Indiquez un chemin absolu, sans « .. ».',
  ProjectOpenProblem.directoryUnavailable =>
    'Dossier absent ou inaccessible. Vérifiez le chemin ou utilisez Parcourir.',
  ProjectOpenProblem.manifestMissing =>
    'Le fichier project.json est absent à la racine de ce dossier.',
  ProjectOpenProblem.manifestInvalid =>
    'Le manifeste du projet est invalide ou incompatible.',
  ProjectOpenProblem.accessDenied =>
    'Accès refusé. Utilisez Parcourir pour autoriser la lecture du dossier.',
  ProjectOpenProblem.readFailed || null =>
    'Impossible de lire ce projet. Vérifiez les permissions et réessayez.',
};
