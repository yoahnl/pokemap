import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;

import '../../../features/narrative/application/narrative_workspace_projection.dart';
import '../../../theme/theme.dart';
import '../../design_system/design_system.dart';

enum SceneLibraryVisibility { active, archived, all }

final class SceneLibraryPanel extends StatefulWidget {
  const SceneLibraryPanel({
    super.key,
    required this.scenes,
    required this.selectedSceneId,
    required this.consumerCountBySceneId,
    required this.onSelectScene,
    required this.onEditScene,
    required this.onDuplicateScene,
    required this.onToggleArchiveScene,
    required this.onDeleteScene,
  });

  final List<NarrativeSceneSummary> scenes;
  final String? selectedSceneId;
  final Map<String, int> consumerCountBySceneId;
  final ValueChanged<String> onSelectScene;
  final VoidCallback? onEditScene;
  final VoidCallback? onDuplicateScene;
  final VoidCallback? onToggleArchiveScene;
  final VoidCallback? onDeleteScene;

  @override
  State<SceneLibraryPanel> createState() => _SceneLibraryPanelState();
}

final class _SceneLibraryPanelState extends State<SceneLibraryPanel> {
  String _query = '';
  SceneLibraryVisibility _visibility = SceneLibraryVisibility.active;

  List<NarrativeSceneSummary> get _visibleScenes {
    final normalizedQuery = _query.trim().toLowerCase();
    return widget.scenes.where((scene) {
      final visible = switch (_visibility) {
        SceneLibraryVisibility.active => !scene.isArchived,
        SceneLibraryVisibility.archived => scene.isArchived,
        SceneLibraryVisibility.all => true,
      };
      if (!visible) return false;
      if (normalizedQuery.isEmpty) return true;
      final searchable = <String>[
        scene.id,
        scene.name,
        scene.description ?? '',
        scene.storylineId ?? '',
        scene.chapterId ?? '',
        scene.libraryFolder ?? '',
        ...scene.tags,
        ...scene.declaredOutcomes,
      ].join(' ').toLowerCase();
      return searchable.contains(normalizedQuery);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.scenes
        .where((scene) => scene.id == widget.selectedSceneId)
        .firstOrNull;
    final scenes = _visibleScenes;
    return Material(
      type: MaterialType.transparency,
      child: PokeMapPanel(
        key: const ValueKey('scenes-tree-panel'),
        expandChild: true,
        padding: EdgeInsets.zero,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SceneLibraryTitle(),
              const SizedBox(height: 8),
              PokeMapSearchField(
                key: const ValueKey('scenes-library-search'),
                hintText: 'Rechercher une scène…',
                semanticLabel: 'Rechercher dans la bibliothèque de scènes',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              PokeMapDropdownField<SceneLibraryVisibility>(
                key: const ValueKey('scenes-library-visibility'),
                label: 'Afficher',
                value: _visibility,
                items: const [
                  PokeMapDropdownItem(
                    value: SceneLibraryVisibility.active,
                    label: 'Scènes actives',
                  ),
                  PokeMapDropdownItem(
                    value: SceneLibraryVisibility.archived,
                    label: 'Scènes archivées',
                  ),
                  PokeMapDropdownItem(
                    value: SceneLibraryVisibility.all,
                    label: 'Toutes les scènes',
                  ),
                ],
                onChanged: (value) => setState(() => _visibility = value),
              ),
              if (selected != null) ...[
                const SizedBox(height: 8),
                _SceneLibraryActions(
                  archived: selected.isArchived,
                  onEdit: widget.onEditScene,
                  onDuplicate: widget.onDuplicateScene,
                  onToggleArchive: widget.onToggleArchiveScene,
                  onDelete: widget.onDeleteScene,
                ),
              ],
            ],
          ),
        ),
        child: scenes.isEmpty
            ? _SceneLibraryEmptyState(
                hasProjectScenes: widget.scenes.isNotEmpty,
              )
            : _SceneLibraryList(
                scenes: scenes,
                selectedSceneId: widget.selectedSceneId,
                consumerCountBySceneId: widget.consumerCountBySceneId,
                onSelectScene: widget.onSelectScene,
              ),
      ),
    );
  }
}

final class _SceneLibraryTitle extends StatelessWidget {
  const _SceneLibraryTitle();

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        const Icon(CupertinoIcons.list_bullet_indent, size: 16),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Arborescence des scènes',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

final class _SceneLibraryActions extends StatelessWidget {
  const _SceneLibraryActions({
    required this.archived,
    required this.onEdit,
    required this.onDuplicate,
    required this.onToggleArchive,
    required this.onDelete,
  });

  final bool archived;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onToggleArchive;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PokeMapIconButton(
          key: const ValueKey('scenes-library-edit'),
          tooltip: 'Renommer et classer',
          onPressed: onEdit,
          icon: const Icon(CupertinoIcons.pencil, size: 15),
        ),
        PokeMapIconButton(
          key: const ValueKey('scenes-library-duplicate'),
          tooltip: 'Dupliquer',
          onPressed: onDuplicate,
          icon: const Icon(CupertinoIcons.doc_on_doc, size: 15),
        ),
        PokeMapIconButton(
          key: const ValueKey('scenes-library-toggle-archive'),
          tooltip: archived ? 'Restaurer' : 'Archiver',
          onPressed: onToggleArchive,
          icon: Icon(
            archived ? CupertinoIcons.arrow_up_bin : CupertinoIcons.archivebox,
            size: 15,
          ),
        ),
        PokeMapIconButton(
          key: const ValueKey('scenes-library-delete'),
          tooltip: 'Supprimer ou remplacer',
          onPressed: onDelete,
          variant: PokeMapIconButtonVariant.danger,
          icon: const Icon(CupertinoIcons.delete, size: 15),
        ),
      ],
    );
  }
}

final class _SceneLibraryEmptyState extends StatelessWidget {
  const _SceneLibraryEmptyState({required this.hasProjectScenes});

  final bool hasProjectScenes;

  @override
  Widget build(BuildContext context) {
    return PokeMapEmptyState(
      key: const ValueKey('scenes-tree-empty-state'),
      icon: const Icon(CupertinoIcons.square_stack_3d_up),
      title: hasProjectScenes ? 'Aucun résultat' : 'Liste vide',
      description: hasProjectScenes
          ? 'Aucune scène ne correspond à la recherche et au filtre.'
          : 'Aucune scène réelle dans ProjectManifest.scenes.',
    );
  }
}

final class _SceneLibraryList extends StatelessWidget {
  const _SceneLibraryList({
    required this.scenes,
    required this.selectedSceneId,
    required this.consumerCountBySceneId,
    required this.onSelectScene,
  });

  final List<NarrativeSceneSummary> scenes;
  final String? selectedSceneId;
  final Map<String, int> consumerCountBySceneId;
  final ValueChanged<String> onSelectScene;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<NarrativeSceneSummary>>{};
    for (final scene in scenes) {
      final key = scene.libraryFolder ??
          scene.storylineId ??
          (scene.isArchived ? 'Archives' : 'Sans dossier');
      grouped.putIfAbsent(key, () => []).add(scene);
    }
    return ListView(
      padding: const EdgeInsets.all(10),
      children: [
        for (final entry in grouped.entries) ...[
          _SceneLibraryGroupLabel(label: entry.key),
          const SizedBox(height: 6),
          for (final scene in entry.value) ...[
            if (scene.chapterId != null) ...[
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: _SceneLibraryGroupLabel(label: scene.chapterId!),
              ),
            ],
            _SceneLibraryItem(
              scene: scene,
              selected: scene.id == selectedSceneId,
              consumerCount: consumerCountBySceneId[scene.id] ?? 0,
              onTap: () => onSelectScene(scene.id),
            ),
            const SizedBox(height: 6),
          ],
          const SizedBox(height: 4),
        ],
      ],
    );
  }
}

final class _SceneLibraryGroupLabel extends StatelessWidget {
  const _SceneLibraryGroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    return Row(
      children: [
        Icon(CupertinoIcons.folder, size: 13, color: colors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

final class _SceneLibraryItem extends StatelessWidget {
  const _SceneLibraryItem({
    required this.scene,
    required this.selected,
    required this.consumerCount,
    required this.onTap,
  });

  final NarrativeSceneSummary scene;
  final bool selected;
  final int consumerCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = <String>[
      '${scene.nodeCount} nœuds',
      '${scene.edgeCount} liens',
      if (consumerCount > 0) '$consumerCount usages',
      if (scene.tags.isNotEmpty) scene.tags.join(', '),
    ].join(' • ');
    return PokeMapSidebarItem(
      key: ValueKey('scenes-tree-item-${scene.id}'),
      icon: Icon(
        scene.isArchived ? CupertinoIcons.archivebox : CupertinoIcons.flowchart,
      ),
      label: scene.name,
      subtitle: subtitle,
      growForTextScale: true,
      trailing: scene.hasDiagnostics
          ? PokeMapBadge(
              label: scene.diagnosticSummaryLabel,
              variant: scene.diagnosticErrorCount > 0
                  ? PokeMapBadgeVariant.error
                  : PokeMapBadgeVariant.warning,
            )
          : const Icon(CupertinoIcons.chevron_right, size: 14),
      selected: selected,
      onTap: onTap,
    );
  }
}
