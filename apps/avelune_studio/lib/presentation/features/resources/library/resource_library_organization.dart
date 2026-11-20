part of 'resource_library_view.dart';

extension _ResourceLibraryOrganization on _ResourceLibraryViewState {
  void _toggleMark(String id) => _updateView(() {
    if (!_marked.remove(id)) _marked.add(id);
  });

  Widget? _organizationControls(BuildContext context) {
    final manageFamilies = widget.onManageFamilies;
    final classify = widget.onClassifySelection;
    if (manageFamilies == null && classify == null && !_marking) return null;
    final count = _marked.length;
    return Wrap(
      spacing: StudioSpacing.m,
      runSpacing: StudioSpacing.s,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (manageFamilies != null && !_marking)
          StudioButton(
            label: 'Gérer les familles',
            secondary: true,
            icon: Icons.drive_file_move_outline,
            onPressed: manageFamilies,
          ),
        if (classify != null && !_marking)
          StudioButton(
            label: 'Sélectionner',
            secondary: true,
            icon: Icons.checklist,
            onPressed: () => _updateView(() => _marking = true),
          ),
        if (_marking) ...[
          Semantics(
            liveRegion: true,
            child: StudioBadge(
              count == 1
                  ? '1 ressource sélectionnée'
                  : '$count ressources sélectionnées',
            ),
          ),
          StudioButton(
            label: 'Classer la sélection',
            icon: Icons.folder_outlined,
            onPressed: classify == null || _marked.isEmpty
                ? null
                : () => classify(context, Set.unmodifiable(_marked)),
          ),
          StudioButton(
            label: 'Terminer',
            secondary: true,
            onPressed: () => _updateView(() {
              _marking = false;
              _marked.clear();
            }),
          ),
        ],
      ],
    );
  }
}
