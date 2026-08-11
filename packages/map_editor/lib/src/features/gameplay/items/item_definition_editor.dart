import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import 'item_effect_editor.dart';
import 'item_studio_gateway.dart';

final class ItemDefinitionEditor extends StatefulWidget {
  const ItemDefinitionEditor({
    super.key,
    required this.initialDefinition,
    required this.onSaved,
    this.onCancel,
    this.heldEffectOptions = const <ItemStudioOption>[],
    this.moveOptions = const <ItemStudioOption>[],
    this.isSaving = false,
  });

  final ProjectItemDefinition? initialDefinition;
  final ValueChanged<ProjectItemDefinition> onSaved;
  final VoidCallback? onCancel;
  final List<ItemStudioOption> heldEffectOptions;
  final List<ItemStudioOption> moveOptions;
  final bool isSaving;

  @override
  State<ItemDefinitionEditor> createState() => _ItemDefinitionEditorState();
}

final class _ItemDefinitionEditorState extends State<ItemDefinitionEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _buyPriceController;
  late final TextEditingController _sellPriceController;
  late ProjectItemDefinition _capabilities;
  late String _pocketId;
  String? _nameError;
  String? _buyPriceError;
  String? _sellPriceError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDefinition;
    _nameController = TextEditingController(text: initial?.displayName ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _buyPriceController = TextEditingController(
      text: initial?.buyPrice?.toString() ?? '',
    );
    _sellPriceController = TextEditingController(
      text: initial?.sellPrice?.toString() ?? '',
    );
    _pocketId = initial?.pocketId ?? 'items';
    _capabilities =
        initial ??
        const ProjectItemDefinition(
          id: 'new-item',
          displayName: 'Nouvel objet',
          pocketId: 'items',
        );
    _nameController.addListener(_refresh);
    _descriptionController.addListener(_refresh);
    _buyPriceController.addListener(_refresh);
    _sellPriceController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identity = _identity;
    return PokeMapPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapSectionHeader(
            title: widget.initialDefinition == null
                ? 'Nouvel objet'
                : 'Modifier ${widget.initialDefinition!.displayName}',
            description: widget.initialDefinition == null
                ? 'L’identifiant technique est généré automatiquement.'
                : 'L’identité reste stable pour protéger les références.',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.onCancel != null) ...[
                  PokeMapButton(
                    onPressed: widget.isSaving ? null : widget.onCancel,
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.small,
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 6),
                ],
                PokeMapButton(
                  key: const Key('item-definition-save-button'),
                  onPressed: widget.isSaving ? null : _save,
                  isLoading: widget.isSaving,
                  size: PokeMapButtonSize.small,
                  leading: const Icon(Icons.save_outlined),
                  child: Text(
                    widget.initialDefinition == null ? 'Créer' : 'Enregistrer',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          PokeMapTextField(
            label: 'Nom affiché',
            controller: _nameController,
            fieldKey: const Key('item-definition-name-field'),
            placeholder: 'Potion Max',
            errorText: _nameError,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          PokeMapCard(
            child: Row(
              children: <Widget>[
                const Expanded(child: Text('Identifiant automatique')),
                PokeMapBadge(
                  label: identity.isEmpty ? 'en attente du nom' : identity,
                  variant: PokeMapBadgeVariant.info,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          PokeMapDropdownField<String>(
            key: const Key('item-definition-pocket-field'),
            label: 'Poche du sac',
            value: _pocketId,
            items: const <PokeMapDropdownItem<String>>[
              PokeMapDropdownItem(value: 'items', label: 'Objets'),
              PokeMapDropdownItem(value: 'medicine', label: 'Soins'),
              PokeMapDropdownItem(
                value: 'poke-balls',
                label: 'Objets de capture',
              ),
              PokeMapDropdownItem(
                value: 'battle-items',
                label: 'Objets de combat',
              ),
              PokeMapDropdownItem(
                value: 'machines',
                label: 'Capsules techniques',
              ),
              PokeMapDropdownItem(value: 'key-items', label: 'Objets rares'),
            ],
            onChanged: (value) => setState(() => _pocketId = value),
          ),
          const SizedBox(height: 8),
          PokeMapTextField(
            label: 'Description',
            controller: _descriptionController,
            placeholder: 'Explique clairement l’effet au joueur.',
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: PokeMapTextField(
                  label: 'Prix d’achat',
                  controller: _buyPriceController,
                  errorText: _buyPriceError,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PokeMapTextField(
                  label: 'Prix de vente',
                  controller: _sellPriceController,
                  errorText: _sellPriceError,
                  keyboardType: TextInputType.number,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ItemEffectEditor(
            definition: _draft(),
            heldEffectOptions: widget.heldEffectOptions,
            moveOptions: widget.moveOptions,
            onChanged: (definition) {
              setState(() => _capabilities = definition);
            },
          ),
        ],
      ),
    );
  }

  String get _identity {
    final initial = widget.initialDefinition;
    if (initial != null) return initial.id;
    return _slug(_nameController.text);
  }

  ProjectItemDefinition _draft() {
    final displayName = _nameController.text.trim();
    return _capabilities.copyWith(
      id: _identity.isEmpty ? 'new-item' : _identity,
      displayName: displayName.isEmpty ? 'Nouvel objet' : displayName,
      pocketId: _pocketId,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      buyPrice: _price(_buyPriceController.text),
      sellPrice: _price(_sellPriceController.text),
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final buyPrice = _validatedPrice(_buyPriceController.text);
    final sellPrice = _validatedPrice(_sellPriceController.text);
    setState(() {
      _nameError = name.isEmpty ? 'Le nom est obligatoire.' : null;
      _buyPriceError = buyPrice.$2;
      _sellPriceError = sellPrice.$2;
    });
    if (_nameError != null ||
        _buyPriceError != null ||
        _sellPriceError != null) {
      return;
    }
    widget.onSaved(
      _capabilities
          .copyWith(
            id: _identity,
            displayName: name,
            pocketId: _pocketId,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            buyPrice: buyPrice.$1,
            sellPrice: sellPrice.$1,
          )
          .normalized(),
    );
  }

  void _refresh() {
    if (mounted) setState(() {});
  }
}

(int?, String?) _validatedPrice(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return (null, null);
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < 0) {
    return (null, 'Le prix doit être un entier positif.');
  }
  return (parsed, null);
}

int? _price(String raw) => int.tryParse(raw.trim());

String _slug(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâä]'), 'a')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized;
}
