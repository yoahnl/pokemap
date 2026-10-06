import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/application/environment_draft.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_slider.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_workspace_visuals.dart';
part 'environment_editor_palette.dart';
part 'environment_decor_picker.dart';

class EnvironmentEditorScreen extends StatefulWidget {
  const EnvironmentEditorScreen({
    super.key,
    required this.draft,
    required this.project,
    required this.visuals,
    required this.onSave,
    required this.onChanged,
    required this.onClose,
    required this.onDiscard,
    required this.onEditDecor,
  });
  final EnvironmentDraft draft;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final Future<void> Function() onSave;
  final VoidCallback onChanged, onClose, onDiscard;
  final ValueChanged<ProjectElementEntry> onEditDecor;

  @override
  State<EnvironmentEditorScreen> createState() =>
      _EnvironmentEditorScreenState();
}

class _EnvironmentEditorScreenState extends State<EnvironmentEditorScreen> {
  String? error;
  bool saving = false;
  EnvironmentDraft get draft => widget.draft;

  void change(VoidCallback edit) {
    setState(edit);
    widget.onChanged();
  }

  void parameters({
    double? density,
    double? variation,
    double? edge,
    int? spacing,
  }) => change(() {
    draft.params = EnvironmentGenerationParams(
      density: density ?? draft.params.density,
      variation: variation ?? draft.params.variation,
      edgeDensity: edge ?? draft.params.edgeDensity,
      minSpacingCells: spacing ?? draft.params.minSpacingCells,
    );
  });

  Future<void> save() async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.onSave();
    } on Object catch (failure) {
      if (mounted) setState(() => error = '$failure');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> add() async {
    final element = await showDialog<ProjectElementEntry>(
      context: context,
      builder: (context) => _EnvironmentDecorPicker(
        project: widget.project,
        visuals: widget.visuals,
        excluded: draft.palette.map((item) => item.elementId).toSet(),
      ),
    );
    if (mounted && element != null) change(() => draft.add(element.id));
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioPageHeader(
        title: 'Composer un environnement',
        description:
            'Choisissez les décors et leur répartition. La zone se dessine sur Carte.',
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, bounds) {
              final palette = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StudioDraftField(
                    value: draft.name,
                    label: 'Nom de l’environnement',
                    onChanged: (value) => change(() => draft.name = value),
                  ),
                  const SizedBox(height: 16),
                  StudioButton(
                    key: const ValueKey('environment-add-decor'),
                    label: 'Ajouter un décor',
                    icon: Icons.add,
                    secondary: true,
                    onPressed: add,
                  ),
                  const SizedBox(height: 12),
                  if (draft.palette.isEmpty)
                    const Text(
                      'Ajoutez les arbres, fleurs ou autres décors à répartir.',
                    ),
                  for (final item in draft.palette)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: paletteItem(item),
                    ),
                ],
              );
              final settings = StudioPanel(
                children: [
                  Text(
                    'Répartition',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  StudioSlider(
                    label: 'Densité',
                    value: draft.params.density,
                    onChanged: (value) => parameters(density: value),
                  ),
                  StudioSlider(
                    label: 'Densité en bordure',
                    value: draft.params.edgeDensity,
                    onChanged: (value) => parameters(edge: value),
                  ),
                  StudioSlider(
                    label: 'Irrégularité',
                    value: draft.params.variation,
                    onChanged: (value) => parameters(variation: value),
                  ),
                  StudioDraftField(
                    value: draft.spacingInput,
                    label: 'Espacement minimum en cases',
                    onChanged: (value) {
                      change(() => draft.setSpacingInput(value));
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Le poids règle la fréquence relative de chaque décor. L’irrégularité change sa probabilité de présence, sans changer sa taille.',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Le sol reste indépendant. L’eau n’est pas détectée automatiquement : excluez les cases à préserver dans la zone sur Carte.',
                  ),
                ],
              );
              if (bounds.maxWidth < 850 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20) {
                return Column(
                  children: [palette, const SizedBox(height: 16), settings],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: palette),
                  const SizedBox(width: 20),
                  SizedBox(width: 320, child: settings),
                ],
              );
            },
          ),
        ),
      ),
      if (error != null) StudioNotice(error!, isError: true),
      Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          alignment: WrapAlignment.end,
          spacing: 12,
          runSpacing: 8,
          children: [
            StudioButton(
              label: 'Annuler les modifications',
              secondary: true,
              onPressed: saving
                  ? null
                  : () async {
                      final discard = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Annuler cette préparation ?'),
                          content: const Text(
                            'Les modifications de cet environnement seront abandonnées.',
                          ),
                          actions: [
                            StudioButton(
                              label: 'Rester',
                              secondary: true,
                              onPressed: () => Navigator.pop(context, false),
                            ),
                            StudioButton(
                              label: 'Annuler les modifications',
                              variant: StudioButtonVariant.destructive,
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ],
                        ),
                      );
                      if (mounted && discard == true) widget.onDiscard();
                    },
            ),
            StudioButton(
              label: 'Retour à la bibliothèque',
              secondary: true,
              onPressed: saving ? null : widget.onClose,
            ),
            StudioButton(
              key: const ValueKey('environment-save'),
              label: saving ? 'Enregistrement…' : 'Enregistrer l’environnement',
              icon: Icons.save_outlined,
              onPressed: saving ? null : save,
            ),
          ],
        ),
      ),
    ],
  );
}
