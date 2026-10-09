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

  test('native certification excludes retired Hub codec fixtures', () async {
    final workflow = await File(
      '../../.github/workflows/pokemap_product_certification.yml',
    ).readAsString();
    final support = await File(
      'tool/release/platform_support.json',
    ).readAsString();

    expect(workflow, isNot(contains('tool/release/verify_intro_codecs.sh')));
    expect(workflow, contains('test_native_host_contracts.py'));
    expect(workflow, isNot(contains('pst_074_native_codec_playback_test.dart')));
    expect(workflow, isNot(contains('flutter build ios')));
    expect(support, contains('"releaseGate": "xcode-cloud"'));
  });
}
