import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:avelune_studio/platform/mcp/studio_mcp_process.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final installed = Platform.environment['POKEMAP_INSTALLED_MCP_MANIFEST'];
  test(
    'installed signed manifest resolves before any process is launched',
    () async {
      final configuration = await StudioMcpLaunchConfiguration.fromManifest(
        File(installed!),
      );
      expect(configuration.arguments, contains(installed));
    },
    skip: installed == null
        ? 'Opt-in installed distribution qualification.'
        : false,
  );
  test('launch configuration verifies platform, hashes and confinement before execution', () async {
    final parent = Directory(
      p.join(
        Platform.environment['HOME']!,
        'Library/Caches/AveluneQA/mcp-studio-integration/launch',
      ),
    );
    await parent.create(recursive: true);
    final root = await parent.createTemp('bundle été ');
    addTearDown(() async {
      await root.delete(recursive: true);
      await parent.delete();
    });
    final node = File(p.join(root.path, 'node'));
    final server = File(p.join(root.path, 'server.mjs'));
    await node.writeAsString('node-placeholder');
    await server.writeAsString('server-placeholder');
    final manifest = File(p.join(root.path, 'runtime-manifest.json'));
    final value = <String, Object?>{
      'schemaVersion': 1,
      'platform': Platform.isMacOS
          ? 'darwin'
          : Platform.isWindows
          ? 'win32'
          : 'linux',
      'architecture': switch (Abi.current()) {
        Abi.macosArm64 || Abi.linuxArm64 || Abi.windowsArm64 => 'arm64',
        _ => 'x64',
      },
      'components': [
        {
          'id': 'node',
          'kind': 'executable',
          'path': 'node',
          'sha256': sha256.convert(await node.readAsBytes()).toString(),
        },
        {
          'id': 'server',
          'kind': 'resource',
          'path': 'server.mjs',
          'sha256': sha256.convert(await server.readAsBytes()).toString(),
        },
      ],
    };
    Future<void> save() => manifest.writeAsString(jsonEncode(value));
    await save();
    final configuration = await StudioMcpLaunchConfiguration.fromManifest(
      manifest,
    );
    expect(configuration.executable, node.path);
    await node.writeAsString('tampered');
    await expectLater(
      StudioMcpLaunchConfiguration.fromManifest(manifest),
      throwsFormatException,
    );
    await node.writeAsString('node-placeholder');
    value['platform'] = 'other';
    await save();
    await expectLater(
      StudioMcpLaunchConfiguration.fromManifest(manifest),
      throwsFormatException,
    );
    if (!Platform.isWindows) {
      final link = Link(p.join(root.path, 'linked-manifest.json'));
      await link.create(manifest.path);
      await expectLater(
        StudioMcpLaunchConfiguration.fromManifest(File(link.path)),
        throwsFormatException,
      );
    }
  });
}
