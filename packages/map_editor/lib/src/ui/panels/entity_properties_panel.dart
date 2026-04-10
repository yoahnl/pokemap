import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/map_entities/application/npc_runtime_rules_authoring_catalog.dart';
import '../../features/map_entities/application/npc_runtime_rules_editor_mapping.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_state.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/editor_paint_palette.dart';
import '../shared/inspector_embedded_widgets.dart';
part 'entity_properties/entity_properties_dialogue_support.dart';
part 'entity_properties/entity_properties_drafts.dart';
part 'entity_properties/entity_properties_dialogue_bindings.dart';
part 'entity_properties/entity_properties_npc_runtime.dart';

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

  // --- Visibilité PNJ + dialogues conditionnels (Map Entities, pas Step Studio) ---
  NpcRuntimeVisibilityUiMode _npcVisUiMode = NpcRuntimeVisibilityUiMode.always;
  MapEntityRuntimePredicateKind _npcVisPredicateKind =
      MapEntityRuntimePredicateKind.storyFlagSet;
  String _npcVisRefMenuId = kNpcRuntimeRefNoneMenuId;
  final List<_NpcConditionalDialogueRowDraft> _npcCondRows = [];

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
    for (final row in _npcCondRows) {
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

  /// Recharge l’état local « visibilité + variantes dialogue » depuis le PNJ carte.
  ///
  /// Distinct des worldChanges Step Studio : ici ce sont des règles **sur l’entité**
  /// consommées par le runtime overworld.
  void _syncNpcRuntimeRulesFromNpc(MapEntityNpcData? npc) {
    final n = npc ?? const MapEntityNpcData();
    final vis = parseVisibilityRuleFromNpc(n);
    _npcVisUiMode = vis.mode;
    _npcVisPredicateKind = vis.kind;
    _npcVisRefMenuId = vis.refId.trim().isEmpty
        ? kNpcRuntimeRefNoneMenuId
        : vis.refId.trim();

    for (final row in _npcCondRows) {
      row.dispose();
    }
    _npcCondRows
      ..clear()
      ..addAll(
        n.conditionalDialogues.map(_NpcConditionalDialogueRowDraft.fromModel),
      );
  }

  /// Sections « Visibilité » et « Dialogues conditionnels » pour un PNJ carte.
  ///
  /// Toute la donnée métier (ids) transite par des menus ; les helpers
  /// [buildVisibilityRuleForSave] / [buildConditionalDialogueRowForSave] font
  /// le pont vers [MapEntityNpcData] au moment de [_saveSelectedEntity].
  List<Widget> _npcMapEntityRuntimeRulesSection(
    BuildContext context,
    ProjectManifest? project,
  ) {
    const accent = EditorChrome.inspectorJoyMint;
    final catalog = project == null
        ? null
        : buildNpcRuntimeAuthoringCatalog(project);

    String visModeLabel(NpcRuntimeVisibilityUiMode m) {
      return switch (m) {
        NpcRuntimeVisibilityUiMode.always => _l('Toujours visible', 'Always visible'),
        NpcRuntimeVisibilityUiMode.visibleOnlyIf =>
          _l('Visible seulement si…', 'Visible only if…'),
        NpcRuntimeVisibilityUiMode.hiddenIf => _l('Caché si…', 'Hidden if…'),
      };
    }

    final visModeIds = NpcRuntimeVisibilityUiMode.values.map((e) => e.name).toList();
    final visSelectedId = _npcVisUiMode.name;

    List<NpcRuntimePickOption> optionsForPredicateKind(
      MapEntityRuntimePredicateKind k,
    ) {
      if (catalog == null) {
        return const [];
      }
      return switch (k) {
        MapEntityRuntimePredicateKind.storyFlagSet ||
        MapEntityRuntimePredicateKind.storyFlagUnset =>
          catalog.flags,
        MapEntityRuntimePredicateKind.stepCompleted ||
        MapEntityRuntimePredicateKind.stepNotCompleted =>
          catalog.steps,
        MapEntityRuntimePredicateKind.chapterCompleted ||
        MapEntityRuntimePredicateKind.chapterNotCompleted =>
          catalog.chapters,
        MapEntityRuntimePredicateKind.cutsceneCompleted ||
        MapEntityRuntimePredicateKind.cutsceneNotCompleted =>
          catalog.cutscenes,
      };
    }

    final dialogueEntries =
        project?.dialogues ?? const <ProjectDialogueEntry>[];
    final sortedDialogues = _sortedDialogueEntries(dialogueEntries);

    return [
      const SizedBox(height: 10),
      InspectorEmbeddedFootnote(
        text: _l(
          'Règles propres à ce PNJ (runtime carte). '
          'Ce n’est pas la même chose que les changements de monde du Step Studio.',
          'Rules for this NPC only (map runtime). '
          'Not the same as Step Studio world changes.',
        ),
        accent: accent,
      ),
      const SizedBox(height: 10),
      InspectorEmbeddedSectionLabel(
        _l('VISIBILITÉ DU PNJ', 'NPC VISIBILITY'),
      ),
      const SizedBox(height: 6),
      if (widget.embedded)
        InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: _l('Quand ce PNJ est visible', 'When this NPC is visible'),
          valueLabel: visModeLabel(_npcVisUiMode),
          orderedIds: visModeIds,
          selectedMenuValue: visSelectedId,
          selectedIdForCheck: visSelectedId,
          idToLabel: (id) => visModeLabel(
            NpcRuntimeVisibilityUiMode.values.firstWhere((e) => e.name == id),
          ),
          onSelected: (id) {
            final m = NpcRuntimeVisibilityUiMode.values.firstWhere(
              (e) => e.name == id,
            );
            setState(() => _npcVisUiMode = m);
          },
        )
      else
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () async {
            final picked = await showCupertinoListPicker<NpcRuntimeVisibilityUiMode>(
              context: context,
              title: _l('Visibilité', 'Visibility'),
              items: NpcRuntimeVisibilityUiMode.values,
              labelOf: visModeLabel,
            );
            if (picked != null && context.mounted) {
              setState(() => _npcVisUiMode = picked);
            }
          },
          child: Text(
            '${_l('Visibilité', 'Visibility')}: ${visModeLabel(_npcVisUiMode)}',
          ),
        ),
      if (_npcVisUiMode != NpcRuntimeVisibilityUiMode.always) ...[
        const SizedBox(height: 8),
        if (widget.embedded)
          InspectorEmbeddedDropdown(
            accent: accent,
            fieldLabel: _l('Condition', 'Condition'),
            valueLabel: npcRuntimePredicateKindLabelFr(_npcVisPredicateKind),
            orderedIds:
                allNpcRuntimePredicateKinds.map((e) => e.name).toList(),
            selectedMenuValue: _npcVisPredicateKind.name,
            selectedIdForCheck: _npcVisPredicateKind.name,
            idToLabel: (id) => npcRuntimePredicateKindLabelFr(
              parsePredicateKindMenuId(id) ??
                  MapEntityRuntimePredicateKind.storyFlagSet,
            ),
            onSelected: (id) {
              final k = parsePredicateKindMenuId(id);
              if (k != null) {
                setState(() => _npcVisPredicateKind = k);
              }
            },
          )
        else
          CupertinoButton(
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
            onPressed: () async {
              final picked =
                  await showCupertinoListPicker<MapEntityRuntimePredicateKind>(
                context: context,
                title: _l('Type de condition', 'Condition type'),
                items: allNpcRuntimePredicateKinds,
                labelOf: npcRuntimePredicateKindLabelFr,
              );
              if (picked != null && context.mounted) {
                setState(() => _npcVisPredicateKind = picked);
              }
            },
            child: Text(
              '${_l('Condition', 'Condition')}: ${npcRuntimePredicateKindLabelFr(_npcVisPredicateKind)}',
            ),
          ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final opts = optionsForPredicateKind(_npcVisPredicateKind);
            final ids = mergeRuntimeRefMenuIds(opts, _npcVisRefMenuId);
            final noneL = _l('Choisir…', 'Choose…');
            final orphanL =
                _l('hors liste projet', 'not listed in project');
            if (widget.embedded) {
              return InspectorEmbeddedDropdown(
                accent: accent,
                fieldLabel: _l('Cible', 'Target'),
                valueLabel: runtimeRefValueLabel(
                  opts,
                  _npcVisRefMenuId,
                  noneLabel: noneL,
                  orphanLabel: orphanL,
                ),
                orderedIds: ids,
                selectedMenuValue: ids.contains(_npcVisRefMenuId)
                    ? _npcVisRefMenuId
                    : kNpcRuntimeRefNoneMenuId,
                selectedIdForCheck: _npcVisRefMenuId,
                idToLabel: (id) => runtimeRefValueLabel(
                  opts,
                  id,
                  noneLabel: noneL,
                  orphanLabel: orphanL,
                ),
                onSelected: (id) =>
                    setState(() => _npcVisRefMenuId = id),
              );
            }
            return CupertinoButton(
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: () async {
                final picked = await showCupertinoListPicker<String>(
                  context: context,
                  title: _l('Cible', 'Target'),
                  items: ids,
                  labelOf: (id) => runtimeRefValueLabel(
                    opts,
                    id,
                    noneLabel: noneL,
                    orphanLabel: orphanL,
                  ),
                );
                if (picked != null && context.mounted) {
                  setState(() => _npcVisRefMenuId = picked);
                }
              },
              child: Text(
                '${_l('Cible', 'Target')}: ${runtimeRefValueLabel(opts, _npcVisRefMenuId, noneLabel: noneL, orphanLabel: orphanL)}',
              ),
            );
          },
        ),
        if (catalog != null &&
            optionsForPredicateKind(_npcVisPredicateKind).isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: InspectorEmbeddedFootnote(
              text: _l(
                'Aucune entrée indexée pour ce type. '
                'Créez-en une dans Step Studio, Global Story ou Cutscene Studio, '
                'ou complétez les flags dans vos scénarios.',
                'No indexed entries for this type. '
                'Author them in Step Studio, Global Story, or Cutscene Studio, '
                'or add flags in your scenarios.',
              ),
              accent: EditorChrome.inspectorJoyCoral,
            ),
          ),
      ],
      const SizedBox(height: 14),
      InspectorEmbeddedSectionLabel(
        _l('DIALOGUES CONDITIONNELS', 'CONDITIONAL DIALOGUES'),
      ),
      const SizedBox(height: 6),
      InspectorEmbeddedFootnote(
        text: _l(
          'On teste chaque ligne dans l’ordre : la première condition vraie gagne. '
          'Sinon c’est le dialogue par défaut du PNJ (champ ci-dessus).',
          'Each line is tested in order: the first true condition wins. '
          'Otherwise the NPC’s default dialogue (field above) is used.',
        ),
        accent: accent,
      ),
      const SizedBox(height: 6),
      InspectorEmbeddedFootnote(
        text: _l(
          'Transparence produit : le nœud Yarn d’une variante est encore une saisie '
          'optionnelle (pas de menu des nœuds). Laisser vide utilise le nœud '
          'défaut du dialogue dans Dialogue Studio.',
          'The variant Yarn start node is still optional free text (no node picker). '
          'Leave empty to use the dialogue’s default start node from Dialogue Studio.',
        ),
        accent: EditorChrome.inspectorJoyCoral,
      ),
      const SizedBox(height: 8),
      if (dialogueEntries.isEmpty)
        InspectorEmbeddedFootnote(
          text: _l(
            'Ajoutez des dialogues dans Dialogue Studio pour configurer des variantes.',
            'Add dialogues in Dialogue Studio to configure variants.',
          ),
          accent: accent,
        )
      else ...[
        for (var i = 0; i < _npcCondRows.length; i++)
          _buildNpcConditionalDialogueRow(
            context,
            index: i,
            catalog: catalog,
            sortedDialogues: sortedDialogues,
            accent: accent,
          ),
        const SizedBox(height: 6),
        CupertinoButton(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () {
            setState(() {
              _npcCondRows.add(_NpcConditionalDialogueRowDraft.empty());
            });
          },
          child: Text(
            _l('+ Ajouter une variante de dialogue', '+ Add dialogue variant'),
          ),
        ),
      ],
    ];
  }

  Widget _buildNpcConditionalDialogueRow(
    BuildContext context, {
    required int index,
    required NpcRuntimeAuthoringCatalog? catalog,
    required List<ProjectDialogueEntry> sortedDialogues,
    required Color accent,
  }) {
    final row = _npcCondRows[index];

    List<NpcRuntimePickOption> rowOpts(MapEntityRuntimePredicateKind k) {
      if (catalog == null) {
        return const [];
      }
      return switch (k) {
        MapEntityRuntimePredicateKind.storyFlagSet ||
        MapEntityRuntimePredicateKind.storyFlagUnset =>
          catalog.flags,
        MapEntityRuntimePredicateKind.stepCompleted ||
        MapEntityRuntimePredicateKind.stepNotCompleted =>
          catalog.steps,
        MapEntityRuntimePredicateKind.chapterCompleted ||
        MapEntityRuntimePredicateKind.chapterNotCompleted =>
          catalog.chapters,
        MapEntityRuntimePredicateKind.cutsceneCompleted ||
        MapEntityRuntimePredicateKind.cutsceneNotCompleted =>
          catalog.cutscenes,
      };
    }

    final opts = rowOpts(row.conditionKind);
    final refIds = mergeRuntimeRefMenuIds(opts, row.refMenuId);
    final dlgIds = _dialogueDropdownIds(sortedDialogues, row.dialogueMenuId);
    final noneL = _l('Choisir…', 'Choose…');
    final orphanL = _l('hors liste projet', 'not listed in project');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _l('Variante ${index + 1}', 'Variant ${index + 1}'),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 6),
              if (widget.embedded)
                InspectorEmbeddedDropdown(
                  accent: accent,
                  fieldLabel: _l('Si…', 'If…'),
                  valueLabel: npcRuntimePredicateKindLabelFr(row.conditionKind),
                  orderedIds:
                      allNpcRuntimePredicateKinds.map((e) => e.name).toList(),
                  selectedMenuValue: row.conditionKind.name,
                  selectedIdForCheck: row.conditionKind.name,
                  idToLabel: (id) => npcRuntimePredicateKindLabelFr(
                    parsePredicateKindMenuId(id) ??
                        MapEntityRuntimePredicateKind.storyFlagSet,
                  ),
                  onSelected: (id) {
                    final k = parsePredicateKindMenuId(id);
                    if (k != null) {
                      setState(() => row.conditionKind = k);
                    }
                  },
                )
              else
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () async {
                    final picked = await showCupertinoListPicker<
                        MapEntityRuntimePredicateKind>(
                      context: context,
                      title: _l('Condition', 'Condition'),
                      items: allNpcRuntimePredicateKinds,
                      labelOf: npcRuntimePredicateKindLabelFr,
                    );
                    if (picked != null && context.mounted) {
                      setState(() => row.conditionKind = picked);
                    }
                  },
                  child: Text(
                    '${_l('Si…', 'If…')}: ${npcRuntimePredicateKindLabelFr(row.conditionKind)}',
                  ),
                ),
              const SizedBox(height: 6),
              if (widget.embedded)
                InspectorEmbeddedDropdown(
                  accent: accent,
                  fieldLabel: _l('Cible', 'Target'),
                  valueLabel: runtimeRefValueLabel(
                    opts,
                    row.refMenuId,
                    noneLabel: noneL,
                    orphanLabel: orphanL,
                  ),
                  orderedIds: refIds,
                  selectedMenuValue: refIds.contains(row.refMenuId)
                      ? row.refMenuId
                      : kNpcRuntimeRefNoneMenuId,
                  selectedIdForCheck: row.refMenuId,
                  idToLabel: (id) => runtimeRefValueLabel(
                    opts,
                    id,
                    noneLabel: noneL,
                    orphanLabel: orphanL,
                  ),
                  onSelected: (id) => setState(() => row.refMenuId = id),
                )
              else
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () async {
                    final picked = await showCupertinoListPicker<String>(
                      context: context,
                      title: _l('Cible', 'Target'),
                      items: refIds,
                      labelOf: (id) => runtimeRefValueLabel(
                        opts,
                        id,
                        noneLabel: noneL,
                        orphanLabel: orphanL,
                      ),
                    );
                    if (picked != null && context.mounted) {
                      setState(() => row.refMenuId = picked);
                    }
                  },
                  child: Text(
                    '${_l('Cible', 'Target')}: ${runtimeRefValueLabel(opts, row.refMenuId, noneLabel: noneL, orphanLabel: orphanL)}',
                  ),
                ),
              const SizedBox(height: 6),
              if (widget.embedded)
                InspectorEmbeddedDropdown(
                  accent: accent,
                  fieldLabel: _l('Dialogue à jouer', 'Dialogue to play'),
                  valueLabel: _dialogueDropdownValueLabel(
                    sortedDialogues,
                    row.dialogueMenuId,
                  ),
                  orderedIds: dlgIds,
                  selectedMenuValue: dlgIds.contains(row.dialogueMenuId)
                      ? row.dialogueMenuId
                      : _kDialogueNoneMenuId,
                  selectedIdForCheck: row.dialogueMenuId,
                  idToLabel: (id) =>
                      _dialogueDropdownValueLabel(sortedDialogues, id),
                  onSelected: (id) =>
                      setState(() => row.dialogueMenuId = id),
                )
              else
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: () async {
                    final picked = await showCupertinoListPicker<String>(
                      context: context,
                      title: _l('Dialogue', 'Dialogue'),
                      items: dlgIds,
                      labelOf: (id) =>
                          _dialogueDropdownValueLabel(sortedDialogues, id),
                    );
                    if (picked != null && context.mounted) {
                      setState(() => row.dialogueMenuId = picked);
                    }
                  },
                  child: Text(
                    '${_l('Dialogue', 'Dialogue')}: ${_dialogueDropdownValueLabel(sortedDialogues, row.dialogueMenuId)}',
                  ),
                ),
              const SizedBox(height: 4),
              _labeledField(
                context,
                label: _l('Nœud Yarn (optionnel)', 'Yarn node (optional)'),
                controller: row.startNode,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.only(right: 8),
                    onPressed: index <= 0
                        ? null
                        : () {
                            setState(() {
                              final t = _npcCondRows[index - 1];
                              _npcCondRows[index - 1] = _npcCondRows[index];
                              _npcCondRows[index] = t;
                            });
                          },
                    child: Text(_l('Monter', 'Up')),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.only(right: 8),
                    onPressed: index >= _npcCondRows.length - 1
                        ? null
                        : () {
                            setState(() {
                              final t = _npcCondRows[index + 1];
                              _npcCondRows[index + 1] = _npcCondRows[index];
                              _npcCondRows[index] = t;
                            });
                          },
                    child: Text(_l('Descendre', 'Down')),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() {
                        final removed = _npcCondRows.removeAt(index);
                        removed.dispose();
                      });
                    },
                    child: Text(
                      _l('Supprimer', 'Remove'),
                      style: const TextStyle(color: CupertinoColors.destructiveRed),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
            ..._npcMapEntityRuntimeRulesSection(context, project),
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

    _syncNpcRuntimeRulesFromNpc(entity?.npc);

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

        // Visibilité + variantes : l’état vient du formulaire (pas d’écrasement
        // silencieux des règles JSON au moment de la sauvegarde).
        final visErr = validateNpcVisibilityDraft(
          uiMode: _npcVisUiMode,
          refMenuId: _npcVisRefMenuId,
        );
        if (visErr != null) {
          if (!context.mounted) {
            return;
          }
          await showCupertinoEditorAlert(context, message: visErr);
          return;
        }
        final condErr = validateConditionalDialogueDrafts(
          rows: _npcCondRows
              .map(
                (r) => (
                  dialogueMenuId: r.dialogueMenuId,
                  refMenuId: r.refMenuId,
                ),
              )
              .toList(growable: false),
          dialogueNoneId: _kDialogueNoneMenuId,
        );
        if (condErr != null) {
          if (!context.mounted) {
            return;
          }
          await showCupertinoEditorAlert(context, message: condErr);
          return;
        }
        final visibilityRule = buildVisibilityRuleForSave(
          uiMode: _npcVisUiMode,
          predicateKind: _npcVisPredicateKind,
          refMenuId: _npcVisRefMenuId,
        );
        final conditionalDialogues = <MapEntityConditionalDialogue>[];
        for (final row in _npcCondRows) {
          final dlgMenu = row.dialogueMenuId.trim();
          final built = buildConditionalDialogueRowForSave(
            conditionKind: row.conditionKind,
            refMenuId: row.refMenuId,
            dialogueId: dlgMenu == _kDialogueNoneMenuId ? '' : dlgMenu,
            startNode: row.startNode.text.trim().isEmpty
                ? null
                : row.startNode.text.trim(),
          );
          if (built != null) {
            conditionalDialogues.add(built);
          }
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
          visibilityRule: visibilityRule,
          conditionalDialogues: conditionalDialogues,
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
