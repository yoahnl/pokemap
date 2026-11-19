import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'resource_library_items.dart';
import 'resource_library_view_data.dart';

class ResourceLibraryInspector extends StatelessWidget {
  const ResourceLibraryInspector({
    super.key,
    required this.item,
    required this.maps,
    required this.source,
    required this.consumers,
    required this.onRelated,
    required this.onClose,
    this.preview,
    this.previewActions = false,
  });

  final ResourceLibraryItemView item;
  final Map<String, String> maps;
  final ResourceLibraryItemView? source;
  final List<ResourceLibraryItemView> consumers;
  final ValueChanged<ResourceLibraryItemView> onRelated;
  final VoidCallback onClose;
  final Widget? preview;
  final bool previewActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.xl,
              vertical: StudioSpacing.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Détails', style: theme.textTheme.titleMedium),
                ),
                StudioTool(
                  label: 'Masquer le panneau de détails',
                  icon: Icons.close,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(StudioSpacing.xl),
              children: [
                ResourceLibraryArt(item: item, height: 154, preview: preview),
                const SizedBox(height: StudioSpacing.xl),
                Text(item.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: StudioSpacing.xs),
                Text(item.type, style: theme.textTheme.bodySmall),
                const SizedBox(height: StudioSpacing.l),
                if (previewActions)
                  const Wrap(
                    spacing: StudioSpacing.m,
                    runSpacing: StudioSpacing.m,
                    children: [
                      StudioButton(
                        label: 'Modifier',
                        icon: Icons.edit_outlined,
                        onPressed: null,
                      ),
                      StudioTool(
                        label: 'Dupliquer',
                        icon: Icons.copy_outlined,
                        onPressed: null,
                      ),
                      StudioTool(
                        label: 'Supprimer',
                        icon: Icons.delete_outline,
                        onPressed: null,
                      ),
                    ],
                  ),
                if (item.description case final description?) ...[
                  const SizedBox(height: StudioSpacing.l),
                  Text(description, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: StudioSpacing.xl),
                const Divider(),
                const SizedBox(height: StudioSpacing.m),
                _property('Catégorie', item.category.label),
                if (item.familyPath case final path?)
                  _property('Famille', path),
                if (item.dimension case final dimension?)
                  _property('Compatibilité', dimension.label),
                if (item.collision case final collision?)
                  _property('Collision', collision),
                if (item.animationCount case final animationCount?)
                  _property('Animations', '$animationCount'),
                const SizedBox(height: StudioSpacing.xl),
                const Divider(),
                const SizedBox(height: StudioSpacing.l),
                Text(
                  item.usedOn == null
                      ? 'Disponibilité'
                      : 'Utilisation dans les cartes',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: StudioSpacing.m),
                if (item.usedOn?.isNotEmpty != true)
                  Text(item.usageLabel(maps), style: theme.textTheme.bodySmall),
                for (final id in item.usedOn ?? const <String>{})
                  Padding(
                    padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: StudioBadge(
                        maps[id] ?? 'Carte de démonstration',
                        icon: Icons.map_outlined,
                      ),
                    ),
                  ),
                if (source case final associated?) ...[
                  const SizedBox(height: StudioSpacing.xl),
                  Text('Source associée', style: theme.textTheme.titleSmall),
                  const SizedBox(height: StudioSpacing.m),
                  _relatedButton(associated),
                ],
                if (consumers.isNotEmpty) ...[
                  const SizedBox(height: StudioSpacing.xl),
                  Text(
                    'Ressources qui utilisent ce fichier',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: StudioSpacing.m),
                  for (final consumer in consumers) _relatedButton(consumer),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _relatedButton(ResourceLibraryItemView target) => StudioButton(
    key: ValueKey('library-source-${target.id}'),
    label: target.name,
    icon: Icons.link,
    secondary: true,
    onPressed: () => onRelated(target),
  );

  Widget _property(String name, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: StudioSpacing.xs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(name)),
        const SizedBox(width: StudioSpacing.m),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}
