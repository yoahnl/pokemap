import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_studio/platform/rendering/regional_map_image_decoder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../application/regional_map_controller_test.dart'
    show MemoryRegionalMapPort;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the regional decoder retains source bytes and real image dimensions',
    () async {
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      );
      final port = MemoryRegionalMapPort()..imageBytes = bytes;
      final result = await decodeRegionalMapImage(port, 'assets/region.png');
      expect(result, isNotNull);
      expect(result!.bytes, orderedEquals(bytes));
      expect((result.width, result.height), (1, 1));
    },
  );

  test(
    'a missing image stays absent and malformed bytes report an error',
    () async {
      final port = MemoryRegionalMapPort();
      expect(await decodeRegionalMapImage(port, 'assets/missing.png'), isNull);
      port.imageBytes = Uint8List.fromList([1, 2, 3]);
      await expectLater(
        decodeRegionalMapImage(port, 'assets/broken.png'),
        throwsStateError,
      );
    },
  );
}
