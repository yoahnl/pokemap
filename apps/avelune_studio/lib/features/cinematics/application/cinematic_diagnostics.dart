import 'package:map_core/map_core_domain.dart';

final class CinematicDiagnosticGroup {
  CinematicDiagnosticGroup(this.message, this.blocking);
  final String message;
  final bool blocking;
  int count = 0;
  final stepIds = <String>[];
  final actorIds = <String>[];
}

List<CinematicDiagnosticGroup> groupCinematicDiagnostics(
  Iterable<CinematicPreviewPlaybackDiagnostic> diagnostics,
) {
  final groups = <(bool, String), CinematicDiagnosticGroup>{};
  for (final diagnostic in diagnostics) {
    final group = groups.putIfAbsent(
      (diagnostic.blocking, diagnostic.message),
      () => CinematicDiagnosticGroup(diagnostic.message, diagnostic.blocking),
    )..count += 1;
    if (diagnostic.stepId case final id? when !group.stepIds.contains(id)) {
      group.stepIds.add(id);
    }
    if (diagnostic.actorId case final id? when !group.actorIds.contains(id)) {
      group.actorIds.add(id);
    }
  }
  return [
    ...groups.values.where((group) => group.blocking),
    ...groups.values.where((group) => !group.blocking),
  ];
}

String cinematicDiagnosticSummary(List<CinematicDiagnosticGroup> groups) {
  final problems = groups.where((group) => group.blocking).length;
  final warnings = groups.length - problems;
  String count(int value, String one, String many) =>
      '$value ${value > 1 ? many : one}';
  if (problems == 0) {
    return 'Lecture possible : ${count(warnings, 'avertissement', 'avertissements')} sans effet bloquant.';
  }
  final parts = [
    'Lecture possible mais incomplète : ${count(problems, 'problème à corriger', 'problèmes à corriger')}',
    if (warnings > 0) count(warnings, 'avertissement', 'avertissements'),
  ];
  return '${parts.join(', ')}.';
}
