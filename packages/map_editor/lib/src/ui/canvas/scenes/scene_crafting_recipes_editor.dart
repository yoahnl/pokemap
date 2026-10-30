import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

class SceneCraftingRecipesEditor extends StatefulWidget {
  const SceneCraftingRecipesEditor({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final List<Map<String, dynamic>> value;
  final Map<String, String> items;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  @override
  State<SceneCraftingRecipesEditor> createState() =>
      _SceneCraftingRecipesEditorState();
}

class _SceneCraftingRecipesEditorState
    extends State<SceneCraftingRecipesEditor> {
  final _controllers = <String, TextEditingController>{};
  List<Map<String, dynamic>> get value => widget.value;
  Map<String, String> get items => widget.items;
  ValueChanged<List<Map<String, dynamic>>> get onChanged => widget.onChanged;

  TextEditingController _controller(
    Map<String, dynamic> recipe,
    String field,
  ) => _controllers.putIfAbsent(
    '${recipe['recipeId']}:$field',
    () => TextEditingController(text: '${recipe[field] ?? ''}'),
  );

  @override
  void didUpdateWidget(SceneCraftingRecipesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final retained = {
      for (final recipe in value)
        for (final field in ['label', 'inputQuantity', 'outputQuantity'])
          '${recipe['recipeId']}:$field',
    };
    for (final key
        in _controllers.keys.where((key) => !retained.contains(key)).toList()) {
      _controllers.remove(key)!.dispose();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _change(int index, String field, Object next) => onChanged([
    for (final (position, recipe) in value.indexed)
      position == index ? {...recipe, field: next} : recipe,
  ]);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (items.isEmpty)
        const PokeMapDiagnosticCallout(
          severity: PokeMapDiagnosticSeverity.warning,
          message:
              'Ajoutez des objets au catalogue pour configurer les recettes.',
        ),
      for (final (index, recipe) in value.indexed) ...[
        const SizedBox(height: 8),
        PokeMapTextField(
          fieldKey: ValueKey('crafting-recipe-$index-label'),
          label: 'Nom de la recette ${index + 1}',
          controller: _controller(recipe, 'label'),
          onChanged: (label) => _change(index, 'label', label),
        ),
        for (final field in ['inputItemId', 'outputItemId']) ...[
          const SizedBox(height: 8),
          PokeMapDropdownField<String>(
            label: field == 'inputItemId' ? 'Ingrédient' : 'Objet fabriqué',
            value: recipe[field] as String? ?? '',
            items: [
              const PokeMapDropdownItem(value: '', label: 'Choisir un objet'),
              if (recipe[field] is String &&
                  (recipe[field] as String).isNotEmpty &&
                  !items.containsKey(recipe[field]))
                PokeMapDropdownItem(
                  value: recipe[field] as String,
                  label: 'Objet introuvable : ${recipe[field]}',
                ),
              for (final item in items.entries)
                PokeMapDropdownItem(value: item.key, label: item.value),
            ],
            onChanged: (item) => _change(index, field, item),
          ),
        ],
        for (final field in ['inputQuantity', 'outputQuantity']) ...[
          const SizedBox(height: 8),
          PokeMapTextField(
            fieldKey: ValueKey('crafting-recipe-$index-$field'),
            label: field == 'inputQuantity'
                ? 'Ingrédients par lot'
                : 'Objets fabriqués par lot',
            controller: _controller(recipe, field),
            keyboardType: TextInputType.number,
            onChanged: (quantity) =>
                _change(index, field, int.tryParse(quantity) ?? 0),
          ),
        ],
        PokeMapButton(
          size: PokeMapButtonSize.small,
          variant: PokeMapButtonVariant.ghost,
          onPressed: () => onChanged([...value]..removeAt(index)),
          child: const Text('Retirer cette recette'),
        ),
      ],
      const SizedBox(height: 8),
      PokeMapButton(
        key: const ValueKey('crafting-recipe-add'),
        size: PokeMapButtonSize.small,
        variant: PokeMapButtonVariant.secondary,
        onPressed: items.isEmpty
            ? null
            : () {
                var suffix = value.length + 1;
                while (value.any(
                  (recipe) => recipe['recipeId'] == 'recipe-$suffix',
                )) {
                  suffix++;
                }
                onChanged([
                  ...value,
                  {
                    'recipeId': 'recipe-$suffix',
                    'label': 'Recette $suffix',
                    'inputItemId': '',
                    'inputQuantity': 1,
                    'outputItemId': '',
                    'outputQuantity': 1,
                  },
                ]);
              },
        child: const Text('Ajouter une recette'),
      ),
    ],
  );
}
