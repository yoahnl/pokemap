part of 'presentation_timeline.dart';

extension _PresentationTimelineRuler on _PresentationTimelineState {
  void scrub(double dx) {
    widget.transport.pause();
    widget.transport.seek(
      (dx / scale * 1000000).round().clamp(0, widget.asset.durationUs),
    );
  }

  Widget ruler() => Positioned(
    left: 0,
    top: 0,
    right: 0,
    height: 26,
    child: MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        key: const ValueKey('presentation-timeline-ruler'),
        behavior: HitTestBehavior.opaque,
        onTapDown: (event) => scrub(event.localPosition.dx),
        onHorizontalDragStart: (event) => scrub(event.localPosition.dx),
        onHorizontalDragUpdate: (event) => scrub(event.localPosition.dx),
        child: Stack(
          children: [
            for (int i = 0; i <= widget.asset.durationUs ~/ 1000000; i++)
              Positioned(
                left: i * scale,
                child: Text('${i}s', style: const TextStyle(fontSize: 10)),
              ),
          ],
        ),
      ),
    ),
  );

  Widget playhead() => AnimatedBuilder(
    animation: PresentationTransportListenable(widget.transport),
    builder: (context, _) => Positioned(
      left: x(widget.transport.timeUs) - 5,
      top: 0,
      bottom: 0,
      width: 11,
      child: IgnorePointer(
        child: Column(
          children: [
            Container(
              width: 11,
              height: 8,
              decoration: BoxDecoration(
                color: StudioColors.of(context).canvasSelection,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(3),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: 1,
                  color: StudioColors.of(context).canvasSelection,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
