import 'dart:io';
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
    final port = LocalPresentationAdapter(
      session: source.session,
      mapAdapter: source.maps,
    );
    final draft = await port.prepare(
      await source.maps.loadProject(source.session),
    );
    final imported = await port.stageMedia(
      sourcePath: File('assets/home/hero_landscape.png').absolute.path,
      label: 'Horizon Avelune',
      kind: ProjectMediaKind.image,
    );
    draft.includeMedia([imported]);
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
    final asset = PresentationCinematicAsset(
      id: 'presentation_ui11',
      title: 'L’appel de l’horizon',
      durationUs: 12000000,
      layers: [imageLayer, textLayer],
      tracks: [
        PresentationTrack(
          id: 'landscape.track',
          label: 'Illustration',
          kind: PresentationTrackKind.visual,
          clips: [
            PresentationVisualClip(
              id: 'landscape.clip',
              startUs: 0,
              durationUs: 12000000,
              layerId: imageLayer.id,
              resourceId: imported.media.id,
            ),
          ],
        ),
        PresentationTrack(
          id: 'title.track',
          label: 'Titre principal',
          kind: PresentationTrackKind.visual,
          clips: [
            PresentationTextClip(
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
            ),
          ],
        ),
      ],
    );
    await port.publish(
      asset: asset,
      base: null,
      imports: [imported],
      mediaBaselines: draft.mediaBaselines,
    );
    return Ui11PresentationFixture(source, asset, imported.media.id);
  }

  Future<void> dispose() => source.dispose();
}
