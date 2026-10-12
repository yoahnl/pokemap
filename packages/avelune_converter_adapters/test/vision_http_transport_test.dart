import 'dart:async';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

void main() {
  test(
      'real transport fixes endpoint and disables redirects with bounded bytes',
      () async {
    final client = _Client(_Response(200, [
      [1, 2, 3]
    ]));
    final result = await OpenAiResponsesTransport(clientFactory: () => client)
        .send(
            body: [10, 20],
            bearerToken: 'decoy',
            policy: const VisionAssistancePolicy(),
            cancellation: ScanCancellation());
    expect(client.uri.toString(), 'https://api.openai.com/v1/responses');
    expect(client.request.followRedirects, false);
    expect(client.request.contentLength, 2);
    expect(client.request.body, [10, 20]);
    expect(client.request.headers.values[HttpHeaders.authorizationHeader],
        'Bearer decoy');
    expect(result.body, [1, 2, 3]);
    expect(client.closed, true);
  });
  test('real transport enforces streamed response cap and sanitizes failure',
      () async {
    final client = _Client(_Response(
        200,
        [
          [1, 2],
          [3, 4]
        ],
        contentLength: -1));
    await expectLater(
        OpenAiResponsesTransport(clientFactory: () => client).send(
            body: [1],
            bearerToken: 'decoy-secret',
            policy: const VisionAssistancePolicy(maxResponseBytes: 3),
            cancellation: ScanCancellation()),
        throwsA(isA<VisionAssistanceException>()));
    expect(client.closed, true);
  });
  test('cancelled request does not create HTTP client', () async {
    var called = false;
    final cancellation = ScanCancellation()..cancel();
    await expectLater(
        OpenAiResponsesTransport(clientFactory: () {
          called = true;
          return _Client(_Response(200, []));
        }).send(
            body: [1],
            bearerToken: 'decoy',
            policy: const VisionAssistancePolicy(),
            cancellation: cancellation),
        throwsA(isA<VisionAssistanceException>()));
    expect(called, false);
  });
  test('redirect response is returned without following another endpoint',
      () async {
    final client = _Client(_Response(307, []));
    final response = await OpenAiResponsesTransport(clientFactory: () => client)
        .send(
            body: [1],
            bearerToken: 'decoy',
            policy: const VisionAssistancePolicy(),
            cancellation: ScanCancellation());
    expect(response.statusCode, 307);
    expect(client.opens, 1);
    expect(client.request.followRedirects, false);
  });
  test('connection timeout prevents a late connection from transmitting bytes',
      () async {
    final gate = Completer<void>();
    final client = _Client(_Response(200, []), openGate: gate.future);
    await expectLater(
        OpenAiResponsesTransport(clientFactory: () => client).send(
            body: [1],
            bearerToken: 'decoy-secret',
            policy: const VisionAssistancePolicy(
                timeout: Duration(milliseconds: 10)),
            cancellation: ScanCancellation()),
        throwsA(isA<VisionAssistanceException>()));
    gate.complete();
    await Future<void>.delayed(Duration.zero);
    expect(client.closed, true);
    expect(client.request.body, isEmpty);
    expect(client.request.headers.values, isEmpty);
  });
  test('transport exception never exposes token or remote response text',
      () async {
    final client = _Client(_Response(200, []),
        error: StateError('decoy-secret private body'));
    Object? error;
    try {
      await OpenAiResponsesTransport(clientFactory: () => client).send(
          body: [1],
          bearerToken: 'decoy-secret',
          policy: const VisionAssistancePolicy(),
          cancellation: ScanCancellation());
    } catch (value) {
      error = value;
    }
    expect(error, isA<VisionAssistanceException>());
    expect('$error', isNot(contains('decoy-secret')));
    expect(client.closed, true);
  });
}

final class _Client implements HttpClient {
  _Client(_Response response, {this.openGate, this.error})
      : request = _Request(response);
  final _Request request;
  final Future<void>? openGate;
  final Object? error;
  Uri? uri;
  int opens = 0;
  bool closed = false;
  @override
  Future<HttpClientRequest> postUrl(Uri url) async {
    uri = url;
    opens++;
    await openGate;
    if (error != null) throw error!;
    return request;
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }

  @override
  set connectionTimeout(Duration? value) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Request implements HttpClientRequest {
  _Request(this.response);
  final _Response response;
  @override
  final _Headers headers = _Headers();
  @override
  bool followRedirects = true;
  @override
  int contentLength = -1;
  final body = <int>[];
  @override
  void add(List<int> data) => body.addAll(data);
  @override
  Future<HttpClientResponse> close() async => response;
  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Headers implements HttpHeaders {
  final values = <String, Object>{};
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) =>
      values[name] = value;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Response extends Stream<List<int>> implements HttpClientResponse {
  _Response(this.statusCode, this.chunks, {this.contentLength = -1});
  @override
  final int statusCode;
  final List<List<int>> chunks;
  @override
  final int contentLength;
  @override
  StreamSubscription<List<int>> listen(void Function(List<int>)? onData,
          {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      Stream<List<int>>.fromIterable(chunks).listen(onData,
          onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
