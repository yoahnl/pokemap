import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../presentation/shared/widgets/feedback/studio_badge.dart';

class StudioPlaytestPerformance extends StatefulWidget {
  const StudioPlaytestPerformance({super.key, required this.active});

  final bool active;

  @override
  State<StudioPlaytestPerformance> createState() =>
      _StudioPlaytestPerformanceState();
}

class _StudioPlaytestPerformanceState extends State<StudioPlaytestPerformance> {
  final _frames = Queue<FrameTiming>();
  int? _lastPublication;
  String _label = 'FPS —';
  StudioTone _tone = StudioTone.neutral;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_observe);
  }

  @override
  void didUpdateWidget(StudioPlaytestPerformance oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _frames.clear();
      _lastPublication = null;
      _label = 'FPS —';
      _tone = StudioTone.neutral;
    }
  }

  void _observe(List<FrameTiming> timings) {
    if (!mounted || !widget.active) return;
    for (final timing in timings) {
      final timestamp = timing.timestampInMicroseconds(FramePhase.rasterFinish);
      if (_frames.isNotEmpty &&
          timestamp <=
              _frames.last.timestampInMicroseconds(FramePhase.rasterFinish)) {
        continue;
      }
      _frames.add(timing);
      while (_frames.length > 2 &&
          _frames.first.timestampInMicroseconds(FramePhase.rasterFinish) <
              timestamp - 2000000) {
        _frames.removeFirst();
      }
    }
    if (_frames.length < 2) return;
    final last = _frames.last.timestampInMicroseconds(FramePhase.rasterFinish);
    if (_lastPublication != null && last - _lastPublication! < 500000) return;
    _lastPublication = last;
    final first = _frames.first.timestampInMicroseconds(
      FramePhase.rasterFinish,
    );
    final fps = (_frames.length - 1) * 1000000 / (last - first);
    final build =
        _frames.fold<int>(
          0,
          (total, frame) => total + frame.buildDuration.inMicroseconds,
        ) /
        _frames.length /
        1000;
    final raster =
        _frames.fold<int>(
          0,
          (total, frame) => total + frame.rasterDuration.inMicroseconds,
        ) /
        _frames.length /
        1000;
    setState(() {
      _label =
          'FPS ${fps.toStringAsFixed(1)} · UI ${build.toStringAsFixed(1)} ms · rendu ${raster.toStringAsFixed(1)} ms';
      _tone = fps < 15
          ? StudioTone.danger
          : fps < 30
          ? StudioTone.warning
          : StudioTone.neutral;
    });
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_observe);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Images réellement calculées par Flutter. UI : calcul de l’image ; rendu : traitement par le moteur graphique. Moyenne sur les deux dernières secondes.',
    child: StudioBadge(
      _label,
      key: const ValueKey('playtest-fps'),
      tone: _tone,
      icon: Icons.speed,
    ),
  );
}
