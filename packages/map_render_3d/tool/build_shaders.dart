import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

Future<void> main() async {
  final package = File.fromUri(Platform.script).parent.parent;
  final flame = await Isolate.resolvePackageUri(
    Uri.parse('package:flame_3d/model.dart'),
  );
  if (flame == null) throw StateError('flame_3d package is unavailable.');
  final cache = File(Platform.resolvedExecutable).resolveSymbolicLinksSync();
  final artifacts = File(
    cache,
  ).parent.parent.parent.uri.resolve('artifacts/engine/');
  final compiler = [
    for (final host in [
      'darwin-x64',
      'darwin-arm64',
      'linux-x64',
      'windows-x64',
    ])
      File.fromUri(
        artifacts.resolve('$host/impellerc${Platform.isWindows ? '.exe' : ''}'),
      ),
  ].firstWhere((file) => file.existsSync());
  final bundle = {
    'TextureFragment': {
      'type': 'fragment',
      'file': '${package.path}/shaders/pixel_material.frag',
    },
    'TextureVertex': {
      'type': 'vertex',
      'file': '${package.path}/shaders/pixel_material.vert',
    },
  };
  final result = await Process.run(compiler.path, [
    '--sl=${package.path}/assets/shaders/pixel_material.shaderbundle',
    '--shader-bundle=${jsonEncode(bundle)}',
    '--include=${package.path}/shaders',
    '--include=${File.fromUri(flame).parent.parent.path}/shaders',
    '--include=${compiler.parent.path}/shader_lib',
  ]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  exitCode = result.exitCode;
  if (result.exitCode == 0)
    stdout.writeln('Pixel material shader bundle built.');
}
