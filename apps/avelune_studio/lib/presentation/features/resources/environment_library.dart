import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../map_workspace/map_workspace_visuals.dart';

class EnvironmentLibrary extends StatefulWidget {
  const EnvironmentLibrary({
    super.key,
    required this.project,
    required this.visuals,
    required this.onEdit,
    required this.onDuplicate,
    required this.onRemove,
    required this.onDraw,
    this.canDraw = true,
  });
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final ValueChanged<EnvironmentPreset> onEdit, onDuplicate, onRemove, onDraw;
  final bool canDraw;

  @override
  State<EnvironmentLibrary> createState() => _EnvironmentLibraryState();
}

class _EnvironmentLibraryState extends State<EnvironmentLibrary> {
  final search = TextEditingController();
  String? selectedId;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presets =
        widget.project.environmentPresets
            .where(
              (preset) =>
                  preset.name.toLowerCase().contains(search.text.toLowerCase()),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioSearchField(
            controller: search,
            hint: 'Rechercher un environnement',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          const Text(
            'Préparez la palette ici. Dessinez sa zone sur Carte, puis examinez l’aperçu avant de répartir les décors.',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: presets.isEmpty
                ? StudioEmptyState(
                    title: widget.project.environmentPresets.isEmpty
                        ? 'Aucun environnement'
                        : 'Aucun résultat',
                    description:
                        'Un environnement répartit des décors existants dans les cases que vous choisissez.',
                    icon: Icons.forest_outlined,
                  )
                : ListView.separated(
                    itemCount: presets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final preset = presets[index];
                      final first = widget.project.elements
                          .where(
                            (element) =>
                                element.id == preset.palette.first.elementId,
                          )
                          .firstOrNull;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          StudioChoice(
                            key: ValueKey('environment-${preset.id}'),
                            label: preset.name,
                            subtitle:
                                '${preset.palette.length} décor(s) · densité ${(preset.defaultParams.density * 100).round()} %',
                            leading: first == null
                                ? const Icon(Icons.broken_image_outlined)
                                : widget.visuals.thumbnail(first, size: 56),
                            selected: selectedId == preset.id,
                            onTap: () => setState(() => selectedId = preset.id),
                          ),
                          if (selectedId == preset.id)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                StudioButton(
                                  label: 'Modifier',
                                  icon: Icons.edit_outlined,
                                  secondary: true,
                                  onPressed: () => widget.onEdit(preset),
                                ),
                                StudioButton(
                                  label: 'Dupliquer',
                                  icon: Icons.copy_outlined,
                                  secondary: true,
                                  onPressed: () => widget.onDuplicate(preset),
                                ),
                                StudioButton(
                                  label: 'Supprimer…',
                                  icon: Icons.delete_outline,
                                  variant: StudioButtonVariant.destructive,
                                  onPressed: () => widget.onRemove(preset),
                                ),
                                StudioButton(
                                  label: 'Dessiner sur la carte',
                                  icon: Icons.draw_outlined,
                                  onPressed: widget.canDraw
                                      ? () => widget.onDraw(preset)
                                      : null,
                                ),
                              ],
                            ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
