part of 'project_library_edit_dialog.dart';

extension _ProjectLibraryEditFields on _ProjectLibraryEditDialogState {
  List<Widget> _detailsFields() => [
    Text(widget.item!.name),
    const SizedBox(height: StudioSpacing.m),
    StudioDraftField(
      key: const ValueKey('library-edit-description'),
      label: 'Description',
      value: _description,
      lines: 3,
      autofocus: true,
      enabled: !_saving && !_published,
      errorText: _description.length > 2000
          ? '2 000 caractères maximum.'
          : null,
      onChanged: (value) => _change(() => _description = value),
    ),
    const SizedBox(height: StudioSpacing.l),
    StudioSelect(
      label: 'Contexte de pose',
      value: _placement?.name ?? '',
      options: const {
        '': 'Selon la famille',
        'interior': 'Intérieur',
        'exterior': 'Extérieur',
        'both': 'Intérieur et extérieur',
      },
      onChanged: _saving || _published
          ? null
          : (value) => _change(() {
              _placement = value.isEmpty
                  ? null
                  : ResourcePlacementContext.values.byName(value);
            }),
    ),
  ];

  List<Widget> _nameFields() => [
    if (widget.duplicate) ...[
      Text('La copie reprend les réglages de « ${widget.item!.name} ».'),
      const SizedBox(height: StudioSpacing.m),
    ],
    if (widget.file case final file?) ...[
      Text(switch (file.imageSize) {
        final size? => 'Image PNG · ${size.width} × ${size.height} px',
        null => 'Modèle 3D GLB',
      }),
      const SizedBox(height: StudioSpacing.m),
    ],
    StudioDraftField(
      key: const ValueKey('library-edit-name'),
      value: _name,
      label: 'Nom',
      autofocus: true,
      enabled: !_saving && !_published,
      onChanged: (value) => _change(() => _name = value),
      onSubmitted: (_) => _save(),
    ),
    if (widget.file?.imageSize != null) ...[
      const SizedBox(height: StudioSpacing.l),
      StudioSelect(
        label: 'Utiliser comme',
        value: _tiles ? 'tiles' : 'image',
        options: const {'image': 'Image entière', 'tiles': 'Planche de tuiles'},
        onChanged: _saving || _published
            ? null
            : (value) => _change(() => _tiles = value == 'tiles'),
      ),
      if (_tiles) ...[
        const SizedBox(height: StudioSpacing.m),
        Row(
          children: [
            Expanded(
              child: _dimension(
                'Largeur (px)',
                _width,
                (value) => _width = value,
              ),
            ),
            const SizedBox(width: StudioSpacing.m),
            Expanded(
              child: _dimension(
                'Hauteur (px)',
                _height,
                (value) => _height = value,
              ),
            ),
          ],
        ),
        if (_tileSize == null) ...[
          const SizedBox(height: StudioSpacing.s),
          const StudioNotice(
            'La largeur et la hauteur doivent diviser exactement l’image.',
            isError: true,
          ),
        ],
      ],
    ],
  ];

  Widget _dimension(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) => StudioDraftField(
    value: value,
    label: label,
    enabled: !_saving && !_published,
    keyboardType: TextInputType.number,
    onChanged: (value) => _change(() => onChanged(value)),
  );

  List<Widget> _classificationFields() {
    final search = studioSearchText(_familySearch.text).trim();
    final families = {
      '': 'Sans famille',
      for (final entry in widget.families.entries)
        if (entry.key == _family ||
            studioSearchText(entry.value).contains(search))
          entry.key: entry.value,
    };
    return [
      Text(widget.item!.name),
      const SizedBox(height: StudioSpacing.m),
      if (widget.families.length > 12) ...[
        StudioSearchField(
          controller: _familySearch,
          label: 'Chercher une famille',
          onChanged: (_) => _change(() {}),
        ),
        const SizedBox(height: StudioSpacing.m),
      ],
      StudioSelect(
        key: const ValueKey('library-edit-family'),
        label: 'Famille',
        value: families.containsKey(_family) ? _family : '',
        options: families,
        onChanged: _saving || _published
            ? null
            : (value) => _change(() => _family = value.isEmpty ? null : value),
      ),
      const SizedBox(height: StudioSpacing.l),
      StudioSelect(
        key: const ValueKey('library-edit-role'),
        label: 'Rôle dans la bibliothèque',
        value: _role.name,
        options: const {
          'standard': 'Ressource à utiliser',
          'component': 'Composant technique',
        },
        onChanged: _saving || _published
            ? null
            : (value) => _change(
                () => _role = ResourceLibraryRole.values.byName(value),
              ),
      ),
    ];
  }
}
