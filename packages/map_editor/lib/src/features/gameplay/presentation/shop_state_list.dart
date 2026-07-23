import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/shop_editor_controller.dart';

class ShopStateList extends StatelessWidget {
  const ShopStateList({
    super.key,
    required this.shop,
    required this.selectedStateId,
    required this.onSelect,
    required this.onCreateFromDefault,
    required this.onCreateEmpty,
    required this.onDuplicate,
    required this.onDelete,
  });

  final ShopDefinition shop;
  final String selectedStateId;
  final ValueChanged<String> onSelect;
  final VoidCallback onCreateFromDefault;
  final VoidCallback onCreateEmpty;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const Key('shop-state-list'),
      expandChild: true,
      header: const Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: PokeMapSectionHeader(
          title: 'États',
          description: 'Priorité et progression',
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PokeMapButton(
              key: const Key('shop-state-create-from-default'),
              onPressed: onCreateFromDefault,
              size: PokeMapButtonSize.compact,
              leading: const Icon(CupertinoIcons.doc_on_doc),
              child: const Text('Copier l’état par défaut'),
            ),
            const SizedBox(height: 6),
            PokeMapButton(
              key: const Key('shop-state-create-empty'),
              onPressed: onCreateEmpty,
              size: PokeMapButtonSize.compact,
              variant: PokeMapButtonVariant.secondary,
              leading: const Icon(CupertinoIcons.add),
              child: const Text('Créer un état vide'),
            ),
          ],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          PokeMapCard(
            key: const Key('shop-state-default'),
            selected: selectedStateId == ShopEditorController.defaultStateId,
            onTap: () => onSelect(ShopEditorController.defaultStateId),
            child: _StateSummary(
              label: 'État par défaut',
              details: '${shop.entries.length} objet(s)',
              badge: 'Toujours',
            ),
          ),
          const SizedBox(height: 8),
          for (final state in [...shop.states]
            ..sort((a, b) => b.priority.compareTo(a.priority))) ...[
            PokeMapCard(
              key: Key('shop-state-${state.id}'),
              selected: selectedStateId == state.id,
              onTap: () => onSelect(state.id),
              child: _StateSummary(
                label: state.label,
                details: '${state.entries.length} objet(s)',
                badge: 'Priorité ${state.priority}',
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (selectedStateId != ShopEditorController.defaultStateId) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: PokeMapButton(
                    key: const Key('shop-state-duplicate'),
                    onPressed: onDuplicate,
                    size: PokeMapButtonSize.compact,
                    variant: PokeMapButtonVariant.ghost,
                    child: const Text('Dupliquer'),
                  ),
                ),
                const SizedBox(width: 6),
                PokeMapIconButton(
                  key: const Key('shop-state-delete'),
                  onPressed: onDelete,
                  icon: const Icon(CupertinoIcons.delete),
                  tooltip: 'Supprimer cet état',
                  variant: PokeMapIconButtonVariant.danger,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StateSummary extends StatelessWidget {
  const _StateSummary({
    required this.label,
    required this.details,
    required this.badge,
  });

  final String label;
  final String details;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.pokeMapColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            PokeMapBadge(label: badge, variant: PokeMapBadgeVariant.info),
            Text(
              details,
              style: TextStyle(
                color: context.pokeMapColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
