import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_authoring/src/api/local_map_authoring_mutation_api.dart';
import 'package:map_authoring/src/api/local_resource_pack_transfer_api.dart';
import 'package:map_authoring/src/contracts/artifact_ref.dart';
import 'package:map_authoring/src/contracts/authoring_request.dart';
import 'package:map_authoring/src/domains/assets/asset_store.dart';
import 'package:map_authoring/src/domains/assets/resource_pack_projection.dart';
import 'package:map_authoring/src/ports/project_file_reader.dart';
import 'package:map_authoring/src/support/authoring_performance_observer.dart';
import 'package:map_authoring/src/workspace/project_open_service.dart';
import 'package:map_authoring/src/workspace/project_snapshot.dart';
import 'package:map_authoring/src/workspace/project_snapshot_loader.dart';
import 'package:map_authoring/src/workspace/workspace_handle_store.dart';
import 'package:map_authoring/src/workspace/workspace_policy.dart';

import 'package:path/path.dart' as p;

enum ResourcePackVolumeCampaign { resources, entries, capacity }

final class ResourcePackVolumeOptions {
  ResourcePackVolumeOptions._({
    required this.help,
    required this.campaign,
    required this.resourceCounts,
    required this.zipEntries,
    required this.archiveBytes,
    required this.payloadBytes,
    required this.outputPath,
    this.workerExecutable,
    this.workerSha256,
    this.workerBuildReceipt,
  });

  factory ResourcePackVolumeOptions.parse(List<String> arguments) {
    if (arguments.length == 1 && arguments.single == '--help') {
      return ResourcePackVolumeOptions._(
        help: true,
        campaign: ResourcePackVolumeCampaign.resources,
        resourceCounts: const [],
        zipEntries: 20000,
        archiveBytes: 536870912,
        payloadBytes: 524288000,
        outputPath: '',
      );
    }
    final values = <String, String>{};
    const known = {
      '--mode',
      '--campaign',
      '--output',
      '--resources',
      '--zip-entries',
      '--payload-bytes',
      '--archive-bytes',
      '--worker-executable',
      '--worker-sha256',
      '--worker-build-receipt',
    };
    for (var index = 0; index < arguments.length; index += 2) {
      final key = arguments[index];
      if (!known.contains(key) ||
          index + 1 == arguments.length ||
          arguments[index + 1].startsWith('--') ||
          values.containsKey(key)) {
        throw FormatException('Invalid or duplicate option: $key');
      }
      values[key] = arguments[index + 1];
    }
    if (values['--mode'] != 'local') {
      throw const FormatException('Explicit --mode local is required.');
    }
    final campaign = switch (values['--campaign']) {
      'resources' => ResourcePackVolumeCampaign.resources,
      'entries' => ResourcePackVolumeCampaign.entries,
      'capacity' => ResourcePackVolumeCampaign.capacity,
      _ => throw const FormatException('An explicit campaign is required.'),
    };
    final output = values['--output'];
    if (output == null || output.isEmpty || !p.isAbsolute(output)) {
      throw const FormatException(
        'An absolute --output directory is required.',
      );
    }
    final allowed = {
      '--mode',
      '--campaign',
      '--output',
      '--archive-bytes',
      '--worker-executable',
      '--worker-sha256',
      '--worker-build-receipt',
      switch (campaign) {
        ResourcePackVolumeCampaign.resources => '--resources',
        ResourcePackVolumeCampaign.entries => '--zip-entries',
        ResourcePackVolumeCampaign.capacity => '--payload-bytes',
      },
    };
    if (values.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException('Campaign options cannot be combined.');
    }
    final worker = values['--worker-executable'];
    final workerHash = values['--worker-sha256'];
    final workerReceipt = values['--worker-build-receipt'];
    if ([worker, workerHash, workerReceipt].any((value) => value != null) &&
        (worker == null ||
            !p.isAbsolute(worker) ||
            workerReceipt == null ||
            !p.isAbsolute(workerReceipt) ||
            !_sha64(workerHash))) {
      throw const FormatException(
        'All three AOT worker options require absolute paths and a lowercase SHA-256.',
      );
    }
    int bounded(String key, int maximum, {int? fallback}) {
      final raw = values[key];
      final value = raw == null
          ? fallback
          : RegExp(r'^[1-9][0-9]*$').hasMatch(raw)
          ? int.tryParse(raw)
          : null;
      if (value == null || value < 1 || value > maximum) {
        throw FormatException('$key must be between 1 and $maximum.');
      }
      return value;
    }

    final counts = <int>[];
    if (campaign == ResourcePackVolumeCampaign.resources) {
      final raw = values['--resources'];
      if (raw == null) {
        throw const FormatException('--resources is required.');
      }
      for (final item in raw.split(',')) {
        final count = RegExp(r'^[1-9][0-9]*$').hasMatch(item)
            ? int.tryParse(item)
            : null;
        if (count == null ||
            count < 1 ||
            count > 10000 ||
            counts.contains(count)) {
          throw const FormatException(
            'Resource counts must be distinct integers between 1 and 10000.',
          );
        }
        counts.add(count);
      }
    }
    return ResourcePackVolumeOptions._(
      help: false,
      campaign: campaign,
      resourceCounts: List.unmodifiable(counts),
      zipEntries: campaign == ResourcePackVolumeCampaign.entries
          ? bounded('--zip-entries', 20000)
          : 20000,
      archiveBytes: bounded('--archive-bytes', 536870912, fallback: 536870912),
      payloadBytes: campaign == ResourcePackVolumeCampaign.capacity
          ? bounded('--payload-bytes', 524288000)
          : 524288000,
      outputPath: output,
      workerExecutable: worker,
      workerSha256: workerHash,
      workerBuildReceipt: workerReceipt,
    );
  }

  final bool help;
  final ResourcePackVolumeCampaign campaign;
  final List<int> resourceCounts;
  final int zipEntries;
  final int archiveBytes;
  final int payloadBytes;
  final String outputPath;
  final String? workerExecutable;
  final String? workerSha256;
  final String? workerBuildReceipt;
}

bool _sha64(Object? value) =>
    value is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(value);

String _canonicalHash(Object? value) =>
    sha256.convert(CanonicalJson.encodeUtf8(value)).toString();

String _targetArchitecture() {
  final match = RegExp(r'"[^" ]+_(arm64|x64|ia32|arm|riscv64)"$')
      .firstMatch(Platform.version);
  if (match == null) throw const FormatException('Unknown Dart target architecture.');
  return match[1]!;
}

Map<String, dynamic> resourcePackVolumeWorkerIdentity() => {
  'formatVersion': 1,
  'kind': 'resource_pack_volume_worker_identity',
  'executionKind': const bool.fromEnvironment('dart.vm.product')
      ? 'dart-aot'
      : 'dart-jit',
  'buildId': const String.fromEnvironment('P12_RESOURCE_PACK_WORKER_BUILD_ID'),
  'dartSdkVersion': Platform.version,
  'targetOS': Platform.operatingSystem,
  'targetArchitecture': _targetArchitecture(),
};

List<String> resourcePackVolumeChildCommand({
  required String dartExecutable,
  required String tool,
  required String config,
  required String mode,
  required String request,
  String? workerExecutable,
}) {
  if (!['generate', 'worker'].contains(mode)) {
    throw const FormatException('Unknown child mode.');
  }
  return mode == 'worker' && workerExecutable != null
      ? [workerExecutable, '--internal-worker', request]
      : [dartExecutable, '--packages=$config', tool, '--internal-$mode', request];
}

final class ResourcePackVolumeAotWorker {
  ResourcePackVolumeAotWorker._(
    this.executable,
    this.executableSha256,
    this.receiptPath,
    this.receiptSha256,
    this.inputs,
    this.compileCommand,
  );

  final String executable, executableSha256, receiptPath, receiptSha256;
  final Map<String, dynamic> inputs;
  final List<String> compileCommand;
  Map<String, dynamic>? _reportedIdentity;

  String get buildId => _canonicalHash(inputs);

  static Map<String, dynamic> buildInputs(
    Map<String, dynamic> sourceIdentity, {
    String? dartSdkVersion,
    String? targetOS,
    String? targetArchitecture,
  }) {
    final sources = _object(sourceIdentity['sourceFiles']);
    final roots = _object(sourceIdentity['productPackageRoots']);
    final tool = sourceIdentity['toolCanonicalPath'];
    if (sources.isEmpty ||
        sources.values.any((value) => !_sha64(value)) ||
        sourceIdentity['sourceFingerprint'] != _canonicalHash(sources) ||
        !_sha64(sourceIdentity['packageConfigSha256']) ||
        tool is! String || !p.isAbsolute(tool) ||
        roots.length != 4 ||
        !roots.keys.toSet().containsAll({
          'map_core', 'map_authoring', 'map_distribution', 'map_gameplay',
        }) ||
        roots.values.any((value) => value is! String || !p.isAbsolute(value))) {
      throw const FormatException('Pinned worker source/config identity is incomplete.');
    }
    return {
      'formatVersion': 1,
      'toolCanonicalPath': tool,
      'dartSdkVersion': dartSdkVersion ?? Platform.version,
      'targetOS': targetOS ?? Platform.operatingSystem,
      'targetArchitecture': targetArchitecture ?? _targetArchitecture(),
      'sourceManifestSha256': sourceIdentity['sourceFingerprint'],
      'sourceFilesSha256': sources,
      'packageConfigSha256': sourceIdentity['packageConfigSha256'],
      'resolvedProductPackageRoots': roots,
    };
  }

  static Future<Map<String, dynamic>> describeBuild(String tool, String config) async =>
      buildInputs(await _identity(
        await File(tool).resolveSymbolicLinks(),
        await File(config).resolveSymbolicLinks(),
        includeWorkerBuildSources: true,
      ));

  static Future<ResourcePackVolumeAotWorker> verifyBuild(
    ResourcePackVolumeOptions options,
    Map<String, dynamic> sourceIdentity,
  ) async {
    final path = options.workerExecutable;
    final receipt = options.workerBuildReceipt;
    if (path == null || receipt == null || !_sha64(options.workerSha256)) {
      throw const FormatException('Explicit AOT worker options are missing.');
    }
    for (final file in [path, receipt]) {
      if (await FileSystemEntity.type(file, followLinks: false) != FileSystemEntityType.file) {
        throw const FormatException('AOT executable and build receipt must be regular files.');
      }
    }
    final executable = await File(path).resolveSymbolicLinks();
    final receiptPath = await File(receipt).resolveSymbolicLinks();
    if (!Platform.isWindows && (await File(executable).stat()).mode & 0x49 == 0) {
      throw const FormatException('The pinned AOT file is not executable.');
    }
    final binaryHash = await _hash(File(executable));
    if (binaryHash != options.workerSha256) {
      throw const FormatException('AOT executable SHA-256 mismatch.');
    }
    final receiptHash = await _hash(File(receiptPath));
    final build = await _readJson(File(receiptPath));
    final inputs = buildInputs(sourceIdentity);
    final id = _canonicalHash(inputs);
    final command = [
      Platform.resolvedExecutable, 'compile', 'exe',
      '-DP12_RESOURCE_PACK_WORKER_BUILD_ID=$id',
      inputs['toolCanonicalPath'] as String, '-o', executable,
    ];
    if (build['formatVersion'] is! int || build['formatVersion'] != 1 ||
        build['kind'] != 'resource_pack_volume_worker_build' ||
        build['workerExecutableCanonicalPath'] != executable ||
        build['workerExecutableRawSha256'] != binaryHash ||
        build['workerBuildId'] != id ||
        build['sourcesAndConfigUnchangedDuringBuild'] != true ||
        !_same(build['compileCommand'], command) ||
        inputs.entries.any((entry) => !_same(build[entry.key], entry.value))) {
      throw const FormatException('AOT build provenance differs from pinned source/config/SDK/target.');
    }
    return ResourcePackVolumeAotWorker._(
      executable, binaryHash, receiptPath, receiptHash, inputs, command,
    );
  }

  void verifyIdentity(Map<String, dynamic> identity) {
    _reportedIdentity = null;
    if (identity['formatVersion'] is! int || identity['formatVersion'] != 1 ||
        identity['kind'] != 'resource_pack_volume_worker_identity' ||
        identity['executionKind'] != 'dart-aot' ||
        identity['buildId'] != buildId ||
        ['dartSdkVersion', 'targetOS', 'targetArchitecture']
            .any((key) => identity[key] != inputs[key])) {
      throw const FormatException('The executable did not report its pinned AOT build identity.');
    }
    _reportedIdentity = Map.unmodifiable(identity);
  }

  Future<void> probeIdentity() async {
    await checkUnchanged();
    final process = await Process.start(executable, ['--internal-worker-identity']);
    await process.stdin.close();
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.transform(utf8.decoder).join();
    late final int code;
    try {
      code = await process.exitCode.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      process.kill();
      await process.exitCode.timeout(const Duration(seconds: 1), onTimeout: () async {
        process.kill(ProcessSignal.sigkill);
        return process.exitCode;
      });
      throw const FormatException('AOT identity probe timed out.');
    } finally {
      await Future.wait([output, errors]);
    }
    if (code != 0) throw const FormatException('AOT identity probe failed.');
    verifyIdentity(_object(jsonDecode(await output)));
    await checkUnchanged();
  }

  Future<void> checkUnchanged() async {
    if (await FileSystemEntity.type(executable, followLinks: false) != FileSystemEntityType.file ||
        await FileSystemEntity.type(receiptPath, followLinks: false) != FileSystemEntityType.file ||
        await _hash(File(executable)) != executableSha256 ||
        await _hash(File(receiptPath)) != receiptSha256) {
      throw const FormatException('AOT executable or pinned build receipt changed.');
    }
  }

  Future<Map<String, dynamic>> proofAfterRun() async {
    await checkUnchanged();
    if (_reportedIdentity == null) throw const FormatException('AOT identity was not verified.');
    return {
      'kind': 'dart-aot',
      'executable': executable,
      'executableSha256': executableSha256,
      'binarySha256AfterRun': executableSha256,
      'buildId': buildId,
      'buildReceiptPath': receiptPath,
      'buildReceiptSha256': receiptSha256,
      'sourceConfigIdentityMatched': true,
      'buildInputs': inputs,
      'compileCommand': compileCommand,
      'identity': _reportedIdentity,
    };
  }
}

const _licenseText =
    'Original deterministic volume QA atlases. Redistribution permitted for local certification fixtures.';
const _diskBudget = 1536 * 1024 * 1024;

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Expected a JSON object.');
  }
  return Map<String, dynamic>.from(value);
}

Future<String> _hash(File file) async =>
    (await sha256.bind(file.openRead()).first).toString();
Future<void> _json(File file, Object? value) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
}

Future<Map<String, dynamic>> _readJson(File file) async =>
    _object(jsonDecode(await file.readAsString()));

Map<String, int> planEntryLayout(int zipEntries) {
  if (zipEntries < 4 || zipEntries > 20000)
    throw const FormatException(
      'A nonempty entry campaign needs 4..20000 ZIP entries.',
    );
  final images = zipEntries - 3;
  return {
    'zipEntries': zipEntries,
    'imageFiles': images,
    'resources': (images + 1) ~/ 2,
    'licenseFiles': 1,
  };
}

int pngStoredByteLength(int width, int height) {
  if (width < 1 || width > 8192 || height < 1 || height > 8192)
    throw const FormatException('PNG dimensions exceed the signed bounds.');
  return 51 + height * (4 * width + 18);
}

final _crcTable = List<int>.generate(256, (index) {
  var value = index;
  for (var bit = 0; bit < 8; bit++) {
    value = value & 1 == 0 ? value >> 1 : (value >> 1) ^ 0xedb88320;
  }
  return value;
});

int _crc(List<int> bytes, [int initial = 0xffffffff]) {
  var value = initial;
  for (final byte in bytes) {
    value = _crcTable[(value ^ byte) & 255] ^ (value >> 8);
  }
  return value;
}

Future<Map<String, dynamic>> writeOriginalPng(
  File file,
  int width,
  int height,
  int seed,
) async {
  final expected = pngStoredByteLength(width, height);
  await file.parent.create(recursive: true);
  final output = await file.open(mode: FileMode.writeOnly);
  Future<void> chunk(String kind, Uint8List data) async {
    final type = ascii.encode(kind);
    final frame = Uint8List(data.length + 12);
    final view = ByteData.sublistView(frame);
    view.setUint32(0, data.length);
    frame.setRange(4, 8, type);
    frame.setRange(8, 8 + data.length, data);
    view.setUint32(
      frame.length - 4,
      (_crc(data, _crc(type)) ^ 0xffffffff) & 0xffffffff,
    );
    await output.writeFrom(frame);
  }

  try {
    await output.writeFrom([137, 80, 78, 71, 13, 10, 26, 10]);
    final header = ByteData(13)
      ..setUint32(0, width)
      ..setUint32(4, height)
      ..setUint8(8, 8)
      ..setUint8(9, 6);
    await chunk('IHDR', header.buffer.asUint8List());
    var adlerA = 1, adlerB = 0;
    for (var y = 0; y < height; y++) {
      final row = Uint8List(1 + width * 4);
      for (var x = 0; x < width; x++) {
        final offset = 1 + x * 4;
        row[offset] = (x + seed) & 255;
        row[offset + 1] = (y + (seed >> 8)) & 255;
        row[offset + 2] = (x ^ y ^ (seed >> 16)) & 255;
        row[offset + 3] = 255;
      }
      for (final byte in row) {
        adlerA += byte;
        adlerB += adlerA;
      }
      adlerA %= 65521;
      adlerB %= 65521;
      final prefix = y == 0 ? 2 : 0;
      final payload = Uint8List(
        prefix + 5 + row.length + (y == height - 1 ? 4 : 0),
      );
      if (prefix != 0) payload.setRange(0, 2, [0x78, 0x01]);
      payload[prefix] = y == height - 1 ? 1 : 0;
      final fields = ByteData.sublistView(payload);
      fields.setUint16(prefix + 1, row.length, Endian.little);
      fields.setUint16(prefix + 3, row.length ^ 0xffff, Endian.little);
      payload.setRange(prefix + 5, prefix + 5 + row.length, row);
      if (y == height - 1)
        fields.setUint32(payload.length - 4, (adlerB << 16) | adlerA);
      await chunk('IDAT', payload);
    }
    await chunk('IEND', Uint8List(0));
    await output.flush();
  } finally {
    await output.close();
  }
  _require(
    await file.length() == expected,
    'PNG stored-scanline formula differs from actual bytes.',
  );
  return {
    'path': file.path,
    'width': width,
    'height': height,
    'byteLength': expected,
    'rawSha256': await _hash(file),
  };
}

ResourcePackMetadata _metadata(String campaign) => ResourcePackMetadata(
  id: 'p12.volume.$campaign',
  version: '1.0.0',
  name: 'Original $campaign volume fixtures',
  description: '',
  universeId: 'p12.original',
  authors: ['Original volume fixtures'],
  provenance: 'Original deterministic RGBA scanlines',
);

ResourcePackBuildSource _licenseSource() {
  final bytes = utf8.encode(_licenseText);
  final hash = sha256.convert(bytes).toString();
  return ResourcePackBuildSource(
    path: 'licenses/$hash.txt',
    byteLength: bytes.length,
    rawSha256: hash,
    mediaType: 'text/plain',
    openRead: () => Stream.value(bytes),
  );
}

Future<ResourcePackExportProjection> _project(
  List<Map<String, dynamic>> images, {
  bool collections = false,
}) async {
  final tilesets = <ProjectTilesetEntry>[];
  final files = <NativeResourcePackFile>[];
  for (var i = 0; i < images.length; i++) {
    final image = images[i];
    files.add(
      NativeResourcePackFile(
        id: 'image-$i',
        logicalPath: 'assets/image-$i.png',
        byteLength: image['byteLength'] as int,
        rawSha256: image['rawSha256'] as String,
        mediaType: 'image/png',
        openRead: () => File(image['path'] as String).openRead(),
      ),
    );
  }
  for (var index = 0; index < images.length; index += collections ? 2 : 1) {
    final first = images[index];
    final source = collections
        ? ProjectTilesetSource.imageCollection(
            pages: [
              for (var j = index; j < min(index + 2, images.length); j++)
                ProjectImageCollectionPage(
                  id: 'page-${j - index}',
                  assetId: 'image-$j',
                  pixelWidth: 16,
                  pixelHeight: 16,
                ),
            ],
            tileDefinitions: [
              for (var j = index; j < min(index + 2, images.length); j++)
                ProjectImageCollectionTileDefinition(
                  tileId: j - index,
                  pageId: 'page-${j - index}',
                  sourceRect: ProjectTilesetPixelRect(
                    x: 0,
                    y: 0,
                    width: 16,
                    height: 16,
                  ),
                ),
            ],
          )
        : ProjectTilesetSource.regularAtlas(
            assetId: 'image-$index',
            pixelWidth: first['width'] as int,
            pixelHeight: first['height'] as int,
            tileWidth: 16,
            tileHeight: 16,
          );
    tilesets.add(
      ProjectTilesetEntry(
        id: 'atlas-${collections ? index ~/ 2 : index}',
        name: 'Original atlas $index',
        relativePath: 'assets/image-$index.png',
        source: source,
      ),
    );
  }
  return const ResourcePackProjectionBuilder().project(
    manifest: ProjectManifest(
      name: 'Original volume fixtures',
      maps: [],
      tilesets: tilesets,
      settings: ProjectSettings(tileWidth: 16, tileHeight: 16),
    ),
    roots: [
      for (final tile in tilesets)
        NativeResourcePackRef(kind: ResourcePackKind.tileset, id: tile.id),
    ],
    files: files,
    author: 'Original volume fixtures',
    sourceRevision: 'original-volume-v1',
    localLicenses: [_licenseSource()],
  );
}

Map<String, dynamic> _projectionSizes(
  ResourcePackExportProjection projection,
  String campaign,
) {
  final catalog = CanonicalJson.encodeUtf8(projection.catalog.toJson());
  final inventory = projection.sources
      .map((source) => source.inventory)
      .toList();
  final descriptor = ResourcePackInventoryFile(
    path: 'catalog.json',
    byteLength: catalog.length,
    rawSha256: sha256.convert(catalog).toString(),
    mediaType: 'application/json',
  );
  final manifest = ResourcePackManifest(
    pack: _metadata(campaign),
    compatibility: ResourcePackCompatibility(
      resourceLibraryCatalogVersion:
          ResourceLibraryCatalog.currentFormatVersion,
      smartTileCatalogVersion: ProjectSmartTileCatalog.currentFormatVersion,
      borderCatalogVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      requiredCapabilities: ResourcePackCapabilities.requiredFor(
        projection.catalog,
        inventory,
      ),
      tileWidth: 16,
      tileHeight: 16,
    ),
    content: ResourcePackContent(
      catalog: descriptor,
      files: inventory,
      treeSha256: resourcePackTreeSha256(descriptor, inventory),
    ),
  );
  final manifestBytes = ResourcePackManifestCodec().encodeUtf8(manifest).length;
  final sources = inventory.fold<int>(0, (sum, file) => sum + file.byteLength);
  var archive = 22;
  for (final entry in [
    for (final file in inventory) (file.path, file.byteLength),
    ('catalog.json', catalog.length),
    ('manifest.json', manifestBytes),
  ]) {
    archive += 76 + 2 * utf8.encode(entry.$1).length + entry.$2;
  }
  final shape = _jsonShape(jsonDecode(utf8.decode(catalog)));
  return {
    'sourceBytes': sources,
    'catalogBytes': catalog.length,
    'manifestBytes': manifestBytes,
    'usefulPayloadBytes': sources + catalog.length,
    'archiveBytes': archive,
    'zipEntries': inventory.length + 2,
    'catalogJsonNodes': shape.$1,
    'catalogJsonDepth': shape.$2,
  };
}

(int, int) _jsonShape(Object? value, [int depth = 0]) {
  var nodes = 1, maximum = depth;
  final children = value is Map
      ? value.values
      : value is List
      ? value
      : const [];
  for (final child in children) {
    final shape = _jsonShape(child, depth + 1);
    nodes += shape.$1;
    maximum = max(maximum, shape.$2);
  }
  return (nodes, maximum);
}

Future<Map<String, dynamic>> planCapacity(
  int payloadBytes,
  int archiveBytes, {
  int width = 4096,
  int fullHeight = 4096,
}) async {
  const policy = ResourcePackSecurityPolicy();
  if (payloadBytes < 1 ||
      payloadBytes > policy.maxTotalPayloadBytes ||
      archiveBytes < 1 ||
      archiveBytes > policy.maxArchiveBytes)
    throw const FormatException('Capacity cannot raise the signed quotas.');
  Future<Map<String, dynamic>> measure(int fullCount, int height) async {
    final images = [
      for (var i = 0; i <= fullCount; i++)
        {
          'path': '',
          'width': width,
          'height': i == fullCount ? height : fullHeight,
          'byteLength': pngStoredByteLength(
            width,
            i == fullCount ? height : fullHeight,
          ),
          'rawSha256': sha256
              .convert(utf8.encode('planned-image-$i'))
              .toString(),
        },
    ];
    return {
      ..._projectionSizes(await _project(images), 'capacity'),
      'fullImages': fullCount,
      'lastHeight': height,
      'width': width,
      'fullHeight': fullHeight,
    };
  }

  for (
    var full = min(7, payloadBytes ~/ pngStoredByteLength(width, fullHeight));
    full >= 0;
    full--
  ) {
    var low = 16, high = fullHeight;
    Map<String, dynamic>? accepted;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      final candidate = await measure(full, middle);
      if ((candidate['usefulPayloadBytes'] as int) <= payloadBytes &&
          (candidate['archiveBytes'] as int) <= archiveBytes) {
        accepted = candidate;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    if (accepted != null) {
      final height = accepted['lastHeight'] as int;
      final next = height < fullHeight ? await measure(full, height + 1) : null;
      return {
        ...accepted,
        'payloadLimitBytes': payloadBytes,
        'archiveLimitBytes': archiveBytes,
        'unusedPayloadBytes':
            payloadBytes - (accepted['usefulPayloadBytes'] as int),
        'nextRow': next,
        'limitingConstraint': next == null
            ? 'configured_atlas_height'
            : (next['usefulPayloadBytes'] as int) > payloadBytes
            ? 'useful_payload_bytes'
            : 'archive_bytes',
        'formula': '51 + height * (4 * width + 18)',
      };
    }
  }
  throw const FormatException(
    'No valid original atlas plus canonical catalogue fits the requested capacity.',
  );
}

Future<void> _phase(String name, [Map<String, Object?> data = const {}]) async {
  stdout.writeln(
    jsonEncode({
      'event': 'phase',
      'phase': name,
      'pid': pid,
      'atUtc': DateTime.now().toUtc().toIso8601String(),
      ...data,
    }),
  );
  await stdout.flush();
}

Future<Map<String, String>> _fingerprints(Directory root) async {
  final result = <String, String>{};
  if (!await root.exists()) return result;
  final files = await root
      .list(recursive: true, followLinks: false)
      .where((entry) => entry is File)
      .cast<File>()
      .toList();
  files.sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    result[p.relative(file.path, from: root.path)] = await _hash(file);
  }
  return result;
}

Future<int> _diskBytes(Directory root) async {
  var total = 0;
  if (await root.exists()) {
    await for (final entry in root.list(recursive: true, followLinks: false)) {
      if (entry is File) total += await entry.length();
    }
  }
  return total;
}

Future<void> _ownedRequest(Map<String, dynamic> request) async {
  final root = Directory(request['root'] as String);
  _require(
    await root.resolveSymbolicLinks() == root.path,
    'Campaign root must be canonical.',
  );
  final marker = await _readJson(File(p.join(root.path, 'owner.json')));
  _require(
    marker['nonce'] == request['nonce'] &&
        marker['kind'] == 'resource_pack_volume',
    'Campaign ownership marker differs.',
  );
  _require(
    p.isWithin(root.path, request['temporaryDirectory'] as String),
    'Worker temporary directory is not owned by the campaign.',
  );
  _require(
    await Directory.systemTemp.resolveSymbolicLinks() ==
        await Directory(request['temporaryDirectory'] as String)
            .resolveSymbolicLinks(),
    'TMPDIR must be the private toolchain directory.',
  );
}

Future<void> _removeOwned(Map<String, dynamic> request, String relative) async {
  await _ownedRequest(request);
  final root = request['root'] as String;
  final target = p.normalize(p.join(root, relative));
  _require(p.isWithin(root, target), 'Removal leaves the owned campaign.');
  for (var current = target; current != root; current = p.dirname(current)) {
    _require(
      await FileSystemEntity.type(current, followLinks: false) !=
          FileSystemEntityType.link,
      'Refusing a symlink in a removable fixture path.',
    );
  }
  final type = await FileSystemEntity.type(target, followLinks: false);
  if (type == FileSystemEntityType.directory)
    await Directory(target).delete(recursive: true);
  if (type == FileSystemEntityType.file) await File(target).delete();
}

Future<Map<String, dynamic>> _generate(Map<String, dynamic> request) async {
  await _ownedRequest(request);
  final root = request['root'] as String;
  final requested = _object(request['requested']);
  final campaign = requested['campaign'] as String;
  await _phase('generation');
  final fixtures = await Directory(p.join(root, 'fixtures')).create();
  final images = <Map<String, dynamic>>[];
  Map<String, dynamic>? plan;
  if (campaign == 'capacity')
    plan = await planCapacity(
      requested['payloadBytes'] as int,
      requested['archiveBytes'] as int,
    );
  final imageCount = campaign == 'resources'
      ? requested['resources'] as int
      : campaign == 'entries'
      ? planEntryLayout(requested['zipEntries'] as int)['imageFiles']!
      : (plan!['fullImages'] as int) + 1;
  for (var index = 0; index < imageCount; index++) {
    final width = campaign == 'capacity' ? plan!['width'] as int : 16;
    final height = campaign == 'capacity'
        ? index == imageCount - 1
              ? plan!['lastHeight'] as int
              : plan!['fullHeight'] as int
        : 16;
    images.add(
      await writeOriginalPng(
        File(p.join(fixtures.path, 'pixels', 'image-$index.png')),
        width,
        height,
        index,
      ),
    );
  }
  _require(
    images.map((image) => image['rawSha256']).toSet().length == images.length,
    'Original PNGs unexpectedly deduplicate.',
  );
  final license = await File(p.join(fixtures.path, 'LICENSE'))
      .writeAsString(_licenseText);
  final result = <String, dynamic>{
    'campaign': campaign,
    'images': images,
    'licensePath': license.path,
    'licenseRawSha256': await _hash(license),
    'imageBytes': images.fold<int>(
      0,
      (n, image) => n + (image['byteLength'] as int),
    ),
    'pngEncoding': 'RGBA8 filter0; legal zlib stored block per scanline; IHDR/IDAT/IEND only',
    'pngFormula': '51 + height*(4*width+18)',
    'plan': plan,
  };
  if (campaign == 'resources') {
    final source = await Directory(p.join(fixtures.path, 'source-a')).create();
    final records = <AssetRecord>[];
    final tilesets = <ProjectTilesetEntry>[];
    for (var index = 0; index < images.length; index++) {
      final input = File(images[index]['path'] as String);
      final logical = 'assets/image-$index.png';
      final file = File(p.join(source.path, logical));
      await file.parent.create(recursive: true);
      await input.copy(file.path);
      final artifact = ContentArtifactRef.fromBytes(
        await input.readAsBytes(),
        mediaType: 'image/png',
      );
      final blob = File(p.join(source.path, assetBlobStorageKey(artifact)));
      await blob.parent.create(recursive: true);
      await input.copy(blob.path);
      records.add(
        AssetRecord(
          id: 'image-$index',
          logicalPath: logical,
          artifact: artifact,
        ),
      );
      tilesets.add(
        ProjectTilesetEntry(
          id: 'atlas-$index',
          name: 'Original atlas $index',
          relativePath: logical,
          source: ProjectTilesetSource.regularAtlas(
            assetId: 'image-$index',
            pixelWidth: 16,
            pixelHeight: 16,
            tileWidth: 16,
            tileHeight: 16,
          ),
        ),
      );
    }
    final manifest = ProjectManifest(
      name: 'Original volume source',
      maps: [],
      tilesets: tilesets,
      settings: ProjectSettings(tileWidth: 16, tileHeight: 16),
    );
    await _json(File(p.join(source.path, 'project.json')), manifest.toJson());
    await _json(
      File(p.join(source.path, assetCatalogStorageKey)),
      AssetCatalog(records: records).toJson(),
    );
    result['sourceProjectPath'] = source.path;
    result['sourceFingerprints'] = await _fingerprints(source);
    result['resourceCount'] = tilesets.length;
  } else {
    final projection = await _project(
      images,
      collections: campaign == 'entries',
    );
    final sizes = _projectionSizes(projection, campaign);
    _require(
      (sizes['usefulPayloadBytes'] as int) <=
          (requested['payloadBytes'] as int),
      'Generated catalogue plus sources exceed useful payload cap.',
    );
    _require(
      (sizes['archiveBytes'] as int) <= (requested['archiveBytes'] as int),
      'Generated catalogue plus sources exceed ZIP cap.',
    );
    if (campaign == 'entries')
      _require(
        sizes['zipEntries'] == requested['zipEntries'],
        'The generated entry count differs.',
      );
    if (plan != null)
      _require(
        sizes['catalogBytes'] == plan['catalogBytes'] &&
            sizes['usefulPayloadBytes'] == plan['usefulPayloadBytes'],
        'Actual canonical catalogue differs from reserved capacity.',
      );
    result['sizes'] = sizes;
    result['resourceCount'] = projection.catalog.tilesets.length;
    result['graph'] = {
      'files': projection.catalog.files.length,
      'resources': ResourcePackDependencyGraph.fromCatalog(projection.catalog)
          .validateAll()
          .resources
          .length,
    };
  }
  final bytes = await _diskBytes(fixtures);
  _require(
    bytes + (requested['archiveBytes'] as int) < _diskBudget,
    'Conservative fixture plus archive reservation exceeds private disk budget.',
  );
  result['fixtureBytesAfterGeneration'] = bytes;
  result['diskBudgetBytes'] = _diskBudget;
  await _json(File(p.join(root, 'generation.json')), result);
  return result;
}

const _byteCounterNames = {
  AuthoringPerformanceCounterName.resourcePackAuthorizeReadBytes,
  AuthoringPerformanceCounterName.resourcePackStageSourceReadBytes,
  AuthoringPerformanceCounterName
      .resourcePackStagePrivateCompletedWriteInputBytes,
  AuthoringPerformanceCounterName.resourcePackPostCopyVerifyReadBytes,
  AuthoringPerformanceCounterName.resourcePackStageVerifyReadBytes,
  AuthoringPerformanceCounterName.resourcePackConsumerReadAtReturnedBytes,
  AuthoringPerformanceCounterName.resourcePackWorkerVerifyReadBytes,
  AuthoringPerformanceCounterName.resourcePackWorkerConsumerReadAtReturnedBytes,
  AuthoringPerformanceCounterName.gatewayResourceReadBytes,
  AuthoringPerformanceCounterName.gatewayVerificationReadBytes,
  AuthoringPerformanceCounterName.gatewayStagedPayloadCompletedWriteInputBytes,
  AuthoringPerformanceCounterName.gatewayDescriptorCompletedWriteInputBytes,
  AuthoringPerformanceCounterName.gatewayJournalCompletedWriteInputBytes,
  AuthoringPerformanceCounterName.snapshotReaderReturnedBytes,
  AuthoringPerformanceCounterName.snapshotStreamDeliveredBytes,
  AuthoringPerformanceCounterName.harnessArchiveReadBytes,
  AuthoringPerformanceCounterName.harnessArchiveCompletedWriteInputBytes,
};
const _operationCounterNames = {
  AuthoringPerformanceCounterName.filesystemRead,
  AuthoringPerformanceCounterName.filesystemWrite,
  AuthoringPerformanceCounterName.filesystemMetadata,
  AuthoringPerformanceCounterName.jsonEncode,
  AuthoringPerformanceCounterName.jsonDecode,
  AuthoringPerformanceCounterName.base64Encode,
  AuthoringPerformanceCounterName.base64Decode,
  AuthoringPerformanceCounterName.journalCompletedWrites,
};
const _incompleteWorkerCounter = AuthoringPerformanceCounterName
    .resourcePackWorkerCoverageIncompleteOperations;
const _ioGaps = [
  'Journal and descriptor readAsString byte counts are unavailable.',
  'History/blob/audit/idempotency and private capture stores are outside these boundaries.',
  'Decode/copy heaps, global I/O and physical device I/O are not observed.',
  'Harness fingerprints, disk inventory, file hashing and fixture-generator I/O are outside these scoped counters.',
  'Project reader counts successful returned buffers and delivered chunks; bytes from failed readBytes calls are unavailable.',
  'Phase deltas describe intervals between worker events, and get timings describe successful awaited responses rather than UI responsiveness.',
  'Failed worker prefix aggregates are unavailable and marked incomplete; completed write inputs do not prove flush or durability.',
];

final class ResourcePackVolumeObserver implements AuthoringPerformanceObserver {
  final counters = <String, int>{};
  final _phases = <Map<String, dynamic>>[];
  final _polls = <String, Map<String, dynamic>>{};
  Map<String, int> _phaseStart = {};
  String? _phaseName = 'startup';
  int? _maximumArchiveReadRequest;
  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
  @override
  void incrementCounter(String name, {int by = 1}) {
    counters.update(name, (value) => value + by, ifAbsent: () => by);
  }

  Future<void> phase(
    String name, [
    Map<String, Object?> data = const {},
  ]) async {
    _finishPhase();
    _require(
      _phases.length < 128,
      'Phase observations exceeded their fixed harness bound.',
    );
    _phaseName = name;
    _phaseStart = Map.of(counters);
    await _phase(name, data);
  }

  void _finishPhase() {
    final name = _phaseName;
    if (name == null) return;
    final delta = <String, int>{
      for (final e in counters.entries)
        if (e.value != (_phaseStart[e.key] ?? 0))
          e.key: e.value - (_phaseStart[e.key] ?? 0),
    };
    _phases.add({
      'phase': name,
      'byteCounters': {
        for (final e in delta.entries)
          if (_byteCounterNames.contains(e.key)) e.key: e.value,
      },
      'operationCounters': {
        for (final e in delta.entries)
          if (_operationCounterNames.contains(e.key)) e.key: e.value,
      },
      'incompleteWorkerOperations': delta[_incompleteWorkerCounter] ?? 0,
    });
    _phaseName = null;
  }

  void recordPoll(String stage, int elapsedMicroseconds) {
    _require(
      elapsedMicroseconds >= 0 &&
          (_polls.containsKey(stage) || _polls.length < 64),
      'Poll observations exceeded their fixed harness bound.',
    );
    final entry = _polls.putIfAbsent(
      stage,
      () => {
        'stage': stage,
        'count': 0,
        'totalMicroseconds': 0,
        'maxMicroseconds': 0,
      },
    );
    entry['count'] = (entry['count'] as int) + 1;
    entry['totalMicroseconds'] =
        (entry['totalMicroseconds'] as int) + elapsedMicroseconds;
    entry['maxMicroseconds'] = max(
      entry['maxMicroseconds'] as int,
      elapsedMicroseconds,
    );
  }

  void recordArchiveRead(int requested, int returned) {
    if (requested > 0)
      _maximumArchiveReadRequest = max(
        _maximumArchiveReadRequest ?? 0,
        requested,
      );
    if (returned > 0)
      incrementCounter(
        AuthoringPerformanceCounterName.harnessArchiveReadBytes,
        by: returned,
      );
  }

  Map<String, dynamic> metrics() {
    _finishPhase();
    final incomplete = counters[_incompleteWorkerCounter] ?? 0;
    return {
      'authoringOperationCounters': {
        for (final e in counters.entries)
          if (_operationCounterNames.contains(e.key)) e.key: e.value,
      },
      'counterUnits': 'operations',
      'ioByteCoverage': 'unavailable',
      'maxBytesInFlight': null,
      'scopedIo': {
        'coverage': 'partial',
        'byteUnit': 'bytes',
        'byteCounters': {
          for (final e in counters.entries)
            if (_byteCounterNames.contains(e.key)) e.key: e.value,
        },
        'globalReadBytes': null,
        'globalWriteBytes': null,
        'unobservedBoundaries': {
          'io.gateway.journal.readBytes': null,
          'io.gateway.descriptor.readBytes': null,
        },
        'incompleteWorkerOperations': incomplete,
        'workerAggregateCoverage': incomplete == 0
            ? 'successful_calls_only'
            : 'incomplete',
        'maxArchiveReadAtRequestBytes': _maximumArchiveReadRequest,
        'journalWriteOperationCount':
            counters[AuthoringPerformanceCounterName.journalCompletedWrites],
        'phaseDeltas': [
          for (final phase in _phases) {...phase},
        ],
        'pollTimingUnit': 'microseconds',
        'pollResponses': [
          for (final poll in _polls.values) {...poll},
        ],
        'gaps': _ioGaps,
      },
    };
  }
}

final class ResourcePackVolumeProjectFileReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceIdentityReader,
        ProjectSnapshotCacheIdentityReader,
        ProjectDirectoryReader,
        ProjectResourceProbeReader {
  ResourcePackVolumeProjectFileReader(this.observer);
  final AuthoringPerformanceObserver observer;
  final LocalProjectFileReader _reader = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      _reader.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) async {
    final bytes = await _reader.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
    if (bytes.isNotEmpty)
      observer.incrementCounter(
        AuthoringPerformanceCounterName.snapshotReaderReturnedBytes,
        by: bytes.length,
      );
    return bytes;
  }

  @override
  bool get supportsStreamingResources => _reader.supportsStreamingResources;
  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) => _reader
      .openRead(projectRoot: projectRoot, relativePath: relativePath)
      .map((chunk) {
        if (chunk.isNotEmpty)
          observer.incrementCounter(
            AuthoringPerformanceCounterName.snapshotStreamDeliveredBytes,
            by: chunk.length,
          );
        return chunk;
      });
  @override
  Future<ProjectResourceIdentity?> readIdentity({
    required String projectRoot,
    required String relativePath,
  }) => _reader.readIdentity(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => _reader.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Future<List<String>> listFiles({
    required String projectRoot,
    required String relativeDirectory,
  }) => _reader.listFiles(
    projectRoot: projectRoot,
    relativeDirectory: relativeDirectory,
  );
}

final class _Session {
  _Session(this.root, this.campaignRoot, this.observer);
  final Directory root;
  final String campaignRoot;
  final ResourcePackVolumeObserver observer;
  late WorkspaceHandleStore handles;
  late ProjectSnapshotLoader loader;
  late LocalMapAuthoringMutationApi mutations;
  late LocalResourcePackTransferApi packs;
  late OpenedProject opened;
  bool active = false;
  Future<void> open() async {
    final reader = ResourcePackVolumeProjectFileReader(observer);
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    handles = WorkspaceHandleStore();
    loader = ProjectSnapshotLoader(handles: handles);
    opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(root.path);
    mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: loader,
      resourcePackSourceRoots: [campaignRoot],
      performanceObserver: observer,
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    packs = LocalResourcePackTransferApi(
      mutations: mutations,
      snapshotLoader: loader,
    );
    active = true;
  }

  Future<void> close() async {
    if (!active) return;
    await packs.closeTransferWorkspace(opened.workspaceHandle);
    await mutations.detachWorkspace(opened.workspaceHandle);
    handles.closeWorkspace(opened.workspaceHandle);
    active = false;
  }

  Future<ProjectSnapshot> snapshot() => loader.load(opened.projectHandle);
  Future<Map<String, Object?>> call(String verb, Map<String, Object?> input) =>
      packs.transfer(opened.projectHandle, verb: verb, input: input);
  Future<Map<String, dynamic>> job(
    String stage,
    String verb,
    Map<String, Object?> input,
  ) async {
    await observer.phase(stage);
    final started = await call(verb, input);
    final deadline = DateTime.now().add(const Duration(minutes: 10));
    while (DateTime.now().isBefore(deadline)) {
      final watch = Stopwatch()..start();
      final state = await call('get', {'jobId': started['jobId']});
      watch.stop();
      observer.recordPoll(stage, watch.elapsedMicroseconds);
      final snapshot = _object(state['snapshot']);
      if (['succeeded', 'failed', 'cancelled'].contains(snapshot['state'])) {
        stdout.writeln(
          jsonEncode({
            'event': 'job',
            'stage': stage,
            'jobId': started['jobId'],
            'state': snapshot['state'],
            'errorCode': snapshot['errorCode'],
          }),
        );
        _require(
          snapshot['state'] == 'succeeded',
          'Canonical job failed: ${jsonEncode(state)}',
        );
        return _object(state['result']);
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw TimeoutException(
      'Canonical job exceeded the explicit 600-second volume harness wait budget.',
    );
  }
}

Future<void> _emptyProject(Directory root) async {
  await Directory(p.join(root.path, 'assets')).create(recursive: true);
  await _json(
    File(p.join(root.path, 'project.json')),
    ProjectManifest(
      name: 'Volume receiver',
      maps: [],
      tilesets: [],
      settings: ProjectSettings(tileWidth: 16, tileHeight: 16),
    ).toJson(),
  );
  await _json(
    File(p.join(root.path, assetCatalogStorageKey)),
    AssetCatalog().toJson(),
  );
}

Future<Map<String, dynamic>> _business(_Session session) async {
  final snapshot = await session.snapshot();
  final catalog = AssetCatalog.fromJson(
    _object(
      jsonDecode(
        utf8.decode(snapshot.findResourceBytes(assetCatalogResourceIdentity)!),
      ),
    ),
  );
  final images = <String, String>{};
  for (final record in catalog.records.where(
    (record) => record.artifact.mediaType == 'image/png',
  )) {
    images[record.logicalPath] = await _hash(
      File(p.join(session.root.path, record.logicalPath)),
    );
  }
  return {
    'manifest': snapshot.manifest.toJson(),
    'assetCatalog': catalog.toJson(),
    'images': images,
  };
}

Future<Map<String, dynamic>> _export(
  _Session session,
  String stage,
  int expected,
  File target,
  ResourcePackSecurityPolicy policy, {
  List<String> licenses = const [],
}) async {
  final selection = await session.call('selection.create', {'mode': 'native'});
  final selected = await session.call('selection.select_filtered', {
    'selectionHandle': selection['selectionHandle'],
    'revision': selection['revision'],
    'filter': {'kind': 'tileset'},
  });
  _require(
    selected['selectedCount'] == expected,
    'Native selected resource count differs.',
  );
  final prepared = await session.job('$stage.prepare', 'prepare', {
    'selectionHandle': selected['selectionHandle'],
    'revision': selected['revision'],
    'expectedRevision': selection['sourceRevision'],
    'metadata': _metadata(stage.toLowerCase()).toJson(),
    'author': 'Original volume fixtures',
    'licenseHandles': licenses,
  });
  for (final handle in licenses) {
    await session.call('release', {'handle': handle});
  }
  final exported = await session.job('$stage.build', 'export', {
    'preparedExportHandle': prepared['preparedExportHandle'],
    'acknowledgeOrganizationRemoval': true,
  });
  _require(
    (exported['byteLength'] as int) <= policy.maxArchiveBytes,
    'Canonical export exceeds requested archive cap.',
  );
  await session.call('release', {'handle': prepared['preparedExportHandle']});
  final sink = ResourcePackVolumeDiskSink(target.path, session.observer);
  try {
    final length = exported['byteLength'] as int;
    for (var offset = 0; offset < length;) {
      final requested = min(64 * 1024, length - offset);
      final chunk = await session.call('read_payload', {
        'payloadRef': exported['payloadRef'],
        'offset': offset,
        'length': requested,
      });
      final bytes = base64Decode(chunk['bytesBase64'] as String);
      _require(
        bytes.length == requested,
        'Canonical payload read returned another chunk length.',
      );
      await sink.write(bytes);
      offset += bytes.length;
    }
    await sink.finish();
  } catch (_) {
    await sink.abort();
    rethrow;
  }
  _require(
    await _hash(target) == exported['rawSha256'],
    'Copied export hash differs.',
  );
  await session.call('release', {'handle': exported['artifactHandle']});
  await session.call('release', {'handle': selected['selectionHandle']});
  await session.observer.phase('$stage.inspect');
  final inspection = _inspect(target, policy, session.observer);
  _require(
    inspection.resourceCount == expected &&
        inspection.archiveRawSha256 == exported['rawSha256'],
    'Official export inspection differs.',
  );
  return {
    'path': target.path,
    'byteLength': await target.length(),
    'rawSha256': exported['rawSha256'],
    'resourceCount': inspection.resourceCount,
    'fileCount': inspection.catalog.files.length,
    'catalogBytes': inspection.manifest.content.catalog.byteLength,
    'payloadBytes': inspection.payloadBytes,
    'sourceRevision': selection['sourceRevision'],
    'projectionFingerprint': prepared['projectionFingerprint'],
    'pngHashes':
        inspection.catalog.files
            .where((file) => file.mediaType == 'image/png')
            .map((file) => file.rawSha256)
            .toList()
          ..sort(),
  };
}

ResourcePackInspection _inspect(
  File file,
  ResourcePackSecurityPolicy policy, [
  ResourcePackVolumeObserver? observer,
]) {
  final source = ResourcePackVolumeDiskSource(file, observer);
  try {
    return ResourcePackInspector(policy: policy).inspectSourceSync(source);
  } finally {
    source.close();
  }
}

final class ResourcePackVolumeDiskSource implements RandomAccessPackageSource {
  ResourcePackVolumeDiskSource(File file, [this.observer])
    : handle = file.openSync(),
      length = file.lengthSync();
  final ResourcePackVolumeObserver? observer;
  final RandomAccessFile handle;
  @override
  final int length;
  @override
  Uint8List readAtSync(int offset, int count) {
    _require(
      count <= 1024 * 1024,
      'Inspector requested a chunk beyond signed policy.',
    );
    handle.setPositionSync(offset);
    final bytes = handle.readSync(count);
    observer?.recordArchiveRead(count, bytes.length);
    _require(bytes.length == count, 'Short archive disk read.');
    return bytes;
  }

  void close() => handle.closeSync();
}

final class ResourcePackVolumeDiskSink implements ResourcePackArchiveSink {
  ResourcePackVolumeDiskSink(this.path, [this.observer])
    : handle = File(path).openSync(mode: FileMode.writeOnly);
  final AuthoringPerformanceObserver? observer;
  final String path;
  final RandomAccessFile handle;
  bool closed = false, finished = false, aborted = false;
  @override
  Future<void> write(Uint8List chunk) async {
    await handle.writeFrom(chunk);
    if (chunk.isNotEmpty)
      observer?.incrementCounter(
        AuthoringPerformanceCounterName.harnessArchiveCompletedWriteInputBytes,
        by: chunk.length,
      );
  }

  @override
  Future<void> finish() async {
    await handle.flush();
    await handle.close();
    closed = true;
    finished = true;
  }

  @override
  Future<void> abort() async {
    if (!closed) await handle.close();
    closed = true;
    aborted = true;
    if (await File(path).exists()) await File(path).delete();
  }
}

bool _same(Object? a, Object? b) =>
    sha256.convert(CanonicalJson.encodeUtf8(a)).toString() ==
    sha256.convert(CanonicalJson.encodeUtf8(b)).toString();

Future<Map<String, dynamic>> _import(
  _Session session,
  File archive,
  String label,
) async {
  final staged = await session.job('$label.stage', 'stage', {
    'sourcePath': archive.path,
  });
  final inspected = await session.job('$label.inspect', 'inspect', {
    'archiveHandle': staged['archiveHandle'],
  });
  final selection = await session.call('selection.create', {
    'mode': 'archive',
    'inspectionHandle': inspected['inspectionHandle'],
  });
  final selected = await session.call('selection.select_filtered', {
    'selectionHandle': selection['selectionHandle'],
    'revision': selection['revision'],
    'filter': {'kind': 'tileset'},
  });
  final revision = (await session.snapshot()).revision;
  final prepared = await session.job('$label.prepare', 'prepare', {
    'selectionHandle': selected['selectionHandle'],
    'revision': selected['revision'],
    'expectedRevision': revision,
  });
  _require(
    prepared['status'] == 'ready' && prepared['conflictCount'] == 0,
    'Original fixture import is not ready.',
  );
  await session.observer.phase('$label.plan_confirm');
  final plan = await session.mutations.planMutation(
    session.opened.projectHandle,
    AuthoringRequest(
      requestId: label,
      actionId: 'resource_pack.import',
      actionVersion: 1,
      workspaceHandle: session.opened.workspaceHandle.value,
      expectedRevision: revision,
      idempotencyKey: label,
      dryRun: false,
      parameters: {'preparedImportHandle': prepared['preparedImportHandle']},
    ),
  );
  final confirmation = await session.mutations.confirmMutation(
    session.opened.projectHandle,
    planId: plan.planId,
  );
  final applied = await session.job('$label.apply', 'start_apply', {
    'planId': plan.planId,
    'operationId': label,
    'confirmationToken': confirmation.confirmationToken,
  });
  return {
    'inspection': inspected,
    'planId': plan.planId,
    'confirmationObtained': true,
    'receipt': applied['receipt'],
  };
}

Future<Map<String, dynamic>> _resourceJourney(
  Map<String, dynamic> request,
  Map<String, dynamic> generation,
  ResourcePackVolumeObserver observer,
) async {
  final root = request['root'] as String;
  final requested = _object(request['requested']);
  final count = requested['resources'] as int;
  final policy = ResourcePackSecurityPolicy(
    maxArchiveBytes: requested['archiveBytes'] as int,
  );
  final a = _Session(
    Directory(generation['sourceProjectPath'] as String),
    root,
    observer,
  );
  final bRoot = Directory(p.join(root, 'fixtures', 'receiver-b'));
  await _emptyProject(bRoot);
  var b = _Session(bRoot, root, observer);
  final artifacts = await Directory(p.join(root, 'artifacts')).create();
  final archiveA = File(p.join(artifacts.path, 'a.aveluneassets'));
  final archiveC = File(p.join(artifacts.path, 'c.aveluneassets'));
  final expectedImages = (generation['images'] as List)
      .map((image) => image['rawSha256'] as String)
      .toSet();
  final phases = <Map<String, dynamic>>[];
  try {
    await observer.phase('open_sessions');
    await a.open();
    await b.open();
    final initial = await _business(b);
    final initialFiles = await _fingerprints(bRoot);
    final initialRevision = (await b.snapshot()).revision;
    final licence = await a.job('exportA.license', 'stage_license', {
      'sourcePath': generation['licensePath'],
    });
    final exportedA = await _export(
      a,
      'exportA',
      count,
      archiveA,
      policy,
      licenses: [licence['licenseHandle'] as String],
    );
    final imported = await _import(b, archiveA, 'importB');
    final importReceipt = _object(imported['receipt']);
    final installed = await _business(b);
    final importedSnapshot = await b.snapshot();
    _require(
      importedSnapshot.manifest.tilesets.length == count &&
          _object(installed['images']).values
              .toSet()
              .containsAll(expectedImages),
      'Imported originals differ.',
    );
    phases.add({
      'phase': 'imported',
      'revision': importedSnapshot.revision,
      'resourceCount': importedSnapshot.manifest.tilesets.length,
      'businessSha256': sha256
          .convert(CanonicalJson.encodeUtf8(installed))
          .toString(),
      'receiptId': importReceipt['receiptId'],
    });
    final initialHandles = [
      b.opened.workspaceHandle.value,
      b.opened.projectHandle.value,
    ];
    await observer.phase('reopen_import');
    await b.close();
    b = _Session(bRoot, root, observer);
    await b.open();
    _require(
      b.opened.workspaceHandle.value != initialHandles[0] &&
          b.opened.projectHandle.value != initialHandles[1],
      'Reopen reused opaque handles.',
    );
    _require(
      _same(await _business(b), installed),
      'Imported business changed across fresh session.',
    );
    phases.add({
      'phase': 'reopened_import',
      'revision': (await b.snapshot()).revision,
      'projectHandle': b.opened.projectHandle.value,
      'workspaceHandle': b.opened.workspaceHandle.value,
    });
    final undo = await b.job('undo', 'start_history', {
      'operation': 'undo',
      'entryId': importReceipt['receiptId'],
      'expectedRevision': (await b.snapshot()).revision,
      'operationId': 'volume-undo',
    });
    await observer.phase('reopen_undo');
    await b.close();
    b = _Session(bRoot, root, observer);
    await b.open();
    final undone = await _business(b);
    _require(
      _same(undone, initial) && (await b.snapshot()).manifest.tilesets.isEmpty,
      'Undo did not restore initial business after reopen.',
    );
    final undoFiles = await _fingerprints(bRoot);
    final delta = <Map<String, dynamic>>[];
    for (final path in {
      ...initialFiles.keys,
      ...undoFiles.keys,
    }.toList()..sort()) {
      if (initialFiles[path] != undoFiles[path])
        delta.add({
          'path': path,
          'initialSha256': initialFiles[path],
          'undoSha256': undoFiles[path],
        });
    }
    _require(
      delta.every(
        (entry) => (entry['path'] as String).startsWith('.pokemap/authoring/'),
      ),
      'Undo left a business file delta outside its journals.',
    );
    phases.add({
      'phase': 'reopened_undo',
      'initialRevision': initialRevision,
      'revision': (await b.snapshot()).revision,
      'resourceCount': 0,
      'journalOnlyDelta': delta,
      'receiptId': _object(undo['receipt'])['receiptId'],
    });
    final redo = await b.job('redo', 'start_history', {
      'operation': 'redo',
      'entryId': importReceipt['receiptId'],
      'expectedRevision': (await b.snapshot()).revision,
      'operationId': 'volume-redo',
    });
    await observer.phase('retire_owned_source');
    final currentSource = await _fingerprints(a.root);
    final sourceBefore = _object(generation['sourceFingerprints']);
    _require(
      sourceBefore.entries.every(
        (entry) => currentSource[entry.key] == entry.value,
      ),
      'Original A bytes changed before retirement.',
    );
    await a.close();
    await b.close();
    final cache = p.relative(
      p.join(Directory.systemTemp.path, 'pokemap-authoring-projections'),
      from: root,
    );
    final cacheFiles = await _fingerprints(Directory(p.join(root, cache)));
    await _removeOwned(request, 'fixtures/source-a');
    await _removeOwned(request, 'fixtures/pixels');
    await _removeOwned(request, 'fixtures/LICENSE');
    await _removeOwned(request, 'artifacts/a.aveluneassets');
    await _removeOwned(request, cache);
    await observer.phase('reopen_redo');
    b = _Session(bRoot, root, observer);
    await b.open();
    final redone = await _business(b);
    _require(
      _same(redone, installed) &&
          (await b.snapshot()).manifest.tilesets.length == count,
      'Redo did not restore imported business after reopen.',
    );
    phases.add({
      'phase': 'reopened_redo',
      'revision': (await b.snapshot()).revision,
      'resourceCount': count,
      'receiptId': _object(redo['receipt'])['receiptId'],
      'projectHandle': b.opened.projectHandle.value,
      'workspaceHandle': b.opened.workspaceHandle.value,
    });
    final exportedC = await _export(b, 'exportC', count, archiveC, policy);
    final finalInspection = _inspect(archiveC, policy, observer);
    final finalHashes = finalInspection.catalog.files
        .where((file) => file.mediaType == 'image/png')
        .map((file) => file.rawSha256)
        .toSet();
    _require(
      finalHashes.length == count && finalHashes.containsAll(expectedImages),
      'Reexport original image hashes differ.',
    );
    _require(
      finalInspection.manifest.content.files.any(
        (file) =>
            file.path.startsWith('licenses/') &&
            file.rawSha256 == generation['licenseRawSha256'],
      ),
      'Inherited original licence disappeared.',
    );
    _require(
      _same(await _business(b), redone),
      'Export changed receiver business.',
    );
    _require(
      !await a.root.exists() &&
          !await archiveA.exists() &&
          !await Directory(p.join(root, 'fixtures', 'pixels')).exists(),
      'Original sources remain during C reexport.',
    );
    return {
      'campaign': 'resources',
      'importedResourceCount': count,
      'undoBusinessEqualsInitial': true,
      'redoBusinessEqualsImported': true,
      'exportedResourceCount': finalInspection.resourceCount,
      'originalImagesPreserved': true,
      'sourceAndArchiveARemovedBeforeExport': true,
      'businessFingerprints': {
        'initial': sha256.convert(CanonicalJson.encodeUtf8(initial)).toString(),
        'imported': sha256
            .convert(CanonicalJson.encodeUtf8(installed))
            .toString(),
        'afterUndo': sha256
            .convert(CanonicalJson.encodeUtf8(undone))
            .toString(),
        'afterRedo': sha256
            .convert(CanonicalJson.encodeUtf8(redone))
            .toString(),
        'afterExport': sha256
            .convert(CanonicalJson.encodeUtf8(await _business(b)))
            .toString(),
      },
      'inheritedLicenseRawSha256': generation['licenseRawSha256'],
      'sourceAOriginalFingerprints': sourceBefore,
      'originalImageHashes': finalHashes.toList()..sort(),
      'cacheFilesAfterClosesBeforeRemoval': cacheFiles.length,
      'exportA': exportedA,
      'exportC': exportedC,
      'history': phases,
      'reopening': 'New services/loaders/opaque handles in one fresh campaign worker; no OS/native restart claim',
      'requestedArchiveBytes': policy.maxArchiveBytes,
      'actualArchiveBytes': exportedC['byteLength'],
      'actualUsefulPayloadBytes': finalInspection.payloadBytes,
    };
  } finally {
    await observer.phase('close_sessions');
    await a.close();
    await b.close();
  }
}

Future<Map<String, dynamic>> _buildJourney(
  Map<String, dynamic> request,
  Map<String, dynamic> generation,
  ResourcePackVolumeObserver observer,
) async {
  final requested = _object(request['requested']);
  final campaign = requested['campaign'] as String;
  await observer.phase('projection');
  final projection = await _project(
    (generation['images'] as List).map(_object).toList(),
    collections: campaign == 'entries',
  );
  final sizes = _projectionSizes(projection, campaign);
  _require(
    _same(sizes, generation['sizes']),
    'Worker sizes differ from separate generator.',
  );
  final policy = ResourcePackSecurityPolicy(
    maxArchiveBytes: requested['archiveBytes'] as int,
    maxTotalPayloadBytes: requested['payloadBytes'] as int,
  );
  final archive = File(
    p.join(request['root'] as String, 'artifacts', '$campaign.aveluneassets'),
  );
  await archive.parent.create();
  final sink = ResourcePackVolumeDiskSink(archive.path, observer);
  await observer.phase('build');
  final built = await ResourcePackBuilder(policy: policy).build(
    metadata: _metadata(campaign),
    catalog: projection.catalog,
    tileWidth: 16,
    tileHeight: 16,
    sources: projection.sources,
    sink: sink,
  );
  _require(
    sink.finished &&
        !sink.aborted &&
        built.archiveBytes == sizes['archiveBytes'],
    'Archive differs from exact reserved ZIP size.',
  );
  await observer.phase('inspect');
  final inspection = _inspect(archive, policy, observer);
  _require(
    inspection.archiveRawSha256 == built.archiveRawSha256 &&
        inspection.payloadBytes == sizes['usefulPayloadBytes'],
    'Official inspection differs from planned useful bytes.',
  );
  _require(
    inspection.resourceCount == generation['resourceCount'],
    'Official resource count differs.',
  );
  if (campaign == 'entries')
    _require(
      sizes['zipEntries'] == requested['zipEntries'],
      'Actual ZIP entries differ.',
    );
  return {
    'campaign': campaign,
    'requested': requested,
    'actual': sizes,
    'resourceCount': inspection.resourceCount,
    'archive': {
      'path': archive.path,
      'byteLength': built.archiveBytes,
      'rawSha256': built.archiveRawSha256,
    },
    'officialInspectionAccepted': true,
    'limitingConstraint': campaign == 'entries'
        ? 'requested_zip_entries'
        : _object(generation['plan'])['limitingConstraint'],
    'plan': generation['plan'],
    'journeyScope': 'Build and official inspection only; resource import/history journey is a separate campaign',
  };
}

Future<void> _worker(Map<String, dynamic> request) async {
  await _ownedRequest(request);
  final root = request['root'] as String;
  final observer = ResourcePackVolumeObserver();
  Map<String, dynamic> result;
  try {
    await observer.phase('baseline', {'windowMs': 300});
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final generation = await _readJson(File(p.join(root, 'generation.json')));
    result = _object(request['requested'])['campaign'] == 'resources'
        ? await _resourceJourney(request, generation, observer)
        : await _buildJourney(request, generation, observer);
    final disk =
        await _diskBytes(Directory(p.join(root, 'fixtures'))) +
        await _diskBytes(Directory(p.join(root, 'artifacts'))) +
        await _diskBytes(
          Directory(
            p.join(Directory.systemTemp.path, 'pokemap-authoring-projections'),
          ),
        );
    _require(
      disk < _diskBudget,
      'Actual fixtures, artifacts and canonical cache exceed private disk budget.',
    );
    result['disk'] = {
      'logicalBytesAtFinish': disk,
      'budgetBytes': _diskBudget,
      'scope': 'Fixtures, archives and canonical cache; excludes toolchain kernels/logs; not a peak sample',
    };
    result['canonicalCacheFileCountAfterClose'] = (await _fingerprints(
      Directory(
        p.join(Directory.systemTemp.path, 'pokemap-authoring-projections'),
      ),
    )).length;
    result['sessionCloseAwaited'] = true;
    result['metrics'] = observer.metrics();
    await _json(File(p.join(root, 'worker-result.json')), {
      'status': 'completed',
      ...result,
    });
    await _phase('finished');
  } catch (error, stack) {
    await _json(File(p.join(root, 'worker-result.json')), {
      'status': 'failed',
      'error': error.toString(),
      'stack': stack.toString(),
    });
    rethrow;
  }
}

Future<Map<String, dynamic>> _identity(
  String toolPath,
  String configPath, {
  bool includeWorkerBuildSources = false,
}
) async {
  final repository = p.dirname(p.dirname(p.dirname(p.dirname(toolPath))));
  final sourceFiles = <String, String>{};
  for (final relative in [
    p.relative(toolPath, from: repository),
    'tools/pokemap_product_certification/pubspec.yaml',
    'packages/map_authoring/lib/src/api/local_map_authoring_mutation_api.dart',
    'packages/map_authoring/lib/src/api/local_resource_pack_transfer_api.dart',
    'packages/map_authoring/lib/src/domains/assets/resource_pack_import_preparer.dart',
    'packages/map_authoring/lib/src/domains/assets/resource_pack_native_attribution.dart',
    'packages/map_authoring/lib/src/domains/assets/resource_pack_projection.dart',
    'packages/map_authoring/lib/src/infrastructure/local_resource_pack_store.dart',
    'packages/map_authoring/lib/src/ports/file_backed_payload_store.dart',
    'packages/map_authoring/lib/src/transactions/local_transaction_file_gateway.dart',
    'packages/map_distribution/lib/src/resource_pack_builder.dart',
    'packages/map_distribution/lib/src/resource_pack_inspector.dart',
    'packages/map_distribution/lib/src/resource_pack_security_policy.dart',
    'packages/map_core/lib/src/models/resource_pack_installation_catalog.dart',
  ]) {
    sourceFiles[relative] = await _hash(File(p.join(repository, relative)));
  }
  if (includeWorkerBuildSources) {
    for (final package in ['map_core', 'map_authoring', 'map_distribution', 'map_gameplay']) {
      final pubspec = p.join('packages', package, 'pubspec.yaml');
      sourceFiles[pubspec] = await _hash(File(p.join(repository, pubspec)));
      await for (final entity in Directory(p.join(repository, 'packages', package, 'lib'))
          .list(recursive: true, followLinks: false)) {
        if (entity is Link) throw const FormatException('Worker build sources contain a symlink.');
        if (entity is File && entity.path.endsWith('.dart')) {
          sourceFiles[p.relative(entity.path, from: repository)] = await _hash(entity);
        }
      }
    }
  }
  final config = await _readJson(File(configPath));
  final productRoots = <String, String>{};
  for (final raw in config['packages'] as List) {
    final entry = _object(raw);
    if ([
      'map_core',
      'map_authoring',
      'map_distribution',
      'map_gameplay',
    ].contains(entry['name'])) {
      final resolved = File(configPath).uri
          .resolve(entry['rootUri'] as String)
          .toFilePath();
      final canonical = await Directory(resolved).resolveSymbolicLinks();
      _require(
        canonical ==
            await Directory(
              p.join(repository, 'packages', entry['name'] as String),
            ).resolveSymbolicLinks(),
        'A product package resolves outside the local source copy.',
      );
      productRoots[entry['name'] as String] = canonical;
    }
  }
  _require(
    productRoots.length == 4,
    'All four product packages must resolve locally.',
  );
  return {
    'scope': 'Targeted source/config fingerprint, not a full checkout audit',
    'sourceFiles': sourceFiles,
    'toolCanonicalPath': toolPath,
    'sourceFingerprint': sha256
        .convert(CanonicalJson.encodeUtf8(sourceFiles))
        .toString(),
    'packageConfigPath': configPath,
    'packageConfigSha256': await _hash(File(configPath)),
    'productPackageRoots': productRoots,
    'gitQueried': false,
    'commitAndCleanState': null,
  };
}

Future<Map<String, dynamic>> _child(
  String executable,
  String tool,
  String config,
  String mode,
  File requestFile,
  Directory temporary, {
  required bool measureRss,
  String? workerExecutable,
}) async {
  final request = await _readJson(requestFile);
  final root = request['root'] as String;
  await temporary.create();
  request['temporaryDirectory'] = await temporary.resolveSymbolicLinks();
  await _json(requestFile, request);
  final stdoutFile = File(p.join(root, '$mode.stdout.jsonl'));
  final stderrFile = File(p.join(root, '$mode.stderr.log'));
  final output = stdoutFile.openWrite(), errors = stderrFile.openWrite();
  final command = resourcePackVolumeChildCommand(
    dartExecutable: executable, tool: tool, config: config, mode: mode,
    request: requestFile.path, workerExecutable: workerExecutable,
  );
  final process = await Process.start(
    command.first,
    command.skip(1).toList(),
    environment: {
      ...Platform.environment,
      'TMPDIR': request['temporaryDirectory'] as String,
    },
  );
  await process.stdin.close();
  final watch = Stopwatch()..start();
  final phases = <Map<String, dynamic>>[];
  final samples = <Map<String, dynamic>>[];
  var phase = 'startup',
      ended = false,
      failedSamples = 0,
      rejectedOwnershipSamples = 0;
  final stdoutDone = process.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((line) {
        output.writeln(line);
        try {
          final value = jsonDecode(line);
          if (value is Map &&
              value['event'] == 'phase' &&
              value['pid'] == process.pid) {
            phase = value['phase'] as String;
            phases.add({
              'phase': phase,
              'observedMs': watch.elapsedMilliseconds,
              'atUtc': value['atUtc'],
            });
          }
        } on FormatException {}
      })
      .asFuture<void>();
  final stderrDone = process.stderr
      .transform(utf8.decoder)
      .listen(errors.write)
      .asFuture<void>();
  Future<void> sample() async {
    while (!ended) {
      final samplePhase = phase;
      final observed = watch.elapsedMilliseconds;
      try {
        final result = await Process.run('ps', [
          '-p',
          '${process.pid}',
          '-o',
          'pid=,rss=,command=',
        ]);
        final text = (result.stdout as String).trim();
        final match = RegExp(r'^(\d+)\s+(\d+)\s+(.+)$').firstMatch(text);
        if (result.exitCode == 0 &&
            match != null &&
            int.parse(match[1]!) == process.pid) {
          if (match[3]!.contains(requestFile.path) &&
              match[3]!.contains('--internal-$mode')) {
            samples.add({
              'pid': process.pid,
              'phase': samplePhase,
              'observedMs': observed,
              'rssBytes': int.parse(match[2]!) * 1024,
            });
          } else {
            rejectedOwnershipSamples++;
          }
        } else {
          failedSamples++;
        }
      } on Object {
        failedSamples++;
      }
      if (!ended) await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  final sampling = measureRss ? sample() : Future<void>.value();
  final code = await process.exitCode;
  ended = true;
  await sampling;
  await Future.wait([stdoutDone, stderrDone]);
  await output.close();
  await errors.close();
  watch.stop();
  final coverage = <Map<String, dynamic>>[];
  for (final name in {
    'startup',
    ...phases.map((event) => event['phase'] as String),
  }) {
    final selected = samples
        .where((sample) => sample['phase'] == name)
        .toList();
    coverage.add({
      'phase': name,
      'sampleCount': selected.length,
      'sampledPeakRssBytes': selected.isEmpty
          ? null
          : selected.map((sample) => sample['rssBytes'] as int).reduce(max),
    });
  }
  final gaps = <int>[];
  for (var i = 1; i < samples.length; i++) {
    gaps.add(
      (samples[i]['observedMs'] as int) - (samples[i - 1]['observedMs'] as int),
    );
  }
  final baseline = samples
      .where((sample) => sample['phase'] == 'baseline')
      .toList();
  return {
    'kind': mode == 'worker' && workerExecutable != null ? 'dart-aot' : 'dart-jit',
    'command': command,
    'pid': process.pid,
    'exitCode': code,
    'elapsedMs': watch.elapsedMilliseconds,
    'stdoutPath': stdoutFile.path,
    'stdoutSha256': await _hash(stdoutFile),
    'stderrPath': stderrFile.path,
    'stderrSha256': await _hash(stderrFile),
    'phaseEvents': phases,
    'childrenAwaited': true,
    'rss': measureRss
        ? {
            'measurement': 'sampled_current_rss',
            'scope': 'worker_process_including_runtime',
            'source': 'External supervisor ps PID/RSS/command, KiB converted to bytes',
            'intervalMs': 100,
            'sampleCount': samples.length,
            'failedSamples': failedSamples,
            'rejectedOwnershipSamples': rejectedOwnershipSamples,
            'observedMaximumIntervalMs': gaps.isEmpty ? null : gaps.reduce(max),
            'sampledPeakRssBytes': samples.isEmpty
                ? null
                : samples
                      .map((sample) => sample['rssBytes'] as int)
                      .reduce(max),
            'baselineSampleCount': baseline.length,
            'baselineRssBytes': baseline.isEmpty
                ? null
                : baseline.first['rssBytes'],
            'coverageByPhase': coverage,
            'samples': samples,
            'coverageLimit': 'Sampled observations; short phases may have zero samples. Not a continuous maximum or ProcessInfo.maxRss.',
          }
        : null,
  };
}

final class ResourcePackVolumeReceipt {
  const ResourcePackVolumeReceipt._();
  static final _shaPattern = RegExp(r'^[0-9a-f]{64}$');

  static bool _validSha(Object? value) =>
      value is String && _shaPattern.hasMatch(value);

  static int _integer(
    Map<String, dynamic> value,
    String key,
    int maximum, {
    int minimum = 1,
  }) {
    final number = value[key];
    if (number is! int || number < minimum || number > maximum) {
      throw FormatException('$key must be an integer in $minimum..$maximum.');
    }
    return number;
  }

  static void _workerExecution(
    Map<String, dynamic> receipt,
    Map<String, dynamic> generator,
    Map<String, dynamic> worker,
  ) {
    final execution = receipt['execution'];
    if (worker['kind'] == 'dart-aot' && execution == null) {
      throw const FormatException(
        'AOT receipts require explicit supervisor and generator execution metadata.',
      );
    }
    final requestedKind = execution == null ? worker['kind'] : _object(execution)['worker'];
    if (execution != null &&
        (_object(execution)['supervisor'] != 'dart-jit' ||
            _object(execution)['generator'] != 'dart-jit' ||
            !['dart-jit', 'dart-aot'].contains(requestedKind) ||
            generator['kind'] != 'dart-jit' || worker['kind'] != requestedKind)) {
      throw const FormatException('Execution kinds differ from the requested launcher.');
    }
    if (requestedKind != 'dart-aot') return;
    final inputs = _object(worker['buildInputs']);
    final sourceIdentity = _object(receipt['sourceIdentity']);
    if (['dartSdkVersion', 'targetOS', 'targetArchitecture']
        .any((key) => inputs[key] is! String || (inputs[key] as String).isEmpty)) {
      throw const FormatException('AOT SDK/target provenance is missing.');
    }
    final expectedInputs = ResourcePackVolumeAotWorker.buildInputs(
      sourceIdentity,
      dartSdkVersion: inputs['dartSdkVersion'] as String,
      targetOS: inputs['targetOS'] as String,
      targetArchitecture: inputs['targetArchitecture'] as String,
    );
    final identity = _object(worker['identity']);
    final command = worker['compileCommand'];
    final launch = worker['command'];
    final executable = worker['executable'];
    final receiptPath = worker['buildReceiptPath'];
    final id = _canonicalHash(inputs);
    if (!_same(inputs, expectedInputs) ||
        !_same(sourceIdentity, receipt['sourceIdentityAfter']) ||
        worker['sourceConfigIdentityMatched'] != true ||
        !_sha64(worker['executableSha256']) ||
        worker['binarySha256AfterRun'] != worker['executableSha256'] ||
        !_sha64(worker['buildReceiptSha256']) ||
        executable is! String || !p.isAbsolute(executable) ||
        receiptPath is! String || !p.isAbsolute(receiptPath) ||
        worker['buildId'] != id ||
        launch is! List || launch.length != 3 ||
        launch[0] != executable || launch[1] != '--internal-worker' ||
        launch[2] is! String || !p.isAbsolute(launch[2] as String) ||
        identity['formatVersion'] is! int || identity['formatVersion'] != 1 ||
        identity['kind'] != 'resource_pack_volume_worker_identity' ||
        identity['executionKind'] != 'dart-aot' || identity['buildId'] != id ||
        ['dartSdkVersion', 'targetOS', 'targetArchitecture']
            .any((key) => identity[key] != inputs[key]) ||
        command is! List || command.length != 7 ||
        command.any((value) => value is! String) ||
        !p.isAbsolute(command.first as String) ||
        !_same(command.skip(1).toList(), [
          'compile', 'exe', '-DP12_RESOURCE_PACK_WORKER_BUILD_ID=$id',
          inputs['toolCanonicalPath'], '-o', executable,
        ])) {
      throw const FormatException('Pinned AOT execution provenance is inconsistent.');
    }
  }

  static Map<String, dynamic> _observedCounters(
    Object? raw,
    Set<String> names,
  ) {
    final map = _object(raw);
    if (map.entries.any(
      (e) => !names.contains(e.key) || e.value is! int || (e.value as int) <= 0,
    )) {
      throw const FormatException(
        'Observed counters require known names and positive integer counts.',
      );
    }
    return map;
  }

  static void _scopedObservations(
    Map<String, dynamic> metrics,
    bool resourceJourney,
  ) {
    final scoped = _object(metrics['scopedIo']);
    final bytes = _observedCounters(scoped['byteCounters'], _byteCounterNames);
    final operations = _observedCounters(
      metrics['authoringOperationCounters'],
      _operationCounterNames,
    );
    final unknown = _object(scoped['unobservedBoundaries']);
    final gaps = scoped['gaps'];
    final incomplete = scoped['incompleteWorkerOperations'];
    final maximum = scoped['maxArchiveReadAtRequestBytes'];
    if (metrics['counterUnits'] != 'operations' ||
        scoped['coverage'] != 'partial' ||
        scoped['byteUnit'] != 'bytes' ||
        !scoped.containsKey('globalReadBytes') ||
        scoped['globalReadBytes'] != null ||
        !scoped.containsKey('globalWriteBytes') ||
        scoped['globalWriteBytes'] != null ||
        !_same(unknown, {
          'io.gateway.journal.readBytes': null,
          'io.gateway.descriptor.readBytes': null,
        }) ||
        gaps is! List ||
        gaps.length < 4 ||
        gaps.any((e) => e is! String || e.length < 8) ||
        incomplete is! int ||
        incomplete < 0 ||
        scoped['workerAggregateCoverage'] !=
            (incomplete == 0 ? 'successful_calls_only' : 'incomplete') ||
        maximum is! int ||
        maximum <= 0 ||
        maximum > 1024 * 1024 ||
        !bytes.containsKey(
          AuthoringPerformanceCounterName.harnessArchiveReadBytes,
        ) ||
        !bytes.containsKey(
          AuthoringPerformanceCounterName
              .harnessArchiveCompletedWriteInputBytes,
        ) ||
        !scoped.containsKey('journalWriteOperationCount') ||
        scoped['journalWriteOperationCount'] !=
            operations[AuthoringPerformanceCounterName
                .journalCompletedWrites]) {
      throw const FormatException(
        'Scoped byte units, partial coverage or explicit gaps are inconsistent.',
      );
    }
    final phases = scoped['phaseDeltas'];
    if (phases is! List || phases.isEmpty || phases.length > 128) {
      throw const FormatException(
        'Bounded phase counter observations are required.',
      );
    }
    final byteSums = <String, int>{}, operationSums = <String, int>{};
    var incompleteSum = 0;
    for (final raw in phases) {
      final phase = _object(raw);
      final name = phase['phase'];
      final marker = phase['incompleteWorkerOperations'];
      if (name is! String ||
          name.isEmpty ||
          name.length > 128 ||
          marker is! int ||
          marker < 0) {
        throw const FormatException('Invalid phase counter interval.');
      }
      incompleteSum += marker;
      for (final pair in [
        (phase['byteCounters'], _byteCounterNames, byteSums),
        (phase['operationCounters'], _operationCounterNames, operationSums),
      ]) {
        for (final e in _observedCounters(pair.$1, pair.$2).entries) {
          pair.$3.update(
            e.key,
            (n) => n + (e.value as int),
            ifAbsent: () => e.value as int,
          );
        }
      }
    }
    if (!_same(byteSums, bytes) ||
        !_same(operationSums, operations) ||
        incompleteSum != incomplete) {
      throw const FormatException(
        'Phase deltas do not reproduce their scoped counters.',
      );
    }
    final polls = scoped['pollResponses'];
    if (scoped['pollTimingUnit'] != 'microseconds' ||
        polls is! List ||
        polls.length > 64) {
      throw const FormatException(
        'Bounded poll timing observations require microsecond units.',
      );
    }
    final stages = <String>{};
    for (final raw in polls) {
      final poll = _object(raw);
      final stage = poll['stage'],
          count = poll['count'],
          total = poll['totalMicroseconds'],
          maximum = poll['maxMicroseconds'];
      if (stage is! String ||
          stage.isEmpty ||
          stage.length > 128 ||
          !stages.add(stage) ||
          count is! int ||
          count <= 0 ||
          total is! int ||
          total < 0 ||
          maximum is! int ||
          maximum < 0 ||
          maximum > total ||
          total > count * maximum) {
        throw const FormatException(
          'Poll elapsed-response aggregates are inconsistent.',
        );
      }
    }
    if (resourceJourney &&
        (polls.isEmpty ||
            scoped['journalWriteOperationCount'] is! int ||
            (scoped['journalWriteOperationCount'] as int) <= 0)) {
      throw const FormatException(
        'Resource journeys require observed get responses and completed journal writes.',
      );
    }
  }

  static void validate(Map<String, dynamic> receipt) {
    const policy = ResourcePackSecurityPolicy();
    if (receipt['formatVersion'] is! int ||
        receipt['formatVersion'] != 1 ||
        receipt['kind'] != 'resource_pack_volume' ||
        receipt['status'] != 'completed')
      throw const FormatException(
        'Unsupported or incomplete resource pack volume receipt.',
      );
    final campaigns = receipt['campaigns'];
    if (campaigns is! List ||
        campaigns.isEmpty ||
        receipt['sourcesUnchanged'] != true)
      throw const FormatException('Campaign or source proof is missing.');
    for (final raw in campaigns) {
      final campaign = _object(raw);
      final generator = _object(campaign['generator']),
          worker = _object(campaign['worker']);
      _workerExecution(receipt, generator, worker);
      final metrics = _object(campaign['metrics']),
          rss = _object(campaign['rss']);
      final result = _object(campaign['result']),
          requested = _object(campaign['requested']);
      if (generator['pid'] is! int ||
          generator['pid'] <= 0 ||
          worker['pid'] is! int ||
          worker['pid'] <= 0 ||
          generator['pid'] == worker['pid'] ||
          generator['exitCode'] is! int ||
          generator['exitCode'] != 0 ||
          worker['exitCode'] is! int ||
          worker['exitCode'] != 0 ||
          result['status'] != 'completed')
        throw const FormatException(
          'Independent successful generation/worker proof is missing.',
        );
      if (!metrics.containsKey('maxBytesInFlight') ||
          metrics['ioByteCoverage'] != 'unavailable' ||
          metrics['maxBytesInFlight'] != null)
        throw const FormatException(
          'Uninstrumented I/O ownership cannot be asserted.',
        );
      _scopedObservations(metrics, requested['campaign'] == 'resources');
      if (rss['measurement'] != 'sampled_current_rss' ||
          rss['intervalMs'] is! int ||
          rss['intervalMs'] != 100 ||
          rss['sampleCount'] is! int ||
          (rss['sampleCount'] as int) < 1)
        throw const FormatException('Current RSS sample coverage is missing.');
      final samples = rss['samples'];
      if (samples is! List ||
          samples.length != rss['sampleCount'] ||
          samples.any(
            (sample) =>
                sample is! Map ||
                sample['pid'] is! int ||
                sample['pid'] != worker['pid'] ||
                sample['rssBytes'] is! int ||
                sample['rssBytes'] <= 0,
          )) {
        throw const FormatException(
          'RSS samples do not match their observed worker PID.',
        );
      }
      if (!['resources', 'entries', 'capacity'].contains(requested['campaign']))
        throw const FormatException('Unknown campaign receipt.');
      if (result['campaign'] != requested['campaign']) {
        throw const FormatException(
          'Result campaign differs from its request.',
        );
      }
      final archiveLimit = _integer(
        requested,
        'archiveBytes',
        policy.maxArchiveBytes,
      );
      final payloadLimit = _integer(
        requested,
        'payloadBytes',
        policy.maxTotalPayloadBytes,
      );
      final entryLimit = _integer(
        requested,
        'zipEntries',
        policy.maxZipEntries,
        minimum: 4,
      );
      if (requested['campaign'] == 'resources') {
        final count = _integer(requested, 'resources', policy.maxResources);
        final business = _object(result['businessFingerprints']);
        final hashes = result['originalImageHashes'];
        if ([
              'initial',
              'imported',
              'afterUndo',
              'afterRedo',
              'afterExport',
            ].any((key) => !_validSha(business[key])) ||
            _integer(result, 'importedResourceCount', policy.maxResources) !=
                count ||
            _integer(result, 'exportedResourceCount', policy.maxResources) !=
                count ||
            result['undoBusinessEqualsInitial'] != true ||
            result['redoBusinessEqualsImported'] != true ||
            result['originalImagesPreserved'] != true ||
            result['sourceAndArchiveARemovedBeforeExport'] != true ||
            result['sessionCloseAwaited'] != true ||
            hashes is! List ||
            hashes.length != count ||
            hashes.any((hash) => !_validSha(hash)) ||
            hashes.toSet().length != count ||
            business['initial'] != business['afterUndo'] ||
            business['imported'] != business['afterRedo'] ||
            business['afterRedo'] != business['afterExport']) {
          throw const FormatException(
            'Canonical persistence/history/reexport proof is incomplete.',
          );
        }
        for (final name in ['exportA', 'exportC']) {
          final archive = _object(result[name]);
          final catalog = _integer(
            archive,
            'catalogBytes',
            policy.maxCatalogBytes,
          );
          final useful = _integer(
            archive,
            'payloadBytes',
            payloadLimit,
            minimum: catalog + 1,
          );
          final bytes = _integer(
            archive,
            'byteLength',
            archiveLimit,
            minimum: useful + 1,
          );
          if (_integer(archive, 'resourceCount', policy.maxResources) !=
                  count ||
              !_validSha(archive['rawSha256']) ||
              bytes <= useful) {
            throw const FormatException(
              'Resource archive proof is inconsistent.',
            );
          }
        }
      } else {
        if (result['officialInspectionAccepted'] != true) {
          throw const FormatException(
            'Official archive inspection is missing.',
          );
        }
        _integer(requested, 'resources', 0, minimum: 0);
        final repeatedRequest = _object(result['requested']);
        if (repeatedRequest['campaign'] != requested['campaign'] ||
            _integer(repeatedRequest, 'resources', 0, minimum: 0) != 0 ||
            _integer(repeatedRequest, 'archiveBytes', policy.maxArchiveBytes) !=
                archiveLimit ||
            _integer(
                  repeatedRequest,
                  'payloadBytes',
                  policy.maxTotalPayloadBytes,
                ) !=
                payloadLimit ||
            _integer(
                  repeatedRequest,
                  'zipEntries',
                  policy.maxZipEntries,
                  minimum: 4,
                ) !=
                entryLimit) {
          throw const FormatException('Build request proof is inconsistent.');
        }
        final actual = _object(result['actual']);
        final source = _integer(actual, 'sourceBytes', payloadLimit);
        final catalog = _integer(
          actual,
          'catalogBytes',
          policy.maxCatalogBytes,
        );
        final manifest = _integer(
          actual,
          'manifestBytes',
          policy.maxManifestBytes,
        );
        final useful = _integer(actual, 'usefulPayloadBytes', payloadLimit);
        final bytes = _integer(actual, 'archiveBytes', archiveLimit);
        final entries = _integer(actual, 'zipEntries', entryLimit, minimum: 4);
        _integer(actual, 'catalogJsonNodes', policy.maxJsonNodes);
        _integer(actual, 'catalogJsonDepth', policy.maxJsonDepth);
        final archive = _object(result['archive']);
        final resources = _integer(
          result,
          'resourceCount',
          policy.maxResources,
        );
        final expectedResources = requested['campaign'] == 'entries'
            ? (entries - 2) ~/ 2
            : entries - 3;
        if (source + catalog != useful ||
            bytes <= useful + manifest ||
            _integer(archive, 'byteLength', archiveLimit) != bytes ||
            !_validSha(archive['rawSha256']) ||
            resources != expectedResources ||
            (requested['campaign'] == 'entries' && entries != entryLimit)) {
          throw const FormatException(
            'Actual build cardinalities or bytes are inconsistent.',
          );
        }
      }
    }
  }
}

Future<Map<String, dynamic>> _supervise(
  ResourcePackVolumeOptions options,
  String tool,
  String config,
) async {
  final sourceIdentity = await _identity(
    tool, config, includeWorkerBuildSources: options.workerExecutable != null,
  );
  final aotWorker = options.workerExecutable == null
      ? null
      : await ResourcePackVolumeAotWorker.verifyBuild(options, sourceIdentity);
  if (aotWorker != null) await aotWorker.probeIdentity();
  final output = Directory(options.outputPath);
  final type = await FileSystemEntity.type(output.path, followLinks: false);
  if (type != FileSystemEntityType.notFound &&
      (type != FileSystemEntityType.directory || !await output.list().isEmpty))
    throw const FormatException(
      'Evidence output must be a new or empty real directory.',
    );
  await output.create(recursive: true);
  final canonical = await output.resolveSymbolicLinks();
  final nonce = List.generate(
    16,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  await _json(File(p.join(canonical, 'owner.json')), {
    'kind': 'resource_pack_volume',
    'nonce': nonce,
  });
  final receipt = <String, dynamic>{
    'formatVersion': 1,
    'kind': 'resource_pack_volume',
    'status': 'running',
    'sourceIdentity': sourceIdentity,
    'sourcesUnchanged': false,
    'execution': {
      'supervisor': 'dart-jit',
      'generator': 'dart-jit',
      'worker': aotWorker == null ? 'dart-jit' : 'dart-aot',
    },
    'campaigns': <Map<String, dynamic>>[],
    'limitations': [
      'Only the resources campaign exercises canonical import/history/reopen/reexport; entries and capacity are separate build/inspection boundaries',
      'No Player/native render/publication or fault-injection recovery certification',
      'Scoped byte boundaries are partial and separate from operation counters; global I/O and maxBytesInFlight remain unavailable',
      'Generation and worker are separate fresh processes; fixture data and toolchain TMPDIR are separate',
      'No Git commit/clean-state claim; targeted source/config fingerprints only',
    ],
  };
  try {
    final counts = options.campaign == ResourcePackVolumeCampaign.resources
        ? options.resourceCounts
        : [0];
    for (final count in counts) {
      if (aotWorker != null) await aotWorker.checkUnchanged();
      final name = options.campaign.name;
      final run = await Directory(
        p.join(canonical, name == 'resources' ? 'resources-$count' : name),
      ).create();
      final runRoot = await run.resolveSymbolicLinks();
      await _json(File(p.join(runRoot, 'owner.json')), {
        'kind': 'resource_pack_volume',
        'nonce': nonce,
      });
      final requested = <String, dynamic>{
        'campaign': name,
        'resources': count,
        'zipEntries': options.zipEntries,
        'payloadBytes': options.payloadBytes,
        'archiveBytes': options.archiveBytes,
      };
      final caseReceipt = <String, dynamic>{'requested': requested};
      (receipt['campaigns'] as List).add(caseReceipt);
      final generatorRequest = File(p.join(runRoot, 'generator-request.json'));
      final workerRequest = File(p.join(runRoot, 'worker-request.json'));
      final request = {
        'root': runRoot,
        'nonce': nonce,
        'requested': requested,
        'temporaryDirectory': '',
      };
      await _json(generatorRequest, request);
      final generator = await _child(
        Platform.resolvedExecutable,
        tool,
        config,
        'generate',
        generatorRequest,
        Directory(p.join(runRoot, 'generator-temp')),
        measureRss: false,
      );
      caseReceipt['generator'] = generator;
      _require(
        generator['exitCode'] == 0,
        'Generator failed; see ${generator['stderrPath']}',
      );
      final generation = await _readJson(
        File(p.join(runRoot, 'generation.json')),
      );
      caseReceipt['generated'] = generation;
      caseReceipt['generationSha256'] = await _hash(
        File(p.join(runRoot, 'generation.json')),
      );
      await _json(workerRequest, request);
      if (aotWorker != null) {
        await aotWorker.checkUnchanged();
        if (!_same(sourceIdentity, await _identity(tool, config, includeWorkerBuildSources: true))) {
          throw const FormatException('Worker source/config changed before launch.');
        }
      }
      final worker = await _child(
        Platform.resolvedExecutable,
        tool,
        config,
        'worker',
        workerRequest,
        Directory(p.join(runRoot, 'worker-temp')),
        measureRss: true,
        workerExecutable: aotWorker?.executable,
      );
      if (aotWorker != null) worker.addAll(await aotWorker.proofAfterRun());
      caseReceipt['worker'] = worker;
      caseReceipt['rss'] = worker['rss'];
      final resultFile = File(p.join(runRoot, 'worker-result.json'));
      final result = await _readJson(resultFile);
      caseReceipt['result'] = result;
      caseReceipt['resultSha256'] = await _hash(resultFile);
      caseReceipt['metrics'] = result['metrics'];
      _require(
        worker['exitCode'] == 0 && result['status'] == 'completed',
        'Worker failed; see ${worker['stderrPath']}',
      );
      await _json(File(p.join(runRoot, 'receipt.json')), caseReceipt);
    }
    if (aotWorker != null) await aotWorker.checkUnchanged();
    receipt['sourceIdentityAfter'] = await _identity(
      tool, config, includeWorkerBuildSources: aotWorker != null,
    );
    receipt['sourcesUnchanged'] = _same(
      sourceIdentity,
      receipt['sourceIdentityAfter'],
    );
    receipt['status'] = 'completed';
    ResourcePackVolumeReceipt.validate(receipt);
    await _json(File(p.join(canonical, 'receipt.json')), receipt);
    return receipt;
  } catch (error, stack) {
    receipt['status'] = 'failed';
    receipt['error'] = error.toString();
    receipt['stack'] = stack.toString();
    await _json(File(p.join(canonical, 'receipt.json')), receipt);
    rethrow;
  }
}

Future<void> main(List<String> arguments) async {
  try {
    if (arguments.length == 1 && arguments.single == '--internal-worker-identity') {
      stdout.writeln(jsonEncode(resourcePackVolumeWorkerIdentity()));
      return;
    }
    if (arguments.length == 2 &&
        [
          '--internal-generate',
          '--internal-worker',
        ].contains(arguments.first)) {
      final request = await _readJson(File(arguments[1]));
      if (arguments.first == '--internal-generate') {
        await _generate(request);
      } else {
        await _worker(request);
      }
      return;
    }
    final options = ResourcePackVolumeOptions.parse(arguments);
    if (options.help) {
      stdout.writeln(
        'resource_pack_volume --mode local --campaign resources|entries|capacity --output /absolute/new/evidence [--resources 10,1000,10000 | --zip-entries 20000 | --payload-bytes 524288000] [--archive-bytes 536870912] [--worker-executable /absolute/worker --worker-sha256 <64-lower-hex> --worker-build-receipt /absolute/build.json]. All three worker options select pinned AOT; none selects Dart JIT.',
      );
      return;
    }
    _require(
      !p.basename(Platform.resolvedExecutable).contains('flutter_tester'),
      'Use the pure Dart entry point, not flutter_tester.',
    );
    _require(
      !const bool.fromEnvironment('dart.vm.product'),
      'The supervisor must use Dart JIT; AOT is worker-only.',
    );
    final tool = await File.fromUri(Platform.script).resolveSymbolicLinks();
    final config = (await Isolate.packageConfig)?.toFilePath();
    _require(
      config != null,
      'An explicitly resolved package configuration is required.',
    );
    final receipt = await _supervise(options, tool, config!);
    stdout.writeln(
      jsonEncode({
        'status': receipt['status'],
        'receipt': p.join(options.outputPath, 'receipt.json'),
        'campaignCount': (receipt['campaigns'] as List).length,
      }),
    );
  } on Object catch (error, stack) {
    stderr.writeln(
      jsonEncode({
        'status': 'failed',
        'error': error.toString(),
        'stack': stack.toString(),
      }),
    );
    exitCode = error is FormatException ? 64 : 1;
  }
}
