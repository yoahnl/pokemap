import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/dialogues/application/dialogue_localization_editing.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_catalog_adapter.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/story_draft/domain/story_dialogue_source.dart';
import 'package:avelune_studio/features/story_draft/application/story_dialogue_text_edits.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_metadata_documents.dart';
import 'package:map_authoring/src/workspace/catalog/catalog_project_reader.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

const _source = 'title: Start\n---\nBonjour !\n===\n';

void main() {
  final baselineAccesses = <int, int>{};
  for (final unrelated in [0, 120]) {
    test(
      'publication ignores $unrelated unrelated dialogue, scene and Fact documents',
      () async {
        final qa = Directory(
          '/Users/karim/Library/Caches/AveluneQA/histoire-d2b-01a1e117/tests',
        );
        final root = await (await qa.create(recursive: true))
            .createTemp('catalog-');
        addTearDown(() => root.delete(recursive: true));
        final localized = readLocalizedDialogue(
          source: _source,
          sourceLocale: 'fr',
        );
        final entry = ProjectDialogueEntry(
          id: 'selected',
          name: 'Partagé',
          relativePath: 'dialogues/selected.yarn',
          localization: localized.localization,
        );
        final store = await CatalogStorageStore.open(projectRoot: root.path);
        final working = await WorkingProjectCatalog.create(
          store: store,
          projectId: 'd2b',
          project: ProjectManifest(
            name: 'D2b',
            maps: const [],
            settings: const ProjectSettings(defaultPlayerCharacterId: 'hero'),
            groups: const [
              ProjectMapGroup(
                id: 'parent',
                name: 'Parent',
                type: MapGroupType.city,
              ),
              ProjectMapGroup(
                id: 'group',
                name: 'Group',
                type: MapGroupType.city,
                parentGroupId: 'parent',
              ),
            ],
            tilesetFolders: const [
              ProjectTilesetFolder(id: 'folder', name: 'Folder'),
            ],
            tilesets: const [
              ProjectTilesetEntry(
                id: 'hero-tiles',
                name: 'Hero',
                relativePath: 'assets/hero.png',
                scope: TilesetScope.group,
                groupId: 'group',
                folderId: 'folder',
              ),
            ],
            characterStudioCatalog: const ProjectCharacterStudioCatalog(
              portraitStates: [
                CharacterPortraitStateDefinition(
                  id: 'custom-happy',
                  displayName: 'Happy',
                ),
              ],
            ),
            characters: const [
              ProjectCharacterEntry(
                id: 'hero',
                name: 'Hero',
                tilesetId: 'hero-tiles',
                portraits: [
                  CharacterPortraitVariant(
                    portraitStateId: 'custom-happy',
                    assetId: 'hero-portrait',
                  ),
                ],
              ),
            ],
            dialogues: [
              entry,
              for (var i = 0; i < unrelated; i++)
                entry.copyWith(
                  id: 'foreign_$i',
                  relativePath: 'dialogues/foreign_$i.yarn',
                ),
            ],
            scenes: [
              _scene('a', entry.id),
              _scene('b', entry.id),
              for (var i = 0; i < unrelated; i++)
                _scene('foreign_$i', 'foreign_$i'),
            ],
            facts: [
              for (var i = 0; i < unrelated; i++)
                NarrativeFactDefinition(id: 'foreign_$i', label: 'Foreign'),
            ],
          ),
        );
        await store.prepareLocalEditing();
        final sourceFile = File('${root.path}/${entry.relativePath}');
        await sourceFile.parent.create(recursive: true);
        await sourceFile.writeAsString(_source);
        final session = ProjectSession(
          sessionId: root.path,
          name: 'D2b',
          directoryPath: root.path,
          storage: ProjectSessionStorage.workingCatalog,
        );
        final maps = LocalMapWorkspaceAdapter();
        await maps.loadProject(session);
        final foreignPaths = <String>{};
        for (var i = 0; i < unrelated; i++) {
          for (final field in ['dialogues', 'scenes', 'facts']) {
            final row = (await working.catalog.snapshot.lookup(
              CatalogMetadataDocuments.documentKey(field, 'foreign_$i'),
            ))!;
            final unit = (await working.catalog.snapshot.indexEntry(
              CatalogMetadataDocuments.definitionKey(
                field,
                row.payload['position'] as int,
              ),
            ))!;
            final path =
                '${root.path}/catalog/objects/${unit.reference.sha256}.json';
            foreignPaths.add(path);
            await File(path)
                .writeAsString('Unrelated document must stay unread.');
          }
        }
        await working.close();
        final descriptor = await File('${root.path}/project.json')
            .readAsBytes();
        final port = LocalDialogueAdapter(session: session, mapAdapter: maps);
        var base = DialogueSourceSnapshot(
          entry: entry,
          source: _source,
          revision: narrativeEventBytesFingerprint(
            await sourceFile.readAsBytes(),
          ),
        );
        final outside = Zone.current;
        for (var step = 0; step < 2; step++) {
          final form = DialogueLocalizationEditing(
            StoryDialogueSource(
              entry: base.entry,
              source: base.source,
              revision: base.revision,
            ),
          );
          final id = form.localization.units.single.id;
          if (step == 0) {
            form.writeTranslation(id, 'en', 'Hello !');
          } else {
            form.writeSource(id, 'Salut !');
          }
          final next = form.build();
          final accesses = <String>[];
          final receipt = await IOOverrides.runZoned(
            () => port.publish(
              id: entry.id,
              base: base,
              entry: next.entry,
              source: next.source,
              lineTextEdits: storyDialogueTextEdits(form.base, next),
            ),
            createFile: (path) {
              accesses.add(path);
              return outside.run(() => File(path));
            },
          );
          expect(accesses.where(foreignPaths.contains), isEmpty);
          if (unrelated == 0) {
            baselineAccesses[step] = accesses.length;
          } else {
            expect(accesses.length, lessThan(baselineAccesses[step]! * 1.1));
          }
          debugPrint(
            'D2b foreign=$unrelated operation=$step filesystem accesses=${accesses.length}; writes=${receipt.resources.changedPaths}',
          );
          expect(
            accesses
                .where((path) => path.endsWith('.yarn'))
                .map(
                  (path) => p.isAbsolute(path) ? path : p.join(root.path, path),
                )
                .toSet(),
            {sourceFile.path},
          );
          expect(
            receipt.resources.changedPaths,
            unorderedEquals([
              'catalog/HEAD.json',
              if (step == 1) entry.relativePath,
            ]),
          );
          final reopened = await LocalDialogueCatalogAdapter(session)
              .document(entry.id);
          expect(reopened.dialogue.entry.localization, next.entry.localization);
          expect(reopened.dialogue.source, next.source);
          expect(reopened.sceneIds.toSet(), {'a', 'b'});
          expect(
            await File('${root.path}/project.json').readAsBytes(),
            descriptor,
          );
          base = receipt.snapshot!;
        }
        final head = await File('${root.path}/catalog/HEAD.json').readAsBytes();
        await expectLater(
          port.publish(
            id: entry.id,
            base: base,
            entry: base.entry,
            source: base.source.replaceFirst('Salut', 'Coucou'),
          ),
          throwsA(isA<DialogueFailure>()),
        );
        expect(
          await File('${root.path}/catalog/HEAD.json').readAsBytes(),
          head,
        );
        expect(await sourceFile.readAsString(), base.source);
        final reader = (await CatalogProjectReader.open(
          store: store,
          descriptor: working.descriptor.toJson(),
          metadataFields: {},
        ))!;
        final scenes = await reader.read(
          (catalog) => CatalogMetadataDocuments.readDocuments(
            snapshot: catalog.snapshot,
            project: catalog.projectMetadata,
            ids: {
              'scenes': {'a', 'b'},
            },
          ),
        );
        for (final scene in scenes.project.scenes) {
          final payload =
              scene.graph.nodes
                      .singleWhere(
                        (node) => node.kind == SceneNodeKind.yarnDialogue,
                      )
                      .payload
                  as SceneYarnDialoguePayload;
          expect(payload.linePolicies.single.feedback.plainText, 'Salut !');
        }
        final form = DialogueLocalizationEditing(
          StoryDialogueSource(
            entry: base.entry,
            source: base.source,
            revision: base.revision,
          ),
        );
        final copy = form.duplicate(id: 'copy', name: 'Copie');
        await port.publish(
          id: copy.id,
          base: null,
          entry: copy.entry,
          source: copy.source,
        );
        final reopenedCopy = await LocalDialogueCatalogAdapter(session)
            .document(copy.id);
        expect(reopenedCopy.sceneIds, isEmpty);
        expect(
          reopenedCopy.dialogue.entry.localization,
          copy.entry.localization,
        );
        expect(
          copy.entry.localization!.units.single.id,
          isNot(base.entry.localization!.units.single.id),
        );
        expect(
          copy.entry.localization!.units.single.translations,
          base.entry.localization!.units.single.translations,
        );
        final original = await LocalDialogueCatalogAdapter(session)
            .document(base.entry.id);
        expect(original.dialogue.entry, base.entry);
        expect(original.sceneIds.toSet(), {'a', 'b'});
      },
    );
  }
}

SceneAsset _scene(String id, String dialogue) => SceneAsset(
  id: id,
  name: id,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(
          dialogueId: dialogue,
          linePolicies: [
            SceneDialogueLinePolicy(
              nodeName: 'Start',
              lineIndex: 0,
              feedback: DialogueLineFeedback(
                segments: [DialogueTextSegment('Bonjour !')],
              ),
            ),
          ],
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'first',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'dialogue',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'last',
        fromNodeId: 'dialogue',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
);
