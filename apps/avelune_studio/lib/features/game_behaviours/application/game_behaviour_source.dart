import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/application/map_story_elements.dart';

abstract interface class GameBehaviourSource {
  NarrativeEventRegistry? get registry;

  List<ProjectMapEntry> get maps;

  List<SceneAsset> get scenes;

  Object? get revision;

  bool touched(String id);

  String? elementName(String mapId, MapStoryElementTarget target, String id);
}
