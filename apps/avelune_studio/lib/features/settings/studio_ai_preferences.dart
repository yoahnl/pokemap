enum StudioAiProvider {
  openAi('OpenAI'),
  anthropic('Anthropic'),
  gemini('Google Gemini');

  const StudioAiProvider(this.label);

  final String label;
}

abstract interface class StudioAiKeyStore {
  Future<bool> contains(StudioAiProvider provider);
  Future<String?> read(StudioAiProvider provider);
  Future<void> write(StudioAiProvider provider, String key);
  Future<void> delete(StudioAiProvider provider);
}

enum StudioAiConnectionResult { connected, denied, unavailable }

abstract interface class StudioAiConnection {
  Future<StudioAiConnectionResult> test(StudioAiProvider provider, String key);
}

String? studioAiKeyInput(String input) {
  final key = input.trim();
  return key.isEmpty || key.codeUnits.any((unit) => unit < 33 || unit > 126)
      ? null
      : key;
}
