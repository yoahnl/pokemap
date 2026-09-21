part of 'verification_workspace_controller.dart';

extension VerificationFilters on VerificationWorkspaceController {
  /// The diagnostics the filters keep, errors first and in a stable order so
  /// two runs of the same report never reshuffle the list.
  List<NarrativeProjectDiagnostic> get visible {
    final current = report;
    if (current == null) return const [];
    final needle = search.trim().toLowerCase();
    final kept = <(int, int, NarrativeProjectDiagnostic)>[];
    for (var index = 0; index < current.diagnostics.length; index++) {
      final item = current.diagnostics[index];
      if (severities.isNotEmpty && !severities.contains(item.severity)) {
        continue;
      }
      if (domains.isNotEmpty && !domains.contains(item.domain)) continue;
      if (needle.isNotEmpty && !_matches(current, item, needle)) continue;
      kept.add((_rank(item.severity), index, item));
    }
    kept.sort((left, right) {
      final bySeverity = left.$1.compareTo(right.$1);
      return bySeverity != 0 ? bySeverity : left.$2.compareTo(right.$2);
    });
    return [for (final entry in kept) entry.$3];
  }

  int _rank(NarrativeProjectDiagnosticSeverity severity) => switch (severity) {
    NarrativeProjectDiagnosticSeverity.error => 0,
    NarrativeProjectDiagnosticSeverity.warning => 1,
    NarrativeProjectDiagnosticSeverity.info => 2,
  };

  bool _matches(
    VerificationReport current,
    NarrativeProjectDiagnostic item,
    String needle,
  ) =>
      item.message.toLowerCase().contains(needle) ||
      item.code.toLowerCase().contains(needle) ||
      item.path.toLowerCase().contains(needle) ||
      current.labelFor(item).toLowerCase().contains(needle) ||
      item.stableKey.toLowerCase().contains(needle);

  NarrativeProjectDiagnostic? get selected {
    final key = selectedKey;
    if (key == null) return null;
    return report?.diagnostics
        .where((item) => item.stableKey == key)
        .firstOrNull;
  }

  /// The selection can survive a filter that hides it; the page says so
  /// instead of letting an action point at an invisible element.
  bool get selectionHidden =>
      selected != null && !visible.any((item) => item.stableKey == selectedKey);

  /// Domains the report actually produced, so a filter never offers a family
  /// the control never looked at.
  List<NarrativeProjectDiagnosticDomain> get presentDomains {
    final current = report;
    if (current == null) return const [];
    return [
      for (final domain in NarrativeProjectDiagnosticDomain.values)
        if (current.countIn(domain) > 0) domain,
    ];
  }

  void setSearch(String value) {
    if (search == value) return;
    search = value;
    changed();
  }

  void toggleSeverity(NarrativeProjectDiagnosticSeverity severity) {
    severities.contains(severity)
        ? severities.remove(severity)
        : severities.add(severity);
    changed();
  }

  void toggleDomain(NarrativeProjectDiagnosticDomain domain) {
    domains.contains(domain) ? domains.remove(domain) : domains.add(domain);
    changed();
  }

  void clearFilters() {
    if (search.isEmpty && severities.isEmpty && domains.isEmpty) return;
    search = '';
    severities.clear();
    domains.clear();
    changed();
  }

  bool get filtered =>
      search.trim().isNotEmpty || severities.isNotEmpty || domains.isNotEmpty;
}
