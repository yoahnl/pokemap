import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_atlas_image_preview.dart';

void main() {
  testWidgets(
      'SurfaceStudioAtlasImagePreview does not overflow in reported sizes',
      (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    Future<void> pumpConstrained(Size size) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: SurfaceStudioAtlasImagePreview(
                resolution: const SurfaceStudioAtlasImagePreviewResolution(
                    status:
                        SurfaceStudioAtlasImagePreviewResolveStatus.missingFile,
                    displayFileName: 'atlas.png',
                    relativePathForUi:
                        'assets/surfaces/water/animated/atlas/source/that/is/very/long/atlas.png'),
                label: Colors.white,
                subtle: Colors.white70,
                draftTileWidth: 32,
                draftTileHeight: 32,
                draftColumns: 12,
                draftRows: 32,
                draftLayoutLabel: 'Colonnes variantes / lignes frames',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }

    await pumpConstrained(const Size(312.8, 557));
    await pumpConstrained(const Size(552, 318));

    expect(
      errors.where((details) =>
          details.exceptionAsString().contains('RenderFlex overflowed')),
      isEmpty,
    );
  });
}
