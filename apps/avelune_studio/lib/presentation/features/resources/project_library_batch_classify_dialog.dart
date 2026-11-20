part of 'project_library_organization_dialog.dart';

class ProjectLibraryBatchClassifyDialog extends StatefulWidget {
  const ProjectLibraryBatchClassifyDialog({
    super.key,
    required this.selectionCount,
    required this.familyLabels,
    required this.save,
    required this.prepareCatalog,
  });

  final int selectionCount;
  final Map<String, String> familyLabels;
  final Future<ProjectLibraryBatchEdit> Function(
    ({String? id})? family,
    ResourceLibraryRole? role,
  )
  save;
  final Future<void> Function() prepareCatalog;

  @override
  State<ProjectLibraryBatchClassifyDialog> createState() =>
      _ProjectLibraryBatchClassifyDialogState();
}

class _ProjectLibraryBatchClassifyDialogState
    extends State<ProjectLibraryBatchClassifyDialog> {
  static const _keepFamily = 'keep';
  static const _clearFamily = 'clear';
  static const _familyPrefix = 'family:';
  final _search = TextEditingController();
  String _family = _keepFamily;
  ResourceLibraryRole? _role;

  ({String? id})? get _familyUpdate => switch (_family) {
    _keepFamily => null,
    _clearFamily => (id: null),
    final value => (id: value.substring(_familyPrefix.length)),
  };

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = studioSearchText(_search.text).trim();
    final options = {
      _keepFamily: 'Conserver les familles actuelles',
      _clearFamily: 'Sans famille',
      for (final entry in widget.familyLabels.entries)
        if ('$_familyPrefix${entry.key}' == _family ||
            studioSearchText(entry.value).contains(query))
          '$_familyPrefix${entry.key}': entry.value,
    };
    return _ProjectLibraryOrganizationForm<ProjectLibraryBatchEdit>(
      title: 'Classer les ressources sélectionnées',
      confirmLabel: 'Classer la sélection',
      prepareCatalog: widget.prepareCatalog,
      commit: _familyUpdate == null && _role == null
          ? null
          : () => widget.save(_familyUpdate, _role),
      content: (enabled) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.selectionCount == 1
                ? '1 ressource sélectionnée'
                : '${widget.selectionCount} ressources sélectionnées',
          ),
          const SizedBox(height: StudioSpacing.l),
          if (widget.familyLabels.length > 12) ...[
            StudioSearchField(
              controller: _search,
              label: 'Chercher une famille',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: StudioSpacing.m),
          ],
          StudioSelect(
            key: const ValueKey('library-batch-family'),
            label: 'Famille',
            value: _family,
            options: options,
            onChanged: enabled
                ? (value) => setState(() => _family = value)
                : null,
          ),
          const SizedBox(height: StudioSpacing.l),
          StudioSelect(
            key: const ValueKey('library-batch-role'),
            label: 'Rôle dans la bibliothèque',
            value: _role?.name ?? '',
            options: const {
              '': 'Conserver les rôles actuels',
              'standard': 'Ressource à utiliser',
              'component': 'Composant technique',
            },
            onChanged: enabled
                ? (value) => setState(() {
                    _role = value.isEmpty
                        ? null
                        : ResourceLibraryRole.values.byName(value);
                  })
                : null,
          ),
        ],
      ),
    );
  }
}
