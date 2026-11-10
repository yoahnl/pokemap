import 'package:flutter/material.dart';

import '../../../features/resources/application/resource_usage_replacement_controller.dart';
import '../../../features/resources/coordination/resource_replacement_workflow.dart';
import '../../../features/resources/domain/resource_usage_port.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import 'resource_management_dialog.dart';

import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';

Future<String?> replaceResourceUsages(
  BuildContext context,
  ResourceNavigation navigation, {
  required ResourceUsageTarget target,
  required String name,
}) => runResourceUsageReplacement(
  navigation: navigation,
  target: target,
  name: name,
  isActive: () => context.mounted,
  present: (controller) => showResourceManagementRoute(
    context,
    (_) => ResourceUsageReplacementDialog(
      controller: controller,
      mapName: (id) =>
          navigation.workspace.project?.maps
              .where((map) => map.id == id)
              .firstOrNull
              ?.name ??
          id,
    ),
  ),
);

class ResourceUsageReplacementDialog extends StatefulWidget {
  const ResourceUsageReplacementDialog({
    super.key,
    required this.controller,
    required this.mapName,
  });

  final ResourceUsageReplacementController controller;
  final String Function(String mapId) mapName;

  @override
  State<ResourceUsageReplacementDialog> createState() =>
      _ResourceUsageReplacementDialogState();
}

class _ResourceUsageReplacementDialogState
    extends State<ResourceUsageReplacementDialog> {
  final _query = TextEditingController();
  ResourceUsageReplacementController get controller => widget.controller;

  @override
  void dispose() {
    controller.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _choose(ResourceItem choice, VoidCallback refresh) async {
    final pending = controller.choose(choice);
    setState(() {});
    refresh();
    await pending;
    if (mounted) {
      setState(() {});
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _query.text.trim().toLowerCase();
    final choices = [
      for (final choice in controller.choices)
        if (query.isEmpty || choice.name.toLowerCase().contains(query)) choice,
    ];
    final prepared = controller.preparation;
    final empty = prepared != null && prepared.noChange;
    return ResourceManagementDialog(
      title: 'Remplacer ses usages',
      submitLabel: empty ? 'Aucun usage à remplacer' : 'Remplacer les usages',
      maxWidth: 640,
      dirty: () => false,
      valid: () => controller.canApply,
      submit: controller.apply,
      fields: (refresh, busy) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(controller.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Toutes les occurrences de cette ressource sur les cartes pointeront '
            'vers la ressource choisie. Leur position est conservée et aucune '
            'définition n’est modifiée.',
          ),
          Text(
            'Pour une seule occurrence, utilisez « Remplacer ici » dans la carte. '
            'Pour changer l’apparence partout sans changer de ressource, utilisez '
            '« Modifier la définition ».',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          StudioSearchField(
            key: const ValueKey('resource-usage-replacement-search'),
            controller: _query,
            label: 'Rechercher la ressource de remplacement',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: choices.isEmpty
                ? const Center(
                    child: Text('Aucune ressource compatible ne correspond.'),
                  )
                : ListView.builder(
                    itemCount: choices.length,
                    itemBuilder: (context, index) {
                      final choice = choices[index];
                      return StudioChoice(
                        key: ValueKey(
                          'resource-usage-replacement-${choice.id}',
                        ),
                        label: choice.name,
                        subtitle: choice.category.isEmpty
                            ? null
                            : choice.category,
                        selected: controller.replacement?.id == choice.id,
                        leading: Icon(
                          controller.spatial
                              ? Icons.view_in_ar_outlined
                              : Icons.image_outlined,
                          size: 18,
                        ),
                        onTap: busy || controller.preparing
                            ? null
                            : () => _choose(choice, refresh),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          if (controller.preparing) ...[
            const Text('Calcul de la portée…'),
            const LinearProgressIndicator(),
          ] else if (controller.error != null)
            Text(
              controller.error!,
              key: const ValueKey('resource-usage-replacement-error'),
              style: TextStyle(color: theme.colorScheme.error),
            )
          else if (prepared == null)
            const Text('Choisissez la ressource de remplacement.')
          else if (empty)
            const Text(
              'Aucune occurrence sur les cartes : rien ne sera modifié.',
            )
          else ...[
            Text(
              'Portée : ${controller.summary}',
              key: const ValueKey('resource-usage-replacement-scope'),
              style: theme.textTheme.titleSmall,
            ),
            for (final entry in controller.scope)
              Text(
                'Carte « ${widget.mapName(entry.mapId)} » · '
                '${entry.count} ${entry.count == 1 ? 'occurrence' : 'occurrences'}',
              ),
            Text(
              'Les cartes non listées et les définitions restent intactes.',
              style: theme.textTheme.bodySmall,
            ),
            CheckboxListTile(
              key: const ValueKey('resource-usage-replacement-confirm'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Je confirme : « ${controller.name} » devient '
                '« ${controller.replacement!.name} » sur ces cartes.',
              ),
              value: controller.confirmed,
              onChanged: busy
                  ? null
                  : (value) {
                      setState(() => controller.confirm(value == true));
                      refresh();
                    },
            ),
          ],
        ],
      ),
    );
  }
}
