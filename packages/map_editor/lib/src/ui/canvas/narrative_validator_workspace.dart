import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../application/services/narrative_diagnostic_suppression_service.dart';
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
const narrativeValidatorDimensionFilterKey =
    ValueKey<String>('narrative-validator-filter-dimension');
const narrativeValidatorStorylineFilterKey =
    ValueKey<String>('narrative-validator-filter-storyline');
const narrativeValidatorAssetFilterKey =
    ValueKey<String>('narrative-validator-filter-asset');
const narrativeValidatorStatusFilterKey =
    ValueKey<String>('narrative-validator-filter-status');

enum NarrativeValidatorView { diagnostics, mapEvents }

enum _SeverityFilter { all, errors, warnings }

enum _DimensionFilter { all, structural, narrative, physical, runtime }

enum _StatusFilter { all, active, suppressed, resolved }

const _maxDiagnosticRestorationAttempts = 20;

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
    this.multidimensionalReport,
    this.suppressionSnapshot,
    this.onSuppressDiagnostic,
    this.onRemoveSuppression,
    this.initialView = NarrativeValidatorView.diagnostics,
    this.showViewTabs = true,
    this.requestedDiagnosticKey,
    this.requestedDiagnosticNonce,
    this.requestedRestorationRevision,
    this.onRestorationApplied,
  });

  final NarrativeProjectValidationReport report;
  final ValueChanged<NarrativeProjectDiagnostic>? onOpenDiagnostic;
  final ValueChanged<String>? onOpenEvent;
  final ValueChanged<String>? onOpenMap;
  final NarrativeMultidimensionalValidationReport? multidimensionalReport;
  final NarrativeDiagnosticSuppressionSnapshot? suppressionSnapshot;
  final ValueChanged<NarrativeProjectDiagnostic>? onSuppressDiagnostic;
  final ValueChanged<String>? onRemoveSuppression;
  final NarrativeValidatorView initialView;
  final bool showViewTabs;
  final String? requestedDiagnosticKey;
  final int? requestedDiagnosticNonce;
  final int? requestedRestorationRevision;
  final ValueChanged<int>? onRestorationApplied;

  @override
  State<NarrativeValidatorWorkspace> createState() =>
      _NarrativeValidatorWorkspaceState();
}

class _NarrativeValidatorWorkspaceState
    extends State<NarrativeValidatorWorkspace> {
  late NarrativeValidatorView _tab;
  _SeverityFilter _severity = _SeverityFilter.all;
  _DimensionFilter _dimension = _DimensionFilter.all;
  _StatusFilter _status = _StatusFilter.active;
  String _domain = _allDomains;
  String _map = _allMaps;
  String _storyline = _allStorylines;
  String _assetQuery = '';
  String? _selectedMapGroup;
  final ScrollController _diagnosticsScrollController = ScrollController();
  final Map<String, GlobalKey> _diagnosticAnchorKeys = <String, GlobalKey>{};
  final Map<String, FocusNode> _diagnosticFocusNodes = <String, FocusNode>{};
  Object? _lastAppliedDiagnosticRequest;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialView;
  }

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
    if (oldWidget.initialView != widget.initialView) {
      _tab = widget.initialView;
    }
    if (oldWidget.requestedDiagnosticKey != widget.requestedDiagnosticKey ||
        oldWidget.requestedDiagnosticNonce != widget.requestedDiagnosticNonce) {
      _tab = NarrativeValidatorView.diagnostics;
      _severity = _SeverityFilter.all;
      _dimension = _DimensionFilter.all;
      _status = _StatusFilter.all;
      _domain = _allDomains;
      _map = _allMaps;
      _storyline = _allStorylines;
      _assetQuery = '';
    }
    if (!identical(oldWidget.report, widget.report)) {
      final diagnosticKeys =
          widget.report.diagnostics.map((value) => value.stableKey).toSet();
      _diagnosticAnchorKeys.removeWhere(
        (key, _) => !diagnosticKeys.contains(key),
      );
      final removedFocusNodes = <FocusNode>[];
      _diagnosticFocusNodes.removeWhere((key, node) {
        final removed = !diagnosticKeys.contains(key);
        if (removed) removedFocusNodes.add(node);
        return removed;
      });
      for (final node in removedFocusNodes) {
        node.dispose();
      }
    }
  }

  @override
  void dispose() {
    _diagnosticsScrollController.dispose();
    for (final node in _diagnosticFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
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
            if (widget.multidimensionalReport case final publication?) ...[
              const SizedBox(height: 10),
              _MultidimensionalVerdicts(report: publication),
            ],
            const SizedBox(height: 10),
            if (widget.showViewTabs) ...[
              Row(
                children: [
                  Expanded(
                    child: PokeMapSegmentedTabs(
                      tabs: [
                        PokeMapSegmentedTab(
                          key: narrativeValidatorDiagnosticsTabKey,
                          label: 'Diagnostics',
                          icon: Icons.fact_check_outlined,
                          selected: _tab == NarrativeValidatorView.diagnostics,
                          onTap: () => setState(
                            () => _tab = NarrativeValidatorView.diagnostics,
                          ),
                        ),
                        PokeMapSegmentedTab(
                          key: narrativeValidatorMapEventsTabKey,
                          label: 'Events par map',
                          icon: Icons.map_outlined,
                          selected: _tab == NarrativeValidatorView.mapEvents,
                          onTap: () => setState(
                            () => _tab = NarrativeValidatorView.mapEvents,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: switch (_tab) {
                NarrativeValidatorView.diagnostics =>
                  _buildDiagnostics(context),
                NarrativeValidatorView.mapEvents => _buildMapEvents(context),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnostics(BuildContext context) {
    final requestedKey = widget.requestedDiagnosticKey?.trim();
    if (requestedKey != null &&
        requestedKey.isNotEmpty &&
        !widget.report.diagnostics.any(
          (diagnostic) => diagnostic.stableKey == requestedKey,
        )) {
      return const PokeMapEmptyState(
        key: ValueKey('narrative-validator-requested-unavailable'),
        title: 'Diagnostic introuvable',
        description:
            'La cible demandée n’existe plus dans le rapport actuel. Actualisez le Validateur pour recalculer les sources.',
        icon: Icon(Icons.search_off_outlined),
      );
    }
    final snapshot = widget.suppressionSnapshot;
    final views = snapshot?.diagnostics ??
        [
          for (final diagnostic in widget.report.diagnostics)
            NarrativeDiagnosticSuppressionView(
              diagnostic: diagnostic,
              status: NarrativeDiagnosticStatus.active,
            ),
        ];
    final normalizedAssetQuery = _assetQuery.trim().toLowerCase();
    final diagnostics = views.where((view) {
      final diagnostic = view.diagnostic;
      final matchesSeverity = switch (_severity) {
        _SeverityFilter.all => true,
        _SeverityFilter.errors =>
          diagnostic.severity == NarrativeProjectDiagnosticSeverity.error,
        _SeverityFilter.warnings =>
          diagnostic.severity == NarrativeProjectDiagnosticSeverity.warning,
      };
      final matchesStatus = switch (_status) {
        _StatusFilter.all => true,
        _StatusFilter.active =>
          view.status != NarrativeDiagnosticStatus.suppressed,
        _StatusFilter.suppressed =>
          view.status == NarrativeDiagnosticStatus.suppressed,
        _StatusFilter.resolved => false,
      };
      final matchesAsset = normalizedAssetQuery.isEmpty ||
          _diagnosticSearchText(diagnostic).contains(normalizedAssetQuery);
      return matchesSeverity &&
          matchesStatus &&
          (_dimension == _DimensionFilter.all ||
              _dimensionFor(diagnostic) == _dimension) &&
          (_domain == _allDomains || diagnostic.domain.name == _domain) &&
          (_map == _allMaps || diagnostic.mapId == _map) &&
          (_storyline == _allStorylines ||
              diagnostic.storylineId == _storyline) &&
          matchesAsset;
    }).toList();
    final resolvedSuppressions = _status == _StatusFilter.resolved
        ? snapshot?.resolvedSuppressions ??
            const <NarrativeDiagnosticSuppression>[]
        : const <NarrativeDiagnosticSuppression>[];

    final mapViews = widget.report.mapEventViews
        .where((view) => view.mapId != null)
        .toList(growable: false);
    _scheduleRequestedDiagnosticFocus(
      diagnostics.map((view) => view.diagnostic).toList(growable: false),
    );

    final storylineIds = widget.report.diagnostics
        .map((diagnostic) => diagnostic.storylineId)
        .whereType<String>()
        .where((id) => id.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();

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
              final dimension = SizedBox(
                width: 210,
                child: PokeMapDropdownField<_DimensionFilter>(
                  key: narrativeValidatorDimensionFilterKey,
                  label: 'Dimension',
                  value: _dimension,
                  items: [
                    for (final value in _DimensionFilter.values)
                      PokeMapDropdownItem(
                        value: value,
                        label: _dimensionFilterLabel(value),
                      ),
                  ],
                  onChanged: (value) => setState(() => _dimension = value),
                ),
              );
              final storyline = SizedBox(
                width: 210,
                child: PokeMapDropdownField<String>(
                  key: narrativeValidatorStorylineFilterKey,
                  label: 'Storyline',
                  value: _storyline,
                  items: [
                    const PokeMapDropdownItem(
                      value: _allStorylines,
                      label: 'Toutes les storylines',
                    ),
                    for (final id in storylineIds)
                      PokeMapDropdownItem(value: id, label: id),
                  ],
                  onChanged: (value) => setState(() => _storyline = value),
                ),
              );
              final status = SizedBox(
                width: 190,
                child: PokeMapDropdownField<_StatusFilter>(
                  key: narrativeValidatorStatusFilterKey,
                  label: 'Statut',
                  value: _status,
                  items: [
                    for (final value in _StatusFilter.values)
                      PokeMapDropdownItem(
                        value: value,
                        label: _statusFilterLabel(value),
                      ),
                  ],
                  onChanged: (value) => setState(() => _status = value),
                ),
              );
              final asset = SizedBox(
                width: 240,
                child: PokeMapTextField(
                  label: 'Asset ou chemin',
                  fieldKey: narrativeValidatorAssetFilterKey,
                  placeholder: 'ID, chemin, message…',
                  onChanged: (value) => setState(() => _assetQuery = value),
                ),
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  severity,
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      dimension,
                      domain,
                      map,
                      storyline,
                      status,
                      asset,
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: diagnostics.isEmpty && resolvedSuppressions.isEmpty
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
                    controller: _diagnosticsScrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: diagnostics.length + resolvedSuppressions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      if (index >= diagnostics.length) {
                        final suppression =
                            resolvedSuppressions[index - diagnostics.length];
                        return _ResolvedSuppressionEntry(
                          suppression: suppression,
                          onRemove: widget.onRemoveSuppression,
                        );
                      }
                      final view = diagnostics[index];
                      final diagnostic = view.diagnostic;
                      final stableKey = diagnostic.stableKey;
                      final anchorKey = _diagnosticAnchorKeys.putIfAbsent(
                        stableKey,
                        GlobalKey.new,
                      );
                      final focusNode = _diagnosticFocusNodes.putIfAbsent(
                        stableKey,
                        () => FocusNode(
                          debugLabel: 'Narrative diagnostic $stableKey',
                        ),
                      );
                      return Focus(
                        key: ValueKey<String>(
                          'narrative-validator-diagnostic-$stableKey',
                        ),
                        focusNode: focusNode,
                        child: KeyedSubtree(
                          key: anchorKey,
                          child: _DiagnosticEntry(
                            view: view,
                            onOpen: widget.onOpenDiagnostic,
                            onSuppress: widget.onSuppressDiagnostic,
                            onRemoveSuppression: widget.onRemoveSuppression,
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _scheduleRequestedDiagnosticFocus(
    List<NarrativeProjectDiagnostic> diagnostics,
  ) {
    final requestedKey = widget.requestedDiagnosticKey?.trim();
    if (requestedKey == null || requestedKey.isEmpty) return;
    if (!diagnostics
        .any((diagnostic) => diagnostic.stableKey == requestedKey)) {
      return;
    }
    final request = (requestedKey, widget.requestedDiagnosticNonce);
    if (_lastAppliedDiagnosticRequest == request) return;
    _lastAppliedDiagnosticRequest = request;
    final targetIndex = diagnostics.indexWhere(
      (diagnostic) => diagnostic.stableKey == requestedKey,
    );
    _attemptRequestedDiagnosticFocus(
      requestedKey: requestedKey,
      request: request,
      targetIndex: targetIndex,
      diagnosticCount: diagnostics.length,
      attempt: 0,
    );
  }

  void _attemptRequestedDiagnosticFocus({
    required String requestedKey,
    required Object request,
    required int targetIndex,
    required int diagnosticCount,
    required int attempt,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastAppliedDiagnosticRequest != request) return;
      final anchorContext = _diagnosticAnchorKeys[requestedKey]?.currentContext;
      if (anchorContext != null) {
        Scrollable.ensureVisible(
          anchorContext,
          alignment: 0.5,
          duration: Duration.zero,
        );
        final focusNode = _diagnosticFocusNodes[requestedKey];
        focusNode?.requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _lastAppliedDiagnosticRequest != request) return;
          if (focusNode?.hasFocus == true) {
            final restorationRevision = widget.requestedRestorationRevision;
            if (restorationRevision != null) {
              widget.onRestorationApplied?.call(restorationRevision);
            }
            return;
          }
          if (attempt < _maxDiagnosticRestorationAttempts) {
            _attemptRequestedDiagnosticFocus(
              requestedKey: requestedKey,
              request: request,
              targetIndex: targetIndex,
              diagnosticCount: diagnosticCount,
              attempt: attempt + 1,
            );
          }
        });
        return;
      }

      if (_diagnosticsScrollController.hasClients) {
        final position = _diagnosticsScrollController.position;
        final fraction =
            diagnosticCount <= 1 ? 0.0 : targetIndex / (diagnosticCount - 1);
        final estimatedOffset = position.maxScrollExtent * fraction;
        _diagnosticsScrollController.jumpTo(
          estimatedOffset
              .clamp(
                position.minScrollExtent,
                position.maxScrollExtent,
              )
              .toDouble(),
        );
      }
      if (attempt < _maxDiagnosticRestorationAttempts) {
        _attemptRequestedDiagnosticFocus(
          requestedKey: requestedKey,
          request: request,
          targetIndex: targetIndex,
          diagnosticCount: diagnosticCount,
          attempt: attempt + 1,
        );
      }
    });
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

class _MultidimensionalVerdicts extends StatelessWidget {
  const _MultidimensionalVerdicts({required this.report});

  final NarrativeMultidimensionalValidationReport report;

  @override
  Widget build(BuildContext context) {
    final dimensions = <(String, NarrativeValidationDimensionResult, IconData)>[
      ('Structure', report.structurallyValid, Icons.account_tree_outlined),
      ('Solvabilité', report.narrativelySolvable, Icons.route_outlined),
      ('Atteignabilité', report.physicallyReachable, Icons.map_outlined),
      ('Smoke runtime', report.runtimeSmokeVerified, Icons.play_circle_outline),
    ];
    return PokeMapPanel(
      padding: const EdgeInsets.all(10),
      header: const Padding(
        padding: EdgeInsets.fromLTRB(10, 8, 10, 0),
        child: PokeMapSectionHeader(
          title: 'Preuve de jouabilité · 4 dimensions',
          description:
              'Chaque verdict reste indépendant ; non exécuté ou indéterminé ne vaut jamais réussite.',
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (label, dimension, icon) in dimensions)
            SizedBox(
              width: 245,
              child: PokeMapCard(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          icon,
                          size: 16,
                          color: context.pokeMapColors.textSecondary,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              color: context.pokeMapColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        PokeMapBadge(
                          label: _validationStatusLabel(dimension.status),
                          variant:
                              _validationStatusBadgeVariant(dimension.status),
                        ),
                      ],
                    ),
                    if (dimension.evidenceRefs.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        'Preuve · ${dimension.evidenceRefs.join(' · ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pokeMapColors.textMuted,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (dimension.limitations.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        'Limite · ${dimension.limitations.join(' · ')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.pokeMapColors.textSecondary,
                          fontSize: 10,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiagnosticEntry extends StatelessWidget {
  const _DiagnosticEntry({
    required this.view,
    required this.onOpen,
    required this.onSuppress,
    required this.onRemoveSuppression,
  });

  final NarrativeDiagnosticSuppressionView view;
  final ValueChanged<NarrativeProjectDiagnostic>? onOpen;
  final ValueChanged<NarrativeProjectDiagnostic>? onSuppress;
  final ValueChanged<String>? onRemoveSuppression;

  @override
  Widget build(BuildContext context) {
    final diagnostic = view.diagnostic;
    final suppression = view.suppression;
    return PokeMapCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapDiagnosticCallout(
            severity: _calloutSeverity(diagnostic.severity),
            title: _diagnosticTitle(diagnostic),
            message: diagnostic.message,
            actionLabel: onOpen == null ? null : 'Ouvrir la source',
            onAction: onOpen == null ? null : () => onOpen!(diagnostic),
            semanticLabel:
                '${_domainLabel(diagnostic.domain)}. ${diagnostic.message}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              PokeMapBadge(
                label: _dimensionFilterLabel(_dimensionFor(diagnostic)),
                variant: PokeMapBadgeVariant.info,
              ),
              PokeMapBadge(
                label: _diagnosticStatusLabel(view.status),
                variant: _diagnosticStatusBadgeVariant(view.status),
              ),
              if (diagnostic.mapId case final mapId?)
                PokeMapBadge(
                  label: 'Map · $mapId',
                  variant: PokeMapBadgeVariant.neutral,
                ),
              if (diagnostic.storylineId case final storylineId?)
                PokeMapBadge(
                  label: 'Storyline · $storylineId',
                  variant: PokeMapBadgeVariant.narrative,
                ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            'Chemin exact · ${diagnostic.path}',
            style: TextStyle(
              color: context.pokeMapColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (diagnostic.suggestedFixLabel case final fix?) ...[
            const SizedBox(height: 4),
            Text(
              'Décision requise · $fix Ouvrez la source pour choisir sans mutation automatique.',
              style: TextStyle(
                color: context.pokeMapColors.textSecondary,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ],
          if (suppression != null) ...[
            const SizedBox(height: 4),
            Text(
              'Suppression · ${suppression.author} · ${suppression.reason}',
              style: TextStyle(
                color: context.pokeMapColors.textSecondary,
                fontSize: 10,
                height: 1.35,
              ),
            ),
          ],
          if (diagnostic.severity != NarrativeProjectDiagnosticSeverity.error &&
              view.status != NarrativeDiagnosticStatus.suppressed &&
              onSuppress != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: PokeMapButton(
                key: ValueKey<String>(
                  'narrative-validator-suppress-${diagnostic.stableKey}',
                ),
                onPressed: () => onSuppress!(diagnostic),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.ghost,
                child: const Text('Masquer avec justification'),
              ),
            ),
          ],
          if (view.status == NarrativeDiagnosticStatus.suppressed &&
              onRemoveSuppression != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: PokeMapButton(
                key: ValueKey<String>(
                  'narrative-validator-unsuppress-${diagnostic.stableKey}',
                ),
                onPressed: () => onRemoveSuppression!(diagnostic.stableKey),
                size: PokeMapButtonSize.small,
                variant: PokeMapButtonVariant.ghost,
                child: const Text('Réactiver le diagnostic'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ResolvedSuppressionEntry extends StatelessWidget {
  const _ResolvedSuppressionEntry({
    required this.suppression,
    required this.onRemove,
  });

  final NarrativeDiagnosticSuppression suppression;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    return PokeMapDiagnosticCallout(
      severity: PokeMapDiagnosticSeverity.info,
      title: 'Diagnostic résolu',
      message:
          '${suppression.reason} · ${suppression.author} · ${suppression.diagnosticId}',
      actionLabel: onRemove == null ? null : 'Nettoyer la suppression',
      onAction:
          onRemove == null ? null : () => onRemove!(suppression.diagnosticId),
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
const _allStorylines = '__all_storylines__';

_DimensionFilter _dimensionFor(NarrativeProjectDiagnostic diagnostic) {
  if (diagnostic.domain == NarrativeProjectDiagnosticDomain.runtime ||
      diagnostic.code.toLowerCase().contains('runtime')) {
    return _DimensionFilter.runtime;
  }
  if (diagnostic.code.toLowerCase().contains('physical') ||
      diagnostic.code.toLowerCase().contains('reachablecell') ||
      const {
        'missingStartMap',
        'invalidStartSpawn',
        'missingSourceMap',
        'missingSourceTarget',
        'explorationBudgetExceeded',
        'permanentlyBlocked',
      }.contains(diagnostic.code)) {
    return _DimensionFilter.physical;
  }
  if (diagnostic.code.startsWith('narrative') ||
      diagnostic.code.startsWith('oneShot') ||
      diagnostic.code.contains('NeverCompleted') ||
      diagnostic.code.contains('NeverProduced')) {
    return _DimensionFilter.narrative;
  }
  return _DimensionFilter.structural;
}

String _dimensionFilterLabel(_DimensionFilter value) => switch (value) {
      _DimensionFilter.all => 'Toutes les dimensions',
      _DimensionFilter.structural => 'Structure',
      _DimensionFilter.narrative => 'Solvabilité narrative',
      _DimensionFilter.physical => 'Atteignabilité physique',
      _DimensionFilter.runtime => 'Smoke runtime',
    };

String _statusFilterLabel(_StatusFilter value) => switch (value) {
      _StatusFilter.all => 'Tous les statuts',
      _StatusFilter.active => 'Actifs',
      _StatusFilter.suppressed => 'Masqués',
      _StatusFilter.resolved => 'Résolus',
    };

String _diagnosticStatusLabel(NarrativeDiagnosticStatus value) =>
    switch (value) {
      NarrativeDiagnosticStatus.active => 'Actif',
      NarrativeDiagnosticStatus.suppressed => 'Masqué',
      NarrativeDiagnosticStatus.expiredSuppression => 'Masquage expiré',
      NarrativeDiagnosticStatus.staleSuppression => 'Masquage obsolète',
    };

PokeMapBadgeVariant _diagnosticStatusBadgeVariant(
  NarrativeDiagnosticStatus value,
) =>
    switch (value) {
      NarrativeDiagnosticStatus.active => PokeMapBadgeVariant.error,
      NarrativeDiagnosticStatus.suppressed => PokeMapBadgeVariant.neutral,
      NarrativeDiagnosticStatus.expiredSuppression =>
        PokeMapBadgeVariant.warning,
      NarrativeDiagnosticStatus.staleSuppression => PokeMapBadgeVariant.warning,
    };

String _validationStatusLabel(NarrativeValidationStatus value) =>
    switch (value) {
      NarrativeValidationStatus.pass => 'Réussi',
      NarrativeValidationStatus.fail => 'Échec',
      NarrativeValidationStatus.indeterminate => 'Indéterminé',
      NarrativeValidationStatus.notRun => 'Non exécuté',
    };

PokeMapBadgeVariant _validationStatusBadgeVariant(
  NarrativeValidationStatus value,
) =>
    switch (value) {
      NarrativeValidationStatus.pass => PokeMapBadgeVariant.success,
      NarrativeValidationStatus.fail => PokeMapBadgeVariant.error,
      NarrativeValidationStatus.indeterminate => PokeMapBadgeVariant.warning,
      NarrativeValidationStatus.notRun => PokeMapBadgeVariant.neutral,
    };

String _diagnosticSearchText(NarrativeProjectDiagnostic diagnostic) =>
    <String?>[
      diagnostic.code,
      diagnostic.message,
      diagnostic.path,
      diagnostic.mapId,
      diagnostic.eventId,
      diagnostic.sceneId,
      diagnostic.dialogueId,
      diagnostic.cinematicId,
      diagnostic.storylineId,
      diagnostic.chapterId,
      diagnostic.stepId,
      diagnostic.factId,
      diagnostic.worldRuleId,
    ].whereType<String>().join(' ').toLowerCase();

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
