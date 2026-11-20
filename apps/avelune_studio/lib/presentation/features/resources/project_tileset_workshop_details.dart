part of 'project_tileset_workshop.dart';

Widget _sourcePanel(
  BuildContext context,
  ProjectTilesetSource? source,
  ProjectImageCollectionPage? page,
  bool fullImage, {
  VoidCallback? onEdit,
}) {
  final facts = switch (source) {
    final ProjectRegularAtlasTilesetSource atlas => <(String, String)>[
      if (atlas.pixelWidth > 0 && atlas.pixelHeight > 0)
        ('Dimensions de l’image', _size(atlas.pixelWidth, atlas.pixelHeight)),
      if (!fullImage && atlas.tileCount > 0) ...[
        ('Taille d’une tuile', _size(atlas.tileWidth, atlas.tileHeight)),
        ('Grille', projectTilesetGridLabel(atlas)),
        if (atlas.marginX != 0 || atlas.marginY != 0)
          (
            'Marges horizontale et verticale',
            _size(atlas.marginX, atlas.marginY),
          ),
        if (atlas.spacingX != 0 || atlas.spacingY != 0)
          (
            'Espacements horizontal et vertical',
            _size(atlas.spacingX, atlas.spacingY),
          ),
      ],
    ],
    ProjectImageCollectionTilesetSource(:final pages, :final tileDefinitions) =>
      [
        ('Pages', '${pages.length}'),
        if (page != null && page.pixelWidth > 0 && page.pixelHeight > 0)
          ('Dimensions de la page', _size(page.pixelWidth, page.pixelHeight)),
        ('Tuiles de la collection', '${tileDefinitions.length}'),
      ],
    null => const <(String, String)>[],
  };
  final title = switch (source) {
    ProjectRegularAtlasTilesetSource() when fullImage => 'Image entière',
    ProjectRegularAtlasTilesetSource() => 'Planche de tuiles',
    ProjectImageCollectionTilesetSource() => 'Collection d’images',
    null => 'Découpe',
  };
  final texts = Theme.of(context).textTheme;
  return StudioPanel(
    title: title,
    icon: Icons.grid_on_outlined,
    actions: [
      if (onEdit != null)
        StudioButton(
          label: 'Modifier le découpage',
          icon: Icons.edit_outlined,
          variant: StudioButtonVariant.secondary,
          onPressed: onEdit,
        ),
    ],
    children: [
      if (source == null)
        const Text('Aucune grille enregistrée pour cette image.')
      else if (source is ProjectRegularAtlasTilesetSource &&
          source.tileCount == 0)
        const StudioNotice('La grille enregistrée est inexploitable.'),
      for (final (label, value) in facts)
        Padding(
          padding: const EdgeInsets.only(bottom: StudioSpacing.s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: texts.bodySmall),
              Text(value, style: texts.titleSmall),
            ],
          ),
        ),
    ],
  );
}

String _size(int width, int height) => '$width × $height px';
