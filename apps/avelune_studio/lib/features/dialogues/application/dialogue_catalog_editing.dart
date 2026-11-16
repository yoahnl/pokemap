import 'package:map_authoring/map_authoring_dialogue.dart'
    show newDialogueEditorId;

import '../../story_draft/domain/story_draft_entry.dart';
import 'dialogue_catalog_controller.dart';
import 'dialogue_draft_host.dart';
import 'dialogue_localization_editing.dart';

extension DialogueCatalogEditing on DialogueCatalogController {
  DialogueDraftHost _editingHost(DialogueLocalizationEditing form) {
    final host = editing;
    if (host == null || !host.editable) {
      throw StateError('The dialogue is read-only.');
    }
    sync();
    if (document(form.base.id)?.dialogue != form.base) {
      throw StateError('The dialogue changed while its form was open.');
    }
    return host;
  }

  void applyEditing(DialogueLocalizationEditing form) {
    final host = _editingHost(form);
    final next = form.build();
    final base = host.savedDialogue(next.id) ?? form.base;
    host.stage((draft) {
      draft.load(StoryDraftKind.dialogue, next.id, base);
      draft.put(StoryDraftKind.dialogue, next);
    });
    changed();
  }

  String copyEditing(DialogueLocalizationEditing form, String name) {
    final host = _editingHost(form);
    if (name.trim().isEmpty) throw ArgumentError('A copy needs a name.');
    final id = 'dialogue_${newDialogueEditorId()}';
    final copied = form.duplicate(id: id, name: name.trim());
    host.stage((draft) {
      draft.load(StoryDraftKind.dialogue, id, null);
      draft.put(StoryDraftKind.dialogue, copied);
    });
    select(id);
    return id;
  }
}
