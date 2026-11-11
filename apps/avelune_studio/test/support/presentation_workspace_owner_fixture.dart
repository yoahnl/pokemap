import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:avelune_studio/features/presentations/coordination/presentation_editing_sessions.dart';
import 'package:avelune_studio/features/presentations/data/local_presentation_adapter.dart';
import 'package:map_core/map_core.dart';

import 'ui11_presentation_fixture.dart';

class CountingPresentationPort implements PresentationPort {
  CountingPresentationPort(this.delegate);
  final PresentationPort delegate;
  int reads = 0, writes = 0;
  Future<void>? gate;

  @override
  Future<PresentationSourceSnapshot> load(String id) {
    reads++;
    return delegate.load(id);
  }

  @override
  Future<PresentationDraftProjection> prepare(ProjectManifest project) async {
    await gate;
    return delegate.prepare(project);
  }

  @override
  Future<PresentationPublicationReceipt> publish({
    required PresentationCinematicAsset asset,
    required PresentationSourceSnapshot? base,
    String? folderId,
    bool changeFolder = false,
    PresentationSceneLink? link,
    List<PresentationStagedMedia> imports = const [],
    List<Map<String, Object?>> mediaBaselines = const [],
  }) {
    writes++;
    return delegate.publish(
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
  }) =>
      delegate.createFolder(id: id, name: name, parentFolderId: parentFolderId);

  @override
  Future<PresentationPublicationReceipt> delete(
    PresentationSourceSnapshot base,
  ) => delegate.delete(base);

  @override
  Future<PresentationPublicationReceipt> setArchived(
    PresentationSourceSnapshot base,
    bool archived,
  ) => delegate.setArchived(base, archived);

  @override
  Future<PresentationStagedMedia> stageMedia({
    required String sourcePath,
    required String label,
    required ProjectMediaKind kind,
  }) => delegate.stageMedia(sourcePath: sourcePath, label: label, kind: kind);

  @override
  Future<void> releaseMedia(PresentationStagedMedia media) =>
      delegate.releaseMedia(media);
}

class PresentationWorkspaceOwnerFixture {
  PresentationWorkspaceOwnerFixture._(
    this.fixture,
    this.maps,
    this.narrative,
    this.port,
    this.controller,
  );

  final Ui11PresentationFixture fixture;
  final MapWorkspaceController maps;
  final NarrativeWorkspaceController narrative;
  final CountingPresentationPort port;
  final PresentationWorkspaceController controller;
  final sessions = PresentationEditingSessions();

  static Future<PresentationWorkspaceOwnerFixture> create() async {
    final fixture = await Ui11PresentationFixture.create();
    final source = fixture.source;
    final maps = MapWorkspaceController(source.session, source.maps);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
      () {},
      (_, _) async {},
    );
    final port = CountingPresentationPort(
      LocalPresentationAdapter(
        session: source.session,
        mapAdapter: source.maps,
      ),
    );
    final controller = PresentationWorkspaceController(
      narrative,
      port,
      changed: () {},
    );
    if (!await controller.open(fixture.asset.id)) {
      throw StateError('${controller.error}');
    }
    port.reads = port.writes = 0;
    return PresentationWorkspaceOwnerFixture._(
      fixture,
      maps,
      narrative,
      port,
      controller,
    );
  }

  PresentationCinematicAsset get asset => controller.active!.asset;

  PresentationClip clip(String id) => asset.tracks
      .expand((track) => track.clips)
      .singleWhere((clip) => clip.id == id);

  Future<PresentationCinematicAsset> reread(String id) async =>
      (await LocalPresentationAdapter(
        session: fixture.source.session,
        mapAdapter: fixture.source.maps,
      ).load(id)).asset;

  Future<void> dispose() async {
    sessions.dispose();
    controller.dispose();
    narrative.dispose();
    maps.dispose();
    await fixture.dispose();
  }
}
