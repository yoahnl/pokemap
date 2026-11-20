part of 'project_library_organization_dialog.dart';

class ProjectLibraryFamiliesDialog extends StatefulWidget {
  const ProjectLibraryFamiliesDialog({
    super.key,
    required this.families,
    required this.familyLabels,
    required this.saveFamily,
    required this.deleteFamily,
    required this.prepareCatalog,
  });

  final Iterable<ResourceFamily> families;
  final Map<String, String> familyLabels;
  final Future<ProjectLibraryFamilyEdit> Function(
    ResourceFamily? existing,
    String name,
    String? parentId,
  )
  saveFamily;
  final Future<ProjectLibraryFamilyEdit> Function(ResourceFamily family)
  deleteFamily;
  final Future<void> Function() prepareCatalog;

  @override
  State<ProjectLibraryFamiliesDialog> createState() =>
      _ProjectLibraryFamiliesDialogState();
}

class _ProjectLibraryFamiliesDialogState
    extends State<ProjectLibraryFamiliesDialog> {
  final _search = TextEditingController();
  ResourceFamily? _existing;
  String _name = '';
  String? _parentId;
  bool _deleting = false;

  bool get _changed =>
      _name.trim().isNotEmpty &&
      (_name.trim() != _existing?.name || _parentId != _existing?.parentId);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _select(ResourceFamily? family) => setState(() {
    _existing = family;
    _name = family?.name ?? '';
    _parentId = family?.parentId;
  });

  Map<String, String> _parentOptions(Map<String, ResourceFamily> families) {
    final editing = _existing?.id;
    bool canParent(String? id) {
      while (id != null) {
        if (id == editing) return false;
        id = families[id]?.parentId;
      }
      return true;
    }

    return {
      '': 'À la racine',
      for (final entry in widget.familyLabels.entries)
        if (canParent(entry.key)) entry.key: entry.value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final existing = _existing;
    if (_deleting && existing != null) {
      return _ProjectLibraryOrganizationForm<ProjectLibraryFamilyEdit>(
        key: ValueKey('delete-${existing.id}'),
        title: 'Supprimer la famille',
        confirmLabel: 'Supprimer la famille',
        prepareCatalog: widget.prepareCatalog,
        onBack: () => setState(() => _deleting = false),
        commit: () => widget.deleteFamily(existing),
        content: (_) => Text(
          'Retirer « ${existing.name} » du classement. La famille doit être vide.',
        ),
      );
    }

    final custom = {for (final family in widget.families) family.id: family};
    final query = studioSearchText(_search.text).trim();
    return _ProjectLibraryOrganizationForm<ProjectLibraryFamilyEdit>(
      key: ValueKey(existing?.id),
      title: 'Gérer les familles',
      confirmLabel: existing == null ? 'Créer la famille' : 'Enregistrer',
      prepareCatalog: widget.prepareCatalog,
      commit: _changed
          ? () => widget.saveFamily(existing, _name.trim(), _parentId)
          : null,
      content: (enabled) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (custom.isEmpty)
            const Text(
              'Aucune famille personnalisée. Vous pouvez en créer une.',
            )
          else ...[
            if (custom.length > 12) ...[
              StudioSearchField(
                controller: _search,
                label: 'Chercher une famille à gérer',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: StudioSpacing.m),
            ],
            StudioSelect(
              key: const ValueKey('library-family-target'),
              label: 'Famille à gérer',
              value: existing?.id ?? '',
              options: {
                '': 'Nouvelle famille',
                for (final entry in widget.familyLabels.entries)
                  if (custom.containsKey(entry.key) &&
                      (entry.key == existing?.id ||
                          studioSearchText(entry.value).contains(query)))
                    entry.key: entry.value,
              },
              onChanged: enabled ? (id) => _select(custom[id]) : null,
            ),
          ],
          const SizedBox(height: StudioSpacing.l),
          StudioDraftField(
            key: const ValueKey('library-family-name'),
            label: 'Nom de la famille',
            value: _name,
            enabled: enabled,
            onChanged: (name) => setState(() => _name = name),
          ),
          const SizedBox(height: StudioSpacing.l),
          StudioSelect(
            key: const ValueKey('library-family-parent'),
            label: 'Famille parente',
            value: _parentId ?? '',
            options: _parentOptions(custom),
            onChanged: enabled
                ? (id) => setState(() => _parentId = id.isEmpty ? null : id)
                : null,
          ),
          if (existing != null) ...[
            const SizedBox(height: StudioSpacing.l),
            Align(
              alignment: Alignment.centerLeft,
              child: StudioButton(
                label: 'Supprimer cette famille…',
                variant: StudioButtonVariant.destructive,
                onPressed: enabled
                    ? () => setState(() => _deleting = true)
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
