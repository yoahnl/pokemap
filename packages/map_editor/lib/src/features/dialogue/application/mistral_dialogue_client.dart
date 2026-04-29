// -----------------------------------------------------------------------------
// Client HTTP minimal Mistral AI — utilisé par Dialogue Studio
// -----------------------------------------------------------------------------
// - Aucun provider abstrait : une seule implémentation REST réelle.
// - Clé API : [ProjectSettings.mistralApiKey] (paramètres projet) puis
//   variable d’environnement `MISTRAL_API_KEY`.
// -----------------------------------------------------------------------------

import 'dart:convert';

import 'package:http/http.dart' as http;

export '../../editor/application/editor_ai_settings.dart'
    show resolveEditorMistralApiKey;

/// Erreur réseau ou réponse API inattendue.
class MistralDialogueException implements Exception {
  MistralDialogueException(this.message);
  final String message;

  @override
  String toString() => 'MistralDialogueException: $message';
}

/// Appel synchrone `chat/completions` (petits prompts dialogue).
class MistralDialogueClient {
  MistralDialogueClient({
    http.Client? httpClient,
    this.baseUrl = 'https://api.mistral.ai/v1/chat/completions',
  }) : _client = httpClient ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  /// Retourne le texte du premier choix (contenu assistant).
  Future<String> completeChat({
    required String apiKey,
    required String systemPrompt,
    required String userMessage,
    String model = 'mistral-small-latest',
  }) async {
    final trimmedKey = apiKey.trim();
    if (trimmedKey.isEmpty) {
      throw MistralDialogueException('Clé API Mistral absente.');
    }

    final uri = Uri.parse(baseUrl);
    final body = jsonEncode({
      'model': model,
      'temperature': 0.7,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
    });

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $trimmedKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MistralDialogueException(
        'HTTP ${response.statusCode}: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw MistralDialogueException('Réponse JSON invalide.');
    }
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw MistralDialogueException('Aucun choix dans la réponse Mistral.');
    }
    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw MistralDialogueException('Format de choix inattendu.');
    }
    final msg = first['message'];
    if (msg is! Map<String, dynamic>) {
      throw MistralDialogueException('Message assistant manquant.');
    }
    final content = msg['content'];
    if (content is! String) {
      throw MistralDialogueException('Contenu assistant vide ou non texte.');
    }
    return content;
  }

  void close() {
    _client.close();
  }
}

/// Retire les balises ``` optionnelles entourant le Yarn renvoyé par le modèle.
String stripMarkdownFences(String raw) {
  var s = raw.trim();
  if (s.startsWith('```')) {
    final firstNl = s.indexOf('\n');
    if (firstNl != -1) {
      s = s.substring(firstNl + 1);
    }
    if (s.endsWith('```')) {
      s = s.substring(0, s.length - 3).trim();
    }
  }
  return s.trim();
}
