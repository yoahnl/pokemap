import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show AuthoringTransactionFaultInjector, StandardEventTemplateSpec;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../map_workspace/domain/map_workspace_workshop.dart';
import '../../project_session/domain/project_session.dart';
import '../../resources/domain/resource_port.dart';
import '../domain/narrative_port.dart';
import 'narrative_publication_baselines.dart';

part 'local_narrative_publication.dart';

class LocalNarrativeAdapter implements NarrativePort, NarrativeArtworkPort {
  const LocalNarrativeAdapter({
    required this.session,
    required this.mapAdapter,
    this.faultInjector,
    this.reader = const LocalProjectFileReader(),
    this.performanceObserver,
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final AuthoringTransactionFaultInjector? faultInjector;
  final ProjectFileReader reader;
  final AuthoringPerformanceObserver? performanceObserver;

  @override
  Future<Uint8List?> readArtwork(
    NarrativeArtworkKind kind, {
    String? id,
  }) async {
    if (kind != NarrativeArtworkKind.hero &&
        (id == null || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id))) {
      return null;
    }
    final path = switch (kind) {
      NarrativeArtworkKind.hero => 'assets/studio/narrative/hero.png',
      NarrativeArtworkKind.story => 'assets/studio/narrative/stories/$id.png',
      NarrativeArtworkKind.scene => 'assets/studio/narrative/scenes/$id.png',
    };
    try {
      final bytes = await reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: path,
      );
      if (bytes.length < 8 ||
          bytes[0] != 0x89 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x4e ||
          bytes[3] != 0x47) {
        return null;
      }
      return Uint8List.fromList(bytes);
    } on Object {
      return null;
    }
  }

  @override
  Future<NarrativeDialogueSource> readDialogue(
    ProjectDialogueEntry entry,
  ) async {
    final baseline = await mapAdapter.resourceBaseline(session);
    if (!baseline.manifest.dialogues.contains(entry)) {
      throw const NarrativeFailure(
        'Ce dialogue ne figure plus dans le projet.',
      );
    }
    final bytes = await reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: entry.relativePath,
    );
    return NarrativeDialogueSource(
      entry: entry,
      source: utf8.decode(bytes),
      revision: narrativeEventBytesFingerprint(bytes),
    );
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) => _publish(publication);

  Future<NarrativePublicationReceipt> publishStandardEvent(
    NarrativePublication publication,
    StandardEventTemplateSpec template,
  ) => _publish(publication, template: template);
}
