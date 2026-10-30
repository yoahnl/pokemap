import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

abstract interface class StudioMcpProcess {
  Stream<Map<String, Object?>> get events;
  Future<int> get exitCode;
  Future<void> send(Map<String, Object?> command);
  Future<void> shutdown();
}

class StudioMcpLaunchConfiguration {
  static String get architecture => switch (Abi.current()) {
    Abi.macosArm64 || Abi.linuxArm64 || Abi.windowsArm64 => 'arm64',
    Abi.macosX64 || Abi.linuxX64 || Abi.windowsX64 => 'x64',
    _ => 'unsupported',
  };
  const StudioMcpLaunchConfiguration({
    required this.executable,
    required this.arguments,
    required this.workingDirectory,
  });

  final String executable;
  final List<String> arguments;
  final String workingDirectory;

  static Future<StudioMcpLaunchConfiguration> resolve() async {
    final executableDirectory = p.dirname(Platform.resolvedExecutable);
    const override = String.fromEnvironment('AVELUNE_MCP_RUNTIME_MANIFEST');
    final manifestPath = kDebugMode
        ? (override.isNotEmpty
              ? override
              : Platform.environment['AVELUNE_MCP_RUNTIME_MANIFEST'])
        : null;
    final bundledManifest = Platform.isMacOS
        ? p.normalize(
            p.join(
              executableDirectory,
              '..',
              'Resources',
              'mcp',
              'runtime-manifest.json',
            ),
          )
        : p.join(executableDirectory, 'mcp', 'runtime-manifest.json');
    final architectureManifest = File(
      p.join(p.dirname(bundledManifest), 'runtime-manifest-$architecture.json'),
    );
    final manifest = File(
      manifestPath ??
          (await architectureManifest.exists()
              ? architectureManifest.path
              : bundledManifest),
    );
    if (await manifest.exists()) return fromManifest(manifest);
    if (manifestPath != null || !kDebugMode) {
      throw const FormatException('distribution.manifest_unavailable');
    }
    var candidate = Directory.current.absolute;
    while (true) {
      final server = File(
        p.join(
          candidate.path,
          'tools',
          'pokemap_mcp',
          'dist',
          'src',
          'index.js',
        ),
      );
      final studio = File(
        p.join(candidate.path, 'apps', 'avelune_studio', 'pubspec.yaml'),
      );
      if (await server.exists() && await studio.exists()) {
        return StudioMcpLaunchConfiguration(
          executable: 'node',
          arguments: [
            server.absolute.path,
            '--companion',
            'true',
            '--transport',
            'http',
          ],
          workingDirectory: candidate.path,
        );
      }
      final parent = candidate.parent;
      if (parent.path == candidate.path) break;
      candidate = parent;
    }
    throw const FormatException('distribution.development_server_unavailable');
  }

  static Future<StudioMcpLaunchConfiguration> fromManifest(
    File manifest,
  ) async {
    if (await FileSystemEntity.type(manifest.path, followLinks: false) !=
            FileSystemEntityType.file ||
        await FileSystemEntity.type(manifest.parent.path, followLinks: false) !=
            FileSystemEntityType.directory) {
      throw const FormatException('distribution.manifest_path_invalid');
    }
    final canonicalManifest = await manifest.resolveSymbolicLinks();
    final root = await manifest.parent.resolveSymbolicLinks();
    if (canonicalManifest != p.join(root, manifest.uri.pathSegments.last)) {
      throw const FormatException('distribution.manifest_outside_bundle');
    }
    final value = jsonDecode(await File(canonicalManifest).readAsString());
    if (value is! Map ||
        value['schemaVersion'] != 1 ||
        value['components'] is! List ||
        value['platform'] !=
            (Platform.isMacOS
                ? 'darwin'
                : Platform.isWindows
                ? 'win32'
                : Platform.operatingSystem) ||
        value['architecture'] != architecture) {
      throw const FormatException('distribution.manifest_invalid');
    }
    Future<String> component(String id, String kind) async {
      final matching = (value['components'] as List)
          .whereType<Map>()
          .where((entry) => entry['id'] == id)
          .toList();
      if (matching.length != 1 || matching.single['kind'] != kind) {
        throw const FormatException('distribution.component_unavailable');
      }
      final relative = matching.single['path'];
      if (relative is! String ||
          relative.isEmpty ||
          p.isAbsolute(relative) ||
          relative.contains('\\') ||
          relative.contains(':') ||
          relative
              .split('/')
              .any((part) => part.isEmpty || part == '..' || part == '.')) {
        throw const FormatException('distribution.component_path_invalid');
      }
      final resolved = await File(p.join(root, relative))
          .resolveSymbolicLinks();
      if (!p.isWithin(root, resolved)) {
        throw const FormatException('distribution.component_outside_bundle');
      }
      final expected = matching.single['sha256'];
      if (expected is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(expected) ||
          (await sha256.bind(File(resolved).openRead()).first).toString() !=
              expected) {
        throw const FormatException('distribution.component_integrity_failed');
      }
      return resolved;
    }

    final node = await component('node', 'executable');
    final server = await component('server', 'resource');
    return StudioMcpLaunchConfiguration(
      executable: node,
      arguments: [
        server,
        '--companion',
        'true',
        '--transport',
        'http',
        '--runtime-manifest',
        canonicalManifest,
      ],
      workingDirectory: root,
    );
  }
}

Future<StudioMcpProcess> launchStudioMcpProcess() async {
  final configuration = await StudioMcpLaunchConfiguration.resolve();
  final process = await Process.start(
    configuration.executable,
    configuration.arguments,
    workingDirectory: configuration.workingDirectory,
    runInShell: false,
  );
  return _OwnedStudioMcpProcess(process);
}

class _OwnedStudioMcpProcess implements StudioMcpProcess {
  _OwnedStudioMcpProcess(this._process) {
    _stderr = _process.stderr.listen((_) {});
    _stdout = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            try {
              final value = jsonDecode(line);
              if (value is! Map<String, dynamic>) throw const FormatException();
              _events.add(value);
            } on Object {
              _events.addError(
                const FormatException('companion.control_invalid'),
              );
            }
          },
          onError: _events.addError,
          onDone: () => unawaited(_events.close()),
        );
    unawaited(_process.exitCode.then((_) => _exited = true));
  }

  final Process _process;
  final _events = StreamController<Map<String, Object?>>();
  late final StreamSubscription<List<int>> _stderr;
  late final StreamSubscription<String> _stdout;
  bool _exited = false;
  Future<void>? _stopping;

  @override
  Stream<Map<String, Object?>> get events => _events.stream;
  @override
  Future<int> get exitCode => _process.exitCode;

  @override
  Future<void> send(Map<String, Object?> command) async {
    if (_exited) throw StateError('companion.stopped');
    _process.stdin.writeln(jsonEncode(command));
    await _process.stdin.flush();
  }

  @override
  Future<void> shutdown() => _stopping ??= _shutdown();

  Future<void> _shutdown() async {
    try {
      if (!_exited) {
        try {
          await send({'id': 'studio-shutdown', 'command': 'shutdown'})
              .timeout(const Duration(seconds: 1));
          await _process.stdin.close().timeout(const Duration(seconds: 1));
        } on Object {
          _process.kill(ProcessSignal.sigterm);
        }
        try {
          await _process.exitCode.timeout(const Duration(seconds: 3));
        } on TimeoutException {
          if (!_exited) _process.kill(ProcessSignal.sigterm);
          try {
            await _process.exitCode.timeout(const Duration(seconds: 2));
          } on TimeoutException {
            if (!_exited) _process.kill(ProcessSignal.sigkill);
            await _process.exitCode;
          }
        }
      }
    } finally {
      await _stdout.cancel();
      await _stderr.cancel();
      unawaited(_events.close());
    }
  }
}
