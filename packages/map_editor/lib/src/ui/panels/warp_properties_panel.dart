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
  String? _boundWarpId;
  String? _selectedTargetMapId;

  @override
  void dispose() {
    _idController.dispose();
    _targetXController.dispose();
    _targetYController.dispose();
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
                      color: CupertinoColors.placeholderText.resolveFrom(context),
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
                                      fontWeight: warp.id == state.selectedWarpId
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
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
    final secondary =
        CupertinoColors.secondaryLabel.resolveFrom(context);
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
      if (x == null || y == null) {
        await showCupertinoEditorAlert(
          context,
          message: embedded
              ? 'Les coordonnées cible doivent être des entiers valides.'
              : 'Target position must be valid integers',
        );
        return;
      }
      final targetMapId = _selectedTargetMapId?.trim();
      if (targetMapId == null || targetMapId.isEmpty) {
        await showCupertinoEditorAlert(
          context,
          message: embedded
              ? 'Choisissez une carte cible.'
              : 'Select a target map',
        );
        return;
      }
      notifier.updateSelectedWarp(
        id: _idController.text.trim(),
        targetMapId: targetMapId,
        targetPosX: x,
        targetPosY: y,
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
              selectedIdForCheck:
                  rawTargetId.isEmpty ? null : rawTargetId,
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
            style: const TextStyle(fontSize: 11, color: EditorPaintColors.amber),
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
      _selectedTargetMapId = null;
      return;
    }
    _idController.text = selectedWarp.id;
    _selectedTargetMapId = selectedWarp.targetMapId;
    _targetXController.text = selectedWarp.targetPos.x.toString();
    _targetYController.text = selectedWarp.targetPos.y.toString();
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
