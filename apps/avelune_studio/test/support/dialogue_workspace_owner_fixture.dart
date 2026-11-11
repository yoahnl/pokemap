import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/dialogues/application/dialogue_workspace_controller.dart';
import 'package:avelune_studio/features/dialogues/data/local_dialogue_adapter.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'package:map_core/map_core.dart';

import '../../tool/example_project_assets.dart';
import 'ui06_scene_fixture.dart';
import 'ui09_runtime_fixture.dart';

class DialogueWorkspaceOwnerFixture {
  DialogueWorkspaceOwnerFixture._(
    this.source,
    this.maps,
    this.workspace,
    this.narrative,
    this.port,
  ) {
    dialogues = DialogueWorkspaceController(narrative, port, changed: () {});
  }

  final Ui06SceneFixture source;
  final LocalMapWorkspaceAdapter maps;
  final MapWorkspaceController workspace;
  final NarrativeWorkspaceController narrative;
  final CountingDialoguePort port;
  late final DialogueWorkspaceController dialogues;

  LocalDialogueAdapter get disk =>
      LocalDialogueAdapter(session: source.session, mapAdapter: maps);

  Future<String> savedSource() async => (await disk.load(ui09DialogueId)).source;

  static Future<DialogueWorkspaceOwnerFixture> create({
    String yarn = guichetDialogueSource,
  }) async {
    final source = await createUi09RuntimeFixture();
    try {
      await _seedPortrait(source);
      final maps = LocalMapWorkspaceAdapter();
      await maps.loadProject(source.session);
      final adapter = LocalDialogueAdapter(
        session: source.session,
        mapAdapter: maps,
      );
      final before = await adapter.load(ui09DialogueId);
      final parsed = parseYarnToDocument(yarn, entryNodeTitle: 'Accueil');
      await adapter.publish(
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
      final workspace = MapWorkspaceController(source.session, maps);
      await workspace.initialize();
      final narrative = NarrativeWorkspaceController(
        workspace,
        LocalNarrativeAdapter(session: source.session, mapAdapter: maps),
        () {},
        (_, _) async {},
      );
      return DialogueWorkspaceOwnerFixture._(
        source,
        maps,
        workspace,
        narrative,
        CountingDialoguePort(adapter),
      );
    } catch (_) {
      await source.dispose();
      rethrow;
    }
  }

  Future<void> dispose() async {
    dialogues.dispose();
    narrative.dispose();
    workspace.dispose();
    await source.dispose();
  }

  static Future<void> _seedPortrait(Ui06SceneFixture source) async {
    final file = File('${source.directory.path}/project.json');
    final project = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    final atlas = image.decodePng(Uint8List.fromList(exampleAtlasPng()))!;
    final bytes = image.encodePng(
      image.copyCrop(atlas, x: 137, y: 0, width: 16, height: 32),
    );
    final artifact = ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png');
    final blob = File('${source.directory.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    await File('${source.directory.path}/$assetCatalogStorageKey').writeAsString(
      jsonEncode(
        AssetCatalog(
          records: [
            AssetRecord(
              id: 'owner_guide_portrait',
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
                              assetId: 'owner_guide_portrait',
                            ),
                          ],
                        )
                      : character,
              ],
            )
            .toJson(),
      ),
    );
  }
}

class CountingDialoguePort implements DialoguePort, DialoguePortraitPort {
  CountingDialoguePort(this.delegate);
  final LocalDialogueAdapter delegate;
  int reads = 0, writes = 0;

  @override
  Future<DialogueSourceSnapshot> load(String id) {
    reads++;
    return delegate.load(id);
  }

  @override
  Future<Uint8List?> readPortrait(String characterId, String stateId) =>
      delegate.readPortrait(characterId, stateId);

  @override
  Future<DialoguePublicationReceipt> publish({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
    List<DialogueLineTextEdit>? lineTextEdits,
  }) {
    writes++;
    return delegate.publish(
      id: id,
      base: base,
      entry: entry,
      source: source,
      lineTextEdits: lineTextEdits,
    );
  }
}

const guichetDialogueSource = '''title: Accueil
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
