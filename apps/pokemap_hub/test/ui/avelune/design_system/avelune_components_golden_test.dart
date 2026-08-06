import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/src/ui/avelune/design_system/avelune_design_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadGoldenFont);

  testWidgets('Avelune component gallery standard visual gate', (tester) async {
    await _pumpGallery(tester, highContrast: false);
    await expectLater(
      find.byKey(const ValueKey<String>('avelune-component-gallery')),
      matchesGoldenFile(
          '../../goldens/avelune/components_standard_800x900.png'),
    );
  });

  testWidgets('Avelune component gallery high contrast visual gate',
      (tester) async {
    await _pumpGallery(tester, highContrast: true);
    await expectLater(
      find.byKey(const ValueKey<String>('avelune-component-gallery')),
      matchesGoldenFile(
        '../../goldens/avelune/components_high_contrast_800x900.png',
      ),
    );
  });
}

Future<void> _pumpGallery(
  WidgetTester tester, {
  required bool highContrast,
}) async {
  tester.view.physicalSize = const Size(800, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final aveluneTheme =
      highContrast ? AveluneThemeData.highContrast : AveluneThemeData.standard;
  final theme = aveluneTheme.applyTo(ThemeData.dark());

  await tester.pumpWidget(
    MaterialApp(
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
      ),
      home: const RepaintBoundary(
        key: ValueKey<String>('avelune-component-gallery'),
        child: _ComponentGallery(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _loadGoldenFont() async {
  final bytes = await File(
    '../../packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf',
  ).readAsBytes();
  final loader = FontLoader('AveluneGoldenSans')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  final materialLoader = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  // The Avelune surfaces draw Cupertino glyphs; without its font every icon
  // records as an empty box in the goldens.
  // The family name has to carry the package prefix: CupertinoIcons
  // declares a fontPackage, so Flutter resolves it as
  // `packages/cupertino_icons/CupertinoIcons`.
  final cupertinoLoader = FontLoader('packages/cupertino_icons/CupertinoIcons')
    ..addFont(
      rootBundle.load('packages/cupertino_icons/assets/CupertinoIcons.ttf'),
    );
  await Future.wait<void>(<Future<void>>[loader.load(), materialLoader.load(),
    cupertinoLoader.load(),
  ]);
}

class _ComponentGallery extends StatelessWidget {
  const _ComponentGallery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AveluneSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('AVELUNE COMPONENTS',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: AveluneSpacing.lg),
                  const AveluneSectionLabel(
                    icon: Icons.touch_app_rounded,
                    label: 'PHYSICAL CONTROLS',
                  ),
                  const SizedBox(height: AveluneSpacing.sm),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _GalleryPressable(
                          label: 'Idle',
                          semanticLabel: 'Idle control',
                        ),
                      ),
                      const SizedBox(width: AveluneSpacing.md),
                      Expanded(
                        child: _GalleryPressable(
                          label: 'Selected',
                          semanticLabel: 'Selected control',
                          selected: true,
                        ),
                      ),
                      const SizedBox(width: AveluneSpacing.md),
                      Expanded(
                        child: _GalleryPressable(
                          label: 'Invalid',
                          semanticLabel: 'Invalid control',
                          enabled: false,
                          invalid: true,
                        ),
                      ),
                      const SizedBox(width: AveluneSpacing.md),
                      AveluneIconControl(
                        semanticLabel: 'Settings',
                        icon: Icons.tune_rounded,
                        selected: true,
                        onPressed: _noop,
                      ),
                    ],
                  ),
                  const SizedBox(height: AveluneSpacing.xl),
                  const AveluneSectionLabel(
                    icon: Icons.layers_rounded,
                    label: 'INSET SURFACES',
                  ),
                  const SizedBox(height: AveluneSpacing.sm),
                  AveluneInsetPanel(
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.history_rounded,
                            color: context.aveluneColors.brass),
                        const SizedBox(width: AveluneSpacing.md),
                        const Expanded(
                          child: Text(
                            'Surfaces recessed into the furniture keep the '
                            'interface tactile without becoming a card grid.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AveluneSpacing.xl),
                  const AveluneSectionLabel(
                    icon: Icons.notifications_none_rounded,
                    label: 'STATES',
                  ),
                  const SizedBox(height: AveluneSpacing.sm),
                  const AveluneStateMessage(
                    kind: AveluneStateMessageKind.empty,
                    title: 'No recent activity',
                    message: 'Start a game to find your latest sessions here.',
                  ),
                  const SizedBox(height: AveluneSpacing.md),
                  AveluneStateMessage(
                    kind: AveluneStateMessageKind.error,
                    title: 'Game unavailable',
                    message: 'Some required files are missing.',
                    actionLabel: 'Inspect',
                    onAction: _noop,
                  ),
                ],
              ),
            ),
          ),
          AveluneBottomNavigation(
            selectedItem: AveluneNavigationItem.home,
            onItemSelected: _ignoreNavigation,
          ),
        ],
      ),
    );
  }
}

class _GalleryPressable extends StatelessWidget {
  const _GalleryPressable({
    required this.label,
    required this.semanticLabel,
    this.selected = false,
    this.enabled = true,
    this.invalid = false,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final bool enabled;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    return AvelunePressable(
      semanticLabel: semanticLabel,
      onPressed: _noop,
      selected: selected,
      enabled: enabled,
      invalid: invalid,
      child: SizedBox(
        height: AveluneShapes.minimumTouchTarget,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.aveluneColors.surfaceRaised,
            borderRadius: AveluneShapes.md,
          ),
          child: Center(child: Text(label)),
        ),
      ),
    );
  }
}

void _noop() {}

void _ignoreNavigation(AveluneNavigationItem _) {}
