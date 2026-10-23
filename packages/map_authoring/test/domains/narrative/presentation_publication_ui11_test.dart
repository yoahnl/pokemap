import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/src/domains/narrative/presentation_publication_guards.dart';

void main() {
  test('targeted Presentation publication is canonical and atomic', () async {
    final dispatcher = MapMutationDispatcher.canonical();
    expect(dispatcher.descriptors.map((e) => e.id),
        contains('presentationCinematic.publish'));
    final action = dispatcher.descriptors
        .singleWhere((a) => a.id == 'presentationCinematic.publish');
    expect(
        action.guarantees,
        containsAll([
          AuthoringGuarantee.atomic,
          AuthoringGuarantee.revisionChecked,
          AuthoringGuarantee.undoable
        ]));
  });
  final cinematic = PresentationCinematicAsset(
    id: 'animated',
    title: 'Animated',
    durationUs: 1000000,
    layers: [PresentationLayer(id: 'title', label: 'Title', zIndex: 0)],
    tracks: [
      PresentationTrack(
          id: 'visuals',
          label: 'Visuals',
          kind: PresentationTrackKind.visual,
          clips: [
            PresentationTextClip(
                id: 'title',
                layerId: 'title',
                text: 'Opening',
                startUs: 0,
                durationUs: 1000000,
                from: PresentationVisualComposition(opacity: 1),
                to: PresentationVisualComposition(translateX: 1))
          ])
    ],
  );
  test('publication accepts equivalent JSON numbers from JavaScript baselines',
      () {
    final encoded = encodePresentationCinematicAsset(cinematic);
    final expected = _javascriptJsonNumbers(encoded);
    expect(
        computeAuthoringJsonFingerprint(expected, logicalName: 'baseline'),
        isNot(
            computeAuthoringJsonFingerprint(encoded, logicalName: 'baseline')));
    expect(
        () => validatePresentationPublicationBase(
                _publicationSnapshot(cinematic), cinematic.id, {
              'expectedCinematic': expected,
              'expectedEntry': null,
            }),
        returnsNormally);
  });
  test('publication still rejects a genuinely changed numeric baseline', () {
    final expected =
        _javascriptJsonNumbers(encodePresentationCinematicAsset(cinematic))
            as Map;
    final clips = ((expected['tracks'] as List).single as Map)['clips'] as List;
    ((clips.single as Map)['to'] as Map)['translateX'] = 0.5;
    expect(
        () => validatePresentationPublicationBase(
                _publicationSnapshot(cinematic), cinematic.id, {
              'expectedCinematic': expected,
              'expectedEntry': null,
            }),
        throwsA(isA<StateError>()));
  });
}

ProjectSnapshot _publicationSnapshot(PresentationCinematicAsset cinematic) {
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('project_publication_baseline'),
    revision: 'sha256:${List<String>.filled(64, 'a').join()}',
    manifest: ProjectManifest(
      name: 'Publication baseline',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()),
      maps: const [],
      tilesets: const [],
      presentationCinematics: [cinematic],
    ),
    maps: const [],
    resourceFingerprints: const {},
    resourceBytes: const {},
  );
}

Object? _javascriptJsonNumbers(Object? value) => switch (value) {
      double value when value == value.roundToDouble() => value.toInt(),
      Map value => <String, Object?>{
          for (final entry in value.entries)
            entry.key as String: _javascriptJsonNumbers(entry.value),
        },
      List value => value.map(_javascriptJsonNumbers).toList(),
      _ => value,
    };
