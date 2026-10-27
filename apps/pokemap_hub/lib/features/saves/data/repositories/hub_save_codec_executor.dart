import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';

typedef HubSaveCodecRunner = Future<T> Function<T>(
  FutureOr<T> Function() computation, {
  String? debugName,
});

final class HubSaveCodecExecutionException implements Exception {
  const HubSaveCodecExecutionException({
    required this.operation,
    required this.cause,
    required this.stackTrace,
    this.precedingError,
  });

  final String operation;
  final Object cause;
  final StackTrace stackTrace;
  final Object? precedingError;

  @override
  String toString() =>
      'HubSaveCodecExecutionException($operation): $cause'
      '${precedingError == null ? '' : '; after $precedingError'}';
}

final class HubSaveCodecExecutor {
  const HubSaveCodecExecutor({this.runner = Isolate.run});

  final HubSaveCodecRunner runner;

  Future<SaveEnvelope> validate({
    required SaveEnvelopeCodec codec,
    required SaveEnvelope envelope,
    required Set<int> acceptedSaveFormats,
  }) => _validate(runner, codec, envelope, acceptedSaveFormats);

  Future<Uint8List> encodeUtf8({
    required SaveEnvelopeCodec codec,
    required SaveEnvelope envelope,
  }) => _encodeUtf8(runner, codec, envelope);

  Future<SaveEnvelope> decode({
    required SaveEnvelopeCodec codec,
    required String source,
    required SaveSlotAddress address,
    required Set<int> acceptedSaveFormats,
  }) => _decode(runner, codec, source, address, acceptedSaveFormats);

  Future<SaveEnvelope> decodeCandidate({
    required SaveEnvelopeCodec codec,
    required String source,
    required SaveSlotAddress address,
    required int currentSaveFormat,
  }) => _decodeCandidate(runner, codec, source, address, currentSaveFormat);

  static Future<SaveEnvelope> _validate(
    HubSaveCodecRunner runner,
    SaveEnvelopeCodec codec,
    SaveEnvelope envelope,
    Set<int> acceptedSaveFormats,
  ) => _run(
    runner,
    () => codec.decodeJson(
      codec.toJson(envelope),
      expectedAddress: envelope.address,
      acceptedSaveFormats: acceptedSaveFormats,
    ),
    debugName: 'hub-save.validate',
  );

  static Future<Uint8List> _encodeUtf8(
    HubSaveCodecRunner runner,
    SaveEnvelopeCodec codec,
    SaveEnvelope envelope,
  ) => _run(
    runner,
    () => codec.encodeUtf8(envelope),
    debugName: 'hub-save.encode',
  );

  static Future<SaveEnvelope> _decode(
    HubSaveCodecRunner runner,
    SaveEnvelopeCodec codec,
    String source,
    SaveSlotAddress address,
    Set<int> acceptedSaveFormats,
  ) => _run(
    runner,
    () => codec.decode(
      source,
      expectedAddress: address,
      acceptedSaveFormats: acceptedSaveFormats,
    ),
    debugName: 'hub-save.decode',
  );

  static Future<SaveEnvelope> _decodeCandidate(
    HubSaveCodecRunner runner,
    SaveEnvelopeCodec codec,
    String source,
    SaveSlotAddress address,
    int currentSaveFormat,
  ) => _run(runner, () {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid save candidate.');
    }
    final format = decoded['saveFormat'];
    final envelope = codec.decodeJson(
      decoded,
      acceptedSaveFormats: {
        if (format is int && format <= currentSaveFormat) format,
      },
    );
    if (envelope.profileId != address.profileId ||
        envelope.slotId != address.slotId) {
      throw const SaveContractException(
        SaveContractErrorCode.addressMismatch,
        'Save profile/slot does not match its storage address.',
      );
    }
    return envelope;
  }, debugName: 'hub-save.decode-candidate');

  static Future<T> _run<T>(
    HubSaveCodecRunner runner,
    FutureOr<T> Function() computation, {
    required String debugName,
  }) async {
    try {
      return await runner(computation, debugName: debugName);
    } on FormatException {
      rethrow;
    } on HubSaveCodecExecutionException {
      rethrow;
    } catch (error, stackTrace) {
      throw HubSaveCodecExecutionException(
        operation: debugName,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
