import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../design_system/design_system.dart';
import '../../../theme/theme.dart';

enum MapEventsWorkspaceView { sources, events, worldRules }

enum MapEventsWorkspaceSourceType { all, mapEntry, zone, npc, object, other }

enum MapEventsWorkspaceStatus { all, linked, unlinked, attention }

/// Dedicated Events-by-map workspace.
///
/// Geometry remains read-only here. Every physical action is delegated to the
/// Map Editor through [onOpenSource], while narrative dependencies use exact
/// typed IDs carried by the core read model.
class MapEventsWorkspace extends StatefulWidget {
  const MapEventsWorkspace({
    super.key,
    required this.readModel,
    this.requestedMapId,
    this.requestedFocusAnchorId,
    this.requestedSelectionNonce = 0,
    this.onOpenSource,
    this.onOpenEvent,
    this.onOpenScene,
    this.onOpenFact,
    this.onOpenWorldRule,
  });

  final NarrativeMapEventsReadModel readModel;
  final String? requestedMapId;
  final String? requestedFocusAnchorId;
  final int requestedSelectionNonce;
  final ValueChanged<NarrativeMapEventSourceRow>? onOpenSource;
  final ValueChanged<String>? onOpenEvent;
  final ValueChanged<String>? onOpenScene;
  final ValueChanged<String>? onOpenFact;
  final ValueChanged<String>? onOpenWorldRule;

  @override
  State<MapEventsWorkspace> createState() => _MapEventsWorkspaceState();
}

class _MapEventsWorkspaceState extends State<MapEventsWorkspace> {
  MapEventsWorkspaceView _view = MapEventsWorkspaceView.sources;
  MapEventsWorkspaceSourceType _sourceType = MapEventsWorkspaceSourceType.all;
  MapEventsWorkspaceStatus _status = MapEventsWorkspaceStatus.all;
  String _query = '';
  String? _selectedMapId;
  String? _selectedStableKey;
  int? _appliedSelectionNonce;

  @override
  void initState() {
    super.initState();
    _restoreRequestedSelection();
  }

  @override
  void didUpdateWidget(covariant MapEventsWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readModel != widget.readModel ||
        oldWidget.requestedSelectionNonce != widget.requestedSelectionNonce ||
        oldWidget.requestedMapId != widget.requestedMapId ||
        oldWidget.requestedFocusAnchorId != widget.requestedFocusAnchorId) {
      _restoreRequestedSelection();
    }
  }

  void _restoreRequestedSelection() {
    if (_appliedSelectionNonce == widget.requestedSelectionNonce &&
        _selectedMapId != null) {
      return;
    }
    _appliedSelectionNonce = widget.requestedSelectionNonce;
    final requestedMap = widget.requestedMapId == null
        ? null
        : widget.readModel.mapById(widget.requestedMapId!);
    final map = requestedMap ?? widget.readModel.maps.firstOrNull;
    _selectedMapId = map?.mapId;
    final anchor = widget.requestedFocusAnchorId;
    if (anchor != null && map != null && _mapOwnsAnchor(map, anchor)) {
      _selectedStableKey = anchor;
      _view = _viewForAnchor(anchor);
    } else {
      _selectedStableKey = map?.sources.firstOrNull?.stableKey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final map = _selectedMapId == null
        ? null
        : widget.readModel.mapById(_selectedMapId!);
    if (map == null) {
      return const PokeMapPageSurface(
        child: PokeMapEmptyState(
          title: 'Aucune map narrative',
          description: 'Ajoutez une map au projet pour inspecter ses sources.',
          icon: Icon(CupertinoIcons.map),
        ),
      );
    }
    return PokeMapPageSurface(
      key: const ValueKey('map-events-workspace'),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildToolbar(context, map),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 980) {
                  return Column(
                    children: [
                      SizedBox(height: 132, child: _buildMapRail(context)),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 3,
                        child: _buildRowsPanel(context, map),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        flex: 2,
                        child: _buildInspector(context, map),
                      ),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 220, child: _buildMapRail(context)),
                    const SizedBox(width: 8),
                    Expanded(flex: 5, child: _buildRowsPanel(context, map)),
                    const SizedBox(width: 8),
                    Expanded(flex: 4, child: _buildInspector(context, map)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    NarrativeMapEventsMapSummary map,
  ) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Icon(CupertinoIcons.map_pin_ellipse, color: colors.brandPrimary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Events par map',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${map.mapLabel} · ${map.sources.length} sources · '
                  '${map.events.length} Events locaux · '
                  '${map.worldRules.length} règles',
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          PokeMapSegmentedTabs(
            tabs: [
              PokeMapSegmentedTab(
                key: const ValueKey('map-events-view-sources'),
                label: 'Sources',
                icon: CupertinoIcons.scope,
                selected: _view == MapEventsWorkspaceView.sources,
                onTap: () => _selectView(MapEventsWorkspaceView.sources),
              ),
              PokeMapSegmentedTab(
                key: const ValueKey('map-events-view-events'),
                label: 'Events',
                icon: CupertinoIcons.bolt,
                selected: _view == MapEventsWorkspaceView.events,
                onTap: () => _selectView(MapEventsWorkspaceView.events),
              ),
              PokeMapSegmentedTab(
                key: const ValueKey('map-events-view-rules'),
                label: 'Règles',
                icon: CupertinoIcons.shield,
                selected: _view == MapEventsWorkspaceView.worldRules,
                onTap: () => _selectView(MapEventsWorkspaceView.worldRules),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapRail(BuildContext context) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(8),
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'MAPS DU PROJET',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
      ),
      child: ListView.separated(
        itemCount: widget.readModel.maps.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final map = widget.readModel.maps[index];
          return PokeMapCard(
            key: ValueKey('map-events-map-${map.mapId}'),
            selected: map.mapId == _selectedMapId,
            padding: const EdgeInsets.all(10),
            onTap: () => setState(() {
              _selectedMapId = map.mapId;
              _selectedStableKey = map.sources.firstOrNull?.stableKey;
            }),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.map,
                  size: 16,
                  color: map.diagnostics.any(
                    (item) =>
                        item.severity ==
                        NarrativeMapEventsDiagnosticSeverity.error,
                  )
                      ? colors.error
                      : colors.mapAccent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        map.mapLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${map.events.length} Events',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRowsPanel(
    BuildContext context,
    NarrativeMapEventsMapSummary map,
  ) {
    final colors = context.pokeMapColors;
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(10),
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            PokeMapTextField(
              label: 'Rechercher dans cette map',
              fieldKey: const ValueKey('map-events-search'),
              hintText: 'Source, Event, Scene ou règle…',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (_view == MapEventsWorkspaceView.sources) ...[
                  Expanded(
                    child: PokeMapDropdownField<MapEventsWorkspaceSourceType>(
                      label: 'Type',
                      value: _sourceType,
                      items: [
                        for (final value in MapEventsWorkspaceSourceType.values)
                          PokeMapDropdownItem(
                            value: value,
                            label: _sourceTypeLabel(value),
                          ),
                      ],
                      onChanged: (value) => setState(() => _sourceType = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      _statusButton(MapEventsWorkspaceStatus.all, 'Tous'),
                      _statusButton(
                        MapEventsWorkspaceStatus.linked,
                        'Liés',
                      ),
                      _statusButton(
                        MapEventsWorkspaceStatus.unlinked,
                        'Sans Event',
                      ),
                      _statusButton(
                        MapEventsWorkspaceStatus.attention,
                        'Attention',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      footer: map.diagnostics.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    size: 14,
                    color: colors.warning,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${map.diagnostics.length} point(s) à examiner sur cette map.',
                      style: TextStyle(color: colors.warning, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
      child: switch (_view) {
        MapEventsWorkspaceView.sources => _buildSourceRows(context, map),
        MapEventsWorkspaceView.events => _buildEventRows(context, map),
        MapEventsWorkspaceView.worldRules => _buildRuleRows(context, map),
      },
    );
  }

  Widget _statusButton(MapEventsWorkspaceStatus status, String label) {
    return PokeMapButton(
      key: ValueKey('map-events-status-${status.name}'),
      onPressed: () => setState(() => _status = status),
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.small,
      isSelected: _status == status,
      child: Text(label),
    );
  }

  Widget _buildSourceRows(
    BuildContext context,
    NarrativeMapEventsMapSummary map,
  ) {
    final rows = map.sources.where(_sourceVisible).toList();
    if (rows.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucune source pour ces filtres',
        description: 'Modifiez le type, le statut ou la recherche.',
        icon: Icon(CupertinoIcons.scope),
      );
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (context, index) => _sourceCard(context, rows[index]),
    );
  }

  Widget _sourceCard(
    BuildContext context,
    NarrativeMapEventSourceRow row,
  ) {
    final colors = context.pokeMapColors;
    return PokeMapCard(
      key: ValueKey('map-events-source-${row.option.ownerId ?? 'map'}'),
      selected: _selectedStableKey == row.stableKey,
      onTap: () => setState(() => _selectedStableKey = row.stableKey),
      child: Row(
        children: [
          Icon(
            _sourceIcon(row.option.presentationKind),
            size: 18,
            color: row.hasPriorityConflict
                ? colors.warning
                : row.option.selectable
                    ? colors.mapAccent
                    : colors.textMuted,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.option.humanLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _sourceSubtitle(row),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ),
          PokeMapBadge(
            label: _sourceBadge(row),
            variant: _sourceBadgeVariant(row),
          ),
        ],
      ),
    );
  }

  Widget _buildEventRows(
    BuildContext context,
    NarrativeMapEventsMapSummary map,
  ) {
    final rows = _allEventRows(map).where(_eventVisible).toList();
    if (rows.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucun Event pour ces filtres',
        icon: Icon(CupertinoIcons.bolt),
      );
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final row = rows[index];
        final colors = context.pokeMapColors;
        return PokeMapCard(
          key: ValueKey('map-events-event-${row.eventId}'),
          selected: _selectedStableKey == row.stableKey,
          onTap: () => setState(() => _selectedStableKey = row.stableKey),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.bolt_fill,
                size: 17,
                color: row.hasPriorityConflict
                    ? colors.warning
                    : row.summary.enabled == true
                        ? colors.success
                        : colors.textMuted,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.summary.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${row.summary.conditions.humanLabel} · '
                      '${row.summary.scene.humanLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              PokeMapBadge(
                label: _eventBadge(row),
                variant: _eventBadgeVariant(row),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRuleRows(
    BuildContext context,
    NarrativeMapEventsMapSummary map,
  ) {
    final rows = map.worldRules.where(_ruleVisible).toList();
    if (rows.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucune World Rule pour ces filtres',
        icon: Icon(CupertinoIcons.shield),
      );
    }
    return ListView.separated(
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 7),
      itemBuilder: (context, index) {
        final row = rows[index];
        final colors = context.pokeMapColors;
        return PokeMapCard(
          key: ValueKey('map-events-rule-${row.ruleId}'),
          selected: _selectedStableKey == row.stableKey,
          onTap: () => setState(() => _selectedStableKey = row.stableKey),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.shield_fill,
                size: 17,
                color: row.targetAvailable ? colors.narrative : colors.error,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.rule.label,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_ruleSourceLabel(row.rule)} → '
                      '${_ruleEffectLabel(row.rule.effect.kind)}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              PokeMapBadge(
                label: row.rule.enabled ? 'Active' : 'Inactive',
                variant: row.rule.enabled
                    ? PokeMapBadgeVariant.success
                    : PokeMapBadgeVariant.neutral,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInspector(
    BuildContext context,
    NarrativeMapEventsMapSummary map,
  ) {
    final selected = _selectedStableKey;
    final source = selected == null ? null : map.sourceByStableKey(selected);
    NarrativeMapEventRow? event;
    NarrativeMapWorldRuleRow? rule;
    for (final candidate in _allEventRows(map)) {
      if (candidate.stableKey == selected) event = candidate;
    }
    for (final candidate in map.worldRules) {
      if (candidate.stableKey == selected) rule = candidate;
    }
    return PokeMapPanel(
      expandChild: true,
      padding: const EdgeInsets.all(12),
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'INSPECTEUR DE MAP',
          style: TextStyle(
            color: context.pokeMapColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .5,
          ),
        ),
      ),
      child: SingleChildScrollView(
        child: source != null
            ? _sourceInspector(context, source, map)
            : event != null
                ? _eventInspector(context, event, map)
                : rule != null
                    ? _ruleInspector(context, rule, map)
                    : const PokeMapEmptyState(
                        title: 'Sélectionnez une ligne',
                        description:
                            'La source, ses Events et ses dépendances apparaîtront ici.',
                        icon: Icon(CupertinoIcons.slider_horizontal_3),
                      ),
      ),
    );
  }

  Widget _sourceInspector(
    BuildContext context,
    NarrativeMapEventSourceRow row,
    NarrativeMapEventsMapSummary map,
  ) {
    final colors = context.pokeMapColors;
    final linked = [
      for (final event in map.events)
        if (row.eventIds.contains(event.eventId)) event,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          row.option.humanLabel,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aperçu de la map',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Icon(CupertinoIcons.scope, color: colors.mapAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${map.mapLabel} · ${_geometryLabel(row.option.geometry)}',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PokeMapButton(
          key: const ValueKey('map-events-open-source'),
          onPressed: widget.onOpenSource == null || !row.option.selectable
              ? null
              : () => widget.onOpenSource!(row),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.compact,
          leading: const Icon(CupertinoIcons.map),
          child: const Text('Ouvrir dans le Map Editor'),
        ),
        const SizedBox(height: 14),
        _sectionTitle(context, 'EVENTS LIÉS (${linked.length})'),
        const SizedBox(height: 7),
        if (linked.isEmpty)
          Text(
            'Aucun Event n’utilise encore cette source.',
            style: TextStyle(color: colors.textSecondary, fontSize: 11),
          )
        else
          for (final event in linked) ...[
            PokeMapButton(
              key: ValueKey('map-events-open-event-${event.eventId}'),
              onPressed: event.eventId == null || widget.onOpenEvent == null
                  ? null
                  : () => widget.onOpenEvent!(event.eventId!),
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.bolt),
              trailing: const Icon(CupertinoIcons.chevron_right),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(event.summary.title),
              ),
            ),
            const SizedBox(height: 5),
          ],
      ],
    );
  }

  Widget _eventInspector(
    BuildContext context,
    NarrativeMapEventRow row,
    NarrativeMapEventsMapSummary map,
  ) {
    final colors = context.pokeMapColors;
    final summary = row.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          summary.title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          summary.source.humanSentence,
          style: TextStyle(color: colors.textSecondary, fontSize: 11),
        ),
        const SizedBox(height: 10),
        _factLine(context, 'Conditions', summary.conditions.humanLabel),
        _factLine(
          context,
          'Ordre',
          'Priorité ${summary.lifecycle.priority ?? 0} · '
              'Ordre ${summary.lifecycle.order ?? 0}',
        ),
        _factLine(context, 'Scene', summary.scene.humanLabel),
        if (row.sourceStableKey != null) ...[
          const SizedBox(height: 8),
          PokeMapButton(
            onPressed: () => setState(() {
              _view = MapEventsWorkspaceView.sources;
              _status = MapEventsWorkspaceStatus.all;
              _selectedStableKey = row.sourceStableKey;
            }),
            variant: PokeMapButtonVariant.secondary,
            size: PokeMapButtonSize.small,
            child: const Text('Voir la source liée'),
          ),
        ],
        if (summary.scene.sceneId != null) ...[
          const SizedBox(height: 8),
          PokeMapButton(
            key: ValueKey('map-events-open-scene-${summary.scene.sceneId}'),
            onPressed: widget.onOpenScene == null
                ? null
                : () => widget.onOpenScene!(summary.scene.sceneId!),
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            leading: const Icon(CupertinoIcons.square_stack_3d_up),
            child: const Text('Ouvrir la Scene'),
          ),
        ],
        if (row.factIds.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionTitle(context, 'FACTS UTILISÉS'),
          const SizedBox(height: 6),
          for (final factId in row.factIds)
            PokeMapButton(
              key: ValueKey('map-events-open-fact-$factId'),
              onPressed: widget.onOpenFact == null
                  ? null
                  : () => widget.onOpenFact!(factId),
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              leading: const Icon(CupertinoIcons.doc_text),
              child: Text(_conditionLabel(summary, factId)),
            ),
        ],
        if (summary.projection.consequences.isNotEmpty) ...[
          const SizedBox(height: 14),
          _sectionTitle(context, 'CONSÉQUENCES DE LA SCENE'),
          const SizedBox(height: 6),
          for (final consequence in summary.projection.consequences)
            _factLine(context, consequence.kind.name, consequence.humanLabel),
        ],
      ],
    );
  }

  Widget _ruleInspector(
    BuildContext context,
    NarrativeMapWorldRuleRow row,
    NarrativeMapEventsMapSummary map,
  ) {
    final colors = context.pokeMapColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          row.rule.label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _factLine(context, 'Source', _ruleSourceLabel(row.rule)),
        _factLine(context, 'Effet', _ruleEffectLabel(row.rule.effect.kind)),
        _factLine(
          context,
          'Cible',
          row.targetAvailable ? 'Présente sur ${map.mapLabel}' : 'Introuvable',
        ),
        const SizedBox(height: 8),
        PokeMapButton(
          key: ValueKey('map-events-open-rule-${row.ruleId}'),
          onPressed: widget.onOpenWorldRule == null
              ? null
              : () => widget.onOpenWorldRule!(row.ruleId),
          variant: PokeMapButtonVariant.secondary,
          size: PokeMapButtonSize.small,
          child: const Text('Ouvrir la World Rule'),
        ),
        if (row.sourceFactId != null) ...[
          const SizedBox(height: 6),
          PokeMapButton(
            key: ValueKey('map-events-open-fact-${row.sourceFactId}'),
            onPressed: widget.onOpenFact == null
                ? null
                : () => widget.onOpenFact!(row.sourceFactId!),
            variant: PokeMapButtonVariant.ghost,
            size: PokeMapButtonSize.small,
            child: const Text('Ouvrir le Fact source'),
          ),
        ],
      ],
    );
  }

  Widget _factLine(BuildContext context, String label, String value) {
    final colors = context.pokeMapColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: Text(
              label,
              style: TextStyle(color: colors.textMuted, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String value) => Text(
        value,
        style: TextStyle(
          color: context.pokeMapColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .4,
        ),
      );

  void _selectView(MapEventsWorkspaceView value) {
    setState(() {
      _view = value;
      _status = MapEventsWorkspaceStatus.all;
      final map = widget.readModel.mapById(_selectedMapId ?? '');
      _selectedStableKey = switch (value) {
        MapEventsWorkspaceView.sources => map?.sources.firstOrNull?.stableKey,
        MapEventsWorkspaceView.events =>
          map == null ? null : _allEventRows(map).firstOrNull?.stableKey,
        MapEventsWorkspaceView.worldRules =>
          map?.worldRules.firstOrNull?.stableKey,
      };
    });
  }

  bool _sourceVisible(NarrativeMapEventSourceRow row) {
    if (!_matchesQuery(
        '${row.option.humanLabel} ${row.option.sourceTypeLabel}')) {
      return false;
    }
    if (_sourceType != MapEventsWorkspaceSourceType.all &&
        _sourceTypeFor(row.option.presentationKind) != _sourceType) {
      return false;
    }
    return switch (_status) {
      MapEventsWorkspaceStatus.all => true,
      MapEventsWorkspaceStatus.linked => row.eventIds.isNotEmpty,
      MapEventsWorkspaceStatus.unlinked =>
        row.option.selectable && row.eventIds.isEmpty,
      MapEventsWorkspaceStatus.attention =>
        !row.option.selectable || row.hasPriorityConflict,
    };
  }

  bool _eventVisible(NarrativeMapEventRow row) {
    if (!_matchesQuery(
      '${row.summary.title} ${row.summary.scene.humanLabel} '
      '${row.summary.conditions.humanLabel}',
    )) {
      return false;
    }
    return switch (_status) {
      MapEventsWorkspaceStatus.all => true,
      MapEventsWorkspaceStatus.linked =>
        row.state == NarrativeMapEventLinkState.linked,
      MapEventsWorkspaceStatus.unlinked =>
        row.state == NarrativeMapEventLinkState.sourceMissing,
      MapEventsWorkspaceStatus.attention =>
        row.state != NarrativeMapEventLinkState.linked,
    };
  }

  bool _ruleVisible(NarrativeMapWorldRuleRow row) {
    if (!_matchesQuery('${row.rule.label} ${row.rule.description}')) {
      return false;
    }
    return switch (_status) {
      MapEventsWorkspaceStatus.all || MapEventsWorkspaceStatus.linked => true,
      MapEventsWorkspaceStatus.unlinked ||
      MapEventsWorkspaceStatus.attention =>
        !row.targetAvailable,
    };
  }

  bool _matchesQuery(String value) {
    final normalized = _query.trim().toLowerCase();
    return normalized.isEmpty || value.toLowerCase().contains(normalized);
  }

  List<NarrativeMapEventRow> _allEventRows(
    NarrativeMapEventsMapSummary map,
  ) =>
      [
        ...map.events,
        // Source-less/outcome and cross-map Events stay visible without being
        // falsely assigned to the selected physical map.
        ...widget.readModel.unassignedEvents,
        ...widget.readModel.orphanEvents,
      ];
}

bool _mapOwnsAnchor(NarrativeMapEventsMapSummary map, String anchor) =>
    map.sources.any((row) => row.stableKey == anchor) ||
    map.events.any((row) => row.stableKey == anchor) ||
    map.worldRules.any((row) => row.stableKey == anchor);

MapEventsWorkspaceView _viewForAnchor(String anchor) {
  if (anchor.startsWith('event:')) return MapEventsWorkspaceView.events;
  if (anchor.startsWith('rule:')) return MapEventsWorkspaceView.worldRules;
  return MapEventsWorkspaceView.sources;
}

String _sourceTypeLabel(MapEventsWorkspaceSourceType type) => switch (type) {
      MapEventsWorkspaceSourceType.all => 'Tous les types',
      MapEventsWorkspaceSourceType.mapEntry => 'Entrées de map',
      MapEventsWorkspaceSourceType.zone => 'Zones',
      MapEventsWorkspaceSourceType.npc => 'PNJ',
      MapEventsWorkspaceSourceType.object => 'Objets',
      MapEventsWorkspaceSourceType.other => 'Autres éléments',
    };

MapEventsWorkspaceSourceType _sourceTypeFor(
  NarrativeSpatialEventSourcePresentationKind kind,
) =>
    switch (kind) {
      NarrativeSpatialEventSourcePresentationKind.mapEntry =>
        MapEventsWorkspaceSourceType.mapEntry,
      NarrativeSpatialEventSourcePresentationKind.zone =>
        MapEventsWorkspaceSourceType.zone,
      NarrativeSpatialEventSourcePresentationKind.npc =>
        MapEventsWorkspaceSourceType.npc,
      NarrativeSpatialEventSourcePresentationKind.object =>
        MapEventsWorkspaceSourceType.object,
      NarrativeSpatialEventSourcePresentationKind.placedElement ||
      NarrativeSpatialEventSourcePresentationKind.legacy =>
        MapEventsWorkspaceSourceType.other,
    };

IconData _sourceIcon(NarrativeSpatialEventSourcePresentationKind kind) =>
    switch (kind) {
      NarrativeSpatialEventSourcePresentationKind.mapEntry =>
        CupertinoIcons.arrow_right_square,
      NarrativeSpatialEventSourcePresentationKind.zone => CupertinoIcons.square,
      NarrativeSpatialEventSourcePresentationKind.npc =>
        CupertinoIcons.person_crop_circle,
      NarrativeSpatialEventSourcePresentationKind.object =>
        CupertinoIcons.cube_box,
      NarrativeSpatialEventSourcePresentationKind.placedElement =>
        CupertinoIcons.layers,
      NarrativeSpatialEventSourcePresentationKind.legacy =>
        CupertinoIcons.archivebox,
    };

String _sourceSubtitle(NarrativeMapEventSourceRow row) {
  if (!row.option.selectable) {
    return row.option.unavailableReason ?? 'Source non rattachable';
  }
  if (row.eventIds.isEmpty) return 'Source disponible · aucun Event lié';
  if (row.eventIds.length == 1) return '1 Event lié';
  return '${row.eventIds.length} Events liés';
}

String _sourceBadge(NarrativeMapEventSourceRow row) {
  if (row.hasPriorityConflict) return 'Conflit';
  return switch (row.linkState) {
    NarrativeMapSourceLinkState.none => 'Sans Event',
    NarrativeMapSourceLinkState.one => 'Liée',
    NarrativeMapSourceLinkState.multiple => '${row.eventIds.length} Events',
    NarrativeMapSourceLinkState.unavailable => 'À réparer',
  };
}

PokeMapBadgeVariant _sourceBadgeVariant(NarrativeMapEventSourceRow row) {
  if (row.hasPriorityConflict) return PokeMapBadgeVariant.warning;
  return switch (row.linkState) {
    NarrativeMapSourceLinkState.none => PokeMapBadgeVariant.info,
    NarrativeMapSourceLinkState.one => PokeMapBadgeVariant.success,
    NarrativeMapSourceLinkState.multiple => PokeMapBadgeVariant.narrative,
    NarrativeMapSourceLinkState.unavailable => PokeMapBadgeVariant.error,
  };
}

String _eventBadge(NarrativeMapEventRow row) => switch (row.state) {
      NarrativeMapEventLinkState.priorityConflict => 'Conflit',
      NarrativeMapEventLinkState.sourceMissing => 'Source absente',
      NarrativeMapEventLinkState.noSpatialSource => 'Hors map',
      NarrativeMapEventLinkState.crossMap => 'Map inconnue',
      NarrativeMapEventLinkState.linked =>
        'P${row.summary.lifecycle.priority ?? 0} · '
            'O${row.summary.lifecycle.order ?? 0}',
    };

PokeMapBadgeVariant _eventBadgeVariant(NarrativeMapEventRow row) =>
    switch (row.state) {
      NarrativeMapEventLinkState.linked => PokeMapBadgeVariant.info,
      NarrativeMapEventLinkState.priorityConflict =>
        PokeMapBadgeVariant.warning,
      NarrativeMapEventLinkState.noSpatialSource => PokeMapBadgeVariant.neutral,
      NarrativeMapEventLinkState.sourceMissing ||
      NarrativeMapEventLinkState.crossMap =>
        PokeMapBadgeVariant.error,
    };

String _geometryLabel(NarrativeSpatialSourceGeometrySummary geometry) =>
    switch (geometry.kind) {
      NarrativeSpatialSourceGeometryKind.mapWide => 'map entière',
      NarrativeSpatialSourceGeometryKind.unavailable =>
        'géométrie indisponible',
      NarrativeSpatialSourceGeometryKind.bounds =>
        'x ${geometry.bounds!.pos.x}, y ${geometry.bounds!.pos.y} · '
            '${geometry.bounds!.size.width}×${geometry.bounds!.size.height}',
    };

String _ruleSourceLabel(WorldRuleDefinition rule) => switch (rule.source.kind) {
      WorldRuleSourceKind.fact =>
        'Fact · ${rule.source.label ?? rule.source.sourceId}',
      WorldRuleSourceKind.storyStepCompletion =>
        'Étape · ${rule.source.label ?? rule.source.sourceId}',
      WorldRuleSourceKind.consumedEvent =>
        'Event · ${rule.source.label ?? rule.source.sourceId}',
    };

String _ruleEffectLabel(WorldRuleEffectKind kind) => switch (kind) {
      WorldRuleEffectKind.entityVisible => 'Afficher l’entité',
      WorldRuleEffectKind.entityHidden => 'Masquer l’entité',
      WorldRuleEffectKind.npcDialogueOverride => 'Changer le dialogue',
      WorldRuleEffectKind.eventEnabled => 'Activer l’Event',
      WorldRuleEffectKind.eventDisabled => 'Désactiver l’Event',
      WorldRuleEffectKind.eventHidden => 'Masquer l’Event',
    };

String _conditionLabel(NarrativeEventProjectSummary summary, String factId) {
  for (final detail in summary.conditions.details) {
    if (detail.kind == NarrativeEventConditionDetailKind.fact) {
      return detail.humanLabel;
    }
  }
  return factId;
}
