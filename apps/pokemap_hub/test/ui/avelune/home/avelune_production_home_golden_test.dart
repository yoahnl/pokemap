import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';
import 'package:pub_semver/pub_semver.dart';

/// Visual gate for the screen the production shell actually renders.
///
/// The pre-existing gate in `test/ui/avelune_mobile_home_golden_test.dart`
/// pumped `AveluneMobileHome`, which commit 2d8485837 removed from the shell.
/// Every one of its goldens stayed green while the shipped screen drifted, so
/// this gate pumps `HubShell` itself — the same composition the app builds on
/// every platform — at the two device presets the approved prototype was
/// captured on.
///
/// It also reports how far the render sits from the frozen prototype capture.
///
/// That number is reported, NOT asserted, and deliberately so. It was first
/// written as a ratchet that could only go down, and three consecutive correct
/// fixes pushed it up: restoring the header and details panel, widening the
/// hero-to-console gap for the insertion hint, and un-stretching the console to
/// its true 3.3333 aspect. A whole-frame pixel count measures raw disagreement,
/// so moving an element into its right place scores worse than leaving it in
/// the wrong one whenever the surrounding pixels shift with it.
///
/// Drift is caught precisely by the goldens above and by human review of them.
/// This figure is context for that review — useful to watch, useless as a
/// pass/fail gate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadGoldenFonts);

  const presets = <_DevicePreset>[
    _DevicePreset(
      id: 'iphone',
      size: Size(393, 852),
      insets: EdgeInsets.only(top: 47, bottom: 34),
      reference: 'home_iphone_393x852.png',
    ),
    _DevicePreset(
      id: 'pixel10',
      size: Size(427, 952),
      insets: EdgeInsets.only(top: 30, bottom: 24),
      reference: 'home_pixel10_427x952.png',
    ),
  ];

  for (final preset in presets) {
    testWidgets('production home visual gate on ${preset.id}', (tester) async {
      await _pumpProductionHome(tester, preset);

      await expectLater(
        find.byKey(_rootKey),
        matchesGoldenFile(preset.goldenFileName),
      );
    });

    testWidgets('production home reports its prototype distance on '
        '${preset.id}', (tester) async {
      // Compares the golden the test above just produced against the frozen
      // prototype capture. Reading both PNGs off disk avoids capturing the
      // render tree through `toImage()`, which does not resolve under the test
      // binding.
      final ratio = await _differenceFromReference(tester, preset);

      // ignore: avoid_print
      print(
        'AVELUNE prototype distance [${preset.id}]: '
        '${(ratio * 100).toStringAsFixed(2)}% of pixels differ from '
        '${preset.reference}',
      );

      expect(
        ratio,
        inInclusiveRange(0, 1),
        reason: 'A measurement, not a gate — see the note at the top of this '
            'file for why no ceiling is asserted.',
      );
    });
  }
}

const ValueKey<String> _rootKey = ValueKey<String>('avelune-production-root');

@immutable
final class _DevicePreset {
  const _DevicePreset({
    required this.id,
    required this.size,
    required this.insets,
    required this.reference,
  });

  final String id;
  final Size size;
  final EdgeInsets insets;
  final String reference;

  String get referencePath =>
      '../../documentation/avelune/reference/console_v1/screenshots/$reference';

  String get _goldenBaseName =>
      'production_home_${id}_'
      '${size.width.toInt()}x${size.height.toInt()}.png';

  /// Relative to the test file, the form `matchesGoldenFile` expects.
  String get goldenFileName => '../../goldens/avelune/$_goldenBaseName';

  /// Relative to the package root, the form `File` expects.
  String get goldenPath => 'test/ui/goldens/avelune/$_goldenBaseName';
}

Future<void> _pumpProductionHome(
  WidgetTester tester,
  _DevicePreset preset,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  tester.view.physicalSize = preset.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final games = _games();
  final snapshot = _snapshot(games);
  // Real callbacks: AveluneHomeController derives launchability from these, so
  // an empty HubUiActions would freeze every cartridge into the disabled state
  // and the gate would capture a degraded home instead of the resting one.
  final actions = HubUiActions(
    onImportRequested: () {},
    onContinue: (_) {},
    onNewGame: (_) {},
  );
  await tester.runAsync(() => _primeCoverImages(snapshot));

  final theme = applyAveluneTheme(PokeMapPlayerTheme.dark(reducedMotion: true));

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
        primaryTextTheme: theme.primaryTextTheme.apply(
          fontFamily: 'AveluneGoldenSans',
        ),
      ),
      home: RepaintBoundary(
        key: _rootKey,
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: preset.insets,
              viewPadding: preset.insets,
              disableAnimations: true,
            ),
            child: HubShell(
              productName: 'Avelune',
              // Pinned so the relative wording never drifts with the calendar.
              referenceTime: DateTime.utc(2026, 8, 4, 12),
              snapshot: snapshot,
              actions: actions,
              homeController: AveluneHomeController(
                snapshot: snapshot,
                actions: actions,
              ),
              onSectionSelected: (_) {},
            ),
          ),
        ),
      ),
    ),
  );

  final context = tester.element(find.byType(AveluneRoomScene));
  await tester.runAsync(
    () => Future.wait<void>(<Future<void>>[
      for (final asset in AveluneMaterialCatalog.cartridgeLayers)
        precacheImage(AssetImage(asset.path), context),
      for (final asset in AveluneMaterialCatalog.consoleLayers)
        precacheImage(AssetImage(asset.path), context),
      precacheImage(const AssetImage(kAveluneFallbackArtworkAssetPath), context),
      precacheImage(
        AssetImage(
          AveluneAppearanceCatalog.background(
            AveluneAppearanceCatalog.defaultBackgroundId,
          ).assetPath!,
        ),
        context,
      ),
      precacheImage(
        AssetImage(
          AveluneAppearanceCatalog.furnitureFinish(
            AveluneAppearanceCatalog.defaultFurnitureId,
          ).assetPath!,
        ),
        context,
      ),
    ]),
  );
  // Bounded pumps rather than pumpAndSettle: the shell keeps indeterminate
  // progress indicators alive in some states, which never settle.
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 100));
  _markSubtreeNeedsPaint(tester.renderObject(find.byKey(_rootKey)));
  await tester.pump();
}

/// Fraction of pixels whose colour differs from the frozen prototype capture by
/// more than [_channelTolerance] on any channel.
Future<double> _differenceFromReference(
  WidgetTester tester,
  _DevicePreset preset,
) async {
  final goldenFile = File(preset.goldenPath);
  expect(
    goldenFile.existsSync(),
    isTrue,
    reason: 'Run this suite with --update-goldens first so the production '
        'render exists on disk.',
  );

  late double ratio;
  await tester.runAsync(() async {
    final rendered = await _decode(goldenFile.readAsBytesSync());
    final reference = await _decode(
      File(preset.referencePath).readAsBytesSync(),
    );
    try {
      expect(
        <int>[rendered.width, rendered.height],
        <int>[reference.width, reference.height],
        reason: 'The preset must match the frozen capture resolution exactly.',
      );
      final renderedPixels = await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final referencePixels = await reference.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      ratio = _differenceRatio(
        renderedPixels!.buffer.asUint8List(),
        referencePixels!.buffer.asUint8List(),
      );
    } finally {
      rendered.dispose();
      reference.dispose();
    }
  });
  return ratio;
}

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}

const int _channelTolerance = 24;

double _differenceRatio(Uint8List actual, Uint8List expected) {
  var differing = 0;
  final pixels = actual.length ~/ 4;
  for (var i = 0; i < actual.length; i += 4) {
    final dr = (actual[i] - expected[i]).abs();
    final dg = (actual[i + 1] - expected[i + 1]).abs();
    final db = (actual[i + 2] - expected[i + 2]).abs();
    if (dr > _channelTolerance ||
        dg > _channelTolerance ||
        db > _channelTolerance) {
      differing++;
    }
  }
  return pixels == 0 ? 0 : differing / pixels;
}

void _markSubtreeNeedsPaint(RenderObject object) {
  object.markNeedsPaint();
  object.visitChildren(_markSubtreeNeedsPaint);
}

Future<void> _primeCoverImages(HubDashboardSnapshot snapshot) async {
  for (final coverPath in snapshot.games
      .map((game) => game.activity.coverPath)
      .whereType<String>()) {
    final bytes = await File(coverPath).readAsBytes();
    final fileProvider = FileImage(File(coverPath));
    final variants = <(ImageProvider<Object>, int?, int?)>[
      (fileProvider, null, null),
      (
        ResizeImage.resizeIfNeeded(
          kAveluneCartridgeHeroArtworkCacheWidth,
          kAveluneCartridgeHeroArtworkCacheHeight,
          fileProvider,
        ),
        kAveluneCartridgeHeroArtworkCacheWidth,
        kAveluneCartridgeHeroArtworkCacheHeight,
      ),
      (
        ResizeImage.resizeIfNeeded(
          kAveluneCartridgeShelfArtworkCacheWidth,
          kAveluneCartridgeShelfArtworkCacheHeight,
          fileProvider,
        ),
        kAveluneCartridgeShelfArtworkCacheWidth,
        kAveluneCartridgeShelfArtworkCacheHeight,
      ),
    ];
    for (final (provider, width, height) in variants) {
      final cache = PaintingBinding.instance.imageCache;
      final key = await provider.obtainKey(ImageConfiguration.empty);
      if (cache.containsKey(key)) continue;
      final codec = await ui.instantiateImageCodec(
        bytes,
        targetWidth: width,
        targetHeight: height,
      );
      final frame = await codec.getNextFrame();
      final cached = frame.image.clone();
      frame.image.dispose();
      codec.dispose();
      cache.putIfAbsent(
        key,
        () => OneFrameImageStreamCompleter(
          Future<ImageInfo>.value(ImageInfo(image: cached)),
        ),
      );
    }
  }
}

Future<void> _loadGoldenFonts() async {
  final bytes = await File(
    '../../packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf',
  ).readAsBytes();
  final textLoader = FontLoader('AveluneGoldenSans')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(bytes))),
    );
  final materialLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await Future.wait(<Future<void>>[textLoader.load(), materialLoader.load()]);
}

List<HubGameView> _games() => <HubGameView>[
      _view(
        id: 'selbrume',
        title: 'Selbrume',
        accentColor: '#64358A',
        installedAt: DateTime.utc(2026, 8, 3),
        lastSaveAt: DateTime.utc(2026, 8, 4, 10),
      ),
      _view(
        id: 'train',
        title: 'Le Train de 17h42',
        accentColor: '#126E78',
        installedAt: DateTime.utc(2026, 8, 2),
        lastSaveAt: DateTime.utc(2026, 8, 3, 12),
      ),
      _view(
        id: 'demo',
        title: 'Démo technique',
        accentColor: '#33343B',
        installedAt: DateTime.utc(2026, 8),
        lastSaveAt: DateTime.utc(2026, 8),
      ),
    ];

HubDashboardSnapshot _snapshot(List<HubGameView> games) =>
    HubDashboardSnapshot.ready(
      library: GameLibrary(
        revision: 1,
        updatedAt: DateTime.utc(2026, 8, 4),
        games: games.map((view) => view.game).toList(growable: false),
      ),
      games: games,
    );

HubGameView _view({
  required String id,
  required String title,
  required String accentColor,
  required DateTime installedAt,
  required DateTime? lastSaveAt,
}) {
  final version = InstalledGameVersion(
    gameVersion: Version.parse('1.0.0'),
    treeSha256: id.padRight(64, '0').substring(0, 64),
    installedAt: installedAt,
    receiptFileName: '$id.json',
    source: GamePackageInstallSource.localFile,
    signatureStatus: PackageSignatureStatus.notPresent,
  );
  return HubGameView(
    game: InstalledGame(
      gameId: 'games.visual.$id',
      title: title,
      authorName: 'Studio Avelune',
      defaultLocale: 'fr',
      supportedLocales: const <String>['fr'],
      branding: InstalledGameBranding(accentColor: accentColor),
      description: 'Une aventure façonnée pour la console Avelune.',
      current: version.pointer,
      versions: <InstalledGameVersion>[version],
    ),
    activity: HubGameActivity(
      canContinue: lastSaveAt != null,
      coverPath: File('test/fixtures/avelune/covers/$id.webp').absolute.path,
      lastSaveAt: lastSaveAt,
      playTimeSeconds: lastSaveAt == null ? 0 : 3720,
    ),
  );
}
