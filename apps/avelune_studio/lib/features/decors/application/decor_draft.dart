import 'package:map_core/map_core_domain.dart';

class DecorDraft {
  DecorDraft({required this.tileset, this.original})
    : selection =
          original?.frames.first.source ?? const TilesetSourceRect(x: 0, y: 0),
      name = original?.name ?? 'Nouveau décor';
  final ProjectTilesetEntry tileset;
  final ProjectElementEntry? original;
  TilesetSourceRect selection;
  String name;
  bool variant = false;
  bool collisionChanged = false;
  final newId = 'decor-${DateTime.now().microsecondsSinceEpoch}';
  Set<GridPos> blocked = {};

  void setBlocked(bool value) {
    collisionChanged = true;
    blocked = value
        ? {
            for (var y = 0; y < selection.height; y++)
              for (var x = 0; x < selection.width; x++) GridPos(x: x, y: y),
          }
        : {};
  }

  ProjectElementEntry build({bool validateName = true}) {
    if (validateName && name.trim().isEmpty) {
      throw const FormatException('Nommez ce décor.');
    }
    final base =
        original ??
        ProjectElementEntry(
          id: newId,
          name: name,
          tilesetId: tileset.id,
          categoryId: '',
          frames: [TilesetVisualFrame(source: selection)],
        );
    final editableFrame = base.frames.length == 1;
    final frames = editableFrame
        ? [base.frames.first.copyWith(source: selection)]
        : base.frames;
    final profile = collisionChanged
        ? (base.collisionProfile ?? const ElementCollisionProfile()).copyWith(
            source: ElementCollisionProfileSource.manual,
            shapeCells: blocked.toList(),
            cells: blocked.toList(),
            manualAddedCells: [],
            manualRemovedCells: [],
            collisionMask: null,
          )
        : base.collisionProfile;
    return base.copyWith(
      id: variant ? newId : base.id,
      name: name.trim(),
      frames: frames,
      collisionProfile: profile,
    );
  }
}
