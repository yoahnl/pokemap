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
  final bundle = {
    'WeatherVertex': {
      'type': 'vertex',
      'file': '${package.path}/shaders/weather.vert',
    },
    'WeatherFragment': {
      'type': 'fragment',
      'file': '${package.path}/shaders/weather.frag',
    },
    'DepthOfFieldVertex': {
      'type': 'vertex',
      'file': '${package.path}/shaders/depth_of_field.vert',
    },
    'DepthOfFieldFragment': {
      'type': 'fragment',
      'file': '${package.path}/shaders/depth_of_field.frag',
    },
    'FsrEasuFragment': {
      'type': 'fragment',
      'file': '${package.path}/shaders/fsr_easu.frag',
    },
    'FsrRcasFragment': {
      'type': 'fragment',
      'file': '${package.path}/shaders/fsr_rcas.frag',
    },
    'TextureFragment': {
      'type': 'fragment',
      'file': '${package.path}/shaders/pixel_material.frag',
    },
    'TextureVertex': {
      'type': 'vertex',
      'file': '${package.path}/shaders/pixel_material.vert',
    },
    'GroundVertex': {
      'type': 'vertex',
      'file': '${package.path}/shaders/pixel_ground.vert',
    },
    'LitTextureVertex': {
      'type': 'vertex',
      'file': '${package.path}/shaders/pixel_lit_material.vert',
    },
    'ShadowDepthFragment': {
      'type': 'fragment',
      'file': '${package.path}/shaders/shadow_depth.frag',
    },
    'ShadowDepthMsaaFragment': {
      'type': 'fragment',
      'file': '${package.path}/shaders/shadow_depth_msaa.frag',
    },
    'PointShadowVertex': {
      'type': 'vertex',
      'file': '${package.path}/shaders/point_shadow.vert',
    },
    'PointShadowDepthFragment': {
      'type': 'fragment',
      'file': '${package.path}/shaders/point_shadow_depth.frag',
    },
    'PointShadowDepthMsaaFragment': {
      'type': 'fragment',
      'file': '${package.path}/shaders/point_shadow_depth_msaa.frag',
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
