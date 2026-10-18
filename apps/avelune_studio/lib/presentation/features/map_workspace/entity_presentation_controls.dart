import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../events/event_conditions.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/feedback/studio_notice.dart';

class EntityPresentationControls extends StatefulWidget {
  const EntityPresentationControls({
    super.key,
    required this.entity,
    required this.project,
    required this.mapId,
    required this.mapSize,
    required this.onChanged,
  });
  final MapEntity entity;
  final ProjectManifest project;
  final String mapId;
  final GridSize mapSize;
  final ValueChanged<MapEntityPresentation?> onChanged;

  @override
  State<EntityPresentationControls> createState() =>
      _EntityPresentationControlsState();
}

class _EntityPresentationControlsState
    extends State<EntityPresentationControls> {
  MapEntity get entity => widget.entity;
  ProjectManifest get project => widget.project;
  String get mapId => widget.mapId;
  ValueChanged<MapEntityPresentation?> get onChanged => widget.onChanged;
  String? _error;

  void _replace(int index, Map<String, dynamic> changes) {
    try {
      final variants = [...entity.presentation!.variants];
      variants[index] = MapEntityPresentationVariant.fromJson({
        ...variants[index].toJson(),
        ...changes,
      });
      onChanged(MapEntityPresentation(variants: variants));
      setState(() => _error = null);
    } on Object {
      setState(
        () => _error =
            'Cette variante contient une condition ou une valeur non valide.',
      );
    }
  }

  bool _resize(int index, String value, {required bool width}) {
    final size = entity.presentation!.variants[index].size;
    final number = int.tryParse(value);
    if (number == null ||
        number < 1 ||
        number > 64 ||
        (width
            ? entity.pos.x + number > widget.mapSize.width
            : entity.pos.y + number > widget.mapSize.height)) {
      setState(
        () => _error =
            'Choisissez une taille de 1 à 64 cases qui reste dans la carte.',
      );
      return false;
    }
    _replace(index, {
      'size': {
        'width': width ? number : size.width,
        'height': width ? size.height : number,
      },
    });
    return _error == null;
  }

  @override
  Widget build(BuildContext context) {
    if (!const [
          MapEntityKind.custom,
          MapEntityKind.npc,
        ].contains(entity.kind) ||
        entity.fieldObstacle != null ||
        entity.healingDisplay != null ||
        entity.interactiveEncounter != null) {
      return const SizedBox.shrink();
    }
    final variants =
        entity.presentation?.variants ?? const <MapEntityPresentationVariant>[];
    return StudioPanel(
      title: 'Apparence selon les conditions',
      compact: true,
      children: [
        const Text(
          'La première variante dont les conditions sont remplies est utilisée. Sans correspondance, cet élément est absent du jeu.',
        ),
        const Text(
          'Retirer toutes les variantes rétablit l’apparence de base de cet élément.',
        ),
        if (_error != null) StudioNotice(_error!, isError: true),
        for (final entry in variants.indexed)
          StudioPanel(
            title: 'Variante ${entry.$1 + 1}',
            compact: true,
            actions: [
              if (entry.$1 > 0)
                StudioTool(
                  label: 'Monter la priorité',
                  icon: Icons.arrow_upward,
                  onPressed: () {
                    final next = [...variants];
                    final value = next.removeAt(entry.$1);
                    next.insert(entry.$1 - 1, value);
                    onChanged(MapEntityPresentation(variants: next));
                  },
                ),
              StudioTool(
                label: 'Retirer la variante',
                icon: Icons.close,
                onPressed: () {
                  final next = [...variants]..removeAt(entry.$1);
                  onChanged(
                    next.isEmpty ? null : MapEntityPresentation(variants: next),
                  );
                },
              ),
            ],
            children: [
              StudioSelect(
                label: 'Personnage de la variante',
                value: entry.$2.characterId ?? '',
                options: {
                  '': 'Aucun graphisme',
                  for (final character in project.characters)
                    character.id: character.name,
                },
                onChanged: (value) => _replace(entry.$1, {
                  'characterId': value.isEmpty ? null : value,
                }),
              ),
              StudioSelect(
                label: 'Orientation initiale',
                value: entry.$2.facing.name,
                options: const {
                  'north': 'Haut',
                  'south': 'Bas',
                  'west': 'Gauche',
                  'east': 'Droite',
                },
                onChanged: (value) => _replace(entry.$1, {'facing': value}),
              ),
              StudioChoice(
                label: 'La variante bloque le passage',
                selected: entry.$2.blocksMovement,
                onTap: () => _replace(entry.$1, {
                  'blocksMovement': !entry.$2.blocksMovement,
                }),
              ),
              StudioSelect(
                label: 'Déclencher l’interaction',
                value: entry.$2.interactionMode.name,
                options: const {
                  'front': 'Devant le joueur',
                  'overlap': 'Sur la même case que le joueur',
                },
                onChanged: (value) =>
                    _replace(entry.$1, {'interactionMode': value}),
              ),
              StudioCommitField(
                label: 'Largeur en cases',
                value: '${entry.$2.size.width}',
                tryCommit: (value) => _resize(entry.$1, value, width: true),
              ),
              StudioCommitField(
                label: 'Hauteur en cases',
                value: '${entry.$2.size.height}',
                tryCommit: (value) => _resize(entry.$1, value, width: false),
              ),
              if (project.settings.dimension == ProjectDimension.twoD)
                for (final side in EntityFacing.values)
                  StudioChoice(
                    label:
                        'Interagir à travers un comptoir : ${switch (side) {
                          EntityFacing.north => 'haut',
                          EntityFacing.south => 'bas',
                          EntityFacing.west => 'gauche',
                          EntityFacing.east => 'droite',
                        }}',
                    selected: entry.$2.counterInteractionSides.contains(side),
                    onTap: () {
                      final sides = [...entry.$2.counterInteractionSides];
                      if (!sides.remove(side)) sides.add(side);
                      _replace(entry.$1, {
                        'counterInteractionSides': sides
                            .map((value) => value.name)
                            .toList(),
                      });
                    },
                  ),
              EventConditions(
                expression: entry.$2.condition,
                facts: project.facts,
                records: project.eventRegistry?.records ?? const [],
                mapId: mapId,
                entityId: entity.id,
                onChanged: (value) =>
                    _replace(entry.$1, {'condition': value.toJson()}),
              ),
            ],
          ),
        StudioButton(
          label: 'Ajouter une variante',
          icon: Icons.add,
          secondary: true,
          onPressed: variants.length >= 256
              ? null
              : () {
                  var suffix = variants.length + 1;
                  while (variants.any(
                    (variant) => variant.id == 'variant_$suffix',
                  )) {
                    suffix++;
                  }
                  onChanged(
                    MapEntityPresentation(
                      variants: [
                        ...variants,
                        MapEntityPresentationVariant(
                          id: 'variant_$suffix',
                          condition: NarrativeEventConditionExpression.all(
                            const [],
                          ),
                          characterId: entity.npc?.characterId,
                          facing: entity.npc?.facing ?? EntityFacing.south,
                          blocksMovement: entity.blocksMovement,
                          size: entity.size,
                          interactionMode: entity.interactionMode,
                          counterInteractionSides:
                              entity.counterInteractionSides.isNotEmpty
                              ? entity.counterInteractionSides
                              : entity.npc?.counterInteractionSides ?? const [],
                        ),
                      ],
                    ),
                  );
                },
        ),
      ],
    );
  }
}
