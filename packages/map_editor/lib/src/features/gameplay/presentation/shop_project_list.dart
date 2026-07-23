import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';

class ShopProjectList extends StatefulWidget {
  const ShopProjectList({
    super.key,
    required this.shops,
    required this.selectedShopId,
    required this.onSelect,
    required this.onCreate,
    required this.onDelete,
  });

  final List<ShopDefinition> shops;
  final String? selectedShopId;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onCreate;
  final VoidCallback? onDelete;

  @override
  State<ShopProjectList> createState() => _ShopProjectListState();
}

class _ShopProjectListState extends State<ShopProjectList> {
  final _searchController = TextEditingController();
  final _createController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _createController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final visibleShops = widget.shops
        .where(
          (shop) =>
              normalizedQuery.isEmpty ||
              shop.label.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);
    return PokeMapPanel(
      key: const Key('shop-project-list'),
      expandChild: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
        child: PokeMapSectionHeader(
          title: 'Boutiques',
          description: '${widget.shops.length} dans le projet',
          trailing: PokeMapIconButton(
            key: const Key('shop-delete-button'),
            onPressed: widget.onDelete,
            icon: const Icon(CupertinoIcons.delete),
            tooltip: 'Supprimer la boutique',
            variant: PokeMapIconButtonVariant.danger,
          ),
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PokeMapTextField(
                label: 'Nouvelle boutique',
                fieldKey: const Key('shop-create-label-field'),
                controller: _createController,
                hintText: 'Ex. Boutique du Port',
                onSubmitted: _create,
              ),
            ),
            const SizedBox(width: 6),
            PokeMapIconButton(
              key: const Key('shop-create-button'),
              onPressed: () => _create(_createController.text),
              icon: const Icon(CupertinoIcons.add),
              tooltip: 'Créer la boutique',
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: PokeMapTextField(
              label: 'Rechercher',
              controller: _searchController,
              hintText: 'Nom de boutique',
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: visibleShops.isEmpty
                ? const PokeMapEmptyState(
                    title: 'Aucune boutique',
                    description: 'Créez ou recherchez une boutique du projet.',
                    icon: Icon(CupertinoIcons.cart),
                  )
                : ListView.separated(
                    key: const Key('shop-editor-list'),
                    padding: const EdgeInsets.all(8),
                    itemCount: visibleShops.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final shop = visibleShops[index];
                      return PokeMapCard(
                        key: Key('shop-card-${shop.id}'),
                        selected: shop.id == widget.selectedShopId,
                        onTap: () => widget.onSelect(shop.id),
                        child: Row(
                          children: [
                            const Icon(CupertinoIcons.cart, size: 17),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.pokeMapColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    '${shop.states.length} état(s) · '
                                    '${shop.entries.length} objet(s)',
                                    style: TextStyle(
                                      color: context.pokeMapColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _create(String value) {
    widget.onCreate(value);
    _createController.clear();
  }
}
