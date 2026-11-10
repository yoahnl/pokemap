import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/resource_replacement_fixture.dart';
import '../support/run_resource_replacement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('cancelling the replacement picker preserves all files and releases its management lock', () async {
    final h = await ResourceReplacementFixture.create();
    final files = await h.files();
    await runReplacementForTest(
      navigation: h.navigation,
      item: h.item,
      picker: () async => null,
      isActive: () => true,
      shouldPresent: false,
      present: (_) async =>
          fail('Cancelled selection must not prepare a replacement'),
    );
    expect(h.navigation.managementDialogActive, isFalse);
    expect(h.navigation.busy, isFalse);
    expect(await h.files(), files);
  });

  test('replacement confirmation preserves identity and maps and cannot publish twice', () async {
    final h = await ResourceReplacementFixture.create();
    final candidate = await h.candidate();
    final old = h.item.tileset!;
    final map = await h.fixture.mapFile.readAsBytes();
    await runReplacementForTest(
      navigation: h.navigation,
      item: h.item,
      picker: () async => candidate,
      isActive: () => true,
      present: (session) async {
        expect(h.navigation.managementDialogActive, isTrue);
        expect(session.preview.preparation.noChange, isFalse);
        expect(session.canApply, isFalse);
        expect(await session.apply(), isNotNull);
        expect((await h.reopen()).tilesets.single, old);
        session.confirm(true);
        expect(await session.apply(), isNull);
        expect(session.canApply, isFalse);
        expect(await session.apply(), isNotNull);
      },
    );
    final published = (await h.reopen()).tilesets.single;
    expect(published.id, old.id);
    expect(published.source, old.source);
    expect(
      await File('${h.fixture.root.path}/${published.relativePath}')
          .readAsBytes(),
      candidate.bytes,
    );
    expect(await h.fixture.mapFile.readAsBytes(), map);
    expect(h.navigation.managementDialogActive, isFalse);
  });

  test(
    'identical replacement needs no confirmation and preserves exact files',
    () async {
      final h = await ResourceReplacementFixture.create();
      final bytes = Uint8List.fromList(await h.fixture.source.readAsBytes());
      final candidate = PickedResourceImage(
        h.fixture.source.path,
        'Identique',
        bytes,
        64,
        48,
      );
      final files = await h.files();
      await runReplacementForTest(
        navigation: h.navigation,
        item: h.item,
        picker: () async => candidate,
        isActive: () => true,
        present: (session) async {
          expect(session.preview.preparation.noChange, isTrue);
          expect(session.canApply, isTrue);
          expect(await session.apply(), isNull);
        },
      );
      expect(await h.files(), files);
    },
  );

  test('interrupted reconciliation retains publication and rereads it without replay', () async {
    var failReconciliation = true;
    final h = await ResourceReplacementFixture.create(
      beforeReconciliation: () async {
        if (failReconciliation) {
          throw StateError('Injected interface refresh failure');
        }
      },
    );
    final candidate = await h.candidate();
    await runReplacementForTest(
      navigation: h.navigation,
      item: h.item,
      picker: () async => candidate,
      isActive: () => true,
      present: (session) async {
        session.confirm(true);
        expect(await session.apply(), contains('Publication effectuée'));
        expect(h.navigation.pendingReceipt, isNotNull);
        expect(session.canApply, isFalse);
        final publishedFiles = await h.files();
        failReconciliation = false;
        expect(await h.navigation.retryReconciliation(), isTrue);
        expect(h.navigation.pendingReceipt, isNull);
        expect(session.canApply, isFalse);
        expect(await session.apply(), isNotNull);
        expect(await h.files(), publishedFiles);
      },
    );
    final published = (await h.reopen()).tilesets.single;
    expect(
      await File('${h.fixture.root.path}/${published.relativePath}')
          .readAsBytes(),
      candidate.bytes,
    );
    expect(h.navigation.pendingReceipt, isNull);
    expect((await h.reopen()).tilesets.single, published);
    expect(h.navigation.managementDialogActive, isFalse);
  });

  test('closing a replacement host waits for its in-flight publication before releasing preparation', () async {
    final entered = Completer<void>();
    final resume = Completer<void>();
    final h = await ResourceReplacementFixture.create(
      beforeReconciliation: () async {
        entered.complete();
        await resume.future;
      },
    );
    final candidate = await h.candidate();
    Future<String?>? applying;
    var closed = false;
    final operation = runReplacementForTest(
      navigation: h.navigation,
      item: h.item,
      picker: () async => candidate,
      isActive: () => true,
      present: (session) async {
        session.confirm(true);
        applying = session.apply();
        await entered.future;
        expect(session.applying, isTrue);
        expect(await session.apply(), isNotNull);
      },
    ).then((_) => closed = true);
    await entered.future;
    await pumpEventQueue();
    expect(closed, isFalse);
    expect(h.navigation.managementDialogActive, isTrue);
    resume.complete();
    await operation;
    expect(await applying, isNull);
    expect(h.navigation.managementDialogActive, isFalse);
    expect(closed, isTrue);
  });
}
