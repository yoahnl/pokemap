import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';

import '../../tool/example_project_assets.dart';
import 'm2_ui_fixture.dart';
import 'ui06_scene_fixture.dart';
import 'ui09_runtime_fixture.dart';

class Ui09DialogueFixture {
  Ui09DialogueFixture(this.source, this.maps);
  final Ui06SceneFixture source;
  final LocalMapWorkspaceAdapter maps;
  Directory get directory => source.directory;
  LocalDialogueAdapter get port =>
      LocalDialogueAdapter(session: source.session, mapAdapter: maps);

  static Future<Ui09DialogueFixture> create() async {
    final source = await createUi09RuntimeFixture();
    try {
      final file = File('${source.directory.path}/project.json');
      final project = ProjectManifest.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
      final atlas = image.decodePng(Uint8List.fromList(exampleAtlasPng()))!;
      final portrait = image.copyResize(
        image.copyCrop(atlas, x: 137, y: 0, width: 16, height: 32),
        width: 64,
        height: 128,
        interpolation: image.Interpolation.nearest,
      );
      final bytes = image.encodePng(portrait);
      final artifact = ContentArtifactRef.fromBytes(
        bytes,
        mediaType: 'image/png',
      );
      final blob = File(
        '${source.directory.path}/${assetBlobStorageKey(artifact)}',
      );
      await blob.parent.create(recursive: true);
      await blob.writeAsBytes(bytes);
      await File(
        '${source.directory.path}/$assetCatalogStorageKey',
      ).writeAsString(
        jsonEncode(
          AssetCatalog(
            records: [
              AssetRecord(
                id: 'ui09_guide_portrait',
                logicalPath: 'portraits/guide.png',
                artifact: artifact,
              ),
            ],
          ).toJson(),
        ),
      );
      await file.writeAsString(
        jsonEncode(
          project
              .copyWith(
                characterStudioCatalog: const ProjectCharacterStudioCatalog(
                  portraitStates: [
                    CharacterPortraitStateDefinition(
                      id: 'neutral',
                      displayName: 'Calme',
                    ),
                  ],
                ),
                characters: [
                  for (final character in project.characters)
                    character.id == 'guide'
                        ? character.copyWith(
                            name: 'Chef de gare',
                            portraits: const [
                              CharacterPortraitVariant(
                                portraitStateId: 'neutral',
                                assetId: 'ui09_guide_portrait',
                              ),
                            ],
                          )
                        : character,
                ],
              )
              .toJson(),
        ),
      );
      final fixture = Ui09DialogueFixture(source, LocalMapWorkspaceAdapter());
      await fixture.maps.loadProject(source.session);
      final before = await fixture.port.load(ui09DialogueId);
      final parsed = parseYarnToDocument(_source, entryNodeTitle: 'Accueil');
      await fixture.port.publish(
        id: ui09DialogueId,
        base: before,
        entry: before.entry,
        source: emitDocumentToYarn(
          DialogueEditorDocument(
            nodes: parsed.nodes,
            entryNodeId: parsed.entryNodeId,
          ),
        ),
      );
      return fixture;
    } catch (_) {
      await source.dispose();
      rethrow;
    }
  }

  bool dirtyConsumer(SceneWorkspaceController controller) {
    if (!controller.open(Ui06SceneFixture.sceneId)) return false;
    return controller.active!.rename(
      'Rencontre au guichet — brouillon conservé',
    );
  }

  LocalSceneAdapter get scenes =>
      LocalSceneAdapter(session: source.session, mapAdapter: maps);
  Future<void> dispose() => source.dispose();
}

class WidgetDialoguePort implements DialoguePort, DialoguePortraitPort {
  WidgetDialoguePort(this.delegate, this.tester);
  final LocalDialogueAdapter delegate;
  final WidgetTester tester;
  int reads = 0, writes = 0, portraitReads = 0;
  final _portraits = <String, Future<Uint8List?>>{};
  Future<T> _run<T>(Future<T> Function() action) async {
    final operation = tester.runAsync(() async {
      try {
        return (await action(), null);
      } catch (failure) {
        return (null, failure);
      }
    });
    WidgetResourcePort.pending = operation;
    try {
      final result = (await operation)!;
      if (result.$2 case final failure?) throw failure;
      return result.$1 as T;
    } finally {
      if (identical(WidgetResourcePort.pending, operation)) {
        WidgetResourcePort.pending = null;
      }
    }
  }

  @override
  Future<DialogueSourceSnapshot> load(String id) {
    reads++;
    return _run(() => delegate.load(id));
  }

  @override
  Future<Uint8List?> readPortrait(String characterId, String stateId) {
    portraitReads++;
    return _portraits.putIfAbsent(
      '$characterId:$stateId',
      () => _run(() => delegate.readPortrait(characterId, stateId)),
    );
  }

  @override
  Future<DialoguePublicationReceipt> publish({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
  }) {
    writes++;
    return _run(
      () => delegate.publish(id: id, base: base, entry: entry, source: source),
    );
  }
}

const _source = '''title: Accueil
---
<<portrait guide neutral>>
Chef: Bonjour ! Souhaitez-vous préparer votre départ ?
-> Je pars maintenant
    <<outcome depart>>
    <<jump Depart>>
-> Je préfère attendre
    <<outcome attente>>
    <<jump Attente>>
===
title: Depart
---
<<portrait guide neutral>>
Chef: Votre train vous attend sur le quai.
===
title: Attente
---
<<portrait guide neutral>>
Chef: Prenez votre temps dans la salle d’attente.
===
''';
