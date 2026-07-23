import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/shop_editor_controller.dart';

class ShopEditorPanel extends StatefulWidget {
  const ShopEditorPanel({
    super.key,
    required this.controller,
    required this.onManifestChanged,
  });

  final ShopEditorController controller;
  final ValueChanged<ProjectManifest> onManifestChanged;

  @override
  State<ShopEditorPanel> createState() => _ShopEditorPanelState();
}

class _ShopEditorPanelState extends State<ShopEditorPanel> {
  final _createLabelController = TextEditingController();
  final _renameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String? _selectedShopId;
  String? _selectedItemId;
  String? _editingItemId;
  String? _replacementShopId;
  String? _feedback;
  bool _feedbackIsError = false;
  List<ShopSceneReference> _blockedReferences = const [];

  @override
  void initState() {
    super.initState();
    if (widget.controller.shops.isNotEmpty) {
      _selectShop(widget.controller.shops.first.id);
    }
    if (widget.controller.itemOptions.isNotEmpty) {
      _selectedItemId = widget.controller.itemOptions.first.id;
    }
  }

  @override
  void dispose() {
    _createLabelController.dispose();
    _renameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const Key('shop-editor-panel'),
      header: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: PokeMapSectionHeader(
          title: 'Catalogue des boutiques',
          description:
              'Créez les boutiques du projet avant de les choisir dans une Scene.',
        ),
      ),
      expandChild: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCreateRow(),
          const SizedBox(height: 16),
          Expanded(
            child: widget.controller.shops.isEmpty
                ? const PokeMapEmptyState(
                    title: 'Aucune boutique',
                    description:
                        'Donnez un nom lisible à votre première boutique.',
                    icon: Icon(Icons.storefront_outlined),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final list = _buildShopList();
                      final editor = _buildSelectedShopEditor();
                      if (constraints.maxWidth < 760) {
                        return ListView(
                          children: [list, const SizedBox(height: 12), editor],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(width: 260, child: list),
                          const SizedBox(width: 12),
                          Expanded(child: editor),
                        ],
                      );
                    },
                  ),
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _feedback!,
              key: const Key('shop-editor-feedback'),
              style: TextStyle(
                color: _feedbackIsError
                    ? context.pokeMapColors.error
                    : context.pokeMapColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: PokeMapTextField(
            label: 'Nom de la nouvelle boutique',
            fieldKey: const Key('shop-create-label-field'),
            controller: _createLabelController,
            hintText: 'Ex. Boutique du Port',
            onSubmitted: (_) => _createShop(),
          ),
        ),
        const SizedBox(width: 8),
        PokeMapButton(
          key: const Key('shop-create-button'),
          onPressed: _createShop,
          leading: const Icon(Icons.add),
          child: const Text('Créer'),
        ),
      ],
    );
  }

  Widget _buildShopList() {
    return ListView.separated(
      key: const Key('shop-editor-list'),
      itemCount: widget.controller.shops.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final shop = widget.controller.shops[index];
        return PokeMapCard(
          key: Key('shop-card-${shop.id}'),
          selected: shop.id == _selectedShopId,
          onTap: () => _selectShop(shop.id),
          child: Row(
            children: [
              const Icon(Icons.storefront_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.label,
                      style: TextStyle(
                        color: context.pokeMapColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${shop.entries.length} objet(s)',
                      style: TextStyle(
                        color: context.pokeMapColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedShopEditor() {
    final shopId = _selectedShopId;
    if (shopId == null) {
      return const PokeMapEmptyState(title: 'Choisissez une boutique');
    }
    final shop = widget.controller.shopById(shopId);
    return PokeMapPanel(
      header: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: PokeMapSectionHeader(
          title: shop.label,
          description: 'L’identifiant stable est géré automatiquement.',
          trailing: PokeMapIconButton(
            key: const Key('shop-delete-button'),
            onPressed: _deleteSelectedShop,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer la boutique',
            variant: PokeMapIconButtonVariant.danger,
          ),
        ),
      ),
      expandChild: true,
      child: ListView(
        children: [
          PokeMapTextField(
            label: 'Nom affiché',
            fieldKey: const Key('shop-rename-field'),
            controller: _renameController,
            onSubmitted: _renameShop,
          ),
          const SizedBox(height: 16),
          PokeMapSectionHeader(
            title: 'Inventaire vendu',
            description: 'Prix positif et stock vide pour un stock illimité.',
            trailing: PokeMapBadge(
              label: '${shop.entries.length}',
              variant: PokeMapBadgeVariant.info,
            ),
          ),
          const SizedBox(height: 8),
          if (shop.entries.isEmpty)
            const PokeMapEmptyState(
              title: 'Aucun objet vendu',
              description: 'Choisissez un objet du catalogue ci-dessous.',
              icon: Icon(Icons.inventory_2_outlined),
            )
          else
            for (final entry in shop.entries) ...[
              PokeMapCard(
                key: Key('shop-entry-${entry.itemId}'),
                onTap: () => _editEntry(entry),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _itemLabel(entry.itemId),
                            style: TextStyle(
                              color: context.pokeMapColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${entry.price} ₽ · '
                            '${entry.stock == null ? 'Stock illimité' : 'Stock : ${entry.stock}'}',
                            style: TextStyle(
                              color: context.pokeMapColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PokeMapIconButton(
                      key: Key('shop-remove-${entry.itemId}'),
                      onPressed: () => _removeEntry(entry.itemId),
                      icon: const Icon(Icons.close),
                      tooltip: 'Retirer cet objet',
                      variant: PokeMapIconButtonVariant.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),
          _buildEntryForm(shop),
          if (_blockedReferences.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildReferenceRepair(shop),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryForm(ShopDefinition shop) {
    if (widget.controller.itemOptions.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Catalogue d’objets indisponible',
        description:
            'Synchronisez le catalogue local avant d’ajouter un objet.',
        icon: Icon(Icons.sync_problem_outlined),
      );
    }
    final selected = _selectedItemId ?? widget.controller.itemOptions.first.id;
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapDropdownField<String>(
            key: const Key('shop-item-picker'),
            label: 'Objet du catalogue',
            value: selected,
            enabled: _editingItemId == null,
            items: [
              for (final option in widget.controller.itemOptions)
                PokeMapDropdownItem(value: option.id, label: option.label),
            ],
            onChanged: (value) => setState(() => _selectedItemId = value),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PokeMapTextField(
                  label: 'Prix',
                  fieldKey: const Key('shop-price-field'),
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PokeMapTextField(
                  label: 'Stock (facultatif)',
                  fieldKey: const Key('shop-stock-field'),
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_editingItemId != null) ...[
                PokeMapButton(
                  onPressed: _cancelEntryEdit,
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  child: const Text('Annuler'),
                ),
                const SizedBox(width: 8),
              ],
              PokeMapButton(
                key: const Key('shop-add-entry-button'),
                onPressed: () => _saveEntry(shop.id),
                size: PokeMapButtonSize.small,
                leading: Icon(
                  _editingItemId == null ? Icons.add : Icons.save_outlined,
                ),
                child: Text(
                  _editingItemId == null ? 'Ajouter' : 'Enregistrer',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceRepair(ShopDefinition shop) {
    final candidates = widget.controller.shops
        .where((candidate) => candidate.id != shop.id)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Suppression bloquée',
        description:
            'Cette boutique est utilisée par une Scene. Créez une boutique de remplacement.',
        icon: Icon(Icons.link_off_outlined),
      );
    }
    final replacement = _replacementShopId ?? candidates.first.id;
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(
            title: 'Réparer ${_blockedReferences.length} référence(s)',
            description:
                'Les commandes de Scene doivent pointer vers une autre boutique.',
          ),
          PokeMapDropdownField<String>(
            label: 'Boutique de remplacement',
            value: replacement,
            items: [
              for (final candidate in candidates)
                PokeMapDropdownItem(
                  value: candidate.id,
                  label: candidate.label,
                ),
            ],
            onChanged: (value) => setState(() => _replacementShopId = value),
          ),
          const SizedBox(height: 8),
          PokeMapButton(
            key: const Key('shop-repair-delete-button'),
            onPressed: () => _repairAndDelete(shop.id, replacement),
            variant: PokeMapButtonVariant.danger,
            child: const Text('Remplacer les références et supprimer'),
          ),
        ],
      ),
    );
  }

  void _createShop() {
    _runMutation(() {
      final shop = widget.controller.createShop(
        label: _createLabelController.text,
      );
      _createLabelController.clear();
      _selectShop(shop.id);
      return 'Boutique créée.';
    });
  }

  void _renameShop(String label) {
    final shopId = _selectedShopId;
    if (shopId == null) return;
    _runMutation(() {
      widget.controller.renameShop(shopId, label);
      _renameController.text = widget.controller.shopById(shopId).label;
      return 'Nom enregistré.';
    });
  }

  void _saveEntry(String shopId) {
    _runMutation(() {
      final price = int.tryParse(_priceController.text.trim());
      final stockText = _stockController.text.trim();
      final stock = stockText.isEmpty ? null : int.tryParse(stockText);
      if (price == null || (stockText.isNotEmpty && stock == null)) {
        throw const ShopEditorValidationException(
          'Prix et stock doivent être des nombres entiers.',
        );
      }
      final editing = _editingItemId;
      if (editing == null) {
        widget.controller.addEntry(
          shopId: shopId,
          itemId: _selectedItemId!,
          price: price,
          stock: stock,
        );
      } else {
        widget.controller.updateEntry(
          shopId: shopId,
          itemId: editing,
          price: price,
          stock: stock,
        );
      }
      _cancelEntryEdit(notify: false);
      return editing == null ? 'Objet ajouté.' : 'Objet mis à jour.';
    });
  }

  void _editEntry(ShopEntryDefinition entry) {
    setState(() {
      _editingItemId = entry.itemId;
      _selectedItemId = entry.itemId;
      _priceController.text = '${entry.price}';
      _stockController.text = entry.stock?.toString() ?? '';
    });
  }

  void _cancelEntryEdit({bool notify = true}) {
    void reset() {
      _editingItemId = null;
      _priceController.clear();
      _stockController.clear();
    }

    if (notify) {
      setState(reset);
    } else {
      reset();
    }
  }

  void _removeEntry(String itemId) {
    final shopId = _selectedShopId;
    if (shopId == null) return;
    _runMutation(() {
      widget.controller.removeEntry(shopId: shopId, itemId: itemId);
      return 'Objet retiré.';
    });
  }

  void _deleteSelectedShop() {
    final shopId = _selectedShopId;
    if (shopId == null) return;
    final result = widget.controller.deleteShop(shopId);
    if (!result.deleted) {
      setState(() {
        _blockedReferences = result.references;
        _feedbackIsError = true;
        _feedback =
            'Suppression bloquée : choisissez une boutique de remplacement.';
      });
      return;
    }
    _afterDelete();
  }

  void _repairAndDelete(String shopId, String replacementShopId) {
    _runMutation(() {
      widget.controller.deleteShop(
        shopId,
        replacementShopId: replacementShopId,
      );
      _afterDelete(notify: false);
      return 'Références réparées et boutique supprimée.';
    });
  }

  void _afterDelete({bool notify = true}) {
    void reset() {
      _selectedShopId = widget.controller.shops.firstOrNull?.id;
      _blockedReferences = const [];
      _replacementShopId = null;
      if (_selectedShopId != null) {
        _renameController.text =
            widget.controller.shopById(_selectedShopId!).label;
      }
    }

    if (notify) {
      widget.onManifestChanged(widget.controller.manifest);
      setState(reset);
    } else {
      reset();
    }
  }

  void _selectShop(String shopId) {
    final shop = widget.controller.shopById(shopId);
    setState(() {
      _selectedShopId = shop.id;
      _renameController.text = shop.label;
      _blockedReferences = const [];
      _replacementShopId = null;
      _editingItemId = null;
    });
  }

  String _itemLabel(String itemId) =>
      widget.controller.itemOptions
          .where((option) => option.id == itemId)
          .map((option) => option.label)
          .firstOrNull ??
      itemId;

  void _runMutation(String Function() mutation) {
    try {
      final message = mutation();
      widget.onManifestChanged(widget.controller.manifest);
      setState(() {
        _feedbackIsError = false;
        _feedback = message;
      });
    } on ShopEditorValidationException catch (error) {
      setState(() {
        _feedbackIsError = true;
        _feedback = error.message;
      });
    } on StateError catch (error) {
      setState(() {
        _feedbackIsError = true;
        _feedback = error.message;
      });
    }
  }
}
