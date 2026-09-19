import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'studio_map_resources.dart';

class StudioCharacterThumbnail extends StatefulWidget {
  const StudioCharacterThumbnail({
    super.key,
    required this.resources,
    required this.character,
    required this.size,
    required this.facing,
  });
  final StudioMapResources resources;
  final ProjectCharacterEntry character;
  final double size;
  final EntityFacing facing;
  @override
  State<StudioCharacterThumbnail> createState() =>
      _StudioCharacterThumbnailState();
}

class _StudioCharacterThumbnailState extends State<StudioCharacterThumbnail> {
  final _owner = Object();
  void _retain() => widget.resources.retain(
    _owner,
    widget.resources.characterResourceIds(widget.character),
  );
  @override
  void initState() {
    super.initState();
    _retain();
  }

  @override
  void didUpdateWidget(StudioCharacterThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resources != widget.resources ||
        oldWidget.character != widget.character) {
      oldWidget.resources.release(_owner);
      _retain();
    }
  }

  @override
  void dispose() {
    widget.resources.release(_owner);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: AnimatedBuilder(
      animation: widget.resources,
      builder: (context, _) {
        final renderer = RuntimeAuthoringCharacterRenderer(
          character: widget.character,
          settings: widget.resources.manifest.settings,
          images: widget.resources.images,
          facing: widget.facing,
        );
        return renderer.hasVisual
            ? CustomPaint(painter: _CharacterPainter(renderer))
            : Tooltip(
                message: 'Sprite indisponible',
                child: Icon(
                  Icons.broken_image_outlined,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
              );
      },
    ),
  );
}

class _CharacterPainter extends CustomPainter {
  _CharacterPainter(this.renderer);
  final RuntimeAuthoringCharacterRenderer renderer;
  @override
  void paint(Canvas canvas, Size size) =>
      renderer.paintThumbnail(canvas, Offset.zero & size);
  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) => true;
}
