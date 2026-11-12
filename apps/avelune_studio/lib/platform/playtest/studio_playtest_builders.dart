import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core_domain.dart';

import 'studio_playtest_controls.dart';

typedef StudioRuntimeBuilder = Widget Function(
  ProjectMapEntry entry,
  String revision,
  StudioPlaytestControls controls,
  VoidCallback onClose,
);

typedef StudioVisualTestBuilder = Widget Function(
  ProjectMapEntry entry,
  String revision,
  VoidCallback close,
  ValueListenable<SpatialVisualPatch> preview,
);
