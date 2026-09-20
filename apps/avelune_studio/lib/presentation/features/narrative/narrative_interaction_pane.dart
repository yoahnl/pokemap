import 'package:flutter/material.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../../../features/narrative/application/dialogue_editing_controller.dart';
import '../../../features/narrative/application/narrative_editing.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'dialogue_lines_editor.dart';
import 'narrative_conditions_editor.dart';
import 'narrative_sequence_editor.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../../shared/widgets/layout/studio_section.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

class NarrativeInteractionPane extends StatelessWidget {
  const NarrativeInteractionPane({
    super.key,
    required this.controller,
    required this.visuals,
    required this.onBack,
    required this.onTest,
    this.onBackLabel = 'Retour à la carte',
  });
  final NarrativeWorkspaceController controller;
  final MapWorkspaceVisuals visuals;
  final VoidCallback onBack, onTest;
  final String onBackLabel;
  @override
  Widget build(BuildContext context) {
    final edit = controller.active!;
    final interaction = edit.current.interaction;
    final mapName =
        controller.project.maps
            .where((map) => map.id == edit.document.base.mapId)
            .firstOrNull
            ?.name ??
        'Carte courante';
    void changed() => controller.changed();
    final editor = DialogueEditingController(edit, changed);
    final outcomes = {
      for (final b in edit.current.dialogue.branches)
        for (final c in b.choices)
          if (c.outcomeId != null) c.outcomeId!: c.text,
    };
    return Column(
      children: [
        StudioPageHeader(
          title: '${interaction.name}${edit.dirty ? ' •' : ''}',
          description: 'Conversation, conditions et conséquences',
          actions: [
            StudioButton(
              label: onBackLabel,
              secondary: true,
              onPressed: onBack,
            ),
            StudioButton(
              label: 'Annuler le dialogue',
              secondary: true,
              onPressed: edit.canUndo
                  ? () {
                      edit.restore(redo: false);
                      changed();
                    }
                  : null,
            ),
            StudioButton(
              label: 'Rétablir le dialogue',
              secondary: true,
              onPressed: edit.canRedo
                  ? () {
                      edit.restore(redo: true);
                      changed();
                    }
                  : null,
            ),
            StudioButton(
              label: 'Enregistrer l’interaction et la carte',
              onPressed: controller.busy || !edit.editable
                  ? null
                  : () => controller.save(),
            ),
            StudioButton(
              label: 'Enregistrer et tester',
              secondary: true,
              onPressed: controller.busy ? null : onTest,
            ),
          ],
        ),
        Expanded(
          child: ListView(
            key: ValueKey(edit.current.interaction.id),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Text(
                'Conversation et petite scène',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(
                'Carte : $mapName · ${interaction.source.toJson()['kind'] == 'entityInteract' ? 'Interaction avec un personnage' : 'Entrée dans une zone'}',
              ),
              const SizedBox(height: 16),
              if (!edit.editable) ...[
                const Text(
                  'Ce dialogue contient des instructions avancées. Sa source est conservée en lecture seule.',
                ),
                SelectableText(edit.readOnlySource!),
              ] else ...[
                StudioDraftField(
                  value: interaction.name,
                  label: 'Nom de l’interaction',
                  onChanged: (v) {
                    edit.change(interaction: interaction.revise(name: v));
                    changed();
                  },
                ),
                const SizedBox(height: 16),
                StudioPanel(
                  title: 'Dialogue',
                  children: [
                    DialogueLinesEditor(
                      editor: editor,
                      project: controller.project,
                      visuals: visuals,
                    ),
                  ],
                ),
                const Divider(height: 32),
                StudioSection(
                  collapsible: true,
                  title: 'Conditions et répétition',
                  initiallyExpanded: true,
                  children: [
                    NarrativeConditionsEditor(
                      controller: controller,
                      conditions: interaction.conditions,
                      onChanged: (v) {
                        edit.change(
                          interaction: interaction.revise(conditions: v),
                        );
                        changed();
                      },
                    ),
                    StudioToggleRow(
                      label: 'Jouer une seule fois',
                      description:
                          'La progression est enregistrée dans la partie de test.',
                      value: interaction.oneShot,
                      onChanged: (v) {
                        edit.change(
                          interaction: interaction.revise(oneShot: v),
                        );
                        changed();
                      },
                    ),
                    StudioDraftField(
                      value: '${interaction.priority}',
                      label:
                          'Priorité si plusieurs conversations conviennent (plus élevée en premier)',
                      onChanged: (v) {
                        final p = int.tryParse(v);
                        if (p != null) {
                          edit.change(
                            interaction: interaction.revise(priority: p),
                          );
                          changed();
                        }
                      },
                    ),
                  ],
                ),
                StudioSection(
                  collapsible: true,
                  initiallyExpanded: false,
                  title: 'Après la conversation',
                  children: [
                    NarrativeSequenceEditor(
                      controller: controller,
                      steps: interaction.steps,
                      onChanged: (v) {
                        edit.change(interaction: interaction.revise(steps: v));
                        changed();
                      },
                    ),
                  ],
                ),
                for (final outcome in outcomes.entries)
                  StudioSection(
                    collapsible: true,
                    initiallyExpanded: false,
                    key: ValueKey(outcome.key),
                    title: 'Après le choix « ${outcome.value} »',
                    children: [
                      NarrativeSequenceEditor(
                        controller: controller,
                        steps: interaction.branches[outcome.key] ?? [],
                        onChanged: (v) {
                          edit.change(
                            interaction: interaction.revise(
                              branches: {
                                ...interaction.branches,
                                outcome.key: v,
                              },
                            ),
                          );
                          changed();
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                StudioButton(
                  label: 'Ajouter une conversation conditionnelle',
                  secondary: true,
                  onPressed: () => controller.openSource(
                    edit.document,
                    interaction.source,
                    '${interaction.name} · variante',
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
