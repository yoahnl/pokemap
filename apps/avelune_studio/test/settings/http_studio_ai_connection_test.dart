import 'package:avelune_studio/features/settings/studio_ai_preferences.dart';
import 'package:avelune_studio/platform/settings/http_studio_ai_connection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final routes = {
    StudioAiProvider.openAi: (
      'api.openai.com',
      'authorization',
      'Bearer dummy',
    ),
    StudioAiProvider.anthropic: ('api.anthropic.com', 'x-api-key', 'dummy'),
    StudioAiProvider.gemini: (
      'generativelanguage.googleapis.com',
      'x-goog-api-key',
      'dummy',
    ),
  };
  for (final entry in routes.entries) {
    test(
      '${entry.key.name} uses its own HTTPS endpoint and auth header',
      () async {
        final (host, header, value) = entry.value;
        final adapter = HttpStudioAiConnection(
          createClient: () => MockClient((request) async {
            expect(request.method, 'GET');
            expect(request.url.scheme, 'https');
            expect(request.url.host, host);
            expect(request.url.path, endsWith('/models'));
            expect(request.url.toString(), isNot(contains('dummy')));
            expect(request.headers[header], value);
            expect(request.followRedirects, isFalse);
            return http.Response('{}', 200);
          }),
        );
        expect(
          await adapter.test(entry.key, 'dummy'),
          StudioAiConnectionResult.connected,
        );
      },
    );
  }

  for (final (status, expected) in [
    (403, StudioAiConnectionResult.denied),
    (302, StudioAiConnectionResult.unavailable),
    (429, StudioAiConnectionResult.unavailable),
  ]) {
    test('HTTP $status maps to ${expected.name}', () async {
      final adapter = HttpStudioAiConnection(
        createClient: () => MockClient((_) async => http.Response('', status)),
      );
      expect(await adapter.test(StudioAiProvider.openAi, 'dummy'), expected);
    });
  }
}
