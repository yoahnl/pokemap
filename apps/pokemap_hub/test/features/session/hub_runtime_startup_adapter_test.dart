import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:pokemap_hub/features/session/application/services/hub_runtime_startup_adapter.dart';
import 'package:pokemap_hub/features/session/domain/repositories/package_asset_port.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  test('projects verified package presentation into runtime startup data',
      () async {
    final root = await Directory.systemTemp.createTemp('hub-startup-adapter-');
    addTearDown(() => root.delete(recursive: true));
    final video = await File('${root.path}/intro.mp4').writeAsBytes(<int>[1]);
    final poster = await File('${root.path}/poster.png').writeAsBytes(<int>[2]);
    final assets = _MemoryPackageAssets(<String, File>{
      'presentation/intro/video.mp4': video,
      'presentation/intro/poster.png': poster,
    });
    final adapter = HubRuntimeStartupAdapter(
      manifest: _manifest,
      assets: assets,
    );

    final profile = await adapter.loadPresentationProfile();
    final resolvedVideo =
        await adapter.resolveMedia('presentation/intro/video.mp4');
    final resolvedPoster =
        await adapter.resolveImage('presentation/intro/poster.png');

    expect(profile?.branding.heroPath, 'presentation/hero.png');
    expect(profile?.branding.titleMusicPath, 'presentation/title.ogg');
    expect(profile?.intro?.videoPath, 'presentation/intro/video.mp4');
    expect(profile?.intro?.allowReplay, isTrue);
    expect(profile?.typography?.display.fontPath, 'presentation/display.ttf');
    expect(profile?.typography?.display.family, 'Train Display');
    expect(profile?.theme?.titleSurface, '#D9F4F6');
    expect(profile?.menuLabels?.pauseTitle, 'Interlude');
    expect(profile?.menuLabels?.pokedex, 'Carnet');
    expect(resolvedVideo?.resolvedUri, video.uri);
    expect(resolvedVideo?.mediaType, 'video/mp4');
    expect(resolvedPoster?.resolvedUri, poster.uri);
    expect(resolvedPoster?.mediaType, 'image/png');
    expect(
      adapter.resolvedAsset('presentation/intro/video.mp4'),
      same(resolvedVideo),
    );
  });

  test('missing optional installed media stays non-blocking and uncached',
      () async {
    final adapter = HubRuntimeStartupAdapter(
      manifest: _manifest,
      assets: _MemoryPackageAssets(const <String, File>{}),
    );

    expect(await adapter.resolveImage('presentation/hero.png'), isNull);
    expect(await adapter.exists('presentation/hero.png'), isFalse);
    expect(adapter.resolvedAsset('presentation/hero.png'), isNull);
  });
}

final class _MemoryPackageAssets implements PackageAssetPort {
  const _MemoryPackageAssets(this.files);

  final Map<String, File> files;

  @override
  PackageAssetReferencePort reference(String packagePath) =>
      _PackageReference(packagePath);

  @override
  Future<File> resolveFile(String packagePath) async =>
      files[packagePath] ??
      (throw const FileSystemException('missing installed asset'));

  @override
  Future<File> resolveReference(PackageAssetReferencePort reference) =>
      resolveFile(reference.packagePath);
}

final class _PackageReference implements PackageAssetReferencePort {
  const _PackageReference(this.packagePath);

  @override
  final String packagePath;
}

final _manifest = GamePackageManifest(
  packageFormat: 1,
  gameId: 'games.example.train',
  gameVersion: Version(1, 0, 0),
  title: 'Le Train de 17h42',
  description: 'Une aventure ferroviaire.',
  author: const GamePackageParty(name: 'PokeMap'),
  compatibility: GamePackageCompatibility(
    minHubVersion: Version(1, 0, 0),
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
  presentation: const GamePackagePresentation(
    branding: GamePackageBranding(
      icon: 'presentation/icon.png',
      hero: 'presentation/hero.png',
      titleMusic: 'presentation/title.ogg',
      layoutVariant: 'cinematic',
    ),
    intro: GamePackageIntroVideo(
      video: 'presentation/intro/video.mp4',
      poster: 'presentation/intro/poster.png',
      durationMilliseconds: 1200,
      width: 1280,
      height: 720,
      bitrateKbps: 2400,
      sizeBytes: 1000,
      videoCodec: 'h264',
      audioCodec: 'aac',
      reducedMotionBehavior: 'poster',
      allowReplay: true,
    ),
    typography: GamePackageTypography(
      display: GamePackageFontRole(
        font: 'presentation/display.ttf',
        family: 'Train Display',
        fallbackFamilies: <String>['serif'],
      ),
    ),
    theme: GamePackageSemanticTheme(
      primary: '#003A44',
      onPrimary: '#FFFFFF',
      background: '#F4F7FB',
      surface: '#FFFFFF',
      surfaceElevated: '#EAF0F8',
      textPrimary: '#101827',
      textSecondary: '#526176',
      outline: '#65758B',
      success: '#16794B',
      warning: '#8A5100',
      danger: '#B4233C',
      titleSurface: '#D9F4F6',
      dialogueSurface: '#FFFFFF',
      menuSurface: '#EAF0F8',
      overworldHudSurface: '#FFFFFF',
      battleHudSurface: '#FFFFFF',
    ),
    menuLabels: GamePackageMenuLabels(
      pauseTitle: 'Interlude',
      pokedex: 'Carnet',
    ),
  ),
  content: GamePackageContent(
    fileCount: 2,
    totalBytes: 2,
    treeSha256: '0' * 64,
    files: const <GamePackageFileEntry>[
      GamePackageFileEntry(
        path: 'presentation/intro/video.mp4',
        size: 1,
        sha256: '1',
        mediaType: 'video/mp4',
      ),
      GamePackageFileEntry(
        path: 'presentation/intro/poster.png',
        size: 1,
        sha256: '2',
        mediaType: 'image/png',
      ),
    ],
  ),
);
