import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';
import '../shared/inspector_embedded_widgets.dart';

/// Source du dialogue sur une entité NPC / panneau (registre projet vs ancien chemin fichier).
enum _DialogueRefSource { none, manifest, legacy }

const _kDialogueNoneMenuId = '__dialogue_none__';
const _kNodeNoneMenuId = '__yarn_node_none__';
const _kElementNoneMenuId = '__entity_element_none__';
const _kTrainerNoneMenuId = '__entity_trainer_none__';
const _kCharacterNoneMenuId = '__entity_character_none__';

String _normalizeDialogueRelPath(String raw) {
  return raw.trim().replaceAll(r'\', '/');
}

Future<List<String>> _extractYarnNodeTitles(String absolutePath) async {
  try {
    final file = File(absolutePath);
    if (!await file.exists()) return const [];
    final lines = await file.readAsLines();
    return [
      for (final line in lines)
        if (line.trim().startsWith('title:'))
          line.trim().substring('title:'.length).trim(),
    ].where((t) => t.isNotEmpty).toList();
  } catch (_) {
    return const [];
  }
}

ProjectDialogueEntry? _dialogueEntryForLegacyPath(
  List<ProjectDialogueEntry> entries,
  String scriptPathRelative,
) {
  final norm = _normalizeDialogueRelPath(scriptPathRelative);
  if (norm.isEmpty) {
    return null;
  }
  for (final e in entries) {
    if (_normalizeDialogueRelPath(e.relativePath) == norm) {
      return e;
    }
  }
  return null;
}

class EntityPropertiesPanel extends ConsumerStatefulWidget {
  const EntityPropertiesPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<EntityPropertiesPanel> createState() =>
      _EntityPropertiesPanelState();
}

class _EntityPropertiesPanelState extends ConsumerState<EntityPropertiesPanel> {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _xController = TextEditingController();
  final _yController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _propertyRows = <_EntityPropertyDraft>[];

  final _npcDialogueId = TextEditingController();
  final _npcScriptPath = TextEditingController();
  final _npcStartNode = TextEditingController();
  EntityFacing _npcFacing = EntityFacing.south;
  String _npcCharacterMenuId = _kCharacterNoneMenuId;
  String _npcTrainerMenuId = _kTrainerNoneMenuId;
  final _npcLineOfSight = TextEditingController();
  final _npcDefeatDialogueId = TextEditingController();
  final _npcDefeatStartNode = TextEditingController();
  _DialogueRefSource _npcDefeatDialogueSource = _DialogueRefSource.none;
  MapEntityNpcMovementMode _npcMovementMode = MapEntityNpcMovementMode.idle;
  bool _npcMovementLoop = true;
  final _npcMovementPauseMs = TextEditingController();
  final _npcMovementStepMs = TextEditingController();
  final _npcWaypointRows = <_NpcWaypointDraft>[];

  final _signTitle = TextEditingController();
  final _signDialogueId = TextEditingController();
  final _signScriptPath = TextEditingController();
  final _signStartNode = TextEditingController();
  final _signPlainText = TextEditingController();

  final _itemGameId = TextEditingController();
  final _itemQuantity = TextEditingController();
  ItemPickupMode _itemPickup = ItemPickupMode.once;
  ItemRespawnPolicy _itemRespawn = ItemRespawnPolicy.none;

  final _spawnKey = TextEditingController();
  final _spawnCategory = TextEditingController();
  EntitySpawnRole _spawnRole = EntitySpawnRole.playerStart;
  EntityFacing _spawnFacing = EntityFacing.south;

  String? _boundFingerprint;
  MapEntityKind _selectedKind = MapEntityKind.npc;
  bool _blocksMovement = true;
  _DialogueRefSource _npcDialogueSource = _DialogueRefSource.none;
  _DialogueRefSource _signDialogueSource = _DialogueRefSource.none;
  String _editorVisualMenuId = _kElementNoneMenuId;

  List<String> _npcDialogueNodes = [];
  List<String> _signDialogueNodes = [];
  List<String> _npcDefeatDialogueNodes = [];

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _xController.dispose();
    _yController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _npcDialogueId.dispose();
    _npcScriptPath.dispose();
    _npcStartNode.dispose();
    _npcLineOfSight.dispose();
    _npcDefeatDialogueId.dispose();
    _npcDefeatStartNode.dispose();
    _npcMovementPauseMs.dispose();
    _npcMovementStepMs.dispose();
    for (final row in _npcWaypointRows) {
      row.dispose();
    }
    _signTitle.dispose();
    _signDialogueId.dispose();
    _signScriptPath.dispose();
    _signStartNode.dispose();
    _signPlainText.dispose();
    _itemGameId.dispose();
    _itemQuantity.dispose();
    _spawnKey.dispose();
    _spawnCategory.dispose();
    for (final row in _propertyRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final selectedEntity = notifier.getSelectedEntity();
    _syncControllers(selectedEntity, state.project);

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final accent = EditorChrome.activeAccent(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);

    final content = map == null
        ? Center(
            child: Text(
              'No map loaded',
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
              if (widget.embedded)
                InspectorEmbeddedDropdown(
                  accent: EditorChrome.inspectorJoyCyan,
                  fieldLabel: 'Type à placer',
                  valueLabel: _entityKindLabel(state.selectedEntityKind),
                  orderedIds: MapEntityKind.values.map((k) => k.name).toList(),
                  selectedMenuValue: state.selectedEntityKind.name,
                  selectedIdForCheck: state.selectedEntityKind.name,
                  idToLabel: (id) => _entityKindLabel(
                    MapEntityKind.values.firstWhere((k) => k.name == id),
                  ),
                  onSelected: (id) {
                    final k = MapEntityKind.values.firstWhere(
                      (e) => e.name == id,
                    );
                    notifier.selectEntityKind(k);
                  },
                  tooltip: 'Type d’entité à placer sur la carte',
                )
              else
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () async {
                    final picked = await showCupertinoListPicker<MapEntityKind>(
                      context: context,
                      title: 'Placement kind',
                      items: MapEntityKind.values,
                      labelOf: _entityKindLabel,
                    );
                    if (picked != null) {
                      notifier.selectEntityKind(picked);
                    }
                  },
                  child: Text(
                    'Placement Kind: ${_entityKindLabel(state.selectedEntityKind)}',
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                state.activeTool == EditorToolType.entityPlacement
                    ? (widget.embedded
                        ? 'Outil Entités actif : cliquez sur la carte pour placer ce type.'
                        : 'Entity tool active. Click on the map to place the selected kind.')
                    : (widget.embedded
                        ? 'Activez l’outil Entités pour placer des éléments sur la carte.'
                        : 'Select the Entity tool to place visible world content on the map.'),
                style: TextStyle(
                  fontSize: 11,
                  color: subtle,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              if (map.entities.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'No entities on this map yet.',
                    style: TextStyle(
                      color:
                          CupertinoColors.placeholderText.resolveFrom(context),
                      fontSize: 12,
                    ),
                  ),
                )
              else
                ...map.entities.map(
                  (entity) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: entity.id == state.selectedEntityId
                            ? Color.lerp(
                                EditorChrome.islandFillElevated(context),
                                _entityColor(entity.kind),
                                0.3,
                              )!
                            : EditorChrome.islandFillElevated(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: entity.id == state.selectedEntityId
                              ? _entityColor(entity.kind)
                                  .withValues(alpha: 0.78)
                              : EditorChrome.editorIslandRim(context),
                          width: 1,
                        ),
                        boxShadow:
                            EditorChrome.inspectorTileHardShadows(context),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                        alignment: Alignment.centerLeft,
                        onPressed: () => notifier.selectEntity(entity.id),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _iconForEntityKind(entity.kind),
                              size: 16,
                              color: entity.id == state.selectedEntityId
                                  ? (widget.embedded
                                      ? EditorChrome.inspectorJoyCyan
                                      : EditorPaintColors.white)
                                  : _entityColor(entity.kind),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entity.inspectorHeadline,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: labelColor,
                                      fontWeight:
                                          entity.id == state.selectedEntityId
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_entityKindLabel(entity.kind)} | ${entity.id} | (${entity.pos.x}, ${entity.pos.y}) ${entity.size.width}x${entity.size.height}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: subtle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (entity.id == state.selectedEntityId)
                              Icon(
                                CupertinoIcons.pencil,
                                size: 12,
                                color: accent,
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
              if (selectedEntity == null)
                Text(
                  'Select an entity to edit its properties.',
                  style: TextStyle(
                    color: CupertinoColors.placeholderText.resolveFrom(context),
                    fontSize: 12,
                  ),
                )
              else
                _buildSelectedEntityEditor(
                  context: context,
                  state: state,
                  notifier: notifier,
                  project: state.project,
                  selectedEntity: selectedEntity,
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
                    'ENTITIES',
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
                  map == null ? '0' : '${map.entities.length}',
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

  String _l(String fr, String en) => widget.embedded ? fr : en;

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLines,
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
          maxLines: maxLines ?? 1,
        ),
      ],
    );
  }

  Widget _toggleField(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: secondary),
          ),
        ),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: EditorChrome.inspectorJoyCyan,
        ),
      ],
    );
  }

  String _facingLabel(EntityFacing f) {
    if (!widget.embedded) return f.name;
    return switch (f) {
      EntityFacing.north => 'Nord',
      EntityFacing.south => 'Sud',
      EntityFacing.east => 'Est',
      EntityFacing.west => 'Ouest',
    };
  }

  String _pickupLabel(ItemPickupMode m) {
    if (!widget.embedded) return m.name;
    return switch (m) {
      ItemPickupMode.once => 'Une fois',
      ItemPickupMode.always => 'Toujours',
      ItemPickupMode.questGated => 'Lié quête',
    };
  }

  String _respawnLabel(ItemRespawnPolicy p) {
    if (!widget.embedded) return p.name;
    return switch (p) {
      ItemRespawnPolicy.none => 'Aucun',
      ItemRespawnPolicy.onMapReload => 'Recharge carte',
      ItemRespawnPolicy.timed => 'Temporisé',
    };
  }

  String _spawnRoleLabel(EntitySpawnRole r) {
    if (!widget.embedded) return r.name;
    return switch (r) {
      EntitySpawnRole.playerStart => 'Départ joueur',
      EntitySpawnRole.event => 'Événement',
      EntitySpawnRole.npcSpawn => 'Apparition PNJ',
      EntitySpawnRole.debug => 'Debug',
      EntitySpawnRole.other => 'Autre',
    };
  }

  String _npcMovementModeLabel(MapEntityNpcMovementMode mode) {
    if (!widget.embedded) return mode.name;
    return switch (mode) {
      MapEntityNpcMovementMode.idle => 'Immobile',
      MapEntityNpcMovementMode.patrol => 'Patrouille',
      MapEntityNpcMovementMode.scriptedOnly => 'Scripted only',
    };
  }

  void _addNpcWaypointRow({GridPos? seed}) {
    final fallbackX = int.tryParse(_xController.text.trim()) ?? 0;
    final fallbackY = int.tryParse(_yController.text.trim()) ?? 0;
    setState(() {
      _npcWaypointRows.add(
        _NpcWaypointDraft(
          xController: TextEditingController(
            text: (seed?.x ?? fallbackX).toString(),
          ),
          yController: TextEditingController(
            text: (seed?.y ?? fallbackY).toString(),
          ),
        ),
      );
    });
  }

  List<Widget> _npcMovementFields(
    BuildContext context,
    EditorState state,
    EditorNotifier notifier,
  ) {
    final modeIds = MapEntityNpcMovementMode.values
        .map((mode) => mode.name)
        .toList(growable: false);

    final modePicker = widget.embedded
        ? InspectorEmbeddedDropdown(
            accent: EditorChrome.inspectorJoyMint,
            fieldLabel: _l('Déplacement PNJ', 'NPC movement'),
            valueLabel: _npcMovementModeLabel(_npcMovementMode),
            orderedIds: modeIds,
            selectedMenuValue: _npcMovementMode.name,
            selectedIdForCheck: _npcMovementMode.name,
            idToLabel: (id) => _npcMovementModeLabel(
              MapEntityNpcMovementMode.values.firstWhere((e) => e.name == id),
            ),
            onSelected: (id) {
              final mode = MapEntityNpcMovementMode.values.firstWhere(
                (e) => e.name == id,
              );
              setState(() => _npcMovementMode = mode);
            },
            tooltip: _l(
              'Comportement par défaut en overworld. Scripted only = aucun auto-move.',
              'Default overworld behavior. Scripted only = no automatic movement.',
            ),
          )
        : CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked =
                  await showCupertinoListPicker<MapEntityNpcMovementMode>(
                context: context,
                title: _l('Déplacement PNJ', 'NPC movement'),
                items: MapEntityNpcMovementMode.values,
                labelOf: _npcMovementModeLabel,
              );
              if (picked != null) {
                setState(() => _npcMovementMode = picked);
              }
            },
            child: Text(
              '${_l('Déplacement PNJ', 'NPC movement')}: ${_npcMovementModeLabel(_npcMovementMode)}',
            ),
          );

    final widgets = <Widget>[
      modePicker,
    ];

    final selectedEntityId = state.selectedEntityId?.trim();
    final placementEntityId = state.npcWaypointPlacementEntityId?.trim();
    final placementActiveForSelection = selectedEntityId != null &&
        selectedEntityId.isNotEmpty &&
        placementEntityId == selectedEntityId;
    if (_npcMovementMode == MapEntityNpcMovementMode.patrol ||
        placementActiveForSelection) {
      widgets.addAll([
        const SizedBox(height: 8),
        if (placementActiveForSelection)
          InspectorEmbeddedFootnote(
            text: _l(
              'Mode placement actif : cliquez sur la map pour ajouter un waypoint.',
              'Placement mode is active: click the map to add a waypoint.',
            ),
            accent: EditorChrome.inspectorJoyMint,
          ),
        const SizedBox(height: 6),
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () {
            if (placementActiveForSelection) {
              notifier.cancelNpcWaypointPlacement();
              return;
            }
            notifier.startNpcWaypointPlacementForSelectedEntity();
          },
          child: Text(
            placementActiveForSelection
                ? _l('Quitter mode placement', 'Exit placement mode')
                : _l('Placer waypoint sur la map', 'Place waypoint on map'),
          ),
        ),
      ]);
    }

    if (_npcMovementMode != MapEntityNpcMovementMode.patrol) {
      return widgets;
    }

    widgets.addAll([
      const SizedBox(height: 8),
      _toggleField(
        context,
        label: _l('Patrouille en boucle', 'Patrol loop'),
        value: _npcMovementLoop,
        onChanged: (v) => setState(() => _npcMovementLoop = v),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _labeledField(
              context,
              label: _l('Pause waypoint (ms)', 'Waypoint pause (ms)'),
              controller: _npcMovementPauseMs,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _labeledField(
              context,
              label: _l('Durée d’un pas (ms)', 'Step duration (ms)'),
              controller: _npcMovementStepMs,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        _l(
          'Waypoints (minimum 2 pour bouger)',
          'Waypoints (minimum 2 to move)',
        ),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
      const SizedBox(height: 6),
      if (_npcWaypointRows.isEmpty)
        Text(
          _l(
            'Aucun waypoint. Le PNJ restera immobile.',
            'No waypoints. NPC will stay still.',
          ),
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
    ]);

    for (var i = 0; i < _npcWaypointRows.length; i++) {
      final row = _npcWaypointRows[i];
      widgets.addAll([
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _labeledField(
                context,
                label: 'X',
                controller: row.xController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _labeledField(
                context,
                label: 'Y',
                controller: row.yController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            CupertinoButton(
              padding: const EdgeInsets.all(0),
              minimumSize: const Size(28, 28),
              onPressed: () {
                setState(() {
                  final removed = _npcWaypointRows.removeAt(i);
                  removed.dispose();
                });
              },
              child: const Icon(
                CupertinoIcons.minus_circle,
                size: 18,
              ),
            ),
          ],
        ),
      ]);
    }

    widgets.addAll([
      const SizedBox(height: 8),
      CupertinoButton(
        padding: EdgeInsets.zero,
        alignment: Alignment.centerLeft,
        onPressed: _addNpcWaypointRow,
        child: Text(_l('+ Ajouter waypoint', '+ Add waypoint')),
      ),
    ]);
    return widgets;
  }

  Future<({DialogueRef? ref, bool invalid})> _parseDialogueRef(
    BuildContext context,
    TextEditingController idC,
    TextEditingController pathC,
    TextEditingController nodeC,
  ) async {
    final id = idC.text.trim();
    if (id.isEmpty) {
      return (ref: null, invalid: false);
    }
    final path = pathC.text.trim();
    if (path.isNotEmpty) {
      if (path.startsWith('/') ||
          path.startsWith(r'\') ||
          path.contains('..')) {
        await showCupertinoEditorAlert(
          context,
          message: _l(
            'Chemin de script invalide (relatif au projet, sans ..).',
            'Invalid script path (project-relative, no ..).',
          ),
        );
        return (ref: null, invalid: true);
      }
    }
    final node = nodeC.text.trim();
    if (!isValidDialogueStartNode(node.isEmpty ? null : node)) {
      await showCupertinoEditorAlert(
        context,
        message: _l(
          'Nœud Yarn invalide (lettres, chiffres, espaces, - ou . ; max 256).',
          'Invalid Yarn node (letters, digits, spaces, - or .; max 256 chars).',
        ),
      );
      return (ref: null, invalid: true);
    }
    return (
      ref: DialogueRef(
        dialogueId: id,
        scriptPathRelative: path,
        startNode: node.isEmpty ? null : node,
      ),
      invalid: false,
    );
  }

  Future<({DialogueRef? ref, bool invalid})> _dialogueRefFromManifestBinding(
    BuildContext context,
    TextEditingController idC,
    TextEditingController nodeC,
  ) async {
    final id = idC.text.trim();
    if (id.isEmpty) {
      return (ref: null, invalid: false);
    }
    final node = nodeC.text.trim();
    if (!isValidDialogueStartNode(node.isEmpty ? null : node)) {
      await showCupertinoEditorAlert(
        context,
        message: _l(
          'Nœud Yarn invalide (lettres, chiffres, espaces, - ou . ; max 256).',
          'Invalid Yarn node (letters, digits, spaces, - or .; max 256 chars).',
        ),
      );
      return (ref: null, invalid: true);
    }
    return (
      ref: DialogueRef(
        dialogueId: id,
        scriptPathRelative: '',
        startNode: node.isEmpty ? null : node,
      ),
      invalid: false,
    );
  }

  List<ProjectDialogueEntry> _sortedDialogueEntries(
    List<ProjectDialogueEntry> entries,
  ) {
    final sorted = List<ProjectDialogueEntry>.of(entries);
    sorted.sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) {
        return byName;
      }
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  List<String> _dialogueDropdownIds(
    List<ProjectDialogueEntry> sorted,
    String currentId,
  ) {
    final ids = <String>[
      _kDialogueNoneMenuId,
      ...sorted.map((e) => e.id),
    ];
    final c = currentId.trim();
    if (c.isNotEmpty && !ids.contains(c)) {
      ids.add(c);
    }
    return ids;
  }

  String _dialogueDropdownValueLabel(
    List<ProjectDialogueEntry> sorted,
    String menuId,
  ) {
    if (menuId == _kDialogueNoneMenuId) {
      return _l('Aucun dialogue', 'No dialogue');
    }
    for (final e in sorted) {
      if (e.id == menuId) {
        return e.name;
      }
    }
    return '$menuId (${_l('absent du projet', 'missing from project')})';
  }

  String _npcDialogueSelectedMenuId() {
    if (_npcDialogueSource == _DialogueRefSource.none) {
      return _kDialogueNoneMenuId;
    }
    if (_npcDialogueSource == _DialogueRefSource.legacy) {
      return _kDialogueNoneMenuId;
    }
    final id = _npcDialogueId.text.trim();
    return id.isEmpty ? _kDialogueNoneMenuId : id;
  }

  String _signDialogueSelectedMenuId() {
    if (_signDialogueSource == _DialogueRefSource.none) {
      return _kDialogueNoneMenuId;
    }
    if (_signDialogueSource == _DialogueRefSource.legacy) {
      return _kDialogueNoneMenuId;
    }
    final id = _signDialogueId.text.trim();
    return id.isEmpty ? _kDialogueNoneMenuId : id;
  }

  String _npcDefeatDialogueSelectedMenuId() {
    if (_npcDefeatDialogueSource == _DialogueRefSource.none) {
      return _kDialogueNoneMenuId;
    }
    if (_npcDefeatDialogueSource == _DialogueRefSource.legacy) {
      return _kDialogueNoneMenuId;
    }
    final id = _npcDefeatDialogueId.text.trim();
    return id.isEmpty ? _kDialogueNoneMenuId : id;
  }

  void _onDefeatDialogueMenuSelected(String menuId) {
    setState(() {
      if (menuId == _kDialogueNoneMenuId) {
        _npcDefeatDialogueSource = _DialogueRefSource.none;
        _npcDefeatDialogueId.text = '';
        _npcDefeatDialogueNodes = [];
      } else {
        _npcDefeatDialogueSource = _DialogueRefSource.manifest;
        _npcDefeatDialogueId.text = menuId;
        _npcDefeatDialogueNodes = [];
      }
      _npcDefeatStartNode.text = '';
    });
    Future.microtask(_reloadYarnNodes);
  }

  String? _resolveDialogueFilePath(
    String dialogueId,
    ProjectManifest manifest,
    String projectRoot,
  ) {
    if (dialogueId.isEmpty) return null;
    final matches = manifest.dialogues.where((e) => e.id == dialogueId);
    if (matches.isEmpty) return null;
    final rel = matches.first.relativePath.trim().replaceAll(r'\', '/');
    if (rel.isEmpty) return null;
    return '$projectRoot/$rel';
  }

  Future<void> _reloadYarnNodes() async {
    final state = ref.read(editorNotifierProvider);
    final root = state.projectRootPath;
    final manifest = state.project;
    if (root == null || manifest == null) {
      if (mounted) {
        setState(() {
          _npcDialogueNodes = [];
          _signDialogueNodes = [];
          _npcDefeatDialogueNodes = [];
        });
      }
      return;
    }

    final npcPath = _resolveDialogueFilePath(
      _npcDialogueId.text.trim(),
      manifest,
      root,
    );
    final signPath = _resolveDialogueFilePath(
      _signDialogueId.text.trim(),
      manifest,
      root,
    );
    final defeatPath = _resolveDialogueFilePath(
      _npcDefeatDialogueId.text.trim(),
      manifest,
      root,
    );

    final results = await Future.wait([
      npcPath != null
          ? _extractYarnNodeTitles(npcPath)
          : Future.value(<String>[]),
      signPath != null
          ? _extractYarnNodeTitles(signPath)
          : Future.value(<String>[]),
      defeatPath != null
          ? _extractYarnNodeTitles(defeatPath)
          : Future.value(<String>[]),
    ]);

    if (!mounted) return;
    setState(() {
      _npcDialogueNodes = results[0];
      _signDialogueNodes = results[1];
      _npcDefeatDialogueNodes = results[2];
    });
  }

  void _onDialogueMenuSelected({
    required bool forNpc,
    required String menuId,
  }) {
    setState(() {
      if (forNpc) {
        if (menuId == _kDialogueNoneMenuId) {
          _npcDialogueSource = _DialogueRefSource.none;
          _npcDialogueId.text = '';
          _npcScriptPath.text = '';
          _npcDialogueNodes = [];
        } else {
          _npcDialogueSource = _DialogueRefSource.manifest;
          _npcDialogueId.text = menuId;
          _npcScriptPath.text = '';
          _npcDialogueNodes = [];
        }
        _npcStartNode.text = '';
      } else {
        if (menuId == _kDialogueNoneMenuId) {
          _signDialogueSource = _DialogueRefSource.none;
          _signDialogueId.text = '';
          _signScriptPath.text = '';
          _signDialogueNodes = [];
        } else {
          _signDialogueSource = _DialogueRefSource.manifest;
          _signDialogueId.text = menuId;
          _signScriptPath.text = '';
          _signDialogueNodes = [];
        }
        _signStartNode.text = '';
      }
    });
    Future.microtask(_reloadYarnNodes);
  }

  Widget _yarnNodeField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required List<String> nodes,
    required Color accent,
  }) {
    if (nodes.isEmpty) {
      return _labeledField(context, label: label, controller: controller);
    }
    final currentVal = controller.text.trim();
    final selected = nodes.contains(currentVal) ? currentVal : _kNodeNoneMenuId;
    final menuIds = [_kNodeNoneMenuId, ...nodes];
    return InspectorEmbeddedDropdown(
      accent: accent,
      fieldLabel: label,
      valueLabel: selected == _kNodeNoneMenuId
          ? _l('Nœud par défaut', 'Default node')
          : selected,
      orderedIds: menuIds,
      selectedMenuValue: selected,
      selectedIdForCheck: selected,
      idToLabel: (id) =>
          id == _kNodeNoneMenuId ? _l('Nœud par défaut', 'Default node') : id,
      onSelected: (id) {
        setState(() {
          controller.text = id == _kNodeNoneMenuId ? '' : id;
        });
      },
      tooltip: _l(
        'Nœuds Yarn disponibles dans ce script',
        'Yarn nodes available in this script',
      ),
    );
  }

  List<Widget> _npcCharacterFields(
    BuildContext context,
    ProjectManifest? project,
  ) {
    const charAccent = EditorChrome.inspectorJoyCyan;
    final characters = project?.characters ?? const <ProjectCharacterEntry>[];
    final menuIds = [_kCharacterNoneMenuId, ...characters.map((c) => c.id)];
    String labelOf(String id) {
      if (id == _kCharacterNoneMenuId) return _l('Aucun', 'None');
      for (final c in characters) {
        if (c.id == id) return c.name;
      }
      return id;
    }

    final selected = menuIds.contains(_npcCharacterMenuId)
        ? _npcCharacterMenuId
        : _kCharacterNoneMenuId;

    return [
      InspectorEmbeddedSectionLabel(
          _l('PERSONNAGE OVERWORLD', 'OVERWORLD CHARACTER')),
      const SizedBox(height: 6),
      if (widget.embedded)
        InspectorEmbeddedDropdown(
          accent: charAccent,
          fieldLabel: _l('Personnage', 'Character'),
          valueLabel: labelOf(selected),
          orderedIds: menuIds,
          selectedMenuValue: selected,
          selectedIdForCheck: selected,
          idToLabel: labelOf,
          onSelected: (id) => setState(() => _npcCharacterMenuId = id),
          tooltip: _l(
            'Sprite de personnage utilisé pour ce PNJ sur l\'overworld',
            'Character sprite used for this NPC on the overworld',
          ),
        )
      else ...[
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () async {
            final picked = await showCupertinoListPicker<String>(
              context: context,
              title: _l('Personnage', 'Character'),
              items: menuIds,
              labelOf: labelOf,
            );
            if (picked != null && context.mounted) {
              setState(() => _npcCharacterMenuId = picked);
            }
          },
          child: Text(
            '${_l('Personnage', 'Character')}: ${labelOf(selected)}',
          ),
        ),
      ],
    ];
  }

  bool _npcUsesTrainerAppearance() {
    final trainerId = _npcTrainerMenuId.trim();
    return trainerId.isNotEmpty && trainerId != _kTrainerNoneMenuId;
  }

  void _setNpcTrainerSelection(String id) {
    setState(() {
      _npcTrainerMenuId = id;
      if (_npcUsesTrainerAppearance()) {
        _npcCharacterMenuId = _kCharacterNoneMenuId;
        _editorVisualMenuId = _kElementNoneMenuId;
      }
    });
  }

  List<Widget> _npcDialogueFields(
    BuildContext context,
    ProjectManifest? project,
  ) {
    const scriptAccent = EditorChrome.inspectorJoyLilac;
    final dialogueEntries =
        project?.dialogues ?? const <ProjectDialogueEntry>[];
    final sorted = _sortedDialogueEntries(dialogueEntries);

    if (dialogueEntries.isEmpty) {
      return [
        InspectorEmbeddedFootnote(
          text: _l(
            'Créez ou importez des dialogues dans Dialogue Studio, puis sélectionnez-les ici — plus besoin de chemin relatif.',
            'Create or import dialogues in Dialogue Studio, then pick them here — no relative paths.',
          ),
          accent: scriptAccent,
        ),
        if (_npcDialogueSource == _DialogueRefSource.legacy &&
            _npcScriptPath.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          InspectorEmbeddedFootnote(
            text: _l(
              'Référence fichier héritée : ${_npcScriptPath.text.trim()}. Importez ce fichier dans Dialogue Studio pour le lier proprement.',
              'Legacy file reference: ${_npcScriptPath.text.trim()}. Import it in Dialogue Studio to bind it cleanly.',
            ),
            accent: scriptAccent,
          ),
        ],
        const SizedBox(height: 8),
        _labeledField(
          context,
          label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
          controller: _npcStartNode,
        ),
      ];
    }

    final menuIds = _dialogueDropdownIds(sorted, _npcDialogueId.text);
    final selectedMenu = _npcDialogueSelectedMenuId();

    return [
      if (widget.embedded)
        InspectorEmbeddedSectionLabel(
          _l('Dialogue (projet)', 'Project dialogue'),
        )
      else
        Text(
          _l('Dialogue (projet)', 'Project dialogue'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      const SizedBox(height: 6),
      if (_npcDialogueSource == _DialogueRefSource.legacy &&
          _npcScriptPath.text.trim().isNotEmpty) ...[
        InspectorEmbeddedFootnote(
          text: _l(
            'Ancienne référence par chemin : ${_npcScriptPath.text.trim()}\nChoisissez un dialogue dans la liste pour enregistrer la liaison au projet.',
            'Legacy path reference: ${_npcScriptPath.text.trim()}\nPick a dialogue from the list to save the project binding.',
          ),
          accent: scriptAccent,
        ),
        const SizedBox(height: 8),
      ],
      InspectorEmbeddedDropdown(
        accent: scriptAccent,
        fieldLabel: _l('Dialogue Yarn', 'Yarn dialogue'),
        valueLabel: _dialogueDropdownValueLabel(sorted, selectedMenu),
        orderedIds: menuIds,
        selectedMenuValue: selectedMenu,
        selectedIdForCheck: selectedMenu,
        idToLabel: (id) => _dialogueDropdownValueLabel(sorted, id),
        onSelected: (id) => _onDialogueMenuSelected(forNpc: true, menuId: id),
        tooltip: _l(
          'Scripts enregistrés dans le manifeste projet',
          'Scripts registered in the project manifest',
        ),
      ),
      const SizedBox(height: 8),
      _yarnNodeField(
        context,
        label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
        controller: _npcStartNode,
        nodes: _npcDialogueNodes,
        accent: scriptAccent,
      ),
    ];
  }

  List<Widget> _npcTrainerBattleFields(
    BuildContext context,
    ProjectManifest? project,
  ) {
    const battleAccent = EditorChrome.accentCoral;
    final dialogueEntries =
        project?.dialogues ?? const <ProjectDialogueEntry>[];
    final sorted = _sortedDialogueEntries(dialogueEntries);
    final trainers = project?.trainers ?? const <ProjectTrainerEntry>[];

    // Trainer IDs: none sentinel + actual IDs
    final trainerMenuIds = [
      _kTrainerNoneMenuId,
      ...trainers.map((t) => t.id),
    ];
    String trainerMenuLabel(String id) {
      if (id == _kTrainerNoneMenuId) return _l('Aucun', 'None');
      final match = trainers.where((t) => t.id == id);
      if (match.isEmpty) return id;
      final t = match.first;
      return '${t.name} (${t.trainerClass})';
    }

    final selectedTrainer = trainerMenuIds.contains(_npcTrainerMenuId)
        ? _npcTrainerMenuId
        : _kTrainerNoneMenuId;

    return [
      InspectorEmbeddedSectionLabel(
        _l('COMBAT DE DRESSEUR', 'TRAINER BATTLE'),
      ),
      const SizedBox(height: 6),
      if (widget.embedded)
        InspectorEmbeddedDropdown(
          accent: battleAccent,
          fieldLabel: _l('Dresseur', 'Trainer'),
          valueLabel: trainerMenuLabel(selectedTrainer),
          orderedIds: trainerMenuIds,
          selectedMenuValue: selectedTrainer,
          selectedIdForCheck: selectedTrainer,
          idToLabel: trainerMenuLabel,
          onSelected: _setNpcTrainerSelection,
          tooltip: _l(
            'Lier à une fiche dresseur du projet. Vide = PNJ non combattant.',
            'Link to a project trainer entry. Empty = non-combat NPC.',
          ),
        )
      else ...[
        Text(
          _l('Dresseur', 'Trainer'),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () async {
            final picked = await showCupertinoListPicker<String>(
              context: context,
              title: _l('Dresseur', 'Trainer'),
              items: trainerMenuIds,
              labelOf: trainerMenuLabel,
            );
            if (picked != null && context.mounted) {
              _setNpcTrainerSelection(picked);
            }
          },
          child: Text(trainerMenuLabel(selectedTrainer)),
        ),
      ],
      const SizedBox(height: 6),
      _labeledField(
        context,
        label: _l('Portée détection (cases)', 'Line of sight (tiles)'),
        controller: _npcLineOfSight,
        keyboardType: TextInputType.number,
      ),
      if (selectedTrainer != _kTrainerNoneMenuId) ...[
        const SizedBox(height: 8),
        InspectorEmbeddedSectionLabel(
          _l('DIALOGUE APRÈS DÉFAITE', 'DEFEAT DIALOGUE'),
        ),
        const SizedBox(height: 4),
        if (dialogueEntries.isEmpty)
          InspectorEmbeddedFootnote(
            text: _l(
              'Ajoutez des dialogues dans Dialogue Studio pour en sélectionner un ici.',
              'Add dialogues in Dialogue Studio to pick one here.',
            ),
            accent: battleAccent,
          )
        else ...[
          InspectorEmbeddedDropdown(
            accent: battleAccent,
            fieldLabel: _l('Dialogue Yarn', 'Yarn dialogue'),
            valueLabel: _dialogueDropdownValueLabel(
              sorted,
              _npcDefeatDialogueSelectedMenuId(),
            ),
            orderedIds: _dialogueDropdownIds(
              sorted,
              _npcDefeatDialogueId.text,
            ),
            selectedMenuValue: _npcDefeatDialogueSelectedMenuId(),
            selectedIdForCheck: _npcDefeatDialogueSelectedMenuId(),
            idToLabel: (id) => _dialogueDropdownValueLabel(sorted, id),
            onSelected: _onDefeatDialogueMenuSelected,
            tooltip: _l(
              'Scripts enregistrés dans le manifeste projet',
              'Scripts registered in the project manifest',
            ),
          ),
          const SizedBox(height: 4),
          _yarnNodeField(
            context,
            label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
            controller: _npcDefeatStartNode,
            nodes: _npcDefeatDialogueNodes,
            accent: battleAccent,
          ),
        ],
      ],
    ];
  }

  List<Widget> _signDialogueFields(
    BuildContext context,
    ProjectManifest? project,
  ) {
    const scriptAccent = EditorChrome.inspectorJoyLilac;
    final dialogueEntries =
        project?.dialogues ?? const <ProjectDialogueEntry>[];
    final sorted = _sortedDialogueEntries(dialogueEntries);

    if (dialogueEntries.isEmpty) {
      return [
        InspectorEmbeddedFootnote(
          text: _l(
            'Créez ou importez des dialogues dans Dialogue Studio, puis sélectionnez-les ici.',
            'Create or import dialogues in Dialogue Studio, then pick them here.',
          ),
          accent: scriptAccent,
        ),
        if (_signDialogueSource == _DialogueRefSource.legacy &&
            _signScriptPath.text.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          InspectorEmbeddedFootnote(
            text: _l(
              'Référence fichier héritée : ${_signScriptPath.text.trim()}. Importez ce fichier dans Dialogue Studio.',
              'Legacy file reference: ${_signScriptPath.text.trim()}. Import it in Dialogue Studio.',
            ),
            accent: scriptAccent,
          ),
        ],
        const SizedBox(height: 8),
        _yarnNodeField(
          context,
          label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
          controller: _signStartNode,
          nodes: _signDialogueNodes,
          accent: scriptAccent,
        ),
      ];
    }

    final menuIds = _dialogueDropdownIds(sorted, _signDialogueId.text);
    final selectedMenu = _signDialogueSelectedMenuId();

    return [
      if (widget.embedded)
        InspectorEmbeddedSectionLabel(
          _l('Dialogue (projet)', 'Project dialogue'),
        )
      else
        Text(
          _l('Dialogue (projet)', 'Project dialogue'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      const SizedBox(height: 6),
      if (_signDialogueSource == _DialogueRefSource.legacy &&
          _signScriptPath.text.trim().isNotEmpty) ...[
        InspectorEmbeddedFootnote(
          text: _l(
            'Ancienne référence par chemin : ${_signScriptPath.text.trim()}\nChoisissez un script dans la liste pour migrer.',
            'Legacy path reference: ${_signScriptPath.text.trim()}\nPick a script from the list to migrate.',
          ),
          accent: scriptAccent,
        ),
        const SizedBox(height: 8),
      ],
      InspectorEmbeddedDropdown(
        accent: scriptAccent,
        fieldLabel: _l('Dialogue Yarn', 'Yarn dialogue'),
        valueLabel: _dialogueDropdownValueLabel(sorted, selectedMenu),
        orderedIds: menuIds,
        selectedMenuValue: selectedMenu,
        selectedIdForCheck: selectedMenu,
        idToLabel: (id) => _dialogueDropdownValueLabel(sorted, id),
        onSelected: (id) => _onDialogueMenuSelected(forNpc: false, menuId: id),
        tooltip: _l(
          'Scripts enregistrés dans le manifeste projet',
          'Scripts registered in the project manifest',
        ),
      ),
      const SizedBox(height: 8),
      _yarnNodeField(
        context,
        label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
        controller: _signStartNode,
        nodes: _signDialogueNodes,
        accent: scriptAccent,
      ),
    ];
  }

  List<ProjectElementEntry> _sortedProjectElements(
    List<ProjectElementEntry> raw,
  ) {
    final list = List<ProjectElementEntry>.of(raw);
    list.sort((a, b) {
      final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (byName != 0) {
        return byName;
      }
      return a.id.compareTo(b.id);
    });
    return list;
  }

  List<String> _elementVisualMenuIds(
    List<ProjectElementEntry> sorted,
    String currentId,
  ) {
    final ids = <String>[
      _kElementNoneMenuId,
      ...sorted.map((e) => e.id),
    ];
    final c = currentId.trim();
    if (c.isNotEmpty && c != _kElementNoneMenuId && !ids.contains(c)) {
      ids.add(c);
    }
    return ids;
  }

  String _elementVisualMenuLabel(
    List<ProjectElementEntry> sorted,
    String menuId,
  ) {
    if (menuId == _kElementNoneMenuId) {
      return _l('Aucun visuel', 'No visual');
    }
    for (final e in sorted) {
      if (e.id == menuId) {
        return e.name;
      }
    }
    return '$menuId (${_l('absent', 'missing')})';
  }

  String _editorVisualSelectedMenuId() {
    final m = _editorVisualMenuId.trim();
    if (m.isEmpty || m == _kElementNoneMenuId) {
      return _kElementNoneMenuId;
    }
    return m;
  }

  List<Widget> _editorVisualFields(
    BuildContext context,
    ProjectManifest? project,
  ) {
    const accent = EditorChrome.inspectorJoyCyan;
    final elements = project?.elements ?? const <ProjectElementEntry>[];
    final sorted = _sortedProjectElements(elements);

    if (widget.embedded) {
      return [
        InspectorEmbeddedSectionLabel(
          _l(
            'Référence visuelle (bibliothèque)',
            'Visual reference (library)',
          ),
        ),
        const SizedBox(height: 6),
        if (sorted.isEmpty)
          InspectorEmbeddedFootnote(
            text: _l(
              'Les visuels réutilisables sont des ProjectElementEntry (une ou plusieurs frames). Créez-les dans l’explorateur, puis liez-les ici pour tout type d’entité.',
              'Reusable visuals are ProjectElementEntry values (one or more frames). Create them in the explorer, then bind them here for any entity kind.',
            ),
            accent: accent,
          )
        else ...[
          InspectorEmbeddedDropdown(
            accent: accent,
            fieldLabel: _l('Élément projet', 'Project element'),
            valueLabel: _elementVisualMenuLabel(
              sorted,
              _editorVisualSelectedMenuId(),
            ),
            orderedIds: _elementVisualMenuIds(sorted, _editorVisualMenuId),
            selectedMenuValue: _editorVisualSelectedMenuId(),
            selectedIdForCheck: _editorVisualSelectedMenuId(),
            idToLabel: (id) => _elementVisualMenuLabel(sorted, id),
            onSelected: (id) => setState(() => _editorVisualMenuId = id),
            tooltip: _l(
              'Même bibliothèque pour PNJ, panneaux, objets, etc. Sur la carte, le canvas alterne les frames de l’élément (durées par frame ou valeur par défaut) ; pas de données d’animation dupliquées sur l’entité.',
              'Same library for NPCs, signs, items, etc. The editor shows the first frame only; animation lives on the element’s frames.',
            ),
          ),
        ],
      ];
    }
    return [
      Text(
        _l(
          'Référence visuelle (bibliothèque)',
          'Visual reference (library)',
        ),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
      const SizedBox(height: 6),
      if (sorted.isEmpty)
        Text(
          _l(
            'Ajoutez des ProjectElementEntry dans l’explorateur (éléments du projet).',
            'Add ProjectElementEntry items in the explorer.',
          ),
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        )
      else
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () async {
            final ids = _elementVisualMenuIds(sorted, _editorVisualMenuId);
            final picked = await showCupertinoListPicker<String>(
              context: context,
              title: _l('Élément projet', 'Project element'),
              items: ids,
              labelOf: (id) => _elementVisualMenuLabel(sorted, id),
            );
            if (picked != null && context.mounted) {
              setState(() => _editorVisualMenuId = picked);
            }
          },
          child: Text(
            _elementVisualMenuLabel(sorted, _editorVisualSelectedMenuId()),
          ),
        ),
    ];
  }

  Widget _kindSpecificFields(
    BuildContext context,
    ProjectManifest? project,
    EditorState state,
    EditorNotifier notifier,
  ) {
    switch (_selectedKind) {
      case MapEntityKind.npc:
        final usesTrainerAppearance = _npcUsesTrainerAppearance();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded)
              InspectorEmbeddedSectionLabel(_l('PNJ', 'NPC'))
            else
              Text(
                _l('PNJ', 'NPC'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            const SizedBox(height: 6),
            Text(
              _l(
                'Le nom sert aussi de libellé dans les listes.',
                'Also used as the list label.',
              ),
              style: TextStyle(
                fontSize: 11,
                height: 1.25,
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            ..._npcDialogueFields(context, project),
            const SizedBox(height: 8),
            if (widget.embedded)
              InspectorEmbeddedDropdown(
                accent: EditorChrome.inspectorJoyCyan,
                fieldLabel: _l('Orientation', 'Facing'),
                valueLabel: _facingLabel(_npcFacing),
                orderedIds: EntityFacing.values
                    .map((f) => f.name)
                    .toList(growable: false),
                selectedMenuValue: _npcFacing.name,
                selectedIdForCheck: _npcFacing.name,
                idToLabel: (id) => _facingLabel(
                  EntityFacing.values.firstWhere((f) => f.name == id),
                ),
                onSelected: (id) {
                  final f = EntityFacing.values.firstWhere((e) => e.name == id);
                  setState(() => _npcFacing = f);
                },
                tooltip: _l('Direction du PNJ', 'NPC facing'),
              )
            else
              CupertinoButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: () async {
                  final picked = await showCupertinoListPicker<EntityFacing>(
                    context: context,
                    title: _l('Orientation', 'Facing'),
                    items: EntityFacing.values,
                    labelOf: _facingLabel,
                  );
                  if (picked != null) {
                    setState(() => _npcFacing = picked);
                  }
                },
                child: Text(
                  '${_l('Orientation', 'Facing')}: ${_facingLabel(_npcFacing)}',
                ),
              ),
            const SizedBox(height: 8),
            ..._npcMovementFields(context, state, notifier),
            const SizedBox(height: 8),
            ..._npcTrainerBattleFields(context, project),
            if (usesTrainerAppearance) ...[
              const SizedBox(height: 8),
              InspectorEmbeddedFootnote(
                text: _l(
                  'L’apparence overworld vient du Character du dresseur lié. Les champs visuels locaux du PNJ sont désactivés.',
                  'Overworld appearance comes from the linked trainer Character. Local NPC visual fields are disabled.',
                ),
                accent: EditorChrome.inspectorJoyCoral,
              ),
            ] else ...[
              const SizedBox(height: 8),
              ..._npcCharacterFields(context, project),
            ],
          ],
        );
      case MapEntityKind.sign:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.embedded)
              InspectorEmbeddedSectionLabel(_l('Panneau', 'Sign'))
            else
              Text(
                _l('Panneau', 'Sign'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Titre (optionnel)', 'Title (optional)'),
              controller: _signTitle,
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Texte simple', 'Plain text'),
              controller: _signPlainText,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            if (widget.embedded)
              InspectorEmbeddedSectionLabel(
                _l('Dialogue scripté (optionnel)',
                    'Scripted dialogue (optional)'),
              )
            else
              Text(
                _l('Dialogue scripté (optionnel)',
                    'Scripted dialogue (optional)'),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            const SizedBox(height: 8),
            ..._signDialogueFields(context, project),
          ],
        );
      case MapEntityKind.item:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _l('Objet', 'Item'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('ID objet jeu', 'Game item ID'),
              controller: _itemGameId,
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Quantité', 'Quantity'),
              controller: _itemQuantity,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () async {
                final picked = await showCupertinoListPicker<ItemPickupMode>(
                  context: context,
                  title: _l('Mode de ramassage', 'Pickup mode'),
                  items: ItemPickupMode.values,
                  labelOf: _pickupLabel,
                );
                if (picked != null) {
                  setState(() => _itemPickup = picked);
                }
              },
              child: Text(
                '${_l('Ramassage', 'Pickup')}: ${_pickupLabel(_itemPickup)}',
              ),
            ),
            const SizedBox(height: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () async {
                final picked = await showCupertinoListPicker<ItemRespawnPolicy>(
                  context: context,
                  title: _l('Réapparition', 'Respawn'),
                  items: ItemRespawnPolicy.values,
                  labelOf: _respawnLabel,
                );
                if (picked != null) {
                  setState(() => _itemRespawn = picked);
                }
              },
              child: Text(
                '${_l('Réapparition', 'Respawn policy')}: ${_respawnLabel(_itemRespawn)}',
              ),
            ),
          ],
        );
      case MapEntityKind.spawn:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _l('Point de spawn', 'Spawn'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Clé / identifiant', 'Spawn key'),
              controller: _spawnKey,
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Catégorie (optionnel)', 'Category (optional)'),
              controller: _spawnCategory,
            ),
            const SizedBox(height: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () async {
                final picked = await showCupertinoListPicker<EntitySpawnRole>(
                  context: context,
                  title: _l('Rôle', 'Role'),
                  items: EntitySpawnRole.values,
                  labelOf: _spawnRoleLabel,
                );
                if (picked != null) {
                  setState(() => _spawnRole = picked);
                }
              },
              child: Text(
                '${_l('Rôle', 'Role')}: ${_spawnRoleLabel(_spawnRole)}',
              ),
            ),
            const SizedBox(height: 4),
            CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () async {
                final picked = await showCupertinoListPicker<EntityFacing>(
                  context: context,
                  title: _l('Orientation', 'Facing'),
                  items: EntityFacing.values,
                  labelOf: _facingLabel,
                );
                if (picked != null) {
                  setState(() => _spawnFacing = picked);
                }
              },
              child: Text(
                '${_l('Orientation', 'Facing')}: ${_facingLabel(_spawnFacing)}',
              ),
            ),
          ],
        );
      case MapEntityKind.custom:
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            _l(
              'Type personnalisé : utilisez les propriétés libres ci-dessous.',
              'Custom type: use free-form properties below.',
            ),
            style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.placeholderText.resolveFrom(context),
              height: 1.25,
            ),
          ),
        );
    }
  }

  Widget _buildSelectedEntityEditor({
    required BuildContext context,
    required EditorState state,
    required EditorNotifier notifier,
    required ProjectManifest? project,
    required MapEntity selectedEntity,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded)
          InspectorEmbeddedSectionLabel(
            _l('Entité sélectionnée', 'Selected entity'),
          )
        else
          Text(
            _l('Entité sélectionnée', 'Selected entity'),
            style: TextStyle(
              fontSize: 12,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          '${_l('Position', 'Position')}: (${selectedEntity.pos.x}, ${selectedEntity.pos.y}) | ${_l('Taille', 'Size')}: ${selectedEntity.size.width}x${selectedEntity.size.height}',
          style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.secondaryLabel.resolveFrom(context)),
        ),
        const SizedBox(height: 8),
        _labeledField(
          context,
          label: _l('ID technique', 'ID'),
          controller: _idController,
        ),
        const SizedBox(height: 8),
        _labeledField(
          context,
          label: _selectedKind == MapEntityKind.npc
              ? _l('Nom', 'Name')
              : _l('Nom (liste)', 'Name'),
          controller: _nameController,
        ),
        const SizedBox(height: 8),
        if (widget.embedded)
          InspectorEmbeddedDropdown(
            accent: EditorChrome.inspectorJoyCyan,
            fieldLabel: _l('Type d’entité', 'Entity kind'),
            valueLabel: _entityKindLabel(_selectedKind),
            orderedIds:
                MapEntityKind.values.map((k) => k.name).toList(growable: false),
            selectedMenuValue: _selectedKind.name,
            selectedIdForCheck: _selectedKind.name,
            idToLabel: (id) => _entityKindLabel(
              MapEntityKind.values.firstWhere((k) => k.name == id),
            ),
            onSelected: (id) {
              final k = MapEntityKind.values.firstWhere((e) => e.name == id);
              setState(() {
                _selectedKind = k;
                if (k == MapEntityKind.npc) {
                  final w = _widthController.text.trim();
                  final h = _heightController.text.trim();
                  if (w.isEmpty || w == '1') {
                    _widthController.text = '2';
                  }
                  if (h.isEmpty || h == '1') {
                    _heightController.text = '2';
                  }
                }
              });
            },
            tooltip: _l('Type d’entité sur la carte', 'Map entity kind'),
          )
        else
          CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked = await showCupertinoListPicker<MapEntityKind>(
                context: context,
                title: _l('Type d’entité', 'Kind'),
                items: MapEntityKind.values,
                labelOf: _entityKindLabel,
              );
              if (picked != null) {
                setState(() {
                  _selectedKind = picked;
                  if (picked == MapEntityKind.npc) {
                    final w = _widthController.text.trim();
                    final h = _heightController.text.trim();
                    if (w.isEmpty || w == '1') {
                      _widthController.text = '2';
                    }
                    if (h.isEmpty || h == '1') {
                      _heightController.text = '2';
                    }
                  }
                });
              }
            },
            child: Text(
              '${_l('Type', 'Kind')}: ${_entityKindLabel(_selectedKind)}',
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _labeledField(
                context,
                label: _l('X', 'X'),
                controller: _xController,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _labeledField(
                context,
                label: _l('Y', 'Y'),
                controller: _yController,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _labeledField(
                context,
                label: _l('Largeur', 'Width'),
                controller: _widthController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _labeledField(
                context,
                label: _l('Hauteur', 'Height'),
                controller: _heightController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        if (_selectedKind != MapEntityKind.spawn) ...[
          const SizedBox(height: 8),
          _toggleField(
            context,
            label: _l('Bloque le mouvement', 'Blocks movement'),
            value: _blocksMovement,
            onChanged: (v) => setState(() => _blocksMovement = v),
          ),
        ],
        if (_selectedKind != MapEntityKind.npc) ...[
          const SizedBox(height: 12),
          ..._editorVisualFields(context, project),
        ],
        const SizedBox(height: 12),
        _kindSpecificFields(context, project, state, notifier),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                _selectedKind == MapEntityKind.custom
                    ? _l('Propriétés', 'Properties')
                    : _l(
                        'Propriétés libres (extensions)',
                        'Custom properties (extensions)',
                      ),
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            EditorToolbarIconButton(
              onPressed: () {
                setState(() {
                  _propertyRows.add(_EntityPropertyDraft.empty());
                });
              },
              icon: CupertinoIcons.add,
              tooltip: _l('Ajouter', 'Add property'),
            ),
          ],
        ),
        if (_propertyRows.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _l('Aucune propriété libre.', 'No custom properties yet.'),
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
          )
        else
          ...List.generate(_propertyRows.length, (index) {
            final row = _propertyRows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _labeledField(
                      context,
                      label: _l('Clé', 'Key'),
                      controller: row.keyController,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _labeledField(
                      context,
                      label: _l('Valeur', 'Value'),
                      controller: row.valueController,
                    ),
                  ),
                  EditorToolbarIconButton(
                    onPressed: () {
                      setState(() {
                        final removed = _propertyRows.removeAt(index);
                        removed.dispose();
                      });
                    },
                    icon: CupertinoIcons.trash,
                    tooltip: _l('Supprimer', 'Remove'),
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CupertinoButton.filled(
                onPressed: () => _saveSelectedEntity(context, notifier),
                child: Text(_l('Enregistrer', 'Save entity')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CupertinoButton(
                onPressed: notifier.deleteSelectedEntity,
                child: Text(_l('Supprimer', 'Delete')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _syncControllers(MapEntity? entity, ProjectManifest? project) {
    final fingerprint = _entityFingerprint(entity);
    if (_boundFingerprint == fingerprint) {
      return;
    }
    _boundFingerprint = fingerprint;
    Future.microtask(_reloadYarnNodes);

    final dialogueEntries =
        project?.dialogues ?? const <ProjectDialogueEntry>[];

    _idController.text = entity?.id ?? '';
    if (entity != null && entity.kind == MapEntityKind.npc) {
      final dn = entity.npc?.displayName.trim() ?? '';
      _nameController.text = dn.isNotEmpty
          ? dn
          : (entity.name.trim().isNotEmpty ? entity.name : entity.id);
    } else {
      _nameController.text = entity?.name ?? '';
    }
    _xController.text = entity?.pos.x.toString() ?? '';
    _yController.text = entity?.pos.y.toString() ?? '';
    _widthController.text = entity?.size.width.toString() ?? '';
    _heightController.text = entity?.size.height.toString() ?? '';
    _selectedKind = entity?.kind ?? MapEntityKind.npc;
    _blocksMovement = entity?.blocksMovement ?? true;

    final n = entity?.npc ?? const MapEntityNpcData();
    final nd = n.dialogue;
    if (nd == null) {
      _npcDialogueSource = _DialogueRefSource.none;
      _npcDialogueId.text = '';
      _npcScriptPath.text = '';
    } else if (nd.scriptPathRelative.trim().isNotEmpty) {
      final matched =
          _dialogueEntryForLegacyPath(dialogueEntries, nd.scriptPathRelative);
      if (matched != null) {
        _npcDialogueSource = _DialogueRefSource.manifest;
        _npcDialogueId.text = matched.id;
        _npcScriptPath.text = '';
      } else {
        _npcDialogueSource = _DialogueRefSource.legacy;
        _npcDialogueId.text = nd.dialogueId;
        _npcScriptPath.text = nd.scriptPathRelative;
      }
    } else {
      _npcDialogueSource = _DialogueRefSource.manifest;
      _npcDialogueId.text = nd.dialogueId;
      _npcScriptPath.text = '';
    }
    _npcStartNode.text = n.dialogue?.startNode ?? '';
    _npcFacing = n.facing;
    final cid = n.characterId?.trim();
    _npcCharacterMenuId =
        (cid == null || cid.isEmpty) ? _kCharacterNoneMenuId : cid;
    final tid = n.trainerId?.trim();
    _npcTrainerMenuId =
        (tid == null || tid.isEmpty) ? _kTrainerNoneMenuId : tid;
    _npcLineOfSight.text = n.lineOfSightRange.toString();
    final movement = n.movement;
    _npcMovementMode = movement.mode;
    _npcMovementLoop = movement.loop;
    _npcMovementPauseMs.text = movement.pauseDurationMs.toString();
    _npcMovementStepMs.text = movement.stepDurationMs.toString();
    for (final row in _npcWaypointRows) {
      row.dispose();
    }
    _npcWaypointRows
      ..clear()
      ..addAll(
        movement.waypoints
            .map(
              (waypoint) => _NpcWaypointDraft(
                xController: TextEditingController(text: waypoint.x.toString()),
                yController: TextEditingController(text: waypoint.y.toString()),
              ),
            )
            .toList(growable: false),
      );
    final dd = n.defeatDialogueRef;
    if (dd == null) {
      _npcDefeatDialogueSource = _DialogueRefSource.none;
      _npcDefeatDialogueId.text = '';
      _npcDefeatStartNode.text = '';
    } else if (dd.scriptPathRelative.trim().isNotEmpty) {
      final matched =
          _dialogueEntryForLegacyPath(dialogueEntries, dd.scriptPathRelative);
      if (matched != null) {
        _npcDefeatDialogueSource = _DialogueRefSource.manifest;
        _npcDefeatDialogueId.text = matched.id;
      } else {
        _npcDefeatDialogueSource = _DialogueRefSource.legacy;
        _npcDefeatDialogueId.text = dd.dialogueId;
      }
      _npcDefeatStartNode.text = dd.startNode ?? '';
    } else {
      _npcDefeatDialogueSource = _DialogueRefSource.manifest;
      _npcDefeatDialogueId.text = dd.dialogueId;
      _npcDefeatStartNode.text = dd.startNode ?? '';
    }

    final resolvedEv = entity?.resolvedProjectElementIdForEditor;
    _editorVisualMenuId = (resolvedEv == null || resolvedEv.isEmpty)
        ? _kElementNoneMenuId
        : resolvedEv;
    if (_npcUsesTrainerAppearance()) {
      _npcCharacterMenuId = _kCharacterNoneMenuId;
      _editorVisualMenuId = _kElementNoneMenuId;
    }

    final s = entity?.sign ?? const MapEntitySignData();
    _signTitle.text = s.title;
    _signPlainText.text = s.plainText;
    final sd = s.dialogue;
    if (sd == null) {
      _signDialogueSource = _DialogueRefSource.none;
      _signDialogueId.text = '';
      _signScriptPath.text = '';
    } else if (sd.scriptPathRelative.trim().isNotEmpty) {
      final matched =
          _dialogueEntryForLegacyPath(dialogueEntries, sd.scriptPathRelative);
      if (matched != null) {
        _signDialogueSource = _DialogueRefSource.manifest;
        _signDialogueId.text = matched.id;
        _signScriptPath.text = '';
      } else {
        _signDialogueSource = _DialogueRefSource.legacy;
        _signDialogueId.text = sd.dialogueId;
        _signScriptPath.text = sd.scriptPathRelative;
      }
    } else {
      _signDialogueSource = _DialogueRefSource.manifest;
      _signDialogueId.text = sd.dialogueId;
      _signScriptPath.text = '';
    }
    _signStartNode.text = s.dialogue?.startNode ?? '';

    final it = entity?.item ?? const MapEntityItemData();
    _itemGameId.text = it.gameItemId;
    _itemQuantity.text = it.quantity.toString();
    _itemPickup = it.pickupMode;
    _itemRespawn = it.respawnPolicy;

    final sp = entity?.spawn ?? const MapEntitySpawnData();
    _spawnKey.text = sp.spawnKey;
    _spawnCategory.text = sp.categoryTag;
    _spawnRole = sp.role;
    _spawnFacing = sp.facing;

    for (final row in _propertyRows) {
      row.dispose();
    }
    _propertyRows
      ..clear()
      ..addAll(
        entity?.properties.entries
                .map(
                  (entry) => _EntityPropertyDraft(
                    keyController: TextEditingController(text: entry.key),
                    valueController: TextEditingController(text: entry.value),
                  ),
                )
                .toList(growable: false) ??
            const [],
      );
  }

  String? _entityFingerprint(MapEntity? entity) {
    if (entity == null) {
      return 'none';
    }
    String enc(Object? o) {
      if (o == null) {
        return '∅';
      }
      try {
        return jsonEncode(o);
      } catch (_) {
        return o.toString();
      }
    }

    return [
      entity.id,
      entity.name,
      entity.kind.name,
      '${entity.pos.x},${entity.pos.y}',
      '${entity.size.width}x${entity.size.height}',
      enc(entity.properties),
      entity.blocksMovement.toString(),
      enc(entity.npc?.toJson()),
      enc(entity.sign?.toJson()),
      enc(entity.item?.toJson()),
      enc(entity.spawn?.toJson()),
      enc(entity.editorVisual?.toJson()),
    ].join('|');
  }

  Future<void> _saveSelectedEntity(
    BuildContext context,
    EditorNotifier notifier,
  ) async {
    final x = int.tryParse(_xController.text.trim());
    final y = int.tryParse(_yController.text.trim());
    final width = int.tryParse(_widthController.text.trim());
    final height = int.tryParse(_heightController.text.trim());
    if (x == null || y == null || width == null || height == null) {
      await showCupertinoEditorAlert(
        context,
        message: _l(
          'Position et taille doivent être des entiers valides.',
          'Entity coordinates and size must be valid integers.',
        ),
      );
      return;
    }
    if (width <= 0 || height <= 0) {
      await showCupertinoEditorAlert(
        context,
        message: _l(
          'Largeur et hauteur doivent être > 0.',
          'Entity width and height must be greater than zero.',
        ),
      );
      return;
    }

    MapEntityNpcData? npcPayload;
    MapEntitySignData? signPayload;
    MapEntityItemData? itemPayload;
    MapEntitySpawnData? spawnPayload;

    final evMenu = _editorVisualMenuId.trim();
    MapEntityEditorVisual? editorVisualPayload =
        evMenu == _kElementNoneMenuId || evMenu.isEmpty
            ? null
            : MapEntityEditorVisual(elementId: evMenu);

    switch (_selectedKind) {
      case MapEntityKind.npc:
        editorVisualPayload = null;
        final DialogueRef? npcDlg;
        final npcFileOverride = _npcScriptPath.text.trim().isNotEmpty;
        if (npcFileOverride) {
          final r = await _parseDialogueRef(
            context,
            _npcDialogueId,
            _npcScriptPath,
            _npcStartNode,
          );
          if (r.invalid) {
            return;
          }
          npcDlg = r.ref;
        } else {
          final r = await _dialogueRefFromManifestBinding(
            context,
            _npcDialogueId,
            _npcStartNode,
          );
          if (r.invalid) {
            return;
          }
          npcDlg = r.ref;
        }
        final trainerIdRaw = _npcTrainerMenuId.trim();
        final trainerId =
            (trainerIdRaw.isEmpty || trainerIdRaw == _kTrainerNoneMenuId)
                ? null
                : trainerIdRaw;
        final losRange = int.tryParse(_npcLineOfSight.text.trim()) ?? 0;
        DialogueRef? defeatDlgRef;
        if (_npcDefeatDialogueSource != _DialogueRefSource.none &&
            _npcDefeatDialogueId.text.trim().isNotEmpty) {
          defeatDlgRef = DialogueRef(
            dialogueId: _npcDefeatDialogueId.text.trim(),
            startNode: _npcDefeatStartNode.text.trim().isEmpty
                ? null
                : _npcDefeatStartNode.text.trim(),
          );
        }
        final charIdRaw = _npcCharacterMenuId.trim();
        final usesTrainerAppearance =
            trainerId != null && trainerId.trim().isNotEmpty;
        final charId = usesTrainerAppearance ||
                charIdRaw.isEmpty ||
                charIdRaw == _kCharacterNoneMenuId
            ? null
            : charIdRaw;
        if (usesTrainerAppearance) {
          editorVisualPayload = null;
        }
        final pauseMs = int.tryParse(_npcMovementPauseMs.text.trim()) ?? 0;
        final stepMs = int.tryParse(_npcMovementStepMs.text.trim()) ?? 200;
        final waypoints = <GridPos>[];
        for (var i = 0; i < _npcWaypointRows.length; i++) {
          final row = _npcWaypointRows[i];
          final wx = int.tryParse(row.xController.text.trim());
          final wy = int.tryParse(row.yController.text.trim());
          if (wx == null || wy == null) {
            if (!context.mounted) {
              return;
            }
            await showCupertinoEditorAlert(
              context,
              message: _l(
                'Waypoint ${i + 1} invalide. X et Y doivent être des entiers.',
                'Invalid waypoint ${i + 1}. X and Y must be integers.',
              ),
            );
            return;
          }
          waypoints.add(GridPos(x: wx, y: wy));
        }
        npcPayload = MapEntityNpcData(
          displayName: _nameController.text.trim(),
          dialogue: npcDlg,
          facing: _npcFacing,
          visualElementId: '',
          trainerId: trainerId,
          lineOfSightRange: losRange.clamp(0, 999),
          defeatDialogueRef: defeatDlgRef,
          characterId: charId,
          movement: MapEntityNpcMovementConfig(
            mode: _npcMovementMode,
            waypoints: waypoints,
            loop: _npcMovementLoop,
            pauseDurationMs: pauseMs < 0 ? 0 : pauseMs,
            stepDurationMs: stepMs <= 0 ? 200 : stepMs,
          ),
        );
        break;
      case MapEntityKind.sign:
        final DialogueRef? signDlg;
        final signFileOverride = _signScriptPath.text.trim().isNotEmpty;
        if (signFileOverride) {
          final r = await _parseDialogueRef(
            context,
            _signDialogueId,
            _signScriptPath,
            _signStartNode,
          );
          if (r.invalid) {
            return;
          }
          signDlg = r.ref;
        } else {
          final r = await _dialogueRefFromManifestBinding(
            context,
            _signDialogueId,
            _signStartNode,
          );
          if (r.invalid) {
            return;
          }
          signDlg = r.ref;
        }
        signPayload = MapEntitySignData(
          title: _signTitle.text.trim(),
          dialogue: signDlg,
          plainText: _signPlainText.text.trim(),
        );
        break;
      case MapEntityKind.item:
        if (_itemGameId.text.trim().isEmpty) {
          await showCupertinoEditorAlert(
            context,
            message: _l(
              'Renseignez un ID d’objet.',
              'Please enter a game item ID.',
            ),
          );
          return;
        }
        final qty = int.tryParse(_itemQuantity.text.trim()) ?? 1;
        if (qty <= 0) {
          await showCupertinoEditorAlert(
            context,
            message: _l(
              'La quantité doit être un entier > 0.',
              'Quantity must be an integer greater than zero.',
            ),
          );
          return;
        }
        itemPayload = MapEntityItemData(
          gameItemId: _itemGameId.text.trim(),
          quantity: qty,
          pickupMode: _itemPickup,
          respawnPolicy: _itemRespawn,
        );
        break;
      case MapEntityKind.spawn:
        spawnPayload = MapEntitySpawnData(
          spawnKey: _spawnKey.text.trim(),
          role: _spawnRole,
          facing: _spawnFacing,
          categoryTag: _spawnCategory.text.trim(),
        );
        break;
      case MapEntityKind.custom:
        break;
    }

    if (!mounted) {
      return;
    }

    final properties = <String, String>{};
    for (final row in _propertyRows) {
      final key = row.keyController.text.trim();
      final value = row.valueController.text.trim();
      if (key.isEmpty && value.isEmpty) {
        continue;
      }
      if (key.isEmpty) {
        if (!context.mounted) {
          return;
        }
        await showCupertinoEditorAlert(
          context,
          message: _l(
            'Les clés de propriétés ne peuvent pas être vides.',
            'Entity property keys cannot be empty.',
          ),
        );
        return;
      }
      if (properties.containsKey(key)) {
        if (!context.mounted) {
          return;
        }
        await showCupertinoEditorAlert(
          context,
          message: _l(
            'Clé dupliquée : $key',
            'Duplicate entity property key: $key',
          ),
        );
        return;
      }
      properties[key] = value;
    }

    final trimmedName = _nameController.text.trim();

    notifier.updateSelectedEntity(
      id: _idController.text.trim(),
      name: trimmedName,
      kind: _selectedKind,
      x: x,
      y: y,
      width: width,
      height: height,
      properties: properties,
      blocksMovement: _blocksMovement,
      npc: _selectedKind == MapEntityKind.npc ? npcPayload : null,
      sign: _selectedKind == MapEntityKind.sign ? signPayload : null,
      item: _selectedKind == MapEntityKind.item ? itemPayload : null,
      spawn: _selectedKind == MapEntityKind.spawn ? spawnPayload : null,
      editorVisual: editorVisualPayload,
    );
  }

  static IconData _iconForEntityKind(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => CupertinoIcons.person,
      MapEntityKind.sign => CupertinoIcons.textformat,
      MapEntityKind.item => CupertinoIcons.cube_box,
      MapEntityKind.spawn => CupertinoIcons.flag,
      MapEntityKind.custom => CupertinoIcons.square_stack_3d_up,
    };
  }

  static Color _entityColor(MapEntityKind kind) {
    return switch (kind) {
      MapEntityKind.npc => const Color(0xFF55D0FF),
      MapEntityKind.sign => const Color(0xFFFFC857),
      MapEntityKind.item => const Color(0xFF7CE38B),
      MapEntityKind.spawn => const Color(0xFFFF7B7B),
      MapEntityKind.custom => const Color(0xFFC18CFF),
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
}

class _EntityPropertyDraft {
  _EntityPropertyDraft({
    required this.keyController,
    required this.valueController,
  });

  factory _EntityPropertyDraft.empty() {
    return _EntityPropertyDraft(
      keyController: TextEditingController(),
      valueController: TextEditingController(),
    );
  }

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

class _NpcWaypointDraft {
  _NpcWaypointDraft({
    required this.xController,
    required this.yController,
  });

  final TextEditingController xController;
  final TextEditingController yController;

  void dispose() {
    xController.dispose();
    yController.dispose();
  }
}
