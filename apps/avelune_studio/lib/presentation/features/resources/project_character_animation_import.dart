part of 'project_character_animation_editor.dart';

extension _CharacterAnimationImages on _ProjectCharacterAnimationEditorState {
  ProjectRegularAtlasTilesetSource? get _poseAtlas {
    if (_custom != null || _sourceId != null) return null;
    final source = widget.project.tilesets
        .where((item) => item.id == widget.character.tilesetId)
        .firstOrNull
        ?.source;
    return source is ProjectRegularAtlasTilesetSource &&
            source.pixelWidth >= _width &&
            source.pixelHeight >= _height
        ? source
        : null;
  }

  Future<void> _choosePose(
    int index,
    ProjectRegularAtlasTilesetSource atlas,
  ) async {
    final source = await showDialog<TilesetSourceRect>(
      context: context,
      builder: (context) => StudioReviewDialog(
        title: index == _poses.length
            ? 'Ajouter une pose'
            : 'Changer l’image de la pose',
        confirmLabel: null,
        onConfirmed: null,
        onCancelled: () => Navigator.pop(context),
        content: ProjectCharacterPoseSheet(
          atlas: atlas,
          width: _width,
          height: _height,
          project: widget.project,
          tilesetId: widget.character.tilesetId,
          visuals: widget.visuals,
          onPick: (source) => Navigator.pop(context, source),
        ),
      ),
    );
    if (source == null || !mounted) return;
    _position = index;
    _assign(source);
  }

  Future<void> _import() async {
    try {
      final image = await widget.pickImage();
      if (image == null || !mounted) return;
      final size = image.imageSize;
      if (size == null) {
        throw const ResourceFailure('Choisissez une planche PNG.');
      }
      final poses = await _selectCharacterAnimationFrames(
        context,
        size,
        width: _width,
        height: _height,
      );
      if (poses == null || !mounted) return;
      final imported = await widget.edit('characterStudio.asset.import', {
        'mediaKind': 'spriteSheet',
        'binding': {
          ..._slot,
          'kind': 'animationClip',
          'slotKind': _slot['kind'],
          'frames': poses.map((pose) => pose.toJson()).toList(),
          'loop': _savedLoop,
          'presentationReferenceHeightPx': null,
        },
      }, image: image);
      if (imported && mounted) _selectPose(0);
    } on ResourceFailure catch (failure) {
      if (mounted) _change(() => _problem = failure.message);
    }
  }
}

Future<({String name, bool directional})?> _describeCustomCharacterAnimation(
  BuildContext context,
) {
  var name = '';
  var directional = false;
  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, change) => StudioReviewDialog(
        title: 'Nouvelle animation',
        confirmLabel: 'Créer l’animation',
        onConfirmed: name.trim().isEmpty
            ? null
            : () => Navigator.pop(context, (
                name: name.trim(),
                directional: directional,
              )),
        onCancelled: () => Navigator.pop(context),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StudioDraftField(
              value: name,
              label: 'Nom de l’animation',
              autofocus: true,
              onChanged: (text) => change(() => name = text),
            ),
            StudioToggleRow(
              label: 'Une planche par direction',
              value: directional,
              onChanged: (value) => change(() => directional = value),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<List<CharacterAnimationFrame>?> _selectCharacterAnimationFrames(
  BuildContext context,
  LibraryImageSize size, {
  required int width,
  required int height,
}) {
  var widthText = (size.width % width == 0 ? width : size.width).toString();
  var heightText = (size.height % height == 0 ? height : size.height)
      .toString();
  return showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, change) {
        final x = int.tryParse(widthText);
        final y = int.tryParse(heightText);
        final fits =
            x != null &&
            y != null &&
            x > 0 &&
            y > 0 &&
            size.width % x == 0 &&
            size.height % y == 0;
        final count = fits ? (size.width ~/ x) * (size.height ~/ y) : 0;
        return StudioReviewDialog(
          title: 'Découper la planche',
          confirmLabel: 'Importer la planche',
          onConfirmed: !fits || count > 24
              ? null
              : () => Navigator.pop(context, [
                  for (var row = 0; row < size.height ~/ y; row++)
                    for (var column = 0; column < size.width ~/ x; column++)
                      CharacterAnimationFrame(
                        source: TilesetSourceRect(
                          x: column * x,
                          y: row * y,
                          width: x,
                          height: y,
                        ),
                        durationMs: 150,
                      ),
                ]),
          onCancelled: () => Navigator.pop(context),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Image de ${size.width} × ${size.height} px'),
              const SizedBox(height: StudioSpacing.m),
              Row(
                children: [
                  Expanded(
                    child: StudioDraftField(
                      label: 'Largeur d’une pose (px)',
                      value: widthText,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => change(() => widthText = value),
                    ),
                  ),
                  const SizedBox(width: StudioSpacing.m),
                  Expanded(
                    child: StudioDraftField(
                      label: 'Hauteur d’une pose (px)',
                      value: heightText,
                      keyboardType: TextInputType.number,
                      onChanged: (value) => change(() => heightText = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StudioSpacing.m),
              StudioNotice(switch ((fits, count)) {
                (false, _) =>
                  'Les poses doivent couvrir la planche par cases entières.',
                (_, > 24) => 'Cette planche contient plus de 24 poses.',
                (_, 1) => 'Une pose sera importée.',
                _ =>
                  '$count poses seront importées, de gauche à droite puis de haut en bas.',
              }),
            ],
          ),
        );
      },
    ),
  );
}
