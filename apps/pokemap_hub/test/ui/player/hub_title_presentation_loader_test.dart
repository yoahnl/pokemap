import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/src/ui/player/hub_title_presentation_loader.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('loads installed branding into the canonical player presentation',
      () async {
    final root = await Directory.systemTemp.createTemp('hub-branding-');
    addTearDown(() => root.delete(recursive: true));
    final logo = await File('${root.path}/icon.png').writeAsBytes(<int>[1]);
    final hero = await File('${root.path}/hero.png').writeAsBytes(<int>[2]);
    final music = await File('${root.path}/title.ogg').writeAsBytes(<int>[3]);
    final files = <String, File>{
      'presentation/icon.png': logo,
      'presentation/hero.png': hero,
      'project/assets/title.ogg': music,
    };

    final loaded = await HubTitlePresentationLoader(
      manifest: _manifest(
        const GamePackageBranding(
          icon: 'presentation/icon.png',
          hero: 'presentation/hero.png',
          accentColor: '#123456',
          titleMusic: 'project/assets/title.ogg',
          layoutVariant: 'cinematic',
        ),
      ),
      resolveFile: (path) async => files[path]!,
    ).load();

    expect((loaded.title.logo! as FileImage).file.path, logo.path);
    expect((loaded.title.background! as FileImage).file.path, hero.path);
    expect(loaded.title.accentColor, const Color(0xFF123456));
    expect(
      loaded.title.layoutVariant,
      PlayerTitleLayoutVariant.cinematic,
    );
    expect(loaded.titleMusicPath, music.path);
    expect(loaded.intro, isNull);
    expect(loaded.unavailableAssets, isEmpty);
  });

  test('broken optional branding falls back without blocking the title',
      () async {
    final loaded = await HubTitlePresentationLoader(
      manifest: _manifest(
        const GamePackageBranding(
          icon: 'presentation/icon.png',
          cover: 'presentation/cover.png',
          titleMusic: 'project/assets/title.ogg',
        ),
      ),
      resolveFile: (_) async => throw const FileSystemException('missing'),
    ).load();

    expect(loaded.title.logo, isNull);
    expect(loaded.title.background, isNull);
    expect(loaded.title.layoutVariant, PlayerTitleLayoutVariant.standard);
    expect(loaded.titleMusicPath, isNull);
    expect(loaded.intro, isNull);
    expect(loaded.unavailableAssets, hasLength(3));
  });

  test('loads installed intro assets independently from title branding',
      () async {
    final root = await Directory.systemTemp.createTemp('hub-intro-');
    addTearDown(() => root.delete(recursive: true));
    final video = await File('${root.path}/video.mp4').writeAsBytes(<int>[1]);
    final poster = await File('${root.path}/poster.png').writeAsBytes(<int>[2]);
    final captions = await File('${root.path}/captions.vtt')
        .writeAsString('WEBVTT\n\n00:00.000 --> 00:01.000\nAube');
    final files = <String, File>{
      'presentation/intro/video.mp4': video,
      'presentation/intro/poster.png': poster,
      'presentation/intro/captions.vtt': captions,
    };

    final loaded = await HubTitlePresentationLoader(
      manifest: _manifest(
        const GamePackageBranding(),
        intro: _intro,
      ),
      resolveFile: (path) async => files[path]!,
    ).load();

    expect(loaded.intro?.videoPath, video.path);
    expect((loaded.intro?.poster! as FileImage).file.path, poster.path);
    expect(loaded.intro?.captionsPath, captions.path);
    expect(loaded.intro?.reducedMotionBehavior, 'poster');
    expect(loaded.intro?.allowReplay, isTrue);
    expect(loaded.unavailableAssets, isEmpty);
  });

  test('missing intro video falls through to title without blocking it',
      () async {
    final loaded = await HubTitlePresentationLoader(
      manifest: _manifest(
        const GamePackageBranding(),
        intro: _intro,
      ),
      resolveFile: (_) async => throw const FileSystemException('missing'),
    ).load();

    expect(loaded.intro, isNull);
    expect(loaded.title.logo, isNull);
    expect(loaded.unavailableAssets, contains('presentation/intro/video.mp4'));
  });
}

const _intro = GamePackageIntroVideo(
  video: 'presentation/intro/video.mp4',
  poster: 'presentation/intro/poster.png',
  captions: 'presentation/intro/captions.vtt',
  durationMilliseconds: 1000,
  width: 1280,
  height: 720,
  bitrateKbps: 1200,
  sizeBytes: 150000,
  videoCodec: 'h264',
  audioCodec: 'aac',
  reducedMotionBehavior: 'poster',
  allowReplay: true,
);

GamePackageManifest _manifest(
  GamePackageBranding branding, {
  GamePackageIntroVideo? intro,
}) =>
    GamePackageManifest(
      packageFormat: 1,
      gameId: 'games.example.branding',
      gameVersion: Version(1, 0, 0),
      title: 'Aube',
      description: 'Une aventure personnalisée.',
      author: const GamePackageParty(name: 'Studio Brume'),
      compatibility: GamePackageCompatibility(
        minHubVersion: Version(0, 1, 0),
        runtimeApiExpression: '>=1.0.0 <2.0.0',
        projectFormat: 'v2',
        saveFormat: 1,
        compatibilityId: 'main',
        requiredCapabilities: const <String>[],
      ),
      locales: GamePackageLocales(
        defaultLocale: 'fr',
        supported: const <String>['fr'],
      ),
      branding: intro == null ? branding : null,
      presentation: intro == null
          ? null
          : GamePackagePresentation(
              branding: branding,
              intro: intro,
            ),
      content: GamePackageContent(
        fileCount: 0,
        totalBytes: 0,
        treeSha256: '0' * 64,
        files: const <GamePackageFileEntry>[],
      ),
    );
