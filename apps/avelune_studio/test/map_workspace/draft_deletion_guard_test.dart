import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_draft_reference_guard.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/draft_reference_fixture.dart';

void main() {
  late DraftReferenceProject h;
  setUp(() async => h = await DraftReferenceProject.create());
  tearDown(() => h.dispose());

  test(
    'a character targeted by an unsaved rule refuses to be deleted',
    () async {
      await h.activate('jardin');
      final document = h.maps.active!;
      final characters = CharacterEditingCommands(document, h.maps.project!);
      final npc = characters.place(
        const ProjectCharacterEntry(
          id: 'guide',
          name: 'Chef de gare',
          tilesetId: 'atelier',
        ),
        const GridPos(x: 6, y: 6),
      );
      final index = MapDraftReferenceIndex(h.sources);
      final guarded = CharacterEditingCommands(
        document,
        h.maps.project!,
        draftGuard: index.guard,
      );
      expect(guarded.deletionProblem(npc.id), isNull);

      h.targetEntity('jardin', npc.id);

      expect(guarded.deletionProblem(npc.id), contains('brouillon'));
      expect(() => guarded.delete(npc.id), throwsStateError);
      expect(guarded.selected(npc.id), isNotNull);
    },
  );
}
