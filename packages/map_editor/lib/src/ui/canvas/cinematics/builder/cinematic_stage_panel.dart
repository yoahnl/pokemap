import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../design_system/design_system.dart';
import 'cinematic_storyboard_strip.dart';

/// Render-neutral owner for the stage/preview surface extracted in NSC-61.
final class CinematicStagePanel extends StatefulWidget {
  const CinematicStagePanel({
    super.key,
    required this.child,
    this.cinematic,
    this.onApplyPreset,
  });

  static const surfaceKey = ValueKey<String>('cinematic-stage-panel');

  final Widget child;

  final CinematicAsset? cinematic;
  final ApplyCinematicBlockingPresetCallback? onApplyPreset;

  @override
  State<CinematicStagePanel> createState() => _CinematicStagePanelState();
}

final class _CinematicStagePanelState extends State<CinematicStagePanel> {
  String? _selectedShotId;
  bool _storyboardExpanded = false;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
        key: CinematicStagePanel.surfaceKey,
        child: widget.cinematic == null
            ? widget.child
            : Stack(
                fit: StackFit.expand,
                children: [
                  widget.child,
                  if (_storyboardExpanded)
                    Positioned(
                      left: 8,
                      right: 8,
                      top: 8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CinematicStoryboardStrip(
                          cinematic: widget.cinematic!,
                          selectedShotId: _selectedShotId,
                          onSelectShot: (shot) => setState(() {
                            _selectedShotId = shot.id;
                          }),
                          onApplyPreset: widget.onApplyPreset,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: PokeMapIconButton(
                      key: const ValueKey('cinematic-storyboard-toggle'),
                      onPressed: () => setState(() {
                        _storyboardExpanded = !_storyboardExpanded;
                      }),
                      icon: Icon(
                        _storyboardExpanded
                            ? CupertinoIcons.rectangle_compress_vertical
                            : CupertinoIcons.rectangle_expand_vertical,
                        size: 15,
                      ),
                      tooltip: _storyboardExpanded
                          ? 'Masquer le storyboard'
                          : 'Afficher le storyboard',
                      variant: PokeMapIconButtonVariant.soft,
                      isSelected: _storyboardExpanded,
                    ),
                  ),
                ],
              ),
      );
}
