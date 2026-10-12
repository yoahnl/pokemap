import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/vision_test_fixture.dart';

void main() {
  late Directory root;
  late VisionTestFixture fixture;
  late VisionRequest request;
  late VisionTestVault vault;
  late VisionTestFiles files;
  late VisionTestTransport transport;
  late LocalVisionStore store;
  late VisionLiveContext live;
  setUp(() async {
    root =
        await Directory.systemTemp.createTemp('avelune-vision-service-test-');
    fixture = VisionTestFixture();
    request = fixture.request();
    vault = VisionTestVault();
    files = VisionTestFiles(fixture.sourceBytes);
    transport = VisionTestTransport((_) async => fixture.http(request));
    store = LocalVisionStore(
        rootPath: '${root.path}/private', excludedRoots: () async => []);
    live = fixture.live(request);
  });
  tearDown(() async => root.delete(recursive: true));
  VisionAssistanceService service(
          {bool offline = false,
          VisionAssistancePolicy policy = const VisionAssistancePolicy()}) =>
      VisionAssistanceService(
          vault: vault,
          store: store,
          liveContext: () async => live,
          sourceFiles: () async => files,
          transport: transport,
          policy: policy,
          offline: offline);

  test('offline rejects before reading a key or calling transport', () async {
    await expectLater(service(offline: true).suggest(request),
        throwsA(isA<VisionAssistanceException>()));
    expect(vault.reads, 0);
    expect(transport.bodies, isEmpty);
    expect(await root.list().toList(), isEmpty);
  });
  test('missing key leaves local conversion and request quota untouched',
      () async {
    vault.secret = null;
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(transport.bodies, isEmpty);
    expect((await store.usage()).requestCount, 0);
  });
  test('sends exact approved PNG with strict Responses schema and no tools',
      () async {
    final response = await service().suggest(request);
    expect(response.suggestions.single.proposedName, 'Petit arbre');
    final body = jsonDecode(utf8.decode(transport.bodies.single)) as Map;
    expect(body['model'], request.material.model);
    expect(body['store'], false);
    expect(body['stream'], false);
    expect(body['tools'], isEmpty);
    expect(body['max_output_tokens'], 2048);
    final content = (body['input'] as List).last['content'] as List;
    final crop = content.where((v) => v['type'] == 'input_image').single;
    expect(crop['image_url'],
        'data:image/png;base64,${base64Encode(request.material.crops.single.pngBytes)}');
    expect(crop['detail'], 'high');
    expect(body['text']['format']['strict'], true);
    expect(body['text']['format']['type'], 'json_schema');
    expect(
        utf8.decode(transport.bodies.single), isNot(contains(vault.secret!)));
    expect((await store.usage()).requestCount, 1);
    expect((await store.usage()).knownCostMicros, isNull);
  });
  test('different pixels under the same source metadata are refused before key',
      () async {
    request = fixture.request(cropBytes: visionPng(2, 3, [6, 5, 4, 3, 2, 1]));
    live = fixture.live(request);
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(vault.reads, 0);
    expect(transport.bodies, isEmpty);
  });
  test(
      'opaque PNG text in identical crop pixels is refused before key and HTTP',
      () async {
    request = fixture.request(
        cropBytes: visionPng(2, 3, [
      1,
      2,
      3,
      4,
      5,
      6
    ], textData: {
      'private-path': '/private/original-script',
      'instructions': 'never-upload-this-text'
    }));
    live = fixture.live(request);
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(vault.reads, 0);
    expect(transport.bodies, isEmpty);
  });
  test(
      'original PNG text stays in source while clean crop alone is transmitted',
      () async {
    fixture = VisionTestFixture(
        sourceTextData: {'private-path': '/private/original-script'});
    final original = List<int>.from(fixture.sourceBytes);
    request = fixture.request(cropBytes: visionPng(2, 3, [1, 2, 3, 4, 5, 6]));
    files = VisionTestFiles(fixture.sourceBytes);
    live = fixture.live(request);
    await service().suggest(request);
    expect(files.bytes, original);
    expect(transport.bodies, hasLength(1));
    expect(utf8.decode(transport.bodies.single),
        isNot(contains('/private/original-script')));
  });
  test('changed source content is refused before key and network', () async {
    files.bytes = visionPng(2, 3, [9, 9, 9, 9, 9, 9]);
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(vault.reads, 0);
    expect(transport.bodies, isEmpty);
  });
  test('session changed while reading key prevents dispatch', () async {
    vault.onRead =
        () async => live = fixture.live(request, session: Sha256Hash('d' * 64));
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(vault.reads, 1);
    expect(transport.bodies, isEmpty);
    expect((await store.usage()).requestCount, 0);
  });
  test(
      'late source and session changes reject response without cache or approval',
      () async {
    transport.onSend = (_) async {
      live = fixture.live(request, verified: false);
      return fixture.http(request);
    };
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(await store.readCache(request), isNull);
    expect((await store.usage()).requestCount, 1);
  });
  test('known predispatch guard failure releases only its unsent reservation',
      () async {
    var storeAccesses = 0;
    store = LocalVisionStore(
        rootPath: '${root.path}/private',
        excludedRoots: () async {
          if (++storeAccesses == 2) {
            live = fixture.live(request, session: Sha256Hash('d' * 64));
          }
          return [];
        });
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(transport.bodies, isEmpty);
    final usage = await store.usage();
    expect(usage.requestCount, 0);
    expect(usage.unknownAttempts, 0);
    expect(usage.reservedCostMicros, isNull);
  });
  test('valid cache is admitted against fresh source and avoids key lookup',
      () async {
    await service().suggest(request);
    vault.reads = 0;
    final response = await service().suggest(request);
    expect(response.toJson(), fixture.response(request).toJson());
    expect(vault.reads, 0);
    expect(transport.bodies, hasLength(1));
    expect(files.reads, greaterThanOrEqualTo(2));
  });
  test('cached response never bypasses current source attestation', () async {
    await service().suggest(request);
    files.bytes = visionPng(2, 3, [7, 7, 7, 7, 7, 7]);
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(transport.bodies, hasLength(1));
  });
  test('new human consent for identical material rebinds cached request nonce',
      () async {
    await service().suggest(request);
    request = fixture.request(requestId: 'request-2');
    live = fixture.live(request);
    vault.reads = 0;
    final response = await service().suggest(request);
    expect(response.requestId, request.context.requestId);
    expect(response.suggestions.single.proposedName, 'Petit arbre');
    expect(vault.reads, 0);
    expect(transport.bodies, hasLength(1));
  });
  test('401 consumes one durable attempt and never retries or leaks body',
      () async {
    transport.onSend = (_) async =>
        VisionHttpResponse(statusCode: 401, body: utf8.encode(vault.secret!));
    Object? error;
    try {
      await service().suggest(request);
    } catch (value) {
      error = value;
    }
    expect(error, isA<VisionAssistanceException>());
    expect('$error', isNot(contains(vault.secret!)));
    expect(vault.reads, 1);
    expect((await store.usage()).requestCount, 1);
    expect((await store.usage()).unknownAttempts, 1);
    final persisted = await _persisted(root);
    expect(persisted, isNot(contains(vault.secret!)));
    expect(persisted, isNot(contains(base64Encode(fixture.sourceBytes))));
  });
  test('transient error retry rereads key and charges both attempts durably',
      () async {
    transport.onSend = (attempt) async => attempt == 1
        ? VisionHttpResponse(statusCode: 503, body: [])
        : fixture.http(request);
    await service(
            policy: const VisionAssistancePolicy(retryDelay: Duration.zero))
        .suggest(request);
    expect(vault.reads, 2);
    expect(transport.bodies, hasLength(2));
    final usage = await LocalVisionStore(
        rootPath: store.rootPath, excludedRoots: () async => []).usage();
    expect(usage.requestCount, 2);
    expect(usage.retryCount, 1);
    expect(usage.unknownAttempts, 1);
  });
  test(
      'source stale before retry leaves first attempt charged and sends no second',
      () async {
    transport.onSend = (_) async {
      live = fixture.live(request, session: Sha256Hash('e' * 64));
      return VisionHttpResponse(statusCode: 503, body: []);
    };
    await expectLater(
        service(policy: const VisionAssistancePolicy(retryDelay: Duration.zero))
            .suggest(request),
        throwsA(isA<VisionAssistanceException>()));
    expect(transport.bodies, hasLength(1));
    expect(vault.reads, 1);
    expect((await store.usage()).requestCount, 1);
  });
  test('provider insufficient quota is not retried', () async {
    transport.onSend = (_) async => VisionHttpResponse(
        statusCode: 429,
        body: utf8.encode(jsonEncode({
          'error': {'code': 'insufficient_quota'}
        })));
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(transport.bodies, hasLength(1));
    expect(vault.reads, 1);
    expect((await store.usage()).requestCount, 1);
  });
  test('rate limit retry is bounded and each attempt is durably charged',
      () async {
    transport.onSend =
        (_) async => VisionHttpResponse(statusCode: 429, body: []);
    await expectLater(
        service(policy: const VisionAssistancePolicy(retryDelay: Duration.zero))
            .suggest(request),
        throwsA(isA<VisionAssistanceException>()));
    expect(transport.bodies, hasLength(2));
    expect(vault.reads, 2);
    expect((await store.usage()).requestCount, 2);
    expect((await store.usage()).unknownAttempts, 2);
  });
  test(
      'cancellation after send retains unknown usage and discards late response',
      () async {
    final cancellation = ScanCancellation();
    transport.onSend = (_) async {
      cancellation.cancel();
      return fixture.http(request);
    };
    await expectLater(service().suggest(request, cancellation: cancellation),
        throwsA(isA<VisionAssistanceException>()));
    expect((await store.usage()).unknownAttempts, 1);
    expect(await store.readCache(request), isNull);
  });
  test('strict money budget without valid tariffs rejects before key',
      () async {
    await expectLater(
        service(policy: const VisionAssistancePolicy(maxCostMicros: 1000000))
            .suggest(request),
        throwsA(isA<VisionAssistanceException>()));
    expect(vault.reads, 0);
    expect(transport.bodies, isEmpty);
  });
  test('unexpected response IDs and provider tool output are rejected',
      () async {
    transport.onSend = (_) async =>
        fixture.http(fixture.request(requestId: 'foreign-request'));
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(await store.readCache(request), isNull);
    transport.onSend = (_) async => VisionHttpResponse(
        statusCode: 200,
        body: utf8.encode(jsonEncode({
          'status': 'completed',
          'output': [
            {'type': 'function_call', 'name': 'run_shell'}
          ]
        })));
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(await store.readCache(request), isNull);
  });
  test('provider response echoing the ephemeral key never reaches cache',
      () async {
    transport.onSend = (_) async => fixture.http(request, name: vault.secret!);
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(await store.readCache(request), isNull);
    expect(await _persisted(root), isNot(contains(vault.secret!)));
  });
  test('Unicode escaped key echo is rejected after structured output decoding',
      () async {
    final raw = jsonEncode(fixture.resultJson(request, name: vault.secret!));
    final escaped = vault.secret!.codeUnits
        .map((unit) => '\\u${unit.toRadixString(16).padLeft(4, '0')}')
        .join();
    transport.onSend = (_) async => VisionHttpResponse(
        statusCode: 200,
        body: utf8.encode(jsonEncode({
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'role': 'assistant',
              'content': [
                {
                  'type': 'output_text',
                  'text': raw.replaceAll(vault.secret!, escaped)
                }
              ]
            }
          ]
        })));
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(await store.readCache(request), isNull);
    expect(await _persisted(root), isNot(contains(vault.secret!)));
  });
  test('decoded key punctuation is rejected before curated cache persistence',
      () async {
    vault.secret = 'decoy-"\\-secret';
    transport.onSend = (_) async => fixture.http(request, name: vault.secret!);
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(await store.readCache(request), isNull);
    expect(await _persisted(root), isNot(contains(vault.secret!)));
  });
  test('oversized response and refusal are rejected without persistence',
      () async {
    transport.onSend = (_) async =>
        VisionHttpResponse(statusCode: 200, body: List.filled(262145, 32));
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    transport.onSend = (_) async => VisionHttpResponse(
        statusCode: 200,
        body: utf8.encode(jsonEncode({
          'status': 'completed',
          'output': [
            {
              'type': 'message',
              'content': [
                {'type': 'refusal', 'refusal': 'refused'}
              ]
            }
          ]
        })));
    await expectLater(
        service().suggest(request), throwsA(isA<VisionAssistanceException>()));
    expect(await store.readCache(request), isNull);
  });
}

Future<String> _persisted(Directory root) async {
  final text = StringBuffer();
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    if (entity is File) {
      text.write(utf8.decode(await entity.readAsBytes(), allowMalformed: true));
    }
  }
  return text.toString();
}
