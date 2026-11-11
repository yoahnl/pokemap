import '../../project_audio/application/project_audio_controller.dart';
import '../../project_cs/application/project_cs_controller.dart';
import '../../project_surf/application/project_surf_controller.dart';
import '../../project_visuals/application/project_visuals_controller.dart';
import 'project_identity_controller.dart';
import 'project_settings_session_controller.dart';

typedef ProjectSettingsRecoveryTarget = ({
  String id,
  String label,
  ProjectSettingsDraft draft,
  bool busy,
  String consequence,
  void Function() recover,
});

typedef ProjectSettingsRecoveryMapVisuals = ({
  String mapId,
  String name,
  ProjectVisualsController owner,
});

const projectSettingsRecoveryChanged =
    'Les brouillons ont changé pendant la confirmation. Vérifiez la rubrique puis recommencez.';

bool projectSettingsRecoveryPending(ProjectSettingsRecoveryTarget target) =>
    target.draft.dirty || target.draft.blocked || target.draft.error != null;

bool projectSettingsRecoveryAvailable(ProjectSettingsRecoveryTarget target) =>
    target.draft.ready &&
    !target.busy &&
    !target.draft.saving &&
    (target.draft is! VisualSettingsDraft ||
        target.draft.dirty ||
        target.draft.blocked);

ProjectSettingsRecoveryTarget? projectSettingsRecoveryConfirmed(
  List<ProjectSettingsRecoveryTarget> targets,
  String id, {
  required bool changed,
}) {
  if (changed) return null;
  final current = targets.where((value) => value.id == id).firstOrNull;
  return current == null || !projectSettingsRecoveryAvailable(current)
      ? null
      : current;
}

String projectSettingsRecoveryOutcome(ProjectSettingsRecoveryTarget target) =>
    projectSettingsRecoveryPending(target)
    ? 'La rubrique « ${target.label} » reste bloquée. Son propriétaire doit encore résoudre le problème signalé.'
    : 'Le brouillon de « ${target.label} » a été abandonné. Les autres rubriques sont conservées.';

List<ProjectSettingsRecoveryTarget> projectSettingsRecoveryTargets({
  ProjectIdentityController? identity,
  ProjectSurfController? surf,
  ProjectCsController? cs,
  ProjectAudioController? audio,
  ProjectVisualsController? projectVisuals,
  Iterable<ProjectSettingsRecoveryMapVisuals> maps = const [],
}) {
  const loaded = 'La dernière version chargée de cette rubrique sera reprise.';
  final targets = <ProjectSettingsRecoveryTarget>[];
  if (identity != null) {
    final external = identity.conflict;
    final metadata = external?.metadata;
    final draft = identity.draft;
    targets.add((
      id: 'project-general',
      label: 'Général · Tout le projet',
      draft: IdentitySettingsDraft(identity),
      busy: identity.loading || identity.saving,
      consequence: external == null
          ? loaded
          : 'La version enregistrée détectée sera reprise pour Général.\n'
                'Titre : brouillon « ${draft.title} » ; enregistré « ${metadata?.title ?? identity.proposed.title} ».\n'
                'Auteur : brouillon « ${draft.author} » ; enregistré « ${metadata?.author ?? identity.proposed.author} ».\n'
                'Version : brouillon « ${draft.version} » ; enregistrée « ${metadata?.version ?? identity.proposed.version} ».\n'
                'Langue : brouillon « ${draft.locale} » ; enregistrée « ${metadata?.locale ?? identity.proposed.locale} ».\n'
                'Langues disponibles : brouillon « ${draft.locales} » ; enregistrées « ${metadata?.locales ?? identity.proposed.locales} ».',
      recover: external == null ? identity.discard : identity.reloadExternal,
    ));
  }
  if (surf != null || cs != null) {
    final draft = FieldAbilitySettingsDraft(cs, surf);
    targets.add((
      id: 'project-fieldAbilities',
      label: 'CS et Surf · Tout le projet',
      draft: draft,
      busy:
          surf?.loading == true ||
          surf?.saving == true ||
          cs?.loading == true ||
          cs?.saving == true,
      consequence: loaded,
      recover: draft.discard,
    ));
  }
  if (audio != null) {
    targets.add((
      id: 'project-sounds',
      label: 'Sons · Tout le projet',
      draft: SoundSettingsDraft(audio),
      busy: audio.busy,
      consequence: loaded,
      recover: audio.discard,
    ));
  }
  void visuals(ProjectVisualsController owner, String id, String label) {
    for (final section in [
      ProjectSettingsSection.image,
      ProjectSettingsSection.timeWeather,
    ]) {
      final draft = VisualSettingsDraft(
        owner,
        section == ProjectSettingsSection.image
            ? isImageVisualParameter
            : isTimeWeatherVisualParameter,
      );
      targets.add((
        id: '$id-${section.name}',
        label:
            '${section == ProjectSettingsSection.image ? 'Image et caméra' : 'Temps et météo'} · $label',
        draft: draft,
        busy: owner.loading || owner.saving,
        consequence: loaded,
        recover: draft.discard,
      ));
    }
  }

  if (projectVisuals != null) {
    visuals(projectVisuals, 'project', 'Tout le projet');
  }
  for (final map in maps) {
    visuals(map.owner, 'map-${map.mapId}', 'Carte « ${map.name} »');
  }
  return targets;
}
