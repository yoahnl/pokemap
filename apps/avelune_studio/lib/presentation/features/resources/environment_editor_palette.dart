part of 'environment_editor_screen.dart';

extension _EnvironmentEditorPalette on _EnvironmentEditorScreenState {
  Widget paletteItem(EnvironmentPaletteItem item) {
    final element = widget.project.elements
        .where((element) => element.id == item.elementId)
        .firstOrNull;
    return StudioPanel(
      compact: true,
      children: [
        Row(
          children: [
            if (element != null)
              widget.visuals.thumbnail(element, size: 64)
            else
              const Icon(Icons.broken_image_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                element?.name ?? 'Décor introuvable · ${item.elementId}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            StudioButton(
              label: 'Retirer',
              icon: Icons.close,
              secondary: true,
              onPressed: () => change(() => draft.remove(item.elementId)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StudioDraftField(
          value: draft.weightInput(item.elementId),
          label: 'Poids de ${element?.name ?? item.elementId}',
          errorText: error,
          onChanged: (value) {
            change(() => draft.setWeightInput(item.elementId, value));
          },
        ),
        const SizedBox(height: 12),
        StudioSelect(
          label: 'Collision de ${element?.name ?? item.elementId}',
          value: item.collisionMode.name,
          options: const {
            'useElementDefault': 'Collision du décor',
            'forceDisabled': 'Traversable',
            'forceEnabled': 'Utiliser le masque du décor',
          },
          onChanged: (value) => change(
            () => draft.setItem(
              item.elementId,
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
