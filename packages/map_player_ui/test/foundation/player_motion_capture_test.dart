import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;

const _captureRoot = String.fromEnvironment('LIGUE_MOTION_CAPTURE_ROOT');
const _frameStep = Duration(microseconds: 33333);
const _boundaryKey = ValueKey('native-primitives-motion-boundary');

Future<void> _loadFonts() async {
  final configuration = File('.dart_tool/package_config.json');
  final packages =
      (jsonDecode(await configuration.readAsString()) as Map)['packages']
          as List;
  final flutter = packages.cast<Map>().firstWhere(
    (entry) => entry['name'] == 'flutter',
  );
  final flutterPackage = Directory.fromUri(
    configuration.absolute.uri.resolve(flutter['rootUri'] as String),
  );
  final sdk = flutterPackage.parent.parent;
  final fonts = {
    'packages/map_player_ui/PokeMapSplashDMSans': File(
      'assets/fonts/DMSans-Variable.ttf',
    ),
    'MaterialIcons': File(
      p.join(
        sdk.path,
        'bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ),
  };
  for (final entry in fonts.entries) {
    final bytes = ByteData.sublistView(await entry.value.readAsBytes());
    await (FontLoader(entry.key)..addFont(Future.value(bytes))).load();
  }
}

class _MotionRecorder {
  _MotionRecorder(this.tester, this.directory)
    : startedAt = tester.binding.clock.now();

  final WidgetTester tester;
  final String directory;
  final DateTime startedAt;
  final frames = <Map<String, Object?>>[];
  var elapsed = Duration.zero;

  Future<void> frame(String phase, {Duration step = _frameStep}) async {
    await tester.pump(step);
    final previousTimestamp = elapsed;
    elapsed = tester.binding.clock.now().difference(startedAt);
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_boundaryKey),
    );
    final image = (await tester.runAsync(
      () => boundary.toImage(pixelRatio: 1),
    ))!;
    try {
      final data = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      ))!;
      final name = 'frame-${frames.length.toString().padLeft(4, '0')}.png';
      await tester.runAsync(
        () =>
            File(p.join(directory, name))
                .writeAsBytes(data.buffer.asUint8List()),
      );
      frames.add({
        'file': name,
        'timestampMicros': elapsed.inMicroseconds,
        'durationMicros': (elapsed - previousTimestamp).inMicroseconds,
        'phase': phase,
        'width': image.width,
        'height': image.height,
      });
    } finally {
      image.dispose();
    }
    expect(tester.takeException(), isNull, reason: phase);
  }

  Future<void> hold(String phase, int count) async {
    for (var index = 0; index < count; index++) {
      await frame(phase);
    }
  }
}

void main() {
  testWidgets('exports native primitive motion at thirty frames per second', (
    tester,
  ) async {
    if (!p.isAbsolute(_captureRoot)) {
      throw ArgumentError(
        'LIGUE_MOTION_CAPTURE_ROOT must be an absolute path.',
      );
    }
    await tester.runAsync(() async {
      await Directory(_captureRoot).create(recursive: true);
      await _loadFonts();
    });
    addTearDown(tester.view.reset);
    final clips = <Map<String, Object?>>[];
    for (final (name, size) in [
      ('portrait', const Size(390, 844)),
      ('landscape', const Size(844, 390)),
    ]) {
      final directory = p.join(_captureRoot, name);
      await tester.runAsync(() => Directory(directory).create(recursive: true));
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      final fixtureKey = GlobalKey<_MotionFixtureState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapPlayerTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: false),
            child: child!,
          ),
          home: RepaintBoundary(
            key: _boundaryKey,
            child: PlayerMenuThemeScope(child: _MotionFixture(key: fixtureKey)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final recorder = _MotionRecorder(tester, directory);
      await recorder.frame('closed');
      await tester.tap(find.byKey(const ValueKey('motion-open')));
      await recorder.hold('panel-open-220ms', 7);
      await recorder.hold('panel-readable', 30);
      final body = find.byKey(const ValueKey('player-paged-body'));
      final gesture = await tester.startGesture(tester.getRect(body).center);
      for (var step = 0; step < 4; step++) {
        await gesture.moveBy(const Offset(-35, 0));
        await recorder.frame('swipe-under-finger');
      }
      await gesture.up();
      await recorder.hold('page-commit-180ms', 6);
      expect(fixtureKey.currentState!.page, 1);
      await recorder.hold('page-readable', 24);
      await tester.tap(find.byKey(const ValueKey('motion-tab-1')));
      await recorder.hold('tab-forward-180ms', 6);
      await recorder.hold('tab-readable', 15);
      await tester.tap(find.byKey(const ValueKey('motion-tab-0')));
      await recorder.hold('tab-back-180ms', 6);
      await recorder.hold('returned-tab-readable', 15);
      await tester.tap(find.byKey(const ValueKey('motion-return')));
      await recorder.hold('panel-close-160ms', 5);
      await recorder.hold('closed-readable', 9);
      expect(fixtureKey.currentState!.visible, isFalse);
      final clip = <String, Object?>{
        'name': name,
        'viewport': {
          'width': size.width,
          'height': size.height,
          'devicePixelRatio': 1,
        },
        'fpsNumerator': 1000000,
        'fpsDenominator': _frameStep.inMicroseconds,
        'frameCount': recorder.frames.length,
        'durationMicros': recorder.elapsed.inMicroseconds,
        'frames': recorder.frames,
      };
      clips.add(clip);
      await tester.runAsync(
        () => File(p.join(directory, 'timestamps.json'))
            .writeAsString(const JsonEncoder.withIndent('  ').convert(clip)),
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
    final manifest = {
      'title': 'Preuve des primitives Flutter natives — mouvement',
      'source': 'Flutter WidgetTester / RenderRepaintBoundary.toImage',
      'sourceFile': 'packages/map_player_ui/test/foundation/player_motion_capture_test.dart',
      'primitives': [
        'PlayerMenuFrame',
        'PlayerMenuTransition',
        'PlayerPagedList',
        'PlayerMenuDetailTransition',
        'PlayerMenuSelectableRow',
      ],
      'fonts': ['DMSans-Variable.ttf', 'MaterialIcons-Regular.otf'],
      'limits': [
        'Démonstration de composants avec données de fixture.',
        'Aucune session de jeu ni matériel Thor.',
        'Thème clair, texte normal, deux viewports sans safeInsets.',
        'Temps simulé WidgetTester ; aucune mesure de performance réelle.',
      ],
      'clips': clips,
    };
    await tester.runAsync(
      () => File(p.join(_captureRoot, 'manifest.json'))
          .writeAsString(const JsonEncoder.withIndent('  ').convert(manifest)),
    );
  }, skip: _captureRoot.isEmpty);
}

class _MotionFixture extends StatefulWidget {
  const _MotionFixture({super.key});

  @override
  State<_MotionFixture> createState() => _MotionFixtureState();
}

class _MotionFixtureState extends State<_MotionFixture> {
  var visible = false;
  var page = 0;
  var tab = 0;
  var direction = 1;

  void _selectTab(int next) => setState(() {
    direction = next > tab ? 1 : -1;
    tab = next;
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.playerMenuTheme;
    final viewport = MediaQuery.sizeOf(context);
    final rowHeight = viewport.width > viewport.height ? 72.0 : 96.0;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: theme.base),
          Center(
            child: SizedBox(
              width: 220,
              child: PlayerMenuSelectableRow(
                key: const ValueKey('motion-open'),
                id: 'motion-open',
                label: 'Ouvrir le menu',
                leading: const Icon(Icons.menu),
                button: true,
                onPressed: () => setState(() => visible = true),
              ),
            ),
          ),
          PlayerMenuFrame(
            visible: visible,
            scrollable: false,
            header: PlayerMenuHeader(
              title: 'Primitives natives',
              icon: Icons.layers_outlined,
              onBack: () => setState(() => visible = false),
            ),
            footer: PlayerMenuFooter(
              hints: const [Text('Démo native')],
              returnAction: PlayerMenuSelectableRow(
                key: const ValueKey('motion-return'),
                id: 'motion-return',
                label: 'Retour',
                leading: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => visible = false),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    for (final (index, label) in [
                      (0, 'Inventaire'),
                      (1, 'Carnet'),
                    ])
                      Expanded(
                        child: PlayerMenuSelectableRow(
                          key: ValueKey('motion-tab-$index'),
                          id: 'motion-tab-$index',
                          label: label,
                          tab: true,
                          selected: tab == index,
                          onPressed: () => _selectTab(index),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: PlayerMenuDetailTransition(
                    contentKey: ValueKey(tab),
                    direction: direction,
                    child: PlayerPagedList(
                      initialPage: tab == 0 ? page : 0,
                      onPageChanged: (value) => page = value,
                      children: [
                        for (var index = 0; index < 8; index++)
                          SizedBox(
                            key: ValueKey('motion-$tab-card-$index'),
                            height: rowHeight,
                            child: PlayerMenuSelectableRow(
                              id: 'motion-$tab-card-$index',
                              label: tab == 0
                                  ? 'Objet ${index + 1}'
                                  : 'Note ${index + 1}',
                              subtitle: tab == 0
                                  ? 'Page par page.'
                                  : 'Retour d’onglet animé.',
                              leading: Icon(
                                tab == 0
                                    ? Icons.inventory_2_outlined
                                    : Icons.book_outlined,
                              ),
                              selected: index == 0,
                              onPressed: () {},
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
