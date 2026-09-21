import 'dart:convert';

import 'package:map_core/map_core_domain.dart';

import '../../cinematics/application/cinematic_workspace_controller.dart';
import '../../dialogues/application/dialogue_workspace_controller.dart';
import '../../events/application/event_workspace_controller.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../../presentations/application/presentation_workspace_controller.dart';
import '../../scenes/application/scene_workspace_controller.dart';
import '../../world/application/world_workspace_controller.dart';
import '../domain/verification_port.dart';

export '../domain/verification_port.dart';

part 'verification_filters.dart';
part 'verification_graph.dart';
part 'verification_graph_model.dart';
part 'verification_report.dart';
part 'verification_run.dart';
part 'verification_snapshot.dart';

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
    this.scenes,
    this.dialogues,
    this.events,
    this.cinematics,
    this.presentations,
  });

  static const validatorVersion = 'narrative-validator-v1';

  final NarrativeWorkspaceController narrative;
  final VerificationPort port;
  final void Function() changed;
  final WorldWorkspaceController? Function()? world;
  final SceneWorkspaceController? Function()? scenes;
  final DialogueWorkspaceController? Function()? dialogues;
  final EventWorkspaceController? Function()? events;
  final CinematicWorkspaceController? Function()? cinematics;
  final PresentationWorkspaceController? Function()? presentations;

  /// Validates the active inputs of every page that owns one, through their
  /// own mechanisms, before a snapshot is taken. It publishes nothing.
  Future<bool> Function()? flushEdits;

  VerificationPhase phase = VerificationPhase.idle;
  VerificationReport? report;
  String? error;
  String? selectionNotice;
  String search = '';
  String? selectedKey;
  final severities = <NarrativeProjectDiagnosticSeverity>{};
  final domains = <NarrativeProjectDiagnosticDomain>{};

  int _generation = 0;
  bool _closed = false;
  VerificationJob? _job;

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
    return current != null && current.freshnessKey != workingRevision();
  }

  void abandon() {
    if (!running) return;
    _generation++;
    _job?.cancel();
    _job = null;
    phase = report == null
        ? VerificationPhase.cancelled
        : VerificationPhase.ready;
    changed();
  }

  void select(String? key) {
    selectedKey = key;
    selectionNotice = null;
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
    _job?.cancel();
    _job = null;
  }
}
