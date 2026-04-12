part of 'pokedex_workspace_page.dart';

// Champs et switches réutilisés par l'édition locale.
//
// On les isole pour rendre le formulaire lisible et garder le fichier de la
// section metadata sous la barre des 400 lignes.

class _PokedexBooleanEditorRow extends StatelessWidget {
  const _PokedexBooleanEditorRow({
    super.key,
    required this.label,
    required this.value,
    required this.switchKey,
    required this.onChanged,
    this.description,
  });

  final String label;
  final bool value;
  final Key switchKey;
  final ValueChanged<bool>? onChanged;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: 4),
                Text(
                  description!,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        CupertinoSwitch(
          key: switchKey,
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PokedexEditorTextField extends StatelessWidget {
  const _PokedexEditorTextField({
    required this.label,
    required this.fieldKey,
    required this.controller,
    required this.enabled,
    this.minLines = 1,
    this.maxLines = 1,
    this.placeholder,
    this.description,
  });

  final String label;
  final Key fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final String? placeholder;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.28);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: TextStyle(
              color: subtle,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 6),
        DecoratedBox(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: 1),
          ),
          child: CupertinoTextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            minLines: minLines,
            maxLines: maxLines,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            placeholder: placeholder,
            placeholderStyle: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PokedexEditableTypeFields extends StatelessWidget {
  const _PokedexEditableTypeFields({
    required this.controllers,
    required this.enabled,
    required this.onAddType,
    required this.onRemoveType,
  });

  final List<TextEditingController> controllers;
  final bool enabled;
  final VoidCallback? onAddType;
  final void Function(int index)? onRemoveType;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Types',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            CupertinoButton(
              key: const Key('pokedex-add-type-button'),
              padding: EdgeInsets.zero,
              onPressed: enabled ? onAddType : null,
              child: const Text('+ ajouter'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Le premier type reste le type principal affiché dans la liste. Les valeurs vides sont ignorées à la sauvegarde.',
          style: TextStyle(
            color: subtle,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < controllers.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PokedexEditorTextField(
                  label: 'Type ${index + 1}',
                  fieldKey: Key('pokedex-type-field-$index'),
                  controller: controllers[index],
                  enabled: enabled,
                  placeholder: 'electric',
                ),
              ),
              const SizedBox(width: 10),
              CupertinoButton(
                key: Key('pokedex-remove-type-button-$index'),
                padding: const EdgeInsets.only(top: 28),
                onPressed: enabled && controllers.length > 1
                    ? () => onRemoveType?.call(index)
                    : null,
                child: const Text('Retirer'),
              ),
            ],
          ),
          if (index != controllers.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}
