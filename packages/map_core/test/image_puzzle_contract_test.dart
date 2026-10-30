import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

ImagePuzzleDefinition definition({List<int> rotations = const [0, 1, 2, 3]}) =>
    ImagePuzzleDefinition(
      puzzleId: 'puzzle',
      imageResourceId: 'images.puzzle',
      rows: 2,
      columns: 2,
      trayCapacity: 2,
      allowedQuarterTurns: rotations,
    );
List<ImagePuzzlePiece> pieces() =>
    List.generate(4, (id) => ImagePuzzlePiece(pieceId: id, slot: id));

void main() {
  test('definition JSON and fingerprint are canonical and complete', () {
    final config = definition();
    expect(ImagePuzzleDefinition.fromJson(config.toJson()), config);
    expect(config.fingerprint, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(definition(rotations: [3, 0, 2, 1]).fingerprint, config.fingerprint);
    expect(
      definition(rotations: [0, 2]).fingerprint,
      isNot(config.fingerprint),
    );
  });
  test('invalid config rejects instead of repairing', () {
    for (final patch in <Map<String, dynamic>>[
      {'rows': 0},
      {'columns': -1},
      {'rows': 1025},
      {'rows': 9223372036854775807, 'columns': 2},
      {'rows': 2, 'columns': 9223372036854775807},
      {'trayCapacity': -1},
      {
        'allowedQuarterTurns': [1],
      },
      {
        'allowedQuarterTurns': [0, 0],
      },
      {
        'allowedQuarterTurns': [0, 4],
      },
      {
        'allowedQuarterTurns': [0, 1.0],
      },
      {'imageResourceId': ''},
      {'puzzleId': ' padded '},
      {'schemaVersion': 2},
      {'unknown': true},
    ]) {
      expect(
        () => ImagePuzzleDefinition.fromJson({
          ...definition().toJson(),
          ...patch,
        }),
        throwsFormatException,
      );
    }
  });
  test(
    'progress rejects missing, duplicate, out of bounds and invalid angle',
    () {
      for (final value in [
        pieces()..removeLast(),
        pieces()..[3] = ImagePuzzlePiece(pieceId: 2, slot: 3),
        pieces()..[3] = ImagePuzzlePiece(pieceId: 3, slot: 0),
        pieces()..[3] = ImagePuzzlePiece(pieceId: 3, slot: 6),
        pieces()..[3] = ImagePuzzlePiece(pieceId: 4, slot: 3),
        pieces()..[3] = ImagePuzzlePiece(pieceId: 3, slot: -1),
        pieces()..[3] = ImagePuzzlePiece(pieceId: 3, slot: 3, quarterTurns: 4),
      ]) {
        expect(
          () => ImagePuzzleProgress(definition: definition(), pieces: value),
          throwsFormatException,
        );
      }
      expect(
        () => ImagePuzzleProgress(
          definition: definition(rotations: [0, 2]),
          pieces: pieces()
            ..[0] = ImagePuzzlePiece(pieceId: 0, slot: 0, quarterTurns: 1),
        ),
        throwsFormatException,
      );
      final progress = ImagePuzzleProgress(
        definition: definition(),
        pieces: pieces(),
      );
      expect(() => progress.pieces.clear(), throwsUnsupportedError);
      expect(
        () => progress.definition.allowedQuarterTurns.clear(),
        throwsUnsupportedError,
      );
      expect(ImagePuzzleProgress.fromJson(progress.toJson()), progress);
      final json = progress.toJson()..['definitionFingerprint'] = 'forged';
      final before = jsonEncode(json);
      expect(() => ImagePuzzleProgress.fromJson(json), throwsFormatException);
      expect(jsonEncode(json), before);
    },
  );
  test('fixed pieces require solved positions', () {
    final config = ImagePuzzleDefinition(
      puzzleId: 'fixed',
      imageResourceId: 'images.fixed',
      rows: 1,
      columns: 2,
      trayCapacity: 2,
      fixedPieceIds: [0],
      initialPieces: [
        ImagePuzzlePiece(pieceId: 0, slot: 0),
        ImagePuzzlePiece(pieceId: 1, slot: 2, quarterTurns: 1),
      ],
    );
    expect(ImagePuzzleDefinition.fromJson(config.toJson()), config);
    expect(
      () => ImagePuzzleProgress(
        definition: config,
        pieces: [
          ImagePuzzlePiece(pieceId: 0, slot: 1),
          ImagePuzzlePiece(pieceId: 1, slot: 0),
        ],
      ),
      throwsFormatException,
    );
  });
  test(
    'strict save and SaveData roundtrip retain unrelated state and legacy absence',
    () {
      final config = definition();
      final progress = ImagePuzzleProgress(
        definition: config,
        pieces: pieces(),
      );
      final state = GameState(
        saveId: 'puzzle-save',
        currentMapId: 'map',
        metadata: {'keep': 'value'},
        imagePuzzleState: ImagePuzzleState(puzzlesById: {'puzzle': progress}),
      );
      final json = strictGameStateSaveJson(state);
      expect(
        gameStateFromStrictSaveJson(
          jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
        ).imagePuzzleState,
        state.imagePuzzleState,
      );
      final restored = gameStateFromSaveData(
        SaveData.fromJson(saveDataFromGameState(state).toJson()),
      );
      expect(restored.imagePuzzleState, state.imagePuzzleState);
      expect(restored.currentMapId, 'map');
      expect(restored.metadata, {'keep': 'value'});
      final legacy = strictGameStateSaveJson(const GameState(saveId: 'old'))
        ..remove('imagePuzzleState');
      expect(
        gameStateFromStrictSaveJson(legacy).imagePuzzleState,
        const ImagePuzzleState.empty(),
      );
      final oldSave = saveDataFromGameState(
        const GameState(saveId: 'old'),
      ).toJson()..remove('imagePuzzleState');
      expect(
        SaveData.fromJson(oldSave).imagePuzzleState,
        const ImagePuzzleState.empty(),
      );
      for (final invalid in [
        null,
        {'schemaVersion': 999, 'puzzlesById': {}},
        {
          'schemaVersion': 1,
          'puzzlesById': {'wrong': progress.toJson()},
        },
      ]) {
        final corrupt = {...json, 'imagePuzzleState': invalid};
        final before = jsonEncode(corrupt);
        expect(
          () => gameStateFromStrictSaveJson(corrupt),
          throwsFormatException,
        );
        expect(jsonEncode(corrupt), before);
      }
    },
  );
  test(
    'signed envelope restores puzzle and rejects corrupt nested state without byte changes',
    () {
      const mapper = GameStateSaveEnvelopeMapper();
      const codec = SaveEnvelopeCodec();
      const saveId = '018f255f-2d50-4f4f-8aa2-c893ae06b8c1';
      final progress = ImagePuzzleProgress(
        definition: definition(),
        pieces: pieces(),
      );
      final state = GameState(
        saveId: saveId,
        imagePuzzleState: ImagePuzzleState(puzzlesById: {'puzzle': progress}),
      );
      final envelope = mapper.create(
        identity: GameIdentity(
          gameId: 'games.example.puzzle',
          gameVersion: '1.0.0',
          projectFormat: ProjectFormat.v8,
          saveFormat: SaveEnvelopeCodec.currentSaveFormat,
          compatibilityId: 'puzzle-v1',
        ),
        profileId: 'player-1',
        slotId: 'slot-1',
        saveId: saveId,
        createdAt: DateTime.utc(2026, 10, 30),
        updatedAt: DateTime.utc(2026, 10, 30),
        status: SaveStatus.active,
        playTimeSeconds: 0,
        gameState: state,
      );
      final encoded = codec.encode(envelope);
      expect(
        mapper.restore(codec.decodeUtf8(utf8.encode(encoded))).imagePuzzleState,
        state.imagePuzzleState,
      );
      expect(codec.verifyChecksum(envelope), isTrue);
      for (final corruptValue in [
        null,
        {'schemaVersion': 999, 'puzzlesById': {}},
      ]) {
        final corrupt = jsonDecode(encoded) as Map<String, dynamic>;
        (corrupt['state'] as Map<String, dynamic>)['imagePuzzleState'] =
            corruptValue;
        corrupt['checksum'] = {
          'algorithm': 'sha256',
          'value': codec.computeChecksum(corrupt),
        };
        final bytes = utf8.encode(jsonEncode(corrupt));
        final originalBytes = List<int>.of(bytes);
        final decoded = codec.decodeUtf8(bytes);
        final originalEnvelope = codec.encode(decoded);
        expect(
          () => mapper.restore(decoded),
          throwsA(isA<SaveContractException>()),
        );
        expect(bytes, originalBytes);
        expect(codec.encode(decoded), originalEnvelope);
      }
    },
  );
  test('a single movable piece needs space or rotation to start unsolved', () {
    expect(
      () => ImagePuzzleDefinition(
        puzzleId: 'puzzle',
        imageResourceId: 'images.puzzle',
        rows: 1,
        columns: 2,
        fixedPieceIds: [0],
        trayCapacity: 0,
        allowSwap: true,
        allowedQuarterTurns: [0],
      ),
      throwsFormatException,
    );
  });
}
