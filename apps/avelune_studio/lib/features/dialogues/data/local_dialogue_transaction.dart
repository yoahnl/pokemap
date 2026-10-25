import 'dart:convert';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring_dialogue.dart'
    show DialogueLineTextEdit;
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../narrative/data/local_narrative_catalog_transaction.dart';
import '../domain/dialogue_port.dart';

class LocalDialogueTransaction {
  const LocalDialogueTransaction({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;

  Future<DialoguePublicationReceipt> run({
    required String id,
    required DialogueSourceSnapshot? base,
    required ProjectDialogueEntry? entry,
    required String? source,
    List<DialogueLineTextEdit>? lineTextEdits,
  }) async {
    final action = entry == null
        ? 'dialogue.delete'
        : base == null
        ? 'dialogue.create'
        : entry == base.entry
        ? 'dialogue.source_update'
        : 'dialogue.update';
    final path = entry?.relativePath ?? base!.entry.relativePath;
    final resources =
        await LocalNarrativeCatalogTransaction(
          session: session,
          mapAdapter: mapAdapter,
          faultInjector: faultInjector,
        ).run(
          actionId: action,
          refreshCatalog: true,
          allowedStorageKeys: {path},
          parameters: (_) => {
            if (action == 'dialogue.delete' ||
                action == 'dialogue.source_update')
              'dialogueId': id
            else
              'entry': entry!.toJson(),
            'source': ?source,
            if (lineTextEdits != null)
              'lineTextEdits': lineTextEdits
                  .map((edit) => edit.toJson())
                  .toList(),
          },
          validateSnapshot: (snapshot) {
            final actual = snapshot.manifest.dialogues
                .where((value) => value.id == id)
                .firstOrNull;
            if (actual != base?.entry ||
                (base != null &&
                    narrativeEventBytesFingerprint(
                          snapshot.resourceBytes('dialogueSource:$id'),
                        ) !=
                        base.revision)) {
              throw const DialogueFailure(
                'Ce dialogue a changé sur le disque. Le brouillon reste ouvert ; rechargez pour reprendre la version actuelle.',
              );
            }
          },
        );
    const reader = LocalProjectFileReader();
    if (source != null) {
      final written = await reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: path,
      );
      if (narrativeEventBytesFingerprint(written) !=
          narrativeEventBytesFingerprint(utf8.encode(source))) {
        throw const DialogueFailure(
          'Le reçu ne correspond pas à la source. Le brouillon reste ouvert.',
        );
      }
    } else {
      final probe = await reader.probeResource(
        projectRoot: session.directoryPath,
        relativePath: path,
      );
      if (probe.status != ProjectResourceProbeStatus.missing) {
        throw const DialogueFailure(
          'La suppression de la source n’est pas confirmée.',
        );
      }
    }
    return DialoguePublicationReceipt(
      resources: resources,
      snapshot: entry == null
          ? null
          : DialogueSourceSnapshot(
              entry: entry,
              source: source!,
              revision: narrativeEventBytesFingerprint(utf8.encode(source)),
            ),
    );
  }
}
