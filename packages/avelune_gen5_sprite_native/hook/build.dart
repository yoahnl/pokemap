import 'dart:io';

import 'package:hooks/hooks.dart';
import 'package:logging/logging.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    final builder = CBuilder.library(
      name: input.packageName,
      assetName: 'src/native_bindings.dart',
      sources: [
        'src/probe_pure.c',
        'src/api_sprite_bridge.c',
        for (final name in [
          'sprite_composer',
          'ncgr',
          'ncer',
          'nanr',
          'nmcr',
          'nmar',
          'nclr',
          'nitro_util',
          'file_util',
          'ppm',
          'coords',
          'lz',
        ])
          'src/vendor/source/$name.c',
      ],
      includes: ['src', 'src/vendor/include'],
    );
    final diagnostics = StringBuffer();
    Logger.root.level = Level.ALL;
    final logger = Logger('avelune-gen5-native');
    final subscription = logger.onRecord.listen((record) {
      if ((record.level == Level.FINE || record.level >= Level.INFO) &&
          !record.message.startsWith('Running `') &&
          diagnostics.length < 1024 * 1024) {
        diagnostics.writeln(record.message);
      }
    });
    try {
      await builder.run(input: input, output: output, logger: logger);
    } catch (_) {
      final pattern = RegExp(
        r'(?:fatal error|error|warning) (?:C|LNK)\d+:[^\r\n]{0,400}',
        caseSensitive: false,
      );
      for (final match in pattern.allMatches(diagnostics.toString())) {
        stderr.writeln(match.group(0));
      }
      rethrow;
    } finally {
      await subscription.cancel();
    }
  });
}
