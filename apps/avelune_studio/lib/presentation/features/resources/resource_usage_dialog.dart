import 'package:flutter/material.dart';
import '../../../features/resources/domain/resource_usage_port.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import 'resource_catalog.dart';
import 'resource_usage_results.dart';

enum ResourceUsagePhase {
  notAnalyzed,
  analyzing,
  complete,
  stale,
  cancelled,
  incomplete,
}

class ResourceUsageDialog extends StatefulWidget {
  const ResourceUsageDialog({
    super.key,
    this.item,
    this.target,
    this.name,
    required this.port,
    required this.changes,
    required this.dirtyOwners,
    required this.onOpen,
    required this.canOpen,
  }) : assert(item != null || (target != null && name != null));
  final ResourceItem? item;
  final ResourceUsageTarget? target;
  final String? name;
  ResourceUsageTarget get resolvedTarget =>
      target ?? ResourceUsageTarget(family: item!.kind.name, id: item!.id);
  final ResourceUsagePort port;
  final Listenable changes;
  final List<String> Function() dirtyOwners;
  final Future<bool> Function(ResourceUsageEntry entry) onOpen;
  final bool Function(ResourceUsageEntry entry) canOpen;

  @override
  State<ResourceUsageDialog> createState() => _ResourceUsageDialogState();
}

class _ResourceUsageDialogState extends State<ResourceUsageDialog> {
  ResourceUsagePhase _phase = ResourceUsagePhase.notAnalyzed;
  ResourceUsageReport? _report;
  String? _error;
  bool _working = false;
  bool _opening = false;
  bool _cancelled = false;
  int _sequence = 0;

  @override
  void initState() {
    super.initState();
    widget.changes.addListener(_changed);
  }

  @override
  void dispose() {
    _cancelled = true;
    _sequence++;
    widget.changes.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (!mounted) return;
    setState(() {
      if (_report != null && !_working) _phase = ResourceUsagePhase.stale;
    });
  }

  Future<bool> _verify() async {
    final report = _report;
    if (report == null || _working) return false;
    final sequence = _sequence;
    try {
      final current = await widget.port.isCurrent(report);
      if (!mounted || sequence != _sequence) return false;
      if (!current) setState(() => _phase = ResourceUsagePhase.stale);
      return current;
    } on Object catch (failure) {
      if (!mounted || sequence != _sequence) return false;
      setState(() {
        _phase = ResourceUsagePhase.incomplete;
        _error = '$failure';
      });
      return false;
    }
  }

  Future<void> _analyze() async {
    if (_working) return;
    final sequence = ++_sequence;
    setState(() {
      _working = true;
      _cancelled = false;
      _phase = ResourceUsagePhase.analyzing;
      _error = null;
      _report = null;
    });
    try {
      final report = await widget.port.analyze(
        widget.resolvedTarget,
        cancelled: () => _cancelled || !mounted || sequence != _sequence,
      );
      if (!mounted || _cancelled || sequence != _sequence) return;
      final current = await widget.port.isCurrent(report);
      if (!mounted || _cancelled || sequence != _sequence) return;
      setState(() {
        _report = report;
        _phase = !current
            ? ResourceUsagePhase.stale
            : report.complete && widget.dirtyOwners().isEmpty
            ? ResourceUsagePhase.complete
            : ResourceUsagePhase.incomplete;
      });
    } on ResourceUsageCancelled {
      if (mounted) setState(() => _phase = ResourceUsagePhase.cancelled);
    } on Object catch (failure) {
      if (!mounted || _cancelled || sequence != _sequence) return;
      setState(() {
        _phase = ResourceUsagePhase.incomplete;
        _error = '$failure';
      });
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  void _cancel() {
    setState(() {
      _cancelled = true;
      _phase = ResourceUsagePhase.cancelled;
    });
  }

  Future<void> _open(ResourceUsageEntry entry) async {
    if (_opening || _working) return;
    setState(() => _opening = true);
    try {
      if (!await _verify() || !mounted) return;
      if (await widget.onOpen(entry)) {
        if (mounted) Navigator.pop(context);
      } else if (mounted) {
        setState(
          () => _error =
              'Ouverture indisponible. Localisation : ${entry.location}',
        );
      }
    } on Object catch (failure) {
      if (mounted) setState(() => _error = '$failure');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dirty = widget.dirtyOwners();
    final phase = dirty.isNotEmpty && _phase == ResourceUsagePhase.complete
        ? ResourceUsagePhase.incomplete
        : _phase;
    final status = switch (phase) {
      ResourceUsagePhase.notAnalyzed => 'Non analysé',
      ResourceUsagePhase.analyzing => 'Analyse en cours',
      ResourceUsagePhase.complete => 'Complet pour la révision identifiée',
      ResourceUsagePhase.stale => 'Résultat périmé · relancez l’analyse',
      ResourceUsagePhase.cancelled =>
        _working ? 'Analyse annulée · nettoyage en cours' : 'Analyse annulée',
      ResourceUsagePhase.incomplete => 'Analyse incomplète',
    };
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 800,
          maxHeight: MediaQuery.sizeOf(context).height - 40,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Usages dans le projet',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(widget.name ?? widget.item!.name),
              const SizedBox(height: 8),
              Text(status, key: const ValueKey('resource-usage-status')),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_working) const LinearProgressIndicator(),
              const SizedBox(height: 12),
              Expanded(
                child: ResourceUsageResults(
                  report: _report,
                  error: null,
                  dirtyOwners: dirty,
                  stale: phase == ResourceUsagePhase.stale,
                  onOpen: _open,
                  canOpen: (entry) => !_opening && widget.canOpen(entry),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_working)
                    StudioButton(
                      label: 'Annuler l’analyse',
                      secondary: true,
                      onPressed: _cancelled ? null : _cancel,
                    ),
                  StudioButton(
                    label: 'Retour aux ressources',
                    secondary: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                  StudioButton(
                    key: const ValueKey('resource-usage-analyze'),
                    label: _report == null
                        ? 'Analyser les usages'
                        : 'Actualiser',
                    onPressed: _working ? null : _analyze,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
