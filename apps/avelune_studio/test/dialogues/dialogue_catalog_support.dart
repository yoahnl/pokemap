import 'package:avelune_studio/features/dialogues/application/dialogue_catalog_controller.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/game_memory/domain/narrative_index_port.dart';
import 'package:avelune_studio/features/story_draft/application/story_draft.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core_domain.dart';

import '../game_memory/game_memory_fakes.dart';

StoryDialogueSource catalogDialogue(String id, {bool localized = true}) {
  const source = 'title: Start\n---\nBonjour le monde.\n===\n';
  final parsed = readLocalizedDialogue(source: source, sourceLocale: 'fr');
  final localization = parsed.localization.translate(
    parsed.localization.units.single.id,
    'en',
    'Hello world.',
  );
  return StoryDialogueSource(
    entry: ProjectDialogueEntry(
      id: id,
      name: 'Dialogue $id',
      relativePath: 'dialogues/$id.yarn',
      localization: localized ? localization : null,
    ),
    source: source,
    revision: 'revision-$id',
  );
}

final class FakeDialogueCatalog implements DialogueCatalogPort {
  final documents = <String, DialogueCatalogDocument>{};
  final requests = <String>[];
  Object? failure;
  int languageReads = 0;
  var profile = const DialogueCatalogLanguages(
    locales: ['fr', 'en', 'es'],
    fallback: 'fr',
  );
  Future<DialogueCatalogDocument> Function(String id)? loader;

  @override
  Future<DialogueCatalogLanguages> languages() async {
    languageReads++;
    return profile;
  }

  @override
  Future<DialogueCatalogDocument> document(String id) async {
    requests.add(id);
    if (failure case final problem?) throw problem;
    if (loader case final read?) return read(id);
    return documents[id] ?? (throw StateError('Unknown dialogue $id'));
  }
}

final class DialogueCatalogHarness {
  DialogueCatalogHarness({int count = 2}) {
    index.titlesByKind[NarrativeTitleKind.dialogues] = [
      for (var i = 0; i < count; i++)
        NarrativeTitle(id: 'talk_$i', title: 'Dialogue $i'),
    ];
    for (var i = 0; i < count; i++) {
      port.documents['talk_$i'] = DialogueCatalogDocument(
        dialogue: catalogDialogue('talk_$i'),
        sceneIds: const ['shared_scene'],
        notCovered: const ['cinematics'],
      );
    }
    controller = DialogueCatalogController(
      index: index,
      port: port,
      draft: draft,
      revision: () => revision,
      changed: () => changes++,
    );
  }

  final index = FakeNarrativeIndex();
  final port = FakeDialogueCatalog();
  final draft = StoryDraft();
  Object revision = Object();
  int changes = 0;
  late final DialogueCatalogController controller;
}
