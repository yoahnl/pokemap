import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/pokemon/application/pokemon_commerce_controller.dart';
import '../../../features/pokemon/application/pokemon_workspace_controller.dart';
import '../../../features/pokemon/domain/pokemon_workspace_models.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'pokemon_commerce_detail.dart';
import 'pokemon_commerce_import_button.dart';
import 'pokemon_commerce_create_dialog.dart';
import 'pokemon_commerce_row.dart';
import 'pokemon_ui_parts.dart';

class PokemonCommercePage extends StatefulWidget {
  const PokemonCommercePage({
    super.key,
    required this.controller,
    required this.commerce,
    this.pickJson,
    this.onOpenReference,
  });

  final PokemonWorkspaceController controller;
  final PokemonCommerceController commerce;
  final Future<String?> Function()? pickJson;
  final Future<void> Function(String kind, String id)? onOpenReference;

  @override
  State<PokemonCommercePage> createState() => _PokemonCommercePageState();
}

class _PokemonCommercePageState extends State<PokemonCommercePage> {
  late final itemSearch = TextEditingController(
    text: widget.commerce.itemSearch,
  );
  late final shopSearch = TextEditingController(
    text: widget.commerce.shopSearch,
  );
  bool compactDetail = false;

  @override
  void dispose() {
    itemSearch.dispose();
    shopSearch.dispose();
    super.dispose();
  }

  Future<void> _create(bool items) async {
    final id = await showPokemonCommerceCreateDialog(context, items: items);
    if (!mounted || id == null) return;
    final created = items
        ? widget.commerce.createItem(id)
        : widget.commerce.createShop(id);
    if (created) setState(() => compactDetail = true);
  }

  void _selectItem(ProjectItemDefinition value) {
    if (!widget.commerce.selectItem(value)) {
      _blocked();
      return;
    }
    setState(() => compactDetail = true);
  }

  void _selectShop(ShopDefinition value) {
    if (!widget.commerce.selectShop(value)) {
      _blocked();
      return;
    }
    widget.controller.setView(PokemonWorkspaceView.shops);
    setState(() => compactDetail = true);
  }

  void _blocked() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Enregistrez ou annulez la fiche en cours.')),
  );

  @override
  Widget build(BuildContext context) {
    final commerce = widget.commerce;
    final items = widget.controller.view == PokemonWorkspaceView.items;
    if (commerce.loading && commerce.snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (commerce.snapshot == null) {
      return PokemonEmptyState(
        title: 'Lecture impossible',
        description: commerce.error ?? 'Le catalogue ne peut pas être lu.',
        icon: Icons.error_outline,
        action: StudioButton(label: 'Réessayer', onPressed: commerce.load),
      );
    }
    return LayoutBuilder(
      builder: (context, bounds) {
        final compact =
            bounds.maxWidth < 900 ||
            MediaQuery.textScalerOf(context).scale(14) > 20;
        final showDetail = items
            ? commerce.item != null
            : commerce.shop != null;
        return Column(
          children: [
            if (commerce.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: PokemonSurface(child: Text(commerce.error!)),
              ),
            if (commerce.notice != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: PokemonSurface(child: Text(commerce.notice!)),
              ),
            Expanded(
              child: compact && compactDetail && showDetail
                  ? PokemonCommerceDetail(
                      commerce: commerce,
                      items: items,
                      onBack: () => setState(() => compactDetail = false),
                      onOpenShop: _selectShop,
                      onOpenReference: widget.onOpenReference,
                    )
                  : Row(
                      children: [
                        SizedBox(
                          width: compact
                              ? bounds.maxWidth
                              : (bounds.maxWidth * .29).clamp(290, 370),
                          child: _library(items),
                        ),
                        if (!compact) ...[
                          const VerticalDivider(width: 1),
                          Expanded(
                            child: PokemonCommerceDetail(
                              commerce: commerce,
                              items: items,
                              onOpenShop: _selectShop,
                              onOpenReference: widget.onOpenReference,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _library(bool items) {
    final commerce = widget.commerce;
    final catalog = commerce.snapshot!.catalog;
    final entries = items ? commerce.visibleItems : commerce.visibleShops;
    final total = items
        ? catalog?.entries.length ?? 0
        : commerce.snapshot!.shops.length;
    final pockets = <String>{
      for (final item in catalog?.entries ?? const <ProjectItemDefinition>[])
        item.pocketId,
    };
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PokemonSectionHeading(
              title: '${items ? 'Objets' : 'Boutiques'} · $total',
              description: items
                  ? 'Les objets utilisables par le projet.'
                  : 'Les catalogues de vente du projet.',
            ),
            StudioSearchField(
              controller: items ? itemSearch : shopSearch,
              label: items ? 'Rechercher un objet' : 'Rechercher une boutique',
              onChanged: (value) {
                setState(() {
                  if (items) {
                    commerce.itemSearch = value;
                  } else {
                    commerce.shopSearch = value;
                  }
                });
              },
            ),
            if (items && pockets.isNotEmpty) ...[
              const SizedBox(height: 9),
              StudioSelect(
                label: 'Poche',
                value: commerce.pocketFilter ?? '',
                options: {
                  '': 'Toutes les poches',
                  for (final pocket in pockets.toList()..sort()) pocket: pocket,
                },
                onChanged: (value) => setState(
                  () => commerce.pocketFilter = value.isEmpty ? null : value,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (items && commerce.snapshot!.problem != null)
              PokemonSurface(child: Text(commerce.snapshot!.problem!)),
            if (items &&
                commerce.item != null &&
                !commerce.visibleItems.any(
                  (entry) => entry.id == commerce.item!.id,
                ))
              const PokemonSurface(
                child: Text('La fiche ouverte est masquée par les filtres.'),
              ),
            Expanded(
              child: entries.isEmpty
                  ? PokemonEmptyState(
                      title: total == 0
                          ? 'Aucun ${items ? 'objet' : 'catalogue de boutique'}'
                          : 'Aucun résultat',
                      description: total == 0
                          ? 'Créez une première fiche pour commencer.'
                          : 'Essayez une autre recherche ou un autre filtre.',
                      icon: items
                          ? Icons.inventory_2_outlined
                          : Icons.storefront_outlined,
                    )
                  : ListView.builder(
                      key: PageStorageKey(
                        items ? 'commerce-items' : 'commerce-shops',
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        if (items) {
                          final entry = entries[index] as ProjectItemDefinition;
                          return PokemonCommerceRow(
                            key: ValueKey('item-${entry.id}'),
                            title: entry.displayName,
                            subtitle:
                                '${entry.pocketId} · ${entry.buyPrice == null ? 'Prix libre' : '${entry.buyPrice} ₽'}',
                            icon: Icons.inventory_2_outlined,
                            selected: commerce.item?.id == entry.id,
                            onTap: () => _selectItem(entry),
                          );
                        }
                        final entry = entries[index] as ShopDefinition;
                        return PokemonCommerceRow(
                          key: ValueKey('shop-${entry.id}'),
                          title: entry.label,
                          subtitle:
                              '${entry.entries.length} objet(s) · ${entry.states.length} état(s)',
                          icon: Icons.storefront_outlined,
                          selected: commerce.shop?.id == entry.id,
                          onTap: () => _selectShop(entry),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StudioButton(
                    label: items ? 'Créer un objet' : 'Créer une boutique',
                    icon: Icons.add,
                    onPressed: commerce.saving || (items && catalog == null)
                        ? null
                        : () => _create(items),
                  ),
                  if (widget.pickJson != null)
                    PokemonCommerceImportButton(
                      commerce: commerce,
                      items: items,
                      pickJson: widget.pickJson!,
                      onImported: () => setState(() => compactDetail = true),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
