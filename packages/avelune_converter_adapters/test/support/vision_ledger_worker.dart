import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';

import 'vision_test_fixture.dart';

Future<void> main(List<String> arguments) async {
  final store =
      LocalVisionStore(rootPath: arguments[0], excludedRoots: () async => []);
  try {
    await store.reserve(
        request: VisionTestFixture().request(requestId: arguments[1]),
        policy: const VisionAssistancePolicy(maxRequests: 1),
        attempt: 0);
    stdout.writeln('reserved');
  } on VisionAssistanceException {
    stdout.writeln('refused');
  }
}
