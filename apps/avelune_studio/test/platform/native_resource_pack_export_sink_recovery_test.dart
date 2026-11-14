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
