@Tags(['visual'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadGoldenFonts);

  testWidgets('Avelune production materials visual gate', (tester) async {
    tester.view.physicalSize = const Size(1200, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());
    await tester.pumpWidget(
      MaterialApp(
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
        ),
        home: const RepaintBoundary(
          key: ValueKey<String>('avelune-material-gate'),
          child: _MaterialGate(),
        ),
      ),
    );
    final context = tester.element(find.byType(_MaterialGate));
    await tester.runAsync(
      () => Future.wait<void>(
        AveluneMaterialCatalog.all
            .map((asset) => precacheImage(AssetImage(asset.path), context)),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey<String>('avelune-material-gate')),
      matchesGoldenFile('../../goldens/avelune/material_catalog_1200x1400.png'),
    );
  });

  testWidgets('Avelune materials remain crisp at 1x 2x and 3x', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());
    await tester.pumpWidget(
      MaterialApp(
        theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
        ),
        home: const RepaintBoundary(
          key: ValueKey<String>('avelune-material-scale-gate'),
          child: _MaterialScaleGate(),
        ),
      ),
    );
    final context = tester.element(find.byType(_MaterialScaleGate));
    await tester.runAsync(
      () => Future.wait<void>(
        AveluneMaterialCatalog.all
            .map((asset) => precacheImage(AssetImage(asset.path), context)),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey<String>('avelune-material-scale-gate')),
      matchesGoldenFile(
        '../../goldens/avelune/material_scale_gate_1200x1000.png',
      ),
    );
  });
}

Future<void> _loadGoldenFonts() async {
  final bytes = await File(
    '../../packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf',
  ).readAsBytes();
  final loader = FontLoader('AveluneGoldenSans')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(Uint8List.fromList(bytes))),
    );
  await loader.load();
}

class _MaterialGate extends StatelessWidget {
  const _MaterialGate();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.aveluneColors.canvas,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AveluneSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('AVELUNE MATERIAL GATE',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: AveluneSpacing.lg),
              _Section(
                title: 'ROOM BACKGROUNDS',
                child: Row(
                  children: AveluneMaterialCatalog.backgrounds
                      .map(
                        (asset) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _LabeledAsset(
                              label: asset.id.split('.').last,
                              height: 210,
                              asset: asset,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AveluneSpacing.lg),
              _Section(
                title: 'FURNITURE — ONE GEOMETRY',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: AveluneMaterialCatalog.furniture
                      .map(
                        (asset) => SizedBox(
                          width: 362,
                          child: _LabeledAsset(
                            label: asset.id.split('.').last,
                            height: 220,
                            asset: asset,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: AveluneSpacing.lg),
              _Section(
                title: 'REAL OBJECT LAYERS',
                child: SizedBox(
                  height: 300,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Expanded(flex: 7, child: _ConsoleComposite()),
                      const SizedBox(width: AveluneSpacing.lg),
                      const Expanded(flex: 3, child: _CartridgeComposite()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialScaleGate extends StatelessWidget {
  const _MaterialScaleGate();

  @override
  Widget build(BuildContext context) {
    final console = AveluneMaterialCatalog.consoleLayers;
    final cartridge = AveluneMaterialCatalog.cartridgeLayers;
    return ColoredBox(
      color: context.aveluneColors.canvas,
      child: Padding(
        padding: const EdgeInsets.all(AveluneSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('AVELUNE 1× / 2× / 3× SCALE GATE',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AveluneSpacing.md),
            _ScaleRow(
              label: 'walnut',
              aspectRatio: 768 / 700,
              widths: const <double>[92, 184, 276],
              assetPaths: <String>[
                AveluneMaterialCatalog.furniture[0].path,
              ],
            ),
            _ScaleRow(
              label: 'ivory',
              aspectRatio: 768 / 700,
              widths: const <double>[92, 184, 276],
              assetPaths: <String>[
                AveluneMaterialCatalog.furniture[1].path,
              ],
            ),
            _ScaleRow(
              label: 'console',
              aspectRatio: 1200 / 360,
              widths: const <double>[108, 216, 324],
              assetPaths: <String>[console[0].path, console[2].path],
            ),
            _ScaleRow(
              label: 'cartridge',
              aspectRatio: 0.7,
              widths: const <double>[56, 112, 168],
              assetPaths: <String>[
                cartridge[0].path,
                cartridge[1].path,
                cartridge[2].path,
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow({
    required this.label,
    required this.aspectRatio,
    required this.widths,
    required this.assetPaths,
  });

  final String label;
  final double aspectRatio;
  final List<double> widths;
  final List<String> assetPaths;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.aveluneColors.outline)),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 118,
              child: Text(label, style: Theme.of(context).textTheme.titleSmall),
            ),
            for (var index = 0; index < widths.length; index++)
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned(
                      top: 8,
                      child: Text('${index + 1}×',
                          style: Theme.of(context).textTheme.labelMedium),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: widths[index],
                        child: AspectRatio(
                          aspectRatio: aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: assetPaths
                                .map((path) => Image.asset(path))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: AveluneSpacing.sm),
        child,
      ],
    );
  }
}

class _LabeledAsset extends StatelessWidget {
  const _LabeledAsset({
    required this.label,
    required this.height,
    required this.asset,
    this.fit = BoxFit.contain,
  });

  final String label;
  final double height;
  final AveluneMaterialAsset asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.aveluneColors.surfaceRaised,
        borderRadius: AveluneShapes.md,
        border: Border.all(color: context.aveluneColors.outline),
      ),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: height,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AveluneShapes.radiusMd),
              ),
              child: Image.asset(asset.path, fit: fit),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
        ],
      ),
    );
  }
}

class _ConsoleComposite extends StatelessWidget {
  const _ConsoleComposite();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            context.aveluneColors.surfaceRaised,
            context.aveluneColors.canvas,
          ],
        ),
        borderRadius: AveluneShapes.lg,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 34,
            right: 34,
            bottom: 38,
            child: Image.asset(
              AveluneMaterialCatalog.consoleLayers[3].path,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 48,
            child: AspectRatio(
              aspectRatio: 1200 / 360,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(AveluneMaterialCatalog.consoleLayers[0].path),
                  Image.asset(AveluneMaterialCatalog.consoleLayers[2].path),
                ],
              ),
            ),
          ),
          Positioned(
            width: 360,
            bottom: 146,
            child: Image.asset(AveluneMaterialCatalog.consoleLayers[1].path),
          ),
          Positioned(
            left: 22,
            top: 18,
            child: Text('console body + slot + wear + shadow',
                style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _CartridgeComposite extends StatelessWidget {
  const _CartridgeComposite();

  @override
  Widget build(BuildContext context) {
    final cartridge = AveluneMaterialCatalog.cartridgeLayers;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.aveluneColors.surfaceRaised,
        borderRadius: AveluneShapes.lg,
      ),
      child: Center(
        child: AspectRatio(
          aspectRatio: 0.7,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(cartridge[0].path),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, 0.02),
                  child: FractionallySizedBox(
                    widthFactor: 0.61,
                    heightFactor: 0.53,
                    child: Image.asset(
                      AveluneMaterialCatalog.fallbackArtwork.path,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, 0.02),
                  child: FractionallySizedBox(
                    widthFactor: 0.66,
                    heightFactor: 0.57,
                    child: Opacity(
                      opacity: 0.42,
                      child: Image.asset(cartridge[4].path, fit: BoxFit.fill),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: const Alignment(0, 0.95),
                  child: FractionallySizedBox(
                    widthFactor: 0.82,
                    heightFactor: 0.105,
                    child: Image.asset(cartridge[3].path, fit: BoxFit.fill),
                  ),
                ),
              ),
              Image.asset(cartridge[1].path),
              Image.asset(cartridge[2].path),
            ],
          ),
        ),
      ),
    );
  }
}
