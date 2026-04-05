import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/dialogue/application/mistral_dialogue_client.dart';

void main() {
  test('resolveEditorMistralApiKey uses project settings when set', () {
    const s = ProjectSettings(mistralApiKey: 'sk-from-project');
    expect(resolveEditorMistralApiKey(s), 'sk-from-project');
  });

  test('resolveEditorMistralApiKey trims project key', () {
    const s = ProjectSettings(mistralApiKey: '  sk-x  ');
    expect(resolveEditorMistralApiKey(s), 'sk-x');
  });
}
