import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/vision_test_fixture.dart';

void main() {
  late Directory root;
  late LocalVisionStore store;
  late VisionTestFixture fixture;
  late VisionRequest request;
  final clock = DateTime.utc(2026, 10, 12);
  LocalVisionStore fresh(
          {VisionStoreLimits limits = const VisionStoreLimits(),
          DateTime? now,
          List<String> excluded = const []}) =>
      LocalVisionStore(
          rootPath: '${root.path}/private',
          excludedRoots: () async => excluded,
          limits: limits,
          now: () => now ?? clock);
  setUp(() async {
    root = await Directory.systemTemp.createTemp('avelune-vision-store-test-');
    fixture = VisionTestFixture();
    request = fixture.request();
    store = fresh();
  });
  tearDown(() async => root.delete(recursive: true));
  test('initial ledger is empty and unknown cost is nullable', () async {
    final usage = await store.usage();
    expect(usage.requestCount, 0);
    expect(usage.knownCostMicros, isNull);
    expect(usage.reservedCostMicros, isNull);
  });
  test('uncompleted attempt survives new store with unknown usage', () async {
    await store.reserve(
        request: request, policy: const VisionAssistancePolicy(), attempt: 0);
    final usage = await fresh().usage();
    expect(usage.requestCount, 1);
    expect(usage.unknownAttempts, 1);
    expect(usage.knownCostMicros, isNull);
    expect(usage.reservedCostMicros, isNull);
  });
  test('simultaneous different requests cannot oversubscribe durable quota',
      () async {
    final policy = const VisionAssistancePolicy(maxRequests: 1);
    final results = await Future.wait([
      store
          .reserve(request: request, policy: policy, attempt: 0)
          .then<Object>((v) => v, onError: (Object error) => error),
      fresh()
          .reserve(
              request: fixture.request(requestId: 'request-2'),
              policy: policy,
              attempt: 0)
          .then<Object>((v) => v, onError: (Object error) => error)
    ]);
    expect(results.whereType<VisionAttemptReservation>(), hasLength(1));
    expect(results.whereType<VisionAssistanceException>(), hasLength(1));
    expect((await fresh().usage()).requestCount, 1);
  });
  test('two independent processes share one durable request quota', () async {
    final worker = File('test/support/vision_ledger_worker.dart').absolute.path;
    final results = await Future.wait([
      Process.run(Platform.resolvedExecutable,
          ['run', worker, store.rootPath, 'process-1']),
      Process.run(Platform.resolvedExecutable,
          ['run', worker, store.rootPath, 'process-2'])
    ]);
    expect(results.map((r) => r.exitCode), everyElement(0));
    expect(
        results.map((r) => '${r.stdout}'.trim()).where((s) => s == 'reserved'),
        hasLength(1));
    expect(
        results.map((r) => '${r.stdout}'.trim()).where((s) => s == 'refused'),
        hasLength(1));
    expect((await fresh().usage()).requestCount, 1);
  });
  test('known usage costs use explicit fresh tariffs and reserve pending retry',
      () async {
    final pricing = VisionPricing(
        model: request.material.model,
        inputMicrosPerMillionTokens: 1000000,
        outputMicrosPerMillionTokens: 2000000,
        verifiedAt: clock,
        validUntil: clock.add(const Duration(days: 1)),
        sourceUrl: 'https://developers.openai.com/api/docs/pricing');
    final policy = VisionAssistancePolicy(
        pricing: pricing, maxCostMicros: 1000, maxInputTokensPerAttempt: 100);
    request = fixture.request(options: {'maxOutputTokens': 10});
    final reservation =
        await store.reserve(request: request, policy: policy, attempt: 0);
    expect(reservation.estimatedCostMicros, 120);
    await store.complete(
        reservation: reservation,
        policy: policy,
        usage: const VisionTokenUsage(inputTokens: 10, outputTokens: 4));
    await store.reserve(request: request, policy: policy, attempt: 1);
    final usage = await fresh().usage();
    expect(usage.knownCostMicros, 18);
    expect(usage.reservedCostMicros, 120);
    expect(usage.unknownAttempts, 1);
    expect(usage.retryCount, 1);
  });
  test('expired or wrong model tariffs cannot admit strict monetary budgets',
      () async {
    final pricing = VisionPricing(
        model: 'wrong-model',
        inputMicrosPerMillionTokens: 1,
        outputMicrosPerMillionTokens: 1,
        verifiedAt: clock.subtract(const Duration(days: 2)),
        validUntil: clock.subtract(const Duration(days: 1)),
        sourceUrl: 'https://developers.openai.com/api/docs/pricing');
    await expectLater(
        store.reserve(
            request: request,
            policy:
                VisionAssistancePolicy(maxCostMicros: 100000, pricing: pricing),
            attempt: 0),
        throwsA(isA<VisionAssistanceException>()));
    expect((await fresh().usage()).requestCount, 0);
  });
  test('strict cost quota counts unresolved reservations after restart',
      () async {
    final pricing = VisionPricing(
        model: request.material.model,
        inputMicrosPerMillionTokens: 1000000,
        outputMicrosPerMillionTokens: 1000000,
        verifiedAt: clock,
        validUntil: clock.add(const Duration(days: 1)),
        sourceUrl: 'https://developers.openai.com/api/docs/pricing');
    final policy = VisionAssistancePolicy(
        pricing: pricing, maxCostMicros: 2100, maxInputTokensPerAttempt: 10);
    await store.reserve(request: request, policy: policy, attempt: 0);
    await expectLater(
        fresh().reserve(request: request, policy: policy, attempt: 1),
        throwsA(isA<VisionAssistanceException>()));
    expect((await fresh().usage()).requestCount, 1);
  });
  test('cached curated response survives restart with exact identity hash',
      () async {
    await store.writeCache(request, fixture.response(request));
    expect((await fresh().readCache(request))!.toJson(),
        fixture.response(request).toJson());
    expect(await fresh().readCache(fixture.request(model: 'another-model')),
        isNull);
    expect(await fresh().readCache(fixture.request(options: {'detail': 'low'})),
        isNull);
    expect(
        await fresh().readCache(
            fixture.request(accountRevision: ConverterId('account-2'))),
        isNull);
  });
  test('expired cache cannot return old suggestions', () async {
    await store.writeCache(request, fixture.response(request));
    expect(
        await fresh(now: clock.add(const Duration(days: 8))).readCache(request),
        isNull);
  });
  test('cache quota refuses another entry without corrupting original',
      () async {
    final one = fresh(limits: const VisionStoreLimits(maxCacheEntries: 1));
    await one.writeCache(request, fixture.response(request));
    final other =
        fixture.request(model: 'other-vision-model', requestId: 'request-2');
    await expectLater(one.writeCache(other, fixture.response(other)),
        throwsA(isA<VisionAssistanceException>()));
    expect((await one.readCache(request))!.toJson(),
        fixture.response(request).toJson());
  });
  test('storage inside source or symlink root is rejected without writes',
      () async {
    await expectLater(
        fresh(excluded: [root.path]).reserve(
            request: request,
            policy: const VisionAssistancePolicy(),
            attempt: 0),
        throwsA(isA<VisionAssistanceException>()));
    expect(await root.list().toList(), isEmpty);
    final outside =
        await Directory.systemTemp.createTemp('avelune-vision-symlink-target-');
    addTearDown(() => outside.delete(recursive: true));
    await Link('${root.path}/private').create(outside.path);
    await expectLater(store.usage(), throwsA(isA<VisionAssistanceException>()));
    expect(await outside.list().toList(), isEmpty);
  });
  test('tampered ledger fails closed instead of resetting charged attempts',
      () async {
    await store.reserve(
        request: request, policy: const VisionAssistancePolicy(), attempt: 0);
    final ledger = File('${store.rootPath}/ledger.json');
    final data =
        jsonDecode(await ledger.readAsString()) as Map<String, dynamic>;
    data['attempts'] = [];
    await ledger.writeAsString(jsonEncode(data), flush: true);
    await expectLater(
        fresh().usage(), throwsA(isA<VisionAssistanceException>()));
  });
  test('completion is single use and unknown response does not claim zero cost',
      () async {
    final reservation = await store.reserve(
        request: request, policy: const VisionAssistancePolicy(), attempt: 0);
    await store.complete(
        reservation: reservation,
        policy: const VisionAssistancePolicy(),
        usage: const VisionTokenUsage(inputTokens: 10, outputTokens: 4));
    await expectLater(
        store.complete(
            reservation: reservation,
            policy: const VisionAssistancePolicy(),
            usage: const VisionTokenUsage(inputTokens: 10, outputTokens: 4)),
        throwsA(isA<VisionAssistanceException>()));
    expect((await store.usage()).unknownAttempts, 0);
    expect((await store.usage()).knownCostMicros, isNull);
  });
}
