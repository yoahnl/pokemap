import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final bool _ffprobeAvailable = !Platform.isWindows &&
    Process.runSync('/usr/bin/env', <String>[
          'sh',
          '-c',
          'command -v ffprobe',
        ]).exitCode ==
        0;

void main() {
  test(
    'certification intro fixtures contain H.264 video and AAC audio',
    () async {
      final verification = await Process.run(
        '/bin/bash',
        <String>['tool/release/verify_intro_codecs.sh'],
      );

      expect(verification.exitCode, 0, reason: '${verification.stderr}');
      expect(verification.stdout, contains('landscape_codec_verified=true'));
      expect(verification.stdout, contains('portrait_codec_verified=true'));
    },
    skip: !_ffprobeAvailable,
  );

  test('certification workflow runs codec and native playback gates', () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_hub_product_certification.yml',
    ).readAsString();

    expect(workflow, contains('tool/release/verify_intro_codecs.sh'));
    expect(
      workflow,
      contains(
        'flutter test '
        'integration_test/pst_074_native_codec_playback_test.dart -d macos',
      ),
    );
    expect(
      RegExp('pst_074_native_codec_playback_test\\.dart').allMatches(workflow),
      hasLength(2),
    );
  });
}
