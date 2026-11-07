import 'package:map_core/map_core_domain.dart';

import '../../verification/application/studio_failure_diagnosis.dart';
import 'project_settings_session_controller.dart';

enum ProjectCheckState { clear, problem, limited, notChecked }

final class ProjectCheckRow {
  const ProjectCheckRow({
    required this.family,
    required this.state,
    required this.summary,
    this.owner,
    this.sections = const [],
  });

  final StudioCheckFamily family;
  final ProjectCheckState state;
  final String summary;
  final StudioFailureOwner? owner;
  final List<ProjectSettingsSection> sections;
}

List<ProjectCheckRow> projectVerificationOverview({
  required Map<ProjectSettingsSection, String> sectionLabels,
  required Set<ProjectSettingsSection> blocked,
  required Set<ProjectSettingsSection> dirty,
  required ProjectNewGameConfig? newGame,
  required Map<String, String> mapNames,
  required bool threeD,
}) {
  String names(Iterable<ProjectSettingsSection> sections) =>
      [for (final section in sections) sectionLabels[section]].join(', ');
  final invalid = [
    for (final section in ProjectSettingsSection.values)
      if (blocked.contains(section)) section,
  ];
  final drafts = [
    for (final section in ProjectSettingsSection.values)
      if (dirty.contains(section) && !blocked.contains(section)) section,
  ];
  return [
    ProjectCheckRow(
      family: StudioCheckFamily.input,
      state: invalid.isNotEmpty
          ? ProjectCheckState.problem
          : drafts.isNotEmpty
          ? ProjectCheckState.limited
          : ProjectCheckState.clear,
      summary: invalid.isNotEmpty
          ? 'Valeurs invalides à corriger : ${names(invalid)}. Ces rubriques '
                'ne peuvent pas être enregistrées.'
          : drafts.isNotEmpty
          ? 'Aucune valeur invalide. Brouillons non enregistrés : '
                '${names(drafts)} ; un test ou un export proposera de les '
                'enregistrer.'
          : 'Aucune valeur invalide ni brouillon dans les rubriques.',
      sections: invalid.isNotEmpty ? invalid : drafts,
    ),
    const ProjectCheckRow(
      family: StudioCheckFamily.resources,
      state: ProjectCheckState.notChecked,
      summary:
          'Non contrôlée depuis cette page : la construction du paquet et le '
          'test du jeu valident les ressources réellement utilisées et '
          'nomment celle qui bloque.',
    ),
    ProjectCheckRow(
      family: StudioCheckFamily.runtimeCapabilities,
      state: threeD ? ProjectCheckState.limited : ProjectCheckState.notChecked,
      summary: threeD
          ? 'Projet 3D : la publication attend la validation complète sur iOS '
                'et Android. Le Test local reste disponible.'
          : 'Contrôlées pendant la construction du paquet, selon le mode '
                'choisi.',
    ),
    _launch(newGame, mapNames),
    const ProjectCheckRow(
      family: StudioCheckFamily.saveCompatibility,
      state: ProjectCheckState.notChecked,
      summary:
          'Non vérifiée par Studio. Un test garde ses sauvegardes en mémoire '
          'et ne touche pas celles des joueurs ; l’identifiant stable du jeu '
          'relie les sauvegardes du Player à ce projet, il ne change pas avec '
          'le titre.',
    ),
  ];
}

ProjectCheckRow _launch(
  ProjectNewGameConfig? newGame,
  Map<String, String> mapNames,
) {
  ProjectCheckRow problem(String summary) => ProjectCheckRow(
    family: StudioCheckFamily.launch,
    state: ProjectCheckState.problem,
    summary: summary,
    owner: StudioFailureOwner.map,
  );
  if (newGame == null) {
    return const ProjectCheckRow(
      family: StudioCheckFamily.launch,
      state: ProjectCheckState.notChecked,
      summary: 'Le départ du joueur se vérifie depuis la carte pour ce projet.',
    );
  }
  final startId = newGame.startMapId.trim();
  if (!newGame.enabled) {
    return problem(
      'La nouvelle partie est désactivée : le jeu complet ne peut pas '
      'démarrer. Tester une carte reste possible.',
    );
  }
  if (startId.isEmpty) {
    return problem('Aucune carte de départ n’est choisie.');
  }
  final name = mapNames[startId];
  if (name == null) {
    return problem(
      'La carte de départ enregistrée est introuvable dans le projet.',
    );
  }
  return ProjectCheckRow(
    family: StudioCheckFamily.launch,
    state: ProjectCheckState.clear,
    summary: 'La nouvelle partie commence sur « $name ».',
    owner: StudioFailureOwner.map,
  );
}
