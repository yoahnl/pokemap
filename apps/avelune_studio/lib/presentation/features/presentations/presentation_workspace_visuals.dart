import 'presentation_scenario_preview.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_frame_geometry.dart';
import '../../../features/presentations/domain/presentation_port.dart';
import '../../../features/presentations/application/presentation_preview_transport.dart';

abstract interface class PresentationWorkspaceVisuals implements Listenable {
  Future<void> prepare(
    PresentationCinematicAsset asset, {
    required bool portrait,
  });
  Future<void> get settled;
  String? get diagnostic;
  bool get diagnosticIsFailure;
  bool get loading;
  void bindTransport(PresentationPreviewTransport transport);
  void setOrientation(bool portrait);
  Future<void> release();
  Future<void> close();
  Future<PresentationScenarioPreview> createScenarioPreview({
    required ProjectManifest project,
    required String sceneId,
    required PresentationCinematicAsset asset,
    bool portrait = false,
    bool reducedMotion = false,
  });
  Widget frame({
    required PresentationCinematicAsset asset,
    required PresentationFrame frame,
    required bool portrait,
    PresentationFrameGeometryController? geometry,
    bool reduceMotion = false,
    bool reduceFlashes = false,
    bool showCaptions = true,
  });
}

abstract interface class PresentationMediaWorkspaceVisuals {
  PresentationWorkspaceVisuals createPresentationVisuals({
    required String revision,
    required ProjectMediaCatalog catalog,
    List<PresentationStagedMedia> imports = const [],
  });
}
