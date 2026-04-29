import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Material, MaterialType, PopupMenuButton, PopupMenuItem, Slider;
import 'package:map_core/map_core.dart';

import '../surface_studio_design_tokens.dart';
import '../surface_studio_role_assignment_draft.dart';
import 'surface_studio_surface_preview_renderer.dart';

class SurfaceStudioPreviewPanel extends StatelessWidget {
  const SurfaceStudioPreviewPanel({
    super.key,
    required this.frameCount,
    required this.frameIndex,
    required this.playing,
    required this.loop,
    required this.gridVisible,
    required this.previewSize,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
    required this.assignmentDraft,
    this.atlasImageBytes,
    this.atlasFallbackMessage,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlaying,
    required this.onFrameChanged,
    required this.onLoopChanged,
    required this.onGridChanged,
    required this.onPreviewSizeChanged,
  });

  final int frameCount;
  final int frameIndex;
  final bool playing;
  final bool loop;
  final bool gridVisible;
  final int previewSize;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;
  final Uint8List? atlasImageBytes;
  final String? atlasFallbackMessage;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlaying;
  final ValueChanged<int> onFrameChanged;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<bool> onGridChanged;
  final ValueChanged<int> onPreviewSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('surfaceStudio.preview.panel'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundPanel,
        borderRadius:
            BorderRadius.circular(SurfaceStudioDesignTokens.panelRadius),
        border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Prévisualisation',
            style: TextStyle(
              color: SurfaceStudioDesignTokens.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: RepaintBoundary(
                    child: _PreviewViewport(
                      previewSize: previewSize,
                      gridVisible: gridVisible,
                      frameIndex: frameIndex,
                      frameCount: frameCount,
                      tileWidth: tileWidth,
                      tileHeight: tileHeight,
                      columnCount: columnCount,
                      atlasImageBytes: atlasImageBytes,
                      atlasFallbackMessage: atlasFallbackMessage,
                      assignmentDraft: assignmentDraft,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 180,
                  child: _PreviewControls(
                    frameCount: frameCount,
                    frameIndex: frameIndex,
                    playing: playing,
                    loop: loop,
                    gridVisible: gridVisible,
                    previewSize: previewSize,
                    onPrevious: onPrevious,
                    onNext: onNext,
                    onTogglePlaying: onTogglePlaying,
                    onFrameChanged: onFrameChanged,
                    onLoopChanged: onLoopChanged,
                    onGridChanged: onGridChanged,
                    onPreviewSizeChanged: onPreviewSizeChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewViewport extends StatelessWidget {
  const _PreviewViewport({
    required this.previewSize,
    required this.gridVisible,
    required this.frameIndex,
    required this.frameCount,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
    this.atlasImageBytes,
    this.atlasFallbackMessage,
    required this.assignmentDraft,
  });

  final int previewSize;
  final bool gridVisible;
  final int frameIndex;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;
  final Uint8List? atlasImageBytes;
  final String? atlasFallbackMessage;
  final SurfaceStudioRoleAssignmentDraft assignmentDraft;

  @override
  Widget build(BuildContext context) {
    final hasCenter = assignmentDraft.isAssigned(SurfaceVariantRole.isolated);
    final centerColumns =
        assignmentDraft.columnsForRole(SurfaceVariantRole.isolated);
    return Container(
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SurfaceStudioDesignTokens.borderStrong),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasCenter
          ? Stack(
              fit: StackFit.expand,
              children: [
                if (atlasImageBytes != null)
                  SurfaceStudioSurfacePreviewRenderer(
                    key: const ValueKey('surfaceStudio.preview.tileRenderer'),
                    atlasImageBytes: atlasImageBytes!,
                    assignmentDraft: assignmentDraft,
                    tileWidth: tileWidth,
                    tileHeight: tileHeight,
                    columnCount: columnCount,
                    frameCount: frameCount,
                    frameIndex: frameIndex,
                    previewSize: previewSize,
                    gridVisible: gridVisible,
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        atlasFallbackMessage ??
                            'Image source indisponible — aperçu illustratif.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: SurfaceStudioDesignTokens.textMuted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                if (atlasImageBytes != null)
                  const Positioned(
                    left: 10,
                    top: 10,
                    child: _PartialPreviewBadge(),
                  ),
                if (atlasImageBytes != null && centerColumns.isNotEmpty)
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: _SourceRectDebug(
                      centerColumns: centerColumns,
                      frameIndex: frameIndex,
                      frameCount: frameCount,
                      tileWidth: tileWidth,
                      tileHeight: tileHeight,
                      columnCount: columnCount,
                    ),
                  ),
              ],
            )
          : const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Assignez au moins le rôle “Plein” pour générer une prévisualisation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: SurfaceStudioDesignTokens.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ),
            ),
    );
  }
}

class _SourceRectDebug extends StatelessWidget {
  const _SourceRectDebug({
    required this.centerColumns,
    required this.frameIndex,
    required this.frameCount,
    required this.tileWidth,
    required this.tileHeight,
    required this.columnCount,
  });

  final List<int> centerColumns;
  final int frameIndex;
  final int frameCount;
  final int tileWidth;
  final int tileHeight;
  final int columnCount;

  @override
  Widget build(BuildContext context) {
    final safeFrameCount = frameCount < 1 ? 1 : frameCount;
    final safeFrameIndex = frameIndex % safeFrameCount;
    final column = centerColumns[safeFrameIndex % centerColumns.length];
    final source = surfaceStudioTileSourceRect(
      uiColumn: column,
      frameIndex: safeFrameIndex,
      tileWidth: tileWidth,
      tileHeight: tileHeight,
      columnCount: columnCount,
      frameCount: safeFrameCount,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SurfaceStudioDesignTokens.borderStrong.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          'Colonnes assignées au Plein : ${_formatColumns(centerColumns)}  •  '
          'Source rect actuelle : x=${source.left.round()} y=${source.top.round()} '
          'w=${source.width.round()} h=${source.height.round()}  •  '
          'Frame : ${safeFrameIndex + 1} / $safeFrameCount',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SurfaceStudioDesignTokens.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}

String _formatColumns(List<int> columns) {
  if (columns.isEmpty) {
    return 'aucune';
  }
  if (columns.length == 1) {
    return '${columns.first}';
  }
  return '${columns.first}–${columns.last}';
}

class _PartialPreviewBadge extends StatelessWidget {
  const _PartialPreviewBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SurfaceStudioDesignTokens.backgroundDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: SurfaceStudioDesignTokens.accentTeal),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          'Preview partielle : Plein(center)',
          style: TextStyle(
            color: SurfaceStudioDesignTokens.accentTeal,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PreviewControls extends StatelessWidget {
  const _PreviewControls({
    required this.frameCount,
    required this.frameIndex,
    required this.playing,
    required this.loop,
    required this.gridVisible,
    required this.previewSize,
    required this.onPrevious,
    required this.onNext,
    required this.onTogglePlaying,
    required this.onFrameChanged,
    required this.onLoopChanged,
    required this.onGridChanged,
    required this.onPreviewSizeChanged,
  });

  final int frameCount;
  final int frameIndex;
  final bool playing;
  final bool loop;
  final bool gridVisible;
  final int previewSize;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTogglePlaying;
  final ValueChanged<int> onFrameChanged;
  final ValueChanged<bool> onLoopChanged;
  final ValueChanged<bool> onGridChanged;
  final ValueChanged<int> onPreviewSizeChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundPanelAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _RoundControl(
                      keyName: 'surfaceStudio.preview.previous',
                      icon: CupertinoIcons.backward_end_fill,
                      onPressed: onPrevious,
                    ),
                    const SizedBox(width: 10),
                    _RoundControl(
                      keyName: 'surfaceStudio.preview.playPause',
                      icon: playing
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      onPressed: onTogglePlaying,
                      highlighted: true,
                    ),
                    const SizedBox(width: 10),
                    _RoundControl(
                      keyName: 'surfaceStudio.preview.next',
                      icon: CupertinoIcons.forward_end_fill,
                      onPressed: onNext,
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  'Frame ${frameIndex + 1} / $frameCount',
                  style: const TextStyle(
                    color: SurfaceStudioDesignTokens.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: Slider(
                    key: const ValueKey('surfaceStudio.preview.scrubSlider'),
                    value: frameIndex.toDouble(),
                    min: 0,
                    max: (frameCount - 1).toDouble(),
                    divisions: frameCount > 1 ? frameCount - 1 : null,
                    onChanged: (value) => onFrameChanged(value.round()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: SurfaceStudioDesignTokens.backgroundPanelAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SurfaceStudioDesignTokens.borderSubtle),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CheckLine(
                    label: 'Boucle',
                    value: loop,
                    onChanged: onLoopChanged,
                  ),
                  _CheckLine(
                    label: 'Grille',
                    value: gridVisible,
                    onChanged: onGridChanged,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Taille',
                        style: TextStyle(
                          color: SurfaceStudioDesignTokens.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Material(
                        type: MaterialType.transparency,
                        child: PopupMenuButton<int>(
                          key: const ValueKey(
                              'surfaceStudio.preview.sizeButton'),
                          initialValue: previewSize,
                          color: SurfaceStudioDesignTokens.backgroundElevated,
                          onSelected: onPreviewSizeChanged,
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 5, child: Text('5 × 5')),
                            PopupMenuItem(value: 10, child: Text('10 × 10')),
                            PopupMenuItem(value: 15, child: Text('15 × 15')),
                            PopupMenuItem(value: 20, child: Text('20 × 20')),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: SurfaceStudioDesignTokens.backgroundDeep,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: SurfaceStudioDesignTokens.borderStrong,
                              ),
                            ),
                            child: Text(
                              '$previewSize × $previewSize',
                              style: const TextStyle(
                                color: SurfaceStudioDesignTokens.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({
    required this.keyName,
    required this.icon,
    required this.onPressed,
    this.highlighted = false,
  });

  final String keyName;
  final IconData icon;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      key: ValueKey(keyName),
      padding: EdgeInsets.zero,
      minimumSize: const Size.square(36),
      onPressed: onPressed,
      child: Container(
        width: highlighted ? 42 : 34,
        height: highlighted ? 42 : 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: highlighted
              ? SurfaceStudioDesignTokens.accentTealSoft
              : SurfaceStudioDesignTokens.backgroundDeep,
          border: Border.all(
            color: highlighted
                ? SurfaceStudioDesignTokens.accentTeal
                : SurfaceStudioDesignTokens.borderStrong,
            width: highlighted ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: highlighted ? 22 : 17,
          color: highlighted
              ? SurfaceStudioDesignTokens.accentTeal
              : SurfaceStudioDesignTokens.textMuted,
        ),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              value
                  ? CupertinoIcons.checkmark_square_fill
                  : CupertinoIcons.square,
              color: value
                  ? SurfaceStudioDesignTokens.accentTeal
                  : SurfaceStudioDesignTokens.textMuted,
              size: 18,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: SurfaceStudioDesignTokens.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
