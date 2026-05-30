import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/tools/editor_tool.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_embedded_widgets.dart';

const _kScriptNoneMenuId = '__event_script_none__';
const _kStartNodeDefaultMenuId = '__event_script_start_default__';
const _kSceneNoneMenuId = '__event_scene_none__';
const _kConditionJsonRawModeHelpTextFr =
    'Colle ici uniquement un objet JSON de type ScriptCondition. '
    'Utilise ce mode pour les conditions avancées non couvertes par '
    'l’éditeur simplifié.';
const _kConditionJsonRawModeHelpTextEn =
    'Paste only a ScriptCondition JSON object here. '
    'Use this advanced mode for conditions not covered by the simple editor.';

class _ConditionJsonExample {
  const _ConditionJsonExample({
    required this.id,
    required this.labelFr,
    required this.labelEn,
    required this.condition,
  });

  final String id;
  final String labelFr;
  final String labelEn;
  final ScriptCondition condition;
}

final List<_ConditionJsonExample> _kConditionJsonExamples =
    <_ConditionJsonExample>[
  _ConditionJsonExample(
    id: 'flag_set',
    labelFr: 'Flag actif',
    labelEn: 'Flag is set',
    condition: ScriptConditionFactory.flagIsSet('story.got_starter'),
  ),
  _ConditionJsonExample(
    id: 'flag_unset',
    labelFr: 'Flag inactif',
    labelEn: 'Flag is unset',
    condition: ScriptConditionFactory.flagIsUnset('story.got_starter'),
  ),
  _ConditionJsonExample(
    id: 'event_consumed',
    labelFr: 'Event consommé',
    labelEn: 'Event is consumed',
    condition: ScriptConditionFactory.eventIsConsumed('event_intro'),
  ),
  _ConditionJsonExample(
    id: 'variable_equals',
    labelFr: 'Variable égale',
    labelEn: 'Variable equals',
    condition: ScriptConditionFactory.variableEqualsInt('quest.step', 2),
  ),
  _ConditionJsonExample(
    id: 'not_event_consumed',
    labelFr: 'not(event consommé)',
    labelEn: 'not(event consumed)',
    condition: ScriptConditionFactory.not(
      ScriptConditionFactory.eventIsConsumed('event_intro'),
    ),
  ),
  _ConditionJsonExample(
    id: 'all_of',
    labelFr: 'allOf(...)',
    labelEn: 'allOf(...)',
    condition: ScriptConditionFactory.allOf(
      <ScriptCondition>[
        ScriptConditionFactory.flagIsSet('story.got_starter'),
        ScriptConditionFactory.not(
          ScriptConditionFactory.eventIsConsumed('event_intro'),
        ),
      ],
    ),
  ),
];

enum _EventConditionMode {
  none,
  flagIsSet,
  flagIsUnset,
  eventIsConsumed,
  rawJson,
}

class EventPropertiesPanel extends ConsumerStatefulWidget {
  const EventPropertiesPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  ConsumerState<EventPropertiesPanel> createState() =>
      _EventPropertiesPanelState();
}

class _EventPropertiesPanelState extends ConsumerState<EventPropertiesPanel> {
  final _idController = TextEditingController();
  final _titleController = TextEditingController();
  final _xController = TextEditingController();
  final _yController = TextEditingController();

  final _pageNumberController = TextEditingController();
  final _pageMessageController = TextEditingController();
  final _conditionValueController = TextEditingController();
  final _conditionJsonController = TextEditingController();

  String? _boundEventFingerprint;
  String? _boundPageFingerprint;
  MapEventType _selectedType = MapEventType.actor;
  String? _selectedLayerId;
  int _selectedPageIndex = 0;
  String _selectedScriptMenuId = _kScriptNoneMenuId;
  String _selectedStartNodeMenuId = _kStartNodeDefaultMenuId;
  String _selectedSceneMenuId = _kSceneNoneMenuId;
  _EventConditionMode _conditionMode = _EventConditionMode.none;

  @override
  void dispose() {
    _idController.dispose();
    _titleController.dispose();
    _xController.dispose();
    _yController.dispose();
    _pageNumberController.dispose();
    _pageMessageController.dispose();
    _conditionValueController.dispose();
    _conditionJsonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorNotifierProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final map = state.activeMap;
    final selectedEvent = notifier.getSelectedMapEvent();

    _syncEventControllers(selectedEvent: selectedEvent, map: map);
    _syncPageControllers(selectedEvent: selectedEvent, project: state.project);

    if (map == null) {
      return Center(
        child: Text(
          widget.embedded ? 'Aucune carte chargée' : 'No map loaded',
          style: TextStyle(
            color: CupertinoColors.placeholderText.resolveFrom(context),
          ),
        ),
      );
    }

    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    const accent = EditorChrome.inspectorJoyCyan;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final eventCards = map.events;

    final content = ListView(
      padding: widget.embedded
          ? kInspectorTileBodyPadding
          : const EdgeInsets.fromLTRB(8, 8, 8, 8),
      children: [
        if (widget.embedded)
          InspectorEmbeddedDropdown(
            accent: accent,
            fieldLabel: 'Outil événement',
            valueLabel: state.activeTool == EditorToolType.eventPlacement
                ? 'Actif'
                : 'Inactif',
            orderedIds: const ['event_tool'],
            selectedMenuValue: 'event_tool',
            selectedIdForCheck: 'event_tool',
            idToLabel: (_) => 'Activer placement Event',
            onSelected: (_) =>
                notifier.selectTool(EditorToolType.eventPlacement),
            tooltip: 'Activer l’outil Event',
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.embedded ? 'Events de la carte' : 'Map events',
                style: TextStyle(
                  fontSize: 12,
                  color: subtle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            EditorToolbarIconButton(
              onPressed: () {
                final center = GridPos(
                  x: math.max(0, map.size.width ~/ 2),
                  y: math.max(0, map.size.height ~/ 2),
                );
                notifier.addMapEventAt(center);
                notifier.selectTool(EditorToolType.eventPlacement);
              },
              icon: CupertinoIcons.add,
              tooltip: widget.embedded
                  ? 'Créer un event au centre'
                  : 'Create event at center',
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          state.activeTool == EditorToolType.eventPlacement
              ? (widget.embedded
                  ? 'Outil Event actif: cliquez sur la carte pour ajouter ou sélectionner un event.'
                  : 'Event tool active: click on the map to add or select an event.')
              : (widget.embedded
                  ? 'Activez l’outil Event puis cliquez sur la carte pour créer un event.'
                  : 'Activate the Event tool then click on map to create events.'),
          style: TextStyle(
            fontSize: 11,
            color: subtle,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 10),
        if (eventCards.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              widget.embedded
                  ? 'Aucun event sur cette carte.'
                  : 'No events on this map.',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 12,
              ),
            ),
          )
        else
          ...eventCards.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: event.id == state.selectedMapEventId
                      ? Color.lerp(
                          EditorChrome.islandFillElevated(context),
                          accent,
                          0.3,
                        )!
                      : EditorChrome.islandFillElevated(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: event.id == state.selectedMapEventId
                        ? accent.withValues(alpha: 0.78)
                        : EditorChrome.editorIslandRim(context),
                    width: 1,
                  ),
                  boxShadow: EditorChrome.inspectorTileHardShadows(context),
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  alignment: Alignment.centerLeft,
                  onPressed: () => notifier.selectMapEvent(event.id),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        CupertinoIcons.flag,
                        size: 16,
                        color: event.id == state.selectedMapEventId
                            ? accent
                            : subtle,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title.trim().isNotEmpty
                                  ? event.title
                                  : event.id,
                              style: TextStyle(
                                fontSize: 12,
                                color: labelColor,
                                fontWeight: event.id == state.selectedMapEventId
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${event.id} | ${event.type.name} | (${event.position.x}, ${event.position.y}) | ${event.pages.length} page(s)',
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
        if (selectedEvent == null)
          Text(
            widget.embedded
                ? 'Sélectionnez un event pour modifier ses propriétés.'
                : 'Select an event to edit properties.',
            style: TextStyle(
              color: CupertinoColors.placeholderText.resolveFrom(context),
              fontSize: 12,
            ),
          )
        else
          _buildSelectedEventEditor(
            context: context,
            notifier: notifier,
            map: map,
            selectedEvent: selectedEvent,
            project: state.project,
          ),
        if (widget.embedded)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: const InspectorEmbeddedFootnote(
              text:
                  'Event = interaction locale conditionnelle. Pour les acteurs gameplay riches (NPC complet, item complexe), continue d’utiliser Map Entities.',
              accent: accent,
            ),
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
                    'EVENTS',
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
                  '${map.events.length}',
                  style: TextStyle(
                    fontSize: 11,
                    color: subtle,
                  ),
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

  Widget _buildSelectedEventEditor({
    required BuildContext context,
    required EditorNotifier notifier,
    required MapData map,
    required MapEventDefinition selectedEvent,
    required ProjectManifest? project,
  }) {
    const accent = EditorChrome.inspectorJoyCyan;
    final layers = map.layers;
    final layerIds = [for (final layer in layers) layer.id];
    final selectedLayerId = _selectedLayerId;
    final safeSelectedLayerId = selectedLayerId != null &&
            selectedLayerId.isNotEmpty &&
            layerIds.contains(selectedLayerId)
        ? selectedLayerId
        : (layerIds.isNotEmpty ? layerIds.first : '');

    final pages = selectedEvent.pages;
    final safePageIndex =
        pages.isEmpty ? 0 : _selectedPageIndex.clamp(0, pages.length - 1);
    final selectedPage = pages.isEmpty ? null : pages[safePageIndex];

    Future<void> saveEventBase() async {
      final x = int.tryParse(_xController.text.trim());
      final y = int.tryParse(_yController.text.trim());
      final id = _idController.text.trim();
      final title = _titleController.text.trim();
      if (x == null || y == null) {
        await showCupertinoEditorAlert(
          context,
          message: widget.embedded
              ? 'Les coordonnées doivent être des entiers.'
              : 'Coordinates must be integers.',
        );
        return;
      }
      if (safeSelectedLayerId.isEmpty) {
        await showCupertinoEditorAlert(
          context,
          message: widget.embedded
              ? 'Aucun layer valide pour cet event.'
              : 'No valid layer for this event.',
        );
        return;
      }
      notifier.updateSelectedMapEvent(
        id: id,
        title: title,
        type: _selectedType,
        layerId: safeSelectedLayerId,
        x: x,
        y: y,
        pages: pages,
      );
    }

    Future<void> saveSelectedPage() async {
      if (selectedPage == null) {
        return;
      }
      final pageNumber = int.tryParse(_pageNumberController.text.trim());
      if (pageNumber == null || pageNumber < 0) {
        await showCupertinoEditorAlert(
          context,
          message: widget.embedded
              ? 'Le numéro de page doit être un entier >= 0.'
              : 'Page number must be >= 0.',
        );
        return;
      }
      final updatedCondition = _buildConditionFromDraft();
      if (_conditionMode == _EventConditionMode.rawJson &&
          updatedCondition == null &&
          _conditionJsonController.text.trim().isNotEmpty) {
        await showCupertinoEditorAlert(
          context,
          message: widget.embedded
              ? 'Condition JSON invalide.'
              : 'Invalid condition JSON.',
        );
        return;
      }
      final updatedScript = _buildScriptRefFromDraft();
      final updatedSceneTarget = _buildSceneTargetFromDraft();
      final nextPages = List<MapEventPage>.from(pages, growable: false);
      nextPages[safePageIndex] = selectedPage.copyWith(
        pageNumber: pageNumber,
        message: _normalizeOptional(_pageMessageController.text),
        condition: updatedCondition,
        script: updatedScript,
        sceneTarget: updatedSceneTarget,
      );
      final x = int.tryParse(_xController.text.trim());
      final y = int.tryParse(_yController.text.trim());
      if (x == null || y == null || safeSelectedLayerId.isEmpty) {
        await showCupertinoEditorAlert(
          context,
          message: widget.embedded
              ? 'Coordonnées ou layer invalides.'
              : 'Invalid coordinates or layer.',
        );
        return;
      }
      notifier.updateSelectedMapEvent(
        id: _idController.text.trim(),
        title: _titleController.text.trim(),
        type: _selectedType,
        layerId: safeSelectedLayerId,
        x: x,
        y: y,
        pages: nextPages,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded)
          const InspectorEmbeddedSectionLabel('Event sélectionné'),
        const SizedBox(height: 8),
        Text(
          widget.embedded
              ? 'Position map: (${selectedEvent.position.x}, ${selectedEvent.position.y})'
              : 'Map position: (${selectedEvent.position.x}, ${selectedEvent.position.y})',
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 8),
        _labeledField(
          context,
          label: widget.embedded ? 'Identifiant' : 'ID',
          controller: _idController,
        ),
        const SizedBox(height: 8),
        _labeledField(
          context,
          label: widget.embedded ? 'Titre' : 'Title',
          controller: _titleController,
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: widget.embedded ? 'Type event' : 'Event type',
          valueLabel: _eventTypeLabel(_selectedType),
          orderedIds: MapEventType.values.map((e) => e.name).toList(),
          selectedMenuValue: _selectedType.name,
          selectedIdForCheck: _selectedType.name,
          idToLabel: (id) => _eventTypeLabel(
            MapEventType.values.firstWhere((e) => e.name == id),
          ),
          onSelected: (id) {
            setState(() {
              _selectedType =
                  MapEventType.values.firstWhere((e) => e.name == id);
            });
          },
          tooltip: widget.embedded ? 'Type event' : 'Event type',
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: widget.embedded ? 'Layer' : 'Layer',
          valueLabel: safeSelectedLayerId.isEmpty
              ? (widget.embedded ? 'Aucun' : 'None')
              : safeSelectedLayerId,
          orderedIds: layerIds,
          selectedMenuValue:
              layerIds.contains(safeSelectedLayerId) ? safeSelectedLayerId : '',
          selectedIdForCheck: layerIds.contains(safeSelectedLayerId)
              ? safeSelectedLayerId
              : null,
          idToLabel: (id) => id,
          onSelected: (id) {
            setState(() {
              _selectedLayerId = id;
            });
          },
          tooltip: widget.embedded ? 'Layer de l’event' : 'Event layer',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _labeledField(
                context,
                label: 'X',
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
                label: 'Y',
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
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InspectorEmbeddedPrimaryCapsule(
                accent: accent,
                icon: CupertinoIcons.checkmark_alt_circle,
                label: widget.embedded ? 'Enregistrer Event' : 'Save event',
                onPressed: saveEventBase,
                prominent: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InspectorEmbeddedSecondaryCapsule(
                accent: EditorChrome.inspectorJoyCoral,
                icon: CupertinoIcons.trash,
                label: widget.embedded ? 'Supprimer Event' : 'Delete event',
                enabled: true,
                onPressed: notifier.deleteSelectedMapEvent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const EditorHorizontalDivider(),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: InspectorEmbeddedSectionLabel('Pages d’event'),
            ),
            EditorToolbarIconButton(
              onPressed: () {
                final maxPageNumber = pages.fold<int>(
                  -1,
                  (previous, page) => math.max(previous, page.pageNumber),
                );
                final nextPages = [
                  ...pages,
                  MapEventPage(pageNumber: maxPageNumber + 1),
                ];
                notifier.updateMapEvent(
                  eventId: selectedEvent.id,
                  pages: nextPages,
                );
                setState(() {
                  _selectedPageIndex = nextPages.length - 1;
                  _boundPageFingerprint = null;
                });
              },
              icon: CupertinoIcons.add,
              tooltip: widget.embedded ? 'Ajouter une page' : 'Add page',
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (pages.isEmpty)
          Text(
            widget.embedded
                ? 'Aucune page: ajoutez au moins une page.'
                : 'No pages: add at least one page.',
            style: TextStyle(
              fontSize: 11,
              color: CupertinoColors.placeholderText.resolveFrom(context),
            ),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < pages.length; i++)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () {
                    setState(() {
                      _selectedPageIndex = i;
                      _boundPageFingerprint = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: i == safePageIndex
                          ? accent.withValues(alpha: 0.3)
                          : EditorChrome.largeIslandSurfaceColor(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: i == safePageIndex
                            ? accent.withValues(alpha: 0.78)
                            : EditorChrome.editorIslandRim(context),
                      ),
                    ),
                    child: Text(
                      'P${pages[i].pageNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: i == safePageIndex
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (selectedPage != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _labeledField(
                  context,
                  label: widget.embedded ? 'Numéro de page' : 'Page number',
                  controller: _pageNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InspectorEmbeddedSecondaryCapsule(
                  accent: EditorChrome.inspectorJoyCoral,
                  icon: CupertinoIcons.delete,
                  label: widget.embedded ? 'Supprimer page' : 'Delete page',
                  enabled: pages.length > 1,
                  onPressed: () {
                    if (pages.length <= 1) {
                      return;
                    }
                    final nextPages =
                        List<MapEventPage>.from(pages, growable: true)
                          ..removeAt(safePageIndex);
                    notifier.updateMapEvent(
                      eventId: selectedEvent.id,
                      pages: nextPages,
                    );
                    setState(() {
                      _selectedPageIndex =
                          (safePageIndex - 1).clamp(0, nextPages.length - 1);
                      _boundPageFingerprint = null;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _labeledField(
            context,
            label:
                widget.embedded ? 'Message (optionnel)' : 'Message (optional)',
            controller: _pageMessageController,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          _buildScriptSelectors(
            context: context,
            project: project,
          ),
          const SizedBox(height: 8),
          _buildSceneTargetSelector(
            context: context,
            project: project,
            selectedPage: selectedPage,
          ),
          const SizedBox(height: 8),
          _buildConditionEditor(context),
          const SizedBox(height: 10),
          InspectorEmbeddedPrimaryCapsule(
            key: const ValueKey('event-save-page-button'),
            accent: accent,
            icon: CupertinoIcons.check_mark_circled_solid,
            label: widget.embedded ? 'Enregistrer page' : 'Save page',
            onPressed: saveSelectedPage,
            prominent: true,
          ),
        ],
      ],
    );
  }

  Widget _buildScriptSelectors({
    required BuildContext context,
    required ProjectManifest? project,
  }) {
    const accent = EditorChrome.inspectorJoyCyan;
    final scripts = project?.scripts ?? const <ProjectScriptEntry>[];
    final scriptIds = <String>[
      _kScriptNoneMenuId,
      ...scripts.map((s) => s.id),
      if (_selectedScriptMenuId != _kScriptNoneMenuId &&
          _selectedScriptMenuId.trim().isNotEmpty &&
          !scripts.any((s) => s.id == _selectedScriptMenuId))
        _selectedScriptMenuId,
    ];
    final safeScriptMenuId = scriptIds.contains(_selectedScriptMenuId)
        ? _selectedScriptMenuId
        : _kScriptNoneMenuId;
    ProjectScriptEntry? selectedScript;
    for (final entry in scripts) {
      if (entry.id == safeScriptMenuId) {
        selectedScript = entry;
        break;
      }
    }
    final nodeIds = <String>[
      _kStartNodeDefaultMenuId,
      if (selectedScript != null)
        ...selectedScript.asset.nodes.map((n) => n.id),
      if (_selectedStartNodeMenuId != _kStartNodeDefaultMenuId &&
          _selectedStartNodeMenuId.trim().isNotEmpty &&
          (selectedScript == null ||
              !selectedScript.asset.nodes
                  .any((n) => n.id == _selectedStartNodeMenuId)))
        _selectedStartNodeMenuId,
    ];
    final safeStartNode = nodeIds.contains(_selectedStartNodeMenuId)
        ? _selectedStartNodeMenuId
        : _kStartNodeDefaultMenuId;

    String scriptValueLabel(String id) {
      if (id == _kScriptNoneMenuId) {
        return widget.embedded ? 'Aucun script' : 'No script';
      }
      ProjectScriptEntry? script;
      for (final entry in scripts) {
        if (entry.id == id) {
          script = entry;
          break;
        }
      }
      if (script == null) {
        return widget.embedded ? 'Script manquant: $id' : 'Missing script: $id';
      }
      return '${script.name} (${script.id})';
    }

    String nodeValueLabel(String id) {
      if (id == _kStartNodeDefaultMenuId) {
        return widget.embedded ? 'Noeud par défaut' : 'Default start node';
      }
      return id;
    }

    return Column(
      children: [
        InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: widget.embedded ? 'Script' : 'Script',
          valueLabel: scriptValueLabel(safeScriptMenuId),
          orderedIds: scriptIds,
          selectedMenuValue: safeScriptMenuId,
          selectedIdForCheck: safeScriptMenuId,
          idToLabel: scriptValueLabel,
          onSelected: (id) {
            setState(() {
              _selectedScriptMenuId = id;
              _selectedStartNodeMenuId = _kStartNodeDefaultMenuId;
            });
          },
          tooltip: widget.embedded ? 'Script de la page' : 'Page script',
        ),
        const SizedBox(height: 8),
        InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: widget.embedded ? 'Noeud de départ' : 'Start node',
          valueLabel: nodeValueLabel(safeStartNode),
          orderedIds: nodeIds,
          selectedMenuValue: safeStartNode,
          selectedIdForCheck: safeStartNode,
          idToLabel: nodeValueLabel,
          onSelected: (id) {
            setState(() {
              _selectedStartNodeMenuId = id;
            });
          },
          tooltip: widget.embedded ? 'Noeud de départ' : 'Start node',
        ),
      ],
    );
  }

  Widget _buildSceneTargetSelector({
    required BuildContext context,
    required ProjectManifest? project,
    required MapEventPage selectedPage,
  }) {
    const accent = EditorChrome.inspectorJoyCyan;
    final scenes = project?.scenes ?? const <SceneAsset>[];
    final hasSceneTarget = _selectedSceneMenuId != _kSceneNoneMenuId &&
        _selectedSceneMenuId.trim().isNotEmpty;
    final orderedSceneIds = <String>[
      _kSceneNoneMenuId,
      ...scenes.map((scene) => scene.id),
      if (hasSceneTarget &&
          !scenes.any((scene) => scene.id == _selectedSceneMenuId))
        _selectedSceneMenuId,
    ];
    final safeSceneMenuId = orderedSceneIds.contains(_selectedSceneMenuId)
        ? _selectedSceneMenuId
        : _kSceneNoneMenuId;

    String sceneValueLabel(String id) {
      if (id == _kSceneNoneMenuId) {
        return 'Aucune Scene V1';
      }
      for (final scene in scenes) {
        if (scene.id == id) {
          return '${scene.name} (${scene.id})';
        }
      }
      return 'Scene manquante: $id';
    }

    final pageHasLegacyContent =
        selectedPage.message?.trim().isNotEmpty == true ||
            selectedPage.script != null;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InspectorEmbeddedDropdown(
          key: const ValueKey('event-scene-target-dropdown'),
          accent: accent,
          fieldLabel: 'Scene V1',
          valueLabel: sceneValueLabel(safeSceneMenuId),
          orderedIds: orderedSceneIds,
          selectedMenuValue: safeSceneMenuId,
          selectedIdForCheck: safeSceneMenuId,
          idToLabel: sceneValueLabel,
          onSelected: (id) {
            setState(() {
              _selectedSceneMenuId = id;
            });
          },
          tooltip: 'Scene V1 cible de la page',
        ),
        if (scenes.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Aucune Scene V1 disponible',
            style: TextStyle(
              fontSize: 11,
              color: secondary,
              height: 1.25,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InspectorEmbeddedSecondaryCapsule(
                key: const ValueKey('event-clear-scene-target'),
                accent: EditorChrome.inspectorJoyCoral,
                icon: CupertinoIcons.clear_circled,
                label: 'Retirer Scene',
                enabled: safeSceneMenuId != _kSceneNoneMenuId,
                onPressed: () {
                  setState(() {
                    _selectedSceneMenuId = _kSceneNoneMenuId;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const InspectorEmbeddedFootnote(
          text: 'Lien authoring uniquement, runtime Scene à venir.',
          accent: accent,
        ),
        if (pageHasLegacyContent) ...[
          const SizedBox(height: 6),
          Text(
            'Cette page contient aussi un message ou un script legacy. '
            'Le lien Scene V1 ne les remplace pas.',
            style: TextStyle(
              fontSize: 11,
              color: secondary,
              height: 1.25,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConditionEditor(BuildContext context) {
    const accent = EditorChrome.inspectorJoyCyan;
    final modeIds = _EventConditionMode.values.map((e) => e.name).toList();
    final isRawJson = _conditionMode == _EventConditionMode.rawJson;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InspectorEmbeddedDropdown(
          accent: accent,
          fieldLabel: widget.embedded ? 'Condition' : 'Condition',
          valueLabel: _conditionModeLabel(_conditionMode),
          orderedIds: modeIds,
          selectedMenuValue: _conditionMode.name,
          selectedIdForCheck: _conditionMode.name,
          idToLabel: (id) => _conditionModeLabel(
            _EventConditionMode.values.firstWhere((e) => e.name == id),
          ),
          onSelected: (id) {
            setState(() {
              _conditionMode =
                  _EventConditionMode.values.firstWhere((e) => e.name == id);
            });
          },
          tooltip: widget.embedded ? 'Condition de page' : 'Page condition',
        ),
        const SizedBox(height: 8),
        if (_conditionMode == _EventConditionMode.flagIsSet ||
            _conditionMode == _EventConditionMode.flagIsUnset)
          _labeledField(
            context,
            label: widget.embedded ? 'Nom du flag' : 'Flag name',
            controller: _conditionValueController,
          ),
        if (_conditionMode == _EventConditionMode.eventIsConsumed)
          _labeledField(
            context,
            label: widget.embedded ? 'ID event consommé' : 'Consumed event ID',
            controller: _conditionValueController,
          ),
        if (isRawJson) ...[
          _buildRawJsonHelpCard(context),
          const SizedBox(height: 8),
          _buildRawJsonExamples(context),
          const SizedBox(height: 8),
          _labeledField(
            context,
            label: widget.embedded ? 'Condition JSON' : 'Condition JSON',
            controller: _conditionJsonController,
            maxLines: 8,
            placeholder: _conditionJsonPlaceholderText,
          ),
        ],
      ],
    );
  }

  Widget _buildRawJsonHelpCard(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final body = widget.embedded
        ? _kConditionJsonRawModeHelpTextFr
        : _kConditionJsonRawModeHelpTextEn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: EditorChrome.largeIslandSurfaceColor(
          context,
          tint: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.08),
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: EditorChrome.inspectorJoyCyan.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.embedded
                ? 'Mode avancé JSON brut'
                : 'Advanced raw JSON mode',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: EditorChrome.primaryLabel(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: TextStyle(
              fontSize: 11,
              height: 1.25,
              color: secondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.embedded
                ? 'Types utiles: flagIsSet/flagIsUnset (params.flagName), '
                    'eventIsConsumed (params.eventId), variableEquals '
                    '(params.variableName, params.value), allOf/anyOf/not '
                    '(children).'
                : 'Useful types: flagIsSet/flagIsUnset (params.flagName), '
                    'eventIsConsumed (params.eventId), variableEquals '
                    '(params.variableName, params.value), allOf/anyOf/not '
                    '(children).',
            style: TextStyle(
              fontSize: 10.5,
              height: 1.28,
              color: secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawJsonExamples(BuildContext context) {
    final accent = EditorChrome.inspectorJoyCyan;
    final hintColor = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.embedded
              ? 'Exemples rapides (insère un JSON dans le champ):'
              : 'Quick examples (insert JSON into the field):',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: hintColor,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final example in _kConditionJsonExamples)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                onPressed: () => _insertRawJsonExample(example),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: EditorChrome.largeIslandSurfaceColor(
                      context,
                      tint: accent.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    widget.embedded ? example.labelFr : example.labelEn,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: EditorChrome.primaryLabel(context),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _labeledField(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? placeholder,
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
          maxLines: maxLines,
          placeholder: placeholder,
        ),
      ],
    );
  }

  String get _conditionJsonPlaceholderText =>
      _encodeConditionJson(_kConditionJsonExamples.first.condition);

  String _encodeConditionJson(ScriptCondition condition) {
    return const JsonEncoder.withIndent('  ').convert(condition.toJson());
  }

  void _insertRawJsonExample(_ConditionJsonExample example) {
    final text = _encodeConditionJson(example.condition);
    setState(() {
      _conditionJsonController.text = text;
      _conditionJsonController.selection =
          TextSelection.collapsed(offset: text.length);
    });
  }

  ScriptCondition? _buildConditionFromDraft() {
    switch (_conditionMode) {
      case _EventConditionMode.none:
        return null;
      case _EventConditionMode.flagIsSet:
        final value = _conditionValueController.text.trim();
        if (value.isEmpty) return null;
        return ScriptConditionFactory.flagIsSet(value);
      case _EventConditionMode.flagIsUnset:
        final value = _conditionValueController.text.trim();
        if (value.isEmpty) return null;
        return ScriptConditionFactory.flagIsUnset(value);
      case _EventConditionMode.eventIsConsumed:
        final value = _conditionValueController.text.trim();
        if (value.isEmpty) return null;
        return ScriptConditionFactory.eventIsConsumed(value);
      case _EventConditionMode.rawJson:
        final raw = _conditionJsonController.text.trim();
        if (raw.isEmpty) return null;
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) {
          return null;
        }
        return ScriptCondition.fromJson(decoded);
    }
  }

  ScriptRef? _buildScriptRefFromDraft() {
    final scriptId = _selectedScriptMenuId.trim();
    if (scriptId.isEmpty || scriptId == _kScriptNoneMenuId) {
      return null;
    }
    final startNode = _selectedStartNodeMenuId == _kStartNodeDefaultMenuId
        ? null
        : _selectedStartNodeMenuId.trim();
    return ScriptRef(
      scriptId: scriptId,
      startNode: startNode == null || startNode.isEmpty ? null : startNode,
    );
  }

  MapEventSceneTarget? _buildSceneTargetFromDraft() {
    final sceneId = _selectedSceneMenuId.trim();
    if (sceneId.isEmpty || sceneId == _kSceneNoneMenuId) {
      return null;
    }
    return MapEventSceneTarget(sceneId: sceneId);
  }

  void _syncEventControllers({
    required MapEventDefinition? selectedEvent,
    required MapData? map,
  }) {
    final eventFingerprint = selectedEvent == null
        ? null
        : '${selectedEvent.id}|${selectedEvent.position.layerId}|${selectedEvent.position.x}|${selectedEvent.position.y}|${selectedEvent.pages.length}|${selectedEvent.type.name}';
    if (_boundEventFingerprint == eventFingerprint) {
      return;
    }
    _boundEventFingerprint = eventFingerprint;
    _boundPageFingerprint = null;
    if (selectedEvent == null) {
      _idController.text = '';
      _titleController.text = '';
      _xController.text = '';
      _yController.text = '';
      _selectedLayerId = null;
      _selectedType = MapEventType.actor;
      _selectedPageIndex = 0;
      return;
    }
    _idController.text = selectedEvent.id;
    _titleController.text = selectedEvent.title;
    _xController.text = selectedEvent.position.x.toString();
    _yController.text = selectedEvent.position.y.toString();
    _selectedType = selectedEvent.type;
    final layerId = selectedEvent.position.layerId;
    if (map != null && map.layers.any((layer) => layer.id == layerId)) {
      _selectedLayerId = layerId;
    } else {
      _selectedLayerId =
          map?.layers.isNotEmpty == true ? map!.layers.first.id : null;
    }
    _selectedPageIndex = _selectedPageIndex.clamp(
      0,
      math.max(0, selectedEvent.pages.length - 1),
    );
  }

  void _syncPageControllers({
    required MapEventDefinition? selectedEvent,
    required ProjectManifest? project,
  }) {
    if (selectedEvent == null || selectedEvent.pages.isEmpty) {
      _boundPageFingerprint = null;
      _pageNumberController.text = '';
      _pageMessageController.text = '';
      _conditionValueController.text = '';
      _conditionJsonController.text = '';
      _selectedScriptMenuId = _kScriptNoneMenuId;
      _selectedStartNodeMenuId = _kStartNodeDefaultMenuId;
      _selectedSceneMenuId = _kSceneNoneMenuId;
      _conditionMode = _EventConditionMode.none;
      return;
    }
    final safeIndex =
        _selectedPageIndex.clamp(0, selectedEvent.pages.length - 1);
    final page = selectedEvent.pages[safeIndex];
    final pageFingerprint =
        '${selectedEvent.id}:$safeIndex:${page.pageNumber}:${page.message}:${page.script?.scriptId}:${page.script?.startNode}:${page.sceneTarget?.sceneId}:${page.condition?.type.name}:${page.condition?.params.hashCode}:${page.condition?.children.length}';
    if (_boundPageFingerprint == pageFingerprint) {
      return;
    }
    _boundPageFingerprint = pageFingerprint;

    _pageNumberController.text = page.pageNumber.toString();
    _pageMessageController.text = page.message ?? '';

    final script = page.script;
    if (script == null) {
      _selectedScriptMenuId = _kScriptNoneMenuId;
      _selectedStartNodeMenuId = _kStartNodeDefaultMenuId;
    } else {
      _selectedScriptMenuId = script.scriptId.trim();
      final startNode = script.startNode?.trim();
      _selectedStartNodeMenuId = (startNode == null || startNode.isEmpty)
          ? _kStartNodeDefaultMenuId
          : startNode;
      if (project != null &&
          !project.scripts.any((entry) => entry.id == _selectedScriptMenuId)) {
        _selectedScriptMenuId = script.scriptId;
      }
    }

    final sceneTarget = page.sceneTarget;
    if (sceneTarget == null || sceneTarget.sceneId.trim().isEmpty) {
      _selectedSceneMenuId = _kSceneNoneMenuId;
    } else {
      _selectedSceneMenuId = sceneTarget.sceneId.trim();
    }

    final condition = page.condition;
    _conditionMode = _resolveConditionMode(condition);
    if (_conditionMode == _EventConditionMode.rawJson) {
      if (condition == null) {
        _conditionJsonController.text = '';
      } else {
        _conditionJsonController.text =
            const JsonEncoder.withIndent('  ').convert(condition.toJson());
      }
      _conditionValueController.text = '';
    } else {
      _conditionJsonController.text = '';
      _conditionValueController.text = _resolveConditionSimpleValue(condition);
    }
  }

  _EventConditionMode _resolveConditionMode(ScriptCondition? condition) {
    if (condition == null) {
      return _EventConditionMode.none;
    }
    if (condition.children.isEmpty) {
      switch (condition.type) {
        case ScriptConditionType.flagIsSet:
          return _EventConditionMode.flagIsSet;
        case ScriptConditionType.flagIsUnset:
          return _EventConditionMode.flagIsUnset;
        case ScriptConditionType.eventIsConsumed:
          return _EventConditionMode.eventIsConsumed;
        default:
          break;
      }
    }
    return _EventConditionMode.rawJson;
  }

  String _resolveConditionSimpleValue(ScriptCondition? condition) {
    if (condition == null) {
      return '';
    }
    return switch (condition.type) {
      ScriptConditionType.flagIsSet =>
        condition.params[ScriptConditionParams.flagName] ?? '',
      ScriptConditionType.flagIsUnset =>
        condition.params[ScriptConditionParams.flagName] ?? '',
      ScriptConditionType.eventIsConsumed =>
        condition.params[ScriptConditionParams.eventId] ?? '',
      _ => '',
    };
  }

  String _conditionModeLabel(_EventConditionMode mode) {
    return switch (mode) {
      _EventConditionMode.none => widget.embedded ? 'Aucune' : 'None',
      _EventConditionMode.flagIsSet =>
        widget.embedded ? 'Flag actif' : 'Flag is set',
      _EventConditionMode.flagIsUnset =>
        widget.embedded ? 'Flag inactif' : 'Flag is unset',
      _EventConditionMode.eventIsConsumed =>
        widget.embedded ? 'Event consommé' : 'Event is consumed',
      _EventConditionMode.rawJson => widget.embedded ? 'JSON brut' : 'Raw JSON',
    };
  }

  String _eventTypeLabel(MapEventType type) {
    if (!widget.embedded) {
      return type.name;
    }
    return switch (type) {
      MapEventType.actor => 'Acteur',
      MapEventType.object => 'Objet',
      MapEventType.triggerZone => 'Zone trigger',
      MapEventType.effect => 'Effet',
    };
  }

  String? _normalizeOptional(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
