import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';
import 'cupertino_editor_widgets.dart';

/// Exposé pour [MacosScaffold.toolBar], qui attend un [ToolBar] typé (pas un [ConsumerWidget]).
ToolBar buildMapEditorToolbar(BuildContext context, WidgetRef ref) =>
    TopToolbar.buildToolBar(context, ref);

/// Barre d’outils native [macos_ui] pour [MacosScaffold].
class TopToolbar extends ConsumerWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      TopToolbar.buildToolBar(context, ref);

  static List<MacosPulldownMenuEntry> _terrainPulldownItems(
    EditorNotifier notifier,
  ) {
    return TerrainType.values
        .where((t) => t.isBackgroundPaintable)
        .map(
          (terrain) => MacosPulldownMenuItem(
            label: _terrainTypeLabel(terrain),
            title: Text(_terrainTypeLabel(terrain)),
            onTap: () => notifier.selectTerrainType(terrain),
          ),
        )
        .toList();
  }

  static List<MacosPulldownMenuEntry> _entityKindPulldownItems(
    EditorNotifier notifier,
  ) {
    return MapEntityKind.values
        .map(
          (kind) => MacosPulldownMenuItem(
            label: _entityKindLabel(kind),
            title: Text(_entityKindLabel(kind)),
            onTap: () => notifier.selectEntityKind(kind),
          ),
        )
        .toList(growable: false);
  }

  static ToolBar buildToolBar(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final settings = state.project?.settings ?? const ProjectSettings();
    final subtle = EditorChrome.subtleLabel(context);

    final map = state.activeMap;
    final isMapWorkspace = state.workspaceMode == EditorWorkspaceMode.map;
    final hasTilesets = (state.project?.tilesets.isNotEmpty ?? false);
    final firstTilesetId =
        hasTilesets ? state.project!.tilesets.first.id : null;
    final hasMapCanvas = map != null;
    final showWorldTools = isMapWorkspace && hasMapCanvas;

    MapLayer? activeLayer;
    if (map != null && state.activeLayerId != null) {
      for (final layer in map.layers) {
        if (layer.id == state.activeLayerId) {
          activeLayer = layer;
          break;
        }
      }
    }

    final canEraseOnActiveLayer = activeLayer is TileLayer ||
        activeLayer is CollisionLayer ||
        activeLayer is TerrainLayer ||
        activeLayer is PathLayer;

    final showTerrainTypePulldown = activeLayer is TerrainLayer &&
        state.activeTool == EditorToolType.terrainPaint &&
        state.terrainSelectionMode == TerrainSelectionMode.terrain;
    final showEntityKindPulldown =
        state.activeTool == EditorToolType.entityPlacement;
    final showContextStrip =
        showWorldTools && (showTerrainTypePulldown || showEntityKindPulldown);

    final showCollisionBrushSize = activeLayer is CollisionLayer &&
        (state.activeTool == EditorToolType.collisionPaint ||
            state.activeTool == EditorToolType.eraser);

    final actions = <ToolbarItem>[
      _groupItem(
        context,
        overflowLabel: 'Project',
        children: [
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.folder_badge_plus,
            tooltip: 'New Project',
            onPressed: () => TopToolbar._showNewProjectDialog(
              context,
              notifier,
            ),
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.folder_open,
            tooltip: 'Open Project',
            onPressed: () async {
              final selectedDirectory =
                  await FilePicker.platform.getDirectoryPath();
              if (selectedDirectory != null) {
                final manifestPath = p.join(selectedDirectory, 'project.json');
                await notifier.loadProject(manifestPath);
              }
            },
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.placemark,
            tooltip: 'New Map',
            onPressed: state.project != null && state.projectRootPath != null
                ? () => TopToolbar._showNewMapDialog(
                      context,
                      notifier,
                      defaultWidth: settings.defaultMapWidth,
                      defaultHeight: settings.defaultMapHeight,
                    )
                : null,
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.gear,
            tooltip: 'Project Settings',
            onPressed: state.project != null
                ? () => TopToolbar._showProjectSettingsDialog(
                      context,
                      notifier,
                      state.project!,
                    )
                : null,
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.rectangle_arrow_up_right_arrow_down_left,
            tooltip: 'Resize Map',
            onPressed: isMapWorkspace && state.activeMap != null
                ? () => TopToolbar._showResizeMapDialog(
                      context,
                      notifier,
                      currentWidth: state.activeMap!.size.width,
                      currentHeight: state.activeMap!.size.height,
                    )
                : null,
          ),
        ],
      ),
      _groupItem(
        context,
        overflowLabel: 'History',
        children: [
          if (state.isSaving)
            const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: ProgressCircle(),
              ),
            )
          else
            _ToolbarCapsuleButton(
              icon: CupertinoIcons.floppy_disk,
              tooltip: 'Save Map',
              selected: state.isDirty,
              onPressed: state.activeMap != null
                  ? () => notifier.saveActiveMap()
                  : null,
            ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_uturn_left,
            tooltip: 'Undo',
            onPressed: state.canUndoMap ? notifier.undoMap : null,
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.arrow_uturn_right,
            tooltip: 'Redo',
            onPressed: state.canRedoMap ? notifier.redoMap : null,
          ),
        ],
      ),
      _groupItem(
        context,
        overflowLabel: 'Workspace',
        children: [
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.map,
            tooltip: 'Switch to map workspace',
            selected: isMapWorkspace,
            onPressed: notifier.selectMapWorkspace,
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.square_grid_2x2,
            tooltip: 'Switch to tileset workspace',
            selected: state.workspaceMode == EditorWorkspaceMode.tileset,
            onPressed: hasTilesets
                ? () => notifier.selectTilesetWorkspace(
                      state.selectedTilesetEditorId ?? firstTilesetId,
                    )
                : null,
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.link,
            tooltip: 'Switch to global story workspace',
            selected: state.workspaceMode == EditorWorkspaceMode.globalStory,
            onPressed: notifier.selectGlobalStoryWorkspace,
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.flag,
            tooltip: 'Switch to step workspace',
            selected: state.workspaceMode == EditorWorkspaceMode.step,
            onPressed: notifier.selectStepWorkspace,
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.play_rectangle,
            tooltip: 'Switch to cutscene workspace',
            selected: state.workspaceMode == EditorWorkspaceMode.cutscene,
            onPressed: notifier.selectCutsceneWorkspace,
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.text_bubble,
            tooltip: 'Switch to dialogue studio',
            selected: state.workspaceMode == EditorWorkspaceMode.dialogue,
            onPressed: notifier.selectDialogueWorkspace,
          ),
        ],
      ),
      if (showWorldTools)
        _groupItem(
          context,
          overflowLabel: 'Painting Tools',
          children: [
            _ToolbarCapsuleButton(
              icon: CupertinoIcons.selection_pin_in_out,
              tooltip: 'Selection Tool',
              selected: state.activeTool == EditorToolType.selection,
              onPressed: () => notifier.selectTool(EditorToolType.selection),
            ),
            if (activeLayer is TileLayer)
              _ToolbarCapsuleButton(
                icon: CupertinoIcons.paintbrush,
                tooltip: 'Tile Paint Tool',
                selected: state.activeTool == EditorToolType.tilePaint,
                onPressed: () => notifier.selectTool(EditorToolType.tilePaint),
              ),
            if (activeLayer is TerrainLayer)
              _ToolbarCapsuleButton(
                icon: CupertinoIcons.tree,
                tooltip: 'Terrain Paint Tool',
                selected: state.activeTool == EditorToolType.terrainPaint &&
                    state.terrainSelectionMode == TerrainSelectionMode.terrain,
                onPressed: () =>
                    notifier.selectTool(EditorToolType.terrainPaint),
              ),
            if (activeLayer is PathLayer)
              _ToolbarCapsuleButton(
                icon: CupertinoIcons.map,
                tooltip: 'Path Paint Tool',
                selected: state.activeTool == EditorToolType.terrainPaint &&
                    state.terrainSelectionMode == TerrainSelectionMode.path,
                onPressed: notifier.selectPathPaintMode,
              ),
            if (activeLayer is CollisionLayer) ...[
              _ToolbarCapsuleButton(
                icon: CupertinoIcons.square_grid_2x2,
                tooltip: 'Collision Paint Tool',
                selected: state.activeTool == EditorToolType.collisionPaint,
                onPressed: () => notifier.selectTool(
                  EditorToolType.collisionPaint,
                ),
              ),
              if (showCollisionBrushSize)
                _ToolbarCapsuleButton(
                  icon: state.collisionBrushSizeMode ==
                          CollisionBrushSizeMode.singleTile
                      ? CupertinoIcons.number
                      : CupertinoIcons.square_grid_3x2,
                  tooltip: state.collisionBrushSizeMode ==
                          CollisionBrushSizeMode.singleTile
                      ? 'Collision Brush Size: 1x1'
                      : 'Collision Brush Size: Brush Footprint',
                  selected: state.activeTool == EditorToolType.collisionPaint ||
                      state.activeTool == EditorToolType.eraser,
                  onPressed: notifier.toggleCollisionBrushSizeMode,
                ),
            ],
            if (canEraseOnActiveLayer)
              _ToolbarCapsuleButton(
                icon: CupertinoIcons.delete,
                tooltip: 'Eraser Tool',
                selected: state.activeTool == EditorToolType.eraser,
                onPressed: () => notifier.selectTool(EditorToolType.eraser),
              ),
          ],
        ),
      if (showWorldTools)
        _groupItem(
          context,
          overflowLabel: 'Gameplay Tools',
          children: [
            _ToolbarCapsuleButton(
              icon: CupertinoIcons.sparkles,
              tooltip: 'Entity Tool',
              selected: state.activeTool == EditorToolType.entityPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.entityPlacement,
              ),
            ),
            _ToolbarCapsuleButton(
              icon: CupertinoIcons.flag,
              tooltip: 'Event Tool',
              selected: state.activeTool == EditorToolType.eventPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.eventPlacement,
              ),
            ),
            _ToolbarCapsuleButton(
              icon: CupertinoIcons.square,
              tooltip: 'Trigger Tool',
              selected: state.activeTool == EditorToolType.triggerPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.triggerPlacement,
              ),
            ),
            _ToolbarCapsuleButton(
              icon: CupertinoIcons.arrow_branch,
              tooltip: 'Warp Tool',
              selected: state.activeTool == EditorToolType.warpPlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.warpPlacement,
              ),
            ),
            _ToolbarCapsuleButton(
              icon: CupertinoIcons.leaf_arrow_circlepath,
              tooltip: 'Gameplay Zone Tool',
              selected:
                  state.activeTool == EditorToolType.gameplayZonePlacement,
              onPressed: () => notifier.selectTool(
                EditorToolType.gameplayZonePlacement,
              ),
            ),
          ],
        ),
      if (showContextStrip)
        _groupItem(
          context,
          overflowLabel: 'Context',
          children: [
            if (showTerrainTypePulldown)
              _ToolbarCapsulePulldown(
                label: _terrainTypeLabel(state.selectedTerrainType),
                items: _terrainPulldownItems(notifier),
              ),
            if (showEntityKindPulldown)
              _ToolbarCapsulePulldown(
                label: _entityKindLabel(state.selectedEntityKind),
                items: _entityKindPulldownItems(notifier),
              ),
          ],
        ),
      _groupItem(
        context,
        overflowLabel: 'View',
        children: [
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.minus_circle,
            tooltip: 'Zoom Out',
            onPressed: () => notifier.zoom(-0.1),
          ),
          _ToolbarCapsuleButton(
            icon: CupertinoIcons.plus_circle,
            tooltip: 'Zoom In',
            onPressed: () => notifier.zoom(0.1),
          ),
        ],
      ),
      const ToolBarSpacer(spacerUnits: 4),
      if (state.statusMessage != null)
        CustomToolbarItem(
          inToolbarBuilder: (_) => Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color.lerp(
                EditorChrome.badgeFill(context),
                EditorChrome.chipFill(context),
                0.45,
              ),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              state.statusMessage!,
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          inOverflowedBuilder: (_) => const ToolbarOverflowMenuItem(
            label: 'Status',
            onPressed: null,
          ),
        ),
    ];

    return ToolBar(
      title: _ToolbarBrand(
        projectName: state.project?.name,
        workspaceLabel: switch (state.workspaceMode) {
          EditorWorkspaceMode.map => 'World Editor',
          EditorWorkspaceMode.tileset => 'Tileset Studio',
          EditorWorkspaceMode.globalStory => 'Global Story',
          EditorWorkspaceMode.step => 'Step Studio',
          EditorWorkspaceMode.cutscene => 'Cutscene Studio',
          EditorWorkspaceMode.dialogue => 'Dialogue Studio',
        },
      ),
      titleWidth: 236,
      automaticallyImplyLeading: false,
      centerTitle: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      dividerColor: MacosColors.transparent,
      decoration: BoxDecoration(
        color: EditorChrome.toolbarBarFill(context),
      ),
      actions: actions,
    );
  }

  static CustomToolbarItem _groupItem(
    BuildContext context, {
    required String overflowLabel,
    required List<Widget> children,
  }) {
    return CustomToolbarItem(
      inToolbarBuilder: (_) => _ToolbarCapsuleGroup(children: children),
      inOverflowedBuilder: (_) => ToolbarOverflowMenuItem(
        label: overflowLabel,
        onPressed: null,
      ),
    );
  }

  static String _terrainTypeLabel(TerrainType type) {
    return switch (type) {
      TerrainType.none => 'None',
      TerrainType.grass => 'Grass Base',
      TerrainType.dirt => 'Dirt Base',
      TerrainType.sand => 'Sand Base',
      TerrainType.rock => 'Rock Base',
      TerrainType.stone => 'Stone Base',
      TerrainType.indoor => 'Indoor Base',
    };
  }

  static String _entityKindLabel(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => 'NPC',
      MapEntityKind.sign => 'Sign',
      MapEntityKind.item => 'Item',
      MapEntityKind.spawn => 'Spawn',
      MapEntityKind.custom => 'Custom',
    };
  }

  static Future<void> _showNewProjectDialog(
      BuildContext context, EditorNotifier notifier) async {
    final controller = TextEditingController(text: 'My New Project');
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'New Project',
      controller: controller,
      placeholder: 'The name of your game',
      confirmLabel: 'Create Project',
    );
    if (!context.mounted) return;
    if (!ok) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    final baseDir = await FilePicker.platform.getDirectoryPath();
    if (baseDir != null) {
      final projectDir =
          p.join(baseDir, name.replaceAll(' ', '_').toLowerCase());
      await notifier.createProject(name, projectDir);
    }
  }

  static Future<void> _showNewMapDialog(
    BuildContext context,
    EditorNotifier notifier, {
    required int defaultWidth,
    required int defaultHeight,
  }) async {
    final controller = TextEditingController();
    final ok = await showMacosEditorPromptSheet(
      context,
      title: 'New Root Map',
      controller: controller,
      placeholder: 'Map ID',
      confirmLabel: 'Create',
    );
    if (!context.mounted) return;
    if (!ok) return;
    final id = controller.text.trim();
    if (id.isEmpty) return;
    notifier.createMap(
      id,
      defaultWidth,
      defaultHeight,
    );
  }

  static void _showProjectSettingsDialog(
    BuildContext context,
    EditorNotifier notifier,
    ProjectManifest project,
  ) {
    final settings = project.settings;
    final characters = project.characters;
    final nameController = TextEditingController(text: project.name);
    final tileWidthController =
        TextEditingController(text: settings.tileWidth.toString());
    final tileHeightController =
        TextEditingController(text: settings.tileHeight.toString());
    final displayScaleController =
        TextEditingController(text: settings.displayScale.toString());
    final defaultMapWidthController =
        TextEditingController(text: settings.defaultMapWidth.toString());
    final defaultMapHeightController =
        TextEditingController(text: settings.defaultMapHeight.toString());
    String? defaultPlayerCharacterId = settings.defaultPlayerCharacterId;
    final mistralApiKeyController =
        TextEditingController(text: settings.mistralApiKey ?? '');

    String? validatePositiveInt(String? v) {
      final text = (v ?? '').trim();
      final n = int.tryParse(text);
      if (n == null) return 'Enter a number';
      if (n <= 0) return 'Must be > 0';
      return null;
    }

    String? validatePositiveDouble(String? v) {
      final text = (v ?? '').trim();
      final n = double.tryParse(text);
      if (n == null) return 'Enter a number';
      if (n <= 0) return 'Must be > 0';
      return null;
    }

    showMacosEditorTallSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Project Settings',
                          style: editorMacosSheetTitleStyle(ctx),
                        ),
                      ),
                      MacosIconButton(
                        icon: const MacosIcon(CupertinoIcons.xmark_circle_fill),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TopToolbar._settingsLabeledField(
                        ctx,
                        label: 'Project Name',
                        controller: nameController,
                      ),
                      const SizedBox(height: 12),
                      TopToolbar._settingsLabeledField(
                        ctx,
                        label: 'Tile Width',
                        controller: tileWidthController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                      const SizedBox(height: 12),
                      TopToolbar._settingsLabeledField(
                        ctx,
                        label: 'Tile Height',
                        controller: tileHeightController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                      const SizedBox(height: 12),
                      TopToolbar._settingsLabeledField(
                        ctx,
                        label: 'Display Scale',
                        controller: displayScaleController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
                        ],
                      ),
                      const SizedBox(height: 12),
                      TopToolbar._settingsLabeledField(
                        ctx,
                        label: 'Default Map Width',
                        controller: defaultMapWidthController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                      const SizedBox(height: 12),
                      TopToolbar._settingsLabeledField(
                        ctx,
                        label: 'Default Map Height',
                        controller: defaultMapHeightController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                      ),
                      const SizedBox(height: 12),
                      TopToolbar._settingsCharacterField(
                        ctx,
                        characters: characters,
                        selectedCharacterId: defaultPlayerCharacterId,
                        onPressed: () async {
                          final picked = await showCupertinoListPicker<
                              ProjectCharacterEntry?>(
                            context: ctx,
                            title: 'Default Player Character',
                            items: [null, ...characters],
                            labelOf: (value) => value?.name ?? 'None',
                          );
                          setSheetState(
                            () => defaultPlayerCharacterId = picked?.id,
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'IA (éditeur)',
                        style: editorMacosSheetTitleStyle(ctx).copyWith(
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Clé utilisée par Dialogue Studio et les futures intégrations '
                        'IA. Elle est enregistrée dans project.json — évitez les dépôts '
                        'publics ou utilisez plutôt la variable d’environnement MISTRAL_API_KEY.',
                        style: MacosTheme.of(ctx).typography.caption1.copyWith(
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(ctx),
                            ),
                      ),
                      const SizedBox(height: 10),
                      TopToolbar._settingsLabeledField(
                        ctx,
                        label: 'Clé API Mistral',
                        controller: mistralApiKeyController,
                        obscureText: true,
                        placeholder: 'sk-… (optionnel si MISTRAL_API_KEY est définie)',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) return;
                          final e1 =
                              validatePositiveInt(tileWidthController.text);
                          final e2 =
                              validatePositiveInt(tileHeightController.text);
                          final e3 = validatePositiveDouble(
                              displayScaleController.text);
                          final e4 = validatePositiveInt(
                              defaultMapWidthController.text);
                          final e5 = validatePositiveInt(
                              defaultMapHeightController.text);
                          if (e1 != null ||
                              e2 != null ||
                              e3 != null ||
                              e4 != null ||
                              e5 != null) {
                            return;
                          }
                          final mistralKey = mistralApiKeyController.text.trim();
                          final updatedSettings = settings.copyWith(
                            tileWidth:
                                int.parse(tileWidthController.text.trim()),
                            tileHeight:
                                int.parse(tileHeightController.text.trim()),
                            displayScale: double.parse(
                              displayScaleController.text.trim(),
                            ),
                            defaultMapWidth: int.parse(
                              defaultMapWidthController.text.trim(),
                            ),
                            defaultMapHeight: int.parse(
                              defaultMapHeightController.text.trim(),
                            ),
                            defaultPlayerCharacterId: defaultPlayerCharacterId,
                            mistralApiKey:
                                mistralKey.isEmpty ? null : mistralKey,
                          );
                          Navigator.pop(ctx);
                          await notifier.updateProjectSettings(
                            name: name,
                            settings: updatedSettings,
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _showResizeMapDialog(
    BuildContext context,
    EditorNotifier notifier, {
    required int currentWidth,
    required int currentHeight,
  }) async {
    final widthController =
        TextEditingController(text: currentWidth.toString());
    final heightController =
        TextEditingController(text: currentHeight.toString());

    String? validatePositiveInt(String? v) {
      final text = (v ?? '').trim();
      final n = int.tryParse(text);
      if (n == null) return 'Enter a number';
      if (n <= 0) return 'Must be > 0';
      return null;
    }

    var saved = false;
    await showMacosSheet<void>(
      context: context,
      builder: (ctx) => MacosSheet(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Resize Map',
                  textAlign: TextAlign.center,
                  style: MacosTheme.of(ctx).typography.title2,
                ),
                const SizedBox(height: 16),
                MacosTextField(
                  controller: widthController,
                  placeholder: 'Width (e.g. 20)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                MacosTextField(
                  controller: heightController,
                  placeholder: 'Height (e.g. 15)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: PushButton(
                        controlSize: ControlSize.large,
                        secondary: true,
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PushButton(
                        controlSize: ControlSize.large,
                        onPressed: () {
                          if (validatePositiveInt(widthController.text) !=
                                  null ||
                              validatePositiveInt(heightController.text) !=
                                  null) {
                            return;
                          }
                          saved = true;
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Resize'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!context.mounted || !saved) return;
    final w = int.parse(widthController.text.trim());
    final h = int.parse(heightController.text.trim());
    await notifier.resizeActiveMap(w, h);
  }

  static Widget _settingsLabeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    String? placeholder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: editorMacosFormLabelStyle(context)),
        const SizedBox(height: 6),
        MacosTextField(
          controller: controller,
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          obscureText: obscureText,
          placeholder: placeholder,
        ),
      ],
    );
  }

  static Widget _settingsCharacterField(
    BuildContext context, {
    required List<ProjectCharacterEntry> characters,
    required String? selectedCharacterId,
    required Future<void> Function() onPressed,
  }) {
    String label = 'None';
    for (final character in characters) {
      if (character.id == selectedCharacterId) {
        label = character.name;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Default Player Character',
            style: editorMacosFormLabelStyle(context)),
        const SizedBox(height: 6),
        PushButton(
          controlSize: ControlSize.large,
          secondary: true,
          onPressed: () {
            onPressed();
          },
          child: Text(label),
        ),
        const SizedBox(height: 4),
        Text(
          'Initial overworld appearance used at game start. Runtime may change it later.',
          style: MacosTheme.of(context).typography.caption1.copyWith(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
        ),
      ],
    );
  }
}

class _ToolbarBrand extends StatelessWidget {
  const _ToolbarBrand({
    required this.projectName,
    required this.workspaceLabel,
  });

  final String? projectName;
  final String workspaceLabel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const honey = EditorChrome.inspectorJoyHoney;
    const cyan = EditorChrome.inspectorJoyCyan;

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(CupertinoColors.white, honey, 0.75)!,
                  Color.lerp(cyan, const Color(0xFF102828), 0.4)!,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: honey.withValues(alpha: 0.9),
                width: 1.25,
              ),
            ),
            alignment: Alignment.center,
            child: const MacosIcon(
              CupertinoIcons.square_stack_3d_up_fill,
              color: CupertinoColors.white,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RPG Map Editor',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.15,
                  ),
                ),
                Text(
                  projectName == null
                      ? workspaceLabel
                      : '$projectName  •  $workspaceLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarCapsuleGroup extends StatelessWidget {
  const _ToolbarCapsuleGroup({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visibleChildren =
        children.whereType<Widget>().toList(growable: false);
    return SizedBox(
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EditorChrome.toolbarCapsuleFill(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF524A64),
            width: 1,
          ),
          boxShadow: EditorChrome.toolbarCapsuleShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < visibleChildren.length; index++) ...[
                visibleChildren[index],
                if (index < visibleChildren.length - 1)
                  const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarCapsuleButton extends StatefulWidget {
  const _ToolbarCapsuleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;

  @override
  State<_ToolbarCapsuleButton> createState() => _ToolbarCapsuleButtonState();
}

class _ToolbarCapsuleButtonState extends State<_ToolbarCapsuleButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const accent = EditorChrome.accentPrimary;
    final enabled = widget.onPressed != null;
    final capsule = EditorChrome.toolbarCapsuleFill(context);
    final selectedFill = Color.lerp(capsule, accent, 0.26)!;
    final iconColor = !enabled
        ? CupertinoColors.inactiveGray.resolveFrom(context)
        : (widget.selected ? accent : EditorChrome.primaryLabel(context));
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.selected
            ? selectedFill
            : (_hovered ? EditorChrome.toolbarMutedHoverFill(context) : null),
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: MacosIcon(
        widget.icon,
        size: 17,
        color: iconColor,
      ),
    );

    return MacosTooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
        onExit: enabled ? (_) => setState(() => _hovered = false) : null,
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: widget.onPressed,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      ),
    );
  }
}

class _ToolbarCapsulePulldown extends StatelessWidget {
  const _ToolbarCapsulePulldown({
    required this.label,
    required this.items,
  });

  final String label;
  final List<MacosPulldownMenuEntry> items;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: EditorChrome.toolbarPulldownTrackFill(context),
        borderRadius: BorderRadius.circular(9),
      ),
      child: SizedBox(
        height: 32,
        child: MacosPulldownButton(
          items: items,
          title: label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
