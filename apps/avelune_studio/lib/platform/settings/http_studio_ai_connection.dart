import 'dart:async';

import 'package:http/http.dart' as http;

import '../../features/settings/studio_ai_preferences.dart';

final class HttpStudioAiConnection implements StudioAiConnection {
  const HttpStudioAiConnection({this.createClient = http.Client.new});

  final http.Client Function() createClient;

  @override
  Future<StudioAiConnectionResult> test(
    StudioAiProvider provider,
    String key,
  ) async {
    final client = createClient();
    try {
      final request = _request(provider, key);
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 8));
      return switch (response.statusCode) {
        >= 200 && < 300 => StudioAiConnectionResult.connected,
        401 || 403 => StudioAiConnectionResult.denied,
        _ => StudioAiConnectionResult.unavailable,
      };
    } on Exception {
      return StudioAiConnectionResult.unavailable;
    } finally {
      client.close();
    }
  }

  http.Request _request(StudioAiProvider provider, String key) {
    final (uri, headers) = switch (provider) {
      StudioAiProvider.openAi => (
        Uri.https('api.openai.com', '/v1/models'),
        {'Authorization': 'Bearer $key'},
      ),
      StudioAiProvider.anthropic => (
        Uri.https('api.anthropic.com', '/v1/models', {'limit': '1'}),
        {'x-api-key': key, 'anthropic-version': '2023-06-01'},
      ),
      StudioAiProvider.gemini => (
        Uri.https('generativelanguage.googleapis.com', '/v1beta/models', {
          'pageSize': '1',
        }),
        {'x-goog-api-key': key},
      ),
    };
    return http.Request('GET', uri)
      ..followRedirects = false
      ..headers.addAll(headers);
  }
}
