import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/shop_editor_controller.dart';
import 'shop_project_list.dart';
import 'shop_state_catalog_editor.dart';
import 'shop_state_inspector.dart';
import 'shop_state_list.dart';

class ShopEditorPanel extends StatefulWidget {
  const ShopEditorPanel({
    super.key,
    required this.controller,
    required this.onManifestChanged,
    this.catalogMessage,
    this.onRetryCatalog,
  });

  final ShopEditorController controller;
  final ValueChanged<ProjectManifest> onManifestChanged;
  final String? catalogMessage;
  final VoidCallback? onRetryCatalog;

  @override
  State<ShopEditorPanel> createState() => _ShopEditorPanelState();
}

class _ShopEditorPanelState extends State<ShopEditorPanel> {
  String? _selectedShopId;
  String _selectedStateId = ShopEditorController.defaultStateId;
  String? _feedback;
  bool _feedbackIsError = false;
  List<ShopSceneReference> _blockedReferences = const [];
  String? _replacementShopId;

  @override
  void initState() {
    super.initState();
    _selectedShopId = widget.controller.shops.firstOrNull?.id;
  }

  @override
  void didUpdateWidget(covariant ShopEditorPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _repairSelection();
  }

  @override
  Widget build(BuildContext context) {
    final shop = _selectedShop;
    return Column(
      key: const Key('shop-editor-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: PokeMapSectionHeader(
            title: 'Boutique Builder',
            description:
                'Définissez le catalogue vendu selon l’état de l’histoire.',
          ),
        ),
        if (_feedback != null) ...[
          PokeMapCard(
            child: Text(
              _feedback!,
              key: const Key('shop-editor-feedback'),
              style: TextStyle(
                color: _feedbackIsError
                    ? context.pokeMapColors.error
                    : context.pokeMapColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_blockedReferences.isNotEmpty && shop != null) ...[
          _buildReferenceRepair(shop),
          const SizedBox(height: 8),
        ],
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (shop == null) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 280, child: _buildProjectList()),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: PokeMapEmptyState(
                        title: 'Sélectionnez une boutique',
                        description:
                            'Créez une boutique pour définir son catalogue.',
                        icon: Icon(CupertinoIcons.cart),
                      ),
                    ),
                  ],
                );
              }
              if (constraints.maxWidth >= 1440) {
                return _buildWideLayout(shop);
              }
              if (constraints.maxWidth >= 1100) {
                return _buildMediumLayout(shop);
              }
              return _buildCompactLayout(shop);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout(ShopDefinition shop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 250, child: _buildProjectList()),
        const SizedBox(width: 8),
        SizedBox(width: 250, child: _buildStateList(shop)),
        const SizedBox(width: 8),
        Expanded(child: _buildCatalog(shop)),
        const SizedBox(width: 8),
        SizedBox(width: 310, child: _buildInspector(shop)),
      ],
    );
  }

  Widget _buildMediumLayout(ShopDefinition shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const Key('shop-inspector-side-sheet-button'),
            onPressed: () => _openInspectorSheet(shop),
            size: PokeMapButtonSize.compact,
            variant: PokeMapButtonVariant.secondary,
            leading: const Icon(CupertinoIcons.slider_horizontal_3),
            child: const Text('Inspecteur'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 245, child: _buildProjectList()),
              const SizedBox(width: 8),
              SizedBox(width: 245, child: _buildStateList(shop)),
              const SizedBox(width: 8),
              Expanded(child: _buildCatalog(shop)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactLayout(ShopDefinition shop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            PokeMapButton(
              key: const Key('shop-lists-compact-button'),
              onPressed: () => _openListsSheet(shop),
              size: PokeMapButtonSize.compact,
              variant: PokeMapButtonVariant.secondary,
              leading: const Icon(CupertinoIcons.list_bullet),
              child: const Text('Boutiques et états'),
            ),
            const Spacer(),
            PokeMapButton(
              key: const Key('shop-inspector-side-sheet-button'),
              onPressed: () => _openInspectorSheet(shop),
              size: PokeMapButtonSize.compact,
              variant: PokeMapButtonVariant.secondary,
              leading: const Icon(CupertinoIcons.slider_horizontal_3),
              child: const Text('Inspecteur'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(child: _buildCatalog(shop)),
      ],
    );
  }

  Widget _buildProjectList() => ShopProjectList(
        shops: widget.controller.shops,
        selectedShopId: _selectedShopId,
        onSelect: _selectShop,
        onCreate: _createShop,
        onDelete: _selectedShopId == null ? null : _deleteSelectedShop,
      );

  Widget _buildStateList(ShopDefinition shop) => ShopStateList(
        shop: shop,
        selectedStateId: _selectedStateId,
        onSelect: (stateId) => setState(() => _selectedStateId = stateId),
        onCreateFromDefault: () => _createState(copyDefault: true),
        onCreateEmpty: () => _createState(copyDefault: false),
        onDuplicate: _selectedStateId == ShopEditorController.defaultStateId
            ? null
            : _duplicateState,
        onDelete: _selectedStateId == ShopEditorController.defaultStateId
            ? null
            : _deleteState,
      );

  Widget _buildCatalog(ShopDefinition shop) {
    final state = _selectedState;
    return ShopStateCatalogEditor(
      key: ValueKey<String>('catalog-${shop.id}-$_selectedStateId'),
      title: state?.label ?? 'Catalogue par défaut',
      entries: state?.entries ?? shop.entries,
      itemOptions: widget.controller.itemOptions,
      catalogMessage: widget.catalogMessage,
      onRetryCatalog: widget.onRetryCatalog,
      onSave: _saveEntry,
      onRemove: _removeEntry,
    );
  }

  Widget _buildInspector(ShopDefinition shop) => ShopStateInspector(
        shop: shop,
        state: _selectedState,
        onRenameShop: _renameShop,
        onSaveState: _selectedState == null ? null : _saveStateSettings,
      );

  Widget _buildReferenceRepair(ShopDefinition shop) {
    final candidates = widget.controller.shops
        .where((candidate) => candidate.id != shop.id)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Suppression bloquée',
        description:
            'Cette boutique est utilisée par une Scene. Créez une boutique de remplacement.',
        icon: Icon(CupertinoIcons.link),
      );
    }
    final replacement = candidates.any(
      (candidate) => candidate.id == _replacementShopId,
    )
        ? _replacementShopId!
        : candidates.first.id;
    return PokeMapCard(
      child: Row(
        children: [
          Expanded(
            child: PokeMapDropdownField<String>(
              label: 'Réparer ${_blockedReferences.length} référence(s) avec',
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
          ),
          const SizedBox(width: 8),
          PokeMapButton(
            key: const Key('shop-repair-delete-button'),
            onPressed: () => _repairAndDelete(shop.id, replacement),
            variant: PokeMapButtonVariant.danger,
            child: const Text('Remplacer et supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInspectorSheet(ShopDefinition shop) {
    return showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Inspecteur de boutique',
      semanticLabel: 'Réglages de la boutique et de son état',
      width: 390,
      builder: (_) => _buildInspector(shop),
    );
  }

  Future<void> _openListsSheet(ShopDefinition shop) {
    return showPokeMapDesktopSideSheet<void>(
      context: context,
      title: 'Boutiques et états',
      semanticLabel: 'Choisir une boutique et un état',
      width: 520,
      builder: (_) => Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _buildProjectList()),
          const SizedBox(width: 8),
          Expanded(child: _buildStateList(shop)),
        ],
      ),
    );
  }

  ShopDefinition? get _selectedShop {
    final id = _selectedShopId;
    if (id == null) return null;
    return widget.controller.shops.where((shop) => shop.id == id).firstOrNull;
  }

  ShopStateDefinition? get _selectedState {
    if (_selectedStateId == ShopEditorController.defaultStateId) return null;
    final shop = _selectedShop;
    return shop?.states
        .where((state) => state.id == _selectedStateId)
        .firstOrNull;
  }

  void _createShop(String label) {
    _runMutation(() {
      final shop = widget.controller.createShop(label: label);
      _selectedShopId = shop.id;
      _selectedStateId = ShopEditorController.defaultStateId;
      return 'Boutique créée.';
    });
  }

  void _renameShop(String label) {
    final shopId = _selectedShopId;
    if (shopId == null) return;
    _runMutation(() {
      widget.controller.renameShop(shopId, label);
      return 'Nom de la boutique enregistré.';
    });
  }

  void _createState({required bool copyDefault}) {
    final shop = _selectedShop;
    if (shop == null) return;
    _runMutation(() {
      final index = shop.states.length + 1;
      final activation = ScriptConditionFactory.flagIsSet(
        'shop_${shop.id}_state_$index',
      );
      final state = copyDefault
          ? widget.controller.createStateFromDefault(
              shopId: shop.id,
              label: 'Nouvel état $index',
              activation: activation,
            )
          : widget.controller.createEmptyState(
              shopId: shop.id,
              label: 'Nouvel état $index',
              activation: activation,
            );
      _selectedStateId = state.id;
      return copyDefault
          ? 'État créé depuis le catalogue par défaut.'
          : 'État vide créé.';
    });
  }

  void _duplicateState() {
    final shopId = _selectedShopId;
    if (shopId == null) return;
    _runMutation(() {
      final state = widget.controller.duplicateState(
        shopId: shopId,
        stateId: _selectedStateId,
      );
      _selectedStateId = state.id;
      return 'État dupliqué.';
    });
  }

  void _deleteState() {
    final shopId = _selectedShopId;
    if (shopId == null) return;
    _runMutation(() {
      widget.controller.deleteState(
        shopId: shopId,
        stateId: _selectedStateId,
      );
      _selectedStateId = ShopEditorController.defaultStateId;
      return 'État supprimé.';
    });
  }

  void _saveStateSettings(ShopStateSettingsDraft draft) {
    final shopId = _selectedShopId;
    if (shopId == null) return;
    _runMutation(() {
      widget.controller.renameState(
        shopId: shopId,
        stateId: _selectedStateId,
        label: draft.label,
      );
      widget.controller.updateStateSettings(
        shopId: shopId,
        stateId: _selectedStateId,
        priority: draft.priority,
        isOpen: draft.isOpen,
        storefrontLabel: draft.storefrontLabel,
        welcomeMessage: draft.welcomeMessage,
        closedMessage: draft.closedMessage,
      );
      return 'Réglages de l’état enregistrés.';
    });
  }

  void _saveEntry(ShopCatalogEntryDraft draft) {
    final shopId = _selectedShopId;
    if (shopId == null) return;
    _runMutation(() {
      final editing = draft.editingItemId;
      if (_selectedStateId == ShopEditorController.defaultStateId) {
        if (editing == null) {
          widget.controller.addEntry(
            shopId: shopId,
            itemId: draft.itemId,
            price: draft.price,
            stock: draft.stock,
          );
        } else {
          widget.controller.updateEntry(
            shopId: shopId,
            itemId: editing,
            price: draft.price,
            stock: draft.stock,
          );
        }
      } else if (editing == null) {
        widget.controller.addStateEntry(
          shopId: shopId,
          stateId: _selectedStateId,
          itemId: draft.itemId,
          price: draft.price,
          stock: draft.stock,
        );
      } else {
        widget.controller.updateStateEntry(
          shopId: shopId,
          stateId: _selectedStateId,
          itemId: editing,
          price: draft.price,
          stock: draft.stock,
        );
      }
      return editing == null ? 'Objet ajouté.' : 'Objet mis à jour.';
    });
  }

  void _removeEntry(String itemId) {
    final shopId = _selectedShopId;
    if (shopId == null) return;
    _runMutation(() {
      if (_selectedStateId == ShopEditorController.defaultStateId) {
        widget.controller.removeEntry(shopId: shopId, itemId: itemId);
      } else {
        widget.controller.removeStateEntry(
          shopId: shopId,
          stateId: _selectedStateId,
          itemId: itemId,
        );
      }
      return 'Objet retiré.';
    });
  }

  void _selectShop(String shopId) {
    setState(() {
      _selectedShopId = shopId;
      _selectedStateId = ShopEditorController.defaultStateId;
      _blockedReferences = const [];
      _replacementShopId = null;
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
    widget.onManifestChanged(widget.controller.manifest);
    setState(() {
      _selectedShopId = widget.controller.shops.firstOrNull?.id;
      _selectedStateId = ShopEditorController.defaultStateId;
      _feedbackIsError = false;
      _feedback = 'Boutique supprimée.';
    });
  }

  void _repairAndDelete(String shopId, String replacementShopId) {
    _runMutation(() {
      widget.controller.deleteShop(
        shopId,
        replacementShopId: replacementShopId,
      );
      _selectedShopId = replacementShopId;
      _selectedStateId = ShopEditorController.defaultStateId;
      _blockedReferences = const [];
      _replacementShopId = null;
      return 'Références réparées et boutique supprimée.';
    });
  }

  void _repairSelection() {
    if (_selectedShop != null) {
      if (_selectedStateId == ShopEditorController.defaultStateId ||
          _selectedState != null) {
        return;
      }
      _selectedStateId = ShopEditorController.defaultStateId;
      return;
    }
    _selectedShopId = widget.controller.shops.firstOrNull?.id;
    _selectedStateId = ShopEditorController.defaultStateId;
  }

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
