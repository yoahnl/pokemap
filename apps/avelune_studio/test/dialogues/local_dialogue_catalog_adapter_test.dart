import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/dialogues/data/local_dialogue_catalog_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'dialogue_catalog_support.dart';

void main() {
  test(
    'Studio reads only one document from a partial working catalog',
    () async {
      final qa = Directory(
        '/Users/karim/Library/Caches/AveluneQA/histoire-d2a-01a1e117/adapters',
      );
      final root = await (await qa.create(recursive: true))
          .createTemp('project-');
      addTearDown(() => root.delete(recursive: true));
      final dialogue = catalogDialogue('selected');
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final working = await WorkingProjectCatalog.create(
        store: store,
        projectId: 'dialogue-catalog-test',
        project: ProjectManifest(
          name: 'Catalogue',
          maps: const [],
          tilesets: const [],
          dialogues: [
            dialogue.entry,
            for (var i = 0; i < 500; i++)
              dialogue.entry.copyWith(
                id: 'other_$i',
                relativePath: 'dialogues/other_$i.yarn',
              ),
          ],
        ),
      );
      await working.close();
      final file = File('${root.path}/${dialogue.relativePath}');
      await file.parent.create(recursive: true);
      await file.writeAsString(dialogue.source);
      final head = await File('${root.path}/catalog/HEAD.json').readAsBytes();
      final port = LocalDialogueCatalogAdapter(
        ProjectSession(
          sessionId: 'owned',
          name: 'Catalogue',
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        ),
      );
      final outside = Zone.current;
      final sources = <String>[];
      final result = await IOOverrides.runZoned(
        () => port.document('selected'),
        createFile: (path) {
          if (path.endsWith('.yarn')) sources.add(path);
          return outside.run(() => File(path));
        },
      );
      expect(result.dialogue.entry, dialogue.entry);
      expect(result.dialogue.source, dialogue.source);
      expect(sources, isNotEmpty);
      expect(
        sources
            .map((path) => p.isAbsolute(path) ? path : p.join(root.path, path))
            .toSet(),
        {file.path},
      );
      expect(result.notCovered, isNotEmpty);
      expect(await File('${root.path}/catalog/HEAD.json').readAsBytes(), head);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
