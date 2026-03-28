import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';
import '../shared/inspector_embedded_widgets.dart';

class WarpPropertiesPanel extends ConsumerStatefulWidget {
  const WarpPropertiesPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<WarpPropertiesPanel> createState() =>
      _WarpPropertiesPanelState();
}

class _WarpPropertiesPanelState extends ConsumerState<WarpPropertiesPanel> {
  final _idController = TextEditingController();
  final _targetXController = TextEditingController();
  final _targetYController = TextEditingController();
  final _paddingTopController = TextEditingController();
  final _paddingRightController = TextEditingController();
  final _paddingBottomController = TextEditingController();
  final _paddingLeftController = TextEditingController();
  String? _boundWarpId;
  String? _selectedTargetMapId;
  MapWarpTriggerMode _selectedTriggerMode = MapWarpTriggerMode.onEnter;
  Set<EntityFacing> _selectedApproachFacings = <EntityFacing>{};

  @override
  void dispose() {
    _idController.dispose();
    _targetXController.dispose();
    _targetYController.dispose();
    _paddingTopController.dispose();
    _paddingRightController.dispose();
    _paddingBottomController.dispose();
    _paddingLeftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final project = state.project;
    final projectMaps = project == null
        ? <ProjectMapEntry>[]
        : List<ProjectMapEntry>.from(project.maps);
    projectMaps.sort((a, b) {
      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) return sortCompare;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    final projectMapById = <String, ProjectMapEntry>{
      for (final mapEntry in projectMaps) mapEntry.id: mapEntry,
    };
    final selectedWarp = notifier.getSelectedWarp();
    _syncControllers(selectedWarp);

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.inspectorJoyOrchid;
    final labelColor = CupertinoColors.label.resolveFrom(context);

    final content = map == null
        ? Center(
            child: Text(
              widget.embedded ? 'Aucune carte chargée' : 'No map loaded',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        : ListView(
            padding: widget.embedded
                ? kInspectorTileBodyPadding
                : const EdgeInsets.fromLTRB(8, 8, 8, 8),
            children: [
              if (map.warps.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    widget.embedded
                        ? 'Aucun warp sur cette carte.\nChoisissez l’outil Warp et cliquez sur la carte pour en ajouter.'
                        : 'No warps on this map.\nSelect the Warp tool and click on the map to add one.',
                    style: TextStyle(
                      color:
                          CupertinoColors.placeholderText.resolveFrom(context),
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ...map.warps.map(
                  (warp) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: warp.id == state.selectedWarpId
                            ? Color.lerp(
                                EditorChrome.islandFillElevated(context),
                                accent,
                                0.28,
                              )!
                            : EditorChrome.islandFillElevated(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: warp.id == state.selectedWarpId
                              ? accent.withValues(alpha: 0.78)
                              : EditorChrome.editorIslandRim(context),
                          width: 1,
                        ),
                        boxShadow:
                            EditorChrome.inspectorTileHardShadows(context),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                        alignment: Alignment.centerLeft,
                        onPressed: () => notifier.selectWarp(warp.id),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              CupertinoIcons.arrow_branch,
                              size: 16,
                              color: warp.id == state.selectedWarpId
                                  ? accent
                                  : subtle,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    warp.id,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: labelColor,
                                      fontWeight:
                                          warp.id == state.selectedWarpId
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '(${warp.pos.x}, ${warp.pos.y}) -> ${_buildTargetMapLabel(warp.targetMapId, projectMapById)} (${warp.targetPos.x}, ${warp.targetPos.y})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtle,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_modeLabel(warp.triggerMode, embedded: widget.embedded)} · ${_approachSummary(warp.allowedApproachFacings, embedded: widget.embedded)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: subtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const EditorHorizontalDivider(),
              const SizedBox(height: 8),
              if (selectedWarp == null)
                Text(
                  widget.embedded
                      ? 'Sélectionnez un warp pour modifier ses propriétés.'
                      : 'Select a warp to edit its properties.',
                  style: TextStyle(
                    color: CupertinoColors.placeholderText.resolveFrom(context),
                    fontSize: 12,
                  ),
                )
              else
                _buildSelectedWarpEditor(
                  context: context,
                  notifier: notifier,
                  selectedWarp: selectedWarp,
                  projectMaps: projectMaps,
                  projectMapById: projectMapById,
                  embedded: widget.embedded,
                ),
            ],
          );

    if (widget.embedded) {
      return content;
    }

    return Container(
      decoration: BoxDecoration(
        color: EditorChrome.islandFill(context),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'WARPS',
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.bold,
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                ),
                Text(
                  map == null ? '0' : '${map.warps.length}',
                  style: TextStyle(fontSize: 11, color: subtle),
                ),
              ],
            ),
          ),
          const EditorHorizontalDivider(),
          Expanded(child: content),
        ],
      ),
    );
  }

  Future<void> _pickTargetMap(
    BuildContext context,
    List<ProjectMapEntry> projectMaps,
  ) async {
    final picked = await showMacosListPicker<ProjectMapEntry>(
      context: context,
      title: 'Target Map',
      items: projectMaps,
      labelOf: (m) => '${m.name} (${m.id})',
    );
    if (picked != null) {
      setState(() => _selectedTargetMapId = picked.id);
    }
  }

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondary,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoTextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
        ),
      ],
    );
  }

  Widget _buildSelectedWarpEditor({
    required BuildContext context,
    required EditorNotifier notifier,
    required MapWarp selectedWarp,
    required List<ProjectMapEntry> projectMaps,
    required Map<String, ProjectMapEntry> projectMapById,
    required bool embedded,
  }) {
    const orchid = EditorChrome.inspectorJoyOrchid;
    final currentTargetMapEntry = projectMapById[selectedWarp.targetMapId];
    final currentTargetMapLabel = currentTargetMapEntry == null
        ? (embedded
            ? 'Carte manquante : ${selectedWarp.targetMapId}'
            : 'Missing map: ${selectedWarp.targetMapId}')
        : '${currentTargetMapEntry.name} (${currentTargetMapEntry.id})';
    final canCreateReturnWarp = currentTargetMapEntry != null;
    final pickedTargetMapId = _selectedTargetMapId;
    final pickedTargetMapExists = pickedTargetMapId != null &&
        projectMapById.containsKey(pickedTargetMapId);
    final rawTargetId = pickedTargetMapId ?? '';
    final mapMenuIds = <String>[
      '',
      if (rawTargetId.isNotEmpty && !projectMapById.containsKey(rawTargetId))
        rawTargetId,
      ...projectMaps.map((m) => m.id),
    ];
    final effectiveMenuId =
        mapMenuIds.contains(rawTargetId) ? rawTargetId : mapMenuIds.first;
    final tid = pickedTargetMapId;
    final targetValueLabel = tid == null || tid.isEmpty
        ? (embedded ? 'Choisir une carte…' : 'Select target map')
        : pickedTargetMapExists
            ? '${projectMapById[tid]!.name} ($tid)'
            : (embedded ? 'Manquante : $tid' : 'Missing: $tid');

    Future<void> onSaveWarp() async {
      final x = int.tryParse(_targetXController.text.trim());
      final y = int.tryParse(_targetYController.text.trim());
      final top = int.tryParse(_paddingTopController.text.trim());
      final right = int.tryParse(_paddingRightController.text.trim());
      final bottom = int.tryParse(_paddingBottomController.text.trim());
      final left = int.tryParse(_paddingLeftController.text.trim());
      if (x == null || y == null) {
        await showCupertinoEditorAlert(
          context,
          message: embedded
              ? 'Les coordonnées cible doivent être des entiers valides.'
              : 'Target position must be valid integers',
        );
        return;
      }
      if (top == null || right == null || bottom == null || left == null) {
        await showCupertinoEditorAlert(
          context,
          message: embedded
              ? 'Les marges d’activation doivent être des entiers valides.'
              : 'Activation padding must be valid integers',
        );
        return;
      }
      if (top < 0 || right < 0 || bottom < 0 || left < 0) {
        await showCupertinoEditorAlert(
          context,
          message: embedded
              ? 'Les marges d’activation doivent être positives.'
              : 'Activation padding must be non-negative',
        );
        return;
      }
      final targetMapId = _selectedTargetMapId?.trim();
      if (targetMapId == null || targetMapId.isEmpty) {
        await showCupertinoEditorAlert(
          context,
          message:
              embedded ? 'Choisissez une carte cible.' : 'Select a target map',
        );
        return;
      }
      final sortedApproachFacings = _selectedApproachFacings.toList(
          growable: false)
        ..sort((a, b) => a.index.compareTo(b.index));
      notifier.updateSelectedWarp(
        id: _idController.text.trim(),
        targetMapId: targetMapId,
        targetPosX: x,
        targetPosY: y,
        triggerMode: _selectedTriggerMode,
        allowedApproachFacings: sortedApproachFacings,
        triggerPadding: WarpTriggerPadding(
          top: top,
          right: right,
          bottom: bottom,
          left: left,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (embedded)
          const InspectorEmbeddedSectionLabel('Warp sélectionné')
        else
          Text(
            'Selected Warp',
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          embedded
              ? 'Position sur la carte : (${selectedWarp.pos.x}, ${selectedWarp.pos.y})'
              : 'Map position: (${selectedWarp.pos.x}, ${selectedWarp.pos.y})',
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          embedded
              ? 'Destination : $currentTargetMapLabel en (${selectedWarp.targetPos.x}, ${selectedWarp.targetPos.y})'
              : 'Destination: $currentTargetMapLabel at (${selectedWarp.targetPos.x}, ${selectedWarp.targetPos.y})',
          style: TextStyle(
            fontSize: 11,
            color: currentTargetMapEntry == null
                ? EditorPaintColors.amber
                : CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        _labeledField(
          context,
          label: embedded ? 'Identifiant' : 'ID',
          controller: _idController,
        ),
        const SizedBox(height: 8),
        if (embedded) ...[
          if (projectMaps.isNotEmpty)
            InspectorEmbeddedDropdown(
              accent: orchid,
              fieldLabel: 'Carte cible',
              valueLabel: targetValueLabel,
              orderedIds: mapMenuIds,
              selectedMenuValue: effectiveMenuId,
              selectedIdForCheck: rawTargetId.isEmpty ? null : rawTargetId,
              idToLabel: (id) => id.isEmpty
                  ? '—'
                  : projectMapById.containsKey(id)
                      ? '${projectMapById[id]!.name} ($id)'
                      : (embedded ? 'Manquante : $id' : 'Missing: $id'),
              onSelected: (id) {
                setState(() {
                  _selectedTargetMapId = id.isEmpty ? null : id;
                });
              },
              tooltip: 'Carte de destination du warp',
            )
          else
            Text(
              'Aucune autre carte dans le projet.',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
        ] else ...[
          Text(
            'Target Map',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          const SizedBox(height: 6),
          CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: projectMaps.isEmpty
                ? null
                : () => _pickTargetMap(context, projectMaps),
            child: Text(
              pickedTargetMapId == null
                  ? 'Select target map'
                  : (pickedTargetMapExists
                      ? '${projectMapById[pickedTargetMapId]!.name} ($pickedTargetMapId)'
                      : 'Missing: $pickedTargetMapId'),
            ),
          ),
        ],
        if (pickedTargetMapId != null && !pickedTargetMapExists) ...[
          const SizedBox(height: 6),
          Text(
            embedded
                ? 'La carte cible est absente du projet : $pickedTargetMapId'
                : 'Current target map is missing from project: $pickedTargetMapId',
            style:
                const TextStyle(fontSize: 11, color: EditorPaintColors.amber),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _labeledField(
                context,
                label: embedded ? 'Cible X' : 'Target X',
                controller: _targetXController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _labeledField(
                context,
                label: embedded ? 'Cible Y' : 'Target Y',
                controller: _targetYController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildTriggerModeSelector(
          context,
          embedded: embedded,
        ),
        const SizedBox(height: 8),
        _buildApproachFacingSelector(
          context,
          embedded: embedded,
        ),
        const SizedBox(height: 8),
        _buildPaddingEditor(
          context,
          embedded: embedded,
        ),
        const SizedBox(height: 10),
        if (embedded)
          Row(
            children: [
              Expanded(
                child: InspectorEmbeddedPrimaryCapsule(
                  accent: orchid,
                  icon: CupertinoIcons.checkmark_circle_fill,
                  label: 'Enregistrer',
                  prominent: true,
                  enabled: projectMaps.isNotEmpty,
                  onPressed: onSaveWarp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: orchid,
                  icon: CupertinoIcons.trash,
                  label: 'Supprimer',
                  enabled: true,
                  onPressed: notifier.deleteSelectedWarp,
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: onSaveWarp,
                  child: const Text('Save Warp'),
                ),
              ),
              const SizedBox(width: 8),
              EditorToolbarIconButton(
                onPressed: notifier.deleteSelectedWarp,
                icon: CupertinoIcons.trash,
                tooltip: 'Delete selected warp',
              ),
            ],
          ),
        const SizedBox(height: 8),
        if (embedded)
          InspectorEmbeddedSecondaryCapsule(
            accent: orchid,
            icon: CupertinoIcons.arrow_left_right,
            label: 'Créer le warp retour',
            enabled: canCreateReturnWarp,
            onPressed: notifier.createReciprocalWarpForSelectedWarp,
          )
        else
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              onPressed: canCreateReturnWarp
                  ? notifier.createReciprocalWarpForSelectedWarp
                  : null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.arrow_left_right, size: 18),
                  SizedBox(width: 8),
                  Text('Create Return Warp'),
                ],
              ),
            ),
          ),
        const SizedBox(height: 4),
        Text(
          embedded
              ? 'Ajoute un warp inverse sur la carte cible, à la case d’arrivée.'
              : 'Creates a reciprocal warp in the target map at the destination cell.',
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  void _syncControllers(MapWarp? selectedWarp) {
    final currentId = selectedWarp?.id;
    if (currentId == _boundWarpId) return;
    _boundWarpId = currentId;
    if (selectedWarp == null) {
      _idController.text = '';
      _targetXController.text = '';
      _targetYController.text = '';
      _paddingTopController.text = '0';
      _paddingRightController.text = '0';
      _paddingBottomController.text = '0';
      _paddingLeftController.text = '0';
      _selectedTargetMapId = null;
      _selectedTriggerMode = MapWarpTriggerMode.onEnter;
      _selectedApproachFacings = <EntityFacing>{};
      return;
    }
    _idController.text = selectedWarp.id;
    _selectedTargetMapId = selectedWarp.targetMapId;
    _targetXController.text = selectedWarp.targetPos.x.toString();
    _targetYController.text = selectedWarp.targetPos.y.toString();
    _paddingTopController.text = selectedWarp.triggerPadding.top.toString();
    _paddingRightController.text = selectedWarp.triggerPadding.right.toString();
    _paddingBottomController.text =
        selectedWarp.triggerPadding.bottom.toString();
    _paddingLeftController.text = selectedWarp.triggerPadding.left.toString();
    _selectedTriggerMode = selectedWarp.triggerMode;
    _selectedApproachFacings = selectedWarp.allowedApproachFacings.toSet();
  }

  Widget _buildTriggerModeSelector(
    BuildContext context, {
    required bool embedded,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          embedded ? 'Mode d’activation' : 'Trigger Mode',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondary,
          ),
        ),
        const SizedBox(height: 6),
        CupertinoSlidingSegmentedControl<MapWarpTriggerMode>(
          groupValue: _selectedTriggerMode,
          children: {
            for (final mode in MapWarpTriggerMode.values)
              mode: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  _modeLabel(mode, embedded: embedded),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          },
          onValueChanged: (value) {
            if (value == null) return;
            setState(() => _selectedTriggerMode = value);
          },
        ),
        const SizedBox(height: 4),
        Text(
          _selectedTriggerMode == MapWarpTriggerMode.onEnter
              ? (embedded
                  ? 'Le warp se déclenche quand le joueur entre dans la zone.'
                  : 'Warp triggers when the player enters its area.')
              : (embedded
                  ? 'Le warp se déclenche quand le joueur pousse une case bloquée dans la zone.'
                  : 'Warp triggers when movement is blocked while bumping into its area.'),
          style: TextStyle(fontSize: 11, color: secondary),
        ),
      ],
    );
  }

  Widget _buildApproachFacingSelector(
    BuildContext context, {
    required bool embedded,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.inspectorJoyOrchid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          embedded ? 'Côtés actifs' : 'Active Sides',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final facing in EntityFacing.values)
              _buildFacingToggle(
                context,
                facing: facing,
                embedded: embedded,
                accent: accent,
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _selectedApproachFacings.isEmpty
              ? (embedded
                  ? 'Aucun filtre : le warp est actif depuis tous les côtés.'
                  : 'No filter: warp can trigger from any side.')
              : (embedded
                  ? 'Le warp est actif seulement si le joueur arrive depuis les côtés sélectionnés.'
                  : 'Warp only triggers when the player approaches from selected sides.'),
          style: TextStyle(fontSize: 11, color: secondary),
        ),
      ],
    );
  }

  Widget _buildFacingToggle(
    BuildContext context, {
    required EntityFacing facing,
    required bool embedded,
    required Color accent,
  }) {
    final selected = _selectedApproachFacings.contains(facing);
    final label = _facingLabel(facing, embedded: embedded);
    final baseFill = EditorChrome.largeIslandSurfaceColor(
      context,
      tint: accent.withValues(alpha: selected ? 0.22 : 0.08),
    );
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: () {
        setState(() {
          final next = Set<EntityFacing>.from(_selectedApproachFacings);
          if (next.contains(facing)) {
            next.remove(facing);
          } else {
            next.add(facing);
          }
          _selectedApproachFacings = next;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: baseFill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.85)
                : accent.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _facingIcon(facing),
              size: 14,
              color: selected
                  ? accent
                  : CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: EditorChrome.primaryLabel(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaddingEditor(
    BuildContext context, {
    required bool embedded,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          embedded ? 'Padding d’activation (px)' : 'Activation Padding (px)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: secondary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _paddingField(
                context,
                label: embedded ? 'Haut' : 'Top',
                controller: _paddingTopController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _paddingField(
                context,
                label: embedded ? 'Droite' : 'Right',
                controller: _paddingRightController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _paddingField(
                context,
                label: embedded ? 'Bas' : 'Bottom',
                controller: _paddingBottomController,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _paddingField(
                context,
                label: embedded ? 'Gauche' : 'Left',
                controller: _paddingLeftController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          embedded ? 'Presets rapides' : 'Quick Presets',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: secondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _presetButton(
              context,
              label: embedded ? 'Reset' : 'Reset',
              onPressed: _resetActivationSettings,
            ),
            _presetButton(
              context,
              label: embedded ? 'Porte Sud' : 'Door South',
              onPressed: () => _applyDoorPreset(EntityFacing.south),
            ),
            _presetButton(
              context,
              label: embedded ? 'Porte Nord' : 'Door North',
              onPressed: () => _applyDoorPreset(EntityFacing.north),
            ),
            _presetButton(
              context,
              label: embedded ? 'Porte Est' : 'Door East',
              onPressed: () => _applyDoorPreset(EntityFacing.east),
            ),
            _presetButton(
              context,
              label: embedded ? 'Porte Ouest' : 'Door West',
              onPressed: () => _applyDoorPreset(EntityFacing.west),
            ),
          ],
        ),
      ],
    );
  }

  Widget _presetButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    final accent = EditorChrome.inspectorJoyOrchid.withValues(alpha: 0.78);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: EditorChrome.largeIslandSurfaceColor(
            context,
            tint: accent.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accent.withValues(alpha: 0.45)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: EditorChrome.primaryLabel(context),
          ),
        ),
      ),
    );
  }

  Widget _paddingField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: secondary,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ],
    );
  }

  String _modeLabel(
    MapWarpTriggerMode mode, {
    required bool embedded,
  }) {
    return switch (mode) {
      MapWarpTriggerMode.onEnter => embedded ? 'Entrée' : 'Enter',
      MapWarpTriggerMode.onBump => embedded ? 'Collision' : 'Bump',
    };
  }

  String _approachSummary(
    List<EntityFacing> facings, {
    required bool embedded,
  }) {
    if (facings.isEmpty) {
      return embedded ? 'Tous côtés' : 'All sides';
    }
    return facings
        .map((facing) => _facingLabel(facing, embedded: embedded))
        .join(' · ');
  }

  String _facingLabel(
    EntityFacing facing, {
    required bool embedded,
  }) {
    return switch (facing) {
      EntityFacing.north => embedded ? 'Nord' : 'North',
      EntityFacing.south => embedded ? 'Sud' : 'South',
      EntityFacing.east => embedded ? 'Est' : 'East',
      EntityFacing.west => embedded ? 'Ouest' : 'West',
    };
  }

  IconData _facingIcon(EntityFacing facing) {
    return switch (facing) {
      EntityFacing.north => CupertinoIcons.arrow_up,
      EntityFacing.south => CupertinoIcons.arrow_down,
      EntityFacing.east => CupertinoIcons.arrow_right,
      EntityFacing.west => CupertinoIcons.arrow_left,
    };
  }

  void _resetActivationSettings() {
    setState(() {
      _selectedTriggerMode = MapWarpTriggerMode.onEnter;
      _selectedApproachFacings = <EntityFacing>{};
      _paddingTopController.text = '0';
      _paddingRightController.text = '0';
      _paddingBottomController.text = '0';
      _paddingLeftController.text = '0';
    });
  }

  void _applyDoorPreset(EntityFacing approachSide) {
    setState(() {
      _selectedTriggerMode = MapWarpTriggerMode.onBump;
      _selectedApproachFacings = <EntityFacing>{approachSide};
      var top = 0;
      var right = 0;
      var bottom = 0;
      var left = 0;
      switch (approachSide) {
        case EntityFacing.north:
          top = 8;
          break;
        case EntityFacing.south:
          bottom = 8;
          break;
        case EntityFacing.east:
          right = 8;
          break;
        case EntityFacing.west:
          left = 8;
          break;
      }
      _paddingTopController.text = top.toString();
      _paddingRightController.text = right.toString();
      _paddingBottomController.text = bottom.toString();
      _paddingLeftController.text = left.toString();
    });
  }

  String _buildTargetMapLabel(
    String targetMapId,
    Map<String, ProjectMapEntry> projectMapById,
  ) {
    final targetMapEntry = projectMapById[targetMapId];
    if (targetMapEntry == null) {
      return '$targetMapId (missing)';
    }
    return '${targetMapEntry.name} (${targetMapEntry.id})';
  }
}
