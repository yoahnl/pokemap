import 'package:avelune_studio/features/story_workspace/application/story_workspace_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the workspace starts in Trame and selects each retained section', () {
    const initial = StoryWorkspaceState();
    expect(initial.section, StorySection.trame);
    expect(StorySection.values, hasLength(7));
    var state = initial;
    for (final section in StorySection.values) {
      state = state.select(section);
      expect(state.section, section);
    }
    expect(initial.section, StorySection.trame);
    expect(state.select(state.section), same(state));
  });
}
