import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:avelune_converter/converter_app.dart';
import 'package:avelune_converter/updates/converter_update_catalog.dart';
import 'package:avelune_converter/updates/converter_update_host.dart';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../../packages/avelune_converter_adapters/test/support/original_asset_fixture.dart';
import 'converter_update_catalog_test.dart' show updateIndex;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.avelune.converter/updates');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets(
    'unsaved review cancellation keeps the conversion and never opens Sparkle',
    (tester) async {
      final fixture = (await tester.runAsync(_UpdateSession.create))!;
      try {
        await fixture.mount(tester);
        await tester.tap(
          find.byKey(const ValueKey('converter-install-update')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Conserver votre session de revue ?'), findsOneWidget);
        await tester.tap(find.widgetWithText(StudioButton, 'Rester'));
        await tester.pumpAndSettle();
        expect(calls, isEmpty);
        expect(fixture.workflow.state.cancellationRequested, isFalse);
        expect(fixture.workflow.state.prepared, isNotNull);
        expect(
          tester
              .widget<StudioButton>(
                find.byKey(const ValueKey('converter-install-update')),
              )
              .onPressed,
          isNotNull,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(fixture.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    'saving owns the barrier and consent survives through native restart and app exit',
    (tester) async {
      final entered = Completer<void>();
      final release = Completer<void>();
      final fixture = (await tester.runAsync(
        () => _UpdateSession.create(
          checkpoint: (stage, _) async {
            if (stage == LocalReviewSessionWriteStage.beforePublish) {
              entered.complete();
              await release.future;
            }
          },
        ),
      ))!;
      try {
        await fixture.mount(tester);
        await tester.tap(
          find.byKey(const ValueKey('converter-install-update')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(StudioButton, 'Enregistrer et fermer'),
        );
        await _wait(tester, () => entered.isCompleted);
        expect(calls, isEmpty);
        expect(
          await tester.binding.handleRequestAppExit(),
          AppExitResponse.cancel,
        );
        final host = tester.widget<ConverterUpdateHost>(
          find.byType(ConverterUpdateHost),
        );
        expect(await host.onRestartRequested(), isFalse);
        expect(host.installEnabled, isFalse);
        release.complete();
        await _wait(
          tester,
          () => calls.any((call) => call.method == 'openUpdateFlow'),
        );
        expect(
          await tester.binding.handleRequestAppExit(),
          AppExitResponse.exit,
        );
        expect(
          await tester
              .widget<ConverterUpdateHost>(find.byType(ConverterUpdateHost))
              .onRestartRequested(),
          isTrue,
        );
        expect((await tester.runAsync(fixture.store.list))!, hasLength(1));
      } finally {
        if (!release.isCompleted) release.complete();
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(fixture.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    'a late workflow job refuses restart without cancelling its work',
    (tester) async {
      final entered = Completer<void>();
      final release = Completer<void>();
      var hold = false;
      final fixture = (await tester.runAsync(
        () => _UpdateSession.create(
          workflowCheckpoint: (_, _, _) async {
            if (hold && !entered.isCompleted) {
              entered.complete();
              await release.future;
            }
          },
        ),
      ))!;
      try {
        await fixture.mount(tester);
        await tester.tap(
          find.byKey(const ValueKey('converter-install-update')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(StudioButton, 'Abandonner les changements'),
        );
        await tester.pumpAndSettle();
        expect(calls.single.method, 'openUpdateFlow');
        hold = true;
        var jobFinished = false;
        final job = fixture.workflow
            .scanSource(fixture.workflow.state.source!)
            .whenComplete(() => jobFinished = true);
        await _wait(tester, () => entered.isCompleted);
        expect(fixture.workflow.state.isBusy, isTrue);
        final host = tester.widget<ConverterUpdateHost>(
          find.byType(ConverterUpdateHost),
        );
        expect(await host.onRestartRequested(), isFalse);
        expect(
          await tester.binding.handleRequestAppExit(),
          AppExitResponse.cancel,
        );
        expect(fixture.workflow.state.cancellationRequested, isFalse);
        release.complete();
        await _wait(tester, () => jobFinished);
        await job;
      } finally {
        if (!release.isCompleted) release.complete();
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(fixture.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    'a session changed while consent is open cannot authorize its replacement',
    (tester) async {
      final fixture = (await tester.runAsync(_UpdateSession.create))!;
      try {
        await fixture.mount(tester);
        await tester.tap(
          find.byKey(const ValueKey('converter-install-update')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Conserver votre session de revue ?'), findsOneWidget);
        var jobFinished = false;
        final job = fixture.workflow
            .scanSource(fixture.workflow.state.source!)
            .whenComplete(() => jobFinished = true);
        await _wait(tester, () => jobFinished);
        await job;
        expect(fixture.workflow.state.isBusy, isFalse);
        await tester.tap(
          find.widgetWithText(StudioButton, 'Abandonner les changements'),
        );
        await tester.pumpAndSettle();
        expect(calls, isEmpty);
        expect(
          tester
              .widget<StudioButton>(
                find.byKey(const ValueKey('converter-install-update')),
              )
              .onPressed,
          isNotNull,
        );
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(fixture.close);
      }
    },
    skip: !Platform.isMacOS,
  );

  testWidgets(
    'failed session saving cancels update and keeps the review editable',
    (tester) async {
      final fixture = (await tester.runAsync(
        () => _UpdateSession.create(
          checkpoint: (stage, _) {
            if (stage == LocalReviewSessionWriteStage.beforePublish) {
              throw const FileSystemException('Controlled update save failure');
            }
          },
        ),
      ))!;
      try {
        await fixture.mount(tester);
        final hash = fixture.workflow.state.prepared!.reviewSet!.canonicalHash;
        await tester.tap(
          find.byKey(const ValueKey('converter-install-update')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(StudioButton, 'Enregistrer et fermer'),
        );
        await _wait(
          tester,
          () => find
              .textContaining('La mise à jour n’a pas été lancée')
              .evaluate()
              .isNotEmpty,
        );
        expect(calls, isEmpty);
        expect(fixture.workflow.state.prepared!.reviewSet!.canonicalHash, hash);
        expect(
          tester
              .widget<ConverterUpdateHost>(find.byType(ConverterUpdateHost))
              .installEnabled,
          isTrue,
        );
        expect((await tester.runAsync(fixture.store.list))!, isEmpty);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(fixture.close);
      }
    },
    skip: !Platform.isMacOS,
  );
}

Future<void> _wait(WidgetTester tester, bool Function() condition) async {
  final elapsed = Stopwatch()..start();
  while (!condition() && elapsed.elapsed < const Duration(seconds: 8)) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 10));
  }
  expect(condition(), isTrue);
}

final class _UpdateSession {
  _UpdateSession(
    this.root,
    this.fixture,
    this.store,
    this.workflow,
    this.client,
  );

  final Directory root;
  final OriginalAssetFixture fixture;
  final LocalReviewSessionStore store;
  final ConverterWorkflow workflow;
  final http.Client client;

  static Future<_UpdateSession> create({
    LocalReviewSessionWriteCheckpoint? checkpoint,
    ConverterWorkflowCheckpoint? workflowCheckpoint,
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'converter-update-session-',
    );
    final fixture = await OriginalAssetFixture.create(
      sourceRootPath: '${root.path}/source',
    );
    await Directory('${root.path}/output').create();
    return _UpdateSession(
      root,
      fixture,
      LocalReviewSessionStore(
        rootPath: '${root.path}/reviews',
        checkpoint: checkpoint,
      ),
      ConverterWorkflow(checkpoint: workflowCheckpoint),
      MockClient((_) async => http.Response(jsonEncode(updateIndex()), 200)),
    );
  }

  Future<void> mount(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ConverterApp(
        workflow: workflow,
        sessionStore: store,
        initialSourcePath: fixture.literalFixture.sourceRootPath!,
        initialParentPath: '${root.path}/output',
        updateCatalog: ConverterUpdateCatalog(client),
        updateBuildLoader: () async =>
            const ConverterInstalledBuild(version: '0.1.0', buildNumber: 1),
        updatePlatformSupported: true,
        automaticUpdateCheck: false,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('analyse-project')));
    await _wait(
      tester,
      () => workflow.state.snapshot != null && !workflow.state.isBusy,
    );
    await tester.ensureVisible(find.text('Tout sélectionner'));
    await tester.tap(find.text('Tout sélectionner'));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('prepare-study')));
    await _wait(
      tester,
      () => workflow.state.prepared != null && !workflow.state.isBusy,
    );
    await tester.tap(find.byKey(const ValueKey('converter-check-updates')));
    await tester.pumpAndSettle();
  }

  Future<void> close() async {
    client.close();
    await workflow.dispose().timeout(const Duration(seconds: 5));
    await root.delete(recursive: true);
  }
}
