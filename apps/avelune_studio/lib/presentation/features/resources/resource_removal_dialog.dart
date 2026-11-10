import 'package:flutter/material.dart';

import '../../../features/resources/application/resource_removal_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_management_dialog.dart';

class ResourceRemovalDialog extends StatefulWidget {
  const ResourceRemovalDialog({
    super.key,
    required this.controller,
    required this.preview,
    required this.openUsages,
  });
  final ResourceRemovalController controller;
  final Widget preview;
  final VoidCallback openUsages;

  @override
  State<ResourceRemovalDialog> createState() => _ResourceRemovalDialogState();
}

class _ResourceRemovalDialogState extends State<ResourceRemovalDialog> {
  ResourceRemovalController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _prepare() => _update(controller.prepare);

  Future<void> _update(Future<void> Function() operation) async {
    final pending = operation();
    setState(() {});
    await pending;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final image = controller.item.tileset != null;
    return ResourceManagementDialog(
      title: image
          ? 'Supprimer la planche'
          : 'Supprimer la définition de décor',
      submitLabel: image ? 'Supprimer la planche' : 'Supprimer la définition',
      dirty: () => false,
      valid: () => controller.canApply,
      submit: controller.apply,
      fields: (refresh, busy) {
        final dirty = controller.dirtyOwners();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 140, child: widget.preview),
            const SizedBox(height: 12),
            Text(
              controller.item.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(
              '${image ? 'Définition de planche' : 'Définition de décor'} : '
              '${controller.item.id}',
            ),
            const SizedBox(height: 12),
            Text(
              image
                  ? 'Seule cette planche est retirée. Aucun décor, terrain, '
                        'personnage ou placement n’est supprimé.'
                  : 'Seule cette définition est retirée. Les images, catégories '
                        'et instances ne sont jamais supprimées en cascade.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Les blobs partagés et versions historiques nécessaires sont '
              'conservés. Cette action ne promet aucune collecte de pixels.',
            ),
            if (image)
              CheckboxListTile(
                key: const ValueKey('resource-removal-source'),
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Supprimer aussi le fichier source inutilisé',
                ),
                subtitle: Text(_sourceRemovalMessage()),
                value: controller.removeSource,
                onChanged:
                    busy ||
                        controller.working ||
                        (!controller.sourceRemovalSupported &&
                            !controller.removeSource)
                    ? null
                    : (value) {
                        _update(
                          () => controller.selectRemoveSource(value == true),
                        );
                      },
              ),
            if (controller.working) const LinearProgressIndicator(),
            if (controller.error != null) ...[
              const SizedBox(height: 12),
              Text(
                'Suppression refusée : ${controller.error}',
                key: const ValueKey('resource-removal-refusal'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (dirty.isNotEmpty)
              Text(
                'Brouillons à résoudre avant suppression : ${dirty.join(' · ')}',
              ),
            if (controller.preparation != null) ...[
              const SizedBox(height: 12),
              Text('Analyse canonique prête pour la révision identifiée.'),
              SelectableText(
                'Révision : ${controller.preparation!.snapshotRevision}',
              ),
              Text(
                '${controller.preparation!.changedPaths.length} document(s) concernés.',
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StudioButton(
                  label: 'Voir les usages dans le projet',
                  secondary: true,
                  icon: Icons.account_tree_outlined,
                  onPressed: busy || controller.working
                      ? null
                      : widget.openUsages,
                ),
                StudioButton(
                  label: 'Réanalyser',
                  secondary: true,
                  onPressed: busy || controller.working ? null : _prepare,
                ),
              ],
            ),
            CheckboxListTile(
              key: const ValueKey('resource-removal-confirm'),
              contentPadding: EdgeInsets.zero,
              title: Text(
                controller.preparation?.impact['sourceRemoved'] == true
                    ? 'Je confirme le retrait de la définition et de sa source logique.'
                    : 'Je confirme le retrait de cette définition.',
              ),
              value: controller.confirmed,
              onChanged:
                  busy ||
                      controller.working ||
                      controller.preparation == null ||
                      dirty.isNotEmpty
                  ? null
                  : (value) {
                      controller.confirm(value == true);
                      refresh();
                    },
            ),
          ],
        );
      },
    );
  }

  String _sourceRemovalMessage() {
    if (controller.working) {
      return 'Analyse du choix en cours ; rien n’est supprimé.';
    }
    if (controller.preparation?.impact['sourceRemoved'] == true) {
      return controller.preparation!.impact['logicalFileRemoved'] == true
          ? 'La source logique et son fichier seront retirés. Le blob est conservé.'
          : 'La source logique sera retirée. Son fichier adressé par contenu est conservé.';
    }
    if (controller.removeSource) {
      return 'Aucun retrait préparé. Décochez pour conserver la source ou réanalysez.';
    }
    return controller.sourceRemovalReason ??
        (controller.sourceRemovalSupported
            ? 'La source reste conservée ; cochez pour analyser son retrait.'
            : 'Le fichier source restera intact.');
  }
}
