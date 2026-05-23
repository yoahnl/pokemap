import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../theme/theme.dart';
import '../design_system/design_system.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'project_explorer/dialogs/import_tileset_dialog.dart';
import 'project_explorer/dialogs/tileset_library_dialogs.dart';
import 'project_explorer/dialogs/world_group_dialogs.dart';
import 'project_explorer/widgets/tree/tileset_tree_nodes.dart';
import 'project_explorer/widgets/tree/world_tree_nodes.dart';
import 'character_library_panel.dart';
import 'narrative_library_panel.dart';
import 'terrain_editor_panel.dart';
import 'trainer_library_panel.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_section_card.dart';

class ProjectExplorerPanel extends ConsumerStatefulWidget {
  const ProjectExplorerPanel({super.key});

  @override
  ConsumerState<ProjectExplorerPanel> createState() =>
      _ProjectExplorerPanelState();
}

class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
  bool _expandTileLib = true;
  bool _expandPokedex = true;
  bool _expandNarrative = true;
  bool _expandWorld = true;
  bool _expandTerrains = true;
  bool _expandPaths = true;
  bool _expandEnvironment = true;
  bool _expandTrainers = false;
  bool _expandCharacters = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(editorProjectExplorerSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = snapshot.project;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: project == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Open a project to browse your world, maps and tilesets.',
                              style: TextStyle(
                                color: context.pokeMapColors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 10),
                        _buildTree(context, project, snapshot, notifier),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colors = context.pokeMapColors;
    final subtle = colors.textMuted;
    final label = colors.textPrimary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(colors.surfaceRaised, colors.brandPrimary, 0.4)!,
                  Color.lerp(colors.surfaceBase, colors.brandPrimary, 0.2)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color.lerp(colors.borderSubtle, colors.brandPrimary, 0.5)!,
                width: 1.15,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.square_stack_3d_up,
              size: 18,
              color: colors.brandPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'World Explorer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cartes, tilesets, surfaces — dialogues dans Dialogue Studio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTree(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final colors = context.pokeMapColors;
    final rootMaps = project.maps.where((m) => m.groupId == null).toList();
    final rootGroups =
        project.groups.where((g) => g.parentGroupId == null).toList();

    final worldChildren = <Widget>[
      ...rootGroups.map(
        (g) => GroupNode(
          group: g,
          project: project,
          snapshot: snapshot,
          notifier: notifier,
          depth: 0,
        ),
      ),
      if (rootMaps.isNotEmpty) ...[
        const EditorSidebarSectionTitle('UNGROUPED MAPS', leftInset: 6),
        ...rootMaps.map(
          (m) => MapNode(
            map: m,
            snapshot: snapshot,
            notifier: notifier,
            depth: 0,
          ),
        ),
      ],
      if (rootGroups.isEmpty && rootMaps.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'World is empty',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              PokeMapButton(
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.medium,
                onPressed: () => showCreateGroupDialog(context, notifier),
                child: const Text('Add City or Route'),
              ),
            ],
          ),
        ),
    ];

    final screenH = MediaQuery.sizeOf(context).height;
    final hTileset = (screenH * 0.30).clamp(240.0, 400.0);
    final hPokedex = (screenH * 0.22).clamp(180.0, 260.0);
    final hNarrative = (screenH * 0.34).clamp(260.0, 460.0);
    final hWorld = (screenH * 0.30).clamp(240.0, 400.0);
    final hTerrains = (screenH * 0.36).clamp(280.0, 500.0);
    final hPaths = (screenH * 0.36).clamp(280.0, 500.0);
    final hEnvironment = (screenH * 0.22).clamp(180.0, 280.0);
    final hTrainers = (screenH * 0.18).clamp(180.0, 240.0);
    final hCharacters = (screenH * 0.35).clamp(260.0, 480.0);
    const explorerTileRadius = 28.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Tileset Library',
          subtitle: 'Folders, imports, and map painting',
          icon: CupertinoIcons.square_grid_2x2,
          accentColor: EditorChrome.inspectorJoyBlue,
          badgeText: '${project.tilesets.length}',
          expanded: _expandTileLib,
          onToggle: () => setState(() => _expandTileLib = !_expandTileLib),
          expandedHeight: hTileset,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PokeMapIconButton(
                onPressed: () =>
                    showImportTilesetDialog(context, snapshot, notifier),
                icon: const Icon(CupertinoIcons.photo_on_rectangle, size: 16),
                tooltip: 'Import tileset',
              ),
              const SizedBox(width: 6),
              PokeMapIconButton(
                onPressed: () => promptNewTilesetLibraryFolder(
                  context,
                  notifier,
                ),
                icon: const Icon(CupertinoIcons.plus_circle_fill, size: 16),
                tooltip: 'New folder',
              ),
            ],
          ),
          child: _buildTilesetsIsland(context, project, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Catalogues Pokémon',
          subtitle: 'Pokédex, Moves et Items dans un espace guidé unique',
          icon: CupertinoIcons.book_fill,
          accentColor: EditorChrome.inspectorJoyAmber,
          expanded: _expandPokedex,
          onToggle: () => setState(() => _expandPokedex = !_expandPokedex),
          expandedHeight: hPokedex,
          child: _buildPokemonCatalogsCard(context, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Narrative Studio',
          subtitle:
              'Global Story, Steps, Cutscenes and outcomes (opens central workspaces)',
          icon: CupertinoIcons.link_circle_fill,
          accentColor: EditorChrome.inspectorJoyCyan,
          badgeText: '${project.scenarios.length}',
          expanded: _expandNarrative,
          onToggle: () => setState(() => _expandNarrative = !_expandNarrative),
          expandedHeight: hNarrative,
          child: const NarrativeLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'World Maps',
          subtitle:
              'Maps jouables et contenu monde (events, entités, warps, triggers)',
          icon: CupertinoIcons.map_fill,
          accentColor: EditorChrome.inspectorJoyPlum,
          badgeText: '${project.maps.length}',
          expanded: _expandWorld,
          onToggle: () => setState(() => _expandWorld = !_expandWorld),
          expandedHeight: hWorld,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PokeMapIconButton(
                onPressed: () => showCreateGroupDialog(context, notifier),
                icon: const Icon(CupertinoIcons.folder_badge_plus, size: 16),
                tooltip: 'New root group',
              ),
            ],
          ),
          child: _buildWorldIslandBody(context, worldChildren),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Terrain Library',
          subtitle: 'Base ground presets',
          icon: CupertinoIcons.map,
          accentColor: EditorChrome.accentJade,
          badgeText: '${project.terrainPresets.length}',
          expanded: _expandTerrains,
          onToggle: () => setState(() => _expandTerrains = !_expandTerrains),
          expandedHeight: hTerrains,
          child: const TerrainLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Path Library',
          subtitle: 'Legacy paths and Path Studio recipes',
          icon: CupertinoIcons.arrow_branch,
          accentColor: EditorChrome.accentWarm,
          badgeText:
              '${project.pathPresets.length}/${project.pathPatternPresets.length}',
          expanded: _expandPaths,
          onToggle: () => setState(() => _expandPaths = !_expandPaths),
          expandedHeight: hPaths,
          child: _buildPathLibraryCard(context, project, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Environment Studio',
          subtitle: 'Presets d’environnements réutilisables',
          icon: CupertinoIcons.tree,
          accentColor: EditorChrome.accentJade,
          badgeText: '${project.environmentPresets.length}',
          expanded: _expandEnvironment,
          onToggle: () =>
              setState(() => _expandEnvironment = !_expandEnvironment),
          expandedHeight: hEnvironment,
          child: _buildEnvironmentStudioCard(context, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Trainer Studio',
          subtitle: 'Battle rosters and teams (opens the central workspace)',
          icon: CupertinoIcons.person_2_fill,
          accentColor: EditorChrome.accentCoral,
          badgeText: '${project.trainers.length}',
          expanded: _expandTrainers,
          onToggle: () => setState(() => _expandTrainers = !_expandTrainers),
          expandedHeight: hTrainers,
          child: const TrainerLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Character Library',
          subtitle: 'Overworld sprites for the player and NPCs',
          icon: CupertinoIcons.person_crop_circle,
          accentColor: EditorChrome.inspectorJoyCyan,
          badgeText: '${project.characters.length}',
          expanded: _expandCharacters,
          onToggle: () =>
              setState(() => _expandCharacters = !_expandCharacters),
          expandedHeight: hCharacters,
          child: const CharacterLibraryPanel(embedded: true),
        ),
      ],
    );
  }

  Widget _buildTilesetsIsland(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildTilesetsSection(context, project, snapshot, notifier),
    );
  }

  Widget _buildPokemonCatalogsCard(
    BuildContext context,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final isCatalogsWorkspace =
        snapshot.workspaceMode == EditorWorkspaceMode.pokedex;

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditorSidebarListRow(
            key: const Key('pokemon-catalog-entry-pokedex'),
            selected: isCatalogsWorkspace &&
                snapshot.pokemonCatalogSection == PokemonCatalogSection.pokedex,
            onTap: () => notifier.selectPokemonCatalogSection(
              PokemonCatalogSection.pokedex,
            ),
            leading: const MacosIcon(CupertinoIcons.book),
            title: const Text('Pokédex'),
            subtitle: const Text(
              'Recherche, import, détail et édition locale des espèces',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          EditorSidebarListRow(
            key: const Key('pokemon-catalog-entry-moves'),
            selected: isCatalogsWorkspace &&
                snapshot.pokemonCatalogSection == PokemonCatalogSection.moves,
            onTap: () => notifier.selectPokemonCatalogSection(
              PokemonCatalogSection.moves,
            ),
            leading: const MacosIcon(CupertinoIcons.sparkles),
            title: const Text('Moves'),
            subtitle: const Text(
              'Catalogue local des capacités du projet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          EditorSidebarListRow(
            key: const Key('pokemon-catalog-entry-items'),
            selected: isCatalogsWorkspace &&
                snapshot.pokemonCatalogSection == PokemonCatalogSection.items,
            onTap: () => notifier.selectPokemonCatalogSection(
              PokemonCatalogSection.items,
            ),
            leading: const MacosIcon(CupertinoIcons.cube_box),
            title: const Text('Items'),
            subtitle: const Text(
              'Catalogue local des objets du projet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentStudioCard(
    BuildContext context,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final isEnvironment =
        snapshot.workspaceMode == EditorWorkspaceMode.environmentStudio;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSidebarListRow(
          key: const Key('project-explorer-environment-studio-entry'),
          selected: isEnvironment,
          onTap: notifier.selectEnvironmentStudioWorkspace,
          leading: const MacosIcon(CupertinoIcons.tree),
          title: const Text('Environment Studio'),
          subtitle: const Text(
            'Créez et organisez vos presets d’environnements.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPathLibraryCard(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final isPathStudio =
        snapshot.workspaceMode == EditorWorkspaceMode.pathStudio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSidebarListRow(
          key: const Key('project-explorer-path-studio-entry'),
          selected: isPathStudio,
          onTap: notifier.selectPathStudioWorkspace,
          leading: const MacosIcon(CupertinoIcons.arrow_branch),
          title: const Text('Path Studio'),
          subtitle: Text(
            '${project.pathPatternPresets.length} motifs PathPattern',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 8),
        const Expanded(
          child: PathLibraryPanel(embedded: true),
        ),
      ],
    );
  }

  Widget _buildWorldIslandBody(
    BuildContext context,
    List<Widget> worldChildren,
  ) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: worldChildren,
      ),
    );
  }

  Widget _buildTilesetsSection(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final selectedTilesetId = snapshot.selectedTilesetEntry?.id;
    final tree = buildTilesetLibraryTree(project);

    String scopeLabel(ProjectTilesetEntry t) {
      if (t.scope == TilesetScope.global) return 'Global';
      final gid = t.groupId;
      if (gid == null) return 'Group';
      for (final g in project.groups) {
        if (g.id == gid) return g.name;
      }
      return 'Group';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TilesetLibraryRootDropStrip(project: project, notifier: notifier),
        if (project.tilesets.isEmpty && project.tilesetFolders.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Text(
              'No tilesets yet. Import an image or create folders to organize your library.',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 12,
              ),
            ),
          ),
        ...tree.rootFolders.map(
          (branch) => TilesetLibraryFolderNode(
            branch: branch,
            depth: 0,
            project: project,
            notifier: notifier,
            selectedTilesetId: selectedTilesetId,
            scopeLabel: scopeLabel,
          ),
        ),
        ...tree.rootTilesets.map(
          (tileset) => TilesetNode(
            tileset: tileset,
            project: project,
            notifier: notifier,
            selected: selectedTilesetId == tileset.id,
            leftIndent: 14,
            scopeLabel: scopeLabel(tileset),
          ),
        ),
      ],
    );
  }
}
