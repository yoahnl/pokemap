import 'dart:io';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:avelune_studio/features/presentations/data/local_presentation_adapter.dart';
import 'package:map_core/map_core.dart';
import 'cinematic_adapter_fixture.dart';

class Ui11PresentationFixture {
  Ui11PresentationFixture(this.source, this.asset, this.mediaId);
  final CinematicAdapterFixture source;
  final PresentationCinematicAsset asset;
  final String mediaId;
  static Future<Ui11PresentationFixture> create() async {
    final source = await CinematicAdapterFixture.create();
    final maps = MapWorkspaceController(source.session, source.maps);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: source.session, mapAdapter: source.maps),
      () {},
      (_, _) async {},
    );
    final controller = PresentationWorkspaceController(
      narrative,
      LocalPresentationAdapter(
        session: source.session,
        mapAdapter: source.maps,
      ),
      changed: () {},
    );
    try {
      if (!await controller.create(
        title: 'L’appel de l’horizon',
        durationUs: 12000000,
      )) {
        throw StateError(controller.error!);
      }
      final imported = await controller.importMedia(
        sourcePath: File('assets/home/hero_landscape.png').absolute.path,
        label: 'Horizon Avelune',
        kind: ProjectMediaKind.image,
      );
      if (imported == null) throw StateError(controller.error!);
      final imageLayer = PresentationLayer(
        id: 'landscape',
        label: 'Illustration',
        zIndex: 0,
      );
      final textLayer = PresentationLayer(
        id: 'title',
        label: 'Titre principal',
        zIndex: 1,
      );
      final image = PresentationVisualClip(
        id: 'landscape.clip',
        startUs: 0,
        durationUs: 12000000,
        layerId: imageLayer.id,
        resourceId: imported.media.id,
      );
      final text = PresentationTextClip(
        id: 'title.clip',
        startUs: 0,
        durationUs: 10000000,
        layerId: textLayer.id,
        text: 'L’appel de l’horizon',
        style: PresentationTextStyle(
          fontFamily: 'Helvetica Neue',
          fontSize: 64,
          weight: PresentationTextWeight.bold,
          colorHex: '#FFF8E7',
        ),
      );
      final encoded = encodePresentationCinematicAsset(
        PresentationCinematicAsset(
          id: 'seed',
          title: 'Seed',
          durationUs: 12000000,
          layers: [imageLayer, textLayer],
          tracks: [
            PresentationTrack(
              id: 'landscape.track',
              label: 'Illustration',
              kind: PresentationTrackKind.visual,
              clips: [image],
            ),
            PresentationTrack(
              id: 'title.track',
              label: 'Titre principal',
              kind: PresentationTrackKind.visual,
              clips: [text],
            ),
          ],
        ),
      );
      final layers = encoded['layers']! as List,
          tracks = encoded['tracks']! as List;
      for (var i = 0; i < 2; i++) {
        if (!controller.apply('presentationTimeline.insert', {
          'targetVisualFolderId': null,
          'layer': layers[i],
          'track': tracks[i],
        })) {
          throw StateError(controller.error!);
        }
      }
      if (!await controller.save()) throw StateError(controller.error!);
      return Ui11PresentationFixture(
        source,
        controller.active!.asset,
        imported.media.id,
      );
    } finally {
      controller.dispose();
      narrative.dispose();
      maps.dispose();
    }
  }

  Future<void> dispose() => source.dispose();
}
