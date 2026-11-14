import 'dart:async';

import 'package:avelune_studio/platform/files/native_resource_pack_export_sink.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'native_resource_pack_export_sink_channel.dart';

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
}
