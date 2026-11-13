import 'package:flutter/widgets.dart';

import 'package:avelune_studio/features/project_session/application/project_opening_progress.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/rendering/contracts/map_canvas_readiness.dart';

class MapBuilderOpening {
  MapBuilderOpening(this.progress);

  final ProjectOpeningProgress? progress;

  late final readiness = MapCanvasReadiness(
    onReady: () => progress?.finish(ProjectOpeningPhase.scene),
    onFailed: (_) => progress?.fail(ProjectOpeningPhase.scene),
  );

  void loadingMap() => progress?.advance(ProjectOpeningPhase.map);

  void mapSettled({required bool failed}) {
    if (failed) progress?.fail(ProjectOpeningPhase.map);
    progress?.advance(ProjectOpeningPhase.resources);
  }

  void resourcesReady() => progress
    ?..finish(ProjectOpeningPhase.resources)
    ..start(ProjectOpeningPhase.palette);

  void resourcesFailed() => progress?.fail(ProjectOpeningPhase.resources);

  void paletteSettled({required bool failed}) => failed
      ? progress?.fail(ProjectOpeningPhase.palette)
      : progress?.finish(ProjectOpeningPhase.palette);

  void awaitScene({required bool hasMap}) {
    final progress = this.progress;
    if (progress == null) return;
    if (!hasMap) return progress.skip(ProjectOpeningPhase.scene);
    progress.start(ProjectOpeningPhase.scene);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!readiness.claimed) progress.finish(ProjectOpeningPhase.scene);
    });
  }
}
