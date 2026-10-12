import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/vision_test_fixture.dart';

void main() {
  test('attests exact RGBA despite PNG encoding differences', () async {
    final fixture = VisionTestFixture();
    await verifyVisionCrops(
        material: fixture.request().material,
        sourceFiles: VisionTestFiles(fixture.sourceBytes),
        cancellation: ScanCancellation());
  });
  test('horizontal reflection precedes clockwise quarter turn', () async {
    final fixture = VisionTestFixture();
    final request = fixture.request(
        reflected: true,
        quarterTurns: 1,
        cropBytes: visionPng(3, 2, [6, 4, 2, 5, 3, 1]));
    await verifyVisionCrops(
        material: request.material,
        sourceFiles: VisionTestFiles(fixture.sourceBytes),
        cancellation: ScanCancellation());
  });
  test('incorrect transform pixels are refused even at matching dimensions',
      () async {
    final fixture = VisionTestFixture();
    final request = fixture.request(
        reflected: true,
        quarterTurns: 1,
        cropBytes: visionPng(3, 2, [5, 3, 1, 6, 4, 2]));
    await expectLater(
        verifyVisionCrops(
            material: request.material,
            sourceFiles: VisionTestFiles(fixture.sourceBytes),
            cancellation: ScanCancellation()),
        throwsA(isA<VisionAssistanceException>()));
  });
}
