import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/state/editor_notifier.dart';
import '../application/narrative_workspace_projection.dart';

/// Projection narrative "prête UI" basée sur le projet actif.
///
/// Ce provider évite de disperser la logique de dérivation dans plusieurs
/// widgets (gauche, centre, droite). Les trois colonnes lisent donc une même
/// vue cohérente de la donnée narrative.
final narrativeWorkspaceProjectionProvider =
    Provider<NarrativeWorkspaceProjection?>((ref) {
  final project = ref.watch(editorNotifierProvider.select((s) => s.project));
  if (project == null) {
    return null;
  }
  return buildNarrativeWorkspaceProjection(project);
});
