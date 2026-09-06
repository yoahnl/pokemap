import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

void registerMenuPerformanceProbe() {
  final frames = <List<int>>[];
  final elapsed = Stopwatch();
  var recording = false;
  var droppedFrames = 0;
  SchedulerBinding.instance.addTimingsCallback((timings) {
    if (!recording) return;
    for (final timing in timings) {
      if (frames.length == 20000) {
        droppedFrames++;
        continue;
      }
      frames.add([
        timing.buildDuration.inMicroseconds,
        timing.rasterDuration.inMicroseconds,
      ]);
    }
  });
  registerMarionetteExtension(
    name: 'player.qaPerformance',
    description: 'Records bounded frame timings and process/image-cache usage.',
    callback: (params) async {
      final operation = params['operation'] ?? 'read';
      if (!const {'start', 'read', 'stop'}.contains(operation)) {
        throw ArgumentError.value(operation, 'operation');
      }
      if (operation == 'start') {
        frames.clear();
        droppedFrames = 0;
        elapsed
          ..reset()
          ..start();
        recording = true;
      } else if (operation == 'stop') {
        recording = false;
        elapsed.stop();
      }
      final view = PlatformDispatcher.instance.views.first;
      final cache = PaintingBinding.instance.imageCache;
      return MarionetteExtensionResult.success({
        'mode': kProfileMode ? 'profile' : (kReleaseMode ? 'release' : 'debug'),
        'revision': const String.fromEnvironment('MENU_QA_REVISION'),
        'recording': recording,
        'elapsedMicros': elapsed.elapsedMicroseconds,
        'framesBuildRasterMicros': frames.map((frame) => [...frame]).toList(),
        'droppedFrames': droppedFrames,
        'rssBytes': ProcessInfo.currentRss,
        'maxRssBytes': ProcessInfo.maxRss,
        'imageCacheBytes': cache.currentSizeBytes,
        'imageCacheEntries': cache.currentSize,
        'imageCacheLiveEntries': cache.liveImageCount,
        'imageCachePendingEntries': cache.pendingImageCount,
        'devicePixelRatio': view.devicePixelRatio,
        'physicalWidth': view.physicalSize.width,
        'physicalHeight': view.physicalSize.height,
      });
    },
  );
}
