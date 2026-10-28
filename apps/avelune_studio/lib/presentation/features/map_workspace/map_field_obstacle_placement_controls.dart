import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/inputs/studio_select.dart';
import 'map_workspace_view_state.dart';

class MapFieldObstaclePlacementControls extends StatelessWidget {
  const MapFieldObstaclePlacementControls({
    super.key,
    required this.view,
    required this.elements,
    required this.onChanged,
  });

  final MapWorkspaceViewState view;
  final List<ProjectElementEntry> elements;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final ability = StudioSelect(
      label: 'Type d’obstacle',
      value: view.fieldObstacleKind.name,
      options: const {
        'cutTree': 'Coupe · arbre à couper',
        'strengthBoulder': 'Force · rocher à pousser',
        'rockSmashRock': 'Éclate-Roc · rocher à briser',
        'iceBlock': 'Glace · poussée au contact',
      },
      onChanged: (value) {
        view.fieldObstacleKind = FieldObstacleKind.values.byName(value);
        if (view.fieldObstacleKind == FieldObstacleKind.strengthBoulder ||
            view.fieldObstacleKind == FieldObstacleKind.iceBlock) {
          view.fieldObstacleResetPolicy = FieldObstacleResetPolicy.mapInstance;
        }
        onChanged();
      },
    );
    final visual = StudioSelect(
      label: 'Visuel de l’obstacle',
      value: view.brush?.id,
      options: {for (final element in elements) element.id: element.name},
      onChanged: elements.isEmpty
          ? null
          : (id) {
              view.brush = elements.singleWhere((element) => element.id == id);
              onChanged();
            },
    );
    return LayoutBuilder(
      builder: (context, bounds) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (bounds.maxWidth < 520)
            Column(children: [ability, const SizedBox(height: 8), visual])
          else
            Row(
              children: [
                Expanded(child: ability),
                const SizedBox(width: 12),
                Expanded(child: visual),
              ],
            ),
          const SizedBox(height: 8),
          if (view.fieldObstacleKind == FieldObstacleKind.cutTree ||
              view.fieldObstacleKind == FieldObstacleKind.rockSmashRock)
            StudioSelect(
              key: const ValueKey('field-obstacle-placement-reset'),
              label: 'Après utilisation',
              value: view.fieldObstacleResetPolicy.name,
              options: const {
                'persistent': 'Conservé dans la sauvegarde',
                'mapInstance': 'Réapparaît à la nouvelle instance',
              },
              onChanged: (value) {
                view.fieldObstacleResetPolicy = FieldObstacleResetPolicy.values
                    .byName(value);
                onChanged();
              },
            ),
          const SizedBox(height: 6),
          Text(
            elements.isEmpty
                ? 'Ajoutez un décor aux ressources du projet pour lui donner ce rôle.'
                : 'Cliquez sur la carte pour poser un obstacle bloquant sur une case.',
          ),
        ],
      ),
    );
  }
}
