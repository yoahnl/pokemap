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

class ProjectExplorerPanel extends ConsumerStatefulWidget {
  const ProjectExplorerPanel({
    super.key,
    this.onCollapse,
  });

  final VoidCallback? onCollapse;

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
                      _buildHeader(context, snapshot.workspaceMode),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Ouvrez un projet pour parcourir votre monde, vos cartes et vos jeux de tuiles.',
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
                        _buildHeader(context, snapshot.workspaceMode),
                        const SizedBox(height: 10),
                        _buildTree(context, project, snapshot, notifier),
                      ],
                    ),
                  ),
          ),
          if (widget.onCollapse != null) ...[
            const SizedBox(height: 10),
            _buildCollapseButton(context),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapseButton(BuildContext context) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Semantics(
        button: true,
        label: 'Réduire l’explorateur global',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            key: const ValueKey('project-explorer-toggle'),
            onTap: widget.onCollapse,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.borderSubtle,
                  width: 1.25,
                ),
                color: colors.surfaceBase,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.borderStrong.withValues(alpha: 0.5),
                        width: 1.15,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      CupertinoIcons.chevron_left,
                      size: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Réduire l\'explorateur',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EditorWorkspaceMode workspaceMode) {
    final colors = context.pokeMapColors;
    final subtle = colors.textMuted;
    final label = colors.textPrimary;
    final isNarrativeWorkspace = _isNarrativeWorkspace(workspaceMode);
    final accent =
        isNarrativeWorkspace ? colors.narrative : colors.brandPrimary;
    final icon = isNarrativeWorkspace
        ? CupertinoIcons.link_circle_fill
        : CupertinoIcons.square_stack_3d_up;
    final title = isNarrativeWorkspace ? 'Narrative Studio' : 'World Explorer';
    final subtitle = isNarrativeWorkspace
        ? 'Aperçu, histoire globale, étapes, cinématiques et dialogues'
        : 'Cartes, tilesets, surfaces — dialogues dans Dialogue Studio';

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
                  Color.lerp(colors.surfaceRaised, accent, 0.4)!,
                  Color.lerp(colors.surfaceBase, accent, 0.2)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color.lerp(colors.borderSubtle, accent, 0.5)!,
                width: 1.15,
              ),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
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
                  subtitle,
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

  bool _isNarrativeWorkspace(EditorWorkspaceMode workspaceMode) {
    return workspaceMode == EditorWorkspaceMode.narrativeOverview ||
        workspaceMode == EditorWorkspaceMode.globalStory ||
        workspaceMode == EditorWorkspaceMode.step ||
        workspaceMode == EditorWorkspaceMode.cutscene ||
        workspaceMode == EditorWorkspaceMode.dialogue;
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
        const EditorSidebarSectionTitle('CARTES NON GROUPÉES', leftInset: 6),
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
                'Le monde est vide',
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
                child: const Text('Ajouter une ville ou une route'),
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
    final isNarrativeWorkspace = _isNarrativeWorkspace(snapshot.workspaceMode);
    final narrativeModuleCard = _buildNarrativeModuleCard(
      context,
      project,
      snapshot,
      hNarrative,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isNarrativeWorkspace) narrativeModuleCard,
        ProjectExplorerModuleCard(
          title: 'Tileset Library',
          description: 'Dossiers, imports et peinture de carte',
          icon: CupertinoIcons.square_grid_2x2,
          accentColor: colors.warning,
          count: project.tilesets.length,
          selected: snapshot.workspaceMode == EditorWorkspaceMode.tileset,
          expanded: _expandTileLib,
          onExpandToggle: () =>
              setState(() => _expandTileLib = !_expandTileLib),
          expandedHeight: hTileset,
          trailing: Row(
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
        ProjectExplorerModuleCard(
          title: 'Catalogues Pokémon',
          description:
              'Pokédex, capacités et objets dans un espace guidé unique',
          icon: CupertinoIcons.book_fill,
          accentColor: colors.fact,
          selected: snapshot.workspaceMode == EditorWorkspaceMode.pokedex,
          expanded: _expandPokedex,
          onExpandToggle: () =>
              setState(() => _expandPokedex = !_expandPokedex),
          expandedHeight: hPokedex,
          child: _buildPokemonCatalogsCard(context, snapshot, notifier),
        ),
        if (!isNarrativeWorkspace) narrativeModuleCard,
        ProjectExplorerModuleCard(
          title: 'World Maps',
          description:
              'Maps jouables et contenu monde (événements, entités, téléportations, déclencheurs)',
          icon: CupertinoIcons.map_fill,
          accentColor: colors.mapAccent,
          count: project.maps.length,
          selected: snapshot.workspaceMode == EditorWorkspaceMode.map,
          expanded: _expandWorld,
          onExpandToggle: () => setState(() => _expandWorld = !_expandWorld),
          expandedHeight: hWorld,
          trailing: Row(
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
        ProjectExplorerModuleCard(
          title: 'Terrain Library',
          description: 'Presets de terrain de base',
          icon: CupertinoIcons.map,
          accentColor: colors.success,
          count: project.terrainPresets.length,
          selected: false,
          expanded: _expandTerrains,
          onExpandToggle: () =>
              setState(() => _expandTerrains = !_expandTerrains),
          expandedHeight: hTerrains,
          child: const TerrainLibraryPanel(embedded: true),
        ),
        ProjectExplorerModuleCard(
          title: 'Path Library',
          description: 'Chemins hérités et recettes Path Studio',
          icon: CupertinoIcons.arrow_branch,
          accentColor: colors.warning,
          countLabel:
              '${project.pathPresets.length}/${project.pathPatternPresets.length}',
          selected: snapshot.workspaceMode == EditorWorkspaceMode.pathStudio,
          expanded: _expandPaths,
          onExpandToggle: () => setState(() => _expandPaths = !_expandPaths),
          expandedHeight: hPaths,
          child: _buildPathLibraryCard(context, project, snapshot, notifier),
        ),
        ProjectExplorerModuleCard(
          title: 'Environment Studio',
          description: 'Presets d’environnements réutilisables',
          icon: CupertinoIcons.tree,
          accentColor: colors.worldRule,
          count: project.environmentPresets.length,
          selected:
              snapshot.workspaceMode == EditorWorkspaceMode.environmentStudio,
          expanded: _expandEnvironment,
          onExpandToggle: () =>
              setState(() => _expandEnvironment = !_expandEnvironment),
          expandedHeight: hEnvironment,
          child: _buildEnvironmentStudioCard(context, snapshot, notifier),
        ),
        ProjectExplorerModuleCard(
          title: 'Trainer Studio',
          description:
              'Équipes et dresseurs de combat (ouvre l\'espace de travail central)',
          icon: CupertinoIcons.person_2_fill,
          accentColor: colors.combat,
          count: project.trainers.length,
          selected: snapshot.workspaceMode == EditorWorkspaceMode.trainer,
          expanded: _expandTrainers,
          onExpandToggle: () =>
              setState(() => _expandTrainers = !_expandTrainers),
          expandedHeight: hTrainers,
          child: const TrainerLibraryPanel(embedded: true),
        ),
        ProjectExplorerModuleCard(
          title: 'Character Library',
          description: 'Sprites de monde pour le joueur et les PNJ',
          icon: CupertinoIcons.person_crop_circle,
          accentColor: colors.cinematic,
          count: project.characters.length,
          selected: false,
          expanded: _expandCharacters,
          onExpandToggle: () =>
              setState(() => _expandCharacters = !_expandCharacters),
          expandedHeight: hCharacters,
          child: const CharacterLibraryPanel(embedded: true),
        ),
      ],
    );
  }

  Widget _buildNarrativeModuleCard(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    double expandedHeight,
  ) {
    final colors = context.pokeMapColors;
    return ProjectExplorerModuleCard(
      title: 'Narrative Studio',
      description: 'Accès aux espaces auteur narratifs existants',
      icon: CupertinoIcons.link_circle_fill,
      accentColor: colors.narrative,
      count: project.scenarios.length,
      selected: _isNarrativeWorkspace(snapshot.workspaceMode),
      expanded: _expandNarrative,
      onExpandToggle: () =>
          setState(() => _expandNarrative = !_expandNarrative),
      expandedHeight: expandedHeight,
      child: const NarrativeLibraryPanel(embedded: true),
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
    final colors = context.pokeMapColors;
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
              'Aucun jeu de tuiles pour le moment. Importez une image ou créez des dossiers pour organiser votre bibliothèque.',
              style: TextStyle(
                color: colors.textMuted,
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
