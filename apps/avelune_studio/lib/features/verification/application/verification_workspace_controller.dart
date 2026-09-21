import 'dart:convert';

import 'package:map_core/map_core_domain.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../../world/application/world_workspace_controller.dart';
import '../domain/verification_port.dart';

export '../domain/verification_port.dart';

part 'verification_filters.dart';
part 'verification_graph.dart';
part 'verification_graph_model.dart';
part 'verification_report.dart';
part 'verification_run.dart';

/// Narrative verification of one project.
///
/// Nothing is computed until the author asks for it: opening the page, moving
/// a filter or selecting a diagnostic never starts a control, and the
/// controller never writes to the project.
class VerificationWorkspaceController {
  VerificationWorkspaceController(
    this.narrative,
    this.port, {
    required this.changed,
    this.world,
  });

  static const validatorVersion = 'narrative-validator-v1';

  final NarrativeWorkspaceController narrative;
  final VerificationPort port;
  final void Function() changed;
  final WorldWorkspaceController? Function()? world;

  /// Validates the active inputs of the pages that hold one, through their own
  /// mechanisms, before a snapshot is taken.
  bool Function()? flushEdits;

  VerificationPhase phase = VerificationPhase.idle;
  VerificationReport? report;
  String? error;
  String search = '';
  String? selectedKey;
  final severities = <NarrativeProjectDiagnosticSeverity>{};
  final domains = <NarrativeProjectDiagnosticDomain>{};

  int _generation = 0;
  bool _closed = false;

  ProjectManifest get project => narrative.project;
  bool get running =>
      phase == VerificationPhase.reading ||
      phase == VerificationPhase.analysing;

  /// True when the working version moved since the report was produced.
  ///
  /// Only changes made through the Studio are seen here. A file edited outside
  /// it is noticed at the next explicit control, which the report states.
  bool get stale {
    final current = report;
    return current != null && current.freshnessKey != _freshnessKey();
  }

  String _freshnessKey() {
    final owner = world?.call();
    final documents = narrative.workspace.documents.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return [
      identityHashCode(project),
      for (final fact in narrative.pendingFacts.values)
        jsonEncode(fact.toJson()),
      for (final story in narrative.pendingStories.values)
        jsonEncode(story.toJson()),
      ...narrative.pendingStoryDeletions,
      if (owner != null)
        for (final draft in owner.pendingRules.values) draft.signature,
      for (final entry in documents)
        '${entry.key}:${entry.value.dirty}:${entry.value.undoCount}',
      for (final session in narrative.sessions.entries)
        if (session.value.dirty) 'session:${session.key}',
    ].join('|');
  }

  void abandon() {
    if (!running) return;
    _generation++;
    phase = report == null
        ? VerificationPhase.cancelled
        : VerificationPhase.ready;
    changed();
  }

  void select(String? key) {
    selectedKey = key;
    changed();
  }

  bool _fail(Object failure) {
    if (!_closed) {
      error = failure.toString();
      phase = VerificationPhase.failed;
      changed();
    }
    return false;
  }

  void dispose() {
    _closed = true;
    _generation++;
  }
}
