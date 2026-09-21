part of 'presentation_timeline.dart';

extension _PresentationTimelineClip on _PresentationTimelineState {
  Color tint(BuildContext context, PresentationClip clip) {
    final accents = StudioColors.of(context);
    return switch (clip) {
      PresentationTextClip() => accents.featureAccent,
      PresentationAudioClip() => accents.success,
      PresentationMarkerClip() => accents.warning,
      PresentationCaptionClip() => Theme.of(context).colorScheme.tertiary,
      _ => accents.canvasSelection,
    };
  }

  Widget bar(BuildContext context, PresentationClip source, int trackIndex) {
    final clip = editing.previewClip(source.id);
    final target = widget.asset.tracks.indexWhere(
      (track) => track.id == editing.previewTrackId(source.id),
    );
    final color = tint(context, clip);
    final selected = editing.selectedClipIds.contains(clip.id);
    Widget handle(PresentationTimelineDragKind kind) => GestureDetector(
      key: ValueKey('${kind.name}-${clip.id}'),
      behavior: HitTestBehavior.opaque,
      onPanStart: (event) =>
          begin(source, trackIndex, kind, event.globalPosition),
      onPanUpdate: (event) => update(event.globalPosition),
      onPanEnd: (_) => finish(),
      onPanCancel: cancel,
      child: SizedBox(
        width: 10,
        child: Center(child: Container(width: 2, height: 16, color: color)),
      ),
    );
    return Positioned(
      left: x(clip.startUs),
      top: 30 + target * 36.0,
      width: math.max(18, x(clip.durationUs)),
      height: 28,
      child: GestureDetector(
        key: ValueKey('clip-${clip.id}'),
        onTap: () {
          if (widget.beforeSelection?.call() == false) return;
          editing.selectClip(
            clip.id,
            additive: HardwareKeyboard.instance.isShiftPressed,
          );
          widget.changed();
        },
        onPanStart: (event) => begin(
          source,
          trackIndex,
          PresentationTimelineDragKind.move,
          event.globalPosition,
        ),
        onPanUpdate: (event) => update(event.globalPosition),
        onPanEnd: (_) => finish(),
        onPanCancel: cancel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: selected ? .45 : .24),
            border: Border.all(color: color, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              if (clip is! PresentationMarkerClip)
                handle(PresentationTimelineDragKind.trimStart),
              Expanded(
                child: Text(
                  clip is PresentationVisualClip ||
                          clip is PresentationAudioClip
                      ? widget.asset.tracks[trackIndex].label
                      : presentationClipLabel(clip),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              if (clip is! PresentationMarkerClip)
                handle(PresentationTimelineDragKind.trimEnd),
            ],
          ),
        ),
      ),
    );
  }
}
