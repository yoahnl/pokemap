import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const codec = SaveEnvelopeCodec();

  group('SaveEnvelopeCodec', () {
    test('accepts and round-trips the canonical Phase 0 fixture', () {
      final fixture = File(
        'test/fixtures/save/minimal-valid-save-envelope.json',
      ).readAsStringSync();

      final envelope = codec.decode(fixture);
      final roundTrip = codec.decode(codec.encode(envelope));

      expect(envelope.gameId, 'games.example.complete');
      expect(envelope.profileId, 'player-1');
      expect(envelope.slotId, 'slot-1');
      expect(envelope.checksum.value,
          'cd6ae9c5e1ae4c3c9ae5ba5574545de893e7ebeabbe1169f9870dec61aacde77');
      expect(roundTrip, envelope);
    });

    test('creates a checksummed immutable envelope', () {
      final sourceState = <String, Object?>{
        'mapId': 'start',
        'inventory': <Object?>['potion'],
      };
      final envelope = codec.create(
        identity: _identity(),
        profileId: 'player-1',
        slotId: 'slot-1',
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        createdAt: DateTime.utc(2026, 7, 25, 10),
        updatedAt: DateTime.utc(2026, 7, 25, 10),
        status: SaveStatus.active,
        playTimeSeconds: 42,
        state: sourceState,
      );

      sourceState['mapId'] = 'mutated';
      (sourceState['inventory']! as List<Object?>).add('escape-rope');

      expect(envelope.state, <String, Object?>{
        'mapId': 'start',
        'inventory': <Object?>['potion'],
      });
      expect(codec.verifyChecksum(envelope), isTrue);
    });

    test('rejects checksum tampering and unknown fields', () {
      final json = _validJson(codec);
      (json['state']! as Map<String, dynamic>)['mapId'] = 'tampered';
      expect(
        () => codec.decodeJson(json),
        throwsA(
          isA<SaveContractException>().having(
            (error) => error.code,
            'code',
            SaveContractErrorCode.checksumMismatch,
          ),
        ),
      );

      final withUnknown = _validJson(codec)..['debug'] = true;
      expect(
        () => codec.decodeJson(withUnknown),
        throwsA(
          isA<SaveContractException>().having(
            (error) => error.code,
            'code',
            SaveContractErrorCode.unknownField,
          ),
        ),
      );
    });

    test('enforces timestamp and completion invariants', () {
      final reversed = _validJson(codec)
        ..['createdAt'] = '2026-07-25T11:00:00Z';
      _resign(reversed, codec);
      expect(
        () => codec.decodeJson(reversed),
        throwsA(
          isA<SaveContractException>().having(
            (error) => error.code,
            'code',
            SaveContractErrorCode.invalidTimeline,
          ),
        ),
      );

      final completedWithoutDate = _validJson(codec)..['status'] = 'completed';
      _resign(completedWithoutDate, codec);
      expect(
        () => codec.decodeJson(completedWithoutDate),
        throwsA(
          isA<SaveContractException>().having(
            (error) => error.code,
            'code',
            SaveContractErrorCode.invalidCompletion,
          ),
        ),
      );

      final activeWithDate = _validJson(codec)
        ..['completedAt'] = '2026-07-25T10:01:00Z';
      _resign(activeWithDate, codec);
      expect(
        () => codec.decodeJson(activeWithDate),
        throwsA(
          isA<SaveContractException>().having(
            (error) => error.code,
            'code',
            SaveContractErrorCode.invalidCompletion,
          ),
        ),
      );

      final completionAfterUpdate = _validJson(codec)
        ..['status'] = 'completed'
        ..['completedAt'] = '2026-07-25T10:01:00Z';
      _resign(completionAfterUpdate, codec);
      expect(
        () => codec.decodeJson(completionAfterUpdate),
        throwsA(
          isA<SaveContractException>().having(
            (error) => error.code,
            'code',
            SaveContractErrorCode.invalidTimeline,
          ),
        ),
      );
    });

    test('enforces expected game/profile/slot identity', () {
      expect(
        () => codec.decodeJson(
          _validJson(codec),
          expectedAddress: SaveSlotAddress(
            gameId: 'games.example.complete',
            profileId: 'other-player',
            slotId: 'slot-1',
          ),
        ),
        throwsA(
          isA<SaveContractException>().having(
            (error) => error.code,
            'code',
            SaveContractErrorCode.addressMismatch,
          ),
        ),
      );
    });

    test('rejects malformed UUID, non-UTC dates, and oversized play time', () {
      final cases = <Map<String, Object?>>[
        _validJson(codec)..['saveId'] = 'save-1',
        _validJson(codec)..['updatedAt'] = '2026-07-25T12:00:00+02:00',
        _validJson(codec)..['playTimeSeconds'] = 3155760001,
      ];
      for (final json in cases) {
        _resign(json, codec);
        expect(
          () => codec.decodeJson(json),
          throwsA(isA<SaveContractException>()),
        );
      }
    });

    test('rejects JSON values that cannot be canonicalized safely', () {
      final json = _validJson(codec);
      (json['state']! as Map<String, dynamic>)['bad'] = double.nan;
      expect(
        () => codec.computeChecksum(json),
        throwsA(isA<SaveContractException>()),
      );
    });
  });
}

GameIdentity _identity({int saveFormat = 1}) => GameIdentity(
      gameId: 'games.example.complete',
      gameVersion: '1.2.0',
      projectFormat: ProjectFormat.v2,
      saveFormat: saveFormat,
      compatibilityId: 'campaign-v1',
    );

Map<String, Object?> _validJson(SaveEnvelopeCodec codec) {
  return jsonDecode(
    codec.encode(
      codec.create(
        identity: _identity(),
        profileId: 'player-1',
        slotId: 'slot-1',
        saveId: '018f255f-2d50-4f4f-8aa2-c893ae06b8c1',
        createdAt: DateTime.utc(2026, 7, 25, 10),
        updatedAt: DateTime.utc(2026, 7, 25, 10),
        status: SaveStatus.active,
        playTimeSeconds: 0,
        state: <String, Object?>{'mapId': 'start'},
      ),
    ),
  ) as Map<String, Object?>;
}

void _resign(Map<String, Object?> json, SaveEnvelopeCodec codec) {
  json['checksum'] = <String, Object?>{
    'algorithm': 'sha256',
    'value': codec.computeChecksum(json),
  };
}
