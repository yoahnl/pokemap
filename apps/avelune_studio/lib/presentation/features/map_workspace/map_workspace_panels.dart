import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_tool.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_sidebar.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';

class MapWorkspacePalette extends StatefulWidget {
  const MapWorkspacePalette({
    super.key,
    required this.project,
    required this.document,
    required this.visuals,
    required this.view,
    required this.onChanged,
  });
  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  @override
  State<MapWorkspacePalette> createState() => _MapWorkspacePaletteState();
}

class _MapWorkspacePaletteState extends State<MapWorkspacePalette> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final elements = widget.project.elements.where(
      (e) => e.name.toLowerCase().contains(_query),
    );
    final tiles = widget.document.current.layers
        .whereType<TileLayer>()
        .expand((layer) => layer.palette)
        .toSet();
    return StudioSidebar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Décors', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(labelText: 'Rechercher un décor'),
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                if (elements.isEmpty)
                  const Text('Aucun décor préparé disponible.'),
                for (final element in elements)
                  StudioChoice(
                    label: element.name,
                    leading: widget.visuals.thumbnail(element, size: 40),
                    selected:
                        widget.view.tool == StudioMapTool.place &&
                        widget.view.brush?.id == element.id,
                    onTap: () {
                      widget.view.brush = element;
                      widget.view.tool = StudioMapTool.place;
                      widget.onChanged();
                    },
                  ),
                const SizedBox(height: 16),
                Text(
                  'Tuiles de la carte',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (tiles.isEmpty)
                  const Text('Aucune tuile déjà référencée sur cette carte.'),
                for (final tile in tiles)
                  StudioChoice(
                    label:
                        '${widget.project.tilesets.where((e) => e.id == tile.tilesetId).firstOrNull?.name ?? 'Ressource'} · tuile ${tile.localTileId + 1}',
                    selected:
                        widget.view.tool == StudioMapTool.paint &&
                        widget.view.tile == tile,
                    onTap: () {
                      widget.view.tile = tile;
                      widget.view.tool = StudioMapTool.paint;
                      widget.onChanged();
                    },
                  ),
              ],
            ),
          ),
          const Text(
            'Décor : clic pour placer plusieurs exemplaires. Échap pour terminer.',
          ),
        ],
      ),
    );
  }
}

class MapWorkspaceInspector extends StatelessWidget {
  const MapWorkspaceInspector({
    super.key,
    required this.project,
    required this.document,
    required this.visuals,
    required this.onChanged,
  });
  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    final commands = MapEditingCommands(document, project);
    final position = document.stackPosition;
    final stack = position == null
        ? <MapPlacedElement>[]
        : commands.stack(position);
    final selected = document.selected;
    final entry = project.elements
        .where((e) => e.id == selected?.elementId)
        .firstOrNull;
    void change(void Function() action) {
      action();
      onChanged();
    }

    return StudioSidebar(
      width: 225,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sélection', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text(
            entry?.name ??
                (selected == null
                    ? 'Cliquez un décor sur la carte.'
                    : 'Ressource manquante'),
          ),
          if (selected != null) ...[
            Text('Position : ${selected.pos.x}, ${selected.pos.y}'),
            Wrap(
              children: [
                StudioTool(
                  label: 'Passer devant',
                  icon: Icons.flip_to_front,
                  shortcut: '⌘↑ / Ctrl↑',
                  onPressed: () =>
                      change(() => commands.reorder(forward: true)),
                ),
                StudioTool(
                  label: 'Passer derrière',
                  icon: Icons.flip_to_back,
                  shortcut: '⌘↓ / Ctrl↓',
                  onPressed: () =>
                      change(() => commands.reorder(forward: false)),
                ),
                StudioTool(
                  label: 'Supprimer le décor',
                  icon: Icons.delete_outline,
                  shortcut: '⌫',
                  onPressed: () => change(commands.deleteSelected),
                ),
              ],
            ),
            const Text(
              'Ordre fixe entre décors compatibles. Le personnage conserve sa profondeur.',
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Empilement ici',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (stack.isEmpty)
            const Text(
              'Cliquez une zone occupée pour retrouver un décor masqué.',
            ),
          Expanded(
            child: ListView(
              children: [
                for (final instance in stack)
                  Builder(
                    builder: (context) {
                      final element = project.elements
                          .where((e) => e.id == instance.elementId)
                          .firstOrNull;
                      return StudioChoice(
                        label: element?.name ?? 'Ressource manquante',
                        leading: element == null
                            ? null
                            : visuals.thumbnail(element, size: 36),
                        selected: instance.id == document.selectedId,
                        onTap: () {
                          document.selectedId = instance.id;
                          onChanged();
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
