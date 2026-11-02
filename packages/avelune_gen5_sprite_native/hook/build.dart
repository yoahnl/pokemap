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
    await builder.run(
      input: input,
      output: output,
      logger: Logger('avelune-gen5-native'),
    );
  });
}
