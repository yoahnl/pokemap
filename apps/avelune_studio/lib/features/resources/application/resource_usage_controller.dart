import '../domain/resource_usage_port.dart';
import 'resource_catalog.dart';

enum ResourceUsagePhase {
  notAnalyzed,
  analyzing,
  complete,
  stale,
  cancelled,
  incomplete,
}

ResourceUsageTarget resourceUsageTargetFor(ResourceItem item) =>
    ResourceUsageTarget(
      family: switch (item.canonicalKind) {
        'model3d' => 'models3d',
        'environmentPreset' => 'environments',
        'borderBlueprint' => 'borders',
        _ => item.kind.name,
      },
      id: item.id,
    );

class ResourceUsageController {
  ResourceUsageController({
    required this.target,
    required this.port,
    required this.dirtyOwners,
    required this.openOwner,
    required this.canOpenOwner,
    required this.changed,
    this.replace,
  });

  final ResourceUsageTarget target;
  final ResourceUsagePort port;
  final List<String> Function() dirtyOwners;
  final Future<bool> Function(ResourceUsageEntry) openOwner;
  final bool Function(ResourceUsageEntry) canOpenOwner;
  final Future<String?> Function(ResourceUsageReport)? replace;
  final void Function() changed;
  ResourceUsagePhase _phase = ResourceUsagePhase.notAnalyzed;
  ResourceUsageReport? _report;
  String? _error, _notice;
  bool _working = false, _opening = false, _cancelled = false, _closed = false;
  int _sequence = 0;

  ResourceUsagePhase get phase =>
      dirtyOwners().isNotEmpty && _phase == ResourceUsagePhase.complete
      ? ResourceUsagePhase.incomplete
      : _phase;
  ResourceUsageReport? get report => _report;
  String? get error => _error;
  String? get notice => _notice;
  bool get working => _working;
  bool get opening => _opening;
  bool get cancelled => _cancelled;
  bool get replaceable =>
      replace != null && const {'decors', 'models3d'}.contains(target.family);
  bool get canReplace =>
      !_closed &&
      replaceable &&
      !_working &&
      !_opening &&
      phase == ResourceUsagePhase.complete &&
      (_report?.entries.isNotEmpty ?? false);

  bool canOpen(ResourceUsageEntry entry) =>
      !_closed &&
      !_working &&
      !_opening &&
      phase != ResourceUsagePhase.stale &&
      canOpenOwner(entry);

  void _notify() {
    if (!_closed) changed();
  }

  void invalidate() {
    if (_closed) return;
    if (_report != null && !_working) {
      _sequence++;
      _phase = ResourceUsagePhase.stale;
    }
    _notify();
  }

  Future<bool> _verify() async {
    final report = _report;
    if (_closed || report == null || _working) return false;
    final sequence = _sequence;
    try {
      final current = await port.isCurrent(report);
      if (_closed || sequence != _sequence) return false;
      if (!current) {
        _phase = ResourceUsagePhase.stale;
        _notify();
      }
      return current;
    } on Object catch (failure) {
      if (_closed || sequence != _sequence) return false;
      _phase = ResourceUsagePhase.incomplete;
      _error = '$failure';
      _notify();
      return false;
    }
  }

  Future<void> analyze() async {
    if (_closed || _working) return;
    final sequence = ++_sequence;
    _working = true;
    _cancelled = false;
    _phase = ResourceUsagePhase.analyzing;
    _error = null;
    _report = null;
    _notify();
    try {
      final report = await port.analyze(
        target,
        cancelled: () => _cancelled || _closed || sequence != _sequence,
      );
      if (_closed || _cancelled || sequence != _sequence) return;
      final current = await port.isCurrent(report);
      if (_closed || _cancelled || sequence != _sequence) return;
      _report = report;
      _phase = !current
          ? ResourceUsagePhase.stale
          : report.complete && dirtyOwners().isEmpty
          ? ResourceUsagePhase.complete
          : ResourceUsagePhase.incomplete;
    } on ResourceUsageCancelled {
      if (!_closed) _phase = ResourceUsagePhase.cancelled;
    } on Object catch (failure) {
      if (_closed || _cancelled || sequence != _sequence) return;
      _phase = ResourceUsagePhase.incomplete;
      _error = '$failure';
    } finally {
      _working = false;
      _notify();
    }
  }

  void cancel() {
    if (_closed || !_working) return;
    _cancelled = true;
    _phase = ResourceUsagePhase.cancelled;
    _notify();
  }

  Future<void> replaceUsages() async {
    if (!canReplace) return;
    final report = _report!;
    _opening = true;
    _notify();
    try {
      if (!await _verify() || _closed) return;
      final summary = await replace!(report);
      if (!_closed && summary != null) {
        _notice = summary;
        _phase = ResourceUsagePhase.stale;
      }
    } on Object catch (failure) {
      if (!_closed) _error = '$failure';
    } finally {
      _opening = false;
      _notify();
    }
  }

  Future<bool> open(ResourceUsageEntry entry) async {
    if (!canOpen(entry)) return false;
    _opening = true;
    _notify();
    try {
      if (!await _verify() || _closed) return false;
      final opened = await openOwner(entry);
      if (_closed) return false;
      if (!opened) {
        _error = 'Ouverture indisponible. Localisation : ${entry.location}';
      }
      return opened;
    } on Object catch (failure) {
      if (!_closed) _error = '$failure';
      return false;
    } finally {
      _opening = false;
      _notify();
    }
  }

  void dispose() {
    _closed = true;
    _cancelled = true;
    _sequence++;
  }
}
