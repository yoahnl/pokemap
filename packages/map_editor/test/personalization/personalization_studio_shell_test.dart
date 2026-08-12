import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/personalization/application/personalization_inspector_target.dart';
import 'package:map_editor/src/features/personalization/application/personalization_preview_surface_descriptor.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_studio_shell.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  test('legacy personalization shells are absent', () {
    expect(
      File(
        'lib/src/features/personalization/presentation/personalization_hub_shell.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'lib/src/features/personalization/presentation/personalization_studio_shell_v2.dart',
      ).existsSync(),
      isFalse,
    );
  });

  testWidgets('uses 260 and 360 pixel panes at 1600 pixels', (tester) async {
    await _pumpShell(tester, const Size(1600, 900));

    expect(find.text('Personalization Studio'), findsNothing);
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('personalization-studio-navigation-pane'),
            ),
          )
          .width,
      260,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('personalization-studio-inspector-pane'),
            ),
          )
          .width,
      360,
    );
    expect(find.byKey(const ValueKey<String>('test-preview')), findsOneWidget);
  });

  testWidgets('uses 220 and 320 pixel panes at 1200 pixels', (tester) async {
    await _pumpShell(tester, const Size(1200, 800));

    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('personalization-studio-navigation-pane'),
            ),
          )
          .width,
      220,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey<String>('personalization-studio-inspector-pane'),
            ),
          )
          .width,
      320,
    );
  });

  testWidgets('uses a compact rail and opens the inspector at 900 pixels', (
    tester,
  ) async {
    await _pumpShell(tester, const Size(900, 800));

    expect(
      find.byKey(
        const ValueKey<String>('personalization-studio-navigation-rail'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('personalization-studio-inspector-pane'),
      ),
      findsNothing,
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-studio-open-inspector'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('test-inspector')),
      findsOneWidget,
    );
  });

  testWidgets('stays usable at 720 pixels with 200 percent text', (
    tester,
  ) async {
    await _pumpShell(tester, const Size(720, 900), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(
        const ValueKey<String>('personalization-studio-navigation-horizontal'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey<String>('test-preview')), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey<String>('personalization-studio-open-inspector'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('test-inspector')),
      findsOneWidget,
    );
  });

  for (final size in <Size>[
    const Size(720, 900),
    const Size(1024, 768),
    const Size(1440, 900),
    const Size(1600, 1000),
  ]) {
    for (final textScale in <double>[1, 1.5, 2]) {
      testWidgets('keeps navigation preview and inspector reachable at '
          '${size.width.toInt()}x${size.height.toInt()} and ${textScale}x', (
        tester,
      ) async {
        await _pumpShell(tester, size, textScale: textScale);

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey<String>('test-preview')),
          findsOneWidget,
        );
        final inspector = find.byKey(
          const ValueKey<String>('personalization-studio-inspector-pane'),
        );
        if (inspector.evaluate().isEmpty) {
          await tester.tap(
            find.byKey(
              const ValueKey<String>('personalization-studio-open-inspector'),
            ),
          );
          await tester.pumpAndSettle();
        }
        expect(
          find.byKey(const ValueKey<String>('test-inspector')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}

Future<void> _pumpShell(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: PersonalizationStudioShell(
            selectedScene: PersonalizationStudioScene.globalStyle,
            onSceneSelected: (_) {},
            preview: const ColoredBox(
              key: ValueKey<String>('test-preview'),
              color: Colors.transparent,
            ),
            inspectorTitle: 'Style global',
            inspectorDescription: 'Réglages communs à toutes les scènes.',
            selectedTarget: const GlobalColorsTarget(),
            onTargetSelected: (_) {},
            inspector: const Text(
              'Inspecteur',
              key: ValueKey<String>('test-inspector'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
