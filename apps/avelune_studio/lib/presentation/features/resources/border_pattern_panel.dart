import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_workspace_visuals.dart';

class BorderPatternPanel extends StatelessWidget {
  const BorderPatternPanel({
    super.key,
    required this.chosen,
    required this.active,
    required this.visuals,
    required this.onAssign,
  });

  final Map<String, ProjectElementEntry> chosen;
  final ProjectElementEntry? active;
  final MapWorkspaceVisuals visuals;
  final void Function(String role, ProjectElementEntry element) onAssign;

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

  Widget _slot(BuildContext context, String label, String role) {
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
    return DragTarget<ProjectElementEntry>(
      onAcceptWithDetails: (details) => onAssign(role, details.data),
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
          key: ValueKey('border-pattern-$label'),
          borderRadius: BorderRadius.circular(8),
          onTap: active == null ? null : () => onAssign(role, active!),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: selected == null
                        ? Icon(_icon(role), size: 24)
                        : _oriented(
                            label,
                            visuals.thumbnail(selected, size: 46),
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
    'lineCap' => Icons.horizontal_rule,
    _ => Icons.segment,
  };

  int _turns(String label) => switch (label) {
    'Angle haut gauche' || 'Extérieur haut gauche' => 3,
    'Angle haut droit' || 'Extérieur haut droit' => 0,
    'Angle bas gauche' || 'Extérieur bas gauche' => 2,
    'Angle bas droit' || 'Extérieur bas droit' => 1,
    'Bord gauche' || 'Bord droit' => 1,
    'Extrémité haute' => 1,
    'Extrémité droite' => 2,
    'Extrémité basse' => 3,
    _ => 0,
  };

  Widget _oriented(String label, Widget piece) => Transform.flip(
    flipX: label.startsWith('Extérieur'),
    child: RotatedBox(quarterTurns: _turns(label), child: piece),
  );

  Widget _row(BuildContext context, List<(String, String)> slots) => Row(
    children: [
      for (var i = 0; i < slots.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(
          child: SizedBox(
            height: 88,
            child: _slot(context, slots[i].$1, slots[i].$2),
          ),
        ),
      ],
    ],
  );

  Widget _pattern(BuildContext context) => StudioPanel(
    title: 'Patron de la bordure',
    compact: true,
    children: [
      const Text('Déposez vos décors sur la forme. Le centre reste libre.'),
      const SizedBox(height: 5),
      Text(
        '${chosen.length} / 3 familles de pièces associées',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      const SizedBox(height: 10),
      for (var row = 0; row < 3; row++) ...[
        _row(context, contour.sublist(row * 3, row * 3 + 3)),
        const SizedBox(height: 6),
      ],
      const SizedBox(height: 10),
      Text('Coins extérieurs', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 5),
      _row(context, [for (final label in exterior) (label, 'lineCorner')]),
      const SizedBox(height: 10),
      Text('Extrémités', style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 5),
      _row(context, [for (final label in ends) (label, 'lineCap')]),
      const SizedBox(height: 10),
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
        : _oriented(label, visuals.thumbnail(element, size: 64));
  }

  Widget _preview(BuildContext context) => StudioPanel(
    title: 'Aperçu immédiat',
    compact: true,
    children: [
      const Text('Le tracé utilise les pièces actuellement associées.'),
      const SizedBox(height: 12),
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
        chosen.length == 3
            ? 'Les trois pièces sont prêtes pour la validation canonique.'
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
