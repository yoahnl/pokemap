import 'dart:typed_data';

import 'package:map_core/map_core.dart';

typedef RuntimeGen5BattleSourceAssetOpener =
    Future<Stream<List<int>>?> Function(String projectRelativePath);

Future<Gen5BattleSourceBundle?> loadRuntimeGen5BattleSource({
  required RuntimeGen5BattleSourceAssetOpener openAsset,
  required String projectSpeciesId,
  required int projectNationalDex,
  required String? expectedBindingSha256,
  bool Function()? isCurrent,
}) async {
  if (expectedBindingSha256 == null) return null;

  void checkCurrent() {
    if (isCurrent != null && !isCurrent()) {
      throw StateError('Gen 5 battle source load is no longer current');
    }
  }

  checkCurrent();
  final bindingPath = Gen5BattleSourceBinding.bindingPathFor(projectSpeciesId);
  final bindingBytes = await _readSourceAsset(
    bindingPath,
    gen5BattleSourceBindingMaxBytes,
    openAsset,
    checkCurrent,
  );
  final binding = Gen5BattleSourceBinding.decode(
    bindingBytes,
    expectedSha256: expectedBindingSha256,
    expectedProjectSpeciesId: projectSpeciesId,
    expectedProjectNationalDex: projectNationalDex,
  );
  checkCurrent();
  final bundleBytes = await _readSourceAsset(
    binding.bundlePath,
    gen5BattleSourceBundleMaxBytes,
    openAsset,
    checkCurrent,
  );
  final bundle = binding.resolve(
    bundleBytes,
    expectedProjectSpeciesId: projectSpeciesId,
    expectedProjectNationalDex: projectNationalDex,
  );
  checkCurrent();
  return bundle;
}

Future<Uint8List> _readSourceAsset(
  String path,
  int maximumBytes,
  RuntimeGen5BattleSourceAssetOpener openAsset,
  void Function() checkCurrent,
) async {
  checkCurrent();
  final stream = await openAsset(path);
  checkCurrent();
  if (stream == null) {
    throw const FormatException('Missing inventoried Gen 5 battle source');
  }
  final buffer = BytesBuilder(copy: false);
  await for (final chunk in stream) {
    checkCurrent();
    if (chunk.length > maximumBytes - buffer.length) {
      throw const FormatException('Gen 5 battle source exceeds its byte limit');
    }
    buffer.add(chunk);
  }
  checkCurrent();
  return buffer.takeBytes();
}
