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

  static CustomToolbarItem _divider(BuildContext context) {
    final color = MacosTheme.of(context).dividerColor;
    return CustomToolbarItem(
      inToolbarBuilder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          width: 1,
          height: 22,
          child: DecoratedBox(decoration: BoxDecoration(color: color)),
        ),
      ),
    );
  }

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
    final accent = EditorChrome.activeAccent(context);
    final subtle = EditorChrome.subtleLabel(context);

    final actions = <ToolbarItem>[
      ToolBarIconButton(
        label: 'New Project',
        tooltipMessage: 'New Project',
        showLabel: false,
        icon: const MacosIcon(CupertinoIcons.folder_badge_plus),
        onPressed: () => TopToolbar._showNewProjectDialog(context, notifier),
      ),
      ToolBarIconButton(
        label: 'Open Project',
        tooltipMessage: 'Open Project',
        showLabel: false,
        icon: const MacosIcon(CupertinoIcons.folder_open),
        onPressed: () async {
          final selectedDirectory =
              await FilePicker.platform.getDirectoryPath();
          if (selectedDirectory != null) {
            final manifestPath = p.join(selectedDirectory, 'project.json');
            await notifier.loadProject(manifestPath);
          }
        },
      ),
      _divider(context),
      ToolBarIconButton(
        label: 'New Map',
        tooltipMessage: 'New Map (Root)',
        showLabel: false,
        icon: const MacosIcon(CupertinoIcons.placemark),
        onPressed: state.project != null && state.projectRootPath != null
            ? () => TopToolbar._showNewMapDialog(
                  context,
                  notifier,
                  defaultWidth: settings.defaultMapWidth,
                  defaultHeight: settings.defaultMapHeight,
                )
            : null,
      ),
      ToolBarIconButton(
        label: 'Project Settings',
        tooltipMessage: 'Project Settings',
        showLabel: false,
        icon: const MacosIcon(CupertinoIcons.gear),
        onPressed: state.project != null
            ? () => TopToolbar._showProjectSettingsDialog(
                  context,
                  notifier,
                  state.project!,
                )
            : null,
      ),
      if (state.isSaving)
        CustomToolbarItem(
          tooltipMessage: 'Saving…',
          inToolbarBuilder: (_) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Center(child: ProgressCircle()),
            ),
          ),
        )
      else
        ToolBarIconButton(
          label: 'Save Map',
          tooltipMessage: 'Save Map',
          showLabel: false,
          icon: MacosIcon(
            CupertinoIcons.floppy_disk,
            color: state.isDirty ? accent : null,
          ),
          onPressed:
              state.activeMap != null ? () => notifier.saveActiveMap() : null,
        ),
      ToolBarIconButton(
        label: 'Undo',
        tooltipMessage: 'Undo',
        showLabel: false,
        icon: const MacosIcon(CupertinoIcons.arrow_uturn_left),
        onPressed: state.canUndoMap ? notifier.undoMap : null,
      ),
      ToolBarIconButton(
        label: 'Redo',
        tooltipMessage: 'Redo',
        showLabel: false,
        icon: const MacosIcon(CupertinoIcons.arrow_uturn_right),
        onPressed: state.canRedoMap ? notifier.redoMap : null,
      ),
      ToolBarIconButton(
        label: 'Resize Map',
        tooltipMessage: 'Resize Map',
        showLabel: false,
        icon: const MacosIcon(
          CupertinoIcons.rectangle_arrow_up_right_arrow_down_left,
        ),
        onPressed: state.activeMap != null
            ? () => TopToolbar._showResizeMapDialog(
                  context,
                  notifier,
                  currentWidth: state.activeMap!.size.width,
                  currentHeight: state.activeMap!.size.height,
                )
            : null,
      ),
      _divider(context),
      ToolBarIconButton(
        label: 'Selection',
        tooltipMessage: 'Selection Tool',
        showLabel: false,
        icon: MacosIcon(
          CupertinoIcons.selection_pin_in_out,
          color: state.activeTool == EditorToolType.selection ? accent : null,
        ),
        onPressed: () => notifier.selectTool(EditorToolType.selection),
      ),
      ToolBarIconButton(
        label: 'Tile Paint',
        tooltipMessage: 'Tile Paint Tool',
        showLabel: false,
        icon: MacosIcon(
          CupertinoIcons.paintbrush,
          color: state.activeTool == EditorToolType.tilePaint ? accent : null,
        ),
        onPressed: () => notifier.selectTool(EditorToolType.tilePaint),
      ),
      ToolBarIconButton(
        label: 'Terrain Paint',
        tooltipMessage: 'Terrain Paint Tool',
        showLabel: false,
        icon: MacosIcon(
          CupertinoIcons.tree,
          color: state.activeTool == EditorToolType.terrainPaint
              ? accent
              : null,
        ),
        onPressed: () => notifier.selectTool(EditorToolType.terrainPaint),
      ),
      ToolBarIconButton(
        label: 'Path Paint',
        tooltipMessage: 'Path Paint Tool',
        showLabel: false,
        icon: MacosIcon(
          CupertinoIcons.map,
          color: state.activeTool == EditorToolType.terrainPaint &&
                  state.terrainSelectionMode == TerrainSelectionMode.path
              ? accent
              : null,
        ),
        onPressed: notifier.selectPathPaintMode,
      ),
      ToolBarPullDownButton(
        label: 'Terrain Type',
        tooltipMessage:
            'Terrain Type: ${_terrainTypeLabel(state.selectedTerrainType)}',
        icon: _terrainTypeIcon(state.selectedTerrainType),
        items: _terrainPulldownItems(notifier),
      ),
      ToolBarIconButton(
        label: 'Collision Paint',
        tooltipMessage: 'Collision Paint Tool',
        showLabel: false,
        icon: MacosIcon(
          CupertinoIcons.square_grid_2x2,
          color: state.activeTool == EditorToolType.collisionPaint
              ? accent
              : null,
        ),
        onPressed: () => notifier.selectTool(EditorToolType.collisionPaint),
      ),
      ToolBarIconButton(
        label: 'Collision brush size',
        tooltipMessage: state.collisionBrushSizeMode ==
                CollisionBrushSizeMode.singleTile
            ? 'Collision Brush Size: 1x1'
            : 'Collision Brush Size: Brush Footprint',
        showLabel: false,
        icon: MacosIcon(
          state.collisionBrushSizeMode == CollisionBrushSizeMode.singleTile
              ? CupertinoIcons.number
              : CupertinoIcons.square_grid_3x2,
          color: state.activeTool == EditorToolType.collisionPaint ||
                  (state.activeTool == EditorToolType.eraser &&
                      state.activeLayerId != null)
              ? accent
              : null,
        ),
        onPressed: () => notifier.toggleCollisionBrushSizeMode(),
      ),
      ToolBarIconButton(
        label: 'Eraser',
        tooltipMessage: 'Eraser Tool',
        showLabel: false,
        icon: MacosIcon(
          CupertinoIcons.delete,
          color: state.activeTool == EditorToolType.eraser ? accent : null,
        ),
        onPressed: () => notifier.selectTool(EditorToolType.eraser),
      ),
      ToolBarIconButton(
        label: 'Entity',
        tooltipMessage: 'Entity Tool',
        showLabel: false,
        icon: MacosIcon(
          CupertinoIcons.sparkles,
          color: state.activeTool == EditorToolType.entityPlacement
              ? accent
              : null,
        ),
        onPressed: () => notifier.selectTool(EditorToolType.entityPlacement),
      ),
      if (state.activeTool == EditorToolType.entityPlacement)
        ToolBarPullDownButton(
          label: 'Entity Kind',
          tooltipMessage:
              'Entity Kind: ${_entityKindLabel(state.selectedEntityKind)}',
          icon: _entityKindIcon(state.selectedEntityKind),
          items: _entityKindPulldownItems(notifier),
        ),
      ToolBarIconButton(
        label: 'Trigger',
        tooltipMessage: 'Trigger Tool',
        showLabel: false,
        icon: MacosIcon(
          CupertinoIcons.square,
          color: state.activeTool == EditorToolType.triggerPlacement
              ? accent
              : null,
        ),
        onPressed: () => notifier.selectTool(EditorToolType.triggerPlacement),
      ),
      ToolBarIconButton(
        label: 'Warp',
        tooltipMessage: 'Warp Tool',
        showLabel: false,
        icon: MacosIcon(
          CupertinoIcons.arrow_branch,
          color: state.activeTool == EditorToolType.warpPlacement
              ? accent
              : null,
        ),
        onPressed: () => notifier.selectTool(EditorToolType.warpPlacement),
      ),
      _divider(context),
      ToolBarIconButton(
        label: 'Zoom In',
        tooltipMessage: 'Zoom In',
        showLabel: false,
        icon: const MacosIcon(CupertinoIcons.plus_circle),
        onPressed: () => notifier.zoom(0.1),
      ),
      ToolBarIconButton(
        label: 'Zoom Out',
        tooltipMessage: 'Zoom Out',
        showLabel: false,
        icon: const MacosIcon(CupertinoIcons.minus_circle),
        onPressed: () => notifier.zoom(-0.1),
      ),
      const ToolBarSpacer(spacerUnits: 6),
      if (state.statusMessage != null)
        CustomToolbarItem(
          inToolbarBuilder: (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              state.statusMessage!,
              style: TextStyle(color: subtle, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
    ];

    return ToolBar(
      title: const Text('RPG Editor'),
      titleWidth: 128,
      automaticallyImplyLeading: false,
      centerTitle: false,
      actions: actions,
    );
  }

  static IconData _terrainTypeIcon(TerrainType type) {
    return switch (type) {
      TerrainType.none => CupertinoIcons.clear_circled,
      TerrainType.grass => CupertinoIcons.leaf_arrow_circlepath,
      TerrainType.dirt => CupertinoIcons.circle_grid_hex,
      TerrainType.sand => CupertinoIcons.circle_grid_3x3,
      TerrainType.rock => CupertinoIcons.circle_grid_hex,
      TerrainType.stone => CupertinoIcons.square_grid_4x3_fill,
      TerrainType.indoor => CupertinoIcons.house,
    };
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

  static IconData _entityKindIcon(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => CupertinoIcons.person,
      MapEntityKind.sign => CupertinoIcons.textformat,
      MapEntityKind.item => CupertinoIcons.cube_box,
      MapEntityKind.spawn => CupertinoIcons.flag,
      MapEntityKind.custom => CupertinoIcons.square_stack_3d_up,
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
      builder: (ctx) => ListView(
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
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'))
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
                      final e1 = validatePositiveInt(tileWidthController.text);
                      final e2 = validatePositiveInt(tileHeightController.text);
                      final e3 =
                          validatePositiveDouble(displayScaleController.text);
                      final e4 =
                          validatePositiveInt(defaultMapWidthController.text);
                      final e5 =
                          validatePositiveInt(defaultMapHeightController.text);
                      if (e1 != null ||
                          e2 != null ||
                          e3 != null ||
                          e4 != null ||
                          e5 != null) {
                        return;
                      }
                      final updatedSettings = settings.copyWith(
                        tileWidth:
                            int.parse(tileWidthController.text.trim()),
                        tileHeight:
                            int.parse(tileHeightController.text.trim()),
                        displayScale: double.parse(
                            displayScaleController.text.trim()),
                        defaultMapWidth: int.parse(
                            defaultMapWidthController.text.trim()),
                        defaultMapHeight: int.parse(
                            defaultMapHeightController.text.trim()),
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
        ),
      ],
    );
  }
}
