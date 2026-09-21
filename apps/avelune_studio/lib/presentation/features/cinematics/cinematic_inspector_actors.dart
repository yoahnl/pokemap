part of 'cinematic_inspector.dart';

extension CinematicInspectorActors on CinematicInspector {
  List<Widget> _actorFields(CinematicAsset asset) {
    final actor = asset.requiredActors
        .where((a) => a.actorId == view.actorId)
        .firstOrNull;
    final binding = asset.stageContext?.actorBindings
        .where((b) => b.actorId == actor?.actorId)
        .firstOrNull;
    final appearance = asset.stageContext?.actorAppearanceBindings
        .where((b) => b.actorId == actor?.actorId)
        .firstOrNull;
    final placement = asset.stageContext?.initialPlacements
        .where((b) => b.actorId == actor?.actorId)
        .firstOrNull;
    return [
      StudioSelect(
        label: 'Acteur de la cinématique',
        value: actor?.actorId,
        options: {
          for (final a in asset.requiredActors)
            a.actorId: '${a.label} · ${a.actorId}',
        },
        onChanged: (id) {
          view.actorId = id;
          view.actionError = null;
          view.initialPlacementChoice = null;
          changed();
        },
      ),
      StudioButton(
        label: 'Ajouter un acteur',
        secondary: true,
        icon: Icons.person_add_alt,
        onPressed: () {
          final id = controller.addActor('Nouvel acteur');
          if (id != null) {
            view.actorId = id;
            view.actionError = null;
            view.initialPlacementChoice = null;
            changed();
          }
        },
      ),
      if (actor != null) ...[
        StudioSelect(
          label: 'Rôle dans le jeu',
          value: (binding?.kind ?? CinematicActorBindingKind.unbound).name,
          options: const {
            'unbound': 'À relier',
            'player': 'Joueur',
            'mapEntity': 'Personnage de la carte',
            'cinematicOnly': 'Acteur propre à la cinématique',
          },
          onChanged: (kind) => controller.bindActor(
            CinematicActorBinding(
              actorId: actor.actorId,
              kind: CinematicActorBindingKind.values.byName(kind),
              mapEntityId: kind == 'mapEntity' ? binding?.mapEntityId : null,
            ),
          ),
        ),
        if (binding?.kind == CinematicActorBindingKind.mapEntity)
          StudioSelect(
            label: 'Personnage exact',
            value: binding?.mapEntityId,
            options: {
              if (model != null)
                for (final entity in model!.map.entities)
                  entity.id: '${entity.name} · ${entity.id}',
            },
            onChanged: model == null
                ? null
                : (id) => controller.bindActor(
                    CinematicActorBinding(
                      actorId: actor.actorId,
                      kind: CinematicActorBindingKind.mapEntity,
                      mapEntityId: id,
                    ),
                  ),
          ),
        if (binding?.kind == CinematicActorBindingKind.cinematicOnly)
          StudioSelect(
            label: 'Apparence',
            value: appearance?.characterId,
            options: {
              for (final character in controller.project.characters)
                character.id: character.name,
            },
            onChanged: (id) => controller.setAppearance(
              CinematicActorAppearanceBinding(
                actorId: actor.actorId,
                characterId: id,
              ),
            ),
          ),
        const Text(
          'La pose d’essai appartient à cette séquence. La carte conserve ses personnages et son point de départ.',
        ),
        StudioSelect(
          label: 'Position initiale',
          value: view.initialPlacementChoice ?? placement?.kind.name ?? 'unset',
          options: const {
            'unset': 'Non définie',
            'fromMapEntity': 'Position du personnage',
            'fromMovementTarget': 'Destination existante',
            'stagePoint': 'Repère de la cinématique',
          },
          onChanged: (kind) {
            if (kind == 'fromMovementTarget' || kind == 'stagePoint') {
              view.initialPlacementChoice = kind;
              changed();
              return;
            }
            view.initialPlacementChoice = null;
            controller.setPlacement(
              CinematicActorInitialPlacement(
                actorId: actor.actorId,
                kind: CinematicActorInitialPlacementKind.values.byName(kind),
                targetId: kind == 'fromMovementTarget'
                    ? placement?.targetId
                    : null,
                stagePointId: kind == 'stagePoint'
                    ? placement?.stagePointId
                    : null,
              ),
            );
          },
        ),
        if (view.initialPlacementChoice != null)
          const Text(
            'Choisissez le repère ou la destination ci-dessous, ou placez cet acteur sur la carte.',
          ),
        if (asset.movementTargets.isNotEmpty)
          StudioSelect(
            label: 'Destination initiale',
            value: placement?.targetId,
            options: {
              for (final target in asset.movementTargets)
                target.targetId: target.label,
            },
            onChanged: (id) {
              view.initialPlacementChoice = null;
              controller.setPlacement(
                CinematicActorInitialPlacement(
                  actorId: actor.actorId,
                  kind: CinematicActorInitialPlacementKind.fromMovementTarget,
                  targetId: id,
                ),
              );
            },
          ),
        if (asset.stageContext?.stagePoints.isNotEmpty ?? false)
          StudioSelect(
            label: 'Repère initial',
            value: placement?.stagePointId,
            options: {
              for (final point
                  in asset.stageContext?.stagePoints ?? <CinematicStagePoint>[])
                point.id: '${point.label} · ${point.x}, ${point.y}',
            },
            onChanged: (id) {
              view.initialPlacementChoice = null;
              controller.setPlacement(
                CinematicActorInitialPlacement(
                  actorId: actor.actorId,
                  kind: CinematicActorInitialPlacementKind.stagePoint,
                  stagePointId: id,
                ),
              );
            },
          ),
        StudioButton(
          label: 'Placer sur la carte',
          secondary: true,
          icon: Icons.my_location,
          onPressed: model == null
              ? null
              : () => _mode(CinematicMapMode.placement),
        ),
      ],
    ];
  }
}
