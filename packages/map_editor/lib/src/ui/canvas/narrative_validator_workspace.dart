import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../theme/theme.dart';
import '../design_system/design_system.dart';

const narrativeValidatorWorkspaceKey =
    ValueKey<String>('narrative-validator-workspace');
const narrativeValidatorDiagnosticsTabKey =
    ValueKey<String>('narrative-validator-tab-diagnostics');
const narrativeValidatorMapEventsTabKey =
    ValueKey<String>('narrative-validator-tab-map-events');
const narrativeValidatorAllFilterKey =
    ValueKey<String>('narrative-validator-filter-all');
const narrativeValidatorErrorsFilterKey =
    ValueKey<String>('narrative-validator-filter-errors');
const narrativeValidatorWarningsFilterKey =
    ValueKey<String>('narrative-validator-filter-warnings');
const narrativeValidatorMapFilterKey =
    ValueKey<String>('narrative-validator-filter-map');
const narrativeValidatorDomainFilterKey =
    ValueKey<String>('narrative-validator-filter-domain');

enum _ValidatorTab { diagnostics, mapEvents }

enum _SeverityFilter { all, errors, warnings }

/// Global, read-only Narrative Validator surface.
///
/// It consumes the canonical map_core report and only owns presentation
/// filters/navigation callbacks. It never re-implements validation rules or
/// mutates project data.
class NarrativeValidatorWorkspace extends StatefulWidget {
  const NarrativeValidatorWorkspace({
    super.key,
    required this.report,
    this.onOpenDiagnostic,
    this.onOpenEvent,
    this.onOpenMap,
  });

  final NarrativeProjectValidationReport report;
  final ValueChanged<NarrativeProjectDiagnostic>? onOpenDiagnostic;
  final ValueChanged<String>? onOpenEvent;
  final ValueChanged<String>? onOpenMap;

  @override
  State<NarrativeValidatorWorkspace> createState() =>
      _NarrativeValidatorWorkspaceState();
}

class _NarrativeValidatorWorkspaceState
    extends State<NarrativeValidatorWorkspace> {
  _ValidatorTab _tab = _ValidatorTab.diagnostics;
  _SeverityFilter _severity = _SeverityFilter.all;
  String _domain = _allDomains;
  String _map = _allMaps;
  String? _selectedMapGroup;

  @override
  void didUpdateWidget(covariant NarrativeValidatorWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.report, widget.report)) {
      final keys = widget.report.mapEventViews.map(_mapGroupKey).toSet();
      final mapIds = widget.report.mapEventViews
          .where((view) => view.mapId != null)
          .map((view) => view.mapId!)
          .toSet();
      if (_selectedMapGroup != null && !keys.contains(_selectedMapGroup)) {
        _selectedMapGroup = null;
      }
      if (_map != _allMaps && !mapIds.contains(_map)) {
        _map = _allMaps;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.report;
    return Semantics(
      key: narrativeValidatorWorkspaceKey,
      container: true,
      label: report.isPlayable
          ? 'Validator narratif, projet jouable'
          : 'Validator narratif, projet non jouable',
      child: PokeMapPageSurface(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _VerdictHeader(report: report),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: PokeMapSegmentedTabs(
                    tabs: [
                      PokeMapSegmentedTab(
                        key: narrativeValidatorDiagnosticsTabKey,
                        label: 'Diagnostics',
                        icon: Icons.fact_check_outlined,
                        selected: _tab == _ValidatorTab.diagnostics,
                        onTap: () => setState(
                          () => _tab = _ValidatorTab.diagnostics,
                        ),
                      ),
                      PokeMapSegmentedTab(
                        key: narrativeValidatorMapEventsTabKey,
                        label: 'Events par map',
                        icon: Icons.map_outlined,
                        selected: _tab == _ValidatorTab.mapEvents,
                        onTap: () => setState(
                          () => _tab = _ValidatorTab.mapEvents,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: switch (_tab) {
                _ValidatorTab.diagnostics => _buildDiagnostics(context),
                _ValidatorTab.mapEvents => _buildMapEvents(context),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnostics(BuildContext context) {
    final diagnostics = widget.report.diagnostics.where((diagnostic) {
      final matchesSeverity = switch (_severity) {
        _SeverityFilter.all => true,
        _SeverityFilter.errors =>
          diagnostic.severity == NarrativeProjectDiagnosticSeverity.error,
        _SeverityFilter.warnings =>
          diagnostic.severity == NarrativeProjectDiagnosticSeverity.warning,
      };
      return matchesSeverity &&
          (_domain == _allDomains || diagnostic.domain.name == _domain) &&
          (_map == _allMaps || diagnostic.mapId == _map);
    }).toList();

    final mapViews = widget.report.mapEventViews
        .where((view) => view.mapId != null)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PokeMapPanel(
          padding: const EdgeInsets.all(10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final severity = PokeMapSegmentedTabs(
                tabs: [
                  PokeMapSegmentedTab(
                    key: narrativeValidatorAllFilterKey,
                    label: 'Tous',
                    selected: _severity == _SeverityFilter.all,
                    onTap: () => setState(
                      () => _severity = _SeverityFilter.all,
                    ),
                  ),
                  PokeMapSegmentedTab(
                    key: narrativeValidatorErrorsFilterKey,
                    label: 'Erreurs',
                    selected: _severity == _SeverityFilter.errors,
                    onTap: () => setState(
                      () => _severity = _SeverityFilter.errors,
                    ),
                  ),
                  PokeMapSegmentedTab(
                    key: narrativeValidatorWarningsFilterKey,
                    label: 'Avertissements',
                    selected: _severity == _SeverityFilter.warnings,
                    onTap: () => setState(
                      () => _severity = _SeverityFilter.warnings,
                    ),
                  ),
                ],
              );
              final domain = SizedBox(
                width: 220,
                child: PokeMapDropdownField<String>(
                  key: narrativeValidatorDomainFilterKey,
                  label: 'Domaine',
                  value: _domain,
                  items: [
                    const PokeMapDropdownItem(
                      value: _allDomains,
                      label: 'Tous les domaines',
                    ),
                    for (final value in NarrativeProjectDiagnosticDomain.values)
                      PokeMapDropdownItem(
                        value: value.name,
                        label: _domainLabel(value),
                      ),
                  ],
                  onChanged: (value) => setState(() => _domain = value),
                ),
              );
              final map = SizedBox(
                width: 220,
                child: PokeMapDropdownField<String>(
                  key: narrativeValidatorMapFilterKey,
                  label: 'Map',
                  value: _map,
                  items: [
                    const PokeMapDropdownItem(
                      value: _allMaps,
                      label: 'Toutes les maps',
                    ),
                    for (final view in mapViews)
                      PokeMapDropdownItem(
                        value: view.mapId!,
                        label: view.label,
                      ),
                  ],
                  onChanged: (value) => setState(() => _map = value),
                ),
              );
              if (constraints.maxWidth < 900) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    severity,
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [domain, map],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: severity),
                  domain,
                  const SizedBox(width: 8),
                  map,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: diagnostics.isEmpty
              ? const PokeMapEmptyState(
                  title: 'Aucun diagnostic dans ce filtre',
                  description:
                      'Changez la sévérité, le domaine ou la map pour afficher le reste du rapport.',
                  icon: Icon(Icons.filter_alt_off_outlined),
                )
              : PokeMapPanel(
                  expandChild: true,
                  padding: EdgeInsets.zero,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(10),
                    itemCount: diagnostics.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final diagnostic = diagnostics[index];
                      return KeyedSubtree(
                        key: ValueKey<String>(
                          'narrative-validator-diagnostic-$index',
                        ),
                        child: PokeMapDiagnosticCallout(
                          severity: _calloutSeverity(diagnostic.severity),
                          title: _diagnosticTitle(diagnostic),
                          message: diagnostic.message,
                          actionLabel: widget.onOpenDiagnostic == null
                              ? null
                              : 'Ouvrir la source',
                          onAction: widget.onOpenDiagnostic == null
                              ? null
                              : () => widget.onOpenDiagnostic!(diagnostic),
                          semanticLabel:
                              '${_domainLabel(diagnostic.domain)}. ${diagnostic.message}',
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMapEvents(BuildContext context) {
    final views = widget.report.mapEventViews;
    if (views.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Aucun Event narratif',
        description:
            'Créez un Event dans l’Event Builder pour voir son raccordement ici.',
        icon: Icon(Icons.map_outlined),
      );
    }
    final selectedKey = _selectedMapGroup ?? _mapGroupKey(views.first);
    final selected = views.firstWhere(
      (view) => _mapGroupKey(view) == selectedKey,
      orElse: () => views.first,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final groups = _MapGroupsPanel(
          views: views,
          selectedKey: _mapGroupKey(selected),
          onSelected: (key) => setState(() => _selectedMapGroup = key),
          onOpenMap: widget.onOpenMap,
        );
        final events = _MapEventEntriesPanel(
          view: selected,
          onOpenEvent: widget.onOpenEvent,
        );
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 170, child: groups),
              const SizedBox(height: 10),
              Expanded(child: events),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 280, child: groups),
            const SizedBox(width: 10),
            Expanded(child: events),
          ],
        );
      },
    );
  }
}

class _VerdictHeader extends StatelessWidget {
  const _VerdictHeader({required this.report});

  final NarrativeProjectValidationReport report;

  @override
  Widget build(BuildContext context) {
    final verdict = report.isPlayable ? 'Jouable' : 'Non jouable';
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        SizedBox(
          width: 230,
          height: 128,
          child: PokeMapMetricCard(
            key: const ValueKey('narrative-validator-verdict'),
            title: 'Verdict projet',
            value: verdict,
            icon: report.isPlayable
                ? Icons.verified_outlined
                : Icons.gpp_bad_outlined,
            tone: report.isPlayable ? PokeMapTone.success : PokeMapTone.danger,
            subtitle: report.isPlayable
                ? 'Aucune erreur critique'
                : 'Corrections requises avant le playtest',
          ),
        ),
        SizedBox(
          width: 180,
          height: 128,
          child: PokeMapMetricCard(
            title: 'Erreurs',
            value: '${report.errorCount}',
            icon: Icons.error_outline,
            tone: report.errorCount == 0
                ? PokeMapTone.success
                : PokeMapTone.danger,
            subtitle:
                '${report.errorCount} ${report.errorCount == 1 ? 'erreur' : 'erreurs'}',
          ),
        ),
        SizedBox(
          width: 180,
          height: 128,
          child: PokeMapMetricCard(
            title: 'Avertissements',
            value: '${report.warningCount}',
            icon: Icons.warning_amber_outlined,
            tone: report.warningCount == 0
                ? PokeMapTone.neutral
                : PokeMapTone.warning,
            subtitle:
                '${report.warningCount} ${report.warningCount == 1 ? 'avertissement' : 'avertissements'}',
          ),
        ),
        SizedBox(
          width: 180,
          height: 128,
          child: PokeMapMetricCard(
            title: 'Events contrôlés',
            value: '${report.totalEventCount}',
            icon: Icons.bolt_outlined,
            tone: PokeMapTone.info,
            subtitle: 'Toutes les maps et outcomes',
          ),
        ),
      ],
    );
  }
}

class _MapGroupsPanel extends StatelessWidget {
  const _MapGroupsPanel({
    required this.views,
    required this.selectedKey,
    required this.onSelected,
    required this.onOpenMap,
  });

  final List<NarrativeMapEventsView> views;
  final String selectedKey;
  final ValueChanged<String> onSelected;
  final ValueChanged<String>? onOpenMap;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: EdgeInsets.zero,
      header: const Padding(
        padding: EdgeInsets.all(12),
        child: PokeMapSectionHeader(
          title: 'Maps et sources',
          description: 'Vue consolidée des raccordements',
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: views.length,
        separatorBuilder: (_, __) => const SizedBox(height: 6),
        itemBuilder: (context, index) {
          final view = views[index];
          final key = _mapGroupKey(view);
          return PokeMapCard(
            key: ValueKey<String>('narrative-validator-map-group-$key'),
            selected: key == selectedKey,
            padding: const EdgeInsets.all(10),
            onTap: () => onSelected(key),
            child: Row(
              children: [
                PokeMapIconTile(
                  icon: view.groupKind == NarrativeMapEventsGroupKind.map
                      ? Icons.map_outlined
                      : Icons.alt_route_outlined,
                  tone: view.orphanSourceCount == 0
                      ? PokeMapTone.info
                      : PokeMapTone.warning,
                  size: 32,
                  iconSize: 16,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pokeMapColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${view.events.length} Event${view.events.length == 1 ? '' : 's'} · ${view.orphanSourceCount} source${view.orphanSourceCount == 1 ? '' : 's'} orpheline${view.orphanSourceCount == 1 ? '' : 's'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pokeMapColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (view.mapId != null && onOpenMap != null)
                  PokeMapIconButton(
                    key: ValueKey<String>(
                      'narrative-validator-open-map-${view.mapId}',
                    ),
                    tooltip: 'Ouvrir dans Map Editor',
                    icon: const Icon(Icons.open_in_new, size: 16),
                    onPressed: () => onOpenMap!(view.mapId!),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MapEventEntriesPanel extends StatelessWidget {
  const _MapEventEntriesPanel({
    required this.view,
    required this.onOpenEvent,
  });

  final NarrativeMapEventsView view;
  final ValueChanged<String>? onOpenEvent;

  @override
  Widget build(BuildContext context) {
    return PokeMapPanel(
      expandChild: true,
      padding: EdgeInsets.zero,
      header: Padding(
        padding: const EdgeInsets.all(12),
        child: PokeMapSectionHeader(
          title: view.label,
          description:
              '${view.events.length} raccordement${view.events.length == 1 ? '' : 's'} contrôlé${view.events.length == 1 ? '' : 's'}',
        ),
      ),
      child: view.events.isEmpty
          ? const PokeMapEmptyState(
              title: 'Aucun Event sur cette map',
              description:
                  'Cette map ne contient actuellement aucun raccordement Event V2.',
              icon: Icon(Icons.bolt_outlined),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(10),
              itemCount: view.events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final event = view.events[index];
                return PokeMapCard(
                  key: ValueKey<String>(
                    'narrative-validator-map-event-${event.eventId}',
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.pokeMapColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          PokeMapBadge(
                            label: event.enabled == false ? 'Inactif' : 'Actif',
                            variant: event.enabled == false
                                ? PokeMapBadgeVariant.neutral
                                : PokeMapBadgeVariant.success,
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          PokeMapBadge(
                            label: _sourceLabel(event),
                            variant: PokeMapBadgeVariant.narrative,
                          ),
                          PokeMapBadge(
                            label: event.sourceConnected
                                ? 'Source raccordée'
                                : 'Source orpheline',
                            variant: event.sourceConnected
                                ? PokeMapBadgeVariant.success
                                : PokeMapBadgeVariant.error,
                          ),
                          PokeMapBadge(
                            label:
                                '${event.conditionCount} condition${event.conditionCount == 1 ? '' : 's'}',
                            variant: PokeMapBadgeVariant.info,
                          ),
                          PokeMapBadge(
                            label: event.sceneConnected
                                ? 'Scene · ${event.sceneLabel ?? event.sceneId}'
                                : 'Scene manquante',
                            variant: event.sceneConnected
                                ? PokeMapBadgeVariant.success
                                : PokeMapBadgeVariant.error,
                          ),
                          if (event.diagnosticCount > 0)
                            PokeMapBadge(
                              label:
                                  '${event.diagnosticCount} erreur${event.diagnosticCount == 1 ? '' : 's'}',
                              variant: PokeMapBadgeVariant.error,
                            ),
                          if (event.warningCount > 0)
                            PokeMapBadge(
                              label:
                                  '${event.warningCount} avertissement${event.warningCount == 1 ? '' : 's'}',
                              variant: PokeMapBadgeVariant.warning,
                            ),
                        ],
                      ),
                      if (onOpenEvent != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: PokeMapButton(
                            key: ValueKey<String>(
                              'narrative-validator-open-event-${event.eventId}',
                            ),
                            onPressed: () => onOpenEvent!(event.eventId),
                            size: PokeMapButtonSize.compact,
                            variant: PokeMapButtonVariant.secondary,
                            leading: const Icon(Icons.open_in_new, size: 15),
                            child: const Text('Ouvrir dans Event Builder'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

const _allDomains = '__all__';
const _allMaps = '__all_maps__';

String _mapGroupKey(NarrativeMapEventsView view) =>
    view.mapId ?? view.groupKind.name;

String _domainLabel(NarrativeProjectDiagnosticDomain domain) =>
    switch (domain) {
      NarrativeProjectDiagnosticDomain.storyline => 'Storylines',
      NarrativeProjectDiagnosticDomain.scene => 'Scenes',
      NarrativeProjectDiagnosticDomain.event => 'Events',
      NarrativeProjectDiagnosticDomain.dialogue => 'Dialogues',
      NarrativeProjectDiagnosticDomain.cinematic => 'Cinématiques',
      NarrativeProjectDiagnosticDomain.fact => 'Facts',
      NarrativeProjectDiagnosticDomain.worldRule => 'Règles du monde',
      NarrativeProjectDiagnosticDomain.map => 'Maps',
      NarrativeProjectDiagnosticDomain.runtime => 'Readiness runtime',
    };

String _diagnosticTitle(NarrativeProjectDiagnostic diagnostic) =>
    '${_domainLabel(diagnostic.domain)} · ${diagnostic.code}';

PokeMapDiagnosticSeverity _calloutSeverity(
  NarrativeProjectDiagnosticSeverity severity,
) =>
    switch (severity) {
      NarrativeProjectDiagnosticSeverity.info => PokeMapDiagnosticSeverity.info,
      NarrativeProjectDiagnosticSeverity.warning =>
        PokeMapDiagnosticSeverity.warning,
      NarrativeProjectDiagnosticSeverity.error =>
        PokeMapDiagnosticSeverity.error,
    };

String _sourceLabel(NarrativeMapEventEntry event) {
  final category = switch (event.sourceKind) {
    NarrativeEventSourceKind.entityInteract => switch (event.sourceEntityKind) {
        MapEntityKind.npc => 'PNJ',
        MapEntityKind.sign ||
        MapEntityKind.item ||
        MapEntityKind.custom =>
          'Objet',
        MapEntityKind.spawn => 'Spawn',
        null => 'Entité de map',
      },
    NarrativeEventSourceKind.triggerEnter => 'Zone',
    NarrativeEventSourceKind.mapEnter => 'Map',
    NarrativeEventSourceKind.outcomeReceived => 'Résultat narratif',
    null => 'Source à configurer',
  };
  final label = event.sourceOwnerLabel?.trim();
  return label == null || label.isEmpty ? category : '$category · $label';
}
