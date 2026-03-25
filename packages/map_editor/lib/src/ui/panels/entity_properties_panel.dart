import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';
import '../shared/inspector_embedded_widgets.dart';

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

class _EntityPropertiesPanelState
    extends ConsumerState<EntityPropertiesPanel> {
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
  final _npcVisualElementId = TextEditingController();
  EntityFacing _npcFacing = EntityFacing.south;

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
    _npcVisualElementId.dispose();
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
    _syncControllers(selectedEntity);

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
                  orderedIds:
                      MapEntityKind.values.map((k) => k.name).toList(),
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
                      color: CupertinoColors.placeholderText.resolveFrom(context),
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
                                      fontWeight: entity.id ==
                                              state.selectedEntityId
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
                  notifier: notifier,
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
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
          maxLines: maxLines ?? 1,
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
    return (
      ref: DialogueRef(
        dialogueId: id,
        scriptPathRelative: path,
        startNode: node.isEmpty ? null : node,
      ),
      invalid: false,
    );
  }

  Widget _kindSpecificFields(BuildContext context) {
    switch (_selectedKind) {
      case MapEntityKind.npc:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                color: CupertinoColors.placeholderText.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Dialogue (ID)', 'Dialogue ID'),
              controller: _npcDialogueId,
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Script (chemin relatif)', 'Script (relative path)'),
              controller: _npcScriptPath,
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Nœud de départ', 'Start node'),
              controller: _npcStartNode,
            ),
            const SizedBox(height: 8),
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
            _labeledField(
              context,
              label: _l('Visuel (ID élément)', 'Visual (element ID)'),
              controller: _npcVisualElementId,
            ),
          ],
        );
      case MapEntityKind.sign:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              _l('Ou dialogue scripté', 'Or scripted dialogue'),
              style: TextStyle(
                fontSize: 11,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Dialogue (ID)', 'Dialogue ID'),
              controller: _signDialogueId,
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Script (chemin relatif)', 'Script (relative path)'),
              controller: _signScriptPath,
            ),
            const SizedBox(height: 8),
            _labeledField(
              context,
              label: _l('Nœud de départ', 'Start node'),
              controller: _signStartNode,
            ),
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
                final picked =
                    await showCupertinoListPicker<ItemRespawnPolicy>(
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
    required EditorNotifier notifier,
    required MapEntity selectedEntity,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          style: TextStyle(fontSize: 11, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
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
              setState(() => _selectedKind = picked);
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
                keyboardType: const TextInputType.numberWithOptions(signed: true),
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
                keyboardType: const TextInputType.numberWithOptions(signed: true),
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
        const SizedBox(height: 12),
        _kindSpecificFields(context),
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

  void _syncControllers(MapEntity? entity) {
    final fingerprint = _entityFingerprint(entity);
    if (_boundFingerprint == fingerprint) {
      return;
    }
    _boundFingerprint = fingerprint;

    _idController.text = entity?.id ?? '';
    if (entity != null && entity.kind == MapEntityKind.npc) {
      final dn = entity.npc?.displayName.trim() ?? '';
      _nameController.text =
          dn.isNotEmpty ? dn : (entity.name.trim().isNotEmpty ? entity.name : entity.id);
    } else {
      _nameController.text = entity?.name ?? '';
    }
    _xController.text = entity?.pos.x.toString() ?? '';
    _yController.text = entity?.pos.y.toString() ?? '';
    _widthController.text = entity?.size.width.toString() ?? '';
    _heightController.text = entity?.size.height.toString() ?? '';
    _selectedKind = entity?.kind ?? MapEntityKind.npc;

    final n = entity?.npc ?? const MapEntityNpcData();
    _npcDialogueId.text = n.dialogue?.dialogueId ?? '';
    _npcScriptPath.text = n.dialogue?.scriptPathRelative ?? '';
    _npcStartNode.text = n.dialogue?.startNode ?? '';
    _npcFacing = n.facing;
    _npcVisualElementId.text = n.visualElementId;

    final s = entity?.sign ?? const MapEntitySignData();
    _signTitle.text = s.title;
    _signPlainText.text = s.plainText;
    _signDialogueId.text = s.dialogue?.dialogueId ?? '';
    _signScriptPath.text = s.dialogue?.scriptPathRelative ?? '';
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
      enc(entity.npc?.toJson()),
      enc(entity.sign?.toJson()),
      enc(entity.item?.toJson()),
      enc(entity.spawn?.toJson()),
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

    switch (_selectedKind) {
      case MapEntityKind.npc:
        final r = await _parseDialogueRef(
          context,
          _npcDialogueId,
          _npcScriptPath,
          _npcStartNode,
        );
        if (r.invalid) {
          return;
        }
        npcPayload = MapEntityNpcData(
          displayName: _nameController.text.trim(),
          dialogue: r.ref,
          facing: _npcFacing,
          visualElementId: _npcVisualElementId.text.trim(),
        );
        break;
      case MapEntityKind.sign:
        final r = await _parseDialogueRef(
          context,
          _signDialogueId,
          _signScriptPath,
          _signStartNode,
        );
        if (r.invalid) {
          return;
        }
        signPayload = MapEntitySignData(
          title: _signTitle.text.trim(),
          dialogue: r.ref,
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
      npc: _selectedKind == MapEntityKind.npc ? npcPayload : null,
      sign: _selectedKind == MapEntityKind.sign ? signPayload : null,
      item: _selectedKind == MapEntityKind.item ? itemPayload : null,
      spawn: _selectedKind == MapEntityKind.spawn ? spawnPayload : null,
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
