import 'dart:async';

import 'package:avelune_studio/platform/files/native_resource_pack_export_sink.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/resource-pack-writer');
  late PackNativeChannel native;
  setUp(() {
    native = PackNativeChannel();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, native.call);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'bounded chunks wait for append before read and seal precedes finalization',
    () async {
      final sink = NativeResourcePackExportSink(channel: channel);
      final reads = <int>[];
      final data = Uint8List(300000);
      native.appendGate = Completer<void>();
      final operation = sink.publish(
        suggestedName: 'Original.aveluneassets',
        byteLength: data.length,
        rawSha256: 'a' * 64,
        readChunk: (offset, length) async {
          reads.add(offset);
          expect(length, lessThanOrEqualTo(128 * 1024));
          return data.sublist(offset, offset + length);
        },
        isCancelled: () => false,
        enterFinalization: () {
          expect(native.methods.last, 'resourcePackExportSeal');
          native.methods.add('barrier');
        },
      );
      await native.appendEntered.future;
      expect(reads, [0]);
      native.appendGate!.complete();
      final result = await operation;
      expect(result.published, isTrue);
      expect(result.path, '/native/Original.aveluneassets');
      expect(reads, [0, 131072, 262144]);
      expect(
        native.methods.indexOf('barrier'),
        lessThan(native.methods.indexOf('resourcePackExportFinish')),
      );
      expect(native.methods.last, 'resourcePackExportRelease');
      expect(native.offset, 300000);
    },
  );
  test(
    'late native folder choice releases its owner after close was requested',
    () async {
      var cancelled = false;
      native.chooseGate = Completer<void>();
      final choosing = NativeResourcePackExportSink(channel: channel).publish(
        suggestedName: 'Pack.aveluneassets',
        byteLength: 3,
        rawSha256: 'a' * 64,
        readChunk: (_, _) async {
          fail('close requested before native choice returned');
        },
        isCancelled: () => cancelled,
        enterFinalization: () {
          fail('cancelled before publication');
        },
      );
      await native.chooseEntered.future;
      cancelled = true;
      native.chooseGate!.complete();
      final result = await choosing;
      expect(result.published, isFalse);
      expect(native.methods, [
        'resourcePackExportChoose',
        'resourcePackExportRelease',
      ]);
    },
  );
  test(
    'cancelled folder picker reads no payload and has no publication',
    () async {
      native.cancelPicker = true;
      final result = await NativeResourcePackExportSink(channel: channel)
          .publish(
            suggestedName: 'Pack.aveluneassets',
            byteLength: 3,
            rawSha256: 'a' * 64,
            readChunk: (_, _) async {
              fail('cancelled picker');
            },
            isCancelled: () => false,
            enterFinalization: () {
              fail('cancelled picker');
            },
          );
      expect(result.published, isFalse);
      expect(native.methods, ['resourcePackExportChoose']);
    },
  );
  test(
    'cancellation after seal releases the native stage without finish',
    () async {
      var cancelled = false;
      native.onSeal = () {
        cancelled = true;
      };
      final result = await NativeResourcePackExportSink(channel: channel)
          .publish(
            suggestedName: 'Pack.aveluneassets',
            byteLength: 3,
            rawSha256: 'a' * 64,
            readChunk: (_, _) async => [1, 2, 3],
            isCancelled: () => cancelled,
            enterFinalization: () {
              fail('cancelled before barrier');
            },
          );
      expect(result.published, isFalse);
      expect(native.methods, isNot(contains('resourcePackExportFinish')));
      expect(native.methods.last, 'resourcePackExportRelease');
    },
  );
  test(
    'invalid source chunks and seal errors release the temporary owner',
    () async {
      for (final mode in ['empty', 'oversize', 'seal']) {
        native = PackNativeChannel();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, native.call);
        if (mode == 'seal') native.sealError = true;
        await expectLater(
          NativeResourcePackExportSink(channel: channel).publish(
            suggestedName: 'Pack.aveluneassets',
            byteLength: 3,
            rawSha256: 'a' * 64,
            readChunk: (_, _) async => mode == 'empty'
                ? []
                : mode == 'oversize'
                ? [1, 2, 3, 4]
                : [1, 2, 3],
            isCancelled: () => false,
            enterFinalization: () {
              fail('invalid input');
            },
          ),
          throwsA(anything),
        );
        expect(native.methods.last, 'resourcePackExportRelease');
        expect(native.methods, isNot(contains('resourcePackExportFinish')));
      }
    },
  );
  test(
    'lost finish reply is recovered by status without a second rename',
    () async {
      native.loseFinish = true;
      final result = await NativeResourcePackExportSink(channel: channel)
          .publish(
            suggestedName: 'Pack.aveluneassets',
            byteLength: 3,
            rawSha256: 'a' * 64,
            readChunk: (_, _) async => [1, 2, 3],
            isCancelled: () => false,
            enterFinalization: () {},
          );
      expect(result.published, isTrue);
      expect(
        native.methods.where((m) => m == 'resourcePackExportFinish'),
        hasLength(1),
      );
      expect(native.methods, contains('resourcePackExportStatus'));
    },
  );
  test(
    'a nonterminal native status after lost finish remains pending',
    () async {
      native.loseFinish = true;
      native.statusState = 'sealed';
      final sink = NativeResourcePackExportSink(channel: channel);
      final outcome = await sink.publish(
        suggestedName: 'Pack.aveluneassets',
        byteLength: 3,
        rawSha256: 'a' * 64,
        readChunk: (_, _) async => [1, 2, 3],
        isCancelled: () => false,
        enterFinalization: () {},
      );
      expect(outcome.pendingToken, 'native-token');
      expect(native.methods, isNot(contains('resourcePackExportRelease')));
      native.statusState = 'published';
      expect(
        (await sink.reconcilePublication(outcome.pendingToken!)).published,
        isTrue,
      );
      expect(
        native.methods.where((m) => m == 'resourcePackExportFinish'),
        hasLength(1),
      );
    },
  );
  test(
    'unknown finish and status retain token then reconcile status only',
    () async {
      final sink = NativeResourcePackExportSink(channel: channel);
      native.loseFinish = true;
      native.loseStatus = true;
      final result = await sink.publish(
        suggestedName: 'Pack.aveluneassets',
        byteLength: 3,
        rawSha256: 'a' * 64,
        readChunk: (_, _) async => [1, 2, 3],
        isCancelled: () => false,
        enterFinalization: () {},
      );
      expect(result.pendingToken, 'native-token');
      expect(result.published, isFalse);
      expect(native.methods, isNot(contains('resourcePackExportRelease')));
      native.loseStatus = false;
      native.releaseError = true;
      final recovered = await sink.reconcilePublication(result.pendingToken!);
      expect(recovered.published, isTrue);
      expect(recovered.warning, contains('cleanup'));
      expect(
        native.methods.where((m) => m == 'resourcePackExportFinish'),
        hasLength(1),
      );
    },
  );
  for (final interruption in ['cancellation', 'source', 'seal']) {
    test(
      '$interruption cleanup failure retains its owner until release',
      () async {
        final sink = NativeResourcePackExportSink(channel: channel);
        native.releaseError = true;
        native.sealError = interruption == 'seal';
        final outcome = await sink.publish(
          suggestedName: 'Pack.aveluneassets',
          byteLength: 3,
          rawSha256: 'a' * 64,
          readChunk: (_, _) async {
            if (interruption == 'source') {
              throw StateError('source unavailable');
            }
            return [1, 2, 3];
          },
          isCancelled: () => interruption == 'cancellation',
          enterFinalization: () => fail('interrupted before publication'),
        );
        expect(outcome.pendingToken, 'native-token');
        expect(outcome.published, isFalse);
        expect(outcome.warning, contains('cleanup'));
        final before = native.methods.length;
        native.releaseError = false;
        native.loseStatus = true;
        final released = await sink.reconcilePublication(outcome.pendingToken!);
        expect(released.pendingToken, isNull);
        expect(released.published, isFalse);
        expect(native.methods.sublist(before), ['resourcePackExportRelease']);
        expect(native.methods, isNot(contains('resourcePackExportFinish')));
        await expectLater(
          sink.reconcilePublication(outcome.pendingToken!),
          throwsA(anything),
        );
      },
    );
  }
  test(
    'confirmed failed publication retries a lost release reply directly',
    () async {
      final sink = NativeResourcePackExportSink(channel: channel);
      native.loseFinish = true;
      native.loseStatus = true;
      final unknown = await sink.publish(
        suggestedName: 'Pack.aveluneassets',
        byteLength: 3,
        rawSha256: 'a' * 64,
        readChunk: (_, _) async => [1, 2, 3],
        isCancelled: () => false,
        enterFinalization: () {},
      );
      native.loseStatus = false;
      native.statusState = 'failed';
      native.loseReleaseReply = true;
      final cleanup = await sink.reconcilePublication(unknown.pendingToken!);
      expect(cleanup.pendingToken, 'native-token');
      expect(native.released, isTrue);
      final before = native.methods.length;
      final completed = await sink.reconcilePublication(cleanup.pendingToken!);
      expect(completed.pendingToken, isNull);
      expect(completed.published, isFalse);
      expect(completed.warning, contains('publication'));
      expect(native.methods.sublist(before), ['resourcePackExportRelease']);
      expect(native.releaseAttempts, 2);
      expect(
        native.methods.where((m) => m == 'resourcePackExportFinish'),
        hasLength(1),
      );
    },
  );
}

class PackNativeChannel {
  final methods = <String>[];
  String statusState = "published";
  int offset = 0;
  int releaseAttempts = 0;
  bool released = false, loseReleaseReply = false;
  bool cancelPicker = false,
      sealError = false,
      loseFinish = false,
      loseStatus = false,
      releaseError = false;
  Completer<void>? appendGate, chooseGate;
  final chooseEntered = Completer<void>();
  final appendEntered = Completer<void>();
  void Function()? onSeal;
  Future<Object?> call(MethodCall call) async {
    methods.add(call.method);
    final input = call.arguments as Map;
    switch (call.method) {
      case 'resourcePackExportChoose':
        if (!chooseEntered.isCompleted) chooseEntered.complete();
        if (chooseGate != null) await chooseGate!.future;
        expect(input['suggestedName'], endsWith('.aveluneassets'));
        return cancelPicker
            ? null
            : {'token': 'native-token', 'state': 'writing'};
      case 'resourcePackExportAppend':
        expect(input['token'], 'native-token');
        expect(input['offset'], offset);
        final bytes = input['bytes'] as Uint8List;
        expect(bytes.length, lessThanOrEqualTo(128 * 1024));
        offset += bytes.length;
        if (!appendEntered.isCompleted) appendEntered.complete();
        if (appendGate != null) await appendGate!.future;
        return {'state': 'writing'};
      case 'resourcePackExportSeal':
        if (sealError) throw PlatformException(code: 'hash_mismatch');
        onSeal?.call();
        return {'state': 'sealed'};
      case 'resourcePackExportFinish':
        if (loseFinish) throw PlatformException(code: 'lost_finish');
        return {'state': 'published', 'path': '/native/Original.aveluneassets'};
      case 'resourcePackExportStatus':
        if (released) throw PlatformException(code: 'handle_unknown');
        if (loseStatus) throw PlatformException(code: 'lost_status');
        return {'state': statusState, 'path': '/native/Original.aveluneassets'};
      case 'resourcePackExportRelease':
        releaseAttempts++;
        if (releaseError) throw PlatformException(code: 'cleanup');
        released = true;
        if (loseReleaseReply) {
          loseReleaseReply = false;
          throw PlatformException(code: 'lost_release_reply');
        }
        return {'released': true};
      default:
        throw StateError(call.method);
    }
  }
}
