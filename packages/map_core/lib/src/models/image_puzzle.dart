import 'dart:convert';

import 'package:crypto/crypto.dart';

final class ImagePuzzlePiece {
  const ImagePuzzlePiece({
    required this.pieceId,
    required this.slot,
    this.quarterTurns = 0,
  });

  factory ImagePuzzlePiece.fromJson(Map<String, dynamic> json) {
    _fields(json, {'pieceId', 'slot', 'quarterTurns'});
    return ImagePuzzlePiece(
      pieceId: _integer(json, 'pieceId'),
      slot: _integer(json, 'slot'),
      quarterTurns: _integer(json, 'quarterTurns'),
    );
  }

  final int pieceId, slot, quarterTurns;

  Map<String, dynamic> toJson() => {
    'pieceId': pieceId,
    'slot': slot,
    'quarterTurns': quarterTurns,
  };

  @override
  bool operator ==(Object other) =>
      other is ImagePuzzlePiece &&
      pieceId == other.pieceId &&
      slot == other.slot &&
      quarterTurns == other.quarterTurns;

  @override
  int get hashCode => Object.hash(pieceId, slot, quarterTurns);
}

final class ImagePuzzleDefinition {
  ImagePuzzleDefinition({
    required this.puzzleId,
    required this.imageResourceId,
    required this.rows,
    required this.columns,
    this.trayCapacity = 1,
    this.allowSwap = false,
    Iterable<int> allowedQuarterTurns = const [0, 1, 2, 3],
    Iterable<int> fixedPieceIds = const [],
    Iterable<ImagePuzzlePiece>? initialPieces,
    this.allowReset = true,
  }) : allowedQuarterTurns = List.unmodifiable(
         allowedQuarterTurns.toList()..sort(),
       ),
       fixedPieceIds = List.unmodifiable(fixedPieceIds.toList()..sort()),
       initialPieces = initialPieces == null ? null : _ordered(initialPieces) {
    _identity(puzzleId);
    _identity(imageResourceId);
    if (rows < 1 ||
        rows > maximumPieces ||
        columns < 1 ||
        columns > maximumPieces ||
        pieceCount > maximumPieces ||
        trayCapacity < 0 ||
        trayCapacity > maximumPieces ||
        (trayCapacity == 0 && !allowSwap) ||
        this.allowedQuarterTurns.isEmpty ||
        !this.allowedQuarterTurns.contains(0) ||
        this.allowedQuarterTurns.toSet().length !=
            this.allowedQuarterTurns.length ||
        this.allowedQuarterTurns.any((value) => value < 0 || value > 3) ||
        this.fixedPieceIds.toSet().length != this.fixedPieceIds.length ||
        this.fixedPieceIds.any((id) => id < 0 || id >= pieceCount) ||
        this.fixedPieceIds.length == pieceCount) {
      throw const FormatException('Invalid image puzzle definition.');
    }
    if (pieceCount - this.fixedPieceIds.length == 1 &&
        trayCapacity == 0 &&
        this.allowedQuarterTurns.length == 1) {
      throw const FormatException(
        'An image puzzle must permit an unsolved arrangement.',
      );
    }
    final initial = this.initialPieces;
    if (initial != null) {
      _validatePieces(this, initial);
      if (_solved(initial)) {
        throw const FormatException(
          'The initial image puzzle must be unsolved.',
        );
      }
    }
  }

  static const maximumPieces = 1024;

  factory ImagePuzzleDefinition.fromJson(Map<String, dynamic> json) {
    _fields(json, {
      'schemaVersion',
      'puzzleId',
      'imageResourceId',
      'rows',
      'columns',
      'trayCapacity',
      'allowedQuarterTurns',
      'fixedPieceIds',
      'allowReset',
      'allowSwap',
      if (json.containsKey('initialPieces')) 'initialPieces',
    });
    _version(json);
    if (json['allowReset'] is! bool || json['allowSwap'] is! bool) {
      throw const FormatException('Image puzzle allowReset must be a boolean.');
    }
    return ImagePuzzleDefinition(
      puzzleId: _string(json, 'puzzleId'),
      imageResourceId: _string(json, 'imageResourceId'),
      rows: _integer(json, 'rows'),
      columns: _integer(json, 'columns'),
      trayCapacity: _integer(json, 'trayCapacity'),
      allowedQuarterTurns: _integers(json['allowedQuarterTurns']),
      fixedPieceIds: _integers(json['fixedPieceIds']),
      allowReset: json['allowReset'] as bool,
      allowSwap: json['allowSwap'] as bool,
      initialPieces: json.containsKey('initialPieces')
          ? _pieces(json['initialPieces'])
          : null,
    );
  }

  final String puzzleId, imageResourceId;
  final int rows, columns, trayCapacity;
  final List<int> allowedQuarterTurns, fixedPieceIds;
  final List<ImagePuzzlePiece>? initialPieces;
  final bool allowReset, allowSwap;
  int get pieceCount => rows * columns;
  int get slotCount => pieceCount + trayCapacity;
  String get fingerprint =>
      sha256.convert(utf8.encode(jsonEncode(toJson()))).toString();

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'puzzleId': puzzleId,
    'imageResourceId': imageResourceId,
    'rows': rows,
    'columns': columns,
    'trayCapacity': trayCapacity,
    'allowedQuarterTurns': allowedQuarterTurns,
    'fixedPieceIds': fixedPieceIds,
    'allowReset': allowReset,
    'allowSwap': allowSwap,
    if (initialPieces != null)
      'initialPieces': [for (final piece in initialPieces!) piece.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is ImagePuzzleDefinition && fingerprint == other.fingerprint;

  @override
  int get hashCode => fingerprint.hashCode;
}

final class ImagePuzzleProgress {
  ImagePuzzleProgress({
    required this.definition,
    required Iterable<ImagePuzzlePiece> pieces,
  }) : pieces = _ordered(pieces) {
    _validatePieces(definition, this.pieces);
  }

  factory ImagePuzzleProgress.fromJson(Map<String, dynamic> json) {
    _fields(json, {
      'schemaVersion',
      'definition',
      'definitionFingerprint',
      'pieces',
    });
    _version(json);
    final definition = ImagePuzzleDefinition.fromJson(
      _object(json['definition']),
    );
    if (_string(json, 'definitionFingerprint') != definition.fingerprint) {
      throw const FormatException(
        'Image puzzle definition fingerprint mismatch.',
      );
    }
    return ImagePuzzleProgress(
      definition: definition,
      pieces: _pieces(json['pieces']),
    );
  }

  final ImagePuzzleDefinition definition;
  final List<ImagePuzzlePiece> pieces;
  bool get isSolved => _solved(pieces);

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'definition': definition.toJson(),
    'definitionFingerprint': definition.fingerprint,
    'pieces': [for (final piece in pieces) piece.toJson()],
  };

  @override
  bool operator ==(Object other) =>
      other is ImagePuzzleProgress &&
      definition == other.definition &&
      pieces.length == other.pieces.length &&
      Iterable.generate(
        pieces.length,
      ).every((id) => pieces[id] == other.pieces[id]);

  @override
  int get hashCode => Object.hash(definition, Object.hashAll(pieces));
}

final class ImagePuzzleState {
  const ImagePuzzleState.empty() : puzzlesById = const {};

  ImagePuzzleState({required Map<String, ImagePuzzleProgress> puzzlesById})
    : puzzlesById = Map.unmodifiable(puzzlesById) {
    for (final entry in this.puzzlesById.entries) {
      if (entry.key != entry.value.definition.puzzleId) {
        throw const FormatException(
          'Image puzzle state key does not match puzzleId.',
        );
      }
    }
  }

  factory ImagePuzzleState.fromJson(Map<String, dynamic> json) {
    _fields(json, {'schemaVersion', 'puzzlesById'});
    _version(json);
    return ImagePuzzleState(
      puzzlesById: {
        for (final entry in _object(json['puzzlesById']).entries)
          entry.key: ImagePuzzleProgress.fromJson(_object(entry.value)),
      },
    );
  }

  final Map<String, ImagePuzzleProgress> puzzlesById;

  ImagePuzzleState withProgress(ImagePuzzleProgress progress) =>
      ImagePuzzleState(
        puzzlesById: {...puzzlesById, progress.definition.puzzleId: progress},
      );

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'puzzlesById': {
      for (final entry in puzzlesById.entries) entry.key: entry.value.toJson(),
    },
  };

  @override
  bool operator ==(Object other) =>
      other is ImagePuzzleState &&
      puzzlesById.length == other.puzzlesById.length &&
      puzzlesById.entries.every(
        (entry) => other.puzzlesById[entry.key] == entry.value,
      );

  @override
  int get hashCode => Object.hashAllUnordered(
    puzzlesById.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}

Object? readImagePuzzleStateJson(Map<dynamic, dynamic> json, String key) {
  if (json.containsKey(key) && json[key] == null) {
    throw const FormatException('Image puzzle state must not be null.');
  }
  return json[key];
}

void _validatePieces(
  ImagePuzzleDefinition definition,
  List<ImagePuzzlePiece> pieces,
) {
  if (pieces.length != definition.pieceCount ||
      pieces.map((piece) => piece.pieceId).toSet().length !=
          definition.pieceCount ||
      pieces.map((piece) => piece.slot).toSet().length !=
          definition.pieceCount ||
      pieces.any(
        (piece) =>
            piece.pieceId < 0 ||
            piece.pieceId >= definition.pieceCount ||
            piece.slot < 0 ||
            piece.slot >= definition.slotCount ||
            !definition.allowedQuarterTurns.contains(piece.quarterTurns) ||
            (definition.fixedPieceIds.contains(piece.pieceId) &&
                (piece.slot != piece.pieceId || piece.quarterTurns != 0)),
      )) {
    throw const FormatException('Invalid image puzzle piece arrangement.');
  }
}

bool _solved(List<ImagePuzzlePiece> pieces) => pieces.every(
  (piece) => piece.pieceId == piece.slot && piece.quarterTurns == 0,
);

List<ImagePuzzlePiece> _ordered(Iterable<ImagePuzzlePiece> pieces) =>
    List.unmodifiable(
      pieces.toList()..sort((a, b) => a.pieceId.compareTo(b.pieceId)),
    );

List<ImagePuzzlePiece> _pieces(Object? value) {
  if (value is! List) {
    throw const FormatException('Image puzzle pieces must be a list.');
  }
  return value
      .map((piece) => ImagePuzzlePiece.fromJson(_object(piece)))
      .toList();
}

List<int> _integers(Object? value) {
  if (value is! List || value.any((entry) => entry is! int)) {
    throw const FormatException('Image puzzle values must be integers.');
  }
  return value.cast<int>();
}

void _fields(Map<String, dynamic> json, Set<String> fields) {
  if (json.length != fields.length || !json.keys.toSet().containsAll(fields)) {
    throw const FormatException('Invalid image puzzle fields.');
  }
}

void _version(Map<String, dynamic> json) {
  if (json['schemaVersion'] is! int || json['schemaVersion'] != 1) {
    throw const FormatException('Unsupported image puzzle schema.');
  }
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Image puzzle requires an object.');
  }
  return Map<String, dynamic>.from(value);
}

String _string(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Image puzzle $key must be a string.');
  }
  return value;
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Image puzzle $key must be an integer.');
  }
  return value;
}

void _identity(String value) {
  if (value.isEmpty || value.trim() != value) {
    throw const FormatException(
      'Image puzzle identities must be nonempty and trim-exact.',
    );
  }
}
