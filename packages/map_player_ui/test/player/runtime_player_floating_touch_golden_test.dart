import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader('packages/map_player_ui/PokeMapSplashDMSans')
          ..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf')))
        .load();
    var cache = File(Platform.resolvedExecutable).parent;
    while (!cache.path.endsWith('${Platform.pathSeparator}cache')) {
      if (cache.parent.path == cache.path) {
        throw StateError('Flutter cache absent');
      }
      cache = cache.parent;
    }
    final icons = await File(
            '${cache.path}/artifacts/material_fonts/MaterialIcons-Regular.otf')
        .readAsBytes();
    await (FontLoader('MaterialIcons')
          ..addFont(Future.value(ByteData.sublistView(icons))))
        .load();
  });

  for (final (name, size, mirrored, running) in [
    ('floating_landscape', const Size(844, 390), false, false),
    ('floating_portrait_right', const Size(390, 844), true, false),
    ('floating_running_accepted', const Size(844, 390), false, true),
  ]) {
    testWidgets('recognized pointer renders $name and disappears on release',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final theme = PokeMapPlayerTheme.dark();
      var sprintAccepted = false;
      await tester.pumpWidget(MaterialApp(
        theme: theme.copyWith(
            textTheme: theme.textTheme.apply(
                fontFamily: 'packages/map_player_ui/PokeMapSplashDMSans')),
        home: RepaintBoundary(
          key: const ValueKey('floating-capture'),
          child: Builder(
              builder: (context) => Material(
                    color: context.playerColors.background,
                    child: MediaQuery(
                      data: MediaQueryData(
                          size: size,
                          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24)),
                      child: StatefulBuilder(
                          builder: (context, setState) =>
                              RuntimePlayerTouchControls(
                                leftHanded: mirrored,
                                sprintAllowed: running,
                                sprintAccepted: sprintAccepted,
                                readGameplayViewport: () => Offset.zero & size,
                                dispatch: (event) {
                                  if (event.control ==
                                      RuntimeInputControl.sprint) {
                                    setState(
                                        () => sprintAccepted = event.isPress);
                                  }
                                },
                              )),
                    ),
                  )),
        ),
      ));
      expect(find.byType(PlayerOverworldJoystickVisual), findsNothing);
      final gesture = await tester.startGesture(
        Offset(mirrored ? size.width - 90 : 90, size.height * .55),
        kind: ui.PointerDeviceKind.touch,
      );
      await gesture.moveBy(Offset(running ? 48 : 32, -8));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(PlayerOverworldJoystickVisual), findsOneWidget);
      expect(
          tester
              .widget<PlayerOverworldJoystickVisual>(
                  find.byType(PlayerOverworldJoystickVisual))
              .running,
          running);
      expect(tester.takeException(), isNull);
      await expectLater(find.byKey(const ValueKey('floating-capture')),
          matchesGoldenFile('goldens/overworld_primitives/$name.png'));
      await gesture.up();
      await tester.pump();
      expect(find.byType(PlayerOverworldJoystickVisual), findsNothing);
    });
  }
}
