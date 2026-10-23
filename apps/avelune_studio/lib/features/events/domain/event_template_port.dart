import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/domain/map_workspace_port.dart';
import '../../narrative/domain/narrative_port.dart';

abstract interface class EventTemplatePort {
  Future<NarrativePublicationReceipt> publishTemplate({
    required MapWorkspaceDocument base,
    required StandardEventTemplateSpec spec,
    required ProjectManifest project,
    required List<MapData> maps,
  });
}
