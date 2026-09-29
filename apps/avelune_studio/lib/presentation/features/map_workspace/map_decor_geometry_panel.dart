import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import '../../shared/widgets/inputs/studio_commit_field.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'map_workspace_view_state.dart';

class MapDecorGeometryPanel extends StatelessWidget {
  const MapDecorGeometryPanel({
    super.key,
    required this.document,
    required this.project,
    required this.instance,
    required this.element,
    required this.view,
    required this.onChanged,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapPlacedElement instance;
  final ProjectElementEntry element;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final commands = MapEditingCommands(document, project);
    final owned =
        environmentOwnedMapPlacedElementIds(
          document.current,
        ).contains(instance.id) ||
        instance.properties[pokemapPlacementOriginProperty]?.trim() ==
            pokemapPlacementOriginEnvironment;
    if (owned) {
      return const Text(
        'Ce décor est piloté par une zone d’environnement. Modifiez cette zone pour le déplacer.',
      );
    }
    if (!isAuthoredMapPlacedElement(instance)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Rendez ce décor indépendant pour le déplacer au pixel près et changer sa taille.',
          ),
          StudioButton(
            key: const ValueKey('decor-detach'),
            label: 'Rendre indépendant',
            secondary: true,
            onPressed: () {
              commands.detach(instance.id);
              onChanged();
            },
          ),
        ],
      );
    }
    final tile = PixelSize(
      width: project.settings.tileWidth,
      height: project.settings.tileHeight,
    );
    final geometry = resolveMapPlacedElementGeometry(
      instance: instance,
      element: element,
      tileSize: tile,
    );
    final rect = geometry.logicalRect;
    bool save(int x, int y, PixelSize? size) {
      if (document.selectedId != instance.id) return false;
      final result = commands.setGeometry(instance.id, x: x, y: y, size: size);
      onChanged();
      return result;
    }

    Widget field(String id, String label, int value) => Expanded(
      child: StudioCommitField(
        key: ValueKey('decor-geometry-$id'),
        label: label,
        value: '$value',
        tryCommit: (text) {
          final number = int.tryParse(text.trim());
          if (number == null) {
            document.error = 'Saisissez un nombre entier de pixels.';
            onChanged();
            return false;
          }
          var width = rect.widthPx, height = rect.heightPx;
          if (id == 'width') {
            width = number;
            if (view.lockDecorProportions) {
              height = math.max(
                1,
                (width * rect.heightPx / rect.widthPx).round(),
              );
            }
          }
          if (id == 'height') {
            height = number;
            if (view.lockDecorProportions) {
              width = math.max(
                1,
                (height * rect.widthPx / rect.heightPx).round(),
              );
            }
          }
          return save(
            id == 'x' ? number : rect.leftPx,
            id == 'y' ? number : rect.topPx,
            id == 'x' || id == 'y'
                ? instance.pixelSize
                : PixelSize(width: width, height: height),
          );
        },
      ),
    );
    final coverage = geometry.cellBounds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            field('x', 'X · px', rect.leftPx),
            const SizedBox(width: 8),
            field('y', 'Y · px', rect.topPx),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            field('width', 'Largeur · px', rect.widthPx),
            const SizedBox(width: 8),
            field('height', 'Hauteur · px', rect.heightPx),
          ],
        ),
        StudioToggleRow(
          key: const ValueKey('decor-lock-ratio'),
          label: 'Garder les proportions',
          value: view.lockDecorProportions,
          description: 'Coins et champs de taille ; les côtés restent libres.',
          onChanged: (value) {
            view.lockDecorProportions = value;
            onChanged();
          },
        ),
        StudioButton(
          key: const ValueKey('decor-natural-size'),
          label: 'Taille naturelle',
          secondary: true,
          onPressed: () => save(rect.leftPx, rect.topPx, null),
        ),
        const SizedBox(height: 6),
        StudioButton(
          key: const ValueKey('decor-snap-grid'),
          label: 'Recaler sur la grille',
          secondary: true,
          onPressed: () => save(
            (rect.leftPx / tile.width).round() * tile.width,
            (rect.topPx / tile.height).round() * tile.height,
            instance.pixelSize,
          ),
        ),
        StudioToggleRow(
          key: const ValueKey('decor-show-collision'),
          label: 'Voir les collisions',
          value: view.showDecorCollision,
          onChanged: (value) {
            view.showDecorCollision = value;
            onChanged();
          },
        ),
        Text(
          'Interactions : ${coverage.size.width} × ${coverage.size.height} cases, depuis ${coverage.pos.x}, ${coverage.pos.y}.',
        ),
        const Text(
          'Maj : déplacement et taille au pixel. Maj + flèches : décaler de 1 px.',
        ),
      ],
    );
  }
}
