import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/presentations/application/presentation_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/presentation_controller_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PresentationControllerFixture fixture;
  late PresentationWorkspaceController controller;
  var mediaCount = 0;

  setUp(() async {
    final parent = Directory(
      '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
    );
    await parent.create(recursive: true);
    fixture = await IOOverrides.runZoned(
      PresentationControllerFixture.create,
      getSystemTempDirectory: () => parent,
    );
    controller = fixture.controller;
    expect(await controller.create(title: 'Médias du montage'), isTrue);
    mediaCount = 0;
  });
  tearDown(() => fixture.dispose());

  Future<ProjectMediaAsset> import(ProjectMediaKind kind) async {
    final source = switch (kind) {
      ProjectMediaKind.image => File('assets/home/hero_landscape.png'),
      ProjectMediaKind.audio => File(
        '../../packages/map_runtime/assets/audio/overworld/jump.wav',
      ),
      ProjectMediaKind.video =>
        await fixture.files.file('source.mp4').writeAsBytes(_videoMetadata()),
      ProjectMediaKind.captions =>
        await fixture.files
            .file('source.vtt')
            .writeAsString('WEBVTT\n\n00:00.000 --> 00:01.000\nBonjour\n'),
      _ => throw ArgumentError.value(kind),
    };
    final media = await controller.importMedia(
      sourcePath: source.absolute.path,
      label: '${kind.id}-${mediaCount++}',
      kind: kind,
    );
    expect(media, isNotNull, reason: controller.error);
    return media!.media;
  }

  for (final kind in [
    ProjectMediaKind.image,
    ProjectMediaKind.video,
    ProjectMediaKind.audio,
  ]) {
    test(
      '${kind.id} source changes preserve orientation variants until explicitly cleared',
      () async {
        final primary = await import(kind);
        final landscape = await import(kind);
        final portrait = await import(kind);
        final clipId = controller.addMediaClip(primary)!;
        if (kind == ProjectMediaKind.audio) {
          expect(controller.patchClip(clipId, {'audioKind': 'voice'}), isTrue);
        }
        expect(controller.addMarker(), isNotNull);
        expect(await controller.save(), isTrue, reason: controller.error);
        final original = controller.active!.asset;
        final untouched = original.tracks.last;
        final before = await fixture.files.file('project.json').readAsBytes();
        expect(
          controller.patchClip(clipId, {
            'landscapeResourceId': landscape.id,
            'portraitResourceId': portrait.id,
          }),
          isTrue,
          reason: controller.error,
        );
        final withVariants = controller.active!.asset;
        controller.undo();
        expect(controller.active!.asset, original);
        controller.redo();
        expect(controller.active!.asset, withVariants);
        expect(await fixture.files.file('project.json').readAsBytes(), before);
        expect((await fixture.port.inner.load(original.id)).asset, original);
        expect(
          controller.patchClip(clipId, {'resourceId': portrait.id}),
          isTrue,
          reason: controller.error,
        );
        final switched = controller.active!.asset;
        final values = encodePresentationClip(
          switched.tracks.first.clips.single,
        );
        expect(values['resourceId'], portrait.id);
        expect(values['landscapeResourceId'], landscape.id);
        expect(values['portraitResourceId'], portrait.id);
        expect(switched.tracks.last, untouched);
        expect(await controller.save(), isTrue, reason: controller.error);
        expect((await fixture.port.inner.load(original.id)).asset, switched);
        expect(
          controller.patchClip(clipId, {'landscapeResourceId': ''}),
          isTrue,
          reason: controller.error,
        );
        final cleared = controller.active!.asset;
        final reset = encodePresentationClip(cleared.tracks.first.clips.single);
        expect(reset['resourceId'], portrait.id);
        expect(reset['landscapeResourceId'], isNull);
        expect(reset['portraitResourceId'], portrait.id);
        expect(cleared.tracks.last, untouched);
        expect(await controller.save(), isTrue, reason: controller.error);
        expect((await fixture.port.inner.load(original.id)).asset, cleared);
        expect(
          controller.patchClip(clipId, {'portraitResourceId': null}),
          isTrue,
          reason: controller.error,
        );
        final fallback = controller.active!.asset;
        final valuesAfterReset = encodePresentationClip(
          fallback.tracks.first.clips.single,
        );
        expect(valuesAfterReset['resourceId'], portrait.id);
        expect(valuesAfterReset['landscapeResourceId'], isNull);
        expect(valuesAfterReset['portraitResourceId'], isNull);
        expect(await controller.save(), isTrue, reason: controller.error);
        expect((await fixture.port.inner.load(original.id)).asset, fallback);
      },
    );
  }

  test('audio kind bus and looping persist without changing source variants or timeline', () async {
    final source = await import(ProjectMediaKind.audio);
    final variant = await import(ProjectMediaKind.audio);
    final clipId = controller.addMediaClip(source)!;
    expect(
      controller.patchClip(clipId, {
        'audioKind': 'voice',
        'landscapeResourceId': variant.id,
        'portraitResourceId': variant.id,
      }),
      isTrue,
    );
    expect(await controller.save(), isTrue, reason: controller.error);
    final before =
        controller.active!.asset.tracks.single.clips.single
            as PresentationAudioClip;
    expect(controller.patchClip(clipId, {'bus': 'effects'}), isTrue);
    final busOnly = controller.active!.asset;
    final rerouted =
        busOnly.tracks.single.clips.single as PresentationAudioClip;
    expect(rerouted.bus, PresentationAudioBus.effects);
    expect(rerouted.audioKind, before.audioKind);
    expect(rerouted.loop, before.loop);
    expect(rerouted.resourceId, before.resourceId);
    expect(rerouted.landscapeResourceId, before.landscapeResourceId);
    expect(rerouted.portraitResourceId, before.portraitResourceId);
    expect(await controller.save(), isTrue, reason: controller.error);
    expect((await fixture.port.inner.load(busOnly.id)).asset, busOnly);
    expect(controller.patchClip(clipId, {'audioKind': 'soundEffect'}), isTrue);
    final kindOnly =
        controller.active!.asset.tracks.single.clips.single
            as PresentationAudioClip;
    expect(kindOnly.bus, PresentationAudioBus.effects);
    expect(kindOnly.loop, before.loop);
    expect(controller.patchClip(clipId, {'loop': true}), isTrue);
    final updated = controller.active!.asset;
    final clip = updated.tracks.single.clips.single as PresentationAudioClip;
    expect(clip.audioKind, PresentationAudioKind.soundEffect);
    expect(clip.bus, PresentationAudioBus.effects);
    expect(clip.loop, isTrue);
    expect(clip.resourceId, before.resourceId);
    expect(clip.landscapeResourceId, before.landscapeResourceId);
    expect(clip.portraitResourceId, before.portraitResourceId);
    expect(clip.startUs, before.startUs);
    expect(clip.durationUs, before.durationUs);
    expect(await controller.save(), isTrue, reason: controller.error);
    expect((await fixture.port.inner.load(updated.id)).asset, updated);
  });

  test('caption source locale and language fallback persist independently of clip timing', () async {
    final source = await import(ProjectMediaKind.captions);
    final alternate = await import(ProjectMediaKind.captions);
    final clipId = controller.addMediaClip(source)!;
    expect(await controller.save(), isTrue, reason: controller.error);
    final original = controller.active!.asset;
    final before =
        original.tracks.single.clips.single as PresentationCaptionClip;
    expect(
      controller.patchClip(clipId, {
        'captionId': alternate.id,
        'locale': 'ja-JP',
      }),
      isTrue,
      reason: controller.error,
    );
    final updated = controller.active!.asset;
    final clip = updated.tracks.single.clips.single as PresentationCaptionClip;
    expect(clip.captionId, alternate.id);
    expect(clip.locale, 'ja-JP');
    expect(clip.fallbackToProjectDefault, before.fallbackToProjectDefault);
    expect(clip.startUs, before.startUs);
    expect(clip.durationUs, before.durationUs);
    controller.undo();
    expect(controller.active!.asset, original);
    controller.redo();
    expect(controller.active!.asset, updated);
    expect(await controller.save(), isTrue, reason: controller.error);
    expect((await fixture.port.inner.load(updated.id)).asset, updated);
    expect(
      controller.patchClip(clipId, {'fallbackToProjectDefault': false}),
      isTrue,
    );
    final withoutFallback = controller.active!.asset;
    final independent =
        withoutFallback.tracks.single.clips.single as PresentationCaptionClip;
    expect(independent.fallbackToProjectDefault, isFalse);
    expect(independent.locale, clip.locale);
    expect(independent.captionId, clip.captionId);
    expect(independent.startUs, clip.startUs);
    expect(independent.durationUs, clip.durationUs);
    expect(await controller.save(), isTrue, reason: controller.error);
    expect((await fixture.port.inner.load(updated.id)).asset, withoutFallback);
    expect(controller.patchClip(clipId, {'locale': ''}), isFalse);
    expect(controller.active!.asset, withoutFallback);
    expect(controller.active!.dirty, isFalse);
    expect((await fixture.port.inner.load(updated.id)).asset, withoutFallback);
  });

  for (final kind in [
    ProjectMediaKind.image,
    ProjectMediaKind.video,
    ProjectMediaKind.audio,
    ProjectMediaKind.captions,
  ]) {
    test(
      '${kind.id} rejects missing and incompatible media without changing draft or files',
      () async {
        final source = await import(kind);
        final incompatible = await import(
          kind == ProjectMediaKind.image
              ? ProjectMediaKind.audio
              : ProjectMediaKind.image,
        );
        final clipId = controller.addMediaClip(source)!;
        if (kind == ProjectMediaKind.audio) {
          expect(controller.patchClip(clipId, {'audioKind': 'voice'}), isTrue);
        }
        expect(await controller.save(), isTrue, reason: controller.error);
        final original = controller.active!.asset;
        final before = await fixture.files.file('project.json').readAsBytes();
        final keys = kind == ProjectMediaKind.captions
            ? ['captionId']
            : ['resourceId', 'landscapeResourceId', 'portraitResourceId'];
        for (final key in keys) {
          for (final value in ['missing', incompatible.id]) {
            expect(controller.patchClip(clipId, {key: value}), isFalse);
            expect(controller.error, isNotNull);
            expect(controller.active!.asset, original);
            expect(controller.active!.dirty, isFalse);
            expect(
              await fixture.files.file('project.json').readAsBytes(),
              before,
            );
            expect(
              (await fixture.port.inner.load(original.id)).asset,
              original,
            );
          }
        }
        expect(
          controller.patchClip(clipId, {
            'durationUs': original.tracks.single.clips.single.durationUs - 1,
          }),
          isTrue,
          reason: controller.error,
        );
        expect(controller.error, isNull);
      },
    );
  }

  test('music rejects orientation variants and voice cannot become music before variants are cleared', () async {
    final source = await import(ProjectMediaKind.audio);
    final variant = await import(ProjectMediaKind.audio);
    final clipId = controller.addMediaClip(source)!;
    expect(await controller.save(), isTrue, reason: controller.error);
    final music = controller.active!.asset;
    for (final key in ['landscapeResourceId', 'portraitResourceId']) {
      expect(controller.patchClip(clipId, {key: variant.id}), isFalse);
      expect(controller.active!.asset, music);
      expect(controller.active!.dirty, isFalse);
    }
    expect(
      controller.patchClip(clipId, {
        'audioKind': 'voice',
        'landscapeResourceId': variant.id,
        'portraitResourceId': variant.id,
      }),
      isTrue,
      reason: controller.error,
    );
    final voice = controller.active!.asset;
    expect(controller.patchClip(clipId, {'audioKind': 'music'}), isFalse);
    expect(controller.active!.asset, voice);
    expect(controller.patchClip(clipId, {'landscapeResourceId': ''}), isTrue);
    final portraitOnly = controller.active!.asset;
    expect(controller.patchClip(clipId, {'audioKind': 'music'}), isFalse);
    expect(controller.active!.asset, portraitOnly);
    expect((await fixture.port.inner.load(music.id)).asset, music);
    expect(controller.patchClip(clipId, {'portraitResourceId': ''}), isTrue);
    expect(controller.patchClip(clipId, {'audioKind': 'music'}), isTrue);
    expect(controller.active!.asset, music);
    expect(controller.active!.dirty, isFalse);
  });
}

Uint8List _videoMetadata() {
  Uint8List box(String type, List<int> payload) {
    final bytes = Uint8List(8 + payload.length)
      ..setRange(4, 8, type.codeUnits)
      ..setRange(8, 8 + payload.length, payload);
    ByteData.sublistView(bytes).setUint32(0, bytes.length);
    return bytes;
  }

  final duration = Uint8List(20);
  ByteData.sublistView(duration)
    ..setUint32(12, 1000)
    ..setUint32(16, 1000);
  final dimensions = Uint8List(84);
  ByteData.sublistView(dimensions)
    ..setUint32(76, 16 << 16)
    ..setUint32(80, 16 << 16);
  final handler = Uint8List(12)..setRange(8, 12, 'vide'.codeUnits);
  final media = box('mdia', [
    ...box('hdlr', handler),
    ...box('minf', box('stbl', box('stsd', 'avc1'.codeUnits))),
  ]);
  return Uint8List.fromList([
    ...box('ftyp', 'isom\u0000\u0000\u0000\u0000isom'.codeUnits),
    ...box('moov', [
      ...box('mvhd', duration),
      ...box('trak', [...box('tkhd', dimensions), ...media]),
    ]),
  ]);
}
