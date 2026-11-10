export 'package:avelune_studio/features/map_workspace/application/spatial_field_obstacle_eligibility.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/features/map_workspace/application/traversal_labels.dart';

typedef SpatialModelRoles = ({
  String interaction,
  String movement,
  String traversal,
});

SpatialModelRoles spatialModelRoles(
  MapData map,
  ProjectManifest project,
  SpatialModelInstance instance,
) {
  final scene = map.spatialScene!;
  final entity = map.entities
      .where((item) => item.id == instance.entityId)
      .firstOrNull;
  final obstacle = entity?.fieldObstacle?.kind;
  final model = project.models3d
      .where((item) => item.id == instance.modelId)
      .firstOrNull;
  final platform = scene.platforms
      .where((item) => item.instanceId == instance.id)
      .firstOrNull;
  final lift = scene.lifts
      .where((item) => item.instanceId == instance.id)
      .firstOrNull;
  final ramp = model?.rampProfile;
  final source = NarrativeEventSourceRef.modelInteract(map.id, instance.id);
  final events = [
    for (final record in project.eventRegistry?.records ?? <Never>[])
      if ((record.definitionOrNull?.source ?? record.draftOrNull?.source) ==
          source)
        record,
  ].length;
  final interaction = [
    if (obstacle != null)
      switch (obstacle) {
        FieldObstacleKind.cutTree => 'Obstacle Coupe : le joueur le coupe. Réglé ci-dessous, pour ce décor seulement.',
        FieldObstacleKind.strengthBoulder => 'Obstacle Force : le joueur le pousse. Réglé ci-dessous, pour ce décor seulement.',
        FieldObstacleKind.rockSmashRock => 'Obstacle Éclate-Roc : le joueur le brise. Réglé ci-dessous, pour ce décor seulement.',
        FieldObstacleKind.iceBlock =>
          'Bloc de glace : le jeu ne le fait pas glisser sur une carte 3D.',
      }
    else if (entity != null)
      'Lié à l’élément du jeu « ${entity.name.trim().isEmpty ? entity.id : entity.name} ».',
    if (events > 0)
      '$events ${events == 1 ? 'événement' : 'événements'} à l’interaction, '
          'réglés dans Événements.',
  ];
  return (
    interaction: interaction.isEmpty
        ? 'Aucune : le joueur ne déclenche rien sur ce décor.'
        : interaction.join(' '),
    movement: platform != null
        ? 'Plateforme « ${platform.name} » : transporte le joueur sur '
              '${platform.routes.length} '
              '${platform.routes.length == 1 ? 'trajet' : 'trajets'} en '
              '${traversalDurationLabel(platform.durationMs)}. Réglée dans '
              '« Plateforme sur trajet » ci-dessous.'
        : lift != null
        ? 'Plateforme verticale « ${lift.name} » : monte et descend entre '
              'deux hauteurs en ${traversalDurationLabel(lift.durationMs)}. '
              'Réglée ci-dessous.'
        : obstacle == FieldObstacleKind.strengthBoulder
        ? 'Poussé par le joueur avec Force.'
        : obstacle == FieldObstacleKind.iceBlock
        ? 'Aucun : un bloc de glace ne glisse pas sur une carte 3D.'
        : 'Aucun : le décor reste à sa place.',
    traversal: ramp != null
        ? 'Escalier franchissable : montée ${_direction(ramp.direction)}, de '
              'la hauteur ${_height(ramp.lowHeight)} à '
              '${_height(ramp.highHeight)}. Réglé dans la ressource du modèle, '
              'pour toutes ses occurrences.'
        : platform != null
        ? 'Le joueur monte sur le support au départ et à l’arrivée du trajet.'
        : !instance.blocksMovement
        ? 'Aucune collision : le joueur passe à travers.'
        : obstacle != null
        ? 'Bloque le passage tant que l’obstacle est en place.'
        : 'Bloque le passage du joueur.',
  );
}

String _direction(SpatialRampDirection direction) => switch (direction) {
  SpatialRampDirection.north => 'vers le fond',
  SpatialRampDirection.south => 'vers le devant',
  SpatialRampDirection.east => 'vers la droite',
  SpatialRampDirection.west => 'vers la gauche',
};

String _height(double value) => value
    .toStringAsFixed(2)
    .replaceFirst(RegExp(r'\.?0+$'), '')
    .replaceAll('.', ',');

class SpatialModelRolesSummary extends StatelessWidget {
  const SpatialModelRolesSummary({
    super.key,
    required this.map,
    required this.project,
    required this.instance,
  });
  final MapData map;
  final ProjectManifest project;
  final SpatialModelInstance instance;

  @override
  Widget build(BuildContext context) {
    final roles = spatialModelRoles(map, project, instance);
    final theme = Theme.of(context).textTheme;
    return StudioPanel(
      compact: true,
      title: 'Rôles de ce décor',
      children: [
        for (final (key, label, text) in [
          ('interaction', 'Interaction du joueur', roles.interaction),
          ('movement', 'Déplacement de l’objet', roles.movement),
          ('traversal', 'Traversée du joueur', roles.traversal),
        ])
          Padding(
            key: ValueKey('spatial-model-role-$key'),
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.titleSmall),
                Text(text),
              ],
            ),
          ),
      ],
    );
  }
}
