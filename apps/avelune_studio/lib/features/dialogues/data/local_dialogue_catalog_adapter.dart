import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../game_memory/data/local_narrative_read.dart';
import '../../project_session/domain/project_session.dart';
import '../../story_draft/domain/story_dialogue_source.dart';
import '../domain/dialogue_catalog_port.dart';

final class LocalDialogueCatalogAdapter implements DialogueCatalogPort {
  const LocalDialogueCatalogAdapter(
    this.session, {
    this.reader = const LocalProjectFileReader(),
  });

  final ProjectSession session;
  final ProjectFileReader reader;

  @override
  Future<DialogueCatalogDocument> document(String id) =>
      readNarrativeIndex(session, reader, (reads, handle) async {
        final result = await reads.queryProject(
          handle,
          AuthoringQueryRequest(
            resourceKind: dialogueDocumentResourceKind,
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: [id],
            pageSize: 1,
          ),
        );
        final item = result.items.single;
        final entry = ProjectDialogueEntry.fromJson(
          Map<String, dynamic>.from(item['entry'] as Map),
        );
        final source = item['source'];
        if (source is! String) {
          throw const FileSystemException(
            'La source du dialogue est introuvable.',
          );
        }
        final usages = item['usages'] as Map;
        return DialogueCatalogDocument(
          dialogue: StoryDialogueSource(
            entry: entry,
            source: source,
            revision: item['revision'] as String?,
          ),
          sceneIds: List<String>.from(usages['sceneIds'] as List),
          notCovered: List<String>.from(usages['notCovered'] as List),
        );
      }, initializeSceneOwners: false);

  @override
  Future<DialogueCatalogLanguages> languages() async {
    final profile = await GamePackageExportProfileStore(
      projectRoot: Directory(session.directoryPath),
    ).load();
    return DialogueCatalogLanguages(
      locales: profile?.supportedLocales ?? const [],
      fallback: profile?.defaultLocale,
    );
  }
}
