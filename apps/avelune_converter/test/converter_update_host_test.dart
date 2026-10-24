import 'dart:async';
import 'dart:convert';

import 'package:avelune_converter/updates/converter_update_catalog.dart';
import 'package:avelune_converter/updates/converter_update_host.dart';
import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'converter_update_catalog_test.dart' show updateIndex;

void main() {
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

  Future<void> incoming(String kind, String operationId) async {
    final completer = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('updateEvent', {
              'operationId': operationId,
              'kind': kind,
            }),
          ),
          (_) => completer.complete(),
        );
    await completer.future;
  }

  Future<void> pump(
    WidgetTester tester, {
    required Future<bool> Function() prepare,
    Future<bool> Function()? restart,
    required VoidCallback finished,
    int status = 200,
  }) async {
    final client = MockClient(
      (_) async =>
          http.Response(status == 200 ? jsonEncode(updateIndex()) : '', status),
    );
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: ConverterUpdateHost(
            catalog: ConverterUpdateCatalog(client),
            installedBuild: () async =>
                const ConverterInstalledBuild(version: '0.1.0', buildNumber: 1),
            platformSupported: true,
            automaticCheck: false,
            onPrepareUpdate: prepare,
            onRestartRequested: restart ?? () async => true,
            onOperationEnded: finished,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('converter-check-updates')));
    for (var frame = 0; frame < 100; frame++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
      await tester.pump(const Duration(milliseconds: 10));
      if (tester
              .widget<StudioButton>(
                find.byKey(const ValueKey('converter-check-updates')),
              )
              .onPressed !=
          null) {
        return;
      }
    }
    fail('The update check did not complete.');
  }

  testWidgets('cancelled session consent never enters the native installer', (
    tester,
  ) async {
    var ended = 0;
    await pump(tester, prepare: () async => false, finished: () => ended++);
    await tester.tap(find.byKey(const ValueKey('converter-install-update')));
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == 'openUpdateFlow'), isEmpty);
    expect(ended, 1);
    expect(find.textContaining('conservée'), findsOneWidget);
  });

  testWidgets(
    'installation waits for session saving and ignores stale native events',
    (tester) async {
      final saved = Completer<bool>();
      var ended = 0;
      await pump(tester, prepare: () => saved.future, finished: () => ended++);
      await tester.tap(find.byKey(const ValueKey('converter-install-update')));
      await tester.pump();
      expect(calls, isEmpty);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('converter-install-update')),
            )
            .onPressed,
        isNull,
      );
      saved.complete(true);
      await tester.pumpAndSettle();
      final operation =
          (calls.single.arguments as Map)['operationId'] as String;
      await incoming('failed', 'obsolete-operation');
      await tester.pump();
      expect(ended, 0);
      await incoming('cancelled', operation);
      await tester.pump();
      expect(ended, 1);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('converter-install-update')),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'late busy restart refusal replies false and releases the barrier',
    (tester) async {
      var busy = false;
      var ended = 0;
      await pump(
        tester,
        prepare: () async => true,
        restart: () async => !busy,
        finished: () => ended++,
      );
      await tester.tap(find.byKey(const ValueKey('converter-install-update')));
      await tester.pumpAndSettle();
      final operation =
          (calls.single.arguments as Map)['operationId'] as String;
      busy = true;
      await incoming('restartRequested', operation);
      await tester.pumpAndSettle();
      expect(calls.last.method, 'respondToRestart');
      expect(calls.last.arguments, {
        'operationId': operation,
        'canRestart': false,
      });
      expect(ended, 1);
      expect(find.textContaining('occupé'), findsOneWidget);
    },
  );

  for (final terminal in ['failed', 'cancelled', 'finished']) {
    testWidgets('$terminal ends only its current operation', (tester) async {
      var ended = 0;
      await pump(tester, prepare: () async => true, finished: () => ended++);
      await tester.tap(find.byKey(const ValueKey('converter-install-update')));
      await tester.pumpAndSettle();
      final operation =
          (calls.single.arguments as Map)['operationId'] as String;
      await incoming(terminal, operation);
      await incoming(terminal, operation);
      await tester.pumpAndSettle();
      expect(ended, 1);
    });
  }

  testWidgets(
    '404 gives an unpublished channel notice without an install offer',
    (tester) async {
      await pump(
        tester,
        status: 404,
        prepare: () async => true,
        finished: () {},
      );
      expect(find.textContaining('pas encore publié'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('converter-install-update')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'an unconfigured native updater stays unavailable without locking the session',
    (tester) async {
      var ended = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            throw PlatformException(code: 'native_update_unconfigured');
          });
      await pump(tester, prepare: () async => true, finished: () => ended++);
      await tester.tap(find.byKey(const ValueKey('converter-install-update')));
      await tester.pumpAndSettle();
      expect(ended, 1);
      expect(find.textContaining('mises à jour signées'), findsOneWidget);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('converter-install-update')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'an operation cancelled during a delayed restart never replies with stale consent',
    (tester) async {
      final restart = Completer<bool>();
      var attempts = 0;
      var ended = 0;
      await pump(
        tester,
        prepare: () async => true,
        restart: () => ++attempts == 1 ? Future.value(true) : restart.future,
        finished: () => ended++,
      );
      await tester.tap(find.byKey(const ValueKey('converter-install-update')));
      await tester.pumpAndSettle();
      final operation =
          (calls.single.arguments as Map)['operationId'] as String;
      final pending = incoming('restartRequested', operation);
      await tester.pump();
      await incoming('cancelled', operation);
      restart.complete(true);
      await pending;
      await tester.pumpAndSettle();
      expect(ended, 1);
      expect(calls.where((call) => call.method == 'respondToRestart'), isEmpty);
    },
  );

  testWidgets(
    'accepted restart retains consent until its native operation finishes',
    (tester) async {
      var ended = 0;
      await pump(tester, prepare: () async => true, finished: () => ended++);
      await tester.tap(find.byKey(const ValueKey('converter-install-update')));
      await tester.pumpAndSettle();
      final operation =
          (calls.single.arguments as Map)['operationId'] as String;
      await incoming('restartRequested', operation);
      await tester.pump();
      expect(calls.last.arguments, {
        'operationId': operation,
        'canRestart': true,
      });
      expect(ended, 0);
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('converter-install-update')),
            )
            .onPressed,
        isNull,
      );
      await incoming('finished', operation);
      await tester.pump();
      expect(ended, 1);
    },
  );

  testWidgets('a local build reports unavailable before requesting its feed', (
    tester,
  ) async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response(jsonEncode(updateIndex()), 200);
    });
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: ConverterUpdateHost(
            catalog: ConverterUpdateCatalog(client),
            platformSupported: true,
            automaticCheck: false,
            onPrepareUpdate: () async => true,
            onRestartRequested: () async => true,
            onOperationEnded: () {},
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('converter-check-updates')));
    await tester.pumpAndSettle();
    expect(find.textContaining('compilation locale'), findsOneWidget);
    expect(requests, 0);
    expect(calls, isEmpty);
    expect(
      find.byKey(const ValueKey('converter-install-update')),
      findsNothing,
    );
  });

  testWidgets('disposing cancels an automatic check before its timer fires', (
    tester,
  ) async {
    var requests = 0;
    final client = MockClient((_) async {
      requests++;
      return http.Response('', 404);
    });
    addTearDown(client.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: ConverterUpdateHost(
            catalog: ConverterUpdateCatalog(client),
            installedBuild: () async =>
                const ConverterInstalledBuild(version: '0.1.0', buildNumber: 1),
            platformSupported: true,
            automaticCheck: true,
            onPrepareUpdate: () async => true,
            onRestartRequested: () async => true,
            onOperationEnded: () {},
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 15));
    expect(requests, 0);
  });

  testWidgets('disposing removes the native handler and active operation', (
    tester,
  ) async {
    var ended = 0;
    await pump(tester, prepare: () async => true, finished: () => ended++);
    await tester.tap(find.byKey(const ValueKey('converter-install-update')));
    await tester.pumpAndSettle();
    final operation = (calls.single.arguments as Map)['operationId'] as String;
    await tester.pumpWidget(const SizedBox());
    expect(ended, 1);
    await incoming('restartRequested', operation);
    expect(calls.where((call) => call.method == 'respondToRestart'), isEmpty);
  });
}
