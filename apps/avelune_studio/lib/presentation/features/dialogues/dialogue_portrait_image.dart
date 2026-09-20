import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../features/dialogues/domain/dialogue_port.dart';
import '../../shared/widgets/feedback/studio_icon_tile.dart';
import '../../shared/widgets/feedback/studio_badge.dart';

class DialoguePortraitImage extends StatefulWidget {
  const DialoguePortraitImage({
    super.key,
    required this.port,
    required this.characterId,
    required this.stateId,
    this.size = 48,
  });
  final DialoguePort port;
  final String? characterId, stateId;
  final double size;
  @override
  State<DialoguePortraitImage> createState() => _DialoguePortraitImageState();
}

class _DialoguePortraitImageState extends State<DialoguePortraitImage> {
  Future<Uint8List?>? image;
  void load() {
    final port = widget.port;
    image =
        port is DialoguePortraitPort &&
            widget.characterId != null &&
            widget.stateId != null
        ? (port as DialoguePortraitPort).readPortrait(
            widget.characterId!,
            widget.stateId!,
          )
        : null;
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  void didUpdateWidget(DialoguePortraitImage old) {
    super.didUpdateWidget(old);
    if (old.port != widget.port ||
        old.characterId != widget.characterId ||
        old.stateId != widget.stateId) {
      load();
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size,
    height: widget.size,
    child: FutureBuilder<Uint8List?>(
      future: image,
      builder: (context, snapshot) => snapshot.data == null
          ? StudioIconTile(
              icon: Icons.person_outline,
              tone: StudioTone.feature,
              size: widget.size,
            )
          : Image.memory(
              snapshot.data!,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, error, stack) =>
                  const Icon(Icons.broken_image_outlined),
            ),
    ),
  );
}
