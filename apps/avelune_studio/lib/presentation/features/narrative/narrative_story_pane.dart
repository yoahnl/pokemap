import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/narrative/application/narrative_interaction.dart';
import '../../../features/narrative/application/narrative_interaction_reader.dart';
import '../../../features/narrative/application/narrative_workspace_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'narrative_name_dialog.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_section.dart';

typedef _Interaction = ({String id, String name, NarrativeEventRecord? record});

class NarrativeStoryPane extends StatelessWidget {
  const NarrativeStoryPane({
    super.key,
    required this.controller,
    required this.onOpen,
  });
  final NarrativeWorkspaceController controller;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final query = controller.search.toLowerCase();
    final records = controller.project.eventRegistry?.records ?? [];
    final interactions = <_Interaction>[
      for (final record in records)
        (
          id: record.id,
          name:
              controller.sessions[record.id]?.current.interaction.name ??
              record.definitionOrNull?.name ??
              'Interaction avancée',
          record: record,
        ),
      for (final edit in controller.sessions.values)
        if (!records.any((r) => r.id == edit.current.interaction.id))
          (
            id: edit.current.interaction.id,
            name: '${edit.current.interaction.name} · brouillon',
            record: null,
          ),
    ];
    final links = <String, List<_Interaction>>{};
    for (final item in interactions) {
      final draft =
          controller.sessions[item.id]?.current.interaction ??
          (item.record == null
              ? null
              : readStudioInteraction(item.record!, controller.project));
      if (draft == null) continue;
      final stepIds = {
        for (final step in [
          ...draft.steps,
          ...draft.branches.values.expand((s) => s),
        ])
          if (step.kind == NarrativeSequenceKind.completeStep) step.targetId,
      };
      for (final id in stepIds) {
        links.putIfAbsent(id, () => []).add(item);
      }
    }
    final entries = <WidgetBuilder>[
      (_) => _header(context),
      if (controller.error case final error?)
        (_) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(error),
        ),
      for (final story in controller.stories)
        if (story.title.toLowerCase().contains(query) ||
            story.chapters
                .expand((c) => c.steps)
                .any((s) => s.title.toLowerCase().contains(query))) ...[
          (_) => StudioSection(title: story.title, children: const []),
          for (final step in story.chapters.expand((c) => c.steps))
            if (story.title.toLowerCase().contains(query) ||
                step.title.toLowerCase().contains(query))
              (_) => StudioChoice(
                leading: const Icon(Icons.radio_button_unchecked),
                label: step.title,
                subtitle:
                    links[step.id]?.map((i) => i.name).join(' · ') ??
                    'Aucune interaction liée : ouvrir une conversation pour y ajouter cette étape.',
                onTap: () => _openStep(
                  context,
                  step.title,
                  links[step.id] ?? interactions,
                ),
              ),
        ],
      (_) => const Divider(),
      for (final item in interactions.where(
        (i) => i.name.toLowerCase().contains(query),
      ))
        (_) => StudioChoice(
          label: item.name,
          leading: const Icon(Icons.chat_bubble_outline),
          onTap: () => _open(context, item),
        ),
      if (interactions.isEmpty)
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Placez un personnage, puis ouvrez sa conversation. Vous pouvez aussi dessiner une zone d’histoire sur la carte.',
          ),
        ),
    ];
    return ListView.builder(
      key: const PageStorageKey('narrative-story'),
      padding: const EdgeInsets.all(24),
      itemCount: entries.length,
      itemBuilder: (context, i) => entries[i](context),
    );
  }

  Future<void> _open(BuildContext context, _Interaction item) async {
    final local = controller.sessions[item.id];
    final opened = local != null
        ? await controller.openSession(local)
        : item.record != null && await controller.openRecord(item.record!);
    if (opened && context.mounted) onOpen();
  }

  Future<void> _openStep(
    BuildContext context,
    String title,
    List<_Interaction> items,
  ) async {
    if (items.length == 1) return _open(context, items.single);
    final selected = await showDialog<_Interaction>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          height: 280,
          child: items.isEmpty
              ? const Text(
                  'Créez une conversation depuis un personnage ou une zone, puis ajoutez « Terminer une étape » à sa séquence.',
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(items[i].name),
                    onTap: () => Navigator.pop(context, items[i]),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
    if (selected != null && context.mounted) await _open(context, selected);
  }

  Widget _header(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Histoire', style: Theme.of(context).textTheme.headlineSmall),
      const Text(
        'Définitions du projet. La progression jouée reste propre à chaque partie.',
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StudioButton(
            label: 'Créer une petite histoire',
            secondary: true,
            onPressed: () async {
              final title = await askNarrativeName(
                context,
                'Nom de l’histoire',
              );
              if (title == null || !context.mounted) return;
              final steps = await askNarrativeName(
                context,
                'Étapes, une par ligne',
                multiline: true,
              );
              if (steps != null) controller.addStory(title, steps.split('\n'));
            },
          ),
          StudioButton(
            label: 'Créer un état',
            secondary: true,
            onPressed: () async {
              final name = await askNarrativeName(context, 'Nom de l’état');
              if (name != null) controller.addFact(name);
            },
          ),
          StudioButton(
            label: 'Enregistrer l’histoire',
            onPressed: controller.busy ? null : controller.saveAll,
          ),
        ],
      ),
      const SizedBox(height: 12),
      StudioDraftField(
        value: controller.search,
        label: 'Rechercher une histoire ou une interaction',
        onChanged: (value) {
          controller.search = value;
          controller.changed();
        },
      ),
    ],
  );
}
