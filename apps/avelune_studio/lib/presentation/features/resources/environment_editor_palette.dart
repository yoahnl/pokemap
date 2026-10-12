part of 'environment_editor_screen.dart';

extension _EnvironmentEditorPalette on _EnvironmentEditorScreenState {
  Widget paletteItem(EnvironmentPaletteItem item) {
    final element = widget.project.elements
        .where((element) => element.id == item.elementId)
        .firstOrNull;
    final resource = resourceCatalog(widget.project)
        .where(
          (resource) =>
              resource.canonicalKind ==
                  (item.isSpatial ? 'model3d' : 'element') &&
              resource.id == item.resourceId,
        )
        .firstOrNull;
    final name = resource?.name ?? 'Décor introuvable · ${item.resourceId}';
    return StudioPanel(
      compact: true,
      children: [
        Row(
          children: [
            if (resource != null)
              resourcePreview(
                resource,
                widget.project,
                widget.visuals,
                size: 64,
              )
            else
              const Icon(Icons.broken_image_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name, style: Theme.of(context).textTheme.titleMedium),
            ),
            StudioButton(
              label: 'Retirer',
              icon: Icons.close,
              secondary: true,
              onPressed: () => change(() => draft.remove(item.resourceId)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (item.isSpatial) ...[
          const Text('Décalage du modèle depuis le centre de case'),
          const Text(
            'En unités de carte. Le masque garde les cases choisies, indépendamment de la taille du modèle.',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final (axis, label) in [
                ('x', 'X · horizontal'),
                ('y', 'Y · hauteur'),
                ('z', 'Z · profondeur'),
              ])
                SizedBox(
                  width: 150,
                  child: StudioDraftField(
                    key: ValueKey(
                      'environment-offset-${item.resourceId}-$axis',
                    ),
                    value: draft.offsetInput(item.resourceId, axis),
                    label: label,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onChanged: (input) => change(
                      () => draft.setOffsetInput(item.resourceId, axis, input),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        StudioDraftField(
          value: draft.weightInput(item.resourceId),
          label: 'Poids de $name',
          errorText: error,
          onChanged: (value) {
            change(() => draft.setWeightInput(item.resourceId, value));
          },
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Collision de $name',
          value: item.collisionMode.name,
          options: {
            'useElementDefault': item.isSpatial
                ? 'Volume du modèle'
                : 'Collision du décor',
            'forceDisabled': 'Traversable',
            'forceEnabled': item.isSpatial
                ? 'Bloquant'
                : 'Utiliser le masque du décor',
          },
          onChanged: (value) => change(
            () => draft.setItem(
              item.resourceId,
              collision: EnvironmentCollisionMode.values.byName(value),
            ),
          ),
        ),
        if (element != null && element.collisionProfile == null) ...[
          const Text(
            'Aucune collision définie : ce décor restera traversable.',
          ),
          StudioButton(
            label: 'Définir ses collisions',
            icon: Icons.grid_on_outlined,
            secondary: true,
            onPressed: () => widget.onEditDecor(element),
          ),
        ],
      ],
    );
  }
}
