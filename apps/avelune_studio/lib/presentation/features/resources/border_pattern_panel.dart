import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/resources/domain/resource_port.dart';

import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../terrains/terrain_spatial_preview.dart';
import 'resource_catalog.dart';
import 'resource_preview.dart';

class BorderPatternPanel extends StatelessWidget {
  const BorderPatternPanel({
    super.key,
    required this.chosen,
    required this.active,
    required this.visuals,
    required this.project,
    required this.onAssign,
    this.straightOnly = false,
    this.followContourDirection = false,
    this.variantSelector,
    this.modelSettings,
    this.settingsForRole,
  });

  final Map<String, ResourceItem> chosen;
  final ResourceItem? active;
  final MapWorkspaceVisuals visuals;
  final ProjectManifest project;
  final void Function(String role, ResourceItem element) onAssign;
  final bool straightOnly;
  final bool followContourDirection;
  final Widget Function(String role)? variantSelector;
  final Widget? modelSettings;
  final BorderModelSettings Function(String role)? settingsForRole;

  static const contour = <(String, String)>[
    ('Angle haut gauche', 'lineCorner'),
    ('Bord haut', 'lineStraight'),
    ('Angle haut droit', 'lineCorner'),
    ('Bord gauche', 'lineStraight'),
    ('Centre libre', ''),
    ('Bord droit', 'lineStraight'),
    ('Angle bas gauche', 'lineCorner'),
    ('Bord bas', 'lineStraight'),
    ('Angle bas droit', 'lineCorner'),
  ];
  static const exterior = <String>[
    'Extérieur haut gauche',
    'Extérieur haut droit',
    'Extérieur bas gauche',
    'Extérieur bas droit',
  ];
  static const ends = <String>[
    'Extrémité haute',
    'Extrémité droite',
    'Extrémité basse',
    'Extrémité gauche',
  ];

  List<String> get _roles => [
    'lineStraight',
    'lineCap',
    if (!straightOnly) 'lineCorner',
    if (!straightOnly && followContourDirection) 'lineCornerLeft',
  ];

  Widget _slot(
    BuildContext context,
    String label,
    String role, {
    bool previewOnly = false,
  }) {
    final color = Theme.of(context).colorScheme;
    if (role.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: color.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
      );
    }
    final selected = chosen[role];
    final settings = settingsForRole?.call(role) ?? const BorderModelSettings();
    return DragTarget<ProjectElementEntry>(
      onAcceptWithDetails: previewOnly
          ? null
          : (details) => onAssign(
              role,
              ResourceItem(
                id: details.data.id,
                name: details.data.name,
                kind: ResourceKind.decors,
                element: details.data,
              ),
            ),
      builder: (context, candidates, rejected) => Material(
        color: candidates.isNotEmpty
            ? color.primaryContainer
            : color.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: candidates.isNotEmpty ? color.primary : color.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: InkWell(
          key: previewOnly ? null : ValueKey('border-pattern-$label'),
          borderRadius: BorderRadius.circular(8),
          onTap: active == null || previewOnly
              ? null
              : () => onAssign(role, active!),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: selected == null
                        ? Icon(_icon(role), size: 24)
                        : selected.model3d != null
                        ? IgnorePointer(
                            child: TerrainSpatialPreview(
                              map: MapData(
                                id: 'border-pattern',
                                name: 'Pièce de bordure',
                                version: ProjectVersion.v9,
                                size: const GridSize(width: 1, height: 1),
                                spatialScene: MapSpatialScene(
                                  width: 1,
                                  depth: 1,
                                  instances: [
                                    SpatialModelInstance(
                                      id: 'preview',
                                      modelId: selected.id,
                                      position: Model3dVector3(
                                        x: .5,
                                        y: 0,
                                        z: .5,
                                      ),
                                      rotationDegrees: -_turns(label) * 90.0,
                                      animationIndex: settings.animationIndex,
                                      animationLoop: settings.animationLoop,
                                      animationSpeed: settings.animationSpeed,
                                      blocksMovement: settings.blocksMovement,
                                    ),
                                  ],
                                ),
                              ),
                              project: project,
                              visuals: visuals,
                            ),
                          )
                        : _oriented(
                            label,
                            resourcePreview(
                              selected,
                              project,
                              visuals,
                              size: 46,
                            ),
                          ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _icon(String role) => switch (role) {
    'lineCorner' => Icons.turn_right,
    'lineCornerLeft' => Icons.turn_left,
    'lineCap' => Icons.horizontal_rule,
    _ => Icons.segment,
  };

  int _turns(String label) => switch (label) {
    'Angle haut gauche' || 'Extérieur haut gauche' => 3,
    'Angle haut droit' || 'Extérieur haut droit' => 0,
    'Angle bas gauche' || 'Extérieur bas gauche' => 2,
    'Angle bas droit' || 'Extérieur bas droit' => 1,
    'Bord gauche' => followContourDirection ? 3 : 1,
    'Bord droit' => 1,
    'Bord bas' => followContourDirection ? 2 : 0,
    'Extrémité haute' => 1,
    'Extrémité droite' => 2,
    'Extrémité basse' => 3,
    _ => 0,
  };

  Widget _oriented(String label, Widget piece) => Transform.flip(
    flipX: label.startsWith('Extérieur'),
    child: RotatedBox(quarterTurns: _turns(label), child: piece),
  );

  Widget _row(
    BuildContext context,
    List<(String, String)> slots, {
    bool previewOnly = false,
  }) => Row(
    children: [
      for (var i = 0; i < slots.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 88,
            child: _slot(
              context,
              slots[i].$1,
              slots[i].$2,
              previewOnly: previewOnly,
            ),
          ),
        ),
      ],
    ],
  );

  Widget _pattern(BuildContext context) => StudioPanel(
    title: 'Patron de la bordure',
    compact: true,
    children: [
      Text(
        followContourDirection
            ? 'La face regarde vers l’extérieur. Associez les deux formes d’angle.'
            : 'Déposez vos décors sur la forme. Le centre reste libre.',
      ),
      const SizedBox(height: 5),
      Text(
        '${_roles.where(chosen.containsKey).length} / ${_roles.length} familles de pièces associées',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      const SizedBox(height: 10),
      if (variantSelector != null)
        for (final role in _roles) variantSelector!(role),
      if (straightOnly) ...[
        const Text(
          'Tracés droits uniquement. Le corps et une extrémité sont nécessaires.',
        ),
        const SizedBox(height: 8),
        _row(context, const [
          ('Corps', 'lineStraight'),
          ('Extrémité', 'lineCap'),
        ]),
      ] else if (followContourDirection) ...[
        _row(context, const [
          ('Corps', 'lineStraight'),
          ('Extrémité', 'lineCap'),
        ]),
        const SizedBox(height: 8),
        _row(context, const [
          ('Angle sortant', 'lineCorner'),
          ('Angle rentrant', 'lineCornerLeft'),
        ]),
      ] else ...[
        for (var row = 0; row < 3; row++) ...[
          _row(context, contour.sublist(row * 3, row * 3 + 3)),
          const SizedBox(height: 6),
        ],
        if (project.settings.dimension == ProjectDimension.twoD) ...[
          const SizedBox(height: 10),
          Text(
            'Coins extérieurs',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 5),
          _row(context, [for (final label in exterior) (label, 'lineCorner')]),
        ],
        const SizedBox(height: 10),
        Text('Extrémités', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 5),
        _row(context, [for (final label in ends) (label, 'lineCap')]),
      ],
      const SizedBox(height: 10),
      if (modelSettings != null) ...[
        modelSettings!,
        const SizedBox(height: 10),
      ],
      Text(
        'Les orientations d’une même famille partagent la pièce choisie. Le moteur la tourne selon le tracé.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  Widget _previewPiece(BuildContext context, int index) {
    final role = contour[index].$2;
    final label = contour[index].$1;
    if (role.isEmpty) return const Text('Libre');
    final element = chosen[role];
    return element == null
        ? Icon(_icon(role))
        : element.model3d != null
        ? _slot(context, label, role, previewOnly: true)
        : _oriented(
            label,
            resourcePreview(element, project, visuals, size: 64),
          );
  }

  Widget _preview(BuildContext context) => StudioPanel(
    title: 'Aperçu immédiat',
    compact: true,
    children: [
      const Text('Le tracé utilise les pièces actuellement associées.'),
      const SizedBox(height: 12),
      if (straightOnly)
        _row(context, const [
          ('Corps', 'lineStraight'),
          ('Extrémité', 'lineCap'),
        ], previewOnly: true)
      else
        for (var row = 0; row < 3; row++) ...[
          Row(
            children: [
              for (var column = 0; column < 3; column++)
                Expanded(
                  child: SizedBox(
                    height: 72,
                    child: Center(
                      child: _previewPiece(context, row * 3 + column),
                    ),
                  ),
                ),
            ],
          ),
        ],
      const SizedBox(height: 8),
      Text(
        chosen.containsKey('lineCap') &&
                chosen.containsKey('lineStraight') &&
                (straightOnly ||
                    (chosen.containsKey('lineCorner') &&
                        (!followContourDirection ||
                            chosen.containsKey('lineCornerLeft'))))
            ? 'Associations complètes. Les raccords restent à valider avant publication.'
            : 'Les pièces manquantes restent visibles avant publication.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      if (bounds.maxWidth < 670) {
        return ListView(
          children: [
            _pattern(context),
            const SizedBox(height: 12),
            _preview(context),
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SingleChildScrollView(child: _pattern(context))),
          const SizedBox(width: 12),
          SizedBox(width: bounds.maxWidth * .3, child: _preview(context)),
        ],
      );
    },
  );
}
