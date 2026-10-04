import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/embedding/avelune_runtime_app.dart';
import 'package:pokemap_hub/embedding/avelune_surface_probe.dart';
import 'package:pokemap_hub/embedding/avelune_surface_probe_app.dart';

const _codec = StandardMethodCodec();

Map<String, Object?> _payload({
  String sessionId = 'session-1',
  int value = 0,
  int revision = 0,
  bool attached = false,
}) => {
  'sessionId': sessionId,
  'value': value,
  'revision': revision,
  'companionAttached': attached,
};

Map<Object?, Object?> _intent({
  String sessionId = 'session-1',
  String sourceId = 'companion-1',
  int sequence = 1,
}) => {
  'sessionId': sessionId,
  'sourceId': sourceId,
  'sequence': sequence,
  'action': 'increment',
};

Matcher _platformError(String code) => throwsA(
  isA<PlatformException>().having((error) => error.code, 'code', code),
);

Future<Object?> _invoke(
  MethodChannel channel,
  String method, [
  Object? arguments,
]) {
  final result = Completer<Object?>();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        channel.name,
        _codec.encodeMethodCall(MethodCall(method, arguments)),
        (data) {
          try {
            if (data == null) throw MissingPluginException();
            result.complete(_codec.decodeEnvelope(data));
          } on Object catch (error) {
            result.completeError(error);
          }
        },
      );
  return result.future;
}

Future<void> _settleMessages() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  group('AveluneSurfaceProbeSnapshot', () {
    test('round trips the complete canonical payload', () {
      final payload = _payload(value: 4, revision: 7, attached: true);
      final snapshot = AveluneSurfaceProbeSnapshot.fromPayload(payload);

      expect(snapshot.sessionId, 'session-1');
      expect(snapshot.value, 4);
      expect(snapshot.revision, 7);
      expect(snapshot.companionAttached, isTrue);
      expect(snapshot.toPayload(), payload);
    });

    test('rejects incomplete, mistyped, and negative payload fields', () {
      final invalid = <Object?>[
        null,
        [],
        {},
        {..._payload(), 'sessionId': ''},
        {..._payload(), 'sessionId': 1},
        {..._payload(), 'value': -1},
        {..._payload(), 'value': 1.0},
        {..._payload(), 'value': '1'},
        {..._payload(), 'revision': -1},
        {..._payload(), 'revision': 1.0},
        {..._payload(), 'companionAttached': 'false'},
        _payload()..remove('companionAttached'),
      ];

      for (final payload in invalid) {
        expect(
          () => AveluneSurfaceProbeSnapshot.fromPayload(payload),
          throwsFormatException,
          reason: '$payload',
        );
      }
    });
  });

  group('AveluneSurfaceProbeController', () {
    late AveluneSurfaceProbeController controller;

    setUp(() => controller = AveluneSurfaceProbeController());
    tearDown(() => controller.dispose());

    test('starts idle and initializes the canonical owner state', () {
      expect(controller.value, isNull);

      controller.start('session-1');

      expect(controller.value!.toPayload(), _payload());
    });

    test('repeating the active session preserves its state and ledger', () {
      controller.start('session-1');
      controller.applyIntent(_intent());
      controller.setCompanionAttached(true);

      controller.start('session-1');
      final duplicate = controller.applyIntent(_intent());

      expect(
        duplicate.toPayload(),
        _payload(value: 1, revision: 2, attached: true),
      );
    });

    test(
      'a new session resets the counter, connection, and sequence ledger',
      () {
        controller.start('session-1');
        controller.applyIntent(_intent(sequence: 4));
        controller.setCompanionAttached(true);

        controller.start('session-2');

        expect(controller.value!.toPayload(), _payload(sessionId: 'session-2'));
        expect(
          controller.applyIntent(_intent(sessionId: 'session-2')).toPayload(),
          _payload(sessionId: 'session-2', value: 1, revision: 1),
        );
      },
    );

    test('attachment changes revision without changing the counter', () {
      controller.start('session-1');
      controller.applyIntent(_intent());

      controller.setCompanionAttached(true);
      expect(
        controller.value!.toPayload(),
        _payload(value: 1, revision: 2, attached: true),
      );

      controller.setCompanionAttached(true);
      expect(controller.value!.revision, 2);

      controller.setCompanionAttached(false);
      expect(controller.value!.toPayload(), _payload(value: 1, revision: 3));
    });

    test(
      'each accepted increment changes canonical value and revision once',
      () {
        controller.start('session-1');

        final first = controller.applyIntent(_intent());
        final second = controller.applyIntent(_intent(sequence: 2));

        expect(first.toPayload(), _payload(value: 1, revision: 1));
        expect(second.toPayload(), _payload(value: 2, revision: 2));
        expect(controller.value, same(second));
      },
    );

    test(
      'duplicate and older source sequences return the current snapshot',
      () {
        controller.start('session-1');
        final accepted = controller.applyIntent(_intent(sequence: 3));

        expect(controller.applyIntent(_intent(sequence: 3)), same(accepted));
        expect(controller.applyIntent(_intent(sequence: 1)), same(accepted));
        expect(controller.value!.toPayload(), _payload(value: 1, revision: 1));
      },
    );

    test('source sequences are independent', () {
      controller.start('session-1');
      controller.applyIntent(_intent());
      controller.applyIntent(_intent(sourceId: 'owner-1'));

      expect(controller.value!.toPayload(), _payload(value: 2, revision: 2));
      expect(controller.applyIntent(_intent()).value, 2);
    });

    test('stale sessions cannot change state or consume a source sequence', () {
      controller.start('session-1');

      expect(
        () => controller.applyIntent(_intent(sessionId: 'session-old')),
        _platformError('staleSession'),
      );
      expect(controller.value!.toPayload(), _payload());
      expect(controller.applyIntent(_intent()).value, 1);
    });

    test(
      'invalid intents cannot change state or consume a source sequence',
      () {
        controller.start('session-1');
        final invalid = <Map<Object?, Object?>>[
          {},
          {..._intent(), 'sessionId': ''},
          {..._intent(), 'sourceId': ''},
          {..._intent(), 'sourceId': 1},
          {..._intent(), 'sequence': 0},
          {..._intent(), 'sequence': -1},
          {..._intent(), 'sequence': 1.0},
          {..._intent(), 'action': 'decrement'},
          {..._intent(), 'action': null},
        ];

        for (final intent in invalid) {
          expect(
            () => controller.applyIntent(intent),
            _platformError('invalidIntent'),
            reason: '$intent',
          );
        }
        expect(controller.value!.toPayload(), _payload());
        expect(controller.applyIntent(_intent()).value, 1);
      },
    );

    test('inactive intents fail without creating a session', () {
      expect(
        () => controller.applyIntent(_intent()),
        _platformError('probeInactive'),
      );
      expect(controller.value, isNull);
    });

    test('stop clears the session and restarting clears deduplication', () {
      controller.start('session-1');
      controller.applyIntent(_intent());

      controller.stop();
      expect(controller.value, isNull);

      controller.start('session-1');
      expect(
        controller.applyIntent(_intent()).toPayload(),
        _payload(value: 1, revision: 1),
      );
    });
  });

  group('AveluneSurfaceProbeBridge', () {
    const channel = MethodChannel('avelune.test.surface_probe.owner');
    late AveluneSurfaceProbeController controller;
    late AveluneSurfaceProbeBridge bridge;
    late List<MethodCall> notifications;
    var canStart = true;

    setUp(() {
      controller = AveluneSurfaceProbeController();
      notifications = [];
      canStart = true;
      messenger.setMockMethodCallHandler(channel, (call) async {
        notifications.add(call);
        return null;
      });
      bridge = AveluneSurfaceProbeBridge(
        controller,
        channel: channel,
        canStart: () => canStart,
      );
      bridge.attach();
    });

    tearDown(() {
      bridge.detach();
      controller.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });

    test(
      'handles canonical start, attachment, intent, snapshot, and stop',
      () async {
        expect(await _invoke(channel, 'snapshot'), isNull);
        expect(
          await _invoke(channel, 'start', {'sessionId': 'session-1'}),
          _payload(),
        );
        expect(
          await _invoke(channel, 'setCompanionAttached', {'attached': true}),
          _payload(revision: 1, attached: true),
        );
        expect(
          await _invoke(channel, 'intent', _intent()),
          _payload(value: 1, revision: 2, attached: true),
        );
        expect(
          await _invoke(channel, 'snapshot'),
          _payload(value: 1, revision: 2, attached: true),
        );
        expect(await _invoke(channel, 'stop'), isNull);
        expect(controller.value, isNull);
      },
    );

    test('notifies the shell for owner updates and stop', () async {
      controller.start('session-1');
      controller.setCompanionAttached(true);
      controller.applyIntent(_intent());
      controller.stop();
      await _settleMessages();

      expect(
        notifications
            .where((call) => call.method == 'stateChanged')
            .map((call) => call.arguments),
        [
          _payload(),
          _payload(revision: 1, attached: true),
          _payload(value: 1, revision: 2, attached: true),
          null,
        ],
      );
    });

    test('a duplicate intent does not notify or advance owner state', () async {
      await _invoke(channel, 'start', {'sessionId': 'session-1'});
      await _invoke(channel, 'intent', _intent());
      await _settleMessages();
      notifications.clear();

      expect(
        await _invoke(channel, 'intent', _intent()),
        _payload(value: 1, revision: 1),
      );
      await _settleMessages();

      expect(notifications, isEmpty);
    });

    test('a running game prevents starting the debug probe', () async {
      canStart = false;

      await expectLater(
        _invoke(channel, 'start', {'sessionId': 'session-1'}),
        _platformError('runtimeBusy'),
      );
      expect(controller.value, isNull);
    });

    test(
      'surfaces protocol failures without changing canonical state',
      () async {
        await expectLater(
          _invoke(channel, 'intent', _intent()),
          _platformError('probeInactive'),
        );
        await _invoke(channel, 'start', {'sessionId': 'session-1'});
        await expectLater(
          _invoke(channel, 'intent', _intent(sessionId: 'session-old')),
          _platformError('staleSession'),
        );
        await expectLater(
          _invoke(channel, 'intent', []),
          _platformError('invalidIntent'),
        );
        expect(controller.value!.toPayload(), _payload());
      },
    );

    test(
      'detach removes the handler and leaves the owner controller usable',
      () async {
        bridge.detach();
        await expectLater(
          _invoke(channel, 'snapshot'),
          throwsA(isA<MissingPluginException>()),
        );

        controller.start('session-1');
        await _settleMessages();

        expect(controller.value!.toPayload(), _payload());
        expect(notifications, isEmpty);
      },
    );
  });

  group('AveluneCompanionProbeBridge', () {
    const channel = MethodChannel('avelune.test.surface_probe.companion');
    late AveluneCompanionProbeBridge bridge;
    late List<MethodCall> outbound;
    late Future<Object?> Function(MethodCall) nativeHandler;

    setUp(() async {
      outbound = [];
      nativeHandler = (_) async => null;
      messenger.setMockMethodCallHandler(channel, (call) {
        outbound.add(call);
        return nativeHandler(call);
      });
      bridge = AveluneCompanionProbeBridge(channel: channel);
      bridge.attach();
      await _settleMessages();
    });

    tearDown(() {
      bridge.detach();
      bridge.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('announces readiness and projects host notifications', () async {
      expect(outbound.map((call) => call.method), ['companionReady']);
      expect(bridge.value, isNull);

      await _invoke(
        channel,
        'stateChanged',
        _payload(value: 2, revision: 3, attached: true),
      );

      expect(
        bridge.value!.toPayload(),
        _payload(value: 2, revision: 3, attached: true),
      );
      await _invoke(channel, 'stateChanged');
      expect(bridge.value, isNull);
    });

    test(
      'late readiness replies cannot replace a newer host projection',
      () async {
        bridge.detach();
        bridge.dispose();
        final reply = Completer<Object?>();
        nativeHandler = (_) => reply.future;
        bridge = AveluneCompanionProbeBridge(channel: channel);
        final attaching = bridge.attach();
        await _settleMessages();

        await _invoke(
          channel,
          'stateChanged',
          _payload(sessionId: 'session-2', value: 5, revision: 8),
        );
        reply.complete(_payload(value: 1, revision: 1));
        await attaching;

        expect(
          bridge.value!.toPayload(),
          _payload(sessionId: 'session-2', value: 5, revision: 8),
        );
      },
    );

    test(
      'increment waits for canonical host state instead of mutating locally',
      () async {
        final reply = Completer<Object?>();
        nativeHandler =
            (call) =>
                call.method == 'intent' ? reply.future : Future.value(null);
        await _invoke(
          channel,
          'stateChanged',
          _payload(value: 2, revision: 3, attached: true),
        );

        final increment = bridge.increment();
        await _settleMessages();

        expect(
          bridge.value!.toPayload(),
          _payload(value: 2, revision: 3, attached: true),
        );
        final intent = outbound.last;
        expect(intent.method, 'intent');
        final arguments = intent.arguments as Map;
        expect(arguments['sessionId'], 'session-1');
        expect(
          arguments['sourceId'],
          isA<String>().having((id) => id.isNotEmpty, 'nonempty', isTrue),
        );
        expect(arguments['sequence'], 1);
        expect(arguments['action'], 'increment');

        reply.complete(_payload(value: 3, revision: 4, attached: true));
        await increment;
        expect(
          bridge.value!.toPayload(),
          _payload(value: 3, revision: 4, attached: true),
        );
      },
    );

    test(
      'uses stable source identity and increasing intent sequences',
      () async {
        await _invoke(channel, 'stateChanged', _payload());
        var value = 0;
        nativeHandler =
            (call) async =>
                call.method == 'intent'
                    ? _payload(value: ++value, revision: value)
                    : null;

        await bridge.increment();
        await bridge.increment();

        final intents =
            outbound
                .where((call) => call.method == 'intent')
                .map((call) => call.arguments as Map)
                .toList();
        expect(intents.map((intent) => intent['sequence']), [1, 2]);
        expect(intents[0]['sourceId'], intents[1]['sourceId']);
        expect(bridge.value!.value, 2);
      },
    );

    test(
      'late replies from an old session cannot replace a new projection',
      () async {
        final reply = Completer<Object?>();
        nativeHandler = (_) => reply.future;
        await _invoke(channel, 'stateChanged', _payload());
        final increment = bridge.increment();
        await _settleMessages();

        await _invoke(
          channel,
          'stateChanged',
          _payload(sessionId: 'session-2', value: 5, revision: 8),
        );
        reply.complete(_payload(value: 1, revision: 1));
        await increment;

        expect(
          bridge.value!.toPayload(),
          _payload(sessionId: 'session-2', value: 5, revision: 8),
        );
      },
    );

    test(
      'late replies cannot roll back a newer revision in the same session',
      () async {
        final reply = Completer<Object?>();
        nativeHandler = (_) => reply.future;
        await _invoke(channel, 'stateChanged', _payload());
        final increment = bridge.increment();
        await _settleMessages();

        await _invoke(channel, 'stateChanged', _payload(value: 2, revision: 2));
        reply.complete(_payload(value: 1, revision: 1));
        await increment;

        expect(bridge.value!.toPayload(), _payload(value: 2, revision: 2));
      },
    );

    test(
      'an empty intent reply cannot erase a newer host projection',
      () async {
        final reply = Completer<Object?>();
        nativeHandler = (_) => reply.future;
        await _invoke(channel, 'stateChanged', _payload());
        final increment = bridge.increment();
        await _settleMessages();

        await _invoke(channel, 'stateChanged', _payload(value: 2, revision: 2));
        reply.complete(null);
        await increment;

        expect(bridge.value!.toPayload(), _payload(value: 2, revision: 2));
      },
    );

    test(
      'late replies cannot recreate a stopped companion projection',
      () async {
        final reply = Completer<Object?>();
        nativeHandler = (_) => reply.future;
        await _invoke(channel, 'stateChanged', _payload());
        final increment = bridge.increment();
        await _settleMessages();

        await _invoke(channel, 'stateChanged');
        reply.complete(_payload(value: 1, revision: 1));
        await increment;

        expect(bridge.value, isNull);
      },
    );

    test(
      'detach ignores an in-flight response and removes the native handler',
      () async {
        final reply = Completer<Object?>();
        nativeHandler = (_) => reply.future;
        await _invoke(channel, 'stateChanged', _payload());
        final increment = bridge.increment();
        await _settleMessages();

        bridge.detach();
        final detached = bridge.value;
        reply.complete(_payload(value: 1, revision: 1));
        await increment;

        expect(bridge.value, same(detached));
        await expectLater(
          _invoke(channel, 'stateChanged', _payload()),
          throwsA(isA<MissingPluginException>()),
        );
      },
    );
  });

  testWidgets(
    'owner probe increments twice before a frame and stops without loading a library',
    (tester) async {
      const probeChannel = MethodChannel('com.avelune.runtime/surface_probe');
      const libraryChannel = MethodChannel('com.avelune.runtime/library');
      final libraryCalls = <MethodCall>[];
      var storageCalls = 0;
      const storageChannels = [
        'plugins.flutter.io/path_provider',
        'dev.flutter.pigeon.path_provider_foundation.PathProviderApi.getDirectoryPath',
        'dev.flutter.pigeon.path_provider_android.PathProviderApi.getApplicationSupportPath',
      ];
      messenger.setMockMethodCallHandler(probeChannel, (_) async => null);
      messenger.setMockMethodCallHandler(libraryChannel, (call) async {
        libraryCalls.add(call);
        return null;
      });
      for (final name in storageChannels) {
        messenger.setMockMessageHandler(name, (_) async {
          storageCalls++;
          return null;
        });
      }
      addTearDown(() {
        messenger.setMockMethodCallHandler(probeChannel, null);
        messenger.setMockMethodCallHandler(libraryChannel, null);
        for (final name in storageChannels) {
          messenger.setMockMessageHandler(name, null);
        }
      });

      await tester.pumpWidget(const AveluneRuntimeApp());
      await tester.pump();
      expect(
        await _invoke(probeChannel, 'start', {'sessionId': 'session-1'}),
        _payload(),
      );
      await tester.pump();
      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('probe-increment')));
      await tester.tap(find.byKey(const ValueKey('probe-increment')));
      expect(
        await _invoke(probeChannel, 'snapshot'),
        _payload(value: 2, revision: 2),
      );
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      expect(await _invoke(probeChannel, 'stop'), isNull);
      await tester.pump();

      expect(find.byType(AvelunePrimaryProbeSurface), findsNothing);
      expect(find.byKey(const ValueKey('probe-counter')), findsNothing);
      expect(libraryCalls.map((call) => call.method), ['runtimeReady']);
      expect(storageCalls, 0);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'companion widget projects host state without invoking the game library',
    (tester) async {
      const probeChannel = MethodChannel('com.avelune.runtime/surface_probe');
      const libraryChannel = MethodChannel('com.avelune.runtime/library');
      final probeCalls = <MethodCall>[];
      final libraryCalls = <MethodCall>[];
      final reply = Completer<Object?>();
      messenger.setMockMethodCallHandler(probeChannel, (call) async {
        probeCalls.add(call);
        return call.method == 'companionReady'
            ? _payload(value: 4, revision: 4, attached: true)
            : await reply.future;
      });
      messenger.setMockMethodCallHandler(libraryChannel, (call) async {
        libraryCalls.add(call);
        return null;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(probeChannel, null);
        messenger.setMockMethodCallHandler(libraryChannel, null);
      });

      await tester.pumpWidget(const AveluneCompanionProbeApp());
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      expect(probeCalls.map((call) => call.method), ['companionReady']);

      await tester.tap(find.byKey(const ValueKey('probe-increment')));
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      expect(probeCalls.map((call) => call.method), [
        'companionReady',
        'intent',
      ]);
      expect(libraryCalls, isEmpty);

      reply.complete(_payload(value: 5, revision: 5, attached: true));
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
      expect(find.byType(AvelunePrimaryProbeSurface), findsNothing);
      expect(libraryCalls, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
