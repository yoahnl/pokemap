import 'dart:convert';
import 'dart:io';

Future<void> main() async {
  final package = File.fromUri(Platform.script).parent.parent;
  final cache = File(Platform.resolvedExecutable).resolveSymbolicLinksSync();
  final artifacts = File(cache).parent.parent.parent.uri
      .resolve('artifacts/engine/');
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
  final shaders = '${package.path}/shaders';
  for (final name in ['unlit_material', 'spatial_material']) {
    final bundle = {
      'TextureFragment': {'type': 'fragment', 'file': '$shaders/$name.frag'},
      'TextureVertex': {'type': 'vertex', 'file': '$shaders/$name.vert'},
    };
    final result = await Process.run(compiler.path, [
      '--sl=${package.path}/assets/shaders/$name.shaderbundle',
      '--shader-bundle=${jsonEncode(bundle)}',
      '--include=$shaders',
      '--include=${compiler.parent.path}/shader_lib',
    ]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) {
      exitCode = result.exitCode;
      return;
    }
    stdout.writeln('Built $name.shaderbundle.');
  }
}
