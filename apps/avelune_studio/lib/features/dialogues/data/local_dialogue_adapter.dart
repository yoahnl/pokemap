import 'dart:convert';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart'
    show
        AuthoringTransactionFaultInjector,
        NarrativeAuthoringException,
        AssetCatalog,
        assetCatalogStorageKey,
        assetBlobStorageKey,
        ContentArtifactRef;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/dialogue_port.dart';
import 'local_dialogue_transaction.dart';

class LocalDialogueAdapter implements DialoguePort, DialoguePortraitPort {
  const LocalDialogueAdapter({
    required this.session,
    required this.mapAdapter,
    this.reader = const LocalProjectFileReader(),
    this.faultInjector,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;
  final AuthoringTransactionFaultInjector? faultInjector;

  @override
  Future<Uint8List?> readPortrait(String characterId, String stateId) async {
    try {
      final baseline = await mapAdapter.resourceBaseline(session);
      final character = baseline.manifest.characters
          .where((value) => value.id == characterId)
          .firstOrNull;
      if (!baseline.manifest.characterStudioCatalog.portraitStates.any(
        (value) => value.id == stateId,
      )) {
        return null;
      }
      final portrait = character?.portraits
          .where((value) => value.portraitStateId == stateId)
          .firstOrNull;
      if (portrait == null) return null;
      final catalog = AssetCatalog.fromJson(
        jsonDecode(
              utf8.decode(
                await reader.readBytes(
                  projectRoot: session.directoryPath,
                  relativePath: assetCatalogStorageKey,
                ),
              ),
            )
            as Map<String, dynamic>,
      );
      final asset = catalog.find(portrait.assetId);
      if (asset == null || asset.artifact.mediaType != 'image/png') return null;
      final bytes = await reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: assetBlobStorageKey(asset.artifact),
      );
      if (ContentArtifactRef.fromBytes(bytes, mediaType: 'image/png').digest !=
          asset.artifact.digest) {
        return null;
      }
      return Uint8List.fromList(bytes);
    } on Object {
      return null;
    }
  }

  @override
  Future<DialogueSourceSnapshot> load(String id) =>
      mapAdapter.withResourceMutation(() async {
        try {
          final baseline = await mapAdapter.resourceBaseline(
            session,
            refreshCatalog: true,
          );
          final entries = baseline.manifest.dialogues.where((e) => e.id == id);
          if (entries.length != 1) {
            throw const DialogueFailure('Ce dialogue est absent du projet.');
          }
          final entry = entries.single;
          final bytes = await reader.readBytes(
            projectRoot: session.directoryPath,
            relativePath: entry.relativePath,
          );
          await mapAdapter.resourceBaseline(session);
          return DialogueSourceSnapshot(
            entry: entry,
            source: utf8.decode(bytes, allowMalformed: false),
            revision: narrativeEventBytesFingerprint(bytes),
          );
        } on DialogueFailure {
          rethrow;
        } on Object catch (error) {
          throw DialogueFailure('Impossible de lire ce dialogue : $error');
        }
      });

  @override
  Future<DialoguePublicationReceipt> publish({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
  }) => mapAdapter.withResourceMutation(() async {
    try {
      if ((entry == null) != (source == null) ||
          (entry != null && entry.id != id) ||
          (base != null && base.entry.id != id) ||
          (base == null && entry == null)) {
        throw const DialogueFailure(
          'La publication ne correspond pas au dialogue.',
        );
      }
      return await LocalDialogueTransaction(
        session: session,
        mapAdapter: mapAdapter,
        faultInjector: faultInjector,
      ).run(id: id, base: base, entry: entry, source: source);
    } on DialogueFailure {
      rethrow;
    } on NarrativeAuthoringException catch (error) {
      final references = error.details['references'];
      final consumers = references is List && references.isNotEmpty
          ? '\nUtilisé par : ${references.join(', ')}'
          : '';
      throw DialogueFailure(
        'Le dialogue n’a pas été enregistré : ${error.message}$consumers',
        details: {'code': error.code, ...error.details},
      );
    } on Object catch (error) {
      throw DialogueFailure(
        'Le dialogue n’a pas été enregistré. Votre brouillon reste ouvert : $error',
      );
    }
  });
}
