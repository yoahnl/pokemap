import 'package:map_core/map_core_domain.dart';

import '../../events/application/behaviour/behaviour_conditions.dart';
import '../../events/application/behaviour/behaviour_line.dart';
import '../../events/application/behaviour/behaviour_reuse.dart';
import '../../events/domain/event_record_view.dart';

final class GameBehaviourSummary {
  const GameBehaviourSummary({
    required this.when,
    required this.conditions,
    required this.scene,
    required this.sceneChosen,
    required this.line,
    required this.after,
  });

  final NarrativeEventSourceKind? when;
  final BehaviourConditions conditions;
  final SceneAsset? scene;
  final bool sceneChosen;
  final bool line;
  final BehaviourAfter? after;
}

GameBehaviourSummary summarizeGameBehaviour(
  NarrativeEventRecord record,
  SceneAsset? Function(String id) scene,
) {
  final sceneId = record.sceneId;
  final found = sceneId == null ? null : scene(sceneId);
  return GameBehaviourSummary(
    when: record.source?.kind,
    conditions: readBehaviourConditions(record),
    scene: found,
    sceneChosen: sceneId != null,
    line: found != null && behaviourLineDialogueId(found) != null,
    after: readBehaviourAfter(record),
  );
}
