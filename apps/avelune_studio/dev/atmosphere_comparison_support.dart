import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import 'save_disk_trace.dart';

SpatialAtmosphereProfile comparisonAtmosphereProfile(Map<String, dynamic> raw) {
  return SpatialAtmosphereProfile(
    waterTargets: [
      for (final id in (raw['waterTilesets'] as List<dynamic>))
        SpatialAtmosphereTarget.groundTileset(id as String),
    ],
    windows: [
      for (final window in (raw['windows'] as List<dynamic>))
        SpatialWindowGlow(
          target: SpatialAtmosphereTarget(
            instanceId: window['instanceId'] as String,
            materialName: window['materialName'] as String,
          ),
          uvRects: [
            for (final r in window['uvRects'] as List<dynamic>)
              Rect.fromLTRB(
                (r[0] as num).toDouble(),
                (r[1] as num).toDouble(),
                (r[2] as num).toDouble(),
                (r[3] as num).toDouble(),
              ),
          ],
          color: Color(0xff000000 | (window['colorRgb'] as int)),
          strength: (window['strength'] as num).toDouble(),
        ),
    ],
    fireflyZones: [
      for (final zone in raw['fireflyZones'] as List<dynamic>)
        SpatialFireflyZone(
          bounds: Model3dBounds.fromJson(
            Map<String, dynamic>.from(zone['bounds'] as Map),
          ),
          count: zone['count'] as int,
          seed: (zone['seed'] as int?) ?? 7,
        ),
    ],
  );
}

class AtmosphereToggleProbe {
  AtmosphereToggleProbe(this.controller, this.trace, {this.counters}) {
    controller.addListener(_changed);
  }
  final SpatialSceneController controller;
  final SaveDiskTrace trace;
  final Map<String, int> Function()? counters;
  Map<String, int>? _beforeCounters;
  final _pointerWatch = Stopwatch();
  void _pointer(PointerEvent event) {
    if (_armed && event is PointerDownEvent) _pointerWatch.start();
  }

  bool _armed = false;
  Map<String, Object?>? result;

  Map<String, Object?> get state => {
    'water': controller.waterAnimated,
    'windows': controller.windowsLit,
    'fireflies': controller.fireflies,
    'halos': controller.halosEnabled,
    'fog': controller.depthFogEnabled,
  };

  void arm() {
    result = null;
    _armed = true;
    _beforeCounters = counters?.call();
    _pointerWatch.reset();
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_pointer);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_pointer);
    trace.arm();
  }

  void _changed() {
    if (!_armed) return;
    _armed = false;
    final watch = Stopwatch()..start();
    final changed = state;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(_pointer);
      trace.armed = false;
      result = {
        'state': changed,
        'stateChangeToFrameUs': watch.elapsedMicroseconds,
        'pointerDownToFrameUs': _pointerWatch.isRunning
            ? _pointerWatch.elapsedMicroseconds
            : null,
        'disk': trace.snapshot(),
        'beforeCounters': _beforeCounters,
        'afterCounters': counters?.call(),
      };
    });
    WidgetsBinding.instance.scheduleFrame();
  }
}
