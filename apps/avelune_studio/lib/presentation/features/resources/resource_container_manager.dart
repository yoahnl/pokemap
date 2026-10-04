import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import 'resource_catalog.dart';
import 'resource_containers.dart';

class ResourceContainerManager extends StatefulWidget {
  const ResourceContainerManager({
    super.key,
    required this.family,
    required this.project,
    required this.onEdit,
    required this.onDelete,
    required this.onSelect,
  });
  final ResourceKind family;
  final ProjectManifest Function() project;
  final Future<void> Function(ResourceContainer? container) onEdit;
  final Future<String?> Function(ResourceContainer container) onDelete;
  final ValueChanged<String> onSelect;

  @override
  State<ResourceContainerManager> createState() =>
      _ResourceContainerManagerState();
}

class _ResourceContainerManagerState extends State<ResourceContainerManager> {
  bool _busy = false;
  String? _error;
  Future<void> _edit(ResourceContainer? entry) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onEdit(entry);
    } on Object catch (failure) {
      _error = '$failure';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(
    ResourceContainer entry,
    int resources,
    int children,
  ) async {
    if (_busy) return;
    final noun = containerTitle(widget.family);
    final article = widget.family == ResourceKind.images ? 'le' : 'la';
    final demonstrative = widget.family == ResourceKind.images ? 'Ce' : 'Cette';
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Supprimer « ${entry.name} » ?'),
        content: Text(
          resources + children == 0
              ? '$demonstrative $noun est vide. Aucune ressource ne sera supprimée.'
              : '$resources ressource(s) et $children sous-conteneur(s). '
                    'Déplacez leur contenu avant de supprimer ${demonstrative.toLowerCase()} $noun.',
        ),
        actions: [
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context, false),
          ),
          if (resources + children > 0)
            StudioButton(
              label: 'Voir le contenu',
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.pop(this.context);
                widget.onSelect(entry.id);
              },
            )
          else
            StudioButton(
              label: 'Supprimer $article $noun vide',
              onPressed: () => Navigator.pop(context, true),
            ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() => _busy = true);
    try {
      _error = await widget.onDelete(entry);
    } on Object catch (failure) {
      _error = '$failure';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project();
    final containers = resourceContainers(project, widget.family);
    final items = resourceCatalog(
      project,
    ).where((item) => item.kind == widget.family).toList();
    final noun = containerTitle(widget.family);
    return PopScope(
      canPop: !_busy,
      child: Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 660,
            maxHeight: MediaQuery.sizeOf(context).height - 40,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Gérer les ${noun}s',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(switch (widget.family) {
                  ResourceKind.images => 'Dossiers des images et tilesets',
                  ResourceKind.decors => 'Catégories des décors',
                  ResourceKind.terrains =>
                    'Catégories des terrains · sans hiérarchie',
                }),
                const SizedBox(height: 12),
                StudioButton(
                  key: const ValueKey('resource-container-create'),
                  label:
                      '${widget.family == ResourceKind.images ? 'Nouveau' : 'Nouvelle'} $noun',
                  icon: Icons.create_new_folder_outlined,
                  onPressed: _busy ? null : () => _edit(null),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Expanded(
                  child: containers.isEmpty
                      ? const Center(
                          child: Text('Aucun conteneur dans cette famille.'),
                        )
                      : ListView.builder(
                          itemCount: containers.length,
                          itemBuilder: (context, index) {
                            final entry = containers[index];
                            final count = items
                                .where((item) => item.category == entry.id)
                                .length;
                            final children = containers
                                .where((value) => value.parentId == entry.id)
                                .length;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: StudioChoice(
                                      key: ValueKey(
                                        'resource-container-${widget.family.name}-${entry.id}',
                                      ),
                                      label: entry.name,
                                      subtitle:
                                          '$count ressource(s) · $children sous-conteneur(s)',
                                      onTap: _busy
                                          ? null
                                          : () {
                                              Navigator.pop(context);
                                              widget.onSelect(entry.id);
                                            },
                                    ),
                                  ),
                                  StudioTool(
                                    key: ValueKey(
                                      'resource-container-edit-${entry.id}',
                                    ),
                                    label: 'Renommer ou déplacer ${entry.name}',
                                    icon: Icons.edit_outlined,
                                    onPressed: _busy
                                        ? null
                                        : () => _edit(entry),
                                  ),
                                  StudioTool(
                                    key: ValueKey(
                                      'resource-container-delete-${entry.id}',
                                    ),
                                    label: 'Supprimer ${entry.name}',
                                    icon: Icons.delete_outline,
                                    onPressed: _busy
                                        ? null
                                        : () => _delete(entry, count, children),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 12),
                StudioButton(
                  label: 'Retour aux ressources',
                  secondary: true,
                  onPressed: _busy ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
