import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring_presentation_editing.dart';

export 'package:map_authoring/map_authoring_presentation_editing.dart';

class PresentationTimelineEditingListenable implements Listenable {
  const PresentationTimelineEditingListenable(this.controller);

  final PresentationTimelineEditingController controller;

  @override
  void addListener(VoidCallback listener) => controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      controller.removeListener(listener);
}
