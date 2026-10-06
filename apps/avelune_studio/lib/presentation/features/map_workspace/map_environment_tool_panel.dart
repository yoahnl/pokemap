import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/environment_editing_commands.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'map_workspace_view_state.dart';

class MapEnvironmentToolPanel extends StatelessWidget {
  const MapEnvironmentToolPanel({
    super.key,
    required this.document,
    required this.project,
    required this.view,
    required this.onChanged,
    required this.onResources,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged, onResources;

  void run(VoidCallback action) {
    try {
      action();
      document.error = null;
    } on Object catch (failure) {
      document.error = environmentEditingMessage(failure);
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final commands = EnvironmentEditingCommands(document, project);
    final entries = commands.areas;
    final session = view.environment;
    final selected = session == null ? null : commands.area(session);
    final fresh =
        session != null &&
        identical(session.previewSource, document.current) &&
        identical(session.previewProject, project);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (entries.isNotEmpty)
                SizedBox(
                  width: 220,
                  child: StudioSelect(
                    key: const ValueKey('environment-zone-select'),
                    label: 'Zone d’environnement',
                    value: selected == null
                        ? ''
                        : '${session!.layerId}/${session.areaId}',
                    options: {
                      '': 'Choisir une zone',
                      for (final entry in entries)
                        '${entry.layer.id}/${entry.area.id}': entry.area.name,
                    },
                    onChanged: (value) {
                      final entry = entries
                          .where(
                            (entry) =>
                                '${entry.layer.id}/${entry.area.id}' == value,
                          )
                          .firstOrNull;
                      view.environment = entry == null
                          ? null
                          : MapEnvironmentSession(
                              layerId: entry.layer.id,
                              areaId: entry.area.id,
                            );
                      onChanged();
                    },
                  ),
                ),
              StudioButton(
                key: const ValueKey('environment-new-zone'),
                label: 'Nouvelle zone',
                icon: Icons.add,
                secondary: true,
                onPressed: project.environmentPresets.isEmpty
                    ? null
                    : () async {
                        final preset = await chooseEnvironmentPreset(
                          context,
                          project,
                        );
                        if (context.mounted && preset != null) {
                          run(() => view.environment = commands.create(preset));
                        }
                      },
              ),
              StudioButton(
                label: 'Composer un environnement',
                icon: Icons.forest_outlined,
                secondary: true,
                onPressed: onResources,
              ),
              if (selected != null) ...[
                for (final (tool, label, icon) in const [
                  (EnvironmentPaintTool.brush, 'Pinceau', Icons.brush_outlined),
                  (
                    EnvironmentPaintTool.rectangle,
                    'Rectangle',
                    Icons.crop_square,
                  ),
                  (
                    EnvironmentPaintTool.erase,
                    'Gomme',
                    Icons.cleaning_services_outlined,
                  ),
                ])
                  StudioButton(
                    key: ValueKey('environment-tool-${tool.name}'),
                    label: label,
                    icon: icon,
                    secondary: session!.tool != tool,
                    onPressed: () {
                      session.tool = tool;
                      onChanged();
                    },
                  ),
                StudioButton(
                  key: const ValueKey('environment-preview'),
                  label: 'Voir l’aperçu',
                  icon: Icons.visibility_outlined,
                  secondary: true,
                  onPressed: () => run(() => commands.preview(session!)),
                ),
                StudioButton(
                  key: const ValueKey('environment-apply'),
                  label: 'Appliquer',
                  icon: Icons.check,
                  onPressed: fresh
                      ? () => run(() => commands.apply(session))
                      : null,
                ),
                StudioButton(
                  label: 'Autre répartition',
                  icon: Icons.shuffle,
                  secondary: true,
                  onPressed: () => run(() => commands.changeSeed(session!)),
                ),
                StudioButton(
                  label: 'Retirer la zone',
                  icon: Icons.delete_outline,
                  variant: StudioButtonVariant.quiet,
                  onPressed: () async {
                    final remove = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Retirer cette zone ?'),
                        content: const Text(
                          'La zone et les décors qu’elle a générés seront retirés. Les autres décors et le sol restent en place.',
                        ),
                        actions: [
                          StudioButton(
                            label: 'Annuler',
                            secondary: true,
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          StudioButton(
                            label: 'Retirer la zone',
                            variant: StudioButtonVariant.destructive,
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                    );
                    if (context.mounted && remove == true) {
                      run(() {
                        commands.delete(session!);
                        view.environment = null;
                      });
                    }
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            selected == null
                ? 'Choisissez ou créez une zone. Le sol se peint avec Terrains ; les environnements répartissent des décors.'
                : '${selected.mask.activeCellCount} cases · Pinceau ou rectangle pour ajouter, gomme pour préserver un passage ou un trou. Aperçu puis Appliquer. Enregistrer conserve la zone.',
          ),
          if (fresh)
            Text(
              '${session.generation!.placements.length} décors proposés · aperçu non appliqué.',
            ),
          if (document.error != null)
            StudioNotice(document.error!, isError: true),
        ],
      ),
    );
  }
}

Future<EnvironmentPreset?> chooseEnvironmentPreset(
  BuildContext context,
  ProjectManifest project,
) => showDialog<EnvironmentPreset>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Choisir un environnement'),
    content: SizedBox(
      width: 420,
      height: 280,
      child: ListView(
        children: [
          for (final preset in project.environmentPresets)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: StudioButton(
                label: preset.name,
                secondary: true,
                onPressed: () => Navigator.pop(context, preset),
              ),
            ),
        ],
      ),
    ),
    actions: [
      StudioButton(
        label: 'Annuler',
        secondary: true,
        onPressed: () => Navigator.pop(context),
      ),
    ],
  ),
);
