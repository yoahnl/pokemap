import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/shop_editor_controller.dart';

final class ShopCatalogEntryDraft {
  const ShopCatalogEntryDraft({
    required this.itemId,
    required this.price,
    this.stock,
    this.editingItemId,
  });

  final String itemId;
  final int price;
  final int? stock;
  final String? editingItemId;
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
  });

  final String title;
  final List<ShopEntryDefinition> entries;
  final List<ShopEditorItemOption> itemOptions;
  final ValueChanged<ShopCatalogEntryDraft> onSave;
  final ValueChanged<String> onRemove;
  final String? catalogMessage;
  final VoidCallback? onRetryCatalog;

  @override
  State<ShopStateCatalogEditor> createState() => _ShopStateCatalogEditorState();
}

class _ShopStateCatalogEditorState extends State<ShopStateCatalogEditor> {
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
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
    _stockController.dispose();
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
                  PokeMapDropdownField<String>(
                    key: const Key('shop-item-picker'),
                    label: 'Objet du catalogue',
                    value: _selectedItemId ?? widget.itemOptions.first.id,
                    enabled: _editingItemId == null,
                    items: [
                      for (final option in widget.itemOptions)
                        PokeMapDropdownItem(
                          value: option.id,
                          label: option.label,
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedItemId = value),
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
      _stockController.text = entry.stock?.toString() ?? '';
      _localError = null;
    });
  }

  void _save() {
    final price = int.tryParse(_priceController.text.trim());
    final stockText = _stockController.text.trim();
    final stock = stockText.isEmpty ? null : int.tryParse(stockText);
    if (price == null || (stockText.isNotEmpty && stock == null)) {
      setState(() {
        _localError = 'Prix et stock doivent être des nombres entiers.';
      });
      return;
    }
    widget.onSave(
      ShopCatalogEntryDraft(
        itemId: _selectedItemId!,
        price: price,
        stock: stock,
        editingItemId: _editingItemId,
      ),
    );
    _cancelEdit();
  }

  void _cancelEdit({bool notify = true}) {
    void reset() {
      _editingItemId = null;
      _priceController.clear();
      _stockController.clear();
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
