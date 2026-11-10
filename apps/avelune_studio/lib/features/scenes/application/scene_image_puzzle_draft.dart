import 'package:map_core/map_core_domain.dart';

class SceneImagePuzzleDraft {
  SceneImagePuzzleDraft({
    required this.current,
    required this.changed,
    this.loadVisualMedia,
  }) {
    read();
    load();
  }
  SceneOpenImagePuzzleInteractiveCommand? current;
  Future<ProjectMediaCatalog> Function()? loadVisualMedia;
  final void Function() changed;
  bool _disposed = false;
  int imageRevision = 0;
  void _update(void Function() update) {
    if (_disposed) return;
    update();
    changed();
  }

  void configure({
    required SceneOpenImagePuzzleInteractiveCommand? current,
    required Future<ProjectMediaCatalog> Function()? loadVisualMedia,
  }) {
    final reread = this.current != current;
    final reload = this.loadVisualMedia != loadVisualMedia;
    this.current = current;
    this.loadVisualMedia = loadVisualMedia;
    if (reread) read();
    if (reload) load();
  }

  void dispose() {
    _disposed = true;
    _request++;
  }

  late Map<String, dynamic> value;
  Map<String, String> images = const {};
  String? mediaError;
  var _request = 0;
  int get count => (value['rows'] as int) * (value['columns'] as int);
  List<int> get fixed => (value['fixedPieceIds'] as List).cast<int>();
  List<int> get turns => (value['allowedQuarterTurns'] as List).cast<int>();
  List<Map<String, dynamic>>? get pieces => (value['initialPieces'] as List?)
      ?.map((piece) => Map<String, dynamic>.from(piece as Map))
      .toList();

  void read() {
    imageRevision++;
    value =
        current?.definition.toJson() ??
        {
          'schemaVersion': 1,
          'puzzleId': '',
          'imageResourceId': '',
          'rows': 4,
          'columns': 4,
          'trayCapacity': 1,
          'allowedQuarterTurns': [0, 1, 2, 3],
          'fixedPieceIds': <int>[],
          'allowReset': true,
          'allowSwap': false,
        };
  }

  Future<void> load() async {
    final request = ++_request;
    images = const {};
    imageRevision++;
    mediaError = null;
    final load = loadVisualMedia;
    if (load == null) return;
    try {
      final media = await load();
      if (!_disposed && request == _request) {
        _update(() {
          imageRevision++;
          images = {
            for (final entry in media.entries)
              if (entry.kind == ProjectMediaKind.image) entry.id: entry.label,
          };
        });
      }
    } on Object {
      if (!_disposed && request == _request) {
        _update(
          () => mediaError = 'La médiathèque est indisponible. Rechargez-la avant d’appliquer.',
        );
      }
    }
  }

  ImagePuzzleDefinition? get definition {
    if (!images.containsKey(value['imageResourceId'])) return null;
    try {
      return ImagePuzzleDefinition.fromJson(value);
    } on Object {
      return null;
    }
  }

  void change(String field, Object value) => _update(() {
    if (field == 'imageResourceId') imageRevision++;
    this.value[field] = value;
  });

  List<Map<String, dynamic>> initial() {
    final movable = [
      for (var id = 0; id < count; id++)
        if (!fixed.contains(id)) id,
    ];
    return [
      for (var id = 0; id < count; id++)
        {
          'pieceId': id,
          'slot': fixed.contains(id)
              ? id
              : movable.length > 1
              ? movable[(movable.indexOf(id) + 1) % movable.length]
              : (value['trayCapacity'] as int) > 0
              ? count
              : id,
          'quarterTurns':
              !fixed.contains(id) &&
                  movable.length == 1 &&
                  value['trayCapacity'] == 0 &&
                  turns.length > 1
              ? turns.last
              : 0,
        },
    ];
  }

  void piece(int id, String field, int value) => change('initialPieces', [
    for (final piece in pieces!)
      piece['pieceId'] == id ? {...piece, field: value} : piece,
  ]);
}
