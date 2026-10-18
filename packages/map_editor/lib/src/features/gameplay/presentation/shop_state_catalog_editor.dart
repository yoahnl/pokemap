import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/shop_editor_controller.dart';
import '../items/item_capability_picker.dart';

final class ShopCatalogEntryDraft {
  const ShopCatalogEntryDraft({
    required this.itemId,
    required this.price,
    this.sellPrice,
    this.stock,
    this.editingItemId,
    this.maximumOwnedQuantity,
    this.purchaseBonus,
  });

  final String itemId;
  final int price;
  final int? sellPrice;
  final int? stock;
  final String? editingItemId;
  final int? maximumOwnedQuantity;
  final ShopPurchaseBonus? purchaseBonus;
}

class ShopStateCatalogEditor extends StatefulWidget {
  const ShopStateCatalogEditor({
    super.key,
    required this.title,
    required this.entries,
    required this.itemOptions,
    required this.onSave,
    required this.onRemove,
    this.catalogMessage,
    this.onRetryCatalog,
    this.sellPolicy = ShopSellPolicy.listedEntries,
    this.onSellPolicyChanged,
  });

  final String title;
  final List<ShopEntryDefinition> entries;
  final List<ShopEditorItemOption> itemOptions;
  final ValueChanged<ShopCatalogEntryDraft> onSave;
  final ValueChanged<String> onRemove;
  final String? catalogMessage;
  final VoidCallback? onRetryCatalog;
  final ShopSellPolicy sellPolicy;
  final ValueChanged<ShopSellPolicy>? onSellPolicyChanged;

  @override
  State<ShopStateCatalogEditor> createState() => _ShopStateCatalogEditorState();
}

class _ShopStateCatalogEditorState extends State<ShopStateCatalogEditor> {
  final _priceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _maximumOwnedController = TextEditingController();
  final _bonusEveryController = TextEditingController(text: '10');
  final _bonusQuantityController = TextEditingController(text: '1');
  final _bonusMaximumController = TextEditingController();
  bool _bonusEnabled = false;
  String? _bonusItemId;
  String? _selectedItemId;
  String? _editingItemId;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _syncCatalogSelection();
  }

  @override
  void didUpdateWidget(covariant ShopStateCatalogEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemOptions != widget.itemOptions) {
      _syncCatalogSelection();
    }
    if (_editingItemId != null &&
        !widget.entries.any((entry) => entry.itemId == _editingItemId)) {
      _cancelEdit(notify: false);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _sellPriceController.dispose();
    _stockController.dispose();
    _maximumOwnedController.dispose();
    _bonusEveryController.dispose();
    _bonusQuantityController.dispose();
    _bonusMaximumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      key: const Key('shop-state-catalog-editor'),
      expandChild: true,
      header: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
        child: PokeMapSectionHeader(
          title: widget.title,
          description: 'Catalogue vendu pour cet état',
          trailing: PokeMapBadge(
            label: '${widget.entries.length} objet(s)',
            variant: PokeMapBadgeVariant.success,
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (widget.onSellPolicyChanged != null) ...[
            PokeMapDropdownField<ShopSellPolicy>(
              key: const Key('shop-sell-policy'),
              label: 'Objets repris à la vente',
              value: widget.sellPolicy,
              items: const [
                PokeMapDropdownItem(
                  value: ShopSellPolicy.listedEntries,
                  label: 'Objets de cette boutique',
                ),
                PokeMapDropdownItem(
                  value: ShopSellPolicy.catalogPrices,
                  label: 'Tout le sac, au prix du catalogue',
                ),
              ],
              onChanged: widget.onSellPolicyChanged!,
            ),
            const SizedBox(height: 8),
          ],
          if (widget.entries.isEmpty)
            const PokeMapEmptyState(
              title: 'Aucun objet vendu',
              description: 'Ajoutez un objet depuis le catalogue du projet.',
              icon: Icon(CupertinoIcons.cube_box),
            )
          else
            for (final entry in widget.entries) ...[
              PokeMapCard(
                key: Key('shop-entry-${entry.itemId}'),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.cube_box, size: 18),
                    const SizedBox(width: 8),
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
                            '${entry.sellPrice == null ? 'Invendable' : 'Revente : ${entry.sellPrice} ₽'} · '
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
                      key: Key('shop-state-entry-edit-${entry.itemId}'),
                      onPressed: () => _edit(entry),
                      icon: const Icon(CupertinoIcons.pencil),
                      tooltip: 'Modifier cet objet',
                    ),
                    PokeMapIconButton(
                      key: Key('shop-remove-${entry.itemId}'),
                      onPressed: () => widget.onRemove(entry.itemId),
                      icon: const Icon(CupertinoIcons.xmark),
                      tooltip: 'Retirer cet objet',
                      variant: PokeMapIconButtonVariant.danger,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
            ],
          const SizedBox(height: 8),
          if (widget.itemOptions.isEmpty)
            PokeMapEmptyState(
              title: 'Catalogue d’objets indisponible',
              description: widget.catalogMessage ??
                  'Synchronisez le catalogue local avant d’ajouter un objet.',
              icon: const Icon(CupertinoIcons.arrow_2_circlepath),
              action: widget.onRetryCatalog == null
                  ? null
                  : PokeMapButton(
                      onPressed: widget.onRetryCatalog,
                      size: PokeMapButtonSize.compact,
                      child: const Text('Réessayer'),
                    ),
            )
          else
            PokeMapCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ItemCapabilityPicker(
                    fieldKey: const Key('shop-item-picker'),
                    label: 'Objet du catalogue',
                    definitions: <ProjectItemDefinition>[
                      for (final option in widget.itemOptions)
                        if (option.definition != null) option.definition!,
                    ],
                    requirement: ItemCapabilityRequirement.any,
                    value: _selectedItemId ?? widget.itemOptions.first.id,
                    enabled: _editingItemId == null,
                    onChanged: (value) => setState(
                      () => _selectedItemId = value,
                    ),
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
                          label: 'Revente (vide = invendable)',
                          fieldKey: const Key('shop-sell-price-field'),
                          controller: _sellPriceController,
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
                  PokeMapTextField(
                    label: 'Quantité maximale possédée (facultatif)',
                    fieldKey: const Key('shop-owned-limit-field'),
                    controller: _maximumOwnedController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  PokeMapToggleTile(
                    key: const Key('shop-bonus-toggle'),
                    label: 'Offrir un objet après un achat',
                    value: _bonusEnabled,
                    onChanged: (value) => setState(() {
                      _bonusEnabled = value;
                      _bonusItemId ??= widget.itemOptions.firstOrNull?.id;
                    }),
                  ),
                  if (_bonusEnabled) ...[
                    const SizedBox(height: 8),
                    ItemCapabilityPicker(
                      fieldKey: const Key('shop-bonus-item-picker'),
                      label: 'Objet offert',
                      definitions: [
                        for (final option in widget.itemOptions)
                          if (option.definition != null) option.definition!,
                      ],
                      requirement: ItemCapabilityRequirement.any,
                      value: _bonusItemId ?? widget.itemOptions.first.id,
                      onChanged: (value) =>
                          setState(() => _bonusItemId = value),
                    ),
                    const SizedBox(height: 8),
                    PokeMapTextField(
                      label: 'Un cadeau toutes les X unités achetées',
                      fieldKey: const Key('shop-bonus-every-field'),
                      controller: _bonusEveryController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    PokeMapTextField(
                      label: 'Quantité offerte',
                      fieldKey: const Key('shop-bonus-quantity-field'),
                      controller: _bonusQuantityController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    PokeMapTextField(
                      label:
                          'Quantité maximale possédée du cadeau (facultatif)',
                      fieldKey: const Key('shop-bonus-owned-limit-field'),
                      controller: _bonusMaximumController,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                  if (_localError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _localError!,
                      style: TextStyle(
                        color: context.pokeMapColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_editingItemId != null) ...[
                        PokeMapButton(
                          onPressed: _cancelEdit,
                          variant: PokeMapButtonVariant.ghost,
                          size: PokeMapButtonSize.small,
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      PokeMapButton(
                        key: const Key('shop-add-entry-button'),
                        onPressed: _save,
                        size: PokeMapButtonSize.small,
                        leading: Icon(
                          _editingItemId == null
                              ? CupertinoIcons.add
                              : CupertinoIcons.floppy_disk,
                        ),
                        child: Text(
                          _editingItemId == null ? 'Ajouter' : 'Enregistrer',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _syncCatalogSelection() {
    final selectedStillExists = widget.itemOptions.any(
      (option) => option.id == _selectedItemId,
    );
    if (!selectedStillExists) {
      _selectedItemId = widget.itemOptions.firstOrNull?.id;
    }
  }

  void _edit(ShopEntryDefinition entry) {
    setState(() {
      _editingItemId = entry.itemId;
      _selectedItemId = entry.itemId;
      _priceController.text = '${entry.price}';
      _sellPriceController.text = entry.sellPrice?.toString() ?? '';
      _stockController.text = entry.stock?.toString() ?? '';
      _maximumOwnedController.text =
          entry.maximumOwnedQuantity?.toString() ?? '';
      _bonusEnabled = entry.purchaseBonus != null;
      _bonusItemId = entry.purchaseBonus?.itemId;
      _bonusEveryController.text =
          '${entry.purchaseBonus?.everyQuantity ?? 10}';
      _bonusQuantityController.text = '${entry.purchaseBonus?.quantity ?? 1}';
      _bonusMaximumController.text =
          entry.purchaseBonus?.maximumOwnedQuantity?.toString() ?? '';
      _localError = null;
    });
  }

  void _save() {
    final price = int.tryParse(_priceController.text.trim());
    final sellPriceText = _sellPriceController.text.trim();
    final sellPrice = sellPriceText.isEmpty
        ? null
        : int.tryParse(sellPriceText);
    final stockText = _stockController.text.trim();
    final stock = stockText.isEmpty ? null : int.tryParse(stockText);
    final maximumText = _maximumOwnedController.text.trim();
    final maximum = maximumText.isEmpty ? null : int.tryParse(maximumText);
    final bonusEvery = int.tryParse(_bonusEveryController.text.trim());
    final bonusQuantity = int.tryParse(_bonusQuantityController.text.trim());
    final bonusMaximumText = _bonusMaximumController.text.trim();
    final bonusMaximum = bonusMaximumText.isEmpty
        ? null
        : int.tryParse(bonusMaximumText);
    if (price == null ||
        (sellPriceText.isNotEmpty && sellPrice == null) ||
        (stockText.isNotEmpty && stock == null) ||
        (maximumText.isNotEmpty && (maximum == null || maximum <= 0)) ||
        (_bonusEnabled &&
            (_bonusItemId == null ||
                bonusEvery == null ||
                bonusEvery <= 0 ||
                bonusQuantity == null ||
                bonusQuantity <= 0 ||
                (bonusMaximumText.isNotEmpty &&
                    (bonusMaximum == null || bonusMaximum <= 0))))) {
      setState(() {
        _localError =
            'Les prix et quantités doivent être des entiers valides. Les limites et cadeaux doivent être positifs.';
      });
      return;
    }
    widget.onSave(
      ShopCatalogEntryDraft(
        itemId: _selectedItemId!,
        price: price,
        sellPrice: sellPrice,
        stock: stock,
        maximumOwnedQuantity: maximum,
        purchaseBonus: !_bonusEnabled
            ? null
            : ShopPurchaseBonus(
                itemId: _bonusItemId!,
                everyQuantity: bonusEvery!,
                quantity: bonusQuantity!,
                maximumOwnedQuantity: bonusMaximum,
              ),
        editingItemId: _editingItemId,
      ),
    );
    _cancelEdit();
  }

  void _cancelEdit({bool notify = true}) {
    void reset() {
      _editingItemId = null;
      _priceController.clear();
      _sellPriceController.clear();
      _stockController.clear();
      _maximumOwnedController.clear();
      _bonusEnabled = false;
      _bonusItemId = null;
      _bonusEveryController.text = '10';
      _bonusQuantityController.text = '1';
      _bonusMaximumController.clear();
      _localError = null;
    }

    if (notify) {
      setState(reset);
    } else {
      reset();
    }
  }

  String _itemLabel(String itemId) =>
      widget.itemOptions
          .where((option) => option.id == itemId)
          .map((option) => option.label)
          .firstOrNull ??
      'Objet indisponible dans le catalogue';
}
