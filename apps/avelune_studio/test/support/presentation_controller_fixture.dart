import 'dart:async';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:avelune_studio/features/presentations/data/local_presentation_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:map_core/map_core_domain.dart';
import 'cinematic_adapter_fixture.dart';

class PresentationControllerFixture {
  PresentationControllerFixture(
    this.files,
    this.maps,
    this.narrative,
    this.port,
    this.controller,
  );
  final CinematicAdapterFixture files;
  final MapWorkspaceController maps;
  final NarrativeWorkspaceController narrative;
  final DelayedPresentationPort port;
  final PresentationWorkspaceController controller;
  static Future<PresentationControllerFixture> create() async {
    final f = await CinematicAdapterFixture.create();
    final maps = MapWorkspaceController(f.session, f.maps);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: f.session, mapAdapter: f.maps),
      () {},
      (_, _) async {},
    );
    final port = DelayedPresentationPort(
      LocalPresentationAdapter(session: f.session, mapAdapter: f.maps),
    );
    final controller = PresentationWorkspaceController(
      narrative,
      port,
      changed: () {},
    );
    return PresentationControllerFixture(f, maps, narrative, port, controller);
  }

  Future<void> dispose() async {
    controller.dispose();
    narrative.dispose();
    maps.dispose();
    await files.dispose();
  }
}

class DelayedPresentationPort implements PresentationPort {
  DelayedPresentationPort(this.inner);
  final PresentationPort inner;
  Completer<void>? publishGate, loadGate;
  String? delayedId;
  @override
  Future<PresentationSourceSnapshot> load(String id) async {
    if (id == delayedId) await loadGate?.future;
    return inner.load(id);
  }

  @override
  Future<PresentationDraftProjection> prepare(ProjectManifest project) =>
      inner.prepare(project);
  @override
  Future<PresentationPublicationReceipt> publish({
    required PresentationCinematicAsset asset,
    required PresentationSourceSnapshot? base,
    String? folderId,
    bool changeFolder = false,
    PresentationSceneLink? link,
    List<PresentationStagedMedia> imports = const [],
    List<Map<String, Object?>> mediaBaselines = const [],
  }) async {
    await publishGate?.future;
    return inner.publish(
      asset: asset,
      base: base,
      folderId: folderId,
      changeFolder: changeFolder,
      link: link,
      imports: imports,
      mediaBaselines: mediaBaselines,
    );
  }

  @override
  Future<PresentationPublicationReceipt> createFolder({
    required String id,
    required String name,
    String? parentFolderId,
  }) => inner.createFolder(id: id, name: name, parentFolderId: parentFolderId);
  @override
  Future<PresentationPublicationReceipt> delete(
    PresentationSourceSnapshot base,
  ) => inner.delete(base);
  @override
  Future<PresentationPublicationReceipt> setArchived(
    PresentationSourceSnapshot base,
    bool archived,
  ) => inner.setArchived(base, archived);
  @override
  Future<PresentationStagedMedia> stageMedia({
    required String sourcePath,
    required String label,
    required ProjectMediaKind kind,
  }) => inner.stageMedia(sourcePath: sourcePath, label: label, kind: kind);
  @override
  Future<void> releaseMedia(PresentationStagedMedia media) =>
      inner.releaseMedia(media);
}
